create or replace function public.inventory_retrieve(p_filter jsonb)
returns table (
  inventory_id uuid,
  material_id uuid,
  site_id uuid,
  qty numeric,
  uom_id uuid,
  batch_code text,
  created_at timestamptz
)
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_limit int;
  v_offset int;
begin
  v_tenant := public._assert_tenant();
  v_limit := greatest(1, least(coalesce((p_filter ->> 'limit')::int, 200), 1000));
  v_offset := greatest(0, coalesce((p_filter ->> 'offset')::int, 0));

  return query
  select i.id, i.material_id, i.site_id, i.qty, i.uom_id, i.batch_code, i.created_at
  from public.inv_inventory i
  where i.tenant_id = v_tenant
    and ((p_filter ->> 'site_id') is null or i.site_id = (p_filter ->> 'site_id')::uuid)
    and ((p_filter ->> 'material_id') is null or i.material_id = (p_filter ->> 'material_id')::uuid)
    and ((p_filter ->> 'batch_code') is null or i.batch_code = (p_filter ->> 'batch_code'))
  order by i.created_at desc
  limit v_limit offset v_offset;
end;
$$;
