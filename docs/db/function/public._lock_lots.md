# `public._lock_lots(p_lot_ids uuid[]) returns void`

## Purpose
Prevent race conditions during lot quantity updates.

## Input Contract
- Required: `p_lot_ids` non-empty array.

## Validation
- All IDs exist and tenant-visible.

## Data Access
- Read/lock: `lot` (`FOR UPDATE`).

## Behavior
- Acquire row locks in deterministic order.

## Output
- None.

## Errors
- Lot id not found.
- Lock timeout/deadlock.
