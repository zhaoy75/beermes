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
  2. material information (not needed in this phase)
  3. step edit (not needed in this phase)
  4. filling 


  
### Modal Dialog
-  material input dialog
-  beer_tax_move dialog
-  batch relation dialog
-  batch actual yield dialog (new)
-  lot dag dialog (new)

### Navigation
- Batch Packing button (移送詰口管理): navigate to Batch Packing page for current batch


## Field Definitions
### basic information section 
    バッチコード
    ステータス
    product_name 
	　actual_yield 
	  actual_yield_uom dropdown list from uom with domain volume
    予定開始日  with calendar picker
    予定終了日  with calendar picker
    実績開始日　with calendar picker
　　 実績終了日  with calendar picker
    
    a horizontal line 
      fields in entity_attr_set in domain "batch". 
        field name should be choose according to system language setting
        field text and input method should follow the attr_def rule

    a horizontal line 
      batch relation list 
      #if there is no related with current batch show "nothing exist"       
  　 
### batch relation list 
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
    a button to edit filling information (a click will move to packing page, not launch a dialog)
    add a "Lot DAG" button at the left side of 移送詰口管理 button
    if click "Lot DAG" button, show lot dag dialog for current batch
    lot dag dialog data should be retrieved by rpc:
      - function: public.lot_dag_get_by_batch
      - parameter: p_batch_id = current batch id
    the packing page should follow the specification defined in batchpacking.md
    for filling (詰口) save, UI must call stored function public.product_filling(p_doc jsonb)
    source lot for filling should be resolved by calling rpc:
      - function: public.get_packing_source_lotid
      - parameter: p_batch_id = current batch id
    source site id should be resolved by source lot
    destination site id should be retrieved from destination site id input by user
    use returned source_lot_id as from_lot_id in product_filling payload
    if not found, show error: product_produce must be executed first

## Action
    - add a button to input actual yield, when the button is click, show the input actual yield and uom (select from mst_uom by volume) and site (select form mst_sites).
    - when 　actual yield is saved, please update the total product volume in filling section and call stored function product_produce.

## Business Rules
  ・
  ・


## Data Handling
- batch basic information stored in mes_batches
- other attribute stored in entity_attr
- batch relation stored in mes_batch_relation

## other
- this page should be multilanguage (english and japanese)
