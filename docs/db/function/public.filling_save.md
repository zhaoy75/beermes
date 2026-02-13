# `public.filling_save(p_movement_id uuid, p_doc jsonb) returns uuid`

## Purpose
Edit, repost, or void a filling record.

## Input Contract
- Required: `p_movement_id`.
- Optional: header fields, `lines[]`, target `status`.

## Validation
- Movement exists and is fill-related.
- Status transition is allowed.

## Data Access
- Write: `inv_movements`, `inv_movement_lines`, `lot_event`, `lot_event_line`.
- Update: `lot` for quantity reversal/reapply when lines changed.

## Behavior
- If lines/status changed, reverse previous impact then apply new impact.

## Output
- Return `p_movement_id`.

## Errors
- Movement not found.
- Invalid status transition.
