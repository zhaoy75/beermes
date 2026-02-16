create or replace function public.lot_dag_get_by_batch(p_batch_id uuid)
returns jsonb
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_result jsonb;
begin
  if p_batch_id is null then
    raise exception 'p_batch_id is required';
  end if;

  v_tenant := public._assert_tenant();

  with nodes as (
    select
      l.id,
      l.lot_no,
      l.batch_id,
      l.site_id,
      l.qty,
      l.uom_id,
      l.status,
      l.produced_at,
      l.created_at
    from public.lot l
    where l.tenant_id = v_tenant
      and l.batch_id = p_batch_id
  ),
  edges as (
    select
      e.id,
      e.from_lot_id as source,
      e.to_lot_id as target,
      e.edge_type::text as edge_type,
      e.qty,
      e.uom_id,
      e.movement_id,
      e.created_at
    from public.lot_edge e
    left join public.lot lf
      on lf.id = e.from_lot_id
     and lf.tenant_id = v_tenant
    left join public.lot lt
      on lt.id = e.to_lot_id
     and lt.tenant_id = v_tenant
    where e.tenant_id = v_tenant
      and (
        lf.batch_id = p_batch_id
        or lt.batch_id = p_batch_id
      )
  ),
  source_lot as (
    select l.id
    from public.lot l
    join public.lot_edge e
      on e.to_lot_id = l.id
     and e.tenant_id = l.tenant_id
    where l.tenant_id = v_tenant
      and l.batch_id = p_batch_id
      and e.from_lot_id is null
      and e.edge_type = 'PRODUCE'::public.lot_edge_type
      and l.status <> 'void'
      and l.qty > 0
    order by l.produced_at desc nulls last, l.created_at desc
    limit 1
  )
  select jsonb_build_object(
    'batch_id', p_batch_id,
    'source_lot_id', (select id from source_lot),
    'nodes', coalesce((
      select jsonb_agg(to_jsonb(n) order by n.produced_at nulls last, n.created_at, n.id)
      from nodes n
    ), '[]'::jsonb),
    'edges', coalesce((
      select jsonb_agg(to_jsonb(e) order by e.created_at, e.id)
      from edges e
    ), '[]'::jsonb)
  ) into v_result;

  return v_result;
end;
$$;
