create or replace function public.batch_get_detail(p_batch_id uuid)
returns jsonb
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_result jsonb;
begin
  if p_batch_id is null then
    raise exception 'p_batch_id is required';
  end if;

  v_tenant := public._assert_tenant();

  select jsonb_build_object(
    'batch', to_jsonb(b),
    'steps', '[]'::jsonb,
    'relations', coalesce((
      select jsonb_agg(to_jsonb(r))
      from public.mes_batch_relation r
      where r.tenant_id = v_tenant
        and (r.src_batch_id = b.id or r.dst_batch_id = b.id)
    ), '[]'::jsonb)
  ) into v_result
  from public.mes_batches b
  where b.tenant_id = v_tenant
    and b.id = p_batch_id;

  if v_result is null then
    raise exception 'Batch not found: %', p_batch_id;
  end if;

  return v_result;
end;
$$;
