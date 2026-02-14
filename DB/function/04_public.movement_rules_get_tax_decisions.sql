create or replace function public.movement_rules_get_tax_decisions(
  p_movement_intent text,
  p_src_site_type text,
  p_dst_site_type text,
  p_lot_tax_type text
)
returns jsonb
language plpgsql
stable
security invoker
as $$
declare
  v_rules jsonb;
  v_decisions jsonb;
begin
  if p_movement_intent is null or p_src_site_type is null or p_dst_site_type is null or p_lot_tax_type is null then
    raise exception 'All parameters are required';
  end if;

  v_rules := public.movement_rules_get_ui();

  select coalesce(r.item -> 'allowed_tax_decisions', '[]'::jsonb)
    into v_decisions
  from jsonb_array_elements(coalesce(v_rules -> 'tax_transformation_rules', '[]'::jsonb)) as r(item)
  where r.item ->> 'movement_intent' = p_movement_intent
    and r.item ->> 'src_site_type' = p_src_site_type
    and r.item ->> 'dst_site_type' = p_dst_site_type
    and r.item ->> 'lot_tax_type' = p_lot_tax_type
  limit 1;

  if v_decisions is null then
    return '[]'::jsonb;
  end if;

  return v_decisions;
end;
$$;
