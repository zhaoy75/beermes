# Current Task

## Goal
- Add a bulk-processing mechanism on `ビール在庫管理` for `国内移出完了` only.

## Scope
- Add row selection to the produced beer inventory table.
- Allow row selection for visible inventory rows, including when only one row is visible.
- Add a bulk action bar that applies `国内移出完了` only to selected eligible rows.
- Keep the existing single-row action menu behavior unchanged.

## Non-Goals
- Do not add bulk processing for `解体`, `関連履歴`, or any other action.
- Do not change inventory aggregation/query semantics.
- Do not change database schema or stored functions.
- Do not change date, quantity, money, or tax calculation rules.
- Do not touch the produced beer movement register page.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue`
- `beeradmin_tail/src/locales/ja.json`
- `beeradmin_tail/src/locales/en.json`
- `specs/domestic-removal-complete-redesign.md`
- `docs/UI/produced-beer-inventory-management-spec.md`

## Data Model / API Changes
- No database schema changes.
- No API changes.
- Bulk processing reuses the existing `domestic_removal_complete` RPC per selected lot/site target.

## Validation Plan
- Run `git diff --check -- specs/current-task.md specs/domestic-removal-complete-redesign.md docs/UI/produced-beer-inventory-management-spec.md beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue beeradmin_tail/src/locales/ja.json beeradmin_tail/src/locales/en.json`.
- Run `npm run type-check` in `beeradmin_tail`.
- Run focused ESLint on `src/views/Pages/ProducedBeerInventory.vue`.

## Planned File Changes
- `ProducedBeerInventory.vue`: add row selection, select-all for visible rows, a bulk `国内移出完了` action bar, and sequential RPC execution for eligible selected rows with one confirmation.
- Locale files: add labels/messages for selected count, clear selection, and bulk confirmation/success/failure.
- `domestic-removal-complete-redesign.md`: document row checkbox and bulk-processing behavior for `国内移出完了`.
- `produced-beer-inventory-management-spec.md`: document the source files and the row-selection/bulk `国内移出完了` UI behavior.

## Final Decisions
- Added a checkbox column to the `ビール在庫管理` table.
- Enabled row selection for visible rows, including non-eligible rows and single-row result sets.
- Added select-all behavior for currently visible rows.
- Added a bulk action bar that appears when rows are selected; the `国内移出完了` button is disabled if none of the selected rows are eligible.
- Kept bulk processing limited to `国内移出完了`; `解体` and `関連履歴` remain single-row actions.
- Reused the existing `domestic_removal_complete` RPC sequentially for each deduplicated selected lot/site target.
- Disabled row actions while bulk processing is running to avoid concurrent actions.
- Updated the durable domestic removal design spec with the new row-selection and bulk-execution behavior.
- Updated the main produced beer inventory UI spec with source file references and the current selection/bulk behavior.

## Validation Results
- `git diff --check -- specs/current-task.md beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue beeradmin_tail/src/locales/ja.json beeradmin_tail/src/locales/en.json` passed.
- `git diff --check -- specs/current-task.md specs/domestic-removal-complete-redesign.md beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue beeradmin_tail/src/locales/ja.json beeradmin_tail/src/locales/en.json` passed after updating the durable spec.
- `git diff --check -- specs/current-task.md specs/domestic-removal-complete-redesign.md docs/UI/produced-beer-inventory-management-spec.md beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue beeradmin_tail/src/locales/ja.json beeradmin_tail/src/locales/en.json` passed after updating the UI spec.
- `npm run type-check` passed in `beeradmin_tail`.
- `npx eslint src/views/Pages/ProducedBeerInventory.vue --no-fix` passed.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a unit test script.
