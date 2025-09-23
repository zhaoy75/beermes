<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <section class="mb-6 bg-white shadow rounded-lg p-4 border border-gray-200" aria-labelledby="wasteSearchHeading">
      <div class="flex items-center justify-between mb-4">
        <h2 id="wasteSearchHeading" class="text-lg font-semibold text-gray-800">{{ t('waste.list.searchTitle') }}</h2>
        <button class="text-sm px-3 py-1 rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-50" :disabled="loading" @click="fetchWaste">
          {{ t('common.refresh') }}
        </button>
      </div>
      <form class="grid grid-cols-1 md:grid-cols-4 gap-4" @submit.prevent>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="fromDate">{{ t('waste.list.startDate') }}</label>
          <input id="fromDate" v-model="search.start" type="date" class="w-full h-[36px] border rounded px-3" />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="toDate">{{ t('waste.list.endDate') }}</label>
          <input id="toDate" v-model="search.end" type="date" class="w-full h-[36px] border rounded px-3" />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="lotFilter">{{ t('waste.list.lotCode') }}</label>
          <input id="lotFilter" v-model.trim="search.lot" type="search" class="w-full h-[36px] border rounded px-3" :placeholder="t('waste.list.lotPlaceholder')" />
        </div>
        <div class="flex items-end">
          <button class="text-sm px-3 py-2 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="resetFilters">{{ t('common.reset') }}</button>
        </div>
      </form>
      <p class="mt-2 text-sm text-gray-500">{{ t('waste.list.showing', { count: filteredWaste.length, total: waste.length }) }}</p>
    </section>

    <section aria-labelledby="wasteTableHeading">
      <h2 id="wasteTableHeading" class="sr-only">{{ t('waste.list.tableTitle') }}</h2>
      <div class="overflow-x-auto border border-gray-200 rounded-lg shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-2 text-left text-xs font-semibold text-gray-600 uppercase tracking-wide">
                <button class="inline-flex items-center gap-1" type="button" @click="setSort('created_at')">
                  <span>{{ t('waste.list.colCreated') }}</span>
                  <span class="text-[10px] text-gray-400">{{ sortGlyph('created_at') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left text-xs font-semibold text-gray-600 uppercase tracking-wide">
                <button class="inline-flex items-center gap-1" type="button" @click="setSort('lot_code')">
                  <span>{{ t('waste.list.colLot') }}</span>
                  <span class="text-[10px] text-gray-400">{{ sortGlyph('lot_code') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left text-xs font-semibold text-gray-600 uppercase tracking-wide">
                {{ t('waste.list.colMaterial') }}
              </th>
              <th class="px-3 py-2 text-right text-xs font-semibold text-gray-600 uppercase tracking-wide">
                <button class="inline-flex items-center gap-1" type="button" @click="setSort('qty')">
                  <span>{{ t('waste.list.colQty') }}</span>
                  <span class="text-[10px] text-gray-400">{{ sortGlyph('qty') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left text-xs font-semibold text-gray-600 uppercase tracking-wide">
                {{ t('waste.list.colReason') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in sortedWaste" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 text-sm text-gray-600">{{ fmtDateTime(row.created_at) }}</td>
              <td class="px-3 py-2 text-sm">{{ row.lot_code || '—' }}</td>
              <td class="px-3 py-2 text-sm">
                <div>{{ row.material_name || '—' }}</div>
                <div v-if="row.material_code" class="text-xs text-gray-500">{{ row.material_code }}</div>
              </td>
              <td class="px-3 py-2 text-sm text-right">{{ row.qty != null ? row.qty : '—' }} <span class="text-xs text-gray-500">{{ row.uom_code || '' }}</span></td>
              <td class="px-3 py-2 text-sm text-gray-700">{{ row.reason || '—' }}</td>
            </tr>
            <tr v-if="!loading && sortedWaste.length === 0">
              <td class="px-3 py-5 text-center text-gray-500" colspan="5">{{ t('common.noData') }}</td>
            </tr>
            <tr v-if="loading">
              <td class="px-3 py-5 text-center text-gray-500" colspan="5">{{ t('common.loading') }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, reactive, ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'

const { t } = useI18n()
const pageTitle = computed(() => t('waste.list.title'))

interface WasteRow {
  id: string
  created_at: string | null
  qty: number | null
  reason: string | null
  lot_code: string | null
  material_name: string | null
  material_code: string | null
  uom_code: string | null
}

type SortKey = 'created_at' | 'lot_code' | 'qty'

type SearchState = {
  start: string
  end: string
  lot: string
}

const waste = ref<WasteRow[]>([])
const loading = ref(false)
const tenantId = ref<string | null>(null)
const search = reactive<SearchState>({ start: '', end: '', lot: '' })
const sortKey = ref<SortKey>('created_at')
const sortDirection = ref<'asc' | 'desc'>('desc')

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved in session')
  tenantId.value = id
  return id
}

async function fetchWaste() {
  try {
    loading.value = true
    const tenant = await ensureTenant()
    const query = supabase
      .from('wst_waste')
      .select('id, qty, reason, created_at, lot:prd_lots(lot_code), material:mst_materials(name, code), uom:mst_uom(code)')
      .eq('tenant_id', tenant)
      .order('created_at', { ascending: false })

    if (search.start) {
      query.gte('created_at', search.start)
    }
    if (search.end) {
      query.lte('created_at', search.end + 'T23:59:59')
    }

    const { data, error } = await query
    if (error) throw error

    waste.value = (data ?? []).map((row) => ({
      id: row.id,
      created_at: row.created_at,
      qty: row.qty ?? null,
      reason: row.reason ?? null,
      lot_code: (row as any)?.lot?.lot_code ?? null,
      material_name: (row as any)?.material?.name ?? null,
      material_code: (row as any)?.material?.code ?? null,
      uom_code: (row as any)?.uom?.code ?? null,
    }))
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

function resetFilters() {
  search.start = ''
  search.end = ''
  search.lot = ''
  fetchWaste()
}

const filteredWaste = computed(() => {
  return waste.value.filter((row) => {
    if (search.lot) {
      const lc = row.lot_code?.toLowerCase() ?? ''
      if (!lc.includes(search.lot.toLowerCase())) return false
    }
    return true
  })
})

const sortedWaste = computed(() => {
  const rows = [...filteredWaste.value]
  const dir = sortDirection.value === 'asc' ? 1 : -1
  rows.sort((a, b) => {
    const key = sortKey.value
    const av = (a as any)[key]
    const bv = (b as any)[key]
    if (av == null && bv == null) return 0
    if (av == null) return 1
    if (bv == null) return -1
    if (key === 'qty') {
      return dir * ((av as number) - (bv as number))
    }
    return dir * String(av).localeCompare(String(bv))
  })
  return rows
})

function setSort(key: SortKey) {
  if (sortKey.value === key) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = key
    sortDirection.value = key === 'created_at' ? 'desc' : 'asc'
  }
}

function sortGlyph(key: SortKey) {
  if (sortKey.value !== key) return ''
  return sortDirection.value === 'asc' ? '▲' : '▼'
}

function fmtDateTime(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
  } catch {
    return value
  }
}

onMounted(() => {
  ensureTenant().then(fetchWaste).catch((err) => console.error(err))
})
</script>
