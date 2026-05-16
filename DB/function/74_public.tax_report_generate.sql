create or replace function public.tax_report_generate(p_doc jsonb)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_report_id uuid;
  v_existing public.tax_reports%rowtype;
  v_report public.tax_reports%rowtype;
  v_tax_type text;
  v_tax_year int;
  v_tax_month int;
  v_requested_status text;
  v_start_date date;
  v_end_date date;
  v_fiscal_start_date date;
  v_volume_breakdown jsonb := '[]'::jsonb;
  v_total_tax_amount numeric := 0;
  v_report_files jsonb;
  v_attachment_files jsonb;
  v_requested_declaration_type text;
  v_declaration_type text;
  v_declaration_reason text;
  v_original_report_id uuid;
  v_previous_report_id uuid;
  v_previous_report public.tax_reports%rowtype;
  v_amendment_no int;
  v_previous_confirmed_payable_tax_amount numeric;
  v_previous_confirmed_refund_tax_amount numeric;
  v_correction_delta_tax_amount numeric;
  v_comparison_breakdown jsonb := '[]'::jsonb;
  v_comparison_changed_count int := 0;
  v_prior_cumulative_tax_amount_calculated numeric := 0;
  v_prior_cumulative_tax_amount_override numeric;
  v_prior_cumulative_tax_amount_source text;
  v_prior_cumulative_tax_amount_notes text;
  v_prior_cumulative_amount_changed boolean := false;
  v_prior_report record;
  v_breakdown_count int := 0;
  v_ref_count int := 0;
begin
  if p_doc is null then
    raise exception 'TRG001: p_doc is required';
  end if;

  v_tenant := public._assert_tenant();
  v_report_id := nullif(p_doc ->> 'report_id', '')::uuid;
  v_tax_type := coalesce(nullif(btrim(p_doc ->> 'tax_type'), ''), 'monthly');
  v_tax_year := nullif(p_doc ->> 'tax_year', '')::int;
  v_tax_month := nullif(p_doc ->> 'tax_month', '')::int;
  v_requested_status := coalesce(nullif(btrim(p_doc ->> 'status'), ''), 'draft');
  v_requested_declaration_type := nullif(btrim(coalesce(p_doc ->> 'declaration_type', p_doc ->> 'declarationType')), '');
  v_declaration_type := coalesce(v_requested_declaration_type, 'on_time');
  v_declaration_reason := nullif(btrim(coalesce(p_doc ->> 'declaration_reason', p_doc ->> 'declarationReason')), '');
  v_original_report_id := nullif(coalesce(p_doc ->> 'original_report_id', p_doc ->> 'originalReportId'), '')::uuid;
  v_previous_report_id := nullif(coalesce(p_doc ->> 'previous_report_id', p_doc ->> 'previousReportId'), '')::uuid;
  v_amendment_no := nullif(coalesce(p_doc ->> 'amendment_no', p_doc ->> 'amendmentNo'), '')::int;
  v_prior_cumulative_tax_amount_source := nullif(btrim(coalesce(p_doc ->> 'prior_cumulative_tax_amount_source', p_doc ->> 'priorCumulativeTaxAmountSource', '')), '');
  v_prior_cumulative_tax_amount_override := nullif(coalesce(p_doc ->> 'prior_cumulative_tax_amount_override', p_doc ->> 'priorCumulativeTaxAmountOverride'), '')::numeric;
  v_prior_cumulative_tax_amount_notes := nullif(btrim(coalesce(p_doc ->> 'prior_cumulative_tax_amount_notes', p_doc ->> 'priorCumulativeTaxAmountNotes', '')), '');

  if v_tax_type <> 'monthly' then
    raise exception 'TRG002: only monthly tax reports are supported';
  end if;

  if v_tax_year is null or v_tax_month is null or v_tax_month < 1 or v_tax_month > 12 then
    raise exception 'TRG002: tax_year and tax_month are required';
  end if;

  if v_requested_status not in ('draft', 'stale') then
    raise exception 'TRG003: tax_report_generate can only write draft or stale reports';
  end if;

  if v_declaration_type not in ('on_time', 'late', 'amended') then
    raise exception 'TRG002: invalid declaration_type';
  end if;

  if v_report_id is not null then
    select *
      into v_existing
    from public.tax_reports r
    where r.tenant_id = v_tenant
      and r.id = v_report_id
    for update;
  else
    if v_declaration_type = 'amended' then
      if v_amendment_no is not null then
        select *
          into v_existing
        from public.tax_reports r
        where r.tenant_id = v_tenant
          and r.tax_type = v_tax_type
          and r.tax_year = v_tax_year
          and r.tax_month = v_tax_month
          and r.declaration_type = 'amended'
          and r.amendment_no = v_amendment_no
        for update;
      end if;
    else
      select *
        into v_existing
      from public.tax_reports r
      where r.tenant_id = v_tenant
        and r.tax_type = v_tax_type
        and r.tax_year = v_tax_year
        and r.tax_month = v_tax_month
        and r.declaration_type in ('on_time', 'late')
      for update;
    end if;
  end if;

  if v_existing.id is not null and v_existing.status in ('submitted', 'approved') then
    raise exception 'TRG004: submitted or approved tax report cannot be regenerated';
  end if;

  v_declaration_type := coalesce(v_requested_declaration_type, v_existing.declaration_type, 'on_time');
  v_declaration_reason := coalesce(v_declaration_reason, v_existing.declaration_reason);
  v_original_report_id := coalesce(v_original_report_id, v_existing.original_report_id);
  v_previous_report_id := coalesce(v_previous_report_id, v_existing.previous_report_id);
  v_amendment_no := coalesce(v_amendment_no, v_existing.amendment_no);

  if v_declaration_type not in ('on_time', 'late', 'amended') then
    raise exception 'TRG002: invalid declaration_type';
  end if;

  if v_declaration_type in ('late', 'amended') and v_declaration_reason is null then
    raise exception 'TRG006: declaration_reason is required for late or amended reports';
  end if;

  if v_declaration_type = 'on_time' then
    v_declaration_reason := null;
  end if;

  v_report_id := coalesce(v_existing.id, v_report_id, gen_random_uuid());
  v_start_date := make_date(v_tax_year, v_tax_month, 1);
  v_end_date := (v_start_date + interval '1 month')::date;
  v_fiscal_start_date := case
    when v_tax_month >= 4 then make_date(v_tax_year, 4, 1)
    else make_date(v_tax_year - 1, 4, 1)
  end;

  v_prior_cumulative_tax_amount_calculated := 0;
  for v_prior_report in
    select distinct on (r.tax_year, r.tax_month)
      r.tax_year,
      r.tax_month,
      r.total_tax_amount,
      r.prior_cumulative_tax_amount_source,
      r.prior_cumulative_tax_amount_override
    from public.tax_reports r
    where r.tenant_id = v_tenant
      and r.tax_type = 'monthly'
      and r.status in ('submitted', 'approved')
      and r.id <> v_report_id
      and make_date(r.tax_year, r.tax_month, 1) >= v_fiscal_start_date
      and make_date(r.tax_year, r.tax_month, 1) < v_start_date
    order by
      r.tax_year,
      r.tax_month,
      case when r.declaration_type = 'amended' then 1 else 0 end desc,
      r.amendment_no desc nulls last,
      r.updated_at desc nulls last,
      r.created_at desc nulls last
  loop
    if v_prior_report.prior_cumulative_tax_amount_source = 'manual_override'
       and v_prior_report.prior_cumulative_tax_amount_override is not null then
      v_prior_cumulative_tax_amount_calculated := greatest(
        v_prior_report.prior_cumulative_tax_amount_override + coalesce(v_prior_report.total_tax_amount, 0),
        0
      );
    else
      v_prior_cumulative_tax_amount_calculated := greatest(
        v_prior_cumulative_tax_amount_calculated + coalesce(v_prior_report.total_tax_amount, 0),
        0
      );
    end if;
  end loop;

  v_prior_cumulative_tax_amount_source := coalesce(
    v_prior_cumulative_tax_amount_source,
    v_existing.prior_cumulative_tax_amount_source,
    'calculated'
  );

  if v_prior_cumulative_tax_amount_source not in ('calculated', 'manual_override') then
    raise exception 'TRG002: invalid prior cumulative tax amount source';
  end if;

  if v_prior_cumulative_tax_amount_source = 'manual_override' then
    v_prior_cumulative_tax_amount_override := coalesce(
      v_prior_cumulative_tax_amount_override,
      v_existing.prior_cumulative_tax_amount_override
    );
    if v_prior_cumulative_tax_amount_override is null then
      raise exception 'TRG002: prior cumulative tax amount override is required';
    end if;
    if v_prior_cumulative_tax_amount_override < 0 then
      raise exception 'TRG002: prior cumulative tax amount override must be non-negative';
    end if;
    v_prior_cumulative_tax_amount_notes := coalesce(
      v_prior_cumulative_tax_amount_notes,
      v_existing.prior_cumulative_tax_amount_notes
    );
  else
    v_prior_cumulative_tax_amount_override := null;
    v_prior_cumulative_tax_amount_notes := null;
  end if;

  v_prior_cumulative_amount_changed :=
    v_existing.id is not null
    and (
      coalesce(v_existing.prior_cumulative_tax_amount_source, 'calculated') is distinct from v_prior_cumulative_tax_amount_source
      or v_existing.prior_cumulative_tax_amount_override is distinct from v_prior_cumulative_tax_amount_override
      or coalesce(v_existing.prior_cumulative_tax_amount_notes, '') is distinct from coalesce(v_prior_cumulative_tax_amount_notes, '')
    );

  if v_declaration_type = 'amended' then
    if v_original_report_id is null and v_previous_report_id is null then
      raise exception 'TRG006: amended report requires an original or previous report';
    end if;

    if v_previous_report_id is not null then
      select *
        into v_previous_report
      from public.tax_reports r
      where r.tenant_id = v_tenant
        and r.id = v_previous_report_id;
    elsif v_original_report_id is not null then
      select *
        into v_previous_report
      from public.tax_reports r
      where r.tenant_id = v_tenant
        and r.tax_type = v_tax_type
        and r.tax_year = v_tax_year
        and r.tax_month = v_tax_month
        and r.declaration_type = 'amended'
        and r.status in ('submitted', 'approved')
        and r.id <> v_report_id
      order by r.amendment_no desc nulls last, r.created_at desc
      limit 1;

      if v_previous_report.id is null then
        select *
          into v_previous_report
        from public.tax_reports r
        where r.tenant_id = v_tenant
          and r.id = v_original_report_id;
      end if;
    end if;

    if v_previous_report.id is null then
      raise exception 'TRG006: amended comparison report was not found';
    end if;

    if v_previous_report.status not in ('submitted', 'approved') then
      raise exception 'TRG006: amended comparison report must be submitted or approved';
    end if;

    if v_previous_report.tax_type <> v_tax_type
       or v_previous_report.tax_year <> v_tax_year
       or v_previous_report.tax_month <> v_tax_month then
      raise exception 'TRG006: amended comparison report period does not match';
    end if;

    if v_previous_report.id = v_report_id then
      raise exception 'TRG006: amended comparison report cannot be itself';
    end if;

    v_previous_report_id := v_previous_report.id;
    v_original_report_id := coalesce(v_original_report_id, v_previous_report.original_report_id, v_previous_report.id);

    if v_amendment_no is null then
      select coalesce(max(r.amendment_no), 0) + 1
        into v_amendment_no
      from public.tax_reports r
      where r.tenant_id = v_tenant
        and r.tax_type = v_tax_type
        and r.tax_year = v_tax_year
        and r.tax_month = v_tax_month
        and r.declaration_type = 'amended'
        and r.id <> v_report_id;
    end if;
  else
    v_original_report_id := null;
    v_previous_report_id := null;
    v_amendment_no := null;
    v_previous_confirmed_payable_tax_amount := null;
    v_previous_confirmed_refund_tax_amount := null;
    v_correction_delta_tax_amount := null;
    v_comparison_breakdown := '[]'::jsonb;
  end if;
  v_report_files := case
    when jsonb_typeof(p_doc -> 'report_files') = 'array' then p_doc -> 'report_files'
    else coalesce(v_existing.report_files, '[]'::jsonb)
  end;
  v_attachment_files := case
    when jsonb_typeof(p_doc -> 'attachment_files') = 'array' then p_doc -> 'attachment_files'
    else coalesce(v_existing.attachment_files, '[]'::jsonb)
  end;

  with source_lines as (
    select
      m.id as movement_id,
      ml.id as movement_line_id,
      m.movement_at,
      m.doc_type::text as move_type,
      upper(coalesce(
        nullif(btrim(ml.meta ->> 'tax_attachment_form'), ''),
        nullif(btrim(m.meta ->> 'tax_attachment_form'), ''),
        nullif(btrim(ml.meta ->> 'tax_form'), ''),
        nullif(btrim(m.meta ->> 'tax_form'), '')
      )) as tax_attachment_form,
      case
        when nullif(btrim(ml.meta ->> 'reduced_tax_amount'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(ml.meta ->> 'reduced_tax_amount'), '')::numeric
        when nullif(btrim(m.meta ->> 'reduced_tax_amount'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(m.meta ->> 'reduced_tax_amount'), '')::numeric
        else null
      end as reduced_tax_amount,
      case
        when nullif(btrim(ml.meta ->> 'disaster_compensation_amount'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(ml.meta ->> 'disaster_compensation_amount'), '')::numeric
        when nullif(btrim(m.meta ->> 'disaster_compensation_amount'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(m.meta ->> 'disaster_compensation_amount'), '')::numeric
        else null
      end as disaster_compensation_amount,
      coalesce(nullif(btrim(ml.meta ->> 'remarks'), ''), nullif(btrim(m.meta ->> 'remarks'), ''), nullif(btrim(ml.meta ->> 'notes'), ''), nullif(btrim(m.meta ->> 'notes'), '')) as remarks,
      coalesce(nullif(btrim(ml.meta ->> 'removal_date'), ''), nullif(btrim(m.meta ->> 'removal_date'), '')) as removal_date,
      coalesce(nullif(btrim(ml.meta ->> 'receipt_date'), ''), nullif(btrim(m.meta ->> 'receipt_date'), '')) as receipt_date,
      case
        when nullif(btrim(ml.meta ->> 'removal_temperature'), '') ~ '^-?[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(ml.meta ->> 'removal_temperature'), '')::numeric
        when nullif(btrim(m.meta ->> 'removal_temperature'), '') ~ '^-?[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(m.meta ->> 'removal_temperature'), '')::numeric
        else null
      end as removal_temperature,
      case
        when nullif(btrim(ml.meta ->> 'receipt_temperature'), '') ~ '^-?[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(ml.meta ->> 'receipt_temperature'), '')::numeric
        when nullif(btrim(m.meta ->> 'receipt_temperature'), '') ~ '^-?[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(m.meta ->> 'receipt_temperature'), '')::numeric
        else null
      end as receipt_temperature,
      case
        when nullif(btrim(ml.meta ->> 'receipt_abv'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(ml.meta ->> 'receipt_abv'), '')::numeric
        when nullif(btrim(m.meta ->> 'receipt_abv'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(m.meta ->> 'receipt_abv'), '')::numeric
        else null
      end as receipt_abv,
      case
        when nullif(btrim(ml.meta ->> 'receipt_volume_ml'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(ml.meta ->> 'receipt_volume_ml'), '')::numeric
        when nullif(btrim(m.meta ->> 'receipt_volume_ml'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(m.meta ->> 'receipt_volume_ml'), '')::numeric
        else null
      end as receipt_volume_ml,
      case
        when nullif(btrim(ml.meta ->> 'volume_delta_ml'), '') ~ '^-?[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(ml.meta ->> 'volume_delta_ml'), '')::numeric
        when nullif(btrim(m.meta ->> 'volume_delta_ml'), '') ~ '^-?[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(m.meta ->> 'volume_delta_ml'), '')::numeric
        else null
      end as volume_delta_ml,
      coalesce(nullif(btrim(ml.meta ->> 'importer_address'), ''), nullif(btrim(m.meta ->> 'importer_address'), '')) as importer_address,
      coalesce(nullif(btrim(ml.meta ->> 'importer_name'), ''), nullif(btrim(m.meta ->> 'importer_name'), '')) as importer_name,
      coalesce(nullif(btrim(ml.meta ->> 'receipt_place_address'), ''), nullif(btrim(m.meta ->> 'receipt_place_address'), '')) as receipt_place_address,
      coalesce(nullif(btrim(ml.meta ->> 'receipt_place_name'), ''), nullif(btrim(m.meta ->> 'receipt_place_name'), '')) as receipt_place_name,
      coalesce(nullif(btrim(ml.meta ->> 'receipt_purpose'), ''), nullif(btrim(m.meta ->> 'receipt_purpose'), '')) as receipt_purpose,
      coalesce(
        nullif(btrim(m.meta ->> 'tax_event'), ''),
        nullif(btrim(m.meta ->> 'tax_decision_code'), ''),
        case m.doc_type::text
          when 'sale' then 'TAXABLE_REMOVAL'
          when 'tax_transfer' then 'EXPORT_EXEMPT'
          when 'return' then 'RETURN_TO_FACTORY'
          when 'transfer' then 'NON_TAXABLE_REMOVAL'
          when 'waste' then 'NON_TAXABLE_REMOVAL'
          else null
        end
      ) as tax_event,
      ml.package_id,
      ml.batch_id,
      ml.qty,
      ml.uom_id,
      nullif(case
        when ml.tax_rate > 0 then ml.tax_rate
        when nullif(btrim(ml.meta ->> 'tax_rate'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(ml.meta ->> 'tax_rate'), '')::numeric
        when nullif(btrim(m.meta ->> 'tax_rate'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(m.meta ->> 'tax_rate'), '')::numeric
        else null
      end, 0) as saved_tax_rate,
      lower(coalesce(u.code, 'l')) as uom_code,
      case lower(coalesce(u.code, 'l'))
        when 'ml' then round(ml.qty)
        when 'kl' then round(ml.qty * 1000000)
        when 'gal_us' then round(ml.qty * 3785.41)
        else round(ml.qty * 1000)
      end as volume_ml,
      coalesce(
        nullif(btrim(ml.meta ->> 'tax_category_code'), ''),
        nullif(btrim(ml.meta ->> 'beer_category'), ''),
        nullif(btrim(m.meta ->> 'tax_category_code'), ''),
        nullif(btrim(m.meta ->> 'beer_category'), ''),
        cat.raw_category_id
      ) as raw_category_id,
      coalesce(
        case
          when nullif(btrim(ml.meta ->> 'abv'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
            nullif(btrim(ml.meta ->> 'abv'), '')::numeric
          when nullif(btrim(ml.meta ->> 'actual_abv'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
            nullif(btrim(ml.meta ->> 'actual_abv'), '')::numeric
          when nullif(btrim(ml.meta ->> 'target_abv'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
            nullif(btrim(ml.meta ->> 'target_abv'), '')::numeric
          when nullif(btrim(m.meta ->> 'abv'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
            nullif(btrim(m.meta ->> 'abv'), '')::numeric
          else null
        end,
        abv.abv
      ) as abv
    from public.inv_movements m
    join public.inv_movement_lines ml
      on ml.tenant_id = m.tenant_id
     and ml.movement_id = m.id
    left join public.mst_uom u
      on u.id = ml.uom_id
    left join lateral (
      select coalesce(
        nullif(btrim(ea.value_json ->> 'def_id'), ''),
        nullif(btrim(ea.value_text), ''),
        ea.value_ref_type_id::text
      ) as raw_category_id
      from public.entity_attr ea
      join public.attr_def ad
        on ad.attr_id = ea.attr_id
      where ea.tenant_id = v_tenant
        and ea.entity_type = 'batch'
        and ea.entity_id = ml.batch_id
        and ad.domain = 'batch'
        and ad.code = 'beer_category'
        and ad.is_active = true
      order by ea.updated_at desc
      limit 1
    ) cat on true
    left join lateral (
      select ea.value_num as abv
      from public.entity_attr ea
      join public.attr_def ad
        on ad.attr_id = ea.attr_id
      where ea.tenant_id = v_tenant
        and ea.entity_type = 'batch'
        and ea.entity_id = ml.batch_id
        and ad.domain = 'batch'
        and ad.code in ('actual_abv', 'target_abv')
        and ad.is_active = true
      order by case when ad.code = 'actual_abv' then 0 else 1 end, ea.updated_at desc
      limit 1
    ) abv on true
    where m.tenant_id = v_tenant
      and m.status <> 'void'
      and m.doc_type::text in ('sale', 'tax_transfer', 'return', 'transfer', 'waste')
      and m.movement_at >= v_start_date
      and m.movement_at < v_end_date
      and (ml.package_id is not null or ml.batch_id is not null)
  ),
  enriched_lines as (
    select
      s.*,
      coalesce(alc.category_id, s.raw_category_id) as category_id,
      coalesce(alc.category_code, '') as category_code,
      coalesce(alc.category_name, s.raw_category_id, '—') as category_name,
      coalesce(s.saved_tax_rate, rate.tax_rate, 0) as tax_rate,
      case
        when s.move_type in ('sale', 'tax_transfer', 'return', 'transfer')
             and s.tax_event = 'TAXABLE_REMOVAL' then 1
        when s.move_type in ('sale', 'tax_transfer', 'return', 'transfer')
             and s.tax_event = 'RETURN_TO_FACTORY' then -1
        else 0
      end as tax_direction
    from source_lines s
    left join lateral (
      select c.category_id, c.category_code, c.category_name
      from (
        select
          0 as priority,
          v.def_id::text as category_id,
          nullif(btrim(v.key), '') as category_code,
          coalesce(nullif(btrim(v.label), ''), nullif(btrim(v.spec ->> 'name'), ''), v.def_key, v.key) as category_name,
          v.def_key,
          v.spec
        from public.v_alcohol_type_options v
        union all
        select
          1 as priority,
          r.def_id::text as category_id,
          nullif(btrim(r.spec ->> 'tax_category_code'), '') as category_code,
          coalesce(nullif(btrim(r.spec ->> 'name'), ''), r.def_key) as category_name,
          r.def_key,
          r.spec
        from public.registry_def r
        where r.kind = 'alcohol_type'
          and r.is_active = true
          and (
            (r.scope = 'tenant' and r.owner_id = v_tenant)
            or r.scope = 'system'
          )
      ) c
      where s.raw_category_id is not null
        and (
          c.category_id = s.raw_category_id
          or c.def_key = s.raw_category_id
          or c.category_code = s.raw_category_id
          or c.category_name = s.raw_category_id
          or c.spec ->> 'code' = s.raw_category_id
        )
      order by c.priority
      limit 1
    ) alc on true
    left join lateral (
      select nullif(btrim(r.spec ->> 'tax_rate'), '')::numeric as tax_rate
      from public.registry_def r
      where s.saved_tax_rate is null
        and r.kind = 'alcohol_tax'
        and r.is_active = true
        and (
          (r.scope = 'tenant' and r.owner_id = v_tenant)
          or r.scope = 'system'
        )
        and nullif(btrim(r.spec ->> 'tax_category_code'), '') = alc.category_code
        and nullif(btrim(r.spec ->> 'start_date'), '') is not null
        and (r.spec ->> 'start_date')::date <= s.movement_at::date
        and (
          nullif(btrim(r.spec ->> 'expiration_date'), '') is null
          or (r.spec ->> 'expiration_date')::date >= s.movement_at::date
        )
      order by
        case when r.scope = 'tenant' and r.owner_id = v_tenant then 0 else 1 end,
        (r.spec ->> 'start_date')::date desc,
        r.updated_at desc
      limit 1
    ) rate on true
    where s.raw_category_id is not null
      and s.volume_ml > 0
      and coalesce(s.tax_event, '') <> 'NONE'
  ),
  line_amounts as (
    select
      e.*,
      (e.volume_ml::numeric / 1000) as volume_l,
      case
        when e.tax_rate::text like '%.%' then
          trim(trailing '.' from trim(trailing '0' from e.tax_rate::text))
        else e.tax_rate::text
      end as tax_rate_key,
      case
        when e.tax_direction = 0 then 0
        else e.tax_direction * floor((e.volume_ml::numeric / 1000000) * e.tax_rate)
      end as line_tax_amount
    from enriched_lines e
  ),
  grouped as (
    select
      case
        when l.move_type in ('sale', 'tax_transfer', 'return', 'transfer') then
          coalesce(l.tax_event, 'unknown') || '-' || l.category_id || '-' || coalesce(l.abv::text, 'na') || '-' || l.tax_rate_key
        else
          l.move_type || '-' || coalesce(l.tax_event, 'unknown') || '-' || l.category_id || '-' || coalesce(l.abv::text, 'na') || '-' || l.tax_rate_key
      end as key,
      min(l.move_type) as move_type,
      min(l.movement_at)::date::text as movement_at,
      l.tax_event,
      max(l.tax_attachment_form) as tax_attachment_form,
      max(l.reduced_tax_amount) as reduced_tax_amount,
      max(l.disaster_compensation_amount) as disaster_compensation_amount,
      max(l.remarks) as remarks,
      max(l.removal_date) as removal_date,
      max(l.receipt_date) as receipt_date,
      max(l.removal_temperature) as removal_temperature,
      max(l.receipt_temperature) as receipt_temperature,
      max(l.receipt_abv) as receipt_abv,
      max(l.receipt_volume_ml) as receipt_volume_ml,
      max(l.volume_delta_ml) as volume_delta_ml,
      max(l.importer_address) as importer_address,
      max(l.importer_name) as importer_name,
      max(l.receipt_place_address) as receipt_place_address,
      max(l.receipt_place_name) as receipt_place_name,
      max(l.receipt_purpose) as receipt_purpose,
      l.category_id,
      l.category_code,
      l.category_name,
      l.abv,
      l.tax_rate,
      sum(l.volume_ml)::bigint as volume_ml,
      sum(l.volume_l) as volume_l,
      sum(l.line_tax_amount) as tax_amount,
      max(l.tax_direction) as tax_direction
    from line_amounts l
    group by
      case
        when l.move_type in ('sale', 'tax_transfer', 'return', 'transfer') then
          coalesce(l.tax_event, 'unknown') || '-' || l.category_id || '-' || coalesce(l.abv::text, 'na') || '-' || l.tax_rate_key
        else
          l.move_type || '-' || coalesce(l.tax_event, 'unknown') || '-' || l.category_id || '-' || coalesce(l.abv::text, 'na') || '-' || l.tax_rate_key
      end,
      l.tax_event,
      l.category_id,
      l.category_code,
      l.category_name,
      l.abv,
      l.tax_rate
  )
  select
    coalesce(
      jsonb_agg(
        jsonb_build_object(
          'key', g.key,
          'move_type', g.move_type,
          'movement_at', g.movement_at,
          'tax_event', g.tax_event,
          'tax_attachment_form', g.tax_attachment_form,
          'reduced_tax_amount', g.reduced_tax_amount,
          'disaster_compensation_amount', g.disaster_compensation_amount,
          'remarks', g.remarks,
          'removal_date', g.removal_date,
          'receipt_date', g.receipt_date,
          'removal_temperature', g.removal_temperature,
          'receipt_temperature', g.receipt_temperature,
          'receipt_abv', g.receipt_abv,
          'receipt_volume_ml', g.receipt_volume_ml,
          'volume_delta_ml', g.volume_delta_ml,
          'importer_address', g.importer_address,
          'importer_name', g.importer_name,
          'receipt_place_address', g.receipt_place_address,
          'receipt_place_name', g.receipt_place_name,
          'receipt_purpose', g.receipt_purpose,
          'categoryId', g.category_id,
          'categoryCode', g.category_code,
          'categoryName', g.category_name,
          'abv', g.abv,
          'volume_l', g.volume_l,
          'volume_ml', g.volume_ml,
          'tax_rate', g.tax_rate,
          'tax_amount', g.tax_amount
        )
        order by g.tax_event, g.category_name, g.category_code, g.abv, g.tax_rate
      ),
      '[]'::jsonb
    ),
    coalesce(sum(case when g.move_type in ('sale', 'tax_transfer', 'return', 'transfer') then g.tax_amount else 0 end), 0)
    into v_volume_breakdown, v_total_tax_amount
  from grouped g;

  v_breakdown_count := jsonb_array_length(coalesce(v_volume_breakdown, '[]'::jsonb));
  if v_existing.id is null and v_breakdown_count = 0 and v_declaration_type <> 'amended' then
    raise exception 'TRG005: no reportable source records for selected period'
      using detail = jsonb_build_object(
        'tax_type', v_tax_type,
        'tax_year', v_tax_year,
        'tax_month', v_tax_month
      )::text;
  end if;

  if v_declaration_type = 'amended' then
    v_previous_confirmed_payable_tax_amount := greatest(coalesce(v_previous_report.total_tax_amount, 0), 0);
    v_previous_confirmed_refund_tax_amount := greatest(-coalesce(v_previous_report.total_tax_amount, 0), 0);
    v_correction_delta_tax_amount := coalesce(v_total_tax_amount, 0) - coalesce(v_previous_report.total_tax_amount, 0);

    with previous_items as (
      select
        coalesce(item ->> 'key', '') as key,
        max(item ->> 'move_type') as move_type,
        max(item ->> 'tax_event') as tax_event,
        max(coalesce(item ->> 'categoryId', item ->> 'category_id')) as category_id,
        max(coalesce(item ->> 'categoryCode', item ->> 'category_code')) as category_code,
        max(coalesce(item ->> 'categoryName', item ->> 'category_name')) as category_name,
        max(case when item ->> 'abv' ~ '^-?[0-9]+(\.[0-9]+)?$' then (item ->> 'abv')::numeric else null end) as abv,
        max(case when item ->> 'tax_rate' ~ '^-?[0-9]+(\.[0-9]+)?$' then (item ->> 'tax_rate')::numeric else null end) as tax_rate,
        sum(case
          when item ->> 'volume_ml' ~ '^-?[0-9]+(\.[0-9]+)?$' then round((item ->> 'volume_ml')::numeric)
          when item ->> 'volume_l' ~ '^-?[0-9]+(\.[0-9]+)?$' then round((item ->> 'volume_l')::numeric * 1000)
          else 0
        end) as volume_ml,
        sum(case when item ->> 'tax_amount' ~ '^-?[0-9]+(\.[0-9]+)?$' then (item ->> 'tax_amount')::numeric else 0 end) as tax_amount
      from jsonb_array_elements(coalesce(v_previous_report.volume_breakdown, '[]'::jsonb)) item
      where coalesce(item ->> 'row_role', 'detail') = 'detail'
      group by coalesce(item ->> 'key', '')
    ),
    current_items as (
      select
        coalesce(item ->> 'key', '') as key,
        max(item ->> 'move_type') as move_type,
        max(item ->> 'tax_event') as tax_event,
        max(coalesce(item ->> 'categoryId', item ->> 'category_id')) as category_id,
        max(coalesce(item ->> 'categoryCode', item ->> 'category_code')) as category_code,
        max(coalesce(item ->> 'categoryName', item ->> 'category_name')) as category_name,
        max(case when item ->> 'abv' ~ '^-?[0-9]+(\.[0-9]+)?$' then (item ->> 'abv')::numeric else null end) as abv,
        max(case when item ->> 'tax_rate' ~ '^-?[0-9]+(\.[0-9]+)?$' then (item ->> 'tax_rate')::numeric else null end) as tax_rate,
        sum(case
          when item ->> 'volume_ml' ~ '^-?[0-9]+(\.[0-9]+)?$' then round((item ->> 'volume_ml')::numeric)
          when item ->> 'volume_l' ~ '^-?[0-9]+(\.[0-9]+)?$' then round((item ->> 'volume_l')::numeric * 1000)
          else 0
        end) as volume_ml,
        sum(case when item ->> 'tax_amount' ~ '^-?[0-9]+(\.[0-9]+)?$' then (item ->> 'tax_amount')::numeric else 0 end) as tax_amount
      from jsonb_array_elements(coalesce(v_volume_breakdown, '[]'::jsonb)) item
      where coalesce(item ->> 'row_role', 'detail') = 'detail'
      group by coalesce(item ->> 'key', '')
    ),
    merged as (
      select
        coalesce(c.key, p.key) as key,
        p.move_type as previous_move_type,
        c.move_type as current_move_type,
        p.tax_event as previous_tax_event,
        c.tax_event as current_tax_event,
        coalesce(c.category_id, p.category_id) as category_id,
        coalesce(c.category_code, p.category_code) as category_code,
        coalesce(c.category_name, p.category_name) as category_name,
        coalesce(c.abv, p.abv) as abv,
        coalesce(c.tax_rate, p.tax_rate) as tax_rate,
        coalesce(p.volume_ml, 0) as previous_volume_ml,
        coalesce(c.volume_ml, 0) as current_volume_ml,
        coalesce(p.tax_amount, 0) as previous_tax_amount,
        coalesce(c.tax_amount, 0) as current_tax_amount
      from previous_items p
      full outer join current_items c
        on c.key = p.key
    ),
    comparison as (
      select
        *,
        current_volume_ml - previous_volume_ml as delta_volume_ml,
        current_tax_amount - previous_tax_amount as delta_tax_amount,
        (current_volume_ml <> previous_volume_ml or current_tax_amount <> previous_tax_amount) as changed
      from merged
    )
    select
      coalesce(jsonb_agg(
        jsonb_build_object(
          'key', key,
          'move_type', coalesce(current_move_type, previous_move_type),
          'tax_event', coalesce(current_tax_event, previous_tax_event),
          'categoryId', category_id,
          'categoryCode', category_code,
          'categoryName', category_name,
          'abv', abv,
          'tax_rate', tax_rate,
          'previous_volume_l', previous_volume_ml / 1000.0,
          'current_volume_l', current_volume_ml / 1000.0,
          'delta_volume_l', delta_volume_ml / 1000.0,
          'previous_volume_ml', previous_volume_ml,
          'current_volume_ml', current_volume_ml,
          'delta_volume_ml', delta_volume_ml,
          'previous_tax_amount', previous_tax_amount,
          'current_tax_amount', current_tax_amount,
          'delta_tax_amount', delta_tax_amount,
          'changed', changed
        )
        order by coalesce(current_tax_event, previous_tax_event), category_name, category_code, abv, tax_rate, key
      ), '[]'::jsonb),
      count(*) filter (where changed)
      into v_comparison_breakdown, v_comparison_changed_count
    from comparison;

    if v_comparison_changed_count = 0 then
      raise exception 'TRG006: amended report has no differences from the selected comparison report';
    end if;
  end if;

  if v_existing.id is null then
    insert into public.tax_reports (
      id, tenant_id, tax_type, tax_year, tax_month, status,
      declaration_type, declaration_reason, original_report_id, previous_report_id, amendment_no,
      previous_confirmed_payable_tax_amount, previous_confirmed_refund_tax_amount, correction_delta_tax_amount,
      prior_cumulative_tax_amount_calculated, prior_cumulative_tax_amount_override, prior_cumulative_tax_amount_source,
      prior_cumulative_tax_amount_notes, prior_cumulative_tax_amount_updated_at, prior_cumulative_tax_amount_updated_by,
      total_tax_amount, volume_breakdown, comparison_breakdown, report_files, attachment_files, updated_at
    ) values (
      v_report_id, v_tenant, v_tax_type, v_tax_year, v_tax_month, v_requested_status,
      v_declaration_type, v_declaration_reason, v_original_report_id, v_previous_report_id, v_amendment_no,
      v_previous_confirmed_payable_tax_amount, v_previous_confirmed_refund_tax_amount, v_correction_delta_tax_amount,
      v_prior_cumulative_tax_amount_calculated, v_prior_cumulative_tax_amount_override, v_prior_cumulative_tax_amount_source,
      v_prior_cumulative_tax_amount_notes,
      case when v_prior_cumulative_tax_amount_source = 'manual_override' then now() else null end,
      case when v_prior_cumulative_tax_amount_source = 'manual_override' then auth.uid() else null end,
      v_total_tax_amount, v_volume_breakdown, v_comparison_breakdown, v_report_files, v_attachment_files, now()
    )
    returning * into v_report;
  else
    update public.tax_reports r
       set tax_type = v_tax_type,
           status = v_requested_status,
           declaration_type = v_declaration_type,
           declaration_reason = v_declaration_reason,
           original_report_id = v_original_report_id,
           previous_report_id = v_previous_report_id,
           amendment_no = v_amendment_no,
           previous_confirmed_payable_tax_amount = v_previous_confirmed_payable_tax_amount,
           previous_confirmed_refund_tax_amount = v_previous_confirmed_refund_tax_amount,
           correction_delta_tax_amount = v_correction_delta_tax_amount,
           prior_cumulative_tax_amount_calculated = v_prior_cumulative_tax_amount_calculated,
           prior_cumulative_tax_amount_override = v_prior_cumulative_tax_amount_override,
           prior_cumulative_tax_amount_source = v_prior_cumulative_tax_amount_source,
           prior_cumulative_tax_amount_notes = v_prior_cumulative_tax_amount_notes,
           prior_cumulative_tax_amount_updated_at = case
             when v_prior_cumulative_amount_changed then now()
             else r.prior_cumulative_tax_amount_updated_at
           end,
           prior_cumulative_tax_amount_updated_by = case
             when v_prior_cumulative_amount_changed then auth.uid()
             else r.prior_cumulative_tax_amount_updated_by
           end,
           total_tax_amount = v_total_tax_amount,
           volume_breakdown = v_volume_breakdown,
           comparison_breakdown = v_comparison_breakdown,
           report_files = v_report_files,
           attachment_files = v_attachment_files,
           updated_at = now()
     where r.tenant_id = v_tenant
       and r.id = v_report_id
    returning * into v_report;
  end if;

  v_report_id := v_report.id;

  if (v_existing.id is null and v_prior_cumulative_tax_amount_source = 'manual_override')
     or v_prior_cumulative_amount_changed then
    insert into public.tax_report_cumulative_amount_audit (
      tenant_id, tax_report_id, old_override_amount, new_override_amount,
      old_source, new_source, notes, changed_by
    ) values (
      v_tenant,
      v_report_id,
      v_existing.prior_cumulative_tax_amount_override,
      v_prior_cumulative_tax_amount_override,
      coalesce(v_existing.prior_cumulative_tax_amount_source, 'calculated'),
      v_prior_cumulative_tax_amount_source,
      v_prior_cumulative_tax_amount_notes,
      auth.uid()
    );
  end if;

  delete from public.tax_report_movement_refs r
  where r.tenant_id = v_tenant
    and r.tax_report_id = v_report_id;

  with source_lines as (
    select
      m.id as movement_id,
      ml.id as movement_line_id,
      m.movement_at,
      m.doc_type::text as move_type,
      coalesce(
        nullif(btrim(m.meta ->> 'tax_event'), ''),
        nullif(btrim(m.meta ->> 'tax_decision_code'), ''),
        case m.doc_type::text
          when 'sale' then 'TAXABLE_REMOVAL'
          when 'tax_transfer' then 'EXPORT_EXEMPT'
          when 'return' then 'RETURN_TO_FACTORY'
          when 'transfer' then 'NON_TAXABLE_REMOVAL'
          when 'waste' then 'NON_TAXABLE_REMOVAL'
          else null
        end
      ) as tax_event,
      case lower(coalesce(u.code, 'l'))
        when 'ml' then round(ml.qty)
        when 'kl' then round(ml.qty * 1000000)
        when 'gal_us' then round(ml.qty * 3785.41)
        else round(ml.qty * 1000)
      end as volume_ml,
      cat.raw_category_id
    from public.inv_movements m
    join public.inv_movement_lines ml
      on ml.tenant_id = m.tenant_id
     and ml.movement_id = m.id
    left join public.mst_uom u
      on u.id = ml.uom_id
    left join lateral (
      select coalesce(
        nullif(btrim(ea.value_json ->> 'def_id'), ''),
        nullif(btrim(ea.value_text), ''),
        ea.value_ref_type_id::text
      ) as raw_category_id
      from public.entity_attr ea
      join public.attr_def ad
        on ad.attr_id = ea.attr_id
      where ea.tenant_id = v_tenant
        and ea.entity_type = 'batch'
        and ea.entity_id = ml.batch_id
        and ad.domain = 'batch'
        and ad.code = 'beer_category'
        and ad.is_active = true
      order by ea.updated_at desc
      limit 1
    ) cat on true
    where m.tenant_id = v_tenant
      and m.status <> 'void'
      and m.doc_type::text in ('sale', 'tax_transfer', 'return', 'transfer', 'waste')
      and m.movement_at >= v_start_date
      and m.movement_at < v_end_date
      and (ml.package_id is not null or ml.batch_id is not null)
  )
  insert into public.tax_report_movement_refs (
    tenant_id, tax_report_id, movement_id, movement_line_id,
    tax_event, role, source_period_year, source_period_month
  )
  select
    v_tenant,
    v_report_id,
    s.movement_id,
    s.movement_line_id,
    s.tax_event,
    'source',
    extract(year from s.movement_at)::int,
    extract(month from s.movement_at)::int
  from source_lines s
  where s.raw_category_id is not null
    and s.volume_ml > 0
    and coalesce(s.tax_event, '') <> 'NONE'
  on conflict do nothing;

  get diagnostics v_ref_count = row_count;

  return jsonb_build_object(
    'report', to_jsonb(v_report),
    'ref_count', v_ref_count
  );
end;
$$;
comment on function public.tax_report_generate(jsonb) is '{"version":5}';
