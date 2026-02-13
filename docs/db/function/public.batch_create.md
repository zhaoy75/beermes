# `public.batch_create(p_doc jsonb) returns uuid`

## Purpose
Create a batch header and optional step rows.

## Input Contract
- Required: `p_doc.batch_code`.
- Optional: `batch_label`, `recipe_id`, `planned_start`, `planned_end`, `status`, `steps[]`.

## Validation
- `batch_code` must be unique per tenant (`mes_batches` unique key).
- If `steps[]` exists: each item needs unique `step_no`.

## Data Access
- Write: `mes_batches`, `mes_batch_steps`.
- Read: `mes_recipes` (optional FK validation), `mst_uom` (optional FK validation).

## Behavior
- Insert `mes_batches` first.
- Insert `mes_batch_steps` if provided.
- Use one transaction.

## Output
- Return created `mes_batches.id`.

## Errors
- Duplicate batch code.
- Invalid FK references.
