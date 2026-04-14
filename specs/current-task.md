# Current Task Spec

## Goal
- Make the `原材料種別` tree on the `MaterialMaster` page foldable.
- Make the `原材料種別` side panel itself hideable.
- Keep the existing material-type-first maintenance flow unchanged while improving tree navigation for large type hierarchies.

## Scope
- Update the `MaterialMaster` left-side type tree so parent nodes can be expanded and collapsed.
- Add a UI control so the entire `原材料種別` panel can be hidden and shown again.
- Preserve existing behaviors:
  - type search
  - selected type summary
  - subtree-based material filtering
  - create/edit flows tied to the selected type
- Keep the current page layout and data sources.

## Non-Goals
- Do not redesign the `MaterialMaster` page layout.
- Do not change material CRUD behavior.
- Do not add attribute editing to this page.
- Do not refactor `EquipmentMaster` in this task.
- Do not change backend schema or queries.

## Affected Files
- [current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [MaterialMaster.vue](/Users/zhao/dev/other/beer/beeradmin_tail/src/views/Pages/MaterialMaster.vue)

## Data Model / API Changes
- No database changes.
- No API contract changes.
- Tree expand/collapse state is UI-only page state.
- Panel visibility is also UI-only page state.

## Planned File Changes
- Update `MaterialMaster.vue` to:
  - render expand/collapse controls for type nodes that have children
  - track expanded node state in component state
  - only render visible descendants for expanded nodes
  - auto-expand during type search so matches are not hidden behind collapsed parents
  - add a show/hide toggle for the whole `原材料種別` panel
  - adjust the desktop grid layout when the left panel is hidden
- Replace the stale `current-task.md` content with this task-specific spec.

## Final Decisions
- Default tree state should remain broadly expanded so the change is additive, not disruptive.
- Fold/unfold is controlled per node, not by replacing the current page with a different tree component.
- Search should temporarily ignore manual collapse state and show matching branches expanded.
- When the selected type changes, the tree should auto-expand that type's ancestor path so the current selection remains visible in the tree.
- Hiding the panel should not clear the selected type; the current selection remains active for filtering and form context.
- The whole `原材料種別` panel is toggled from the page header, and the open panel also exposes a local collapse button in its own header.
- When the panel is hidden, the desktop layout switches from three columns to two columns so the list and form panes use the freed space.

## Validation Plan
- Run:
  - `npx eslint src/views/Pages/MaterialMaster.vue --no-fix` in `beeradmin_tail`
  - `npm run type-check` in `beeradmin_tail`
  - `npm run test` in `beeradmin_tail`
  - `npx eslint . --no-fix` in `beeradmin_tail`

## Validation Results
- `npx eslint src/views/Pages/MaterialMaster.vue --no-fix` in `beeradmin_tail`: passed
- `npm run type-check` in `beeradmin_tail`: passed
- `npm run test` in `beeradmin_tail`: failed because `beeradmin_tail/package.json` has no `test` script
- `npx eslint . --no-fix` in `beeradmin_tail`: failed on the existing repo-wide ESLint backlog unrelated to this change
