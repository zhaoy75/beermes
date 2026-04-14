# Produced Beer Unpacking UI Specification

## Purpose
- Register dismantling of packaged beer back into bulk beer.
- Use packaged inventory as the starting point.
- Keep the workflow separate from the generic beer movement wizard.

## Entry Point
- From `在庫管理` row action: `解体`
- The action opens a dedicated page:
  - `/producedBeerInventory/unpack/:lotId`

## Page Role
- This page is an input page, not a list page.
- It handles only unpacking registration.
- It does not replace batch packing history or inventory list pages.

## Read-Only Source Summary
- lot code
- batch code
- beer / style
- package type
- current qty
- current site

## Input Fields
- unpack quantity
- uom
- destination site
- destination tank
- target batch
- loss qty
- reason
- memo

## Validation
- unpack quantity must be positive and not exceed current available qty
- destination site must be manufacturing-side bulk destination in phase 1
- target batch is required
- loss qty must be zero or positive
- destination tank is optional in phase 1

## Save Behavior
- UI calls:
  - `public.product_unpacking(p_doc jsonb)`
- UI must not update `lot` or `inv_inventory` directly
- backend writes packing-history-compatible metadata with `packing_type = unpack`
- On success:
  - show success notice
  - return to inventory page

## Integration Rules
- Inventory page is the launcher
- Batch Packing page is the history consumer
- Movement wizard is not used for unpacking

## Non-Goals
- package-material recovery
- bulk multi-source merge in phase 1
- inventory-grid inline edit implementation
