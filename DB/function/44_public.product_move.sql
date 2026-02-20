create or replace function public.product_move(p_doc jsonb)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_movement_id uuid;
  v_movement_line_id uuid;
  v_to_lot_id uuid;
  v_dest_inv_id uuid;
  v_source_inv_id uuid;
  v_remaining_qty numeric;

  v_doc_no text;
  v_doc_type_text text;
  v_movement_at timestamptz;
  v_src_site_id uuid;
  v_dst_site_id uuid;
  v_src_lot_id uuid;
  v_qty numeric;
  v_unit numeric;
  v_uom_id uuid;
  v_movement_intent text;
  v_tax_decision_code text;
  v_reason text;
  v_notes text;
  v_meta jsonb;
  v_idempotency_key text;

  v_src_site_type text;
  v_dst_site_type text;

  v_rules jsonb;
  v_intent_rule jsonb;
  v_transform_rule jsonb;
  v_decision_rule jsonb;
  v_line_rules jsonb;

  v_edge_type text;
  v_tax_event text;
  v_effective_lot_tax_type text;
  v_result_lot_tax_type text;
  v_allow_partial_quantity boolean;
  v_require_full_lot boolean;

  v_source_lot_qty numeric;
  v_source_lot_unit numeric;
  v_source_lot_uom uuid;
  v_source_lot_site uuid;
  v_source_lot_tax_type text;
  v_source_lot_status text;
  v_source_lot_no text;
  v_source_material_id uuid;
  v_source_package_id uuid;
  v_source_batch_id uuid;
  v_source_meta jsonb;
  v_source_produced_at timestamptz;
  v_source_expires_at timestamptz;
  v_source_inv_qty numeric;
  v_remaining_unit numeric;

  v_dest_lot_no text;
  v_lot_no_base text;
  v_next_lot_seq int;
  v_zero_material_id uuid := '00000000-0000-0000-0000-000000000000'::uuid;
begin
  if p_doc is null then
    raise exception 'PM001: p_doc is required';
  end if;

  v_tenant := public._assert_tenant();

  v_doc_no := nullif(btrim(coalesce(p_doc ->> 'doc_no', '')), '');
  v_movement_at := coalesce(nullif(p_doc ->> 'movement_at', '')::timestamptz, now());
  v_movement_intent := nullif(btrim(coalesce(p_doc ->> 'movement_intent', '')), '');
  v_src_site_id := nullif(p_doc ->> 'src_site', '')::uuid;
  v_dst_site_id := nullif(p_doc ->> 'dst_site', '')::uuid;
  v_src_lot_id := nullif(p_doc ->> 'src_lot_id', '')::uuid;
  v_qty := coalesce((p_doc ->> 'qty')::numeric, 0);
  v_unit := nullif(btrim(coalesce(p_doc ->> 'unit', '')), '')::numeric;
  v_uom_id := nullif(p_doc ->> 'uom_id', '')::uuid;
  v_tax_decision_code := nullif(btrim(coalesce(p_doc ->> 'tax_decision_code', '')), '');
  v_reason := nullif(p_doc ->> 'reason', '');
  v_notes := nullif(p_doc ->> 'notes', '');
  v_meta := coalesce(p_doc -> 'meta', '{}'::jsonb);
  v_idempotency_key := nullif(btrim(coalesce(v_meta ->> 'idempotency_key', '')), '');

  if v_movement_intent is null
     or v_src_site_id is null
     or v_dst_site_id is null
     or v_src_lot_id is null
     or v_uom_id is null
     or v_tax_decision_code is null then
    raise exception 'PM001: missing required input';
  end if;

  if v_qty <= 0 then
    raise exception 'PM002: qty must be greater than 0';
  end if;

  if v_unit is not null and v_unit <= 0 then
    raise exception 'PM002: unit must be greater than 0';
  end if;

  select r.spec
    into v_rules
  from public.registry_def r
  where r.kind = 'ruleengine'
    and r.def_key = 'beer_movement_rule'
    and r.is_active = true
    and (
      (r.scope = 'tenant' and r.owner_id = v_tenant)
      or r.scope = 'system'
    )
  order by
    case when r.scope = 'tenant' and r.owner_id = v_tenant then 0 else 1 end,
    r.updated_at desc
  limit 1;

  if v_rules is null then
    raise exception 'PM003: rule definition not found (ruleengine/beer_movement_rule)';
  end if;

  if not exists (
    select 1
    from jsonb_array_elements_text(coalesce(v_rules -> 'enums' -> 'movement_intent', '[]'::jsonb)) e(v)
    where e.v = v_movement_intent
  ) then
    raise exception 'PM004: invalid movement_intent: %', v_movement_intent;
  end if;

  if not exists (
    select 1
    from jsonb_array_elements_text(coalesce(v_rules -> 'enums' -> 'tax_decision_code', '[]'::jsonb)) e(v)
    where e.v = v_tax_decision_code
  ) then
    raise exception 'PM005: invalid tax_decision_code: %', v_tax_decision_code;
  end if;

  select
    case lower(coalesce(rd.def_key, ''))
      when 'brewery' then 'BREWERY_MANUFACTUR'
      when 'brewery_manufactur' then 'BREWERY_MANUFACTUR'
      when 'brewery_storage' then 'BREWERY_STORAGE'
      when 'tax_storage' then 'TAX_STORAGE'
      when 'bonded_area' then 'TAX_STORAGE'
      when 'domestic_customer' then 'DOMESTIC_CUSTOMER'
      when 'oversea_customer' then 'OVERSEA_CUSTOMER'
      when 'other_brewery' then 'OTHER_BREWERY'
      when 'disposal_facility' then 'DISPOSAL_FACILITY'
      when 'direct_sales_shop' then 'DIRECT_SALES_SHOP'
      else upper(replace(coalesce(rd.def_key, ''), '-', '_'))
    end
    into v_src_site_type
  from public.mst_sites s
  left join public.registry_def rd
    on rd.def_id = s.site_type_id
   and rd.kind = 'site_type'
   and rd.is_active = true
  where s.tenant_id = v_tenant
    and s.id = v_src_site_id;

  if v_src_site_type is null then
    raise exception 'PM001: src_site not found or site_type is invalid';
  end if;

  select
    case lower(coalesce(rd.def_key, ''))
      when 'brewery' then 'BREWERY_MANUFACTUR'
      when 'brewery_manufactur' then 'BREWERY_MANUFACTUR'
      when 'brewery_storage' then 'BREWERY_STORAGE'
      when 'tax_storage' then 'TAX_STORAGE'
      when 'bonded_area' then 'TAX_STORAGE'
      when 'domestic_customer' then 'DOMESTIC_CUSTOMER'
      when 'oversea_customer' then 'OVERSEA_CUSTOMER'
      when 'other_brewery' then 'OTHER_BREWERY'
      when 'disposal_facility' then 'DISPOSAL_FACILITY'
      when 'direct_sales_shop' then 'DIRECT_SALES_SHOP'
      else upper(replace(coalesce(rd.def_key, ''), '-', '_'))
    end
    into v_dst_site_type
  from public.mst_sites s
  left join public.registry_def rd
    on rd.def_id = s.site_type_id
   and rd.kind = 'site_type'
   and rd.is_active = true
  where s.tenant_id = v_tenant
    and s.id = v_dst_site_id;

  if v_dst_site_type is null then
    raise exception 'PM001: dst_site not found or site_type is invalid';
  end if;

  select i.item
    into v_intent_rule
  from jsonb_array_elements(coalesce(v_rules -> 'movement_intent_rules', '[]'::jsonb)) i(item)
  where i.item ->> 'movement_intent' = v_movement_intent
    and exists (
      select 1
      from jsonb_array_elements_text(coalesce(i.item -> 'allowed_src_site_types', '[]'::jsonb)) s(v)
      where s.v = v_src_site_type
    )
    and exists (
      select 1
      from jsonb_array_elements_text(coalesce(i.item -> 'allowed_dst_site_types', '[]'::jsonb)) d(v)
      where d.v = v_dst_site_type
    )
  limit 1;

  if v_intent_rule is null then
    raise exception 'PM004: movement_intent/site_type combination is not allowed';
  end if;

  v_edge_type := coalesce(v_intent_rule ->> 'edge_type', 'MOVE');
  if v_edge_type not in ('MOVE', 'CONSUME', 'SPLIT', 'MERGE') then
    raise exception 'PM004: unsupported edge_type for product_move: %', v_edge_type;
  end if;

  select
    l.qty,
    l.unit,
    l.uom_id,
    l.site_id,
    l.lot_tax_type,
    l.status,
    l.lot_no,
    l.material_id,
    l.package_id,
    l.batch_id,
    l.meta,
    l.produced_at,
    l.expires_at
    into
      v_source_lot_qty,
      v_source_lot_unit,
      v_source_lot_uom,
      v_source_lot_site,
      v_source_lot_tax_type,
      v_source_lot_status,
      v_source_lot_no,
      v_source_material_id,
      v_source_package_id,
      v_source_batch_id,
      v_source_meta,
      v_source_produced_at,
      v_source_expires_at
  from public.lot l
  where l.tenant_id = v_tenant
    and l.id = v_src_lot_id
  for update;

  if not found then
    raise exception 'PM006: source lot not found';
  end if;

  if v_source_lot_status <> 'active' then
    raise exception 'PM006: source lot is not movable. status=%', v_source_lot_status;
  end if;

  if v_source_lot_site is not null and v_source_lot_site <> v_src_site_id then
    raise exception 'PM006: source lot site mismatch';
  end if;

  if v_source_lot_uom is distinct from v_uom_id then
    raise exception 'PM006: uom_id mismatch with source lot';
  end if;

  if v_source_lot_qty < v_qty then
    raise exception 'PM007: source lot insufficient quantity';
  end if;

  if v_unit is not null and coalesce(v_source_lot_unit, 0) < v_unit then
    raise exception 'PM007: source lot insufficient unit';
  end if;

  v_effective_lot_tax_type := coalesce(v_source_lot_tax_type, 'OUT_OF_SCOPE');

  select t.item
    into v_transform_rule
  from jsonb_array_elements(coalesce(v_rules -> 'tax_transformation_rules', '[]'::jsonb)) t(item)
  where t.item ->> 'movement_intent' = v_movement_intent
    and t.item ->> 'src_site_type' = v_src_site_type
    and t.item ->> 'dst_site_type' = v_dst_site_type
    and t.item ->> 'lot_tax_type' = v_effective_lot_tax_type
  limit 1;

  if v_transform_rule is null then
    raise exception 'PM005: no transformation rule for movement context';
  end if;

  select d.item
    into v_decision_rule
  from jsonb_array_elements(coalesce(v_transform_rule -> 'allowed_tax_decisions', '[]'::jsonb)) d(item)
  where d.item ->> 'tax_decision_code' = v_tax_decision_code
  limit 1;

  if v_decision_rule is null then
    raise exception 'PM005: tax_decision_code is not allowed for movement context';
  end if;

  v_tax_event := coalesce(nullif(v_decision_rule ->> 'tax_event', ''), 'NONE');
  v_result_lot_tax_type := nullif(v_decision_rule ->> 'result_lot_tax_type', '');
  v_line_rules := coalesce(v_decision_rule -> 'lines_rules', '{}'::jsonb);
  v_allow_partial_quantity := coalesce((v_line_rules ->> 'allow_partial_quantity')::boolean, true);
  v_require_full_lot := coalesce((v_line_rules ->> 'require_full_lot')::boolean, false);

  if v_require_full_lot and v_qty <> v_source_lot_qty then
    raise exception 'PM008: full-lot movement required by rule';
  end if;

  if not v_allow_partial_quantity and v_qty < v_source_lot_qty then
    raise exception 'PM008: partial quantity is not allowed by rule';
  end if;

  select i.id, i.qty
    into v_source_inv_id, v_source_inv_qty
  from public.inv_inventory i
  where i.tenant_id = v_tenant
    and i.site_id = v_src_site_id
    and i.lot_id = v_src_lot_id
    and i.uom_id = v_uom_id
  order by i.created_at, i.id
  limit 1
  for update;

  if not found or coalesce(v_source_inv_qty, 0) < v_qty then
    raise exception 'PM007: source inventory insufficient quantity';
  end if;

  v_doc_type_text := case v_movement_intent
    when 'INTERNAL_TRANSFER' then 'transfer'
    when 'SHIP_DOMESTIC' then 'sale'
    when 'SHIP_EXPORT' then 'sale'
    when 'RETURN_FROM_CUSTOMER' then 'return'
    when 'LOSS' then 'adjustment'
    when 'DISPOSE' then 'waste'
    when 'PACKAGE_FILL' then 'production_receipt'
    when 'BREW_PRODUCE' then 'production_receipt'
    else 'transfer'
  end;

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

  if v_doc_no is null then
    v_doc_no := format(
      'PM-%s-%s',
      to_char(v_movement_at, 'YYYYMMDDHH24MISSMS'),
      substr(replace(gen_random_uuid()::text, '-', ''), 1, 6)
    );
  end if;

  v_lot_no_base := coalesce(v_source_lot_no, 'LOT');
  perform pg_advisory_xact_lock(hashtext(v_tenant::text), hashtext(v_lot_no_base));

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
    v_dst_site_id,
    v_reason,
    v_meta || jsonb_build_object(
      'movement_intent', v_movement_intent,
      'tax_decision_code', v_tax_decision_code,
      'tax_event', v_tax_event
    ),
    v_notes
  )
  returning id into v_movement_id;

  insert into public.inv_movement_lines (
    tenant_id, movement_id, line_no,
    material_id, package_id, batch_id, qty, unit, uom_id, notes, meta
  ) values (
    v_tenant,
    v_movement_id,
    1,
    coalesce(v_source_material_id, v_zero_material_id),
    v_source_package_id,
    v_source_batch_id,
    v_qty,
    v_unit,
    v_uom_id,
    v_notes,
    jsonb_build_object(
      'src_lot_id', v_src_lot_id,
      'movement_intent', v_movement_intent,
      'tax_decision_code', v_tax_decision_code,
      'tax_event', v_tax_event,
      'rule_version', v_rules ->> 'version',
      'src_site_type', v_src_site_type,
      'dst_site_type', v_dst_site_type,
      'src_lot_tax_type', v_effective_lot_tax_type
    )
  )
  returning id into v_movement_line_id;

  if v_edge_type <> 'CONSUME' then
    -- Reuse previously mapped destination lot for this source lot/site when possible.
    select l.id
      into v_to_lot_id
    from public.lot l
    where l.tenant_id = v_tenant
      and l.site_id = v_dst_site_id
      and l.status = 'active'
      and l.uom_id = v_uom_id
      and l.meta ->> 'from_lot_id' = v_src_lot_id::text
    order by l.created_at desc, l.id desc
    limit 1
    for update;

    if v_to_lot_id is null then
      -- Prefer source lot_no. Fall back to suffixed lot_no only when uniqueness requires it.
      v_dest_lot_no := v_lot_no_base;
      if exists (
        select 1
        from public.lot l
        where l.tenant_id = v_tenant
          and l.lot_no = v_dest_lot_no
      ) then
        select coalesce(max(sub.seq), 0) + 1
          into v_next_lot_seq
        from (
          select case
                   when l.lot_no like v_lot_no_base || '\_%' escape '\'
                        and substring(l.lot_no from char_length(v_lot_no_base) + 2) ~ '^[0-9]+$'
                     then substring(l.lot_no from char_length(v_lot_no_base) + 2)::int
                   else null
                 end as seq
          from public.lot l
          where l.tenant_id = v_tenant
        ) sub;

        v_dest_lot_no := format('%s_%s', v_lot_no_base, lpad(v_next_lot_seq::text, 3, '0'));
      end if;

      insert into public.lot (
        tenant_id, lot_no, material_id, package_id, batch_id, lot_tax_type, site_id,
        produced_at, expires_at, qty, unit, uom_id, status, meta, notes
      ) values (
        v_tenant,
        v_dest_lot_no,
        coalesce(v_source_material_id, v_zero_material_id),
        v_source_package_id,
        v_source_batch_id,
        coalesce(v_result_lot_tax_type, v_effective_lot_tax_type),
        v_dst_site_id,
        v_source_produced_at,
        v_source_expires_at,
        v_qty,
        v_unit,
        v_uom_id,
        'active',
        coalesce(v_source_meta, '{}'::jsonb) || jsonb_build_object(
          'source_movement_id', v_movement_id,
          'from_lot_id', v_src_lot_id,
          'movement_intent', v_movement_intent,
          'tax_decision_code', v_tax_decision_code,
          'tax_event', v_tax_event
        ),
        v_notes
      )
      returning id into v_to_lot_id;
    else
      update public.lot l
         set qty = l.qty + v_qty,
             unit = case
               when v_unit is not null then coalesce(l.unit, 0) + v_unit
               else l.unit
             end,
             lot_tax_type = coalesce(v_result_lot_tax_type, l.lot_tax_type),
             updated_at = now(),
             meta = coalesce(l.meta, '{}'::jsonb) || jsonb_build_object(
               'source_movement_id', v_movement_id,
               'movement_intent', v_movement_intent,
               'tax_decision_code', v_tax_decision_code,
               'tax_event', v_tax_event
             )
       where l.id = v_to_lot_id;
    end if;
  end if;

  insert into public.lot_edge (
    tenant_id, movement_id, movement_line_id, edge_type,
    from_lot_id, to_lot_id, qty, uom_id, notes, meta
  ) values (
    v_tenant,
    v_movement_id,
    v_movement_line_id,
    v_edge_type::public.lot_edge_type,
    v_src_lot_id,
    case when v_edge_type = 'CONSUME' then null else v_to_lot_id end,
    v_qty,
    v_uom_id,
    v_notes,
    jsonb_build_object(
      'movement_intent', v_movement_intent,
      'tax_decision_code', v_tax_decision_code,
      'tax_event', v_tax_event
    )
  );

  update public.inv_inventory i
     set qty = i.qty - v_qty
   where i.id = v_source_inv_id;

  if v_edge_type <> 'CONSUME' then
    select i.id
      into v_dest_inv_id
    from public.inv_inventory i
    where i.tenant_id = v_tenant
      and i.site_id = v_dst_site_id
      and i.lot_id = v_to_lot_id
      and i.uom_id = v_uom_id
    order by i.created_at, i.id
    limit 1
    for update;

    if v_dest_inv_id is null then
      insert into public.inv_inventory (
        tenant_id, site_id, lot_id, qty, uom_id
      ) values (
        v_tenant, v_dst_site_id, v_to_lot_id, v_qty, v_uom_id
      );
    else
      update public.inv_inventory i
         set qty = i.qty + v_qty
       where i.id = v_dest_inv_id;
    end if;
  end if;

  update public.lot l
     set qty = l.qty - v_qty,
         unit = case
           when v_unit is not null then coalesce(l.unit, 0) - v_unit
           else l.unit
         end,
         status = case when l.qty - v_qty <= 0 then 'consumed' else l.status end,
         updated_at = now()
   where l.tenant_id = v_tenant
     and l.id = v_src_lot_id
  returning qty, unit into v_remaining_qty, v_remaining_unit;

  if v_remaining_qty < 0 then
    raise exception 'PM007: source lot insufficient quantity after update';
  end if;

  if v_unit is not null and coalesce(v_remaining_unit, 0) < 0 then
    raise exception 'PM007: source lot insufficient unit after update';
  end if;

  perform public._assert_non_negative_lot_qty(v_src_lot_id);

  return v_movement_id;

exception
  when unique_violation then
    if strpos(sqlerrm, 'inv_movements_tenant_id_doc_no_key') > 0 then
      raise exception 'PM001: duplicate doc_no';
    elsif strpos(sqlerrm, 'lot_tenant_id_lot_no_key') > 0 then
      raise exception 'PM009: destination lot creation/validation failed (duplicate lot_no)';
    else
      raise;
    end if;
end;
$$;
