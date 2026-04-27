# Current Task

## Goal
- Rename the `製品ビール移出登録` page wording to `その他移入出登録`.
- Add a Step 1 entry point in the movement wizard for shipping/selling produced beer to another brewery.
- Continue using the current rule engine for movement rules, tax decisions, site type labels, and lot tax behavior.
- Keep `SHIP_DOMESTIC` hidden from the normal rule-engine-driven movement intent list.

## Scope
- Update the movement wizard Step 1 design to show one business-action list.
- The list includes:
  - normal rule-engine visible movement intents
  - the frontend preset `その他醸造所移出` / `Other Brewery Shipment`
- The preset card should not show explanatory/comment text.
- The dedicated preset maps internally to:
  - `movement_intent = "SHIP_DOMESTIC"`
  - `entry_mode = "OTHER_BREWERY_SHIPMENT"`
  - destination site type constrained to `OTHER_BREWERY`
- The preset must call `movement_get_rules('SHIP_DOMESTIC')` and derive all allowed source site types, lot tax types, tax decisions, and tax events from the returned rule payload.
- Step 2 must restrict destination site type and destination site choices to `OTHER_BREWERY` when the preset is active.
- Step 2 must be complete before the user can move to Step 3.
- Step 3 must be complete before the user can move to Step 4.
- Save must still call `public.product_move(p_doc jsonb)`.
- Save payload metadata should include:
  - `meta.entry_mode = "OTHER_BREWERY_SHIPMENT"`

## Non-Goals
- Do not make `SHIP_DOMESTIC.show_in_movement_wizard` true.
- Do not add a new movement intent enum.
- Do not add a new stored function.
- Do not change `movementrule.sql` rule visibility or tax transformation semantics in this task.
- Do not add a real customer shipment flow.
- Do not redesign later wizard steps beyond the constraints needed for this preset.

## Affected Files
- Spec:
  - `specs/current-task.md`
- Expected implementation files:
  - `beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue`
  - `beeradmin_tail/src/locales/ja.json`
  - `beeradmin_tail/src/locales/en.json`
- Reference files:
  - `docs/UI/product_move.md`
  - `DB/dml/registry_def/movementrule.sql`
  - `DB/function/44_public.product_move.sql`
  - `DB/function/35_public.movement_get_rules.sql`
  - `DB/function/34_public.movement_get_movement_UI_intent.sql`

## Data Model / API Changes
- No database schema changes.
- No stored function signature changes.
- `movement_get_movement_UI_intent()` remains the source for normal Step 1 movement intents.
- `movement_get_rules('SHIP_DOMESTIC')` is used after selecting the dedicated other-brewery preset.
- `public.product_move(...)` remains the posting API.
- New frontend-only state:
  - `entryMode: "RULE_INTENT" | "OTHER_BREWERY_SHIPMENT"`
- New movement metadata on save:
  - `meta.entry_mode = "OTHER_BREWERY_SHIPMENT"` only for this preset.

## Step 1 Design
- Step 1 title should use business wording:
  - Japanese: `登録内容を選択`
  - English: `Select Registration Type`
- Step 1 should display one list of business actions.
- The list contains:
  - movement intents returned by `movement_get_movement_UI_intent()`
  - one frontend preset card:
    - Japanese label: `その他醸造所移出`
    - English label: `Other Brewery Shipment`
- The preset card must not show a description/comment under the label.
- The UI must not expose a visible distinction such as `通常の移出目的` vs `専用登録`.
- The preset card is not returned by the rule engine and is not a new movement intent.
- Selecting the preset should:
  - set `movementForm.intent = "SHIP_DOMESTIC"`
  - set `entryMode = "OTHER_BREWERY_SHIPMENT"`
  - call `movement_get_rules('SHIP_DOMESTIC')`
  - move to the same Step 2 flow used by normal intents

## Step 2 Constraints
- When `entryMode = "OTHER_BREWERY_SHIPMENT"`:
  - destination site type options must be filtered to `OTHER_BREWERY`
  - destination site options must be filtered to sites whose resolved rule site type is `OTHER_BREWERY`
  - source site type options must still come from the `SHIP_DOMESTIC` rule payload
  - source site options must follow the selected source site type
- The UI must not show `DOMESTIC_CUSTOMER` as an allowed destination in this preset.
- Step 2 is complete only when all required site fields are selected:
  - source site type
  - source site
  - destination site type
  - destination site
- The Next button must not move from Step 2 to Step 3 until Step 2 is complete.
- The step header buttons must not allow jumping to Step 3 or later until Step 2 is complete.
- In the other-brewery preset, Step 2 completion also requires:
  - `dstSiteType = "OTHER_BREWERY"`
  - the selected destination site resolves to site type `OTHER_BREWERY`

## Step 3 / Tax Behavior
- Lot tax type options must be derived from `tax_transformation_rules` matching:
  - `movement_intent = "SHIP_DOMESTIC"`
  - selected source site type
  - `dst_site_type = "OTHER_BREWERY"`
- Tax decision options and default decision must come from the matching rule.
- If a non-default tax decision is selected, existing reason handling should remain in effect.
- Quantity and package input behavior must continue to follow existing wizard behavior and durable quantity rules.
- Step 3 is complete only when:
  - `移出元ロット税区分` / source lot tax type is selected
  - `税務判定コード` / tax decision code is selected
  - at least one lot row is selected
  - every selected lot row has a valid movement quantity greater than zero
  - selected lot movement quantity does not exceed available lot stock
  - selected lot row has a UOM
  - non-default tax decision reason is entered when the existing reason rule requires it
- The Next button must not move from Step 3 to Step 4 until Step 3 is complete.
- The step header buttons must not allow jumping to Step 4 or later until Step 3 is complete.

## Confirmation / Save
- Confirmation should make the preset clear:
  - registration type: `その他醸造所移出`
  - movement intent: `SHIP_DOMESTIC` / `国内出荷`
  - destination site type: `OTHER_BREWERY`
- Before save, frontend validation must reject the preset if the resolved destination site type is not `OTHER_BREWERY`.
- Save payload should include:
  - `movement_intent: "SHIP_DOMESTIC"`
  - selected source and destination sites
  - selected lot and quantity
  - selected tax decision code
  - existing price/notes/reason fields
  - `meta.entry_mode = "OTHER_BREWERY_SHIPMENT"`

## Concerns / Guardrails
- This is a UI preset, not backend authorization. Direct API calls can still post any valid rule-engine `SHIP_DOMESTIC` context.
- The preset must not be treated as a real movement intent in saved movement data.
- Reports/history that need to distinguish this flow should use:
  - destination site type `OTHER_BREWERY`
  - or `inv_movements.meta.entry_mode`
- If business rules later require stricter source site restrictions, update the rule engine or add an explicit preset source filter.
- Return flow compatibility should be checked because the outbound lot lands at an `OTHER_BREWERY` destination.

## Planned File Changes
- `ProducedBeerMovementEdit.vue`
  - Add Step 1 business-action list.
  - Add frontend-only `entryMode`.
  - Load `SHIP_DOMESTIC` rules when the preset is selected.
  - Constrain destination site type/site options to `OTHER_BREWERY`.
  - Require complete Step 2 source/destination selections before Step 3 navigation.
  - Require complete Step 3 tax/lot selections before Step 4 navigation.
  - Validate destination site type before save.
  - Add `meta.entry_mode` to save payload for the preset.
- Locale files:
  - Rename page title/wizard title to `その他移入出登録`.
  - Rename the preset card to `その他醸造所移出`.
  - Remove preset card comment text.
  - Add confirmation label for registration type if needed.

## Validation Plan
- Spec/design:
  - `git diff --check`
- Implementation:
  - locale JSON parse for `ja.json` and `en.json`
  - `npm run type-check`
  - targeted ESLint for touched Vue files
  - `npm run test --if-present`
  - manual UI check:
    - Step 1 shows one business-action list
    - rule-engine visible intents and `その他醸造所移出` appear together
    - preset loads `SHIP_DOMESTIC` rules
    - Step 2 destination type only allows `OTHER_BREWERY`
    - Step 2 Next remains blocked until source type, source site, destination type, and destination site are selected
    - Step header buttons cannot jump to Step 3 or later until Step 2 is complete
    - Step 3 Next remains blocked until source lot tax type, tax decision code, and valid selected lot rows are present
    - Step header buttons cannot jump to Step 4 or later until Step 3 is complete
    - save payload uses `SHIP_DOMESTIC` and includes `meta.entry_mode`

## Final Decisions
- Step 1 now shows a single business-action list.
- Rule-engine visible movement intents and the frontend preset appear together.
- The UI does not expose `通常の移出目的` / `専用登録` as separate concepts.
- The preset is frontend-only and maps to:
  - `movement_intent = "SHIP_DOMESTIC"`
  - `entryMode = "OTHER_BREWERY_SHIPMENT"`
- The preset still loads normal `SHIP_DOMESTIC` rules through `movement_get_rules`.
- Destination site type/site options are constrained to `OTHER_BREWERY` in preset mode.
- Step 2 navigation now requires source site type, source site, destination site type, and destination site before Step 3 is reachable.
- The step header buttons follow the same Step 2 completion gate for Step 3 and later steps.
- Page title and wizard title are now `その他移入出登録`.
- The preset label is now `その他醸造所移出`.
- The preset card does not show a description/comment.
- Step 3 navigation now requires source lot tax type, tax decision code, and valid selected lot rows before Step 4 is reachable.
- The step header buttons follow the same Step 3 completion gate for Step 4 and later steps.
- Save validation rejects the preset if destination site type is not `OTHER_BREWERY`.
- Save payload adds `meta.entry_mode = "OTHER_BREWERY_SHIPMENT"` only for the preset.

## Validation Results
- `git diff --check` passed after the title, preset label, and Step 3 navigation changes.
- Locale JSON parse passed for `beeradmin_tail/src/locales/ja.json` and `beeradmin_tail/src/locales/en.json`.
- `npm run type-check` passed.
- `npm run build` passed with existing CSS minifier warnings for `::-webkit-scrollbar-thumb:is()`.
- `npm run test --if-present` passed with no test output.
- Targeted `npx eslint --no-fix src/views/Pages/ProducedBeerMovementEdit.vue` still fails on existing `no-explicit-any` and unused-helper debt in that file.
