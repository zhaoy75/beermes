-- ============================================================================
-- attr_set: group of attributes (used to define required/optional fields per domain/industry)
-- - type_def: holds value lists/trees
-- - attr_def: holds field definitions
-- - attr_set: bundles fields into UI / validation profiles (templates)
-- - attr_set_rule: membership + required/order/UI hints per attribute in the set
-- ============================================================================

-- NOTE: assumes you already have:
--   - app_current_tenant_id() function
--   - attr_def(tenant_id, attr_id, ...)
--   - uom(tenant_id, uom_id, ...) if you use it

CREATE TABLE IF NOT EXISTS attr_set (
  tenant_id uuid NOT NULL,

  attr_set_id bigint GENERATED ALWAYS AS IDENTITY,

  -- Which object this set applies tor
  -- e.g. 'batch', 'recipe', 'item', 'equipment'
  domain text NOT NULL,

  -- ownership / visibility
  scope     text NOT NULL DEFAULT 'system',  -- system | tenant
  owner_id  uuid NULL,                       -- tenant_id if scope='tenant'

  -- Industry scope (NULL = shared across industries)
  industry_id uuid NULL,

  -- Stable set code (used in API / JSON / UI mapping)
  code text NOT NULL,

  -- Display name (default language)
  name text NOT NULL,

  -- Optional i18n names: {"ja":"...", "en":"..."}
  name_i18n jsonb NULL,

  description text NULL,

  sort_order int NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,

  meta jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (tenant_id, attr_set_id),

  -- Set code must be unique per scope
  CONSTRAINT uq_attr_set_code
    UNIQUE (tenant_id, domain, industry_id, code),

  CONSTRAINT ck_attr_set_name_i18n_object
    CHECK (name_i18n IS NULL OR jsonb_typeof(name_i18n) = 'object'),

  CONSTRAINT ck_attr_set_meta_object
    CHECK (jsonb_typeof(meta) = 'object'),

  CONSTRAINT attr_set_scope_ck
    CHECK (scope IN ('system','tenant')),

  CONSTRAINT attr_set_scope_owner_ck
    CHECK (
      (scope = 'system' AND owner_id IS NULL)
      OR
      (scope = 'tenant' AND owner_id IS NOT NULL)
    )
);

-- Membership rules: which attributes belong to the set and how to render/validate them
CREATE TABLE IF NOT EXISTS attr_set_rule (
  tenant_id uuid NOT NULL,

  attr_set_id bigint NOT NULL,
  attr_id bigint NOT NULL,

  -- Required in this set (contextual requiredness)
  required boolean NOT NULL DEFAULT false,

  -- UI hints (keep minimal; expand later if needed)
  ui_section text NULL,         -- e.g. 'Basics', 'Quality', 'Tax'
  ui_widget  text NULL,         -- e.g. 'text', 'number', 'select', 'toggle', 'date'
  help_text  text NULL,

  sort_order int NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,

  meta jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (tenant_id, attr_set_id, attr_id),

  CONSTRAINT fk_attr_set_rule_set
    FOREIGN KEY (tenant_id, attr_set_id)
    REFERENCES attr_set(tenant_id, attr_set_id)
    ON DELETE CASCADE,

  CONSTRAINT fk_attr_set_rule_attr
    FOREIGN KEY (tenant_id, attr_id)
    REFERENCES attr_def(tenant_id, attr_id)
    ON DELETE RESTRICT,

  CONSTRAINT ck_attr_set_rule_meta_object
    CHECK (jsonb_typeof(meta) = 'object')
);

-- Helpful indexes for UI queries
CREATE INDEX IF NOT EXISTS ix_attr_set_domain_industry_active
  ON attr_set(tenant_id, domain, industry_id, is_active, sort_order, code);

CREATE INDEX IF NOT EXISTS ix_attr_set_rule_lookup
  ON attr_set_rule(tenant_id, attr_set_id, is_active, sort_order);

CREATE INDEX IF NOT EXISTS ix_attr_set_rule_by_attr
  ON attr_set_rule(tenant_id, attr_id);

-- updated_at trigger (reuse your shared function if already created)
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_attr_set_updated_at ON attr_set;
CREATE TRIGGER trg_attr_set_updated_at
BEFORE UPDATE ON attr_set
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_attr_set_rule_updated_at ON attr_set_rule;
CREATE TRIGGER trg_attr_set_rule_updated_at
BEFORE UPDATE ON attr_set_rule
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- ----------------------------------------------------------------------------
-- RLS (Supabase-style): system rows readable; tenant rows readable/editable by owner
-- ----------------------------------------------------------------------------
ALTER TABLE attr_set ENABLE ROW LEVEL SECURITY;
ALTER TABLE attr_set_rule ENABLE ROW LEVEL SECURITY;

-- attr_set SELECT: system rows + tenant's own rows
CREATE POLICY attr_set_select_system_or_tenant
ON attr_set
FOR SELECT
TO authenticated
USING (
  scope = 'system'
  OR (scope = 'tenant' AND owner_id = app_current_tenant_id())
);

-- attr_set INSERT: tenant can only insert tenant-scoped rows for itself
CREATE POLICY attr_set_insert_tenant_only
ON attr_set
FOR INSERT
TO authenticated
WITH CHECK (
  scope = 'tenant'
  AND owner_id = app_current_tenant_id()
);

-- attr_set UPDATE: tenant can only update its own tenant-scoped rows
CREATE POLICY attr_set_update_own_tenant
ON attr_set
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

-- attr_set DELETE: tenant can only delete its own tenant-scoped rows
CREATE POLICY attr_set_delete_own_tenant
ON attr_set
FOR DELETE
TO authenticated
USING (
  scope = 'tenant'
  AND owner_id = app_current_tenant_id()
);

-- ----------------------------------------------------------------------------
-- attr_set_rule RLS: rule rows are governed by the parent attr_set visibility/ownership
-- ----------------------------------------------------------------------------

-- SELECT: if parent set is visible, rules are visible
CREATE POLICY attr_set_rule_select_via_parent
ON attr_set_rule
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM attr_set s
    WHERE s.tenant_id = attr_set_rule.tenant_id
      AND s.attr_set_id = attr_set_rule.attr_set_id
      AND (
        s.scope = 'system'
        OR (s.scope = 'tenant' AND s.owner_id = app_current_tenant_id())
      )
  )
);

-- INSERT: only allowed if parent set is tenant-owned by current tenant
CREATE POLICY attr_set_rule_insert_via_parent
ON attr_set_rule
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM attr_set s
    WHERE s.tenant_id = attr_set_rule.tenant_id
      AND s.attr_set_id = attr_set_rule.attr_set_id
      AND s.scope = 'tenant'
      AND s.owner_id = app_current_tenant_id()
  )
);

-- UPDATE: only allowed if parent set is tenant-owned by current tenant
CREATE POLICY attr_set_rule_update_via_parent
ON attr_set_rule
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM attr_set s
    WHERE s.tenant_id = attr_set_rule.tenant_id
      AND s.attr_set_id = attr_set_rule.attr_set_id
      AND s.scope = 'tenant'
      AND s.owner_id = app_current_tenant_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM attr_set s
    WHERE s.tenant_id = attr_set_rule.tenant_id
      AND s.attr_set_id = attr_set_rule.attr_set_id
      AND s.scope = 'tenant'
      AND s.owner_id = app_current_tenant_id()
  )
);

-- DELETE: only allowed if parent set is tenant-owned by current tenant
CREATE POLICY attr_set_rule_delete_via_parent
ON attr_set_rule
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM attr_set s
    WHERE s.tenant_id = attr_set_rule.tenant_id
      AND s.attr_set_id = attr_set_rule.attr_set_id
      AND s.scope = 'tenant'
      AND s.owner_id = app_current_tenant_id()
  )
);