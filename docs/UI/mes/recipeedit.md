## Purpose
- Maintain one recipe header and one selected recipe version in the `mes` schema model.
- Edit recipe body content through `mes.mst_recipe_version.recipe_body_json`.
- Load recipe schema from `public.registry_def` through `public.recipe_schema_get`.

## Entry Points
- MES -> Recipe Management -> Recipe List -> open recipe
- Direct route:
  - `/recipeEdit/:recipeId/:versionId`

## Users and Permissions
- Tenant user:
  - can edit recipe header fields
  - can edit recipe version metadata
  - can edit outputs in recipe-body JSON
  - can edit materials in recipe-body JSON
  - can edit default equipment requirements in recipe-body JSON
  - can edit flow steps in recipe-body JSON
  - can edit global quality checks and release criteria in recipe-body JSON
  - can edit document references in recipe-body JSON
  - can version up
- Admin:
  - same as tenant user

## Page Layout
### Section 1: Recipe Header
- Purpose:
  - maintain `mes.mst_recipe`
  - maintain selected `mes.mst_recipe_version`
- Header actions:
  - `Refresh`
  - `Load Schema`
  - `Save`
  - `Version Up`

### Section 2: Materials
- Purpose:
  - maintain `recipe_body_json.materials.required`
  - maintain `recipe_body_json.materials.optional`

### Section 3: Outputs
- Purpose:
  - maintain `recipe_body_json.outputs.primary`
  - maintain `recipe_body_json.outputs.co_products`
  - maintain `recipe_body_json.outputs.waste`

### Section 4: Equipment
- Purpose:
  - maintain `recipe_body_json.equipment.default_requirements`

### Section 5: Flow Steps
- Purpose:
  - maintain `recipe_body_json.flow.steps`

### Section 6: Quality
- Purpose:
  - maintain `recipe_body_json.quality.global_checks`
  - maintain `recipe_body_json.quality.release_criteria`

### Section 7: Documents
- Purpose:
  - maintain `recipe_body_json.documents`

### Section 8: Schema Summary
- Purpose:
  - show schema key, scope, and visible top-level sections

### Section Visibility Control
- Each top-level editor section has a display switch in the section header.
- Supported sections:
  - `Materials`
  - `Outputs`
  - `Equipment`
  - `Flow Steps`
  - `Quality`
  - `Documents`
- When the switch is turned off:
  - the section stays on the page
  - the section body is folded
  - add/edit controls inside the section are hidden
- When the switch is turned on:
  - the section body expands again
- Sections unsupported by the loaded schema remain unavailable and do not render.

### Modal Dialog
- `Material Edit`
- `Output Edit`
- `Equipment Requirement Edit`
- `Step Edit`
- `Global Quality Check Edit`
- `Document Edit`

## Field Definitions
### Recipe Header Fields
- `Recipe Code`
  - bound to `mes.mst_recipe.recipe_code`
  - required
- `Recipe Name`
  - bound to `mes.mst_recipe.recipe_name`
  - required
- `Recipe Category`
  - bound to `mes.mst_recipe.recipe_category`
- `Industry Type`
  - bound to `mes.mst_recipe.industry_type`
- `Recipe Status`
  - bound to `mes.mst_recipe.status`
  - values:
    - `active`
    - `inactive`

### Recipe Version Fields
- `Version`
  - selected from `mes.mst_recipe_version`
- `Version Label`
  - bound to `mes.mst_recipe_version.version_label`
- `Schema Code`
  - bound to `mes.mst_recipe_version.schema_code`
  - required for schema-driven behavior
- `Version Status`
  - bound to `mes.mst_recipe_version.status`
  - values:
    - `draft`
    - `in_review`
    - `approved`
    - `obsolete`
    - `archived`
- `Effective From`
  - bound to `mes.mst_recipe_version.effective_from`
- `Effective To`
  - bound to `mes.mst_recipe_version.effective_to`
- `Change Summary`
  - bound to `mes.mst_recipe_version.change_summary`

### Materials Grid
- Source:
  - `recipe_body_json.materials.required`
  - `recipe_body_json.materials.optional`
- Lookup source for selection:
  - `mes.mst_material`
  - `mes.mst_material_spec`
  - `public.type_def` domain `material_type`
  - `public.mst_uom`
- Main fields per row:
  - material
  - material role
  - quantity
  - UOM code
  - basis
  - notes

### Outputs Grid
- Source:
  - `recipe_body_json.outputs.primary`
  - `recipe_body_json.outputs.co_products`
  - `recipe_body_json.outputs.waste`
- Main fields per row:
  - output code
  - output name
  - output type
  - quantity
  - UOM code
  - basis
  - notes

### Equipment Grid
- Source:
  - `recipe_body_json.equipment.default_requirements`
- Lookup source for selection:
  - `public.type_def` domain `equipment_type`
  - `mes.mst_equipment_template`
- Main fields per row:
  - equipment type code
  - equipment template code
  - quantity
  - capability-rules JSON
  - notes

### Flow Steps Grid
- Source:
  - `recipe_body_json.flow.steps`
- Main fields:
  - `step_no`
  - `step_code`
  - `step_name`
  - `step_type`
  - `duration_sec`
  - parameter count
  - quality-check count

### Step Edit Dialog
- editable fields:
  - `step_no`
  - `step_code`
  - `step_name`
  - `step_type`
  - `step_template_code`
  - `duration_sec`
  - `instructions`
  - `notes`
  - parameters array
  - quality-check array
- preserved fields:
  - material inputs
  - material outputs
  - equipment requirements
  - hold constraints

### Quality Grid
- Source:
  - `recipe_body_json.quality.global_checks`
- Lookup source for selection:
  - `mes.mst_quality_check`
- Main fields per row:
  - check code
  - check name
  - sampling point
  - frequency
  - required flag
  - acceptance-criteria JSON
  - notes
- Release criteria editor:
  - `recipe_body_json.quality.release_criteria`
  - edited as JSON object text

### Documents Grid
- Source:
  - `recipe_body_json.documents`
- Main fields per row:
  - document code
  - document type
  - title
  - revision
  - URL
  - required flag
  - notes

## Actions
### Refresh
- Reload:
  - recipe header
  - recipe version list
  - selected version body
  - schema

### Load Schema
- Call `public.recipe_schema_get(p_def_key)`.
- Use the result to:
  - show schema metadata
  - decide visible section badges
  - derive step-type options when enum metadata exists
  - decide which section switches are available

### Save
- Update `mes.mst_recipe`.
- Update the selected `mes.mst_recipe_version`.
- Persist the current `recipe_body_json`.

### Version Up
- Save current data first.
- Create a new `mes.mst_recipe_version` with:
  - incremented `version_no`
  - status `draft`
  - cloned `recipe_body_json`
- Update `mes.mst_recipe.current_version_id`.
- Navigate to the new version.

### Add Material / Edit Material / Delete Material
- Edit recipe materials directly inside body JSON.
- No separate `mes_ingredients` table is used.

### Add Output / Edit Output / Delete Output
- Edit top-level recipe outputs directly inside body JSON.

### Add Equipment Requirement / Edit Equipment Requirement / Delete Equipment Requirement
- Edit top-level default equipment requirements directly inside body JSON.

### Add Step / Edit Step / Delete Step
- Edit recipe flow steps directly inside body JSON.
- No separate `mes_recipe_steps` table is used.

### Add Global Quality Check / Edit Global Quality Check / Delete Global Quality Check
- Edit top-level global quality checks directly inside body JSON.

### Apply Release Criteria
- Validate release criteria JSON and keep it in `recipe_body_json.quality.release_criteria`.

### Add Document / Edit Document / Delete Document
- Edit document references directly inside body JSON.

## Business Rules
- Source of truth is:
  - `mes.mst_recipe`
  - `mes.mst_recipe_version`
  - `mes.mst_recipe_version.recipe_body_json`
- The page does not depend on:
  - `public.mes_recipes`
  - `mes_ingredients`
  - `public.mst_materials`
  - `public.mst_category`
- Materials and steps are JSON-body structures, not relational child tables.
- Schema remains registry-managed configuration loaded by RPC.
- The page may use fallback step-type options when the schema does not define machine-readable enums.
- Section display on/off is UI state only. It folds or expands the editor section and does not delete recipe-body JSON data.

## Data Handling
- Recipe header:
  - `mes.mst_recipe`
- Recipe version:
  - `mes.mst_recipe_version`
- Schema:
  - `public.recipe_schema_get(p_def_key)`
- Material lookup:
  - `mes.mst_material`
  - `mes.mst_material_spec`
  - `public.type_def`
  - `public.mst_uom`

## JSON Handling
- `recipe_body_json.materials.required`
  - array of required material requirement objects
- `recipe_body_json.materials.optional`
  - array of optional material requirement objects
- `recipe_body_json.outputs.primary`
  - array of primary output objects
- `recipe_body_json.outputs.co_products`
  - array of co-product output objects
- `recipe_body_json.outputs.waste`
  - array of waste output objects
- `recipe_body_json.equipment.default_requirements`
  - array of default equipment requirement objects
- `recipe_body_json.flow.steps`
  - array of flow-step objects
- `recipe_body_json.quality.global_checks`
  - array of global quality-check objects
- `recipe_body_json.quality.release_criteria`
  - JSON object
- `recipe_body_json.documents`
  - array of document-reference objects
- step parameters
  - stored in `flow.steps[].parameters`
- quality checks
  - stored in `flow.steps[].quality_checks`

## Notes
- This page is already aligned to the `mes` schema model rather than the deleted legacy recipe tables.
- Top-level schema sections `outputs`, `equipment`, `quality`, and `documents` now have editable UI sections in addition to schema badges.
