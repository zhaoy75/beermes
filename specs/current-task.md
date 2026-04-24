# Current Task

## Goal
- Add single-column sort and multi-column filters to safe first-batch main-menu list tables.

## Scope
- Add a reusable table control composable for one active sort column plus multiple active column filters.
- Add a reusable table column header component with clickable sort and compact per-column filter controls.
- Apply the pattern to:
  - `移入出登録` movement history table.
  - `酒税申告` report list table.
  - `課税移出一覧表` detail table.
  - `単位マスタ` UOM list table.
  - `パッケージマスタ` package list table.
- Add common locale strings needed by shared table filters.
- Keep existing page-level filters; column filters apply after page-level filters.

## Non-Goals
- Do not implement multi-column sort yet.
- Do not change backend/API query filtering.
- Do not change movement posting logic.
- Do not change route paths or route names.
- Do not add backend schema/API changes.
- Do not change tax report XML behavior.
- Do not refactor unrelated tables or edit/create wizard line tables.
- Do not convert tree/card/board pages to tables.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [docs/UI/product_beer.md](/Users/zhao/dev/other/beer/docs/UI/product_beer.md)
- [beeradmin_tail/src/components/common/TableColumnHeader.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/components/common/TableColumnHeader.vue)
- [beeradmin_tail/src/composables/useColumnTableControls.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/composables/useColumnTableControls.ts)
- [beeradmin_tail/src/views/Pages/ProducedBeer.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/ProducedBeer.vue)
- [beeradmin_tail/src/views/Pages/TaxReport.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/TaxReport.vue)
- [beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue)
- [beeradmin_tail/src/views/Pages/UomMaster.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/UomMaster.vue)
- [beeradmin_tail/src/views/Pages/PackageMaster.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/PackageMaster.vue)
- [beeradmin_tail/src/locales/en.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/en.json)
- [beeradmin_tail/src/locales/ja.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/ja.json)

## Data Model / API Changes
- No data model changes.
- No API changes.

## Implementation Notes
- Header click toggles a single sort column between ascending and descending.
- Column filters are combined with AND logic.
- Filter controls are compact and live in the header cell below the sortable label.
- Filter types in this pass are text contains and select/exact match.
- Existing server/page filters remain unchanged and feed into the column filter/sort pipeline.
- Export actions should use the currently visible filtered/sorted rows when the page already exports visible rows.

## Validation Plan
- Run targeted ESLint for touched Vue/TS files.
- Run frontend type-check.
- Run `git diff --check`.
- Run `npm run test --if-present`.
- Run `npm run build:test`.

## Final Decisions
- Added `useColumnTableControls` for one active sort column plus multiple active column filters.
- Added `TableColumnHeader` to render clickable sort labels and compact text/select filters inside table headers.
- Implemented the first safe batch:
  - `ProducedBeer.vue` movement table.
  - `TaxReport.vue` report list table.
  - `TaxableRemovalReport.vue` detail table.
  - `UomMaster.vue` UOM list table.
  - `PackageMaster.vue` package list table.
- Page-level filters remain unchanged and run before the shared column controls.
- `ProducedBeer.vue` Excel export now uses the visible sorted/filtered rows.
- `TaxableRemovalReport.vue` annual Excel export remains business-year based, not detail-table column-filter based.
- Added `common.clearFilters` in English and Japanese.

## Validation Results
- `npx eslint src/components/common/TableColumnHeader.vue src/composables/useColumnTableControls.ts src/views/Pages/ProducedBeer.vue src/views/Pages/TaxReport.vue src/views/Pages/TaxableRemovalReport.vue src/views/Pages/UomMaster.vue src/views/Pages/PackageMaster.vue --no-fix` in `beeradmin_tail`: passed.
- `npm run type-check` in `beeradmin_tail`: passed.
- `git diff --check -- specs/current-task.md docs/UI/product_beer.md beeradmin_tail/src/components/common/TableColumnHeader.vue beeradmin_tail/src/composables/useColumnTableControls.ts beeradmin_tail/src/views/Pages/ProducedBeer.vue beeradmin_tail/src/views/Pages/TaxReport.vue beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue beeradmin_tail/src/views/Pages/UomMaster.vue beeradmin_tail/src/views/Pages/PackageMaster.vue beeradmin_tail/src/locales/en.json beeradmin_tail/src/locales/ja.json`: passed.
- `npm run test --if-present` in `beeradmin_tail`: passed with no test script configured.
- `npm run build:test` in `beeradmin_tail`: passed with existing CSS `:is()` minify warnings and existing chunk-size warnings.
