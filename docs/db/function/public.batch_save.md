# `public.batch_save(p_batch_id uuid, p_patch jsonb) returns uuid`

## Purpose
Update batch fields and optionally upsert steps.

## Input Contract
- Required: `p_batch_id`.
- Optional patch keys: status/timestamps/notes/meta/kpi/steps.

## Validation
- Batch must exist and be tenant-visible.
- Status must be valid `mes_batch_status`.

## Data Access
- Write: `mes_batches`, `mes_batch_steps`.

## Behavior
- Patch `mes_batches` with only provided fields.
- If `steps` present, delegate to `_upsert_batch_steps`.

## Output
- Return `p_batch_id`.

## Errors
- Batch not found.
- Invalid status or step payload.
