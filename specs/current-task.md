# Current Task Spec

## Goal
- Create concrete page specs for the current MES batch pages:
  - batch list
  - batch edit
- Clarify how each page should present both released recipe information and batch execution status.

## Scope
- Replace the active task spec with this documentation task.
- Create a dedicated batch list page spec.
- Create a dedicated batch edit page spec.
- Document recommended UI structure, data sources, key fields, actions, and execution-status presentation for both pages.
- Record any remaining design decisions that are still open.

## Non-Goals
- Do not change Vue source in this task.
- Do not change SQL or schema in this task.
- Do not rewrite existing UI docs unless needed for direct cross-reference later.

## Affected Files
- [current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [batch-list-page.md](/Users/zhao/dev/other/beer/specs/batch-list-page.md)
- [batch-edit-page.md](/Users/zhao/dev/other/beer/specs/batch-edit-page.md)

## Data Model / API Changes
- No data model changes.
- No API changes.
- Specs will reference existing execution-side sources:
  - `public.mes_batches`
  - `mes.batch_step`
  - `mes.batch_material_plan`
  - `mes.batch_material_actual`
  - `mes.batch_equipment_assignment`
  - `mes.batch_execution_log`
  - `mes.batch_deviation`
  - `mes.mst_recipe`
  - `mes.mst_recipe_version`

## Planned File Changes
- Replace the current task spec with this spec-writing task.
- Add `specs/batch-list-page.md`.
- Add `specs/batch-edit-page.md`.

## Final Decisions
- Added a dedicated batch list page spec focused on search, optional recipe-based batch creation, released recipe visibility, and execution progress columns.
- Added a dedicated batch edit page spec focused on batch header editing, released recipe snapshot visibility, execution summary, step execution table, and secondary operations.
- Recorded concrete recommended layouts and data-source mappings for both pages.
- Captured open design decisions explicitly instead of leaving them implicit in prose.

## Validation Plan
- Run:
  - `rg -n "Batch List Page|Batch Edit Page|Open Decisions" specs -g '*.md'`
  - `npm run type-check` in `beeradmin_tail`
  - `npm run test` in `beeradmin_tail`
  - `npx eslint . --no-fix` in `beeradmin_tail`

## Validation Results
- `rg -n "Batch List Page|Batch Edit Page|Open Decisions" specs -g '*.md'`: passed
- `npm run type-check` in `beeradmin_tail`: passed
- `npm run test` in `beeradmin_tail`: failed because `beeradmin_tail/package.json` has no `test` script
- `npx eslint . --no-fix` in `beeradmin_tail`: failed on the existing repo-wide ESLint backlog outside this documentation task
