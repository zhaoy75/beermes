# Current Task

## Goal
- Let operational pages use the available screen width instead of being constrained by centered `max-width` wrappers.

## Scope
- Remove the shared admin layout content cap from tenant and system-admin layouts.
- Remove top-level centered `max-w-*` wrappers from operational page containers so right-side panels/action areas can use wider screens.
- Preserve modal/dialog width limits.
- Preserve fixed sidebar/header behavior.

## Non-Goals
- Do not redesign individual page layouts.
- Do not change table columns, forms, or business logic.
- Do not change modal/dialog max widths.
- Do not add a user preference for page width in this pass.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [beeradmin_tail/src/components/layout/AdminLayout.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/components/layout/AdminLayout.vue)
- [beeradmin_tail/src/layouts/SystemAdminLayout.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/layouts/SystemAdminLayout.vue)
- Operational page root containers under [beeradmin_tail/src/views/Pages](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages)

## Data Model / API Changes
- No data model changes.
- No API changes.

## Implementation Notes
- The shared layout currently uses `mx-auto max-w-(--breakpoint-2xl)`, which caps all page content around the 2xl breakpoint.
- Several operational pages add a second top-level `max-w-5xl`, `max-w-6xl`, or `max-w-7xl` wrapper.
- Removing the shared cap alone is not enough for pages with local caps, so update the top-level page wrappers that constrain the main operable area.
- Keep nested modal/dialog `max-w-*` classes because they are not part of the main page operation area.

## Validation Plan
- Run targeted ESLint for touched Vue files.
- Run frontend type-check.
- Run `git diff --check`.
- Run `npm run test --if-present`.
- Run `npm run build:test`.

## Final Decisions
- The shared tenant and system-admin layout wrappers now use full available width instead of `mx-auto max-w-(--breakpoint-2xl)`.
- Main operational page wrappers that constrained the page with `max-w-5xl`, `max-w-6xl`, or `max-w-7xl` were widened to full width.
- Modal/dialog-specific `max-w-*` constraints were left unchanged.
- No business logic, routing, data model, or API behavior changed.

## Validation Results
- `git diff --check -- ...`: passed.
- `npm run type-check` in `beeradmin_tail`: passed.
- `npm run test --if-present` in `beeradmin_tail`: passed with no test script configured.
- `npm run build:test` in `beeradmin_tail`: passed with existing CSS `:is()` minify warnings and existing chunk-size warnings.
- `npx eslint` on the shared layout files and a clean subset of widened pages passed.
- `npx eslint` across every touched Vue file did not pass because several touched pages already contain unrelated lint errors (`no-explicit-any`, unused symbols, and missing script `lang`) outside this layout-only change.
