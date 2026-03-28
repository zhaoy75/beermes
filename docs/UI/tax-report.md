# Tax Report Page UI Specification

## Purpose
- Provide a tenant-scoped page to create, view, edit, and manage saved `酒税申告` records.
- Let users generate monthly tax-report breakdowns from inventory movement data and save the result into `tax_reports`.
- Support XML generation for the main report and a separate disposal report from the current modal data.

## Entry Points
- Sidebar -> `酒税管理` -> `酒税申告`
- Route: `/taxReports`
- Route name: `TaxReport`

## Users and Permissions
- Tenant user: view saved tax reports inside the current tenant scope.
- Tenant user: create a new tax report draft for a selected period.
- Tenant user: edit an existing saved tax report.
- Tenant user: generate XML files locally from the current report data.
- No delete action is available on this page in v1.

## Page Layout
### Header
- Title: `酒税申告`
- Subtitle:
  - summarize that the page creates and manages craft-beer tax reports
- Actions:
  - `申告書作成`
  - `Refresh`

### Body
1. Search section
   - `課税種別`
   - `課税年度`
   - `月`
   - `ステータス`
2. Saved report table
   - one row per saved `tax_reports` row
3. Empty state
   - shown when no saved reports match the current filters

### Create Prompt Dialog
- Opened from `申告書作成`
- Fields:
  - `課税種別`
  - `課税年度`
  - `月`
- Actions:
  - `Cancel`
  - `生成`

### Edit / Create Modal
- Header:
  - `申告書作成` for new rows
  - `申告書編集` for existing rows
- Form area:
  - `課税種別`
  - `課税年度`
  - `月`
  - `ステータス`
  - `酒税額合計`
- Summary section:
  - visible table of reportable movement rows
  - XML generate button
  - optional generated download link
- Disposal section:
  - visible table of disposal-only rows
  - XML generate button
  - optional generated download link
- File / attachment section:
  - `XMLファイル` textarea
  - `添付ファイル` input
  - uploaded file-name chips with remove action
- Footer actions:
  - `Cancel`
  - `Save`

## UI Flow Line
1. User opens `酒税申告` from the liquor-tax sidebar.
2. Page resolves the current tenant from session metadata.
3. Page loads reference data:
   - alcohol categories
   - UOM master rows
   - alcohol tax definitions
   - XML template file
4. Page loads saved `tax_reports` rows for the tenant.
5. User may filter the saved rows by tax type, year, month, and status.
6. User may open `申告書作成`, select a period, and generate a new draft breakdown.
7. User may edit the generated breakdown values before saving.
8. User may generate XML from the summary section or disposal section.
9. User may save the row back to `tax_reports`.
10. User may open an existing row, update it, and save it again.

## Field Definitions
### Filter Fields
- `課税種別`
  - current visible option set is `monthly`
  - filter value is stored in `filters.taxType`
- `課税年度`
  - select built from current year range plus saved report years
- `月`
  - values: `1` to `12`
  - disabled when filter tax type is `yearly`
- `ステータス`
  - values:
    - `draft`
    - `submitted`
    - `approved`

### Saved Report Table Row
- `課税種別`
  - localized label from `taxTypeMap`
- `対象期間`
  - currently displayed as `tax_year / tax_month`
- `ステータス`
  - localized label from `statusMap`
- `酒税額合計`
  - currency-formatted JPY value
- `申告内訳（種別・ABV別）`
  - one text row per `volume_breakdown` item
  - display format:
    - `移出種別 · カテゴリ名 (ABV): 数量`
- `申告XML`
  - saved `report_files`
- `添付ファイル`
  - saved `attachment_files`
- Row actions:
  - `参照`
  - `削除`


### Create / Edit Form Fields
- `課税種別`
  - default: `monthly`
  - disabled while editing an existing row
- `課税年度`
  - numeric input
  - disabled while editing an existing row
- `月`
  - required when tax type is `monthly`
  - disabled while editing an existing row
- `ステータス`
  - editable only for existing rows
  - new rows are saved as `draft`
- `酒税額合計`
  - read-only derived display
- `申告XMLファイル`
  - free text list
  - one file name per line
- `添付ファイル`
  - browser file picker
  - current implementation stores file names only, not file uploads

### Summary Section Table
- Row granularity:
  - one row per `move_type + category + ABV` group for summary movement types
- Columns:
  - `移出種別`
  - `ビール種別`
  - `ABV(%)`
  - `数量(L)`
- Editable fields:
  - `ABV`
  - `数量(L)`

### Disposal Section Table
- Row granularity:
  - one row per `move_type + category + ABV` group where `move_type = waste`
- Columns:
  - `移出種別`
  - `ビール種別`
  - `ABV(%)`
  - `数量(L)`
- Editable fields:
  - `ABV`
  - `数量(L)`

## Business Rules
- Tenant isolation:
  - all reads and writes are scoped by the current session tenant
- Saved data source:
  - `tax_reports`
- Current report period behavior:
  - the page effectively operates as monthly-only in the visible UI
  - helper code still contains legacy yearly branches, but the current visible option set exposes only `monthly`
- Summary movement types used for generated report rows:
  - `sale`
  - `tax_transfer`
  - `return`
  - `transfer`
- Disposal movement types used for generated disposal rows:
  - `waste`
- Report generation date range:
  - monthly range from the first day of the selected month to the first day of the next month
- Included source rows:
  - `inv_movements` headers in the selected period
  - matching `inv_movement_lines`
  - only lines with `package_id` or `batch_id`
- Category resolution order for batch rows:
  - batch `entity_attr` with attr code `beer_category`
- ABV resolution order:
  - batch `entity_attr` with attr code `target_abv`
- Category label resolution:
  - resolve against active `registry_def(kind = 'alcohol_type')`
  - lookup supports both id and code keys
- Volume calculation:
  - prefer `inv_movement_lines.qty` converted by `uom_id`
  - fallback to `meta.package_qty * mst_package.unit_volume`
- Supported UOM conversion:
  - `L`
  - `mL`
  - `kL`
  - `gal_us`
- Tax-rate lookup:
  - source: active `registry_def(kind = 'alcohol_tax')`
  - grouped by `tax_category_code`
  - rate chosen by movement date against `start_date` and `expiration_date`
- Total tax amount:
  - sum of `volume_l * tax_rate` for summary rows only
- Validation:
  - tax type required
  - tax year required
  - tax month required for monthly
  - status required
  - summary breakdown must not be empty

## XML Generation
### Summary XML
- Available from:
  - saved-row card action
  - summary section in the modal
- Uses summary breakdown rows only.
- File name format:
  - `R<n>年<m>月_納税申告.xtx` for monthly
  - yearly fallback branch also exists in helper code
- XML template source:
  - `/etax/R7年11月_納税申告.xtx`
- XML payload rules:
  - non-`return` rows go to `LIA110 / EHD00000`
  - `return` rows go to `LIA220 / EKD00000`
  - move type to `kubun_CD` mapping:
    - `sale` -> `1`
    - `tax_transfer` -> `2`
    - `transfer` -> `3`
    - `waste` -> `4`
  - category code falls back to `000` if unresolved or non-numeric
- After generation:
  - file downloads in the browser
  - modal flow also shows a download link
  - filename is added to `report_files`

### Disposal XML
- Available from the disposal section in the modal.
- Uses disposal rows only.
- File name format:
  - summary XML file name plus `_廃棄.xtx`
- After generation:
  - file downloads in the browser
  - modal shows a generated download link
  - filename is added to `report_files`

## Persistence Rules
- New row save:
  - inserts one `tax_reports` row
  - status forced to `draft`
  - attempts to generate the main XML file automatically if it is not already listed
- Existing row save:
  - updates the saved `tax_reports` row by id
- Persisted fields:
  - `tenant_id`
  - `tax_type`
  - `tax_year`
  - `tax_month`
  - `status`
  - `total_tax_amount`
  - `volume_breakdown`
  - `report_files`
  - `attachment_files`
- `volume_breakdown` persistence:
  - summary rows and disposal rows are merged into one saved array
- Attachment persistence:
  - current implementation saves file names only

## Formatting
- Currency:
  - JPY with zero decimal places
- Volume:
  - rendered through the shared volume-format helper
- ABV:
  - show localized numeric percent
  - fallback to `ABV不明`
- Blank/unavailable values:
  - display `—`

## Actions
### Refresh
- Reload saved report rows using the current filter state.

### Create Report
- Open the create prompt.
- After confirmation, open the modal and generate movement breakdown rows for the selected period.

### Edit Report
- Open an existing saved row in the modal.
- Split saved `volume_breakdown` into summary and disposal sections for editing.

### Generate XML
- Generate summary XML from summary rows.
- Generate disposal XML from disposal rows.
- Show a download link in the modal after successful generation.

## Non-Scope
- No delete action.
- No server-side attachment upload storage.
- No Excel export on this page.
- No multi-month or business-year aggregation view on this page.
- No direct posting to an external tax authority API in this UI.

## Other
- This page should be multi-language in English and Japanese.
