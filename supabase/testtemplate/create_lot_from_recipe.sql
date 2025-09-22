-- Procedure: create a production lot from an existing recipe + process definition.
-- Usage: call create_lot_from_recipe(<tenant_id>, <recipe_id>, <lot_code>, ...);
-- Copies the latest (or specified) process steps into prd_lot_steps so the lot can be executed.

create or replace function create_lot_from_recipe(
  _tenant_id uuid,
  _recipe_id uuid,
  _lot_code text,
  _planned_start timestamptz default null,
  _vessel_id uuid default null,
  _target_volume_l numeric default null,
  _process_version int default null,
  _notes text default null
) returns uuid
language plpgsql
as $$
declare
  v_recipe rcp_recipes%rowtype;
  v_process prc_processes%rowtype;
  v_lot_id uuid;
begin
  if _lot_code is null or length(trim(_lot_code)) = 0 then
    raise exception 'Lot code must be provided';
  end if;

  select *
    into v_recipe
  from rcp_recipes
  where id = _recipe_id
    and tenant_id = _tenant_id;

  if not found then
    raise exception 'Recipe % not found for tenant %', _recipe_id, _tenant_id;
  end if;

  if _process_version is not null then
    select *
      into v_process
    from prc_processes
    where tenant_id = _tenant_id
      and recipe_id = _recipe_id
      and version = _process_version
    order by is_active desc
    limit 1;
  else
    select *
      into v_process
    from prc_processes
    where tenant_id = _tenant_id
      and recipe_id = _recipe_id
    order by is_active desc, version desc
    limit 1;
  end if;

  if v_process.id is null then
    raise exception 'No process found for recipe % (tenant %)', _recipe_id, _tenant_id;
  end if;

  begin
    insert into prd_lots (
      tenant_id,
      lot_code,
      recipe_id,
      process_version,
      vessel_id,
      target_volume_l,
      planned_start,
      status,
      notes
    )
    values (
      _tenant_id,
      _lot_code,
      _recipe_id,
      v_process.version,
      _vessel_id,
      coalesce(_target_volume_l, v_recipe.batch_size_l),
      coalesce(_planned_start, now()),
      'planned',
      coalesce(_notes, v_recipe.notes)
    )
    returning id into v_lot_id;
  exception when unique_violation then
    raise exception 'Lot code % already exists for tenant %', _lot_code, _tenant_id;
  end;

  delete from prd_lot_steps
  where lot_id = v_lot_id
    and tenant_id = _tenant_id;

  insert into prd_lot_steps (
    tenant_id,
    lot_id,
    step_no,
    step,
    planned_params,
    notes
  )
  select
    _tenant_id,
    v_lot_id,
    ps.step_no,
    ps.step,
    coalesce(ps.target_params, '{}'::jsonb) ||
      case
        when ps.qa_checks is not null and ps.qa_checks <> '[]'::jsonb
          then jsonb_build_object('qa_checks', ps.qa_checks)
        else '{}'::jsonb
      end,
    ps.notes
  from prc_steps ps
  where ps.process_id = v_process.id
    and ps.tenant_id = _tenant_id
  order by ps.step_no;

  return v_lot_id;
end;
$$;
