create or replace function public.lot_effective_created_at(p_lot_id uuid)
returns timestamptz
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_created_at timestamptz;
  v_produce_movement_at timestamptz;
begin
  if p_lot_id is null then
    raise exception 'LOT_TIME001: p_lot_id is required';
  end if;

  v_tenant := public._assert_tenant();

  select min(m.movement_at)
    into v_produce_movement_at
  from public.lot_edge e
  join public.inv_movements m
    on m.id = e.movement_id
   and m.tenant_id = e.tenant_id
  where e.tenant_id = v_tenant
    and e.to_lot_id = p_lot_id
    and coalesce(m.status, '') <> 'void';

  select coalesce(b.actual_start, v_produce_movement_at, l.produced_at, l.created_at)
    into v_created_at
  from public.lot l
  left join public.mes_batches b
    on b.tenant_id = l.tenant_id
   and b.id = l.batch_id
  where l.tenant_id = v_tenant
    and l.id = p_lot_id;

  if v_created_at is null then
    raise exception 'LOT_TIME002: lot not found: %', p_lot_id;
  end if;

  return v_created_at;
end;
$$;

create or replace function public._assert_source_lot_not_after_movement(
  p_movement_at timestamptz,
  p_source_lot_ids uuid[],
  p_context text default null
)
returns void
language plpgsql
security invoker
as $$
declare
  v_tenant uuid;
  v_lot_id uuid;
  v_lot_no text;
  v_created_at timestamptz;
begin
  if p_movement_at is null then
    raise exception 'LOT_TIME003: movement_at is required';
  end if;

  if p_source_lot_ids is null or coalesce(array_length(p_source_lot_ids, 1), 0) = 0 then
    return;
  end if;

  v_tenant := public._assert_tenant();

  for v_lot_id in
    select distinct id
    from unnest(p_source_lot_ids) as ids(id)
    where id is not null
  loop
    select l.lot_no
      into v_lot_no
    from public.lot l
    where l.tenant_id = v_tenant
      and l.id = v_lot_id;

    if v_lot_no is null then
      raise exception 'LOT_TIME002: lot not found: %', v_lot_id;
    end if;

    v_created_at := public.lot_effective_created_at(v_lot_id);

    if date_trunc('minute', v_created_at) > date_trunc('minute', p_movement_at) then
      raise exception
        'LOT_TIME004: movement_at % is before source lot % creation time % (context=%)',
        p_movement_at,
        v_lot_no,
        v_created_at,
        coalesce(p_context, '');
    end if;
  end loop;
end;
$$;

create or replace function public.trg_lot_edge_source_chronology()
returns trigger
language plpgsql
security invoker
as $$
declare
  v_movement_at timestamptz;
  v_status text;
begin
  if new.from_lot_id is null then
    return new;
  end if;

  select m.movement_at, m.status
    into v_movement_at, v_status
  from public.inv_movements m
  where m.tenant_id = new.tenant_id
    and m.id = new.movement_id;

  if v_movement_at is null then
    raise exception 'LOT_TIME005: movement not found for lot_edge: %', new.movement_id;
  end if;

  if coalesce(v_status, '') = 'void' then
    return new;
  end if;

  perform public._assert_source_lot_not_after_movement(
    v_movement_at,
    array[new.from_lot_id],
    'lot_edge'
  );

  return new;
end;
$$;

drop trigger if exists trg_lot_edge_source_chronology on public.lot_edge;
create trigger trg_lot_edge_source_chronology
before insert or update of movement_id, from_lot_id
on public.lot_edge
for each row execute function public.trg_lot_edge_source_chronology();

create or replace function public.trg_inv_movement_line_source_chronology()
returns trigger
language plpgsql
security invoker
as $$
declare
  v_movement_at timestamptz;
  v_src_site_id uuid;
  v_status text;
  v_lot_ids uuid[] := '{}'::uuid[];
  v_key text;
  v_value text;
begin
  if new.meta is null then
    return new;
  end if;

  select m.movement_at, m.src_site_id, m.status
    into v_movement_at, v_src_site_id, v_status
  from public.inv_movements m
  where m.tenant_id = new.tenant_id
    and m.id = new.movement_id;

  if v_movement_at is null then
    raise exception 'LOT_TIME005: movement not found for movement line: %', new.movement_id;
  end if;

  if coalesce(v_status, '') = 'void' or v_src_site_id is null then
    return new;
  end if;

  foreach v_key in array array['src_lot_id', 'source_lot_id', 'lot_id']
  loop
    v_value := nullif(btrim(coalesce(new.meta ->> v_key, '')), '');
    if v_value ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      v_lot_ids := array_append(v_lot_ids, v_value::uuid);
    end if;
  end loop;

  perform public._assert_source_lot_not_after_movement(
    v_movement_at,
    v_lot_ids,
    'inv_movement_lines'
  );

  return new;
end;
$$;

drop trigger if exists trg_inv_movement_line_source_chronology on public.inv_movement_lines;
create trigger trg_inv_movement_line_source_chronology
before insert or update of movement_id, meta
on public.inv_movement_lines
for each row execute function public.trg_inv_movement_line_source_chronology();

create or replace function public.trg_inv_movement_chronology_update()
returns trigger
language plpgsql
security invoker
as $$
declare
  v_source_lot_ids uuid[] := '{}'::uuid[];
  v_downstream record;
begin
  if new.movement_at is distinct from old.movement_at
     or coalesce(new.status, '') is distinct from coalesce(old.status, '')
     or new.src_site_id is distinct from old.src_site_id then
    if coalesce(new.status, '') <> 'void' then
      with edge_sources as (
        select e.from_lot_id as lot_id
        from public.lot_edge e
        where e.tenant_id = new.tenant_id
          and e.movement_id = new.id
          and e.from_lot_id is not null
      ),
      line_sources as (
        select value::uuid as lot_id
        from public.inv_movement_lines l
        cross join lateral (
          values
            (l.meta ->> 'src_lot_id'),
            (l.meta ->> 'source_lot_id'),
            (l.meta ->> 'lot_id')
        ) as candidates(value)
        where l.tenant_id = new.tenant_id
          and l.movement_id = new.id
          and new.src_site_id is not null
          and candidates.value ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      )
      select coalesce(array_agg(distinct lot_id), '{}'::uuid[])
        into v_source_lot_ids
      from (
        select lot_id from edge_sources
        union all
        select lot_id from line_sources
      ) s;

      perform public._assert_source_lot_not_after_movement(
        new.movement_at,
        v_source_lot_ids,
        'inv_movements_update'
      );
    end if;

    for v_downstream in
      with created_lots as (
        select e.to_lot_id as lot_id
        from public.lot_edge e
        where e.tenant_id = new.tenant_id
          and e.movement_id = new.id
          and e.to_lot_id is not null
      ),
      downstream_edges as (
        select m.id as movement_id, m.movement_at, l.lot_no
        from created_lots cl
        join public.lot_edge e
          on e.tenant_id = new.tenant_id
         and e.from_lot_id = cl.lot_id
         and e.movement_id <> new.id
        join public.inv_movements m
          on m.tenant_id = e.tenant_id
         and m.id = e.movement_id
         and coalesce(m.status, '') <> 'void'
        join public.lot l
          on l.tenant_id = new.tenant_id
         and l.id = cl.lot_id
      ),
      downstream_lines as (
        select m.id as movement_id, m.movement_at, lot.lot_no
        from created_lots cl
        join public.lot lot
          on lot.tenant_id = new.tenant_id
         and lot.id = cl.lot_id
        join public.inv_movement_lines line
          on line.tenant_id = new.tenant_id
         and line.movement_id <> new.id
        join public.inv_movements m
          on m.tenant_id = line.tenant_id
         and m.id = line.movement_id
         and coalesce(m.status, '') <> 'void'
         and m.src_site_id is not null
        where line.meta ->> 'src_lot_id' = cl.lot_id::text
           or line.meta ->> 'source_lot_id' = cl.lot_id::text
           or line.meta ->> 'lot_id' = cl.lot_id::text
      )
      select *
      from (
        select * from downstream_edges
        union all
        select * from downstream_lines
      ) d
      where d.movement_at < new.movement_at
      order by d.movement_at, d.movement_id
      limit 1
    loop
      raise exception
        'LOT_TIME006: movement_at % is after downstream movement % at % for created lot %',
        new.movement_at,
        v_downstream.movement_id,
        v_downstream.movement_at,
        v_downstream.lot_no;
    end loop;
  end if;

  return new;
end;
$$;

drop trigger if exists trg_inv_movement_chronology_update on public.inv_movements;
create trigger trg_inv_movement_chronology_update
before update of movement_at, status, src_site_id
on public.inv_movements
for each row execute function public.trg_inv_movement_chronology_update();
