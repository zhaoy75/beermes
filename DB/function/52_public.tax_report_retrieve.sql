create or replace function public.tax_report_retrieve(
  p_year int,
  p_month int
)
returns jsonb
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_result jsonb;
begin
  if p_month is null or p_month < 1 or p_month > 12 then
    raise exception 'p_month must be between 1 and 12';
  end if;

  v_tenant := public._assert_tenant();

  select to_jsonb(t)
    into v_result
  from public.tax_reports t
  where t.tenant_id = v_tenant
    and t.tax_year = p_year
    and t.tax_month = p_month;

  if v_result is null then
    raise exception 'Tax report not found: year=%, month=%', p_year, p_month;
  end if;

  return v_result;
end;
$$;
