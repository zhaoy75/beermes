# `public.movement_rules_get_ui() returns jsonb`

## Purpose
Provide movement-rule payload for UI wizard.

## Input Contract
- No input.

## Validation
- Ensure JSON payload has required sections (`enums`, `movement_intent_rules`, `tax_transformation_rules`).

## Data Access
- Current: no DB table required.

## Behavior
- Return JSON payload equivalent to `docs/data/movementrule.jsonc`.
- Implementation options:
- Embedded JSON in function.
- Future: read from config table.

## Output
- Full rules JSON.

## Errors
- Rule payload missing required keys.
