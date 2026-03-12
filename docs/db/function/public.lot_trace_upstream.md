# `public.lot_trace_upstream(p_lot_id uuid) returns table (...)`

## Purpose
Trace upstream genealogy (source lots/events/movements).

## Input Contract
- Required: `p_lot_id`.

## Validation
- Lot exists.

## Data Access
- Read: `lot`, `inv_movements`, `lot_edge`, `mes_batch_relation`.

## Behavior
- Trace toward origin lots via `lot_edge.to_lot_id = p_lot_id`.
- Also include upstream batch relations via `mes_batch_relation`.
- Emit one row per discovered edge with depth.

## Output
- Edge rows from signature.

## Errors
- Lot not found.
- Recursion safety guard exceeded (if configured).
