INSERT INTO registry_def (kind, def_key, scope, owner_id, spec)
VALUES

-- ビール
('alcohol_tax', 'beer_2023_2026', 'system', NULL, '{
  "name": "ビール",
  "tax_category_code": 350,
  "tax_rate": 63.35,
  "start_date": "2023-10-01",
  "expiration_date": "2026-09-30"
}'),

('alcohol_tax', 'beer_2026_onward', 'system', NULL, '{
  "name": "ビール",
  "tax_category_code": 350,
  "tax_rate": 54.25,
  "start_date": "2026-10-01",
  "expiration_date": null
}'),

-- 発泡酒（ビールと同様な税率）
('alcohol_tax', 'happoshu_same_as_beer_2023_2026', 'system', NULL, '{
  "name": "発泡酒(ビールと同様な税率)",
  "tax_category_code": 581,
  "tax_rate": 63.35,
  "start_date": "2023-10-01",
  "expiration_date": "2026-09-30"
}'),

('alcohol_tax', 'happoshu_same_as_beer_2026_onward', 'system', NULL, '{
  "name": "発泡酒(ビールと同様な税率)",
  "tax_category_code": 581,
  "tax_rate": 54.25,
  "start_date": "2026-10-01",
  "expiration_date": null
}'),

-- 発泡酒（麦芽比率25%以上50%未満、アルコール10度未満）
('alcohol_tax', 'happoshu_25_50_under10_2023_2026', 'system', NULL, '{
  "name": "発泡酒_麦芽比率25%以上50％未満（アルコール分10度未満）",
  "tax_category_code": 582,
  "tax_rate": 46.99,
  "start_date": "2023-10-01",
  "expiration_date": "2026-09-30"
}'),

('alcohol_tax', 'happoshu_25_50_under10_2026_onward', 'system', NULL, '{
  "name": "発泡酒_麦芽比率25%以上50％未満（アルコール分10度未満）",
  "tax_category_code": 582,
  "tax_rate": 54.25,
  "start_date": "2026-10-01",
  "expiration_date": null
}'),

-- 発泡酒（麦芽比率25%未満）＆新ジャンル
('alcohol_tax', 'happoshu_under25_newgenre_2023_2026', 'system', NULL, '{
  "name": "発泡酒_麦芽比率25%未満（アルコール分10度未満）&新ジャンル",
  "tax_category_code": 583,
  "tax_rate": 46.99,
  "start_date": "2023-10-01",
  "expiration_date": "2026-09-30"
}'),

('alcohol_tax', 'happoshu_under25_newgenre_2026_onward', 'system', NULL, '{
  "name": "発泡酒_麦芽比率25%未満（アルコール分10度未満）&新ジャンル",
  "tax_category_code": 583,
  "tax_rate": 54.25,
  "start_date": "2026-10-01",
  "expiration_date": null
}');
