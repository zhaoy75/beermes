製品ビール移動登録 Dialog UI Specification (Dynamic Rules)
=================================================

## Purpose
This specification defines the UI flow for 製品ビール移動登録 (Tax Movement Register).
The UI must get rules from server call and never hardcode movement intents, tax decisions, or site type mappings.

Key principles:
- Movement intent is chosen first.
- Site types and default tax are derived by the system from the rules file.
- Product/Lot selection can change tax results when multiple candidates exist.
- Final confirmation must explain derived tax event and rule source.

## Entry Point
- ProducedBeer page -> button: "製品ビール移動登録" (Tax Movement Regist...)

## Rule Source (Dynamic)
- Rules are stored in - Table: `public.registry_def`
  - Selector:
    - `kind = 'ruleengine'`
    - `def_key = 'beer_movement_rule'`
    - `is_active = true`
- UI will call rpc to 
    -  movement_get_movement_UI_intent to get movement_list shown in UI
    -  movement_get_rules to get rules for the movement intent
- UI must load and interpret rules:
    - enums with lables
    - `movement_intent_rules`
    - `tax_decision_definitions`
    - `tax_transformation_rules`
    - `enums` (movement_intent, site_type, lot_tax_type, tax_event, tax_decision_code)

## Terminology
- movement_intent: user-selected business intent
- src/dst site_type: derived from selected sites
- tax decision code: a rule-specific decision (optional)
- tax event: derived final tax event shown in confirmation

## Flow Overview (Wizard)
Step 1 → movement_intent  
Step 2 → select src/dst site (system derives site_type + default tax)  
Step 3 → select product/lot (tax may be adjusted if multiple candidates)  
Step 4 → fill necessary information  
Step 5 → confirmation

--------------------------------------------------
Step 1: Select movement_intent(移動目的)
--------------------------------------------------
UI:
- List movement intents 

System behavior:
- movement_get_movement_UI_intent
- list the movement intents in return json

--------------------------------------------------
Step 2: Select src/dst site（移動元先酒税情報入力）
--------------------------------------------------
UI:
- Select Source Site (required)
  - select source site type (dropdown list including allowed site types got from step 1)
  - select source site (dropdown list)
  - source site name should be shown as the label (get from movement_get_rules) 

- Select Destination Site (required if `dst_required=true`)
  - select destination site type (dropdown list including allowed site types got from step 1)
  - select destination site (dropdown list)
  - destination site name should be shown as the label (get from movement_get_rules) 

- Tax Decision Code 
  - set default Tax Decision Code from tax_transformation_rules based on movement_intent, src site type and dst site type
  - if user want to choose other allowed_tax_decision. user need to input reason 
  - decision code should be shown as the label (get from movement_get_rules) 

System behavior:
- call movement_get_rules to get rules for the movement intent which user input in Step 1
- Compute default tax decision code (if rule requires a decision).
- Preview derived tax event using `tax_transformation_rules`.

--------------------------------------------------
Step 3: Select lot　（移動商品選択）
--------------------------------------------------
UI:
- Select Lot(s) from inventory (inv_inventory) for Source Site
  - lot code
  - ビール分類
  - 目標ABV
  - スタイル名
  - batch code
  - package volume
  - package uom
  - quantity
  - movement quantity (for input)
- If multiple lots have different `lot_tax_type`, show tax preview changes.

System behavior:
- find `src_lot_tax_type` from selected lot.
- If multiple candidates change tax event, highlight options.

--------------------------------------------------
Step 4: Fill necessary information（詳細情報入力）
--------------------------------------------------
UI:
- Unit Price (単価)
- Price（価格）
- Reason or evidence fields (conditional by rule)
- Notes (摘要)

System behavior:
- Validate required fields per selected rule.
- Ensure quantities and UOM are consistent.

--------------------------------------------------
Step 5: Confirmation
--------------------------------------------------
UI shows:
- movement_intent label
- src/dst site + derived site_type
- selected product/lot
- derived tax decision code + tax event
- selected rule id(s) used for decision

Actions:
- Post (requires validation)

--------------------------------------------------
Validation Rules (Dynamic)
--------------------------------------------------
- movement_intent must be selected.^[]
- src/dst site types must match rule.
- lot requirements follow `line_rules`:
  - require_src_lot
  - require_dst_lot_or_new_lot
  - allow_new_lot
  - allow_same_lot
- tax decision code must be selected when multiple options exist.

--------------------------------------------------
Data Handling
--------------------------------------------------
when Post button is clicked, call rpc public.product_move


--------------------------------------------------
Notes
--------------------------------------------------
- UI must re-evaluate tax event when any of steps 1-3 change.
- If rule changes invalidate current selection, prompt user to reselect.
- the page should be multi-languaged
