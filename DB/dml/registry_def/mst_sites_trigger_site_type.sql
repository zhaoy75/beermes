-- Update mst_sites tenant/type validation to use registry_def (site_type)
-- Replaces trg_sites_same_tenant_type to reference registry_def instead of mst_site_types

create or replace function public.trg_sites_same_tenant_type()
returns trigger language plpgsql as $$
declare
  ok boolean;
begin
  if new.site_type_id is not null then
    select
      case
        when r.scope = 'system' then true
        when r.scope in ('tenant','user') and r.owner_id = new.tenant_id then true
        else false
      end
    into ok
    from public.registry_def r
    where r.def_id = new.site_type_id
      and r.kind = 'site_type'
      and r.is_active = true;

    if not coalesce(ok,false) then
      raise exception 'mst_sites.site_type_id is invalid or not accessible for tenant';
    end if;
  end if;
  return new;
end $$;

drop trigger if exists trg_sites_same_tenant_type on public.mst_sites;
create trigger trg_sites_same_tenant_type
before insert or update on public.mst_sites
for each row execute function public.trg_sites_same_tenant_type();
