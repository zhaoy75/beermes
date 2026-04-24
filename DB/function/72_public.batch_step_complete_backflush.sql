create or replace function public.batch_step_complete_backflush(
  p_batch_step_id uuid,
  p_patch jsonb default '{}'::jsonb
)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_actor_user_id uuid;
  v_patch jsonb;
  v_patch_status text;
  v_started_at timestamptz;
  v_ended_at timestamptz;
  v_notes text;
  v_actual_params jsonb;
  v_quality_checks_json jsonb;
  v_auto_ready_next_step boolean;
  v_reason text;
  v_batch_id uuid;
  v_batch_code text;
  v_batch_meta jsonb;
  v_step_no integer;
  v_step_code text;
  v_step_status text;
  v_patch_source_site_text text;
  v_patch_source_site_id uuid;
  v_source_site_id uuid;
  v_source_site_text text;
  v_existing_movement_id uuid;
  v_existing_movement_site_id uuid;
  v_existing_consumed_lines jsonb;
  v_has_backflush boolean := false;
  v_has_exact boolean := false;
  v_mode text;
  v_positive_actual_rows integer := 0;
  v_doc_no text;
  v_movement_id uuid;
  v_line_no integer := 0;
  v_consumed_lines jsonb := '[]'::jsonb;
  v_next_step_id uuid;
  v_next_step_status text;
  v_current_actual_qty numeric;
  v_current_uom_id uuid;
  v_current_material_id uuid;
  v_current_lot_id uuid;
  v_current_actual_id uuid;
  v_remaining_qty numeric;
  v_explicit_lot_no text;
  v_explicit_lot_site_id uuid;
  v_explicit_lot_material_id uuid;
  v_explicit_lot_uom_id uuid;
  v_explicit_lot_status text;
  v_explicit_lot_qty numeric;
  v_explicit_inventory_id uuid;
  v_explicit_inventory_qty numeric;
  v_candidate_lot_ids uuid[];
  v_candidate_lot_id uuid;
  v_candidate_lot_no text;
  v_candidate_lot_qty numeric;
  v_candidate_inventory_id uuid;
  v_candidate_inventory_qty numeric;
  v_candidate_take_qty numeric;
  v_inventory_remaining numeric;
  v_lot_remaining numeric;
begin
  if p_batch_step_id is null then
    raise exception 'BSBC001: p_batch_step_id is required';
  end if;

  v_tenant := public._assert_tenant();
  v_actor_user_id := auth.uid();
  v_patch := coalesce(p_patch, '{}'::jsonb);

  if jsonb_typeof(v_patch) <> 'object' then
    raise exception 'BSBC002: p_patch must be a JSON object';
  end if;

  v_patch_status := nullif(btrim(coalesce(v_patch ->> 'status', '')), '');
  if v_patch_status is not null and v_patch_status <> 'completed' then
    raise exception 'BSBC003: status must be completed';
  end if;

  select
    s.batch_id,
    s.step_no,
    s.step_code,
    s.status::text,
    s.started_at,
    s.ended_at,
    s.notes,
    s.actual_params,
    s.quality_checks_json,
    b.batch_code,
    coalesce(b.meta, '{}'::jsonb)
    into
      v_batch_id,
      v_step_no,
      v_step_code,
      v_step_status,
      v_started_at,
      v_ended_at,
      v_notes,
      v_actual_params,
      v_quality_checks_json,
      v_batch_code,
      v_batch_meta
  from mes.batch_step s
  join public.mes_batches b
    on b.id = s.batch_id
   and b.tenant_id = s.tenant_id
  where s.tenant_id = v_tenant
    and s.id = p_batch_step_id
  for update of s;

  if not found then
    raise exception 'BSBC004: batch step not found';
  end if;

  if v_step_status in ('skipped', 'cancelled') then
    raise exception 'BSBC005: step status % cannot be completed', v_step_status;
  end if;

  if v_patch ? 'started_at' then
    v_source_site_text := nullif(btrim(coalesce(v_patch ->> 'started_at', '')), '');
    v_started_at := case when v_source_site_text is null then null else v_source_site_text::timestamptz end;
  end if;

  if v_patch ? 'ended_at' then
    v_source_site_text := nullif(btrim(coalesce(v_patch ->> 'ended_at', '')), '');
    v_ended_at := case when v_source_site_text is null then null else v_source_site_text::timestamptz end;
  end if;
  v_ended_at := coalesce(v_ended_at, now());

  if v_patch ? 'notes' then
    v_notes := nullif(v_patch ->> 'notes', '');
  end if;

  if v_patch ? 'source_site_id' then
    v_patch_source_site_text := nullif(btrim(coalesce(v_patch ->> 'source_site_id', '')), '');
    v_patch_source_site_id := case
      when v_patch_source_site_text is null then null
      else v_patch_source_site_text::uuid
    end;
  end if;

  if v_patch ? 'actual_params' then
    if coalesce(jsonb_typeof(v_patch -> 'actual_params'), 'null') not in ('object', 'null') then
      raise exception 'BSBC006: actual_params must be a JSON object';
    end if;
    v_actual_params := coalesce(v_patch -> 'actual_params', '{}'::jsonb);
  end if;

  if v_patch ? 'quality_checks_json' then
    if coalesce(jsonb_typeof(v_patch -> 'quality_checks_json'), 'null') not in ('array', 'null') then
      raise exception 'BSBC007: quality_checks_json must be a JSON array';
    end if;
    v_quality_checks_json := coalesce(v_patch -> 'quality_checks_json', '[]'::jsonb);
  end if;

  v_auto_ready_next_step := coalesce((v_patch ->> 'auto_ready_next_step')::boolean, true);
  v_reason := coalesce(nullif(btrim(coalesce(v_patch ->> 'reason', '')), ''), 'batch_step_backflush');

  if v_started_at is not null and v_ended_at is not null and v_started_at > v_ended_at then
    raise exception 'BSBC008: started_at must be earlier than or equal to ended_at';
  end if;

  for v_mode in
    select coalesce(
      nullif(btrim(coalesce(
        p.requirement_json ->> 'consumption_mode',
        jsonb_path_query_first(p.requirement_json, '$.**.consumption_mode') #>> '{}',
        ''
      )), ''),
      nullif(btrim(coalesce(
        p.snapshot_json ->> 'consumption_mode',
        jsonb_path_query_first(p.snapshot_json, '$.**.consumption_mode') #>> '{}',
        ''
      )), ''),
      'estimate'
    )
    from mes.batch_material_plan p
    where p.tenant_id = v_tenant
      and p.batch_step_id = p_batch_step_id
  loop
    if v_mode = 'backflush' then
      v_has_backflush := true;
    elsif v_mode = 'exact' then
      v_has_exact := true;
    end if;
  end loop;

  if not v_has_backflush then
    raise exception 'BSBC009: step does not contain backflush planned inputs';
  end if;

  if v_has_exact then
    raise exception 'BSBC010: mixed exact and backflush planned inputs are not supported';
  end if;

  select
    m.id,
    m.src_site_id,
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'material_id', l.material_id,
          'lot_id', nullif(l.meta ->> 'lot_id', '')::uuid,
          'qty', l.qty,
          'uom_id', l.uom_id,
          'batch_material_actual_id', nullif(l.meta ->> 'batch_material_actual_id', '')::uuid,
          'allocation_mode', l.meta ->> 'allocation_mode'
        )
        order by l.line_no
      ) filter (where l.id is not null),
      '[]'::jsonb
    )
    into
      v_existing_movement_id,
      v_existing_movement_site_id,
      v_existing_consumed_lines
  from public.inv_movements m
  left join public.inv_movement_lines l
    on l.movement_id = m.id
   and l.tenant_id = m.tenant_id
  where m.tenant_id = v_tenant
    and m.doc_type = 'production_issue'
    and m.status = 'posted'
    and m.meta ->> 'source' = 'batch_step_backflush'
    and m.meta ->> 'batch_step_id' = p_batch_step_id::text
  group by m.id, m.src_site_id
  order by m.id desc
  limit 1;

  if v_existing_movement_id is null then
    v_source_site_id := coalesce(
      v_patch_source_site_id,
      nullif(btrim(coalesce(v_batch_meta ->> 'manufacturing_site_id', '')), '')::uuid,
      nullif(btrim(coalesce(v_batch_meta ->> 'manufacture_site_id', '')), '')::uuid,
      nullif(btrim(coalesce(v_batch_meta ->> 'brew_site_id', '')), '')::uuid,
      nullif(btrim(coalesce(v_batch_meta ->> 'site_id', '')), '')::uuid,
      nullif(btrim(coalesce(v_batch_meta ->> 'dest_site_id', '')), '')::uuid,
      nullif(btrim(coalesce(v_batch_meta ->> 'movement_site_id', '')), '')::uuid
    );

    if v_source_site_id is null then
      raise exception 'BSBC011: source site could not be resolved from batch metadata';
    end if;

    v_batch_code := upper(regexp_replace(coalesce(v_batch_code, 'BATCH'), '[^A-Za-z0-9]+', '_', 'g'));
    v_batch_code := regexp_replace(v_batch_code, '^_+|_+$', '', 'g');
    v_batch_code := coalesce(nullif(v_batch_code, ''), 'BATCH');
    v_doc_no := format('RMISS-%s-%s', v_batch_code, left(replace(p_batch_step_id::text, '-', ''), 8));

    insert into public.inv_movements (
      tenant_id,
      doc_no,
      doc_type,
      status,
      movement_at,
      src_site_id,
      dest_site_id,
      reason,
      meta,
      notes,
      created_by
    ) values (
      v_tenant,
      v_doc_no,
      'production_issue',
      'posted',
      v_ended_at,
      v_source_site_id,
      null,
      v_reason,
      jsonb_strip_nulls(jsonb_build_object(
        'source', 'batch_step_backflush',
        'batch_id', v_batch_id,
        'batch_step_id', p_batch_step_id,
        'step_no', v_step_no,
        'step_code', v_step_code,
        'allocation_policy', 'FIFO'
      )),
      v_reason,
      v_actor_user_id
    )
    returning id into v_movement_id;

    for
      v_current_actual_id,
      v_current_material_id,
      v_current_lot_id,
      v_current_actual_qty,
      v_current_uom_id
    in
      select
        a.id,
        a.material_id,
        a.lot_id,
        a.actual_qty,
        a.uom_id
      from mes.batch_material_actual a
      where a.tenant_id = v_tenant
        and a.batch_step_id = p_batch_step_id
        and a.actual_qty > 0
      order by a.consumed_at, a.created_at, a.id
    loop
      v_positive_actual_rows := v_positive_actual_rows + 1;

      if v_current_uom_id is null then
        raise exception 'BSBC012: actual material row % is missing uom_id', v_current_actual_id;
      end if;

      if v_current_lot_id is not null then
        perform public._lock_lots(array[v_current_lot_id]);

        select
          l.lot_no,
          l.site_id,
          l.material_id,
          l.uom_id,
          l.status,
          l.qty
          into
            v_explicit_lot_no,
            v_explicit_lot_site_id,
            v_explicit_lot_material_id,
            v_explicit_lot_uom_id,
            v_explicit_lot_status,
            v_explicit_lot_qty
        from public.lot l
        where l.tenant_id = v_tenant
          and l.id = v_current_lot_id
        for update;

        if not found then
          raise exception 'BSBC013: explicit lot % not found', v_current_lot_id;
        end if;

        perform public._assert_source_lot_not_after_movement(
          v_ended_at,
          array[v_current_lot_id],
          'batch_step_complete_backflush:explicit_lot'
        );

        if v_explicit_lot_site_id is distinct from v_source_site_id then
          raise exception 'BSBC014: explicit lot % does not belong to the source site', v_explicit_lot_no;
        end if;

        if v_explicit_lot_status <> 'active' then
          raise exception 'BSBC015: explicit lot % is not active', v_explicit_lot_no;
        end if;

        if v_current_material_id is null then
          v_current_material_id := v_explicit_lot_material_id;
        elsif v_explicit_lot_material_id is distinct from v_current_material_id then
          raise exception 'BSBC016: explicit lot % does not match the actual material row', v_explicit_lot_no;
        end if;

        if v_current_material_id is null then
          raise exception 'BSBC017: explicit lot % cannot resolve material_id', v_explicit_lot_no;
        end if;

        if v_explicit_lot_uom_id is distinct from v_current_uom_id then
          raise exception 'BSBC018: explicit lot % does not match the actual row uom', v_explicit_lot_no;
        end if;

        select
          i.id,
          i.qty
          into
            v_explicit_inventory_id,
            v_explicit_inventory_qty
        from public.inv_inventory i
        where i.tenant_id = v_tenant
          and i.site_id = v_source_site_id
          and i.lot_id = v_current_lot_id
          and i.uom_id = v_current_uom_id
        for update;

        if v_explicit_inventory_id is null
           or coalesce(v_explicit_inventory_qty, 0) < v_current_actual_qty
           or coalesce(v_explicit_lot_qty, 0) < v_current_actual_qty then
          raise exception 'BSBC019: explicit lot % does not have enough stock', v_explicit_lot_no;
        end if;

        v_line_no := v_line_no + 1;
        insert into public.inv_movement_lines (
          tenant_id,
          movement_id,
          line_no,
          material_id,
          batch_id,
          qty,
          uom_id,
          meta
        ) values (
          v_tenant,
          v_movement_id,
          v_line_no,
          v_current_material_id,
          v_batch_id,
          v_current_actual_qty,
          v_current_uom_id,
          jsonb_build_object(
            'source', 'batch_step_backflush',
            'lot_id', v_current_lot_id,
            'batch_material_actual_id', v_current_actual_id,
            'allocation_mode', 'explicit_lot'
          )
        );

        update public.inv_inventory i
           set qty = i.qty - v_current_actual_qty
         where i.id = v_explicit_inventory_id
        returning qty into v_inventory_remaining;

        if v_inventory_remaining < 0 then
          raise exception 'BSBC020: inventory became negative for explicit lot %', v_explicit_lot_no;
        end if;

        update public.lot l
           set qty = l.qty - v_current_actual_qty,
               status = case when l.qty - v_current_actual_qty <= 0 then 'consumed' else l.status end,
               updated_at = now()
         where l.tenant_id = v_tenant
           and l.id = v_current_lot_id
        returning qty into v_lot_remaining;

        if v_lot_remaining < 0 then
          raise exception 'BSBC021: lot quantity became negative for explicit lot %', v_explicit_lot_no;
        end if;

        perform public._assert_non_negative_lot_qty(v_current_lot_id);

        v_consumed_lines := v_consumed_lines || jsonb_build_array(jsonb_build_object(
          'material_id', v_current_material_id,
          'lot_id', v_current_lot_id,
          'qty', v_current_actual_qty,
          'uom_id', v_current_uom_id,
          'batch_material_actual_id', v_current_actual_id,
          'allocation_mode', 'explicit_lot'
        ));
      else
        if v_current_material_id is null then
          raise exception 'BSBC022: actual material row % is missing material_id', v_current_actual_id;
        end if;

        select coalesce(
          array_agg(l.id order by l.created_at, l.lot_no, l.id),
          '{}'::uuid[]
        )
          into v_candidate_lot_ids
        from public.lot l
        where l.tenant_id = v_tenant
          and l.status = 'active'
          and l.site_id = v_source_site_id
          and l.material_id = v_current_material_id
          and l.uom_id = v_current_uom_id
          and public.lot_effective_created_at(l.id) <= v_ended_at;

        if coalesce(array_length(v_candidate_lot_ids, 1), 0) = 0 then
          raise exception 'BSBC023: no candidate lots found for material % in source site %', v_current_material_id, v_source_site_id;
        end if;

        perform public._lock_lots(v_candidate_lot_ids);

        v_remaining_qty := v_current_actual_qty;

        for
          v_candidate_lot_id,
          v_candidate_lot_no,
          v_candidate_lot_qty,
          v_candidate_inventory_id,
          v_candidate_inventory_qty
        in
          select
            l.id,
            l.lot_no,
            l.qty,
            i.id,
            i.qty
          from public.lot l
          join public.inv_inventory i
            on i.tenant_id = l.tenant_id
           and i.site_id = v_source_site_id
           and i.lot_id = l.id
           and i.uom_id = v_current_uom_id
          where l.tenant_id = v_tenant
            and l.id = any(v_candidate_lot_ids)
          order by l.created_at, l.lot_no, l.id
          for update of l, i
        loop
          exit when v_remaining_qty <= 0;
          continue when coalesce(v_candidate_inventory_qty, 0) <= 0 or coalesce(v_candidate_lot_qty, 0) <= 0;

          v_candidate_take_qty := least(v_remaining_qty, least(v_candidate_inventory_qty, v_candidate_lot_qty));
          continue when v_candidate_take_qty <= 0;

          v_line_no := v_line_no + 1;
          insert into public.inv_movement_lines (
            tenant_id,
            movement_id,
            line_no,
            material_id,
            batch_id,
            qty,
            uom_id,
            meta
          ) values (
            v_tenant,
            v_movement_id,
            v_line_no,
            v_current_material_id,
            v_batch_id,
            v_candidate_take_qty,
            v_current_uom_id,
            jsonb_build_object(
              'source', 'batch_step_backflush',
              'lot_id', v_candidate_lot_id,
              'batch_material_actual_id', v_current_actual_id,
              'allocation_mode', 'fifo_auto'
            )
          );

          update public.inv_inventory i
             set qty = i.qty - v_candidate_take_qty
           where i.id = v_candidate_inventory_id
          returning qty into v_inventory_remaining;

          if v_inventory_remaining < 0 then
            raise exception 'BSBC024: inventory became negative for lot %', v_candidate_lot_no;
          end if;

          update public.lot l
             set qty = l.qty - v_candidate_take_qty,
                 status = case when l.qty - v_candidate_take_qty <= 0 then 'consumed' else l.status end,
                 updated_at = now()
           where l.tenant_id = v_tenant
             and l.id = v_candidate_lot_id
          returning qty into v_lot_remaining;

          if v_lot_remaining < 0 then
            raise exception 'BSBC025: lot quantity became negative for lot %', v_candidate_lot_no;
          end if;

          perform public._assert_non_negative_lot_qty(v_candidate_lot_id);

          v_remaining_qty := v_remaining_qty - v_candidate_take_qty;
          v_consumed_lines := v_consumed_lines || jsonb_build_array(jsonb_build_object(
            'material_id', v_current_material_id,
            'lot_id', v_candidate_lot_id,
            'qty', v_candidate_take_qty,
            'uom_id', v_current_uom_id,
            'batch_material_actual_id', v_current_actual_id,
            'allocation_mode', 'fifo_auto'
          ));
        end loop;

        if v_remaining_qty > 0 then
          raise exception 'BSBC026: insufficient stock for material % in source site %', v_current_material_id, v_source_site_id;
        end if;
      end if;
    end loop;

    if v_positive_actual_rows = 0 then
      raise exception 'BSBC027: no positive actual material rows found for backflush';
    end if;
  else
    v_movement_id := v_existing_movement_id;
    v_source_site_id := v_existing_movement_site_id;
    v_consumed_lines := coalesce(v_existing_consumed_lines, '[]'::jsonb);
  end if;

  update mes.batch_step s
     set status = 'completed',
         started_at = v_started_at,
         ended_at = v_ended_at,
         notes = v_notes,
         actual_params = coalesce(v_actual_params, '{}'::jsonb),
         quality_checks_json = coalesce(v_quality_checks_json, '[]'::jsonb),
         updated_by = v_actor_user_id,
         updated_at = now()
   where s.tenant_id = v_tenant
     and s.id = p_batch_step_id;

  if v_auto_ready_next_step then
    select
      s.id,
      s.status::text
      into
        v_next_step_id,
        v_next_step_status
    from mes.batch_step s
    where s.tenant_id = v_tenant
      and s.batch_id = v_batch_id
      and s.step_no > v_step_no
    order by s.step_no
    limit 1
    for update;

    if v_next_step_id is not null and v_next_step_status = 'open' then
      update mes.batch_step s
         set status = 'ready',
             updated_by = v_actor_user_id,
             updated_at = now()
       where s.tenant_id = v_tenant
         and s.id = v_next_step_id;
      v_next_step_status := 'ready';
    end if;
  end if;

  return jsonb_build_object(
    'batch_step_id', p_batch_step_id,
    'batch_id', v_batch_id,
    'movement_id', v_movement_id,
    'source_site_id', v_source_site_id,
    'next_step_id', v_next_step_id,
    'next_step_status', v_next_step_status,
    'reused_existing_movement', v_existing_movement_id is not null,
    'consumed_lines', coalesce(v_consumed_lines, '[]'::jsonb)
  );
end;
$$;
