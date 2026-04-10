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

### Section 4: Flow Steps
- Purpose:
  - maintain `recipe_body_json.flow.steps`

### Section 5: Quality
- Purpose:
  - maintain `recipe_body_json.quality.global_checks`
  - maintain `recipe_body_json.quality.release_criteria`

### Section 6: Documents
- Purpose:
  - maintain `recipe_body_json.documents`

### Section 7: Schema Summary
- Purpose:
  - show schema key, scope, and visible top-level sections

### Section Visibility Control
- Each top-level editor section has a display switch in the section header.
- Supported sections:
  - `Materials`
  - `Outputs`
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

### Dialog / Dedicated Page
- `Global Quality Check Edit`
- `Document Edit`
- dedicated page:
  - `RecipeStepEditor`

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
  - `public.type_def` domain `material_type`
  - `public.entity_attr_set`
  - `public.attr_set`
  - `public.attr_set_rule`
  - `public.attr_def`
  - `public.mst_uom`
- Main fields per row:
  - material
  - material role
  - quantity
  - UOM code
  - basis
  - notes
  - attr-values summary
- Add/edit behavior:
  - add and edit actions open the dedicated recipe item editor page
  - the detail editor is no longer embedded in `RecipeEdit.vue`

### Material / Output Editor Page
- Detailed material and output editing is handled by:
  - [recipe_material_output_editor.md](/Users/zhao/dev/other/beer/docs/UI/mes/recipe_material_output_editor.md)

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
- Add/edit behavior:
  - add and edit actions open the dedicated recipe item editor page

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
- Add/edit behavior:
  - add and edit actions open the dedicated step editor page

### Step Editor Page
- Detailed flow-step editing is handled by:
  - [recipe_step_editor.md](/Users/zhao/dev/other/beer/docs/UI/mes/recipe_step_editor.md)

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
  - material rows may include `attr_values` for selected type-specific attributes

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
  - `public.type_def`
  - `public.entity_attr_set`
  - `public.attr_set`
  - `public.attr_set_rule`
  - `public.attr_def`
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
- Top-level schema sections `outputs`, `quality`, and `documents` now have editable UI sections in addition to schema badges.
- Detailed flow-step editing is documented separately in:
  - [recipe_step_editor.md](/Users/zhao/dev/other/beer/docs/UI/mes/recipe_step_editor.md)
