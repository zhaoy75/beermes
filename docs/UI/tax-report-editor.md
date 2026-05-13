# Tax Report Editor Page UI Specification

## Purpose
- Provide a dedicated page to create or edit one `酒税申告` record.
- Generate monthly tax-report breakdown data from movement records.
- Generate XML files for the main report and disposal section.
- Generate a yearly `課税移出一覧表` Excel from the shared taxable-removal export source when saving a monthly report.
- Generate the supporting yearly ledger Excel package when saving a report:
  - `課税移出一覧表_<year>.xlsx`
  - `未納税移出帳_<year>.xlsx`
  - `輸出免税帳_<year>.xlsx`
  - `未納税移入帳_<year>.xlsx`
  - `戻入帳_<year>.xlsx`
- Persist generated XML/XLSX files in Supabase Storage and save file metadata in `tax_reports.report_files`.
- Persist the source movement references used by the report so submitted/approved reports can block operational rollback of reported movements.

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

## Source Movement Tracking
- Backend RPCs are the authority for source movement selection, tax breakdown calculation, `tax_reports` save/update, and source-reference persistence.
- The editor calls `tax_report_generate` for report creation/regeneration.
- New report creation must not create a `tax_reports` row when the selected period has no reportable source movement lines.
- If `tax_report_generate` returns `TRG005`, the editor shows an empty-period message and returns to the list page.
- If an existing editable report has no generated report rows, save must show the empty-period/validation message instead of returning silently.
- Source references are stored in `tax_report_movement_refs`, not embedded only in `tax_reports.volume_breakdown`.
- The backend must replace refs atomically whenever it saves the report:
  - delete old refs for `tax_report_id`
  - insert refs for the current generated source movement lines
- The frontend uses the returned saved report data for edit/preview and XML/file generation.
- The frontend must not submit a report whose status is `stale`.
- Draft refs do not block movement rollback.
- Submitted/approved refs block movement rollback for included movements.
- If a source movement is rolled back or materially changed while a draft report exists, the referenced draft report must be marked `stale` and regenerated before XML export/submission.

## PDF / Guide References
- Use only the PDFs directly under `docs/taxpdf` as the primary local visual samples for this redesign:
  - `docs/taxpdf/酒税納税申告書_4095_01.pdf`
    - `LIA010` / 酒税納税申告書
  - `docs/taxpdf/税額算出表_0024002-128.pdf`
    - `LIA110` / 税額算出表
  - `docs/taxpdf/軽減税額算出表_0024002-128.pdf`
    - `LIA130` / 軽減税額算出表
  - `docs/taxpdf/R8年3月_戻入れ酒類の控除(還付)税額計算書.pdf`
    - `LIA220` / 戻入れ酒類の控除(還付)税額計算書
  - `docs/taxpdf/R8年3月_輸出免税酒類輸出明細書兼輸出酒類販売場における購入明細書.pdf`
    - `LIA260` / 輸出免税酒類輸出明細書兼輸出酒類販売場における購入明細書
  - `docs/taxpdf/shinkokup04.pdf`
    - confirms the `酒税納税申告（月分申告用）` form set includes the main return, tax calculation table, return/deduction attachments, `未納税移出免税明細書`, `輸出免税酒類輸出明細書兼輸出酒類販売場における購入明細書`, and tax-accountant attachments
- The guide file was found under:
  - `docs/taxpdf/docfromcustomer/20260416データ/承認酒類製造者に対する酒税の税率の特例措置を適用する場合の酒税納税申告書の作成の手引.pdf`
- Guide findings that affect the UI spec:
  - `LIA110` is grouped by alcohol code/category, alcohol percentage, and e-Tax tax-rate application `区分`.
  - `LIA110` `区分` is not a movement `tax_event`; it is the tax-rate application code shown on the form.
  - `tax_event` determines which quantity column is populated:
    - normal/taxable removals contribute to `①総移出数量` and taxable-standard calculation
    - `NON_TAXABLE_REMOVAL` contributes to `②未納税移出数量`
    - `EXPORT_EXEMPT` contributes to `③輸出免税数量`
    - `RETURN_TO_FACTORY` contributes to `LIA220`, not to `LIA110`
  - `LIA130` row `⑭ 申告対象製造場 合計酒税額` is transferred to `LIA010` tax amount field `①`.
  - `LIA260` is the export detail attachment corresponding to export-exempt quantities, not a replacement for `LIA110` summary quantities.
  - The guide and form list also include `LIA230`, `LIA240`, and `LIA250`; XML generation now includes these forms when source rows exist, while full editor tabs/previews remain future UI work.

## Page Layout
### Header
- Title:
  - `申告書作成` for new rows
  - `申告書編集` for existing rows
- Subtitle:
  - summarize that the page edits report details and related file output
- Actions:
  - `一覧へ戻る`
  - `保存`
- The `保存` button is placed immediately to the right of `一覧へ戻る`.
- The header `保存` button uses the same save handler and disabled/loading state as the footer `Save` action.

### Summary Area
- Show compact report metadata:
  - `課税種別`
    - read only
  - `年`
    - read only
  - `月`
    - read only
  - `ステータス`
- Do not show LIA010 tax amount fields in the page header/title area; those values belong to the `LIA010` edit panel.

### Mode Switch
- A segmented control is shown on the right side of the form tab toolbar:
  - `編集`
  - `帳票プレビュー`
- The default mode is `帳票プレビュー`.
- The selected mode controls the selected form tab content only.
- The selected form tab remains unchanged when the user switches modes.
- `編集` mode:
  - keeps the UI simple and table-oriented
  - shows editable controls for user-owned fields in the selected form
  - prioritizes changing field contents over reproducing the PDF layout
  - keeps calculated totals, subtotal rows, generated rows, and XML-derived metadata read-only
- `帳票プレビュー` mode:
  - shows a read-only e-Tax/PDF-like Vue preview for the selected form
  - uses the same in-memory draft state as edit mode
  - does not write to `tax_reports` or regenerate XML by itself
  - prioritizes visual fidelity to the sample PDFs over edit ergonomics

### Form Tabs
- The editor is organized by e-Tax form block:
  - `LIA010 酒税納税申告書`
  - `LIA110 税額算出表`
  - `LIA130 軽減税額算出表`
  - `LIA220 戻入れ酒類の控除(還付)税額計算書`
  - `LIA260 輸出免税酒類輸出明細書兼輸出酒類販売場における購入明細書`
- Tabs should use short user-facing captions and browser title/tooltip text, each 14 characters or less.
- Full official form names may remain available through accessibility labels and documentation, but should not be used as the browser tooltip text.
- Tabs should not show XML form codes such as `LIA010`; those codes can remain internal or appear only in developer/spec documentation.
- Tabs should use a rounded segmented-control treatment so the panel switch reads as one compact control instead of separate card buttons.
- The active form panel should start directly below the tab/mode toolbar; avoid extra vertical whitespace between the two.
- The `納税申告XML作成` action should sit to the right of the mode switch in the same toolbar so it is available from both edit and preview modes.
- Edit-mode field-list panels should use compact rows and internal scrolling when the field list is long, so the panel does not consume excessive vertical space.
- Tabs for optional forms should remain visible when the form is relevant to the current report.
- Empty optional forms should show a clear empty state in edit mode and a blank/empty official-style form in preview mode only when that helps review.
- Current optional XML-only forms without full tabs:
  - `LIA230`
  - `LIA240`
  - `LIA250`

### LIA010 Panel (`酒税納税申告書`)
- Edit mode:
  - shows the filing period, tenant/profile references, declaration type, and calculated tax totals inside the panel body
  - profile-derived fields are read-only unless profile editing is explicitly linked from this page
  - tax total fields are read-only and sourced from the current draft calculation
  - lists every field currently emitted by the `LIA010` XML builder:
    - `EFA00010` 申告対象年月
    - `EFB00010` 提出年月日
    - `EFB00020` 提出先税務署
    - `EFB00030` 製造場郵便番号
    - `EFB00040` 製造場所在地
    - `EFB00050` 製造場名称
    - `EFB00060` 製造場電話番号
    - `EFB00070` 納税者郵便番号
    - `EFB00080` 納税者住所
    - `EFB00090` 納税者電話番号
    - `EFB00100` 納税者氏名又は名称
    - `EFB00110` 代表者氏名
    - `kubun_CD` 申告区分
    - `EFD00020` 税額
    - `EFD00030` 100円未満切捨額
    - `EFD00040` 還付税額
    - `EFD00050` 納付税額
    - `EFD00090` 修正申告還付税額
    - `EFD00100` 修正申告納付税額
    - `EFD00110` 差引納付税額
    - `EFE00010` 税理士氏名
    - `EFE00020` 税理士電話番号
    - `EFG00000` 還付金融機関
    - `EFI00000` 作成者名
- Preview mode:
  - renders the main tax return form as a paper-like e-Tax preview
  - highlights the final tax amount that will be written to `LIA010/EFD00020`

### LIA110 Panel (`税額算出表`)
- Edit mode:
  - shows a simple editable movement table currently described as `移出・移入概要`
  - groups source data by alcohol category/code, alcohol percentage, and e-Tax tax-rate application `区分`
  - shows `tax_event` as the source movement classification, but does not use it as the e-Tax `区分`
  - allows editing only user-owned detail values such as `ABV`, source quantities, and remarks where the row type permits it
  - keeps derived summary rows, category subtotal rows, and grand total rows read-only
  - provides XML generation status and warnings relevant to summary rows
- Preview mode:
  - renders one or more `LIA110` paper-like pages
  - uses the same paging rule as XML generation
  - follows the sample layout:
    - `①総移出数量`
    - `②未納税移出数量`
    - `③輸出免税数量`
    - `④課税標準数量`
    - `⑤税率`
    - `⑥税額`
    - `⑦軽減後税額`
    - `⑧控除税額`
    - `⑨算出税額`

### LIA130 Panel (`軽減税額算出表`)
- Edit mode:
  - shows the reduced tax calculation inputs and outputs
  - prior fiscal-year cumulative amount is read from saved `tax_reports.total_tax_amount`
  - calculated amounts are read-only
  - lists every field currently emitted by the `LIA130` XML builder:
    - `EQA00010` 申告対象年月
    - `EQB00020` 申告対象製造場
    - `EQC00010` 前月までの当年度酒税累計額
    - `EQC00050` 当月分本則税額
    - `EQC00070` 当月分本則税額
    - `EQC00080` 当月分軽減後税額
    - `EQC00100` 当月分本則税額
    - `EQC00120` 当月分本則税額
    - `EQC00130` 当月分軽減後税額
    - `EQC00290` 戻入控除前累計本則税額
    - `EQC00310` 戻入控除分本則税額
    - `EQC00330` 戻入控除分本則税額
    - `EQC00340` 戻入控除分軽減後税額
    - `EQC00360` 差引本則税額
    - `EQC00380` 差引本則税額
    - `EQC00390` 差引軽減後税額
    - `EQC00400` 戻入控除後累計本則税額
    - `EQD00000` 軽減割合の区分
    - `EQE00040` 申告対象製造場合計酒税額
- Preview mode:
  - renders the official-style reduced tax calculation form
  - uses the same calculation source as generated XML
  - shows:
    - prior fiscal-year cumulative standard tax through the previous month
    - current-month standard tax and reduced tax
    - return/deduction standard tax and reduced tax
    - net standard tax and net reduced tax
    - cumulative standard tax before and after return/deduction
  - does not update `tax_reports.total_tax_amount`

### LIA220 Panel (`戻入れ酒類の控除(還付)税額計算書`)
- Edit mode:
  - shows source return rows where `tax_event = RETURN_TO_FACTORY` for review and correction
  - allows editing user-owned row values when required for report review
  - does not treat generated LIA220 subtotal rows as editable source rows
- Preview mode:
  - renders one or more `LIA220` paper-like pages when return rows exist
  - outputs source/detail rows with `区分 = 1`
  - outputs generated subtotal rows with `区分 = 7`
  - subtotal rows are generated per alcohol category/code and ABV
  - subtotal rows split further by tax rate when the same alcohol category/code and ABV contain multiple tax rates, because one subtotal row must have one constant tax rate
  - subtotal rows sum quantity and tax amount from the matching detail rows
  - uses stored `tax_amount` when available; it must not reverse-calculate tax rate from truncated tax amount
  - LIA130 return/deduction totals consume only the generated `区分 = 7` subtotal rows, so previewing both detail and subtotal rows does not double-count the deduction

### LIA260 Panel (`輸出免税酒類輸出明細書兼輸出酒類販売場における購入明細書`)
- Edit mode:
  - shows export-exempt detail rows separately from the `LIA110` summary quantity
  - row fields follow `LIA260-003.xsd`:
    - `区分`
    - `酒類コード`
    - `酒類の品目別等`
    - `アルコール分別`
    - `数量`
    - `輸出年月日又は販売年月日`
    - `仕向地`
    - `輸出港の所轄税関`
    - `輸出者又は国際第二種貨物利用運送事業者の住所`
    - `輸出者又は国際第二種貨物利用運送事業者の氏名又は名称`
  - optional panel-level field:
    - `参考事項`
  - the sample layout combines exporter/carrier address and name into one visual column, but XML keeps them as separate fields:
    - `EOD00120`
    - `EOD00130`
  - XML output is enabled from current `EXPORT_EXEMPT` rows as the first source.
  - Destination and customs-office fields remain blank/omitted until those values are persisted in source data.
- Preview mode:
  - renders one or more `LIA260` paper-like pages
  - shows up to 9 detail rows per page according to the schema

### File / Attachment Section
- generated report file list
- `添付ファイル` input
- uploaded file-name chips with remove action

### Footer Actions
- `Cancel`
- `Save`
- Keep the footer `Save` action for users who finish editing at the bottom of the page.
- The header `保存` action is an additional shortcut and does not replace the footer action.

## UI Flow Line
1. User enters the page from the list page create prompt or an existing saved row.
2. Page resolves the current tenant from session metadata.
3. Page loads reference data:
   - movement-rule labels
   - tenant tax-report profile
   - XML template file when XML output is requested
4. New flow:
   - use selected route query values as the initial period
   - call `tax_report_generate` for that period
   - use the returned saved report row as the editor state
   - if the tax type is monthly, prepare the generated supporting workbook package when saving files
5. Edit flow:
   - load the saved `tax_reports` row by id
   - populate the editor from the stored breakdown and file metadata
6. User may edit breakdown values, generate XML files, manage attachment file-name lists, and save.
7. Save behavior:
   - regenerate the report through `tax_report_generate` so source movement refs match the saved aggregate
   - upload generated XML/XLSX files and supporting ledger workbooks to Supabase Storage
   - call `tax_report_generate` again with the generated file metadata and attachments
   - call `tax_report_set_status` when the requested final status is `submitted` or `approved`
8. After save, user returns to the `酒税申告` list page.

## Field Definitions
### Create / Edit Form Fields
- `課税種別`
  - default: `monthly`
  - read only on the editor page
- `年`
  - derived from the create prompt or the saved row
  - read only on the editor page
- `月`
  - required for monthly reports
  - derived from the create prompt or the saved row
  - visible option order: `4` to `12`, then `1` to `3`
  - read only on the editor page
- `ステータス`
  - editable only for existing rows
  - new rows are saved as `draft`
- `本則税額合計`
  - read-only derived display
  - means the tax amount before `LIA130` reduction
  - must not be labeled as the final liquor tax amount
- `軽減税額`
  - read-only derived display
  - `0` when `LIA130` is not included
- `納付税額`
  - read-only derived display
  - uses the value that will be written to `LIA010/EFD00020`
- `還付税額`
  - read-only derived display
- `最終納付税額`
  - read-only derived display
  - uses the final payable value after reduction, returns, and rounding
- `添付ファイル`
  - browser file picker
  - current implementation scope still stores file names only unless attachment storage is specified separately

### Movement Section Table
- Row groups:
  - `LIA110` detail rows:
    - one row per `category + alcohol code + ABV + tax-rate application 区分` group for non-return summary movement types
    - retain `tax_event` only as the source movement classification used to populate quantity columns and remarks
    - exclude rows where `tax_event = NONE` or `RETURN_TO_FACTORY_NON_TAXABLE`; they are not displayed and are not output to XML
  - `LIA110` derived summary rows:
    - generated by the system from detail rows
    - not source movement rows
    - read-only and recalculated whenever detail rows change
  - `LIA220` return rows:
    - rows where `tax_event = RETURN_TO_FACTORY`
    - raw source rows are shown separately from `LIA110` `区分` rows when return editing/review is required
    - preview/XML include source/detail rows with `区分 = 1`
    - preview/XML include generated subtotal rows grouped by alcohol category/code and ABV with `区分 = 7`
    - if the same alcohol category/code and ABV has multiple tax rates, preview/XML keeps separate subtotal rows per tax rate
    - generated LIA220 subtotal rows are output rows, not editable source rows, and are recalculated from the source return rows
    - LIA130 return/deduction totals are calculated from the generated `区分 = 7` subtotal rows only
    - output to `LIA220`, not to `LIA110`
- Default sort:
  - `酒類分類` asc
  - then `区分` asc
  - then `ABV` desc
- Columns:
  - `区分`
    - e-Tax `LIA110/EHD00010/kubun_CD`
    - detail rows: `0` = 本則税率適用
    - detail rows: `1` = 措置法適用
    - detail rows: `2` = 沖縄特例適用
    - detail rows: `3` = 措置法/経過措置 and 沖縄特例 both apply
    - derived tax-rate-application subtotal rows: `7` only for attachment forms that require it, such as `LIA220`
    - derived category subtotal rows: `8`
    - derived grand total row: `9`
  - `酒類分類`
  - `ABV(%)`
  - `①総移出数量`
  - `②未納税移出数量`
  - `③輸出免税数量`
  - `④課税標準数量`
  - `⑤税率`
  - `⑥税額`
  - `⑦軽減後税額`
  - `⑧控除税額`
  - `⑨算出税額`
  - `税務移出種別`
- Sort behavior:
  - user may click each column header to sort
  - clicking the same header toggles ascending / descending
  - initial sort is `酒類分類`, then `区分`, then `ABV`
- Grouping behavior:
  - for every `category + tax-rate application 区分` detail group, generate a read-only summary row with the same `区分`
  - for every `category` group, generate a read-only subtotal row with `区分 = 8`
  - generate one read-only grand total row with `区分 = 9`
- Editable fields:
  - `ABV` is editable only on detail rows
  - source quantity fields are editable only on detail rows
  - derived summary rows are not editable

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
  },
  {
    "fileName": "未納税移出帳_2026.xlsx",
    "fileType": "non_taxable_removal_ledger_excel",
    "mimeType": "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    "storageBucket": "tax-report-files",
    "storagePath": "tenant/<tenantId>/tax-reports/<reportId>/non_taxable_removal_ledger_excel/未納税移出帳_2026.xlsx",
    "size": 56789,
    "generatedAt": "2026-03-30T12:06:00Z"
  }
]
```

## Business Rules
- Tenant isolation:
  - all reads and writes are scoped by the current session tenant
- Saved data source:
  - `tax_reports`
- Source movement reference source:
  - `tax_report_movement_refs`
  - generated by `tax_report_generate`
  - replaced atomically whenever a draft/stale report is regenerated
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
- Excluded source tax events:
  - `NONE`
  - `RETURN_TO_FACTORY_NON_TAXABLE`
  - excluded from editor display, XML output, and source refs
- Return output rule:
  - `return` rows are used for `LIA220` return output, not for `LIA110` `区分` rows
- Disposal movement types used for generated disposal rows:
  - `waste`
- Report generation date range:
  - monthly range from the first day of the selected month to the first day of the next month
- Included source rows:
  - `inv_movements` headers in the selected period
  - tax basis comes from `inv_movements.meta.tax_event`
  - fallback tax basis comes from `inv_movements.meta.tax_decision_code`
  - legacy fallback only when neither field exists: infer from `doc_type`
  - displayed `税務移出種別` label must use the same movement-rule `tax_event_labels` source as `移出登録`
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
  - `NON_TAXABLE_REMOVAL`, `EXPORT_EXEMPT`, and `NONE` do not affect `本則税額合計`
  - `本則税額合計` is not the final filing amount when `LIA130` reduction or returns apply
- e-Tax `区分` code semantics:
  - `0` = 本則税率適用
  - `1` = 措置法適用
  - `2` = 沖縄特例適用
  - `3` = 措置法/経過措置 and 沖縄特例 both apply
  - `7` = 税率適用区分別計 for return/deduction attachment forms
  - `8` = 品目区分別計
  - `9` = 総合計
  - this code must not be derived directly from `tax_event`
- LIA130 cumulative source:
  - before creating the main report XML, read prior monthly rows from `tax_reports`
  - source column: `tax_reports.total_tax_amount`
  - scope: same tenant, `tax_type = monthly`, same Japanese fiscal year, months before the current report month
  - fiscal year starts in April and ends in March
  - April reports use `0` when there are no prior fiscal-year months
  - January to March reports sum rows from the previous calendar year's April through the previous month
  - `tax_reports.total_tax_amount` remains the monthly standard/net tax amount before LIA130 reduction so future months can use it as cumulative `本則税額`
- LIA130 reduction rule:
  - current supported reduction category: `Ａ`
  - current supported reduction rate: `0.8`
  - current-month and return reduced amounts are floored separately after multiplying by the reduction rate
  - final reduced tax amount is current-month reduced tax minus return reduced tax
  - final reduced tax amount is used in the generated XML for `LIA130/EQE00040` and `LIA010/EFD00020`
  - final reduced tax amount must not replace `tax_reports.total_tax_amount`
- Validation:
  - tax type required
  - tax year required
  - tax month required for monthly
  - status required
  - `LIA110` source/detail section must not be empty
- Storage overwrite rule:
  - saving the same report updates or replaces files of the same `fileType`
  - old metadata entries for superseded files should not remain active in the saved row

## Component Design Guidance
- `TaxReportEditor.vue` should be the page shell:
  - load/create/edit flow
  - save and file generation actions
  - summary metrics
  - mode switch
  - selected form tab
- Form-specific logic should be split into child components during implementation.
- Recommended component grouping:
  - `TaxReportLia010Editor.vue`
  - `TaxReportLia010Preview.vue`
  - `TaxReportLia110Editor.vue`
  - `TaxReportLia110Preview.vue`
  - `TaxReportLia130Editor.vue`
  - `TaxReportLia130Preview.vue`
  - `TaxReportLia220Editor.vue`
  - `TaxReportLia220Preview.vue`
  - `TaxReportLia260Editor.vue`
  - `TaxReportLia260Preview.vue`
- A shared paper preview frame should be used by all preview components.
- The preview should look like a document page, not an application data table:
  - gray preview canvas
  - centered white A4-like page
  - official-form black borders
  - compact typography similar to the sample PDFs
  - boxed metadata and taxpayer/factory areas
  - table headers and body cells arranged close to each referenced sample PDF
- Preview components should be hand-tuned per form from the local sample PDFs; they should not reuse the simplified edit table layouts.
- Edit components should remain simple data-entry/review tables and should not copy the PDF layout when that reduces editing clarity.
- Preview pages use landscape A4 proportions because the local sample PDFs are landscape forms.
- Preview canvas controls:
  - provide zoom out, zoom in, reset to 100%, and fit-to-width controls
  - show the current zoom percentage
  - fit the page to the available panel width by default when the editor opens in preview mode
  - keep scrollbars available when the page is larger than the viewport
  - allow drag-to-pan inside the preview canvas so users can slide the page around without using only scrollbars
- First-pass preview fidelity targets:
  - `LIA010`: large centered title, left period/date area, submitter block, tax office processing block, tax calculation block, and lower bank/notes areas
  - `LIA110`: dense 18-row ruled table with the official tax calculation column order
  - `LIA130`: landscape reduced-tax grid with organizer/factory boxes and calculation rows
  - `LIA220`: dense 18-row ruled return/deduction table
  - `LIA260`: dense 9-row ruled export-detail table plus reference-notes area
- `LIA130` preview must be closer to the sample than the first implementation:
  - date block on the left and title centered
  - organizer/factory box on the right
  - diagonal top-left header cell
  - gray/diagonal non-entry cells
  - numbered rows ① through ⑭
  - lower `軽減割合の区分` box and final-total rows
- Official form labels inside paper previews may remain Japanese even when the application locale is English, because the output document is an e-Tax form.
- App-shell labels such as mode switch, tab captions, buttons, and errors should remain localized through Vue i18n.

## XML Generation
### Summary XML
- Uses movement-section data only.
- Before building XML, also loads prior fiscal-year monthly totals from `tax_reports.total_tax_amount` for `LIA130/EQC00010`.
- Current generated form order in the `CATALOG` and `CONTENTS`:
  - `LIA010`
  - `LIA110`
  - `LIA130`
  - `LIA220`
  - `LIA260`
- `LIA010` output:
  - uses the final LIA130 reduced tax amount when `LIA130` is included
  - otherwise uses the normal calculated total tax amount
- `LIA110` output:
  - uses non-return detail rows plus generated tax-rate-application and category summary rows
  - excludes `tax_event = NONE` rows
  - excludes `tax_event = RETURN_TO_FACTORY_NON_TAXABLE` (`移入`) rows
  - recalculates generated summary rows from detail rows during XML generation
  - e-Tax `EHD00010/kubun_CD` is the tax-rate application code, not the `tax_event`
  - `TAXABLE_REMOVAL` contributes to taxable standard quantity and tax
  - `NON_TAXABLE_REMOVAL` contributes to `EHD00060` / 未納税移出数量
  - `EXPORT_EXEMPT` contributes to `EHD00070` / 輸出免税数量
  - `RETURN_TO_FACTORY` is output through `LIA220`
  - unknown tax events are output as `摘要`; `NONE` and `RETURN_TO_FACTORY_NON_TAXABLE` rows are excluded before XML generation
- `LIA130` output:
  - `EQC00010` = prior fiscal-year cumulative standard tax amount from saved `tax_reports.total_tax_amount`
  - current-month standard tax before returns comes from the `LIA110` grand total
  - return/deduction standard tax comes from the generated `LIA220` `kubun_CD = 7` subtotal rows only
  - net standard tax = current-month standard tax minus return/deduction standard tax
  - reduced net tax = `floor(current-month standard tax * 0.8) - floor(return/deduction standard tax * 0.8)` for category `Ａ`
  - `EQE00040` = reduced net tax
- `LIA220` output:
  - uses `RETURN_TO_FACTORY` return rows
  - XML uses the same detail + subtotal LIA220 row sequence as the preview
  - source/detail rows use `EKD00010/kubun_CD = 1`
  - generated subtotal rows use `EKD00010/kubun_CD = 7`
  - subtotal rows are grouped by alcohol category/code and ABV
  - subtotal rows are additionally split by tax rate when needed so each subtotal XML row has a single constant tax rate
  - each subtotal row sums grouped quantity and tax amount; stored `tax_amount` is preferred before fallback calculation
  - XML and preview must show the same LIA220 row count, category, ABV, quantity, tax rate, and tax amount
- `LIA260` output:
  - enabled when `EXPORT_EXEMPT` rows exist
  - uses `EXPORT_EXEMPT` detail rows rather than the summarized `LIA110/EHD00070` quantity alone
  - outputs up to 9 `EOD00000` detail rows per `LIA260` page
  - required detail fields follow `LIA260-003.xsd`
  - `EOD00010/kubun_CD` uses the same tax-rate application code semantics as the guide
  - uses the report period date as the fallback `EOD00090` date until movement-level export date is persisted
  - omits optional destination/customs-office fields when source data is unavailable; do not write placeholder filing values
- `LIA230` output:
  - enabled when rows exist where `tax_event = RETURN_TO_FACTORY_NON_TAXABLE` or `tax_attachment_form = LIA230`
  - outputs detail rows and generated `区分 = 7` subtotal rows
  - outputs up to 18 rows per page
  - contributes its deduction total to `LIA130/EQE00020`
- `LIA240` output:
  - enabled when rows are tagged `tax_attachment_form = LIA240` or carry `disaster_compensation_amount`
  - outputs detail rows and generated `区分 = 7` subtotal rows
  - outputs up to 18 rows per page
  - contributes its deduction total to `LIA130/EQE00030`
- `LIA250` output:
  - enabled when `NON_TAXABLE_REMOVAL` rows exist
  - outputs up to 9 rows per page
  - uses movement/report date as a fallback removal date when source metadata has no explicit removal date
- `LIA130` final total:
  - `EQE00040` subtracts `LIA230` and `LIA240` deduction totals from the current supported reduced-tax amount.
- File name format:
  - `R<n>年<m>月_納税申告.xtx`
- Save behavior:
  - upload file to Supabase Storage during save
  - save metadata object to `report_files`
- Download behavior:
  - editor may show a temporary download link before save
  - after save, the canonical file is downloaded from storage metadata

### Disposal XML
- The standalone on-page `廃棄` editor section is hidden in this layout pass.
- Disposal XML generation/persistence behavior may remain available internally while disposal page design is revisited.

## 課税移出一覧表 Excel Generation
- Tax-report save generates the yearly `課税移出一覧表` workbook as part of the supporting workbook package.
- No manual `課税移出一覧表Excel` button is shown on the editor page.
- Implementation rule:
  - reuse the shared taxable-removal export source used by the `課税移出一覧表` page
- Workbook content:
  - business-year summary sheet
  - one monthly detail sheet per month in the selected business year
  - metadata rows include generation timestamp and business year
- File name format:
  - `課税移出一覧表_<year>.xlsx`
- Save behavior:
  - upload file to Supabase Storage during save
  - save metadata object to `report_files`

## Supporting Ledger Workbook Generation
- Tax-report save generates five yearly supporting workbook files:
  - `課税移出一覧表_<year>.xlsx`
  - `未納税移出帳_<year>.xlsx`
  - `輸出免税帳_<year>.xlsx`
  - `未納税移入帳_<year>.xlsx`
  - `戻入帳_<year>.xlsx`
- These files are supporting audit/report files, not e-Tax XML submission files.
- File generation uses the selected business year.
- File generation does not apply the editor's visible month or `酒類コード` filters.
- File source helpers:
  - `課税移出一覧表`: shared taxable-removal workbook helper.
  - other four ledgers: shared tax-ledger report config/helper.
- File metadata `fileType` values:
  - `taxable_removal_excel`
  - `non_taxable_removal_ledger_excel`
  - `export_exempt_ledger_excel`
  - `non_taxable_receipt_ledger_excel`
  - `return_to_factory_ledger_excel`
- Save behavior:
  - upload all generated workbook files to Supabase Storage during save
  - save metadata objects to `report_files`
  - replace prior metadata by `fileType` so stale generated workbook metadata does not remain active
  - remove obsolete/replaced generated storage objects after the new metadata is saved
- Workbook formatting follows repository Excel rules:
  - table rows are included
  - table header background is gray
  - table header font is bold

## Non-Scope
- No persistence of generated XML/XLSX binaries in `localStorage`.
- No base64 file-content persistence inside `tax_reports.report_files`.
- No delete action on the editor page.
