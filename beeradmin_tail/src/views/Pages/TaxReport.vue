<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white p-4 text-gray-900">
      <div class="w-full space-y-4">
        <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h1 class="text-xl font-semibold">{{ t('taxReport.title') }}</h1>
            <p class="text-sm text-gray-500">{{ t('taxReport.subtitle') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <button
              class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-50 disabled:opacity-50"
              :disabled="!hasColumnFilters"
              type="button"
              @click="clearColumnFilters"
            >
              {{ t('common.clearFilters') }}
            </button>
            <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" @click="openCreate">
              {{ t('taxReport.actions.new') }}
            </button>
            <button
              class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-50 disabled:opacity-50"
              :disabled="loading"
              @click="fetchReports"
            >
              {{ t('common.refresh') }}
            </button>
          </div>
        </header>

        <section class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
          <form class="grid grid-cols-1 gap-3 md:grid-cols-6" @submit.prevent>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('taxReport.filters.taxType') }}</label>
              <select v-model="filters.taxType" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="">{{ t('common.all') }}</option>
                <option v-for="type in taxTypeOptions" :key="type" :value="type">{{ taxTypeLabel(type) }}</option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('taxReport.filters.taxYear') }}</label>
              <select v-model="filters.taxYear" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="">{{ t('common.all') }}</option>
                <option v-for="year in yearOptions" :key="year" :value="String(year)">{{ year }}</option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('taxReport.filters.taxMonth') }}</label>
              <select
                v-model="filters.taxMonth"
                class="h-[40px] w-full rounded border bg-white px-3"
                :disabled="filters.taxType === 'yearly'"
              >
                <option value="">{{ t('common.all') }}</option>
                <option v-for="month in monthOptions" :key="month" :value="String(month)">{{ month }}</option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('taxReport.filters.declarationType') }}</label>
              <select v-model="filters.declarationType" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="">{{ t('common.all') }}</option>
                <option v-for="type in declarationTypeOptions" :key="type" :value="type">{{ declarationTypeLabel(type) }}</option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('taxReport.filters.status') }}</label>
              <select v-model="filters.status" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="">{{ t('common.all') }}</option>
                <option v-for="status in statusOptions" :key="status" :value="status">{{ statusLabel(status) }}</option>
              </select>
            </div>
          </form>
        </section>

        <section class="overflow-x-auto rounded-xl border border-gray-200 bg-white shadow-sm">
          <table class="min-w-full text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-500">
              <tr>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="columnFilters.taxType"
                    :active-sort-key="sortKey"
                    :all-label="t('common.all')"
                    :filter-options="taxTypeColumnFilterOptions"
                    filter-type="select"
                    :label="t('taxReport.card.taxType')"
                    sort-key="taxType"
                    :sort-direction="sortDirection"
                    @sort="setColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="columnFilters.period"
                    :active-sort-key="sortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('taxReport.card.period')"
                    sort-key="period"
                    :sort-direction="sortDirection"
                    @sort="setColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="columnFilters.declarationType"
                    :active-sort-key="sortKey"
                    :all-label="t('common.all')"
                    :filter-options="declarationTypeColumnFilterOptions"
                    filter-type="select"
                    :label="t('taxReport.card.declarationType')"
                    sort-key="declarationType"
                    :sort-direction="sortDirection"
                    @sort="setColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="columnFilters.status"
                    :active-sort-key="sortKey"
                    :all-label="t('common.all')"
                    :filter-options="statusColumnFilterOptions"
                    filter-type="select"
                    :label="t('taxReport.card.status')"
                    sort-key="status"
                    :sort-direction="sortDirection"
                    @sort="setColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-right">
                  <TableColumnHeader
                    v-model:filter-value="columnFilters.totalTax"
                    align="right"
                    :active-sort-key="sortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('taxReport.card.totalTax')"
                    sort-key="totalTax"
                    :sort-direction="sortDirection"
                    @sort="setColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="columnFilters.productionVolume"
                    :active-sort-key="sortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('taxReport.card.productionVolume')"
                    sort-key="productionVolume"
                    :sort-direction="sortDirection"
                    @sort="setColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="columnFilters.reportFiles"
                    :active-sort-key="sortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('taxReport.card.reportFiles') || t('taxReport.card.xmlFiles')"
                    sort-key="reportFiles"
                    :sort-direction="sortDirection"
                    @sort="setColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="columnFilters.attachments"
                    :active-sort-key="sortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('taxReport.card.attachments')"
                    sort-key="attachments"
                    :sort-direction="sortDirection"
                    @sort="setColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="row in visibleReportRows" :key="row.id" class="align-top">
                <td class="px-3 py-3 text-gray-700">{{ taxTypeLabel(row.tax_type) }}</td>
                <td class="px-3 py-3 text-gray-700">
                  <button class="text-left text-blue-600 hover:underline" type="button" @click="openEdit(row)">
                    {{ formatPeriod(row) }}
                  </button>
                </td>
                <td class="px-3 py-3 text-gray-700">{{ declarationTypeLabel(row.declaration_type, row.amendment_no) }}</td>
                <td class="px-3 py-3 text-gray-700">{{ statusLabel(row.status) }}</td>
                <td class="px-3 py-3 text-right font-medium text-gray-900">{{ formatCurrency(displayTotalTax(row)) }}</td>
                <td class="wrap-cell px-3 py-3 text-gray-700">
                  <div v-if="row.volume_breakdown.length" class="space-y-1">
                    <div v-for="item in visibleBreakdownItems(row)" :key="item.key">
                      {{ breakdownLabel(item) }}
                    </div>
                    <div v-if="hasOverflowBreakdown(row)">...</div>
                  </div>
                  <span v-else class="text-gray-400">—</span>
                </td>
                <td class="wrap-cell px-3 py-3">
                  <div v-if="row.report_files.length" class="space-y-1 text-blue-600">
                    <button
                      v-for="file in row.report_files"
                      :key="`${row.id}-${file.fileType}-${file.fileName}`"
                      class="block text-left hover:underline"
                      type="button"
                      @click="downloadXmlForRowFile(row, file)"
                    >
                      {{ file.fileName }}
                    </button>
                  </div>
                  <span v-else class="text-gray-400">—</span>
                </td>
                <td class="wrap-cell px-3 py-3">
                  <div v-if="row.attachment_files.length" class="space-y-1 text-blue-600">
                    <div v-for="file in row.attachment_files" :key="file">{{ file }}</div>
                  </div>
                  <span v-else class="text-gray-400">—</span>
                </td>
                <td class="px-3 py-3">
                  <div class="flex flex-wrap items-center gap-2">
                    <button
                      class="rounded border px-3 py-1.5 text-xs hover:bg-gray-100 disabled:opacity-50"
                      type="button"
                      :disabled="deletingReportId === row.id || !canDeleteReport(row)"
                      @click="deleteReport(row)"
                    >
                      {{ t('common.delete') }}
                    </button>
                  </div>
                </td>
              </tr>
              <tr v-if="!loading && visibleReportRows.length === 0">
                <td colspan="9" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </section>

        <div v-if="showCreatePrompt" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
          <div class="w-full max-w-xl rounded-xl border bg-white shadow-lg">
            <header class="border-b px-4 py-3">
              <h3 class="font-semibold">{{ t('taxReport.createPrompt.title') }}</h3>
            </header>
            <section class="space-y-4 p-4">
              <p class="text-sm text-gray-500">{{ t('taxReport.createPrompt.subtitle') }}</p>
              <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
                <div>
                  <label class="mb-1 block text-sm text-gray-600">{{ t('taxReport.form.taxType') }}</label>
                  <select v-model="promptForm.tax_type" class="h-[40px] w-full rounded border bg-white px-3">
                    <option v-for="type in taxTypeOptions" :key="type" :value="type">{{ taxTypeLabel(type) }}</option>
                  </select>
                </div>
                <div>
                  <label class="mb-1 block text-sm text-gray-600">{{ t('taxReport.form.taxYear') }}</label>
                  <input
                    v-model.number="promptForm.tax_year"
                    type="number"
                    min="2000"
                    class="h-[40px] w-full rounded border px-3"
                  />
                </div>
                <div v-if="promptForm.tax_type === 'monthly'">
                  <label class="mb-1 block text-sm text-gray-600">{{ t('taxReport.form.taxMonth') }}</label>
                  <select v-model.number="promptForm.tax_month" class="h-[40px] w-full rounded border bg-white px-3">
                    <option v-for="month in monthOptions" :key="month" :value="month">{{ month }}</option>
                  </select>
                </div>
                <div>
                  <label class="mb-1 block text-sm text-gray-600">{{ t('taxReport.form.declarationType') }}</label>
                  <select v-model="promptForm.declaration_type" class="h-[40px] w-full rounded border bg-white px-3">
                    <option v-for="type in declarationTypeOptions" :key="type" :value="type">{{ declarationTypeLabel(type) }}</option>
                  </select>
                </div>
                <div v-if="promptForm.declaration_type === 'amended'" class="md:col-span-3">
                  <label class="mb-1 block text-sm text-gray-600">{{ t('taxReport.form.originalReport') }}</label>
                  <select v-model="promptForm.original_report_id" class="h-[40px] w-full rounded border bg-white px-3">
                    <option value="">{{ t('taxReport.createPrompt.selectOriginal') }}</option>
                    <option v-for="report in amendmentSourceOptions" :key="report.id" :value="report.id">
                      {{ originalReportOptionLabel(report) }}
                    </option>
                  </select>
                </div>
                <div v-if="promptForm.declaration_type === 'late' || promptForm.declaration_type === 'amended'" class="md:col-span-3">
                  <label class="mb-1 block text-sm text-gray-600">{{ t('taxReport.form.declarationReason') }}</label>
                  <textarea
                    v-model="promptForm.declaration_reason"
                    rows="3"
                    class="w-full rounded border px-3 py-2"
                  />
                </div>
              </div>
            </section>
            <footer class="flex items-center justify-end gap-2 border-t px-4 py-3">
              <button class="rounded border px-3 py-2 hover:bg-gray-50" @click="closeCreatePrompt">
                {{ t('common.cancel') }}
              </button>
              <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" @click="startCreateFromPrompt">
                {{ t('taxReport.createPrompt.confirm') }}
              </button>
            </footer>
          </div>
        </div>
      </div>
    </div>

    <ConfirmActionDialog
      :open="confirmDialog.open"
      :title="confirmDialog.title"
      :message="confirmDialog.message"
      :confirm-label="confirmDialog.confirmLabel"
      :cancel-label="confirmDialog.cancelLabel"
      :tone="confirmDialog.tone"
      @cancel="cancelConfirmation"
      @confirm="acceptConfirmation"
    />
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'
import ConfirmActionDialog from '@/components/common/ConfirmActionDialog.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import TableColumnHeader from '@/components/common/TableColumnHeader.vue'
import { useConfirmDialog } from '@/composables/useConfirmDialog'
import { useColumnTableControls, type ColumnSortDirection } from '@/composables/useColumnTableControls'
import { formatAbvPercent } from '@/lib/abvFormat'
import { formatYen } from '@/lib/moneyFormat'
import { formatTotalVolumeFromLiters } from '@/lib/volumeFormat'
import { supabase } from '@/lib/supabase'
import {
  createEmptyTaxReportProfile,
  fetchTaxReportProfileForTenant,
  type TaxReportProfile,
} from '@/lib/taxReportProfile'
import {
  calculateTaxTotalAmount,
  buildXmlPayload,
  downloadStoredTaxReportFile,
  disposeItemsFromBreakdown,
  fetchPriorFiscalYearStandardTaxAmount,
  inferStoredFileType,
  isDisasterDeductionItem,
  isDisposeFilename,
  normalizeReport,
  resolveTaxEvent,
  summaryItemsFromBreakdown,
  type JsonMap,
  type TaxDeclarationType,
  type TaxReportStoredFile,
  type TaxReportRow,
  type TaxVolumeItem,
} from '@/lib/taxReport'

const TABLE = 'tax_reports'
const TAX_REPORT_REDIRECT_ERROR_TOAST_KEY = 'beeradmin.taxReport.redirectErrorToast'
const REPORT_SELECT = 'id, tax_type, tax_year, tax_month, status, declaration_type, declaration_reason, original_report_id, previous_report_id, amendment_no, previous_confirmed_payable_tax_amount, previous_confirmed_refund_tax_amount, correction_delta_tax_amount, total_tax_amount, volume_breakdown, comparison_breakdown, report_files, attachment_files, created_at, updated_at'
const STATUS_OPTIONS = ['draft', 'stale', 'submitted', 'approved'] as const
const TAX_TYPE_OPTIONS = ['monthly'] as const
const DECLARATION_TYPE_OPTIONS: TaxDeclarationType[] = ['on_time', 'late', 'amended']
type ReportTableSortKey =
  | 'taxType'
  | 'period'
  | 'declarationType'
  | 'status'
  | 'totalTax'
  | 'productionVolume'
  | 'reportFiles'
  | 'attachments'

const { t, tm, locale } = useI18n()
const router = useRouter()
const { confirmDialog, requestConfirmation, cancelConfirmation, acceptConfirmation } = useConfirmDialog()

const pageTitle = computed(() => t('taxReport.title'))
const rows = ref<TaxReportRow[]>([])
const amendmentSourceRows = ref<TaxReportRow[]>([])
const loading = ref(false)
const deletingReportId = ref('')
const showCreatePrompt = ref(false)
const tenantId = ref<string | null>(null)
const tenantName = ref('')
const tenantProfile = ref<TaxReportProfile>(createEmptyTaxReportProfile())

const filters = reactive({ taxType: '', taxYear: '', taxMonth: '', declarationType: '', status: '' })
const promptForm = reactive({
  tax_type: 'monthly',
  tax_year: new Date().getFullYear(),
  tax_month: new Date().getMonth() + 1,
  declaration_type: 'on_time' as TaxDeclarationType,
  declaration_reason: '',
  original_report_id: '',
})

const statusOptions = STATUS_OPTIONS
const taxTypeOptions = TAX_TYPE_OPTIONS
const declarationTypeOptions = DECLARATION_TYPE_OPTIONS
const {
  sortKey,
  sortDirection,
  columnFilters,
  sortedRows: visibleReportRows,
  hasColumnFilters,
  setSort,
  clearColumnFilters,
} = useColumnTableControls<TaxReportRow, ReportTableSortKey>(
  rows,
  [
    { key: 'taxType', sortValue: (row) => taxTypeLabel(row.tax_type), filterValue: (row) => row.tax_type, filterType: 'select' },
    { key: 'period', sortValue: (row) => row.tax_year * 100 + (row.tax_month ?? 0), filterValue: (row) => formatPeriod(row), filterType: 'text' },
    { key: 'declarationType', sortValue: (row) => declarationTypeSortValue(row), filterValue: (row) => row.declaration_type, filterType: 'select' },
    { key: 'status', sortValue: (row) => statusLabel(row.status), filterValue: (row) => row.status, filterType: 'select' },
    { key: 'totalTax', sortValue: (row) => displayTotalTax(row), filterValue: (row) => formatCurrency(displayTotalTax(row)), filterType: 'text' },
    { key: 'productionVolume', sortValue: (row) => reportVolumeText(row), filterType: 'text' },
    { key: 'reportFiles', sortValue: (row) => reportFileText(row), filterType: 'text' },
    { key: 'attachments', sortValue: (row) => row.attachment_files.join(' '), filterType: 'text' },
  ],
  'period',
  'desc',
)

const taxTypeColumnFilterOptions = computed(() =>
  taxTypeOptions.map((type) => ({ value: type, label: taxTypeLabel(type) })),
)

const statusColumnFilterOptions = computed(() =>
  statusOptions.map((status) => ({ value: status, label: statusLabel(status) })),
)

const declarationTypeColumnFilterOptions = computed(() =>
  declarationTypeOptions.map((type) => ({ value: type, label: declarationTypeLabel(type) })),
)

const amendmentSourceOptions = computed(() =>
  amendmentSourceRows.value
    .filter((row) =>
      row.tax_type === promptForm.tax_type &&
      row.tax_year === promptForm.tax_year &&
      row.tax_month === promptForm.tax_month &&
      (row.status === 'submitted' || row.status === 'approved') &&
      (row.declaration_type === 'on_time' || row.declaration_type === 'late' || row.declaration_type === 'amended'),
    )
    .sort((a, b) => declarationTypeSortValue(b).localeCompare(declarationTypeSortValue(a))),
)

const yearOptions = computed(() => {
  const current = new Date().getFullYear()
  const years = new Set<number>()
  for (let i = current - 3; i <= current + 1; i += 1) years.add(i)
  rows.value.forEach((row) => years.add(row.tax_year))
  return Array.from(years).sort((a, b) => b - a)
})

const monthOptions = computed(() => [4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3])
function statusLabel(status: string) {
  const map = tm('taxReport.statusMap')
  if (!map || typeof map !== 'object') return status
  const label = (map as Record<string, unknown>)[status]
  return typeof label === 'string' ? label : status
}

function taxTypeLabel(taxType: string) {
  const map = tm('taxReport.taxTypeMap')
  if (!map || typeof map !== 'object') return taxType
  const label = (map as Record<string, unknown>)[taxType]
  return typeof label === 'string' ? label : taxType
}

function declarationTypeLabel(type: string, amendmentNo?: number | null) {
  const map = tm('taxReport.declarationTypeMap')
  const label = map && typeof map === 'object'
    ? (map as Record<string, unknown>)[type]
    : null
  const text = typeof label === 'string' ? label : type
  if (type === 'amended' && Number.isFinite(amendmentNo)) return `${text} #${amendmentNo}`
  return text
}

function declarationTypeSortValue(row: Pick<TaxReportRow, 'declaration_type' | 'amendment_no'>) {
  const rank = row.declaration_type === 'amended'
    ? 200 + (row.amendment_no ?? 0)
    : row.declaration_type === 'late'
      ? 100
      : 0
  return String(rank).padStart(4, '0')
}

function originalReportOptionLabel(row: TaxReportRow) {
  return `${formatPeriod(row)} · ${declarationTypeLabel(row.declaration_type, row.amendment_no)} · ${statusLabel(row.status)} · ${formatCurrency(displayTotalTax(row))}`
}

function movementTypeLabel(value: string) {
  const map = tm('taxReport.movementTypeMap')
  if (!map || typeof map !== 'object') return value
  const label = (map as Record<string, unknown>)[value]
  return typeof label === 'string' ? label : value
}

function taxEventLabel(value: string | null | undefined) {
  if (!value) return ''
  const map = tm('taxReport.taxEventMap')
  if (!map || typeof map !== 'object') return value
  const label = (map as Record<string, unknown>)[value]
  return typeof label === 'string' ? label : value
}

function formatPeriod(row: TaxReportRow) {
  if (row.tax_type === 'yearly') return `${row.tax_year} / —`
  return `${row.tax_year} / ${row.tax_month || '—'}`
}

function formatCurrency(value: number | null | undefined) {
  return formatYen(value, locale.value)
}

function formatVolume(value: number | null | undefined) {
  return formatTotalVolumeFromLiters(value, locale.value)
}

function formatAbv(value: number | null | undefined) {
  return formatAbvPercent(value, locale.value, t('taxReport.abvUnknown'))
}

function breakdownLabel(item: TaxVolumeItem) {
  const actualTaxEvent = resolveTaxEvent(item.move_type, item.tax_event)
  const movementLabel = taxEventLabel(actualTaxEvent) || movementTypeLabel(item.move_type)
  return `${movementLabel} · ${item.categoryName} (${formatAbv(item.abv)}): ${formatVolume(item.volume_l)}`
}

function reportVolumeText(row: Pick<TaxReportRow, 'volume_breakdown'>) {
  return row.volume_breakdown.map((item) => breakdownLabel(item)).join(' ')
}

function reportFileText(row: Pick<TaxReportRow, 'report_files'>) {
  return row.report_files.map((file) => file.fileName).join(' ')
}

function setColumnSort(key: string, direction?: ColumnSortDirection) {
  setSort(key as ReportTableSortKey, direction)
}

function visibleBreakdownItems(row: Pick<TaxReportRow, 'volume_breakdown'>) {
  return row.volume_breakdown.slice(0, 3)
}

function hasOverflowBreakdown(row: Pick<TaxReportRow, 'volume_breakdown'>) {
  return row.volume_breakdown.length > 3
}

function displayTotalTax(row: TaxReportRow) {
  if (row.volume_breakdown.length > 0) {
    return calculateTaxTotalAmount(row.volume_breakdown)
  }
  return row.total_tax_amount
}

function canDeleteReport(row: TaxReportRow) {
  return row.status === 'draft' || row.status === 'stale'
}

function downloadBlob(filename: string, blob: Blob) {
  const url = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = filename
  document.body.appendChild(anchor)
  anchor.click()
  anchor.remove()
  URL.revokeObjectURL(url)
}

function downloadTextFile(filename: string, content: string, mime = 'application/xml') {
  downloadBlob(filename, new Blob([content], { type: mime }))
}

function showQueuedRedirectErrorToast() {
  try {
    const message = window.sessionStorage.getItem(TAX_REPORT_REDIRECT_ERROR_TOAST_KEY)
    if (!message) return
    window.sessionStorage.removeItem(TAX_REPORT_REDIRECT_ERROR_TOAST_KEY)
    toast.error(message)
  } catch (err) {
    console.warn('Failed to read tax report redirect toast', err)
  }
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

async function loadTenantTaxReportProfile() {
  const tenant = await ensureTenant()
  const loaded = await fetchTaxReportProfileForTenant(supabase, tenant)
  tenantName.value = loaded.tenantName
  tenantProfile.value = loaded.profile
}

async function fetchReports() {
  try {
    loading.value = true
    const tenant = await ensureTenant()
    let query = supabase
      .from(TABLE)
      .select(REPORT_SELECT)
      .eq('tenant_id', tenant)
      .order('tax_year', { ascending: false })
      .order('tax_month', { ascending: false })
      .order('declaration_type', { ascending: true })
      .order('amendment_no', { ascending: true })

    if (filters.taxType) query = query.eq('tax_type', filters.taxType)
    if (filters.taxYear) query = query.eq('tax_year', Number(filters.taxYear))
    if (filters.taxMonth) query = query.eq('tax_month', Number(filters.taxMonth))
    if (filters.declarationType) query = query.eq('declaration_type', filters.declarationType)
    if (filters.status) query = query.eq('status', filters.status)

    const { data, error } = await query
    if (error) throw error

    rows.value = (data ?? []).map((row) => normalizeReport(row as JsonMap))
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    loading.value = false
  }
}

async function fetchAmendmentSourceRows() {
  try {
    const tenant = await ensureTenant()
    const { data, error } = await supabase
      .from(TABLE)
      .select(REPORT_SELECT)
      .eq('tenant_id', tenant)
      .eq('tax_type', promptForm.tax_type)
      .eq('tax_year', promptForm.tax_year)
      .eq('tax_month', promptForm.tax_month)
      .in('status', ['submitted', 'approved'])
      .order('declaration_type', { ascending: true })
      .order('amendment_no', { ascending: true })
    if (error) throw error
    amendmentSourceRows.value = (data ?? []).map((row) => normalizeReport(row as JsonMap))
  } catch (err) {
    console.error(err)
    amendmentSourceRows.value = []
    toast.error(err instanceof Error ? err.message : String(err))
  }
}

function openCreate() {
  promptForm.tax_type = filters.taxType || 'monthly'
  promptForm.tax_year = filters.taxYear ? Number(filters.taxYear) : new Date().getFullYear()
  promptForm.tax_month = filters.taxMonth ? Number(filters.taxMonth) : new Date().getMonth() + 1
  promptForm.declaration_type = (filters.declarationType as TaxDeclarationType) || 'on_time'
  promptForm.declaration_reason = ''
  promptForm.original_report_id = ''
  showCreatePrompt.value = true
  void fetchAmendmentSourceRows()
}

function closeCreatePrompt() {
  showCreatePrompt.value = false
}

async function startCreateFromPrompt() {
  if (!promptForm.tax_year) {
    toast.info(t('taxReport.errors.taxYearRequired'))
    return
  }
  if (promptForm.tax_type === 'monthly' && !promptForm.tax_month) {
    toast.info(t('taxReport.errors.taxMonthRequired'))
    return
  }
  if ((promptForm.declaration_type === 'late' || promptForm.declaration_type === 'amended') && !promptForm.declaration_reason.trim()) {
    toast.info(t('taxReport.errors.declarationReasonRequired'))
    return
  }
  if (promptForm.declaration_type === 'amended' && !promptForm.original_report_id) {
    toast.info(t('taxReport.errors.originalReportRequired'))
    return
  }
  if (promptForm.declaration_type !== 'amended') {
    const lockedBase = rows.value.find((row) =>
      row.tax_type === promptForm.tax_type &&
      row.tax_year === promptForm.tax_year &&
      row.tax_month === promptForm.tax_month &&
      (row.declaration_type === 'on_time' || row.declaration_type === 'late') &&
      (row.status === 'submitted' || row.status === 'approved'),
    )
    if (lockedBase) {
      toast.info(t('taxReport.errors.baseDeclarationLocked'))
      return
    }
  }
  showCreatePrompt.value = false
  await router.push({
    name: 'TaxReportCreate',
    query: {
      taxType: promptForm.tax_type,
      taxYear: String(promptForm.tax_year),
      taxMonth: promptForm.tax_type === 'monthly' ? String(promptForm.tax_month) : undefined,
      declarationType: promptForm.declaration_type,
      declarationReason: promptForm.declaration_reason.trim() || undefined,
      originalReportId: promptForm.declaration_type === 'amended' ? promptForm.original_report_id : undefined,
    },
  })
}

async function openEdit(row: TaxReportRow) {
  await router.push({ name: 'TaxReportEdit', params: { id: row.id } })
}

async function deleteReport(row: TaxReportRow) {
  if (!canDeleteReport(row)) {
    toast.info(t('taxReport.deleteDraftOnly'))
    return
  }
  const confirmed = await requestConfirmation({
    title: t('common.delete'),
    message: t('taxReport.deleteConfirm', { period: formatPeriod(row) }),
    confirmLabel: t('common.delete'),
    tone: 'danger',
  })
  if (!confirmed) return

  try {
    deletingReportId.value = row.id
    const tenant = await ensureTenant()
    const { error } = await supabase.from(TABLE).delete().eq('id', row.id).eq('tenant_id', tenant)
    if (error) throw error
    toast.success(t('taxReport.deleted'))
    await fetchReports()
  } catch (err) {
    console.error(err)
    toast.error(t('taxReport.deleteFailed', { message: err instanceof Error ? err.message : String(err) }))
  } finally {
    deletingReportId.value = ''
  }
}

async function downloadXmlForRowFile(row: TaxReportRow, file: TaxReportStoredFile) {
  if (file.storageBucket && file.storagePath) {
    try {
      const blob = await downloadStoredTaxReportFile({ supabase, file })
      downloadBlob(file.fileName, blob)
      return
    } catch (err) {
      console.error(err)
      toast.error(err instanceof Error ? err.message : String(err))
      return
    }
  }

  const dispose =
    file.fileType === 'tax_report_dispose_xml' ||
    (file.fileType === 'legacy' && isDisposeFilename(file.fileName, row))
  const fileType = inferStoredFileType(file.fileName)
  if (fileType === 'taxable_removal_excel') {
    toast.info(t('taxReport.fileUnavailable'))
    return
  }

  const breakdown = dispose
    ? disposeItemsFromBreakdown(row.volume_breakdown)
    : [
        ...summaryItemsFromBreakdown(row.volume_breakdown),
        ...disposeItemsFromBreakdown(row.volume_breakdown).filter(isDisasterDeductionItem),
      ]
  if (!breakdown.length) {
    toast.info(t('taxReport.emptyBreakdown'))
    return
  }

  try {
    const tenant = await ensureTenant()
    const priorFiscalYearStandardTaxAmount = dispose
      ? 0
      : await fetchPriorFiscalYearStandardTaxAmount({
          supabase,
          tenantId: tenant,
          taxYear: row.tax_year,
          taxMonth: row.tax_month,
          excludeReportId: row.id,
        })
    const xml = buildXmlPayload({
      taxType: row.tax_type,
      taxYear: row.tax_year,
      taxMonth: row.tax_month,
      declarationType: row.declaration_type,
      declarationReason: row.declaration_reason,
      previousConfirmedPayableTaxAmount: row.previous_confirmed_payable_tax_amount,
      previousConfirmedRefundTaxAmount: row.previous_confirmed_refund_tax_amount,
      breakdown,
      profile: tenantProfile.value,
      tenantId: tenant,
      tenantName: tenantName.value,
      priorFiscalYearStandardTaxAmount,
      includeLia130: !dispose,
    })
    downloadTextFile(file.fileName, await xml)
  } catch (err) {
    toast.error(err instanceof Error ? err.message : String(err))
    console.error(err)
  }
}

onMounted(async () => {
  showQueuedRedirectErrorToast()
  try {
    await ensureTenant()
    await loadTenantTaxReportProfile()
    await fetchReports()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
})

watch(
  () => ({ ...filters }),
  async () => {
    await fetchReports()
  },
  { deep: true },
)

watch(
  () => filters.taxType,
  (value) => {
    if (value === 'yearly') filters.taxMonth = ''
  },
)

watch(
  () => [showCreatePrompt.value, promptForm.tax_type, promptForm.tax_year, promptForm.tax_month],
  () => {
    if (!showCreatePrompt.value) return
    promptForm.original_report_id = ''
    void fetchAmendmentSourceRows()
  },
)
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}

.wrap-cell {
  min-width: 14rem;
  white-space: normal;
}
</style>
