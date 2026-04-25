# Stored Function Error Catalog

## Purpose

This catalog is the working list for translating stored-function errors into clear UI messages.

The frontend must translate stable business codes such as `TRM002`, not raw English database text. Raw database text can change; once a code is exposed to the UI, the code must remain stable.

## Message Rules

- Use business language, not implementation language.
- Do not show table names, function names, SQLSTATE values, or raw IDs in normal toast text.
- Put technical details in logs or an expandable detail area, not in the primary message.
- Use one code for one user-visible condition.
- Use JSON `DETAIL` for dynamic values such as lot number, report period, quantity, or conflicting movement.
- Prefer a clear action when possible: regenerate, change quantity, select another lot, review downstream movement, or contact an administrator.

Example:

| Raw database error | UI message |
|---|---|
| `TRM002: movement is locked by tax report (submitted 2026/04)` | `この移動は酒税申告（提出済み 2026/04）に含まれているため、取消できません。` |
| `PM007: source inventory insufficient quantity` | `移出元の在庫数量が不足しています。数量を確認してください。` |

## Scan Scope

- Source scanned: `DB/function/*.sql`
- Pattern scanned: active lines starting with `raise exception`
- Current scan count: 253 active `raise exception` statements
- Current same-line coded count: 202 statements using a `CODE: message` prefix
- Current issue: several coded exceptions are multi-line, and several helper functions still raise uncoded messages.

Re-scan command:

```sh
rg -n "^\s*raise exception" DB/function --glob '*.sql'
```

## Classification

- `Ready`: code is stable enough for translation now.
- `Ready + details`: code is stable, but a complete message needs JSON `DETAIL` values instead of parsing `%` text.
- `Ambiguous`: the same code is used for different business meanings; split the code or add a stable detail reason before broad translation.
- `Uncoded`: no stable business code exists; add one before translating.
- `Internal`: low-level helper/config error; can map to a generic admin/support message unless surfaced in normal UI.

## Error Contract

Short term:

```sql
raise exception 'TRM002: movement is locked by tax report (%)', v_locked_report;
```

Preferred:

```sql
raise exception 'TRM002: movement_locked_by_tax_report'
  using detail = jsonb_build_object(
    'status', v_status,
    'tax_year', v_tax_year,
    'tax_month', v_tax_month
  )::text;
```

Frontend translation key:

```json
{
  "rpcErrors": {
    "codes": {
      "TRM002": {
        "message": "This movement is included in tax report ({report}) and cannot be reversed."
      }
    }
  }
}
```

## Translation-Ready Codes

These codes have one clear user meaning. They can receive locale entries now. Codes marked `Ready + details` should still get JSON `DETAIL` later for richer messages.

| Code / family | Source | Classification | Notes |
|---|---|---:|---|
| `BSEA001`-`BSEA015` | `73_public.batch_step_save_equipment_assignments.sql` | Ready / Ready + details | Equipment assignment validation. `BSEA010`, `BSEA014`, `BSEA015` should eventually include equipment/time detail. |
| `BSBC001`-`BSBC027` | `72_public.batch_step_complete_backflush.sql` | Ready / Ready + details | Backflush validation. Codes with lot/material placeholders should move values to JSON detail. |
| `DRC001`, `DRC002`, `DRC004`-`DRC008` | `70_public.domestic_removal_complete.sql` | Ready / Ready + details | Domestic removal checks. `DRC006`, `DRC008` need details for status/tax type. |
| `EDCS001` | `69_public.ensure_dummy_domestic_customer_site.sql` | Ready + details | Tenant id should be detail, not shown by default. |
| `GTR001`-`GTR005` | `66_public.get_current_tax_rate.sql` | Ready | Tax-rate lookup/master-data errors. `GTR005` repeats with the same meaning. |
| `ILV001`-`ILV008` | `67_public.inventory_lot_void.sql` | Ready | Inventory lot void errors. |
| `LOT_TIME001`, `LOT_TIME003`, `LOT_TIME004`, `LOT_TIME006` | `03_public.lot_chronology.sql` | Ready + details | Chronology errors. Dates, lot numbers, context should be JSON detail. |
| `LOT_TIME002` | `03_public.lot_chronology.sql` | Ready + details | Repeated same meaning: lot not found. |
| `LOT_TIME005` | `03_public.lot_chronology.sql` | Ready + details | Movement not found for trigger context; include ref kind in detail. |
| `PF003`, `PF005`, `PF007` | `43_public.product_filling.sql` | Ready + details | Duplicate doc, insufficient source, source lot not found. `PF005` should include lot/inventory/source quantity context. |
| `PFR001`, `PFR002`, `PFR005`, `PFR007` | `47_public.product_filling_rollback.sql` | Ready / Ready + details | Filling rollback required input, target not found, downstream block, duplicate doc. |
| `PM003`, `PM010`, `PM011`, `PM012` | `44_public.product_move.sql` | Ready / Ready + details | Rule missing, category/tax missing, tax-rate wrapper, return inventory landing check. |
| `PMF500` | `46_public.product_move_fast_post.sql` | Ready + details | Segment wrapper. Should expose segment index and nested error code separately. |
| `PP002`, `PP003`, `PP005`-`PP008` | `42_public.product_produce.sql` | Ready | Production validation and duplicate document errors. |
| `PPR002`, `PPR005`, `PPR007` | `45_public.product_produce_rollback.sql` | Ready / Ready + details | Produce rollback target missing, downstream block, duplicate doc. |
| `PU003`, `PU006`, `PU008`, `PU009`, `PU010` | `71_public.product_unpacking.sql` | Ready / Ready + details | Unpacking target/source/doc validation. |
| `RSG001`-`RSG003` | `68_public.recipe_schema_get.sql` | Ready | Recipe schema errors. |
| `TRG001`, `TRG003`, `TRG004` | `74_public.tax_report_generate.sql` | Ready | Tax report generation validation. |
| `TRM001`, `TRM002` | `76_public.tax_report_mark_stale_for_movement.sql` | Ready + details | `TRM002` already translated in UI; should eventually expose report status/year/month as JSON detail. |
| `TRS001`, `TRS002`, `TRS003`, `TRS006` | `75_public.tax_report_set_status.sql` | Ready | Tax report status validation. |

## Codes To Clean Before Translation

These codes currently represent multiple user-visible meanings. Translating them as-is would force weak generic messages and hide useful feedback.

| Code | Source | Current meanings | Required cleanup |
|---|---|---|---|
| `DRC003` | `70_public.domestic_removal_complete.sql:64,68` | Source site could not be resolved; source lot site mismatch. | Split into `DRC003` source site unresolved and `DRC009` source lot site mismatch. |
| `PF001` | `43_public.product_filling.sql:51,80,84,174` | `p_doc` required; required fields missing; `lines[]` required; source lot uom mismatch. | Keep `PF001` for required input only; split uom mismatch to a new code. |
| `PF002` | `43_public.product_filling.sql:88,142,145` | Loss quantity invalid; line quantity invalid; line unit invalid. | Split or add detail `field`. |
| `PF006` | `43_public.product_filling.sql:111,178` | Unsupported doc type mapping; source lot site mismatch. | Split config error from user data mismatch. |
| `PFR003` | `47_public.product_filling_rollback.sql:71,102,106,110` | Unsupported adjustment doc type; target not posted; target not filling; already rolled back. | Split into config/state/type/already-rolled-back codes. |
| `PFR004` | `47_public.product_filling_rollback.sql:123,138,150,215,219` | Source edge missing; source site/uom missing; filled lot not found; filled lot site/uom mismatch. | Split source graph errors from filled-lot validation errors. |
| `PFR006` | `47_public.product_filling_rollback.sql:223,238,246,339,351,409` | Filled lot quantity insufficient; inventory insufficient; rollback quantity not positive; post-update invalid source/filled quantities. | Split quantity, inventory, non-positive rollback, and invariant-failure cases. |
| `PM001` | `44_public.product_move.sql:74,100,170,197,699` | Input missing; source site invalid; destination site invalid; duplicate doc number. | Split required input, source site, destination site, duplicate doc. |
| `PM002` | `44_public.product_move.sql:104,108` | Quantity invalid; unit invalid. | Split or add detail `field`. |
| `PM004` | `44_public.product_move.sql:135,217,222` | Invalid movement intent; disallowed context; unsupported edge type. | Split invalid enum/context/edge type. |
| `PM005` | `44_public.product_move.sql:143,300,310` | Invalid tax decision code; no transformation rule; tax decision not allowed. | Split invalid enum, missing rule, disallowed decision. |
| `PM006` | `44_public.product_move.sql:259,269,273,277` | Source lot not found; not movable; site mismatch; uom mismatch. | Split lot missing/status/site/uom. |
| `PM007` | `44_public.product_move.sql:281,285,340,685,689` | Source lot quantity insufficient; unit insufficient; inventory insufficient; after-update invariant failure. | Split lot qty, unit qty, inventory qty, invariant failure. |
| `PM008` | `44_public.product_move.sql:320,324` | Full-lot movement required; partial quantity disallowed. | Split or add detail `rule`. |
| `PMF001` | `46_public.product_move_fast_post.sql:16,20` | Payload is not array; array is empty. | Split or add detail `reason`. |
| `PP001` | `42_public.product_produce.sql:32,57` | `p_doc` required; required fields missing. | Can translate generically, but better split required document vs missing fields. |
| `PPR001` | `45_public.product_produce_rollback.sql:38,52` | `p_doc` required; required fields missing. | Same cleanup as `PP001`. |
| `PPR003` | `45_public.product_produce_rollback.sql:61,92,96,100` | Unsupported adjustment doc type; target not posted; target not produce movement; already rolled back. | Split config/state/type/already-rolled-back. |
| `PPR004` | `45_public.product_produce_rollback.sql:114,125,130` | Produced edge not found; produced lot not found; site missing. | Split graph missing, lot missing, lot metadata missing. |
| `PPR006` | `45_public.product_produce_rollback.sql:149,164,233,245` | Quantity not positive; inventory insufficient; post-update inventory/lot insufficient. | Split business validation from invariant failure. |
| `PU001` | `71_public.product_unpacking.sql:58,83` | `p_doc` required; required fields missing. | Split or keep generic required input. |
| `PU002` | `71_public.product_unpacking.sql:87,91,96` | Quantity invalid; loss quantity invalid; quantity must exceed loss quantity. | Split or add detail `field` / `relation`. |
| `PU004` | `71_public.product_unpacking.sql:166,170,174,178` | Source lot not packaged; not active; site mismatch; uom mismatch. | Split source-lot packaging/status/site/uom. |
| `PU005` | `71_public.product_unpacking.sql:182,197,493` | Source lot insufficient; inventory insufficient; after-update insufficient. | Split lot qty, inventory qty, invariant failure. |
| `PU007` | `71_public.product_unpacking.sql:241,245` | Destination site missing/invalid; destination site wrong type. | Split missing/invalid from wrong type. |
| `TRG002` | `74_public.tax_report_generate.sql:35,39` | Unsupported tax type; invalid/missing period. | Split tax type and period validation. |
| `TRS004` | `75_public.tax_report_set_status.sql:40,44` | Approved status cannot change; submitted cannot return to draft. | Split approved immutable and submitted no-draft transition. |
| `TRS005` | `75_public.tax_report_set_status.sql:49,60` | Stale report cannot submit; report has no movement refs. | Split stale-block and empty-source-block. |

## Details Needed For Complete Messages

These codes can be translated, but complete messages need structured values from `RAISE ... USING DETAIL = ...`.

| Code / family | Needed detail values |
|---|---|
| `BSBC005` | `step_status` |
| `BSBC012`-`BSBC026` | `actual_row_id`, `lot_no`, `material_id`, `site_id`, `required_qty`, `available_qty` depending on code |
| `BSEA010`, `BSEA014`, `BSEA015` | `assigned_at`, `released_at`, `equipment_id`, `equipment_name`, conflicting assignment/window |
| `DRC006`, `DRC008` | `source_lot_status`, `source_lot_tax_type` |
| `EDCS001` | `tenant_id` for logs only |
| `LOT_TIME002`, `LOT_TIME004`, `LOT_TIME005`, `LOT_TIME006` | `lot_id`, `lot_no`, `movement_id`, `movement_at`, `created_at`, `context` |
| `PF005`, `PFR005`, `PFR006`, `PPR005`, `PPR006`, `PU005`, `PM007` | `lot_id`, `lot_no`, `site_id`, `required_qty`, `available_qty`, `uom_id`, `movement_id` |
| `PM004`, `PM005`, `PM011`, `PM012` | `movement_intent`, `edge_type`, `tax_decision_code`, `dst_site_type`, nested tax-rate error |
| `PMF500` | `segment_index`, nested `business_code`, nested `message` |
| `RSG002` | `def_key` |
| `TRM002` | `status`, `tax_year`, `tax_month`, `tax_report_id` |

## Uncoded Exceptions To Standardize

These exceptions need stable codes before they can participate in the translation architecture.

| Source | Current messages | Recommended prefix |
|---|---|---|
| `00_public._assert_tenant.sql` | `Missing tenant_id in JWT app_metadata`; `Invalid tenant_id format in JWT app_metadata` | `TENANT001`, `TENANT002` |
| `01_public._lock_lots.sql` | `p_lot_ids is required`; `Some lot ids are not visible for current tenant` | `LOCK_LOT001`, `LOCK_LOT002` |
| `02_public._assert_non_negative_lot_qty.sql` | `p_lot_id is required`; `Lot not found: %`; `Lot qty must not be negative...` | `LOT_QTY001`-`LOT_QTY003` |
| `07_public._upsert_movement_lines.sql` | `p_movement_id is required`; `p_lines must be a json array`; `Movement not found: %` | `UML001`-`UML003` |
| `08_public._upsert_batch_steps.sql` | `p_batch_id is required`; `p_steps must be a json array`; `Batch not found: %` | `UBS001`-`UBS003` |
| `10_public.batch_create.sql` | `p_doc is required` | `BC001` |
| `11_public.batch_save.sql` | `p_batch_id is required`; `p_patch is required`; `Batch not found: %` | `BS001`-`BS003` |
| `13_public.batch_get_detail.sql` | `p_batch_id is required`; `Batch not found: %` | `BGD001`, `BGD002` |
| `31_public.movement_save.sql` | `p_movement_id is required`; `Movement not found: %` | `MS001`, `MS002` |
| `60_public.lot_trace_upstream.sql` | `p_lot_id is required` | `LTU001` |
| `61_public.lot_trace_downstream.sql` | `p_lot_id is required` | `LTD001` |
| `62_public.lot_trace_full.sql` | `p_lot_id is required`; `p_max_depth must be between 1 and 100` | `LTF001`, `LTF002` |
| `63_public.get_packing_source_lotid.sql` | `p_batch_id is required` | `GPSL001` |
| `64_public.lot_dag_get_by_batch.sql` | `p_batch_id is required` | `LDGB001` |
| `65_public.get_volume_by_tank.sql` | tank input/calibration validation messages | `GVT001`-`GVT020` |

## Detailed Catalog By Function

### Product Filling

| Source | Code | Raw message variants | Classification |
|---|---|---|---|
| `43_public.product_filling.sql:51,80,84,174` | `PF001` | `p_doc is required`; `missing required field`; `lines[] is required`; `source lot uom_id mismatch` | Ambiguous |
| `43_public.product_filling.sql:88,142,145` | `PF002` | `loss qty must be greater than or equal to 0`; `line qty must be greater than 0`; `line unit must be greater than 0` | Ambiguous |
| `43_public.product_filling.sql:417` | `PF003` | `duplicate doc_no` | Ready |
| `43_public.product_filling.sql:182,196,409` | `PF005` | source lot/inventory insufficient quantity | Ready + details |
| `43_public.product_filling.sql:111,178` | `PF006` | unsupported doc type mapping; source lot site mismatch | Ambiguous |
| `43_public.product_filling.sql:164,235` | `PF007` | `source lot not found` | Ready |

### Product Filling Rollback

| Source | Code | Raw message variants | Classification |
|---|---|---|---|
| `47_public.product_filling_rollback.sql:48,62` | `PFR001` | `p_doc is required`; `missing required field` | Ready |
| `47_public.product_filling_rollback.sql:98` | `PFR002` | `target filling movement not found` | Ready |
| `47_public.product_filling_rollback.sql:71,102,106,110` | `PFR003` | adjustment unsupported; target not posted; target not filling; already rolled back | Ambiguous |
| `47_public.product_filling_rollback.sql:123,138,150,215,219` | `PFR004` | source edge/site/uom missing; filled lot missing/mismatch | Ambiguous |
| `47_public.product_filling_rollback.sql:183,203` | `PFR005` | rollback blocked by downstream movements | Ready + details |
| `47_public.product_filling_rollback.sql:223,238,246,339,351,409` | `PFR006` | quantity/inventory insufficient or invalid after rollback | Ambiguous |
| `47_public.product_filling_rollback.sql:431` | `PFR007` | `duplicate doc_no` | Ready |

### Product Produce And Rollback

| Source | Code | Raw message variants | Classification |
|---|---|---|---|
| `42_public.product_produce.sql:32,57` | `PP001` | `p_doc is required`; `missing required field` | Ambiguous minor |
| `42_public.product_produce.sql:61` | `PP002` | `qty must be greater than 0` | Ready |
| `42_public.product_produce.sql:250` | `PP003` | `duplicate doc_no` | Ready |
| `42_public.product_produce.sql:65` | `PP005` | source/destination site mismatch | Ready |
| `42_public.product_produce.sql:102` | `PP006` | unsupported doc type mapping | Ready |
| `42_public.product_produce.sql:79` | `PP007` | destination site missing/invalid | Ready |
| `42_public.product_produce.sql:83` | `PP008` | destination site must be manufacturing site | Ready |
| `45_public.product_produce_rollback.sql:38,52` | `PPR001` | `p_doc is required`; `missing required field` | Ambiguous minor |
| `45_public.product_produce_rollback.sql:88` | `PPR002` | target movement not found | Ready |
| `45_public.product_produce_rollback.sql:61,92,96,100` | `PPR003` | adjustment unsupported; target not posted; target not produce; already rolled back | Ambiguous |
| `45_public.product_produce_rollback.sql:114,125,130` | `PPR004` | produced edge/lot/site missing | Ambiguous |
| `45_public.product_produce_rollback.sql:145` | `PPR005` | downstream movement blocks rollback | Ready + details |
| `45_public.product_produce_rollback.sql:149,164,233,245` | `PPR006` | quantity/inventory insufficient or invariant failure | Ambiguous |
| `45_public.product_produce_rollback.sql:267` | `PPR007` | duplicate doc number | Ready |

### Product Move And Fast Move

| Source | Code | Raw message variants | Classification |
|---|---|---|---|
| `44_public.product_move.sql:74,100,170,197,699` | `PM001` | input missing; source/destination site invalid; duplicate doc number | Ambiguous |
| `44_public.product_move.sql:104,108` | `PM002` | qty/unit must be positive | Ambiguous |
| `44_public.product_move.sql:127` | `PM003` | rule definition missing | Ready |
| `44_public.product_move.sql:135,217,222` | `PM004` | invalid movement intent; context not allowed; unsupported edge type | Ambiguous |
| `44_public.product_move.sql:143,300,310` | `PM005` | invalid tax decision; no transformation rule; tax decision not allowed | Ambiguous |
| `44_public.product_move.sql:259,269,273,277` | `PM006` | source lot not found/status/site/uom invalid | Ambiguous |
| `44_public.product_move.sql:281,285,340,685,689` | `PM007` | quantity/unit/inventory insufficient or invariant failure | Ambiguous |
| `44_public.product_move.sql:320,324` | `PM008` | full-lot/partial movement rule violation | Ambiguous |
| `44_public.product_move.sql:373,405,424,444` | `PM010` | beer category or tax category missing for taxable movement | Ready |
| `44_public.product_move.sql:451` | `PM011` | wrapped tax-rate error | Ready + details |
| `44_public.product_move.sql:666` | `PM012` | customer return must land in inventory | Ready + details |
| `46_public.product_move_fast_post.sql:16,20` | `PMF001` | payload not array; payload empty | Ambiguous |
| `46_public.product_move_fast_post.sql:31` | `PMF500` | failed to post segment | Ready + details |

### Product Unpacking

| Source | Code | Raw message variants | Classification |
|---|---|---|---|
| `71_public.product_unpacking.sql:58,83` | `PU001` | `p_doc is required`; `missing required field` | Ambiguous minor |
| `71_public.product_unpacking.sql:87,91,96` | `PU002` | qty/loss qty invalid or inconsistent | Ambiguous |
| `71_public.product_unpacking.sql:156` | `PU003` | source lot not found | Ready |
| `71_public.product_unpacking.sql:166,170,174,178` | `PU004` | source lot packaging/status/site/uom invalid | Ambiguous |
| `71_public.product_unpacking.sql:182,197,493` | `PU005` | source lot/inventory insufficient or invariant failure | Ambiguous |
| `71_public.product_unpacking.sql:208` | `PU006` | target batch not found | Ready |
| `71_public.product_unpacking.sql:241,245` | `PU007` | destination site invalid or wrong type | Ambiguous |
| `71_public.product_unpacking.sql:259` | `PU008` | tank id invalid | Ready |
| `71_public.product_unpacking.sql:527` | `PU009` | unpack destination must land in inventory | Ready + details |
| `71_public.product_unpacking.sql:539` | `PU010` | duplicate doc number | Ready |

### Tax Report

| Source | Code | Raw message variants | Classification |
|---|---|---|---|
| `74_public.tax_report_generate.sql:24` | `TRG001` | `p_doc is required` | Ready |
| `74_public.tax_report_generate.sql:35,39` | `TRG002` | unsupported tax type; missing/invalid period | Ambiguous |
| `74_public.tax_report_generate.sql:43` | `TRG003` | generate can only write draft/stale | Ready |
| `74_public.tax_report_generate.sql:65` | `TRG004` | submitted/approved report cannot regenerate | Ready |
| `75_public.tax_report_set_status.sql:18` | `TRS001` | report id required | Ready |
| `75_public.tax_report_set_status.sql:23` | `TRS002` | invalid status | Ready |
| `75_public.tax_report_set_status.sql:36` | `TRS003` | report not found | Ready |
| `75_public.tax_report_set_status.sql:40,44` | `TRS004` | approved immutable; submitted cannot return to draft | Ambiguous |
| `75_public.tax_report_set_status.sql:49,60` | `TRS005` | stale cannot submit; no refs | Ambiguous |
| `75_public.tax_report_set_status.sql:65` | `TRS006` | only submitted can be approved | Ready |
| `76_public.tax_report_mark_stale_for_movement.sql:12` | `TRM001` | movement id required | Ready |
| `76_public.tax_report_mark_stale_for_movement.sql:30` | `TRM002` | movement locked by submitted/approved tax report | Ready + details |

### Batch And Equipment

| Source | Code | Raw message variants | Classification |
|---|---|---|---|
| `73_public.batch_step_save_equipment_assignments.sql:16-221` | `BSEA001`-`BSEA015` | assignment payload, status, date range, duplicate, ownership, overlap errors | Ready / Ready + details |
| `72_public.batch_step_complete_backflush.sql:69-568` | `BSBC001`-`BSBC027` | backflush payload, status, source site, explicit lot, FIFO lot, stock errors | Ready / Ready + details |

### Supporting Domain Functions

| Source | Code | Raw message variants | Classification |
|---|---|---|---|
| `03_public.lot_chronology.sql:12,38,61,82,88,119,166,297` | `LOT_TIME001`-`LOT_TIME006` | lot/time chronology validation | Ready / Ready + details |
| `66_public.get_current_tax_rate.sql:19-79` | `GTR001`-`GTR005` | tax rate lookup/master-data validation | Ready |
| `67_public.inventory_lot_void.sql:32-192` | `ILV001`-`ILV008` | inventory lot void validation | Ready |
| `68_public.recipe_schema_get.sql:18-47` | `RSG001`-`RSG003` | recipe schema lookup/definition validation | Ready |
| `69_public.ensure_dummy_domestic_customer_site.sql:39` | `EDCS001` | dummy customer site type missing | Ready + details |
| `70_public.domestic_removal_complete.sql:28-148` | `DRC001`-`DRC008` | domestic removal validation | Mixed; `DRC003` ambiguous |

## Recommended Cleanup Order

1. Add codes to uncoded functions used directly by UI or reports:
   - `movement_save`, `batch_get_detail`, `batch_save`, `get_volume_by_tank`, lot trace functions.
2. Split high-traffic ambiguous movement codes:
   - `PM001`, `PM004`, `PM005`, `PM006`, `PM007`.
3. Split rollback/filling ambiguous codes:
   - `PFR003`, `PFR004`, `PFR006`, `PPR003`, `PPR004`, `PPR006`, `PF001`, `PF006`.
4. Add JSON `DETAIL` to errors that need values in the UI:
   - tax report lock, chronology errors, stock insufficiency, downstream rollback block, equipment overlap.
5. Add locale entries under `rpcErrors.codes` only after a code is either `Ready` or intentionally translated as a generic family message.

## Translation Entry Template

Use this shape when adding locale entries:

```json
{
  "rpcErrors": {
    "codes": {
      "CODE001": {
        "message": "User-facing message with {parameter}.",
        "hint": "Optional next action."
      }
    }
  }
}
```

Keep `message` short enough for toast display. Put longer guidance in `hint` only when the UI has a place to show it.
