# Current Task Spec

## Goal
- Update the System Admin ground design to adopt a module-based frontend structure.
- Refactor the frontend architecture to introduce module-based route/layout/guard separation for tenant scope and system-admin scope.

## Scope
- Update `docs/system-admin-ground-design.md` so the target frontend architecture is module-based, using:
  - `modules/tenant/*`
  - `modules/system-admin/*`
  - `router/tenant-routes.ts`
  - `router/system-routes.ts`
  - `layouts/TenantLayout.vue`
  - `layouts/SystemAdminLayout.vue`
  - `guards/tenantGuard.ts`
  - `guards/systemAdminGuard.ts`
- Implement that structure in the current frontend codebase with minimal disruption to existing tenant pages.
- Add initial System Admin pages, services, stores, layout, sidebar, routes, and guard wiring.
- Preserve the existing application behavior for current tenant routes while moving route definitions into dedicated route modules.

## Non-Goals
- Full migration of every existing tenant page into `modules/tenant/pages` in one step.
- Backend schema or Edge Function implementation for the full system-admin domain.
- Broad redesign of existing tenant page internals.
- Fixing unrelated pre-existing lint issues across the repository.

## Affected Files
- `specs/current-task.md`
- `docs/system-admin-ground-design.md`
- `beeradmin_tail/src/router/index.ts`
- `beeradmin_tail/src/router/tenant-routes.ts`
- `beeradmin_tail/src/router/system-routes.ts`
- `beeradmin_tail/src/guards/tenantGuard.ts`
- `beeradmin_tail/src/guards/systemAdminGuard.ts`
- `beeradmin_tail/src/layouts/TenantLayout.vue`
- `beeradmin_tail/src/layouts/SystemAdminLayout.vue`
- `beeradmin_tail/src/modules/system-admin/pages/*`
- `beeradmin_tail/src/modules/system-admin/components/*`
- `beeradmin_tail/src/modules/system-admin/services/*`
- `beeradmin_tail/src/modules/system-admin/stores/*`
- `beeradmin_tail/src/modules/tenant/services/*`
- `beeradmin_tail/src/modules/tenant/stores/*`
- `beeradmin_tail/src/stores/auth.ts`
- `beeradmin_tail/src/locales/en.json`
- `beeradmin_tail/src/locales/ja.json`

## Data Model / API Changes
- No required backend schema changes in this task.
- Frontend code should read system-admin capability from session metadata when present.
- System-admin services may use placeholder or direct-read patterns compatible with the current backend until full backend implementation is added later.

## Validation Plan
- Confirm the design document reflects the module-based frontend structure.
- Run frontend type-check.
- Run frontend lint and report unrelated existing failures if any remain.
- Verify the new route split and guard files are wired into the main router.

## Planned File Changes
- `specs/current-task.md`: replace the previous doc-only task with the module-based refactor task.
- `docs/system-admin-ground-design.md`: update the design to make the sample structure the target frontend architecture.
- `beeradmin_tail/src/router/*`: split tenant and system-admin routes.
- `beeradmin_tail/src/guards/*`: add tenant and system-admin guards.
- `beeradmin_tail/src/layouts/*`: add dedicated tenant and system-admin layouts.
- `beeradmin_tail/src/modules/system-admin/*`: add initial module pages/components/services/stores.
- `beeradmin_tail/src/modules/tenant/*`: add initial tenant module services/stores to support the new architecture.
- `beeradmin_tail/src/stores/auth.ts`: expose system-admin metadata for guards and UI.
- `beeradmin_tail/src/locales/*.json`: add system-admin labels.

## Final Decisions
- Updated `docs/system-admin-ground-design.md` so the module-based frontend structure is the target architecture for this repo.
- Split route definitions into:
  - `beeradmin_tail/src/router/tenant-routes.ts`
  - `beeradmin_tail/src/router/system-routes.ts`
- Replaced the monolithic guard logic in `beeradmin_tail/src/router/index.ts` with:
  - `beeradmin_tail/src/guards/tenantGuard.ts`
  - `beeradmin_tail/src/guards/systemAdminGuard.ts`
- Added dedicated layout shells:
  - `beeradmin_tail/src/layouts/TenantLayout.vue`
  - `beeradmin_tail/src/layouts/SystemAdminLayout.vue`
- Added initial module boundaries:
  - `beeradmin_tail/src/modules/system-admin/*`
  - `beeradmin_tail/src/modules/tenant/*`
- Added an initial System Admin UI slice with:
  - dashboard page
  - tenant list page
  - tenant detail page
  - audit placeholder page
  - dedicated system-admin sidebar
- Updated `beeradmin_tail/src/stores/auth.ts` to keep tenant and system-admin metadata in store state and to make `set-tenant` failure non-fatal during sign-in.
- Added System Admin navigation labels to `beeradmin_tail/src/locales/en.json` and `beeradmin_tail/src/locales/ja.json`, and exposed a System Admin entry link from the existing tenant sidebar for system-admin users.
- Validation outcome:
  - `npm run type-check` in `beeradmin_tail`: passed
  - locale JSON parse check: passed
  - `npm exec eslint .` in `beeradmin_tail`: failed due to large pre-existing unrelated lint errors already present across the repository
  - unit tests: no unit test script is defined in `beeradmin_tail/package.json`
