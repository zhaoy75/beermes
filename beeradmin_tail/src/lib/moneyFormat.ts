type MoneyLocale = string | string[] | undefined

function finiteNumber(value: number | null | undefined) {
  return Number.isFinite(value) ? Number(value) : 0
}

export function truncateYen(value: number | null | undefined) {
  const numeric = finiteNumber(value)
  return numeric < 0 ? Math.ceil(numeric) : Math.floor(numeric)
}

export function nonNegativeYen(value: number | null | undefined) {
  return Math.max(0, truncateYen(value))
}

export function formatYen(
  value: number | null | undefined,
  locale?: MoneyLocale,
  fallback = '—',
) {
  if (value == null || Number.isNaN(Number(value))) return fallback
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency: 'JPY',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(truncateYen(Number(value)))
}

export function taxAmountFromMilliliters(
  milliliters: number | null | undefined,
  taxRatePerKiloliter: number | null | undefined,
) {
  const volumeMl = finiteNumber(milliliters)
  const rate = finiteNumber(taxRatePerKiloliter)
  return nonNegativeYen((volumeMl / 1000000) * rate)
}

export function taxAmountFromLiters(
  liters: number | null | undefined,
  taxRatePerKiloliter: number | null | undefined,
) {
  return taxAmountFromMilliliters(finiteNumber(liters) * 1000, taxRatePerKiloliter)
}
