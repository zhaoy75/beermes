<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto space-y-4">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('site.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('site.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">
            {{ t('common.new') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="fetchSites"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white">
        <form class="grid grid-cols-1 md:grid-cols-3 gap-3" @submit.prevent>
          <div class="md:col-span-2">
            <label class="block text-sm text-gray-600 mb-1" for="siteSearch">{{ t('common.search') }}</label>
            <input
              id="siteSearch"
              v-model.trim="filters.keyword"
              :placeholder="t('site.filters.namePlaceholder')"
              class="w-full h-[40px] border rounded px-3"
              type="search"
            />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="siteTypeFilter">{{ t('site.filters.siteType') }}</label>
            <select id="siteTypeFilter" v-model="filters.siteType" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="type in siteTypeOptions" :key="type.value" :value="type.value">
                {{ type.label }}
              </option>
            </select>
          </div>
        </form>
      </section>

      <section class="hidden md:block overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50 text-xs text-gray-600 uppercase">
            <tr>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('code')">{{ t('site.table.code') }}<span v-if="sortKey === 'code'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('name')">{{ t('site.table.name') }}<span v-if="sortKey === 'name'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('site_type_name')">{{ t('site.table.siteType') }}<span v-if="sortKey === 'site_type_name'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('parent_name')">{{ t('site.table.parent') }}<span v-if="sortKey === 'parent_name'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('active')">{{ t('site.table.active') }}<span v-if="sortKey === 'active'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('created_at')">{{ t('site.table.createdAt') }}<span v-if="sortKey === 'created_at'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100 text-sm">
            <tr v-for="row in sortedRows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.code }}</td>
              <td class="px-3 py-2 text-gray-800">{{ row.name }}</td>
              <td class="px-3 py-2 text-gray-600">{{ row.siteTypeName || '—' }}</td>
              <td class="px-3 py-2 text-gray-600">{{ row.parentName || '—' }}</td>
              <td class="px-3 py-2">
                <span class="inline-flex items-center gap-1 text-xs px-2 py-1 rounded-full border" :class="row.active ? 'border-green-200 bg-green-50 text-green-700' : 'border-gray-200 bg-gray-50 text-gray-500'">
                  <span class="h-2 w-2 rounded-full" :class="row.active ? 'bg-green-500' : 'bg-gray-400'" />
                  {{ row.active ? t('common.yes') : t('common.no') }}
                </span>
              </td>
              <td class="px-3 py-2 text-xs text-gray-500">{{ formatTimestamp(row.created_at) }}</td>
              <td class="px-3 py-2 space-x-2">
                <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openEdit(row)">{{ t('common.edit') }}</button>
                <button class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">{{ t('common.delete') }}</button>
              </td>
            </tr>
            <tr v-if="!loading && sortedRows.length === 0">
              <td colspan="7" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section class="md:hidden grid gap-3">
        <article v-for="row in sortedRows" :key="row.id" class="border border-gray-200 rounded-xl shadow-sm p-4 space-y-2">
          <header class="flex items-center justify-between">
            <div>
              <p class="text-xs uppercase text-gray-400">{{ row.code }}</p>
              <h2 class="text-lg font-semibold text-gray-900">{{ row.name }}</h2>
            </div>
            <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openEdit(row)">{{ t('common.edit') }}</button>
          </header>
          <dl class="text-sm text-gray-600 space-y-1">
            <div class="flex justify-between"><dt>{{ t('site.table.siteType') }}</dt><dd>{{ row.siteTypeName || '—' }}</dd></div>
            <div class="flex justify-between"><dt>{{ t('site.table.parent') }}</dt><dd>{{ row.parentName || '—' }}</dd></div>
            <div class="flex justify-between"><dt>{{ t('site.table.active') }}</dt><dd>{{ row.active ? t('common.yes') : t('common.no') }}</dd></div>
            <div class="flex justify-between"><dt>{{ t('site.table.createdAt') }}</dt><dd class="text-xs text-gray-500">{{ formatTimestamp(row.created_at) }}</dd></div>
          </dl>
          <footer class="flex gap-2">
            <button class="px-3 py-2 text-sm rounded border hover:bg-gray-100" @click="openEdit(row)">{{ t('common.edit') }}</button>
            <button class="px-3 py-2 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">{{ t('common.delete') }}</button>
          </footer>
        </article>
        <p v-if="!loading && sortedRows.length === 0" class="text-center text-sm text-gray-500">{{ t('common.noData') }}</p>
      </section>

      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg border">
          <header class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ editing ? t('site.editTitle') : t('site.newTitle') }}</h3>
          </header>
          <section class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('site.table.code') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.code" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.code" class="text-xs text-red-600 mt-1">{{ errors.code }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('site.table.name') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.name" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.name" class="text-xs text-red-600 mt-1">{{ errors.name }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('site.table.siteType') }}<span class="text-red-600">*</span></label>
                <select v-model="form.site_type_id" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('site.filters.siteType') }}</option>
                  <option v-for="type in siteTypeOptions" :key="type.value" :value="type.value">{{ type.label }}</option>
                </select>
                <p v-if="errors.site_type_id" class="text-xs text-red-600 mt-1">{{ errors.site_type_id }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('site.table.parent') }}</label>
                <select v-model="form.parent_site_id" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('common.none') }}</option>
                  <option v-for="option in parentOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
              </div>
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1">{{ t('site.form.address') }}</label>
                <textarea v-model.trim="form.address" rows="3" class="w-full border rounded px-3 py-2 font-mono text-xs" placeholder='{"address1":"..."}'></textarea>
                <p v-if="errors.address" class="text-xs text-red-600 mt-1">{{ errors.address }}</p>
              </div>
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1">{{ t('site.form.contact') }}</label>
                <textarea v-model.trim="form.contact" rows="2" class="w-full border rounded px-3 py-2 font-mono text-xs" placeholder='{"phone":"..."}'></textarea>
                <p v-if="errors.contact" class="text-xs text-red-600 mt-1">{{ errors.contact }}</p>
              </div>
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1">{{ t('site.form.notes') }}</label>
                <textarea v-model.trim="form.notes" rows="2" class="w-full border rounded px-3 py-2"></textarea>
              </div>
              <div class="flex items-center gap-2 md:col-span-2">
                <input id="siteActive" v-model="form.active" type="checkbox" class="h-4 w-4" />
                <label for="siteActive" class="text-sm text-gray-700">{{ t('site.form.active') }}</label>
              </div>
            </div>
          </section>
          <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" :disabled="saving" @click="saveRecord">
              {{ saving ? t('common.saving') : t('common.save') }}
            </button>
          </footer>
        </div>
      </div>

      <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
          <header class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('site.deleteTitle') }}</h3>
          </header>
          <section class="p-4 text-sm">{{ t('site.deleteConfirm', { code: toDelete?.code ?? '' }) }}</section>
          <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="showDelete = false">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700" @click="deleteRecord">{{ t('common.delete') }}</button>
          </footer>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'

interface SiteRow {
  id: string
  tenant_id?: string
  code: string
  name: string
  site_type_id: string
  parent_site_id: string | null
  address: any
  contact: any
  notes: string | null
  active: boolean
  created_at: string | null
  siteTypeName: string | null
  parentName: string | null
}

type SortKey = 'code' | 'name' | 'site_type_name' | 'parent_name' | 'active' | 'created_at'
type SortDirection = 'asc' | 'desc'

const TABLE = 'mst_sites'

const { t } = useI18n()
const pageTitle = computed(() => t('site.title'))

const rows = ref<SiteRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const toDelete = ref<SiteRow | null>(null)

const sortKey = ref<SortKey>('code')
const sortDirection = ref<SortDirection>('asc')

const filters = reactive({ keyword: '', siteType: '' })
const tenantId = ref<string | null>(null)

const siteTypes = ref<Array<{ id: string; code: string; name: string }>>([])

const form = reactive({
  id: '',
  code: '',
  name: '',
  site_type_id: '',
  parent_site_id: '',
  address: '',
  contact: '',
  notes: '',
  active: true,
})

const errors = reactive<Record<string, string>>({})

const sortGlyph = computed(() => (sortDirection.value === 'asc' ? '▲' : '▼'))

const siteTypeOptions = computed(() =>
  siteTypes.value.map((item) => ({ value: item.id, label: item.name || item.code })),
)

const parentOptions = computed(() =>
  rows.value
    .filter((row) => !form.id || row.id !== form.id)
    .map((row) => ({ value: row.id, label: `${row.code} — ${row.name}` })),
)

const filteredRows = computed(() => {
  const keyword = filters.keyword.trim().toLowerCase()
  const siteTypeFilter = filters.siteType
  return rows.value.filter((row) => {
    const matchesKeyword = !keyword || row.code.toLowerCase().includes(keyword) || row.name.toLowerCase().includes(keyword)
    const matchesType = !siteTypeFilter || row.site_type_id === siteTypeFilter
    return matchesKeyword && matchesType
  })
})

const sortedRows = computed(() => {
  const list = [...filteredRows.value]
  list.sort((a, b) => {
    const dir = sortDirection.value === 'asc' ? 1 : -1
    const key = sortKey.value
    const av = (a as any)[key]
    const bv = (b as any)[key]
    if (av == null && bv == null) return 0
    if (av == null) return 1
    if (bv == null) return -1
    if (key === 'active') return dir * ((av ? 1 : 0) - (bv ? 1 : 0))
    if (key === 'created_at') return dir * (new Date(av).getTime() - new Date(bv).getTime())
    return dir * String(av).localeCompare(String(bv))
  })
  return list
})

function setSort(key: SortKey) {
  if (sortKey.value === key) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = key
    sortDirection.value = 'asc'
  }
}

function formatTimestamp(value: string | null) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
  } catch {
    return value
  }
}

function resetForm() {
  form.id = ''
  form.code = ''
  form.name = ''
  form.site_type_id = ''
  form.parent_site_id = ''
  form.address = ''
  form.contact = ''
  form.notes = ''
  form.active = true
  Object.keys(errors).forEach((key) => delete errors[key])
}

function openCreate() {
  editing.value = false
  resetForm()
  showModal.value = true
}

function openEdit(row: SiteRow) {
  editing.value = true
  resetForm()
  form.id = row.id
  form.code = row.code
  form.name = row.name
  form.site_type_id = row.site_type_id
  form.parent_site_id = row.parent_site_id ?? ''
  form.address = row.address ? JSON.stringify(row.address, null, 2) : ''
  form.contact = row.contact ? JSON.stringify(row.contact, null, 2) : ''
  form.notes = row.notes ?? ''
  form.active = row.active
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function confirmDelete(row: SiteRow) {
  toDelete.value = row
  showDelete.value = true
}

function validateJson(value: string, fieldKey: 'address' | 'contact') {
  const trimmed = value.trim()
  if (!trimmed) {
    delete errors[fieldKey]
    return null
  }
  try {
    const parsed = JSON.parse(trimmed)
    delete errors[fieldKey]
    return parsed
  } catch {
    errors[fieldKey] = fieldKey === 'address' ? t('site.errors.invalidAddress') : t('site.errors.invalidContact')
    throw new Error('invalid json')
  }
}

function validate() {
  Object.keys(errors).forEach((key) => delete errors[key])
  if (!form.code) errors.code = t('site.form.codeRequired')
  if (!form.name) errors.name = t('site.form.nameRequired')
  if (!form.site_type_id) errors.site_type_id = t('site.form.siteTypeRequired')
  if (Object.keys(errors).length > 0) return false
  try {
    validateJson(form.address, 'address')
    validateJson(form.contact, 'contact')
  } catch {
    return false
  }
  return true
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

async function fetchSiteTypes() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_site_types')
    .select('id, code, name')
    .eq('tenant_id', tenant)
    .order('code', { ascending: true })
  if (error) throw error
  siteTypes.value = data ?? []
}

function parseJson(value: any) {
  if (!value) return null
  if (typeof value === 'object') return value
  if (typeof value === 'string') {
    try {
      return JSON.parse(value)
    } catch {
      return null
    }
  }
  return null
}

async function fetchSites() {
  try {
    loading.value = true
    const tenant = await ensureTenant()
    let query = supabase
      .from(TABLE)
      .select('id, tenant_id, code, name, site_type_id, parent_site_id, address, contact, notes, active, created_at, site_type:site_type_id(id, code, name), parent:parent_site_id(id, code, name)')
      .eq('tenant_id', tenant)
      .order('code', { ascending: true })

    if (filters.siteType) query = query.eq('site_type_id', filters.siteType)
    if (filters.keyword.trim()) {
      const sanitized = filters.keyword.trim().replace(/[%_]/g, (char) => `\\${char}`)
      const keyword = `%${sanitized}%`
      query = query.or(`code.ilike.${keyword},name.ilike.${keyword}`)
    }

    const { data, error } = await query
    if (error) throw error

    rows.value = (data ?? []).map((row: any) => ({
      id: row.id,
      tenant_id: row.tenant_id,
      code: row.code,
      name: row.name,
      site_type_id: row.site_type_id,
      parent_site_id: row.parent_site_id,
      address: parseJson(row.address),
      contact: parseJson(row.contact),
      notes: row.notes ?? null,
      active: row.active ?? false,
      created_at: row.created_at ?? null,
      siteTypeName: row.site_type?.name || row.site_type?.code || null,
      parentName: row.parent?.name || row.parent?.code || null,
    }))
  } catch (err) {
    console.error(err)
    rows.value = []
  } finally {
    loading.value = false
  }
}

async function saveRecord() {
  if (!validate()) return
  try {
    saving.value = true
    const tenant = await ensureTenant()
    const addressPayload = validateJson(form.address, 'address')
    const contactPayload = validateJson(form.contact, 'contact')

    const payload = {
      tenant_id: tenant,
      code: form.code.trim(),
      name: form.name.trim(),
      site_type_id: form.site_type_id,
      parent_site_id: form.parent_site_id || null,
      address: addressPayload,
      contact: contactPayload,
      notes: form.notes.trim() || null,
      active: !!form.active,
    }

    if (editing.value && form.id) {
      const { error } = await supabase.from(TABLE).update(payload).eq('id', form.id)
      if (error) throw error
    } else {
      const { error } = await supabase.from(TABLE).insert(payload)
      if (error) throw error
    }

    closeModal()
    await fetchSites()
  } catch (err) {
    console.error(err)
    alert(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

async function deleteRecord() {
  if (!toDelete.value) return
  try {
    const { error } = await supabase.from(TABLE).delete().eq('id', toDelete.value.id)
    if (error) throw error
    showDelete.value = false
    toDelete.value = null
    await fetchSites()
  } catch (err) {
    console.error(err)
    alert(err instanceof Error ? err.message : String(err))
  }
}

watch(
  () => ({ ...filters }),
  async () => {
    await fetchSites()
  },
  { deep: true }
)

onMounted(async () => {
  await ensureTenant()
  await fetchSiteTypes()
  await fetchSites()
})
</script>
