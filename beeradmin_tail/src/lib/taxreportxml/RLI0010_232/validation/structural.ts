import type { RLI0010_232_Input, RLI0010_232_ValidationMessage } from '../types'
import { schemaMap } from '../schemaMap'
import { buildLia230OutputRows } from '../builders/lia230'
import { buildLia240OutputRows } from '../builders/lia240'

export function validateStructural(input: RLI0010_232_Input) {
  const messages: RLI0010_232_ValidationMessage[] = []

  input.breakdown.summary.forEach((item, index) => {
    if (item.categoryCode && item.categoryCode.length > 3) {
      messages.push(warn('CATEGORY_CODE_TRUNCATED', `酒類コードが3桁を超えています: ${item.categoryCode}`, `summary[${index}].categoryCode`))
    }
    if (item.volume_l < 0) {
      messages.push(error('NEGATIVE_VOLUME', '負の数量はXMLに出力できません。', `summary[${index}].volume_l`))
    }
  })

  input.breakdown.returns.forEach((item, index) => {
    if (item.volume_l < 0) {
      messages.push(error('NEGATIVE_RETURN_VOLUME', '負の戻入数量はXMLに出力できません。', `returns[${index}].volume_l`))
    }
  })

  input.breakdown.reimportDeductions.forEach((item, index) => {
    if (item.volume_l < 0) {
      messages.push(error('NEGATIVE_REIMPORT_DEDUCTION_VOLUME', '負の移入控除数量はXMLに出力できません。', `reimportDeductions[${index}].volume_l`))
    }
  })

  input.breakdown.disasterDeductions.forEach((item, index) => {
    if (item.volume_l < 0) {
      messages.push(error('NEGATIVE_DISASTER_DEDUCTION_VOLUME', '負の被災酒類数量はXMLに出力できません。', `disasterDeductions[${index}].volume_l`))
    }
  })

  input.breakdown.nonTaxableRemovals.forEach((item, index) => {
    if (item.volume_l < 0) {
      messages.push(error('NEGATIVE_NON_TAXABLE_REMOVAL_VOLUME', '負の未納税移出数量はXMLに出力できません。', `nonTaxableRemovals[${index}].volume_l`))
    }
  })

  input.breakdown.exportExempt.forEach((item, index) => {
    if (item.volume_l < 0) {
      messages.push(error('NEGATIVE_EXPORT_EXEMPT_VOLUME', '負の輸出免税数量はXMLに出力できません。', `exportExempt[${index}].volume_l`))
    }
  })

  const summaryPages = Math.ceil(input.breakdown.summary.length / schemaMap.forms.LIA110.rowsPerPage)
  if (summaryPages > 999) {
    messages.push(error('LIA110_PAGE_LIMIT', 'LIA110 の総頁数が上限を超えています。', 'breakdown.summary'))
  }
  const returnPages = Math.ceil(input.breakdown.returns.length / schemaMap.forms.LIA220.rowsPerPage)
  if (returnPages > 999) {
    messages.push(error('LIA220_PAGE_LIMIT', 'LIA220 の総頁数が上限を超えています。', 'breakdown.returns'))
  }
  const reimportPages = Math.ceil(
    buildLia230OutputRows(input.breakdown.reimportDeductions).length / schemaMap.forms.LIA230.rowsPerPage,
  )
  if (reimportPages > 999) {
    messages.push(error('LIA230_PAGE_LIMIT', 'LIA230 の総頁数が上限を超えています。', 'breakdown.reimportDeductions'))
  }
  const disasterPages = Math.ceil(
    buildLia240OutputRows(input.breakdown.disasterDeductions).length / schemaMap.forms.LIA240.rowsPerPage,
  )
  if (disasterPages > 999) {
    messages.push(error('LIA240_PAGE_LIMIT', 'LIA240 の総頁数が上限を超えています。', 'breakdown.disasterDeductions'))
  }
  const nonTaxableRemovalPages = Math.ceil(input.breakdown.nonTaxableRemovals.length / schemaMap.forms.LIA250.rowsPerPage)
  if (nonTaxableRemovalPages > 999) {
    messages.push(error('LIA250_PAGE_LIMIT', 'LIA250 の総頁数が上限を超えています。', 'breakdown.nonTaxableRemovals'))
  }
  const exportExemptPages = Math.ceil(input.breakdown.exportExempt.length / schemaMap.forms.LIA260.rowsPerPage)
  if (exportExemptPages > 999) {
    messages.push(error('LIA260_PAGE_LIMIT', 'LIA260 の総頁数が上限を超えています。', 'breakdown.exportExempt'))
  }

  return messages
}

function error(code: string, message: string, path?: string): RLI0010_232_ValidationMessage {
  return { level: 'error', source: 'structural', code, message, path }
}

function warn(code: string, message: string, path?: string): RLI0010_232_ValidationMessage {
  return { level: 'warning', source: 'structural', code, message, path }
}
