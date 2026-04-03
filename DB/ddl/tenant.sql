do $$ begin
  create type tenant_role as enum ('owner','admin','editor','viewer');
exception when duplicate_object then null; end $$;

create table if not exists tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  meta jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists tenant_members (
  tenant_id uuid not null references tenants(id) on delete cascade,
  user_id uuid not null,  -- references auth.users(id) (can’t FK directly)
  role tenant_role not null default 'viewer',
  invited_by uuid,
  created_at timestamptz not null default now(),
  primary key (tenant_id, user_id)
);

create index if not exists idx_tenant_members_user on tenant_members(user_id);
create index if not exists idx_tenant_members_tenant_role on tenant_members(tenant_id, role);

alter table tenants
  add column if not exists meta jsonb not null default '{}'::jsonb;

alter table tenant_members
  add column if not exists meta jsonb not null default '{}'::jsonb;

alter table tenant_members
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table tenants enable row level security;

drop policy if exists tenants_select_current_or_system_admin on tenants;
create policy tenants_select_current_or_system_admin
on tenants
for select
to authenticated
using (
  coalesce(auth.jwt() -> 'app_metadata' ->> 'is_system_admin', 'false') = 'true'
  or coalesce(auth.jwt() -> 'app_metadata' ->> 'system_role', '') <> ''
  or (
    id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    and exists (
      select 1
      from tenant_members tm
      where tm.tenant_id = tenants.id
        and tm.user_id = auth.uid()
    )
  )
);

drop policy if exists tenants_update_admin_or_system_admin on tenants;
create policy tenants_update_admin_or_system_admin
on tenants
for update
to authenticated
using (
  coalesce(auth.jwt() -> 'app_metadata' ->> 'is_system_admin', 'false') = 'true'
  or coalesce(auth.jwt() -> 'app_metadata' ->> 'system_role', '') <> ''
  or (
    id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    and exists (
      select 1
      from tenant_members tm
      where tm.tenant_id = tenants.id
        and tm.user_id = auth.uid()
        and tm.role in ('owner', 'admin')
    )
  )
)
with check (
  coalesce(auth.jwt() -> 'app_metadata' ->> 'is_system_admin', 'false') = 'true'
  or coalesce(auth.jwt() -> 'app_metadata' ->> 'system_role', '') <> ''
  or (
    id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    and exists (
      select 1
      from tenant_members tm
      where tm.tenant_id = tenants.id
        and tm.user_id = auth.uid()
        and tm.role in ('owner', 'admin')
    )
  )
);
