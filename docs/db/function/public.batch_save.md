# `public.batch_save(p_batch_id uuid, p_patch jsonb) returns uuid`

## Purpose
Update batch fields.

## Input Contract
- Required: `p_batch_id`.
- Optional patch keys: `batch_code`, status/date fields/notes/meta/kpi.
- `batch_code`, when supplied, is trimmed and must not be blank.
- `planned_start`, `planned_end`, `actual_start`, and `actual_end` are date-only business fields.
- Send these date fields as `YYYY-MM-DD`; the function truncates them to day precision before storing.

## Validation
- Batch must exist and be tenant-visible.
- `batch_code` must not be blank when supplied.
- Status must be valid `mes_batch_status`.

## Data Access
- Write: `mes_batches`.

## Behavior
- Patch `mes_batches` with only provided fields.
- Store batch date-like fields at day precision for compatibility with current `timestamptz` columns.

## Output
- Return `p_batch_id`.

## Errors
- Batch not found.
- Blank batch code.
- Invalid status or step payload.
