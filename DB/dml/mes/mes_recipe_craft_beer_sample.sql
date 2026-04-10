-- Craft-beer sample DML for the MES recipe model.
-- This script is idempotent by business code where practical.
-- It assumes:
--   - public.industry already contains craft beer with industry_id = 00000000-0000-0000-0000-000000000000
--   - public.type_def exists
--   - public.mst_uom exists
--   - mes.* recipe tables from DB/ddl/mes_recipe.sql already exist
--
-- Tenant note:
--   - When app_current_tenant_id() is available, that tenant is used.
--   - Otherwise the fallback sample tenant UUID below is used.

DO $$
DECLARE
  v_tenant uuid := COALESCE(app_current_tenant_id(), '2a231822-aa8d-452a-aa5f-9f5e4293cdaa'::uuid);
  v_industry_id uuid := '00000000-0000-0000-0000-000000000000'::uuid;

  v_uom_kg uuid;
  v_uom_l uuid;
  v_uom_c uuid;
  v_uom_min uuid;
  v_uom_hour uuid;
  v_uom_ml uuid;
  v_uom_pct uuid;
  v_uom_pcs uuid;

  v_mt_water uuid;
  v_mt_malt uuid;
  v_mt_hops uuid;
  v_mt_yeast uuid;
  v_mt_packaging uuid;
  v_mt_beer uuid;

  v_et_mash_tun uuid;
  v_et_boil_kettle uuid;
  v_et_fermenter uuid;
  v_et_brite_tank uuid;
  v_et_bottling_line uuid;

  v_eqtpl_mash uuid;
  v_eqtpl_boil uuid;
  v_eqtpl_ferm uuid;
  v_eqtpl_brite uuid;
  v_eqtpl_pack uuid;

  v_param_mash_temp uuid;
  v_param_mash_time uuid;
  v_param_boil_time uuid;
  v_param_ferment_temp uuid;
  v_param_ferment_time uuid;
  v_param_fill_volume uuid;
  v_param_abv uuid;

  v_qc_ph_mash uuid;
  v_qc_gravity_end uuid;
  v_qc_fill_volume uuid;
  v_qc_label_inspection uuid;
  v_qc_abv_release uuid;

  v_step_mash uuid;
  v_step_boil uuid;
  v_step_ferment uuid;
  v_step_package uuid;

  v_recipe_id uuid;
  v_recipe_version_id uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM public.industry
     WHERE industry_id = v_industry_id
  ) THEN
    RAISE EXCEPTION 'Required craft beer industry row is missing: %', v_industry_id;
  END IF;

  INSERT INTO public.mst_uom (
    tenant_id,
    scope,
    owner_id,
    industry_id,
    code,
    name,
    dimension,
    base_factor,
    base_code,
    is_base_unit,
    meta
  )
  VALUES (
    v_tenant,
    'tenant',
    v_tenant,
    v_industry_id,
    'pcs',
    'Pieces',
    NULL,
    NULL,
    NULL,
    false,
    '{"label":{"en":"Pieces","ja":"個"}}'::jsonb
  )
  ON CONFLICT (tenant_id, code)
  DO UPDATE SET
    name = EXCLUDED.name,
    meta = EXCLUDED.meta;

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
     AND tenant_id = v_tenant
   LIMIT 1;

  IF v_uom_kg IS NULL OR v_uom_l IS NULL OR v_uom_c IS NULL OR v_uom_min IS NULL
     OR v_uom_hour IS NULL OR v_uom_ml IS NULL OR v_uom_pct IS NULL OR v_uom_pcs IS NULL THEN
    RAISE EXCEPTION 'Required UOM rows are missing. Seed mst_uom first.';
  END IF;

  INSERT INTO public.type_def (
    tenant_id, scope, owner_id, domain, industry_id, code, name, name_i18n, sort_order, meta, is_active
  )
  VALUES
    (v_tenant, 'tenant', v_tenant, 'material_type', v_industry_id, 'WATER', 'Water', '{"ja":"水","en":"Water"}'::jsonb, 10, '{"category":"raw_material"}'::jsonb, true),
    (v_tenant, 'tenant', v_tenant, 'material_type', v_industry_id, 'MALT', 'Malt', '{"ja":"麦芽","en":"Malt"}'::jsonb, 20, '{"category":"raw_material"}'::jsonb, true),
    (v_tenant, 'tenant', v_tenant, 'material_type', v_industry_id, 'HOPS', 'Hops', '{"ja":"ホップ","en":"Hops"}'::jsonb, 30, '{"category":"raw_material"}'::jsonb, true),
    (v_tenant, 'tenant', v_tenant, 'material_type', v_industry_id, 'YEAST', 'Yeast', '{"ja":"酵母","en":"Yeast"}'::jsonb, 40, '{"category":"raw_material"}'::jsonb, true),
    (v_tenant, 'tenant', v_tenant, 'material_type', v_industry_id, 'PACKAGING', 'Packaging', '{"ja":"包装資材","en":"Packaging"}'::jsonb, 50, '{"category":"packaging"}'::jsonb, true),
    (v_tenant, 'tenant', v_tenant, 'material_type', v_industry_id, 'BEER', 'Beer', '{"ja":"ビール","en":"Beer"}'::jsonb, 60, '{"category":"finished_good"}'::jsonb, true),
    (v_tenant, 'tenant', v_tenant, 'equipment_type', v_industry_id, 'MASH_TUN', 'Mash Tun', '{"ja":"糖化槽","en":"Mash Tun"}'::jsonb, 10, '{"process_group":"brewhouse"}'::jsonb, true),
    (v_tenant, 'tenant', v_tenant, 'equipment_type', v_industry_id, 'BOIL_KETTLE', 'Boil Kettle', '{"ja":"煮沸釜","en":"Boil Kettle"}'::jsonb, 20, '{"process_group":"brewhouse"}'::jsonb, true),
    (v_tenant, 'tenant', v_tenant, 'equipment_type', v_industry_id, 'FERMENTER', 'Fermenter', '{"ja":"発酵タンク","en":"Fermenter"}'::jsonb, 30, '{"process_group":"cellar"}'::jsonb, true),
    (v_tenant, 'tenant', v_tenant, 'equipment_type', v_industry_id, 'BRITE_TANK', 'Brite Tank', '{"ja":"ブライトタンク","en":"Brite Tank"}'::jsonb, 40, '{"process_group":"cellar"}'::jsonb, true),
    (v_tenant, 'tenant', v_tenant, 'equipment_type', v_industry_id, 'BOTTLING_LINE', 'Bottling Line', '{"ja":"瓶詰ライン","en":"Bottling Line"}'::jsonb, 50, '{"process_group":"packaging"}'::jsonb, true)
  ON CONFLICT (tenant_id, domain, industry_id, code)
  DO UPDATE SET
    name = EXCLUDED.name,
    name_i18n = EXCLUDED.name_i18n,
    sort_order = EXCLUDED.sort_order,
    meta = EXCLUDED.meta,
    is_active = EXCLUDED.is_active,
    updated_at = now();

  SELECT type_id INTO v_mt_water FROM public.type_def WHERE tenant_id = v_tenant AND domain = 'material_type' AND industry_id = v_industry_id AND code = 'WATER';
  SELECT type_id INTO v_mt_malt FROM public.type_def WHERE tenant_id = v_tenant AND domain = 'material_type' AND industry_id = v_industry_id AND code = 'MALT';
  SELECT type_id INTO v_mt_hops FROM public.type_def WHERE tenant_id = v_tenant AND domain = 'material_type' AND industry_id = v_industry_id AND code = 'HOPS';
  SELECT type_id INTO v_mt_yeast FROM public.type_def WHERE tenant_id = v_tenant AND domain = 'material_type' AND industry_id = v_industry_id AND code = 'YEAST';
  SELECT type_id INTO v_mt_packaging FROM public.type_def WHERE tenant_id = v_tenant AND domain = 'material_type' AND industry_id = v_industry_id AND code = 'PACKAGING';
  SELECT type_id INTO v_mt_beer FROM public.type_def WHERE tenant_id = v_tenant AND domain = 'material_type' AND industry_id = v_industry_id AND code = 'BEER';

  SELECT type_id INTO v_et_mash_tun FROM public.type_def WHERE tenant_id = v_tenant AND domain = 'equipment_type' AND industry_id = v_industry_id AND code = 'MASH_TUN';
  SELECT type_id INTO v_et_boil_kettle FROM public.type_def WHERE tenant_id = v_tenant AND domain = 'equipment_type' AND industry_id = v_industry_id AND code = 'BOIL_KETTLE';
  SELECT type_id INTO v_et_fermenter FROM public.type_def WHERE tenant_id = v_tenant AND domain = 'equipment_type' AND industry_id = v_industry_id AND code = 'FERMENTER';
  SELECT type_id INTO v_et_brite_tank FROM public.type_def WHERE tenant_id = v_tenant AND domain = 'equipment_type' AND industry_id = v_industry_id AND code = 'BRITE_TANK';
  SELECT type_id INTO v_et_bottling_line FROM public.type_def WHERE tenant_id = v_tenant AND domain = 'equipment_type' AND industry_id = v_industry_id AND code = 'BOTTLING_LINE';

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
    (v_tenant, 'MAT_MALT_PALE', 'Pale Malt', v_mt_malt, v_uom_kg, 'raw_material', true, true, '{"material_key":"MALT_BASE"}'::jsonb, 'active'),
    (v_tenant, 'MAT_HOPS_SAAZ', 'Saaz Hops', v_mt_hops, v_uom_kg, 'raw_material', true, true, '{"material_key":"HOPS_BITTER"}'::jsonb, 'active'),
    (v_tenant, 'MAT_YEAST_LAGER', 'Lager Yeast', v_mt_yeast, v_uom_kg, 'raw_material', true, true, '{"material_key":"YEAST_MAIN"}'::jsonb, 'active'),
    (v_tenant, 'PKG_BOTTLE_330', '330mL Bottle', v_mt_packaging, v_uom_pcs, 'packaging', true, true, '{"material_key":"BOTTLE_330"}'::jsonb, 'active'),
    (v_tenant, 'PKG_CAP_330', 'Bottle Cap', v_mt_packaging, v_uom_pcs, 'packaging', true, true, '{"material_key":"CAP_330"}'::jsonb, 'active'),
    (v_tenant, 'PKG_LABEL_STD', 'Standard Label', v_mt_packaging, v_uom_pcs, 'packaging', true, true, '{"material_key":"LABEL_STD"}'::jsonb, 'active'),
    (v_tenant, 'FG_LAGER_330', 'Lager Beer 330mL', v_mt_beer, v_uom_pcs, 'finished_good', true, true, '{"material_key":"BEER_LAGER_330"}'::jsonb, 'active')
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

  INSERT INTO mes.mst_equipment_template (
    tenant_id,
    template_code,
    template_name,
    equipment_type_id,
    capacity_min,
    capacity_max,
    capacity_uom_id,
    capability_json,
    status
  )
  VALUES
    (v_tenant, 'MASH_TUN_1000L', 'Mash Tun 1000L', v_et_mash_tun, 800, 1200, v_uom_l, '{"heating":true,"agitation":true}'::jsonb, 'active'),
    (v_tenant, 'BOIL_KETTLE_1000L', 'Boil Kettle 1000L', v_et_boil_kettle, 800, 1200, v_uom_l, '{"steam_heating":true,"whirlpool_capable":true}'::jsonb, 'active'),
    (v_tenant, 'FERMENTER_1000L', 'Fermenter 1000L', v_et_fermenter, 800, 1200, v_uom_l, '{"temperature_control":true,"pressure_capable":true}'::jsonb, 'active'),
    (v_tenant, 'BRITE_TANK_1000L', 'Brite Tank 1000L', v_et_brite_tank, 800, 1200, v_uom_l, '{"carbonation":true,"pressure_capable":true}'::jsonb, 'active'),
    (v_tenant, 'BOTTLING_LINE_STD', 'Standard Bottling Line', v_et_bottling_line, NULL, NULL, NULL, '{"speed_bph":3000,"rinser":true,"capper":true,"labeler":true}'::jsonb, 'active')
  ON CONFLICT (tenant_id, template_code)
  DO UPDATE SET
    template_name = EXCLUDED.template_name,
    equipment_type_id = EXCLUDED.equipment_type_id,
    capacity_min = EXCLUDED.capacity_min,
    capacity_max = EXCLUDED.capacity_max,
    capacity_uom_id = EXCLUDED.capacity_uom_id,
    capability_json = EXCLUDED.capability_json,
    status = EXCLUDED.status,
    updated_at = now();

  SELECT id INTO v_eqtpl_mash FROM mes.mst_equipment_template WHERE tenant_id = v_tenant AND template_code = 'MASH_TUN_1000L';
  SELECT id INTO v_eqtpl_boil FROM mes.mst_equipment_template WHERE tenant_id = v_tenant AND template_code = 'BOIL_KETTLE_1000L';
  SELECT id INTO v_eqtpl_ferm FROM mes.mst_equipment_template WHERE tenant_id = v_tenant AND template_code = 'FERMENTER_1000L';
  SELECT id INTO v_eqtpl_brite FROM mes.mst_equipment_template WHERE tenant_id = v_tenant AND template_code = 'BRITE_TANK_1000L';
  SELECT id INTO v_eqtpl_pack FROM mes.mst_equipment_template WHERE tenant_id = v_tenant AND template_code = 'BOTTLING_LINE_STD';

  INSERT INTO mes.mst_parameter_def (
    tenant_id, parameter_code, parameter_name, data_type, default_uom_id, precision_digits, min_value, max_value, status
  )
  VALUES
    (v_tenant, 'MASH_TEMP', 'Mash Temperature', 'number', v_uom_c, 2, 0, 100, 'active'),
    (v_tenant, 'MASH_TIME', 'Mash Time', 'number', v_uom_min, 0, 0, 600, 'active'),
    (v_tenant, 'BOIL_TIME', 'Boil Time', 'number', v_uom_min, 0, 0, 600, 'active'),
    (v_tenant, 'FERMENT_TEMP', 'Fermentation Temperature', 'number', v_uom_c, 2, -5, 40, 'active'),
    (v_tenant, 'FERMENT_TIME', 'Fermentation Time', 'number', v_uom_hour, 0, 0, 1000, 'active'),
    (v_tenant, 'FILL_VOLUME', 'Fill Volume', 'number', v_uom_ml, 1, 0, 1000, 'active'),
    (v_tenant, 'ABV', 'Alcohol By Volume', 'number', v_uom_pct, 2, 0, 20, 'active')
  ON CONFLICT (tenant_id, parameter_code)
  DO UPDATE SET
    parameter_name = EXCLUDED.parameter_name,
    data_type = EXCLUDED.data_type,
    default_uom_id = EXCLUDED.default_uom_id,
    precision_digits = EXCLUDED.precision_digits,
    min_value = EXCLUDED.min_value,
    max_value = EXCLUDED.max_value,
    status = EXCLUDED.status,
    updated_at = now();

  SELECT id INTO v_param_mash_temp FROM mes.mst_parameter_def WHERE tenant_id = v_tenant AND parameter_code = 'MASH_TEMP';
  SELECT id INTO v_param_mash_time FROM mes.mst_parameter_def WHERE tenant_id = v_tenant AND parameter_code = 'MASH_TIME';
  SELECT id INTO v_param_boil_time FROM mes.mst_parameter_def WHERE tenant_id = v_tenant AND parameter_code = 'BOIL_TIME';
  SELECT id INTO v_param_ferment_temp FROM mes.mst_parameter_def WHERE tenant_id = v_tenant AND parameter_code = 'FERMENT_TEMP';
  SELECT id INTO v_param_ferment_time FROM mes.mst_parameter_def WHERE tenant_id = v_tenant AND parameter_code = 'FERMENT_TIME';
  SELECT id INTO v_param_fill_volume FROM mes.mst_parameter_def WHERE tenant_id = v_tenant AND parameter_code = 'FILL_VOLUME';
  SELECT id INTO v_param_abv FROM mes.mst_parameter_def WHERE tenant_id = v_tenant AND parameter_code = 'ABV';

  INSERT INTO mes.mst_quality_check (
    tenant_id, check_code, check_name, check_type, parameter_json, status
  )
  VALUES
    (v_tenant, 'QC_PH_MASH', 'Mash pH Check', 'parameter', '{"parameter_code":"PH","sampling_point":"end_of_step"}'::jsonb, 'active'),
    (v_tenant, 'QC_GRAVITY_END', 'End Gravity Check', 'parameter', '{"parameter_code":"GRAVITY","sampling_point":"end_of_step"}'::jsonb, 'active'),
    (v_tenant, 'QC_FILL_VOLUME', 'Fill Volume Check', 'parameter', '{"parameter_code":"FILL_VOLUME","sampling_point":"in_process","uom_code":"mL"}'::jsonb, 'active'),
    (v_tenant, 'QC_LABEL_INSPECTION', 'Label Inspection', 'visual', '{"inspection_type":"appearance"}'::jsonb, 'active'),
    (v_tenant, 'QC_ABV_RELEASE', 'ABV Release Check', 'parameter', '{"parameter_code":"ABV","sampling_point":"release","uom_code":"%"}'::jsonb, 'active')
  ON CONFLICT (tenant_id, check_code)
  DO UPDATE SET
    check_name = EXCLUDED.check_name,
    check_type = EXCLUDED.check_type,
    parameter_json = EXCLUDED.parameter_json,
    status = EXCLUDED.status,
    updated_at = now();

  SELECT id INTO v_qc_ph_mash FROM mes.mst_quality_check WHERE tenant_id = v_tenant AND check_code = 'QC_PH_MASH';
  SELECT id INTO v_qc_gravity_end FROM mes.mst_quality_check WHERE tenant_id = v_tenant AND check_code = 'QC_GRAVITY_END';
  SELECT id INTO v_qc_fill_volume FROM mes.mst_quality_check WHERE tenant_id = v_tenant AND check_code = 'QC_FILL_VOLUME';
  SELECT id INTO v_qc_label_inspection FROM mes.mst_quality_check WHERE tenant_id = v_tenant AND check_code = 'QC_LABEL_INSPECTION';
  SELECT id INTO v_qc_abv_release FROM mes.mst_quality_check WHERE tenant_id = v_tenant AND check_code = 'QC_ABV_RELEASE';

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

  SELECT id INTO v_step_mash FROM mes.mst_step_template WHERE tenant_id = v_tenant AND step_template_code = 'STEP_MASH';
  SELECT id INTO v_step_boil FROM mes.mst_step_template WHERE tenant_id = v_tenant AND step_template_code = 'STEP_BOIL';
  SELECT id INTO v_step_ferment FROM mes.mst_step_template WHERE tenant_id = v_tenant AND step_template_code = 'STEP_FERMENT';
  SELECT id INTO v_step_package FROM mes.mst_step_template WHERE tenant_id = v_tenant AND step_template_code = 'STEP_BOTTLE';

  INSERT INTO mes.recipe_approval_flow_def (
    tenant_id, flow_code, recipe_category, industry_type, step_no, approval_role, is_required, status
  )
  VALUES
    (v_tenant, 'CRAFT_BEER_STD', 'beer', 'beer', 10, 'process_engineer', true, 'active'),
    (v_tenant, 'CRAFT_BEER_STD', 'beer', 'beer', 20, 'qa_manager', true, 'active')
  ON CONFLICT (tenant_id, flow_code, step_no)
  DO UPDATE SET
    recipe_category = EXCLUDED.recipe_category,
    industry_type = EXCLUDED.industry_type,
    approval_role = EXCLUDED.approval_role,
    is_required = EXCLUDED.is_required,
    status = EXCLUDED.status,
    updated_at = now();

  INSERT INTO mes.mst_recipe (
    tenant_id, recipe_code, recipe_name, recipe_category, industry_type, status, current_version_id
  )
  VALUES (
    v_tenant, 'RCP_BEER_LAGER_330', 'Craft Lager 330mL', 'beer', 'beer', 'active', NULL
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
        "description": "Standard lager recipe for bottled 330 mL product.",
        "batch_strategy": "fixed",
        "tags": ["lager", "bottle", "core"],
        "notes": "Design-time recipe definition only."
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
            "output_code": "BEER_LAGER_330",
            "output_name": "Lager Beer 330mL",
            "output_type": "primary",
            "qty": 3000,
            "uom_code": "pcs",
            "basis": "per_base"
          }
        ],
        "co_products": [
          {
            "output_code": "SPENT_GRAIN",
            "output_name": "Spent Grain",
            "output_type": "co_product",
            "qty": 120,
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
            "qty": 1200,
            "uom_code": "L",
            "basis": "per_base"
          },
          {
            "material_key": "MALT_BASE",
            "material_name": "Pale Malt",
            "material_role": "main_substrate",
            "material_type_code": "MALT",
            "material_code": "MAT_MALT_PALE",
            "qty": 180,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "HOPS_BITTER",
            "material_name": "Saaz Hops",
            "material_role": "flavor",
            "material_type_code": "HOPS",
            "material_code": "MAT_HOPS_SAAZ",
            "qty": 2.5,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "YEAST_MAIN",
            "material_name": "Lager Yeast",
            "material_role": "culture",
            "material_type_code": "YEAST",
            "material_code": "MAT_YEAST_LAGER",
            "qty": 5,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_key": "BOTTLE_330",
            "material_name": "330mL Bottle",
            "material_role": "packaging_primary",
            "material_type_code": "PACKAGING",
            "material_code": "PKG_BOTTLE_330",
            "qty": 3000,
            "uom_code": "pcs",
            "basis": "per_base"
          },
          {
            "material_key": "CAP_330",
            "material_name": "Bottle Cap",
            "material_role": "packaging_component",
            "material_type_code": "PACKAGING",
            "material_code": "PKG_CAP_330",
            "qty": 3000,
            "uom_code": "pcs",
            "basis": "per_base"
          },
          {
            "material_key": "LABEL_STD",
            "material_name": "Standard Label",
            "material_role": "packaging_component",
            "material_type_code": "PACKAGING",
            "material_code": "PKG_LABEL_STD",
            "qty": 3000,
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
            "instructions": "Charge water and malt, then hold the mash rest.",
            "duration_sec": 5400,
            "material_inputs": [
              {
                "material_key": "WATER_BREW",
                "qty": 800,
                "uom_code": "L",
                "basis": "per_base",
                "consumption_mode": "estimate"
              },
              {
                "material_key": "MALT_BASE",
                "qty": 180,
                "uom_code": "kg",
                "basis": "per_base",
                "consumption_mode": "estimate"
              }
            ],
            "material_outputs": [
              {
                "output_code": "SWEET_WORT",
                "output_name": "Sweet Wort",
                "output_type": "intermediate",
                "qty": 760,
                "uom_code": "L"
              }
            ],
            "equipment_requirements": [
              {
                "equipment_type_code": "MASH_TUN",
                "equipment_template_code": "MASH_TUN_1000L",
                "quantity": 1
              }
            ],
            "parameters": [
              {
                "parameter_code": "MASH_TEMP",
                "target": 65,
                "min": 63,
                "max": 67,
                "uom_code": "C",
                "required": true
              },
              {
                "parameter_code": "MASH_TIME",
                "target": 90,
                "uom_code": "min",
                "required": true
              }
            ],
            "quality_checks": [
              {
                "check_code": "QC_PH_MASH",
                "sampling_point": "end_of_step",
                "frequency": "per_batch",
                "required": true
              }
            ]
          },
          {
            "step_code": "BOIL",
            "step_name": "Boiling",
            "step_no": 20,
            "step_type": "process",
            "step_template_code": "STEP_BOIL",
            "instructions": "Boil wort and dose hops according to schedule.",
            "duration_sec": 4500,
            "material_inputs": [
              {
                "material_key": "HOPS_BITTER",
                "qty": 2.5,
                "uom_code": "kg",
                "basis": "per_base",
                "consumption_mode": "estimate"
              }
            ],
            "material_outputs": [
              {
                "output_code": "HOT_WORT",
                "output_name": "Hot Wort",
                "output_type": "intermediate",
                "qty": 730,
                "uom_code": "L"
              }
            ],
            "equipment_requirements": [
              {
                "equipment_type_code": "BOIL_KETTLE",
                "equipment_template_code": "BOIL_KETTLE_1000L",
                "quantity": 1
              }
            ],
            "parameters": [
              {
                "parameter_code": "BOIL_TIME",
                "target": 75,
                "uom_code": "min",
                "required": true
              }
            ]
          },
          {
            "step_code": "FERMENT",
            "step_name": "Fermentation",
            "step_no": 30,
            "step_type": "process",
            "step_template_code": "STEP_FERMENT",
            "instructions": "Pitch yeast and control fermentation temperature.",
            "duration_sec": 604800,
            "material_inputs": [
              {
                "material_key": "YEAST_MAIN",
                "qty": 5,
                "uom_code": "kg",
                "basis": "per_base",
                "consumption_mode": "estimate"
              }
            ],
            "material_outputs": [
              {
                "output_code": "GREEN_BEER",
                "output_name": "Green Beer",
                "output_type": "intermediate",
                "qty": 690,
                "uom_code": "L"
              }
            ],
            "equipment_requirements": [
              {
                "equipment_type_code": "FERMENTER",
                "equipment_template_code": "FERMENTER_1000L",
                "quantity": 1
              }
            ],
            "parameters": [
              {
                "parameter_code": "FERMENT_TEMP",
                "target": 12,
                "min": 10,
                "max": 14,
                "uom_code": "C",
                "required": true
              },
              {
                "parameter_code": "FERMENT_TIME",
                "target": 168,
                "uom_code": "hour",
                "required": true
              }
            ],
            "quality_checks": [
              {
                "check_code": "QC_GRAVITY_END",
                "sampling_point": "end_of_step",
                "frequency": "per_batch",
                "required": true
              }
            ]
          },
          {
            "step_code": "PACKAGE",
            "step_name": "Packaging",
            "step_no": 40,
            "step_type": "packaging",
            "step_template_code": "STEP_BOTTLE",
            "instructions": "Fill, cap, and label bottles.",
            "duration_sec": 14400,
            "material_inputs": [
              {
                "material_key": "BOTTLE_330",
                "qty": 3000,
                "uom_code": "pcs",
                "basis": "per_base",
                "consumption_mode": "backflush"
              },
              {
                "material_key": "CAP_330",
                "qty": 3000,
                "uom_code": "pcs",
                "basis": "per_base",
                "consumption_mode": "backflush"
              },
              {
                "material_key": "LABEL_STD",
                "qty": 3000,
                "uom_code": "pcs",
                "basis": "per_base",
                "consumption_mode": "backflush"
              }
            ],
            "material_outputs": [
              {
                "output_code": "BEER_LAGER_330",
                "output_name": "Lager Beer 330mL",
                "output_type": "primary",
                "qty": 3000,
                "uom_code": "pcs"
              }
            ],
            "equipment_requirements": [
              {
                "equipment_type_code": "BOTTLING_LINE",
                "equipment_template_code": "BOTTLING_LINE_STD",
                "quantity": 1
              }
            ],
            "parameters": [
              {
                "parameter_code": "FILL_VOLUME",
                "target": 330,
                "min": 327,
                "max": 333,
                "uom_code": "mL",
                "required": true
              }
            ],
            "quality_checks": [
              {
                "check_code": "QC_FILL_VOLUME",
                "sampling_point": "in_process",
                "frequency": "hourly",
                "required": true
              },
              {
                "check_code": "QC_LABEL_INSPECTION",
                "sampling_point": "end_of_step",
                "frequency": "per_batch",
                "required": true
              }
            ]
          }
        ],
        "dependencies": [
          {
            "from_step_code": "MASH",
            "to_step_code": "BOIL",
            "relation_type": "finish_start"
          },
          {
            "from_step_code": "BOIL",
            "to_step_code": "FERMENT",
            "relation_type": "finish_start"
          },
          {
            "from_step_code": "FERMENT",
            "to_step_code": "PACKAGE",
            "relation_type": "finish_start"
          }
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
              "min": 4.8,
              "max": 5.2,
              "uom_code": "%"
            }
          }
        ]
      },
      "storage_constraints": [
        {
          "constraint_code": "GREEN_BEER_HOLD",
          "target_code": "GREEN_BEER",
          "storage_type": "fermenter",
          "max_hold_time": 72,
          "uom_code": "hour",
          "max_temp": 4,
          "temp_uom_code": "C"
        }
      ],
      "documents": [
        {
          "doc_code": "SOP_BREW_LAGER",
          "doc_type": "sop",
          "title": "Standard Lager Brewing SOP",
          "revision": "A",
          "required": true
        }
      ]
    }
    $json$::jsonb,
    jsonb_build_object(
      'industry_code', 'CRAFT_BEER',
      'material_type_map', jsonb_build_object(
        'WATER', v_mt_water,
        'MALT', v_mt_malt,
        'HOPS', v_mt_hops,
        'YEAST', v_mt_yeast,
        'PACKAGING', v_mt_packaging,
        'BEER', v_mt_beer
      ),
      'equipment_type_map', jsonb_build_object(
        'MASH_TUN', v_et_mash_tun,
        'BOIL_KETTLE', v_et_boil_kettle,
        'FERMENTER', v_et_fermenter,
        'BRITE_TANK', v_et_brite_tank,
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
    'CRAFT_BEER_STD_V1',
    'approved',
    now(),
    NULL,
    'Initial craft lager release sample',
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
END $$;
