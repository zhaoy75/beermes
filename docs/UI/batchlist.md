## Purpose
- Search batch, Show list of batch important information
- Please Entry Points for add, edit, delete batch


## Entry Points
- 製造管理 -> バッチ管理

## Users and Permissions
- Admin: edit and delete batch of all states
- Tenant User: can not delete in in_progress and completed status

## Page Layout
### Header: バッチ管理
- Title: バッチ管理
- Button: バッチ作成、検索

### Body: 
- There are two section
  1. search section
  2. バッチリスト
  
### Modal Dialog
-  Batch Add Dialog

## Field Definitions
### search section
    search field should include:
      バッチ名
      ステータス
      開始日  with calendar picker
      終了日  with calendar picker
      a horizontal line 
      fields in entity_attr_set in domain "batch". 
        field name should be choose according to system language setting
        field text and input method should follow the attr_def rule
  　
### バッチリスト
    a list columns include the same fields in search section and a 操作 column with edit & delete button 

### Batch Add Dialog
    Modal dialog to let user input 
      レシピ (optional, only shown when development mode is on)
      バッチ名 (should not to be blank)
      開始日  with calendar picker
      終了日  with calendar picker
      fields from entity_attr_set in domain "batch" (all optional at create time)
    A cancel and confirm button 
    

## Action
- Search

- Add
  A Batch Add dialog will shown to let user input related field.
  recipe selection is optional and should read from `mes.mst_recipe`
  recipe selection is hidden when `VITE_DEVELOPMENT_MODE` is off because recipe functions are still under development
  when selected, current released version should be derived from `mes.mst_recipe.current_version_id`
  when not selected, batch header only is created
  after user fill the form and click confirm button, call create_batch_from_recipe
  active batch attribute fields should be shown and saved to `entity_attr` after the batch is created
  at create time, do not force any batch attribute as required

- Edit
  move to batchedit page

- Delete
  check the status of batch
   if status is in_progress or complete show error message window. 
   other status, delete the db record
   
## Business Rules
- default value of search section
  開始日 should be two months previous
- normal user can not delete batch whose status is in_progress or completed

## Data Handling
- batch basic information stored in mes_batches
- selected recipe source:
  - `mes.mst_recipe`
  - `mes.mst_recipe_version`
- batch release function expands `mes.mst_recipe_version.recipe_body_json` into:
  - `mes.batch_step`
  - `mes.batch_material_plan`
- other attribute stored in entity_attr
- batch create attribute fields:
  - read active `attr_set`, `attr_set_rule`, and `attr_def` rows for domain `batch`
  - assign batch attr sets to `entity_attr_set`
  - save non-empty values to `entity_attr`

## other
- this page should be multilanguage (english and japanese)
