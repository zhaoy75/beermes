-- Seed a basic pale ale template across recipes, ingredients, processes, and steps.
-- Update tenant_name to match the target tenant before running.

do $$
declare
  tenant_name text := 't';
  v_tenant_id uuid;
  v_recipe_id uuid;
  v_process_id uuid;
  v_ingredient_rows int := 0;
  v_step_rows int := 0;
begin
  select id into v_tenant_id
  from tenants
  where name = tenant_name
  limit 1;

  if not found then
    raise exception 'Tenant % not found', tenant_name;
  end if;

  insert into mes_recipes (
    tenant_id,
    code,
    name,
    style,
    batch_size_l,
    target_og,
    target_fg,
    target_abv,
    target_ibu,
    target_srm,
    version,
    status,
    notes
  )
  values (
    v_tenant_id,
    'BASIC-PALE',
    'Basic Pale Ale Template',
    'American Pale Ale',
    20,
    1.052,
    1.012,
    5.2,
    35,
    6,
    1,
    'active',
    'Template recipe used as a starting point for hop-forward pale ales.'
  )
  on conflict (tenant_id, code, version) do update
    set
      name = excluded.name,
      style = excluded.style,
      batch_size_l = excluded.batch_size_l,
      target_og = excluded.target_og,
      target_fg = excluded.target_fg,
      target_abv = excluded.target_abv,
      target_ibu = excluded.target_ibu,
      target_srm = excluded.target_srm,
      status = excluded.status,
      notes = excluded.notes
  returning id into v_recipe_id;

  -- Ensure the recipe_id is populated even when the row already existed.
  if v_recipe_id is null then
    select id into v_recipe_id
    from mes_recipes
    where tenant_id = v_tenant_id
      and code = 'BASIC-PALE'
      and version = 1;
  end if;

  if v_recipe_id is null then
    raise exception 'Failed to resolve recipe_id for tenant %', tenant_name;
  end if;

  -- Replace ingredients for this recipe with the template set.
  delete from mes_ingredients
  where recipe_id = v_recipe_id;

  insert into mes_ingredients (
    tenant_id,
    recipe_id,
    material_id,
    amount,
    uom_id,
    usage_stage,
    notes
  )
  select
    v_tenant_id,
    v_recipe_id,
    m.id,
    d.amount,
    u.id,
    d.usage_stage,
    d.notes
  from (
    values
      ('2ROW',        18.0, 'kg', 'mash',         'Base malt providing bulk of fermentable sugars.'),
      ('CARAMEL60',    1.0, 'kg', 'mash',         'Adds color and light caramel sweetness.'),
      ('BREWWATER',   25.0, 'L',  'mash',         'Strike water volume for mash-in.'),
      ('CENT',        50.0, 'g',  'boil',         '60-minute bittering addition.'),
      ('CITRA',       75.0, 'g',  'whirlpool',    'Steep at 80C for 20 minutes.'),
      ('US05',         2.0, 'ea', 'fermentation', 'Rehydrate per supplier guidance before pitching.')
  ) as d(material_code, amount, uom_code, usage_stage, notes)
  join mst_materials m on m.tenant_id = v_tenant_id and m.code = d.material_code
  join mst_uom u on u.tenant_id = v_tenant_id and u.code = d.uom_code;

  get diagnostics v_ingredient_rows = ROW_COUNT;

  insert into mes_recipe_processes (
    tenant_id,
    recipe_id,
    name,
    version,
    is_active,
    notes
  )
  values (
    v_tenant_id,
    v_recipe_id,
    'Standard Pale Ale Process',
    1,
    true,
    'Baseline process covering mash, boil, fermentation, conditioning, and packaging.'
  )
  on conflict (tenant_id, recipe_id, name, version) do update
    set
      is_active = excluded.is_active,
      notes = excluded.notes
  returning id into v_process_id;

  if v_process_id is null then
    select id into v_process_id
    from mes_recipe_processes
    where tenant_id = v_tenant_id
      and recipe_id = v_recipe_id
      and name = 'Standard Pale Ale Process'
      and version = 1;
  end if;

  if v_process_id is null then
    raise exception 'Failed to resolve process_id for tenant %', tenant_name;
  end if;

  delete from mes_recipe_steps
  where process_id = v_process_id;

  insert into mes_recipe_steps (
    tenant_id,
    process_id,
    step_no,
    step,
    target_params,
    qa_checks,
    notes
  )
  select
    v_tenant_id,
    v_process_id,
    d.step_no,
    d.step::prc_step_type,
    d.target_params,
    d.qa_checks,
    d.notes
  from (
    values
      (1, 'mashing',      jsonb_build_object('temp_c', 66, 'duration_min', 60),    jsonb_build_array('Verify mash pH 5.2-5.6'),                                 'Single-infusion mash at 66C.'),
      (2, 'lautering',    jsonb_build_object('sparge_temp_c', 75, 'target_preboil_volume_l', 28), jsonb_build_array('Check pre-boil gravity 1.045-1.047'), 'Batch sparge with 75C water.'),
      (3, 'boil',         jsonb_build_object('duration_min', 60, 'post_boil_volume_l', 23),      jsonb_build_array('Confirm vigorous rolling boil', 'Log hop additions'), 'Add bittering hops at start of boil; follow hop schedule.'),
      (4, 'whirlpool',    jsonb_build_object('temp_c', 80, 'duration_min', 20),                   jsonb_build_array('Hold whirlpool temp within +/-2C'),               'Whirlpool hop steep for aroma.'),
      (5, 'cooling',      jsonb_build_object('target_temp_c', 19, 'method', 'plate_chiller'),    jsonb_build_array('Record knockout temperature'),                   'Chill wort to 19C quickly to minimize DMS pickup.'),
      (6, 'fermentation', jsonb_build_object('primary_temp_c', 19, 'duration_days', 10),         jsonb_build_array('Check gravity on day 7', 'Record terminal gravity'), 'Ferment at 19C and complete diacetyl rest if necessary.'),
      (7, 'packaging',    jsonb_build_object('conditioning_temp_c', 2, 'duration_days', 3, 'package_type', 'keg'), jsonb_build_array('Confirm carbonation 2.4 volumes CO2', 'Pressure test package before release'), 'Crash, carbonate, and package into sanitized kegs.')
  ) as d(step_no, step, target_params, qa_checks, notes);

  get diagnostics v_step_rows = ROW_COUNT;

  raise notice 'Recipe template seeded. recipe_id=%, process_id=%, ingredients inserted=%, steps inserted=%',
    v_recipe_id,
    v_process_id,
    v_ingredient_rows,
    v_step_rows;
end;
$$ language plpgsql;
