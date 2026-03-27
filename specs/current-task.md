# Current Task Spec

## Goal
- Add Excel export to the tenant-scoped Vue page `課税移出一覧表`.
- When the user clicks the export button, generate an `.xlsx` file in the browser, expose a download link, and name the file `課税移出一覧表_<business-year>.xlsx`.
- Include one summary sheet plus one sheet for each month in the selected business year.

## Scope
- Frontend only.
- Add an export action button to `課税移出一覧表`.
- Generate a downloadable Excel workbook client-side using the existing workbook helper pattern already used in the repo.
- Show a download link after the workbook is generated.
- Workbook sheet contents:
  - first sheet: same data as the page `年度サマリー`
  - one sheet per month in the selected business year
- Monthly sheets must ignore the current page `month` and `酒類コード` filter inputs and instead include all detail rows for that calendar month within the selected business year.
- Keep the current page filtering, summary rendering, and data loading logic intact outside the export feature.

## Non-Goals
- Adding backend export endpoints, storage uploads, or server-side file generation.
- Changing persisted data, RPCs, or schema.
- Changing the detail table shown on screen to ignore current filters.
- Refactoring unrelated reports.

## Affected Files
- `specs/current-task.md`
- `docs/UI/tax-removal-report.md`
- `beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue`
- `beeradmin_tail/src/locales/ja.json`
- `beeradmin_tail/src/locales/en.json`

## Data Model / API Changes
- No backend or API changes.
- Reuse the already loaded report data in memory.
- Use the selected `年度` as the business-year basis for export file naming and sheet data.
- Summary sheet uses the same grouped rows as the on-screen summary for the selected `年度`.
- Monthly detail sheets derive from all detail rows in memory that belong to the selected `年度` and the target calendar month, regardless of the current search section values for `month` and `酒類コード`.

## Workbook Decisions
- File name format: `課税移出一覧表_<business-year>.xlsx`
- Sheet order:
  - first: summary sheet
  - then months `4` through `12`
  - then months `1` through `3`
- Summary sheet contents:
  - title
  - generated timestamp
  - selected business year
  - the same columns and row values as `年度サマリー`
- Monthly sheet contents:
  - month label and generated timestamp
  - the same columns and row values as `課税移出明細`
  - all matching rows for that month in the selected business year
- Sheet names should remain short and Excel-safe.
- If a monthly sheet has no rows, still create it with headers and no data rows.

## Final Decisions
- Reused the existing client-side workbook generator in `beeradmin_tail/src/lib/fillingReportExport.ts`; no new dependency was added.
- Added an `Excel Export` button and a generated download link on `課税移出一覧表`.
- Export file name is implemented as `課税移出一覧表_<selected-business-year>.xlsx`.
- The summary sheet uses the same selected-business-year summary rows shown on screen.
- Monthly sheets are generated for all twelve months in business-year order and ignore the current page `month` and `酒類コード` filter values.
- The export link is cleared when the selected business year changes, when the report reloads, and on component unmount so stale downloads are not shown.

## Validation Plan
- Confirm the page shows an export button.
- Confirm clicking export generates a download link on the page.
- Confirm the generated file name matches `課税移出一覧表_<business-year>.xlsx`.
- Confirm the workbook includes:
  - one summary sheet
  - twelve monthly sheets for the selected business year
- Confirm the summary sheet matches the on-screen `年度サマリー`.
- Confirm each monthly sheet includes all rows for that month in the selected business year even when the page `month` or `酒類コード` filter is set.
- Run required checks before finishing:
  - unit tests
  - lint
  - type-check
- Repository note:
  - if no unit test script exists, report that explicitly.

## Validation Outcome
- `npm run type-check` in `beeradmin_tail`: passed.
- `npm run lint` in `beeradmin_tail`: failed due to pre-existing repo-wide ESLint violations unrelated to this task.
- `npm exec eslint src/views/Pages/TaxableRemovalReport.vue` in `beeradmin_tail`: passed.
- locale JSON parse check for `src/locales/ja.json` and `src/locales/en.json`: passed.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a test script.

## Planned File Changes
- `specs/current-task.md`
  - replace the previous task scope with the taxable-removal Excel export spec
- `docs/UI/tax-removal-report.md`
  - document the new export action and workbook structure
- `beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue`
  - add export button, download link, and client-side workbook generation
- `beeradmin_tail/src/locales/ja.json`
  - add export labels and messages
- `beeradmin_tail/src/locales/en.json`
  - add export labels and messages
