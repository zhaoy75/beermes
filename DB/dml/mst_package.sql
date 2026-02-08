-- Example DML for craft-beer packaging master
INSERT INTO mst_package (
  package_code,
  name,
  text,
  unit_volume,
  volume_uom
) VALUES
  ('CAN_355', '355ml Can', 'Standard 12oz aluminum can for core beers', 355, 'mL'),
  ('CAN_473', '473ml Can', '16oz tallboy can for seasonal releases', 473, 'mL'),
  ('BOTTLE_330', '330ml Bottle', '330ml glass bottle for export/retail', 330, 'mL'),
  ('BOTTLE_500', '500ml Bottle', '500ml glass bottle for specialty ales', 500, 'mL'),
  ('KEG_20L', '20L Keg', '20L stainless keg for draft service', 20, 'L'),
  ('KEG_30L', '30L Keg', '30L stainless keg for draft service', 30, 'L'),
  ('KEG_50L', '50L Keg', '50L stainless keg for high-volume accounts', 50, 'L');
