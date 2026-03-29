# Current Task Spec

## Goal
- Change existing batch ABV-related processing to use `actual_abv` first.
- Keep backward compatibility by falling back to `target_abv` only when `actual_abv` is not set.

## Scope
- Update batch ABV resolution logic in report and inventory-related frontend code.
- Update related UI specs/docs so they describe `actual_abv -> target_abv fallback`.
- Limit this task to places where batch/result ABV is derived for display, filtering, export, or tax/report calculations.

## Non-Goals
- No changes to recipe master semantics; recipe `target_abv` remains the recipe target value.
- No schema changes.
- No batch data backfill.
- No change to alcohol-type/category handling.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/views/Pages/FillingReport.vue`
- `beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue`
- `beeradmin_tail/src/views/Pages/TaxReport.vue`
- `beeradmin_tail/src/views/Pages/ProducedBeer.vue`
- `beeradmin_tail/src/composables/useProducedBeerInventory.ts`
- `beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue`
- `docs/UI/filling-report.md`
- `docs/UI/tax-report.md`
- `docs/UI/product_beer.md`

## Data Model / API Changes
- No schema/API changes.
- Batch ABV lookup order changes from:
  - `target_abv` batch attr, then recipe/meta fallback
- To:
  - `actual_abv` batch attr
  - `target_abv` batch attr
  - recipe `target_abv`
  - batch meta `actual_abv`
  - batch meta `target_abv`

## Planned File Changes
- `specs/current-task.md`
  - replace the previous SQL patch spec with this ABV resolution migration task
- frontend batch ABV consumers
  - include `actual_abv` attr_def lookup
  - resolve ABV from `actual_abv` first and keep `target_abv` as fallback
  - preserve existing UI fields/exports while changing the source priority
- docs
  - update ABV resolution order descriptions

## Fix Decisions
- Use candidate 2: `actual_abv` first, `target_abv` only as fallback.
- Treat batch attribute values as the authoritative source before recipe/meta fallbacks.
- Keep variable names/UI labels stable unless a file clearly needs renaming for correctness.

## Final Decisions
- Updated the targeted batch ABV consumers to include `actual_abv` in batch attr lookup.
- Implemented ABV resolution as `actual_abv` batch attr, then `target_abv` batch attr, then existing recipe/meta fallbacks where those files already used them.
- Kept existing variable names such as `targetAbv` and `abv` in UI code to avoid unrelated churn, while changing only the source priority.
- Updated the related UI docs to describe the new `actual_abv`-first resolution order.

## Validation Plan
- Verify every targeted batch ABV consumer includes `actual_abv` in attr lookup.
- Verify the fallback order is `actual_abv -> target_abv -> recipe target_abv -> meta actual_abv -> meta target_abv`.
- Run required checks before finishing:
  - unit tests
  - lint
  - type-check
- Repository note:
  - if no unit test script exists, report that explicitly.

## Validation Outcome
- Verified the targeted files now include `actual_abv` in batch attr lookup and prefer it over `target_abv`.
- `npm run type-check` passed in `beeradmin_tail`.
- Unit tests could not be run because `beeradmin_tail/package.json` does not define a `test` script.
- Targeted ESLint execution still fails due to pre-existing repository issues, primarily `@typescript-eslint/no-explicit-any` and some `no-unused-vars` findings in the touched files.
