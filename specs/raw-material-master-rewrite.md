# Raw Material Master Rewrite Spec

## Goal
- Rewrite the `原材料登録` page into a cleaner, material-type-first master-maintenance page for raw material data.
- Improve usability for the create flow by making material-type selection the first-class interaction instead of a secondary form field.

## Background
- The current page is [MaterialMaster.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/MaterialMaster.vue).
- Current issues:
  - it uses a flat category-tab model (`malt`, `hop`, `yeast`, `adjunct`) instead of the shared `material_type` tree
  - it edits in a modal, which makes create/edit feel disconnected from browsing
  - it uses `mst_materials`, while recipe-related pages already use `mes.mst_material`
  - it does not reuse the material-type selection patterns already present in recipe editing
- Related current references:
  - [MaterialMaster.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/MaterialMaster.vue)
  - [RecipeEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RecipeEdit.vue)
  - [RecipeMaterialOutputEditor.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RecipeMaterialOutputEditor.vue)
  - [type_master.md](/Users/zhao/dev/other/beer/docs/UI/master/type_master.md)
  - [mes_recipe.md](/Users/zhao/dev/other/beer/docs/mes_recipe.md)

## Product Decisions
### Source Of Truth
- The rewritten page should use `mes.mst_material` as the canonical material table.
- Material type classification should use `public.type_def` where `domain = 'material_type'`.
- Reason:
  - current recipe pages already depend on `mes.mst_material`
  - `type_def` is already the shared classification model in the repo
  - continuing to invest in `mst_materials` + hardcoded categories would deepen the current split-brain design

### Route
- Keep the current route and entrypoint for now:
  - route: `/MaterialMaster`
  - component path: [MaterialMaster.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/MaterialMaster.vue)
- Reason:
  - minimizes router churn
  - allows a full page rewrite without forcing unrelated navigation updates in the same task

### Page Identity
- Japanese page name: `原材料登録`
- English meaning in code/docs: raw material master / raw material registration
- The page is a master-maintenance screen, not an inventory or receipt screen.

## Scope
- Replace the flat category-based CRUD page with a type-tree-based maintenance page.
- Support:
  - browse raw materials by material type
  - search raw materials
  - create a raw material under a selected material type
  - edit an existing raw material
  - delete an existing raw material
- Improve create usability so the user chooses a type first, then fills the form.
- Keep the first rewrite focused on core material maintenance fields.

## Non-Goals
- No rewrite of:
  - [RawMaterialInventory.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RawMaterialInventory.vue)
  - [RawMaterialReceipts.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RawMaterialReceipts.vue)
- No embedded material-type maintenance in this page.
- No embedded attribute-set maintenance in this page.
- No DB migration between `mst_materials` and `mes.mst_material` in this task.
- No bulk import/export workflow in this first rewrite.

## UX Objectives
- Make material type selection obvious and fast.
- Reduce modal-heavy interaction and keep browsing context visible while editing.
- Make the create flow feel like:
  - choose type
  - confirm type context
  - enter material details
  - save and stay in that type context
- Keep the page usable on both desktop and mobile.

## Page Layout
### Desktop
- Three-column layout:
  - left: material type tree
  - center: material list under selected type
  - right: material form / detail pane
- The left `原材料種別` panel should be hideable on large screens.
- The hide/show control should be a small icon handle placed on the boundary between the left `原材料種別` panel and the center `原材料一覧` panel.
- When the left panel is hidden:
  - the remaining layout should collapse cleanly without leaving a wide empty column
  - the small boundary handle should remain visible so the panel can be reopened
  - the selected type context should remain active for list filtering and form context

### Mobile
- Stacked layout:
  - type selector section first
  - filtered material list second
  - form section third
- The selected type summary should stay visible at the top of the form section.

### Header
- Title: `原材料登録`
- Subtitle: maintain raw material master data used by recipe and manufacturing workflows
- Actions:
  - `新規原材料`
  - `更新`
- Search:
  - keyword search for code/name

## Main Regions
### Left: Material Type Tree
- Data source:
  - `public.type_def`
  - filter: `domain = 'material_type'`
  - filter: `is_active = true`
- Display:
  - tree hierarchy
  - type display name
  - optional count badge if inexpensive to query
- Behavior:
  - selecting a type filters the material list
  - selecting a type sets the default create context
  - tree remains expanded enough to keep navigation easy
  - parent nodes must be foldable / unfoldable
  - when search is active, matching branches should still be visible even if the user previously collapsed a parent
  - when a type is selected from the list/edit flow, its ancestor path should be expanded so the current selection stays visible
- UX helpers:
  - search box for types
  - recent or pinned types section above the tree if simple to implement
  - path/breadcrumb for selected type
  - small boundary icon handle for hide/show on desktop

### Center: Material List
- Shows materials filtered by selected type subtree.
- Columns:
  - material code
  - material name
  - base UOM
  - status
  - actions
- Behavior:
  - selecting a row loads it into the right-side form
  - create button in this pane should mean “create under selected type”
- Empty states:
  - no type selected
  - no materials under selected type
  - no search results

### Right: Material Form
- Default state:
  - if no row selected, show a create prompt and selected type summary
- Edit state:
  - show material detail form
- Create state:
  - form opens already pinned to the selected material type
- Preferred interaction:
  - dedicated form pane, not a modal

## Create Flow
### Primary Flow
1. User chooses a material type from the left tree.
2. User clicks `新規原材料`.
3. Form opens in create mode with:
   - selected type path shown clearly
   - type locked by default, or changed only through an explicit `種別を変更` action
4. User enters required fields.
5. Save returns to the same selected type context and refreshes the center list.

### If No Type Is Selected
- `新規原材料` should not open a blank generic form.
- Expected behavior:
  - either disable the button until a type is selected
  - or open a focused type-picker dialog first
- Recommended choice:
  - disable create until a type is selected, with inline guidance text
- Reason:
  - this is simpler and keeps the page model clear

## Edit Flow
- Selecting a row in the material list loads it in the form pane.
- The form shows:
  - material code
  - material name
  - selected type path
  - base UOM
  - status
- If the material belongs to a type outside the current filter context, the tree should auto-expand/select its type path when the row is opened from the list.

## Delete Flow
- Delete remains confirmation-based.
- The confirmation dialog should be the only modal retained in the first rewrite.
- After delete:
  - stay in the same selected type
  - refresh list
  - clear the form pane if that deleted row was open

## Form Fields
### First Rewrite Required Fields
- `material_code`
- `material_name`
- `material_type_id`
- `base_uom_id`
- `status`

### First Rewrite Optional Fields
- `is_batch_managed` if confirmed present in the target table
- `is_lot_managed` if confirmed present in the target table
- freeform notes only if a backing column exists

### Field Strategy
- Do not carry over the current `category` field UX from the old page.
- Material type should replace category as the main classification concept.

## Data Sources
### Materials
- Table: `mes.mst_material`
- Minimum fields needed by the page:
  - `id`
  - `material_code`
  - `material_name`
  - `material_type_id`
  - `base_uom_id`
  - `status`

### Material Types
- Table: `public.type_def`
- Filters:
  - `domain = 'material_type'`
  - `is_active = true`
- Fields:
  - `type_id`
  - `code`
  - `name`
  - `name_i18n`
  - `parent_type_id`
  - `sort_order`

### UOM
- Table: `public.mst_uom`
- Fields:
  - `id`
  - `code`
  - `name`

## Validation Rules
- `material_code` required
- `material_name` required
- `material_type_id` required
- `base_uom_id` required
- `status` required
- Duplicate-code handling should be surfaced clearly from DB errors.

## Type Selection Usability Requirements
- The selected type must always be visible in the create form.
- The user must not need to reopen a modal just to understand which type they are creating under.
- The tree should support quick narrowing:
  - type search
  - subtree filtering
- Recommended enhancements for implementation priority:
  - show selected type path
  - remember last selected type in page state
  - create button label can include context, e.g. `この種別で追加`

## Type-Driven Attributes
### First Rewrite
- Do not embed full attribute-set maintenance into this page.
- Keep the first rewrite focused on core master fields.

### Optional Future Extension
- After the base rewrite is stable, the form can add a type-driven attribute section using:
  - `entity_attr_set`
  - `attr_set_rule`
  - `attr_def`
- This future extension should reuse the same patterns already used in recipe editors.

## Implementation Guidance
### Recommended Structure
- Keep the page route/component entrypoint the same.
- Break the page into focused units:
  - `MaterialTypeTree.vue`
  - `MaterialListPane.vue`
  - `MaterialFormPane.vue`
  - optional composables:
    - `useMaterialTypes`
    - `useMaterials`

### Rewrite Strategy
1. Replace category tabs with material type tree.
2. Move from modal editing to persistent form pane.
3. Switch material CRUD to `mes.mst_material`.
4. Wire selected type into create flow.
5. Add search and empty-state polish.
6. Add optional type-driven attribute section later if needed.

### State Model
- `selectedTypeId`
- `selectedMaterialId`
- `materialListFilter`
- `materialFormMode = create | edit`
- `expandedTypeIds`
- `showTypePanel`

### Empty States
- No type selected:
  - show instruction to select a material type
- Type selected but no materials:
  - show CTA to create the first material under that type
- Search result empty:
  - show filtered-empty message without clearing selected type

## Risks / Notes
- There is an existing table mismatch in the repo between `mst_materials` and `mes.mst_material`.
- This spec resolves the new page direction in favor of `mes.mst_material`, but unrelated pages still using `mst_materials` are outside this task.
- If implementation finds that the current tenant environment does not yet support the required `mes.mst_material` columns, the implementation task must stop and reconcile schema usage before proceeding.

## Affected Files For Future Implementation
- [MaterialMaster.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/MaterialMaster.vue)
- [tenant-routes.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/router/tenant-routes.ts)
- [ja.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/ja.json)
- [en.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/en.json)
- Optional new files under:
  - `beeradmin_tail/src/views/Pages/components/`
  - `beeradmin_tail/src/composables/`

## Validation Plan For Future Implementation
- Run:
  - unit tests
  - lint
  - type-check

## Implementation Notes
- Implemented directly in [MaterialMaster.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/MaterialMaster.vue) without splitting into new subcomponents in the first pass.
- The rewritten page now:
  - reads and writes `mes.mst_material`
  - reads `public.type_def` filtered by `domain = 'material_type'` and `is_active = true`
  - reads `public.mst_uom`
- The page prefers the `RAW_MATERIAL` type as the tree root when available; otherwise it renders from all root material types.
- Create is disabled until a type is selected.
- The form keeps the selected type context visible and allows reassignment only through an explicit `Use Selected Type` action.
- The implemented form scope is limited to:
  - `material_code`
  - `material_name`
  - `material_type_id`
  - `base_uom_id`
  - `status`
- Router changes were not required for this implementation.
- Additional implemented UI refinement:
  - on large screens, the `原材料種別` panel hide/show interaction uses a small boundary icon handle between `原材料種別` and `原材料一覧`
  - the hidden state collapses cleanly to the remaining list/form columns without leaving a wide empty desktop column
  - hiding the panel does not clear the selected type context
  - a large top-header show/hide button is not used for the final desktop interaction

## Validation Results
- `npx eslint src/views/Pages/MaterialMaster.vue --no-fix`: passed
- `node -e "const fs=require('fs'); JSON.parse(fs.readFileSync('src/locales/ja.json','utf8')); JSON.parse(fs.readFileSync('src/locales/en.json','utf8'));"`: passed
- `npm run type-check`: passed
- `npm run test`: failed because `beeradmin_tail/package.json` has no `test` script
- `npx eslint . --no-fix`: failed because of the pre-existing repo-wide ESLint backlog outside this implementation
