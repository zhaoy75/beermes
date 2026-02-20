INSERT INTO registry_def (kind, def_key, scope, owner_id, spec)
VALUES
-- 製造場
('site_type', 'BREWERY_MANUFACTUR', 'system', NULL, '{
  "name": "製造場",
  "inventory_count_flg": true
}'),

-- 蔵置場
('site_type', 'BREWERY_STORAGE', 'system', NULL, '{
  "name": "蔵置場",
  "inventory_count_flg": true
}'),

-- 蔵置所
('site_type', 'TAX_STORAGE', 'system', NULL, '{
  "name": "蔵置所",
  "inventory_count_flg": true
}'),

-- 保税地域
('site_type', 'BONDED_AREA', 'system', NULL, '{
  "name": "保税地域",
  "inventory_count_flg": false
}'),

-- 国内の得意先
('site_type', 'DOMESTIC_CUSTOMER', 'system', NULL, '{
  "name": "国内の得意先",
  "inventory_count_flg": false
}'),

-- 海外の得意先/輸出業者
('site_type', 'OVERSEA_CUSTOMER', 'system', NULL, '{
  "name": "海外の得意先/輸出業者",
  "inventory_count_flg": false
}'),


-- 他の酒類製造者の製造場
('site_type', 'OTHER_BREWERY', 'system', NULL, '{
  "name": "他の酒類製造者の製造場",
  "inventory_count_flg": false
}'),


-- 廃棄
('site_type', 'DISPOSAL_FACILITY', 'system', NULL, '{
  "name": "廃棄",
  "inventory_count_flg": false
}'),

-- 直売所
('site_type', 'DIRECT_SALES_SHOP', 'system', NULL, '{
  "name": "直売所",
  "inventory_count_flg": true
}'),

-- 仕入先
('site_type', 'SUPPLIER', 'system', NULL, '{
  "name": "仕入先",
  "inventory_count_flg": false
}');