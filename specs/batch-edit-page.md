# Batch Edit Page

## Goal
- Define the concrete target behavior for the batch edit page.
- Reframe the page around:
  - batch header editing
  - released recipe visibility
  - execution progress visibility
  - step execution tracking
- Keep current actual-yield and filling operations stable while the page structure evolves.

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
- Provide access to step-level execution input, filling/packing, lot DAG, and batch relations.

## Compatibility Strategy
- This page must be migrated in-place, not rewritten in a way that breaks current operations.
- `actual_yield` entry is an operationally stable feature and must remain usable throughout the redesign.
- `filling / packing` is also operationally stable and must remain usable throughout the redesign.
- New design work should be layered above or around these stable operations.
- If a design decision conflicts with current `actual_yield` or `filling` behavior, preserve operation first and defer the visual redesign.

## Users
- Tenant User
- Admin

## Page Layout
- Section 1: Batch Header
- Section 2: Step Execution Table
- Section 3: Secondary Operations
  - filling / packing summary
  - batch relation

## Phased Layout Rule
- Phase 1:
  - keep current editable batch header
  - add released recipe info inside the header section
  - add compact execution summary inside the step execution section
  - keep current filling and relation sections working
- Phase 2:
  - add step execution table as the main operational table
  - move filling and relation lower on the page
- Phase 3:
  - move step inspection to a dedicated step execution page and keep `BatchEdit` compact
- The redesign must not require disabling actual-yield or filling operations in any phase.

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
- released recipe link text
- released recipe version summary

### Rules
- batch code is readonly after create
- planned start and planned end must use calendar-selectable date inputs
- actual start and actual end must use calendar-selectable date inputs
- dynamic batch attributes on Batch Edit should validate entered values against `attr_def` rules, including numeric `num_min` / `num_max`, but missing / blank values must not block save
- save should block when dynamic attribute validation fails
- `actual_yield` dialog remains part of this section
- `actual_yield` save flow must keep:
  - batch status gate: allowed only when batch status is `in_progress` or terminal `finished`
  - quantity validation `0 < actual_yield <= 1000000`
  - volume UOM selection from `mst_uom`
  - manufacturing-site validation
  - `product_produce` call
  - `batch_save` update
- released recipe information in the header is read-only
- released recipe display should be a simple inline row, not a separate bordered block
- changing released recipe is not supported on batch edit
- if a batch has no recipe, show an explicit `No Base Recipe` state in the inline row
- when both `mes_recipe_id` and `recipe_version_id` are available, the recipe link should navigate to `/recipeEdit/:recipeId/:versionId`
- the link text should use recipe name first and include recipe code when available
- the version summary should use released version no / label when available
- do not show recipe version id, release timestamp, description, base quantity, or output summary
- recipe display must prefer:
  - `released_reference_json`
  - `mes_recipe_id`
  - `recipe_version_id`
- batch edit runtime code must not query `public.mes_recipes`
- recipe display and batch beer-category resolution must use:
  - `released_reference_json`
  - `recipe_json`
  - `mes_recipe_id`
  - `recipe_version_id`
  - batch `entity_attr`
  - batch `meta`
- legacy `recipe_id` on `mes_batches` may remain in the schema for compatibility, but it is not a runtime UI source for batch edit

## Section 2: Step Execution Table

### Purpose
- Make step execution the main operational table on the page.
- Include a compact execution summary in the header area of this section.

### Compact Summary
- batch status
- progress
  - `completed_steps / total_steps`
- current step
- open deviation count

### Summary Rules
- do not render a dedicated execution summary section or large summary cards
- summary should use small inline items or chips in the section header area
- total steps from `mes.batch_step`
- completed steps where status = `completed`
- current step priority:
  - `in_progress`
  - `ready`
  - `open`
  - else none
- open deviation count from `mes.batch_deviation`
- if no `mes.batch_step` data exists yet, the section still renders and shows zero/empty values
- step state machine execution is not triggered on `BatchEdit`
- `BatchEdit` only reflects step status changes persisted by `BatchStepExecution` or other server-side processes

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

### Compatibility Rule
- if step-release data is absent for an older batch, show an empty-state message instead of failing the whole page
- the page must still allow:
  - batch header save
  - actual-yield save
  - filling / packing navigation
  - relation editing
- batch page must not auto-start the next step on its own

### Actions
- open dedicated step execution page

### Row Detail
- recommended interaction:
  - click row to move to the dedicated step execution page
  - row-level detail button should do the same navigation
  - `BatchEdit` should not host step execution input forms directly

## Step Detail Navigation

### Route
- `/batches/:batchId/step/:stepId`

### Rules
- batch edit page should not render a right-side step detail drawer
- step execution should be opened as a dedicated page
- the dedicated page should provide a back action to the batch edit page
- step detail navigation must not affect:
  - batch header save
  - actual-yield flow
  - filling / packing flow
  - batch relation flow

### Ownership Boundary
- `BatchEdit` owns:
  - batch header editing
  - actual yield
  - filling / packing
  - lot DAG entry
  - batch relation
- `BatchStepExecution` owns:
  - step status and timestamps
  - step actual parameters
  - step actual material records
  - step-level raw-material issue posting for execution-side consumption modes such as `backflush`
  - step equipment assignment records
  - step QA input
  - step deviations and execution logs

## Section 3: Secondary Operations

### Filling / Packing
- keep filling summary and packing navigation
- keep `Lot DAG` button
- this section remains after the step execution table
- this section is operationally stable and must not be redesigned in a way that changes current calculations
- the current filling summary behavior stays valid:
  - total product volume
  - processed volume
  - remaining volume
- current filling history table remains read-only except for allowed deletion
- current packing page remains the edit surface
- current calculation source remains shared filling logic from the packing implementation

### Actual Yield
- keep the actual-yield dialog button in the batch header area
- do not move actual-yield entry into step execution
- do not convert actual-yield entry into a generic inventory edit form
- actual-yield remains a batch-level manufacturing result operation

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
  - `public.mes_batches.mes_recipe_id`
  - `public.mes_batches.recipe_version_id`
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
- secondary does not mean removable:
  - actual-yield remains required
  - filling / packing remains required
- batch redesign must not break `product_produce` or `product_filling` entry points

## Recommended Visual Design
- top:
  - batch header with inline released recipe link row
- middle:
  - compact execution summary inside the step table header
  - step table
- bottom:
  - filling / packing
  - relations

## Stability Constraints
- Do not remove the current actual-yield button during redesign.
- Do not replace the filling history table with the execution step table.
- Do not derive filling history from `mes.batch_step`; keep reading operational filling records from inventory movement sources.
- Do not require a released recipe for actual-yield or filling operations to work.
- If released recipe information is missing, show empty-state UI and keep operations enabled.

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
