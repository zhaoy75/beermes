# Recipe Step Editor Page Spec

## Goal
- Define the dedicated page behavior for editing one recipe flow step outside `RecipeEdit.vue`.

## Route
- `/recipeEdit/:recipeId/:versionId/step/:index?`

## Page Modes
### Create
- route has no `index`
- append one new step into `recipe_body_json.flow.steps`

### Edit
- route has `index`
- load one existing step from `recipe_body_json.flow.steps[index]`
- replace that step on save

## Data Sources
- `mes.mst_recipe`
- `mes.mst_recipe_version`
- `public.recipe_schema_get`

## Page Sections
### 1. Main Information
- source:
  - scalar fields in `flow.steps[]`
- main fields:
  - `step_no`
  - `step_code`
  - `step_name`
  - `step_type`
  - `step_template_code`
  - `duration_sec`
  - `instructions`
  - `notes`

### 2. Input Materials / Output Materials
- sources:
  - `flow.steps[].material_inputs`
  - `flow.steps[].material_outputs`
- input-material editable fields:
  - `material_type`
  - `qty`
  - `uom_code`
  - `basis`
  - `consumption_mode`
  - `notes`
- output-material editable fields:
  - `output_material_type`
  - `output_name`
  - `output_type`
  - `qty`
  - `uom_code`
  - `notes`

### 3. Equipments
- source:
  - `flow.steps[].equipment_requirements`
- editable fields:
  - `equipment_type_code`
  - `equipment_template_code`
  - `quantity`
  - `capability_rules`
  - `notes`

### 4. Parameters
- source:
  - `flow.steps[].parameters`
- editable fields:
  - `parameter_code`
  - `parameter_name`
  - `target`
  - `min`
  - `max`
  - `setpoint`
  - `uom_code`
  - `required`
  - `sampling_frequency`
  - `notes`

### 5. QA
- source:
  - `flow.steps[].quality_checks`
- editable fields:
  - `check_code`
  - `check_name`
  - `sampling_point`
  - `frequency`
  - `required`
  - `acceptance_criteria`
  - `notes`

## Preserved Fields
- Existing step edit must preserve:
  - `hold_constraints`

## Save Behavior
- Update only `mes.mst_recipe_version.recipe_body_json`
- Sort `flow.steps` by `step_no` after save
- Navigate back to `RecipeEdit.vue`
- Save must persist changes from all five sections on the same page

## Validation Rules
- `step_no`
  - integer
  - `>= 1`
- `step_code`
  - required
- `step_name`
  - required

## Step Type Options
- Prefer enum values from loaded schema metadata
- Fall back to:
  - `process`
  - `prep`
  - `transfer`
  - `inspection`
  - `packaging`
  - `other`

## Current Model Notes
- top-level `recipe_body_json.equipment` is not used
- step-level `flow.steps[].equipment_requirements` remains valid
- The dedicated step page owns step-level materials, equipment, parameters, and QA editing
