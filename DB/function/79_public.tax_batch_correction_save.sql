create or replace function public.tax_batch_correction_save(p_doc jsonb)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_correction_id uuid;
  v_comparison_report_id uuid;
  v_batch_id uuid;
  v_new_beer_category_id text;
  v_new_actual_abv numeric;
  v_new_target_abv numeric;
  v_reason text;
  v_existing public.tax_batch_corrections%rowtype;
  v_preview jsonb;
  v_correction public.tax_batch_corrections%rowtype;
begin
  if p_doc is null then
    raise exception 'TBC001: p_doc is required';
  end if;

  v_tenant := public._assert_tenant();
  v_correction_id := nullif(coalesce(p_doc ->> 'id', p_doc ->> 'correction_id', p_doc ->> 'correctionId'), '')::uuid;
  v_comparison_report_id := nullif(coalesce(p_doc ->> 'comparison_report_id', p_doc ->> 'comparisonReportId'), '')::uuid;
  v_batch_id := nullif(coalesce(p_doc ->> 'batch_id', p_doc ->> 'batchId'), '')::uuid;
  v_new_beer_category_id := nullif(btrim(coalesce(p_doc ->> 'new_beer_category_id', p_doc ->> 'newBeerCategoryId', '')), '');
  v_new_actual_abv := nullif(coalesce(p_doc ->> 'new_actual_abv', p_doc ->> 'newActualAbv'), '')::numeric;
  v_new_target_abv := nullif(coalesce(p_doc ->> 'new_target_abv', p_doc ->> 'newTargetAbv'), '')::numeric;
  v_reason := nullif(btrim(coalesce(p_doc ->> 'reason', '')), '');

  if v_reason is null then
    raise exception 'TBC001: reason is required';
  end if;

  if v_correction_id is not null then
    select *
      into v_existing
    from public.tax_batch_corrections c
    where c.tenant_id = v_tenant
      and c.id = v_correction_id
    for update;

    if v_existing.id is null then
      raise exception 'TBC002: correction not found';
    end if;

    if v_existing.status <> 'draft' then
      raise exception 'TBC007: only draft corrections can be changed';
    end if;

    v_comparison_report_id := coalesce(v_comparison_report_id, v_existing.comparison_report_id);
    v_batch_id := coalesce(v_batch_id, v_existing.batch_id);
    v_new_beer_category_id := coalesce(v_new_beer_category_id, v_existing.new_beer_category_id);
    v_new_actual_abv := coalesce(v_new_actual_abv, v_existing.new_actual_abv);
    v_new_target_abv := coalesce(v_new_target_abv, v_existing.new_target_abv);
  end if;

  v_preview := public._tax_batch_correction_preview_payload(
    v_tenant,
    v_comparison_report_id,
    v_batch_id,
    v_new_beer_category_id,
    v_new_actual_abv,
    v_new_target_abv
  );

  if coalesce((v_preview ->> 'old_category_count')::int, 0) > 1
     or coalesce((v_preview ->> 'old_actual_abv_count')::int, 0) > 1
     or coalesce((v_preview ->> 'old_target_abv_count')::int, 0) > 1 then
    raise exception 'TBC006: selected batch has mixed category or ABV snapshots in the comparison report'
      using detail = jsonb_build_object(
        'old_category_count', v_preview ->> 'old_category_count',
        'old_actual_abv_count', v_preview ->> 'old_actual_abv_count',
        'old_target_abv_count', v_preview ->> 'old_target_abv_count'
      )::text;
  end if;

  if coalesce(v_new_beer_category_id, v_preview ->> 'old_beer_category_id') is not distinct from (v_preview ->> 'old_beer_category_id')
     and coalesce(v_new_actual_abv, nullif(v_preview ->> 'old_actual_abv', '')::numeric) is not distinct from nullif(v_preview ->> 'old_actual_abv', '')::numeric
     and coalesce(v_new_target_abv, nullif(v_preview ->> 'old_target_abv', '')::numeric) is not distinct from nullif(v_preview ->> 'old_target_abv', '')::numeric then
    raise exception 'TBC004: correction has no category or ABV difference';
  end if;

  if v_correction_id is null then
    insert into public.tax_batch_corrections (
      tenant_id,
      comparison_report_id,
      batch_id,
      old_beer_category_id,
      new_beer_category_id,
      old_actual_abv,
      new_actual_abv,
      old_target_abv,
      new_target_abv,
      reason,
      status,
      created_by,
      updated_by
    ) values (
      v_tenant,
      v_comparison_report_id,
      v_batch_id,
      v_preview ->> 'old_beer_category_id',
      v_new_beer_category_id,
      nullif(v_preview ->> 'old_actual_abv', '')::numeric,
      v_new_actual_abv,
      nullif(v_preview ->> 'old_target_abv', '')::numeric,
      v_new_target_abv,
      v_reason,
      'draft',
      auth.uid(),
      auth.uid()
    )
    returning * into v_correction;
  else
    update public.tax_batch_corrections c
       set comparison_report_id = v_comparison_report_id,
           batch_id = v_batch_id,
           old_beer_category_id = v_preview ->> 'old_beer_category_id',
           new_beer_category_id = v_new_beer_category_id,
           old_actual_abv = nullif(v_preview ->> 'old_actual_abv', '')::numeric,
           new_actual_abv = v_new_actual_abv,
           old_target_abv = nullif(v_preview ->> 'old_target_abv', '')::numeric,
           new_target_abv = v_new_target_abv,
           reason = v_reason,
           updated_by = auth.uid(),
           updated_at = now()
     where c.tenant_id = v_tenant
       and c.id = v_correction_id
    returning * into v_correction;
  end if;

  return jsonb_build_object(
    'correction', to_jsonb(v_correction),
    'preview', v_preview
  );
exception
  when unique_violation then
    raise exception 'TBC008: an active correction already exists for this report and batch';
end;
$$;
comment on function public.tax_batch_correction_save(jsonb) is '{"version":1}';
