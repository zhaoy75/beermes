create or replace function public.lot_trace_full(
  p_lot_id uuid,
  p_max_depth int default 10
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
  if p_lot_id is null then
    raise exception 'p_lot_id is required';
  end if;
  if p_max_depth is null or p_max_depth <= 0 or p_max_depth > 100 then
    raise exception 'p_max_depth must be between 1 and 100';
  end if;

  v_tenant := public._assert_tenant();

  with up_edges as (
    select * from public.lot_trace_upstream(p_lot_id)
  ), down_edges as (
    select * from public.lot_trace_downstream(p_lot_id)
  ), edges as (
    select * from up_edges
    union all
    select * from down_edges
  ), node_ids as (
    select p_lot_id as id
    union
    select related_lot_id from edges where related_lot_id is not null
  )
  select jsonb_build_object(
    'root_lot_id', p_lot_id,
    'nodes', coalesce((
      select jsonb_agg(to_jsonb(l))
      from public.lot l
      join node_ids n on n.id = l.id
      where l.tenant_id = v_tenant
    ), '[]'::jsonb),
    'edges', coalesce((
      select jsonb_agg(to_jsonb(e)) from edges e
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;
