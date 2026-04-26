# Current Task

## Active Goal
- Design several tax ledger report pages under `税務管理 > 帳票一覧`:
  - `未納税移出帳`
  - `輸出免税帳`
  - `未納税移入帳`
  - `戻入帳`

## Active Scope
- Match the UI pattern of the existing `課税移出一覧表` page.
- Add one report page route/menu item per ledger.
- Use one reusable page implementation if practical; report differences should live in config.
- Each report page has a search section with:
  - `年度`
  - `月`
  - `酒類コード`
- Each report page reads tenant-scoped data from:
  - `inv_movements`
  - `inv_movement_lines`
  - supporting lookup/enrichment tables already used by `課税移出一覧表`
- Movement type mapping:
  - `未納税移出帳`: `NON_TAXABLE_REMOVAL`
  - `輸出免税帳`: `EXPORT_EXEMPT`
  - `未納税移入帳`: `RETURN_TO_FACTORY_NON_TAXABLE`
  - `戻入帳`: `RETURN_TO_FACTORY`
- Each page has a business-year summary grouped by:
  - `酒類コード`
  - `ABV`
- Summary totals include quantity and package count only.
- Each page exports Excel:
  - `未納税移出帳_<year>.xlsx`
  - `輸出免税帳_<year>.xlsx`
  - `未納税移入帳_<year>.xlsx`
  - `戻入帳_<year>.xlsx`
- Excel layouts should follow the provided sample workbook structure as closely as practical.
- Business-year summary uses only the selected business year, not the visible month or `酒類コード` filters.
- Excel export uses the selected business year and does not apply the visible month or `酒類コード` filters, consistent with `課税移出一覧表`.

## Active Non-Goals
- Do not calculate tax amount in the new yearly summaries.
- Do not add edit actions to these report pages.
- Do not change movement posting or tax event derivation.
- Do not add new database tables.
- Do not change existing `課税移出一覧表` behavior except for extracting shared report helpers when needed.
- Do not add PDF export in this task.

## Active Affected Files
- Spec:
  - [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- Docs to create/update:
  - `docs/UI/tax-ledger-reports.md`
- Frontend page/helper files:
  - `beeradmin_tail/src/views/Pages/TaxLedgerReport.vue`
  - `beeradmin_tail/src/lib/taxLedgerReport.ts`
  - `beeradmin_tail/src/router/tenant-routes.ts`
  - `beeradmin_tail/src/components/layout/AppSidebar.vue`
  - `beeradmin_tail/src/locales/ja.json`
  - `beeradmin_tail/src/locales/en.json`
- Reference files:
  - [TaxableRemovalReport.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue)
  - [taxableRemovalReport.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxableRemovalReport.ts)
  - sample Excel files under `/Users/zhao/Documents/FutureProject/ビール/受領資料/20250829/既存デモ/税務`

## Active Data Model / API Changes
- No schema changes.
- No stored function changes planned for v1.
- Frontend loader should query existing tables directly, consistent with `課税移出一覧表`.
- Movement matching should use normalized tax event values from movement metadata:
  - first `inv_movements.meta.tax_event`
  - then fallback `inv_movements.meta.tax_decision_code`
- Shared normalized row model should include:
  - movement id / line id
  - movement date
  - movement type
  - source/destination site
  - item / liquor code
  - brand/product name
  - ABV
  - package/container label
  - package count
  - quantity in mL
  - display quantity
  - tax rate if present
  - source/destination address fields
  - lot number
  - notes
- Quantity calculation follows the domain rule:
  - durable internal volume is mL
  - total display can show L where useful
  - ledger detail/export quantity should follow the sample workbook and existing report convention

## Active Implementation Design
1. Built a generic tax-ledger report config layer:
   - one config per report type
   - title, route, tax event, file name, detail columns, workbook sheets
2. Built a shared loader in `taxLedgerReport.ts`:
   - fetch matching `inv_movements`
   - fetch lines for matched movements
   - enrich from `mes_batches`, `entity_attr`, `mst_package`, `mst_uom`, `mst_sites`, `lot`
3. Built one reusable `TaxLedgerReport.vue`:
   - uses route meta/param to select report config
   - same visual structure as `TaxableRemovalReport.vue`
   - filters by fiscal year, month, liquor code
   - business-year summary groups by liquor code + ABV and uses fiscal year only
4. Excel export:
   - uses existing workbook helper without changing `課税移出一覧表`
   - uses two gray header rows for the `容器` / `種類・個数` structure instead of true merged cells
   - keep gray bold header cells and bordered data rows
   - workbook contents use selected fiscal year, ignoring page month/liquor filters like `課税移出一覧表`
5. Added routes/menu entries under `税務管理 > 帳票一覧`.

## Active Route / Menu Plan
- `未納税移出帳`
  - route path: `/nonTaxableRemovalLedger`
  - route name: `NonTaxableRemovalLedger`
- `輸出免税帳`
  - route path: `/exportExemptLedger`
  - route name: `ExportExemptLedger`
- `未納税移入帳`
  - route path: `/nonTaxableReceiptLedger`
  - route name: `NonTaxableReceiptLedger`
- `戻入帳`
  - route path: `/returnToFactoryLedger`
  - route name: `ReturnToFactoryLedger`

## Active Validation Plan
- Spec/design step:
  - `git diff --check`
- Implementation step:
  - direct targeted ESLint for touched Vue/TS files
  - `npm run type-check`
  - `npm run test --if-present`
  - JSON parse for locale files
  - manual route/menu verification
  - manual export workbook open check

## Active Findings
- Existing `課税移出一覧表` already has the target UI structure and filter behavior.
- Existing workbook generator supports basic `.xlsx`, gray bold headers, and borders, but does not yet support merged two-row headers used by the samples.
- Sample workbook sheets:
  - `未納税移出帳`: `製造場`, `蔵置場`
  - `未納税移入帳`: `蔵置場`, `製造場`
  - `輸出免税帳`: `輸出免税帳`
  - `戻入帳`: `戻入帳`
- Sample workbook detail columns are similar but not identical. The reusable page should support report-specific address/name columns.

## Active Final Decisions
- `戻入帳` source movement type is `RETURN_TO_FACTORY`.
- `未納税移入帳` source movement type is `RETURN_TO_FACTORY_NON_TAXABLE`.
- Business-year summaries include quantity/package only, not tax amount.
- Export workbook output must keep gray bold headers and table rows per repository Excel rule.
- New ledger pages reuse one component and differ by config.
- `未納税移出帳` and `未納税移入帳` export split sheets by source/destination site type when that metadata can be resolved; unmatched rows are kept in the first sheet so they are not dropped.

## Active Validation Results
- `git diff --check -- specs/current-task.md docs/UI/tax-ledger-reports.md` passed before implementation.
- `git diff --check -- touched files` passed after implementation.
- `npm run type-check` passed.
- Targeted `npx eslint --no-fix src/lib/taxLedgerReport.ts src/views/Pages/TaxLedgerReport.vue src/router/tenant-routes.ts src/components/layout/AppSidebar.vue` passed.
- Locale JSON parse passed for `src/locales/ja.json` and `src/locales/en.json`.
- `npm run test --if-present` passed.
- Full `npx eslint --no-fix .` still fails on existing unrelated lint debt outside this task.
