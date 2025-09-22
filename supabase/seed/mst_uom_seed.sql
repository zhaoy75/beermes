-- Seed canonical units of measure frequently used in brewery operations.
-- Assumes mst_uom.tenant_id is filled automatically (e.g., via column default).

insert into mst_uom (code, name, base_factor, base_code)
values
  ('kg',       'Kilogram',                       1.0,         'kg'),
  ('g',        'Gram',                           0.001,       'kg'),
  ('mg',       'Milligram',                      0.000001,    'kg'),
  ('lb',       'Pound',                          0.45359237,  'kg'),
  ('oz',       'Ounce',                          0.02834952,  'kg'),

  ('L',        'Liter',                          1.0,         'L'),
  ('mL',       'Milliliter',                     0.001,       'L'),
  ('hL',       'Hectoliter',                     100.0,       'L'),
  ('gal_us',   'US Gallon',                      3.78541178,  'L'),
  ('qt_us',    'US Quart',                       0.94635295,  'L'),
  ('pt_us',    'US Pint',                        0.47317647,  'L'),
  ('floz_us',  'US Fluid Ounce',                 0.02957353,  'L'),
  ('bbl_us',   'US Beer Barrel (31 gal)',        117.347765,  'L'),
  ('keg_half', 'Half Barrel Keg (15.5 gal)',     58.673882,   'L'),
  ('keg_sixt', 'Sixtel Keg (5.16 gal)',          19.532328,   'L'),

  ('ea',       'Each',                           1.0,         'ea'),
  ('pack_4',   '4-Pack',                         4.0,         'ea'),
  ('pack_6',   '6-Pack',                         6.0,         'ea'),
  ('pack_12',  '12-Pack',                        12.0,        'ea'),
  ('case_24',  '24 Bottle/Can Case',             24.0,        'ea')
on conflict do nothing;
