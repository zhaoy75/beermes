# Current Task

## Goal
- Prevent `移入出登録` from calling the server while `開始日` / `終了日` are being edited.

## Scope
- Stop automatic movement reloads on `開始日` and `終了日` model changes.
- Add an explicit search action for applying date range changes.
- Keep other existing filter behavior and movement table behavior unchanged.

## Non-Goals
- Do not change database schema or APIs.
- Do not change movement query semantics.
- Do not refactor unrelated `ProducedBeer.vue` sections.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/views/Pages/ProducedBeer.vue`

## Data Model / API Changes
- No database schema changes.
- No application API changes.
- Frontend filter interaction change only.

## Validation Plan
- Run `git diff --check -- specs/current-task.md beeradmin_tail/src/views/Pages/ProducedBeer.vue`.
- Run `npm run type-check` in `beeradmin_tail`.
- Run focused ESLint for `ProducedBeer.vue`.

## Final Decisions
- Removed `開始日` and `終了日` from the auto-fetch watcher.
- Added an explicit `検索` button to apply date range changes by calling `fetchMovements()`.
- Kept `税務移出のみ`, `取消済みを表示`, and movement type changes on the existing auto-refresh behavior.
- Made Reset explicitly reload movements after restoring default filters.

## Validation Results
- `git diff --check -- specs/current-task.md beeradmin_tail/src/views/Pages/ProducedBeer.vue` passed.
- `npm run type-check` passed in `beeradmin_tail`.
- `npx eslint src/views/Pages/ProducedBeer.vue --no-fix` passed.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a unit test script.
