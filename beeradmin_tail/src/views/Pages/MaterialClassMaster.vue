<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto">
      <header class="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('materialClass.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('materialClass.subtitle') }}</p>
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
          <label class="block text-sm text-gray-600 mb-1">{{ t('materialClass.filters.category') }}</label>
          <select v-model="filters.category" class="w-full h-[40px] border rounded px-3 text-sm bg-white">
            <option value="">{{ t('common.all') }}</option>
            <option v-for="option in categoryOptions" :key="option" :value="option">{{ option }}</option>
          </select>
        </div>
      </section>

      <section class="hidden md:block overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialClass.table.name') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialClass.table.label') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialClass.table.category') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialClass.table.alcoholTaxRequired') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialClass.table.manufacturingRequired') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialClass.table.movingControlRequired') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialClass.table.shipmentControlRequired') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialClass.table.description') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialClass.table.createdAt') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in filteredRows" :key="row.def_id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.spec?.name || row.def_key }}</td>
              <td class="px-3 py-2 text-gray-800">{{ row.spec?.label || '—' }}</td>
              <td class="px-3 py-2 text-gray-800">{{ row.spec?.category || '—' }}</td>
              <td class="px-3 py-2 text-sm text-gray-700">{{ boolLabel(row.spec?.alcohol_tax_required_flg) }}</td>
              <td class="px-3 py-2 text-sm text-gray-700">{{ boolLabel(row.spec?.manufacturing_application_required_flg) }}</td>
              <td class="px-3 py-2 text-sm text-gray-700">{{ boolLabel(row.spec?.moving_control_required_flg) }}</td>
              <td class="px-3 py-2 text-sm text-gray-700">{{ boolLabel(row.spec?.shipment_control_required_flg) }}</td>
              <td class="px-3 py-2 text-sm text-gray-600 whitespace-pre-wrap">{{ row.spec?.description || '—' }}</td>
              <td class="px-3 py-2 text-xs text-gray-500">{{ formatTimestamp(row.created_at) }}</td>
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
              <td colspan="10" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section class="md:hidden grid gap-3">
        <div v-for="row in filteredRows" :key="row.def_id" class="border border-gray-200 rounded-xl shadow-sm p-4">
          <div class="flex items-start justify-between gap-3">
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">{{ row.spec?.category || '—' }}</p>
              <h2 class="text-lg font-semibold text-gray-900">{{ row.spec?.label || row.spec?.name || row.def_key }}</h2>
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
              <dt>{{ t('materialClass.table.name') }}</dt>
              <dd class="font-mono text-xs">{{ row.spec?.name || row.def_key }}</dd>
            </div>
            <div class="flex justify-between">
              <dt>{{ t('materialClass.table.alcoholTaxRequired') }}</dt>
              <dd>{{ boolLabel(row.spec?.alcohol_tax_required_flg) }}</dd>
            </div>
            <div class="flex justify-between">
              <dt>{{ t('materialClass.table.manufacturingRequired') }}</dt>
              <dd>{{ boolLabel(row.spec?.manufacturing_application_required_flg) }}</dd>
            </div>
            <div class="flex justify-between">
              <dt>{{ t('materialClass.table.movingControlRequired') }}</dt>
              <dd>{{ boolLabel(row.spec?.moving_control_required_flg) }}</dd>
            </div>
            <div class="flex justify-between">
              <dt>{{ t('materialClass.table.shipmentControlRequired') }}</dt>
              <dd>{{ boolLabel(row.spec?.shipment_control_required_flg) }}</dd>
            </div>
            <div>
              <dt class="font-medium">{{ t('materialClass.table.description') }}</dt>
              <dd class="text-sm text-gray-600">{{ row.spec?.description || '—' }}</dd>
            </div>
            <div class="flex justify-between">
              <dt>{{ t('materialClass.table.createdAt') }}</dt>
              <dd class="text-xs text-gray-500">{{ formatTimestamp(row.created_at) }}</dd>
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
            <h3 class="font-semibold">{{ editing ? t('materialClass.editTitle') : t('materialClass.newTitle') }}</h3>
          </div>
          <div class="p-4 space-y-4">
            <div class="grid grid-cols-1 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('materialClass.form.name') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.name" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
                <p v-if="errors.name" class="mt-1 text-xs text-red-600">{{ errors.name }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('materialClass.form.label') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.label" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.label" class="mt-1 text-xs text-red-600">{{ errors.label }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('materialClass.form.category') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.category" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.category" class="mt-1 text-xs text-red-600">{{ errors.category }}</p>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('materialClass.form.alcoholTaxRequired') }}<span class="text-red-600">*</span></label>
                  <select v-model="form.alcohol_tax_required_flg" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="true">{{ t('common.yes') }}</option>
                    <option value="false">{{ t('common.no') }}</option>
                  </select>
                  <p v-if="errors.alcohol_tax_required_flg" class="mt-1 text-xs text-red-600">{{ errors.alcohol_tax_required_flg }}</p>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('materialClass.form.manufacturingRequired') }}<span class="text-red-600">*</span></label>
                  <select v-model="form.manufacturing_application_required_flg" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="true">{{ t('common.yes') }}</option>
                    <option value="false">{{ t('common.no') }}</option>
                  </select>
                  <p v-if="errors.manufacturing_application_required_flg" class="mt-1 text-xs text-red-600">
                    {{ errors.manufacturing_application_required_flg }}
                  </p>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('materialClass.form.movingControlRequired') }}<span class="text-red-600">*</span></label>
                  <select v-model="form.moving_control_required_flg" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="true">{{ t('common.yes') }}</option>
                    <option value="false">{{ t('common.no') }}</option>
                  </select>
                  <p v-if="errors.moving_control_required_flg" class="mt-1 text-xs text-red-600">{{ errors.moving_control_required_flg }}</p>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('materialClass.form.shipmentControlRequired') }}<span class="text-red-600">*</span></label>
                  <select v-model="form.shipment_control_required_flg" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="true">{{ t('common.yes') }}</option>
                    <option value="false">{{ t('common.no') }}</option>
                  </select>
                  <p v-if="errors.shipment_control_required_flg" class="mt-1 text-xs text-red-600">{{ errors.shipment_control_required_flg }}</p>
                </div>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('materialClass.form.description') }}</label>
                <textarea v-model.trim="form.description" class="w-full min-h-[100px] border rounded px-3 py-2 text-sm" />
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
            <h3 class="font-semibold">{{ t('materialClass.deleteTitle') }}</h3>
          </div>
          <div class="p-4 text-sm">
            {{ t('materialClass.deleteConfirm', { name: toDelete?.spec?.label ?? toDelete?.spec?.name ?? toDelete?.def_key ?? '' }) }}
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
  label?: string | null
  category?: string | null
  alcohol_tax_required_flg?: boolean | null
  manufacturing_application_required_flg?: boolean | null
  moving_control_required_flg?: boolean | null
  shipment_control_required_flg?: boolean | null
  description?: string | null
}

type MaterialClassRow = {
  def_id: string
  def_key: string
  scope: string
  owner_id: string | null
  spec: RegistrySpec | null
  created_at: string | null
}

const TABLE = 'registry_def'
const KIND = 'material_class'

const { t } = useI18n()
const pageTitle = computed(() => t('materialClass.title'))

const rows = ref<MaterialClassRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const selected = ref<MaterialClassRow | null>(null)
const toDelete = ref<MaterialClassRow | null>(null)
const tenantId = ref<string | null>(null)
const isAdmin = ref(false)

const filters = reactive({
  category: '',
})

const form = reactive({
  name: '',
  label: '',
  category: '',
  alcohol_tax_required_flg: 'false',
  manufacturing_application_required_flg: 'false',
  moving_control_required_flg: 'false',
  shipment_control_required_flg: 'false',
  description: '',
})

const errors = reactive({
  name: '',
  label: '',
  category: '',
  alcohol_tax_required_flg: '',
  manufacturing_application_required_flg: '',
  moving_control_required_flg: '',
  shipment_control_required_flg: '',
})

const categoryOptions = computed(() => {
  const options = rows.value
    .map((row) => (row.spec?.category ? String(row.spec.category) : ''))
    .filter((value) => value)
  return Array.from(new Set(options)).sort((a, b) => a.localeCompare(b))
})

const filteredRows = computed(() => {
  const categoryFilter = filters.category.trim().toLowerCase()
  return rows.value.filter((row) => {
    const category = String(row.spec?.category ?? '').toLowerCase()
    return !categoryFilter || category.includes(categoryFilter)
  })
})

function formatTimestamp(value: string | null | undefined) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleString()
}

function normalizeKey(value: string) {
  const cleaned = value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9._-]+/g, '_')
    .replace(/_+/g, '_')
    .replace(/^_+|_+$/g, '')
  if (!cleaned) {
    return `material_class_${Date.now()}`
  }
  const trimmed = cleaned.slice(0, 64)
  return /^[a-z0-9]/.test(trimmed) ? trimmed : `m_${trimmed}`.slice(0, 64)
}

function boolLabel(value: boolean | null | undefined) {
  if (value === true) return t('common.yes')
  if (value === false) return t('common.no')
  return '—'
}

function parseBoolean(value: string) {
  if (value === 'true') return true
  if (value === 'false') return false
  return null
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

function canEdit(row: MaterialClassRow) {
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
    rows.value = (data ?? []) as MaterialClassRow[]
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
  errors.label = ''
  errors.category = ''
  errors.alcohol_tax_required_flg = ''
  errors.manufacturing_application_required_flg = ''
  errors.moving_control_required_flg = ''
  errors.shipment_control_required_flg = ''
}

function openCreate() {
  editing.value = false
  selected.value = null
  form.name = ''
  form.label = ''
  form.category = ''
  form.alcohol_tax_required_flg = 'false'
  form.manufacturing_application_required_flg = 'false'
  form.moving_control_required_flg = 'false'
  form.shipment_control_required_flg = 'false'
  form.description = ''
  resetErrors()
  showModal.value = true
}

function openEdit(row: MaterialClassRow) {
  if (!canEdit(row)) {
    toast.error(t('materialClass.errors.adminOnlySystem'))
    return
  }
  editing.value = true
  selected.value = row
  form.name = String(row.spec?.name ?? '')
  form.label = String(row.spec?.label ?? '')
  form.category = String(row.spec?.category ?? '')
  form.alcohol_tax_required_flg = row.spec?.alcohol_tax_required_flg === true ? 'true' : 'false'
  form.manufacturing_application_required_flg =
    row.spec?.manufacturing_application_required_flg === true ? 'true' : 'false'
  form.moving_control_required_flg = row.spec?.moving_control_required_flg === true ? 'true' : 'false'
  form.shipment_control_required_flg = row.spec?.shipment_control_required_flg === true ? 'true' : 'false'
  form.description = String(row.spec?.description ?? '')
  resetErrors()
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function confirmDelete(row: MaterialClassRow) {
  if (!canEdit(row)) {
    toast.error(t('materialClass.errors.adminOnlySystem'))
    return
  }
  toDelete.value = row
  showDelete.value = true
}

function buildSpec(): RegistrySpec {
  return {
    name: form.name.trim() || null,
    label: form.label.trim() || null,
    category: form.category.trim() || null,
    alcohol_tax_required_flg: parseBoolean(form.alcohol_tax_required_flg),
    manufacturing_application_required_flg: parseBoolean(form.manufacturing_application_required_flg),
    moving_control_required_flg: parseBoolean(form.moving_control_required_flg),
    shipment_control_required_flg: parseBoolean(form.shipment_control_required_flg),
    description: form.description.trim() || null,
  }
}

async function saveRecord() {
  resetErrors()
  const nameValue = String(form.name ?? '').trim()
  const labelValue = String(form.label ?? '').trim()
  const categoryValue = String(form.category ?? '').trim()

  if (!nameValue) {
    errors.name = t('materialClass.errors.nameRequired')
  }
  if (!labelValue) {
    errors.label = t('materialClass.errors.labelRequired')
  }
  if (!categoryValue) {
    errors.category = t('materialClass.errors.categoryRequired')
  }
  if (parseBoolean(form.alcohol_tax_required_flg) === null) {
    errors.alcohol_tax_required_flg = t('materialClass.errors.flagInvalid')
  }
  if (parseBoolean(form.manufacturing_application_required_flg) === null) {
    errors.manufacturing_application_required_flg = t('materialClass.errors.flagInvalid')
  }
  if (parseBoolean(form.moving_control_required_flg) === null) {
    errors.moving_control_required_flg = t('materialClass.errors.flagInvalid')
  }
  if (parseBoolean(form.shipment_control_required_flg) === null) {
    errors.shipment_control_required_flg = t('materialClass.errors.flagInvalid')
  }

  if (
    errors.name ||
    errors.label ||
    errors.category ||
    errors.alcohol_tax_required_flg ||
    errors.manufacturing_application_required_flg ||
    errors.moving_control_required_flg ||
    errors.shipment_control_required_flg
  ) {
    return
  }

  try {
    saving.value = true
    const spec = buildSpec()

    if (editing.value && selected.value) {
      if (selected.value.scope === 'system' && !isAdmin.value) {
        toast.error(t('materialClass.errors.adminOnlySystem'))
        return
      }
      const { error } = await supabase
        .from(TABLE)
        .update({ spec, updated_at: new Date().toISOString() })
        .eq('def_id', selected.value.def_id)
      if (error) throw error
    } else {
      const tenant = await ensureTenant()
      const defKey = normalizeKey(form.name)
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
