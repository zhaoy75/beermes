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
  v_volume_breakdown jsonb := '[]'::jsonb;
  v_total_tax_amount numeric := 0;
  v_report_files jsonb;
  v_attachment_files jsonb;
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

  if v_tax_type <> 'monthly' then
    raise exception 'TRG002: only monthly tax reports are supported';
  end if;

  if v_tax_year is null or v_tax_month is null or v_tax_month < 1 or v_tax_month > 12 then
    raise exception 'TRG002: tax_year and tax_month are required';
  end if;

  if v_requested_status not in ('draft', 'stale') then
    raise exception 'TRG003: tax_report_generate can only write draft or stale reports';
  end if;

  if v_report_id is not null then
    select *
      into v_existing
    from public.tax_reports r
    where r.tenant_id = v_tenant
      and r.id = v_report_id
    for update;
  else
    select *
      into v_existing
    from public.tax_reports r
    where r.tenant_id = v_tenant
      and r.tax_type = v_tax_type
      and r.tax_year = v_tax_year
      and r.tax_month = v_tax_month
    for update;
  end if;

  if v_existing.id is not null and v_existing.status in ('submitted', 'approved') then
    raise exception 'TRG004: submitted or approved tax report cannot be regenerated';
  end if;

  v_report_id := coalesce(v_existing.id, v_report_id, gen_random_uuid());
  v_start_date := make_date(v_tax_year, v_tax_month, 1);
  v_end_date := (v_start_date + interval '1 month')::date;
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
      and coalesce(s.tax_event, '') not in ('NONE', 'RETURN_TO_FACTORY_NON_TAXABLE')
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
      l.tax_event,
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
          'tax_event', g.tax_event,
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
  if v_existing.id is null and v_breakdown_count = 0 then
    raise exception 'TRG005: no reportable source records for selected period'
      using detail = jsonb_build_object(
        'tax_type', v_tax_type,
        'tax_year', v_tax_year,
        'tax_month', v_tax_month
      )::text;
  end if;

  insert into public.tax_reports (
    id, tenant_id, tax_type, tax_year, tax_month, status,
    total_tax_amount, volume_breakdown, report_files, attachment_files
  ) values (
    v_report_id, v_tenant, v_tax_type, v_tax_year, v_tax_month, v_requested_status,
    v_total_tax_amount, v_volume_breakdown, v_report_files, v_attachment_files
  )
  on conflict (tenant_id, tax_year, tax_month) do update
     set tax_type = excluded.tax_type,
         status = excluded.status,
         total_tax_amount = excluded.total_tax_amount,
         volume_breakdown = excluded.volume_breakdown,
         report_files = excluded.report_files,
         attachment_files = excluded.attachment_files
  returning * into v_report;

  v_report_id := v_report.id;

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
    and coalesce(s.tax_event, '') not in ('NONE', 'RETURN_TO_FACTORY_NON_TAXABLE')
  on conflict do nothing;

  get diagnostics v_ref_count = row_count;

  return jsonb_build_object(
    'report', to_jsonb(v_report),
    'ref_count', v_ref_count
  );
end;
$$;
comment on function public.tax_report_generate(jsonb) is '{"version":1}';
