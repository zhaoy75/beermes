# Current Task

## Goal
- Persist the `移入出登録` page search conditions so users returning to the page see the same filters and table view.

## Scope
- Persist the main movement search section fields:
  - 製造バッチ
  - 酒類分類
  - パッケージ種別
  - ビール名
  - 開始日
  - 終了日
  - 税務移出種別
  - 税務関連移入出のみ表示
  - 取消済みの移動を表示
- Persist movement table column filters and sort state because they are also part of the visible search/view condition.
- Restore the persisted state before the first movement fetch.
- Keep the existing reset behavior, but make reset overwrite the remembered state with default values.

## Non-Goals
- Do not change movement query semantics.
- Do not change page layout.
- Do not persist fetched movement results; only persist search/view state.
- Do not add database tables or server APIs.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/views/Pages/ProducedBeer.vue`

## Data Model / API Changes
- No database schema changes.
- No API changes.
- Browser `localStorage` stores page-specific search/view state under a versioned key.

## Validation Plan
- Run `git diff --check` for changed files.
- Run `npm run type-check` in `beeradmin_tail`.
- Run focused ESLint on `src/views/Pages/ProducedBeer.vue`.

## Final Decisions
- Added a versioned `localStorage` key for the movement page search/view state.
- Restored the saved state during setup before the initial `fetchMovements()` call.
- Saved changes to the main movement filters, movement type filter, table column filters, and table sort state.
- Kept fetched movement rows out of storage; the page still reloads data from Supabase.
- Kept reset scoped to the existing movement search filters and movement type filter, then persisted those defaults.

## Validation Results
- `git diff --check -- specs/current-task.md beeradmin_tail/src/views/Pages/ProducedBeer.vue` passed.
- `npm run type-check` passed in `beeradmin_tail`.
- `npx eslint src/views/Pages/ProducedBeer.vue --no-fix` passed.
- Full `npx eslint . --no-fix` failed on pre-existing unrelated lint issues outside this change, including missing Vue `lang` attributes, unused variables, component naming, and `any` usage.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a unit test script.

## Previous Goal - Tax Calculation Consistency
- Fix the 1 yen mismatch between `LIA110 税額算出表` tax amount and `LIA130 軽減税額算出表` standard tax amount.
- Make `LIA130` use the same generated standard tax amount shown in `LIA110`.

## Scope
- Align frontend tax report preview/XML generation so `LIA130` current-month standard tax is derived from the generated `LIA110` grand-total row.
- Align stored report generation so grouped tax amount is calculated from the grouped quantity and tax rate, not by summing line-level truncated tax amounts.
- Align `tax_reports.total_tax_amount` and the editor's standard/net tax total with:
  - `LIA110` current-month standard tax
  - minus `LIA220` return standard tax
- Keep yen truncation behavior as floor/toward-zero per `docs/domain/quantity-and-money.md`.
- Keep final reduced-tax and payable-tax formulas unchanged.

## Non-Goals
- Do not change tax rates, tax category resolution, or movement selection.
- Do not change UI layout.
- Do not mutate submitted/approved historical reports.
- Do not change `LIA220`, `LIA230`, or `LIA240` rules except where they consume the already generated report breakdown.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/lib/taxReport.ts`
- `DB/function/74_public.tax_report_generate.sql`
- `DB/function/77_public._tax_batch_correction_preview_payload.sql`

## Data Model / API Changes
- No schema changes.
- No function signature changes.
- `tax_report_generate(jsonb)` behavior changes; increment the stored function version comment.
- `_tax_batch_correction_preview_payload(uuid, uuid, uuid, text, numeric, numeric)` behavior changes; increment the stored function version comment.

## Calculation Design
- `LIA110` generated grand-total row remains the authoritative current-month standard tax amount for `LIA130`.
- `LIA130` preview/XML should not independently recalculate current-month standard tax from source detail rows.
- `tax_reports.total_tax_amount` is the canonical standard/net tax amount before LIA130 reduction.
- `tax_reports.total_tax_amount` should equal `LIA110 current-month standard tax - LIA220 return standard tax`.
- `LIA010` final filing tax amount can differ from `tax_reports.total_tax_amount` when LIA130 reduction or deductions apply; that difference is expected.
- `tax_report_generate` should calculate each grouped `tax_amount` as:
  - `floor(group_volume_ml / 1,000,000 * tax_rate) * tax_direction`
- This prevents package/movement-level truncation from causing a 1 yen difference against the official grouped quantity calculation.
- Frontend-generated LIA110 and LIA220 subtotal rows must follow the same rule:
  - sum the group quantity first
  - multiply the summed quantity by the tax rate
  - discard fractional yen once per generated subtotal group
- Tax batch correction preview totals must also compare grouped previous/corrected amounts, not line-level truncated movement amounts.

## Validation Plan
- Run `git diff --check` for changed files.
- Review SQL for the changed grouping calculation and function version.
- Run `npm run type-check` in `beeradmin_tail`.
- Run focused ESLint on `src/lib/taxReport.ts`.

## Final Decisions
- Added a frontend helper that reads the generated `LIA110` grand-total row and uses that amount as the `LIA130` current-month standard tax amount.
- Updated XML generation and UI preview paths to share that same source amount.
- Added `calculateStandardNetTaxAmount` so report normalization and editor recalculation use the same canonical standard/net total.
- Updated `tax_report_generate` so grouped `tax_amount` is calculated from grouped `volume_ml` and `tax_rate`, then truncated once at the grouped row level.
- Updated `tax_report_generate` so persisted `total_tax_amount` is calculated as LIA110-style taxable standard tax minus LIA220-style return standard tax.
- Updated LIA110 detail row volume handling to prefer integer milliliter-backed conversion before deriving liters.
- Updated frontend LIA110 and LIA220 generated subtotal calculations so they calculate tax from summed group quantity instead of adding detail-row tax calculations.
- Updated tax batch correction preview totals so previous/corrected tax amounts are calculated from grouped affected quantity and rate.
- Incremented `tax_report_generate(jsonb)` function version from `6` to `8`.
- Incremented `_tax_batch_correction_preview_payload(...)` function version from `1` to `2`.

## Validation Results
- `git diff --check -- specs/current-task.md beeradmin_tail/src/lib/taxReport.ts beeradmin_tail/src/views/Pages/TaxReportEditor.vue DB/function/74_public.tax_report_generate.sql` passed.
- `git diff --check -- specs/current-task.md beeradmin_tail/src/lib/taxReport.ts DB/function/77_public._tax_batch_correction_preview_payload.sql` passed.
- SQL static review confirmed the grouped tax formula and function version comment were updated.
- `npm run type-check` passed in `beeradmin_tail`.
- `npx eslint src/lib/taxReport.ts src/views/Pages/TaxReportEditor.vue --no-fix` passed.
- `npx eslint src/lib/taxReport.ts --no-fix` passed.
- Full `npx eslint . --no-fix` failed on pre-existing unrelated lint issues outside this change, including missing Vue `lang` attributes, unused variables, component naming, and `any` usage.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a unit test script.
