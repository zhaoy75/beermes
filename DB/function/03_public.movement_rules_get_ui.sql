create or replace function public.movement_rules_get_ui()
returns jsonb
language sql
stable
security invoker
as $$
  select jsonb_build_object(
    'version', '3.1',
    'enums', jsonb_build_object(
      'movement_intent', jsonb_build_array(
        'BREW_PRODUCE','PACKAGE_FILL','INTERNAL_TRANSFER','SHIP_DOMESTIC',
        'SHIP_EXPORT','RETURN_FROM_CUSTOMER','LOSS','DISPOSE'
      ),
      'site_type', jsonb_build_array(
        'BREWERY_MANUFACTUR','BREWERY_STORAGE','TAX_STORAGE','DOMESTIC_CUSTOMER',
        'OVERSEA_CUSTOMER','OTHER_BREWERY','DISPOSAL_FACILITY','DIRECT_SALES_SHOP'
      ),
      'lot_tax_type', jsonb_build_array(
        'TAX_SUSPENDED','TAX_PAID','EXPORT_EXEMPT','OUT_OF_SCOPE'
      ),
      'tax_event', jsonb_build_array(
        'NONE','NON_TAXABLE_REMOVAL','TAXABLE_REMOVAL','EXPORT_EXEMPT','RETURN_TO_FACTORY'
      ),
      'tax_decision_code', jsonb_build_array(
        'NONE','NON_TAXABLE_REMOVAL','TAXABLE_REMOVAL','EXPORT_EXEMPT','RETURN_TO_FACTORY'
      )
    ),
    'tax_transformation_rules', jsonb_build_array(
      jsonb_build_object('movement_intent','PACKAGE_FILL','src_site_type','BREWERY_MANUFACTUR','dst_site_type','BREWERY_STORAGE','lot_tax_type','TAX_SUSPENDED','allowed_tax_decisions',jsonb_build_array(jsonb_build_object('tax_decision_code','NONE','tax_event','NONE','default',true))),
      jsonb_build_object('movement_intent','INTERNAL_TRANSFER','src_site_type','BREWERY_MANUFACTUR','dst_site_type','BREWERY_STORAGE','lot_tax_type','TAX_SUSPENDED','allowed_tax_decisions',jsonb_build_array(jsonb_build_object('tax_decision_code','NON_TAXABLE_REMOVAL','tax_event','NON_TAXABLE_REMOVAL','default',true),jsonb_build_object('tax_decision_code','TAXABLE_REMOVAL','tax_event','TAXABLE_REMOVAL','default',false))),
      jsonb_build_object('movement_intent','INTERNAL_TRANSFER','src_site_type','BREWERY_STORAGE','dst_site_type','TAX_STORAGE','lot_tax_type','TAX_SUSPENDED','allowed_tax_decisions',jsonb_build_array(jsonb_build_object('tax_decision_code','NON_TAXABLE_REMOVAL','tax_event','NON_TAXABLE_REMOVAL','default',true))),
      jsonb_build_object('movement_intent','SHIP_DOMESTIC','src_site_type','BREWERY_STORAGE','dst_site_type','DOMESTIC_CUSTOMER','lot_tax_type','TAX_SUSPENDED','allowed_tax_decisions',jsonb_build_array(jsonb_build_object('tax_decision_code','TAXABLE_REMOVAL','tax_event','TAXABLE_REMOVAL','default',true))),
      jsonb_build_object('movement_intent','SHIP_DOMESTIC','src_site_type','BREWERY_STORAGE','dst_site_type','DOMESTIC_CUSTOMER','lot_tax_type','TAX_PAID','allowed_tax_decisions',jsonb_build_array(jsonb_build_object('tax_decision_code','NONE','tax_event','NONE','default',true))),
      jsonb_build_object('movement_intent','SHIP_EXPORT','src_site_type','TAX_STORAGE','dst_site_type','OVERSEA_CUSTOMER','lot_tax_type','TAX_SUSPENDED','allowed_tax_decisions',jsonb_build_array(jsonb_build_object('tax_decision_code','EXPORT_EXEMPT','tax_event','EXPORT_EXEMPT','default',true))),
      jsonb_build_object('movement_intent','RETURN_FROM_CUSTOMER','src_site_type','DOMESTIC_CUSTOMER','dst_site_type','BREWERY_STORAGE','lot_tax_type','TAX_PAID','allowed_tax_decisions',jsonb_build_array(jsonb_build_object('tax_decision_code','RETURN_TO_FACTORY','tax_event','RETURN_TO_FACTORY','default',true))),
      jsonb_build_object('movement_intent','LOSS','src_site_type','BREWERY_STORAGE','dst_site_type','BREWERY_STORAGE','lot_tax_type','TAX_SUSPENDED','allowed_tax_decisions',jsonb_build_array(jsonb_build_object('tax_decision_code','NON_TAXABLE_REMOVAL','tax_event','NON_TAXABLE_REMOVAL','default',true))),
      jsonb_build_object('movement_intent','DISPOSE','src_site_type','BREWERY_STORAGE','dst_site_type','DISPOSAL_FACILITY','lot_tax_type','TAX_SUSPENDED','allowed_tax_decisions',jsonb_build_array(jsonb_build_object('tax_decision_code','NON_TAXABLE_REMOVAL','tax_event','NON_TAXABLE_REMOVAL','default',true)))
    )
  );
$$;
