## Purpose
- Edit one recipe raw-material row or one recipe output row on a dedicated page.
- Persist the edited item back into `mes.mst_recipe_version.recipe_body_json`.

## Entry Points
- From `レシピ編集` page material grid:
  - add raw material
  - edit raw material
- From `レシピ編集` page output grids:
  - add output
  - edit output

## Route
- `/recipeEdit/:recipeId/:versionId/item/:kind/:section/:index?`

## Modes
### Material Mode
- `kind = material`
- supports:
  - create
  - edit
- supported sections:
  - `required`
  - `optional`

### Output Mode
- `kind = output`
- supports:
  - create
  - edit
- supported sections:
  - `primary`
  - `co_products`
  - `waste`

## Layout
### Header
- back to recipe button
- save and return button
- recipe summary
- edit context summary

### Material Mode Layout
- left pane:
  - `RAW_MATERIAL` subtree from `public.type_def`
  - filtered `mes.mst_material` source list
- right pane:
  - recipe material fields
  - type-specific dynamic fields
  - all attribute inputs are optional during recipe editing
  - master material selection is optional during recipe editing

### Output Mode Layout
- single editor pane for one output row

## Data Sources
### Shared
- `mes.mst_recipe`
- `mes.mst_recipe_version`
- `public.mst_uom`

### Material Mode
- `mes.mst_material`
- `public.type_def` where `domain = 'material_type'`
- `public.entity_attr_set`
- `public.attr_set`
- `public.attr_set_rule`
- `public.attr_def`

## Save Behavior
- save updates the target version row in `mes.mst_recipe_version`
- only `recipe_body_json` is updated
- after save:
  - navigate back to `レシピ編集`

## Material JSON Handling
- target arrays:
  - `recipe_body_json.materials.required`
  - `recipe_body_json.materials.optional`
- dynamic values are stored in:
  - `attr_values`
- empty attribute inputs do not block save on this page
- if no master material is selected, the page writes a fallback `material_type` from recipe-entered data so the row can still be saved

## Output JSON Handling
- target arrays:
  - `recipe_body_json.outputs.primary`
  - `recipe_body_json.outputs.co_products`
  - `recipe_body_json.outputs.waste`
