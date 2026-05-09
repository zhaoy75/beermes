# Batch Packing Page UI Specification

## Purpose
- Manage packing events for one batch on a dedicated page (not a modal dialog)
- User selects packing type and inputs required fields by type
- One save creates one packing event
- For Filling type, multiple filling lines may be created
- Unpacking events may be shown here as read-only history rows when they belong to the same batch context

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
- Batch attribute edits on this page must follow the same `attr_def` save-time validation as Batch Edit.

## Page Layout
### Header
- Title: Packing
- Batch summary (batch code / name)
- Return button (`戻る`): return to Batch Edit page (`/batches/:batchId`)
  - if edit form has unsaved input, show confirmation before leaving
- `移動履歴` button: navigate to Lot DAG page

### Body Mode A: History Mode (default)
1) Product Volume Summary
   - Total product volume of the batch
   - Processed volume (filling, shipped, transferred, lost, disposed)
   - Remaining volume
2) Packing Event List
   - event list table
  　 date
      beer category
      - source: batch attr `beer_category`
      - fallback: recipe `category`, then batch meta `beer_category` / `category`
      Packing Type
      Tank No
      Tank Fill Start Volume (タンク詰め前 容量 (L))
      Tank Fill Left Volume (タンク残 容量(L))
      詰口払出数量　= Tank Fill Start Volume - Tank Fill Left Volume
      package info
      number
      Total line volume
      詰口残数量 =  詰口払出数量 -Total line volume
      Loss
      memo
   - actions: Edit / View / Delete
   - Edit switches to Edit mode with selected row values prefilled
   - View switches to read-only detail mode with selected row values prefilled
   - unpacking events are read-only in phase 1 and must not use the standard edit form
   - unpacking events must not show Delete from this page in phase 1
   - unpacking events reduce `Processed volume` by the recovered quantity and show unpack loss in the `Loss` column
   - unpacking events should display source package / source lot context in `Package Info`
   - unpacking events should display recovered bulk quantity in `Filling Payout Qty`
   - unpacking events should display unpack input quantity in `Total line volume`
   - unpacking events should display remaining packaged quantity in `Filling Remaining Qty`
   - Batch Edit page packing history list must show the same derived values and use the same filling calculation rules as this page
   - In particular, for Filling rows on Batch Edit page:
     - `明細総容量` must match `Total line volume`
     - `詰口残数量` must match the same derived remaining quantity
     - `欠減` must match the same derived loss quantity
   - These three Batch Edit columns must not use separate or simplified page-specific logic
3) Toolbar Actions
   - `新規登録` (switch to Edit mode)

### Body Mode B: Edit Mode (in-page form)
1) Packing Type Selector
   - UI: segmented control or radio cards
   - Values: Filling(詰口), Ship(外部製造場移動), Transfer(社内移動), Loss, Dispose
   - Default: Filling
   - phase 1 unpacking is not created from this selector; it is launched from inventory and consumed here only as history
2) Common Fields
   - Event time (default now)
   - Memo (optional)
3) Dynamic Sections (order fixed)
   - Volume Section
   - Filling Section
   - Movement Section
   - Review Summary
4) Edit Actions
   - 保存
   - Cancel (discard local input and return to History mode)
   - In View mode, only Close is shown

## Field Definitions
### Product Summary Section
- Total product volume of the batch
- Processed volume (filling, shipped, transferred, lost, disposed)
- Remaining volume = total volume - processed volume
- Unpacking subtracts recovered volume from processed volume
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
- Tank (dropdown list selected from `mst_equipment_tank`)
- Volume Auto Fill Button (only shown for dispose)
- Quantity (numeric, required, > 0)
- Unit of measure (dropdown from `mst_uom` where dimension = volume)

Defaults:
  Tank choose is not need for Loss and Dispose

For Dispose, if the volume auto fill button is clicked,set Remaining volume to the Quantity field.



### Movement Section
Shown for: Ship, Transfer

Fields:
- Site (dropdown, required)
- Quantity (numeric, required)
- Memo (optional)

Defaults:
- Ship 
  Site type should be OTHER_BREWERY
  movement quantity defaults to volume quantity

- Transfer: 
  Site type should BREWERY_STORAGE
  movement quantity defaults to volume quantity

- Filling: 
  Movement Section hidden for Filling
  `src_site_id` is auto-derived from the batch BREWERY_MANUFACTUR site
  `dest_site_id` defaults to the same value as `src_site_id`
  movement quantity is derived from filling total (only lines where `sample_flg = false`) and is not user-editable

### Filling Section (Filling only)
Components:
- Tank No (dropdown list to choose tank from mst_equipment and mst_equipement_tank)

- Tank Fill Start Depth (タンク詰め前 深さ (mm))
- Tank Fill Start Volume (タンク詰め前 容量 (L)) autocaculated by can be modify
- Tank Fill Left Depth (タンク残 深さ(mm))
- Tank Fill Left Volume (タンク残 容量(L)) autocaculated by can be modify
- Sample Volume (サンプル) auto-calculated from filling lines where `sample_flg = true`
- Tank Loss Volume (欠減)
- horizontal line
- Add Filling button
  - must be visually prominent as the primary action for the filling-line table
  - use a filled primary button style and enough padding so users can find it quickly
- Filling lines table

Filling line fields:
- Package type (dropdown from `mst_package`)
- lot_code
- Container count / 容器数
  - fixed-volume package: required integer, `>= 1`
  - non-fixed-volume package: optional integer, `>= 1` when entered
- Volume per container / capacity reference
  - fixed-volume package: read-only `mst_package.unit_volume`, converted by `mst_package.volume_uom` for calculations
  - non-fixed-volume package: reference only, from `mst_package.max_volume` or `mst_package.unit_volume` when available
  - capacity reference must be converted to liters before display comparison: `convertToLiters(max_volume ?? unit_volume, volume_uom)`
- Total filled volume / 総充填容量(L)
  - fixed-volume package: read-only calculated value
  - non-fixed-volume package: required user input, stored as liters
  - if non-fixed total volume exceeds the capacity reference, show a warning but allow save
  - if non-fixed container count is entered, show average volume per container: `総充填容量(L) / 容器数`
- sample_flg (boolean toggle)
  - `true`: sample line, treated as loss (not inventory)
  - `false`: normal filling line, treated as inventory movement

Table actions:
- Edit filling line
- Delete filling line

Derived values:
- Tank Fill Start Volume = get_volume_by_tank (tank id, Tank Fill Start Depth )
- Tank Fill Left Volume　= get_volume_by_tank (tank id, Tank Fill Left Depth )
- Volume per unit / capacity reference
- Total line volume = sum of filling line volume where `sample_flg = false` (inventory only)
- Sample Volume = sum of filling line volume where `sample_flg = true`
- Sample Volume input field is read-only and auto-updated when filling lines change
- Tank Loss Volume = Fill Start Volume - Left Volume - Total line volume - Sample Volume
- Effective Loss Qty (for RPC) = Tank Loss Volume + Sample Volume
- Loss and Sample Volume must be included in Processed volume

Common filling calculation rules:
- Batch Packing filling logic is the source of truth for any page that shows filling totals or filling-derived history columns
- Filling line volume resolution order:
  - if package type is fixed-volume package: `qty * package unit volume`
  - if package type is non-fixed-volume package: use line `volume`
  - non-fixed `volume` is total filled volume in liters
  - never use non-fixed `qty` as a volume fallback
- Precision rule:
  - non-fixed total volume remains stored in metadata as liters for compatibility
  - before comparison, aggregation, warning calculation, or source-lot UOM conversion, normalize liters to integer milliliters
  - convert integer milliliters back to liters only for display and compatible metadata fields that explicitly store liters
- `sample_flg = true` lines are sample-only:
  - excluded from `Total line volume`
  - excluded from package count shown in packing history
  - included in `Sample Volume`
- `sample_flg = false` lines are inventory lines:
  - included in `Total line volume`
  - included in package count when `qty` is present
- Package count rules:
  - fixed-volume `qty` is required container count
  - non-fixed-volume `qty` is optional container count
  - never use non-fixed `volume` as package count fallback
- Filling history derived columns must be calculated as:
  - `詰口払出数量 = Tank Fill Start Volume - Tank Fill Left Volume`
  - `明細総容量 = sum(filling line volume where sample_flg = false)`
  - `詰口残数量 = 詰口払出数量 - 明細総容量`
  - `欠減 = Tank Fill Start Volume - Tank Fill Left Volume - 明細総容量 - Sample Volume`
- If persisted `sample_volume` is missing, UI must derive `Sample Volume` from sample lines instead of assuming zero
- These rules apply to:
  - Batch Packing page
  - Batch Edit page packing history list
  - Filling Report / 詰口一覧表
  - any shared packing/filling history component

Batch Edit consistency requirement:
- Batch Edit page is a consumer of packing history; it is not allowed to redefine filling-derived columns independently

Batch attribute validation requirement:
- when this page saves batch attributes into `entity_attr`, it must validate against the linked `attr_def`
- validation scope:
  - required
  - num_min / num_max
  - text_regex
  - allowed_values
- if any attribute is invalid, save must be blocked and the field error must be shown inline
- before opening or saving `実績生産量`, required batch attributes must be entered
- actual yield save must persist current batch attributes to `entity_attr` before product production is posted
- For Filling rows, Batch Edit page must display:
  - `明細総容量` using the same `sample_flg = false` line-total rule as Batch Packing
  - `詰口残数量` using the same `詰口払出数量 - 明細総容量` rule as Batch Packing
  - `欠減` using the same `Tank Fill Start Volume - Tank Fill Left Volume - 明細総容量 - Sample Volume` rule as Batch Packing
- If a shared component or shared calculation module exists, Batch Edit page should reuse it instead of duplicating logic

Totals:
- Total units
- Total volume (if available)

### Type-specific Behavior
Ship:
- Volume section + Movement section

Transfer:
- Volume section + Movement section

Filling:
- Filling section only
- At least one filling line is required
- `タンク充填終了` button is not shown (tank values are auto-calculated)

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
  - for Filling: show derived read-only route summary (`src_site_id`, `dest_site_id = src_site_id`) and derived movement quantity, or hide this row if the UI does not display route data for Filling
- Filling breakdown (if applicable)

## Validation Rules
- Packing type required
- Quantity > 0 applies only to non-Filling Volume/Movement sections
- Site required when movement is present
- At least one filling line for Filling
- Filling fixed-volume line:
  - container count must be an integer `>= 1`
  - package `unit_volume` must exist, be greater than zero, and be convertible to liters
- Filling non-fixed-volume line:
  - total filled volume must be greater than zero and is stored as liters
  - container count is optional
  - if container count is entered, it must be an integer `>= 1`
- Filling RPC quantity conversion:
  - filled liters must be convertible to the source lot UOM before calling `public.product_filling`
  - if conversion fails, block save and show an inline error on the filling line or review summary
- `sample_flg` must be boolean

Warnings:
- Movement quantity differs from volume or filling total
- Non-fixed total filled volume exceeds the capacity reference:
  - first calculate `capacity_reference_liters = convertToLiters(max_volume ?? unit_volume, volume_uom)`
  - warn when `総充填容量(L) > capacity_reference_liters * 容器数`
  - if container count is not entered, warn when `総充填容量(L) > capacity_reference_liters`
  - this warning must not block save in this task

## Save Behavior
- Disable Save during submission
- On `保存` click, UI must execute save path by type:
  - Filling: `public.product_filling(p_doc jsonb)`
  - Ship (社外非納税移出): `public.product_move(p_doc jsonb)`
  - Transfer (社内非納税移出): `public.product_move(p_doc jsonb)`
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
- Before calling `product_filling`, UI should run the source-lot chronology early-warning check when the helper is available; the database remains the final authority.
- `src_site_id` must be auto-derived from the batch BREWERY_MANUFACTUR site
- `dest_site_id` must default to `src_site_id`
- `product_filling` RPC payload must include:
  - `tank_id`: selected tank id
  - `loss_qty`: effective filling loss quantity (`Tank_Loss_Volume + Sample_Volume`)
- For `product_filling` payload `lines[]`:
  - include only filling lines where `sample_flg = false`
  - exclude all lines where `sample_flg = true` (sample is not inventory)
  - `qty` must be filled volume converted from liters to the source lot UOM
  - `unit` must be container count when entered
  - include `tax_rate` when available for the packed line
- If filled liters cannot be converted to the source lot UOM, UI must block save before calling `product_filling`.
- If not found, show error: `product_produce must be executed first`
- UI must not insert/update `inv_movements`, `inv_movement_lines`, `lot`, `lot_edge` directly
- If a previous filling row was deleted through rollback, the next filling save must still call `product_filling` normally. Rollback `MERGE` lineage must be handled inside the database function and must not be followed by UI code as source ancestry.

### Filling delete / rollback rule
- Deleting a Filling event must call stored function `public.product_filling_rollback(p_doc jsonb)`.
- UI must not void only the `inv_movements` header for Filling events.
- Rollback must restore source lot/source inventory and remove or consume filled child lot availability through database lineage.
- Rollback-created `MERGE` edges are reversal/audit lineage. They must not change which source lot `get_packing_source_lotid` returns for future filling saves.

### Filling RPC payload (`public.product_filling`)
```json
{
  "doc_no": "PF-20260218-0001",
  "movement_at": "2026-02-18T10:30:00Z",
  "src_site_id": "...",
  "dest_site_id": "...",
  "batch_id": "...",
  "from_lot_id": "...",
  "uom_id": "...",
  "tank_id": "...",
  "loss_qty": 10,
  "notes": "...",
  "lines": [
    {
      "line_no": 1,
      "package_id": "fixed-package-id",
      "qty": 120,
      "unit": 240,
      "tax_rate": 0.1,
      "lot_no": "BATCH20260218_001",
      "meta": {
        "unit_count": 240,
        "volume_fix_flg": true
      }
    },
    {
      "line_no": 2,
      "package_id": "variable-package-id",
      "qty": 57.5,
      "unit": 3,
      "tax_rate": 0.1,
      "lot_no": "BATCH20260218_002",
      "meta": {
        "unit_count": 3,
        "input_volume_l": 57.5,
        "volume_fix_flg": false
      }
    }
  ]
}
```
- The example assumes the source lot UOM is liters. If the source lot UOM is not liters, `lines[].qty` must contain the converted value.
- UI-to-RPC field mapping for Filling:
  - `Tank_No` -> `tank_id`
  - `Tank_Loss_Volume + Sample_Volume` -> `loss_qty`
  - `filling_lines(sample_flg=false)` -> `lines[]`
  - `filling_lines(sample_flg=true)` -> excluded from `lines[]` and counted in `loss_qty`
  - fixed package line:
    - `lines[].qty` = `container count * package unit volume`, converted to source lot UOM
    - `lines[].unit` = container count
    - `lines[].meta.unit_count` = container count
    - `meta.filling_lines[].qty` = container count
    - `meta.filling_lines[].volume` = `null`
  - non-fixed package line:
    - `meta.filling_lines[].volume` = total filled volume in liters
    - `meta.filling_lines[].qty` = optional container count
    - `lines[].qty` = total filled volume converted to source lot UOM
    - `lines[].unit` = optional container count when entered
    - `lines[].meta.unit_count` = optional container count when entered
    - `lines[].meta.input_volume_l` = total filled volume in liters

### Transfer (社内非納税移出) save rule
- UI must call stored function `public.product_move(p_doc jsonb)`
- `movement_intent` must be `INTERNAL_TRANSFER`
- include `tax_rate` when the selected route/document carries a line tax rate
- UI must not insert/update `inv_movements`, `inv_movement_lines`, `lot`, `lot_edge` directly

### Ship (社外非納税移出) save rule
- UI must call stored function `public.product_move(p_doc jsonb)`
- `movement_intent` must be `SHIP_DOMESTIC`
- `tax_decision_code` must be `NON_TAXABLE_REMOVAL`
- include `tax_rate` when the selected route/document carries a line tax rate
- UI must not insert/update `inv_movements`, `inv_movement_lines`, `lot`, `lot_edge` directly

## Suggested Payload Structure
```json
{
  "batch_id": "...",
  "packing_type": "filling",
  "event_time": "...",
  "memo": "...",
  "Tank_No": "...",
  "Tank_Fill_Start_Depth" : 0,
  "Tank_Fill_Start_Volume" : 1000,
  "Tank_Fill_Left_Depth" : 0,
  "Tank_Fill_Left_Volume" : 500,
  "Sample_Volume" : 1,
  "Tank_Loss_Volume" : 10,
  "volume_qty": null,
  "src_site_id": "...",
  "dest_site_id": "...",
  "filling_lines": [
    { "package_id": "keg_variable_package_id", "qty": 3, "volume": 57.5, "sample_flg": false },
    { "package_id": "bottle_330ml_package_id", "qty": 6, "volume": null, "sample_flg": true }
  ]
}
```
- In this example:
  - `src_site_id` is derived from the batch manufacturing site.
  - `dest_site_id` should be the same as `src_site_id`.
  - derived movement quantity should reflect only non-sample filling lines total volume.
  - `package_id` means the selected `mst_package.id`; it must not be confused with `mst_package.package_type_id`.
  - `keg_variable_package_id.volume = 57.5` is liters and `keg_variable_package_id.qty = 3` is container count.
  - `bottle_330ml_package_id.qty = 6` is container count and its volume is calculated from package unit volume.
  - `loss_qty` sent to `product_filling` should be `Tank_Loss_Volume + Sample_Volume`.
  - any line with `sample_flg = true` must not be included in RPC `lines[]`.

## Data Handling
### tables
- `mst_package` for package
- `mst_equipment_tank` for tank
- `registry_def` kind=`alcohol_type` for beer category master
- `attr_def` / `entity_attr` for batch attribute `beer_category`
- `inv_movements` for movement header
- `inv_movement_lines` for movement lines
- `lot` for lot master
- `lot_edge` for lot lineage

### usage
- Filling: save by `public.product_filling(p_doc jsonb)`
- Ship: save by `public.product_move(p_doc jsonb)` with `movement_intent = SHIP_DOMESTIC`
- Transfer: save by `public.product_move(p_doc jsonb)` with `movement_intent = INTERNAL_TRANSFER`
- Loss / Dispose: save by `inv_movements` + `inv_movement_lines` (until dedicated functions exist)

### derived fields
- `beer category` in Packing Event List must use batch attr `beer_category` first
- if batch attr `beer_category` is not available, fallback to recipe `category`, then batch meta `beer_category` / `category`
- if `beer_category` resolves to a registry id, UI must display the label from `registry_def`
- filling-derived history fields must use the common filling calculation rules above and must not implement page-specific variants

## Accessibility & i18n
- Labels for all inputs
- Keyboard navigable
- Multi-language support (English and Japanese)
