# Current Task

## Goal
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

## Data Model / API Changes
- No schema changes.
- No function signature changes.
- `tax_report_generate(jsonb)` behavior changes; increment the stored function version comment.

## Calculation Design
- `LIA110` generated grand-total row remains the authoritative current-month standard tax amount for `LIA130`.
- `LIA130` preview/XML should not independently recalculate current-month standard tax from source detail rows.
- `tax_reports.total_tax_amount` is the canonical standard/net tax amount before LIA130 reduction.
- `tax_reports.total_tax_amount` should equal `LIA110 current-month standard tax - LIA220 return standard tax`.
- `LIA010` final filing tax amount can differ from `tax_reports.total_tax_amount` when LIA130 reduction or deductions apply; that difference is expected.
- `tax_report_generate` should calculate each grouped `tax_amount` as:
  - `floor(group_volume_ml / 1,000,000 * tax_rate) * tax_direction`
- This prevents package/movement-level truncation from causing a 1 yen difference against the official grouped quantity calculation.

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
- Incremented `tax_report_generate(jsonb)` function version from `6` to `8`.

## Validation Results
- `git diff --check -- specs/current-task.md beeradmin_tail/src/lib/taxReport.ts beeradmin_tail/src/views/Pages/TaxReportEditor.vue DB/function/74_public.tax_report_generate.sql` passed.
- SQL static review confirmed the grouped tax formula and function version comment were updated.
- `npm run type-check` passed in `beeradmin_tail`.
- `npx eslint src/lib/taxReport.ts src/views/Pages/TaxReportEditor.vue --no-fix` passed.
- Full `npx eslint . --no-fix` failed on pre-existing unrelated lint issues outside this change, including missing Vue `lang` attributes, unused variables, component naming, and `any` usage.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a unit test script.
