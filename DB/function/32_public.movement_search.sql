create or replace function public.movement_search(p_filter jsonb)
returns table (
  id uuid,
  doc_no text,
  doc_type inv_doc_type,
  status text,
  movement_at timestamptz,
  src_site_id uuid,
  dest_site_id uuid,
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
  v_limit := greatest(1, least(coalesce((p_filter ->> 'limit')::int, 100), 500));
  v_offset := greatest(0, coalesce((p_filter ->> 'offset')::int, 0));

  return query
  select m.id, m.doc_no, m.doc_type, m.status, m.movement_at,
         m.src_site_id, m.dest_site_id, m.created_at
  from public.inv_movements m
  where m.tenant_id = v_tenant
    and ((p_filter ->> 'doc_type') is null or m.doc_type::text = (p_filter ->> 'doc_type'))
    and ((p_filter ->> 'status') is null or m.status = (p_filter ->> 'status'))
    and ((p_filter ->> 'doc_no') is null or m.doc_no ilike ('%' || (p_filter ->> 'doc_no') || '%'))
    and ((p_filter ->> 'src_site_id') is null or m.src_site_id = (p_filter ->> 'src_site_id')::uuid)
    and ((p_filter ->> 'dest_site_id') is null or m.dest_site_id = (p_filter ->> 'dest_site_id')::uuid)
    and ((p_filter ->> 'from') is null or m.movement_at >= (p_filter ->> 'from')::timestamptz)
    and ((p_filter ->> 'to') is null or m.movement_at <= (p_filter ->> 'to')::timestamptz)
  order by m.movement_at desc, m.created_at desc
  limit v_limit offset v_offset;
end;
$$;
