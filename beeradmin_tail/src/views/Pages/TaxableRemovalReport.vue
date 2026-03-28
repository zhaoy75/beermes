<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen w-full space-y-6 bg-white p-4 text-gray-900">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('taxableRemovalReport.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('taxableRemovalReport.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button
            class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading || exportLoading || businessYearDetailRows.length === 0"
            @click="exportExcel"
          >
            {{ exportLoading ? t('taxableRemovalReport.export.exporting') : t('taxableRemovalReport.export.button') }}
          </button>
          <button
            class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="loadReport"
          >
            {{ t('common.refresh') }}
          </button>
          <a
            v-if="exportDownloadUrl && exportFileName"
            :href="exportDownloadUrl"
            :download="exportFileName"
            class="text-sm text-blue-700 underline underline-offset-2"
          >
            {{ exportFileName }}
          </a>
        </div>
      </header>

      <section class="space-y-4 rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
        <section class="rounded-xl border border-gray-200 bg-gray-50/70 p-4">
          <form class="grid grid-cols-1 gap-4 md:grid-cols-3" @submit.prevent>
            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('taxableRemovalReport.filters.businessYear') }}
              </label>
              <select
                v-model.number="filters.businessYear"
                class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
              >
                <option v-for="year in businessYearOptions" :key="year" :value="year">
                  {{ year }}
                </option>
              </select>
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('taxableRemovalReport.filters.month') }}
              </label>
              <select
                v-model="filters.month"
                class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
              >
                <option value="">{{ t('taxableRemovalReport.defaults.allMonths') }}</option>
                <option v-for="month in monthOptions" :key="month" :value="String(month)">
                  {{ month }}
                </option>
              </select>
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('taxableRemovalReport.filters.liquorCode') }}
              </label>
              <select
                v-model="filters.liquorCode"
                class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
              >
                <option value="">{{ t('taxableRemovalReport.defaults.allLiquorCodes') }}</option>
                <option v-for="option in liquorCodeOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
          </form>
        </section>

        <section class="space-y-3 rounded-xl border border-gray-200 bg-gray-50/40 p-4">
          <div>
            <h2 class="text-base font-semibold text-gray-900">
              {{ t('taxableRemovalReport.summary.title') }}
            </h2>
            <p class="text-sm text-gray-500">
              {{ t('taxableRemovalReport.summary.subtitle') }}
            </p>
          </div>

          <section class="overflow-x-auto rounded-lg border border-gray-200 bg-white">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                <tr>
                  <th class="px-3 py-2 text-left">{{ t('taxableRemovalReport.summary.columns.liquorCode') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('taxableRemovalReport.summary.columns.abv') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('taxableRemovalReport.summary.columns.quantityMl') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('taxableRemovalReport.summary.columns.packageCount') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('taxableRemovalReport.summary.columns.taxRate') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('taxableRemovalReport.summary.columns.taxAmount') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 bg-white">
                <tr v-if="loading">
                  <td colspan="6" class="px-3 py-8 text-center text-gray-500">
                    {{ t('common.loading') }}
                  </td>
                </tr>
                <tr v-else-if="summaryRows.length === 0">
                  <td colspan="6" class="px-3 py-8 text-center text-gray-500">
                    {{ t('common.noData') }}
                  </td>
                </tr>
                <tr v-for="row in summaryRows" v-else :key="row.key" class="hover:bg-gray-50">
                  <td class="px-3 py-2 text-gray-700">{{ row.liquorCodeLabel || row.liquorCode || '—' }}</td>
                  <td class="px-3 py-2 text-right">{{ formatAbv(row.abv) }}</td>
                  <td class="px-3 py-2 text-right">{{ formatQuantityMl(row.quantityMl) }}</td>
                  <td class="px-3 py-2 text-right">{{ formatNumberValue(row.packageCount) }}</td>
                  <td class="px-3 py-2 text-right">{{ formatTaxRateSummary(row.taxRates) }}</td>
                  <td class="px-3 py-2 text-right">{{ formatCurrency(row.taxAmount) }}</td>
                </tr>
              </tbody>
            </table>
          </section>
        </section>

        <section class="space-y-3 rounded-xl border border-gray-200 bg-gray-50/40 p-4">
          <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
            <div>
              <h2 class="text-base font-semibold text-gray-900">
                {{ t('taxableRemovalReport.table.title') }}
              </h2>
              <p class="text-sm text-gray-500">
                {{ t('taxableRemovalReport.results.count', { count: filteredRows.length }) }}
              </p>
            </div>
          </div>

          <section class="overflow-x-auto rounded-lg border border-gray-200 bg-white">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                <tr>
                  <th class="px-3 py-2 text-left">{{ t('taxableRemovalReport.table.columns.item') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('taxableRemovalReport.table.columns.brand') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('taxableRemovalReport.table.columns.abv') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('taxableRemovalReport.table.columns.movementAt') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('taxableRemovalReport.table.columns.container') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('taxableRemovalReport.table.columns.quantityMl') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('taxableRemovalReport.table.columns.unitPrice') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('taxableRemovalReport.table.columns.amount') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('taxableRemovalReport.table.columns.removalType') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('taxableRemovalReport.table.columns.destinationAddress') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('taxableRemovalReport.table.columns.destinationName') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('taxableRemovalReport.table.columns.lotNo') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('taxableRemovalReport.table.columns.notes') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 bg-white">
                <tr v-if="loading">
                  <td colspan="13" class="px-3 py-8 text-center text-gray-500">
                    {{ t('common.loading') }}
                  </td>
                </tr>
                <tr v-else-if="filteredRows.length === 0">
                  <td colspan="13" class="px-3 py-8 text-center text-gray-500">
                    {{ t('common.noData') }}
                  </td>
                </tr>
                <tr v-for="row in filteredRows" v-else :key="row.id" class="hover:bg-gray-50">
                  <td class="px-3 py-2 text-gray-700">{{ row.itemLabel || row.liquorCode || '—' }}</td>
                  <td class="px-3 py-2 text-gray-700">{{ row.brandName || '—' }}</td>
                  <td class="px-3 py-2 text-right">{{ formatAbv(row.abv) }}</td>
                  <td class="px-3 py-2 text-xs text-gray-500">{{ formatDateTime(row.movementAt) }}</td>
                  <td class="px-3 py-2 text-gray-700">{{ row.containerLabel || '—' }}</td>
                  <td class="px-3 py-2 text-right">{{ formatQuantityMl(row.quantityMl) }}</td>
                  <td class="px-3 py-2 text-right">—</td>
                  <td class="px-3 py-2 text-right">—</td>
                  <td class="px-3 py-2 text-gray-700">{{ row.removalTypeLabel || '—' }}</td>
                  <td class="px-3 py-2 text-gray-700">{{ row.destinationAddress || '—' }}</td>
                  <td class="px-3 py-2 text-gray-700">{{ row.destinationName || '—' }}</td>
                  <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.lotNo || '—' }}</td>
                  <td class="px-3 py-2 text-gray-700">{{ row.notes || '—' }}</td>
                </tr>
              </tbody>
            </table>
          </section>
        </section>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue3-toastify'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { buildAlcoholTypeLabelMap, resolveAlcoholTypeLabel as resolveAlcoholTypeRegistryLabel } from '@/lib/alcoholTypeRegistry'
import { createWorkbookBlob, type WorkbookCell, type WorkbookCellValue, type WorkbookSheet } from '@/lib/fillingReportExport'
import { supabase } from '@/lib/supabase'

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
  recipe: JsonMap | JsonMap[] | null
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

type DetailRow = {
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

type SummaryRow = {
  key: string
  liquorCode: string | null
  liquorCodeLabel: string | null
  abv: number | null
  quantityMl: number
  packageCount: number
  taxRates: number[]
  taxAmount: number
}

type LiquorCodeOption = {
  value: string
  label: string
}

const { t, locale } = useI18n()

const pageTitle = computed(() => t('taxableRemovalReport.title'))
const loading = ref(false)
const exportLoading = ref(false)
const exportFileName = ref('')
const exportDownloadUrl = ref('')
const tenantId = ref('')
const detailRows = ref<DetailRow[]>([])
const uomMap = ref(new Map<string, string>())
const packageMap = ref(new Map<string, PackageRow>())
const siteMap = ref(new Map<string, SiteRow>())
const alcoholTypeLabelMap = ref(new Map<string, string>())

const filters = reactive({
  businessYear: getCurrentBusinessYear(),
  month: '',
  liquorCode: '',
})

const monthOptions = Array.from({ length: 12 }, (_, index) => index + 1)

const businessYearOptions = computed(() => {
  const years = new Set<number>([getCurrentBusinessYear(), filters.businessYear])
  detailRows.value.forEach((row) => {
    const year = businessYearForDate(row.movementAt)
    if (year != null) years.add(year)
  })
  const sorted = Array.from(years).sort((a, b) => b - a)
  if (sorted.length >= 6) return sorted
  const maxYear = sorted[0] ?? getCurrentBusinessYear()
  const minYear = sorted[sorted.length - 1] ?? getCurrentBusinessYear()
  for (let year = maxYear; year >= maxYear - 4; year -= 1) years.add(year)
  for (let year = minYear + 1; year <= maxYear; year += 1) years.add(year)
  return Array.from(years).sort((a, b) => b - a)
})

const liquorCodeOptions = computed<LiquorCodeOption[]>(() =>
  Array.from(
    new Set(
      detailRows.value
        .map((row) => (row.liquorCode ?? '').trim())
        .filter((value) => value.length > 0),
    ),
  )
    .map((value) => ({
      value,
      label: resolveAlcoholTypeLabel(value) ?? value,
    }))
    .sort((a, b) => {
      const labelCompare = a.label.localeCompare(b.label)
      if (labelCompare !== 0) return labelCompare
      return a.value.localeCompare(b.value)
    }),
)

const filteredRows = computed(() =>
  detailRows.value
    .filter((row) => matchesBusinessYear(row.movementAt, filters.businessYear))
    .filter((row) => {
      if (!filters.month) return true
      const date = safeDate(row.movementAt)
      if (!date) return false
      return date.getMonth() + 1 === Number(filters.month)
    })
    .filter((row) => {
      if (!filters.liquorCode) return true
      return (row.liquorCode ?? '') === filters.liquorCode
    })
    .sort(compareDetailRows),
)

const businessYearDetailRows = computed(() =>
  detailRows.value
    .filter((row) => matchesBusinessYear(row.movementAt, filters.businessYear))
    .sort(compareDetailRows),
)

const summaryRows = computed<SummaryRow[]>(() => {
  const map = new Map<string, SummaryRow>()
  detailRows.value
    .filter((row) => matchesBusinessYear(row.movementAt, filters.businessYear))
    .forEach((row) => {
      const abvKey = row.abv == null ? '' : String(row.abv)
      const key = `${row.liquorCode ?? ''}__${abvKey}`
      if (!map.has(key)) {
        map.set(key, {
          key,
          liquorCode: row.liquorCode,
          liquorCodeLabel: resolveAlcoholTypeLabel(row.liquorCode) ?? row.liquorCode ?? null,
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
})

function getCurrentBusinessYear(date = new Date()) {
  return date.getMonth() + 1 >= 4 ? date.getFullYear() : date.getFullYear() - 1
}

function businessYearForDate(value: string | null | undefined) {
  const date = safeDate(value)
  if (!date) return null
  return date.getMonth() + 1 >= 4 ? date.getFullYear() : date.getFullYear() - 1
}

function matchesBusinessYear(value: string | null | undefined, businessYear: number) {
  const year = businessYearForDate(value)
  return year === businessYear
}

function safeDate(value: string | null | undefined) {
  if (!value) return null
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
}

function compareDetailRows(a: DetailRow, b: DetailRow) {
  const aTime = a.movementAt ? Date.parse(a.movementAt) : 0
  const bTime = b.movementAt ? Date.parse(b.movementAt) : 0
  if (aTime !== bTime) return bTime - aTime
  const movementCompare = a.movementId.localeCompare(b.movementId)
  if (movementCompare !== 0) return movementCompare
  return a.lineNo - b.lineNo
}

function toNumber(value: unknown): number | null {
  if (value == null) return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function extractErrorMessage(err: unknown) {
  if (!err) return ''
  if (typeof err === 'string') return err
  if (err instanceof Error) return err.message
  const record = err as Record<string, unknown>
  if (typeof record.message === 'string') return record.message
  return ''
}

function resolveMetaString(meta: JsonMap | null | undefined, key: string) {
  const value = meta?.[key]
  return typeof value === 'string' && value.trim() ? value.trim() : null
}

function resolveMetaNumber(meta: JsonMap | null | undefined, key: string) {
  return toNumber(meta?.[key])
}

function resolveBatchLabel(meta: JsonMap | null | undefined) {
  return resolveMetaString(meta, 'batch_label') ?? resolveMetaString(meta, 'name')
}

function resolveLocalizedName(value: Record<string, string> | null | undefined) {
  if (!value) return ''
  const exact = value[locale.value]
  if (typeof exact === 'string' && exact.trim()) return exact.trim()
  const fallback = Object.values(value).find((entry) => typeof entry === 'string' && entry.trim())
  return typeof fallback === 'string' ? fallback.trim() : ''
}

function convertToLiters(quantity: number | null, uomCode: string | null | undefined) {
  if (quantity == null || Number.isNaN(quantity)) return null
  switch (uomCode) {
    case 'L':
    case null:
    case undefined:
      return quantity
    case 'mL':
      return quantity / 1000
    case 'kL':
      return quantity * 1000
    case 'gal_us':
      return quantity * 3.78541
    default:
      return quantity
  }
}

function quantityMlFromLiters(quantityLiters: number | null) {
  if (quantityLiters == null) return null
  return quantityLiters * 1000
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  const date = safeDate(value)
  if (!date) return value
  return date.toLocaleString(locale.value)
}

function formatNumberValue(value: number | null | undefined, digits = 0) {
  if (value == null || Number.isNaN(value)) return '—'
  return new Intl.NumberFormat(locale.value, {
    minimumFractionDigits: digits,
    maximumFractionDigits: digits,
  }).format(value)
}

function formatAbv(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return new Intl.NumberFormat(locale.value, {
    minimumFractionDigits: 1,
    maximumFractionDigits: 2,
  }).format(value)
}

function formatQuantityMl(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return new Intl.NumberFormat(locale.value, {
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(Math.round(value))
}

function formatCurrency(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return new Intl.NumberFormat(locale.value, {
    style: 'currency',
    currency: 'JPY',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(Math.round(value))
}

function formatTaxRateSummary(values: number[]) {
  if (!values.length) return '—'
  return values.map((value) => `${formatNumberValue(value)}/kl`).join(', ')
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

function clearExportDownload() {
  if (exportDownloadUrl.value) URL.revokeObjectURL(exportDownloadUrl.value)
  exportDownloadUrl.value = ''
  exportFileName.value = ''
}

function borderedRow(values: WorkbookCellValue[]): WorkbookCell[] {
  return values.map((value) => ({
    style: 'border',
    value,
  }))
}

function buildSummarySheetRows(createdAtLabel: string): WorkbookCell[][] {
  const header: WorkbookCellValue[] = [
    t('taxableRemovalReport.summary.columns.liquorCode'),
    t('taxableRemovalReport.summary.columns.abv'),
    t('taxableRemovalReport.summary.columns.quantityMl'),
    t('taxableRemovalReport.summary.columns.packageCount'),
    t('taxableRemovalReport.summary.columns.taxRate'),
    t('taxableRemovalReport.summary.columns.taxAmount'),
  ]

  const rows = summaryRows.value.map<WorkbookCell[]>((row) =>
    borderedRow([
      row.liquorCodeLabel || row.liquorCode || '—',
      formatAbv(row.abv),
      formatQuantityMl(row.quantityMl),
      formatNumberValue(row.packageCount),
      formatTaxRateSummary(row.taxRates),
      formatCurrency(row.taxAmount),
    ]),
  )

  return [
    [t('taxableRemovalReport.summary.title')],
    [t('taxableRemovalReport.export.generatedAt'), createdAtLabel],
    [t('taxableRemovalReport.export.businessYear'), filters.businessYear],
    [],
    borderedRow(header),
    ...rows,
  ]
}

function buildMonthlySheetRows(month: number, createdAtLabel: string): WorkbookCell[][] {
  const calendarYear = calendarYearForBusinessYearMonth(filters.businessYear, month)
  const monthRows = businessYearDetailRows.value.filter((row) => {
    const date = safeDate(row.movementAt)
    if (!date) return false
    return date.getMonth() + 1 === month
  })

  const header: WorkbookCellValue[] = [
    t('taxableRemovalReport.table.columns.item'),
    t('taxableRemovalReport.table.columns.brand'),
    t('taxableRemovalReport.table.columns.abv'),
    t('taxableRemovalReport.table.columns.movementAt'),
    t('taxableRemovalReport.table.columns.container'),
    t('taxableRemovalReport.table.columns.quantityMl'),
    t('taxableRemovalReport.table.columns.unitPrice'),
    t('taxableRemovalReport.table.columns.amount'),
    t('taxableRemovalReport.table.columns.removalType'),
    t('taxableRemovalReport.table.columns.destinationAddress'),
    t('taxableRemovalReport.table.columns.destinationName'),
    t('taxableRemovalReport.table.columns.lotNo'),
    t('taxableRemovalReport.table.columns.notes'),
  ]

  const rows = monthRows.map<WorkbookCell[]>((row) =>
    borderedRow([
      row.itemLabel || row.liquorCode || '—',
      row.brandName || '—',
      formatAbv(row.abv),
      formatDateTime(row.movementAt),
      row.containerLabel || '—',
      formatQuantityMl(row.quantityMl),
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
    [t('taxableRemovalReport.table.title')],
    [t('taxableRemovalReport.export.generatedAt'), createdAtLabel],
    [t('taxableRemovalReport.export.businessYear'), filters.businessYear],
    [t('taxableRemovalReport.export.monthSheetLabel'), `${calendarYear}-${pad2(month)}`],
    [],
    borderedRow(header),
    ...rows,
  ]
}

function buildExportSheets(createdAtLabel: string): WorkbookSheet[] {
  return [
    {
      name: t('taxableRemovalReport.export.summarySheetName'),
      rows: buildSummarySheetRows(createdAtLabel),
    },
    ...buildMonthSheetOrder().map((month) => {
      const calendarYear = calendarYearForBusinessYearMonth(filters.businessYear, month)
      return {
        name: `${calendarYear}-${pad2(month)}`,
        rows: buildMonthlySheetRows(month, createdAtLabel),
      }
    }),
  ]
}

function exportExcel() {
  if (!businessYearDetailRows.value.length) {
    toast.error(t('taxableRemovalReport.export.noData'))
    return
  }

  try {
    exportLoading.value = true
    const createdAt = new Date()
    const fileName = `課税移出一覧表_${filters.businessYear}.xlsx`
    const blob = createWorkbookBlob({
      creator: 'beeradmin_tail',
      createdAtIso: createdAt.toISOString(),
      sheets: buildExportSheets(createdAt.toLocaleString(locale.value)),
    })
    const url = URL.createObjectURL(blob)
    clearExportDownload()
    exportFileName.value = fileName
    exportDownloadUrl.value = url
  } catch (err) {
    clearExportDownload()
    toast.error(extractErrorMessage(err) || t('taxableRemovalReport.export.failed'))
  } finally {
    exportLoading.value = false
  }
}

function normalizedCode(value: string | null | undefined) {
  return (value ?? '').trim()
}

function resolveAlcoholTypeLabel(code: string | null | undefined) {
  const normalized = normalizedCode(code)
  if (!normalized) return null
  return resolveAlcoholTypeRegistryLabel(alcoholTypeLabelMap.value, normalized) ?? null
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

function packageLabel(row: PackageRow | undefined) {
  if (!row) return ''
  return row.package_code?.trim() || resolveLocalizedName(row.name_i18n) || ''
}

function packageUnitLiters(row: PackageRow | undefined) {
  if (!row) return null
  const size = toNumber(row.unit_volume)
  const uomCode = row.volume_uom ? uomMap.value.get(row.volume_uom) ?? row.volume_uom : null
  return convertToLiters(size, uomCode)
}

function linePackageCount(line: MovementLineRow) {
  return toNumber(line.meta?.package_qty) ?? toNumber(line.unit)
}

function lineQuantityMl(line: MovementLineRow, pkg: PackageRow | undefined) {
  const rawQty = toNumber(line.qty)
  const uomCode = line.uom_id ? uomMap.value.get(line.uom_id) ?? line.uom_id : null
  const liters = convertToLiters(rawQty, uomCode)
  if (liters != null) return quantityMlFromLiters(liters)

  const count = linePackageCount(line)
  const unitLiters = packageUnitLiters(pkg)
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
  return (quantityMl / 1000000) * taxRate
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const resolved = data.user?.app_metadata?.tenant_id as string | undefined
  if (!resolved) throw new Error('Tenant not resolved in session')
  tenantId.value = resolved
  return resolved
}

async function loadUoms() {
  const { data, error } = await supabase.from('mst_uom').select('id, code').order('code', { ascending: true })
  if (error) throw error
  const next = new Map<string, string>()
  ;((data ?? []) as UomLookupRow[]).forEach((row) => {
    if (!row?.id || !row?.code) return
    next.set(String(row.id), String(row.code))
  })
  uomMap.value = next
}

async function loadSites() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_sites')
    .select('id, name, address')
    .eq('tenant_id', tenant)
  if (error) throw error
  const next = new Map<string, SiteRow>()
  ;((data ?? []) as SiteRow[]).forEach((row) => {
    next.set(String(row.id), {
      id: String(row.id),
      name: typeof row.name === 'string' ? row.name : null,
      address: row.address ?? null,
    })
  })
  siteMap.value = next
}

async function loadPackages() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_package')
    .select('id, package_code, name_i18n, unit_volume, volume_uom, is_active')
    .eq('tenant_id', tenant)
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
  packageMap.value = next
}

async function loadAlcoholTypes() {
  const { data, error } = await supabase
    .from('registry_def')
    .select('def_id, def_key, spec')
    .eq('kind', 'alcohol_type')
    .eq('is_active', true)
  if (error) throw error
  alcoholTypeLabelMap.value = buildAlcoholTypeLabelMap((data ?? []) as AlcoholTypeRegistryRow[])
}

async function loadBatchInfo(batchIds: string[]) {
  const infoMap = new Map<string, BatchInfo>()
  if (batchIds.length === 0) return infoMap

  const tenant = await ensureTenant()
  const uniqueIds = Array.from(new Set(batchIds))
  const attrIdToCode = new Map<string, string>()
  const attrIds: number[] = []
  const attrValueByBatch = new Map<string, { liquorCode: string | null; abv: number | null }>()

  try {
    const { data: attrDefs, error: attrDefError } = await supabase
      .from('attr_def')
      .select('attr_id, code')
      .eq('domain', 'batch')
      .in('code', ['beer_category', 'target_abv'])
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

        if (code === 'target_abv') {
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
    .select(
      'id, batch_code, batch_label, product_name, meta, recipe_id, recipe:recipe_id ( category, target_abv )',
    )
    .eq('tenant_id', tenant)
    .in('id', uniqueIds)
  if (error) throw error

  ;((data ?? []) as BatchRow[]).forEach((row) => {
    const attr = attrValueByBatch.get(row.id)
    const recipe = Array.isArray(row.recipe) ? row.recipe[0] : row.recipe
    const meta =
      row.meta && typeof row.meta === 'object' && !Array.isArray(row.meta)
        ? (row.meta as JsonMap)
        : null

    infoMap.set(String(row.id), {
      batchCode: row.batch_code ?? null,
      brandName: row.product_name ?? row.batch_label ?? resolveBatchLabel(meta) ?? null,
      liquorCode:
        attr?.liquorCode ??
        (typeof recipe?.category === 'string' ? recipe.category : null) ??
        resolveMetaString(meta, 'beer_category') ??
        resolveMetaString(meta, 'category') ??
        null,
      abv:
        attr?.abv ??
        toNumber(recipe?.target_abv) ??
        resolveMetaNumber(meta, 'target_abv') ??
        null,
    })
  })

  return infoMap
}

async function loadLotInfo(lotIds: string[]) {
  const map = new Map<string, string>()
  if (lotIds.length === 0) return map
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('lot')
    .select('id, lot_no')
    .eq('tenant_id', tenant)
    .in('id', Array.from(new Set(lotIds)))
  if (error) throw error
  ;((data ?? []) as LotRow[]).forEach((row) => {
    if (!row?.id) return
    map.set(String(row.id), typeof row.lot_no === 'string' ? row.lot_no : '')
  })
  return map
}

async function loadReferenceData() {
  await Promise.all([loadUoms(), loadSites(), loadPackages(), loadAlcoholTypes()])
}

async function loadReport() {
  try {
    loading.value = true
    clearExportDownload()
    await loadReferenceData()

    const tenant = await ensureTenant()
    const { data: headerData, error: headerError } = await supabase
      .from('inv_movements')
      .select('id, doc_no, movement_at, status, dest_site_id, notes, meta')
      .eq('tenant_id', tenant)
      .neq('status', 'void')
      .order('movement_at', { ascending: false })

    if (headerError) throw headerError

    const headers = ((headerData ?? []) as MovementHeaderRow[]).filter(isTaxableRemoval)
    if (headers.length === 0) {
      detailRows.value = []
      return
    }

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

    const [batchInfoMap, lotInfoMap] = await Promise.all([loadBatchInfo(batchIds), loadLotInfo(lotIds)])

    detailRows.value = lines
      .map<DetailRow | null>((line) => {
        const header = headerMap.get(line.movement_id)
        if (!header) return null

        const pkg = line.package_id ? packageMap.value.get(line.package_id) : undefined
        const batchInfo = line.batch_id ? batchInfoMap.get(line.batch_id) : undefined
        const destination = header.dest_site_id ? siteMap.value.get(header.dest_site_id) : undefined
        const liquorCode = batchInfo?.liquorCode ?? resolveMetaString(line.meta, 'beer_category')
        const itemLabel = resolveAlcoholTypeLabel(liquorCode)
        const quantityMl = lineQuantityMl(line, pkg)
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
          containerLabel: packageLabel(pkg) || null,
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
          removalTypeLabel: t('taxableRemovalReport.defaults.taxableRemovalType'),
        }
      })
      .filter((row): row is DetailRow => row !== null)
      .sort(compareDetailRows)
  } catch (err) {
    detailRows.value = []
    toast.error(extractErrorMessage(err) || t('taxableRemovalReport.errors.loadFailed'))
  } finally {
    loading.value = false
  }
}

onMounted(() => {
  loadReport()
})

watch(
  () => filters.businessYear,
  () => {
    clearExportDownload()
  },
)

onUnmounted(() => {
  clearExportDownload()
})
</script>
