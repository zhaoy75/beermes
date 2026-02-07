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
  　
### material information section (not shown no needed in this phase)
    
### step edit section (not shown no needed in this phase)

### filling section
    a summary of move and filling information
    a button to edit filling information (a click will launch packageing dialog)
    the packaging dialog should follow the specification defined in batch_packing.md

## Action


## Business Rules

## Data Handling
- batch basic information stored in mes_batches
- other attribute stored in entity_attr
- 

## other
- this page should be multilanguage (english and japanese)