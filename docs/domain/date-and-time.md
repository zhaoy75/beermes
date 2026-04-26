# Date and Timestamp Rules

## Purpose
- Keep business-date fields separate from operational timestamp fields.
- Avoid timezone drift when users input or view dates that have day-level meaning.

## Date-Only Fields
- Store and send date-only values as `YYYY-MM-DD`.
- Render date-only values without time.
- Do not parse `YYYY-MM-DD` through `new Date(...)` for display or comparison.
- Compare and filter date-only values by normalized `YYYY-MM-DD` strings or date-only helpers.
- Inclusive end-date filters should use `< next day`, not `23:59:59`.

## Timestamp Fields
- Keep operational events as full timestamps.
- Examples include movement times, rollback times, batch step execution times, equipment reservations, lot chronology, and audit fields.
- Do not truncate timestamp fields to day unless a specific business rule says the field is date-only.

## Current Date-Only Fields
- `mes_batches.planned_start`
- `mes_batches.planned_end`
- `mes_batches.actual_start`
- `mes_batches.actual_end`
- `mst_equipment.commissioned_at`
- `mst_equipment.decommissioned_at`
- `type_def.valid_from`
- `type_def.valid_to`
- `entity_attr.value_date` when `attr_def.data_type = 'date'`
- `registry_def.spec.start_date`
- `registry_def.spec.expiration_date`

## Compatibility
- Some current date-only business fields are still stored in `timestamptz` columns for compatibility.
- Until those columns are migrated, UI and RPC payloads should still normalize them to `YYYY-MM-DD` and backend functions should truncate them to the day before storing.
