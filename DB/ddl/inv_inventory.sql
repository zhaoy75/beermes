-- public.inv_inventory definition

-- Drop table

DROP TABLE public.inv_inventory;

CREATE TABLE public.inv_inventory (
	id uuid DEFAULT gen_random_uuid() NOT NULL,
	tenant_id uuid NOT NULL,

	site_id uuid NOT NULL references public.mst_sites(id),
	lot_id uuid NOT NULL references public.lot(id),
	qty numeric DEFAULT 0 NOT NULL,
	uom_id uuid NOT NULL,
	
	created_at timestamptz DEFAULT now() NULL,
	CONSTRAINT inv_inventory_pkey PRIMARY KEY (id)
);



-- Permissions
alter table inv_inventory
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

ALTER TABLE public.inv_inventory OWNER TO postgres;
GRANT ALL ON TABLE public.inv_inventory TO postgres;
GRANT ALL ON TABLE public.inv_inventory TO anon;
GRANT ALL ON TABLE public.inv_inventory TO authenticated;
GRANT ALL ON TABLE public.inv_inventory TO service_role;


-- public.inv_inventory foreign keys

ALTER TABLE public.inv_inventory ADD CONSTRAINT inv_inventory_lot_id_fkey FOREIGN KEY (lot_id) REFERENCES public.lot(id);
ALTER TABLE public.inv_inventory ADD CONSTRAINT inv_inventory_uom_id_fkey FOREIGN KEY (uom_id) REFERENCES public.mst_uom(id);



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
