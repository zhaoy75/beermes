# Current Task Spec

## Goal
- Align the active recipe-editor source and step-editor specs/docs with the renamed recipe schema fields:
  - `material_key` -> `material_type`
  - `output_code` -> `output_material_type`

## Scope
- Update the active task spec for this schema-alignment task.
- Update the dedicated step-editor spec and UI doc to use the renamed field names.
- Update the active schema SQL source in `DB/dml/registry_def/recipe_body_schema_v1.sql`.
- Update recipe editor source that reads/writes these fields:
  - `RecipeStepEditor.vue`
  - `RecipeEdit.vue`
  - `RecipeMaterialOutputEditor.vue`
- Keep read-side compatibility for older recipe JSON by accepting both the old and new field names during normalization.

## Non-Goals
- Do not change unrelated schema sections.
- Do not change database table definitions.
- Do not rewrite all craft-beer seed SQL in this task.
- Do not redesign the recipe editor UI beyond field-name alignment.

## Affected Files
- [current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [recipe-step-editor-page.md](/Users/zhao/dev/other/beer/specs/recipe-step-editor-page.md)
- [recipe-material-output-editor-page.md](/Users/zhao/dev/other/beer/specs/recipe-material-output-editor-page.md)
- [recipe_step_editor.md](/Users/zhao/dev/other/beer/docs/UI/mes/recipe_step_editor.md)
- [recipe_material_output_editor.md](/Users/zhao/dev/other/beer/docs/UI/mes/recipe_material_output_editor.md)
- [recipe_body_schema_v1.sql](/Users/zhao/dev/other/beer/DB/dml/registry_def/recipe_body_schema_v1.sql)
- [RecipeStepEditor.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RecipeStepEditor.vue)
- [RecipeEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RecipeEdit.vue)
- [RecipeMaterialOutputEditor.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RecipeMaterialOutputEditor.vue)

## Data Model / API Changes
- The active recipe JSON model now uses:
  - `materials.required[]/optional[].material_type`
  - `outputs.*[].output_material_type`
  - `flow.steps[].material_inputs[].material_type`
  - `flow.steps[].material_outputs[].output_material_type`
- Editor source will accept old fields on read:
  - `material_key`
  - `output_code`
- Editor source will write the new fields on save.

## Planned File Changes
- Replace the active task spec with this schema rename task.
- Update the step-editor spec/doc wording to the new field names.
- Update the material/output editor spec/doc wording where fallback field names are described.
- Update the registry schema SQL definitions and required-property lists.
- Update step-editor normalization, row state, template bindings, and save builders.
- Update main recipe editor normalization/display/save logic for top-level materials and outputs.
- Update the dedicated material/output page normalization/display/save logic for top-level materials and outputs.

## Final Decisions
- Active recipe JSON field names are now aligned in the editor source and supporting spec/docs:
  - `materials.required[]/optional[].material_type`
  - `outputs.*[].output_material_type`
  - `flow.steps[].material_inputs[].material_type`
  - `flow.steps[].material_outputs[].output_material_type`
- `RecipeStepEditor.vue`, `RecipeEdit.vue`, and `RecipeMaterialOutputEditor.vue` now write the new field names on save.
- Read-side compatibility for older recipe JSON is preserved by accepting:
  - `material_key` as a fallback for `material_type`
  - `output_code` as a fallback for `output_material_type`
- Output-editor form state in `RecipeEdit.vue` and `RecipeMaterialOutputEditor.vue` was also renamed internally to `output_material_type` so the source matches the current schema terminology.
- Related spec/docs that described fallback material identity were updated from `material_key` to `material_type`.

## Validation Plan
- Run:
  - `npx eslint src/views/Pages/RecipeStepEditor.vue src/views/Pages/RecipeEdit.vue src/views/Pages/RecipeMaterialOutputEditor.vue --no-fix`
  - `npm run type-check` in `beeradmin_tail`
  - `npm run test` in `beeradmin_tail`
  - `npx eslint . --no-fix` in `beeradmin_tail`

## Validation Results
- `npx eslint src/views/Pages/RecipeStepEditor.vue src/views/Pages/RecipeEdit.vue src/views/Pages/RecipeMaterialOutputEditor.vue --no-fix`: passed
- `npm run type-check` in `beeradmin_tail`: passed
- `npm run test` in `beeradmin_tail`: failed because `beeradmin_tail/package.json` has no `test` script
- `npx eslint . --no-fix` in `beeradmin_tail`: failed on the existing repo-wide ESLint backlog outside this task
