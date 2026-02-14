create or replace function public.movement_get_detail(p_movement_id uuid)
returns jsonb
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_result jsonb;
begin
  if p_movement_id is null then
    raise exception 'p_movement_id is required';
  end if;

  v_tenant := public._assert_tenant();

  select jsonb_build_object(
    'header', to_jsonb(m),
    'src_site', to_jsonb(ss),
    'dest_site', to_jsonb(ds),
    'lot_event', to_jsonb(le),
    'lines', coalesce((
      select jsonb_agg(to_jsonb(l) order by l.line_no)
      from public.inv_movement_lines l
      where l.tenant_id = v_tenant and l.movement_id = m.id
    ), '[]'::jsonb)
  ) into v_result
  from public.inv_movements m
  left join public.mst_sites ss on ss.id = m.src_site_id
  left join public.mst_sites ds on ds.id = m.dest_site_id
  left join public.lot_event le on le.id = m.lot_event_id
  where m.tenant_id = v_tenant
    and m.id = p_movement_id;

  if v_result is null then
    raise exception 'Movement not found: %', p_movement_id;
  end if;

  return v_result;
end;
$$;
