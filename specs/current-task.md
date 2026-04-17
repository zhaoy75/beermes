# Current Task

## Goal
- Hide the `工程実行一覧` section on the `バッチ実績入力` page when `VITE_DEVELOPMENT_MODE` is false.

## Scope
- Update the batch edit page to conditionally hide the step execution section by the existing development-mode flag.
- Prevent the under-development step execution detail page from being directly reachable when development mode is disabled.
- Keep the rest of the batch edit page behavior unchanged.

## Non-Goals
- Do not redesign the `バッチ実績入力` page layout.
- Do not change the `工程実行一覧` implementation itself.
- Do not change unrelated routing, packing, lot DAG, or batch save behavior.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [beeradmin_tail/src/views/Pages/BatchEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchEdit.vue)
- [beeradmin_tail/src/router/tenant-routes.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/router/tenant-routes.ts)

## Data Model / API Changes
- No data model changes.
- No API changes.
- Route metadata will mark the step execution detail page as development-only.

## Implementation Notes
- Reuse the existing `DEVELOPMENT_MODE_ENABLED` helper in `src/lib/devMode.ts`.
- Hide the `工程実行一覧` section entirely when development mode is off.
- Skip loading step execution summary data on the batch edit page when the section is hidden.
- Add `requiresDevelopmentMode: true` to the batch step execution detail route so the existing router guard blocks direct access when development mode is off.

## Final Decisions
- Hide the `工程実行一覧` section on `BatchEdit` by checking the existing `DEVELOPMENT_MODE_ENABLED` flag.
- Skip loading execution summary data when that section is hidden so the page does not make unnecessary MES execution queries in non-development mode.
- Mark the `batchStepExecution` route as `requiresDevelopmentMode: true` so direct access is blocked by the existing router guard when development mode is disabled.

## Validation Plan
- Run targeted ESLint for the touched frontend files.
- Run frontend type-check.
- Run the frontend unit test command if available; otherwise document that no test script exists.

## Validation Results
- `npx eslint src/views/Pages/BatchEdit.vue src/router/tenant-routes.ts --no-fix` in `beeradmin_tail`: passed.
- `npm run type-check` in `beeradmin_tail`: passed.
- `npm run test` in `beeradmin_tail`: failed because `package.json` does not define a `test` script.
