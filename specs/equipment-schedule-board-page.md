# Equipment Schedule Board Page

This spec reflects the current final board design using `vis-timeline`. Older gantt experiments are not part of this spec.

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
  - view mode (`day` / `week`)
- actions:
  - search
  - reset
- recommended additions:
  - `show completed`
  - `show actual usage`

### Section 2: Schedule Grid
- the grouped site/equipment table above the chart is required
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

### Suggested Child Components
- `components/EquipmentSchedule/EquipmentScheduleFilterBar.vue`
- `components/EquipmentSchedule/EquipmentScheduleLegend.vue`
- `components/EquipmentSchedule/EquipmentScheduleGrid.vue`
- `components/EquipmentSchedule/EquipmentScheduleSiteGroup.vue`
- `components/EquipmentSchedule/EquipmentScheduleRow.vue`
- `components/EquipmentSchedule/EquipmentScheduleBlock.vue`
- `components/EquipmentSchedule/EquipmentReservationDialog.vue`

### Responsibility Split
- page component:
  - route/query parsing
  - data loading
  - merged board view model creation
  - modal open/close state
  - grouped site/equipment summary layout assembly
  - shared timeline group/item assembly
- filter bar:
  - filter inputs and search/reset actions
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
- click reservation block
- open reservation modal in edit mode

### View Actual Usage
- click actual usage block
- navigate to the related step execution page when step context exists
- fallback navigation:
  - batch detail

### Optional Later Enhancements
- drag to move reservation
- resize to adjust duration
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
- `viewMode: 'day' | 'week'`
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
- site should be rendered as a collapsible section
- each section should contain equipment rows
- each equipment row should contain:
  - compact table row cells
  - schedule summary for visible reservations / actual usage
- this grouped list acts as the table above the chart and should remain visible
- recommended columns:
  - equipment
  - equipment type
  - status
  - reservation count
  - actual usage count
  - action
- below the grouped site/equipment context area, the page should render one shared timeline for the full filtered result set
- site collapse affects the context list only; the shared timeline still renders the filtered equipment groups

### Shared Timeline Model
- group row:
  - one row for every filtered equipment, even if it has no visible blocks
  - group label should represent the equipment row directly
- item:
  - one item for each visible reservation block
  - one item for each visible actual usage block
  - linked to the matching equipment group
- item clicks:
  - reservation items open reservation edit
  - actual items navigate to step execution or batch detail
- timeline double click:
  - timeline double click should resolve the equipment group context and open create mode
  - reservation / actual items keep their normal click ownership and should not create a new reservation

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

### Reservation Block Click
- open reservation modal

### Actual Block Click
- do not open reservation modal
- navigate to step execution when `batch_step_id` exists
- otherwise navigate to batch detail

### Empty Slot Click
- single click on empty timeline space does not create
- double click on empty timeline space should open create mode
- create should inherit:
  - resolved equipment group context
  - clicked board time when derivable from the chart
  - board default create window as fallback

## Navigation
- from equipment row:
  - equipment detail
- from reservation block:
  - reservation edit
- from actual usage block:
  - step execution detail
  - fallback batch detail

## MVP Scope
- filter bar
- multi-site grouped schedule grid
- day / week switch
- timeline double click to create reservation
- click reservation block to edit reservation
- click actual block to view related execution detail
- color-coded blocks
- overlap validation
- completed toggle

## Non-MVP
- drag and resize
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
