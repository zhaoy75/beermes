create or replace function public._tax_batch_correction_preview_payload(
  p_tenant uuid,
  p_comparison_report_id uuid,
  p_batch_id uuid,
  p_new_beer_category_id text default null,
  p_new_actual_abv numeric default null,
  p_new_target_abv numeric default null
)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_report public.tax_reports%rowtype;
  v_payload jsonb;
begin
  if p_tenant is null then
    raise exception 'TBC001: tenant is required';
  end if;
  if p_comparison_report_id is null then
    raise exception 'TBC001: comparison_report_id is required';
  end if;
  if p_batch_id is null then
    raise exception 'TBC001: batch_id is required';
  end if;

  select *
    into v_report
  from public.tax_reports r
  where r.tenant_id = p_tenant
    and r.id = p_comparison_report_id;

  if v_report.id is null then
    raise exception 'TBC002: comparison tax report not found';
  end if;

  if v_report.status not in ('submitted', 'approved') then
    raise exception 'TBC003: comparison tax report must be submitted or approved';
  end if;

  if nullif(btrim(coalesce(p_new_beer_category_id, '')), '') is not null
     and not exists (
       select 1
       from public.v_alcohol_type_options v
       where v.def_id::text = nullif(btrim(p_new_beer_category_id), '')
          or v.def_key = nullif(btrim(p_new_beer_category_id), '')
          or v.key = nullif(btrim(p_new_beer_category_id), '')
          or v.value = nullif(btrim(p_new_beer_category_id), '')
       union all
       select 1
       from public.registry_def r
       where r.kind = 'alcohol_type'
         and r.is_active = true
         and (
           (r.scope = 'tenant' and r.owner_id = p_tenant)
           or r.scope = 'system'
         )
         and (
           r.def_id::text = nullif(btrim(p_new_beer_category_id), '')
           or r.def_key = nullif(btrim(p_new_beer_category_id), '')
           or nullif(btrim(r.spec ->> 'tax_category_code'), '') = nullif(btrim(p_new_beer_category_id), '')
           or nullif(btrim(r.spec ->> 'name'), '') = nullif(btrim(p_new_beer_category_id), '')
           or r.spec ->> 'code' = nullif(btrim(p_new_beer_category_id), '')
         )
     ) then
    raise exception 'TBC011: corrected beer category was not found';
  end if;

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
      nullif(case
        when ml.tax_rate > 0 then ml.tax_rate
        when nullif(btrim(ml.meta ->> 'tax_rate'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(ml.meta ->> 'tax_rate'), '')::numeric
        when nullif(btrim(m.meta ->> 'tax_rate'), '') ~ '^[0-9]+(\.[0-9]+)?$' then
          nullif(btrim(m.meta ->> 'tax_rate'), '')::numeric
        else null
      end, 0) as saved_tax_rate,
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
      where ea.tenant_id = p_tenant
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
      where ea.tenant_id = p_tenant
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
      where ea.tenant_id = p_tenant
        and ea.entity_type = 'batch'
        and ea.entity_id = ml.batch_id
        and ad.domain = 'batch'
        and ad.code = 'target_abv'
        and ad.is_active = true
      order by ea.updated_at desc
      limit 1
    ) target_abv on true
    where ref.tenant_id = p_tenant
      and ref.tax_report_id = p_comparison_report_id
      and ref.role = 'source'
      and ml.batch_id = p_batch_id
      and m.status <> 'void'
  ),
  resolved_lines as (
    select
      s.*,
      coalesce(old_alc.category_id, s.raw_category_id) as old_category_id,
      old_alc.category_code as old_category_code,
      coalesce(old_alc.category_name, s.raw_category_id, '—') as old_category_name,
      coalesce(new_alc.category_id, nullif(btrim(p_new_beer_category_id), ''), coalesce(old_alc.category_id, s.raw_category_id)) as new_category_id,
      new_alc.category_code as new_category_code,
      coalesce(new_alc.category_name, old_alc.category_name, nullif(btrim(p_new_beer_category_id), ''), s.raw_category_id, '—') as new_category_name,
      coalesce(p_new_actual_abv, s.actual_abv) as effective_actual_abv,
      coalesce(p_new_target_abv, s.target_abv) as effective_target_abv
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
            (r.scope = 'tenant' and r.owner_id = p_tenant)
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
    ) old_alc on true
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
            (r.scope = 'tenant' and r.owner_id = p_tenant)
            or r.scope = 'system'
          )
      ) c
      where nullif(btrim(p_new_beer_category_id), '') is not null
        and (
          c.category_id = nullif(btrim(p_new_beer_category_id), '')
          or c.def_key = nullif(btrim(p_new_beer_category_id), '')
          or c.category_code = nullif(btrim(p_new_beer_category_id), '')
          or c.category_name = nullif(btrim(p_new_beer_category_id), '')
          or c.spec ->> 'code' = nullif(btrim(p_new_beer_category_id), '')
        )
      order by c.priority
      limit 1
    ) new_alc on true
    where s.raw_category_id is not null
      and s.volume_ml > 0
      and coalesce(s.tax_event, '') <> 'NONE'
  ),
  rated_lines as (
    select
      r.*,
      coalesce(r.actual_abv, r.target_abv) as old_effective_abv,
      coalesce(r.effective_actual_abv, r.effective_target_abv) as new_effective_abv,
      coalesce(r.saved_tax_rate, old_rate.tax_rate, 0) as old_tax_rate,
      case
        when nullif(btrim(p_new_beer_category_id), '') is null then coalesce(r.saved_tax_rate, new_rate.tax_rate, 0)
        else coalesce(new_rate.tax_rate, 0)
      end as new_tax_rate,
      case
        when r.move_type in ('sale', 'tax_transfer', 'return', 'transfer')
             and r.tax_event = 'TAXABLE_REMOVAL' then 1
        when r.move_type in ('sale', 'tax_transfer', 'return', 'transfer')
             and r.tax_event = 'RETURN_TO_FACTORY' then -1
        else 0
      end as tax_direction
    from resolved_lines r
    left join lateral (
      select nullif(btrim(tax.spec ->> 'tax_rate'), '')::numeric as tax_rate
      from public.registry_def tax
      where r.saved_tax_rate is null
        and tax.kind = 'alcohol_tax'
        and tax.is_active = true
        and (
          (tax.scope = 'tenant' and tax.owner_id = p_tenant)
          or tax.scope = 'system'
        )
        and nullif(btrim(tax.spec ->> 'tax_category_code'), '') = r.old_category_code
        and nullif(btrim(tax.spec ->> 'start_date'), '') is not null
        and (tax.spec ->> 'start_date')::date <= r.movement_at::date
        and (
          nullif(btrim(tax.spec ->> 'expiration_date'), '') is null
          or (tax.spec ->> 'expiration_date')::date >= r.movement_at::date
        )
      order by
        case when tax.scope = 'tenant' and tax.owner_id = p_tenant then 0 else 1 end,
        (tax.spec ->> 'start_date')::date desc,
        tax.updated_at desc
      limit 1
    ) old_rate on true
    left join lateral (
      select nullif(btrim(tax.spec ->> 'tax_rate'), '')::numeric as tax_rate
      from public.registry_def tax
      where tax.kind = 'alcohol_tax'
        and tax.is_active = true
        and (
          (tax.scope = 'tenant' and tax.owner_id = p_tenant)
          or tax.scope = 'system'
        )
        and nullif(btrim(tax.spec ->> 'tax_category_code'), '') = coalesce(r.new_category_code, r.old_category_code)
        and nullif(btrim(tax.spec ->> 'start_date'), '') is not null
        and (tax.spec ->> 'start_date')::date <= r.movement_at::date
        and (
          nullif(btrim(tax.spec ->> 'expiration_date'), '') is null
          or (tax.spec ->> 'expiration_date')::date >= r.movement_at::date
        )
      order by
        case when tax.scope = 'tenant' and tax.owner_id = p_tenant then 0 else 1 end,
        (tax.spec ->> 'start_date')::date desc,
        tax.updated_at desc
      limit 1
    ) new_rate on true
  ),
  totals as (
    select
      count(*)::int as affected_movement_count,
      coalesce(sum(volume_ml), 0)::bigint as affected_volume_ml,
      min(old_category_id) as old_beer_category_id,
      min(old_category_name) as old_beer_category_name,
      min(new_category_id) as new_beer_category_id,
      min(new_category_name) as new_beer_category_name,
      min(actual_abv) as old_actual_abv,
      min(target_abv) as old_target_abv,
      min(effective_actual_abv) as new_actual_abv,
      min(effective_target_abv) as new_target_abv,
      count(distinct old_category_id) filter (where old_category_id is not null) as old_category_count,
      count(distinct actual_abv) filter (where actual_abv is not null) as old_actual_abv_count,
      count(distinct target_abv) filter (where target_abv is not null) as old_target_abv_count,
      coalesce(sum(
        case when tax_direction = 0 then 0
        else tax_direction * floor((volume_ml::numeric / 1000000) * old_tax_rate)
        end
      ), 0) as previous_tax_amount,
      coalesce(sum(
        case when tax_direction = 0 then 0
        else tax_direction * floor((volume_ml::numeric / 1000000) * new_tax_rate)
        end
      ), 0) as corrected_tax_amount
    from rated_lines
  )
  select jsonb_build_object(
    'comparison_report_id', v_report.id,
    'tax_type', v_report.tax_type,
    'tax_year', v_report.tax_year,
    'tax_month', v_report.tax_month,
    'batch_id', b.id,
    'batch_code', b.batch_code,
    'batch_label', b.batch_label,
    'old_beer_category_id', t.old_beer_category_id,
    'old_beer_category_name', t.old_beer_category_name,
    'new_beer_category_id', t.new_beer_category_id,
    'new_beer_category_name', t.new_beer_category_name,
    'old_actual_abv', t.old_actual_abv,
    'new_actual_abv', t.new_actual_abv,
    'old_target_abv', t.old_target_abv,
    'new_target_abv', t.new_target_abv,
    'affected_movement_count', t.affected_movement_count,
    'affected_volume_ml', t.affected_volume_ml,
    'affected_volume_l', t.affected_volume_ml / 1000.0,
    'previous_tax_amount', t.previous_tax_amount,
    'corrected_tax_amount', t.corrected_tax_amount,
    'delta_tax_amount', t.corrected_tax_amount - t.previous_tax_amount,
    'old_category_count', t.old_category_count,
    'old_actual_abv_count', t.old_actual_abv_count,
    'old_target_abv_count', t.old_target_abv_count
  )
    into v_payload
  from totals t
  join public.mes_batches b
    on b.tenant_id = p_tenant
   and b.id = p_batch_id;

  if coalesce((v_payload ->> 'affected_movement_count')::int, 0) = 0 then
    raise exception 'TBC005: no report source movements found for selected batch';
  end if;

  return v_payload;
end;
$$;
comment on function public._tax_batch_correction_preview_payload(uuid, uuid, uuid, text, numeric, numeric) is '{"version":1}';
