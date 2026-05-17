# Current Task

## Goal
- Move the `税務移出種別` column to the left of `バッチコード` on the `移入出登録` movement result table.

## Scope
- Reorder the movement result table so `税務移出種別` appears immediately before `バッチコード`.
- Keep the existing sort and filter behavior for both columns.
- Keep movement row selection, actions, and underlying data unchanged.
- Keep exported movement columns in the same order as the on-screen table.

## Non-Goals
- Do not change movement query, create, reverse, or selection behavior.
- Do not add, remove, or rename result columns.
- Do not change `ProductMoveFast.vue`.
- Do not change database schema or APIs.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/views/Pages/ProducedBeer.vue`

## Data Model / API Changes
- No database schema changes.
- No application API changes.
- Frontend table/export column-order changes only for `移入出登録`.

## Validation Plan
- Run `git diff --check -- specs/current-task.md beeradmin_tail/src/views/Pages/ProducedBeer.vue`.
- Run `npm run type-check` in `beeradmin_tail`.
- Run focused ESLint for `ProducedBeer.vue`.

## Planned File Changes
- `ProducedBeer.vue`: move the `taxEvent` header/body cell before `batchCode`, and reorder the movement sort-key/control/export definitions to match.
- `specs/current-task.md`: document scope, validation, and final decisions.

## Final Decisions
- Moved the `税務移出種別` table header to immediately after `移出日` and before `バッチコード`.
- Moved the `税務移出種別` table body cell to the same position.
- Reordered the movement table sort keys and column filter controls so saved/filterable column behavior matches the visible table order.
- Reordered the movement Excel export columns to match the on-screen movement table order.
- Kept movement query, row actions, selection, and source data unchanged.

## Validation Results
- `git diff --check -- specs/current-task.md beeradmin_tail/src/views/Pages/ProducedBeer.vue` passed.
- `npm run type-check` passed in `beeradmin_tail`.
- `npx eslint src/views/Pages/ProducedBeer.vue --no-fix` passed.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a unit test script.
