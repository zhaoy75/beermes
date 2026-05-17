export const JAPANESE_TAX_YEAR_MONTHS = [4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3] as const

export function japaneseTaxYearMonthOptions() {
  return [...JAPANESE_TAX_YEAR_MONTHS]
}
