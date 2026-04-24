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
                {{ t('taxableRemovalReport.results.count', { count: visibleDetailRows.length }) }}
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
                  <th class="px-3 py-2 text-left">
                    <TableColumnHeader
                      v-model:filter-value="columnFilters.item"
                      :active-sort-key="sortKey"
                      :filter-placeholder="t('common.search')"
                      :label="t('taxableRemovalReport.table.columns.item')"
                      sort-key="item"
                      :sort-direction="sortDirection"
                      @sort="setColumnSort"
                    />
                  </th>
                  <th class="px-3 py-2 text-left">
                    <TableColumnHeader
                      v-model:filter-value="columnFilters.brand"
                      :active-sort-key="sortKey"
                      :filter-placeholder="t('common.search')"
                      :label="t('taxableRemovalReport.table.columns.brand')"
                      sort-key="brand"
                      :sort-direction="sortDirection"
                      @sort="setColumnSort"
                    />
                  </th>
                  <th class="px-3 py-2 text-right">
                    <TableColumnHeader
                      v-model:filter-value="columnFilters.abv"
                      align="right"
                      :active-sort-key="sortKey"
                      :filter-placeholder="t('common.search')"
                      :label="t('taxableRemovalReport.table.columns.abv')"
                      sort-key="abv"
                      :sort-direction="sortDirection"
                      @sort="setColumnSort"
                    />
                  </th>
                  <th class="px-3 py-2 text-left">
                    <TableColumnHeader
                      v-model:filter-value="columnFilters.movementAt"
                      :active-sort-key="sortKey"
                      :filter-placeholder="t('common.search')"
                      :label="t('taxableRemovalReport.table.columns.movementAt')"
                      sort-key="movementAt"
                      :sort-direction="sortDirection"
                      @sort="setColumnSort"
                    />
                  </th>
                  <th class="px-3 py-2 text-left">
                    <TableColumnHeader
                      v-model:filter-value="columnFilters.container"
                      :active-sort-key="sortKey"
                      :filter-placeholder="t('common.search')"
                      :label="t('taxableRemovalReport.table.columns.container')"
                      sort-key="container"
                      :sort-direction="sortDirection"
                      @sort="setColumnSort"
                    />
                  </th>
                  <th class="px-3 py-2 text-right">
                    <TableColumnHeader
                      v-model:filter-value="columnFilters.quantityMl"
                      align="right"
                      :active-sort-key="sortKey"
                      :filter-placeholder="t('common.search')"
                      :label="t('taxableRemovalReport.table.columns.quantityMl')"
                      sort-key="quantityMl"
                      :sort-direction="sortDirection"
                      @sort="setColumnSort"
                    />
                  </th>
                  <th class="px-3 py-2 text-right">{{ t('taxableRemovalReport.table.columns.unitPrice') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('taxableRemovalReport.table.columns.amount') }}</th>
                  <th class="px-3 py-2 text-left">
                    <TableColumnHeader
                      v-model:filter-value="columnFilters.removalType"
                      :active-sort-key="sortKey"
                      :filter-placeholder="t('common.search')"
                      :label="t('taxableRemovalReport.table.columns.removalType')"
                      sort-key="removalType"
                      :sort-direction="sortDirection"
                      @sort="setColumnSort"
                    />
                  </th>
                  <th class="px-3 py-2 text-left">
                    <TableColumnHeader
                      v-model:filter-value="columnFilters.destinationAddress"
                      :active-sort-key="sortKey"
                      :filter-placeholder="t('common.search')"
                      :label="t('taxableRemovalReport.table.columns.destinationAddress')"
                      sort-key="destinationAddress"
                      :sort-direction="sortDirection"
                      @sort="setColumnSort"
                    />
                  </th>
                  <th class="px-3 py-2 text-left">
                    <TableColumnHeader
                      v-model:filter-value="columnFilters.destinationName"
                      :active-sort-key="sortKey"
                      :filter-placeholder="t('common.search')"
                      :label="t('taxableRemovalReport.table.columns.destinationName')"
                      sort-key="destinationName"
                      :sort-direction="sortDirection"
                      @sort="setColumnSort"
                    />
                  </th>
                  <th class="px-3 py-2 text-left">
                    <TableColumnHeader
                      v-model:filter-value="columnFilters.lotNo"
                      :active-sort-key="sortKey"
                      :filter-placeholder="t('common.search')"
                      :label="t('taxableRemovalReport.table.columns.lotNo')"
                      sort-key="lotNo"
                      :sort-direction="sortDirection"
                      @sort="setColumnSort"
                    />
                  </th>
                  <th class="px-3 py-2 text-left">
                    <TableColumnHeader
                      v-model:filter-value="columnFilters.notes"
                      :active-sort-key="sortKey"
                      :filter-placeholder="t('common.search')"
                      :label="t('taxableRemovalReport.table.columns.notes')"
                      sort-key="notes"
                      :sort-direction="sortDirection"
                      @sort="setColumnSort"
                    />
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100 bg-white">
                <tr v-if="loading">
                  <td colspan="13" class="px-3 py-8 text-center text-gray-500">
                    {{ t('common.loading') }}
                  </td>
                </tr>
                <tr v-else-if="visibleDetailRows.length === 0">
                  <td colspan="13" class="px-3 py-8 text-center text-gray-500">
                    {{ t('common.noData') }}
                  </td>
                </tr>
                <tr v-for="row in visibleDetailRows" v-else :key="row.id" class="hover:bg-gray-50">
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
import TableColumnHeader from '@/components/common/TableColumnHeader.vue'
import { useColumnTableControls } from '@/composables/useColumnTableControls'
import { supabase } from '@/lib/supabase'
import {
  buildTaxableRemovalBusinessYearFileName,
  buildTaxableRemovalSummaryRows,
  businessYearForDate,
  compareTaxableRemovalDetailRows,
  createTaxableRemovalBusinessYearWorkbookBlob,
  extractErrorMessage,
  getCurrentBusinessYear,
  loadTaxableRemovalDetailRows,
  matchesBusinessYear,
  type TaxableRemovalDetailRow,
  type TaxableRemovalExportLabels,
} from '@/lib/taxableRemovalReport'

type LiquorCodeOption = {
  value: string
  label: string
}

type DetailTableSortKey =
  | 'item'
  | 'brand'
  | 'abv'
  | 'movementAt'
  | 'container'
  | 'quantityMl'
  | 'removalType'
  | 'destinationAddress'
  | 'destinationName'
  | 'lotNo'
  | 'notes'

const { t, locale } = useI18n()

const pageTitle = computed(() => t('taxableRemovalReport.title'))
const loading = ref(false)
const exportLoading = ref(false)
const exportFileName = ref('')
const exportDownloadUrl = ref('')
const tenantId = ref('')
const detailRows = ref<TaxableRemovalDetailRow[]>([])

const filters = reactive({
  businessYear: getCurrentBusinessYear(),
  month: '',
  liquorCode: '',
})

const monthOptions = Array.from({ length: 12 }, (_, index) => index + 1)

const exportLabels = computed<TaxableRemovalExportLabels>(() => ({
  summaryTitle: t('taxableRemovalReport.summary.title'),
  tableTitle: t('taxableRemovalReport.table.title'),
  generatedAt: t('taxableRemovalReport.export.generatedAt'),
  businessYear: t('taxableRemovalReport.export.businessYear'),
  monthSheetLabel: t('taxableRemovalReport.export.monthSheetLabel'),
  summarySheetName: t('taxableRemovalReport.export.summarySheetName'),
  summaryColumns: {
    liquorCode: t('taxableRemovalReport.summary.columns.liquorCode'),
    abv: t('taxableRemovalReport.summary.columns.abv'),
    quantityMl: t('taxableRemovalReport.summary.columns.quantityMl'),
    packageCount: t('taxableRemovalReport.summary.columns.packageCount'),
    taxRate: t('taxableRemovalReport.summary.columns.taxRate'),
    taxAmount: t('taxableRemovalReport.summary.columns.taxAmount'),
  },
  tableColumns: {
    item: t('taxableRemovalReport.table.columns.item'),
    brand: t('taxableRemovalReport.table.columns.brand'),
    abv: t('taxableRemovalReport.table.columns.abv'),
    movementAt: t('taxableRemovalReport.table.columns.movementAt'),
    container: t('taxableRemovalReport.table.columns.container'),
    quantityMl: t('taxableRemovalReport.table.columns.quantityMl'),
    unitPrice: t('taxableRemovalReport.table.columns.unitPrice'),
    amount: t('taxableRemovalReport.table.columns.amount'),
    removalType: t('taxableRemovalReport.table.columns.removalType'),
    destinationAddress: t('taxableRemovalReport.table.columns.destinationAddress'),
    destinationName: t('taxableRemovalReport.table.columns.destinationName'),
    lotNo: t('taxableRemovalReport.table.columns.lotNo'),
    notes: t('taxableRemovalReport.table.columns.notes'),
  },
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
    .sort(compareTaxableRemovalDetailRows),
)

const {
  sortKey,
  sortDirection,
  columnFilters,
  sortedRows: visibleDetailRows,
  hasColumnFilters,
  setSort,
  clearColumnFilters,
} = useColumnTableControls<TaxableRemovalDetailRow, DetailTableSortKey>(
  filteredRows,
  [
    { key: 'item', sortValue: (row) => row.itemLabel || row.liquorCode, filterType: 'text' },
    { key: 'brand', sortValue: (row) => row.brandName, filterType: 'text' },
    { key: 'abv', sortValue: (row) => row.abv, filterValue: (row) => formatAbv(row.abv), filterType: 'text' },
    { key: 'movementAt', sortValue: (row) => (row.movementAt ? Date.parse(row.movementAt) : null), filterValue: (row) => formatDateTime(row.movementAt), filterType: 'text' },
    { key: 'container', sortValue: (row) => row.containerLabel, filterType: 'text' },
    { key: 'quantityMl', sortValue: (row) => row.quantityMl, filterValue: (row) => formatQuantityMl(row.quantityMl), filterType: 'text' },
    { key: 'removalType', sortValue: (row) => row.removalTypeLabel, filterType: 'text' },
    { key: 'destinationAddress', sortValue: (row) => row.destinationAddress, filterType: 'text' },
    { key: 'destinationName', sortValue: (row) => row.destinationName, filterType: 'text' },
    { key: 'lotNo', sortValue: (row) => row.lotNo, filterType: 'text' },
    { key: 'notes', sortValue: (row) => row.notes, filterType: 'text' },
  ],
  'movementAt',
  'desc',
)

function setColumnSort(key: string) {
  setSort(key as DetailTableSortKey)
}

const businessYearDetailRows = computed(() =>
  detailRows.value
    .filter((row) => matchesBusinessYear(row.movementAt, filters.businessYear))
    .slice()
    .sort(compareTaxableRemovalDetailRows),
)

const summaryRows = computed(() => buildTaxableRemovalSummaryRows(detailRows.value, filters.businessYear))

function safeDate(value: string | null | undefined) {
  if (!value) return null
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date
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
    detailRows.value = await loadTaxableRemovalDetailRows({
      supabase,
      tenantId: tenant,
      locale: locale.value,
      removalTypeLabel: t('taxableRemovalReport.defaults.taxableRemovalType'),
    })
  } catch (err) {
    detailRows.value = []
    toast.error(extractErrorMessage(err) || t('taxableRemovalReport.errors.loadFailed'))
  } finally {
    loading.value = false
  }
}

function exportExcel() {
  if (!businessYearDetailRows.value.length) {
    toast.error(t('taxableRemovalReport.export.noData'))
    return
  }

  try {
    exportLoading.value = true
    const createdAt = new Date()
    const blob = createTaxableRemovalBusinessYearWorkbookBlob({
      detailRows: detailRows.value,
      businessYear: filters.businessYear,
      labels: exportLabels.value,
      locale: locale.value,
      createdAt,
      creator: 'beeradmin_tail',
    })
    const url = URL.createObjectURL(blob)
    clearExportDownload()
    exportFileName.value = buildTaxableRemovalBusinessYearFileName(filters.businessYear)
    exportDownloadUrl.value = url
  } catch (err) {
    clearExportDownload()
    toast.error(extractErrorMessage(err) || t('taxableRemovalReport.export.failed'))
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

onUnmounted(() => {
  clearExportDownload()
})
</script>
