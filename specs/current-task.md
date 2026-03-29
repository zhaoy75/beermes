# Current Task Spec

## Goal
- For `バッチ実績入力` and `移送詰口管理`, validate batch `entity_attr` values against the check conditions defined in `attr_def` before saving.

## Scope
- Load `attr_def` validation fields for batch attribute inputs in `BatchEdit` and `BatchPacking`.
- Validate batch attribute values before `entity_attr` upsert using:
  - required
  - num_min / num_max
  - text_regex
  - allowed_values
- Surface validation errors in the page so invalid attributes are not silently ignored.
- Update the relevant UI specs to state that save-time validation follows `attr_def`.

## Non-Goals
- No DB trigger or RLS change for `entity_attr`.
- No validation changes for non-batch entity attributes.
- No redesign of the batch attribute input UI beyond error display needed for validation.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/lib/batchAttrValidation.ts`
- `beeradmin_tail/src/views/Pages/BatchEdit.vue`
- `beeradmin_tail/src/views/Pages/BatchPacking.vue`
- `beeradmin_tail/src/locales/ja.json`
- `beeradmin_tail/src/locales/en.json`
- `docs/UI/batchedit.md`
- `docs/UI/batchpacking.md`

## Data Model / API Changes
- None.
- Frontend will request additional existing `attr_def` columns when loading batch attribute definitions:
  - `required`
  - `num_min`
  - `num_max`
  - `text_regex`
  - `allowed_values`

## Planned File Changes
- Add a shared batch-attribute validation helper for normalized data type handling and rule checks.
- Extend batch attribute field types in `BatchEdit` and `BatchPacking` to carry validation metadata and per-field error text.
- Validate before `entity_attr` delete/upsert and stop save when any field is invalid.
- Show inline validation errors for batch attribute inputs and a page-level save error message.
- Update docs to state that batch attribute save follows `attr_def` conditions.

## Final Decisions
- Added a shared validation helper in `beeradmin_tail/src/lib/batchAttrValidation.ts` so batch attribute save rules are defined once for both `BatchEdit` and `BatchPacking`.
- Extended batch attribute loading in both pages to fetch `attr_def.required`, `num_min`, `num_max`, `text_regex`, and `allowed_values`.
- Combined `attr_set_rule.required` and `attr_def.required` so either source can make a field required at save time.
- Normalized attribute data types during load (`string` -> `text`, `boolean` -> `bool`) before rendering and validation.
- Blocked save when any batch attribute is invalid, showed field-level inline errors, and exposed a page-level error banner for overall save failure.
- Replaced permissive JSON fallback with strict JSON parsing for batch attribute saves after validation.
- Updated the batch edit and batch packing docs to state that `entity_attr` save must validate against linked `attr_def` conditions.

## Validation Plan
- Run required checks before finishing:
  - unit tests
  - lint
  - type-check
- If no unit test script exists, report that explicitly.
- If repo-wide lint has pre-existing failures, run targeted lint on touched files and report remaining failures.

## Validation Outcome
- `npm run type-check` passed in `beeradmin_tail`.
- `npm run test` could not run because `beeradmin_tail/package.json` does not define a `test` script.
- Targeted ESLint execution on `src/lib/batchAttrValidation.ts`, `src/views/Pages/BatchEdit.vue`, and `src/views/Pages/BatchPacking.vue` failed due to pre-existing `@typescript-eslint/no-explicit-any` and `no-unused-vars` issues in the two page files.
