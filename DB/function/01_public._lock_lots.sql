create or replace function public._lock_lots(p_lot_ids uuid[])
returns void
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_missing int;
begin
  if p_lot_ids is null or coalesce(array_length(p_lot_ids, 1), 0) = 0 then
    raise exception 'p_lot_ids is required';
  end if;

  v_tenant := public._assert_tenant();

  with ids as (
    select distinct unnest(p_lot_ids) as id
  )
  select count(*) into v_missing
  from ids i
  left join public.lot l
    on l.id = i.id
   and l.tenant_id = v_tenant
  where l.id is null;

  if v_missing > 0 then
    raise exception 'Some lot ids are not visible for current tenant';
  end if;

  perform 1
  from public.lot l
  where l.tenant_id = v_tenant
    and l.id = any(p_lot_ids)
  order by l.id
  for update;
end;
$$;
