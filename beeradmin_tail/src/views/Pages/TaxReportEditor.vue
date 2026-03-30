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
                :disabled="editing"
                @change="handlePeriodChange"
              >
                <option v-for="type in taxTypeOptions" :key="type" :value="type">{{ taxTypeLabel(type) }}</option>
              </select>
              <p v-if="errors.tax_type" class="mt-1 text-xs text-red-600">{{ errors.tax_type }}</p>
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
                :disabled="editing"
                @change="handlePeriodChange"
              />
              <p v-if="errors.tax_year" class="mt-1 text-xs text-red-600">{{ errors.tax_year }}</p>
            </div>
            <div v-if="form.tax_type === 'monthly'">
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('taxReport.form.taxMonth') }}<span class="text-red-600">*</span>
              </label>
              <select
                v-model.number="form.tax_month"
                class="h-[40px] w-full rounded border bg-white px-3"
                :disabled="editing"
                @change="handlePeriodChange"
              >
                <option v-for="month in monthOptions" :key="month" :value="month">{{ month }}</option>
              </select>
              <p v-if="errors.tax_month" class="mt-1 text-xs text-red-600">{{ errors.tax_month }}</p>
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
                <h2 class="text-base font-semibold">{{ t('taxReport.sections.summary.title') }}</h2>
                <p class="text-xs text-gray-500">{{ t('taxReport.sections.summary.subtitle') }}</p>
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
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.movementType') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.category') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.abv') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('taxReport.breakdown.columns.volume') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="(item, index) in reportBreakdown" :key="item.key">
                    <td class="px-3 py-2 text-gray-700">{{ movementTypeLabel(item.move_type) }}</td>
                    <td class="px-3 py-2 text-gray-700">{{ item.categoryName }}</td>
                    <td class="px-3 py-2">
                      <input
                        v-model.number="item.abv"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2"
                        @input="handleBreakdownChange(index)"
                      />
                    </td>
                    <td class="px-3 py-2 text-right">
                      <input
                        v-model.number="item.volume_l"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2 text-right"
                        @input="handleBreakdownChange(index)"
                      />
                    </td>
                  </tr>
                  <tr v-if="reportBreakdown.length === 0">
                    <td colspan="4" class="px-3 py-4 text-center text-xs text-gray-400">{{ t('taxReport.emptyBreakdown') }}</td>
                  </tr>
                </tbody>
              </table>
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
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.movementType') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.category') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.abv') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('taxReport.breakdown.columns.volume') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="(item, index) in disposeBreakdown" :key="item.key">
                    <td class="px-3 py-2 text-gray-700">{{ movementTypeLabel(item.move_type) }}</td>
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
            <label class="block text-sm text-gray-600">{{ t('taxReport.form.xmlFiles') }}</label>
            <textarea
              v-model.trim="form.report_files"
              rows="3"
              class="w-full rounded border px-3 py-2"
              :placeholder="t('taxReport.form.xmlPlaceholder')"
            ></textarea>
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
  buildDisposeXmlFilename,
  buildXmlFilename,
  buildXmlPayload,
  disposeItemsFromBreakdown,
  normalizeReport,
  parseFileList,
  summaryItemsFromBreakdown,
  type JsonMap,
  type TaxVolumeItem,
} from '@/lib/taxReport'
import {
  buildTaxableRemovalMonthFileName,
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

interface MovementHeader {
  id: string
  movement_at: string | null
  doc_type: string
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
const TAX_TEMPLATE_PATH = '/etax/R7年11月_納税申告.xtx'

const { t, tm, locale } = useI18n()
const route = useRoute()
const router = useRouter()

const loadingInitial = ref(false)
const saving = ref(false)
const generating = ref(false)
const taxableRemovalLoading = ref(false)
const templateXml = ref('')
const tenantId = ref<string | null>(null)

const categories = ref<CategoryRow[]>([])
const uoms = ref<Array<{ id: string; code: string | null }>>([])
const taxRateIndex = ref<Record<string, TaxRateRecord[]>>({})

const form = reactive({
  id: '',
  tax_type: 'monthly',
  tax_year: new Date().getFullYear(),
  tax_month: new Date().getMonth() + 1,
  status: 'draft',
  report_files: '',
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

const editing = computed(() => typeof route.params.id === 'string' && route.params.id.length > 0)
const pageTitle = computed(() => (editing.value ? t('taxReportEditor.editTitle') : t('taxReportEditor.newTitle')))
const statusOptions = STATUS_OPTIONS
const taxTypeOptions = TAX_TYPE_OPTIONS
const monthOptions = computed(() => Array.from({ length: 12 }, (_, idx) => idx + 1))
const currencyFormatter = computed(
  () => new Intl.NumberFormat(locale.value, { style: 'currency', currency: 'JPY', maximumFractionDigits: 0 }),
)
const attachmentList = computed(() => parseFileList(form.attachment_files))
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

function movementTypeLabel(value: string) {
  const map = tm('taxReport.movementTypeMap')
  if (!map || typeof map !== 'object') return value
  const label = (map as Record<string, unknown>)[value]
  return typeof label === 'string' ? label : value
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
  totalTaxAmount.value = summaryItemsFromBreakdown(reportBreakdown.value).reduce((sum, item) => {
    const volume = Number.isFinite(item.volume_l) ? item.volume_l : 0
    const rate = item.tax_rate ?? 0
    return sum + volume * rate
  }, 0)
}

function handleBreakdownChange(index: number) {
  const item = reportBreakdown.value[index]
  if (!item) return
  if (!Number.isFinite(item.volume_l)) item.volume_l = 0
  if (!Number.isFinite(item.abv)) item.abv = null
  recalcTotalTax()
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

async function loadTemplate() {
  try {
    const response = await fetch(TAX_TEMPLATE_PATH)
    if (!response.ok) throw new Error(`Template fetch failed: ${response.status}`)
    templateXml.value = await response.text()
  } catch (err) {
    console.error(err)
    toast.error(t('taxReport.templateMissing'))
    templateXml.value = ''
  }
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
      .select('id, movement_at, doc_type')
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

    const headerMap = new Map(headers.map((row) => [row.id, { movementAt: row.movement_at, docType: row.doc_type }]))
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
    let totalTax = 0

    lines.forEach((line) => {
      const header = headerMap.get(line.movement_id)
      const movementAt = header?.movementAt ?? null
      const moveType = header?.docType ?? 'unknown'
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

      const key = `${moveType}-${categoryId}-${abv ?? 'na'}`
      const existing = breakdownMap.get(key)
      if (existing) {
        existing.volume_l += volume
      } else {
        breakdownMap.set(key, {
          key,
          move_type: moveType,
          categoryId,
          categoryCode,
          categoryName,
          abv: abv != null ? Number(abv) : null,
          volume_l: volume,
          tax_rate: null,
        })
      }

      const taxRate = applicableTaxRate(categoryCode, movementAt)
      if (isSummaryDocType(moveType)) {
        totalTax += volume * taxRate
      }
      taxTotalMap.set(key, (taxTotalMap.get(key) ?? 0) + volume * taxRate)
    })

    breakdownMap.forEach((item, key) => {
      const taxTotal = taxTotalMap.get(key) ?? 0
      item.tax_rate = item.volume_l > 0 ? taxTotal / item.volume_l : 0
    })

    const generatedItems = Array.from(breakdownMap.values()).sort((a, b) => {
      if (a.categoryName !== b.categoryName) return a.categoryName.localeCompare(b.categoryName)
      return (a.abv ?? 0) - (b.abv ?? 0)
    })
    reportBreakdown.value = summaryItemsFromBreakdown(generatedItems)
    disposeBreakdown.value = disposeItemsFromBreakdown(generatedItems)
    totalTaxAmount.value = totalTax
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    generating.value = false
  }
}

async function handlePeriodChange() {
  if (editing.value) return
  if (!form.tax_year) return
  if (form.tax_type === 'monthly' && !form.tax_month) return
  if (form.tax_type === 'yearly') form.tax_month = 12
  await generateReportForPeriod(form.tax_type, form.tax_year, form.tax_month)
  if (form.tax_type === 'monthly') await generateTaxableRemovalExcelForCurrentPeriod()
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

async function saveReport() {
  if (!validateForm()) return
  try {
    saving.value = true
    const tenant = await ensureTenant()
    const isNew = !editing.value
    const status = isNew ? 'draft' : form.status
    if (form.tax_type === 'yearly') form.tax_month = 12

    if (isNew) {
      const filename = buildXmlFilename(form.tax_type, form.tax_year, form.tax_month)
      const fileSet = new Set(parseFileList(form.report_files))
      if (!fileSet.has(filename)) {
        try {
          const xml = buildXmlPayload({
            templateXml: templateXml.value,
            movementTypeLabel,
            taxType: form.tax_type,
            taxYear: form.tax_year,
            taxMonth: form.tax_month,
            breakdown: reportBreakdown.value,
          })
          downloadTextFile(filename, xml)
          fileSet.add(filename)
          form.report_files = Array.from(fileSet).join('\n')
        } catch (err) {
          toast.error(t('taxReport.templateMissing'))
          console.error(err)
        }
      }
    }

    const payload = {
      tenant_id: tenant,
      tax_type: form.tax_type,
      tax_year: form.tax_year,
      tax_month: form.tax_month,
      status,
      total_tax_amount: totalTaxAmount.value,
      volume_breakdown: [...reportBreakdown.value, ...disposeBreakdown.value],
      report_files: parseFileList(form.report_files),
      attachment_files: parseFileList(form.attachment_files),
    }

    if (editing.value && form.id) {
      const { error } = await supabase.from(TABLE).update(payload).eq('id', form.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from(TABLE).insert(payload)
      if (error) throw error
    }

    await router.push({ name: 'TaxReport' })
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

function createXmlForSummary() {
  const summaryBreakdown = summaryItemsFromBreakdown(reportBreakdown.value)
  if (summaryBreakdown.length === 0) {
    toast.info(t('taxReport.emptyBreakdown'))
    return
  }
  const filename = buildXmlFilename(form.tax_type, form.tax_year, form.tax_month)
  try {
    const xml = buildXmlPayload({
      templateXml: templateXml.value,
      movementTypeLabel,
      taxType: form.tax_type,
      taxYear: form.tax_year,
      taxMonth: form.tax_month,
      breakdown: summaryBreakdown,
    })
    downloadTextFile(filename, xml)
    setXmlLink('summary', filename, xml)
  } catch (err) {
    toast.error(t('taxReport.templateMissing'))
    console.error(err)
    return
  }

  const files = new Set(parseFileList(form.report_files))
  files.add(filename)
  form.report_files = Array.from(files).join('\n')
}

function createXmlForDispose() {
  if (disposeBreakdown.value.length === 0) {
    toast.info(t('taxReport.emptyBreakdown'))
    return
  }
  const filename = buildDisposeXmlFilename(form.tax_type, form.tax_year, form.tax_month)
  try {
    const xml = buildXmlPayload({
      templateXml: templateXml.value,
      movementTypeLabel,
      taxType: form.tax_type,
      taxYear: form.tax_year,
      taxMonth: form.tax_month,
      breakdown: disposeBreakdown.value,
    })
    downloadTextFile(filename, xml)
    setXmlLink('dispose', filename, xml)
  } catch (err) {
    toast.error(t('taxReport.templateMissing'))
    console.error(err)
    return
  }

  const files = new Set(parseFileList(form.report_files))
  files.add(filename)
  form.report_files = Array.from(files).join('\n')
}

async function generateTaxableRemovalExcelForCurrentPeriod() {
  if (form.tax_type !== 'monthly' || !form.tax_year || !form.tax_month) return

  try {
    taxableRemovalLoading.value = true
    const tenant = await ensureTenant()
    const detailRows = await loadTaxableRemovalDetailRows({
      supabase,
      tenantId: tenant,
      locale: locale.value,
      removalTypeLabel: t('taxableRemovalReport.defaults.taxableRemovalType'),
    })
    const businessYear = businessYearForDate(`${form.tax_year}-${String(form.tax_month).padStart(2, '0')}-01`) ?? form.tax_year
    const fileName = buildTaxableRemovalMonthFileName(form.tax_year, form.tax_month)
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
    downloadBlob(fileName, blob)
  } catch (err) {
    console.error(err)
    toast.error(t('taxableRemovalReport.export.failed'))
  } finally {
    taxableRemovalLoading.value = false
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
  form.report_files = row.report_files.join('\n')
  form.attachment_files = row.attachment_files.join('\n')
  reportBreakdown.value = summaryItemsFromBreakdown(row.volume_breakdown).map((item) => ({ ...item }))
  disposeBreakdown.value = disposeItemsFromBreakdown(row.volume_breakdown).map((item) => ({ ...item }))
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
    await Promise.all([loadCategories(), loadUoms(), loadTaxRates(), loadTemplate()])
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
