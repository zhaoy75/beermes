# Current Task

## Goal
- Improve the 移送詰口管理 Filling UI for 詰口容器 where `volume_fix_flg = false`.
- Use one unified filling-line design for both fixed-volume and non-fixed-volume packages.
- Make total filled volume explicit and store non-fixed total volume as liters.
- Fix produced beer inventory `数量(本/箱)` so variable-volume packages use saved package count instead of deriving count from volume.
- Fix produced beer movement entry points so non-fixed package `unit` / `package_qty` is not derived from volume.

## Scope
- Analyze and specify the current filling-line metadata contract.
- Update the Batch Packing UI spec before source implementation.
- Define how fixed and non-fixed 詰口 lines should display, validate, save metadata, and map to `public.product_filling`.
- Keep Batch Packing, Batch Edit history, and Filling Report consistent through shared filling calculation rules.
- Keep Produced Beer Inventory package counts consistent with `lot.unit` / movement-line `unit` semantics.
- Keep Product Move Fast and Produced Beer Movement wizard package counts consistent with saved lot package counts.

## Non-Goals
- Do not change database schema for this UI task.
- Do not change `public.product_filling(p_doc jsonb)`.
- Do not change 詰口容器管理 master fields.
- Do not backfill old `inv_movements.meta.filling_lines` data.
- Do not change `inv_inventory` schema.
- Do not change `public.product_move(p_doc jsonb)`.

## Affected Files
- Spec/docs:
  - `specs/current-task.md`
  - `docs/UI/batchpacking.md`
  - `docs/UI/produced-beer-inventory-management-spec.md`
  - `docs/UI/product_beer.md`
- Source implementation:
  - `beeradmin_tail/src/views/Pages/BatchPacking.vue`
  - `beeradmin_tail/src/lib/batchFilling.ts`
  - `beeradmin_tail/src/views/Pages/BatchEdit.vue`
  - `beeradmin_tail/src/views/Pages/FillingReport.vue`
  - `beeradmin_tail/src/composables/useProducedBeerInventory.ts`
  - `beeradmin_tail/src/views/Pages/ProductMoveFast.vue`
  - `beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue`
  - `beeradmin_tail/src/locales/ja.json`
  - `beeradmin_tail/src/locales/en.json`

## Current Metadata / Behavior
- Current UI uses one input column `個数/容量(L)` whose meaning changes by package:
  - fixed-volume package: input is `qty` / container count
  - non-fixed-volume package: input is `volume`
- Current movement metadata for `meta.filling_lines[]`:
  - fixed package:
    - `qty` = container count
    - `volume` = `null`
  - non-fixed package:
    - `qty` = `null`
    - `volume` = entered total volume
- Current `product_filling.lines[]` mapping:
  - `qty` = filled volume converted to source lot UOM
  - `unit` = fixed package count only
  - `meta.unit_count` = fixed package count only
  - `meta.input_volume_l` = non-fixed input volume
  - `meta.volume_fix_flg` = fixed/non-fixed flag
- Current shared report/history logic still has risky fallback behavior:
  - non-fixed `qty` may be treated as volume when `volume` is missing
  - package count for non-fixed rows may fall back to volume
- This fallback must be removed when non-fixed `qty` becomes container count.
- Current Produced Beer Inventory behavior derives `数量(本/箱)` from `qtyLiters / mst_package.unit_volume`.
  - This is acceptable for fixed-volume packages.
  - This is incorrect for non-fixed-volume packages, where actual container count is saved in `lot.unit` / `inv_movement_lines.unit`.

## Target UX Design
- Use one filling-line table layout for both package types:
  - 詰口容器
  - ロットコード
  - 容器数
  - 1容器あたり容量 / 容量目安
  - 総充填容量(L)
  - サンプル
  - 操作
- Fixed-volume package:
  - `容器数` is required and must be an integer `>= 1`.
  - `1容器あたり容量` is read-only from `mst_package.unit_volume`.
  - `総充填容量(L)` is read-only and calculated as `容器数 * unit_volume` converted to liters.
  - Save is blocked if `unit_volume` is missing or not greater than zero.
- Non-fixed-volume package:
  - `総充填容量(L)` is required and user-editable.
  - `総充填容量(L)` is stored in metadata as liters.
  - `容器数` is optional; when entered, it must be an integer `>= 1`.
  - `1容器あたり容量 / 容量目安` shows only a reference from `max_volume` or `unit_volume` when available.
  - If `容器数` is entered, display derived average volume per container: `総充填容量(L) / 容器数`.
  - `max_volume` is not a blocking validation rule in this task.
  - If entered volume exceeds the reference capacity converted to liters, show a warning but allow save.

## Data Model / API Contract
- No schema changes.
- `meta.filling_lines[]` target meaning:
  - fixed package:
    - `qty` = container count
    - `volume` = `null`
  - non-fixed package:
    - `qty` = optional container count
    - `volume` = required total filled volume in liters
- `public.product_filling(p_doc).lines[]` target meaning:
  - `qty` = filled volume converted from liters to the source lot UOM
  - `unit` = container count when entered
  - `meta.unit_count` = container count when entered
  - `meta.input_volume_l` = non-fixed total filled volume in liters
  - `meta.volume_fix_flg` = fixed/non-fixed flag
- If liters cannot be converted to the source lot UOM, save must be blocked before calling `public.product_filling`.
- Non-fixed total volume remains stored in metadata as liters for compatibility, but calculations, warnings, and RPC conversion must normalize through integer milliliters at calculation boundaries.

## Calculation Rules
- Fixed package line volume:
  - `line.qty * mst_package.unit_volume`, converted to liters using `mst_package.volume_uom`.
- Non-fixed package line volume:
  - `line.volume` only.
  - Never use non-fixed `qty` as volume fallback.
- Capacity warning:
  - `capacity_reference_liters = convertToLiters(mst_package.max_volume ?? mst_package.unit_volume, mst_package.volume_uom)`.
  - When non-fixed `qty` is present, warn if `line.volume > capacity_reference_liters * line.qty`.
  - When non-fixed `qty` is absent, warn if `line.volume > capacity_reference_liters`.
  - The warning is non-blocking.
- Precision boundary:
  - Convert stored liter values to integer milliliters before comparison, aggregation, or conversion to source lot UOM.
  - Convert integer milliliters back to liters only for display or compatible payload fields that explicitly store liters.
- Package count:
  - Sum non-sample `qty` when present for both fixed and non-fixed rows.
  - Do not use non-fixed `volume` as package count fallback.
- Produced Beer Inventory package count:
  - Prefer `lot.unit` as the current package count for packaged lots.
  - If the same lot appears in a partial inventory row, prorate `lot.unit` by `inv_inventory.qty / lot.qty` after converting both quantities to liters.
  - For fixed-volume packages only, if no saved package count exists, fall back to `qtyLiters / unit_volume_liters`.
  - For non-fixed-volume packages, do not fall back to `qtyLiters / unit_volume_liters`; show no package count when saved count is missing.
- Product movement entry package count:
  - Movement pages must load `lot.unit`, `lot.qty`, `lot.uom_id`, `lot.meta`, and `mst_package.volume_fix_flg` when candidate lots are loaded.
  - Fixed-volume packages may continue to convert package count input to movement volume using `unit_volume`.
  - Fixed-volume package availability and validation must use saved/prorated package count when available, with volume-derived fallback only for display/legacy data.
  - Fixed-volume package movement quantity input must be an integer package count.
  - Non-fixed-volume packages must treat movement quantity input as volume in the lot UOM / liters field, not package count.
  - Non-fixed-volume package count display and saved `unit` / `meta.package_qty` must come from saved lot count prorated by moved volume.
  - If saved lot count is missing for a non-fixed package, save `unit` / `meta.package_qty` as `null`; do not calculate `qty / unit_volume`.
  - Fast movement quick-entry may auto-calculate volume from unit count only for fixed-volume packages.
  - Fast movement quick-entry unit input is disabled for non-fixed-volume packages so user-entered count is not confused with saved/prorated count.
- Filling report fallback:
  - New `product_filling` rows must use `meta.input_volume_l` for non-fixed-volume report volume.
  - When `meta.input_volume_l` is missing, fallback reconstruction from movement line `qty` is allowed only when the line UOM is liters.
  - Do not assume movement line `qty` is liters when its UOM is unknown or non-liter.
- Sample rows:
  - Excluded from inventory `lines[]`.
  - Excluded from inventory package count.
  - Included in sample volume and effective loss.

## Validation Plan
- Run:
  - `git diff --check`
  - targeted ESLint for changed frontend files
  - `npm run type-check`
- Static checks after implementation:
  - non-fixed `volume` is saved/read as liters
  - non-fixed `qty` is only count, never volume fallback
  - fixed package requires valid `unit_volume`
  - fixed and non-fixed filled volumes can be converted from liters to the source lot UOM
  - volume calculations normalize through integer milliliters at calculation boundaries
  - non-fixed capacity excess shows a warning, not a blocking error
  - `product_filling.lines[].qty` remains filled volume
  - `product_filling.lines[].unit` carries count when entered
  - inventory `数量(本/箱)` for non-fixed packages uses saved count and never derives count from volume
  - movement entry pages save package count for non-fixed packages only from saved/prorated lot count
  - fixed-package movement pages validate integer package count against available package count
  - filling report fallback does not treat non-liter movement quantity as liters

## Final Decisions
- Batch Packing filling rows now use separate UI fields for container count, capacity reference, and total filled volume.
- Fixed-volume packages require integer container count and derive total liters from `unit_volume`.
- Non-fixed-volume packages require total filled volume in liters; container count is optional and saved as count when entered.
- Non-fixed capacity excess is a non-blocking warning based on `max_volume ?? unit_volume`, converted through `volume_uom`.
- Filling calculations normalize liters through integer milliliters before aggregation and source-lot UOM conversion.
- `meta.filling_lines[]` saves both `package_id` and legacy `package_type_id` for compatibility; readers accept either field.
- `public.product_filling.lines[].qty` remains filled volume in the source lot UOM; `unit` and `meta.unit_count` carry container count when entered.
- Shared filling history/report logic no longer treats non-fixed `qty` as a volume fallback.
- Produced Beer Inventory derives `数量(本/箱)` from saved lot package count first; volume-based fallback is limited to fixed-volume packages.
- Product movement entry pages derive non-fixed package count from saved lot count and no longer use volume divided by package unit volume for variable-volume containers.

## Validation Results
- `git diff --check` passed after spec edits.
- `npm run type-check` passed in `beeradmin_tail` after source edits.
- Targeted ESLint passed for changed TypeScript/Vue files:
  - `src/lib/batchFilling.ts`
  - `src/views/Pages/BatchPacking.vue`
  - `src/views/Pages/BatchEdit.vue`
  - `src/views/Pages/FillingReport.vue`
  - `src/composables/useProducedBeerInventory.ts`
- Targeted ESLint passed for `src/views/Pages/FillingReport.vue` after fallback reconstruction changes.
- Targeted ESLint for movement entry files was run but did not pass because these files still contain existing `@typescript-eslint/no-explicit-any` and `@typescript-eslint/no-unused-vars` violations outside this change:
  - `src/views/Pages/ProductMoveFast.vue`
  - `src/views/Pages/ProducedBeerMovementEdit.vue`
- Unit tests were not run because this frontend package does not define a unit-test script.
