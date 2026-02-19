# `public.product_move(p_doc jsonb) returns uuid`

## Purpose
Register a product movement from one lot/site to another business destination using dynamic rules from `registry_def` and save inventory, movement, and lot lineage atomically.

## Rule Source
- Table: `public.registry_def`
- Selector:
  - `kind = 'ruleengine'`
  - `def_key = 'beer_movement_rule'`
  - `is_active = true`
- Scope priority:
  - tenant rule first (`scope='tenant' and owner_id=<tenant_id>`)
  - fallback to system rule (`scope='system'`)
- Source payload: `registry_def.spec` JSON.

## Function Signature
```sql
create or replace function public.product_move(p_doc jsonb)
returns uuid
language plpgsql
security invoker;
```

## Input Contract (`p_doc`)
Required fields:
- `movement_intent` text
- `src_site` uuid
- `dst_site` uuid
- `src_lot_id` uuid
- `qty` numeric (`> 0`)
- `uom_id` uuid
- `tax_decision_code` text

Recommended optional fields:
- `doc_no` text
- `movement_at` timestamptz (default `now()`)
- `reason` text
- `notes` text
- `meta` jsonb

## Validation (Rule Engine First)
1. Assert tenant context (`public._assert_tenant()`).
2. Load `beer_movement_rule` JSON from `registry_def`.
3. Validate input enums:
   - `movement_intent` in `spec.enums.movement_intent`
   - `tax_decision_code` in `spec.enums.tax_decision_code`
4. Resolve `src_site_type` and `dst_site_type` from site master mapping used by the rule engine.
5. Validate site-type allowance:
   - match `movement_intent_rules[*]`
   - `src_site_type` in `allowed_src_site_types`
   - `dst_site_type` in `allowed_dst_site_types`
6. Read lot (`src_lot_id`) to get `lot_tax_type`.
7. Resolve the matching row in `tax_transformation_rules` by:
   - `movement_intent`, `src_site_type`, `dst_site_type`, `lot_tax_type`
8. Validate `tax_decision_code` is in `allowed_tax_decisions[*].tax_decision_code`.
9. Derive:
   - `tax_event`
   - `result_lot_tax_type`
   - line constraints (`allow_partial_quantity`, `require_full_lot`, `lot_split_required`, etc.).

## Lot and Quantity Checks
- Lock source lot row `for update`.
- Source lot exists, tenant-visible, and status is movable (`active`).
- Source lot belongs to `src_site`.
- `uom_id` is required and must match source lot/inventory UOM context.
- `qty` does not exceed source lot balance.
- Source inventory (`inv_inventory`) for `(src_site, src_lot_id, uom_id)` exists and has sufficient quantity.
- If rule requires full-lot movement, enforce `qty = source_lot_qty`.

## Tables Affected
- Write: `public.inv_inventory`
- Write: `public.inv_movement_lines`
- Write: `public.inc_movements` (movement header)
- Update/Insert: `public.lot`
- Write: `public.lot_edge`

## Transaction Behavior (Atomic)
1. Normalize payload and resolve rule result.
2. Insert movement header to `inc_movements` with:
   - source/destination site
   - movement timestamp
   - `movement_intent`, `tax_decision_code`, derived `tax_event` in `meta`.
3. Insert one line in `inv_movement_lines`:
   - `src_lot_id`, `qty`, `uom_id`
   - include rule snapshot in `meta` (rule version + matched rule keys).
4. Apply lot movement:
   - Decrease source lot qty.
   - If destination lot is required:
     - create destination lot or reuse mapped destination lot
     - destination lot will inherit src lot package information
     - if auto-created, destination `lot_no` is set to src `lot_no`
     - set `lot_tax_type` to derived `result_lot_tax_type` when rule changes tax type.
5. Insert `lot_edge`:
   - `edge_type = 'MOVE'` for lot-to-lot movement.
   - `from_lot_id = src_lot_id`.
   - `to_lot_id = dst_lot_id` (or `NULL` for consume-style intents if applicable).
6. Update `inv_inventory`:
   - decrement source inventory
   - increment destination inventory when destination lot exists
7. If source lot qty becomes `0`, set source lot status to `consumed`.
8. Return created movement id.

## Output
- Returns `movement_id uuid`.

## Suggested Error Codes
- `PM001`: missing required input
- `PM002`: invalid qty
- `PM003`: rule definition not found (`ruleengine/beer_movement_rule`)
- `PM004`: movement_intent not allowed for site types
- `PM005`: tax_decision_code not allowed for resolved transformation rule
- `PM006`: source lot not found or not movable
- `PM007`: insufficient source lot/inventory qty
- `PM008`: full-lot movement required by rule
- `PM009`: destination lot creation/validation failed

## Example Input
```json
{
  "doc_no": "PM-20260214-0001",
  "movement_at": "2026-02-14T10:30:00Z",
  "movement_intent": "SHIP_DOMESTIC",
  "src_site": "11111111-1111-1111-1111-111111111111",
  "dst_site": "22222222-2222-2222-2222-222222222222",
  "src_lot_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "qty": 120,
  "uom_id": "44444444-4444-4444-4444-444444444444",
  "tax_decision_code": "TAXABLE_REMOVAL",
  "notes": "Domestic shipment",
  "meta": {
    "idempotency_key": "product_move:20260214:0001"
  }
}
```

## Notes
- This specification uses your requested header table name `inc_movements`.
- In current repository schema, movement headers are stored in `inv_movements`; implementers should map `inc_movements` to the active table name if needed.
