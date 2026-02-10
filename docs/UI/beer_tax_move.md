for producedBeer vue page, please replace 移出登録 dialog with following UI Specification: 酒税 Event (Liquor Tax Event)
=================================================

# 移出登録　Dialog UI Specification

## Purpose
----------
This UI specification defines a guided user interface for handling liquor tax
(酒税) related events. The design goal is to prevent mis-operations by ensuring
that users select business intent first, while the system automatically
determines tax treatment.

Key principles:
- System will automatically determine tax treatment. but user still have a chance to select tax treatment.
- Legal constraints, required evidence, and auditability are enforced by the UI.
- Posting an event updates inventory, tax ledger, and reporting consistently.

## Entry Points
-移出記録(producedBeer page) -> button:　"Tax Movement Regist..." (japanese text: "酒税関連登録")


## Scope
--------
Supported user-facing intents and corresponding tax treatments:

1. Domestic Shipment (国内出荷 / 国内販売)
   -> Tax treatment: 課税移出
2. Export Shipment (輸出 / 国外向け)
   -> Tax treatment: 輸出免税（非課税移出：輸出）
3. Return Acceptance (返品受入 / 回収)
   -> Tax treatment: 戻入
4. Inbound Receipt (受入 / 他製造場等から搬入)
   -> Tax treatment: 移入
5. Non-taxable Removal – Other (非納税移出：その他)
   -> Tax treatment: 非納税移出（理由コード必須）

## Users and Permissions
------------------------
Roles:
- Operator: Create and edit Draft events
- Supervisor: Post (confirm) events, create reversals
- Auditor: Read-only access, export evidence and logs

Rules:
- Only Supervisors can POST (確定).
- Draft events are editable; Posted events are immutable.
- Corrections are handled by reversal or adjustment events.

## Terminology
--------------
UI terminology:
- Intent (目的): Business purpose selected by user
- Tax Treatment (税区分): System-determined, read-only
- Evidence (証憑): Documents or references required for compliance

System fields (recommended):
- movement_intent
- tax_treatment
- status (draft / posted / reversed)

 Entry Points
---------------
- Batch Edit Page: "Add 酒税 Event"
- Shipment/Receipt Module
- Returns Module (always starts from original shipment)

## Screens
----------
S1. Create Tax Event Wizard
S2. Return Acceptance (Start from Original Shipment)
S3. Tax Event Detail
S4. Reversal / Adjustment

--------------------------------------------------
S1. Create Tax Event Wizard
--------------------------------------------------

Layout:
- Header: 酒税イベント作成
- Stepper:
  1) Intent
  2) Parties / Route
  3) Items / Quantity
  4) Evidence
  5) Review & Save
- Right-side panel:
  - Computed tax treatment (read-only)
  - Tax preview (optional)
  - Validation checklist

Step 1: Select Intent
---------------------
User selects one of the following:
- Domestic Shipment (国内出荷)
- Export Shipment (輸出)
- Return Acceptance (返品受入) -> goes to S2
- Inbound Receipt (受入)
- Non-taxable Removal – Other (非課税移出：その他)

System behavior:
- movement_intent is set
- tax_treatment is computed and locked

Step 2: Parties and Route
-------------------------
Fields vary by intent.

Domestic Shipment:
- Ship-from site (required)
- Ship-to party (required, domestic only)
- Ship date (required)

Export Shipment:
- Ship-from site (required)
- Export mode (direct / forwarder)
- Destination country (required, non-JP)
- Planned ship date
- Export evidence required before POST

Inbound Receipt:
- Receiving site (required)
- Source type and source party (required)
- Receipt date

Non-taxable Removal – Other:
- Removal site
- Reason code (required)
- Planned date

Step 3: Items and Quantity
--------------------------
Line items table:
- Product
- Lot / Batch
- Quantity
- Unit of Measure
- ABV (optional)
- Tax category (read-only)

Validations:
- Quantity > 0
- Inventory sufficiency for removals
- Proper UoM conversion

Step 4: Evidence
----------------
Conditional by intent.

Export Shipment (required):
- Invoice number
- B/L or AWB number
- Optional file attachments

Other intents:
- Evidence optional or conditional depending on configuration

Step 5: Review and Save
-----------------------
Summary includes:
- Intent
- Tax treatment
- Parties and route
- Item totals
- Evidence status
- Warnings and blockers

Actions:
- Save Draft
- Post (Supervisor only, validation required)

--------------------------------------------------
S2. Return Acceptance (戻入)
--------------------------------------------------
Flow:
1. Search original posted shipment (課税移出)
2. Select original event
3. Create return draft with prefilled data
4. Enter return quantities and date
5. Save Draft or Post

Rules:
- Original event reference is mandatory
- Return quantity cannot exceed remaining eligible quantity

--------------------------------------------------
S3. Tax Event Detail
--------------------------------------------------
- Header: Event No., Status, Intent, Tax treatment
- Tabs:
  - Summary
  - Lines
  - Evidence
  - Audit Log
  - Related Events

Draft: editable
Posted: read-only, reversal only

--------------------------------------------------
S4. Reversal / Adjustment
--------------------------------------------------
- Used to correct posted events
- Creates a reversal event referencing the original
- Original event marked as reversed

--------------------------------------------------
Global Mis-operation Prevention Rules
--------------------------------------------------
- System will automatically determine tax treatment. but user still have a chance to select tax treatment.
- Intent change requires creating a new event
- Hard validation on POST
- Draft and Posted states are clearly separated
- Full audit trail for all events

--------------------------------------------------
Intent and Tax Treatment Matrix
--------------------------------------------------
Intent: Domestic Shipment
Tax treatment: 課税移出
Evidence required: No
Original reference: No

Intent: Export Shipment
Tax treatment: 輸出免税
Evidence required: Yes
Original reference: No

Intent: Return Acceptance
Tax treatment: 戻入
Evidence required: Optional
Original reference: Yes

Intent: Inbound Receipt
Tax treatment: 移入
Evidence required: Optional
Original reference: No

Intent: Non-taxable Removal – Other
Tax treatment: 非課税移出
Evidence required: Conditional
Original reference: No
for producedBeer vue page, please replace 移出登録 dialog with following UI Specification: 酒税 Event (Liquor Tax Event)
