create or replace function public.batch_search(p_filter jsonb)
returns table (
  id uuid,
  batch_code text,
  status mes_batch_status,
  recipe_id uuid,
  planned_start timestamptz,
  planned_end timestamptz,
  actual_start timestamptz,
  actual_end timestamptz,
  created_at timestamptz
)
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_limit int;
  v_offset int;
begin
  v_tenant := public._assert_tenant();
  v_limit := greatest(1, least(coalesce((p_filter ->> 'limit')::int, 100), 500));
  v_offset := greatest(0, coalesce((p_filter ->> 'offset')::int, 0));

  return query
  select b.id, b.batch_code, b.status, b.recipe_id,
         b.planned_start, b.planned_end, b.actual_start, b.actual_end, b.created_at
  from public.mes_batches b
  where b.tenant_id = v_tenant
    and ((p_filter ->> 'status') is null or b.status::text = (p_filter ->> 'status'))
    and ((p_filter ->> 'recipe_id') is null or b.recipe_id = (p_filter ->> 'recipe_id')::uuid)
    and ((p_filter ->> 'planned_from') is null or b.planned_start >= (p_filter ->> 'planned_from')::timestamptz)
    and ((p_filter ->> 'planned_to') is null or b.planned_start <= (p_filter ->> 'planned_to')::timestamptz)
    and ((p_filter ->> 'keyword') is null or b.batch_code ilike ('%' || (p_filter ->> 'keyword') || '%') or coalesce(b.batch_label,'') ilike ('%' || (p_filter ->> 'keyword') || '%'))
  order by b.created_at desc
  limit v_limit offset v_offset;
end;
$$;
