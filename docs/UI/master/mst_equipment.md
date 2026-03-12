# Equipment Management UI Specification (mst_equipment / mst_equipment_tank)

## Purpose

This page is used to manage physical equipment assets in the system, including tanks and non-tank equipment (pump, filler, etc.).

The page supports:
- creating, editing, and deleting equipment master data
- managing tank-specific attributes when equipment is a tank
- providing reliable equipment status for batch, transfer, filling, and maintenance operations
- serving as the single source of truth for equipment availability

## Entry Points

- Main navigation: Master Data → Equipment
- Contextual navigation:
  - From Batch Edit (read-only reference)
  - From Maintenance module (jump to equipment detail)

## Users and Permissions


Permissions are enforced by:
- application role control
- RLS on mst_equipment / mst_equipment_tank

## Page Layout

### Header
- Page title: Equipment
- Breadcrumb navigation
- Optional global actions:
  - Refresh
  - Language switch (EN / JA)

### Body

Split layout (List + Detail):

```
┌──────────────┬─────────────────────────────┐
│ A Panel      │ B Panel                     │
│ (List)       │ (Detail / Edit)             │
└──────────────┴─────────────────────────────┘
```

### Modal Dialog
- Maintenance Dialog
- Delete Confirmation Dialog

## Field Definitions

### A panel (left side panel)

**Purpose:** browse and select equipment

**Filter fields**
- Equipment Code (partial match)
- Site (dropdown)
- Equipment Kind (Tank / Other)
- Status (Available / Cleaning / Maintenance)

**List columns**
- Equipment Code
- Equipment Type
- Site
- Status (badge)
- Action (Edit / Maintenance)

### B panel

#### Base Equipment Fields (mst_equipment)

| Field | Required | Editable | Notes |
|------|----------|----------|-------|
| Equipment Code | Yes | Create only | Immutable after create |
| Name | Yes | Yes | Multilanguage |
| Equipment Kind | Yes | Yes | Determines tank UI |
| Site | Yes | Yes | mst_sites |
| Status | No | No | Read-only badge |
| Active | Yes | Yes | Logical delete |

#### Tank Profile Section (mst_equipment_tank)

Displayed only when Equipment Kind = Tank

| Field | Required | Notes |
|------|----------|-------|
| Capacity Volume | Yes | Must be > 0 |
| Volume UOM | Yes | Volume domain |
| Max Working Volume | No | ≤ Capacity |
| Pressurized | No | Boolean |
| Jacketed | No | Boolean |
| CIP Supported | No | Boolean |
| Tank Attributes | No | Advanced JSON |
| Calibration Table | No | Table editor backed by JSONB (depth/volume calibration map) |

#### Calibration Table Editor

The calibration table must be entered through a dedicated row-based editor, not a raw JSON textarea as the primary UI.

**Header fields**
- Reference Temperature C (`reference_temperature_c`)
- Thermal Expansion Coefficient per C (`thermal_expansion_coef_per_c`)

**Grid columns**
- Row No
- Depth (mm)
- Volume (L)
- Action
  - Delete row

**Grid actions**
- Add row
- Paste CSV / TSV rows
- Sort by Depth
- Reset to template
- Optional raw JSON preview / advanced editor in collapsed area

**Default row template**
- first row should default to `depth_mm = 0`, `volume_l = 0`
- editor should start with at least 2 rows

**Keyboard behavior**
- Enter on the last row adds a new row
- Tab moves across editable cells
- Paste of two-column spreadsheet data should map to `depth_mm`, `volume_l`

**JSON mapping**
- UI rows are converted to `calibration_table.points`
- header fields are converted to top-level JSON keys
- saved JSON contract must remain compatible with `public.get_volume_by_tank`

## Action

### add button
- Located in A panel
- Opens B panel in Create mode
- Default status: available
- Equipment Kind must be selected before saving

### delete button
- Enabled only when equipment is selected
- Confirmation required
- If equipment has history → logical delete
- Physical delete only when unused

## Business Rules

1. Equipment Code must be unique per tenant
2. Tank must have capacity before use
3. Equipment under cleaning or maintenance must not be selectable in operations
4. Equipment status is changed only via Maintenance UI
5. Switching Equipment Kind:
   - Non-tank → Tank requires tank profile
   - Tank → Non-tank requires confirmation
6. Tank max working volume must not exceed capacity
7. Calibration table must have at least 2 valid points
8. `depth_mm` values must be numeric, non-negative, unique, and strictly increasing after sort
9. `volume_l` values must be numeric, non-negative, and non-decreasing
10. Invalid calibration rows must block save with row-level error display
11. Capacity mismatch against the last calibration point may show warning but does not have to block save

## Data Handling

### Tables
- mst_equipment
- mst_equipment_tank

### Save behavior
- One Save action upserts base + tank profile
- Failure in tank save must rollback or compensate
- Calibration table editor rows must be serialized into `mst_equipment_tank.calibration_table`
- Raw JSON input is optional advanced mode only; normal users should complete calibration entry through the table editor

### Read behavior
- List view joins equipment + tank profile
- Filters apply to base fields
- Existing `calibration_table` JSON must be expanded into header fields + point rows on load

## Validation UX

- Row-level validation errors must be shown inline near the affected row
- Page-level validation summary may show calibration issues in aggregated form
- Empty optional rows should be ignored until user enters data
- Save must be blocked if calibration JSON shape would violate `public.get_volume_by_tank` contract

## Integration Note

- `mst_equipment_tank.calibration_table` must continue to follow the JSON contract documented in [`public.get_volume_by_tank`](/Users/zhao/dev/other/beer/docs/db/function/get_volume_by_tank.md)
- This UI change is a presentation/input improvement only; no DB schema change is required for the calibration table itself

## Other

- This page must support multilanguage UI (English / Japanese)
- Equipment name uses name_i18n
- All labels and messages must be localized
