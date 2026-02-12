酒税関連登録 Dialog UI Specification (Dynamic Rules)
=================================================

## Purpose
This specification defines the UI flow for 酒税関連登録 (Tax Movement Register).
The UI must read rules dynamically from `docs/data/movementrule.jsonc` and never
hardcode movement intents, tax decisions, or site type mappings.

Key principles:
- Movement intent is chosen first.
- Site types and default tax are derived by the system from the rules file.
- Product/Lot selection can change tax results when multiple candidates exist.
- Final confirmation must explain derived tax event and rule source.

## Entry Point
- ProducedBeer page -> button: "酒税関連登録" (Tax Movement Regist...)

## Rule Source (Dynamic)
- Rules are stored in `docs/data/movementrule.jsonc`.
- UI must load and interpret:
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
- List movement intents from `movement_intent` with labels read from `movement_intent_labels`
- Show short rule summary (allowed site types, edge types).

System behavior:
- Loads movementrule.jsonc
- Initializes default tax decision code if rule has choices.

--------------------------------------------------
Step 2: Select src/dst site（移動元先酒税情報入力）
--------------------------------------------------
UI:
- Select Source Site (required)
  - select source site type (dropdown list including allowed site types got from step 1)
  - select source site (dropdown list)

- Select Destination Site (required if `dst_required=true`)
  - select destination site type (dropdown list including allowed site types got from step 1)
  - select destination site (dropdown list)

- Tax Decision Code 
  - set default Tax Decision Code from tax_transformation_rules based on movement_intent, src site type and dst site type
  - if user want to choose other allowed_tax_decision. user need to input reason 

System behavior:
- Validate against allowed site types in the rule.
- Compute default tax decision code (if rule requires a decision).
- Preview derived tax event using `tax_transformation_rules`.

--------------------------------------------------
Step 3: Select lot　（移動商品選択）
--------------------------------------------------
UI:
- Select Lot(s) from inventory (inv_movement and inv_movement_lines) for Source Site
  - lot code
  - related batch code
  - batch info
  - package info (volume, uom )
  - quantity
- If multiple lots have different `lot_tax_type`, show tax preview changes.

System behavior:
- find `src_lot_tax_type` from selected lot.
- If destination lot is created/selected, determine `dst_lot_tax_type`.
- If multiple candidates change tax event, highlight options.

--------------------------------------------------
Step 4: Fill necessary information（詳細情報入力）
--------------------------------------------------
UI:
- Date/time
- Quantity / UOM
- Reason or evidence fields (conditional by rule)
- Notes (optional)

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
- Save Draft
- Post (requires validation)

--------------------------------------------------
Validation Rules (Dynamic)
--------------------------------------------------
- movement_intent must be selected.
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
Primary fields:
- movement_intent
- src_site_id / dst_site_id
- src_site_type / dst_site_type (derived)
- product_id
- lot_id (source) / lot_id (destination or new lot)
- tax_decision_code
- tax_event
- status (draft/posted)

All derived fields must be traceable to:
- `movementrule.jsonc` + selected rule id

--------------------------------------------------
Notes
--------------------------------------------------
- UI must re-evaluate tax event when any of steps 1-3 change.
- If rule changes invalidate current selection, prompt user to reselect.
