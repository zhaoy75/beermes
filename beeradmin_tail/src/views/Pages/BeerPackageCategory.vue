<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-5xl mx-auto">
      <header class="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('packageCategory.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('packageCategory.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <input
            v-model.trim="searchTerm"
            type="search"
            :placeholder="t('packageCategory.searchPlaceholder')"
            class="w-60 h-[40px] border rounded px-3 text-sm"
          />
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">
            {{ t('common.new') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="fetchPackages"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <!-- Desktop table -->
      <section class="hidden md:block overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none" @click="setSort('package_code')">
                {{ t('packageCategory.columns.code') }}<span v-if="sortKey === 'package_code'"> {{ sortGlyph }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none" @click="setSort('package_name')">
                {{ t('packageCategory.columns.name') }}<span v-if="sortKey === 'package_name'"> {{ sortGlyph }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none" @click="setSort('size')">
                {{ t('packageCategory.columns.size') }}<span v-if="sortKey === 'size'"> {{ sortGlyph }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('packageCategory.columns.sizeFixed') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none" @click="setSort('created_at')">
                {{ t('packageCategory.columns.createdAt') }}<span v-if="sortKey === 'created_at'"> {{ sortGlyph }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in sortedRows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.package_code }}</td>
              <td class="px-3 py-2">{{ row.package_name || '—' }}</td>
              <td class="px-3 py-2 text-sm text-gray-700">{{ formatSize(row) }}</td>
              <td class="px-3 py-2">
                <span :class="sizeFixedBadge(row.size_fixed)">{{ row.size_fixed ? t('common.yes') : t('common.no') }}</span>
              </td>
              <td class="px-3 py-2 text-xs text-gray-500">{{ formatTimestamp(row.created_at) }}</td>
              <td class="px-3 py-2 space-x-2">
                <button class="px-2 py-1 text-sm rounded border hover:bg-gray-100" @click="openEdit(row)">{{ t('common.edit') }}</button>
                <button class="px-2 py-1 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">{{ t('common.delete') }}</button>
              </td>
            </tr>
            <tr v-if="!loading && sortedRows.length === 0">
              <td colspan="6" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <!-- Mobile cards -->
      <section class="md:hidden grid gap-3">
        <div v-for="row in sortedRows" :key="row.id" class="border border-gray-200 rounded-xl shadow-sm p-4">
          <div class="flex items-center justify-between mb-2">
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">{{ t('packageCategory.columns.code') }}</p>
              <h2 class="text-lg font-semibold text-gray-900">{{ row.package_code }}</h2>
            </div>
            <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openEdit(row)">{{ t('common.edit') }}</button>
          </div>
          <dl class="text-sm text-gray-600 space-y-1">
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('packageCategory.columns.name') }}</dt>
              <dd>{{ row.package_name || '—' }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('packageCategory.columns.size') }}</dt>
              <dd>{{ formatSize(row) }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('packageCategory.columns.sizeFixed') }}</dt>
              <dd>{{ row.size_fixed ? t('common.yes') : t('common.no') }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('packageCategory.columns.createdAt') }}</dt>
              <dd class="text-xs text-gray-500">{{ formatTimestamp(row.created_at) }}</dd>
            </div>
          </dl>
          <div class="mt-3 flex gap-2">
            <button class="px-3 py-2 text-sm rounded border hover:bg-gray-100" @click="openEdit(row)">{{ t('common.edit') }}</button>
            <button class="px-3 py-2 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">{{ t('common.delete') }}</button>
          </div>
        </div>
        <p v-if="!loading && sortedRows.length === 0" class="text-center text-gray-500 text-sm">{{ t('common.noData') }}</p>
      </section>

      <!-- Create / edit modal -->
      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ editing ? t('packageCategory.editTitle') : t('packageCategory.newTitle') }}</h3>
          </div>
          <div class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('packageCategory.columns.code') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.package_code" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.package_code" class="mt-1 text-xs text-red-600">{{ errors.package_code }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('packageCategory.columns.name') }}</label>
                <input v-model.trim="form.package_name" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('packageCategory.columns.size') }}</label>
                <input v-model="form.size" type="number" step="0.01" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.size" class="mt-1 text-xs text-red-600">{{ errors.size }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('packageCategory.columns.uom') }}</label>
                <select v-model="form.uom_id" class="w-full h-[40px] border rounded px-3">
                  <option value="">{{ t('packageCategory.uomPlaceholder') }}</option>
                  <option v-for="opt in uomOptions" :key="opt.id" :value="opt.id">{{ opt.name ? opt.code + ' — ' + opt.name : opt.code }}</option>
                </select>
              </div>
              <div class="md:col-span-2 flex items-center gap-2">
                <input id="sizeFixed" v-model="form.size_fixed" type="checkbox" class="h-4 w-4" />
                <label for="sizeFixed" class="text-sm text-gray-600">{{ t('packageCategory.sizeFixedLabel') }}</label>
              </div>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" :disabled="saving" @click="saveRecord">
              {{ saving ? t('common.saving') : t('common.save') }}
            </button>
          </div>
        </div>
      </div>

      <!-- Delete confirm -->
      <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('packageCategory.deleteTitle') }}</h3>
          </div>
          <div class="p-4 text-sm">{{ t('packageCategory.deleteConfirm', { code: toDelete?.package_code ?? '' }) }}</div>
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
import { computed, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'

type PackageRow = {
  id: string
  package_code: string
  package_name: string | null
  size: number | null
  size_fixed: boolean
  uom_id: string | null
  uom_code: string | null
  created_at: string | null
}

type SortKey = 'package_code' | 'package_name' | 'size' | 'created_at'
type SortDirection = 'asc' | 'desc'

const TABLE = 'mst_beer_package_category'

const { t } = useI18n()
const pageTitle = computed(() => t('packageCategory.title'))

const rows = ref<PackageRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const toDelete = ref<PackageRow | null>(null)

const sortKey = ref<SortKey>('package_code')
const sortDirection = ref<SortDirection>('asc')
const searchTerm = ref('')

const uomOptions = ref<Array<{ id: string; code: string; name: string | null }>>([])

const blank = () => ({
  id: '',
  package_code: '',
  package_name: '',
  size: '',
  uom_id: '',
  size_fixed: false,
})

const form = reactive<Record<string, any>>(blank())
const errors = reactive<Record<string, string>>({})

const sortGlyph = computed(() => (sortDirection.value === 'asc' ? '▲' : '▼'))

const filteredRows = computed(() => {
  if (!searchTerm.value) return rows.value
  const term = searchTerm.value.toLowerCase()
  return rows.value.filter((row) =>
    [row.package_code, row.package_name, row.uom_code].some((field) => field?.toLowerCase().includes(term))
  )
})

const sortedRows = computed(() => {
  const data = [...filteredRows.value]
  const dir = sortDirection.value === 'asc' ? 1 : -1
  data.sort((a, b) => {
    const key = sortKey.value
    const av = (a as any)[key]
    const bv = (b as any)[key]
    if (av == null && bv == null) return 0
    if (av == null) return 1
    if (bv == null) return -1
    if (key === 'size') {
      return dir * ((Number(av) || 0) - (Number(bv) || 0))
    }
    return dir * String(av).localeCompare(String(bv))
  })
  return data
})

function setSort(key: SortKey) {
  if (sortKey.value === key) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = key
    sortDirection.value = key === 'package_code' ? 'asc' : 'desc'
  }
}

function sizeFixedBadge(value: boolean) {
  return value
    ? 'inline-flex items-center px-2 py-0.5 text-xs font-semibold rounded-full bg-green-100 text-green-800'
    : 'inline-flex items-center px-2 py-0.5 text-xs font-semibold rounded-full bg-gray-100 text-gray-600'
}

function formatTimestamp(value: string | null) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
  } catch {
    return value
  }
}

function formatSize(row: PackageRow) {
  if (row.size == null) return '—'
  const size = Number(row.size)
  const qty = Number.isFinite(size) ? size.toLocaleString(undefined, { maximumFractionDigits: 2 }) : row.size
  return row.uom_code ? `${qty} ${row.uom_code}` : String(qty)
}

function openCreate() {
  editing.value = false
  Object.assign(form, blank())
  Object.keys(errors).forEach((key) => delete errors[key])
  showModal.value = true
}

function openEdit(row: PackageRow) {
  editing.value = true
  Object.assign(form, {
    id: row.id,
    package_code: row.package_code,
    package_name: row.package_name ?? '',
    size: row.size != null ? String(row.size) : '',
    uom_id: row.uom_id ?? '',
    size_fixed: row.size_fixed,
  })
  Object.keys(errors).forEach((key) => delete errors[key])
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

async function fetchUoms() {
  const { data, error } = await supabase
    .from('mst_uom')
    .select('id, code, name')
    .order('code')
  if (error) {
    console.error(error)
    return
  }
  uomOptions.value = data ?? []
}

async function fetchPackages() {
  try {
    loading.value = true
    const { data, error } = await supabase
      .from(TABLE)
      .select('id, package_code, package_name, size, size_fixed, uom_id, created_at, uom:mst_uom(code)')
      .order('package_code', { ascending: true })
    if (error) throw error

    rows.value = (data ?? []).map((row: any) => ({
      id: row.id,
      package_code: row.package_code,
      package_name: row.package_name,
      size: row.size != null ? Number(row.size) : null,
      size_fixed: row.size_fixed ?? false,
      uom_id: row.uom_id ?? null,
      uom_code: row.uom?.code ?? null,
      created_at: row.created_at,
    }))
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

function validateForm() {
  Object.keys(errors).forEach((key) => delete errors[key])
  if (!form.package_code) {
    errors.package_code = t('errors.required', { field: t('packageCategory.columns.code') })
  }
  if (form.size !== '' && isNaN(Number(form.size))) {
    errors.size = t('errors.mustBeNumber', { field: t('packageCategory.columns.size') })
  }
  return Object.keys(errors).length === 0
}

async function saveRecord() {
  if (!validateForm()) return
  try {
    saving.value = true
    const payload = {
      package_code: form.package_code,
      package_name: form.package_name ? form.package_name : null,
      size: form.size !== '' ? Number(form.size) : null,
      uom_id: form.uom_id || null,
      size_fixed: !!form.size_fixed,
    }

    if (editing.value && form.id) {
      const { error } = await supabase.from(TABLE).update(payload).eq('id', form.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from(TABLE).insert(payload)
      if (error) throw error
    }
    showModal.value = false
    await fetchPackages()
  } catch (err) {
    console.error(err)
  } finally {
    saving.value = false
  }
}

function confirmDelete(row: PackageRow) {
  toDelete.value = row
  showDelete.value = true
}

async function deleteRecord() {
  if (!toDelete.value) return
  try {
    const { error } = await supabase.from(TABLE).delete().eq('id', toDelete.value.id)
    if (error) throw error
    showDelete.value = false
    toDelete.value = null
    await fetchPackages()
  } catch (err) {
    console.error(err)
  }
}

onMounted(async () => {
  await Promise.all([fetchUoms(), fetchPackages()])
})
</script>
