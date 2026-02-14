# `public.product_produce(p_doc jsonb) returns uuid`

## Purpose
Register product produced from a batch. A new beer lot appears at a destination (manufacturing) site and inventory increases.

## Business Meaning
- Movement intent: product production
- Result: new lot is created and stocked at destination site
- Traceability: `lot_edge` is recorded as `PRODUCE` from `NULL` to new lot

## Tables Affected
- Write: `public.inv_movements`
- Write: `public.inv_movement_lines`
- Write: `public.lot`
- Write: `public.lot_edge`
- Write/Upsert: `public.inv_inventory`

## Function Signature
```sql
create or replace function public.product_produce(p_doc jsonb)
returns uuid
language plpgsql
security invoker;
```

## Input Contract (`p_doc`)
Required fields:
- `doc_no` text: business document number (tenant unique)
- `movement_at` timestamptz: production timestamp
- `dest_site_id` uuid: manufacturing site id
- `batch_id` uuid: source manufacturing batch id
- `qty` numeric: produced quantity, must be `> 0`
- `uom_id` uuid: quantity UOM

Optional fields:
- `src_site_id` uuid: nullable, may be `NULL` or manufacturing site
- `lot_no` text: explicit lot number; if absent, generate by rule
- `produced_at` timestamptz: defaults to `movement_at`
- `expires_at` timestamptz
- `notes` text
- `meta` jsonb
- `line_meta` jsonb

## Fixed/Derived Values
- `inv_movements.doc_type = 'BREW_PRODUCE'` (or mapped enum value in your system)
- `inv_movements.status = 'posted'`
- `inv_movement_lines.line_no = 1`
- `inv_movement_lines.material_id = '00000000-0000-0000-0000-000000000000'::uuid`
- `lot_edge.edge_type = 'PRODUCE'`
- `lot_edge.from_lot_id = NULL`
- `lot_edge.to_lot_id = <new_lot_id>`
- `lot_edge.qty = p_doc.qty`

## Validation
- Tenant exists via `public._assert_tenant()`.
- `qty > 0`.
- `dest_site_id`, `batch_id`, `uom_id` are present.
- `doc_no` unique per tenant in `inv_movements`.
- `lot_no` unique per tenant in `lot` (if provided).
- `src_site_id` is either `NULL` or same as `dest_site_id` for this intent.
- `uom_id` consistency across movement line, lot, lot_edge, inventory row.

## Transaction Behavior (Atomic)
1. Resolve tenant id (`v_tenant`) and normalize payload.
2. Insert one row into `inv_movements`:
   - `src_site_id = NULL` or provided manufacturing site
   - `dest_site_id = p_doc.dest_site_id`
   - `doc_type = BREW_PRODUCE`
   - `status = posted`
3. Insert one row into `inv_movement_lines`:
   - `movement_id = <inserted movement id>`
   - `material_id = '00000000-0000-0000-0000-000000000000'::uuid`
   - `batch_id = p_doc.batch_id`
   - `qty = p_doc.qty`, `uom_id = p_doc.uom_id`
4. Create one new lot in `lot`:
   - `lot_no`, `material_id='00000000-0000-0000-0000-000000000000'::uuid`, `batch_id`, `site_id = dest_site_id`
   - `produced_at`, `expires_at`, `qty`, `uom_id`, `status = active`
5. Create one `lot_edge` row:
   - `movement_id`, `movement_line_id`
   - `edge_type = PRODUCE`
   - `from_lot_id = NULL`, `to_lot_id = <new_lot_id>`
   - `qty`, `uom_id`
6. Upsert inventory in `inv_inventory` on key `(tenant_id, site_id, lot_id, uom_id)`:
   - if exists: `qty = qty + p_doc.qty`
   - else: insert new row with `qty = p_doc.qty`
7. Return `<movement_id>`.

## Suggested Return
Return `movement_id uuid`.

## Suggested Error Codes
- `PP001`: missing required field
- `PP002`: invalid quantity (`qty <= 0`)
- `PP003`: duplicate `doc_no`
- `PP004`: duplicate `lot_no`
- `PP005`: invalid `src_site_id`/`dest_site_id` combination for produce intent
- `PP006`: FK/reference not found (`batch_id`, `uom_id`, `site_id`)

## Idempotency Recommendation
Support optional `idempotency_key` in `p_doc.meta`:
- unique per tenant
- if repeated, return existing `movement_id` without creating duplicate lot/inventory.

## Example Input
```json
{
  "doc_no": "BP-20260214-0001",
  "movement_at": "2026-02-14T09:00:00Z",
  "src_site_id": null,
  "dest_site_id": "11111111-1111-1111-1111-111111111111",
  "batch_id": "33333333-3333-3333-3333-333333333333",
  "qty": 1200,
  "uom_id": "44444444-4444-4444-4444-444444444444",
  "lot_no": "LOT-20260214-01",
  "produced_at": "2026-02-14T08:30:00Z",
  "meta": { "movement_intent": "BREW_PRODUCE" }
}
```

## Notes
- Current `inv_doc_type` enum in DDL may need extension/mapping to support `BREW_PRODUCE` literal.
- Function should run in a single transaction and rely on RLS tenant defaults/policies already defined in DDL.
