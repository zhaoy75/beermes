製品ビール移出登録 Dialog UI Specification (Dynamic Rules)
=================================================

## Purpose
This specification defines the UI flow for 製品ビール移出登録 (Tax Removal Register).
The UI must get rules from server call and never hardcode movement intents, tax decisions, or site type mappings.

Key principles:
- Movement intent is chosen first.
- Site types and default tax are derived by the system from the rules file.
- Product/Lot selection can change tax results when multiple candidates exist.
- Final confirmation must explain derived tax event and rule source.

## Entry Point
- ProducedBeer page -> button: "製品ビール移出登録" (Tax Removal Register...)

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
Step 1: Select movement_intent(移出目的)
--------------------------------------------------
UI:
- List movement intents 

System behavior:
- movement_get_movement_UI_intent
- list the movement intents in return json

--------------------------------------------------
Step 2: Select src/dst site（移出元先酒税情報入力）
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
Step 3: Select lot　（移出商品選択）
--------------------------------------------------
UI:
- Keep the current Step 3 layout and row/grid style used by the existing page.
- The UI must not switch to a different dialog/page layout for return / put-back intents.
- When source stock exists in `inv_inventory`, Step 3 may still resolve rows from inventory.
- When `movement_intent = RETURN_FROM_CUSTOMER` and source stock does not exist in `inv_inventory`, Step 3 must switch to lot lookup mode while keeping the same visual structure.
- In lot lookup mode:
  - user inputs `lot no` in the existing row UI
  - type-ahead / suggestion list should be shown while typing
  - selected lot populates row display fields using lot/batch/package master data
  - the row should continue to show the same information area as the current page
    - lot code
    - ビール分類
    - 目標ABV
    - スタイル名
    - batch code
    - package volume
    - package uom
    - quantity
    - removal quantity (for input)
- If the selected lot has package information:
  - system shows package info automatically
  - user inputs package unit count
  - system derives volume
- If the selected lot does not have package information:
  - user inputs volume directly
- Row-level validation and inline error style must remain consistent with the current page UX.
- If multiple lots have different `lot_tax_type`, show tax preview changes.

System behavior:
- find `src_lot_tax_type` from selected lot.
- If multiple candidates change tax event, highlight options.
- In lot lookup mode, the system must resolve lot candidate data from lot-oriented sources, not only from `inv_inventory`.
- Suggested source data for lot lookup mode:
  - `lot`
  - batch / product master data
  - package master data
  - movement / lot linkage needed to determine returnable quantity
- After lot selection, the system should determine:
  - product / style display data
  - package metadata
  - allowable return quantity
  - whether unit-entry or volume-entry is required
- The system must validate that:
  - lot exists
  - lot is eligible for the selected movement intent
  - entered unit count is numeric and within allowable range
  - derived / entered volume is valid
  - lot/package combination is consistent
- For `RETURN_FROM_CUSTOMER`, allowable quantity must be validated from the source lot balance even when source `inv_inventory` does not exist, because customer-side sites are non-inventory-ledger sites.
- If multiple matching lots exist for the entered lot code, the user must select one explicitly from suggestions.

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
- rpc payload should include `unit` when package unit count is known for the selected move line
- rpc payload must not include `tax_rate`
- `tax_rate` is derived inside `public.product_move` by:
  - setting `0` for non-taxable movements
  - only when derived `tax_event = 'TAXABLE_REMOVAL'`:
    - resolving beer category from batch attr `beer_category`
    - resolving `registry_def.kind = 'alcohol_type'` to get `tax_category_code`
    - calling `public.get_current_tax_rate(tax_category_code, movement_at::date)`


--------------------------------------------------
Notes
--------------------------------------------------
- UI must re-evaluate tax event when any of steps 1-3 change.
- If rule changes invalidate current selection, prompt user to reselect.
- the page should be multi-languaged
