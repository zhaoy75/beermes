INSERT INTO registry_def (kind, def_key, scope, owner_id, spec)
VALUES (
  'kpi_definition',
  'beer_production_kpi',
  'system',
  NULL,
  '{
    "kpi_meta": [
      {
        "id": "tax_category_code",
        "name": "製品種類",
        "uom": "",
        "datasource": "registry_def",
		"search_key_flg": true
      },
      {
        "id": "volume",
        "name": "生産量",
        "uom": "L"
      },
      {
        "id": "abv",
        "name": "ABV",
        "uom": ""
      },
      {
        "id": "og",
        "name": "OG",
        "uom": ""
      },
      {
        "id": "fg",
        "name": "FG",
        "uom": ""
      },
      {
        "id": "srm",
        "name": "SRM",
        "uom": ""
      },
      {
        "id": "ibu",
        "name": "IBU",
        "uom": ""
      }
    ]
  }'::jsonb
);