# Tax Report List Page UI Specification

## Purpose
- Provide a tenant-scoped page to view, filter, create-entry, and delete saved `酒税申告` records.
- Keep report editing and draft generation on a dedicated editor page.
- Allow users to download saved XML/XLSX files from metadata stored on the saved report row.

## Entry Points
- Sidebar -> `酒税率管理` -> `酒税申告`
- Route: `/taxReports`
- Route name: `TaxReport`

## Users and Permissions
- Tenant user: view saved tax reports inside the current tenant scope.
- Tenant user: open the tax-report editor page for a new draft.
- Tenant user: open the tax-report editor page for an existing saved report.
- Tenant user: delete draft reports only.

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
   - `年`
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
  - `年`
  - `月`
- Actions:
  - `Cancel`
  - `生成`
- After confirm:
  - navigate to the dedicated editor page
  - pass the selected period as the initial editor context

## UI Flow Line
1. User opens `酒税申告` from the liquor-tax sidebar.
2. Page resolves the current tenant from session metadata.
3. Page loads saved `tax_reports` rows for the tenant.
4. User may filter saved rows by tax type, year, month, and status.
5. User may open `申告書作成`, choose a period, and move to the dedicated editor page.
6. User may open an existing saved row from the period link and move to the dedicated editor page.
7. User may download saved report files from the table.
8. User may delete a draft row.

## Field Definitions
### Filter Fields
- `課税種別`
  - current visible option set is `monthly`
  - filter value is stored in `filters.taxType`
- `年`
  - select built from current year range plus saved report years
- `月`
  - visible option order: `4` to `12`, then `1` to `3`
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
  - click opens the dedicated editor page
- `ステータス`
  - localized label from `statusMap`
- `酒税額合計`
  - currency-formatted JPY value
- `申告内訳（種別・ABV別）`
  - one text row per `volume_breakdown` item
  - display format:
    - `税務移出種別 · カテゴリ名 (ABV): 数量`
    - movement label uses saved `tax_event` when present
    - fallback to legacy inference only for older rows without saved `tax_event`
  - preview shows at most 3 lines in the list page
  - when more than 3 rows exist, append `...`
- `申告ファイル`
  - saved `report_files`
  - each entry represents saved file metadata
  - clicking a file downloads it from the stored Supabase Storage path
- `添付ファイル`
  - saved `attachment_files`
- Row actions:
  - `削除`

## Business Rules
- Tenant isolation:
  - all reads and deletes are scoped by the current session tenant
- Saved data source:
  - `tax_reports`
- Delete rule:
  - only `draft` rows can be deleted
- Editor separation:
  - create and edit form content is not rendered on this page
  - the page only launches the dedicated editor route
- File download:
  - uses file metadata saved on the report row
  - downloads the file from Supabase Storage
- List-page tax total:
  - derives from saved `volume_breakdown`
  - uses saved `tax_event` when present
  - falls back to legacy doc-type inference only for older rows

## Saved File Metadata
- `tax_reports.report_files` is a JSON array of file metadata objects, not a string array of file names.
- Expected metadata includes:
  - `fileName`
  - `fileType`
  - `mimeType`
  - `storageBucket`
  - `storagePath`
  - `size`
  - `generatedAt`

## Non-Scope
- No inline report editing on the list page.
- No report generation form on the list page beyond the create prompt dialog.
