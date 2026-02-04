create table if not exists tax_reports (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  tax_type text not null default 'monthly',
  tax_year int not null,
  tax_month int not null,
  status text not null default 'draft',
  total_tax_amount numeric not null default 0,
  volume_breakdown jsonb default '[]'::jsonb,
  report_files jsonb default '[]'::jsonb,
  attachment_files jsonb default '[]'::jsonb,
  created_at timestamptz default now(),
  unique (tenant_id, tax_year, tax_month),
  constraint tax_reports_status_check check (status in ('draft','submitted','approved')),
  constraint tax_reports_month_check check (tax_month between 1 and 12)
);

alter table tax_reports   enable row level security;

alter table tax_reports
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

drop policy if exists "tax_reports_tenant_all" on tax_reports;
create policy "tax_reports_tenant_all"
  on tax_reports
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

alter table inv_inventory
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table inv_inventory   enable row level security;

drop policy if exists "inv_inventory_tenant_all" on inv_inventory;
create policy "inv_inventory_tenant_all"
  on inv_inventory
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);
