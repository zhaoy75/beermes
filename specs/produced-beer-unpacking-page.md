# Produced Beer Unpacking Page Spec

## Purpose
- Register dismantling of packaged beer back into bulk / unpacked beer.
- Use current packaged inventory as the operational source of truth.
- Support partial unpacking of a packaged lot that may already have been partially shipped.
- Preserve lot genealogy and inventory audit trail.

## Entry Strategy
- Primary entry point: `在庫管理` packaged inventory row action `解体`.
- The inventory row must pass:
  - source `lot_id`
  - source `site_id`
  - source `batch_id`
  - package info
  - currently available quantity
- Secondary future entry point:
  - from batch packing history row detail, read-only navigation into the same unpacking page
- The actual data-entry page is dedicated:
  - route recommendation: `/producedBeerInventory/unpack/:lotId`
  - page name recommendation: `ProducedBeerUnpacking`

## Why Inventory Is the Entry Point
- The user decides based on current remaining packaged stock, not only on original filling history.
- A partially shipped packaged lot is still represented as a current inventory row and remains a valid unpacking target.
- Inventory is the only place where the user can reliably see the remaining quantity available for unpacking.

## Why Inventory Is Not the Full Editing Surface
- Unpacking is not a simple row-level quantity edit.
- The operation needs structured input:
  - unpack quantity
  - destination site
  - destination tank
  - target batch
  - loss
  - reason / notes
- Embedding that form into the inventory grid would make the page too heavy and error-prone.

## Page Layout
### Header
- Title:
  - Japanese: `製品ビール解体登録`
  - English: `Packaged Beer Unpacking`
- Back button:
  - returns to inventory page
- Source lot summary card:
  - lot code
  - batch code
  - style / product
  - package type
  - current available qty
  - current site

### Main Form
1. Source Section
- Read-only
- Fields:
  - source lot
  - source site
  - source batch
  - package type
  - available quantity

2. Unpacking Section
- Fields:
  - unpack quantity
  - quantity UOM
  - destination site
  - destination tank
  - target batch
  - unpack loss qty
  - reason
  - memo

3. Result Preview
- show:
  - source packaged qty after unpacking
  - resulting bulk qty
  - resulting loss qty
  - target site / tank / batch

4. Actions
- `保存`
- `保存して次へ` is not needed in phase 1
- `キャンセル`

## Field Rules
### Source Lot
- Must be a packaged lot from current positive inventory.
- The unpack page is not allowed to search arbitrary historical packaged lots in phase 1.

### Unpack Quantity
- Required
- Must be `> 0`
- Must be `<= current available qty`
- Partial unpack is allowed

### Destination Site
- Required
- Allowed site type in phase 1:
  - `BREWERY_MANUFACTUR`
- This keeps the result aligned with bulk / unpacked beer handling

### Destination Tank
- Required when the destination site is tank-managed
- Optional only if the site has no tank requirement policy

### Target Batch
- Required
- Phase 1 default:
  - prefill from source batch
- Recommendation:
  - operator may later choose a dedicated rework batch, but automatic rework-batch creation is outside phase 1

### Loss
- Required numeric field with default `0`
- Must be `>= 0`
- `unpack qty - loss qty` becomes the resulting bulk lot quantity

## Backend Contract
### RPC
- `public.product_unpacking(p_doc jsonb) returns uuid`

### Required Payload
```json
{
  "doc_no": "PU-20260412-0001",
  "movement_at": "2026-04-12T10:30:00Z",
  "src_site_id": "<source packaged site>",
  "dest_site_id": "<destination bulk site>",
  "src_lot_id": "<packaged lot id>",
  "target_batch_id": "<batch id>",
  "uom_id": "<volume uom>",
  "qty": 100,
  "loss_qty": 2,
  "tank_id": "<optional tank id>",
  "reason": "unpack",
  "notes": "damaged package / repack work",
  "meta": {
    "source": "produced_beer_inventory_unpacking",
    "movement_intent": "PACKAGE_UNPACK",
    "package_recovery": false
  }
}
```

### Backend Behavior
- lock source packaged lot and source inventory
- validate current available quantity
- decrease source packaged lot qty
- decrease source packaged `inv_inventory`
- create one new bulk lot for the recovered beer quantity
- add destination `inv_inventory`
- create `lot_edge` from source packaged lot to destination bulk lot
- write one business movement record and line records
- store unpack metadata for later history rendering

## Lot Genealogy Rule
- The unpack result must create a new bulk lot.
- Do not add quantity back into the old pre-filling source lot.
- Reason:
  - avoids rewriting historical lot balances
  - keeps audit trail explicit
  - works even when packaged lot was partially shipped before unpacking

## Inventory Page Integration
- `在庫管理` row action:
  - `解体`
- Action visible only when:
  - row is packaged beer
  - row quantity is positive
  - row resolves to exactly one underlying lot id in phase 1
- On click:
  - navigate to the unpack page with source lot context

## Batch Packing Integration
- Batch Packing history should show unpacking as a read-only event row.
- Unpack rows must reduce processed volume by the recovered quantity, not by the source packaged quantity.
- Batch Packing is not the phase-1 entry point.
- Batch Edit filling summary may later include unpacking-derived effects, but phase 1 only requires history visibility.

## Non-Goals
- Recover bottles / cans / caps / labels into packaging inventory
- Multi-source-lot to single-bulk-lot unpacking
- Inline unpack editing inside inventory grid
- Auto-create rework batch
- Add unpacking to the generic movement wizard

## Finalized Phase-1 Choices
- `lot_edge.edge_type` for recovered unpack output is `SPLIT`.
- When unpack loss exists, phase 1 also writes a `CONSUME` edge for the loss line.
- `target_batch_id` remains operator-selectable, but UI defaults it from the source batch.
- `destination tank` is optional in phase 1 because there is no site-level tank-required policy in the current source.
- `inv_movements.meta` for unpacking uses:
  - `source = "packing"`
  - `entry_source = "produced_beer_inventory_unpacking"`
  - `packing_type = "unpack"`
  - `batch_id = <target_batch_id>`
  - `volume_qty = <recovered_qty>`
  - `unpack_qty = <input_qty>`
  - `loss_qty = <loss_qty>`
  - `source_package_id`, `source_lot_no`, `unpack_units`, and `source_remaining_qty` for batch-page rendering

## Acceptance Criteria
1. User can start unpacking from a packaged inventory row in `在庫管理`.
2. User can register partial unpacking based on current remaining packaged quantity.
3. Save logic is defined through a dedicated backend RPC, not the generic movement wizard.
4. A successful unpack creates a new bulk lot and destination inventory.
5. The original historical bulk lot is not mutated directly.
6. The resulting unpack event is traceable from inventory and visible in batch-packing history.
