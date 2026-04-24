export const VOLUME_DISPLAY_DECIMALS = 3
export const MILLILITERS_PER_LITER = 1000
export const MILLILITERS_PER_KILOLITER = 1000000
const US_GALLON_TO_MILLILITERS = 3785.41

type VolumeLocale = string | string[] | undefined

function isFiniteNumber(value: number | null | undefined): value is number {
  return value != null && Number.isFinite(Number(value))
}

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

export function litersToMilliliters(value: number | null | undefined) {
  if (!isFiniteNumber(value)) return null
  return Math.round(Number(value) * MILLILITERS_PER_LITER)
}

export function millilitersToLiters(value: number | null | undefined) {
  if (!isFiniteNumber(value)) return null
  return Number(value) / MILLILITERS_PER_LITER
}

export function quantityToMilliliters(
  value: number | null | undefined,
  uomCode?: string | null,
) {
  if (!isFiniteNumber(value)) return null
  const numeric = Number(value)
  switch (uomCode?.trim().toLowerCase()) {
    case 'ml':
      return Math.round(numeric)
    case 'kl':
      return Math.round(numeric * MILLILITERS_PER_KILOLITER)
    case 'gal_us':
      return Math.round(numeric * US_GALLON_TO_MILLILITERS)
    case 'l':
    case '':
    case undefined:
    case null:
      return litersToMilliliters(numeric)
    default:
      return litersToMilliliters(numeric)
  }
}

export function millilitersToQuantity(
  value: number | null | undefined,
  uomCode?: string | null,
) {
  if (!isFiniteNumber(value)) return null
  const numeric = Number(value)
  switch (uomCode?.trim().toLowerCase()) {
    case 'ml':
      return numeric
    case 'kl':
      return numeric / MILLILITERS_PER_KILOLITER
    case 'gal_us':
      return numeric / US_GALLON_TO_MILLILITERS
    case 'l':
    case '':
    case undefined:
    case null:
      return millilitersToLiters(numeric)
    default:
      return millilitersToLiters(numeric)
  }
}

export function formatMilliliters(
  value: number | null | undefined,
  locale?: VolumeLocale,
  fallback = '—',
) {
  if (!isFiniteNumber(value)) return fallback
  return new Intl.NumberFormat(locale, {
    maximumFractionDigits: 0,
  }).format(Math.round(Number(value)))
}

export function formatUnitVolumeFromMilliliters(
  value: number | null | undefined,
  locale?: VolumeLocale,
  fallback = '—',
) {
  if (!isFiniteNumber(value)) return fallback
  const milliliterText = formatMilliliters(value, locale, fallback)
  if (milliliterText === fallback) return fallback
  return `${milliliterText} mL`
}

export function formatUnitVolumeFromLiters(
  value: number | null | undefined,
  locale?: VolumeLocale,
  fallback = '—',
) {
  const milliliters = litersToMilliliters(value)
  return formatUnitVolumeFromMilliliters(milliliters, locale, fallback)
}

export function formatTotalVolumeFromMilliliters(
  value: number | null | undefined,
  locale?: VolumeLocale,
  fallback = '—',
) {
  return formatVolume(millilitersToLiters(value), locale, 'L', fallback)
}

export function formatTotalVolumeFromLiters(
  value: number | null | undefined,
  locale?: VolumeLocale,
  fallback = '—',
) {
  return formatVolume(value, locale, 'L', fallback)
}
