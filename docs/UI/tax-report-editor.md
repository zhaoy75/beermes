# Tax Report Editor Page UI Specification

## Purpose
- Provide a dedicated page to create or edit one `酒税申告` record.
- Generate monthly tax-report breakdown data from movement records.
- Generate XML files for the main report and disposal section.
- Generate a month-scoped `課税移出一覧表` Excel from the shared taxable-removal export source when creating a new monthly draft.

## Entry Points
- Route from `酒税申告` list page create prompt
- Route from a saved row on the `酒税申告` list page
- Routes:
  - `/taxReports/new`
  - `/taxReports/:id`

## Users and Permissions
- Tenant user: create a new tax report draft for a selected period.
- Tenant user: edit an existing saved tax report.
- Tenant user: generate XML files locally from the current editor data.
- Tenant user: generate the related `課税移出一覧表` Excel locally for monthly reports.

## Page Layout
### Header
- Title:
  - `申告書作成` for new rows
  - `申告書編集` for existing rows
- Subtitle:
  - summarize that the page edits report details and related file output
- Actions:
  - `一覧へ戻る`

### Form Area
- `課税種別`
- `課税年度`
- `月`
- `ステータス`
- `酒税額合計`

### Summary Section
- visible table of reportable movement rows
- XML generate button
- optional generated download link

### Disposal Section
- visible table of disposal-only rows
- XML generate button
- optional generated download link

### File / Attachment Section
- `XMLファイル` textarea
- `添付ファイル` input
- uploaded file-name chips with remove action

### Footer Actions
- `Cancel`
- `Save`

## UI Flow Line
1. User enters the page from the list page create prompt or an existing saved row.
2. Page resolves the current tenant from session metadata.
3. Page loads reference data:
   - alcohol categories
   - UOM master rows
   - alcohol tax definitions
   - XML template file
4. New flow:
   - use selected route query values as the initial period
   - generate report breakdown data for that period
   - if the tax type is monthly, also generate the month-scoped `課税移出一覧表` Excel using the shared taxable-removal export source
5. Edit flow:
   - load the saved `tax_reports` row by id
   - populate the editor from the stored breakdown and file lists
6. User may edit breakdown values, generate XML files, manage attachment file-name lists, and save.
7. After save, user returns to the `酒税申告` list page.

## Field Definitions
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
  - batch `entity_attr` with attr code `actual_abv`
  - batch `entity_attr` with attr code `target_abv`
- Category label resolution:
  - resolve against active `registry_def(kind = 'alcohol_type')`
- Tax-rate lookup:
  - source: active `registry_def(kind = 'alcohol_tax')`
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
- Uses summary breakdown rows only.
- File name format:
  - `R<n>年<m>月_納税申告.xtx`
- After generation:
  - file downloads in the browser
  - editor page also shows a download link
  - filename is added to `report_files`

### Disposal XML
- Uses disposal rows only.
- File name format:
  - summary XML file name plus `_廃棄.xtx`
- After generation:
  - file downloads in the browser
  - editor page also shows a download link
  - filename is added to `report_files`

## 課税移出一覧表 Excel Generation
- New monthly draft flow automatically generates the month-scoped workbook once after the initial report breakdown is created.
- Implementation rule:
  - reuse the shared taxable-removal export source used by the `課税移出一覧表` page
- Workbook content:
  - one monthly sheet using the same columns and layout as `課税移出明細`
  - metadata rows include generation timestamp, business year, and selected month
- File name format:
  - `課税移出一覧表_<YYYYMM>.xlsx`

## Non-Scope
- No backend file storage for generated XML or Excel files.
- No delete action on the editor page.
