# Current Task Spec

## Goal
- Update produced beer inventory row merging so rows are merged only when `製造バッチ`, `ロットコード`, `ロット税区分`, `パッケージ種別`, and `保管場所` all match, while keeping the existing row expansion UI on the inventory page and inventory dialog.

## Scope
- Change the shared inventory grouping logic in `useProducedBeerInventory.ts` so `lotTaxType` is part of the merge key in addition to `siteId`.
- Preserve summed quantities when multiple underlying lots still merge inside the same site-scoped group.
- Expose merged-row detail data from the shared inventory composable.
- On `ProducedBeerInventory.vue`, show an unfold toggle at the right side of the `ロットコード` cell only when a row represents multiple underlying lots, and render a detail section when expanded.
- On `InventorySearchModal.vue`, show the same unfold toggle and merged-row detail display.
- Update related UI specs for the inventory page and inventory search modal.

## Non-Goals
- No change to inventory fetch source tables or backend RPCs.
- No change to cancellation business rules or DAG tracing behavior.
- No change to row filters, sort keys, or selection payload beyond the row structure needed to support expansion.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/composables/useProducedBeerInventory.ts`
- `beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue`
- `beeradmin_tail/src/components/inventory/InventorySearchModal.vue`
- `beeradmin_tail/src/locales/ja.json`
- `beeradmin_tail/src/locales/en.json`
- `docs/UI/produced-beer-inventory-management-spec.md`
- `docs/UI/inventory-search-shortcut-modal-spec.md`

## Data Model / API Changes
- None.
- Shared frontend inventory row shape will include merged-row detail metadata for UI expansion.

## Planned File Changes
- Include `lotTaxType` in the inventory row merge key in `useProducedBeerInventory.ts`.
- Add merged-row detail arrays and `isMerged`-style metadata to the shared inventory row model.
- Render an expand/collapse control beside `ロットコード` for merged rows in both inventory tables.
- Render expanded detail rows beneath merged parent rows on both the inventory page and the inventory search modal.
- Update docs to describe the new merge rule and unfold behavior.

## Final Decisions
- Inventory rows now merge only when batch, lot number, lot tax type, package type, and site all match.
- The existing merged-row detail and expand/collapse UI remains unchanged; only the grouping condition was tightened.
- Inventory page and inventory search modal specs were updated to document the added lot tax type condition.

## Validation Plan
- Run required checks before finishing:
  - unit tests
  - lint
  - type-check
- If no unit test script exists, report that explicitly.

## Validation Outcome
- `npm run type-check` in `beeradmin_tail`: pass.
- `npm exec eslint src/composables/useProducedBeerInventory.ts` in `beeradmin_tail`: failed on pre-existing `no-explicit-any` errors in `useProducedBeerInventory.ts`.
- `npm run test` in `beeradmin_tail`: failed because `package.json` has no `test` script.
- Verified by source inspection that the merge key now includes `lotTaxTypeGroupKey`, and both inventory specs mention the new merge condition.
