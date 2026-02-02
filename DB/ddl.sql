-- =========================================
-- DEV RESET (optional for local/dev only)
-- =========================================
-- drop schema if exists brewery cascade;

-- (Re)create schema



do $$ begin
  create type tenant_role as enum ('owner','admin','editor','viewer');
exception when duplicate_object then null; end $$;

create table if not exists tenants (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table if not exists tenant_members (
  tenant_id uuid not null references tenants(id) on delete cascade,
  user_id uuid not null,  -- references auth.users(id) (can’t FK directly)
  role tenant_role not null default 'viewer',
  invited_by uuid,
  created_at timestamptz not null default now(),
  primary key (tenant_id, user_id)
);

create index if not exists idx_tenant_members_user on tenant_members(user_id);
create index if not exists idx_tenant_members_tenant_role on tenant_members(tenant_id, role);
-- =========================================
-- Extensions
-- =========================================
create extension if not exists pgcrypto;  -- for gen_random_uuid()

-- =========================================
-- Enums (idempotent)
-- =========================================

do $$ begin
  CREATE TYPE public.mes_batch_status AS ENUM (
    'planned',
    'ready',
    'in_progress',
    'hold',
    'finished');
exception when duplicate_object then null; end $$;


-- =========================================
-- Masters
-- =========================================
create table if not exists mst_uom (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  code text not null,
  name text,
  base_factor numeric,
  base_code text,
  meta jsonb default '{}'::jsonb,
  created_at timestamptz default now(),
  unique (tenant_id, code)
);


-- =========================================
-- Recipe & Process
-- =========================================
CREATE TABLE public.mes_recipes (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	tenant_id uuid DEFAULT ((auth.jwt() -> 'app_metadata'::text) ->> 'tenant_id'::text)::uuid NOT NULL,
	code text NOT NULL,
	"name" text NOT NULL,
	"style" text NULL,
	batch_size_l numeric NULL,
	target_og numeric NULL,
	target_fg numeric NULL,
	target_abv numeric NULL,
	target_ibu numeric NULL,
	target_srm numeric NULL,
	"version" int4 DEFAULT 1 NOT NULL,
	status text DEFAULT 'active'::text NOT NULL,
	notes text NULL,
	created_by uuid NULL,
	created_at timestamptz DEFAULT now() NULL,
	basic_template_flg bool NULL,
	category uuid NULL,
	CONSTRAINT rcp_recipes_pkey PRIMARY KEY (id),
	CONSTRAINT rcp_recipes_tenant_id_code_version_key UNIQUE (tenant_id, code, version)
);
ALTER TABLE public.mes_recipes ADD CONSTRAINT rcp_recipes_category_fkey FOREIGN KEY (category) REFERENCES public.mst_category(id);


-- public.mes_recipes foreign keys

ALTER TABLE public.mes_recipes ADD CONSTRAINT rcp_recipes_category_fkey FOREIGN KEY (category) REFERENCES public.mst_category(id);

create table if not exists mes_ingredients (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  recipe_id uuid not null references mes_recipes(id) on delete cascade,
  material_id uuid not null references mst_materials(id),
  amount numeric,
  uom_id uuid not null references mst_uom(id),
  usage_stage text,
  notes text
);

create table if not exists mes_recipe_processes (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  recipe_id uuid not null references mes_recipes(id) on delete cascade,
  name text not null,
  version int not null default 1,
  is_active boolean default true,
  notes text,
  created_at timestamptz default now(),
  unique (tenant_id, recipe_id, name, version)
);

create table if not exists mes_recipe_steps (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  process_id uuid not null references mes_recipe_processes(id) on delete cascade,
  step_no int not null,
  step prc_step_type not null,
  target_params jsonb default '{}'::jsonb,
  qa_checks jsonb default '[]'::jsonb,
  notes text,
  unique (tenant_id, process_id, step_no)
);

-- =========================================
-- Production Batches & Executed Steps
-- =========================================
create table if not exists mes_batches (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  batch_code text not null,
  batch_label varchar,
  recipe_id uuid not null references mes_recipes(id),
  process_version int not null,
  scale_factor numeric,
  recipe_json jsonb,
  planned_start timestamptz,
  planned_end timestamptz,
  actual_start timestamptz,
  actual_end timestamptz,
  status text default 'planned',
  kpi jsonb default '[]'::jsonb,
  material_consumption jsonb default '[]'::jsonb,
  output_actual jsonb default '[]'::jsonb,
  created_at timestamptz default now(),
  notes text,
  meta jsonb default '{}'::jsonb,
  unique (tenant_id, batch_code)
);

create table if not exists mes_batch_steps (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  batch_id uuid not null references mes_batches(id) on delete cascade,
  step_no int not null,
  step prc_step_type not null,
  planned_params jsonb default '{}'::jsonb,
  actual_params jsonb default '{}'::jsonb,
  status text default 'open',
  notes text,
  unique (tenant_id, batch_id, step_no)
);



create table if not exists inv_inventory (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  material_id uuid not null references mst_materials(id),
  site_id uuid not null references mst_sites(id),
  qty numeric not null default 0,
  uom_id uuid not null references mst_uom(id),
  batch_code text,
  created_at timestamptz default now()
);

-- =========================================
-- Waste & Beer Tax
-- =========================================
create table if not exists wst_waste (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  batch_id uuid references mes_batches(id),
  step_id uuid references mes_batch_steps(id),
  material_id uuid references mst_materials(id),
  qty numeric,
  uom_id uuid references mst_uom(id),
  reason text,
  created_at timestamptz default now()
);

create table if not exists tax_beer (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  category uuid not null references mst_category(id),
  note text,
  taxrate numeric not null,
  created_date date not null default current_date,
  effect_date date,
  expire_date date
);

create table if not exists tax_reports (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  tax_type text not null default 'monthly',
  tax_year int not null,
  tax_month int not null,
  status text not null default 'draft',
  total_tax_amount numeric not null default 0,
  volume_breakdown jsonb default '[]'::jsonb,
  report_files jsonb default '[]'::jsonb,
  attachment_files jsonb default '[]'::jsonb,
  created_at timestamptz default now(),
  unique (tenant_id, tax_year, tax_month),
  constraint tax_reports_status_check check (status in ('draft','submitted','approved')),
  constraint tax_reports_month_check check (tax_month between 1 and 12)
);

-- =========================================
-- Orders & Packaging
-- =========================================
create table if not exists ord_orders (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  order_code text not null,
  customer text,
  order_date date default current_date,
  status text default 'open',
  notes text,
  unique (tenant_id, order_code)
);

create table if not exists ord_order_lines (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  order_id uuid not null references ord_orders(id) on delete cascade,
  recipe_id uuid not null references mes_recipes(id),
  qty numeric not null,
  uom_id uuid not null references mst_uom(id),
  package_size_l numeric,
  created_at timestamptz default now()
);

-- =========================================
-- HACCP
-- =========================================
create table if not exists haccp_plans (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  recipe_id uuid not null references mes_recipes(id),
  name text not null,
  version int not null default 1,
  scope text,
  approvals jsonb default '[]'::jsonb,
  effective_from date,
  effective_to date,
  status text default 'active',
  created_at timestamptz default now(),
  unique (tenant_id, recipe_id, version)
);

create table if not exists haccp_hazards (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  plan_id uuid not null references haccp_plans(id) on delete cascade,
  prc_step_id uuid not null references mes_recipe_steps(id),
  name text not null,
  htype haccp_hazard_type not null,
  description text,
  severity int,
  likelihood int,
  preventive_measures jsonb default '[]'::jsonb
);

create table if not exists haccp_ccp_points (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  plan_id uuid not null references haccp_plans(id) on delete cascade,
  prc_step_id uuid not null references mes_recipe_steps(id),
  name text not null,
  monitoring_method text,
  frequency text,
  responsible_role text,
  records_required boolean default true
);

create table if not exists haccp_ccp_limits (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  ccp_id uuid not null references haccp_ccp_points(id) on delete cascade,
  param text not null,
  limit_type haccp_limit_type not null,
  min_value numeric,
  max_value numeric,
  target_value numeric,
  unit text
);

create table if not exists haccp_ccp_measure_maps (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  ccp_id uuid not null references haccp_ccp_points(id) on delete cascade,
  mtype text not null,
  tolerance jsonb default '{}'::jsonb
);

-- =========================================
-- QC Measurements
-- =========================================
create table if not exists qc_measurements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  batch_id uuid not null references mes_batches(id),
  step_id uuid references mes_batch_steps(id),
  mtype text not null,
  value numeric,
  unit text,
  taken_at timestamptz default now(),
  notes text
);

-- =========================================
-- Tenant column defaults (auto-fill from JWT)
-- =========================================
alter table tenant_members
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table mst_uom
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table mst_materials
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table mst_beer_package_category
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table mst_category
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table mes_recipes
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table mes_ingredients
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table mes_recipe_processes
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table mes_recipe_steps
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table mes_batches
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table mes_batch_steps
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;


alter table inv_inventory
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table wst_waste
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table tax_beer
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table tax_reports
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table ord_orders
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table ord_order_lines
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table haccp_plans
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table haccp_hazards
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table haccp_ccp_points
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table haccp_ccp_limits
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table haccp_ccp_measure_maps
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table qc_measurements
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;



-- =========================================
-- Index Pack
-- =========================================
-- Masters
create index if not exists idx_mst_uom_tenant_code
  on mst_uom (tenant_id, code);
create index if not exists idx_mst_materials_tenant_code
  on mst_materials (tenant_id, code);
create index if not exists idx_mst_materials_tenant_category
  on mst_materials (tenant_id, category);
create index if not exists idx_mst_materials_uom
  on mst_materials (uom_id);

create index if not exists idx_mst_beer_package_category_tenant_code
  on mst_beer_package_category (tenant_id, package_code);

-- Recipes & Process
create index if not exists idx_rcp_recipes_tenant_code_version
  on mes_recipes (tenant_id, code, version);
create index if not exists idx_rcp_recipes_tenant_style
  on mes_recipes (tenant_id, style);
create index if not exists idx_rcp_recipes_created_at
  on mes_recipes (created_at);

create index if not exists idx_rcp_ingredients_recipe
  on mes_ingredients (recipe_id);
create index if not exists idx_rcp_ingredients_tenant_recipe
  on mes_ingredients (tenant_id, recipe_id);
create index if not exists idx_rcp_ingredients_material
  on mes_ingredients (material_id);
create index if not exists idx_rcp_ingredients_uom
  on mes_ingredients (uom_id);

create index if not exists idx_prc_processes_tenant_recipe_active
  on mes_recipe_processes (tenant_id, recipe_id, is_active, version desc);
create index if not exists idx_prc_steps_process_stepno
  on mes_recipe_steps (process_id, step_no);
create index if not exists idx_prc_steps_tenant_process
  on mes_recipe_steps (tenant_id, process_id);
create index if not exists idx_prc_steps_target_params_gin
  on mes_recipe_steps using gin (target_params);
create index if not exists idx_prc_steps_qa_checks_gin
  on mes_recipe_steps using gin (qa_checks);

-- Production
create index if not exists idx_mes_batches_tenant_batch_code
  on mes_batches (tenant_id, batch_code);
create index if not exists idx_mes_batches_tenant_recipe_status
  on mes_batches (tenant_id, recipe_id, status);
create index if not exists idx_mes_batches_planned_start
  on mes_batches (planned_start);
create index if not exists idx_mes_batches_created_at
  on mes_batches (created_at);

create index if not exists idx_mes_batch_steps_batch_stepno
  on mes_batch_steps (batch_id, step_no);
create index if not exists idx_mes_batch_steps_tenant_batch
  on mes_batch_steps (tenant_id, batch_id);
create index if not exists idx_mes_batch_steps_planned_params_gin
  on mes_batch_steps using gin (planned_params);
create index if not exists idx_mes_batch_steps_actual_params_gin
  on mes_batch_steps using gin (actual_params);

-- Inventory

create index if not exists idx_inv_inventory_material
  on inv_inventory (material_id);
create index if not exists idx_inv_inventory_tenant_wh_material
  on inv_inventory (tenant_id, site_id, material_id);
create index if not exists idx_inv_inventory_batch_code
  on inv_inventory (batch_code);

-- Waste & Tax
create index if not exists idx_wst_waste_tenant_batch
  on wst_waste (tenant_id, batch_id);
create index if not exists idx_wst_waste_material
  on wst_waste (material_id);
create index if not exists idx_wst_waste_created_at
  on wst_waste (created_at);

create index if not exists idx_tax_beer_tenant_category_dates
  on tax_beer (tenant_id, category, effect_date, expire_date);
create index if not exists idx_tax_reports_tenant_year_month
  on tax_reports (tenant_id, tax_year, tax_month);
create index if not exists idx_tax_reports_tenant_status
  on tax_reports (tenant_id, status);

-- Orders & Packaging
create index if not exists idx_ord_orders_tenant_code
  on ord_orders (tenant_id, order_code);
create index if not exists idx_ord_orders_status_date
  on ord_orders (status, order_date);

create index if not exists idx_ord_order_lines_order
  on ord_order_lines (order_id);
create index if not exists idx_ord_order_lines_tenant_order
  on ord_order_lines (tenant_id, order_id);
create index if not exists idx_ord_order_lines_recipe
  on ord_order_lines (recipe_id);
create index if not exists idx_ord_order_lines_uom
  on ord_order_lines (uom_id);

-- HACCP
create index if not exists idx_haccp_plans_tenant_recipe_version
  on haccp_plans (tenant_id, recipe_id, version);
create index if not exists idx_haccp_plans_status
  on haccp_plans (status);

create index if not exists idx_haccp_hazards_plan
  on haccp_hazards (plan_id);
create index if not exists idx_haccp_hazards_step
  on haccp_hazards (prc_step_id);

create index if not exists idx_haccp_ccp_points_plan_step
  on haccp_ccp_points (plan_id, prc_step_id);
create index if not exists idx_haccp_ccp_limits_ccp
  on haccp_ccp_limits (ccp_id);
create index if not exists idx_haccp_ccp_measure_maps_ccp
  on haccp_ccp_measure_maps (ccp_id);

-- QC
create index if not exists idx_qc_measurements_batch_time
  on qc_measurements (batch_id, taken_at);
create index if not exists idx_qc_measurements_tenant_type_time
  on qc_measurements (tenant_id, mtype, taken_at);
create index if not exists idx_qc_measurements_step
  on qc_measurements (step_id);

-- =========================================
-- RLS: enable + tenant policies
-- (drop-then-create so it's idempotent)
-- =========================================
grant usage on schema brewery to authenticated;

-- Enable RLS
alter table mst_uom         enable row level security;
alter table mst_materials   enable row level security;
alter table mst_beer_package_category enable row level security;
alter table mst_category    enable row level security;
alter table mes_recipes     enable row level security;
alter table mes_ingredients enable row level security;
alter table mes_recipe_processes   enable row level security;
alter table mes_recipe_steps       enable row level security;
alter table mes_batches        enable row level security;
alter table mes_batch_steps   enable row level security;
alter table inv_inventory   enable row level security;
alter table wst_waste       enable row level security;
alter table tax_beer        enable row level security;
alter table tax_reports     enable row level security;
alter table ord_orders      enable row level security;
alter table ord_order_lines enable row level security;
alter table haccp_plans                 enable row level security;
alter table haccp_hazards               enable row level security;
alter table haccp_ccp_points            enable row level security;
alter table haccp_ccp_limits            enable row level security;
alter table haccp_ccp_measure_maps      enable row level security;
alter table qc_measurements  enable row level security;

-- Policies (drop-if-exists then create)
-- Masters
drop policy if exists "mst_uom_tenant_all" on mst_uom;
create policy "mst_uom_tenant_all"
  on mst_uom
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "mst_materials_tenant_all" on mst_materials;
create policy "mst_materials_tenant_all"
  on mst_materials
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "mst_beer_package_category_tenant_all" on mst_beer_package_category;
create policy "mst_beer_package_category_tenant_all"
  on mst_beer_package_category
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "mst_category_tenant_all" on mst_category;
create policy "mst_category_tenant_all"
  on mst_category 
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);
  
-- Recipe/Process
drop policy if exists "rcp_recipes_tenant_all" on mes_recipes;
create policy "rcp_recipes_tenant_all"
  on mes_recipes
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "rcp_ingredients_tenant_all" on mes_ingredients;
create policy "rcp_ingredients_tenant_all"
  on mes_ingredients
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "prc_processes_tenant_all" on mes_recipe_processes;
create policy "prc_processes_tenant_all"
  on mes_recipe_processes
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "prc_steps_tenant_all" on mes_recipe_steps;
create policy "prc_steps_tenant_all"
  on mes_recipe_steps
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- Production
drop policy if exists "mes_batches_tenant_all" on mes_batches;
create policy "mes_batches_tenant_all"
  on mes_batches
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "mes_batch_steps_tenant_all" on mes_batch_steps;
create policy "mes_batch_steps_tenant_all"
  on mes_batch_steps
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- Inventory

drop policy if exists "inv_inventory_tenant_all" on inv_inventory;
create policy "inv_inventory_tenant_all"
  on inv_inventory
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- Waste/Tax
drop policy if exists "wst_waste_tenant_all" on wst_waste;
create policy "wst_waste_tenant_all"
  on wst_waste
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "tax_beer_tenant_all" on tax_beer;
create policy "tax_beer_tenant_all"
  on tax_beer
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "tax_reports_tenant_all" on tax_reports;
create policy "tax_reports_tenant_all"
  on tax_reports
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- Orders & Packaging
drop policy if exists "ord_orders_tenant_all" on ord_orders;
create policy "ord_orders_tenant_all"
  on ord_orders
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "ord_order_lines_tenant_all" on ord_order_lines;
create policy "ord_order_lines_tenant_all"
  on ord_order_lines
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- HACCP
drop policy if exists "haccp_plans_tenant_all" on haccp_plans;
create policy "haccp_plans_tenant_all"
  on haccp_plans
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "haccp_hazards_tenant_all" on haccp_hazards;
create policy "haccp_hazards_tenant_all"
  on haccp_hazards
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "haccp_ccp_points_tenant_all" on haccp_ccp_points;
create policy "haccp_ccp_points_tenant_all"
  on haccp_ccp_points
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "haccp_ccp_limits_tenant_all" on haccp_ccp_limits;
create policy "haccp_ccp_limits_tenant_all"
  on haccp_ccp_limits
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "haccp_ccp_measure_maps_tenant_all" on haccp_ccp_measure_maps;
create policy "haccp_ccp_measure_maps_tenant_all"
  on haccp_ccp_measure_maps
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- QC
drop policy if exists "qc_measurements_tenant_all" on qc_measurements;
create policy "qc_measurements_tenant_all"
  on qc_measurements
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);
