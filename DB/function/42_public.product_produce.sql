create or replace function public.product_produce(p_doc jsonb)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_movement_id uuid;
  v_movement_line_id uuid;
  v_lot_id uuid;
  v_doc_no text;
  v_doc_type_text text;
  v_movement_at timestamptz;
  v_src_site_id uuid;
  v_dest_site_id uuid;
  v_material_id uuid;
  v_batch_id uuid;
  v_qty numeric;
  v_uom_id uuid;
  v_lot_no text;
  v_produced_at timestamptz;
  v_expires_at timestamptz;
  v_notes text;
  v_meta jsonb;
  v_line_meta jsonb;
  v_idempotency_key text;
begin
  if p_doc is null then
    raise exception 'PP001: p_doc is required';
  end if;

  v_tenant := public._assert_tenant();

  v_doc_no := nullif(btrim(coalesce(p_doc ->> 'doc_no', '')), '');
  v_movement_at := coalesce(nullif(p_doc ->> 'movement_at', '')::timestamptz, now());
  v_src_site_id := nullif(p_doc ->> 'src_site_id', '')::uuid;
  v_dest_site_id := nullif(p_doc ->> 'dest_site_id', '')::uuid;
  v_material_id := '00000000-0000-0000-0000-000000000000'::uuid;
  v_batch_id := nullif(p_doc ->> 'batch_id', '')::uuid;
  v_qty := coalesce((p_doc ->> 'qty')::numeric, 0);
  v_uom_id := nullif(p_doc ->> 'uom_id', '')::uuid;
  v_lot_no := nullif(btrim(coalesce(p_doc ->> 'lot_no', '')), '');
  v_produced_at := coalesce(nullif(p_doc ->> 'produced_at', '')::timestamptz, v_movement_at);
  v_expires_at := nullif(p_doc ->> 'expires_at', '')::timestamptz;
  v_notes := nullif(p_doc ->> 'notes', '');
  v_meta := coalesce(p_doc -> 'meta', '{}'::jsonb);
  v_line_meta := coalesce(p_doc -> 'line_meta', '{}'::jsonb);
  v_idempotency_key := nullif(btrim(coalesce(v_meta ->> 'idempotency_key', '')), '');

  if v_doc_no is null
     or v_dest_site_id is null
     or v_batch_id is null
     or v_uom_id is null then
    raise exception 'PP001: missing required field';
  end if;

  if v_qty <= 0 then
    raise exception 'PP002: qty must be greater than 0';
  end if;

  if v_src_site_id is not null and v_src_site_id <> v_dest_site_id then
    raise exception 'PP005: src_site_id must be NULL or equal to dest_site_id';
  end if;

  -- Map BREW_PRODUCE to enum value available in this DB.
  if exists (
    select 1
    from pg_enum e
    where e.enumtypid = 'public.inv_doc_type'::regtype
      and e.enumlabel = 'BREW_PRODUCE'
  ) then
    v_doc_type_text := 'BREW_PRODUCE';
  elsif exists (
    select 1
    from pg_enum e
    where e.enumtypid = 'public.inv_doc_type'::regtype
      and e.enumlabel = 'production_receipt'
  ) then
    v_doc_type_text := 'production_receipt';
  else
    raise exception 'PP006: inv_doc_type does not support BREW_PRODUCE mapping';
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

  if v_lot_no is null then
    v_lot_no := format(
      'LOT-%s-%s',
      to_char(v_movement_at, 'YYYYMMDDHH24MISSMS'),
      substr(replace(gen_random_uuid()::text, '-', ''), 1, 8)
    );
  end if;

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
    v_meta || jsonb_build_object('movement_intent', 'BREW_PRODUCE'),
    v_notes
  )
  returning id into v_movement_id;

  insert into public.inv_movement_lines (
    tenant_id, movement_id, line_no,
    material_id, batch_id, qty, uom_id, notes, meta
  ) values (
    v_tenant,
    v_movement_id,
    1,
    v_material_id,
    v_batch_id,
    v_qty,
    v_uom_id,
    v_notes,
    v_line_meta
  )
  returning id into v_movement_line_id;

  insert into public.lot (
    tenant_id, lot_no, material_id, batch_id, site_id,
    produced_at, expires_at, qty, uom_id, status, meta, notes
  ) values (
    v_tenant,
    v_lot_no,
    v_material_id,
    v_batch_id,
    v_dest_site_id,
    v_produced_at,
    v_expires_at,
    v_qty,
    v_uom_id,
    'active',
    v_meta || jsonb_build_object('source_movement_id', v_movement_id),
    v_notes
  )
  returning id into v_lot_id;

  insert into public.lot_edge (
    tenant_id, movement_id, movement_line_id, edge_type,
    from_lot_id, to_lot_id, qty, uom_id, notes, meta
  ) values (
    v_tenant,
    v_movement_id,
    v_movement_line_id,
    'PRODUCE'::public.lot_edge_type,
    null,
    v_lot_id,
    v_qty,
    v_uom_id,
    v_notes,
    v_meta
  );

  update public.inv_inventory i
     set qty = i.qty + v_qty
   where i.tenant_id = v_tenant
     and i.site_id = v_dest_site_id
     and i.lot_id = v_lot_id
     and i.uom_id = v_uom_id;

  if not found then
    insert into public.inv_inventory (
      tenant_id, site_id, lot_id, qty, uom_id
    ) values (
      v_tenant, v_dest_site_id, v_lot_id, v_qty, v_uom_id
    );
  end if;

  return v_movement_id;

exception
  when unique_violation then
    if strpos(sqlerrm, 'inv_movements_tenant_id_doc_no_key') > 0 then
      raise exception 'PP003: duplicate doc_no';
    elsif strpos(sqlerrm, 'lot_tenant_id_lot_no_key') > 0 then
      raise exception 'PP004: duplicate lot_no';
    else
      raise;
    end if;
end;
$$;
