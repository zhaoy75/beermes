
# Purpose

 a set of postgres stored function to handle movement events from brew_production, filling and various kind of movement. I need you to care about the data intergrity.

# Stored function architecture

there should be a public entry point, a set of internal shared primitives function and Intent-specific rule function for each movement_intent

## Public entrypoint (stable API)

public.register_movement(p_doc jsonb) returns uuid

Responsibilities:
	•	parse header
	•	idempotency check (optional but strongly recommended)
	•	insert movement + lines
	•	call validate_* and apply_*
	•	return movement_id

## Internal shared primitives (small)
	•	assert_tenant() / assert_user()
	•	assert_lot_material_match(lot_id, material_id)
	•	lock_lots_for_update(lot_ids[])  (prevents race conditions)
	•	apply_lot_edge(from_lot, to_lot, qty, edge_type) (updates balances)
	•	assert_non_negative(lot_id)
	•	convert_qty(qty, from_uom, to_uom) (if needed)

## Intent-specific rule functions (small)
	•	validate_intent_package_fill(movement, lines)
	•	validate_intent_ship_domestic_taxable(...)
	•	validate_intent_move_to_storage(...)
	•	validate_intent_dispose(...)
	•	derive_tax_event(move_intent, from_site_type, to_site_type, …)

# The movement intent
   the movement intent includes 
    BREW_PRODUCE 
    PACKAGE_FILL
    REFILL
    INTERNAL_TRANSFER
    SHIP_DOMESTIC
    SHIP_EXPORT
    RETURN_FROM_CUSTOMER
    LOSS
    DISPOSE



enums
  movement_intent
  site_type
  lot_tax_type
  tax_event
  edge_type
movement_intent
allowed_site_types
  array of src_site_types
  array of dst_site_types
tax_transformation_rules
  array of {src_site_type, dst_site_type, src_lot_tax_type, dst_lot_tax_type, tax_event}

