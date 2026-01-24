## Mermaid ER Diagram

```mermaid
erDiagram

  PRODUCT ||--o{ RECIPE : has
  RECIPE ||--o{ RECIPE_VERSION : versioned_as

  PRODUCT {
    string product_id PK
    string name
    string product_family
    string revision
    string status
  }

  RECIPE {
    string recipe_id PK
    string product_id FK
    string name
    string recipe_kind
    string status
  }

  RECIPE_VERSION {
    string recipe_version_id PK
    string recipe_id FK
    int version_no
    datetime effective_from
    datetime effective_to
    string status
    decimal base_quantity
    string base_uom_id FK
  }

  RECIPE_VERSION ||--o{ STEP_DEF : defines
  RECIPE_VERSION ||--o{ STEP_DEP : dependencies

  STEP_DEF {
    string step_def_id PK
    string recipe_version_id FK
    int step_seq
    string step_code
    string name
    string step_type
    int std_cycle_time_sec
  }

  STEP_DEP {
    string step_dep_id PK
    string recipe_version_id FK
    string predecessor_step_def_id FK
    string successor_step_def_id FK
    string dependency_type
  }

  MATERIAL ||--o{ MATERIAL_SPEC : has
  MATERIAL ||--o{ RECIPE_MATERIAL_DEF : used_in
  MATERIAL ||--o{ STEP_INPUT_DEF : input
  MATERIAL ||--o{ STEP_OUTPUT_DEF : output

  MATERIAL {
    string material_id PK
    string name
    string material_type
    bool lot_tracked
  }

  MATERIAL_SPEC {
    string material_spec_id PK
    string material_id FK
    string spec_json
  }

  UOM {
    string uom_id PK
    string code
    string dimension
  }

  RECIPE_MATERIAL_DEF {
    string recipe_mat_def_id PK
    string recipe_version_id FK
    string material_id FK
    decimal planned_qty
    string uom_id FK
    string qty_basis_type
  }

  STEP_INPUT_DEF {
    string step_input_def_id PK
    string step_def_id FK
    string material_id FK
    decimal planned_qty
    string uom_id FK
  }

  STEP_OUTPUT_DEF {
    string step_output_def_id PK
    string step_def_id FK
    string material_id FK
    decimal planned_qty
    string uom_id FK
    string output_type
  }

  PARAM_CATALOG ||--o{ STEP_PARAM_DEF : used_by

  PARAM_CATALOG {
    string parameter_id PK
    string code
    string name
    string data_type
  }

  STEP_PARAM_DEF {
    string step_param_def_id PK
    string step_def_id FK
    string parameter_id FK
    decimal target_value
    decimal min_value
    decimal max_value
  }

  EQUIP_TYPE ||--o{ STEP_EQUIP_REQ : required_by

  EQUIP_TYPE {
    string equipment_type_id PK
    string name
    string category
  }

  STEP_EQUIP_REQ {
    string step_equip_req_id PK
    string step_def_id FK
    string equipment_type_id FK
    int qty_required
  }

  QC_CHECKPOINT_DEF {
    string qc_def_id PK
    string recipe_version_id FK
    string step_def_id FK
    string qc_type
    string acceptance_criteria
  }

  DOC_REF {
    string doc_ref_id PK
    string recipe_version_id FK
    string step_def_id FK
    string doc_type
    string uri
  }