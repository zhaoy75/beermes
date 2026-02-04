-- public.mes_recipes definition

-- Drop table

-- DROP TABLE public.mes_recipes;

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
	basic_template_flg bool NULL, -- basic template can not be delete.
	category uuid NOT NULL, -- tax category
	CONSTRAINT rcp_recipes_pkey PRIMARY KEY (id),
	CONSTRAINT rcp_recipes_tenant_id_code_version_key UNIQUE (tenant_id, code, version)
);
CREATE INDEX idx_rcp_recipes_created_at ON public.mes_recipes USING btree (created_at);
CREATE INDEX idx_rcp_recipes_tenant_code_version ON public.mes_recipes USING btree (tenant_id, code, version);
CREATE INDEX idx_rcp_recipes_tenant_style ON public.mes_recipes USING btree (tenant_id, style);

-- Column comments

COMMENT ON COLUMN public.mes_recipes.basic_template_flg IS 'basic template can not be delete.';
COMMENT ON COLUMN public.mes_recipes.category IS 'tax category';

-- Permissions

ALTER TABLE public.mes_recipes OWNER TO postgres;
GRANT ALL ON TABLE public.mes_recipes TO postgres;
GRANT ALL ON TABLE public.mes_recipes TO anon;
GRANT ALL ON TABLE public.mes_recipes TO authenticated;
GRANT ALL ON TABLE public.mes_recipes TO service_role;

ALTER TABLE public.mes_recipes ADD CONSTRAINT rcp_recipes_category_fkey FOREIGN KEY (category) REFERENCES public.mst_category(id);

alter table mes_recipes
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

-- public.mes_recipe_processes definition

-- Drop table

-- DROP TABLE public.mes_recipe_processes;

CREATE TABLE public.mes_recipe_processes (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	tenant_id uuid DEFAULT ((auth.jwt() -> 'app_metadata'::text) ->> 'tenant_id'::text)::uuid NOT NULL,
	recipe_id uuid NOT NULL,
	"name" text NOT NULL,
	"version" int4 DEFAULT 1 NOT NULL,
	is_active bool DEFAULT true NULL,
	notes text NULL,
	created_at timestamptz DEFAULT now() NULL,
	CONSTRAINT prc_processes_pkey PRIMARY KEY (id),
	CONSTRAINT prc_processes_tenant_id_recipe_id_name_version_key UNIQUE (tenant_id, recipe_id, name, version)
);
CREATE INDEX idx_prc_processes_tenant_recipe_active ON public.mes_recipe_processes USING btree (tenant_id, recipe_id, is_active, version DESC);

-- Permissions

ALTER TABLE public.mes_recipe_processes OWNER TO postgres;
GRANT ALL ON TABLE public.mes_recipe_processes TO postgres;
GRANT ALL ON TABLE public.mes_recipe_processes TO anon;
GRANT ALL ON TABLE public.mes_recipe_processes TO authenticated;
GRANT ALL ON TABLE public.mes_recipe_processes TO service_role;


-- public.mes_recipe_processes foreign keys

ALTER TABLE public.mes_recipe_processes ADD CONSTRAINT prc_processes_recipe_id_fkey FOREIGN KEY (recipe_id) REFERENCES public.mes_recipes(id) ON DELETE CASCADE;

alter table mes_recipe_processes
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table mes_recipe_processes
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

create index if not exists idx_rcp_recipes_tenant_code_version
  on mes_recipes (tenant_id, code, version);
create index if not exists idx_rcp_recipes_tenant_style
  on mes_recipes (tenant_id, style);
create index if not exists idx_rcp_recipes_created_at
  on mes_recipes (created_at);


create index if not exists idx_prc_processes_tenant_recipe_active
  on mes_recipe_processes (tenant_id, recipe_id, is_active, version desc);

alter table mes_recipes     enable row level security;
alter table mes_recipe_processes   enable row level security;


drop policy if exists "mes_recipes_tenant_all" on mes_recipes;
create policy "rcp_recipes_tenant_all"
  on mes_recipes
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

drop policy if exists "mes_processes_tenant_all" on mes_recipe_processes;
create policy "prc_processes_tenant_all"
  on mes_recipe_processes
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

