create or replace function public._assert_non_negative_lot_qty(p_lot_id uuid)
returns void
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_qty numeric;
begin
  if p_lot_id is null then
    raise exception 'p_lot_id is required';
  end if;

  v_tenant := public._assert_tenant();

  select l.qty into v_qty
  from public.lot l
  where l.id = p_lot_id
    and l.tenant_id = v_tenant;

  if v_qty is null then
    raise exception 'Lot not found: %', p_lot_id;
  end if;

  if v_qty < 0 then
    raise exception 'Lot qty must not be negative. lot_id=%, qty=%', p_lot_id, v_qty;
  end if;
end;
$$;
