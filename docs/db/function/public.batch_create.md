# `public.batch_create(p_doc jsonb) returns uuid`

## Purpose
Create a batch header and optional step rows.

## Input Contract
- Required: `p_doc.batch_code`.
- Optional: `batch_label`, `recipe_id`, `planned_start`, `planned_end`, `status`.
- `planned_start`, `planned_end`, `actual_start`, and `actual_end` are date-only business fields.
- Send these date fields as `YYYY-MM-DD`; the function truncates them to day precision before storing.

## Validation
- `batch_code` must be unique per tenant (`mes_batches` unique key).

## Data Access
- Write: `mes_batches`.
- Read: `mes_recipes` (optional FK validation), `mst_uom` (optional FK validation).

## Behavior
- Insert `mes_batches` first.
- Store batch date-like fields at day precision for compatibility with current `timestamptz` columns.
- Use one transaction.

## Output
- Return created `mes_batches.id`.

## Errors
- Duplicate batch code.
- Invalid FK references.
