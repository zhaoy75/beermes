# `public._upsert_batch_steps(p_batch_id uuid, p_steps jsonb) returns void`

## Purpose
Replace or merge step rows under a batch.

## Input Contract
- Required: `p_batch_id`, `p_steps[]`.

## Validation
- Batch exists.
- `step_no` unique in payload.
- `step` enum/shape compatible with `prc_step_type`.

## Data Access
- Write: `mes_batch_steps`.

## Behavior
- Upsert by `(tenant_id, batch_id, step_no)`.
- Remove stale rows when caller intends full replace.

## Output
- None.

## Errors
- Batch not found.
- Invalid step payload.
