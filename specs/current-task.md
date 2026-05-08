# Current Task

## Goal
- Ensure generated tax report breakdown rows keep tax rate strictly constant per row.
- Prevent `tax_rate` in `tax_reports.volume_breakdown` from being reverse-calculated from truncated yen tax amounts.
- Preserve the tax rate that was saved on each movement line when generating reports, instead of recalculating report rows from the current tax master.
- Prevent frontend-generated tax report summary rows from reverse-calculating or averaging tax rates.
- Preserve generated `tax_amount`, beer category, and ABV snapshots through frontend report/XML/export paths.

## Scope
- Update `DB/function/74_public.tax_report_generate.sql`.
- Update `DB/function/44_public.product_move.sql` so new reportable movements snapshot the applicable category tax rate when possible.
- Update frontend tax report summary row construction.
- Update frontend tax report normalization and XML/export builders that still recalculate tax amount or mix tax rates.
- Treat `tax_rate` as part of the tax report grouping identity.
- Emit the original grouped tax rate directly in `volume_breakdown`.
- Use the saved movement-line tax rate as the authoritative rate for report generation.
- Use the alcohol tax master only as a legacy fallback when a reportable movement line has no saved tax rate or only has legacy saved `0`.
- Keep summary rows split by tax rate when detail rows in the same category/kubun use different tax rates.
- Keep tax amount calculation and yen truncation separate from tax rate display/storage.
- Include generated row `tax_amount` in `volume_breakdown` so frontend code can use the stored amount instead of recalculating from rate/volume.
- Snapshot report-relevant beer category and ABV metadata on new product movements.
- Use saved beer category and ABV metadata in report generation before falling back to current batch attributes.
- Remove frontend fallback behavior that reverse-calculates missing tax rates from stored total tax amount.

## Non-Goals
- Do not change tax master schema.
- Do not change frontend tax report rendering in this task.
- Do not change existing tax rate master data.
- Do not backfill existing `inv_movement_lines.tax_rate` values in this task.
- Do not decide whether tax amount should be truncated per line or per grouped row in this task.

## Affected Files
- Spec:
  - `specs/current-task.md`
- Implementation:
  - `DB/function/74_public.tax_report_generate.sql`
  - `DB/function/44_public.product_move.sql`
  - `beeradmin_tail/src/lib/taxReport.ts`
  - `beeradmin_tail/src/views/Pages/TaxReportEditor.vue`
  - `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia220.ts`
  - `beeradmin_tail/src/lib/taxableRemovalReport.ts`
  - `beeradmin_tail/src/lib/taxLedgerReport.ts`
  - `beeradmin_tail/src/views/Pages/TaxYearSummary.vue`
- Reference files:
  - `docs/domain/quantity-and-money.md`
  - `DB/function/66_public.get_current_tax_rate.sql`
  - `beeradmin_tail/src/lib/taxReport.ts`
  - `beeradmin_tail/src/lib/moneyFormat.ts`

## Data Model / API Changes
- No schema changes.
- Existing `tax_reports.volume_breakdown` JSON gains a `tax_amount` property per generated row.
- `tax_reports.volume_breakdown[].tax_rate` should now always be the grouped source/master tax rate, not an effective rate derived from truncated tax amount.
- `tax_reports.volume_breakdown[].tax_amount` should be read and reused by frontend tax report calculations when present.
- `tax_report_generate` reads tax rates in this priority order:
  1. `inv_movement_lines.tax_rate`
  2. `inv_movement_lines.meta.tax_rate`
  3. `inv_movements.meta.tax_rate`
  4. alcohol tax master lookup by category/date for legacy rows with no saved positive rate
- New movements should snapshot the applicable tax rate for reportable events:
  - `TAXABLE_REMOVAL`
  - `NON_TAXABLE_REMOVAL`
  - `EXPORT_EXEMPT`
  - `RETURN_TO_FACTORY`
- New movements should snapshot source beer category / tax category code and ABV when available.

## Implementation Plan
- Add `l.tax_rate` to the `grouped` CTE select list.
- Add saved tax-rate extraction to `source_lines`.
- Change `enriched_lines.tax_rate` to prefer saved positive source rates before master lookup.
- Change `product_move` to resolve and save an applicable tax rate for reportable tax events, while preserving strict errors for taxable removals and avoiding new hard failures for non-taxable/export/return events.
- Change LIA110 kubun summary grouping to include tax rate.
- Change kubun summary rows to display the shared source tax rate, not an effective rate derived from truncated tax amount.
- Change frontend normalization to preserve stored `tax_amount` and avoid reverse-calculating fallback rates.
- Change frontend total/summary amount calculations to prefer stored `tax_amount`.
- Change LIA220 return XML amount generation to prefer stored `tax_amount`.
- Change taxable-removal Excel summary rows to group by tax rate.
- Change tax ledger export rows and yearly tax summary category lookup to prefer saved movement metadata before current batch attributes.
- Change report generation to prefer saved beer category and ABV metadata before current batch attributes.
- Keep category and grand-total rows tax-rate blank because they may aggregate multiple rates.
- Include `l.tax_rate` in the group key expression, `GROUP BY`, and generated `key` string.
- Remove `weighted_tax_rate` from the grouped calculation because rows are no longer mixed across rates.
- Emit:
  - `'tax_rate', g.tax_rate`
  - `'tax_amount', g.tax_amount`
- Keep `v_total_tax_amount` based on `g.tax_amount`.
- Validate SQL shape and run available project checks.

## Validation Plan
- `git diff --check`
- SQL syntax-oriented review of the changed function section
- `npm run test --if-present`
- `npx eslint .`
- `npx eslint src/lib/taxReport.ts src/views/Pages/TaxReportEditor.vue`
- `npx eslint src/lib/taxreportxml/RLI0010_232/builders/lia220.ts src/lib/taxableRemovalReport.ts src/lib/taxLedgerReport.ts src/views/Pages/TaxYearSummary.vue`
- `npm run type-check`
- `npm run build`
- Manual DB check when available:
  - generate a report with small volume and tax rate `155000`
  - confirm generated `volume_breakdown[].tax_rate = 155000`
  - confirm generated `volume_breakdown[].tax_amount` is still truncated yen
  - confirm rows split when the same category/event/ABV has different tax rates

## Final Decisions
- `tax_report_generate` now includes the tax rate in the generated breakdown row identity.
- Rows with the same category/event/ABV but different tax rates are split into separate `volume_breakdown` rows.
- Generated `volume_breakdown[].tax_rate` now uses the saved movement-line/header tax rate when available.
- Saved tax rates of `0` are treated as missing in `tax_report_generate` so old non-taxable/export/return rows can still fall back to the master rate.
- Alcohol tax master lookup remains only as a legacy fallback for reportable movement lines without a saved positive tax rate.
- `product_move` now snapshots applicable tax rate for reportable tax events when category/rate can be resolved.
- Taxable removals still raise if category/rate resolution fails; non-taxable/export/return movements keep posting and can rely on report-generation fallback.
- LIA110 kubun summary rows are split by tax rate and now display the shared source tax rate.
- Frontend summary row tax rates are no longer derived from tax amount and volume.
- Category and grand-total summary rows continue to leave tax rate blank.
- Generated `volume_breakdown[]` now includes `tax_amount` separately from `tax_rate`.
- The old reverse calculation from truncated `tax_amount` back into `tax_rate` was removed.
- Taxable removal Excel, tax ledger export, and yearly tax summary now prefer saved line/header category and ABV metadata before live batch attributes.
- The existing per-line yen truncation behavior was left unchanged.

## Validation Results
- `git diff --check` passed.
- Static review confirmed saved tax-rate extraction, saved-positive-rate preference, master fallback gating, product-move rate/category/ABV snapshotting for reportable tax events, LIA110 summary grouping by tax rate, and absence of the old SQL `weighted_tax_rate` / `g.tax_amount * 1000` reverse-rate formula.
- Static search found no remaining `storedTotalTaxAmount * 1000`, `fallbackRate`, `effectiveTaxRate`, `weighted_tax_rate`, or `g.tax_amount * 1000` patterns in the tax-report source paths.
- `npm run test --if-present` passed with no test output.
- `npx eslint .` failed on existing project-wide frontend lint debt such as missing `<script lang>`, unused variables, `no-explicit-any`, and multi-word component-name violations.
- `npx eslint src/lib/taxReport.ts src/views/Pages/TaxReportEditor.vue src/lib/taxreportxml/RLI0010_232/builders/lia220.ts src/lib/taxableRemovalReport.ts src/lib/taxLedgerReport.ts src/views/Pages/TaxYearSummary.vue` passed.
- `npm run type-check` passed.
- `npm run build` passed with existing CSS minifier warnings for `::-webkit-scrollbar-thumb:is()`.
- Manual DB execution of `tax_report_generate` was not run in this workspace.
