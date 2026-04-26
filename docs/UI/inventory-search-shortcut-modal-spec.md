# Inventory Search Shortcut Modal Specification

## Purpose
- Provide a global keyboard shortcut to open an inventory search modal from authenticated app screens.
- Let users search produced beer inventory without leaving the current page.
- Reuse the same inventory result shape already shown on the `ProducedBeerInventory` page.

## Scope
- Frontend only.
- Applies to the authenticated admin application shell.
- Initial shortcut is `Ctrl + I`. for mac will be `command + I`
- Supports caller-provided page context for default filters and row selection callback.

## Trigger and Availability
- Register the shortcut globally while the user is inside the authenticated app layout.
- Shortcut:
  - Windows/Linux: `Ctrl + I`
  - mac: `command + I`
- The handler should call `preventDefault()` when the modal is opened.
- Do not open the modal when the active target is:
  - `input`
  - `textarea`
  - `select`
  - any `contenteditable` element
- If the modal is already open, pressing `Ctrl + I` should keep it open and move focus to the first field.

## Modal Placement
- Mount the modal from a shared authenticated layout layer so it is available across pages using `AdminLayout`.
- Render as a centered overlay with backdrop.
- The modal should not navigate to a dedicated route.

## Open and Close Behavior
- Open by pressing `Ctrl + I`.
- Close by pressing `Escape`.
- Close by clicking the backdrop.
- When opened:
  - focus the `Lot / Barcode` input
  - preserve the current page in the background
- When closed:
  - return focus to the element that was focused before opening, when possible
- When opened with caller context:
  - apply caller-provided default filters before the first search result is shown
  - if caller marks a filter as locked, user cannot expand search outside that filter

## Search Form

### Fields
- `keyword`
  - text input
  - keyword should matching lot code, batch code, other information in entity_attr 
  - placeholder: empty or a short search hint
- `Product`
  - select dropdown
  - default option: all products
  - example option shown in mock: `IPA`
- `Site`
  - select dropdown
  - default option: `All Sites`
- `Package`
  - select dropdown
  - default option: all package
  - package list from mst_package
- `Show Non-Package`
  - checkbox
  - default: off
  - when off, rows without `package_id` are hidden
  - when on, rows without `package_id` are included in the result grid

### Layout
- Show the form above the result grid.
- Use a compact modal layout suitable for keyboard-driven search.
- Labels and controls should remain readable on desktop and mobile widths.

## Result Grid
- Render a searchable result grid below the filters.
- Columns should match the `ProducedBeerInventory` page as closely as possible:
  - Lot Code
  - Lot Tax Type
  - Batch No
  - Beer Category
  - ABV
  - Style Name
  - Package Type
  - Production Date
  - Qty (L)
  - Qty (Packages)
  - Site
- Empty-state behavior should match the current inventory page pattern.
- The grid should update from the active filter state.
- The grid can be sort by each column
- The grid should support keyboard row navigation.
- ABV column displays actual ABV, not target ABV:
  - prefer batch `actual_abv`
  - fallback only to actual-like snapshot/meta `actual_abv` or generic `abv`
  - do not fallback to `target_abv`
- Rows are merged only when manufacturing batch, lot code, lot tax type, package type, and site all match.
- When a merged row represents multiple underlying lots, show an unfold toggle on the right side of the `Lot Code` cell.
- Expanding a merged row shows the underlying lot detail directly below the parent row.

### Result Grid Keyboard Behavior
- `ArrowDown`
  - moves the active row highlight to the next visible result row
  - if no row is active and results exist, activates the first row
- `ArrowUp`
  - moves the active row highlight to the previous visible result row
  - if no row is active and results exist, activates the last row
- `Enter`
  - when a result row is active, behaves the same as double-click on that row
  - must call `onSelect(row)` when caller selection mode is enabled
  - must close the modal after selection
- The active row should remain visible by scrolling into view when needed.
- Mouse and keyboard selection must use the same result payload.

## Data Contract
- Base the result set on the same produced beer inventory source used by `ProducedBeerInventory`.
- Reuse existing inventory enrichment for:
  - lot
  - batch
  - category
  - package
  - production date
  - site
- The first version may use client-side filtering on top of the current produced beer inventory dataset if performance is acceptable.

## Filter Semantics
- `Keyword`
  - matches lot number
  - should also support barcode-compatible identifiers when such values are available in the inventory source
- `Product`
  - filters by produced beer / batch product label
- `Site`
  - filters by site id/name selection
  - when caller provides a locked `site_id`, results must be constrained to that site
- `Package`
  - filters inventory rows into package:

## Caller Context Integration
- Modal may be opened with contextual parameters from the current page.
- Supported context parameters:
  - `site_id`: preselected site filter
  - `site_locked`: locks the site filter to the provided value
  - `onSelect`: callback payload returned when a result row is selected
- ProductMoveFast integration:
  - when ProductMoveFast has selected `From Site`, modal opens with `site_id = From Site`
  - `site_locked = true`
  - result grid must show only lots in that source site
  - double-clicking a result row must call `onSelect(row)` and close the modal
  - selection payload should include quantity values needed by the caller page
  - ProductMoveFast may route focus after close based on selected row:
    - package lot -> `unit`
    - non-package lot -> `volume`
  
## Implementation Direction
- Preferred placement:
  - shortcut state and modal host in a shared layout-level component used by `AdminLayout`
- Preferred reuse:
  - reuse `useProducedBeerInventory` as the base inventory loader
  - add search/filter-specific state in a modal-focused component or composable
- Add dedicated locale keys for:
  - modal title
  - field labels
  - default option labels
  - empty state / helper text if needed

## Acceptance Criteria
1. Pressing `Ctrl + I` from an authenticated page opens the inventory search modal.
2. The modal contains the requested search fields:
   - Lot / Barcode
   - Product
   - Site
   - Container
   - Show Non-Package
3. The modal shows a result grid with the same core columns as `ProducedBeerInventory`.
4. Pressing `Escape` closes the modal.
5. Clicking outside the modal closes it.
6. The shortcut does not fire while the user is typing in a form control.
7. Closing the modal returns the user to the same page state they were on before opening it.
8. If ProductMoveFast opens the modal with selected `From Site`, the modal only shows lots from that site.
9. If ProductMoveFast user double-clicks a lot row, the modal closes and returns the selected row to the caller page.
10. ProductMoveFast can use returned quantity values to prefill quantity inputs on the caller page.
11. ProductMoveFast focuses `unit` for package lots and `volume` for non-package lots after modal close.
12. Pressing `ArrowDown` / `ArrowUp` in the modal moves the active result row selection.
13. Pressing `Enter` while a result row is active behaves the same as double-clicking that row.
14. Non-package inventory rows are hidden by default and only shown when `Show Non-Package` is enabled.
