# Current Task

## Goal
- Make `年間課税概要` use the Japanese tax-year period from April through March.

## Scope
- Query annual summary data from April 1 of the selected year through March 31 of the following year.
- Render monthly chart data in April-to-March order: `4,5,6,7,8,9,10,11,12,1,2,3`.
- Render batch breakdown month groups in the same April-to-March order.
- Keep existing tax/category calculation logic unchanged.

## Non-Goals
- Do not change database schema or APIs.
- Do not change tax-rate, category, quantity, or money calculations.
- Do not change other report pages.
- Do not change locale text.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/views/Pages/TaxYearSummary.vue`

## Data Model / API Changes
- No database schema changes.
- No application API changes.
- Frontend query date range and display ordering only.

## Validation Plan
- Run `git diff --check -- specs/current-task.md beeradmin_tail/src/views/Pages/TaxYearSummary.vue`.
- Run `npm run type-check` in `beeradmin_tail`.
- Run focused ESLint for `TaxYearSummary.vue`.

## Final Decisions
- Treated the selected year as the Japanese tax-year start year for `年間課税概要`.
- Changed the `inv_movements` query window from calendar year to April 1 through the following April 1.
- Reused the shared April-to-March month order helper for chart series and batch month groups.
- Kept tax, category, quantity, and money calculations unchanged.

## Validation Results
- `git diff --check -- specs/current-task.md beeradmin_tail/src/views/Pages/TaxYearSummary.vue` passed.
- `npm run type-check` passed in `beeradmin_tail`.
- `npx eslint src/views/Pages/TaxYearSummary.vue --no-fix` passed.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a unit test script.
