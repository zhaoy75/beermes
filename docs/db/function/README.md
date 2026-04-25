# Stored Function Specifications

Source list: `docs/db/dbfunction.md`

## Analysis Summary
- Current list contains the active stored-function specs only.
- Legacy generic filling, inventory-retrieve, movement CRUD, rule, and tax-event report RPCs have been removed.
- Movement-rule data is currently file-based (`docs/data/movementrule.jsonc`), not table-based.
- Tax event is modeled through `lot_event`/`lot_event_line` plus optional `meta.tax_event`.
- Core integrity risks to control in implementation:
- Tenant isolation and RLS-safe writes.
- Non-negative lot and inventory quantities.
- Cross-table consistency between movement and lot events.
- Idempotency for create endpoints to avoid duplicate business documents.

## Function Groups
- Batch: `batch_create`, `batch_save`, `batch_search`, `batch_get_detail`
- Product Movement: `product_produce`, `product_filling`, `product_move`, `product_move_fast_post`, `product_produce_rollback`, `product_filling_rollback`, `product_unpacking`, `domestic_removal_complete`
- Movement: `movement_save`, `movement_get_movement_ui_intent`, `movement_get_rules`
- Rule/UI labels: `ruleengine_get_ui_labels`
- Lot Trace: `lot_trace_upstream`, `lot_trace_downstream`, `lot_trace_full`
- Shared Helpers: `_assert_tenant`, `_lock_lots`, `_assert_non_negative_lot_qty`, `_upsert_movement_lines`, `_upsert_batch_steps`

## Spec Files
- `docs/db/function/public.batch_create.md`
- `docs/db/function/public.batch_save.md`
- `docs/db/function/public.batch_search.md`
- `docs/db/function/public.batch_get_detail.md`
- `docs/db/function/public.movement_save.md`
- `docs/db/function/movement_get_movement_UI_intent.md`
- `docs/db/function/movement_get_rules.md`
- `docs/db/function/ProductProduce.md`
- `docs/db/function/ProductProduceRollback.md`
- `docs/db/function/ProductFilling.md`
- `docs/db/function/ProductMove.md`
- `docs/db/function/public.lot_trace_upstream.md`
- `docs/db/function/public.lot_trace_downstream.md`
- `docs/db/function/public.lot_trace_full.md`
- `docs/db/function/lot_dag_get_by_batch.md`
- `docs/db/function/public.get_packing_source_lotid.md`
- `docs/db/function/get_volume_by_tank.md`
- `docs/db/function/public.get_current_tax_rate.md`
- `docs/db/function/public.batch_step_complete_backflush.md`
- `docs/db/function/public._assert_tenant.md`
- `docs/db/function/public._lock_lots.md`
- `docs/db/function/public._assert_non_negative_lot_qty.md`
- `docs/db/function/public._upsert_movement_lines.md`
- `docs/db/function/public._upsert_batch_steps.md`
