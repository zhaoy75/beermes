-- Attribute definitions and set for Batch: Beer Category + Target ABV
-- Scope: system, Industry: 00000000-0000-0000-0000-000000000000
-- References registry_def kind = 'alcohol_type'

-- Constants
-- industry_id = 00000000-0000-0000-0000-000000000000

-- 1) attr_def
insert into attr_def (
  tenant_id,
  domain,
  scope,
  owner_id,
  industry_id,
  code,
  name,
  name_i18n,
  data_type,
  uom_id,
  ref_kind,
  ref_domain,
  required,
  description,
  sort_order
)
values
  (
    '00000000-0000-0000-0000-000000000000',
    'batch',
    'system',
    null,
    '00000000-0000-0000-0000-000000000000',
    'beer_category',
    'Beer Category',
    '{"ja":"ビール分類","en":"Beer Category"}',
    'ref',
    null,
    'registry_def',
    'alcohol_type',
    true,
    'Beer category reference (registry_def: alcohol_type)',
    10
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'batch',
    'system',
    null,
    '00000000-0000-0000-0000-000000000000',
    'target_abv',
    'Target ABV',
    '{"ja":"目標ABV","en":"Target ABV"}',
    'number',
    (select id from mst_uom where tenant_id = '00000000-0000-0000-0000-000000000000' and code = '%' limit 1),
    null,
    null,
    true,
    'Target alcohol by volume (%)',
    20
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'batch',
    'system',
    null,
    '00000000-0000-0000-0000-000000000000',
    'liquid_name',
    'Liquid Name',
    '{"ja":"液種名","en":"Liquid Name"}',
    'string',
    null,
    null,
    null,
    false,
    'Liquid name for the batch',
    30
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'batch',
    'system',
    null,
    '00000000-0000-0000-0000-000000000000',
    'style_name',
    'Style Name',
    '{"ja":"スタイル名","en":"Style Name"}',
    'string',
    null,
    null,
    null,
    false,
    'Style name for the batch',
    40
  ),
  (
    '00000000-0000-0000-0000-000000000000',
    'batch',
    'system',
    null,
    '00000000-0000-0000-0000-000000000000',
    'customer_name',
    'Customer Name',
    '{"ja":"顧客名","en":"Customer Name"}',
    'string',
    null,
    null,
    null,
    false,
    'Customer name for the batch',
    50
  )
on conflict do nothing;

-- 2) attr_set
insert into attr_set (
  tenant_id,
  domain,
  scope,
  owner_id,
  industry_id,
  code,
  name,
  name_i18n,
  description,
  sort_order
)
values (
  '00000000-0000-0000-0000-000000000000',
  'batch',
  'system',
  null,
  '00000000-0000-0000-0000-000000000000',
  'batch_alcohol',
  'Batch Alcohol',
  '{"ja":"バッチの酒類情報","en":"Batch Alcohol"}',
  'Beer category and target ABV for batch',
  10
)
on conflict do nothing;

-- 3) attr_set_rule
insert into attr_set_rule (
  tenant_id,
  attr_set_id,
  attr_id,
  required,
  ui_section,
  ui_widget,
  sort_order
)
select
  '00000000-0000-0000-0000-000000000000',
  s.attr_set_id,
  d.attr_id,
  case d.code
    when 'beer_category' then true
    when 'target_abv' then true
    else false
  end,
  'Tax',
  case d.code
    when 'beer_category' then 'select'
    when 'target_abv' then 'number'
    when 'liquid_name' then 'text'
    when 'style_name' then 'text'
    when 'customer_name' then 'text'
    else null
  end,
  case d.code
    when 'beer_category' then 10
    when 'target_abv' then 20
    when 'liquid_name' then 30
    when 'style_name' then 40
    when 'customer_name' then 50
    else 0
  end
from attr_set s
join attr_def d
  on d.tenant_id = s.tenant_id
 and d.domain = s.domain
 and d.industry_id is not distinct from s.industry_id
where s.tenant_id = '00000000-0000-0000-0000-000000000000'
  and s.domain = 'batch'
  and s.code = 'batch_alcohol'
  and d.code in ('beer_category', 'target_abv', 'liquid_name', 'style_name', 'customer_name')
on conflict do nothing;

-- 4) entity_attr_set / entity_attr
-- Only for new batches: do not backfill existing data here.
-- Use these templates when creating a batch (replace :batch_id and :tenant_id).

-- insert into entity_attr_set (
--   tenant_id, entity_type, entity_id, attr_set_id, is_active
-- )
-- select
--   :tenant_id,
--   'batch',
--   :batch_id,
--   s.attr_set_id,
--   true
-- from attr_set s
-- where s.tenant_id = :tenant_id
--   and s.domain = 'batch'
--   and s.code = 'batch_alcohol';

-- insert into entity_attr (
--   tenant_id, entity_type, entity_id_uuid, attr_id, value_ref_type_id
-- )
-- select
--   :tenant_id,
--   'batch',
--   :batch_id,
--   d.attr_id,
--   :alcohol_type_def_id
-- from attr_def d
-- where d.tenant_id = :tenant_id
--   and d.domain = 'batch'
--   and d.code = 'beer_category';

-- insert into entity_attr (
--   tenant_id, entity_type, entity_id_uuid, attr_id, value_num, uom_id
-- )
-- select
--   :tenant_id,
--   'batch',
--   :batch_id,
--   d.attr_id,
--   :target_abv,
--   (select id from mst_uom where tenant_id = :tenant_id and code = '%' limit 1)
-- from attr_def d
-- where d.tenant_id = :tenant_id
--   and d.domain = 'batch'
--   and d.code = 'target_abv';
