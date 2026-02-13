# `public.movement_search(p_filter jsonb) returns table (...)`

## Purpose
Search movement documents for list UI.

## Input Contract
- Optional: `doc_type`, `status`, `doc_no`, date range, `src_site_id`, `dest_site_id`, paging.

## Validation
- Pagination and date range sanity.

## Data Access
- Read: `inv_movements`.

## Behavior
- Apply filters and return ordered rows.

## Output
- Rows defined by signature.

## Errors
- Invalid filter data types.
