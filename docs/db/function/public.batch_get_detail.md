# `public.batch_get_detail(p_batch_id uuid) returns jsonb`

## Purpose
Return batch header, steps, and relation summary.

## Input Contract
- Required: `p_batch_id`.

## Validation
- Batch must exist and be tenant-visible.

## Data Access
- Read: `mes_batches`, `mes_batch_steps`, `mes_batch_relation`.

## Behavior
- Build one JSON document with header and child arrays.

## Output
- JSON object: `{batch, steps, relations}`.

## Errors
- Batch not found.
