## Purpose
- Enter and update batch actual results and additional industry attributes (stored in `entity_attr_set`)
- Manage batch relation and navigate to filling / packing workflow
- Show released recipe information and batch execution status without breaking current operational flows


## Entry Points
- 製造管理 -> バッチ管理　→　編集
- 製造管理 -> バッチ管理　→　追加 -> 作成

## Users and Permissions
- Tenant User: edit all batch information

## Page Layout
### Header: バッチ管理
- Title: バッチ実績入力

### Body: 
- There are 4 sections
  1. basic information
  2. step execution
  3. filling
  4. batch relation


  
### Modal Dialog
-  material input dialog
-  beer_tax_move dialog
-  batch relation dialog
-  batch actual yield dialog (new)

### Navigation
- Batch Packing button (移送詰口管理): navigate to Batch Packing page for current batch


## Field Definitions
### basic information section 
    バッチコード
      editable
      required
      saved to `mes_batches.batch_code`
      duplicate values are allowed; `mes_batches.id` remains the canonical identifier
    ステータス
    product_name 
	　actual_yield 
      can only be input when batch status is 製造中 or 完了
      must be greater than 0 and must not exceed 1000000
	  actual_yield_uom dropdown list from uom with domain volume
      actual_yield site dropdown list from mst_sites
        only sites with site_type = BREWERY_MANUFACTUR can be shown and selected
    予定開始日  with calendar picker
    予定終了日  with calendar picker
    実績開始日　with calendar picker
　　 実績終了日  with calendar picker
    
    a horizontal line 
      fields in entity_attr_set in domain "batch". 
        field name should be choose according to system language setting
        field text and input method should follow the attr_def rule
        save-time validation for entered values must follow attr_def conditions:
          - num_min / num_max
          - text_regex
          - allowed_values
        if any entered batch attribute is invalid, batch save must be blocked and the field error must be shown inline
        required / non-null batch attributes are not forced on ordinary batch save, but must be completed before actual yield entry

    a horizontal line 
      released recipe information
        read-only
        use `mes_batches.released_reference_json`, `mes_batches.recipe_json`, `mes_batches.mes_recipe_id`, `mes_batches.recipe_version_id`
        place this as a simple inline row inside basic information section, not as a block or dedicated page section
        show only current recipe link and version summary
        if `mes_recipe_id` and `recipe_version_id` exist, clicking the link should move to `/recipeEdit/:recipeId/:versionId`
        do not show recipe description, base quantity, output summary, or recipe version id
        if no recipe is attached, show explicit empty state

    a horizontal line
      step execution section header should contain compact execution summary
        batch status
        progress
        current step
        open deviation count
      do not show a dedicated large execution summary block
      source should be `mes.batch_step` and related execution tables
      state machine is not executed on this page
      when a step is completed or skipped on 工程実行 page, this page only reflects the updated step statuses

    compatibility note
      actual_yield dialog and save flow must remain unchanged while the new sections are added
  　 
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
      - if there is no relation record, hide this section on batch edit page
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
    this is replaced by read-only execution status / step execution visibility
    batch page does not edit recipe steps
    batch page shows released execution-side steps
    step detail should not open in a drawer
    clicking a step row or 詳細 button should move to dedicated page `/batches/:batchId/step/:stepId`

### filling section
    a summary of move and filling information
    a button to edit filling information (a click will move to packing page, not launch a dialog)
    the filling summary table on this page is read-only for editing; do not show a row-level 編集 button
    keep row-level deletion only when deletion is allowed by the current implementation
    add a "Lot DAG" button at the left side of 移送詰口管理 button
    if click "Lot DAG" button, move to lot dag page for current batch
    lot dag page data should be retrieved by rpc:
      - function: public.lot_dag_get_by_batch
      - parameter: p_batch_id = current batch id
    lot dag page should follow the specification defined in batchlotdag.md
    the packing page should follow the specification defined in batchpacking.md
    for filling (詰口) save, UI must call stored function public.product_filling(p_doc jsonb)
    source lot for filling should be resolved by calling rpc:
      - function: public.get_packing_source_lotid
      - parameter: p_batch_id = current batch id
    source site id should be resolved by source lot
    destination site id should be retrieved from destination site id input by user
    use returned source_lot_id as from_lot_id in product_filling payload
    if not found, show error: product_produce must be executed first
    this section must continue to work even when batch has no base recipe
    this section must not be replaced by step execution UI

## Action
    - add a button to input actual yield, when the button is click, show actual yield, uom (select from mst_uom by volume), and site.
    - actual yield site must be selected from `mst_sites`, but only `BREWERY_MANUFACTUR` sites are allowed.
    - if existing batch meta has non-manufacturing site id, do not auto-select it in the dialog.
    - when actual yield is saved, update the total product volume in filling section and call stored function `product_produce`.
    - before opening or saving actual yield, all required batch attributes from `entity_attr_set` / `attr_def` must be entered.
    - actual yield save must persist current batch attributes to `entity_attr` before calling `product_produce`.
    - if a non-`BREWERY_MANUFACTUR` site is submitted, show validation error and do not save.
    - redesign of batch page must keep this actual_yield operation intact

## Business Rules
  - Batch actual yield entry is for manufacturing result entry.
  - Manufacturing site for actual yield must be `BREWERY_MANUFACTUR`.
  - Stored function `product_produce` is the server-side source of truth and must reject non-manufacturing destination sites.
  - Batch attribute values stored in `entity_attr` must be validated against the linked `attr_def` conditions before save when a value is entered.
  - Missing / blank `entity_attr` values on Batch Edit do not block ordinary batch save.
  - Missing / blank required `entity_attr` values block `実績生産量を入力` and actual-yield save.


## Data Handling
- batch basic information stored in mes_batches
- other attribute stored in entity_attr
- batch relation stored in mes_batch_relation
- released recipe snapshot stored in `mes_batches.recipe_json` and `mes_batches.released_reference_json`
- execution status stored in `mes.batch_step` and related execution tables

## other
- this page should be multilanguage (english and japanese)
