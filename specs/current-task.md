# Current Task

## Goal
- Fix step completion for backflush inputs so `工程入力の保存` does not fail with `BSBC011` when the batch is missing site metadata.

## Scope
- Update the batch-step execution spec to clarify how backflush source site resolution works.
- Update `BatchStepExecution.vue` to resolve a backflush source site from available execution context and pass it to the completion RPC.
- Update `public.batch_step_complete_backflush` to accept an explicit `source_site_id` override before falling back to batch metadata.
- Preserve the existing backflush inventory issue flow and completion behavior.

## Non-Goals
- Do not change table schema or add a new RPC.
- Do not redesign the `BatchStepExecution` page layout.
- Do not change non-backflush step save behavior.
- Do not refactor unrelated equipment-assignment logic.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [specs/batch-step-execution-page.md](/Users/zhao/dev/other/beer/specs/batch-step-execution-page.md)
- [beeradmin_tail/src/views/Pages/BatchStepExecution.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchStepExecution.vue)
- [DB/function/72_public.batch_step_complete_backflush.sql](/Users/zhao/dev/other/beer/DB/function/72_public.batch_step_complete_backflush.sql)

## Data Model / API Changes
- No schema changes.
- Extend the existing `batch_step_complete_backflush` patch payload with optional `source_site_id`.
- Reuse existing batch metadata and equipment context as source-site fallbacks.

## Implementation Notes
- Prefer `batch.meta` site fields first, then fall back to execution-context site inference on the page when completing a backflush step.
- Keep the source-site decision explicit in the RPC so the DB function does not depend only on historical batch metadata quality.
- Preserve the existing cross-site safety rule for backflush allocation after source site is resolved.

## Final Decisions
- Resolve backflush source site on the page by checking batch metadata first, then falling back to a single inferred site from equipment assignments / reservations.
- Pass the inferred site through `p_patch.source_site_id` when calling `batch_step_complete_backflush`.
- Keep the RPC fallback to batch metadata so existing callers remain compatible.

## Validation Plan
- Review the updated batch-step execution spec against the backflush completion flow.
- Run targeted ESLint for the touched execution page files.
- Run project type-check.
- Run project build-only.
- Run unit test script status.

## Validation Results
- `npx eslint src/views/Pages/BatchStepExecution.vue --no-fix`: passed
- `npm run type-check`: passed
- `npm run build-only`: passed with existing CSS minify warnings and existing chunk-size warnings
- `npm run test`: failed because `package.json` does not define a `test` script
