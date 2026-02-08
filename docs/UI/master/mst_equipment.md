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

## Data Handling

### Tables
- mst_equipment
- mst_equipment_tank

### Save behavior
- One Save action upserts base + tank profile
- Failure in tank save must rollback or compensate

### Read behavior
- List view joins equipment + tank profile
- Filters apply to base fields

## Other

- This page must support multilanguage UI (English / Japanese)
- Equipment name uses name_i18n
- All labels and messages must be localized
