import { i18n } from '@/i18n'

export interface RpcErrorLike {
  code?: string
  message?: string
  details?: string | null
  hint?: string | null
  status?: number
}

export interface ParsedRpcError {
  businessCode?: string
  sqlState?: string
  status?: number
  summary: string
  rawMessage: string
  details?: string | null
  hint?: string | null
  params: Record<string, unknown>
}

export interface FormattedRpcError extends ParsedRpcError {
  message: string
  devMessage: string
}

export class RpcUserError extends Error {
  readonly businessCode?: string
  readonly sqlState?: string
  readonly devMessage: string
  readonly originalError: unknown

  constructor(formatted: FormattedRpcError, originalError: unknown) {
    super(formatted.message)
    this.name = 'RpcUserError'
    this.businessCode = formatted.businessCode
    this.sqlState = formatted.sqlState
    this.devMessage = formatted.devMessage
    this.originalError = originalError
  }
}

export interface FormatRpcErrorOptions {
  fallbackKey?: string
  fallbackParams?: Record<string, unknown>
}

type Translator = (key: string, params?: Record<string, unknown>) => string

const BUSINESS_CODE_PATTERN = /^([A-Z][A-Z0-9_]*\d{3}):\s*(.*)$/
const TAX_REPORT_LOCK_LABEL_PATTERN = /^(draft|stale|submitted|approved)\s+(\d{4})\/(\d{1,2})$/i

export function extractErrorMessage(error: unknown) {
  if (error instanceof Error && error.message) return error.message
  if (typeof error === 'object' && error !== null && 'message' in error) {
    const message = (error as { message?: unknown }).message
    return typeof message === 'string' ? message : ''
  }
  return typeof error === 'string' ? error : ''
}

export function parseRpcError(error: unknown): ParsedRpcError {
  const rpcError = toRpcErrorLike(error)
  const rawMessage = rpcError.message || extractErrorMessage(error)
  const businessMatch = rawMessage.match(BUSINESS_CODE_PATTERN)
  const detailParams = parseJsonObject(rpcError.details)

  return {
    businessCode: businessMatch?.[1],
    sqlState: rpcError.code,
    status: rpcError.status,
    summary: businessMatch?.[2] ?? rawMessage,
    rawMessage,
    details: rpcError.details,
    hint: rpcError.hint,
    params: detailParams ?? {},
  }
}

export function formatRpcError(
  error: unknown,
  options: FormatRpcErrorOptions = {},
  translator: Translator = translateGlobal,
): FormattedRpcError {
  const parsed = parseRpcError(error)
  const params = buildBusinessParams(parsed, translator)

  return {
    ...parsed,
    params,
    message: resolveUserMessage(parsed, params, options, translator),
    devMessage: buildDevMessage(parsed),
  }
}

export function formatRpcErrorMessage(error: unknown, options: FormatRpcErrorOptions = {}) {
  return formatRpcError(error, options).message
}

export function toRpcUserError(error: unknown, options: FormatRpcErrorOptions = {}) {
  return new RpcUserError(formatRpcError(error, options), error)
}

function resolveUserMessage(
  parsed: ParsedRpcError,
  params: Record<string, unknown>,
  options: FormatRpcErrorOptions,
  translator: Translator,
) {
  if (parsed.businessCode) {
    const codeMessage = translate(translator, `rpcErrors.codes.${parsed.businessCode}.message`, params)
    if (codeMessage) return codeMessage

    const familyMessage = translate(
      translator,
      `rpcErrors.families.${businessFamily(parsed.businessCode)}.message`,
      { ...params, code: parsed.businessCode },
    )
    if (familyMessage) return familyMessage

    return translate(translator, 'rpcErrors.fallback.business', { code: parsed.businessCode })
      ?? fallbackMessage(parsed, options, translator)
  }

  return fallbackMessage(parsed, options, translator)
}

function fallbackMessage(
  parsed: ParsedRpcError,
  options: FormatRpcErrorOptions,
  translator: Translator,
) {
  const fallbackKey = fallbackKeyFor(parsed)
  if (fallbackKey !== 'rpcErrors.fallback.unknown') {
    const categorized = translate(translator, fallbackKey)
    if (categorized) return categorized
  }

  if (isPlainError(parsed)) return parsed.rawMessage

  if (options.fallbackKey) {
    const pageFallback = translate(translator, options.fallbackKey, options.fallbackParams)
    if (pageFallback) return pageFallback
  }

  return translate(translator, fallbackKey)
    ?? 'The operation could not be completed.'
}

function buildBusinessParams(parsed: ParsedRpcError, translator: Translator) {
  const params: Record<string, unknown> = { ...parsed.params }

  if (parsed.businessCode === 'TRM002') {
    const reportMatch = parsed.summary.match(/tax report\s*\(([^)]+)\)/i)
    if (reportMatch) params.report = formatTaxReportLabel(reportMatch[1], translator)
  }

  if (parsed.businessCode === 'PMF500') {
    const segmentMatch = parsed.summary.match(/segment\s+(\d+)/i)
    if (segmentMatch) params.segment = segmentMatch[1]
  }

  return params
}

function businessFamily(code: string) {
  const match = code.match(/^([A-Z_]+?)(?:\d{3})$/)
  return match?.[1] ?? code
}

function formatTaxReportLabel(value: string, translator: Translator) {
  const match = value.trim().match(TAX_REPORT_LOCK_LABEL_PATTERN)
  if (!match) return value

  const [, status, year, month] = match
  const statusLabel = translate(translator, `taxReport.statusMap.${status.toLowerCase()}`) ?? status
  return `${statusLabel} ${year}/${month.padStart(2, '0')}`
}

function fallbackKeyFor(parsed: ParsedRpcError) {
  const blob = `${parsed.rawMessage} ${parsed.details ?? ''} ${parsed.hint ?? ''}`

  if (/fetch|network/i.test(blob)) return 'rpcErrors.fallback.network'
  if (parsed.status === 401) return 'rpcErrors.fallback.auth'
  if (parsed.status === 403 || parsed.sqlState === '42501') return 'rpcErrors.fallback.permission'
  if (parsed.status === 404) return 'rpcErrors.fallback.notFound'
  if (parsed.status === 409 || parsed.sqlState === '23505') return 'rpcErrors.fallback.conflict'
  if (parsed.status === 429) return 'rpcErrors.fallback.rateLimit'
  if (parsed.status && parsed.status >= 500) return 'rpcErrors.fallback.server'

  if (['23502', '23503', '23514'].includes(parsed.sqlState ?? '')) {
    return 'rpcErrors.fallback.validation'
  }

  if (/row-level security|rls|permission|not allowed/i.test(blob)) {
    return 'rpcErrors.fallback.permission'
  }

  return 'rpcErrors.fallback.unknown'
}

function isPlainError(parsed: ParsedRpcError) {
  return Boolean(parsed.rawMessage)
    && !parsed.sqlState
    && parsed.status == null
    && parsed.details == null
    && parsed.hint == null
}

function toRpcErrorLike(error: unknown): RpcErrorLike {
  if (typeof error !== 'object' || error === null) {
    return { message: typeof error === 'string' ? error : '' }
  }

  const record = error as Record<string, unknown>
  return {
    code: readString(record.code),
    message: readString(record.message),
    details: readNullableString(record.details),
    hint: readNullableString(record.hint),
    status: typeof record.status === 'number' ? record.status : undefined,
  }
}

function parseJsonObject(value: string | null | undefined) {
  if (!value) return null
  try {
    const parsed = JSON.parse(value)
    return typeof parsed === 'object' && parsed !== null && !Array.isArray(parsed)
      ? parsed as Record<string, unknown>
      : null
  } catch {
    return null
  }
}

function buildDevMessage(parsed: ParsedRpcError) {
  return [
    parsed.businessCode,
    parsed.sqlState,
    parsed.rawMessage,
    parsed.details,
    parsed.hint,
  ].filter(Boolean).join(' | ')
}

function translateGlobal(key: string, params?: Record<string, unknown>) {
  const t = i18n.global.t as unknown as Translator
  return params ? t(key, params) : t(key)
}

function translate(
  translator: Translator,
  key: string,
  params?: Record<string, unknown>,
) {
  const translated = params ? translator(key, params) : translator(key)
  return translated && translated !== key ? translated : null
}

function readString(value: unknown) {
  return typeof value === 'string' ? value : undefined
}

function readNullableString(value: unknown) {
  return typeof value === 'string' || value === null ? value : undefined
}
