# Current Task Spec

## Goal
- Add clickable column sorting to master-page list tables that currently do not support sorting.
- Keep the existing filter and CRUD behavior unchanged while making table order user-controllable.

## Scope
- Implement sort state, sortable headers, and sorted row rendering for master-page list tables in the frontend.
- Reuse a shared sorting helper/composable where it reduces repeated comparator logic.
- Apply sorting only to list-style tables that display master data records or assigned attributes.

## Non-Goals
- No changes to report pages, inventory pages, or non-master screens.
- No changes to database schema, SQL, or API contracts.
- No changes to card-only lists.
- No changes to editor-only grids such as the calibration input table in `EquipmentMaster.vue`.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/composables/useTableSort.ts`
- `beeradmin_tail/src/views/Pages/AlcoholTaxMaster.vue`
- `beeradmin_tail/src/views/Pages/AlcoholTypeMaster.vue`
- `beeradmin_tail/src/views/Pages/AttrDefMaster.vue`
- `beeradmin_tail/src/views/Pages/AttrSetMaster.vue`
- `beeradmin_tail/src/views/Pages/MaterialClassMaster.vue`
- `beeradmin_tail/src/views/Pages/MaterialTypeMaster.vue`
- `beeradmin_tail/src/views/Pages/PackageMaster.vue`
- `beeradmin_tail/src/views/Pages/SiteTypeMaster.vue`
- `beeradmin_tail/src/views/Pages/UomMaster.vue`

## Data Model / API Changes
- None.

## Planned File Changes
- Add a shared table-sorting composable that handles sort key, direction, icon state, and null-safe value comparison.
- Update each targeted master page to:
  - define sortable columns,
  - render clickable table headers,
  - switch `filteredRows` / `pagedRows` rendering to sorted rows.
- Keep existing mobile card views and filters intact.

## Final Decisions
- Added `beeradmin_tail/src/composables/useTableSort.ts` as the shared sort-state and comparator helper for master tables.
- Applied sortable headers to these master-page tables:
  - `AlcoholTaxMaster`
  - `AlcoholTypeMaster`
  - `AttrDefMaster`
  - `AttrSetMaster` rule tables
  - `MaterialClassMaster`
  - `MaterialTypeMaster` attribute table
  - `PackageMaster`
  - `SiteTypeMaster`
  - `UomMaster`
- Kept existing default ordering where practical:
  - `createdAt desc` for registry-based masters that were previously fetched newest-first
  - `code` or `dimension` ascending for code-based masters
  - existing attribute/rule natural ordering as the initial sort where that was already the implicit UI order
- Left `EquipmentMaster` calibration editing grid out of scope because it is an input table with an existing dedicated `sort by depth` action, not a master list view.

## Validation Plan
- Verify each targeted table header toggles ascending/descending order.
- Verify filters are applied before sorting, and pagination remains based on the sorted list where pagination exists.
- Run required checks before finishing:
  - unit tests
  - lint
  - type-check
- If no unit test script exists, report that explicitly.

## Validation Outcome
- Verified the targeted master tables now render sortable headers and use sorted row collections.
- `npm run type-check` passed in `beeradmin_tail`.
- Unit tests could not be run because `beeradmin_tail/package.json` does not define a `test` script.
- Targeted ESLint execution on the touched files still fails due pre-existing repository issues, including `@typescript-eslint/no-explicit-any` and some `no-unused-vars` findings in files that were already carrying those patterns.
