# Current Task

## Goal
- Make the top summary and `工程実行コントロール` sections on `BatchStepExecution` more compact.

## Scope
- Reduce vertical space usage in the top summary section.
- Reduce vertical space usage in the `工程実行コントロール` section.
- Keep the same fields, actions, and save behavior.
- Limit this task to layout / spacing / density changes in those two sections.

## Non-Goals
- Do not change schema.
- Do not change step save behavior.
- Do not change materials, outputs, equipment, QA, deviation, or execution-log sections.
- Do not refactor unrelated page structure outside the top summary and execution control sections.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [specs/batch-step-execution-page.md](/Users/zhao/dev/other/beer/specs/batch-step-execution-page.md)
- [beeradmin_tail/src/views/Pages/BatchStepExecution.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchStepExecution.vue)

## Data Model / API Changes
- None.

## Final Decisions
- The summary area uses denser cards, smaller heading text, and reduced section padding so more step context fits above the fold.
- The execution control section keeps the same inputs but uses a tighter grid, shorter field heights, and a smaller notes area.
- This task is visual only and must not change data handling.

## Validation Plan
- Run:
  - `npx eslint src/views/Pages/BatchStepExecution.vue --no-fix` in `beeradmin_tail`
  - `npm run type-check` in `beeradmin_tail`
  - `npm run lint` in `beeradmin_tail`
  - `npm run test` in `beeradmin_tail`

## Validation Results
- `npx eslint src/views/Pages/BatchStepExecution.vue --no-fix`: passed
- `npm run type-check`: passed
- `npm run lint`: failed with the same 315 pre-existing repo-wide ESLint errors outside this task
- `npm run test`: failed because `beeradmin_tail/package.json` has no `test` script
