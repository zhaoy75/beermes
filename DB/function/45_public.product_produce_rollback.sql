create or replace function public.product_produce_rollback(p_doc jsonb)
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
  v_reason text;
  v_notes text;
  v_meta jsonb;
  v_idempotency_key text;
  v_zero_material_id uuid := '00000000-0000-0000-0000-000000000000'::uuid;

  v_target_status text;
  v_target_meta jsonb;
  v_target_src_site_id uuid;
  v_target_dest_site_id uuid;

  v_produced_lot_id uuid;
  v_produced_qty numeric;
  v_produced_uom_id uuid;
  v_produced_site_id uuid;
  v_produced_batch_id uuid;
  v_lot_remaining_qty numeric;

  v_source_inv_id uuid;
  v_source_inv_qty numeric;
  v_source_inv_remaining numeric;

  v_downstream_movement_id uuid;
begin
  if p_doc is null then
    raise exception 'PPR001: p_doc is required';
  end if;

  v_tenant := public._assert_tenant();

  v_doc_no := nullif(btrim(coalesce(p_doc ->> 'doc_no', '')), '');
  v_movement_at := coalesce(nullif(p_doc ->> 'movement_at', '')::timestamptz, now());
  v_target_movement_id := nullif(p_doc ->> 'produce_movement_id', '')::uuid;
  v_reason := nullif(p_doc ->> 'reason', '');
  v_notes := nullif(p_doc ->> 'notes', '');
  v_meta := coalesce(p_doc -> 'meta', '{}'::jsonb);
  v_idempotency_key := nullif(btrim(coalesce(v_meta ->> 'idempotency_key', '')), '');

  if v_doc_no is null or v_target_movement_id is null then
    raise exception 'PPR001: missing required field';
  end if;

  if not exists (
    select 1
    from pg_enum e
    where e.enumtypid = 'public.inv_doc_type'::regtype
      and e.enumlabel = 'adjustment'
  ) then
    raise exception 'PPR003: inv_doc_type does not support adjustment';
  end if;

  if v_idempotency_key is not null then
    select m.id
      into v_rollback_movement_id
    from public.inv_movements m
    where m.tenant_id = v_tenant
      and m.meta ->> 'idempotency_key' = v_idempotency_key
      and m.doc_type = 'adjustment'::public.inv_doc_type
      and m.meta ->> 'movement_intent' = 'BREW_PRODUCE_ROLLBACK'
    order by m.created_at desc
    limit 1;

    if v_rollback_movement_id is not null then
      return v_rollback_movement_id;
    end if;
  end if;

  select m.status, m.meta, m.src_site_id, m.dest_site_id
    into v_target_status, v_target_meta, v_target_src_site_id, v_target_dest_site_id
  from public.inv_movements m
  where m.tenant_id = v_tenant
    and m.id = v_target_movement_id
  for update;

  if not found then
    raise exception 'PPR002: target produce movement not found';
  end if;

  if v_target_status <> 'posted' then
    raise exception 'PPR003: target movement is not in posted status';
  end if;

  if coalesce(v_target_meta ->> 'movement_intent', '') <> 'BREW_PRODUCE' then
    raise exception 'PPR003: target movement is not a BREW_PRODUCE movement';
  end if;

  if nullif(v_target_meta ->> 'reversed_by_movement_id', '') is not null then
    raise exception 'PPR003: target movement is already rolled back';
  end if;

  select e.to_lot_id
    into v_produced_lot_id
  from public.lot_edge e
  where e.tenant_id = v_tenant
    and e.movement_id = v_target_movement_id
    and e.edge_type = 'PRODUCE'::public.lot_edge_type
    and e.from_lot_id is null
  order by e.created_at, e.id
  limit 1;

  if v_produced_lot_id is null then
    raise exception 'PPR004: produced lot/edge not found for target movement';
  end if;

  select l.qty, l.uom_id, l.site_id, l.batch_id
    into v_produced_qty, v_produced_uom_id, v_produced_site_id, v_produced_batch_id
  from public.lot l
  where l.tenant_id = v_tenant
    and l.id = v_produced_lot_id
  for update;

  if not found then
    raise exception 'PPR004: produced lot not found';
  end if;

  v_produced_site_id := coalesce(v_produced_site_id, v_target_dest_site_id, v_target_src_site_id);
  if v_produced_site_id is null then
    raise exception 'PPR004: produced lot site is missing';
  end if;

  if coalesce(v_produced_qty, 0) <= 0 then
    raise exception 'PPR006: produced lot quantity is not positive';
  end if;

  select i.id, i.qty
    into v_source_inv_id, v_source_inv_qty
  from public.inv_inventory i
  where i.tenant_id = v_tenant
    and i.site_id = v_produced_site_id
    and i.lot_id = v_produced_lot_id
    and i.uom_id = v_produced_uom_id
  order by i.created_at, i.id
  limit 1
  for update;

  if v_source_inv_id is null or coalesce(v_source_inv_qty, 0) < v_produced_qty then
    raise exception 'PPR006: produced lot inventory is insufficient';
  end if;

  select e.movement_id
    into v_downstream_movement_id
  from public.lot_edge e
  join public.inv_movements m
    on m.tenant_id = v_tenant
   and m.id = e.movement_id
  where e.tenant_id = v_tenant
    and e.from_lot_id = v_produced_lot_id
    and m.status <> 'void'
  limit 1;

  if v_downstream_movement_id is not null then
    raise exception 'PPR005: rollback blocked by downstream movements';
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
    v_produced_site_id,
    null,
    v_reason,
    v_meta || jsonb_build_object(
      'movement_intent', 'BREW_PRODUCE_ROLLBACK',
      'rollback_of_movement_id', v_target_movement_id,
      'rollback_of_lot_id', v_produced_lot_id
    ),
    v_notes
  )
  returning id into v_rollback_movement_id;

  insert into public.inv_movement_lines (
    tenant_id, movement_id, line_no,
    material_id, batch_id, qty, uom_id, notes, meta
  ) values (
    v_tenant,
    v_rollback_movement_id,
    1,
    v_zero_material_id,
    v_produced_batch_id,
    v_produced_qty,
    v_produced_uom_id,
    v_notes,
    jsonb_build_object(
      'line_role', 'ROLLBACK',
      'rollback_of_movement_id', v_target_movement_id,
      'rollback_of_lot_id', v_produced_lot_id
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
    'CONSUME'::public.lot_edge_type,
    v_produced_lot_id,
    null,
    v_produced_qty,
    v_produced_uom_id,
    v_notes,
    v_meta || jsonb_build_object(
      'movement_intent', 'BREW_PRODUCE_ROLLBACK',
      'rollback_of_movement_id', v_target_movement_id
    )
  );

  update public.inv_inventory i
     set qty = i.qty - v_produced_qty
   where i.id = v_source_inv_id
  returning i.qty into v_source_inv_remaining;

  if v_source_inv_remaining < 0 then
    raise exception 'PPR006: produced lot inventory is insufficient after update';
  end if;

  update public.lot l
     set qty = l.qty - v_produced_qty,
         status = case when l.qty - v_produced_qty <= 0 then 'void' else l.status end,
         updated_at = now()
   where l.tenant_id = v_tenant
     and l.id = v_produced_lot_id
  returning l.qty into v_lot_remaining_qty;

  if v_lot_remaining_qty < 0 then
    raise exception 'PPR006: produced lot quantity is insufficient after update';
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

  perform public._assert_non_negative_lot_qty(v_produced_lot_id);

  return v_rollback_movement_id;

exception
  when unique_violation then
    if strpos(sqlerrm, 'inv_movements_tenant_id_doc_no_key') > 0 then
      raise exception 'PPR007: duplicate doc_no';
    else
      raise;
    end if;
end;
$$;
