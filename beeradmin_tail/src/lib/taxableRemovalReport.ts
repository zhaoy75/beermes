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
import { formatYen, taxAmountFromMilliliters } from '@/lib/moneyFormat'
import { formatTotalVolumeFromMilliliters, quantityToMilliliters } from '@/lib/volumeFormat'

type JsonMap = Record<string, unknown>

type MovementHeaderRow = {
  id: string
  doc_no: string
  movement_at: string | null
  status: string | null
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

export type TaxableRemovalDetailRow = {
  id: string
  movementId: string
  lineNo: number
  movementAt: string | null
  liquorCode: string | null
  itemLabel: string | null
  brandName: string | null
  abv: number | null
  containerLabel: string | null
  quantityMl: number | null
  packageCount: number | null
  taxRate: number | null
  taxAmount: number | null
  destinationAddress: string | null
  destinationName: string | null
  lotNo: string | null
  notes: string | null
  removalTypeLabel: string | null
}

export type TaxableRemovalSummaryRow = {
  key: string
  liquorCode: string | null
  liquorCodeLabel: string | null
  abv: number | null
  quantityMl: number
  packageCount: number
  taxRates: number[]
  taxAmount: number
}

export type TaxableRemovalExportLabels = {
  summaryTitle: string
  tableTitle: string
  generatedAt: string
  businessYear: string
  monthSheetLabel: string
  summarySheetName: string
  summaryColumns: {
    liquorCode: string
    abv: string
    quantityMl: string
    packageCount: string
    taxRate: string
    taxAmount: string
  }
  tableColumns: {
    item: string
    brand: string
    abv: string
    movementAt: string
    container: string
    quantityMl: string
    unitPrice: string
    amount: string
    removalType: string
    destinationAddress: string
    destinationName: string
    lotNo: string
    notes: string
  }
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

export function compareTaxableRemovalDetailRows(a: TaxableRemovalDetailRow, b: TaxableRemovalDetailRow) {
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

export function buildTaxableRemovalSummaryRows(
  detailRows: TaxableRemovalDetailRow[],
  businessYear: number,
) {
  const map = new Map<string, TaxableRemovalSummaryRow>()

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
          taxRates: [],
          taxAmount: 0,
        })
      }

      const entry = map.get(key)
      if (!entry) return
      entry.quantityMl += row.quantityMl ?? 0
      entry.packageCount += row.packageCount ?? 0
      if (row.taxRate != null && !entry.taxRates.includes(row.taxRate)) entry.taxRates.push(row.taxRate)
      entry.taxAmount += row.taxAmount ?? 0
    })

  return Array.from(map.values())
    .map((row) => ({
      ...row,
      taxRates: row.taxRates.slice().sort((a, b) => a - b),
    }))
    .sort((a, b) => {
      const labelCompare = (a.liquorCodeLabel ?? a.liquorCode ?? '').localeCompare(
        b.liquorCodeLabel ?? b.liquorCode ?? '',
      )
      if (labelCompare !== 0) return labelCompare
      const codeCompare = (a.liquorCode ?? '').localeCompare(b.liquorCode ?? '')
      if (codeCompare !== 0) return codeCompare
      return (a.abv ?? 0) - (b.abv ?? 0)
    })
}

export function createTaxableRemovalBusinessYearWorkbookBlob(options: {
  detailRows: TaxableRemovalDetailRow[]
  businessYear: number
  labels: TaxableRemovalExportLabels
  locale: string
  createdAt: Date
  creator?: string
}) {
  const { detailRows, businessYear, labels, locale, createdAt, creator } = options
  const createdAtLabel = createdAt.toLocaleString(locale)
  const summaryRows = buildTaxableRemovalSummaryRows(detailRows, businessYear)
  const sheets: WorkbookSheet[] = [
    {
      name: labels.summarySheetName,
      rows: buildSummarySheetRows({
        summaryRows,
        businessYear,
        createdAtLabel,
        labels,
        locale,
      }),
    },
    ...buildMonthSheetOrder().map((month) => ({
      name: `${calendarYearForBusinessYearMonth(businessYear, month)}-${pad2(month)}`,
      rows: buildMonthlySheetRows({
        detailRows,
        businessYear,
        month,
        createdAtLabel,
        labels,
        locale,
      }),
    })),
  ]

  return createWorkbookBlob({
    creator: creator ?? 'beeradmin_tail',
    createdAtIso: createdAt.toISOString(),
    sheets,
  })
}

export function createTaxableRemovalMonthWorkbookBlob(options: {
  detailRows: TaxableRemovalDetailRow[]
  businessYear: number
  month: number
  labels: TaxableRemovalExportLabels
  locale: string
  createdAt: Date
  creator?: string
}) {
  const { detailRows, businessYear, month, labels, locale, createdAt, creator } = options
  const createdAtLabel = createdAt.toLocaleString(locale)
  const calendarYear = calendarYearForBusinessYearMonth(businessYear, month)

  return createWorkbookBlob({
    creator: creator ?? 'beeradmin_tail',
    createdAtIso: createdAt.toISOString(),
    sheets: [
      {
        name: `${calendarYear}-${pad2(month)}`,
        rows: buildMonthlySheetRows({
          detailRows,
          businessYear,
          month,
          createdAtLabel,
          labels,
          locale,
        }),
      },
    ],
  })
}

export function buildTaxableRemovalBusinessYearFileName(businessYear: number) {
  return `課税移出一覧表_${businessYear}.xlsx`
}

export function buildTaxableRemovalMonthFileName(year: number, month: number) {
  return `課税移出一覧表_${year}${pad2(month)}.xlsx`
}

export async function loadTaxableRemovalDetailRows(options: {
  supabase: SupabaseClient
  tenantId: string
  locale: string
  removalTypeLabel: string
}) {
  const { supabase, tenantId, locale, removalTypeLabel } = options
  const [uomMap, siteMap, packageMap, alcoholTypeLabelMap] = await Promise.all([
    loadUoms(supabase),
    loadSites(supabase, tenantId),
    loadPackages(supabase, tenantId),
    loadAlcoholTypes(supabase),
  ])

  const { data: headerData, error: headerError } = await supabase
    .from('inv_movements')
    .select('id, doc_no, movement_at, status, dest_site_id, notes, meta')
    .eq('tenant_id', tenantId)
    .neq('status', 'void')
    .order('movement_at', { ascending: false })

  if (headerError) throw headerError

  const headers = ((headerData ?? []) as MovementHeaderRow[]).filter(isTaxableRemoval)
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
    .map((line) => resolveMetaString(line.meta, 'src_lot_id'))
    .filter((value): value is string => !!value)

  const [batchInfoMap, lotInfoMap] = await Promise.all([
    loadBatchInfo(supabase, tenantId, batchIds),
    loadLotInfo(supabase, tenantId, lotIds),
  ])

  return lines
    .map<TaxableRemovalDetailRow | null>((line) => {
      const header = headerMap.get(line.movement_id)
      if (!header) return null

      const pkg = line.package_id ? packageMap.get(line.package_id) : undefined
      const batchInfo = line.batch_id ? batchInfoMap.get(line.batch_id) : undefined
      const destination = header.dest_site_id ? siteMap.get(header.dest_site_id) : undefined
      const liquorCode = batchInfo?.liquorCode ?? resolveMetaString(line.meta, 'beer_category')
      const itemLabel = resolveAlcoholTypeLabel(alcoholTypeLabelMap, liquorCode)
      const quantityMl = lineQuantityMl(line, pkg, uomMap)
      const packageCount = linePackageCount(line)
      const taxRate = taxRateForLine(line, header)
      const lotId = resolveMetaString(line.meta, 'src_lot_id')
      const lotNo = (lotId ? lotInfoMap.get(lotId) : '') || batchInfo?.batchCode || null

      return {
        id: line.id,
        movementId: line.movement_id,
        lineNo: line.line_no ?? 0,
        movementAt: header.movement_at ?? null,
        liquorCode: liquorCode ?? null,
        itemLabel: itemLabel ?? liquorCode ?? null,
        brandName: batchInfo?.brandName ?? null,
        abv: batchInfo?.abv ?? null,
        containerLabel: packageLabel(pkg, locale) || null,
        quantityMl,
        packageCount,
        taxRate,
        taxAmount: taxAmountForLine(quantityMl, taxRate),
        destinationAddress: formatAddress(destination?.address) || null,
        destinationName: destination?.name ?? null,
        lotNo,
        notes:
          (line.notes && line.notes.trim()) ||
          resolveMetaString(line.meta, 'line_note') ||
          (header.notes && header.notes.trim()) ||
          null,
        removalTypeLabel,
      }
    })
    .filter((row): row is TaxableRemovalDetailRow => row !== null)
    .sort(compareTaxableRemovalDetailRows)
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

function formatCurrency(value: number | null | undefined, locale: string) {
  return formatYen(value, locale)
}

function formatTaxRateSummary(values: number[], locale: string) {
  if (!values.length) return '—'
  return values.map((value) => `${formatNumberValue(value, locale)}/kl`).join(', ')
}

function formatDateTime(value: string | null | undefined, locale: string) {
  if (!value) return '—'
  const date = safeDate(value)
  if (!date) return value
  return date.toLocaleString(locale)
}

function pad2(value: number) {
  return String(value).padStart(2, '0')
}

function buildMonthSheetOrder() {
  return [...Array.from({ length: 9 }, (_, index) => index + 4), 1, 2, 3]
}

function calendarYearForBusinessYearMonth(businessYear: number, month: number) {
  return month >= 4 ? businessYear : businessYear + 1
}

function borderedRow(values: WorkbookCellValue[]): WorkbookCell[] {
  return values.map((value) => ({
    style: 'border',
    value,
  }))
}

function buildSummarySheetRows(options: {
  summaryRows: TaxableRemovalSummaryRow[]
  businessYear: number
  createdAtLabel: string
  labels: TaxableRemovalExportLabels
  locale: string
}) {
  const { summaryRows, businessYear, createdAtLabel, labels, locale } = options
  const header: WorkbookCellValue[] = [
    labels.summaryColumns.liquorCode,
    labels.summaryColumns.abv,
    labels.summaryColumns.quantityMl,
    labels.summaryColumns.packageCount,
    labels.summaryColumns.taxRate,
    labels.summaryColumns.taxAmount,
  ]

  const rows = summaryRows.map<WorkbookCell[]>((row) =>
    borderedRow([
      row.liquorCodeLabel || row.liquorCode || '—',
      formatAbv(row.abv, locale),
      formatQuantityMl(row.quantityMl, locale),
      formatNumberValue(row.packageCount, locale),
      formatTaxRateSummary(row.taxRates, locale),
      formatCurrency(row.taxAmount, locale),
    ]),
  )

  return [
    [labels.summaryTitle],
    [labels.generatedAt, createdAtLabel],
    [labels.businessYear, businessYear],
    [],
    borderedRow(header),
    ...rows,
  ]
}

function buildMonthlySheetRows(options: {
  detailRows: TaxableRemovalDetailRow[]
  businessYear: number
  month: number
  createdAtLabel: string
  labels: TaxableRemovalExportLabels
  locale: string
}) {
  const { detailRows, businessYear, month, createdAtLabel, labels, locale } = options
  const calendarYear = calendarYearForBusinessYearMonth(businessYear, month)
  const monthRows = detailRows.filter((row) => {
    if (!matchesBusinessYear(row.movementAt, businessYear)) return false
    const date = safeDate(row.movementAt)
    return !!date && date.getMonth() + 1 === month
  })

  const header: WorkbookCellValue[] = [
    labels.tableColumns.item,
    labels.tableColumns.brand,
    labels.tableColumns.abv,
    labels.tableColumns.movementAt,
    labels.tableColumns.container,
    labels.tableColumns.quantityMl,
    labels.tableColumns.unitPrice,
    labels.tableColumns.amount,
    labels.tableColumns.removalType,
    labels.tableColumns.destinationAddress,
    labels.tableColumns.destinationName,
    labels.tableColumns.lotNo,
    labels.tableColumns.notes,
  ]

  const rows = monthRows.map<WorkbookCell[]>((row) =>
    borderedRow([
      row.itemLabel || row.liquorCode || '—',
      row.brandName || '—',
      formatAbv(row.abv, locale),
      formatDateTime(row.movementAt, locale),
      row.containerLabel || '—',
      formatQuantityMl(row.quantityMl, locale),
      '—',
      '—',
      row.removalTypeLabel || '—',
      row.destinationAddress || '—',
      row.destinationName || '—',
      row.lotNo || '—',
      row.notes || '—',
    ]),
  )

  return [
    [labels.tableTitle],
    [labels.generatedAt, createdAtLabel],
    [labels.businessYear, businessYear],
    [labels.monthSheetLabel, `${calendarYear}-${pad2(month)}`],
    [],
    borderedRow(header),
    ...rows,
  ]
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

function isTaxableRemoval(header: MovementHeaderRow) {
  const taxEvent = resolveMetaString(header.meta, 'tax_event')
  if (taxEvent === 'TAXABLE_REMOVAL') return true
  const decision = resolveMetaString(header.meta, 'tax_decision_code')
  return decision === 'TAXABLE_REMOVAL'
}

function taxRateForLine(line: MovementLineRow, header: MovementHeaderRow) {
  return toNumber(line.tax_rate) ?? resolveMetaNumber(header.meta, 'tax_rate')
}

function taxAmountForLine(quantityMl: number | null, taxRate: number | null) {
  if (quantityMl == null || taxRate == null) return null
  return taxAmountFromMilliliters(quantityMl, taxRate)
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

async function loadSites(supabase: SupabaseClient, tenantId: string) {
  const { data, error } = await supabase.from('mst_sites').select('id, name, address').eq('tenant_id', tenantId)
  if (error) throw error
  const next = new Map<string, SiteRow>()
  ;((data ?? []) as SiteRow[]).forEach((row) => {
    next.set(String(row.id), {
      id: String(row.id),
      name: typeof row.name === 'string' ? row.name : null,
      address: row.address ?? null,
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
    console.warn('Failed to load batch attrs for taxable removal report', err)
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
