# Batch Edit Page

## Goal
- Define the concrete target behavior for the batch edit page.
- Reframe the page around:
  - batch header editing
  - released recipe visibility
  - execution progress visibility
  - step execution tracking

## Route / Entry Point
- Primary route: `/batches/:id`
- Entry points:
  - batch list row click
  - batch list edit action
  - batch create success flow

## Purpose
- Edit the batch header and batch attributes.
- Show which recipe/version was released to the batch.
- Show the current execution state of the batch and its steps.
- Provide access to step-level detail, filling/packing, lot DAG, and batch relations.

## Users
- Tenant User
- Admin

## Page Layout
- Section 1: Batch Header
- Section 2: Released Recipe Info
- Section 3: Execution Summary
- Section 4: Step Execution Table
- Section 5: Secondary Operations
  - filling / packing summary
  - batch relation

## Section 1: Batch Header

### Purpose
- Maintain editable batch-level business fields.

### Fields
- batch code
  - readonly
- status
- product name
- actual yield summary
- planned start
- planned end
- actual start
- actual end
- dynamic batch attributes from `entity_attr`

### Rules
- batch code is readonly after create
- dynamic batch attributes follow `attr_def` validation rules
- save should block when dynamic attribute validation fails

## Section 2: Released Recipe Info

### Purpose
- Show the exact released recipe context used by this batch.

### Fields
- recipe code
- recipe name
- recipe version no
- recipe version label
- recipe version id
- recipe release timestamp
- recipe description
- base quantity
- base UOM
- output summary

### Data Source
- primary:
  - `public.mes_batches.released_reference_json`
  - `public.mes_batches.recipe_json`
  - `public.mes_batches.mes_recipe_id`
  - `public.mes_batches.recipe_version_id`
- if no recipe is attached:
  - show an explicit `No Base Recipe` state

### Rules
- this section is read-only on batch page
- changing released recipe is not supported on batch edit
- if a batch has no recipe, this section remains visible but uses empty-state UI

## Section 3: Execution Summary

### Purpose
- Show overall execution status without forcing users to scan every step.

### Required Cards
- batch status
- total steps
- completed steps
- current step
- hold step count
- open deviation count

### Derived Data
- total steps from `mes.batch_step`
- completed steps where status = `completed`
- current step priority:
  - `in_progress`
  - `ready`
  - `open`
  - else none
- open deviation count from `mes.batch_deviation`

### Recommended Display
- top summary cards
- one progress bar:
  - `completed_steps / total_steps`

## Section 4: Step Execution Table

### Purpose
- Make step execution the main operational table on the page.

### Required Columns
- `step_no`
- `step_code`
- `step_name`
- `status`
- `planned_duration_sec`
- `started_at`
- `ended_at`
- `planned_material_count`
- `quality_check_count`
- `equipment_assignment_count`
- `actions`

### Source
- `mes.batch_step`
- plus aggregated counts from:
  - `mes.batch_material_plan`
  - `mes.batch_equipment_assignment`

### Actions
- view detail
- optionally update status
- optionally open step execution subview later

### Row Detail
- recommended interaction:
  - click row to open a right-side drawer

## Step Detail Drawer

### Purpose
- Show full execution context for one released step.

### Blocks
- step header
- planned parameters
- actual parameters
- quality checks
- planned materials
- actual material consumption
- equipment assignments
- execution log
- deviations

### Sources
- step:
  - `mes.batch_step`
- planned materials:
  - `mes.batch_material_plan`
- actual materials:
  - `mes.batch_material_actual`
- equipment:
  - `mes.batch_equipment_assignment`
- logs:
  - `mes.batch_execution_log`
- deviations:
  - `mes.batch_deviation`

## Section 5: Secondary Operations

### Filling / Packing
- keep filling summary and packing navigation
- keep `Lot DAG` button
- this section remains after the step execution table

### Batch Relation
- keep relation list and relation dialog
- move relation below execution sections unless business users insist it stays near the header

## Empty-State Rules

### No Recipe Attached
- show a read-only recipe empty state:
  - `No Base Recipe`
- execution summary may still show `0 steps`

### Recipe Attached But Not Released Properly
- show warning banner if:
  - `recipe_version_id` exists but no `mes.batch_step` rows exist

### No Execution Yet
- execution summary stays visible
- step table shows empty state

## Data Sources
- batch header:
  - `public.mes_batches`
- batch attributes:
  - `entity_attr`
- released recipe:
  - `public.mes_batches.recipe_json`
  - `public.mes_batches.released_reference_json`
- steps:
  - `mes.batch_step`
- planned materials:
  - `mes.batch_material_plan`
- actual materials:
  - `mes.batch_material_actual`
- equipment assignments:
  - `mes.batch_equipment_assignment`
- logs:
  - `mes.batch_execution_log`
- deviations:
  - `mes.batch_deviation`

## Business Rules
- batch edit page should no longer be centered only on manual result entry
- released recipe info must be treated as immutable snapshot display
- execution progress must come from `mes.batch_step`, not legacy `public.mes_batch_steps`
- relation and filling remain secondary operational sections

## Recommended Visual Design
- top:
  - batch header
  - released recipe info side by side on wide screens
- middle:
  - execution summary cards
  - step table
- bottom:
  - filling / packing
  - relations

## Open Decisions

### 1. Step Detail Interaction
- Option A:
  - inline expandable rows
- Option B:
  - right-side drawer
- Option C:
  - separate page per batch step
- Recommended:
  - Option B

### 2. Step Status Editing
- Option A:
  - status is read-only on batch edit page
- Option B:
  - quick status update in table
- Recommended:
  - Option A first, because execution logging rules are usually stricter

### 3. Relation Section Position
- Option A:
  - keep near header
- Option B:
  - move below execution sections
- Recommended:
  - Option B, because relation is secondary to execution visibility

### 4. Filling Section Position
- Option A:
  - above execution steps
- Option B:
  - below execution steps
- Recommended:
  - Option B, unless filling is the primary operation for your users
