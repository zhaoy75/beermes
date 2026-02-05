INSERT INTO registry_def (kind, def_key, scope, owner_id, spec)
VALUES
-- 製造場
('site_type', 'brewery', 'system', NULL, '{
  "name": "製造場",
  "inventory_count_flg": true
}'),

-- 蔵置場
('site_type', 'brewery_storage', 'system', NULL, '{
  "name": "蔵置場",
  "inventory_count_flg": true
}'),

-- 蔵置所
('site_type', 'tax_storage', 'system', NULL, '{
  "name": "蔵置所",
  "inventory_count_flg": true
}'),

-- 保税地域
('site_type', 'bonded_area', 'system', NULL, '{
  "name": "保税地域",
  "inventory_count_flg": false
}'),

-- 国内の得意先
('site_type', 'domestic_customer', 'system', NULL, '{
  "name": "国内の得意先",
  "inventory_count_flg": false
}'),

-- 海外の得意先/輸出業者
('site_type', 'oversea_customer', 'system', NULL, '{
  "name": "海外の得意先/輸出業者",
  "inventory_count_flg": false
}'),


-- 他の酒類製造者の製造場
('site_type', 'other_brewery', 'system', NULL, '{
  "name": "他の酒類製造者の製造場",
  "inventory_count_flg": false
}'),


-- 廃棄
('site_type', 'disposal_facility', 'system', NULL, '{
  "name": "廃棄",
  "inventory_count_flg": false
}'),

-- 直売所
('site_type', 'direct_sales_shop', 'system', NULL, '{
  "name": "直売所",
  "inventory_count_flg": true
}'),

-- 仕入先
('site_type', 'supplier', 'system', NULL, '{
  "name": "仕入先",
  "inventory_count_flg": false
}');