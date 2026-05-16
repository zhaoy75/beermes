create or replace function public.tax_batch_correction_approve(p_correction_id uuid)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_correction public.tax_batch_corrections%rowtype;
begin
  if p_correction_id is null then
    raise exception 'TBC001: p_correction_id is required';
  end if;

  v_tenant := public._assert_tenant();

  select *
    into v_correction
  from public.tax_batch_corrections c
  where c.tenant_id = v_tenant
    and c.id = p_correction_id
  for update;

  if v_correction.id is null then
    raise exception 'TBC002: correction not found';
  end if;

  if v_correction.status <> 'draft' then
    raise exception 'TBC009: only draft corrections can be approved';
  end if;

  update public.tax_batch_corrections c
     set status = 'approved',
         approved_by = auth.uid(),
         approved_at = now(),
         updated_by = auth.uid(),
         updated_at = now()
   where c.tenant_id = v_tenant
     and c.id = p_correction_id
  returning * into v_correction;

  return to_jsonb(v_correction);
end;
$$;
comment on function public.tax_batch_correction_approve(uuid) is '{"version":1}';
