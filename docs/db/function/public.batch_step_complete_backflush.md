# `public.batch_step_complete_backflush(p_batch_step_id uuid, p_patch jsonb default '{}'::jsonb) returns jsonb`

## Purpose
Complete one batch step with transactional raw-material backflush posting.

## Input Contract
- Required: `p_batch_step_id`.
- Optional `p_patch` object keys:
  - `status`: must be `completed` when provided.
  - `started_at`, `ended_at`, `notes`
  - `actual_params`
  - `quality_checks_json`
  - `auto_ready_next_step`
  - `reason`

## Validation
- Step must exist in the current tenant.
- Step cannot be `skipped` or `cancelled`.
- Step must include at least one planned material with `consumption_mode = backflush`.
- `consumption_mode` may be stored at the top level or nested inside the plan JSON payload.
- Mixed `exact` + `backflush` planned inputs are rejected in this version.
- `started_at` must be earlier than or equal to `ended_at`.
- Batch metadata must resolve a source site for consumption.
- Actual-material rows must already exist in `mes.batch_material_actual` with positive quantity and `uom_id`.
- Explicit-lot rows must match source site, material, UOM, and available stock.
- Auto-allocation rows must be satisfiable from active lots in source-site FIFO order.

## Data Access
- Read/write: `mes.batch_step`
- Read: `mes.batch_material_plan`, `mes.batch_material_actual`, `mes_batches`
- Read/write: `inv_movements`, `inv_movement_lines`, `inv_inventory`, `lot`
- Helper calls: `_assert_tenant`, `_lock_lots`, `_assert_non_negative_lot_qty`

## Behavior
- Lock the target step row and resolve tenant/user context.
- Apply optional step-field patch values, defaulting `ended_at` to `now()`.
- Detect whether the step is eligible for backflush completion.
- Reuse an existing posted `production_issue` movement when the step was already backflushed.
- Otherwise:
  - resolve source site from batch metadata
  - insert one posted `inv_movements` header with `doc_type = 'production_issue'`
  - consume explicit-lot actual rows exactly as entered
  - consume non-lot actual rows by FIFO allocation across active lots in the source site
  - decrement `inv_inventory` and `lot.qty`, marking depleted lots as `consumed`
- Update the current `mes.batch_step` to `completed`.
- Optionally move the next `open` step to `ready`.

## Output
- JSON object with:
  - `batch_step_id`
  - `batch_id`
  - `movement_id`
  - `source_site_id`
  - `next_step_id`
  - `next_step_status`
  - `reused_existing_movement`
  - `consumed_lines`

## Idempotency
- Idempotent per batch step.
- If a posted backflush movement already exists for `meta.source = 'batch_step_backflush'` and the same `batch_step_id`, the function reuses that movement and does not post duplicate consumption.

## Errors
- Missing / invalid input patch data.
- Batch step not found or in an invalid status.
- No backflush planned materials found.
- Mixed `exact` + `backflush` planned materials.
- Source site could not be resolved from batch metadata.
- Missing actual-material quantity, UOM, or material context.
- Lot mismatch, inactive lot, insufficient stock, or negative-inventory guard failure.
