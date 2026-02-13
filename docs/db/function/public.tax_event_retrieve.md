# `public.tax_event_retrieve(p_filter jsonb) returns table (...)`

## Purpose
List tax-relevant lot events for reporting screens.

## Input Contract
- Optional filters: `event_type`, `status`, date range, sites, `tax_event`.

## Validation
- Filter values and date window.

## Data Access
- Read: `lot_event`.

## Behavior
- Read `tax_event` from `lot_event.meta ->> 'tax_event'`.
- Return event-level rows.

## Output
- Rows from signature.

## Errors
- Invalid filter payload.
