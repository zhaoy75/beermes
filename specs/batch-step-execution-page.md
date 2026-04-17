# Batch Step Execution Page

## Goal
- Define `BatchStepExecution` as the dedicated page for `one step` execution work.
- Move operator input for step execution onto this page instead of overloading `BatchEdit`.
- Protect current batch-level operations from regression by keeping responsibilities clearly separated.

## Route / Entry Point
- Primary route:
  - `/batches/:batchId/step/:stepId`
- Entry points:
  - click a row in the batch step execution table on `BatchEdit`
  - click the `詳細 / Step Execution` action in the batch step execution table

## Purpose
- Provide the focused execution workspace for one released batch step.
- Let the user review plan vs actual and input step-level execution data.
- Keep `BatchEdit` as the batch-level page and avoid mixing batch-wide operations into the step page.
- Keep all static page labels and option text locale-driven so the page works in Japanese and English.

## Core Boundary

### This Page Owns
- step-level execution input
- step-level execution monitoring
- step-level actual records
- raw-material issue posting for step consumption modes handled at execution time
- step-level QA and deviation handling

### This Page Does Not Own
- batch header editing
- `actual_yield`
- `product_produce`
- filling / packing
- `product_filling`
- lot DAG navigation logic
- batch relation editing

## Page Layout
- Primary workspace:
  - Section 1: Batch / Step Context
  - Section 2: Step Execution Control
  - Section 3: Material Execution
  - Section 4: Equipment Execution
- Secondary workspace:
  - Section 5: Execution Details
  - the secondary workspace may render `Parameters`, `QA`, `Execution Logs`, and `Deviations` as tabs inside one shared section instead of four full-width sections
- the page should keep the most common operator flow above the fold and move lower-frequency detail capture into the secondary workspace

## Section 1: Batch / Step Context

### Purpose
- Give the operator enough context without turning the page into another batch overview.

### Required Items
- back button to batch edit page
- batch code
- product name
- released recipe link summary
- step no
- step code
- step name
- step template
- step type
- planned duration
- instructions

### Rules
- the back button should navigate to `/batches/:batchId`
- batch context is readonly on this page
- recipe link should navigate to `/recipeEdit/:recipeId/:versionId` when available
- do not show full recipe detail blocks here
- if batch or step is not found, show a clear not-found state
- static labels, option values, and generic fallback text must come from locale resources
- this section should stay compact and summary-like rather than card-heavy
- summary items should prefer denser spacing and shorter vertical rhythm

## Section 2: Step Execution Control

### Purpose
- Capture the core lifecycle state of the selected step.

### Editable Items
- step status
- actual started at
- actual ended at
- operator note / execution note

### Readonly Companion Items
- planned duration
- current status summary
- latest execution timestamp summary

### Rules
- this section is the primary place for step start / progress / complete input
- status update is initiated from the current step only
- changing a step on this page must not update batch header fields directly
- if status logic later requires validation, that validation belongs here, not on `BatchEdit`
- keep this section visually compact; prefer a tight grid over large isolated form blocks
- state machine rule for this phase:
  - when the current step is saved as `completed` or `skipped`
  - if `ended_at` is blank, auto-set it to now
  - when the current step is saved as `completed` and it has unresolved `backflush` material inputs, backflush issue posting must succeed before completion is finalized
  - search the next step in the same batch by `step_no`
  - if the next step is `open`, auto-advance it to `ready`
- do not auto-skip over `hold`, `completed`, `skipped`, or `cancelled` next steps
- do not change batch header fields or filling / yield logic as part of this transition
- companion summary items may render as dense readonly badges or cards inside the same section rather than a separate summary block

## Section 3: Material Execution

### Purpose
- Capture what was actually consumed or issued for this step.

### Subsection A: Merged Plan / Actual Table
- keep planned and actual material input capture in one main section
- the section may render `Inputs` and `Outputs` as tabs inside the same card instead of separate full-width blocks
- show in the input view:
  - planned material type / label
  - planned qty
  - planned uom
  - consumption mode
  - actual material
  - actual qty
- editable / maintainable actual-side records:
  - actual material
  - actual qty
  - lot when the operator needs lot-specific execution capture
  - consumed at
  - note

### Source / Persistence Direction
- planned:
  - `mes.batch_material_plan`
- actual:
  - `mes.batch_material_actual`
- inventory issue posting:
  - `inv_movements`
  - `inv_movement_lines`

### Rules
- planned rows are reference only
- actual rows belong to the selected `batch_step_id`
- `mes.batch_material_actual` is an execution record and not the inventory source of truth
- planned and actual material inputs should be shown together instead of in separate sections
- when an actual row is tied to a planned row, the actual material selector should default to materials matching the planned material type
- the operator must still be able to add extra actual rows that are not tied to a planned row
- lot, consumed at, and note may be shown in a compact row detail area so the default table stays narrow
- when the planned recipe input uses `consumption_mode = backflush`, the actual row may remain unresolved to a lot while the step is in progress
- when a `backflush` step is completed, the page must resolve the actual issue to concrete raw-material lots and create posted inventory issue movements
- the backflush inventory issue must use `doc_type = 'production_issue'`
- the backflush movement lines must remain lot-level and carry `meta.lot_id`
- backflush completion should resolve the source site from batch metadata when available, and may pass an explicit execution-context site fallback when batch metadata is incomplete
- backflush allocation must not silently consume stock across multiple sites
- insufficient stock for backflush must block step completion
- this page must not change filling / packing data
- this page must not alter finished-goods inventory result logic owned by `actual_yield` or packing

### Subsection B: Output Materials
- show output-material actual capture on the same page
- this may render inside the same material execution section as a secondary tab
- show:
  - output material type / name
  - planned qty
  - uom
  - output type
  - actual qty
- support an add button for extra output rows
- actual output qty should be maintained in execution-side JSON only
- extra operator-added rows may capture:
  - output material type
  - output name
  - output type
  - uom
  - actual qty
- this section is step-level execution reference and actual capture, not finished-goods inventory posting

## Section 4: Equipment Execution

### Purpose
- Record which actual equipment was assigned to the step and for how long.
- Make the common operator path fast while keeping plan vs actual mismatch visible.

### Operator View
- show three aligned layers in one section:
  - planned equipment requirement
  - reserved equipment candidate
  - actual assignment
- show a compact summary before the detail rows, including:
  - required count
  - reserved count
  - in-use count
  - mismatch count
- keep the default view dense and execution-oriented rather than using a large free-form table as the only interaction pattern

### Editable / Maintainable Items
- equipment
- assignment role
- assignment status
- assigned at
- released at
- reservation link
- note

### Source / Persistence Direction
- `mes.batch_equipment_assignment`
- optional link to `mes.equipment_reservation`

### Operator Actions
- `Use Reserved Equipment`
- `Start With Other Equipment`
- `Start Use`
- `Release`
- `Complete`
- `Cancel`

### Rules
- assignment is step-level only
- planned occupancy and blocking should live in `mes.equipment_reservation`, not in `mes.batch_equipment_assignment`
- assignment may reference a reservation, but it must remain the actual execution-side record
- the page should show planned, reserved, and actual equipment together rather than isolating actual rows from their planning context
- action buttons should be the primary path for common operator work; raw timestamp editing remains available as a fallback
- `assignment_role` should use constrained option values rather than free text
- `assignment status` should use controlled values aligned to execution flow:
  - `assigned`
  - `in_use`
  - `done`
  - `cancelled`
- `Use Reserved Equipment` should prefill equipment, role, and reservation link from the selected reservation when available
- `Start Use` should auto-fill `assigned_at` with now when it is blank
- `Release` and `Complete` should auto-fill `released_at` with now when it is blank
- changing the actual equipment away from a linked reservation should show a visible mismatch warning rather than silently hiding the difference
- candidate equipment should rank in this order:
  - matching reserved equipment
  - active equipment matching the step requirement and site context
  - other active equipment as an explicit override path
- save should be handled as one step-level transaction rather than a per-row client save loop
- save validation should cover:
  - required equipment presence when the step requirement demands it
  - `assigned_at <= released_at`
  - conflicting active assignment on the same equipment
  - reservation linkage consistency with tenant / batch / step / equipment
- mismatch with planned requirement or reserved equipment should be visible and confirmable by the operator when override is allowed
- this page must not act as equipment vacancy planning for the whole batch
- this page must not change batch-level packing or yield behavior

## Section 5: Execution Details

### Purpose
- Keep lower-frequency execution details close to the step without forcing every operator to scroll through all detail sections on every visit.
- Allow `Parameters`, `QA`, `Execution Logs`, and `Deviations` to share one denser workspace.

### Tab A: Parameters
- show:
  - parameter code / name
  - planned target
  - planned min
  - planned max
  - uom
  - actual value
  - operator comment when needed
- source / persistence direction:
  - planned values:
    - `mes.batch_step.planned_params.parameters`
    - fallback `mes.batch_step.snapshot_json.parameters`
  - actual values:
    - must stay in execution-side storage only
- rules:
  - planned values remain readonly
  - only actual result input is editable
  - this page must not rewrite released recipe planning data

### Tab B: QA
- show:
  - planned checks
  - check code / name
  - planned acceptance rule summary
- editable / maintainable items:
  - result value or result note
  - checked at
  - checked by
  - pass / fail / required handling

### Tab B Source / Persistence Direction
- planned checks:
  - `mes.batch_step.quality_checks_json`
  - fallback `mes.batch_step.snapshot_json.quality_checks`
- actual result storage:
  - must remain step-level execution data, not batch header data

### Tab B Rules
- QA input on this page must not modify recipe master data
- global release / product yield logic remains outside this page

### Tab C: Deviations
- maintain:
  - deviation code
  - summary
  - severity
  - status
  - opened at
  - closed at
  - note

### Tab D: Execution Logs
- maintain or show:
  - event type
  - event at
  - note

### Tab C / D Source / Persistence Direction
- deviations:
  - `mes.batch_deviation`
- logs:
  - `mes.batch_execution_log`

### Tab C / D Rules
- deviation handling here must remain step-scoped as much as possible
- this page must not be used to replace batch relation history or packing history
- lower-priority detail tabs may be collapsed behind one shared tabbed card to keep the page visually slimmer

## Data Sources
- batch header context:
  - `public.mes_batches`
- step:
  - `mes.batch_step`
- planned materials:
  - `mes.batch_material_plan`
- actual materials:
  - `mes.batch_material_actual`
- raw-material issue postings:
  - `inv_movements`
  - `inv_movement_lines`
- inventory projection:
  - `inv_inventory`
- equipment:
  - `mes.batch_equipment_assignment`
- equipment reservations:
  - `mes.equipment_reservation`
- logs:
  - `mes.batch_execution_log`
- deviations:
  - `mes.batch_deviation`

## Compatibility Rules
- introducing step execution input here must not change:
  - batch header save on `BatchEdit`
  - `actual_yield` dialog behavior
  - `product_produce` call timing / ownership
  - filling summary calculations
  - packing navigation and `product_filling` ownership
  - lot DAG navigation
  - batch relation management
- `BatchEdit` remains the source page for batch-wide operations
- `BatchStepExecution` remains the source page for step-wide execution operations
- `BatchStepExecution` is also the owner of automatic step progression logic in this phase

## Empty-State / Error Rules
- if detail rows do not exist for a subsection, show `No data`
- if the selected step does not belong to the route batch, show not-found state
- if the batch has no released execution-side step data yet, show a clear execution-not-ready state

## Non-Goals
- do not edit batch header fields on this page
- do not input `actual_yield` on this page
- do not perform filling / packing on this page
- do not edit batch relation on this page
- do not turn this page into a duplicate of `BatchEdit`
