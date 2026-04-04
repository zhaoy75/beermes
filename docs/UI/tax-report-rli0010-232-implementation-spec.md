# RLI0010_232 Schema-Driven XML Implementation Spec

## Purpose
- Convert the grand design for schema-driven `酒税申告` XML generation into an implementation-ready technical spec.
- Lock down the first supported report module:
  - `beeradmin_tail/src/lib/taxreportxml/RLI0010_232`
- Define the module API, XSD validation contract, and `TaxReportEditor` interaction model.

## Scope
- First supported report:
  - `RLI0010_232`
- First supported forms:
  - `DATA`
  - `RLI0010`
  - `CATALOG`
  - `IT`
  - `LIA010`
  - `LIA110`
  - `LIA220`
- Optional forms that remain out of initial scope:
  - `LIA130`
  - `LIA230`
  - `LIA240`
  - `LIA250`
  - `LIA260`
  - `TENPU`

## Non-Goals
- No support for generic XSD-to-XML rendering.
- No implementation of additional report families in this spec.
- No attempt to cover digital signature generation in this spec.
- No change to tax business logic beyond what is required to express the current monthly flow in schema-driven form.

## Source of Truth
- Root schema:
  - `etax/19XMLスキーマ/shuzei/RLI0010-232.xsd`
- Shared IT schema:
  - `etax/19XMLスキーマ/general/ITdefinition.xsd`
- Shared general types:
  - `etax/19XMLスキーマ/general/General.xsd`
- Tenant profile source:
  - `beeradmin_tail/src/lib/taxReportProfile.ts`

## Target Module Layout

```text
beeradmin_tail/src/lib/taxreportxml/
  index.ts
  types/
    canonical.ts
    validation.ts
    service.ts
  core/
    ids.ts
    pagination.ts
    xml.ts
    catalog.ts
  RLI0010_232/
    index.ts
    constants.ts
    types.ts
    service.ts
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

## Public API
### File
- `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/index.ts`

### Required exports

```ts
export const reportName = 'RLI0010_232'
export { schemaMap } from './schemaMap'

export type {
  RLI0010_232_Input,
  RLI0010_232_Result,
  RLI0010_232_ValidationMessage,
  RLI0010_232_XsdValidateRequest,
  RLI0010_232_XsdValidateResponse,
} from './types'

export { buildXml } from './builders/root'
export { validateBusiness } from './validation/business'
export { validateStructural } from './validation/structural'
export { validateXsdRequest, parseXsdValidationError } from './validation/xsd'
export { generateRLI0010_232 } from './service'
```

### Facade function

```ts
type GenerateRLI0010_232Options = {
  input: RLI0010_232_Input
  validateXsd: (request: RLI0010_232_XsdValidateRequest) => Promise<RLI0010_232_XsdValidateResponse>
}

async function generateRLI0010_232(
  options: GenerateRLI0010_232Options,
): Promise<RLI0010_232_Result>
```

### Facade behavior
- `generateRLI0010_232()` must:
  1. normalize canonical input
  2. map canonical input to form payloads
  3. build XML
  4. run business validation
  5. run structural validation
  6. call XSD validation service
  7. return result only if XSD validation passes
- If XSD validation fails:
  - the function must throw
  - the thrown error must preserve structured validation messages

## Exact Types
### Canonical input

```ts
type RLI0010_232_Input = {
  report: {
    taxType: 'monthly'
    taxYear: number
    taxMonth: number
    generatedAt: string
  }
  tenant: {
    tenantId: string
    tenantName: string
  }
  profile: TaxReportProfile
  totals: {
    totalTaxAmount: number
    refundableTaxAmount: number
    roundedDownAmount: number
    payableTaxAmount: number
    amendedRefundableTaxAmount?: number
    amendedPayableTaxAmount?: number
    netPayableTaxAmount?: number
  }
  breakdown: {
    summary: TaxVolumeItem[]
    returns: TaxVolumeItem[]
  }
  attachments: Array<{
    kind: string
    fileName: string
    storageBucket?: string | null
    storagePath?: string | null
  }>
}
```

### Validation message

```ts
type RLI0010_232_ValidationMessage = {
  level: 'error' | 'warning'
  source: 'business' | 'structural' | 'xsd'
  code: string
  message: string
  path?: string
}
```

### Generation result

```ts
type RLI0010_232_Result = {
  reportName: 'RLI0010_232'
  xml: string
  fileName: string
  formSummary: {
    IT: { included: true }
    LIA010: { included: true }
    LIA110: { included: boolean; pageCount: number; rowCount: number }
    LIA220: { included: boolean; pageCount: number; rowCount: number }
  }
  validation: {
    businessValid: boolean
    structuralValid: boolean
    xsdValid: true
    messages: RLI0010_232_ValidationMessage[]
  }
}
```

### XSD validation request/response

```ts
type RLI0010_232_XsdValidateRequest = {
  reportName: 'RLI0010_232'
  xml: string
}

type RLI0010_232_XsdValidateResponse = {
  reportName: 'RLI0010_232'
  valid: boolean
  messages: RLI0010_232_ValidationMessage[]
}
```

## Schema Map Contract
### File
- `beeradmin_tail/src/lib/taxreportxml/RLI0010_232/schemaMap.ts`

### Required shape

```ts
export const schemaMap = {
  reportName: 'RLI0010_232',
  root: {
    procedureCode: 'RLI0010',
    version: '23.2.0',
    namespace: 'http://xml.e-tax.nta.go.jp/XSD/shuzei',
  },
  forms: {
    IT: { required: true },
    LIA010: { required: true, version: '0.0.4' },
    LIA110: { required: true, version: '0.0.3', rowsPerPage: 18 },
    LIA220: { required: false, version: '0.0.2', rowsPerPage: 18 },
  },
  validation: {
    rootXsd: 'RLI0010-232.xsd',
  },
}
```

## Internal Responsibilities
### `mappers/toIT.ts`
- Convert `TaxReportProfile` into IT payload
- Own:
  - `ZEIMUSHO`
  - `NOZEISHA_ID`
  - `NOZEISHA_BANGO`
  - `NOZEISHA_NM_KN`
  - `NOZEISHA_NM`
  - `NOZEISHA_ZIP`
  - `NOZEISHA_ADR_KN`
  - `NOZEISHA_ADR`
  - `NOZEISHA_TEL`
  - `KANPU_KINYUKIKAN`
  - `DAIHYO_*`
  - `SEIZOJO_*`
  - `DAIRI_*`

### `mappers/toLIA010.ts`
- Convert report totals and period into LIA010 payload
- Own:
  - reporting period fields
  - declaration category defaults
  - tax totals
  - IT reference fields

### `mappers/toLIA110.ts`
- Convert summary-side breakdown rows into paged LIA110 payloads
- Own:
  - row grouping
  - page splitting
  - form page numbering

### `mappers/toLIA220.ts`
- Convert return-side breakdown rows into paged LIA220 payloads

### `builders/*`
- Render XML elements in schema order only
- No business lookup logic
- No Supabase queries

## Business Data Source Assumptions
These are implementation assumptions based on the current template-driven flow.

### `IT`
- Source:
  - `tenants.meta.tax_report_profile`
- Access path:
  - current frontend helper in `taxReportProfile.ts`

### `LIA010`
- Source:
  - report period from editor state
  - totals from generated report breakdown
  - taxpayer references from tenant profile

### `LIA110`
- Source:
  - `tax_reports.volume_breakdown`
  - generated from:
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
- Source:
  - subset of `volume_breakdown` where tax event is return/refund related
  - current practical assumption:
    - `RETURN_TO_FACTORY`

### `CATALOG`
- Source:
  - generator-owned metadata and form ids only

## XSD Validation Service Spec
### Placement
- XSD validation must run outside the browser in a controlled HTTP service.

### Endpoint
- Recommended endpoint:
  - `POST /api/taxreportxml/RLI0010_232/validate`

Alternative acceptable deployment:
- Supabase Edge Function
- internal API route
- backend microservice

### Request

```json
{
  "reportName": "RLI0010_232",
  "xml": "<DATA ...>...</DATA>"
}
```

### Success response
- HTTP `200`

```json
{
  "reportName": "RLI0010_232",
  "valid": true,
  "messages": []
}
```

### Failure response
- HTTP `422 Unprocessable Entity`

```json
{
  "code": "XSD_VALIDATION_FAILED",
  "reportName": "RLI0010_232",
  "messages": [
    {
      "level": "error",
      "source": "xsd",
      "code": "XML_SCHEMA_ERROR",
      "path": "/DATA/RLI0010/CONTENTS/LIA110[1]",
      "message": "Element 'EHD00080' is missing."
    }
  ]
}
```

### Caller behavior
- On HTTP `200`:
  - continue to save/download flow
- On HTTP `422`:
  - block save
  - block successful download state
  - show returned messages in UI
- On HTTP `5xx` or transport failure:
  - treat validation as failed
  - show system error
  - do not mark XML generation as successful

## TaxReportEditor Spec
### Required state model

```ts
type TaxReportEditorXmlState = {
  reportName: 'RLI0010_232'
  sourceReady: boolean
  profileReady: boolean
  businessValidation: 'idle' | 'pass' | 'fail'
  structuralValidation: 'idle' | 'pass' | 'fail'
  xsdValidation: 'idle' | 'pending' | 'pass' | 'fail'
  generation: 'idle' | 'building' | 'ready' | 'error'
  generatedXml: string | null
  validationMessages: RLI0010_232_ValidationMessage[]
  formSummary: {
    lia110Pages: number
    lia220Pages: number
  }
}
```

### Required UI sections
1. Report header
- tax type
- tax year
- tax month
- report name: `RLI0010_232`

2. Readiness section
- source data ready
- profile ready
- missing required fields list

3. Form summary section
- `IT`
- `LIA010`
- `LIA110` page count
- `LIA220` page count

4. Validation section
- business validation badge
- structural validation badge
- XSD validation badge
- detailed message list

5. Output section
- `Validate`
- `Generate XML`
- `Download XML`
- `Save`

### Button behavior
- `Validate`
  - runs business + structural validation
  - if those pass, triggers XSD validation request
- `Generate XML`
  - builds XML
  - may internally trigger validation if state is stale
- `Download XML`
  - enabled only when:
    - generation is ready
    - XSD validation is pass
- `Save`
  - enabled only when:
    - generation is ready
    - XSD validation is pass

### Failure behavior
- If XSD validation returns HTTP `422`:
  - keep generated XML in memory only if useful for debugging
  - set UI state to `xsdValidation = fail`
  - render returned errors
  - do not upload/save report XML

## Save/Download Workflow
1. User opens `TaxReportEditor`.
2. Page loads source report data and tenant tax-report profile.
3. Page builds canonical `RLI0010_232_Input`.
4. User validates or generates.
5. Module builds XML.
6. Module sends XML to XSD validation service.
7. If validation passes:
  - enable download
  - enable save/upload
8. If validation fails:
  - return HTTP error path to UI
  - block save
  - block success status

## Implementation Phases
### Phase 1
- Create folder `beeradmin_tail/src/lib/taxreportxml/RLI0010_232`
- Add types, schema map, business validation, structural validation
- Add `IT`, `LIA010`, `LIA110`, `LIA220` builders

### Phase 2
- Add HTTP XSD validation endpoint
- Add endpoint client in `validation/xsd.ts`
- Integrate into `generateRLI0010_232()`

### Phase 3
- Refactor `TaxReportEditor` to use the new state model
- Remove direct dependence on sample `.xtx`

### Phase 4
- Add test coverage:
  - unit tests for mappers
  - pagination tests
  - XML snapshot tests
  - endpoint contract tests

## Acceptance Criteria
- `TaxReportEditor` no longer depends on `public/etax/R7年11月_納税申告.xtx`
- XML is generated from `beeradmin_tail/src/lib/taxreportxml/RLI0010_232`
- Generated XML is validated through HTTP against the target XSD set
- HTTP `422` is returned on XSD validation failure
- Save/download success is impossible unless XSD validation passes
- Current summary and return breakdown semantics are preserved

## Final Recommendation
- Implement `RLI0010_232` as the first concrete report module.
- Do not add another abstraction layer until this module is working end-to-end.
- Keep the public API small and strict.
- Treat XSD validation failure as a hard error, not a warning.
