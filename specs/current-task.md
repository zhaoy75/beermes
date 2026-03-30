# Current Task Spec

## Goal
- Change the `酒税申告` flow so report creation/editing happens on a dedicated page instead of an in-page dialog.
- When a user creates a new monthly tax report draft, also generate the `課税移出一覧表` Excel for the selected month by reusing the existing taxable-removal export source.

## Scope
- Keep `TaxReport.vue` focused on the list/search/create-prompt experience for saved `tax_reports`.
- Create a separate `申告書編集` page/component and route for:
  - creating a new draft from the selected tax period
  - editing an existing saved report
- Move shared tax-report editor logic out of the list page as needed so the editor source is separated from the list page source.
- Reuse the existing `課税移出一覧表` export implementation by extracting shared taxable-removal data/export helpers instead of duplicating the workbook logic inside the tax-report editor.
- On new monthly draft creation, generate a month-scoped `課税移出一覧表` Excel download from the shared export source in addition to the existing tax-report flow.
- Do not expose a manual `課税移出一覧表Excel` button on the dedicated editor page.
- Update UI specs so the list page spec and the editor page spec are separated.

## Non-Goals
- No change to `tax_reports` table schema.
- No change to taxable-removal business rules or movement source tables beyond what is needed to reuse the current export logic.
- No redesign of unrelated tax pages.
- No backend file storage or upload implementation for the generated Excel file in this task; generation remains browser-side unless existing code already persists only file names.

## Affected Files
- `specs/current-task.md`
- `docs/UI/tax-report.md`
- `docs/UI/tax-report-editor.md`
- `docs/UI/tax-removal-report.md`
- `beeradmin_tail/src/router/tenant-routes.ts`
- `beeradmin_tail/src/views/Pages/TaxReport.vue`
- `beeradmin_tail/src/views/Pages/TaxReportEditor.vue`
- `beeradmin_tail/src/views/Pages/TaxableRemovalReport.vue`
- `beeradmin_tail/src/lib/*` or `beeradmin_tail/src/composables/*` shared tax-report / taxable-removal helper files as needed
- `beeradmin_tail/src/locales/ja.json`
- `beeradmin_tail/src/locales/en.json`

## Data Model / API Changes
- No database schema changes planned.
- Frontend routing will add a dedicated tax-report editor route.
- Shared frontend helper APIs may be introduced for:
  - tax-report editor state / load-save behavior
  - taxable-removal data loading
  - taxable-removal workbook generation for full business-year export and selected-month export

## Planned File Changes
- Shrink `TaxReport.vue` to the list page and replace modal open/edit behavior with navigation to the dedicated editor page.
- Add a new `TaxReportEditor.vue` page for create/edit.
- Add a router entry for the editor page.
- Extract reusable taxable-removal export/data logic from `TaxableRemovalReport.vue`.
- Use the shared taxable-removal export source from the tax-report editor to generate the selected-month Excel during new monthly report creation.
- Split the UI documentation into separate list-page and editor-page specs.

## Final Decisions
- `TaxReport.vue` now only handles list/search/create-prompt/delete/XML-download behavior.
- A new dedicated editor route and page were added:
  - `/taxReports/new`
  - `/taxReports/:id`
- Tax-report XML helpers were extracted into a shared frontend module so the list page and editor page use the same XML rebuild logic.
- Taxable-removal data loading and workbook generation were extracted into a shared frontend module, and `TaxableRemovalReport.vue` now uses that shared source.
- New monthly tax-report creation now auto-generates the selected-month `課税移出一覧表` Excel from the shared taxable-removal export source.
- The dedicated editor page does not expose a manual `課税移出一覧表Excel` button.
- UI docs were split so the list page and editor page have separate specifications.

## Validation Plan
- Run required checks before finishing:
  - unit tests
  - lint
  - type-check
- If a required script does not exist, report that explicitly.

## Validation Outcome
- `npm run type-check` in `beeradmin_tail`: pass.
- `npm run lint` in `beeradmin_tail`: failed on many pre-existing project-wide ESLint violations outside this task's files.
- `npx eslint src/lib/taxReport.ts src/lib/taxableRemovalReport.ts src/views/Pages/TaxReport.vue src/views/Pages/TaxReportEditor.vue src/views/Pages/TaxableRemovalReport.vue src/router/tenant-routes.ts` in `beeradmin_tail`: pass.
- `npm run test` in `beeradmin_tail`: failed because `package.json` has no `test` script.
