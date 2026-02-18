-- Enforce inv_inventory rows only for site_type where spec.inventory_count_flg = false

create or replace function public.trg_inv_inventory_site_inventory_count_flg()
returns trigger
language plpgsql
as $function$
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
end $function$;

drop trigger if exists trg_inv_inventory_site_inventory_count_flg on public.inv_inventory;
create trigger trg_inv_inventory_site_inventory_count_flg
before insert or update on public.inv_inventory
for each row execute function public.trg_inv_inventory_site_inventory_count_flg();
