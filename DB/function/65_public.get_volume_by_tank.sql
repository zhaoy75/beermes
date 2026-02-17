create or replace function public.get_volume_by_tank(
  p_tank_id uuid,
  p_depth_mm numeric,
  p_temperature_c numeric
)
returns numeric
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_calibration jsonb;

  v_ref_temp numeric := 20;
  v_alpha numeric := 0;

  v_depths numeric[] := '{}'::numeric[];
  v_volumes numeric[] := '{}'::numeric[];
  v_h numeric[];
  v_delta numeric[];
  v_m numeric[];

  v_n int;
  i int;
  v_idx int;

  v_point jsonb;
  v_depth_txt text;
  v_volume_txt text;
  v_depth_value numeric;
  v_volume_value numeric;

  v_h_i numeric;
  v_t numeric;
  v_h00 numeric;
  v_h10 numeric;
  v_h01 numeric;
  v_h11 numeric;
  v_ref_volume numeric;
  v_temp_volume numeric;
begin
  if p_tank_id is null then
    raise exception 'p_tank_id is required';
  end if;

  if p_depth_mm is null then
    raise exception 'p_depth_mm is required';
  end if;

  if p_temperature_c is null then
    raise exception 'p_temperature_c is required';
  end if;

  if p_depth_mm < 0 then
    raise exception 'p_depth_mm must be >= 0';
  end if;

  v_tenant := public._assert_tenant();

  select t.calibration_table
    into v_calibration
  from public.mst_equipment_tank t
  join public.mst_equipment e
    on e.id = t.equipment_id
  where t.equipment_id = p_tank_id
    and e.tenant_id = v_tenant
  limit 1;

  if v_calibration is null then
    raise exception 'tank not found or calibration_table is null';
  end if;

  if jsonb_typeof(v_calibration) <> 'object' then
    raise exception 'calibration_table must be a JSON object';
  end if;

  if not (v_calibration ? 'points') then
    raise exception 'calibration_table.points is required';
  end if;

  if jsonb_typeof(v_calibration -> 'points') <> 'array' then
    raise exception 'calibration_table.points must be an array';
  end if;

  if jsonb_array_length(v_calibration -> 'points') < 2 then
    raise exception 'calibration_table.points must have at least 2 rows';
  end if;

  if coalesce(nullif(btrim(v_calibration ->> 'reference_temperature_c'), ''), '') <> '' then
    begin
      v_ref_temp := (v_calibration ->> 'reference_temperature_c')::numeric;
    exception
      when others then
        raise exception 'calibration_table.reference_temperature_c must be numeric';
    end;
  end if;

  if coalesce(nullif(btrim(v_calibration ->> 'thermal_expansion_coef_per_c'), ''), '') <> '' then
    begin
      v_alpha := (v_calibration ->> 'thermal_expansion_coef_per_c')::numeric;
    exception
      when others then
        raise exception 'calibration_table.thermal_expansion_coef_per_c must be numeric';
    end;
  end if;

  for v_point in
    select value
    from jsonb_array_elements(v_calibration -> 'points')
  loop
    v_depth_txt := btrim(coalesce(v_point ->> 'depth_mm', ''));
    v_volume_txt := btrim(coalesce(v_point ->> 'volume_l', ''));

    if v_depth_txt = '' or v_volume_txt = '' then
      raise exception 'each calibration point must contain depth_mm and volume_l';
    end if;

    begin
      v_depth_value := v_depth_txt::numeric;
    exception
      when others then
        raise exception 'depth_mm must be numeric: %', v_depth_txt;
    end;

    begin
      v_volume_value := v_volume_txt::numeric;
    exception
      when others then
        raise exception 'volume_l must be numeric: %', v_volume_txt;
    end;

    v_depths := array_append(v_depths, v_depth_value);
    v_volumes := array_append(v_volumes, v_volume_value);
  end loop;

  select
    array_agg(u.depth_mm order by u.depth_mm, u.ord),
    array_agg(u.volume_l order by u.depth_mm, u.ord)
    into v_depths, v_volumes
  from unnest(v_depths, v_volumes) with ordinality as u(depth_mm, volume_l, ord);

  v_n := coalesce(array_length(v_depths, 1), 0);
  if v_n < 2 then
    raise exception 'calibration points are invalid';
  end if;

  for i in 1..v_n - 1 loop
    if v_depths[i + 1] <= v_depths[i] then
      raise exception 'depth_mm must be strictly increasing';
    end if;
    if v_volumes[i + 1] < v_volumes[i] then
      raise exception 'volume_l must be non-decreasing';
    end if;
  end loop;

  v_h := array_fill(0::numeric, array[v_n - 1]);
  v_delta := array_fill(0::numeric, array[v_n - 1]);
  v_m := array_fill(0::numeric, array[v_n]);

  for i in 1..v_n - 1 loop
    v_h[i] := v_depths[i + 1] - v_depths[i];
    if v_h[i] <= 0 then
      raise exception 'invalid calibration segment width';
    end if;
    v_delta[i] := (v_volumes[i + 1] - v_volumes[i]) / v_h[i];
  end loop;

  if v_n = 2 then
    v_m[1] := v_delta[1];
    v_m[2] := v_delta[1];
  else
    for i in 2..v_n - 1 loop
      if v_delta[i - 1] * v_delta[i] <= 0 then
        v_m[i] := 0;
      else
        v_m[i] := ((2 * v_h[i] + v_h[i - 1]) + (v_h[i] + 2 * v_h[i - 1]))
          / (((2 * v_h[i] + v_h[i - 1]) / v_delta[i - 1]) + ((v_h[i] + 2 * v_h[i - 1]) / v_delta[i]));
      end if;
    end loop;

    v_m[1] := ((2 * v_h[1] + v_h[2]) * v_delta[1] - v_h[1] * v_delta[2]) / (v_h[1] + v_h[2]);
    if v_m[1] * v_delta[1] <= 0 then
      v_m[1] := 0;
    elsif abs(v_m[1]) > 3 * abs(v_delta[1]) then
      v_m[1] := 3 * v_delta[1];
    end if;

    v_m[v_n] := ((2 * v_h[v_n - 1] + v_h[v_n - 2]) * v_delta[v_n - 1] - v_h[v_n - 1] * v_delta[v_n - 2]) / (v_h[v_n - 1] + v_h[v_n - 2]);
    if v_m[v_n] * v_delta[v_n - 1] <= 0 then
      v_m[v_n] := 0;
    elsif abs(v_m[v_n]) > 3 * abs(v_delta[v_n - 1]) then
      v_m[v_n] := 3 * v_delta[v_n - 1];
    end if;
  end if;

  if p_depth_mm <= v_depths[1] then
    v_ref_volume := v_volumes[1];
  elsif p_depth_mm >= v_depths[v_n] then
    v_ref_volume := v_volumes[v_n];
  else
    v_idx := 1;
    for i in 1..v_n - 1 loop
      if p_depth_mm >= v_depths[i] and p_depth_mm < v_depths[i + 1] then
        v_idx := i;
        exit;
      end if;
    end loop;

    v_h_i := v_depths[v_idx + 1] - v_depths[v_idx];
    v_t := (p_depth_mm - v_depths[v_idx]) / v_h_i;

    v_h00 := (2 * v_t * v_t * v_t) - (3 * v_t * v_t) + 1;
    v_h10 := (v_t * v_t * v_t) - (2 * v_t * v_t) + v_t;
    v_h01 := (-2 * v_t * v_t * v_t) + (3 * v_t * v_t);
    v_h11 := (v_t * v_t * v_t) - (v_t * v_t);

    v_ref_volume := (v_h00 * v_volumes[v_idx])
      + (v_h10 * v_h_i * v_m[v_idx])
      + (v_h01 * v_volumes[v_idx + 1])
      + (v_h11 * v_h_i * v_m[v_idx + 1]);
  end if;

  v_temp_volume := v_ref_volume * (1 + v_alpha * (p_temperature_c - v_ref_temp));
  return v_temp_volume;
end;
$$;
