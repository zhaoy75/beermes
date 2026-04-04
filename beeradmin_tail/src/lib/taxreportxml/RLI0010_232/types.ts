import type { TaxReportProfile } from '@/lib/taxReportProfile'
import type { TaxVolumeItem } from '@/lib/taxReport'

export type ValidationSource = 'business' | 'structural' | 'xsd'
export type ValidationLevel = 'error' | 'warning'

export interface RLI0010_232_ValidationMessage {
  level: ValidationLevel
  source: ValidationSource
  code: string
  message: string
  path?: string
}

export interface RLI0010_232_XsdValidateRequest {
  reportName: 'RLI0010_232'
  xml: string
}

export interface RLI0010_232_XsdValidateResponse {
  reportName: 'RLI0010_232'
  valid: boolean
  messages: RLI0010_232_ValidationMessage[]
}

export interface RLI0010_232_Input {
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

export interface RLI0010_232_Result {
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
