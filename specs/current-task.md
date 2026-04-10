# Current Task Spec

## Goal
- Make the `RecipeStepEditor.vue` main-information layout more compact so the core step fields fit in a denser, faster-to-scan arrangement.

## Scope
- Update the active task spec for this UI layout change.
- Update the dedicated step-editor spec and UI doc to describe the compact main-information arrangement.
- Update only the main-information section layout in `RecipeStepEditor.vue`.

## Non-Goals
- Do not change the recipe JSON model.
- Do not change materials, equipments, parameters, or QA sections.
- Do not change validation rules or save behavior.
- Do not redesign the page header or route summary cards in this task.

## Affected Files
- [current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [recipe-step-editor-page.md](/Users/zhao/dev/other/beer/specs/recipe-step-editor-page.md)
- [recipe_step_editor.md](/Users/zhao/dev/other/beer/docs/UI/mes/recipe_step_editor.md)
- [RecipeStepEditor.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/RecipeStepEditor.vue)

## Data Model / API Changes
- No data model or API changes.

## Planned File Changes
- Replace the active task spec with this compact-layout task.
- Update the step-editor spec/doc to state that Section 1 uses a denser multi-column form layout.
- Reduce spacing in the main-information block and place scalar fields into more columns.
- Place `instructions` and `notes` side by side on wide screens while keeping them stacked on narrow screens.

## Final Decisions
- Section 1 of `RecipeStepEditor.vue` now uses a denser desktop grid instead of the previous loose two-column form.
- `step_no`, `step_type`, `step_code`, `step_name`, `step_template_code`, and `duration_sec` are arranged in a compact multi-column layout.
- `instructions` and `notes` now sit side by side on wider screens and remain stacked on narrow screens.
- The change is layout-only; no step data fields, validation rules, or save behavior changed.

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
