# Current Task

## Goal
- Decrease the height of the `サマリー` panel on the `製品ビール移出(社内移出)` page.

## Scope
- Compact the right-side summary panel in `ProductMoveFast.vue`.
- Reduce panel padding, row spacing, section spacing, and text sizes where appropriate.
- Remove the helper subtitle below `サマリー` to save height.
- Keep all summary, validation, warning, and manual-mode information visible.

## Non-Goals
- Do not change summary calculations.
- Do not change validation or warning behavior.
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
- Reduce summary panel padding and internal vertical spacing.
- Remove the summary helper subtitle.
- Use smaller text and tighter spacing for summary rows, validation, warnings, and manual-mode hint.

## Validation Plan
- Run `git diff --check`.
- Run targeted ESLint on `src/views/Pages/ProductMoveFast.vue`.
- Run `npm run type-check` in `beeradmin_tail`.

## Final Decisions
- The summary panel card now uses `p-3 space-y-2` instead of `p-4 space-y-4`.
- Removed the helper subtitle below the `サマリー` heading.
- Summary rows now use `text-xs`, `space-y-1`, and tighter horizontal gaps.
- Validation and warning sections now use smaller headings, tighter spacing, and `text-xs` messages.
- Manual-mode hint padding and text size were reduced.

## Validation Results
- `git diff --check` passed.
- `npx eslint src/views/Pages/ProductMoveFast.vue --no-fix` passed.
- `npm run type-check` passed in `beeradmin_tail`.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a unit test script.
