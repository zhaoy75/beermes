# `public.get_volume_by_tank(p_tank_id uuid, p_depth_mm numeric, p_temperature_c numeric) returns numeric`

## Purpose
Return tank volume (L) from measured liquid depth (mm) and temperature (C).

The function reads tank calibration data from:
- table: `public.mst_equipment_tank`
- field: `calibration_table` (`jsonb`)

Interpolation method:
- Monotone cubic interpolation (Fritsch-Carlson / PCHIP-style slope limiter)

## Function Signature
```sql
create or replace function public.get_volume_by_tank(
  p_tank_id uuid,
  p_depth_mm numeric,
  p_temperature_c numeric
)
returns numeric
language plpgsql
stable
security invoker;
```

## Input Contract
- `p_tank_id`:
  - required
  - must exist in `mst_equipment_tank.equipment_id`
- `p_depth_mm`:
  - required
  - depth in millimeters
  - expected `>= 0`
- `p_temperature_c`:
  - not required
  - if not set, p_temperature_c will be set as default
  - measured liquid temperature in Celsius

## Calibration Table JSON Contract (`mst_equipment_tank.calibration_table`)
Recommended JSON format:

```json
{
  "version": 1,
  "reference_temperature_c": 20.0,
  "thermal_expansion_coef_per_c": 0.00021,
  "points": [
    { "depth_mm": 0, "volume_l": 0 },
    { "depth_mm": 100, "volume_l": 120.5 },
    { "depth_mm": 200, "volume_l": 245.2 }
  ]
}
```

Required keys:
- `points` (array, at least 2 rows)
- each point must contain:
  - `depth_mm` (numeric)
  - `volume_l` (numeric)

Optional keys:
- `reference_temperature_c` (numeric, default `20`)
- `thermal_expansion_coef_per_c` (numeric, default `0` if not provided)

## Validation Rules
1. `p_tank_id`, `p_depth_mm`, `p_temperature_c` are required.
2. `points` must be present and have at least 2 rows.
3. `depth_mm` values must be strictly increasing after sort.
4. `volume_l` values should be non-decreasing.
5. reject invalid JSON shape or non-numeric values.

## Interpolation Algorithm (Monotone Cubic)
Given sorted points `(x_i, y_i)` where:
- `x_i = depth_mm`
- `y_i = volume_l` at reference temperature

### 1) Segment lengths and secants
- `h_i = x_{i+1} - x_i`
- `delta_i = (y_{i+1} - y_i) / h_i`

### 2) Tangent slopes `m_i` (Fritsch-Carlson limiter)
- Interior slope (`1 <= i <= n-1`):
  - if `delta_{i-1} * delta_i <= 0` then `m_i = 0`
  - else:
    - `w1 = 2*h_i + h_{i-1}`
    - `w2 = h_i + 2*h_{i-1}`
    - `m_i = (w1 + w2) / (w1/delta_{i-1} + w2/delta_i)`
- End slopes (`m_0`, `m_n`) use one-sided estimates with monotonicity clamp:
  - if slope sign conflicts with first/last secant, set to `0`
  - if magnitude too large, clamp to `3 * secant`

### 3) Cubic Hermite interpolation inside segment `[x_i, x_{i+1}]`
- `t = (x - x_i) / h_i`
- basis:
  - `H00 = 2t^3 - 3t^2 + 1`
  - `H10 = t^3 - 2t^2 + t`
  - `H01 = -2t^3 + 3t^2`
  - `H11 = t^3 - t^2`
- interpolated reference volume:
  - `v_ref = H00*y_i + H10*h_i*m_i + H01*y_{i+1} + H11*h_i*m_{i+1}`

### 4) Out-of-range depth behavior
- Recommended: clamp to nearest endpoint volume
  - `x <= min(depth_mm)` => `v_ref = min(volume_l)`
  - `x >= max(depth_mm)` => `v_ref = max(volume_l)`

## Temperature Compensation
Base volume from calibration is interpreted at `reference_temperature_c`.

Let:
- `T_ref = calibration_table.reference_temperature_c` (default `20`)
- `alpha = calibration_table.thermal_expansion_coef_per_c` (default `0`)
- `T = p_temperature_c`

Then:
- `v_temp = v_ref * (1 + alpha * (T - T_ref))`

Return:
- `v_temp` (numeric, liters)

If no temperature settings exist:
- return `v_ref` unchanged.

## Data Access
- Read: `public.mst_equipment_tank`

## Output
- `numeric`: calculated volume in liters after temperature compensation.

## Error Cases
- tank not found
- calibration table missing/invalid
- calibration points invalid (insufficient, duplicate depth, non-numeric)
- required parameter is null

## Notes
- Use this function for filling screens where depth-based tank volume is needed.
- Keep `calibration_table.points` dense enough in curved tank regions for stable interpolation accuracy.
