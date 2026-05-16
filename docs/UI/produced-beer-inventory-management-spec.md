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
- View component: `beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue`
- Shared inventory loader: `beeradmin_tail/src/composables/useProducedBeerInventory.ts`
- Page title:
  - Japanese: `ビール在庫管理`
  - English: `Beer Inventory Management`

### Source Files
- Route registration:
  - `beeradmin_tail/src/router/tenant-routes.ts`
- Sidebar navigation:
  - `beeradmin_tail/src/components/layout/AppSidebar.vue`
- Page component:
  - `beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue`
- Shared inventory source/composable:
  - `beeradmin_tail/src/composables/useProducedBeerInventory.ts`
- Inventory shortcut modal using the same source shape:
  - `beeradmin_tail/src/components/inventory/InventorySearchModal.vue`
- Locale keys:
  - `beeradmin_tail/src/locales/ja.json`
  - `beeradmin_tail/src/locales/en.json`
- Related behavior specs:
  - `specs/domestic-removal-complete-redesign.md`
  - `specs/produced-beer-unpacking-page.md`
  - `docs/UI/inventory-search-shortcut-modal-spec.md`

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
- Add a row-selection checkbox column in the inventory grid.
- Add row-level action buttons in the inventory grid.
- Keep the current inventory table columns:
  - Selection checkbox
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
- Add one more column:
  - Actions
- Keep the existing empty state and refresh behavior.
- ABV column:
  - display actual ABV, not target ABV.
  - resolve from batch `actual_abv` first.
  - fallback only to actual-like snapshot/meta `actual_abv` or generic `abv`.
  - do not fallback to `target_abv`.

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
  - `解体` / `Unpack`

### Row Selection and Bulk Action Bar
- The inventory grid includes a checkbox column.
- The header checkbox selects or clears all currently visible rows.
- Row checkboxes are general row selection:
  - they remain enabled when only one row is visible
  - they may be enabled even when the row is not eligible for `国内移出完了`
- A bulk action bar appears when at least one visible row is selected.
- The bulk action bar shows:
  - selected row count
  - clear selection command
  - `国内移出完了` command
- Bulk processing is available only for `国内移出完了`.
- The bulk `国内移出完了` command must be disabled when none of the selected rows are eligible.
- When bulk `国内移出完了` runs, it processes only selected rows that are eligible for `国内移出完了`.
- Selected ineligible rows must not be sent to the backend RPC.
- The implementation should deduplicate underlying lot/site targets before calling the backend.
- Row actions should be disabled while bulk processing is running to avoid concurrent operations.
- Selection should be cleared or pruned after successful processing and inventory refresh.

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
  - for bulk execution, show one confirmation that includes selected row count and actual eligible target count
  - for bulk execution, call the backend only for eligible selected lot/site targets
- Backend direction:
  - UI must not update `inv_inventory` or `lot` directly
  - implement or call a backend endpoint / RPC that performs the shipment through business logic
  - backend must reject the action for non-`TAX_STORAGE` sites
  - backend should resolve or lazily create the tenant hidden dummy `DOMESTIC_CUSTOMER` site as shipment destination
  - backend should call standard shipment logic through `public.product_move(p_doc jsonb)` instead of inventory-zero adjustment logic
  - backend should update inventory / lot quantity consistently and keep audit metadata
  - backend should not delete rows
  - see dedicated redesign spec: [domestic-removal-complete-redesign.md](/Users/zhao/dev/other/beer/specs/domestic-removal-complete-redesign.md)

#### `解体` / `Unpack`
- Purpose:
  - start a packaged-beer unpacking workflow from the current packaged inventory row
- UI behavior:
  - this action is visible only for rows that represent packaged beer with positive quantity
  - this action is hidden when the visible row is a merged multi-lot row
  - clicking the action does not unpack inline inside the grid
  - clicking the action navigates to the dedicated unpacking registration page
  - the selected inventory row provides the initial source lot context
- Backend direction:
  - save behavior is not implemented on the inventory page itself
  - the destination page must call a dedicated unpacking RPC
  - unpacking must create a new bulk lot rather than directly rewriting the historical source lot before filling
  - see dedicated spec: [produced-beer-unpacking-page.md](/Users/zhao/dev/other/beer/specs/produced-beer-unpacking-page.md)

### Row Merge
- inventory rows are merged only when manufacturing batch, lot code, lot tax type, package type, and site all match
- merged row quantities are summed
- merged rows no longer cross site boundaries
- `関連履歴` stays available only when the merged row resolves to one underlying lot id
- when a visible row contains multiple underlying lots, show an unfold toggle at the right side of the `ロットコード` cell
- clicking the unfold toggle shows the merged row detail directly below the parent row
- the detail view lists the underlying lots and their quantities for that merged row

### Quantity Rules
- `Qty (L)` is the inventory volume converted from `inv_inventory.qty` and `inv_inventory.uom_id`.
- `Qty (Packages)` / `数量(本/箱)` is package count, not derived volume.
- Preferred package-count source:
  - use `lot.unit` when present and greater than zero.
  - if the visible `inv_inventory` row is only part of the lot, prorate `lot.unit` by `inv_inventory.qty / lot.qty` after both quantities are converted to liters.
- Fixed-volume fallback:
  - if `lot.unit` is missing and the package has `volume_fix_flg != false`, derive package count as `qtyLiters / mst_package.unit_volume_liters`.
- Non-fixed-volume behavior:
  - if `volume_fix_flg = false`, do not derive package count from volume.
  - use saved count only (`lot.unit`, or proportional `lot.unit` for partial rows).
  - if saved count is missing, display blank/`—` for package count rather than a misleading calculated count.
- Merged rows sum package counts only from rows where package count is known.

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
  - row selection and bulk `国内移出完了` labels/messages
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
8. Each inventory row includes `関連履歴`, `国内移出完了`, and `解体` actions.
9. `関連履歴` shows all related movement / lot genealogy for the selected row.
10. `国内移出完了` executes through backend business logic, only for `TAX_STORAGE` rows, and removes or updates the visible merged row after refresh.
11. `解体` navigates to a dedicated unpacking page using the selected inventory row as source context.
12. Row checkboxes can select visible rows even when only one row is visible.
13. Bulk processing is available only for `国内移出完了`; no bulk `解体`, `関連履歴`, or other action is exposed.
14. Bulk `国内移出完了` executes only eligible selected targets and does not send selected ineligible rows to the backend.
15. The new page and existing movement page both load successfully without TypeScript or build regressions.
