# Current Task

## Goal
- Analyze and specify validation to prevent a movement/transaction date from being earlier than the source lot's business creation date.
- Protect user-editable movement dates in UI flows from producing impossible lot chronology.

## Scope
- Identify the canonical source-lot creation timestamp for validation.
- Identify backend entry points that create or update movements using source lots.
- Identify UI pages where users can edit movement or transaction dates.
- Recommend the safest implementation layer and edge-case behavior.
- Add frontend early-warning checks on pages that expose user-editable movement/event timestamps.
- Keep backend validation as the final authority.

## Findings
- `inv_movements.movement_at` is user-controlled in several flows and is the business effective timestamp used by tax/reporting and lot trace.
- `lot.created_at` is not a sufficient business creation date because it is database insert time; backdated production can create a lot today with an earlier `movement_at`.
- `lot.produced_at` is not sufficient for moved/split/fill lots because it can preserve the original product production date instead of the specific lot record's creation/movement date.
- The best business creation timestamp for product lots is the first `inv_movements.movement_at` joined through `lot_edge.to_lot_id = lot.id`; fallback should be `lot.produced_at`, then `lot.created_at` for legacy/raw-material lots without edges.
- Product beer flows with source lots include:
  - `public.product_move(p_doc)`
  - `public.product_move_fast_post(p_docs)` through `product_move`
  - `public.product_filling(p_doc)`
  - `public.product_unpacking(p_doc)`
  - `public.domestic_removal_complete(...)` through `product_move`
- Additional lot-consuming paths exist outside `lot_edge`:
  - raw material inventory create/edit/move writes `inv_movements` and stores lot id in line `meta.lot_id`
  - batch-step backflush consumes material lots and stores lot id in line `meta.lot_id`
- `public.movement_save(p_movement_id, p_doc)` can update `inv_movements.movement_at` after posting. This can invalidate chronology unless it validates both source lots used by that movement and downstream movements that already use lots created by that movement.

## Recommended Implementation Plan
1. Add a DB helper to resolve lot business creation time:
   - input: `p_lot_id uuid`
   - primary source: earliest `m.movement_at` from `lot_edge e join inv_movements m on m.id = e.movement_id where e.to_lot_id = p_lot_id and m.status <> 'void'`
   - fallback: `lot.produced_at`
   - fallback: `lot.created_at`
2. Add a DB assertion helper for source-lot chronology:
   - input: `p_movement_at timestamptz`, `p_source_lot_ids uuid[]`, optional context
   - reject if any source lot creation time is after `p_movement_at`
   - error should include lot number and both dates for clear UI feedback
3. Call the assertion inside all posting functions before stock/lot mutation:
   - `product_move`: `v_src_lot_id`
   - `product_filling`: `v_from_lot_id`
   - `product_unpacking`: `v_src_lot_id`
   - `batch_step_complete_backflush`: explicit and FIFO-selected material lot ids before consumption
   - raw-material movement creation path should move to an RPC or add equivalent validation before direct insert/update
4. Add trigger protection for posted data:
   - `lot_edge` before insert/update: if `from_lot_id` exists, movement date must be on/after source lot creation time
   - `inv_movements` before update of `movement_at`: validate source lots already used by this movement
   - for movements that created lots, also validate that the new movement date is not later than any downstream non-void movement that uses those created lots as a source
5. Add UI pre-checks only as convenience:
   - ProductMoveFast and produced beer movement edit should compare selected movement date with selected/candidate source lot creation date when known
   - Batch packing/filling dialogs should compare event time with resolved source lot creation date when known
   - UI must still rely on backend errors as the final authority

## Non-Goals
- Do not use UI-only validation as the final safeguard.
- Do not rewrite historical inventory quantities in this pass.
- Do not allow `movement_save` to silently change lot graph chronology.
- Do not use `lot.created_at` alone as the validation source.

## Affected Files For Implementation
- [DB/function/03_public.lot_chronology.sql](/Users/zhao/dev/other/beer/DB/function/03_public.lot_chronology.sql)
- [DB/function/44_public.product_move.sql](/Users/zhao/dev/other/beer/DB/function/44_public.product_move.sql)
- [DB/function/43_public.product_filling.sql](/Users/zhao/dev/other/beer/DB/function/43_public.product_filling.sql)
- [DB/function/71_public.product_unpacking.sql](/Users/zhao/dev/other/beer/DB/function/71_public.product_unpacking.sql)
- [DB/function/72_public.batch_step_complete_backflush.sql](/Users/zhao/dev/other/beer/DB/function/72_public.batch_step_complete_backflush.sql)
- `DB/function/31_public.movement_save.sql` is protected indirectly by the new `inv_movements` update trigger.
- raw material inventory movement path, currently [RawMaterialInventoryEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RawMaterialInventoryEdit.vue)
- UI early-warning paths:
  - [ProductMoveFast.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/ProductMoveFast.vue)
  - [ProducedBeerMovementEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue)
  - [BatchPacking.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchPacking.vue)
  - [BatchStepExecution.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchStepExecution.vue)
- Shared frontend helper:
  - [lotChronology.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/lotChronology.ts)

## Validation Plan
- Add SQL tests or manual SQL cases:
  - movement at same timestamp as source creation: allowed
  - movement before source creation: rejected
  - editing a posted movement earlier than source creation: rejected
  - editing a lot-creating movement later than a downstream use of that lot: rejected
  - void downstream movement should not block chronology update
- Run frontend type-check/lint only if UI early warnings are implemented.
- For frontend warning pass:
  - run targeted ESLint for touched Vue/TS files
  - run frontend type-check
  - run unit tests if present
  - run `npm run build:test`

## Final Decisions
- Added `public.lot_effective_created_at(p_lot_id uuid)` to resolve a lot's business creation timestamp from the first non-void `lot_edge.to_lot_id` movement, then `lot.produced_at`, then `lot.created_at`.
- Added `public._assert_source_lot_not_after_movement(...)` to reject source lots created after the requested movement timestamp.
- Added a `lot_edge` trigger to protect all edge-based source-lot movement paths.
- Added an `inv_movement_lines` trigger to protect legacy/direct movement-line paths that store source lot ids in line `meta`.
- Added an `inv_movements` update trigger to protect changing `movement_at` after posting:
  - validates existing source lots for that movement
  - rejects moving a lot-creating movement later than downstream movements that already use the created lot
- Added explicit pre-mutation assertions in `product_move`, `product_filling`, and `product_unpacking`.
- Updated `batch_step_complete_backflush`:
  - explicit lot consumption rejects if the step completion time is before the lot creation time
  - FIFO candidate selection ignores lots not yet created at the step completion time
- Added a shared frontend helper `lotChronology.ts` that calls `lot_effective_created_at` and formats early-warning messages.
- Added frontend early-warning checks before posting user-editable movement/event dates:
  - `ProductMoveFast.vue` checks allocated source lots before bulk posting.
  - `ProducedBeerMovementEdit.vue` exposes `movement_at`, sends it to `product_move`, and checks selected source lots before save.
  - `BatchPacking.vue` checks the resolved source lot for filling, transfer, and ship packing events.
  - `BatchStepExecution.vue` checks selected actual-material lots before direct actual-material save and before backflush completion.
- Frontend early-warning RPC failures are logged and do not block posting; the database validation remains the final authority after the DB helper/trigger deployment.
- `ProductMoveFast.vue` preserves `LOT_TIME...` backend validation messages instead of replacing them with the generic RPC unavailable message.
- The `inv_movements` chronology update trigger now also fires on `src_site_id` changes, because line-based lot validation depends on source-site semantics.
- Voiding a lot-creating movement no longer skips downstream chronology validation; source-lot validation is skipped for voided movement rows, but downstream created-lot protection still runs.

## Validation Results
- `git diff --check -- specs/current-task.md DB/function/03_public.lot_chronology.sql DB/function/43_public.product_filling.sql DB/function/44_public.product_move.sql DB/function/71_public.product_unpacking.sql DB/function/72_public.batch_step_complete_backflush.sql`: passed.
- `git diff --check -- specs/current-task.md beeradmin_tail/src/lib/lotChronology.ts beeradmin_tail/src/views/Pages/ProductMoveFast.vue beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue beeradmin_tail/src/views/Pages/BatchPacking.vue`: passed.
- `git diff --check -- specs/current-task.md DB/function/03_public.lot_chronology.sql beeradmin_tail/src/lib/lotChronology.ts beeradmin_tail/src/views/Pages/ProductMoveFast.vue beeradmin_tail/src/views/Pages/BatchStepExecution.vue beeradmin_tail/src/views/Pages/BatchPacking.vue beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue`: passed after review fixes.
- `npx eslint src/lib/lotChronology.ts --no-fix`: passed.
- `npx eslint src/views/Pages/BatchStepExecution.vue --no-fix`: passed.
- `npx eslint src/lib/lotChronology.ts src/views/Pages/ProductMoveFast.vue src/views/Pages/ProducedBeerMovementEdit.vue src/views/Pages/BatchPacking.vue --no-fix`: failed because the touched Vue files already contain existing lint debt, mostly `@typescript-eslint/no-explicit-any` and unused-function errors. The new shared helper passes ESLint.
- `npx eslint src/lib/lotChronology.ts src/views/Pages/ProductMoveFast.vue src/views/Pages/ProducedBeerMovementEdit.vue src/views/Pages/BatchPacking.vue src/views/Pages/BatchStepExecution.vue --no-fix`: failed because `ProductMoveFast.vue`, `ProducedBeerMovementEdit.vue`, and `BatchPacking.vue` still contain existing lint debt; `lotChronology.ts` and `BatchStepExecution.vue` pass individually.
- `npm run type-check` in `beeradmin_tail`: passed.
- `npm run test --if-present` in `beeradmin_tail`: passed with no test script configured.
- `npm run build:test` in `beeradmin_tail`: passed with existing CSS minifier warnings and existing large-chunk warnings.
- SQL runtime validation was not executed in this workspace because `psql` is not installed; the new DB helper/trigger file should be applied and tested against Supabase/Postgres before release.

---

# Previous Task: LIA260 XML Output

## Goal
- Add `LIA260` XML output to the generated `RLI0010_232` `.xtx` file.
- Use existing `EXPORT_EXEMPT` report rows as the first source for `LIA260` detail rows.
- Keep `LIA260` in `CATALOG` and `CONTENTS` only when export-exempt rows exist.

## Scope
- Update the RLI0010_232 XML builder so `LIA260` pages are emitted after `LIA220`.
- Add a `LIA260` builder using `LIA260-003.xsd` and the local sample `.xtx` as references.
- Populate supported `LIA260` fields from existing tax breakdown/profile data:
  - `EOD00010/kubun_CD`
  - `EOD00020` liquor code
  - `EOD00030` item/category name
  - `EOD00040` ABV
  - `EOD00080` quantity in mL
  - `EOD00090` export/sale date, using the report period date as a fallback
  - `EOD00100` destination when source data exists; omit the optional field instead of writing placeholder filing data
  - `EOD00110` export customs office when source data exists; omit the optional field instead of writing placeholder filing data
  - `EOD00120` exporter/carrier address, using profile data when available
  - `EOD00130` exporter/carrier name, using taxpayer/tenant name when available
- Keep existing `LIA110` export-exempt summary behavior.
- Keep database schema and RPC/API fields unchanged in this pass.

## Non-Goals
- Do not add new export-detail data-entry fields in this pass.
- Do not change movement posting behavior.
- Do not implement `LIA230`, `LIA240`, or `LIA250`.
- Do not change official e-Tax schema validation behavior.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [docs/UI/tax-report-editor.md](/Users/zhao/dev/other/beer/docs/UI/tax-report-editor.md)
- [beeradmin_tail/src/lib/taxReport.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxReport.ts)
- [beeradmin_tail/src/lib/taxreportxml/RLI0010_232/types.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxreportxml/RLI0010_232/types.ts)
- [beeradmin_tail/src/lib/taxreportxml/RLI0010_232/schemaMap.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxreportxml/RLI0010_232/schemaMap.ts)
- [beeradmin_tail/src/lib/taxreportxml/RLI0010_232/constants.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxreportxml/RLI0010_232/constants.ts)
- [beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/root.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/root.ts)
- [beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia260.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia260.ts)

## Data Model / API Changes
- No schema/API changes.
- `LIA260` detail rows are derived from existing `TaxVolumeItem` `EXPORT_EXEMPT` rows.
- Export destination/customs-office fields should be replaced by real persisted source data in a later pass.

## Validation Plan
- Run targeted ESLint for touched TS/Markdown files.
- Run frontend type-check.
- Run unit tests if present.
- Run `npm run build:test`.
- Run `git diff --check` for touched files.
- Inspect generated XML structure for `LIA260` inclusion when export-exempt rows exist.

## Final Decisions
- Added `breakdown.exportExempt` to the `RLI0010_232` XML input and `formSummary.LIA260` to the generated result.
- Added a `LIA260` builder for `LIA260-003.xsd`.
- `LIA260` pages are emitted after `LIA220` in both `CATALOG` and `CONTENTS`.
- `LIA260` is emitted only when existing `EXPORT_EXEMPT` rows exist.
- `LIA260` rows use existing category, ABV, and quantity data; quantity is written in mL.
- `EOD00090` falls back to the first day of the report period until movement-level export dates are persisted.
- `EOD00120` and `EOD00130` use taxpayer/profile data when row-level exporter data is unavailable.
- Although the initial scope considered placeholders for destination/customs office, the implementation omits those optional fields when source data is unavailable. This keeps the generated `.xtx` schema-compatible without inventing filing data.

## Validation Results
- `npx eslint src/lib/taxReport.ts src/lib/taxreportxml/RLI0010_232/types.ts src/lib/taxreportxml/RLI0010_232/constants.ts src/lib/taxreportxml/RLI0010_232/schemaMap.ts src/lib/taxreportxml/RLI0010_232/builders/root.ts src/lib/taxreportxml/RLI0010_232/builders/lia260.ts src/lib/taxreportxml/RLI0010_232/service.ts src/lib/taxreportxml/RLI0010_232/validation/structural.ts --no-fix`: passed.
- `npm run type-check` in `beeradmin_tail`: passed.
- `npm run test --if-present` in `beeradmin_tail`: passed with no test script configured.
- `npm run build:test` in `beeradmin_tail`: passed with existing CSS minifier warnings and existing large-chunk warnings.
- `git diff --check -- specs/current-task.md docs/UI/tax-report-editor.md beeradmin_tail/src/lib/taxReport.ts beeradmin_tail/src/lib/taxreportxml/RLI0010_232/types.ts beeradmin_tail/src/lib/taxreportxml/RLI0010_232/constants.ts beeradmin_tail/src/lib/taxreportxml/RLI0010_232/schemaMap.ts beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/root.ts beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia260.ts beeradmin_tail/src/lib/taxreportxml/RLI0010_232/service.ts beeradmin_tail/src/lib/taxreportxml/RLI0010_232/validation/structural.ts`: passed.
- Generated XML sanity check with one `EXPORT_EXEMPT` row: passed; output included `<LIA260 VR="3.0" id="LIA260-1" ...>` and `EOD00080` quantity `1000`.

---

## Previous Goal
- Normalize beer volume and money calculation/presentation across the directly used beer, inventory, and tax/report pages.
- Use milliliters as the canonical calculation/output boundary for beer volume.
- Present unit/package beer volume in mL and total/aggregate beer volume in L.
- Preserve official form/schema units for tax form previews and XML output.
- Treat money/tax amounts as integer yen and discard fractions smaller than 1 yen.

## Previous Scope
- Add the durable volume/money rule to `AGENTS.md`.
- Add shared frontend helpers for:
  - converting liters/UOM quantities to integer milliliters
  - displaying unit/package volume as mL
  - displaying total/aggregate volume as L
  - converting raw tax/money values to integer yen without fractional rounding up
- Update the tax report calculation and XML generation paths so generated yen values use integer-yen flooring/truncation.
- Update report/list pages that directly show tax amounts or beer volume:
  - `申告書一覧`
  - `申告書編集`
  - `課税移出明細`
  - `年度酒税サマリー`
- Update the safe beer inventory/movement list displays:
  - `ビール在庫管理`
  - inventory search modal
  - `移入出登録` summary volume labels
- Preserve existing database/RPC compatibility fields such as `volume_l` and `qty_l` in this pass.

## Previous Non-Goals
- Do not change database schema in this pass.
- Do not rename RPC/API fields such as `qty_l`.
- Do not migrate stored `volume_breakdown` JSON.
- Do not change raw-material quantity pages or generic UOM pages unless they are specifically beer volume reports.
- Do not change the existing tax-report editor redesign behavior except for volume/money normalization.

## Previous Affected Files
- [AGENTS.md](/Users/zhao/dev/other/beer/AGENTS.md)
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [docs/domain/quantity-and-money.md](/Users/zhao/dev/other/beer/docs/domain/quantity-and-money.md)
- [beeradmin_tail/src/lib/volumeFormat.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/volumeFormat.ts)
- [beeradmin_tail/src/lib/moneyFormat.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/moneyFormat.ts)
- [beeradmin_tail/src/lib/taxReport.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxReport.ts)
- [beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia010.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia010.ts)
- [beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia110.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia110.ts)
- [beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia130.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia130.ts)
- [beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia220.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia220.ts)
- [beeradmin_tail/src/lib/taxableRemovalReport.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/lib/taxableRemovalReport.ts)
- [beeradmin_tail/src/views/Pages/TaxReport.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/TaxReport.vue)
- [beeradmin_tail/src/views/Pages/TaxReportEditor.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/TaxReportEditor.vue)
- [beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue)
- [beeradmin_tail/src/views/Pages/TaxYearSummary.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/TaxYearSummary.vue)
- [beeradmin_tail/src/composables/useProducedBeerInventory.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/composables/useProducedBeerInventory.ts)
- [beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/ProducedBeerInventory.vue)
- [beeradmin_tail/src/components/inventory/InventorySearchModal.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/components/inventory/InventorySearchModal.vue)
- [beeradmin_tail/src/views/Pages/ProducedBeer.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/ProducedBeer.vue)

## Previous Data Model / API Changes
- No schema or API changes in this pass.
- Stored `volume_l` remains supported and is converted to integer mL for calculations/presentation.
- Future migration can add stored `volume_ml`, but this is intentionally not required for the first pass.

## Previous Validation Plan
- Run targeted ESLint for touched Vue/TS files.
- Run frontend type-check.
- Run unit tests if present.
- Run `npm run build:test`.
- Run `git diff --check` for touched files.

## Previous Final Decisions
- Added durable project guidance to `AGENTS.md` for beer volume and yen handling.
- Moved durable quantity/money domain rules from `AGENTS.md` into `docs/domain/quantity-and-money.md`.
- `AGENTS.md` now keeps only a short pointer to the domain-rule document.
- Added shared volume helpers in `volumeFormat.ts`:
  - liters/UOM quantities can be converted through integer milliliters
  - unit/package beer volume can be displayed in mL
  - total/aggregate beer volume can be displayed in L
- Added shared money helpers in `moneyFormat.ts`:
  - yen values are truncated toward zero
  - non-negative tax output floors fractions smaller than 1 yen
  - tax can be calculated from mL or L using yen-per-kL rates
- Updated tax report calculation and XML generation so tax/money output uses integer-yen helpers instead of `Math.round`.
- Kept stored `volume_l` and RPC/API field names unchanged for compatibility.
- Added optional `volume_ml` support to normalized tax report breakdown rows when present or newly generated.
- Updated `申告書一覧`, `申告書編集`, `課税移出明細`, and `年度酒税サマリー` to use shared yen/volume helpers.
- Updated `ビール在庫管理`, inventory search modal, and `移入出登録` list/summary volume display through the shared total-volume L path.
- Updated `課税移出明細` display/export labels from mL to L because those rows present removal totals, not unit/package volume.
- Kept official tax form previews using mL where the e-Tax form layout/schema expects mL.
- Removed existing lint debt in the touched inventory composable while preserving behavior.

## Previous Validation Results
- `npx eslint src/lib/volumeFormat.ts src/lib/moneyFormat.ts src/lib/taxReport.ts src/lib/taxreportxml/RLI0010_232/builders/lia010.ts src/lib/taxreportxml/RLI0010_232/builders/lia110.ts src/lib/taxreportxml/RLI0010_232/builders/lia130.ts src/lib/taxreportxml/RLI0010_232/builders/lia220.ts src/lib/taxableRemovalReport.ts src/views/Pages/TaxReport.vue src/views/Pages/TaxReportEditor.vue src/views/Pages/TaxableRemovalReport.vue src/views/Pages/TaxYearSummary.vue src/composables/useProducedBeerInventory.ts src/views/Pages/ProducedBeer.vue src/views/Pages/ProducedBeerInventory.vue src/components/inventory/InventorySearchModal.vue --no-fix`: passed.
- `npm run type-check`: passed.
- `npm run test --if-present`: passed with no test script configured.
- `npm run build:test`: passed with existing CSS `:is()` minifier warnings and existing large-chunk warnings.
- `node -e "JSON.parse(...)"` for `src/locales/en.json` and `src/locales/ja.json`: passed.
- `git diff --check -- AGENTS.md specs/current-task.md beeradmin_tail/src/lib/volumeFormat.ts beeradmin_tail/src/lib/moneyFormat.ts beeradmin_tail/src/lib/taxReport.ts beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia010.ts beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia110.ts beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia130.ts beeradmin_tail/src/lib/taxreportxml/RLI0010_232/builders/lia220.ts beeradmin_tail/src/lib/taxableRemovalReport.ts beeradmin_tail/src/views/Pages/TaxReport.vue beeradmin_tail/src/views/Pages/TaxReportEditor.vue beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue beeradmin_tail/src/views/Pages/TaxYearSummary.vue beeradmin_tail/src/composables/useProducedBeerInventory.ts beeradmin_tail/src/views/Pages/ProducedBeer.vue beeradmin_tail/src/components/inventory/InventorySearchModal.vue`: passed.
- Documentation move:
  - `git diff --check -- AGENTS.md specs/current-task.md docs/domain/quantity-and-money.md`: passed.

---

## Previous Goal
- Redesign the `申告書編集` page as a tabbed form-document editor for the e-Tax `RLI0010_232` monthly liquor tax report.
- Add an explicit mode switch between editable form panels and e-Tax/PDF-like document previews.
- Correct the top summary terminology so tax before reduction is not shown as the final liquor tax amount.

## Previous Scope
- Update the page specification before implementation.
- Use sample PDFs directly under `docs/taxpdf` as visual references for the form panels.
- Use the guide found at `docs/taxpdf/docfromcustomer/20260416データ/承認酒類製造者に対する酒税の税率の特例措置を適用する場合の酒税納税申告書の作成の手引.pdf` as the rule/layout reference for the reduced-tax flow.
- Keep the page title behavior:
  - `申告書作成` for new rows
  - `申告書編集` for existing rows
- Replace ambiguous `酒税額合計` top-summary wording with clear fields:
  - `本則税額合計` or `軽減前酒税額`
  - `軽減税額`
  - `納付税額`
  - `還付税額`
  - `最終納付税額`
- Add a mode switch:
  - `編集`
  - `帳票プレビュー`
- Place the mode switch on the right side of the tab/mode toolbar.
- Add form tabs for:
  - `LIA010` 酒税納税申告書
  - `LIA110` 税額算出表
  - `LIA130` 軽減税額算出表
  - `LIA220` 戻入れ酒類の控除(還付)税額計算書
  - `LIA260` 輸出免税酒類輸出明細書兼輸出酒類販売場における購入明細書
- Show short user-facing tab captions and browser title/tooltip text, each 14 characters or less, and do not show XML form codes such as `LIA010` in the tab itself.
- Keep full official form names available for accessibility labels or documentation, not as visible tab captions or browser tooltips.
- Improve the form-tab visual design with rounded, compact segmented tabs.
- Do not keep extra vertical whitespace between the tab/mode toolbar and the active form panel.
- Keep edit-mode panels compact; long field-list panels should have a lower visible height and scroll internally instead of stretching the page.
- In edit mode, keep the UI simple and table-oriented; show only the fields users can change plus enough read-only context to identify each row.
- Editable fields in edit mode should include field contents that are persisted in the current draft, especially quantity and alcohol percentage where available.
- `LIA010` edit mode should list every field currently emitted by the `LIA010` XML builder, including profile-derived fields, declaration class, tax totals, tax-accountant fields, refund account, and creator name.
- LIA010 tax amount fields belong inside the `LIA010` panel, not in the page title/header summary area.
- `LIA130` edit mode should list every field currently emitted by the `LIA130` XML builder, including the repeated XML elements that share the same source calculation value.
- In preview mode, prioritize visual fidelity to the sample PDFs over edit ergonomics:
  - A4-like page proportions
  - official title and metadata placement
  - black ruled table layout
  - compact official-form typography
  - column order and labels matching the sample PDFs as closely as possible within the current data model
- Preview mode remains read-only and uses the current draft state.
- Preview mode should support document navigation:
  - zoom out / zoom in
  - reset to 100%
  - fit to viewport width
  - scrollbars for overflow
  - drag-to-pan ("slide") inside the preview canvas
- `LIA130` preview requires a closer match to the sample PDF than the first implementation:
  - landscape page header with date at left, title centered, organizer/factory box at right
  - main calculation grid with diagonal header cell
  - row numbers ① through ⑭ laid out like the sample
  - gray/diagonal non-entry cells
  - lower `軽減割合の区分` box and final-total rows
- Keep existing XML generation behavior unless explicitly changed in a later implementation step.

## Previous Non-Goals
- Do not implement `LIA260` XML output until its source data fields are confirmed.
- Do not change tax calculation rules in this redesign step.
- Do not change movement posting, ruleengine behavior, or tax event semantics.
- Do not replace existing XML/XSD validation flow.
- Do not introduce generic XSD-to-Vue rendering.
- Do not change storage behavior for generated XML/XLSX files.

## Previous Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [docs/UI/tax-report-editor.md](/Users/zhao/dev/other/beer/docs/UI/tax-report-editor.md)
- [beeradmin_tail/src/views/Pages/TaxReportEditor.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/TaxReportEditor.vue)
- [beeradmin_tail/src/locales/ja.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/ja.json)
- [beeradmin_tail/src/locales/en.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/en.json)

## Previous Data Model / API Changes
- No database schema changes in the redesign spec.
- No API changes for the initial tab/mode shell.
- `LIA260` requires additional source fields before XML output can be implemented:
  - export/sale date
  - destination
  - export customs office
  - exporter or carrier address
  - exporter or carrier name
  - optional reference notes
- Until those fields are mapped to stored data, `LIA260` can be specified and previewed as a draft/manual panel, but XML emission should remain disabled or omitted.

## Previous UI Design Decisions
- `TaxReportEditor.vue` should become the page shell:
  - route/load/save/generate orchestration
  - summary metrics
  - mode switch
  - form tab switch
  - file actions
- Form-specific editor and preview code should be split into child components when implementation starts.
- The selected tab should remain stable when switching between `編集` and `帳票プレビュー`.
- Preview components should share one paper-like visual frame and support multi-page forms.
- The preview frame should look like a document page rather than an app table:
  - gray surrounding canvas
  - white A4-like page
  - black official-form borders
  - tighter form typography
  - small boxed metadata areas
- Preview layouts should be hand-tuned per form from the local sample PDFs instead of reusing the simple edit tables.
- Edit layouts should stay intentionally simpler than preview layouts and should not copy the PDF structure when that makes editing harder.
- `LIA110`, `LIA220`, and `LIA260` can have multiple pages; previews should support page navigation or a stacked-page layout.
- `LIA110` and related attachment `区分` values should be treated as e-Tax tax-rate application codes, not movement tax-event codes:
  - `0` = 本則税率適用
  - `1` = 措置法適用
  - `2` = 沖縄特例適用
  - `3` = 措置法/経過措置 and 沖縄特例 both apply
  - `7` = 税率適用区分別計 for return/deduction attachment forms
  - `8` = 品目区分別計
  - `9` = 総合計
- `tax_event` should drive which quantity/tax column is populated, not replace the e-Tax `区分` semantics.
- `EXPORT_EXEMPT` contributes to `LIA110` `輸出免税数量` and to detailed `LIA260` rows.

## Previous Validation Plan
- Documentation step:
  - run `git diff --check` for changed spec files
- Implementation step:
  - run targeted ESLint for touched Vue/TS files
  - run frontend type-check
  - run unit tests if present
  - run `npm run build:test`
  - verify the editor opens in both new and existing report routes
  - verify `編集` and `帳票プレビュー` preserve selected tab and current draft data

## Previous Final Decisions
- Spec-first step completed.
- `TaxReportEditor.vue` now includes a page-level mode switch with `編集` and `帳票プレビュー`.
- The page now uses form tabs for `LIA010`, `LIA110`, `LIA130`, `LIA220`, and `LIA260`.
- The mode switch is aligned to the right side of the tab/mode toolbar.
- Tab captions are short user-facing labels and no longer show XML form codes such as `LIA010`.
- Tab visible labels and browser title/tooltip text are capped at 14 characters; full official form names remain available through accessibility labels.
- The tab switch now uses a compact rounded segmented-control design.
- The tab/mode toolbar now sits directly above the active panel without the previous large vertical gap.
- Long edit-mode field-list panels use denser rows and internal scrolling to keep the visible panel height lower.
- LIA010/LIA130 field-list tables use a fixed visible height, compact row padding, and sticky headers so long lists remain reviewable without making the editor panel tall.
- The preview area now uses a gray canvas and A4-like white paper frame with denser official-form borders and typography.
- The preview area is zoomable and draggable:
  - zoom out, zoom in, reset, and fit-to-width controls
  - current zoom percentage display
  - scrollbars remain available
  - drag-to-pan lets users slide the document inside the preview canvas
- Preview pages now use landscape A4 proportions to match the sample PDFs.
- The preview layouts were hand-tuned closer to the local PDF samples:
  - `LIA010` uses the main return's large title, tax office/submitter block, tax calculation block, and lower bank/notes areas.
  - `LIA110` uses the tax calculation table's dense 18-row ruled layout and official column order.
- `LIA130` uses the reduced-tax table's landscape header, organizer/factory boxes, and main calculation grid.
- `LIA130` preview was redone after review because the first version was too far from the sample:
  - added the sample-like diagonal top-left header
  - added row numbers ① through ⑭
  - added gray/diagonal non-entry cells
  - added the left vertical calculation label
  - added the lower `軽減割合の区分` box and final-total block
  - `LIA220` uses the return/deduction attachment's 18-row ruled layout.
  - `LIA260` uses the export attachment's 9-row ruled layout and reference-notes area.
- Edit mode remains intentionally simpler than preview mode; it is focused on changing draft field contents instead of copying the PDF layout.
- Export-exempt rows in edit mode now allow changing alcohol percentage and quantity, matching the editable behavior of other report detail rows.
- The top summary now uses `本則税額合計`, `軽減税額`, `納付税額`, `還付税額`, and `最終納付税額` instead of the ambiguous `酒税額合計`.
- Existing editable movement rows remain editable in their form panels; generated subtotal/total rows remain read-only.
- `LIA010` edit mode now lists all current `LIA010` XML output fields in the panel; tax amount fields were moved out of the page-level summary area and into this panel.
- `LIA130` edit mode now lists all current `LIA130` XML output fields, including the individual XML element codes used by the builder.
- `LIA010`, `LIA110`, `LIA130`, `LIA220`, and `LIA260` now have read-only paper-like preview views driven by the current draft data.
- `LIA260` is visible as a UI/preview panel, but XML output remains out of scope until export detail source fields are confirmed.
- Existing XML generation behavior is unchanged.
- The sample PDFs and guide were reviewed for spec refinement.
- The spec now treats `区分` as an e-Tax tax-rate application code and keeps `tax_event` as the movement classification that populates quantity/detail columns.

## Previous Validation Results
- `git diff --check -- specs/current-task.md docs/UI/tax-report-editor.md`: passed.
- `npx eslint src/views/Pages/TaxReportEditor.vue --no-fix` in `beeradmin_tail`: passed.
- `npm run type-check` in `beeradmin_tail`: passed.
- `npm run test --if-present` in `beeradmin_tail`: passed with no test script configured.
- `npm run build:test` in `beeradmin_tail`: passed with existing CSS minifier warnings and existing large-chunk warnings.
- `node -e "JSON.parse(...)"` for `src/locales/en.json` and `src/locales/ja.json`: passed.
- `git diff --check -- specs/current-task.md docs/UI/tax-report-editor.md beeradmin_tail/src/views/Pages/TaxReportEditor.vue beeradmin_tail/src/locales/ja.json beeradmin_tail/src/locales/en.json`: passed.
- After PDF-fidelity refinement:
  - `npx eslint src/views/Pages/TaxReportEditor.vue --no-fix` in `beeradmin_tail`: passed.
  - `npm run type-check` in `beeradmin_tail`: passed.
  - `npm run test --if-present` in `beeradmin_tail`: passed with no test script configured.
  - `npm run build:test` in `beeradmin_tail`: passed with existing CSS minifier warnings and existing large-chunk warnings.
  - `node -e "JSON.parse(...)"` for `src/locales/en.json` and `src/locales/ja.json`: passed.
  - `git diff --check -- specs/current-task.md docs/UI/tax-report-editor.md beeradmin_tail/src/views/Pages/TaxReportEditor.vue beeradmin_tail/src/locales/ja.json beeradmin_tail/src/locales/en.json`: passed.
- After LIA130 preview redo:
  - `npx eslint src/views/Pages/TaxReportEditor.vue --no-fix` in `beeradmin_tail`: passed.
  - `npm run type-check` in `beeradmin_tail`: passed.
  - `npm run test --if-present` in `beeradmin_tail`: passed with no test script configured.
  - `npm run build:test` in `beeradmin_tail`: passed with existing CSS minifier warnings and existing large-chunk warnings.
  - `git diff --check -- specs/current-task.md docs/UI/tax-report-editor.md beeradmin_tail/src/views/Pages/TaxReportEditor.vue`: passed.
- After zoomable/slidable preview update:
  - `npx eslint src/views/Pages/TaxReportEditor.vue --no-fix` in `beeradmin_tail`: passed.
  - `npm run type-check` in `beeradmin_tail`: passed.
  - `npm run test --if-present` in `beeradmin_tail`: passed with no test script configured.
  - `npm run build:test` in `beeradmin_tail`: passed with existing CSS minifier warnings and existing large-chunk warnings.
  - `node -e "JSON.parse(...)"` for `src/locales/en.json` and `src/locales/ja.json`: passed.
  - `git diff --check -- specs/current-task.md docs/UI/tax-report-editor.md beeradmin_tail/src/views/Pages/TaxReportEditor.vue beeradmin_tail/src/locales/ja.json beeradmin_tail/src/locales/en.json`: passed.
- After tab title length update:
  - `npx eslint src/views/Pages/TaxReportEditor.vue --no-fix` in `beeradmin_tail`: passed.
  - `npm run type-check` in `beeradmin_tail`: passed.
  - `npm run test --if-present` in `beeradmin_tail`: passed with no test script configured.
  - `npm run build:test` in `beeradmin_tail`: passed with existing CSS minifier warnings and existing large-chunk warnings.
  - `git diff --check -- specs/current-task.md docs/UI/tax-report-editor.md beeradmin_tail/src/views/Pages/TaxReportEditor.vue`: passed.
- After LIA010/LIA130 edit field-list update:
  - `npx eslint src/views/Pages/TaxReportEditor.vue --no-fix` in `beeradmin_tail`: passed.
  - `node -e "JSON.parse(...)"` for `src/locales/en.json` and `src/locales/ja.json`: passed.
  - `npm run type-check` in `beeradmin_tail`: passed.
  - `npm run test --if-present` in `beeradmin_tail`: passed with no test script configured.
  - `npm run build:test` in `beeradmin_tail`: passed with existing CSS minifier warnings and existing large-chunk warnings.
  - `git diff --check -- specs/current-task.md docs/UI/tax-report-editor.md beeradmin_tail/src/views/Pages/TaxReportEditor.vue beeradmin_tail/src/locales/ja.json beeradmin_tail/src/locales/en.json`: passed.
- After compact tab-to-panel layout update:
  - `npx eslint src/views/Pages/TaxReportEditor.vue --no-fix` in `beeradmin_tail`: passed.
  - `npm run type-check` in `beeradmin_tail`: passed.
  - `npm run test --if-present` in `beeradmin_tail`: passed with no test script configured.
  - `npm run build:test` in `beeradmin_tail`: passed with existing CSS minifier warnings and existing large-chunk warnings.
  - `git diff --check -- specs/current-task.md docs/UI/tax-report-editor.md beeradmin_tail/src/views/Pages/TaxReportEditor.vue`: passed.
