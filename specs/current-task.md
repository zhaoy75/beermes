# Current Task Spec

## Goal
- Create a database view for `registry_def(kind = 'alcohol_type')` keyed by `tax_category_code`.
- When the same `tax_category_code` exists in both `tenant` and `system` scope, prefer the tenant-scoped row.

## Scope
- Database SQL only.
- Add the alcohol-type view definition in the existing alcohol-type DML SQL file.
- Keep the result aligned with the current tenant visibility rules.

## Non-Goals
- No frontend changes.
- No schema changes to `registry_def`.
- No seed-data edits for existing alcohol-type rows.
- No change to unrelated registry kinds.

## Affected Files
- `specs/current-task.md`
- `DB/dml/registry_def/alcohol_type.sql`

## Data Model / API Changes
- Adds a view over `registry_def` for active `alcohol_type` rows.
- The view should expose one row per `tax_category_code`, preferring tenant scope over system scope for duplicates.

## Planned File Changes
- `specs/current-task.md`
  - replace the previous frontend alcohol-type display spec with this DB view task
- `DB/dml/registry_def/alcohol_type.sql`
  - add a `CREATE OR REPLACE VIEW` for alcohol types keyed by `tax_category_code`
  - rank duplicate codes so tenant rows win over system rows

## Fix Decisions
- Reuse the existing `app_current_tenant_id()` visibility logic directly in the view query so behavior is stable even if the querying role bypasses RLS.
- Filter to active alcohol-type rows with a non-empty `tax_category_code`.
- Keep the view output option-friendly by exposing both key/value and label-related columns.

## Final Decisions
- Added `v_alcohol_type_options` in the alcohol-type DML SQL file.
- The view resolves active `alcohol_type` rows by `spec.tax_category_code`.
- Visibility is explicitly limited to `system` rows plus the current tenant's rows via `app_current_tenant_id()`.
- Duplicate `tax_category_code` values are ranked so the current tenant's row wins over the system row.
- The view exposes `key`, `value`, `label`, and source columns so it can be used directly as an option source.

## Validation Plan
- Review the generated SQL for correct scope precedence and tenant filtering.
- Verify the view outputs one row per `tax_category_code`.
- Repository note:
  - no automated SQL validation tooling is configured in this repo for this script.

## Validation Outcome
- Reviewed the generated SQL in `DB/dml/registry_def/alcohol_type.sql`.
- Confirmed the view filters to active `alcohol_type` rows with non-empty `tax_category_code`.
- Confirmed the ranking logic prefers tenant scope over system scope for duplicate `tax_category_code`.
- Unit tests, lint, and type-check were not run because this task changes only database SQL and the repository does not provide SQL-specific automated validation tooling for it.
