create or replace function public.tax_event_retrieve(p_filter jsonb)
returns table (
  lot_event_id uuid,
  event_no text,
  event_type lot_event_type,
  event_at timestamptz,
  status text,
  src_site_id uuid,
  dest_site_id uuid,
  tax_event text,
  reason text
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
  v_limit := greatest(1, least(coalesce((p_filter ->> 'limit')::int, 100), 500));
  v_offset := greatest(0, coalesce((p_filter ->> 'offset')::int, 0));

  return query
  select e.id, e.event_no, e.event_type, e.event_at, e.status,
         e.src_site_id, e.dest_site_id, e.meta ->> 'tax_event', e.reason
  from public.lot_event e
  where e.tenant_id = v_tenant
    and ((p_filter ->> 'event_type') is null or e.event_type::text = (p_filter ->> 'event_type'))
    and ((p_filter ->> 'status') is null or e.status = (p_filter ->> 'status'))
    and ((p_filter ->> 'src_site_id') is null or e.src_site_id = (p_filter ->> 'src_site_id')::uuid)
    and ((p_filter ->> 'dest_site_id') is null or e.dest_site_id = (p_filter ->> 'dest_site_id')::uuid)
    and ((p_filter ->> 'tax_event') is null or (e.meta ->> 'tax_event') = (p_filter ->> 'tax_event'))
    and ((p_filter ->> 'from') is null or e.event_at >= (p_filter ->> 'from')::timestamptz)
    and ((p_filter ->> 'to') is null or e.event_at <= (p_filter ->> 'to')::timestamptz)
  order by e.event_at desc, e.created_at desc
  limit v_limit offset v_offset;
end;
$$;
