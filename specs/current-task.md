# Current Task Spec

## Goal
- Remove the generated `type_def` default-UOM update DML from the workspace.

## Scope
- Remove the generated SQL file from `DB/dml/`.
- Update the active task record to reflect that the DML was rolled back.

## Non-Goals
- Do not alter the `type_def` table schema.
- Do not modify the existing craft-beer seed file in this task.
- Do not change frontend code.
- Do not replace the deleted SQL with another implementation in this task.

## Affected Files
- [current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)

## Data Model / API Changes
- No schema changes.
- No database changes are shipped because the generated DML is removed.

## Planned File Changes
- Delete the generated SQL file from `DB/dml/`.
- Update this spec to record the rollback.

## Final Decisions
- The generated file `DB/dml/type_def_material_default_uom_update.sql` was removed at the user's request.
- No replacement SQL was introduced in this rollback task.

## Validation Plan
- Run:
  - `test ! -f DB/dml/type_def_material_default_uom_update.sql`
  - `npm run type-check` in `beeradmin_tail`
  - `npm run test` in `beeradmin_tail`
  - `npx eslint . --no-fix` in `beeradmin_tail`

## Validation Results
- `test ! -f DB/dml/type_def_material_default_uom_update.sql`: passed
- `npm run type-check` in `beeradmin_tail`: passed
- `npm run test` in `beeradmin_tail`: failed because `beeradmin_tail/package.json` has no `test` script
- `npx eslint . --no-fix` in `beeradmin_tail`: failed on the existing repo-wide ESLint backlog
- `npm run type-check` in `beeradmin_tail`: passed
- `npm run test` in `beeradmin_tail`: failed because `beeradmin_tail/package.json` has no `test` script
- `npx eslint . --no-fix` in `beeradmin_tail`: failed on the existing repo-wide ESLint backlog
