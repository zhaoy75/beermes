create or replace function public._derive_tax_event(p_context jsonb)
returns text
language plpgsql
stable
security invoker
as $$
declare
  v_decisions jsonb;
  v_tax_event text;
begin
  if p_context is null then
    raise exception 'p_context is required';
  end if;

  v_decisions := public.movement_rules_get_tax_decisions(
    p_context ->> 'movement_intent',
    p_context ->> 'src_site_type',
    p_context ->> 'dst_site_type',
    p_context ->> 'lot_tax_type'
  );

  select d.item ->> 'tax_event'
    into v_tax_event
  from jsonb_array_elements(v_decisions) as d(item)
  where coalesce((d.item ->> 'default')::boolean, false)
  limit 1;

  if v_tax_event is null then
    select d.item ->> 'tax_event'
      into v_tax_event
    from jsonb_array_elements(v_decisions) as d(item)
    limit 1;
  end if;

  if v_tax_event is null then
    raise exception 'No tax event derived for provided context';
  end if;

  return v_tax_event;
end;
$$;
