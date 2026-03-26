# Filling Report Excel Export Design

## Purpose
- Add Excel export capability to `詰口一覧表`.
- Generate a workbook from the current page data and provide a download link.

## Scope
- Design only in this document.
- This document defines only Excel-specific behavior.
- Base page structure, field definitions, and table content remain defined in:
  - `docs/UI/filling-report.md`

## Entry Point
- Add an `Excel Export` action in the `詰口一覧表` header action area near `Refresh`.

## User Flow
1. User opens `詰口一覧表`.
2. User applies filters and reviews the current table.
3. User clicks `Excel Export`.
4. System builds an Excel workbook from the current visible page data.
5. System shows a generated file link.
6. User downloads the workbook from that link.

## Export UI State
- Idle:
  - export button enabled
- Generating:
  - export button disabled
  - loading text shown near the button
- Success:
  - show generated file name
  - show download link
- Error:
  - show toast error
  - clear stale link if generation failed

## File Naming
- Workbook file name format:
  - `詰口一覧表_YYYYMMDD.xlsx`
- Date source:
  - client local date at generation time

## Workbook Structure
### Sheet 1
- Sheet name:
  - `Summary`
- Content:
  - same rows, columns, filters, and sort order as the visible main report table

### Batch Detail Sheets
- Create one sheet per exported batch.
- Each sheet content must match the batch’s current `バッチ詰口明細` on the page, including:
  - summary line
  - movement rows
  - total row

## Sheet Naming Rules
- Preferred sheet name:
  - `ロット番号`
- Fallback:
  - batch display name or `Batch_<index>`
- Apply Excel sheet-name constraints:
  - max 31 characters
  - remove invalid characters: `\ / ? * [ ] :`
  - ensure uniqueness

## Source of Truth
- Reuse the page’s already normalized/computed data.
- Do not re-define report field rules in the export layer.
- Reuse the existing source and computed state already assembled in `beeradmin_tail/src/views/Pages/FillingReport.vue`.
- Do not add a separate export-only fetch path if the current page state already contains the required data.
- Export must reflect:
  - current filters
  - current summary sort order
  - current detail ordering rules

## Recommended Implementation
- Generate the workbook client-side in the Vue page.
- Reuse the summary rows, selected/detail row builders, package column definitions, and normalized values already used by `FillingReport.vue`.
- Recommended library:
  - `xlsx`
- Suggested page state:
  - `exporting: boolean`
  - `exportFileName: string | null`
  - `exportDownloadUrl: string | null`
- Optional helper:
  - `beeradmin_tail/src/lib/fillingReportExport.ts`

## Formatting Rules
- Export blank values as blank cells, not `—`.
- Keep datetime and numeric formatting readable.
- Preserve grouped headers where practical for detail sheets.

## Validation Plan
- Confirm export button is visible on `詰口一覧表`.
- Confirm generated file name matches `詰口一覧表_YYYYMMDD.xlsx`.
- Confirm a download link appears after generation.
- Confirm `Summary` matches the visible main report table.
- Confirm one batch detail sheet is created for each exported batch.
- Confirm each batch detail sheet matches the page’s `バッチ詰口明細`.
- Confirm invalid or duplicate sheet names are sanitized safely.

## Risks
- Excel sheet-name limits require sanitization.
- Large exports may increase browser memory usage.
- If future requirements need stored/shared download URLs, a server-side export flow should replace the object-URL approach.
