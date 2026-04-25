# Stored Function List (Based on Current DDL)

This list is aligned to current tables in:
- `mes_batches`, `mes_batch_steps`, `mes_batch_relation`
- `inv_inventory`
- `inv_movements`, `inv_movement_lines`
- `lot`, `lot_event`, `lot_event_line`
- `tax_reports`

All functions are expected in `public` schema and tenant-aware via existing RLS/default `tenant_id`.

## 1) Batch: create/save/search

1. `public.batch_create(p_doc jsonb) returns uuid`
- Purpose: create a new batch header and optional steps.
- Main tables: `mes_batches`, `mes_batch_steps`.
- Notes: `p_doc` should include `batch_code`, optional `recipe_id`, dates, and step array.

2. `public.batch_save(p_batch_id uuid, p_patch jsonb) returns uuid`
- Purpose: update existing batch data (header, KPI, notes, status, optional step updates).
- Main tables: `mes_batches`, `mes_batch_steps`.
- Notes: patch-style update for UI edit screens.

3. `public.batch_search(p_filter jsonb) returns table (id uuid, batch_code text, status mes_batch_status, recipe_id uuid, planned_start timestamptz, planned_end timestamptz, actual_start timestamptz, actual_end timestamptz, created_at timestamptz)`
- Purpose: searchable list API for batch list.
- Main tables: `mes_batches`.
- Notes: filter keys like `status`, date range, `recipe_id`, keyword (`batch_code`/`batch_label`).

4. `public.batch_get_detail(p_batch_id uuid) returns jsonb`
- Purpose: retrieve one batch with steps and lineage summary.
- Main tables: `mes_batches`, `mes_batch_steps`, `mes_batch_relation`.

## 2) Movement

1. `public.movement_save(p_movement_id uuid, p_doc jsonb) returns uuid`
- Purpose: update movement (open/posted/void, metadata, lines).
- Main tables: `inv_movements`, `inv_movement_lines`.

2. `public.movement_get_movement_ui_intent() returns table`
- Purpose: return movement intents for movement UI.

3. `public.movement_get_rules(p_movement_intent text) returns jsonb`
- Purpose: return active movement-rule data for a movement intent.

## 3) Product movement

1. `public.product_produce(p_doc jsonb) returns uuid`
- Purpose: post produced beer lot receipt.

2. `public.product_filling(p_doc jsonb) returns uuid`
- Purpose: split a source lot into packaged/filling lots.

3. `public.product_move(p_doc jsonb) returns uuid`
- Purpose: move/ship product lots with tax-rule metadata.

4. `public.product_move_fast_post(p_docs jsonb) returns jsonb`
- Purpose: post multiple product move documents.

5. `public.product_produce_rollback(p_doc jsonb) returns uuid`
- Purpose: rollback a produced beer receipt when no downstream usage blocks it.

6. `public.product_filling_rollback(p_doc jsonb) returns uuid`
- Purpose: rollback a filling movement and restore source lot quantity.

7. `public.product_unpacking(p_doc jsonb) returns uuid`
- Purpose: unpack product lot quantities.

8. `public.domestic_removal_complete(...) returns uuid`
- Purpose: complete domestic removal through standard movement logic.

## 4) Trace lot

1. `public.lot_trace_upstream(p_lot_id uuid) returns table (...)`
- Purpose: trace where lot came from (parents/source).
- Main tables: `lot`, `lot_event`, `lot_event_line`, `inv_movements`, `inv_movement_lines`, `mes_batch_relation`.

2. `public.lot_trace_downstream(p_lot_id uuid) returns table (...)`
- Purpose: trace where lot went (consumption/shipment/split).
- Main tables: same as upstream.

3. `public.lot_trace_full(p_lot_id uuid, p_max_depth int default 10) returns jsonb`
- Purpose: full lot genealogy graph for UI.
- Notes: use recursive CTE internally, return nodes/edges JSON.

## 5) Shared internal helper functions

1. `public._assert_tenant() returns uuid`
2. `public._lock_lots(p_lot_ids uuid[]) returns void`
3. `public._assert_non_negative_lot_qty(p_lot_id uuid) returns void`
4. `public._upsert_movement_lines(p_movement_id uuid, p_lines jsonb) returns void`
5. `public._upsert_batch_steps(p_batch_id uuid, p_steps jsonb) returns void`

## Removed legacy functions

The following old generic RPCs/helpers were removed from the active source list:
`filling_create`, `filling_save`, `inventory_retrieve`, `inventory_retrieve_by_lot`,
`movement_create`, `movement_search`, `movement_get_detail`,
`movement_rules_get_ui`, `movement_rules_get_tax_decisions`,
`tax_event_retrieve`, `tax_event_retrieve_lines`, `tax_report_retrieve`,
`_derive_tax_event`, and `_apply_inventory_delta`.
