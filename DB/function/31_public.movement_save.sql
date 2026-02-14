create or replace function public.movement_save(
  p_movement_id uuid,
  p_doc jsonb
)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
begin
  if p_movement_id is null then
    raise exception 'p_movement_id is required';
  end if;

  v_tenant := public._assert_tenant();

  update public.inv_movements m
     set doc_no = coalesce(p_doc ->> 'doc_no', m.doc_no),
         doc_type = coalesce((p_doc ->> 'doc_type')::inv_doc_type, m.doc_type),
         status = coalesce(p_doc ->> 'status', m.status),
         movement_at = coalesce(nullif(p_doc ->> 'movement_at', '')::timestamptz, m.movement_at),
         src_site_id = coalesce(nullif(p_doc ->> 'src_site_id', '')::uuid, m.src_site_id),
         dest_site_id = coalesce(nullif(p_doc ->> 'dest_site_id', '')::uuid, m.dest_site_id),
         external_ref = coalesce(p_doc ->> 'external_ref', m.external_ref),
         reason = coalesce(p_doc ->> 'reason', m.reason),
         meta = coalesce(p_doc -> 'meta', m.meta),
         notes = coalesce(p_doc ->> 'notes', m.notes)
   where m.id = p_movement_id
     and m.tenant_id = v_tenant;

  if not found then
    raise exception 'Movement not found: %', p_movement_id;
  end if;

  if jsonb_typeof(p_doc -> 'lines') = 'array' then
    perform public._upsert_movement_lines(p_movement_id, p_doc -> 'lines');
  end if;

  return p_movement_id;
end;
$$;
