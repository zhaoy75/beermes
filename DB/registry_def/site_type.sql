INSERT INTO registry_def (kind, def_key, scope, owner_id, spec)
VALUES
-- 醸造所
('site_type', 'brewery', 'system', NULL, '{
  "name": "醸造所",
  "inventory_count_flg": true
}'),

-- 顧客
('site_type', 'customer', 'system', NULL, '{
  "name": "顧客",
  "inventory_count_flg": false
}'),

-- 海外顧客
('site_type', 'overseas_customer', 'system', NULL, '{
  "name": "海外顧客",
  "inventory_count_flg": false
}'),

-- 廃棄物処理業者
('site_type', 'waste_disposal_vendor', 'system', NULL, '{
  "name": "廃棄物処理業者",
  "inventory_count_flg": false
}'),

-- 仕入先
('site_type', 'supplier', 'system', NULL, '{
  "name": "仕入先",
  "inventory_count_flg": false
}'),

-- 蔵置場
('site_type', 'bonded_storage_place', 'system', NULL, '{
  "name": "蔵置場",
  "inventory_count_flg": true
}'),

-- 蔵置所
('site_type', 'bonded_storage_location', 'system', NULL, '{
  "name": "蔵置所",
  "inventory_count_flg": true
}'),

-- 廃棄内部
('site_type', 'internal_disposal', 'system', NULL, '{
  "name": "廃棄内部",
  "inventory_count_flg": false
}'),

-- 直売所
('site_type', 'direct_sales_shop', 'system', NULL, '{
  "name": "直売所",
  "inventory_count_flg": true
}');