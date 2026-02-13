# `public._assert_non_negative_lot_qty(p_lot_id uuid) returns void`

## Purpose
Enforce non-negative lot balance after updates.

## Input Contract
- Required: `p_lot_id`.

## Validation
- Lot exists.

## Data Access
- Read: `lot.qty`.

## Behavior
- Raise exception when `qty < 0`.

## Output
- None.

## Errors
- Lot not found.
- Negative quantity.
