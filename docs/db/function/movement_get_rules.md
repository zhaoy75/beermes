# `public.movement_get_rules() returns list`

## Purpose
retrieve rules for the movement intent

## Input Contract
- movement intent.

## Validation
- validate movement intent is valid in registry_def table

## Data Access
get movement intent list from following table
- Table: `public.registry_def`
  - Selector:
    - `kind = 'ruleengine'`
    - `def_key = 'beer_movement_rule'`
    - `is_active = true`

## Behavior
- Retrieve rule json file. Read it and return following json
- return 
    enums
    enum labels
    tax_decision_code 
    movement_intents_rules only march with input movement intent
    tax_transformation_rules only march with input movement intent

## Output
- 

## Errors
- none
