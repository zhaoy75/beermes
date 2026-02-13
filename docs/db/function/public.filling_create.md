# `public.filling_create(p_doc jsonb) returns uuid`

## Purpose
Register filling/packaging movement and linked lot event.

## Input Contract
- Required: movement header fields and `lines[]`.
- Expected meta: `movement_intent = PACKAGE_FILL`.

## Validation
- At least one line.
- Each line has `qty > 0` and valid item identity.
- Source/destination site consistency.

## Data Access
- Write: `inv_movements`, `inv_movement_lines`, `lot_event`, `lot_event_line`.
- Update: `lot` qty/balance according to rules.

## Behavior
- Create movement header+lines.
- Create lot event header+lines and link via `inv_movements.lot_event_id`.
- Apply quantity effects atomically.

## Output
- Return `movement_id`.

## Errors
- Invalid line payload.
- Negative balance after apply.
