<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white p-4 text-gray-900">
      <div class="mx-auto max-w-6xl space-y-4">
        <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h1 class="text-xl font-semibold">{{ pageTitle }}</h1>
            <p class="text-sm text-gray-500">{{ t('taxReportEditor.subtitle') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <button class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-50" @click="goBack">
              {{ t('taxReportEditor.actions.back') }}
            </button>
          </div>
        </header>

        <section class="space-y-6 rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
          <section class="grid grid-cols-1 gap-4 md:grid-cols-4">
            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('taxReport.form.taxType') }}<span class="text-red-600">*</span>
              </label>
              <select
                v-model="form.tax_type"
                class="h-[40px] w-full rounded border bg-white px-3"
                disabled
              >
                <option v-for="type in taxTypeOptions" :key="type" :value="type">{{ taxTypeLabel(type) }}</option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('taxReport.form.taxYear') }}<span class="text-red-600">*</span>
              </label>
              <input
                v-model.number="form.tax_year"
                type="number"
                min="2000"
                class="h-[40px] w-full rounded border px-3"
                disabled
              />
            </div>
            <div v-if="form.tax_type === 'monthly'">
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('taxReport.form.taxMonth') }}<span class="text-red-600">*</span>
              </label>
              <select
                v-model.number="form.tax_month"
                class="h-[40px] w-full rounded border bg-white px-3"
                disabled
              >
                <option v-for="month in monthOptions" :key="month" :value="month">{{ month }}</option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('taxReport.form.status') }}<span class="text-red-600">*</span>
              </label>
              <select v-model="form.status" class="h-[40px] w-full rounded border bg-white px-3" :disabled="!editing">
                <option v-for="status in statusOptions" :key="status" :value="status">{{ statusLabel(status) }}</option>
              </select>
              <p v-if="errors.status" class="mt-1 text-xs text-red-600">{{ errors.status }}</p>
            </div>
            <div class="md:col-span-4">
              <label class="mb-1 block text-sm text-gray-600">{{ t('taxReport.form.totalTax') }}</label>
              <div class="flex h-[40px] items-center rounded border bg-gray-50 px-3 text-sm text-gray-700">
                {{ formatCurrency(totalTaxAmount) }}
              </div>
            </div>
          </section>

          <section class="space-y-3">
            <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
              <div>
                <h2 class="text-base font-semibold">{{ t('taxReportEditor.sections.movement.title') }}</h2>
                <p class="text-xs text-gray-500">{{ t('taxReportEditor.sections.movement.subtitle') }}</p>
              </div>
              <div class="flex flex-wrap items-center gap-2">
                <button
                  class="rounded border px-3 py-2 hover:bg-gray-50 disabled:opacity-50"
                  :disabled="generating"
                  @click="createXmlForSummary"
                >
                  {{ t('taxReport.actions.createXml') }}
                </button>
                <a v-if="summaryXmlUrl" :href="summaryXmlUrl" :download="summaryXmlName" class="text-xs text-blue-600">
                  {{ t('taxReport.actions.downloadXml') }}
                </a>
              </div>
            </div>
            <div class="overflow-x-auto rounded border bg-gray-50">
              <table class="min-w-full text-sm">
                <thead class="bg-white text-xs uppercase text-gray-500">
                  <tr>
                    <th class="px-3 py-2 text-left">
                      <button class="inline-flex items-center gap-1 hover:text-gray-700" type="button" @click="sortMovementTable('kubun')">
                        <span>{{ t('taxReportEditor.columns.kubun') }}</span>
                        <span>{{ movementSortIndicator('kubun') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left">
                      <button class="inline-flex items-center gap-1 hover:text-gray-700" type="button" @click="sortMovementTable('category')">
                        <span>{{ t('taxReport.breakdown.columns.category') }}</span>
                        <span>{{ movementSortIndicator('category') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left">
                      <button class="inline-flex items-center gap-1 hover:text-gray-700" type="button" @click="sortMovementTable('abv')">
                        <span>{{ t('taxReport.breakdown.columns.abv') }}</span>
                        <span>{{ movementSortIndicator('abv') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-right">
                      <button class="inline-flex items-center gap-1 hover:text-gray-700" type="button" @click="sortMovementTable('volume')">
                        <span>{{ t('taxReport.breakdown.columns.volume') }}</span>
                        <span>{{ movementSortIndicator('volume') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left">
                      <button class="inline-flex items-center gap-1 hover:text-gray-700" type="button" @click="sortMovementTable('taxEvent')">
                        <span>{{ t('taxReportEditor.columns.taxEvent') }}</span>
                        <span>{{ movementSortIndicator('taxEvent') }}</span>
                      </button>
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="row in movementTableRows" :key="row.item.key" :class="movementRowClass(row.item)">
                    <td class="px-3 py-2 text-gray-700">{{ lia110KubunCodeForItem(row.item) }}</td>
                    <td class="px-3 py-2 text-gray-700">{{ row.item.categoryName }}</td>
                    <td class="px-3 py-2">
                      <input
                        v-if="row.editable && row.sourceIndex != null"
                        :value="formatInputNumber(row.item.abv)"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2"
                        @input="updateReportBreakdownNumber(row.sourceIndex, 'abv', $event)"
                      />
                      <span v-else class="text-gray-600">{{ formatNullableNumber(row.item.abv, 1) }}</span>
                    </td>
                    <td class="px-3 py-2 text-right">
                      <input
                        v-if="row.editable && row.sourceIndex != null"
                        :value="formatInputNumber(row.item.volume_l)"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2 text-right"
                        @input="updateReportBreakdownNumber(row.sourceIndex, 'volume_l', $event)"
                      />
                      <span v-else class="text-gray-700">{{ formatNullableNumber(row.item.volume_l, 2) }}</span>
                    </td>
                    <td class="px-3 py-2 text-gray-700">
                      <div>{{ movementRowLabel(row.item) }}</div>
                      <div v-if="movementRowRoleLabel(row.item)" class="text-[11px] text-gray-400">
                        {{ movementRowRoleLabel(row.item) }}
                      </div>
                    </td>
                  </tr>
                  <tr v-if="movementTableRows.length === 0">
                    <td colspan="5" class="px-3 py-4 text-center text-xs text-gray-400">{{ t('taxReport.emptyBreakdown') }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div v-if="returnTableRows.length > 0" class="space-y-2">
              <div>
                <h3 class="text-sm font-semibold text-gray-700">{{ t('taxReportEditor.sections.returns.title') }}</h3>
                <p class="text-xs text-gray-500">{{ t('taxReportEditor.sections.returns.subtitle') }}</p>
              </div>
              <div class="overflow-x-auto rounded border bg-gray-50">
                <table class="min-w-full text-sm">
                  <thead class="bg-white text-xs uppercase text-gray-500">
                    <tr>
                      <th class="px-3 py-2 text-left">{{ t('taxReportEditor.columns.taxEvent') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.category') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.abv') }}</th>
                      <th class="px-3 py-2 text-right">{{ t('taxReport.breakdown.columns.volume') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="row in returnTableRows" :key="row.item.key">
                      <td class="px-3 py-2 text-gray-700">{{ breakdownMovementLabel(row.item) }}</td>
                      <td class="px-3 py-2 text-gray-700">{{ row.item.categoryName }}</td>
                      <td class="px-3 py-2">
                        <input
                          v-if="row.sourceIndex != null"
                          :value="formatInputNumber(row.item.abv)"
                          type="number"
                          min="0"
                          step="0.01"
                          class="h-[36px] w-full rounded border bg-white px-2"
                          @input="updateReportBreakdownNumber(row.sourceIndex, 'abv', $event)"
                        />
                      </td>
                      <td class="px-3 py-2 text-right">
                        <input
                          v-if="row.sourceIndex != null"
                          :value="formatInputNumber(row.item.volume_l)"
                          type="number"
                          min="0"
                          step="0.01"
                          class="h-[36px] w-full rounded border bg-white px-2 text-right"
                          @input="updateReportBreakdownNumber(row.sourceIndex, 'volume_l', $event)"
                        />
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
            <p v-if="errors.breakdown" class="text-xs text-red-600">{{ errors.breakdown }}</p>
          </section>

          <section class="space-y-3">
            <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
              <div>
                <h2 class="text-base font-semibold">{{ t('taxReport.sections.dispose.title') }}</h2>
                <p class="text-xs text-gray-500">{{ t('taxReport.sections.dispose.subtitle') }}</p>
              </div>
              <div class="flex flex-wrap items-center gap-2">
                <button
                  class="rounded border px-3 py-2 hover:bg-gray-50 disabled:opacity-50"
                  :disabled="generating"
                  @click="createXmlForDispose"
                >
                  {{ t('taxReport.actions.createXml') }}
                </button>
                <a v-if="disposeXmlUrl" :href="disposeXmlUrl" :download="disposeXmlName" class="text-xs text-blue-600">
                  {{ t('taxReport.actions.downloadXml') }}
                </a>
              </div>
            </div>
            <div class="overflow-x-auto rounded border bg-gray-50">
              <table class="min-w-full text-sm">
                <thead class="bg-white text-xs uppercase text-gray-500">
                  <tr>
                    <th class="px-3 py-2 text-left">{{ t('taxReportEditor.columns.taxEvent') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.category') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.abv') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('taxReport.breakdown.columns.volume') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="(item, index) in disposeBreakdown" :key="item.key">
                    <td class="px-3 py-2 text-gray-700">{{ breakdownMovementLabel(item) }}</td>
                    <td class="px-3 py-2 text-gray-700">{{ item.categoryName }}</td>
                    <td class="px-3 py-2">
                      <input
                        v-model.number="item.abv"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2"
                        @input="handleDisposeChange(index)"
                      />
                    </td>
                    <td class="px-3 py-2 text-right">
                      <input
                        v-model.number="item.volume_l"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2 text-right"
                        @input="handleDisposeChange(index)"
                      />
                    </td>
                  </tr>
                  <tr v-if="disposeBreakdown.length === 0">
                    <td colspan="4" class="px-3 py-4 text-center text-xs text-gray-400">{{ t('taxReport.emptyBreakdown') }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <section class="space-y-3">
            <div>
              <h2 class="text-base font-semibold">{{ t('taxReportEditor.sections.files.title') }}</h2>
              <p class="text-xs text-gray-500">{{ t('taxReportEditor.sections.files.subtitle') }}</p>
            </div>
            <div class="space-y-2 rounded border bg-gray-50 p-3">
              <div
                v-for="file in displayReportFiles"
                :key="`${file.fileType}-${file.fileName}`"
                class="flex flex-col gap-2 rounded border bg-white px-3 py-2 text-sm md:flex-row md:items-center md:justify-between"
              >
                <div class="min-w-0">
                  <div class="truncate font-medium text-gray-800">{{ file.fileName }}</div>
                  <div class="text-xs text-gray-500">
                    {{ file.saved ? t('taxReportEditor.sections.files.saved') : t('taxReportEditor.sections.files.pending') }}
                  </div>
                </div>
                <button
                  v-if="file.saved"
                  class="rounded border px-3 py-1.5 text-xs hover:bg-gray-50"
                  type="button"
                  @click="downloadSavedReportFile(file)"
                >
                  {{ t('taxReportEditor.sections.files.download') }}
                </button>
              </div>
              <p v-if="displayReportFiles.length === 0" class="text-xs text-gray-400">
                {{ t('taxReportEditor.sections.files.empty') }}
              </p>
            </div>
            <label class="block text-sm text-gray-600">{{ t('taxReport.form.attachments') }}</label>
            <input type="file" multiple class="h-[40px] w-full rounded border px-3 py-2" @change="handleAttachmentUpload" />
            <div v-if="attachmentList.length" class="flex flex-wrap gap-2 text-xs">
              <span
                v-for="file in attachmentList"
                :key="file"
                class="inline-flex items-center gap-2 rounded-full border border-gray-200 px-2.5 py-1 text-gray-700"
              >
                {{ file }}
                <button class="text-gray-400 hover:text-gray-700" type="button" @click="removeAttachment(file)">×</button>
              </span>
            </div>
            <p v-else class="text-xs text-gray-400">{{ t('taxReport.form.attachmentsHint') }}</p>
          </section>

          <footer class="flex items-center justify-between border-t pt-4">
            <div class="text-xs text-gray-500">
              <span v-if="generating">{{ t('taxReport.generating') }}</span>
            </div>
            <div class="flex items-center gap-2">
              <button class="rounded border px-3 py-2 hover:bg-gray-50" @click="goBack">{{ t('common.cancel') }}</button>
              <button
                class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700 disabled:opacity-50"
                :disabled="saving || generating || loadingInitial"
                @click="saveReport"
              >
                {{ saving ? t('common.saving') : t('common.save') }}
              </button>
            </div>
          </footer>
        </section>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'
import {
  buildAlcoholTypeLookupKeys,
  loadAlcoholTypeReferenceData,
} from '@/lib/alcoholTypeRegistry'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import {
  createEmptyTaxReportProfile,
  fetchTaxReportProfileForTenant,
  type TaxReportProfile,
} from '@/lib/taxReportProfile'
import {
  calculateTaxAmount,
  calculateTaxTotalAmount,
  buildLia110ReportRows,
  buildTaxableRemovalExcelFilename,
  buildDisposeXmlFilename,
  buildXmlFilename,
  buildXmlPayload,
  downloadStoredTaxReportFile,
  disposeItemsFromBreakdown,
  fetchPriorFiscalYearStandardTaxAmount,
  type GeneratedTaxReportFile,
  inferStoredFileType,
  mergeStoredFiles,
  normalizeReport,
  parseFileList,
  removeStoredTaxReportFiles,
  resolveTaxEvent,
  isReturnTaxEvent,
  lia110KubunCodeForItem,
  sortTaxVolumeItems,
  summaryItemsFromBreakdown,
  type TaxReportStoredFile,
  uploadGeneratedTaxReportFiles,
  type JsonMap,
  type TaxVolumeItem,
} from '@/lib/taxReport'
import {
  businessYearForDate,
  createTaxableRemovalMonthWorkbookBlob,
  loadTaxableRemovalDetailRows,
  type TaxableRemovalExportLabels,
} from '@/lib/taxableRemovalReport'

interface CategoryRow {
  id: string
  code: string
  name: string | null
  lookupKeys: string[]
}

interface TaxRateRecord {
  taxrate: number
  effectDate: Date | null
  expireDate: Date | null
}

interface RuleLabel {
  ja?: string | null
  en?: string | null
}

interface MovementRules {
  tax_event_labels?: Record<string, RuleLabel>
}

type MovementSortKey = 'kubun' | 'taxEvent' | 'category' | 'abv' | 'volume'
type MovementSortDirection = 'asc' | 'desc'

interface MovementTableRow {
  item: TaxVolumeItem
  sourceIndex: number | null
  editable: boolean
}

interface MovementHeader {
  id: string
  movement_at: string | null
  doc_type: string
  meta?: JsonMap | null
}

interface MovementLine {
  movement_id: string
  package_id: string | null
  batch_id: string | null
  qty: number | null
  uom_id: string | null
  meta?: JsonMap | null
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

interface BatchLookupRow {
  id: string
}

interface AttrDefRow {
  attr_id: number | string
  code: string | null
}

interface EntityAttrRow {
  entity_id: string | number | null
  attr_id: number | string | null
  value_text?: string | null
  value_num: unknown
  value_ref_type_id?: string | number | null
  value_json?: Record<string, unknown> | null
}

const TABLE = 'tax_reports'
const STATUS_OPTIONS = ['draft', 'submitted', 'approved'] as const
const TAX_TYPE_OPTIONS = ['monthly'] as const
const SUMMARY_DOC_TYPES = ['sale', 'tax_transfer', 'return', 'transfer'] as const
const DISPOSE_DOC_TYPES = ['waste'] as const
const REPORT_DOC_TYPES = [...SUMMARY_DOC_TYPES, ...DISPOSE_DOC_TYPES] as const

const { t, tm, locale } = useI18n()
const route = useRoute()
const router = useRouter()

const loadingInitial = ref(false)
const saving = ref(false)
const generating = ref(false)
const tenantId = ref<string | null>(null)
const tenantName = ref('')
const tenantProfile = ref<TaxReportProfile>(createEmptyTaxReportProfile())

const categories = ref<CategoryRow[]>([])
const uoms = ref<Array<{ id: string; code: string | null }>>([])
const taxRateIndex = ref<Record<string, TaxRateRecord[]>>({})
const movementRules = ref<MovementRules | null>(null)

const form = reactive({
  id: '',
  tax_type: 'monthly',
  tax_year: new Date().getFullYear(),
  tax_month: new Date().getMonth() + 1,
  status: 'draft',
  attachment_files: '',
})

const errors = reactive<Record<string, string>>({})
const reportBreakdown = ref<TaxVolumeItem[]>([])
const disposeBreakdown = ref<TaxVolumeItem[]>([])
const totalTaxAmount = ref(0)
const summaryXmlUrl = ref('')
const summaryXmlName = ref('')
const disposeXmlUrl = ref('')
const disposeXmlName = ref('')
const storedReportFiles = ref<TaxReportStoredFile[]>([])
const movementSort = reactive<{
  key: MovementSortKey
  direction: MovementSortDirection
}>({
  key: 'category',
  direction: 'asc',
})

const editing = computed(() => typeof route.params.id === 'string' && route.params.id.length > 0)
const pageTitle = computed(() => (editing.value ? t('taxReportEditor.editTitle') : t('taxReportEditor.newTitle')))
const statusOptions = STATUS_OPTIONS
const taxTypeOptions = TAX_TYPE_OPTIONS
const monthOptions = computed(() => [4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3])
const currencyFormatter = computed(
  () => new Intl.NumberFormat(locale.value, { style: 'currency', currency: 'JPY', maximumFractionDigits: 0 }),
)
const attachmentList = computed(() => parseFileList(form.attachment_files))
const expectedGeneratedFiles = computed(() => {
  const files: Array<{ fileName: string; fileType: GeneratedTaxReportFile['fileType'] }> = []
  if (reportBreakdown.value.length > 0) {
    files.push({
      fileName: buildXmlFilename(form.tax_type, form.tax_year, form.tax_month),
      fileType: 'tax_report_xml',
    })
  }
  if (disposeBreakdown.value.length > 0) {
    files.push({
      fileName: buildDisposeXmlFilename(form.tax_type, form.tax_year, form.tax_month),
      fileType: 'tax_report_dispose_xml',
    })
  }
  if (form.tax_type === 'monthly' && form.tax_month) {
    files.push({
      fileName: buildTaxableRemovalExcelFilename(form.tax_year, form.tax_month),
      fileType: 'taxable_removal_excel',
    })
  }
  return files
})
const displayReportFiles = computed(() => {
  type DisplayReportFile = {
    fileName: string
    fileType: string
    saved: boolean
    stored: TaxReportStoredFile | null
  }
  const storedByType = new Map(storedReportFiles.value.map((file) => [String(file.fileType), file]))
  const rows: DisplayReportFile[] = expectedGeneratedFiles.value.map((file) => ({
    fileName: file.fileName,
    fileType: file.fileType,
    saved: storedByType.has(file.fileType),
    stored: storedByType.get(file.fileType) ?? null,
  }))

  storedReportFiles.value.forEach((file) => {
    const alreadyIncluded = rows.some((row) => row.fileType === file.fileType)
    if (!alreadyIncluded) {
      rows.push({
        fileName: file.fileName,
        fileType: file.fileType,
        saved: true,
        stored: file,
      })
    }
  })

  return rows.sort((a, b) => a.fileName.localeCompare(b.fileName))
})
const movementTableRows = computed<MovementTableRow[]>(() => {
  const sourceIndexByKey = new Map(reportBreakdown.value.map((item, index) => [item.key, index]))
  const rows = buildLia110ReportRows(reportBreakdown.value).map((item) => ({
    item,
    sourceIndex: (item.row_role ?? 'detail') === 'detail' ? sourceIndexByKey.get(item.key) ?? null : null,
    editable: (item.row_role ?? 'detail') === 'detail',
  }))

  return sortMovementTableRows(rows)
})
const returnTableRows = computed<MovementTableRow[]>(() =>
  reportBreakdown.value
    .map((item, index) => ({ item, sourceIndex: index, editable: true }))
    .filter((row) => isReturnTaxEvent(row.item.move_type, row.item.tax_event))
    .sort((a, b) => {
      const categoryResult = compareStrings(a.item.categoryName, b.item.categoryName, 'asc')
      if (categoryResult !== 0) return categoryResult
      return compareNullableNumbers(a.item.abv, b.item.abv, 'desc')
    }),
)
const taxableRemovalExportLabels = computed<TaxableRemovalExportLabels>(() => ({
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

function pickLabel(label: RuleLabel | null | undefined, fallback: string) {
  if (!label) return fallback
  const isJa = String(locale.value || '')
    .toLowerCase()
    .startsWith('ja')
  if (isJa) return label.ja || label.en || fallback
  return label.en || label.ja || fallback
}

function mapRuleLabel(map: Record<string, RuleLabel> | undefined, code: string | null | undefined) {
  if (!code) return '—'
  return pickLabel(map?.[code], code)
}

function taxEventLabel(value: string | null | undefined) {
  return mapRuleLabel(movementRules.value?.tax_event_labels, value)
}

function breakdownMovementLabel(item: TaxVolumeItem) {
  const actualTaxEvent = resolveTaxEvent(item.move_type, item.tax_event)
  return taxEventLabel(actualTaxEvent)
}

function movementRowLabel(item: TaxVolumeItem) {
  const rowRole = item.row_role ?? 'detail'
  if (rowRole === 'detail') return breakdownMovementLabel(item)
  if (rowRole === 'kubun_summary') return t('taxReportEditor.rowTypes.kubunSummary')
  if (rowRole === 'category_summary') return t('taxReportEditor.rowTypes.categorySummary')
  if (rowRole === 'grand_total') return t('taxReportEditor.rowTypes.grandTotal')
  return breakdownMovementLabel(item)
}

function movementRowRoleLabel(item: TaxVolumeItem) {
  const rowRole = item.row_role ?? 'detail'
  if (rowRole === 'detail') return ''
  return t('taxReportEditor.rowTypes.generated')
}

function movementRowClass(item: TaxVolumeItem) {
  const rowRole = item.row_role ?? 'detail'
  if (rowRole === 'grand_total') return 'bg-blue-50 font-semibold'
  if (rowRole === 'category_summary') return 'bg-gray-100 font-semibold'
  if (rowRole === 'kubun_summary') return 'bg-gray-50 font-medium'
  return 'bg-white'
}

function movementSortIndicator(key: MovementSortKey) {
  if (movementSort.key !== key) return ''
  return movementSort.direction === 'asc' ? '↑' : '↓'
}

function formatInputNumber(value: number | null | undefined) {
  return Number.isFinite(value) ? String(value) : ''
}

function formatNullableNumber(value: number | null | undefined, maximumFractionDigits = 2) {
  if (!Number.isFinite(value)) return '—'
  return new Intl.NumberFormat(locale.value, {
    maximumFractionDigits,
  }).format(Number(value))
}

function compareNullableNumbers(
  left: number | null | undefined,
  right: number | null | undefined,
  direction: MovementSortDirection,
) {
  const a = Number.isFinite(left) ? Number(left) : null
  const b = Number.isFinite(right) ? Number(right) : null
  if (a == null && b == null) return 0
  if (a == null) return 1
  if (b == null) return -1
  return direction === 'asc' ? a - b : b - a
}

function compareStrings(left: string, right: string, direction: MovementSortDirection) {
  const result = left.localeCompare(right, locale.value)
  return direction === 'asc' ? result : -result
}

function sortMovementTableRows(rows: MovementTableRow[]) {
  if (movementSort.key === 'category' && movementSort.direction === 'asc') return rows

  return [...rows].sort((a, b) => compareMovementTableRows(a.item, b.item))
}

function compareMovementTableRows(a: TaxVolumeItem, b: TaxVolumeItem) {
  let result = 0
  if (movementSort.key === 'kubun') {
    result = compareNullableNumbers(lia110KubunCodeForItem(a), lia110KubunCodeForItem(b), movementSort.direction)
  } else if (movementSort.key === 'taxEvent') {
    result = compareStrings(movementRowLabel(a), movementRowLabel(b), movementSort.direction)
  } else if (movementSort.key === 'category') {
    result = compareStrings(a.categoryName, b.categoryName, movementSort.direction)
  } else if (movementSort.key === 'abv') {
    result = compareNullableNumbers(a.abv, b.abv, movementSort.direction)
  } else if (movementSort.key === 'volume') {
    result = compareNullableNumbers(a.volume_l, b.volume_l, movementSort.direction)
  }
  if (result !== 0) return result

  const categoryResult = compareStrings(a.categoryName, b.categoryName, 'asc')
  if (categoryResult !== 0) return categoryResult

  const kubunResult = lia110KubunCodeForItem(a) - lia110KubunCodeForItem(b)
  if (kubunResult !== 0) return kubunResult

  const roleResult = movementRowRoleRank(a) - movementRowRoleRank(b)
  if (roleResult !== 0) return roleResult

  return compareNullableNumbers(a.abv, b.abv, 'desc')
}

function movementRowRoleRank(item: TaxVolumeItem) {
  switch (item.row_role ?? 'detail') {
    case 'detail':
      return 0
    case 'kubun_summary':
      return 1
    case 'category_summary':
      return 2
    case 'grand_total':
      return 3
    default:
      return 9
  }
}

function sortMovementBreakdown(
  items: TaxVolumeItem[],
  key = movementSort.key,
  direction = movementSort.direction,
) {
  items.sort((a, b) => {
    if (key === 'kubun') {
      const result = compareNullableNumbers(lia110KubunCodeForItem(a), lia110KubunCodeForItem(b), direction)
      if (result !== 0) return result
    } else if (key === 'taxEvent') {
      const result = compareStrings(breakdownMovementLabel(a), breakdownMovementLabel(b), direction)
      if (result !== 0) return result
    } else if (key === 'category') {
      const result = compareStrings(a.categoryName, b.categoryName, direction)
      if (result !== 0) return result
    } else if (key === 'abv') {
      const result = compareNullableNumbers(a.abv, b.abv, direction)
      if (result !== 0) return result
    } else if (key === 'volume') {
      const result = compareNullableNumbers(a.volume_l, b.volume_l, direction)
      if (result !== 0) return result
    }

    const categoryResult = compareStrings(a.categoryName, b.categoryName, 'asc')
    if (categoryResult !== 0) return categoryResult
    return compareNullableNumbers(a.abv, b.abv, 'asc')
  })
}

function sortMovementTable(key: MovementSortKey) {
  if (movementSort.key === key) {
    movementSort.direction = movementSort.direction === 'asc' ? 'desc' : 'asc'
  } else {
    movementSort.key = key
    movementSort.direction = 'asc'
  }
  sortMovementBreakdown(reportBreakdown.value)
}

function formatCurrency(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  try {
    return currencyFormatter.value.format(value)
  } catch {
    return `¥${Math.round(value).toLocaleString()}`
  }
}

function isSummaryDocType(value: string): value is (typeof SUMMARY_DOC_TYPES)[number] {
  return (SUMMARY_DOC_TYPES as readonly string[]).includes(value)
}

function recalcTotalTax() {
  totalTaxAmount.value = calculateTaxTotalAmount(reportBreakdown.value)
}

function handleBreakdownChange(index: number) {
  const item = reportBreakdown.value[index]
  if (!item) return
  if (!Number.isFinite(item.volume_l)) item.volume_l = 0
  if (!Number.isFinite(item.abv)) item.abv = null
  recalcTotalTax()
}

function updateReportBreakdownNumber(
  index: number,
  field: 'abv' | 'volume_l',
  event: Event,
) {
  const item = reportBreakdown.value[index]
  const target = event.target as HTMLInputElement | null
  if (!item || !target) return
  const value = target.value === '' ? null : Number(target.value)
  if (field === 'abv') {
    item.abv = Number.isFinite(value) ? Number(value) : null
  } else {
    item.volume_l = Number.isFinite(value) ? Number(value) : 0
  }
  handleBreakdownChange(index)
}

function handleDisposeChange(index: number) {
  const item = disposeBreakdown.value[index]
  if (!item) return
  if (!Number.isFinite(item.volume_l)) item.volume_l = 0
  if (!Number.isFinite(item.abv)) item.abv = null
  recalcTotalTax()
}

function setXmlLink(kind: 'summary' | 'dispose', name: string, xml: string) {
  const url = URL.createObjectURL(new Blob([xml], { type: 'application/xml' }))
  if (kind === 'summary') {
    if (summaryXmlUrl.value) URL.revokeObjectURL(summaryXmlUrl.value)
    summaryXmlUrl.value = url
    summaryXmlName.value = name
  } else {
    if (disposeXmlUrl.value) URL.revokeObjectURL(disposeXmlUrl.value)
    disposeXmlUrl.value = url
    disposeXmlName.value = name
  }
}

function resolveMetaString(meta: JsonMap | null | undefined, key: string) {
  const value = meta?.[key]
  return typeof value === 'string' && value.trim() ? value.trim() : null
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

function createReportId() {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID()
  }

  if (typeof crypto !== 'undefined' && typeof crypto.getRandomValues === 'function') {
    const bytes = crypto.getRandomValues(new Uint8Array(16))
    bytes[6] = (bytes[6] & 0x0f) | 0x40
    bytes[8] = (bytes[8] & 0x3f) | 0x80
    const hex = Array.from(bytes, (byte) => byte.toString(16).padStart(2, '0')).join('')
    return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20)}`
  }

  const timestamp = Date.now().toString(16).padStart(12, '0').slice(-12)
  const randomHex = Array.from({ length: 20 }, () => Math.floor(Math.random() * 16).toString(16)).join('')
  const hex = `${randomHex}${timestamp}`.slice(0, 32)
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-4${hex.slice(13, 16)}-8${hex.slice(17, 20)}-${hex.slice(20)}`
}

async function downloadSavedReportFile(entry: {
  stored: TaxReportStoredFile | null
  fileName: string
}) {
  if (!entry.stored) return
  if (!entry.stored.storageBucket || !entry.stored.storagePath) {
    try {
      const fileType = inferStoredFileType(entry.fileName)
      if (fileType === 'tax_report_xml') {
        const summaryFile = await buildSummaryXmlFile()
        if (summaryFile) {
          const xml = await summaryFile.blob.text()
          downloadTextFile(summaryFile.fileName, xml)
        }
        return
      }
      if (fileType === 'tax_report_dispose_xml') {
        const disposeFile = await buildDisposeXmlFile()
        if (disposeFile) {
          const xml = await disposeFile.blob.text()
          downloadTextFile(disposeFile.fileName, xml)
        }
        return
      }
      toast.info(t('taxReport.fileUnavailable'))
    } catch (err) {
      console.error(err)
      toast.error(err instanceof Error ? err.message : String(err))
    }
    return
  }
  try {
    const blob = await downloadStoredTaxReportFile({
      supabase,
      file: entry.stored,
    })
    downloadBlob(entry.fileName, blob)
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
}

function toNullableNumber(value: unknown) {
  if (value == null || value === '') return null
  const numeric = Number(value)
  return Number.isFinite(numeric) ? numeric : null
}

function normalizeTaxCategoryCode(value: unknown) {
  if (value == null) return ''
  if (typeof value === 'number' && Number.isFinite(value)) return String(Math.trunc(value))
  const text = String(value).trim()
  if (!text) return ''
  const num = Number(text)
  return Number.isFinite(num) ? String(Math.trunc(num)) : text
}

function convertToLiters(size: number | null, uomCode: string | null | undefined) {
  if (size == null || Number.isNaN(size)) return null
  const normalized = uomCode ? uomCode.toLowerCase() : null
  switch (normalized) {
    case 'l':
    case null:
    case undefined:
      return size
    case 'ml':
      return size / 1000
    case 'kl':
      return size * 1000
    case 'gal_us':
      return size * 3.78541
    default:
      return size
  }
}

function resolvePackageSizeLiters(row: PackageCategoryInfo | undefined) {
  return row?.unit_size_l ?? null
}

const categoryLookup = computed(() => {
  const map = new Map<string, CategoryRow>()
  categories.value.forEach((row) => {
    row.lookupKeys.forEach((key) => {
      const normalized = String(key ?? '').trim()
      if (normalized) map.set(normalized, row)
    })
    if (row.id) map.set(row.id, row)
    if (row.code) map.set(row.code, row)
  })
  return map
})

const uomLookup = computed(() => {
  const map = new Map<string, string>()
  uoms.value.forEach((row) => map.set(row.id, row.code ?? ''))
  return map
})

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

async function loadCategories() {
  const { optionRows, fallbackRows } = await loadAlcoholTypeReferenceData(supabase)
  categories.value = optionRows.map((row: { def_id?: unknown; def_key?: unknown; spec?: Record<string, unknown> | null }) => ({
    id: String(row.def_id ?? ''),
    code: String(row.spec?.tax_category_code ?? row.spec?.code ?? row.def_key ?? ''),
    name: typeof row.spec?.name === 'string' ? row.spec.name : (typeof row.def_key === 'string' ? row.def_key : null),
    lookupKeys: buildAlcoholTypeLookupKeys(row, fallbackRows),
  }))
}

async function loadUoms() {
  const { data, error } = await supabase.from('mst_uom').select('id, code').order('code', { ascending: true })
  if (error) throw error
  uoms.value = data ?? []
}

function buildTaxRateIndex(rows: Array<{ spec?: Record<string, unknown> | null }>) {
  const index: Record<string, TaxRateRecord[]> = {}
  rows.forEach((row) => {
    const spec = row.spec && typeof row.spec === 'object' ? row.spec : {}
    const categoryCode = normalizeTaxCategoryCode(spec.tax_category_code)
    if (!categoryCode) return

    const taxRateRaw = Number(spec.tax_rate ?? 0)
    if (!Number.isFinite(taxRateRaw)) return

    const entry: TaxRateRecord = {
      taxrate: taxRateRaw,
      effectDate: spec.start_date ? new Date(String(spec.start_date)) : null,
      expireDate: spec.expiration_date ? new Date(String(spec.expiration_date)) : null,
    }
    if (!index[categoryCode]) index[categoryCode] = []
    index[categoryCode].push(entry)
  })

  Object.values(index).forEach((list) => {
    list.sort((a, b) => {
      if (!a.effectDate || !b.effectDate) return 0
      return a.effectDate.getTime() - b.effectDate.getTime()
    })
  })
  taxRateIndex.value = index
}

async function loadTaxRates() {
  const { data, error } = await supabase
    .from('registry_def')
    .select('spec')
    .eq('kind', 'alcohol_tax')
    .eq('is_active', true)
  if (error) throw error
  buildTaxRateIndex((data ?? []) as Array<{ spec?: Record<string, unknown> | null }>)
}

async function loadMovementRules() {
  const { data, error } = await supabase.rpc('movement_get_rules', {
    p_movement_intent: null,
  })
  if (error) throw error
  movementRules.value = ((Array.isArray(data) ? data[0] : data) ?? null) as MovementRules | null
}

function applicableTaxRate(categoryCode: string | null | undefined, dateStr: string | null | undefined) {
  const code = normalizeTaxCategoryCode(categoryCode)
  if (!code) return 0
  const records = taxRateIndex.value[code]
  if (!records || records.length === 0) return 0
  if (!dateStr) return records[records.length - 1]?.taxrate ?? 0
  const date = new Date(dateStr)
  let candidate: TaxRateRecord | null = null
  for (const record of records) {
    const effectOk = !record.effectDate || date >= record.effectDate
    const expireOk = !record.expireDate || date <= record.expireDate
    if (effectOk && expireOk) {
      candidate = record
    }
    if (record.effectDate && date < record.effectDate) break
  }
  return candidate?.taxrate ?? records[records.length - 1]?.taxrate ?? 0
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
    map.set(row.id, {
      id: row.id,
      unit_size_l: convertToLiters(
        toNullableNumber(row.unit_volume),
        typeof row.volume_uom === 'string' ? row.volume_uom : null,
      ),
    })
  })
  return map
}

async function loadBatchEntityAttrsByBatchIds(batchIds: string[]) {
  const map = new Map<string, { categoryId: string | null; abv: number | null }>()
  if (batchIds.length === 0) return map

  const uniqueIds = Array.from(new Set(batchIds))
  const { data: attrDefs, error: attrDefError } = await supabase
    .from('attr_def')
    .select('attr_id, code')
    .eq('domain', 'batch')
    .in('code', ['beer_category', 'actual_abv', 'target_abv'])
    .eq('is_active', true)
  if (attrDefError) throw attrDefError

  const attrIdToCode = new Map<string, string>()
  const attrIds = ((attrDefs ?? []) as AttrDefRow[])
    .map((row) => {
      const id = Number(row.attr_id)
      if (!Number.isFinite(id)) return null
      const code = typeof row.code === 'string' ? row.code : null
      if (code) attrIdToCode.set(String(row.attr_id), code)
      return id
    })
    .filter((id): id is number => id != null)
  if (!attrIds.length) return map

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
    if (!map.has(batchId)) {
      map.set(batchId, { categoryId: null, abv: null })
    }
    const entry = map.get(batchId)
    if (!entry) return

    const code = attrIdToCode.get(String(row.attr_id))
    if (!code) return

    if (code === 'beer_category') {
      const jsonDefId = row.value_json?.def_id
      if (typeof jsonDefId === 'string' && jsonDefId.trim()) entry.categoryId = jsonDefId.trim()
      else if (typeof row.value_text === 'string' && row.value_text.trim()) entry.categoryId = row.value_text.trim()
      else if (row.value_ref_type_id != null) entry.categoryId = String(row.value_ref_type_id)
    }

    if (code === 'actual_abv') {
      const abv = toNullableNumber(row.value_num)
      if (abv != null) entry.abv = abv
    }

    if (code === 'target_abv' && entry.abv == null) {
      const abv = toNullableNumber(row.value_num)
      if (abv != null) entry.abv = abv
    }
  })

  return map
}

async function generateReportForPeriod(taxType: string, year: number, month: number) {
  try {
    generating.value = true
    reportBreakdown.value = []
    disposeBreakdown.value = []
    totalTaxAmount.value = 0

    const tenant = await ensureTenant()
    const start = taxType === 'yearly' ? new Date(year, 0, 1) : new Date(year, month - 1, 1)
    const end = taxType === 'yearly' ? new Date(year + 1, 0, 1) : new Date(year, month, 1)
    const startDate = `${start.getFullYear()}-${String(start.getMonth() + 1).padStart(2, '0')}-01`
    const endDate = `${end.getFullYear()}-${String(end.getMonth() + 1).padStart(2, '0')}-01`

    const { data: movementHeaders, error: headerError } = await supabase
      .from('inv_movements')
      .select('id, movement_at, doc_type, meta')
      .eq('tenant_id', tenant)
      .in('doc_type', REPORT_DOC_TYPES as unknown as string[])
      .gte('movement_at', startDate)
      .lt('movement_at', endDate)

    if (headerError) throw headerError
    const headers = (movementHeaders ?? []) as MovementHeader[]
    if (headers.length === 0) {
      reportBreakdown.value = []
      disposeBreakdown.value = []
      totalTaxAmount.value = 0
      return
    }

    const headerMap = new Map(
      headers.map((row) => [
        row.id,
        {
          movementAt: row.movement_at,
          docType: row.doc_type,
          taxEvent: resolveTaxEvent(
            row.doc_type,
            resolveMetaString(row.meta, 'tax_event'),
            resolveMetaString(row.meta, 'tax_decision_code'),
          ),
        },
      ]),
    )
    const movementIds = headers.map((row) => row.id)

    const { data: movementLines, error: lineError } = await supabase
      .from('inv_movement_lines')
      .select('movement_id, package_id, batch_id, qty, uom_id, meta')
      .in('movement_id', movementIds)

    if (lineError) throw lineError

    const lines = ((movementLines ?? []) as MovementLine[]).filter((row) => row.package_id || row.batch_id)
    if (lines.length === 0) {
      reportBreakdown.value = []
      disposeBreakdown.value = []
      totalTaxAmount.value = 0
      return
    }

    const packageIds = Array.from(new Set(lines.map((line) => line.package_id).filter(Boolean))) as string[]
    const batchIds = Array.from(new Set(lines.map((line) => line.batch_id).filter(Boolean))) as string[]

    const packageMap = await loadPackageCategories(packageIds)
    const batchAttrMap = await loadBatchEntityAttrsByBatchIds(batchIds)

    const batchMap = new Map<string, { categoryId: string | null; categoryName: string; abv: number | null }>()
    if (batchIds.length > 0) {
      const { data: batches, error: batchError } = await supabase
        .from('mes_batches')
        .select('id')
        .eq('tenant_id', tenant)
        .in('id', batchIds)
      if (batchError) throw batchError
      ;((batches ?? []) as BatchLookupRow[]).forEach((row) => {
        const attr = batchAttrMap.get(String(row.id))
        const categoryId = attr?.categoryId ?? null
        const category = categoryId ? categoryLookup.value.get(categoryId) : null
        batchMap.set(String(row.id), {
          categoryId,
          categoryName: category?.name || category?.code || categoryId || '—',
          abv: attr?.abv ?? null,
        })
      })
    }

    const breakdownMap = new Map<string, TaxVolumeItem>()
    const taxTotalMap = new Map<string, number>()
    const taxRateWeightedMap = new Map<string, number>()
    let totalTax = 0

    lines.forEach((line) => {
      const header = headerMap.get(line.movement_id)
      const movementAt = header?.movementAt ?? null
      const moveType = header?.docType ?? 'unknown'
      const taxEvent = header?.taxEvent ?? resolveTaxEvent(moveType)
      const packageRow = line.package_id ? packageMap.get(line.package_id) : undefined
      const batchId = line.batch_id ?? null
      const batchInfo = batchId ? batchMap.get(batchId) : undefined

      const categoryId = batchInfo?.categoryId ?? null
      if (!categoryId) return
      const category = categoryLookup.value.get(categoryId)
      const categoryName = category?.name || category?.code || categoryId
      const categoryCode = category?.code ?? ''
      const abv = batchInfo?.abv ?? null

      if (!(REPORT_DOC_TYPES as readonly string[]).includes(moveType)) return

      const uomCode = line.uom_id ? uomLookup.value.get(line.uom_id) : null
      let volume = line.qty != null ? convertToLiters(Number(line.qty), uomCode) : null

      if (!volume || volume <= 0) {
        const unitSize = resolvePackageSizeLiters(packageRow)
        const pkgQty = Number(line.meta?.package_qty ?? 0)
        if (unitSize && pkgQty > 0) {
          volume = pkgQty * unitSize
        }
      }

      if (!volume || Number.isNaN(volume)) return

      const key = isSummaryDocType(moveType)
        ? `${taxEvent ?? 'unknown'}-${categoryId}-${abv ?? 'na'}`
        : `${moveType}-${taxEvent ?? 'unknown'}-${categoryId}-${abv ?? 'na'}`
      const existing = breakdownMap.get(key)
      if (existing) {
        existing.volume_l += volume
      } else {
        breakdownMap.set(key, {
          key,
          move_type: moveType,
          tax_event: taxEvent,
          categoryId,
          categoryCode,
          categoryName,
          abv: abv != null ? Number(abv) : null,
          volume_l: volume,
          tax_rate: null,
        })
      }

      const taxRate = applicableTaxRate(categoryCode, movementAt)
      const lineTaxAmount = calculateTaxAmount(moveType, volume, taxRate, taxEvent)
      if (isSummaryDocType(moveType)) {
        totalTax += lineTaxAmount
      }
      taxTotalMap.set(key, (taxTotalMap.get(key) ?? 0) + lineTaxAmount)
      taxRateWeightedMap.set(key, (taxRateWeightedMap.get(key) ?? 0) + (taxRate * volume))
    })

    breakdownMap.forEach((item, key) => {
      const taxTotal = taxTotalMap.get(key) ?? 0
      const direction = Math.sign(calculateTaxAmount(item.move_type, item.volume_l, 1, item.tax_event))
      const weightedRate = item.volume_l > 0 ? (taxRateWeightedMap.get(key) ?? 0) / item.volume_l : 0
      item.tax_rate =
        item.volume_l > 0 && direction !== 0
          ? (taxTotal * 1000) / (item.volume_l * direction)
          : weightedRate
    })

    const generatedItems = sortTaxVolumeItems(Array.from(breakdownMap.values()))
    reportBreakdown.value = summaryItemsFromBreakdown(generatedItems)
    disposeBreakdown.value = disposeItemsFromBreakdown(generatedItems)
    sortMovementBreakdown(reportBreakdown.value)
    totalTaxAmount.value = totalTax
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    generating.value = false
  }
}

function validateForm() {
  Object.keys(errors).forEach((key) => delete errors[key])
  if (!form.tax_type) errors.tax_type = t('taxReport.errors.taxTypeRequired')
  if (!form.tax_year) errors.tax_year = t('taxReport.errors.taxYearRequired')
  if (form.tax_type === 'monthly' && !form.tax_month) errors.tax_month = t('taxReport.errors.taxMonthRequired')
  if (!form.status) errors.status = t('taxReport.errors.statusRequired')
  if (reportBreakdown.value.length === 0) errors.breakdown = t('taxReport.errors.breakdownRequired')
  return Object.keys(errors).length === 0
}

async function buildSummaryXmlFile() {
  const summaryBreakdown = summaryItemsFromBreakdown(reportBreakdown.value)
  if (summaryBreakdown.length === 0) return null
  const tenant = await ensureTenant()
  const priorFiscalYearStandardTaxAmount = await fetchPriorFiscalYearStandardTaxAmount({
    supabase,
    tenantId: tenant,
    taxYear: form.tax_year,
    taxMonth: form.tax_month,
    excludeReportId: form.id || null,
  })
  const fileName = buildXmlFilename(form.tax_type, form.tax_year, form.tax_month)
  const content = await buildXmlPayload({
    taxType: form.tax_type,
    taxYear: form.tax_year,
    taxMonth: form.tax_month,
    breakdown: summaryBreakdown,
    profile: tenantProfile.value,
    tenantId: tenant,
    tenantName: tenantName.value,
    priorFiscalYearStandardTaxAmount,
    includeLia130: true,
  })
  return {
    blob: new Blob([content], { type: 'application/xml' }),
    fileName,
    fileType: 'tax_report_xml' as const,
    generatedAt: new Date().toISOString(),
    mimeType: 'application/xml',
  }
}

async function buildDisposeXmlFile() {
  if (disposeBreakdown.value.length === 0) return null
  const fileName = buildDisposeXmlFilename(form.tax_type, form.tax_year, form.tax_month)
  const content = await buildXmlPayload({
    taxType: form.tax_type,
    taxYear: form.tax_year,
    taxMonth: form.tax_month,
    breakdown: disposeBreakdown.value,
    profile: tenantProfile.value,
    tenantId: tenantId.value ?? '',
    tenantName: tenantName.value,
    includeLia130: false,
  })
  return {
    blob: new Blob([content], { type: 'application/xml' }),
    fileName,
    fileType: 'tax_report_dispose_xml' as const,
    generatedAt: new Date().toISOString(),
    mimeType: 'application/xml',
  }
}

async function buildTaxableRemovalExcelFile() {
  if (form.tax_type !== 'monthly' || !form.tax_year || !form.tax_month) return null

  const tenant = await ensureTenant()
  const detailRows = await loadTaxableRemovalDetailRows({
    supabase,
    tenantId: tenant,
    locale: locale.value,
    removalTypeLabel: t('taxableRemovalReport.defaults.taxableRemovalType'),
  })
  const businessYear =
    businessYearForDate(`${form.tax_year}-${String(form.tax_month).padStart(2, '0')}-01`) ??
    form.tax_year
  const fileName = buildTaxableRemovalExcelFilename(form.tax_year, form.tax_month)
  const createdAt = new Date()
  const blob = createTaxableRemovalMonthWorkbookBlob({
    detailRows,
    businessYear,
    month: form.tax_month,
    labels: taxableRemovalExportLabels.value,
    locale: locale.value,
    createdAt,
    creator: 'beeradmin_tail',
  })

  return {
    blob,
    fileName,
    fileType: 'taxable_removal_excel' as const,
    generatedAt: createdAt.toISOString(),
    mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  }
}

async function saveReport() {
  if (!validateForm()) return
  let uploadedFiles: TaxReportStoredFile[] = []
  try {
    saving.value = true
    const tenant = await ensureTenant()
    const reportId = form.id || createReportId()
    const isNew = !editing.value
    const status = isNew ? 'draft' : form.status
    if (form.tax_type === 'yearly') form.tax_month = 12
    const generatedFiles: GeneratedTaxReportFile[] = []

    const summaryFile = await buildSummaryXmlFile()
    if (summaryFile) generatedFiles.push(summaryFile)

    const disposeFile = await buildDisposeXmlFile()
    if (disposeFile) generatedFiles.push(disposeFile)

    const taxableRemovalFile = await buildTaxableRemovalExcelFile()
    if (taxableRemovalFile) generatedFiles.push(taxableRemovalFile)

    const activeFileTypes = new Set(generatedFiles.map((file) => file.fileType))
    const obsoleteStoredFiles = storedReportFiles.value.filter(
      (file) => !activeFileTypes.has(file.fileType as GeneratedTaxReportFile['fileType']),
    )
    const retainedStoredFiles = storedReportFiles.value.filter(
      (file) => activeFileTypes.has(file.fileType as GeneratedTaxReportFile['fileType']),
    )

    uploadedFiles = await uploadGeneratedTaxReportFiles({
      supabase,
      files: generatedFiles,
      reportId,
      tenantId: tenant,
    })

    const payload = {
      id: reportId,
      tenant_id: tenant,
      tax_type: form.tax_type,
      tax_year: form.tax_year,
      tax_month: form.tax_month,
      status,
      total_tax_amount: totalTaxAmount.value,
      volume_breakdown: [...reportBreakdown.value, ...disposeBreakdown.value],
      report_files: mergeStoredFiles(retainedStoredFiles, uploadedFiles),
      attachment_files: parseFileList(form.attachment_files),
    }

    if (editing.value && form.id) {
      const { error } = await supabase.from(TABLE).update(payload).eq('id', form.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from(TABLE).insert(payload)
      if (error) throw error
    }

    storedReportFiles.value = payload.report_files
    if (obsoleteStoredFiles.length > 0) {
      try {
        await removeStoredTaxReportFiles({
          supabase,
          files: obsoleteStoredFiles,
        })
      } catch (cleanupErr) {
        console.warn('Failed to remove obsolete tax report files from storage', cleanupErr)
      }
    }
    await router.push({ name: 'TaxReport' })
  } catch (err) {
    if (uploadedFiles.length > 0) {
      await removeStoredTaxReportFiles({
        supabase,
        files: uploadedFiles,
      })
    }
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

async function createXmlForSummary() {
  const summaryFile = await buildSummaryXmlFile()
  if (!summaryFile) {
    toast.info(t('taxReport.emptyBreakdown'))
    return
  }

  try {
    const xml = await summaryFile.blob.text()
    downloadTextFile(summaryFile.fileName, xml)
    setXmlLink('summary', summaryFile.fileName, xml)
  } catch (err) {
    toast.error(err instanceof Error ? err.message : String(err))
    console.error(err)
  }
}

async function createXmlForDispose() {
  const disposeFile = await buildDisposeXmlFile()
  if (!disposeFile) {
    toast.info(t('taxReport.emptyBreakdown'))
    return
  }

  try {
    const xml = await disposeFile.blob.text()
    downloadTextFile(disposeFile.fileName, xml)
    setXmlLink('dispose', disposeFile.fileName, xml)
  } catch (err) {
    toast.error(err instanceof Error ? err.message : String(err))
    console.error(err)
  }
}

async function generateTaxableRemovalExcelForCurrentPeriod() {
  if (form.tax_type !== 'monthly' || !form.tax_year || !form.tax_month) return

  try {
    await buildTaxableRemovalExcelFile()
  } catch (err) {
    console.error(err)
    toast.error(t('taxableRemovalReport.export.failed'))
  }
}

function handleAttachmentUpload(event: Event) {
  const input = event.target as HTMLInputElement
  const files = Array.from(input.files ?? [])
  if (!files.length) return
  const current = new Set(parseFileList(form.attachment_files))
  files.forEach((file) => current.add(file.name))
  form.attachment_files = Array.from(current).join('\n')
  input.value = ''
}

function removeAttachment(file: string) {
  form.attachment_files = parseFileList(form.attachment_files)
    .filter((name) => name !== file)
    .join('\n')
}

async function loadExistingReport(id: string) {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from(TABLE)
    .select('id, tax_type, tax_year, tax_month, status, total_tax_amount, volume_breakdown, report_files, attachment_files, created_at')
    .eq('tenant_id', tenant)
    .eq('id', id)
    .maybeSingle()
  if (error) throw error
  if (!data) throw new Error('Tax report not found')

  const row = normalizeReport(data as JsonMap)
  form.id = row.id
  form.tax_type = row.tax_type || 'monthly'
  form.tax_year = row.tax_year
  form.tax_month = row.tax_month
  form.status = row.status
  form.attachment_files = row.attachment_files.join('\n')
  storedReportFiles.value = row.report_files
  reportBreakdown.value = sortTaxVolumeItems(summaryItemsFromBreakdown(row.volume_breakdown)).map((item) => ({ ...item }))
  disposeBreakdown.value = sortTaxVolumeItems(disposeItemsFromBreakdown(row.volume_breakdown)).map((item) => ({ ...item }))
  sortMovementBreakdown(reportBreakdown.value)
  totalTaxAmount.value = row.total_tax_amount
}

function queryNumber(value: unknown, fallback: number) {
  const numeric = Number(value)
  return Number.isFinite(numeric) ? numeric : fallback
}

async function initializeNewReport() {
  form.tax_type = typeof route.query.taxType === 'string' ? route.query.taxType : 'monthly'
  form.tax_year = queryNumber(route.query.taxYear, new Date().getFullYear())
  form.tax_month = form.tax_type === 'monthly' ? queryNumber(route.query.taxMonth, new Date().getMonth() + 1) : 12
  form.status = 'draft'
  await generateReportForPeriod(form.tax_type, form.tax_year, form.tax_month)
  if (form.tax_type === 'monthly') await generateTaxableRemovalExcelForCurrentPeriod()
}

async function goBack() {
  await router.push({ name: 'TaxReport' })
}

onMounted(async () => {
  try {
    loadingInitial.value = true
    await ensureTenant()
    await Promise.all([loadCategories(), loadUoms(), loadTaxRates(), loadMovementRules(), loadTenantTaxReportProfile()])
    if (editing.value && typeof route.params.id === 'string') {
      await loadExistingReport(route.params.id)
    } else {
      await initializeNewReport()
    }
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    loadingInitial.value = false
  }
})

onUnmounted(() => {
  if (summaryXmlUrl.value) URL.revokeObjectURL(summaryXmlUrl.value)
  if (disposeXmlUrl.value) URL.revokeObjectURL(disposeXmlUrl.value)
})
</script>
