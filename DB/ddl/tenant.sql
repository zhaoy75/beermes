do $$ begin
  create type tenant_role as enum ('owner','admin','editor','viewer');
exception when duplicate_object then null; end $$;

create table if not exists tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
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

alter table tenant_members
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

