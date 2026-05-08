import type { SupabaseClient } from '@supabase/supabase-js'
import {
  buildAlcoholTypeLabelMap,
  loadAlcoholTypeReferenceData,
  resolveAlcoholTypeLabel as resolveAlcoholTypeRegistryLabel,
} from '@/lib/alcoholTypeRegistry'
import {
  resolveBatchBeerCategoryId,
  resolveBatchDisplayName,
  resolveBatchTargetAbv,
} from '@/lib/batchRecipeSnapshot'
import { formatAbvPercent } from '@/lib/abvFormat'
import { createWorkbookBlob, type WorkbookCell, type WorkbookCellValue, type WorkbookSheet } from '@/lib/fillingReportExport'
import { formatTotalVolumeFromMilliliters, quantityToMilliliters } from '@/lib/volumeFormat'

type JsonMap = Record<string, unknown>

type MovementHeaderRow = {
  id: string
  doc_no: string | null
  movement_at: string | null
  status: string | null
  src_site_id: string | null
  dest_site_id: string | null
  notes: string | null
  meta: JsonMap | null
}

type MovementLineRow = {
  id: string
  movement_id: string
  line_no: number | null
  package_id: string | null
  batch_id: string | null
  qty: number | string | null
  unit: number | string | null
  tax_rate: number | string | null
  uom_id: string | null
  notes: string | null
  meta: JsonMap | null
}

type PackageRow = {
  id: string
  package_code: string | null
  name_i18n: Record<string, string> | null
  unit_volume: number | string | null
  volume_uom: string | null
  is_active: boolean | null
}

type SiteRow = {
  id: string
  name: string | null
  address: JsonMap | string | null
  site_type_id: string | null
}

type SiteInfo = SiteRow & {
  siteTypeCode: string | null
  siteTypeLabel: string | null
}

type SiteTypeRow = {
  def_id: string
  def_key: string | null
  spec: JsonMap | null
}

type UomLookupRow = {
  id: string
  code: string
}

type AlcoholTypeRegistryRow = {
  def_id: string
  def_key: string | null
  spec: JsonMap | null
}

type AttrDefRow = {
  attr_id: number | string
  code: string | null
}

type EntityAttrRow = {
  entity_id: string | null
  attr_id: number | string | null
  value_text: string | null
  value_num: number | string | null
  value_ref_type_id: string | number | null
  value_json: JsonMap | null
}

type BatchRow = {
  id: string
  batch_code: string | null
  batch_label: string | null
  product_name: string | null
  meta: JsonMap | null
  mes_recipe_id: string | null
  released_reference_json: JsonMap | null
  recipe_json: JsonMap | null
}

type LotRow = {
  id: string
  lot_no: string | null
}

type BatchInfo = {
  batchCode: string | null
  brandName: string | null
  liquorCode: string | null
  abv: number | null
}

export type TaxLedgerKey =
  | 'nonTaxableRemoval'
  | 'exportExempt'
  | 'nonTaxableReceipt'
  | 'returnToFactory'

export type TaxLedgerColumnKey =
  | 'movementAt'
  | 'item'
  | 'brand'
  | 'abv'
  | 'container'
  | 'packageCount'
  | 'quantityMl'
  | 'taxRate'
  | 'sourceAddress'
  | 'sourceName'
  | 'destinationAddress'
  | 'destinationName'
  | 'recipientAddress'
  | 'location'
  | 'exporterAddress'
  | 'exportDestinationAddress'
  | 'exportDestinationName'
  | 'transferorAddress'
  | 'deliveryAddress'
  | 'lotNo'
  | 'notes'

type LocalizedText = {
  ja: string
  en: string
}

type TaxLedgerSheetConfig = {
  name: string
  siteRole?: 'source' | 'destination' | 'all'
  match?: string[]
}

export type TaxLedgerReportConfig = {
  key: TaxLedgerKey
  sourceEvent: string
  title: LocalizedText
  subtitle: LocalizedText
  fileStem: string
  eventLabel: LocalizedText
  detailColumns: TaxLedgerColumnKey[]
  workbookSheets: TaxLedgerSheetConfig[]
}

export type TaxLedgerDetailRow = {
  id: string
  movementId: string
  lineNo: number
  movementAt: string | null
  sourceEvent: string | null
  liquorCode: string | null
  itemLabel: string | null
  brandName: string | null
  abv: number | null
  containerLabel: string | null
  quantityMl: number | null
  packageCount: number | null
  taxRate: number | null
  sourceSiteName: string | null
  sourceSiteAddress: string | null
  sourceSiteTypeCode: string | null
  sourceSiteTypeLabel: string | null
  destinationSiteName: string | null
  destinationSiteAddress: string | null
  destinationSiteTypeCode: string | null
  destinationSiteTypeLabel: string | null
  lotNo: string | null
  notes: string | null
}

export type TaxLedgerSummaryRow = {
  key: string
  liquorCode: string | null
  liquorCodeLabel: string | null
  abv: number | null
  quantityMl: number
  packageCount: number
}

export type TaxLedgerExportLabels = {
  generatedAt: string
  businessYear: string
  columns: Record<TaxLedgerColumnKey, string> & {
    containerType: string
  }
}

export const TAX_LEDGER_CONFIGS: Record<TaxLedgerKey, TaxLedgerReportConfig> = {
  nonTaxableRemoval: {
    key: 'nonTaxableRemoval',
    sourceEvent: 'NON_TAXABLE_REMOVAL',
    title: { ja: '未納税移出帳', en: 'Non-taxable Removal Ledger' },
    subtitle: {
      ja: '未納税移出の記録を年度サマリーと明細で確認します。',
      en: 'Review non-taxable removal records with business-year summary and details.',
    },
    fileStem: '未納税移出帳',
    eventLabel: { ja: '未納税移出', en: 'Non-taxable removal' },
    detailColumns: [
      'movementAt',
      'item',
      'brand',
      'abv',
      'container',
      'packageCount',
      'quantityMl',
      'taxRate',
      'recipientAddress',
      'destinationAddress',
      'lotNo',
      'notes',
    ],
    workbookSheets: [
      { name: '製造場', siteRole: 'source', match: ['BREWERY_MANUFACTUR', '製造場'] },
      { name: '蔵置場', siteRole: 'source', match: ['BREWERY_STORAGE', 'TAX_STORAGE', '蔵置場'] },
    ],
  },
  exportExempt: {
    key: 'exportExempt',
    sourceEvent: 'EXPORT_EXEMPT',
    title: { ja: '輸出免税帳', en: 'Export Exemption Ledger' },
    subtitle: {
      ja: '輸出免税の記録を年度サマリーと明細で確認します。',
      en: 'Review export-exempt records with business-year summary and details.',
    },
    fileStem: '輸出免税帳',
    eventLabel: { ja: '輸出免税', en: 'Export exempt' },
    detailColumns: [
      'movementAt',
      'item',
      'brand',
      'abv',
      'container',
      'packageCount',
      'quantityMl',
      'taxRate',
      'exporterAddress',
      'exportDestinationAddress',
      'exportDestinationName',
      'lotNo',
      'notes',
    ],
    workbookSheets: [{ name: '輸出免税帳', siteRole: 'all' }],
  },
  nonTaxableReceipt: {
    key: 'nonTaxableReceipt',
    sourceEvent: 'RETURN_TO_FACTORY_NON_TAXABLE',
    title: { ja: '未納税移入帳', en: 'Non-taxable Receipt Ledger' },
    subtitle: {
      ja: '未納税移入の記録を年度サマリーと明細で確認します。',
      en: 'Review non-taxable receipt records with business-year summary and details.',
    },
    fileStem: '未納税移入帳',
    eventLabel: { ja: '未納税移入', en: 'Non-taxable receipt' },
    detailColumns: [
      'movementAt',
      'item',
      'brand',
      'abv',
      'container',
      'packageCount',
      'quantityMl',
      'taxRate',
      'location',
      'lotNo',
      'notes',
    ],
    workbookSheets: [
      { name: '蔵置場', siteRole: 'destination', match: ['BREWERY_STORAGE', 'TAX_STORAGE', '蔵置場'] },
      { name: '製造場', siteRole: 'destination', match: ['BREWERY_MANUFACTUR', '製造場'] },
    ],
  },
  returnToFactory: {
    key: 'returnToFactory',
    sourceEvent: 'RETURN_TO_FACTORY',
    title: { ja: '戻入帳', en: 'Return Ledger' },
    subtitle: {
      ja: '戻入の記録を年度サマリーと明細で確認します。',
      en: 'Review return-to-factory records with business-year summary and details.',
    },
    fileStem: '戻入帳',
    eventLabel: { ja: '戻入', en: 'Return to factory' },
    detailColumns: [
      'movementAt',
      'item',
      'abv',
      'brand',
      'container',
      'packageCount',
      'quantityMl',
      'taxRate',
      'transferorAddress',
      'deliveryAddress',
      'lotNo',
      'notes',
    ],
    workbookSheets: [{ name: '戻入帳', siteRole: 'all' }],
  },
}

export function getTaxLedgerConfig(key: string | null | undefined) {
  if (key && key in TAX_LEDGER_CONFIGS) return TAX_LEDGER_CONFIGS[key as TaxLedgerKey]
  return TAX_LEDGER_CONFIGS.nonTaxableRemoval
}

export function localizedText(value: LocalizedText, locale: string) {
  return locale.toLowerCase().startsWith('ja') ? value.ja : value.en
}

export function getCurrentBusinessYear(date = new Date()) {
  return date.getMonth() + 1 >= 4 ? date.getFullYear() : date.getFullYear() - 1
}

export function businessYearForDate(value: string | null | undefined) {
  const date = safeDate(value)
  if (!date) return null
  return date.getMonth() + 1 >= 4 ? date.getFullYear() : date.getFullYear() - 1
}

export function matchesBusinessYear(value: string | null | undefined, businessYear: number) {
  return businessYearForDate(value) === businessYear
}

export function compareTaxLedgerDetailRows(a: TaxLedgerDetailRow, b: TaxLedgerDetailRow) {
  const aTime = a.movementAt ? Date.parse(a.movementAt) : 0
  const bTime = b.movementAt ? Date.parse(b.movementAt) : 0
  if (aTime !== bTime) return bTime - aTime
  const movementCompare = a.movementId.localeCompare(b.movementId)
  if (movementCompare !== 0) return movementCompare
  return a.lineNo - b.lineNo
}

export function extractErrorMessage(err: unknown) {
  if (!err) return ''
  if (typeof err === 'string') return err
  if (err instanceof Error) return err.message
  const record = err as Record<string, unknown>
  return typeof record.message === 'string' ? record.message : ''
}

export function buildTaxLedgerSummaryRows(
  detailRows: TaxLedgerDetailRow[],
  businessYear: number,
) {
  const map = new Map<string, TaxLedgerSummaryRow>()

  detailRows
    .filter((row) => matchesBusinessYear(row.movementAt, businessYear))
    .forEach((row) => {
      const abvKey = row.abv == null ? '' : String(row.abv)
      const key = `${row.liquorCode ?? ''}__${abvKey}`
      if (!map.has(key)) {
        map.set(key, {
          key,
          liquorCode: row.liquorCode,
          liquorCodeLabel: row.itemLabel ?? row.liquorCode ?? null,
          abv: row.abv,
          quantityMl: 0,
          packageCount: 0,
        })
      }

      const entry = map.get(key)
      if (!entry) return
      entry.quantityMl += row.quantityMl ?? 0
      entry.packageCount += row.packageCount ?? 0
    })

  return Array.from(map.values()).sort((a, b) => {
    const labelCompare = (a.liquorCodeLabel ?? a.liquorCode ?? '').localeCompare(
      b.liquorCodeLabel ?? b.liquorCode ?? '',
    )
    if (labelCompare !== 0) return labelCompare
    const codeCompare = (a.liquorCode ?? '').localeCompare(b.liquorCode ?? '')
    if (codeCompare !== 0) return codeCompare
    return (a.abv ?? 0) - (b.abv ?? 0)
  })
}

export function buildTaxLedgerBusinessYearFileName(config: TaxLedgerReportConfig, businessYear: number) {
  return `${config.fileStem}_${businessYear}.xlsx`
}

export function createTaxLedgerBusinessYearWorkbookBlob(options: {
  detailRows: TaxLedgerDetailRow[]
  businessYear: number
  config: TaxLedgerReportConfig
  labels: TaxLedgerExportLabels
  locale: string
  createdAt: Date
  creator?: string
}) {
  const { detailRows, businessYear, config, labels, locale, createdAt, creator } = options
  const createdAtLabel = createdAt.toLocaleString(locale)
  const businessYearRows = detailRows
    .filter((row) => matchesBusinessYear(row.movementAt, businessYear))
    .slice()
    .sort(compareTaxLedgerDetailRows)
  const sheets = buildWorkbookSheets({
    businessYearRows,
    businessYear,
    config,
    labels,
    locale,
    createdAtLabel,
  })

  return createWorkbookBlob({
    creator: creator ?? 'beeradmin_tail',
    createdAtIso: createdAt.toISOString(),
    sheets,
  })
}

export async function loadTaxLedgerDetailRows(options: {
  supabase: SupabaseClient
  tenantId: string
  locale: string
  config: TaxLedgerReportConfig
}) {
  const { supabase, tenantId, locale, config } = options
  const [uomMap, siteMap, packageMap, alcoholTypeLabelMap] = await Promise.all([
    loadUoms(supabase),
    loadSites(supabase, tenantId, locale),
    loadPackages(supabase, tenantId),
    loadAlcoholTypes(supabase),
  ])

  const { data: headerData, error: headerError } = await supabase
    .from('inv_movements')
    .select('id, doc_no, movement_at, status, src_site_id, dest_site_id, notes, meta')
    .eq('tenant_id', tenantId)
    .neq('status', 'void')
    .order('movement_at', { ascending: false })

  if (headerError) throw headerError

  const headers = (headerData ?? []) as MovementHeaderRow[]
  if (headers.length === 0) return []

  const headerMap = new Map(headers.map((row) => [row.id, row]))
  const movementIds = headers.map((row) => row.id)
  const { data: lineData, error: lineError } = await supabase
    .from('inv_movement_lines')
    .select('id, movement_id, line_no, package_id, batch_id, qty, unit, tax_rate, uom_id, notes, meta')
    .in('movement_id', movementIds)
    .order('line_no', { ascending: true })

  if (lineError) throw lineError

  const lines = (lineData ?? []) as MovementLineRow[]
  const batchIds = lines.map((line) => line.batch_id).filter((value): value is string => !!value)
  const lotIds = lines
    .map((line) => resolveLineLotId(line))
    .filter((value): value is string => !!value)

  const [batchInfoMap, lotInfoMap] = await Promise.all([
    loadBatchInfo(supabase, tenantId, batchIds),
    loadLotInfo(supabase, tenantId, lotIds),
  ])

  return lines
    .map<TaxLedgerDetailRow | null>((line) => {
      const header = headerMap.get(line.movement_id)
      if (!header) return null
      const sourceEvent = resolveSourceEvent(header, line)
      if (sourceEvent !== config.sourceEvent) return null

      const pkg = line.package_id ? packageMap.get(line.package_id) : undefined
      const batchInfo = line.batch_id ? batchInfoMap.get(line.batch_id) : undefined
      const sourceSite = header.src_site_id ? siteMap.get(header.src_site_id) : undefined
      const destinationSite = header.dest_site_id ? siteMap.get(header.dest_site_id) : undefined
      const liquorCode = resolveLineLiquorCode(line, header, batchInfo)
      const itemLabel = resolveAlcoholTypeLabel(alcoholTypeLabelMap, liquorCode)
      const quantityMl = lineQuantityMl(line, pkg, uomMap)
      const packageCount = linePackageCount(line)
      const taxRate = taxRateForLine(line, header)
      const lotId = resolveLineLotId(line)
      const lotNo = (lotId ? lotInfoMap.get(lotId) : '') || batchInfo?.batchCode || null

      return {
        id: line.id,
        movementId: line.movement_id,
        lineNo: line.line_no ?? 0,
        movementAt: header.movement_at ?? null,
        sourceEvent,
        liquorCode: liquorCode ?? null,
        itemLabel: itemLabel ?? liquorCode ?? null,
        brandName: batchInfo?.brandName ?? null,
        abv: resolveLineAbv(line, header, batchInfo),
        containerLabel: packageLabel(pkg, locale) || null,
        quantityMl,
        packageCount,
        taxRate,
        sourceSiteName: sourceSite?.name ?? null,
        sourceSiteAddress: formatAddress(sourceSite?.address) || null,
        sourceSiteTypeCode: sourceSite?.siteTypeCode ?? null,
        sourceSiteTypeLabel: sourceSite?.siteTypeLabel ?? null,
        destinationSiteName: destinationSite?.name ?? null,
        destinationSiteAddress: formatAddress(destinationSite?.address) || null,
        destinationSiteTypeCode: destinationSite?.siteTypeCode ?? null,
        destinationSiteTypeLabel: destinationSite?.siteTypeLabel ?? null,
        lotNo,
        notes:
          (line.notes && line.notes.trim()) ||
          resolveMetaString(line.meta, 'line_note') ||
          (header.notes && header.notes.trim()) ||
          null,
      }
    })
    .filter((row): row is TaxLedgerDetailRow => row !== null)
    .sort(compareTaxLedgerDetailRows)
}

function safeDate(value: string | null | undefined) {
  if (!value) return null
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
}

function toNumber(value: unknown): number | null {
  if (value == null) return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function resolveMetaString(meta: JsonMap | null | undefined, key: string) {
  const value = meta?.[key]
  return typeof value === 'string' && value.trim() ? value.trim() : null
}

function resolveMetaNumber(meta: JsonMap | null | undefined, key: string) {
  return toNumber(meta?.[key])
}

function resolveLocalizedName(value: Record<string, string> | null | undefined, locale: string) {
  if (!value) return ''
  const exact = value[locale]
  if (typeof exact === 'string' && exact.trim()) return exact.trim()
  const fallback = Object.values(value).find((entry) => typeof entry === 'string' && entry.trim())
  return typeof fallback === 'string' ? fallback.trim() : ''
}

function localizedSpecText(spec: JsonMap | null | undefined, locale: string) {
  if (!spec) return ''
  const name = spec.name
  if (typeof name === 'string' && name.trim()) return name.trim()
  if (typeof name === 'object' && name !== null) {
    const text = resolveLocalizedName(name as Record<string, string>, locale)
    if (text) return text
  }
  const label = spec.label
  if (typeof label === 'string' && label.trim()) return label.trim()
  if (typeof label === 'object' && label !== null) {
    const text = resolveLocalizedName(label as Record<string, string>, locale)
    if (text) return text
  }
  return ''
}

function convertToLiters(quantity: number | null, uomCode: string | null | undefined) {
  const milliliters = quantityToMilliliters(quantity, uomCode)
  return milliliters == null ? null : milliliters / 1000
}

function quantityMlFromLiters(quantityLiters: number | null) {
  if (quantityLiters == null) return null
  return quantityToMilliliters(quantityLiters, 'L')
}

function formatNumberValue(value: number | null | undefined, locale: string, digits = 0) {
  if (value == null || Number.isNaN(value)) return '—'
  return new Intl.NumberFormat(locale, {
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  }).format(value)
}

function formatAbv(value: number | null | undefined, locale: string) {
  return formatAbvPercent(value, locale)
}

function formatQuantityMl(value: number | null | undefined, locale: string) {
  return formatTotalVolumeFromMilliliters(value, locale)
}

function formatTaxRate(value: number | null | undefined, locale: string) {
  if (value == null || Number.isNaN(value)) return '—'
  return `${formatNumberValue(value, locale)}/kl`
}

function formatDate(value: string | null | undefined, locale: string) {
  if (!value) return '—'
  const date = safeDate(value)
  if (!date) return value
  return date.toLocaleDateString(locale)
}

function borderedRow(values: WorkbookCellValue[]): WorkbookCell[] {
  return values.map((value) => ({
    style: 'border',
    value,
  }))
}

function headerRow(values: WorkbookCellValue[]): WorkbookCell[] {
  return values.map((value) => ({
    style: 'header',
    value,
  }))
}

function buildWorkbookSheets(options: {
  businessYearRows: TaxLedgerDetailRow[]
  businessYear: number
  config: TaxLedgerReportConfig
  labels: TaxLedgerExportLabels
  locale: string
  createdAtLabel: string
}) {
  const { businessYearRows, businessYear, config, labels, locale, createdAtLabel } = options
  const sheets = config.workbookSheets.length ? config.workbookSheets : [{ name: config.fileStem, siteRole: 'all' as const }]
  const matchedRowIds = new Set<string>()
  const sheetRows = sheets.map((sheet) => {
    const rows = sheet.siteRole === 'all'
      ? businessYearRows
      : businessYearRows.filter((row) => {
          const matched = matchesSheet(row, sheet)
          if (matched) matchedRowIds.add(row.id)
          return matched
        })
    return { sheet, rows }
  })

  if (sheets.length > 1) {
    const hasClassifiedRows = sheetRows.some((entry) => entry.rows.length > 0)
    if (!hasClassifiedRows) {
      sheetRows[0].rows = businessYearRows
    } else {
      const unmatched = businessYearRows.filter((row) => !matchedRowIds.has(row.id))
      sheetRows[0].rows = [...sheetRows[0].rows, ...unmatched].sort(compareTaxLedgerDetailRows)
    }
  }

  return sheetRows.map<WorkbookSheet>(({ sheet, rows }) => ({
    name: sheet.name,
    rows: buildLedgerSheetRows({
      title: sheet.name,
      rows,
      businessYear,
      config,
      labels,
      locale,
      createdAtLabel,
    }),
  }))
}

function buildLedgerSheetRows(options: {
  title: string
  rows: TaxLedgerDetailRow[]
  businessYear: number
  config: TaxLedgerReportConfig
  labels: TaxLedgerExportLabels
  locale: string
  createdAtLabel: string
}) {
  const { title, rows, businessYear, config, labels, locale, createdAtLabel } = options
  const headerRows = buildLedgerHeaderRows(config.detailColumns, labels)
  const dataRows = rows.map<WorkbookCell[]>((row) =>
    borderedRow(config.detailColumns.map((column) => formatColumnValue(row, column, locale))),
  )

  return [
    [title],
    [labels.generatedAt, createdAtLabel],
    [labels.businessYear, businessYear],
    [],
    ...headerRows,
    ...dataRows,
  ]
}

function buildLedgerHeaderRows(columns: TaxLedgerColumnKey[], labels: TaxLedgerExportLabels) {
  const hasContainerGroup = columns.includes('container') && columns.includes('packageCount')
  if (!hasContainerGroup) return [headerRow(columns.map((column) => labels.columns[column]))]

  return [
    headerRow(columns.map((column) => {
      if (column === 'container') return labels.columns.container
      if (column === 'packageCount') return ''
      return labels.columns[column]
    })),
    headerRow(columns.map((column) => {
      if (column === 'container') return labels.columns.containerType
      if (column === 'packageCount') return labels.columns.packageCount
      return ''
    })),
  ]
}

function matchesSheet(row: TaxLedgerDetailRow, sheet: TaxLedgerSheetConfig) {
  if (sheet.siteRole === 'all') return true
  const tokens = sheet.siteRole === 'destination'
    ? [
        row.destinationSiteTypeCode,
        row.destinationSiteTypeLabel,
        row.destinationSiteName,
        row.destinationSiteAddress,
      ]
    : [
        row.sourceSiteTypeCode,
        row.sourceSiteTypeLabel,
        row.sourceSiteName,
        row.sourceSiteAddress,
      ]
  const normalizedTokens = tokens
    .map((value) => normalizeComparable(value))
    .filter((value) => value.length > 0)
  const matchers = (sheet.match ?? [sheet.name]).map((value) => normalizeComparable(value))
  return matchers.some((matcher) => normalizedTokens.some((token) => token.includes(matcher)))
}

export function formatColumnValue(row: TaxLedgerDetailRow, column: TaxLedgerColumnKey, locale: string) {
  switch (column) {
    case 'movementAt':
      return formatDate(row.movementAt, locale)
    case 'item':
      return row.itemLabel || row.liquorCode || '—'
    case 'brand':
      return row.brandName || '—'
    case 'abv':
      return formatAbv(row.abv, locale)
    case 'container':
      return row.containerLabel || '—'
    case 'packageCount':
      return formatNumberValue(row.packageCount, locale)
    case 'quantityMl':
      return formatQuantityMl(row.quantityMl, locale)
    case 'taxRate':
      return formatTaxRate(row.taxRate, locale)
    case 'sourceAddress':
    case 'exporterAddress':
    case 'transferorAddress':
      return row.sourceSiteAddress || '—'
    case 'sourceName':
      return row.sourceSiteName || '—'
    case 'destinationAddress':
    case 'recipientAddress':
    case 'exportDestinationAddress':
    case 'deliveryAddress':
      return row.destinationSiteAddress || '—'
    case 'destinationName':
    case 'exportDestinationName':
      return row.destinationSiteName || '—'
    case 'location':
      return row.destinationSiteAddress || row.sourceSiteAddress || '—'
    case 'lotNo':
      return row.lotNo || '—'
    case 'notes':
      return row.notes || '—'
    default:
      return '—'
  }
}

export function columnSortValue(row: TaxLedgerDetailRow, column: TaxLedgerColumnKey) {
  switch (column) {
    case 'movementAt':
      return row.movementAt ? Date.parse(row.movementAt) : null
    case 'item':
      return row.itemLabel || row.liquorCode
    case 'brand':
      return row.brandName
    case 'abv':
      return row.abv
    case 'container':
      return row.containerLabel
    case 'packageCount':
      return row.packageCount
    case 'quantityMl':
      return row.quantityMl
    case 'taxRate':
      return row.taxRate
    case 'sourceAddress':
    case 'exporterAddress':
    case 'transferorAddress':
      return row.sourceSiteAddress
    case 'sourceName':
      return row.sourceSiteName
    case 'destinationAddress':
    case 'recipientAddress':
    case 'exportDestinationAddress':
    case 'deliveryAddress':
      return row.destinationSiteAddress
    case 'destinationName':
    case 'exportDestinationName':
      return row.destinationSiteName
    case 'location':
      return row.destinationSiteAddress || row.sourceSiteAddress
    case 'lotNo':
      return row.lotNo
    case 'notes':
      return row.notes
    default:
      return null
  }
}

function normalizeComparable(value: string | null | undefined) {
  return (value ?? '').trim().toLowerCase()
}

function normalizedCode(value: string | null | undefined) {
  return (value ?? '').trim()
}

function resolveAlcoholTypeLabel(alcoholTypeLabelMap: Map<string, string>, code: string | null | undefined) {
  const normalized = normalizedCode(code)
  if (!normalized) return null
  return resolveAlcoholTypeRegistryLabel(alcoholTypeLabelMap, normalized) ?? null
}

function formatAddress(value: JsonMap | string | null | undefined) {
  if (!value) return ''
  if (typeof value === 'string') return value.trim()
  if (typeof value !== 'object') return ''
  return Object.values(value)
    .flatMap((entry) => (Array.isArray(entry) ? entry : [entry]))
    .map((entry) => (entry == null ? '' : String(entry).trim()))
    .filter((entry) => entry.length > 0)
    .join(' ')
}

function packageLabel(row: PackageRow | undefined, locale: string) {
  if (!row) return ''
  return row.package_code?.trim() || resolveLocalizedName(row.name_i18n, locale) || ''
}

function packageUnitLiters(row: PackageRow | undefined, uomMap: Map<string, string>) {
  if (!row) return null
  const size = toNumber(row.unit_volume)
  const uomCode = row.volume_uom ? uomMap.get(row.volume_uom) ?? row.volume_uom : null
  return convertToLiters(size, uomCode)
}

function linePackageCount(line: MovementLineRow) {
  return toNumber(line.meta?.package_qty) ?? toNumber(line.unit)
}

function lineQuantityMl(line: MovementLineRow, pkg: PackageRow | undefined, uomMap: Map<string, string>) {
  const rawQty = toNumber(line.qty)
  const uomCode = line.uom_id ? uomMap.get(line.uom_id) ?? line.uom_id : null
  const liters = convertToLiters(rawQty, uomCode)
  if (liters != null) return quantityMlFromLiters(liters)

  const count = linePackageCount(line)
  const unitLiters = packageUnitLiters(pkg, uomMap)
  if (count != null && unitLiters != null) return quantityMlFromLiters(count * unitLiters)
  return null
}

function resolveLineLotId(line: MovementLineRow) {
  return (
    resolveMetaString(line.meta, 'src_lot_id') ||
    resolveMetaString(line.meta, 'source_lot_id') ||
    resolveMetaString(line.meta, 'lot_id') ||
    resolveMetaString(line.meta, 'from_lot_id') ||
    null
  )
}

function resolveSourceEvent(header: MovementHeaderRow, line: MovementLineRow) {
  return (
    resolveMetaString(header.meta, 'tax_event') ||
    resolveMetaString(header.meta, 'tax_decision_code') ||
    resolveMetaString(line.meta, 'tax_event') ||
    resolveMetaString(line.meta, 'derived_tax_event') ||
    resolveMetaString(line.meta, 'tax_decision_code') ||
    null
  )
}

function taxRateForLine(line: MovementLineRow, header: MovementHeaderRow) {
  const lineRate = toNumber(line.tax_rate)
  if (lineRate != null && lineRate > 0) return lineRate
  return resolveMetaNumber(line.meta, 'tax_rate') ?? resolveMetaNumber(header.meta, 'tax_rate')
}

function resolveLineLiquorCode(
  line: MovementLineRow,
  header: MovementHeaderRow,
  batchInfo: BatchInfo | undefined,
) {
  return (
    resolveMetaString(line.meta, 'tax_category_code') ||
    resolveMetaString(line.meta, 'beer_category') ||
    resolveMetaString(header.meta, 'tax_category_code') ||
    resolveMetaString(header.meta, 'beer_category') ||
    batchInfo?.liquorCode ||
    null
  )
}

function resolveLineAbv(
  line: MovementLineRow,
  header: MovementHeaderRow,
  batchInfo: BatchInfo | undefined,
) {
  return (
    resolveMetaNumber(line.meta, 'abv') ??
    resolveMetaNumber(line.meta, 'actual_abv') ??
    resolveMetaNumber(line.meta, 'target_abv') ??
    resolveMetaNumber(header.meta, 'abv') ??
    batchInfo?.abv ??
    null
  )
}

async function loadUoms(supabase: SupabaseClient) {
  const { data, error } = await supabase.from('mst_uom').select('id, code').order('code', { ascending: true })
  if (error) throw error
  const next = new Map<string, string>()
  ;((data ?? []) as UomLookupRow[]).forEach((row) => {
    if (!row?.id || !row?.code) return
    next.set(String(row.id), String(row.code))
  })
  return next
}

async function loadSites(supabase: SupabaseClient, tenantId: string, locale: string) {
  const [siteTypes, sites] = await Promise.all([
    loadSiteTypes(supabase, locale),
    supabase.from('mst_sites').select('id, name, address, site_type_id').eq('tenant_id', tenantId),
  ])

  if (sites.error) throw sites.error
  const next = new Map<string, SiteInfo>()
  ;((sites.data ?? []) as SiteRow[]).forEach((row) => {
    const siteType = row.site_type_id ? siteTypes.get(String(row.site_type_id)) : undefined
    next.set(String(row.id), {
      id: String(row.id),
      name: typeof row.name === 'string' ? row.name : null,
      address: row.address ?? null,
      site_type_id: row.site_type_id ? String(row.site_type_id) : null,
      siteTypeCode: siteType?.code ?? null,
      siteTypeLabel: siteType?.label ?? null,
    })
  })
  return next
}

async function loadSiteTypes(supabase: SupabaseClient, locale: string) {
  const { data, error } = await supabase
    .from('registry_def')
    .select('def_id, def_key, spec')
    .eq('kind', 'site_type')
    .eq('is_active', true)
  if (error) throw error

  const next = new Map<string, { code: string | null; label: string | null }>()
  ;((data ?? []) as SiteTypeRow[]).forEach((row) => {
    if (!row.def_id) return
    const specLabel = localizedSpecText(row.spec, locale)
    const rawCode = row.spec?.code
    const specCode = typeof rawCode === 'string' && rawCode.trim() ? rawCode.trim() : null
    next.set(String(row.def_id), {
      code: specCode ?? row.def_key ?? null,
      label: specLabel || row.def_key || null,
    })
  })
  return next
}

async function loadPackages(supabase: SupabaseClient, tenantId: string) {
  const { data, error } = await supabase
    .from('mst_package')
    .select('id, package_code, name_i18n, unit_volume, volume_uom, is_active')
    .eq('tenant_id', tenantId)
    .eq('is_active', true)
  if (error) throw error
  const next = new Map<string, PackageRow>()
  ;((data ?? []) as PackageRow[]).forEach((row) => {
    next.set(String(row.id), {
      id: String(row.id),
      package_code: typeof row.package_code === 'string' ? row.package_code : null,
      name_i18n: row.name_i18n ?? null,
      unit_volume: row.unit_volume ?? null,
      volume_uom: row.volume_uom ? String(row.volume_uom) : null,
      is_active: row.is_active ?? null,
    })
  })
  return next
}

async function loadAlcoholTypes(supabase: SupabaseClient) {
  const { optionRows, fallbackRows } = await loadAlcoholTypeReferenceData(supabase)
  return buildAlcoholTypeLabelMap(
    optionRows as AlcoholTypeRegistryRow[],
    fallbackRows as AlcoholTypeRegistryRow[],
  )
}

async function loadBatchInfo(supabase: SupabaseClient, tenantId: string, batchIds: string[]) {
  const infoMap = new Map<string, BatchInfo>()
  if (batchIds.length === 0) return infoMap

  const uniqueIds = Array.from(new Set(batchIds))
  const attrIdToCode = new Map<string, string>()
  const attrIds: number[] = []
  const attrValueByBatch = new Map<string, { liquorCode: string | null; abv: number | null }>()

  try {
    const { data: attrDefs, error: attrDefError } = await supabase
      .from('attr_def')
      .select('attr_id, code')
      .eq('domain', 'batch')
      .in('code', ['beer_category', 'actual_abv', 'target_abv'])
      .eq('is_active', true)
    if (attrDefError) throw attrDefError

    ;((attrDefs ?? []) as AttrDefRow[]).forEach((row) => {
      const id = Number(row.attr_id)
      if (!Number.isFinite(id)) return
      attrIds.push(id)
      attrIdToCode.set(String(row.attr_id), String(row.code))
    })

    if (attrIds.length) {
      const { data: attrValues, error: attrValueError } = await supabase
        .from('entity_attr')
        .select('entity_id, attr_id, value_text, value_num, value_ref_type_id, value_json')
        .eq('entity_type', 'batch')
        .in('entity_id', uniqueIds)
        .in('attr_id', attrIds)
      if (attrValueError) throw attrValueError

      ;((attrValues ?? []) as EntityAttrRow[]).forEach((row) => {
        const batchId = String(row.entity_id ?? '')
        if (!batchId) return
        if (!attrValueByBatch.has(batchId)) {
          attrValueByBatch.set(batchId, {
            liquorCode: null,
            abv: null,
          })
        }
        const entry = attrValueByBatch.get(batchId)
        if (!entry) return
        const code = attrIdToCode.get(String(row.attr_id))
        if (!code) return

        if (code === 'beer_category') {
          const jsonDefId = row.value_json?.def_id
          if (typeof jsonDefId === 'string' && jsonDefId.trim()) entry.liquorCode = jsonDefId.trim()
          else if (typeof row.value_text === 'string' && row.value_text.trim()) entry.liquorCode = row.value_text.trim()
          else if (row.value_ref_type_id != null) entry.liquorCode = String(row.value_ref_type_id)
        }

        if (code === 'actual_abv') {
          const abv = toNumber(row.value_num)
          if (abv != null) entry.abv = abv
        }

        if (code === 'target_abv' && entry.abv == null) {
          const abv = toNumber(row.value_num)
          if (abv != null) entry.abv = abv
        }
      })
    }
  } catch (err) {
    console.warn('Failed to load batch attrs for tax ledger report', err)
  }

  const { data, error } = await supabase
    .from('mes_batches')
    .select('id, batch_code, batch_label, product_name, meta, mes_recipe_id, released_reference_json, recipe_json')
    .eq('tenant_id', tenantId)
    .in('id', uniqueIds)
  if (error) throw error

  ;((data ?? []) as BatchRow[]).forEach((row) => {
    const attr = attrValueByBatch.get(row.id)

    infoMap.set(String(row.id), {
      batchCode: row.batch_code ?? null,
      brandName: resolveBatchDisplayName(row),
      liquorCode: resolveBatchBeerCategoryId(row, {
        beerCategoryId: attr?.liquorCode ?? null,
      }),
      abv: resolveBatchTargetAbv(row, {
        targetAbv: attr?.abv ?? null,
      }),
    })
  })

  return infoMap
}

async function loadLotInfo(supabase: SupabaseClient, tenantId: string, lotIds: string[]) {
  const map = new Map<string, string>()
  if (lotIds.length === 0) return map
  const { data, error } = await supabase
    .from('lot')
    .select('id, lot_no')
    .eq('tenant_id', tenantId)
    .in('id', Array.from(new Set(lotIds)))
  if (error) throw error
  ;((data ?? []) as LotRow[]).forEach((row) => {
    if (!row?.id) return
    map.set(String(row.id), typeof row.lot_no === 'string' ? row.lot_no : '')
  })
  return map
}
