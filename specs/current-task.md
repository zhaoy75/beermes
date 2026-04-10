# Current Task Spec

## Goal
- Align `RecipeStepEditor.vue` Section 2 with the updated UI doc so output-material rows use the same type-browser flow as input-material rows, and `output_name` is auto-filled from the selected `type_def` name.

## Scope
- Update the active task spec for this behavior change.
- Update the dedicated step-editor spec to describe the output-material browser flow and `output_name` autofill behavior.
- Update only Section 2 behavior in `RecipeStepEditor.vue`.

## Non-Goals
- Do not change the recipe JSON model.
- Do not change equipments, parameters, or QA sections.
- Do not change validation rules or save behavior.
- Do not redesign unrelated page layout in this task.

## Affected Files
- [current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [recipe-step-editor-page.md](/Users/zhao/dev/other/beer/specs/recipe-step-editor-page.md)
- [recipe_step_editor.md](/Users/zhao/dev/other/beer/docs/UI/mes/recipe_step_editor.md)
- [RecipeStepEditor.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RecipeStepEditor.vue)

## Data Model / API Changes
- No data model or API changes.

## Planned File Changes
- Replace the active task spec with this output-material browser task.
- Update the step-editor spec/doc so Section 2 documents separate `material_inputs` and `material_outputs` browser behavior.
- Add refs/focus handlers for `output_material_type` inputs.
- Open the shared type browser when a new output-material row is added and its type field gains focus.
- Copy the selected type code into `output_material_type`.
- Copy the selected type display name into `output_name`.
- Copy `type_def.meta.default_uom` into the output row when present.

## Final Decisions
- Output-material type selection now also fills `output_name` from the selected `type_def` display name.
- `output_material_type` continues to receive the selected `type_def.code`.
- When the selected type carries `type_def.meta.default_uom`, the output row `uom_code` is still filled from that default.
- The change is limited to `RecipeStepEditor.vue` Section 2 behavior; no recipe JSON shape or save mapping changed.

## Validation Plan
- Run:
  - `npx eslint src/views/Pages/RecipeStepEditor.vue --no-fix`
  - `npm run type-check` in `beeradmin_tail`
  - `npm run test` in `beeradmin_tail`
  - `npx eslint . --no-fix` in `beeradmin_tail`

## Validation Results
- `npx eslint src/views/Pages/RecipeStepEditor.vue --no-fix`: passed
- `npm run type-check` in `beeradmin_tail`: passed
- `npm run test` in `beeradmin_tail`: failed because `beeradmin_tail/package.json` has no `test` script
- `npx eslint . --no-fix` in `beeradmin_tail`: failed on the existing repo-wide ESLint backlog outside this task
