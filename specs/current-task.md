# Current Task

## Goal
- Rename the four date labels on `バッチ実績入力` to explicitly include `日`.

## Scope
- On the Batch Edit page only, change Japanese field labels:
  - `計画開始` -> `計画開始日`
  - `計画終了` -> `計画終了日`
  - `実績開始` -> `実績開始日`
  - `実績終了` -> `実績終了日`
- Keep the existing locale keys so Vue source bindings do not change.
- Update related Batch Edit UI spec wording.

## Non-Goals
- Do not change database fields.
- Do not change date picker behavior.
- Do not change batch list/create/summary labels unless they use the Batch Edit labels.
- Do not change English labels.

## Affected Files
- `specs/current-task.md`
- `docs/UI/batchedit.md`
- `beeradmin_tail/src/locales/ja.json`

## Data Model / API Changes
- No schema changes.
- No RPC signature changes.
- No persisted data changes.

## Planned File Changes
- Update `batch.edit.plannedStart`, `batch.edit.plannedEnd`, `batch.edit.actualStart`, and `batch.edit.actualEnd` in Japanese locale.
- Update the Batch Edit UI spec to use the same label names.

## Validation Plan
- Run `git diff --check`.
- Parse locale JSON.
- Run `npm run type-check` in `beeradmin_tail`.
- Confirm no unit-test script is available or run it if present.

## Final Decisions
- Updated Japanese `batch.edit` labels to `計画開始日`, `計画終了日`, `実績開始日`, and `実績終了日`.
- Updated the existing Batch Edit packing-navigation validation message to refer to `実績開始日`.
- The Vue template remains unchanged because it already uses the `batch.edit.*` locale keys.
- Batch list/create/summary labels were left unchanged.
- English labels were left unchanged.

## Validation Results
- `git diff --check` passed.
- `src/locales/ja.json` JSON parse check passed.
- `npm run type-check` passed in `beeradmin_tail`.
- `npx eslint src/locales/ja.json` returned no errors; ESLint reported the JSON file is ignored by the project config.
- `npx eslint . --no-fix` failed on existing unrelated lint errors across legacy components and pages.
- Unit tests were not run because `beeradmin_tail/package.json` has no `test`, `unit`, or `test:unit` script.
