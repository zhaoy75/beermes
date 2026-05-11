## Purpose
- Use one dedicated page for one batch step execution workspace.
- Keep batch-wide operations on `BatchEdit` and move step-wide execution input here.

## Entry Points
- バッチ管理 -> 工程実行一覧 -> row click
- バッチ管理 -> 工程実行一覧 -> 詳細

## Route
- `/batches/:batchId/step/:stepId`

## Users and Permissions
- Tenant User: input and maintain step execution data

## Page Layout
- batch / step context
- step execution control
- parameters
- quality checks
- planned materials
- actual materials
- equipment assignments
- execution logs
- deviations

## Ownership Boundary
- this page owns:
  - step status
  - step started / ended timestamps
  - step notes
  - actual parameter input
  - QA result input
  - actual material rows
  - equipment assignment rows
  - execution logs
  - deviations
- this page does not own:
  - batch header edit
  - actual yield
  - filling / packing
  - lot dag
  - batch relation

## Header Summary
- back button
  - move to batch edit page `/batches/:batchId`
- save step inputs button
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

## Step Execution Control
- editable:
  - status
  - started at with shared Flatpickr date-time picker
  - ended at with shared Flatpickr date-time picker
  - notes
- save target:
  - `mes.batch_step`
- state machine:
  - if current step is saved as `completed` or `skipped`, and previous status was not terminal
  - auto-set current `ended_at` when blank
  - find next step by `step_no`
  - if next step status is `open`, set it to `ready`

## Parameters
- planned source:
  - `mes.batch_step.planned_params.parameters`
  - fallback `mes.batch_step.snapshot_json.parameters`
- actual result input:
  - actual value
  - comment
- save target:
  - `mes.batch_step.actual_params`

## Quality Checks
- planned source:
  - `mes.batch_step.quality_checks_json`
  - fallback `mes.batch_step.snapshot_json.quality_checks`
- editable:
  - result status
  - result value
  - checked at with shared Flatpickr date-time picker
  - checked by
  - result note
- save target:
  - `mes.batch_step.quality_checks_json`

## Planned Materials
- readonly reference only
- source:
  - `mes.batch_material_plan`

## Actual Materials
- editable rows:
  - material
  - lot
  - actual qty
  - uom
  - consumed at with shared Flatpickr date-time picker
  - note
- save target:
  - `mes.batch_material_actual`

## Equipment Assignments
- editable rows:
  - equipment
  - assignment role
  - assigned at with shared Flatpickr date-time picker
  - released at with shared Flatpickr date-time picker
- save target:
  - `mes.batch_equipment_assignment`

## Execution Logs
- editable rows:
  - event type
  - event at with shared Flatpickr date-time picker
  - comment
- save target:
  - `mes.batch_execution_log`

## Deviations
- editable rows:
  - deviation code
  - summary
  - severity
  - status
  - opened at with shared Flatpickr date-time picker
  - closed at with shared Flatpickr date-time picker
  - note
- save target:
  - `mes.batch_deviation`

## Compatibility Note
- this page must not affect:
  - batch header save
  - actual yield dialog
  - `product_produce`
  - filling / packing
  - `product_filling`
  - lot dag
  - batch relation
- this page is the owner of step auto-progression in the current UI phase
