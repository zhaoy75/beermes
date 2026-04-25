# `public.movement_save(p_movement_id uuid, p_doc jsonb) returns uuid`

## Purpose
Update movement header/lines and status.

## Input Contract
- Required: `p_movement_id`.
- Optional patch keys: `status`, `movement_at`, `reason`, `meta`, `lines`.

## Validation
- Movement exists.
- Line payload valid if provided.
- Status transition allowed (`open|posted|void`).

## Data Access
- Write: `inv_movements`, `inv_movement_lines`.

## Behavior
- Patch header.
- If `lines` present, use `_upsert_movement_lines`.
- Does not apply product lot/inventory rollback deltas.
- Product movement cancellation must call `product_move_rollback` instead of setting `status = void` here.

## Output
- Return `p_movement_id`.

## Errors
- Movement not found.
- Invalid transition.
