<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto space-y-4">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('beerInventory.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('beerInventory.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="fetchInventory"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white">
        <form class="grid grid-cols-1 md:grid-cols-4 gap-3" @submit.prevent>
          <div class="md:col-span-2">
            <label class="block text-sm text-gray-600 mb-1">{{ t('common.search') }}</label>
            <input v-model.trim="filters.keyword" type="search" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.filters.site') }}</label>
            <select v-model="filters.site" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in siteOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.filters.category') }}</label>
            <select v-model="filters.category" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in categoryOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
        </form>
      </section>

      <section class="overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200 text-sm">
          <thead class="bg-gray-50 text-xs uppercase text-gray-600">
            <tr>
              <th class="px-3 py-2 text-left">{{ t('beerInventory.table.beer') }}</th>
              <th class="px-3 py-2 text-left">{{ t('beerInventory.table.category') }}</th>
              <th class="px-3 py-2 text-left">{{ t('beerInventory.table.site') }}</th>
              <th class="px-3 py-2 text-left">{{ t('beerInventory.table.qty') }}</th>
              <th class="px-3 py-2 text-left">{{ t('beerInventory.table.uom') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in filteredRows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2">
                <div class="font-medium text-gray-900">{{ row.beer_code }}</div>
                <div class="text-xs text-gray-500">{{ row.beer_name }}</div>
              </td>
              <td class="px-3 py-2">{{ beerCategoryLabel(row.beer_category) }}</td>
              <td class="px-3 py-2">{{ siteLabel(row.site_id) }}</td>
              <td class="px-3 py-2">{{ formatQuantity(row.qty) }}</td>
              <td class="px-3 py-2">{{ row.uom_code || '—' }}</td>
            </tr>
            <tr v-if="!loading && filteredRows.length === 0">
              <td colspan="5" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

interface InventoryRow {
  id: string
  beer_id: string
  beer_code: string
  beer_name: string
  beer_category: string | null
  site_id: string
  qty: number
  uom_id: string
  uom_code: string | null
}

interface OptionItem {
  value: string
  label: string
}

const { t, locale } = useI18n()
const pageTitle = computed(() => t('beerInventory.title'))

const rows = ref<InventoryRow[]>([])
const loading = ref(false)

const siteOptions = ref<OptionItem[]>([])
const siteMap = computed(() => {
  const map = new Map<string, OptionItem>()
  siteOptions.value.forEach((item) => map.set(item.value, item))
  return map
})

const categoryOptions = computed(() => {
  const categories = ['ipa', 'lager', 'ale', 'pilsner', 'stout', 'porter', 'other']
  return categories.map((value) => ({ value, label: beerCategoryLabel(value) }))
})

const filters = reactive({ keyword: '', site: '', category: '' })

function beerCategoryLabel(value: string | null | undefined) {
  if (!value) return t('beerInventory.categories.other')
  const key = `beerInventory.categories.${value}`
  const translated = t(key as any)
  return translated === key ? value : translated
}

function siteLabel(id: string | null | undefined) {
  if (!id) return '—'
  return siteMap.value.get(id)?.label ?? '—'
}

function formatQuantity(value: number | null | undefined) {
  if (value == null) return '—'
  return new Intl.NumberFormat(locale.value, { maximumFractionDigits: 2 }).format(value)
}

const filteredRows = computed(() => {
  const keyword = filters.keyword.trim().toLowerCase()
  return rows.value.filter((row) => {
    const matchKeyword =
      keyword === '' ||
      row.beer_code.toLowerCase().includes(keyword) ||
      (row.beer_name ?? '').toLowerCase().includes(keyword)
    const matchSite = !filters.site || row.site_id === filters.site
    const matchCategory = !filters.category || row.beer_category === filters.category
    return matchKeyword && matchSite && matchCategory
  })
})

async function loadSites() {
  const { data, error } = await supabase
    .from('v_sites')
    .select('id, code, name')
    .eq('site_type_code', 'warehouse')
    .order('code', { ascending: true })
  if (error) throw error
  siteOptions.value = (data ?? []).map((row: any) => ({ value: row.id, label: `${row.code} — ${row.name}` }))
}

async function fetchInventory() {
  try {
    loading.value = true
    const { data, error } = await supabase
      .from('inv_inventory')
      .select('id, qty, uom_id, site_id, material:material_id(id, code, name, category, meta), uom:uom_id(code)')
    if (error) throw error
    rows.value = (data ?? [])
      .filter((row: any) => row.material?.meta?.type === 'beer')
      .map((row: any) => ({
        id: row.id,
        beer_id: row.material?.id ?? '',
        beer_code: row.material?.code ?? '',
        beer_name: row.material?.name ?? '',
        beer_category: row.material?.meta?.style ?? row.material?.category ?? null,
        site_id: row.site_id ?? '',
        qty: row.qty ?? 0,
        uom_id: row.uom_id ?? row.material?.uom_id ?? '',
        uom_code: row.uom?.code ?? null,
      }))
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await loadSites()
  await fetchInventory()
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
