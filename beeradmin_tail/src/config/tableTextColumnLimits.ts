export const TABLE_TEXT_COLUMN_MAX_CHARS = {
  default: 18,
  beerCategory: 12,
  liquorCode: 12,
  beerName: 18,
  batchCode: 16,
  packageType: 14,
  packageInfo: 18,
  styleName: 16,
  productName: 18,
  lotNo: 16,
  site: 16,
  source: 16,
  destination: 16,
  tankNo: 12,
  brand: 18,
  container: 14,
  removalType: 14,
  address: 26,
  notes: 24,
} as const

export type TableTextColumnKey = keyof typeof TABLE_TEXT_COLUMN_MAX_CHARS

export function tableTextColumnMaxChars(column?: string | null) {
  if (!column) return null
  return (
    TABLE_TEXT_COLUMN_MAX_CHARS[column as TableTextColumnKey] ??
    TABLE_TEXT_COLUMN_MAX_CHARS.default
  )
}

export function tableTextColumnMaxWidth(column?: string | null) {
  const chars = tableTextColumnMaxChars(column)
  return chars == null ? '' : `${chars}ch`
}
