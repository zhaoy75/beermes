-- type_def: generic tree/list master (BIGINT PK)
CREATE TABLE IF NOT EXISTS type_def (
  tenant_id uuid NOT NULL,

  type_id bigint GENERATED ALWAYS AS IDENTITY,

  -- ownership / visibility
  scope	  text NOT NULL DEFAULT 'system',  -- system | tenant | user
  owner_id    uuid NULL,                       -- tenant_id or user_id if not system

  domain text NOT NULL,              -- e.g. 'material_type', 'beer_style'
  industry_id uuid NULL,             -- NULL = shared across industries
  code text NOT NULL,                -- stable within (tenant, domain, industry)
  name text NOT NULL,
  name_i18n jsonb NULL,

  parent_type_id bigint NULL,
  sort_order int NOT NULL DEFAULT 0,

  description text NULL,
  meta jsonb NOT NULL DEFAULT '{}'::jsonb,
  is_active boolean NOT NULL DEFAULT true,

  valid_from date NULL,
  valid_to date NULL,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  PRIMARY KEY (tenant_id, type_id),

  CONSTRAINT registry_scope_ck CHECK (
    scope IN ('system','tenant','user')
  ),

  CONSTRAINT uq_type_def_code UNIQUE (tenant_id, domain, industry_id, code),

  CONSTRAINT fk_type_def_parent
    FOREIGN KEY (tenant_id, parent_type_id)
    REFERENCES type_def(tenant_id, type_id)
    ON DELETE RESTRICT,

  CONSTRAINT ck_type_def_valid_range
    CHECK (valid_from IS NULL OR valid_to IS NULL OR valid_from <= valid_to),

  CONSTRAINT ck_type_def_name_i18n_object
    CHECK (name_i18n IS NULL OR jsonb_typeof(name_i18n) = 'object'),

  CONSTRAINT ck_type_def_meta_object
    CHECK (jsonb_typeof(meta) = 'object')
);

CREATE INDEX IF NOT EXISTS ix_type_def_domain
  ON type_def(tenant_id, domain);

CREATE INDEX IF NOT EXISTS ix_type_def_domain_industry_active
  ON type_def(tenant_id, domain, industry_id, is_active);

CREATE INDEX IF NOT EXISTS ix_type_def_parent
  ON type_def(tenant_id, parent_type_id);

CREATE INDEX IF NOT EXISTS ix_type_def_sort
  ON type_def(tenant_id, domain, industry_id, parent_type_id, sort_order, code);

-- updated_at trigger (reuse if you already have a common function)
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_type_def_updated_at ON type_def;
CREATE TRIGGER trg_type_def_updated_at
BEFORE UPDATE ON type_def
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

ALTER TABLE type_def ENABLE ROW LEVEL SECURITY;

CREATE POLICY type_def_select_system_or_tenant
ON type_def
FOR SELECT
TO authenticated
USING (
  scope = 'system'
  OR (scope = 'tenant' AND owner_id = app_current_tenant_id())
);

CREATE POLICY type_def_insert_tenant_only
ON type_def
FOR INSERT
TO authenticated
WITH CHECK (
  scope = 'tenant'
  AND owner_id = app_current_tenant_id()
);


CREATE POLICY type_def_update_own_tenant
ON type_def
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

CREATE POLICY type_def_delete_own_tenant
ON type_def
FOR DELETE
TO authenticated
USING (
  scope = 'tenant'
  AND owner_id = app_current_tenant_id()
);


CREATE TABLE IF NOT EXISTS type_closure (
  tenant_id uuid NOT NULL,
  domain text NOT NULL,
  industry_id uuid NULL,

  ancestor_type_id bigint NOT NULL,
  descendant_type_id bigint NOT NULL,
  depth int NOT NULL CHECK (depth >= 0),

  PRIMARY KEY (tenant_id, domain, industry_id, ancestor_type_id, descendant_type_id),

  -- optional FKs (recommended)
  FOREIGN KEY (tenant_id, ancestor_type_id)
    REFERENCES type_def(tenant_id, type_id)
    ON DELETE CASCADE,
  FOREIGN KEY (tenant_id, descendant_type_id)
    REFERENCES type_def(tenant_id, type_id)
    ON DELETE CASCADE
);

-- Query indexes
CREATE INDEX IF NOT EXISTS ix_type_closure_descendants
ON type_closure(tenant_id, domain, industry_id, ancestor_type_id, depth);

CREATE INDEX IF NOT EXISTS ix_type_closure_ancestors
ON type_closure(tenant_id, domain, industry_id, descendant_type_id, depth);

CREATE OR REPLACE FUNCTION rebuild_type_closure(
  p_tenant_id uuid,
  p_domain text,
  p_industry_id uuid
)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  -- Remove old closure for this scope
  DELETE FROM type_closure
   WHERE tenant_id = p_tenant_id
     AND domain = p_domain
     AND industry_id IS NOT DISTINCT FROM p_industry_id;

  -- Rebuild closure using recursive walk
  INSERT INTO type_closure(
    tenant_id, domain, industry_id,
    ancestor_type_id, descendant_type_id, depth
  )
  WITH RECURSIVE walk AS (
    -- self rows
    SELECT
      td.tenant_id,
      td.domain,
      td.industry_id,
      td.type_id AS ancestor_type_id,
      td.type_id AS descendant_type_id,
      0 AS depth
    FROM type_def td
    WHERE td.tenant_id = p_tenant_id
      AND td.domain = p_domain
      AND td.industry_id IS NOT DISTINCT FROM p_industry_id

    UNION ALL

    -- expand to children
    SELECT
      w.tenant_id,
      w.domain,
      w.industry_id,
      w.ancestor_type_id,
      c.type_id AS descendant_type_id,
      w.depth + 1 AS depth
    FROM walk w
    JOIN type_def c
      ON c.tenant_id = w.tenant_id
     AND c.domain = w.domain
     AND c.industry_id IS NOT DISTINCT FROM w.industry_id
     AND c.parent_type_id = w.descendant_type_id
  )
  SELECT tenant_id, domain, industry_id, ancestor_type_id, descendant_type_id, depth
  FROM walk;
END $$;

CREATE OR REPLACE FUNCTION trg_type_def_refresh_closure()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_tenant uuid;
  v_domain text;
  v_industry uuid;
BEGIN
  IF TG_OP = 'DELETE' THEN
    v_tenant := OLD.tenant_id;
    v_domain := OLD.domain;
    v_industry := OLD.industry_id;
  ELSE
    v_tenant := NEW.tenant_id;
    v_domain := NEW.domain;
    v_industry := NEW.industry_id;
  END IF;

  PERFORM rebuild_type_closure(v_tenant, v_domain, v_industry);

  -- if an update moved rows across domain/industry, rebuild old scope too
  IF TG_OP = 'UPDATE' THEN
    IF (OLD.domain <> NEW.domain)
       OR (OLD.industry_id IS DISTINCT FROM NEW.industry_id) THEN
      PERFORM rebuild_type_closure(OLD.tenant_id, OLD.domain, OLD.industry_id);
    END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_type_def_refresh_closure ON type_def;
CREATE TRIGGER trg_type_def_refresh_closure
AFTER INSERT OR UPDATE OR DELETE ON type_def
FOR EACH ROW
EXECUTE FUNCTION trg_type_def_refresh_closure();

CREATE OR REPLACE FUNCTION trg_type_def_prevent_cycle()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE
  v_found int;
BEGIN
  -- root is always OK
  IF NEW.parent_type_id IS NULL THEN
    RETURN NEW;
  END IF;

  -- cannot parent to self
  IF NEW.parent_type_id = NEW.type_id THEN
    RAISE EXCEPTION 'type_def cycle: parent cannot be self (type_id=%)', NEW.type_id;
  END IF;

  -- enforce parent exists in same tenant + same domain + same industry scope
  IF NOT EXISTS (
    SELECT 1
    FROM type_def p
    WHERE p.tenant_id = NEW.tenant_id
      AND p.type_id = NEW.parent_type_id
      AND p.domain = NEW.domain
      AND p.industry_id IS NOT DISTINCT FROM NEW.industry_id
  ) THEN
    RAISE EXCEPTION 'type_def invalid parent: parent must exist in same tenant/domain/industry scope';
  END IF;

  -- Cycle check using base table:
  -- If NEW.parent is inside NEW's subtree => cycle.
  WITH RECURSIVE subtree AS (
    SELECT td.tenant_id, td.type_id
    FROM type_def td
    WHERE td.tenant_id = NEW.tenant_id
      AND td.type_id = NEW.type_id

    UNION ALL

    SELECT c.tenant_id, c.type_id
    FROM type_def c
    JOIN subtree s
      ON c.tenant_id = s.tenant_id
     AND c.parent_type_id = s.type_id
     AND c.domain = NEW.domain
     AND c.industry_id IS NOT DISTINCT FROM NEW.industry_id
  )
  SELECT 1 INTO v_found
  FROM subtree
  WHERE type_id = NEW.parent_type_id
  LIMIT 1;

  IF v_found = 1 THEN
    RAISE EXCEPTION 'type_def cycle: parent is a descendant of this node';
  END IF;

  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_type_def_prevent_cycle ON type_def;
CREATE TRIGGER trg_type_def_prevent_cycle
BEFORE INSERT OR UPDATE OF parent_type_id, domain, industry_id ON type_def
FOR EACH ROW
EXECUTE FUNCTION trg_type_def_prevent_cycle();



