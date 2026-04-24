# `public.product_filling(p_doc jsonb) returns uuid`

## Purpose
Register filling/packaging for product produced from a batch. Quantity is moved from one source lot to one or more new filled lots at a site.

## Business Meaning
- Movement intent: filling/package
- Result: source lot is consumed (partially or fully) and new packed lots are created
- Traceability: `lot_edge` records split flow from source lot to each packed lot
- Rollback/reversal lineage is audit lineage only; it must not be treated as upstream production ancestry for future filling lot-number generation.

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
- `loss_qty` numeric: loss quantity for packing. Legacy key `loss qty` may be accepted for backward compatibility.

Required line fields (`lines[]`):
- `qty` numeric: filled quantity per line, must be `> 0`

Optional line fields:
- `line_no` int
- `unit` numeric: unit count for the filled lot line (`> 0` when provided)
- `tax_rate` numeric: stored on `inv_movement_lines.tax_rate` when provided
- `lot_no` text: destination filled lot number; generated if absent from root lot:
  - `<ROOT_LOT_NO>_NNN` (increasing number)
  - `lot_no` is a business-visible label and may duplicate within a tenant; system identity is always `lot.id`
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

## Lot Lineage And Lot Numbering
- `product_filling` derives the root lot number by walking upstream from `p_doc.from_lot_id` through `lot_edge.to_lot_id -> lot_edge.from_lot_id`.
- The upstream walk is used only to generate default destination filled lot numbers when `lines[].lot_no` is not provided.
- The upstream walk must be cycle-safe:
  - track visited lot ids
  - stop at a bounded maximum depth
  - never follow `MERGE` edges
- `MERGE` edges written by `product_filling_rollback` represent rollback/reversal movement from filled child lot back to the source lot. They must not be used as production ancestry; otherwise a later filling save can loop through source lot -> filled child lot -> source lot and hit `statement_timeout`.
- Generated filled lot numbers use the highest existing numeric suffix for the resolved root lot:
  - root lot: `<ROOT_LOT_NO>`
  - generated filled lot: `<ROOT_LOT_NO>_NNN`
  - the suffix scan is protected by an advisory transaction lock on `(tenant, root lot number)`.

## Validation
- Tenant exists via `public._assert_tenant()`.
- `doc_no`, `src_site_id`, `dest_site_id`, `batch_id`, `from_lot_id`, `uom_id`, `lines[]` are present.
- `lines[]` is non-empty and each line `qty > 0`.
- If line `unit` is provided, it must be `> 0`.
- Source lot exists, tenant-visible, and has enough balance for `sum(lines.qty) + loss_qty`.
- Source inventory exists at `(src_site_id, from_lot_id, uom_id)` and has enough balance for `sum(lines.qty) + loss_qty`.
- Source lot `uom_id` must match payload `uom_id`.
- Source lot `site_id`, when present, must match payload `src_site_id`.
- Filling `movement_at` must not be before the effective creation time of `from_lot_id`.
- `src_site_id` and `dest_site_id` normally match for filling; the function may allow same-site filling when packaging happens in the source site.
- `doc_no` unique per tenant in `inv_movements`.
- `uom_id` consistency across movement lines, lot, lot_edge, inventory.

## Transaction Behavior (Atomic)
1. Resolve tenant id (`v_tenant`) and normalize payload.
2. Lock source lot row (`from_lot_id`) for update.
3. Validate total required qty against source lot qty and source inventory qty.
4. Resolve root lot number with the cycle-safe upstream walk described above.
5. Insert one row into `inv_movements`:
   - `doc_type = PACKAGE_FILL`
   - `status = posted`
   - `src_site_id = p_doc.src_site_id`
   - `dest_site_id = p_doc.dest_site_id`
6. For each `lines[]` row:
   - Determine `line_no`.
   - Generate `lot_no` from root lot when the line does not provide one.
   - Create destination filled lot in `lot` with line qty and line unit. lot_tax_type set to TAX_SUSPENDED.
   - Insert one `inv_movement_lines` row with `qty`, `unit`, optional `tax_rate`, `uom_id`.
   - Insert one `lot_edge` row with `edge_type = SPLIT` from source lot to destination lot.
   - Upsert inventory:
     - increment destination inventory `(dest_site_id, new_lot_id, uom_id)`
7. If loss qty is > 0:
   - Determine `line_no`.
   - Insert one `inv_movement_lines` row.
   - meta.line_role: `LOSS`
   - meta.tank_id: `tank_id`
8. Decrement source inventory `(src_site_id, from_lot_id, uom_id)` by `sum(lines.qty) + loss_qty`.
9. Decrease source lot qty by `sum(lines.qty) + loss_qty`.
10. If source lot qty reaches `0`, set source lot `status = consumed`.
11. Return `<movement_id>`.

## Suggested Return
Return `movement_id uuid`.

## Suggested Error Codes
- `PF001`: missing required field
- `PF002`: invalid quantity (`qty <= 0`)
- `PF003`: duplicate `doc_no`
- `PF005`: source lot insufficient quantity
- `PF006`: invalid site combination for filling intent
- `PF007`: source lot not found

## Idempotency Recommendation
Support optional `idempotency_key` in `p_doc.meta`:
- unique per tenant
- if repeated while the matching movement is still `posted`, return existing `movement_id` and do not create duplicate lots/edges.
- do not return voided/reversed movements for idempotency. A filling event deleted by rollback must not block a later re-created filling event from writing active lots/edges.

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
      "tax_rate": 0.1,
      "meta": { "unit_count": 240 }
    },
    {
      "line_no": 2,
      "lot_no": "BATCH20260214_002",
      "package_id": "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
      "qty": 80,
      "unit": 160,
      "tax_rate": 0.1,
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
- `inv_movement_lines` persists per-line `unit` and optional `tax_rate`; `lot` persists the per-line `unit` value when provided.
- Downstream UI/search flows must treat `lot.id` as the canonical key and `lot_no` as a non-unique display/search attribute.
- Apply supporting indexes on `lot_edge` for `(tenant_id, movement_id)`, `(tenant_id, from_lot_id)`, and `(tenant_id, to_lot_id)` because filling, rollback, chronology checks, and source-lot lookup all rely on these access patterns.
