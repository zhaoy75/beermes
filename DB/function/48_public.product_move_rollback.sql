create or replace function public.product_move_rollback(p_doc jsonb)
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
  v_target_intent text;
  v_restore_source_inventory boolean;
  v_edge_count int;
  v_line_no int := 0;

  v_edge record;
  v_source_lot_site_id uuid;
  v_source_lot_uom_id uuid;
  v_source_lot_remaining_qty numeric;
  v_source_lot_remaining_unit numeric;
  v_source_inv_remaining numeric;
  v_dest_lot_site_id uuid;
  v_dest_lot_uom_id uuid;
  v_dest_lot_qty numeric;
  v_dest_lot_unit numeric;
  v_dest_lot_remaining_qty numeric;
  v_dest_lot_remaining_unit numeric;
  v_dest_inventory_required boolean;
  v_dest_inv_id uuid;
  v_dest_inv_qty numeric;
  v_dest_inv_remaining numeric;
  v_downstream_movement_id uuid;
begin
  if p_doc is null then
    raise exception 'PMR001: p_doc is required';
  end if;

  v_tenant := public._assert_tenant();

  v_doc_no := nullif(btrim(coalesce(p_doc ->> 'doc_no', '')), '');
  v_requested_movement_at := nullif(p_doc ->> 'movement_at', '')::timestamptz;
  v_movement_at := coalesce(v_requested_movement_at, now());
  v_target_movement_id := coalesce(
    nullif(p_doc ->> 'product_movement_id', '')::uuid,
    nullif(p_doc ->> 'movement_id', '')::uuid
  );
  v_reason := nullif(p_doc ->> 'reason', '');
  v_notes := nullif(p_doc ->> 'notes', '');
  v_meta := coalesce(p_doc -> 'meta', '{}'::jsonb);
  v_idempotency_key := nullif(btrim(coalesce(v_meta ->> 'idempotency_key', '')), '');

  if v_doc_no is null or v_target_movement_id is null then
    raise exception 'PMR001: missing required field';
  end if;

  if not exists (
    select 1
    from pg_enum e
    where e.enumtypid = 'public.inv_doc_type'::regtype
      and e.enumlabel = 'adjustment'
  ) then
    raise exception 'PMR003: inv_doc_type does not support adjustment';
  end if;

  if v_idempotency_key is not null then
    select m.id
      into v_rollback_movement_id
    from public.inv_movements m
    where m.tenant_id = v_tenant
      and m.meta ->> 'idempotency_key' = v_idempotency_key
      and m.doc_type = 'adjustment'::public.inv_doc_type
      and m.meta ->> 'movement_intent' = 'PRODUCT_MOVE_ROLLBACK'
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
    raise exception 'PMR002: target product movement not found';
  end if;

  if v_target_status <> 'posted' then
    raise exception 'PMR003: target movement is not in posted status';
  end if;

  if v_movement_at < v_target_movement_at then
    v_movement_at := v_target_movement_at;
    v_movement_at_adjusted := true;
  end if;

  if nullif(v_target_meta ->> 'reversed_by_movement_id', '') is not null then
    raise exception 'PMR003: target movement is already rolled back';
  end if;

  v_target_intent := coalesce(v_target_meta ->> 'movement_intent', '');
  if v_target_intent in (
    'BREW_PRODUCE',
    'BREW_PRODUCE_ROLLBACK',
    'PACKAGE_FILL',
    'PACKAGE_FILL_ROLLBACK',
    'PACKAGE_UNPACK',
    'PRODUCT_MOVE_ROLLBACK'
  ) then
    raise exception 'PMR003: target movement is not a product_move movement';
  end if;

  select count(*)
    into v_edge_count
  from public.lot_edge e
  where e.tenant_id = v_tenant
    and e.movement_id = v_target_movement_id
    and e.from_lot_id is not null
    and e.edge_type in (
      'MOVE'::public.lot_edge_type,
      'CONSUME'::public.lot_edge_type,
      'SPLIT'::public.lot_edge_type,
      'MERGE'::public.lot_edge_type
    );

  if coalesce(v_edge_count, 0) = 0 then
    raise exception 'PMR004: product movement lot edge not found';
  end if;

  perform public.tax_report_mark_stale_for_movement(v_target_movement_id);

  v_restore_source_inventory := v_target_intent <> 'RETURN_FROM_CUSTOMER';

  for v_edge in
    select
      e.id,
      e.edge_type,
      e.from_lot_id,
      e.to_lot_id,
      e.qty,
      e.uom_id,
      e.notes,
      e.meta,
      ml.material_id,
      ml.package_id,
      ml.batch_id,
      ml.unit,
      ml.tax_rate,
      ml.notes as line_notes
    from public.lot_edge e
    left join public.inv_movement_lines ml
      on ml.tenant_id = e.tenant_id
     and ml.id = e.movement_line_id
    where e.tenant_id = v_tenant
      and e.movement_id = v_target_movement_id
      and e.from_lot_id is not null
      and e.edge_type in (
        'MOVE'::public.lot_edge_type,
        'CONSUME'::public.lot_edge_type,
        'SPLIT'::public.lot_edge_type,
        'MERGE'::public.lot_edge_type
      )
    order by e.created_at, e.id
  loop
    select l.site_id, l.uom_id
      into v_source_lot_site_id, v_source_lot_uom_id
    from public.lot l
    where l.tenant_id = v_tenant
      and l.id = v_edge.from_lot_id
    for update;

    if not found then
      raise exception 'PMR004: source lot not found for target movement';
    end if;

    v_source_lot_site_id := coalesce(v_source_lot_site_id, v_target_src_site_id);
    if v_source_lot_site_id is null or v_source_lot_uom_id is distinct from v_edge.uom_id then
      raise exception 'PMR004: source lot site/uom mismatch';
    end if;

    if v_edge.to_lot_id is not null then
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
        raise exception 'PMR005: rollback blocked by downstream movements'
          using detail = jsonb_build_object(
            'lot_id', v_edge.to_lot_id,
            'downstream_movement_id', v_downstream_movement_id
          )::text;
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
        raise exception 'PMR005: rollback blocked by downstream movements'
          using detail = jsonb_build_object(
            'lot_id', v_edge.to_lot_id,
            'downstream_movement_id', v_downstream_movement_id
          )::text;
      end if;

      select l.qty, l.unit, l.site_id, l.uom_id
        into v_dest_lot_qty, v_dest_lot_unit, v_dest_lot_site_id, v_dest_lot_uom_id
      from public.lot l
      where l.tenant_id = v_tenant
        and l.id = v_edge.to_lot_id
      for update;

      if not found then
        raise exception 'PMR004: destination lot not found for target movement';
      end if;

      v_dest_lot_site_id := coalesce(v_dest_lot_site_id, v_target_dest_site_id);
      if v_dest_lot_site_id is null or v_dest_lot_uom_id is distinct from v_edge.uom_id then
        raise exception 'PMR004: destination lot site/uom mismatch';
      end if;

      if coalesce(v_dest_lot_qty, 0) < v_edge.qty then
        raise exception 'PMR006: destination lot quantity is insufficient';
      end if;

      if v_edge.unit is not null and coalesce(v_dest_lot_unit, 0) < v_edge.unit then
        raise exception 'PMR006: destination lot unit is insufficient';
      end if;

      select coalesce((r.spec ->> 'inventory_count_flg')::boolean, true) = true
        into v_dest_inventory_required
      from public.mst_sites s
      join public.registry_def r
        on r.def_id = s.site_type_id
       and r.kind = 'site_type'
       and r.is_active = true
      where s.tenant_id = v_tenant
        and s.id = v_dest_lot_site_id;

      if not found then
        v_dest_inventory_required := false;
      end if;

      if v_dest_inventory_required then
        v_dest_inv_id := null;
        v_dest_inv_qty := null;
        select i.id, i.qty
          into v_dest_inv_id, v_dest_inv_qty
        from public.inv_inventory i
        where i.tenant_id = v_tenant
          and i.site_id = v_dest_lot_site_id
          and i.lot_id = v_edge.to_lot_id
          and i.uom_id = v_edge.uom_id
        order by i.created_at, i.id
        limit 1
        for update;

        if v_dest_inv_id is null then
          raise exception 'PMR006: destination inventory is insufficient';
        end if;

        if coalesce(v_dest_inv_qty, 0) < v_edge.qty then
          raise exception 'PMR006: destination inventory is insufficient';
        end if;
      end if;
    end if;
  end loop;

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
    v_target_src_site_id,
    v_reason,
    v_meta || jsonb_strip_nulls(jsonb_build_object(
      'movement_intent', 'PRODUCT_MOVE_ROLLBACK',
      'rollback_of_movement_id', v_target_movement_id,
      'rollback_of_doc_type', v_target_doc_type::text,
      'rollback_of_movement_intent', v_target_intent,
      'rollback_requested_movement_at', v_requested_movement_at,
      'rollback_effective_at_adjusted', case when v_movement_at_adjusted then true else null end
    )),
    v_notes
  )
  returning id into v_rollback_movement_id;

  for v_edge in
    select
      e.id,
      e.edge_type,
      e.from_lot_id,
      e.to_lot_id,
      e.qty,
      e.uom_id,
      e.notes,
      e.meta,
      ml.material_id,
      ml.package_id,
      ml.batch_id,
      ml.unit,
      ml.tax_rate,
      ml.notes as line_notes
    from public.lot_edge e
    left join public.inv_movement_lines ml
      on ml.tenant_id = e.tenant_id
     and ml.id = e.movement_line_id
    where e.tenant_id = v_tenant
      and e.movement_id = v_target_movement_id
      and e.from_lot_id is not null
      and e.edge_type in (
        'MOVE'::public.lot_edge_type,
        'CONSUME'::public.lot_edge_type,
        'SPLIT'::public.lot_edge_type,
        'MERGE'::public.lot_edge_type
      )
    order by e.created_at, e.id
  loop
    v_line_no := v_line_no + 1;

    select l.site_id, l.uom_id
      into v_source_lot_site_id, v_source_lot_uom_id
    from public.lot l
    where l.tenant_id = v_tenant
      and l.id = v_edge.from_lot_id;

    v_source_lot_site_id := coalesce(v_source_lot_site_id, v_target_src_site_id);

    insert into public.inv_movement_lines (
      tenant_id, movement_id, line_no,
      material_id, package_id, batch_id, qty, unit, tax_rate, uom_id, notes, meta
    ) values (
      v_tenant,
      v_rollback_movement_id,
      v_line_no,
      coalesce(v_edge.material_id, v_zero_material_id),
      v_edge.package_id,
      v_edge.batch_id,
      v_edge.qty,
      v_edge.unit,
      v_edge.tax_rate,
      v_edge.uom_id,
      coalesce(v_notes, v_edge.line_notes, v_edge.notes),
      jsonb_build_object(
        'line_role', 'PRODUCT_MOVE_ROLLBACK',
        'rollback_of_movement_id', v_target_movement_id,
        'rollback_of_edge_id', v_edge.id,
        'rollback_of_from_lot_id', v_edge.from_lot_id,
        'rollback_of_to_lot_id', v_edge.to_lot_id
      )
    )
    returning id into v_rollback_line_id;

    -- Keep product-move rollback out of lot DAG creation paths. The audit link is
    -- stored on the rollback movement line so lot_effective_created_at is not skewed.
    if v_edge.to_lot_id is not null then
      select l.site_id
        into v_dest_lot_site_id
      from public.lot l
      where l.tenant_id = v_tenant
        and l.id = v_edge.to_lot_id;

      v_dest_lot_site_id := coalesce(v_dest_lot_site_id, v_target_dest_site_id);

      select coalesce((r.spec ->> 'inventory_count_flg')::boolean, true) = true
        into v_dest_inventory_required
      from public.mst_sites s
      join public.registry_def r
        on r.def_id = s.site_type_id
       and r.kind = 'site_type'
       and r.is_active = true
      where s.tenant_id = v_tenant
        and s.id = v_dest_lot_site_id;

      if not found then
        v_dest_inventory_required := false;
      end if;

      if v_dest_inventory_required then
        v_dest_inv_id := null;
        v_dest_inv_qty := null;
        select i.id, i.qty
          into v_dest_inv_id, v_dest_inv_qty
        from public.inv_inventory i
        where i.tenant_id = v_tenant
          and i.site_id = v_dest_lot_site_id
          and i.lot_id = v_edge.to_lot_id
          and i.uom_id = v_edge.uom_id
        order by i.created_at, i.id
        limit 1
        for update;

        if v_dest_inv_id is null then
          raise exception 'PMR006: destination inventory is insufficient after update';
        end if;

        if coalesce(v_dest_inv_qty, 0) < v_edge.qty then
          raise exception 'PMR006: destination inventory is insufficient after update';
        end if;

        update public.inv_inventory i
           set qty = i.qty - v_edge.qty
         where i.id = v_dest_inv_id
        returning i.qty into v_dest_inv_remaining;

        if v_dest_inv_remaining < 0 then
          raise exception 'PMR006: destination inventory is insufficient after update';
        end if;
      end if;

      update public.lot l
         set qty = l.qty - v_edge.qty,
             unit = case
               when v_edge.unit is not null then coalesce(l.unit, 0) - v_edge.unit
               else l.unit
             end,
             status = case when l.qty - v_edge.qty <= 0 then 'void' else l.status end,
             updated_at = now()
       where l.tenant_id = v_tenant
         and l.id = v_edge.to_lot_id
      returning l.qty, l.unit into v_dest_lot_remaining_qty, v_dest_lot_remaining_unit;

      if v_dest_lot_remaining_qty < 0 then
        raise exception 'PMR006: destination lot quantity is insufficient after update';
      end if;

      if v_edge.unit is not null and coalesce(v_dest_lot_remaining_unit, 0) < 0 then
        raise exception 'PMR006: destination lot unit is insufficient after update';
      end if;

      perform public._assert_non_negative_lot_qty(v_edge.to_lot_id);
    end if;

    if v_restore_source_inventory then
      update public.inv_inventory i
         set qty = i.qty + v_edge.qty
       where i.tenant_id = v_tenant
         and i.site_id = v_source_lot_site_id
         and i.lot_id = v_edge.from_lot_id
         and i.uom_id = v_edge.uom_id
      returning i.qty into v_source_inv_remaining;

      if not found then
        insert into public.inv_inventory (
          tenant_id, site_id, lot_id, qty, uom_id
        ) values (
          v_tenant, v_source_lot_site_id, v_edge.from_lot_id, v_edge.qty, v_edge.uom_id
        );
      end if;
    end if;

    update public.lot l
       set qty = l.qty + v_edge.qty,
           unit = case
             when v_edge.unit is not null then coalesce(l.unit, 0) + v_edge.unit
             else l.unit
           end,
           status = case
             when l.status = 'consumed' and l.qty + v_edge.qty > 0 then 'active'
             else l.status
           end,
           updated_at = now()
     where l.tenant_id = v_tenant
       and l.id = v_edge.from_lot_id
    returning l.qty, l.unit into v_source_lot_remaining_qty, v_source_lot_remaining_unit;

    if v_source_lot_remaining_qty < 0 then
      raise exception 'PMR006: source lot quantity is invalid after rollback';
    end if;

    if v_edge.unit is not null and coalesce(v_source_lot_remaining_unit, 0) < 0 then
      raise exception 'PMR006: source lot unit is invalid after rollback';
    end if;

    perform public._assert_non_negative_lot_qty(v_edge.from_lot_id);
  end loop;

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

  return v_rollback_movement_id;

exception
  when unique_violation then
    if strpos(sqlerrm, 'inv_movements_tenant_id_doc_no_key') > 0 then
      raise exception 'PMR007: duplicate doc_no';
    else
      raise;
    end if;
end;
$$;
comment on function public.product_move_rollback(jsonb) is '{"version":1}';
