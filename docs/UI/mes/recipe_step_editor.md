## Purpose
- Edit one recipe flow-step row on a dedicated page.
- Persist the edited step back into `mes.mst_recipe_version.recipe_body_json`.

## Entry Points
- From `レシピ編集` page flow-step grid:
  - add step
  - edit step

## Route
- `/recipeEdit/:recipeId/:versionId/step/:index?`

## Modes
### Create Mode
- route has no `index`
- creates one new `flow.steps[]` row

### Edit Mode
- route has `index`
- edits one existing `flow.steps[]` row

## Layout
### Header
- back to recipe button
- save and return button
- recipe summary
- edit context summary

### Section 1: Main Information
- `step_no`
- `step_type`
- `step_code`
- `step_name`
- `step_template_code`
- `duration_sec`
- `instructions`
- `notes`

### Section 2: Input Materials / Output Materials
- input material editor:
  - `flow.steps[].material_inputs`
- output material editor:
  - `flow.steps[].material_outputs`
- this section edits step-level material consumption and step-level material/output results

### Section 3: Equipments
- array editor for:
  - `flow.steps[].equipment_requirements`
- this section stays step-level only
- it does not reintroduce top-level `recipe_body_json.equipment`

### Section 4: Parameters
- array editor for:
  - `flow.steps[].parameters`

### Section 5: QA
- array editor for:
  - `flow.steps[].quality_checks`

## Data Sources
- `mes.mst_recipe`
- `mes.mst_recipe_version`
- `public.recipe_schema_get`
- `mes.mst_material`
- `public.type_def`
- `public.mst_uom`
- `mes.mst_quality_check`

## Save Behavior
- save updates the target version row in `mes.mst_recipe_version`
- only `recipe_body_json` is updated
- after save:
  - navigate back to `レシピ編集`

## JSON Handling
- target array:
  - `recipe_body_json.flow.steps`
- edited on this page:
  - scalar step fields
  - `material_inputs`
  - `material_outputs`
  - `equipment_requirements`
  - `parameters`
  - `quality_checks`
- preserved on existing-step edit when not explicitly changed:
  - `hold_constraints`

## Validation
- `step_no` must be a positive integer
- `step_code` is required
- `step_name` is required

## Notes
- step-type options use schema enum values when available
- otherwise the page uses fallback step-type options
- top-level `recipe_body_json.equipment` is not part of this page model
- the page is organized into five sections:
  - main information
  - input materials / output materials
  - equipments
  - parameters
  - QA
