# Stored Function Specifications

Source list: `docs/db/dbfunction.md`

## Analysis Summary
- Current list contains `27` functions.
- Public API functions: `20`.
- Internal helper functions: `7`.
- Movement-rule data is currently file-based (`docs/data/movementrule.jsonc`), not table-based.
- Tax event is modeled through `lot_event`/`lot_event_line` plus optional `meta.tax_event`.
- Core integrity risks to control in implementation:
- Tenant isolation and RLS-safe writes.
- Non-negative lot and inventory quantities.
- Cross-table consistency between movement and lot events.
- Idempotency for create endpoints to avoid duplicate business documents.

## Function Groups
- Batch: `batch_create`, `batch_save`, `batch_search`, `batch_get_detail`
- Filling/Inventory: `filling_create`, `filling_save`, `inventory_retrieve`, `inventory_retrieve_by_lot`
- Movement: `movement_create`, `movement_save`, `movement_search`, `movement_get_detail`
- Rules/Tax: `movement_rules_get_ui`, `movement_rules_get_tax_decisions`, `tax_event_retrieve`, `tax_event_retrieve_lines`, `tax_report_retrieve`
- Lot Trace: `lot_trace_upstream`, `lot_trace_downstream`, `lot_trace_full`
- Shared Helpers: `_assert_tenant`, `_lock_lots`, `_assert_non_negative_lot_qty`, `_derive_tax_event`, `_apply_inventory_delta`, `_upsert_movement_lines`, `_upsert_batch_steps`

## Spec Files
- `docs/db/function/public.batch_create.md`
- `docs/db/function/public.batch_save.md`
- `docs/db/function/public.batch_search.md`
- `docs/db/function/public.batch_get_detail.md`
- `docs/db/function/public.filling_create.md`
- `docs/db/function/public.filling_save.md`
- `docs/db/function/public.inventory_retrieve.md`
- `docs/db/function/public.inventory_retrieve_by_lot.md`
- `docs/db/function/public.movement_create.md`
- `docs/db/function/public.movement_save.md`
- `docs/db/function/public.movement_search.md`
- `docs/db/function/public.movement_get_detail.md`
- `docs/db/function/public.movement_rules_get_ui.md`
- `docs/db/function/public.movement_rules_get_tax_decisions.md`
- `docs/db/function/public.tax_event_retrieve.md`
- `docs/db/function/public.tax_event_retrieve_lines.md`
- `docs/db/function/public.tax_report_retrieve.md`
- `docs/db/function/public.lot_trace_upstream.md`
- `docs/db/function/public.lot_trace_downstream.md`
- `docs/db/function/public.lot_trace_full.md`
- `docs/db/function/public.source_lot_get_by_batch.md`
- `docs/db/function/public.get_packing_source_lotid.md`
- `docs/db/function/public._assert_tenant.md`
- `docs/db/function/public._lock_lots.md`
- `docs/db/function/public._assert_non_negative_lot_qty.md`
- `docs/db/function/public._derive_tax_event.md`
- `docs/db/function/public._apply_inventory_delta.md`
- `docs/db/function/public._upsert_movement_lines.md`
- `docs/db/function/public._upsert_batch_steps.md`
