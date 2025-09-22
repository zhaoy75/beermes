-- Seed common brewing materials. Assumes mst_materials.tenant_id is filled automatically.
-- Requires referenced UOMs to exist (see mst_uom_seed.sql).

with ingredient_data as (
  select *
  from (values
    -- Malts
    ('malt',    '2ROW',      'US 2-Row Pale Malt',        'kg',  true),
    ('malt',    'PILS',      'Pilsner Malt',              'kg',  true),
    ('malt',    'MUNICH10',  'Munich Malt 10L',           'kg',  true),
    ('malt',    'CARAMEL60', 'Crystal/Caramel 60L',       'kg',  true),
    ('malt',    'CHOC',      'Chocolate Malt',            'kg',  true),
    ('malt',    'WHEAT',     'Wheat Malt',                'kg',  true),

    -- Hops
    ('hop',     'CITRA',     'Citra Pellet Hops',         'g',   true),
    ('hop',     'MOSAIC',    'Mosaic Pellet Hops',        'g',   true),
    ('hop',     'AMAR',      'Amarillo Pellet Hops',      'g',   true),
    ('hop',     'CENT',      'Centennial Pellet Hops',    'g',   true),
    ('hop',     'SAAZ',      'Saaz Pellet Hops',          'g',   true),

    -- Yeasts
    ('yeast',   'US05',      'Ale Yeast US-05',           'ea',  true),
    ('yeast',   'WLP001',    'Ale Yeast WLP001',          'ea',  true),
    ('yeast',   'LAGER34',   'Lager Yeast 34/70',         'ea',  true),

    -- Adjuncts / Additions
    ('adjunct', 'DEXTROSE',  'Dextrose (Corn Sugar)',     'kg',  true),
    ('adjunct', 'OATS',      'Flaked Oats',               'kg',  true),
    ('adjunct', 'HONEY',     'Wildflower Honey',          'kg',  true),

    -- Water treatments / chemicals
    ('chemical','GYPSUM',    'Gypsum (Calcium Sulfate)',  'g',   true),
    ('chemical','CACL2',     'Calcium Chloride',          'g',   true),
    ('chemical','PHOSPHOR',  'Phosphoric Acid 10%',       'mL',  true),

    -- Cleaning / sanitation
    ('cleaning','PBW',       'PBW Cleaner',               'kg',  true),
    ('cleaning','STAR',      'Star San Sanitizer',        'L',   true),

    -- Packaging
    ('packaging','CAN355',   '355ml Aluminum Can',        'ea',  true),
    ('packaging','CAP26',    '26mm Crown Cap',            'ea',  true),
    ('packaging','KEG_HALF', 'Half Barrel Stainless Keg', 'ea',  true),

    -- Water reference
    ('water',   'BREWWATER', 'Brewing Water',             'L',   true)
  ) as t(category, code, name, uom_code, active)
)
insert into mst_materials (category, code, name, uom_id, active)
select
  d.category::mst_material_category,
  d.code,
  d.name,
  u.id,
  d.active
from ingredient_data d
join mst_uom u on u.code = d.uom_code
on conflict do nothing;
