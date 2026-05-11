# Current Task

## Goal
- Show 詰口一覧表 `最終充填日` as a date-only value on screen and in Excel export.

## Scope
- Main Filling Report table should display `最終充填日` without time.
- Excel summary sheet should export `最終充填日` without time.
- Keep sorting and filtering based on the original latest filling timestamp.
- Keep detail-row `日付` values as datetime because they are movement event timestamps.

## Non-Goals
- Do not change database schema or stored values.
- Do not change movement timestamp capture.
- Do not change detail sheet movement `日付` datetime display.
- Do not change tax/report stored functions.

## Affected Files
- `specs/current-task.md`
- `docs/UI/filling-report.md`
- `beeradmin_tail/src/views/Pages/FillingReport.vue`

## Data Model / API Changes
- No schema changes.
- No RPC signature changes.
- No persisted data changes.

## Planned File Changes
- Add/use a date-only formatter for the main report `最終充填日`.
- Use the same date-only formatter in the Excel summary sheet.
- Update the Filling Report UI spec to distinguish `最終充填日` date-only display from detail movement datetime display.

## Validation Plan
- Run `git diff --check`.
- Run `npm run type-check` in `beeradmin_tail`.
- Run focused ESLint on changed files.

## Final Decisions
- `最終充填日` keeps using the latest `inv_movements.movement_at` timestamp for source, sorting, and filtering.
- Main report table display now formats `最終充填日` as date only.
- Excel summary sheet now exports `最終充填日` as date only.
- Detail movement `日付` remains datetime because it represents each movement event timestamp.

## Validation Results
- `git diff --check` passed.
- `npm run type-check` passed in `beeradmin_tail`.
- `npx eslint src/views/Pages/FillingReport.vue` passed.
- Unit tests were not run because `beeradmin_tail/package.json` has no `test`, `unit`, or `test:unit` script.
