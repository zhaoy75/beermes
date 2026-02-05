INSERT INTO industry (
  industry_id,
  code,
  name,
  name_i18n,
  description,
  sort_order,
  meta
)
VALUES (
  '00000000-0000-0000-0000-000000000000',
  'CRAFT_BEER',
  'Craft Beer',
  '{"ja":"クラフトビール","en":"Craft Beer"}',
  'Beer manufacturing under Japanese liquor tax law',
  10,
  '{"country":"JP","regulated":true}'
)
ON CONFLICT (code)
DO UPDATE SET
  name        = EXCLUDED.name,
  name_i18n   = EXCLUDED.name_i18n,
  description= EXCLUDED.description,
  meta        = EXCLUDED.meta,
  updated_at = now();