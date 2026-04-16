# Current Task

## Goal
- Rewrite the `設備スケジュール管理 / Equipment Schedule Board` spec so it reflects the current final implementation state only.
- Remove historical ambiguity caused by multiple gantt component changes.

## Scope
- Treat the current board implementation as the source of truth:
  - shared `vis-timeline`
  - grouped site/equipment summary table above the chart
  - one timeline group per filtered equipment
  - one timeline item per visible reservation / actual usage block
  - timeline double click to open `設備予約登録`
- Rewrite the current task spec to describe the board in final-state terms, not migration/history terms.
- Keep the page spec aligned with the same final-state model.

## Non-Goals
- Do not change database schema.
- Do not change route/sidebar/locale behavior.
- Do not change the board UI or timeline behavior in this turn.
- Do not revisit abandoned `frappe-gantt` or `@lee576/vue3-gantt` experiments except to remove stale wording from specs.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [specs/equipment-schedule-board-page.md](/Users/zhao/dev/other/beer/specs/equipment-schedule-board-page.md)

## Data Model / API Changes
- No schema or API changes.
- The current board continues to read from:
  - `public.mst_equipment`
  - `public.mst_sites`
  - `public.type_def`
  - `public.mes_batches`
  - `mes.batch_step`
  - `mes.equipment_reservation`
  - `mes.batch_equipment_assignment`

## Final State
- The board uses one shared `vis-timeline` instance.
- Every filtered equipment row is represented as a native timeline group, even when no visible schedule item exists for that equipment.
- Visible reservations and visible actual usage rows are rendered as timeline items attached to the matching equipment group.
- The grouped site/equipment context table above the chart is required and remains visible.
- The context area is a compact table, not a card list.
- The board supports multiple sites on one page.
- Site sections in the context table are collapsible.
- The timeline remains a single shared chart below the grouped context table.
- Reservation blocks are editable from the board.
- Actual usage blocks are view/navigation only.
- If an actual assignment links to a reservation via `reservation_id`, the actual block is the primary visible block.
- The board query window uses browser timezone with half-open range semantics `[start, end)`.
- Completed rows remain hidden by default behind a toggle.
- `show actual usage` defaults to `true`.
- Equipment type labels/options come from `public.type_def` with `domain = 'equipment_type'`.
- Editing an existing reservation keeps equipment readonly.
- Timeline item click behavior:
  - reservation item -> open reservation edit
  - actual item -> navigate to step execution or batch detail
- Timeline double click behavior:
  - empty timeline space inside an equipment group -> open create reservation modal
  - start/end default from clicked time, snapped by current view mode
  - fallback to default board create window if exact click time cannot be resolved
- Reservation overlap is checked client-side against visible reservations and active `in_use` assignments, with final enforcement still backend-driven.

## Validation Plan
- Run spec consistency checks only.

## Validation Results
- `git diff --check -- specs/current-task.md specs/equipment-schedule-board-page.md`: passed
