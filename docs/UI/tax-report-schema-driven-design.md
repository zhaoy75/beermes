# Tax Report Schema-Driven XML Grand Design

## Purpose
- Replace the current template-string-based `酒税申告` XML generation with a schema-driven implementation.
- Keep source changes localized when an e-Tax XSD version changes.
- Standardize the new implementation under `beeradmin_tail/src/lib/taxreportxml`.
- Clarify likely source data for each XML section based on the current implementation.
- Define the `TaxReportEditor` GUI changes needed to support the new architecture.
- Pair this document with the concrete implementation spec:
  - `docs/UI/tax-report-rli0010-232-implementation-spec.md`

## Current Problem
- The current generator depends on one fixed template file: `beeradmin_tail/public/etax/R7年11月_納税申告.xtx`.
- The current XML build path rewrites that template with regex replacements.
- Only a small subset of the XML is truly dynamic today:
  - reporting period fields
  - `LIA110` row blocks
  - `LIA220` row blocks
- `IT`, `LIA010`, `CATALOG`, and most other form sections are effectively inherited from the template.
- When the XSD or sample template changes, the current approach risks broad source changes across UI code, helper code, and fixed string replacements.

## Design Goals
- Make the XML generator schema-driven, not template-driven.
- Keep XSD-version-specific logic sandboxed behind report-name-rooted modules.
- Separate business data collection from XML form construction.
- Make XML generation testable without running the whole editor page.
- Require generated XML to pass XSD validation before it is treated as valid output.
- Keep the current storage and report workflow intact during migration.

## Core Design Principles
### 1. Separate domain data from XML form data
- Inventory, movement, tax-rate, and tenant-profile data should first be normalized into a canonical report input model.
- XML builders should consume only canonical input plus schema-version configuration.

### 2. Sandbox XSD-version-specific logic
- Do not spread `23.2.0` assumptions across the codebase.
- Create report-name-rooted adapters so future schema changes stay inside one report folder.

### 3. Build only the supported form subset explicitly
- Do not attempt a generic “render any XSD” engine.
- Implement the current monthly `RLI0010` flow explicitly:
  - `DATA`
  - `RLI0010`
  - `CATALOG`
  - `IT`
  - `LIA010`
  - `LIA110`
  - `LIA220`
- Leave optional forms (`LIA130`, `LIA230`, `LIA240`, `LIA250`, `LIA260`, `TENPU`) behind feature flags or later phases.

### 4. Keep the UI ignorant of XML details
- `TaxReportEditor` should never assemble XML directly.
- The page should collect and display data, run generation commands, surface validation, and save files.

## Target Source Layout
- Base implementation root:
  - `beeradmin_tail/src/lib/taxreportxml`

Recommended structure:

```text
beeradmin_tail/src/lib/taxreportxml/
  index.ts
  types/
    canonical.ts
    generated.ts
    validation.ts
  core/
    ids.ts
    pagination.ts
    xml.ts
    catalog.ts
    xsdValidation.ts
  data/
    reportInput.ts
    tenantProfile.ts
    attachments.ts
  RLI0010_232/
    index.ts
    constants.ts
    schemaMap.ts
    builders/
      root.ts
      it.ts
      lia010.ts
      lia110.ts
      lia220.ts
    mappers/
      toIT.ts
      toLIA010.ts
      toLIA110.ts
      toLIA220.ts
    validation/
      business.ts
      structural.ts
      xsd.ts
```

## How To Limit Source Modification When XSD Changes
### Report-name sandboxing strategy
- Each supported report/XSD combination gets its own isolated folder under:
  - `src/lib/taxreportxml/<report_name>`
- Example:
  - `RLI0010_232`
  - future `RLI0010_240`

### Stable public API
- The rest of the app should depend only on a small stable API:

```ts
generateTaxReportXml({
  reportName: 'RLI0010_232',
  input,
})
```

- The caller should not know:
  - element names
  - form ordering
  - page-size rules
  - catalog details
  - ID/IDREF wiring

### Report-specific sandbox contents
- Each report folder owns:
  - root procedure version constant
  - supported forms
  - field-to-element mapping
  - code tables and form constraints
  - per-form builder implementation
  - business validation rules specific to that version

### Shared core that should not change often
- Keep these shared and version-agnostic:
  - canonical input types
  - XML escaping / serialization helpers
  - pagination helpers
  - ID generation helpers
  - editor orchestration
  - XSD validation runner interface
  - file upload/download flow

### Schema map instead of scattered literals
- Each report folder should expose one `schemaMap.ts` describing:
  - root namespace
  - procedure code
  - form version strings
  - page row limits
  - optional-form switches

Example:

```ts
export const schemaMap = {
  root: { procedure: 'RLI0010', version: '23.2.0' },
  forms: {
    IT: { version: '1.5' },
    LIA010: { version: '0.0.4', required: true },
    LIA110: { version: '0.0.3', required: true, rowsPerPage: 18 },
    LIA220: { version: '0.0.2', required: false, rowsPerPage: 18 },
  },
}
```

This keeps future XSD changes largely confined to:
- one new report folder
- wiring in `src/lib/taxreportxml/index.ts`
- optional editor feature-flag updates if new forms become visible in UI

## Canonical Data Pipeline
### Step 1. Collect domain input
- Source from current editor/report flow.
- Normalize into one canonical input object.

### Step 2. Map canonical input to form payloads
- Convert business data into schema-aligned form payloads.
- This is where report semantics are translated into XML semantics.

### Step 3. Build XML nodes from form payloads
- Use a real XML builder.
- Do not use regex replacement.

### Step 4. Validate
- Business validation
- Structural validation
- Mandatory XSD validation against the selected schema version
- Validation should run before:
  - enabling successful download
  - enabling save/upload of generated XML metadata

### XSD validation placement
- Recommended primary implementation:
  - run XSD validation in a server-side function, worker, or CI-compatible service
- Reason:
  - browser-side XSD validation is difficult to make reliable
  - XSD import/include resolution is easier in a controlled server-side runtime
  - versioned schema bundles can be managed more predictably
- Browser-side role:
  - show validation state and messages returned by the validation service
  - optionally run lightweight structural prechecks before sending XML for XSD validation
- HTTP contract:
  - if XSD validation fails, the validation endpoint should return an HTTP error response
  - recommended status: `422 Unprocessable Entity`
  - response body should contain structured validation messages

### Step 5. Serialize and persist
- Output `.xtx`
- Keep current filename, storage, and metadata flow unless requirements change

## Canonical Input Model
Suggested minimum model:

```ts
type ShuzeiReportInput = {
  report: {
    taxType: 'monthly' | 'yearly'
    taxYear: number
    taxMonth: number
    generatedAt: string
  }
  profile: TaxReportProfile
  totals: {
    totalTaxAmount: number
    refundableTaxAmount?: number
  }
  summaryBreakdown: TaxVolumeItem[]
  returnBreakdown: TaxVolumeItem[]
  attachments: Array<{
    kind: string
    name: string
    storagePath?: string
  }>
}
```

## Builder Responsibilities
### `buildIT`
- Source:
  - tenant tax-report profile
- Output:
  - `ZEIMUSHO`
  - `NOZEISHA_*`
  - `KANPU_KINYUKIKAN`
  - `DAIHYO_*`
  - `SEIZOJO_*`
  - `DAIRI_*`
- Notes:
  - IDs and IDREF targets should be created centrally.

### `buildLIA010`
- Source:
  - report period
  - totals
  - IT references
  - declaration type defaults or explicit selections
- Output:
  - declaration header
  - taxpayer references
  - totals section

### `buildLIA110`
- Source:
  - summary-side breakdown rows
- Output:
  - one or more `LIA110` pages
- Notes:
  - paginate explicitly using schema row limits
  - element order must follow XSD sequence exactly

### `buildLIA220`
- Source:
  - return/refund-side breakdown rows
- Output:
  - one or more `LIA220` pages

### `buildCATALOG`
- Short-term:
  - generate from a controlled internal template using emitted form ids
- Long-term:
  - dedicated RDF builder if needed

## XML Technology Choice
- Recommended:
  - `xmlbuilder2`
- Reason:
  - explicit element ordering
  - attributes and namespaces are easy to control
  - better maintainability than string replacement

Avoid:
- regex-driven XML updates
- DOM mutation of a sample template
- runtime XSD parsing in the browser

## Validation Subsystem Design
### Public API of `src/lib/taxreportxml/RLI0010_232`
Recommended exports from `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/index.ts`:

```ts
export type { RLI0010_232_Input } from './types'
export type { RLI0010_232_Result } from './types'
export { reportName, schemaMap } from './constants'
export { buildXml } from './builders/root'
export { validateBusiness } from './validation/business'
export { validateStructural } from './validation/structural'
export { validateXsdRequest, parseXsdValidationError } from './validation/xsd'
export { generateRLI0010_232 } from './service'
```

Recommended facade behavior:

```ts
type GenerateRLI0010_232Options = {
  input: RLI0010_232_Input
  validateXsd: (xml: string, reportName: 'RLI0010_232') => Promise<void>
}

async function generateRLI0010_232(
  options: GenerateRLI0010_232Options,
): Promise<RLI0010_232_Result>
```

Design rule:
- `generateRLI0010_232()` should:
  - map canonical input to report payloads
  - build XML
  - run business validation
  - run structural validation
  - call the XSD validation service
  - throw if XSD validation fails

### Public validation contract
- The XML generation subsystem should expose a stable result shape:

```ts
type GenerateTaxReportXmlResult = {
  xml: string
  reportName: string
  validation: {
    businessValid: boolean
    structuralValid: boolean
    xsdValid: boolean
    messages: Array<{
      level: 'error' | 'warning'
      source: 'business' | 'structural' | 'xsd'
      code: string
      message: string
      path?: string
    }>
  }
}
```

### Validation rule
- `xsdValid` must be `true` before the XML is treated as completed output.
- If `xsdValid` is `false`:
  - save should be blocked
  - “successful generation” status should not be shown
  - the XSD validation service should return an HTTP error
  - the caller should treat that error as generation failure

### Recommended HTTP error shape
```json
{
  "code": "XSD_VALIDATION_FAILED",
  "reportName": "RLI0010_232",
  "messages": [
    {
      "level": "error",
      "source": "xsd",
      "path": "/DATA/RLI0010/CONTENTS/LIA110[1]",
      "message": "Element 'EHD00080' is missing."
    }
  ]
}
```

### Schema bundle management
- Each report folder should own a schema bundle manifest describing:
  - root XSD file
  - imported/included dependencies
  - namespace expectations
- Example:

```ts
export const validationBundle = {
  rootXsd: 'RLI0010-232.xsd',
  includes: [
    '../general/ITdefinition.xsd',
    '../general/CATALOG.xsd',
    'LIA010-004.xsd',
    'LIA110-003.xsd',
    'LIA220-002.xsd',
  ],
}
```

### Why report-name sandboxing also helps validation
- When XSD version changes:
  - the builder logic changes inside one report folder
  - the validation bundle changes inside the same report folder
  - the application-level API does not need to know the internal schema dependency graph

## Guess About Data Sources Based On Current Template-Based Implementation
These are inferred from the current implementation and should be treated as the initial design assumption, not final truth.

### `IT`
- Likely source:
  - `tenants.meta.tax_report_profile`
- Evidence:
  - [taxReportProfile.ts] stores schema-aligned IT fields
- Current gap:
  - current XML generator does not yet use this profile dynamically

### `LIA010`
- Likely source:
  - editor form period fields
  - derived `totalTaxAmount`
  - tenant profile references
  - possibly fixed defaults for declaration category / procedure metadata
- Evidence:
  - current generator updates period and keeps header/body mostly from sample template

### `LIA110`
- Likely source:
  - `tax_reports.volume_breakdown`
  - generated from movement headers, movement lines, package sizes, batch attrs, category registry, and alcohol tax registry
- Current concrete inputs inferred from code:
  - `inv_movements`
  - `inv_movement_lines`
  - `mes_batches`
  - `entity_attr`
  - `attr_def`
  - `mst_package`
  - `mst_uom`
  - `registry_def(kind='alcohol_type')`
  - `registry_def(kind='alcohol_tax')`
  - `movement_get_rules(...)`

### `LIA220`
- Likely source:
  - subset of `volume_breakdown` where the tax event is `RETURN_TO_FACTORY`

### `TENPU`
- Likely source:
  - current attachment list in `tax_reports.attachment_files`
  - plus future attachment metadata if binary uploads are formalized

### `CATALOG`
- Likely source:
  - generator-managed metadata only
- It should not depend directly on inventory data.

## Current-to-Target Mapping
### What remains reusable from the current implementation
- movement aggregation logic
- tax calculation logic
- category lookup logic
- tax-rate lookup logic
- report file naming
- storage upload/download behavior

### What should be replaced
- fixed sample template dependency
- regex replacements in XML
- implicit borrowing of non-row XML from `R7年11月_納税申告.xtx`

## Required `TaxReportEditor` GUI Changes
The current page is organized around “movement table + create XML button”. That is too thin for schema-driven generation.

### New editor layout
Recommended sections:

1. Report header
- tax type
- tax year
- tax month
- schema version
- generation status

2. Tax report profile status
- show whether required profile fields are complete
- link to `申告基本情報`
- display missing required fields summary

3. Form generation summary
- `IT`: ready / invalid
- `LIA010`: ready / invalid
- `LIA110`: page count preview
- `LIA220`: page count preview
- `TENPU`: attachment count
 - `XSD validation`: pending / pass / fail

4. Source data section
- summary breakdown table
- return/disposal breakdown table
- show data-source provenance per section

5. Validation panel
- business validation errors
- schema-structure warnings
- unsupported field warnings

6. Output section
- generate XML
- validate against XSD
- download XML
- generated file metadata

### UI behavior changes
- Replace simple “Create XML” actions with:
  - `Validate`
  - `Generate XML`
  - `Download XML`
- Disable generation when required IT/profile data is missing.
- Disable successful save/download actions when XSD validation has not passed.
- Show which XML forms will be emitted before generation.
- Show schema version explicitly so users know which e-Tax definition is active.
- Show counts:
  - `LIA110 pages`
  - `LIA220 pages`
  - attachment sections included or omitted
- Show validation badges:
  - business validation
  - structural validation
  - XSD validation

### New editor data dependencies
- The page should load:
  - tenant tax-report profile completeness state
  - schema-version configuration
  - form validation result
- The page should not inspect XML strings directly.

### Suggested editor flow
1. User opens report editor.
2. Page loads report source data and tenant tax-report profile.
3. Page shows a readiness summary:
  - source data ready
  - profile ready
  - validation issues
4. User fixes missing profile data if needed.
5. User validates.
6. System runs XSD validation on the generated XML.
7. If XSD validation fails, the validation endpoint returns an HTTP error and the page shows the returned messages.
8. User downloads or saves generated files only after XSD validation passes.

## Migration Plan
### Phase 1. Foundation
- Create `src/lib/taxreportxml`.
- Define canonical input types.
- Move current XML orchestration entrypoint into the new module.
- Keep current template-based generation behind a compatibility adapter.

### Phase 2. Schema-driven core
- Implement `RLI0010_232/buildIT`
- Implement `RLI0010_232/buildLIA010`
- Implement `RLI0010_232/buildLIA110`
- Implement `RLI0010_232/buildLIA220`
- Keep `CATALOG` on a controlled internal template if necessary

### Phase 3. Editor integration
- Update `TaxReportEditor` to use readiness/validation/generation state from `taxreportxml`
- Remove direct dependence on `public/etax/R7年11月_納税申告.xtx`

### Phase 4. Validation hardening
- Add business validation tests
- Add XML snapshot tests
- Add mandatory XSD validation in a backend service or equivalent controlled runtime
- Make editor save/download flow depend on passed XSD validation

### Phase 5. Future version support
- Add a new version folder for the next XSD release
- Keep the app-level generation API stable

## Testing Strategy
- Unit tests:
  - canonical input to form payload mapping
  - pagination
  - ID/IDREF wiring
  - business validation
- Snapshot tests:
  - generated `IT`
  - generated `LIA010`
  - generated `LIA110`
  - generated root document
- Regression tests:
  - compare generated rows against current report breakdown semantics

## Final Recommendation
- Treat `src/lib/taxreportxml` as a versioned XML generation subsystem, not just another helper file.
- Keep all XSD-version assumptions inside `RLI0010_232` or the matching future report folder.
- Keep `TaxReportEditor` focused on source-data review, readiness, validation, and file actions.
- Reuse current business-data aggregation, but stop using the sample `.xtx` file as the source of truth for XML structure.
