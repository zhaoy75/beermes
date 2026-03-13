# Current Task Spec

## Goal
- Remove subtitle text from the `製品ビール移出登録` page.

## Scope
- Stop rendering all subtitle text blocks on the `製品ビール移出登録` page.
- Remove the corresponding Japanese locale subtitle entries that become unused after the view change.

## Non-Goals
- No changes to movement behavior, API calls, validation, routing, or step flow.
- No changes to non-subtitle helper text such as loading, warning, or hint messages.
- No English copy changes unless implementation requires it.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue`
- `beeradmin_tail/src/locales/ja.json`

## Data Model / API Changes
- None.

## Validation Plan
- Confirm subtitle text is no longer rendered in the page header area of `ProducedBeerMovementEdit.vue`.
- Confirm subtitle text is no longer rendered in Steps 1-5 section headers of `ProducedBeerMovementEdit.vue`.
- Confirm the removed Japanese subtitle entries are not left as active UI copy in `beeradmin_tail/src/locales/ja.json`.
- Run frontend validation after implementation:
  - unit tests
  - lint
  - type-check

## Planned File Changes
- `specs/current-task.md`: replace the previous task spec with this subtitle-removal task.
- `beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue`: remove the rendered subtitle text blocks from the page.
- `beeradmin_tail/src/locales/ja.json`: remove the matching unused Japanese subtitle entries.

## Final Decisions
- Removed all subtitle text renders from `beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue`.
- Removed the now-unused Japanese subtitle entries under `producedBeer.movementWizard` from `beeradmin_tail/src/locales/ja.json`.
- No data model, API, validation, routing, or step-flow changes were required.
