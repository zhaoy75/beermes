# ProductMoveFast Page UI Specification

## Purpose
- Register beer `INTERNAL_TRANSFER` movements on a dedicated high-speed page.
- Minimize clicks for repetitive internal logistics entry.
- Support keyboard-first operation and paste-based multi-line input.
- Prevent route misuse for tax-sensitive site combinations.
- Default to backend auto lot allocation using `FEFO`.
- Ensure posting is atomic (all-or-nothing) even when one UI line is split into multiple lot-level movements.

## Entry Points
- Produced Beer page -> action button: `ProductMoveFast` / `社内移動(高速入力)`
- Optional shortcut from movement list for users who repeatedly post `INTERNAL_TRANSFER`
- Route: `/producedBeerMovementFast`

## Users and Permissions
- Tenant User: create `INTERNAL_TRANSFER` product movements in tenant scope.
- Tenant User: use recent routes and favorites saved for that user.
- Read-only or unauthorized user: page hidden or blocked.

## Page Layout
### Header
- Sticky header.
- Title: `INTERNAL_TRANSFER`
- Actions:
  - `Post`
  - `Post & Next`

### Body
- Recent / Favorites
- Sticky route bar under header.
- Main body uses 2 areas on desktop and stacked layout on mobile:
  - left: 
    Lines Search
    Lines Grid
  - Right: Summary / Validation

### Modal/Dialog
- No modal in standard flow.
- Minimal modal or side drawer may be used only for `MANUAL` lot allocation.

## Field Definitions
### Route Bar
- Fields:

| Field | Required | Default | Notes |
| --- | --- | --- | --- |
| From Site | Yes | Last used | Source site |
| To Site | Yes | Last used | Destination site |
| Movement Date | Yes | Now | User editable |
| Allocation Policy | Yes | `FEFO` | `FEFO`, `FIFO`, `MANUAL` |
| Derived Movement Intent | Yes | `INTERNAL_TRANSFER` | Read-only |
| Derived Tax Movement Type | Yes | Auto | Read-only after route evaluation |
| Tax Decision Code | Conditional | Auto | Shown when rule returns selectable tax decision |
| Note | No | Empty | Header note for movement |

add favorites button 

- Behavior:
  - `From Site` dropdown must be filtered to site types allowed as `allowed_src_site_types` for `INTERNAL_TRANSFER`
  - `To Site` dropdown must be filtered to site types allowed as `allowed_dst_site_types` for `INTERNAL_TRANSFER`
  - route values persist after successful `Post` and `Post & Next`
  - block when `From Site = To Site`
  - swap button exchanges From/To site values
  - once From/To site is chosen, UI evaluates the rule engine and shows:
    - fixed `movement_intent = INTERNAL_TRANSFER`
    - derived tax movement type / tax event
    - default `tax_decision_code`
  - UI must call Supabase RPC `movement_get_rules` with `p_movement_intent = 'INTERNAL_TRANSFER'`
  - if multiple tax decisions are allowed for the resolved `INTERNAL_TRANSFER` route, UI shows selectable tax decision list and defaults to the rule default
  - default focus after page load is first Beer field in Lines Grid, not route bar
  - clike button (add to favorites) will add current route to favoriates 

### Recent / Favorites Panel
- Shows recently used routes for the current user.
- Supports favorite route presets.
- Each item shows at minimum:
  - From site
  - To site
  - Last used date or favorite marker
- Clicking an item applies route bar values without posting.
- Recent routes are updated only after successful post.

### Lines Search
- One primary search input (`Beer`) is used for line entry.
- Search modes:
  - exact code
  - partial code
  - name match
- `Enter` selects top result when suggestion list is open.
- After beer selection, focus moves to Quantity.
- Search result should display code and name together.
- Package and amount are represented by line fields (Lot No and Quantity), not separate global search inputs.

### Paste Input
- User can paste multiple lines into the first `Beer` field.
- Example:

```text
IPA01 50
PILS02 20
STOUT03 10
```
- System behavior:
  - parse each line as `beer_identifier + qty`
  - create rows automatically
  - resolve beer code/name search for each pasted row
  - leave unresolved rows highlighted for correction


### Lines Grid
- Default state:
  - 5 empty rows
  - first Beer field focused
  - Quantity input should be sized for typical entry around 4 integer digits plus decimal precision, without wasting horizontal space
- Columns:

| Column | Required | Notes |
| --- | --- | --- |
| Beer | Yes | Search by beer code or name |
| Lot No | Conditional | Required only for `MANUAL`; read-only/auto for `FEFO` and `FIFO` |
| Quantity (L) | Yes | Numeric, `> 0`; width should comfortably fit values in the range of `9999.999` but stay visually compact |
| Note | No | Line note |

- Row behavior:
  - selecting a beer moves focus to Quantity
  - pressing `Enter` in Quantity moves to next editable row
  - empty trailing rows should be auto-added as needed
  - rows with no beer and no quantity are ignored
  - when allocation policy is `MANUAL`, `Lot No` is user-selectable from available lots in source site stock for the selected beer
  - when allocation policy is `FEFO` or `FIFO`, `Lot No` is display-only and determined by backend allocation result
  - changing policy from `MANUAL` to `FEFO`/`FIFO` clears manual lot selections for all lines
  - Quantity cell width should balance entry speed and table density; avoid both cramped and oversized presentation


### Summary / Validation Panel
- Always visible.
- Shows:
  - selected route summary
  - derived movement intent
  - derived tax movement type / tax event
  - selected tax decision code
  - allocation policy
  - valid line count
  - total quantity in liters
  - hard-block validation errors
  - soft warnings

## Actions
- `Post`
  - validate route and lines
  - submit movement
  - save route to Recent
  - return created `movement_id`
- `Post & Next`
  - same save behavior as `Post`
  - clear lines only
  - keep route bar values
  - focus first Beer field
- `Swap`
  - exchange From Site and To Site
  - immediately re-run route validation
- `Apply Recent/Favorite`
  - copy saved route into route bar
- Keyboard shortcuts:

| Key | Action |
| --- | --- |
| `/` | Focus first Beer search field |
| `Enter` | Move to next editable cell |
| `Ctrl+Enter` | Post |
| `Shift+Enter` | Post & Next |

## Business Rules
- This page is dedicated to `movement_intent = INTERNAL_TRANSFER`.
- UI must not hardcode tax movement type or tax decision behavior.
- Route resolution flow:
  - UI first loads `INTERNAL_TRANSFER` rule data
  - `From Site` dropdown only shows sites whose site type matches `allowed_src_site_types` for `INTERNAL_TRANSFER`
  - after `From Site` is chosen, `To Site` dropdown only shows sites whose site type matches `allowed_dst_site_types` for `INTERNAL_TRANSFER`
  - user selects From Site
  - user selects To Site
  - UI resolves site types
  - UI calls Supabase RPC `movement_get_rules` with `p_movement_intent = 'INTERNAL_TRANSFER'` to load rule-engine data
  - UI determines derived tax movement type / tax event and default `tax_decision_code`
- Examples:
  - internal non-taxable route may resolve to non-taxable internal transfer behavior
  - route to `DIRECT_SALES_SHOP` must be blocked on this page and explained as domestic shipment flow
  - route to `TAX_STORAGE` must be blocked on this page and explained as tax-specific movement flow
- If site combination has no valid rule match, posting is blocked.
- If route change invalidates current tax decision, lots, or line assumptions, UI must recalculate and prompt user to confirm if needed.
- `From Site` and `To Site` are required.
- `From Site` must not equal `To Site`.
- `movement_intent` is always `INTERNAL_TRANSFER`.
- At least one valid line is required.
- Quantity must be greater than `0`.
- Beer is identified by code or name, but backend resolution must use stable beer/product id before posting.
- Allocation rules:
  - `FEFO` or `FIFO`: backend auto-allocates lots
  - `MANUAL`: user must select lots before posting
  - in `MANUAL`, selected lot must belong to the selected beer and source site
  - in `MANUAL`, selected lot available quantity must be `>=` line quantity
- Soft warnings:
  - low available stock
  - allocation split across many lots
  - near-expiry lots included in allocation
- Route blocking reason codes:
  - `ROUTE_BLOCKED_DIRECT_SALES_SHOP`: destination is `DIRECT_SALES_SHOP`; user must use domestic shipment flow
  - `ROUTE_BLOCKED_TAX_STORAGE`: destination is `TAX_STORAGE`; user must use tax-specific movement flow
  - `ROUTE_NO_INTERNAL_TRANSFER_RULE`: no matching `INTERNAL_TRANSFER` rule for site combination

## Save Behavior
- Disable `Post` actions while submitting.
- ProductMoveFast must use existing backend function:
  - `public.product_move(p_doc jsonb)`
- `public.product_move` is a single-lot movement function, so ProductMoveFast posting must convert each UI line into one or more lot-level `product_move` calls.
- UI must not create inventory, lot, or movement rows directly.
- Before posting, UI must resolve route-driven rule data:
  - fixed `movement_intent = INTERNAL_TRANSFER`
  - `tax_decision_code`
  - derived tax movement type / tax event shown to the user
- Allocation behavior by mode:
  - `FEFO` / `FIFO`
    - determine source lots for each entered beer row
    - split requested quantity across selected lots in allocation order
    - call `public.product_move(p_doc jsonb)` once per allocated lot segment
  - `MANUAL`
    - user selects source lots explicitly
    - call `public.product_move(p_doc jsonb)` once per selected lot segment
- Because one screen post may require multiple `product_move` calls, posting must be orchestrated server-side in one transaction.
- UI must call a single backend endpoint (Edge Function or RPC wrapper) for posting, not loop `product_move` directly from browser.
- Backend endpoint requirements:
  - run all lot-level `product_move` calls inside one DB transaction
  - rollback all work if any line/segment fails
  - return structured row-level errors and route-level errors
  - support optional idempotency key to prevent duplicate posts on retry
- UI working payload example:

```json
{
  "movement_intent": "INTERNAL_TRANSFER",
  "from_site_id": "11111111-1111-1111-1111-111111111111",
  "to_site_id": "22222222-2222-2222-2222-222222222222",
  "moved_at": "2026-03-03T12:00:00+09:00",
  "allocation_policy": "FEFO",
  "tax_decision_code": "NON_TAXABLE_REMOVAL",
  "derived_tax_event": "NON_TAXABLE_REMOVAL",
  "note": "daily internal transfer",
  "lines": [
    { "beer_code": "IPA01", "qty_l": 50.0, "note": "" },
    { "beer_code": "PILS02", "qty_l": 20.0, "note": "priority order" }
  ]
}
```

- Example `public.product_move(p_doc jsonb)` call payload after allocation:

```json
{
  "movement_intent": "INTERNAL_TRANSFER",
  "src_site": "11111111-1111-1111-1111-111111111111",
  "dst_site": "22222222-2222-2222-2222-222222222222",
  "src_lot_id": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
  "qty": 30.0,
  "uom_id": "44444444-4444-4444-4444-444444444444",
  "tax_decision_code": "NON_TAXABLE_REMOVAL",
  "movement_at": "2026-03-03T12:00:00+09:00",
  "notes": "daily internal transfer",
  "meta": {
    "source": "product_move_fast",
    "allocation_policy": "FEFO",
    "beer_code": "IPA01",
    "derived_tax_event": "NON_TAXABLE_REMOVAL",
    "line_note": ""
  }
}
```

- Posting responsibilities:
  - retrieve/evaluate rule-engine data from Supabase via `movement_get_rules`
  - use `movement_intent = INTERNAL_TRANSFER`
  - resolve tax movement type / tax event
  - resolve default or selected `tax_decision_code`
  - validate route rules
  - validate stock before allocation
  - resolve lot allocation
  - execute required `product_move` calls
  - collect created `movement_id` values
  - commit transaction only after all moves succeed
- Success result:
  - return created `movement_id` list or equivalent posted-count summary
- On success:
  - show success message
  - update Recent routes
  - `Post`: remain on page with current route retained
  - `Post & Next`: clear lines and return focus to first Beer field
- On error:
  - show inline row errors when possible
  - show global error summary for post failure

## Data Handling
- Master/reference data:
  - site list from site master
  - beer/product search source with code and localized name
- Rule engine data:
  - load from Supabase before route evaluation
  - use RPC `movement_get_rules` with `p_movement_intent = 'INTERNAL_TRANSFER'`
  - at minimum, UI must obtain:
    - `allowed_src_site_types`
    - `allowed_dst_site_types`
    - site-type labels and mappings
    - tax decision definitions
    - tax transformation rules
- User preference data:
  - last used route
  - recent routes
  - favorite routes
- Derived UI state:
  - route validity
  - resolved source site type
  - resolved destination site type
  - fixed movement intent (`INTERNAL_TRANSFER`)
  - derived tax movement type / tax event
  - selected/default tax decision code
  - total entered liters
  - line-level validity
  - warning summary
- Page should preserve unsaved line input during temporary fetch refreshes where possible.

## Error Handling
- Hard-block errors:
  - missing From Site
  - missing To Site
  - same source and destination
  - no valid `INTERNAL_TRANSFER` rule for selected route
  - tax decision required but not selected
  - no valid lines
  - quantity `<= 0`
  - invalid site combination for `INTERNAL_TRANSFER`
  - unresolved beer code/name
  - `MANUAL` selected but `Lot No` missing for any valid line
  - selected lot does not match beer/source site
  - selected lot has insufficient available quantity
  - backend transaction failed; no movements committed
- Soft warnings:
  - low stock
  - many-lot split
  - near expiry
- Route/rule message must be explicit:
  - destination `DIRECT_SALES_SHOP`: explain that domestic shipment flow must be used
  - destination `TAX_STORAGE`: explain that tax-specific movement flow must be used
  - if route has no matching `INTERNAL_TRANSFER` rule, UI must explain that the selected site combination is not allowed

## Other
- This page is multilingual (Japanese/English).
- Layout must work on desktop and mobile.
- Use sticky header and sticky route bar to keep posting controls visible.
- UX philosophy:
  - single-page design
  - minimal modal usage
  - keyboard-first workflow
  - route reuse
  - fast repetitive entry

## Acceptance Criteria
- FEFO/FIFO post:
  - Given valid route and lines
  - When user clicks `Post`
  - Then backend allocates lots automatically and commits all movements atomically
- MANUAL post:
  - Given allocation policy `MANUAL`
  - When any valid line has no lot selection
  - Then post is blocked with line-level error
  - When all lines have valid lot selections
  - Then post succeeds and keeps exact selected lots
- Route blocking:
  - Route to `DIRECT_SALES_SHOP` must return `ROUTE_BLOCKED_DIRECT_SALES_SHOP`
  - Route to `TAX_STORAGE` must return `ROUTE_BLOCKED_TAX_STORAGE`
  - Unmapped route must return `ROUTE_NO_INTERNAL_TRANSFER_RULE`
- Atomicity:
  - If one segment fails during backend execution
  - Then zero movement rows are committed for that post attempt
