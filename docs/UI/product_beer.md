## Purpose
- Show produced beer movement history with filter, table view, and Excel export.
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
- View: table only
- Actions:
  - Export Excel
  - Fast movement
  - New movement
  - Reset filters
- Filters:
  - Beer name
  - Category
  - Package type
  - Batch no
  - Date from
  - Date to
  - Tax removal type (`税務移出種別`)

### Movement List View columns
- Movement date
- Style name
- Target ABV
- Package type
- Volume Per Package
- Unit of Package
- Total Volume
- Tax rate
- Source site
- Destination site
- Document no
- Tax removal type (`税務移出種別`)
- Actions (reverse)

## Actions
- Reset filters:
  - clear beer/category/package/batch/date filters.
  - set tax removal type to `all`.
- Export Excel:
  - exports the currently visible filtered movement table rows.
  - exported columns match the visible movement table columns except the actions column.
  - file name format: `movements-YYYYMMDD.xlsx`.
  - exported sheet has bordered cells, gray header background, and bold header font.
- Fast movement:
  - navigate to `/producedBeerMovementFast`.
- New movement:
  - navigate to `/producedBeerMovement`.
- Edit movement:
  - navigate to `/producedBeerMovement?id=<movement_id>`.

## Business Rules
- Tenant isolation:
  - all reads are restricted by current session `tenant_id`.
- Tax removal type filter logic:
  - `taxed`: `doc_type = sale` and `meta.tax_type = tax`
  - `notax`: `doc_type = sale` and `meta.tax_type = notax`
  - `returnNotax`: `doc_type = return` and `meta.tax_type = notax`
  - `wasteNotax`: `doc_type = waste` and `meta.tax_type = notax`
  - `transferNotax`: `doc_type = transfer` and `meta.tax_type = notax`
- Filter behavior:
  - Date range and tax removal type are applied before loading movement lines into the page result.
  - Beer/category/package/batch filters are applied client-side to movement lines.
  - Movement rows with zero remaining lines after client-side filtering are hidden.
- Totals:
  - movement row totals are recalculated from the filtered visible lines.
- Tax rate label:
  - prefer `inv_movements.meta.tax_rate`.
  - if tax type is `notax`, show `0/kl`.
  - tax rate display must use `/kl` suffix, not `%`.
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
    - `actual_abv`
    - `target_abv`
    - `style_name`
- Transactional data:
  - `inv_movements` (movement header)
  - `inv_movement_lines` (movement lines)
  - `mes_batches` (batch code, product name, recipe link, meta)
- Derived fields:
  - movement row totals from filtered lines.
  - tax removal type value from `inv_movements.meta.tax_event`.
  - tax removal type filter value uses raw `tax_event` code.
  - tax removal type display label must use rule engine `tax_event_labels`.
  - if label mapping is unavailable, fallback to raw `tax_event` code.
  - Volume Per Package from `mst_uom`.
  - tax rate label from `inv_movement_lines.tax_rate`, displayed with `/kl` suffix.
  - unit of package from `inv_movement_lines.unit`.
  - liters from line `qty`, or fallback from package quantity x package unit liters.
  - style/category/ABV from batch attributes first, then recipe/meta fallback.

## Loading Behavior
- On mount:
  - resolve tenant
  - load sites, categories, packages, and UOMs in parallel
  - load movements
- On change of `dateFrom`, `dateTo`, or tax removal type:
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
- UI supports responsive layout with wrapped toolbar and table presentation.
