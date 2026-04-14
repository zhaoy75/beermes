# Current Task

## Goal
- Remove active application usage of legacy `public.mes_recipes`.
- Refactor batch-related runtime flows to use the current MES recipe model and released batch snapshot fields instead.

## Scope
- Replace direct `mes_recipes` reads and indirect `mes_batches.recipe_id -> mes_recipes` relation reads in active frontend/runtime code.
- Keep current batch, produced-beer, filling, move, and tax UI behavior stable while switching data sources.
- Use current batch release fields such as `mes_recipe_id`, `recipe_version_id`, `released_reference_json`, `recipe_json`, and batch attributes / meta as the new fallback chain.
- Update batch summary ingredient/step loading to use released batch data instead of legacy recipe tables where needed.

## Non-Goals
- Do not remove the legacy `public.mes_recipes` table definition from the repository in this turn.
- Do not drop `public.mes_batches.recipe_id` or rewrite database migrations / production data migration logic in this turn.
- Do not redesign page layouts or change business workflows beyond the data-source refactor.
- Do not refactor unrelated recipe authoring pages that already use `mes.mst_recipe` and `mes.mst_recipe_version`.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [BatchEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchEdit.vue)
- [BatchPacking.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchPacking.vue)
- [BatchYieldSummary.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchYieldSummary.vue)
- [BatchSummaryDialog.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/components/BatchSummaryDialog.vue)
- [ProductMoveFast.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/ProductMoveFast.vue)
- [ProducedBeer.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/ProducedBeer.vue)
- [ProducedBeerMovementEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue)
- [useProducedBeerInventory.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/composables/useProducedBeerInventory.ts)
- [FillingReport.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/FillingReport.vue)
- [taxableRemovalReport.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxableRemovalReport.ts)
- new shared helper under `beeradmin_tail/src/lib/` if needed

## Spec Source Of Truth
- Batch page behavior remains governed by:
  - [batch-edit-page.md](/Users/zhao/dev/other/beer/specs/batch-edit-page.md)
  - [batch-list-page.md](/Users/zhao/dev/other/beer/specs/batch-list-page.md)
- This task is an implementation refactor to align runtime data access with those specs.

## Data Model / API Changes
- No external API contract changes.
- No required database schema migration in this turn.
- Frontend queries should stop depending on:
  - direct reads from `public.mes_recipes`
  - implicit Supabase relations through `mes_batches.recipe_id`
- Batch summary data should prefer:
  - `public.mes_batches.released_reference_json`
  - `public.mes_batches.recipe_json`
  - `public.mes_batches.mes_recipe_id`
  - batch `entity_attr`
  - batch `meta`
- Batch summary collections may query `mes.batch_step` / `mes.batch_material_plan` instead of legacy recipe detail tables.

## Planned File Changes
- Add a shared helper for resolving batch recipe display values from released batch fields, attributes, and meta.
- Update batch edit / packing category lookup to stop querying `mes_recipes`.
- Update yield / summary / produced-beer / movement / filling / tax flows to stop using `recipe:recipe_id (...)` or `mes_recipes`.
- Update the batch summary dialog to read released batch materials / steps from current batch snapshot tables.

## Validation Plan
- Run:
  - `npx eslint src/views/Pages/BatchEdit.vue src/views/Pages/BatchPacking.vue src/views/Pages/BatchYieldSummary.vue src/views/Pages/components/BatchSummaryDialog.vue src/views/Pages/ProductMoveFast.vue src/views/Pages/ProducedBeer.vue src/views/Pages/ProducedBeerMovementEdit.vue src/composables/useProducedBeerInventory.ts src/views/Pages/FillingReport.vue src/lib/taxableRemovalReport.ts src/lib/*.ts --no-fix` in `beeradmin_tail`
  - `npm run type-check` in `beeradmin_tail`
  - `npm run test` in `beeradmin_tail`

## Final Decisions
- Added a shared batch recipe snapshot helper at [batchRecipeSnapshot.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/batchRecipeSnapshot.ts) to resolve display name, recipe code, style, beer category, and target ABV from:
  - `mes_batches.released_reference_json`
  - `mes_batches.recipe_json`
  - `mes_batches.mes_recipe_id`
  - batch `entity_attr`
  - batch `meta`
- Active frontend/runtime code under `beeradmin_tail/src` no longer queries:
  - `public.mes_recipes`
  - `recipe:recipe_id (...)`
  - `recipe:mes_recipes(...)`
- `BatchEdit` and `BatchPacking` recipe-category lookup now uses `mes.mst_recipe.recipe_category` via `mes_recipe_id` only.
- `BatchYieldSummary` now derives recipe identity from released batch fields and batch `style_name` attributes instead of legacy recipe rows.
- `BatchSummaryDialog` now reads:
  - recipe display from released batch fields
  - planned materials from `mes.batch_material_plan` with `recipe_json` fallback
  - released steps from `mes.batch_step`
- Produced-beer, movement, filling, tax, and inventory helper flows now derive beer category / ABV / style from batch attributes and released batch fields instead of the legacy recipe relation.

## Validation Results
- `npx eslint src/views/Pages/BatchEdit.vue src/views/Pages/BatchPacking.vue src/views/Pages/BatchYieldSummary.vue src/views/Pages/components/BatchSummaryDialog.vue src/views/Pages/ProductMoveFast.vue src/views/Pages/ProducedBeer.vue src/views/Pages/ProducedBeerMovementEdit.vue src/composables/useProducedBeerInventory.ts src/views/Pages/FillingReport.vue src/lib/taxableRemovalReport.ts src/lib/batchRecipeSnapshot.ts --no-fix` in `beeradmin_tail`: failed on the long-standing `@typescript-eslint/no-explicit-any` / unused-symbol backlog already present in these legacy files
- `npx eslint src/lib/batchRecipeSnapshot.ts --no-fix` in `beeradmin_tail`: passed
- `npm run type-check` in `beeradmin_tail`: passed
- `npm run test` in `beeradmin_tail`: failed because `package.json` has no `test` script
- `rg -n "from\\('mes_recipes'\\)|from\\(\\\"mes_recipes\\\"\\)|recipe:recipe_id \\(|recipe:mes_recipes\\(|public\\.mes_recipes\\b" beeradmin_tail/src -S`: no matches
