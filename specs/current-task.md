# Current Task Spec

## Goal
- Implement `BatchStepExecution.vue` as the dedicated page for step-level execution input.
- Keep `BatchEdit.vue` focused on batch-level operations.
- Preserve current `actual_yield`, `filling / packing`, `Lot DAG`, and `batch relation` behavior without regression.
- Ensure the `BatchStepExecution` UI is multilingual for all static page text.
- Add a minimal batch step control state machine for automatic step progression.

## Scope
- Update `BatchStepExecution.vue` from read-only detail to step execution input.
- Keep the route `/batches/:batchId/step/:stepId` and the existing navigation from `BatchEdit`.
- Add step-level save flows only for execution-side data:
  - `mes.batch_step`
  - `mes.batch_material_actual`
  - `mes.batch_equipment_assignment`
  - `mes.batch_execution_log`
  - `mes.batch_deviation`
- Update the dedicated UI doc and this task spec with final implementation decisions.
- Add only the minimum locale strings required for the new editing behavior.
- Replace remaining page-level hardcoded or generated English labels on `BatchStepExecution.vue` with locale-driven text.
- Add missing `recipe.parameters.*`, `recipe.qa.*`, and `recipe.materials.*` locale paths required by `BatchStepExecution.vue`.
- Add automatic transition logic when the current step is completed or skipped:
  - auto-fill current step `ended_at` when missing
  - advance the next eligible step to `ready`
- Keep `BatchEdit.vue` read-only for step execution control and let it reflect the updated execution state.

## Non-Goals
- Do not change SQL or schema in this task.
- Do not move `actual_yield` to `BatchStepExecution`.
- Do not move filling / packing to `BatchStepExecution`.
- Do not move `Lot DAG` or batch relation to `BatchStepExecution`.
- Do not redesign `BatchEdit` layout in this task.
- Do not modify `product_produce`, `product_filling`, or packing calculations.
- Do not change route structure or step execution persistence behavior for multilingual support.
- Do not add direct step-status editing to `BatchEdit.vue`.
- Do not implement a database-side workflow engine or approval engine in this task.

## Affected Files
- [current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [batch-edit-page.md](/Users/zhao/dev/other/beer/specs/batch-edit-page.md)
- [batch-step-execution-page.md](/Users/zhao/dev/other/beer/specs/batch-step-execution-page.md)
- [batchedit.md](/Users/zhao/dev/other/beer/docs/UI/batchedit.md)
- [batch_step_execution.md](/Users/zhao/dev/other/beer/docs/UI/batch_step_execution.md)
- [BatchStepExecution.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchStepExecution.vue)
- [ja.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/ja.json)
- [en.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/en.json)

## Data Model / API Changes
- No data model changes.
- No API changes.
- Use existing execution-side tables only:
  - `public.mes_batches`
  - `mes.batch_step`
  - `mes.batch_material_plan`
  - `mes.batch_material_actual`
  - `mes.batch_equipment_assignment`
  - `mes.batch_execution_log`
  - `mes.batch_deviation`
  - readonly reference masters:
    - `public.mst_uom`
    - `mes.mst_material`
    - `public.mst_equipment`
    - `public.lot`
- Reuse the existing `mes.batch_step.status` enum:
  - `open`
  - `ready`
  - `in_progress`
  - `hold`
  - `completed`
  - `skipped`
  - `cancelled`

## Planned File Changes
- Update `BatchStepExecution.vue` to add:
  - readonly batch / recipe context
  - editable step execution control
  - editable actual parameter capture stored in `mes.batch_step.actual_params`
  - editable QA result fields stored in `mes.batch_step.quality_checks_json`
  - editable actual material rows
  - editable equipment assignment rows
  - append/manage execution logs
  - editable deviations
- Keep planned materials readonly.
- Update the UI doc to match the new editing behavior.
- Add locale keys for section actions, field labels, and save status.
- Localize remaining `BatchStepExecution` event-type labels and generic unknown-error fallback text.
- Backfill missing nested `recipe.*` label keys so table headers do not render raw i18n paths.
- Add state-machine helper logic in `BatchStepExecution.vue` for `completed / skipped -> next ready`.
- Update batch docs/specs so `BatchEdit` is explicitly a state-visibility page, not the state-transition owner.

## Final Decisions
- `BatchStepExecution` owns step-level execution input only.
- `BatchEdit` remains the owner of:
  - batch header editing
  - `actual_yield`
  - filling / packing
  - `Lot DAG`
  - batch relation
- Implemented in `BatchStepExecution.vue`:
  - readonly batch / recipe context with recipe link navigation
  - editable step control for status, started / ended timestamps, and notes
  - editable actual parameter input stored in `mes.batch_step.actual_params.parameters`
  - editable QA result fields stored on `mes.batch_step.quality_checks_json`
  - readonly planned material table from `mes.batch_material_plan`
  - editable actual material rows backed by `mes.batch_material_actual`
  - editable equipment assignment rows backed by `mes.batch_equipment_assignment`
  - editable execution log rows backed by `mes.batch_execution_log`
  - editable deviation rows backed by `mes.batch_deviation`
- The page now loads reference options from:
  - `public.mst_uom`
  - `mes.mst_material`
  - `public.mst_equipment`
  - `public.lot`
- Compatibility guardrails kept:
  - no `BatchEdit` save behavior changes
  - no `actual_yield` behavior changes
  - no filling summary or packing navigation changes
  - no relation behavior changes
- Multilingual support on `BatchStepExecution` is limited to static UI text:
  - execution event type options now come from locale keys
  - generic unknown-error fallback text now comes from locale keys
  - duration display units are locale-driven
  - missing nested `recipe.parameters`, `recipe.qa`, and `recipe.materials` labels are provided from locale resources
  - no execution save logic changed
- Step control state machine rule in this task:
  - when the current step is saved as `completed` or `skipped`, and it was not already in a terminal state
  - the page auto-fills current step `ended_at` with now when blank
  - the next step by `step_no` in the same batch is searched
  - if that next step is `open`, it is advanced to `ready`
  - `BatchEdit` only reflects the resulting state; it does not trigger the transition itself

## Validation Plan
- Run:
  - `npx eslint src/views/Pages/BatchStepExecution.vue --no-fix` in `beeradmin_tail`
  - locale JSON parse check in `beeradmin_tail`
  - `npm run type-check` in `beeradmin_tail`
  - `npm run test` in `beeradmin_tail`
  - `npx eslint . --no-fix` in `beeradmin_tail`

## Validation Results
- `npx eslint src/views/Pages/BatchStepExecution.vue --no-fix` in `beeradmin_tail`: passed
- locale JSON parse check in `beeradmin_tail`: passed
- `npm run type-check` in `beeradmin_tail`: passed
- `npm run test` in `beeradmin_tail`: failed because `beeradmin_tail/package.json` has no `test` script
- `npx eslint . --no-fix` in `beeradmin_tail`: failed on the existing repo-wide ESLint backlog outside this task
