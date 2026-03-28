-- Add batch actual_abv attr_def and attr_set_rule for existing environments.
-- Safe to re-run: inserts are guarded by not exists checks.

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
select
  '00000000-0000-0000-0000-000000000000',
  'batch',
  'system',
  null,
  '00000000-0000-0000-0000-000000000000',
  'actual_abv',
  'Actual ABV',
  '{"ja":"実績ABV","en":"Actual ABV"}'::jsonb,
  'number',
  (
    select id
    from mst_uom
    where tenant_id = '00000000-0000-0000-0000-000000000000'
      and code = '%'
    limit 1
  ),
  null,
  null,
  false,
  'Actual alcohol by volume (%)',
  25
where not exists (
  select 1
  from attr_def
  where tenant_id = '00000000-0000-0000-0000-000000000000'
    and domain = 'batch'
    and scope = 'system'
    and owner_id is null
    and industry_id = '00000000-0000-0000-0000-000000000000'
    and code = 'actual_abv'
);

-- 2) attr_set description
update attr_set
set
  description = 'Beer category, target ABV, and actual ABV for batch',
  updated_at = now()
where tenant_id = '00000000-0000-0000-0000-000000000000'
  and domain = 'batch'
  and scope = 'system'
  and owner_id is null
  and industry_id = '00000000-0000-0000-0000-000000000000'
  and code = 'batch_alcohol'
  and coalesce(description, '') is distinct from 'Beer category, target ABV, and actual ABV for batch';

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
  false,
  'Tax',
  'number',
  25
from attr_set s
join attr_def d
  on d.tenant_id = s.tenant_id
 and d.domain = s.domain
 and d.industry_id is not distinct from s.industry_id
where s.tenant_id = '00000000-0000-0000-0000-000000000000'
  and s.domain = 'batch'
  and s.scope = 'system'
  and s.owner_id is null
  and s.industry_id = '00000000-0000-0000-0000-000000000000'
  and s.code = 'batch_alcohol'
  and d.code = 'actual_abv'
  and not exists (
    select 1
    from attr_set_rule r
    where r.tenant_id = s.tenant_id
      and r.attr_set_id = s.attr_set_id
      and r.attr_id = d.attr_id
  );

-- Verification
select
  attr_id,
  tenant_id,
  domain,
  scope,
  industry_id,
  code,
  name,
  name_i18n,
  data_type,
  required,
  description,
  sort_order
from attr_def
where tenant_id = '00000000-0000-0000-0000-000000000000'
  and domain = 'batch'
  and scope = 'system'
  and owner_id is null
  and industry_id = '00000000-0000-0000-0000-000000000000'
  and code = 'actual_abv';

select
  s.code as attr_set_code,
  d.code as attr_code,
  r.required,
  r.ui_section,
  r.ui_widget,
  r.sort_order
from attr_set_rule r
join attr_set s
  on s.tenant_id = r.tenant_id
 and s.attr_set_id = r.attr_set_id
join attr_def d
  on d.tenant_id = r.tenant_id
 and d.attr_id = r.attr_id
where r.tenant_id = '00000000-0000-0000-0000-000000000000'
  and s.domain = 'batch'
  and s.code = 'batch_alcohol'
  and d.code = 'actual_abv';
