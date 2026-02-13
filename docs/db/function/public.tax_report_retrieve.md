# `public.tax_report_retrieve(p_year int, p_month int) returns jsonb`

## Purpose
Read saved tax report summary for period.

## Input Contract
- Required: `p_year`, `p_month`.

## Validation
- `p_month` must be `1..12`.

## Data Access
- Read: `tax_reports`.

## Behavior
- Lookup report row by tenant + year + month.

## Output
- JSON object of report row, including breakdown/files arrays.

## Errors
- Invalid month.
- Report not found.
