# Current Task

## Goal
- Add `酒類分類` to the `移入出登録` movement table.
- Add the same `酒類分類` column to the movement Excel export.

## Scope
- Update the `/producedBeer` page movement list table.
- Use the existing movement line `categoryId` and alcohol-type label resolver.
- Add column filtering/sorting support where consistent with the existing table controls.
- Update the movement Excel export rows and header.
- Reuse existing locale labels.

## Non-Goals
- Do not change movement registration/save behavior.
- Do not change inventory table columns.
- Do not change backend SQL or RPC functions.
- Do not change tax report logic.
- Do not modify unrelated lint debt or existing unrelated worktree changes.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/views/Pages/ProducedBeer.vue`

## Data Model / API Changes
- No database schema changes.
- No API/RPC changes.
- No Excel file format change beyond adding one visible column.

## Planned File Changes
- Add a `酒類分類` table header and cell to the movement list.
- Add a `beerCategory` movement column filter/sort key if the table needs it.
- Add `酒類分類` to the movement Excel export header and row data.
- Keep Excel export through the existing workbook generator.

## Validation Plan
- Run focused `git diff --check`.
- Run `npm run type-check` in `beeradmin_tail`.
- Run focused ESLint for `src/views/Pages/ProducedBeer.vue`.

## Final Decisions
- Added a `酒類分類` column to the `/producedBeer` movement table after `バッチコード`.
- The new table column supports the existing per-column text filtering and sorting controls.
- Added `酒類分類` to the movement Excel export in the same position as the table.
- Reused existing alcohol-type registry labels and existing locale key `producedBeer.inventory.table.beerCategory`; no locale file change was needed.

## Validation Results
- `git diff --check -- specs/current-task.md beeradmin_tail/src/views/Pages/ProducedBeer.vue` passed.
- `npm run type-check` passed in `beeradmin_tail`.
- `npx eslint src/views/Pages/ProducedBeer.vue --no-fix` passed.
- `npx eslint . --no-fix` failed on pre-existing unrelated lint issues outside this change, including missing Vue `lang` attributes, unused variables, component naming, and `any` usage.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a unit test script.
