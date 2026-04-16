-- Craft-beer recipe-only sample DML for mes.mst_recipe / mes.mst_recipe_version.
--
-- Usage:
--   select set_config('app.seed_tenant_id', '<tenant-uuid>', false);
--   \i DB/dml/mes/mst_material_craft_beer_sample.sql
--   \i DB/dml/mes/mes_recipe_craft_beer_recipe_sample.sql
--
-- Assumptions:
--   - public.industry contains an active row with code = 'CRAFT_BEER'
--   - public.mst_uom contains kg, L, mL, pcs, C, min, hour, %
--   - mes.mst_material already contains the craft-beer sample material codes
--   - mes.mst_recipe and mes.mst_recipe_version exist from DB/ddl/mes_recipe.sql

DO $seed$
DECLARE
  v_tenant uuid := COALESCE(
    NULLIF(current_setting('app.seed_tenant_id', true), '')::uuid,
    app_current_tenant_id(),
    '2a231822-aa8d-452a-aa5f-9f5e4293cdaa'::uuid
  );
  v_industry_id uuid;
  v_recipe_id uuid;
  v_recipe_version_id uuid;

  v_uom_kg uuid;
  v_uom_l uuid;
  v_uom_ml uuid;
  v_uom_pcs uuid;
  v_uom_c uuid;
  v_uom_min uuid;
  v_uom_hour uuid;
  v_uom_pct uuid;

  v_mat_water_brew uuid;
  v_mat_malt_2row uuid;
  v_mat_malt_munich uuid;
  v_mat_malt_caramel_40 uuid;
  v_mat_hops_columbus uuid;
  v_mat_hops_cascade uuid;
  v_mat_hops_centennial uuid;
  v_mat_hops_citra uuid;
  v_mat_yeast_us05 uuid;
  v_mat_fining_biofine uuid;
  v_pkg_can_355 uuid;
  v_pkg_can_end_355 uuid;
  v_fg_ipa_355 uuid;
  v_byp_spent_grain uuid;
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

  SELECT id INTO v_uom_pct
    FROM public.mst_uom
   WHERE code = '%'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  IF v_uom_kg IS NULL OR v_uom_l IS NULL OR v_uom_ml IS NULL OR v_uom_pcs IS NULL
     OR v_uom_c IS NULL OR v_uom_min IS NULL OR v_uom_hour IS NULL OR v_uom_pct IS NULL THEN
    RAISE EXCEPTION 'Required UOM rows (kg, L, mL, pcs, C, min, hour, %%) are missing.';
  END IF;

  SELECT id INTO v_mat_water_brew
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'MAT_WATER_BREW';

  SELECT id INTO v_mat_malt_2row
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'MAT_MALT_2ROW';

  SELECT id INTO v_mat_malt_munich
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'MAT_MALT_MUNICH';

  SELECT id INTO v_mat_malt_caramel_40
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'MAT_MALT_CARAMEL_40';

  SELECT id INTO v_mat_hops_columbus
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'MAT_HOPS_COLUMBUS';

  SELECT id INTO v_mat_hops_cascade
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'MAT_HOPS_CASCADE';

  SELECT id INTO v_mat_hops_centennial
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'MAT_HOPS_CENTENNIAL';

  SELECT id INTO v_mat_hops_citra
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'MAT_HOPS_CITRA';

  SELECT id INTO v_mat_yeast_us05
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'MAT_YEAST_US05';

  SELECT id INTO v_mat_fining_biofine
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'MAT_FINING_BIOFINE';

  SELECT id INTO v_pkg_can_355
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'PKG_CAN_355';

  SELECT id INTO v_pkg_can_end_355
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'PKG_CAN_END_355';

  SELECT id INTO v_fg_ipa_355
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'FG_AMERICAN_IPA_355';

  SELECT id INTO v_byp_spent_grain
    FROM mes.mst_material
   WHERE tenant_id = v_tenant
     AND material_code = 'BYP_SPENT_GRAIN';

  IF v_mat_water_brew IS NULL OR v_mat_malt_2row IS NULL OR v_mat_malt_munich IS NULL
     OR v_mat_malt_caramel_40 IS NULL OR v_mat_hops_columbus IS NULL OR v_mat_hops_cascade IS NULL
     OR v_mat_hops_centennial IS NULL OR v_mat_hops_citra IS NULL OR v_mat_yeast_us05 IS NULL
     OR v_mat_fining_biofine IS NULL OR v_pkg_can_355 IS NULL OR v_pkg_can_end_355 IS NULL
     OR v_fg_ipa_355 IS NULL OR v_byp_spent_grain IS NULL THEN
    RAISE EXCEPTION 'Required craft-beer sample material rows are missing. Run mst_material_craft_beer_sample.sql first.';
  END IF;

  INSERT INTO mes.mst_recipe (
    tenant_id,
    recipe_code,
    recipe_name,
    recipe_category,
    industry_type,
    status,
    current_version_id
  )
  VALUES (
    v_tenant,
    'RCP_AMERICAN_IPA_355',
    'American IPA 355mL',
    'beer',
    'beer',
    'active',
    NULL
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
        "description": "Sample American IPA recipe for 355mL canned finished goods.",
        "batch_strategy": "fixed",
        "tags": ["ipa", "can", "craft-beer", "sample"],
        "notes": "Recipe-only sample aligned with mst_material_craft_beer_sample.sql."
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
            "output_material_type": "FINISHED_GOOD",
            "output_name": "American IPA 355mL",
            "output_type": "primary",
            "qty": 2800,
            "uom_code": "pcs",
            "basis": "per_base"
          }
        ],
        "co_products": [
          {
            "output_material_type": "BYPRODUCT",
            "output_name": "Spent Grain",
            "output_type": "co_product",
            "qty": 210,
            "uom_code": "kg",
            "basis": "yield_based"
          }
        ],
        "waste": []
      },
      "materials": {
        "required": [
          {
            "material_type": "WATER",
            "material_name": "Brewing Water",
            "material_role": "process_water",
            "material_type_code": "WATER",
            "material_code": "MAT_WATER_BREW",
            "qty": 1350,
            "uom_code": "L",
            "basis": "per_base"
          },
          {
            "material_type": "BASE_MALT",
            "material_name": "Two-Row Pale Malt",
            "material_role": "main_substrate",
            "material_type_code": "BASE_MALT",
            "material_code": "MAT_MALT_2ROW",
            "qty": 185,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_type": "SPECIALTY_MALT",
            "material_name": "Munich Malt",
            "material_role": "flavor_substrate",
            "material_type_code": "SPECIALTY_MALT",
            "material_code": "MAT_MALT_MUNICH",
            "qty": 18,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_type": "SPECIALTY_MALT",
            "material_name": "Caramel 40 Malt",
            "material_role": "color_substrate",
            "material_type_code": "SPECIALTY_MALT",
            "material_code": "MAT_MALT_CARAMEL_40",
            "qty": 12,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_type": "HOP_PELLET",
            "material_name": "Columbus Hops",
            "material_role": "bittering",
            "material_type_code": "HOP_PELLET",
            "material_code": "MAT_HOPS_COLUMBUS",
            "qty": 2.2,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_type": "HOP_PELLET",
            "material_name": "Cascade Hops",
            "material_role": "late_hop",
            "material_type_code": "HOP_PELLET",
            "material_code": "MAT_HOPS_CASCADE",
            "qty": 4.5,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_type": "HOP_PELLET",
            "material_name": "Centennial Hops",
            "material_role": "dry_hop",
            "material_type_code": "HOP_PELLET",
            "material_code": "MAT_HOPS_CENTENNIAL",
            "qty": 4.0,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_type": "HOP_PELLET",
            "material_name": "Citra Hops",
            "material_role": "dry_hop",
            "material_type_code": "HOP_PELLET",
            "material_code": "MAT_HOPS_CITRA",
            "qty": 5.5,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_type": "DRY_YEAST",
            "material_name": "US-05 Ale Yeast",
            "material_role": "culture",
            "material_type_code": "DRY_YEAST",
            "material_code": "MAT_YEAST_US05",
            "qty": 4,
            "uom_code": "kg",
            "basis": "per_base"
          },
          {
            "material_type": "FINING",
            "material_name": "Biofine Clear",
            "material_role": "process_aid",
            "material_type_code": "FINING",
            "material_code": "MAT_FINING_BIOFINE",
            "qty": 1500,
            "uom_code": "mL",
            "basis": "per_base"
          },
          {
            "material_type": "CAN",
            "material_name": "355mL Standard Can",
            "material_role": "packaging_primary",
            "material_type_code": "CAN",
            "material_code": "PKG_CAN_355",
            "qty": 2800,
            "uom_code": "pcs",
            "basis": "per_base"
          },
          {
            "material_type": "CAN_END",
            "material_name": "355mL Can End",
            "material_role": "packaging_component",
            "material_type_code": "CAN_END",
            "material_code": "PKG_CAN_END_355",
            "qty": 2800,
            "uom_code": "pcs",
            "basis": "per_base"
          }
        ],
        "optional": []
      },
      "flow": {
        "steps": [
          {
            "step_code": "MASH",
            "step_name": "Mashing",
            "step_no": 10,
            "step_type": "process",
            "step_template_code": "CB_MASH",
            "instructions": "Charge mash water and grist, then hold conversion rests.",
            "duration_sec": 7200,
            "material_inputs": [
              {
                "material_type": "WATER",
                "qty": 1150,
                "uom_code": "L",
                "basis": "per_base",
                "consumption_mode": "estimate"
              },
              {
                "material_type": "BASE_MALT",
                "qty": 185,
                "uom_code": "kg",
                "basis": "per_base",
                "consumption_mode": "estimate"
              },
              {
                "material_type": "SPECIALTY_MALT",
                "qty": 18,
                "uom_code": "kg",
                "basis": "per_base",
                "consumption_mode": "estimate"
              },
              {
                "material_type": "SPECIALTY_MALT",
                "qty": 12,
                "uom_code": "kg",
                "basis": "per_base",
                "consumption_mode": "estimate"
              }
            ],
            "material_outputs": [
              {
                "output_material_type": "WORT",
                "output_name": "Sweet Wort",
                "output_type": "intermediate",
                "qty": 1030,
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
                "target": 66,
                "min": 64,
                "max": 68,
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
                "check_code": "QC_MASH_PH",
                "sampling_point": "end_of_step",
                "frequency": "per_batch",
                "required": true,
                "acceptance_criteria": {
                  "min": 5.2,
                  "max": 5.6
                }
              }
            ]
          },
          {
            "step_code": "BOIL",
            "step_name": "Boiling",
            "step_no": 20,
            "step_type": "process",
            "step_template_code": "CB_BOIL",
            "instructions": "Boil wort, dose bittering hops at the start, and late hops near knockout.",
            "duration_sec": 4500,
            "material_inputs": [
              {
                "material_type": "HOP_PELLET",
                "qty": 2.2,
                "uom_code": "kg",
                "basis": "per_base",
                "consumption_mode": "estimate"
              },
              {
                "material_type": "HOP_PELLET",
                "qty": 1.8,
                "uom_code": "kg",
                "basis": "per_base",
                "consumption_mode": "estimate"
              }
            ],
            "material_outputs": [
              {
                "output_material_type": "WORT",
                "output_name": "Cooled Wort",
                "output_type": "intermediate",
                "qty": 970,
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
            ],
            "quality_checks": [
              {
                "check_code": "QC_ORIGINAL_GRAVITY",
                "sampling_point": "end_of_step",
                "frequency": "per_batch",
                "required": true
              }
            ]
          },
          {
            "step_code": "FERMENT",
            "step_name": "Fermentation and Dry Hop",
            "step_no": 30,
            "step_type": "process",
            "step_template_code": "CB_FERMENT",
            "instructions": "Pitch yeast, ferment under temperature control, then dry hop and fine before transfer.",
            "duration_sec": 864000,
            "material_inputs": [
              {
                "material_type": "DRY_YEAST",
                "qty": 4,
                "uom_code": "kg",
                "basis": "per_base",
                "consumption_mode": "backflush"
              },
              {
                "material_type": "HOP_PELLET",
                "qty": 2.7,
                "uom_code": "kg",
                "basis": "per_base",
                "consumption_mode": "backflush"
              },
              {
                "material_type": "HOP_PELLET",
                "qty": 4.0,
                "uom_code": "kg",
                "basis": "per_base",
                "consumption_mode": "backflush"
              },
              {
                "material_type": "HOP_PELLET",
                "qty": 5.5,
                "uom_code": "kg",
                "basis": "per_base",
                "consumption_mode": "backflush"
              },
              {
                "material_type": "FINING",
                "qty": 1500,
                "uom_code": "mL",
                "basis": "per_base",
                "consumption_mode": "backflush"
              }
            ],
            "material_outputs": [
              {
                "output_material_type": "BEER",
                "output_name": "Bright Beer",
                "output_type": "intermediate",
                "qty": 935,
                "uom_code": "L"
              }
            ],
            "equipment_requirements": [
              {
                "equipment_type_code": "FERMENTER",
                "equipment_template_code": "FERMENTER_1000L",
                "quantity": 1
              },
              {
                "equipment_type_code": "BRITE_TANK",
                "equipment_template_code": "BRITE_TANK_1000L",
                "quantity": 1
              }
            ],
            "parameters": [
              {
                "parameter_code": "FERMENT_TEMP",
                "target": 19,
                "min": 18,
                "max": 21,
                "uom_code": "C",
                "required": true
              },
              {
                "parameter_code": "FERMENT_TIME",
                "target": 240,
                "uom_code": "hour",
                "required": true
              }
            ],
            "quality_checks": [
              {
                "check_code": "QC_FINAL_GRAVITY",
                "sampling_point": "end_of_step",
                "frequency": "per_batch",
                "required": true
              },
              {
                "check_code": "QC_ABV_RELEASE",
                "sampling_point": "end_of_step",
                "frequency": "per_batch",
                "required": true
              }
            ]
          },
          {
            "step_code": "PACKAGE",
            "step_name": "Can Packaging",
            "step_no": 40,
            "step_type": "packaging",
            "step_template_code": "CB_CAN_PACKAGE",
            "instructions": "Fill cans, seam lids, and palletize finished goods.",
            "duration_sec": 18000,
            "material_inputs": [
              {
                "material_type": "CAN",
                "qty": 2800,
                "uom_code": "pcs",
                "basis": "per_base",
                "consumption_mode": "backflush"
              },
              {
                "material_type": "CAN_END",
                "qty": 2800,
                "uom_code": "pcs",
                "basis": "per_base",
                "consumption_mode": "backflush"
              }
            ],
            "material_outputs": [
              {
                "output_material_type": "FINISHED_GOOD",
                "output_name": "American IPA 355mL",
                "output_type": "primary",
                "qty": 2800,
                "uom_code": "pcs"
              }
            ],
            "equipment_requirements": [
              {
                "equipment_type_code": "CAN_LINE",
                "equipment_template_code": "CAN_LINE_STD",
                "quantity": 1
              }
            ],
            "parameters": [
              {
                "parameter_code": "FILL_VOLUME",
                "target": 355,
                "min": 352,
                "max": 358,
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
                "check_code": "QC_SEAM_CHECK",
                "sampling_point": "in_process",
                "frequency": "hourly",
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
              "min": 6.2,
              "max": 6.8,
              "uom_code": "%"
            }
          }
        ],
        "release_criteria": {
          "abv_range": {
            "min": 6.2,
            "max": 6.8,
            "uom_code": "%"
          },
          "packaging": {
            "container_code": "355mL_can",
            "target_units": 2800
          }
        }
      },
      "documents": [
        {
          "doc_code": "SOP_IPA_BREWHOUSE",
          "doc_type": "sop",
          "title": "American IPA Brewhouse SOP",
          "revision": "A",
          "required": true
        },
        {
          "doc_code": "SOP_IPA_PACKAGING",
          "doc_type": "sop",
          "title": "American IPA Packaging SOP",
          "revision": "A",
          "required": true
        }
      ]
    }
    $json$::jsonb,
    jsonb_build_object(
      'industry_code', 'CRAFT_BEER',
      'prerequisite_seed', 'mst_material_craft_beer_sample.sql',
      'material_id_map', jsonb_build_object(
        'MAT_WATER_BREW', v_mat_water_brew,
        'MAT_MALT_2ROW', v_mat_malt_2row,
        'MAT_MALT_MUNICH', v_mat_malt_munich,
        'MAT_MALT_CARAMEL_40', v_mat_malt_caramel_40,
        'MAT_HOPS_COLUMBUS', v_mat_hops_columbus,
        'MAT_HOPS_CASCADE', v_mat_hops_cascade,
        'MAT_HOPS_CENTENNIAL', v_mat_hops_centennial,
        'MAT_HOPS_CITRA', v_mat_hops_citra,
        'MAT_YEAST_US05', v_mat_yeast_us05,
        'MAT_FINING_BIOFINE', v_mat_fining_biofine,
        'PKG_CAN_355', v_pkg_can_355,
        'PKG_CAN_END_355', v_pkg_can_end_355,
        'FG_AMERICAN_IPA_355', v_fg_ipa_355,
        'BYP_SPENT_GRAIN', v_byp_spent_grain
      ),
      'uom_id_map', jsonb_build_object(
        'kg', v_uom_kg,
        'L', v_uom_l,
        'mL', v_uom_ml,
        'pcs', v_uom_pcs,
        'C', v_uom_c,
        'min', v_uom_min,
        'hour', v_uom_hour,
        '%', v_uom_pct
      )
    ),
    'recipe_body_v1',
    'CRAFT_BEER_RECIPE_SAMPLE_V1',
    'approved',
    now(),
    NULL,
    'Initial American IPA canned recipe sample aligned with craft-beer material seed',
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
