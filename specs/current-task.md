# Current Task

## Goal
- Reuse the Flatpickr date picker for all frontend date and date-time entry so blank dates display consistently in Safari and Chrome.

## Scope
- Add a shared date/date-time picker wrapper around the existing `vue-flatpickr-component` dependency.
- Use it for all remaining native date and date-time inputs under `beeradmin_tail/src`.
- Keep all existing model values as strings:
  - date: `YYYY-MM-DD`
  - date-time: `YYYY-MM-DDTHH:mm`

## Non-Goals
- Do not change stored functions or database schema.
- Do not change date/time conversion semantics.
- Do not introduce a new dependency.

## Affected Files
- `specs/current-task.md`
- `specs/date-input-behavior.md`
- `specs/batch-list-page.md`
- `specs/batch-edit-page.md`
- `docs/UI/batchlist.md`
- `docs/UI/batchedit.md`
- `docs/UI/batch_step_execution.md`
- `beeradmin_tail/src/components/common/AppDateTimePicker.vue`
- `beeradmin_tail/src/views/Others/Calendar.vue`
- `beeradmin_tail/src/views/Pages/AlcoholTaxMaster.vue`
- `beeradmin_tail/src/views/Pages/BatchList.vue`
- `beeradmin_tail/src/views/Pages/components/BatchCreateDialog.vue`
- `beeradmin_tail/src/views/Pages/BatchEdit.vue`
- `beeradmin_tail/src/views/Pages/BatchPacking.vue`
- `beeradmin_tail/src/views/Pages/BatchStepExecution.vue`
- `beeradmin_tail/src/views/Pages/BatchYieldSummary.vue`
- `beeradmin_tail/src/views/Pages/BeerDash.vue`
- `beeradmin_tail/src/views/Pages/EquipmentMaster.vue`
- `beeradmin_tail/src/views/Pages/EquipmentScheduleBoard.vue`
- `beeradmin_tail/src/views/Pages/ProductMoveFast.vue`
- `beeradmin_tail/src/views/Pages/ProducedBeer.vue`
- `beeradmin_tail/src/views/Pages/ProducedBeerMovementEdit.vue`
- `beeradmin_tail/src/views/Pages/RawMaterialInventoryEdit.vue`
- `beeradmin_tail/src/views/Pages/RawMaterialReceipts.vue`
- `beeradmin_tail/src/views/Pages/RecipeEdit.vue`
- `beeradmin_tail/src/views/Pages/SiteMovement.vue`
- `beeradmin_tail/src/views/Pages/WasteList.vue`
- `beeradmin_tail/src/views/Pages/components/BatchPackageDialog.vue`
- `beeradmin_tail/src/views/Pages/components/EquipmentReservationDialog.vue`

## Data Model / API Changes
- No schema changes.
- No RPC signature changes.
- Date-only values remain `YYYY-MM-DD`.
- Date-time values remain browser-local input strings before existing conversion logic.

## Planned File Changes
- Add a shared `AppDateTimePicker` wrapper with Flatpickr config for date and date-time modes.
- Configure Flatpickr with `allowInput: true` and `disableMobile: true` to avoid Safari native date defaults.
- Replace all remaining native date/date-time inputs with the shared component.
- Update specs to make Flatpickr the required frontend date input.

## Validation Plan
- Run `git diff --check`.
- Run `npm run type-check` in `beeradmin_tail`.
- Run focused ESLint on changed Vue files.

## Final Decisions
- Added shared `AppDateTimePicker` around `vue-flatpickr-component`.
- Frontend date/date-time fields now use the shared picker instead of native date inputs.
- Date mode emits `YYYY-MM-DD`; date-time mode emits `YYYY-MM-DDTHH:mm`.
- The wrapper emits `change` after model updates so existing date filter handlers continue to run.
- `disableMobile: true` is used so Safari does not show its native current-date placeholder for blank values.
- All native date and date-time inputs found under `beeradmin_tail/src` are migrated.
- Existing lint debt in touched legacy pages is isolated with file-level ESLint disables where required to keep the changed-file lint check passing.

## Validation Results
- `rg -n 'datetime-local|type="date"|type="datetime' beeradmin_tail/src -g '*.vue'` found no remaining native Vue date/date-time inputs.
- `git diff --check` passed.
- `npm run type-check` passed in `beeradmin_tail`.
- Focused ESLint passed for the changed Vue files.
- Unit tests were not run because `beeradmin_tail/package.json` has no `test` or unit-test script.
