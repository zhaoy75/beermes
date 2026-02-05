
CREATE TABLE IF NOT EXISTS industry (
  industry_id uuid primary key default gen_random_uuid(),

  -- Stable code used by API / JSON / config
  code text NOT NULL,              -- e.g. 'CRAFT_BEER'

  -- Display name
  name text NOT NULL,              -- e.g. 'Craft Beer'

  -- Optional i18n name
  name_i18n jsonb NULL,            -- {"ja":"クラフトビール","en":"Craft Beer"}

  description text NULL,

  is_active boolean NOT NULL DEFAULT true,
  sort_order int NOT NULL DEFAULT 0,

  meta jsonb NOT NULL DEFAULT '{}'::jsonb,

  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),

  CONSTRAINT uq_industry_code
    UNIQUE (code),

  CONSTRAINT ck_industry_name_i18n_object
    CHECK (name_i18n IS NULL OR jsonb_typeof(name_i18n) = 'object'),

  CONSTRAINT ck_industry_meta_object
    CHECK (jsonb_typeof(meta) = 'object')
);



CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_industry_updated_at ON industry;
CREATE TRIGGER trg_industry_updated_at
BEFORE UPDATE ON industry
FOR EACH ROW
EXECUTE FUNCTION set_updated_at();

-- Permissions

ALTER TABLE public.industry OWNER TO postgres;
GRANT ALL ON TABLE public.industry TO postgres;
GRANT ALL ON TABLE public.industry TO anon;
GRANT ALL ON TABLE public.industry TO authenticated;
GRANT ALL ON TABLE public.industry TO service_role;