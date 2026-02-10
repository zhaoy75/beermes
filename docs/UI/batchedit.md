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
- There are 5 sections
  1. basic information
  2. batch relation (new)
  3. material information (not needed in this phase)
  4. step edit (not needed in this phase)
  5. filling 


  
### Modal Dialog
-  material input dialog
-  beer_tax_move dialog
-  batch relation dialog (new)


## Field Definitions
### basic information section 
    バッチ名
    ステータス
    予定開始日  with calendar picker
    予定終了日  with calendar picker
    実績開始日　with calendar picker
　　 実績終了日  with calendar picker
    
    a horizontal line 
      fields in entity_attr_set in domain "batch". 
        field name should be choose according to system language setting
        field text and input method should follow the attr_def rule
  　 
### batch relation section (new)
    purpose: manage lineage between batches (mes_batch_relation)
    layout:
      - table list of relations for current batch
      - toolbar: Add Relation, Edit, Delete
    table columns:
      - relation_type (enum: split / merge / blend / rework / repackage / dilution / transfer)
      - src_batch (batch code)
      - dst_batch (batch code)
      - quantity
      - uom
      - ratio
      - effective_at (datetime)
    rules:
      - src_batch_id and dst_batch_id cannot be the same
      - if current batch is the edited batch:
          - show relations where current batch is src or dst
      - quantity optional, ratio optional (both can be null)
      - uom required when quantity is set
      - effective_at default now

### batch relation dialog (new)
    fields:
      - relation_type (select enum)
      - src_batch (batch selector)
      - dst_batch (batch selector)
      - quantity (numeric)
      - uom (select from mst_uom)
      - ratio (numeric)
      - effective_at (datetime picker)
    actions:
      - Save
      - Cancel

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
- batch relation stored in mes_batch_relation

## other
- this page should be multilanguage (english and japanese)
