create or replace function public.product_unpacking(p_doc jsonb)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_movement_id uuid;
  v_recovered_line_id uuid;
  v_loss_line_id uuid;
  v_dest_lot_id uuid;
  v_source_inv_id uuid;
  v_dest_inv_id uuid;

  v_doc_no text;
  v_movement_at timestamptz;
  v_src_site_id uuid;
  v_dest_site_id uuid;
  v_src_lot_id uuid;
  v_target_batch_id uuid;
  v_uom_id uuid;
  v_qty numeric;
  v_loss_qty numeric;
  v_recovered_qty numeric;
  v_reason text;
  v_notes text;
  v_meta jsonb;
  v_idempotency_key text;
  v_tank_id uuid;
  v_tank_no text;

  v_source_lot_no text;
  v_source_material_id uuid;
  v_source_package_id uuid;
  v_source_batch_id uuid;
  v_source_lot_tax_type text;
  v_source_lot_site_id uuid;
  v_source_lot_qty numeric;
  v_source_lot_unit numeric;
  v_source_lot_uom_id uuid;
  v_source_lot_status text;
  v_source_lot_meta jsonb;
  v_source_produced_at timestamptz;
  v_source_expires_at timestamptz;
  v_source_inventory_qty numeric;

  v_dest_site_type text;
  v_target_batch_code text;
  v_uom_code text;
  v_lot_no_base text;
  v_next_lot_seq int;
  v_remaining_qty numeric;
  v_unpack_units numeric;
  v_remaining_units numeric;
  v_zero_material_id uuid := '00000000-0000-0000-0000-000000000000'::uuid;
begin
  if p_doc is null then
    raise exception 'PU001: p_doc is required';
  end if;

  v_tenant := public._assert_tenant();

  v_doc_no := nullif(btrim(coalesce(p_doc ->> 'doc_no', '')), '');
  v_movement_at := coalesce(nullif(p_doc ->> 'movement_at', '')::timestamptz, now());
  v_src_site_id := nullif(p_doc ->> 'src_site_id', '')::uuid;
  v_dest_site_id := nullif(p_doc ->> 'dest_site_id', '')::uuid;
  v_src_lot_id := nullif(p_doc ->> 'src_lot_id', '')::uuid;
  v_target_batch_id := nullif(p_doc ->> 'target_batch_id', '')::uuid;
  v_uom_id := nullif(p_doc ->> 'uom_id', '')::uuid;
  v_qty := coalesce((p_doc ->> 'qty')::numeric, 0);
  v_loss_qty := coalesce((p_doc ->> 'loss_qty')::numeric, 0);
  v_reason := nullif(btrim(coalesce(p_doc ->> 'reason', '')), '');
  v_notes := nullif(p_doc ->> 'notes', '');
  v_meta := coalesce(p_doc -> 'meta', '{}'::jsonb);
  v_idempotency_key := nullif(btrim(coalesce(v_meta ->> 'idempotency_key', '')), '');
  v_tank_id := nullif(p_doc ->> 'tank_id', '')::uuid;

  if v_src_site_id is null
     or v_dest_site_id is null
     or v_src_lot_id is null
     or v_target_batch_id is null
     or v_uom_id is null then
    raise exception 'PU001: missing required field';
  end if;

  if v_qty <= 0 then
    raise exception 'PU002: qty must be greater than 0';
  end if;

  if v_loss_qty < 0 then
    raise exception 'PU002: loss_qty must be greater than or equal to 0';
  end if;

  v_recovered_qty := v_qty - v_loss_qty;
  if v_recovered_qty <= 0 then
    raise exception 'PU002: qty must be greater than loss_qty';
  end if;

  if v_doc_no is null then
    v_doc_no := format(
      'PU-%s-%s',
      to_char(v_movement_at, 'YYYYMMDDHH24MISSMS'),
      substr(replace(gen_random_uuid()::text, '-', ''), 1, 6)
    );
  end if;

  if v_idempotency_key is not null then
    select m.id
      into v_movement_id
    from public.inv_movements m
    where m.tenant_id = v_tenant
      and m.meta ->> 'idempotency_key' = v_idempotency_key
      and m.doc_type = 'transfer'::public.inv_doc_type
    order by m.created_at desc
    limit 1;

    if v_movement_id is not null then
      return v_movement_id;
    end if;
  end if;

  select
    l.lot_no,
    l.material_id,
    l.package_id,
    l.batch_id,
    coalesce(l.lot_tax_type, 'OUT_OF_SCOPE'),
    l.site_id,
    l.qty,
    l.unit,
    l.uom_id,
    l.status,
    coalesce(l.meta, '{}'::jsonb),
    l.produced_at,
    l.expires_at
    into
      v_source_lot_no,
      v_source_material_id,
      v_source_package_id,
      v_source_batch_id,
      v_source_lot_tax_type,
      v_source_lot_site_id,
      v_source_lot_qty,
      v_source_lot_unit,
      v_source_lot_uom_id,
      v_source_lot_status,
      v_source_lot_meta,
      v_source_produced_at,
      v_source_expires_at
  from public.lot l
  where l.tenant_id = v_tenant
    and l.id = v_src_lot_id
  for update;

  if not found then
    raise exception 'PU003: source lot not found';
  end if;

  if v_source_package_id is null then
    raise exception 'PU004: source lot is not packaged';
  end if;

  if v_source_lot_status <> 'active' then
    raise exception 'PU004: source lot is not active. status=%', v_source_lot_status;
  end if;

  if v_source_lot_site_id is not null and v_source_lot_site_id <> v_src_site_id then
    raise exception 'PU004: source lot site mismatch';
  end if;

  if v_source_lot_uom_id is distinct from v_uom_id then
    raise exception 'PU004: source lot uom_id mismatch';
  end if;

  if v_source_lot_qty < v_qty then
    raise exception 'PU005: source lot insufficient quantity';
  end if;

  select i.id, i.qty
    into v_source_inv_id, v_source_inventory_qty
  from public.inv_inventory i
  where i.tenant_id = v_tenant
    and i.site_id = v_src_site_id
    and i.lot_id = v_src_lot_id
    and i.uom_id = v_uom_id
  order by i.created_at, i.id
  limit 1
  for update;

  if v_source_inv_id is null or coalesce(v_source_inventory_qty, 0) < v_qty then
    raise exception 'PU005: source inventory insufficient quantity';
  end if;

  select b.batch_code
    into v_target_batch_code
  from public.mes_batches b
  where b.tenant_id = v_tenant
    and b.id = v_target_batch_id
  limit 1;

  if v_target_batch_code is null then
    raise exception 'PU006: target batch not found';
  end if;

  select u.code
    into v_uom_code
  from public.mst_uom u
  where u.id = v_uom_id
  limit 1;

  select
    case lower(coalesce(rd.def_key, ''))
      when 'brewery' then 'BREWERY_MANUFACTUR'
      when 'brewery_manufactur' then 'BREWERY_MANUFACTUR'
      when 'brewery_storage' then 'BREWERY_STORAGE'
      when 'tax_storage' then 'TAX_STORAGE'
      when 'bonded_area' then 'TAX_STORAGE'
      when 'domestic_customer' then 'DOMESTIC_CUSTOMER'
      when 'oversea_customer' then 'OVERSEA_CUSTOMER'
      when 'other_brewery' then 'OTHER_BREWERY'
      when 'disposal_facility' then 'DISPOSAL_FACILITY'
      when 'direct_sales_shop' then 'DIRECT_SALES_SHOP'
      else upper(replace(coalesce(rd.def_key, ''), '-', '_'))
    end
    into v_dest_site_type
  from public.mst_sites s
  left join public.registry_def rd
    on rd.def_id = s.site_type_id
   and rd.kind = 'site_type'
   and rd.is_active = true
  where s.tenant_id = v_tenant
    and s.id = v_dest_site_id;

  if v_dest_site_type is null then
    raise exception 'PU007: destination site not found or site_type is invalid';
  end if;

  if v_dest_site_type <> 'BREWERY_MANUFACTUR' then
    raise exception 'PU007: destination site must be BREWERY_MANUFACTUR';
  end if;

  if v_tank_id is not null then
    select e.equipment_code
      into v_tank_no
    from public.mst_equipment e
    where e.tenant_id = v_tenant
      and e.id = v_tank_id
      and e.equipment_kind = 'tank'
      and e.is_active = true
    limit 1;

    if v_tank_no is null then
      raise exception 'PU008: tank_id is invalid';
    end if;
  end if;

  if coalesce(v_source_lot_unit, 0) > 0 and v_source_lot_qty > 0 then
    v_unpack_units := (v_source_lot_unit * v_qty) / v_source_lot_qty;
    v_remaining_units := greatest(v_source_lot_unit - v_unpack_units, 0);
  else
    v_unpack_units := null;
    v_remaining_units := null;
  end if;

  v_lot_no_base := format('%s_UP_', coalesce(v_source_lot_no, 'LOT'));
  perform pg_advisory_xact_lock(hashtext(v_tenant::text), hashtext(v_lot_no_base));

  select coalesce(max(sub.seq), 0) + 1
    into v_next_lot_seq
  from (
    select case
             when l.lot_no like v_lot_no_base || '%'
                  and substring(l.lot_no from char_length(v_lot_no_base) + 1) ~ '^[0-9]+$'
               then substring(l.lot_no from char_length(v_lot_no_base) + 1)::int
             else null
           end as seq
    from public.lot l
    where l.tenant_id = v_tenant
  ) sub;

  insert into public.inv_movements (
    tenant_id, doc_no, doc_type, status, movement_at,
    src_site_id, dest_site_id, reason, meta, notes
  ) values (
    v_tenant,
    v_doc_no,
    'transfer'::public.inv_doc_type,
    'posted',
    v_movement_at,
    v_src_site_id,
    v_dest_site_id,
    coalesce(v_reason, 'unpack'),
    jsonb_strip_nulls(
      v_meta || jsonb_build_object(
        'source', 'packing',
        'entry_source', 'produced_beer_inventory_unpacking',
        'packing_type', 'unpack',
        'movement_intent', 'PACKAGE_UNPACK',
        'batch_id', v_target_batch_id,
        'source_batch_id', v_source_batch_id,
        'source_lot_id', v_src_lot_id,
        'source_lot_no', v_source_lot_no,
        'source_package_id', v_source_package_id,
        'source_site_id', v_src_site_id,
        'volume_qty', v_recovered_qty,
        'volume_uom', v_uom_id,
        'movement_qty', v_recovered_qty,
        'movement_site_id', v_dest_site_id,
        'unpack_qty', v_qty,
        'unpack_uom', v_uom_id,
        'unpack_units', v_unpack_units,
        'source_remaining_qty', v_source_lot_qty - v_qty,
        'source_remaining_uom', v_uom_id,
        'source_remaining_units', v_remaining_units,
        'loss_qty', v_loss_qty,
        'loss_uom', v_uom_id,
        'tank_id', v_tank_id,
        'tank_no', v_tank_no,
        'reason', coalesce(v_reason, 'unpack'),
        'memo', v_notes,
        'lot_edge_type', 'SPLIT',
        'filling_lines', jsonb_build_array(
          jsonb_strip_nulls(
            jsonb_build_object(
              'package_type_id', v_source_package_id,
              'qty', v_unpack_units,
              'volume', v_qty,
              'sample_flg', false
            )
          )
        )
      )
    ),
    v_notes
  )
  returning id into v_movement_id;

  insert into public.inv_movement_lines (
    tenant_id, movement_id, line_no,
    material_id, package_id, batch_id, qty, unit, tax_rate, uom_id, notes, meta
  ) values (
    v_tenant,
    v_movement_id,
    1,
    coalesce(v_source_material_id, v_zero_material_id),
    null,
    v_target_batch_id,
    v_recovered_qty,
    null,
    null,
    v_uom_id,
    v_notes,
    jsonb_strip_nulls(jsonb_build_object(
      'line_role', 'RECOVERED',
      'source_lot_id', v_src_lot_id,
      'source_package_id', v_source_package_id,
      'movement_intent', 'PACKAGE_UNPACK',
      'tank_id', v_tank_id,
      'tank_no', v_tank_no,
      'target_batch_id', v_target_batch_id,
      'loss_qty', v_loss_qty
    ))
  )
  returning id into v_recovered_line_id;

  insert into public.lot (
    tenant_id, lot_no, material_id, package_id, batch_id, lot_tax_type, site_id,
    produced_at, expires_at, qty, unit, uom_id, status, meta, notes
  ) values (
    v_tenant,
    format('%s%s', v_lot_no_base, lpad(v_next_lot_seq::text, 3, '0')),
    coalesce(v_source_material_id, v_zero_material_id),
    null,
    v_target_batch_id,
    v_source_lot_tax_type,
    v_dest_site_id,
    coalesce(v_source_produced_at, v_movement_at),
    v_source_expires_at,
    v_recovered_qty,
    null,
    v_uom_id,
    'active',
    jsonb_strip_nulls(
      v_source_lot_meta || v_meta || jsonb_build_object(
        'source_movement_id', v_movement_id,
        'from_lot_id', v_src_lot_id,
        'source_lot_no', v_source_lot_no,
        'movement_intent', 'PACKAGE_UNPACK',
        'packing_type', 'unpack',
        'entry_source', 'produced_beer_inventory_unpacking',
        'source_package_id', v_source_package_id,
        'unpack_qty', v_qty,
        'loss_qty', v_loss_qty,
        'tank_id', v_tank_id,
        'tank_no', v_tank_no
      )
    ),
    v_notes
  )
  returning id into v_dest_lot_id;

  insert into public.lot_edge (
    tenant_id, movement_id, movement_line_id, edge_type,
    from_lot_id, to_lot_id, qty, uom_id, notes, meta
  ) values (
    v_tenant,
    v_movement_id,
    v_recovered_line_id,
    'SPLIT'::public.lot_edge_type,
    v_src_lot_id,
    v_dest_lot_id,
    v_recovered_qty,
    v_uom_id,
    v_notes,
    jsonb_strip_nulls(jsonb_build_object(
      'movement_intent', 'PACKAGE_UNPACK',
      'packing_type', 'unpack',
      'loss_qty', v_loss_qty
    ))
  );

  if v_loss_qty > 0 then
    insert into public.inv_movement_lines (
      tenant_id, movement_id, line_no,
      material_id, package_id, batch_id, qty, unit, tax_rate, uom_id, notes, meta
    ) values (
      v_tenant,
      v_movement_id,
      2,
      coalesce(v_source_material_id, v_zero_material_id),
      null,
      v_target_batch_id,
      v_loss_qty,
      null,
      null,
      v_uom_id,
      v_notes,
      jsonb_build_object(
        'line_role', 'LOSS',
        'movement_intent', 'PACKAGE_UNPACK',
        'source_lot_id', v_src_lot_id
      )
    )
    returning id into v_loss_line_id;

    insert into public.lot_edge (
      tenant_id, movement_id, movement_line_id, edge_type,
      from_lot_id, to_lot_id, qty, uom_id, notes, meta
    ) values (
      v_tenant,
      v_movement_id,
      v_loss_line_id,
      'CONSUME'::public.lot_edge_type,
      v_src_lot_id,
      null,
      v_loss_qty,
      v_uom_id,
      v_notes,
      jsonb_build_object(
        'movement_intent', 'PACKAGE_UNPACK',
        'packing_type', 'unpack',
        'line_role', 'LOSS'
      )
    );
  end if;

  update public.inv_inventory i
     set qty = i.qty - v_qty
   where i.id = v_source_inv_id;

  update public.lot l
     set qty = l.qty - v_qty,
         unit = case
           when l.qty - v_qty <= 0 then 0
           else l.unit
         end,
         status = case
           when l.qty - v_qty <= 0 then 'consumed'
           else l.status
         end,
         updated_at = now()
   where l.tenant_id = v_tenant
     and l.id = v_src_lot_id
  returning qty into v_remaining_qty;

  if v_remaining_qty < 0 then
    raise exception 'PU005: source lot insufficient quantity after update';
  end if;

  select i.id
    into v_dest_inv_id
  from public.inv_inventory i
  where i.tenant_id = v_tenant
    and i.site_id = v_dest_site_id
    and i.lot_id = v_dest_lot_id
    and i.uom_id = v_uom_id
  order by i.created_at, i.id
  limit 1
  for update;

  if v_dest_inv_id is null then
    insert into public.inv_inventory (
      tenant_id, site_id, lot_id, qty, uom_id
    ) values (
      v_tenant, v_dest_site_id, v_dest_lot_id, v_recovered_qty, v_uom_id
    );
  else
    update public.inv_inventory i
       set qty = i.qty + v_recovered_qty
     where i.id = v_dest_inv_id;
  end if;

  if not exists (
    select 1
    from public.inv_inventory i
    where i.tenant_id = v_tenant
      and i.site_id = v_dest_site_id
      and i.lot_id = v_dest_lot_id
      and i.uom_id = v_uom_id
  ) then
    raise exception
      'PU009: unpack destination must land in inv_inventory. dst_site_type=%',
      v_dest_site_type;
  end if;

  perform public._assert_non_negative_lot_qty(v_src_lot_id);

  return v_movement_id;

exception
  when unique_violation then
    if strpos(sqlerrm, 'inv_movements_tenant_id_doc_no_key') > 0 then
      raise exception 'PU010: duplicate doc_no';
    else
      raise;
    end if;
end;
$$;
