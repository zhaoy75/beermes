-- Replace lot_event / lot_event_line with lot_edge (lot flow graph)
-- NOTE: You can DROP the old tables after migrating data:
-- drop table if exists public.lot_event_line;
-- drop table if exists public.lot_event;

-- (Optional but recommended) Define an enum for edge_type. If you already have one, skip this.
do $$
begin
  if not exists (select 1 from pg_type where typname = 'lot_edge_type') then
    create type public.lot_edge_type as enum (
      'PRODUCE',  -- NULL -> to_lot
      'MOVE',     -- from_lot -> to_lot (location/packaging/transfer)
      'CONSUME',  -- from_lot -> NULL (ship/loss/dispose)
      'SPLIT',    -- from_lot -> to_lot (one-to-many, semantically split)
      'MERGE'     -- from_lot -> to_lot (many-to-one, semantically merge)
    );
  end if;
end$$;

create table if not exists public.lot_edge (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,

  -- Link back to business document (movement) and the specific line
  movement_id uuid not null references public.inv_movements(id) on delete cascade,
  movement_line_id uuid null references public.inv_movement_lines(id) on delete set null,

  -- Graph semantics
  edge_type public.lot_edge_type not null,

  -- Directional lot relation (nullable for PRODUCE/CONSUME)
  from_lot_id uuid null references public.lot(id) on delete restrict,
  to_lot_id   uuid null references public.lot(id) on delete restrict,

  -- Quantity flowing along this edge
  qty numeric not null check (qty > 0),
  uom_id uuid not null, -- FK to mst_uom

  -- Optional snapshot/extra for audit/debug (do not overuse)
  notes text null,
  meta jsonb default '{}'::jsonb,

  created_at timestamptz default now(),

  -- Ensure edge endpoints make sense per edge_type
  constraint lot_edge_endpoints_ck check (
    (edge_type = 'PRODUCE' and from_lot_id is null and to_lot_id is not null) or
    (edge_type = 'CONSUME' and from_lot_id is not null and to_lot_id is null) or
    (edge_type in ('MOVE','SPLIT','MERGE') and from_lot_id is not null and to_lot_id is not null)
  )
);

-- Prevent duplicate edges per movement/line (helps idempotency)
-- You can tighten this later if you allow multiple edges per same line_no.
create unique index if not exists ux_lot_edge_tenant_movement_line_edge
  on public.lot_edge(tenant_id, movement_id, movement_line_id, edge_type, from_lot_id, to_lot_id)
  where movement_line_id is not null;

-- (Optional) If you want strict tenant matching without composite FKs,
-- at least enforce tenant equality by triggers. Skipping here per your request.

-- -----------------------------------------------------
-- RLS
-- -----------------------------------------------------
alter table public.lot_edge enable row level security;

drop policy if exists lot_edge_rls on public.lot_edge;
create policy lot_edge_rls on public.lot_edge
for all
using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- -----------------------------------------------------
-- Defaults
-- -----------------------------------------------------
alter table public.lot_edge
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;
