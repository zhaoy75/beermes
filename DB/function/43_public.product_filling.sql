create or replace function public.product_filling(p_doc jsonb)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_movement_id uuid;
  v_movement_line_id uuid;
  v_to_lot_id uuid;
  v_doc_no text;
  v_doc_type_text text;
  v_movement_at timestamptz;
  v_src_site_id uuid;
  v_dest_site_id uuid;
  v_batch_id uuid;
  v_from_lot_id uuid;
  v_uom_id uuid;
  v_notes text;
  v_meta jsonb;
  v_lines jsonb;
  v_idempotency_key text;
  v_zero_material_id uuid := '00000000-0000-0000-0000-000000000000'::uuid;

  v_source_lot_qty numeric;
  v_source_lot_uom uuid;
  v_source_lot_site uuid;
  v_source_inv_qty numeric;
  v_total_qty numeric := 0;
  v_remaining_qty numeric;

  v_line jsonb;
  v_line_qty numeric;
  v_line_no int;
  v_line_counter int := 0;
  v_line_package_id uuid;
  v_line_lot_no text;
  v_line_expires_at timestamptz;
  v_line_notes text;
  v_line_meta jsonb;
  v_root_lot_no text;
  v_next_lot_seq int;
begin
  if p_doc is null then
    raise exception 'PF001: p_doc is required';
  end if;

  v_tenant := public._assert_tenant();

  v_doc_no := nullif(btrim(coalesce(p_doc ->> 'doc_no', '')), '');
  v_movement_at := coalesce(nullif(p_doc ->> 'movement_at', '')::timestamptz, now());
  v_src_site_id := nullif(p_doc ->> 'src_site_id', '')::uuid;
  v_dest_site_id := nullif(p_doc ->> 'dest_site_id', '')::uuid;
  v_batch_id := nullif(p_doc ->> 'batch_id', '')::uuid;
  v_from_lot_id := nullif(p_doc ->> 'from_lot_id', '')::uuid;
  v_uom_id := nullif(p_doc ->> 'uom_id', '')::uuid;
  v_notes := nullif(p_doc ->> 'notes', '');
  v_meta := coalesce(p_doc -> 'meta', '{}'::jsonb);
  v_lines := p_doc -> 'lines';
  v_idempotency_key := nullif(btrim(coalesce(v_meta ->> 'idempotency_key', '')), '');

  if v_doc_no is null
     or v_src_site_id is null
     or v_dest_site_id is null
     or v_batch_id is null
     or v_from_lot_id is null
     or v_uom_id is null then
    raise exception 'PF001: missing required field';
  end if;

  if jsonb_typeof(v_lines) <> 'array' or jsonb_array_length(v_lines) = 0 then
    raise exception 'PF001: lines[] is required';
  end if;

  if v_src_site_id = v_dest_site_id then
    raise exception 'PF006: src_site_id and dest_site_id must be not same for filling';
  end if;

  -- Map PACKAGE_FILL to enum value available in this DB.
  if exists (
    select 1
    from pg_enum e
    where e.enumtypid = 'public.inv_doc_type'::regtype
      and e.enumlabel = 'PACKAGE_FILL'
  ) then
    v_doc_type_text := 'PACKAGE_FILL';
  elsif exists (
    select 1
    from pg_enum e
    where e.enumtypid = 'public.inv_doc_type'::regtype
      and e.enumlabel = 'production_receipt'
  ) then
    v_doc_type_text := 'production_receipt';
  else
    raise exception 'PF006: inv_doc_type does not support PACKAGE_FILL mapping';
  end if;

  -- Optional idempotency support
  if v_idempotency_key is not null then
    select m.id
      into v_movement_id
    from public.inv_movements m
    where m.tenant_id = v_tenant
      and m.meta ->> 'idempotency_key' = v_idempotency_key
      and m.doc_type = v_doc_type_text::public.inv_doc_type
    order by m.created_at desc
    limit 1;

    if v_movement_id is not null then
      return v_movement_id;
    end if;
  end if;

  -- Validate lines and aggregate required quantity
  for v_line in
    select value
    from jsonb_array_elements(v_lines)
  loop
    v_line_qty := coalesce((v_line ->> 'qty')::numeric, 0);
    if v_line_qty <= 0 then
      raise exception 'PF002: line qty must be greater than 0';
    end if;
    v_total_qty := v_total_qty + v_line_qty;
  end loop;

  -- Lock and validate source lot
  select l.qty, l.uom_id, l.site_id
    into v_source_lot_qty, v_source_lot_uom, v_source_lot_site
  from public.lot l
  where l.tenant_id = v_tenant
    and l.id = v_from_lot_id
  for update;

  if not found then
    raise exception 'PF007: source lot not found';
  end if;

  if v_source_lot_uom is distinct from v_uom_id then
    raise exception 'PF001: source lot uom_id mismatch';
  end if;

  if v_source_lot_site is not null and v_source_lot_site <> v_src_site_id then
    raise exception 'PF006: source lot site mismatch';
  end if;

  if v_source_lot_qty < v_total_qty then
    raise exception 'PF005: source lot insufficient quantity';
  end if;

  -- Lock and validate source inventory
  select i.qty
    into v_source_inv_qty
  from public.inv_inventory i
  where i.tenant_id = v_tenant
    and i.site_id = v_src_site_id
    and i.lot_id = v_from_lot_id
    and i.uom_id = v_uom_id
  for update;

  if not found or coalesce(v_source_inv_qty, 0) < v_total_qty then
    raise exception 'PF005: source inventory insufficient quantity';
  end if;

  with recursive upstream as (
    select l.id, l.lot_no, 0 as depth
    from public.lot l
    where l.tenant_id = v_tenant
      and l.id = v_from_lot_id
    union all
    select parent.id, parent.lot_no, u.depth + 1
    from upstream u
    join public.lot_edge e
      on e.tenant_id = v_tenant
     and e.to_lot_id = u.id
     and e.from_lot_id is not null
    join public.lot parent
      on parent.tenant_id = v_tenant
     and parent.id = e.from_lot_id
  )
  select u.lot_no
    into v_root_lot_no
  from upstream u
  order by u.depth desc
  limit 1;

  if v_root_lot_no is null then
    select l.lot_no
      into v_root_lot_no
    from public.lot l
    where l.tenant_id = v_tenant
      and l.id = v_from_lot_id;
  end if;

  if v_root_lot_no is null then
    raise exception 'PF007: source lot not found';
  end if;

  perform pg_advisory_xact_lock(hashtext(v_tenant::text), hashtext(v_root_lot_no));

  select coalesce(max(sub.seq), 0) + 1
    into v_next_lot_seq
  from (
    select case
             when l.lot_no like v_root_lot_no || '\_%' escape '\'
                  and substring(l.lot_no from char_length(v_root_lot_no) + 2) ~ '^[0-9]+$'
               then substring(l.lot_no from char_length(v_root_lot_no) + 2)::int
             else null
           end as seq
    from public.lot l
    where l.tenant_id = v_tenant
  ) sub;

  insert into public.inv_movements (
    tenant_id, doc_no, doc_type, status, movement_at,
    src_site_id, dest_site_id, reason, meta, notes
  ) values (
    v_tenant,
    v_doc_no,
    v_doc_type_text::public.inv_doc_type,
    'posted',
    v_movement_at,
    v_src_site_id,
    v_dest_site_id,
    nullif(p_doc ->> 'reason', ''),
    v_meta || jsonb_build_object('movement_intent', 'PACKAGE_FILL'),
    v_notes
  )
  returning id into v_movement_id;

  for v_line in
    select value
    from jsonb_array_elements(v_lines)
  loop
    v_line_counter := v_line_counter + 1;
    v_line_no := coalesce((v_line ->> 'line_no')::int, v_line_counter);
    v_line_qty := coalesce((v_line ->> 'qty')::numeric, 0);
    v_line_package_id := nullif(v_line ->> 'package_id', '')::uuid;
    v_line_lot_no := nullif(btrim(coalesce(v_line ->> 'lot_no', '')), '');
    v_line_expires_at := nullif(v_line ->> 'expires_at', '')::timestamptz;
    v_line_notes := coalesce(nullif(v_line ->> 'notes', ''), v_notes);
    v_line_meta := coalesce(v_line -> 'meta', '{}'::jsonb);

    if v_line_lot_no is null then
      v_line_lot_no := format('%s_%s', v_root_lot_no, lpad(v_next_lot_seq::text, 3, '0'));
      v_next_lot_seq := v_next_lot_seq + 1;
    end if;

    insert into public.lot (
      tenant_id, lot_no, material_id, package_id, batch_id, site_id,
      produced_at, expires_at, qty, uom_id, status, meta, notes
    ) values (
      v_tenant,
      v_line_lot_no,
      v_zero_material_id,
      v_line_package_id,
      v_batch_id,
      v_dest_site_id,
      v_movement_at,
      v_line_expires_at,
      v_line_qty,
      v_uom_id,
      'active',
      v_meta || v_line_meta || jsonb_build_object(
        'source_movement_id', v_movement_id,
        'from_lot_id', v_from_lot_id
      ),
      v_line_notes
    )
    returning id into v_to_lot_id;

    insert into public.inv_movement_lines (
      tenant_id, movement_id, line_no,
      material_id, package_id, batch_id, qty, uom_id, notes, meta
    ) values (
      v_tenant,
      v_movement_id,
      v_line_no,
      v_zero_material_id,
      v_line_package_id,
      v_batch_id,
      v_line_qty,
      v_uom_id,
      v_line_notes,
      v_line_meta
    )
    returning id into v_movement_line_id;

    insert into public.lot_edge (
      tenant_id, movement_id, movement_line_id, edge_type,
      from_lot_id, to_lot_id, qty, uom_id, notes, meta
    ) values (
      v_tenant,
      v_movement_id,
      v_movement_line_id,
      'SPLIT'::public.lot_edge_type,
      v_from_lot_id,
      v_to_lot_id,
      v_line_qty,
      v_uom_id,
      v_line_notes,
      v_meta || v_line_meta
    );

    update public.inv_inventory i
       set qty = i.qty + v_line_qty
     where i.tenant_id = v_tenant
       and i.site_id = v_dest_site_id
       and i.lot_id = v_to_lot_id
       and i.uom_id = v_uom_id;

    if not found then
      insert into public.inv_inventory (
        tenant_id, site_id, lot_id, qty, uom_id
      ) values (
        v_tenant, v_dest_site_id, v_to_lot_id, v_line_qty, v_uom_id
      );
    end if;
  end loop;

  update public.inv_inventory i
     set qty = i.qty - v_total_qty
   where i.tenant_id = v_tenant
     and i.site_id = v_src_site_id
     and i.lot_id = v_from_lot_id
     and i.uom_id = v_uom_id;

  update public.lot l
     set qty = l.qty - v_total_qty,
         status = case when l.qty - v_total_qty <= 0 then 'consumed' else l.status end,
         updated_at = now()
   where l.tenant_id = v_tenant
     and l.id = v_from_lot_id
  returning qty into v_remaining_qty;

  if v_remaining_qty < 0 then
    raise exception 'PF005: source lot insufficient quantity after update';
  end if;

  return v_movement_id;

exception
  when unique_violation then
    if strpos(sqlerrm, 'inv_movements_tenant_id_doc_no_key') > 0 then
      raise exception 'PF003: duplicate doc_no';
    elsif strpos(sqlerrm, 'lot_tenant_id_lot_no_key') > 0 then
      raise exception 'PF004: duplicate destination lot_no';
    else
      raise;
    end if;
end;
$$;
