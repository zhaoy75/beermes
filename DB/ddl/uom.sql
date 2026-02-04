create table if not exists mst_uom (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  code text not null,
  name text,
  base_factor numeric,
  base_code text,
  meta jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  unique (tenant_id, code)
);

alter table mst_uom
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

create index if not exists idx_mst_uom_tenant_code
  on mst_uom (tenant_id, code);

alter table mst_uom         enable row level security;

-- Policies (drop-if-exists then create)
-- Masters
drop policy if exists "mst_uom_tenant_all" on mst_uom;
create policy "mst_uom_tenant_all"
  on mst_uom
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);