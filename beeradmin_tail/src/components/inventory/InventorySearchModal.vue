<template>
  <Modal :fullScreenBackdrop="true" @close="emit('close')">
    <template #body>
      <div class="relative z-[100000] w-full max-w-7xl px-4 py-6">
        <section
          class="mx-auto max-h-[85vh] overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-2xl"
          role="dialog"
          aria-modal="true"
          :aria-label="t('inventorySearchModal.title')"
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
              <form class="grid grid-cols-1 gap-4 md:grid-cols-4" @submit.prevent>
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
              </form>
            </section>

            <section class="space-y-3">
              <div class="flex items-center justify-between gap-3">
                <p class="text-sm text-gray-500">
                  {{ t('inventorySearchModal.results.count', { count: sortedRows.length }) }}
                </p>
                <button
                  class="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50"
                  type="button"
                  :disabled="inventoryLoading"
                  @click="loadInventory"
                >
                  {{ t('common.refresh') }}
                </button>
              </div>

              <div class="overflow-x-auto rounded-xl border border-gray-200">
                <table class="min-w-full divide-y divide-gray-200 text-sm">
                  <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                    <tr>
                      <th class="px-3 py-2 text-left">
                        <button class="font-medium" type="button" @click="toggleSort('lotNo')">
                          {{ t('producedBeer.inventory.table.lotNo') }} {{ sortIndicator('lotNo') }}
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
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100 bg-white">
                    <tr v-if="inventoryLoading">
                      <td colspan="10" class="px-3 py-8 text-center text-gray-500">
                        {{ t('common.loading') }}
                      </td>
                    </tr>
                    <tr v-else-if="sortedRows.length === 0">
                      <td colspan="10" class="px-3 py-8 text-center text-gray-500">
                        {{ t('common.noData') }}
                      </td>
                    </tr>
                    <tr v-for="row in sortedRows" v-else :key="row.id" class="hover:bg-gray-50">
                      <td class="px-3 py-2 font-mono text-xs text-gray-600">
                        {{ row.lotNo || '—' }}
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
                      <td class="px-3 py-2 text-right">{{ formatNumber(row.qtyLiters) }}</td>
                      <td class="px-3 py-2 text-right">{{ formatNumber(row.qtyPackages) }}</td>
                      <td class="px-3 py-2">{{ siteLabel(row.siteId) }}</td>
                    </tr>
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
import { computed, nextTick, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import Modal from '@/components/ui/Modal.vue'
import { useProducedBeerInventory } from '@/composables/useProducedBeerInventory'

const emit = defineEmits<{
  close: []
}>()

const { t } = useI18n()
const keywordInputRef = ref<HTMLInputElement | null>(null)

const filters = reactive({
  keyword: '',
  product: '',
  site: '',
  packageId: '',
})

const sortState = reactive<{
  key:
    | 'lotNo'
    | 'batchCode'
    | 'beerCategory'
    | 'targetAbv'
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

  return inventoryRows.value.filter((row) => {
    if (keyword && !row.keywordIndex.includes(keyword)) return false
    if (filters.product && productFilterValue(row) !== filters.product) return false
    if (filters.site && row.siteId !== filters.site) return false
    if (filters.packageId && row.packageId !== filters.packageId) return false
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

function sortValue(
  row: (typeof inventoryRows.value)[number],
  key: (typeof sortState)['key'],
): string | number {
  switch (key) {
    case 'lotNo':
      return normalizeString(row.lotNo)
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

async function focusFirstField() {
  await nextTick()
  keywordInputRef.value?.focus()
  keywordInputRef.value?.select()
}

defineExpose({
  focusFirstField,
})

onMounted(async () => {
  await initialize()
  await focusFirstField()
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
