-- Procedure: create a production batch from the current MES recipe design.
-- Usage: call create_batch_from_recipe(<tenant_id>, <mes.mst_recipe.id>, <batch_code>, ...);
-- Releases the selected recipe version from mes.mst_recipe_version.recipe_body_json
-- into public.mes_batches, mes.batch_step, and mes.batch_material_plan.

create or replace function create_batch_from_recipe(
  _tenant_id uuid,
  _recipe_id text,
  _batch_code text,
  _planned_start timestamptz default null,
  _process_version int default null,
  _notes text default null
) returns uuid
language plpgsql
as $$
declare
  v_batch_id uuid;
  v_mes_recipe_id uuid;
  v_recipe_version_id uuid;
  v_recipe_code text;
  v_recipe_name text;
  v_version_no integer;
  v_version_label text;
  v_recipe_body jsonb := '{}'::jsonb;
  v_resolved_reference jsonb := '{}'::jsonb;
  v_batch_note text;
  v_product_name text;
  v_batch_step_id uuid;
  v_step jsonb;
  v_step_no integer;
  v_step_code text;
  v_step_name text;
  v_material jsonb;
  v_material_type_code text;
  v_material_type_id uuid;
  v_material_role text;
  v_uom_code text;
  v_uom_id uuid;
  v_planned_qty numeric;
  v_step_has_materials boolean;
  v_exists_in_steps boolean;
begin
  if _batch_code is null or length(trim(_batch_code)) = 0 then
    raise exception 'Batch code must be provided';
  end if;

  begin
    v_mes_recipe_id := nullif(trim(_recipe_id), '')::uuid;
  exception when invalid_text_representation then
    raise exception 'Recipe id % is not a valid uuid', _recipe_id;
  end;

  if v_mes_recipe_id is not null then
    select
      r.id,
      r.recipe_code,
      r.recipe_name,
      rv.id,
      rv.version_no,
      rv.version_label,
      rv.recipe_body_json,
      rv.resolved_reference_json
    into
      v_mes_recipe_id,
      v_recipe_code,
      v_recipe_name,
      v_recipe_version_id,
      v_version_no,
      v_version_label,
      v_recipe_body,
      v_resolved_reference
    from mes.mst_recipe r
    join mes.mst_recipe_version rv
      on rv.tenant_id = r.tenant_id
     and rv.recipe_id = r.id
    where r.tenant_id = _tenant_id
      and r.id = v_mes_recipe_id
      and (
        (_process_version is not null and rv.version_no = _process_version)
        or (_process_version is null and rv.id = r.current_version_id)
        or (
          _process_version is null
          and r.current_version_id is null
          and rv.id = (
            select rv2.id
            from mes.mst_recipe_version rv2
            where rv2.tenant_id = r.tenant_id
              and rv2.recipe_id = r.id
            order by
              case when rv2.status = 'approved' then 0 else 1 end,
              rv2.version_no desc
            limit 1
          )
        )
      )
    order by rv.version_no desc
    limit 1;

    if v_recipe_version_id is null then
      raise exception 'Recipe % not found or has no releasable version for tenant %', v_mes_recipe_id, _tenant_id;
    end if;

    if jsonb_typeof(v_recipe_body) <> 'object' then
      raise exception 'Recipe version % has invalid recipe_body_json', v_recipe_version_id;
    end if;

    if coalesce(jsonb_typeof(v_recipe_body -> 'flow' -> 'steps'), 'null') <> 'array' then
      raise exception 'Recipe version % has no flow.steps array', v_recipe_version_id;
    end if;
  end if;

  v_batch_note := coalesce(
    nullif(trim(_notes), ''),
    nullif(trim(coalesce(v_recipe_body -> 'recipe_info' ->> 'notes', '')), ''),
    nullif(trim(coalesce(v_recipe_body -> 'recipe_info' ->> 'description', '')), ''),
    nullif(trim(v_recipe_name), '')
  );

  v_product_name := coalesce(
    nullif(trim(coalesce(v_recipe_body -> 'outputs' -> 'primary' -> 0 ->> 'output_name', '')), ''),
    nullif(trim(v_recipe_name), '')
  );

  begin
    insert into public.mes_batches (
      tenant_id,
      batch_code,
      recipe_id,
      mes_recipe_id,
      recipe_version_id,
      recipe_json,
      planned_start,
      status,
      notes,
      product_name,
      released_reference_json
    )
    values (
      _tenant_id,
      trim(_batch_code),
      null,
      v_mes_recipe_id,
      v_recipe_version_id,
      case when v_mes_recipe_id is null then null else v_recipe_body end,
      coalesce(_planned_start, now()),
      'planned',
      v_batch_note,
      v_product_name,
      case
        when v_mes_recipe_id is null then '{}'::jsonb
        else coalesce(v_resolved_reference, '{}'::jsonb) || jsonb_build_object(
          'mes_recipe_id', v_mes_recipe_id,
          'recipe_code', v_recipe_code,
          'recipe_name', v_recipe_name,
          'recipe_version_id', v_recipe_version_id,
          'version_no', v_version_no,
          'version_label', v_version_label,
          'released_at', now()
        )
      end
    )
    returning id into v_batch_id;
  exception when unique_violation then
    raise exception 'Batch code % already exists for tenant %', _batch_code, _tenant_id;
  end;

  insert into entity_attr_set (
    tenant_id,
    entity_type,
    entity_id,
    attr_set_id,
    is_active
  )
  select
    _tenant_id,
    'batch',
    v_batch_id,
    s.attr_set_id,
    true
  from attr_set s
  where s.tenant_id = _tenant_id
    and s.domain = 'batch'
    and s.is_active = true
  on conflict (tenant_id, entity_type, entity_id, attr_set_id) do nothing;

  if v_mes_recipe_id is null then
    return v_batch_id;
  end if;

  for v_step in
    select value
    from jsonb_array_elements(coalesce(v_recipe_body -> 'flow' -> 'steps', '[]'::jsonb))
    order by coalesce((value ->> 'step_no')::integer, 0)
  loop
    v_step_no := coalesce((v_step ->> 'step_no')::integer, null);
    v_step_code := nullif(trim(coalesce(v_step ->> 'step_code', '')), '');
    v_step_name := nullif(trim(coalesce(v_step ->> 'step_name', '')), '');

    if v_step_no is null or v_step_code is null or v_step_name is null then
      raise exception 'Recipe version % contains a step missing step_no, step_code, or step_name', v_recipe_version_id;
    end if;

    insert into mes.batch_step (
      tenant_id,
      batch_id,
      step_no,
      step_code,
      step_name,
      step_template_code,
      planned_duration_sec,
      status,
      planned_params,
      quality_checks_json,
      snapshot_json,
      notes
    )
    values (
      _tenant_id,
      v_batch_id,
      v_step_no,
      v_step_code,
      v_step_name,
      nullif(trim(coalesce(v_step ->> 'step_template_code', '')), ''),
      case when nullif(trim(coalesce(v_step ->> 'duration_sec', '')), '') is null then null else (v_step ->> 'duration_sec')::integer end,
      'open',
      jsonb_strip_nulls(jsonb_build_object(
        'step_type', nullif(trim(coalesce(v_step ->> 'step_type', '')), ''),
        'instructions', nullif(trim(coalesce(v_step ->> 'instructions', '')), ''),
        'parameters', coalesce(v_step -> 'parameters', '[]'::jsonb),
        'material_outputs', coalesce(v_step -> 'material_outputs', '[]'::jsonb),
        'equipment_requirements', coalesce(v_step -> 'equipment_requirements', '[]'::jsonb)
      )),
      coalesce(v_step -> 'quality_checks', '[]'::jsonb),
      v_step,
      nullif(trim(coalesce(v_step ->> 'notes', v_step ->> 'instructions', '')), '')
    )
    returning id into v_batch_step_id;

    for v_material in
      select value
      from jsonb_array_elements(coalesce(v_step -> 'material_inputs', '[]'::jsonb))
    loop
      v_material_type_code := coalesce(
        nullif(trim(coalesce(v_material ->> 'material_type_code', '')), ''),
        nullif(trim(split_part(coalesce(v_material ->> 'material_type', ''), ':', 1)), ''),
        nullif(trim(coalesce(v_material ->> 'material_type', '')), '')
      );
      v_uom_code := nullif(trim(coalesce(v_material ->> 'uom_code', '')), '');
      v_planned_qty := coalesce((v_material ->> 'qty')::numeric, 0);

      if v_material_type_code is null then
        raise exception 'Step % is missing material_type for one material input', v_step_code;
      end if;
      if v_uom_code is null then
        raise exception 'Step % material input % is missing uom_code', v_step_code, v_material_type_code;
      end if;

      select td.type_id
        into v_material_type_id
      from public.type_def td
      where td.tenant_id = _tenant_id
        and td.domain = 'material_type'
        and td.code = v_material_type_code
      order by td.created_at
      limit 1;

      if v_material_type_id is null then
        raise exception 'Material type % not found in public.type_def for tenant %', v_material_type_code, _tenant_id;
      end if;

      select u.id
        into v_uom_id
      from public.mst_uom u
      where u.code = v_uom_code
        and (u.tenant_id = _tenant_id or u.tenant_id is null)
      order by case when u.tenant_id = _tenant_id then 0 else 1 end
      limit 1;

      if v_uom_id is null then
        raise exception 'UOM code % not found in public.mst_uom for tenant %', v_uom_code, _tenant_id;
      end if;

      insert into mes.batch_material_plan (
        tenant_id,
        batch_id,
        batch_step_id,
        material_role,
        material_type_id,
        planned_qty,
        uom_id,
        requirement_json,
        snapshot_json
      )
      values (
        _tenant_id,
        v_batch_id,
        v_batch_step_id,
        nullif(trim(coalesce(v_material ->> 'material_role', '')), ''),
        v_material_type_id,
        v_planned_qty,
        v_uom_id,
        v_material,
        jsonb_build_object(
          'source', 'flow.steps.material_inputs',
          'step_code', v_step_code,
          'step_no', v_step_no
        ) || v_material
      );
    end loop;
  end loop;

  v_step_has_materials := exists (
    select 1
    from jsonb_array_elements(coalesce(v_recipe_body -> 'flow' -> 'steps', '[]'::jsonb)) as step_row(step_value)
    cross join lateral jsonb_array_elements(coalesce(step_row.step_value -> 'material_inputs', '[]'::jsonb)) as input_row(input_value)
  );

  if not v_step_has_materials then
    v_exists_in_steps := false;
  end if;

  for v_material in
    select value
    from jsonb_array_elements(
      coalesce(v_recipe_body -> 'materials' -> 'required', '[]'::jsonb)
      || coalesce(v_recipe_body -> 'materials' -> 'optional', '[]'::jsonb)
    )
  loop
    v_material_type_code := coalesce(
      nullif(trim(coalesce(v_material ->> 'material_type_code', '')), ''),
      nullif(trim(split_part(coalesce(v_material ->> 'material_type', ''), ':', 1)), ''),
      nullif(trim(coalesce(v_material ->> 'material_type', '')), '')
    );
    v_material_role := nullif(trim(coalesce(v_material ->> 'material_role', '')), '');
    v_uom_code := nullif(trim(coalesce(v_material ->> 'uom_code', '')), '');
    v_planned_qty := coalesce((v_material ->> 'qty')::numeric, 0);

    if v_material_type_code is null or v_uom_code is null then
      continue;
    end if;

    v_exists_in_steps := exists (
      select 1
      from jsonb_array_elements(coalesce(v_recipe_body -> 'flow' -> 'steps', '[]'::jsonb)) as step_row(step_value)
      cross join lateral jsonb_array_elements(coalesce(step_row.step_value -> 'material_inputs', '[]'::jsonb)) as input_row(input_value)
      where coalesce(
        nullif(trim(coalesce(input_row.input_value ->> 'material_type_code', '')), ''),
        nullif(trim(split_part(coalesce(input_row.input_value ->> 'material_type', ''), ':', 1)), ''),
        nullif(trim(coalesce(input_row.input_value ->> 'material_type', '')), '')
      ) = v_material_type_code
    );

    if v_exists_in_steps then
      continue;
    end if;

    select td.type_id
      into v_material_type_id
    from public.type_def td
    where td.tenant_id = _tenant_id
      and td.domain = 'material_type'
      and td.code = v_material_type_code
    order by td.created_at
    limit 1;

    if v_material_type_id is null then
      raise exception 'Material type % not found in public.type_def for tenant %', v_material_type_code, _tenant_id;
    end if;

    select u.id
      into v_uom_id
    from public.mst_uom u
    where u.code = v_uom_code
      and (u.tenant_id = _tenant_id or u.tenant_id is null)
    order by case when u.tenant_id = _tenant_id then 0 else 1 end
    limit 1;

    if v_uom_id is null then
      raise exception 'UOM code % not found in public.mst_uom for tenant %', v_uom_code, _tenant_id;
    end if;

    insert into mes.batch_material_plan (
      tenant_id,
      batch_id,
      batch_step_id,
      material_role,
      material_type_id,
      planned_qty,
      uom_id,
      requirement_json,
      snapshot_json
    )
    values (
      _tenant_id,
      v_batch_id,
      null,
      v_material_role,
      v_material_type_id,
      v_planned_qty,
      v_uom_id,
      v_material,
      jsonb_build_object('source', 'materials.required_or_optional') || v_material
    );
  end loop;

  return v_batch_id;
end;
$$;
