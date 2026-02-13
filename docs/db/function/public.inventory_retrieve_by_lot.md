# `public.inventory_retrieve_by_lot(p_filter jsonb) returns table (...)`

## Purpose
Query lot-level inventory status.

## Input Contract
- Optional filters: `site_id`, `batch_id`, `material_id`, `status`, `expires_before`.

## Validation
- Filter types and pagination bounds.

## Data Access
- Read: `lot`.

## Behavior
- Return lot rows for operational/trace UI.

## Output
- Tabular rows from signature.

## Errors
- Invalid filter payload.
