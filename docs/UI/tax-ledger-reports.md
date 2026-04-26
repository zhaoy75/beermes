# Tax Ledger Report Pages UI Specification

## Purpose
- Add four read-only tax ledger pages under `税務管理 > 帳票一覧`.
- Let users review yearly and monthly movement ledger data without opening each movement.
- Export sample-like Excel workbooks for each ledger.

## Target Pages
| Page | Source tax event | Route path | Route name | Excel file |
|---|---|---|---|---|
| `未納税移出帳` | `NON_TAXABLE_REMOVAL` | `/nonTaxableRemovalLedger` | `NonTaxableRemovalLedger` | `未納税移出帳_<year>.xlsx` |
| `輸出免税帳` | `EXPORT_EXEMPT` | `/exportExemptLedger` | `ExportExemptLedger` | `輸出免税帳_<year>.xlsx` |
| `未納税移入帳` | `RETURN_TO_FACTORY_NON_TAXABLE` | `/nonTaxableReceiptLedger` | `NonTaxableReceiptLedger` | `未納税移入帳_<year>.xlsx` |
| `戻入帳` | `RETURN_TO_FACTORY` | `/returnToFactoryLedger` | `ReturnToFactoryLedger` | `戻入帳_<year>.xlsx` |

## Entry Points
- Sidebar -> `税務管理` -> `帳票一覧` -> each ledger page.
- All pages require tenant auth.

## Users and Permissions
- Tenant user can view ledger data for the current tenant.
- Tenant user can refresh and export Excel.
- No edit, cancel, or posting action is available on these pages.

## Page Layout
Use the existing `課税移出一覧表` layout pattern.

1. Header
   - page title
   - short subtitle
   - actions: `Excel Export`, `Refresh`
2. Search section
   - `年度`
   - `月`
   - `酒類コード`
3. Business-year summary
   - grouped by `酒類コード` + `ABV`
4. Detail table
   - one row per matching movement line
5. Empty state
   - shown when no matching records exist

## Search Behavior
- `年度`
  - required visible field
  - default: current business year
  - business year range: April 1 through March 31
- `月`
  - optional
  - filters the detail table only
  - does not affect business-year summary
  - does not affect Excel export
- `酒類コード`
  - optional
  - filters the detail table
  - does not affect business-year summary
  - does not affect Excel export

## Data Source
Read existing tenant-scoped data from:
- `inv_movements`
- `inv_movement_lines`
- supporting master/enrichment data already used by `課税移出一覧表`

Movement filter:
- `inv_movements.status <> 'void'`
- source event is matched by:
  - `inv_movements.meta.tax_event`
  - fallback `inv_movements.meta.tax_decision_code`

Enrichment targets:
- batch product/category/ABV attributes
- package/container label
- unit of measure
- source/destination site name/address
- lot number
- movement/line notes

## Normalized Row Model
The loader should normalize each detail row to include:
- movement id
- movement line id
- movement date
- source event
- source site
- destination site
- liquor code
- liquor label
- product/brand name
- ABV
- package/container label
- package count
- quantity in mL
- display quantity
- tax rate if present
- source/destination address fields
- lot number
- notes

## Summary Rules
- One row is one `酒類コード` + `ABV` group.
- Summary uses the selected business year.
- Summary does not apply the visible `月` or `酒類コード` filters.
- Summary totals include only:
  - package count
  - quantity
- Summary does not calculate:
  - tax amount
  - reduction amount
  - final payable tax

## Detail Table Rules
- Detail rows use the selected business year.
- Detail rows apply selected `月` and `酒類コード`.
- Sort default: newest movement date first.
- Quantity presentation follows the domain rule:
  - internal durable volume is mL
  - ledger values should match existing report and sample workbook expectations
- ABV presentation:
  - keep data as numeric ABV
  - display and Excel export values with `%`, for example `5.0%`

## Detail Columns
Use a common base column set and allow report-specific address/name columns.

Common columns:
- `年月日`
- `品目`
- `製品名`
- `ABV`
  - displayed as a percentage value with `%`
- `容器`
- `個数`
- `数量`
- `適用税率`
- `ロット番号`
- `摘要`

Report-specific columns:
- `未納税移出帳`
  - `受取人住所`
  - `移出先所在地`
- `輸出免税帳`
  - `移出者所在地`
  - `輸出先所在地`
  - `輸出先名称`
- `未納税移入帳`
  - `所在地`
- `戻入帳`
  - `引渡人所在地`
  - `引渡先所在地`

## Excel Export
- Generate workbook in the browser.
- File names:
  - `未納税移出帳_<year>.xlsx`
  - `輸出免税帳_<year>.xlsx`
  - `未納税移入帳_<year>.xlsx`
  - `戻入帳_<year>.xlsx`
- Export source:
  - selected business year
  - ignore visible `月` filter
  - ignore visible `酒類コード` filter
- Formatting rules:
  - always add rows to a table-like sheet
  - header cells are gray
  - header font is bold
  - bordered rows
- Workbook layout should follow customer samples as closely as practical:
  - `未納税移出帳`: sheets `製造場`, `蔵置場`
  - `未納税移入帳`: sheets `蔵置場`, `製造場`
  - `輸出免税帳`: sheet `輸出免税帳`
  - `戻入帳`: sheet `戻入帳`
- If sheet splitting by site type cannot be resolved reliably from existing site metadata, v1 should still export the right rows and mark the sheet-splitting decision in code comments/spec notes before implementation completion.

## Implementation Plan
1. Created a report config module in `taxLedgerReport.ts`.
2. Implemented a shared loader that returns normalized rows.
3. Implemented `TaxLedgerReport.vue` using the same visual structure as `TaxableRemovalReport.vue`.
4. Added per-report route records that pass the ledger key through route meta.
5. Added sidebar entries under `税務管理 > 帳票一覧`.
6. Added Japanese and English locale labels.
7. Reused the existing workbook helper with report-specific sheet/header rows.
8. Validated with targeted lint, type-check, test script, locale JSON parse, and diff whitespace checks.

## Implementation Notes
- The workbook helper currently does not support true merged cells, so ledger exports use two gray bold header rows for the `容器` group.
- Multi-sheet exports keep unmatched rows in the first sheet if site type metadata cannot classify them reliably.
- Summary and export remain business-year level and ignore visible `月` / `酒類コード` filters.
- ABV display/export values use the shared percent formatter.

## Non-Scope
- No database schema changes.
- No stored function changes.
- No tax amount summary.
- No inline movement edit/cancel.
- No PDF export.
