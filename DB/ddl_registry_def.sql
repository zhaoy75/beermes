CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS registry_def (
  def_id      uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  -- definition category
  kind        text NOT NULL,      -- e.g. material_type | site_type | movement_type | ...

  -- stable logical key
  def_key     text NOT NULL,      -- e.g. malt, starch, warehouse, brew_input

  -- ownership / visibility
  scope	  text NOT NULL DEFAULT 'system',  -- system | tenant | user
  owner_id    uuid NULL,                       -- tenant_id or user_id if not system

  is_active   boolean NOT NULL DEFAULT true,

  -- JSON definition
  spec        jsonb NOT NULL,

  created_at  timestamptz NOT NULL DEFAULT now(),
  updated_at  timestamptz NOT NULL DEFAULT now(),

  -- constraints
--   CONSTRAINT registry_def_kind_ck CHECK (
--     kind IN (
--       'material_type',
--       'site_type',
--       'movement_type',
--       'packaging_type',
--       'tax_type',
--       'alcohol_type',
--       'alcohol_tax',
--       'other'
--     )
--   ),

  CONSTRAINT registry_scope_ck CHECK (
    scope IN ('system','tenant','user')
  ),

  CONSTRAINT registry_def_spec_is_object_ck CHECK (
    jsonb_typeof(spec) = 'object'
  ),

  CONSTRAINT registry_def_key_format_ck CHECK (
    def_key ~ '^[a-z0-9][a-z0-9._-]{1,63}$'
  ),

  CONSTRAINT registry_scope_owner_ck CHECK (
    (scope = 'system' AND owner_id IS NULL)
    OR
    (scope IN ('tenant','user') AND owner_id IS NOT NULL)
  )
);

CREATE OR REPLACE FUNCTION app_current_tenant_id()
RETURNS uuid
LANGUAGE sql
AS $$
  SELECT NULLIF((auth.jwt() -> 'app_metadata' ->> 'tenant_id'), '')::uuid
$$;

ALTER TABLE registry_def ENABLE ROW LEVEL SECURITY;

CREATE POLICY registry_def_select_system_or_tenant
ON registry_def
FOR SELECT
TO authenticated
USING (
  scope = 'system'
  OR (scope = 'tenant' AND owner_id = app_current_tenant_id())
);

CREATE POLICY registry_def_insert_tenant_only
ON registry_def
FOR INSERT
TO authenticated
WITH CHECK (
  scope = 'tenant'
  AND owner_id = app_current_tenant_id()
);


CREATE POLICY registry_def_update_own_tenant
ON registry_def
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

CREATE POLICY registry_def_delete_own_tenant
ON registry_def
FOR DELETE
TO authenticated
USING (
  scope = 'tenant'
  AND owner_id = app_current_tenant_id()
);





















