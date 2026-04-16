-- Craft-beer sample DML for mes.mst_material.
--
-- Usage:
--   select set_config('app.seed_tenant_id', '<tenant-uuid>', false);
--   \i DB/dml/mes/mst_material_craft_beer_sample.sql
--
-- Assumptions:
--   - public.industry contains an active row with code = 'CRAFT_BEER'
--   - public.mst_uom contains kg, g, L, mL, pcs
--   - public.type_def contains craft-beer material_type rows
--   - mes.mst_material exists from DB/ddl/mes_recipe.sql

DO $seed$
DECLARE
  v_tenant uuid := COALESCE(
    NULLIF(current_setting('app.seed_tenant_id', true), '')::uuid,
    app_current_tenant_id(),
    '2a231822-aa8d-452a-aa5f-9f5e4293cdaa'::uuid
  );
  v_industry_id uuid;

  v_uom_kg uuid;
  v_uom_g uuid;
  v_uom_l uuid;
  v_uom_ml uuid;
  v_uom_pcs uuid;

  v_mt_water uuid;
  v_mt_base_malt uuid;
  v_mt_specialty_malt uuid;
  v_mt_roasted_malt uuid;
  v_mt_hop uuid;
  v_mt_dry_yeast uuid;
  v_mt_brewing_sugar uuid;
  v_mt_fruit_adjunct uuid;
  v_mt_spice_adjunct uuid;
  v_mt_fining uuid;
  v_mt_enzyme uuid;
  v_mt_filter_aid uuid;
  v_mt_bottle uuid;
  v_mt_can uuid;
  v_mt_keg uuid;
  v_mt_cap uuid;
  v_mt_can_end uuid;
  v_mt_label uuid;
  v_mt_carton uuid;
  v_mt_beer uuid;
  v_mt_spent_grain uuid;
  v_mt_spent_yeast uuid;
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

  SELECT id INTO v_uom_g
    FROM public.mst_uom
   WHERE code = 'g'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_l
    FROM public.mst_uom
   WHERE code = 'L'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_ml
    FROM public.mst_uom
   WHERE code = 'mL'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_pcs
    FROM public.mst_uom
   WHERE code = 'pcs'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  IF v_uom_kg IS NULL OR v_uom_g IS NULL OR v_uom_l IS NULL OR v_uom_ml IS NULL OR v_uom_pcs IS NULL THEN
    RAISE EXCEPTION 'Required UOM rows (kg, g, L, mL, pcs) are missing.';
  END IF;

  SELECT type_id INTO v_mt_water
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code = 'WATER';

  SELECT type_id INTO v_mt_base_malt
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('BASE_MALT', 'MALT')
   ORDER BY CASE code WHEN 'BASE_MALT' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_specialty_malt
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('SPECIALTY_MALT', 'MALT')
   ORDER BY CASE code WHEN 'SPECIALTY_MALT' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_roasted_malt
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('ROASTED_MALT', 'MALT')
   ORDER BY CASE code WHEN 'ROASTED_MALT' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_hop
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('HOP_PELLET', 'HOPS')
   ORDER BY CASE code WHEN 'HOP_PELLET' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_dry_yeast
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('DRY_YEAST', 'YEAST')
   ORDER BY CASE code WHEN 'DRY_YEAST' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_brewing_sugar
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('BREWING_SUGAR', 'ADJUNCT', 'RAW_MATERIAL')
   ORDER BY CASE code WHEN 'BREWING_SUGAR' THEN 0 WHEN 'ADJUNCT' THEN 1 ELSE 2 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_fruit_adjunct
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('FRUIT_ADJUNCT', 'ADJUNCT', 'RAW_MATERIAL')
   ORDER BY CASE code WHEN 'FRUIT_ADJUNCT' THEN 0 WHEN 'ADJUNCT' THEN 1 ELSE 2 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_spice_adjunct
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('SPICE_ADJUNCT', 'ADJUNCT', 'RAW_MATERIAL')
   ORDER BY CASE code WHEN 'SPICE_ADJUNCT' THEN 0 WHEN 'ADJUNCT' THEN 1 ELSE 2 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_fining
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('FINING', 'PROCESS_AID', 'RAW_MATERIAL')
   ORDER BY CASE code WHEN 'FINING' THEN 0 WHEN 'PROCESS_AID' THEN 1 ELSE 2 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_enzyme
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('ENZYME', 'PROCESS_AID', 'RAW_MATERIAL')
   ORDER BY CASE code WHEN 'ENZYME' THEN 0 WHEN 'PROCESS_AID' THEN 1 ELSE 2 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_filter_aid
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('FILTER_AID', 'PROCESS_AID', 'RAW_MATERIAL')
   ORDER BY CASE code WHEN 'FILTER_AID' THEN 0 WHEN 'PROCESS_AID' THEN 1 ELSE 2 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_bottle
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('BOTTLE', 'PRIMARY_PACKAGE', 'PACKAGING')
   ORDER BY CASE code WHEN 'BOTTLE' THEN 0 WHEN 'PRIMARY_PACKAGE' THEN 1 ELSE 2 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_can
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('CAN', 'PRIMARY_PACKAGE', 'PACKAGING')
   ORDER BY CASE code WHEN 'CAN' THEN 0 WHEN 'PRIMARY_PACKAGE' THEN 1 ELSE 2 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_keg
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('KEG', 'PRIMARY_PACKAGE', 'PACKAGING')
   ORDER BY CASE code WHEN 'KEG' THEN 0 WHEN 'PRIMARY_PACKAGE' THEN 1 ELSE 2 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_cap
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('CROWN_CAP', 'CLOSURE', 'PACKAGING')
   ORDER BY CASE code WHEN 'CROWN_CAP' THEN 0 WHEN 'CLOSURE' THEN 1 ELSE 2 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_can_end
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('CAN_END', 'CLOSURE', 'PACKAGING')
   ORDER BY CASE code WHEN 'CAN_END' THEN 0 WHEN 'CLOSURE' THEN 1 ELSE 2 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_label
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('LABEL', 'DECORATION', 'PACKAGING')
   ORDER BY CASE code WHEN 'LABEL' THEN 0 WHEN 'DECORATION' THEN 1 ELSE 2 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_carton
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('CARTON', 'SECONDARY_PACKAGE', 'PACKAGING')
   ORDER BY CASE code WHEN 'CARTON' THEN 0 WHEN 'SECONDARY_PACKAGE' THEN 1 ELSE 2 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_beer
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code = 'BEER';

  SELECT type_id INTO v_mt_spent_grain
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('SPENT_GRAIN', 'BYPRODUCT')
   ORDER BY CASE code WHEN 'SPENT_GRAIN' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  SELECT type_id INTO v_mt_spent_yeast
    FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain = 'material_type'
     AND industry_id = v_industry_id
     AND code IN ('SPENT_YEAST', 'BYPRODUCT')
   ORDER BY CASE code WHEN 'SPENT_YEAST' THEN 0 ELSE 1 END, created_at
   LIMIT 1;

  IF v_mt_water IS NULL OR v_mt_base_malt IS NULL OR v_mt_specialty_malt IS NULL
     OR v_mt_roasted_malt IS NULL OR v_mt_hop IS NULL OR v_mt_dry_yeast IS NULL
     OR v_mt_brewing_sugar IS NULL OR v_mt_fruit_adjunct IS NULL OR v_mt_spice_adjunct IS NULL
     OR v_mt_fining IS NULL OR v_mt_enzyme IS NULL OR v_mt_filter_aid IS NULL
     OR v_mt_bottle IS NULL OR v_mt_can IS NULL OR v_mt_keg IS NULL
     OR v_mt_cap IS NULL OR v_mt_can_end IS NULL OR v_mt_label IS NULL
     OR v_mt_carton IS NULL OR v_mt_beer IS NULL THEN
    RAISE EXCEPTION 'Required craft-beer material_type rows are missing. Seed public.type_def first.';
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
    (v_tenant, 'MAT_WATER_BREW', 'Brewing Water', v_mt_water, v_uom_l, 'raw_material', false, false, '{"material_key":"WATER_BREW","family":"water","origin":"utility"}'::jsonb, 'active'),
    (v_tenant, 'MAT_WATER_DEAERATED', 'Deaerated Water', v_mt_water, v_uom_l, 'raw_material', false, false, '{"material_key":"WATER_DEAERATED","family":"water","origin":"utility"}'::jsonb, 'active'),

    (v_tenant, 'MAT_MALT_2ROW', 'Two-Row Pale Malt', v_mt_base_malt, v_uom_kg, 'raw_material', true, true, '{"material_key":"MALT_2ROW","extract_class":"base"}'::jsonb, 'active'),
    (v_tenant, 'MAT_MALT_PILSNER', 'Pilsner Malt', v_mt_base_malt, v_uom_kg, 'raw_material', true, true, '{"material_key":"MALT_PILSNER","extract_class":"base"}'::jsonb, 'active'),
    (v_tenant, 'MAT_MALT_MUNICH', 'Munich Malt', v_mt_specialty_malt, v_uom_kg, 'raw_material', true, true, '{"material_key":"MALT_MUNICH","extract_class":"specialty"}'::jsonb, 'active'),
    (v_tenant, 'MAT_MALT_CARAMEL_40', 'Caramel 40 Malt', v_mt_specialty_malt, v_uom_kg, 'raw_material', true, true, '{"material_key":"MALT_CARAMEL_40","extract_class":"specialty"}'::jsonb, 'active'),
    (v_tenant, 'MAT_MALT_WHEAT', 'Wheat Malt', v_mt_specialty_malt, v_uom_kg, 'raw_material', true, true, '{"material_key":"MALT_WHEAT","extract_class":"specialty"}'::jsonb, 'active'),
    (v_tenant, 'MAT_MALT_CHOCOLATE', 'Chocolate Malt', v_mt_roasted_malt, v_uom_kg, 'raw_material', true, true, '{"material_key":"MALT_CHOCOLATE","extract_class":"roasted"}'::jsonb, 'active'),
    (v_tenant, 'MAT_ROASTED_BARLEY', 'Roasted Barley', v_mt_roasted_malt, v_uom_kg, 'raw_material', true, true, '{"material_key":"ROASTED_BARLEY","extract_class":"roasted"}'::jsonb, 'active'),

    (v_tenant, 'MAT_FLAKED_BARLEY', 'Flaked Barley', v_mt_brewing_sugar, v_uom_kg, 'raw_material', true, true, '{"material_key":"FLAKED_BARLEY","adjunct_class":"grain"}'::jsonb, 'active'),
    (v_tenant, 'MAT_DEXTROSE', 'Brewing Dextrose', v_mt_brewing_sugar, v_uom_kg, 'raw_material', true, true, '{"material_key":"DEXTROSE","adjunct_class":"sugar"}'::jsonb, 'active'),
    (v_tenant, 'MAT_ORANGE_PEEL', 'Sweet Orange Peel', v_mt_spice_adjunct, v_uom_kg, 'raw_material', true, true, '{"material_key":"ORANGE_PEEL","adjunct_class":"spice"}'::jsonb, 'active'),
    (v_tenant, 'MAT_CORIANDER', 'Coriander Seed', v_mt_spice_adjunct, v_uom_kg, 'raw_material', true, true, '{"material_key":"CORIANDER","adjunct_class":"spice"}'::jsonb, 'active'),
    (v_tenant, 'MAT_MANGO_PUREE', 'Mango Puree', v_mt_fruit_adjunct, v_uom_kg, 'raw_material', true, true, '{"material_key":"MANGO_PUREE","adjunct_class":"fruit"}'::jsonb, 'active'),

    (v_tenant, 'MAT_HOPS_EKG', 'East Kent Goldings', v_mt_hop, v_uom_kg, 'raw_material', true, true, '{"material_key":"HOPS_EKG","hop_form":"pellet"}'::jsonb, 'active'),
    (v_tenant, 'MAT_HOPS_COLUMBUS', 'Columbus Hops', v_mt_hop, v_uom_kg, 'raw_material', true, true, '{"material_key":"HOPS_COLUMBUS","hop_form":"pellet"}'::jsonb, 'active'),
    (v_tenant, 'MAT_HOPS_CITRA', 'Citra Hops', v_mt_hop, v_uom_kg, 'raw_material', true, true, '{"material_key":"HOPS_CITRA","hop_form":"pellet"}'::jsonb, 'active'),
    (v_tenant, 'MAT_HOPS_CASCADE', 'Cascade Hops', v_mt_hop, v_uom_kg, 'raw_material', true, true, '{"material_key":"HOPS_CASCADE","hop_form":"pellet"}'::jsonb, 'active'),
    (v_tenant, 'MAT_HOPS_CENTENNIAL', 'Centennial Hops', v_mt_hop, v_uom_kg, 'raw_material', true, true, '{"material_key":"HOPS_CENTENNIAL","hop_form":"pellet"}'::jsonb, 'active'),

    (v_tenant, 'MAT_YEAST_US05', 'US-05 Ale Yeast', v_mt_dry_yeast, v_uom_kg, 'raw_material', true, true, '{"material_key":"YEAST_US05","yeast_form":"dry"}'::jsonb, 'active'),
    (v_tenant, 'MAT_YEAST_ALE_IRISH', 'Irish Ale Yeast', v_mt_dry_yeast, v_uom_kg, 'raw_material', true, true, '{"material_key":"YEAST_ALE_IRISH","yeast_form":"dry"}'::jsonb, 'active'),
    (v_tenant, 'MAT_YEAST_LAGER_3470', 'SafLager W-34/70', v_mt_dry_yeast, v_uom_kg, 'raw_material', true, true, '{"material_key":"YEAST_W3470","yeast_form":"dry"}'::jsonb, 'active'),

    (v_tenant, 'MAT_FINING_ISINGLASS', 'Isinglass Fining', v_mt_fining, v_uom_l, 'raw_material', true, true, '{"material_key":"FINING_ISINGLASS","process_aid":"fining"}'::jsonb, 'active'),
    (v_tenant, 'MAT_FINING_BIOFINE', 'Biofine Clear', v_mt_fining, v_uom_ml, 'raw_material', true, true, '{"material_key":"FINING_BIOFINE","process_aid":"fining"}'::jsonb, 'active'),
    (v_tenant, 'MAT_ENZYME_AMYLASE', 'Alpha Amylase Enzyme', v_mt_enzyme, v_uom_ml, 'raw_material', true, true, '{"material_key":"ENZYME_AMYLASE","process_aid":"enzyme"}'::jsonb, 'active'),
    (v_tenant, 'MAT_FILTER_AID_DE', 'Diatomaceous Earth', v_mt_filter_aid, v_uom_kg, 'raw_material', true, true, '{"material_key":"FILTER_AID_DE","process_aid":"filter_aid"}'::jsonb, 'active'),

    (v_tenant, 'PKG_BOTTLE_330', '330mL Amber Bottle', v_mt_bottle, v_uom_pcs, 'packaging', true, true, '{"material_key":"BOTTLE_330","package_size_ml":330}'::jsonb, 'active'),
    (v_tenant, 'PKG_CAN_355', '355mL Standard Can', v_mt_can, v_uom_pcs, 'packaging', true, true, '{"material_key":"CAN_355","package_size_ml":355}'::jsonb, 'active'),
    (v_tenant, 'PKG_KEG_20L', '20L Stainless Keg', v_mt_keg, v_uom_pcs, 'packaging', true, true, '{"material_key":"KEG_20L","package_size_l":20}'::jsonb, 'active'),
    (v_tenant, 'PKG_CAP_330', 'Bottle Cap', v_mt_cap, v_uom_pcs, 'packaging', true, true, '{"material_key":"CAP_330"}'::jsonb, 'active'),
    (v_tenant, 'PKG_CAN_END_355', '355mL Can End', v_mt_can_end, v_uom_pcs, 'packaging', true, true, '{"material_key":"CAN_END_355"}'::jsonb, 'active'),
    (v_tenant, 'PKG_LABEL_STD', 'Standard Bottle Label', v_mt_label, v_uom_pcs, 'packaging', true, true, '{"material_key":"LABEL_STD"}'::jsonb, 'active'),
    (v_tenant, 'PKG_CARTON_24X330', '24 x 330mL Carton', v_mt_carton, v_uom_pcs, 'packaging', true, true, '{"material_key":"CARTON_24X330","pack_out":"24x330"}'::jsonb, 'active'),

    (v_tenant, 'FG_DRY_STOUT_330', 'Dry Stout 330mL', v_mt_beer, v_uom_pcs, 'finished_good', true, true, '{"material_key":"BEER_DRY_STOUT_330","package_format":"bottle_330"}'::jsonb, 'active'),
    (v_tenant, 'FG_AMERICAN_IPA_355', 'American IPA 355mL', v_mt_beer, v_uom_pcs, 'finished_good', true, true, '{"material_key":"BEER_AMERICAN_IPA_355","package_format":"can_355"}'::jsonb, 'active'),
    (v_tenant, 'FG_PILSNER_20L', 'Pilsner 20L Keg', v_mt_beer, v_uom_pcs, 'finished_good', true, true, '{"material_key":"BEER_PILSNER_20L","package_format":"keg_20l"}'::jsonb, 'active'),

    (v_tenant, 'BYP_SPENT_GRAIN', 'Spent Grain', COALESCE(v_mt_spent_grain, v_mt_brewing_sugar), v_uom_kg, 'byproduct', true, true, '{"material_key":"SPENT_GRAIN","byproduct_class":"grain"}'::jsonb, 'active'),
    (v_tenant, 'BYP_SPENT_YEAST', 'Spent Yeast', COALESCE(v_mt_spent_yeast, v_mt_dry_yeast), v_uom_kg, 'byproduct', true, true, '{"material_key":"SPENT_YEAST","byproduct_class":"yeast"}'::jsonb, 'active')
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
END;
$seed$;
