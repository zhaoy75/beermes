# Current Task

## Goal
- Expose only UI-safe ruleengine labels/enums to the frontend and cache them after login for shared label rendering.
- Add a read-only `軽減税額算出表` preview to the tax report editor page.

## Scope
- Add a sanitized RPC that reads the active `registry_def.kind = 'ruleengine'` / `beer_movement_rule` row but returns only labels, selected enum lists, version, and `updated_at`.
- Add a persisted frontend store for the sanitized ruleengine UI labels.
- Load the sanitized labels during auth sign-in/bootstrap and clear them on sign-out.
- Add a small label composable so pages can resolve `site_type`, `lot_tax_type`, `tax_event`, `edge_type`, `tax_decision_code`, and `movement_intent` labels from the cache.
- Add a `軽減税額算出表` preview in `TaxReportEditor.vue` that uses the same LIA130 calculation source as XML generation.
- Show current-month standard tax, return/deduction standard tax, reduced amounts, net amounts, prior fiscal-year cumulative standard tax, and reduction category/rate.
- Refresh the preview when the report breakdown, tax year/month, or current report id changes.
- Update safe display-oriented consumers first:
  - `ProducedBeer.vue` should stop loading full movement rules just for tax event labels/enums.
  - `TaxReportEditor.vue` should stop loading full movement rules just for tax event labels.
  - `ProducedBeerInventory.vue` should show `lot_tax_type` using ruleengine labels in the main table, merged detail table, and DAG dialog.
  - `InventorySearchModal.vue` should show `lot_tax_type` using ruleengine labels in the modal inventory table and merged detail table.
  - `ProductMoveFast.vue` and `ProducedBeerMovementEdit.vue` should prefer cached labels while still using full rule RPC data where route/tax decision logic requires it.

## Non-Goals
- Do not remove rule-decision RPC use from movement-entry pages that still require transformation rules.
- Do not change movement posting, tax report XML generation, or rule semantics.
- Do not change `registry_def` table schema.
- Do not move or duplicate labels into static Vue i18n JSON files.
- Do not refactor unrelated registry definitions.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [docs/UI/tax-report-editor.md](/Users/zhao/dev/other/beer/docs/UI/tax-report-editor.md)
- [DB/function/36_public.ruleengine_get_ui_labels.sql](/Users/zhao/dev/other/beer/DB/function/36_public.ruleengine_get_ui_labels.sql)
- [beeradmin_tail/src/stores/ruleengineLabels.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/stores/ruleengineLabels.ts)
- [beeradmin_tail/src/stores/auth.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/stores/auth.ts)
- [beeradmin_tail/src/stores/index.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/stores/index.ts)
- [beeradmin_tail/src/composables/useRuleengineLabels.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/composables/useRuleengineLabels.ts)
- [beeradmin_tail/src/components/inventory/InventorySearchModal.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/components/inventory/InventorySearchModal.vue)
- [beeradmin_tail/src/lib/taxReport.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxReport.ts)
- [beeradmin_tail/src/views/Pages/ProducedBeer.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/ProducedBeer.vue)
- [beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue)
- [beeradmin_tail/src/views/Pages/TaxReportEditor.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/TaxReportEditor.vue)
- [beeradmin_tail/src/views/Pages/ProductMoveFast.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/ProductMoveFast.vue)
- [beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue)

## Data Model / API Changes
- No table/schema changes.
- Add RPC `public.ruleengine_get_ui_labels()` returning a sanitized JSON payload:
  - `version`
  - `updated_at`
  - `enums` for UI-safe code lists
  - `labels` for UI-safe label maps
- The RPC must not return movement transformation rules, movement intent rules, allowed route combinations, tax decision behavior flags, or defaults.
- No API changes for the `軽減税額算出表` preview; it reuses existing `tax_reports` reads and local reduction calculation.

## Implementation Notes
- The frontend cache is tenant-aware and persisted in localStorage through Pinia persisted state.
- Cached label lookup should fall back to existing full-rule payloads on pages that still load them, then fall back to the raw code.
- Display-only pages should use the sanitized cache directly and avoid `movement_get_rules()` when labels/enums are the only need.
- Inventory rows and modal inventory rows should keep raw `lot_tax_type` values for grouping/filtering/sorting and convert only rendered text to labels.
- The tax reduction preview is read-only and must not change `tax_reports.total_tax_amount`.
- The preview should use the same prior fiscal-year cumulative source as XML generation: `fetchPriorFiscalYearStandardTaxAmount`.
- If prior fiscal-year cumulative loading fails, show a compact error and keep the rest of the editor usable.
- If the sanitized RPC fails during login/bootstrap, auth should continue; individual pages can still show raw codes/fallback labels.

## Validation Plan
- Run SQL text sanity checks where feasible.
- Run targeted ESLint for touched frontend files.
- Run frontend type-check.
- Run `git diff --check`.
- Run `npm run test --if-present`.
- Run `npm run build:test`.

## Final Decisions
- Added `public.ruleengine_get_ui_labels()` as a sanitized RPC for ruleengine UI labels/enums only.
- Added a persisted Pinia cache in `ruleengineLabels.ts` and a `useRuleengineLabels()` composable for localized label lookup.
- Auth sign-in and bootstrap force-refresh the sanitized label cache after session resolution; sign-out and signed-out auth events clear it.
- `ProducedBeer.vue` and `TaxReportEditor.vue` no longer call `movement_get_rules()` just to display tax event labels.
- `TaxReportEditor.vue` now shows a read-only `軽減税額算出表` preview based on the same LIA130 calculation source as generated XML.
- `ProducedBeerInventory.vue` renders `lot_tax_type` through the sanitized label cache while preserving raw values in the data model.
- `InventorySearchModal.vue` renders `lot_tax_type` through the sanitized label cache while preserving raw values in the data model and selection payloads.
- `ProductMoveFast.vue` and `ProducedBeerMovementEdit.vue` still call `movement_get_rules()` where rule decisions are needed, but label rendering now prefers the sanitized cache and falls back to the full-rule payload.
- Full rule exposure remains only on movement-entry pages that currently need transformation rules for validation/default decisions.

## Validation Results
- `npx eslint src/stores/auth.ts src/stores/ruleengineLabels.ts src/composables/useRuleengineLabels.ts src/views/Pages/ProducedBeer.vue src/views/Pages/TaxReportEditor.vue --no-fix` in `beeradmin_tail`: passed.
- `npx eslint src/stores/auth.ts src/stores/ruleengineLabels.ts src/composables/useRuleengineLabels.ts src/views/Pages/ProducedBeer.vue src/views/Pages/TaxReportEditor.vue src/views/Pages/ProductMoveFast.vue src/views/Pages/ProducedBeerMovementEdit.vue --no-fix` in `beeradmin_tail`: failed because `ProductMoveFast.vue` and `ProducedBeerMovementEdit.vue` already contain many `no-explicit-any` and unused-function violations unrelated to this change.
- `npm run type-check` in `beeradmin_tail`: passed.
- `git diff --check -- specs/current-task.md DB/function/36_public.ruleengine_get_ui_labels.sql beeradmin_tail/src/stores/auth.ts beeradmin_tail/src/stores/index.ts beeradmin_tail/src/stores/ruleengineLabels.ts beeradmin_tail/src/composables/useRuleengineLabels.ts beeradmin_tail/src/views/Pages/ProducedBeer.vue beeradmin_tail/src/views/Pages/TaxReportEditor.vue beeradmin_tail/src/views/Pages/ProductMoveFast.vue beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue`: passed.
- `npm run test --if-present` in `beeradmin_tail`: passed with no test script configured.
- `npm run build:test` in `beeradmin_tail`: passed with existing CSS `:is()` minify warnings and existing chunk-size warnings.
- `npx eslint src/views/Pages/ProducedBeerInventory.vue src/composables/useRuleengineLabels.ts src/stores/ruleengineLabels.ts --no-fix` in `beeradmin_tail`: passed.
- `npm run type-check` in `beeradmin_tail` after inventory page update: passed.
- `git diff --check -- specs/current-task.md beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue`: passed.
- `npm run test --if-present` in `beeradmin_tail` after inventory page update: passed with no test script configured.
- `npm run build:test` in `beeradmin_tail` after inventory page update: passed with existing CSS `:is()` minify warnings and existing chunk-size warnings.
- `npx eslint src/components/inventory/InventorySearchModal.vue src/composables/useRuleengineLabels.ts src/stores/ruleengineLabels.ts --no-fix` in `beeradmin_tail`: passed.
- `npm run type-check` in `beeradmin_tail` after modal inventory update: passed.
- `git diff --check -- specs/current-task.md beeradmin_tail/src/components/inventory/InventorySearchModal.vue`: passed.
- `npm run test --if-present` in `beeradmin_tail` after modal inventory update: passed with no test script configured.
- `npm run build:test` in `beeradmin_tail` after modal inventory update: passed with existing CSS `:is()` minify warnings and existing chunk-size warnings.
- `npx eslint src/views/Pages/TaxReportEditor.vue src/lib/taxReport.ts --no-fix` in `beeradmin_tail`: passed.
- `npm run type-check` in `beeradmin_tail` after reduction preview update: passed.
- `git diff --check -- specs/current-task.md docs/UI/tax-report-editor.md beeradmin_tail/src/views/Pages/TaxReportEditor.vue beeradmin_tail/src/lib/taxReport.ts beeradmin_tail/src/locales/ja.json beeradmin_tail/src/locales/en.json`: passed.
- `npm run test --if-present` in `beeradmin_tail` after reduction preview update: passed with no test script configured.
- `npm run build:test` in `beeradmin_tail` after reduction preview update: passed with existing CSS `:is()` minify warnings and existing chunk-size warnings.
