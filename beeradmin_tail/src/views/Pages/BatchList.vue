<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="currentPageTitle" />
    <section class="mb-6 bg-white shadow rounded-lg p-4 border border-gray-200" aria-labelledby="searchHeading">
      <div class="flex items-center justify-between mb-4">
        <h2 id="searchHeading" class="text-lg font-semibold">{{ $t('batch.list.searchTitle') }}</h2>
        <button class="text-sm px-3 py-1 rounded border border-gray-300 hover:bg-gray-100"
          @click="resetSearch">{{ $t('batch.list.reset') }}</button>
      </div>
      <form class="grid grid-cols-1 md:grid-cols-4 gap-4" @submit.prevent>
        <div>
          <label for="status" class="block text-sm text-gray-600 mb-1">{{ $t('batch.list.status') }}</label>
          <select id="status" v-model="search.status" class="w-full h-[30px] border rounded px-3 py-2">
            <option value="">{{ $t('batch.list.all') }}</option>
            <option v-for="s in STATUSES" :key="s" :value="s">{{ $t('batch.statusMap.' + s) }}</option>
          </select>
        </div>
        <div>
          <label for="start" class="block text-sm text-gray-600 mb-1">{{ $t('batch.list.startDate') }}</label>
          <input id="start" type="date" v-model="search.startDate" class="w-full h-[30px] border rounded px-3 py-2" />
        </div>
        <div>
          <label for="end" class="block text-sm text-gray-600 mb-1">{{ $t('batch.list.endDate') }}</label>
          <input id="end" type="date" v-model="search.endDate" class="w-full h-[30px] border rounded px-3 py-2" />
        </div>
        <div>
          <label for="q" class="block text-sm text-gray-600 mb-1">{{ $t('batch.list.keyword') }}</label>
          <input id="q" type="search" v-model.trim="search.q" :placeholder="$t('batch.list.keywordPh')"
            class="w-full h-[30px] border rounded px-3 py-2" />
        </div>
      </form>
      <div class="mt-2 text-sm text-gray-500">{{ $t('batch.list.showing', { count: filteredLots.length, total: lots.length }) }}</div>
    </section>


    <!-- Results Table -->
    <section aria-labelledby="resultHeading">
      <h2 id="resultHeading" class="sr-only">Results</h2>

      <!-- Mobile cards -->
      <div class="grid gap-4 md:hidden" role="list">
        <div v-for="lot in filteredLots" :key="lot.lotId" role="listitem" class="border rounded-lg p-4 shadow">
          <div class="flex items-center justify-between mb-2">
            <div class="font-semibold">{{ lot.lotId }} <span class="text-gray-500">• {{ lot.beerName }}</span></div>
            <span :class="['px-2 py-1 text-xs rounded-full', statusClass(lot.status)]">{{ $t('batch.statusMap.' + lot.status) }}</span>
          </div>
          <div class="text-sm space-y-1">
            <div><strong>{{ $t('batch.list.brewDate') }}:</strong> {{ fmtDate(lot.brewDate) }}</div>
            <div><strong>{{ $t('batch.list.finish') }}:</strong> {{ lot.finishDate ? fmtDate(lot.finishDate) : '—' }}</div>
            <div><strong>{{ $t('batch.list.style') }}:</strong> {{ lot.style }}</div>
            <div><strong>{{ $t('batch.list.batchL') }}:</strong> {{ lot.batchSize }}</div>
          </div>
          <div class="flex justify-end gap-2 mt-3">
            <button class="px-3 py-1 text-sm border rounded hover:bg-gray-100" @click="$emit('view', lot)">{{ $t('batch.list.view') }}</button>
            <button class="px-3 py-1 text-sm rounded bg-blue-600 text-white hover:bg-blue-700"
              @click="goEdit(lot)">{{ $t('batch.list.edit') }}</button>
          </div>
        </div>
      </div>

      <!-- Desktop table -->
      <div class="hidden md:block overflow-x-auto">
        <table class="min-w-full border border-gray-200 divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-2 text-left text-sm font-medium text-gray-600">{{ $t('batch.list.lotId') }}</th>
              <th class="px-3 py-2 text-left text-sm font-medium text-gray-600">{{ $t('batch.list.beerName') }}</th>
              <th class="px-3 py-2 text-left text-sm font-medium text-gray-600">{{ $t('batch.list.status') }}</th>
              <th class="px-3 py-2 text-left text-sm font-medium text-gray-600">{{ $t('batch.list.brewDate') }}</th>
              <th class="px-3 py-2 text-left text-sm font-medium text-gray-600">{{ $t('batch.list.finish') }}</th>
              <th class="px-3 py-2 text-left text-sm font-medium text-gray-600">{{ $t('batch.list.style') }}</th>
              <th class="px-3 py-2 text-right text-sm font-medium text-gray-600">{{ $t('batch.list.batchL') }}</th>
              <th class="px-3 py-2 text-sm font-medium text-gray-600">{{ $t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="lot in filteredLots" :key="lot.lotId" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-semibold">{{ lot.lotId }}</td>
              <td class="px-3 py-2">{{ lot.beerName }}</td>
              <td class="px-3 py-2"><span :class="['px-2 py-1 text-xs rounded-full', statusClass(lot.status)]">{{ $t('batch.statusMap.' + lot.status) }}</span></td>
              <td class="px-3 py-2">{{ fmtDate(lot.brewDate) }}</td>
              <td class="px-3 py-2">{{ lot.finishDate ? fmtDate(lot.finishDate) : '—' }}</td>
              <td class="px-3 py-2">{{ lot.style }}</td>
              <td class="px-3 py-2 text-right">{{ lot.batchSize }}</td>
              <td class="px-3 py-2 space-x-2">
                <button class="px-3 py-1 text-sm border rounded hover:bg-gray-100"
                  @click="$emit('view', lot)">{{ $t('batch.list.view') }}</button>
                <button class="px-3 py-1 text-sm rounded bg-blue-600 text-white hover:bg-blue-700"
                  @click="goEdit(lot)">{{ $t('batch.list.edit') }}</button>
              </td>
            </tr>
            <tr v-if="filteredLots.length === 0">
              <td colspan="8" class="px-3 py-6 text-center text-gray-500">{{ $t('batch.list.noMatch') }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </AdminLayout>
</template>

<script setup>
import { computed, reactive, watch } from 'vue'
import { ref } from "vue";
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import AdminLayout from "@/components/layout/AdminLayout.vue";
import PageBreadcrumb from "@/components/common/PageBreadcrumb.vue";

const { t } = useI18n()
const currentPageTitle = computed(() => t('batch.list.title'));

const STATUSES = ['Not started', 'In progress', 'Complete']

const router = useRouter()
function goEdit(lot) {
  try {
    const id = lot?.lotId ?? ''
    router.push({ path: '/batchedit', query: id ? { id } : undefined })
  } catch {}
}

const props = defineProps({
  lots: {
    type: Array,
    default: () => [
      { lotId: '2025-IPA-001', beerName: 'Galaxy IPA', status: 'In progress', brewDate: '2025-08-28', finishDate: '', style: 'IPA', batchSize: 20 },
      { lotId: '2025-STR-002', beerName: 'Midnight Stout', status: 'Complete', brewDate: '2025-06-04', finishDate: '2025-06-28', style: 'Stout', batchSize: 25 },
      { lotId: '2025-LGR-003', beerName: 'Kölsch Breeze', status: 'Not started', brewDate: '2025-09-10', finishDate: '', style: 'Kölsch', batchSize: 18 },
      { lotId: '2025-PLS-004', beerName: 'Pils Nova', status: 'In progress', brewDate: '2025-08-14', finishDate: '', style: 'Pilsner', batchSize: 30 }
    ]
  }
})

const search = reactive({ status: '', startDate: '', endDate: '', q: '' })

const STORAGE_KEY = 'lot-list-search-v1'
const loadSearch = () => {
  try { Object.assign(search, JSON.parse(localStorage.getItem(STORAGE_KEY)) || {}) } catch { }
}
const saveSearch = () => localStorage.setItem(STORAGE_KEY, JSON.stringify(search))
watch(search, saveSearch, { deep: true })
loadSearch()

const parseDate = (d) => d ? new Date(d + 'T00:00:00') : null
const fmtDate = (d) => d ? new Date(d + 'T00:00:00').toLocaleDateString() : ''

const statusClass = (s) => {
  if (s === 'Complete') return 'bg-green-100 text-green-800'
  if (s === 'In progress') return 'bg-yellow-100 text-yellow-800'
  if (s === 'Not started') return 'bg-red-100 text-red-800'
  return 'bg-gray-100 text-gray-800'
}

const inRange = (dateStr, startStr, endStr) => {
  if (!dateStr) return true
  const d = parseDate(dateStr)
  const s = parseDate(startStr)
  const e = parseDate(endStr)
  if (s && d < s) return false
  if (e) {
    const eod = new Date(e); eod.setHours(23, 59, 59, 999)
    if (d > eod) return false
  }
  return true
}

const filteredLots = computed(() => {
  const q = search.q.toLowerCase()
  return props.lots.filter(lot => {
    const statusOk = !search.status || lot.status === search.status
    const dateOk = inRange(lot.brewDate, search.startDate, search.endDate)
    const textOk = !q || `${lot.lotId} ${lot.beerName}`.toLowerCase().includes(q)
    return statusOk && dateOk && textOk
  })
})

function resetSearch() {
  search.status = ''
  search.startDate = ''
  search.endDate = ''
  search.q = ''
}
</script>
