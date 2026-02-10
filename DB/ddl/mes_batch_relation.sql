-- =====================================================
-- MES Batch Relation DDL (with RLS, UOM FK)
-- Target: PostgreSQL / Supabase
-- =====================================================

-- =====================================================
-- 1. ENUM: batch_relation_type
-- =====================================================
DO $$
BEGIN
  CREATE TYPE batch_relation_type AS ENUM (
    'split',
    'merge',
    'blend',
    'rework',
    'repackage',
    'dilution',
    'transfer'
  );
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- =====================================================
-- 2. TABLE: mes_batch_relation
-- =====================================================
CREATE TABLE IF NOT EXISTS public.mes_batch_relation (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

    tenant_id   uuid NOT NULL,
    industry_id uuid,

    -- lineage edge
    src_batch_id uuid NOT NULL,
    dst_batch_id uuid NOT NULL,

    relation_type batch_relation_type NOT NULL,

    quantity numeric(18,6),

    -- unit of measure (FK)
    uom_id uuid NOT NULL,

    ratio numeric(10,6),

    effective_at timestamptz NOT NULL DEFAULT now(),

    created_at timestamptz NOT NULL DEFAULT now(),
    created_by uuid,

    CONSTRAINT chk_mbr_not_self
      CHECK (src_batch_id <> dst_batch_id)
);

-- =====================================================
-- 3. FOREIGN KEY: mst_uom
-- =====================================================
-- Case A: mst_uom is tenant-global (recommended)
ALTER TABLE public.mes_batch_relation
DROP CONSTRAINT IF EXISTS fk_mbr_uom;

ALTER TABLE public.mes_batch_relation
ADD CONSTRAINT fk_mbr_uom
FOREIGN KEY (uom_id)
REFERENCES public.mst_uom(id);

-- =====================================================
-- 4. INDEXES
-- =====================================================
CREATE INDEX IF NOT EXISTS ix_mbr_tenant_src
  ON public.mes_batch_relation (tenant_id, src_batch_id);

CREATE INDEX IF NOT EXISTS ix_mbr_tenant_dst
  ON public.mes_batch_relation (tenant_id, dst_batch_id);

CREATE INDEX IF NOT EXISTS ix_mbr_tenant_type
  ON public.mes_batch_relation (tenant_id, relation_type);

CREATE INDEX IF NOT EXISTS ix_mbr_tenant_uom
  ON public.mes_batch_relation (tenant_id, uom_id);

CREATE INDEX IF NOT EXISTS ix_mbr_tenant_effective
  ON public.mes_batch_relation (tenant_id, effective_at);

-- =====================================================
-- 5. tenant_id auto-fill trigger
-- =====================================================
CREATE OR REPLACE FUNCTION public.set_tenant_id_mes_batch_relation()
RETURNS trigger AS $$
BEGIN
  IF NEW.tenant_id IS NULL THEN
    NEW.tenant_id :=
      (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS trg_set_tenant_id_mes_batch_relation
ON public.mes_batch_relation;

CREATE TRIGGER trg_set_tenant_id_mes_batch_relation
BEFORE INSERT ON public.mes_batch_relation
FOR EACH ROW
EXECUTE FUNCTION public.set_tenant_id_mes_batch_relation();

-- =====================================================
-- 6. ROW LEVEL SECURITY (Supabase style)
-- =====================================================
ALTER TABLE public.mes_batch_relation ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS mes_batch_relation_rls
ON public.mes_batch_relation;

CREATE POLICY mes_batch_relation_rls
ON public.mes_batch_relation
FOR ALL
USING (
  tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
)
WITH CHECK (
  tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
);

-- =====================================================
-- END OF FILE
-- =====================================================
