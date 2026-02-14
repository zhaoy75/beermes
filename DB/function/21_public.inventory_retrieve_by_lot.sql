create or replace function public.inventory_retrieve_by_lot(p_filter jsonb)
returns table (
  lot_id uuid,
  lot_no text,
  material_id uuid,
  package_id uuid,
  batch_id uuid,
  site_id uuid,
  qty numeric,
  uom_id uuid,
  status text,
  produced_at timestamptz,
  expires_at timestamptz
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
  select l.id, l.lot_no, l.material_id, l.package_id, l.batch_id, l.site_id,
         l.qty, l.uom_id, l.status, l.produced_at, l.expires_at
  from public.lot l
  where l.tenant_id = v_tenant
    and ((p_filter ->> 'site_id') is null or l.site_id = (p_filter ->> 'site_id')::uuid)
    and ((p_filter ->> 'batch_id') is null or l.batch_id = (p_filter ->> 'batch_id')::uuid)
    and ((p_filter ->> 'material_id') is null or l.material_id = (p_filter ->> 'material_id')::uuid)
    and ((p_filter ->> 'status') is null or l.status = (p_filter ->> 'status'))
    and ((p_filter ->> 'expires_before') is null or l.expires_at <= (p_filter ->> 'expires_before')::timestamptz)
  order by l.created_at desc
  limit v_limit offset v_offset;
end;
$$;
