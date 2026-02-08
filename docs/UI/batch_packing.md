
# Packing Dialog UI Specification

## Purpose
The Packing Dialog records a packaging-related batch event.
The user selects a packing type, then inputs only the fields required for that type.
One packing dialog submission creates one packing event.
For Filling type, multiple filling lines may be created.

## Entry Points
- Batch Edit page → button: “Packing…”　(japanese text: 移送詰口管理)
- Opens a modal dialog
- Can be used multiple times per batch

## Users & Permissions
- Operator: create packing events
- QA / Manager: create, edit, delete (policy dependent)
- No permission: dialog read-only or blocked

## Dialog Layout
### Header:
- Title: Packing
- Batch summary (batch code / name)
- Close button

### Body (top):
1) Product Volume Summary
   - Total product volume of the batch
   - Processed volume (shipped, fillin, transferred, lost, disposed)
   - Remaining volume available

2) Packing Type Selector
   - UI: segmented control or radio cards
   - Values: Fillin(japanese text: 詰口)，Ship(外部製造場移動), Transfer(社内
   移動), Loss, Dispose

3) Common Fields
   - Event time (default now)
   - memo (optional)

### Dynamic Sections (order fixed):
1) Volume Section
2) Filling Section
3) Movement Section
4) Review Summary

### Footer:
- Save Packing
- Cancel
- Optional: Save and Add Another

## Field Definitions

### product Summary section 
   - Total product volume of the batch
   - Processed volume (filling, shipped(社外非納税移出), transferred(社内非納税移出), lost, disposed)
   - Remaining volume available(left volume = total volume - processed volume)
     remaining volume should be zero or positive and finally reach zero. 
     remain volume should be color as yellow when it is above zero and green if it is zero.

### Packing Type
- Required
- Changing type resets incompatible sections
- Confirm before discarding inputs

### Volume Section
Shown for: Ship, Transfer, Loss, Dispose

Fields:
- Tank (text input or chosen from list of mst_equipment_tank) 
- Quantity (numeric, required, > 0)
- Unit of measure  (dropdown list chosen from mst_uom with dimension = volume)

Tank is not needed for Loss, Dispose type

### Movement Section
Shown for: Ship, Filling, Transfer

Fields:
- Site (dropdown, required)
- Quantity (numeric, required)
- Memo (optional)

Defaults:
- Ship/Transfer: movement quantity defaults to volume quantity
- Filling: movement quantity defaults to filling total

### Filling Section (Filling only)
Components:
- Add Filling button
- Filling lines table

Filling line fields:
- Package type (dropdown, from mst_package table)
  when a package type is chosen, please use the proper uom 
- Quantity (integer, >= 1)

Table actions:
- Edit filling line
- Delete filling line

Derived values (optional):
- Volume per unit
- Total line volume

Totals:
- Total units
- Total volume (if available)

### Type-specific Behavior

Ship:
- Volume section
- Movement section
- movement_qty defaults to volume_qty

Transfer:
- Same as Ship

Filling:
- Filling section
- Movement section
- At least one filling line required
- movement_qty defaults to filling total

Loss:
- Volume section only
- Optional reason field

Dispose:
- Volume section only
- Optional reason field

### Review Summary
Always visible.
Shows:
- Packing type
- Volume
- Movement site and quantity
- Filling breakdown (if applicable)

### Validation Rules
- Packing type required
- Quantity > 0
- Site required when movement is present
- At least one filling line for Filling type
- Filling quantity must be integer >= 1

Warnings:
- Movement quantity differs from volume or filling total

### tate Reset Rules
- Changing packing type resets irrelevant fields
- Confirm dialog if data will be lost

### Save Behavior
- Disable Save during submission
- On success:
  - Close dialog
  - Refresh batch packing list
  - Show success message
- On error:
  - Show inline and global error

### Suggested Payload Structure

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

### Accessibility & i18n
- Labels for all inputs
- Keyboard navigable
- i18n for labels and messages

## data handle
### tables
- mst_package for package
- mst_equipment_tank for tank
- inv_movement for record movement
- inv_movement_line for movement line 
- lot for lot master
- lot_event for lot event header
- lot_event_line for lot event lines

### data usage
- Saves packing events via inv_movements + inv_movement_lines.
- Loads packing events from inv_movements where meta.source = 'packing' and meta.batch_id = <batchId>.
- Soft-deletes by setting inv_movements.status = 'void'.
- Uses UOM conversions for both package and volume calculations.
- Stores UI detail in inv_movements.meta (e.g., packing_type, volume_qty, volume_uom, filling_lines, etc.) for display/edit.
- Lot handling (new):
  - Create lot_event for each packing dialog submission.
  - Create lot_event_line records that mirror movement lines (same quantities/uom).
  - Link inv_movements.lot_event_id to lot_event.id.
  - Link inv_movement_lines.lot_id to the affected lot (if known).
  - Soft-delete: set lot_event.status = 'void' when inv_movements.status = 'void'.

### doc_type mapping:
- Movement
  filling → production_receipt
  ship → sale
  transfer → transfer
  loss → adjustment
  dispose → waste
  dest_site_id: set to movement_site_id for ship/transfer/filling; src_site_id is left null (needs your rule).
- Movement lines:

Filling: line per package; qty = unit_count * unit_volume(L); uom_id = liters UOM.
Volume-only (ship/transfer/loss/dispose): a single line using a default package (currently first package in mst_package — TODO in code).


### Suggested UI Components
- PackingDialog
- PackingTypeSelector
- VolumeSection
- MovementSection
- FillingSection
- FillingLineEditor
- ReviewSummary
