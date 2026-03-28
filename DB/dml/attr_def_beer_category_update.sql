-- Update the existing batch beer_category attr_def Japanese label to 酒類分類.
-- Safe to re-run: rows already set to 酒類分類 are skipped.

update attr_def
set
  name_i18n = jsonb_set(
    coalesce(name_i18n, '{}'::jsonb),
    '{ja}',
    to_jsonb('酒類分類'::text),
    true
  ),
  updated_at = now()
where tenant_id = '00000000-0000-0000-0000-000000000000'
  and domain = 'batch'
  and scope = 'system'
  and owner_id is null
  and industry_id = '00000000-0000-0000-0000-000000000000'
  and code = 'beer_category'
  and coalesce(name_i18n ->> 'ja', '') is distinct from '酒類分類';

-- Verification
select
  attr_id,
  tenant_id,
  domain,
  scope,
  industry_id,
  code,
  name,
  name_i18n
from attr_def
where tenant_id = '00000000-0000-0000-0000-000000000000'
  and domain = 'batch'
  and scope = 'system'
  and owner_id is null
  and industry_id = '00000000-0000-0000-0000-000000000000'
  and code = 'beer_category';
