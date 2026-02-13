# `public.lot_trace_full(p_lot_id uuid, p_max_depth int default 10) returns jsonb`

## Purpose
Return full lot genealogy graph as UI-friendly JSON.

## Input Contract
- Required: `p_lot_id`.
- Optional: `p_max_depth` default `10`.

## Validation
- `p_max_depth > 0` and bounded.

## Data Access
- Read: same sources as upstream/downstream trace functions.

## Behavior
- Build recursive graph both directions.
- Deduplicate nodes/edges.

## Output
- JSON object: `{root_lot_id, nodes[], edges[]}`.

## Errors
- Invalid `p_max_depth`.
- Lot not found.
