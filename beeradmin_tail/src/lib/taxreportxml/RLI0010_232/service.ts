import { buildXml } from './builders/root'
import { reportName } from './constants'
import type { RLI0010_232_Input, RLI0010_232_Result } from './types'
import { validateBusiness } from './validation/business'
import { validateStructural } from './validation/structural'
import { validateXsdRequest, XsdValidationError } from './validation/xsd'

type Options = {
  input: RLI0010_232_Input
}

export async function generateRLI0010_232(options: Options): Promise<RLI0010_232_Result> {
  const { input } = options
  const businessMessages = validateBusiness(input)
  const structuralMessages = validateStructural(input)
  const preflightErrors = [...businessMessages, ...structuralMessages].filter((message) => message.level === 'error')
  if (preflightErrors.length > 0) {
    throw new XsdValidationError(preflightErrors[0]?.message ?? 'Tax report XML validation failed.', {
      status: 422,
      messages: [...businessMessages, ...structuralMessages],
    })
  }

  const xml = buildXml(input)
  const xsdResponse = await validateXsdRequest({
    reportName,
    xml,
  })

  if (!xsdResponse.valid) {
    throw new XsdValidationError(xsdResponse.messages[0]?.message ?? 'XSD validation failed.', {
      status: 422,
      messages: xsdResponse.messages,
    })
  }

  return {
    reportName,
    xml,
    fileName: buildMonthlyReportFileName(input.report.taxYear, input.report.taxMonth),
    formSummary: {
      IT: { included: true },
      LIA010: { included: true },
      LIA110: {
        included: input.breakdown.summary.length > 0,
        pageCount: input.breakdown.summary.length > 0 ? Math.ceil(input.breakdown.summary.length / 18) : 0,
        rowCount: input.breakdown.summary.length,
      },
      LIA220: {
        included: input.breakdown.returns.length > 0,
        pageCount: input.breakdown.returns.length > 0 ? Math.ceil(input.breakdown.returns.length / 18) : 0,
        rowCount: input.breakdown.returns.length,
      },
    },
    validation: {
      businessValid: true,
      structuralValid: true,
      xsdValid: true,
      messages: [...businessMessages, ...structuralMessages, ...xsdResponse.messages],
    },
  }
}

function buildMonthlyReportFileName(taxYear: number, taxMonth: number) {
  const reiwa = taxYear >= 2019 ? `R${taxYear - 2018}年` : `${taxYear}年`
  return `${reiwa}${taxMonth}月_納税申告.xtx`
}
