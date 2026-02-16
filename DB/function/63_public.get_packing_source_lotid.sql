create or replace view public.v_batch_source_lot_candidates as
select
  l.tenant_id,
  l.batch_id,
  l.id as source_lot_id,
  l.site_id,
  l.uom_id,
  l.status,
  l.qty,
  l.produced_at,
  l.created_at
from public.lot l
join public.lot_edge e
  on e.to_lot_id = l.id
 and e.tenant_id = l.tenant_id
where e.from_lot_id is null
  and e.edge_type = 'PRODUCE'::public.lot_edge_type;

create or replace function public.get_packing_source_lotid(p_batch_id uuid)
returns uuid
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_source_lot_id uuid;
begin
  if p_batch_id is null then
    raise exception 'p_batch_id is required';
  end if;

  v_tenant := public._assert_tenant();

  select v.source_lot_id
    into v_source_lot_id
  from public.v_batch_source_lot_candidates v
  where v.tenant_id = v_tenant
    and v.batch_id = p_batch_id
    and v.status <> 'void'
    and v.qty > 0
  order by v.produced_at desc nulls last, v.created_at desc
  limit 1;

  return v_source_lot_id;
end;
$$;
