# Current Task Spec

## Goal
- Add `lot_tax_type` to the result grid in the `Inventory Search Shortcut Modal`.

## Scope
- Show a `lot_tax_type` column in the inventory search modal result grid.
- Keep the modal grid aligned with the produced beer inventory row shape and sorting behavior.
- Update the modal UI spec so the documented grid columns match the implementation.

## Non-Goals
- No backend, database, or inventory query changes.
- No changes to modal open/close behavior, shortcut handling, or caller integration.
- No unrelated refactoring of the modal layout.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/components/inventory/InventorySearchModal.vue`
- `docs/UI/inventory-search-shortcut-modal-spec.md`

## Data Model / API Changes
- None.

## Validation Plan
- Confirm the inventory search modal grid shows a `lot_tax_type` column.
- Confirm the new modal column uses the existing inventory row value and sorts consistently with the other modal columns.
- Confirm the modal UI spec lists the new grid column.
- Run frontend validation after implementation:
  - unit tests
  - lint
  - type-check

## Planned File Changes
- `specs/current-task.md`: replace the previous task spec with this inventory-search-modal grid task.
- `beeradmin_tail/src/components/inventory/InventorySearchModal.vue`: add the `lot_tax_type` column and sort key to the modal grid.
- `docs/UI/inventory-search-shortcut-modal-spec.md`: document the added modal grid column.

## Final Decisions
- The inventory search modal result grid now includes a `lot_tax_type` column.
- The modal column reuses the existing `lotTaxType` value from produced beer inventory rows and supports sorting.
- The modal UI spec was updated so the documented result-grid columns match the implementation.
