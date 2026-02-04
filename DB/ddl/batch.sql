do $$ begin
  CREATE TYPE public.mes_batch_status AS ENUM (
    'planned',
    'ready',
    'in_progress',
    'hold',
    'finished');
exception when duplicate_object then null; end $$;

-- =========================================
-- Production Batches & Executed Steps
-- =========================================
-- public.mes_batches definition

-- Drop table

-- DROP TABLE public.mes_batches;

CREATE TABLE public.mes_batches (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	tenant_id uuid DEFAULT ((auth.jwt() -> 'app_metadata'::text) ->> 'tenant_id'::text)::uuid NOT NULL,
	batch_code text NOT NULL,
	batch_label varchar NULL,
	recipe_id uuid NULL,
	process_version int4 NULL,
	scale_factor numeric NULL,
	recipe_json jsonb NULL,
	planned_start timestamptz NULL,
	planned_end timestamptz NULL,
	actual_start timestamptz NULL,
	actual_end timestamptz NULL,
	kpi jsonb DEFAULT '[]'::jsonb NULL,
	material_consumption jsonb DEFAULT '[]'::jsonb NULL,
	output_actual jsonb DEFAULT '[]'::jsonb NULL,
	created_at timestamptz DEFAULT now() NULL,
	notes text NULL,
	meta jsonb DEFAULT '{}'::jsonb NULL,
	status public."mes_batch_status" DEFAULT 'planned'::mes_batch_status NULL,
	CONSTRAINT mes_batches_pkey PRIMARY KEY (id),
	CONSTRAINT mes_batches_tenant_id_batch_code_key UNIQUE (tenant_id, batch_code)
);
CREATE INDEX idx_mes_batches_created_at ON public.mes_batches USING btree (created_at);
CREATE INDEX idx_mes_batches_planned_start ON public.mes_batches USING btree (planned_start);
CREATE INDEX idx_mes_batches_tenant_batch_code ON public.mes_batches USING btree (tenant_id, batch_code);


-- public.mes_batches foreign keys

ALTER TABLE public.mes_batches ADD CONSTRAINT mes_batches_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.mes_recipes(id);

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

create index if not exists idx_mes_batches_tenant_batch_code
  on mes_batches (tenant_id, batch_code);
create index if not exists idx_mes_batches_tenant_recipe_status
  on mes_batches (tenant_id, recipe_id, status);
create index if not exists idx_mes_batches_planned_start
  on mes_batches (planned_start);
create index if not exists idx_mes_batches_created_at
  on mes_batches (created_at);
  
alter table mes_batches        enable row level security;
alter table mes_batch_steps   enable row level security;

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

alter table mes_batches
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table mes_batch_steps
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;
