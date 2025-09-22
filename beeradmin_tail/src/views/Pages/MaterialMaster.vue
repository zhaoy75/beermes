<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto">
      <header class="mb-4 flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('material.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('material.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">
            {{ t('common.new') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="fetchMaterials"
          >
            {{ t('common.refresh') }}
          </button>
          <div class="relative">
            <input
              v-model.trim="searchTerm"
              type="search"
              :placeholder="t('material.searchPlaceholder')"
              class="w-56 h-[40px] border rounded px-3 pr-8 text-sm"
            />
            <span class="absolute inset-y-0 right-2 flex items-center text-gray-400">
              <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-4.35-4.35m0 0A7.5 7.5 0 1016.65 16.65z" />
              </svg>
            </span>
          </div>
        </div>
      </header>

      <nav class="mb-4 flex flex-wrap gap-2">
        <button
          v-for="tab in categoryTabs"
          :key="tab"
          class="px-3 py-1 rounded-full border text-sm transition"
          :class="[
            currentCategory === tab
              ? 'bg-blue-600 text-white border-blue-600'
              : 'bg-white text-gray-600 border-gray-200 hover:bg-gray-100'
          ]"
          @click="currentCategory = tab"
        >
          {{ tab === 'all' ? t('common.all') : categoryLabel(tab) }}
        </button>
      </nav>

      <section class="hidden md:block overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('code')"
              >
                {{ t('labels.code') }}<span v-if="sortKey === 'code'"> {{ sortIcon }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('name')"
              >
                {{ t('labels.name') }}<span v-if="sortKey === 'name'"> {{ sortIcon }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('category')"
              >
                {{ t('labels.category') }}<span v-if="sortKey === 'category'"> {{ sortIcon }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('uomCode')"
              >
                {{ t('labels.uom') }}<span v-if="sortKey === 'uomCode'"> {{ sortIcon }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('active')"
              >
                {{ t('labels.active') }}<span v-if="sortKey === 'active'"> {{ sortIcon }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('created_at')"
              >
                {{ t('labels.createdAt') }}<span v-if="sortKey === 'created_at'"> {{ sortIcon }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in sortedRows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.code }}</td>
              <td class="px-3 py-2">{{ row.name || '—' }}</td>
              <td class="px-3 py-2">{{ categoryLabel(row.category) }}</td>
              <td class="px-3 py-2">{{ row.uomCode || '—' }}</td>
              <td class="px-3 py-2">{{ row.active ? t('common.yes') : t('common.no') }}</td>
              <td class="px-3 py-2 text-xs text-gray-500">{{ formatTimestamp(row.created_at) }}</td>
              <td class="px-3 py-2 space-x-2">
                <button class="px-2 py-1 text-sm rounded border hover:bg-gray-100" @click="openEdit(row)">
                  {{ t('common.edit') }}
                </button>
                <button
                  class="px-2 py-1 text-sm rounded bg-red-600 text-white hover:bg-red-700"
                  @click="confirmDelete(row)"
                >
                  {{ t('common.delete') }}
                </button>
              </td>
            </tr>
            <tr v-if="!loading && sortedRows.length === 0">
              <td colspan="7" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section class="md:hidden grid gap-3">
        <div
          v-for="row in sortedRows"
          :key="`card-${row.id}`"
          class="border border-gray-200 rounded-xl shadow-sm p-4"
        >
          <div class="flex items-center justify-between mb-2">
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">{{ categoryLabel(row.category) }}</p>
              <h2 class="text-lg font-semibold text-gray-900">{{ row.name || row.code }}</h2>
            </div>
            <span
              class="text-xs font-medium px-2 py-1 rounded-full"
              :class="row.active ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-600'"
            >
              {{ row.active ? t('common.yes') : t('common.no') }}
            </span>
          </div>
          <dl class="text-sm text-gray-600 space-y-1">
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('labels.code') }}</dt>
              <dd class="font-mono text-xs text-gray-700">{{ row.code }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('labels.uom') }}</dt>
              <dd>{{ row.uomCode || '—' }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('labels.createdAt') }}</dt>
              <dd class="text-xs text-gray-500">{{ formatTimestamp(row.created_at) }}</dd>
            </div>
          </dl>
          <div class="mt-3 flex gap-2">
            <button class="px-3 py-2 text-sm rounded border hover:bg-gray-100" @click="openEdit(row)">
              {{ t('common.edit') }}
            </button>
            <button class="px-3 py-2 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">
              {{ t('common.delete') }}
            </button>
          </div>
        </div>
        <p v-if="!loading && sortedRows.length === 0" class="text-center text-gray-500 text-sm">
          {{ t('common.noData') }}
        </p>
      </section>

      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-3xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">
              {{ editing ? t('material.editTitle') : t('material.newTitle') }}
            </h3>
          </div>
          <div class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.code') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.code" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.code" class="mt-1 text-xs text-red-600">{{ errors.code }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.name') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.name" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.name" class="mt-1 text-xs text-red-600">{{ errors.name }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.category') }}<span class="text-red-600">*</span></label>
                <select v-model="form.category" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option disabled value="">{{ t('material.categoryPlaceholder') }}</option>
                  <option v-for="option in categoryOptions" :key="option.value" :value="option.value">
                    {{ option.label }}
                  </option>
                </select>
                <p v-if="errors.category" class="mt-1 text-xs text-red-600">{{ errors.category }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.uom') }}<span class="text-red-600">*</span></label>
                <select v-model="form.uom_id" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option disabled value="">{{ t('material.uomPlaceholder') }}</option>
                  <option v-for="uom in uomOptions" :key="uom.id" :value="uom.id">
                    {{ uom.code }}<span v-if="uom.name"> · {{ uom.name }}</span>
                  </option>
                </select>
                <p v-if="errors.uom_id" class="mt-1 text-xs text-red-600">{{ errors.uom_id }}</p>
              </div>
              <div class="flex items-center gap-2">
                <input id="material-active" v-model="form.active" type="checkbox" class="h-4 w-4" />
                <label for="material-active" class="text-sm text-gray-600">{{ t('material.activeLabel') }}</label>
              </div>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">
              {{ t('common.cancel') }}
            </button>
            <button
              class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
              :disabled="saving"
              @click="saveRecord"
            >
              {{ saving ? t('common.saving') : t('common.save') }}
            </button>
          </div>
        </div>
      </div>

      <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('material.deleteTitle') }}</h3>
          </div>
          <div class="p-4 text-sm">
            {{ t('material.deleteConfirm', { code: toDelete?.code ?? '' }) }}
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="showDelete = false">
              {{ t('common.cancel') }}
            </button>
            <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700" @click="deleteRecord">
              {{ t('common.delete') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { ref, reactive, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'

type MaterialRow = {
  id: string
  code: string
  name: string | null
  category: string
  uom_id: string
  active: boolean
  created_at: string | null
}

type MaterialDisplayRow = MaterialRow & {
  uomCode: string
  uomName: string | null
}

type SortKey = 'code' | 'name' | 'category' | 'uomCode' | 'active' | 'created_at'
type SortDirection = 'asc' | 'desc'

type UomOption = {
  id: string
  code: string
  name: string | null
}

const MATERIAL_TABLE = 'mst_materials'
const UOM_TABLE = 'mst_uom'

const CATEGORY_SOURCE = [
  'malt',
  'hop',
  'yeast',
  'adjunct',
  'water',
  'packaging',
  'chemical',
  'cleaning',
  'other',
] as const

type CategoryValue = (typeof CATEGORY_SOURCE)[number]

const { t } = useI18n()
const pageTitle = computed(() => t('material.title'))

const rows = ref<MaterialRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const toDelete = ref<MaterialRow | null>(null)

const searchTerm = ref('')
const currentCategory = ref<'all' | CategoryValue>('all')
const sortKey = ref<SortKey>('code')
const sortDirection = ref<SortDirection>('asc')

const uomOptions = ref<UomOption[]>([])

const categoryOptions = computed(() =>
  CATEGORY_SOURCE.map((value) => ({ value, label: categoryLabel(value) }))
)

const categoryTabs = computed(() => ['all', ...CATEGORY_SOURCE] as Array<'all' | CategoryValue>)

const uomMap = computed(() => {
  const map = new Map<string, UomOption>()
  uomOptions.value.forEach((item) => {
    map.set(item.id, item)
  })
  return map
})

const decoratedRows = computed<MaterialDisplayRow[]>(() =>
  rows.value.map((row) => {
    const match = uomMap.value.get(row.uom_id)
    return {
      ...row,
      uomCode: match?.code ?? '',
      uomName: match?.name ?? null,
    }
  })
)

const filteredRows = computed(() => {
  const cat = currentCategory.value
  const keyword = searchTerm.value.trim().toLowerCase()

  return decoratedRows.value.filter((row) => {
    const matchesCategory = cat === 'all' || row.category === cat
    const matchesSearch =
      keyword === '' || (row.name ?? '').toLowerCase().includes(keyword) || row.code.toLowerCase().includes(keyword)
    return matchesCategory && matchesSearch
  })
})

const sortedRows = computed<MaterialDisplayRow[]>(() => {
  const data = [...filteredRows.value]
  const direction = sortDirection.value === 'asc' ? 1 : -1
  const key = sortKey.value

  data.sort((a, b) => {
    const aVal = a[key]
    const bVal = b[key]

    if (key === 'active') {
      return ((aVal ? 1 : 0) - (bVal ? 1 : 0)) * direction
    }

    if (key === 'created_at') {
      const aTime = aVal ? Date.parse(aVal as string) : 0
      const bTime = bVal ? Date.parse(bVal as string) : 0
      return (aTime - bTime) * direction
    }

    if (aVal == null && bVal == null) return 0
    if (aVal == null) return 1 * direction
    if (bVal == null) return -1 * direction

    if (typeof aVal === 'number' && typeof bVal === 'number') {
      return (aVal - bVal) * direction
    }

    const aStr = String(aVal).toLowerCase()
    const bStr = String(bVal).toLowerCase()
    return aStr.localeCompare(bStr) * direction
  })

  return data
})

const sortIcon = computed(() => (sortDirection.value === 'asc' ? '▲' : '▼'))

const blank = () => ({
  id: '',
  code: '',
  name: '',
  category: '' as '' | CategoryValue,
  uom_id: '',
  active: true,
})

const form = reactive<Record<string, any>>(blank())
const errors = reactive<Record<string, string>>({})

function categoryLabel(value: string | null | undefined) {
  if (!value) return ''
  const key = `material.categories.${value}`
  const translated = t(key as any)
  return translated === key ? value : translated
}

function setSort(column: SortKey) {
  if (sortKey.value === column) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = column
    sortDirection.value = 'asc'
  }
}

function resetForm() {
  Object.assign(form, blank())
  Object.keys(errors).forEach((key) => delete errors[key])
}

function openCreate() {
  editing.value = false
  resetForm()
  form.category = CATEGORY_SOURCE[0] ?? ''
  form.active = true
  showModal.value = true
}

function openEdit(row: MaterialDisplayRow) {
  editing.value = true
  resetForm()
  Object.assign(form, {
    id: row.id,
    code: row.code,
    name: row.name ?? '',
    category: row.category,
    uom_id: row.uom_id,
    active: Boolean(row.active),
  })
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function confirmDelete(row: MaterialRow) {
  toDelete.value = row
  showDelete.value = true
}

function validate() {
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!form.code || String(form.code).trim() === '') {
    errors.code = t('errors.required', { field: t('labels.code') })
  }

  if (!form.name || String(form.name).trim() === '') {
    errors.name = t('errors.required', { field: t('labels.name') })
  }

  if (!form.category) {
    errors.category = t('errors.required', { field: t('labels.category') })
  } else if (!CATEGORY_SOURCE.includes(form.category as CategoryValue)) {
    errors.category = t('material.invalidCategory')
  }

  if (!form.uom_id) {
    errors.uom_id = t('errors.required', { field: t('labels.uom') })
  }

  return Object.keys(errors).length === 0
}

async function fetchUoms() {
  const { data, error } = await supabase
    .from<UomOption>(UOM_TABLE)
    .select('id, code, name')
    .order('code', { ascending: true })

  if (error) {
    alert('UOM fetch error: ' + error.message)
    return
  }

  uomOptions.value = data ?? []
}

async function fetchMaterials() {
  loading.value = true
  const { data, error } = await supabase
    .from<MaterialRow>(MATERIAL_TABLE)
    .select('id, code, name, category, uom_id, active, created_at')
    .order('code', { ascending: true })
  loading.value = false

  if (error) {
    alert('Fetch error: ' + error.message)
    return
  }

  rows.value = (data ?? []).map((item) => ({
    ...item,
    name: item.name ?? '',
    active: Boolean(item.active),
  }))
}

async function saveRecord() {
  if (!validate()) return

  saving.value = true
  const payload = {
    code: form.code?.trim() || '',
    name: form.name?.trim() || '',
    category: form.category,
    uom_id: form.uom_id,
    active: Boolean(form.active),
  }

  let response
  if (editing.value) {
    response = await supabase
      .from(MATERIAL_TABLE)
      .update(payload)
      .eq('id', form.id)
      .select('id, code, name, category, uom_id, active, created_at')
      .single()
  } else {
    response = await supabase
      .from(MATERIAL_TABLE)
      .insert(payload)
      .select('id, code, name, category, uom_id, active, created_at')
      .single()
  }

  saving.value = false
  if (response.error) {
    alert('Save error: ' + response.error.message)
    return
  }

  const saved = response.data as MaterialRow
  const idx = rows.value.findIndex((row) => row.id === saved.id)
  const normalized: MaterialRow = {
    ...saved,
    name: saved.name ?? '',
    active: Boolean(saved.active),
  }

  if (idx > -1) {
    rows.value[idx] = normalized
  } else {
    rows.value.push(normalized)
  }
  rows.value = [...rows.value]

  showModal.value = false
}

async function deleteRecord() {
  if (!toDelete.value) return

  const { error } = await supabase.from(MATERIAL_TABLE).delete().eq('id', toDelete.value.id)
  if (error) {
    alert('Delete error: ' + error.message)
    return
  }

  rows.value = rows.value.filter((row) => row.id !== toDelete.value?.id)
  showDelete.value = false
  toDelete.value = null
}

function formatTimestamp(value: string | null) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleString()
}

onMounted(async () => {
  await Promise.all([fetchUoms(), fetchMaterials()])
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
