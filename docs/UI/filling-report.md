# Filling Report Page UI Specification

## Purpose
- Show filling results across all batches in one production report page.
- Provide a read-only tenant-scoped report named `詰口一覧表`.
- Let users review the latest filling date, packaged totals, package breakdown, sample volume, tank remaining volume, and loss without opening each batch individually.
- Keep report totals consistent with the existing Batch Packing and Batch Edit filling logic.

## Entry Points
- Sidebar -> `製造管理` -> `詰口一覧表`
- Route: `/fillingReport`
- Route name: `FillingReport`

## Users and Permissions
- Tenant user: view the report inside the current tenant scope.
- Tenant user: refresh the report data.
- No edit actions are available on this page in v1.

## Page Layout
### Header
- Title: `詰口一覧表`
- Subtitle:
  - summarize that the page shows filling records across all batches
- Actions:
  - `Refresh`

### Body
1. Report summary area
   - optional compact text or card showing result count
2. Search section
   - `年度`
   - `month`
   - `酒類コード`
3. Main report table
   - one row per batch with filling history
   - read-only
   - `ロット番号` is clickable
4. Batch filling detail section
   - shown below the main report table after a batch is selected
   - summary line for the selected batch
   - movement-level detail table
4. Empty state
   - shown when the tenant has no filling records

### Modal Dialog
- None in v1

## UI Flow Line
1. User opens `詰口一覧表` from `製造管理`.
2. Page resolves current tenant context.
3. Page loads batch rows with filling history.
4. User may narrow the visible rows by `年度`, `month`, and `酒類コード`.
5. User may sort the table by clicking a column header.
6. User clicks `ロット番号` for one batch.
7. Page renders one row per visible batch and one detail section for the selected batch.
8. User may refresh the page to reload the latest data.

## Field Definitions
### Report Row Granularity
- One row represents one batch.
- A batch is included only when it has at least one non-void filling movement.

### Batch Detail Row Granularity
- One row represents one related filling movement in `inv_movements`.
- The detail section is driven by the batch selected from the main table.
- Rows are ordered by `日付` ascending.

### Table Columns
- `ロット番号`
  - display `mes_batches.batch_code`
- `名前`
  - display `mes_batches.product_name`
  - fallback: `mes_batches.batch_label`
- `最終充填日`
  - latest filling datetime for the batch
  - source: latest `inv_movements.movement_at` among filling movements
- `総量 (L)`
  - display `mes_batches.actual_yield`
- `酒類コード`
  - batch category/code value
  - resolution order:
    - batch attribute `beer_category`
    - recipe category
    - `mes_batches.meta.beer_category`
    - `mes_batches.meta.category`
- `ABV`
  - target ABV for the batch
  - resolution order:
    - batch attribute `target_abv`
    - recipe target ABV
    - `mes_batches.meta.target_abv`
- dynamic package-type columns
  - each existing package type becomes one table column
  - column header source: `mst_package.package_code`
  - cell value: aggregated package number for that batch and package type
- `サンプル(Liter)`
  - total sample volume across filling movements of the batch
- `タンク残(Liter)`
  - tank left volume from the latest filling movement only
- `欠減(Liter)`
  - total filling loss across filling movements of the batch

### Package Breakdown Rules
- Aggregate only non-sample filling lines.
- Group by package type.
- Sort groups by `mst_package.package_code` ascending.
- Build the package columns from the distinct package types present in the loaded result.
- If a batch does not use a package type shown in the table:
  - leave that cell blank

### Batch Detail Section
- Summary line fields:
  - `ロット番号`
  - `名前`
  - `酒類コード`
  - `ABV`
  - `Filling Tank`
- `Filling Tank`
  - display the distinct tank numbers used by the selected batch's filling movements
  - join multiple tank numbers in display order

### Batch Detail Table Columns
- `日付`
  - movement datetime from `inv_movements.movement_at`
- `樽詰め前 深さ、数量`
  - one display cell containing:
    - `tank_fill_start_depth`
    - `tank_fill_start_volume`
- dynamic package-type columns
  - column set is built from package types present in the selected batch's movement rows
  - each package type renders two sub columns:
    - `本数`
    - `容量 (L)`
  - `本数` cell value is the package number for that movement row and package type
  - `容量 (L)` cell value is the packaged volume in liters for that movement row and package type
  - if a non-fixed filling line stores volume in the package master UOM, convert it to liters using `mst_package.volume_uom` before display
  - if `mst_package.volume_uom` is persisted as a UOM id, resolve it through `mst_uom.code` before conversion
- `サンプル`
  - sample volume for that movement
- `総数量`
  - render as three sub columns:
    - `樽`
    - `缶・瓶`
    - `総量 (L)`
  - `樽`: keg unit count for that movement
  - `缶・瓶`: non-keg unit count for that movement
  - `総量 (L)`: non-sample packaged liters for that movement
- `タンク残`
  - `tank_left_volume` for that movement
- `欠減`
  - derived movement loss using the same filling-loss rule as the operational screens

### Batch Detail Total Row
- Append one total row after the movement rows.
- `日付`
  - blank
- `樽詰め前 深さ、数量`
  - blank
- package-type sub columns
  - `本数`: sum across the selected batch's movement rows
  - `容量 (L)`: sum across the selected batch's movement rows
- `サンプル`
  - sum across the selected batch's movement rows
- `総数量`
  - render as three sub columns
  - `樽`: sum of keg unit counts across the selected batch's movement rows
  - `缶・瓶`: sum of non-keg unit counts across the selected batch's movement rows
  - `総量 (L)`: sum of packaged liters across the selected batch's movement rows
- `タンク残`
  - show the last movement row's `タンク残` in ascending `日付` order
- `欠減`
  - sum across the selected batch's movement rows

### Formatting
- Datetime:
  - use local datetime display style consistent with other admin pages
- Volume / numeric fields:
  - use numeric formatting with reasonable decimal precision
- Blank/unavailable values:
  - display `—`

## Actions
### Refresh
- Reload the report dataset.
- Keep the user on the same page.

### Search Section
- `年度`
  - required visible field
  - default value: current business year
  - business year range definition:
    - April 1 to March 31
- `month`
  - values: `1` to `12`
  - default value: blank
  - interpreted as calendar month inside the selected business year range
- `酒類コード`
  - filters by the liquor-code value shown in the table

### Column Sort
- All visible table columns must be sortable.
- Sort direction toggle:
  - first click: ascending
  - second click: descending
- Dynamic package-type columns must also be sortable by their package-number values.
- This sort requirement applies to the main report table.
- The batch detail table uses a fixed `日付` ascending order in v1.

## Business Rules
- Tenant isolation:
  - all reads are limited to the current tenant
- Included movements:
  - `inv_movements.status != 'void'`
  - `inv_movements.meta.source = 'packing'`
  - `inv_movements.meta.packing_type = 'filling'`
- Compatibility fallback:
  - implementation may also accept `meta.movement_intent = 'PACKAGE_FILL'`
- Page is read-only:
  - no create
  - no edit
  - no delete

### Filling Calculation Rules
- This page must reuse the same filling calculation logic as Batch Packing / Batch Edit.
- Shared source of truth:
  - `beeradmin_tail/src/lib/batchFilling.ts`
- Non-sample lines:
  - counted in total packaged volume
  - counted in package breakdown columns
- Sample lines:
  - excluded from total packaged volume
  - excluded from package breakdown columns
  - included in sample volume
- Derived loss:
  - `tank_fill_start_volume - tank_left_volume - non_sample_line_volume - sample_volume`
- If persisted `sample_volume` is missing:
  - derive it from `meta.filling_lines` where `sample_flg = true`

### Tank Remaining Rule
- `タンク残(Liter)` is not summed across movements.
- The page must display the `tank_left_volume` from the latest filling event for the batch.

### Batch Detail Rules
- Clicking `ロット番号` selects the batch for the detail section.
- If no batch has been clicked yet:
  - show a neutral empty prompt in the detail section
- Package columns in the detail table are scoped to the selected batch only.

## Data Handling
### Main Tables
- `mes_batches`
  - batch code, label, product name, recipe reference, meta
- `inv_movements`
  - filling movement header and movement date
- `inv_movement_lines`
  - line-level package and quantity detail
- `mst_package`
  - package code and fixed-volume metadata
- `attr_def` / `entity_attr`
  - batch attribute lookup for `beer_category` and `target_abv`

### Source-of-Truth Rule
- Current operational filling records are persisted in:
  - `inv_movements`
  - `inv_movement_lines`
  - `inv_movements.meta`
- `mes_batch_steps` must not be treated as the primary report source unless implementation confirms the tenant data is populated and intentionally used.

### Recommended Load Sequence
1. Resolve tenant.
2. Load filling movement headers for the tenant.
3. Load matching movement lines.
4. Load referenced batches.
5. Load package master data.
6. Load batch attribute values for category and ABV.
7. Aggregate rows client-side for v1.

## Sorting / Display Behavior
- Default sort:
  - `最終充填日` descending
- Default filter:
  - `年度 = current business year`
  - `month = blank`
  - `酒類コード = blank`
- v1 may render a plain table without advanced filtering.
- The table may scroll horizontally when many package types exist.
- If no rows exist:
  - show an empty-state message instead of a blank page

## Error Handling
- On fetch error:
  - clear current rows if needed
  - show a toast with the error message
- On partial missing historic fields:
  - show blanks rather than synthetic values

## Non-Scope
- Inline filtering
- CSV export
- Print layout
- Pagination
- Drill-down dialog
- Batch edit navigation from this page

## Other
- This page should be multilingual (English and Japanese).
- The Japanese UI label must be `詰口一覧表`.
- The page should visually match the existing tenant admin page shell.
