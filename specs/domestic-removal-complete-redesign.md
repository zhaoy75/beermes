# Domestic Removal Complete Redesign

## Purpose
- Redefine `国内移出完了` on the `ビール在庫管理` page as a real business shipment.
- Replace the current `inventory set zero` behavior with a special full-quantity `SHIP_DOMESTIC` flow.
- Preserve lot lineage and tax-event traceability.
- Make later `RETURN_FROM_CUSTOMER` lot search possible without ad hoc reconstruction.

## Background
- Current inventory-page action calls `public.inventory_lot_void(...)`.
- That behavior creates an `adjustment` movement and consumes the lot/inventory to zero.
- This is operationally simple but semantically weak:
  - it is not a real domestic shipment
  - it does not go through `public.product_move(...)`
  - it does not create a customer-side lot
  - it weakens downstream return search and audit consistency

## Target Design Summary
- Keep the UI action label `国内移出完了`.
- Reinterpret the action as:
  - move the full current quantity of the selected tax-storage lot
  - from `TAX_STORAGE`
  - to a hidden dummy `DOMESTIC_CUSTOMER` site
  - using standard shipment logic through `public.product_move(...)`
- The inventory page action becomes a thin trigger over backend business logic.

## Core Business Meaning
- `国内移出完了` means:
  - “this lot has now left internal tax storage and has been shipped outside domestically”
- It is not:
  - inventory correction
  - data cleanup
  - lot voiding
  - arbitrary quantity adjustment

## UI Behavior

### Availability
- The action remains available only when all underlying visible-row lots are in `TAX_STORAGE`.
- The action remains unavailable for non-`TAX_STORAGE` rows.
- The action remains unavailable when the visible row has no positive quantity.

### Row Selection and Bulk Processing
- The inventory table may provide checkboxes for row selection.
- Row selection itself is not limited to `国内移出完了` eligibility:
  - a checkbox may be enabled even when only one row is visible
  - a checkbox may be enabled for rows that are not eligible for `国内移出完了`
- Bulk execution is limited to `国内移出完了` only.
- The bulk `国内移出完了` command must execute only against selected rows that are eligible for the action.
- If selected rows contain no eligible `国内移出完了` targets, the bulk command must be disabled or otherwise blocked before RPC execution.
- Select-all behavior should operate on the currently visible rows, then the bulk command should internally filter to eligible rows before execution.
- Bulk execution should deduplicate underlying lot/site targets before calling the backend wrapper.
- Other row actions, including `解体` and `関連履歴`, remain single-row actions.

### Full-Quantity Rule
- The action always moves the full current quantity of each target lot in the visible row.
- The inventory page must not prompt the user for partial quantity.
- For merged visible rows, the page may continue iterating underlying lot targets one by one.
- For bulk execution, each eligible selected row follows the same full-quantity rule for each underlying target lot.

### Confirmation
- Keep a confirmation dialog.
- Suggested confirmation meaning:
  - “complete domestic removal for the selected lot(s)”
- The wording must no longer imply “cancel removal” or “set inventory to zero”.
- For bulk execution, the confirmation should communicate the selected row count and the actual eligible target count.

### Success Result on Inventory Page
- After success, the selected `TAX_STORAGE` inventory row disappears from the tax-storage view because its source quantity becomes zero.
- The destination customer-side lot must not appear in normal `ビール在庫管理` grid results.
- The page refresh behavior remains the same after successful completion.
- After successful bulk execution, selected rows should be cleared or pruned during the inventory refresh.

## Backend Flow

### New Backend Entry Point
- Introduce a dedicated wrapper function or RPC for this action.
- Recommended name:
  - `public.domestic_removal_complete(p_lot_id uuid, p_site_id uuid, p_reason text default null)`

### Dummy Site Helper Contract
- Introduce a backend helper function dedicated to the tenant dummy destination site.
- Recommended name:
  - `public.ensure_dummy_domestic_customer_site() returns uuid`
- Responsibility:
  - resolve the current tenant dummy domestic-customer site
  - if absent, create it lazily
  - return the site id
- This helper is backend-owned only.
- UI must not create, seed, or select the dummy site directly.

### Wrapper Responsibilities
- Lock and validate the source lot and source inventory row.
- Confirm the source site is `TAX_STORAGE`.
- Resolve the current positive quantity and UOM from the source inventory / lot.
- Resolve the tenant dummy domestic-customer site through `ensure_dummy_domestic_customer_site()`.
- Determine the required tax decision using movement rules for:
  - `movement_intent = 'SHIP_DOMESTIC'`
  - `src_site_type = 'TAX_STORAGE'`
  - `dst_site_type = 'DOMESTIC_CUSTOMER'`
  - source lot tax type
- Build a single full-quantity `product_move` payload.
- Call `public.product_move(p_doc jsonb)` internally.
- Return the created movement id.

### Product Move Payload Direction
- The wrapper must build a payload equivalent to:
  - `movement_intent = 'SHIP_DOMESTIC'`
  - `src_site = source TAX_STORAGE site`
  - `dst_site = dummy DOMESTIC_CUSTOMER site`
  - `src_lot_id = source lot id`
  - `qty = full current quantity`
  - `unit = full current unit when package unit exists`
  - `uom_id = source lot uom_id`
  - `tax_decision_code = resolved default tax decision for the route`
  - `reason = caller reason or system default`
  - `meta.source = 'produced_beer_inventory_domestic_removal_complete'`

### Explicit Replacement
- `public.inventory_lot_void(...)` must no longer be used by the inventory-page `国内移出完了` action.
- `inventory_lot_void` may remain in the system for other administrative inventory-zeroing use cases, but not for this page action.

## Movement Rule Requirements

### Required Rule Coverage
- Add rule-engine support for:
  - `movement_intent = 'SHIP_DOMESTIC'`
  - `src_site_type = 'TAX_STORAGE'`
  - `dst_site_type = 'DOMESTIC_CUSTOMER'`

### Required Tax Decision Expectations
- At minimum, define valid domestic-shipment behavior for:
  - `lot_tax_type = 'TAX_SUSPENDED'`
    - default tax decision should resolve to taxable domestic removal
  - `lot_tax_type = 'TAX_PAID'`
    - default tax decision should resolve to no additional tax effect

### Result Lot Tax Type
- Rule definitions must provide correct result-lot tax semantics for the customer-side lot.
- For taxable domestic removal, the destination lot should end in a tax-paid-equivalent state.

## Dummy Domestic-Customer Site

### Purpose
- Represent outbound domestic shipment completion without requiring real customer-master selection from the inventory page.

### Site Characteristics
- One dummy site per tenant.
- Site type:
  - `DOMESTIC_CUSTOMER`
- System-managed:
  - yes
- Hidden from ordinary site pickers:
  - yes
- Hidden from standard inventory views:
  - yes

### Recommended Metadata
- Current schema note:
  - `public.mst_sites` does not have a `meta` column
- Therefore the helper implementation must use existing fields only:
  - `name`
  - `site_type_id`
  - `notes`
  - `owner_type`
  - `owner_name`
  - `active`
  - `sort_order`
- Any future hidden/system-managed flags would require separate schema or UI-filter work.

### Recommended Stable Identity
- The helper must be able to find the same row deterministically.
- In the current schema, recommended identity is:
  - `owner_type = 'OUTSIDE'`
  - `owner_name = 'SYSTEM_DOMESTIC_REMOVAL_COMPLETE'`
- `name = '国内移出完了ダミー取引先'` is the canonical display value but should not be the only match key.
- Matching must also include the resolved `DOMESTIC_CUSTOMER` `site_type_id`.

### Resolution Strategy
- Preferred runtime behavior:
  - backend resolves the tenant dummy site by stable business fields
  - if it does not exist, backend creates it lazily in the same transaction scope
- The create-vs-require policy is no longer open for this design.
- Lazy create by backend helper is the chosen design.

### Concurrency and Uniqueness
- The helper must be safe under concurrent calls.
- Recommended safeguards:
  - use `pg_advisory_xact_lock(...)` on a tenant-scoped key before create
  - also enforce a uniqueness condition at the data level when feasible
- If two sessions race, only one dummy site row may survive as the canonical target.
- The helper must always return the canonical row id after creation / conflict resolution.

### Suggested Create Defaults
- When the helper creates the site, the default record should be:
  - tenant-owned
  - active
  - clearly marked by fixed `owner_type`, `owner_name`, and `notes`
- Display-name example:
  - Japanese: `国内移出完了ダミー取引先`
  - English: `Domestic Removal Dummy Customer`

## Inventory Visibility Rules

### Inventory Page
- The standard `ビール在庫管理` page must exclude lots stored in the dummy domestic-customer site.
- This keeps `国内移出完了` visually equivalent to “lot has left internal inventory”.

### Inventory Search Modal
- The standard inventory search modal should also exclude dummy-site rows by default.
- The dummy-site lots are operational return candidates, not standard on-hand internal stock.

## Lot Lineage and Return Compatibility

### Required Outcome
- Because `product_move(...)` creates or reuses the destination customer-side lot, downstream return flow can search and select that lot.

### Return Flow Requirement
- Future `RETURN_FROM_CUSTOMER` search must treat dummy-site domestic shipment lots as valid sold-lot candidates.
- The search target is the customer-side lot created by shipment, not the original brewery lot.

### Traceability Limitation
- This design preserves lot-level traceability but not real-customer identity.
- That tradeoff is accepted in this design.
- If real customer traceability is later required, the system can evolve from dummy customer site to real destination customer sites without changing the meaning of `国内移出完了`.

## UI Copy Direction
- Japanese action label may stay:
  - `国内移出完了`
- English label should be revised away from `Cancel Removal`.
- Recommended English label:
  - `Complete Domestic Removal`

## Error Handling
- Backend must reject the action when:
  - source site is not `TAX_STORAGE`
  - source lot is not active / movable
  - source quantity is zero or negative
  - no valid `SHIP_DOMESTIC` rule exists for the source lot context
  - dummy domestic-customer site cannot be resolved or created
- UI must show the backend message and leave the row unchanged.

## Audit / Reporting Expectations
- Resulting movement must be a real shipment movement, not an adjustment.
- `inv_movements.meta.tax_event` and `tax_decision_code` must be populated through standard movement logic.
- Tax reporting should therefore use the resulting movement naturally instead of relying on an inventory-adjustment exception path.

## Affected Areas In Future Implementation
- Inventory page action handler
- inventory page action copy
- backend wrapper function
- movement-rule seed / registry definition
- dummy-site resolution helper
- returnable sold-lot search
- normal inventory dataset filtering

## Non-Goals
- Do not add real customer selection from the inventory page in this design.
- Do not make `国内移出完了` partial-quantity capable.
- Do not redesign the full domestic shipment wizard here.
- Do not remove `inventory_lot_void` globally for all use cases.

## Acceptance Criteria
1. Clicking `国内移出完了` on a `TAX_STORAGE` inventory row triggers a backend business flow that performs a real `SHIP_DOMESTIC` movement.
2. The backend uses full current lot quantity and does not accept partial quantity from this page action.
3. The backend action creates a normal shipment movement through `public.product_move(...)`, not an `adjustment` zeroing movement.
4. The destination of this movement is the tenant dummy `DOMESTIC_CUSTOMER` site.
5. After success, the source `TAX_STORAGE` quantity becomes zero and disappears from the normal inventory page.
6. The destination dummy-site lot is hidden from ordinary inventory views and pickers.
7. The created movement stores standard movement metadata including `movement_intent`, `tax_decision_code`, and derived `tax_event`.
8. Future `RETURN_FROM_CUSTOMER` flow can search the resulting customer-side lot as a sold-lot candidate.
9. The inventory page no longer depends on `inventory_lot_void(...)` for `国内移出完了`.
10. Inventory row checkboxes can be used for selection even when only one row is visible.
11. Bulk processing is available only for `国内移出完了`; selecting rows must not create bulk `解体`, `関連履歴`, or other bulk actions.
12. Bulk `国内移出完了` executes only selected eligible targets and must not call the backend for selected ineligible rows.
