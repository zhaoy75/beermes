-- public.mst_sites definition

-- Drop table

-- DROP TABLE public.mst_sites;

CREATE TABLE public.mst_sites (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	tenant_id uuid DEFAULT ((auth.jwt() -> 'app_metadata'::text) ->> 'tenant_id'::text)::uuid NOT NULL,
	"name" text NOT NULL,
	site_type_id uuid NOT NULL,
	parent_site_id uuid NULL,
	address jsonb NULL,
	contact jsonb NULL,
	notes text NULL,
	active bool DEFAULT true NULL,
	created_at timestamptz DEFAULT now() NULL,
	node_kind text DEFAULT 'SITE'::text NOT NULL,
	owner_type text DEFAULT 'OWN'::text NOT NULL,
	owner_name text NULL,
	sort_order int4 DEFAULT 0 NOT NULL,
	CONSTRAINT mst_sites_pkey PRIMARY KEY (id),
	CONSTRAINT mst_sites_parent_site_id_fkey FOREIGN KEY (parent_site_id) REFERENCES public.mst_sites(id)
);
CREATE INDEX idx_mst_sites_tenant_type ON public.mst_sites USING btree (tenant_id, site_type_id);


-- Table Triggers

create trigger trg_sites_same_tenant_type before
insert
    or
update
    on
    public.mst_sites for each row execute function trg_sites_same_tenant_type();

-- Permissions

ALTER TABLE public.mst_sites OWNER TO postgres;
GRANT ALL ON TABLE public.mst_sites TO postgres;
GRANT ALL ON TABLE public.mst_sites TO anon;
GRANT ALL ON TABLE public.mst_sites TO authenticated;
GRANT ALL ON TABLE public.mst_sites TO service_role;

alter table public.mst_sites enable row level security;

drop policy if exists mst_sites on public.mst_sites;
create policy mst_sites_rls on public.mst_sites
for all
using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);


alter table public.mst_sites
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;


