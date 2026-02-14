create or replace function public.batch_create(p_doc jsonb)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_batch_id uuid;
begin
  if p_doc is null then
    raise exception 'p_doc is required';
  end if;

  v_tenant := public._assert_tenant();

  insert into public.mes_batches (
    tenant_id, batch_code, batch_label, recipe_id, process_version, scale_factor,
    recipe_json, planned_start, planned_end, actual_start, actual_end, notes, meta,
    status, product_name, actual_yield, actual_yield_uom
  ) values (
    v_tenant,
    p_doc ->> 'batch_code',
    p_doc ->> 'batch_label',
    nullif(p_doc ->> 'recipe_id', '')::uuid,
    nullif(p_doc ->> 'process_version', '')::int,
    nullif(p_doc ->> 'scale_factor', '')::numeric,
    coalesce(p_doc -> 'recipe_json', 'null'::jsonb),
    nullif(p_doc ->> 'planned_start', '')::timestamptz,
    nullif(p_doc ->> 'planned_end', '')::timestamptz,
    nullif(p_doc ->> 'actual_start', '')::timestamptz,
    nullif(p_doc ->> 'actual_end', '')::timestamptz,
    p_doc ->> 'notes',
    coalesce(p_doc -> 'meta', '{}'::jsonb),
    coalesce((p_doc ->> 'status')::mes_batch_status, 'planned'::mes_batch_status),
    p_doc ->> 'product_name',
    nullif(p_doc ->> 'actual_yield', '')::numeric,
    nullif(p_doc ->> 'actual_yield_uom', '')::uuid
  ) returning id into v_batch_id;

  return v_batch_id;
end;
$$;
