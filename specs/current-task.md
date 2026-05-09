# Current Task

## Goal
- Allow duplicate `batch_code` values in `public.mes_batches`.
- Remove the custom `Batch code ... already exists for tenant ...` error from `create_batch_from_recipe`.
- Move the existing `supabase/testtemplate/create_batch_from_recipe.sql` function into `DB/function` so it is managed with the other database functions.

## Scope
- Move the existing template function source to `DB/function/14_public.create_batch_from_recipe.sql`.
- Preserve the existing function signature and recipe-release behavior.
- Remove only the duplicate batch-code custom error handling from the function.
- Add SQL to drop the existing `mes_batches` unique constraint in deployed databases.
- Update `DB/ddl/mes_batches.sql` so new databases do not recreate the unique constraint.

## Non-Goals
- Do not change batch code from required to optional.
- Do not change batch navigation or identity. `mes_batches.id` remains canonical.
- Do not rewrite recipe release logic or material planning logic.
- Do not backfill or rename existing batch codes.

## Affected Files
- `specs/current-task.md`
- `supabase/testtemplate/create_batch_from_recipe.sql`
- `DB/function/14_public.create_batch_from_recipe.sql`
- `DB/ddl/mes_batches.sql`
- `DB/ddl/mes_batches_allow_duplicate_batch_code.sql`

## Data Model / API Changes
- `public.mes_batches.batch_code` remains `text NOT NULL`.
- `public.mes_batches.batch_code` is no longer unique per tenant.
- Drop constraint `mes_batches_tenant_id_batch_code_key` from existing databases.
- Keep non-unique index `idx_mes_batches_tenant_batch_code` for search.
- `public.create_batch_from_recipe(_tenant_id uuid, _recipe_id text, _batch_code text, _planned_start timestamptz, _process_version int, _notes text)` keeps the same signature and return value.

## Implementation Plan
- Move `supabase/testtemplate/create_batch_from_recipe.sql` to `DB/function/14_public.create_batch_from_recipe.sql`.
- Schema-qualify the function as `public.create_batch_from_recipe`.
- Remove the `exception when unique_violation` block that raises the duplicate batch-code message.
- Remove `UNIQUE (tenant_id, batch_code)` from the `mes_batches` table DDL.
- Add an idempotent DDL patch that drops `mes_batches_tenant_id_batch_code_key`.

## Validation Plan
- `git diff --check`
- Static SQL review:
  - `create_batch_from_recipe` has no duplicate batch-code custom exception.
  - `DB/ddl/mes_batches.sql` does not create `mes_batches_tenant_id_batch_code_key`.
  - constraint-drop SQL uses `DROP CONSTRAINT IF EXISTS`.
  - function source remains in `DB/function` with the existing behavior preserved.
- Run frontend checks only if frontend files change.

## Final Decisions
- `create_batch_from_recipe` has been moved from `supabase/testtemplate/create_batch_from_recipe.sql` to `DB/function/14_public.create_batch_from_recipe.sql`.
- The function is schema-qualified as `public.create_batch_from_recipe`.
- The existing function signature and recipe-release/material-planning behavior were preserved.
- The custom `unique_violation` handler that raised `Batch code ... already exists for tenant ...` was removed.
- `DB/ddl/mes_batches.sql` no longer declares `UNIQUE (tenant_id, batch_code)`.
- `DB/ddl/mes_batches_allow_duplicate_batch_code.sql` drops `mes_batches_tenant_id_batch_code_key` for existing databases and keeps a non-unique search index.

## Validation Results
- `git diff --check` passed.
- Static review confirmed `DB/function/14_public.create_batch_from_recipe.sql` has no `unique_violation` handler and no duplicate batch-code custom exception.
- Static review confirmed `DB/ddl/mes_batches.sql` does not create `mes_batches_tenant_id_batch_code_key`.
- Static review confirmed `DB/ddl/mes_batches_allow_duplicate_batch_code.sql` uses `DROP CONSTRAINT IF EXISTS`.
- Frontend lint/type-check were not run because no frontend files changed.
- SQL was not executed against a live database in this workspace.
