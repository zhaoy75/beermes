# Current Task Spec

## Goal
- Make all `酒類分類` displays use the `name` value in `registry_def.spec` for `kind = 'alcohol_type'` instead of showing registry keys.

## Scope
- Frontend only.
- Update alcohol-type label resolution on pages that display batch/recipe/product liquor classification.
- Include filter dropdowns, table cells, detail panels, and generated export content where the same value is shown.

## Non-Goals
- No database schema or seed changes.
- No locale copy changes beyond what is necessary to show the resolved alcohol-type name.
- No changes to unrelated category systems such as material categories.
- No refactor of unrelated data-loading code.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/lib/alcoholTypeRegistry.ts`
- `beeradmin_tail/src/composables/useProducedBeerInventory.ts`
- `beeradmin_tail/src/views/Pages/ProducedBeer.vue`
- `beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue`
- `beeradmin_tail/src/views/Pages/FillingReport.vue`
- `beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue`
- `beeradmin_tail/src/views/Pages/TaxReport.vue`
- `beeradmin_tail/src/views/Pages/TaxYearSummary.vue`
- `beeradmin_tail/src/views/Pages/RecipeList.vue`
- `beeradmin_tail/src/views/Pages/BatchEdit.vue`
- `beeradmin_tail/src/views/Pages/BatchPacking.vue`

## Data Model / API Changes
- None.
- The app will still read from `registry_def(kind = 'alcohol_type')`, but display labels will resolve from `spec.name`.
- Lookup should continue to accept existing stored values such as `def_id`, `def_key`, and tax category code where present.

## Planned File Changes
- `specs/current-task.md`
  - replace the previous SQL task spec with this UI resolution task
- `beeradmin_tail/src/lib/alcoholTypeRegistry.ts`
  - add shared helpers to extract alcohol-type labels from `registry_def.spec.name`
  - add shared lookup-map construction for `def_id`, `def_key`, `spec.name`, and code-like fields
- frontend pages/composables
  - switch alcohol-type display logic to the shared helper
  - update `FillingReport` row/filter/export handling so labels display `spec.name` consistently

## Fix Decisions
- Centralize alcohol-type label resolution to avoid per-page drift.
- Use `spec.name` as the preferred display label, with existing identifiers retained only as lookup keys or final fallback.
- Keep filter values stable by storing raw values internally while rendering labels from the shared lookup.

## Final Decisions
- Added a shared alcohol-type registry helper to standardize label extraction and lookup-key handling.
- Alcohol-type display labels now prefer `registry_def.spec.name` across inventory, movement, filling, taxable removal, tax report, tax year summary, recipe, and batch packing related screens.
- Lookup remains backward-compatible with stored `def_id`, `def_key`, label text, and tax-category-like values where those still exist in batch/meta/recipe data.
- `FillingReport` now keeps the raw liquor classification value for filtering while rendering a separate display label for UI and export output.

## Validation Plan
- Verify targeted pages display alcohol-type names from `registry_def.spec.name`.
- Verify filters and exports still work when stored values are `def_id`, `def_key`, or tax category code.
- Run required checks before finishing:
  - unit tests
  - lint
  - type-check
- Repository note:
  - if no unit test script exists, report that explicitly.

## Validation Outcome
- `npm run type-check` in `beeradmin_tail`: passed.
- `npm exec eslint src/lib/alcoholTypeRegistry.ts src/composables/useProducedBeerInventory.ts src/views/Pages/ProducedBeer.vue src/views/Pages/ProducedBeerMovementEdit.vue src/views/Pages/FillingReport.vue src/views/Pages/TaxableRemovalReport.vue src/views/Pages/TaxReport.vue src/views/Pages/TaxYearSummary.vue src/views/Pages/RecipeList.vue src/views/Pages/BatchEdit.vue src/views/Pages/BatchPacking.vue` in `beeradmin_tail`: failed due to pre-existing ESLint errors in those files, primarily long-standing `@typescript-eslint/no-explicit-any` violations and a few unused-symbol errors unrelated to this change.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a test script.
