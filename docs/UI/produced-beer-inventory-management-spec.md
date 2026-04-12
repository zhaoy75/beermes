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
  - Lot Code
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
  - `Show Non-Package`
    - checkbox
    - controls whether rows without `package_id` are visible
    - default value: `off`
- Behavior:
  - filters are shown inline above the grid
  - filtering updates the visible grid rows without requiring page navigation
  - refresh button reloads the underlying inventory dataset
  - `RETURN_FROM_CUSTOMER` is expected to land in destination `inv_inventory`; returned beer should appear here as inventory when the movement posts successfully
  - when `Show Non-Package` is `off`, rows with `package_id is null` are hidden
    - exception: rows whose latest `lot.meta.movement_intent` is `INTERNAL_TRANSFER` or `RETURN_FROM_CUSTOMER` must remain visible as inventory arrivals
  - when `Show Non-Package` is `on`, rows with `package_id is null` may appear together with packaged rows

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
  - `国内移出完了` / `Complete Domestic Removal`

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

#### `国内移出完了` / `Complete Domestic Removal`
- Purpose:
  - complete domestic shipment for the selected visible inventory row through a backend business action
- UI behavior:
  - show confirmation dialog before execution
  - this action is only available when all underlying source rows of the visible inventory row are in `TAX_STORAGE` (`蔵置所`)
  - the action always moves the full current quantity of each underlying lot
  - after success, refresh inventory grid and remove or update the affected `TAX_STORAGE` row from the visible positive inventory result
  - if the action is rejected by backend business rules, show an explicit error message
- Backend direction:
  - UI must not update `inv_inventory` or `lot` directly
  - implement or call a backend endpoint / RPC that performs the shipment through business logic
  - backend must reject the action for non-`TAX_STORAGE` sites
  - backend should resolve or lazily create the tenant hidden dummy `DOMESTIC_CUSTOMER` site as shipment destination
  - backend should call standard shipment logic through `public.product_move(p_doc jsonb)` instead of inventory-zero adjustment logic
  - backend should update inventory / lot quantity consistently and keep audit metadata
  - backend should not delete rows
  - see dedicated redesign spec: [domestic-removal-complete-redesign.md](/Users/zhao/dev/other/beer/specs/domestic-removal-complete-redesign.md)

### Row Merge
- inventory rows are merged only when manufacturing batch, lot code, lot tax type, package type, and site all match
- merged row quantities are summed
- merged rows no longer cross site boundaries
- `関連履歴` stays available only when the merged row resolves to one underlying lot id
- when a visible row contains multiple underlying lots, show an unfold toggle at the right side of the `ロットコード` cell
- clicking the unfold toggle shows the merged row detail directly below the parent row
- the detail view lists the underlying lots and their quantities for that merged row

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
- Add new locale keys for row actions and confirmation/error messages related to `国内移出完了` if they do not already exist.

## Acceptance Criteria
1. `在庫管理` appears in the sidebar directly under `製造管理`.
2. Clicking `在庫管理` opens a dedicated page showing the same produced-beer inventory table previously shown on `ProducedBeer`.
3. `ProducedBeer` no longer renders the inventory section.
4. `ProducedBeer` still supports movement listing, filtering, export, and creation flows.
5. The inventory page includes a search section with `Keyword`, `Product`, `Site`, `Package`, and `Show Non-Package` filters.
6. `Show Non-Package` defaults to `off`, and rows without `package_id` are hidden until the checkbox is turned on, except for inventory-arrival rows created by `INTERNAL_TRANSFER` or `RETURN_FROM_CUSTOMER`.
7. The inventory grid supports sort on each visible data column.
8. Each inventory row includes `関連履歴` and `国内移出完了` actions.
9. `関連履歴` shows all related movement / lot genealogy for the selected row.
10. `国内移出完了` executes through backend business logic, only for `TAX_STORAGE` rows, and removes or updates the visible merged row after refresh.
11. The new page and existing movement page both load successfully without TypeScript or build regressions.
