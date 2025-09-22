<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-5xl mx-auto">
      <header class="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('category.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('category.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <input
            v-model.trim="searchTerm"
            type="search"
            :placeholder="t('category.searchPlaceholder')"
            class="w-52 h-[40px] border rounded px-3 text-sm"
          />
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">
            {{ t('common.new') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="fetchCategories"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="hidden md:block overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('code')"
              >
                {{ t('labels.code') }}<span v-if="sortKey === 'code'"> {{ sortGlyph }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('name')"
              >
                {{ t('labels.name') }}<span v-if="sortKey === 'name'"> {{ sortGlyph }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('created_at')"
              >
                {{ t('labels.createdAt') }}<span v-if="sortKey === 'created_at'"> {{ sortGlyph }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in sortedRows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.code }}</td>
              <td class="px-3 py-2">{{ row.name || '—' }}</td>
              <td class="px-3 py-2 text-xs text-gray-500">{{ formatTimestamp(row.created_at) }}</td>
              <td class="px-3 py-2 space-x-2">
                <button class="px-2 py-1 text-sm rounded border hover:bg-gray-100" @click="openEdit(row)">
                  {{ t('common.edit') }}
                </button>
                <button class="px-2 py-1 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">
                  {{ t('common.delete') }}
                </button>
              </td>
            </tr>
            <tr v-if="!loading && sortedRows.length === 0">
              <td colspan="4" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section class="md:hidden grid gap-3">
        <div v-for="row in sortedRows" :key="row.id" class="border border-gray-200 rounded-xl shadow-sm p-4">
          <div class="flex items-center justify-between mb-2">
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">{{ t('labels.code') }}</p>
              <h2 class="text-lg font-semibold text-gray-900">{{ row.code }}</h2>
            </div>
            <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openEdit(row)">
              {{ t('common.edit') }}
            </button>
          </div>
          <dl class="text-sm text-gray-600 space-y-1">
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('labels.name') }}</dt>
              <dd>{{ row.name || '—' }}</dd>
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
        <div class="w-full max-w-lg bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ editing ? t('category.editTitle') : t('category.newTitle') }}</h3>
          </div>
          <div class="p-4 space-y-4">
            <div class="grid grid-cols-1 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.code') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.code" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.code" class="mt-1 text-xs text-red-600">{{ errors.code }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.name') }}</label>
                <input v-model.trim="form.name" class="w-full h-[40px] border rounded px-3" />
              </div>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">{{ t('common.cancel') }}</button>
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
            <h3 class="font-semibold">{{ t('category.deleteTitle') }}</h3>
          </div>
          <div class="p-4 text-sm">{{ t('category.deleteConfirm', { code: toDelete?.code ?? '' }) }}</div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="showDelete = false">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700" @click="deleteRecord">{{ t('common.delete') }}</button>
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

type CategoryRow = {
  id: string
  code: string
  name: string | null
  created_at: string | null
}

type SortKey = 'code' | 'name' | 'created_at'
type SortDirection = 'asc' | 'desc'

const TABLE = 'mst_category'

const { t } = useI18n()
const pageTitle = computed(() => t('category.title'))

const rows = ref<CategoryRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const toDelete = ref<CategoryRow | null>(null)

const sortKey = ref<SortKey>('code')
const sortDirection = ref<SortDirection>('asc')
const searchTerm = ref('')

const blank = () => ({
  id: '',
  code: '',
  name: '',
  created_at: null as string | null,
})

const form = reactive<Record<string, any>>(blank())
const errors = reactive<Record<string, string>>({})

const filteredRows = computed(() => {
  const keyword = searchTerm.value.trim().toLowerCase()
  if (keyword === '') return rows.value
  return rows.value.filter((row) => {
    return row.code.toLowerCase().includes(keyword) || (row.name ?? '').toLowerCase().includes(keyword)
  })
})

const sortedRows = computed(() => {
  const data = [...filteredRows.value]
  const direction = sortDirection.value === 'asc' ? 1 : -1
  const key = sortKey.value

  data.sort((a, b) => {
    const aVal = a[key]
    const bVal = b[key]

    if (key === 'created_at') {
      const aTime = aVal ? Date.parse(aVal) : 0
      const bTime = bVal ? Date.parse(bVal) : 0
      return (aTime - bTime) * direction
    }

    const aStr = (aVal ?? '').toString().toLowerCase()
    const bStr = (bVal ?? '').toString().toLowerCase()
    return aStr.localeCompare(bStr) * direction
  })

  return data
})

const sortGlyph = computed(() => (sortDirection.value === 'asc' ? '▲' : '▼'))

function setSort(column: SortKey) {
  if (sortKey.value === column) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = column
    sortDirection.value = 'asc'
  }
}

function formatTimestamp(value: string | null) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleString()
}

function resetForm() {
  Object.assign(form, blank())
  Object.keys(errors).forEach((key) => delete errors[key])
}

async function fetchCategories() {
  loading.value = true
  const { data, error } = await supabase
    .from<CategoryRow>(TABLE)
    .select('id, code, name, created_at')
    .order('code', { ascending: true })
  loading.value = false

  if (error) {
    alert('Fetch error: ' + error.message)
    return
  }

  rows.value = (data ?? []).map((item) => ({
    ...item,
    name: item.name ?? '',
  }))
}

function openCreate() {
  editing.value = false
  resetForm()
  showModal.value = true
}

function openEdit(row: CategoryRow) {
  editing.value = true
  resetForm()
  Object.assign(form, {
    id: row.id,
    code: row.code,
    name: row.name ?? '',
  })
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function confirmDelete(row: CategoryRow) {
  toDelete.value = row
  showDelete.value = true
}

function validate() {
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!form.code || String(form.code).trim() === '') {
    errors.code = t('errors.required', { field: t('labels.code') })
  }

  return Object.keys(errors).length === 0
}

async function saveRecord() {
  if (!validate()) return

  saving.value = true
  const payload = {
    code: form.code?.trim() || '',
    name: form.name?.trim() || null,
  }

  let response
  if (editing.value) {
    response = await supabase
      .from(TABLE)
      .update(payload)
      .eq('id', form.id)
      .select('id, code, name, created_at')
      .single()
  } else {
    response = await supabase
      .from(TABLE)
      .insert(payload)
      .select('id, code, name, created_at')
      .single()
  }

  saving.value = false
  if (response.error) {
    alert('Save error: ' + response.error.message)
    return
  }

  const saved = response.data as CategoryRow
  const idx = rows.value.findIndex((row) => row.id === saved.id)
  if (idx > -1) {
    rows.value[idx] = saved
  } else {
    rows.value.push(saved)
  }
  rows.value = [...rows.value]

  showModal.value = false
}

async function deleteRecord() {
  if (!toDelete.value) return

  const { error } = await supabase.from(TABLE).delete().eq('id', toDelete.value.id)
  if (error) {
    alert('Delete error: ' + error.message)
    return
  }

  rows.value = rows.value.filter((row) => row.id !== toDelete.value?.id)
  showDelete.value = false
  toDelete.value = null
}

onMounted(async () => {
  await fetchCategories()
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
