# `public._apply_inventory_delta(p_lines jsonb, p_direction text) returns void`

## Purpose
Apply inventory quantity change from movement lines.

## Input Contract
- Required: `p_lines` array and `p_direction` (`apply` or `reverse`).

## Validation
- Every line has item id/site/uom/qty.
- `qty > 0`.

## Data Access
- Write: `inv_inventory` (upsert/update).

## Behavior
- Convert line impacts into signed deltas.
- Upsert inventory rows by tenant/site/item/uom/batch.

## Output
- None.

## Errors
- Invalid line structure.
- Negative inventory constraint violation (if enforced).
