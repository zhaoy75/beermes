insert into public.mst_site_types (code, name, flags)
values
  ('brewery',    'Brewery Plant',   '{"ja":"醸造所"}'),
  ('warehouse',  'Warehouse',       '{"ja":"倉庫"}'),
  ('supplier',   'Supplier',        '{"ja":"仕入先"}'),
  ('customer',   'Customer',        '{"ja":"顧客"}'),
  ('recycler',   'Waste Recycler',  '{"ja":"廃棄物処理業者"}'),
  ('tax_authority','Tax Authority', '{"ja":"税務当局"}')
on conflict (tenant_id, code) do nothing;