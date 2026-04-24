# Current Task

## Goal
- Exclude non-reportable `tax_event` rows from `LIA110` UI display and generated XML:
  - `NONE`
  - `RETURN_TO_FACTORY_NON_TAXABLE` (`移入`)

## Scope
- Update the shared `LIA110` detail-row filter so `NONE` and `RETURN_TO_FACTORY_NON_TAXABLE` tax events are not converted into report rows.
- Keep legacy fallback behavior for rows where `tax_event` is missing and `move_type` still maps to a valid legacy tax event.
- Update the tax report specs to document that `NONE` and `RETURN_TO_FACTORY_NON_TAXABLE` are not output rows for `LIA110`.

## Non-Goals
- Do not change LIA110 volume/tax calculations for taxable, non-taxable, export, or return rows.
- Do not add a new XML bucket or label for `RETURN_TO_FACTORY_NON_TAXABLE`.
- Do not change LIA130 calculations.
- Do not change Supabase schema or stored report shape.
- Do not redesign the Tax Report Editor UI.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [docs/UI/tax-report-editor.md](/Users/zhao/dev/other/beer/docs/UI/tax-report-editor.md)
- [docs/UI/tax-report-rli0010-232-implementation-spec.md](/Users/zhao/dev/other/beer/docs/UI/tax-report-rli0010-232-implementation-spec.md)
- [beeradmin_tail/src/lib/taxReport.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxReport.ts)

## Data Model / API Changes
- No data model changes.
- No API changes.

## Implementation Notes
- `TaxReportEditor` display rows and XML generation both use `buildLia110ReportRows()`.
- `buildLia110ReportRows()` uses `isLia110DetailItem()` as the shared detail-row gate.
- Filtering `NONE` and `RETURN_TO_FACTORY_NON_TAXABLE` in `isLia110DetailItem()` removes those rows from both UI display and `LIA110` XML.

## Validation Plan
- Run targeted ESLint for touched source files.
- Run frontend type-check.
- Run `git diff --check`.
- Run `npm run test --if-present`.
- Run `npm run build:test`.

## Final Decisions
- `tax_event = NONE` and `tax_event = RETURN_TO_FACTORY_NON_TAXABLE` rows are filtered in `isLia110DetailItem()`.
- Because `TaxReportEditor` and XML generation both use `buildLia110ReportRows()`, this removes those rows from both the movement table and generated `LIA110` XML.
- `RETURN_TO_FACTORY_NON_TAXABLE` is still a valid movement-rule tax event for `移入`; this change only excludes it from tax-report `LIA110` display/XML output.
- Stored source breakdown shape is unchanged; the filtering is output/display behavior only.

## Validation Results
- `npx eslint src/lib/taxReport.ts --no-fix` in `beeradmin_tail`: passed.
- `npm run type-check` in `beeradmin_tail`: passed.
- `git diff --check -- specs/current-task.md docs/UI/tax-report-editor.md docs/UI/tax-report-rli0010-232-implementation-spec.md beeradmin_tail/src/lib/taxReport.ts`: passed.
- `npm run test --if-present` in `beeradmin_tail`: passed with no test script configured.
- `npm run build:test` in `beeradmin_tail`: passed with existing CSS `:is()` minify warnings and existing chunk-size warnings.
