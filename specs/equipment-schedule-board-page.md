# Equipment Schedule Board Page

This spec reflects the current board implementation using `vis-timeline`.

## Goal
- Provide a single page to review equipment availability, manage planned reservations, and visualize actual usage across multiple sites.

## Page Name
- Japanese:
  - `設備スケジュール管理`
- English:
  - `Equipment Schedule Board`

## Route
- Recommended:
  - `/equipment-schedule`

## Menu Placement
- recommended sidebar group:
  - `製造管理 / Production`
- recommended order:
  - after `バッチ管理 / Batch List`
  - before `詰口一覧表 / Filling Report`
- rationale:
  - this page is operational scheduling / monitoring, not master maintenance

## Purpose
- Show equipment occupancy over time.
- Create and update planned reservations.
- Visualize actual execution-side usage.
- Block maintenance windows.
- Support multi-site schedule review from one board.

## Core Boundary

### This Page Owns
- schedule-oriented filtering
- reservation create / edit for `mes.equipment_reservation`
- schedule board visualization
- vacancy review

### This Page Does Not Own
- editing execution-side actual equipment usage
- step execution input
- equipment master maintenance
- batch header editing

## Data Sources
- equipment rows:
  - `public.mst_equipment`
- planned / blocking blocks:
  - `mes.equipment_reservation`
- actual usage blocks:
  - `mes.batch_equipment_assignment`

## Layout

### Section 1: Filter Bar
- filters:
  - site
  - equipment type
  - equipment
  - date range
  - view mode (`day` / `week` / `two weeks` / `month`)
- actions:
  - search
  - reset
- recommended additions:
  - `show completed`
  - `show actual usage`

### Section 2: Schedule Grid
- rows:
  - equipment
- grouping:
  - rows should be grouped by site because one board can span multiple sites
  - site grouping should be rendered as collapsible site sections in the page
- columns:
  - `day` view:
    - timeline day-scale view
  - `week` view:
    - timeline week-scale view
- each row should show:
  - equipment code / name
  - equipment type
  - site name
  - schedule blocks on the time axis

### Section 3: Legend / Display Toggles
- legend should explain:
  - reservation
  - actual usage
  - maintenance
  - completed
  - conflict
- toggles:
  - show completed
  - show actual usage
- defaults:
  - `show completed = false`
  - `show actual usage = true`

## Vue Implementation Shape

### Page Component
- recommended page:
  - `beeradmin_tail/src/views/Pages/EquipmentScheduleBoard.vue`

### Scheduler Dependency
- this page uses `vis-timeline`
- the page should render one shared timeline instance for the visible board area
- equipment rows should be modeled as native timeline groups
- schedule blocks should be modeled as timeline items attached to the matching equipment group
- the board should not use a separate left-side task table model
- prepared reservation / assignment windows should be reused across filtering, validation, and timeline item assembly instead of reparsing dates in each pass
- timeline dataset updates should prefer incremental refreshes over full clear-and-rebuild when the visible board is already mounted

### Suggested Child Components
- `components/EquipmentScheduleMultiSelectFilter.vue`
- `components/EquipmentReservationDialog.vue`

### Responsibility Split
- page component:
  - route/query parsing
  - data loading
  - merged board view model creation
  - modal open/close state
  - shared timeline group/item assembly
- filter bar:
  - filter inputs and search/reset actions
  - shared multi-select dropdown behavior for site / equipment type / equipment filters
- grid/site group/row:
  - board context layout only
- timeline group/item rendering:
  - handled by the shared `vis-timeline` instance
- reservation dialog:
  - create/edit reservation form

## Block Types

### Reservation Blocks
- source:
  - `mes.equipment_reservation`
- reservation types currently supported by schema:
  - `batch`
  - `maintenance`
  - `cip`
  - `manual_block`
- UI labels:
  - `batch` -> production reservation
  - `maintenance` -> maintenance
  - `cip` -> CIP
  - `manual_block` -> manual block

### Actual Usage Blocks
- source:
  - `mes.batch_equipment_assignment`
- purpose:
  - show what equipment is actually being used in execution
- actual blocks are view/navigation oriented, not the main edit target of this page

## Block Render Priority
- if a `batch_equipment_assignment` row links to a reservation via `reservation_id`, the board should render the actual block as the primary visible block for the overlapping time range
- linked reservation context may still be shown inside the block tooltip/detail panel
- linked reservation hiding should only happen when the linked actual row is itself visible under the current board filters
- if there is an unlinked actual assignment, render it as an independent actual block
- if reservation and actual overlap but are not linked, mark as mismatch/conflict candidate

## Color Rules
- reservation `draft / reserved / confirmed`:
  - blue family
- actual usage `in_use`:
  - green
- completed / done:
  - gray
- maintenance:
  - red
- conflict / mismatch:
  - orange

## Status Logic

### Reservation-Side
- created reservation:
  - blue
- maintenance reservation:
  - red and blocking
- completed / cancelled reservation:
  - gray when shown

### Actual-Side
- execution started:
  - green
- execution done:
  - gray when shown

## Completed Block Visibility
- completed gray blocks should be hidden by default
- the page should provide a `show completed` toggle
- default-hidden completed blocks are especially important for week view readability

## Vacancy Logic

### Primary Method
- visual schedule vacancy on the grid

### Vacancy Rule
- an equipment slot is available only when all of the following are true:
  - there is no overlapping active exclusive reservation
  - there is no overlapping actual in-use assignment
  - the equipment itself is active / usable

### Optional Future Search
- `find available slot`
- optional inputs:
  - equipment type
  - time range
  - site
- note:
  - capacity-based search should be deferred unless the board is explicitly scoped to equipment types that have capacity semantics

## User Actions

### Create Reservation
- use timeline double click as the primary create interaction
- open reservation modal
- prefill:
  - equipment resolved from the clicked timeline group row
  - site derived from the selected equipment
  - start/end inferred from the clicked timeline time when possible
  - fallback start/end use the board default create window based on current view

### Edit Reservation
- double click reservation block
- open reservation modal in edit mode
- reservation modal in edit mode should provide a delete action for the current reservation
- reservation block drag should move start / end time together directly on the board
- reservation block drag should keep the original duration fixed
- drag should persist only after reservation validation passes

### View Actual Usage
- actual usage blocks remain read-only
- double click actual usage block should open reservation create mode for the same equipment/time area

### Optional Later Enhancements
- empty-slot create

## Reservation Modal

### Fields
- type
- equipment
- site summary
- batch
- batch step
- start time
- end time
- status
- note

### Field Rules
- do not expose a separate `repair` type
- use current schema types:
  - `batch`
  - `maintenance`
  - `cip`
  - `manual_block`
- `site` should be display-only because reservation site is derived from the selected equipment
- `batch` reservations may optionally link to batch and step
- `batch step` is selectable only after `batch` is chosen
- when editing an existing reservation in MVP, equipment is readonly
- `maintenance` is the repair-like blocking concept for this phase
- `status` should use current schema values:
  - `draft`
  - `reserved`
  - `confirmed`
  - `in_progress`
  - `completed`
  - `cancelled`
- `batch step` should be nullable for non-batch reservation types
- delete action should be shown only in edit mode
- delete should require explicit user confirmation before removing the reservation
- after delete succeeds, close the modal and refresh the board

### Validation
- check overlapping reservation window
- check equipment active/usable state
- validate `start_at < end_at`
- validate `batch` type requires `batch_id`
- if `batch_step_id` is set, it must belong to the selected batch
- final conflict validation must still rely on backend/database response

## Filter / Query Model

### Filter State
- `siteIds: string[]`
- `equipmentTypeIds: string[]`
- `equipmentIds: string[]`
- `rangeStart: string`
- `rangeEnd: string`
- `viewMode: 'day' | 'week' | 'two_weeks' | 'month'`
- `showCompleted: boolean`
- `showActualUsage: boolean`

### Recommended URL Query
- `site`
- `equipmentType`
- `equipment`
- `start`
- `end`
- `view`
- `showCompleted`
- `showActual`

### Time Window Rule
- the board query window must use a half-open interval:
  - `[start, end)`
- the page must use browser timezone for both rendering and query normalization
- event/range intersection checks must follow the same half-open rule
- changing `viewMode` should recalculate the visible frame length from the current `rangeStart`

## Data Loading Shape

### MVP Loading Strategy
- use separate Supabase reads, then merge on the page side

### Query 1: Equipment Rows
- source:
  - `public.mst_equipment`
- fields:
  - `id`
  - `equipment_code`
  - `name_i18n`
  - `equipment_type_id`
  - `equipment_kind`
  - `site_id`
  - `equipment_status`
  - `is_active`
  - `sort_order`
- filters:
  - selected sites
  - selected equipment ids
  - selected equipment types
  - active equipment by default
- sort:
  - site
  - sort order
  - equipment code

### Query 2: Reservation Blocks
- source:
  - `mes.equipment_reservation`
- fields:
  - `id`
  - `site_id`
  - `equipment_id`
  - `reservation_type`
  - `batch_id`
  - `batch_step_id`
  - `start_at`
  - `end_at`
  - `status`
  - `note`
  - `created_at`
  - `updated_at`
- range rule:
  - load blocks whose time range intersects the visible board range
- hide by default:
  - `completed`
  - `cancelled`
  - unless `showCompleted = true`

### Query 3: Actual Usage Blocks
- source:
  - `mes.batch_equipment_assignment`
- fields:
  - `id`
  - `batch_id`
  - `batch_step_id`
  - `reservation_id`
  - `equipment_id`
  - `assignment_role`
  - `status`
  - `assigned_at`
  - `released_at`
  - `note`
  - `updated_at`
- range rule:
  - load rows whose actual time range intersects the visible board range
- legacy compatibility:
  - if an older row has no `assigned_at`, the page may fall back to `updated_at` to decide whether the row should still be loaded and rendered
- ongoing rule:
  - if `released_at` is null and status is `in_use`, use `now` as the display end
- hide by default:
  - `done`
  - `cancelled`
  - unless `showCompleted = true`

### Supporting Lookup Data
- sites:
  - `public.mst_sites`
- equipment types:
  - `public.type_def`
  - domain must be `equipment_type`
- linked labels required for MVP:
  - batch code from `public.mes_batches`
  - step name/no from `mes.batch_step`
- these labels must be loaded in bulk, not via per-block fetches

## Board View Model

### Equipment Row Model
- `siteId`
- `siteLabel`
- `siteResourceId`
- `equipmentId`
- `equipmentCode`
- `equipmentName`
- `equipmentTypeLabel`
- `equipmentStatus`
- `isActive`
- `blocks: ScheduleBlock[]`
- `summaryText`

### Page Group Model
- the page should render one shared timeline for the full filtered result set without a separate grouped table above it
- equipment rows are represented directly by timeline groups
- site grouping should be reflected in equipment ordering, labels, and optional future visual separators inside the timeline area

### Shared Timeline Model
- group row:
  - one row for every filtered equipment, even if it has no visible blocks
  - group label should represent the equipment row directly
- item:
  - one item for each visible reservation block
  - one item for each visible actual usage block
  - linked to the matching equipment group
- item single click:
  - no modal or navigation action
- item double click:
  - reservation items open reservation edit
  - actual items open reservation create mode using the clicked equipment/time context
- timeline double click:
  - timeline double click should resolve the equipment group context and open create mode
  - empty timeline space should open reservation create mode
  - block double click should open reservation edit/create depending on block kind
- timeline frame drag:
  - dragging the title/time-axis row should move the visible frame
  - user-driven frame changes should sync back to page filters and reload board data for the new visible range

### Schedule Block Model
- `id`
- `kind: 'reservation' | 'actual' | 'conflict'`
- `equipmentId`
- `siteId`
- `startAt`
- `endAt`
- `displayStatus`
- `colorToken`
- `label`
- `subLabel`
- `batchId?`
- `batchStepId?`
- `reservationId?`
- `editable`
- `navigationTarget`
- `groupId`

## Interaction Rules

### Reservation Block Double Click
- open reservation modal in edit mode

### Reservation Block Drag
- reservation items are draggable for time adjustment
- equipment/group change is not allowed from drag
- drag must preserve the item duration
- drag must validate overlap rules before save
- failed validation should revert the block to its previous position

### Actual Block Double Click
- open reservation modal in create mode using the current equipment/time area

### Actual Block Drag / Resize
- actual usage blocks remain read-only

### Empty Slot Double Click
- single click on empty timeline space does not create
- double click on empty timeline space should open create mode
- create should inherit:
  - resolved equipment group context
  - clicked board time when derivable from the chart
  - board default create window as fallback

### Timeline Frame Drag
- dragging the time-axis/title row should move the current visible frame
- the moved frame should update range filters so the board does not snap back on the next sync

## Navigation
- from equipment row:
  - equipment detail
- from reservation block:
  - reservation edit

## MVP Scope
- filter bar
- multi-site grouped schedule grid
- day / week switch
- timeline double click to create reservation
- double click reservation block to edit reservation
- drag reservation block to update time window
- drag time-axis/title row to change visible frame
- color-coded blocks
- overlap validation
- completed toggle

## Non-MVP
- advanced capacity search
- auto-scheduling
- board-level execution editing
- conflict resolution workflow

## Additional Concerns
- performance:
  - multi-site week view can become very large, so row virtualization or lazy group expansion may be needed
- timezone:
  - browser timezone is the display/query timezone rule for MVP
- ongoing usage:
  - when `released_at` is null and status is `in_use`, render the block through `now`
- conflict semantics:
  - orange should represent data mismatch or exceptional overlap, not normal planned occupancy
- permissions:
  - reservation create/update/delete permissions may differ from execution-view permissions
- data loading:
  - the page will likely need a merged board query/view model instead of naively loading three large tables independently

## Backend / Performance Follow-Up
- if the three-query MVP becomes too heavy, add a backend RPC or database view such as:
  - `public.equipment_schedule_board_get(...)`
- that backend shape should return already-merged board blocks and linked labels

## Route / Locale Implementation Notes
- tenant route:
  - add to `beeradmin_tail/src/router/tenant-routes.ts`
- sidebar:
  - add under `production` in `beeradmin_tail/src/components/layout/AppSidebar.vue`
- locale keys:
  - add page title, filter labels, legend labels, board labels, modal labels, and status/type display text in:
    - `beeradmin_tail/src/locales/ja.json`
    - `beeradmin_tail/src/locales/en.json`
