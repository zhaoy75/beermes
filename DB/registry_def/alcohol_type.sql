INSERT INTO registry_def (kind, def_key, scope, owner_id, spec)
VALUES
(
  'alcohol_type',
  'beer',
  'system',
  NULL,
  '{
    "name": "ビール" ,
    "tax_category_code": 350,
    "description": "ビール",
    "malt_ratio": ">=50%",
    "max_abv": null
  }'
),
(
  'alcohol_type',
  'happoshu_beer_rate',
  'system',
  NULL,
  '{
    "name": "発泡酒(ビールと同様な税率)" ,
    "tax_category_code": 581,
    "description": "ビールと同様の税率が適用される発泡酒",
    "malt_ratio": ">=50%",
    "max_abv": null
  }'
),
(
  'alcohol_type',
  'happoshu_25_50_under10',
  'system',
  NULL,
  '{
    "name": "発泡酒_麦芽比率25%以上50％未満（アルコール分10度未満）",
    "tax_category_code": 582,
    "description": "麦芽比率25%以上50%未満、アルコール分10度未満",
    "malt_ratio": "25%-50%",
    "max_abv": 10
  }'
),
(
  'alcohol_type',
  'happoshu_under25_newgenre',
  'system',
  NULL,
  '{
    "name": "発泡酒_麦芽比率25%未満（アルコール分10度未満）&新ジャンル",
    "tax_category_code": 583,
    "description": "麦芽比率25%未満（アルコール分10度未満）および新ジャンル",
    "malt_ratio": "<25%",
    "max_abv": 10
  }'
);

CREATE OR REPLACE VIEW v_batch_with_alcohol_type AS
SELECT
  b.*,
  at.label AS alcohol_type_label
FROM batch b
LEFT JOIN v_alcohol_type_options at
  ON at.value = b.alcohol_type_key;