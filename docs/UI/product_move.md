製品ビール移出登録 Dialog UI Specification (Dynamic Rules)
=================================================

## Purpose
This specification defines the UI flow for 製品ビール移出登録 (Tax Removal Register).
The UI must get rules from server call and never hardcode movement intents, tax decisions, or site type mappings.

Key principles:
- Movement intent is chosen first.
- Site types are derived from selected sites.
- Source lot tax type candidates are derived from the rules after source/destination sites are fixed.
- Default tax decision is derived after the source lot tax type is chosen.
- Product/Lot selection can change tax results when multiple candidates exist.
- Final confirmation must explain derived tax event and rule source.
- Movement intents shown in this wizard must be controlled by ruleengine visibility flags, not by UI hardcode.

## Entry Point
- ProducedBeer page -> button: "他の移入出" (Tax Removal Register...)

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
Step 2 → select src/dst site (system derives site_type)  
Step 3 → select source lot tax type + product/lot + tax decision code  
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
- Only movement intents with `movement_intent_labels.<code>.show_in_movement_wizard = true` are shown in this wizard.
- For this wizard, `INTERNAL_TRANSFER`, `SHIP_DOMESTIC`, and `LOSS` must be hidden by rule configuration.

--------------------------------------------------
Step 2: Select src/dst site（移出元先選択）
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

System behavior:
- call movement_get_rules to get rules for the movement intent which user input in Step 1
- Derive site_type from the selected source/destination sites.
- Derive the list of allowed `src_lot_tax_type` from `tax_transformation_rules` matching:
  - `movement_intent`
  - `src_site_type`
  - `dst_site_type`
- Do not finalize default tax decision code in this step because `src_lot_tax_type` is not yet chosen.

--------------------------------------------------
Step 3: Select lot　（移出商品選択）
--------------------------------------------------
UI layout:
- Do not switch to a different dialog or alternate page layout.
- Step 3 is composed of these blocks in order:
  - header
  - first input row
    - `移出元ロット税区分`
    - `税務判定コード`
  - second input row
    - `ロットコード` lookup input in lot lookup mode only
    - `製品名`
    - `理由` when required
  - selected lot summary in lot lookup mode only
  - lot table
  - warning messages area
- The header may show a lookup-mode hint when candidates are loaded from `lot` instead of `inv_inventory`.

UI:
- `移出元ロット税区分` is shown before lot selection.
- `移出元ロット税区分` options are derived from the rule context:
  - `movement_intent`
  - `src_site_type`
  - `dst_site_type`
- If exactly one `src_lot_tax_type` candidate exists, the page may auto-select it.
- If multiple `src_lot_tax_type` candidates exist, the user must choose one before lot candidates are shown.
- `税務判定コード` is shown in Step 3 and is enabled only after `移出元ロット税区分` is selected.
- The Step 3 area shows the default `税務判定コード`.
- If the selected `税務判定コード` is non-default, show `理由` input in the second row.
- In lot lookup mode:
  - show `ロットコード` input
  - show type-ahead suggestion list while typing
  - suggestion row must include disambiguation information because `lot_no` may duplicate
  - current implementation uses:
    - lot code / label
    - style name
    - batch code
    - displayed quantity + UOM
    - site
    - produced date
    - short `lot.id`
- After a lot is selected in lookup mode, show a compact selected-lot summary above the table.
- The lot table keeps the current columns:
  - select
  - lot code
  - beer category
  - ABV
  - style name
  - batch code
  - package volume
  - package UOM
  - total volume
  - quantity
  - movement quantity
  - UOM
- `movement quantity` input is enabled only for checked rows.
- By default, the lot table and lot suggestions must be filtered to the selected `移出元ロット税区分`.
- By default, if no `移出元ロット税区分` is selected, the lot table shows no candidates.
- Exception: when `src_site_type = DOMESTIC_CUSTOMER` or `src_site_type = OTHER_BREWERY`, Step 3 candidate search must not apply site filtering or `移出元ロット税区分` filtering.
- The page may show warning messages below the table for:
  - multiple selected lot tax types
  - multiple candidate tax events

Validation:
- `src_lot_tax_type` is required before save.
- `tax_decision_code` is required before save.
- At least one source lot must be selected before save.
- A selected lot must match the selected `src_lot_tax_type`.
- `理由` is required only when selected `tax_decision_code` is not the default decision in the current rule context.
- `movement quantity` must be numeric and greater than `0`.
- `movement quantity` must not exceed the candidate lot's available quantity.
- If packaged input is used, the page converts package count to base quantity before validation.
- The page keeps row-level inline validation style consistent with the current implementation.

System behavior:
- Before lot selection, find candidate `src_lot_tax_type` values from `tax_transformation_rules` matching:
  - `movement_intent`
  - `src_site_type`
  - `dst_site_type`
- After `src_lot_tax_type` is selected, derive:
  - filtered lot candidate list
  - allowed `tax_decision_code` list
  - default `tax_decision_code`
  - tax event preview
- `tax_decision_code` candidates are filtered from `tax_transformation_rules` by:
  - `movement_intent`
  - `src_site_type`
  - `dst_site_type`
  - `src_lot_tax_type`
- When source stock exists in `inv_inventory`, Step 3 resolves candidates from inventory rows.
- When `movement_intent = RETURN_FROM_CUSTOMER` and source stock does not exist in `inv_inventory`, Step 3 switches to lot lookup mode and resolves candidates from `lot`-based data.
- A successful `RETURN_FROM_CUSTOMER` post must also create or update destination `inv_inventory`; if the destination inventory row does not exist after posting, backend raises `PM012`.
- When `src_site_type = DOMESTIC_CUSTOMER` or `src_site_type = OTHER_BREWERY`, Step 3 must search the tenant `lot` table instead of `inv_inventory`, without site filtering and without `src_lot_tax_type` candidate filtering, because `SHIP_DOMESTIC` is not registered in this system.
- For this special case, filled-lot lookup means tenant `lot` rows where `package_id` is present.
- In lot lookup mode, the page still posts using `lot.id`, not `lot_no`.
- Changing `src_lot_tax_type` must:
  - re-evaluate allowed `tax_decision_code`
  - reset invalid tax decision selections
  - drop selected lots that no longer match the chosen tax type
- Changing selected lots must prune stale `movement quantity` inputs for unchecked rows.
- For `RETURN_FROM_CUSTOMER`, allowable quantity is validated from lot balance even when source `inv_inventory` does not exist.

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
- source lot tax type must be selected from the rule-derived candidate list.
- tax decision code must be resolved from the same rule context as the selected `src_lot_tax_type`.
- reason is required only when selected `tax_decision_code` is not the default decision for that rule context.

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
- Changing source lot tax type or selected lot(s) must re-evaluate:
  - allowed tax decision list
  - default tax decision
  - whether `reason` is required
- If rule changes invalidate current selection, prompt user to reselect.
- the page should be multi-languaged
