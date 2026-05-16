create or replace function public.tax_report_set_status(
  p_tax_report_id uuid,
  p_status text,
  p_reason text default null
)
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_current public.tax_reports%rowtype;
  v_target_status text;
  v_ref_count int;
  v_breakdown_count int;
begin
  if p_tax_report_id is null then
    raise exception 'TRS001: p_tax_report_id is required';
  end if;

  v_target_status := nullif(btrim(coalesce(p_status, '')), '');
  if v_target_status not in ('draft', 'stale', 'submitted', 'approved') then
    raise exception 'TRS002: invalid tax report status';
  end if;

  v_tenant := public._assert_tenant();

  select *
    into v_current
  from public.tax_reports r
  where r.tenant_id = v_tenant
    and r.id = p_tax_report_id
  for update;

  if not found then
    raise exception 'TRS003: tax report not found';
  end if;

  if v_current.status = 'approved' and v_target_status <> 'approved' then
    raise exception 'TRS004: approved tax report status cannot be changed';
  end if;

  if v_current.status = 'submitted' and v_target_status not in ('submitted', 'approved') then
    raise exception 'TRS004: submitted tax report cannot return to draft';
  end if;

  if v_target_status = 'submitted' then
    if v_current.status = 'stale' then
      raise exception 'TRS005: stale tax report must be regenerated before submission';
    end if;

    select count(*)
      into v_ref_count
    from public.tax_report_movement_refs r
    where r.tenant_id = v_tenant
      and r.tax_report_id = p_tax_report_id;

    v_breakdown_count := jsonb_array_length(coalesce(v_current.volume_breakdown, '[]'::jsonb));
    if v_breakdown_count > 0 and v_ref_count = 0 then
      raise exception 'TRS005: tax report has no source movement references';
    end if;

    if v_current.prior_cumulative_tax_amount_source = 'manual_override' then
      if v_current.prior_cumulative_tax_amount_override is null
         or v_current.prior_cumulative_tax_amount_override < 0 then
        raise exception 'TRS008: prior cumulative tax amount override is invalid';
      end if;

      if v_current.prior_cumulative_tax_amount_override is distinct from coalesce(v_current.prior_cumulative_tax_amount_calculated, 0)
         and nullif(btrim(coalesce(v_current.prior_cumulative_tax_amount_notes, '')), '') is null then
        raise exception 'TRS008: prior cumulative tax amount override notes are required';
      end if;
    end if;

    if v_current.declaration_type = 'amended' then
      if v_current.previous_report_id is null
         or v_current.amendment_no is null
         or nullif(btrim(coalesce(v_current.declaration_reason, '')), '') is null
         or jsonb_array_length(coalesce(v_current.comparison_breakdown, '[]'::jsonb)) = 0
         or v_current.correction_delta_tax_amount is null then
        raise exception 'TRS007: amended tax report is missing comparison metadata';
      end if;

      if v_current.correction_delta_tax_amount < 0 then
        raise exception 'TRS007: amended tax report reduces tax and may require a correction claim workflow';
      end if;
    end if;
  end if;

  if v_target_status = 'approved' and v_current.status <> 'submitted' then
    raise exception 'TRS006: only submitted tax reports can be approved';
  end if;

  update public.tax_reports r
     set status = v_target_status,
         updated_at = now()
   where r.tenant_id = v_tenant
     and r.id = p_tax_report_id;

  if v_target_status in ('submitted', 'approved')
     and v_current.declaration_type = 'amended'
     and v_current.previous_report_id is not null then
    update public.tax_batch_corrections c
       set status = 'used',
           used_report_id = p_tax_report_id,
           used_at = coalesce(c.used_at, now()),
           updated_by = auth.uid(),
           updated_at = now()
     where c.tenant_id = v_tenant
       and c.comparison_report_id = v_current.previous_report_id
       and c.status = 'approved';
  end if;

  return p_tax_report_id;
end;
$$;
comment on function public.tax_report_set_status(uuid, text, text) is '{"version":4}';
