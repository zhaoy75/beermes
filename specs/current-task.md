# Current Task Spec

## Goal
- Change the `酒税申告` page list view from card-based display to table-based display.
- Keep the underlying data loading, create/edit flow, and XML behavior unchanged.

## Scope
- Frontend only.
- Update `beeradmin_tail/src/views/Pages/TaxReport.vue`.
- Update `docs/UI/tax-report.md` so the document matches the new list layout.

## Non-Goals
- No backend, database, RPC, or schema changes.
- No change to tax-report generation logic.
- No change to modal edit behavior.
- No cleanup of unrelated repo-wide lint issues.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/views/Pages/TaxReport.vue`
- `docs/UI/tax-report.md`

## Data Model / API Changes
- None.
- Saved rows continue to come from `tax_reports`.

## Fix Decisions
- Replace the saved-report card list with one table.
- Keep the same visible information as the current cards:
  - tax type
  - period
  - status
  - total tax
  - breakdown summary
  - XML files
  - attachments
  - actions
- Keep row actions as `XML生成` and `Edit`.
- Update the UI document so it describes a table instead of cards.

## Final Decisions
- Replaced the list section in `TaxReport.vue` with a horizontally scrollable table.
- Kept the same data fields and row actions, only changing their presentation.
- Added wrapped multi-line cells for breakdown, XML files, and attachments so the table remains readable.
- Updated `docs/UI/tax-report.md` so page layout and field definitions now describe table rows rather than cards.

## Validation Plan
- Confirm the saved report list renders as a table.
- Confirm table rows still show the same information as the prior cards.
- Confirm row actions still open XML generation and edit flows.
- Confirm type-check passes.
- Confirm targeted lint for `TaxReport.vue` passes.
- Run required checks before finishing:
  - unit tests
  - lint
  - type-check
- Repository note:
  - if no unit test script exists, report that explicitly.

## Validation Outcome
- `npm run type-check` in `beeradmin_tail`: passed.
- `npm exec eslint src/views/Pages/TaxReport.vue` in `beeradmin_tail`: passed.
- `npm run lint` in `beeradmin_tail`: still fails due to pre-existing repo-wide ESLint issues unrelated to this task.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a test script.
- Manual template review confirmed the list section now renders as a table and keeps the same row actions.

## Planned File Changes
- `specs/current-task.md`
  - replace the prior enrichment-source spec with this table-layout spec
- `beeradmin_tail/src/views/Pages/TaxReport.vue`
  - convert the saved report list from cards to a table
- `docs/UI/tax-report.md`
  - update the layout and field descriptions from card list to table list
