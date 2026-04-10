# Current Task Spec

## Goal
- Align `RecipeStepEditor.vue` with the updated step-editor UI doc so adding an input material row focuses the new material field, opens the type browser, fills the row UOM from `type_def.meta.default_uom`, and all step-page UOM inputs use dropdown lists instead of free-text fields.

## Scope
- Update the active task spec for this frontend behavior change.
- Extend the shared type-browser selection payload so callers can receive default UOM metadata from `public.type_def.meta.default_uom`.
- Update the input-material add flow in `RecipeStepEditor.vue`.
- Load `public.mst_uom` on the step editor page and replace free-text `uom_code` fields with dropdown selects.
- Set default values for newly added input-material rows.
- Keep the change limited to the dedicated step editor page.

## Non-Goals
- Do not change the recipe JSON schema.
- Do not change equipment or QA editors in this task.
- Do not add or modify database DDL/DML.
- Do not change the existing type browser layout or keyboard navigation.

## Affected Files
- [current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [RecipeStepEditor.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RecipeStepEditor.vue)
- [TypeDefGraphModal.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/components/type-def/TypeDefGraphModal.vue)
- [useTypeDefGraphModal.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/composables/useTypeDefGraphModal.ts)

## Data Model / API Changes
- No database schema changes.
- The shared `TypeDefGraphSelection` payload will include:
  - `defaultUomCode`
  - `defaultUomId`
- The values come from `public.type_def.meta.default_uom`.
- `RecipeStepEditor.vue` will load `public.mst_uom` and use it as the option source for step-page `uom_code` dropdowns.
- `RecipeStepEditor.vue` will use `defaultUomCode` to populate `flow.steps[].material_inputs[].uom_code` in the editor state.

## Planned File Changes
- Replace the active task spec with this step-editor behavior task.
- Update the type browser query to load `meta`.
- Parse `meta.default_uom` in the modal and include it in the emitted selection payload.
- Add input-field refs in `RecipeStepEditor.vue` so the newest input-material row can be focused after add.
- Update the material-key selection callback so it sets the selected type code and copies the default UOM into the row when available.
- Load UOM reference rows in `RecipeStepEditor.vue`.
- Replace the input-material, output-material, and parameter `uom_code` text inputs with dropdowns backed by loaded UOM codes.
- Default new input-material rows to `basis = per_base` and `consumption_mode = estimate`.

## Final Decisions
- `RecipeStepEditor.vue` now focuses the newly added input-material key field when the add button is pressed.
- The existing focus handler remains the entry point for opening the shared `種別ブラウザ`, so the browser appears immediately after the new input receives focus.
- The shared `TypeDefGraphSelection` payload now carries `defaultUomCode` and `defaultUomId`, parsed from `public.type_def.meta.default_uom`.
- When a type is chosen from the browser, `RecipeStepEditor.vue` writes the selected type code into `material_key` and overwrites `uom_code` with the selected type's `defaultUomCode` when present.
- `RecipeStepEditor.vue` now loads `public.mst_uom` and uses dropdown selects for `uom_code` in input materials, output materials, and parameters.
- If a saved `uom_code` is not present in the current `mst_uom` master, the step editor keeps it visible by injecting a temporary option into the select for that row.
- Newly added input-material rows now default `basis` to `per_base` and `consumption_mode` to `estimate`.
- No recipe JSON shape changed; the behavior only affects editor-state defaulting and UOM input controls on the dedicated step page.

## Validation Plan
- Run:
  - `npx eslint src/views/Pages/RecipeStepEditor.vue src/components/type-def/TypeDefGraphModal.vue src/composables/useTypeDefGraphModal.ts --no-fix`
  - `npm run type-check` in `beeradmin_tail`
  - `npm run test` in `beeradmin_tail`
  - `npx eslint . --no-fix` in `beeradmin_tail`

## Validation Results
- `npx eslint src/views/Pages/RecipeStepEditor.vue src/components/type-def/TypeDefGraphModal.vue src/composables/useTypeDefGraphModal.ts --no-fix`: passed
- `npm run type-check` in `beeradmin_tail`: passed
- `npm run test` in `beeradmin_tail`: failed because `beeradmin_tail/package.json` has no `test` script
- `npx eslint . --no-fix` in `beeradmin_tail`: failed on the existing repo-wide ESLint backlog
