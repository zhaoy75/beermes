-- ============================================================================
-- entity_attr
-- Stores actual attribute values for entities (batch / recipe / item / etc.)
-- Uses UUID entity IDs
-- ============================================================================

CREATE TABLE IF NOT EXISTS entity_attr (
  tenant_id uuid NOT NULL,

  entity_type text NOT NULL,
  entity_id uuid NOT NULL,

  attr_id bigint NOT NULL,

  -- Typed value columns (exactly one should be used)
  value_text  text NULL,
  value_num   numeric NULL,
  value_bool  boolean NULL,
  value_date  date NULL,
  value_ts    timestamptz NULL,
  value_json  jsonb NULL,

  -- Reference to type_def (for data_type='ref')
  value_ref_type_id bigint NULL,

  -- Optional UOM override
  uom_id uuid NULL,

  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NULL,

  -- At most one value column allowed
  CONSTRAINT ck_entity_attr_single_value
  CHECK (
    (CASE WHEN value_text IS NULL THEN 0 ELSE 1 END) +
    (CASE WHEN value_num  IS NULL THEN 0 ELSE 1 END) +
    (CASE WHEN value_bool IS NULL THEN 0 ELSE 1 END) +
    (CASE WHEN value_date IS NULL THEN 0 ELSE 1 END) +
    (CASE WHEN value_ts   IS NULL THEN 0 ELSE 1 END) +
    (CASE WHEN value_json IS NULL THEN 0 ELSE 1 END) +
    (CASE WHEN value_ref_type_id IS NULL THEN 0 ELSE 1 END)
    <= 1
  ),

  PRIMARY KEY (
    tenant_id,
    entity_type,
    entity_id,
    attr_id
  ),

  CONSTRAINT fk_entity_attr_attr_def
    FOREIGN KEY (tenant_id, attr_id)
    REFERENCES attr_def(tenant_id, attr_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_entity_attr_ref_type_def
    FOREIGN KEY (tenant_id, value_ref_type_id)
    REFERENCES type_def(tenant_id, type_id)
    ON DELETE RESTRICT,

  CONSTRAINT fk_entity_attr_uom
    FOREIGN KEY (uom_id)
    REFERENCES mst_uom(id),

  CONSTRAINT ck_entity_attr_value_json_valid
    CHECK (value_json IS NULL OR jsonb_typeof(value_json) IS NOT NULL)
);

-- Indexes
CREATE INDEX IF NOT EXISTS ix_entity_attr_by_entity
  ON entity_attr(tenant_id, entity_type, entity_id);

CREATE INDEX IF NOT EXISTS ix_entity_attr_by_attr
  ON entity_attr(tenant_id, attr_id);

CREATE INDEX IF NOT EXISTS ix_entity_attr_ref
  ON entity_attr(tenant_id, value_ref_type_id)
  WHERE value_ref_type_id IS NOT NULL;

ALTER TABLE entity_attr ENABLE ROW LEVEL SECURITY;

CREATE POLICY entity_attr_select_own_tenant
ON entity_attr
FOR SELECT
TO authenticated
USING (tenant_id = app_current_tenant_id());

CREATE POLICY entity_attr_insert_own_tenant
ON entity_attr
FOR INSERT
TO authenticated
WITH CHECK (tenant_id = app_current_tenant_id());

CREATE POLICY entity_attr_update_own_tenant
ON entity_attr
FOR UPDATE
TO authenticated
USING (tenant_id = app_current_tenant_id())
WITH CHECK (tenant_id = app_current_tenant_id());

CREATE POLICY entity_attr_delete_own_tenant
ON entity_attr
FOR DELETE
TO authenticated
USING (tenant_id = app_current_tenant_id());

-- ============================================================================
-- entity_attr_set
-- Assigns one or more attr_set profiles to an entity instance
-- Uses UUID entity IDs
-- ============================================================================

CREATE TABLE IF NOT EXISTS entity_attr_set (
  tenant_id uuid NOT NULL,

  entity_type text NOT NULL,        -- e.g. 'batch', 'recipe_version', 'item'
  entity_id uuid NOT NULL,

  attr_set_id bigint NOT NULL,
  is_active boolean NOT NULL DEFAULT true,

  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,

  PRIMARY KEY (
    tenant_id,
    entity_type,
    entity_id,
    attr_set_id
  ),

  CONSTRAINT fk_entity_attr_set_attr_set
    FOREIGN KEY (tenant_id, attr_set_id)
    REFERENCES attr_set(tenant_id, attr_set_id)
    ON DELETE CASCADE
);

-- Indexes
CREATE INDEX IF NOT EXISTS ix_entity_attr_set_lookup
  ON entity_attr_set(tenant_id, entity_type, entity_id, is_active);

ALTER TABLE entity_attr_set ENABLE ROW LEVEL SECURITY;

CREATE POLICY entity_attr_set_select_own_tenant
ON entity_attr_set
FOR SELECT
TO authenticated
USING (tenant_id = app_current_tenant_id());

CREATE POLICY entity_attr_set_insert_own_tenant
ON entity_attr_set
FOR INSERT
TO authenticated
WITH CHECK (tenant_id = app_current_tenant_id());

CREATE POLICY entity_attr_set_update_own_tenant
ON entity_attr_set
FOR UPDATE
TO authenticated
USING (tenant_id = app_current_tenant_id())
WITH CHECK (tenant_id = app_current_tenant_id());

CREATE POLICY entity_attr_set_delete_own_tenant
ON entity_attr_set
FOR DELETE
TO authenticated
USING (tenant_id = app_current_tenant_id());
