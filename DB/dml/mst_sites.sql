WITH a_company AS (
  INSERT INTO public.mst_sites (
    tenant_id, name, site_type_id, parent_site_id, address, contact, notes, active
  )
  VALUES (
    '2a231822-aa8d-452a-aa5f-9f5e4293cdaa',
    'A社 本社・製造場',
    (SELECT def_id FROM registry_def
      WHERE kind = 'site_type' AND def_key = 'brewery' AND scope = 'system'
      LIMIT 1),
    NULL,
    '{
      "postal_code": "150-0001",
      "prefecture": "東京都",
      "city": "渋谷区",
      "ward": "",
      "address1": "神宮前1-1-1",
      "address2": ""
    }'::jsonb,
    '{"name":"製造場","phone":"03-1111-1111","email":"brewery@acompany.example"}'::jsonb,
    'A社の主製造拠点',
    true
  )
  RETURNING id
),
external_company AS (
  INSERT INTO public.mst_sites (
    tenant_id, name, site_type_id, parent_site_id, address, contact, notes, active
  )
  VALUES (
    '2a231822-aa8d-452a-aa5f-9f5e4293cdaa',
    '外部会社',
    (SELECT def_id FROM registry_def
      WHERE kind = 'site_type' AND def_key = 'other_brewery' AND scope = 'system'
      LIMIT 1),
    NULL,
    '{
      "postal_code": "530-0001",
      "prefecture": "大阪府",
      "city": "大阪市北区",
      "ward": "",
      "address1": "梅田2-2-2",
      "address2": ""
    }'::jsonb,
    '{"name":"外部会社 本社","phone":"06-2000-0000","email":"contact@external.example"}'::jsonb,
    '外部会社の親ノード',
    true
  )
  RETURNING id
)
INSERT INTO public.mst_sites (
  tenant_id, name, site_type_id, parent_site_id, address, contact, notes, active
)
SELECT
  '2a231822-aa8d-452a-aa5f-9f5e4293cdaa',
  s.name,
  r.def_id,
  s.parent_id,
  s.address,
  s.contact,
  s.notes,
  true
FROM (
  VALUES
    -- A社 配下
    ('A社 蔵置場', 'brewery_storage',
     (SELECT id FROM a_company),
     '{
        "postal_code": "210-0005",
        "prefecture": "神奈川県",
        "city": "川崎市川崎区",
        "ward": "",
        "address1": "東田町2-2-2",
        "address2": ""
      }'::jsonb,
     '{"name":"蔵置場","phone":"044-111-2222","email":"storage@acompany.example"}'::jsonb,
     '蔵置場'),

    ('A社 蔵置所', 'tax_storage',
     (SELECT id FROM a_company),
     '{
        "postal_code": "060-0005",
        "prefecture": "北海道",
        "city": "札幌市中央区",
        "ward": "",
        "address1": "北5条西2-2-2",
        "address2": ""
      }'::jsonb,
     '{"name":"蔵置所","phone":"011-111-2222","email":"tax@acompany.example"}'::jsonb,
     '蔵置所'),

    ('A社 直売所', 'direct_sales_shop',
     (SELECT id FROM a_company),
     '{
        "postal_code": "604-8006",
        "prefecture": "京都府",
        "city": "京都市中京区",
        "ward": "",
        "address1": "河原町8-8-8",
        "address2": ""
      }'::jsonb,
     '{"name":"直売所","phone":"075-111-2222","email":"shop@acompany.example"}'::jsonb,
     '直売所'),

    -- 外部会社 配下
    ('外部会社 仕入先', 'supplier',
     (SELECT id FROM external_company),
     '{
        "postal_code": "810-0001",
        "prefecture": "福岡県",
        "city": "福岡市中央区",
        "ward": "",
        "address1": "天神9-9-9",
        "address2": ""
      }'::jsonb,
     '{"name":"仕入先","phone":"092-111-2222","email":"supplier@external.example"}'::jsonb,
     '仕入先'),

    ('外部会社 国内得意先','domestic_customer',
     (SELECT id FROM external_company),
     '{
        "postal_code": "460-0008",
        "prefecture": "愛知県",
        "city": "名古屋市中区",
        "ward": "",
        "address1": "栄5-5-5",
        "address2": ""
      }'::jsonb,
     '{"name":"国内得意先","phone":"052-111-2222","email":"customer@external.example"}'::jsonb,
     '国内得意先')
) AS s(name, site_type_key, parent_id, address, contact, notes)
JOIN registry_def r
  ON r.kind = 'site_type'
 AND r.def_key = s.site_type_key
 AND r.scope = 'system';
