# Raw Material Inventory Page

## Goal
- Provide a dedicated page to browse current raw-material inventory.
- Let users quickly search inventory and open a dedicated edit page for add, edit, and move actions.
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

## UI Framework
- The inventory grid must use PrimeVue `DataTable`.
- Its visual styling should align with the app's normal table look used in pages like `BatchList`, rather than the default PrimeVue visual treatment.
- Any DataTable styling changes must be scoped to this page only. Do not rely on global table CSS changes.

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
  - material type
  - location
- Material type filtering should be quick to use from the search section.
- Selecting a material type should include descendant types in the visible result set.
- The quick filter should not show the `RAW_MATERIAL` root node itself as a filter chip.
- Search updates the visible list client-side after data load in the first version.

## Table Columns
- material name
- material type
- quantity in stock
- unit of measure
- location
- actions

## Material Name Display
- Show material name only in the material-name column.
- Do not show material code in that column.
- Lot number may be shown as secondary inventory context if needed.

## Actions
- Header action:
  - `新規在庫`
  - opens inventory edit page in create mode
- Row actions:
  - `編集`
  - `移動`
  - `廃棄`
- `編集` opens the dedicated inventory edit page in edit mode.
- `移動` opens the dedicated inventory edit page in move mode.
- `移動` should remain visually and functionally distinct from normal edit.
- `廃棄` should not navigate directly. It should open a confirm dialog first, then post a `waste` movement that removes the lot balance from stock.
- The row action buttons themselves should keep the app's normal neutral button style rather than introducing special amber/red row-button variants.

## Empty State
- When no data matches filters, show a normal empty-state message.
- The page must still keep the `新規在庫` action visible.

## Non-Goals
- No inline inventory editing inside the table.
- No receipt posting workflow on this page.
- No lot genealogy modal in the first version.
