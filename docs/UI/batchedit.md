## Purpose
- Edit batch basic and additional industry (stored in entity_attr_set) information
- Please Entry Points for add, edit, delete batch


## Entry Points
- 製造管理 -> バッチ管理　→　編集
- 製造管理 -> バッチ管理　→　追加 -> 作成

## Users and Permissions
- Tenant User: edit all batch information

## Page Layout
### Header: バッチ管理
- Title: バッチ編集

### Body: 
- There are 4 sections
  1. basic information
  2. material information (not needed in this phase)
  3. step edit (not needed in this phase)
  4. filling 
  
### Modal Dialog
-  material input dialog
-  beer_tax_move dialog


## Field Definitions
### basic information section 
    バッチ名
    ステータス
    予定開始日  with calendar picker
    予定終了日  with calendar picker
    実績開始日　with calendar picker
　　 実績終了日  with calendar picker
    関連バッチ　with batch code list 
    a horizontal line 
    fields in entity_attr_set in domain "batch". 
      field name should be choose according to system language setting
      field text and input method should follow the attr_def rule
  　
### material information section (not needed in this phase)
    
### step edit section (not needed in this phase)

### filling section
    a summary of move and filling information
    a button to edit filling information (a click will launch beer_tax_move dialog)
    a list of all move information of this batch (to be design)

## Action
- Search

- Add
  A Batch Add dialog will shown to let user input related field.
  after user fill the form and click confirm button, call create_batch_from_recipe

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
- other attribute stored in entity_attr

## other
- this page should be multilanguage (english and japanese)