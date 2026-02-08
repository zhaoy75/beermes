-- Example DML for craft-beer packaging master
INSERT INTO mst_package (
  package_code,
  tenant_id,
  name_i18n,
  description,
  unit_volume,
  volume_uom
) VALUES
  ('CAN_355', '2a231822-aa8d-452a-aa5f-9f5e4293cdaa', '{\"en\":\"355ml Can\",\"ja\":\"355ml 缶\"}', 'Standard 12oz aluminum can for core beers', 355, '5d449c18-f973-44ee-a501-48b7bfcd4e0c'),
  ('CAN_473', '2a231822-aa8d-452a-aa5f-9f5e4293cdaa', '{\"en\":\"473ml Can\",\"ja\":\"473ml 缶\"}', '16oz tallboy can for seasonal releases', 473, '5d449c18-f973-44ee-a501-48b7bfcd4e0c'),
  ('BOTTLE_330', '2a231822-aa8d-452a-aa5f-9f5e4293cdaa', '{\"en\":\"330ml Bottle\",\"ja\":\"330ml ボトル\"}', '330ml glass bottle for export/retail', 330, '5d449c18-f973-44ee-a501-48b7bfcd4e0c'),
  ('BOTTLE_500', '2a231822-aa8d-452a-aa5f-9f5e4293cdaa', '{\"en\":\"500ml Bottle\",\"ja\":\"500ml ボトル\"}', '500ml glass bottle for specialty ales', 500, '5d449c18-f973-44ee-a501-48b7bfcd4e0c'),
  ('KEG_20L', '2a231822-aa8d-452a-aa5f-9f5e4293cdaa', '{\"en\":\"20L Keg\",\"ja\":\"20L ケグ\"}', '20L stainless keg for draft service', 20, '0b038b0e-d1d8-464b-8511-a7706e2b2b65'),
  ('KEG_30L', '2a231822-aa8d-452a-aa5f-9f5e4293cdaa', '{\"en\":\"30L Keg\",\"ja\":\"30L ケグ\"}', '30L stainless keg for draft service', 30, '0b038b0e-d1d8-464b-8511-a7706e2b2b65'),
  ('KEG_50L', '2a231822-aa8d-452a-aa5f-9f5e4293cdaa', '{\"en\":\"50L Keg\",\"ja\":\"50L ケグ\"}', '50L stainless keg for high-volume accounts', 50, '0b038b0e-d1d8-464b-8511-a7706e2b2b65');
