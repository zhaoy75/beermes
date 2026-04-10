## Purpose
- Search, browse, create, copy, open, and delete recipes using the `mes` schema recipe master model.
- Show either the current version per recipe or every version row.
- Resolve the effective schema key before creating or copying a recipe.

## Entry Points
- MES -> Recipe Management -> Recipe List

## Users and Permissions
- Tenant user:
  - can browse recipe headers and versions
  - can create a new recipe
  - can copy a selected recipe version into a new recipe
  - can open recipe edit
  - can delete a recipe header if backend policy allows it
- Admin:
  - same as tenant user

## Page Layout
### Header
- Title: `Recipe List`
- Actions:
  - `New`
  - `Refresh`
  - `Reset`

### Search Section
- Fields:
  - keyword
  - category
  - industry
  - version status
  - show all versions

### List Section
- Desktop:
  - table
- Mobile:
  - card list

### Modal Dialog
- `New Recipe`
- `Copy Recipe`
- `Delete Confirmation`

## Field Definitions
### Search Fields
- `Keyword`
  - target fields:
    - `mes.mst_recipe.recipe_code`
    - `mes.mst_recipe.recipe_name`
- `Category`
  - source:
    - distinct values from `mes.mst_recipe.recipe_category`
- `Industry`
  - source:
    - distinct values from `mes.mst_recipe.industry_type`
- `Version Status`
  - values:
    - `draft`
    - `in_review`
    - `approved`
    - `obsolete`
    - `archived`
- `Show All Versions`
  - unchecked:
    - show one row per recipe using `current_version_id` when available
  - checked:
    - show every `mst_recipe_version` row

### List Columns
- `Recipe Code`
  - from `mes.mst_recipe.recipe_code`
- `Recipe Name`
  - from `mes.mst_recipe.recipe_name`
  - clickable to open recipe edit
- `Version`
  - from `mes.mst_recipe_version.version_no`
- `Version Status`
  - from `mes.mst_recipe_version.status`
- `Recipe Status`
  - from `mes.mst_recipe.status`
- `Category`
  - from `mes.mst_recipe.recipe_category`
- `Industry`
  - from `mes.mst_recipe.industry_type`
- `Schema`
  - from `mes.mst_recipe_version.schema_code`
  - fallback:
    - `recipe_body_v1`
- `Updated`
  - from recipe-version `updated_at`
  - fallback to recipe-header update time
- `Actions`
  - `Copy`
  - `Delete`

### New Recipe Dialog
- Fields:
  - `Recipe Code` required
  - `Recipe Name` required
  - `Recipe Category` optional
  - `Industry Type` optional
  - `Schema Key` required
- Save behavior:
  - create `mes.mst_recipe`
  - create initial `mes.mst_recipe_version`
  - set `mes.mst_recipe.current_version_id`

### Copy Recipe Dialog
- Fields:
  - `Recipe Code` required
  - `Recipe Name` required
  - `Recipe Category` optional
  - `Industry Type` optional
  - `Schema Key` required
- Save behavior:
  - create a new recipe header
  - clone the selected source version body into version `1`
  - set the new header `current_version_id`

## Actions
### Refresh
- Reload:
  - `mes.mst_recipe`
  - `mes.mst_recipe_version`

### New
- Validate the schema key through `public.recipe_schema_get`.
- Create recipe header and initial version.
- Navigate to:
  - `/recipeEdit/:recipeId/:versionId`

### Open
- Open the selected recipe/version row.
- Pass `schemaKey` in route query for immediate schema loading.

### Copy
- Copy the selected version body into a new recipe/version pair.

### Delete
- Delete the recipe header from `mes.mst_recipe`.
- Recipe versions follow FK cascade rules.

## Business Rules
- Recipe list source of truth is:
  - `mes.mst_recipe`
  - `mes.mst_recipe_version`
- The page does not depend on:
  - `public.mes_recipes`
  - `mes_ingredients`
  - `public.mst_materials`
  - `public.mst_category`
- New recipes start as:
  - recipe status `active`
  - version status `draft`
  - version number `1`
- Schema selection belongs to registry-managed configuration in `registry_def`.

## Data Handling
- Recipe header:
  - `mes.mst_recipe`
- Recipe versions:
  - `mes.mst_recipe_version`
- Schema retrieval:
  - `public.recipe_schema_get(p_def_key)`
- Initial recipe body:
  - written to `mes.mst_recipe_version.recipe_body_json`

## Notes
- This page is intentionally lightweight.
- Detailed editing of materials and flow steps belongs to the recipe edit page.
