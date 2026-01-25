INSERT INTO public.registry_def
(def_id, kind, def_key, "scope", owner_id, is_active, spec, created_at, updated_at)
VALUES('3dca7f7f-3ef1-49b9-a691-391cbb2b24fc'::uuid, 'material_class', 'malt', 'system', NULL, true, '{"name": "malt", "label": "麦芽", "category": "原材料", "description": "例：ピルスナーモルト、ペールモルト、ミュンヘン、カラメルモルト、ウィートモルト", "alcohol_tax_required_flg": false, "moving_control_required_flg": true, "shipment_control_required_flg": false, "manufacturing_application_required_flg": true}'::jsonb, '2026-01-24 22:30:05.658', '2026-01-24 22:30:05.658');
INSERT INTO public.registry_def
(def_id, kind, def_key, "scope", owner_id, is_active, spec, created_at, updated_at)
VALUES('94afbc91-aef0-472b-9dbe-fe46c1c683e3'::uuid, 'material_class', 'rice', 'system', NULL, true, '{"name": "rice", "label": "米", "category": "原材料", "description": "例：うるち米、砕米（ライスフレーク等）", "alcohol_tax_required_flg": false, "moving_control_required_flg": true, "shipment_control_required_flg": false, "manufacturing_application_required_flg": true}'::jsonb, '2026-01-24 22:30:05.658', '2026-01-24 22:30:05.658');
INSERT INTO public.registry_def
(def_id, kind, def_key, "scope", owner_id, is_active, spec, created_at, updated_at)
VALUES('8bf416ba-56ac-4c6f-ad22-67ff73e8209e'::uuid, 'material_class', 'starch', 'system', NULL, true, '{"name": "starch", "label": "でん粉", "category": "原材料", "description": "例：コーンスターチ、ポテトスターチ、タピオカスターチ", "alcohol_tax_required_flg": false, "moving_control_required_flg": true, "shipment_control_required_flg": false, "manufacturing_application_required_flg": true}'::jsonb, '2026-01-24 22:30:05.658', '2026-01-24 22:30:05.658');
INSERT INTO public.registry_def
(def_id, kind, def_key, "scope", owner_id, is_active, spec, created_at, updated_at)
VALUES('b9fa9e01-8991-4348-aad3-5ab41408c597'::uuid, 'material_class', 'hop', 'system', NULL, true, '{"name": "hop", "label": "ホップ", "category": "原材料", "description": "例：Citra、Cascade、Saaz（ペレット/ホール）", "alcohol_tax_required_flg": false, "moving_control_required_flg": true, "shipment_control_required_flg": false, "manufacturing_application_required_flg": true}'::jsonb, '2026-01-24 22:30:05.658', '2026-01-24 22:30:05.658');
INSERT INTO public.registry_def
(def_id, kind, def_key, "scope", owner_id, is_active, spec, created_at, updated_at)
VALUES('6e9f0dfa-bb3a-4a78-a412-b0dc620ff5da'::uuid, 'material_class', 'water', 'system', NULL, true, '{"name": "water", "label": "水", "category": "原材料", "description": "例：仕込み水（RO水/軟水/硬水調整水）", "alcohol_tax_required_flg": false, "moving_control_required_flg": true, "shipment_control_required_flg": false, "manufacturing_application_required_flg": true}'::jsonb, '2026-01-24 22:30:05.658', '2026-01-24 22:30:05.658');
INSERT INTO public.registry_def
(def_id, kind, def_key, "scope", owner_id, is_active, spec, created_at, updated_at)
VALUES('36e10634-a1d8-4a37-be24-b5937bcfea1b'::uuid, 'material_class', 'yeast', 'system', NULL, true, '{"name": "yeast", "label": "酵母", "category": "原材料", "description": "例：US-05、S-04、W-34/70、ベルジャン酵母", "alcohol_tax_required_flg": false, "moving_control_required_flg": true, "shipment_control_required_flg": false, "manufacturing_application_required_flg": true}'::jsonb, '2026-01-24 22:30:05.658', '2026-01-24 22:30:05.658');
INSERT INTO public.registry_def
(def_id, kind, def_key, "scope", owner_id, is_active, spec, created_at, updated_at)
VALUES('d0511d7f-b3d4-4482-904e-dc84f23bd32c'::uuid, 'material_class', 'other_raw_material', 'system', NULL, true, '{"name": "other_raw_material", "label": "その他原料", "category": "原材料", "description": "例：糖類（デキストロース/乳糖）、果実（マンゴー/ベリー）、香辛料（コリアンダー）、ハーブ、コーヒー、カカオ、酵素、清澄剤", "alcohol_tax_required_flg": false, "moving_control_required_flg": true, "shipment_control_required_flg": false, "manufacturing_application_required_flg": true}'::jsonb, '2026-01-24 22:30:05.658', '2026-01-24 22:30:05.658');
INSERT INTO public.registry_def
(def_id, kind, def_key, "scope", owner_id, is_active, spec, created_at, updated_at)
VALUES('bb22d723-24c9-4323-a5d3-bca9898a611b'::uuid, 'material_class', 'spent_grain', 'system', NULL, true, '{"name": "spent_grain", "label": "麦芽粕", "category": "副産物", "description": "例：糖化後の麦芽粕（飼料・堆肥等に利用）", "alcohol_tax_required_flg": false, "moving_control_required_flg": false, "shipment_control_required_flg": false, "manufacturing_application_required_flg": false}'::jsonb, '2026-01-24 22:30:05.658', '2026-01-24 22:30:05.658');
INSERT INTO public.registry_def
(def_id, kind, def_key, "scope", owner_id, is_active, spec, created_at, updated_at)
VALUES('a26062c5-faf5-4978-9d35-301593cd377d'::uuid, 'material_class', 'spent_hop', 'system', NULL, true, '{"name": "spent_hop", "label": "ホップかす", "category": "副産物", "description": "例：煮沸/ワールプール後のホップ残渣", "alcohol_tax_required_flg": false, "moving_control_required_flg": false, "shipment_control_required_flg": false, "manufacturing_application_required_flg": false}'::jsonb, '2026-01-24 22:30:05.658', '2026-01-24 22:30:05.658');
INSERT INTO public.registry_def
(def_id, kind, def_key, "scope", owner_id, is_active, spec, created_at, updated_at)
VALUES('5cfa11aa-8e2d-4151-b7e9-81e6fbedd83c'::uuid, 'material_class', 'spent_yeast', 'system', NULL, true, '{"name": "spent_yeast", "label": "使用済み酵母", "category": "副産物", "description": "例：回収酵母（再利用/廃棄）", "alcohol_tax_required_flg": false, "moving_control_required_flg": false, "shipment_control_required_flg": false, "manufacturing_application_required_flg": false}'::jsonb, '2026-01-24 22:30:05.658', '2026-01-24 22:30:05.658');
INSERT INTO public.registry_def
(def_id, kind, def_key, "scope", owner_id, is_active, spec, created_at, updated_at)
VALUES('504e731c-163e-429a-897b-ea0f5072e8f2'::uuid, 'material_class', 'trub', 'system', NULL, true, '{"name": "trub", "label": "トルーブ", "category": "副産物", "description": "例：トルーブ（タンパク質沈殿物＋ホップ滓）", "alcohol_tax_required_flg": false, "moving_control_required_flg": false, "shipment_control_required_flg": false, "manufacturing_application_required_flg": false}'::jsonb, '2026-01-24 22:30:05.658', '2026-01-24 22:30:05.658');
INSERT INTO public.registry_def
(def_id, kind, def_key, "scope", owner_id, is_active, spec, created_at, updated_at)
VALUES('e0236f8b-33c1-40b0-a752-769fe8b38b0c'::uuid, 'material_class', 'beer', 'system', NULL, true, '{"name": "beer", "label": "ビール", "category": "最終生産物", "description": "例：瓶・缶・樽の最終製品（IPA、ピルスナー等）", "alcohol_tax_required_flg": true, "moving_control_required_flg": true, "shipment_control_required_flg": true, "manufacturing_application_required_flg": false}'::jsonb, '2026-01-24 22:30:05.658', '2026-01-24 22:30:05.658');