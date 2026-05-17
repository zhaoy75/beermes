<template>
  <Modal :fullScreenBackdrop="true" @close="emit('close')">
    <template #body>
      <div class="relative z-[100000] w-full max-w-7xl px-4 py-6">
        <section
          ref="dialogRef"
          class="mx-auto max-h-[85vh] overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-2xl"
          role="dialog"
          aria-modal="true"
          tabindex="-1"
          :aria-label="t('inventorySearchModal.title')"
          @keydown.capture="handleModalKeydown"
        >
          <header
            class="flex flex-col gap-3 border-b border-gray-200 px-5 py-4 md:flex-row md:items-start md:justify-between"
          >
            <div>
              <h2 class="text-lg font-semibold text-gray-900">
                {{ t('inventorySearchModal.title') }}
              </h2>
              <p class="text-sm text-gray-500">{{ t('inventorySearchModal.subtitle') }}</p>
            </div>
            <div class="flex items-center gap-2">
              <span
                class="hidden rounded-full border border-gray-200 px-3 py-1 text-xs text-gray-500 md:inline-flex"
              >
                {{ t('inventorySearchModal.shortcuts.closeHint') }}
              </span>
              <button
                class="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
                type="button"
                @click="emit('close')"
              >
                {{ t('common.close') }}
              </button>
            </div>
          </header>

          <div class="space-y-4 overflow-y-auto px-5 py-4">
            <section class="rounded-xl border border-gray-200 bg-gray-50/70 p-4">
              <form class="grid grid-cols-1 gap-4 md:grid-cols-5" @submit.prevent>
                <div>
                  <label class="mb-1 block text-sm text-gray-600">
                    {{ t('inventorySearchModal.fields.keyword') }}
                  </label>
                  <input
                    ref="keywordInputRef"
                    v-model.trim="filters.keyword"
                    type="search"
                    class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
                    :placeholder="t('inventorySearchModal.placeholders.keyword')"
                  />
                </div>

                <div>
                  <label class="mb-1 block text-sm text-gray-600">
                    {{ t('inventorySearchModal.fields.product') }}
                  </label>
                  <select
                    v-model="filters.product"
                    class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
                  >
                    <option value="">{{ t('inventorySearchModal.defaults.allProducts') }}</option>
                    <option
                      v-for="option in productOptions"
                      :key="option.value"
                      :value="option.value"
                    >
                      {{ option.label }}
                    </option>
                  </select>
                </div>

                <div>
                  <label class="mb-1 block text-sm text-gray-600">
                    {{ t('inventorySearchModal.fields.site') }}
                  </label>
                  <select
                    v-model="filters.site"
                    class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
                    :disabled="siteLocked"
                  >
                    <option value="">{{ t('inventorySearchModal.defaults.allSites') }}</option>
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
                    {{ t('inventorySearchModal.fields.package') }}
                  </label>
                  <select
                    v-model="filters.packageId"
                    class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
                  >
                    <option value="">{{ t('inventorySearchModal.defaults.allPackages') }}</option>
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

            <section class="space-y-3">
              <div class="flex items-center justify-between gap-3">
                <p class="text-sm text-gray-500">
                  {{ t('inventorySearchModal.results.count', { count: sortedRows.length }) }}
                </p>
                <div class="flex flex-wrap items-center justify-end gap-2">
                  <div
                    v-if="selectedResultRows.length > 0"
                    class="flex flex-wrap items-center justify-end gap-2 rounded-lg border border-blue-200 bg-blue-50 px-3 py-2 text-sm text-blue-900"
                  >
                    <span class="font-medium">
                      {{ t('inventorySearchModal.bulk.selected', { count: selectedResultRows.length }) }}
                    </span>
                    <button
                      class="text-blue-700 underline-offset-2 hover:underline"
                      type="button"
                      @click="clearSelectedResultRows"
                    >
                      {{ t('inventorySearchModal.bulk.clearSelection') }}
                    </button>
                    <button
                      v-if="canApplySelection"
                      class="rounded-lg bg-blue-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-blue-700"
                      type="button"
                      @click="applySelectedResultRows"
                    >
                      {{ applySelectionLabel || t('inventorySearchModal.bulk.applySelected') }}
                    </button>
                  </div>
                  <button
                    class="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50"
                    type="button"
                    :disabled="inventoryLoading"
                    @click="loadInventory"
                  >
                    {{ t('common.refresh') }}
                  </button>
                </div>
              </div>

              <div class="max-h-[48vh] overflow-auto rounded-xl border border-gray-200">
                <table class="compact-table min-w-full divide-y divide-gray-200 text-sm">
                  <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                    <tr>
                      <th class="w-10 px-3 py-2 text-center">
                        <input
                          type="checkbox"
                          class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                          :checked="allVisibleResultRowsSelected"
                          :disabled="sortedRows.length === 0"
                          :aria-label="t('inventorySearchModal.bulk.selectVisible')"
                          @change="toggleVisibleResultRows"
                        />
                      </th>
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
                        <button class="font-medium" type="button" @click="toggleSort('actualAbv')">
                          {{ t('producedBeer.inventory.table.actualAbv') }} {{ sortIndicator('actualAbv') }}
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
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100 bg-white">
                    <tr v-if="inventoryLoading">
                      <td :colspan="resultColumnCount" class="px-3 py-8 text-center text-gray-500">
                        {{ t('common.loading') }}
                      </td>
                    </tr>
                    <tr v-else-if="sortedRows.length === 0">
                      <td :colspan="resultColumnCount" class="px-3 py-8 text-center text-gray-500">
                        {{ t('common.noData') }}
                      </td>
                    </tr>
                    <template v-for="row in sortedRows" :key="row.id">
                      <tr
                        :ref="(el) => setResultRowRef(row.id, el)"
                        class="hover:bg-gray-50"
                        :class="{
                          'cursor-pointer': selectable,
                          'bg-blue-50 ring-1 ring-inset ring-blue-200': activeRowId === row.id,
                          'bg-blue-50/70': selectedResultRowIdSet.has(row.id),
                        }"
                        :tabindex="selectable ? 0 : -1"
                        :role="selectable ? 'button' : undefined"
                        @click="setActiveRow(row.id)"
                        @dblclick.stop.prevent="handleRowDoubleClick(row)"
                        @keydown.enter.prevent="handleRowDoubleClick(row)"
                      >
                        <td class="px-3 py-2 text-center">
                          <input
                            type="checkbox"
                            class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                            :checked="selectedResultRowIdSet.has(row.id)"
                            :aria-label="t('inventorySearchModal.bulk.selectRow')"
                            @click.stop
                            @keydown.stop
                            @change.stop="toggleResultRowSelection(row)"
                          />
                        </td>
                        <td class="px-3 py-2 text-gray-600">
                          <div class="flex items-center justify-between gap-2">
                            <div class="font-mono text-xs">{{ row.lotNo || '—' }}</div>
                            <button
                              v-if="row.mergedCount > 1"
                              class="rounded border border-gray-300 px-1.5 py-0.5 text-[11px] hover:bg-gray-100"
                              type="button"
                              :title="
                                isExpanded(row.id)
                                  ? t('producedBeerInventory.merge.collapse')
                                  : t('producedBeerInventory.merge.expand')
                              "
                              @click.stop="toggleExpanded(row.id)"
                            >
                              {{ isExpanded(row.id) ? 'v' : '>' }}
                            </button>
                          </div>
                          <div class="text-[11px] text-gray-400">{{ rowDisambiguationText(row) }}</div>
                        </td>
                        <td class="px-3 py-2 font-mono text-xs text-gray-600">
                          {{ lotTaxTypeLabel(row.lotTaxType) }}
                        </td>
                        <td class="px-3 py-2 font-mono text-xs text-gray-600">
                          {{ row.batchCode || '—' }}
                        </td>
                        <CompactTableCell
                          :value="categoryLabel(row.beerCategoryId)"
                          text-column="beerCategory"
                          truncate
                          focusable
                        />
                        <td class="px-3 py-2 text-right">{{ formatAbv(row.actualAbv) }}</td>
                        <CompactTableCell
                          :value="row.styleName || row.productName"
                          text-column="styleName"
                          truncate
                          focusable
                        />
                        <CompactTableCell
                          :value="row.packageTypeLabel"
                          text-column="packageType"
                          truncate
                          focusable
                        />
                        <td class="px-3 py-2 text-xs text-gray-500">
                          {{ formatDate(row.productionDate) }}
                        </td>
                        <td class="px-3 py-2 text-right">{{ formatVolumeNumberValue(row.qtyLiters) }}</td>
                        <td class="px-3 py-2 text-right">{{ formatNumber(row.qtyPackages) }}</td>
                        <CompactTableCell
                          :value="siteLabel(row.siteId)"
                          text-column="site"
                          truncate
                          focusable
                        />
                      </tr>
                      <tr v-if="isExpanded(row.id)" class="bg-gray-50/80">
                        <td :colspan="resultColumnCount" class="px-4 py-3">
                          <div class="rounded-lg border border-gray-200 bg-white">
                            <div class="border-b border-gray-200 px-3 py-2 text-xs font-medium text-gray-600">
                              {{ t('producedBeerInventory.merge.detailsTitle') }}
                            </div>
                            <div class="overflow-x-auto">
                              <table class="min-w-full divide-y divide-gray-200 text-xs">
                                <thead class="bg-gray-50 text-gray-600">
                                  <tr>
                                    <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.lotNo') }}</th>
                                    <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.lotTaxType') }}</th>
                                    <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.productionDate') }}</th>
                                    <th class="px-3 py-2 text-right">{{ t('producedBeer.inventory.table.qtyLiters') }}</th>
                                    <th class="px-3 py-2 text-right">{{ t('producedBeer.inventory.table.qtyPackages') }}</th>
                                  </tr>
                                </thead>
                                <tbody class="divide-y divide-gray-100 bg-white">
                                  <tr
                                    v-for="detail in row.mergedDetails"
                                    :key="detail.id"
                                    :class="{ 'cursor-pointer hover:bg-blue-50': selectable }"
                                    @dblclick.stop.prevent="handleMergedDetailDoubleClick(row, detail)"
                                  >
                                    <td class="px-3 py-2 font-mono text-gray-600">{{ detail.lotNo || '—' }}</td>
                                    <td class="px-3 py-2 font-mono text-gray-600">{{ lotTaxTypeLabel(detail.lotTaxType) }}</td>
                                    <td class="px-3 py-2 text-gray-500">{{ formatDate(detail.productionDate) }}</td>
                                    <td class="px-3 py-2 text-right text-gray-700">{{ formatVolumeNumberValue(detail.qtyLiters) }}</td>
                                    <td class="px-3 py-2 text-right text-gray-700">{{ formatNumber(detail.qtyPackages) }}</td>
                                  </tr>
                                </tbody>
                              </table>
                            </div>
                          </div>
                        </td>
                      </tr>
                    </template>
                  </tbody>
                </table>
              </div>
            </section>
          </div>
        </section>
      </div>
    </template>
  </Modal>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import CompactTableCell from '@/components/common/CompactTableCell.vue'
import Modal from '@/components/ui/Modal.vue'
import { useRuleengineLabels } from '@/composables/useRuleengineLabels'
import { useProducedBeerInventory } from '@/composables/useProducedBeerInventory'

import type { InventorySearchSelection } from '@/composables/useInventorySearchModal'

const props = withDefaults(
  defineProps<{
    siteId?: string
    siteLocked?: boolean
    selectable?: boolean
    canApplySelection?: boolean
    applySelectionLabel?: string
  }>(),
  {
    siteId: '',
    siteLocked: false,
    selectable: false,
    canApplySelection: false,
    applySelectionLabel: '',
  },
)

const emit = defineEmits<{
  close: []
  select: [row: InventorySearchSelection]
  selectMany: [rows: InventorySearchSelection[]]
}>()

const { t } = useI18n()
const { loadRuleengineLabels, ruleLabel } = useRuleengineLabels()
const keywordInputRef = ref<HTMLInputElement | null>(null)
const dialogRef = ref<HTMLElement | null>(null)
const activeRowId = ref('')
const resultRowRefs = new Map<string, HTMLTableRowElement>()
const expandedRowIds = ref<string[]>([])
const selectedResultRowIds = ref<string[]>([])

const filters = reactive({
  keyword: '',
  product: '',
  site: '',
  packageId: '',
  showNonPackage: false,
})

const siteLocked = computed(() => props.siteLocked && !!props.siteId)
const selectable = computed(() => props.selectable)
const canApplySelection = computed(() => props.canApplySelection)
const resultColumnCount = 12

const sortState = reactive<{
  key:
    | 'lotNo'
    | 'lotTaxType'
    | 'batchCode'
    | 'beerCategory'
    | 'actualAbv'
    | 'styleName'
    | 'packageType'
    | 'productionDate'
    | 'qtyLiters'
    | 'qtyPackages'
    | 'site'
  direction: 'asc' | 'desc'
}>({
  key: 'productionDate',
  direction: 'desc',
})

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

function productFilterValue(row: (typeof inventoryRows.value)[number]) {
  return row.productName || row.styleName || row.batchCode || row.lotNo || ''
}

const productOptions = computed(() => {
  const seen = new Set<string>()
  return inventoryRows.value
    .map((row) => {
      const value = productFilterValue(row)
      return {
        value,
        label: value,
      }
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
  const activeSiteFilter = siteLocked.value ? props.siteId : filters.site

  return inventoryRows.value.filter((row) => {
    if (keyword && !row.keywordIndex.includes(keyword)) return false
    if (filters.product && productFilterValue(row) !== filters.product) return false
    if (activeSiteFilter && row.siteId !== activeSiteFilter) return false
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

function shortLotId(value: string | null | undefined) {
  if (!value) return '—'
  return value.slice(0, 8)
}

function rowDisambiguationText(row: (typeof inventoryRows.value)[number]) {
  if (row.mergedCount > 1) {
    return t('producedBeerInventory.merge.summary', { count: row.mergedCount })
  }
  const parts: string[] = []
  const site = row.siteId ? siteLabel(row.siteId) : ''
  if (site && site !== '—') parts.push(site)
  const producedAt = formatDate(row.productionDate)
  if (producedAt && producedAt !== '—') parts.push(producedAt)
  parts.push(`ID ${shortLotId(row.lotId)}`)
  return parts.join(' / ')
}

function sortValue(
  row: (typeof inventoryRows.value)[number],
  key: (typeof sortState)['key'],
): string | number {
  switch (key) {
    case 'lotNo':
      return normalizeString(row.lotNo)
    case 'lotTaxType':
      return normalizeString(row.lotTaxType)
    case 'batchCode':
      return normalizeString(row.batchCode)
    case 'beerCategory':
      return normalizeString(categoryLabel(row.beerCategoryId))
    case 'actualAbv':
      return row.actualAbv ?? Number.NEGATIVE_INFINITY
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
    if (result !== 0) return sortState.direction === 'asc' ? result : -result
    return a.lotId.localeCompare(b.lotId)
  }),
)

const selectedResultRowIdSet = computed(() => new Set(selectedResultRowIds.value))
const selectedResultRows = computed(() =>
  sortedRows.value.filter((row) => selectedResultRowIdSet.value.has(row.id)),
)
const allVisibleResultRowsSelected = computed(() => {
  if (!sortedRows.value.length) return false
  return sortedRows.value.every((row) => selectedResultRowIdSet.value.has(row.id))
})

function setResultRowRef(id: string, el: unknown) {
  if (el instanceof HTMLTableRowElement) {
    resultRowRefs.set(id, el)
    return
  }
  resultRowRefs.delete(id)
}

function setActiveRow(id: string) {
  activeRowId.value = id
}

function isExpanded(rowId: string) {
  return expandedRowIds.value.includes(rowId)
}

function toggleExpanded(rowId: string) {
  if (isExpanded(rowId)) {
    expandedRowIds.value = expandedRowIds.value.filter((id) => id !== rowId)
    return
  }
  expandedRowIds.value = [...expandedRowIds.value, rowId]
}

function scrollActiveRowIntoView() {
  const target = resultRowRefs.get(activeRowId.value)
  if (!target) return
  target.scrollIntoView({ block: 'nearest' })
}

function ensureActiveRow() {
  if (!sortedRows.value.length) {
    activeRowId.value = ''
    return
  }
  if (sortedRows.value.some((row) => row.id === activeRowId.value)) return
  activeRowId.value = sortedRows.value[0]?.id ?? ''
}

function moveActiveRow(direction: 1 | -1) {
  if (!sortedRows.value.length) return
  const currentIndex = sortedRows.value.findIndex((row) => row.id === activeRowId.value)
  if (currentIndex < 0) {
    activeRowId.value = direction > 0 ? sortedRows.value[0].id : sortedRows.value[sortedRows.value.length - 1].id
  } else {
    const nextIndex = Math.min(
      sortedRows.value.length - 1,
      Math.max(0, currentIndex + direction),
    )
    activeRowId.value = sortedRows.value[nextIndex].id
  }
  nextTick(() => scrollActiveRowIntoView())
}

function selectActiveRow() {
  if (!selectable.value || !activeRowId.value) return
  const row = sortedRows.value.find((entry) => entry.id === activeRowId.value)
  if (!row) return
  handleRowDoubleClick(row)
}

function toggleSort(key: (typeof sortState)['key']) {
  if (sortState.key === key) {
    sortState.direction = sortState.direction === 'asc' ? 'desc' : 'asc'
    return
  }
  sortState.key = key
  sortState.direction = key === 'productionDate' ? 'desc' : 'asc'
}

function sortIndicator(key: (typeof sortState)['key']) {
  if (sortState.key !== key) return ''
  return sortState.direction === 'asc' ? '^' : 'v'
}

function lotTaxTypeLabel(code: string | null | undefined) {
  return ruleLabel('lot_tax_type', code)
}

function clearSelectedResultRows() {
  selectedResultRowIds.value = []
}

function toggleResultRowSelection(row: (typeof inventoryRows.value)[number]) {
  const selected = new Set(selectedResultRowIds.value)
  if (selected.has(row.id)) selected.delete(row.id)
  else selected.add(row.id)
  selectedResultRowIds.value = Array.from(selected)
}

function toggleVisibleResultRows() {
  const selected = new Set(selectedResultRowIds.value)
  if (allVisibleResultRowsSelected.value) {
    sortedRows.value.forEach((row) => selected.delete(row.id))
  } else {
    sortedRows.value.forEach((row) => selected.add(row.id))
  }
  selectedResultRowIds.value = Array.from(selected)
}

function handleModalKeydown(event: KeyboardEvent) {
  if (event.defaultPrevented) return
  if (event.altKey || event.ctrlKey || event.metaKey) return
  const activeElement = document.activeElement
  if (
    activeElement instanceof HTMLSelectElement ||
    activeElement instanceof HTMLTextAreaElement ||
    (activeElement instanceof HTMLElement && activeElement.isContentEditable)
  ) {
    return
  }
  if (event.key === 'ArrowDown') {
    event.preventDefault()
    moveActiveRow(1)
    return
  }
  if (event.key === 'ArrowUp') {
    event.preventDefault()
    moveActiveRow(-1)
    return
  }
  if (event.key === 'Enter' && selectable.value && activeRowId.value) {
    event.preventDefault()
    selectActiveRow()
  }
}

function handleWindowKeydown(event: KeyboardEvent) {
  if (!dialogRef.value) return
  const target = event.target
  if (target instanceof Node && !dialogRef.value.contains(target)) return
  handleModalKeydown(event)
}

function handleRowDoubleClick(row: (typeof inventoryRows.value)[number]) {
  if (row.mergedCount > 1) {
    toggleExpanded(row.id)
    return
  }
  emitSelection(row, row)
}

function handleMergedDetailDoubleClick(
  row: (typeof inventoryRows.value)[number],
  detail: (typeof inventoryRows.value)[number]['mergedDetails'][number],
) {
  emitSelection(row, detail)
}

function emitSelection(
  row: (typeof inventoryRows.value)[number],
  detail: Pick<
    (typeof inventoryRows.value)[number]['mergedDetails'][number],
    'lotId' | 'lotNo' | 'siteId' | 'qtyLiters' | 'qtyPackages'
  >,
) {
  if (!selectable.value) return
  emit('select', toInventorySearchSelection(row, detail))
}

function toInventorySearchSelection(
  row: (typeof inventoryRows.value)[number],
  detail: Pick<
    (typeof inventoryRows.value)[number]['mergedDetails'][number],
    'lotId' | 'lotNo' | 'siteId' | 'qtyLiters' | 'qtyPackages'
  >,
): InventorySearchSelection {
  return {
    id: detail.lotId,
    lotId: detail.lotId,
    lotNo: detail.lotNo,
    batchCode: row.batchCode,
    productName: row.productName,
    styleName: row.styleName,
    packageId: row.packageId,
    packageTypeLabel: row.packageTypeLabel,
    siteId: detail.siteId,
    qtyLiters: detail.qtyLiters,
    qtyPackages: detail.qtyPackages,
  }
}

function selectionsForResultRow(row: (typeof inventoryRows.value)[number]) {
  const details = row.mergedDetails.length > 0 ? row.mergedDetails : [row]
  return details.map((detail) => toInventorySearchSelection(row, detail))
}

function applySelectedResultRows() {
  if (!canApplySelection.value || selectedResultRows.value.length === 0) return
  const uniqueRows = new Map<string, InventorySearchSelection>()
  selectedResultRows.value
    .flatMap((row) => selectionsForResultRow(row))
    .forEach((row) => {
      uniqueRows.set(row.lotId, row)
    })
  const rows = Array.from(uniqueRows.values())
  if (!rows.length) return
  emit('selectMany', rows)
}

async function focusFirstField() {
  await nextTick()
  dialogRef.value?.focus()
  keywordInputRef.value?.focus()
  keywordInputRef.value?.select()
}

defineExpose({
  focusFirstField,
})

watch(
  () => [props.siteId, props.siteLocked] as const,
  ([siteId, locked]) => {
    if (!locked) return
    filters.site = siteId ?? ''
  },
  { immediate: true },
)

watch(
  sortedRows,
  () => {
    ensureActiveRow()
    const visibleIds = new Set(sortedRows.value.map((row) => row.id))
    selectedResultRowIds.value = selectedResultRowIds.value.filter((id) => visibleIds.has(id))
    nextTick(() => scrollActiveRowIntoView())
  },
  { immediate: true },
)

onMounted(async () => {
  await Promise.all([initialize(), loadRuleengineLabels()])
  if (siteLocked.value) {
    filters.site = props.siteId
  }
  await focusFirstField()
  window.addEventListener('keydown', handleWindowKeydown, true)
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', handleWindowKeydown, true)
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}

.compact-table :is(th, td) {
  padding: 0.375rem 0.5rem;
}

.compact-table tbody tr {
  min-height: 2.25rem;
}
</style>
