# Date Input Behavior

## Goal
- Define one consistent rule for date-capable inputs across the app.

## Scope
- `beeradmin_tail` pages, page components, and shared screens that accept date or date-time input.

## Rules
- All frontend date and date-time inputs under `beeradmin_tail/src` must use the shared `AppDateTimePicker` Flatpickr wrapper.
- The shared picker must render blank values as visually blank in Safari and Chrome.
- Date mode must emit `YYYY-MM-DD`.
- Date-time mode must emit `YYYY-MM-DDTHH:mm` before page-specific conversion to UTC/API payloads.
- The shared picker must emit `change` after model updates so existing search/filter handlers continue to work.
- The picker must use `disableMobile: true` to avoid Safari native date placeholders.
- New native `type="date"` and `type="datetime-local"` inputs should not be added to Vue pages.

## Non-Goals
- Do not introduce any new date-picker dependency beyond the existing Flatpickr package.
- Do not change stored values or API payload formats.
