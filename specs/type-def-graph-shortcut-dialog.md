# TypeDef Shortcut Column Browser Spec

## Goal
- Provide a global shortcut, `Ctrl/Cmd+T`, that opens a read-only dialog for searching and browsing `type_def` with a column-browser UI.

## Entry Point
- Global keyboard shortcut from the admin layout:
  - `Ctrl+T` on Windows/Linux
  - `Cmd+T` on macOS

## Scope
- Open a modal dialog from any tenant admin page.
- Show a domain dropdown and search box at the top of the dialog.
- Load and browse `public.type_def` rows for the selected domain.
- Render the hierarchy as a read-only column browser:
  - first column shows root nodes
  - selecting a row opens its children in the next column
  - the selected branch remains visible as a left-to-right path
- Keep the feature read-only.

## Non-Goals
- No create, edit, delete, or drag-drop behavior in this dialog.
- No replacement of the existing `TypeMaster.vue` maintenance page.
- No schema or RPC changes.
- No graph canvas or force-directed visualization in this dialog.

## Data Sources
- `public.type_def`
- `public.industry`

## Domain Behavior
- Domain options are populated from existing `type_def.domain` values.
- Built-in fallback domains must still appear:
  - `material_type`
  - `equipment_type`
- Changing the dropdown reloads the browser for the selected domain.
- Reload resets the visible branch to a safe default selection in the new domain.

## Layout
### Header
- title
- subtitle
- close button
- close shortcut hint

### Toolbar
- domain dropdown
- search input
- refresh button

### Main Area
- loading state
- error state
- empty state
- horizontally scrollable column browser

## Browser Rules
- Build a tree from:
  - `type_id`
  - `parent_type_id`
- Nodes without a resolvable parent in the current domain become roots.
- Sort siblings by:
  1. `sort_order`
  2. `code`
- Column 1 shows roots.
- Selecting a row in column `N` replaces the current path from `N` onward and shows child rows in column `N + 1`.
- The currently selected node must remain visually distinct.
- Matched rows should be highlighted when search is active.
- Double-clicking a row returns that type to the caller when the dialog was opened by a page-level input flow.

## Search Rules
- Search targets:
  - `code`
  - `name`
  - `name_i18n.ja`
  - `name_i18n.en`
- Search is client-side on the loaded domain rows.
- Search visually highlights matched rows in the column browser.

## Keyboard and Accessibility
- When opened, focus moves to the search input.
- `Escape` closes the dialog.
- Focus returns to the previously focused element after close.
- The dialog uses modal semantics from the shared modal component.
- When focus is not inside an input or select:
  - `ArrowUp` / `ArrowDown` move within the current column
  - `ArrowRight` moves into the first child column when children exist
  - `ArrowLeft` moves back to the parent column

## Integration Rules
- The feature lives in shared admin layout, not in individual pages.
- It must coexist with the existing inventory search shortcut.
- If another global modal is already open, do not stack the type browser dialog on top of it.
- Other pages may open the same dialog programmatically with:
  - a preferred starting domain
  - a flag that disables focus restoration on close when reopening the same field would cause a loop
  - a selection callback that receives the chosen `type_def` row identity

## Implementation Notes
- Shared modal state is stored in a dedicated composable.
- The dialog is implemented as a dedicated component.
- Keep the existing shortcut wiring and modal state API if possible to minimize unrelated code churn.

## Validation
- Targeted ESLint for:
  - `AdminLayout.vue`
  - `TypeDefGraphModal.vue`
  - `useTypeDefGraphModal.ts`
- Locale JSON parse check
- Type-check
- Existing repo-wide lint/test status may remain unchanged outside this feature
