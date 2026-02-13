# `public.inventory_retrieve(p_filter jsonb) returns table (...)`

## Purpose
Query current inventory balances for UI.

## Input Contract
- Optional filters: `site_id`, `material_id`, `batch_code`, `limit`, `offset`.

## Validation
- Pagination bounds.

## Data Access
- Read: `inv_inventory`.

## Behavior
- Filter and return raw inventory rows.

## Output
- Tabular rows from signature.

## Errors
- Invalid filter types.
