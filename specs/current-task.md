# Current Task

## Goal
- Fix lot chronology validation for batch-produced lots so `created_at` is not used ahead of batch `実績開始` (`mes_batches.actual_start`).
- Prevent 移送詰口管理 from rejecting a historical packing/filling movement just because the lot row was inserted later.
- Align actual-yield lot creation from the batch pages with `実績開始`.

## Scope
- Update the database lot chronology helper.
- Update batch actual-yield production payloads in the frontend pages that can create the source lot.
- Keep the chronology rule itself: a source lot still cannot be consumed/moved before its effective creation time.

## Non-Goals
- Do not remove source-lot chronology validation.
- Do not change unrelated movement rules.
- Do not backfill existing lot or movement rows in this task.
- Do not modify tenant transaction delete scripts.

## Affected Files
- `specs/current-task.md`
- `DB/function/03_public.lot_chronology.sql`
- `beeradmin_tail/src/views/Pages/BatchPacking.vue`
- `beeradmin_tail/src/views/Pages/BatchEdit.vue`

## Data Model / API Changes
- No schema changes.
- `public.lot_effective_created_at(p_lot_id)` behavior changes for lots linked to `public.mes_batches`:
  - prefer `mes_batches.actual_start`
  - then lot-producing movement time
  - then `lot.produced_at`
  - use `lot.created_at` only as the last fallback

## Implementation Plan
- Change `lot_effective_created_at` to load the lot row and joined batch row before returning a fallback.
- Keep producing movement time available, but let batch `actual_start` override it for batch-owned lots.
- Change actual-yield lot creation in `BatchPacking.vue` and `BatchEdit.vue` from `actual_end` to `actual_start`.
- Validate the changed SQL and frontend files.

## Validation Plan
- `git diff --check`
- Targeted lint:
  - `npx eslint src/views/Pages/BatchPacking.vue src/views/Pages/BatchEdit.vue`
- Static review:
  - `lot_effective_created_at` uses `mes_batches.actual_start` before `lot.created_at`
  - actual-yield product-produce payloads use `actual_start`

## Final Decisions
- `public.lot_effective_created_at(p_lot_id)` now prefers the linked batch `actual_start` before movement/produced/created timestamps.
- Existing batch-produced lots can pass chronology checks based on `実績開始` when `mes_batches.actual_start` is populated, even if the lot row was inserted later.
- Actual-yield production from both batch pages now sends `actual_start` as the product-produce `movement_at` / `produced_at`.
- The final fallback to `lot.created_at` remains only for lots without batch `actual_start`, producing movement time, or `produced_at`.

## Validation Results
- `git diff --check` passed.
- `npx eslint src/views/Pages/BatchPacking.vue src/views/Pages/BatchEdit.vue` passed.
- `npm run type-check` passed.
- Static review confirmed `lot_effective_created_at` uses `mes_batches.actual_start` before `lot.created_at`.
- Static review confirmed actual-yield product-produce payloads use `batch.value.actual_start` in both batch pages.
- SQL was not executed against a live database in this workspace.
