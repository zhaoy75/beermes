# Batch Packing Page UI Specification

## Purpose
- Manage packing events for one batch on a dedicated page (not a modal dialog)
- User selects packing type and inputs required fields by type
- One save creates one packing event
- For Filling type, multiple filling lines may be created

## Entry Points
- Batch Edit page -> button: `移送詰口管理` (Batch Packing)
- On click, navigate to Batch Packing page for current batch
- Batch Edit page must not launch packing dialog
- Lot DAG button (`移動履歴`) must navigate to dedicated page (`/batches/:batchId/lot-dag`)

## UI Flow Line (Recommended)
1. User clicks `移送詰口管理` on Batch Edit page.
2. UI navigates to Batch Packing page (`/batches/:batchId/packing`).
3. Initial view is History mode:
   - show product summary and packing event list
   - no modal opens
4. User clicks `新規登録` to open in-page edit form (Edit mode).
5. User clicks row action:
   - `Edit` for editable events
   - `View` for read-only events (at least Filling / Transfer)
6. In View mode:
   - same form layout is shown
   - all fields are read-only
   - Save actions are hidden
   - Close returns to History mode
7. User enters data and clicks Save.
8. On success:
   - return to History mode in same page
   - refresh list and summary
   - highlight saved row
9. User clicks `移動履歴` when DAG is needed:
   - navigate to Lot DAG page
   - back button returns to Batch Packing page

## Users and Permissions
- Operator: create packing events
- QA / Manager: create, edit, delete (policy dependent)
- No permission: page read-only or blocked

## Page Layout
### Header
- Title: Packing
- Batch summary (batch code / name)
- Back button: return to Batch Edit page
- `移動履歴` button: navigate to Lot DAG page

### Body Mode A: History Mode (default)
1) Product Volume Summary
   - Total product volume of the batch
   - Processed volume (filling, shipped, transferred, lost, disposed)
   - Remaining volume
2) Packing Event List
   - event list table
   - actions: Edit / View / Delete
   - Edit switches to Edit mode with selected row values prefilled
   - View switches to read-only detail mode with selected row values prefilled
3) Toolbar Actions
   - `新規登録` (switch to Edit mode)

### Body Mode B: Edit Mode (in-page form)
1) Packing Type Selector
   - UI: segmented control or radio cards
   - Values: Filling(詰口), Ship(外部製造場移動), Transfer(社内移動), Loss, Dispose
   - Default: Filling
2) Common Fields
   - Event time (default now)
   - Memo (optional)
3) Dynamic Sections (order fixed)
   - Volume Section
   - Filling Section
   - Movement Section
   - Review Summary
4) Edit Actions
   - Save Packing
   - Cancel (discard local input and return to History mode)
   - Optional: Save and Add Another
   - In View mode, only Close is shown

## Field Definitions
### Product Summary Section
- Total product volume of the batch
- Processed volume (filling, shipped, transferred, lost, disposed)
- Remaining volume = total volume - processed volume
- Remaining volume must be >= 0
- Remaining volume color:
  - yellow when > 0
  - green when = 0

### Packing Type
- Required
- Changing type resets incompatible inputs
- Confirm before discarding current input

### Volume Section
Shown for: Ship, Transfer, Loss, Dispose

Fields:
- Tank (text input or selected from `mst_equipment_tank`)
- Quantity (numeric, required, > 0)
- Unit of measure (dropdown from `mst_uom` where dimension = volume)

Rules:
- Tank is not needed for Loss and Dispose

### Movement Section
Shown for: Ship, Filling, Transfer

Fields:
- Site (dropdown, required)
- Quantity (numeric, required)
- Memo (optional)

Defaults:
- Ship / Transfer: movement quantity defaults to volume quantity
- Filling: movement quantity defaults to filling total

### Filling Section (Filling only)
Components:
- Tank Fill Start Volume
- Tank Left Volume
- Tank Loss Volume
- Tank Filling End button
- horizontal line
- Add Filling button
- Filling lines table

Filling line fields:
- Package type (dropdown from `mst_package`)
- Quantity (integer, >= 1)
- lot_code

Table actions:
- Edit filling line
- Delete filling line

Derived values:
- Volume per unit
- Total line volume
- Loss = Fill Start Volume - Left Volume - Total Filling Volume
- Loss must be included in Processed volume

Totals:
- Total units
- Total volume (if available)

### Type-specific Behavior
Ship:
- Volume section + Movement section

Transfer:
- Volume section + Movement section

Filling:
- Filling section + Movement section
- At least one filling line is required

Loss:
- Volume section only
- Optional reason

Dispose:
- Volume section only
- Optional reason

### Review Summary
Always visible.
Shows:
- Packing type
- Volume
- Movement site and quantity
- Filling breakdown (if applicable)

## Validation Rules
- Packing type required
- Quantity > 0
- Site required when movement is present
- At least one filling line for Filling
- Filling quantity must be integer >= 1

Warnings:
- Movement quantity differs from volume or filling total

## Save Behavior
- Disable Save during submission
- On success:
  - Stay on Batch Packing page
  - Switch from Edit mode to History mode
  - Refresh packing list/summary
  - Highlight saved row
  - Show success message
- On error:
  - Show inline and global error
- In View mode:
  - Save is not available
  - No update is executed

### Filling (詰口) save rule
- UI must call stored function `public.product_filling(p_doc jsonb)`
- Source lot for filling must be resolved by calling:
  - function: `public.get_packing_source_lotid`
  - parameter: `p_batch_id = current batch id`
- Use returned `source_lot_id` as `from_lot_id` in `product_filling` payload
- If not found, show error: `product_produce must be executed first`
- UI must not insert/update `inv_movements`, `inv_movement_lines`, `lot`, `lot_edge` directly

### Transfer (社内非納税移出) save rule
- UI must call stored function `public.product_move(p_doc jsonb)`
- `movement_intent` must be `INTERNAL_TRANSFER`
- UI must not insert/update `inv_movements`, `inv_movement_lines`, `lot`, `lot_edge` directly

## Suggested Payload Structure
```json
{
  "batch_id": "...",
  "packing_type": "filling",
  "event_time": "...",
  "memo": "...",
  "volume_qty": null,
  "movement": {
    "site_id": "...",
    "qty": 240,
    "memo": "..."
  },
  "filling_lines": [
    { "package_type_id": "keg_10l", "qty": 24 }
  ]
}
```

## Data Handling
### tables
- `mst_package` for package
- `mst_equipment_tank` for tank
- `inv_movements` for movement header
- `inv_movement_lines` for movement lines
- `lot` for lot master
- `lot_edge` for lot lineage

### usage
- Filling: save by `public.product_filling(p_doc jsonb)`
- Transfer: save by `public.product_move(p_doc jsonb)` with `movement_intent = INTERNAL_TRANSFER`
- Ship / Loss / Dispose: save by `inv_movements` + `inv_movement_lines` (until dedicated functions exist)

## Accessibility & i18n
- Labels for all inputs
- Keyboard navigable
- Multi-language support (English and Japanese)
