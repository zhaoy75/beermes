create or replace function public.ensure_dummy_domestic_customer_site()
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_site_type_id uuid;
  v_site_id uuid;
  v_site_name text := '国内移出完了ダミー取引先';
  v_owner_type text := 'OUTSIDE';
  v_owner_name text := 'SYSTEM_DOMESTIC_REMOVAL_COMPLETE';
  v_notes text := 'System-managed dummy DOMESTIC_CUSTOMER site for domestic removal complete';
  v_sort_order integer := 999999;
begin
  v_tenant := public._assert_tenant();

  select rd.def_id
    into v_site_type_id
  from public.registry_def rd
  where rd.kind = 'site_type'
    and upper(rd.def_key) = 'DOMESTIC_CUSTOMER'
    and rd.is_active = true
    and (
      (rd.scope = 'tenant' and rd.owner_id = v_tenant)
      or rd.scope = 'system'
    )
  order by
    case
      when rd.scope = 'tenant' and rd.owner_id = v_tenant then 0
      else 1
    end,
    rd.updated_at desc,
    rd.created_at desc,
    rd.def_id
  limit 1;

  if v_site_type_id is null then
    raise exception 'EDCS001: DOMESTIC_CUSTOMER site_type not found for tenant %', v_tenant;
  end if;

  perform pg_advisory_xact_lock(
    hashtext(v_tenant::text),
    hashtext('ensure_dummy_domestic_customer_site')
  );

  select s.id
    into v_site_id
  from public.mst_sites s
  where s.tenant_id = v_tenant
    and s.site_type_id = v_site_type_id
    and s.owner_type = v_owner_type
    and coalesce(s.owner_name, '') = v_owner_name
  order by s.created_at, s.id
  limit 1;

  if v_site_id is not null then
    update public.mst_sites s
       set name = v_site_name,
           parent_site_id = null,
           notes = v_notes,
           active = true,
           sort_order = v_sort_order
     where s.tenant_id = v_tenant
       and s.id = v_site_id;

    return v_site_id;
  end if;

  insert into public.mst_sites (
    tenant_id,
    name,
    site_type_id,
    parent_site_id,
    notes,
    active,
    owner_type,
    owner_name,
    sort_order
  )
  values (
    v_tenant,
    v_site_name,
    v_site_type_id,
    null,
    v_notes,
    true,
    v_owner_type,
    v_owner_name,
    v_sort_order
  )
  returning id into v_site_id;

  return v_site_id;
end;
$$;
