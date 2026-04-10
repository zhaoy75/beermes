## Purpose
- Maintain `attr_set` master data in the system-admin area.
- Build and save `attr_set_rule` membership and per-rule UI metadata.
- Provide a palette-driven workflow for composing a set from active attribute definitions.
- Preview the resulting form fields from the selected set.

## Entry Points
- System admin route: `/system-admin/attr-sets`
- Legacy redirect: `/attrSetMaster` -> `/system-admin/attr-sets`

## Users and Permissions
- Route access is restricted to system admin users by [system-routes.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/router/system-routes.ts#L64).
- The page still resolves tenant/session metadata and applies row-level edit guards.
- `canEdit(row)` behavior:
  - `scope = 'system'`: editable only when `auth.isSystemAdmin` or resolved `isAdmin` is true
  - other scopes: editable
- In practice, the route already limits entry to system admin users.

## Page Layout
### Header
- Title: `属性セット管理`
- Subtitle: attribute sets are built by dragging from the palette.
- Actions:
  - `新規`
  - `更新`

### Filter Bar
- A domain dropdown is shown above the main body.
- Purpose:
  - filter the attribute palette
  - filter the attribute-set list
- Default value:
  - `すべて` / `All`
- Option source:
  - distinct `domain` values found in the currently loaded `attr_def` rows
  - distinct `domain` values found in the currently loaded `attr_set` rows
  - merged and sorted for display

### Main Body
- Two-column layout on large screens.
- Left panel:
  - attribute palette
  - search input
  - grouped draggable attribute definitions
- Right panel:
  - selected set summary card
  - attribute-set card list
  - rules canvas and rules table

### Overlays
- Context menu for a set card
- Set create modal
- Rules dialog
- Preview dialog

## Data Sources
### Attribute Palette
- Table: `attr_def`
- Query:
  - `is_active = true`
- Sorting:
  - `code` ascending
- Selected columns:
  - `tenant_id`
  - `attr_id`
  - `code`
  - `name`
  - `name_i18n`
  - `domain`
  - `data_type`
  - `allowed_values`
  - `scope`

### Attribute Set List
- Table: `attr_set`
- Query:
  - no explicit filter in current source
- Sorting:
  - `code` ascending
- Selected columns:
  - `tenant_id`
  - `attr_set_id`
  - `code`
  - `name`
  - `name_i18n`
  - `domain`
  - `industry_id`
  - `is_active`
  - `scope`
  - `owner_id`

### Rules for Selected Set
- Table: `attr_set_rule`
- Joined table:
  - `attr_def` via `fk_attr_set_rule_attr`
- Filter:
  - `attr_set_id = selectedSetId`
- Sorting:
  - `sort_order` ascending

### Industry Options
- Table: `industry`
- Query:
  - `is_active = true`
- Sorting:
  - `sort_order` ascending

## Palette Behavior
- Palette search matches lowercased concatenated text from:
  - `code`
  - `name`
  - rendered `name_i18n`
- Palette items are grouped by:
  - `domain`
  - normalized `data_type`
- Group label format:
  - `{domain} · {data type label}`
- Data type normalization:
  - `string` -> `text`
  - `boolean` -> `bool`
- Available palette items are filtered by the currently selected set tenant:
  - when a set is selected, only `attr_def` rows with the same `tenant_id` are shown
  - additionally, when a specific domain is selected in the domain dropdown, only matching `attr_def.domain` rows are shown
  - when the domain dropdown is `すべて` / `All`, no domain filter is applied

## Attribute Set List Behavior
- The page loads all `attr_set` rows and shows them as selectable cards.
- When a specific domain is selected in the domain dropdown:
  - only matching `attr_set.domain` rows are shown
- When the domain dropdown is `すべて` / `All`:
  - all loaded `attr_set` rows are shown
- Card content:
  - `domain`
  - `name`
  - `code`
  - industry label
  - active flag
- When the first load returns at least one row and nothing is selected yet:
  - the first set is auto-selected
  - its rules are fetched immediately
- When the user changes the domain filter:
  - if the current selected set still matches the filter, keep it selected
  - if it no longer matches, clear the selection
  - if visible sets remain after filtering, auto-select the first visible set

## Selected Set Summary
- Shows:
  - selected set name
  - selected set code
- Actions:
  - `プレビュー`
  - `保存`
- Buttons are disabled when no set is selected.

## Context Menu
- Available actions on right-click:
  - `編集`
  - `プレビュー`
  - `ルール設定`
  - `保存`
  - `削除`
- `編集` opens the same modal used for `新規`.
- Edit mode preloads:
  - `code`
  - `name`
  - `name_i18n`
  - `domain`
  - `industry_id`
  - `is_active`

## Create Set Modal
### Trigger
- Opened from:
  - header `新規` button in create mode
  - right-click `編集` action in edit mode

### Current Mode
- The modal supports both create mode and edit mode.

### Fields
- `code` required
- `name` required
- `name_i18n` optional JSON object text
- `domain` required
- `industry_id` optional
- `is_active`

### Validation
- `code` required
- `name` required
- `domain` required
- `name_i18n`, when entered, must parse as a JSON object

### Save Behavior
- Create:
  - insert one row into `attr_set`
- Edit:
  - update selected `attr_set` row by `attr_set_id`

### Domain Defaulting
- When `新規` is opened while the page filter is a specific domain:
  - prefill the modal `domain` with the selected filter domain
- When the page filter is `すべて` / `All`:
  - keep the modal `domain` empty until the user enters or selects a value

### Written Values on Create
- `code`
- `name`
- `name_i18n`
- `domain`
- `industry_id`
- `is_active`
- `tenant_id`
- `scope`
- `owner_id`

### Scope Resolution
- If `auth.isSystemAdmin` is true:
  - `tenant_id = SYSTEM_TENANT_ID`
  - `scope = 'system'`
  - `owner_id = null`
- Otherwise:
  - `tenant_id = resolved tenant`
  - `scope = 'tenant'`
  - `owner_id = tenant_id`

## Rule Editing
### Rule Source
- Rules are held in local state per selected set:
  - `rules: Record<number, AttrRuleRow[]>`

### Add Rule
- User drags an attribute from the palette and drops it on the rules canvas.
- If the attribute already exists in the selected set:
  - show `alreadyAdded` toast
  - do not add duplicate rule
- New rules default to:
  - `required = false`
  - `editable = true`
  - `visible = true`
  - `default_value = ''`
  - `is_active = true`
  - `sort_order = current length`

### Remove Rule
- A rule can be removed from the main rules table with the `削除` button.

### Editable Rule Fields
- `required`
- `editable`
- `visible`
- `default_value`

### Rule Ordering
- Chosen attributes are reordered by explicit up/down buttons in the main rules table.
- Left palette drag/drop remains dedicated to adding attributes into the set.
- Button behavior rewrites the current selected-set rule list in the new order.
- After reorder:
  - `sort_order` is reassigned sequentially in local state
  - the table returns to `sort_order` ascending display
- Save persists that current order through `attr_set_rule.sort_order`.

## Save Selected Set
- Triggered from:
  - summary card `保存`
  - context menu `保存`
- Save strategy:
  - delete all existing `attr_set_rule` rows for the selected set
  - insert the full current in-memory rule list
- Written rule fields:
  - `tenant_id`
  - `attr_set_id`
  - `attr_id`
  - `required`
  - `sort_order`
  - `is_active`
  - `meta.editable`
  - `meta.visible`
  - `meta.default_value`

## Delete Set
- Triggered from the context menu.
- Confirmation uses browser `window.confirm`.
- Delete sequence:
  - delete `attr_set_rule` rows by `tenant_id` and `attr_set_id`
  - delete `attr_set` row by `tenant_id` and `attr_set_id`
- After delete:
  - clear `selectedSetId` if the deleted set was selected
  - reload set list

## Preview Dialog
- Triggered from:
  - summary card `プレビュー`
  - context menu `プレビュー`
- Preview includes only rules where `visible = true`.
- Input rendering by normalized data type:
  - `number` -> number input
  - `bool` -> checkbox
  - `enum` -> select from `allowed_values`
  - otherwise -> text input
- `editable = false` disables the preview input.
- `default_value` is shown as placeholder text for non-boolean inputs.

## Refresh Behavior
- `refreshAll()` runs on mount and from the header `更新` button.
- Refresh loads in parallel:
  - `attr_def`
  - `attr_set`
  - `industry`
- After refresh:
  - rebuild the domain dropdown options from the latest `attr_def` and `attr_set` rows
  - preserve the current domain selection when it still exists
  - otherwise reset the domain filter to `すべて` / `All`

## Display Rules
- `name_i18n` is rendered as `key:value` pairs joined by ` · `.
- Industry display:
  - matched industry name when found
  - otherwise raw `industry_id`
  - `null` displays the shared label

## Known Gaps In Current Source
- No additional functional gaps are documented for the current scope of this page.
