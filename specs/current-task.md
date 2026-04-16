# Current Task

## Goal
- Create a sample DML script for `mes.mst_material` covering typical craft beer manufacturing materials.

## Scope
- Add a new SQL seed/sample file under `DB/dml/mes`.
- Follow the repo's existing material seed style:
  - tenant-scoped
  - type and UOM lookup by code
  - `INSERT ... ON CONFLICT (tenant_id, material_code) DO UPDATE`
- Include representative craft beer manufacturing materials across:
  - brewing water
  - malts
  - adjuncts
  - hops
  - yeast
  - process aids / utilities if useful
  - packaging
  - finished goods

## Non-Goals
- Do not change schema.
- Do not modify existing seed files unless necessary.
- Do not add frontend changes.
- Do not redesign recipe sample data in this task.

## Affected Files
- [specs/current-task.md](/Users/zhao/dev/other/beer/specs/current-task.md)
- [DB/dml/mes/mst_material_craft_beer_sample.sql](/Users/zhao/dev/other/beer/DB/dml/mes/mst_material_craft_beer_sample.sql)

## Data Model / API Changes
- None.
- Sample DML targets `mes.mst_material`.

## Final Decisions
- The sample should be safe to rerun through idempotent upsert behavior.
- The sample should use shared `public.type_def` entries in the `material_type` domain and existing `mst_uom` rows.
- The sample should be useful independently of the larger recipe seed files.

## Validation Plan
- Run:
  - review the SQL for consistency with existing seed patterns
  - `npm run type-check` in `beeradmin_tail`
  - `npm run lint` in `beeradmin_tail`
  - `npm run test` in `beeradmin_tail`

## Validation Results
- Pending implementation.
