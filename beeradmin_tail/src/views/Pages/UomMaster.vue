<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto">
      <header class="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('uom.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('uom.subtitle') }}</p>
        </div>
        <div class="flex gap-2">
          <button
            class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
            :disabled="loading"
            @click="openCreate"
          >
            {{ t('uom.addButton') }}
          </button>
          <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50" :disabled="loading" @click="fetchUoms">
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('uom.table.dimension') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('uom.table.code') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('uom.table.name') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('uom.table.conversionFactor') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('uom.table.baseUnit') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in pagedRows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 text-sm">{{ row.dimension || '—' }}</td>
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.code }}</td>
              <td class="px-3 py-2">
                <div class="text-sm">{{ labelEn(row) }}</div>
                <div v-if="labelJa(row)" class="text-xs text-gray-500">{{ labelJa(row) }}</div>
              </td>
              <td class="px-3 py-2 text-sm">{{ row.base_factor ?? '—' }}</td>
              <td class="px-3 py-2 text-sm">
                <span
                  class="inline-flex items-center px-2 py-0.5 rounded-full text-xs"
                  :class="row.is_base_unit ? 'bg-green-100 text-green-800' : 'bg-gray-100 text-gray-600'"
                >
                  {{ row.is_base_unit ? t('common.yes') : t('common.no') }}
                </span>
              </td>
              <td class="px-3 py-2 space-x-2">
                <button
                  class="px-2 py-1 text-sm rounded border hover:bg-gray-100 disabled:opacity-50"
                  :disabled="!canEdit(row)"
                  @click="openEdit(row)"
                >
                  {{ t('common.edit') }}
                </button>
                <button
                  class="px-2 py-1 text-sm rounded bg-red-600 text-white hover:bg-red-700 disabled:opacity-50"
                  :disabled="!canEdit(row)"
                  @click="confirmDelete(row)"
                >
                  {{ t('common.delete') }}
                </button>
              </td>
            </tr>
            <tr v-if="rows.length === 0">
              <td colspan="6" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <div class="flex items-center justify-between text-sm text-gray-600 mt-3" v-if="rows.length">
        <div>{{ t('uom.pagination.showing', { start: pageStart + 1, end: pageEnd, total: rows.length }) }}</div>
        <div class="flex items-center gap-2">
          <button class="px-2 py-1 border rounded disabled:opacity-50" :disabled="page === 1" @click="page--">
            {{ t('uom.pagination.prev') }}
          </button>
          <span>{{ t('uom.pagination.page', { page, total: totalPages }) }}</span>
          <button class="px-2 py-1 border rounded disabled:opacity-50" :disabled="page === totalPages" @click="page++">
            {{ t('uom.pagination.next') }}
          </button>
        </div>
      </div>

      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
        <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b flex items-center justify-between">
            <h3 class="font-semibold">{{ editing ? t('uom.editTitle') : t('uom.newTitle') }}</h3>
            <button class="text-gray-400 hover:text-gray-600" @click="closeModal">&times;</button>
          </div>
          <div class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('uom.form.dimension') }}<span class="text-red-600">*</span></label>
                <select v-model="form.dimension" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="" disabled>{{ t('uom.form.dimensionPlaceholder') }}</option>
                  <option v-for="opt in dimensionOptions" :key="opt" :value="opt">{{ opt }}</option>
                </select>
                <p v-if="errors.dimension" class="mt-1 text-xs text-red-600">{{ errors.dimension }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('uom.form.code') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.code" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.code" class="mt-1 text-xs text-red-600">{{ errors.code }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('uom.form.nameEn') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.name_en" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.name_en" class="mt-1 text-xs text-red-600">{{ errors.name_en }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('uom.form.nameJa') }}</label>
                <input v-model.trim="form.name_ja" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('uom.form.conversionFactor') }}<span class="text-red-600">*</span></label>
                <input v-model="form.base_factor" type="number" step="any" class="w-full h-[40px] border rounded px-3" :disabled="form.is_base_unit" />
                <p v-if="errors.base_factor" class="mt-1 text-xs text-red-600">{{ errors.base_factor }}</p>
              </div>
              <div class="flex items-end">
                <div>
                  <label class="inline-flex items-center gap-2 text-sm text-gray-700">
                    <input v-model="form.is_base_unit" type="checkbox" class="h-4 w-4" />
                    {{ t('uom.form.isBaseUnit') }}
                  </label>
                  <p v-if="errors.is_base_unit" class="mt-1 text-xs text-red-600">{{ errors.is_base_unit }}</p>
                </div>
              </div>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" :disabled="saving" @click="saveRecord">
              {{ saving ? t('common.saving') : t('uom.saveButton') }}
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
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

type UomMeta = {
  label?: {
    en?: string | null
    ja?: string | null
  }
}

type UomRow = {
  id: string
  code: string
  name: string | null
  dimension: string | null
  base_factor: number | null
  base_code: string | null
  is_base_unit: boolean | null
  scope: string | null
  industry_id: string | null
  owner_id: string | null
  meta: UomMeta | null
  created_at?: string | null
}

const TABLE = 'mst_uom'
const INDUSTRY_ID = '00000000-0000-0000-0000-000000000000'
const FALLBACK_DIMENSIONS = ['weight', 'volume', 'temperature', 'pressure', 'length', 'time', 'percentage', 'density']

const { t } = useI18n()
const pageTitle = computed(() => t('uom.title'))
const rows = ref<UomRow[]>([])
const dimensionOptions = ref<string[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const toDelete = ref<UomRow | null>(null)
const tenantId = ref<string | null>(null)

const page = ref(1)
const pageSize = 20

const form = reactive({
  id: '',
  dimension: '',
  code: '',
  name_en: '',
  name_ja: '',
  base_factor: '',
  is_base_unit: false,
})

const errors = reactive<Record<string, string>>({})

const totalPages = computed(() => Math.max(1, Math.ceil(rows.value.length / pageSize)))
const pageStart = computed(() => (page.value - 1) * pageSize)
const pageEnd = computed(() => Math.min(rows.value.length, pageStart.value + pageSize))
const pagedRows = computed(() => rows.value.slice(pageStart.value, pageEnd.value))

function labelEn(row: UomRow) {
  return row.meta?.label?.en || row.name || '—'
}

function labelJa(row: UomRow) {
  return row.meta?.label?.ja || ''
}

function resetForm() {
  form.id = ''
  form.dimension = ''
  form.code = ''
  form.name_en = ''
  form.name_ja = ''
  form.base_factor = ''
  form.is_base_unit = false
  Object.keys(errors).forEach((key) => delete errors[key])
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved in session')
  tenantId.value = id
  return id
}

function canEdit(row: UomRow) {
  if (row.scope === 'system') return false
  return true
}

async function fetchDimensions() {
  const { data, error } = await supabase.from(TABLE).select('dimension').not('dimension', 'is', null)
  if (error) {
    dimensionOptions.value = [...FALLBACK_DIMENSIONS]
    return
  }
  const set = new Set<string>()
  ;(data ?? []).forEach((row: any) => {
    if (row.dimension) set.add(String(row.dimension))
  })
  const values = Array.from(set).sort()
  dimensionOptions.value = values.length ? values : [...FALLBACK_DIMENSIONS]
}

async function fetchUoms() {
  loading.value = true
  const { data, error } = await supabase
    .from(TABLE)
    .select('id, code, name, dimension, base_factor, base_code, is_base_unit, scope, industry_id, owner_id, meta, created_at')
    .order('dimension', { ascending: true })
    .order('code', { ascending: true })
  loading.value = false
  if (error) {
    toast.error(t('uom.errors.fetch', { message: error.message }))
    rows.value = []
    return
  }
  rows.value = (data ?? []) as UomRow[]
  if (page.value > totalPages.value) page.value = totalPages.value
}

function openEdit(row: UomRow) {
  if (!canEdit(row)) {
    toast.error(t('uom.errors.systemReadOnly'))
    return
  }
  editing.value = true
  resetForm()
  form.id = row.id
  form.dimension = row.dimension ?? ''
  form.code = row.code
  form.name_en = row.meta?.label?.en ?? row.name ?? ''
  form.name_ja = row.meta?.label?.ja ?? ''
  form.base_factor = row.base_factor == null ? '' : String(row.base_factor)
  form.is_base_unit = Boolean(row.is_base_unit)
  showModal.value = true
}

function openCreate() {
  editing.value = false
  resetForm()
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function confirmDelete(row: UomRow) {
  if (!canEdit(row)) {
    toast.error(t('uom.errors.systemReadOnly'))
    return
  }
  toDelete.value = row
  showDelete.value = true
}

async function deleteRecord() {
  if (!toDelete.value) return
  const { error } = await supabase.from(TABLE).delete().eq('id', toDelete.value.id)
  if (error) {
    toast.error(t('uom.errors.delete', { message: error.message }))
    return
  }
  rows.value = rows.value.filter((r) => r.id !== toDelete.value?.id)
  showDelete.value = false
  toDelete.value = null
  if (page.value > totalPages.value) page.value = totalPages.value
}

function validate() {
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!form.dimension) errors.dimension = t('uom.errors.dimensionRequired')
  if (!form.code.trim()) errors.code = t('uom.errors.codeRequired')
  if (!form.name_en.trim()) errors.name_en = t('uom.errors.nameEnRequired')

  if (!form.is_base_unit) {
    if (form.base_factor === '' || form.base_factor === null || form.base_factor === undefined) {
      errors.base_factor = t('uom.errors.factorRequired')
    } else {
      const num = Number(form.base_factor)
      if (Number.isNaN(num)) {
        errors.base_factor = t('uom.errors.factorNumber')
      } else if (num <= 0) {
        errors.base_factor = t('uom.errors.factorPositive')
      }
    }
  }

  const dup = rows.value.find(
    (row) =>
      row.dimension === form.dimension &&
      row.code.toLowerCase() === form.code.trim().toLowerCase() &&
      row.id !== form.id,
  )
  if (dup) errors.code = t('uom.errors.codeUnique')

  const baseUnit = rows.value.find(
    (row) => row.dimension === form.dimension && row.is_base_unit && row.id !== form.id,
  )

  if (form.is_base_unit && baseUnit) {
    errors.is_base_unit = t('uom.errors.baseUnitSingle')
  }

  if (!form.is_base_unit && !baseUnit) {
    errors.base_factor = t('uom.errors.baseUnitMissing')
  }

  return Object.keys(errors).length === 0
}

async function saveRecord() {
  if (!validate()) return
  saving.value = true
  try {
    const tenant = await ensureTenant()
    const baseUnit = rows.value.find(
      (row) => row.dimension === form.dimension && row.is_base_unit && row.id !== form.id,
    )

    const isBase = Boolean(form.is_base_unit)
    const baseFactor = isBase ? 1 : Number(form.base_factor)
    const baseCode = isBase ? form.code.trim() : baseUnit?.code ?? null

    const payload: Record<string, any> = {
      code: form.code.trim(),
      name: form.name_en.trim(),
      dimension: form.dimension,
      base_factor: baseFactor,
      base_code: baseCode,
      is_base_unit: isBase,
      scope: 'tenant',
      tenant_id: tenant,
      industry_id: INDUSTRY_ID,
      owner_id: tenant,
      meta: { label: { en: form.name_en.trim(), ja: form.name_ja.trim() || null } },
    }

    let response
    if (editing.value) {
      response = await supabase
        .from(TABLE)
        .update(payload)
        .eq('id', form.id)
        .select('id, code, name, dimension, base_factor, base_code, is_base_unit, scope, industry_id, owner_id, meta, created_at')
        .single()
    } else {
      response = await supabase
        .from(TABLE)
        .insert(payload)
        .select('id, code, name, dimension, base_factor, base_code, is_base_unit, scope, industry_id, owner_id, meta, created_at')
        .single()
    }

    if (response.error) {
      toast.error(t('uom.errors.save', { message: response.error.message }))
      return
    }

    const saved = response.data as UomRow
    const idx = rows.value.findIndex((r) => r.id === saved.id)
    if (idx > -1) rows.value[idx] = saved
    else rows.value.push(saved)

    showModal.value = false
    await fetchUoms()
  } catch (err) {
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  try {
    await ensureTenant()
    await Promise.all([fetchDimensions(), fetchUoms()])
  } catch (err) {
    toast.error(err instanceof Error ? err.message : String(err))
  }
})
</script>

<style scoped>
th, td {
  white-space: nowrap;
}
</style>
