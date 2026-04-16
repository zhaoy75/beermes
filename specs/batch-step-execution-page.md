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
- Section 1: Batch / Step Context
- Section 2: Step Execution Control
- Section 3: Parameters
- Section 4: Material Execution
- Section 5: Equipment Execution
- Section 6: QA
- Section 7: Deviations and Logs

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

## Section 3: Parameters

### Purpose
- Show planned step parameters and capture actual parameter results.

### Show
- parameter code / name
- planned target
- planned min
- planned max
- uom
- actual value
- operator comment when needed

### Source / Persistence Direction
- planned values:
  - `mes.batch_step.planned_params.parameters`
  - fallback `mes.batch_step.snapshot_json.parameters`
- actual values:
  - must stay in execution-side storage only

### Rules
- planned values remain readonly
- only actual result input is editable
- this page must not rewrite released recipe planning data

## Section 4: Material Execution

### Purpose
- Capture what was actually consumed or issued for this step.

### Subsection A: Merged Plan / Actual Table
- show in one table:
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
- when the planned recipe input uses `consumption_mode = backflush`, the actual row may remain unresolved to a lot while the step is in progress
- when a `backflush` step is completed, the page must resolve the actual issue to concrete raw-material lots and create posted inventory issue movements
- the backflush inventory issue must use `doc_type = 'production_issue'`
- the backflush movement lines must remain lot-level and carry `meta.lot_id`
- backflush allocation must not silently consume stock across multiple sites
- insufficient stock for backflush must block step completion
- this page must not change filling / packing data
- this page must not alter finished-goods inventory result logic owned by `actual_yield` or packing

### Subsection B: Output Materials
- show a separate output-material section on the same page
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

## Section 5: Equipment Execution

### Purpose
- Record which actual equipment was assigned to the step and for how long.

### Editable / Maintainable Items
- equipment
- assignment role
- assigned at
- released at
- note

### Source / Persistence Direction
- `mes.batch_equipment_assignment`

### Rules
- assignment is step-level only
- this page must not act as equipment vacancy planning for the whole batch
- this page must not change batch-level packing or yield behavior

## Section 6: QA

### Purpose
- Capture step-level quality execution and result input.

### Show
- planned checks
- check code / name
- planned acceptance rule summary

### Editable / Maintainable Items
- result value or result note
- checked at
- checked by
- pass / fail / required handling

### Source / Persistence Direction
- planned checks:
  - `mes.batch_step.quality_checks_json`
  - fallback `mes.batch_step.snapshot_json.quality_checks`
- actual result storage:
  - must remain step-level execution data, not batch header data

### Rules
- QA input on this page must not modify recipe master data
- global release / product yield logic remains outside this page

## Section 7: Deviations and Logs

### Purpose
- Keep execution exceptions and event history close to the step where they happen.

### Subsection A: Deviations
- maintain:
  - deviation code
  - summary
  - severity
  - status
  - opened at
  - closed at
  - note

### Subsection B: Execution Logs
- maintain or show:
  - event type
  - event at
  - note

### Source / Persistence Direction
- deviations:
  - `mes.batch_deviation`
- logs:
  - `mes.batch_execution_log`

### Rules
- deviation handling here must remain step-scoped as much as possible
- this page must not be used to replace batch relation history or packing history

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
