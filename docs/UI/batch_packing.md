
# Packing Dialog UI Specification

## Purpose
The Packing Dialog records a packaging-related batch event.
The user selects a packing type, then inputs only the fields required for that type.
One packing dialog submission creates one packing event.
For Filling type, multiple filling lines may be created.

# Entry Points
- Batch Edit page → button: “Packing…”　(japanese text: 移送詰口管理)
- Opens a modal dialog
- Can be used multiple times per batch

3. Users & Permissions
- Operator: create packing events
- QA / Manager: create, edit, delete (policy dependent)
- No permission: dialog read-only or blocked

4. Dialog Layout
Header:
- Title: Packing
- Batch summary (batch code / name)
- Close button

Body (top):
1) Product Volume Summary
   - Total product volume of the batch
   - Processed volume (shipped, fillin, transferred, lost, disposed)
   - Remaining volume available

2) Packing Type Selector
   - UI: segmented control or radio cards
   - Values: Fillin(japanese text: 詰口)，Ship, Transfer, Loss, Dispose
3) Common Fields
   - Event time (default now)
   - memo (optional)

Dynamic Sections (order fixed):
1) Volume Section
2) Filling Section
3) Movement Section
4) Review Summary

Footer:
- Save Packing
- Cancel
- Optional: Save and Add Another

5. Field Definitions

5.0 product Summary section 
   - Total product volume of the batch
   - Processed volume (shipped, fillin, transferred, lost, disposed)
   - Remaining volume available(left volume = total volume - processed volume)
     remaining volume should be zero or positive and finally reach zero. 
     remain volume should be color as yellow when it is above zero and green if it is zero.



5.1 Packing Type
- Required
- Changing type resets incompatible sections
- Confirm before discarding inputs

5.2 Volume Section
Shown for: Ship, Transfer, Loss, Dispose

Fields:
- Quantity (numeric, required, > 0)
- Unit of measure displayed (e.g. L)

5.3 Movement Section
Shown for: Ship, Filling, Transfer

Fields:
- Site (dropdown, required)
- Quantity (numeric, required)
- Memo (optional)

Defaults:
- Ship/Transfer: movement quantity defaults to volume quantity
- Filling: movement quantity defaults to filling total

5.4 Filling Section (Filling only)
Components:
- Add Filling button
- Filling lines table

Filling line fields:
- Package type (dropdown, required)
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

6. Type-specific Behavior

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

7. Review Summary
Always visible.
Shows:
- Packing type
- Volume
- Movement site and quantity
- Filling breakdown (if applicable)

8. Validation Rules
- Packing type required
- Quantity > 0
- Site required when movement is present
- At least one filling line for Filling type
- Filling quantity must be integer >= 1

Warnings:
- Movement quantity differs from volume or filling total

9. State Reset Rules
- Changing packing type resets irrelevant fields
- Confirm dialog if data will be lost

10. Save Behavior
- Disable Save during submission
- On success:
  - Close dialog
  - Refresh batch packing list
  - Show success message
- On error:
  - Show inline and global error

11. Suggested Payload Structure

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

12. Accessibility & i18n
- Labels for all inputs
- Keyboard navigable
- i18n for labels and messages

13. Suggested UI Components
- PackingDialog
- PackingTypeSelector
- VolumeSection
- MovementSection
- FillingSection
- FillingLineEditor
- ReviewSummary
