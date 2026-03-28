# Current Task Spec

## Goal
- Fix `年間課税概要` loader failures caused by outdated table names.
- Align category, tax-rate, package, and batch-category lookups with the current database design already used elsewhere in the app.

## Scope
- Frontend only.
- Update `beeradmin_tail/src/views/Pages/TaxYearSummary.vue`.
- No UI redesign beyond what is needed to restore data loading.

## Non-Goals
- No backend, database schema, or RPC changes.
- No change to the page layout or chart design.
- No change to the annual summary aggregation target beyond replacing broken master lookups.
- No cleanup of unrelated repo-wide lint issues.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/views/Pages/TaxYearSummary.vue`

## Data Model / API Changes
- None.
- Category master should come from `registry_def` with `kind = 'alcohol_type'`.
- Tax rate master should come from `registry_def` with `kind = 'alcohol_tax'`.
- Package volume fallback should come from `mst_package`.
- Batch category should come from `attr_def` / `entity_attr` for the `beer_category` batch attribute.

## Planned File Changes
- `specs/current-task.md`
  - replace the previous `酒税申告` interaction spec with this DB-alignment task
- `beeradmin_tail/src/views/Pages/TaxYearSummary.vue`
  - replace `mst_category`, `tax_beer`, and `mst_beer_package_category` lookups
  - remove the `mes_recipes` dependency for category resolution
  - resolve batch category from `entity_attr`
  - align tax-rate indexing and package volume conversion with the current master design
  - clean up local typing needed for targeted lint/type-check

## Fix Decisions
- Keep the current page behavior and output structure, but source category/tax/package data from the current tables.
- Use the same category normalization rules as `TaxReport.vue` so category ids or codes can both resolve.
- Use `beer_category` from batch `entity_attr` as the source of category classification.

## Final Decisions
- `TaxYearSummary.vue` no longer queries `mst_category`, `tax_beer`, or `mst_beer_package_category`.
- Category master now loads from `registry_def(kind = 'alcohol_type')`.
- Tax rates now load from `registry_def(kind = 'alcohol_tax')` and are indexed by normalized tax category code.
- Package volume fallback now loads from `mst_package`, resolving `volume_uom` through the loaded UOM map when needed.
- Batch category resolution now uses `attr_def` / `entity_attr` for the `beer_category` batch attribute, removing the `mes_recipes` dependency.
- Summary and batch rows keep the same UI output shape, but category resolution now accepts either registry ids or tax category codes.

## Validation Plan
- Confirm `年間課税概要` no longer queries removed tables.
- Confirm category, tax rate, and package loaders use the current master tables.
- Confirm the page still builds monthly/category summaries from movement data.
- Run required checks before finishing:
  - unit tests
  - lint
  - type-check
- Repository note:
  - if no unit test script exists, report that explicitly.

## Validation Outcome
- `npm exec eslint src/views/Pages/TaxYearSummary.vue` in `beeradmin_tail`: passed.
- `npm run type-check` in `beeradmin_tail`: passed.
- `npm run lint` in `beeradmin_tail`: failed due to pre-existing repo-wide ESLint issues unrelated to this task.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a test script.
