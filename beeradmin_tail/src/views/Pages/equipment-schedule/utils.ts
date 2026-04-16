import type { FilterState, NameI18n, ReservationFormState, AssignmentRow } from './types'

export function rangeDaysForViewMode(viewMode: FilterState['viewMode']) {
  switch (viewMode) {
    case 'day':
      return 1
    case 'week':
      return 7
    case 'two_weeks':
      return 14
    case 'month':
      return 31
    default:
      return 14
  }
}

export function startOfDay(value: Date) {
  return new Date(value.getFullYear(), value.getMonth(), value.getDate(), 0, 0, 0, 0)
}

export function startOfHour(value: Date) {
  return new Date(value.getFullYear(), value.getMonth(), value.getDate(), value.getHours(), 0, 0, 0)
}

export function addDays(value: Date, days: number) {
  const next = new Date(value)
  next.setDate(next.getDate() + days)
  return next
}

export function addHours(value: Date, hours: number) {
  const next = new Date(value)
  next.setHours(next.getHours() + hours)
  return next
}

export function parseDateInput(value: string) {
  if (!value) return startOfDay(new Date())
  const parsed = new Date(`${value}T00:00:00`)
  return Number.isNaN(parsed.getTime()) ? startOfDay(new Date()) : parsed
}

export function parseDateTimeInput(value: string) {
  if (!value) return null
  const parsed = new Date(value)
  return Number.isNaN(parsed.getTime()) ? null : parsed
}

export function formatDateInput(value: Date) {
  const local = new Date(value.getTime() - value.getTimezoneOffset() * 60000)
  return local.toISOString().slice(0, 10)
}

export function formatDateTimeInput(value: Date) {
  const local = new Date(value.getTime() - value.getTimezoneOffset() * 60000)
  return local.toISOString().slice(0, 16)
}

export function createDefaultFilters(viewMode: FilterState['viewMode'] = 'two_weeks'): FilterState {
  const start = startOfDay(new Date())
  const end = addDays(start, rangeDaysForViewMode(viewMode))
  return {
    siteIds: [],
    equipmentTypeIds: [],
    equipmentIds: [],
    rangeStart: formatDateInput(start),
    rangeEnd: formatDateInput(end),
    viewMode,
    showCompleted: false,
    showActualUsage: true,
  }
}

export function createEmptyReservationForm(): ReservationFormState {
  const start = startOfHour(new Date())
  const end = addHours(start, 1)
  return {
    id: null,
    reservation_type: 'batch',
    equipment_id: '',
    batch_id: '',
    batch_step_id: '',
    start_at: formatDateTimeInput(start),
    end_at: formatDateTimeInput(end),
    status: 'reserved',
    note: '',
  }
}

export function normalizeBoardRange(rangeStart: string, rangeEnd: string, viewMode: FilterState['viewMode']) {
  const start = parseDateInput(rangeStart)
  let end = parseDateInput(rangeEnd)
  if (end.getTime() <= start.getTime()) {
    end = addDays(start, rangeDaysForViewMode(viewMode))
  }
  return {
    start,
    end,
    startIso: start.toISOString(),
    endIso: end.toISOString(),
  }
}

export function localizeName(value: { name_i18n?: NameI18n, name?: string | null, code?: string | null }, lang: string) {
  const localized = value.name_i18n?.[lang]
  if (localized) return localized
  if (value.name) return value.name
  const fallback = value.name_i18n ? Object.values(value.name_i18n)[0] : ''
  return fallback || value.code || ''
}

export function asNameI18n(value: unknown): NameI18n {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null
  const result: Record<string, string> = {}
  for (const [key, item] of Object.entries(value)) {
    if (typeof item === 'string') result[key] = item
  }
  return result
}

export function isValidRange(start: Date, end: Date) {
  return Number.isFinite(start.getTime()) && Number.isFinite(end.getTime()) && end.getTime() > start.getTime()
}

export function intersectsRange(start: Date, end: Date, rangeStart: Date, rangeEnd: Date) {
  return start.getTime() < rangeEnd.getTime() && end.getTime() > rangeStart.getTime()
}

export function resolveAssignmentStart(row: AssignmentRow) {
  if (row.assigned_at) {
    const parsed = new Date(row.assigned_at)
    if (!Number.isNaN(parsed.getTime())) return parsed
  }
  if (row.updated_at) {
    const parsed = new Date(row.updated_at)
    if (!Number.isNaN(parsed.getTime())) return parsed
  }
  return null
}

export function resolveAssignmentEnd(row: AssignmentRow) {
  if (row.released_at) {
    const parsed = new Date(row.released_at)
    if (!Number.isNaN(parsed.getTime())) return parsed
  }
  if (row.status === 'in_use') return new Date()
  const start = resolveAssignmentStart(row)
  return start ? addHours(start, 1) : null
}

export function parseCsvQuery(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value.flatMap((item) => parseCsvQuery(item))
  }
  if (typeof value !== 'string') return []
  return value.split(',').map((item) => item.trim()).filter(Boolean)
}

export function parseBooleanQuery(value: unknown, fallback: boolean) {
  if (value == null) return fallback
  if (Array.isArray(value)) return parseBooleanQuery(value[0], fallback)
  if (typeof value !== 'string') return fallback
  if (value === 'true') return true
  if (value === 'false') return false
  return fallback
}

export function parseStringQuery(value: unknown, fallback: string) {
  if (Array.isArray(value)) return parseStringQuery(value[0], fallback)
  return typeof value === 'string' && value.trim() ? value : fallback
}
