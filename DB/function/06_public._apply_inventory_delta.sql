create or replace function public._apply_inventory_delta(
  p_lines jsonb,
  p_direction text
)
returns void
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_sign int;
  v_line jsonb;
  v_site_id uuid;
  v_material_id uuid;
  v_uom_id uuid;
  v_batch_code text;
  v_qty numeric;
begin
  if p_lines is null or jsonb_typeof(p_lines) <> 'array' then
    raise exception 'p_lines must be a json array';
  end if;

  if p_direction not in ('apply', 'reverse') then
    raise exception 'p_direction must be apply or reverse';
  end if;

  v_sign := case when p_direction = 'apply' then 1 else -1 end;
  v_tenant := public._assert_tenant();

  for v_line in select value from jsonb_array_elements(p_lines)
  loop
    v_site_id := (v_line ->> 'site_id')::uuid;
    v_material_id := nullif(v_line ->> 'material_id', '')::uuid;
    v_uom_id := (v_line ->> 'uom_id')::uuid;
    v_batch_code := nullif(v_line ->> 'batch_code', '');
    v_qty := coalesce((v_line ->> 'qty')::numeric, 0);

    if v_site_id is null or v_uom_id is null or v_qty <= 0 then
      raise exception 'Invalid inventory line payload: %', v_line::text;
    end if;

    if v_material_id is null then
      continue;
    end if;

    insert into public.inv_inventory (
      tenant_id, material_id, site_id, qty, uom_id, batch_code
    ) values (
      v_tenant, v_material_id, v_site_id, v_sign * v_qty, v_uom_id, v_batch_code
    )
    on conflict do nothing;

    update public.inv_inventory i
       set qty = i.qty + (v_sign * v_qty)
     where i.tenant_id = v_tenant
       and i.site_id = v_site_id
       and i.material_id = v_material_id
       and i.uom_id = v_uom_id
       and coalesce(i.batch_code, '') = coalesce(v_batch_code, '');
  end loop;
end;
$$;
