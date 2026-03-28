import type { SupabaseClient } from '@supabase/supabase-js'

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

function taxCategoryCode(row: AlcoholTypeRegistryRow) {
  const spec = row.spec && typeof row.spec === 'object' ? row.spec : {}
  return toTrimmedString(spec.tax_category_code)
}

function addAlcoholTypeRowsToLabelMap(
  map: Map<string, string>,
  rows: AlcoholTypeRegistryRow[],
) {
  rows.forEach((row) => {
    const label = alcoholTypeDisplayLabel(row)
    if (!label) return
    alcoholTypeLookupKeys(row).forEach((key) => map.set(key, label))
  })
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

export function buildAlcoholTypeLabelMap(
  rows: AlcoholTypeRegistryRow[],
  fallbackRows: AlcoholTypeRegistryRow[] = [],
) {
  const map = new Map<string, string>()
  addAlcoholTypeRowsToLabelMap(map, fallbackRows)
  addAlcoholTypeRowsToLabelMap(map, rows)
  return map
}

export function buildAlcoholTypeLookupKeys(
  row: AlcoholTypeRegistryRow,
  fallbackRows: AlcoholTypeRegistryRow[] = [],
) {
  const code = taxCategoryCode(row)
  const relatedRows = code
    ? fallbackRows.filter((entry) => taxCategoryCode(entry) === code)
    : []
  return uniqueStrings([
    ...alcoholTypeLookupKeys(row),
    ...relatedRows.flatMap((entry) => alcoholTypeLookupKeys(entry)),
  ])
}

export async function loadAlcoholTypeReferenceData(
  client: SupabaseClient,
) {
  const [optionResult, fallbackResult] = await Promise.all([
    client
      .from('v_alcohol_type_options')
      .select('def_id, def_key, spec')
      .order('value', { ascending: true }),
    client
      .from('registry_def')
      .select('def_id, def_key, spec')
      .eq('kind', 'alcohol_type')
      .eq('is_active', true),
  ])

  if (optionResult.error) throw optionResult.error
  if (fallbackResult.error) throw fallbackResult.error

  return {
    optionRows: (optionResult.data ?? []) as AlcoholTypeRegistryRow[],
    fallbackRows: (fallbackResult.data ?? []) as AlcoholTypeRegistryRow[],
  }
}

export function resolveAlcoholTypeLabel(
  labelMap: Map<string, string>,
  value: string | number | null | undefined,
) {
  const key = toTrimmedString(value)
  if (!key) return null
  return labelMap.get(key) ?? null
}
