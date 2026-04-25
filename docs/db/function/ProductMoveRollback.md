# `public.product_move_rollback(p_doc jsonb) returns uuid`

## Purpose
Rollback a previously posted `product_move` transaction by posting a compensating adjustment movement, reversing lot/inventory balances, and voiding the original movement.

## Business Meaning
- Rollback is compensation, not physical delete.
- `movement_save(status='void')` must not be used for `移入出登録` cancellation because it only changes the movement header.
- After successful rollback:
  - source lot quantity is restored
  - source inventory is restored except for `RETURN_FROM_CUSTOMER`
  - destination lot/inventory is reduced when the original move created a destination lot
  - original movement is marked `void`

## Tables Affected
- Write: `public.inv_movements` rollback adjustment header
- Write: `public.inv_movement_lines` rollback lines
- Update/insert: `public.inv_inventory`
- Update: `public.lot`
- Update: `public.inv_movements` original movement status/meta

## Input Contract (`p_doc`)
Required fields:
- `doc_no` text: rollback business document number
- `product_movement_id` uuid: target movement id created by `product_move`

Optional fields:
- `movement_at` timestamptz: rollback timestamp, defaults to `now()`
- `reason` text
- `notes` text
- `meta` jsonb
- `movement_id` uuid: accepted as a backward-compatible alias for `product_movement_id`

Optional idempotency:
- `meta.idempotency_key` text

## Validation
- Tenant exists via `public._assert_tenant()`.
- `doc_no` and target movement id are present.
- `inv_doc_type` supports `adjustment`.
- Target movement exists, is tenant-visible, and `status = posted`.
- Target movement is not already reversed.
- Rollback timestamp must not be before the target movement timestamp.
- Target movement must be a `product_move` movement, not produce, filling, unpacking, or rollback.
- Target movement must have at least one source `lot_edge`.
- `tax_report_mark_stale_for_movement(target)` must run before mutation:
  - submitted/approved report refs block rollback
  - draft report refs become `stale`
- Destination lots must not have downstream non-void movement usage.
- Destination lot and inventory must have enough quantity to subtract.

## Transaction Behavior
1. Lock the target movement.
2. Validate target movement status/type and tax-report lock state.
3. Lock and validate source and destination lots/inventory.
4. Reject rollback when destination lots have downstream non-void use.
5. Insert a posted adjustment movement with `movement_intent = PRODUCT_MOVE_ROLLBACK`.
6. Insert rollback movement lines.
7. Do not insert rollback `lot_edge` rows:
   - rollback audit is stored on the adjustment movement lines.
   - adding incoming rollback edges to existing source lots would change `lot_effective_created_at` and break chronology checks.
8. Reverse inventory:
   - decrement destination inventory when destination lot exists
   - restore source inventory except for `RETURN_FROM_CUSTOMER`
9. Reverse lot balances:
   - decrement destination lot
   - increment source lot and reactivate it when it was consumed
10. Mark the original movement `void` and set `meta.reversed_by_movement_id`.
11. Return rollback movement id.

## Error Codes
- `PMR001`: missing rollback input
- `PMR002`: target product movement not found
- `PMR003`: target movement is not eligible for rollback
- `PMR004`: required lot graph data is missing or inconsistent
- `PMR005`: rollback blocked by downstream movements
- `PMR006`: destination/source lot or inventory quantity is insufficient
- `PMR007`: duplicate rollback `doc_no`
