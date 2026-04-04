import type { RLI0010_232_Input, RLI0010_232_ValidationMessage } from '../types'
import { schemaMap } from '../schemaMap'

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

  const summaryPages = Math.ceil(input.breakdown.summary.length / schemaMap.forms.LIA110.rowsPerPage)
  if (summaryPages > 999) {
    messages.push(error('LIA110_PAGE_LIMIT', 'LIA110 の総頁数が上限を超えています。', 'breakdown.summary'))
  }
  const returnPages = Math.ceil(input.breakdown.returns.length / schemaMap.forms.LIA220.rowsPerPage)
  if (returnPages > 999) {
    messages.push(error('LIA220_PAGE_LIMIT', 'LIA220 の総頁数が上限を超えています。', 'breakdown.returns'))
  }

  return messages
}

function error(code: string, message: string, path?: string): RLI0010_232_ValidationMessage {
  return { level: 'error', source: 'structural', code, message, path }
}

function warn(code: string, message: string, path?: string): RLI0010_232_ValidationMessage {
  return { level: 'warning', source: 'structural', code, message, path }
}
