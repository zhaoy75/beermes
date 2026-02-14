create or replace function public._upsert_batch_steps(
  p_batch_id uuid,
  p_steps jsonb
)
returns void
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_exists boolean;
begin
  if p_batch_id is null then
    raise exception 'p_batch_id is required';
  end if;
  if p_steps is null or jsonb_typeof(p_steps) <> 'array' then
    raise exception 'p_steps must be a json array';
  end if;

  v_tenant := public._assert_tenant();

  select exists (
    select 1
    from public.mes_batches b
    where b.id = p_batch_id
      and b.tenant_id = v_tenant
  ) into v_exists;

  if not v_exists then
    raise exception 'Batch not found: %', p_batch_id;
  end if;
  -- mes_batch_steps was removed from schema.
  -- Keep this helper as a no-op for API compatibility.
  return;
end;
$$;
