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

COMMENT ON COLUMN public.mes_recipes.basic_template_flg IS 'basic template can not be delete.';
COMMENT ON COLUMN public.mes_recipes.category IS 'tax category';

ALTER TABLE public.mes_recipes OWNER TO postgres;
GRANT ALL ON TABLE public.mes_recipes TO postgres;
GRANT ALL ON TABLE public.mes_recipes TO anon;
GRANT ALL ON TABLE public.mes_recipes TO authenticated;
GRANT ALL ON TABLE public.mes_recipes TO service_role;

ALTER TABLE public.mes_recipes
  ADD CONSTRAINT rcp_recipes_category_fkey FOREIGN KEY (category) REFERENCES public.mst_category(id);

ALTER TABLE mes_recipes
  ALTER COLUMN tenant_id SET DEFAULT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

-- public.mes_recipe_steps definition

CREATE TABLE IF NOT EXISTS public.mes_recipe_steps (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	tenant_id uuid DEFAULT ((auth.jwt() -> 'app_metadata'::text) ->> 'tenant_id'::text)::uuid NOT NULL,
	recipe_id uuid NOT NULL,
	step_no int4 NOT NULL,
	step prc_step_type NOT NULL,
	target_params jsonb DEFAULT '{}'::jsonb NULL,
	qa_checks jsonb DEFAULT '[]'::jsonb NULL,
	notes text NULL,
	created_at timestamptz DEFAULT now() NULL,
	CONSTRAINT rcp_steps_pkey PRIMARY KEY (id),
	CONSTRAINT rcp_steps_tenant_recipe_step_no_key UNIQUE (tenant_id, recipe_id, step_no)
);

ALTER TABLE IF EXISTS public.mes_recipe_steps
  ADD COLUMN IF NOT EXISTS recipe_id uuid;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name = 'mes_recipe_processes'
  ) THEN
    UPDATE public.mes_recipe_steps s
       SET recipe_id = p.recipe_id
      FROM public.mes_recipe_processes p
     WHERE s.recipe_id IS NULL
       AND s.process_id = p.id;
  END IF;
END $$;

ALTER TABLE public.mes_recipe_steps OWNER TO postgres;
GRANT ALL ON TABLE public.mes_recipe_steps TO postgres;
GRANT ALL ON TABLE public.mes_recipe_steps TO anon;
GRANT ALL ON TABLE public.mes_recipe_steps TO authenticated;
GRANT ALL ON TABLE public.mes_recipe_steps TO service_role;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conname = 'rcp_steps_recipe_id_fkey'
      AND conrelid = 'public.mes_recipe_steps'::regclass
  ) THEN
    ALTER TABLE public.mes_recipe_steps
      ADD CONSTRAINT rcp_steps_recipe_id_fkey
      FOREIGN KEY (recipe_id) REFERENCES public.mes_recipes(id) ON DELETE CASCADE;
  END IF;
END $$;

ALTER TABLE mes_recipe_steps
  ALTER COLUMN tenant_id SET DEFAULT (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

CREATE INDEX IF NOT EXISTS idx_rcp_steps_tenant_recipe_step_no
  ON mes_recipe_steps (tenant_id, recipe_id, step_no);

ALTER TABLE mes_recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE mes_recipe_steps ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "mes_recipes_tenant_all" ON mes_recipes;
DROP POLICY IF EXISTS "rcp_recipes_tenant_all" ON mes_recipes;
CREATE POLICY "rcp_recipes_tenant_all"
  ON mes_recipes
  FOR ALL
  USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  WITH CHECK (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

DROP POLICY IF EXISTS "mes_recipe_steps_tenant_all" ON mes_recipe_steps;
DROP POLICY IF EXISTS "rcp_steps_tenant_all" ON mes_recipe_steps;
CREATE POLICY "rcp_steps_tenant_all"
  ON mes_recipe_steps
  FOR ALL
  USING (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  WITH CHECK (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

-- Legacy public.mes_recipe_processes has been removed from the recipe model.
