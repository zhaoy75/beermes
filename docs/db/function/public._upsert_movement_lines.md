# `public._upsert_movement_lines(p_movement_id uuid, p_lines jsonb) returns void`

## Purpose
Replace or merge movement lines for a movement header.

## Input Contract
- Required: `p_movement_id`, `p_lines[]`.

## Validation
- Header exists.
- `line_no` unique.
- Item identity constraint satisfied (`material_id` or `package_id`).

## Data Access
- Write: `inv_movement_lines`.

## Behavior
- Delete missing lines and upsert provided lines.
- Maintain tenant consistency with header.

## Output
- None.

## Errors
- Header not found.
- Duplicate line numbers.
