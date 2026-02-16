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
  notes text,
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
using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);


create or replace view public.v_sites as
select
  s.id,
  s.tenant_id,
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
