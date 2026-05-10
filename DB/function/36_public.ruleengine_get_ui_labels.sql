create or replace function public.ruleengine_get_ui_labels()
returns jsonb
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_rules jsonb;
  v_updated_at timestamptz;
begin
  v_tenant := public._assert_tenant();

  select r.spec, r.updated_at
    into v_rules, v_updated_at
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

  return jsonb_build_object(
    'version', coalesce(v_rules ->> 'version', ''),
    'updated_at', v_updated_at,
    'enums', jsonb_build_object(
      'movement_intent', coalesce(v_rules -> 'enums' -> 'movement_intent', '[]'::jsonb),
      'site_type', coalesce(v_rules -> 'enums' -> 'site_type', '[]'::jsonb),
      'lot_tax_type', coalesce(v_rules -> 'enums' -> 'lot_tax_type', '[]'::jsonb),
      'tax_event', coalesce(v_rules -> 'enums' -> 'tax_event', '[]'::jsonb),
      'edge_type', coalesce(v_rules -> 'enums' -> 'edge_type', '[]'::jsonb),
      'tax_decision_code', coalesce(v_rules -> 'enums' -> 'tax_decision_code', '[]'::jsonb)
    ),
    'labels', jsonb_build_object(
      'movement_intent', coalesce(v_rules -> 'movement_intent_labels', '{}'::jsonb),
      'site_type', coalesce(v_rules -> 'site_type_labels', '{}'::jsonb),
      'lot_tax_type', coalesce(v_rules -> 'lot_tax_type_labels', '{}'::jsonb),
      'tax_event', coalesce(v_rules -> 'tax_event_labels', '{}'::jsonb),
      'edge_type', coalesce(v_rules -> 'edge_type_labels', '{}'::jsonb),
      'tax_decision_code', coalesce(v_rules -> 'tax_decision_code_labels', '{}'::jsonb)
    )
  );
end;
$$;
comment on function public.ruleengine_get_ui_labels() is '{"version":1}';
