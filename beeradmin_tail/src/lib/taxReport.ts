import type { SupabaseClient } from '@supabase/supabase-js'

export type JsonMap = Record<string, unknown>

export type TaxReportFileType =
  | 'tax_report_xml'
  | 'tax_report_dispose_xml'
  | 'taxable_removal_excel'
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
  tax_rate: number | null
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
  'NONE',
  'unknown',
] as const

export function summaryItemsFromBreakdown(items: TaxVolumeItem[]) {
  return items.filter((item) => isSummaryDocType(item.move_type))
}

export function disposeItemsFromBreakdown(items: TaxVolumeItem[]) {
  return items.filter((item) => isDisposeDocType(item.move_type))
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
  const volume = Number.isFinite(volumeLiters) ? Number(volumeLiters) : 0
  const rate = Number.isFinite(taxRate) ? Number(taxRate) : 0
  const taxableKl = volume / 1000
  return taxDirectionForMovement(moveType, taxEvent) * taxableKl * rate
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

export function calculateTaxTotalAmount(
  items: Array<Pick<TaxVolumeItem, 'move_type' | 'tax_event' | 'volume_l' | 'tax_rate'>>,
) {
  return items.reduce(
    (sum, item) => sum + calculateTaxAmount(item.move_type, item.volume_l, item.tax_rate, item.tax_event),
    0,
  )
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
          typeof record.volume_l === 'number' ? record.volume_l : Number(record.volume_l || 0),
        tax_rate:
          typeof record.tax_rate === 'number'
            ? record.tax_rate
            : record.tax_rate
              ? Number(record.tax_rate)
              : record.taxRate
                ? Number(record.taxRate)
                : null,
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

export function buildXmlPayload(options: {
  templateXml: string
  movementTypeLabel: (value: string) => string
  taxType: string
  taxYear: number
  taxMonth: number
  breakdown: TaxVolumeItem[]
}) {
  const { templateXml, movementTypeLabel, taxType, taxYear, taxMonth, breakdown } = options
  if (!templateXml) {
    throw new Error('TEMPLATE_NOT_LOADED')
  }

  const { era, yy } = reiwaYear(taxYear)
  const mm = taxType === 'monthly' ? taxMonth : 12
  const dateStr = new Date().toISOString().slice(0, 10)

  const taxableItems = breakdown.filter((item) => !isReturnTaxEvent(item.move_type, item.tax_event))
  const returnItems = breakdown.filter((item) => isReturnTaxEvent(item.move_type, item.tax_event))

  const ehdBlocks = taxableItems
    .map((item) => {
      const categoryCode = resolveCategoryCode(item)
      const abvTag =
        item.abv != null ? `\n                    <EHD00040>${item.abv}</EHD00040>` : ''
      const volume = formatXmlVolume(item.volume_l)
      return `                <EHD00000>
                    <EHD00010>
                        <kubun_CD>${kubunCodeForMoveType(item.move_type)}</kubun_CD>
                    </EHD00010>
                    <EHD00020>${categoryCode}</EHD00020>
                    <EHD00030>${xmlEscape(item.categoryName)}</EHD00030>${abvTag}
                    <EHD00050>${volume}</EHD00050>
                    <EHD00080 AutoCalc="1">${volume}</EHD00080>
                    <EHD00100 AutoCalc="1">0</EHD00100>
                </EHD00000>`
    })
    .join('\n')

  const ekdBlocks = returnItems
    .map((item) => {
      const categoryCode = resolveCategoryCode(item)
      const abvTag =
        item.abv != null ? `\n                    <EKD00040>${item.abv}</EKD00040>` : ''
      const volume = formatXmlVolume(item.volume_l)
      return `                <EKD00000>
                    <EKD00010>
                        <kubun_CD>1</kubun_CD>
                    </EKD00010>
                    <EKD00020>${categoryCode}</EKD00020>
                    <EKD00030>${xmlEscape(item.categoryName)}</EKD00030>${abvTag}
                    <EKD00080>${volume}</EKD00080>
                    <EKD00100 AutoCalc="1">0</EKD00100>
                    <EKD00120>${xmlEscape(movementTypeLabel(item.move_type))}</EKD00120>
                </EKD00000>`
    })
    .join('\n')

  let xml = templateXml

  xml = xml.replace(/sakuseiDay="\d{4}-\d{2}-\d{2}"/g, `sakuseiDay="${dateStr}"`)
  xml = xml.replace(/<gen:era>\d+<\/gen:era>/g, `<gen:era>${era}</gen:era>`)
  xml = xml.replace(/<gen:yy>\d+<\/gen:yy>/g, `<gen:yy>${yy}</gen:yy>`)
  xml = xml.replace(/<gen:mm>\d+<\/gen:mm>/g, `<gen:mm>${mm}</gen:mm>`)

  xml = xml.replace(/<LIA110[\s\S]*?<\/LIA110>/, (section) => {
    let updated = section.replace(/<EHD00000>[\s\S]*?<\/EHD00000>/g, '')
    updated = updated.replace(/(<EHC00000>[\s\S]*?<\/EHC00000>)/, `$1\n${ehdBlocks}`)
    return updated
  })

  xml = xml.replace(/<LIA220[\s\S]*?<\/LIA220>/, (section) => {
    let updated = section.replace(/<EKD00000>[\s\S]*?<\/EKD00000>/g, '')
    updated = updated.replace(/(<EKC00000>[\s\S]*?<\/EKC00000>)/, `$1\n${ekdBlocks}`)
    return updated
  })

  return xml
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

function reiwaYear(year: number) {
  if (year >= 2019) return { era: 5, yy: year - 2018 }
  if (year >= 1989) return { era: 4, yy: year - 1988 }
  return { era: 3, yy: year }
}

function formatXmlVolume(value: number) {
  if (!Number.isFinite(value)) return '0'
  return String(Math.round(value * 1000))
}

function resolveCategoryCode(item: TaxVolumeItem) {
  if (item.categoryCode && /^\d+$/.test(item.categoryCode)) return item.categoryCode
  return '000'
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

function kubunCodeForMoveType(moveType: string, fallback = '1') {
  switch (moveType) {
    case 'sale':
      return '1'
    case 'tax_transfer':
      return '2'
    case 'transfer':
      return '3'
    case 'waste':
      return '4'
    default:
      return fallback
  }
}

function xmlEscape(value: string) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')
}
