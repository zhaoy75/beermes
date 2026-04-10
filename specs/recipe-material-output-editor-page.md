# Recipe Material / Output Editor Page Spec

## Goal
- Move recipe raw-material editing and output add/edit out of inline/modal UI into a dedicated page.
- Use one dedicated page component for both:
  - raw material add/edit
  - output add/edit

## Scope
- Add a dedicated route and page component for recipe body item editing.
- Support two editor modes:
  - `material`
  - `output`
- For `material` mode:
  - show the `RAW_MATERIAL` subtree from `public.type_def`
  - show a filtered `mes.mst_material` source list
  - show recipe material fields on the right
  - show dynamic attribute fields driven by `entity_attr_set` / `attr_set_rule` / `attr_def`
  - do not require any attribute field to be filled during recipe editing
  - when editing an existing recipe row, preserve the original material identity if it is no longer available in the active material source list
  - do not show a persistent warning message for that preserved-material fallback
  - do not auto-clear the currently selected material when the type tree selection changes
  - allow saving without an explicit master-material selection by generating a recipe-local material identity
- For `output` mode:
  - show a dedicated output form on the page
  - allow section switching between `primary`, `co_products`, and `waste`
- Load the target recipe version directly from `mes.mst_recipe_version`.
- Persist changes directly back to `mes.mst_recipe_version.recipe_body_json`.
- Return to `RecipeEdit.vue` after successful save or cancel.
- Update `RecipeEdit.vue` so material/output add/edit actions navigate to this dedicated page instead of opening inline/modal editors.

## Non-Goals
- No changes to equipment, flow, quality, or document editors.
- No redesign of the rest of `RecipeEdit.vue`.
- No DB schema changes beyond the already-added `attr_values` support.
- No migration of existing recipe data.
- No sidebar navigation entry for this page; it is a workflow sub-page only.

## Affected Files
- [current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [recipe-material-output-editor-page.md](/Users/zhao/dev/other/beer/specs/recipe-material-output-editor-page.md)
- [recipeedit.md](/Users/zhao/dev/other/beer/docs/UI/mes/recipeedit.md)
- [tenant-routes.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/router/tenant-routes.ts)
- [RecipeEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RecipeEdit.vue)
- [RecipeMaterialOutputEditor.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RecipeMaterialOutputEditor.vue)
- [ja.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/ja.json)
- [en.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/en.json)
- [recipe_material_output_editor.md](/Users/zhao/dev/other/beer/docs/UI/mes/recipe_material_output_editor.md)

## Data Model / API Changes
- No new DB tables or columns.
- `material` editor continues to use recipe material objects with optional `attr_values`.
- `output` editor continues to use recipe output objects under:
  - `recipe_body_json.outputs.primary`
  - `recipe_body_json.outputs.co_products`
  - `recipe_body_json.outputs.waste`
- Dedicated page route parameters:
  - `recipeId`
  - `versionId`
  - `kind` in `material | output`
  - `section`
  - optional `index`

## UX Decisions
- `RecipeEdit.vue` remains the list/overview page for recipe sections.
- Detailed editing for raw materials and outputs moves to the dedicated page.
- The page header shows:
  - back button to recipe edit
  - mode-aware title
  - recipe code / recipe name / version summary
- Material page layout:
  - left source pane for type tree + material list
  - right edit pane for recipe fields + dynamic attributes
- Dynamic attribute inputs remain available for convenience, but all are optional in the recipe editor even if the underlying attribute definition is marked required.
- If an existing recipe material no longer resolves to an active source-list entry, the page still shows and preserves that material so the row can be saved after editing other fields.
- That fallback is silent in the normal page layout; the material summary still shows the preserved material name/code.
- The type tree filters the source list, but it does not forcibly clear an already selected material.
- When no master material is selected, save derives a lightweight material identity from the entered role and selected type so the recipe row remains serializable.
- Output page layout:
  - single edit pane with output fields
- Save writes directly to the target recipe version row, then returns to `RecipeEdit.vue`.
- Cancel returns without saving.

## Validation Plan
- Run:
  - unit tests
  - lint
  - type-check

## Final Decisions
- Added a dedicated workflow page at `/recipeEdit/:recipeId/:versionId/item/:kind/:section/:index?`.
- The dedicated page component is `RecipeMaterialOutputEditor.vue`.
- One page handles both:
  - raw material add/edit
  - output add/edit
- `RecipeEdit.vue` now launches this page for material and output actions instead of opening local editors.
- Before routing to the dedicated page, `RecipeEdit.vue` persists the current recipe so unsaved page state is not dropped.
- The dedicated page saves only `mes.mst_recipe_version.recipe_body_json` and then returns to `RecipeEdit.vue`.
- Material mode keeps the `RAW_MATERIAL` tree + `mes.mst_material` source flow and type-driven `attr_values`.
- In `RecipeMaterialOutputEditor.vue`, type-driven attribute fields are informational/optional during recipe editing and do not block save when left blank.
- When editing an existing material row, save falls back to the stored material identity if no active `mst_material` row can be resolved.
- The page does not show a persistent warning message when using that stored material fallback.
- The selected material is preserved when the type tree selection changes; users must explicitly choose a different material to replace it.
- For new material rows, a master-material selection is optional; the page writes a fallback `material_key` based on recipe-entered data.
- Output mode uses a dedicated page form rather than a modal.

## Validation Results
- `npx eslint src/views/Pages/RecipeMaterialOutputEditor.vue --no-fix`: passed
- `npm run type-check`: passed
- `npm run test`: failed because `beeradmin_tail/package.json` has no `test` script
- `npx eslint . --no-fix`: failed because of existing repo-wide ESLint errors outside this task
