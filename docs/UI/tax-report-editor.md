# Tax Report Editor Page UI Specification

## Purpose
- Provide a dedicated page to create or edit one `酒税申告` record.
- Generate monthly tax-report breakdown data from movement records.
- Generate XML files for the main report and disposal section.
- Generate a month-scoped `課税移出一覧表` Excel from the shared taxable-removal export source when creating a new monthly draft.
- Persist generated XML/XLSX files in Supabase Storage and save file metadata in `tax_reports.report_files`.

## Entry Points
- Route from `酒税申告` list page create prompt
- Route from a saved row on the `酒税申告` list page
- Routes:
  - `/taxReports/new`
  - `/taxReports/:id`

## Users and Permissions
- Tenant user: create a new tax report draft for a selected period.
- Tenant user: edit an existing saved tax report.
- Tenant user: generate XML files from the current editor data.
- Tenant user: save the generated report files and related metadata.

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
  - read only
- `課税年度`
  - read only
- `月`
  - read only
- `ステータス`
- `酒税額合計`

### Movement Section (`移出・移入概要`)
- visible table of reportable movement rows
- XML generate button
- optional generated download link

### Disposal Section
- visible table of disposal-only rows
- XML generate button
- optional generated download link

### File / Attachment Section
- generated report file list
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
   - generate the main report XML in the browser memory
   - if the tax type is monthly, also generate the month-scoped `課税移出一覧表` Excel using the shared taxable-removal export source
5. Edit flow:
   - load the saved `tax_reports` row by id
   - populate the editor from the stored breakdown and file metadata
6. User may edit breakdown values, generate XML files, manage attachment file-name lists, and save.
7. Save behavior:
   - upload generated XML/XLSX files to Supabase Storage
   - save file metadata to `tax_reports.report_files`
   - update the `tax_reports` row
8. After save, user returns to the `酒税申告` list page.

## Field Definitions
### Create / Edit Form Fields
- `課税種別`
  - default: `monthly`
  - read only on the editor page
- `課税年度`
  - derived from the create prompt or the saved row
  - read only on the editor page
- `月`
  - required for monthly reports
  - derived from the create prompt or the saved row
  - read only on the editor page
- `ステータス`
  - editable only for existing rows
  - new rows are saved as `draft`
- `酒税額合計`
  - read-only derived display
- `添付ファイル`
  - browser file picker
  - current implementation scope still stores file names only unless attachment storage is specified separately

### Movement Section Table
- Row granularity:
  - one row per `move_type + tax_event + category + ABV` group for summary movement types
- Default sort:
  - `税務移出種別`
  - then `酒類分類`
  - then `ABV`
- Columns:
  - `税務移出種別`
  - `酒類分類`
  - `ABV(%)`
  - `数量(L)`
- Sort behavior:
  - user may click each column header to sort
  - clicking the same header toggles ascending / descending
  - initial sort remains `税務移出種別`, then `酒類分類`, then `ABV`
- Editable fields:
  - `ABV`
  - `数量(L)`

### Disposal Section Table
- Row granularity:
  - one row per `move_type + category + ABV` group where `move_type = waste`
- Columns:
  - `税務移出種別`
  - `酒類分類`
  - `ABV(%)`
  - `数量(L)`
- Editable fields:
  - `ABV`
  - `数量(L)`

### Report File Metadata
- `tax_reports.report_files` stores a JSON array of metadata objects.
- Recommended shape:
```json
[
  {
    "fileName": "R8年1月_納税申告.xtx",
    "fileType": "tax_report_xml",
    "mimeType": "application/xml",
    "storageBucket": "tax-report-files",
    "storagePath": "tenant/<tenantId>/tax-reports/<reportId>/R8年1月_納税申告.xtx",
    "size": 12345,
    "generatedAt": "2026-03-30T12:00:00Z"
  },
  {
    "fileName": "R8年1月_課税移出一覧表.xlsx",
    "fileType": "taxable_removal_excel",
    "mimeType": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "storageBucket": "tax-report-files",
    "storagePath": "tenant/<tenantId>/tax-reports/<reportId>/R8年1月_課税移出一覧表.xlsx",
    "size": 45678,
    "generatedAt": "2026-03-30T12:05:00Z"
  }
]
```

## Business Rules
- Tenant isolation:
  - all reads and writes are scoped by the current session tenant
- Saved data source:
  - `tax_reports`
- File binary storage:
  - generated XML and Excel files are stored in Supabase Storage
- File metadata storage:
  - file metadata is stored in `tax_reports.report_files`
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
  - tax basis comes from `inv_movements.meta.tax_event`
  - fallback tax basis comes from `inv_movements.meta.tax_decision_code`
  - legacy fallback only when neither field exists: infer from `doc_type`
  - displayed `税務移出種別` label must use the same movement-rule `tax_event_labels` source as `移出記録`
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
  - tax rates are handled as `/kL`
  - tax effect is based on `tax_event`, not `doc_type`
  - `TAXABLE_REMOVAL` rows add `volume_l / 1000 * tax_rate`
  - `RETURN_TO_FACTORY` rows subtract `volume_l / 1000 * tax_rate`
  - `NON_TAXABLE_REMOVAL`, `EXPORT_EXEMPT`, and `NONE` do not affect `酒税額合計`
- Validation:
  - tax type required
  - tax year required
  - tax month required for monthly
  - status required
  - movement section must not be empty
- Storage overwrite rule:
  - saving the same report updates or replaces files of the same `fileType`
  - old metadata entries for superseded files should not remain active in the saved row

## XML Generation
### Summary XML
- Uses movement-section rows only.
- File name format:
  - `R<n>年<m>月_納税申告.xtx`
- Save behavior:
  - upload file to Supabase Storage during save
  - save metadata object to `report_files`
- Download behavior:
  - editor may show a temporary download link before save
  - after save, the canonical file is downloaded from storage metadata

### Disposal XML
- Uses disposal rows only.
- File name format:
  - summary XML file name plus `_廃棄.xtx`
- Save behavior:
  - upload file to Supabase Storage during save
  - save metadata object to `report_files`

## 課税移出一覧表 Excel Generation
- New monthly draft flow automatically generates the month-scoped workbook once after the initial report breakdown is created.
- No manual `課税移出一覧表Excel` button is shown on the editor page.
- Implementation rule:
  - reuse the shared taxable-removal export source used by the `課税移出一覧表` page
- Workbook content:
  - one monthly sheet using the same columns and layout as `課税移出明細`
  - metadata rows include generation timestamp, business year, and selected month
- File name format:
  - `R<n>年<m>月_課税移出一覧表.xlsx`
- Save behavior:
  - upload file to Supabase Storage during save
  - save metadata object to `report_files`

## Non-Scope
- No persistence of generated XML/XLSX binaries in `localStorage`.
- No base64 file-content persistence inside `tax_reports.report_files`.
- No delete action on the editor page.
