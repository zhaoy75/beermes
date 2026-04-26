type AbvLocale = string | string[] | undefined

export function formatAbvPercent(
  value: number | null | undefined,
  locale?: AbvLocale,
  fallback = '—',
) {
  if (value == null || !Number.isFinite(Number(value))) return fallback
  const formatted = new Intl.NumberFormat(locale, {
    minimumFractionDigits: 1,
    maximumFractionDigits: 2,
  }).format(Number(value))
  return `${formatted}%`
}
