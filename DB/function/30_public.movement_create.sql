create or replace function public.movement_create(p_doc jsonb)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_movement_id uuid;
  v_line jsonb;
  v_src_site uuid;
  v_dst_site uuid;
begin
  if p_doc is null then
    raise exception 'p_doc is required';
  end if;

  v_tenant := public._assert_tenant();
  v_src_site := nullif(p_doc ->> 'src_site_id', '')::uuid;
  v_dst_site := nullif(p_doc ->> 'dest_site_id', '')::uuid;

  insert into public.inv_movements (
    tenant_id, doc_no, doc_type, status, movement_at,
    src_site_id, dest_site_id, external_ref, reason, meta, notes, created_by
  ) values (
    v_tenant,
    p_doc ->> 'doc_no',
    (p_doc ->> 'doc_type')::inv_doc_type,
    coalesce(p_doc ->> 'status', 'open'),
    coalesce(nullif(p_doc ->> 'movement_at', '')::timestamptz, now()),
    v_src_site,
    v_dst_site,
    p_doc ->> 'external_ref',
    p_doc ->> 'reason',
    coalesce(p_doc -> 'meta', '{}'::jsonb),
    p_doc ->> 'notes',
    nullif(p_doc ->> 'created_by', '')::uuid
  ) returning id into v_movement_id;

  if jsonb_typeof(p_doc -> 'lines') = 'array' then
    perform public._upsert_movement_lines(v_movement_id, p_doc -> 'lines');
  else
    raise exception 'lines[] is required';
  end if;

  return v_movement_id;
end;
$$;
