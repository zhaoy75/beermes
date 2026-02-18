# `public.product_produce_rollback(p_doc jsonb) returns uuid`

## Purpose
Rollback a previously posted produce transaction when input was wrong, by posting a compensating movement that consumes the produced lot and voiding the original produce movement.

## Business Meaning
- Rollback is **compensation**, not physical delete.
- Preserve full audit and lot lineage:
  - original edge: `PRODUCE` (`NULL -> produced_lot`)
  - rollback edge: `CONSUME` (`produced_lot -> NULL`)
- After successful rollback:
  - produced lot quantity becomes `0`
  - produced lot is no longer usable for downstream operations
  - original produce movement is marked `void`

## Tables Affected
- Write: `public.inv_movements` (rollback movement header)
- Write: `public.inv_movement_lines` (rollback movement line)
- Write: `public.lot_edge` (rollback `CONSUME` edge)
- Update: `public.inv_inventory` (decrement produced lot stock)
- Update: `public.lot` (decrement qty; set status)
- Update: `public.inv_movements` (original produce movement -> `void`)

## Function Signature
```sql
create or replace function public.product_produce_rollback(p_doc jsonb)
returns uuid
language plpgsql
security invoker;
```

## Input Contract (`p_doc`)
Required fields:
- `doc_no` text: rollback business document number (tenant unique)
- `produce_movement_id` uuid: target movement id created by `product_produce`

Optional fields:
- `movement_at` timestamptz: rollback timestamp (defaults to `now()`)
- `reason` text
- `notes` text
- `meta` jsonb

Optional idempotency:
- `meta.idempotency_key` text

## Fixed/Derived Values
- Rollback movement:
  - `inv_movements.doc_type = 'adjustment'`
  - `inv_movements.status = 'posted'`
  - `inv_movements.src_site_id = produced_lot.site_id`
  - `inv_movements.dest_site_id = NULL`
- Rollback movement line:
  - `line_no = 1`
  - `material_id = '00000000-0000-0000-0000-000000000000'::uuid`
  - `qty = produced_lot.remaining_qty` at rollback time
  - `uom_id = produced_lot.uom_id`
- Rollback edge:
  - `edge_type = 'CONSUME'`
  - `from_lot_id = produced_lot_id`
  - `to_lot_id = NULL`

## Validation
- Tenant exists via `public._assert_tenant()`.
- `doc_no`, `produce_movement_id` are present.
- `inv_doc_type` supports `adjustment`.
- Target produce movement exists, tenant-visible, and `status = 'posted'`.
- Target movement is a produce transaction:
  - `meta.movement_intent = 'BREW_PRODUCE'`.
- Target movement must not already contain `meta.reversed_by_movement_id`.
- Produced lot and produce edge (`edge_type = 'PRODUCE'`, `from_lot_id IS NULL`) exist for the target movement.
- Produced lot site is resolved from lot site, or fallback to target movement destination/source site.
- Produced lot has enough inventory to rollback the current lot qty.
- No active downstream dependency exists:
  - there must be no non-void movement with `lot_edge.from_lot_id = produced_lot_id`.
- `doc_no` unique per tenant for rollback movement.

## Transaction Behavior (Atomic)
1. Resolve tenant id (`v_tenant`) and normalize payload.
2. Lock target movement (`produce_movement_id`) `FOR UPDATE`.
3. Resolve and lock produced lot row and produced inventory row `FOR UPDATE`.
4. Check downstream usage:
   - if any non-void movement has `lot_edge.from_lot_id = produced_lot_id`, reject rollback.
5. Compute rollback qty = current produced lot qty (`lot.qty`, must be `> 0`).
6. Insert rollback movement (`inv_movements`) with `doc_type='adjustment'`, `status='posted'`, and rollback metadata:
   - `movement_intent = 'BREW_PRODUCE_ROLLBACK'`
   - `rollback_of_movement_id = produce_movement_id`
   - `rollback_of_lot_id = produced_lot_id`
7. Insert one rollback movement line (`inv_movement_lines`) for rollback qty.
8. Insert one rollback `lot_edge` row (`CONSUME`) tied to rollback movement/line.
9. Decrement inventory for produced lot (`inv_inventory.qty -= rollback_qty`).
10. Decrement lot qty and close lot:
    - `lot.qty -= rollback_qty` (expected to become `0`)
    - `lot.status = 'void'` when remaining qty is `<= 0`
11. Mark original produce movement as void:
    - `inv_movements.status = 'void'`
    - `reason/notes` are updated when provided
    - append metadata: `voided_at`, `void_reason`, `reversed_by_movement_id`
12. Return rollback movement id.

## Suggested Return
Return `rollback_movement_id uuid`.

## Suggested Error Codes
- `PPR001`: missing required field
- `PPR002`: target produce movement not found
- `PPR003`: target movement is not an eligible posted produce movement
- `PPR004`: produced lot/edge not found for target movement
- `PPR005`: rollback blocked by downstream movements (reverse children first)
- `PPR006`: insufficient produced lot/inventory quantity for rollback
- `PPR007`: duplicate rollback `doc_no`

## Idempotency Recommendation
Support optional `meta.idempotency_key`:
- unique per tenant
- if repeated, return existing rollback movement id where:
  - `doc_type = adjustment`
  - `meta.movement_intent = BREW_PRODUCE_ROLLBACK`

## Example Input
```json
{
  "doc_no": "PPR-20260218-0001",
  "movement_at": "2026-02-18T11:00:00Z",
  "produce_movement_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "reason": "Wrong produced qty input",
  "notes": "Rollback and re-enter correct value",
  "meta": {
    "idempotency_key": "produce_rollback:aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa:001"
  }
}
```

## Notes
- This specification intentionally avoids delete/truncate for business rollback.
- If downstream filling/transfer already exists, rollback must be executed in reverse dependency order (child first, then parent produce).
- Keep lot DAG query behavior consistent by excluding void movements/lots in read models where needed.
