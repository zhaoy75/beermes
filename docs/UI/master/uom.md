## Purpose
- Add, edit, and delete Unit of Measure (UOM) records used in the system.

## Entry Points
- System maintenance menu -> System Related -> Unit of Measure (UOM)
- From the UOM list page

## Users and Permissions
- Admin: create, edit, delete UOMs
- Tenant User: add, edit and delete tenant-scope UOMs only
- No permission: read-only
- System-scope UOMs are read-only for all users

## Page Layout
### Header: Unit of Measure (UOM) Management
- Title: Unit of Measure (UOM) Management
- Button: Add UOM

### Body: UOM List Table
- Columns: Dimension, Code, Name, Conversion Factor to Base Unit, Base Unit Flag, Actions
- Actions: Edit, Delete
- Pagination if needed

### UOM Edit Dialog
- Opens when clicking Add UOM or Edit

Header: Unit of Measure (UOM) Edit
- Title: Add UOM / Edit UOM
- Close button

Body: UOM Edit Form
- Dimension (required): dropdown from `uom_type`
- Code (required)
- Name in English (required)
- Name in Japanese (optional)
- Conversion Factor to Base Unit (required, numeric)
- Is Base Unit (checkbox)

Footer
- Cancel button
- Save UOM button

## Field Definitions
- Dimension: category of the UOM (e.g., volume, weight)
- Code: unique code for the UOM (e.g., L, kg)
- Name: display name of the UOM
- Conversion Factor to Base Unit: numeric factor to convert to the base unit
- Is Base Unit: true if this UOM is the base unit for its dimension
- industry_id, scope, owner_id are not shown on the edit page

## Business Rules
- UOM code must be unique within the same dimension
- Conversion factor must be a positive number
- Only one base unit allowed per dimension
- System-scope UOMs cannot be edited or deleted

## Data Handling
- On Save UOM: validate inputs, then create or update the record in `mst_uom`
- When saving a UOM:
  - `scope` = system
  - `tenant_id` is set
  - `industry_id` = 00000000-0000-0000-0000-000000000000
  - `owner_id` = `tenant_id`
  - `meta` stores labels as JSON: {"ja":"詰口","en":"Filling"}

## other
- this page should be multilanguage (english and japanese)