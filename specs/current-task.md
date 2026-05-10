# Current Task

## Goal
- Stop `移送詰口管理` saves from being blocked by a source lot or batch `created_at` timestamp.
- Validate packing movement chronology against the batch business start (`mes_batches.actual_start`) and, only when needed, the source lot business timestamp (`lot.produced_at`).
- Keep date-only comparison aligned with `docs/domain/date-and-time.md`.
- Stop `public.product_filling` from rejecting backdated packing events when the source lot has a valid business production date.

## Scope
- Update the BatchPacking source-lot chronology check used before saving filling, transfer, and ship packing events.
- Load the source lot `produced_at` value so it can be used as a business-date fallback.
- Compare movement date to the batch actual start date without using the lot-created timestamp RPC.
- Update the shared backend lot effective-start helper so `lot.produced_at` is preferred over the operational produce movement timestamp.
- Update the backend chronology error wording so it no longer says source lot creation time.

## Non-Goals
- Do not change database schema.
- Do not change frontend shared `lotChronology` helper.
- Do not change inventory, product movement, or tax-report behavior.
- Do not change packing quantity or package-volume behavior.
- Do not remove chronology validation entirely; only replace the `created_at`-based validation on this page.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/views/Pages/BatchPacking.vue`
- `DB/function/03_public.lot_chronology.sql`

## Data Model / API Changes
- No schema changes.
- No API changes.
- Frontend source-lot queries read existing `lot.produced_at`.
- `mes_batches.actual_start` remains the primary date-only business start for this page.
- Backend effective lot start priority becomes `batch.actual_start`, `lot.produced_at`, produce movement timestamp, then `lot.created_at`.

## Planned File Changes
- Remove BatchPacking’s dependency on `checkLotChronology` / `lotChronologyViolationMessage`.
- Include `produced_at` in source lot query results.
- Replace `assertPackingSourceLotChronology` with a page-local business-date comparison:
  - movement timestamp date must not be before `batch.actual_start`;
  - if `batch.actual_start` is unavailable, movement timestamp date must not be before `sourceLot.produced_at`;
  - no comparison uses `created_at`.
- Change `lot_effective_created_at` to prefer `lot.produced_at` before produce movement timestamp.
- Increment stored-function version comments for changed chronology functions.

## Validation Plan
- Run `git diff --check`.
- Run targeted lint for `beeradmin_tail/src/views/Pages/BatchPacking.vue`.
- Run `npm run type-check` in `beeradmin_tail`.
- Run a static stored-function version/comment coverage check.

## Final Decisions
- BatchPacking no longer calls the shared `lot_effective_created_at`-based chronology check before saving packing events.
- Packing movement chronology is compared by normalized `YYYY-MM-DD` values.
- `mes_batches.actual_start` is the primary source business date.
- `lot.produced_at` is only a fallback when the batch actual start is unavailable.
- If neither business date is available, the page logs a warning and does not block the save on chronology.
- Backend lot effective-start priority is now `batch.actual_start`, then `lot.produced_at`, then produce movement timestamp, then `lot.created_at`.
- Backend `LOT_TIME004` wording now says effective start time instead of creation time.
- Stored-function version comments were incremented for `lot_effective_created_at` and `_assert_source_lot_not_after_movement`.

## Validation Results
- `git diff --check` passed.
- `npm exec eslint -- src/views/Pages/BatchPacking.vue` passed.
- `npm run type-check` passed in `beeradmin_tail`.
- Static stored-function version/comment coverage passed: 43 functions and 43 version comments.
- Full no-fix lint (`npm exec eslint -- .`) was run and failed on existing unrelated lint debt across the frontend, including legacy `vue/block-lang`, `vue/multi-word-component-names`, `@typescript-eslint/no-explicit-any`, and `@typescript-eslint/no-unused-vars` errors.
