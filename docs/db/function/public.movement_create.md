# `public.movement_create(p_doc jsonb) returns uuid`

## Purpose
Create movement header and lines.

## Input Contract
- Required header: `doc_no`, `doc_type`, `movement_at`.
- Required lines: `lines[]` with positive qty and `uom_id`.

## Validation
- `doc_no` unique per tenant.
- `doc_type` in `inv_doc_type`.
- `src_site_id`/`dest_site_id` valid for movement type.

## Data Access
- Write: `inv_movements`, `inv_movement_lines`.

## Behavior
- Insert header then lines.
- Optionally call `_apply_inventory_delta` when status is posted.

## Output
- Return created `movement_id`.

## Errors
- Duplicate `doc_no`.
- Invalid line items.
