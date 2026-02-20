## Purpose
- Maintain `mst_package` records used by filling and packing operations.

## Entry Point
- マスターメンテナンス → 詰口容器管理

## Users and Permissions
- Tenant user: can create / edit / delete `mst_package` records for own tenant.

## Page Layout
### Header
- Title: 詰口容器管理
- Actions:
  - Add (`新規`)
  - Refresh (`更新`)

### Body
- One list section (table).

### Modal Dialog
- Package input dialog for create/edit.

## Field Definitions
### List Columns
- `package_code`
- `name`
- `description`
- `unit_volume`
- `max_volume`
- `volume_uom`
- `volume_fix_flg`
- `created_at`
- actions (`edit`, `delete`)

### Dialog Fields
- `package_code` (required)
- `name` (multilingual label input)
- `description` (optional)
- `unit_volume` numeric (required, `> 0`)
- `max_volume` numeric (optional, when provided must be `> 0`)
- `volume_fix_flg` boolean (default `true`)
- `volume_uom` dropdown from `mst_uom` where `dimension = volume` (required)

## Business Rules
- `package_code` must be unique in tenant scope.
- `unit_volume` must be positive.
- `max_volume`:
  - nullable
  - if set, must be positive
- `volume_fix_flg`:
  - `true`: package volume is fixed by package setting
  - `false`: package volume is not fixed
- All labels/messages must support Japanese and English.

## Actions
- Add: open empty dialog with defaults.
- Edit: open dialog prefilled from selected row.
- Save:
  - validate required fields and numeric constraints
  - upsert to `mst_package`
- Delete:
  - confirm dialog
  - remove selected row from `mst_package`

## Data Handling
- Main table: `mst_package`
- UOM source: `mst_uom` (`dimension = volume`)

## Notes
- This page is master maintenance only; inventory updates are handled by movement/filling functions.
