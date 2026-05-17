# Current Task

## Goal
- Hide the notification icon/menu from the shared application header.

## Scope
- Remove the notification menu render from the shared `AppHeader`.
- Remove the now-unused notification menu import from `AppHeader`.
- Preserve the language selector, user menu, search bar, and sidebar toggle behavior.

## Non-Goals
- Do not delete `NotificationMenu.vue`.
- Do not remove notification translations or icons.
- Do not change header spacing beyond the natural removal of the notification button.
- Do not alter sidebar layout changes from prior work.

## Affected Files
- `specs/current-task.md`
- `beeradmin_tail/src/components/layout/AppHeader.vue`

## Data Model / API Changes
- No database schema changes.
- No application API changes.
- Frontend header-only change.

## Validation Plan
- Run `git diff --check -- specs/current-task.md beeradmin_tail/src/components/layout/AppHeader.vue`.
- Run `npm run type-check` in `beeradmin_tail`.
- Run focused ESLint for `AppHeader.vue`.

## Planned File Changes
- `AppHeader.vue`: remove `<NotificationMenu />` from the header action area and remove its import.
- `specs/current-task.md`: document scope, validation, and final decisions.

## Final Decisions
- Removed `<NotificationMenu />` from the shared `AppHeader` action area.
- Removed the now-unused `NotificationMenu` import from `AppHeader`.
- Kept `NotificationMenu.vue`, notification locales, and icon exports untouched.
- Language selector, user menu, search bar, and sidebar toggle remain in place.

## Validation Results
- `git diff --check -- specs/current-task.md beeradmin_tail/src/components/layout/AppHeader.vue` passed.
- `npm run type-check` passed in `beeradmin_tail`.
- `npx eslint src/components/layout/AppHeader.vue --no-fix` passed.
- Verified `AppHeader.vue` no longer references `NotificationMenu`.
- Unit tests were not run because `beeradmin_tail/package.json` does not define a unit test script.
