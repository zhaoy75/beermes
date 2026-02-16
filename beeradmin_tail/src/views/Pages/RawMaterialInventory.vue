<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto space-y-4">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('rawMaterialInventory.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('rawMaterialInventory.subtitle') }}</p>
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
            <label class="block text-sm text-gray-600 mb-1">{{ t('rawMaterialInventory.filters.warehouse') }}</label>
            <select v-model="filters.warehouse" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in warehouseOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('rawMaterialInventory.filters.category') }}</label>
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
              <th class="px-3 py-2 text-left">{{ t('rawMaterialInventory.table.material') }}</th>
              <th class="px-3 py-2 text-left">{{ t('labels.category') }}</th>
              <th class="px-3 py-2 text-left">{{ t('rawMaterialInventory.table.warehouse') }}</th>
              <th class="px-3 py-2 text-left">{{ t('rawMaterialInventory.table.qty') }}</th>
              <th class="px-3 py-2 text-left">{{ t('labels.uom') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in filteredRows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2">
                <div class="font-medium text-gray-900">{{ row.material_code }}</div>
                <div class="text-xs text-gray-500">{{ row.material_name }}</div>
              </td>
              <td class="px-3 py-2">{{ categoryLabel(row.material_category) }}</td>
              <td class="px-3 py-2">{{ warehouseLabel(row.warehouse_id) }}</td>
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

const ALLOWED_CATEGORIES = ['malt', 'hop', 'yeast', 'adjunct'] as const

interface InventoryRow {
  id: string
  material_id: string
  material_code: string
  material_name: string
  material_category: string
  warehouse_id: string
  warehouse_name: string
  qty: number
  uom_id: string
  uom_code: string | null
}

interface WarehouseOption {
  value: string
  name: string
  label: string
}

const { t, locale } = useI18n()
const pageTitle = computed(() => t('rawMaterialInventory.title'))

const rows = ref<InventoryRow[]>([])
const loading = ref(false)

const warehouseOptions = ref<WarehouseOption[]>([])
const warehouseMap = computed(() => {
  const map = new Map<string, WarehouseOption>()
  warehouseOptions.value.forEach((item) => map.set(item.value, item))
  return map
})

const categoryOptions = computed(() =>
  ALLOWED_CATEGORIES.map((value) => ({ value, label: categoryLabel(value) }))
)

const filters = reactive({ keyword: '', warehouse: '', category: '' })

function categoryLabel(value: string | null | undefined) {
  if (!value) return '—'
  const key = `material.categories.${value}`
  const translated = t(key as any)
  return translated === key ? value : translated
}

function warehouseLabel(id: string | null | undefined) {
  if (!id) return '—'
  const option = warehouseMap.value.get(id)
  return option?.label ?? '—'
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
      row.material_code.toLowerCase().includes(keyword) ||
      (row.material_name ?? '').toLowerCase().includes(keyword)
    const matchWarehouse = !filters.warehouse || row.warehouse_id === filters.warehouse
    const matchCategory = !filters.category || row.material_category === filters.category
    return matchKeyword && matchWarehouse && matchCategory
  })
})

async function loadWarehouses() {
  const { data, error } = await supabase
    .from('v_sites')
    .select('id, name, site_type_code')
    .eq('site_type_code', 'warehouse')
    .order('name', { ascending: true })
  if (error) throw error
  warehouseOptions.value = (data ?? []).map((row: any) => ({
    value: row.id,
    name: row.name,
    label: row.name ?? row.id,
  }))
}

async function fetchInventory() {
  try {
    loading.value = true
    const { data, error } = await supabase
      .from('inv_inventory')
      .select('id, qty, uom_id, site_id, material:material_id(id, code, name, category, uom_id), uom:uom_id(code)')
    if (error) throw error
    rows.value = (data ?? [])
      .filter((row: any) => ALLOWED_CATEGORIES.includes(row.material?.category))
      .map((row: any) => {
        const warehouseOption = warehouseMap.value.get(row.site_id ?? '')
        return {
          id: row.id,
          material_id: row.material?.id ?? '',
          material_code: row.material?.code ?? '',
          material_name: row.material?.name ?? '',
          material_category: row.material?.category ?? '',
          site_id: row.site_id ?? '',
          warehouse_name: warehouseOption?.name ?? '',
          qty: row.qty ?? 0,
          uom_id: row.uom_id ?? row.material?.uom_id ?? '',
          uom_code: row.uom?.code ?? null,
        }
      })
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    loading.value = false
  }
}

onMounted(async () => {
  await loadWarehouses()
  await fetchInventory()
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
