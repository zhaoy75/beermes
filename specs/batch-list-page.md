# Batch List Page

## Goal
- Define the concrete target behavior for the batch list page.
- Make the page useful for both:
  - planning/releasing batches
  - monitoring released recipe and execution progress

## Route / Entry Point
- Primary route: `/batches`
- Entry point: 製造管理 -> バッチ管理

## Purpose
- Search and browse batches.
- Create a new batch, with or without a base recipe.
- Show enough recipe release information and execution status to decide which batch to open next.

## Users
- Tenant User
- Admin

## Page Layout
- Section 1: Search Panel
- Section 2: Batch Table
- Modal: Batch Create Dialog

## Section 1: Search Panel

### Purpose
- Filter batches by basic schedule/status conditions and batch attributes.

### Fields
- batch name / memo
- status
- planned start from
- planned start to
- dynamic attribute filters from batch `attr_set`

### Rules
- default planned start from = two months before today
- `planned start from` and `planned start to` must use the shared Flatpickr date picker
- `planned start from` and `planned start to` are date-only `YYYY-MM-DD` values
- `planned start to` is inclusive for the whole selected day and should be implemented as `< next day`
- dynamic batch attribute filters follow `attr_def` data type behavior
- date dynamic batch attribute filters use `entity_attr.value_date` and remain `YYYY-MM-DD`
- numeric dynamic batch attribute filters must validate entered values against `attr_def.num_min` / `attr_def.num_max`
- invalid numeric batch attribute filters should show inline error text and should not be applied until corrected
- filter values are optional

## Section 2: Batch Table

### Purpose
- Show each batch as a combined planning + execution card in table form.
- Use the same compact table density as the `移入出登録` movement table.

### Required Columns
- `batch_code`
- `batch_label` or visible batch name
- `status`
- `planned_start`
- `planned_end`
- `recipe_name`
- `recipe_version`
- `product_name`
- `step_progress`
- `current_step`
- `alerts`
- `actions`

### Column Definitions

#### recipe_name
- source:
  - `public.mes_batches.released_reference_json.recipe_name`
  - fallback: `public.mes_batches.product_name`
  - fallback: blank
- if no recipe is attached, show `—`

#### recipe_version
- source:
  - `public.mes_batches.released_reference_json.version_no`
  - `public.mes_batches.released_reference_json.version_label`
- format:
  - `v{version_no}`
  - if `version_label` exists, append it
- if no recipe is attached, show `—`

#### step_progress
- source: `mes.batch_step`
- value:
  - `{completed_count} / {total_count}`
- total_count = number of released step rows for the batch
- completed_count = number of rows where status = `completed`
- if batch has no released steps, show `0 / 0`

#### current_step
- source: `mes.batch_step`
- priority order:
  - first `in_progress`
  - else first `ready`
  - else first `open`
  - else last incomplete step
  - else `Completed`
- display:
  - `step_name`
  - optional badge of current step status

#### alerts
- compact status indicators
- recommended indicators:
  - hold step exists
  - open deviation exists
  - overdue planned end
  - no recipe attached

### Actions
- edit
- delete

### Row Click
- clicking the batch name or edit opens batch edit page

### Current UI Adjustment
- The first visible column title should be `バッチコード`, not `名称`.
- The first visible column value should display `batch_code`.
- Apply compact table styling consistent with `移入出登録`:
  - `compact-table`
  - `text-xs`
  - reduced header/body padding
- Keep existing sorting, search, row actions, and data loading behavior.
- Use clickable column headers with sort/filter popovers consistent with `移入出登録`.
- Add row checkboxes and a visible-row select-all checkbox.
- Do not add a bulk delete action in this change.

## Batch Create Dialog

### Purpose
- Create a batch header quickly.
- Optionally attach and release a recipe at creation time.

### Fields
- base recipe
- batch code
- planned start
- planned end
- notes
- configured batch attributes from active batch `attr_set`

### Base Recipe
- optional
- development-mode only until recipe functions are production-ready
- when `VITE_DEVELOPMENT_MODE` is disabled:
  - hide the recipe selector
  - do not query recipe options
  - submit a blank recipe id and create a header-only batch
- data source:
  - `mes.mst_recipe`
  - current version via `mes.mst_recipe.current_version_id`
- display label:
  - `recipe_name (recipe_code) / v{version_no}`

### Batch Attributes
- source:
  - active `attr_set` rows where `domain = 'batch'`
  - active `attr_set_rule`
  - active `attr_def`
- display labels follow `attr_def.name_i18n` for the current locale, then `name`, then `code`
- create-dialog fields are optional for now; do not enforce `attr_set_rule.required` or `attr_def.required` during batch creation
- input control follows `attr_def.data_type`:
  - `number`: numeric input with configured min/max
  - `bool`: checkbox
  - `date`: shared Flatpickr date picker
  - `timestamp`: shared Flatpickr date-time picker
  - `json`: textarea with JSON validation
  - `ref`: select from configured reference options
  - text/enum: text input, with allowed-value validation when configured
- after batch creation:
  - assign active batch attr sets to `entity_attr_set`
  - upsert non-empty values into `entity_attr`
  - leave empty optional values absent from `entity_attr`

### Rules
- recipe is nullable
- `planned start` and `planned end` must use the shared Flatpickr date picker, not native `input[type="date"]`, so blank dates render blank consistently in Safari and Chrome
- `planned start` and `planned end` are date-only `YYYY-MM-DD` values and should not show or save time
- blank planned start and planned end values submit `null`
- date attributes in the create dialog are saved to `entity_attr.value_date` as `YYYY-MM-DD`
- if recipe is selected:
  - call `create_batch_from_recipe`
  - released recipe info and step rows are created
- if recipe is blank:
  - call `create_batch_from_recipe`
  - header-only batch is created
- batch code may be blank in UI
  - if blank, UI auto-generates

## Data Sources
- batch header:
  - `public.mes_batches`
- released recipe display:
  - `public.mes_batches.released_reference_json`
  - `public.mes_batches.recipe_version_id`
- execution summary:
  - `mes.batch_step`
- batch attributes:
  - `entity_attr`
  - `attr_set`
  - `attr_set_rule`
  - `attr_def`
- create dialog recipe list:
  - `mes.mst_recipe`
  - `mes.mst_recipe_version`
- create dialog attribute input:
  - `attr_set`
  - `attr_set_rule`
  - `attr_def`
  - `entity_attr_set`
  - `entity_attr`

## Business Rules
- batch delete remains blocked for normal users when status is `in_progress` or `completed`
- blocked delete feedback from row actions should use multilingual toast messaging, not browser `window.alert`
- batch list should not query legacy `public.mes_recipes`
- batch list should not query legacy `public.mes_batch_steps` for execution progress
- execution progress must use `mes.batch_step`

## Recommended Visual Design
- keep table layout
- add compact badges for batch status and alerts
- keep step progress as text first
- optionally add a thin inline progress bar beside `step_progress`

## Open Decisions

### 1. Progress Visualization
- Option A:
  - text only: `2 / 5`
- Option B:
  - text + small progress bar
- Recommended:
  - Option B

### 2. Alerts 
- Option A:
  - text labels such as `Hold`, `Deviation`
- Option B:
  - icon/dot badges only
- Recommended:
  - Option A for initial release because it is easier to read

### 3. Recipe-less Batch Labeling
- Option A:
  - show blank recipe columns
- Option B:
  - show a visible badge such as `No Recipe`
- Recommended:
  - Option B in alerts column while keeping recipe columns as `—`
