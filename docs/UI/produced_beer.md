## Purpose
- Show produced beer inventory by site/package/batch.
- Show produced beer movement history with filter, view toggle, and CSV export.
- Provide entry points to create/edit movement records.

## Entry Points
- Sidebar -> 移動記録 / Produced Craft Beer
- Route: `/producedBeer`

## Users and Permissions
- Tenant User: view inventory and movements in tenant scope.
- Tenant User: move to movement create/edit page.

## Page Layout
### Header
- Title: `producedBeer.title`
- Subtitle: `producedBeer.subtitle`
- Action: Refresh all

### Body
- 2 sections:
  1. Inventory section
  2. Movements section

### Modal/Dialog
- None in this page.
- Create/edit is handled in `/producedBeerMovement`.

## Field Definitions
### Inventory section
- Section title: `producedBeer.sections.inventory`
- Action: refresh inventory
- Table columns:
  - Lot no
  - Production batch no
  - ビール分類
  - 目標ABV
  - スタイル名
  - Production date
  - package
  - Quantity (L)
  - Quantity (packages)
  - Site location
  
  retrieve data from inv_inventory and related table


### Movements section
- Section title: `producedBeer.sections.movements`
- Actions:
  - List/Card view toggle
  - Export CSV
  - New movement
  - Reset filters
  - Refresh movements
- Filters:
  - Beer name
  - Category
  - Package type
  - Production batch no
  - Date from
  - Date to
  - Movement type

### Movement List View columns
- Document no
- Movement type
- Movement date
- Source site
- Destination site
- Total liters
- Total packages
- Actions (Edit)

### Movement Card View
- Header: document no, movement type, movement date
- Summary: source site, destination site, total liters, total packages
- Lines table:
  - Beer
  - Category
  - Package type
  - Batch no
  - Packages
  - Liters

## Actions
- Refresh all:
  - reload inventory and movement list in parallel.
- Refresh inventory:
  - reload inventory rows from `inv_inventory` and related lot/master/batch tables.
- Refresh movements:
  - reload movement headers and lines.
- Reset filters:
  - clear all movement filters and set movement type to `all`.
- Export CSV:
  - exports currently filtered movement cards/lines.
  - file name format: `movements-YYYYMMDD.csv`.
- New movement:
  - navigate to `/producedBeerMovement`.
- Edit movement:
  - navigate to `/producedBeerMovement?id=<movement_id>`.

## Business Rules
- Tenant isolation:
  - all reads are restricted by current session `tenant_id`.
- Inventory aggregation:
  - source from `inv_inventory`, linked by `lot_id`.
  - join `lot` to obtain `batch_id`, `package_id`, and `produced_at`.
  - aggregate by `(site, package, batch)` for display.
  - show only rows where quantity is positive.
- Movement type filter logic:
  - `taxed`: `doc_type = sale` and `meta.tax_type = tax`
  - `notax`: `doc_type = sale` and `meta.tax_type = notax`
  - `returnNotax`: `doc_type = return` and `meta.tax_type = notax`
  - `wasteNotax`: `doc_type = waste` and `meta.tax_type = notax`
  - `transferNotax`: `doc_type = transfer` and `meta.tax_type = notax`
- Filter behavior:
  - Date range and movement type are applied at query/reload time.
  - Beer/category/package/batch filters are applied client-side to movement lines.
  - Cards with zero remaining lines after client filter are hidden.
- Quantity conversion:
  - package unit volume is converted to liters using UOM code.
  - supported conversion in page:
    - `L`
    - `mL`
    - `gal_us`

## Data Handling
- Auth:
  - `supabase.auth.getUser()` to resolve `tenant_id`.
- Master data:
  - `mst_sites` (site label)
  - `registry_def` kind=`alcohol_type` (category master)
  - `mst_package` (package master and unit volume)
  - `mst_uom` (uom code mapping)
- Transactional data:
  - `inv_inventory` (on-hand balance by site/lot/uom)
  - `lot` (batch/package/produced date)
  - `inv_movements` (movement header)
  - `inv_movement_lines` (movement lines)
  - `mes_batches` (batch code + product label from `meta.label`)
- Derived fields:
  - movement card totals from filtered lines.
  - movement type label from `doc_type` + `meta.tax_type`.
  - inventory package qty from inventory liters divided by package unit liters.

## Error Handling
- On fetch error:
  - clear affected list when needed.
  - show toast with error message.

## Other
- This page is multilingual (Japanese/English) via i18n keys under `producedBeer`.
- UI has both desktop and mobile responsive layout (table/card switch and wrapped toolbar).
