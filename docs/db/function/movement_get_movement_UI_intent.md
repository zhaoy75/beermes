# `public.movement_get_movement_UI_intent() returns list`

## Purpose
retrieve movement intent list should shown in the movement register dialog

## Input Contract
- No input.

## Validation

## Data Access
get movement intent list from following table
- Table: `public.registry_def`
  - Selector:
    - `kind = 'ruleengine'`
    - `def_key = 'beer_movement_rule'`
    - `is_active = true`

## Behavior
- Return list of movement intent 
- from movement_intent_labels get i18n name
- only return movement intent which show_in_movement_wizard is true

## Output
- list of movement intent and i18n name

## Errors
- none
