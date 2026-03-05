create table if not exists tenant_invitations (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references tenants(id) on delete cascade,
  email text not null,
  role tenant_role not null default 'viewer',
  status text not null default 'invited'
    check (status in ('invited', 'accepted', 'revoked', 'expired')),
  invited_by uuid not null,
  invited_user_id uuid null, -- auth.users.id when known
  invited_at timestamptz not null default now(),
  accepted_at timestamptz null,
  expires_at timestamptz null,
  meta jsonb not null default '{}'::jsonb,
  constraint tenant_invitations_email_not_blank check (length(trim(email)) > 0)
);

alter table tenant_invitations
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

create index if not exists idx_tenant_invitations_tenant_status
  on tenant_invitations (tenant_id, status);

create index if not exists idx_tenant_invitations_invited_user
  on tenant_invitations (invited_user_id);

create unique index if not exists uq_tenant_invitations_pending_email
  on tenant_invitations (tenant_id, lower(email))
  where status = 'invited';

alter table tenant_invitations enable row level security;

drop policy if exists tenant_invitations_select_admin on tenant_invitations;
create policy tenant_invitations_select_admin
on tenant_invitations
for select
to authenticated
using (
  tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
  and exists (
    select 1
    from tenant_members tm
    where tm.tenant_id = tenant_invitations.tenant_id
      and tm.user_id = auth.uid()
      and tm.role in ('owner', 'admin')
  )
);

drop policy if exists tenant_invitations_insert_admin on tenant_invitations;
create policy tenant_invitations_insert_admin
on tenant_invitations
for insert
to authenticated
with check (
  tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
  and invited_by = auth.uid()
  and exists (
    select 1
    from tenant_members tm
    where tm.tenant_id = tenant_invitations.tenant_id
      and tm.user_id = auth.uid()
      and tm.role in ('owner', 'admin')
  )
);

drop policy if exists tenant_invitations_update_admin on tenant_invitations;
create policy tenant_invitations_update_admin
on tenant_invitations
for update
to authenticated
using (
  tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
  and exists (
    select 1
    from tenant_members tm
    where tm.tenant_id = tenant_invitations.tenant_id
      and tm.user_id = auth.uid()
      and tm.role in ('owner', 'admin')
  )
)
with check (
  tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
  and exists (
    select 1
    from tenant_members tm
    where tm.tenant_id = tenant_invitations.tenant_id
      and tm.user_id = auth.uid()
      and tm.role in ('owner', 'admin')
  )
);

drop policy if exists tenant_invitations_delete_admin on tenant_invitations;
create policy tenant_invitations_delete_admin
on tenant_invitations
for delete
to authenticated
using (
  tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
  and exists (
    select 1
    from tenant_members tm
    where tm.tenant_id = tenant_invitations.tenant_id
      and tm.user_id = auth.uid()
      and tm.role in ('owner', 'admin')
  )
);
