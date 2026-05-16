create or replace function public.tax_batch_correction_preview(p_doc jsonb)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_comparison_report_id uuid;
  v_batch_id uuid;
  v_new_beer_category_id text;
  v_new_actual_abv numeric;
  v_new_target_abv numeric;
begin
  if p_doc is null then
    raise exception 'TBC001: p_doc is required';
  end if;

  v_tenant := public._assert_tenant();
  v_comparison_report_id := nullif(coalesce(p_doc ->> 'comparison_report_id', p_doc ->> 'comparisonReportId'), '')::uuid;
  v_batch_id := nullif(coalesce(p_doc ->> 'batch_id', p_doc ->> 'batchId'), '')::uuid;
  v_new_beer_category_id := nullif(btrim(coalesce(p_doc ->> 'new_beer_category_id', p_doc ->> 'newBeerCategoryId', '')), '');
  v_new_actual_abv := nullif(coalesce(p_doc ->> 'new_actual_abv', p_doc ->> 'newActualAbv'), '')::numeric;
  v_new_target_abv := nullif(coalesce(p_doc ->> 'new_target_abv', p_doc ->> 'newTargetAbv'), '')::numeric;

  return public._tax_batch_correction_preview_payload(
    v_tenant,
    v_comparison_report_id,
    v_batch_id,
    v_new_beer_category_id,
    v_new_actual_abv,
    v_new_target_abv
  );
end;
$$;
comment on function public.tax_batch_correction_preview(jsonb) is '{"version":1}';
