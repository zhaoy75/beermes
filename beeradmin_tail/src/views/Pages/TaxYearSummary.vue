<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <section class="space-y-6">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between bg-white border border-gray-200 rounded-xl p-4 shadow-sm">
        <div>
          <h1 class="text-lg font-semibold text-gray-900">{{ t('taxYearSummary.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('taxYearSummary.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <label class="flex items-center gap-2 text-sm text-gray-700">
            <span>{{ t('taxYearSummary.yearLabel') }}</span>
            <select v-model.number="selectedYear" class="h-[40px] border rounded px-3 bg-white">
              <option v-for="option in yearOptions" :key="option" :value="option">
                {{ option }}
              </option>
            </select>
          </label>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-50"
            :disabled="loading"
            @click="loadSummary"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <div v-if="errorMessage" class="p-3 border border-red-200 bg-red-50 text-red-700 rounded-lg">{{ errorMessage }}</div>

      <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
        <header class="flex items-center justify-between mb-4">
          <h2 class="text-base font-semibold text-gray-900">{{ t('taxYearSummary.summaryHeading') }}</h2>
          <span v-if="loading" class="text-sm text-gray-500">{{ t('taxYearSummary.loading') }}</span>
        </header>
        <div v-if="categorySummaries.length > 0" class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
          <article
            v-for="item in categorySummaries"
            :key="item.categoryId"
            class="border border-gray-200 rounded-lg p-4 bg-white shadow-sm"
          >
            <header class="flex items-center justify-between">
              <h3 class="text-sm font-medium text-gray-700">{{ item.categoryName }}</h3>
              <span class="text-xs text-gray-500">{{ selectedYear }}</span>
            </header>
            <dl class="mt-3 space-y-1 text-sm">
              <div class="flex justify-between text-gray-600">
                <dt>{{ t('taxYearSummary.volume') }}</dt>
                <dd class="font-semibold text-gray-900">{{ formatVolume(item.totalVolume) }}</dd>
              </div>
              <div class="flex justify-between text-gray-600">
                <dt>{{ t('taxYearSummary.taxAmount') }}</dt>
                <dd class="font-semibold text-gray-900">{{ formatCurrency(item.totalTax) }}</dd>
              </div>
            </dl>
          </article>
        </div>
        <div v-else class="text-sm text-gray-500">{{ loading ? t('taxYearSummary.loading') : t('taxYearSummary.noData') }}</div>
      </section>

      <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
        <header class="flex items-center justify-between mb-4">
          <h2 class="text-base font-semibold text-gray-900">{{ t('taxYearSummary.monthlyChartTitle') }}</h2>
        </header>
        <div class="h-72">
          <canvas ref="chartCanvas"></canvas>
        </div>
      </section>

      <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
        <header class="flex items-center justify-between mb-4">
          <h2 class="text-base font-semibold text-gray-900">{{ t('taxYearSummary.batchesSectionTitle') }}</h2>
        </header>
        <div v-if="batchBreakdown.length === 0" class="text-sm text-gray-500">
          {{ loading ? t('taxYearSummary.loading') : t('taxYearSummary.noData') }}
        </div>
        <div v-else class="space-y-4">
          <article v-for="month in batchBreakdown" :key="month.month" class="border border-gray-200 rounded-lg">
            <header class="flex items-center justify-between px-4 py-3 border-b border-gray-100 bg-gray-50">
              <div class="text-sm font-semibold text-gray-800">{{ month.label }}</div>
              <div class="flex items-center gap-4 text-sm text-gray-600">
                <span>{{ t('taxYearSummary.volumeShort') }}: <strong class="text-gray-900">{{ formatVolume(month.subtotalVolume) }}</strong></span>
                <span>{{ t('taxYearSummary.taxShort') }}: <strong class="text-gray-900">{{ formatCurrency(month.subtotalTax) }}</strong></span>
              </div>
            </header>
            <div class="overflow-x-auto">
              <table class="min-w-full text-sm">
                <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
                  <tr>
                    <th class="px-3 py-2 text-left">{{ t('taxYearSummary.batch') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxYearSummary.category') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxYearSummary.fillDate') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('taxYearSummary.volumeShort') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('taxYearSummary.taxShort') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="row in month.batches" :key="row.key" class="hover:bg-gray-50">
                    <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.batchCode }}</td>
                    <td class="px-3 py-2 text-gray-700">{{ row.categoryName }}</td>
                    <td class="px-3 py-2 text-gray-600">{{ formatDate(row.fillDate) }}</td>
                    <td class="px-3 py-2 text-right font-semibold text-gray-800">{{ formatVolume(row.totalVolume) }}</td>
                    <td class="px-3 py-2 text-right font-semibold text-gray-800">{{ formatCurrency(row.totalTax) }}</td>
                  </tr>
                  <tr class="bg-gray-50 text-gray-700 font-semibold">
                    <td class="px-3 py-2" colspan="3">{{ t('taxYearSummary.monthTotal') }}</td>
                    <td class="px-3 py-2 text-right">{{ formatVolume(month.subtotalVolume) }}</td>
                    <td class="px-3 py-2 text-right">{{ formatCurrency(month.subtotalTax) }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </article>
        </div>
      </section>
    </section>
  </AdminLayout>
</template>

<script setup lang="ts">
import { Chart, registerables } from 'chart.js'
import { computed, nextTick, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'

Chart.register(...registerables)

const { t, locale } = useI18n()
const pageTitle = computed(() => t('taxYearSummary.title'))

const currentYear = new Date().getFullYear()
const yearOptions = computed(() => {
  const years: number[] = []
  for (let offset = 0; offset < 6; offset += 1) {
    years.push(currentYear - offset)
  }
  return years
})
const selectedYear = ref(currentYear)

const loading = ref(false)
const errorMessage = ref('')
const tenantId = ref<string | null>(null)

interface CategoryRecord {
  id: string
  code: string
  name: string | null
}

interface TaxRateRecord {
  category: string
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
  meta: Record<string, any> | null
}

interface PackageCategoryInfo {
  id: string
  unit_size_l: number | null
}

interface BatchRow {
  id: string
  batch_code: string | null
  recipe_id: string | null
}

interface RecipeRow {
  id: string
  category: string | null
}

interface CategorySummary {
  categoryId: string
  categoryName: string
  totalVolume: number
  totalTax: number
}

interface MonthBatchRow {
  key: string
  month: number
  batchId: string
  batchCode: string
  categoryId: string
  categoryName: string
  fillDate: string
  totalVolume: number
  totalTax: number
}

interface MonthGroup {
  month: number
  label: string
  subtotalVolume: number
  subtotalTax: number
  batches: MonthBatchRow[]
}

const categories = ref<CategoryRecord[]>([])
const uoms = ref<Array<{ id: string; code: string }>>([])
const categorySummaries = ref<CategorySummary[]>([])
const monthlySeries = ref<Array<{ month: number; volume: number; tax: number }>>([])
const batchBreakdown = ref<MonthGroup[]>([])

const chartCanvas = ref<HTMLCanvasElement | null>(null)
let chartInstance: Chart | null = null

const categoryLookup = computed(() => {
  const map = new Map<string, CategoryRecord>()
  categories.value.forEach((row) => map.set(row.id, row))
  return map
})

const uomLookup = computed(() => {
  const map = new Map<string, string>()
  uoms.value.forEach((row) => map.set(row.id, row.code))
  return map
})

const monthFormatter = computed(() => new Intl.DateTimeFormat(locale.value, { month: 'short' }))

function monthLabel(monthIndex: number) {
  return monthFormatter.value.format(new Date(selectedYear.value, monthIndex, 1))
}

const volumeFormatter = computed(() =>
  new Intl.NumberFormat(locale.value, { maximumFractionDigits: 2, minimumFractionDigits: 0 }),
)
const currencyFormatter = computed(() =>
  new Intl.NumberFormat(locale.value, { style: 'currency', currency: 'JPY', maximumFractionDigits: 0 }),
)

function formatVolume(value: number) {
  if (!Number.isFinite(value)) return '—'
  return `${volumeFormatter.value.format(value)} L`
}

function formatCurrency(value: number) {
  if (!Number.isFinite(value)) return '—'
  try {
    return currencyFormatter.value.format(value)
  } catch {
    return `¥${Math.round(value).toLocaleString()}`
  }
}

function formatDate(value: string) {
  if (!value) return '—'
  try {
    return new Intl.DateTimeFormat(locale.value).format(new Date(value))
  } catch {
    return value
  }
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved for current session')
  tenantId.value = id
  return id
}

async function loadCategories() {
  try {
    const tenant = await ensureTenant()
    const { data, error } = await supabase
      .from('mst_category')
      .select('id, code, name')
      .eq('tenant_id', tenant)
      .order('name', { ascending: true, nullsFirst: false })
    if (error) throw error
    categories.value = data ?? []
  } catch (err) {
    console.warn('Failed to load categories', err)
  }
}

const taxRateIndex = ref<Record<string, TaxRateRecord[]>>({})

function buildTaxRateIndex(rows: any[]) {
  const index: Record<string, TaxRateRecord[]> = {}
  rows.forEach((row) => {
    if (!row.category) return
    const effectDate = row.effect_date ? new Date(row.effect_date) : null
    const expireDate = row.expire_date ? new Date(row.expire_date) : null
    const entry: TaxRateRecord = {
      category: row.category,
      taxrate: Number(row.taxrate ?? 0) || 0,
      effectDate,
      expireDate,
    }
    if (!index[entry.category]) index[entry.category] = []
    index[entry.category].push(entry)
  })

  Object.keys(index).forEach((key) => {
    index[key].sort((a, b) => {
      const aTime = a.effectDate ? a.effectDate.getTime() : -Infinity
      const bTime = b.effectDate ? b.effectDate.getTime() : -Infinity
      return aTime - bTime
    })
  })
  taxRateIndex.value = index
}

async function loadTaxRates() {
  try {
    const tenant = await ensureTenant()
    const { data, error } = await supabase
      .from('tax_beer')
      .select('category, taxrate, effect_date, expire_date')
      .eq('tenant_id', tenant)
    if (error) throw error
    buildTaxRateIndex(data ?? [])
  } catch (err) {
    console.warn('Failed to load tax rates', err)
    taxRateIndex.value = {}
  }
}

async function loadUoms() {
  try {
    const { data, error } = await supabase
      .from('mst_uom')
      .select('id, code')
      .order('code', { ascending: true })
    if (error) throw error
    uoms.value = data ?? []
  } catch (err) {
    console.warn('Failed to load UOM codes', err)
    uoms.value = []
  }
}

function convertToLiters(size: number | null | undefined, uomCode: string | null | undefined) {
  if (size == null || Number.isNaN(Number(size))) return null
  const numeric = Number(size)
  switch (uomCode) {
    case 'L':
    case null:
    case undefined:
      return numeric
    case 'mL':
      return numeric / 1000
    case 'gal_us':
      return numeric * 3.78541
    default:
      return numeric
  }
}

function toNumber(value: any): number | null {
  if (value == null || value === '') return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function resolvePackageSizeLiters(row: PackageCategoryInfo | undefined) {
  return row?.unit_size_l ?? null
}

function resolveLineVolume(line: MovementLine, packageRow: PackageCategoryInfo | undefined) {
  const qty = toNumber(line.qty)
  const uomCode = line.uom_id ? uomLookup.value.get(line.uom_id) : null
  let volume = qty != null ? convertToLiters(qty, uomCode) : null

  if (!volume || volume <= 0) {
    const pkgQty = toNumber(line.meta?.package_qty)
    const unitVolume = toNumber(line.meta?.unit_volume_l) ?? resolvePackageSizeLiters(packageRow)
    if (pkgQty != null && unitVolume != null) {
      volume = pkgQty * unitVolume
    }
  }

  return volume
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
    if (record.effectDate && date < record.effectDate) {
      break
    }
  }
  if (candidate) return candidate.taxrate
  return records[records.length - 1]?.taxrate ?? 0
}

async function loadMovementLines(movementIds: string[]) {
  if (movementIds.length === 0) return [] as MovementLine[]
  const { data, error } = await supabase
    .from('inv_movement_lines')
    .select('movement_id, package_id, batch_id, qty, uom_id, meta')
    .in('movement_id', movementIds)
  if (error) throw error
  return (data ?? []).filter((row: any) => row.package_id || row.batch_id) as MovementLine[]
}

async function loadPackageCategories(packageIds: string[]) {
  const map = new Map<string, PackageCategoryInfo>()
  if (packageIds.length === 0) return map
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_beer_package_category')
    .select('id, size, uom_id')
    .eq('tenant_id', tenant)
    .in('id', packageIds)
  if (error) throw error
  ;(data ?? []).forEach((row: any) => {
    const uomCode = row.uom_id ? uomLookup.value.get(row.uom_id) : null
    const unitSize = convertToLiters(row.size, uomCode)
    map.set(row.id, { id: row.id, unit_size_l: unitSize })
  })
  return map
}

async function loadBatches(batchIds: string[]) {
  const map = new Map<string, BatchRow>()
  if (batchIds.length === 0) return map
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mes_batches')
    .select('id, batch_code, recipe_id')
    .eq('tenant_id', tenant)
    .in('id', batchIds)
  if (error) throw error
  ;(data ?? []).forEach((row: any) => map.set(row.id, row as BatchRow))
  return map
}

async function loadRecipes(recipeIds: string[]) {
  const map = new Map<string, RecipeRow>()
  if (recipeIds.length === 0) return map
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mes_recipes')
    .select('id, category')
    .eq('tenant_id', tenant)
    .in('id', recipeIds)
  if (error) throw error
  ;(data ?? []).forEach((row: any) => map.set(row.id, row as RecipeRow))
  return map
}

async function loadSummary() {
  try {
    loading.value = true
    errorMessage.value = ''
    const tenant = await ensureTenant()
    const startDate = `${selectedYear.value}-01-01`
    const endDate = `${selectedYear.value + 1}-01-01`

    const { data, error } = await supabase
      .from('inv_movements')
      .select('id, movement_at, doc_type')
      .eq('tenant_id', tenant)
      .eq('doc_type', 'production_receipt')
      .gte('movement_at', startDate)
      .lt('movement_at', endDate)

    if (error) throw error

    const headers = (data ?? []) as MovementHeader[]
    if (headers.length === 0) {
      resetSummary()
      return
    }

    const headerMap = new Map(headers.map((row) => [row.id, row]))
    const movementIds = headers.map((row) => row.id)
    const lines = await loadMovementLines(movementIds)

    if (lines.length === 0) {
      resetSummary()
      return
    }

    const packageIds = Array.from(new Set(lines.map((line) => line.package_id).filter(Boolean))) as string[]
    const packageMap = await loadPackageCategories(packageIds)
    const batchIds = Array.from(new Set(lines.map((line) => line.batch_id).filter(Boolean)))
    const batchMap = await loadBatches(batchIds)
    const recipeIds = Array.from(new Set(Array.from(batchMap.values()).map((row) => row.recipe_id).filter(Boolean))) as string[]
    const recipeMap = await loadRecipes(recipeIds)

    processMovementLines(lines, headerMap, packageMap, batchMap, recipeMap)
  } catch (err) {
    console.error(err)
    errorMessage.value = err instanceof Error ? err.message : String(err)
    resetSummary()
  } finally {
    loading.value = false
  }
}

function resetSummary() {
  categorySummaries.value = []
  monthlySeries.value = Array.from({ length: 12 }, (_, month) => ({ month, volume: 0, tax: 0 }))
  batchBreakdown.value = []
  updateChart()
}

function processMovementLines(
  rows: MovementLine[],
  headerMap: Map<string, MovementHeader>,
  packageMap: Map<string, PackageCategoryInfo>,
  batchMap: Map<string, BatchRow>,
  recipeMap: Map<string, RecipeRow>
) {
  const categoryTotals = new Map<string, { volume: number; tax: number }>()
  const monthlyTotals = Array.from({ length: 12 }, (_, month) => ({ month, volume: 0, tax: 0 }))
  const monthBatchMap = new Map<string, MonthBatchRow>()

  rows.forEach((row) => {
    const header = headerMap.get(row.movement_id)
    if (!header?.movement_at) return
    const movementAt = header.movement_at
    const movementDate = new Date(movementAt)
    if (Number.isNaN(movementDate.getTime())) return
    const monthIndex = movementDate.getMonth()

    const packageRow = row.package_id ? packageMap.get(row.package_id) : undefined
    const batchId = row.batch_id ?? null
    if (!batchId) return
    const batchInfo = batchMap.get(batchId)
    const recipe = batchInfo?.recipe_id ? recipeMap.get(batchInfo.recipe_id) : undefined
    const categoryId = recipe?.category ?? null
    if (!categoryId) return

    const volume = resolveLineVolume(row, packageRow)
    if (volume == null || volume <= 0) return

    const taxRate = applicableTaxRate(categoryId, movementAt)
    const taxAmount = volume * taxRate

    const categoryEntry = categoryTotals.get(categoryId) || { volume: 0, tax: 0 }
    categoryEntry.volume += volume
    categoryEntry.tax += taxAmount
    categoryTotals.set(categoryId, categoryEntry)

    monthlyTotals[monthIndex].volume += volume
    monthlyTotals[monthIndex].tax += taxAmount

    const key = `${monthIndex}-${batchId}`
    let batchEntry = monthBatchMap.get(key)
    if (!batchEntry) {
      batchEntry = {
        key,
        month: monthIndex,
        batchId,
        batchCode: batchInfo?.batch_code ?? batchId,
        categoryId,
        categoryName: categoryLookup.value.get(categoryId)?.name || categoryLookup.value.get(categoryId)?.code || categoryId,
        fillDate: movementAt,
        totalVolume: 0,
        totalTax: 0,
      }
      monthBatchMap.set(key, batchEntry)
    }
    batchEntry.totalVolume += volume
    batchEntry.totalTax += taxAmount
    if (movementDate < new Date(batchEntry.fillDate)) {
      batchEntry.fillDate = movementAt
    }
  })

  categorySummaries.value = Array.from(categoryTotals.entries()).map(([categoryId, totals]) => {
    const category = categoryLookup.value.get(categoryId)
    return {
      categoryId,
      categoryName: category?.name || category?.code || categoryId,
      totalVolume: totals.volume,
      totalTax: totals.tax,
    }
  }).sort((a, b) => a.categoryName.localeCompare(b.categoryName))

  monthlySeries.value = monthlyTotals

  const groups: MonthGroup[] = []
  for (let month = 0; month < 12; month += 1) {
    const batches = Array.from(monthBatchMap.values()).filter((row) => row.month === month)
    if (batches.length === 0) continue
    batches.sort((a, b) => new Date(a.fillDate).getTime() - new Date(b.fillDate).getTime() || a.batchCode.localeCompare(b.batchCode))
    const subtotalVolume = batches.reduce((sum, row) => sum + row.totalVolume, 0)
    const subtotalTax = batches.reduce((sum, row) => sum + row.totalTax, 0)
    groups.push({
      month,
      label: monthLabel(month),
      subtotalVolume,
      subtotalTax,
      batches,
    })
  }
  batchBreakdown.value = groups
  updateChart()
}

function updateChart() {
  nextTick(() => {
    const canvas = chartCanvas.value
    if (!canvas) return
    const ctx = canvas.getContext('2d')
    if (!ctx) return

    const labels = monthlySeries.value.map((entry) => monthLabel(entry.month))
    const volumes = monthlySeries.value.map((entry) => Number(entry.volume.toFixed(2)))
    const taxes = monthlySeries.value.map((entry) => Number(entry.tax.toFixed(0)))

    if (!chartInstance) {
      chartInstance = new Chart(ctx, {
        type: 'bar',
        data: {
          labels,
          datasets: [
            {
              label: t('taxYearSummary.volumeSeries'),
              data: volumes,
              backgroundColor: 'rgba(37, 99, 235, 0.5)',
              borderColor: 'rgba(37, 99, 235, 1)',
              borderWidth: 1,
              yAxisID: 'y',
            },
            {
              label: t('taxYearSummary.taxSeries'),
              data: taxes,
              type: 'line',
              borderColor: 'rgba(234, 179, 8, 1)',
              backgroundColor: 'rgba(250, 204, 21, 0.45)',
              borderWidth: 2,
              tension: 0.2,
              yAxisID: 'y1',
            },
          ],
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          interaction: { mode: 'index', intersect: false },
          scales: {
            y: {
              beginAtZero: true,
              title: { display: true, text: t('taxYearSummary.volumeSeries') },
            },
            y1: {
              position: 'right',
              beginAtZero: true,
              grid: { drawOnChartArea: false },
              title: { display: true, text: t('taxYearSummary.taxSeries') },
            },
          },
          plugins: {
            legend: { position: 'top' },
          },
        },
      })
  } else {
      chartInstance.data.labels = labels
      const volumeDataset = chartInstance.data.datasets[0] as any
      const taxDataset = chartInstance.data.datasets[1] as any
      volumeDataset.label = t('taxYearSummary.volumeSeries')
      volumeDataset.data = volumes
      taxDataset.label = t('taxYearSummary.taxSeries')
      taxDataset.data = taxes
      const opts = chartInstance.options as any
      if (opts.scales?.y?.title) opts.scales.y.title.text = t('taxYearSummary.volumeSeries')
      if (opts.scales?.y1?.title) opts.scales.y1.title.text = t('taxYearSummary.taxSeries')
      chartInstance.update()
    }
  })
}

watch(locale, () => {
  batchBreakdown.value = batchBreakdown.value.map((group) => ({
    ...group,
    label: monthLabel(group.month),
  }))
  updateChart()
})

watch(selectedYear, async (newVal, oldVal) => {
  if (newVal !== oldVal) await loadSummary()
})

onMounted(async () => {
  await ensureTenant()
  await Promise.all([loadCategories(), loadTaxRates(), loadUoms()])
  await loadSummary()
})

onBeforeUnmount(() => {
  if (chartInstance) {
    chartInstance.destroy()
    chartInstance = null
  }
})
</script>
