-- attr_def: definition of additional attributes (industry-dependent fields)
-- Used by batch / recipe / item / equipment etc.
-- Values are stored separately (e.g., entity_attr)

CREATE TABLE IF NOT EXISTS attr_def (
  tenant_id uuid NULL,

  attr_id bigint GENERATED ALWAYS AS IDENTITY,

  -- What object this attribute applies to
  -- e.g. 'batch', 'recipe', 'item', 'equipment'
  domain text NOT NULL,

  -- ownership / visibility
  scope	  text NOT NULL DEFAULT 'system',  -- system | tenant | user
  owner_id    uuid NULL,                       -- tenant_id or user_id if not system

  -- Industry scope (NULL = shared across industries)
  industry_id uuid NULL,

  -- Stable attribute code (used in API / JSON / UI mapping)
  code text NOT NULL,

  -- Display name (default language)
  name text NOT NULL,

  -- Optional i18n names: {"ja":"...", "en":"..."}
  name_i18n jsonb NULL,

  -- Attribute data type
  -- Suggested values:
  -- 'string','number','boolean','date','timestamp','json','ref'
  data_type text NOT NULL,

  -- Unit of measure (for numeric values)
  uom_id uuid NULL,

  -- Reference definition (used when data_type='ref')
  -- Example:
  --   ref_kind='type_def'
  --   ref_domain='beer_style'
  ref_kind text NULL,
  ref_domain text NULL,

  -- Validation rules
  required boolean NOT NULL DEFAULT false,

  num_min numeric NULL,
  num_max numeric NULL,

  text_regex text NULL,
  allowed_values jsonb NULL,   -- enum-like values (only if NOT ref)

  default_value jsonb NULL,    -- default value (typed in JSON)

  description text NULL,

  sort_order int NOT NULL DEFAULT 0,
  is_active boolean NOT NULL DEFAULT true,

  meta jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (attr_id),

  -- Attribute code must be unique per scope
  CONSTRAINT uq_attr_def_code
    UNIQUE (tenant_id, domain, industry_id, code),

  -- Optional FK to unit of measure
  CONSTRAINT fk_attr_def_uom
    FOREIGN KEY (uom_id)
    REFERENCES mst_uom(id),

  -- JSON structure checks
  CONSTRAINT ck_attr_def_name_i18n_object
    CHECK (name_i18n IS NULL OR jsonb_typeof(name_i18n) = 'object'),

  CONSTRAINT ck_attr_def_allowed_values_object
    CHECK (allowed_values IS NULL OR jsonb_typeof(allowed_values) IN ('array','object')),

  CONSTRAINT ck_attr_def_default_value_json
    CHECK (default_value IS NULL OR jsonb_typeof(default_value) IS NOT NULL),

  CONSTRAINT ck_attr_def_meta_object
    CHECK (jsonb_typeof(meta) = 'object'),

  -- ref attributes must declare reference info
  CONSTRAINT ck_attr_def_ref_consistency
    CHECK (
      (data_type <> 'ref')
      OR
      (ref_kind IS NOT NULL AND ref_domain IS NOT NULL)
    )
);

ALTER TABLE attr_def ENABLE ROW LEVEL SECURITY;

-- SELECT: system rows + tenant's own rows
CREATE POLICY attr_def_select_system_or_tenant
ON attr_def
FOR SELECT
TO authenticated
USING (
  scope = 'system'
  OR (scope = 'tenant' AND owner_id = app_current_tenant_id())
);

-- INSERT: tenant can only insert tenant-scoped rows for itself
CREATE POLICY attr_def_insert_tenant_only
ON attr_def
FOR INSERT
TO authenticated
WITH CHECK (
  scope = 'tenant'
  AND owner_id = app_current_tenant_id()
);

-- UPDATE: tenant can only update its own tenant-scoped rows
CREATE POLICY attr_def_update_own_tenant
ON attr_def
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
CREATE POLICY attr_def_delete_own_tenant
ON attr_def
FOR DELETE
TO authenticated
USING (
  scope = 'tenant'
  AND owner_id = app_current_tenant_id()
);

ALTER TABLE attr_def
ADD CONSTRAINT attr_def_scope_ck CHECK (scope IN ('system','tenant'));

ALTER TABLE attr_def
ADD CONSTRAINT attr_def_scope_owner_ck CHECK (
  (scope = 'system' AND owner_id IS NULL)
  OR
  (scope = 'tenant' AND owner_id IS NOT NULL)
);
