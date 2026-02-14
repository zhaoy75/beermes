create or replace function public.lot_trace_upstream(p_lot_id uuid)
returns table (
  depth int,
  lot_id uuid,
  related_lot_id uuid,
  relation_type text,
  movement_id uuid,
  lot_event_id uuid,
  occurred_at timestamptz
)
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_batch_id uuid;
begin
  if p_lot_id is null then
    raise exception 'p_lot_id is required';
  end if;

  v_tenant := public._assert_tenant();

  select l.batch_id into v_batch_id
  from public.lot l
  where l.id = p_lot_id and l.tenant_id = v_tenant;

  if v_batch_id is null then
    return query
    select 1, p_lot_id, null::uuid, 'movement'::text, m.id, m.lot_event_id, m.movement_at
    from public.inv_movements m
    join public.inv_movement_lines ml
      on ml.movement_id = m.id
     and ml.tenant_id = v_tenant
    where m.tenant_id = v_tenant
      and ml.lot_id = p_lot_id
    order by m.movement_at asc;
    return;
  end if;

  return query
  with rel as (
    select 1 as depth,
           p_lot_id as lot_id,
           l2.id as related_lot_id,
           r.relation_type::text as relation_type,
           null::uuid as movement_id,
           null::uuid as lot_event_id,
           r.effective_at as occurred_at
    from public.mes_batch_relation r
    join public.lot l2
      on l2.batch_id = r.src_batch_id
     and l2.tenant_id = v_tenant
    where r.tenant_id = v_tenant
      and r.dst_batch_id = v_batch_id
  )
  select * from rel
  union all
  select 1, p_lot_id, null::uuid, 'movement'::text, m.id, m.lot_event_id, m.movement_at
  from public.inv_movements m
  join public.inv_movement_lines ml
    on ml.movement_id = m.id
   and ml.tenant_id = v_tenant
  where m.tenant_id = v_tenant
    and ml.lot_id = p_lot_id
  order by occurred_at asc;
end;
$$;
