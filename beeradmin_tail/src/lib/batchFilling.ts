export interface FillingCalculationOptions {
  isPackageVolumeFixed: (packageTypeId: string) => boolean
  resolvePackageUnitVolume: (packageTypeId: string) => number | null
}

export interface FillingHistoryLine {
  package_type_id?: string | null
  qty?: number | null
  volume?: number | null
  sample_flg?: boolean | null
}

export interface FillingHistoryEvent {
  tank_fill_start_volume?: number | null
  tank_left_volume?: number | null
  sample_volume?: number | null
  filling_lines?: FillingHistoryLine[] | null
}

function isFiniteNumber(value: unknown): value is number {
  return typeof value === 'number' && Number.isFinite(value)
}

export function litersToMilliliters(value: number | null | undefined) {
  if (!isFiniteNumber(value)) return null
  return Math.round(value * 1000)
}

export function millilitersToLiters(value: number | null | undefined) {
  if (!isFiniteNumber(value)) return null
  return value / 1000
}

function normalizeLiters(value: number | null | undefined) {
  const milliliters = litersToMilliliters(value)
  return millilitersToLiters(milliliters)
}

export function resolveFillingLineVolumeFromEvent(
  line: FillingHistoryLine,
  options: FillingCalculationOptions,
) {
  const packageTypeId = typeof line.package_type_id === 'string' ? line.package_type_id : ''
  if (!packageTypeId) return null
  if (options.isPackageVolumeFixed(packageTypeId)) {
    const unitVolume = options.resolvePackageUnitVolume(packageTypeId)
    if (!isFiniteNumber(unitVolume)) return null
    const qty = isFiniteNumber(line.qty) ? line.qty : 0
    return normalizeLiters(qty * unitVolume)
  }
  if (isFiniteNumber(line.volume)) return normalizeLiters(line.volume)
  return null
}

export function fillingLinesVolumeFromEvent(
  lines: FillingHistoryLine[],
  options: FillingCalculationOptions,
) {
  const totalMilliliters = lines.reduce((sum, line) => {
    if (line.sample_flg) return sum
    const volume = resolveFillingLineVolumeFromEvent(line, options)
    if (!isFiniteNumber(volume)) return sum
    return sum + (litersToMilliliters(volume) ?? 0)
  }, 0)
  return millilitersToLiters(totalMilliliters) ?? 0
}

export function fillingSampleVolumeFromEvent(
  lines: FillingHistoryLine[],
  options: FillingCalculationOptions,
) {
  const totalMilliliters = lines.reduce((sum, line) => {
    if (!line.sample_flg) return sum
    const volume = resolveFillingLineVolumeFromEvent(line, options)
    if (!isFiniteNumber(volume)) return sum
    return sum + (litersToMilliliters(volume) ?? 0)
  }, 0)
  return millilitersToLiters(totalMilliliters) ?? 0
}

export function fillingUnitsFromEvent(
  lines: FillingHistoryLine[],
  options: FillingCalculationOptions,
) {
  void options
  return lines.reduce((sum, line) => {
    if (line.sample_flg) return sum
    const packageTypeId = typeof line.package_type_id === 'string' ? line.package_type_id : ''
    if (!packageTypeId) return sum
    const qty = isFiniteNumber(line.qty) ? line.qty : 0
    return sum + qty
  }, 0)
}

export function packingFillingPayoutFromEvent(event: FillingHistoryEvent) {
  if (!isFiniteNumber(event.tank_fill_start_volume) || !isFiniteNumber(event.tank_left_volume)) return null
  return event.tank_fill_start_volume - event.tank_left_volume
}

export function packingTotalLineVolumeFromEvent(
  event: FillingHistoryEvent,
  options: FillingCalculationOptions,
) {
  const lines = Array.isArray(event.filling_lines) ? event.filling_lines : []
  return fillingLinesVolumeFromEvent(lines, options)
}

export function packingFillingRemainingFromEvent(
  event: FillingHistoryEvent,
  options: FillingCalculationOptions,
) {
  const payout = packingFillingPayoutFromEvent(event)
  if (!isFiniteNumber(payout)) return null
  return payout - packingTotalLineVolumeFromEvent(event, options)
}

export function packingLossFromEvent(
  event: FillingHistoryEvent,
  options: FillingCalculationOptions,
) {
  if (!isFiniteNumber(event.tank_fill_start_volume) || !isFiniteNumber(event.tank_left_volume)) return null
  const lines = Array.isArray(event.filling_lines) ? event.filling_lines : []
  const sampleVolume = isFiniteNumber(event.sample_volume)
    ? event.sample_volume
    : fillingSampleVolumeFromEvent(lines, options)
  const totalLineVolume = fillingLinesVolumeFromEvent(lines, options)
  return event.tank_fill_start_volume - event.tank_left_volume - totalLineVolume - sampleVolume
}

export function processedFillingVolumeFromEvent(
  event: FillingHistoryEvent,
  options: FillingCalculationOptions,
) {
  const lines = Array.isArray(event.filling_lines) ? event.filling_lines : []
  const totalLineVolume = fillingLinesVolumeFromEvent(lines, options)
  const sampleVolume = isFiniteNumber(event.sample_volume)
    ? event.sample_volume
    : fillingSampleVolumeFromEvent(lines, options)
  const loss = packingLossFromEvent(event, options)
  return totalLineVolume + sampleVolume + (isFiniteNumber(loss) ? loss : 0)
}
