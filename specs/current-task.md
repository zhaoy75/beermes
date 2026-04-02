# Current Task Spec

## Goal
- Change the `酒税申告` flow so report creation/editing happens on a dedicated page instead of an in-page dialog.
- When a user creates a new monthly tax report draft, also generate the `課税移出一覧表` Excel for the selected month by reusing the existing taxable-removal export source.
- Persist generated XML/XLSX files in Supabase Storage and save file metadata in `tax_reports.report_files`.
- Fix the `酒税申告` tax total so only `課税移出` adds tax and `戻入` subtracts tax, with tax rates applied per `kL` rather than per `L`.
- Change the `酒税申告` tax basis from movement `doc_type` to movement `税務移出種別` (`tax_event`, with fallback to `tax_decision_code` / legacy doc-type inference).
- Fix the `酒税申告` per-row `tax_rate` normalization so derived totals are not inflated by a `1000x` unit mismatch.
- Fix the `年間課税概要` page tax calculation so it converts `L` to `kL` before applying tax and determines tax effect from `税務移出種別` instead of assuming every volume is taxable.

## Scope
- Keep `TaxReport.vue` focused on the list/search/create-prompt experience for saved `tax_reports`.
- Create a separate `申告書編集` page/component and route for:
  - creating a new draft from the selected tax period
  - editing an existing saved report
- Move shared tax-report editor logic out of the list page as needed so the editor source is separated from the list page source.
- Reuse the existing `課税移出一覧表` export implementation by extracting shared taxable-removal data/export helpers instead of duplicating the workbook logic inside the tax-report editor.
- On new monthly draft creation, generate a month-scoped `課税移出一覧表` Excel from the shared export source in addition to the existing tax-report flow.
- Do not expose a manual `課税移出一覧表Excel` button on the dedicated editor page.
- Upload generated XML/XLSX files to Supabase Storage and persist metadata objects in `tax_reports.report_files`.
- Update UI specs so the list page spec and the editor page spec are separated.
- Correct the editor/list tax-total calculation path for saved and newly generated report data.
- Sort the editor `移出・移入概要` rows by `移出種別`.
- Make the list-page `酒税額合計` render from the normalized breakdown calculation path.
- Preserve the tax-basis classification in saved `volume_breakdown` rows so saved reports can be recalculated consistently.
- Correct saved/generated `volume_breakdown.tax_rate` values so they remain `/kL` rates instead of accidental `/L * 1000` scaled values.
- On the `申告書編集` page, replace the displayed `移出種別` column with `税務移出種別`, using the same `tax_event` labeling source as the `移出記録` page.
- Make the `申告書編集` page `移出・移入概要` table user-sortable by column.
- Make the `酒税申告` list-page `申告内訳（種別・ABV別）` display use `税務移出種別` instead of legacy `移出種別`.
- Limit the `酒税申告` list-page `申告内訳（種別・ABV別）` display to 3 visible lines and show `...` when more rows exist.
- On the `移出記録` page, set the default `開始日` filter to one month ago and ensure the initial load / reset / refetch behavior follows that search condition.
- On the `年間課税概要` page, recalculate tax from movement-level `tax_event` / `tax_decision_code` and `volume_l / 1000 * tax_rate`.
- Align the `年間課税概要` data loading and labels with movement-based tax data instead of production-receipt-only assumptions where needed.

## Non-Goals
- No change to taxable-removal business rules or movement source tables beyond what is needed to reuse the current export logic.
- No redesign of unrelated tax pages.
- No persistence of file binaries inside `localStorage`.
- No persistence of base64 file content directly inside `tax_reports.report_files`.
- No redesign of XML output structure beyond what is required for corrected tax calculation and saved-row compatibility.

## Affected Files
- `specs/current-task.md`
- `DB/ddl/storage_tax_report_files.sql`
- `docs/UI/product_beer.md`
- `docs/UI/tax-report.md`
- `docs/UI/tax-report-editor.md`
- `docs/UI/tax-removal-report.md`
- `beeradmin_tail/src/router/tenant-routes.ts`
- `beeradmin_tail/src/views/Pages/ProducedBeer.vue`
- `beeradmin_tail/src/views/Pages/TaxYearSummary.vue`
- `beeradmin_tail/src/views/Pages/TaxReport.vue`
- `beeradmin_tail/src/views/Pages/TaxReportEditor.vue`
- `beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue`
- `beeradmin_tail/src/lib/*` or `beeradmin_tail/src/composables/*` shared tax-report / taxable-removal helper files as needed
- `beeradmin_tail/src/locales/ja.json`
- `beeradmin_tail/src/locales/en.json`

## Data Model / API Changes
- `tax_reports.report_files` will be treated as a JSON array of file metadata objects instead of a string array of file names.
- Generated XML/XLSX binaries will be stored in Supabase Storage.
- Frontend routing will add a dedicated tax-report editor route.
- Shared frontend helper APIs may be introduced for:
  - tax-report editor state / load-save behavior
  - taxable-removal data loading
  - taxable-removal workbook generation for full business-year export and selected-month export
  - tax-report file upload/download via Supabase Storage
- `tax_reports.volume_breakdown` items may include persisted tax-basis metadata such as `tax_event` so derived totals do not need to rely on `move_type` alone.

## Planned File Changes
- Shrink `TaxReport.vue` to the list page and replace modal open/edit behavior with navigation to the dedicated editor page.
- Add a new `TaxReportEditor.vue` page for create/edit.
- Add a router entry for the editor page.
- Extract reusable taxable-removal export/data logic from `TaxableRemovalReport.vue`.
- Use the shared taxable-removal export source from the tax-report editor to generate the selected-month Excel during new monthly report creation.
- Replace file-name-only `report_files` handling with storage metadata handling in the specs.
- Split the UI documentation into separate list-page and editor-page specs.
- Fetch movement tax metadata during editor breakdown generation and use it as the tax-effect source of truth.
- Persist tax-basis metadata in the breakdown and update list/editor derived-total paths to use it with legacy fallbacks.
- Fix generation and read-normalization so derived totals remain consistent with the stored `total_tax_amount` field for existing rows affected by the scaling bug.
- Load movement-rule label metadata in the editor so `税務移出種別` is displayed the same way as in `移出記録`.
- Add movement-table sort state and header actions in the editor without changing saved data shape.
- Update the list-page breakdown label and heading text so it reflects `税務移出種別`.
- Truncate the list-page breakdown preview without changing the saved breakdown data.
- Set the produced-beer movement search default date range state before the first fetch and restore that default on filter reset.
- Change `TaxYearSummary.vue` to load movement headers/lines with tax metadata, calculate tax by `tax_event`, and divide liters by `1000` before applying the rate.
- Update `年間課税概要` labels if the page no longer represents production-only data.

## Final Decisions
- `TaxReport.vue` now only handles list/search/create-prompt/delete/XML-download behavior.
- A new dedicated editor route and page were added:
  - `/taxReports/new`
  - `/taxReports/:id`
- Tax-report XML helpers were extracted into a shared frontend module so the list page and editor page use the same XML rebuild logic.
- Taxable-removal data loading and workbook generation were extracted into a shared frontend module, and `TaxableRemovalReport.vue` now uses that shared source.
- `tax_reports.report_files` is now handled as storage metadata objects in the frontend, with legacy string-array rows normalized on read for backward compatibility.
- Saving a tax report uploads generated XML/XLSX files to Supabase Storage and persists their metadata in `tax_reports.report_files`.
- Stored object keys use a flat sanitized format instead of nested folder-style paths so they work with stricter/self-hosted storage backends.
- A dedicated SQL DDL file defines the `tax-report-files` storage bucket and tenant-scoped `storage.objects` policies required for upload/download/delete.
- New report ids use a browser-compatible UUID fallback when `crypto.randomUUID()` is unavailable.
- The list page downloads saved files from Supabase Storage when metadata is available, and still rebuilds legacy XML files locally when an old row has only file names.
- New monthly tax-report creation now prepares the selected-month `課税移出一覧表` Excel from the shared taxable-removal export source and persists it on save.
- The dedicated editor page does not expose a manual `課税移出一覧表Excel` button.
- The editor period fields (`課税種別`, `課税年度`, `月`) are read-only.
- `sale` and `return` now affect `酒税額合計` using `volume_l / 1000 * tax_rate_per_kL`, while non-taxable movement types do not affect the total.
- Legacy saved rows with no per-row tax rates infer fallback rates from tax-affecting movement types only (`sale` / `return`).
- Saved rows with explicit per-row tax rates are normalized to the corrected derived total on load.
- The editor `移出・移入概要` table is ordered by `税務移出種別`, then legacy move type, then category, then ABV for both generated and loaded rows.
- The list page `酒税額合計` display now uses the shared derived-tax calculation instead of trusting stale saved totals.
- `酒税申告` tax calculation now uses saved/generated `tax_event` values as the source of truth, with fallback to `tax_decision_code` and legacy doc-type inference only for older rows.
- Generated and saved `volume_breakdown` rows now persist `tax_event`, and the editor groups summary rows by `move_type + tax_event + category + ABV`.
- The editor and list page append a tax-classification label only when the saved `tax_event` differs from the legacy doc-type meaning, to disambiguate mixed cases without renaming standard rows.
- Generated `volume_breakdown.tax_rate` values are now derived from actual grouped tax amounts, so the stored rate remains a `/kL` rate instead of an accidental `1000x` scaled value.
- Saved rows with explicit per-row `tax_rate` values are normalized on load when the derived total is `1000x` the saved `total_tax_amount` and dividing the rates by `1000` matches the stored total.
- The `申告書編集` page now displays `税務移出種別` instead of `移出種別`, and the label source matches `移出記録`: `inv_movements.meta.tax_event` displayed through `movement_get_rules(...).tax_event_labels`, with raw-code fallback when no label mapping exists.
- The `申告書編集` page `移出・移入概要` table is now user-sortable by `税務移出種別`, `酒類分類`, `ABV`, and `数量`, with repeated clicks toggling ascending and descending order.
- The `酒税申告` list page `申告内訳（税務移出種別・ABV別）` now renders each breakdown row from `tax_event` labels, with legacy move-type label fallback only when no tax-event label is available.
- The `酒税申告` list page breakdown preview now shows at most 3 rows per report and appends `...` when additional rows exist.
- UI docs were split so the list page and editor page have separate specifications.
- On the `移出記録` page, `開始日` now defaults to one month before the current date.
- The `移出記録` page initial load and filter reset now both use that default `開始日`, so the first fetch and reset fetch follow the search condition immediately.
- `年間課税概要` now loads non-void movement headers and lines for the selected year instead of assuming `production_receipt` rows are the taxable basis.
- `年間課税概要` tax amounts are now calculated from movement `tax_event` / `tax_decision_code` with the shared `volume_l / 1000 * tax_rate` rule, so only tax-relevant movement types affect `酒税`.
- `年間課税概要` labels now describe movement-based quantities and movement dates rather than production/fill terminology.

## Validation Plan
- Run required checks before finishing:
  - unit tests
  - lint
  - type-check
- If a required script does not exist, report that explicitly.

## Validation Outcome
- `npm run type-check` in `beeradmin_tail`: pass.
- `npm run lint` in `beeradmin_tail`: failed on many pre-existing project-wide ESLint violations outside this task's files.
- `npx eslint src/lib/taxReport.ts src/views/Pages/TaxReport.vue src/views/Pages/TaxReportEditor.vue src/locales/ja.json src/locales/en.json` in `beeradmin_tail`: pass for changed source files; locale JSON files are ignored by the ESLint config.
- `npx eslint src/lib/taxReport.ts src/views/Pages/TaxReportEditor.vue src/views/Pages/TaxReport.vue` in `beeradmin_tail`: pass after the tax-total fix.
- `npx eslint src/lib/taxReport.ts src/views/Pages/TaxReport.vue src/views/Pages/TaxReportEditor.vue` in `beeradmin_tail`: pass after the list-page total fix.
- `npx eslint src/lib/taxReport.ts src/views/Pages/TaxReport.vue src/views/Pages/TaxReportEditor.vue` in `beeradmin_tail`: pass after the `tax_event` basis change.
- `npx eslint src/lib/taxReport.ts src/views/Pages/TaxReport.vue src/views/Pages/TaxReportEditor.vue` in `beeradmin_tail`: pass after the `1000x` tax-rate normalization fix.
- `npx eslint src/lib/taxReport.ts src/views/Pages/TaxReportEditor.vue src/locales/ja.json src/locales/en.json` in `beeradmin_tail`: pass for code; locale JSON files are ignored by the ESLint config.
- `npx eslint src/views/Pages/TaxReportEditor.vue` in `beeradmin_tail`: pass after adding movement-table sorting.
- `npx eslint src/views/Pages/TaxReport.vue` in `beeradmin_tail`: pass after switching list-page breakdown labels to `税務移出種別`.
- `npx eslint src/views/Pages/TaxReport.vue` in `beeradmin_tail`: pass after limiting the breakdown preview to 3 rows.
- `npx eslint src/views/Pages/ProducedBeer.vue` in `beeradmin_tail`: failed due pre-existing file-level ESLint issues unrelated to this change, including existing `@typescript-eslint/no-explicit-any` and unused-symbol violations.
- `npx eslint src/views/Pages/TaxYearSummary.vue src/locales/ja.json src/locales/en.json` in `beeradmin_tail`: pass for `TaxYearSummary.vue`; locale JSON files are ignored by the ESLint config and report warnings only.
- `npm run test` in `beeradmin_tail`: failed because `package.json` has no `test` script.

## Task Addendum 2026-04-02: Produced Beer Inventory Label Update

### Goal
- Change the `ビール在庫管理` page row-action label from `移出取消` to `国内移出完了`.

### Scope
- Update the Japanese UI label used by the produced beer inventory page action button.
- Align the produced beer inventory page spec with the new displayed label.
- Apply no-behavior-change typing cleanup in the inventory page only if required to satisfy lint validation for this task.

### Non-Goals
- No change to the action key name, backend behavior, or confirmation/success/error message behavior.
- No change to English locale text unless required by the existing implementation.

### Affected Files
- `specs/current-task.md`
- `docs/UI/produced-beer-inventory-management-spec.md`
- `beeradmin_tail/src/locales/ja.json`
- `beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue`

### Data Model / API Changes
- None.

### Planned File Changes
- Append this addendum to capture the scope for the label-only task.
- Update the inventory management UI spec row-action label text.
- Change the Japanese locale value for the produced beer inventory action label.
- Replace pre-existing `any` annotations in the inventory page with local narrow types if lint requires it.

### Final Decisions
- The produced beer inventory page keeps the existing locale key and action wiring, and only the Japanese label text changes to `国内移出完了`.
- The produced beer inventory UI spec mirrors the new label text.
- `ProducedBeerInventory.vue` may receive local typing-only cleanup with no functional change so task-level lint can pass.

### Validation Plan
- Run required checks before finishing:
  - unit tests
  - lint
  - type-check
- If a required script does not exist, report that explicitly.

### Validation Outcome
- `npm run type-check` in `beeradmin_tail`: pass.
- `npm run test` in `beeradmin_tail`: failed because `package.json` has no `test` script.
- `npx eslint src/locales/ja.json` in `beeradmin_tail`: exits with a warning because the locale JSON file is ignored by the current ESLint configuration.
- `npx eslint src/views/Pages/ProducedBeerInventory.vue` in `beeradmin_tail`: pass after replacing pre-existing `any` annotations with narrow local types.
