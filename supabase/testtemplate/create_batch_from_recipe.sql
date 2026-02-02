-- Procedure: create a production batch from an existing recipe + process definition.
-- Usage: call create_batch_from_recipe(<tenant_id>, <recipe_id>, <batch_code>, ...);
-- Copies the latest (or specified) process steps into mes_batch_steps so the batch can be executed.

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
  v_recipe mes_recipes%rowtype;
  v_process mes_recipe_processes%rowtype;
  v_batch_id uuid;
  v_recipe_id uuid;
begin
  if _batch_code is null or length(trim(_batch_code)) = 0 then
    raise exception 'Batch code must be provided';
  end if;

  begin
    v_recipe_id := nullif(trim(_recipe_id), '')::uuid;
  exception when invalid_text_representation then
    raise exception 'Recipe id % is not a valid uuid', _recipe_id;
  end;

  if v_recipe_id is null then
    begin
      insert into mes_batches (
        tenant_id,
        batch_code,
        recipe_id,
        process_version,
        planned_start,
        status,
        notes
      )
      values (
        _tenant_id,
        _batch_code,
        v_recipe_id,
        _process_version,
        coalesce(_planned_start, now()),
        'planned',
        _notes
      )
      returning id into v_batch_id;
    exception when unique_violation then
      raise exception 'Batch code % already exists for tenant %', _batch_code, _tenant_id;
    end;
    return v_batch_id;
  end if;


  select *
    into v_recipe
  from mes_recipes
  where id = v_recipe_id
    and tenant_id = _tenant_id;

  if not found then
    raise exception 'Recipe % not found for tenant %', v_recipe_id, _tenant_id;
  end if;

  if _process_version is not null then
    select *
      into v_process
    from mes_recipe_processes
    where tenant_id = _tenant_id
      and recipe_id = v_recipe_id
      and version = _process_version
    order by is_active desc
    limit 1;
  else
    select *
      into v_process
    from mes_recipe_processes
    where tenant_id = _tenant_id
      and recipe_id = v_recipe_id
    order by is_active desc, version desc
    limit 1;
  end if;

  if v_process.id is null then
    raise exception 'No process found for recipe % (tenant %)', _recipe_id, _tenant_id;
  end if;

  begin
    insert into mes_batches (
      tenant_id,
      batch_code,
      recipe_id,
      process_version,
      planned_start,
      status,
      notes
    )
    values (
      _tenant_id,
      _batch_code,
      v_recipe_id,
      v_process.version,
      coalesce(_planned_start, now()),
      'planned',
      coalesce(_notes, v_recipe.notes)
    )
    returning id into v_batch_id;
  exception when unique_violation then
    raise exception 'Batch code % already exists for tenant %', _batch_code, _tenant_id;
  end;

  delete from mes_batch_steps
  where batch_id = v_batch_id
    and tenant_id = _tenant_id;

  insert into mes_batch_steps (
    tenant_id,
    batch_id,
    step_no,
    step,
    planned_params,
    notes
  )
  select
    _tenant_id,
    v_batch_id,
    ps.step_no,
    ps.step,
    coalesce(ps.target_params, '{}'::jsonb) ||
      case
        when ps.qa_checks is not null and ps.qa_checks <> '[]'::jsonb
          then jsonb_build_object('qa_checks', ps.qa_checks)
        else '{}'::jsonb
      end,
    ps.notes
  from mes_recipe_steps ps
  where ps.process_id = v_process.id
    and ps.tenant_id = _tenant_id
  order by ps.step_no;

  return v_batch_id;
end;
$$;
