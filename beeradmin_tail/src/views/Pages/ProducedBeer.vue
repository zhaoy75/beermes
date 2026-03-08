<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 w-full space-y-6">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('producedBeer.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('producedBeer.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="movementLoading"
            @click="fetchMovements"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <header class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-semibold">{{ t('producedBeer.sections.movements') }}</h2>
            <p class="text-sm text-gray-500">{{ t('producedBeer.movement.subtitle') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
              :disabled="movementLoading || filteredMovementCards.length === 0"
              @click="exportMovementsCsv"
            >
              {{ t('producedBeer.movement.actions.exportCsv') }}
            </button>
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50"
              @click="openMovementCreateFast"
            >
              {{ t('producedBeer.movement.actions.fast') }}
            </button>
            <button
              class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700"
              @click="openMovementCreate"
            >
              {{ t('producedBeer.movement.actions.new') }}
            </button>
            <button
              class="px-3 py-2 rounded border hover:bg-gray-50"
              type="button"
              @click="resetMovementFilters"
            >
              {{ t('common.reset') }}
            </button>
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
              :disabled="movementLoading"
              @click="fetchMovements"
            >
              {{ t('common.refresh') }}
            </button>
          </div>
        </header>

        <section class="border border-gray-200 rounded-lg p-4 bg-white">
          <form class="grid grid-cols-1 md:grid-cols-6 gap-3" @submit.prevent>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.beerName')
              }}</label>
              <input
                v-model.trim="movementFilters.beerName"
                type="search"
                class="w-full h-[40px] border rounded px-3"
              />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.category')
              }}</label>
              <select
                v-model="movementFilters.category"
                class="w-full h-[40px] border rounded px-3 bg-white"
              >
                <option value="">{{ t('common.all') }}</option>
                <option
                  v-for="category in categories"
                  :key="category.def_id"
                  :value="category.def_id"
                >
                  {{
                    typeof category.spec?.name === 'string' ? category.spec.name : category.def_key
                  }}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.packageType')
              }}</label>
              <select
                v-model="movementFilters.packageType"
                class="w-full h-[40px] border rounded px-3 bg-white"
              >
                <option value="">{{ t('common.all') }}</option>
                <option
                  v-for="option in packageCategoryOptions"
                  :key="option.value"
                  :value="option.value"
                >
                  {{ option.label }}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.batchNo')
              }}</label>
              <input
                v-model.trim="movementFilters.batchNo"
                type="search"
                class="w-full h-[40px] border rounded px-3"
              />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.dateFrom')
              }}</label>
              <input
                v-model="movementFilters.dateFrom"
                type="date"
                class="w-full h-[40px] border rounded px-3"
              />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.dateTo')
              }}</label>
              <input
                v-model="movementFilters.dateTo"
                type="date"
                class="w-full h-[40px] border rounded px-3"
              />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.movementType')
              }}</label>
              <select
                v-model="movementTypeFilter"
                class="w-full h-[40px] border rounded px-3 bg-white"
              >
                <option value="all">{{ t('common.all') }}</option>
                <option value="taxed">{{ t('producedBeer.movement.types.taxed') }}</option>
                <option value="notax">{{ t('producedBeer.movement.types.notax') }}</option>
                <option value="returnNotax">
                  {{ t('producedBeer.movement.types.returnNotax') }}
                </option>
                <option value="wasteNotax">
                  {{ t('producedBeer.movement.types.wasteNotax') }}
                </option>
                <option value="transferNotax">
                  {{ t('producedBeer.movement.types.transferNotax') }}
                </option>
              </select>
            </div>
          </form>
        </section>

        <section class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="px-3 py-2 text-left">
                  {{ t('producedBeer.movement.card.movementDate') }}
                </th>
                <th class="px-3 py-2 text-left">
                  {{ t('producedBeer.inventory.table.styleName') }}
                </th>
                <th class="px-3 py-2 text-right">
                  {{ t('producedBeer.inventory.table.targetAbv') }}
                </th>
                <th class="px-3 py-2 text-left">
                  {{ t('producedBeer.movement.card.linePackageType') }}
                </th>
                <th class="px-3 py-2 text-right">
                  {{ t('producedBeer.movement.card.volumePerPackage') }}
                </th>
                <th class="px-3 py-2 text-right">
                  {{ t('producedBeer.movement.card.unitOfPackage') }}
                </th>
                <th class="px-3 py-2 text-right">{{ t('producedBeer.movement.card.totalVolume') }}</th>
                <th class="px-3 py-2 text-right">{{ t('producedBeer.movement.card.taxRate') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.movement.card.source') }}</th>
                <th class="px-3 py-2 text-left">
                  {{ t('producedBeer.movement.card.destination') }}
                </th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.movement.card.docNo') }}</th>
                <th class="px-3 py-2 text-left">
                  {{ t('producedBeer.movement.filters.movementType') }}
                </th>
                <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="card in filteredMovementCards" :key="card.id" class="hover:bg-gray-50">
                <td class="px-3 py-2 text-xs text-gray-500">
                  {{ formatDateTime(card.movementAt) }}
                </td>
                <td class="px-3 py-2 text-gray-600">{{ movementStyleLabel(card) }}</td>
                <td class="px-3 py-2 text-right text-gray-600">
                  {{ movementTargetAbvLabel(card) }}
                </td>
                <td class="px-3 py-2 text-gray-600">{{ movementPackageLabel(card) }}</td>
                <td class="px-3 py-2 text-right text-gray-600">
                  {{ movementVolumeLabel(card) }}
                </td>
                <td class="px-3 py-2 text-right text-gray-600">
                  {{ movementUnitOfPackageLabel(card) }}
                </td>
                <td class="px-3 py-2 text-right font-semibold text-gray-900">
                  {{ formatVolumeNumberValue(card.totalLiters) }}
                </td>
                <td class="px-3 py-2 text-right text-gray-600">{{ movementTaxRateLabel(card) }}</td>
                <td class="px-3 py-2 text-gray-600">{{ siteLabel(card.sourceSiteId) }}</td>
                <td class="px-3 py-2 text-gray-600">{{ siteLabel(card.destSiteId) }}</td>
                <td class="px-3 py-2 font-semibold text-gray-900">{{ card.docNo }}</td>
                <td class="px-3 py-2 text-gray-600">
                  {{ movementTypeLabel(card.docType, card.taxType) }}
                </td>
                <td class="px-3 py-2">
                  <button
                    class="px-2 py-1 text-xs rounded border hover:bg-gray-50 disabled:opacity-50 disabled:hover:bg-white"
                    :disabled="movementLoading || card.status === 'void'"
                    @click="reverseMovement(card)"
                  >
                    {{
                      card.status === 'void'
                        ? t('producedBeer.movement.actions.reversed')
                        : t('producedBeer.movement.actions.reverse')
                    }}
                  </button>
                </td>
              </tr>
              <tr v-if="!movementLoading && filteredMovementCards.length === 0">
                <td colspan="13" class="px-3 py-8 text-center text-gray-500">
                  {{ t('common.noData') }}
                </td>
              </tr>
            </tbody>
          </table>
        </section>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { formatVolumeNumber } from '@/lib/volumeFormat'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

interface CategoryRow {
  def_id: string
  def_key: string
  spec: Record<string, any>
}

interface SiteOption {
  value: string
  label: string
}

interface PackageCategoryRow {
  id: string
  package_code: string
  name_i18n: Record<string, string> | null
  unit_volume: number | null
  volume_uom: string | null
}

interface MovementHeader {
  id: string
  doc_no: string
  doc_type: string
  movement_at: string | null
  status: string
  src_site_id: string | null
  dest_site_id: string | null
  notes: string | null
  meta?: Record<string, any> | null
}

interface MovementLineRow {
  id: string
  movement_id: string
  package_id: string | null
  batch_id: string | null
  qty: number | null
  unit: number | null
  tax_rate: number | null
  uom_id: string | null
  meta?: Record<string, any> | null
}

interface PackageInfo {
  id: string
  batchId: string | null
  batchCode: string | null
  beerName: string | null
  packageTypeId: string | null
  packageTypeLabel: string | null
  unitSizeLiters: number | null
  productionDate: string | null
}

interface MovementLineCard {
  id: string
  packageId: string | null
  batchCode: string | null
  beerName: string | null
  categoryId: string | null
  styleName: string | null
  targetAbv: number | null
  packageTypeId: string | null
  packageTypeLabel: string | null
  packageQty: number | null
  unitOfPackage: number | null
  taxRate: number | null
  qtyLiters: number | null
}

interface MovementCard {
  id: string
  docNo: string
  docType: string
  taxType: string | null
  movementAt: string | null
  status: string
  sourceSiteId: string | null
  destSiteId: string | null
  lines: MovementLineCard[]
}

interface MovementCardView extends MovementCard {
  totalPackages: number | null
  totalLiters: number | null
}

const { t, locale, tm } = useI18n()
const router = useRouter()
const pageTitle = computed(() => t('producedBeer.title'))

const tenantId = ref<string | null>(null)
const movementLoading = ref(false)

const categories = ref<CategoryRow[]>([])
const packageCategories = ref<PackageCategoryRow[]>([])
const uoms = ref<Array<{ id: string; code: string | null }>>([])
const siteOptions = ref<SiteOption[]>([])

const movementCards = ref<MovementCard[]>([])
const movementFilters = reactive({
  beerName: '',
  category: '',
  packageType: '',
  batchNo: '',
  dateFrom: '',
  dateTo: '',
})

const movementTypeFilter = ref<
  'all' | 'taxed' | 'notax' | 'returnNotax' | 'wasteNotax' | 'transferNotax'
>('all')

const siteMap = computed(() => {
  const map = new Map<string, SiteOption>()
  siteOptions.value.forEach((item) => map.set(item.value, item))
  return map
})

const categoryMap = computed(() => {
  const map = new Map<string, CategoryRow>()
  categories.value.forEach((row) => map.set(row.def_id, row))
  return map
})

const packageCategoryMap = computed(() => {
  const map = new Map<string, { label: string; size: number | null; uomId: string | null }>()
  packageCategories.value.forEach((row) => {
    map.set(row.id, {
      label: resolvePackageName(row),
      size: row.unit_volume ?? null,
      uomId: row.volume_uom ?? null,
    })
  })
  return map
})

const uomMap = computed(() => {
  const map = new Map<string, string>()
  uoms.value.forEach((row) => map.set(row.id, row.code ?? ''))
  return map
})

const packageCategoryOptions = computed(() =>
  packageCategories.value.map((row) => ({
    value: row.id,
    label: resolvePackageName(row),
  })),
)

const filteredMovementCards = computed<MovementCardView[]>(() => {
  const nameFilter = movementFilters.beerName.trim().toLowerCase()
  const batchFilter = movementFilters.batchNo.trim().toLowerCase()

  return movementCards.value.reduce<MovementCardView[]>((acc, card) => {
    const filteredLines = card.lines.filter((line) => {
      if (nameFilter && !(line.beerName || '').toLowerCase().includes(nameFilter)) return false
      if (movementFilters.category && line.categoryId !== movementFilters.category) return false
      if (movementFilters.packageType && line.packageTypeId !== movementFilters.packageType)
        return false
      if (batchFilter && !(line.batchCode || '').toLowerCase().includes(batchFilter)) return false
      return true
    })

    if (filteredLines.length === 0) return acc

    const totalPackages = filteredLines.reduce((sum, line) => sum + (line.packageQty ?? 0), 0)
    const totalLiters = filteredLines.reduce((sum, line) => sum + (line.qtyLiters ?? 0), 0)

    acc.push({
      ...card,
      lines: filteredLines,
      totalPackages,
      totalLiters,
    })
    return acc
  }, [])
})

const numberFormatter = computed(
  () => new Intl.NumberFormat(locale.value, { maximumFractionDigits: 2 }),
)

function formatNumber(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return numberFormatter.value.format(value)
}

function formatVolumeNumberValue(value: number | null | undefined) {
  return formatVolumeNumber(value, locale.value)
}

function formatAbv(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return `${numberFormatter.value.format(value)}%`
}

function formatDate(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Intl.DateTimeFormat(locale.value).format(new Date(value))
  } catch {
    return value
  }
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
  } catch {
    return value
  }
}

function categoryLabel(categoryId: string | null | undefined) {
  if (!categoryId) return '—'
  const category = categoryMap.value.get(categoryId)
  if (!category) return categoryId
  const label = typeof category.spec?.name === 'string' ? category.spec.name : category.def_key
  return label || categoryId
}

function resolveLang() {
  return String(locale.value ?? '')
    .toLowerCase()
    .startsWith('ja')
    ? 'ja'
    : 'en'
}

function resolvePackageName(row: PackageCategoryRow) {
  const lang = resolveLang()
  const name = row.name_i18n?.[lang] ?? Object.values(row.name_i18n ?? {})[0]
  return name || row.package_code
}

function resolveBatchLabel(meta: Record<string, any> | null | undefined) {
  const label = meta?.label
  if (typeof label !== 'string') return null
  const trimmed = label.trim()
  return trimmed.length ? trimmed : null
}

function resolveMetaString(meta: Record<string, any> | null | undefined, key: string) {
  const value = meta?.[key]
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  return trimmed.length ? trimmed : null
}

function resolveMetaNumber(meta: Record<string, any> | null | undefined, key: string) {
  const value = meta?.[key]
  if (value == null) return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function siteLabel(siteId: string | null | undefined) {
  if (!siteId) return '—'
  return siteMap.value.get(siteId)?.label ?? '—'
}

function docTypeLabel(value: string) {
  const map = tm('producedBeer.movement.docTypeMap') as Record<string, string> | string
  if (!map || typeof map !== 'object') return value
  return map[value] || value
}

function movementTypeLabel(docType: string, taxType: string | null) {
  if (docType === 'sale' && taxType === 'tax') return t('producedBeer.movement.types.taxed')
  if (docType === 'sale' && taxType === 'notax') return t('producedBeer.movement.types.notax')
  if (docType === 'return' && taxType === 'notax')
    return t('producedBeer.movement.types.returnNotax')
  if (docType === 'waste' && taxType === 'notax') return t('producedBeer.movement.types.wasteNotax')
  if (docType === 'transfer' && taxType === 'notax')
    return t('producedBeer.movement.types.transferNotax')
  return docTypeLabel(docType)
}

function uniqueNonEmpty(values: Array<string | null | undefined>) {
  return Array.from(
    new Set(values.map((value) => (value ?? '').trim()).filter((value) => value.length > 0)),
  )
}

function uniqueNumbers(values: Array<number | null | undefined>, precision = 6) {
  const map = new Map<string, number>()
  values.forEach((value) => {
    if (value == null || Number.isNaN(value)) return
    const normalized = Number(value.toFixed(precision))
    map.set(String(normalized), normalized)
  })
  return Array.from(map.values())
}

function movementStyleLabel(card: MovementCardView) {
  const styles = uniqueNonEmpty(card.lines.map((line) => line.styleName))
  return styles.length ? styles.join(', ') : '—'
}

function movementTargetAbvLabel(card: MovementCardView) {
  const abvs = uniqueNumbers(card.lines.map((line) => line.targetAbv))
  if (!abvs.length) return '—'
  return abvs.map((value) => formatAbv(value)).join(', ')
}

function movementPackageLabel(card: MovementCardView) {
  const packages = uniqueNonEmpty(card.lines.map((line) => line.packageTypeLabel))
  return packages.length ? packages.join(', ') : '—'
}

function packageVolumePerPackageLabel(packageTypeId: string | null | undefined) {
  if (!packageTypeId) return null
  const pkg = packageCategoryMap.value.get(packageTypeId)
  if (pkg?.size == null || Number.isNaN(pkg.size)) return null
  const qty = Number(pkg.size)
  const display = Number.isFinite(qty) ? formatVolumeNumberValue(qty) : String(pkg.size)
  const uomCode = pkg.uomId ? uomMap.value.get(pkg.uomId) ?? pkg.uomId : null
  return uomCode ? `${display} ${uomCode}` : display
}

function movementVolumeLabel(card: MovementCardView) {
  const packageVolumes = uniqueNonEmpty(
    card.lines.map((line) => packageVolumePerPackageLabel(line.packageTypeId)),
  )
  return packageVolumes.length ? packageVolumes.join(', ') : '—'
}

function movementUnitOfPackageLabel(card: MovementCardView) {
  const units = uniqueNumbers(card.lines.map((line) => line.unitOfPackage))
  if (!units.length) return '—'
  return units.map((value) => formatNumber(value)).join(', ')
}

function normalizeTaxRatePercent(rate: number) {
  if (!Number.isFinite(rate)) return null
  if (Math.abs(rate) <= 1) return rate * 100
  return rate
}

function movementTaxRateLabel(card: MovementCardView) {
  const taxRates = uniqueNumbers(card.lines.map((line) => normalizeTaxRatePercent(line.taxRate ?? NaN)))
  if (taxRates.length) return taxRates.map((value) => `${formatNumber(value)}%`).join(', ')
  if (card.taxType === 'notax') return '0%'
  return '—'
}

function csvEscape(value: unknown) {
  const raw = value == null ? '' : String(value)
  if (raw.includes('"')) {
    const escaped = raw.replace(/"/g, '""')
    return `"${escaped}"`
  }
  if (raw.includes(',') || raw.includes('\n')) {
    return `"${raw}"`
  }
  return raw
}

function exportMovementsCsv() {
  const header = [
    t('producedBeer.movement.card.docNo'),
    t('producedBeer.movement.filters.movementType'),
    t('producedBeer.movement.card.taxType'),
    t('producedBeer.movement.card.movementDate'),
    t('producedBeer.movement.card.source'),
    t('producedBeer.movement.card.destination'),
    t('producedBeer.movement.card.lineBeer'),
    t('producedBeer.movement.card.linePackageType'),
    t('producedBeer.movement.card.lineBatch'),
    t('producedBeer.movement.card.lineQtyPackages'),
    t('producedBeer.movement.card.lineQtyLiters'),
  ]

  const rows: string[][] = []
  filteredMovementCards.value.forEach((card) => {
    const base = [
      card.docNo,
      movementTypeLabel(card.docType, card.taxType),
      card.taxType ?? '',
      card.movementAt ?? '',
      siteLabel(card.sourceSiteId),
      siteLabel(card.destSiteId),
    ]
    if (card.lines.length === 0) {
      rows.push([...base, '', '', '', '', ''])
      return
    }
    card.lines.forEach((line) => {
      rows.push(
        [
          ...base,
          line.beerName ?? '',
          line.packageTypeLabel ?? '',
          line.batchCode ?? '',
          line.packageQty ?? '',
          line.qtyLiters ?? '',
        ].map((value) => String(value)),
      )
    })
  })

  const csv = [header, ...rows].map((row) => row.map(csvEscape).join(',')).join('\n')

  const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  const dateStamp = new Date().toISOString().slice(0, 10).replace(/-/g, '')
  link.href = url
  link.download = `movements-${dateStamp}.csv`
  link.click()
  URL.revokeObjectURL(url)
}

function matchesMovementType(header: MovementHeader) {
  if (movementTypeFilter.value === 'all') return true

  const docType = header.doc_type
  const taxType = typeof header.meta?.tax_type === 'string' ? header.meta.tax_type : ''

  switch (movementTypeFilter.value) {
    case 'taxed':
      return docType === 'sale' && taxType === 'tax'
    case 'notax':
      return docType === 'sale' && taxType === 'notax'
    case 'returnNotax':
      return docType === 'return' && taxType === 'notax'
    case 'wasteNotax':
      return docType === 'waste' && taxType === 'notax'
    case 'transferNotax':
      return docType === 'transfer' && taxType === 'notax'
    default:
      return true
  }
}

function toNumber(value: any): number | null {
  if (value == null) return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
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
  const { data, error } = await supabase
    .from('registry_def')
    .select('def_id, def_key, spec')
    .eq('kind', 'alcohol_type')
    .eq('is_active', true)
    .order('def_key', { ascending: true })
  if (error) throw error
  categories.value = data ?? []
}

async function loadPackageCategories() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_package')
    .select('id, package_code, name_i18n, unit_volume, volume_uom, is_active')
    .eq('tenant_id', tenant)
    .eq('is_active', true)
    .order('package_code', { ascending: true })
  if (error) throw error
  packageCategories.value = data ?? []
}

async function loadUoms() {
  const { data, error } = await supabase
    .from('mst_uom')
    .select('id, code')
    .order('code', { ascending: true })
  if (error) throw error
  uoms.value = data ?? []
}

async function loadSites() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_sites')
    .select('id, name')
    .eq('tenant_id', tenant)
    .order('name', { ascending: true })
  if (error) throw error
  siteOptions.value = (data ?? []).map((row) => ({ value: row.id, label: row.name ?? row.id }))
}

async function fetchMovements() {
  try {
    movementLoading.value = true
    const tenant = await ensureTenant()
    let headerQuery = supabase
      .from('inv_movements')
      .select('id, doc_no, doc_type, movement_at, status, src_site_id, dest_site_id, notes, meta')
      .eq('tenant_id', tenant)
      .order('movement_at', { ascending: false })

    if (movementFilters.dateFrom)
      headerQuery = headerQuery.gte('movement_at', `${movementFilters.dateFrom}T00:00:00`)
    if (movementFilters.dateTo)
      headerQuery = headerQuery.lte('movement_at', `${movementFilters.dateTo}T23:59:59`)

    const { data: headers, error: headerError } = await headerQuery
    if (headerError) throw headerError

    const headerList = (headers ?? []) as MovementHeader[]
    const filteredHeaders = headerList.filter((row) => matchesMovementType(row))
    const headerMap = new Map(filteredHeaders.map((row) => [row.id, row]))
    const movementIds = filteredHeaders.map((row) => row.id)

    if (movementIds.length === 0) {
      movementCards.value = []
      return
    }

    const { data: lines, error: lineError } = await supabase
      .from('inv_movement_lines')
      .select('id, movement_id, package_id, batch_id, qty, unit, tax_rate, uom_id, meta')
      .in('movement_id', movementIds)
      .order('line_no', { ascending: true })

    if (lineError) throw lineError

    const lineList = (lines ?? []).filter(
      (row: any) => row.package_id || row.batch_id,
    ) as MovementLineRow[]
    const packageIds = lineList.map((row) => row.package_id).filter(Boolean) as string[]
    const batchIds = lineList.map((row) => row.batch_id).filter(Boolean) as string[]

    const packageInfoMap = await loadPackageInfo(packageIds)
    const batchInfoMap = await loadBatchInfo(batchIds)

    const cardMap = new Map<string, MovementCard>()
    lineList.forEach((line) => {
      const header = headerMap.get(line.movement_id)
      if (!header) return
      if (!cardMap.has(line.movement_id)) {
        const taxType = typeof header.meta?.tax_type === 'string' ? header.meta.tax_type : null
        cardMap.set(line.movement_id, {
          id: line.movement_id,
          docNo: header.doc_no,
          docType: header.doc_type,
          taxType,
          movementAt: header.movement_at ?? null,
          status: header.status,
          sourceSiteId: header.src_site_id ?? null,
          destSiteId: header.dest_site_id ?? null,
          lines: [],
        })
      }

      const pkgInfo = line.package_id ? packageInfoMap.get(line.package_id) : undefined
      const batchInfo = line.batch_id ? batchInfoMap.get(line.batch_id) : undefined
      const packageQty = toNumber(line.meta?.package_qty)
      const qtyLiters =
        toNumber(line.qty) ??
        (packageQty && pkgInfo?.unitSizeLiters ? packageQty * pkgInfo.unitSizeLiters : null)

      const lineCard: MovementLineCard = {
        id: line.id,
        packageId: line.package_id ?? null,
        batchCode: pkgInfo?.batchCode ?? batchInfo?.batchCode ?? null,
        beerName: pkgInfo?.beerName ?? batchInfo?.beerName ?? null,
        categoryId: batchInfo?.beerCategoryId ?? null,
        styleName: batchInfo?.styleName ?? null,
        targetAbv: batchInfo?.targetAbv ?? null,
        packageTypeId: pkgInfo?.packageTypeId ?? null,
        packageTypeLabel: pkgInfo?.packageTypeLabel ?? null,
        packageQty,
        unitOfPackage: toNumber(line.unit),
        taxRate: toNumber(line.tax_rate),
        qtyLiters,
      }

      cardMap.get(line.movement_id)?.lines.push(lineCard)
    })

    movementCards.value = Array.from(cardMap.values()).sort((a, b) => {
      const aTime = a.movementAt ? Date.parse(a.movementAt) : 0
      const bTime = b.movementAt ? Date.parse(b.movementAt) : 0
      return bTime - aTime
    })
  } catch (err) {
    console.error(err)
    movementCards.value = []
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    movementLoading.value = false
  }
}

async function loadPackageInfo(packageIds: string[]) {
  const infoMap = new Map<string, PackageInfo>()
  if (packageIds.length === 0) return infoMap
  const uniqueIds = Array.from(new Set(packageIds))
  uniqueIds.forEach((id) => {
    const category = packageCategoryMap.value.get(id)
    const uomCode = category?.uomId ? uomMap.value.get(category.uomId) : null
    const unitSizeLiters = category?.size != null ? convertToLiters(category.size, uomCode) : null
    infoMap.set(id, {
      id,
      batchId: null,
      batchCode: null,
      beerName: null,
      packageTypeId: id,
      packageTypeLabel: category?.label ?? null,
      unitSizeLiters,
      productionDate: null,
    })
  })
  return infoMap
}

async function loadBatchInfo(batchIds: string[]) {
  const infoMap = new Map<
    string,
    {
      batchCode: string | null
      beerName: string | null
      beerCategoryId: string | null
      targetAbv: number | null
      styleName: string | null
    }
  >()
  if (batchIds.length === 0) return infoMap

  const tenant = await ensureTenant()
  const uniqueIds = Array.from(new Set(batchIds))

  const attrIdToCode = new Map<string, string>()
  const attrIds: number[] = []
  const attrValueByBatch = new Map<
    string,
    {
      beerCategoryId: string | null
      targetAbv: number | null
      styleName: string | null
    }
  >()

  try {
    const { data: attrDefs, error: attrDefError } = await supabase
      .from('attr_def')
      .select('attr_id, code')
      .eq('domain', 'batch')
      .in('code', ['beer_category', 'target_abv', 'style_name'])
      .eq('is_active', true)
    if (attrDefError) throw attrDefError
    ;(attrDefs ?? []).forEach((row: any) => {
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
      ;(attrValues ?? []).forEach((row: any) => {
        const batchId = String(row.entity_id ?? '')
        if (!batchId) return
        if (!attrValueByBatch.has(batchId)) {
          attrValueByBatch.set(batchId, {
            beerCategoryId: null,
            targetAbv: null,
            styleName: null,
          })
        }
        const entry = attrValueByBatch.get(batchId)
        if (!entry) return

        const code = attrIdToCode.get(String(row.attr_id))
        if (!code) return

        if (code === 'beer_category') {
          const jsonDefId = row.value_json?.def_id
          if (typeof jsonDefId === 'string' && jsonDefId.trim())
            entry.beerCategoryId = jsonDefId.trim()
          else if (typeof row.value_text === 'string' && row.value_text.trim())
            entry.beerCategoryId = row.value_text.trim()
          else if (row.value_ref_type_id != null)
            entry.beerCategoryId = String(row.value_ref_type_id)
        }
        if (code === 'target_abv') {
          const num = toNumber(row.value_num)
          if (num != null) entry.targetAbv = num
        }
        if (code === 'style_name') {
          if (typeof row.value_text === 'string' && row.value_text.trim())
            entry.styleName = row.value_text.trim()
        }
      })
    }
  } catch (err) {
    console.warn('Failed to load batch attr values, fallback to recipe/meta only', err)
  }

  const { data, error } = await supabase
    .from('mes_batches')
    .select(
      'id, batch_code, batch_label, product_name, meta, recipe_id, recipe:recipe_id ( category, target_abv, style )',
    )
    .eq('tenant_id', tenant)
    .in('id', uniqueIds)
  if (error) throw error
  ;(data ?? []).forEach((row: any) => {
    const attr = attrValueByBatch.get(row.id)
    const recipe = Array.isArray(row.recipe) ? row.recipe[0] : row.recipe
    const meta =
      row.meta && typeof row.meta === 'object' && !Array.isArray(row.meta)
        ? (row.meta as Record<string, any>)
        : null

    infoMap.set(row.id, {
      batchCode: row.batch_code ?? null,
      beerName: row.product_name ?? row.batch_label ?? resolveBatchLabel(meta) ?? null,
      beerCategoryId:
        attr?.beerCategoryId ??
        (typeof recipe?.category === 'string' ? recipe.category : null) ??
        resolveMetaString(meta, 'beer_category') ??
        resolveMetaString(meta, 'category') ??
        null,
      targetAbv:
        attr?.targetAbv ??
        toNumber(recipe?.target_abv) ??
        resolveMetaNumber(meta, 'target_abv') ??
        null,
      styleName:
        attr?.styleName ??
        (typeof recipe?.style === 'string' ? recipe.style : null) ??
        resolveMetaString(meta, 'style_name') ??
        resolveMetaString(meta, 'style') ??
        null,
    })
  })
  return infoMap
}

function resetMovementFilters() {
  movementFilters.beerName = ''
  movementFilters.category = ''
  movementFilters.packageType = ''
  movementFilters.batchNo = ''
  movementFilters.dateFrom = ''
  movementFilters.dateTo = ''
  movementTypeFilter.value = 'all'
}

function openMovementCreate() {
  router.push({ path: '/producedBeerMovement' })
}

function openMovementCreateFast() {
  router.push({ path: '/producedBeerMovementFast' })
}

async function reverseMovement(card: MovementCard) {
  if (movementLoading.value || card.status === 'void') return

  const confirmed = window.confirm(
    t('producedBeer.movement.actions.reverseConfirm', { docNo: card.docNo }),
  )
  if (!confirmed) return

  try {
    movementLoading.value = true
    const { error } = await supabase.rpc('movement_save', {
      p_movement_id: card.id,
      p_doc: { status: 'void' },
    })
    if (error) throw error

    toast.success(t('producedBeer.movement.actions.reverseSuccess'))
    await fetchMovements()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    movementLoading.value = false
  }
}

watch(
  () => ({
    dateFrom: movementFilters.dateFrom,
    dateTo: movementFilters.dateTo,
    movementType: movementTypeFilter.value,
  }),
  async () => {
    await fetchMovements()
  },
)

onMounted(async () => {
  try {
    await ensureTenant()
    await Promise.all([loadSites(), loadCategories(), loadPackageCategories(), loadUoms()])
    await fetchMovements()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
