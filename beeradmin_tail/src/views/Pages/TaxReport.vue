<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto space-y-4">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('taxReport.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('taxReport.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">
            {{ t('taxReport.actions.new') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="fetchReports"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white">
        <form class="grid grid-cols-1 md:grid-cols-6 gap-3" @submit.prevent>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.filters.taxType') }}</label>
            <select v-model="filters.taxType" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="type in taxTypeOptions" :key="type" :value="type">{{ taxTypeLabel(type) }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.filters.taxYear') }}</label>
            <select v-model="filters.taxYear" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="year in yearOptions" :key="year" :value="String(year)">{{ year }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.filters.taxMonth') }}</label>
            <select
              v-model="filters.taxMonth"
              class="w-full h-[40px] border rounded px-3 bg-white"
              :disabled="filters.taxType === 'yearly'"
            >
              <option value="">{{ t('common.all') }}</option>
              <option v-for="month in monthOptions" :key="month" :value="String(month)">{{ month }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.filters.status') }}</label>
            <select v-model="filters.status" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="status in statusOptions" :key="status" :value="status">{{ statusLabel(status) }}</option>
            </select>
          </div>
        </form>
      </section>

      <section class="grid gap-4">
        <article v-for="row in rows" :key="row.id" class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
          <div class="flex flex-col gap-2 md:flex-row md:items-start md:justify-between">
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">{{ t('taxReport.card.taxType') }}</p>
              <h3 class="text-lg font-semibold text-gray-900">{{ taxTypeLabel(row.tax_type) }}</h3>
              <p class="text-xs uppercase tracking-wide text-gray-400 mt-2">{{ t('taxReport.card.period') }}</p>
              <p class="text-xs text-gray-500">{{ formatPeriod(row) }}</p>
            </div>
            <div class="text-left md:text-right">
              <p class="text-xs uppercase tracking-wide text-gray-400">{{ t('taxReport.card.status') }}</p>
              <p class="text-sm text-gray-700">{{ statusLabel(row.status) }}</p>
              <p class="mt-2 text-xs uppercase tracking-wide text-gray-400">{{ t('taxReport.card.totalTax') }}</p>
              <p class="text-lg font-semibold text-gray-900">{{ formatCurrency(row.total_tax_amount) }}</p>
            </div>
          </div>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400 mb-2">{{ t('taxReport.card.productionVolume') }}</p>
              <div v-if="row.volume_breakdown.length" class="space-y-1 text-sm text-gray-700">
                <div v-for="item in row.volume_breakdown" :key="item.key">
                  {{ breakdownLabel(item) }}
                </div>
              </div>
              <p v-else class="text-xs text-gray-400">—</p>
            </div>
            <div class="grid grid-cols-1 gap-3 text-xs">
              <div>
                <p class="text-gray-500 mb-1">{{ t('taxReport.card.xmlFiles') }}</p>
                <div v-if="row.report_files.length" class="space-y-1">
                  <div v-for="file in row.report_files" :key="file" class="text-blue-600">{{ file }}</div>
                </div>
                <div v-else class="text-gray-400">—</div>
              </div>
              <div>
                <p class="text-gray-500 mb-1">{{ t('taxReport.card.attachments') }}</p>
                <div v-if="row.attachment_files.length" class="space-y-1">
                  <div v-for="file in row.attachment_files" :key="file" class="text-blue-600">{{ file }}</div>
                </div>
                <div v-else class="text-gray-400">—</div>
              </div>
            </div>
          </div>

          <div class="flex flex-wrap items-center gap-2">
            <button class="px-3 py-1.5 text-xs rounded border hover:bg-gray-100" @click="createXmlForRow(row)">
              {{ t('taxReport.actions.createXml') }}
            </button>
            <button class="px-3 py-1.5 text-xs rounded border hover:bg-gray-100" @click="openEdit(row)">
              {{ t('common.edit') }}
            </button>
          </div>
        </article>
        <p v-if="!loading && rows.length === 0" class="py-8 text-center text-gray-500">{{ t('common.noData') }}</p>
      </section>

      <div v-if="showCreatePrompt" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-xl bg-white rounded-xl shadow-lg border">
          <header class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('taxReport.createPrompt.title') }}</h3>
          </header>
          <section class="p-4 space-y-4">
            <p class="text-sm text-gray-500">{{ t('taxReport.createPrompt.subtitle') }}</p>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.form.taxType') }}</label>
                <select v-model="promptForm.tax_type" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option v-for="type in taxTypeOptions" :key="type" :value="type">{{ taxTypeLabel(type) }}</option>
                </select>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.form.taxYear') }}</label>
                <input v-model.number="promptForm.tax_year" type="number" min="2000" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div v-if="promptForm.tax_type === 'monthly'">
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.form.taxMonth') }}</label>
                <select v-model.number="promptForm.tax_month" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option v-for="month in monthOptions" :key="month" :value="month">{{ month }}</option>
                </select>
              </div>
            </div>
          </section>
          <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeCreatePrompt">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="startCreateFromPrompt">
              {{ t('taxReport.createPrompt.confirm') }}
            </button>
          </footer>
        </div>
      </div>

      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-3xl bg-white rounded-xl shadow-lg border">
          <header class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ editing ? t('taxReport.modal.editTitle') : t('taxReport.modal.newTitle') }}</h3>
          </header>
          <section class="p-4 space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.form.taxType') }}<span class="text-red-600">*</span></label>
                <select
                  v-model="form.tax_type"
                  class="w-full h-[40px] border rounded px-3 bg-white"
                  :disabled="editing"
                  @change="handlePeriodChange"
                >
                  <option v-for="type in taxTypeOptions" :key="type" :value="type">{{ taxTypeLabel(type) }}</option>
                </select>
                <p v-if="errors.tax_type" class="text-xs text-red-600 mt-1">{{ errors.tax_type }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.form.taxYear') }}<span class="text-red-600">*</span></label>
                <input
                  v-model.number="form.tax_year"
                  type="number"
                  min="2000"
                  class="w-full h-[40px] border rounded px-3"
                  :disabled="editing"
                  @change="handlePeriodChange"
                />
                <p v-if="errors.tax_year" class="text-xs text-red-600 mt-1">{{ errors.tax_year }}</p>
              </div>
              <div v-if="form.tax_type === 'monthly'">
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.form.taxMonth') }}<span class="text-red-600">*</span></label>
                <select
                  v-model.number="form.tax_month"
                  class="w-full h-[40px] border rounded px-3 bg-white"
                  :disabled="editing"
                  @change="handlePeriodChange"
                >
                  <option v-for="month in monthOptions" :key="month" :value="month">{{ month }}</option>
                </select>
                <p v-if="errors.tax_month" class="text-xs text-red-600 mt-1">{{ errors.tax_month }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.form.status') }}<span class="text-red-600">*</span></label>
                <select v-model="form.status" class="w-full h-[40px] border rounded px-3 bg-white" :disabled="!editing">
                  <option v-for="status in statusOptions" :key="status" :value="status">{{ statusLabel(status) }}</option>
                </select>
                <p v-if="errors.status" class="text-xs text-red-600 mt-1">{{ errors.status }}</p>
              </div>
              <div class="md:col-span-4">
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.form.totalTax') }}</label>
                <div class="h-[40px] flex items-center border rounded px-3 text-sm text-gray-700 bg-gray-50">
                  {{ formatCurrency(totalTaxAmount) }}
                </div>
              </div>
            </div>

            <section class="space-y-3">
              <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
                <div>
                  <h4 class="text-base font-semibold">{{ t('taxReport.sections.summary.title') }}</h4>
                  <p class="text-xs text-gray-500">{{ t('taxReport.sections.summary.subtitle') }}</p>
                </div>
                <div class="flex flex-wrap items-center gap-2">
                  <button
                    class="px-3 py-2 rounded border hover:bg-gray-50"
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
              <div class="border rounded bg-gray-50 overflow-x-auto">
                <table class="min-w-full text-sm">
                  <thead class="text-xs uppercase text-gray-500 bg-white">
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
                          class="w-full h-[36px] border rounded px-2 bg-white"
                          @input="handleBreakdownChange(index)"
                        />
                      </td>
                      <td class="px-3 py-2 text-right">
                        <input
                          v-model.number="item.volume_l"
                          type="number"
                          min="0"
                          step="0.01"
                          class="w-full h-[36px] border rounded px-2 text-right bg-white"
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
                  <h4 class="text-base font-semibold">{{ t('taxReport.sections.dispose.title') }}</h4>
                  <p class="text-xs text-gray-500">{{ t('taxReport.sections.dispose.subtitle') }}</p>
                </div>
                <div class="flex flex-wrap items-center gap-2">
                  <button
                    class="px-3 py-2 rounded border hover:bg-gray-50"
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
              <div class="border rounded bg-gray-50 overflow-x-auto">
                <table class="min-w-full text-sm">
                  <thead class="text-xs uppercase text-gray-500 bg-white">
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
                          class="w-full h-[36px] border rounded px-2 bg-white"
                          @input="handleDisposeChange(index)"
                        />
                      </td>
                      <td class="px-3 py-2 text-right">
                        <input
                          v-model.number="item.volume_l"
                          type="number"
                          min="0"
                          step="0.01"
                          class="w-full h-[36px] border rounded px-2 text-right bg-white"
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
                class="w-full border rounded px-3 py-2"
                :placeholder="t('taxReport.form.xmlPlaceholder')"
              ></textarea>
              <label class="block text-sm text-gray-600">{{ t('taxReport.form.attachments') }}</label>
              <input type="file" multiple class="w-full h-[40px] border rounded px-3 py-2" @change="handleAttachmentUpload" />
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
          </section>
          <footer class="px-4 py-3 border-t flex items-center justify-between">
            <div class="text-xs text-gray-500">
              <span v-if="generating">{{ t('taxReport.generating') }}</span>
            </div>
            <div class="flex items-center gap-2">
              <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">{{ t('common.cancel') }}</button>
              <button
                class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
                :disabled="saving || generating"
                @click="saveReport"
              >
                {{ saving ? t('common.saving') : t('common.save') }}
              </button>
            </div>
          </footer>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

interface CategoryRow {
  id: string
  code: string
  name: string | null
}

interface TaxRateRecord {
  taxrate: number
  effectDate: Date | null
  expireDate: Date | null
}

interface TaxVolumeItem {
  key: string
  move_type: string
  categoryId: string
  categoryCode: string
  categoryName: string
  abv: number | null
  volume_l: number
  tax_rate: number | null
}

interface TaxReportRow {
  id: string
  tax_type: string
  tax_year: number
  tax_month: number
  status: string
  total_tax_amount: number
  volume_breakdown: TaxVolumeItem[]
  report_files: string[]
  attachment_files: string[]
  created_at: string | null
}

interface MovementHeader {
  id: string
  movement_at: string | null
  doc_type: string
}

interface MovementLine {
  movement_id: string
  package_id: string | null
  lot_id: string | null
  qty: number | null
  uom_id: string | null
  meta?: Record<string, any> | null
}

interface PackageRow {
  id: string
  fill_at: string | null
  package_qty: number | null
  package_size_l: number | null
  lot?: {
    id: string
    actual_abv: number | null
    recipe?: {
      id: string
      name: string
      category: string | null
      target_abv: number | null
    } | null
  } | null
  package?: {
    id: string
    size: number | null
    uom_id: string | null
  } | null
}

const TABLE = 'tax_reports'
const STATUS_OPTIONS = ['draft', 'submitted', 'approved'] as const
const TAX_TYPE_OPTIONS = ['monthly', 'yearly'] as const
const MOVEMENT_DOC_TYPES = ['sale', 'tax_transfer', 'return', 'transfer', 'waste'] as const

const { t, locale } = useI18n()
const pageTitle = computed(() => t('taxReport.title'))

const rows = ref<TaxReportRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const editing = ref(false)
const generating = ref(false)
const showCreatePrompt = ref(false)
const templateXml = ref('')

const TAX_TEMPLATE_PATH = '/etax/R7年11月_納税申告.xtx'

const filters = reactive({ taxType: '', taxYear: '', taxMonth: '', status: '' })

const categories = ref<CategoryRow[]>([])
const uoms = ref<Array<{ id: string; code: string | null }>>([])
const taxRateIndex = ref<Record<string, TaxRateRecord[]>>({})
const tenantId = ref<string | null>(null)

const form = reactive({
  id: '',
  tax_type: 'monthly',
  tax_year: new Date().getFullYear(),
  tax_month: new Date().getMonth() + 1,
  status: 'draft',
  report_files: '',
  attachment_files: '',
})

const promptForm = reactive({
  tax_type: 'monthly',
  tax_year: new Date().getFullYear(),
  tax_month: new Date().getMonth() + 1,
})

const errors = reactive<Record<string, string>>({})
const reportBreakdown = ref<TaxVolumeItem[]>([])
const disposeBreakdown = ref<TaxVolumeItem[]>([])
const totalTaxAmount = ref(0)
const summaryXmlUrl = ref('')
const summaryXmlName = ref('')
const disposeXmlUrl = ref('')
const disposeXmlName = ref('')

const statusOptions = STATUS_OPTIONS
const taxTypeOptions = TAX_TYPE_OPTIONS

const yearOptions = computed(() => {
  const current = new Date().getFullYear()
  const years = new Set<number>()
  for (let i = current - 3; i <= current + 1; i += 1) years.add(i)
  rows.value.forEach((row) => years.add(row.tax_year))
  return Array.from(years).sort((a, b) => b - a)
})

const monthOptions = computed(() => Array.from({ length: 12 }, (_, idx) => idx + 1))

const currencyFormatter = computed(
  () => new Intl.NumberFormat(locale.value, { style: 'currency', currency: 'JPY', maximumFractionDigits: 0 })
)

function statusLabel(status: string) {
  const map = t('taxReport.statusMap') as Record<string, string>
  return map[status] || status
}

function taxTypeLabel(taxType: string) {
  const map = t('taxReport.taxTypeMap') as Record<string, string>
  return map[taxType] || taxType
}

function movementTypeLabel(value: string) {
  const map = t('taxReport.movementTypeMap') as Record<string, string>
  return map[value] || value
}

function formatPeriod(row: TaxReportRow) {
  if (row.tax_type === 'yearly') return `${row.tax_year} / —`
  return `${row.tax_year} / ${row.tax_month || '—'}`
}

const attachmentList = computed(() => parseFileList(form.attachment_files))

function formatCurrency(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  try {
    return currencyFormatter.value.format(value)
  } catch {
    return `¥${Math.round(value).toLocaleString()}`
  }
}

function formatVolume(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return `${new Intl.NumberFormat(locale.value, { maximumFractionDigits: 2 }).format(value)} L`
}

function formatAbv(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return t('taxReport.abvUnknown')
  return `${new Intl.NumberFormat(locale.value, { maximumFractionDigits: 2 }).format(value)}%`
}

function breakdownLabel(item: TaxVolumeItem) {
  return `${movementTypeLabel(item.move_type)} · ${item.categoryName} (${formatAbv(item.abv)}): ${formatVolume(item.volume_l)}`
}

function parseFileList(text: string) {
  return text
    .split(/[\n,]/)
    .map((entry) => entry.trim())
    .filter(Boolean)
}

function reiwaYear(year: number) {
  if (year >= 2019) return { era: 5, yy: year - 2018 }
  if (year >= 1989) return { era: 4, yy: year - 1988 }
  return { era: 3, yy: year }
}

function formatXmlVolume(value: number) {
  if (!Number.isFinite(value)) return '0'
  return String(Math.round(value * 1000))
}

function resolveCategoryCode(item: TaxVolumeItem) {
  if (item.categoryCode && /^\d+$/.test(item.categoryCode)) return item.categoryCode
  return '000'
}

function kubunCodeForMoveType(moveType: string, fallback = '1') {
  switch (moveType) {
    case 'sale':
      return '1'
    case 'tax_transfer':
      return '2'
    case 'transfer':
      return '3'
    case 'waste':
      return '4'
    default:
      return fallback
  }
}

function recalcTotalTax() {
  totalTaxAmount.value = reportBreakdown.value.reduce((sum, item) => {
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
  if (item.move_type === 'waste') {
    const disposeItem = disposeBreakdown.value.find((entry) => entry.key === item.key)
    if (disposeItem) {
      disposeItem.abv = item.abv
      disposeItem.volume_l = item.volume_l
    }
  }
  recalcTotalTax()
}

function handleDisposeChange(index: number) {
  const item = disposeBreakdown.value[index]
  if (!item) return
  if (!Number.isFinite(item.volume_l)) item.volume_l = 0
  if (!Number.isFinite(item.abv)) item.abv = null
  const summaryItem = reportBreakdown.value.find((entry) => entry.key === item.key)
  if (summaryItem) {
    summaryItem.abv = item.abv
    summaryItem.volume_l = item.volume_l
  }
  recalcTotalTax()
}

function updateDisposeBreakdown() {
  disposeBreakdown.value = reportBreakdown.value
    .filter((item) => item.move_type === 'waste')
    .map((item) => ({ ...item }))
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

function xmlEscape(value: string) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;')
}

function buildXmlPayload(row: {
  taxType: string
  taxYear: number
  taxMonth: number
  status: string
  totalTax: number
  breakdown: TaxVolumeItem[]
}) {
  if (!templateXml.value) {
    throw new Error('TEMPLATE_NOT_LOADED')
  }

  const { era, yy } = reiwaYear(row.taxYear)
  const mm = row.taxType === 'monthly' ? row.taxMonth : 12
  const dateStr = new Date().toISOString().slice(0, 10)

  const taxableItems = row.breakdown.filter((item) => item.move_type !== 'return')
  const returnItems = row.breakdown.filter((item) => item.move_type === 'return')

  const ehdBlocks = taxableItems
    .map((item) => {
      const categoryCode = resolveCategoryCode(item)
      const abvTag = item.abv != null ? `\n                    <EHD00040>${item.abv}</EHD00040>` : ''
      const volume = formatXmlVolume(item.volume_l)
      return `                <EHD00000>
                    <EHD00010>
                        <kubun_CD>${kubunCodeForMoveType(item.move_type)}</kubun_CD>
                    </EHD00010>
                    <EHD00020>${categoryCode}</EHD00020>
                    <EHD00030>${xmlEscape(item.categoryName)}</EHD00030>${abvTag}
                    <EHD00050>${volume}</EHD00050>
                    <EHD00080 AutoCalc="1">${volume}</EHD00080>
                    <EHD00100 AutoCalc="1">0</EHD00100>
                </EHD00000>`
    })
    .join('\n')

  const ekdBlocks = returnItems
    .map((item) => {
      const categoryCode = resolveCategoryCode(item)
      const abvTag = item.abv != null ? `\n                    <EKD00040>${item.abv}</EKD00040>` : ''
      const volume = formatXmlVolume(item.volume_l)
      return `                <EKD00000>
                    <EKD00010>
                        <kubun_CD>1</kubun_CD>
                    </EKD00010>
                    <EKD00020>${categoryCode}</EKD00020>
                    <EKD00030>${xmlEscape(item.categoryName)}</EKD00030>${abvTag}
                    <EKD00080>${volume}</EKD00080>
                    <EKD00100 AutoCalc="1">0</EKD00100>
                    <EKD00120>${xmlEscape(movementTypeLabel(item.move_type))}</EKD00120>
                </EKD00000>`
    })
    .join('\n')

  let xml = templateXml.value

  xml = xml.replace(new RegExp('sakuseiDay="\\d{4}-\\d{2}-\\d{2}"', 'g'), `sakuseiDay="${dateStr}"`)
  xml = xml.replace(new RegExp('<gen:era>\\d+<\\/gen:era>', 'g'), `<gen:era>${era}</gen:era>`)
  xml = xml.replace(new RegExp('<gen:yy>\\d+<\\/gen:yy>', 'g'), `<gen:yy>${yy}</gen:yy>`)
  xml = xml.replace(new RegExp('<gen:mm>\\d+<\\/gen:mm>', 'g'), `<gen:mm>${mm}</gen:mm>`)

  xml = xml.replace(new RegExp('<LIA110[\\s\\S]*?<\\/LIA110>'), (section) => {
    let updated = section.replace(new RegExp('<EHD00000>[\\s\\S]*?<\\/EHD00000>', 'g'), '')
    updated = updated.replace(new RegExp('(<EHC00000>[\\s\\S]*?<\\/EHC00000>)'), `$1\n${ehdBlocks}`)
    return updated
  })

  xml = xml.replace(new RegExp('<LIA220[\\s\\S]*?<\\/LIA220>'), (section) => {
    let updated = section.replace(new RegExp('<EKD00000>[\\s\\S]*?<\\/EKD00000>', 'g'), '')
    updated = updated.replace(new RegExp('(<EKC00000>[\\s\\S]*?<\\/EKC00000>)'), `$1\n${ekdBlocks}`)
    return updated
  })

  return xml
}

function buildXmlFilename(taxType: string, taxYear: number, taxMonth: number) {
  const reiwa = taxYear >= 2019 ? `R${taxYear - 2018}年` : `${taxYear}年`
  if (taxType === 'yearly') {
    return `${reiwa}_納税申告.xtx`
  }
  return `${reiwa}${taxMonth}月_納税申告.xtx`
}

function downloadTextFile(filename: string, content: string, mime = 'application/xml') {
  const blob = new Blob([content], { type: mime })
  const url = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = filename
  document.body.appendChild(anchor)
  anchor.click()
  anchor.remove()
  URL.revokeObjectURL(url)
}

function normalizeReport(row: any): TaxReportRow {
  const files = Array.isArray(row.report_files) ? row.report_files : []
  const attachments = Array.isArray(row.attachment_files) ? row.attachment_files : []
  const breakdown = Array.isArray(row.volume_breakdown) ? row.volume_breakdown : []
  const normalizedBreakdown = breakdown
    .map((item: any, index: number) => ({
      key: item.key || `${row.id}-${index}`,
      move_type: item.move_type || item.moveType || item.doc_type || 'unknown',
      categoryId: item.categoryId || item.category_id || '',
      categoryCode: item.categoryCode || item.category_code || '',
      categoryName: item.categoryName || item.category_name || '—',
      abv: typeof item.abv === 'number' ? item.abv : item.abv ? Number(item.abv) : null,
      volume_l: typeof item.volume_l === 'number' ? item.volume_l : Number(item.volume_l || 0),
      tax_rate:
        typeof item.tax_rate === 'number'
          ? item.tax_rate
          : item.tax_rate
            ? Number(item.tax_rate)
            : item.taxRate
              ? Number(item.taxRate)
              : null,
    }))
    .filter((item: TaxVolumeItem) => item.categoryId || item.categoryName)
  if (normalizedBreakdown.length > 0 && normalizedBreakdown.every((item) => item.tax_rate == null)) {
    const totalVolume = normalizedBreakdown.reduce((sum, item) => sum + (item.volume_l || 0), 0)
    const fallbackRate = totalVolume > 0 ? Number(row.total_tax_amount ?? 0) / totalVolume : 0
    normalizedBreakdown.forEach((item) => {
      item.tax_rate = fallbackRate
    })
  }
  return {
    id: row.id,
    tax_type: row.tax_type || 'monthly',
    tax_year: Number(row.tax_year),
    tax_month: row.tax_month ? Number(row.tax_month) : 0,
    status: row.status,
    total_tax_amount: Number(row.total_tax_amount ?? 0),
    volume_breakdown: normalizedBreakdown,
    report_files: files.map((file: any) => String(file)),
    attachment_files: attachments.map((file: any) => String(file)),
    created_at: row.created_at ?? null,
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

async function loadCategories() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_category')
    .select('id, code, name')
    .eq('tenant_id', tenant)
    .order('code', { ascending: true })
  if (error) throw error
  categories.value = data ?? []
}

async function loadUoms() {
  const { data, error } = await supabase.from('mst_uom').select('id, code').order('code', { ascending: true })
  if (error) throw error
  uoms.value = data ?? []
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

function buildTaxRateIndex(rows: any[]) {
  const index: Record<string, TaxRateRecord[]> = {}
  rows.forEach((row) => {
    const categoryId = row.category
    if (!categoryId) return
    const entry: TaxRateRecord = {
      taxrate: Number(row.taxrate ?? 0),
      effectDate: row.effect_date ? new Date(row.effect_date) : null,
      expireDate: row.expire_date ? new Date(row.expire_date) : null,
    }
    if (!index[categoryId]) index[categoryId] = []
    index[categoryId].push(entry)
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
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('tax_beer')
    .select('category, taxrate, effect_date, expire_date')
    .eq('tenant_id', tenant)
  if (error) throw error
  buildTaxRateIndex(data ?? [])
}

function applicableTaxRate(categoryId: string | null | undefined, dateStr: string | null | undefined) {
  if (!categoryId) return 0
  const records = taxRateIndex.value[categoryId]
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
    case 'gal_us':
      return size * 3.78541
    default:
      return size
  }
}

function resolvePackageSizeLiters(row: PackageRow) {
  if (row.package_size_l != null) {
    const direct = Number(row.package_size_l)
    if (!Number.isNaN(direct) && direct > 0) return direct
  }
  const size = row.package?.size != null ? Number(row.package.size) : null
  if (size == null || Number.isNaN(size)) return null
  const uomCode = row.package?.uom_id ? uomLookup.value.get(row.package.uom_id) : null
  return convertToLiters(size, uomCode)
}

const categoryLookup = computed(() => {
  const map = new Map<string, CategoryRow>()
  categories.value.forEach((row) => map.set(row.id, row))
  return map
})

const uomLookup = computed(() => {
  const map = new Map<string, string>()
  uoms.value.forEach((row) => map.set(row.id, row.code ?? ''))
  return map
})

async function generateReportForPeriod(taxType: string, year: number, month: number) {
  try {
    generating.value = true
    reportBreakdown.value = []
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
      .in('doc_type', MOVEMENT_DOC_TYPES as unknown as string[])
      .gte('movement_at', startDate)
      .lt('movement_at', endDate)

    if (headerError) throw headerError
    const headers = (movementHeaders ?? []) as MovementHeader[]
    if (headers.length === 0) {
      reportBreakdown.value = []
      totalTaxAmount.value = 0
      return
    }

    const headerMap = new Map(headers.map((row) => [row.id, { movementAt: row.movement_at, docType: row.doc_type }]))
    const movementIds = headers.map((row) => row.id)

    const { data: movementLines, error: lineError } = await supabase
      .from('inv_movement_lines')
      .select('movement_id, package_id, lot_id, qty, uom_id, meta')
      .in('movement_id', movementIds)

    if (lineError) throw lineError

    const lines = (movementLines ?? []).filter((row: any) => row.package_id || row.lot_id) as MovementLine[]
    if (lines.length === 0) {
      reportBreakdown.value = []
      totalTaxAmount.value = 0
      return
    }

    const packageIds = Array.from(new Set(lines.map((line) => line.package_id).filter(Boolean))) as string[]
    const lotIdsFromLines = Array.from(new Set(lines.map((line) => line.lot_id).filter(Boolean))) as string[]

    const packageMap = new Map<string, PackageRow>()
    if (packageIds.length > 0) {
      const { data: packages, error: packageError } = await supabase
        .from('pkg_packages')
        .select(
          'id, lot_id, fill_at, package_qty, package_size_l, lot:lot_id ( id, actual_abv, recipe:rcp_recipes ( id, name, category, target_abv ) ), package:package_id ( id, size, uom_id )'
        )
        .eq('tenant_id', tenant)
        .in('id', packageIds)
      if (packageError) throw packageError
      ;(packages ?? []).forEach((row: any) => packageMap.set(row.id, row as PackageRow))
    }

    const lotIdsFromPackages = Array.from(
      new Set(Array.from(packageMap.values()).map((row) => row.lot_id).filter(Boolean))
    ) as string[]
    const lotIds = Array.from(new Set([...lotIdsFromLines, ...lotIdsFromPackages]))

    const lotMap = new Map<string, { categoryId: string | null; categoryName: string; abv: number | null }>()
    if (lotIds.length > 0) {
      const { data: lots, error: lotError } = await supabase
        .from('prd_lots')
        .select('id, actual_abv, recipe:recipe_id ( id, category, target_abv )')
        .eq('tenant_id', tenant)
        .in('id', lotIds)
      if (lotError) throw lotError
      ;(lots ?? []).forEach((row: any) => {
        const categoryId = row.recipe?.category ?? null
        const category = categoryId ? categoryLookup.value.get(categoryId) : null
        lotMap.set(row.id, {
          categoryId,
          categoryName: category?.name || category?.code || categoryId || '—',
          abv: row.actual_abv ?? row.recipe?.target_abv ?? null,
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
      const lotId = line.lot_id ?? packageRow?.lot_id ?? packageRow?.lot?.id ?? null
      const lotInfo = lotId ? lotMap.get(lotId) : undefined

      const categoryId = packageRow?.lot?.recipe?.category ?? lotInfo?.categoryId ?? null
      if (!categoryId) return
      const category = categoryLookup.value.get(categoryId)
      const categoryName = category?.name || category?.code || categoryId
      const categoryCode = category?.code ?? ''
      const abv = packageRow?.lot?.actual_abv ?? packageRow?.lot?.recipe?.target_abv ?? lotInfo?.abv ?? null

      const uomCode = line.uom_id ? uomLookup.value.get(line.uom_id) : null
      let volume = line.qty != null ? convertToLiters(Number(line.qty), uomCode) : null

      if (!volume || volume <= 0) {
        const unitSize = packageRow ? resolvePackageSizeLiters(packageRow) : null
        const pkgQty = Number(line.meta?.package_qty ?? packageRow?.package_qty ?? 0)
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

      const taxRate = applicableTaxRate(categoryId, movementAt)
      totalTax += volume * taxRate
      taxTotalMap.set(key, (taxTotalMap.get(key) ?? 0) + volume * taxRate)
    })

    breakdownMap.forEach((item, key) => {
      const taxTotal = taxTotalMap.get(key) ?? 0
      item.tax_rate = item.volume_l > 0 ? taxTotal / item.volume_l : 0
    })

    reportBreakdown.value = Array.from(breakdownMap.values()).sort((a, b) => {
      if (a.categoryName !== b.categoryName) return a.categoryName.localeCompare(b.categoryName)
      return (a.abv ?? 0) - (b.abv ?? 0)
    })
    totalTaxAmount.value = totalTax
    updateDisposeBreakdown()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    generating.value = false
  }
}

async function fetchReports() {
  try {
    loading.value = true
    const tenant = await ensureTenant()
    let query = supabase
      .from(TABLE)
      .select('id, tax_type, tax_year, tax_month, status, total_tax_amount, volume_breakdown, report_files, attachment_files, created_at')
      .eq('tenant_id', tenant)
      .order('tax_year', { ascending: false })
      .order('tax_month', { ascending: false })

    if (filters.taxType) query = query.eq('tax_type', filters.taxType)
    if (filters.taxYear) query = query.eq('tax_year', Number(filters.taxYear))
    if (filters.taxMonth) query = query.eq('tax_month', Number(filters.taxMonth))
    if (filters.status) query = query.eq('status', filters.status)

    const { data, error } = await query
    if (error) throw error

    rows.value = (data ?? []).map(normalizeReport)
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    loading.value = false
  }
}

function resetForm() {
  form.id = ''
  form.tax_type = (filters.taxType as string) || 'monthly'
  form.tax_year = filters.taxYear ? Number(filters.taxYear) : new Date().getFullYear()
  form.tax_month = filters.taxMonth ? Number(filters.taxMonth) : new Date().getMonth() + 1
  if (form.tax_type === 'yearly') form.tax_month = 12
  form.status = 'draft'
  form.report_files = ''
  form.attachment_files = ''
  reportBreakdown.value = []
  disposeBreakdown.value = []
  totalTaxAmount.value = 0
  if (summaryXmlUrl.value) URL.revokeObjectURL(summaryXmlUrl.value)
  if (disposeXmlUrl.value) URL.revokeObjectURL(disposeXmlUrl.value)
  summaryXmlUrl.value = ''
  summaryXmlName.value = ''
  disposeXmlUrl.value = ''
  disposeXmlName.value = ''
  Object.keys(errors).forEach((key) => delete errors[key])
}

async function openCreate() {
  editing.value = false
  promptForm.tax_type = (filters.taxType as string) || 'monthly'
  promptForm.tax_year = filters.taxYear ? Number(filters.taxYear) : new Date().getFullYear()
  promptForm.tax_month = filters.taxMonth ? Number(filters.taxMonth) : new Date().getMonth() + 1
  showCreatePrompt.value = true
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
  editing.value = false
  resetForm()
  form.tax_type = promptForm.tax_type
  form.tax_year = promptForm.tax_year
  form.tax_month = promptForm.tax_type === 'monthly' ? promptForm.tax_month : 12
  form.status = 'draft'
  showModal.value = true
  showCreatePrompt.value = false
  await generateReportForPeriod(form.tax_type, form.tax_year, form.tax_month)
}

function closeModal() {
  showModal.value = false
}

async function openEdit(row: TaxReportRow) {
  editing.value = true
  resetForm()
  form.id = row.id
  form.tax_type = row.tax_type || 'monthly'
  form.tax_year = row.tax_year
  form.tax_month = row.tax_month
  form.status = row.status
  form.report_files = row.report_files.join('\n')
  form.attachment_files = row.attachment_files.join('\n')
  reportBreakdown.value = row.volume_breakdown
  totalTaxAmount.value = row.total_tax_amount
  updateDisposeBreakdown()
  showModal.value = true
}

async function handlePeriodChange() {
  if (editing.value) return
  if (!form.tax_year) return
  if (form.tax_type === 'monthly' && !form.tax_month) return
  if (form.tax_type === 'yearly') {
    form.tax_month = 12
  }
  await generateReportForPeriod(form.tax_type, form.tax_year, form.tax_month)
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
    if (form.tax_type === 'yearly') {
      form.tax_month = 12
    }
    if (isNew) {
      const filename = buildXmlFilename(form.tax_type, form.tax_year, form.tax_month)
      const fileSet = new Set(parseFileList(form.report_files))
      if (!fileSet.has(filename)) {
        try {
          const xml = buildXmlPayload({
            taxType: form.tax_type,
            taxYear: form.tax_year,
            taxMonth: form.tax_month,
            status,
            totalTax: totalTaxAmount.value,
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
      volume_breakdown: reportBreakdown.value,
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

    showModal.value = false
    await fetchReports()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

function buildDisposeXmlFilename(taxType: string, taxYear: number, taxMonth: number) {
  const base = buildXmlFilename(taxType, taxYear, taxMonth)
  return base.replace('.xtx', '_廃棄.xtx')
}

function createXmlForSummary() {
  if (reportBreakdown.value.length === 0) {
    toast.info(t('taxReport.emptyBreakdown'))
    return
  }
  const filename = buildXmlFilename(form.tax_type, form.tax_year, form.tax_month)
  let xml = ''
  try {
    xml = buildXmlPayload({
      taxType: form.tax_type,
      taxYear: form.tax_year,
      taxMonth: form.tax_month,
      status: editing.value ? form.status : 'draft',
      totalTax: totalTaxAmount.value,
      breakdown: reportBreakdown.value,
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
  let xml = ''
  try {
    xml = buildXmlPayload({
      taxType: form.tax_type,
      taxYear: form.tax_year,
      taxMonth: form.tax_month,
      status: editing.value ? form.status : 'draft',
      totalTax: totalTaxAmount.value,
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

async function createXmlForRow(row: TaxReportRow) {
  if (!row.volume_breakdown.length) {
    toast.info(t('taxReport.emptyBreakdown'))
    return
  }
  const filename = buildXmlFilename(row.tax_type, row.tax_year, row.tax_month)
  let xml = ''
  try {
    xml = buildXmlPayload({
      taxType: row.tax_type,
      taxYear: row.tax_year,
      taxMonth: row.tax_month,
      status: row.status,
      totalTax: row.total_tax_amount,
      breakdown: row.volume_breakdown,
    })
    downloadTextFile(filename, xml)
  } catch (err) {
    toast.error(t('taxReport.templateMissing'))
    console.error(err)
    return
  }

  if (row.report_files.includes(filename)) return
  try {
    const tenant = await ensureTenant()
    const updatedFiles = [...row.report_files, filename]
    const { error } = await supabase
      .from(TABLE)
      .update({ report_files: updatedFiles })
      .eq('id', row.id)
      .eq('tenant_id', tenant)
    if (error) throw error
    await fetchReports()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
}

onMounted(async () => {
  try {
    await ensureTenant()
    await Promise.all([loadCategories(), loadUoms(), loadTaxRates(), loadTemplate()])
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
  { deep: true }
)

watch(
  () => filters.taxType,
  (value) => {
    if (value === 'yearly') filters.taxMonth = ''
  }
)

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
  const updated = parseFileList(form.attachment_files).filter((name) => name !== file)
  form.attachment_files = updated.join('\n')
}
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
