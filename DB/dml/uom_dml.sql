-- UOM master seed (craft beer manufacturing)
-- Package-related UOMs intentionally omitted.
-- Assumes mst_uom.tenant_id is filled automatically (e.g., via column default).

insert into mst_uom (code, name, scope, industry_id, dimension, base_factor, base_code, is_base_unit, meta)
values
  -- Weight
  ('kg',      'Kilogram',                     'system', '00000000-0000-0000-0000-000000000000', 'weight',      1.0,        'kg',    true,  '{"label":{"en":"Kilogram","ja":"キログラム"}}'),
  ('g',       'Gram',                         'system', '00000000-0000-0000-0000-000000000000', 'weight',      0.001,      'kg',    false, '{"label":{"en":"Gram","ja":"グラム"}}'),
  ('mg',      'Milligram',                    'system', '00000000-0000-0000-0000-000000000000', 'weight',      0.000001,   'kg',    false, '{"label":{"en":"Milligram","ja":"ミリグラム"}}'),
  ('lb',      'Pound',                        'system', '00000000-0000-0000-0000-000000000000', 'weight',      0.45359237, 'kg',    false, '{"label":{"en":"Pound","ja":"ポンド"}}'),
  ('oz',      'Ounce',                        'system', '00000000-0000-0000-0000-000000000000', 'weight',      0.02834952, 'kg',    false, '{"label":{"en":"Ounce","ja":"オンス"}}'),

  -- Volume
  ('L',       'Liter',                        'system', '00000000-0000-0000-0000-000000000000', 'volume',      1.0,        'L',     true,  '{"label":{"en":"Liter","ja":"リットル"}}'),
  ('mL',      'Milliliter',                   'system', '00000000-0000-0000-0000-000000000000', 'volume',      0.001,      'L',     false, '{"label":{"en":"Milliliter","ja":"ミリリットル"}}'),
  ('hL',      'Hectoliter',                   'system', '00000000-0000-0000-0000-000000000000', 'volume',      100.0,      'L',     false, '{"label":{"en":"Hectoliter","ja":"ヘクトリットル"}}'),
  ('gal_us',  'US Gallon',                    'system', '00000000-0000-0000-0000-000000000000', 'volume',      3.78541178, 'L',     false, '{"label":{"en":"US Gallon","ja":"米ガロン"}}'),
  ('bbl_us',  'US Beer Barrel (31 gal)',      'system', '00000000-0000-0000-0000-000000000000', 'volume',      117.347765, 'L',     false, '{"label":{"en":"US Beer Barrel (31 gal)","ja":"米ビールバレル（31ガロン）"}}'),

  -- Temperature (affine conversions; no base_factor)
  ('C',       'Celsius',                      'system', '00000000-0000-0000-0000-000000000000', 'temperature', null,       null,   false, '{"label":{"en":"Celsius","ja":"セルシウス"}}'),
  ('F',       'Fahrenheit',                   'system', '00000000-0000-0000-0000-000000000000', 'temperature', null,       null,   false, '{"label":{"en":"Fahrenheit","ja":"華氏"}}'),

  -- Pressure
  ('kPa',     'Kilopascal',                   'system', '00000000-0000-0000-0000-000000000000', 'pressure',    1.0,        'kPa',  true,  '{"label":{"en":"Kilopascal","ja":"キロパスカル"}}'),
  ('bar',     'Bar',                          'system', '00000000-0000-0000-0000-000000000000', 'pressure',    100.0,      'kPa',  false, '{"label":{"en":"Bar","ja":"バール"}}'),
  ('psi',     'Pound per square inch',        'system', '00000000-0000-0000-0000-000000000000', 'pressure',    6.89475729, 'kPa',  false, '{"label":{"en":"Pound per square inch","ja":"ポンド毎平方インチ"}}'),

  -- Length
  ('m',       'Meter',                        'system', '00000000-0000-0000-0000-000000000000', 'length',      1.0,        'm',    true,  '{"label":{"en":"Meter","ja":"メートル"}}'),
  ('cm',      'Centimeter',                   'system', '00000000-0000-0000-0000-000000000000', 'length',      0.01,       'm',    false, '{"label":{"en":"Centimeter","ja":"センチメートル"}}'),
  ('mm',      'Millimeter',                   'system', '00000000-0000-0000-0000-000000000000', 'length',      0.001,      'm',    false, '{"label":{"en":"Millimeter","ja":"ミリメートル"}}'),
  ('in',      'Inch',                         'system', '00000000-0000-0000-0000-000000000000', 'length',      0.0254,     'm',    false, '{"label":{"en":"Inch","ja":"インチ"}}'),
  ('ft',      'Foot',                         'system', '00000000-0000-0000-0000-000000000000', 'length',      0.3048,     'm',    false, '{"label":{"en":"Foot","ja":"フィート"}}'),

  -- Time
  ('sec',     'Second',                       'system', '00000000-0000-0000-0000-000000000000', 'time',        1.0,        'sec',  true,  '{"label":{"en":"Second","ja":"秒"}}'),
  ('min',     'Minute',                       'system', '00000000-0000-0000-0000-000000000000', 'time',        60.0,       'sec',  false, '{"label":{"en":"Minute","ja":"分"}}'),
  ('hour',    'Hour',                         'system', '00000000-0000-0000-0000-000000000000', 'time',        3600.0,     'sec',  false, '{"label":{"en":"Hour","ja":"時間"}}'),
  ('day',     'Day',                          'system', '00000000-0000-0000-0000-000000000000', 'time',        86400.0,    'sec',  false, '{"label":{"en":"Day","ja":"日"}}'),

  -- Percentage
  ('%',       'Percent',                      'system', '00000000-0000-0000-0000-000000000000', 'percentage',  1.0,        '%',    true,  '{"label":{"en":"Percent","ja":"パーセント"}}'),
  ('ppm',     'Parts per million',            'system', '00000000-0000-0000-0000-000000000000', 'percentage',  0.0001,     '%',    false, '{"label":{"en":"Parts per million","ja":"百万分率"}}'),

  -- Density
  ('kg_m3',   'Kilogram per cubic meter',     'system', '00000000-0000-0000-0000-000000000000', 'density',     1.0,        'kg_m3', true,  '{"label":{"en":"Kilogram per cubic meter","ja":"立方メートル当たりキログラム"}}'),
  ('g_ml',    'Gram per milliliter',          'system', '00000000-0000-0000-0000-000000000000', 'density',     1000.0,     'kg_m3', false, '{"label":{"en":"Gram per milliliter","ja":"ミリリットル当たりグラム"}}')

on conflict do nothing;
