<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto">
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

      <section class="hidden md:block overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('code')"
              >
                {{ t('siteType.table.code') }}<span v-if="sortKey === 'code'"> {{ sortGlyph }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('name')"
              >
                {{ t('siteType.table.name') }}<span v-if="sortKey === 'name'"> {{ sortGlyph }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('flags_ja')"
              >
                {{ t('siteType.table.nameJa') }}<span v-if="sortKey === 'flags_ja'"> {{ sortGlyph }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('active')"
              >
                {{ t('siteType.table.active') }}<span v-if="sortKey === 'active'"> {{ sortGlyph }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('created_at')"
              >
                {{ t('siteType.table.createdAt') }}<span v-if="sortKey === 'created_at'"> {{ sortGlyph }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in sortedRows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.code }}</td>
              <td class="px-3 py-2 text-gray-800">{{ row.name }}</td>
              <td class="px-3 py-2 text-gray-800">{{ row.flagsJa || '—' }}</td>
              <td class="px-3 py-2">
                <span
                  class="inline-flex items-center gap-1 text-xs px-2 py-1 rounded-full border"
                  :class="row.active ? 'border-green-200 bg-green-50 text-green-700' : 'border-gray-200 bg-gray-50 text-gray-500'"
                >
                  <span class="h-2 w-2 rounded-full" :class="row.active ? 'bg-green-500' : 'bg-gray-400'" />
                  {{ row.active ? t('common.yes') : t('common.no') }}
                </span>
              </td>
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
              <td colspan="6" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section class="md:hidden grid gap-3">
        <article v-for="row in sortedRows" :key="row.id" class="border border-gray-200 rounded-xl shadow-sm p-4">
          <header class="flex items-center justify-between mb-2">
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">{{ t('siteType.table.code') }}</p>
              <h2 class="text-lg font-semibold text-gray-900">{{ row.code }}</h2>
            </div>
            <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openEdit(row)">
              {{ t('common.edit') }}
            </button>
          </header>
          <dl class="text-sm text-gray-600 space-y-1">
            <div class="flex justify-between">
              <dt>{{ t('siteType.table.name') }}</dt>
              <dd>{{ row.name }}</dd>
            </div>
            <div class="flex justify-between">
              <dt>{{ t('siteType.table.nameJa') }}</dt>
              <dd>{{ row.flagsJa || '—' }}</dd>
            </div>
            <div class="flex justify-between">
              <dt>{{ t('siteType.table.active') }}</dt>
              <dd>{{ row.active ? t('common.yes') : t('common.no') }}</dd>
            </div>
            <div class="flex justify-between">
              <dt>{{ t('siteType.table.createdAt') }}</dt>
              <dd class="text-xs text-gray-500">{{ formatTimestamp(row.created_at) }}</dd>
            </div>
          </dl>
          <footer class="mt-3 flex gap-2">
            <button class="px-3 py-2 text-sm rounded border hover:bg-gray-100" @click="openEdit(row)">
              {{ t('common.edit') }}
            </button>
            <button class="px-3 py-2 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">
              {{ t('common.delete') }}
            </button>
          </footer>
        </article>
        <p v-if="!loading && sortedRows.length === 0" class="text-center text-gray-500 text-sm">
          {{ t('common.noData') }}
        </p>
      </section>

      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ editing ? t('siteType.editTitle') : t('siteType.newTitle') }}</h3>
          </div>
          <div class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('siteType.table.code') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.code" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.code" class="mt-1 text-xs text-red-600">{{ errors.code }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('siteType.table.name') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.name" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.name" class="mt-1 text-xs text-red-600">{{ errors.name }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('siteType.form.jaLabel') }}</label>
                <input v-model.trim="form.flagsJa" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div class="flex items-center gap-2 mt-6 md:mt-0">
                <input id="siteTypeActive" v-model="form.active" type="checkbox" class="h-4 w-4" />
                <label for="siteTypeActive" class="text-sm text-gray-700">{{ t('siteType.table.active') }}</label>
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
          <div class="p-4 text-sm">{{ t('siteType.deleteConfirm', { code: toDelete?.code ?? '' }) }}</div>
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
import { computed, reactive, ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

interface SiteTypeRow {
  id: string
  code: string
  name: string
  flags: Record<string, unknown> | null
  active: boolean
  created_at: string | null
  flagsJa: string | null
}

type SortKey = 'code' | 'name' | 'flags_ja' | 'active' | 'created_at'
type SortDirection = 'asc' | 'desc'

const TABLE = 'mst_site_types'

const { t } = useI18n()
const pageTitle = computed(() => t('siteType.title'))

const rows = ref<SiteTypeRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const toDelete = ref<SiteTypeRow | null>(null)

const sortKey = ref<SortKey>('code')
const sortDirection = ref<SortDirection>('asc')

const tenantId = ref<string | null>(null)

const form = reactive({
  id: '',
  code: '',
  name: '',
  flagsJa: '',
  active: true,
})

const errors = reactive<Record<string, string>>({})

const sortGlyph = computed(() => (sortDirection.value === 'asc' ? '▲' : '▼'))

const sortedRows = computed(() => {
  const list = [...rows.value]
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
  form.flagsJa = ''
  form.active = true
  Object.keys(errors).forEach((key) => delete errors[key])
}

function openCreate() {
  editing.value = false
  resetForm()
  showModal.value = true
}

function openEdit(row: SiteTypeRow) {
  editing.value = true
  resetForm()
  form.id = row.id
  form.code = row.code
  form.name = row.name
  form.flagsJa = row.flagsJa || ''
  form.active = row.active
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function confirmDelete(row: SiteTypeRow) {
  toDelete.value = row
  showDelete.value = true
}

function validate() {
  Object.keys(errors).forEach((key) => delete errors[key])
  if (!form.code) errors.code = t('siteType.form.codeRequired')
  if (!form.name) errors.name = t('siteType.form.nameRequired')
  return Object.keys(errors).length === 0
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

function buildFlags() {
  const ja = form.flagsJa.trim()
  if (!ja) return {}
  return { ja }
}

function parseFlags(value: unknown) {
  if (!value) return {}
  if (typeof value === 'object' && !Array.isArray(value)) return value as Record<string, unknown>
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value)
      return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
        ? (parsed as Record<string, unknown>)
        : {}
    } catch {
      return {}
    }
  }
  return {}
}

async function fetchRows() {
  try {
    loading.value = true
    await ensureTenant()
    const { data, error } = await supabase
      .from(TABLE)
      .select('id, code, name, flags, active, created_at')
      .order('code', { ascending: true })
    if (error) throw error
    rows.value = (data ?? []).map((row: any) => {
      const flags = parseFlags(row.flags)
      const flagsJa = typeof (flags as any).ja === 'string' ? (flags as any).ja : ''
      return {
        id: row.id,
        code: row.code,
        name: row.name,
        flags,
        flagsJa,
        active: row.active ?? false,
        created_at: row.created_at ?? null,
      }
    })
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
    const payload = {
      tenant_id: tenant,
      code: form.code.trim(),
      name: form.name.trim(),
      flags: buildFlags(),
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
    const { error } = await supabase.from(TABLE).delete().eq('id', toDelete.value.id)
    if (error) throw error
    showDelete.value = false
    toDelete.value = null
    await fetchRows()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
}

onMounted(fetchRows)
</script>
