create or replace function public.movement_get_rules(p_movement_intent text)
returns jsonb
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_rules jsonb;
  v_movement_intent text;
  v_is_valid_intent boolean := false;
  v_movement_intent_rules jsonb := '[]'::jsonb;
  v_tax_transformation_rules jsonb := '[]'::jsonb;
begin
  v_tenant := public._assert_tenant();
  v_movement_intent := nullif(btrim(coalesce(p_movement_intent, '')), '');

  select r.spec
    into v_rules
  from public.registry_def r
  where r.kind = 'ruleengine'
    and r.def_key = 'beer_movement_rule'
    and r.is_active = true
    and (
      (r.scope = 'tenant' and r.owner_id = v_tenant)
      or r.scope = 'system'
    )
  order by
    case when r.scope = 'tenant' and r.owner_id = v_tenant then 0 else 1 end,
    r.updated_at desc
  limit 1;

  if v_rules is null then
    return jsonb_build_object(
      'enums', '{}'::jsonb,
      'tax_decision_code', '[]'::jsonb,
      'movement_intent_rules', '[]'::jsonb,
      'tax_transformation_rules', '[]'::jsonb
    );
  end if;

  if v_movement_intent is not null then
    select exists (
      select 1
      from jsonb_array_elements_text(coalesce(v_rules -> 'enums' -> 'movement_intent', '[]'::jsonb)) e(v)
      where e.v = v_movement_intent
    )
      into v_is_valid_intent;
  end if;

  if v_is_valid_intent then
    select coalesce(jsonb_agg(i.item), '[]'::jsonb)
      into v_movement_intent_rules
    from jsonb_array_elements(coalesce(v_rules -> 'movement_intent_rules', '[]'::jsonb)) i(item)
    where i.item ->> 'movement_intent' = v_movement_intent;

    select coalesce(jsonb_agg(t.item), '[]'::jsonb)
      into v_tax_transformation_rules
    from jsonb_array_elements(coalesce(v_rules -> 'tax_transformation_rules', '[]'::jsonb)) t(item)
    where t.item ->> 'movement_intent' = v_movement_intent;
  end if;

  return jsonb_build_object(
    'enums', coalesce(v_rules -> 'enums', '{}'::jsonb),
    'tax_decision_code', coalesce(v_rules -> 'enums' -> 'tax_decision_code', '[]'::jsonb),
    'movement_intent_rules', coalesce(v_movement_intent_rules, '[]'::jsonb),
    'tax_transformation_rules', coalesce(v_tax_transformation_rules, '[]'::jsonb)
  );
end;
$$;
