# Current Task

## Goal
- Add a multi-check feature to the `在庫検索` modal dialog so supported caller pages can select and apply multiple inventory lots.

## Scope
- Update the inventory search shortcut modal spec to define multi-check behavior.
- Add multi-select support to the shared inventory search modal.
- Show a checkbox column, visible-row select-all checkbox, selected count, and clear action in the inventory search modal.
- Show the apply-selected action only when a caller provides multi-select handling.
- Preserve existing single-row double-click and Enter selection behavior.
- Integrate ProductMoveFast so applying selected inventory rows appends one movement input line per selected lot.

## Non-Goals
- Do not change inventory query, filtering, sorting, or merge rules.
- Do not change backend RPCs, database schema, or posting behavior.
- Do not change ProductMoveFast route, tax, validation, or save semantics.
- Do not add multi-check to unrelated pages.

## Affected Files
- `specs/current-task.md`
- `docs/UI/inventory-search-shortcut-modal-spec.md`
- `beeradmin_tail/src/components/inventory/InventorySearchModal.vue`
- `beeradmin_tail/src/components/layout/AdminLayout.vue`
- `beeradmin_tail/src/composables/useInventorySearchModal.ts`
- `beeradmin_tail/src/views/Pages/ProductMoveFast.vue`
- `beeradmin_tail/src/locales/ja.json`
- `beeradmin_tail/src/locales/en.json`

## Data Model / API Changes
- No database schema changes.
- No Supabase RPC changes.
- Frontend-only contract change: `InventorySearchOpenOptions` keeps optional multi-select callback and optional post-close focus callback for pages that can apply selected rows.

## Validation Plan
- Run `git diff --check -- specs/current-task.md docs/UI/inventory-search-shortcut-modal-spec.md beeradmin_tail/src/components/inventory/InventorySearchModal.vue beeradmin_tail/src/components/layout/AdminLayout.vue beeradmin_tail/src/composables/useInventorySearchModal.ts beeradmin_tail/src/views/Pages/ProductMoveFast.vue beeradmin_tail/src/locales/ja.json beeradmin_tail/src/locales/en.json`.
- Run `npm run type-check` in `beeradmin_tail`.
- Run focused ESLint on touched Vue/TS files.

## Planned File Changes
- `inventory-search-shortcut-modal-spec.md`: document modal multi-check behavior and ProductMoveFast integration.
- `useInventorySearchModal.ts`: add optional `onSelectMany` and `afterSelectManyFocus`.
- `AdminLayout.vue`: render modal multi-check everywhere and dispatch selected rows when a caller provides the callback.
- `InventorySearchModal.vue`: keep selection state, checkbox UI, visible select-all, selected summary, clear selection, optional apply-selected emit, and selected-row pruning.
- `ProductMoveFast.vue`: convert applied selected inventory rows into movement input lines.
- Locale files: add labels for selected count, select row/visible, clear selection, and apply selected.

## Final Decisions
- Added optional `onSelectMany` and `afterSelectManyFocus` callbacks to the inventory search modal options.
- The modal shows checkbox controls globally.
- The modal shows the apply-selected button only when a caller provides multi-select handling.
- Added visible-row select-all, row-level checkbox selection, selected-count summary, clear selection, and apply-selected controls.
- Selected row IDs are pruned when visible result rows change after filtering, sorting, or reload.
- Applying selected rows emits the same inventory selection payload shape used by single-row selection.
- Merged selected rows are flattened into their underlying lot details for the multi-select payload.
- Existing double-click and Enter behavior remains single-row selection.
- ProductMoveFast enables modal multi-select and appends one movement input line per selected inventory lot.
- ProductMoveFast returns focus to the quick keyword input after multi-select apply closes the modal.

## Validation Results
- `git diff --check -- specs/current-task.md docs/UI/inventory-search-shortcut-modal-spec.md beeradmin_tail/src/components/inventory/InventorySearchModal.vue beeradmin_tail/src/components/layout/AdminLayout.vue beeradmin_tail/src/composables/useInventorySearchModal.ts beeradmin_tail/src/views/Pages/ProductMoveFast.vue beeradmin_tail/src/locales/ja.json beeradmin_tail/src/locales/en.json` passed.
- `npm run type-check` passed in `beeradmin_tail`.
- `npx eslint src/components/inventory/InventorySearchModal.vue src/components/layout/AdminLayout.vue src/composables/useInventorySearchModal.ts src/views/Pages/ProductMoveFast.vue --no-fix` passed.
- `npm run build-only` passed in `beeradmin_tail`; Vite still reports existing CSS minifier warnings for empty `:is()` selectors.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a unit test script.
