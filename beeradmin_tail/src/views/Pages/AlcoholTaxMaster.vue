<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto">
      <header class="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('alcoholTax.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('alcoholTax.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">
            {{ t('common.new') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="fetchRows"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="mb-4 grid grid-cols-1 md:grid-cols-2 gap-3">
        <div>
          <label class="block text-sm text-gray-600 mb-1">{{ t('alcoholTax.filters.name') }}</label>
          <input
            v-model.trim="filters.name"
            type="search"
            :placeholder="t('alcoholTax.filters.namePlaceholder')"
            class="w-full h-[40px] border rounded px-3 text-sm"
          />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1">{{ t('alcoholTax.filters.taxCategoryCode') }}</label>
          <input
            v-model.trim="filters.taxCategoryCode"
            type="search"
            :placeholder="t('alcoholTax.filters.taxCategoryPlaceholder')"
            class="w-full h-[40px] border rounded px-3 text-sm"
          />
        </div>
      </section>

      <section class="hidden md:block overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                {{ t('alcoholTax.table.name') }}
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                {{ t('alcoholTax.table.taxCategoryCode') }}
              </th>
              <th class="px-3 py-2 text-right text-xs font-medium text-gray-600">
                {{ t('alcoholTax.table.taxRate') }}
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                {{ t('alcoholTax.table.startDate') }}
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                {{ t('alcoholTax.table.expirationDate') }}
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in filteredRows" :key="row.def_id" class="hover:bg-gray-50">
              <td class="px-3 py-2">{{ row.spec?.name || row.def_key }}</td>
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.spec?.tax_category_code ?? '—' }}</td>
              <td class="px-3 py-2 text-right font-mono text-xs text-gray-700">{{ formatRate(row.spec?.tax_rate) }}</td>
              <td class="px-3 py-2 text-xs text-gray-600">{{ formatDate(row.spec?.start_date) }}</td>
              <td class="px-3 py-2 text-xs text-gray-600">{{ formatDate(row.spec?.expiration_date) }}</td>
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
            <tr v-if="!loading && filteredRows.length === 0">
              <td colspan="6" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section class="md:hidden grid gap-3">
        <div v-for="row in filteredRows" :key="row.def_id" class="border border-gray-200 rounded-xl shadow-sm p-4">
          <div class="flex items-start justify-between gap-3">
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">{{ row.spec?.tax_category_code ?? '—' }}</p>
              <h2 class="text-lg font-semibold text-gray-900">{{ row.spec?.name || row.def_key }}</h2>
            </div>
            <button
              class="px-2 py-1 text-xs rounded border hover:bg-gray-100 disabled:opacity-50"
              :disabled="!canEdit(row)"
              @click="openEdit(row)"
            >
              {{ t('common.edit') }}
            </button>
          </div>
          <dl class="text-sm text-gray-600 space-y-1 mt-2">
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('alcoholTax.table.taxRate') }}</dt>
              <dd class="font-mono">{{ formatRate(row.spec?.tax_rate) }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('alcoholTax.table.startDate') }}</dt>
              <dd>{{ formatDate(row.spec?.start_date) }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('alcoholTax.table.expirationDate') }}</dt>
              <dd>{{ formatDate(row.spec?.expiration_date) }}</dd>
            </div>
          </dl>
          <div class="mt-3 flex gap-2">
            <button
              class="px-3 py-2 text-sm rounded border hover:bg-gray-100 disabled:opacity-50"
              :disabled="!canEdit(row)"
              @click="openEdit(row)"
            >
              {{ t('common.edit') }}
            </button>
            <button
              class="px-3 py-2 text-sm rounded bg-red-600 text-white hover:bg-red-700 disabled:opacity-50"
              :disabled="!canEdit(row)"
              @click="confirmDelete(row)"
            >
              {{ t('common.delete') }}
            </button>
          </div>
        </div>
        <p v-if="!loading && filteredRows.length === 0" class="text-center text-gray-500 text-sm">
          {{ t('common.noData') }}
        </p>
      </section>

      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ editing ? t('alcoholTax.editTitle') : t('alcoholTax.newTitle') }}</h3>
          </div>
          <div class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1">{{ t('alcoholTax.form.name') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.name" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.name" class="mt-1 text-xs text-red-600">{{ errors.name }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('alcoholTax.form.taxCategoryCode') }}<span class="text-red-600">*</span></label>
                <input
                  v-model.trim="form.tax_category_code"
                  type="number"
                  step="1"
                  inputmode="numeric"
                  class="w-full h-[40px] border rounded px-3 font-mono text-sm"
                />
                <p v-if="errors.tax_category_code" class="mt-1 text-xs text-red-600">{{ errors.tax_category_code }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('alcoholTax.form.taxRate') }}<span class="text-red-600">*</span></label>
                <input
                  v-model.trim="form.tax_rate"
                  type="number"
                  step="0.01"
                  inputmode="decimal"
                  class="w-full h-[40px] border rounded px-3 font-mono text-sm"
                />
                <p v-if="errors.tax_rate" class="mt-1 text-xs text-red-600">{{ errors.tax_rate }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('alcoholTax.form.startDate') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.start_date" type="date" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.start_date" class="mt-1 text-xs text-red-600">{{ errors.start_date }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('alcoholTax.form.expirationDate') }}</label>
                <input v-model.trim="form.expiration_date" type="date" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.expiration_date" class="mt-1 text-xs text-red-600">{{ errors.expiration_date }}</p>
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
            <h3 class="font-semibold">{{ t('alcoholTax.deleteTitle') }}</h3>
          </div>
          <div class="p-4 text-sm">
            {{ t('alcoholTax.deleteConfirm', { name: toDelete?.spec?.name ?? toDelete?.def_key ?? '' }) }}
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="showDelete = false">{{ t('common.cancel') }}</button>
            <button
              class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700 disabled:opacity-50"
              :disabled="saving"
              @click="deleteRecord"
            >
              {{ t('common.delete') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

type RegistrySpec = {
  name?: string | null
  tax_category_code?: number | string | null
  tax_rate?: number | string | null
  start_date?: string | null
  expiration_date?: string | null
}

type AlcoholTaxRow = {
  def_id: string
  def_key: string
  scope: string
  owner_id: string | null
  spec: RegistrySpec | null
  created_at: string | null
}

const TABLE = 'registry_def'
const KIND = 'alcohol_tax'

const { t } = useI18n()
const pageTitle = computed(() => t('alcoholTax.title'))

const rows = ref<AlcoholTaxRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const selected = ref<AlcoholTaxRow | null>(null)
const toDelete = ref<AlcoholTaxRow | null>(null)
const tenantId = ref<string | null>(null)
const isAdmin = ref(false)

const filters = reactive({
  name: '',
  taxCategoryCode: '',
})

const form = reactive({
  name: '',
  tax_category_code: '',
  tax_rate: '',
  start_date: '',
  expiration_date: '',
})

const errors = reactive({
  name: '',
  tax_category_code: '',
  tax_rate: '',
  start_date: '',
  expiration_date: '',
})

const filteredRows = computed(() => {
  const nameFilter = filters.name.trim().toLowerCase()
  const taxFilter = filters.taxCategoryCode.trim().toLowerCase()

  return rows.value.filter((row) => {
    const name = String(row.spec?.name ?? row.def_key ?? '').toLowerCase()
    const taxCode = String(row.spec?.tax_category_code ?? '').toLowerCase()
    const matchName = !nameFilter || name.includes(nameFilter)
    const matchTax = !taxFilter || taxCode.includes(taxFilter)
    return matchName && matchTax
  })
})

function formatDate(value: string | null | undefined) {
  if (!value) return '—'
  return value
}

function formatRate(value: number | string | null | undefined) {
  if (value === null || value === undefined || value === '') return '—'
  const num = Number(value)
  if (Number.isNaN(num)) return String(value)
  return num.toFixed(2)
}

function normalizeKey(value: string) {
  const cleaned = value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9._-]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '')
  if (!cleaned) {
    return `alcohol_tax_${Date.now()}`
  }
  const trimmed = cleaned.slice(0, 64)
  return /^[a-z0-9]/.test(trimmed) ? trimmed : `a_${trimmed}`.slice(0, 64)
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved in session')
  tenantId.value = id
  const role = String(data.user?.app_metadata?.role ?? data.user?.user_metadata?.role ?? '').toLowerCase()
  const isAdminFlag = Boolean(data.user?.app_metadata?.is_admin || data.user?.user_metadata?.is_admin)
  isAdmin.value = isAdminFlag || role === 'admin'
  return id
}

function canEdit(row: AlcoholTaxRow) {
  if (row.scope === 'system') return isAdmin.value
  return true
}

async function fetchRows() {
  try {
    loading.value = true
    const { data, error } = await supabase
      .from(TABLE)
      .select('def_id, def_key, scope, owner_id, spec, created_at')
      .eq('kind', KIND)
      .order('created_at', { ascending: false })
    if (error) throw error
    rows.value = (data ?? []) as AlcoholTaxRow[]
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
    rows.value = []
  } finally {
    loading.value = false
  }
}

function resetErrors() {
  errors.name = ''
  errors.tax_category_code = ''
  errors.tax_rate = ''
  errors.start_date = ''
  errors.expiration_date = ''
}

function openCreate() {
  editing.value = false
  selected.value = null
  form.name = ''
  form.tax_category_code = ''
  form.tax_rate = ''
  form.start_date = ''
  form.expiration_date = ''
  resetErrors()
  showModal.value = true
}

function openEdit(row: AlcoholTaxRow) {
  if (!canEdit(row)) {
    toast.error(t('alcoholTax.errors.adminOnlySystem'))
    return
  }
  editing.value = true
  selected.value = row
  form.name = String(row.spec?.name ?? '')
  form.tax_category_code = row.spec?.tax_category_code != null ? String(row.spec?.tax_category_code) : ''
  form.tax_rate = row.spec?.tax_rate != null ? String(row.spec?.tax_rate) : ''
  form.start_date = row.spec?.start_date ?? ''
  form.expiration_date = row.spec?.expiration_date ?? ''
  resetErrors()
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function confirmDelete(row: AlcoholTaxRow) {
  if (!canEdit(row)) {
    toast.error(t('alcoholTax.errors.adminOnlySystem'))
    return
  }
  toDelete.value = row
  showDelete.value = true
}

function parseNumber(value: unknown) {
  const num = Number(String(value ?? '').trim())
  return Number.isFinite(num) ? num : null
}

function isValidDate(value: string) {
  if (!value) return false
  const parsed = Date.parse(value)
  return !Number.isNaN(parsed)
}

function buildSpec(): RegistrySpec {
  return {
    name: form.name.trim() || null,
    tax_category_code: parseNumber(form.tax_category_code),
    tax_rate: parseNumber(form.tax_rate),
    start_date: form.start_date || null,
    expiration_date: form.expiration_date || null,
  }
}

async function saveRecord() {
  resetErrors()
  const nameValue = String(form.name ?? '').trim()
  const taxCodeValue = String(form.tax_category_code ?? '').trim()
  const taxRateValue = String(form.tax_rate ?? '').trim()
  const startDateValue = String(form.start_date ?? '').trim()
  const expirationDateValue = String(form.expiration_date ?? '').trim()

  if (!nameValue) {
    errors.name = t('alcoholTax.errors.nameRequired')
  }
  if (!taxCodeValue || parseNumber(taxCodeValue) === null) {
    errors.tax_category_code = t('alcoholTax.errors.taxCategoryCodeInvalid')
  }
  if (!taxRateValue || parseNumber(taxRateValue) === null) {
    errors.tax_rate = t('alcoholTax.errors.taxRateInvalid')
  }
  if (!startDateValue || !isValidDate(startDateValue)) {
    errors.start_date = t('alcoholTax.errors.startDateInvalid')
  }
  if (expirationDateValue && !isValidDate(expirationDateValue)) {
    errors.expiration_date = t('alcoholTax.errors.expirationDateInvalid')
  }

  if (errors.name || errors.tax_category_code || errors.tax_rate || errors.start_date || errors.expiration_date) {
    return
  }

  try {
    saving.value = true
    const spec = buildSpec()

    if (editing.value && selected.value) {
      if (selected.value.scope === 'system' && !isAdmin.value) {
        toast.error(t('alcoholTax.errors.adminOnlySystem'))
        return
      }
      const { error } = await supabase
        .from(TABLE)
        .update({ spec, updated_at: new Date().toISOString() })
        .eq('def_id', selected.value.def_id)
      if (error) throw error
    } else {
      const tenant = await ensureTenant()
      const defKey = normalizeKey(`${form.name}-${form.start_date}`)
      const payload = {
        kind: KIND,
        def_key: defKey,
        scope: 'tenant',
        owner_id: tenant,
        spec,
      }
      const { error } = await supabase.from(TABLE).insert(payload)
      if (error) throw error
    }

    closeModal()
    await fetchRows()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

async function deleteRecord() {
  if (!toDelete.value) return
  try {
    saving.value = true
    const { error } = await supabase.from(TABLE).delete().eq('def_id', toDelete.value.def_id)
    if (error) throw error
    showDelete.value = false
    toDelete.value = null
    await fetchRows()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

onMounted(async () => {
  try {
    await ensureTenant()
    await fetchRows()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
})
</script>
