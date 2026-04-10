-- Craft-beer style recipe seed for Dry Stout, American IPA, and American Pale Ale.
-- This script follows the current recipe model that uses material_type_code/material_code
-- and does not depend on mes.mst_material_spec.
--
-- Usage:
--   select set_config('app.seed_tenant_id', '<tenant-uuid>', false);
--   \i DB/dml/mes/mes_recipe_craft_beer_styles_seed.sql
--
-- Assumptions:
--   - public.industry contains code = 'CRAFT_BEER'
--   - public.mst_uom contains kg, L, C, min, hour, mL, %, pcs
--   - public.type_def contains the craft-beer material/equipment type tree
--   - mes.mst_equipment_template contains:
--       MASH_TUN_1000L, BOIL_KETTLE_1000L, FERMENTER_1000L, BOTTLING_LINE_STD

DO $seed$
DECLARE
  v_tenant uuid := COALESCE(
    NULLIF(current_setting('app.seed_tenant_id', true), '')::uuid,
    app_current_tenant_id(),
    '2a231822-aa8d-452a-aa5f-9f5e4293cdaa'::uuid
  );
  v_industry_id uuid;

  v_uom_kg uuid;
  v_uom_l uuid;
  v_uom_c uuid;
  v_uom_min uuid;
  v_uom_hour uuid;
  v_uom_ml uuid;
  v_uom_pct uuid;
  v_uom_pcs uuid;

  v_mt_water uuid;
  v_mt_base_malt uuid;
  v_mt_specialty_malt uuid;
  v_mt_roasted_malt uuid;
  v_mt_hop uuid;
  v_mt_yeast uuid;
  v_mt_adjunct uuid;
  v_mt_bottle uuid;
  v_mt_cap uuid;
  v_mt_label uuid;
  v_mt_beer uuid;

  v_et_mash_tun uuid;
  v_et_boil_kettle uuid;
  v_et_fermenter uuid;
  v_et_bottling_line uuid;

  v_eqtpl_mash uuid;
  v_eqtpl_boil uuid;
  v_eqtpl_ferm uuid;
  v_eqtpl_pack uuid;

  v_step_mash uuid;
  v_step_boil uuid;
  v_step_ferment uuid;
  v_step_package uuid;

  v_recipe_id uuid;
  v_recipe_version_id uuid;
BEGIN
  SELECT industry_id
    INTO v_industry_id
    FROM public.industry
   WHERE code = 'CRAFT_BEER'
     AND is_active = true
   ORDER BY sort_order, created_at
   LIMIT 1;

  IF v_industry_id IS NULL THEN
    RAISE EXCEPTION 'Active industry code CRAFT_BEER is required before running this script.';
  END IF;

  SELECT id INTO v_uom_kg
    FROM public.mst_uom
   WHERE code = 'kg'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_l
    FROM public.mst_uom
   WHERE code = 'L'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_c
    FROM public.mst_uom
   WHERE code = 'C'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_min
    FROM public.mst_uom
   WHERE code = 'min'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_hour
    FROM public.mst_uom
   WHERE code = 'hour'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_ml
    FROM public.mst_uom
   WHERE code = 'mL'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_pct
    FROM public.mst_uom
   WHERE code = '%'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_pcs
    FROM public.mst_uom
   WHERE code = 'pcs'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  IF v_uom_kg IS NULL OR v_uom_l IS NULL OR v_uom_c IS NULL OR v_uom_min IS NULL
     OR v_uom_hour IS NULL OR v_uom_ml IS NULL OR v_uom_pct IS NULL OR v_uom_pcs IS NULL THEN
    RAISE EXCEPTION 'Required craft-beer UOM rows are missing. Seed public.mst_uom first.';
  END IF;

  SELECT type_id INTO v_mt_water
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND code = 'WATER'
   ORDER BY CASE WHEN industry_id = v_industry_id THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_base_malt
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND code IN ('BASE_MALT', 'MALT')
   ORDER BY CASE code WHEN 'BASE_MALT' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_specialty_malt
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND code IN ('SPECIALTY_MALT', 'MALT')
   ORDER BY CASE code WHEN 'SPECIALTY_MALT' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_roasted_malt
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND code IN ('ROASTED_MALT', 'MALT')
   ORDER BY CASE code WHEN 'ROASTED_MALT' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_hop
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND code IN ('HOP_PELLET', 'HOPS')
   ORDER BY CASE code WHEN 'HOP_PELLET' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_yeast
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND code IN ('DRY_YEAST', 'YEAST')
   ORDER BY CASE code WHEN 'DRY_YEAST' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_adjunct
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND code IN ('ADJUNCT', 'RAW_MATERIAL')
   ORDER BY CASE code WHEN 'ADJUNCT' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_bottle
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND code IN ('BOTTLE', 'PACKAGING')
   ORDER BY CASE code WHEN 'BOTTLE' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_cap
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND code IN ('CROWN_CAP', 'PACKAGING')
   ORDER BY CASE code WHEN 'CROWN_CAP' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_label
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND code IN ('LABEL', 'PACKAGING')
   ORDER BY CASE code WHEN 'LABEL' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_beer
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND code = 'BEER'
   ORDER BY CASE WHEN industry_id = v_industry_id THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  IF v_mt_water IS NULL OR v_mt_base_malt IS NULL OR v_mt_specialty_malt IS NULL
     OR v_mt_roasted_malt IS NULL OR v_mt_hop IS NULL OR v_mt_yeast IS NULL
     OR v_mt_adjunct IS NULL OR v_mt_bottle IS NULL OR v_mt_cap IS NULL
     OR v_mt_label IS NULL OR v_mt_beer IS NULL THEN
    RAISE EXCEPTION 'Required craft-beer material_type rows are missing. Seed public.type_def first.';
  END IF;

  SELECT type_id INTO v_et_mash_tun
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'equipment_type'
     AND code = 'MASH_TUN'
   ORDER BY CASE WHEN industry_id = v_industry_id THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_et_boil_kettle
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'equipment_type'
     AND code = 'BOIL_KETTLE'
   ORDER BY CASE WHEN industry_id = v_industry_id THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_et_fermenter
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'equipment_type'
     AND code = 'FERMENTER'
   ORDER BY CASE WHEN industry_id = v_industry_id THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_et_bottling_line
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'equipment_type'
     AND code = 'BOTTLING_LINE'
   ORDER BY CASE WHEN industry_id = v_industry_id THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT id INTO v_eqtpl_mash
    FROM mes.mst_equipment_template
   WHERE tenant_id = v_tenant
     AND template_code = 'MASH_TUN_1000L'
   LIMIT 1;

  SELECT id INTO v_eqtpl_boil
    FROM mes.mst_equipment_template
   WHERE tenant_id = v_tenant
     AND template_code = 'BOIL_KETTLE_1000L'
   LIMIT 1;

  SELECT id INTO v_eqtpl_ferm
    FROM mes.mst_equipment_template
   WHERE tenant_id = v_tenant
     AND template_code = 'FERMENTER_1000L'
   LIMIT 1;

  SELECT id INTO v_eqtpl_pack
    FROM mes.mst_equipment_template
   WHERE tenant_id = v_tenant
     AND template_code = 'BOTTLING_LINE_STD'
   LIMIT 1;

  IF v_et_mash_tun IS NULL OR v_et_boil_kettle IS NULL OR v_et_fermenter IS NULL
     OR v_et_bottling_line IS NULL OR v_eqtpl_mash IS NULL OR v_eqtpl_boil IS NULL
     OR v_eqtpl_ferm IS NULL OR v_eqtpl_pack IS NULL THEN
    RAISE EXCEPTION 'Required craft-beer equipment templates are missing. Seed standard MES recipe masters first.';
  END IF;

  INSERT INTO mes.mst_step_template (
    tenant_id,
    step_template_code,
    step_template_name,
    step_type,
    industry_type,
    default_instructions,
    default_duration_sec,
    parameter_template_json,
    default_equipment_type_id,
    default_equipment_requirement_json,
    default_quality_check_json,
    default_material_role,
    sort_no,
    status
  )
  VALUES
    (
      v_tenant,
      'STEP_MASH',
      'Mash',
      'process',
      'beer',
      'Charge water and malt, then hold the mash rest.',
      5400,
      '{"parameters":[{"parameter_code":"MASH_TEMP","required":true},{"parameter_code":"MASH_TIME","required":true}]}'::jsonb,
      v_et_mash_tun,
      '{"equipment_type_code":"MASH_TUN","equipment_template_code":"MASH_TUN_1000L"}'::jsonb,
      '[{"check_code":"QC_PH_MASH"}]'::jsonb,
      'main_substrate',
      10,
      'active'
    ),
    (
      v_tenant,
      'STEP_BOIL',
      'Boil',
      'process',
      'beer',
      'Boil wort and add hops according to the schedule.',
      4500,
      '{"parameters":[{"parameter_code":"BOIL_TIME","required":true}]}'::jsonb,
      v_et_boil_kettle,
      '{"equipment_type_code":"BOIL_KETTLE","equipment_template_code":"BOIL_KETTLE_1000L"}'::jsonb,
      '[]'::jsonb,
      'flavor',
      20,
      'active'
    ),
    (
      v_tenant,
      'STEP_FERMENT',
      'Ferment',
      'process',
      'beer',
      'Pitch yeast and control fermentation temperature.',
      604800,
      '{"parameters":[{"parameter_code":"FERMENT_TEMP","required":true},{"parameter_code":"FERMENT_TIME","required":true}]}'::jsonb,
      v_et_fermenter,
      '{"equipment_type_code":"FERMENTER","equipment_template_code":"FERMENTER_1000L"}'::jsonb,
      '[{"check_code":"QC_GRAVITY_END"}]'::jsonb,
      'culture',
      30,
      'active'
    ),
    (
      v_tenant,
      'STEP_BOTTLE',
      'Bottle',
      'packaging',
      'beer',
      'Fill, cap, and label bottles.',
      14400,
      '{"parameters":[{"parameter_code":"FILL_VOLUME","required":true}]}'::jsonb,
      v_et_bottling_line,
      '{"equipment_type_code":"BOTTLING_LINE","equipment_template_code":"BOTTLING_LINE_STD"}'::jsonb,
      '[{"check_code":"QC_FILL_VOLUME"},{"check_code":"QC_LABEL_INSPECTION"}]'::jsonb,
      'packaging_primary',
      40,
      'active'
    )
  ON CONFLICT (tenant_id, step_template_code)
  DO UPDATE SET
    step_template_name = EXCLUDED.step_template_name,
    step_type = EXCLUDED.step_type,
    industry_type = EXCLUDED.industry_type,
    default_instructions = EXCLUDED.default_instructions,
    default_duration_sec = EXCLUDED.default_duration_sec,
    parameter_template_json = EXCLUDED.parameter_template_json,
    default_equipment_type_id = EXCLUDED.default_equipment_type_id,
    default_equipment_requirement_json = EXCLUDED.default_equipment_requirement_json,
    default_quality_check_json = EXCLUDED.default_quality_check_json,
    default_material_role = EXCLUDED.default_material_role,
    sort_no = EXCLUDED.sort_no,
    status = EXCLUDED.status,
    updated_at = now();

  SELECT id INTO v_step_mash
    FROM mes.mst_step_template
   WHERE tenant_id = v_tenant
     AND step_template_code = 'STEP_MASH'
   LIMIT 1;

  SELECT id INTO v_step_boil
    FROM mes.mst_step_template
   WHERE tenant_id = v_tenant
     AND step_template_code = 'STEP_BOIL'
   LIMIT 1;

  SELECT id INTO v_step_ferment
    FROM mes.mst_step_template
   WHERE tenant_id = v_tenant
     AND step_template_code = 'STEP_FERMENT'
   LIMIT 1;

  SELECT id INTO v_step_package
    FROM mes.mst_step_template
   WHERE tenant_id = v_tenant
     AND step_template_code = 'STEP_BOTTLE'
   LIMIT 1;

  IF v_step_mash IS NULL OR v_step_boil IS NULL OR v_step_ferment IS NULL OR v_step_package IS NULL THEN
    RAISE EXCEPTION 'Failed to resolve craft-beer step templates after upsert.';
  END IF;

  INSERT INTO mes.mst_material (
    tenant_id,
    material_code,
    material_name,
    material_type_id,
    base_uom_id,
    material_category,
    is_batch_managed,
    is_lot_managed,
    meta_json,
    status
  )
  VALUES
    (v_tenant, 'MAT_WATER_BREW', 'Brewing Water', v_mt_water, v_uom_l, 'raw_material', false, false, '{"material_key":"WATER_BREW"}'::jsonb, 'active'),
    (v_tenant, 'MAT_MALT_2ROW', 'Two-Row Pale Malt', v_mt_base_malt, v_uom_kg, 'raw_material', true, true, '{"material_key":"MALT_2ROW"}'::jsonb, 'active'),
    (v_tenant, 'MAT_MALT_MUNICH', 'Munich Malt', v_mt_specialty_malt, v_uom_kg, 'raw_material', true, true, '{"material_key":"MALT_MUNICH"}'::jsonb, 'active'),
    (v_tenant, 'MAT_MALT_CARAMEL_40', 'Caramel 40 Malt', v_mt_specialty_malt, v_uom_kg, 'raw_material', true, true, '{"material_key":"MALT_CARAMEL_40"}'::jsonb, 'active'),
    (v_tenant, 'MAT_MALT_CHOCOLATE', 'Chocolate Malt', v_mt_roasted_malt, v_uom_kg, 'raw_material', true, true, '{"material_key":"MALT_CHOCOLATE"}'::jsonb, 'active'),
    (v_tenant, 'MAT_ROASTED_BARLEY', 'Roasted Barley', v_mt_roasted_malt, v_uom_kg, 'raw_material', true, true, '{"material_key":"ROASTED_BARLEY"}'::jsonb, 'active'),
    (v_tenant, 'MAT_FLAKED_BARLEY', 'Flaked Barley', v_mt_adjunct, v_uom_kg, 'raw_material', true, true, '{"material_key":"FLAKED_BARLEY"}'::jsonb, 'active'),
    (v_tenant, 'MAT_HOPS_EKG', 'East Kent Goldings', v_mt_hop, v_uom_kg, 'raw_material', true, true, '{"material_key":"HOPS_EKG"}'::jsonb, 'active'),
    (v_tenant, 'MAT_HOPS_COLUMBUS', 'Columbus Hops', v_mt_hop, v_uom_kg, 'raw_material', true, true, '{"material_key":"HOPS_COLUMBUS"}'::jsonb, 'active'),
    (v_tenant, 'MAT_HOPS_CITRA', 'Citra Hops', v_mt_hop, v_uom_kg, 'raw_material', true, true, '{"material_key":"HOPS_CITRA"}'::jsonb, 'active'),
    (v_tenant, 'MAT_HOPS_CASCADE', 'Cascade Hops', v_mt_hop, v_uom_kg, 'raw_material', true, true, '{"material_key":"HOPS_CASCADE"}'::jsonb, 'active'),
    (v_tenant, 'MAT_HOPS_CENTENNIAL', 'Centennial Hops', v_mt_hop, v_uom_kg, 'raw_material', true, true, '{"material_key":"HOPS_CENTENNIAL"}'::jsonb, 'active'),
    (v_tenant, 'MAT_YEAST_ALE_IRISH', 'Irish Ale Yeast', v_mt_yeast, v_uom_kg, 'raw_material', true, true, '{"material_key":"YEAST_ALE_IRISH"}'::jsonb, 'active'),
    (v_tenant, 'MAT_YEAST_US05', 'US-05 Ale Yeast', v_mt_yeast, v_uom_kg, 'raw_material', true, true, '{"material_key":"YEAST_US05"}'::jsonb, 'active'),
    (v_tenant, 'PKG_BOTTLE_330', '330mL Bottle', v_mt_bottle, v_uom_pcs, 'packaging', true, true, '{"material_key":"BOTTLE_330"}'::jsonb, 'active'),
    (v_tenant, 'PKG_CAP_330', 'Bottle Cap', v_mt_cap, v_uom_pcs, 'packaging', true, true, '{"material_key":"CAP_330"}'::jsonb, 'active'),
    (v_tenant, 'PKG_LABEL_STD', 'Standard Label', v_mt_label, v_uom_pcs, 'packaging', true, true, '{"material_key":"LABEL_STD"}'::jsonb, 'active'),
    (v_tenant, 'FG_DRY_STOUT_330', 'Dry Stout 330mL', v_mt_beer, v_uom_pcs, 'finished_good', true, true, '{"material_key":"BEER_DRY_STOUT_330"}'::jsonb, 'active'),
    (v_tenant, 'FG_AMERICAN_IPA_330', 'American IPA 330mL', v_mt_beer, v_uom_pcs, 'finished_good', true, true, '{"material_key":"BEER_AMERICAN_IPA_330"}'::jsonb, 'active'),
    (v_tenant, 'FG_AMERICAN_PALE_ALE_330', 'American Pale Ale 330mL', v_mt_beer, v_uom_pcs, 'finished_good', true, true, '{"material_key":"BEER_AMERICAN_PALE_ALE_330"}'::jsonb, 'active')
  ON CONFLICT (tenant_id, material_code)
  DO UPDATE SET
    material_name = EXCLUDED.material_name,
    material_type_id = EXCLUDED.material_type_id,
    base_uom_id = EXCLUDED.base_uom_id,
    material_category = EXCLUDED.material_category,
    is_batch_managed = EXCLUDED.is_batch_managed,
    is_lot_managed = EXCLUDED.is_lot_managed,
    meta_json = EXCLUDED.meta_json,
    status = EXCLUDED.status,
    updated_at = now();

  INSERT INTO mes.mst_recipe (
    tenant_id, recipe_code, recipe_name, recipe_category, industry_type, status, current_version_id
  )
  VALUES (
    v_tenant, 'RCP_BEER_DRY_STOUT_330', 'Dry Stout 330mL', 'beer', 'beer', 'active', NULL
  )
  ON CONFLICT (tenant_id, recipe_code)
  DO UPDATE SET
    recipe_name = EXCLUDED.recipe_name,
    recipe_category = EXCLUDED.recipe_category,
    industry_type = EXCLUDED.industry_type,
    status = EXCLUDED.status,
    updated_at = now()
  RETURNING id INTO v_recipe_id;

  INSERT INTO mes.mst_recipe_version (
    tenant_id,
    recipe_id,
    version_no,
    version_label,
    recipe_body_json,
    resolved_reference_json,
    schema_code,
    template_code,
    status,
    effective_from,
    effective_to,
    change_summary,
    approved_at,
    approved_by
  )
  VALUES (
    v_tenant,
    v_recipe_id,
    1,
    'v1.0',
    $json$
    {
      "schema_version": "recipe_body_v1",
      "recipe_info": {
        "recipe_type": "process_manufacturing",
        "industry_type": "beer",
        "description": "Dry stout recipe with roasted barley character and bottled 330 mL packaging.",
        "batch_strategy": "fixed",
        "tags": ["stout", "ale", "bottle"],
        "notes": "Seeded craft-beer style recipe."
      },
      "base": {
        "quantity": 1000,
        "uom_code": "L",
        "scaling_method": "linear",
        "rounding_rule": "standard"
      },
      "outputs": {
        "primary": [
          {
            "output_code": "BEER_DRY_STOUT_330",
            "output_name": "Dry Stout 330mL",
            "output_type": "primary",
            "qty": 2880,
            "uom_code": "pcs",
            "basis": "per_base"
          }
        ],
        "co_products": [
          {
            "output_code": "SPENT_GRAIN",
            "output_name": "Spent Grain",
            "output_type": "co_product",
            "qty": 150,
            "uom_code": "kg",
            "basis": "yield_based"
          }
        ]
      },
      "materials": {
        "required": [
          {
            "material_key": "WATER_BREW",
            "material_name": "Brewing Water",
            "material_role": "process_water",
            "material_type_code": "WATER",
            "material_code": "MAT_WATER_BREW",
            "qty": 1220,
            "uom_code": "L",
            "basis": "per_base"
          },
          {
            "material_key": "MALT_2ROW",
            "material_name": "Two-Row Pale Malt",
            "material_role": "main_substrate",
            "material_type_code": "BASE_MALT",
            "material_code": "MAT_MALT_2ROW",
            "qty": 150,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "FLAKED_BARLEY",
            "material_name": "Flaked Barley",
            "material_role": "foam_adjunct",
            "material_type_code": "ADJUNCT",
            "material_code": "MAT_FLAKED_BARLEY",
            "qty": 25,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "ROASTED_BARLEY",
            "material_name": "Roasted Barley",
            "material_role": "roast_malt",
            "material_type_code": "ROASTED_MALT",
            "material_code": "MAT_ROASTED_BARLEY",
            "qty": 32,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "MALT_CHOCOLATE",
            "material_name": "Chocolate Malt",
            "material_role": "color_malt",
            "material_type_code": "ROASTED_MALT",
            "material_code": "MAT_MALT_CHOCOLATE",
            "qty": 8,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "HOPS_EKG",
            "material_name": "East Kent Goldings",
            "material_role": "bittering",
            "material_type_code": "HOP_PELLET",
            "material_code": "MAT_HOPS_EKG",
            "qty": 4.0,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "YEAST_ALE_IRISH",
            "material_name": "Irish Ale Yeast",
            "material_role": "culture",
            "material_type_code": "DRY_YEAST",
            "material_code": "MAT_YEAST_ALE_IRISH",
            "qty": 5,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "BOTTLE_330",
            "material_name": "330mL Bottle",
            "material_role": "packaging_primary",
            "material_type_code": "BOTTLE",
            "material_code": "PKG_BOTTLE_330",
            "qty": 2880,
            "uom_code": "pcs",
            "basis": "per_base"
          },
          {
            "material_key": "CAP_330",
            "material_name": "Bottle Cap",
            "material_role": "packaging_component",
            "material_type_code": "CROWN_CAP",
            "material_code": "PKG_CAP_330",
            "qty": 2880,
            "uom_code": "pcs",
            "basis": "per_base"
          },
          {
            "material_key": "LABEL_STD",
            "material_name": "Standard Label",
            "material_role": "packaging_component",
            "material_type_code": "LABEL",
            "material_code": "PKG_LABEL_STD",
            "qty": 2880,
            "uom_code": "pcs",
            "basis": "per_base"
          }
        ]
      },
      "flow": {
        "steps": [
          {
            "step_code": "MASH",
            "step_name": "Mashing",
            "step_no": 10,
            "step_type": "process",
            "step_template_code": "STEP_MASH",
            "instructions": "Mash pale malt, flaked barley, roasted barley, and chocolate malt for a dry stout grist.",
            "duration_sec": 5400,
            "material_inputs": [
              { "material_key": "WATER_BREW", "qty": 820, "uom_code": "L", "basis": "per_base", "consumption_mode": "estimate" },
              { "material_key": "MALT_2ROW", "qty": 150, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" },
              { "material_key": "FLAKED_BARLEY", "qty": 25, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" },
              { "material_key": "ROASTED_BARLEY", "qty": 32, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" },
              { "material_key": "MALT_CHOCOLATE", "qty": 8, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" }
            ],
            "material_outputs": [
              { "output_code": "SWEET_WORT", "output_name": "Sweet Wort", "output_type": "intermediate", "qty": 775, "uom_code": "L" }
            ],
            "equipment_requirements": [
              { "equipment_type_code": "MASH_TUN", "equipment_template_code": "MASH_TUN_1000L", "quantity": 1 }
            ],
            "parameters": [
              { "parameter_code": "MASH_TEMP", "target": 67, "min": 65, "max": 69, "uom_code": "C", "required": true },
              { "parameter_code": "MASH_TIME", "target": 90, "uom_code": "min", "required": true }
            ],
            "quality_checks": [
              { "check_code": "QC_PH_MASH", "sampling_point": "end_of_step", "frequency": "per_batch", "required": true }
            ]
          },
          {
            "step_code": "BOIL",
            "step_name": "Boiling",
            "step_no": 20,
            "step_type": "process",
            "step_template_code": "STEP_BOIL",
            "instructions": "Boil wort and add East Kent Goldings for balanced bitterness.",
            "duration_sec": 4500,
            "material_inputs": [
              { "material_key": "HOPS_EKG", "qty": 4.0, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" }
            ],
            "material_outputs": [
              { "output_code": "HOT_WORT", "output_name": "Hot Wort", "output_type": "intermediate", "qty": 745, "uom_code": "L" }
            ],
            "equipment_requirements": [
              { "equipment_type_code": "BOIL_KETTLE", "equipment_template_code": "BOIL_KETTLE_1000L", "quantity": 1 }
            ],
            "parameters": [
              { "parameter_code": "BOIL_TIME", "target": 75, "uom_code": "min", "required": true }
            ]
          },
          {
            "step_code": "FERMENT",
            "step_name": "Fermentation",
            "step_no": 30,
            "step_type": "process",
            "step_template_code": "STEP_FERMENT",
            "instructions": "Pitch Irish ale yeast and ferment for a clean, dry stout profile.",
            "duration_sec": 604800,
            "material_inputs": [
              { "material_key": "YEAST_ALE_IRISH", "qty": 5, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" }
            ],
            "material_outputs": [
              { "output_code": "GREEN_BEER", "output_name": "Green Beer", "output_type": "intermediate", "qty": 700, "uom_code": "L" }
            ],
            "equipment_requirements": [
              { "equipment_type_code": "FERMENTER", "equipment_template_code": "FERMENTER_1000L", "quantity": 1 }
            ],
            "parameters": [
              { "parameter_code": "FERMENT_TEMP", "target": 19, "min": 18, "max": 20, "uom_code": "C", "required": true },
              { "parameter_code": "FERMENT_TIME", "target": 168, "uom_code": "hour", "required": true }
            ],
            "quality_checks": [
              { "check_code": "QC_GRAVITY_END", "sampling_point": "end_of_step", "frequency": "per_batch", "required": true }
            ]
          },
          {
            "step_code": "PACKAGE",
            "step_name": "Packaging",
            "step_no": 40,
            "step_type": "packaging",
            "step_template_code": "STEP_BOTTLE",
            "instructions": "Fill, cap, and label dry stout bottles.",
            "duration_sec": 14400,
            "material_inputs": [
              { "material_key": "BOTTLE_330", "qty": 2880, "uom_code": "pcs", "basis": "per_base", "consumption_mode": "backflush" },
              { "material_key": "CAP_330", "qty": 2880, "uom_code": "pcs", "basis": "per_base", "consumption_mode": "backflush" },
              { "material_key": "LABEL_STD", "qty": 2880, "uom_code": "pcs", "basis": "per_base", "consumption_mode": "backflush" }
            ],
            "material_outputs": [
              { "output_code": "BEER_DRY_STOUT_330", "output_name": "Dry Stout 330mL", "output_type": "primary", "qty": 2880, "uom_code": "pcs" }
            ],
            "equipment_requirements": [
              { "equipment_type_code": "BOTTLING_LINE", "equipment_template_code": "BOTTLING_LINE_STD", "quantity": 1 }
            ],
            "parameters": [
              { "parameter_code": "FILL_VOLUME", "target": 330, "min": 327, "max": 333, "uom_code": "mL", "required": true }
            ],
            "quality_checks": [
              { "check_code": "QC_FILL_VOLUME", "sampling_point": "in_process", "frequency": "hourly", "required": true },
              { "check_code": "QC_LABEL_INSPECTION", "sampling_point": "end_of_step", "frequency": "per_batch", "required": true }
            ]
          }
        ],
        "dependencies": [
          { "from_step_code": "MASH", "to_step_code": "BOIL", "relation_type": "finish_start" },
          { "from_step_code": "BOIL", "to_step_code": "FERMENT", "relation_type": "finish_start" },
          { "from_step_code": "FERMENT", "to_step_code": "PACKAGE", "relation_type": "finish_start" }
        ]
      },
      "quality": {
        "global_checks": [
          {
            "check_code": "QC_ABV_RELEASE",
            "sampling_point": "release",
            "frequency": "per_batch",
            "required": true,
            "acceptance_criteria": {
              "min": 4.0,
              "max": 4.5,
              "uom_code": "%"
            }
          }
        ]
      },
      "documents": [
        { "doc_code": "SOP_DRY_STOUT", "doc_type": "sop", "title": "Dry Stout Brewing SOP", "revision": "A", "required": true }
      ]
    }
    $json$::jsonb,
    jsonb_build_object(
      'industry_code', 'CRAFT_BEER',
      'style_code', 'DRY_STOUT',
      'material_type_map', jsonb_build_object(
        'WATER', v_mt_water,
        'BASE_MALT', v_mt_base_malt,
        'SPECIALTY_MALT', v_mt_specialty_malt,
        'ROASTED_MALT', v_mt_roasted_malt,
        'HOP_PELLET', v_mt_hop,
        'DRY_YEAST', v_mt_yeast,
        'ADJUNCT', v_mt_adjunct,
        'BOTTLE', v_mt_bottle,
        'CROWN_CAP', v_mt_cap,
        'LABEL', v_mt_label,
        'BEER', v_mt_beer
      ),
      'equipment_type_map', jsonb_build_object(
        'MASH_TUN', v_et_mash_tun,
        'BOIL_KETTLE', v_et_boil_kettle,
        'FERMENTER', v_et_fermenter,
        'BOTTLING_LINE', v_et_bottling_line
      ),
      'step_template_map', jsonb_build_object(
        'STEP_MASH', v_step_mash,
        'STEP_BOIL', v_step_boil,
        'STEP_FERMENT', v_step_ferment,
        'STEP_BOTTLE', v_step_package
      ),
      'uom_map', jsonb_build_object(
        'kg', v_uom_kg,
        'L', v_uom_l,
        'C', v_uom_c,
        'min', v_uom_min,
        'hour', v_uom_hour,
        'mL', v_uom_ml,
        '%', v_uom_pct,
        'pcs', v_uom_pcs
      )
    ),
    'recipe_body_v1',
    'CRAFT_BEER_STYLE_V1',
    'approved',
    now(),
    NULL,
    'Seeded dry stout recipe',
    now(),
    NULL
  )
  ON CONFLICT (tenant_id, recipe_id, version_no)
  DO UPDATE SET
    version_label = EXCLUDED.version_label,
    recipe_body_json = EXCLUDED.recipe_body_json,
    resolved_reference_json = EXCLUDED.resolved_reference_json,
    schema_code = EXCLUDED.schema_code,
    template_code = EXCLUDED.template_code,
    status = EXCLUDED.status,
    effective_from = EXCLUDED.effective_from,
    effective_to = EXCLUDED.effective_to,
    change_summary = EXCLUDED.change_summary,
    approved_at = EXCLUDED.approved_at,
    approved_by = EXCLUDED.approved_by,
    updated_at = now()
  RETURNING id INTO v_recipe_version_id;

  UPDATE mes.mst_recipe
     SET current_version_id = v_recipe_version_id,
         updated_at = now()
   WHERE id = v_recipe_id;

  INSERT INTO mes.mst_recipe (
    tenant_id, recipe_code, recipe_name, recipe_category, industry_type, status, current_version_id
  )
  VALUES (
    v_tenant, 'RCP_BEER_AMERICAN_IPA_330', 'American IPA 330mL', 'beer', 'beer', 'active', NULL
  )
  ON CONFLICT (tenant_id, recipe_code)
  DO UPDATE SET
    recipe_name = EXCLUDED.recipe_name,
    recipe_category = EXCLUDED.recipe_category,
    industry_type = EXCLUDED.industry_type,
    status = EXCLUDED.status,
    updated_at = now()
  RETURNING id INTO v_recipe_id;

  INSERT INTO mes.mst_recipe_version (
    tenant_id,
    recipe_id,
    version_no,
    version_label,
    recipe_body_json,
    resolved_reference_json,
    schema_code,
    template_code,
    status,
    effective_from,
    effective_to,
    change_summary,
    approved_at,
    approved_by
  )
  VALUES (
    v_tenant,
    v_recipe_id,
    1,
    'v1.0',
    $json$
    {
      "schema_version": "recipe_body_v1",
      "recipe_info": {
        "recipe_type": "process_manufacturing",
        "industry_type": "beer",
        "description": "American IPA recipe with Columbus bitterness, citrus aroma, and dry hopping.",
        "batch_strategy": "fixed",
        "tags": ["ipa", "ale", "hoppy", "bottle"],
        "notes": "Seeded craft-beer style recipe."
      },
      "base": {
        "quantity": 1000,
        "uom_code": "L",
        "scaling_method": "linear",
        "rounding_rule": "standard"
      },
      "outputs": {
        "primary": [
          {
            "output_code": "BEER_AMERICAN_IPA_330",
            "output_name": "American IPA 330mL",
            "output_type": "primary",
            "qty": 2900,
            "uom_code": "pcs",
            "basis": "per_base"
          }
        ],
        "co_products": [
          {
            "output_code": "SPENT_GRAIN",
            "output_name": "Spent Grain",
            "output_type": "co_product",
            "qty": 145,
            "uom_code": "kg",
            "basis": "yield_based"
          }
        ]
      },
      "materials": {
        "required": [
          {
            "material_key": "WATER_BREW",
            "material_name": "Brewing Water",
            "material_role": "process_water",
            "material_type_code": "WATER",
            "material_code": "MAT_WATER_BREW",
            "qty": 1260,
            "uom_code": "L",
            "basis": "per_base"
          },
          {
            "material_key": "MALT_2ROW",
            "material_name": "Two-Row Pale Malt",
            "material_role": "main_substrate",
            "material_type_code": "BASE_MALT",
            "material_code": "MAT_MALT_2ROW",
            "qty": 185,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "MALT_MUNICH",
            "material_name": "Munich Malt",
            "material_role": "body_malt",
            "material_type_code": "SPECIALTY_MALT",
            "material_code": "MAT_MALT_MUNICH",
            "qty": 18,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "MALT_CARAMEL_40",
            "material_name": "Caramel 40 Malt",
            "material_role": "character_malt",
            "material_type_code": "SPECIALTY_MALT",
            "material_code": "MAT_MALT_CARAMEL_40",
            "qty": 10,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "HOPS_COLUMBUS",
            "material_name": "Columbus Hops",
            "material_role": "bittering",
            "material_type_code": "HOP_PELLET",
            "material_code": "MAT_HOPS_COLUMBUS",
            "qty": 4.0,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "HOPS_CITRA",
            "material_name": "Citra Hops",
            "material_role": "aroma",
            "material_type_code": "HOP_PELLET",
            "material_code": "MAT_HOPS_CITRA",
            "qty": 5.5,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "HOPS_CASCADE",
            "material_name": "Cascade Hops",
            "material_role": "dry_hop",
            "material_type_code": "HOP_PELLET",
            "material_code": "MAT_HOPS_CASCADE",
            "qty": 4.5,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "YEAST_US05",
            "material_name": "US-05 Ale Yeast",
            "material_role": "culture",
            "material_type_code": "DRY_YEAST",
            "material_code": "MAT_YEAST_US05",
            "qty": 6,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "BOTTLE_330",
            "material_name": "330mL Bottle",
            "material_role": "packaging_primary",
            "material_type_code": "BOTTLE",
            "material_code": "PKG_BOTTLE_330",
            "qty": 2900,
            "uom_code": "pcs",
            "basis": "per_base"
          },
          {
            "material_key": "CAP_330",
            "material_name": "Bottle Cap",
            "material_role": "packaging_component",
            "material_type_code": "CROWN_CAP",
            "material_code": "PKG_CAP_330",
            "qty": 2900,
            "uom_code": "pcs",
            "basis": "per_base"
          },
          {
            "material_key": "LABEL_STD",
            "material_name": "Standard Label",
            "material_role": "packaging_component",
            "material_type_code": "LABEL",
            "material_code": "PKG_LABEL_STD",
            "qty": 2900,
            "uom_code": "pcs",
            "basis": "per_base"
          }
        ]
      },
      "flow": {
        "steps": [
          {
            "step_code": "MASH",
            "step_name": "Mashing",
            "step_no": 10,
            "step_type": "process",
            "step_template_code": "STEP_MASH",
            "instructions": "Mash two-row, Munich, and caramel malt for a firm but lean IPA base.",
            "duration_sec": 5400,
            "material_inputs": [
              { "material_key": "WATER_BREW", "qty": 840, "uom_code": "L", "basis": "per_base", "consumption_mode": "estimate" },
              { "material_key": "MALT_2ROW", "qty": 185, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" },
              { "material_key": "MALT_MUNICH", "qty": 18, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" },
              { "material_key": "MALT_CARAMEL_40", "qty": 10, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" }
            ],
            "material_outputs": [
              { "output_code": "SWEET_WORT", "output_name": "Sweet Wort", "output_type": "intermediate", "qty": 780, "uom_code": "L" }
            ],
            "equipment_requirements": [
              { "equipment_type_code": "MASH_TUN", "equipment_template_code": "MASH_TUN_1000L", "quantity": 1 }
            ],
            "parameters": [
              { "parameter_code": "MASH_TEMP", "target": 66, "min": 64, "max": 67, "uom_code": "C", "required": true },
              { "parameter_code": "MASH_TIME", "target": 75, "uom_code": "min", "required": true }
            ],
            "quality_checks": [
              { "check_code": "QC_PH_MASH", "sampling_point": "end_of_step", "frequency": "per_batch", "required": true }
            ]
          },
          {
            "step_code": "BOIL",
            "step_name": "Boiling",
            "step_no": 20,
            "step_type": "process",
            "step_template_code": "STEP_BOIL",
            "instructions": "Boil wort with Columbus for bitterness and early Citra for hot-side aroma.",
            "duration_sec": 4500,
            "material_inputs": [
              { "material_key": "HOPS_COLUMBUS", "qty": 4.0, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" },
              { "material_key": "HOPS_CITRA", "qty": 2.5, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" }
            ],
            "material_outputs": [
              { "output_code": "HOT_WORT", "output_name": "Hot Wort", "output_type": "intermediate", "qty": 750, "uom_code": "L" }
            ],
            "equipment_requirements": [
              { "equipment_type_code": "BOIL_KETTLE", "equipment_template_code": "BOIL_KETTLE_1000L", "quantity": 1 }
            ],
            "parameters": [
              { "parameter_code": "BOIL_TIME", "target": 75, "uom_code": "min", "required": true }
            ]
          },
          {
            "step_code": "FERMENT",
            "step_name": "Fermentation",
            "step_no": 30,
            "step_type": "process",
            "step_template_code": "STEP_FERMENT",
            "instructions": "Pitch US-05 and ferment clean before dry hopping.",
            "duration_sec": 604800,
            "material_inputs": [
              { "material_key": "YEAST_US05", "qty": 6, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" }
            ],
            "material_outputs": [
              { "output_code": "GREEN_BEER", "output_name": "Green Beer", "output_type": "intermediate", "qty": 710, "uom_code": "L" }
            ],
            "equipment_requirements": [
              { "equipment_type_code": "FERMENTER", "equipment_template_code": "FERMENTER_1000L", "quantity": 1 }
            ],
            "parameters": [
              { "parameter_code": "FERMENT_TEMP", "target": 18.5, "min": 17.5, "max": 19.5, "uom_code": "C", "required": true },
              { "parameter_code": "FERMENT_TIME", "target": 168, "uom_code": "hour", "required": true }
            ],
            "quality_checks": [
              { "check_code": "QC_GRAVITY_END", "sampling_point": "end_of_step", "frequency": "per_batch", "required": true }
            ]
          },
          {
            "step_code": "DRY_HOP",
            "step_name": "Dry Hopping",
            "step_no": 35,
            "step_type": "process",
            "instructions": "Dry hop with Citra and Cascade to build the final aroma profile.",
            "duration_sec": 259200,
            "material_inputs": [
              { "material_key": "HOPS_CITRA", "qty": 3.0, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" },
              { "material_key": "HOPS_CASCADE", "qty": 4.5, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" }
            ],
            "material_outputs": [
              { "output_code": "GREEN_BEER_DRY_HOP", "output_name": "Dry-Hopped Beer", "output_type": "intermediate", "qty": 695, "uom_code": "L" }
            ],
            "equipment_requirements": [
              { "equipment_type_code": "FERMENTER", "equipment_template_code": "FERMENTER_1000L", "quantity": 1 }
            ]
          },
          {
            "step_code": "PACKAGE",
            "step_name": "Packaging",
            "step_no": 40,
            "step_type": "packaging",
            "step_template_code": "STEP_BOTTLE",
            "instructions": "Fill, cap, and label American IPA bottles.",
            "duration_sec": 14400,
            "material_inputs": [
              { "material_key": "BOTTLE_330", "qty": 2900, "uom_code": "pcs", "basis": "per_base", "consumption_mode": "backflush" },
              { "material_key": "CAP_330", "qty": 2900, "uom_code": "pcs", "basis": "per_base", "consumption_mode": "backflush" },
              { "material_key": "LABEL_STD", "qty": 2900, "uom_code": "pcs", "basis": "per_base", "consumption_mode": "backflush" }
            ],
            "material_outputs": [
              { "output_code": "BEER_AMERICAN_IPA_330", "output_name": "American IPA 330mL", "output_type": "primary", "qty": 2900, "uom_code": "pcs" }
            ],
            "equipment_requirements": [
              { "equipment_type_code": "BOTTLING_LINE", "equipment_template_code": "BOTTLING_LINE_STD", "quantity": 1 }
            ],
            "parameters": [
              { "parameter_code": "FILL_VOLUME", "target": 330, "min": 327, "max": 333, "uom_code": "mL", "required": true }
            ],
            "quality_checks": [
              { "check_code": "QC_FILL_VOLUME", "sampling_point": "in_process", "frequency": "hourly", "required": true },
              { "check_code": "QC_LABEL_INSPECTION", "sampling_point": "end_of_step", "frequency": "per_batch", "required": true }
            ]
          }
        ],
        "dependencies": [
          { "from_step_code": "MASH", "to_step_code": "BOIL", "relation_type": "finish_start" },
          { "from_step_code": "BOIL", "to_step_code": "FERMENT", "relation_type": "finish_start" },
          { "from_step_code": "FERMENT", "to_step_code": "DRY_HOP", "relation_type": "finish_start" },
          { "from_step_code": "DRY_HOP", "to_step_code": "PACKAGE", "relation_type": "finish_start" }
        ]
      },
      "quality": {
        "global_checks": [
          {
            "check_code": "QC_ABV_RELEASE",
            "sampling_point": "release",
            "frequency": "per_batch",
            "required": true,
            "acceptance_criteria": {
              "min": 6.3,
              "max": 6.9,
              "uom_code": "%"
            }
          }
        ]
      },
      "documents": [
        { "doc_code": "SOP_AMERICAN_IPA", "doc_type": "sop", "title": "American IPA Brewing SOP", "revision": "A", "required": true }
      ]
    }
    $json$::jsonb,
    jsonb_build_object(
      'industry_code', 'CRAFT_BEER',
      'style_code', 'AMERICAN_IPA',
      'material_type_map', jsonb_build_object(
        'WATER', v_mt_water,
        'BASE_MALT', v_mt_base_malt,
        'SPECIALTY_MALT', v_mt_specialty_malt,
        'ROASTED_MALT', v_mt_roasted_malt,
        'HOP_PELLET', v_mt_hop,
        'DRY_YEAST', v_mt_yeast,
        'ADJUNCT', v_mt_adjunct,
        'BOTTLE', v_mt_bottle,
        'CROWN_CAP', v_mt_cap,
        'LABEL', v_mt_label,
        'BEER', v_mt_beer
      ),
      'equipment_type_map', jsonb_build_object(
        'MASH_TUN', v_et_mash_tun,
        'BOIL_KETTLE', v_et_boil_kettle,
        'FERMENTER', v_et_fermenter,
        'BOTTLING_LINE', v_et_bottling_line
      ),
      'step_template_map', jsonb_build_object(
        'STEP_MASH', v_step_mash,
        'STEP_BOIL', v_step_boil,
        'STEP_FERMENT', v_step_ferment,
        'STEP_BOTTLE', v_step_package
      ),
      'uom_map', jsonb_build_object(
        'kg', v_uom_kg,
        'L', v_uom_l,
        'C', v_uom_c,
        'min', v_uom_min,
        'hour', v_uom_hour,
        'mL', v_uom_ml,
        '%', v_uom_pct,
        'pcs', v_uom_pcs
      )
    ),
    'recipe_body_v1',
    'CRAFT_BEER_STYLE_V1',
    'approved',
    now(),
    NULL,
    'Seeded American IPA recipe',
    now(),
    NULL
  )
  ON CONFLICT (tenant_id, recipe_id, version_no)
  DO UPDATE SET
    version_label = EXCLUDED.version_label,
    recipe_body_json = EXCLUDED.recipe_body_json,
    resolved_reference_json = EXCLUDED.resolved_reference_json,
    schema_code = EXCLUDED.schema_code,
    template_code = EXCLUDED.template_code,
    status = EXCLUDED.status,
    effective_from = EXCLUDED.effective_from,
    effective_to = EXCLUDED.effective_to,
    change_summary = EXCLUDED.change_summary,
    approved_at = EXCLUDED.approved_at,
    approved_by = EXCLUDED.approved_by,
    updated_at = now()
  RETURNING id INTO v_recipe_version_id;

  UPDATE mes.mst_recipe
     SET current_version_id = v_recipe_version_id,
         updated_at = now()
   WHERE id = v_recipe_id;

  INSERT INTO mes.mst_recipe (
    tenant_id, recipe_code, recipe_name, recipe_category, industry_type, status, current_version_id
  )
  VALUES (
    v_tenant, 'RCP_BEER_AMERICAN_PALE_ALE_330', 'American Pale Ale 330mL', 'beer', 'beer', 'active', NULL
  )
  ON CONFLICT (tenant_id, recipe_code)
  DO UPDATE SET
    recipe_name = EXCLUDED.recipe_name,
    recipe_category = EXCLUDED.recipe_category,
    industry_type = EXCLUDED.industry_type,
    status = EXCLUDED.status,
    updated_at = now()
  RETURNING id INTO v_recipe_id;

  INSERT INTO mes.mst_recipe_version (
    tenant_id,
    recipe_id,
    version_no,
    version_label,
    recipe_body_json,
    resolved_reference_json,
    schema_code,
    template_code,
    status,
    effective_from,
    effective_to,
    change_summary,
    approved_at,
    approved_by
  )
  VALUES (
    v_tenant,
    v_recipe_id,
    1,
    'v1.0',
    $json$
    {
      "schema_version": "recipe_body_v1",
      "recipe_info": {
        "recipe_type": "process_manufacturing",
        "industry_type": "beer",
        "description": "American Pale Ale recipe with citrus hop character and balanced malt support.",
        "batch_strategy": "fixed",
        "tags": ["pale_ale", "ale", "bottle"],
        "notes": "Seeded craft-beer style recipe."
      },
      "base": {
        "quantity": 1000,
        "uom_code": "L",
        "scaling_method": "linear",
        "rounding_rule": "standard"
      },
      "outputs": {
        "primary": [
          {
            "output_code": "BEER_AMERICAN_PALE_ALE_330",
            "output_name": "American Pale Ale 330mL",
            "output_type": "primary",
            "qty": 2950,
            "uom_code": "pcs",
            "basis": "per_base"
          }
        ],
        "co_products": [
          {
            "output_code": "SPENT_GRAIN",
            "output_name": "Spent Grain",
            "output_type": "co_product",
            "qty": 138,
            "uom_code": "kg",
            "basis": "yield_based"
          }
        ]
      },
      "materials": {
        "required": [
          {
            "material_key": "WATER_BREW",
            "material_name": "Brewing Water",
            "material_role": "process_water",
            "material_type_code": "WATER",
            "material_code": "MAT_WATER_BREW",
            "qty": 1240,
            "uom_code": "L",
            "basis": "per_base"
          },
          {
            "material_key": "MALT_2ROW",
            "material_name": "Two-Row Pale Malt",
            "material_role": "main_substrate",
            "material_type_code": "BASE_MALT",
            "material_code": "MAT_MALT_2ROW",
            "qty": 170,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "MALT_MUNICH",
            "material_name": "Munich Malt",
            "material_role": "body_malt",
            "material_type_code": "SPECIALTY_MALT",
            "material_code": "MAT_MALT_MUNICH",
            "qty": 12,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "MALT_CARAMEL_40",
            "material_name": "Caramel 40 Malt",
            "material_role": "character_malt",
            "material_type_code": "SPECIALTY_MALT",
            "material_code": "MAT_MALT_CARAMEL_40",
            "qty": 8,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "HOPS_CENTENNIAL",
            "material_name": "Centennial Hops",
            "material_role": "bittering",
            "material_type_code": "HOP_PELLET",
            "material_code": "MAT_HOPS_CENTENNIAL",
            "qty": 2.8,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "HOPS_CASCADE",
            "material_name": "Cascade Hops",
            "material_role": "aroma",
            "material_type_code": "HOP_PELLET",
            "material_code": "MAT_HOPS_CASCADE",
            "qty": 3.2,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "YEAST_US05",
            "material_name": "US-05 Ale Yeast",
            "material_role": "culture",
            "material_type_code": "DRY_YEAST",
            "material_code": "MAT_YEAST_US05",
            "qty": 5.5,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "BOTTLE_330",
            "material_name": "330mL Bottle",
            "material_role": "packaging_primary",
            "material_type_code": "BOTTLE",
            "material_code": "PKG_BOTTLE_330",
            "qty": 2950,
            "uom_code": "pcs",
            "basis": "per_base"
          },
          {
            "material_key": "CAP_330",
            "material_name": "Bottle Cap",
            "material_role": "packaging_component",
            "material_type_code": "CROWN_CAP",
            "material_code": "PKG_CAP_330",
            "qty": 2950,
            "uom_code": "pcs",
            "basis": "per_base"
          },
          {
            "material_key": "LABEL_STD",
            "material_name": "Standard Label",
            "material_role": "packaging_component",
            "material_type_code": "LABEL",
            "material_code": "PKG_LABEL_STD",
            "qty": 2950,
            "uom_code": "pcs",
            "basis": "per_base"
          }
        ]
      },
      "flow": {
        "steps": [
          {
            "step_code": "MASH",
            "step_name": "Mashing",
            "step_no": 10,
            "step_type": "process",
            "step_template_code": "STEP_MASH",
            "instructions": "Mash two-row, Munich, and caramel malt for a balanced pale ale base.",
            "duration_sec": 5100,
            "material_inputs": [
              { "material_key": "WATER_BREW", "qty": 830, "uom_code": "L", "basis": "per_base", "consumption_mode": "estimate" },
              { "material_key": "MALT_2ROW", "qty": 170, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" },
              { "material_key": "MALT_MUNICH", "qty": 12, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" },
              { "material_key": "MALT_CARAMEL_40", "qty": 8, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" }
            ],
            "material_outputs": [
              { "output_code": "SWEET_WORT", "output_name": "Sweet Wort", "output_type": "intermediate", "qty": 785, "uom_code": "L" }
            ],
            "equipment_requirements": [
              { "equipment_type_code": "MASH_TUN", "equipment_template_code": "MASH_TUN_1000L", "quantity": 1 }
            ],
            "parameters": [
              { "parameter_code": "MASH_TEMP", "target": 66, "min": 64, "max": 67, "uom_code": "C", "required": true },
              { "parameter_code": "MASH_TIME", "target": 85, "uom_code": "min", "required": true }
            ],
            "quality_checks": [
              { "check_code": "QC_PH_MASH", "sampling_point": "end_of_step", "frequency": "per_batch", "required": true }
            ]
          },
          {
            "step_code": "BOIL",
            "step_name": "Boiling",
            "step_no": 20,
            "step_type": "process",
            "step_template_code": "STEP_BOIL",
            "instructions": "Boil wort with Centennial and Cascade for classic American pale ale hop character.",
            "duration_sec": 4200,
            "material_inputs": [
              { "material_key": "HOPS_CENTENNIAL", "qty": 2.8, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" },
              { "material_key": "HOPS_CASCADE", "qty": 3.2, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" }
            ],
            "material_outputs": [
              { "output_code": "HOT_WORT", "output_name": "Hot Wort", "output_type": "intermediate", "qty": 755, "uom_code": "L" }
            ],
            "equipment_requirements": [
              { "equipment_type_code": "BOIL_KETTLE", "equipment_template_code": "BOIL_KETTLE_1000L", "quantity": 1 }
            ],
            "parameters": [
              { "parameter_code": "BOIL_TIME", "target": 70, "uom_code": "min", "required": true }
            ]
          },
          {
            "step_code": "FERMENT",
            "step_name": "Fermentation",
            "step_no": 30,
            "step_type": "process",
            "step_template_code": "STEP_FERMENT",
            "instructions": "Pitch US-05 and ferment clean to keep the pale ale profile bright and hop-forward.",
            "duration_sec": 518400,
            "material_inputs": [
              { "material_key": "YEAST_US05", "qty": 5.5, "uom_code": "kg", "basis": "per_base", "consumption_mode": "estimate" }
            ],
            "material_outputs": [
              { "output_code": "GREEN_BEER", "output_name": "Green Beer", "output_type": "intermediate", "qty": 715, "uom_code": "L" }
            ],
            "equipment_requirements": [
              { "equipment_type_code": "FERMENTER", "equipment_template_code": "FERMENTER_1000L", "quantity": 1 }
            ],
            "parameters": [
              { "parameter_code": "FERMENT_TEMP", "target": 18.5, "min": 17.5, "max": 19.5, "uom_code": "C", "required": true },
              { "parameter_code": "FERMENT_TIME", "target": 144, "uom_code": "hour", "required": true }
            ],
            "quality_checks": [
              { "check_code": "QC_GRAVITY_END", "sampling_point": "end_of_step", "frequency": "per_batch", "required": true }
            ]
          },
          {
            "step_code": "PACKAGE",
            "step_name": "Packaging",
            "step_no": 40,
            "step_type": "packaging",
            "step_template_code": "STEP_BOTTLE",
            "instructions": "Fill, cap, and label American pale ale bottles.",
            "duration_sec": 14400,
            "material_inputs": [
              { "material_key": "BOTTLE_330", "qty": 2950, "uom_code": "pcs", "basis": "per_base", "consumption_mode": "backflush" },
              { "material_key": "CAP_330", "qty": 2950, "uom_code": "pcs", "basis": "per_base", "consumption_mode": "backflush" },
              { "material_key": "LABEL_STD", "qty": 2950, "uom_code": "pcs", "basis": "per_base", "consumption_mode": "backflush" }
            ],
            "material_outputs": [
              { "output_code": "BEER_AMERICAN_PALE_ALE_330", "output_name": "American Pale Ale 330mL", "output_type": "primary", "qty": 2950, "uom_code": "pcs" }
            ],
            "equipment_requirements": [
              { "equipment_type_code": "BOTTLING_LINE", "equipment_template_code": "BOTTLING_LINE_STD", "quantity": 1 }
            ],
            "parameters": [
              { "parameter_code": "FILL_VOLUME", "target": 330, "min": 327, "max": 333, "uom_code": "mL", "required": true }
            ],
            "quality_checks": [
              { "check_code": "QC_FILL_VOLUME", "sampling_point": "in_process", "frequency": "hourly", "required": true },
              { "check_code": "QC_LABEL_INSPECTION", "sampling_point": "end_of_step", "frequency": "per_batch", "required": true }
            ]
          }
        ],
        "dependencies": [
          { "from_step_code": "MASH", "to_step_code": "BOIL", "relation_type": "finish_start" },
          { "from_step_code": "BOIL", "to_step_code": "FERMENT", "relation_type": "finish_start" },
          { "from_step_code": "FERMENT", "to_step_code": "PACKAGE", "relation_type": "finish_start" }
        ]
      },
      "quality": {
        "global_checks": [
          {
            "check_code": "QC_ABV_RELEASE",
            "sampling_point": "release",
            "frequency": "per_batch",
            "required": true,
            "acceptance_criteria": {
              "min": 5.0,
              "max": 5.6,
              "uom_code": "%"
            }
          }
        ]
      },
      "documents": [
        { "doc_code": "SOP_AMERICAN_PALE_ALE", "doc_type": "sop", "title": "American Pale Ale Brewing SOP", "revision": "A", "required": true }
      ]
    }
    $json$::jsonb,
    jsonb_build_object(
      'industry_code', 'CRAFT_BEER',
      'style_code', 'AMERICAN_PALE_ALE',
      'material_type_map', jsonb_build_object(
        'WATER', v_mt_water,
        'BASE_MALT', v_mt_base_malt,
        'SPECIALTY_MALT', v_mt_specialty_malt,
        'ROASTED_MALT', v_mt_roasted_malt,
        'HOP_PELLET', v_mt_hop,
        'DRY_YEAST', v_mt_yeast,
        'ADJUNCT', v_mt_adjunct,
        'BOTTLE', v_mt_bottle,
        'CROWN_CAP', v_mt_cap,
        'LABEL', v_mt_label,
        'BEER', v_mt_beer
      ),
      'equipment_type_map', jsonb_build_object(
        'MASH_TUN', v_et_mash_tun,
        'BOIL_KETTLE', v_et_boil_kettle,
        'FERMENTER', v_et_fermenter,
        'BOTTLING_LINE', v_et_bottling_line
      ),
      'step_template_map', jsonb_build_object(
        'STEP_MASH', v_step_mash,
        'STEP_BOIL', v_step_boil,
        'STEP_FERMENT', v_step_ferment,
        'STEP_BOTTLE', v_step_package
      ),
      'uom_map', jsonb_build_object(
        'kg', v_uom_kg,
        'L', v_uom_l,
        'C', v_uom_c,
        'min', v_uom_min,
        'hour', v_uom_hour,
        'mL', v_uom_ml,
        '%', v_uom_pct,
        'pcs', v_uom_pcs
      )
    ),
    'recipe_body_v1',
    'CRAFT_BEER_STYLE_V1',
    'approved',
    now(),
    NULL,
    'Seeded American Pale Ale recipe',
    now(),
    NULL
  )
  ON CONFLICT (tenant_id, recipe_id, version_no)
  DO UPDATE SET
    version_label = EXCLUDED.version_label,
    recipe_body_json = EXCLUDED.recipe_body_json,
    resolved_reference_json = EXCLUDED.resolved_reference_json,
    schema_code = EXCLUDED.schema_code,
    template_code = EXCLUDED.template_code,
    status = EXCLUDED.status,
    effective_from = EXCLUDED.effective_from,
    effective_to = EXCLUDED.effective_to,
    change_summary = EXCLUDED.change_summary,
    approved_at = EXCLUDED.approved_at,
    approved_by = EXCLUDED.approved_by,
    updated_at = now()
  RETURNING id INTO v_recipe_version_id;

  UPDATE mes.mst_recipe
     SET current_version_id = v_recipe_version_id,
         updated_at = now()
   WHERE id = v_recipe_id;
END;
$seed$;
