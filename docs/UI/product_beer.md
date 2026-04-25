## Purpose
- Show produced beer movement history with filter, table view, and Excel export.
- Provide entry points to create, fast-create, and edit produced beer movement records.
- Keep inventory browsing on the dedicated `ProducedBeerInventory` page, not on this page.

## Entry Points
- Sidebar -> `移入出登録` / `Inbound/Outbound Register`
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
- Table controls:
  - each sortable/filterable column header shows one compact action icon.
  - clicking the icon opens a popup menu with:
    - sort ascending
    - sort descending
    - column filter
  - column labels are not direct sort buttons.
  - active sort/filter state is indicated on the icon and inside the popup menu.
  - column filters apply after page-level filters.
  - Clear filters clears table column filters only.
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
    - default: one month ago
  - Date to
  - Tax-related movements only (`税務関連移入出のみ表示`)
    - default: checked
  - Tax removal type (`税務移出種別`)

### Movement List View columns
- Movement date
- Batch code
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
  - table display is limited to 15 characters
  - if longer than 15 characters, show the left 15 characters followed by `....`
  - full value remains available for export and actions
- Tax removal type (`税務移出種別`)
- Actions (reverse)

## Actions
- Reset filters:
  - clear beer/category/package/batch/date filters.
  - restore `Date from` to one month ago.
  - set tax removal type to `all`.
  - restore `Tax-related movements only` to checked.
- Export Excel:
  - exports the currently visible filtered movement table rows.
  - respects table column filters and current sort order.
  - exported columns match the visible movement table columns except the actions column.
  - batch code is included in the export in the same position as the visible table.
  - file name format: `movements-YYYYMMDD.xlsx`.
  - exported sheet has bordered cells, gray header background, and bold header font.
- Fast movement:
  - navigate to `/producedBeerMovementFast`.
- New movement:
  - navigate to `/producedBeerMovement`.
- Edit movement:
  - navigate to `/producedBeerMovement?id=<movement_id>`.
- Reverse movement:
  - call `public.product_move_rollback`.
  - do not call `movement_save(status='void')` because that only changes the movement header and does not reverse `inv_inventory` or lot balances.
  - on success, reload the movement list.

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
  - When `Tax-related movements only` is enabled, rows whose resolved raw `tax_event` is missing or `NONE` are excluded before loading movement lines.
  - Beer/category/package/batch filters are applied client-side to movement lines.
  - Movement rows with zero remaining lines after client-side filtering are hidden.
- Totals:
  - movement row totals are recalculated from the filtered visible lines.
- Cancellation:
  - creates a compensating adjustment movement.
  - restores source lot quantity and source inventory when the original move deducted source inventory.
  - reduces destination lot quantity and destination inventory when the original move created or reused a destination lot.
  - blocks cancellation if the destination lot has downstream non-void movement usage.
  - blocks cancellation when the movement is locked by a submitted or approved tax report.
  - marks draft tax reports that referenced the movement as stale.
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
  - batch code from `mes_batches.batch_code` through the movement line's `batch_id`.
  - when a visible movement row contains multiple unique batch codes, display the unique values joined by comma.
  - if no batch code is available, display `—`.
  - tax removal type value from `inv_movements.meta.tax_event`.
  - tax removal type filter value uses raw `tax_event` code.
  - `Tax-related movements only` uses raw `tax_event`; missing values and `NONE` are not tax movement rows.
  - tax removal type display label must use rule engine `tax_event_labels`.
  - when raw `tax_event = NONE`, display `—` for `税務移出種別`.
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
  - initialize `Date from` to one month ago
  - load movements
- On change of `dateFrom`, `dateTo`, tax removal type, or `Tax-related movements only`:
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
