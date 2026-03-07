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

        <section class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.lotNo') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.batchNo') }}</th>
                <th class="px-3 py-2 text-left">
                  {{ t('producedBeer.inventory.table.beerCategory') }}
                </th>
                <th class="px-3 py-2 text-right">
                  {{ t('producedBeer.inventory.table.targetAbv') }}
                </th>
                <th class="px-3 py-2 text-left">
                  {{ t('producedBeer.inventory.table.styleName') }}
                </th>
                <th class="px-3 py-2 text-left">
                  {{ t('producedBeer.inventory.table.packageType') }}
                </th>
                <th class="px-3 py-2 text-left">
                  {{ t('producedBeer.inventory.table.productionDate') }}
                </th>
                <th class="px-3 py-2 text-right">
                  {{ t('producedBeer.inventory.table.qtyLiters') }}
                </th>
                <th class="px-3 py-2 text-right">
                  {{ t('producedBeer.inventory.table.qtyPackages') }}
                </th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.site') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="row in inventoryRows" :key="row.id" class="hover:bg-gray-50">
                <td class="px-3 py-2 font-mono text-xs text-gray-600">{{ row.lotNo || '—' }}</td>
                <td class="px-3 py-2 font-mono text-xs text-gray-600">
                  {{ row.batchCode || '—' }}
                </td>
                <td class="px-3 py-2">{{ categoryLabel(row.beerCategoryId) }}</td>
                <td class="px-3 py-2 text-right">{{ formatAbv(row.targetAbv) }}</td>
                <td class="px-3 py-2">{{ row.styleName || '—' }}</td>
                <td class="px-3 py-2">{{ row.packageTypeLabel || '—' }}</td>
                <td class="px-3 py-2 text-xs text-gray-500">
                  {{ formatDate(row.productionDate) }}
                </td>
                <td class="px-3 py-2 text-right">{{ formatNumber(row.qtyLiters) }}</td>
                <td class="px-3 py-2 text-right">{{ formatNumber(row.qtyPackages) }}</td>
                <td class="px-3 py-2">{{ siteLabel(row.siteId) }}</td>
              </tr>
              <tr v-if="!inventoryLoading && inventoryRows.length === 0">
                <td colspan="10" class="px-3 py-8 text-center text-gray-500">
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
import { computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { useProducedBeerInventory } from '@/composables/useProducedBeerInventory'

const { t } = useI18n()
const pageTitle = computed(() => t('producedBeerInventory.title'))

const {
  categoryLabel,
  formatAbv,
  formatDate,
  formatNumber,
  initialize,
  inventoryLoading,
  inventoryRows,
  loadInventory,
  siteLabel,
} = useProducedBeerInventory()

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
