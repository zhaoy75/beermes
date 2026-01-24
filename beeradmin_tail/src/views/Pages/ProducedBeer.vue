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
            :disabled="inventoryLoading || movementLoading"
            @click="refreshAll"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <header class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-semibold">{{ t('producedBeer.sections.inventory') }}</h2>
            <p class="text-sm text-gray-500">{{ t('producedBeer.inventory.subtitle') }}</p>
          </div>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="inventoryLoading"
            @click="loadInventoryFromMovements"
          >
            {{ t('common.refresh') }}
          </button>
        </header>

        <section class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.beerName') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.category') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.packageType') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.lotNo') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.productionDate') }}</th>
                <th class="px-3 py-2 text-right">{{ t('producedBeer.inventory.table.qtyLiters') }}</th>
                <th class="px-3 py-2 text-right">{{ t('producedBeer.inventory.table.qtyPackages') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.site') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="row in inventoryRows" :key="row.id" class="hover:bg-gray-50">
                <td class="px-3 py-2">
                  <div class="font-medium text-gray-900">{{ row.beerName || '—' }}</div>
                </td>
                <td class="px-3 py-2">{{ categoryLabel(row.categoryId) }}</td>
                <td class="px-3 py-2">{{ row.packageTypeLabel || '—' }}</td>
                <td class="px-3 py-2 font-mono text-xs text-gray-600">{{ row.lotCode || '—' }}</td>
                <td class="px-3 py-2 text-xs text-gray-500">{{ formatDate(row.productionDate) }}</td>
                <td class="px-3 py-2 text-right">{{ formatNumber(row.qtyLiters) }}</td>
                <td class="px-3 py-2 text-right">{{ formatNumber(row.qtyPackages) }}</td>
                <td class="px-3 py-2">{{ siteLabel(row.siteId) }}</td>
              </tr>
              <tr v-if="!inventoryLoading && inventoryRows.length === 0">
                <td colspan="8" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </section>
      </section>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <header class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-semibold">{{ t('producedBeer.sections.movements') }}</h2>
            <p class="text-sm text-gray-500">{{ t('producedBeer.movement.subtitle') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <div class="inline-flex rounded-lg border border-gray-300 bg-white p-0.5 mr-6">
              <button
                class="px-3 py-1.5 text-sm rounded-md"
                :class="movementView === 'list' ? 'bg-gray-900 text-white' : 'text-gray-600 hover:bg-gray-50'"
                type="button"
                @click="movementView = 'list'"
              >
                {{ t('producedBeer.movement.viewList') }}
              </button>
              <button
                class="px-3 py-1.5 text-sm rounded-md"
                :class="movementView === 'card' ? 'bg-gray-900 text-white' : 'text-gray-600 hover:bg-gray-50'"
                type="button"
                @click="movementView = 'card'"
              >
                {{ t('producedBeer.movement.viewCard') }}
              </button>
            </div>
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50 mr-10"
              :disabled="movementLoading || filteredMovementCards.length === 0"
              @click="exportMovementsCsv"
            >
              {{ t('producedBeer.movement.actions.exportCsv') }}
            </button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openMovementCreate">
              {{ t('producedBeer.movement.actions.new') }}
            </button>
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="resetMovementFilters">
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
              <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movement.filters.beerName') }}</label>
              <input v-model.trim="movementFilters.beerName" type="search" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movement.filters.category') }}</label>
              <select v-model="movementFilters.category" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.all') }}</option>
                <option v-for="category in categories" :key="category.id" :value="category.id">
                  {{ category.name || category.code || category.id }}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movement.filters.packageType') }}</label>
              <select v-model="movementFilters.packageType" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.all') }}</option>
                <option v-for="option in packageCategoryOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movement.filters.lotNo') }}</label>
              <input v-model.trim="movementFilters.lotNo" type="search" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movement.filters.dateFrom') }}</label>
              <input v-model="movementFilters.dateFrom" type="date" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movement.filters.dateTo') }}</label>
              <input v-model="movementFilters.dateTo" type="date" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movement.filters.movementType') }}</label>
              <select v-model="movementTypeFilter" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="all">{{ t('common.all') }}</option>
                <option value="taxed">{{ t('producedBeer.movement.types.taxed') }}</option>
                <option value="notax">{{ t('producedBeer.movement.types.notax') }}</option>
                <option value="returnNotax">{{ t('producedBeer.movement.types.returnNotax') }}</option>
                <option value="wasteNotax">{{ t('producedBeer.movement.types.wasteNotax') }}</option>
                <option value="transferNotax">{{ t('producedBeer.movement.types.transferNotax') }}</option>
              </select>
            </div>
          </form>
        </section>

        <section v-if="movementView === 'list'" class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.movement.card.docNo') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.movement.filters.movementType') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.movement.card.movementDate') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.movement.card.source') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.movement.card.destination') }}</th>
                <th class="px-3 py-2 text-right">{{ t('producedBeer.movement.card.totalLiters') }}</th>
                <th class="px-3 py-2 text-right">{{ t('producedBeer.movement.card.totalPackages') }}</th>
                <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="card in filteredMovementCards" :key="card.id" class="hover:bg-gray-50">
                <td class="px-3 py-2 font-semibold text-gray-900">{{ card.docNo }}</td>
                <td class="px-3 py-2 text-gray-600">{{ movementTypeLabel(card.docType, card.taxType) }}</td>
                <td class="px-3 py-2 text-xs text-gray-500">{{ formatDateTime(card.movementAt) }}</td>
                <td class="px-3 py-2 text-gray-600">{{ siteLabel(card.sourceSiteId) }}</td>
                <td class="px-3 py-2 text-gray-600">{{ siteLabel(card.destSiteId) }}</td>
                <td class="px-3 py-2 text-right font-semibold text-gray-900">{{ formatNumber(card.totalLiters) }}</td>
                <td class="px-3 py-2 text-right font-semibold text-gray-900">{{ formatNumber(card.totalPackages) }}</td>
                <td class="px-3 py-2">
                  <button class="px-2 py-1 text-xs rounded border hover:bg-gray-50" @click="openMovementEdit(card)">
                    {{ t('producedBeer.movement.actions.edit') }}
                  </button>
                </td>
              </tr>
              <tr v-if="!movementLoading && filteredMovementCards.length === 0">
                <td colspan="8" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </section>

        <section v-else class="grid gap-4">
          <article
            v-for="card in filteredMovementCards"
            :key="card.id"
            class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-3"
          >
            <div class="flex flex-col gap-2 md:flex-row md:items-start md:justify-between">
              <div>
                <p class="text-xs uppercase tracking-wide text-gray-400">{{ t('producedBeer.movement.card.docNo') }}</p>
                <h3 class="text-lg font-semibold text-gray-900">{{ card.docNo }}</h3>
                <p class="text-xs text-gray-500">{{ movementTypeLabel(card.docType, card.taxType) }}</p>
              </div>
              <div class="text-left md:text-right">
                <p class="text-xs uppercase tracking-wide text-gray-400">{{ t('producedBeer.movement.card.movementDate') }}</p>
                <p class="text-xs text-gray-500">{{ formatDateTime(card.movementAt) }}</p>
                <button class="mt-2 px-3 py-1.5 text-xs rounded border hover:bg-gray-50" @click="openMovementEdit(card)">
                  {{ t('producedBeer.movement.actions.edit') }}
                </button>
              </div>
            </div>

            <dl class="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm text-gray-600">
              <div class="flex justify-between">
                <dt class="font-medium">{{ t('producedBeer.movement.card.source') }}</dt>
                <dd>{{ siteLabel(card.sourceSiteId) }}</dd>
              </div>
              <div class="flex justify-between">
                <dt class="font-medium">{{ t('producedBeer.movement.card.destination') }}</dt>
                <dd>{{ siteLabel(card.destSiteId) }}</dd>
              </div>
              <div class="flex justify-between">
                <dt class="font-medium">{{ t('producedBeer.movement.card.totalLiters') }}</dt>
                <dd class="font-semibold text-gray-900">{{ formatNumber(card.totalLiters) }}</dd>
              </div>
              <div class="flex justify-between">
                <dt class="font-medium">{{ t('producedBeer.movement.card.totalPackages') }}</dt>
                <dd class="font-semibold text-gray-900">{{ formatNumber(card.totalPackages) }}</dd>
              </div>
            </dl>

            <div class="border-t border-gray-100 pt-3">
              <p class="text-xs uppercase tracking-wide text-gray-400 mb-2">{{ t('producedBeer.movement.card.lines') }}</p>
              <div class="overflow-x-auto">
                <table class="min-w-full text-xs">
                  <thead class="text-[11px] uppercase text-gray-500">
                    <tr>
                      <th class="px-2 py-1 text-left">{{ t('producedBeer.movement.card.lineBeer') }}</th>
                      <th class="px-2 py-1 text-left">{{ t('producedBeer.movement.card.lineCategory') }}</th>
                      <th class="px-2 py-1 text-left">{{ t('producedBeer.movement.card.linePackageType') }}</th>
                      <th class="px-2 py-1 text-left">{{ t('producedBeer.movement.card.lineLot') }}</th>
                      <th class="px-2 py-1 text-right">{{ t('producedBeer.movement.card.lineQtyPackages') }}</th>
                      <th class="px-2 py-1 text-right">{{ t('producedBeer.movement.card.lineQtyLiters') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="line in card.lines" :key="line.id">
                      <td class="px-2 py-1 text-gray-800">{{ line.beerName || '—' }}</td>
                      <td class="px-2 py-1 text-gray-600">{{ categoryLabel(line.categoryId) }}</td>
                      <td class="px-2 py-1 text-gray-600">{{ line.packageTypeLabel || '—' }}</td>
                      <td class="px-2 py-1 font-mono text-[11px] text-gray-500">{{ line.lotCode || '—' }}</td>
                      <td class="px-2 py-1 text-right">{{ formatNumber(line.packageQty) }}</td>
                      <td class="px-2 py-1 text-right">{{ formatNumber(line.qtyLiters) }}</td>
                    </tr>
                    <tr v-if="card.lines.length === 0">
                      <td colspan="6" class="px-2 py-2 text-center text-gray-500">{{ t('common.noData') }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </article>
          <p v-if="!movementLoading && filteredMovementCards.length === 0" class="py-8 text-center text-gray-500">
            {{ t('common.noData') }}
          </p>
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
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

interface CategoryRow {
  id: string
  code: string
  name: string | null
}

interface SiteOption {
  value: string
  label: string
}

interface PackageCategoryRow {
  id: string
  package_code: string
  package_name: string | null
  size: number | null
  uom_id: string | null
}

interface PackageRow {
  id: string
  lot_id: string | null
  fill_at: string | null
  package_id: string | null
  package_size_l: number | null
  package_qty: number | null
  lot?: {
    id: string
    lot_code: string
    meta?: Record<string, any> | null
  } | null
  package?: {
    id: string
    package_code: string
    package_name: string | null
    size: number | null
    uom_id: string | null
  } | null
}

interface InventoryRow {
  id: string
  beerName: string | null
  categoryId: string | null
  packageTypeLabel: string | null
  lotCode: string | null
  productionDate: string | null
  qtyPackages: number | null
  qtyLiters: number | null
  siteId: string | null
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
  lot_id: string | null
  qty: number | null
  uom_id: string | null
  meta?: Record<string, any> | null
}

interface PackageInfo {
  id: string
  lotId: string | null
  lotCode: string | null
  beerName: string | null
  packageTypeId: string | null
  packageTypeLabel: string | null
  unitSizeLiters: number | null
  productionDate: string | null
}

interface MovementLineCard {
  id: string
  packageId: string | null
  lotCode: string | null
  beerName: string | null
  categoryId: string | null
  packageTypeId: string | null
  packageTypeLabel: string | null
  packageQty: number | null
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

const { t, locale } = useI18n()
const router = useRouter()
const pageTitle = computed(() => t('producedBeer.title'))

const tenantId = ref<string | null>(null)
const inventoryLoading = ref(false)
const movementLoading = ref(false)

const categories = ref<CategoryRow[]>([])
const packageCategories = ref<PackageCategoryRow[]>([])
const uoms = ref<Array<{ id: string; code: string | null }>>([])
const siteOptions = ref<SiteOption[]>([])

const inventoryRows = ref<InventoryRow[]>([])

const movementCards = ref<MovementCard[]>([])
const movementView = ref<'list' | 'card'>('card')

const movementFilters = reactive({
  beerName: '',
  category: '',
  packageType: '',
  lotNo: '',
  dateFrom: '',
  dateTo: '',
})

const movementTypeFilter = ref<'all' | 'taxed' | 'notax' | 'returnNotax' | 'wasteNotax' | 'transferNotax'>('all')

const siteMap = computed(() => {
  const map = new Map<string, SiteOption>()
  siteOptions.value.forEach((item) => map.set(item.value, item))
  return map
})

const categoryMap = computed(() => {
  const map = new Map<string, CategoryRow>()
  categories.value.forEach((row) => map.set(row.id, row))
  return map
})

const packageCategoryMap = computed(() => {
  const map = new Map<string, { label: string; size: number | null; uomId: string | null }>()
  packageCategories.value.forEach((row) => {
    map.set(row.id, {
      label: row.package_name || row.package_code,
      size: row.size ?? null,
      uomId: row.uom_id ?? null,
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
    label: row.package_name || row.package_code,
  }))
)

const filteredMovementCards = computed<MovementCardView[]>(() => {
  const nameFilter = movementFilters.beerName.trim().toLowerCase()
  const lotFilter = movementFilters.lotNo.trim().toLowerCase()

  return movementCards.value
    .map((card) => {
      const filteredLines = card.lines.filter((line) => {
        if (nameFilter && !(line.beerName || '').toLowerCase().includes(nameFilter)) return false
        if (movementFilters.category && line.categoryId !== movementFilters.category) return false
        if (movementFilters.packageType && line.packageTypeId !== movementFilters.packageType) return false
        if (lotFilter && !(line.lotCode || '').toLowerCase().includes(lotFilter)) return false
        return true
      })

      if (filteredLines.length === 0) return null

      const totalPackages = filteredLines.reduce((sum, line) => sum + (line.packageQty ?? 0), 0)
      const totalLiters = filteredLines.reduce((sum, line) => sum + (line.qtyLiters ?? 0), 0)

      return {
        ...card,
        lines: filteredLines,
        totalPackages,
        totalLiters,
      }
    })
    .filter((item): item is MovementCardView => Boolean(item))
})

const numberFormatter = computed(() => new Intl.NumberFormat(locale.value, { maximumFractionDigits: 2 }))

function formatNumber(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return numberFormatter.value.format(value)
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
  return category?.name || category?.code || categoryId
}

function resolveLotLabel(meta: Record<string, any> | null | undefined) {
  const label = meta?.label
  if (typeof label !== 'string') return null
  const trimmed = label.trim()
  return trimmed.length ? trimmed : null
}

function siteLabel(siteId: string | null | undefined) {
  if (!siteId) return '—'
  return siteMap.value.get(siteId)?.label ?? '—'
}

function docTypeLabel(value: string) {
  const map = t('producedBeer.movement.docTypeMap') as Record<string, string>
  return map[value] || value
}

function movementTypeLabel(docType: string, taxType: string | null) {
  if (docType === 'sale' && taxType === 'tax') return t('producedBeer.movement.types.taxed')
  if (docType === 'sale' && taxType === 'notax') return t('producedBeer.movement.types.notax')
  if (docType === 'return' && taxType === 'notax') return t('producedBeer.movement.types.returnNotax')
  if (docType === 'waste' && taxType === 'notax') return t('producedBeer.movement.types.wasteNotax')
  if (docType === 'transfer' && taxType === 'notax') return t('producedBeer.movement.types.transferNotax')
  return docTypeLabel(docType)
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
    t('producedBeer.movement.card.lineLot'),
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
      rows.push([
        ...base,
        line.beerName ?? '',
        line.packageTypeLabel ?? '',
        line.lotCode ?? '',
        line.packageQty ?? '',
        line.qtyLiters ?? '',
      ].map((value) => String(value)))
    })
  })

  const csv = [header, ...rows]
    .map((row) => row.map(csvEscape).join(','))
    .join('\n')

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

function resolvePackageSizeLiters(row: PackageRow): number | null {
  const direct = toNumber(row.package_size_l)
  if (direct != null && direct > 0) return direct
  const size = toNumber(row.package?.size)
  if (size == null) return null
  const uomCode = row.package?.uom_id ? uomMap.value.get(row.package.uom_id) : null
  return convertToLiters(size, uomCode)
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

async function loadPackageCategories() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_beer_package_category')
    .select('id, package_code, package_name, size, uom_id')
    .eq('tenant_id', tenant)
    .order('package_code', { ascending: true })
  if (error) throw error
  packageCategories.value = data ?? []
}

async function loadUoms() {
  const { data, error } = await supabase.from('mst_uom').select('id, code').order('code', { ascending: true })
  if (error) throw error
  uoms.value = data ?? []
}

async function loadSites() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_sites')
    .select('id, code, name')
    .eq('tenant_id', tenant)
    .order('code', { ascending: true })
  if (error) throw error
  siteOptions.value = (data ?? []).map((row) => ({ value: row.id, label: `${row.code} — ${row.name}` }))
}

async function loadInventoryFromMovements() {
  try {
    inventoryLoading.value = true
    const tenant = await ensureTenant()
    const { data, error } = await supabase
      .from('inv_movement_lines')
      .select(
        'id, movement_id, package_id, lot_id, qty, uom_id, meta, movement:movement_id ( movement_at, status, src_site_id, dest_site_id, doc_type )'
      )
      .eq('tenant_id', tenant)
      .or('package_id.not.is.null,lot_id.not.is.null')
      .order('movement_id', { ascending: true })
    if (error) throw error

    const lines = (data ?? []).filter((row: any) => row.movement?.status !== 'void')
    if (!lines.length) {
      inventoryRows.value = []
      return
    }

    const packageIds = Array.from(new Set(lines.map((row: any) => row.package_id).filter(Boolean)))
    const lotIds = Array.from(new Set(lines.map((row: any) => row.lot_id).filter(Boolean)))

    const packageInfoMap = await loadPackageInfo(packageIds)
    const lotInfoMap = await loadLotInfo(lotIds, packageInfoMap)

    type InventoryAccumulator = {
      key: string
      siteId: string
      packageId: string | null
      lotId: string | null
      beerName: string | null
      packageTypeLabel: string | null
      lotCode: string | null
      productionDate: string | null
      qtyPackages: number
      qtyLiters: number
    }

    const accum = new Map<string, InventoryAccumulator>()

    const applyDelta = (siteId: string | null, delta: number, row: any) => {
      if (!siteId) return
      const pkgInfo = row.package_id ? packageInfoMap.get(row.package_id) : undefined
      const lotInfo = row.lot_id ? lotInfoMap.get(row.lot_id) : undefined
      const unitSizeLiters = pkgInfo?.unitSizeLiters ?? null
      const qtyLiters = toNumber(row.qty) ?? 0
      const packageQty = toNumber(row.meta?.package_qty)
      const derivedPackages = packageQty != null
        ? packageQty
        : (unitSizeLiters && qtyLiters ? qtyLiters / unitSizeLiters : 0)

      const key = `${siteId}__${row.package_id ?? ''}__${row.lot_id ?? ''}`
      if (!accum.has(key)) {
        accum.set(key, {
          key,
          siteId,
          packageId: row.package_id ?? null,
          lotId: row.lot_id ?? pkgInfo?.lotId ?? null,
          beerName: pkgInfo?.beerName ?? lotInfo?.beerName ?? null,
          packageTypeLabel: pkgInfo?.packageTypeLabel ?? null,
          lotCode: pkgInfo?.lotCode ?? lotInfo?.lotCode ?? null,
          productionDate: pkgInfo?.productionDate ?? row.movement?.movement_at ?? null,
          qtyPackages: 0,
          qtyLiters: 0,
        })
      }

      const entry = accum.get(key)
      if (!entry) return
      entry.qtyLiters += qtyLiters * delta
      entry.qtyPackages += derivedPackages * delta
    }

    lines.forEach((row: any) => {
      const movement = row.movement ?? null
      if (!movement) return
      applyDelta(movement.dest_site_id ?? null, 1, row)
      applyDelta(movement.src_site_id ?? null, -1, row)
    })

    inventoryRows.value = Array.from(accum.values())
      .filter((row) => row.qtyLiters > 0 || row.qtyPackages > 0)
      .map((row) => ({
        id: row.key,
        beerName: row.beerName,
        categoryId: null,
        packageTypeLabel: row.packageTypeLabel,
        lotCode: row.lotCode,
        productionDate: row.productionDate,
        qtyPackages: row.qtyPackages > 0 ? row.qtyPackages : null,
        qtyLiters: row.qtyLiters > 0 ? row.qtyLiters : null,
        siteId: row.siteId,
      }))
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    inventoryLoading.value = false
  }
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

    if (movementFilters.dateFrom) headerQuery = headerQuery.gte('movement_at', `${movementFilters.dateFrom}T00:00:00`)
    if (movementFilters.dateTo) headerQuery = headerQuery.lte('movement_at', `${movementFilters.dateTo}T23:59:59`)

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
      .select('id, movement_id, package_id, lot_id, qty, uom_id, meta')
      .in('movement_id', movementIds)
      .order('line_no', { ascending: true })

    if (lineError) throw lineError

    const lineList = (lines ?? []).filter((row: any) => row.package_id || row.lot_id) as MovementLineRow[]
    const packageIds = lineList.map((row) => row.package_id).filter(Boolean) as string[]
    const lotIds = lineList.map((row) => row.lot_id).filter(Boolean) as string[]

    const packageInfoMap = await loadPackageInfo(packageIds)
    const lotInfoMap = await loadLotInfo(lotIds, packageInfoMap)

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
      const lotInfo = line.lot_id ? lotInfoMap.get(line.lot_id) : undefined
      const packageQty = toNumber(line.meta?.package_qty)
      const qtyLiters = toNumber(line.qty) ?? (packageQty && pkgInfo?.unitSizeLiters ? packageQty * pkgInfo.unitSizeLiters : null)

      const lineCard: MovementLineCard = {
        id: line.id,
        packageId: line.package_id ?? null,
        lotCode: pkgInfo?.lotCode ?? lotInfo?.lotCode ?? null,
        beerName: pkgInfo?.beerName ?? lotInfo?.beerName ?? null,
        categoryId: null,
        packageTypeId: pkgInfo?.packageTypeId ?? null,
        packageTypeLabel: pkgInfo?.packageTypeLabel ?? null,
        packageQty,
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

  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('pkg_packages')
    .select(
      'id, lot_id, fill_at, package_id, package_size_l, package_qty, lot:lot_id ( id, lot_code, meta ), package:package_id ( id, package_code, package_name, size, uom_id )'
    )
    .eq('tenant_id', tenant)
    .in('id', packageIds)
  if (error) throw error

  ;(data ?? []).forEach((row: any) => {
    const packageRow = row as PackageRow
    const unitSizeLiters = resolvePackageSizeLiters(packageRow)
    const lotLabel = resolveLotLabel(packageRow.lot?.meta)
    infoMap.set(packageRow.id, {
      id: packageRow.id,
      lotId: packageRow.lot_id ?? packageRow.lot?.id ?? null,
      lotCode: packageRow.lot?.lot_code ?? null,
      beerName: lotLabel ?? null,
      packageTypeId: packageRow.package_id ?? packageRow.package?.id ?? null,
      packageTypeLabel:
        packageRow.package?.package_name ||
        packageRow.package?.package_code ||
        (packageRow.package_id ? packageCategoryMap.value.get(packageRow.package_id)?.label : null) ||
        null,
      unitSizeLiters,
      productionDate: packageRow.fill_at ?? null,
    })
  })

  return infoMap
}

async function loadLotInfo(lotIds: string[], packageInfoMap: Map<string, PackageInfo>) {
  const infoMap = new Map<string, { lotCode: string | null; beerName: string | null }>()
  if (lotIds.length === 0) return infoMap

  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('prd_lots')
    .select('id, lot_code, meta')
    .eq('tenant_id', tenant)
    .in('id', lotIds)
  if (error) throw error

  ;(data ?? []).forEach((row: any) => {
    infoMap.set(row.id, {
      lotCode: row.lot_code ?? null,
      beerName: resolveLotLabel(row.meta) ?? null,
    })
  })

  packageInfoMap.forEach((info) => {
    if (info.lotId && !infoMap.has(info.lotId)) {
      infoMap.set(info.lotId, {
        lotCode: info.lotCode,
        beerName: info.beerName,
      })
    }
  })

  return infoMap
}

function resetMovementFilters() {
  movementFilters.beerName = ''
  movementFilters.category = ''
  movementFilters.packageType = ''
  movementFilters.lotNo = ''
  movementFilters.dateFrom = ''
  movementFilters.dateTo = ''
  movementTypeFilter.value = 'all'
}

function openMovementCreate() {
  router.push({ path: '/producedBeerMovement' })
}

function openMovementEdit(card: MovementCard) {
  router.push({ path: '/producedBeerMovement', query: { id: card.id } })
}

async function refreshAll() {
  await Promise.all([loadInventoryFromMovements(), fetchMovements()])
}

watch(
  () => ({
    dateFrom: movementFilters.dateFrom,
    dateTo: movementFilters.dateTo,
    movementType: movementTypeFilter.value,
  }),
  async () => {
    await fetchMovements()
  }
)

onMounted(async () => {
  try {
    await ensureTenant()
    await Promise.all([loadSites(), loadCategories(), loadPackageCategories(), loadUoms()])
    await loadInventoryFromMovements()
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
