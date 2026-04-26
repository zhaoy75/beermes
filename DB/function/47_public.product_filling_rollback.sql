create or replace function public.product_filling_rollback(p_doc jsonb)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_rollback_movement_id uuid;
  v_rollback_line_id uuid;
  v_target_movement_id uuid;
  v_doc_no text;
  v_movement_at timestamptz;
  v_requested_movement_at timestamptz;
  v_movement_at_adjusted boolean := false;
  v_reason text;
  v_notes text;
  v_meta jsonb;
  v_idempotency_key text;
  v_zero_material_id uuid := '00000000-0000-0000-0000-000000000000'::uuid;

  v_target_status text;
  v_target_meta jsonb;
  v_target_src_site_id uuid;
  v_target_dest_site_id uuid;
  v_target_doc_type public.inv_doc_type;
  v_target_movement_at timestamptz;
  v_source_lot_id uuid;
  v_source_uom_id uuid;
  v_source_site_id uuid;
  v_source_remaining_qty numeric;
  v_source_lot_count int;
  v_loss_qty numeric := 0;
  v_total_restore_qty numeric := 0;
  v_source_inv_remaining numeric;
  v_line_no int := 0;

  v_edge record;
  v_filled_lot_qty numeric;
  v_filled_lot_site_id uuid;
  v_filled_lot_uom_id uuid;
  v_filled_lot_material_id uuid;
  v_filled_lot_package_id uuid;
  v_filled_lot_batch_id uuid;
  v_filled_lot_remaining_qty numeric;
  v_filled_inv_id uuid;
  v_filled_inv_qty numeric;
  v_filled_inv_remaining numeric;
  v_downstream_movement_id uuid;
begin
  if p_doc is null then
    raise exception 'PFR001: p_doc is required';
  end if;

  v_tenant := public._assert_tenant();

  v_doc_no := nullif(btrim(coalesce(p_doc ->> 'doc_no', '')), '');
  v_requested_movement_at := nullif(p_doc ->> 'movement_at', '')::timestamptz;
  v_movement_at := coalesce(v_requested_movement_at, now());
  v_target_movement_id := nullif(p_doc ->> 'filling_movement_id', '')::uuid;
  v_reason := nullif(p_doc ->> 'reason', '');
  v_notes := nullif(p_doc ->> 'notes', '');
  v_meta := coalesce(p_doc -> 'meta', '{}'::jsonb);
  v_idempotency_key := nullif(btrim(coalesce(v_meta ->> 'idempotency_key', '')), '');

  if v_doc_no is null or v_target_movement_id is null then
    raise exception 'PFR001: missing required field';
  end if;

  if not exists (
    select 1
    from pg_enum e
    where e.enumtypid = 'public.inv_doc_type'::regtype
      and e.enumlabel = 'adjustment'
  ) then
    raise exception 'PFR003: inv_doc_type does not support adjustment';
  end if;

  if v_idempotency_key is not null then
    select m.id
      into v_rollback_movement_id
    from public.inv_movements m
    where m.tenant_id = v_tenant
      and m.meta ->> 'idempotency_key' = v_idempotency_key
      and m.doc_type = 'adjustment'::public.inv_doc_type
      and m.meta ->> 'movement_intent' = 'PACKAGE_FILL_ROLLBACK'
    order by m.created_at desc
    limit 1;

    if v_rollback_movement_id is not null then
      return v_rollback_movement_id;
    end if;
  end if;

  select m.status, m.meta, m.src_site_id, m.dest_site_id, m.doc_type, m.movement_at
    into v_target_status, v_target_meta, v_target_src_site_id, v_target_dest_site_id,
         v_target_doc_type, v_target_movement_at
  from public.inv_movements m
  where m.tenant_id = v_tenant
    and m.id = v_target_movement_id
  for update;

  if not found then
    raise exception 'PFR002: target filling movement not found';
  end if;

  if v_target_status <> 'posted' then
    raise exception 'PFR003: target movement is not in posted status';
  end if;

  if coalesce(v_target_meta ->> 'movement_intent', '') <> 'PACKAGE_FILL' then
    raise exception 'PFR003: target movement is not a PACKAGE_FILL movement';
  end if;

  if nullif(v_target_meta ->> 'reversed_by_movement_id', '') is not null then
    raise exception 'PFR003: target movement is already rolled back';
  end if;

  if v_movement_at < v_target_movement_at then
    v_movement_at := v_target_movement_at;
    v_movement_at_adjusted := true;
  end if;

  select count(distinct e.from_lot_id)
    into v_source_lot_count
  from public.lot_edge e
  where e.tenant_id = v_tenant
    and e.movement_id = v_target_movement_id
    and e.edge_type = 'SPLIT'::public.lot_edge_type
    and e.from_lot_id is not null
    and e.to_lot_id is not null;

  if coalesce(v_source_lot_count, 0) <> 1 then
    raise exception 'PFR004: source lot/edge not found for target movement';
  end if;

  select e.from_lot_id, e.uom_id
    into v_source_lot_id, v_source_uom_id
  from public.lot_edge e
  where e.tenant_id = v_tenant
    and e.movement_id = v_target_movement_id
    and e.edge_type = 'SPLIT'::public.lot_edge_type
    and e.from_lot_id is not null
    and e.to_lot_id is not null
  order by e.created_at, e.id
  limit 1;

  if v_source_lot_id is null then
    raise exception 'PFR004: source lot/edge not found for target movement';
  end if;

  select l.site_id, l.uom_id
    into v_source_site_id, v_source_uom_id
  from public.lot l
  where l.tenant_id = v_tenant
    and l.id = v_source_lot_id
  for update;

  v_source_site_id := coalesce(v_source_site_id, v_target_src_site_id);
  if v_source_site_id is null or v_source_uom_id is null then
    raise exception 'PFR004: source lot site/uom is missing';
  end if;

  select coalesce(sum(l.qty), 0)
    into v_loss_qty
  from public.inv_movement_lines l
  where l.tenant_id = v_tenant
    and l.movement_id = v_target_movement_id
    and l.meta ->> 'line_role' = 'LOSS';

  for v_edge in
    select e.id, e.to_lot_id, e.qty, e.uom_id, e.notes, e.meta
    from public.lot_edge e
    where e.tenant_id = v_tenant
      and e.movement_id = v_target_movement_id
      and e.edge_type = 'SPLIT'::public.lot_edge_type
      and e.from_lot_id = v_source_lot_id
      and e.to_lot_id is not null
    order by e.created_at, e.id
  loop
    select m.id
      into v_downstream_movement_id
    from public.lot_edge e
    join public.inv_movements m
      on m.tenant_id = v_tenant
     and m.id = e.movement_id
    where e.tenant_id = v_tenant
      and e.from_lot_id = v_edge.to_lot_id
      and e.movement_id <> v_target_movement_id
      and m.status <> 'void'
    limit 1;

    if v_downstream_movement_id is not null then
      raise exception 'PFR005: rollback blocked by downstream movements';
    end if;

    select m.id
      into v_downstream_movement_id
    from public.inv_movement_lines line
    join public.inv_movements m
      on m.tenant_id = line.tenant_id
     and m.id = line.movement_id
    where line.tenant_id = v_tenant
      and line.movement_id <> v_target_movement_id
      and m.status <> 'void'
      and (
        line.meta ->> 'src_lot_id' = v_edge.to_lot_id::text
        or line.meta ->> 'source_lot_id' = v_edge.to_lot_id::text
        or line.meta ->> 'lot_id' = v_edge.to_lot_id::text
      )
    limit 1;

    if v_downstream_movement_id is not null then
      raise exception 'PFR005: rollback blocked by downstream movements';
    end if;

    select l.qty, l.site_id, l.uom_id, l.material_id, l.package_id, l.batch_id
      into v_filled_lot_qty, v_filled_lot_site_id, v_filled_lot_uom_id,
           v_filled_lot_material_id, v_filled_lot_package_id, v_filled_lot_batch_id
    from public.lot l
    where l.tenant_id = v_tenant
      and l.id = v_edge.to_lot_id
    for update;

    if not found then
      raise exception 'PFR004: filled lot not found';
    end if;

    if v_filled_lot_site_id is null or v_filled_lot_uom_id is distinct from v_edge.uom_id then
      raise exception 'PFR004: filled lot site/uom mismatch';
    end if;

    if coalesce(v_filled_lot_qty, 0) < v_edge.qty then
      raise exception 'PFR006: filled lot quantity is insufficient';
    end if;

    select i.id, i.qty
      into v_filled_inv_id, v_filled_inv_qty
    from public.inv_inventory i
    where i.tenant_id = v_tenant
      and i.site_id = v_filled_lot_site_id
      and i.lot_id = v_edge.to_lot_id
      and i.uom_id = v_edge.uom_id
    order by i.created_at, i.id
    limit 1
    for update;

    if v_filled_inv_id is null or coalesce(v_filled_inv_qty, 0) < v_edge.qty then
      raise exception 'PFR006: filled lot inventory is insufficient';
    end if;

    v_total_restore_qty := v_total_restore_qty + v_edge.qty;
  end loop;

  v_total_restore_qty := v_total_restore_qty + coalesce(v_loss_qty, 0);
  if v_total_restore_qty <= 0 then
    raise exception 'PFR006: rollback quantity is not positive';
  end if;

  insert into public.inv_movements (
    tenant_id, doc_no, doc_type, status, movement_at,
    src_site_id, dest_site_id, reason, meta, notes
  ) values (
    v_tenant,
    v_doc_no,
    'adjustment'::public.inv_doc_type,
    'posted',
    v_movement_at,
    v_target_dest_site_id,
    v_source_site_id,
    v_reason,
    v_meta || jsonb_strip_nulls(jsonb_build_object(
      'movement_intent', 'PACKAGE_FILL_ROLLBACK',
      'rollback_of_movement_id', v_target_movement_id,
      'rollback_of_doc_type', v_target_doc_type,
      'rollback_requested_movement_at', v_requested_movement_at,
      'rollback_effective_at_adjusted', case when v_movement_at_adjusted then true else null end
    )),
    v_notes
  )
  returning id into v_rollback_movement_id;

  for v_edge in
    select e.id, e.to_lot_id, e.qty, e.uom_id, e.notes, e.meta
    from public.lot_edge e
    where e.tenant_id = v_tenant
      and e.movement_id = v_target_movement_id
      and e.edge_type = 'SPLIT'::public.lot_edge_type
      and e.from_lot_id = v_source_lot_id
      and e.to_lot_id is not null
    order by e.created_at, e.id
  loop
    v_line_no := v_line_no + 1;

    select l.site_id, l.material_id, l.package_id, l.batch_id
      into v_filled_lot_site_id, v_filled_lot_material_id, v_filled_lot_package_id, v_filled_lot_batch_id
    from public.lot l
    where l.tenant_id = v_tenant
      and l.id = v_edge.to_lot_id;

    insert into public.inv_movement_lines (
      tenant_id, movement_id, line_no,
      material_id, package_id, batch_id, qty, uom_id, notes, meta
    ) values (
      v_tenant,
      v_rollback_movement_id,
      v_line_no,
      coalesce(v_filled_lot_material_id, v_zero_material_id),
      v_filled_lot_package_id,
      v_filled_lot_batch_id,
      v_edge.qty,
      v_edge.uom_id,
      v_notes,
      jsonb_build_object(
        'line_role', 'FILLING_ROLLBACK',
        'rollback_of_movement_id', v_target_movement_id,
        'rollback_of_filled_lot_id', v_edge.to_lot_id,
        'restore_to_source_lot_id', v_source_lot_id
      )
    )
    returning id into v_rollback_line_id;

    insert into public.lot_edge (
      tenant_id, movement_id, movement_line_id, edge_type,
      from_lot_id, to_lot_id, qty, uom_id, notes, meta
    ) values (
      v_tenant,
      v_rollback_movement_id,
      v_rollback_line_id,
      'MERGE'::public.lot_edge_type,
      v_edge.to_lot_id,
      v_source_lot_id,
      v_edge.qty,
      v_edge.uom_id,
      v_notes,
      v_meta || jsonb_build_object(
        'movement_intent', 'PACKAGE_FILL_ROLLBACK',
        'rollback_of_movement_id', v_target_movement_id,
        'rollback_of_edge_id', v_edge.id
      )
    );

    update public.inv_inventory i
       set qty = i.qty - v_edge.qty
     where i.tenant_id = v_tenant
       and i.site_id = v_filled_lot_site_id
       and i.lot_id = v_edge.to_lot_id
       and i.uom_id = v_edge.uom_id
    returning i.qty into v_filled_inv_remaining;

    if v_filled_inv_remaining < 0 then
      raise exception 'PFR006: filled lot inventory is insufficient after update';
    end if;

    update public.lot l
       set qty = l.qty - v_edge.qty,
           status = case when l.qty - v_edge.qty <= 0 then 'void' else l.status end,
           updated_at = now()
     where l.tenant_id = v_tenant
       and l.id = v_edge.to_lot_id
    returning l.qty into v_filled_lot_remaining_qty;

    if v_filled_lot_remaining_qty < 0 then
      raise exception 'PFR006: filled lot quantity is insufficient after update';
    end if;

    perform public._assert_non_negative_lot_qty(v_edge.to_lot_id);
  end loop;

  if v_loss_qty > 0 then
    v_line_no := v_line_no + 1;

    insert into public.inv_movement_lines (
      tenant_id, movement_id, line_no,
      material_id, batch_id, qty, uom_id, notes, meta
    ) values (
      v_tenant,
      v_rollback_movement_id,
      v_line_no,
      v_zero_material_id,
      null,
      v_loss_qty,
      v_source_uom_id,
      v_notes,
      jsonb_build_object(
        'line_role', 'FILLING_LOSS_ROLLBACK',
        'rollback_of_movement_id', v_target_movement_id,
        'restore_to_source_lot_id', v_source_lot_id
      )
    );
  end if;

  update public.inv_inventory i
     set qty = i.qty + v_total_restore_qty
   where i.tenant_id = v_tenant
     and i.site_id = v_source_site_id
     and i.lot_id = v_source_lot_id
     and i.uom_id = v_source_uom_id
  returning i.qty into v_source_inv_remaining;

  if not found then
    insert into public.inv_inventory (
      tenant_id, site_id, lot_id, qty, uom_id
    ) values (
      v_tenant, v_source_site_id, v_source_lot_id, v_total_restore_qty, v_source_uom_id
    )
    returning qty into v_source_inv_remaining;
  end if;

  update public.lot l
     set qty = l.qty + v_total_restore_qty,
         status = case
           when l.status = 'consumed' and l.qty + v_total_restore_qty > 0 then 'active'
           else l.status
         end,
         updated_at = now()
   where l.tenant_id = v_tenant
     and l.id = v_source_lot_id
  returning l.qty into v_source_remaining_qty;

  if v_source_remaining_qty < 0 then
    raise exception 'PFR006: source lot quantity is invalid after rollback';
  end if;

  update public.inv_movements m
     set status = 'void',
         reason = coalesce(v_reason, m.reason),
         notes = coalesce(v_notes, m.notes),
         meta = coalesce(m.meta, '{}'::jsonb) || jsonb_strip_nulls(jsonb_build_object(
           'voided_at', now(),
           'void_reason', coalesce(v_reason, m.reason),
           'reversed_by_movement_id', v_rollback_movement_id
         ))
   where m.tenant_id = v_tenant
     and m.id = v_target_movement_id;

  perform public._assert_non_negative_lot_qty(v_source_lot_id);

  return v_rollback_movement_id;

exception
  when unique_violation then
    if strpos(sqlerrm, 'inv_movements_tenant_id_doc_no_key') > 0 then
      raise exception 'PFR007: duplicate doc_no';
    else
      raise;
    end if;
end;
$$;
