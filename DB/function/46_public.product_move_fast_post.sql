create or replace function public.product_move_fast_post(p_docs jsonb)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_doc jsonb;
  v_idx int;
  v_movement_id uuid;
  v_movement_ids jsonb := '[]'::jsonb;
begin
  v_tenant := public._assert_tenant();

  if p_docs is null or jsonb_typeof(p_docs) <> 'array' then
    raise exception 'PMF001: p_docs must be a json array';
  end if;

  if jsonb_array_length(p_docs) = 0 then
    raise exception 'PMF001: p_docs must include at least one segment';
  end if;

  for v_doc, v_idx in
    select value, ordinality::int
    from jsonb_array_elements(p_docs) with ordinality
  loop
    begin
      v_movement_id := public.product_move(v_doc);
    exception
      when others then
        raise exception 'PMF500: failed to post segment %: %', v_idx, sqlerrm;
    end;
    v_movement_ids := v_movement_ids || jsonb_build_array(v_movement_id);
  end loop;

  return jsonb_build_object(
    'tenant_id', v_tenant,
    'count', jsonb_array_length(v_movement_ids),
    'movement_ids', v_movement_ids
  );
end;
$$;
comment on function public.product_move_fast_post(jsonb) is '{"version":1}';
