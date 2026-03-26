# Current Task Spec

## Goal
- Create a tenant-scoped Vue report page named `課税移出一覧表`.
- Expose the page under `税務管理 > 帳票一覧`.
- Show all taxable-removal records derived from `inv_movements` and `inv_movement_lines`.
- Provide a business-year summary grouped by `酒類コード` and `ABV`.
- Provide a searchable detail table of taxable-removal records.

## Scope
- Frontend only.
- Replace the previous current-task scope with this new taxable-removal report task.
- Add a UI specification document for the new page under `docs/UI`.
- Add one new route, one new page component, and the related sidebar/i18n entries.
- Add a search section with:
  - `年度`
  - `month`
  - `酒類コード`
- Add a business-year summary section above the detail table.
- Add a detail table for taxable-removal records.
- Keep the page read-only in v1.

## Non-Goals
- Creating, editing, reversing, or deleting product movements from this report.
- Adding Excel export in this task.
- Adding new backend RPCs, SQL functions, or schema changes.
- Refactoring unrelated tax-management pages.

## Affected Files
- `specs/current-task.md`
- `docs/UI/tax-removal-report.md`
- `beeradmin_tail/src/router/tenant-routes.ts`
- `beeradmin_tail/src/components/layout/AppSidebar.vue`
- `beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue`
- `beeradmin_tail/src/locales/ja.json`
- `beeradmin_tail/src/locales/en.json`
- Optional extraction only if implementation becomes materially simpler:
  - `beeradmin_tail/src/lib/taxRemovalReport.ts`

## Data Model / API Changes
- No backend schema change in v1.
- No new RPC in v1.

### Source-of-Truth Decision
- This page must use `inv_movements` and `inv_movement_lines` as the transactional source of truth.
- Taxable-removal filtering must be based on persisted tax movement metadata, not Japanese display text.
- Include movement rows when either of the following is true:
  - `inv_movements.meta->>'tax_event' = 'TAXABLE_REMOVAL'`
  - fallback: `inv_movements.meta->>'tax_decision_code' = 'TAXABLE_REMOVAL'`
- Exclude void rows:
  - `inv_movements.status != 'void'`
- Supporting master/detail lookups are allowed for display fields:
  - `mes_batches`
  - `mst_package`
  - `mst_sites`
  - `mst_uom`
  - `registry_def` kind=`alcohol_type`
  - `entity_attr` / `attr_def`
  - `lot` when `src_lot_id` exists in line meta and lot number display is needed

### Row Granularity
- Business-year summary:
  - one row per `酒類コード + ABV` group
- Detail table:
  - one row per taxable-removal `inv_movement_lines` row
  - rows without package or batch context may still appear if the required detail fields can be resolved from movement/line data

### Search / Filter Rules
- `年度`
  - required visible field
  - default: current business year
  - business year definition: April 1 to March 31
- `month`
  - values: `1` to `12`
  - default: blank
  - interpreted as calendar month inside the selected business year range
- `酒類コード`
  - default: blank
  - filters by the code value shown in the page
- Summary section filter scope:
  - use the selected `年度` only
  - do not narrow summary rows by `month`
  - do not narrow summary rows by `酒類コード`
- Detail table filter scope:
  - use selected `年度`
  - use selected `month` when not blank
  - use selected `酒類コード` when not blank

### Column Mapping
#### Summary Section
- `酒類コード`
  - resolve from batch/category metadata using the same order already used in produced-beer pages:
    - batch attribute `beer_category`
    - recipe/category fallback
    - `mes_batches.meta.beer_category`
    - `mes_batches.meta.category`
- `ABV`
  - resolve from batch metadata using the same order already used in produced-beer pages:
    - batch attribute `target_abv`
    - recipe target ABV
    - `mes_batches.meta.target_abv`
- `数量(ml)`
  - sum taxable-removal line quantity converted to milliliters
  - primary source: `inv_movement_lines.qty` using `uom_id` / `mst_uom.code`
  - fallback: package count × package unit volume when line quantity is missing but package quantity and package master are available
- `存在数`
  - sum package-count style value per line
  - prefer `inv_movement_lines.meta.package_qty`
  - fallback to `inv_movement_lines.unit`
- `税率`
  - use persisted `inv_movement_lines.tax_rate`
  - fallback: `inv_movements.meta.tax_rate`
  - display as raw numeric `/kl` rate
- `酒税`
  - calculate from taxable-removal volume and rate
  - formula: `quantity_ml / 1000000 * tax_rate`
  - aggregate by `酒類コード + ABV`

#### Detail Table
- `品目`
  - alcohol type label resolved from `registry_def.kind = 'alcohol_type'` for the displayed `酒類コード`
  - fallback to raw `酒類コード`
- `銘柄`
  - `mes_batches.product_name`
  - fallback: `mes_batches.batch_label`
  - fallback: batch/style name resolved on the produced-beer pages
- `アルコール分（％）`
  - displayed ABV value for the line
- `年月日`
  - `inv_movements.movement_at`
- `容器`
  - `mst_package.package_code`
  - fallback: package localized name
- `数量（mℓ）`
  - line quantity converted to milliliters using the same conversion rule as summary
- `単価（円）`
  - blank in v1
- `価格（円）`
  - blank in v1
- `移出区分`
  - tax event display label for the movement
  - for this page it should normally display `課税移出`
- `移出先所在地`
  - `mst_sites.address` formatted into a readable single-line string
  - fallback: blank when address is missing
- `移出先氏名又は名称`
  - `mst_sites.name`
- `ロット番号`
  - prefer source lot number resolved from `lot.id = inv_movement_lines.meta.src_lot_id`
  - fallback: `mes_batches.batch_code`
- `摘要`
  - prefer `inv_movement_lines.notes`
  - fallback: `inv_movement_lines.meta.line_note`
  - fallback: `inv_movements.notes`

## UI / Navigation
- Add a new tax-management submenu path:
  - parent: `税務管理`
  - child group: `帳票一覧`
  - page item: `課税移出一覧表`
- New route:
  - path: `/taxableRemovalReport`
  - name: `TaxableRemovalReport`
  - component: `@/views/Pages/TaxableRemovalReport.vue`
- Page shell should match existing admin pages:
  - `PageBreadcrumb`
  - page title and subtitle
  - search section
  - top-level refresh action

## Page Behavior
- Load report data on mount.
- Restrict all reads to the current tenant.
- Default detail-table sort:
  - `年月日` descending
  - tie-breaker by document/line order when needed
- Search section fields:
  - `年度`
  - `month`
  - `酒類コード`
- Summary section:
  - displayed above the detail table
  - grouped by `酒類コード` and `ABV`
  - calculated from the selected business year only
- Detail table:
  - shows all matching taxable-removal line rows
  - updates based on selected `年度`, `month`, and `酒類コード`
- Empty state:
  - show standard no-data state when no records match
- Error handling:
  - clear rows on fatal fetch failure
  - show toast with the error message

## Implementation Notes
- Prefer reusing existing produced-beer movement helpers/patterns for:
  - tenant resolution
  - batch beer-category and ABV resolution
  - UOM to liters conversion
  - tax-event label mapping
- Milliliter conversion must support at least:
  - `L`
  - `mL`
  - `kL`
  - `gal_us`
- If `mst_sites.address` is stored as structured JSON, format it by joining non-empty string values in field order.
- Keep implementation scoped:
  - no server-side filtering beyond the taxable-removal movement query itself
  - no pagination unless the dataset size immediately requires it

## Validation Plan
- Functional validation:
  - confirm the page appears under `税務管理 > 帳票一覧`
  - confirm the route opens successfully
  - confirm the search section shows `年度`, `month`, and `酒類コード`
  - confirm `年度` defaults to the current business year based on April 1 to March 31
  - confirm `month` defaults to blank
  - confirm only taxable-removal movements appear
  - confirm summary rows are grouped by `酒類コード` and `ABV`
  - confirm summary uses selected `年度` only
  - confirm detail table uses selected `年度`, `month`, and `酒類コード`
  - confirm `数量(ml)` and detail `数量（mℓ）` convert from persisted movement quantity correctly
  - confirm `税率` is read from persisted movement-line/header tax rate
  - confirm `酒税` is calculated from `mL -> kL` conversion and tax rate
  - confirm `単価（円）` and `価格（円）` remain blank
  - confirm destination name/address and lot number degrade gracefully when missing
- Required checks before finishing implementation:
  - unit tests
  - lint
  - type-check
- Repository note:
  - `beeradmin_tail/package.json` currently defines `type-check` and `lint`
  - no dedicated unit test script is currently defined, so this must be reported explicitly unless one is added as part of implementation

## Planned File Changes
- `specs/current-task.md`
  - replace the previous task scope with the taxable-removal report spec
- `docs/UI/tax-removal-report.md`
  - add the dedicated UI specification for `課税移出一覧表`
- `beeradmin_tail/src/router/tenant-routes.ts`
  - add the new report route
- `beeradmin_tail/src/components/layout/AppSidebar.vue`
  - add `帳票一覧 > 課税移出一覧表` under `税務管理`
- `beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue`
  - add the new report page and report loading logic
- `beeradmin_tail/src/locales/ja.json`
  - add sidebar/page labels in Japanese
- `beeradmin_tail/src/locales/en.json`
  - add sidebar/page labels in English

## Open Decisions / Risks
- `movement type = 課税移出` is a UI/business label, while persisted data uses `tax_event` / `tax_decision_code`; implementation must not filter by translated text.
- Some historical movement rows may lack `meta.src_lot_id`, `meta.package_qty`, destination address, or line notes; the page must degrade gracefully.
- If some line quantities are stored in unusual UOMs, summary/detail quantity conversion depends on correct `mst_uom.code` mapping.
- `存在数` is interpreted in v1 as package count, using `meta.package_qty` first and `unit` as fallback.

## Final Decisions
- Added a dedicated UI specification document at `docs/UI/tax-removal-report.md`.
- Implemented the new report page at `beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue`.
- Added the new tenant route:
  - `/taxableRemovalReport`
  - route name: `TaxableRemovalReport`
- Added the new sidebar navigation path under:
  - `税務管理 > 帳票一覧 > 課税移出一覧表`
- The implemented page uses:
  - `inv_movements` and `inv_movement_lines` as the taxable-removal source of truth
  - `mes_batches` plus batch attributes for `酒類コード`, `銘柄`, and `ABV`
  - `mst_package` and `mst_uom` for package label and quantity conversion
  - `mst_sites` for destination site name and address
  - `lot` for lot number fallback when `src_lot_id` exists
- Taxable-removal filtering is implemented by persisted tax metadata:
  - `meta.tax_event = 'TAXABLE_REMOVAL'`
  - fallback: `meta.tax_decision_code = 'TAXABLE_REMOVAL'`
- The summary section is implemented as a business-year aggregation grouped by `酒類コード` and `ABV`.
- The detail table is implemented as one row per taxable-removal movement line filtered by `年度`, `month`, and `酒類コード`.
- `数量(ml)` and `数量（mℓ）` are derived from persisted line quantity with UOM conversion, with package-volume fallback when needed.
- `税率` is read from persisted movement-line tax rate with movement-header fallback.
- `酒税` is calculated as `quantity_ml / 1000000 * tax_rate`.
- `単価（円）` and `価格（円）` are intentionally rendered blank in v1.
- Validation outcome:
  - `npm run type-check` in `beeradmin_tail`: passed
  - `npm exec eslint src/views/Pages/TaxableRemovalReport.vue src/router/tenant-routes.ts src/components/layout/AppSidebar.vue` in `beeradmin_tail`: passed
  - locale JSON parse check for `src/locales/ja.json` and `src/locales/en.json`: passed
  - `npm run test` in `beeradmin_tail`: failed because `package.json` does not define a `test` script
