# ProductMoveFast Page UI Specification

## Purpose
- Register beer `INTERNAL_TRANSFER` movements on a dedicated high-speed page.
- Minimize clicks for repetitive internal logistics entry.
- Support keyboard-first operation and paste-based multi-line input.
- Prevent route misuse for tax-sensitive site combinations.
- Default to backend auto lot allocation using `FEFO`.

## Entry Points
- Produced Beer page -> action button: `ProductMoveFast` / `社内移動(高速入力)`
- Optional shortcut from movement list for users who repeatedly post `INTERNAL_TRANSFER`
- Route: `/producedBeerMovementFast`

## Users and Permissions
- Tenant User: create internal transfer movements in tenant scope.
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
- Sticky route bar under header.
- Main body uses 3 areas on desktop and stacked layout on mobile:
  - Left: Recent / Favorites
  - Center: Lines Grid
  - Right: Summary / Validation

### Modal/Dialog
- No modal in standard flow.
- Minimal modal or side drawer may be used only for `MANUAL` lot allocation.

## Field Definitions
### Route Bar
- Fields:

| Field | Required | Default | Notes |
| --- | --- | --- | --- |
| From Site | Yes | Last used | Must be internal site |
| To Site | Yes | Last used | Must be internal site |
| Movement Date | Yes | Now | User editable |
| Allocation Policy | Yes | `FEFO` | `FEFO`, `FIFO`, `MANUAL` |
| Note | No | Empty | Header note for movement |

- Behavior:
  - route values persist after successful `Post` and `Post & Next`
  - block when `From Site = To Site`
  - swap button exchanges From/To site values
  - route must remain valid for `INTERNAL_TRANSFER`
  - default focus after page load is first Beer field in Lines Grid, not route bar

### Recent / Favorites Panel
- Shows recently used routes for the current user.
- Supports favorite route presets.
- Each item shows at minimum:
  - From site
  - To site
  - Last used date or favorite marker
- Clicking an item applies route bar values without posting.
- Recent routes are updated only after successful post.

### Lines Grid
- Default state:
  - 5 empty rows
  - first Beer field focused
- Columns:

| Column | Required | Notes |
| --- | --- | --- |
| Beer | Yes | Search by beer code or name |
| Quantity (L) | Yes | Numeric, `> 0` |
| Note | No | Line note |

- Row behavior:
  - selecting a beer moves focus to Quantity
  - pressing `Enter` in Quantity moves to next editable row
  - empty trailing rows should be auto-added as needed
  - rows with no beer and no quantity are ignored

### Beer Search
- Search modes:
  - exact code
  - partial code
  - name match
- `Enter` selects top result when suggestion list is open.
- After beer selection, focus moves to Quantity.
- Search result should display code and name together.

### Paste Input
- User can paste multiple lines into the first Beer cell or dedicated paste target.
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

### Summary / Validation Panel
- Always visible.
- Shows:
  - selected route summary
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
- This page is intentionally narrower than the generic movement wizard:
  - allowed page routes:
    - `BREWERY_MANUFACTUR -> BREWERY_STORAGE`
    - `BREWERY_STORAGE -> BREWERY_MANUFACTUR`
    - `BREWERY_STORAGE -> BREWERY_STORAGE`
    - `BREWERY_MANUFACTUR -> BREWERY_MANUFACTUR` only within same permit scope
  - blocked on this page:
    - any route to `DIRECT_SALES_SHOP`
    - any route to `TAX_STORAGE`
- When user selects a blocked route, show guidance to use the correct movement intent/page instead:
  - `DIRECT_SALES_SHOP`: use domestic shipment / `課税移出`
  - `TAX_STORAGE`: use tax-specific movement flow
- `From Site` and `To Site` are required.
- `From Site` must not equal `To Site`.
- At least one valid line is required.
- Quantity must be greater than `0`.
- Beer is identified by code or name, but backend resolution must use stable beer/product id before posting.
- Allocation rules:
  - `FEFO` or `FIFO`: backend auto-allocates lots
  - `MANUAL`: user must select lots before posting
- Soft warnings:
  - low available stock
  - allocation split across many lots
  - near-expiry lots included in allocation

## Save Behavior
- Disable `Post` actions while submitting.
- UI must submit a line-based payload and must not allocate lots on the client for `FEFO` or `FIFO`.
- Recommended backend entry point:
  - `public.product_move_fast(p_doc jsonb)`
- If backend implementation delegates to `public.product_move(p_doc jsonb)`, lot splitting/allocation must still be handled server-side.
- Request payload example:

```json
{
  "movement_intent": "INTERNAL_TRANSFER",
  "from_site_id": "11111111-1111-1111-1111-111111111111",
  "to_site_id": "22222222-2222-2222-2222-222222222222",
  "moved_at": "2026-03-03T12:00:00+09:00",
  "allocation_policy": "FEFO",
  "note": "daily internal transfer",
  "lines": [
    { "beer_code": "IPA01", "qty_l": 50.0, "note": "" },
    { "beer_code": "PILS02", "qty_l": 20.0, "note": "priority order" }
  ]
}
```

- Backend responsibilities:
  - validate route rules
  - validate stock
  - allocate lots
  - create movement header and lines
  - create lot/inventory changes
  - return `movement_id`
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
  - site list from site master, filtered to internal sites valid for this page
  - beer/product search source with code and localized name
- User preference data:
  - last used route
  - recent routes
  - favorite routes
- Derived UI state:
  - route validity
  - total entered liters
  - line-level validity
  - warning summary
- Page should preserve unsaved line input during temporary fetch refreshes where possible.

## Error Handling
- Hard-block errors:
  - missing From Site
  - missing To Site
  - same source and destination
  - no valid lines
  - quantity `<= 0`
  - invalid site combination for this page
  - unresolved beer code/name
- Soft warnings:
  - low stock
  - many-lot split
  - near expiry
- Route-specific message must be explicit:
  - destination `DIRECT_SALES_SHOP`: "Use domestic shipment flow"
  - destination `TAX_STORAGE`: "Use tax-specific movement flow"

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
