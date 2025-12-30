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
        <form class="grid grid-cols-1 md:grid-cols-5 gap-3" @submit.prevent>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.filters.taxYear') }}</label>
            <select v-model="filters.taxYear" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="year in yearOptions" :key="year" :value="String(year)">{{ year }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.filters.taxMonth') }}</label>
            <select v-model="filters.taxMonth" class="w-full h-[40px] border rounded px-3 bg-white">
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

      <section class="overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200 text-sm">
          <thead class="bg-gray-50 text-xs uppercase text-gray-600">
            <tr>
              <th class="px-3 py-2 text-left">{{ t('taxReport.table.taxYear') }}</th>
              <th class="px-3 py-2 text-left">{{ t('taxReport.table.taxMonth') }}</th>
              <th class="px-3 py-2 text-left">{{ t('taxReport.table.productionVolume') }}</th>
              <th class="px-3 py-2 text-right">{{ t('taxReport.table.totalTax') }}</th>
              <th class="px-3 py-2 text-left">{{ t('taxReport.table.files') }}</th>
              <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in rows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2">
                <div class="font-medium text-gray-900">{{ row.tax_year }}</div>
                <div class="text-xs text-gray-500">{{ statusLabel(row.status) }}</div>
              </td>
              <td class="px-3 py-2 text-sm text-gray-700">{{ row.tax_month || '—' }}</td>
              <td class="px-3 py-2">
                <div v-if="row.volume_breakdown.length" class="space-y-1">
                  <div v-for="item in row.volume_breakdown" :key="item.key" class="text-xs text-gray-700">
                    {{ breakdownLabel(item) }}
                  </div>
                </div>
                <span v-else class="text-xs text-gray-400">—</span>
              </td>
              <td class="px-3 py-2 text-right font-semibold text-gray-900">{{ formatCurrency(row.total_tax_amount) }}</td>
              <td class="px-3 py-2">
                <div class="space-y-2 text-xs">
                  <div>
                    <div class="text-gray-500">{{ t('taxReport.table.xmlFiles') }}</div>
                    <div v-if="row.report_files.length" class="space-y-1">
                      <div v-for="file in row.report_files" :key="file" class="text-blue-600">
                        {{ file }}
                      </div>
                    </div>
                    <div v-else class="text-gray-400">—</div>
                  </div>
                  <div>
                    <div class="text-gray-500">{{ t('taxReport.table.attachments') }}</div>
                    <div v-if="row.attachment_files.length" class="space-y-1">
                      <div v-for="file in row.attachment_files" :key="file" class="text-blue-600">
                        {{ file }}
                      </div>
                    </div>
                    <div v-else class="text-gray-400">—</div>
                  </div>
                </div>
              </td>
              <td class="px-3 py-2 space-x-2">
                <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="createXmlForRow(row)">
                  {{ t('taxReport.actions.createXml') }}
                </button>
                <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openEdit(row)">
                  {{ t('common.edit') }}
                </button>
              </td>
            </tr>
            <tr v-if="!loading && rows.length === 0">
              <td colspan="6" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-3xl bg-white rounded-xl shadow-lg border">
          <header class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ editing ? t('taxReport.modal.editTitle') : t('taxReport.modal.newTitle') }}</h3>
          </header>
          <section class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
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
              <div>
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
              <div class="md:col-span-3">
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.form.totalTax') }}</label>
                <div class="h-[40px] flex items-center border rounded px-3 text-sm text-gray-700 bg-gray-50">
                  {{ formatCurrency(totalTaxAmount) }}
                </div>
              </div>
              <div class="md:col-span-3">
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.form.breakdown') }}</label>
                <div class="border rounded p-3 bg-gray-50">
                  <div v-if="reportBreakdown.length" class="space-y-1 text-sm text-gray-700">
                    <div v-for="item in reportBreakdown" :key="item.key">
                      {{ breakdownLabel(item) }}
                    </div>
                  </div>
                  <div v-else class="text-xs text-gray-400">{{ t('taxReport.emptyBreakdown') }}</div>
                </div>
                <p v-if="errors.breakdown" class="text-xs text-red-600 mt-1">{{ errors.breakdown }}</p>
              </div>
              <div class="md:col-span-3">
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.form.xmlFiles') }}</label>
                <textarea
                  v-model.trim="form.report_files"
                  rows="3"
                  class="w-full border rounded px-3 py-2"
                  :placeholder="t('taxReport.form.xmlPlaceholder')"
                ></textarea>
              </div>
              <div class="md:col-span-3">
                <label class="block text-sm text-gray-600 mb-1">{{ t('taxReport.form.attachments') }}</label>
                <textarea
                  v-model.trim="form.attachment_files"
                  rows="3"
                  class="w-full border rounded px-3 py-2"
                  :placeholder="t('taxReport.form.attachmentsPlaceholder')"
                ></textarea>
              </div>
            </div>
          </section>
          <footer class="px-4 py-3 border-t flex items-center justify-between">
            <div class="text-xs text-gray-500">
              <span v-if="generating">{{ t('taxReport.generating') }}</span>
            </div>
            <div class="flex items-center gap-2">
              <button
                class="px-3 py-2 rounded border hover:bg-gray-50"
                :disabled="generating"
                @click="createXmlForForm"
              >
                {{ t('taxReport.actions.createXml') }}
              </button>
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
  categoryId: string
  categoryName: string
  abv: number | null
  volume_l: number
}

interface TaxReportRow {
  id: string
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
const MOVEMENT_DOC_TYPES = ['sale', 'tax_transfer', 'transfer', 'waste'] as const

const { t, locale } = useI18n()
const pageTitle = computed(() => t('taxReport.title'))

const rows = ref<TaxReportRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const editing = ref(false)
const generating = ref(false)

const filters = reactive({ taxYear: '', taxMonth: '', status: '' })

const categories = ref<CategoryRow[]>([])
const uoms = ref<Array<{ id: string; code: string | null }>>([])
const taxRateIndex = ref<Record<string, TaxRateRecord[]>>({})
const tenantId = ref<string | null>(null)

const form = reactive({
  id: '',
  tax_year: new Date().getFullYear(),
  tax_month: new Date().getMonth() + 1,
  status: 'draft',
  report_files: '',
  attachment_files: '',
})

const errors = reactive<Record<string, string>>({})
const reportBreakdown = ref<TaxVolumeItem[]>([])
const totalTaxAmount = ref(0)

const statusOptions = STATUS_OPTIONS

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
  return `${item.categoryName} (${formatAbv(item.abv)}): ${formatVolume(item.volume_l)}`
}

function parseFileList(text: string) {
  return text
    .split(/[\n,]/)
    .map((entry) => entry.trim())
    .filter(Boolean)
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
  taxYear: number
  taxMonth: number
  status: string
  totalTax: number
  breakdown: TaxVolumeItem[]
}) {
  const items = row.breakdown
    .map(
      (item) => `    <item>
      <category>${xmlEscape(item.categoryName)}</category>
      <abv>${item.abv ?? ''}</abv>
      <volumeLiters>${item.volume_l.toFixed(3)}</volumeLiters>
    </item>`
    )
    .join('\n')
  return `<?xml version="1.0" encoding="UTF-8"?>
<taxReport>
  <taxYear>${row.taxYear}</taxYear>
  <taxMonth>${String(row.taxMonth).padStart(2, '0')}</taxMonth>
  <status>${xmlEscape(row.status)}</status>
  <totalTaxAmount>${row.totalTax.toFixed(2)}</totalTaxAmount>
  <productionVolumes>
${items}
  </productionVolumes>
</taxReport>`
}

function buildXmlFilename(taxYear: number, taxMonth: number) {
  return `tax_report_${taxYear}_${String(taxMonth).padStart(2, '0')}.xml`
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
      categoryId: item.categoryId || item.category_id || '',
      categoryName: item.categoryName || item.category_name || '—',
      abv: typeof item.abv === 'number' ? item.abv : item.abv ? Number(item.abv) : null,
      volume_l: typeof item.volume_l === 'number' ? item.volume_l : Number(item.volume_l || 0),
    }))
    .filter((item: TaxVolumeItem) => item.categoryId || item.categoryName)
  return {
    id: row.id,
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

async function generateReportForPeriod(year: number, month: number) {
  try {
    generating.value = true
    reportBreakdown.value = []
    totalTaxAmount.value = 0

    const tenant = await ensureTenant()
    const start = new Date(year, month - 1, 1)
    const end = new Date(year, month, 1)
    const startDate = `${start.getFullYear()}-${String(start.getMonth() + 1).padStart(2, '0')}-01`
    const endDate = `${end.getFullYear()}-${String(end.getMonth() + 1).padStart(2, '0')}-01`

    const { data: movementHeaders, error: headerError } = await supabase
      .from('inv_movements')
      .select('id, movement_at')
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

    const headerMap = new Map(headers.map((row) => [row.id, row.movement_at]))
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
    let totalTax = 0

    lines.forEach((line) => {
      const movementAt = headerMap.get(line.movement_id)
      const packageRow = line.package_id ? packageMap.get(line.package_id) : undefined
      const lotId = line.lot_id ?? packageRow?.lot_id ?? packageRow?.lot?.id ?? null
      const lotInfo = lotId ? lotMap.get(lotId) : undefined

      const categoryId = packageRow?.lot?.recipe?.category ?? lotInfo?.categoryId ?? null
      if (!categoryId) return
      const category = categoryLookup.value.get(categoryId)
      const categoryName = category?.name || category?.code || categoryId
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

      const key = `${categoryId}-${abv ?? 'na'}`
      const existing = breakdownMap.get(key)
      if (existing) {
        existing.volume_l += volume
      } else {
        breakdownMap.set(key, {
          key,
          categoryId,
          categoryName,
          abv: abv != null ? Number(abv) : null,
          volume_l: volume,
        })
      }

      const taxRate = applicableTaxRate(categoryId, movementAt)
      totalTax += volume * taxRate
    })

    reportBreakdown.value = Array.from(breakdownMap.values()).sort((a, b) => {
      if (a.categoryName !== b.categoryName) return a.categoryName.localeCompare(b.categoryName)
      return (a.abv ?? 0) - (b.abv ?? 0)
    })
    totalTaxAmount.value = totalTax
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
      .select('id, tax_year, tax_month, status, total_tax_amount, volume_breakdown, report_files, attachment_files, created_at')
      .eq('tenant_id', tenant)
      .order('tax_year', { ascending: false })
      .order('tax_month', { ascending: false })

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
  form.tax_year = filters.taxYear ? Number(filters.taxYear) : new Date().getFullYear()
  form.tax_month = filters.taxMonth ? Number(filters.taxMonth) : new Date().getMonth() + 1
  form.status = 'draft'
  form.report_files = ''
  form.attachment_files = ''
  reportBreakdown.value = []
  totalTaxAmount.value = 0
  Object.keys(errors).forEach((key) => delete errors[key])
}

async function openCreate() {
  if (!filters.taxYear || !filters.taxMonth) {
    toast.info(t('taxReport.selectTaxYear'))
  }
  editing.value = false
  resetForm()
  form.status = 'draft'
  showModal.value = true
  await generateReportForPeriod(form.tax_year, form.tax_month)
}

function closeModal() {
  showModal.value = false
}

async function openEdit(row: TaxReportRow) {
  editing.value = true
  resetForm()
  form.id = row.id
  form.tax_year = row.tax_year
  form.tax_month = row.tax_month
  form.status = row.status
  form.report_files = row.report_files.join('\n')
  form.attachment_files = row.attachment_files.join('\n')
  reportBreakdown.value = row.volume_breakdown
  totalTaxAmount.value = row.total_tax_amount
  showModal.value = true
}

async function handlePeriodChange() {
  if (editing.value) return
  if (!form.tax_year || !form.tax_month) return
  await generateReportForPeriod(form.tax_year, form.tax_month)
}

function validateForm() {
  Object.keys(errors).forEach((key) => delete errors[key])
  if (!form.tax_year) errors.tax_year = t('taxReport.errors.taxYearRequired')
  if (!form.tax_month) errors.tax_month = t('taxReport.errors.taxMonthRequired')
  if (!form.status) errors.status = t('taxReport.errors.statusRequired')
  if (reportBreakdown.value.length === 0) errors.breakdown = t('taxReport.errors.breakdownRequired')
  return Object.keys(errors).length === 0
}

async function saveReport() {
  if (!validateForm()) return
  try {
    saving.value = true
    const tenant = await ensureTenant()
    const status = editing.value ? form.status : 'draft'
    const payload = {
      tenant_id: tenant,
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

function createXmlForForm() {
  if (reportBreakdown.value.length === 0) {
    toast.info(t('taxReport.emptyBreakdown'))
    return
  }
  const filename = buildXmlFilename(form.tax_year, form.tax_month)
  const xml = buildXmlPayload({
    taxYear: form.tax_year,
    taxMonth: form.tax_month,
    status: editing.value ? form.status : 'draft',
    totalTax: totalTaxAmount.value,
    breakdown: reportBreakdown.value,
  })
  downloadTextFile(filename, xml)

  const files = new Set(parseFileList(form.report_files))
  files.add(filename)
  form.report_files = Array.from(files).join('\n')
}

async function createXmlForRow(row: TaxReportRow) {
  if (!row.volume_breakdown.length) {
    toast.info(t('taxReport.emptyBreakdown'))
    return
  }
  const filename = buildXmlFilename(row.tax_year, row.tax_month)
  const xml = buildXmlPayload({
    taxYear: row.tax_year,
    taxMonth: row.tax_month,
    status: row.status,
    totalTax: row.total_tax_amount,
    breakdown: row.volume_breakdown,
  })
  downloadTextFile(filename, xml)

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
    await Promise.all([loadCategories(), loadUoms(), loadTaxRates()])
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
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
