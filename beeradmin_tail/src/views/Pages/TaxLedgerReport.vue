<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen w-full space-y-6 bg-white p-4 text-gray-900">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ pageTitle }}</h1>
          <p class="text-sm text-gray-500">{{ pageSubtitle }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button
            class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading || exportLoading || businessYearDetailRows.length === 0"
            @click="exportExcel"
          >
            {{ exportLoading ? t('taxLedgerReport.export.exporting') : t('taxLedgerReport.export.button') }}
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
                {{ t('taxLedgerReport.filters.businessYear') }}
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
                {{ t('taxLedgerReport.filters.month') }}
              </label>
              <select
                v-model="filters.month"
                class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
              >
                <option value="">{{ t('taxLedgerReport.defaults.allMonths') }}</option>
                <option v-for="month in monthOptions" :key="month" :value="String(month)">
                  {{ month }}
                </option>
              </select>
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('taxLedgerReport.filters.liquorCode') }}
              </label>
              <select
                v-model="filters.liquorCode"
                class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
              >
                <option value="">{{ t('taxLedgerReport.defaults.allLiquorCodes') }}</option>
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
              {{ t('taxLedgerReport.summary.title') }}
            </h2>
            <p class="text-sm text-gray-500">
              {{ t('taxLedgerReport.summary.subtitle') }}
            </p>
          </div>

          <section class="overflow-x-auto rounded-lg border border-gray-200 bg-white">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                <tr>
                  <th class="px-3 py-2 text-left">{{ t('taxLedgerReport.summary.columns.liquorCode') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('taxLedgerReport.summary.columns.abv') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('taxLedgerReport.summary.columns.quantityMl') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('taxLedgerReport.summary.columns.packageCount') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 bg-white">
                <tr v-if="loading">
                  <td colspan="4" class="px-3 py-8 text-center text-gray-500">
                    {{ t('common.loading') }}
                  </td>
                </tr>
                <tr v-else-if="summaryRows.length === 0">
                  <td colspan="4" class="px-3 py-8 text-center text-gray-500">
                    {{ t('common.noData') }}
                  </td>
                </tr>
                <tr v-for="row in summaryRows" v-else :key="row.key" class="hover:bg-gray-50">
                  <td class="px-3 py-2 text-gray-700">{{ row.liquorCodeLabel || row.liquorCode || '—' }}</td>
                  <td class="px-3 py-2 text-right">{{ formatAbv(row.abv) }}</td>
                  <td class="px-3 py-2 text-right">{{ formatQuantityMl(row.quantityMl) }}</td>
                  <td class="px-3 py-2 text-right">{{ formatNumberValue(row.packageCount) }}</td>
                </tr>
              </tbody>
            </table>
          </section>
        </section>

        <section class="space-y-3 rounded-xl border border-gray-200 bg-gray-50/40 p-4">
          <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
            <div>
              <h2 class="text-base font-semibold text-gray-900">
                {{ t('taxLedgerReport.table.title') }}
              </h2>
              <p class="text-sm text-gray-500">
                {{ t('taxLedgerReport.results.count', { count: visibleDetailRows.length }) }}
              </p>
            </div>
            <button
              class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50 disabled:opacity-50"
              :disabled="!hasColumnFilters"
              type="button"
              @click="clearColumnFilters"
            >
              {{ t('common.clearFilters') }}
            </button>
          </div>

          <section class="overflow-x-auto rounded-lg border border-gray-200 bg-white">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                <tr>
                  <th
                    v-for="column in detailColumns"
                    :key="column"
                    class="px-3 py-2"
                    :class="isRightAlignedColumn(column) ? 'text-right' : 'text-left'"
                  >
                    <TableColumnHeader
                      v-model:filter-value="columnFilters[column]"
                      :active-sort-key="sortKey"
                      :align="isRightAlignedColumn(column) ? 'right' : 'left'"
                      :filter-placeholder="t('common.search')"
                      :label="columnLabel(column)"
                      :sort-key="column"
                      :sort-direction="sortDirection"
                      @sort="setColumnSort"
                    />
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 bg-white">
                <tr v-if="loading">
                  <td :colspan="detailColumns.length" class="px-3 py-8 text-center text-gray-500">
                    {{ t('common.loading') }}
                  </td>
                </tr>
                <tr v-else-if="visibleDetailRows.length === 0">
                  <td :colspan="detailColumns.length" class="px-3 py-8 text-center text-gray-500">
                    {{ t('common.noData') }}
                  </td>
                </tr>
                <tr v-for="row in visibleDetailRows" v-else :key="row.id" class="hover:bg-gray-50">
                  <td
                    v-for="column in detailColumns"
                    :key="`${row.id}-${column}`"
                    class="px-3 py-2 text-gray-700"
                    :class="[
                      isRightAlignedColumn(column) ? 'text-right' : 'text-left',
                      column === 'lotNo' ? 'font-mono text-xs' : '',
                    ]"
                  >
                    {{ formatDetailValue(row, column) }}
                  </td>
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
import { useRoute } from 'vue-router'
import { toast } from 'vue3-toastify'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import TableColumnHeader from '@/components/common/TableColumnHeader.vue'
import { useColumnTableControls, type ColumnSortDirection } from '@/composables/useColumnTableControls'
import { supabase } from '@/lib/supabase'
import { formatTotalVolumeFromMilliliters } from '@/lib/volumeFormat'
import {
  buildTaxLedgerBusinessYearFileName,
  buildTaxLedgerSummaryRows,
  businessYearForDate,
  columnSortValue,
  compareTaxLedgerDetailRows,
  createTaxLedgerBusinessYearWorkbookBlob,
  extractErrorMessage,
  formatColumnValue,
  getCurrentBusinessYear,
  getTaxLedgerConfig,
  loadTaxLedgerDetailRows,
  localizedText,
  matchesBusinessYear,
  type TaxLedgerColumnKey,
  type TaxLedgerDetailRow,
  type TaxLedgerExportLabels,
} from '@/lib/taxLedgerReport'

type LiquorCodeOption = {
  value: string
  label: string
}

const allColumnKeys: TaxLedgerColumnKey[] = [
  'movementAt',
  'item',
  'brand',
  'abv',
  'container',
  'packageCount',
  'quantityMl',
  'taxRate',
  'sourceAddress',
  'sourceName',
  'destinationAddress',
  'destinationName',
  'recipientAddress',
  'location',
  'exporterAddress',
  'exportDestinationAddress',
  'exportDestinationName',
  'transferorAddress',
  'deliveryAddress',
  'lotNo',
  'notes',
]

const rightAlignedColumns = new Set<TaxLedgerColumnKey>([
  'abv',
  'packageCount',
  'quantityMl',
  'taxRate',
])

const { t, locale } = useI18n()
const route = useRoute()

const loading = ref(false)
const exportLoading = ref(false)
const exportFileName = ref('')
const exportDownloadUrl = ref('')
const tenantId = ref('')
const detailRows = ref<TaxLedgerDetailRow[]>([])

const filters = reactive({
  businessYear: getCurrentBusinessYear(),
  month: '',
  liquorCode: '',
})

const monthOptions = Array.from({ length: 12 }, (_, index) => index + 1)

const ledgerKey = computed(() => String(route.meta.ledgerKey ?? 'nonTaxableRemoval'))
const reportConfig = computed(() => getTaxLedgerConfig(ledgerKey.value))
const pageTitle = computed(() => localizedText(reportConfig.value.title, locale.value))
const pageSubtitle = computed(() => localizedText(reportConfig.value.subtitle, locale.value))
const detailColumns = computed(() => reportConfig.value.detailColumns)

const exportLabels = computed<TaxLedgerExportLabels>(() => ({
  generatedAt: t('taxLedgerReport.export.generatedAt'),
  businessYear: t('taxLedgerReport.export.businessYear'),
  columns: Object.fromEntries(
    [...allColumnKeys, 'containerType'].map((column) => [
      column,
      t(`taxLedgerReport.table.columns.${column}`),
    ]),
  ) as TaxLedgerExportLabels['columns'],
}))

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
    new Map(
      detailRows.value
        .map((row) => ({
          value: (row.liquorCode ?? '').trim(),
          label: row.itemLabel || row.liquorCode || '',
        }))
        .filter((row) => row.value.length > 0)
        .map((row) => [row.value, row.label]),
    ),
  )
    .map(([value, label]) => ({ value, label }))
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
      return !!date && date.getMonth() + 1 === Number(filters.month)
    })
    .filter((row) => !filters.liquorCode || (row.liquorCode ?? '') === filters.liquorCode)
    .slice()
    .sort(compareTaxLedgerDetailRows),
)

const {
  sortKey,
  sortDirection,
  columnFilters,
  sortedRows: visibleDetailRows,
  hasColumnFilters,
  setSort,
  clearColumnFilters,
} = useColumnTableControls<TaxLedgerDetailRow, TaxLedgerColumnKey>(
  filteredRows,
  allColumnKeys.map((key) => ({
    key,
    sortValue: (row) => columnSortValue(row, key),
    filterValue: (row) => formatColumnValue(row, key, locale.value),
    filterType: 'text',
  })),
  'movementAt',
  'desc',
)

const businessYearDetailRows = computed(() =>
  detailRows.value
    .filter((row) => matchesBusinessYear(row.movementAt, filters.businessYear))
    .slice()
    .sort(compareTaxLedgerDetailRows),
)

const summaryRows = computed(() => buildTaxLedgerSummaryRows(detailRows.value, filters.businessYear))

function safeDate(value: string | null | undefined) {
  if (!value) return null
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
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
  return formatTotalVolumeFromMilliliters(value, locale.value)
}

function columnLabel(column: TaxLedgerColumnKey) {
  return t(`taxLedgerReport.table.columns.${column}`)
}

function formatDetailValue(row: TaxLedgerDetailRow, column: TaxLedgerColumnKey) {
  return formatColumnValue(row, column, locale.value)
}

function isRightAlignedColumn(column: TaxLedgerColumnKey) {
  return rightAlignedColumns.has(column)
}

function setColumnSort(key: string, direction?: ColumnSortDirection) {
  setSort(key as TaxLedgerColumnKey, direction)
}

function clearExportDownload() {
  if (exportDownloadUrl.value) URL.revokeObjectURL(exportDownloadUrl.value)
  exportDownloadUrl.value = ''
  exportFileName.value = ''
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

async function loadReport() {
  try {
    loading.value = true
    clearExportDownload()
    const tenant = await ensureTenant()
    detailRows.value = await loadTaxLedgerDetailRows({
      supabase,
      tenantId: tenant,
      locale: locale.value,
      config: reportConfig.value,
    })
  } catch (err) {
    detailRows.value = []
    toast.error(extractErrorMessage(err) || t('taxLedgerReport.errors.loadFailed'))
  } finally {
    loading.value = false
  }
}

function exportExcel() {
  if (!businessYearDetailRows.value.length) {
    toast.error(t('taxLedgerReport.export.noData'))
    return
  }

  try {
    exportLoading.value = true
    const createdAt = new Date()
    const blob = createTaxLedgerBusinessYearWorkbookBlob({
      detailRows: detailRows.value,
      businessYear: filters.businessYear,
      config: reportConfig.value,
      labels: exportLabels.value,
      locale: locale.value,
      createdAt,
      creator: 'beeradmin_tail',
    })
    const url = URL.createObjectURL(blob)
    clearExportDownload()
    exportFileName.value = buildTaxLedgerBusinessYearFileName(reportConfig.value, filters.businessYear)
    exportDownloadUrl.value = url
  } catch (err) {
    clearExportDownload()
    toast.error(extractErrorMessage(err) || t('taxLedgerReport.export.failed'))
  } finally {
    exportLoading.value = false
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

watch(
  () => ledgerKey.value,
  (next, previous) => {
    if (next === previous) return
    filters.month = ''
    filters.liquorCode = ''
    clearColumnFilters()
    setSort('movementAt', 'desc')
    loadReport()
  },
)

onUnmounted(() => {
  clearExportDownload()
})
</script>
