import type { SupabaseClient } from '@supabase/supabase-js'

export type LotChronologyCandidate = {
  lotId: string
  lotLabel?: string | null
}

export type LotChronologyViolation = {
  lotId: string
  lotLabel: string
  movementAt: string
  createdAt: string
}

export type LotChronologyCheckResult = {
  violations: LotChronologyViolation[]
  unavailableReason: string | null
}

export async function checkLotChronology(options: {
  supabase: SupabaseClient
  movementAt: string | Date | null | undefined
  lots: LotChronologyCandidate[]
}): Promise<LotChronologyCheckResult> {
  const movementAt = parseDate(options.movementAt)
  if (!movementAt || options.lots.length === 0) {
    return { violations: [], unavailableReason: null }
  }

  const lotMap = new Map<string, LotChronologyCandidate>()
  options.lots.forEach((lot) => {
    if (!lot.lotId) return
    if (!lotMap.has(lot.lotId)) lotMap.set(lot.lotId, lot)
  })

  const violations: LotChronologyViolation[] = []
  for (const lot of lotMap.values()) {
    const { data, error } = await options.supabase.rpc('lot_effective_created_at', {
      p_lot_id: lot.lotId,
    })
    if (error) {
      return { violations: [], unavailableReason: error.message }
    }

    const createdAt = parseDate(typeof data === 'string' ? data : null)
    if (!createdAt) continue
    if (createdAt.getTime() > movementAt.getTime()) {
      violations.push({
        lotId: lot.lotId,
        lotLabel: lot.lotLabel || lot.lotId,
        movementAt: movementAt.toISOString(),
        createdAt: createdAt.toISOString(),
      })
    }
  }

  return { violations, unavailableReason: null }
}

export function lotChronologyViolationMessage(
  violation: LotChronologyViolation,
  locale: string | null | undefined,
) {
  return [
    '移動日時はロット作成日時より前にできません。',
    `ロット: ${violation.lotLabel}`,
    `移動日時: ${formatDateTime(violation.movementAt, locale)}`,
    `ロット作成日時: ${formatDateTime(violation.createdAt, locale)}`,
  ].join(' ')
}

function parseDate(value: string | Date | null | undefined) {
  if (!value) return null
  const date = value instanceof Date ? value : new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
}

function formatDateTime(value: string, locale: string | null | undefined) {
  const date = parseDate(value)
  if (!date) return value
  return new Intl.DateTimeFormat(locale || undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  }).format(date)
}
