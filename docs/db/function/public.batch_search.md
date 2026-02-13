# `public.batch_search(p_filter jsonb) returns table (...)`

## Purpose
Search and paginate batches for list UI.

## Input Contract
- Optional filters: `status`, `recipe_id`, `planned_from`, `planned_to`, `keyword`, `limit`, `offset`.

## Validation
- `limit` and `offset` must be bounded.

## Data Access
- Read: `mes_batches`.

## Behavior
- Apply dynamic predicates from `p_filter`.
- Default sort: `created_at desc`.

## Output
- Batch list rows defined in signature.

## Errors
- Invalid filter types.
