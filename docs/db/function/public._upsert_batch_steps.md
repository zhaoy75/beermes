# `public._upsert_batch_steps(p_batch_id uuid, p_steps jsonb) returns void`

## Purpose
Compatibility helper after `mes_batch_steps` removal.

## Input Contract
- Required: `p_batch_id`, `p_steps[]`.

## Validation
- Batch exists.

## Data Access
- No table writes (no-op).

## Behavior
- Validate tenant and batch existence, then return without persistence.

## Output
- None.

## Errors
- Batch not found.
- Invalid step payload.
