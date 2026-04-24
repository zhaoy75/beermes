<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4">
      <header class="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('siteType.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('siteType.subtitle') }}</p>
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
          <label class="block text-sm text-gray-600 mb-1">{{ t('siteType.filters.name') }}</label>
          <input
            v-model.trim="filters.name"
            type="search"
            :placeholder="t('siteType.filters.namePlaceholder')"
            class="w-full h-[40px] border rounded px-3 text-sm"
          />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1">{{ t('siteType.filters.inventoryCount') }}</label>
          <select v-model="filters.inventoryCount" class="w-full h-[40px] border rounded px-3 text-sm bg-white">
            <option value="">{{ t('common.all') }}</option>
            <option value="true">{{ t('common.yes') }}</option>
            <option value="false">{{ t('common.no') }}</option>
          </select>
        </div>
      </section>

      <section class="hidden md:block overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setSort('name')">
                  <span>{{ t('siteType.table.name') }}</span>
                  <span v-if="sortIcon('name')" class="text-xs">{{ sortIcon('name') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setSort('inventoryCount')">
                  <span>{{ t('siteType.table.inventoryCount') }}</span>
                  <span v-if="sortIcon('inventoryCount')" class="text-xs">{{ sortIcon('inventoryCount') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setSort('description')">
                  <span>{{ t('siteType.table.description') }}</span>
                  <span v-if="sortIcon('description')" class="text-xs">{{ sortIcon('description') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setSort('createdAt')">
                  <span>{{ t('siteType.table.createdAt') }}</span>
                  <span v-if="sortIcon('createdAt')" class="text-xs">{{ sortIcon('createdAt') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in sortedRows" :key="row.def_id" class="hover:bg-gray-50">
              <td class="px-3 py-2">{{ row.spec?.name || row.def_key }}</td>
              <td class="px-3 py-2 text-sm text-gray-700">
                {{ row.spec?.inventory_count_flg === true ? t('common.yes') : row.spec?.inventory_count_flg === false ? t('common.no') : '—' }}
              </td>
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
            <tr v-if="!loading && sortedRows.length === 0">
              <td colspan="5" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section class="md:hidden grid gap-3">
        <div v-for="row in sortedRows" :key="row.def_id" class="border border-gray-200 rounded-xl shadow-sm p-4">
          <div class="flex items-start justify-between gap-3">
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">
                {{ row.spec?.inventory_count_flg === true ? t('common.yes') : row.spec?.inventory_count_flg === false ? t('common.no') : '—' }}
              </p>
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
            <div>
              <dt class="font-medium">{{ t('siteType.table.description') }}</dt>
              <dd class="text-sm text-gray-600">{{ row.spec?.description || '—' }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('siteType.table.createdAt') }}</dt>
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
            <h3 class="font-semibold">{{ editing ? t('siteType.editTitle') : t('siteType.newTitle') }}</h3>
          </div>
          <div class="p-4 space-y-4">
            <div class="grid grid-cols-1 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('siteType.form.name') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.name" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.name" class="mt-1 text-xs text-red-600">{{ errors.name }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('siteType.form.inventoryCount') }}<span class="text-red-600">*</span></label>
                <select v-model="form.inventory_count_flg" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="true">{{ t('common.yes') }}</option>
                  <option value="false">{{ t('common.no') }}</option>
                </select>
                <p v-if="errors.inventory_count_flg" class="mt-1 text-xs text-red-600">{{ errors.inventory_count_flg }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('siteType.form.description') }}</label>
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
            <h3 class="font-semibold">{{ t('siteType.deleteTitle') }}</h3>
          </div>
          <div class="p-4 text-sm">
            {{ t('siteType.deleteConfirm', { name: toDelete?.spec?.name ?? toDelete?.def_key ?? '' }) }}
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
import { useTableSort } from '@/composables/useTableSort'

type RegistrySpec = {
  name?: string | null
  inventory_count_flg?: boolean | null
  description?: string | null
}

type SiteTypeRow = {
  def_id: string
  def_key: string
  scope: string
  owner_id: string | null
  spec: RegistrySpec | null
  created_at: string | null
}

type SortKey = 'name' | 'inventoryCount' | 'description' | 'createdAt'

const TABLE = 'registry_def'
const KIND = 'site_type'

const { t } = useI18n()
const pageTitle = computed(() => t('siteType.title'))

const rows = ref<SiteTypeRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const selected = ref<SiteTypeRow | null>(null)
const toDelete = ref<SiteTypeRow | null>(null)
const tenantId = ref<string | null>(null)
const isAdmin = ref(false)

const filters = reactive({
  name: '',
  inventoryCount: '',
})

const form = reactive({
  name: '',
  inventory_count_flg: 'false',
  description: '',
})

const errors = reactive({
  name: '',
  inventory_count_flg: '',
})

const filteredRows = computed(() => {
  const nameFilter = filters.name.trim().toLowerCase()
  const countFilter = filters.inventoryCount.trim().toLowerCase()

  return rows.value.filter((row) => {
    const name = String(row.spec?.name ?? row.def_key ?? '').toLowerCase()
    const inventoryValue = row.spec?.inventory_count_flg
    const inventoryText = inventoryValue === true ? 'true' : inventoryValue === false ? 'false' : ''
    const matchName = !nameFilter || name.includes(nameFilter)
    const matchInventory = !countFilter || inventoryText === countFilter
    return matchName && matchInventory
  })
})

const { sortedRows, setSort, sortIcon } = useTableSort<SiteTypeRow, SortKey>(
  filteredRows,
  {
    name: (row) => row.spec?.name ?? row.def_key,
    inventoryCount: (row) => row.spec?.inventory_count_flg,
    description: (row) => row.spec?.description,
    createdAt: (row) => (row.created_at ? Date.parse(row.created_at) : null),
  },
  'createdAt',
  'desc',
)

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
    return `site_type_${Date.now()}`
  }
  const trimmed = cleaned.slice(0, 64)
  return /^[a-z0-9]/.test(trimmed) ? trimmed : `s_${trimmed}`.slice(0, 64)
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

function canEdit(row: SiteTypeRow) {
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
    rows.value = (data ?? []) as SiteTypeRow[]
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
  errors.inventory_count_flg = ''
}

function openCreate() {
  editing.value = false
  selected.value = null
  form.name = ''
  form.inventory_count_flg = 'false'
  form.description = ''
  resetErrors()
  showModal.value = true
}

function openEdit(row: SiteTypeRow) {
  if (!canEdit(row)) {
    toast.error(t('siteType.errors.adminOnlySystem'))
    return
  }
  editing.value = true
  selected.value = row
  form.name = String(row.spec?.name ?? '')
  form.inventory_count_flg = row.spec?.inventory_count_flg === true ? 'true' : 'false'
  form.description = String(row.spec?.description ?? '')
  resetErrors()
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function confirmDelete(row: SiteTypeRow) {
  if (!canEdit(row)) {
    toast.error(t('siteType.errors.adminOnlySystem'))
    return
  }
  toDelete.value = row
  showDelete.value = true
}

function parseBoolean(value: string) {
  if (value === 'true') return true
  if (value === 'false') return false
  return null
}

function buildSpec(): RegistrySpec {
  return {
    name: form.name.trim() || null,
    inventory_count_flg: parseBoolean(form.inventory_count_flg),
    description: form.description.trim() || null,
  }
}

async function saveRecord() {
  resetErrors()
  if (!form.name.trim()) {
    errors.name = t('siteType.errors.nameRequired')
  }
  if (parseBoolean(form.inventory_count_flg) === null) {
    errors.inventory_count_flg = t('siteType.errors.inventoryCountInvalid')
  }

  if (errors.name || errors.inventory_count_flg) return

  try {
    saving.value = true
    const spec = buildSpec()

    if (editing.value && selected.value) {
      if (selected.value.scope === 'system' && !isAdmin.value) {
        toast.error(t('siteType.errors.adminOnlySystem'))
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
