export type AlcoholTypeRegistryRow = {
  def_id?: unknown
  def_key?: unknown
  spec?: Record<string, unknown> | null
}

function toTrimmedString(value: unknown) {
  if (value == null) return ''
  const text = String(value).trim()
  return text
}

function normalizedNumericString(value: unknown) {
  if (value == null) return ''
  if (typeof value === 'number' && Number.isFinite(value)) return String(Math.trunc(value))
  const text = toTrimmedString(value)
  if (!text) return ''
  const numeric = Number(text)
  return Number.isFinite(numeric) ? String(Math.trunc(numeric)) : ''
}

function uniqueStrings(values: string[]) {
  return Array.from(new Set(values.filter((value) => value.length > 0)))
}

export function alcoholTypeDisplayLabel(row: AlcoholTypeRegistryRow) {
  const spec = row.spec && typeof row.spec === 'object' ? row.spec : {}
  return (
    toTrimmedString(spec.name) ||
    toTrimmedString(row.def_key) ||
    toTrimmedString(row.def_id) ||
    null
  )
}

export function alcoholTypeLookupKeys(row: AlcoholTypeRegistryRow) {
  const spec = row.spec && typeof row.spec === 'object' ? row.spec : {}
  const taxCategoryCode = toTrimmedString(spec.tax_category_code)
  return uniqueStrings([
    toTrimmedString(row.def_id),
    toTrimmedString(row.def_key),
    toTrimmedString(spec.name),
    toTrimmedString(spec.code),
    taxCategoryCode,
    normalizedNumericString(spec.tax_category_code),
  ])
}

export function buildAlcoholTypeLabelMap(rows: AlcoholTypeRegistryRow[]) {
  const map = new Map<string, string>()
  rows.forEach((row) => {
    const label = alcoholTypeDisplayLabel(row)
    if (!label) return
    alcoholTypeLookupKeys(row).forEach((key) => map.set(key, label))
  })
  return map
}

export function resolveAlcoholTypeLabel(
  labelMap: Map<string, string>,
  value: string | number | null | undefined,
) {
  const key = toTrimmedString(value)
  if (!key) return null
  return labelMap.get(key) ?? null
}
