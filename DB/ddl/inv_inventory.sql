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


-- Enforce: inv_inventory only stores lots for sites whose site_type inventory_count_flg is false.
create or replace function public.trg_inv_inventory_site_inventory_count_flg()
returns trigger
language plpgsql
as $$
declare
  v_inventory_count_flg boolean;
begin
  select (r.spec ->> 'inventory_count_flg')::boolean
    into v_inventory_count_flg
  from public.mst_sites s
  join public.registry_def r
    on r.def_id = s.site_type_id
   and r.kind = 'site_type'
   and r.is_active = true
  where s.id = new.site_id
    and s.tenant_id = new.tenant_id;

  if not found then
    raise exception 'inv_inventory.site_id must reference mst_sites row in same tenant with active site_type';
  end if;

  if coalesce(v_inventory_count_flg, true) <> false then
    raise exception 'inv_inventory.site_id must reference site_type where inventory_count_flg=false';
  end if;

  return new;
end;
$$;

drop trigger if exists trg_inv_inventory_site_inventory_count_flg on public.inv_inventory;
create trigger trg_inv_inventory_site_inventory_count_flg
before insert or update on public.inv_inventory
for each row execute function public.trg_inv_inventory_site_inventory_count_flg();
