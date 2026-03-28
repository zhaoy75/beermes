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

CREATE OR REPLACE VIEW v_alcohol_type_options AS
WITH ranked_alcohol_type AS (
  SELECT
    rd.def_id,
    rd.def_key,
    rd.scope,
    rd.owner_id,
    rd.spec,
    NULLIF(BTRIM(rd.spec ->> 'tax_category_code'), '') AS tax_category_code,
    COALESCE(NULLIF(BTRIM(rd.spec ->> 'name'), ''), rd.def_key) AS label,
    ROW_NUMBER() OVER (
      PARTITION BY NULLIF(BTRIM(rd.spec ->> 'tax_category_code'), '')
      ORDER BY
        CASE
          WHEN rd.scope = 'tenant' AND rd.owner_id = app_current_tenant_id() THEN 0
          WHEN rd.scope = 'system' THEN 1
          ELSE 2
        END,
        rd.updated_at DESC,
        rd.created_at DESC,
        rd.def_id DESC
    ) AS row_priority
  FROM registry_def rd
  WHERE rd.kind = 'alcohol_type'
    AND rd.is_active = true
    AND (
      rd.scope = 'system'
      OR (rd.scope = 'tenant' AND rd.owner_id = app_current_tenant_id())
    )
    AND NULLIF(BTRIM(rd.spec ->> 'tax_category_code'), '') IS NOT NULL
)
SELECT
  tax_category_code AS key,
  tax_category_code AS value,
  label,
  def_id,
  def_key,
  scope,
  owner_id,
  spec
FROM ranked_alcohol_type
WHERE row_priority = 1;

