# `public.movement_rules_get_tax_decisions(p_movement_intent text, p_src_site_type text, p_dst_site_type text, p_lot_tax_type text) returns jsonb`

## Purpose
Return allowed tax decisions for selected movement context.

## Input Contract
- Required all four parameters.

## Validation
- Inputs must match valid enum values in movement-rule definitions.

## Data Access
- Reads rules payload (same source as `movement_rules_get_ui`).

## Behavior
- Find matching rule row by intent/src/dst/lot-tax-type.
- Return `allowed_tax_decisions` array.

## Output
- JSON array of decision candidates.

## Errors
- No rule match.
- Invalid enum code input.
