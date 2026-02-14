create or replace function public.batch_save(
  p_batch_id uuid,
  p_patch jsonb
)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
begin
  if p_batch_id is null then
    raise exception 'p_batch_id is required';
  end if;
  if p_patch is null then
    raise exception 'p_patch is required';
  end if;

  v_tenant := public._assert_tenant();

  update public.mes_batches b
     set batch_label = coalesce(p_patch ->> 'batch_label', b.batch_label),
         process_version = coalesce(nullif(p_patch ->> 'process_version','')::int, b.process_version),
         scale_factor = coalesce(nullif(p_patch ->> 'scale_factor','')::numeric, b.scale_factor),
         planned_start = coalesce(nullif(p_patch ->> 'planned_start','')::timestamptz, b.planned_start),
         planned_end = coalesce(nullif(p_patch ->> 'planned_end','')::timestamptz, b.planned_end),
         actual_start = coalesce(nullif(p_patch ->> 'actual_start','')::timestamptz, b.actual_start),
         actual_end = coalesce(nullif(p_patch ->> 'actual_end','')::timestamptz, b.actual_end),
         notes = coalesce(p_patch ->> 'notes', b.notes),
         meta = coalesce(p_patch -> 'meta', b.meta),
         status = coalesce((p_patch ->> 'status')::mes_batch_status, b.status),
         product_name = coalesce(p_patch ->> 'product_name', b.product_name),
         actual_yield = coalesce(nullif(p_patch ->> 'actual_yield','')::numeric, b.actual_yield),
         actual_yield_uom = coalesce(nullif(p_patch ->> 'actual_yield_uom','')::uuid, b.actual_yield_uom)
   where b.id = p_batch_id
     and b.tenant_id = v_tenant;

  if not found then
    raise exception 'Batch not found: %', p_batch_id;
  end if;

  return p_batch_id;
end;
$$;
