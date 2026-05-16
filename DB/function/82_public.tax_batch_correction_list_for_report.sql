create or replace function public.tax_batch_correction_list_for_report(p_tax_report_id uuid)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_report public.tax_reports%rowtype;
  v_batch_options jsonb := '[]'::jsonb;
  v_corrections jsonb := '[]'::jsonb;
begin
  if p_tax_report_id is null then
    raise exception 'TBC001: p_tax_report_id is required';
  end if;

  v_tenant := public._assert_tenant();

  select *
    into v_report
  from public.tax_reports r
  where r.tenant_id = v_tenant
    and r.id = p_tax_report_id;

  if v_report.id is null then
    raise exception 'TBC002: tax report not found';
  end if;

  with source_lines as (
    select
      ml.batch_id,
      coalesce(
        nullif(btrim(ml.meta ->> 'tax_category_code'), ''),
        nullif(btrim(ml.meta ->> 'beer_category'), ''),
        nullif(btrim(m.meta ->> 'tax_category_code'), ''),
        nullif(btrim(m.meta ->> 'beer_category'), ''),
        cat.raw_category_id
      ) as raw_category_id,
      coalesce(
        case
          when nullif(btrim(ml.meta ->> 'actual_abv'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
            nullif(btrim(ml.meta ->> 'actual_abv'), '')::numeric
          when nullif(btrim(ml.meta ->> 'abv'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
            nullif(btrim(ml.meta ->> 'abv'), '')::numeric
          when nullif(btrim(m.meta ->> 'actual_abv'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
            nullif(btrim(m.meta ->> 'actual_abv'), '')::numeric
          when nullif(btrim(m.meta ->> 'abv'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
            nullif(btrim(m.meta ->> 'abv'), '')::numeric
          else null
        end,
        actual_abv.abv
      ) as actual_abv,
      coalesce(
        case
          when nullif(btrim(ml.meta ->> 'target_abv'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
            nullif(btrim(ml.meta ->> 'target_abv'), '')::numeric
          when nullif(btrim(m.meta ->> 'target_abv'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
            nullif(btrim(m.meta ->> 'target_abv'), '')::numeric
          else null
        end,
        target_abv.abv
      ) as target_abv
    from public.tax_report_movement_refs ref
    join public.inv_movement_lines ml
      on ml.tenant_id = ref.tenant_id
     and ml.id = ref.movement_line_id
    join public.inv_movements m
      on m.tenant_id = ref.tenant_id
     and m.id = ref.movement_id
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
        and ad.code = 'actual_abv'
        and ad.is_active = true
      order by ea.updated_at desc
      limit 1
    ) actual_abv on true
    left join lateral (
      select ea.value_num as abv
      from public.entity_attr ea
      join public.attr_def ad
        on ad.attr_id = ea.attr_id
      where ea.tenant_id = v_tenant
        and ea.entity_type = 'batch'
        and ea.entity_id = ml.batch_id
        and ad.domain = 'batch'
        and ad.code = 'target_abv'
        and ad.is_active = true
      order by ea.updated_at desc
      limit 1
    ) target_abv on true
    where ref.tenant_id = v_tenant
      and ref.tax_report_id = p_tax_report_id
      and ref.role = 'source'
      and ml.batch_id is not null
      and m.status <> 'void'
  ),
  grouped as (
    select
      b.id as batch_id,
      b.batch_code,
      b.batch_label,
      count(*)::int as affected_movement_count,
      min(coalesce(alc.category_id, s.raw_category_id)) as beer_category_id,
      min(coalesce(alc.category_name, s.raw_category_id, '—')) as beer_category_name,
      min(s.actual_abv) as actual_abv,
      min(s.target_abv) as target_abv
    from source_lines s
    join public.mes_batches b
      on b.tenant_id = v_tenant
     and b.id = s.batch_id
    left join lateral (
      select c.category_id, c.category_name
      from (
        select
          0 as priority,
          v.def_id::text as category_id,
          coalesce(nullif(btrim(v.label), ''), nullif(btrim(v.spec ->> 'name'), ''), v.def_key, v.key) as category_name,
          v.def_key,
          nullif(btrim(v.key), '') as category_code,
          v.spec
        from public.v_alcohol_type_options v
        union all
        select
          1 as priority,
          r.def_id::text as category_id,
          coalesce(nullif(btrim(r.spec ->> 'name'), ''), r.def_key) as category_name,
          r.def_key,
          nullif(btrim(r.spec ->> 'tax_category_code'), '') as category_code,
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
    group by b.id, b.batch_code, b.batch_label
  )
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'batch_id', batch_id,
      'batch_code', batch_code,
      'batch_label', batch_label,
      'affected_movement_count', affected_movement_count,
      'beer_category_id', beer_category_id,
      'beer_category_name', beer_category_name,
      'actual_abv', actual_abv,
      'target_abv', target_abv
    )
    order by batch_code
  ), '[]'::jsonb)
    into v_batch_options
  from grouped;

  with correction_rows as (
    select
      c.*,
      b.batch_code,
      b.batch_label,
      old_alc.category_name as old_beer_category_name,
      new_alc.category_name as new_beer_category_name
    from public.tax_batch_corrections c
    join public.mes_batches b
      on b.tenant_id = c.tenant_id
     and b.id = c.batch_id
    left join lateral (
      select coalesce(nullif(btrim(v.label), ''), nullif(btrim(v.spec ->> 'name'), ''), v.def_key, v.key) as category_name
      from public.v_alcohol_type_options v
      where v.def_id::text = c.old_beer_category_id
         or v.def_key = c.old_beer_category_id
         or v.key = c.old_beer_category_id
      limit 1
    ) old_alc on true
    left join lateral (
      select coalesce(nullif(btrim(v.label), ''), nullif(btrim(v.spec ->> 'name'), ''), v.def_key, v.key) as category_name
      from public.v_alcohol_type_options v
      where v.def_id::text = c.new_beer_category_id
         or v.def_key = c.new_beer_category_id
         or v.key = c.new_beer_category_id
      limit 1
    ) new_alc on true
    where c.tenant_id = v_tenant
      and (
        c.comparison_report_id = p_tax_report_id
        or c.used_report_id = p_tax_report_id
      )
  )
  select coalesce(jsonb_agg(
    to_jsonb(correction_rows) - 'tenant_id'
    order by correction_rows.created_at desc
  ), '[]'::jsonb)
    into v_corrections
  from correction_rows;

  return jsonb_build_object(
    'report', to_jsonb(v_report),
    'batch_options', v_batch_options,
    'corrections', v_corrections
  );
end;
$$;
comment on function public.tax_batch_correction_list_for_report(uuid) is '{"version":1}';
