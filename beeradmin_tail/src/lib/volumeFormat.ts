export const VOLUME_DISPLAY_DECIMALS = 3

type VolumeLocale = string | string[] | undefined

export function formatVolumeNumber(
  value: number | null | undefined,
  locale?: VolumeLocale,
  fallback = '—',
) {
  if (value == null || Number.isNaN(Number(value))) return fallback
  return new Intl.NumberFormat(locale, {
    minimumFractionDigits: VOLUME_DISPLAY_DECIMALS,
    maximumFractionDigits: VOLUME_DISPLAY_DECIMALS,
  }).format(Number(value))
}

export function formatVolume(
  value: number | null | undefined,
  locale?: VolumeLocale,
  unit = 'L',
  fallback = '—',
) {
  const formatted = formatVolumeNumber(value, locale, fallback)
  if (formatted === fallback) return fallback
  return unit ? `${formatted} ${unit}` : formatted
}
