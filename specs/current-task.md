# Current Task

## Goal
- Remove the paste example hint from the 明細入力 section on the `製品ビール移出(社内移出)` page.

## Scope
- Remove the visible paste example footer hint from `ProductMoveFast.vue`.
- Remove the now-empty footer divider wrapper.
- Keep route form, validation, warnings, and submit behavior unchanged.

## Non-Goals
- Do not change paste handling behavior.
- Do not change line-entry table behavior.
- Do not change route validation behavior.
- Do not change movement submission behavior.
- Do not redesign the rest of the page.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/views/Pages/ProductMoveFast.vue`

## Data Model / API Changes
- No database changes.
- No API changes.
- No stored-function changes.

## Planned File Changes
- Remove the footer block that renders `producedBeer.movementFast.hints.pasteExample`.

## Validation Plan
- Run `git diff --check`.
- Run targeted ESLint on `src/views/Pages/ProductMoveFast.vue`.
- Run `npm run type-check` in `beeradmin_tail`.

## Final Decisions
- Removed the footer block that rendered `producedBeer.movementFast.hints.pasteExample`.
- Removed the footer divider and padding with it.
- Paste handling behavior remains unchanged.

## Validation Results
- `git diff --check` passed.
- `npx eslint src/views/Pages/ProductMoveFast.vue --no-fix` passed.
- `npm run type-check` passed in `beeradmin_tail`.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a unit test script.
