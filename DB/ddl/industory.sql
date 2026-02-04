-- public.industry definition

-- Drop table

-- DROP TABLE public.industry;

CREATE TABLE public.industry (
	industry_id uuid DEFAULT gen_random_uuid() NOT NULL,
	code text NOT NULL,
	"name" text NOT NULL,
	name_i18n jsonb NULL,
	description text NULL,
	is_active bool DEFAULT true NOT NULL,
	sort_order int4 DEFAULT 0 NOT NULL,
	meta jsonb DEFAULT '{}'::jsonb NOT NULL,
	created_at timestamptz DEFAULT now() NOT NULL,
	updated_at timestamptz DEFAULT now() NOT NULL,
	CONSTRAINT ck_industry_meta_object CHECK ((jsonb_typeof(meta) = 'object'::text)),
	CONSTRAINT ck_industry_name_i18n_object CHECK (((name_i18n IS NULL) OR (jsonb_typeof(name_i18n) = 'object'::text))),
	CONSTRAINT industry_pkey PRIMARY KEY (industry_id),
	CONSTRAINT uq_industry_code UNIQUE (code)
);

-- Table Triggers

create trigger trg_industry_updated_at before
update
    on
    public.industry for each row execute function set_updated_at();

-- Permissions

ALTER TABLE public.industry OWNER TO postgres;
GRANT ALL ON TABLE public.industry TO postgres;
GRANT ALL ON TABLE public.industry TO anon;
GRANT ALL ON TABLE public.industry TO authenticated;
GRANT ALL ON TABLE public.industry TO service_role;