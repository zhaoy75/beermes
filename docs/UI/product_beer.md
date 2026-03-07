## Purpose
- Show produced beer movement history with filter, list/card view toggle, and CSV export.
- Provide entry points to create, fast-create, and edit produced beer movement records.
- Keep inventory browsing on the dedicated `ProducedBeerInventory` page, not on this page.

## Entry Points
- Sidebar -> `移出記録` / `Produced Craft Beer`
- Route: `/producedBeer`
- Create page: `/producedBeerMovement`
- Fast-create page: `/producedBeerMovementFast`

## Users and Permissions
- Tenant User: view movements in tenant scope.
- Tenant User: navigate to create/edit movement pages.

## Page Layout
### Header
- Title: `producedBeer.title`
- Subtitle: `producedBeer.subtitle`
- Action: refresh movements

### Body
- 1 main section:
  1. Movements section

### Modal/Dialog
- None on this page.
- Create/edit flows are handled by route navigation.

## Field Definitions
### Movements section
- Section title: `producedBeer.sections.movements`
- Subtitle: `producedBeer.movement.subtitle`
- Default view: list view
- Actions:
  - List/Card view toggle
  - Export CSV
  - Fast movement
  - New movement
  - Reset filters
  - Refresh movements
- Filters:
  - Beer name
  - Category
  - Package type
  - Batch no
  - Date from
  - Date to
  - Movement type

### Movement List View columns
- Movement date
- Style name
- Target ABV
- Package type
- Quantity (packages)
- Volume per package
- Tax rate
- Source site
- Destination site
- Document no
- Movement type
- Total liters
- Total packages
- Actions (Edit)

### Movement Card View
- Header:
  - Document no
  - Movement type
  - Movement date
  - Edit action
- Summary:
  - Source site
  - Destination site
  - Total liters
  - Total packages
- Lines table:
  - Beer
  - Category
  - Package type
  - Batch no
  - Packages
  - Liters

## Actions
- Refresh header action:
  - reload movement headers and lines.
- List/Card toggle:
  - switch local presentation only.
- Reset filters:
  - clear beer/category/package/batch/date filters.
  - set movement type to `all`.
- Export CSV:
  - exports currently filtered movement cards/lines.
  - file name format: `movements-YYYYMMDD.csv`.
- Fast movement:
  - navigate to `/producedBeerMovementFast`.
- New movement:
  - navigate to `/producedBeerMovement`.
- Edit movement:
  - navigate to `/producedBeerMovement?id=<movement_id>`.

## Business Rules
- Tenant isolation:
  - all reads are restricted by current session `tenant_id`.
- Movement type filter logic:
  - `taxed`: `doc_type = sale` and `meta.tax_type = tax`
  - `notax`: `doc_type = sale` and `meta.tax_type = notax`
  - `returnNotax`: `doc_type = return` and `meta.tax_type = notax`
  - `wasteNotax`: `doc_type = waste` and `meta.tax_type = notax`
  - `transferNotax`: `doc_type = transfer` and `meta.tax_type = notax`
- Filter behavior:
  - Date range and movement type are applied before loading card lines into the page result.
  - Beer/category/package/batch filters are applied client-side to movement lines.
  - Cards with zero remaining lines after client-side filtering are hidden.
- Totals:
  - card totals are recalculated from the filtered visible lines.
- Tax rate label:
  - prefer `inv_movements.meta.tax_rate`.
  - if tax type is `notax`, show `0%`.
- Volume per package:
  - derived from `line.qtyLiters / line.packageQty` when both values are available.
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
  - `attr_def` / `entity_attr` for batch attributes:
    - `beer_category`
    - `target_abv`
    - `style_name`
- Transactional data:
  - `inv_movements` (movement header)
  - `inv_movement_lines` (movement lines)
  - `mes_batches` (batch code, product name, recipe link, meta)
- Derived fields:
  - movement card totals from filtered lines.
  - movement type label from `doc_type` + `meta.tax_type`.
  - tax rate label from `inv_movements.meta.tax_rate`.
  - package quantity from `inv_movement_lines.meta.package_qty`.
  - liters from line `qty`, or fallback from package quantity x package unit liters.
  - style/category/ABV from batch attributes first, then recipe/meta fallback.

## Loading Behavior
- On mount:
  - resolve tenant
  - load sites, categories, packages, and UOMs in parallel
  - load movements
- On change of `dateFrom`, `dateTo`, or movement type:
  - automatically reload movements
- Other filters update the visible result locally without refetching

## Error Handling
- On fetch error:
  - clear movement list when needed.
  - show toast with error message.

## Non-Scope
- No inventory table on this page.
- No inline modal editing on this page.

## Other
- This page is multilingual (Japanese/English) via i18n keys under `producedBeer`.
- UI supports responsive layout with wrapped toolbar and list/card presentation.
