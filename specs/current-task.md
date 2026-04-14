# Current Task

## Goal
- Restrict `BatchEdit` actual-yield input so `実績生産量` can only be entered when the batch status is in progress or completed.

## Scope
- Update the durable Batch Edit spec to define the allowed statuses for the actual-yield operation.
- Update the Batch Edit UI doc so the same status restriction is documented.
- Enforce the status restriction in the Batch Edit actual-yield button, dialog open flow, and save flow.

## Non-Goals
- Do not change other batch operations.
- Do not change database schema or RPC signatures.
- Do not redesign the actual-yield dialog layout.
- Do not change the existing actual-yield numeric limit in this turn.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [batch-edit-page.md](/Users/zhao/dev/other/beer/specs/batch-edit-page.md)
- [batchedit.md](/Users/zhao/dev/other/beer/docs/UI/batchedit.md)
- [BatchEdit.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/BatchEdit.vue)
- [ja.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/ja.json)
- [en.json](/Users/zhao/dev/other/beer/beeradmin_tail/src/locales/en.json)

## Data Model / API Changes
- No database change.
- No API change.
- Frontend behavior and validation only.

## Planned File Changes
- Update the task-management spec for the actual-yield status restriction.
- Update the durable Batch Edit spec to require batch status `in_progress` or terminal completion status before actual-yield input is allowed.
- Update the Batch Edit UI doc to record the same restriction.
- Disable the actual-yield entry button when the current batch status is not allowed.
- Guard dialog open/save flows with the same status rule and add multilingual feedback.

## Validation Plan
- Run:
  - `npx eslint src/views/Pages/BatchEdit.vue --no-fix` in `beeradmin_tail`
  - `npm run type-check` in `beeradmin_tail`
  - `npm run test` in `beeradmin_tail`

## Final Decisions
- `BatchEdit` actual-yield input is now allowed only when batch status is `in_progress` or terminal `finished`.
- The actual-yield entry button is disabled outside those statuses, and the same rule is enforced again in dialog open/save guards.
- The implementation also accepts `completed` as a compatibility alias in code, but the current status master uses `finished` as the terminal batch status.
- Added multilingual feedback for blocked actual-yield entry.

## Validation Results
- `npx eslint src/views/Pages/BatchEdit.vue --no-fix` in `beeradmin_tail`: passed
- `npm run type-check` in `beeradmin_tail`: passed
- `npm run test` in `beeradmin_tail`: failed because `package.json` has no `test` script
- `node -e "const fs=require('fs'); for (const p of process.argv.slice(1)) JSON.parse(fs.readFileSync(p,'utf8'));" src/locales/ja.json src/locales/en.json` in `beeradmin_tail`: passed
