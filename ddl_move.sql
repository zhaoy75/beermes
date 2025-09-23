-- =====================================================
-- ENUM: Document types for inventory movements
-- =====================================================
do $$ begin
  create type public.inv_doc_type as enum (
    'purchase',          -- supplier -> our site
    'production_issue',  -- our site/warehouse -> WIP
    'production_receipt',-- WIP -> FG warehouse
    'transfer',          -- site -> site (internal)
    'sale',              -- our site -> customer
    'return',            -- customer -> our site
    'waste',             -- our site -> recycler/disposal
    'adjustment',        -- stock gain/loss
    'tax_transfer'       -- bonded/tax warehouse moves
  );
exception when duplicate_object then null;
end $$;

-- =====================================================
-- MASTER: Site Types (lookup)
-- =====================================================
create table if not exists public.mst_site_types (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  code text not null,               -- e.g., 'brewery','warehouse','supplier'
  name text not null,
  flags jsonb default '{}'::jsonb,
  active boolean default true,
  created_at timestamptz default now(),
  unique (tenant_id, code)
);

create index if not exists idx_mst_site_types_tenant_code
  on public.mst_site_types (tenant_id, code);

-- RLS
alter table public.mst_site_types enable row level security;

drop policy if exists mst_site_types_rls on public.mst_site_types;
create policy mst_site_types_rls on public.mst_site_types
for all
using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'active_tenant_id')::uuid)
with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'active_tenant_id')::uuid);

-- =====================================================
-- MASTER: Sites (locations, plants, suppliers, customers)
-- =====================================================
create table if not exists public.mst_sites (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  code text not null,
  name text not null,
  site_type_id uuid not null references public.mst_site_types(id),
  parent_site_id uuid references public.mst_sites(id),
  address jsonb,
  contact jsonb,
  notes text,
  active boolean default true,
  created_at timestamptz default now(),
  unique (tenant_id, code)
);

create index if not exists idx_mst_sites_tenant_code
  on public.mst_sites (tenant_id, code);

create index if not exists idx_mst_sites_tenant_type
  on public.mst_sites (tenant_id, site_type_id);

-- Tenant consistency: site must match site_type tenant
create or replace function public.trg_sites_same_tenant_type()
returns trigger language plpgsql as $$
declare ok boolean;
begin
  if new.site_type_id is not null then
    select (tenant_id = new.tenant_id) into ok
    from public.mst_site_types where id = new.site_type_id;
    if not coalesce(ok,false) then
      raise exception 'mst_sites.tenant_id must match mst_site_types.tenant_id';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists trg_sites_same_tenant_type on public.mst_sites;
create trigger trg_sites_same_tenant_type
before insert or update on public.mst_sites
for each row execute function public.trg_sites_same_tenant_type();

-- RLS
alter table public.mst_sites enable row level security;

drop policy if exists mst_sites_rls on public.mst_sites;
create policy mst_sites_rls on public.mst_sites
for all
using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'active_tenant_id')::uuid)
with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'active_tenant_id')::uuid);

-- =====================================================
-- TRANSACTION HEADER: Inventory Movements
-- =====================================================
create table if not exists public.inv_movements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  doc_no text not null,                         -- business document number
  doc_type public.inv_doc_type not null,
  status text not null default 'open',          -- 'open','posted','void'
  movement_at timestamptz not null default now(),
  src_site_id uuid references public.mst_sites(id),
  dest_site_id uuid references public.mst_sites(id),
  external_ref text,                            -- supplier invoice, PO, SO, etc.
  reason text,
  meta jsonb default '{}'::jsonb,
  created_by uuid,
  created_at timestamptz default now(),
  unique (tenant_id, doc_no)
);

create index if not exists idx_inv_mov_tenant_docno
  on public.inv_movements (tenant_id, doc_no);

create index if not exists idx_inv_mov_type_status
  on public.inv_movements (tenant_id, doc_type, status);

create index if not exists idx_inv_mov_dates
  on public.inv_movements (movement_at);

-- RLS
alter table public.inv_movements enable row level security;

drop policy if exists inv_movements_rls on public.inv_movements;
create policy inv_movements_rls on public.inv_movements
for all
using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'active_tenant_id')::uuid)
with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'active_tenant_id')::uuid);

-- =====================================================
-- TRANSACTION LINES: Movement Lines
-- =====================================================
create table if not exists public.inv_movement_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  movement_id uuid not null references public.inv_movements(id) on delete cascade,
  line_no int not null,
  material_id uuid,                               -- FK to mst_materials (if defined)
  package_id uuid,                                -- FK to pkg_packages (if defined)
  lot_id uuid,                                    -- FK to prd_lots (if defined)
  qty numeric not null check (qty > 0),
  uom_id uuid not null,                           -- FK to mst_uom
  notes text,
  meta jsonb default '{}'::jsonb,
  unique (tenant_id, movement_id, line_no),
  constraint inv_mov_line_has_item check (material_id is not null or package_id is not null)
);

create index if not exists idx_inv_mov_lines_movement
  on public.inv_movement_lines (movement_id);

create index if not exists idx_inv_mov_lines_material
  on public.inv_movement_lines (material_id);

create index if not exists idx_inv_mov_lines_package
  on public.inv_movement_lines (package_id);

create index if not exists idx_inv_mov_lines_lot
  on public.inv_movement_lines (lot_id);

-- Tenant consistency: line must match header tenant
create or replace function public.trg_inv_lines_same_tenant()
returns trigger language plpgsql as $$
declare p_tenant uuid;
begin
  select tenant_id into p_tenant from public.inv_movements where id = new.movement_id;
  if p_tenant is null or new.tenant_id <> p_tenant then
    raise exception 'inv_movement_lines.tenant_id must match inv_movements.tenant_id';
  end if;
  return new;
end $$;

drop trigger if exists trg_inv_lines_same_tenant on public.inv_movement_lines;
create trigger trg_inv_lines_same_tenant
before insert or update on public.inv_movement_lines
for each row execute function public.trg_inv_lines_same_tenant();

-- RLS
alter table public.inv_movement_lines enable row level security;

drop policy if exists inv_movement_lines_rls on public.inv_movement_lines;
create policy inv_movement_lines_rls on public.inv_movement_lines
for all
using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'active_tenant_id')::uuid)
with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'active_tenant_id')::uuid);

-- =====================================================
-- VIEW: Sites with type info (optional)
-- =====================================================
create or replace view public.v_sites as
select
  s.id,
  s.tenant_id,
  s.code,
  s.name,
  t.code as site_type_code,
  t.name as site_type_name,
  s.parent_site_id,
  s.address,
  s.contact,
  s.notes,
  s.active,
  s.created_at
from public.mst_sites s
left join public.mst_site_types t on t.id = s.site_type_id;