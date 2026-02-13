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

## 2) Filling + inventory retrieve

1. `public.filling_create(p_doc jsonb) returns uuid`
- Purpose: register filling/packaging event.
- Main tables: `inv_movements`, `inv_movement_lines`, `lot_event`, `lot_event_line`, `lot`.
- Notes: should write movement and lot event together (atomic transaction).

2. `public.filling_save(p_movement_id uuid, p_doc jsonb) returns uuid`
- Purpose: update/void/repost a filling movement.
- Main tables: `inv_movements`, `inv_movement_lines`, linked `lot_event*`.

3. `public.inventory_retrieve(p_filter jsonb) returns table (inventory_id uuid, material_id uuid, site_id uuid, qty numeric, uom_id uuid, batch_code text, created_at timestamptz)`
- Purpose: inventory list for UI.
- Main tables: `inv_inventory`.

4. `public.inventory_retrieve_by_lot(p_filter jsonb) returns table (lot_id uuid, lot_no text, material_id uuid, package_id uuid, batch_id uuid, site_id uuid, qty numeric, uom_id uuid, status text, produced_at timestamptz, expires_at timestamptz)`
- Purpose: lot-level inventory view for packing/shipping UI.
- Main tables: `lot`.

## 3) Movement: create/save/search

1. `public.movement_create(p_doc jsonb) returns uuid`
- Purpose: create movement header + lines.
- Main tables: `inv_movements`, `inv_movement_lines`.
- Notes: supports `doc_type`, `src_site_id`, `dest_site_id`, `movement_at`, lines array.

2. `public.movement_save(p_movement_id uuid, p_doc jsonb) returns uuid`
- Purpose: update movement (open/posted/void, metadata, lines).
- Main tables: `inv_movements`, `inv_movement_lines`.

3. `public.movement_search(p_filter jsonb) returns table (id uuid, doc_no text, doc_type inv_doc_type, status text, movement_at timestamptz, src_site_id uuid, dest_site_id uuid, created_at timestamptz)`
- Purpose: searchable movement list API.
- Main tables: `inv_movements`.

4. `public.movement_get_detail(p_movement_id uuid) returns jsonb`
- Purpose: retrieve header with lines, lot links, and site names.
- Main tables: `inv_movements`, `inv_movement_lines`, `mst_sites`, `lot_event`.

## 4) Get movement rules for UI

Current DDL has no dedicated movement-rule table. Rules are in `docs/data/movementrule.jsonc`.

1. `public.movement_rules_get_ui() returns jsonb`
- Purpose: return rule payload for UI wizard.
- Implementation options:
- `A)` hardcoded JSONB constant in function (deployed from `movementrule.jsonc`).
- `B)` preferred: add a config table later and read latest active rule version.

2. `public.movement_rules_get_tax_decisions(p_movement_intent text, p_src_site_type text, p_dst_site_type text, p_lot_tax_type text) returns jsonb`
- Purpose: return allowed tax decisions for selected context.
- Notes: helper API for UI dependent dropdowns.

## 5) Retrieve tax event

`tax_event` is not a native column in current DDL tables; it is represented by rule data and/or stored in `meta`.

1. `public.tax_event_retrieve(p_filter jsonb) returns table (lot_event_id uuid, event_no text, event_type lot_event_type, event_at timestamptz, status text, src_site_id uuid, dest_site_id uuid, tax_event text, reason text)`
- Purpose: list tax-related event records for report screens.
- Main tables: `lot_event`.
- Notes: `tax_event` can be read from `lot_event.meta ->> 'tax_event'`.

2. `public.tax_event_retrieve_lines(p_lot_event_id uuid) returns jsonb`
- Purpose: return tax-event header with line-level quantities/lots.
- Main tables: `lot_event`, `lot_event_line`, `lot`.

3. `public.tax_report_retrieve(p_year int, p_month int) returns jsonb`
- Purpose: read stored tax report summary.
- Main tables: `tax_reports`.

## 6) Trace lot

1. `public.lot_trace_upstream(p_lot_id uuid) returns table (depth int, lot_id uuid, related_lot_id uuid, relation_type text, movement_id uuid, lot_event_id uuid, occurred_at timestamptz)`
- Purpose: trace where lot came from (parents/source).
- Main tables: `lot`, `lot_event`, `lot_event_line`, `inv_movements`, `inv_movement_lines`, `mes_batch_relation`.

2. `public.lot_trace_downstream(p_lot_id uuid) returns table (depth int, lot_id uuid, related_lot_id uuid, relation_type text, movement_id uuid, lot_event_id uuid, occurred_at timestamptz)`
- Purpose: trace where lot went (consumption/shipment/split).
- Main tables: same as upstream.

3. `public.lot_trace_full(p_lot_id uuid, p_max_depth int default 10) returns jsonb`
- Purpose: full lot genealogy graph for UI.
- Notes: use recursive CTE internally, return nodes/edges JSON.

## 7) Shared internal helper functions (recommended)

1. `public._assert_tenant() returns uuid`
2. `public._lock_lots(p_lot_ids uuid[]) returns void`
3. `public._assert_non_negative_lot_qty(p_lot_id uuid) returns void`
4. `public._derive_tax_event(p_context jsonb) returns text`
5. `public._apply_inventory_delta(p_lines jsonb, p_direction text) returns void`
6. `public._upsert_movement_lines(p_movement_id uuid, p_lines jsonb) returns void`
7. `public._upsert_batch_steps(p_batch_id uuid, p_steps jsonb) returns void`

These helpers keep the public API stable and reduce duplicated validation logic.
