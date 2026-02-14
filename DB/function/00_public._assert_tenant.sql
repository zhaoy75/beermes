create or replace function public._assert_tenant()
returns uuid
language plpgsql
security invoker
as $$
declare
  v_tenant_text text;
  v_tenant uuid;
begin
  v_tenant_text := auth.jwt() -> 'app_metadata' ->> 'tenant_id';
  if v_tenant_text is null or btrim(v_tenant_text) = '' then
    raise exception 'Missing tenant_id in JWT app_metadata';
  end if;

  v_tenant := v_tenant_text::uuid;
  return v_tenant;
exception
  when invalid_text_representation then
    raise exception 'Invalid tenant_id format in JWT app_metadata';
end;
$$;
