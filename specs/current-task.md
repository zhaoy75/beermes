# Current Task Spec

## Goal
- Create a reusable SQL patch to add batch attribute `actual_abv` into existing environments.

## Scope
- Add one patch SQL file under `DB/dml`.
- Patch should safely insert `actual_abv` into `attr_def` and add the matching `attr_set_rule` for `batch_alcohol`.
- Patch may update the `batch_alcohol` description text so it matches the new attribute set contents.

## Non-Goals
- No frontend or application logic changes.
- No seed-file restructuring beyond the already completed `attr_batch_dml.sql` update.
- No backfill of existing batch `entity_attr` rows.

## Affected Files
- `specs/current-task.md`
- `DB/dml/attr_def_actual_abv_patch.sql`

## Data Model / API Changes
- No schema changes.
- Adds data rows in existing tables:
  - `attr_def` for `code = 'actual_abv'`
  - `attr_set_rule` linking `actual_abv` into `batch_alcohol`

## Planned File Changes
- `specs/current-task.md`
  - replace the previous seed-update spec with this patch-SQL task
- `DB/dml/attr_def_actual_abv_patch.sql`
  - insert `actual_abv` into `attr_def` if missing
  - update `batch_alcohol` description if needed
  - insert `attr_set_rule` for `actual_abv` if missing
  - add verification queries

## Fix Decisions
- Keep the patch safe to re-run.
- Use the same tenant/domain/scope/industry constants as the existing batch seed data.
- Match the `actual_abv` definition already added to `attr_batch_dml.sql`.

## Final Decisions
- Created a re-runnable patch SQL file at `DB/dml/attr_def_actual_abv_patch.sql`.
- The patch inserts `actual_abv` into `attr_def` if missing, updates the `batch_alcohol` description text, and inserts the corresponding `attr_set_rule` if missing.
- The patch includes verification queries for both `attr_def` and `attr_set_rule`.

## Validation Plan
- Review the patch SQL for idempotency and consistency with `attr_batch_dml.sql`.
- Run required checks before finishing:
  - unit tests
  - lint
  - type-check
- Repository note:
  - this task is SQL-only, so app checks are expected to be unchanged and may only validate no incidental breakage.

## Validation Outcome
- Reviewed `DB/dml/attr_def_actual_abv_patch.sql` and confirmed it matches the `actual_abv` definition already added to `DB/dml/attr_batch_dml.sql`.
- `npm run type-check` passed in `beeradmin_tail`.
- Unit tests could not be run because `beeradmin_tail/package.json` does not define a `test` script.
- `npm exec eslint src` still fails due to pre-existing repository-wide lint issues unrelated to this SQL patch task.
