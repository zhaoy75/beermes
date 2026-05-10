create or replace function public.tax_report_mark_stale_for_movement(p_movement_id uuid)
returns int
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_count int;
  v_locked_report text;
begin
  if p_movement_id is null then
    raise exception 'TRM001: p_movement_id is required';
  end if;

  v_tenant := public._assert_tenant();

  select format('%s %s/%s', r.status, r.tax_year, lpad(r.tax_month::text, 2, '0'))
    into v_locked_report
  from public.tax_report_movement_refs ref
  join public.tax_reports r
    on r.tenant_id = ref.tenant_id
   and r.id = ref.tax_report_id
  where ref.tenant_id = v_tenant
    and ref.movement_id = p_movement_id
    and r.status in ('submitted', 'approved')
  order by r.tax_year desc, r.tax_month desc
  limit 1;

  if v_locked_report is not null then
    raise exception 'TRM002: movement is locked by tax report (%)', v_locked_report;
  end if;

  update public.tax_reports r
     set status = 'stale'
   where r.tenant_id = v_tenant
     and r.status = 'draft'
     and exists (
       select 1
       from public.tax_report_movement_refs ref
       where ref.tenant_id = v_tenant
         and ref.tax_report_id = r.id
         and ref.movement_id = p_movement_id
     );

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;
comment on function public.tax_report_mark_stale_for_movement(uuid) is '{"version":1}';
