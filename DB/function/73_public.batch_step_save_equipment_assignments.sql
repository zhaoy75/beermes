create or replace function public.batch_step_save_equipment_assignments(
  p_batch_step_id uuid,
  p_rows jsonb default '[]'::jsonb
)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_actor_user_id uuid;
  v_batch_id uuid;
  v_saved_count integer := 0;
begin
  if p_batch_step_id is null then
    raise exception 'BSEA001: p_batch_step_id is required';
  end if;

  v_tenant := public._assert_tenant();
  v_actor_user_id := auth.uid();
  p_rows := coalesce(p_rows, '[]'::jsonb);

  if jsonb_typeof(p_rows) <> 'array' then
    raise exception 'BSEA002: p_rows must be a JSON array';
  end if;

  select s.batch_id
    into v_batch_id
  from mes.batch_step s
  where s.tenant_id = v_tenant
    and s.id = p_batch_step_id
  for update of s;

  if v_batch_id is null then
    raise exception 'BSEA003: batch step not found';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(p_rows) as elem(value)
    where jsonb_typeof(elem.value) <> 'object'
  ) then
    raise exception 'BSEA004: each equipment assignment row must be a JSON object';
  end if;

  drop table if exists pg_temp.batch_step_equipment_assignment_input;
  create temporary table batch_step_equipment_assignment_input (
    sort_order integer not null,
    id uuid null,
    equipment_id uuid null,
    reservation_id uuid null,
    assignment_role_text text null,
    status_text text null,
    assigned_at timestamptz null,
    released_at timestamptz null,
    note text null,
    snapshot_json jsonb not null default '{}'::jsonb
  ) on commit drop;

  insert into batch_step_equipment_assignment_input (
    sort_order,
    id,
    equipment_id,
    reservation_id,
    assignment_role_text,
    status_text,
    assigned_at,
    released_at,
    note,
    snapshot_json
  )
  select
    elem.ord::integer,
    nullif(btrim(coalesce(elem.value ->> 'id', '')), '')::uuid,
    nullif(btrim(coalesce(elem.value ->> 'equipment_id', '')), '')::uuid,
    nullif(btrim(coalesce(elem.value ->> 'reservation_id', '')), '')::uuid,
    lower(nullif(btrim(coalesce(elem.value ->> 'assignment_role', '')), '')),
    lower(nullif(btrim(coalesce(elem.value ->> 'status', '')), '')),
    nullif(btrim(coalesce(elem.value ->> 'assigned_at', '')), '')::timestamptz,
    nullif(btrim(coalesce(elem.value ->> 'released_at', '')), '')::timestamptz,
    nullif(btrim(coalesce(elem.value ->> 'note', '')), ''),
    case
      when elem.value ? 'snapshot_json' then elem.value -> 'snapshot_json'
      else '{}'::jsonb
    end
  from jsonb_array_elements(p_rows) with ordinality as elem(value, ord);

  if exists (
    select 1
    from batch_step_equipment_assignment_input
    where equipment_id is null
  ) then
    raise exception 'BSEA005: equipment_id is required';
  end if;

  if exists (
    select 1
    from batch_step_equipment_assignment_input
    where assigned_at is null
  ) then
    raise exception 'BSEA006: assigned_at is required';
  end if;

  if exists (
    select 1
    from batch_step_equipment_assignment_input
    where jsonb_typeof(snapshot_json) <> 'object'
  ) then
    raise exception 'BSEA007: snapshot_json must be a JSON object';
  end if;

  if exists (
    select 1
    from batch_step_equipment_assignment_input
    where assignment_role_text is not null
      and assignment_role_text not in ('main', 'aux', 'qc', 'cleaning')
  ) then
    raise exception 'BSEA008: assignment_role must be main, aux, qc, or cleaning';
  end if;

  if exists (
    select 1
    from batch_step_equipment_assignment_input
    where status_text is not null
      and status_text not in ('assigned', 'in_use', 'done', 'cancelled')
  ) then
    raise exception 'BSEA009: status must be assigned, in_use, done, or cancelled';
  end if;

  if exists (
    select 1
    from batch_step_equipment_assignment_input
    where released_at is not null
      and assigned_at > released_at
  ) then
    raise exception 'BSEA010: assigned_at must be earlier than or equal to released_at';
  end if;

  if exists (
    select 1
    from (
      select id
      from batch_step_equipment_assignment_input
      where id is not null
      group by id
      having count(*) > 1
    ) duplicated
  ) then
    raise exception 'BSEA011: duplicate assignment ids are not allowed';
  end if;

  if exists (
    select 1
    from (
      select reservation_id
      from batch_step_equipment_assignment_input
      where reservation_id is not null
      group by reservation_id
      having count(*) > 1
    ) duplicated
  ) then
    raise exception 'BSEA012: duplicate reservation links are not allowed';
  end if;

  if exists (
    select 1
    from batch_step_equipment_assignment_input i
    left join mes.batch_equipment_assignment existing
      on existing.tenant_id = v_tenant
     and existing.batch_step_id = p_batch_step_id
     and existing.id = i.id
    where i.id is not null
      and existing.id is null
  ) then
    raise exception 'BSEA013: assignment id does not belong to the selected batch step';
  end if;

  if exists (
    with normalized as (
      select
        sort_order,
        equipment_id,
        coalesce(status_text, 'assigned') as status_text,
        assigned_at,
        coalesce(released_at, 'infinity'::timestamptz) as released_at
      from batch_step_equipment_assignment_input
    )
    select 1
    from normalized left_row
    join normalized right_row
      on left_row.sort_order < right_row.sort_order
     and left_row.equipment_id = right_row.equipment_id
    where left_row.status_text <> 'cancelled'
      and right_row.status_text <> 'cancelled'
      and tstzrange(left_row.assigned_at, left_row.released_at, '[]')
          && tstzrange(right_row.assigned_at, right_row.released_at, '[]')
  ) then
    raise exception 'BSEA014: equipment assignment windows overlap within the same save payload';
  end if;

  if exists (
    with normalized as (
      select
        equipment_id,
        coalesce(status_text, 'assigned') as status_text,
        assigned_at,
        coalesce(released_at, 'infinity'::timestamptz) as released_at
      from batch_step_equipment_assignment_input
    )
    select 1
    from normalized input_row
    join mes.batch_equipment_assignment existing
      on existing.tenant_id = v_tenant
     and existing.equipment_id = input_row.equipment_id
     and existing.batch_step_id is distinct from p_batch_step_id
     and existing.status::text <> 'cancelled'
     and tstzrange(existing.assigned_at, coalesce(existing.released_at, 'infinity'::timestamptz), '[]')
         && tstzrange(input_row.assigned_at, input_row.released_at, '[]')
    where input_row.status_text <> 'cancelled'
  ) then
    raise exception 'BSEA015: equipment assignment overlaps with existing actual usage';
  end if;

  delete from mes.batch_equipment_assignment assignment_row
  where assignment_row.tenant_id = v_tenant
    and assignment_row.batch_step_id = p_batch_step_id
    and not exists (
      select 1
      from batch_step_equipment_assignment_input input_row
      where input_row.id = assignment_row.id
    );

  update mes.batch_equipment_assignment assignment_row
     set reservation_id = input_row.reservation_id,
         equipment_id = input_row.equipment_id,
         assignment_role = case
           when input_row.assignment_role_text is null then null
           else input_row.assignment_role_text::mes.equipment_assignment_role
         end,
         status = coalesce(input_row.status_text, 'assigned')::mes.batch_equipment_assignment_status,
         assigned_at = input_row.assigned_at,
         released_at = input_row.released_at,
         snapshot_json = input_row.snapshot_json,
         note = input_row.note,
         updated_by = v_actor_user_id
    from batch_step_equipment_assignment_input input_row
   where assignment_row.tenant_id = v_tenant
     and assignment_row.batch_step_id = p_batch_step_id
     and assignment_row.id = input_row.id;

  insert into mes.batch_equipment_assignment (
    tenant_id,
    batch_id,
    batch_step_id,
    reservation_id,
    equipment_id,
    assignment_role,
    status,
    assigned_at,
    released_at,
    snapshot_json,
    note,
    created_by,
    updated_by
  )
  select
    v_tenant,
    v_batch_id,
    p_batch_step_id,
    input_row.reservation_id,
    input_row.equipment_id,
    case
      when input_row.assignment_role_text is null then null
      else input_row.assignment_role_text::mes.equipment_assignment_role
    end,
    coalesce(input_row.status_text, 'assigned')::mes.batch_equipment_assignment_status,
    input_row.assigned_at,
    input_row.released_at,
    input_row.snapshot_json,
    input_row.note,
    v_actor_user_id,
    v_actor_user_id
  from batch_step_equipment_assignment_input input_row
  where input_row.id is null;

  select count(*)
    into v_saved_count
  from batch_step_equipment_assignment_input;

  return jsonb_build_object(
    'batch_step_id', p_batch_step_id,
    'saved_count', v_saved_count
  );
end;
$$;
comment on function public.batch_step_save_equipment_assignments(uuid, jsonb) is '{"version":1}';
