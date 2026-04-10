## Purpose
- Maintain `type_def` tree data across domains.
- Maintain attribute-set assignments for each selected type.
- Provide a read-only view of the assigned attribute definitions for the selected type.
- Support multilingual naming and explicit sort-order management.

## Entry Points
- システムメンテナンス → 種別管理
- Route: `/materialTypeMaster`

## Users and Permissions
- Tenant User:
  - can create tenant-scope types
  - can edit tenant-scope types
  - can delete tenant-scope types
  - can assign and unassign attribute sets to tenant types
- Tenant Admin:
  - same as tenant user
  - can edit/delete `scope = 'system'` rows

## Page Layout
### Header
- Title: `種別管理`
- Subtitle: selected domain type tree and attribute-set assignments are maintained here.
- Action:
  - Refresh

### Top Section
- Domain selector area displayed above the main two-column layout
- Controls:
  - Domain dropdown
  - Add domain button
- Behavior:
  - when the selected domain changes, the page reloads the current tree and attribute content for that domain

### Body
- Two-column layout on large screens
- Left panel:
  - type tree for the selected domain
  - expand / collapse control
  - drag-and-drop reorder within the same parent level
- Right panel:
  - selected type summary
  - action buttons
  - assigned attribute-set chips
  - attribute table

### Dialogs
- Type create/edit dialog
- Type delete confirmation dialog
- Attribute-set assignment dialog
- Add-domain dialog

## Domain Selector
### Data Source
- Domain list comes from distinct `type_def.domain` values visible to the current tenant.
- The dropdown must include built-in options even when no rows exist yet:
  - `material_type`
  - `equipment_type`

### Display
- Dropdown shows friendly labels for known domains.
- Examples:
  - `material_type` => `material`
  - `equipment_type` => `equipment`
- Unknown domains fall back to the raw domain code.

### Add Domain
- Because there is no separate domain master table in the current schema, adding a domain means creating the first/root `type_def` row for that domain.
- Add-domain dialog fields:
  - domain code
  - root code
  - 日本語名
  - English Name
- On save:
  - create the root `type_def` row for the new domain
  - add the domain to the dropdown
  - select it
  - reload current contents

## Data Sources
### Type tree
- Table: `type_def`
- Filters:
  - `domain = selected domain`
  - `industry_id = resolved industry`
- Sorting:
  - `sort_order` ascending
  - `code` ascending

### Candidate attribute sets
- Table: `attr_set`
- Filters:
  - `industry_id = resolved industry`
  - `is_active = true`
  - domain should be relevant to the selected `type_def.domain`

### Domain-to-attribute-set mapping
- For selected domain `material_type`, candidate `attr_set.domain` should be `material`.
- For selected domain `equipment_type`, candidate `attr_set.domain` should be `equipment`.
- For unknown domains, default behavior is:
  - first try the exact selected domain
  - if it ends with `_type`, also allow the base domain without `_type`

### Assigned attribute sets
- Table: `entity_attr_set`
- Filters:
  - `entity_type = selected domain`
  - `entity_id = selected type_id`
  - `is_active = true`

### Attribute rows
- Table: `attr_set_rule`
- Joined table: `attr_def`
- Filters:
  - `attr_set_id in assigned attr_set_id list`
- Sorting:
  - `sort_order` ascending

## Industry Resolution
- First choice:
  - active `industry` row where `code = 'CRAFT_BEER'`
- Fallback:
  - first active `industry` row ordered by `sort_order`

## Root Type Behavior
- If no rows exist for the selected domain and industry, the page may create a root row when required by the current create/add-domain flow.
- Root defaults depend on selected domain.
- For known domains:
  - `material_type`
    - `code = 'material'`
    - `name = 'Material'`
    - `name_i18n = {"ja":"原材料","en":"Material"}`
  - `equipment_type`
    - `code = 'equipment'`
    - `name = 'Equipment'`
    - `name_i18n = {"ja":"設備","en":"Equipment"}`

## Tree Panel
- Tree nodes are built from `parent_type_id`.
- Node label:
  - display `name_i18n.ja` in Japanese UI when available
  - otherwise fall back to `name`
  - otherwise `code`
- Tree behavior:
  - all nodes expanded after load
  - user can toggle a single node
  - user can expand all / collapse all
  - user can drag and drop sibling nodes to change their display order
- Selecting a node loads the assigned attribute sets and attribute rows for that type.

## Sort Order Drag And Drop
- Drag-and-drop is used to reorder types within the same parent node.
- Drag-and-drop does not change `parent_type_id`.
- On drop:
  - the UI recalculates sibling order
  - `sort_order` values are rewritten to reflect the new order
- Recommended persisted ordering rule:
  - assign sequential values such as `10, 20, 30...`

## Selected Type Summary Panel
- Shows:
  - selected type display name
  - selected type code
  - selected domain
- Buttons:
  - 子種別を追加
  - 編集
  - 属性セット管理
  - 削除
- Buttons are disabled when no type is selected.

## Create / Edit Type
### Create
- Opens modal in create mode.
- Default `parent_type_id` is the currently selected type.
- New rows are created in the currently selected domain.

### Edit
- Opens modal in edit mode with selected row values.

### Editable Fields
- `code` required
- `日本語名` required
- `English Name` required
- `parent_type_id`
- `sort_order`
- `is_active`

### Name Storage Rules
- The page stores multilingual names in `type_def.name_i18n`:
  - `ja = 日本語名`
  - `en = English Name`
- The page also keeps `type_def.name` populated for compatibility.
- Canonical `name` write rule:
  - use `日本語名` if present
  - otherwise use `English Name`

### Save Rules
- Create:
  - insert into `type_def`
- Edit:
  - update selected `type_def` row by `type_id`
- Written values on create:
  - `tenant_id = current tenant`
  - `domain = selected domain`
  - `industry_id = resolved industry`
  - `scope = 'tenant'`
  - `owner_id = tenant_id`
  - `name`
  - `name_i18n`

## Delete Type
- Delete action opens confirmation dialog with selected type display name or code.
- Confirm:
  - delete from `type_def` by `type_id`
- After delete:
  - clear current selection
  - reload tree
  - reload attribute area

## Attribute-Set Assignment
### Assignment Dialog
- Opens when user clicks `属性セット管理`.
- Shows eligible `attr_set` rows as a checkbox list for the selected domain mapping.
- Each row shows:
  - `name`
  - `code`
  - `domain`

### Save Behavior
- Differential update:
  - `toAdd = desired - current`
  - `toRemove = current - desired`
- Add:
  - insert rows into `entity_attr_set`
- Remove:
  - delete matching rows from `entity_attr_set`
- Assignment keys:
  - `entity_type = selected domain`
  - `entity_id = selected type_id`

## Attribute Table
- The table is built from assigned `attr_set_rule` rows joined to `attr_def`.
- One row is shown per assigned rule.
- Visible columns:
  - 属性セット
  - コード
  - 名称
  - データ型
  - 必須
  - UIセクション
  - UIウィジェット
  - 有効

## Permission Rules
- `tenant_id` is resolved from the authenticated user session.
- `isAdmin` is derived from session metadata:
  - `app_metadata.is_admin`
  - `user_metadata.is_admin`
  - or role `admin`
- If `scope = 'system'`:
  - edit/delete allowed only for admin
- If `scope = 'tenant'`:
  - edit/delete allowed

## Current Target Limitations
- The page assigns attribute sets, but does not edit actual attribute values in `entity_attr`.
- The page does not resolve inherited attribute sets from parent types.
- The page does not merge duplicate `attr_id` rows across multiple assigned sets.
- Drag-and-drop reorder is limited to sibling sort-order changes and does not include reparenting.

## Data Handling Summary
- Read:
  - `industry`
  - `type_def`
  - `attr_set`
  - `entity_attr_set`
  - `attr_set_rule`
  - `attr_def`
- Write:
  - `type_def`
  - `entity_attr_set`

## Other
- This document is the implementation-target spec for the next `種別管理` changes.
- Existing screens that currently read `type_def.name` should continue to work because `name` remains populated alongside `name_i18n`.
