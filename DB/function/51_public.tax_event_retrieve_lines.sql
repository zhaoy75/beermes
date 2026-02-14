create or replace function public.tax_event_retrieve_lines(p_lot_event_id uuid)
returns jsonb
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_result jsonb;
begin
  if p_lot_event_id is null then
    raise exception 'p_lot_event_id is required';
  end if;

  v_tenant := public._assert_tenant();

  select jsonb_build_object(
    'event', to_jsonb(e),
    'lines', coalesce((
      select jsonb_agg(
        to_jsonb(l) || jsonb_build_object('lot_no', lt.lot_no)
        order by l.line_no
      )
      from public.lot_event_line l
      left join public.lot lt on lt.id = l.lot_id
      where l.tenant_id = v_tenant
        and l.lot_event_id = e.id
    ), '[]'::jsonb)
  ) into v_result
  from public.lot_event e
  where e.tenant_id = v_tenant
    and e.id = p_lot_event_id;

  if v_result is null then
    raise exception 'Lot event not found: %', p_lot_event_id;
  end if;

  return v_result;
end;
$$;
