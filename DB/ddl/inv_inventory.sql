-- public.inv_inventory definition

-- Drop table

-- DROP TABLE public.inv_inventory;

CREATE TABLE public.inv_inventory (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	tenant_id uuid DEFAULT ((auth.jwt() -> 'app_metadata'::text) ->> 'tenant_id'::text)::uuid NOT NULL,
	material_id uuid NOT NULL,
	site_id uuid NOT NULL,
	qty numeric DEFAULT 0 NOT NULL,
	uom_id uuid NOT NULL,
	batch_code text NULL,
	created_at timestamptz DEFAULT now() NULL,
	CONSTRAINT inv_inventory_pkey PRIMARY KEY (id)
);
CREATE INDEX idx_inv_inventory_batch_code ON public.inv_inventory USING btree (batch_code);
CREATE INDEX idx_inv_inventory_material ON public.inv_inventory USING btree (material_id);
CREATE INDEX idx_inv_inventory_tenant_wh_material ON public.inv_inventory USING btree (tenant_id, site_id, material_id);

-- Permissions

ALTER TABLE public.inv_inventory OWNER TO postgres;
GRANT ALL ON TABLE public.inv_inventory TO postgres;
GRANT ALL ON TABLE public.inv_inventory TO anon;
GRANT ALL ON TABLE public.inv_inventory TO authenticated;
GRANT ALL ON TABLE public.inv_inventory TO service_role;


-- public.inv_inventory foreign keys

ALTER TABLE public.inv_inventory ADD CONSTRAINT inv_inventory_site_id_fkey FOREIGN KEY (site_id) REFERENCES public.mst_sites(id);
ALTER TABLE public.inv_inventory ADD CONSTRAINT inv_inventory_uom_id_fkey FOREIGN KEY (uom_id) REFERENCES public.mst_uom(id);

create index if not exists idx_inv_inventory_material
  on inv_inventory (material_id);
create index if not exists idx_inv_inventory_tenant_wh_material
  on inv_inventory (tenant_id, site_id, material_id);
create index if not exists idx_inv_inventory_batch_code
  on inv_inventory (batch_code);

alter table inv_inventory   enable row level security;


-- Policies (drop-if-exists then create)
-- Masters

-- Inventory

drop policy if exists "inv_inventory_tenant_all" on inv_inventory;
create policy "inv_inventory_tenant_all"
  on inv_inventory
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);
