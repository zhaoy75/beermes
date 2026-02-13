# `public.movement_get_detail(p_movement_id uuid) returns jsonb`

## Purpose
Return full movement detail for view/edit screen.

## Input Contract
- Required: `p_movement_id`.

## Validation
- Movement must exist.

## Data Access
- Read: `inv_movements`, `inv_movement_lines`, `mst_sites`, `lot_event`.

## Behavior
- Join header and lines.
- Include site display info and linked `lot_event_id`.

## Output
- JSON object: `{header, lines, sites, lot_event}`.

## Errors
- Movement not found.
