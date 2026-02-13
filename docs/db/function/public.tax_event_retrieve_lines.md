# `public.tax_event_retrieve_lines(p_lot_event_id uuid) returns jsonb`

## Purpose
Return one tax event with detailed lines.

## Input Contract
- Required: `p_lot_event_id`.

## Validation
- Event exists and tenant-visible.

## Data Access
- Read: `lot_event`, `lot_event_line`, `lot`.

## Behavior
- Build JSON structure with header and line array.
- Include lot identifiers and quantities.

## Output
- JSON object: `{event, lines}`.

## Errors
- Event not found.
