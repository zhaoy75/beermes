-- Seed standard beer package categories. Assumes tenant defaults handle tenant_id.
-- Requires mst_uom entries for 'L' and 'mL'.

with package_data as (
  select *
  from (values
    ('KEG10L',  '10L 樽',   10.0, 'L',  true),
    ('KEG15L',  '15L 樽',   15.0, 'L',  true),
    ('KEG20L',  '20L 樽',   20.0, 'L',  true),
    ('KEGPART', 'ハンパ 樽', null, 'L',  false),
    ('CAN350',  '350ml 缶', 350.0, 'mL', true),
    ('CAN500',  '500ml 缶', 500.0, 'mL', true),
    ('BOT750',  '750ml 瓶', 750.0, 'mL', true)
  ) as t(package_code, package_name, size, uom_code, size_fixed)
)
insert into mst_beer_package_category (package_code, package_name, size, uom_id, size_fixed)
select
  d.package_code,
  d.package_name,
  d.size,
  u.id,
  d.size_fixed
from package_data d
join mst_uom u on u.code = d.uom_code
on conflict do nothing;
