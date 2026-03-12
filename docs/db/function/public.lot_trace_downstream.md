# `public.lot_trace_downstream(p_lot_id uuid) returns table (...)`

## Purpose
Trace downstream genealogy (consumption/split/shipment).

## Input Contract
- Required: `p_lot_id`.

## Validation
- Lot exists.

## Data Access
- Read: `lot`, `inv_movements`, `lot_edge`, `mes_batch_relation`.

## Behavior
- Trace toward descendant lots via `lot_edge.from_lot_id = p_lot_id`.
- Also include downstream batch relations via `mes_batch_relation`.
- Emit one row per discovered edge with depth.

## Output
- Edge rows from signature.

## Errors
- Lot not found.
- Recursion safety guard exceeded (if configured).
