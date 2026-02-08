-- ============================================================
-- Equipment master + Tank subtype (1:1)
-- Tables:
--   - mst_equipment        : all physical assets (tank/pump/filler/etc.)
--   - mst_equipment_tank   : tank-only fields (capacity, working volume...)
-- Notes:
--   - Uses mst_sites(id) for location
--   - Uses JSONB attr_doc for extensions
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ------------------------------------------------------------
-- Shared updated_at trigger
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION trg_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

-- ------------------------------------------------------------
-- mst_equipment (base asset)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mst_equipment (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id          uuid NOT NULL,
  industry_id        uuid NULL,

  equipment_code     text NOT NULL,                          -- e.g. FV-01, PUMP-01, FILLER-01
  name_i18n          jsonb NOT NULL DEFAULT '{}'::jsonb,
  description        text NULL,

  -- classification (recommend: type_def.id)
  equipment_type_id  uuid NULL,                              -- e.g. tank / pump / filler / chiller
  equipment_kind     text NULL
    CHECK (
      equipment_kind IS NULL
      OR equipment_kind IN ('tank','pump','filler','labeler','kettle','mash_tun','lauter_tun','chiller','other')
    ),

  -- location
  site_id            uuid NOT NULL REFERENCES mst_sites(id),

  -- lifecycle/state
  equipment_status   text NOT NULL DEFAULT 'available'
    CHECK (equipment_status IN ('available','in_use','cleaning','maintenance','retired')),

  commissioned_at    date NULL,
  decommissioned_at  date NULL,

  -- generic extension
  attr_doc           jsonb NOT NULL DEFAULT '{}'::jsonb,

  is_active          boolean NOT NULL DEFAULT true,
  sort_order         integer NOT NULL DEFAULT 0,

  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT mst_equipment_uq_tenant_industry_code
    UNIQUE (tenant_id, industry_id, equipment_code),

  CONSTRAINT mst_equipment_decom_chk
    CHECK (decommissioned_at IS NULL OR commissioned_at IS NULL OR decommissioned_at >= commissioned_at)
);

CREATE INDEX IF NOT EXISTS ix_mst_equipment_lookup
  ON mst_equipment (tenant_id, industry_id, is_active, sort_order, equipment_code);

CREATE INDEX IF NOT EXISTS ix_mst_equipment_site
  ON mst_equipment (tenant_id, site_id);

CREATE INDEX IF NOT EXISTS ix_mst_equipment_status
  ON mst_equipment (tenant_id, equipment_status);

CREATE INDEX IF NOT EXISTS ix_mst_equipment_kind
  ON mst_equipment (tenant_id, equipment_kind)
  WHERE equipment_kind IS NOT NULL;

CREATE INDEX IF NOT EXISTS ix_mst_equipment_attr_doc_gin
  ON mst_equipment USING gin (attr_doc);

DROP TRIGGER IF EXISTS trg_mst_equipment_updated_at ON mst_equipment;
CREATE TRIGGER trg_mst_equipment_updated_at
BEFORE UPDATE ON mst_equipment
FOR EACH ROW
EXECUTE FUNCTION trg_set_updated_at();

-- ------------------------------------------------------------
-- mst_equipment_tank (subtype: tank-only)
-- 1:1 with mst_equipment (PK = FK)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS mst_equipment_tank (
  equipment_id       uuid PRIMARY KEY REFERENCES mst_equipment(id) ON DELETE CASCADE,

  -- Capacity (core for transfers/planning)
  capacity_volume    numeric(18,6) NOT NULL CHECK (capacity_volume > 0),
  volume_uom         text NOT NULL DEFAULT 'L',              -- should be volume domain

  -- Optional working volume limit
  max_work_volume    numeric(18,6) NULL,
  max_work_uom       text NULL,

  -- Optional tank semantics
  is_pressurized     boolean NOT NULL DEFAULT false,
  is_jacketed        boolean NOT NULL DEFAULT false,
  cip_supported      boolean NOT NULL DEFAULT true,

  -- Tank-specific extension (ports, zones, ratings, etc.)
  tank_attr_doc      jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at         timestamptz NOT NULL DEFAULT now(),
  updated_at         timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT mst_equipment_tank_max_work_chk
    CHECK (
      (max_work_volume IS NULL AND max_work_uom IS NULL)
      OR
      (max_work_volume IS NOT NULL AND max_work_uom IS NOT NULL)
    ),

  CONSTRAINT mst_equipment_tank_max_le_capacity_chk
    CHECK (
      max_work_volume IS NULL
      OR max_work_volume <= capacity_volume
    )
);

CREATE INDEX IF NOT EXISTS ix_mst_equipment_tank_attr_doc_gin
  ON mst_equipment_tank USING gin (tank_attr_doc);

DROP TRIGGER IF EXISTS trg_mst_equipment_tank_updated_at ON mst_equipment_tank;
CREATE TRIGGER trg_mst_equipment_tank_updated_at
BEFORE UPDATE ON mst_equipment_tank
FOR EACH ROW
EXECUTE FUNCTION trg_set_updated_at();

-- ============================================================
-- RLS + tenant auto-fill triggers for:
--   - mst_equipment
--   - mst_equipment_tank
--
-- Assumptions:
--   - app_current_tenant_id() already exists in your DB
--   - tenant_id is stored in JWT and resolved by app_current_tenant_id()
-- ============================================================

-- ------------------------------------------------------------
-- Enable RLS
-- ------------------------------------------------------------
ALTER TABLE mst_equipment ENABLE ROW LEVEL SECURITY;
ALTER TABLE mst_equipment FORCE ROW LEVEL SECURITY;

ALTER TABLE mst_equipment_tank ENABLE ROW LEVEL SECURITY;
ALTER TABLE mst_equipment_tank FORCE ROW LEVEL SECURITY;

-- ------------------------------------------------------------
-- Policies: mst_equipment
-- ------------------------------------------------------------
DROP POLICY IF EXISTS mst_equipment_select ON mst_equipment;
CREATE POLICY mst_equipment_select
ON mst_equipment
FOR SELECT
TO authenticated
USING (
  tenant_id = app_current_tenant_id()
);

DROP POLICY IF EXISTS mst_equipment_insert ON mst_equipment;
CREATE POLICY mst_equipment_insert
ON mst_equipment
FOR INSERT
TO authenticated
WITH CHECK (
  tenant_id = app_current_tenant_id()
);

DROP POLICY IF EXISTS mst_equipment_update ON mst_equipment;
CREATE POLICY mst_equipment_update
ON mst_equipment
FOR UPDATE
TO authenticated
USING (
  tenant_id = app_current_tenant_id()
)
WITH CHECK (
  tenant_id = app_current_tenant_id()
);

DROP POLICY IF EXISTS mst_equipment_delete ON mst_equipment;
CREATE POLICY mst_equipment_delete
ON mst_equipment
FOR DELETE
TO authenticated
USING (
  tenant_id = app_current_tenant_id()
);

-- ------------------------------------------------------------
-- Policies: mst_equipment_tank
-- IMPORTANT: table has no tenant_id, so enforce via join to mst_equipment
-- ------------------------------------------------------------
DROP POLICY IF EXISTS mst_equipment_tank_select ON mst_equipment_tank;
CREATE POLICY mst_equipment_tank_select
ON mst_equipment_tank
FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM mst_equipment e
    WHERE e.id = mst_equipment_tank.equipment_id
      AND e.tenant_id = app_current_tenant_id()
  )
);

DROP POLICY IF EXISTS mst_equipment_tank_insert ON mst_equipment_tank;
CREATE POLICY mst_equipment_tank_insert
ON mst_equipment_tank
FOR INSERT
TO authenticated
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM mst_equipment e
    WHERE e.id = mst_equipment_tank.equipment_id
      AND e.tenant_id = app_current_tenant_id()
  )
);

DROP POLICY IF EXISTS mst_equipment_tank_update ON mst_equipment_tank;
CREATE POLICY mst_equipment_tank_update
ON mst_equipment_tank
FOR UPDATE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM mst_equipment e
    WHERE e.id = mst_equipment_tank.equipment_id
      AND e.tenant_id = app_current_tenant_id()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM mst_equipment e
    WHERE e.id = mst_equipment_tank.equipment_id
      AND e.tenant_id = app_current_tenant_id()
  )
);

DROP POLICY IF EXISTS mst_equipment_tank_delete ON mst_equipment_tank;
CREATE POLICY mst_equipment_tank_delete
ON mst_equipment_tank
FOR DELETE
TO authenticated
USING (
  EXISTS (
    SELECT 1
    FROM mst_equipment e
    WHERE e.id = mst_equipment_tank.equipment_id
      AND e.tenant_id = app_current_tenant_id()
  )
);

-- ------------------------------------------------------------
-- Trigger: auto-fill and enforce tenant_id on mst_equipment
-- (same pattern as you used for mst_sites / mst_package)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION mst_equipment_enforce_tenant()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  IF NEW.tenant_id IS NULL THEN
    NEW.tenant_id := app_current_tenant_id();
  END IF;

  IF NEW.tenant_id <> app_current_tenant_id() THEN
    RAISE EXCEPTION 'tenant_id mismatch';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_mst_equipment_enforce_tenant ON mst_equipment;
CREATE TRIGGER trg_mst_equipment_enforce_tenant
BEFORE INSERT OR UPDATE ON mst_equipment
FOR EACH ROW
EXECUTE FUNCTION mst_equipment_enforce_tenant();

-- ------------------------------------------------------------
-- Trigger: prevent creating tank subtype for equipment not owned by tenant
-- (RLS already does this, but trigger gives clearer error messages)
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION mst_equipment_tank_enforce_owner()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  owner_tenant uuid;
BEGIN
  SELECT tenant_id INTO owner_tenant
  FROM mst_equipment
  WHERE id = NEW.equipment_id;

  IF owner_tenant IS NULL THEN
    RAISE EXCEPTION 'equipment_id not found';
  END IF;

  IF owner_tenant <> app_current_tenant_id() THEN
    RAISE EXCEPTION 'equipment_id not owned by current tenant';
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_mst_equipment_tank_enforce_owner ON mst_equipment_tank;
CREATE TRIGGER trg_mst_equipment_tank_enforce_owner
BEFORE INSERT OR UPDATE ON mst_equipment_tank
FOR EACH ROW
EXECUTE FUNCTION mst_equipment_tank_enforce_owner();