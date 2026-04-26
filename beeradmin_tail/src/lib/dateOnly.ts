const DATE_ONLY_PATTERN = /^(\d{4})-(\d{2})-(\d{2})/

function pad2(value: number) {
  return String(value).padStart(2, '0')
}

function isValidDateParts(year: number, month: number, day: number) {
  if (!Number.isInteger(year) || !Number.isInteger(month) || !Number.isInteger(day)) return false
  if (month < 1 || month > 12 || day < 1 || day > 31) return false
  const date = new Date(Date.UTC(year, month - 1, day))
  return date.getUTCFullYear() === year
    && date.getUTCMonth() === month - 1
    && date.getUTCDate() === day
}

function formatDateParts(year: number, month: number, day: number) {
  return `${year}-${pad2(month)}-${pad2(day)}`
}

function parseDateOnlyParts(value: unknown) {
  const normalized = normalizeDateOnly(value)
  if (!normalized) return null
  const year = Number(normalized.slice(0, 4))
  const month = Number(normalized.slice(5, 7))
  const day = Number(normalized.slice(8, 10))
  return { year, month, day, normalized }
}

export function normalizeDateOnly(value: unknown) {
  if (value === null || value === undefined) return ''
  if (value instanceof Date) {
    if (Number.isNaN(value.getTime())) return ''
    return formatDateParts(value.getFullYear(), value.getMonth() + 1, value.getDate())
  }

  const text = String(value).trim()
  if (!text) return ''

  const direct = text.match(DATE_ONLY_PATTERN)
  if (direct) {
    const year = Number(direct[1])
    const month = Number(direct[2])
    const day = Number(direct[3])
    return isValidDateParts(year, month, day) ? formatDateParts(year, month, day) : ''
  }

  const parsed = new Date(text)
  if (Number.isNaN(parsed.getTime())) return ''
  return formatDateParts(parsed.getFullYear(), parsed.getMonth() + 1, parsed.getDate())
}

export function isValidDateOnly(value: unknown) {
  return normalizeDateOnly(value) !== ''
}

export function formatDateOnly(value: unknown, locale?: string | null, fallback = '—') {
  const parts = parseDateOnlyParts(value)
  if (!parts) return fallback
  const date = new Date(parts.year, parts.month - 1, parts.day)
  return new Intl.DateTimeFormat(locale || undefined).format(date)
}

export function dateOnlySortValue(value: unknown) {
  const normalized = normalizeDateOnly(value)
  return normalized ? Number(normalized.replace(/-/g, '')) : null
}

export function compareDateOnly(a: unknown, b: unknown) {
  const left = dateOnlySortValue(a)
  const right = dateOnlySortValue(b)
  if (left === null && right === null) return 0
  if (left === null) return 1
  if (right === null) return -1
  return left - right
}

export function nextDateOnly(value: unknown) {
  const parts = parseDateOnlyParts(value)
  if (!parts) return ''
  const date = new Date(Date.UTC(parts.year, parts.month - 1, parts.day))
  date.setUTCDate(date.getUTCDate() + 1)
  return formatDateParts(date.getUTCFullYear(), date.getUTCMonth() + 1, date.getUTCDate())
}

export function dateOnlyToUtcStartOfDayIso(value: unknown) {
  const parts = parseDateOnlyParts(value)
  if (!parts) return null
  return new Date(Date.UTC(parts.year, parts.month - 1, parts.day)).toISOString()
}
