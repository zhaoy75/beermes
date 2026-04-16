# Raw Material Inventory Page

## Goal
- Provide a dedicated page to browse and manage current raw-material inventory.
- Let users quickly search summarized inventory, open a dedicated edit page for add, edit, and move actions, and inspect material-level inventory detail.
- Let users dispose raw-material inventory from the list with explicit confirmation.

## Route
- `/rawMaterialInventory`

## Navigation
- The page should appear under the `在庫管理` sidebar group.
- The sidebar entry should be visible only in development mode in the current version.

## Purpose
- Show current positive raw-material stock rows.
- Filter by material name, material type, and location.
- Open the dedicated inventory edit page.

## Layout
- On desktop, the page should use a left-side `原材料種別` panel and a right-side content area.
- On small screens, the material-type panel may stack above the content area.
- The left panel should feel aligned with the existing `原材料登録` page.
- On large screens, the left material-type panel should be foldable.

## Left Material-Type Panel
- Show a `原材料種別` title and a short hint.
- Show a search box for filtering visible type nodes.
- Show the currently selected type summary.
- Show a tree built from the `RAW_MATERIAL` root when available.
- Selecting a type filters the inventory list by that type and its descendants.
- Selecting the `RAW_MATERIAL` root should behave as the all-types state for raw-material inventory.
- Clicking a material-type label from a result row should update the selected node in this panel.
- Provide a collapse / expand control so the panel can be hidden and restored on large screens.

## UI Framework
- The inventory grid must use PrimeVue `DataTable`.
- Its visual styling should align with the app's normal table look used in pages like `BatchList`, rather than the default PrimeVue visual treatment.
- Any DataTable styling changes must be scoped to this page only. Do not rely on global table CSS changes.
- The main summary table and expanded lot table should use compact vertical spacing so more inventory rows fit on screen.

## Data Source
- `lot` is the inventory row identity and attribute container.
- `inv_movements` and `inv_movement_lines` are the source of truth for stock movement.
- `inv_inventory` is projection only and must not be treated as the authoritative quantity source on this page.
- `mes.mst_material` provides material code, name, and material type.
- `type_def` provides material-type label where `domain = 'material_type'`.
- `mst_sites` provides location label.
- `mst_uom` provides unit label.

## Query Model
- Inventory list should not assume `inv_inventory.material_id` exists.
- Inventory rows should be lot-based:
  - `lot.id`
  - `lot.material_id`
  - `lot.site_id`
- Current quantity should be calculated from posted movement lines belonging to the lot.
- Movement-to-lot linkage should use `inv_movement_lines.meta.lot_id`.
- Only rows with positive quantity should be shown.
- Only rows whose material resolves to a raw-material type tree should be shown.

## Search Section
- Filters:
  - material name keyword
  - location
- Material type filtering should be driven by the left-side panel instead of a search-form control.
- Search updates the visible list client-side after data load in the first version.

## Table Columns
- material name
- material type
- quantity in stock
- unit of measure
- location
- actions

## Table Row Model
- The main table should summarize inventory to one row per material.
- Each summarized material row should be expandable / collapsible.
- Summary rows with only one underlying lot should not show collapse / expand controls.
- The quantity column should sum all positive stock for that material.
- The material-type column should show all distinct material-type labels represented in that summarized row.
- The location column should show a compact summary of the locations that currently hold stock for that material.
- Expanding a material row should reveal the underlying lot-level inventory rows.

## Material Name Display
- Show the material name as a clickable link in the material-name column.
- Do not show lot number in the summarized table row.
- The link should open a detail dialog for that material.

## Detail Dialog
- The material detail dialog should show the selected material name and key context.
- It should include a current-inventory-by-location section.
- It should include an inventory-movement-history section for the selected material.
- The movement history should show enough context to understand date/time, document or movement type, quantity, and source / destination location.

## Actions
- Header action:
  - `新規在庫`
  - opens inventory edit page in create mode
  - should stay visually prominent as the primary action in the page header
  - should pass the currently selected `原材料種別` as the default type for the create page
  - should use the `materialTypeId` route query for that default handoff
- Row actions:
  - must be lot-dependent rather than material-summary-dependent
  - should appear on the expanded lot rows
  - when a material summary row has only one lot, that lot's dropdown action menu should appear directly on the summary row
- `編集` opens the dedicated inventory edit page in edit mode for the selected lot.
- `移動` opens the dedicated inventory edit page in move mode for the selected lot.
- `移動` should remain visually and functionally distinct from normal edit.
- `廃棄` should not navigate directly. It should open a confirm dialog first, then post a `waste` movement that removes the selected lot balance from stock.
- Expanded lot-row actions should be grouped inside a dropdown menu to save horizontal space.

## Empty State
- When no data matches filters, show a normal empty-state message.
- The page must still keep the `新規在庫` action visible.

## Non-Goals
- No inline inventory editing inside the table.
- No receipt posting workflow on this page.
- No lot genealogy modal in the first version.
