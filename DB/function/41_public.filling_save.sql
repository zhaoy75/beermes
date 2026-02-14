create or replace function public.filling_save(
  p_movement_id uuid,
  p_doc jsonb
)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_lot_event_id uuid;
begin
  if p_movement_id is null then
    raise exception 'p_movement_id is required';
  end if;

  v_tenant := public._assert_tenant();

  update public.inv_movements m
     set status = coalesce(p_doc ->> 'status', m.status),
         movement_at = coalesce(nullif(p_doc ->> 'movement_at', '')::timestamptz, m.movement_at),
         reason = coalesce(p_doc ->> 'reason', m.reason),
         meta = coalesce(p_doc -> 'meta', m.meta),
         notes = coalesce(p_doc ->> 'notes', m.notes)
   where m.id = p_movement_id
     and m.tenant_id = v_tenant
  returning m.lot_event_id into v_lot_event_id;

  if not found then
    raise exception 'Movement not found: %', p_movement_id;
  end if;

  if jsonb_typeof(p_doc -> 'lines') = 'array' then
    perform public._upsert_movement_lines(p_movement_id, p_doc -> 'lines');

    if v_lot_event_id is not null then
      delete from public.lot_event_line l
      where l.tenant_id = v_tenant
        and l.lot_event_id = v_lot_event_id;

      insert into public.lot_event_line (
        tenant_id, lot_event_id, line_no, lot_id,
        material_id, package_id, batch_id, qty, uom_id, notes, meta
      )
      select v_tenant, v_lot_event_id,
             coalesce((x.value ->> 'line_no')::int, row_number() over ()),
             nullif(x.value ->> 'lot_id', '')::uuid,
             nullif(x.value ->> 'material_id', '')::uuid,
             nullif(x.value ->> 'package_id', '')::uuid,
             nullif(x.value ->> 'batch_id', '')::uuid,
             coalesce((x.value ->> 'qty')::numeric, 0),
             (x.value ->> 'uom_id')::uuid,
             x.value ->> 'notes',
             coalesce(x.value -> 'meta', '{}'::jsonb)
      from jsonb_array_elements(p_doc -> 'lines') x(value);
    end if;
  end if;

  if v_lot_event_id is not null then
    update public.lot_event e
       set status = coalesce(p_doc ->> 'status', e.status),
           event_at = coalesce(nullif(p_doc ->> 'movement_at', '')::timestamptz, e.event_at),
           reason = coalesce(p_doc ->> 'reason', e.reason),
           meta = coalesce(p_doc -> 'meta', e.meta),
           notes = coalesce(p_doc ->> 'notes', e.notes)
     where e.id = v_lot_event_id
       and e.tenant_id = v_tenant;
  end if;

  return p_movement_id;
end;
$$;
