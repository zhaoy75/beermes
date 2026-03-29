create or replace function public.inventory_lot_void(
  p_lot_id uuid,
  p_reason text default null,
  p_site_id uuid default null
)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_status text;
  v_site_id uuid;
  v_reason text;
  v_site_type text;
  v_qty numeric;
  v_uom_id uuid;
  v_material_id uuid;
  v_package_id uuid;
  v_batch_id uuid;
  v_lot_unit numeric;
  v_inventory_id uuid;
  v_inventory_remaining numeric;
  v_lot_remaining_qty numeric;
  v_movement_at timestamptz := now();
  v_doc_no text;
  v_movement_id uuid;
  v_movement_line_id uuid;
  v_zero_material_id uuid := '00000000-0000-0000-0000-000000000000'::uuid;
begin
  if p_lot_id is null then
    raise exception 'ILV001: p_lot_id is required';
  end if;

  v_tenant := public._assert_tenant();
  v_reason := nullif(btrim(p_reason), '');

  select l.status,
         l.site_id,
         l.qty,
         l.uom_id,
         l.material_id,
         l.package_id,
         l.batch_id,
         l.unit
    into v_status,
         v_site_id,
         v_lot_remaining_qty,
         v_uom_id,
         v_material_id,
         v_package_id,
         v_batch_id,
         v_lot_unit
  from public.lot l
  where l.tenant_id = v_tenant
    and l.id = p_lot_id
  for update;

  if not found then
    raise exception 'ILV002: lot not found';
  end if;

  if v_status = 'void' then
    return p_lot_id;
  end if;

  v_site_id := coalesce(p_site_id, v_site_id);
  if v_site_id is null then
    raise exception 'ILV003: site_id is required';
  end if;

  select rd.def_key
    into v_site_type
  from public.mst_sites s
  join public.registry_def rd
    on rd.def_id = s.site_type_id
   and rd.kind = 'site_type'
  where s.tenant_id = v_tenant
    and s.id = v_site_id;

  if v_site_type is null then
    raise exception 'ILV007: site_id not found or site_type is invalid';
  end if;

  if v_site_type <> 'TAX_STORAGE' then
    raise exception 'ILV008: inventory_lot_void is only allowed for TAX_STORAGE';
  end if;

  select i.id, i.qty
    into v_inventory_id, v_qty
  from public.inv_inventory i
  where i.tenant_id = v_tenant
    and i.site_id = v_site_id
    and i.lot_id = p_lot_id
    and i.uom_id = v_uom_id
  order by i.created_at, i.id
  limit 1
  for update;

  if v_inventory_id is null then
    raise exception 'ILV004: inventory row not found for site/lot';
  end if;

  if coalesce(v_qty, 0) <= 0 then
    return p_lot_id;
  end if;

  if not exists (
    select 1
    from pg_enum e
    where e.enumtypid = 'public.inv_doc_type'::regtype
      and e.enumlabel = 'adjustment'
  ) then
    raise exception 'ILV005: inv_doc_type does not support adjustment';
  end if;

  v_doc_no := format(
    'IZ-%s-%s',
    to_char(v_movement_at, 'YYYYMMDDHH24MISSMS'),
    substr(replace(gen_random_uuid()::text, '-', ''), 1, 6)
  );

  insert into public.inv_movements (
    tenant_id, doc_no, doc_type, status, movement_at,
    src_site_id, dest_site_id, reason, meta, notes
  ) values (
    v_tenant,
    v_doc_no,
    'adjustment'::public.inv_doc_type,
    'posted',
    v_movement_at,
    v_site_id,
    null,
    v_reason,
    jsonb_strip_nulls(jsonb_build_object(
      'movement_intent', 'INVENTORY_SET_ZERO',
      'target_lot_id', p_lot_id,
      'target_site_id', v_site_id
    )),
    v_reason
  )
  returning id into v_movement_id;

  insert into public.inv_movement_lines (
    tenant_id, movement_id, line_no,
    material_id, package_id, batch_id, qty, unit, tax_rate, uom_id, notes, meta
  ) values (
    v_tenant,
    v_movement_id,
    1,
    coalesce(v_material_id, v_zero_material_id),
    v_package_id,
    v_batch_id,
    v_qty,
    case when coalesce(v_lot_remaining_qty, 0) <= v_qty then coalesce(v_lot_unit, 0) else null end,
    null,
    v_uom_id,
    v_reason,
    jsonb_strip_nulls(jsonb_build_object(
      'line_role', 'INVENTORY_SET_ZERO',
      'target_lot_id', p_lot_id,
      'target_site_id', v_site_id
    ))
  )
  returning id into v_movement_line_id;

  insert into public.lot_edge (
    tenant_id, movement_id, movement_line_id, edge_type,
    from_lot_id, to_lot_id, qty, uom_id, notes, meta
  ) values (
    v_tenant,
    v_movement_id,
    v_movement_line_id,
    'CONSUME'::public.lot_edge_type,
    p_lot_id,
    null,
    v_qty,
    v_uom_id,
    v_reason,
    jsonb_strip_nulls(jsonb_build_object(
      'movement_intent', 'INVENTORY_SET_ZERO',
      'target_site_id', v_site_id
    ))
  );

  update public.inv_inventory i
     set qty = i.qty - v_qty
   where i.id = v_inventory_id
  returning i.qty into v_inventory_remaining;

  if v_inventory_remaining < 0 then
    raise exception 'ILV006: inventory quantity is insufficient after update';
  end if;

  update public.lot l
     set qty = greatest(l.qty - v_qty, 0),
         unit = case
           when l.qty - v_qty <= 0 then 0
           else l.unit
         end,
         status = case
           when l.qty - v_qty <= 0 then 'consumed'
           else l.status
         end,
         updated_at = now(),
         notes = coalesce(v_reason, l.notes),
         meta = coalesce(l.meta, '{}'::jsonb) || jsonb_strip_nulls(jsonb_build_object(
           'inventory_zeroed_at', now(),
           'inventory_zero_reason', v_reason,
           'inventory_zero_movement_id', v_movement_id,
           'inventory_zero_site_id', v_site_id
         ))
   where l.tenant_id = v_tenant
     and l.id = p_lot_id;

  perform public._assert_non_negative_lot_qty(p_lot_id);

  return v_movement_id;
end;
$$;
