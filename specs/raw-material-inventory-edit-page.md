# Raw Material Inventory Edit Page

## Goal
- Provide a dedicated page to add, edit, and move raw-material inventory based on lot + movement data.

## Route
- `/rawMaterialInventory/edit`
- `/rawMaterialInventory/edit/:lotId`

## Modes
- Create:
  - create a new lot
  - create an opening inventory movement
- Edit:
  - adjust quantity for an existing lot
  - update lot attributes
- Move:
  - move an existing lot to another location through a transfer movement
  - show a move-specific UI rather than the normal edit presentation

## Main Fields
- material type
- material
- quantity
- unit of measure
- location
- type-driven attributes

## Type / Material Selection
- In create mode, material type is displayed as a clickable label-style field instead of a native select.
- Clicking the material-type field in create mode should open the shared type-selection modal.
- The create page may receive a default material type from the inventory list page through the `materialTypeId` route query.
- Material type is selected first.
- Material dropdown is filtered by the selected type subtree.
- When editing an existing lot, material type and material preload from the lot/material master.
- Edit and move modes should show a read-only material-type summary block.
- Move mode should keep material selection read-only.
- Only types under the `RAW_MATERIAL` tree are valid selections for this page.

## Quantity Rule
- The displayed current quantity is derived from posted movement lines for the lot.
- Save must not directly treat `inv_inventory` as source-of-truth quantity.

## Type-Driven Attributes
- Attribute definitions should be resolved from the selected material type via:
  - `entity_attr_set`
  - `attr_set_rule`
  - `attr_def`
- Attribute values should be loaded from and saved to `entity_attr` with:
  - `entity_type = 'lot'`
  - `entity_id = lot.id`

## Save Model
- Create:
  - insert `lot`
  - insert one posted `inv_movements` row
  - insert one `inv_movement_lines` row with `meta.lot_id`
  - refresh the derived `inv_inventory` projection row for the lot/site
- Edit:
  - update `lot`
  - if quantity changed, insert one posted `adjustment` movement for the delta
  - refresh the derived `inv_inventory` projection row for the lot/site
- Move:
  - insert one posted `transfer` movement with `src_site_id` and `dest_site_id`
  - update `lot.site_id` to the destination site
  - refresh the derived `inv_inventory` projection rows for source and destination sites

## Validation
- material type required in create mode
- material required in create mode
- quantity required and must be greater than `0`
- location required
- move destination must differ from current location
- type-driven attributes must follow `attr_def` validation rules

## Actions
- `保存`
- `キャンセル`

## Non-Goals
- No supplier receipt document flow.
- No partial-lot splitting in the first version.
- No batch genealogy flow.
- No dispose flow on the edit page in the first version; dispose is handled as a confirmed row action from the list page.
