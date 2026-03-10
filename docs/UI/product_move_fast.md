# ProductMoveFast Page UI Specification

## Purpose
- Register beer `INTERNAL_TRANSFER` movements on a dedicated high-speed page.
- Minimize clicks for repetitive internal logistics entry.
- Support keyboard-first operation and paste-based multi-line input.
- Prevent route misuse for tax-sensitive site combinations.
- Default to backend auto lot allocation using `FEFO`.
- Ensure posting is atomic (all-or-nothing) even when one UI line is split into multiple lot-level movements.
- Allow all tax movement outcomes derived by rule engine, as long as `movement_intent` is `INTERNAL_TRANSFER`.

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
- route & summary section used 2 areas 
 - Left
   - Sticky route bar under header.
   - Recent / Favorites
 - Right:
   - Summary / Validation
- Main body 
   Fixed Input Area (`keyword`, `package`, `amount`)
   Lines Grid
 

### Modal/Dialog
- No modal in standard flow.
- Minimal modal or side drawer may be used only for `MANUAL` lot allocation.
- Inventory search shortcut modal may be opened for source-lot lookup.

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

- Behavior:
  - `From Site` dropdown must be filtered to site types allowed as `allowed_src_site_types` for `INTERNAL_TRANSFER`
  - `To Site` dropdown must be filtered to site types allowed as `allowed_dst_site_types` for `INTERNAL_TRANSFER`
  - when `From Site` is selected, UI loads source-site inventory and lot candidates for line entry
  - when `From Site` is selected and inventory shortcut modal is opened, modal result must be limited to lots in the selected `From Site`
  - route values persist after successful `Post` and `Post & Next`
  - block when `From Site = To Site`
  - swap button exchanges From/To site values
  - once From/To site is chosen, UI evaluates the rule engine and shows:
    - fixed `movement_intent = INTERNAL_TRANSFER`
    - derived tax movement type / tax event
    - default `tax_decision_code`
  - UI must call Supabase RPC `movement_get_rules` with `p_movement_intent = 'INTERNAL_TRANSFER'`
  - if multiple tax decisions are allowed for the resolved `INTERNAL_TRANSFER` route, UI shows selectable tax decision list and defaults to the rule default
  - default focus after page load is `keyword` field in fixed input area, not route bar
  - click favorites button adds current route to favorites

### Recent / Favorites Panel
- Shows recently used routes for the current user.
- Supports favorite route presets.
- Item layout:
  - desktop/tablet: items are arranged in 2 columns
  - mobile: items are stacked in 1 column
- Each item shows at minimum:
  - From site
  - To site
- Clicking an item applies route bar values without posting.
- Recent routes are updated only after successful post.

### Fixed Input Area (`keyword`, `package`, `unit`, `volume`)
- A fixed input area is displayed above Lines Grid.
- Fields:

| Field | Required | Notes |
| --- | --- | --- |
| Keyword | Yes | Beer lookup key (code/name/style/etc.) |
| Package | Conditional | Optional filter; required when multiple package candidates must be disambiguated |
| Unit    | Conditional | Input quantity for line creation (`> 0`) |
| Volume (L)  | Conditional | (package * unit) with uom conversion or  volume |

- Keyword behavior:
  - when user put cursor on keyword field, show suggestion list of beer in inventory
    - beer name, style name, package, unit 
  - exact code
  - partial code
  - name match
  - suggestion list must include beer basic info and related `entity_attr` fields
  - suggestion display should include beer code and name at minimum
- Enter behavior (`keyword` + `amount`, and `package` when needed):
  - resolve beer/package from source-site inventory context
  - apply current `allocation_policy`
  - `FEFO`/`FIFO`: allocate lots automatically and split quantity across multiple lots when one lot is insufficient
  - `MANUAL`: open lot selection UI and add line(s) after lot selection is confirmed
  - append resulting row(s) to Lines Grid
  - if source-site stock is insufficient for requested amount, do not append rows and show error

### Inventory Shortcut Modal Integration
- Shortcut: `Ctrl + I` / `Command + I`
- If `From Site` is selected, open inventory modal in source-site scoped mode.
- In source-site scoped mode:
  - modal site filter is set from current `From Site`
  - modal result grid must show only lots in current `From Site`
  - user cannot broaden the result outside the selected `From Site`
- On result row double-click:
  - close the modal
  - set fixed input area `keyword` from the selected lot identifier (`lot_no` as primary display value)
  - set fixed input area `package` from the selected lot package
  - move focus to fixed input area `unit`
  - do not append a line automatically until quantity is entered and confirmed

### Paste Input
- User can paste multiple lines into `keyword` input.
- Example:

```text
IPA01 50
PILS02 20
STOUT03 10
```
- System behavior:
  - parse each line as `keyword + amount` (optional package token can be supported)
  - create rows automatically
  - resolve beer/package candidates against source-site inventory
  - apply allocation policy (`FEFO`/`FIFO` auto split; `MANUAL` requires lot selection)
  - leave unresolved rows highlighted for correction


### Lines Grid
- Default state:
  - 5 empty rows
  - first `keyword` field in fixed input area focused
  - Quantity input should be sized for typical entry around 4 integer digits plus decimal precision, without wasting horizontal space
- Columns:

| Column | Required | Notes |
| --- | --- | --- |
| Beer | Yes | Search by beer code or name |
| Lot No | Conditional | Required only for `MANUAL`; read-only/auto for `FEFO` and `FIFO` |
| Package Info | Conditional | only if package is choosen |
| Unit         | Conditional | package unit or qty        |
| Volume (L) | Yes | Numeric, `> 0`; width should comfortably fit values in the range of `9999.999` but stay visually compact |
| Note | No | Line note |

- Row behavior:
  - main add flow is fixed input area + `Enter`
  - when allocation splits requested amount across lots, grid receives multiple rows (one row per lot segment)
  - grid rows remain editable for note and quantity correction before posting
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
  - focus `keyword` field in fixed input area
- `Swap`
  - exchange From Site and To Site
  - immediately re-run route validation
- `Apply Recent/Favorite`
  - copy saved route into route bar
- Keyboard shortcuts:

| Key | Action |
| --- | --- |
| `/` | Focus `keyword` input in fixed input area |
| `Enter` | In fixed input area: allocate and append line(s); in grid: move to next editable cell |
| `Ctrl+Enter` | Post |
| `Shift+Enter` | Post & Next |
| `Ctrl+I` | Open inventory shortcut modal; when `From Site` is selected, modal is scoped to that site |

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
  - taxable/non-taxable/tax-storage-related tax movement results are all allowed when resolved under `INTERNAL_TRANSFER`
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
  - at line-entry stage, requested amount must be allocated from source-site inventory based on allocation policy
  - if one lot is insufficient, allocation must continue from the next eligible lot
  - if package is specified, allocation candidates must be filtered by package first
  - in `MANUAL`, selected lot must belong to the selected beer and source site
  - in `MANUAL`, selected lot available quantity must be `>=` line quantity
  - inventory shortcut modal selection must also be restricted to the current source site when `From Site` is selected
- Soft warnings:
  - low available stock
  - allocation split across many lots
  - near-expiry lots included in allocation
- Route validation reason codes:
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
  "unit": 100,
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

- Lot-level `product_move` payload rules:
  - include `unit` when the UI line was entered as package count and the allocated segment keeps a known unit count
  - do not include `tax_rate`
  - `tax_rate` must be derived in `public.product_move`
  - if derived `tax_event <> 'TAXABLE_REMOVAL'`, stored `tax_rate` must be `0`
  - only when derived `tax_event = 'TAXABLE_REMOVAL'`, `product_move` resolves tax master from batch attr `beer_category` and `movement_at`

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
  - `Post & Next`: clear lines and return focus to `keyword` field
- On error:
  - show inline row errors when possible
  - show global error summary for post failure

## Data Handling
- Master/reference data:
  - site list from site master
  - beer/product search source with code and localized name
  - source-site inventory/lot candidates loaded after `From Site` selection
  - keyword suggestion payload includes beer basic information and relevant `entity_attr` fields
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
  - line entry attempted before selecting From Site
  - same source and destination
  - no valid `INTERNAL_TRANSFER` rule for selected route
  - tax decision required but not selected
  - no valid lines
  - quantity `<= 0`
  - package required for candidate disambiguation but not selected
  - invalid site combination for `INTERNAL_TRANSFER`
  - unresolved beer code/name
  - requested amount exceeds allocatable source-site stock
  - `MANUAL` selected but `Lot No` missing for any valid line
  - selected lot does not match beer/source site
  - selected lot has insufficient available quantity
  - backend transaction failed; no movements committed
- Soft warnings:
  - low stock
  - many-lot split
  - near expiry
- Route/rule message must be explicit:
  - if route has no matching `INTERNAL_TRANSFER` rule, UI must explain that the selected site combination is not allowed
  - do not block route only because derived tax movement type is taxable/tax-storage-related

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
- Fixed input line creation:
  - Given `From Site` is selected and inventory is loaded
  - When user inputs `keyword`, `amount`, and presses `Enter`
  - Then system allocates by policy and appends row(s) to Lines Grid
- Multi-lot split on line entry:
  - Given one lot is insufficient for requested amount
  - When allocation policy is `FEFO` or `FIFO`
  - Then system continues allocation from next eligible lot and appends split rows
- Keyword suggestion:
  - Suggestion list includes beer basic info and `entity_attr`
- Inventory shortcut modal:
  - Given `From Site` is selected
  - When user presses `Ctrl + I`
  - Then inventory modal opens and shows only lots from the selected `From Site`
- Inventory shortcut row selection:
  - Given ProductMoveFast inventory modal is open
  - When user double-clicks one lot row
  - Then modal closes, `keyword` and `package` are filled from the selected lot, and focus moves to `unit`
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
  - Route with valid `INTERNAL_TRANSFER` rule is allowed regardless of derived tax movement type
  - Unmapped route must return `ROUTE_NO_INTERNAL_TRANSFER_RULE`
- Atomicity:
  - If one segment fails during backend execution
  - Then zero movement rows are committed for that post attempt
