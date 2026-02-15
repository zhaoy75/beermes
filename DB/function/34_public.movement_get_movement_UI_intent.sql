create or replace function public.movement_get_movement_ui_intent()
returns table (
  movement_intent text,
  name_ja text,
  name_en text
)
language sql
stable
security invoker
as $$
  with v_tenant as (
    select public._assert_tenant() as tenant_id
  ),
  v_rule as (
    select r.spec
    from public.registry_def r
    cross join v_tenant t
    where r.kind = 'ruleengine'
      and r.def_key = 'beer_movement_rule'
      and r.is_active = true
      and (
        (r.scope = 'tenant' and r.owner_id = t.tenant_id)
        or r.scope = 'system'
      )
    order by
      case when r.scope = 'tenant' and r.owner_id = t.tenant_id then 0 else 1 end,
      r.updated_at desc
    limit 1
  ),
  v_intents as (
    select e.value as movement_intent, e.ordinality as sort_order
    from v_rule r
    cross join lateral jsonb_array_elements_text(
      coalesce(r.spec -> 'enums' -> 'movement_intent', '[]'::jsonb)
    ) with ordinality as e(value, ordinality)
  ),
  v_labels as (
    select l.key as movement_intent, l.value as label
    from v_rule r
    cross join lateral jsonb_each(
      coalesce(r.spec -> 'movement_intent_labels', '{}'::jsonb)
    ) as l(key, value)
  )
  select
    i.movement_intent,
    nullif(l.label ->> 'ja', '') as name_ja,
    nullif(l.label ->> 'en', '') as name_en
  from v_intents i
  join v_labels l
    on l.movement_intent = i.movement_intent
  where coalesce(lower(l.label ->> 'show_in_movement_wizard') = 'true', false)
  order by i.sort_order;
$$;
