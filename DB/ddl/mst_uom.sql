-- UOM type enum (for categorizing UOM dimensions)
do $$
begin
  create type uom_type as enum (
    'weight',
    'volume',
    'temperature',
    'pressure',
    'length',
    'time',
    'percentage',
    'density'
  );
exception
  when duplicate_object then
    null;
end $$;

create table if not exists mst_uom (
  id uuid primary key default gen_random_uuid(),
  scope	  text NOT NULL DEFAULT 'system',  -- system | tenant | user
  industry_id uuid NULL,             -- NULL = shared across industries
  tenant_id uuid,
  owner_id  uuid NULL,                       -- tenant_id or user_id if not system

  code text not null,
  name text,
  dimension uom_type,
  base_factor numeric,
  base_code text,
  is_base_unit boolean default false,
  meta jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  unique (tenant_id, code)
);

alter table mst_uom
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

create index if not exists idx_mst_uom_tenant_code
  on mst_uom (tenant_id, code);

ALTER TABLE mst_uom ENABLE ROW LEVEL SECURITY;

-- SELECT: system rows + tenant's own rows
CREATE POLICY mst_uom_select_system_or_tenant
ON mst_uom
FOR SELECT
TO authenticated
USING (
  scope = 'system'
  OR (scope = 'tenant' AND owner_id = app_current_tenant_id())
);

-- INSERT: tenant can only insert tenant-scoped rows for itself
CREATE POLICY mst_uom_insert_tenant_only
ON mst_uom
FOR INSERT
TO authenticated
WITH CHECK (
  scope = 'tenant'
  AND owner_id = app_current_tenant_id()
);

-- UPDATE: tenant can only update its own tenant-scoped rows
CREATE POLICY mst_uom_update_own_tenant
ON mst_uom
FOR UPDATE
TO authenticated
USING (
  scope = 'tenant'
  AND owner_id = app_current_tenant_id()
)
WITH CHECK (
  scope = 'tenant'
  AND owner_id = app_current_tenant_id()
);

-- DELETE: tenant can only delete its own tenant-scoped rows
CREATE POLICY mst_uom_delete_own_tenant
ON mst_uom
FOR DELETE
TO authenticated
USING (
  scope = 'tenant'
  AND owner_id = app_current_tenant_id()
);

ALTER TABLE mst_uom
ADD CONSTRAINT mst_uom_scope_ck CHECK (scope IN ('system','tenant'));

ALTER TABLE mst_uom
ADD CONSTRAINT mst_uom_scope_owner_ck CHECK (
  (scope = 'system' AND owner_id IS NULL)
  OR
  (scope = 'tenant' AND owner_id IS NOT NULL)
);
