# Produced Beer Inventory Management Page Specification

## Purpose
- Move the packaged beer inventory section out of the `ProducedBeer` page.
- Create a dedicated page named `在庫管理` / `Inventory Management`.
- Place the new navigation item directly under `製造管理` / `Production` in the sidebar.
- Keep the existing movement workflows on `ProducedBeer` focused on transfer and tax-related records.

## Scope
- Frontend only.
- Reuse the current produced-beer inventory query and table presentation.
- Do not change the inventory calculation source tables or movement behavior.

## Navigation Changes
- Add a new route for the inventory page.
- Add a new sidebar child item under `sidebar.items.production`.
- Position the new item immediately after the existing batch-related items under `製造管理`.
- Keep `ProducedBeer` under `税務管理` / `Liquor Tax`.

## Page Behavior

### New Page
- Route path: `/producedBeerInventory`
- Route name: `ProducedBeerInventory`
- View component: new page component under `src/views/Pages/`
- Page title:
  - Japanese: `在庫管理`
  - English: `Inventory Management`

### Data Source
- Continue reading packaged beer stock from `inv_inventory`.
- Continue resolving lot, batch, package, UOM, category, and site metadata with the same logic currently used inside `ProducedBeer.vue`.
- Only positive-quantity inventory rows are displayed.

### UI
- Keep the existing page shell style:
  - `AdminLayout`
  - `PageBreadcrumb`
  - top-level refresh action
- Keep the current inventory table columns:
  - Lot No
  - Batch No
  - Beer Category
  - Target ABV
  - Style Name
  - Package Type
  - Production Date
  - Qty (L)
  - Qty (Packages)
  - Site
- Keep the existing empty state and refresh behavior.

## ProducedBeer Page Changes
- Remove the inventory section from `ProducedBeer.vue`.
- Remove inventory loading from the page-level refresh action.
- Keep movement filters, cards, CSV export, and create/edit flows unchanged.

## Implementation Notes
- Prefer extracting shared inventory-loading logic into a reusable composable instead of duplicating the fetch code.
- Reuse existing locale keys for inventory table labels where possible.
- Add new locale keys only for:
  - the new page title/subtitle
  - the new sidebar label if a distinct label is needed

## Acceptance Criteria
1. `在庫管理` appears in the sidebar directly under `製造管理`.
2. Clicking `在庫管理` opens a dedicated page showing the same produced-beer inventory table previously shown on `ProducedBeer`.
3. `ProducedBeer` no longer renders the inventory section.
4. `ProducedBeer` still supports movement listing, filtering, export, and creation flows.
5. The new page and existing movement page both load successfully without TypeScript or build regressions.
