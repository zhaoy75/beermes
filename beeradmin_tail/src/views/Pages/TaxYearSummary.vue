<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <section class="space-y-6">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between bg-white border border-gray-200 rounded-xl p-4 shadow-sm">
        <div>
          <h1 class="text-lg font-semibold text-gray-900">{{ t('taxYearSummary.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('taxYearSummary.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <label class="flex items-center gap-2 text-sm text-gray-700">
            <span>{{ t('taxYearSummary.yearLabel') }}</span>
            <select v-model.number="selectedYear" class="h-[40px] border rounded px-3 bg-white">
              <option v-for="option in yearOptions" :key="option" :value="option">
                {{ option }}
              </option>
            </select>
          </label>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-50"
            :disabled="loading"
            @click="loadSummary"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <div v-if="errorMessage" class="p-3 border border-red-200 bg-red-50 text-red-700 rounded-lg">{{ errorMessage }}</div>

      <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
        <header class="flex items-center justify-between mb-4">
          <h2 class="text-base font-semibold text-gray-900">{{ t('taxYearSummary.summaryHeading') }}</h2>
          <span v-if="loading" class="text-sm text-gray-500">{{ t('taxYearSummary.loading') }}</span>
        </header>
        <div v-if="categorySummaries.length > 0" class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
          <article
            v-for="item in categorySummaries"
            :key="item.categoryId"
            class="border border-gray-200 rounded-lg p-4 bg-white shadow-sm"
          >
            <header class="flex items-center justify-between">
              <h3 class="text-sm font-medium text-gray-700">{{ item.categoryName }}</h3>
              <span class="text-xs text-gray-500">{{ selectedYear }}</span>
            </header>
            <dl class="mt-3 space-y-1 text-sm">
              <div class="flex justify-between text-gray-600">
                <dt>{{ t('taxYearSummary.volume') }}</dt>
                <dd class="font-semibold text-gray-900">{{ formatVolume(item.totalVolume) }}</dd>
              </div>
              <div class="flex justify-between text-gray-600">
                <dt>{{ t('taxYearSummary.taxAmount') }}</dt>
                <dd class="font-semibold text-gray-900">{{ formatCurrency(item.totalTax) }}</dd>
              </div>
            </dl>
          </article>
        </div>
        <div v-else class="text-sm text-gray-500">{{ loading ? t('taxYearSummary.loading') : t('taxYearSummary.noData') }}</div>
      </section>

      <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
        <header class="flex items-center justify-between mb-4">
          <h2 class="text-base font-semibold text-gray-900">{{ t('taxYearSummary.monthlyChartTitle') }}</h2>
        </header>
        <div class="h-72">
          <canvas ref="chartCanvas"></canvas>
        </div>
      </section>

      <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
        <header class="flex items-center justify-between mb-4">
          <h2 class="text-base font-semibold text-gray-900">{{ t('taxYearSummary.batchesSectionTitle') }}</h2>
        </header>
        <div v-if="batchBreakdown.length === 0" class="text-sm text-gray-500">
          {{ loading ? t('taxYearSummary.loading') : t('taxYearSummary.noData') }}
        </div>
        <div v-else class="space-y-4">
          <article v-for="month in batchBreakdown" :key="month.month" class="border border-gray-200 rounded-lg">
            <header class="flex items-center justify-between px-4 py-3 border-b border-gray-100 bg-gray-50">
              <div class="text-sm font-semibold text-gray-800">{{ month.label }}</div>
              <div class="flex items-center gap-4 text-sm text-gray-600">
                <span>{{ t('taxYearSummary.volumeShort') }}: <strong class="text-gray-900">{{ formatVolume(month.subtotalVolume) }}</strong></span>
                <span>{{ t('taxYearSummary.taxShort') }}: <strong class="text-gray-900">{{ formatCurrency(month.subtotalTax) }}</strong></span>
              </div>
            </header>
            <div class="overflow-x-auto">
              <table class="min-w-full text-sm">
                <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
                  <tr>
                    <th class="px-3 py-2 text-left">{{ t('taxYearSummary.batch') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxYearSummary.category') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxYearSummary.movementDate') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('taxYearSummary.volumeShort') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('taxYearSummary.taxShort') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="row in month.batches" :key="row.key" class="hover:bg-gray-50">
                    <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.batchCode }}</td>
                    <td class="px-3 py-2 text-gray-700">{{ row.categoryName }}</td>
                    <td class="px-3 py-2 text-gray-600">{{ formatDate(row.movementDate) }}</td>
                    <td class="px-3 py-2 text-right font-semibold text-gray-800">{{ formatVolume(row.totalVolume) }}</td>
                    <td class="px-3 py-2 text-right font-semibold text-gray-800">{{ formatCurrency(row.totalTax) }}</td>
                  </tr>
                  <tr class="bg-gray-50 text-gray-700 font-semibold">
                    <td class="px-3 py-2" colspan="3">{{ t('taxYearSummary.monthTotal') }}</td>
                    <td class="px-3 py-2 text-right">{{ formatVolume(month.subtotalVolume) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatCurrency(month.subtotalTax) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </article>
        </div>
      </section>
    </section>
  </AdminLayout>
</template>

<script setup lang="ts">
import { Chart, registerables } from 'chart.js'
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import {
  buildAlcoholTypeLookupKeys,
  loadAlcoholTypeReferenceData,
} from '@/lib/alcoholTypeRegistry'
import { supabase } from '@/lib/supabase'
import { normalizeDateOnly } from '@/lib/dateOnly'
import { calculateTaxAmount, normalizeTaxEventValue, resolveTaxEvent } from '@/lib/taxReport'
import { formatYen, truncateYen } from '@/lib/moneyFormat'
import { formatTotalVolumeFromLiters, millilitersToLiters, quantityToMilliliters } from '@/lib/volumeFormat'

Chart.register(...registerables)

const { t, locale } = useI18n()
const pageTitle = computed(() => t('taxYearSummary.title'))

const currentYear = new Date().getFullYear()
const yearOptions = computed(() => {
  const years: number[] = []
  for (let offset = 0; offset < 6; offset += 1) {
    years.push(currentYear - offset)
  }
  return years
})
const selectedYear = ref(currentYear)

const loading = ref(false)
const errorMessage = ref('')
const tenantId = ref<string | null>(null)

interface CategoryRecord {
  id: string
  code: string
  name: string | null
  lookupKeys: string[]
}

interface TaxRateRecord {
  taxrate: number
  effectDate: string | null
  expireDate: string | null
}

interface MovementHeader {
  id: string
  movement_at: string | null
  doc_type: string
  status: string | null
  meta: Record<string, unknown> | null
}

interface MovementLine {
  movement_id: string
  package_id: string | null
  batch_id: string | null
  qty: number | null
  tax_rate: number | string | null
  uom_id: string | null
  meta: Record<string, unknown> | null
}

interface PackageCategoryInfo {
  id: string
  unit_size_l: number | null
}

interface PackageLookupRow {
  id: string
  unit_volume: unknown
  volume_uom: unknown
}

interface BatchRow {
  id: string
  batch_code: string | null
}

interface AttrDefRow {
  attr_id: number | string
  code: string | null
}

interface EntityAttrRow {
  entity_id: string | number | null
  attr_id: number | string | null
  value_text?: string | null
  value_ref_type_id?: string | number | null
  value_json?: Record<string, unknown> | null
}

interface CategorySummary {
  categoryId: string
  categoryName: string
  totalVolume: number
  totalTax: number
}

interface MonthBatchRow {
  key: string
  month: number
  batchId: string
  batchCode: string
  categoryId: string
  categoryName: string
  movementDate: string
  totalVolume: number
  totalTax: number
}

interface MonthGroup {
  month: number
  label: string
  subtotalVolume: number
  subtotalTax: number
  batches: MonthBatchRow[]
}

const categories = ref<CategoryRecord[]>([])
const uoms = ref<Array<{ id: string; code: string }>>([])
const categorySummaries = ref<CategorySummary[]>([])
const monthlySeries = ref<Array<{ month: number; volume: number; tax: number }>>([])
const batchBreakdown = ref<MonthGroup[]>([])

const chartCanvas = ref<HTMLCanvasElement | null>(null)
let chartInstance: Chart | null = null

const categoryLookup = computed(() => {
  const map = new Map<string, CategoryRecord>()
  categories.value.forEach((row) => {
    row.lookupKeys.forEach((key) => {
      const normalized = String(key ?? '').trim()
      if (normalized) map.set(normalized, row)
      const normalizedCode = normalizeTaxCategoryCode(normalized)
      if (normalizedCode) map.set(normalizedCode, row)
    })
    const normalizedCode = normalizeTaxCategoryCode(row.code)
    if (normalizedCode) map.set(normalizedCode, row)
  })
  return map
})

const uomLookup = computed(() => {
  const map = new Map<string, string>()
  uoms.value.forEach((row) => map.set(row.id, row.code))
  return map
})

const monthFormatter = computed(() => new Intl.DateTimeFormat(locale.value, { month: 'short' }))

function monthLabel(monthIndex: number) {
  return monthFormatter.value.format(new Date(selectedYear.value, monthIndex, 1))
}

function formatVolume(value: number) {
  if (!Number.isFinite(value)) return '—'
  return formatTotalVolumeFromLiters(value, locale.value)
}

function formatCurrency(value: number) {
  return formatYen(value, locale.value)
}

function formatDate(value: string) {
  if (!value) return '—'
  try {
    return new Intl.DateTimeFormat(locale.value).format(new Date(value))
  } catch {
    return value
  }
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved for current session')
  tenantId.value = id
  return id
}

async function loadCategories() {
  try {
    const { optionRows, fallbackRows } = await loadAlcoholTypeReferenceData(supabase)
    categories.value = optionRows.map((row: { def_id?: unknown; def_key?: unknown; spec?: Record<string, unknown> | null }) => ({
      id: String(row.def_id ?? ''),
      code: String(row.spec?.tax_category_code ?? row.spec?.code ?? row.def_key ?? ''),
      name: typeof row.spec?.name === 'string' ? row.spec.name : (typeof row.def_key === 'string' ? row.def_key : null),
      lookupKeys: buildAlcoholTypeLookupKeys(row, fallbackRows),
    }))
  } catch (err) {
    console.warn('Failed to load categories', err)
  }
}

const taxRateIndex = ref<Record<string, TaxRateRecord[]>>({})

function normalizeTaxCategoryCode(value: unknown) {
  if (value == null) return ''
  if (typeof value === 'number' && Number.isFinite(value)) return String(Math.trunc(value))
  const text = String(value).trim()
  if (!text) return ''
  const numeric = Number(text)
  return Number.isFinite(numeric) ? String(Math.trunc(numeric)) : text
}

function buildTaxRateIndex(rows: Array<{ spec?: Record<string, unknown> | null }>) {
  const index: Record<string, TaxRateRecord[]> = {}
  rows.forEach((row) => {
    const spec = (row.spec && typeof row.spec === 'object') ? row.spec : {}
    const categoryCode = normalizeTaxCategoryCode(spec.tax_category_code)
    if (!categoryCode) return
    const taxRateRaw = Number(spec.tax_rate ?? 0)
    if (!Number.isFinite(taxRateRaw)) return
    const entry: TaxRateRecord = {
      taxrate: taxRateRaw,
      effectDate: normalizeDateOnly(spec.start_date) || null,
      expireDate: normalizeDateOnly(spec.expiration_date) || null,
    }
    if (!index[categoryCode]) index[categoryCode] = []
    index[categoryCode].push(entry)
  })

  Object.values(index).forEach((records) => {
    records.sort((a, b) => {
      if (!a.effectDate || !b.effectDate) return 0
      return a.effectDate.localeCompare(b.effectDate)
    })
  })
  taxRateIndex.value = index
}

async function loadTaxRates() {
  try {
    const { data, error } = await supabase
      .from('registry_def')
      .select('spec')
      .eq('kind', 'alcohol_tax')
      .eq('is_active', true)
    if (error) throw error
    buildTaxRateIndex((data ?? []) as Array<{ spec?: Record<string, unknown> | null }>)
  } catch (err) {
    console.warn('Failed to load tax rates', err)
    taxRateIndex.value = {}
  }
}

async function loadUoms() {
  try {
    const { data, error } = await supabase
      .from('mst_uom')
      .select('id, code')
      .order('code', { ascending: true })
    if (error) throw error
    uoms.value = data ?? []
  } catch (err) {
    console.warn('Failed to load UOM codes', err)
    uoms.value = []
  }
}

function convertToLiters(size: number | null | undefined, uomCode: string | null | undefined) {
  return millilitersToLiters(quantityToMilliliters(size, uomCode))
}

function toNumber(value: unknown): number | null {
  if (value == null || value === '') return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function resolvePackageSizeLiters(row: PackageCategoryInfo | undefined) {
  return row?.unit_size_l ?? null
}

function resolveLineVolume(line: MovementLine, packageRow: PackageCategoryInfo | undefined) {
  const qty = toNumber(line.qty)
  const uomCode = line.uom_id ? uomLookup.value.get(line.uom_id) : null
  let volume = qty != null ? convertToLiters(qty, uomCode) : null

  if (!volume || volume <= 0) {
    const pkgQty = toNumber(line.meta?.package_qty)
    const unitVolume = toNumber(line.meta?.unit_volume_l) ?? resolvePackageSizeLiters(packageRow)
    if (pkgQty != null && unitVolume != null) {
      volume = pkgQty * unitVolume
    }
  }

  return volume
}

function applicableTaxRate(categoryId: string | null | undefined, dateStr: string | null | undefined) {
  const code = normalizeTaxCategoryCode(categoryId)
  if (!code) return 0
  const records = taxRateIndex.value[code]
  if (!records || records.length === 0) return 0
  if (!dateStr) return records[records.length - 1]?.taxrate ?? 0
  const date = normalizeDateOnly(dateStr)
  if (!date) return records[records.length - 1]?.taxrate ?? 0
  let candidate: TaxRateRecord | null = null
  for (const record of records) {
    const effectOk = !record.effectDate || date >= record.effectDate
    const expireOk = !record.expireDate || date <= record.expireDate
    if (effectOk && expireOk) {
      candidate = record
    }
    if (record.effectDate && date < record.effectDate) {
      break
    }
  }
  if (candidate) return candidate.taxrate
  return records[records.length - 1]?.taxrate ?? 0
}

function resolveMovementTaxEvent(header: MovementHeader) {
  return resolveTaxEvent(
    header.doc_type,
    normalizeTaxEventValue(header.meta?.tax_event),
    normalizeTaxEventValue(header.meta?.tax_decision_code),
  )
}

function includeInYearSummary(taxEvent: string | null) {
  return (
    taxEvent === 'TAXABLE_REMOVAL' ||
    taxEvent === 'RETURN_TO_FACTORY' ||
    taxEvent === 'NON_TAXABLE_REMOVAL' ||
    taxEvent === 'EXPORT_EXEMPT'
  )
}

function resolveMovementTaxRate(
  line: MovementLine,
  header: MovementHeader,
  categoryCode: string,
) {
  const explicitLineRate = toNumber(line.tax_rate)
  if (explicitLineRate != null && explicitLineRate > 0) return explicitLineRate
  return applicableTaxRate(categoryCode, header.movement_at)
}

async function loadMovementLines(movementIds: string[]) {
  if (movementIds.length === 0) return [] as MovementLine[]
  const { data, error } = await supabase
    .from('inv_movement_lines')
    .select('movement_id, package_id, batch_id, qty, tax_rate, uom_id, meta')
    .in('movement_id', movementIds)
  if (error) throw error
  return ((data ?? []) as MovementLine[]).filter((row) => row.package_id || row.batch_id)
}

async function loadPackageCategories(packageIds: string[]) {
  const map = new Map<string, PackageCategoryInfo>()
  if (packageIds.length === 0) return map
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_package')
    .select('id, unit_volume, volume_uom, is_active')
    .eq('tenant_id', tenant)
    .eq('is_active', true)
    .in('id', packageIds)
  if (error) throw error
  ;((data ?? []) as PackageLookupRow[]).forEach((row) => {
    const volumeUom =
      typeof row.volume_uom === 'string'
        ? (uomLookup.value.get(row.volume_uom) ?? row.volume_uom)
        : null
    map.set(row.id, {
      id: row.id,
      unit_size_l: convertToLiters(
        toNumber(row.unit_volume),
        volumeUom,
      ),
    })
  })
  return map
}

async function loadBatches(batchIds: string[]) {
  const map = new Map<string, BatchRow>()
  if (batchIds.length === 0) return map
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mes_batches')
    .select('id, batch_code')
    .eq('tenant_id', tenant)
    .in('id', batchIds)
  if (error) throw error
  ;((data ?? []) as BatchRow[]).forEach((row) => map.set(row.id, row))
  return map
}

async function loadBatchCategories(batchIds: string[]) {
  const map = new Map<string, string>()
  if (batchIds.length === 0) return map
  const uniqueIds = Array.from(new Set(batchIds))
  const { data: attrDefs, error: attrDefError } = await supabase
    .from('attr_def')
    .select('attr_id, code')
    .eq('domain', 'batch')
    .eq('code', 'beer_category')
    .eq('is_active', true)
  if (attrDefError) throw attrDefError

  const attrIds = ((attrDefs ?? []) as AttrDefRow[])
    .map((row) => Number(row.attr_id))
    .filter((value) => Number.isFinite(value))
  if (!attrIds.length) return map

  const { data: attrValues, error: attrValueError } = await supabase
    .from('entity_attr')
    .select('entity_id, attr_id, value_text, value_ref_type_id, value_json')
    .eq('entity_type', 'batch')
    .in('entity_id', uniqueIds)
    .in('attr_id', attrIds)
  if (attrValueError) throw attrValueError

  ;((attrValues ?? []) as EntityAttrRow[]).forEach((row) => {
    const batchId = String(row.entity_id ?? '')
    if (!batchId) return
    const jsonDefId = row.value_json?.def_id
    if (typeof jsonDefId === 'string' && jsonDefId.trim()) {
      map.set(batchId, jsonDefId.trim())
      return
    }
    if (typeof jsonDefId === 'number' && Number.isFinite(jsonDefId)) {
      map.set(batchId, String(jsonDefId))
      return
    }
    if (typeof row.value_text === 'string' && row.value_text.trim()) {
      map.set(batchId, row.value_text.trim())
      return
    }
    if (row.value_ref_type_id != null) {
      map.set(batchId, String(row.value_ref_type_id))
    }
  })
  return map
}

async function loadSummary() {
  try {
    loading.value = true
    errorMessage.value = ''
    const tenant = await ensureTenant()
    const startDate = `${selectedYear.value}-01-01`
    const endDate = `${selectedYear.value + 1}-01-01`

    const { data, error } = await supabase
      .from('inv_movements')
      .select('id, movement_at, doc_type, status, meta')
      .eq('tenant_id', tenant)
      .neq('status', 'void')
      .gte('movement_at', startDate)
      .lt('movement_at', endDate)

    if (error) throw error

    const headers = (data ?? []) as MovementHeader[]
    if (headers.length === 0) {
      resetSummary()
      return
    }

    const headerMap = new Map(headers.map((row) => [row.id, row]))
    const movementIds = headers.map((row) => row.id)
    const lines = await loadMovementLines(movementIds)

    if (lines.length === 0) {
      resetSummary()
      return
    }

    const packageIds = Array.from(new Set(lines.map((line) => line.package_id).filter(Boolean))) as string[]
    const packageMap = await loadPackageCategories(packageIds)
    const batchIds = Array.from(
      new Set(lines.map((line) => line.batch_id).filter((id): id is string => Boolean(id))),
    )
    const batchMap = await loadBatches(batchIds)
    const batchCategoryMap = await loadBatchCategories(batchIds)

    processMovementLines(lines, headerMap, packageMap, batchMap, batchCategoryMap)
  } catch (err) {
    console.error(err)
    errorMessage.value = err instanceof Error ? err.message : String(err)
    resetSummary()
  } finally {
    loading.value = false
  }
}

function resetSummary() {
  categorySummaries.value = []
  monthlySeries.value = Array.from({ length: 12 }, (_, month) => ({ month, volume: 0, tax: 0 }))
  batchBreakdown.value = []
  updateChart()
}

function processMovementLines(
  rows: MovementLine[],
  headerMap: Map<string, MovementHeader>,
  packageMap: Map<string, PackageCategoryInfo>,
  batchMap: Map<string, BatchRow>,
  batchCategoryMap: Map<string, string>
) {
  const categoryTotals = new Map<string, { volume: number; tax: number }>()
  const monthlyTotals = Array.from({ length: 12 }, (_, month) => ({ month, volume: 0, tax: 0 }))
  const monthBatchMap = new Map<string, MonthBatchRow>()

  rows.forEach((row) => {
    const header = headerMap.get(row.movement_id)
    if (!header?.movement_at) return
    const taxEvent = resolveMovementTaxEvent(header)
    if (!includeInYearSummary(taxEvent)) return
    const movementAt = header.movement_at
    const movementDate = new Date(movementAt)
    if (Number.isNaN(movementDate.getTime())) return
    const monthIndex = movementDate.getMonth()

    const packageRow = row.package_id ? packageMap.get(row.package_id) : undefined
    const batchId = row.batch_id ?? null
    if (!batchId) return
    const batchInfo = batchMap.get(batchId)
    const rawCategoryId = batchCategoryMap.get(batchId) ?? null
    if (!rawCategoryId) return
    const categoryRecord = categoryLookup.value.get(rawCategoryId)
    const categoryId = categoryRecord?.id || normalizeTaxCategoryCode(rawCategoryId) || rawCategoryId
    const categoryName = categoryRecord?.name || categoryRecord?.code || categoryId

    const volume = resolveLineVolume(row, packageRow)
    if (volume == null || volume <= 0) return

    const taxRate = resolveMovementTaxRate(row, header, categoryRecord?.code ?? rawCategoryId)
    const taxAmount = calculateTaxAmount(header.doc_type, volume, taxRate, taxEvent)

    const categoryEntry = categoryTotals.get(categoryId) || { volume: 0, tax: 0 }
    categoryEntry.volume += volume
    categoryEntry.tax += taxAmount
    categoryTotals.set(categoryId, categoryEntry)

    monthlyTotals[monthIndex].volume += volume
    monthlyTotals[monthIndex].tax += taxAmount

    const key = `${monthIndex}-${batchId}`
    let batchEntry = monthBatchMap.get(key)
    if (!batchEntry) {
      batchEntry = {
        key,
        month: monthIndex,
        batchId,
        batchCode: batchInfo?.batch_code ?? batchId,
        categoryId,
        categoryName,
        movementDate: movementAt,
        totalVolume: 0,
        totalTax: 0,
      }
      monthBatchMap.set(key, batchEntry)
    }
    batchEntry.totalVolume += volume
    batchEntry.totalTax += taxAmount
    if (movementDate < new Date(batchEntry.movementDate)) {
      batchEntry.movementDate = movementAt
    }
  })

  categorySummaries.value = Array.from(categoryTotals.entries()).map(([categoryId, totals]) => {
    const category = categoryLookup.value.get(categoryId)
    return {
      categoryId,
      categoryName: category?.name || category?.code || categoryId,
      totalVolume: totals.volume,
      totalTax: totals.tax,
    }
  }).sort((a, b) => a.categoryName.localeCompare(b.categoryName))

  monthlySeries.value = monthlyTotals

  const groups: MonthGroup[] = []
  for (let month = 0; month < 12; month += 1) {
    const batches = Array.from(monthBatchMap.values()).filter((row) => row.month === month)
    if (batches.length === 0) continue
    batches.sort((a, b) => new Date(a.movementDate).getTime() - new Date(b.movementDate).getTime() || a.batchCode.localeCompare(b.batchCode))
    const subtotalVolume = batches.reduce((sum, row) => sum + row.totalVolume, 0)
    const subtotalTax = batches.reduce((sum, row) => sum + row.totalTax, 0)
    groups.push({
      month,
      label: monthLabel(month),
      subtotalVolume,
      subtotalTax,
      batches,
    })
  }
  batchBreakdown.value = groups
  updateChart()
}

function updateChart() {
  nextTick(() => {
    const canvas = chartCanvas.value
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const labels = monthlySeries.value.map((entry) => monthLabel(entry.month))
    const volumes = monthlySeries.value.map((entry) => Number(entry.volume.toFixed(2)))
    const taxes = monthlySeries.value.map((entry) => truncateYen(entry.tax))

    if (!chartInstance) {
      chartInstance = new Chart(ctx, {
        type: 'bar',
        data: {
          labels,
          datasets: [
            {
              label: t('taxYearSummary.volumeSeries'),
              data: volumes,
              backgroundColor: 'rgba(37, 99, 235, 0.5)',
              borderColor: 'rgba(37, 99, 235, 1)',
              borderWidth: 1,
              yAxisID: 'y',
            },
            {
              label: t('taxYearSummary.taxSeries'),
              data: taxes,
              type: 'line',
              borderColor: 'rgba(234, 179, 8, 1)',
              backgroundColor: 'rgba(250, 204, 21, 0.45)',
              borderWidth: 2,
              tension: 0.2,
              yAxisID: 'y1',
            },
          ],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: 'index', intersect: false },
          scales: {
            y: {
              beginAtZero: true,
              title: { display: true, text: t('taxYearSummary.volumeSeries') },
            },
            y1: {
              position: 'right',
              beginAtZero: true,
              grid: { drawOnChartArea: false },
              title: { display: true, text: t('taxYearSummary.taxSeries') },
            },
          },
          plugins: {
            legend: { position: 'top' },
          },
        },
      })
  } else {
      chartInstance.data.labels = labels
      const volumeDataset = chartInstance.data.datasets[0] as { label?: string; data?: number[] }
      const taxDataset = chartInstance.data.datasets[1] as { label?: string; data?: number[] }
      volumeDataset.label = t('taxYearSummary.volumeSeries')
      volumeDataset.data = volumes
      taxDataset.label = t('taxYearSummary.taxSeries')
      taxDataset.data = taxes
      const opts = chartInstance.options as {
        scales?: {
          y?: { title?: { text?: string } }
          y1?: { title?: { text?: string } }
        }
      }
      if (opts.scales?.y?.title) opts.scales.y.title.text = t('taxYearSummary.volumeSeries')
      if (opts.scales?.y1?.title) opts.scales.y1.title.text = t('taxYearSummary.taxSeries')
      chartInstance.update()
    }
  })
}

watch(locale, () => {
  batchBreakdown.value = batchBreakdown.value.map((group) => ({
    ...group,
    label: monthLabel(group.month),
  }))
  updateChart()
})

watch(selectedYear, async (newVal, oldVal) => {
  if (newVal !== oldVal) await loadSummary()
})

onMounted(async () => {
  await ensureTenant()
  await Promise.all([loadCategories(), loadTaxRates(), loadUoms()])
  await loadSummary()
})

onBeforeUnmount(() => {
  if (chartInstance) {
    chartInstance.destroy()
    chartInstance = null
  }
})
</script>
