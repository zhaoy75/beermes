import type { RLI0010_232_Input, RLI0010_232_ValidationMessage } from '../types'

export function validateBusiness(input: RLI0010_232_Input) {
  const messages: RLI0010_232_ValidationMessage[] = []

  if (!input.profile.ZEIMUSHO.zeimusho_CD) {
    messages.push(error('PROFILE_ZEIMUSHO_CD_REQUIRED', '税務署コードが未設定です。', 'ZEIMUSHO.zeimusho_CD'))
  }
  if (!input.profile.ZEIMUSHO.zeimusho_NM) {
    messages.push(error('PROFILE_ZEIMUSHO_NM_REQUIRED', '税務署名が未設定です。', 'ZEIMUSHO.zeimusho_NM'))
  }
  if (!input.profile.NOZEISHA_ID) {
    messages.push(error('PROFILE_NOZEISHA_ID_REQUIRED', '利用者識別番号が未設定です。', 'NOZEISHA_ID'))
  }
  if (!input.profile.NOZEISHA_NM) {
    messages.push(error('PROFILE_NOZEISHA_NM_REQUIRED', '納税者名が未設定です。', 'NOZEISHA_NM'))
  }
  if (!input.profile.NOZEISHA_ADR) {
    messages.push(error('PROFILE_NOZEISHA_ADR_REQUIRED', '納税者住所が未設定です。', 'NOZEISHA_ADR'))
  }
  if (!input.profile.SEIZOJO_NM) {
    messages.push(error('PROFILE_SEIZOJO_NM_REQUIRED', '製造場名称が未設定です。', 'SEIZOJO_NM'))
  }
  if (!input.profile.SEIZOJO_ADR) {
    messages.push(error('PROFILE_SEIZOJO_ADR_REQUIRED', '製造場所在地が未設定です。', 'SEIZOJO_ADR'))
  }
  if (input.breakdown.summary.length === 0) {
    messages.push(error('LIA110_BREAKDOWN_REQUIRED', '税額算出表に出力する内訳がありません。', 'breakdown.summary'))
  }

  return messages
}

function error(code: string, message: string, path?: string): RLI0010_232_ValidationMessage {
  return {
    level: 'error',
    source: 'business',
    code,
    message,
    path,
  }
}
