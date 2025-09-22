<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-5xl mx-auto">
      <header class="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('uom.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('uom.subtitle') }}</p>
        </div>
        <div class="flex gap-2">
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">{{ t('common.new') }}</button>
          <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50" :disabled="loading" @click="fetchUoms">{{ t('common.refresh') }}</button>
        </div>
      </header>

      <section class="overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('code')"
              >
                {{ t('labels.code') }}<span v-if="sortKey === 'code'"> {{ sortLabel }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('name')"
              >
                {{ t('labels.name') }}<span v-if="sortKey === 'name'"> {{ sortLabel }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('base_factor')"
              >
                {{ t('labels.baseFactor') }}<span v-if="sortKey === 'base_factor'"> {{ sortLabel }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('base_code')"
              >
                {{ t('labels.baseCode') }}<span v-if="sortKey === 'base_code'"> {{ sortLabel }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in sortedRows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.code }}</td>
              <td class="px-3 py-2">{{ row.name || '—' }}</td>
              <td class="px-3 py-2">{{ row.base_factor ?? '—' }}</td>
              <td class="px-3 py-2">{{ row.base_code || '—' }}</td>
              <td class="px-3 py-2 space-x-2">
                <button class="px-2 py-1 text-sm rounded border hover:bg-gray-100" @click="openEdit(row)">{{ t('common.edit') }}</button>
                <button class="px-2 py-1 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">{{ t('common.delete') }}</button>
              </td>
            </tr>
            <tr v-if="rows.length === 0">
              <td colspan="5" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
        <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ editing ? t('uom.editTitle') : t('uom.newTitle') }}</h3>
          </div>
          <div class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.code') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.code" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.code" class="mt-1 text-xs text-red-600">{{ errors.code }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.name') }}</label>
                <input v-model.trim="form.name" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.baseFactor') }}</label>
                <input v-model="form.base_factor" type="number" step="any" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.base_factor" class="mt-1 text-xs text-red-600">{{ errors.base_factor }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.baseCode') }}</label>
                <input v-model.trim="form.base_code" class="w-full h-[40px] border rounded px-3" />
              </div>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" :disabled="saving" @click="saveRecord">
              {{ saving ? t('common.saving') : t('common.save') }}
            </button>
          </div>
        </div>
      </div>

      <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
        <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('uom.deleteTitle') }}</h3>
          </div>
          <div class="p-4 text-sm">{{ t('uom.deleteConfirm', { code: toDelete?.code || '' }) }}</div>
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

type UomRow = {
  id: string
  code: string
  name: string | null
  base_factor: number | null
  base_code: string | null
  created_at?: string | null
}

type SortKey = 'code' | 'name' | 'base_factor' | 'base_code'
type SortDirection = 'asc' | 'desc'

const TABLE = 'mst_uom'

const { t } = useI18n()
const pageTitle = computed(() => t('uom.title'))

const rows = ref<UomRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const toDelete = ref<UomRow | null>(null)
const sortKey = ref<SortKey>('code')
const sortDirection = ref<SortDirection>('asc')

const blank = () => ({
  id: '',
  code: '',
  name: '',
  base_factor: '',
  base_code: '',
})

const form = reactive<Record<string, any>>(blank())
const errors = reactive<Record<string, string>>({})

const sortedRows = computed<UomRow[]>(() => {
  const data = [...rows.value]
  const direction = sortDirection.value === 'asc' ? 1 : -1
  const key = sortKey.value

  data.sort((a, b) => {
    const aVal = a[key]
    const bVal = b[key]

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

const sortLabel = computed(() => (sortDirection.value === 'asc' ? '(asc)' : '(desc)'))

function resetForm() {
  Object.assign(form, blank())
  Object.keys(errors).forEach((key) => delete errors[key])
}

function setSort(column: SortKey) {
  if (sortKey.value === column) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = column
    sortDirection.value = 'asc'
  }
}

async function fetchUoms() {
  loading.value = true
  const { data, error } = await supabase
    .from(TABLE)
    .select('id, code, name, base_factor, base_code, created_at')
    .order('code', { ascending: true })
  loading.value = false
  if (error) {
    alert('Fetch error: ' + error.message)
    return
  }
  rows.value = (data ?? []) as UomRow[]
}

function openEdit(row: UomRow) {
  editing.value = true
  resetForm()
  Object.assign(form, {
    id: row.id,
    code: row.code,
    name: row.name ?? '',
    base_factor: row.base_factor ?? '',
    base_code: row.base_code ?? '',
  })
  showModal.value = true
}

async function openCreate() {
  editing.value = false
  resetForm()
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function confirmDelete(row: UomRow) {
  toDelete.value = row
  showDelete.value = true
}

async function deleteRecord() {
  if (!toDelete.value) return
  const { error } = await supabase.from(TABLE).delete().eq('id', toDelete.value.id)
  if (error) {
    alert('Delete error: ' + error.message)
    return
  }
  rows.value = rows.value.filter((r) => r.id !== toDelete.value?.id)
  showDelete.value = false
  toDelete.value = null
}

function validate() {
  Object.keys(errors).forEach((key) => delete errors[key])
  if (!form.code || String(form.code).trim() === '') {
    errors.code = t('errors.required', { field: t('labels.code') })
  }
  if (form.base_factor !== '' && form.base_factor !== null && form.base_factor !== undefined) {
    const num = Number(form.base_factor)
    if (Number.isNaN(num)) {
      errors.base_factor = t('errors.mustBeNumber', { field: t('labels.baseFactor') })
    }
  }
  return Object.keys(errors).length === 0
}

async function saveRecord() {
  if (!validate()) return
  saving.value = true
  const payload: Record<string, any> = {
    code: form.code?.trim() || '',
    name: form.name?.trim() || null,
    base_factor:
      form.base_factor === '' || form.base_factor === null || form.base_factor === undefined
        ? null
        : Number(form.base_factor),
    base_code: form.base_code?.trim() || null,
  }

  let response
  if (editing.value) {
    response = await supabase
      .from(TABLE)
      .update(payload)
      .eq('id', form.id)
      .select('id, code, name, base_factor, base_code, created_at')
      .single()
  } else {
    response = await supabase
      .from(TABLE)
      .insert(payload)
      .select('id, code, name, base_factor, base_code, created_at')
      .single()
  }

  saving.value = false
  if (response.error) {
    alert('Save error: ' + response.error.message)
    return
  }

  const saved = response.data as UomRow

  const idx = rows.value.findIndex((r) => r.id === saved.id)
  if (idx > -1) rows.value[idx] = saved
  else rows.value.push(saved)

  showModal.value = false
}

onMounted(async () => {
  await fetchUoms()
})
</script>

<style scoped>
th, td {
  white-space: nowrap;
}
</style>
