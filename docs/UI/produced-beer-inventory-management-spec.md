# Produced Beer Inventory Management Page Specification

## Purpose
- Move the packaged beer inventory section out of the `ProducedBeer` page.
- Create a dedicated page named `在庫管理` / `Inventory Management`.
- Place the new navigation item directly under `製造管理` / `Production` in the sidebar.
- Keep the existing movement workflows on `ProducedBeer` focused on transfer and tax-related records.

## Scope
- Frontend only.
- Reuse the current produced-beer inventory query and table presentation.
- Do not change the inventory calculation source tables or movement behavior.
- Add search/filter UX and row-level actions on the dedicated inventory page.

## Navigation Changes
- Add a new route for the inventory page.
- Add a new sidebar child item under `sidebar.items.production`.
- Position the new item immediately after the existing batch-related items under `製造管理`.
- Keep `ProducedBeer` under `税務管理` / `Liquor Tax`.

## Page Behavior

### New Page
- Route path: `/producedBeerInventory`
- Route name: `ProducedBeerInventory`
- View component: new page component under `src/views/Pages/`
- Page title:
  - Japanese: `在庫管理`
  - English: `Inventory Management`

### Data Source
- Continue reading packaged beer stock from `inv_inventory`.
- Continue resolving lot, batch, package, UOM, category, and site metadata with the same logic currently used inside `ProducedBeer.vue`.
- Only positive-quantity inventory rows are displayed.

### UI
- Keep the existing page shell style:
  - `AdminLayout`
  - `PageBreadcrumb`
  - top-level refresh action
- Add a search/filter section above the inventory grid.
- Add sortable column headers in the inventory grid.
- Add row-level action buttons in the inventory grid.
- Keep the current inventory table columns:
  - Lot No
  - Batch No
  - Beer Category
  - Target ABV
  - Style Name
  - Package Type
  - Production Date
  - Qty (L)
  - Qty (Packages)
  - Site
- Add one more column:
  - Actions
- Keep the existing empty state and refresh behavior.

### Search / Filter Section
- Add a compact search section similar to `inventory-search-shortcut-modal-spec.md`.
- Fields:
  - `Keyword`
    - match lot number
    - match batch code
    - match produced beer / style / related inventory keyword text
  - `Product`
    - filter by produced beer / product label
  - `Site`
    - filter by site id / site label
  - `Package`
    - filter by package type
- Behavior:
  - filters are shown inline above the grid
  - filtering updates the visible grid rows without requiring page navigation
  - refresh button reloads the underlying inventory dataset

### Inventory Grid Sort
- Every visible data column in the inventory grid must support sort toggle.
- Sort direction cycle:
  - first click: ascending
  - second click: descending
  - third click may keep descending or reset to default, implementation choice is acceptable if consistent
- Recommended default sort:
  - `Production Date` descending

### Row Actions
- Each inventory row must show:
  - `関連履歴` / `Show DAG`
  - `Void`

#### `関連履歴` / `Show DAG`
- Purpose:
  - show all related movement / lot genealogy for the selected inventory lot
- UI behavior:
  - open a dedicated modal or side panel from the inventory row
  - show related movement history for the selected lot in both upstream and downstream directions
  - include movement date/time, movement type, source, destination, qty, and related lot identifiers when available
- Backend direction:
  - preferred read source is `public.lot_trace_full(p_lot_id uuid, p_max_depth int default 10)`
  - UI may render graph, table, or mixed representation as long as all related movement is traceable from the selected lot

#### `Void`
- Purpose:
  - void the selected inventory lot record through a backend business action
- UI behavior:
  - show confirmation dialog before void execution
  - after successful void, refresh inventory grid and remove the voided row from visible positive inventory result
  - if void is rejected by backend business rules, show an explicit error message
- Backend direction:
  - UI must not update `inv_inventory` or `lot` directly
  - implement or call a backend endpoint / RPC that performs transactional lot void logic
  - backend must enforce that only valid void targets can be voided
  - backend should mark related business status as `void` instead of deleting rows

## ProducedBeer Page Changes
- Remove the inventory section from `ProducedBeer.vue`.
- Remove inventory loading from the page-level refresh action.
- Keep movement filters, cards, CSV export, and create/edit flows unchanged.

## Implementation Notes
- Prefer extracting shared inventory-loading logic into a reusable composable instead of duplicating the fetch code.
- Reuse existing locale keys for inventory table labels where possible.
- Add new locale keys only for:
  - the new page title/subtitle
  - the new sidebar label if a distinct label is needed
- Reuse search/filter behavior from `inventory-search-shortcut-modal-spec.md` where practical.
- Reuse lot genealogy backend from `public.lot_trace_full` for `関連履歴`.
- Add new locale keys for row actions and confirmation/error messages related to `Void` if they do not already exist.

## Acceptance Criteria
1. `在庫管理` appears in the sidebar directly under `製造管理`.
2. Clicking `在庫管理` opens a dedicated page showing the same produced-beer inventory table previously shown on `ProducedBeer`.
3. `ProducedBeer` no longer renders the inventory section.
4. `ProducedBeer` still supports movement listing, filtering, export, and creation flows.
5. The inventory page includes a search section with `Keyword`, `Product`, `Site`, and `Package` filters.
6. The inventory grid supports sort on each visible data column.
7. Each inventory row includes `関連履歴` and `Void` actions.
8. `関連履歴` shows all related movement / lot genealogy for the selected row.
9. `Void` executes through backend business logic and removes the voided inventory from the visible positive inventory list after refresh.
10. The new page and existing movement page both load successfully without TypeScript or build regressions.
