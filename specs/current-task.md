# Current Task Spec

## Goal
- Create a SQL migration that completes the `public.type_def` cutover from `bigint` identifiers to canonical `uuid` identifiers.
- Replace the previous “phase 1 only” state with a migration that performs the DB-side cutover steps after shadow-column backfill.

## Scope
- Complete the repo-side `type_def` UUID cutover, not just the migration file.
- Keep the migration SQL under `DB/ddl` as the executable cutover path.
- Update the source-of-truth DDL/functions so a fresh build uses UUID-based `type_def` columns natively.
- Cover `public.type_def` itself, including final canonical UUID column names.
- Cover the direct dependent tables currently using `type_def.type_id` as `bigint`:
  - `public.type_closure`
  - `public.entity_attr.value_ref_type_id`
  - `mes.mst_material_spec.material_type_id`
  - `mes.mst_material.material_type_id`
  - `mes.mst_equipment_template.equipment_type_id`
  - `mes.mst_step_template.default_equipment_type_id`
  - `mes.batch_material_plan.material_type_id`
- Backfill UUID shadow columns from existing `bigint` references.
- Perform the canonical swap so UUID columns become the primary `type_id` / `parent_type_id` style columns.
- Rebuild dependent constraints, indexes, and triggers to use canonical UUID columns.
- Rewrite DB-side functions that still assume bigint type ids, especially:
  - `public.rebuild_type_closure`
  - `public.trg_type_def_refresh_closure`
  - `public.trg_type_def_prevent_cycle`
  - `mes.trg_assert_type_def_domain`
  - `public.product_move`
- Drop the legacy bigint reference columns after cutover.
- Update the current frontend call sites that still type or coerce `type_def` identifiers as numbers:
  - `MaterialTypeMaster.vue`
  - `RecipeEdit.vue`
  - `BatchEdit.vue`
  - `BatchPacking.vue`
  - `batchAttrValidation.ts`
- Update the craft-beer MES sample DML to use UUID `type_def` variables.

## Non-Goals
- No live database execution in this task.
- No attempt to fix the full `entity_attr_set.entity_id` polymorphism problem in this task.
- No attempt to update every frontend page in the repo that touches registry-driven UUIDs; this task is limited to the current `type_def`-dependent call sites identified above.

## Affected Files
- [current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [type_def_uuid_migration.sql](/Users/zhao/dev/other/beer/DB/ddl/type_def_uuid_migration.sql)
- [type_def.sql](/Users/zhao/dev/other/beer/DB/ddl/type_def.sql)
- [entity_attr_set.sql](/Users/zhao/dev/other/beer/DB/ddl/entity_attr_set.sql)
- [mes_recipe.sql](/Users/zhao/dev/other/beer/DB/ddl/mes_recipe.sql)
- [44_public.product_move.sql](/Users/zhao/dev/other/beer/DB/function/44_public.product_move.sql)
- [mes_recipe_craft_beer_sample.sql](/Users/zhao/dev/other/beer/DB/dml/mes/mes_recipe_craft_beer_sample.sql)
- [MaterialTypeMaster.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/MaterialTypeMaster.vue)
- [RecipeEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RecipeEdit.vue)
- [BatchEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchEdit.vue)
- [BatchPacking.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchPacking.vue)
- [batchAttrValidation.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/batchAttrValidation.ts)

## Data Model / API Changes
- Final canonical UUID columns after cutover:
  - `public.type_def.type_id uuid`
  - `public.type_def.parent_type_id uuid`
  - `public.type_closure.ancestor_type_id uuid`
  - `public.type_closure.descendant_type_id uuid`
  - `public.entity_attr.value_ref_type_id uuid`
  - `mes.mst_material_spec.material_type_id uuid`
  - `mes.mst_material.material_type_id uuid`
  - `mes.mst_equipment_template.equipment_type_id uuid`
  - `mes.mst_step_template.default_equipment_type_id uuid`
  - `mes.batch_material_plan.material_type_id uuid`
- Legacy bigint columns are removed by the end of the migration.
- Current frontend code should treat `type_def` identifiers and `entity_attr.value_ref_type_id` as UUID strings, not numbers.

## Planned File Changes
- Add a phased migration SQL file that:
  - creates UUID shadow columns
  - backfills UUID values
  - swaps canonical columns to UUID
  - rebuilds constraints, indexes, and triggers
  - rewrites dependent DB functions
  - removes legacy bigint columns
- Update base DDL and SQL function files so the repo's canonical schema is UUID-native.
- Update current Vue/TS code paths that still assume numeric `type_def` identifiers.

## Final Decisions
- Use UUID shadow columns instead of direct `ALTER COLUMN ... TYPE uuid`.
- Prefer `gen_random_uuid()` for existing `type_def` rows rather than deterministic bigint-to-uuid encoding.
- Use shadow columns only as an internal migration phase; the final state of this migration is canonical UUID columns.
- Rewrite the DB-side `type_def` cycle/closure logic to operate on UUID columns.
- Rewrite the recipe-domain validator and `product_move` DB function to use UUID type references.
- Remove legacy bigint type-reference columns in the final migration state.
- For PostgreSQL compatibility, `UPDATE ... FROM` statements in the migration must not reference the target-table alias from inside a `JOIN ... ON` clause; those predicates are written in the `WHERE` clause instead.
- The repo should no longer describe `type_def` IDs as bigint in its canonical DDL, sample DML, or the current recipe/material/batch frontend call sites covered by this task.

## Validation Plan
- Validate the migration SQL text for completeness against current known `type_def` references.
- Run:
  - unit tests
  - lint
  - type-check

## Validation Results
- Spec updated first.
- Updated files:
  - [type_def_uuid_migration.sql](/Users/zhao/dev/other/beer/DB/ddl/type_def_uuid_migration.sql)
  - [type_def.sql](/Users/zhao/dev/other/beer/DB/ddl/type_def.sql)
  - [entity_attr_set.sql](/Users/zhao/dev/other/beer/DB/ddl/entity_attr_set.sql)
  - [mes_recipe.sql](/Users/zhao/dev/other/beer/DB/ddl/mes_recipe.sql)
  - [44_public.product_move.sql](/Users/zhao/dev/other/beer/DB/function/44_public.product_move.sql)
  - [mes_recipe_craft_beer_sample.sql](/Users/zhao/dev/other/beer/DB/dml/mes/mes_recipe_craft_beer_sample.sql)
  - [MaterialTypeMaster.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/MaterialTypeMaster.vue)
  - [RecipeEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RecipeEdit.vue)
  - [BatchEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchEdit.vue)
  - [BatchPacking.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchPacking.vue)
  - [batchAttrValidation.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/batchAttrValidation.ts)
- The migration and repo-side cutover now:
  - backfills UUID shadow columns
  - swaps canonical `type_id` / `parent_type_id` style columns to UUID
  - rebuilds `type_def`, `type_closure`, `entity_attr`, and `mes` type-reference constraints/indexes
  - rewrites `public.rebuild_type_closure`, `public.trg_type_def_refresh_closure`, `public.trg_type_def_prevent_cycle`, `mes.trg_assert_type_def_domain`, and patches `public.product_move`
  - drops the legacy bigint columns at the end of the cutover
- The canonical DDL and sample DML now define UUID-based `type_def` references instead of bigint ones.
- The touched frontend call sites now treat `type_def` and `value_ref_type_id` values as UUID strings instead of numbers.
- `npm run type-check` in `beeradmin_tail`: pass.
- `npm run test` in `beeradmin_tail`: failed because no `test` script exists.
- `npm run lint` in `beeradmin_tail`: failed on the existing repo-wide ESLint backlog unrelated to this task.
- `npx eslint src/views/Pages/MaterialTypeMaster.vue src/views/Pages/RecipeEdit.vue src/lib/batchAttrValidation.ts` in `beeradmin_tail`: pass.
- `npx eslint src/views/Pages/BatchEdit.vue src/views/Pages/BatchPacking.vue` in `beeradmin_tail`: still fails on pre-existing `@typescript-eslint/no-explicit-any` / unused-symbol issues already present in those files before this change.
