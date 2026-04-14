# Current Task

## Goal
- Build the raw-material inventory maintenance flow so the list page and edit page match the current lot + movement design.
- Fix the regression where `RawMaterialInventory` renders blank at runtime.

## Scope
- Replace the old `RawMaterialInventory.vue` with a lot-based PrimeVue `DataTable` inventory page.
- Show these columns:
  - material name only
  - material type
  - quantity in stock
  - unit of measure
  - location
  - actions
- Add search filters for:
  - material name
  - material type
  - location
- Make material-type filtering quick to use from the search section.
- Add row actions for:
  - edit
  - move
  - dispose
- Keep style changes local to the inventory page only. Do not change global table CSS.
- Add the edit-page route if missing.
- Add the raw-material inventory sidebar entry under `在庫管理` in development mode.
- Update locale keys needed by the new list and existing edit page.
- Fix any runtime issue that prevents the raw-material inventory page from rendering.

## Non-Goals
- Do not change database schema.
- Do not redesign unrelated pages.
- Do not move dispose into the edit page in this turn.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [specs/raw-material-inventory-page.md](/Users/zhao/dev/other/beer/specs/raw-material-inventory-page.md)
- [specs/raw-material-inventory-edit-page.md](/Users/zhao/dev/other/beer/specs/raw-material-inventory-edit-page.md)
- [tenant-routes.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/router/tenant-routes.ts)
- [AppSidebar.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/components/layout/AppSidebar.vue)
- [main.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/main.ts)
- [package.json](/Users/zhao/dev/other/beer/beeradmin_tail/package.json)
- [RawMaterialInventory.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RawMaterialInventory.vue)
- [RawMaterialInventoryEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RawMaterialInventoryEdit.vue)
- [ja.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/ja.json)
- [en.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/en.json)

## Data Model / API Changes
- No schema change.
- Inventory list should use:
  - `lot`
  - `inv_movements`
  - `inv_movement_lines`
  - `mes.mst_material`
  - `type_def`
  - `mst_sites`
  - `mst_uom`
- Inventory quantity must be calculated from movement in / movement out, not read as source-of-truth from `inv_inventory`.
- `inv_inventory` remains projection only.

## Final Decisions
- `RawMaterialInventory.vue` remains a PrimeVue `DataTable`, but all visual alignment with the app's normal list tables is handled through page-local `.inventory-datatable` scoped styles only.
- The material-name column shows the material name as the main value and may show the lot number as secondary context; it does not show material code.
- Material-type quick filters are rendered as button chips in the search section.
- The quick filter excludes the `RAW_MATERIAL` root node itself and applies to the selected type subtree so parent-type selection still shows descendant material rows.
- The list is restricted to materials whose `material_type_id` resolves inside the `RAW_MATERIAL` type tree.
- The dedicated edit route is `/rawMaterialInventory/edit/:lotId?` with optional `mode=move` query for move mode.
- The sidebar should expose `原材料在庫` under `在庫管理` only when development-mode features are visible.
- PrimeVue must be initialized in `main.ts` with a theme preset before using the raw-material inventory `DataTable` page.
- The app manifest should explicitly list the PrimeVue packages used by the raw-material inventory page so fresh installs are consistent with the runtime code.
- Dispose remains a list-page action, uses the shared confirm dialog, inserts a posted `waste` movement, updates the lot to consumed, refreshes the `inv_inventory` projection, and reloads the list.

## Validation Plan
- Run:
  - `npx eslint src/views/Pages/RawMaterialInventory.vue src/views/Pages/RawMaterialInventoryEdit.vue src/router/tenant-routes.ts src/components/layout/AppSidebar.vue --no-fix` in `beeradmin_tail`
  - `npm run type-check` in `beeradmin_tail`
  - `npm run build-only` in `beeradmin_tail`
  - `npm run test` in `beeradmin_tail`

## Validation Results
- `npx eslint src/main.ts src/views/Pages/RawMaterialInventory.vue src/views/Pages/RawMaterialInventoryEdit.vue src/router/tenant-routes.ts src/components/layout/AppSidebar.vue --no-fix`: passed
- `npm run type-check`: passed
- `npm run build-only`: passed, with pre-existing CSS minify warnings unrelated to this task
- `npm run test`: failed because `beeradmin_tail/package.json` has no `test` script
