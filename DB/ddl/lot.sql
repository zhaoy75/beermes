-- =====================================================
-- LOT / LOT EVENT (separate from inv_movements)
-- =====================================================

-- -----------------------------------------------------
-- ENUM: Lot event types (adjust as needed)
-- -----------------------------------------------------
do $$ begin
  create type public.lot_event_type as enum (
    'receive',          -- inbound lot creation
    'issue',            -- consumption / outbound
    'transfer',         -- site to site
    'adjustment',       -- gain/loss
    'waste',            -- disposal
    'sale',             -- customer shipment
    'return',           -- customer return
    'production'        -- production completion
  );
exception when duplicate_object then null;
end $$;

-- -----------------------------------------------------
-- LOT MASTER
-- -----------------------------------------------------
create table if not exists public.lot (
  id                uuid primary key default gen_random_uuid(),
  tenant_id         uuid not null,

  lot_no            text not null, -- business lot number
  material_id       uuid null,     -- FK to mst_materials (if defined)
  package_id        uuid null,     -- FK to mst_package (if defined)
  batch_id          uuid null,     -- FK to mes_batches (if defined)

  site_id           uuid null references public.mst_sites(id),
  produced_at       timestamptz null,
  expires_at        timestamptz null,

  qty               numeric not null check (qty >= 0),
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
-- LOT EVENT HEADER
-- -----------------------------------------------------
create table if not exists public.lot_event (
  id                uuid primary key default gen_random_uuid(),
  tenant_id         uuid not null,

  event_no          text not null, -- business document number
  event_type        public.lot_event_type not null,
  status            text not null default 'open', -- open | posted | void
  event_at          timestamptz not null default now(),

  src_site_id       uuid references public.mst_sites(id),
  dest_site_id      uuid references public.mst_sites(id),
  reason            text null,
  meta              jsonb default '{}'::jsonb,
  notes             text null,
  created_by        uuid null,
  created_at        timestamptz default now(),

  unique (tenant_id, event_no)
);

create index if not exists idx_lot_event_tenant_eventno
  on public.lot_event (tenant_id, event_no);
create index if not exists idx_lot_event_type_status
  on public.lot_event (tenant_id, event_type, status);
create index if not exists idx_lot_event_dates
  on public.lot_event (event_at);

-- -----------------------------------------------------
-- LOT EVENT LINES
-- -----------------------------------------------------
create table if not exists public.lot_event_line (
  id                uuid primary key default gen_random_uuid(),
  tenant_id         uuid not null,
  lot_event_id      uuid not null references public.lot_event(id) on delete cascade,
  line_no           int not null,

  lot_id            uuid null references public.lot(id),
  material_id       uuid null,      -- FK to mst_materials (if defined)
  package_id        uuid null,       -- FK to mst_package (if defined)
  batch_id          uuid null,       -- FK to mes_batches (if defined)

  qty               numeric not null check (qty > 0),
  uom_id            uuid not null,   -- FK to mst_uom
  notes             text null,
  meta              jsonb default '{}'::jsonb,

  unique (tenant_id, lot_event_id, line_no),
  constraint lot_event_line_has_item check (lot_id is not null or material_id is not null or package_id is not null)
);

create index if not exists idx_lot_event_lines_event
  on public.lot_event_line (lot_event_id);
create index if not exists idx_lot_event_lines_lot
  on public.lot_event_line (lot_id);
create index if not exists idx_lot_event_lines_batch
  on public.lot_event_line (batch_id);

-- -----------------------------------------------------
-- Tenant consistency trigger for lot_event_line
-- -----------------------------------------------------
create or replace function public.trg_lot_event_lines_same_tenant()
returns trigger language plpgsql as $$
declare p_tenant uuid;
begin
  select tenant_id into p_tenant from public.lot_event where id = new.lot_event_id;
  if p_tenant is null or new.tenant_id <> p_tenant then
    raise exception 'lot_event_line.tenant_id must match lot_event.tenant_id';
  end if;
  return new;
end $$;

drop trigger if exists trg_lot_event_lines_same_tenant on public.lot_event_line;
create trigger trg_lot_event_lines_same_tenant
before insert or update on public.lot_event_line
for each row execute function public.trg_lot_event_lines_same_tenant();

-- -----------------------------------------------------
-- RLS
-- -----------------------------------------------------
alter table public.lot enable row level security;
alter table public.lot_event enable row level security;
alter table public.lot_event_line enable row level security;

drop policy if exists lot_rls on public.lot;
create policy lot_rls on public.lot
for all
using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists lot_event_rls on public.lot_event;
create policy lot_event_rls on public.lot_event
for all
using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists lot_event_line_rls on public.lot_event_line;
create policy lot_event_line_rls on public.lot_event_line
for all
using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- -----------------------------------------------------
-- Defaults
-- -----------------------------------------------------
alter table public.lot
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;
alter table public.lot_event
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;
alter table public.lot_event_line
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;
