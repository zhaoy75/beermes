# Current Task

## Goal
- Add first-pass XML generation support for the currently missing optional `RLI0010_232` forms:
  - `LIA230` 移入酒類の再移出等控除(還付)税額計算書
  - `LIA240` 被災酒類に対する酒税の控除(還付)明細書
  - `LIA250` 未納税移出免税明細書

## Scope
- Extend the schema-driven tax-report XML generator to include `LIA230`, `LIA240`, and `LIA250` when source rows exist.
- Preserve the `RLI0010-232.xsd` form order:
  - `LIA010`, `LIA110`, `LIA130`, `LIA220`, `LIA230`, `LIA240`, `LIA250`, `LIA260`.
- Derive first-pass rows from existing `tax_reports.volume_breakdown` data and optional movement metadata:
  - `LIA230`: rows where `tax_event = RETURN_TO_FACTORY_NON_TAXABLE`, plus rows explicitly tagged with `tax_attachment_form = LIA230`.
  - `LIA240`: rows explicitly tagged with `tax_attachment_form = LIA240`, or disaster rows carrying a disaster compensation/tax amount.
  - `LIA250`: rows where `tax_event = NON_TAXABLE_REMOVAL`.
- Add metadata fields to `TaxVolumeItem` so XML builders can consume source dates, remarks, reduced tax amount, disaster compensation amount, and counterparty/place fields when available.
- Update `tax_report_generate` so `RETURN_TO_FACTORY_NON_TAXABLE` source rows are kept in `volume_breakdown` for optional XML forms while still excluded from `LIA110`.
- Include `LIA230` and `LIA240` deduction totals in `LIA130/EQE00020`, `LIA130/EQE00030`, and final `LIA130/EQE00040` / `LIA010/EFD00020` filing amount.
- Update implementation documentation/specs to reflect the new supported forms and remaining limitations.

## Non-Goals
- Do not build full editor tabs or official previews for `LIA230`, `LIA240`, or `LIA250` in this pass.
- Do not add a new database table for form-specific row details.
- Do not implement `TENPU` attachment XML.
- Do not solve the broader `LIA130` multi-band/category A-D calculation gaps in this task.
- Do not change unrelated tax-report UI layout.

## Affected Files
- `specs/current-task.md`
- `docs/UI/tax-report-rli0010-232-implementation-spec.md`
- `docs/UI/tax-report-editor.md`
- `DB/function/74_public.tax_report_generate.sql`
- `beeradmin_tail/src/lib/taxReport.ts`
- `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/types.ts`
- `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/schemaMap.ts`
- `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/constants.ts`
- `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/service.ts`
- `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/root.ts`
- `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia130.ts`
- `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia230.ts`
- `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia240.ts`
- `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia250.ts`
- `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/validation/structural.ts`

## Data Model / API Changes
- No SQL table schema changes.
- `tax_reports.volume_breakdown` JSON may now contain additional optional row metadata copied from movement/line `meta`.
- `public.tax_report_generate(jsonb)` behavior changes and its function version comment must be incremented.
- `RLI0010_232_Input.breakdown` gains:
  - `reimportDeductions`
  - `disasterDeductions`
  - `nonTaxableRemovals`
- `RLI0010_232_Result.formSummary` gains summaries for `LIA230`, `LIA240`, and `LIA250`.

## Planned File Changes
- Add `LIA230`, `LIA240`, and `LIA250` to the schema map and form summaries.
- Add builders that paginate according to XSD limits:
  - `LIA230`: 18 rows/page
  - `LIA240`: 18 rows/page
  - `LIA250`: 9 rows/page
- Add form IDs to the catalog/root output in XSD order.
- Extend `buildXmlPayload()` to derive the new optional-form rows and compute deduction totals.
- Extend `LIA130` output so `EQE00020`, `EQE00030`, and `EQE00040` reflect the new optional deductions.
- Preserve `RETURN_TO_FACTORY_NON_TAXABLE` rows in generated report breakdown and source refs.

## Validation Plan
- Run `git diff --check`.
- Run `npm run type-check` in `beeradmin_tail`.
- Run a local XSD validation smoke check if a sample XML can be generated without live Supabase data.
- Run lint if feasible; if existing unrelated lint failures remain, report them clearly.

## Final Decisions
- `LIA230`, `LIA240`, and `LIA250` are now XML-generation features for `RLI0010_232`; full editor tabs/previews remain out of scope.
- `LIA230` is included when `tax_event = RETURN_TO_FACTORY_NON_TAXABLE` or `tax_attachment_form = LIA230` rows exist.
- `LIA240` is included when rows are tagged `tax_attachment_form = LIA240` or carry `disaster_compensation_amount`.
- `LIA250` is included when `NON_TAXABLE_REMOVAL` rows exist.
- `tax_report_generate` now preserves `RETURN_TO_FACTORY_NON_TAXABLE` rows in `volume_breakdown` and source refs, while `LIA110` continues to exclude them.
- `LIA130/EQE00020` and `LIA130/EQE00030` now receive `LIA230` and `LIA240` deduction totals, and `LIA130/EQE00040` / `LIA010/EFD00020` use the post-deduction final filing amount.
- The stored function version comment for `public.tax_report_generate(jsonb)` was incremented from `{"version":1}` to `{"version":2}`.

## Validation Results
- `git diff --check` passed.
- `npm run type-check` passed in `beeradmin_tail`.
- Targeted ESLint on changed TypeScript/Vue files passed.
- Full `npm run lint -- --no-fix` failed on existing unrelated legacy lint errors outside this change set.
- Unit tests were not run because `beeradmin_tail/package.json` has no `test`, `unit`, or `test:unit` script.
