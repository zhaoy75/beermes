DELETE FROM registry_def WHERE kind = 'alcohol_tax' and scope = 'system' and owner_id IS NULL;

INSERT INTO registry_def (kind, def_key, scope, owner_id, spec)
VALUES

-- ビール
('alcohol_tax', 'beer_2023_2026', 'system', NULL, jsonb_build_object(
  'name', 'ビール',
  'tax_category_code', 350,
  'tax_rate', 181000,
  'start_date', '2023-10-01',
  'expiration_date', '2026-09-30'
)),

('alcohol_tax', 'beer_2026_onward', 'system', NULL, jsonb_build_object(
  'name', 'ビール',
  'tax_category_code', 350,
  'tax_rate', 155000,
  'start_date', '2026-10-01',
  'expiration_date', null
)),

-- 発泡酒（ビールと同様な税率）
('alcohol_tax', 'happoshu_same_as_beer_2023_2026', 'system', NULL, jsonb_build_object(
  'name', '発泡酒(1)',
  'tax_category_code', 581,
  'tax_rate', 181000,
  'start_date', '2023-10-01',
  'expiration_date', '2026-09-30'
)),

('alcohol_tax', 'happoshu_same_as_beer_2026_onward', 'system', NULL, jsonb_build_object(
  'name', '発泡酒(1)',
  'tax_category_code', 581,
  'tax_rate', 155000,
  'start_date', '2026-10-01',
  'expiration_date', null
)),

-- 発泡酒（麦芽比率25%以上50%未満、アルコール10度未満）
('alcohol_tax', 'happoshu_25_50_under10_2023_2026', 'system', NULL, jsonb_build_object(
  'name', '発泡酒(2)',
  'tax_category_code', 582,
  'tax_rate', 155000,
  'start_date', '2023-10-01',
  'expiration_date', '2026-09-30'
)),

('alcohol_tax', 'happoshu_25_50_under10_2026_onward', 'system', NULL, jsonb_build_object(
  'name', '発泡酒(2)',
  'tax_category_code', 582,
  'tax_rate', 155000,
  'start_date', '2026-10-01',
  'expiration_date', null
)),

-- 発泡酒（麦芽比率25%未満）＆新ジャンル
('alcohol_tax', 'happoshu_under25_newgenre_2023_2026', 'system', NULL, jsonb_build_object(
  'name', '発泡酒_麦芽比率25%未満（アルコール分10度未満）&新ジャンル',
  'tax_category_code', 583,
  'tax_rate', 134250,
  'start_date', '2023-10-01',
  'expiration_date', '2026-09-30'
)),

('alcohol_tax', 'happoshu_under25_newgenre_2026_onward', 'system', NULL, jsonb_build_object(
  'name', '発泡酒_麦芽比率25%未満（アルコール分10度未満）&新ジャンル',
  'tax_category_code', 583,
  'tax_rate', 155000,
  'start_date', '2026-10-01',
  'expiration_date', null
));
