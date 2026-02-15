-- System-wide Japanese address definition
INSERT INTO registry_def (kind, def_key, scope, owner_id, spec)
VALUES (
  'ruleengine',
  'beer_movement_rule',
  'system',
  NULL,
  '{
  "version": "3.1",
  "domain": "alcohol_beer",

  "enums": {
    "movement_intent": [
      "INTERNAL_TRANSFER",
      "SHIP_DOMESTIC",
      "SHIP_EXPORT",
      "RETURN_FROM_CUSTOMER",
      "LOSS",
      "DISPOSE"
    ],
    "site_type": [
      "BREWERY_MANUFACTUR",
      "BREWERY_STORAGE",
      "TAX_STORAGE",
      "DOMESTIC_CUSTOMER",
      "OVERSEA_CUSTOMER",
      "OTHER_BREWERY",
      "DISPOSAL_FACILITY",
      "DIRECT_SALES_SHOP"
    ],
    "lot_tax_type": [
      "TAX_SUSPENDED",
      "TAX_PAID",
      "EXPORT_EXEMPT",
      "OUT_OF_SCOPE"
    ],
    "tax_event": [
      "NONE",
      "NON_TAXABLE_REMOVAL",
      "TAXABLE_REMOVAL",
      "EXPORT_EXEMPT",
      "RETURN_TO_FACTORY"
    ],
    "edge_type": [
      "PRODUCE",
      "MOVE",
      "CONSUME",
      "SPLIT",
      "MERGE"
    ],
    "tax_decision_code": [
      "NONE",
      "NON_TAXABLE_REMOVAL",
      "TAXABLE_REMOVAL",
      "EXPORT_EXEMPT",
      "RETURN_TO_FACTORY"
    ]
  },

  "movement_intent_labels": {
    "BREW_PRODUCE": { "ja": "生成（製造）", "en": "Produce (Brew)" , "show_in_movement_wizard": false},
    "PACKAGE_FILL": { "ja": "詰口（充填）", "en": "Package Fill" , "show_in_movement_wizard": false },
    "INTERNAL_TRANSFER": { "ja": "社内移動", "en": "Internal Transfer", "show_in_movement_wizard": true },
    "SHIP_DOMESTIC": { "ja": "国内出荷", "en": "Domestic Shipment" , "show_in_movement_wizard": true },
    "SHIP_EXPORT": { "ja": "輸出（免税）", "en": "Export (Exempt)" , "show_in_movement_wizard": true },
    "RETURN_FROM_CUSTOMER": { "ja": "返品（戻入）", "en": "Return from Customer" , "show_in_movement_wizard": true },
    "LOSS": { "ja": "滅失（事故・破損）", "en": "Loss" , "show_in_movement_wizard": true },
    "DISPOSE": { "ja": "廃棄", "en": "Dispose" , "show_in_movement_wizard": true }
  },

  "tax_decision_definitions": [
    {
      "tax_decision_code": "NONE",
      "name_en": "No Tax Impact",
      "name_ja": "税務影響なし",
      "tax_event": "NONE",
      "affects_tax_ledger": false,
      "requires_tax_declaration": false,
      "changes_lot_tax_type": false,
      "requires_approval": false,
      "requires_reference_document": false,
      "description": "Pure inventory movement without tax implication."
    },
    {
      "tax_decision_code": "NON_TAXABLE_REMOVAL",
      "name_en": "Non-Taxable Removal",
      "name_ja": "非納税移出",
      "tax_event": "NON_TAXABLE_REMOVAL",
      "affects_tax_ledger": false,
      "requires_tax_declaration": true,
      "changes_lot_tax_type": false,
      "requires_approval": true,
      "requires_reference_document": true,
      "description": "Removal under suspension / loss / destruction process without triggering tax payment."
    },
    {
      "tax_decision_code": "TAXABLE_REMOVAL",
      "name_en": "Taxable Removal",
      "name_ja": "課税移出",
      "tax_event": "TAXABLE_REMOVAL",
      "affects_tax_ledger": true,
      "requires_tax_declaration": true,
      "changes_lot_tax_type": true,
      "requires_approval": true,
      "requires_reference_document": true,
      "description": "Domestic shipment that triggers alcohol tax payment."
    },
    {
      "tax_decision_code": "EXPORT_EXEMPT",
      "name_en": "Export Exemption",
      "name_ja": "輸出免税",
      "tax_event": "EXPORT_EXEMPT",
      "affects_tax_ledger": false,
      "requires_tax_declaration": true,
      "changes_lot_tax_type": true,
      "requires_approval": true,
      "requires_reference_document": true,
      "description": "Export shipment under exemption (tax-free export)."
    },
    {
      "tax_decision_code": "RETURN_TO_FACTORY",
      "name_en": "Return to Factory",
      "name_ja": "戻入",
      "tax_event": "RETURN_TO_FACTORY",
      "affects_tax_ledger": true,
      "requires_tax_declaration": true,
      "changes_lot_tax_type": false,
      "requires_approval": true,
      "requires_reference_document": true,
      "description": "Return adjustment for tax reconciliation (e.g., returned goods)."
    }
  ],

  "movement_intent_rules": [
    {
      "movement_intent": "BREW_PRODUCE",
      "edge_type": "PRODUCE",
      "allowed_src_site_types": ["BREWERY_MANUFACTUR"],
      "allowed_dst_site_types": ["BREWERY_MANUFACTUR"],
      "ui_hints": {
        "wizard_entry": true,
        "icon": "produce",
        "title_en": "Produce",
        "title_ja": "製造"
      }
    },
    {
      "movement_intent": "PACKAGE_FILL",
      "edge_type": "CONSUME",
      "allowed_src_site_types": ["BREWERY_MANUFACTUR"],
      "allowed_dst_site_types": ["BREWERY_STORAGE", "DIRECT_SALES_SHOP"],
      "ui_hints": {
        "wizard_entry": true,
        "icon": "package",
        "title_en": "Package / Fill",
        "title_ja": "充填"
      }
    },
    {
      "movement_intent": "INTERNAL_TRANSFER",
      "edge_type": "MOVE",
      "allowed_src_site_types": ["BREWERY_MANUFACTUR", "BREWERY_STORAGE"],
      "allowed_dst_site_types": ["BREWERY_MANUFACTUR", "BREWERY_STORAGE", "TAX_STORAGE"],
      "ui_hints": {
        "wizard_entry": true,
        "icon": "transfer",
        "title_en": "Internal Transfer",
        "title_ja": "場内移動"
      }
    },
    {
      "movement_intent": "SHIP_DOMESTIC",
      "edge_type": "MOVE",
      "allowed_src_site_types": ["BREWERY_STORAGE", "DIRECT_SALES_SHOP"],
      "allowed_dst_site_types": ["DOMESTIC_CUSTOMER"],
      "ui_hints": {
        "wizard_entry": true,
        "icon": "truck",
        "title_en": "Ship Domestic",
        "title_ja": "国内出荷"
      }
    },
    {
      "movement_intent": "SHIP_EXPORT",
      "edge_type": "MOVE",
      "allowed_src_site_types": ["BREWERY_STORAGE", "TAX_STORAGE"],
      "allowed_dst_site_types": ["OVERSEA_CUSTOMER"],
      "ui_hints": {
        "wizard_entry": true,
        "icon": "ship",
        "title_en": "Ship Export",
        "title_ja": "輸出"
      }
    },
    {
      "movement_intent": "RETURN_FROM_CUSTOMER",
      "edge_type": "MOVE",
      "allowed_src_site_types": ["DOMESTIC_CUSTOMER"],
      "allowed_dst_site_types": ["BREWERY_STORAGE", "BREWERY_MANUFACTUR"],
      "ui_hints": {
        "wizard_entry": true,
        "icon": "return",
        "title_en": "Return",
        "title_ja": "戻入"
      }
    },
    {
      "movement_intent": "LOSS",
      "edge_type": "CONSUME",
      "allowed_src_site_types": ["BREWERY_MANUFACTUR", "BREWERY_STORAGE", "TAX_STORAGE"],
      "allowed_dst_site_types": ["BREWERY_STORAGE"],
      "ui_hints": {
        "wizard_entry": true,
        "icon": "loss",
        "title_en": "Loss",
        "title_ja": "欠減"
      }
    },
    {
      "movement_intent": "DISPOSE",
      "edge_type": "CONSUME",
      "allowed_src_site_types": ["BREWERY_MANUFACTUR", "BREWERY_STORAGE", "TAX_STORAGE"],
      "allowed_dst_site_types": ["DISPOSAL_FACILITY"],
      "ui_hints": {
        "wizard_entry": true,
        "icon": "dispose",
        "title_en": "Dispose",
        "title_ja": "廃棄"
      }
    }
  ],

  "tax_transformation_rules": [
    {
      "movement_intent": "BREW_PRODUCE",
      "src_site_type": "BREWERY_MANUFACTUR",
      "dst_site_type": "BREWERY_MANUFACTUR",
      "lot_tax_type": "OUT_OF_SCOPE",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "NONE",
          "tax_event": "NONE",
          "result_lot_tax_type": "TAX_SUSPENDED",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": false,
            "lot_split_required": false,
            "approval_required": false,
            "require_reference_document": false,
            "require_reason_code": false
          }
        }
      ]
    },

    {
      "movement_intent": "PACKAGE_FILL",
      "src_site_type": "BREWERY_MANUFACTUR",
      "dst_site_type": "BREWERY_STORAGE",
      "lot_tax_type": "TAX_SUSPENDED",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "NONE",
          "tax_event": "NONE",
          "result_lot_tax_type": "TAX_SUSPENDED",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": true,
            "lot_split_required": true,
            "approval_required": false,
            "require_reference_document": false,
            "require_reason_code": false
          }
        }
      ]
    },

    {
      "movement_intent": "INTERNAL_TRANSFER",
      "src_site_type": "BREWERY_MANUFACTUR",
      "dst_site_type": "BREWERY_STORAGE",
      "lot_tax_type": "TAX_SUSPENDED",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "NON_TAXABLE_REMOVAL",
          "tax_event": "NON_TAXABLE_REMOVAL",
          "result_lot_tax_type": "TAX_SUSPENDED",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": true,
            "lot_split_required": false,
            "approval_required": false,
            "require_reference_document": false,
            "require_reason_code": false
          }
        },
        {
          "tax_decision_code": "TAXABLE_REMOVAL",
          "tax_event": "TAXABLE_REMOVAL",
          "result_lot_tax_type": "TAX_PAID",
          "default": false,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": true,
            "lot_split_required": false,
            "approval_required": false,
            "require_reference_document": false,
            "require_reason_code": false
          }
        }
      ]
    },
    {
      "movement_intent": "INTERNAL_TRANSFER",
      "src_site_type": "BREWERY_STORAGE",
      "dst_site_type": "BREWERY_MANUFACTUR",
      "lot_tax_type": "TAX_SUSPENDED",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "NONE",
          "tax_event": "NONE",
          "result_lot_tax_type": "TAX_SUSPENDED",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": true,
            "lot_split_required": false,
            "approval_required": false,
            "require_reference_document": false,
            "require_reason_code": false
          }
        }
      ]
    },

    {
      "movement_intent": "INTERNAL_TRANSFER",
      "src_site_type": "BREWERY_STORAGE",
      "dst_site_type": "TAX_STORAGE",
      "lot_tax_type": "TAX_SUSPENDED",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "NON_TAXABLE_REMOVAL",
          "tax_event": "NON_TAXABLE_REMOVAL",
          "result_lot_tax_type": "TAX_SUSPENDED",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": true,
            "lot_split_required": true,
            "approval_required": true,
            "require_reference_document": true,
            "require_reason_code": false
          }
        }
      ]
    },

    {
      "movement_intent": "SHIP_DOMESTIC",
      "src_site_type": "BREWERY_STORAGE",
      "dst_site_type": "DOMESTIC_CUSTOMER",
      "lot_tax_type": "TAX_SUSPENDED",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "TAXABLE_REMOVAL",
          "tax_event": "TAXABLE_REMOVAL",
          "result_lot_tax_type": "TAX_PAID",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": true,
            "lot_split_required": true,
            "approval_required": true,
            "require_reference_document": true,
            "require_reason_code": false
          }
        }
      ]
    },
    {
      "movement_intent": "SHIP_DOMESTIC",
      "src_site_type": "DIRECT_SALES_SHOP",
      "dst_site_type": "DOMESTIC_CUSTOMER",
      "lot_tax_type": "TAX_SUSPENDED",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "TAXABLE_REMOVAL",
          "tax_event": "TAXABLE_REMOVAL",
          "result_lot_tax_type": "TAX_PAID",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": true,
            "lot_split_required": true,
            "approval_required": true,
            "require_reference_document": true,
            "require_reason_code": false
          }
        }
      ]
    },
    {
      "movement_intent": "SHIP_DOMESTIC",
      "src_site_type": "BREWERY_STORAGE",
      "dst_site_type": "DOMESTIC_CUSTOMER",
      "lot_tax_type": "TAX_PAID",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "NONE",
          "tax_event": "NONE",
          "result_lot_tax_type": "TAX_PAID",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": true,
            "lot_split_required": false,
            "approval_required": false,
            "require_reference_document": false,
            "require_reason_code": false
          }
        }
      ]
    },

    {
      "movement_intent": "SHIP_EXPORT",
      "src_site_type": "TAX_STORAGE",
      "dst_site_type": "OVERSEA_CUSTOMER",
      "lot_tax_type": "TAX_SUSPENDED",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "EXPORT_EXEMPT",
          "tax_event": "EXPORT_EXEMPT",
          "result_lot_tax_type": "EXPORT_EXEMPT",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": true,
            "lot_split_required": true,
            "approval_required": true,
            "require_reference_document": true,
            "require_reason_code": false
          }
        }
      ]
    },
    {
      "movement_intent": "SHIP_EXPORT",
      "src_site_type": "BREWERY_STORAGE",
      "dst_site_type": "OVERSEA_CUSTOMER",
      "lot_tax_type": "TAX_PAID",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "NONE",
          "tax_event": "NONE",
          "result_lot_tax_type": "TAX_PAID",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": true,
            "lot_split_required": false,
            "approval_required": false,
            "require_reference_document": false,
            "require_reason_code": false
          }
        }
      ]
    },

    {
      "movement_intent": "RETURN_FROM_CUSTOMER",
      "src_site_type": "DOMESTIC_CUSTOMER",
      "dst_site_type": "BREWERY_STORAGE",
      "lot_tax_type": "TAX_PAID",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "RETURN_TO_FACTORY",
          "tax_event": "RETURN_TO_FACTORY",
          "result_lot_tax_type": "TAX_PAID",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": false,
            "lot_split_required": false,
            "approval_required": true,
            "require_reference_document": true,
            "require_reason_code": false
          }
        }
      ]
    },

    {
      "movement_intent": "LOSS",
      "src_site_type": "BREWERY_STORAGE",
      "dst_site_type": "BREWERY_STORAGE",
      "lot_tax_type": "TAX_SUSPENDED",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "NON_TAXABLE_REMOVAL",
          "tax_event": "NON_TAXABLE_REMOVAL",
          "result_lot_tax_type": "TAX_SUSPENDED",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": false,
            "lot_split_required": true,
            "approval_required": true,
            "require_reference_document": true,
            "require_reason_code": true
          }
        }
      ]
    },

    {
      "movement_intent": "DISPOSE",
      "src_site_type": "BREWERY_STORAGE",
      "dst_site_type": "DISPOSAL_FACILITY",
      "lot_tax_type": "TAX_SUSPENDED",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "NON_TAXABLE_REMOVAL",
          "tax_event": "NON_TAXABLE_REMOVAL",
          "result_lot_tax_type": "OUT_OF_SCOPE",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": true,
            "require_full_lot": false,
            "allow_multiple_lots": false,
            "lot_split_required": true,
            "approval_required": true,
            "require_reference_document": true,
            "require_reason_code": true
          }
        }
      ]
    },

    {
      "movement_intent": "SHIP_DOMESTIC",
      "src_site_type": "BREWERY_STORAGE",
      "dst_site_type": "DOMESTIC_CUSTOMER",
      "lot_tax_type": "EXPORT_EXEMPT",
      "allowed_tax_decisions": [
        {
          "tax_decision_code": "NONE",
          "tax_event": "NONE",
          "result_lot_tax_type": "EXPORT_EXEMPT",
          "default": true,
          "lines_rules": {
            "allow_partial_quantity": false,
            "require_full_lot": true,
            "allow_multiple_lots": false,
            "lot_split_required": false,
            "approval_required": true,
            "require_reference_document": true,
            "require_reason_code": true
          }
        }
      ]
    }
  ],

  "validation_rules": {
    "default_selection": {
      "rule": "For any allowed_tax_decisions array with length > 1, exactly one item must have default=true."
    },
    "enum_integrity": {
      "rule": "All codes used in rules must exist in enums."
    }
  }
}
'::jsonb
);
