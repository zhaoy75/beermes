create or replace function public.domestic_removal_complete(
  p_lot_id uuid,
  p_site_id uuid default null,
  p_reason text default null
)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_rules jsonb;
  v_movement_id uuid;
  v_dummy_site_id uuid;
  v_lot_site_id uuid;
  v_source_site_id uuid;
  v_source_site_type text;
  v_source_lot_qty numeric;
  v_source_lot_unit numeric;
  v_source_lot_uom_id uuid;
  v_source_lot_tax_type text;
  v_source_lot_status text;
  v_source_inventory_qty numeric;
  v_tax_decision_code text;
  v_reason text;
begin
  if p_lot_id is null then
    raise exception 'DRC001: p_lot_id is required';
  end if;

  v_tenant := public._assert_tenant();
  v_reason := coalesce(
    nullif(btrim(p_reason), ''),
    'domestic_removal_complete'
  );

  select
    l.site_id,
    l.qty,
    l.unit,
    l.uom_id,
    coalesce(l.lot_tax_type, 'OUT_OF_SCOPE'),
    l.status
    into
      v_source_site_id,
      v_source_lot_qty,
      v_source_lot_unit,
      v_source_lot_uom_id,
      v_source_lot_tax_type,
      v_source_lot_status
  from public.lot l
  where l.tenant_id = v_tenant
    and l.id = p_lot_id
  for update;

  if not found then
    raise exception 'DRC002: source lot not found';
  end if;

  v_lot_site_id := v_source_site_id;
  v_source_site_id := coalesce(p_site_id, v_lot_site_id);

  if v_source_site_id is null then
    raise exception 'DRC003: source site could not be resolved';
  end if;

  if p_site_id is not null and v_lot_site_id is not null and p_site_id <> v_lot_site_id then
    raise exception 'DRC003: source lot site mismatch';
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
    into v_source_site_type
  from public.mst_sites s
  left join public.registry_def rd
    on rd.def_id = s.site_type_id
   and rd.kind = 'site_type'
   and rd.is_active = true
  where s.tenant_id = v_tenant
    and s.id = v_source_site_id;

  if v_source_site_type is null then
    raise exception 'DRC004: source site not found or site_type is invalid';
  end if;

  if v_source_site_type <> 'TAX_STORAGE' then
    raise exception 'DRC005: domestic_removal_complete is only allowed for TAX_STORAGE';
  end if;

  if v_source_lot_status <> 'active' then
    raise exception 'DRC006: source lot is not movable. status=%', v_source_lot_status;
  end if;

  select i.qty
    into v_source_inventory_qty
  from public.inv_inventory i
  where i.tenant_id = v_tenant
    and i.site_id = v_source_site_id
    and i.lot_id = p_lot_id
    and i.uom_id = v_source_lot_uom_id
  order by i.created_at, i.id
  limit 1
  for update;

  if coalesce(v_source_inventory_qty, 0) <= 0 then
    raise exception 'DRC007: source inventory row not found or quantity is not positive';
  end if;

  select public.movement_get_rules('SHIP_DOMESTIC')
    into v_rules;

  select coalesce(
           (
             select d.item ->> 'tax_decision_code'
             from jsonb_array_elements(coalesce(t.item -> 'allowed_tax_decisions', '[]'::jsonb)) d(item)
             where coalesce((d.item ->> 'default')::boolean, false)
             order by d.item ->> 'tax_decision_code'
             limit 1
           ),
           (
             select d.item ->> 'tax_decision_code'
             from jsonb_array_elements(coalesce(t.item -> 'allowed_tax_decisions', '[]'::jsonb)) d(item)
             order by d.item ->> 'tax_decision_code'
             limit 1
           )
         )
    into v_tax_decision_code
  from jsonb_array_elements(coalesce(v_rules -> 'tax_transformation_rules', '[]'::jsonb)) t(item)
  where t.item ->> 'movement_intent' = 'SHIP_DOMESTIC'
    and t.item ->> 'src_site_type' = 'TAX_STORAGE'
    and t.item ->> 'dst_site_type' = 'DOMESTIC_CUSTOMER'
    and t.item ->> 'lot_tax_type' = v_source_lot_tax_type
  limit 1;

  if v_tax_decision_code is null then
    raise exception 'DRC008: default tax decision is not defined for SHIP_DOMESTIC/TAX_STORAGE/DOMESTIC_CUSTOMER/%', v_source_lot_tax_type;
  end if;

  v_dummy_site_id := public.ensure_dummy_domestic_customer_site();

  select public.product_move(
    jsonb_strip_nulls(
      jsonb_build_object(
        'movement_intent', 'SHIP_DOMESTIC',
        'src_site', v_source_site_id,
        'dst_site', v_dummy_site_id,
        'src_lot_id', p_lot_id,
        'qty', v_source_inventory_qty,
        'unit', case
          when coalesce(v_source_lot_unit, 0) > 0 and v_source_lot_qty = v_source_inventory_qty
            then v_source_lot_unit
          else null
        end,
        'uom_id', v_source_lot_uom_id,
        'tax_decision_code', v_tax_decision_code,
        'reason', v_reason,
        'notes', v_reason,
        'meta', jsonb_build_object(
          'source', 'produced_beer_inventory_domestic_removal_complete',
          'source_site_id', v_source_site_id,
          'dummy_destination_site_id', v_dummy_site_id
        )
      )
    )
  )
    into v_movement_id;

  return v_movement_id;
end;
$$;
comment on function public.domestic_removal_complete(uuid, uuid, text) is '{"version":1}';
