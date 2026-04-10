# Current Task Spec

## Goal
- Fix the `relation "public.mst_quality_check" does not exist` error by aligning recipe-editor quality-check loading with the actual `mes.mst_quality_check` table.

## Scope
- Update the active task spec for this bug fix.
- Update `RecipeEdit.vue` so quality-check master loading uses the correct schema.

## Non-Goals
- Do not change the recipe JSON model.
- Do not change step-editor behavior in this task.
- Do not change quality-check save mapping or UI layout.
- Do not modify database schema or DDL.

## Affected Files
- [current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [RecipeEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RecipeEdit.vue)

## Data Model / API Changes
- No data model or API changes.

## Planned File Changes
- Replace the active task spec with this quality-check schema fix.
- Change the quality-check master query in `RecipeEdit.vue` from the default/public schema to `mes`.

## Final Decisions
- `RecipeEdit.vue` now loads quality-check master data from `mes.mst_quality_check`, matching the actual table defined in the MES schema.
- The previous failure was caused by querying the default/public schema for `mst_quality_check`.
- No recipe JSON, save behavior, or step-editor behavior changed in this fix.

## Validation Plan
- Run:
  - `npx eslint src/views/Pages/RecipeEdit.vue --no-fix`
  - `npm run type-check` in `beeradmin_tail`
  - `npm run test` in `beeradmin_tail`
  - `npx eslint . --no-fix` in `beeradmin_tail`

## Validation Results
- `npx eslint src/views/Pages/RecipeEdit.vue --no-fix`: passed
- `npm run type-check` in `beeradmin_tail`: passed
- `npm run test` in `beeradmin_tail`: failed because `beeradmin_tail/package.json` has no `test` script
- `npx eslint . --no-fix` in `beeradmin_tail`: failed on the existing repo-wide ESLint backlog outside this task
