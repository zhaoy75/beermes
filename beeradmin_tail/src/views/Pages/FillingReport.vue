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
            :disabled="reportLoading || exportLoading || sortedRows.length === 0"
            @click="exportExcel"
          >
            {{ exportLoading ? t('fillingReport.export.exporting') : t('fillingReport.export.button') }}
          </button>
          <button
            class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-50 disabled:opacity-50"
            :disabled="reportLoading"
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
                <option v-for="option in liquorCodeOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
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
                <td class="px-3 py-2 text-gray-700">{{ row.liquorCodeLabel || row.liquorCode || '—' }}</td>
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
                <dd class="mt-1 text-sm text-gray-700">{{ selectedReportRow.liquorCodeLabel || selectedReportRow.liquorCode || '—' }}</dd>
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
                    <th rowspan="2" class="px-3 py-2 text-left align-middle">{{ t('fillingReport.detail.table.date') }}</th>
                    <th rowspan="2" class="px-3 py-2 text-left align-middle">{{ t('fillingReport.detail.table.beforeFilling') }}</th>
                    <th
                      v-for="packageCode in detailPackageColumns"
                      :key="`detail-package-header-${packageCode}`"
                      colspan="2"
                      class="px-3 py-2 text-center"
                    >
                      {{ packageCode }}
                    </th>
                    <th rowspan="2" class="px-3 py-2 text-right align-middle">{{ t('fillingReport.detail.table.sampleVolume') }}</th>
                    <th colspan="3" class="px-3 py-2 text-center">{{ t('fillingReport.detail.table.totalQuantity') }}</th>
                    <th rowspan="2" class="px-3 py-2 text-right align-middle">{{ t('fillingReport.detail.table.tankLeftVolume') }}</th>
                    <th rowspan="2" class="px-3 py-2 text-right align-middle">{{ t('fillingReport.detail.table.lossVolume') }}</th>
                  </tr>
                  <tr>
                    <template v-for="packageCode in detailPackageColumns" :key="`detail-package-subheader-${packageCode}`">
                      <th class="px-3 py-2 text-right">{{ t('fillingReport.detail.table.packageNumber') }}</th>
                      <th class="px-3 py-2 text-right">{{ t('fillingReport.detail.table.packageVolume') }}</th>
                    </template>
                    <th class="px-3 py-2 text-right">{{ t('fillingReport.detail.table.kegVolume') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('fillingReport.detail.table.canBottleVolume') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('fillingReport.detail.table.totalVolume') }}</th>
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
                    <template v-for="packageCode in detailPackageColumns" :key="`detail-package-row-${detailRow.id}-${packageCode}`">
                      <td class="px-3 py-2 text-right">
                        {{ formatPackageNumber(detailRow.packageNumbers[packageCode]) }}
                      </td>
                      <td class="px-3 py-2 text-right">
                        {{ formatVolumeValue(detailRow.packageVolumes[packageCode]) }}
                      </td>
                    </template>
                    <td class="px-3 py-2 text-right">{{ formatVolumeValue(detailRow.sampleVolume) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatPackageNumber(detailRow.kegUnits) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatPackageNumber(detailRow.canBottleUnits) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatVolumeValue(detailRow.totalQuantity) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatVolumeValue(detailRow.tankLeftVolume) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatVolumeValue(detailRow.lossVolume) }}</td>
                  </tr>
                  <tr v-if="selectedDetailRows.length > 0" class="bg-gray-50 font-semibold text-gray-900">
                    <td class="px-3 py-2"></td>
                    <td class="px-3 py-2"></td>
                    <template v-for="packageCode in detailPackageColumns" :key="`detail-package-total-${packageCode}`">
                      <td class="px-3 py-2 text-right">
                        {{ formatPackageNumber(selectedDetailTotals.packageNumbers[packageCode]) }}
                      </td>
                      <td class="px-3 py-2 text-right">
                        {{ formatVolumeValue(selectedDetailTotals.packageVolumes[packageCode]) }}
                      </td>
                    </template>
                    <td class="px-3 py-2 text-right">{{ formatVolumeValue(selectedDetailTotals.sampleVolume) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatPackageNumber(selectedDetailTotals.kegUnits) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatPackageNumber(selectedDetailTotals.canBottleUnits) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatVolumeValue(selectedDetailTotals.totalQuantity) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatVolumeValue(selectedDetailTotals.tankLeftVolume) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatVolumeValue(selectedDetailTotals.lossVolume) }}</td>
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
import { computed, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue3-toastify'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import {
  buildAlcoholTypeLabelMap,
  loadAlcoholTypeReferenceData,
  resolveAlcoholTypeLabel,
} from '@/lib/alcoholTypeRegistry'
import {
  resolveBatchBeerCategoryId,
  resolveBatchDisplayName,
  resolveBatchTargetAbv,
} from '@/lib/batchRecipeSnapshot'
import {
  fillingSampleVolumeFromEvent,
  packingLossFromEvent,
  packingTotalLineVolumeFromEvent,
  resolveFillingLineVolumeFromEvent,
  type FillingCalculationOptions,
  type FillingHistoryLine,
  type FillingHistoryEvent,
} from '@/lib/batchFilling'
import {
  createWorkbookBlob,
  type WorkbookCell,
  type WorkbookCellValue,
  type WorkbookSheet,
} from '@/lib/fillingReportExport'
import { supabase } from '@/lib/supabase'
import { formatVolumeNumber } from '@/lib/volumeFormat'

type JsonRecord = Record<string, unknown>

type PackageLookup = {
  packageCode: string
  volumeFix: boolean
  unitVolumeLiters: number | null
  volumeUomCode: string | null
}

type PackageRow = {
  id: string
  package_code: string | null
  package_type_id: string | null
  unit_volume: number | string | null
  volume_uom: string | null
  volume_fix_flg: boolean | null
}

type PreparedPackageRow = {
  id: string
  packageCode: string
  packageTypeId: string | null
  lookup: PackageLookup
}

type RegistryRow = {
  def_id: string
  def_key: string | null
  spec?: Record<string, unknown> | null
}

type VolumeUomRow = {
  id: string
  code: string | null
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

type BatchRow = {
  id: string
  batch_code: string | null
  batch_label: string | null
  product_name: string | null
  actual_yield: number | string | null
  meta: JsonRecord | null
  mes_recipe_id: string | null
  released_reference_json: JsonRecord | null
  recipe_json: JsonRecord | null
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
  uom_id: string | null
  meta: JsonRecord | null
}

type BatchInfo = {
  batchCode: string | null
  displayName: string | null
  actualYield: number | null
  liquorCode: string | null
  liquorCodeLabel: string | null
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
  packageVolumes: Record<string, number | null>
  sampleVolume: number | null
  kegUnits: number | null
  canBottleUnits: number | null
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
  liquorCodeLabel: string | null
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

type DetailPackageGroup = {
  label: string
  quantity: number | null
  volume: number | null
}

type AggregateBatchRow = {
  id: string
  batchId: string
  batchCode: string | null
  displayName: string | null
  latestFillingAt: string | null
  totalVolume: number | null
  liquorCode: string | null
  liquorCodeLabel: string | null
  abv: number | null
  packageGroups: Map<string, AggregatePackageGroup>
  sampleVolume: number
  tankLeftVolume: number | null
  lossVolume: number
  lossVolumeKnown: boolean
  detailRows: FillingDetailRow[]
}

type FillingDetailTotals = {
  packageNumbers: Record<string, number | null>
  packageVolumes: Record<string, number | null>
  sampleVolume: number | null
  kegUnits: number | null
  canBottleUnits: number | null
  totalQuantity: number | null
  tankLeftVolume: number | null
  lossVolume: number | null
}

type LiquorCodeOption = {
  value: string
  label: string
}

const { t, locale } = useI18n()
const pageTitle = computed(() => t('fillingReport.title'))
const reportLoading = ref(false)
const exportLoading = ref(false)
const exportFileName = ref('')
const exportDownloadUrl = ref('')
const reportRows = ref<FillingReportRow[]>([])
const liquorCodeLabelMap = ref<Map<string, string>>(new Map())
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
  return selectedReportRow.value ? detailPackageColumnsFor(selectedReportRow.value) : []
})
const detailTableColumnCount = computed(() => 2 + detailPackageColumns.value.length * 2 + 6)
const businessYearOptions = computed(() => {
  const years = new Set<number>([currentBusinessYear()])
  reportRows.value.forEach((row) => {
    const businessYear = businessYearFromDate(row.latestFillingAt)
    if (businessYear != null) years.add(businessYear)
  })
  return Array.from(years).sort((a, b) => b - a)
})
const liquorCodeOptions = computed<LiquorCodeOption[]>(() =>
  Array.from(
    new Map(
      reportRows.value
        .map((row) => {
          const value = (row.liquorCode ?? '').trim()
          if (!value) return null
          return [value, row.liquorCodeLabel || value] as const
        })
        .filter((entry): entry is readonly [string, string] => entry != null),
    ),
    ([value, label]) => ({ value, label }),
  ).sort((a, b) => a.label.localeCompare(b.label)),
)
const monthOptions = Array.from({ length: 12 }, (_, index) => index + 1)
const selectedDetailRows = computed(() =>
  selectedReportRow.value ? orderedDetailRowsFor(selectedReportRow.value) : [],
)
const selectedDetailTotals = computed(() =>
  buildDetailTotals(selectedDetailRows.value, detailPackageColumns.value),
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

function isLiterUomCode(value: string | null | undefined) {
  return (value ?? '').trim().toLowerCase() === 'l'
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
      return normalizeString(row.liquorCodeLabel ?? row.liquorCode)
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

function buildLocalDateStamp(date = new Date()) {
  const year = String(date.getFullYear())
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}${month}${day}`
}

function clearExportDownload() {
  if (exportDownloadUrl.value) URL.revokeObjectURL(exportDownloadUrl.value)
  exportDownloadUrl.value = ''
  exportFileName.value = ''
}

function buildExportFilterSummary() {
  const businessYear = `${t('fillingReport.filters.businessYear')}: ${filters.businessYear}`
  const month = `${t('fillingReport.filters.month')}: ${filters.month || t('fillingReport.defaults.allMonths')}`
  const liquorCodeLabel =
    (filters.liquorCode ? resolveAlcoholTypeLabel(liquorCodeLabelMap.value, filters.liquorCode) : null) ||
    filters.liquorCode ||
    t('fillingReport.defaults.allLiquorCodes')
  const liquorCode = `${t('fillingReport.filters.liquorCode')}: ${liquorCodeLabel}`
  return [businessYear, month, liquorCode].join(' / ')
}

function borderedRow(values: WorkbookCellValue[]): WorkbookCell[] {
  return values.map((value) => ({
    style: 'border',
    value,
  }))
}

function buildSummarySheetRows(createdAtLabel: string): WorkbookCell[][] {
  const header: WorkbookCellValue[] = [
    t('fillingReport.table.batchCode'),
    t('fillingReport.table.name'),
    t('fillingReport.table.latestFillingAt'),
    t('fillingReport.table.totalVolume'),
    t('fillingReport.table.liquorCode'),
    t('fillingReport.table.abv'),
    ...packageColumns.value,
    t('fillingReport.table.sampleVolume'),
    t('fillingReport.table.tankLeftVolume'),
    t('fillingReport.table.lossVolume'),
  ]

  const rows = sortedRows.value.map<WorkbookCell[]>((row) =>
    borderedRow([
      row.batchCode ?? '',
      row.displayName ?? '',
      row.latestFillingAt ? formatDateTime(row.latestFillingAt) : '',
      row.totalVolume ?? null,
      row.liquorCodeLabel || row.liquorCode || '',
      row.abv == null ? '' : formatAbv(row.abv),
      ...packageColumns.value.map((packageCode) => row.packageNumbers[packageCode] ?? null),
      row.sampleVolume ?? null,
      row.tankLeftVolume ?? null,
      row.lossVolume ?? null,
    ]),
  )

  return [
    [t('fillingReport.title')],
    [t('fillingReport.export.generatedAt'), createdAtLabel],
    [t('fillingReport.export.filters'), buildExportFilterSummary()],
    [],
    borderedRow(header),
    ...rows,
  ]
}

function buildDetailSheetRows(row: FillingReportRow): WorkbookCell[][] {
  const packageCodes = detailPackageColumnsFor(row)
  const detailRows = orderedDetailRowsFor(row)
  const totals = buildDetailTotals(detailRows, packageCodes)

  const headerRow1: WorkbookCellValue[] = [
    t('fillingReport.detail.table.date'),
    t('fillingReport.detail.table.beforeFilling'),
    ...packageCodes.flatMap((packageCode) => [packageCode, null]),
    t('fillingReport.detail.table.sampleVolume'),
    t('fillingReport.detail.table.totalQuantity'),
    null,
    null,
    t('fillingReport.detail.table.tankLeftVolume'),
    t('fillingReport.detail.table.lossVolume'),
  ]
  const headerRow2: WorkbookCellValue[] = [
    null,
    null,
    ...packageCodes.flatMap(() => [
      t('fillingReport.detail.table.packageNumber'),
      t('fillingReport.detail.table.packageVolume'),
    ]),
    null,
    t('fillingReport.detail.table.kegVolume'),
    t('fillingReport.detail.table.canBottleVolume'),
    t('fillingReport.detail.table.totalVolume'),
    null,
    null,
  ]

  const movementRows = detailRows.map<WorkbookCell[]>((detailRow) =>
    borderedRow([
      detailRow.movementAt ? formatDateTime(detailRow.movementAt) : '',
      [
        `${t('fillingReport.detail.depth')}: ${formatNumberValue(detailRow.tankFillStartDepth)}`,
        `${t('fillingReport.detail.quantity')}: ${formatVolumeValue(detailRow.tankFillStartVolume)}`,
      ].join('\n'),
      ...packageCodes.flatMap((packageCode) => [
        detailRow.packageNumbers[packageCode] ?? null,
        detailRow.packageVolumes[packageCode] ?? null,
      ]),
      detailRow.sampleVolume ?? null,
      detailRow.kegUnits ?? null,
      detailRow.canBottleUnits ?? null,
      detailRow.totalQuantity ?? null,
      detailRow.tankLeftVolume ?? null,
      detailRow.lossVolume ?? null,
    ]),
  )

  const totalRow: WorkbookCellValue[] = [
    null,
    null,
    ...packageCodes.flatMap((packageCode) => [
      totals.packageNumbers[packageCode] ?? null,
      totals.packageVolumes[packageCode] ?? null,
    ]),
    totals.sampleVolume ?? null,
    totals.kegUnits ?? null,
    totals.canBottleUnits ?? null,
    totals.totalQuantity ?? null,
    totals.tankLeftVolume ?? null,
    totals.lossVolume ?? null,
  ]

  return [
    [t('fillingReport.table.batchCode'), row.batchCode ?? '', t('fillingReport.table.name'), row.displayName ?? ''],
    [t('fillingReport.table.liquorCode'), row.liquorCodeLabel || row.liquorCode || '', t('fillingReport.table.abv'), row.abv == null ? '' : formatAbv(row.abv)],
    [t('fillingReport.detail.fillingTank'), formatTankSummary(row.fillingTanks)],
    [],
    borderedRow(headerRow1),
    borderedRow(headerRow2),
    ...movementRows,
    borderedRow(totalRow),
  ]
}

function buildExportSheets(createdAtLabel: string): WorkbookSheet[] {
  return [
    {
      name: 'Summary',
      rows: buildSummarySheetRows(createdAtLabel),
    },
    ...sortedRows.value.map((row, index) => ({
      name: row.batchCode ?? row.displayName ?? `Batch_${index + 1}`,
      rows: buildDetailSheetRows(row),
    })),
  ]
}

function exportExcel() {
  if (!sortedRows.value.length) {
    toast.error(t('fillingReport.export.noData'))
    return
  }

  try {
    exportLoading.value = true
    const createdAt = new Date()
    const fileName = `詰口一覧表_${buildLocalDateStamp(createdAt)}.xlsx`
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
    const detail = extractErrorMessage(err)
    toast.error(detail || t('fillingReport.export.failed'))
  } finally {
    exportLoading.value = false
  }
}

function resolveContainerKind(packageCode: string | null | undefined) {
  const normalized = String(packageCode ?? '').trim().toLowerCase()
  if (!normalized) return 'other'
  if (normalized.includes('keg')) return 'keg'
  return 'other'
}

function isUuidLike(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(
    value.trim(),
  )
}

function unknownPackageLabel(index: number) {
  const key = 'fillingReport.defaults.unknownPackage'
  const label = t(key, { index })
  return label === key ? `Unknown package ${index}` : label
}

function resolvePackageDisplayLabel(
  packageTypeId: string,
  lookup: Map<string, PackageLookup>,
  unresolvedPackageLabels: Map<string, string>,
) {
  const normalized = packageTypeId.trim()
  const packageDef = lookup.get(normalized)
  if (packageDef?.packageCode) return packageDef.packageCode
  if (!isUuidLike(normalized)) return normalized

  const existing = unresolvedPackageLabels.get(normalized)
  if (existing) return existing

  const label = unknownPackageLabel(unresolvedPackageLabels.size + 1)
  unresolvedPackageLabels.set(normalized, label)
  return label
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
    .select('id, package_code, package_type_id, unit_volume, volume_uom, volume_fix_flg, is_active')
    .eq('tenant_id', tenant)
    .order('package_code', { ascending: true })
  if (error) throw error

  const lookup = new Map<string, PackageLookup>()
  const packages: PreparedPackageRow[] = ((data ?? []) as PackageRow[]).flatMap((row) => {
    const id = String(row.id ?? '').trim()
    if (!id) return []

    const packageCode = String(row.package_code ?? '').trim() || id
    const packageTypeId = String(row.package_type_id ?? '').trim() || null
    const unitVolume = toNumber(row.unit_volume)
    const volumeUomCode = resolveVolumeUomCode(row.volume_uom ?? null, volumeUomCodeById.value)
    const unitVolumeLiters = convertToLiters(unitVolume, volumeUomCode)

    return [{
      id,
      packageCode,
      packageTypeId,
      lookup: {
        packageCode,
        volumeFix: row.volume_fix_flg !== false,
        unitVolumeLiters,
        volumeUomCode,
      } satisfies PackageLookup,
    }]
  })

  packages.forEach((row) => {
    lookup.set(row.id, row.lookup)
  })

  const rowsByPackageCode = new Map<string, PreparedPackageRow[]>()
  const rowsByPackageTypeId = new Map<string, PreparedPackageRow[]>()
  packages.forEach((row) => {
    if (row.packageCode && row.packageCode !== row.id) {
      rowsByPackageCode.set(row.packageCode, [...(rowsByPackageCode.get(row.packageCode) ?? []), row])
    }
    if (row.packageTypeId) {
      rowsByPackageTypeId.set(row.packageTypeId, [
        ...(rowsByPackageTypeId.get(row.packageTypeId) ?? []),
        row,
      ])
    }
  })

  rowsByPackageCode.forEach((rows, packageCode) => {
    const row = rows[0]
    if (rows.length === 1 && row && !lookup.has(packageCode)) lookup.set(packageCode, row.lookup)
  })
  rowsByPackageTypeId.forEach((rows, packageTypeId) => {
    const row = rows[0]
    if (rows.length === 1 && row && !lookup.has(packageTypeId)) lookup.set(packageTypeId, row.lookup)
  })

  return lookup
}

const volumeUomCodeById = ref<Map<string, string>>(new Map())

function resolveVolumeUomCode(value: string | null | undefined, uomCodeById: Map<string, string>) {
  if (!value) return null
  return uomCodeById.get(value) ?? value
}

async function loadVolumeUomCodes() {
  const { data, error } = await supabase
    .from('mst_uom')
    .select('id, code')
    .eq('dimension', 'volume')
    .order('code', { ascending: true })
  if (error) throw error

  return new Map<string, string>(
    ((data ?? []) as VolumeUomRow[]).flatMap((row) => {
      if (!row?.id || !row?.code) return []
      return [[String(row.id), String(row.code)]]
    }),
  )
}

async function loadLiquorCodeLabelMap() {
  const { optionRows, fallbackRows } = await loadAlcoholTypeReferenceData(supabase)
  return buildAlcoholTypeLabelMap(optionRows as RegistryRow[], fallbackRows as RegistryRow[])
}

function resolveLiquorCodeValue(value: string | number | null | undefined) {
  if (value == null) return null
  const normalized = String(value).trim()
  if (!normalized) return null
  return normalized
}

async function loadBatchInfo(batchIds: string[], alcoholTypeLabels: Map<string, string>) {
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
        entry.liquorCode = resolveLiquorCodeValue(rawValue)
      }

      if (code === 'actual_abv') {
        const num = toNumber(row.value_num)
        if (num != null) entry.abv = num
      }

      if (code === 'target_abv' && entry.abv == null) {
        const num = toNumber(row.value_num)
        if (num != null) entry.abv = num
      }
    })
  }

  const { data: batches, error: batchError } = await supabase
    .from('mes_batches')
    .select('id, batch_code, batch_label, product_name, actual_yield, meta, mes_recipe_id, released_reference_json, recipe_json')
    .eq('tenant_id', tenant)
    .in('id', uniqueIds)
  if (batchError) throw batchError

  ;((batches ?? []) as BatchRow[]).forEach((row) => {
    const attr = attrValueByBatch.get(String(row.id))
    const liquorCode = resolveLiquorCodeValue(resolveBatchBeerCategoryId(row, {
      beerCategoryId: attr?.liquorCode ?? null,
    }))
    infoMap.set(String(row.id), {
      batchCode: row.batch_code ?? null,
      displayName: resolveBatchDisplayName(row),
      actualYield: toNumber(row.actual_yield),
      liquorCode,
      liquorCodeLabel:
        resolveAlcoholTypeLabel(
          alcoholTypeLabels,
          liquorCode,
        ) ??
        liquorCode,
      abv:
        resolveBatchTargetAbv(row, {
          targetAbv: attr?.abv ?? null,
        }),
    })
  })

  return infoMap
}

function normalizeFillingLines(rawLines: unknown): FillingHistoryLine[] {
  if (!Array.isArray(rawLines)) return []
  return rawLines.map((line) => {
    const record = isRecord(line) ? line : {}
    const packageTypeId =
      typeof record.package_id === 'string' && record.package_id.trim()
        ? record.package_id.trim()
        : typeof record.package_type_id === 'string' && record.package_type_id.trim()
          ? record.package_type_id.trim()
          : null
    const rawQty = toNumber(record.qty)
    const rawVolume = toNumber(record.volume)
    return {
      package_type_id: packageTypeId,
      qty: rawQty,
      volume: rawVolume,
      sample_flg: record.sample_flg === true || record.sample_flg === 'true',
    } satisfies FillingHistoryLine
  })
}

function deriveFillingLinesFromMovementLines(
  lines: MovementLineRow[],
  lookup: Map<string, PackageLookup>,
  uomCodeById: Map<string, string>,
) {
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
    const lineUomCode =
      typeof line.uom_id === 'string' && line.uom_id.trim()
        ? (uomCodeById.get(line.uom_id) ?? line.uom_id)
        : null
    const fallbackVolumeLiters = isLiterUomCode(lineUomCode) ? qty : null
    const sampleFlag = meta?.sample_flg === true || meta?.sample_flg === 'true'
    return [{
      package_type_id: packageId,
      qty: unitCount ?? unit,
      volume: packageDef?.volumeFix ? null : (inputVolumeLiters ?? fallbackVolumeLiters),
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
  const fallbackLines = deriveFillingLinesFromMovementLines(
    linesByMovementId.get(String(movement.id)) ?? [],
    lookup,
    volumeUomCodeById.value,
  )
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

function lossVolumeFromMovement(
  meta: JsonRecord | null | undefined,
  event: FillingHistoryEvent,
  options: FillingCalculationOptions,
) {
  const persistedLoss = toNumber(meta?.tank_loss_volume)
  if (persistedLoss != null && Number.isFinite(persistedLoss)) return persistedLoss
  return packingLossFromEvent(event, options)
}

function packageNumberFromLine(line: FillingHistoryLine, lookup: Map<string, PackageLookup>) {
  const packageTypeId =
    typeof line.package_type_id === 'string' && line.package_type_id.trim() ? line.package_type_id.trim() : ''
  if (!packageTypeId) return null
  const packageDef = lookup.get(packageTypeId)
  if (packageDef?.volumeFix) return toNumber(line.qty)
  return toNumber(line.qty)
}

function compareTimestamp(a: string | null | undefined, b: string | null | undefined) {
  const aValue = a ? Date.parse(a) : Number.NEGATIVE_INFINITY
  const bValue = b ? Date.parse(b) : Number.NEGATIVE_INFINITY
  return aValue - bValue
}

function orderedDetailRowsFor(row: FillingReportRow) {
  return [...row.detailRows].sort((a, b) => {
    const result = compareTimestamp(a.movementAt, b.movementAt)
    return result !== 0 ? result : a.id.localeCompare(b.id)
  })
}

function detailPackageColumnsFor(row: FillingReportRow) {
  const columns = new Set<string>()
  row.detailRows.forEach((detailRow) => {
    Object.keys(detailRow.packageNumbers).forEach((key) => columns.add(key))
  })
  return Array.from(columns).sort((a, b) => a.localeCompare(b))
}

function buildDetailTotals(
  detailRows: FillingDetailRow[],
  detailPackageCodes: string[],
): FillingDetailTotals {
  const packageNumbers: Record<string, number | null> = {}
  const packageVolumes: Record<string, number | null> = {}
  let sampleVolumeTotal = 0
  let kegUnitsTotal = 0
  let canBottleUnitsTotal = 0
  let totalQuantityTotal = 0
  let lossVolumeTotal = 0
  let hasSampleVolume = false
  let hasKegUnits = false
  let hasCanBottleUnits = false
  let hasTotalQuantity = false
  let hasLossVolume = false

  detailPackageCodes.forEach((packageCode) => {
    let packageNumberTotal = 0
    let packageVolumeTotal = 0
    let hasPackageNumber = false
    let hasPackageVolume = false

    detailRows.forEach((row) => {
      const packageNumber = row.packageNumbers[packageCode]
      const packageVolume = row.packageVolumes[packageCode]
      if (packageNumber != null && Number.isFinite(packageNumber)) {
        packageNumberTotal += packageNumber
        hasPackageNumber = true
      }
      if (packageVolume != null && Number.isFinite(packageVolume)) {
        packageVolumeTotal += packageVolume
        hasPackageVolume = true
      }
    })

    packageNumbers[packageCode] = hasPackageNumber ? packageNumberTotal : null
    packageVolumes[packageCode] = hasPackageVolume ? packageVolumeTotal : null
  })

  detailRows.forEach((row) => {
    if (row.sampleVolume != null && Number.isFinite(row.sampleVolume)) {
      sampleVolumeTotal += row.sampleVolume
      hasSampleVolume = true
    }
    if (row.kegUnits != null && Number.isFinite(row.kegUnits)) {
      kegUnitsTotal += row.kegUnits
      hasKegUnits = true
    }
    if (row.canBottleUnits != null && Number.isFinite(row.canBottleUnits)) {
      canBottleUnitsTotal += row.canBottleUnits
      hasCanBottleUnits = true
    }
    if (row.totalQuantity != null && Number.isFinite(row.totalQuantity)) {
      totalQuantityTotal += row.totalQuantity
      hasTotalQuantity = true
    }
    if (row.lossVolume != null && Number.isFinite(row.lossVolume)) {
      lossVolumeTotal += row.lossVolume
      hasLossVolume = true
    }
  })

  return {
    packageNumbers,
    packageVolumes,
    sampleVolume: hasSampleVolume ? sampleVolumeTotal : null,
    kegUnits: hasKegUnits ? kegUnitsTotal : null,
    canBottleUnits: hasCanBottleUnits ? canBottleUnitsTotal : null,
    totalQuantity: hasTotalQuantity ? totalQuantityTotal : null,
    tankLeftVolume: detailRows.length > 0 ? detailRows[detailRows.length - 1]?.tankLeftVolume ?? null : null,
    lossVolume: hasLossVolume ? lossVolumeTotal : null,
  }
}

function buildReportRows(
  movements: MovementRow[],
  linesByMovementId: Map<string, MovementLineRow[]>,
  batchInfoById: Map<string, BatchInfo>,
  lookup: Map<string, PackageLookup>,
) {
  const rowsByBatch = new Map<string, AggregateBatchRow>()
  const unresolvedPackageLabels = new Map<string, string>()

  movements.forEach((movement) => {
    const meta = isRecord(movement.meta) ? movement.meta : {}
    const batchId =
      typeof meta.batch_id === 'string' && meta.batch_id.trim() ? meta.batch_id.trim() : ''
    if (!batchId) return

    const batchInfo = batchInfoById.get(batchId)
    const event = fillingEventFromMovement(movement, linesByMovementId, lookup)
    const sampleVolume = sampleVolumeFromEvent(event, fillingOptions)
    const totalQuantity = packingTotalLineVolumeFromEvent(event, fillingOptions)
    const lossVolume = lossVolumeFromMovement(meta, event, fillingOptions)
    const detailPackageGroups = new Map<string, DetailPackageGroup>()

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
        liquorCodeLabel: batchInfo?.liquorCodeLabel ?? batchInfo?.liquorCode ?? null,
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

      const label = resolvePackageDisplayLabel(packageTypeId, lookup, unresolvedPackageLabels)
      const quantity = packageNumberFromLine(line, lookup)
      const volume = resolveFillingLineVolumeFromEvent(line, fillingOptions)
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
          volume,
        })
        return
      }

      if (detailGroup.quantity == null || quantity == null) {
        detailGroup.quantity = detailGroup.quantity ?? quantity
      } else {
        detailGroup.quantity += quantity
      }
      if (detailGroup.volume == null || volume == null) {
        detailGroup.volume = detailGroup.volume ?? volume
        return
      }
      detailGroup.volume += volume
    })

    const orderedDetailGroups = Array.from(detailPackageGroups.values()).sort((a, b) =>
      a.label.localeCompare(b.label),
    )
    const detailPackageNumbers = orderedDetailGroups.reduce<Record<string, number | null>>((acc, group) => {
      acc[group.label] = group.quantity
      return acc
    }, {})
    const detailPackageVolumes = orderedDetailGroups.reduce<Record<string, number | null>>((acc, group) => {
      acc[group.label] = group.volume
      return acc
    }, {})
    let kegUnits: number | null = null
    let canBottleUnits: number | null = null
    orderedDetailGroups.forEach((group) => {
      if (group.quantity == null || !Number.isFinite(group.quantity)) return
      if (resolveContainerKind(group.label) === 'keg') {
        kegUnits = (kegUnits ?? 0) + group.quantity
        return
      }
      canBottleUnits = (canBottleUnits ?? 0) + group.quantity
    })

    row.detailRows.push({
      id: String(movement.id),
      batchId,
      movementAt: movement.movement_at ?? null,
      tankNo: resolveTankNumber(meta),
      tankFillStartDepth: toNumber(meta.tank_fill_start_depth),
      tankFillStartVolume: toNumber(meta.tank_fill_start_volume),
      packageNumbers: detailPackageNumbers,
      packageVolumes: detailPackageVolumes,
      sampleVolume,
      kegUnits,
      canBottleUnits,
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
      liquorCodeLabel: row.liquorCodeLabel,
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
    const [uomCodeById, alcoholTypeLabels, movementRowsBySource, movementRowsByIntent] = await Promise.all([
      loadVolumeUomCodes(),
      loadLiquorCodeLabelMap(),
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

    volumeUomCodeById.value = uomCodeById
    liquorCodeLabelMap.value = alcoholTypeLabels
    const packageLookup = await loadPackageLookup(tenant)
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
        .select('movement_id, package_id, qty, unit, uom_id, meta')
        .in('movement_id', movementIds),
      loadBatchInfo(batchIds, alcoholTypeLabels),
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

onBeforeUnmount(() => {
  clearExportDownload()
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
