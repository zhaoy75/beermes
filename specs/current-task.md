# Current Task

## Goal
- Fix the equipment schedule board so `表示単位` correctly changes the board frame length.

## Scope
- Make `day / week / two weeks / month` update the visible frame length consistently.
- Keep the change limited to the board page, related page spec, and this task spec.

## Non-Goals
- Do not change database schema.
- Do not change route/sidebar/locale behavior.
- Do not redesign the page visually.
- Do not change reservation form behavior in this turn.
- Do not change drag/drop behavior in this turn.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [specs/equipment-schedule-board-page.md](/Users/zhao/dev/other/beer/specs/equipment-schedule-board-page.md)
- [beeradmin_tail/src/views/Pages/EquipmentScheduleBoard.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/EquipmentScheduleBoard.vue)
- [beeradmin_tail/src/views/Pages/equipment-schedule/utils.ts](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/equipment-schedule/utils.ts)

## Data Model / API Changes
- No schema or API changes.

## Final State
- Changing `表示単位` recalculates the board end date from the current start date.
- `day / week / two weeks / month` each produce a visibly different frame length.
- The board query and timeline stay aligned to the selected unit after search.

## Validation Plan
- Run targeted board validation:
  - eslint on `EquipmentScheduleBoard.vue`
  - type-check
  - build-only
  - repo lint
  - test script status

## Validation Results
- `npx eslint src/views/Pages/EquipmentScheduleBoard.vue src/views/Pages/equipment-schedule/utils.ts --no-fix`: passed
- `npm run type-check`: passed
- `npm run build-only`: passed with the existing CSS minify warnings and chunk-size warnings
- `npm run lint`: failed with the same pre-existing repo-wide ESLint errors
- `npm run test`: failed because `package.json` has no `test` script
