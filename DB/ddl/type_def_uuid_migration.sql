-- ============================================================================
-- Phase 1 migration: introduce UUID shadow keys for public.type_def
-- ----------------------------------------------------------------------------
-- This migration is intentionally non-destructive.
-- It keeps the existing bigint identifiers in place and adds UUID shadow
-- columns plus dual-write sync triggers so the application can cut over later.
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ----------------------------------------------------------------------------
-- 1. public.type_def: add UUID shadow columns
-- ----------------------------------------------------------------------------
ALTER TABLE public.type_def
  ADD COLUMN IF NOT EXISTS type_uuid uuid,
  ADD COLUMN IF NOT EXISTS parent_type_uuid uuid;

ALTER TABLE public.type_def
  ALTER COLUMN type_uuid SET DEFAULT gen_random_uuid();

UPDATE public.type_def
   SET type_uuid = gen_random_uuid()
 WHERE type_uuid IS NULL;

UPDATE public.type_def child
   SET parent_type_uuid = parent.type_uuid
  FROM public.type_def parent
 WHERE child.tenant_id = parent.tenant_id
   AND child.parent_type_id = parent.type_id
   AND child.parent_type_id IS NOT NULL
   AND child.parent_type_uuid IS DISTINCT FROM parent.type_uuid;

ALTER TABLE public.type_def
  ALTER COLUMN type_uuid SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_type_def_tenant_type_uuid
  ON public.type_def (tenant_id, type_uuid);

CREATE INDEX IF NOT EXISTS ix_type_def_parent_uuid
  ON public.type_def (tenant_id, parent_type_uuid);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conname = 'fk_type_def_parent_uuid'
       AND conrelid = 'public.type_def'::regclass
  ) THEN
    ALTER TABLE public.type_def
      ADD CONSTRAINT fk_type_def_parent_uuid
      FOREIGN KEY (tenant_id, parent_type_uuid)
      REFERENCES public.type_def (tenant_id, type_uuid)
      ON DELETE RESTRICT;
  END IF;
END $$;

-- ----------------------------------------------------------------------------
-- 2. Helper trigger: keep bigint and UUID type references in sync
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.trg_sync_type_def_ref_shadow()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_bigint_col text := TG_ARGV[0];
  v_uuid_col text := TG_ARGV[1];
  v_tenant uuid;
  v_bigint_value_text text;
  v_uuid_value_text text;
  v_type_id bigint;
  v_type_uuid uuid;
BEGIN
  v_tenant := NULLIF(to_jsonb(NEW) ->> 'tenant_id', '')::uuid;

  v_bigint_value_text := NULLIF(to_jsonb(NEW) ->> v_bigint_col, '');
  v_uuid_value_text := NULLIF(to_jsonb(NEW) ->> v_uuid_col, '');

  IF v_bigint_value_text IS NOT NULL THEN
    v_type_id := v_bigint_value_text::bigint;

    SELECT td.type_uuid
      INTO v_type_uuid
      FROM public.type_def td
     WHERE td.tenant_id = v_tenant
       AND td.type_id = v_type_id;

    IF v_type_uuid IS NULL THEN
      RAISE EXCEPTION 'type_def row not found for tenant % and bigint id %', v_tenant, v_type_id;
    END IF;

    NEW := jsonb_populate_record(NEW, jsonb_build_object(v_uuid_col, v_type_uuid));
    RETURN NEW;
  END IF;

  IF v_uuid_value_text IS NOT NULL THEN
    v_type_uuid := v_uuid_value_text::uuid;

    SELECT td.type_id
      INTO v_type_id
      FROM public.type_def td
     WHERE td.tenant_id = v_tenant
       AND td.type_uuid = v_type_uuid;

    IF v_type_id IS NULL THEN
      RAISE EXCEPTION 'type_def row not found for tenant % and uuid %', v_tenant, v_type_uuid;
    END IF;

    NEW := jsonb_populate_record(NEW, jsonb_build_object(v_bigint_col, v_type_id));
    RETURN NEW;
  END IF;

  NEW := jsonb_populate_record(
    NEW,
    jsonb_build_object(
      v_bigint_col, NULL,
      v_uuid_col, NULL
    )
  );

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_type_def_sync_parent_shadow ON public.type_def;
CREATE TRIGGER trg_type_def_sync_parent_shadow
BEFORE INSERT OR UPDATE OF tenant_id, parent_type_id, parent_type_uuid
ON public.type_def
FOR EACH ROW
EXECUTE FUNCTION public.trg_sync_type_def_ref_shadow('parent_type_id', 'parent_type_uuid');

-- ----------------------------------------------------------------------------
-- 3. public.type_closure: add UUID shadow columns and sync with type_def
-- ----------------------------------------------------------------------------
ALTER TABLE public.type_closure
  ADD COLUMN IF NOT EXISTS ancestor_type_uuid uuid,
  ADD COLUMN IF NOT EXISTS descendant_type_uuid uuid;

UPDATE public.type_closure tc
   SET ancestor_type_uuid = a.type_uuid,
       descendant_type_uuid = d.type_uuid
  FROM public.type_def a,
       public.type_def d
 WHERE a.tenant_id = tc.tenant_id
   AND a.type_id = tc.ancestor_type_id
   AND d.tenant_id = tc.tenant_id
   AND d.type_id = tc.descendant_type_id;

CREATE INDEX IF NOT EXISTS ix_type_closure_descendants_uuid
  ON public.type_closure (tenant_id, domain, industry_id, ancestor_type_uuid, depth);

CREATE INDEX IF NOT EXISTS ix_type_closure_ancestors_uuid
  ON public.type_closure (tenant_id, domain, industry_id, descendant_type_uuid, depth);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conname = 'fk_type_closure_ancestor_uuid'
       AND conrelid = 'public.type_closure'::regclass
  ) THEN
    ALTER TABLE public.type_closure
      ADD CONSTRAINT fk_type_closure_ancestor_uuid
      FOREIGN KEY (tenant_id, ancestor_type_uuid)
      REFERENCES public.type_def (tenant_id, type_uuid)
      ON DELETE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conname = 'fk_type_closure_descendant_uuid'
       AND conrelid = 'public.type_closure'::regclass
  ) THEN
    ALTER TABLE public.type_closure
      ADD CONSTRAINT fk_type_closure_descendant_uuid
      FOREIGN KEY (tenant_id, descendant_type_uuid)
      REFERENCES public.type_def (tenant_id, type_uuid)
      ON DELETE CASCADE;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.refresh_type_closure_uuid_scope(
  p_tenant_id uuid,
  p_domain text,
  p_industry_id uuid
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.type_closure tc
     SET ancestor_type_uuid = a.type_uuid,
         descendant_type_uuid = d.type_uuid
    FROM public.type_def a,
         public.type_def d
   WHERE tc.tenant_id = p_tenant_id
     AND tc.domain = p_domain
     AND tc.industry_id IS NOT DISTINCT FROM p_industry_id
     AND a.tenant_id = tc.tenant_id
     AND a.type_id = tc.ancestor_type_id
     AND d.tenant_id = tc.tenant_id
     AND d.type_id = tc.descendant_type_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.trg_type_def_refresh_closure_uuid_shadow()
RETURNS trigger
LANGUAGE plpgsql
AS $$
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

  PERFORM public.refresh_type_closure_uuid_scope(v_tenant, v_domain, v_industry);

  IF TG_OP = 'UPDATE' THEN
    IF (OLD.domain <> NEW.domain)
       OR (OLD.industry_id IS DISTINCT FROM NEW.industry_id) THEN
      PERFORM public.refresh_type_closure_uuid_scope(OLD.tenant_id, OLD.domain, OLD.industry_id);
    END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_type_def_refresh_closure_uuid_shadow ON public.type_def;
CREATE TRIGGER trg_type_def_refresh_closure_uuid_shadow
AFTER INSERT OR UPDATE OR DELETE ON public.type_def
FOR EACH ROW
EXECUTE FUNCTION public.trg_type_def_refresh_closure_uuid_shadow();

-- ----------------------------------------------------------------------------
-- 4. public.entity_attr: UUID shadow reference for type_def value refs
-- ----------------------------------------------------------------------------
ALTER TABLE public.entity_attr
  ADD COLUMN IF NOT EXISTS value_ref_type_uuid uuid;

UPDATE public.entity_attr ea
   SET value_ref_type_uuid = td.type_uuid
  FROM public.type_def td
 WHERE ea.tenant_id = td.tenant_id
   AND ea.value_ref_type_id = td.type_id
   AND ea.value_ref_type_id IS NOT NULL
   AND ea.value_ref_type_uuid IS DISTINCT FROM td.type_uuid;

CREATE INDEX IF NOT EXISTS ix_entity_attr_ref_uuid
  ON public.entity_attr (tenant_id, value_ref_type_uuid)
  WHERE value_ref_type_uuid IS NOT NULL;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conname = 'fk_entity_attr_ref_type_def_uuid'
       AND conrelid = 'public.entity_attr'::regclass
  ) THEN
    ALTER TABLE public.entity_attr
      ADD CONSTRAINT fk_entity_attr_ref_type_def_uuid
      FOREIGN KEY (tenant_id, value_ref_type_uuid)
      REFERENCES public.type_def (tenant_id, type_uuid)
      ON DELETE RESTRICT;
  END IF;
END $$;

DROP TRIGGER IF EXISTS trg_entity_attr_sync_value_ref_shadow ON public.entity_attr;
CREATE TRIGGER trg_entity_attr_sync_value_ref_shadow
BEFORE INSERT OR UPDATE OF tenant_id, value_ref_type_id, value_ref_type_uuid
ON public.entity_attr
FOR EACH ROW
EXECUTE FUNCTION public.trg_sync_type_def_ref_shadow('value_ref_type_id', 'value_ref_type_uuid');

-- ----------------------------------------------------------------------------
-- 5. mes tables: UUID shadow references to type_def
-- ----------------------------------------------------------------------------
ALTER TABLE mes.mst_material_spec
  ADD COLUMN IF NOT EXISTS material_type_uuid uuid;

UPDATE mes.mst_material_spec t
   SET material_type_uuid = td.type_uuid
  FROM public.type_def td
 WHERE t.tenant_id = td.tenant_id
   AND t.material_type_id = td.type_id
   AND t.material_type_uuid IS DISTINCT FROM td.type_uuid;

CREATE INDEX IF NOT EXISTS ix_mst_material_spec_type_uuid
  ON mes.mst_material_spec (tenant_id, material_type_uuid, status);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conname = 'mst_material_spec_material_type_uuid_fk'
       AND conrelid = 'mes.mst_material_spec'::regclass
  ) THEN
    ALTER TABLE mes.mst_material_spec
      ADD CONSTRAINT mst_material_spec_material_type_uuid_fk
      FOREIGN KEY (tenant_id, material_type_uuid)
      REFERENCES public.type_def (tenant_id, type_uuid)
      ON DELETE RESTRICT;
  END IF;
END $$;

DROP TRIGGER IF EXISTS trg_mst_material_spec_sync_type_shadow ON mes.mst_material_spec;
CREATE TRIGGER trg_mst_material_spec_sync_type_shadow
BEFORE INSERT OR UPDATE OF tenant_id, material_type_id, material_type_uuid
ON mes.mst_material_spec
FOR EACH ROW
EXECUTE FUNCTION public.trg_sync_type_def_ref_shadow('material_type_id', 'material_type_uuid');

ALTER TABLE mes.mst_material
  ADD COLUMN IF NOT EXISTS material_type_uuid uuid;

UPDATE mes.mst_material t
   SET material_type_uuid = td.type_uuid
  FROM public.type_def td
 WHERE t.tenant_id = td.tenant_id
   AND t.material_type_id = td.type_id
   AND t.material_type_uuid IS DISTINCT FROM td.type_uuid;

CREATE INDEX IF NOT EXISTS ix_mst_material_type_uuid
  ON mes.mst_material (tenant_id, material_type_uuid, material_spec_id, status);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conname = 'mst_material_material_type_uuid_fk'
       AND conrelid = 'mes.mst_material'::regclass
  ) THEN
    ALTER TABLE mes.mst_material
      ADD CONSTRAINT mst_material_material_type_uuid_fk
      FOREIGN KEY (tenant_id, material_type_uuid)
      REFERENCES public.type_def (tenant_id, type_uuid)
      ON DELETE RESTRICT;
  END IF;
END $$;

DROP TRIGGER IF EXISTS trg_mst_material_sync_type_shadow ON mes.mst_material;
CREATE TRIGGER trg_mst_material_sync_type_shadow
BEFORE INSERT OR UPDATE OF tenant_id, material_type_id, material_type_uuid
ON mes.mst_material
FOR EACH ROW
EXECUTE FUNCTION public.trg_sync_type_def_ref_shadow('material_type_id', 'material_type_uuid');

ALTER TABLE mes.mst_equipment_template
  ADD COLUMN IF NOT EXISTS equipment_type_uuid uuid;

UPDATE mes.mst_equipment_template t
   SET equipment_type_uuid = td.type_uuid
  FROM public.type_def td
 WHERE t.tenant_id = td.tenant_id
   AND t.equipment_type_id = td.type_id
   AND t.equipment_type_uuid IS DISTINCT FROM td.type_uuid;

CREATE INDEX IF NOT EXISTS ix_mst_equipment_template_type_uuid
  ON mes.mst_equipment_template (tenant_id, equipment_type_uuid, status);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conname = 'mst_equipment_template_equipment_type_uuid_fk'
       AND conrelid = 'mes.mst_equipment_template'::regclass
  ) THEN
    ALTER TABLE mes.mst_equipment_template
      ADD CONSTRAINT mst_equipment_template_equipment_type_uuid_fk
      FOREIGN KEY (tenant_id, equipment_type_uuid)
      REFERENCES public.type_def (tenant_id, type_uuid)
      ON DELETE RESTRICT;
  END IF;
END $$;

DROP TRIGGER IF EXISTS trg_mst_equipment_template_sync_type_shadow ON mes.mst_equipment_template;
CREATE TRIGGER trg_mst_equipment_template_sync_type_shadow
BEFORE INSERT OR UPDATE OF tenant_id, equipment_type_id, equipment_type_uuid
ON mes.mst_equipment_template
FOR EACH ROW
EXECUTE FUNCTION public.trg_sync_type_def_ref_shadow('equipment_type_id', 'equipment_type_uuid');

ALTER TABLE mes.mst_step_template
  ADD COLUMN IF NOT EXISTS default_equipment_type_uuid uuid;

UPDATE mes.mst_step_template t
   SET default_equipment_type_uuid = td.type_uuid
  FROM public.type_def td
 WHERE t.tenant_id = td.tenant_id
   AND t.default_equipment_type_id = td.type_id
   AND t.default_equipment_type_uuid IS DISTINCT FROM td.type_uuid;

CREATE INDEX IF NOT EXISTS ix_mst_step_template_default_equipment_type_uuid
  ON mes.mst_step_template (tenant_id, default_equipment_type_uuid, status);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conname = 'mst_step_template_default_equipment_type_uuid_fk'
       AND conrelid = 'mes.mst_step_template'::regclass
  ) THEN
    ALTER TABLE mes.mst_step_template
      ADD CONSTRAINT mst_step_template_default_equipment_type_uuid_fk
      FOREIGN KEY (tenant_id, default_equipment_type_uuid)
      REFERENCES public.type_def (tenant_id, type_uuid)
      ON DELETE RESTRICT;
  END IF;
END $$;

DROP TRIGGER IF EXISTS trg_mst_step_template_sync_type_shadow ON mes.mst_step_template;
CREATE TRIGGER trg_mst_step_template_sync_type_shadow
BEFORE INSERT OR UPDATE OF tenant_id, default_equipment_type_id, default_equipment_type_uuid
ON mes.mst_step_template
FOR EACH ROW
EXECUTE FUNCTION public.trg_sync_type_def_ref_shadow('default_equipment_type_id', 'default_equipment_type_uuid');

ALTER TABLE mes.batch_material_plan
  ADD COLUMN IF NOT EXISTS material_type_uuid uuid;

UPDATE mes.batch_material_plan t
   SET material_type_uuid = td.type_uuid
  FROM public.type_def td
 WHERE t.tenant_id = td.tenant_id
   AND t.material_type_id = td.type_id
   AND t.material_type_uuid IS DISTINCT FROM td.type_uuid;

CREATE INDEX IF NOT EXISTS ix_batch_material_plan_type_uuid
  ON mes.batch_material_plan (tenant_id, material_type_uuid);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
      FROM pg_constraint
     WHERE conname = 'batch_material_plan_material_type_uuid_fk'
       AND conrelid = 'mes.batch_material_plan'::regclass
  ) THEN
    ALTER TABLE mes.batch_material_plan
      ADD CONSTRAINT batch_material_plan_material_type_uuid_fk
      FOREIGN KEY (tenant_id, material_type_uuid)
      REFERENCES public.type_def (tenant_id, type_uuid)
      ON DELETE RESTRICT;
  END IF;
END $$;

DROP TRIGGER IF EXISTS trg_batch_material_plan_sync_type_shadow ON mes.batch_material_plan;
CREATE TRIGGER trg_batch_material_plan_sync_type_shadow
BEFORE INSERT OR UPDATE OF tenant_id, material_type_id, material_type_uuid
ON mes.batch_material_plan
FOR EACH ROW
EXECUTE FUNCTION public.trg_sync_type_def_ref_shadow('material_type_id', 'material_type_uuid');

-- ----------------------------------------------------------------------------
-- 6. Phase 2: destructive DB-side cutover to canonical UUID columns
-- ----------------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_type_def_sync_parent_shadow ON public.type_def;
DROP TRIGGER IF EXISTS trg_type_def_refresh_closure_uuid_shadow ON public.type_def;
DROP TRIGGER IF EXISTS trg_entity_attr_sync_value_ref_shadow ON public.entity_attr;
DROP TRIGGER IF EXISTS trg_mst_material_spec_sync_type_shadow ON mes.mst_material_spec;
DROP TRIGGER IF EXISTS trg_mst_material_sync_type_shadow ON mes.mst_material;
DROP TRIGGER IF EXISTS trg_mst_equipment_template_sync_type_shadow ON mes.mst_equipment_template;
DROP TRIGGER IF EXISTS trg_mst_step_template_sync_type_shadow ON mes.mst_step_template;
DROP TRIGGER IF EXISTS trg_batch_material_plan_sync_type_shadow ON mes.batch_material_plan;

DROP FUNCTION IF EXISTS public.trg_sync_type_def_ref_shadow();
DROP FUNCTION IF EXISTS public.refresh_type_closure_uuid_scope(uuid, text, uuid);
DROP FUNCTION IF EXISTS public.trg_type_def_refresh_closure_uuid_shadow();

DROP TRIGGER IF EXISTS trg_type_def_refresh_closure ON public.type_def;
DROP TRIGGER IF EXISTS trg_type_def_prevent_cycle ON public.type_def;

DROP TRIGGER IF EXISTS trg_mst_material_spec_assert_material_type_domain ON mes.mst_material_spec;
DROP TRIGGER IF EXISTS trg_mst_material_assert_material_type_domain ON mes.mst_material;
DROP TRIGGER IF EXISTS trg_mst_equipment_template_assert_equipment_type_domain ON mes.mst_equipment_template;
DROP TRIGGER IF EXISTS trg_mst_step_template_assert_equipment_type_domain ON mes.mst_step_template;
DROP TRIGGER IF EXISTS trg_batch_material_plan_assert_material_type_domain ON mes.batch_material_plan;

ALTER TABLE public.entity_attr
  DROP CONSTRAINT IF EXISTS fk_entity_attr_ref_type_def,
  DROP CONSTRAINT IF EXISTS fk_entity_attr_ref_type_def_uuid,
  DROP CONSTRAINT IF EXISTS ck_entity_attr_single_value;

ALTER TABLE public.type_closure
  DROP CONSTRAINT IF EXISTS type_closure_pkey,
  DROP CONSTRAINT IF EXISTS type_closure_tenant_id_ancestor_type_id_fkey,
  DROP CONSTRAINT IF EXISTS type_closure_tenant_id_descendant_type_id_fkey,
  DROP CONSTRAINT IF EXISTS fk_type_closure_ancestor_uuid,
  DROP CONSTRAINT IF EXISTS fk_type_closure_descendant_uuid;

ALTER TABLE public.type_def
  DROP CONSTRAINT IF EXISTS fk_type_def_parent,
  DROP CONSTRAINT IF EXISTS fk_type_def_parent_uuid;

ALTER TABLE mes.mst_material_spec
  DROP CONSTRAINT IF EXISTS mst_material_spec_material_type_fk,
  DROP CONSTRAINT IF EXISTS mst_material_spec_material_type_uuid_fk;

ALTER TABLE mes.mst_material
  DROP CONSTRAINT IF EXISTS mst_material_material_type_fk,
  DROP CONSTRAINT IF EXISTS mst_material_material_type_uuid_fk;

ALTER TABLE mes.mst_equipment_template
  DROP CONSTRAINT IF EXISTS mst_equipment_template_equipment_type_fk,
  DROP CONSTRAINT IF EXISTS mst_equipment_template_equipment_type_uuid_fk;

ALTER TABLE mes.mst_step_template
  DROP CONSTRAINT IF EXISTS mst_step_template_default_equipment_type_fk,
  DROP CONSTRAINT IF EXISTS mst_step_template_default_equipment_type_uuid_fk;

ALTER TABLE mes.batch_material_plan
  DROP CONSTRAINT IF EXISTS batch_material_plan_material_type_fk,
  DROP CONSTRAINT IF EXISTS batch_material_plan_material_type_uuid_fk;

DROP INDEX IF EXISTS public.ix_entity_attr_ref;
DROP INDEX IF EXISTS public.ix_entity_attr_ref_uuid;

DROP INDEX IF EXISTS public.ix_type_closure_descendants;
DROP INDEX IF EXISTS public.ix_type_closure_ancestors;
DROP INDEX IF EXISTS public.ix_type_closure_descendants_uuid;
DROP INDEX IF EXISTS public.ix_type_closure_ancestors_uuid;

DROP INDEX IF EXISTS public.ix_type_def_parent;
DROP INDEX IF EXISTS public.ix_type_def_parent_uuid;
DROP INDEX IF EXISTS public.ix_type_def_sort;
DROP INDEX IF EXISTS public.uq_type_def_tenant_type_uuid;

DROP INDEX IF EXISTS mes.idx_mst_material_spec_tenant_type;
DROP INDEX IF EXISTS mes.ix_mst_material_spec_type_uuid;
DROP INDEX IF EXISTS mes.idx_mst_material_tenant_type_spec;
DROP INDEX IF EXISTS mes.ix_mst_material_type_uuid;
DROP INDEX IF EXISTS mes.idx_mst_equipment_template_tenant_type;
DROP INDEX IF EXISTS mes.ix_mst_equipment_template_type_uuid;
DROP INDEX IF EXISTS mes.ix_mst_step_template_default_equipment_type_uuid;
DROP INDEX IF EXISTS mes.ix_batch_material_plan_type_uuid;

ALTER TABLE public.type_def DROP CONSTRAINT IF EXISTS type_def_pkey;

ALTER TABLE public.type_def
  RENAME COLUMN type_id TO type_id_bigint_legacy;
ALTER TABLE public.type_def
  RENAME COLUMN parent_type_id TO parent_type_id_bigint_legacy;
ALTER TABLE public.type_def
  RENAME COLUMN type_uuid TO type_id;
ALTER TABLE public.type_def
  RENAME COLUMN parent_type_uuid TO parent_type_id;

ALTER TABLE public.type_closure
  RENAME COLUMN ancestor_type_id TO ancestor_type_id_bigint_legacy;
ALTER TABLE public.type_closure
  RENAME COLUMN descendant_type_id TO descendant_type_id_bigint_legacy;
ALTER TABLE public.type_closure
  RENAME COLUMN ancestor_type_uuid TO ancestor_type_id;
ALTER TABLE public.type_closure
  RENAME COLUMN descendant_type_uuid TO descendant_type_id;

ALTER TABLE public.entity_attr
  RENAME COLUMN value_ref_type_id TO value_ref_type_id_bigint_legacy;
ALTER TABLE public.entity_attr
  RENAME COLUMN value_ref_type_uuid TO value_ref_type_id;

ALTER TABLE mes.mst_material_spec
  RENAME COLUMN material_type_id TO material_type_id_bigint_legacy;
ALTER TABLE mes.mst_material_spec
  RENAME COLUMN material_type_uuid TO material_type_id;

ALTER TABLE mes.mst_material
  RENAME COLUMN material_type_id TO material_type_id_bigint_legacy;
ALTER TABLE mes.mst_material
  RENAME COLUMN material_type_uuid TO material_type_id;

ALTER TABLE mes.mst_equipment_template
  RENAME COLUMN equipment_type_id TO equipment_type_id_bigint_legacy;
ALTER TABLE mes.mst_equipment_template
  RENAME COLUMN equipment_type_uuid TO equipment_type_id;

ALTER TABLE mes.mst_step_template
  RENAME COLUMN default_equipment_type_id TO default_equipment_type_id_bigint_legacy;
ALTER TABLE mes.mst_step_template
  RENAME COLUMN default_equipment_type_uuid TO default_equipment_type_id;

ALTER TABLE mes.batch_material_plan
  RENAME COLUMN material_type_id TO material_type_id_bigint_legacy;
ALTER TABLE mes.batch_material_plan
  RENAME COLUMN material_type_uuid TO material_type_id;

ALTER TABLE public.type_def
  ADD CONSTRAINT type_def_pkey PRIMARY KEY (tenant_id, type_id);

ALTER TABLE public.type_def
  ADD CONSTRAINT fk_type_def_parent
  FOREIGN KEY (tenant_id, parent_type_id)
  REFERENCES public.type_def (tenant_id, type_id)
  ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS ix_type_def_parent
  ON public.type_def (tenant_id, parent_type_id);

CREATE INDEX IF NOT EXISTS ix_type_def_sort
  ON public.type_def (tenant_id, domain, industry_id, parent_type_id, sort_order, code);

ALTER TABLE public.type_closure
  ADD CONSTRAINT type_closure_pkey
  PRIMARY KEY (tenant_id, domain, industry_id, ancestor_type_id, descendant_type_id);

ALTER TABLE public.type_closure
  ADD CONSTRAINT fk_type_closure_ancestor
  FOREIGN KEY (tenant_id, ancestor_type_id)
  REFERENCES public.type_def (tenant_id, type_id)
  ON DELETE CASCADE;

ALTER TABLE public.type_closure
  ADD CONSTRAINT fk_type_closure_descendant
  FOREIGN KEY (tenant_id, descendant_type_id)
  REFERENCES public.type_def (tenant_id, type_id)
  ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS ix_type_closure_descendants
  ON public.type_closure (tenant_id, domain, industry_id, ancestor_type_id, depth);

CREATE INDEX IF NOT EXISTS ix_type_closure_ancestors
  ON public.type_closure (tenant_id, domain, industry_id, descendant_type_id, depth);

ALTER TABLE public.entity_attr
  ADD CONSTRAINT ck_entity_attr_single_value
  CHECK (
    (CASE WHEN value_text IS NULL THEN 0 ELSE 1 END) +
    (CASE WHEN value_num  IS NULL THEN 0 ELSE 1 END) +
    (CASE WHEN value_bool IS NULL THEN 0 ELSE 1 END) +
    (CASE WHEN value_date IS NULL THEN 0 ELSE 1 END) +
    (CASE WHEN value_ts   IS NULL THEN 0 ELSE 1 END) +
    (CASE WHEN value_json IS NULL THEN 0 ELSE 1 END) +
    (CASE WHEN value_ref_type_id IS NULL THEN 0 ELSE 1 END)
    <= 1
  );

ALTER TABLE public.entity_attr
  ADD CONSTRAINT fk_entity_attr_ref_type_def
  FOREIGN KEY (tenant_id, value_ref_type_id)
  REFERENCES public.type_def (tenant_id, type_id)
  ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS ix_entity_attr_ref
  ON public.entity_attr (tenant_id, value_ref_type_id)
  WHERE value_ref_type_id IS NOT NULL;

ALTER TABLE mes.mst_material_spec
  ADD CONSTRAINT mst_material_spec_material_type_fk
  FOREIGN KEY (tenant_id, material_type_id)
  REFERENCES public.type_def (tenant_id, type_id)
  ON DELETE RESTRICT;

ALTER TABLE mes.mst_material
  ADD CONSTRAINT mst_material_material_type_fk
  FOREIGN KEY (tenant_id, material_type_id)
  REFERENCES public.type_def (tenant_id, type_id)
  ON DELETE RESTRICT;

ALTER TABLE mes.mst_equipment_template
  ADD CONSTRAINT mst_equipment_template_equipment_type_fk
  FOREIGN KEY (tenant_id, equipment_type_id)
  REFERENCES public.type_def (tenant_id, type_id)
  ON DELETE RESTRICT;

ALTER TABLE mes.mst_step_template
  ADD CONSTRAINT mst_step_template_default_equipment_type_fk
  FOREIGN KEY (tenant_id, default_equipment_type_id)
  REFERENCES public.type_def (tenant_id, type_id)
  ON DELETE RESTRICT;

ALTER TABLE mes.batch_material_plan
  ADD CONSTRAINT batch_material_plan_material_type_fk
  FOREIGN KEY (tenant_id, material_type_id)
  REFERENCES public.type_def (tenant_id, type_id)
  ON DELETE RESTRICT;

CREATE INDEX IF NOT EXISTS idx_mst_material_spec_tenant_type
  ON mes.mst_material_spec (tenant_id, material_type_id, status);

CREATE INDEX IF NOT EXISTS idx_mst_material_tenant_type_spec
  ON mes.mst_material (tenant_id, material_type_id, material_spec_id, status);

CREATE INDEX IF NOT EXISTS idx_mst_equipment_template_tenant_type
  ON mes.mst_equipment_template (tenant_id, equipment_type_id, status);

CREATE INDEX IF NOT EXISTS idx_batch_material_plan_type
  ON mes.batch_material_plan (tenant_id, material_type_id);

CREATE OR REPLACE FUNCTION public.rebuild_type_closure(
  p_tenant_id uuid,
  p_domain text,
  p_industry_id uuid
)
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  DELETE FROM public.type_closure
   WHERE tenant_id = p_tenant_id
     AND domain = p_domain
     AND industry_id IS NOT DISTINCT FROM p_industry_id;

  INSERT INTO public.type_closure(
    tenant_id, domain, industry_id,
    ancestor_type_id, descendant_type_id, depth
  )
  WITH RECURSIVE walk AS (
    SELECT
      td.tenant_id,
      td.domain,
      td.industry_id,
      td.type_id AS ancestor_type_id,
      td.type_id AS descendant_type_id,
      0 AS depth
    FROM public.type_def td
    WHERE td.tenant_id = p_tenant_id
      AND td.domain = p_domain
      AND td.industry_id IS NOT DISTINCT FROM p_industry_id

    UNION ALL

    SELECT
      w.tenant_id,
      w.domain,
      w.industry_id,
      w.ancestor_type_id,
      c.type_id AS descendant_type_id,
      w.depth + 1 AS depth
    FROM walk w
    JOIN public.type_def c
      ON c.tenant_id = w.tenant_id
     AND c.domain = w.domain
     AND c.industry_id IS NOT DISTINCT FROM w.industry_id
     AND c.parent_type_id = w.descendant_type_id
  )
  SELECT tenant_id, domain, industry_id, ancestor_type_id, descendant_type_id, depth
  FROM walk;
END $$;

CREATE OR REPLACE FUNCTION public.trg_type_def_refresh_closure()
RETURNS trigger
LANGUAGE plpgsql
AS $$
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

  PERFORM public.rebuild_type_closure(v_tenant, v_domain, v_industry);

  IF TG_OP = 'UPDATE' THEN
    IF (OLD.domain <> NEW.domain)
       OR (OLD.industry_id IS DISTINCT FROM NEW.industry_id) THEN
      PERFORM public.rebuild_type_closure(OLD.tenant_id, OLD.domain, OLD.industry_id);
    END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END $$;

CREATE TRIGGER trg_type_def_refresh_closure
AFTER INSERT OR UPDATE OR DELETE ON public.type_def
FOR EACH ROW
EXECUTE FUNCTION public.trg_type_def_refresh_closure();

CREATE OR REPLACE FUNCTION public.trg_type_def_prevent_cycle()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_found int;
BEGIN
  IF NEW.parent_type_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.parent_type_id = NEW.type_id THEN
    RAISE EXCEPTION 'type_def cycle: parent cannot be self (type_id=%)', NEW.type_id;
  END IF;

  IF NOT EXISTS (
    SELECT 1
      FROM public.type_def p
     WHERE p.tenant_id = NEW.tenant_id
       AND p.type_id = NEW.parent_type_id
       AND p.domain = NEW.domain
       AND p.industry_id IS NOT DISTINCT FROM NEW.industry_id
  ) THEN
    RAISE EXCEPTION 'type_def invalid parent: parent must exist in same tenant/domain/industry scope';
  END IF;

  WITH RECURSIVE subtree AS (
    SELECT td.tenant_id, td.type_id
      FROM public.type_def td
     WHERE td.tenant_id = NEW.tenant_id
       AND td.type_id = NEW.type_id

    UNION ALL

    SELECT c.tenant_id, c.type_id
      FROM public.type_def c
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

CREATE TRIGGER trg_type_def_prevent_cycle
BEFORE INSERT OR UPDATE OF parent_type_id, domain, industry_id ON public.type_def
FOR EACH ROW
EXECUTE FUNCTION public.trg_type_def_prevent_cycle();

CREATE OR REPLACE FUNCTION mes.trg_assert_type_def_domain()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_type_id uuid;
  v_expected_domain text;
  v_actual_domain text;
BEGIN
  IF NEW.tenant_id IS NULL THEN
    NEW.tenant_id := app_current_tenant_id();
  END IF;

  v_type_id := NULLIF(to_jsonb(NEW) ->> TG_ARGV[0], '')::uuid;
  v_expected_domain := TG_ARGV[1];

  IF v_type_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT td.domain
    INTO v_actual_domain
    FROM public.type_def td
   WHERE td.tenant_id = NEW.tenant_id
     AND td.type_id = v_type_id;

  IF v_actual_domain IS NULL THEN
    RAISE EXCEPTION 'Type % does not exist for tenant %', v_type_id, NEW.tenant_id;
  END IF;

  IF v_actual_domain <> v_expected_domain THEN
    RAISE EXCEPTION 'Type % must use type_def domain %, got %', v_type_id, v_expected_domain, v_actual_domain;
  END IF;

  RETURN NEW;
END;
$$;

CREATE TRIGGER trg_mst_material_spec_assert_material_type_domain
BEFORE INSERT OR UPDATE OF tenant_id, material_type_id ON mes.mst_material_spec
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_type_def_domain('material_type_id', 'material_type');

CREATE TRIGGER trg_mst_material_assert_material_type_domain
BEFORE INSERT OR UPDATE OF tenant_id, material_type_id ON mes.mst_material
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_type_def_domain('material_type_id', 'material_type');

CREATE TRIGGER trg_mst_equipment_template_assert_equipment_type_domain
BEFORE INSERT OR UPDATE OF tenant_id, equipment_type_id ON mes.mst_equipment_template
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_type_def_domain('equipment_type_id', 'equipment_type');

CREATE TRIGGER trg_mst_step_template_assert_equipment_type_domain
BEFORE INSERT OR UPDATE OF tenant_id, default_equipment_type_id ON mes.mst_step_template
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_type_def_domain('default_equipment_type_id', 'equipment_type');

CREATE TRIGGER trg_batch_material_plan_assert_material_type_domain
BEFORE INSERT OR UPDATE OF tenant_id, material_type_id ON mes.batch_material_plan
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_type_def_domain('material_type_id', 'material_type');

DO $$
DECLARE
  v_fn text;
BEGIN
  SELECT pg_get_functiondef('public.product_move(jsonb)'::regprocedure)
    INTO v_fn;

  IF v_fn IS NULL THEN
    RAISE EXCEPTION 'public.product_move(jsonb) not found';
  END IF;

  v_fn := replace(
    v_fn,
    'v_beer_category_type_id bigint;',
    'v_beer_category_type_id uuid;'
  );

  EXECUTE v_fn;
END $$;

ALTER TABLE public.type_closure
  DROP COLUMN ancestor_type_id_bigint_legacy,
  DROP COLUMN descendant_type_id_bigint_legacy;

ALTER TABLE public.entity_attr
  DROP COLUMN value_ref_type_id_bigint_legacy;

ALTER TABLE mes.mst_material_spec
  DROP COLUMN material_type_id_bigint_legacy;

ALTER TABLE mes.mst_material
  DROP COLUMN material_type_id_bigint_legacy;

ALTER TABLE mes.mst_equipment_template
  DROP COLUMN equipment_type_id_bigint_legacy;

ALTER TABLE mes.mst_step_template
  DROP COLUMN default_equipment_type_id_bigint_legacy;

ALTER TABLE mes.batch_material_plan
  DROP COLUMN material_type_id_bigint_legacy;

ALTER TABLE public.type_def
  DROP COLUMN parent_type_id_bigint_legacy,
  DROP COLUMN type_id_bigint_legacy;

COMMENT ON COLUMN public.type_def.type_id IS
  'Canonical UUID key for type_def after bigint-to-uuid cutover.';

COMMENT ON COLUMN public.type_def.parent_type_id IS
  'Canonical UUID parent reference for type_def after bigint-to-uuid cutover.';
