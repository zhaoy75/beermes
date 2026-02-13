# `public.lot_trace_upstream(p_lot_id uuid) returns table (...)`

## Purpose
Trace upstream genealogy (source lots/events/movements).

## Input Contract
- Required: `p_lot_id`.

## Validation
- Lot exists.

## Data Access
- Read: `lot`, `lot_event`, `lot_event_line`, `inv_movements`, `inv_movement_lines`, `mes_batch_relation`.

## Behavior
- Recursive traversal toward origin.
- Emit one row per discovered edge with depth.

## Output
- Edge rows from signature.

## Errors
- Lot not found.
- Recursion safety guard exceeded (if configured).
