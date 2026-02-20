# `public.product_filling(p_doc jsonb) returns uuid`

## Purpose
Register filling/packaging for product produced from a batch. Quantity is moved from one source lot to one or more new filled lots at a site.

## Business Meaning
- Movement intent: filling/package
- Result: source lot is consumed (partially or fully) and new packed lots are created
- Traceability: `lot_edge` records split flow from source lot to each packed lot

## Tables Affected
- Write: `public.inv_movements`
- Write: `public.inv_movement_lines`
- Write: `public.lot`
- Write: `public.lot_edge`
- Write/Upsert: `public.inv_inventory`
- Update: `public.lot` (decrease source lot qty)

## Function Signature
```sql
create or replace function public.product_filling(p_doc jsonb)
returns uuid
language plpgsql
security invoker;
```

## Input Contract (`p_doc`)
Required fields:
- `doc_no` text: business document number (tenant unique)
- `movement_at` timestamptz: filling timestamp
- `src_site_id` uuid: source site
- `dest_site_id` uuid: destination site (for filling, normally same as source)
- `batch_id` uuid: batch id
- `from_lot_id` uuid: source produced lot id
- `uom_id` uuid: quantity UOM (volume)
- `lines` jsonb array: at least 1 line
- `loss qty` numeric: loss quantity for packing

Required line fields (`lines[]`):
- `qty` numeric: filled quantity per line, must be `> 0`

Optional line fields:
- `line_no` int
- `unit` numeric: unit count for the filled lot line (`> 0` when provided)
- `lot_no` text: destination filled lot number; generated if absent from root lot:
  - `<ROOT_LOT_NO>_NNN` (increasing number)
- `package_id` uuid
- `expires_at` timestamptz
- `notes` text
- `meta` jsonb

Optional header fields:
- `notes` text
- `meta` jsonb

## Fixed/Derived Values
- `inv_movements.doc_type = 'PACKAGE_FILL'` (or mapped enum value in your system)
- `inv_movements.status = 'posted'`
- `inv_movement_lines.material_id = '00000000-0000-0000-0000-000000000000'::uuid`
- `lot.material_id = '00000000-0000-0000-0000-000000000000'::uuid`
- `lot_edge.edge_type = 'SPLIT'`
- `lot_edge.from_lot_id = p_doc.from_lot_id`
- `lot_edge.to_lot_id = <new_filled_lot_id>`

## Validation
- Tenant exists via `public._assert_tenant()`.
- `doc_no`, `src_site_id`, `dest_site_id`, `batch_id`, `from_lot_id`, `uom_id`, `lines[]` are present.
- `lines[]` is non-empty and each line `qty > 0`.
- If line `unit` is provided, it must be `> 0`.
- Source lot exists, tenant-visible, and has enough balance for `sum(lines.qty)`.
- `src_site_id` and `dest_site_id` must be same for filling intent (or explicitly allowed by your rule).
- `doc_no` unique per tenant in `inv_movements`.
- Destination `lot_no` unique per tenant (if provided).
- `uom_id` consistency across movement lines, lot, lot_edge, inventory.

## Transaction Behavior (Atomic)
1. Resolve tenant id (`v_tenant`) and normalize payload.
2. Lock source lot row (`from_lot_id`) for update.
3. Validate total required qty against source lot qty.
4. Insert one row into `inv_movements`:
   - `doc_type = PACKAGE_FILL`
   - `status = posted`
   - `src_site_id = p_doc.src_site_id`
   - `dest_site_id = p_doc.dest_site_id`
5. For each `lines[]` row:
   - Determine `line_no`.
   - Create destination filled lot in `lot` with line qty and line unit. lot_tax_type set to TAX_SUSPENDED.
   - Insert one `inv_movement_lines` row with `qty`, `unit`, `uom_id`.
   - Insert one `lot_edge` row with `edge_type = SPLIT` from source lot to destination lot.
   - Decrease source lot qty by line qty.
   - Upsert inventory:
     - decrement source inventory `(src_site_id, from_lot_id, uom_id)`
     - increment destination inventory `(dest_site_id, new_lot_id, uom_id)`
6. If loss qty is > 0
  - Determine `line_no`.
  - Insert one `inv_movement_lines` row.
   - meta.line_role: `LOSS`
   - meta.tank_id: `tank_id`
  - Decrease source lot qty by line qty.

6. If source lot qty reaches `0`, optionally set source lot `status = consumed`.
7. Return `<movement_id>`.

## Suggested Return
Return `movement_id uuid`.

## Suggested Error Codes
- `PF001`: missing required field
- `PF002`: invalid quantity (`qty <= 0`)
- `PF003`: duplicate `doc_no`
- `PF004`: duplicate destination `lot_no`
- `PF005`: source lot insufficient quantity
- `PF006`: invalid site combination for filling intent
- `PF007`: source lot not found

## Idempotency Recommendation
Support optional `idempotency_key` in `p_doc.meta`:
- unique per tenant
- if repeated, return existing `movement_id` and do not create duplicate lots/edges.

## Example Input
```json
{
  "doc_no": "PF-20260214-0001",
  "movement_at": "2026-02-14T10:30:00Z",
  "src_site_id": "11111111-1111-1111-1111-111111111111",
  "dest_site_id": "11111111-1111-1111-1111-111111111111",
  "batch_id": "33333333-3333-3333-3333-333333333333",
  "from_lot_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "uom_id": "44444444-4444-4444-4444-444444444444",
  "lines": [
    {
      "line_no": 1,
      "lot_no": "BATCH20260214_001",
      "package_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
      "qty": 120,
      "unit": 240,
      "meta": { "unit_count": 240 }
    },
    {
      "line_no": 2,
      "lot_no": "BATCH20260214_002",
      "package_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
      "qty": 80,
      "unit": 160,
      "meta": { "unit_count": 160 }
    }
  ],
  "meta": {
    "movement_intent": "PACKAGE_FILL",
    "idempotency_key": "batch_filling:33333333-3333-3333-3333-333333333333:20260214:001"
  }
}
```

## Notes
- This specification is aligned to `lot_edge`-based lineage (no `lot_event` / `lot_event_line`).
- If `inv_doc_type` does not include `PACKAGE_FILL`, map to your available enum (commonly `production_receipt`).
- DDL now provides `unit numeric` on `lot` and `inv_movement_lines`; this function should persist per-line unit counts when provided.
