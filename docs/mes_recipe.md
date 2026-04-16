Recipe Grand Design for MES / Manufacturing Management

## 1. Design Goal

This design defines a recipe architecture for MES that can support multiple process-manufacturing industries such as beer, food, chemical, and pharma-like manufacturing.

The design must support:
- recipe version control
- recipe approval workflow
- recipe change history
- recipe execution traceability
- JSON-based flexible recipe definition
- reusable master data for materials, equipment, parameters, and step templates
- implementation on Supabase / PostgreSQL JSONB

Important scope note:
- This design is process-manufacturing first.
- It may support some packaging or light assembly use cases.
- It is not intended to be a full discrete BOM + routing replacement.

## 2. Core Design Principles

### 2.1 Separate recipe identity from recipe version

Do not store the versioned recipe body directly in `mst_recipe`.

Recommended split:
- `mst_recipe`: stable recipe identity / business header
- `mst_recipe_version`: immutable version snapshot containing `recipe_body_json`

This separation is required for:
- immutable approved versions
- proper approval workflow
- effective date control
- version comparison
- execution traceability

### 2.2 Keep governance outside the recipe body

The recipe JSON should describe the manufacturing definition only.

The following must be stored outside the JSON body:
- approval workflow records
- change / audit history
- execution logs

Reason:
- governance data changes more frequently than the manufacturing definition
- audit and approval queries should not depend on JSON diff parsing
- execution logs must remain valid even if the recipe model evolves

### 2.3 Use JSON as the canonical internal format

Recommended policy:
- canonical internal storage: JSON / JSONB
- validation: JSON Schema
- exchange format: optional XML import / export when required by external systems

Reason:
- JSONB fits Supabase / PostgreSQL well
- JSON Schema is easier to evolve and validate in app code
- XML is still useful as an exchange format, but should not be the primary editing/storage model

### 2.4 Use business codes in design JSON, but snapshot resolved identities later

Recipe JSON should mainly reference reusable master data by business code.

Typical references in design JSON:
- `step_template_code`
- `material_type_code`
- `material_code`
- `equipment_type_code`
- `equipment_template_code`
- `parameter_code`
- `quality_check_code`
- `uom_code`

Why business codes are preferred in design JSON:
- easier to read and debug
- easier to migrate/import/export
- less environment-specific than UUIDs

However, code-only references are not enough for audit-grade traceability.

Required rule:
- design-time recipe JSON may store business codes
- on approval, the system should resolve and snapshot the master identifiers and visible labels needed for audit
- on execution release, the system should snapshot the exact approved recipe version and the resolved execution context used by the batch/order

### 2.5 Separate design-time, planning-time, and execution-time decisions

This design should distinguish three stages clearly:

1. Design time
- Define what should happen.
- Reference material type/code and equipment capability/template.

2. Planning / scheduling time
- Decide what can be used for a specific planned run.
- Assign actual material candidates, actual equipment candidates, or line/site constraints if needed.

3. Execution time
- Record what was actually used.
- Store actual material lots, equipment instances, operator actions, actual parameters, and deviations.

This separation avoids mixing recipe design with batch execution.

## 3. Lifecycle Model

### 3.1 `mst_recipe` lifecycle

`mst_recipe` represents the stable business identity.

Suggested status meaning:
- `active`: recipe identity is available for use
- `inactive`: recipe identity is retired or hidden from new planning

`mst_recipe.status` should not be used for approval workflow.

### 3.2 `mst_recipe_version` lifecycle

`mst_recipe_version` represents a specific versioned definition.

Suggested status meaning:
- `draft`
- `in_review`
- `approved`
- `obsolete`
- `archived`

Meaning:
- `draft`: editable working version
- `in_review`: submitted for approval
- `approved`: frozen, releasable for execution
- `obsolete`: no longer preferred for new release
- `archived`: kept for history only

### 3.3 Effective dating

Recommended fields:
- `effective_from`
- `effective_to`

Rules:
- only approved versions can become effective
- multiple draft versions may exist, but effective overlap for approved versions should be controlled by business rules
- execution should reference the version that was actually released, not re-resolve a version by current date later

### 3.4 Change rule

Required rule:
- approved versions are immutable
- any change after approval creates a new draft version
- execution records must never point to a mutable draft document

## 4. Recommended Table Structure

### 4.1 Core Recipe Tables

#### 4.1.1 `mst_recipe`

Stable recipe identity.

Suggested fields:
- `id`
- `tenant_id`
- `recipe_code`
- `recipe_name`
- `recipe_category`
- `industry_type`
- `status`
- `current_version_id`
- `created_at`
- `created_by`
- `updated_at`
- `updated_by`

Purpose:
- stable recipe business identity
- active / inactive lifecycle control
- reference point for all version rows

Notes:
- `current_version_id` should normally point to the latest approved or preferred version
- it is a convenience pointer, not the audit source of truth

#### 4.1.2 `mst_recipe_version`

Versioned immutable recipe snapshot.

Suggested fields:
- `id`
- `tenant_id`
- `recipe_id`
- `version_no`
- `version_label`
- `recipe_body_json`
- `schema_code`
- `template_code`
- `status`
- `effective_from`
- `effective_to`
- `change_summary`
- `body_hash`
- `created_at`
- `created_by`
- `approved_at`
- `approved_by`

Purpose:
- store the exact recipe definition used by that version
- support immutable approved versions
- support comparison and audit

Recommended constraints:
- unique: `tenant_id + recipe_id + version_no`
- `body_hash` should be derived from canonicalized JSON to support integrity checks

### 4.2 Governance Tables

#### 4.2.1 `mes_recipe_approval_flow_def` (recommended)

Defines the approval sequence expected for a recipe category, industry, or site context.

Suggested fields:
- `id`
- `tenant_id`
- `flow_code`
- `recipe_category`
- `industry_type`
- `step_no`
- `approval_role`
- `is_required`
- `status`

Purpose:
- define who must approve and in what order
- avoid hardcoding approval sequences inside the recipe record itself

#### 4.2.2 `mes_recipe_approval_event`

Stores actual approval decisions for a specific recipe version.

Suggested fields:
- `id`
- `tenant_id`
- `recipe_version_id`
- `flow_def_id`
- `step_no`
- `approval_role`
- `approver_user_id`
- `decision` (`pending` / `approved` / `rejected` / `skipped`)
- `decision_at`
- `comment`
- `e_signature`

Purpose:
- record the real approval transaction, not only the configured flow

Reason for separation:
- approval flow definition and actual approval events are different concepts
- one defines the route
- the other records what actually happened

#### 4.2.3 `mes_recipe_change_history`

Event-oriented change / audit history.

Suggested fields:
- `id`
- `tenant_id`
- `recipe_version_id`
- `event_type` (`create` / `edit` / `submit` / `approve` / `reject` / `obsolete` / `rollback`)
- `changed_at`
- `changed_by`
- `diff_doc`
- `reason_code`
- `reason_text`
- `comment`

Optional future detail table:
- `recipe_change_detail`
  - `change_history_id`
  - `field_path`
  - `old_value`
  - `new_value`

Recommendation:
- keep the base audit model event-oriented first
- add field-level detail only where it is really needed

### 4.3 Reusable Master Tables

#### 4.3.1 `mst_step_template`

Reusable step pattern master.

Suggested fields:
- `id`
- `tenant_id`
- `step_template_code`
- `step_template_name`
- `step_type`
- `industry_type`
- `default_instructions`
- `default_duration`
- `parameter_template_json`
- `default_equipment_type_id` (`public.type_def.type_id`, domain=`equipment_type`)
- `default_equipment_requirement_json`
- `default_quality_check_json` or `quality_check_template_id`
- `default_material_role`
- `sort_no`
- `is_active`

Examples:
- Mixing
- Heating
- Cooling
- Fermentation
- Filling
- Packaging
- Inspection
- Cleaning

Important rule:
- step template metadata should be strong enough to drive dynamic UI rendering and validation

#### 4.3.2 `mst_material`

Specific material / item master.

Suggested fields:
- `id`
- `tenant_id`
- `material_code`
- `material_name`
- `material_type_id` (`public.type_def.type_id`, domain=`material_type`)
- `base_uom_id`
- `material_category`
- `is_batch_managed`
- `is_lot_managed`
- `status`

#### 4.3.3 `type_def` for material and equipment classification

Use the shared `public.type_def` table instead of creating separate `mst_material_type` and `mst_equipment_type` tables.

Suggested fields:
- `tenant_id`
- `type_id`
- `domain`
- `code`
- `name`
- `parent_type_id`
- `industry_id`
- `sort_order`
- `meta`
- `is_active`

Recommended domains:
- `material_type`
- `equipment_type`

Examples for `material_type`:
- malt
- hop
- yeast
- bottle
- label
- active ingredient
- excipient

Examples for `equipment_type`:
- fermenter
- mixer
- reactor
- filler
- oven
- conveyor

Important rules:
- all type references in recipe-related tables should resolve to `public.type_def(tenant_id, type_id)`
- tenant ownership should be enforced by composite foreign key
- domain correctness should be enforced so `material_type_id` only points to `domain='material_type'` and `equipment_type_id` only points to `domain='equipment_type'`

#### 4.3.4 Recipe JSON material references

Use a combination of:
- `material_type_code` for class-level design intent
- `material_code` when a recipe should point to an approved tenant material master row

Recommended rule:
- keep `material_type_code` as the broad compatibility reference
- add `material_code` whenever the recipe is intended to bind to a maintained material master
- avoid introducing a separate material-spec master layer unless there is a concrete business need for it

#### 4.3.5 `mst_equipment`

Actual equipment instance.

Suggested fields:
- `id`
- `tenant_id`
- `equipment_code`
- `equipment_name`
- `equipment_type_id` (`public.type_def.type_id`, domain=`equipment_type`)
- `site_id`
- `line_id`
- `status`
- `capacity`
- `capacity_uom_id`
- `meta_json`

#### 4.3.6 `mst_equipment_template`

Reusable equipment requirement profile, not an actual equipment instance.

Suggested fields:
- `id`
- `tenant_id`
- `template_code`
- `template_name`
- `equipment_type_id` (`public.type_def.type_id`, domain=`equipment_type`)
- `capacity_min`
- `capacity_max`
- `capacity_uom_id`
- `capability_json`
- `status`

Examples:
- standard 1000L fermenter
- 350ml can filling line
- heated mixing tank 200L

Why it is needed:
- recipe design should normally bind to equipment requirement/template, not to a specific tank or machine

#### 4.3.7 `mst_parameter_def`

Reusable process parameter definition.

Suggested fields:
- `id`
- `tenant_id`
- `parameter_code`
- `parameter_name`
- `data_type`
- `default_uom_id`
- `precision`
- `min_value`
- `max_value`
- `status`

Examples:
- `TEMP`
- `PRESSURE`
- `MIX_SPEED`
- `HOLD_TIME`
- `PH`
- `HUMIDITY`

#### 4.3.8 `mst_quality_check`

Reusable QC / inspection definition.

Suggested fields:
- `id`
- `tenant_id`
- `check_code`
- `check_name`
- `check_type`
- `parameter_json`
- `status`

Optional future addition:
- `mst_quality_check_template`

#### 4.3.9 `mst_uom`

Unit of measure master.

Suggested fields:
- `id`
- `code`
- `name`
- `dimension`
- `precision`
- `status`

Examples of dimension:
- mass
- volume
- count
- time
- temperature

### 4.4 Meta / Definition Table

#### 4.4.1 `regist_def`

`regist_def` is useful, but its role must be limited to reusable meta/config definition.

Recommended use cases:
1. schema definition
- `recipe_body_v1`
- `recipe_body_schema_beer_v1`

2. starter template / UI template
- `beer1`
- `beer2`
- `beer3`

3. validation/config definition
- allowed step types by industry
- required sections by industry

Suggested fields:
- `id`
- `tenant_id`
- `def_type` (`schema` / `template` / `ui` / `validation`)
- `def_code`
- `def_name`
- `industry_type`
- `version_no`
- `body_json`
- `status`
- `description`

Important rule:
- `regist_def` stores reusable meta definitions
- `mst_recipe_version` stores actual recipe version documents

## 5. Execution-Side Model

This section is critical. Execution traceability cannot be achieved by recipe tables alone.

### 5.1 Recommended execution-side entities

Suggested execution-side entities:
- existing `public.mes_batches`
- `mes.batch_step`
- `mes.batch_material_plan`
- `mes.batch_material_actual`
- `mes.equipment_reservation`
- `mes.batch_equipment_assignment`
- `mes.batch_execution_log`
- `mes.batch_deviation`

Minimum meaning:
- `public.mes_batches`: one planned / released / running execution instance
- `mes.batch_step`: released step list for the batch under the new recipe architecture
- `mes.batch_material_plan`: planned material requirements after release/scaling
- `mes.batch_material_actual`: actual material lots / quantities consumed
- `mes.equipment_reservation`: planned equipment occupancy / maintenance / CIP / manual blocks
- `mes.batch_equipment_assignment`: actual equipment used, optionally linked to a planned reservation
- `mes.batch_execution_log`: operator/system events, start/stop/hold/resume/value capture
- `mes.batch_deviation`: deviations and exception handling

Practical repository rule for this project:
- reuse the existing `public.mes_batches` table as the execution header
- do not reuse the existing `public.mes_batch_steps` table as the long-term released-step structure for the new recipe architecture
- create the new released-step and detail traceability model around `mes_batches.id`
- keep equipment planning (`mes.equipment_reservation`) separate from actual execution assignment (`mes.batch_equipment_assignment`)

### 5.2 Design-time vs execution-time binding

#### Materials

At recipe design time, prefer:
- `material_type_code`
- optional approved `material_code`
- optional approved material list

Avoid at design time:
- actual lot ID
- actual inventory item

At execution time, record:
- actual material ID
- actual lot ID
- actual consumed quantity
- substitution / deviation reason if different from the recipe expectation

#### Equipment

At recipe design time, prefer:
- `equipment_type_code`
- `equipment_template_code`
- capability requirement

Avoid at design time:
- actual equipment instance, except when the process is legally or technically site-fixed

At execution time, record:
- actual equipment ID
- actual line / site
- assignment timing
- reason if assigned equipment does not match the default template exactly

### 5.3 Snapshot policy

Required rules:

1. Approval snapshot
- when a recipe version is approved, the approved version must become immutable
- the exact JSON body and relevant resolved references must be frozen for audit

2. Release snapshot
- when a batch/order is released, the system must snapshot the exact approved recipe version being used
- release should not depend on re-reading mutable master data later

3. Execution snapshot
- execution records must retain the actual materials, lots, equipment, parameters, and deviations used at runtime

4. Reproducibility rule
- historical execution must remain interpretable even if master codes, labels, or templates are changed later

Practical recommendation:
- keep the source recipe JSON in `mst_recipe_version`
- reuse `public.mes_batches.recipe_json` as the released recipe snapshot body
- add explicit version-aware execution link fields to `public.mes_batches`, especially `recipe_version_id`
- store released steps and detailed runtime traceability in the new execution-side tables

### 5.4 Recommended reuse strategy for this repo

Because this repository already uses `public.mes_batches`, the most practical migration path is:

1. Keep `public.mes_batches` as the batch header.
2. Add new fields needed for the new recipe model, such as:
- `mes_recipe_id`
- `recipe_version_id`
- `released_reference_json`
3. Keep `recipe_json` as the frozen released recipe snapshot body.
4. Do not rely on the current `public.mes_batch_steps` as the target released-step structure for the new architecture.
5. Create a new `mes.batch_step` table and related detail tables linked back to `mes_batches.id`.

Why this is the better compromise:
- it preserves compatibility with the current app's batch header model
- it avoids creating a second competing batch header table
- it still allows the recipe redesign to introduce a cleaner released-step model

## 6. Recommended Recipe JSON Policy

### 6.1 What recipe JSON should contain

The recipe JSON should define:
- recipe metadata needed by the version
- base quantity and scaling basis
- material requirements
- process flow / steps
- step parameters
- quality checks
- equipment requirements
- storage / hold constraints where relevant
- optional document references

The recipe JSON should not contain:
- approval transaction history
- execution logs
- actual lot consumption
- actual equipment usage

### 6.2 Example reference style

```json
{
  "schema_version": "recipe_body_v1",
  "base": {
    "quantity": 1000,
    "uom_code": "L"
  },
  "materials": {
    "required": [
      {
        "material_role": "main_substrate",
        "material_type_code": "MALT",
        "material_code": "MAT_MALT_PALE",
        "qty": 180,
        "uom_code": "KG"
      }
    ]
  },
  "flow": {
    "steps": [
      {
        "step_code": "FERMENT",
        "step_template_code": "STEP_FERMENT",
        "equipment_requirement": {
          "equipment_type_code": "FERMENTER",
          "equipment_template_code": "STD_FERMENTER_1000L"
        },
        "parameters": [
          {
            "parameter_code": "TEMP",
            "target": 18,
            "uom_code": "C"
          }
        ],
        "quality_checks": [
          {
            "check_code": "QC_PH"
          }
        ]
      }
    ]
  }
}
```

### 6.3 Validation policy

Recommended validation layers:

1. JSON schema validation
- structure, required fields, data types

2. master reference validation
- code exists and is active

3. semantic rule validation
- required sections by industry
- required parameter sets by step type
- UOM compatibility
- effective date / approval constraints

4. release-time validation
- approved version only
- execution site / line / equipment / material compatibility

## 7. Alignment with Existing Repo Assets

This document should be treated as the architectural source of truth for future recipe redesign.

Alignment notes:
- `docs/data/recipe_schema.json` should be updated to match the concepts in this document
- `docs/UI/recipeedit.md` should derive its dynamic-step editing rules from `mst_step_template` and the recipe JSON schema defined here

Important consistency rule:
- there should not be one recipe model in `mes_recipe.md` and a conflicting second model in `recipe_schema.json`

## 8. Biggest Risks in the Current Direction

Risk 1: mixing recipe identity and version
- Fix: use `mst_recipe` + `mst_recipe_version`

Risk 2: code references without snapshot traceability
- Fix: use business codes in design JSON, but snapshot resolved identities on approval and release

Risk 3: ambiguous material identity in recipe JSON
- Fix: use `material_type_code` plus `material_code` where the recipe should bind to an approved material master

Risk 4: missing equipment requirement layer
- Fix: add `mst_equipment_template`

Risk 5: approval definition and approval event being mixed together
- Fix: separate flow definition from actual approval event records

Risk 6: execution traceability being underspecified
- Fix: define execution-side entities and snapshot policy explicitly

Risk 7: trying to replace the existing batch header unnecessarily
- Fix: reuse `public.mes_batches` as the execution header in this repo

Risk 8: carrying forward the current `mes_batch_steps` structure as-is
- Fix: keep batch header compatibility, but introduce a new released-step model for the redesigned recipe architecture

Risk 9: `regist_def` becoming an overloaded catch-all table
- Fix: limit it to schema / template / UI / validation definitions

## 9. Recommended Minimum Revised Model

### 9.1 Keep
- `mst_recipe`
- `mst_step_template`
- `mst_material`
- `mst_equipment`
- `type_def` with `material_type` and `equipment_type` domains
- `mst_parameter_def`
- `mst_quality_check`
- `mst_uom`
- `regist_def`

### 9.2 Add immediately
- `mst_recipe_version`
- `mst_equipment_template`

### 9.3 Strongly recommended next
- `recipe_approval_flow_def`
- `recipe_approval_event`
- `recipe_change_history`
- execution-side released-step / assignment / actual / log tables, reusing `public.mes_batches` as the execution header

## 10. Practical Final Recommendation

Most important design rule:
- `mst_recipe` is the stable header only
- all versioned recipe JSON belongs in `mst_recipe_version`

Most important additions:
- `mst_equipment_template`
- explicit execution-side snapshot model

Best practical architecture:
- `mst_recipe` = stable identity
- `mst_recipe_version` = versioned recipe JSON
- `regist_def` = schema/template/meta definitions
- master tables = reusable material/equipment/step/parameter/QC references
- governance tables = approval and change history
- `public.mes_batches` = execution header
- execution tables = released and actual production traceability around `mes_batches.id`

## 11. Suggested Next Deliverables

Recommended next outputs:
1. PostgreSQL / Supabase DDL for the recommended core tables
2. recipe JSON Schema aligned to this document
3. sample beer recipe JSON using `step_template_code`, `material_type_code`, `material_code`, and `equipment_template_code`
4. execution-side DDL that reuses `public.mes_batches`, introduces a new released-step model, and adds equipment/material/log traceability tables
5. RLS policy template for Supabase multi-tenant design

## 12. Short Summary

This design is now strong enough to serve as the base architecture for MES recipe management.

The highest-value rules are:
- split recipe identity from recipe version
- keep approval/change/execution history outside the recipe body
- use JSONB as the canonical recipe representation
- reference business codes in design JSON, but snapshot resolved identities for audit and execution
- link recipe design to material spec and equipment template, not directly to lots or equipment instances
- define execution-side snapshot and traceability explicitly, not as an afterthought

If these rules are followed, the model will be much more suitable for:
- multi-industry process manufacturing
- controlled versioning
- approval workflow
- batch execution traceability
- Supabase / PostgreSQL implementation
- long-term maintainability
