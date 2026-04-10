-- Craft-beer material/equipment definition seed
--
-- Usage:
--   select set_config('app.seed_tenant_id', '<tenant-uuid>', false);
--   \i DB/dml/mes/craft_beer_material_equipment_master_seed.sql
--
-- Behavior:
--   1. resolves tenant from session setting app.seed_tenant_id
--   2. resolves industry from public.industry.code = 'CRAFT_BEER'
--   3. clears tenant rows for:
--        - public.type_def            domain in ('material_type','equipment_type')
--        - public.attr_def            domain in ('material','equipment')
--        - public.attr_set            domain in ('material','equipment')
--        - public.attr_set_rule       rows attached to the above
--        - public.entity_attr_set     entity_type in ('material_type','equipment_type')
--   4. inserts craft-beer-oriented type tree, attr defs, attr sets, set rules,
--      and type-to-attr_set assignments

DO $seed$
DECLARE
  v_tenant uuid := '2a231822-aa8d-452a-aa5f-9f5e4293cdaa'::uuid;
  v_industry_id uuid;

  v_uom_pct uuid;
  v_uom_c uuid;
  v_uom_ml uuid;
  v_uom_l uuid;
  v_uom_g uuid;
BEGIN
  IF v_tenant IS NULL THEN
    RAISE EXCEPTION 'Set app.seed_tenant_id before running this script.';
  END IF;

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

  SELECT id INTO v_uom_pct
    FROM public.mst_uom
   WHERE code = '%'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_c
    FROM public.mst_uom
   WHERE code = 'C'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_ml
    FROM public.mst_uom
   WHERE code = 'mL'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_l
    FROM public.mst_uom
   WHERE code = 'L'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  SELECT id INTO v_uom_g
    FROM public.mst_uom
   WHERE code = 'g'
     AND (tenant_id = v_tenant OR tenant_id IS NULL)
   ORDER BY CASE WHEN tenant_id = v_tenant THEN 0 ELSE 1 END
   LIMIT 1;

  DELETE FROM public.attr_set_rule r
   WHERE r.tenant_id = v_tenant
     AND (
       EXISTS (
         SELECT 1
           FROM public.attr_set s
          WHERE s.tenant_id = r.tenant_id
            AND s.attr_set_id = r.attr_set_id
            AND s.domain IN ('material', 'equipment')
       )
       OR EXISTS (
         SELECT 1
           FROM public.attr_def d
          WHERE d.tenant_id = r.tenant_id
            AND d.attr_id = r.attr_id
            AND d.domain IN ('material', 'equipment')
       )
     );

  DELETE FROM public.attr_set
   WHERE tenant_id = v_tenant
     AND domain IN ('material', 'equipment');

  DELETE FROM public.attr_def
   WHERE tenant_id = v_tenant
     AND domain IN ('material', 'equipment');

  DELETE FROM public.entity_attr_set
   WHERE tenant_id = v_tenant
     AND entity_type IN ('material_type', 'equipment_type');

  DELETE FROM public.type_def
   WHERE tenant_id = v_tenant
     AND domain IN ('material_type', 'equipment_type');

  WITH type_seed AS (
    SELECT
      seed.domain,
      seed.code,
      seed.parent_code,
      seed.name,
      seed.name_i18n::jsonb AS name_i18n,
      seed.sort_order,
      seed.description,
      seed.meta::jsonb AS meta,
      gen_random_uuid() AS type_id
    FROM (
      VALUES
        ('material_type', 'MATERIAL', NULL, 'Material', '{"ja":"原材料・資材","en":"Material"}', 10, 'Root node for craft-beer material classification', '{"level":"root","recommended_attr_sets":[]}'),
        ('material_type', 'RAW_MATERIAL', 'MATERIAL', 'Raw Material', '{"ja":"仕込原料","en":"Raw Material"}', 10, 'Raw ingredients used in brewing', '{"level":"group"}'),
        ('material_type', 'PACKAGING', 'MATERIAL', 'Packaging', '{"ja":"包装資材","en":"Packaging"}', 20, 'Packaging components for finished product', '{"level":"group"}'),
        ('material_type', 'FINISHED_GOOD', 'MATERIAL', 'Finished Good', '{"ja":"最終製品","en":"Finished Good"}', 30, 'Finished products managed as material master', '{"level":"group"}'),
        ('material_type', 'BYPRODUCT', 'MATERIAL', 'Byproduct', '{"ja":"副産物","en":"Byproduct"}', 40, 'Byproducts and waste streams from brewing', '{"level":"group"}'),
        ('material_type', 'WATER', 'RAW_MATERIAL', 'Water', '{"ja":"水","en":"Water"}', 10, 'Brewing and process water', '{"level":"family","recommended_attr_sets":["material_common","material_water"]}'),
        ('material_type', 'MALT', 'RAW_MATERIAL', 'Malt', '{"ja":"麦芽","en":"Malt"}', 20, 'Base and specialty malt', '{"level":"family","recommended_attr_sets":["material_common","material_malt"]}'),
        ('material_type', 'HOPS', 'RAW_MATERIAL', 'Hops', '{"ja":"ホップ","en":"Hops"}', 30, 'Hop products for bittering and aroma', '{"level":"family","recommended_attr_sets":["material_common","material_hops"]}'),
        ('material_type', 'YEAST', 'RAW_MATERIAL', 'Yeast', '{"ja":"酵母","en":"Yeast"}', 40, 'Yeast for fermentation', '{"level":"family","recommended_attr_sets":["material_common","material_yeast"]}'),
        ('material_type', 'ADJUNCT', 'RAW_MATERIAL', 'Adjunct', '{"ja":"副原料","en":"Adjunct"}', 50, 'Sugars, fruit, spices and similar adjuncts', '{"level":"family","recommended_attr_sets":["material_common","material_adjunct"]}'),
        ('material_type', 'PROCESS_AID', 'RAW_MATERIAL', 'Process Aid', '{"ja":"工程資材","en":"Process Aid"}', 60, 'Finings, enzymes and filter aids', '{"level":"family","recommended_attr_sets":["material_common","material_adjunct"]}'),
        ('material_type', 'BASE_MALT', 'MALT', 'Base Malt', '{"ja":"ベースモルト","en":"Base Malt"}', 10, 'Base malts for grist foundation', '{"recommended_attr_sets":["material_common","material_malt"]}'),
        ('material_type', 'SPECIALTY_MALT', 'MALT', 'Specialty Malt', '{"ja":"スペシャルティモルト","en":"Specialty Malt"}', 20, 'Specialty and character malts', '{"recommended_attr_sets":["material_common","material_malt"]}'),
        ('material_type', 'ROASTED_MALT', 'MALT', 'Roasted Malt', '{"ja":"焙煎モルト","en":"Roasted Malt"}', 30, 'Dark roasted malts', '{"recommended_attr_sets":["material_common","material_malt"]}'),
        ('material_type', 'HOP_PELLET', 'HOPS', 'Hop Pellet', '{"ja":"ペレットホップ","en":"Hop Pellet"}', 10, 'Pelletized hops', '{"recommended_attr_sets":["material_common","material_hops"]}'),
        ('material_type', 'HOP_WHOLE', 'HOPS', 'Whole Hop', '{"ja":"ホールホップ","en":"Whole Hop"}', 20, 'Whole-cone hops', '{"recommended_attr_sets":["material_common","material_hops"]}'),
        ('material_type', 'HOP_EXTRACT', 'HOPS', 'Hop Extract', '{"ja":"ホップエキス","en":"Hop Extract"}', 30, 'Hop extract products', '{"recommended_attr_sets":["material_common","material_hops"]}'),
        ('material_type', 'DRY_YEAST', 'YEAST', 'Dry Yeast', '{"ja":"ドライイースト","en":"Dry Yeast"}', 10, 'Dry brewing yeast', '{"recommended_attr_sets":["material_common","material_yeast"]}'),
        ('material_type', 'LIQUID_YEAST', 'YEAST', 'Liquid Yeast', '{"ja":"液体酵母","en":"Liquid Yeast"}', 20, 'Liquid brewing yeast', '{"recommended_attr_sets":["material_common","material_yeast"]}'),
        ('material_type', 'SLURRY_YEAST', 'YEAST', 'Slurry Yeast', '{"ja":"スラリー酵母","en":"Slurry Yeast"}', 30, 'Repitched slurry yeast', '{"recommended_attr_sets":["material_common","material_yeast"]}'),
        ('material_type', 'BREWING_SUGAR', 'ADJUNCT', 'Brewing Sugar', '{"ja":"糖類副原料","en":"Brewing Sugar"}', 10, 'Sugars used as adjuncts', '{"recommended_attr_sets":["material_common","material_adjunct"]}'),
        ('material_type', 'FRUIT_ADJUNCT', 'ADJUNCT', 'Fruit Adjunct', '{"ja":"果実副原料","en":"Fruit Adjunct"}', 20, 'Fruit purees and concentrates', '{"recommended_attr_sets":["material_common","material_adjunct"]}'),
        ('material_type', 'SPICE_ADJUNCT', 'ADJUNCT', 'Spice Adjunct', '{"ja":"スパイス副原料","en":"Spice Adjunct"}', 30, 'Spice and herb adjuncts', '{"recommended_attr_sets":["material_common","material_adjunct"]}'),
        ('material_type', 'ENZYME', 'PROCESS_AID', 'Enzyme', '{"ja":"酵素剤","en":"Enzyme"}', 10, 'Enzyme process aids', '{"recommended_attr_sets":["material_common","material_adjunct"]}'),
        ('material_type', 'FINING', 'PROCESS_AID', 'Fining', '{"ja":"清澄剤","en":"Fining"}', 20, 'Fining agents', '{"recommended_attr_sets":["material_common","material_adjunct"]}'),
        ('material_type', 'FILTER_AID', 'PROCESS_AID', 'Filter Aid', '{"ja":"ろ過助剤","en":"Filter Aid"}', 30, 'Filter aid materials', '{"recommended_attr_sets":["material_common","material_adjunct"]}'),
        ('material_type', 'PRIMARY_PACKAGE', 'PACKAGING', 'Primary Package', '{"ja":"一次包装","en":"Primary Package"}', 10, 'Primary product-contact packaging', '{"level":"group"}'),
        ('material_type', 'CLOSURE', 'PACKAGING', 'Closure', '{"ja":"栓・蓋","en":"Closure"}', 20, 'Closures and caps', '{"level":"group"}'),
        ('material_type', 'DECORATION', 'PACKAGING', 'Decoration', '{"ja":"装飾資材","en":"Decoration"}', 30, 'Labels and decorative packaging', '{"level":"group"}'),
        ('material_type', 'SECONDARY_PACKAGE', 'PACKAGING', 'Secondary Package', '{"ja":"二次包装","en":"Secondary Package"}', 40, 'Cartons and shipper packaging', '{"level":"group"}'),
        ('material_type', 'BOTTLE', 'PRIMARY_PACKAGE', 'Bottle', '{"ja":"瓶","en":"Bottle"}', 10, 'Glass bottle packaging', '{"recommended_attr_sets":["material_common","material_packaging"]}'),
        ('material_type', 'CAN', 'PRIMARY_PACKAGE', 'Can', '{"ja":"缶","en":"Can"}', 20, 'Can packaging', '{"recommended_attr_sets":["material_common","material_packaging"]}'),
        ('material_type', 'KEG', 'PRIMARY_PACKAGE', 'Keg', '{"ja":"樽","en":"Keg"}', 30, 'Keg container', '{"recommended_attr_sets":["material_common","material_packaging"]}'),
        ('material_type', 'CROWN_CAP', 'CLOSURE', 'Crown Cap', '{"ja":"王冠","en":"Crown Cap"}', 10, 'Bottle cap and closure', '{"recommended_attr_sets":["material_common","material_packaging"]}'),
        ('material_type', 'CAN_END', 'CLOSURE', 'Can End', '{"ja":"缶蓋","en":"Can End"}', 20, 'Can lid and end', '{"recommended_attr_sets":["material_common","material_packaging"]}'),
        ('material_type', 'KEG_FITTING', 'CLOSURE', 'Keg Fitting', '{"ja":"樽フィッティング","en":"Keg Fitting"}', 30, 'Keg fitting and spear parts', '{"recommended_attr_sets":["material_common","material_packaging"]}'),
        ('material_type', 'LABEL', 'DECORATION', 'Label', '{"ja":"ラベル","en":"Label"}', 10, 'Label materials', '{"recommended_attr_sets":["material_common","material_packaging"]}'),
        ('material_type', 'SLEEVE', 'DECORATION', 'Sleeve', '{"ja":"シュリンクスリーブ","en":"Sleeve"}', 20, 'Shrink sleeve material', '{"recommended_attr_sets":["material_common","material_packaging"]}'),
        ('material_type', 'CARTON', 'SECONDARY_PACKAGE', 'Carton', '{"ja":"外装箱","en":"Carton"}', 10, 'Secondary packaging cartons', '{"recommended_attr_sets":["material_common","material_packaging"]}'),
        ('material_type', 'TRAY', 'SECONDARY_PACKAGE', 'Tray', '{"ja":"トレー","en":"Tray"}', 20, 'Tray or basket packaging', '{"recommended_attr_sets":["material_common","material_packaging"]}'),
        ('material_type', 'SHIPPER_CASE', 'SECONDARY_PACKAGE', 'Shipper Case', '{"ja":"配送箱","en":"Shipper Case"}', 30, 'Shipping cases', '{"recommended_attr_sets":["material_common","material_packaging"]}'),
        ('material_type', 'BEER', 'FINISHED_GOOD', 'Beer', '{"ja":"ビール","en":"Beer"}', 10, 'Finished beer product', '{"recommended_attr_sets":["material_common","material_packaging"]}'),
        ('material_type', 'NON_BEER_BEVERAGE', 'FINISHED_GOOD', 'Non-beer Beverage', '{"ja":"ビール以外飲料","en":"Non-beer Beverage"}', 20, 'Non-beer finished beverage', '{"recommended_attr_sets":["material_common","material_packaging"]}'),
        ('material_type', 'SPENT_GRAIN', 'BYPRODUCT', 'Spent Grain', '{"ja":"麦芽粕","en":"Spent Grain"}', 10, 'Spent grain byproduct', '{"recommended_attr_sets":["material_common"]}'),
        ('material_type', 'SPENT_HOP', 'BYPRODUCT', 'Spent Hop', '{"ja":"ホップかす","en":"Spent Hop"}', 20, 'Spent hop byproduct', '{"recommended_attr_sets":["material_common"]}'),
        ('material_type', 'SPENT_YEAST', 'BYPRODUCT', 'Spent Yeast', '{"ja":"使用済み酵母","en":"Spent Yeast"}', 30, 'Spent yeast byproduct', '{"recommended_attr_sets":["material_common"]}'),
        ('material_type', 'TRUB', 'BYPRODUCT', 'Trub', '{"ja":"トルーブ","en":"Trub"}', 40, 'Trub and solids byproduct', '{"recommended_attr_sets":["material_common"]}'),
        ('equipment_type', 'EQUIPMENT', NULL, 'Equipment', '{"ja":"設備","en":"Equipment"}', 10, 'Root node for craft-beer equipment classification', '{"level":"root","recommended_attr_sets":[]}'),
        ('equipment_type', 'BREWHOUSE', 'EQUIPMENT', 'Brewhouse', '{"ja":"仕込設備","en":"Brewhouse"}', 10, 'Hot-side process equipment', '{"level":"group"}'),
        ('equipment_type', 'CELLAR', 'EQUIPMENT', 'Cellar', '{"ja":"セラー設備","en":"Cellar"}', 20, 'Cold-side process equipment', '{"level":"group"}'),
        ('equipment_type', 'PACKAGING_LINE', 'EQUIPMENT', 'Packaging Line', '{"ja":"包装設備","en":"Packaging Line"}', 30, 'Packaging process equipment', '{"level":"group"}'),
        ('equipment_type', 'UTILITY', 'EQUIPMENT', 'Utility', '{"ja":"ユーティリティ設備","en":"Utility"}', 40, 'Utility and support equipment', '{"level":"group"}'),
        ('equipment_type', 'QUALITY_CONTROL', 'EQUIPMENT', 'Quality Control', '{"ja":"品質管理設備","en":"Quality Control"}', 50, 'Lab and QC equipment', '{"level":"group"}'),
        ('equipment_type', 'MILLING', 'BREWHOUSE', 'Milling', '{"ja":"粉砕工程","en":"Milling"}', 10, 'Malt crushing equipment', '{"level":"group"}'),
        ('equipment_type', 'MASHING', 'BREWHOUSE', 'Mashing', '{"ja":"糖化工程","en":"Mashing"}', 20, 'Mashing equipment', '{"level":"group"}'),
        ('equipment_type', 'LAUTERING', 'BREWHOUSE', 'Lautering', '{"ja":"ろ過工程","en":"Lautering"}', 30, 'Lautering equipment', '{"level":"group"}'),
        ('equipment_type', 'BOILING', 'BREWHOUSE', 'Boiling', '{"ja":"煮沸工程","en":"Boiling"}', 40, 'Boiling and whirlpool equipment', '{"level":"group"}'),
        ('equipment_type', 'HOT_SIDE_TRANSFER', 'BREWHOUSE', 'Hot-side Transfer', '{"ja":"熱工程搬送","en":"Hot-side Transfer"}', 50, 'Hot-side transfer and cooling equipment', '{"level":"group"}'),
        ('equipment_type', 'MALT_MILL', 'MILLING', 'Malt Mill', '{"ja":"モルトミル","en":"Malt Mill"}', 10, 'Mill for crushed malt', '{"recommended_attr_sets":["equipment_common","equipment_brewhouse"]}'),
        ('equipment_type', 'GRIST_CASE', 'MILLING', 'Grist Case', '{"ja":"グリストケース","en":"Grist Case"}', 20, 'Grain grist case or hopper', '{"recommended_attr_sets":["equipment_common","equipment_brewhouse"]}'),
        ('equipment_type', 'MASH_TUN', 'MASHING', 'Mash Tun', '{"ja":"糖化槽","en":"Mash Tun"}', 10, 'Mashing vessel', '{"recommended_attr_sets":["equipment_common","equipment_brewhouse","equipment_tank"]}'),
        ('equipment_type', 'MASH_MIXER', 'MASHING', 'Mash Mixer', '{"ja":"マッシュミキサー","en":"Mash Mixer"}', 20, 'Mash mixing vessel', '{"recommended_attr_sets":["equipment_common","equipment_brewhouse","equipment_tank"]}'),
        ('equipment_type', 'LAUTER_TUN', 'LAUTERING', 'Lauter Tun', '{"ja":"ろ過槽","en":"Lauter Tun"}', 10, 'Lautering vessel', '{"recommended_attr_sets":["equipment_common","equipment_brewhouse","equipment_tank"]}'),
        ('equipment_type', 'BREW_KETTLE', 'BOILING', 'Brew Kettle', '{"ja":"煮沸釜","en":"Brew Kettle"}', 10, 'Wort boiling kettle', '{"recommended_attr_sets":["equipment_common","equipment_brewhouse","equipment_tank"]}'),
        ('equipment_type', 'WHIRLPOOL', 'BOILING', 'Whirlpool', '{"ja":"ワールプール","en":"Whirlpool"}', 20, 'Hot trub separation vessel', '{"recommended_attr_sets":["equipment_common","equipment_tank"]}'),
        ('equipment_type', 'HEAT_EXCHANGER', 'HOT_SIDE_TRANSFER', 'Heat Exchanger', '{"ja":"熱交換器","en":"Heat Exchanger"}', 10, 'Wort cooling heat exchanger', '{"recommended_attr_sets":["equipment_common","equipment_brewhouse"]}'),
        ('equipment_type', 'HOT_LIQUOR_TANK', 'HOT_SIDE_TRANSFER', 'Hot Liquor Tank', '{"ja":"温水タンク","en":"Hot Liquor Tank"}', 20, 'Heated brewing water tank', '{"recommended_attr_sets":["equipment_common","equipment_tank"]}'),
        ('equipment_type', 'COLD_LIQUOR_TANK', 'HOT_SIDE_TRANSFER', 'Cold Liquor Tank', '{"ja":"冷水タンク","en":"Cold Liquor Tank"}', 30, 'Cold brewing water tank', '{"recommended_attr_sets":["equipment_common","equipment_tank"]}'),
        ('equipment_type', 'FERMENTATION', 'CELLAR', 'Fermentation', '{"ja":"発酵工程","en":"Fermentation"}', 10, 'Fermentation equipment', '{"level":"group"}'),
        ('equipment_type', 'BRIGHT_BEER', 'CELLAR', 'Bright Beer', '{"ja":"熟成工程","en":"Bright Beer"}', 20, 'Conditioning and bright beer equipment', '{"level":"group"}'),
        ('equipment_type', 'YEAST_HANDLING', 'CELLAR', 'Yeast Handling', '{"ja":"酵母管理","en":"Yeast Handling"}', 30, 'Yeast handling equipment', '{"level":"group"}'),
        ('equipment_type', 'CELLAR_SUPPORT', 'CELLAR', 'Cellar Support', '{"ja":"セラー補助設備","en":"Cellar Support"}', 40, 'Cleaning and cellar support equipment', '{"level":"group"}'),
        ('equipment_type', 'FERMENTER', 'FERMENTATION', 'Fermenter', '{"ja":"発酵タンク","en":"Fermenter"}', 10, 'Fermentation tank', '{"recommended_attr_sets":["equipment_common","equipment_cold_side","equipment_tank"]}'),
        ('equipment_type', 'UNITANK', 'FERMENTATION', 'Unitank', '{"ja":"ユニタンク","en":"Unitank"}', 20, 'Single vessel for ferment and condition', '{"recommended_attr_sets":["equipment_common","equipment_cold_side","equipment_tank"]}'),
        ('equipment_type', 'BRITE_TANK', 'BRIGHT_BEER', 'Brite Tank', '{"ja":"ブライトタンク","en":"Brite Tank"}', 10, 'Bright beer tank', '{"recommended_attr_sets":["equipment_common","equipment_cold_side","equipment_tank"]}'),
        ('equipment_type', 'YEAST_PROPAGATION_TANK', 'YEAST_HANDLING', 'Yeast Propagation Tank', '{"ja":"酵母培養槽","en":"Yeast Propagation Tank"}', 10, 'Yeast propagation vessel', '{"recommended_attr_sets":["equipment_common","equipment_cold_side","equipment_tank"]}'),
        ('equipment_type', 'YEAST_BRINK', 'YEAST_HANDLING', 'Yeast Brink', '{"ja":"酵母保管タンク","en":"Yeast Brink"}', 20, 'Yeast storage and pitching tank', '{"recommended_attr_sets":["equipment_common","equipment_cold_side","equipment_tank"]}'),
        ('equipment_type', 'CIP_SKID', 'CELLAR_SUPPORT', 'CIP Skid', '{"ja":"CIP装置","en":"CIP Skid"}', 10, 'Cleaning-in-place skid', '{"recommended_attr_sets":["equipment_common","equipment_cold_side"]}'),
        ('equipment_type', 'DE_FILTER', 'CELLAR_SUPPORT', 'DE Filter', '{"ja":"珪藻土ろ過機","en":"DE Filter"}', 20, 'Diatomaceous earth filter', '{"recommended_attr_sets":["equipment_common","equipment_cold_side"]}'),
        ('equipment_type', 'BOTTLE_PACKAGING', 'PACKAGING_LINE', 'Bottle Packaging', '{"ja":"瓶包装ライン","en":"Bottle Packaging"}', 10, 'Bottle packaging equipment group', '{"level":"group"}'),
        ('equipment_type', 'CAN_PACKAGING', 'PACKAGING_LINE', 'Can Packaging', '{"ja":"缶包装ライン","en":"Can Packaging"}', 20, 'Can packaging equipment group', '{"level":"group"}'),
        ('equipment_type', 'KEG_PACKAGING', 'PACKAGING_LINE', 'Keg Packaging', '{"ja":"樽包装ライン","en":"Keg Packaging"}', 30, 'Keg packaging equipment group', '{"level":"group"}'),
        ('equipment_type', 'END_OF_LINE', 'PACKAGING_LINE', 'End Of Line', '{"ja":"後工程包装","en":"End Of Line"}', 40, 'End-of-line packaging equipment', '{"level":"group"}'),
        ('equipment_type', 'BOTTLING_LINE', 'BOTTLE_PACKAGING', 'Bottling Line', '{"ja":"瓶詰ライン","en":"Bottling Line"}', 10, 'Bottling line', '{"recommended_attr_sets":["equipment_common","equipment_packaging_line"]}'),
        ('equipment_type', 'BOTTLE_RINSER', 'BOTTLE_PACKAGING', 'Bottle Rinser', '{"ja":"ボトルリンサー","en":"Bottle Rinser"}', 20, 'Bottle rinsing machine', '{"recommended_attr_sets":["equipment_common","equipment_packaging_line"]}'),
        ('equipment_type', 'CANNING_LINE', 'CAN_PACKAGING', 'Canning Line', '{"ja":"缶詰ライン","en":"Canning Line"}', 10, 'Canning line', '{"recommended_attr_sets":["equipment_common","equipment_packaging_line"]}'),
        ('equipment_type', 'SEAMER', 'CAN_PACKAGING', 'Seamer', '{"ja":"シーマー","en":"Seamer"}', 20, 'Can seamer', '{"recommended_attr_sets":["equipment_common","equipment_packaging_line"]}'),
        ('equipment_type', 'KEG_FILLER', 'KEG_PACKAGING', 'Keg Filler', '{"ja":"樽詰機","en":"Keg Filler"}', 10, 'Keg filling machine', '{"recommended_attr_sets":["equipment_common","equipment_packaging_line"]}'),
        ('equipment_type', 'KEG_WASHER', 'KEG_PACKAGING', 'Keg Washer', '{"ja":"樽洗浄機","en":"Keg Washer"}', 20, 'Keg washing machine', '{"recommended_attr_sets":["equipment_common","equipment_packaging_line"]}'),
        ('equipment_type', 'LABELER', 'END_OF_LINE', 'Labeler', '{"ja":"ラベラー","en":"Labeler"}', 10, 'Label application equipment', '{"recommended_attr_sets":["equipment_common","equipment_packaging_line"]}'),
        ('equipment_type', 'CASE_PACKER', 'END_OF_LINE', 'Case Packer', '{"ja":"ケースパッカー","en":"Case Packer"}', 20, 'Secondary packaging equipment', '{"recommended_attr_sets":["equipment_common","equipment_packaging_line"]}'),
        ('equipment_type', 'PALLETIZER', 'END_OF_LINE', 'Palletizer', '{"ja":"パレタイザー","en":"Palletizer"}', 30, 'Palletizing equipment', '{"recommended_attr_sets":["equipment_common","equipment_packaging_line"]}'),
        ('equipment_type', 'GLYCOL_CHILLER', 'UTILITY', 'Glycol Chiller', '{"ja":"グリコールチラー","en":"Glycol Chiller"}', 10, 'Glycol cooling unit', '{"recommended_attr_sets":["equipment_common","equipment_cold_side"]}'),
        ('equipment_type', 'STEAM_BOILER', 'UTILITY', 'Steam Boiler', '{"ja":"蒸気ボイラー","en":"Steam Boiler"}', 20, 'Steam boiler for brewhouse heating', '{"recommended_attr_sets":["equipment_common"]}'),
        ('equipment_type', 'AIR_COMPRESSOR', 'UTILITY', 'Air Compressor', '{"ja":"エアコンプレッサー","en":"Air Compressor"}', 30, 'Compressed air utility unit', '{"recommended_attr_sets":["equipment_common"]}'),
        ('equipment_type', 'WATER_TREATMENT', 'UTILITY', 'Water Treatment', '{"ja":"水処理設備","en":"Water Treatment"}', 40, 'Water treatment equipment', '{"recommended_attr_sets":["equipment_common"]}'),
        ('equipment_type', 'CO2_SUPPLY', 'UTILITY', 'CO2 Supply', '{"ja":"CO2供給設備","en":"CO2 Supply"}', 50, 'CO2 supply and management equipment', '{"recommended_attr_sets":["equipment_common"]}'),
        ('equipment_type', 'LAB_ANALYZER', 'QUALITY_CONTROL', 'Lab Analyzer', '{"ja":"分析装置","en":"Lab Analyzer"}', 10, 'Quality control analytical equipment', '{"recommended_attr_sets":["equipment_common"]}'),
        ('equipment_type', 'MICROBIOLOGY_INCUBATOR', 'QUALITY_CONTROL', 'Microbiology Incubator', '{"ja":"微生物培養器","en":"Microbiology Incubator"}', 20, 'Microbiology incubation equipment', '{"recommended_attr_sets":["equipment_common"]}')
    ) AS seed(domain, code, parent_code, name, name_i18n, sort_order, description, meta)
  ),
  resolved_tree AS (
    SELECT
      node.type_id,
      node.domain,
      node.code,
      node.name,
      node.name_i18n,
      node.sort_order,
      node.description,
      node.meta,
      parent.type_id AS parent_type_id
    FROM type_seed node
    LEFT JOIN type_seed parent
      ON parent.domain = node.domain
     AND parent.code = node.parent_code
  )
  INSERT INTO public.type_def (
    tenant_id, type_id, scope, owner_id, domain, industry_id, code, name, name_i18n,
    parent_type_id, sort_order, description, meta, is_active
  )
  SELECT
    v_tenant,
    type_id,
    'tenant',
    v_tenant,
    domain,
    v_industry_id,
    code,
    name,
    name_i18n,
    parent_type_id,
    sort_order,
    description,
    meta,
    true
  FROM resolved_tree;

  INSERT INTO public.attr_def (
    tenant_id, domain, scope, owner_id, industry_id, code, name, name_i18n,
    data_type, uom_id, ref_kind, ref_domain, required, num_min, num_max,
    allowed_values, description, sort_order, meta, is_active
  )
  SELECT
    v_tenant,
    defs.domain,
    'tenant',
    v_tenant,
    v_industry_id,
    defs.code,
    defs.name,
    defs.name_i18n::jsonb,
    defs.data_type,
    CASE defs.uom_code
      WHEN '%' THEN v_uom_pct
      WHEN 'C' THEN v_uom_c
      WHEN 'mL' THEN v_uom_ml
      WHEN 'L' THEN v_uom_l
      WHEN 'g' THEN v_uom_g
      ELSE NULL
    END,
    NULL,
    NULL,
    defs.required,
    defs.num_min,
    defs.num_max,
    defs.allowed_values::jsonb,
    defs.description,
    defs.sort_order,
    defs.meta::jsonb,
    true
  FROM (
    VALUES
      ('material', 'manufacturer', 'Manufacturer', '{"ja":"製造元","en":"Manufacturer"}', 'string', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Manufacturer or maltster / producer', 10, '{"group":"common"}'),
      ('material', 'supplier_name', 'Supplier Name', '{"ja":"仕入先名","en":"Supplier Name"}', 'string', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Primary purchasing supplier', 20, '{"group":"common"}'),
      ('material', 'supplier_item_code', 'Supplier Item Code', '{"ja":"仕入先品番","en":"Supplier Item Code"}', 'string', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Supplier-specific item code', 30, '{"group":"common"}'),
      ('material', 'origin_country', 'Origin Country', '{"ja":"原産国","en":"Origin Country"}', 'string', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Country of origin for the material', 40, '{"group":"common"}'),
      ('material', 'storage_condition', 'Storage Condition', '{"ja":"保管条件","en":"Storage Condition"}', 'string', NULL, false, NULL::numeric, NULL::numeric, '["ambient","cool","cold","frozen","dry"]', 'Recommended storage condition', 50, '{"group":"common"}'),
      ('material', 'shelf_life_days', 'Shelf Life Days', '{"ja":"賞味期限日数","en":"Shelf Life Days"}', 'number', NULL, false, 0, NULL::numeric, NULL, 'Shelf life in days', 60, '{"group":"common"}'),
      ('material', 'allergen_note', 'Allergen Note', '{"ja":"アレルゲン備考","en":"Allergen Note"}', 'string', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Allergen handling notes', 70, '{"group":"common"}'),
      ('material', 'organic_certified', 'Organic Certified', '{"ja":"有機認証","en":"Organic Certified"}', 'boolean', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Whether the material is organic certified', 80, '{"group":"common"}'),
      ('material', 'extract_yield_pct', 'Extract Yield', '{"ja":"抽出収率","en":"Extract Yield"}', 'number', '%', false, 0, 100, NULL, 'Potential extract yield percentage for malt', 110, '{"group":"malt"}'),
      ('material', 'color_ebc', 'Color EBC', '{"ja":"色度 EBC","en":"Color EBC"}', 'number', NULL, false, 0, NULL::numeric, NULL, 'Color contribution in EBC', 120, '{"group":"malt"}'),
      ('material', 'protein_pct', 'Protein Percentage', '{"ja":"たんぱく質率","en":"Protein Percentage"}', 'number', '%', false, 0, 100, NULL, 'Protein percentage', 130, '{"group":"malt"}'),
      ('material', 'moisture_pct', 'Moisture Percentage', '{"ja":"水分率","en":"Moisture Percentage"}', 'number', '%', false, 0, 100, NULL, 'Moisture content percentage', 140, '{"group":"malt"}'),
      ('material', 'hop_form', 'Hop Form', '{"ja":"ホップ形状","en":"Hop Form"}', 'string', NULL, false, NULL::numeric, NULL::numeric, '["pellet","whole","cryo","extract"]', 'Physical form of hop product', 210, '{"group":"hops"}'),
      ('material', 'alpha_acid_pct', 'Alpha Acid', '{"ja":"α酸","en":"Alpha Acid"}', 'number', '%', false, 0, 100, NULL, 'Alpha acid percentage', 220, '{"group":"hops"}'),
      ('material', 'beta_acid_pct', 'Beta Acid', '{"ja":"β酸","en":"Beta Acid"}', 'number', '%', false, 0, 100, NULL, 'Beta acid percentage', 230, '{"group":"hops"}'),
      ('material', 'crop_year', 'Crop Year', '{"ja":"収穫年","en":"Crop Year"}', 'number', NULL, false, 2000, 2100, NULL, 'Harvest crop year for hops', 240, '{"group":"hops"}'),
      ('material', 'strain_code', 'Strain Code', '{"ja":"菌株コード","en":"Strain Code"}', 'string', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Supplier strain identifier', 310, '{"group":"yeast"}'),
      ('material', 'yeast_form', 'Yeast Form', '{"ja":"酵母形状","en":"Yeast Form"}', 'string', NULL, false, NULL::numeric, NULL::numeric, '["dry","liquid","slurry"]', 'Physical form of yeast', 320, '{"group":"yeast"}'),
      ('material', 'attenuation_pct', 'Attenuation', '{"ja":"発酵度","en":"Attenuation"}', 'number', '%', false, 0, 100, NULL, 'Typical apparent attenuation percentage', 330, '{"group":"yeast"}'),
      ('material', 'fermentation_temp_min_c', 'Fermentation Temp Min', '{"ja":"発酵温度下限","en":"Fermentation Temp Min"}', 'number', 'C', false, -10, 60, NULL, 'Minimum recommended fermentation temperature', 340, '{"group":"yeast"}'),
      ('material', 'fermentation_temp_max_c', 'Fermentation Temp Max', '{"ja":"発酵温度上限","en":"Fermentation Temp Max"}', 'number', 'C', false, -10, 60, NULL, 'Maximum recommended fermentation temperature', 350, '{"group":"yeast"}'),
      ('material', 'hardness_ppm', 'Hardness', '{"ja":"硬度","en":"Hardness"}', 'number', NULL, false, 0, NULL::numeric, NULL, 'Water hardness in ppm as CaCO3', 410, '{"group":"water"}'),
      ('material', 'alkalinity_ppm', 'Alkalinity', '{"ja":"アルカリ度","en":"Alkalinity"}', 'number', NULL, false, 0, NULL::numeric, NULL, 'Water alkalinity in ppm', 420, '{"group":"water"}'),
      ('material', 'chloride_ppm', 'Chloride', '{"ja":"塩化物","en":"Chloride"}', 'number', NULL, false, 0, NULL::numeric, NULL, 'Water chloride ppm', 430, '{"group":"water"}'),
      ('material', 'sulfate_ppm', 'Sulfate', '{"ja":"硫酸塩","en":"Sulfate"}', 'number', NULL, false, 0, NULL::numeric, NULL, 'Water sulfate ppm', 440, '{"group":"water"}'),
      ('material', 'ph', 'pH', '{"ja":"pH","en":"pH"}', 'number', NULL, false, 0, 14, NULL, 'Water pH', 450, '{"group":"water"}'),
      ('material', 'package_volume_ml', 'Package Volume', '{"ja":"内容量","en":"Package Volume"}', 'number', 'mL', false, 0, NULL::numeric, NULL, 'Nominal package volume', 510, '{"group":"packaging"}'),
      ('material', 'tare_weight_g', 'Tare Weight', '{"ja":"風袋重量","en":"Tare Weight"}', 'number', 'g', false, 0, NULL::numeric, NULL, 'Empty package weight', 520, '{"group":"packaging"}'),
      ('material', 'container_color', 'Container Color', '{"ja":"容器色","en":"Container Color"}', 'string', NULL, false, NULL::numeric, NULL::numeric, '["clear","green","amber","silver","printed"]', 'Package or container color', 530, '{"group":"packaging"}'),
      ('material', 'package_material', 'Package Material', '{"ja":"包装材質","en":"Package Material"}', 'string', NULL, false, NULL::numeric, NULL::numeric, '["glass","aluminum","steel","paper","plastic","mixed"]', 'Primary package material', 540, '{"group":"packaging"}'),
      ('material', 'adjunct_type', 'Adjunct Type', '{"ja":"副原料種別","en":"Adjunct Type"}', 'string', NULL, false, NULL::numeric, NULL::numeric, '["sugar","fruit","spice","herb","coffee","cacao","enzyme","fining"]', 'Type of adjunct or process aid', 610, '{"group":"adjunct"}'),
      ('material', 'max_usage_pct', 'Max Usage Percentage', '{"ja":"最大使用率","en":"Max Usage Percentage"}', 'number', '%', false, 0, 100, NULL, 'Maximum recipe usage recommendation', 620, '{"group":"adjunct"}'),
      ('equipment', 'equipment_manufacturer', 'Manufacturer', '{"ja":"製造元","en":"Manufacturer"}', 'string', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Equipment manufacturer', 10, '{"group":"common"}'),
      ('equipment', 'equipment_model', 'Model', '{"ja":"型式","en":"Model"}', 'string', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Equipment model number', 20, '{"group":"common"}'),
      ('equipment', 'serial_number', 'Serial Number', '{"ja":"製造番号","en":"Serial Number"}', 'string', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Manufacturer serial number', 30, '{"group":"common"}'),
      ('equipment', 'rated_capacity_l', 'Rated Capacity', '{"ja":"定格容量","en":"Rated Capacity"}', 'number', 'L', false, 0, NULL::numeric, NULL, 'Rated vessel or machine capacity', 40, '{"group":"common"}'),
      ('equipment', 'cip_capable', 'CIP Capable', '{"ja":"CIP対応","en":"CIP Capable"}', 'boolean', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Whether equipment supports CIP', 50, '{"group":"common"}'),
      ('equipment', 'utility_requirements', 'Utility Requirements', '{"ja":"ユーティリティ要件","en":"Utility Requirements"}', 'json', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Utility requirements summary JSON', 60, '{"group":"common"}'),
      ('equipment', 'working_volume_l', 'Working Volume', '{"ja":"実作業容量","en":"Working Volume"}', 'number', 'L', false, 0, NULL::numeric, NULL, 'Usable working volume for tanks', 110, '{"group":"tank"}'),
      ('equipment', 'pressure_rating_bar', 'Pressure Rating', '{"ja":"耐圧","en":"Pressure Rating"}', 'number', NULL, false, 0, NULL::numeric, NULL, 'Maximum rated pressure in bar', 120, '{"group":"tank"}'),
      ('equipment', 'jacket_zone_count', 'Jacket Zone Count', '{"ja":"ジャケットゾーン数","en":"Jacket Zone Count"}', 'number', NULL, false, 0, NULL::numeric, NULL, 'Count of temperature control jacket zones', 130, '{"group":"tank"}'),
      ('equipment', 'has_carb_stone', 'Has Carb Stone', '{"ja":"カーボネーションストーン有無","en":"Has Carb Stone"}', 'boolean', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Whether tank has carbonation stone', 140, '{"group":"tank"}'),
      ('equipment', 'temperature_probe_count', 'Temperature Probe Count', '{"ja":"温度計測点数","en":"Temperature Probe Count"}', 'number', NULL, false, 0, NULL::numeric, NULL, 'Number of installed temperature probes', 150, '{"group":"tank"}'),
      ('equipment', 'heating_mode', 'Heating Mode', '{"ja":"加熱方式","en":"Heating Mode"}', 'string', NULL, false, NULL::numeric, NULL::numeric, '["steam","electric","direct_fire","none"]', 'Heating mode of brewhouse equipment', 210, '{"group":"brewhouse"}'),
      ('equipment', 'agitator_installed', 'Agitator Installed', '{"ja":"撹拌機有無","en":"Agitator Installed"}', 'boolean', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Whether equipment has agitator', 220, '{"group":"brewhouse"}'),
      ('equipment', 'steam_required', 'Steam Required', '{"ja":"蒸気要否","en":"Steam Required"}', 'boolean', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Whether steam utility is required', 230, '{"group":"brewhouse"}'),
      ('equipment', 'cooling_zone_count', 'Cooling Zone Count', '{"ja":"冷却ゾーン数","en":"Cooling Zone Count"}', 'number', NULL, false, 0, NULL::numeric, NULL, 'Count of cooling or jacket zones', 310, '{"group":"cold_side"}'),
      ('equipment', 'temp_control_supported', 'Temperature Control Supported', '{"ja":"温度制御対応","en":"Temperature Control Supported"}', 'boolean', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Whether temperature control is supported', 320, '{"group":"cold_side"}'),
      ('equipment', 'glycol_loop_required', 'Glycol Loop Required', '{"ja":"グリコール循環要否","en":"Glycol Loop Required"}', 'boolean', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Whether glycol loop is required', 330, '{"group":"cold_side"}'),
      ('equipment', 'package_format', 'Package Format', '{"ja":"包装形態","en":"Package Format"}', 'string', NULL, false, NULL::numeric, NULL::numeric, '["bottle","can","keg","mixed"]', 'Supported package format', 410, '{"group":"packaging_line"}'),
      ('equipment', 'rated_speed_cph', 'Rated Speed CPH', '{"ja":"定格能力 CPH","en":"Rated Speed CPH"}', 'number', NULL, false, 0, NULL::numeric, NULL, 'Rated speed in containers per hour', 420, '{"group":"packaging_line"}'),
      ('equipment', 'rinser_integrated', 'Rinser Integrated', '{"ja":"リンサー内蔵","en":"Rinser Integrated"}', 'boolean', NULL, false, NULL::numeric, NULL::numeric, NULL, 'Whether rinser is integrated', 430, '{"group":"packaging_line"}')
  ) AS defs(domain, code, name, name_i18n, data_type, uom_code, required, num_min, num_max, allowed_values, description, sort_order, meta);

  INSERT INTO public.attr_set (
    tenant_id, domain, scope, owner_id, industry_id, code, name, name_i18n,
    description, sort_order, meta, is_active
  )
  SELECT
    v_tenant,
    sets.domain,
    'tenant',
    v_tenant,
    v_industry_id,
    sets.code,
    sets.name,
    sets.name_i18n::jsonb,
    sets.description,
    sets.sort_order,
    sets.meta::jsonb,
    true
  FROM (
    VALUES
      ('material', 'material_common', 'Material Common', '{"ja":"原材料共通","en":"Material Common"}', 'Common vendor and storage attributes for materials', 10, '{"category":"common"}'),
      ('material', 'material_malt', 'Material Malt', '{"ja":"麦芽属性","en":"Material Malt"}', 'Malt-specific brewing properties', 20, '{"category":"malt"}'),
      ('material', 'material_hops', 'Material Hops', '{"ja":"ホップ属性","en":"Material Hops"}', 'Hop-specific brewing properties', 30, '{"category":"hops"}'),
      ('material', 'material_yeast', 'Material Yeast', '{"ja":"酵母属性","en":"Material Yeast"}', 'Yeast-specific brewing properties', 40, '{"category":"yeast"}'),
      ('material', 'material_water', 'Material Water', '{"ja":"水属性","en":"Material Water"}', 'Water chemistry properties', 50, '{"category":"water"}'),
      ('material', 'material_packaging', 'Material Packaging', '{"ja":"包装資材属性","en":"Material Packaging"}', 'Packaging material properties', 60, '{"category":"packaging"}'),
      ('material', 'material_adjunct', 'Material Adjunct', '{"ja":"副原料属性","en":"Material Adjunct"}', 'Adjunct and process-aid properties', 70, '{"category":"adjunct"}'),
      ('equipment', 'equipment_common', 'Equipment Common', '{"ja":"設備共通","en":"Equipment Common"}', 'Common equipment master attributes', 10, '{"category":"common"}'),
      ('equipment', 'equipment_tank', 'Equipment Tank', '{"ja":"タンク属性","en":"Equipment Tank"}', 'Tank-specific equipment attributes', 20, '{"category":"tank"}'),
      ('equipment', 'equipment_brewhouse', 'Equipment Brewhouse', '{"ja":"仕込設備属性","en":"Equipment Brewhouse"}', 'Brewhouse equipment attributes', 30, '{"category":"brewhouse"}'),
      ('equipment', 'equipment_cold_side', 'Equipment Cold Side', '{"ja":"セラー設備属性","en":"Equipment Cold Side"}', 'Cold-side equipment attributes', 40, '{"category":"cold_side"}'),
      ('equipment', 'equipment_packaging_line', 'Equipment Packaging Line', '{"ja":"包装設備属性","en":"Equipment Packaging Line"}', 'Packaging line equipment attributes', 50, '{"category":"packaging_line"}')
  ) AS sets(domain, code, name, name_i18n, description, sort_order, meta);

  INSERT INTO public.attr_set_rule (
    tenant_id, attr_set_id, attr_id, required, ui_section, ui_widget, help_text,
    sort_order, is_active, meta
  )
  SELECT
    v_tenant,
    s.attr_set_id,
    d.attr_id,
    rule.required,
    rule.ui_section,
    rule.ui_widget,
    rule.help_text,
    rule.sort_order,
    true,
    rule.meta::jsonb
  FROM (
    VALUES
      ('material', 'material_common', 'manufacturer', false, 'Vendor', 'text', 'Manufacturer or producer name', 10, '{}'),
      ('material', 'material_common', 'supplier_name', false, 'Vendor', 'text', 'Primary supplier name', 20, '{}'),
      ('material', 'material_common', 'supplier_item_code', false, 'Vendor', 'text', 'Supplier code or SKU', 30, '{}'),
      ('material', 'material_common', 'origin_country', false, 'Basics', 'text', 'Country of origin', 40, '{}'),
      ('material', 'material_common', 'storage_condition', false, 'Storage', 'select', 'Recommended storage condition', 50, '{}'),
      ('material', 'material_common', 'shelf_life_days', false, 'Storage', 'number', 'Shelf life in days', 60, '{}'),
      ('material', 'material_common', 'allergen_note', false, 'Compliance', 'textarea', 'Allergen note', 70, '{}'),
      ('material', 'material_common', 'organic_certified', false, 'Compliance', 'toggle', 'Organic certification flag', 80, '{}'),
      ('material', 'material_malt', 'extract_yield_pct', true, 'Brewing', 'number', 'Potential extract yield', 10, '{}'),
      ('material', 'material_malt', 'color_ebc', true, 'Brewing', 'number', 'Color contribution in EBC', 20, '{}'),
      ('material', 'material_malt', 'protein_pct', false, 'Brewing', 'number', 'Protein percentage', 30, '{}'),
      ('material', 'material_malt', 'moisture_pct', false, 'Brewing', 'number', 'Moisture percentage', 40, '{}'),
      ('material', 'material_hops', 'hop_form', true, 'Brewing', 'select', 'Hop product form', 10, '{}'),
      ('material', 'material_hops', 'alpha_acid_pct', true, 'Brewing', 'number', 'Alpha acid percentage', 20, '{}'),
      ('material', 'material_hops', 'beta_acid_pct', false, 'Brewing', 'number', 'Beta acid percentage', 30, '{}'),
      ('material', 'material_hops', 'crop_year', false, 'Brewing', 'number', 'Crop year', 40, '{}'),
      ('material', 'material_yeast', 'strain_code', true, 'Brewing', 'text', 'Supplier strain code', 10, '{}'),
      ('material', 'material_yeast', 'yeast_form', true, 'Brewing', 'select', 'Yeast physical form', 20, '{}'),
      ('material', 'material_yeast', 'attenuation_pct', false, 'Brewing', 'number', 'Typical attenuation', 30, '{}'),
      ('material', 'material_yeast', 'fermentation_temp_min_c', false, 'Brewing', 'number', 'Recommended min temp', 40, '{}'),
      ('material', 'material_yeast', 'fermentation_temp_max_c', false, 'Brewing', 'number', 'Recommended max temp', 50, '{}'),
      ('material', 'material_water', 'hardness_ppm', false, 'Chemistry', 'number', 'Water hardness', 10, '{}'),
      ('material', 'material_water', 'alkalinity_ppm', false, 'Chemistry', 'number', 'Water alkalinity', 20, '{}'),
      ('material', 'material_water', 'chloride_ppm', false, 'Chemistry', 'number', 'Water chloride ppm', 30, '{}'),
      ('material', 'material_water', 'sulfate_ppm', false, 'Chemistry', 'number', 'Water sulfate ppm', 40, '{}'),
      ('material', 'material_water', 'ph', true, 'Chemistry', 'number', 'Water pH', 50, '{}'),
      ('material', 'material_packaging', 'package_volume_ml', true, 'Package', 'number', 'Nominal content volume', 10, '{}'),
      ('material', 'material_packaging', 'package_material', true, 'Package', 'select', 'Primary package material', 20, '{}'),
      ('material', 'material_packaging', 'container_color', false, 'Package', 'select', 'Container color', 30, '{}'),
      ('material', 'material_packaging', 'tare_weight_g', false, 'Package', 'number', 'Empty package weight', 40, '{}'),
      ('material', 'material_adjunct', 'adjunct_type', true, 'Brewing', 'select', 'Adjunct or process aid type', 10, '{}'),
      ('material', 'material_adjunct', 'max_usage_pct', false, 'Brewing', 'number', 'Maximum recommended usage percentage', 20, '{}'),
      ('equipment', 'equipment_common', 'equipment_manufacturer', false, 'Basics', 'text', 'Equipment manufacturer', 10, '{}'),
      ('equipment', 'equipment_common', 'equipment_model', false, 'Basics', 'text', 'Model name or number', 20, '{}'),
      ('equipment', 'equipment_common', 'serial_number', false, 'Basics', 'text', 'Serial number', 30, '{}'),
      ('equipment', 'equipment_common', 'rated_capacity_l', false, 'Capacity', 'number', 'Rated capacity in liters', 40, '{}'),
      ('equipment', 'equipment_common', 'cip_capable', false, 'Utilities', 'toggle', 'Whether CIP capable', 50, '{}'),
      ('equipment', 'equipment_common', 'utility_requirements', false, 'Utilities', 'json', 'Utility requirement JSON', 60, '{}'),
      ('equipment', 'equipment_tank', 'working_volume_l', true, 'Capacity', 'number', 'Working volume in liters', 10, '{}'),
      ('equipment', 'equipment_tank', 'pressure_rating_bar', false, 'Mechanical', 'number', 'Pressure rating in bar', 20, '{}'),
      ('equipment', 'equipment_tank', 'jacket_zone_count', false, 'Mechanical', 'number', 'Jacket zone count', 30, '{}'),
      ('equipment', 'equipment_tank', 'has_carb_stone', false, 'Mechanical', 'toggle', 'Carbonation stone flag', 40, '{}'),
      ('equipment', 'equipment_tank', 'temperature_probe_count', false, 'Controls', 'number', 'Number of probes', 50, '{}'),
      ('equipment', 'equipment_brewhouse', 'heating_mode', false, 'Process', 'select', 'Heating mode', 10, '{}'),
      ('equipment', 'equipment_brewhouse', 'agitator_installed', false, 'Process', 'toggle', 'Agitator installed', 20, '{}'),
      ('equipment', 'equipment_brewhouse', 'steam_required', false, 'Utilities', 'toggle', 'Steam requirement', 30, '{}'),
      ('equipment', 'equipment_cold_side', 'cooling_zone_count', false, 'Controls', 'number', 'Cooling zone count', 10, '{}'),
      ('equipment', 'equipment_cold_side', 'temp_control_supported', true, 'Controls', 'toggle', 'Temperature control supported', 20, '{}'),
      ('equipment', 'equipment_cold_side', 'glycol_loop_required', false, 'Utilities', 'toggle', 'Glycol loop required', 30, '{}'),
      ('equipment', 'equipment_packaging_line', 'package_format', true, 'Process', 'select', 'Supported package format', 10, '{}'),
      ('equipment', 'equipment_packaging_line', 'rated_speed_cph', false, 'Process', 'number', 'Rated containers per hour', 20, '{}'),
      ('equipment', 'equipment_packaging_line', 'rinser_integrated', false, 'Process', 'toggle', 'Rinser integrated', 30, '{}')
  ) AS rule(domain, set_code, attr_code, required, ui_section, ui_widget, help_text, sort_order, meta)
  JOIN public.attr_set s
    ON s.tenant_id = v_tenant
   AND s.domain = rule.domain
   AND s.industry_id IS NOT DISTINCT FROM v_industry_id
   AND s.code = rule.set_code
  JOIN public.attr_def d
    ON d.tenant_id = v_tenant
   AND d.domain = rule.domain
   AND d.industry_id IS NOT DISTINCT FROM v_industry_id
   AND d.code = rule.attr_code;

  INSERT INTO public.entity_attr_set (
    tenant_id,
    entity_type,
    entity_id,
    attr_set_id,
    is_active
  )
  SELECT
    v_tenant,
    td.domain,
    td.type_id,
    s.attr_set_id,
    true
  FROM public.type_def td
  CROSS JOIN LATERAL jsonb_array_elements_text(
    COALESCE(td.meta -> 'recommended_attr_sets', '[]'::jsonb)
  ) AS rec(attr_set_code)
  JOIN public.attr_set s
    ON s.tenant_id = v_tenant
   AND s.industry_id IS NOT DISTINCT FROM v_industry_id
   AND s.code = rec.attr_set_code
   AND (
     (td.domain = 'material_type' AND s.domain = 'material')
     OR (td.domain = 'equipment_type' AND s.domain = 'equipment')
   )
  WHERE td.tenant_id = v_tenant
    AND td.domain IN ('material_type', 'equipment_type');

  RAISE NOTICE 'Craft-beer material/equipment seed completed for tenant % (industry %).', v_tenant, v_industry_id;
END
$seed$;
