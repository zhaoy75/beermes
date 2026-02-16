
-- =====================================================
-- TRANSACTION LINES: Movement Lines
-- =====================================================
create table if not exists public.inv_movement_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  movement_id uuid not null references public.inv_movements(id) on delete cascade,
  line_no int not null,
  material_id uuid,                               -- FK to mst_materials (if defined)
  package_id uuid,                                -- FK to mst_beer_package_category (if defined)
  batch_id uuid,                                    -- FK to mes_batches (if defined)
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

create index if not exists idx_inv_mov_lines_batch
  on public.inv_movement_lines (batch_id);

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
using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);


alter table mst_site_types
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table mst_sites
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table inv_movements
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;


alter table inv_movement_lines
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

-- =====================================================
-- VIEW: Sites with type info (optional)
-- =====================================================
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
