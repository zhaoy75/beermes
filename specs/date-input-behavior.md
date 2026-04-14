# Date Input Behavior

## Goal
- Define one consistent rule for date-capable inputs across the app.

## Scope
- `beeradmin_tail` pages, page components, and shared screens that use native `input[type="date"]` or `input[type="datetime-local"]`.

## Rules
- Native `input[type="date"]` inputs must open the browser calendar picker on focus when the browser supports `showPicker()`.
- Native `input[type="datetime-local"]` inputs must open the browser date/time picker on focus when the browser supports `showPicker()`.
- The shared behavior must ignore disabled and readonly inputs.
- If the browser does not support `showPicker()`, the input must continue to work as a normal native field without throwing errors.
- This behavior should be provided centrally so newly added pages inherit the same rule without page-specific duplicate handlers.

## Non-Goals
- Do not introduce a third-party date-picker library.
- Do not override locale-specific browser formatting.
- Do not change stored values or API payload formats.
