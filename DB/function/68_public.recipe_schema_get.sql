create or replace function public.recipe_schema_get(
  p_def_key text default 'recipe_body_v1'
)
returns jsonb
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_def_key text;
  v_def_id uuid;
  v_scope text;
  v_spec jsonb;
begin
  v_def_key := nullif(btrim(coalesce(p_def_key, '')), '');
  if v_def_key is null then
    raise exception 'RSG001: p_def_key is required';
  end if;


  v_tenant := public._assert_tenant();

  select
    r.def_id,
    r.scope,
    r.spec
    into v_def_id, v_scope, v_spec
  from public.registry_def r
  where r.kind = 'recipe_schema'
    and r.def_key = v_def_key
    and r.is_active = true
    and (
      (r.scope = 'tenant' and r.owner_id = v_tenant)
      or r.scope = 'system'
    )
  order by
    case when r.scope = 'tenant' and r.owner_id = v_tenant then 0 else 1 end,
    r.updated_at desc
  limit 1;

  if v_spec is null then
    raise exception 'RSG002: recipe schema definition not found for key %', v_def_key;
  end if;

  if jsonb_typeof(v_spec) <> 'object' then
    raise exception 'RSG003: invalid recipe schema definition in registry_def.spec';
  end if;

  return jsonb_build_object(
    'def_id', v_def_id,
    'def_key', v_def_key,
    'scope', v_scope,
    'schema', v_spec
  );
end;
$$;
comment on function public.recipe_schema_get(text) is '{"version":1}';
