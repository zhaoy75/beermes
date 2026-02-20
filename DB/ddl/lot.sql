drop table if exists public.lot cascade;

create table if not exists public.lot (
  id                uuid primary key default gen_random_uuid(),
  tenant_id         uuid not null,

  lot_no            text not null, -- business lot number
  material_id       uuid null,     -- FK to mst_materials (if defined)
  package_id        uuid null,     -- FK to mst_package (if defined)
  batch_id          uuid null,     -- FK to mes_batches (if defined)
  lot_tax_type      text null,     -- e.g., 'bonded', 'taxed', 'exempt' 

  site_id           uuid null references public.mst_sites(id),
  produced_at       timestamptz null,
  expires_at        timestamptz null,

  qty               numeric not null check (qty >= 0),
  unit              numeric null,
  uom_id            uuid not null, -- FK to mst_uom

  status            text not null default 'active', -- active | consumed | void
  meta              jsonb default '{}'::jsonb,
  notes             text null,

  created_at        timestamptz default now(),
  updated_at        timestamptz default now(),

  unique (tenant_id, lot_no)
);

create index if not exists idx_lot_tenant_lotno
  on public.lot (tenant_id, lot_no);
create index if not exists idx_lot_tenant_status
  on public.lot (tenant_id, status);
create index if not exists idx_lot_batch
  on public.lot (batch_id);



-- -----------------------------------------------------
-- RLS
-- -----------------------------------------------------
alter table public.lot enable row level security;

drop policy if exists lot_rls on public.lot;
create policy lot_rls on public.lot
for all
using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);


-- -----------------------------------------------------
-- Defaults
-- -----------------------------------------------------
alter table public.lot
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;
