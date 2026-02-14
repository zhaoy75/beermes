create or replace function public._upsert_movement_lines(
  p_movement_id uuid,
  p_lines jsonb
)
returns void
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_line jsonb;
  v_exists boolean;
begin
  if p_movement_id is null then
    raise exception 'p_movement_id is required';
  end if;
  if p_lines is null or jsonb_typeof(p_lines) <> 'array' then
    raise exception 'p_lines must be a json array';
  end if;

  v_tenant := public._assert_tenant();

  select exists (
    select 1
    from public.inv_movements m
    where m.id = p_movement_id
      and m.tenant_id = v_tenant
  ) into v_exists;

  if not v_exists then
    raise exception 'Movement not found: %', p_movement_id;
  end if;

  delete from public.inv_movement_lines l
  where l.tenant_id = v_tenant
    and l.movement_id = p_movement_id;

  for v_line in select value from jsonb_array_elements(p_lines)
  loop
    insert into public.inv_movement_lines (
      tenant_id, movement_id, line_no,
      material_id, package_id, batch_id, lot_id,
      qty, uom_id, notes, meta
    ) values (
      v_tenant,
      p_movement_id,
      coalesce((v_line ->> 'line_no')::int, 0),
      nullif(v_line ->> 'material_id', '')::uuid,
      nullif(v_line ->> 'package_id', '')::uuid,
      nullif(v_line ->> 'batch_id', '')::uuid,
      nullif(v_line ->> 'lot_id', '')::uuid,
      coalesce((v_line ->> 'qty')::numeric, 0),
      (v_line ->> 'uom_id')::uuid,
      v_line ->> 'notes',
      coalesce(v_line -> 'meta', '{}'::jsonb)
    );
  end loop;
end;
$$;
