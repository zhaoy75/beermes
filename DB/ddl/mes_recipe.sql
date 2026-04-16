CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE EXTENSION IF NOT EXISTS btree_gist;

CREATE SCHEMA IF NOT EXISTS mes;

GRANT USAGE ON SCHEMA mes TO anon;
GRANT USAGE ON SCHEMA mes TO authenticated;
GRANT USAGE ON SCHEMA mes TO service_role;

DO $$
BEGIN
  CREATE TYPE mes.master_status AS ENUM ('active', 'inactive');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE mes.recipe_version_status AS ENUM ('draft', 'in_review', 'approved', 'obsolete', 'archived');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE mes.approval_decision AS ENUM ('pending', 'approved', 'rejected', 'skipped');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE mes.batch_step_status AS ENUM ('open', 'ready', 'in_progress', 'hold', 'completed', 'skipped', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE mes.execution_event_type AS ENUM (
    'create',
    'release',
    'start',
    'pause',
    'resume',
    'complete',
    'parameter_capture',
    'qa_record',
    'material_issue',
    'equipment_assign',
    'deviation',
    'comment'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE mes.deviation_severity AS ENUM ('minor', 'major', 'critical');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE mes.deviation_status AS ENUM ('open', 'approved', 'rejected', 'closed');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE mes.equipment_reservation_type AS ENUM ('batch', 'maintenance', 'cip', 'manual_block');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE mes.equipment_reservation_status AS ENUM ('draft', 'reserved', 'confirmed', 'in_progress', 'completed', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE mes.equipment_assignment_role AS ENUM ('main', 'aux', 'qc', 'cleaning');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE mes.batch_equipment_assignment_status AS ENUM ('assigned', 'in_use', 'done', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

CREATE OR REPLACE FUNCTION mes.trg_set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$;

CREATE TABLE IF NOT EXISTS mes.mst_recipe (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  recipe_code text NOT NULL,
  recipe_name text NOT NULL,
  recipe_category text NULL,
  industry_type text NULL,
  status mes.master_status NOT NULL DEFAULT 'active',
  current_version_id uuid NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NULL,
  CONSTRAINT mst_recipe_uq_tenant_code UNIQUE (tenant_id, recipe_code)
);

CREATE TABLE IF NOT EXISTS mes.mst_material (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  material_code text NOT NULL,
  material_name text NOT NULL,
  material_type_id uuid NULL,
  base_uom_id uuid NULL REFERENCES public.mst_uom(id),
  material_category text NULL,
  is_batch_managed boolean NOT NULL DEFAULT false,
  is_lot_managed boolean NOT NULL DEFAULT false,
  meta_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  status mes.master_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NULL,
  CONSTRAINT mst_material_uq_tenant_code UNIQUE (tenant_id, material_code),
  CONSTRAINT mst_material_material_type_fk
    FOREIGN KEY (tenant_id, material_type_id)
    REFERENCES public.type_def(tenant_id, type_id)
    ON DELETE RESTRICT,
  CONSTRAINT mst_material_meta_json_object_ck CHECK (jsonb_typeof(meta_json) = 'object')
);

CREATE TABLE IF NOT EXISTS mes.mst_equipment_template (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  template_code text NOT NULL,
  template_name text NOT NULL,
  equipment_type_id uuid NOT NULL,
  capacity_min numeric NULL,
  capacity_max numeric NULL,
  capacity_uom_id uuid NULL REFERENCES public.mst_uom(id),
  capability_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  status mes.master_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NULL,
  CONSTRAINT mst_equipment_template_uq_tenant_code UNIQUE (tenant_id, template_code),
  CONSTRAINT mst_equipment_template_equipment_type_fk
    FOREIGN KEY (tenant_id, equipment_type_id)
    REFERENCES public.type_def(tenant_id, type_id)
    ON DELETE RESTRICT,
  CONSTRAINT mst_equipment_template_capacity_range_ck CHECK (
    capacity_min IS NULL
    OR capacity_max IS NULL
    OR capacity_min <= capacity_max
  ),
  CONSTRAINT mst_equipment_template_capability_json_object_ck CHECK (jsonb_typeof(capability_json) = 'object')
);

CREATE TABLE IF NOT EXISTS mes.mst_parameter_def (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  parameter_code text NOT NULL,
  parameter_name text NOT NULL,
  data_type text NOT NULL,
  default_uom_id uuid NULL REFERENCES public.mst_uom(id),
  precision_digits integer NULL,
  min_value numeric NULL,
  max_value numeric NULL,
  status mes.master_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NULL,
  CONSTRAINT mst_parameter_def_uq_tenant_code UNIQUE (tenant_id, parameter_code),
  CONSTRAINT mst_parameter_def_range_ck CHECK (
    min_value IS NULL
    OR max_value IS NULL
    OR min_value <= max_value
  )
);

CREATE TABLE IF NOT EXISTS mes.mst_quality_check (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  check_code text NOT NULL,
  check_name text NOT NULL,
  check_type text NOT NULL,
  parameter_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  status mes.master_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NULL,
  CONSTRAINT mst_quality_check_uq_tenant_code UNIQUE (tenant_id, check_code),
  CONSTRAINT mst_quality_check_parameter_json_object_ck CHECK (jsonb_typeof(parameter_json) = 'object')
);

CREATE TABLE IF NOT EXISTS mes.mst_step_template (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  step_template_code text NOT NULL,
  step_template_name text NOT NULL,
  step_type text NOT NULL,
  industry_type text NULL,
  default_instructions text NULL,
  default_duration_sec integer NULL,
  parameter_template_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  default_equipment_type_id uuid NULL,
  default_equipment_requirement_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  default_quality_check_json jsonb NOT NULL DEFAULT '[]'::jsonb,
  default_material_role text NULL,
  sort_no integer NOT NULL DEFAULT 0,
  status mes.master_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NULL,
  CONSTRAINT mst_step_template_uq_tenant_code UNIQUE (tenant_id, step_template_code),
  CONSTRAINT mst_step_template_default_equipment_type_fk
    FOREIGN KEY (tenant_id, default_equipment_type_id)
    REFERENCES public.type_def(tenant_id, type_id)
    ON DELETE RESTRICT,
  CONSTRAINT mst_step_template_parameter_json_object_ck CHECK (jsonb_typeof(parameter_template_json) = 'object'),
  CONSTRAINT mst_step_template_equipment_json_object_ck CHECK (jsonb_typeof(default_equipment_requirement_json) = 'object'),
  CONSTRAINT mst_step_template_quality_json_array_ck CHECK (jsonb_typeof(default_quality_check_json) = 'array')
);

CREATE TABLE IF NOT EXISTS mes.mst_recipe_version (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  recipe_id uuid NOT NULL REFERENCES mes.mst_recipe(id) ON DELETE CASCADE,
  version_no integer NOT NULL,
  version_label text NULL,
  recipe_body_json jsonb NOT NULL,
  resolved_reference_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  schema_code text NULL,
  template_code text NULL,
  status mes.recipe_version_status NOT NULL DEFAULT 'draft',
  effective_from timestamptz NULL,
  effective_to timestamptz NULL,
  change_summary text NULL,
  body_hash text GENERATED ALWAYS AS (encode(digest(recipe_body_json::text, 'sha256'), 'hex')) STORED,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  approved_at timestamptz NULL,
  approved_by uuid NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NULL,
  CONSTRAINT mst_recipe_version_uq_tenant_recipe_version UNIQUE (tenant_id, recipe_id, version_no),
  CONSTRAINT mst_recipe_version_recipe_body_json_object_ck CHECK (jsonb_typeof(recipe_body_json) = 'object'),
  CONSTRAINT mst_recipe_version_resolved_reference_json_object_ck CHECK (jsonb_typeof(resolved_reference_json) = 'object'),
  CONSTRAINT mst_recipe_version_effective_range_ck CHECK (
    effective_from IS NULL
    OR effective_to IS NULL
    OR effective_from <= effective_to
  )
);

ALTER TABLE mes.mst_recipe
  DROP CONSTRAINT IF EXISTS mst_recipe_current_version_fk;

ALTER TABLE mes.mst_recipe
  ADD CONSTRAINT mst_recipe_current_version_fk
  FOREIGN KEY (current_version_id)
  REFERENCES mes.mst_recipe_version(id)
  ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS mes.recipe_approval_flow_def (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  flow_code text NOT NULL,
  recipe_category text NULL,
  industry_type text NULL,
  step_no integer NOT NULL,
  approval_role text NOT NULL,
  is_required boolean NOT NULL DEFAULT true,
  status mes.master_status NOT NULL DEFAULT 'active',
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NULL,
  CONSTRAINT recipe_approval_flow_def_uq_tenant_flow_step UNIQUE (tenant_id, flow_code, step_no)
);

CREATE TABLE IF NOT EXISTS mes.recipe_approval_event (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  recipe_version_id uuid NOT NULL REFERENCES mes.mst_recipe_version(id) ON DELETE CASCADE,
  flow_def_id uuid NULL REFERENCES mes.recipe_approval_flow_def(id) ON DELETE SET NULL,
  step_no integer NOT NULL,
  approval_role text NOT NULL,
  approver_user_id uuid NULL,
  decision mes.approval_decision NOT NULL DEFAULT 'pending',
  decision_at timestamptz NULL,
  comment text NULL,
  e_signature text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  CONSTRAINT recipe_approval_event_uq_tenant_version_step UNIQUE (tenant_id, recipe_version_id, step_no)
);

CREATE TABLE IF NOT EXISTS mes.recipe_change_history (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  recipe_version_id uuid NOT NULL REFERENCES mes.mst_recipe_version(id) ON DELETE CASCADE,
  event_type text NOT NULL,
  changed_at timestamptz NOT NULL DEFAULT now(),
  changed_by uuid NULL,
  diff_doc jsonb NOT NULL DEFAULT '{}'::jsonb,
  reason_code text NULL,
  reason_text text NULL,
  comment text NULL,
  CONSTRAINT recipe_change_history_diff_doc_object_ck CHECK (jsonb_typeof(diff_doc) = 'object')
);

ALTER TABLE public.mes_batches
  ADD COLUMN IF NOT EXISTS mes_recipe_id uuid NULL,
  ADD COLUMN IF NOT EXISTS recipe_version_id uuid NULL,
  ADD COLUMN IF NOT EXISTS released_reference_json jsonb NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE public.mes_batches
  DROP CONSTRAINT IF EXISTS mes_batches_mes_recipe_id_fkey;

ALTER TABLE public.mes_batches
  ADD CONSTRAINT mes_batches_mes_recipe_id_fkey
  FOREIGN KEY (mes_recipe_id)
  REFERENCES mes.mst_recipe(id)
  ON DELETE SET NULL;

ALTER TABLE public.mes_batches
  DROP CONSTRAINT IF EXISTS mes_batches_recipe_version_id_fkey;

ALTER TABLE public.mes_batches
  ADD CONSTRAINT mes_batches_recipe_version_id_fkey
  FOREIGN KEY (recipe_version_id)
  REFERENCES mes.mst_recipe_version(id)
  ON DELETE SET NULL;

ALTER TABLE public.mes_batches
  DROP CONSTRAINT IF EXISTS mes_batches_released_reference_json_object_ck;

ALTER TABLE public.mes_batches
  ADD CONSTRAINT mes_batches_released_reference_json_object_ck
  CHECK (jsonb_typeof(released_reference_json) = 'object');

CREATE TABLE IF NOT EXISTS mes.batch_step (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  batch_id uuid NOT NULL REFERENCES public.mes_batches(id) ON DELETE CASCADE,
  step_no integer NOT NULL,
  step_code text NOT NULL,
  step_name text NOT NULL,
  step_template_code text NULL,
  planned_duration_sec integer NULL,
  status mes.batch_step_status NOT NULL DEFAULT 'open',
  planned_params jsonb NOT NULL DEFAULT '{}'::jsonb,
  actual_params jsonb NOT NULL DEFAULT '{}'::jsonb,
  quality_checks_json jsonb NOT NULL DEFAULT '[]'::jsonb,
  snapshot_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  started_at timestamptz NULL,
  ended_at timestamptz NULL,
  notes text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NULL,
  CONSTRAINT batch_step_uq_tenant_batch_step_no UNIQUE (tenant_id, batch_id, step_no),
  CONSTRAINT batch_step_planned_params_object_ck CHECK (jsonb_typeof(planned_params) = 'object'),
  CONSTRAINT batch_step_actual_params_object_ck CHECK (jsonb_typeof(actual_params) = 'object'),
  CONSTRAINT batch_step_quality_checks_array_ck CHECK (jsonb_typeof(quality_checks_json) = 'array'),
  CONSTRAINT batch_step_snapshot_object_ck CHECK (jsonb_typeof(snapshot_json) = 'object'),
  CONSTRAINT batch_step_time_range_ck CHECK (
    started_at IS NULL
    OR ended_at IS NULL
    OR started_at <= ended_at
  )
);

CREATE TABLE IF NOT EXISTS mes.batch_material_plan (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  batch_id uuid NOT NULL REFERENCES public.mes_batches(id) ON DELETE CASCADE,
  batch_step_id uuid NULL REFERENCES mes.batch_step(id) ON DELETE CASCADE,
  material_role text NULL,
  material_type_id uuid NULL,
  planned_qty numeric NOT NULL,
  uom_id uuid NOT NULL REFERENCES public.mst_uom(id),
  requirement_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  snapshot_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  CONSTRAINT batch_material_plan_material_type_fk
    FOREIGN KEY (tenant_id, material_type_id)
    REFERENCES public.type_def(tenant_id, type_id)
    ON DELETE RESTRICT,
  CONSTRAINT batch_material_plan_qty_ck CHECK (planned_qty >= 0),
  CONSTRAINT batch_material_plan_requirement_object_ck CHECK (jsonb_typeof(requirement_json) = 'object'),
  CONSTRAINT batch_material_plan_snapshot_object_ck CHECK (jsonb_typeof(snapshot_json) = 'object')
);

CREATE TABLE IF NOT EXISTS mes.batch_material_actual (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  batch_id uuid NOT NULL REFERENCES public.mes_batches(id) ON DELETE CASCADE,
  batch_step_id uuid NULL REFERENCES mes.batch_step(id) ON DELETE CASCADE,
  material_id uuid NULL REFERENCES mes.mst_material(id) ON DELETE SET NULL,
  lot_id uuid NULL,
  actual_qty numeric NOT NULL,
  uom_id uuid NOT NULL REFERENCES public.mst_uom(id),
  consumed_at timestamptz NOT NULL DEFAULT now(),
  snapshot_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  note text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  CONSTRAINT batch_material_actual_qty_ck CHECK (actual_qty >= 0),
  CONSTRAINT batch_material_actual_snapshot_object_ck CHECK (jsonb_typeof(snapshot_json) = 'object')
);

CREATE TABLE IF NOT EXISTS mes.batch_equipment_assignment (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  batch_id uuid NOT NULL REFERENCES public.mes_batches(id) ON DELETE CASCADE,
  batch_step_id uuid NULL REFERENCES mes.batch_step(id) ON DELETE CASCADE,
  reservation_id uuid NULL,
  equipment_id uuid NOT NULL REFERENCES public.mst_equipment(id),
  assignment_role mes.equipment_assignment_role NULL,
  status mes.batch_equipment_assignment_status NOT NULL DEFAULT 'assigned',
  assigned_at timestamptz NOT NULL DEFAULT now(),
  released_at timestamptz NULL,
  snapshot_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  note text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NULL,
  CONSTRAINT batch_equipment_assignment_snapshot_object_ck CHECK (jsonb_typeof(snapshot_json) = 'object'),
  CONSTRAINT batch_equipment_assignment_time_range_ck CHECK (
    released_at IS NULL
    OR assigned_at <= released_at
  )
);

ALTER TABLE mes.batch_equipment_assignment
  ADD COLUMN IF NOT EXISTS reservation_id uuid NULL;

ALTER TABLE mes.batch_equipment_assignment
  ADD COLUMN IF NOT EXISTS status mes.batch_equipment_assignment_status NOT NULL DEFAULT 'assigned';

ALTER TABLE mes.batch_equipment_assignment
  ADD COLUMN IF NOT EXISTS note text NULL;

ALTER TABLE mes.batch_equipment_assignment
  ADD COLUMN IF NOT EXISTS updated_at timestamptz NOT NULL DEFAULT now();

ALTER TABLE mes.batch_equipment_assignment
  ADD COLUMN IF NOT EXISTS updated_by uuid NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'mes'
      AND table_name = 'batch_equipment_assignment'
      AND column_name = 'assignment_role'
      AND udt_name = 'text'
  ) THEN
    IF EXISTS (
      SELECT 1
      FROM mes.batch_equipment_assignment
      WHERE assignment_role IS NOT NULL
        AND lower(assignment_role) NOT IN ('main', 'aux', 'qc', 'cleaning')
    ) THEN
      RAISE EXCEPTION 'Existing batch_equipment_assignment.assignment_role contains values outside MAIN/AUX/QC/CLEANING';
    END IF;

    ALTER TABLE mes.batch_equipment_assignment
      ALTER COLUMN assignment_role
      TYPE mes.equipment_assignment_role
      USING lower(assignment_role)::mes.equipment_assignment_role;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS mes.equipment_reservation (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  site_id uuid NOT NULL REFERENCES public.mst_sites(id),
  equipment_id uuid NOT NULL REFERENCES public.mst_equipment(id),
  reservation_type mes.equipment_reservation_type NOT NULL,
  batch_id uuid NULL REFERENCES public.mes_batches(id) ON DELETE CASCADE,
  batch_step_id uuid NULL REFERENCES mes.batch_step(id) ON DELETE CASCADE,
  source_type text NULL,
  source_id uuid NULL,
  start_at timestamptz NOT NULL,
  end_at timestamptz NOT NULL,
  status mes.equipment_reservation_status NOT NULL DEFAULT 'reserved',
  priority integer NOT NULL DEFAULT 100,
  exclusive_use boolean NOT NULL DEFAULT true,
  note text NULL,
  meta_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NULL,
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NULL,
  CONSTRAINT equipment_reservation_time_range_ck CHECK (start_at < end_at),
  CONSTRAINT equipment_reservation_priority_ck CHECK (priority >= 0),
  CONSTRAINT equipment_reservation_meta_json_object_ck CHECK (jsonb_typeof(meta_json) = 'object'),
  CONSTRAINT equipment_reservation_step_requires_batch_ck CHECK (
    batch_step_id IS NULL
    OR batch_id IS NOT NULL
  ),
  CONSTRAINT equipment_reservation_batch_type_ck CHECK (
    reservation_type <> 'batch'
    OR batch_id IS NOT NULL
  ),
  CONSTRAINT equipment_reservation_source_pair_ck CHECK (
    (source_type IS NULL AND source_id IS NULL)
    OR (source_type IS NOT NULL AND source_id IS NOT NULL)
  )
);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'batch_equipment_assignment_reservation_fk'
      AND conrelid = 'mes.batch_equipment_assignment'::regclass
  ) THEN
    ALTER TABLE mes.batch_equipment_assignment
      ADD CONSTRAINT batch_equipment_assignment_reservation_fk
      FOREIGN KEY (reservation_id)
      REFERENCES mes.equipment_reservation(id)
      ON DELETE SET NULL;
  END IF;
END $$;

CREATE TABLE IF NOT EXISTS mes.batch_execution_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  batch_id uuid NOT NULL REFERENCES public.mes_batches(id) ON DELETE CASCADE,
  batch_step_id uuid NULL REFERENCES mes.batch_step(id) ON DELETE CASCADE,
  event_type mes.execution_event_type NOT NULL,
  event_at timestamptz NOT NULL DEFAULT now(),
  actor_user_id uuid NULL,
  event_data jsonb NOT NULL DEFAULT '{}'::jsonb,
  comment text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT batch_execution_log_event_data_object_ck CHECK (jsonb_typeof(event_data) = 'object')
);

CREATE TABLE IF NOT EXISTS mes.batch_deviation (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id uuid NOT NULL DEFAULT app_current_tenant_id(),
  batch_id uuid NOT NULL REFERENCES public.mes_batches(id) ON DELETE CASCADE,
  batch_step_id uuid NULL REFERENCES mes.batch_step(id) ON DELETE CASCADE,
  deviation_code text NULL,
  summary text NOT NULL,
  severity mes.deviation_severity NOT NULL DEFAULT 'minor',
  status mes.deviation_status NOT NULL DEFAULT 'open',
  detail_json jsonb NOT NULL DEFAULT '{}'::jsonb,
  opened_at timestamptz NOT NULL DEFAULT now(),
  opened_by uuid NULL,
  closed_at timestamptz NULL,
  closed_by uuid NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  updated_by uuid NULL,
  CONSTRAINT batch_deviation_detail_json_object_ck CHECK (jsonb_typeof(detail_json) = 'object'),
  CONSTRAINT batch_deviation_time_range_ck CHECK (
    closed_at IS NULL
    OR opened_at <= closed_at
  )
);

CREATE OR REPLACE FUNCTION mes.trg_assert_batch_parent_tenant()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_batch_tenant uuid;
BEGIN
  IF NEW.tenant_id IS NULL THEN
    NEW.tenant_id := app_current_tenant_id();
  END IF;

  SELECT b.tenant_id
    INTO v_batch_tenant
  FROM public.mes_batches b
  WHERE b.id = NEW.batch_id;

  IF v_batch_tenant IS NULL THEN
    RAISE EXCEPTION 'Batch % does not exist', NEW.batch_id;
  END IF;

  IF v_batch_tenant <> NEW.tenant_id THEN
    RAISE EXCEPTION 'Batch % does not belong to tenant %', NEW.batch_id, NEW.tenant_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION mes.trg_assert_optional_batch_parent_tenant()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_batch_tenant uuid;
BEGIN
  IF NEW.batch_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF NEW.tenant_id IS NULL THEN
    NEW.tenant_id := app_current_tenant_id();
  END IF;

  SELECT b.tenant_id
    INTO v_batch_tenant
  FROM public.mes_batches b
  WHERE b.id = NEW.batch_id;

  IF v_batch_tenant IS NULL THEN
    RAISE EXCEPTION 'Batch % does not exist', NEW.batch_id;
  END IF;

  IF v_batch_tenant <> NEW.tenant_id THEN
    RAISE EXCEPTION 'Batch % does not belong to tenant %', NEW.batch_id, NEW.tenant_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION mes.trg_assert_batch_step_parent_tenant()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_step_tenant uuid;
  v_step_batch uuid;
BEGIN
  IF NEW.batch_step_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT s.tenant_id, s.batch_id
    INTO v_step_tenant, v_step_batch
  FROM mes.batch_step s
  WHERE s.id = NEW.batch_step_id;

  IF v_step_tenant IS NULL THEN
    RAISE EXCEPTION 'Batch step % does not exist', NEW.batch_step_id;
  END IF;

  IF v_step_tenant <> NEW.tenant_id THEN
    RAISE EXCEPTION 'Batch step % does not belong to tenant %', NEW.batch_step_id, NEW.tenant_id;
  END IF;

  IF v_step_batch <> NEW.batch_id THEN
    RAISE EXCEPTION 'Batch step % does not belong to batch %', NEW.batch_step_id, NEW.batch_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION mes.trg_assert_equipment_parent_tenant()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_equipment_tenant uuid;
BEGIN
  SELECT e.tenant_id
    INTO v_equipment_tenant
  FROM public.mst_equipment e
  WHERE e.id = NEW.equipment_id;

  IF v_equipment_tenant IS NULL THEN
    RAISE EXCEPTION 'Equipment % does not exist', NEW.equipment_id;
  END IF;

  IF v_equipment_tenant <> NEW.tenant_id THEN
    RAISE EXCEPTION 'Equipment % does not belong to tenant %', NEW.equipment_id, NEW.tenant_id;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION mes.trg_prepare_equipment_reservation()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_equipment_tenant uuid;
  v_equipment_site uuid;
BEGIN
  IF NEW.tenant_id IS NULL THEN
    NEW.tenant_id := app_current_tenant_id();
  END IF;

  SELECT e.tenant_id, e.site_id
    INTO v_equipment_tenant, v_equipment_site
  FROM public.mst_equipment e
  WHERE e.id = NEW.equipment_id;

  IF v_equipment_tenant IS NULL THEN
    RAISE EXCEPTION 'Equipment % does not exist', NEW.equipment_id;
  END IF;

  IF v_equipment_tenant <> NEW.tenant_id THEN
    RAISE EXCEPTION 'Equipment % does not belong to tenant %', NEW.equipment_id, NEW.tenant_id;
  END IF;

  IF NEW.site_id IS NULL THEN
    NEW.site_id := v_equipment_site;
  ELSIF NEW.site_id <> v_equipment_site THEN
    RAISE EXCEPTION 'Reservation site % must match equipment % site %', NEW.site_id, NEW.equipment_id, v_equipment_site;
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION mes.trg_assert_equipment_reservation_parent()
RETURNS trigger
LANGUAGE plpgsql
AS $$
DECLARE
  v_reservation_tenant uuid;
  v_reservation_equipment uuid;
  v_reservation_batch uuid;
  v_reservation_step uuid;
BEGIN
  IF NEW.reservation_id IS NULL THEN
    RETURN NEW;
  END IF;

  SELECT r.tenant_id, r.equipment_id, r.batch_id, r.batch_step_id
    INTO v_reservation_tenant, v_reservation_equipment, v_reservation_batch, v_reservation_step
  FROM mes.equipment_reservation r
  WHERE r.id = NEW.reservation_id;

  IF v_reservation_tenant IS NULL THEN
    RAISE EXCEPTION 'Equipment reservation % does not exist', NEW.reservation_id;
  END IF;

  IF v_reservation_tenant <> NEW.tenant_id THEN
    RAISE EXCEPTION 'Equipment reservation % does not belong to tenant %', NEW.reservation_id, NEW.tenant_id;
  END IF;

  IF v_reservation_equipment <> NEW.equipment_id THEN
    RAISE EXCEPTION 'Equipment reservation % does not belong to equipment %', NEW.reservation_id, NEW.equipment_id;
  END IF;

  IF v_reservation_batch IS NOT NULL AND v_reservation_batch <> NEW.batch_id THEN
    RAISE EXCEPTION 'Equipment reservation % does not belong to batch %', NEW.reservation_id, NEW.batch_id;
  END IF;

  IF v_reservation_step IS NOT NULL AND v_reservation_step <> NEW.batch_step_id THEN
    RAISE EXCEPTION 'Equipment reservation % does not belong to batch step %', NEW.reservation_id, NEW.batch_step_id;
  END IF;

  RETURN NEW;
END;
$$;

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

CREATE INDEX IF NOT EXISTS idx_mst_recipe_tenant_status
  ON mes.mst_recipe (tenant_id, status, recipe_code);

CREATE INDEX IF NOT EXISTS idx_mst_recipe_version_tenant_recipe_status
  ON mes.mst_recipe_version (tenant_id, recipe_id, status, version_no DESC);

CREATE INDEX IF NOT EXISTS idx_mst_recipe_version_tenant_effective
  ON mes.mst_recipe_version (tenant_id, effective_from, effective_to);

CREATE INDEX IF NOT EXISTS idx_recipe_approval_flow_def_tenant_category
  ON mes.recipe_approval_flow_def (tenant_id, recipe_category, industry_type, status);

CREATE INDEX IF NOT EXISTS idx_recipe_approval_event_tenant_version
  ON mes.recipe_approval_event (tenant_id, recipe_version_id, step_no);

CREATE INDEX IF NOT EXISTS idx_recipe_change_history_tenant_version_changed_at
  ON mes.recipe_change_history (tenant_id, recipe_version_id, changed_at DESC);

CREATE INDEX IF NOT EXISTS idx_mst_step_template_tenant_type
  ON mes.mst_step_template (tenant_id, step_type, industry_type, status);

CREATE INDEX IF NOT EXISTS idx_mst_material_tenant_type
  ON mes.mst_material (tenant_id, material_type_id, status);

CREATE INDEX IF NOT EXISTS idx_mst_equipment_template_tenant_type
  ON mes.mst_equipment_template (tenant_id, equipment_type_id, status);

CREATE INDEX IF NOT EXISTS idx_mst_parameter_def_tenant_data_type
  ON mes.mst_parameter_def (tenant_id, data_type, status);

CREATE INDEX IF NOT EXISTS idx_mst_quality_check_tenant_type
  ON mes.mst_quality_check (tenant_id, check_type, status);

CREATE INDEX IF NOT EXISTS idx_mes_batches_tenant_mes_recipe_version_status
  ON public.mes_batches (tenant_id, mes_recipe_id, recipe_version_id, status);

CREATE INDEX IF NOT EXISTS idx_mes_batches_recipe_version_id
  ON public.mes_batches (recipe_version_id);

CREATE INDEX IF NOT EXISTS idx_batch_step_tenant_batch_status
  ON mes.batch_step (tenant_id, batch_id, status, step_no);

CREATE INDEX IF NOT EXISTS idx_batch_material_plan_tenant_batch
  ON mes.batch_material_plan (tenant_id, batch_id, batch_step_id);

CREATE INDEX IF NOT EXISTS idx_batch_material_actual_tenant_batch
  ON mes.batch_material_actual (tenant_id, batch_id, batch_step_id, consumed_at DESC);

CREATE INDEX IF NOT EXISTS idx_batch_equipment_assignment_tenant_batch
  ON mes.batch_equipment_assignment (tenant_id, batch_id, batch_step_id, assigned_at DESC);

CREATE INDEX IF NOT EXISTS idx_batch_equipment_assignment_tenant_status
  ON mes.batch_equipment_assignment (tenant_id, status, assigned_at DESC);

CREATE INDEX IF NOT EXISTS idx_batch_equipment_assignment_reservation
  ON mes.batch_equipment_assignment (reservation_id)
  WHERE reservation_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_equipment_reservation_tenant_equipment_window
  ON mes.equipment_reservation (tenant_id, equipment_id, start_at, end_at);

CREATE INDEX IF NOT EXISTS idx_equipment_reservation_tenant_batch
  ON mes.equipment_reservation (tenant_id, batch_id, batch_step_id, start_at);

CREATE INDEX IF NOT EXISTS idx_equipment_reservation_tenant_site_status
  ON mes.equipment_reservation (tenant_id, site_id, status, start_at);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'equipment_reservation_no_overlap_excl'
      AND conrelid = 'mes.equipment_reservation'::regclass
  ) THEN
    EXECUTE $sql$
      ALTER TABLE mes.equipment_reservation
      ADD CONSTRAINT equipment_reservation_no_overlap_excl
      EXCLUDE USING gist (
        equipment_id WITH =,
        tstzrange(start_at, end_at, '[)') WITH &&
      )
      WHERE (
        exclusive_use
        AND status IN ('reserved', 'confirmed', 'in_progress')
      )
    $sql$;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_batch_execution_log_tenant_batch
  ON mes.batch_execution_log (tenant_id, batch_id, batch_step_id, event_at DESC);

CREATE INDEX IF NOT EXISTS idx_batch_deviation_tenant_batch_status
  ON mes.batch_deviation (tenant_id, batch_id, batch_step_id, status, opened_at DESC);

DROP TRIGGER IF EXISTS trg_mst_recipe_updated_at ON mes.mst_recipe;
CREATE TRIGGER trg_mst_recipe_updated_at
BEFORE UPDATE ON mes.mst_recipe
FOR EACH ROW
EXECUTE FUNCTION mes.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_mst_recipe_version_updated_at ON mes.mst_recipe_version;
CREATE TRIGGER trg_mst_recipe_version_updated_at
BEFORE UPDATE ON mes.mst_recipe_version
FOR EACH ROW
EXECUTE FUNCTION mes.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_mst_material_updated_at ON mes.mst_material;
CREATE TRIGGER trg_mst_material_updated_at
BEFORE UPDATE ON mes.mst_material
FOR EACH ROW
EXECUTE FUNCTION mes.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_mst_material_assert_material_type_domain ON mes.mst_material;
CREATE TRIGGER trg_mst_material_assert_material_type_domain
BEFORE INSERT OR UPDATE OF tenant_id, material_type_id ON mes.mst_material
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_type_def_domain('material_type_id', 'material_type');

DROP TRIGGER IF EXISTS trg_mst_equipment_template_updated_at ON mes.mst_equipment_template;
CREATE TRIGGER trg_mst_equipment_template_updated_at
BEFORE UPDATE ON mes.mst_equipment_template
FOR EACH ROW
EXECUTE FUNCTION mes.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_mst_equipment_template_assert_equipment_type_domain ON mes.mst_equipment_template;
CREATE TRIGGER trg_mst_equipment_template_assert_equipment_type_domain
BEFORE INSERT OR UPDATE OF tenant_id, equipment_type_id ON mes.mst_equipment_template
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_type_def_domain('equipment_type_id', 'equipment_type');

DROP TRIGGER IF EXISTS trg_mst_parameter_def_updated_at ON mes.mst_parameter_def;
CREATE TRIGGER trg_mst_parameter_def_updated_at
BEFORE UPDATE ON mes.mst_parameter_def
FOR EACH ROW
EXECUTE FUNCTION mes.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_mst_quality_check_updated_at ON mes.mst_quality_check;
CREATE TRIGGER trg_mst_quality_check_updated_at
BEFORE UPDATE ON mes.mst_quality_check
FOR EACH ROW
EXECUTE FUNCTION mes.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_mst_step_template_updated_at ON mes.mst_step_template;
CREATE TRIGGER trg_mst_step_template_updated_at
BEFORE UPDATE ON mes.mst_step_template
FOR EACH ROW
EXECUTE FUNCTION mes.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_mst_step_template_assert_equipment_type_domain ON mes.mst_step_template;
CREATE TRIGGER trg_mst_step_template_assert_equipment_type_domain
BEFORE INSERT OR UPDATE OF tenant_id, default_equipment_type_id ON mes.mst_step_template
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_type_def_domain('default_equipment_type_id', 'equipment_type');

DROP TRIGGER IF EXISTS trg_recipe_approval_flow_def_updated_at ON mes.recipe_approval_flow_def;
CREATE TRIGGER trg_recipe_approval_flow_def_updated_at
BEFORE UPDATE ON mes.recipe_approval_flow_def
FOR EACH ROW
EXECUTE FUNCTION mes.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_batch_step_updated_at ON mes.batch_step;
CREATE TRIGGER trg_batch_step_updated_at
BEFORE UPDATE ON mes.batch_step
FOR EACH ROW
EXECUTE FUNCTION mes.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_batch_step_assert_parent_tenant ON mes.batch_step;
CREATE TRIGGER trg_batch_step_assert_parent_tenant
BEFORE INSERT OR UPDATE ON mes.batch_step
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_batch_parent_tenant();

DROP TRIGGER IF EXISTS trg_batch_material_plan_assert_batch_tenant ON mes.batch_material_plan;
CREATE TRIGGER trg_batch_material_plan_assert_batch_tenant
BEFORE INSERT OR UPDATE ON mes.batch_material_plan
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_batch_parent_tenant();

DROP TRIGGER IF EXISTS trg_batch_material_plan_assert_step_tenant ON mes.batch_material_plan;
CREATE TRIGGER trg_batch_material_plan_assert_step_tenant
BEFORE INSERT OR UPDATE ON mes.batch_material_plan
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_batch_step_parent_tenant();

DROP TRIGGER IF EXISTS trg_batch_material_plan_assert_material_type_domain ON mes.batch_material_plan;
CREATE TRIGGER trg_batch_material_plan_assert_material_type_domain
BEFORE INSERT OR UPDATE OF tenant_id, material_type_id ON mes.batch_material_plan
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_type_def_domain('material_type_id', 'material_type');

DROP TRIGGER IF EXISTS trg_batch_material_actual_assert_batch_tenant ON mes.batch_material_actual;
CREATE TRIGGER trg_batch_material_actual_assert_batch_tenant
BEFORE INSERT OR UPDATE ON mes.batch_material_actual
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_batch_parent_tenant();

DROP TRIGGER IF EXISTS trg_batch_material_actual_assert_step_tenant ON mes.batch_material_actual;
CREATE TRIGGER trg_batch_material_actual_assert_step_tenant
BEFORE INSERT OR UPDATE ON mes.batch_material_actual
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_batch_step_parent_tenant();

DROP TRIGGER IF EXISTS trg_batch_equipment_assignment_updated_at ON mes.batch_equipment_assignment;
CREATE TRIGGER trg_batch_equipment_assignment_updated_at
BEFORE UPDATE ON mes.batch_equipment_assignment
FOR EACH ROW
EXECUTE FUNCTION mes.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_batch_equipment_assignment_assert_batch_tenant ON mes.batch_equipment_assignment;
CREATE TRIGGER trg_batch_equipment_assignment_assert_batch_tenant
BEFORE INSERT OR UPDATE ON mes.batch_equipment_assignment
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_batch_parent_tenant();

DROP TRIGGER IF EXISTS trg_batch_equipment_assignment_assert_step_tenant ON mes.batch_equipment_assignment;
CREATE TRIGGER trg_batch_equipment_assignment_assert_step_tenant
BEFORE INSERT OR UPDATE ON mes.batch_equipment_assignment
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_batch_step_parent_tenant();

DROP TRIGGER IF EXISTS trg_batch_equipment_assignment_assert_equipment_tenant ON mes.batch_equipment_assignment;
CREATE TRIGGER trg_batch_equipment_assignment_assert_equipment_tenant
BEFORE INSERT OR UPDATE ON mes.batch_equipment_assignment
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_equipment_parent_tenant();

DROP TRIGGER IF EXISTS trg_batch_equipment_assignment_assert_reservation_tenant ON mes.batch_equipment_assignment;
CREATE TRIGGER trg_batch_equipment_assignment_assert_reservation_tenant
BEFORE INSERT OR UPDATE ON mes.batch_equipment_assignment
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_equipment_reservation_parent();

DROP TRIGGER IF EXISTS trg_equipment_reservation_updated_at ON mes.equipment_reservation;
CREATE TRIGGER trg_equipment_reservation_updated_at
BEFORE UPDATE ON mes.equipment_reservation
FOR EACH ROW
EXECUTE FUNCTION mes.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_equipment_reservation_prepare ON mes.equipment_reservation;
CREATE TRIGGER trg_equipment_reservation_prepare
BEFORE INSERT OR UPDATE OF tenant_id, site_id, equipment_id ON mes.equipment_reservation
FOR EACH ROW
EXECUTE FUNCTION mes.trg_prepare_equipment_reservation();

DROP TRIGGER IF EXISTS trg_equipment_reservation_assert_batch_tenant ON mes.equipment_reservation;
CREATE TRIGGER trg_equipment_reservation_assert_batch_tenant
BEFORE INSERT OR UPDATE ON mes.equipment_reservation
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_optional_batch_parent_tenant();

DROP TRIGGER IF EXISTS trg_equipment_reservation_assert_step_tenant ON mes.equipment_reservation;
CREATE TRIGGER trg_equipment_reservation_assert_step_tenant
BEFORE INSERT OR UPDATE ON mes.equipment_reservation
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_batch_step_parent_tenant();

DROP TRIGGER IF EXISTS trg_batch_execution_log_assert_batch_tenant ON mes.batch_execution_log;
CREATE TRIGGER trg_batch_execution_log_assert_batch_tenant
BEFORE INSERT OR UPDATE ON mes.batch_execution_log
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_batch_parent_tenant();

DROP TRIGGER IF EXISTS trg_batch_execution_log_assert_step_tenant ON mes.batch_execution_log;
CREATE TRIGGER trg_batch_execution_log_assert_step_tenant
BEFORE INSERT OR UPDATE ON mes.batch_execution_log
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_batch_step_parent_tenant();

DROP TRIGGER IF EXISTS trg_batch_deviation_updated_at ON mes.batch_deviation;
CREATE TRIGGER trg_batch_deviation_updated_at
BEFORE UPDATE ON mes.batch_deviation
FOR EACH ROW
EXECUTE FUNCTION mes.trg_set_updated_at();

DROP TRIGGER IF EXISTS trg_batch_deviation_assert_batch_tenant ON mes.batch_deviation;
CREATE TRIGGER trg_batch_deviation_assert_batch_tenant
BEFORE INSERT OR UPDATE ON mes.batch_deviation
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_batch_parent_tenant();

DROP TRIGGER IF EXISTS trg_batch_deviation_assert_step_tenant ON mes.batch_deviation;
CREATE TRIGGER trg_batch_deviation_assert_step_tenant
BEFORE INSERT OR UPDATE ON mes.batch_deviation
FOR EACH ROW
EXECUTE FUNCTION mes.trg_assert_batch_step_parent_tenant();

DO $$
DECLARE
  tbl text;
  tbls text[] := ARRAY[
    'mst_recipe',
    'mst_recipe_version',
    'mst_material',
    'mst_equipment_template',
    'mst_parameter_def',
    'mst_quality_check',
    'mst_step_template',
    'recipe_approval_flow_def',
    'recipe_approval_event',
    'recipe_change_history',
    'batch_step',
    'batch_material_plan',
    'batch_material_actual',
    'batch_equipment_assignment',
    'equipment_reservation',
    'batch_execution_log',
    'batch_deviation'
  ];
BEGIN
  FOREACH tbl IN ARRAY tbls LOOP
    EXECUTE format('ALTER TABLE mes.%I ENABLE ROW LEVEL SECURITY', tbl);

    EXECUTE format('DROP POLICY IF EXISTS tenant_select ON mes.%I', tbl);
    EXECUTE format(
      'CREATE POLICY tenant_select ON mes.%I FOR SELECT TO authenticated USING (tenant_id = app_current_tenant_id())',
      tbl
    );

    EXECUTE format('DROP POLICY IF EXISTS tenant_insert ON mes.%I', tbl);
    EXECUTE format(
      'CREATE POLICY tenant_insert ON mes.%I FOR INSERT TO authenticated WITH CHECK (tenant_id = app_current_tenant_id())',
      tbl
    );

    EXECUTE format('DROP POLICY IF EXISTS tenant_update ON mes.%I', tbl);
    EXECUTE format(
      'CREATE POLICY tenant_update ON mes.%I FOR UPDATE TO authenticated USING (tenant_id = app_current_tenant_id()) WITH CHECK (tenant_id = app_current_tenant_id())',
      tbl
    );

    EXECUTE format('DROP POLICY IF EXISTS tenant_delete ON mes.%I', tbl);
    EXECUTE format(
      'CREATE POLICY tenant_delete ON mes.%I FOR DELETE TO authenticated USING (tenant_id = app_current_tenant_id())',
      tbl
    );
  END LOOP;
END $$;

GRANT ALL ON ALL TABLES IN SCHEMA mes TO postgres;
GRANT ALL ON ALL TABLES IN SCHEMA mes TO anon;
GRANT ALL ON ALL TABLES IN SCHEMA mes TO authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA mes TO service_role;
