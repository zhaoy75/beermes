## Purpose
- Maintain `mst_sites` master data.
- Maintain site tree relationship (`parent_site_id`) for location/site hierarchy.
- Clearly distinguish own company site vs outside company site.

## Entry Points
- マスターメンテナンス → サイト管理

## Users and Permissions
- Tenant User: edit all `mst_sites` records in the tenant.

## Page Layout
### Header
- Title: サイト管理

### Body
- 2-panel layout
- Left panel: site tree + search + add/delete
- Right panel: site detail edit form

### Modal Dialog
- Address input dialog (common dialog; rule from `registry_def.kind = 'address_rule'`)

## Field Definitions
### Site tree panel (left)
- Search filters:
    - `code` (partial match)
    - `site_type_id` (`registry_def.kind = 'site_type'`)
    - `owner_type` (Own company / Outside company)
- Action buttons:
    - Add Location
    - Add Site
    - Delete
- Tree:
    - Virtual root node: `サイトルート`
    - Node label: `name (code)`
    - Parent-child relation by `parent_site_id`
    - Sort order in same parent:
    - `sort_order` ascending, then `code` ascending

### Site information edit panel (right)
- `code` (required, unique per tenant)
- `name` (required)
- `site_type_id` (required, dropdown from `registry_def.kind = 'site_type'`)
- `parent_site_id` (not editable tree relationship parent; selected node is default parent)
- `node_kind` (required, default `SITE`)
- `owner_type` (required, default `OWN`)
- `OWN`: own company
- `OUTSIDE`: outside company
- `owner_name` (text, outside company name)
- `sort_order` (integer, required, default `0`)
- `address` (edit by common address dialog)
- `notes`

## Action
### Add button
- Add child node under currently selected tree node.
- If virtual root is selected, create top-level node (`parent_site_id = null`).
- For create mode defaults:
- `node_kind = 'SITE'`
- `owner_type = 'OWN'`
- `sort_order = 0`

### Delete button
- Delete selected node and descendant nodes.

## Business Rules
- `owner_type` must be selected.
- When `owner_type = 'OUTSIDE'`, `owner_name` is required.
- When `owner_type = 'OWN'`, `owner_name` is optional (normally blank).
- Tree structure must be maintained by `parent_site_id` for site hierarchy.
- UI must show ownership clearly so users can identify own-company vs outside-company sites.

## Data Handling
- Main table: `mst_sites`
- Site type master: `registry_def` with `kind = 'site_type'`
- `mst_sites` columns used on this page:
- Existing: `code`, `name`, `site_type_id`, `parent_site_id`, `address`, `contact`, `notes`, `active`
- Added:
- `node_kind text not null default 'SITE'`
- `owner_type text not null default 'OWN'`
- `owner_name text null`
- `sort_order int4 not null default 0`

## Other
- This page must support multilanguage (English/Japanese).
