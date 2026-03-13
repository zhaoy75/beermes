<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 w-full space-y-6">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('producedBeerInventory.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('producedBeerInventory.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="inventoryLoading"
            @click="loadInventory"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <header>
          <h2 class="text-lg font-semibold">{{ t('producedBeer.sections.inventory') }}</h2>
          <p class="text-sm text-gray-500">{{ t('producedBeer.inventory.subtitle') }}</p>
        </header>

        <section class="rounded-xl border border-gray-200 bg-gray-50/70 p-4">
          <form class="grid grid-cols-1 gap-4 md:grid-cols-5" @submit.prevent>
            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('producedBeerInventory.filters.keyword') }}
              </label>
              <input
                v-model.trim="filters.keyword"
                type="search"
                class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
                :placeholder="t('producedBeerInventory.placeholders.keyword')"
              />
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('producedBeerInventory.filters.product') }}
              </label>
              <select
                v-model="filters.product"
                class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
              >
                <option value="">{{ t('producedBeerInventory.defaults.allProducts') }}</option>
                <option v-for="option in productOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('producedBeerInventory.filters.site') }}
              </label>
              <select
                v-model="filters.site"
                class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
              >
                <option value="">{{ t('producedBeerInventory.defaults.allSites') }}</option>
                <option
                  v-for="option in ownedSiteOptions"
                  :key="option.value"
                  :value="option.value"
                >
                  {{ option.label }}
                </option>
              </select>
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('producedBeerInventory.filters.package') }}
              </label>
              <select
                v-model="filters.packageId"
                class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
              >
                <option value="">{{ t('producedBeerInventory.defaults.allPackages') }}</option>
                <option v-for="option in packageOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>

            <label class="flex items-center gap-2 pt-7 text-sm text-gray-700">
              <input
                v-model="filters.showNonPackage"
                type="checkbox"
                class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
              />
              <span>{{ t('producedBeerInventory.filters.showNonPackage') }}</span>
            </label>
          </form>
        </section>

        <div class="flex items-center justify-between gap-3">
          <p class="text-sm text-gray-500">
            {{ t('producedBeerInventory.results.count', { count: sortedRows.length }) }}
          </p>
        </div>

        <section class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="px-3 py-2 text-left">
                  <button class="font-medium" type="button" @click="toggleSort('lotNo')">
                    {{ t('producedBeer.inventory.table.lotNo') }} {{ sortIndicator('lotNo') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-left">
                  <button class="font-medium" type="button" @click="toggleSort('lotTaxType')">
                    {{ t('producedBeer.inventory.table.lotTaxType') }}
                    {{ sortIndicator('lotTaxType') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-left">
                  <button class="font-medium" type="button" @click="toggleSort('batchCode')">
                    {{ t('producedBeer.inventory.table.batchNo') }} {{ sortIndicator('batchCode') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-left">
                  <button class="font-medium" type="button" @click="toggleSort('beerCategory')">
                    {{ t('producedBeer.inventory.table.beerCategory') }} {{ sortIndicator('beerCategory') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-right">
                  <button class="font-medium" type="button" @click="toggleSort('targetAbv')">
                    {{ t('producedBeer.inventory.table.targetAbv') }} {{ sortIndicator('targetAbv') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-left">
                  <button class="font-medium" type="button" @click="toggleSort('styleName')">
                    {{ t('producedBeer.inventory.table.styleName') }} {{ sortIndicator('styleName') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-left">
                  <button class="font-medium" type="button" @click="toggleSort('packageType')">
                    {{ t('producedBeer.inventory.table.packageType') }} {{ sortIndicator('packageType') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-left">
                  <button class="font-medium" type="button" @click="toggleSort('productionDate')">
                    {{ t('producedBeer.inventory.table.productionDate') }} {{ sortIndicator('productionDate') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-right">
                  <button class="font-medium" type="button" @click="toggleSort('qtyLiters')">
                    {{ t('producedBeer.inventory.table.qtyLiters') }} {{ sortIndicator('qtyLiters') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-right">
                  <button class="font-medium" type="button" @click="toggleSort('qtyPackages')">
                    {{ t('producedBeer.inventory.table.qtyPackages') }} {{ sortIndicator('qtyPackages') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-left">
                  <button class="font-medium" type="button" @click="toggleSort('site')">
                    {{ t('producedBeer.inventory.table.site') }} {{ sortIndicator('site') }}
                  </button>
                </th>
                <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 bg-white">
              <tr v-if="inventoryLoading">
                <td colspan="12" class="px-3 py-8 text-center text-gray-500">
                  {{ t('common.loading') }}
                </td>
              </tr>
              <tr v-else-if="sortedRows.length === 0">
                <td colspan="12" class="px-3 py-8 text-center text-gray-500">
                  {{ t('common.noData') }}
                </td>
              </tr>
              <tr v-for="row in sortedRows" v-else :key="row.id" class="hover:bg-gray-50">
                <td class="px-3 py-2 font-mono text-xs text-gray-600">{{ row.lotNo || '—' }}</td>
                <td class="px-3 py-2 font-mono text-xs text-gray-600">
                  {{ row.lotTaxType || '—' }}
                </td>
                <td class="px-3 py-2 font-mono text-xs text-gray-600">
                  {{ row.batchCode || '—' }}
                </td>
                <td class="px-3 py-2">{{ categoryLabel(row.beerCategoryId) }}</td>
                <td class="px-3 py-2 text-right">{{ formatAbv(row.targetAbv) }}</td>
                <td class="px-3 py-2">{{ row.styleName || row.productName || '—' }}</td>
                <td class="px-3 py-2">{{ row.packageTypeLabel || '—' }}</td>
                <td class="px-3 py-2 text-xs text-gray-500">
                  {{ formatDate(row.productionDate) }}
                </td>
                <td class="px-3 py-2 text-right">{{ formatVolumeNumberValue(row.qtyLiters) }}</td>
                <td class="px-3 py-2 text-right">{{ formatNumber(row.qtyPackages) }}</td>
                <td class="px-3 py-2">{{ siteLabel(row.siteId) }}</td>
                <td class="px-3 py-2 space-x-2">
                  <button
                    class="px-2 py-1 text-xs rounded border hover:bg-gray-100"
                    type="button"
                    @click="openDagDialog(row)"
                  >
                    {{ t('producedBeerInventory.actions.showDag') }}
                  </button>
                  <button
                    class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700 disabled:opacity-50"
                    type="button"
                    :disabled="zeroingLotId === row.lotId"
                    @click="setLotQtyZero(row)"
                  >
                    {{
                      zeroingLotId === row.lotId
                        ? t('common.saving')
                        : t('producedBeerInventory.actions.void')
                    }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </section>
      </section>

      <Modal v-if="dagDialog.open" :fullScreenBackdrop="true" @close="closeDagDialog">
        <template #body>
          <div class="relative z-[100000] w-full max-w-6xl px-4 py-6">
            <section class="mx-auto max-h-[85vh] overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-2xl">
              <header class="flex flex-col gap-3 border-b border-gray-200 px-5 py-4 md:flex-row md:items-start md:justify-between">
                <div>
                  <h2 class="text-lg font-semibold text-gray-900">
                    {{ t('producedBeerInventory.dag.title') }}
                  </h2>
                  <p class="text-sm text-gray-500">{{ t('producedBeerInventory.dag.subtitle') }}</p>
                  <p class="text-xs text-gray-500 mt-1">{{ dagDialogSummary }}</p>
                </div>
                <button
                  class="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
                  type="button"
                  @click="closeDagDialog"
                >
                  {{ t('common.close') }}
                </button>
              </header>

              <div class="space-y-4 overflow-y-auto px-5 py-4">
                <div v-if="dagDialog.error" class="text-sm text-red-600">{{ dagDialog.error }}</div>
                <div v-else-if="dagDialog.loading" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
                <template v-else>
                  <section class="rounded-xl border border-gray-200 bg-gray-50/70 p-4">
                    <h3 class="text-sm font-semibold text-gray-900">
                      {{ t('producedBeerInventory.dag.rootLot') }}
                    </h3>
                    <div class="mt-2 grid grid-cols-1 gap-3 md:grid-cols-5 text-sm">
                      <div>
                        <div class="text-xs text-gray-500">{{ t('producedBeer.inventory.table.lotNo') }}</div>
                        <div class="font-mono text-gray-700">{{ dagDialog.rootLot?.lotNo || '—' }}</div>
                      </div>
                      <div>
                        <div class="text-xs text-gray-500">{{ t('producedBeer.inventory.table.lotTaxType') }}</div>
                        <div class="font-mono text-gray-700">{{ dagDialog.rootLot?.lotTaxType || '—' }}</div>
                      </div>
                      <div>
                        <div class="text-xs text-gray-500">{{ t('producedBeer.inventory.table.site') }}</div>
                        <div class="text-gray-700">{{ siteLabel(dagDialog.rootLot?.siteId) }}</div>
                      </div>
                      <div>
                        <div class="text-xs text-gray-500">{{ t('producedBeer.inventory.table.qtyLiters') }}</div>
                        <div class="text-gray-700">{{ formatVolumeNumberValue(dagDialog.rootLot?.qty) }}</div>
                      </div>
                      <div>
                        <div class="text-xs text-gray-500">{{ t('producedBeerInventory.dag.table.status') }}</div>
                        <div class="text-gray-700">{{ dagDialog.rootLot?.status || '—' }}</div>
                      </div>
                    </div>
                  </section>

                  <section class="space-y-3">
                    <div class="flex items-center justify-between gap-3">
                      <h3 class="text-sm font-semibold text-gray-900">
                        {{ t('producedBeerInventory.dag.movementsTitle') }}
                      </h3>
                      <p class="text-xs text-gray-500">
                        {{ t('producedBeerInventory.results.count', { count: dagDialog.movements.length }) }}
                      </p>
                    </div>
                    <div class="overflow-x-auto rounded-xl border border-gray-200">
                      <table class="min-w-full divide-y divide-gray-200 text-sm">
                        <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                          <tr>
                            <th class="px-3 py-2 text-left">{{ t('producedBeerInventory.dag.table.occurredAt') }}</th>
                            <th class="px-3 py-2 text-left">{{ t('producedBeerInventory.dag.table.relationType') }}</th>
                            <th class="px-3 py-2 text-left">{{ t('producedBeerInventory.dag.table.docNo') }}</th>
                            <th class="px-3 py-2 text-left">{{ t('producedBeerInventory.dag.table.docType') }}</th>
                            <th class="px-3 py-2 text-left">{{ t('producedBeerInventory.dag.table.source') }}</th>
                            <th class="px-3 py-2 text-left">{{ t('producedBeerInventory.dag.table.destination') }}</th>
                            <th class="px-3 py-2 text-left">{{ t('producedBeerInventory.dag.table.relatedLot') }}</th>
                            <th class="px-3 py-2 text-left">{{ t('producedBeerInventory.dag.table.status') }}</th>
                          </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-100 bg-white">
                          <tr v-if="dagDialog.movements.length === 0">
                            <td colspan="8" class="px-3 py-8 text-center text-gray-500">
                              {{ t('producedBeerInventory.dag.noData') }}
                            </td>
                          </tr>
                          <tr v-for="row in dagDialog.movements" v-else :key="row.key" class="hover:bg-gray-50">
                            <td class="px-3 py-2 text-gray-600">{{ formatDateTime(row.occurredAt) }}</td>
                            <td class="px-3 py-2 text-gray-700">{{ row.relationType || '—' }}</td>
                            <td class="px-3 py-2 font-mono text-xs text-gray-600">{{ row.docNo || '—' }}</td>
                            <td class="px-3 py-2 text-gray-700">{{ row.docType || '—' }}</td>
                            <td class="px-3 py-2 text-gray-700">{{ row.srcSiteLabel }}</td>
                            <td class="px-3 py-2 text-gray-700">{{ row.destSiteLabel }}</td>
                            <td class="px-3 py-2 font-mono text-xs text-gray-600">{{ row.relatedLotLabel }}</td>
                            <td class="px-3 py-2 text-gray-700">{{ row.status || '—' }}</td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </section>

                  <section class="space-y-3">
                    <h3 class="text-sm font-semibold text-gray-900">
                      {{ t('producedBeerInventory.dag.relatedLotsTitle') }}
                    </h3>
                    <div class="overflow-x-auto rounded-xl border border-gray-200">
                      <table class="min-w-full divide-y divide-gray-200 text-sm">
                        <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                          <tr>
                            <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.lotNo') }}</th>
                            <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.lotTaxType') }}</th>
                            <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.site') }}</th>
                            <th class="px-3 py-2 text-right">{{ t('producedBeer.inventory.table.qtyLiters') }}</th>
                            <th class="px-3 py-2 text-left">{{ t('producedBeerInventory.dag.table.status') }}</th>
                          </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-100 bg-white">
                          <tr v-if="dagDialog.relatedLots.length === 0">
                            <td colspan="5" class="px-3 py-8 text-center text-gray-500">
                              {{ t('producedBeerInventory.dag.noData') }}
                            </td>
                          </tr>
                          <tr v-for="row in dagDialog.relatedLots" v-else :key="row.id" class="hover:bg-gray-50">
                            <td class="px-3 py-2 font-mono text-xs text-gray-600">{{ row.lotNo || '—' }}</td>
                            <td class="px-3 py-2 font-mono text-xs text-gray-600">{{ row.lotTaxType || '—' }}</td>
                            <td class="px-3 py-2 text-gray-700">{{ siteLabel(row.siteId) }}</td>
                            <td class="px-3 py-2 text-right text-gray-700">{{ formatVolumeNumberValue(row.qty) }}</td>
                            <td class="px-3 py-2 text-gray-700">{{ row.status || '—' }}</td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </section>
                </template>
              </div>
            </section>
          </div>
        </template>
      </Modal>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import Modal from '@/components/ui/Modal.vue'
import { supabase } from '@/lib/supabase'
import { useProducedBeerInventory } from '@/composables/useProducedBeerInventory'
import { toast } from 'vue3-toastify'

const { t } = useI18n()
const pageTitle = computed(() => t('producedBeerInventory.title'))

const {
  categoryLabel,
  formatAbv,
  formatDate,
  formatNumber,
  formatVolumeNumberValue,
  initialize,
  inventoryLoading,
  inventoryRows,
  loadInventory,
  ownedSiteOptions,
  packageOptions,
  siteLabel,
} = useProducedBeerInventory()

type InventoryPageRow = (typeof inventoryRows.value)[number]

type SortKey =
  | 'lotNo'
  | 'lotTaxType'
  | 'batchCode'
  | 'beerCategory'
  | 'targetAbv'
  | 'styleName'
  | 'packageType'
  | 'productionDate'
  | 'qtyLiters'
  | 'qtyPackages'
  | 'site'

type TraceLotNode = {
  id: string
  lotNo: string | null
  lotTaxType: string | null
  siteId: string | null
  qty: number | null
  status: string | null
}

type TraceMovementRow = {
  key: string
  occurredAt: string | null
  relationType: string | null
  docNo: string | null
  docType: string | null
  status: string | null
  srcSiteLabel: string
  destSiteLabel: string
  relatedLotLabel: string
}

const filters = reactive({
  keyword: '',
  product: '',
  site: '',
  packageId: '',
  showNonPackage: false,
})

const sortState = reactive<{
  key: SortKey
  direction: 'asc' | 'desc'
}>({
  key: 'productionDate',
  direction: 'desc',
})

const zeroingLotId = ref('')

const dagDialog = reactive({
  open: false,
  loading: false,
  error: '',
  rootRow: null as InventoryPageRow | null,
  rootLot: null as TraceLotNode | null,
  relatedLots: [] as TraceLotNode[],
  movements: [] as TraceMovementRow[],
})

function productFilterValue(row: InventoryPageRow) {
  return row.productName || row.styleName || row.batchCode || row.lotNo || ''
}

const productOptions = computed(() => {
  const seen = new Set<string>()
  return inventoryRows.value
    .map((row) => {
      const value = productFilterValue(row)
      return { value, label: value }
    })
    .filter((option) => option.value)
    .filter((option) => {
      if (seen.has(option.value)) return false
      seen.add(option.value)
      return true
    })
    .sort((a, b) => a.label.localeCompare(b.label))
})

const filteredRows = computed(() => {
  const keyword = filters.keyword.trim().toLowerCase()
  return inventoryRows.value.filter((row) => {
    if (keyword && !row.keywordIndex.includes(keyword)) return false
    if (filters.product && productFilterValue(row) !== filters.product) return false
    if (filters.site && row.siteId !== filters.site) return false
    if (filters.packageId && row.packageId !== filters.packageId) return false
    if (!filters.showNonPackage && !row.packageId) return false
    return true
  })
})

function normalizeString(value: string | null | undefined) {
  return (value ?? '').toLowerCase()
}

function compareValues(a: string | number, b: string | number) {
  if (typeof a === 'number' && typeof b === 'number') return a - b
  return String(a).localeCompare(String(b))
}

function sortValue(row: InventoryPageRow, key: SortKey): string | number {
  switch (key) {
    case 'lotNo':
      return normalizeString(row.lotNo)
    case 'lotTaxType':
      return normalizeString(row.lotTaxType)
    case 'batchCode':
      return normalizeString(row.batchCode)
    case 'beerCategory':
      return normalizeString(categoryLabel(row.beerCategoryId))
    case 'targetAbv':
      return row.targetAbv ?? Number.NEGATIVE_INFINITY
    case 'styleName':
      return normalizeString(row.styleName || row.productName)
    case 'packageType':
      return normalizeString(row.packageTypeLabel)
    case 'productionDate':
      return row.productionDate ? Date.parse(row.productionDate) : Number.NEGATIVE_INFINITY
    case 'qtyLiters':
      return row.qtyLiters ?? Number.NEGATIVE_INFINITY
    case 'qtyPackages':
      return row.qtyPackages ?? Number.NEGATIVE_INFINITY
    case 'site':
      return normalizeString(siteLabel(row.siteId))
  }
}

const sortedRows = computed(() =>
  [...filteredRows.value].sort((a, b) => {
    const result = compareValues(sortValue(a, sortState.key), sortValue(b, sortState.key))
    return sortState.direction === 'asc' ? result : -result
  }),
)

const dagDialogSummary = computed(() => {
  const root = dagDialog.rootRow
  if (!root) return ''
  return `${root.lotNo || '—'} / ${root.batchCode || '—'}`
})

function toggleSort(key: SortKey) {
  if (sortState.key === key) {
    sortState.direction = sortState.direction === 'asc' ? 'desc' : 'asc'
    return
  }
  sortState.key = key
  sortState.direction = key === 'productionDate' ? 'desc' : 'asc'
}

function sortIndicator(key: SortKey) {
  if (sortState.key !== key) return ''
  return sortState.direction === 'asc' ? '^' : 'v'
}

function toNumber(value: unknown): number | null {
  if (value == null || value === '') return null
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : null
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
  } catch {
    return value
  }
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

function closeDagDialog() {
  dagDialog.open = false
  dagDialog.loading = false
  dagDialog.error = ''
  dagDialog.rootRow = null
  dagDialog.rootLot = null
  dagDialog.relatedLots = []
  dagDialog.movements = []
}

async function openDagDialog(row: InventoryPageRow) {
  dagDialog.open = true
  dagDialog.loading = true
  dagDialog.error = ''
  dagDialog.rootRow = row
  dagDialog.rootLot = null
  dagDialog.relatedLots = []
  dagDialog.movements = []

  try {
    const { data, error } = await supabase.rpc('lot_trace_full', {
      p_lot_id: row.lotId,
      p_max_depth: 10,
    })
    if (error) throw error

    const payload = Array.isArray(data)
      ? ((data[0] && typeof data[0] === 'object') ? data[0] as Record<string, any> : {})
      : ((data && typeof data === 'object') ? data as Record<string, any> : {})

    const nodes = Array.isArray(payload.nodes)
      ? payload.nodes
          .map((node: any) => ({
            id: String(node?.id ?? ''),
            lotNo: node?.lot_no != null ? String(node.lot_no) : null,
            lotTaxType: node?.lot_tax_type != null ? String(node.lot_tax_type) : null,
            siteId: node?.site_id != null ? String(node.site_id) : null,
            qty: toNumber(node?.qty),
            status: node?.status != null ? String(node.status) : null,
          }))
          .filter((node: TraceLotNode) => node.id)
      : []

    const rootLot = nodes.find((node: TraceLotNode) => node.id === row.lotId) ?? {
      id: row.lotId,
      lotNo: row.lotNo,
      lotTaxType: row.lotTaxType,
      siteId: row.siteId,
      qty: row.qtyLiters,
      status: 'active',
    }
    dagDialog.rootLot = rootLot
    dagDialog.relatedLots = nodes.filter((node: TraceLotNode) => node.id !== row.lotId)

    const edges = Array.isArray(payload.edges)
      ? payload.edges
          .map((edge: any) => ({
            key: [
              String(edge?.movement_id ?? ''),
              String(edge?.related_lot_id ?? ''),
              String(edge?.relation_type ?? ''),
              String(edge?.occurred_at ?? ''),
            ].join('__'),
            movementId: edge?.movement_id != null ? String(edge.movement_id) : null,
            relatedLotId: edge?.related_lot_id != null ? String(edge.related_lot_id) : null,
            relationType: edge?.relation_type != null ? String(edge.relation_type) : null,
            occurredAt: edge?.occurred_at != null ? String(edge.occurred_at) : null,
          }))
      : []

    const movementIds = Array.from(
      new Set(
        edges
          .map((edge: any) => edge.movementId)
          .filter((value: string | null): value is string => typeof value === 'string' && value.length > 0),
      ),
    )

    const movementMap = new Map<string, any>()
    if (movementIds.length) {
      const { data: movementRows, error: movementError } = await supabase
        .from('inv_movements')
        .select('id, doc_no, doc_type, status, movement_at, src_site_id, dest_site_id')
        .in('id', movementIds)
      if (movementError) throw movementError
      ;(movementRows ?? []).forEach((movement: any) => {
        if (!movement?.id) return
        movementMap.set(String(movement.id), movement)
      })
    }

    dagDialog.movements = edges
      .filter((edge: any) => edge.movementId)
      .map((edge: any) => {
        const movement = movementMap.get(edge.movementId as string)
        const relatedLot = dagDialog.relatedLots.find((node) => node.id === edge.relatedLotId)
        return {
          key: edge.key,
          occurredAt: edge.occurredAt ?? movement?.movement_at ?? null,
          relationType: edge.relationType,
          docNo: movement?.doc_no != null ? String(movement.doc_no) : null,
          docType: movement?.doc_type != null ? String(movement.doc_type) : null,
          status: movement?.status != null ? String(movement.status) : null,
          srcSiteLabel: siteLabel(movement?.src_site_id ?? null),
          destSiteLabel: siteLabel(movement?.dest_site_id ?? null),
          relatedLotLabel: relatedLot?.lotNo || edge.relatedLotId || '—',
        } as TraceMovementRow
      })
      .sort((a, b) => {
        const aValue = a.occurredAt ? Date.parse(a.occurredAt) : Number.NEGATIVE_INFINITY
        const bValue = b.occurredAt ? Date.parse(b.occurredAt) : Number.NEGATIVE_INFINITY
        return bValue - aValue
      })
  } catch (err) {
    const detail = extractErrorMessage(err)
    dagDialog.error = detail
      ? `${t('producedBeerInventory.dag.loadFailed')} (${detail})`
      : t('producedBeerInventory.dag.loadFailed')
  } finally {
    dagDialog.loading = false
  }
}

async function setLotQtyZero(row: InventoryPageRow) {
  const target = row.lotNo || row.batchCode || row.id
  if (!window.confirm(t('producedBeerInventory.voidConfirm', { lot: target }))) return
  try {
    zeroingLotId.value = row.lotId
    const { error } = await supabase.rpc('inventory_lot_void', {
      p_lot_id: row.lotId,
      p_site_id: row.siteId,
      p_reason: 'manual_set_qty_zero_from_inventory_page',
    })
    if (error) throw error
    if (dagDialog.rootRow?.lotId === row.lotId) closeDagDialog()
    await loadInventory()
    toast.success(t('producedBeerInventory.voidSuccess'))
  } catch (err) {
    const detail = extractErrorMessage(err)
    toast.error(
      detail
        ? `${t('producedBeerInventory.voidFailed')} (${detail})`
        : t('producedBeerInventory.voidFailed'),
    )
  } finally {
    zeroingLotId.value = ''
  }
}

onMounted(async () => {
  await initialize()
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
