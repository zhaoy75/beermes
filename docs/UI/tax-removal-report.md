# Taxable Removal Report Page UI Specification

## Purpose
- Show all `課税移出` records in one tenant-scoped read-only report page.
- Provide a business-year summary grouped by `酒類コード` and `ABV`.
- Let users review taxable-removal history without opening each movement individually.

## Entry Points
- Sidebar -> `税務管理` -> `帳票一覧` -> `課税移出一覧表`
- Route: `/taxableRemovalReport`
- Route name: `TaxableRemovalReport`

## Users and Permissions
- Tenant user: view the report inside the current tenant scope.
- Tenant user: refresh the report data.
- No edit actions are available on this page in v1.

## Page Layout
### Header
- Title: `課税移出一覧表`
- Subtitle:
  - summarize that the page shows all taxable-removal records
- Actions:
  - `Excel Export`
  - `Refresh`

### Body
1. Search section
   - `年度`
   - `month`
   - `酒類コード`
2. Business-year summary section
   - one row per `酒類コード + ABV`
3. Detail table section
   - one row per taxable-removal movement line
4. Empty state
   - shown when the tenant has no matching taxable-removal records

## UI Flow Line
1. User opens `課税移出一覧表` from `税務管理 > 帳票一覧`.
2. Page resolves current tenant context.
3. Page loads taxable-removal movement headers and lines.
4. Page renders the business-year summary using the selected `年度`.
5. User may narrow the detail table by `年度`, `month`, and `酒類コード`.
6. User may click `Excel Export` to generate a workbook and receive a download link.
7. User may refresh the page to reload the latest data.

## Field Definitions
### Summary Row Granularity
- One row represents one `酒類コード + ABV` group.
- The summary uses only the selected `年度`.

### Detail Row Granularity
- One row represents one taxable-removal `inv_movement_lines` row.
- Rows are ordered by `年月日` descending in v1.

### Search Fields
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
  - option label displays the alcohol type name resolved from master data
  - selected value still filters by the underlying liquor code
  - fallback to the raw liquor code when no master label is available

### Summary Columns
- `酒類コード`
  - resolved from batch category metadata
  - display the alcohol type name for the resolved liquor code
  - fallback to the raw liquor code when no master label is available
- `ABV`
  - resolved from batch ABV metadata
- `数量(ml)`
  - taxable-removal line quantity converted to milliliters
- `存在数`
  - package count style value
- `税率`
  - persisted tax rate displayed as `/kl`
- `酒税`
  - `数量(ml) / 1000000 * 税率`

### Detail Table Columns
- `品目`
  - alcohol type label for the displayed `酒類コード`
- `銘柄`
  - batch/product name
- `アルコール分（％）`
  - displayed ABV value
- `年月日`
  - movement datetime
- `容器`
  - package code or package name
- `数量（mℓ）`
  - line quantity converted to milliliters
- `単価（円）`
  - blank
- `価格（円）`
  - blank
- `移出区分`
  - `課税移出`
- `移出先所在地`
  - formatted destination site address
- `移出先氏名又は名称`
  - destination site name
- `ロット番号`
  - source lot number when available
- `摘要`
  - line note or movement note

## Business Rules
- Tenant isolation:
  - all reads are limited to the current tenant
- Included movements:
  - `inv_movements.status != 'void'`
  - `inv_movements.meta.tax_event = 'TAXABLE_REMOVAL'`
  - fallback: `inv_movements.meta.tax_decision_code = 'TAXABLE_REMOVAL'`
- Summary filter behavior:
  - uses selected `年度` only
- Detail filter behavior:
  - uses selected `年度`
  - applies selected `month` when not blank
  - applies selected `酒類コード` when not blank
- Tax amount:
  - uses persisted tax rate
  - converts `mL` to `kL` before multiplication

## Formatting
- Datetime:
  - use local datetime display style consistent with other admin pages
- Numeric fields:
  - use readable decimal formatting
- Blank/unavailable values:
  - display `—`

## Actions
### Excel Export
- Generate the workbook in the browser.
- Show a download link after generation succeeds.
- File name format:
  - `課税移出一覧表_<business-year>.xlsx`
- Workbook structure:
  - first sheet: same rows and columns as `年度サマリー`
  - then one sheet per month in the selected business year
- Monthly sheet rules:
  - include all detail rows for that month inside the selected business year
  - ignore the current page `month` and `酒類コード` filter inputs
  - keep the same column set as `課税移出明細`
- Month sheet order:
  - `4` through `12`
  - then `1` through `3`

### Refresh
- Reload the report dataset.
- Keep the user on the same page.

## Non-Scope
- No inline movement editing.
- No CSV export in this task.
