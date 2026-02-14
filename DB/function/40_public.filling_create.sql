create or replace function public.filling_create(p_doc jsonb)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_movement_id uuid;
  v_lot_event_id uuid;
  v_line jsonb;
  v_line_no int := 0;
  v_tax_event text;
begin
  if p_doc is null then
    raise exception 'p_doc is required';
  end if;

  v_tenant := public._assert_tenant();

  insert into public.inv_movements (
    tenant_id, doc_no, doc_type, status, movement_at,
    src_site_id, dest_site_id, external_ref, reason, meta, notes, created_by
  ) values (
    v_tenant,
    p_doc ->> 'doc_no',
    coalesce((p_doc ->> 'doc_type')::inv_doc_type, 'production_receipt'::inv_doc_type),
    coalesce(p_doc ->> 'status', 'open'),
    coalesce(nullif(p_doc ->> 'movement_at', '')::timestamptz, now()),
    nullif(p_doc ->> 'src_site_id', '')::uuid,
    nullif(p_doc ->> 'dest_site_id', '')::uuid,
    p_doc ->> 'external_ref',
    p_doc ->> 'reason',
    coalesce(p_doc -> 'meta', '{}'::jsonb) || jsonb_build_object('movement_intent', coalesce((p_doc->'meta'->>'movement_intent'),'PACKAGE_FILL')),
    p_doc ->> 'notes',
    nullif(p_doc ->> 'created_by', '')::uuid
  ) returning id into v_movement_id;

  begin
    v_tax_event := public._derive_tax_event(coalesce(p_doc -> 'tax_context', '{}'::jsonb));
  exception when others then
    v_tax_event := null;
  end;

  insert into public.lot_event (
    tenant_id, event_no, event_type, status, event_at,
    src_site_id, dest_site_id, reason, meta, notes, created_by
  ) values (
    v_tenant,
    coalesce(p_doc ->> 'event_no', p_doc ->> 'doc_no'),
    'production'::lot_event_type,
    coalesce(p_doc ->> 'status', 'open'),
    coalesce(nullif(p_doc ->> 'movement_at', '')::timestamptz, now()),
    nullif(p_doc ->> 'src_site_id', '')::uuid,
    nullif(p_doc ->> 'dest_site_id', '')::uuid,
    p_doc ->> 'reason',
    coalesce(p_doc -> 'meta', '{}'::jsonb) || coalesce(case when v_tax_event is not null then jsonb_build_object('tax_event', v_tax_event) end, '{}'::jsonb),
    p_doc ->> 'notes',
    nullif(p_doc ->> 'created_by', '')::uuid
  ) returning id into v_lot_event_id;

  update public.inv_movements
     set lot_event_id = v_lot_event_id
   where id = v_movement_id
     and tenant_id = v_tenant;

  if jsonb_typeof(p_doc -> 'lines') <> 'array' then
    raise exception 'lines[] is required';
  end if;

  for v_line in select value from jsonb_array_elements(p_doc -> 'lines')
  loop
    v_line_no := v_line_no + 1;

    insert into public.inv_movement_lines (
      tenant_id, movement_id, line_no,
      material_id, package_id, batch_id, lot_id,
      qty, uom_id, notes, meta
    ) values (
      v_tenant,
      v_movement_id,
      coalesce((v_line ->> 'line_no')::int, v_line_no),
      nullif(v_line ->> 'material_id', '')::uuid,
      nullif(v_line ->> 'package_id', '')::uuid,
      nullif(v_line ->> 'batch_id', '')::uuid,
      nullif(v_line ->> 'lot_id', '')::uuid,
      coalesce((v_line ->> 'qty')::numeric, 0),
      (v_line ->> 'uom_id')::uuid,
      v_line ->> 'notes',
      coalesce(v_line -> 'meta', '{}'::jsonb)
    );

    insert into public.lot_event_line (
      tenant_id, lot_event_id, line_no,
      lot_id, material_id, package_id, batch_id,
      qty, uom_id, notes, meta
    ) values (
      v_tenant,
      v_lot_event_id,
      coalesce((v_line ->> 'line_no')::int, v_line_no),
      nullif(v_line ->> 'lot_id', '')::uuid,
      nullif(v_line ->> 'material_id', '')::uuid,
      nullif(v_line ->> 'package_id', '')::uuid,
      nullif(v_line ->> 'batch_id', '')::uuid,
      coalesce((v_line ->> 'qty')::numeric, 0),
      (v_line ->> 'uom_id')::uuid,
      v_line ->> 'notes',
      coalesce(v_line -> 'meta', '{}'::jsonb)
    );
  end loop;

  return v_movement_id;
end;
$$;
