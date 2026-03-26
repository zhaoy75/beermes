<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen w-full space-y-6 bg-white p-4 text-gray-900">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('fillingReport.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('fillingReport.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button
            class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-50 disabled:opacity-50"
            :disabled="reportLoading"
            @click="loadReport"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="space-y-4 rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
        <section class="rounded-xl border border-gray-200 bg-gray-50/70 p-4">
          <form class="grid grid-cols-1 gap-4 md:grid-cols-3" @submit.prevent>
            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('fillingReport.filters.businessYear') }}
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
                {{ t('fillingReport.filters.month') }}
              </label>
              <select
                v-model="filters.month"
                class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
              >
                <option value="">{{ t('fillingReport.defaults.allMonths') }}</option>
                <option v-for="month in monthOptions" :key="month" :value="String(month)">
                  {{ month }}
                </option>
              </select>
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('fillingReport.filters.liquorCode') }}
              </label>
              <select
                v-model="filters.liquorCode"
                class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
              >
                <option value="">{{ t('fillingReport.defaults.allLiquorCodes') }}</option>
                <option v-for="code in liquorCodeOptions" :key="code" :value="code">
                  {{ code }}
                </option>
              </select>
            </div>
          </form>
        </section>

        <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <p class="text-sm text-gray-500">
            {{ t('fillingReport.results.count', { count: sortedRows.length }) }}
          </p>
        </div>

        <section class="overflow-x-auto rounded-lg border border-gray-200">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="px-3 py-2 text-left">
                  <button class="font-medium" type="button" @click="toggleSort('batchCode')">
                    {{ t('fillingReport.table.batchCode') }} {{ sortIndicator('batchCode') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-left">
                  <button class="font-medium" type="button" @click="toggleSort('name')">
                    {{ t('fillingReport.table.name') }} {{ sortIndicator('name') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-left">
                  <button class="font-medium" type="button" @click="toggleSort('latestFillingAt')">
                    {{ t('fillingReport.table.latestFillingAt') }} {{ sortIndicator('latestFillingAt') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-right">
                  <button class="font-medium" type="button" @click="toggleSort('totalVolume')">
                    {{ t('fillingReport.table.totalVolume') }} {{ sortIndicator('totalVolume') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-left">
                  <button class="font-medium" type="button" @click="toggleSort('liquorCode')">
                    {{ t('fillingReport.table.liquorCode') }} {{ sortIndicator('liquorCode') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-right">
                  <button class="font-medium" type="button" @click="toggleSort('abv')">
                    {{ t('fillingReport.table.abv') }} {{ sortIndicator('abv') }}
                  </button>
                </th>
                <th
                  v-for="packageCode in packageColumns"
                  :key="`package-header-${packageCode}`"
                  class="px-3 py-2 text-right"
                >
                  <button class="font-medium" type="button" @click="toggleSort(packageSortKey(packageCode))">
                    {{ packageCode }} {{ sortIndicator(packageSortKey(packageCode)) }}
                  </button>
                </th>
                <th class="px-3 py-2 text-right">
                  <button class="font-medium" type="button" @click="toggleSort('sampleVolume')">
                    {{ t('fillingReport.table.sampleVolume') }} {{ sortIndicator('sampleVolume') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-right">
                  <button class="font-medium" type="button" @click="toggleSort('tankLeftVolume')">
                    {{ t('fillingReport.table.tankLeftVolume') }} {{ sortIndicator('tankLeftVolume') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-right">
                  <button class="font-medium" type="button" @click="toggleSort('lossVolume')">
                    {{ t('fillingReport.table.lossVolume') }} {{ sortIndicator('lossVolume') }}
                  </button>
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 bg-white">
              <tr v-if="reportLoading">
                <td :colspan="tableColumnCount" class="px-3 py-8 text-center text-gray-500">
                  {{ t('common.loading') }}
                </td>
              </tr>
              <tr v-else-if="sortedRows.length === 0">
                <td :colspan="tableColumnCount" class="px-3 py-8 text-center text-gray-500">
                  {{ t('common.noData') }}
                </td>
              </tr>
              <tr
                v-for="row in sortedRows"
                v-else
                :key="row.id"
                :class="selectedBatchId === row.batchId ? 'bg-blue-50' : 'hover:bg-gray-50'"
              >
                <td class="px-3 py-2">
                  <button
                    type="button"
                    class="font-mono text-xs text-blue-700 underline-offset-2 hover:underline"
                    @click="selectBatch(row.batchId)"
                  >
                    {{ row.batchCode || '—' }}
                  </button>
                </td>
                <td class="px-3 py-2">{{ row.displayName || '—' }}</td>
                <td class="px-3 py-2 text-xs text-gray-500">{{ formatDateTime(row.latestFillingAt) }}</td>
                <td class="px-3 py-2 text-right">{{ formatVolumeValue(row.totalVolume) }}</td>
                <td class="px-3 py-2 font-mono text-xs text-gray-600">{{ row.liquorCode || '—' }}</td>
                <td class="px-3 py-2 text-right">{{ formatAbv(row.abv) }}</td>
                <td
                  v-for="packageCode in packageColumns"
                  :key="`package-row-${row.id}-${packageCode}`"
                  class="px-3 py-2 text-right"
                >
                  {{ formatPackageNumber(row.packageNumbers[packageCode]) }}
                </td>
                <td class="px-3 py-2 text-right">{{ formatVolumeValue(row.sampleVolume) }}</td>
                <td class="px-3 py-2 text-right">{{ formatVolumeValue(row.tankLeftVolume) }}</td>
                <td class="px-3 py-2 text-right">{{ formatVolumeValue(row.lossVolume) }}</td>
              </tr>
            </tbody>
          </table>
        </section>

        <section class="space-y-4 rounded-xl border border-gray-200 bg-gray-50/40 p-4">
          <div>
            <h2 class="text-base font-semibold text-gray-900">{{ t('fillingReport.detail.title') }}</h2>
            <p class="text-sm text-gray-500">{{ t('fillingReport.detail.subtitle') }}</p>
          </div>

          <div v-if="reportLoading" class="rounded-lg border border-dashed border-gray-300 bg-white px-4 py-8 text-center text-sm text-gray-500">
            {{ t('common.loading') }}
          </div>
          <div
            v-else-if="sortedRows.length === 0"
            class="rounded-lg border border-dashed border-gray-300 bg-white px-4 py-8 text-center text-sm text-gray-500"
          >
            {{ t('common.noData') }}
          </div>
          <div
            v-else-if="!selectedReportRow"
            class="rounded-lg border border-dashed border-gray-300 bg-white px-4 py-8 text-center text-sm text-gray-500"
          >
            {{ t('fillingReport.detail.selectPrompt') }}
          </div>
          <template v-else>
            <dl class="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-5">
              <div class="rounded-lg border border-gray-200 bg-white p-3">
                <dt class="text-xs uppercase text-gray-500">{{ t('fillingReport.table.batchCode') }}</dt>
                <dd class="mt-1 font-mono text-sm text-gray-700">{{ selectedReportRow.batchCode || '—' }}</dd>
              </div>
              <div class="rounded-lg border border-gray-200 bg-white p-3">
                <dt class="text-xs uppercase text-gray-500">{{ t('fillingReport.table.name') }}</dt>
                <dd class="mt-1 text-sm text-gray-700">{{ selectedReportRow.displayName || '—' }}</dd>
              </div>
              <div class="rounded-lg border border-gray-200 bg-white p-3">
                <dt class="text-xs uppercase text-gray-500">{{ t('fillingReport.table.liquorCode') }}</dt>
                <dd class="mt-1 font-mono text-sm text-gray-700">{{ selectedReportRow.liquorCode || '—' }}</dd>
              </div>
              <div class="rounded-lg border border-gray-200 bg-white p-3">
                <dt class="text-xs uppercase text-gray-500">{{ t('fillingReport.table.abv') }}</dt>
                <dd class="mt-1 text-sm text-gray-700">{{ formatAbv(selectedReportRow.abv) }}</dd>
              </div>
              <div class="rounded-lg border border-gray-200 bg-white p-3">
                <dt class="text-xs uppercase text-gray-500">{{ t('fillingReport.detail.fillingTank') }}</dt>
                <dd class="mt-1 text-sm text-gray-700">{{ formatTankSummary(selectedReportRow.fillingTanks) }}</dd>
              </div>
            </dl>

            <section class="overflow-x-auto rounded-lg border border-gray-200 bg-white">
              <table class="min-w-full divide-y divide-gray-200 text-sm">
                <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                  <tr>
                    <th class="px-3 py-2 text-left">{{ t('fillingReport.detail.table.date') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('fillingReport.detail.table.beforeFilling') }}</th>
                    <th
                      v-for="packageCode in detailPackageColumns"
                      :key="`detail-package-header-${packageCode}`"
                      class="px-3 py-2 text-right"
                    >
                      {{ packageCode }}
                    </th>
                    <th class="px-3 py-2 text-right">{{ t('fillingReport.detail.table.sampleVolume') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('fillingReport.detail.table.totalQuantity') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('fillingReport.detail.table.tankLeftVolume') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('fillingReport.detail.table.lossVolume') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100 bg-white">
                  <tr v-if="selectedDetailRows.length === 0">
                    <td :colspan="detailTableColumnCount" class="px-3 py-8 text-center text-gray-500">
                      {{ t('common.noData') }}
                    </td>
                  </tr>
                  <tr v-for="detailRow in selectedDetailRows" v-else :key="detailRow.id" class="hover:bg-gray-50">
                    <td class="px-3 py-2 text-xs text-gray-500">{{ formatDateTime(detailRow.movementAt) }}</td>
                    <td class="px-3 py-2">
                      <div class="text-xs text-gray-500">
                        {{ t('fillingReport.detail.depth') }}: {{ formatNumberValue(detailRow.tankFillStartDepth) }}
                      </div>
                      <div class="text-xs text-gray-700">
                        {{ t('fillingReport.detail.quantity') }}: {{ formatVolumeValue(detailRow.tankFillStartVolume) }}
                      </div>
                    </td>
                    <td
                      v-for="packageCode in detailPackageColumns"
                      :key="`detail-package-row-${detailRow.id}-${packageCode}`"
                      class="px-3 py-2 text-right"
                    >
                      {{ formatPackageNumber(detailRow.packageNumbers[packageCode]) }}
                    </td>
                    <td class="px-3 py-2 text-right">{{ formatVolumeValue(detailRow.sampleVolume) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatVolumeValue(detailRow.totalQuantity) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatVolumeValue(detailRow.tankLeftVolume) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatVolumeValue(detailRow.lossVolume) }}</td>
                  </tr>
                </tbody>
              </table>
            </section>
          </template>
        </section>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue3-toastify'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import {
  fillingSampleVolumeFromEvent,
  packingLossFromEvent,
  packingTotalLineVolumeFromEvent,
  type FillingCalculationOptions,
  type FillingHistoryLine,
  type FillingHistoryEvent,
} from '@/lib/batchFilling'
import { supabase } from '@/lib/supabase'
import { formatVolumeNumber } from '@/lib/volumeFormat'

type JsonRecord = Record<string, unknown>

type PackageLookup = {
  packageCode: string
  volumeFix: boolean
  unitVolumeLiters: number | null
}

type PackageRow = {
  id: string
  package_code: string | null
  unit_volume: number | string | null
  volume_uom: string | null
  volume_fix_flg: boolean | null
}

type RegistryRow = {
  def_id: string
  def_key: string | null
}

type AttrDefRow = {
  attr_id: number | string
  code: string
}

type AttrValueRow = {
  entity_id: string
  attr_id: number | string
  value_text: string | null
  value_num: number | string | null
  value_ref_type_id: string | number | null
  value_json: JsonRecord | null
}

type RecipeSummary = {
  category?: string | null
  target_abv?: number | string | null
}

type BatchRow = {
  id: string
  batch_code: string | null
  batch_label: string | null
  product_name: string | null
  actual_yield: number | string | null
  meta: JsonRecord | null
  recipe: RecipeSummary | RecipeSummary[] | null
}

type MovementRow = {
  id: string
  movement_at: string | null
  meta: JsonRecord | null
}

type MovementLineRow = {
  movement_id: string | null
  package_id: string | null
  qty: number | string | null
  unit: number | string | null
  meta: JsonRecord | null
}

type BatchInfo = {
  batchCode: string | null
  displayName: string | null
  actualYield: number | null
  liquorCode: string | null
  abv: number | null
}

type FillingDetailRow = {
  id: string
  batchId: string
  movementAt: string | null
  tankNo: string | null
  tankFillStartDepth: number | null
  tankFillStartVolume: number | null
  packageNumbers: Record<string, number | null>
  sampleVolume: number | null
  totalQuantity: number | null
  tankLeftVolume: number | null
  lossVolume: number | null
}

type FillingReportRow = {
  id: string
  batchId: string
  batchCode: string | null
  displayName: string | null
  latestFillingAt: string | null
  totalVolume: number | null
  liquorCode: string | null
  abv: number | null
  packageNumbers: Record<string, number | null>
  sampleVolume: number | null
  tankLeftVolume: number | null
  lossVolume: number | null
  fillingTanks: string[]
  detailRows: FillingDetailRow[]
}

type AggregatePackageGroup = {
  label: string
  quantity: number | null
}

type AggregateBatchRow = {
  id: string
  batchId: string
  batchCode: string | null
  displayName: string | null
  latestFillingAt: string | null
  totalVolume: number | null
  liquorCode: string | null
  abv: number | null
  packageGroups: Map<string, AggregatePackageGroup>
  sampleVolume: number
  tankLeftVolume: number | null
  lossVolume: number
  lossVolumeKnown: boolean
  detailRows: FillingDetailRow[]
}

const { t, locale } = useI18n()
const pageTitle = computed(() => t('fillingReport.title'))
const reportLoading = ref(false)
const reportRows = ref<FillingReportRow[]>([])
const tenantId = ref('')
const selectedBatchId = ref('')
const filters = reactive({
  businessYear: currentBusinessYear(),
  month: '',
  liquorCode: '',
})
const sortState = reactive<{
  key: string
  direction: 'asc' | 'desc'
}>({
  key: 'latestFillingAt',
  direction: 'desc',
})

const numberFormatter = computed(
  () => new Intl.NumberFormat(locale.value, { minimumFractionDigits: 0, maximumFractionDigits: 3 }),
)

const fillingOptions: FillingCalculationOptions = {
  isPackageVolumeFixed(packageTypeId: string) {
    return packageLookupMap.value.get(packageTypeId)?.volumeFix === true
  },
  resolvePackageUnitVolume(packageTypeId: string) {
    return packageLookupMap.value.get(packageTypeId)?.unitVolumeLiters ?? null
  },
}

const packageLookupMap = ref<Map<string, PackageLookup>>(new Map())
const packageColumns = computed(() => {
  const columns = new Set<string>()
  reportRows.value.forEach((row) => {
    Object.keys(row.packageNumbers).forEach((key) => columns.add(key))
  })
  return Array.from(columns).sort((a, b) => a.localeCompare(b))
})
const tableColumnCount = computed(() => 6 + packageColumns.value.length + 3)
const selectedReportRow = computed(
  () => sortedRows.value.find((row) => row.batchId === selectedBatchId.value) ?? null,
)
const detailPackageColumns = computed(() => {
  const columns = new Set<string>()
  selectedReportRow.value?.detailRows.forEach((row) => {
    Object.keys(row.packageNumbers).forEach((key) => columns.add(key))
  })
  return Array.from(columns).sort((a, b) => a.localeCompare(b))
})
const detailTableColumnCount = computed(() => 2 + detailPackageColumns.value.length + 4)
const businessYearOptions = computed(() => {
  const years = new Set<number>([currentBusinessYear()])
  reportRows.value.forEach((row) => {
    const businessYear = businessYearFromDate(row.latestFillingAt)
    if (businessYear != null) years.add(businessYear)
  })
  return Array.from(years).sort((a, b) => b - a)
})
const liquorCodeOptions = computed(() =>
  Array.from(
    new Set(
      reportRows.value
        .map((row) => (row.liquorCode ?? '').trim())
        .filter((value) => value.length > 0),
    ),
  ).sort((a, b) => a.localeCompare(b)),
)
const monthOptions = Array.from({ length: 12 }, (_, index) => index + 1)
const selectedDetailRows = computed(() =>
  [...(selectedReportRow.value?.detailRows ?? [])].sort((a, b) => {
    const result = compareTimestamp(b.movementAt, a.movementAt)
    return result !== 0 ? result : a.id.localeCompare(b.id)
  }),
)

const filteredRows = computed(() =>
  reportRows.value.filter((row) => {
    if (!matchesBusinessYear(row.latestFillingAt, filters.businessYear)) return false
    if (filters.month && !matchesCalendarMonth(row.latestFillingAt, Number(filters.month))) return false
    if (filters.liquorCode && row.liquorCode !== filters.liquorCode) return false
    return true
  }),
)

const sortedRows = computed(() =>
  [...filteredRows.value].sort((a, b) => {
    const result = compareValues(sortValue(a, sortState.key), sortValue(b, sortState.key))
    if (result !== 0) return sortState.direction === 'asc' ? result : -result
    const fallback = compareValues(sortValue(a, 'latestFillingAt'), sortValue(b, 'latestFillingAt'))
    return fallback !== 0 ? -fallback : (a.batchCode ?? '').localeCompare(b.batchCode ?? '')
  }),
)

function toNumber(value: unknown): number | null {
  if (value == null || value === '') return null
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : null
}

function currentBusinessYear(date = new Date()) {
  const year = date.getFullYear()
  const month = date.getMonth() + 1
  return month >= 4 ? year : year - 1
}

function businessYearFromDate(value: string | null | undefined) {
  if (!value) return null
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return null
  return currentBusinessYear(date)
}

function matchesBusinessYear(value: string | null | undefined, businessYear: number) {
  return businessYearFromDate(value) === businessYear
}

function matchesCalendarMonth(value: string | null | undefined, month: number) {
  if (!value) return false
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return false
  return date.getMonth() + 1 === month
}

function compareValues(a: string | number, b: string | number) {
  if (typeof a === 'number' && typeof b === 'number') return a - b
  return String(a).localeCompare(String(b))
}

function normalizeString(value: string | null | undefined) {
  return (value ?? '').toLowerCase()
}

function isRecord(value: unknown): value is JsonRecord {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function resolveMetaString(meta: JsonRecord | null | undefined, key: string) {
  const value = meta?.[key]
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  return trimmed.length ? trimmed : null
}

function resolveMetaNumber(meta: JsonRecord | null | undefined, key: string) {
  return toNumber(meta?.[key])
}

function resolveBatchLabel(meta: JsonRecord | null | undefined) {
  return resolveMetaString(meta, 'label')
}

function convertToLiters(size: number | null, uomCode: string | null | undefined) {
  if (size == null || Number.isNaN(size)) return null
  switch (uomCode) {
    case 'L':
    case null:
    case undefined:
      return size
    case 'mL':
      return size / 1000
    case 'gal_us':
      return size * 3.78541
    default:
      return size
  }
}

function formatAbv(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return `${numberFormatter.value.format(value)}%`
}

function formatVolumeValue(value: number | null | undefined) {
  return formatVolumeNumber(value, locale.value)
}

function formatPackageNumber(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return numberFormatter.value.format(value)
}

function formatNumberValue(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return numberFormatter.value.format(value)
}

function sortIndicator(key: string) {
  if (sortState.key !== key) return ''
  return sortState.direction === 'asc' ? '^' : 'v'
}

function toggleSort(key: string) {
  if (sortState.key === key) {
    sortState.direction = sortState.direction === 'asc' ? 'desc' : 'asc'
    return
  }
  sortState.key = key
  sortState.direction = key === 'latestFillingAt' ? 'desc' : 'asc'
}

function packageSortKey(packageCode: string) {
  return `package:${packageCode}`
}

function sortValue(row: FillingReportRow, key: string): string | number {
  if (key.startsWith('package:')) {
    const packageCode = key.slice('package:'.length)
    return row.packageNumbers[packageCode] ?? Number.NEGATIVE_INFINITY
  }

  switch (key) {
    case 'batchCode':
      return normalizeString(row.batchCode)
    case 'name':
      return normalizeString(row.displayName)
    case 'latestFillingAt':
      return row.latestFillingAt ? Date.parse(row.latestFillingAt) : Number.NEGATIVE_INFINITY
    case 'totalVolume':
      return row.totalVolume ?? Number.NEGATIVE_INFINITY
    case 'liquorCode':
      return normalizeString(row.liquorCode)
    case 'abv':
      return row.abv ?? Number.NEGATIVE_INFINITY
    case 'sampleVolume':
      return row.sampleVolume ?? Number.NEGATIVE_INFINITY
    case 'tankLeftVolume':
      return row.tankLeftVolume ?? Number.NEGATIVE_INFINITY
    case 'lossVolume':
      return row.lossVolume ?? Number.NEGATIVE_INFINITY
    default:
      return ''
  }
}

function selectBatch(batchId: string) {
  selectedBatchId.value = batchId
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString(locale.value)
  } catch {
    return value
  }
}

function formatTankSummary(tanks: string[]) {
  const values = tanks.map((value) => value.trim()).filter((value) => value.length > 0)
  return values.length ? values.join(', ') : '—'
}

function extractErrorMessage(err: unknown) {
  if (!err) return ''
  if (typeof err === 'string') return err
  if (err instanceof Error) return err.message
  const rec = err as Record<string, unknown>
  if (typeof rec.message === 'string' && rec.message.trim()) return rec.message
  if (typeof rec.details === 'string' && rec.details.trim()) return rec.details
  if (typeof rec.hint === 'string' && rec.hint.trim()) return rec.hint
  return ''
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved in session')
  tenantId.value = id
  return id
}

async function loadPackageLookup(tenant: string) {
  const { data, error } = await supabase
    .from('mst_package')
    .select('id, package_code, unit_volume, volume_uom, volume_fix_flg, is_active')
    .eq('tenant_id', tenant)
    .eq('is_active', true)
    .order('package_code', { ascending: true })
  if (error) throw error

  return new Map<string, PackageLookup>(
    ((data ?? []) as PackageRow[]).map((row) => {
      const unitVolume = toNumber(row.unit_volume)
      const unitVolumeLiters = convertToLiters(unitVolume, row.volume_uom ?? null)
      return [
        String(row.id),
        {
          packageCode: String(row.package_code ?? row.id),
          volumeFix: row.volume_fix_flg === true,
          unitVolumeLiters,
        },
      ]
    }),
  )
}

async function loadLiquorCodeMap() {
  const { data, error } = await supabase
    .from('registry_def')
    .select('def_id, def_key')
    .eq('kind', 'alcohol_type')
    .eq('is_active', true)
  if (error) throw error

  return new Map<string, string>(
    ((data ?? []) as RegistryRow[]).flatMap((row) => {
      if (!row?.def_id) return []
      const key = typeof row.def_key === 'string' && row.def_key.trim() ? row.def_key.trim() : String(row.def_id)
      return [[String(row.def_id), key]]
    }),
  )
}

function resolveLiquorCode(
  value: string | number | null | undefined,
  liquorCodeById: Map<string, string>,
) {
  if (value == null) return null
  const normalized = String(value).trim()
  if (!normalized) return null
  return liquorCodeById.get(normalized) ?? normalized
}

async function loadBatchInfo(batchIds: string[], liquorCodeById: Map<string, string>) {
  const infoMap = new Map<string, BatchInfo>()
  if (!batchIds.length) return infoMap

  const tenant = await ensureTenant()
  const uniqueIds = Array.from(new Set(batchIds))

  const attrIdToCode = new Map<string, string>()
  const attrIds: number[] = []
  const attrValueByBatch = new Map<string, { liquorCode: string | null; abv: number | null }>()

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

    ;((attrValues ?? []) as AttrValueRow[]).forEach((row) => {
      const batchId = String(row.entity_id ?? '')
      if (!batchId) return
      if (!attrValueByBatch.has(batchId)) {
        attrValueByBatch.set(batchId, { liquorCode: null, abv: null })
      }
      const entry = attrValueByBatch.get(batchId)
      if (!entry) return

      const code = attrIdToCode.get(String(row.attr_id))
      if (!code) return

      if (code === 'beer_category') {
        const jsonDefId = row.value_json?.def_id
        const rawValue =
          typeof jsonDefId === 'string' && jsonDefId.trim()
            ? jsonDefId.trim()
            : typeof row.value_text === 'string' && row.value_text.trim()
              ? row.value_text.trim()
              : row.value_ref_type_id != null
                ? String(row.value_ref_type_id)
                : null
        entry.liquorCode = resolveLiquorCode(rawValue, liquorCodeById)
      }

      if (code === 'target_abv') {
        const num = toNumber(row.value_num)
        if (num != null) entry.abv = num
      }
    })
  }

  const { data: batches, error: batchError } = await supabase
    .from('mes_batches')
    .select('id, batch_code, batch_label, product_name, actual_yield, meta, recipe_id, recipe:recipe_id ( category, target_abv )')
    .eq('tenant_id', tenant)
    .in('id', uniqueIds)
  if (batchError) throw batchError

  ;((batches ?? []) as BatchRow[]).forEach((row) => {
    const attr = attrValueByBatch.get(String(row.id))
    const recipe = Array.isArray(row.recipe) ? row.recipe[0] : row.recipe
    const meta = isRecord(row.meta) ? row.meta : null
    infoMap.set(String(row.id), {
      batchCode: row.batch_code ?? null,
      displayName: row.product_name ?? row.batch_label ?? resolveBatchLabel(meta) ?? null,
      actualYield: toNumber(row.actual_yield),
      liquorCode:
        attr?.liquorCode ??
        resolveLiquorCode(recipe?.category ?? null, liquorCodeById) ??
        resolveLiquorCode(resolveMetaString(meta, 'beer_category'), liquorCodeById) ??
        resolveLiquorCode(resolveMetaString(meta, 'category'), liquorCodeById) ??
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

function normalizeFillingLines(rawLines: unknown): FillingHistoryLine[] {
  if (!Array.isArray(rawLines)) return []
  return rawLines.map((line) => {
    const record = isRecord(line) ? line : {}
    return {
      package_type_id:
        typeof record.package_type_id === 'string' && record.package_type_id.trim()
          ? record.package_type_id.trim()
          : null,
      qty: toNumber(record.qty),
      volume: toNumber(record.volume),
      sample_flg: record.sample_flg === true || record.sample_flg === 'true',
    } satisfies FillingHistoryLine
  })
}

function deriveFillingLinesFromMovementLines(lines: MovementLineRow[], lookup: Map<string, PackageLookup>) {
  return lines.flatMap((line) => {
    const packageId =
      typeof line.package_id === 'string' && line.package_id.trim() ? line.package_id.trim() : ''
    if (!packageId) return []
    const packageDef = lookup.get(packageId)
    const meta = isRecord(line.meta) ? line.meta : null
    const qty = toNumber(line.qty)
    const unit = toNumber(line.unit)
    const unitCount = toNumber(meta?.unit_count)
    const inputVolumeLiters = toNumber(meta?.input_volume_l)
    const sampleFlag = meta?.sample_flg === true || meta?.sample_flg === 'true'
    return [{
      package_type_id: packageId,
      qty: packageDef?.volumeFix ? (unitCount ?? unit) : null,
      volume: packageDef?.volumeFix ? null : (inputVolumeLiters ?? qty),
      sample_flg: sampleFlag,
    } satisfies FillingHistoryLine]
  })
}

function fillingEventFromMovement(
  movement: MovementRow,
  linesByMovementId: Map<string, MovementLineRow[]>,
  lookup: Map<string, PackageLookup>,
) {
  const meta = isRecord(movement.meta) ? movement.meta : {}
  const metaLines = normalizeFillingLines(meta.filling_lines)
  const fallbackLines = deriveFillingLinesFromMovementLines(linesByMovementId.get(String(movement.id)) ?? [], lookup)
  const fillingLines = metaLines.length ? metaLines : fallbackLines
  return {
    tank_fill_start_volume: toNumber(meta.tank_fill_start_volume),
    tank_left_volume: toNumber(meta.tank_left_volume),
    sample_volume: toNumber(meta.sample_volume),
    filling_lines: fillingLines,
  } satisfies FillingHistoryEvent
}

function resolveTankNumber(meta: JsonRecord | null | undefined) {
  return resolveMetaString(meta, 'tank_no') ?? resolveMetaString(meta, 'tank_id')
}

function sampleVolumeFromEvent(event: FillingHistoryEvent, options: FillingCalculationOptions) {
  if (event.sample_volume != null && Number.isFinite(event.sample_volume)) return event.sample_volume
  const lines = Array.isArray(event.filling_lines) ? event.filling_lines : []
  return fillingSampleVolumeFromEvent(lines, options)
}

function packageNumberFromLine(line: FillingHistoryLine, lookup: Map<string, PackageLookup>) {
  const packageTypeId =
    typeof line.package_type_id === 'string' && line.package_type_id.trim() ? line.package_type_id.trim() : ''
  if (!packageTypeId) return null
  const packageDef = lookup.get(packageTypeId)
  if (packageDef?.volumeFix) return toNumber(line.qty)
  return toNumber(line.qty) ?? toNumber(line.volume)
}

function compareTimestamp(a: string | null | undefined, b: string | null | undefined) {
  const aValue = a ? Date.parse(a) : Number.NEGATIVE_INFINITY
  const bValue = b ? Date.parse(b) : Number.NEGATIVE_INFINITY
  return aValue - bValue
}

function buildReportRows(
  movements: MovementRow[],
  linesByMovementId: Map<string, MovementLineRow[]>,
  batchInfoById: Map<string, BatchInfo>,
  lookup: Map<string, PackageLookup>,
) {
  const rowsByBatch = new Map<string, AggregateBatchRow>()

  movements.forEach((movement) => {
    const meta = isRecord(movement.meta) ? movement.meta : {}
    const batchId =
      typeof meta.batch_id === 'string' && meta.batch_id.trim() ? meta.batch_id.trim() : ''
    if (!batchId) return

    const batchInfo = batchInfoById.get(batchId)
    const event = fillingEventFromMovement(movement, linesByMovementId, lookup)
    const sampleVolume = sampleVolumeFromEvent(event, fillingOptions)
    const totalQuantity = packingTotalLineVolumeFromEvent(event, fillingOptions)
    const lossVolume = packingLossFromEvent(event, fillingOptions)
    const detailPackageGroups = new Map<string, AggregatePackageGroup>()

    if (!rowsByBatch.has(batchId)) {
      rowsByBatch.set(batchId, {
        id: batchId,
        batchId,
        batchCode:
          batchInfo?.batchCode ??
          (typeof meta.batch_code === 'string' && meta.batch_code.trim() ? meta.batch_code.trim() : null),
        displayName: batchInfo?.displayName ?? null,
        latestFillingAt: movement.movement_at ?? null,
        totalVolume: batchInfo?.actualYield ?? null,
        liquorCode: batchInfo?.liquorCode ?? null,
        abv: batchInfo?.abv ?? null,
        packageGroups: new Map(),
        sampleVolume: 0,
        tankLeftVolume: toNumber(meta.tank_left_volume),
        lossVolume: 0,
        lossVolumeKnown: true,
        detailRows: [],
      })
    }

    const row = rowsByBatch.get(batchId)
    if (!row) return

    if (compareTimestamp(row.latestFillingAt, movement.movement_at ?? null) < 0) {
      row.latestFillingAt = movement.movement_at ?? null
      row.tankLeftVolume = toNumber(meta.tank_left_volume)
    }

    if (sampleVolume != null && Number.isFinite(sampleVolume)) {
      row.sampleVolume += sampleVolume
    }

    if (lossVolume == null) row.lossVolumeKnown = false
    else row.lossVolume += lossVolume

    const fillingLines = Array.isArray(event.filling_lines) ? event.filling_lines : []
    fillingLines.forEach((line) => {
      if (line.sample_flg) return
      const packageTypeId =
        typeof line.package_type_id === 'string' && line.package_type_id.trim()
          ? line.package_type_id.trim()
          : ''
      if (!packageTypeId) return

      const packageDef = lookup.get(packageTypeId)
      const label = packageDef?.packageCode ?? packageTypeId
      const quantity = packageNumberFromLine(line, lookup)
      const group = row.packageGroups.get(packageTypeId)
      const detailGroup = detailPackageGroups.get(packageTypeId)
      if (!group) {
        row.packageGroups.set(packageTypeId, {
          label,
          quantity,
        })
      } else if (group.quantity == null || quantity == null) {
        group.quantity = group.quantity ?? quantity
      } else {
        group.quantity += quantity
      }

      if (!detailGroup) {
        detailPackageGroups.set(packageTypeId, {
          label,
          quantity,
        })
        return
      }

      if (detailGroup.quantity == null || quantity == null) {
        detailGroup.quantity = detailGroup.quantity ?? quantity
        return
      }
      detailGroup.quantity += quantity
    })

    const orderedDetailGroups = Array.from(detailPackageGroups.values()).sort((a, b) =>
      a.label.localeCompare(b.label),
    )
    const detailPackageNumbers = orderedDetailGroups.reduce<Record<string, number | null>>((acc, group) => {
      acc[group.label] = group.quantity
      return acc
    }, {})

    row.detailRows.push({
      id: String(movement.id),
      batchId,
      movementAt: movement.movement_at ?? null,
      tankNo: resolveTankNumber(meta),
      tankFillStartDepth: toNumber(meta.tank_fill_start_depth),
      tankFillStartVolume: toNumber(meta.tank_fill_start_volume),
      packageNumbers: detailPackageNumbers,
      sampleVolume,
      totalQuantity,
      tankLeftVolume: toNumber(meta.tank_left_volume),
      lossVolume,
    } satisfies FillingDetailRow)
  })

  return Array.from(rowsByBatch.values()).map((row) => {
    const orderedGroups = Array.from(row.packageGroups.values()).sort((a, b) =>
      a.label.localeCompare(b.label),
    )
    const packageNumbers = orderedGroups.reduce<Record<string, number | null>>((acc, group) => {
      acc[group.label] = group.quantity
      return acc
    }, {})
    const fillingTanks = row.detailRows
      .map((detail) => detail.tankNo?.trim() ?? '')
      .filter((value, index, arr) => value.length > 0 && arr.indexOf(value) === index)
    return {
      id: row.id,
      batchId: row.batchId,
      batchCode: row.batchCode,
      displayName: row.displayName,
      latestFillingAt: row.latestFillingAt,
      totalVolume: row.totalVolume,
      liquorCode: row.liquorCode,
      abv: row.abv,
      packageNumbers,
      sampleVolume: row.sampleVolume,
      tankLeftVolume: row.tankLeftVolume,
      lossVolume: row.lossVolumeKnown ? row.lossVolume : null,
      fillingTanks,
      detailRows: row.detailRows,
    } satisfies FillingReportRow
  })
}

async function loadReport() {
  try {
    reportLoading.value = true
    reportRows.value = []

    const tenant = await ensureTenant()
    const [packageLookup, liquorCodeById, movementRowsBySource, movementRowsByIntent] = await Promise.all([
      loadPackageLookup(tenant),
      loadLiquorCodeMap(),
      supabase
        .from('inv_movements')
        .select('id, movement_at, meta')
        .eq('tenant_id', tenant)
        .neq('status', 'void')
        .eq('meta->>source', 'packing')
        .eq('meta->>packing_type', 'filling'),
      supabase
        .from('inv_movements')
        .select('id, movement_at, meta')
        .eq('tenant_id', tenant)
        .neq('status', 'void')
        .eq('meta->>movement_intent', 'PACKAGE_FILL'),
    ])

    if (movementRowsBySource.error) throw movementRowsBySource.error
    if (movementRowsByIntent.error) throw movementRowsByIntent.error

    packageLookupMap.value = packageLookup

    const mergedMovementMap = new Map<string, MovementRow>()
    ;[
      ...((movementRowsBySource.data ?? []) as MovementRow[]),
      ...((movementRowsByIntent.data ?? []) as MovementRow[]),
    ].forEach((row) => {
      if (!row?.id) return
      mergedMovementMap.set(String(row.id), row)
    })

    const movements = Array.from(mergedMovementMap.values()).filter((movement) => {
      const meta = isRecord(movement.meta) ? movement.meta : {}
      return typeof meta.batch_id === 'string' && meta.batch_id.trim().length > 0
    })

    if (!movements.length) {
      reportRows.value = []
      return
    }

    const movementIds = movements.map((movement) => String(movement.id))
    const batchIds = movements
      .map((movement) => {
        const meta = isRecord(movement.meta) ? movement.meta : {}
        return typeof meta.batch_id === 'string' ? meta.batch_id.trim() : ''
      })
      .filter((value: string) => value.length > 0)

    const [{ data: lineRows, error: lineError }, batchInfoById] = await Promise.all([
      supabase
        .from('inv_movement_lines')
        .select('movement_id, package_id, qty, unit, meta')
        .in('movement_id', movementIds),
      loadBatchInfo(batchIds, liquorCodeById),
    ])

    if (lineError) throw lineError

    const linesByMovementId = new Map<string, MovementLineRow[]>()
    ;((lineRows ?? []) as MovementLineRow[]).forEach((line) => {
      const movementId = String(line.movement_id ?? '')
      if (!movementId) return
      const list = linesByMovementId.get(movementId) ?? []
      list.push(line)
      linesByMovementId.set(movementId, list)
    })

    reportRows.value = buildReportRows(movements, linesByMovementId, batchInfoById, packageLookup)
  } catch (err) {
    reportRows.value = []
    const detail = extractErrorMessage(err)
    toast.error(detail || 'Failed to load filling report.')
  } finally {
    reportLoading.value = false
  }
}

onMounted(async () => {
  await loadReport()
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
