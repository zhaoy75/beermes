# Current Task

## Goal
- Rename the 移送詰口管理 filling calculation mode labels:
  - `残量で詰める` -> `欠減容量なし`
  - `タンク深さ測定で詰める` -> `欠減容量あり`

## Scope
- Change display labels only.
- Keep existing mode keys:
  - `ignore_loss`
  - `calculate_loss`
- Update UI spec text so the documentation matches the new labels.

## Non-Goals
- Do not change calculation behavior.
- Do not change saved metadata values.
- Do not change database schema, RPCs, or stored functions.
- Do not change the surrounding form layout.

## Affected Files
- `specs/current-task.md`
- `docs/UI/batchpacking.md`
- `beeradmin_tail/src/locales/en.json`
- `beeradmin_tail/src/locales/ja.json`

## Data Model / API Changes
- No schema changes.
- No API changes.
- `tank_loss_calc_mode` values remain `ignore_loss` and `calculate_loss`.

## Planned File Changes
- Update Japanese locale labels.
- Update English locale labels with equivalent wording.
- Update `docs/UI/batchpacking.md` references to the new Japanese labels.

## Validation Plan
- Run `git diff --check`.
- Parse locale JSON files.
- Run `npm run type-check` in `beeradmin_tail`.

## Final Decisions
- Japanese labels were changed to `欠減容量なし` and `欠減容量あり`.
- English labels were changed to `No Loss Volume` and `With Loss Volume`.
- Internal values remain `ignore_loss` and `calculate_loss`.
- No calculation behavior changed.

## Validation Results
- `git diff --check` passed.
- Locale JSON parse check passed for `src/locales/en.json` and `src/locales/ja.json`.
- `npm run type-check` passed in `beeradmin_tail`.
- No unit test script is defined in `beeradmin_tail/package.json`.
