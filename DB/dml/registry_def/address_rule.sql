-- System-wide Japanese address definition
INSERT INTO registry_def (kind, def_key, scope, owner_id, spec)
VALUES (
  'address_rule',
  'jp_default',
  'system',
  NULL,
  '{
    "name": "日本住所",
    "name_i18n": { "ja": "日本住所", "en": "Japan Address" },
    "country": "JP",
    "fields": [
      { "key": "postal_code", "label": "郵便番号", "label_i18n": { "ja": "郵便番号", "en": "Postal Code" }, "type": "string", "required": true },
      { "key": "prefecture", "label": "都道府県", "label_i18n": { "ja": "都道府県", "en": "Prefecture" }, "type": "string", "required": true },
      { "key": "city", "label": "市区町村", "label_i18n": { "ja": "市区町村", "en": "City" }, "type": "string", "required": true },
      { "key": "ward", "label": "区", "label_i18n": { "ja": "区", "en": "Ward" }, "type": "string", "required": false },
      { "key": "address1", "label": "町名・番地", "label_i18n": { "ja": "町名・番地", "en": "Street" }, "type": "string", "required": true },
      { "key": "address2", "label": "建物名・部屋番号", "label_i18n": { "ja": "建物名・部屋番号", "en": "Building / Room" }, "type": "string", "required": false }
    ],
    "format": {
      "ja": "{postal_code} {prefecture}{city}{ward}{address1}{address2}",
      "en": "{address1} {address2}, {city}, {prefecture} {postal_code}, JP"
    }
  }'::jsonb
);
