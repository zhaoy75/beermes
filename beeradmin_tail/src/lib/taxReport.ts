import type { SupabaseClient } from '@supabase/supabase-js'
import type { TaxReportProfile } from '@/lib/taxReportProfile'
import {
  generateRLI0010_232,
  type RLI0010_232_ReductionTotals,
} from '@/lib/taxreportxml/RLI0010_232'
import { nonNegativeYen, taxAmountFromLiters, truncateYen } from '@/lib/moneyFormat'
import { litersToMilliliters, millilitersToLiters } from '@/lib/volumeFormat'

export type JsonMap = Record<string, unknown>

export type TaxReportRowRole = 'detail' | 'kubun_summary' | 'category_summary' | 'grand_total'

export type TaxReportFileType =
  | 'tax_report_xml'
  | 'tax_report_dispose_xml'
  | 'taxable_removal_excel'
  | 'non_taxable_removal_ledger_excel'
  | 'export_exempt_ledger_excel'
  | 'non_taxable_receipt_ledger_excel'
  | 'return_to_factory_ledger_excel'
  | 'legacy'

export interface TaxVolumeItem {
  key: string
  move_type: string
  tax_event: string | null
  categoryId: string
  categoryCode: string
  categoryName: string
  abv: number | null
  volume_l: number
  volume_ml?: number | null
  tax_rate: number | null
  row_role?: TaxReportRowRole | null
  kubun_code?: number | null
  non_taxable_volume_l?: number | null
  export_exempt_volume_l?: number | null
  taxable_volume_l?: number | null
  tax_amount?: number | null
  export_date?: string | null
  export_destination?: string | null
  export_customs_office?: string | null
  exporter_address?: string | null
  exporter_name?: string | null
  export_reference_notes?: string | null
}

export interface TaxReportStoredFile {
  fileName: string
  fileType: TaxReportFileType | string
  mimeType: string | null
  storageBucket: string | null
  storagePath: string | null
  size: number | null
  generatedAt: string | null
}

export interface GeneratedTaxReportFile {
  blob: Blob
  fileName: string
  fileType: TaxReportFileType
  generatedAt: string
  mimeType: string
}

export interface TaxReportRow {
  id: string
  tax_type: string
  tax_year: number
  tax_month: number
  status: string
  total_tax_amount: number
  volume_breakdown: TaxVolumeItem[]
  report_files: TaxReportStoredFile[]
  attachment_files: string[]
  created_at: string | null
}

const SUMMARY_DOC_TYPES = ['sale', 'tax_transfer', 'return', 'transfer'] as const
const DISPOSE_DOC_TYPES = ['waste'] as const
const DEFAULT_BUCKET = import.meta.env.VITE_TAX_REPORT_STORAGE_BUCKET || 'tax-report-files'
const LIA130_REDUCTION_CATEGORY = 'Ａ'
const LIA130_REDUCTION_RATE = 0.8
const MOVEMENT_TYPE_SORT_ORDER = [
  ...SUMMARY_DOC_TYPES,
  ...DISPOSE_DOC_TYPES,
  'production_receipt',
  'unknown',
] as const
const TAX_EVENT_SORT_ORDER = [
  'TAXABLE_REMOVAL',
  'NON_TAXABLE_REMOVAL',
  'EXPORT_EXEMPT',
  'RETURN_TO_FACTORY',
  'RETURN_TO_FACTORY_NON_TAXABLE',
  'NONE',
  'unknown',
] as const
const LIA110_EXCLUDED_TAX_EVENTS = new Set(['NONE', 'RETURN_TO_FACTORY_NON_TAXABLE'])

export function summaryItemsFromBreakdown(items: TaxVolumeItem[]) {
  return items.filter((item) => !isGeneratedTaxVolumeItem(item) && isSummaryDocType(item.move_type))
}

export function disposeItemsFromBreakdown(items: TaxVolumeItem[]) {
  return items.filter((item) => !isGeneratedTaxVolumeItem(item) && isDisposeDocType(item.move_type))
}

export function sortTaxVolumeItems(items: TaxVolumeItem[]) {
  const rankMap = new Map<string, number>(
    MOVEMENT_TYPE_SORT_ORDER.map((value, index) => [value, index]),
  )
  const taxEventRankMap = new Map<string, number>(
    TAX_EVENT_SORT_ORDER.map((value, index) => [value, index]),
  )

  return [...items].sort((a, b) => {
    const taxEventA = resolveTaxEvent(a.move_type, a.tax_event)
    const taxEventB = resolveTaxEvent(b.move_type, b.tax_event)
    const taxRankA = taxEventRankMap.get(taxEventA ?? 'unknown') ?? Number.MAX_SAFE_INTEGER
    const taxRankB = taxEventRankMap.get(taxEventB ?? 'unknown') ?? Number.MAX_SAFE_INTEGER
    if (taxRankA !== taxRankB) return taxRankA - taxRankB

    const rankA = rankMap.get(a.move_type) ?? Number.MAX_SAFE_INTEGER
    const rankB = rankMap.get(b.move_type) ?? Number.MAX_SAFE_INTEGER
    if (rankA !== rankB) return rankA - rankB

    if (a.categoryName !== b.categoryName) return a.categoryName.localeCompare(b.categoryName)
    if ((a.categoryCode ?? '') !== (b.categoryCode ?? '')) {
      return (a.categoryCode ?? '').localeCompare(b.categoryCode ?? '')
    }
    return (a.abv ?? 0) - (b.abv ?? 0)
  })
}

export function calculateTaxAmount(
  moveType: string,
  volumeLiters: number | null | undefined,
  taxRate: number | null | undefined,
  taxEvent?: string | null,
) {
  return taxDirectionForMovement(moveType, taxEvent) * taxAmountFromLiters(volumeLiters, taxRate)
}

export function volumeMillilitersForItem(
  item: Pick<TaxVolumeItem, 'volume_l' | 'volume_ml'>,
) {
  if (Number.isFinite(item.volume_ml)) return Math.max(0, Math.round(Number(item.volume_ml)))
  return litersToMilliliters(item.volume_l) ?? 0
}

export function volumeLitersForItem(
  item: Pick<TaxVolumeItem, 'volume_l' | 'volume_ml'>,
) {
  return millilitersToLiters(volumeMillilitersForItem(item)) ?? 0
}

export function normalizeTaxEventValue(value: unknown) {
  if (typeof value !== 'string') return null
  const normalized = value.trim()
  return normalized ? normalized : null
}

export function legacyTaxEventForMoveType(moveType: string) {
  switch (moveType) {
    case 'sale':
      return 'TAXABLE_REMOVAL'
    case 'tax_transfer':
      return 'EXPORT_EXEMPT'
    case 'return':
      return 'RETURN_TO_FACTORY'
    case 'transfer':
    case 'waste':
      return 'NON_TAXABLE_REMOVAL'
    default:
      return null
  }
}

export function resolveTaxEvent(
  moveType: string,
  taxEvent?: unknown,
  taxDecisionCode?: unknown,
) {
  const resolvedTaxEvent = normalizeTaxEventValue(taxEvent)
  if (resolvedTaxEvent) return resolvedTaxEvent
  const resolvedTaxDecisionCode = normalizeTaxEventValue(taxDecisionCode)
  if (resolvedTaxDecisionCode) return resolvedTaxDecisionCode
  return legacyTaxEventForMoveType(moveType)
}

export function isTaxAffectingMoveType(value: string, taxEvent?: string | null) {
  return taxDirectionForMovement(value, taxEvent) !== 0
}

export function isReturnTaxEvent(moveType: string, taxEvent?: string | null) {
  return resolveTaxEvent(moveType, taxEvent) === 'RETURN_TO_FACTORY'
}

export function isGeneratedTaxVolumeItem(item: Pick<TaxVolumeItem, 'row_role'>) {
  const rowRole = item.row_role ?? 'detail'
  return rowRole !== 'detail'
}

export function isLia110DetailItem(item: TaxVolumeItem) {
  const taxEvent = resolveTaxEvent(item.move_type, item.tax_event)
  return (
    !isGeneratedTaxVolumeItem(item) &&
    isSummaryDocType(item.move_type) &&
    taxEvent !== 'RETURN_TO_FACTORY' &&
    !LIA110_EXCLUDED_TAX_EVENTS.has(taxEvent ?? '')
  )
}

export function lia110KubunCodeForItem(item: TaxVolumeItem) {
  if (Number.isFinite(item.kubun_code)) return Number(item.kubun_code)
  const rowRole = item.row_role ?? 'detail'
  if (rowRole === 'category_summary') return 8
  if (rowRole === 'grand_total') return 9

  const taxEvent = resolveTaxEvent(item.move_type, item.tax_event)
  if (taxEvent === 'TAXABLE_REMOVAL') return 1
  if (taxEvent === 'NON_TAXABLE_REMOVAL' || taxEvent === 'EXPORT_EXEMPT') return 0
  return 0
}

export function buildLia110ReportRows(items: TaxVolumeItem[]) {
  const detailRows = items
    .filter(isLia110DetailItem)
    .map((item) => createLia110DetailRow(item))
    .sort(compareLia110Rows)

  const categoryGroups = new Map<string, TaxVolumeItem[]>()
  detailRows.forEach((item) => {
    const key = categoryGroupKey(item)
    if (!categoryGroups.has(key)) categoryGroups.set(key, [])
    categoryGroups.get(key)?.push(item)
  })

  const rows: TaxVolumeItem[] = []
  let grandTaxableVolume = 0
  let grandTaxAmount = 0

  Array.from(categoryGroups.entries())
    .sort(([, leftRows], [, rightRows]) => compareCategoryRows(leftRows[0], rightRows[0]))
    .forEach(([categoryKey, categoryRows]) => {
      const kubunGroups = new Map<number, TaxVolumeItem[]>()
      categoryRows.forEach((item) => {
        const kubunCode = lia110KubunCodeForItem(item)
        if (!kubunGroups.has(kubunCode)) kubunGroups.set(kubunCode, [])
        kubunGroups.get(kubunCode)?.push(item)
      })

      let categoryTaxableVolume = 0
      let categoryTaxAmount = 0

      Array.from(kubunGroups.entries())
        .sort(([left], [right]) => left - right)
        .forEach(([kubunCode, groupRows]) => {
          groupRows.sort(compareLia110Rows)
          rows.push(...groupRows)
          const summaryRow = createKubunSummaryRow(categoryKey, kubunCode, groupRows)
          rows.push(summaryRow)
          categoryTaxableVolume += summaryRow.taxable_volume_l ?? 0
          categoryTaxAmount += summaryRow.tax_amount ?? 0
        })

      rows.push(createCategorySummaryRow(categoryKey, categoryRows[0], categoryTaxableVolume, categoryTaxAmount))
      grandTaxableVolume += categoryTaxableVolume
      grandTaxAmount += categoryTaxAmount
    })

  if (detailRows.length > 0) {
    rows.push(createGrandTotalRow(grandTaxableVolume, grandTaxAmount))
  }

  return rows
}

export function calculateTaxTotalAmount(
  items: Array<Pick<TaxVolumeItem, 'move_type' | 'tax_event' | 'volume_l' | 'tax_rate'>>,
) {
  return items.reduce(
    (sum, item) => sum + calculateTaxAmount(item.move_type, item.volume_l, item.tax_rate, item.tax_event),
    0,
  )
}

export function buildTaxReductionPreview(options: {
  breakdown: TaxVolumeItem[]
  priorFiscalYearStandardTaxAmount: number
}): RLI0010_232_ReductionTotals {
  const sourceBreakdown = options.breakdown.filter((item) => !isGeneratedTaxVolumeItem(item))
  const lia110DetailItems = sourceBreakdown.filter(isLia110DetailItem)
  const returnItems = sourceBreakdown.filter((item) => isReturnTaxEvent(item.move_type, item.tax_event))
  const currentMonthStandardTaxAmount = roundNonNegativeTax(calculateTaxTotalAmount(lia110DetailItems))
  const returnStandardTaxAmount = roundNonNegativeTax(Math.abs(calculateTaxTotalAmount(returnItems)))

  return buildLia130ReductionTotals({
    priorFiscalYearStandardTaxAmount: options.priorFiscalYearStandardTaxAmount,
    currentMonthStandardTaxAmount,
    returnStandardTaxAmount,
  })
}

export function priorFiscalYearReportPeriods(taxYear: number, taxMonth: number) {
  if (!Number.isFinite(taxYear) || !Number.isFinite(taxMonth) || taxMonth < 1 || taxMonth > 12) {
    return []
  }

  const startYear = taxMonth >= 4 ? taxYear : taxYear - 1
  const periods: Array<{ taxYear: number; taxMonth: number }> = []
  let year = startYear
  let month = 4

  while (year < taxYear || (year === taxYear && month < taxMonth)) {
    periods.push({ taxYear: year, taxMonth: month })
    month += 1
    if (month > 12) {
      month = 1
      year += 1
    }
  }

  return periods
}

export async function fetchPriorFiscalYearStandardTaxAmount(options: {
  supabase: SupabaseClient
  tenantId: string
  taxYear: number
  taxMonth: number
  excludeReportId?: string | null
}) {
  const { supabase, tenantId, taxYear, taxMonth, excludeReportId } = options
  const periods = priorFiscalYearReportPeriods(taxYear, taxMonth)
  if (periods.length === 0) return 0

  const years = Array.from(new Set(periods.map((period) => period.taxYear)))
  const periodKeys = new Set(periods.map((period) => `${period.taxYear}-${period.taxMonth}`))
  const { data, error } = await supabase
    .from('tax_reports')
    .select('id, tax_year, tax_month, total_tax_amount')
    .eq('tenant_id', tenantId)
    .eq('tax_type', 'monthly')
    .in('tax_year', years)

  if (error) throw error

  return (data ?? []).reduce((sum, row) => {
    if (excludeReportId && String(row.id) === excludeReportId) return sum
    const key = `${Number(row.tax_year)}-${Number(row.tax_month)}`
    if (!periodKeys.has(key)) return sum
    const amount = Number(row.total_tax_amount ?? 0)
    return Number.isFinite(amount) ? sum + amount : sum
  }, 0)
}

export function isSummaryDocType(value: string): value is (typeof SUMMARY_DOC_TYPES)[number] {
  return (SUMMARY_DOC_TYPES as readonly string[]).includes(value)
}

export function isDisposeDocType(value: string): value is (typeof DISPOSE_DOC_TYPES)[number] {
  return (DISPOSE_DOC_TYPES as readonly string[]).includes(value)
}

export function parseFileList(text: string) {
  return text
    .split(/[\n,]/)
    .map((entry) => entry.trim())
    .filter(Boolean)
}

export function buildXmlFilename(taxType: string, taxYear: number, taxMonth: number) {
  const reiwa = taxYear >= 2019 ? `R${taxYear - 2018}年` : `${taxYear}年`
  if (taxType === 'yearly') {
    return `${reiwa}_納税申告.xtx`
  }
  return `${reiwa}${taxMonth}月_納税申告.xtx`
}

export function buildDisposeXmlFilename(taxType: string, taxYear: number, taxMonth: number) {
  return buildXmlFilename(taxType, taxYear, taxMonth).replace('.xtx', '_廃棄.xtx')
}

export function buildTaxableRemovalExcelFilename(taxYear: number, taxMonth: number) {
  const reiwa = taxYear >= 2019 ? `R${taxYear - 2018}年` : `${taxYear}年`
  return `${reiwa}${taxMonth}月_課税移出一覧表.xlsx`
}

export function isDisposeFilename(
  filename: string,
  row: Pick<TaxReportRow, 'tax_type' | 'tax_year' | 'tax_month'>,
) {
  const expectedDisposeName = buildDisposeXmlFilename(row.tax_type, row.tax_year, row.tax_month)
  return filename === expectedDisposeName || filename.includes('廃棄')
}

export function normalizeReport(row: JsonMap): TaxReportRow {
  const attachments = Array.isArray(row.attachment_files) ? row.attachment_files : []
  const breakdown = Array.isArray(row.volume_breakdown) ? row.volume_breakdown : []
  const storedTotalTaxAmount = Number(row.total_tax_amount ?? 0)

  const normalizedBreakdown: TaxVolumeItem[] = breakdown
    .map((item: unknown, index: number) => {
      const record = item && typeof item === 'object' ? (item as JsonMap) : {}
      return {
        key: String(record.key ?? `${String(row.id ?? '')}-${index}`),
        move_type: String(record.move_type ?? record.moveType ?? record.doc_type ?? 'unknown'),
        tax_event: resolveTaxEvent(
          String(record.move_type ?? record.moveType ?? record.doc_type ?? 'unknown'),
          record.tax_event ?? record.taxEvent,
          record.tax_decision_code ?? record.taxDecisionCode,
        ),
        categoryId: String(record.categoryId ?? record.category_id ?? ''),
        categoryCode: String(record.categoryCode ?? record.category_code ?? ''),
        categoryName: String(record.categoryName ?? record.category_name ?? '—'),
        abv: typeof record.abv === 'number' ? record.abv : record.abv ? Number(record.abv) : null,
        volume_l:
          typeof record.volume_l === 'number'
            ? record.volume_l
            : record.volume_ml
              ? (millilitersToLiters(Number(record.volume_ml)) ?? 0)
              : Number(record.volume_l || 0),
        volume_ml:
          typeof record.volume_ml === 'number'
            ? record.volume_ml
            : record.volume_ml
              ? Number(record.volume_ml)
              : null,
        tax_rate:
          typeof record.tax_rate === 'number'
            ? record.tax_rate
            : record.tax_rate
              ? Number(record.tax_rate)
              : record.taxRate
                ? Number(record.taxRate)
                : null,
        export_date: toNullableString(record.export_date ?? record.exportDate),
        export_destination: toNullableString(record.export_destination ?? record.exportDestination),
        export_customs_office: toNullableString(record.export_customs_office ?? record.exportCustomsOffice),
        exporter_address: toNullableString(record.exporter_address ?? record.exporterAddress),
        exporter_name: toNullableString(record.exporter_name ?? record.exporterName),
        export_reference_notes: toNullableString(record.export_reference_notes ?? record.exportReferenceNotes),
      }
    })
    .filter((item) => item.categoryId || item.categoryName)
  if (
    normalizedBreakdown.length > 0 &&
    normalizedBreakdown.every((item) => item.tax_rate == null)
  ) {
    const totalVolume = normalizedBreakdown.reduce((sum, item) => {
      const sign = taxDirectionForMovement(item.move_type, item.tax_event)
      if (sign === 0) return sum
      return sum + sign * (item.volume_l || 0)
    }, 0)
    const fallbackRate =
      totalVolume !== 0 ? (storedTotalTaxAmount * 1000) / totalVolume : 0
    normalizedBreakdown.forEach((item) => {
      item.tax_rate = isTaxAffectingMoveType(item.move_type, item.tax_event) ? fallbackRate : 0
    })
  } else if (normalizedBreakdown.length > 0) {
    normalizeStoredBreakdownTaxRates(normalizedBreakdown, storedTotalTaxAmount)
  }

  const hasDerivedBreakdown = normalizedBreakdown.length > 0

  return {
    id: String(row.id ?? ''),
    tax_type: toNullableString(row.tax_type) ?? 'monthly',
    tax_year: Number(row.tax_year),
    tax_month: row.tax_month ? Number(row.tax_month) : 0,
    status: toNullableString(row.status) ?? 'draft',
    total_tax_amount: hasDerivedBreakdown
      ? calculateTaxTotalAmount(normalizedBreakdown)
      : storedTotalTaxAmount,
    volume_breakdown: normalizedBreakdown,
    report_files: normalizeStoredFiles(row.report_files),
    attachment_files: attachments.map((file: unknown) => String(file)),
    created_at: toNullableString(row.created_at),
  }
}

export function normalizeStoredFiles(value: unknown): TaxReportStoredFile[] {
  if (!Array.isArray(value)) return []

  return value
    .map((item) => normalizeStoredFile(item))
    .filter((item): item is TaxReportStoredFile => item !== null)
}

export function normalizeStoredFile(value: unknown): TaxReportStoredFile | null {
  if (typeof value === 'string') {
    const fileName = value.trim()
    if (!fileName) return null
    return {
      fileName,
      fileType: inferStoredFileType(fileName),
      mimeType: inferMimeType(fileName),
      storageBucket: null,
      storagePath: null,
      size: null,
      generatedAt: null,
    }
  }

  if (!value || typeof value !== 'object') return null
  const record = value as JsonMap
  const fileName = toNullableString(record.fileName ?? record.filename)
  if (!fileName) return null

  return {
    fileName,
    fileType: toNullableString(record.fileType) ?? inferStoredFileType(fileName),
    mimeType: toNullableString(record.mimeType) ?? inferMimeType(fileName),
    storageBucket: toNullableString(record.storageBucket),
    storagePath: toNullableString(record.storagePath),
    size: toNullableNumber(record.size),
    generatedAt: toNullableString(record.generatedAt),
  }
}

export function inferStoredFileType(fileName: string): TaxReportFileType {
  if (fileName.includes('未納税移出帳')) return 'non_taxable_removal_ledger_excel'
  if (fileName.includes('輸出免税帳')) return 'export_exempt_ledger_excel'
  if (fileName.includes('未納税移入帳')) return 'non_taxable_receipt_ledger_excel'
  if (fileName.includes('戻入帳')) return 'return_to_factory_ledger_excel'
  if (fileName.includes('課税移出一覧表') || fileName.toLowerCase().endsWith('.xlsx')) {
    return 'taxable_removal_excel'
  }
  if (fileName.includes('廃棄')) return 'tax_report_dispose_xml'
  if (fileName.toLowerCase().endsWith('.xtx') || fileName.toLowerCase().endsWith('.xml')) {
    return 'tax_report_xml'
  }
  return 'legacy'
}

export function inferMimeType(fileName: string) {
  const lower = fileName.toLowerCase()
  if (lower.endsWith('.xlsx')) {
    return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
  }
  if (lower.endsWith('.xtx') || lower.endsWith('.xml')) {
    return 'application/xml'
  }
  return 'application/octet-stream'
}

function createLia110DetailRow(item: TaxVolumeItem): TaxVolumeItem {
  const taxEvent = resolveTaxEvent(item.move_type, item.tax_event)
  const volume = finiteNumber(item.volume_l)
  const kubunCode = lia110KubunCodeForItem(item)
  return {
    ...item,
    row_role: 'detail',
    kubun_code: kubunCode,
    tax_event: taxEvent,
    non_taxable_volume_l: taxEvent === 'NON_TAXABLE_REMOVAL' ? volume : 0,
    export_exempt_volume_l: taxEvent === 'EXPORT_EXEMPT' ? volume : 0,
    taxable_volume_l: taxEvent === 'TAXABLE_REMOVAL' ? volume : 0,
    tax_amount: 0,
  }
}

function createLegacyDisposeLia110Row(item: TaxVolumeItem): TaxVolumeItem {
  const volume = finiteNumber(item.volume_l)
  return {
    ...item,
    row_role: 'detail',
    kubun_code: 9,
    non_taxable_volume_l: volume,
    export_exempt_volume_l: 0,
    taxable_volume_l: 0,
    tax_amount: 0,
  }
}

function createKubunSummaryRow(
  categoryKey: string,
  kubunCode: number,
  rows: TaxVolumeItem[],
): TaxVolumeItem {
  const first = rows[0]
  const totalVolume = sumNumbers(rows.map((item) => item.volume_l))
  const nonTaxableVolume = sumNumbers(rows.map((item) => item.non_taxable_volume_l))
  const exportExemptVolume = sumNumbers(rows.map((item) => item.export_exempt_volume_l))
  const taxableVolume = sumNumbers(rows.map((item) => item.taxable_volume_l))
  const taxAmount = sumNumbers(
    rows.map((item) => calculateTaxAmount(item.move_type, item.volume_l, item.tax_rate, item.tax_event)),
  )
  const basisVolume = taxableVolume > 0 ? taxableVolume : totalVolume

  return {
    key: `${categoryKey}-kubun-${kubunCode}-summary`,
    move_type: first?.move_type ?? 'summary',
    tax_event: kubunCode === 1 ? 'TAXABLE_REMOVAL' : null,
    categoryId: first?.categoryId ?? '',
    categoryCode: first?.categoryCode ?? '',
    categoryName: first?.categoryName ?? '—',
    abv: null,
    volume_l: kubunCode === 1 ? taxableVolume : totalVolume,
    tax_rate: effectiveTaxRate(rows, basisVolume, taxAmount),
    row_role: 'kubun_summary',
    kubun_code: kubunCode,
    non_taxable_volume_l: nonTaxableVolume,
    export_exempt_volume_l: exportExemptVolume,
    taxable_volume_l: taxableVolume,
    tax_amount: nonNegativeYen(taxAmount),
    volume_ml: litersToMilliliters(kubunCode === 1 ? taxableVolume : totalVolume),
  }
}

function createCategorySummaryRow(
  categoryKey: string,
  first: TaxVolumeItem | undefined,
  taxableVolume: number,
  taxAmount: number,
): TaxVolumeItem {
  return {
    key: `${categoryKey}-category-summary`,
    move_type: 'summary',
    tax_event: 'TAXABLE_REMOVAL',
    categoryId: first?.categoryId ?? '',
    categoryCode: first?.categoryCode ?? '',
    categoryName: first?.categoryName ?? '—',
    abv: null,
    volume_l: taxableVolume,
    tax_rate: null,
    row_role: 'category_summary',
    kubun_code: 8,
    non_taxable_volume_l: 0,
    export_exempt_volume_l: 0,
    taxable_volume_l: taxableVolume,
    tax_amount: nonNegativeYen(taxAmount),
    volume_ml: litersToMilliliters(taxableVolume),
  }
}

function createGrandTotalRow(taxableVolume: number, taxAmount: number): TaxVolumeItem {
  return {
    key: 'all-liquor-grand-total',
    move_type: 'summary',
    tax_event: 'TAXABLE_REMOVAL',
    categoryId: '__all__',
    categoryCode: '000',
    categoryName: '全酒類',
    abv: null,
    volume_l: taxableVolume,
    tax_rate: null,
    row_role: 'grand_total',
    kubun_code: 9,
    non_taxable_volume_l: 0,
    export_exempt_volume_l: 0,
    taxable_volume_l: taxableVolume,
    tax_amount: nonNegativeYen(taxAmount),
    volume_ml: litersToMilliliters(taxableVolume),
  }
}

function categoryGroupKey(item: TaxVolumeItem) {
  return `${item.categoryId || item.categoryCode || item.categoryName || 'unknown'}`
}

function compareLia110Rows(left: TaxVolumeItem, right: TaxVolumeItem) {
  const categoryResult = compareCategoryRows(left, right)
  if (categoryResult !== 0) return categoryResult

  const kubunResult = lia110KubunCodeForItem(left) - lia110KubunCodeForItem(right)
  if (kubunResult !== 0) return kubunResult

  const leftAbv = Number.isFinite(left.abv) ? Number(left.abv) : Number.NEGATIVE_INFINITY
  const rightAbv = Number.isFinite(right.abv) ? Number(right.abv) : Number.NEGATIVE_INFINITY
  if (leftAbv !== rightAbv) return rightAbv - leftAbv

  return String(left.tax_event ?? '').localeCompare(String(right.tax_event ?? ''))
}

function compareCategoryRows(left: TaxVolumeItem | undefined, right: TaxVolumeItem | undefined) {
  const leftCode = left?.categoryCode ?? ''
  const rightCode = right?.categoryCode ?? ''
  if (leftCode !== rightCode) return leftCode.localeCompare(rightCode)

  const leftName = left?.categoryName ?? ''
  const rightName = right?.categoryName ?? ''
  if (leftName !== rightName) return leftName.localeCompare(rightName)

  return (left?.categoryId ?? '').localeCompare(right?.categoryId ?? '')
}

function effectiveTaxRate(rows: TaxVolumeItem[], basisVolume: number, taxAmount: number) {
  if (basisVolume > 0 && taxAmount > 0) return (taxAmount * 1000) / basisVolume

  const weightedVolume = sumNumbers(rows.map((item) => item.volume_l))
  if (weightedVolume <= 0) return finiteNumber(rows.find((item) => Number.isFinite(item.tax_rate))?.tax_rate)

  const weightedRateTotal = sumNumbers(
    rows.map((item) => finiteNumber(item.tax_rate) * finiteNumber(item.volume_l)),
  )
  return weightedRateTotal / weightedVolume
}

function sumNumbers(values: Array<number | null | undefined>): number {
  return values.reduce<number>((sum, value) => sum + finiteNumber(value), 0)
}

function finiteNumber(value: number | null | undefined) {
  return Number.isFinite(value) ? Number(value) : 0
}

function buildLia130ReductionTotals(options: {
  priorFiscalYearStandardTaxAmount: number
  currentMonthStandardTaxAmount: number
  returnStandardTaxAmount: number
}): RLI0010_232_ReductionTotals {
  const priorFiscalYearStandardTaxAmount = roundNonNegativeTax(options.priorFiscalYearStandardTaxAmount)
  const currentMonthStandardTaxAmount = roundNonNegativeTax(options.currentMonthStandardTaxAmount)
  const returnStandardTaxAmount = roundNonNegativeTax(options.returnStandardTaxAmount)
  const netStandardTaxAmount = roundNonNegativeTax(currentMonthStandardTaxAmount - returnStandardTaxAmount)
  const cumulativeBeforeReturnStandardTaxAmount = roundNonNegativeTax(
    priorFiscalYearStandardTaxAmount + currentMonthStandardTaxAmount,
  )
  const cumulativeAfterReturnStandardTaxAmount = roundNonNegativeTax(
    cumulativeBeforeReturnStandardTaxAmount - returnStandardTaxAmount,
  )
  const currentMonthReducedTaxAmount = reducedTaxAmount(currentMonthStandardTaxAmount)
  const returnReducedTaxAmount = reducedTaxAmount(returnStandardTaxAmount)

  return {
    included: true,
    priorFiscalYearStandardTaxAmount,
    currentMonthStandardTaxAmount,
    currentMonthReducedTaxAmount,
    returnStandardTaxAmount,
    returnReducedTaxAmount,
    netStandardTaxAmount,
    netReducedTaxAmount: roundNonNegativeTax(currentMonthReducedTaxAmount - returnReducedTaxAmount),
    cumulativeBeforeReturnStandardTaxAmount,
    cumulativeAfterReturnStandardTaxAmount,
    category: LIA130_REDUCTION_CATEGORY,
    rate: LIA130_REDUCTION_RATE,
  }
}

function reducedTaxAmount(value: number) {
  return nonNegativeYen(roundNonNegativeTax(value) * LIA130_REDUCTION_RATE)
}

function roundNonNegativeTax(value: number) {
  return nonNegativeYen(Number.isFinite(value) ? value : 0)
}

export async function buildXmlPayload(options: {
  taxType: string
  taxYear: number
  taxMonth: number
  breakdown: TaxVolumeItem[]
  profile: TaxReportProfile
  tenantId: string
  tenantName: string
  priorFiscalYearStandardTaxAmount?: number
  includeLia130?: boolean
}) {
  const {
    taxType,
    taxYear,
    taxMonth,
    breakdown,
    profile,
    tenantId,
    tenantName,
    priorFiscalYearStandardTaxAmount = 0,
    includeLia130 = true,
  } = options
  if (taxType !== 'monthly') {
    throw new Error('UNSUPPORTED_TAX_TYPE')
  }
  const sourceBreakdown = breakdown.filter((item) => !isGeneratedTaxVolumeItem(item))
  const disposeOnly = sourceBreakdown.length > 0 && sourceBreakdown.every((item) => isDisposeDocType(item.move_type))
  const lia110DetailItems = sourceBreakdown.filter(isLia110DetailItem)
  const summaryItems = disposeOnly
    ? sourceBreakdown.map((item) => createLegacyDisposeLia110Row(item))
    : buildLia110ReportRows(lia110DetailItems)
  const returnItems = disposeOnly
    ? []
    : sourceBreakdown.filter((item) => isReturnTaxEvent(item.move_type, item.tax_event))
  const exportExemptItems = disposeOnly
    ? []
    : sourceBreakdown.filter((item) => resolveTaxEvent(item.move_type, item.tax_event) === 'EXPORT_EXEMPT')
  const currentMonthStandardTaxAmount = roundNonNegativeTax(calculateTaxTotalAmount(lia110DetailItems))
  const returnStandardTaxAmount = roundNonNegativeTax(Math.abs(calculateTaxTotalAmount(returnItems)))
  const rawNetStandardTaxAmount = currentMonthStandardTaxAmount - returnStandardTaxAmount
  const netStandardTaxAmount = roundNonNegativeTax(rawNetStandardTaxAmount)
  const rawTotalTaxAmount = disposeOnly ? calculateTaxTotalAmount(sourceBreakdown) : rawNetStandardTaxAmount
  const reduction = !disposeOnly && includeLia130
    ? buildLia130ReductionTotals({
        priorFiscalYearStandardTaxAmount,
        currentMonthStandardTaxAmount,
        returnStandardTaxAmount,
      })
    : undefined
  const totalTaxAmount = reduction?.netReducedTaxAmount ?? nonNegativeYen(rawTotalTaxAmount)
  const roundedDownAmount = totalTaxAmount > 0 ? totalTaxAmount % 100 : 0
  const payableTaxAmount = Math.max(0, totalTaxAmount - roundedDownAmount)
  const refundableTaxAmount = Math.max(0, truncateYen(rawTotalTaxAmount < 0 ? Math.abs(rawTotalTaxAmount) : 0))
  const generatedAt = new Date().toISOString()

  const result = await generateRLI0010_232({
    input: {
      report: {
        taxType: 'monthly',
        taxYear,
        taxMonth,
        generatedAt,
      },
      tenant: {
        tenantId,
        tenantName,
      },
      profile,
      totals: {
        currentMonthStandardTaxAmount,
        returnStandardTaxAmount,
        netStandardTaxAmount,
        totalTaxAmount,
        refundableTaxAmount,
        roundedDownAmount,
        payableTaxAmount,
        netPayableTaxAmount: payableTaxAmount,
        reduction,
      },
      breakdown: {
        summary: summaryItems,
        returns: returnItems,
        exportExempt: exportExemptItems,
      },
      attachments: [],
    },
  })

  return result.xml
}

export async function uploadGeneratedTaxReportFiles(options: {
  supabase: SupabaseClient
  files: GeneratedTaxReportFile[]
  reportId: string
  tenantId: string
}) {
  const { supabase, files, reportId, tenantId } = options
  const uploaded: TaxReportStoredFile[] = []

  try {
    for (const file of files) {
      const storagePath = buildStoragePath(tenantId, reportId, file.fileType, file.fileName)
      const { error } = await supabase.storage
        .from(DEFAULT_BUCKET)
        .upload(storagePath, file.blob, {
          contentType: file.mimeType,
          upsert: true,
        })
      if (error) throw error

      uploaded.push({
        fileName: file.fileName,
        fileType: file.fileType,
        mimeType: file.mimeType,
        storageBucket: DEFAULT_BUCKET,
        storagePath,
        size: file.blob.size,
        generatedAt: file.generatedAt,
      })
    }
  } catch (err) {
    await removeStoredTaxReportFiles({ supabase, files: uploaded })
    throw err
  }

  return uploaded
}

export async function downloadStoredTaxReportFile(options: {
  supabase: SupabaseClient
  file: TaxReportStoredFile
}) {
  const { supabase, file } = options
  if (!file.storageBucket || !file.storagePath) {
    throw new Error('FILE_NOT_IN_STORAGE')
  }
  const { data, error } = await supabase.storage.from(file.storageBucket).download(file.storagePath)
  if (error) throw error
  return data
}

export async function removeStoredTaxReportFiles(options: {
  supabase: SupabaseClient
  files: TaxReportStoredFile[]
}) {
  const { supabase, files } = options
  const filesByBucket = new Map<string, string[]>()

  files.forEach((file) => {
    if (!file.storageBucket || !file.storagePath) return
    if (!filesByBucket.has(file.storageBucket)) {
      filesByBucket.set(file.storageBucket, [])
    }
    filesByBucket.get(file.storageBucket)?.push(file.storagePath)
  })

  for (const [bucket, paths] of filesByBucket.entries()) {
    if (!paths.length) continue
    await supabase.storage.from(bucket).remove(paths)
  }
}

export function mergeStoredFiles(
  existing: TaxReportStoredFile[],
  replacements: TaxReportStoredFile[],
) {
  const byType = new Map<string, TaxReportStoredFile>()
  existing.forEach((file) => {
    byType.set(String(file.fileType || file.fileName), file)
  })
  replacements.forEach((file) => {
    byType.set(String(file.fileType || file.fileName), file)
  })
  return Array.from(byType.values()).sort((a, b) => a.fileName.localeCompare(b.fileName))
}

function buildStoragePath(
  tenantId: string,
  reportId: string,
  fileType: string,
  fileName: string,
) {
  return [
    'tenant',
    sanitizePathSegment(tenantId),
    'tax_reports',
    sanitizePathSegment(reportId),
    sanitizePathSegment(fileType),
    sanitizeFileName(fileName),
  ].join('__')
}

function sanitizePathSegment(value: string) {
  return value.normalize('NFKC').replace(/[^a-zA-Z0-9_-]/g, '_')
}

function sanitizeFileName(value: string) {
  return value
    .normalize('NFKC')
    .replace(/\s+/g, '_')
    .replace(/[^a-zA-Z0-9._-]/g, '_')
}

function toNullableString(value: unknown) {
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  return trimmed ? trimmed : null
}

function toNullableNumber(value: unknown) {
  if (value == null || value === '') return null
  const numeric = Number(value)
  return Number.isFinite(numeric) ? numeric : null
}

function taxDirectionForMovement(moveType: string, taxEvent?: string | null) {
  if (!isSummaryDocType(moveType)) return 0

  switch (resolveTaxEvent(moveType, taxEvent)) {
    case 'TAXABLE_REMOVAL':
      return 1
    case 'RETURN_TO_FACTORY':
      return -1
    default:
      return 0
  }
}

function normalizeStoredBreakdownTaxRates(
  items: TaxVolumeItem[],
  storedTotalTaxAmount: number,
) {
  if (!Number.isFinite(storedTotalTaxAmount) || storedTotalTaxAmount === 0) return

  const derivedTotal = calculateTaxTotalAmount(items)
  if (!Number.isFinite(derivedTotal) || derivedTotal === 0) return
  if (isApproximatelyEqual(derivedTotal, storedTotalTaxAmount)) return

  const scaledDownItems = items.map((item) => ({
    ...item,
    tax_rate: Number.isFinite(item.tax_rate) ? Number(item.tax_rate) / 1000 : item.tax_rate,
  }))
  const scaledDownTotal = calculateTaxTotalAmount(scaledDownItems)

  if (!isApproximatelyEqual(scaledDownTotal, storedTotalTaxAmount)) return

  items.forEach((item) => {
    if (!Number.isFinite(item.tax_rate)) return
    item.tax_rate = Number(item.tax_rate) / 1000
  })
}

function isApproximatelyEqual(left: number, right: number) {
  const tolerance = Math.max(1, Math.abs(right) * 0.01)
  return Math.abs(left - right) <= tolerance
}
