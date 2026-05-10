create or replace function public.get_current_tax_rate(
  p_tax_category_code text,
  p_target_date date
)
returns numeric
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_tax_category_code text;
  v_match_count int;
  v_tax_rate_txt text;
  v_tax_rate numeric;
begin
  v_tax_category_code := nullif(btrim(p_tax_category_code), '');
  if v_tax_category_code is null then
    raise exception 'GTR001: p_tax_category_code is required';
  end if;

  if p_target_date is null then
    raise exception 'GTR002: p_target_date is required';
  end if;

  v_tenant := public._assert_tenant();

  with candidates as (
    select
      case
        when r.scope = 'tenant' and r.owner_id = v_tenant then 0
        else 1
      end as scope_rank,
      nullif(btrim(r.spec ->> 'tax_rate'), '') as tax_rate_txt
    from public.registry_def r
    where r.kind = 'alcohol_tax'
      and r.is_active = true
      and (
        (r.scope = 'tenant' and r.owner_id = v_tenant)
        or r.scope = 'system'
      )
      and nullif(btrim(r.spec ->> 'tax_category_code'), '') = v_tax_category_code
      and nullif(btrim(r.spec ->> 'start_date'), '') is not null
      and (r.spec ->> 'start_date')::date <= p_target_date
      and (
        nullif(btrim(r.spec ->> 'expiration_date'), '') is null
        or (r.spec ->> 'expiration_date')::date >= p_target_date
      )
  ),
  prioritized as (
    select c.scope_rank, c.tax_rate_txt
    from candidates c
    where c.scope_rank = (select min(c2.scope_rank) from candidates c2)
  )
  select count(*), max(p.tax_rate_txt)
    into v_match_count, v_tax_rate_txt
  from prioritized p;

  if v_match_count = 0 then
    raise exception 'GTR003: no tax rate definition found for category/date';
  end if;

  if v_match_count > 1 then
    raise exception 'GTR004: overlapping tax rate definitions found for category/date';
  end if;

  if v_tax_rate_txt is null then
    raise exception 'GTR005: invalid tax master data in registry_def.spec';
  end if;

  begin
    v_tax_rate := v_tax_rate_txt::numeric;
  exception
    when others then
      raise exception 'GTR005: invalid tax master data in registry_def.spec';
  end;

  if v_tax_rate < 0 then
    raise exception 'GTR005: invalid tax master data in registry_def.spec';
  end if;

  return v_tax_rate;
end;
$$;
comment on function public.get_current_tax_rate(text, date) is '{"version":1}';
