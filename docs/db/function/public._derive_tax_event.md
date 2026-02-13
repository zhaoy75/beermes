# `public._derive_tax_event(p_context jsonb) returns text`

## Purpose
Resolve tax event code from movement context and rules.

## Input Contract
- Required context keys: `movement_intent`, `src_site_type`, `dst_site_type`, `lot_tax_type`.

## Validation
- Required keys present.
- Values in known enums.

## Data Access
- Read from rule payload source (`movementrule.jsonc` equivalent).

## Behavior
- Locate matching transformation rule.
- Return selected/default `tax_event`.

## Output
- Tax event code text.

## Errors
- No matching rule.
- Ambiguous default selection.
