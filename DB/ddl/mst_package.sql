CREATE TABLE IF NOT EXISTS mst_package (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  tenant_id         uuid NOT NULL,
  industry_id       uuid NULL,

  -- Identity
  package_code      text NOT NULL,                          -- e.g. CAN_350, BTL_330, KEG_20L
  name_i18n         jsonb NOT NULL DEFAULT '{}'::jsonb,
  description       text NULL,

  -- Classification (optional taxonomy)
  package_type_id   uuid NULL,                              -- e.g. type_def.id (bottle/can/keg)

  -- Core for filling calculation
  unit_volume       numeric(18,6) NOT NULL CHECK (unit_volume > 0),
  max_volume
  volume_uom        text NOT NULL DEFAULT 'L',              -- should be volume domain (enforce by FK later if needed)
  fixed_qty         boolean NOT NULL DEFAULT false,         -- if true, then qty is fixed and unit_volume is informational only

  -- Optional packaging properties
  units_per_case    integer NULL CHECK (units_per_case IS NULL OR units_per_case > 0),
  tare_weight       numeric(18,6) NULL,
  weight_uom        text NULL,

  is_returnable     boolean NOT NULL DEFAULT false,
  deposit_amount    numeric(18,2) NULL,
  deposit_currency  text NULL,                              -- e.g. 'JPY'

  sku              text NULL,
  barcode          text NULL,

  -- Extensibility
  attr_doc          jsonb NOT NULL DEFAULT '{}'::jsonb,

  is_active         boolean NOT NULL DEFAULT true,
  sort_order        integer NOT NULL DEFAULT 0,

  created_at        timestamptz NOT NULL DEFAULT now(),
  updated_at        timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT mst_package_uq_tenant_industry_code
    UNIQUE (tenant_id, industry_id, package_code),

  CONSTRAINT mst_package_tare_chk
    CHECK (
      (tare_weight IS NULL AND weight_uom IS NULL)
      OR
      (tare_weight IS NOT NULL AND weight_uom IS NOT NULL)
    ),

  CONSTRAINT mst_package_deposit_chk
    CHECK (
      (deposit_amount IS NULL AND deposit_currency IS NULL)
      OR
      (deposit_amount IS NOT NULL AND deposit_currency IS NOT NULL)
    )
);

CREATE INDEX IF NOT EXISTS ix_mst_package_lookup
  ON mst_package (tenant_id, industry_id, is_active, sort_order, package_code);

CREATE INDEX IF NOT EXISTS ix_mst_package_type
  ON mst_package (tenant_id, package_type_id)
  WHERE package_type_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS ix_mst_package_barcode
  ON mst_package (tenant_id, barcode)
  WHERE barcode IS NOT NULL;

CREATE INDEX IF NOT EXISTS ix_mst_package_attr_doc_gin
  ON mst_package USING gin (attr_doc);




alter table public.mst_package enable row level security;

drop policy if exists mst_package on public.mst_package;
create policy mst_package_rls on public.mst_package
for all
using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);


alter table public.mst_package
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;