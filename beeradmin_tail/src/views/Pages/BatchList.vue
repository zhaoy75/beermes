<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <section class="mb-6 bg-white shadow rounded-lg p-4 border border-gray-200" aria-labelledby="batchSearchHeading">
      <div class="flex items-center justify-between mb-4">
        <h2 id="batchSearchHeading" class="text-lg font-semibold text-gray-800">{{ t('batch.list.searchTitle') }}</h2>
        <div class="flex gap-2">
          <button class="text-sm px-3 py-1 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" :disabled="loading" @click="openCreate">
            {{ t('batch.list.newBatch') }}
          </button>
          <button class="text-sm px-3 py-1 rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-50" :disabled="loading" @click="fetchBatches">
            {{ t('common.search') }}
          </button>
        </div>
      </div>
      <form class="grid grid-cols-1 md:grid-cols-4 gap-4" @submit.prevent>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="batchNameFilter">{{ t('batch.list.nameLabel') }}</label>
          <input id="batchNameFilter" v-model.trim="search.name" type="search" class="w-full h-[36px] border rounded px-3" :placeholder="t('batch.list.namePlaceholder')" />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="batchStatusFilter">{{ t('batch.list.colStatus') }}</label>
          <select id="batchStatusFilter" v-model="search.status" class="w-full h-[36px] border rounded px-3 bg-white" :disabled="batchStatusLoading">
            <option value="">{{ t('common.select') }}</option>
            <option v-for="option in batchStatusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
          </select>
        </div>
        <div v-for="field in attrSearchFields" :key="field.attr_id">
          <label class="block text-sm text-gray-600 mb-1" :for="`attr-search-${field.attr_id}`">{{ attrLabel(field) }}</label>
          <select
            v-if="field.data_type === 'ref'"
            :id="`attr-search-${field.attr_id}`"
            v-model="search.attr[String(field.attr_id)]"
            class="w-full h-[36px] border rounded px-3 bg-white"
          >
            <option value="">{{ t('common.select') }}</option>
            <option v-for="option in attrOptions(field)" :key="`${option.value}`" :value="String(option.value)">
              {{ option.label }}
            </option>
          </select>
          <select
            v-else-if="field.data_type === 'boolean'"
            :id="`attr-search-${field.attr_id}`"
            v-model="search.attr[String(field.attr_id)]"
            class="w-full h-[36px] border rounded px-3 bg-white"
          >
            <option value="">{{ t('common.select') }}</option>
            <option value="true">{{ t('common.yes') }}</option>
            <option value="false">{{ t('common.no') }}</option>
          </select>
          <input
            v-else-if="field.data_type === 'date'"
            :id="`attr-search-${field.attr_id}`"
            v-model="search.attr[String(field.attr_id)]"
            type="date"
            class="w-full h-[36px] border rounded px-3"
          />
          <input
            v-else-if="field.data_type === 'timestamp'"
            :id="`attr-search-${field.attr_id}`"
            v-model="search.attr[String(field.attr_id)]"
            type="datetime-local"
            class="w-full h-[36px] border rounded px-3"
          />
          <input
            v-else-if="field.data_type === 'number'"
            :id="`attr-search-${field.attr_id}`"
            v-model.trim="search.attr[String(field.attr_id)]"
            type="number"
            class="w-full h-[36px] border rounded px-3"
          />
          <input
            v-else
            :id="`attr-search-${field.attr_id}`"
            v-model.trim="search.attr[String(field.attr_id)]"
            type="search"
            class="w-full h-[36px] border rounded px-3"
          />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="startFilter">{{ t('batch.list.startDate') }}</label>
          <input id="startFilter" v-model="search.start" type="date" class="w-full h-[36px] border rounded px-3" />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="endFilter">{{ t('batch.list.endDate') }}</label>
          <input id="endFilter" v-model="search.end" type="date" class="w-full h-[36px] border rounded px-3" />
        </div>
        <div class="flex items-end">
          <button class="text-sm px-3 py-2 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="resetFilters">{{ t('common.reset') }}</button>
        </div>
      </form>
      <p class="mt-2 text-sm text-gray-500">{{ t('batch.list.showing', { count: filteredBatches.length, total: batches.length }) }}</p>
      <div v-if="searchConditions.length" class="mt-2 flex flex-wrap gap-2 text-xs text-gray-600">
        <span v-for="cond in searchConditions" :key="cond.key" class="px-2 py-1 rounded-full bg-gray-100">
          {{ cond.label }}: {{ cond.value }}
        </span>
      </div>
    </section>

    <section aria-labelledby="batchTableHeading">
      <h2 id="batchTableHeading" class="sr-only">{{ t('batch.list.tableTitle') }}</h2>

      <div class="overflow-x-auto border border-gray-200 rounded-lg shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th v-for="col in columns" :key="col.key" class="px-3 py-2 text-left text-xs font-semibold text-gray-600 uppercase tracking-wide">
                <button v-if="col.sortable" class="inline-flex items-center gap-1" @click="setSort(col.key as SortKey)" type="button">
                  <span>{{ col.i18n ? t(col.label) : col.label }}</span>
                  <span class="text-[10px] text-gray-400">{{ sortGlyph(col.key) }}</span>
                </button>
                <span v-else>{{ col.i18n ? t(col.label) : col.label }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-semibold text-gray-600 uppercase tracking-wide">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="batch in sortedBatches" :key="batch.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 text-sm text-blue-600 hover:underline cursor-pointer" @click="goEdit(batch)">{{ batch.label || batch.batch_code }}</td>
              <td class="px-3 py-2 text-sm">
                <span :class="statusClass(batch.status)">{{ statusLabel(batch.status) }}</span>
              </td>
              <td class="px-3 py-2 text-sm text-gray-600">{{ fmtDateTime(batch.planned_start) }}</td>
              <td class="px-3 py-2 text-sm text-gray-600">{{ fmtDateTime(batch.planned_end) }}</td>
              <td v-for="field in attrSearchFields" :key="`${batch.id}-${field.attr_id}`" class="px-3 py-2 text-sm text-gray-600">
                {{ formatAttrValueForField(attrValueFor(batch.id, field.attr_id), field) }}
              </td>
              <td class="px-3 py-2 text-sm">
                <div class="flex flex-wrap gap-2">
                  <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="goEdit(batch)" type="button">{{ t('common.edit') }}</button>
                  <button class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700 disabled:opacity-50" :disabled="loading" @click="confirmDelete(batch)" type="button">{{ t('common.delete') }}</button>
                </div>
              </td>
            </tr>
            <tr v-if="!loading && sortedBatches.length === 0">
              <td class="px-3 py-5 text-center text-gray-500" colspan="6">{{ t('common.noData') }}</td>
            </tr>
            <tr v-if="loading">
              <td class="px-3 py-5 text-center text-gray-500" colspan="6">{{ t('common.loading') }}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>

    <BatchSummaryDialog v-if="showSummary && summaryState" :batch="summaryState" :open="showSummary" @close="showSummary = false" />
    <BatchCreateDialog v-if="showCreate" :open="showCreate" :recipes="recipes" :loading="loading" @close="closeCreate" @submit="handleCreate" />

    <ConfirmDeleteDialog v-if="toDelete" :open="!!toDelete" :batch="toDelete" :loading="loading" @cancel="toDelete = null" @confirm="deleteBatch" />
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, reactive, ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import BatchSummaryDialog from '@/views/Pages/components/BatchSummaryDialog.vue'
import BatchCreateDialog from '@/views/Pages/components/BatchCreateDialog.vue'
import ConfirmDeleteDialog from '@/views/Pages/components/BatchDeleteDialog.vue'

const { t, locale } = useI18n()
const router = useRouter()

const pageTitle = computed(() => t('batch.list.title'))

interface RawBatchRow {
  id: string
  tenant_id: string
  batch_code: string
  batch_label?: string | null
  meta?: Record<string, any> | null
  process_version: number | null
  status: string | null
  created_at: string | null
  planned_start: string | null
  planned_end: string | null
  // planned_end?: string | null
  // actual_start?: string | null
  // actual_end?: string | null
  notes?: string | null
}

interface BatchRow extends RawBatchRow {
  display_name: string
  label: string
}

type SortKey = 'label' | 'status' | 'planned_start' | 'planned_end'

type SearchState = {
  name: string
  status: string
  start: string
  end: string
  attr: Record<string, string>
}

type AttrField = {
  attr_set_id: number
  attr_id: number
  code: string
  name: string
  name_i18n?: Record<string, string> | null
  data_type: string
  ref_kind?: string | null
  ref_domain?: string | null
}

type ColumnDef = { key: SortKey | string, label: string, sortable: boolean, i18n: boolean }

const baseColumns: ColumnDef[] = [
  { key: 'label', label: 'batch.list.colName', sortable: true, i18n: true },
  { key: 'status', label: 'batch.list.colStatus', sortable: true, i18n: true },
  { key: 'planned_start', label: 'batch.list.startDate', sortable: true, i18n: true },
  { key: 'planned_end', label: 'batch.list.endDate', sortable: true, i18n: true },
]

const batches = ref<BatchRow[]>([])
const loading = ref(false)
const tenantId = ref<string | null>(null)
const recipes = ref<Array<{ id: string, name: string, code: string, version: number }>>([])
const isAdmin = ref(false)

const search = reactive<SearchState>({
  name: '',
  status: '',
  start: defaultStartDate(),
  end: '',
  attr: {},
})
const sortKey = ref<SortKey>('planned_start')
const sortDirection = ref<'asc' | 'desc'>('desc')

const showSummary = ref(false)
const summaryState = ref<BatchRow | null>(null)
const showCreate = ref(false)
const toDelete = ref<BatchRow | null>(null)

const batchStatusRows = ref<Array<{ status_code: string, label_ja: string | null, label_en: string | null, sort_order: number | null }>>([])
const batchStatusLoading = ref(false)

const attrFields = ref<AttrField[]>([])
const attrLoading = ref(false)
const attrValuesByBatch = ref<Record<string, Record<string, unknown>>>({})
const attrRefOptions = ref<Record<string, Array<{ value: string | number, label: string }>>>({})

const attrSearchFields = computed(() => attrFields.value)

const columns = computed<ColumnDef[]>(() => {
  const dynamic = attrSearchFields.value.map((field) => ({
    key: `attr-${field.attr_id}`,
    label: attrLabel(field),
    sortable: false,
    i18n: false,
  }))
  return [...baseColumns, ...dynamic]
})

const batchStatusOptions = computed(() => {
  const lang = String(locale.value ?? '').toLowerCase()
  const useJa = lang.startsWith('ja')
  return batchStatusRows.value
    .slice()
    .sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0))
    .map((row) => {
      const label = useJa ? row.label_ja : row.label_en
      const fallback = row.label_en ?? row.label_ja ?? row.status_code
      return { value: row.status_code, label: String(label ?? fallback ?? row.status_code).trim() || row.status_code }
    })
})

const searchConditions = computed(() => {
  const conditions: Array<{ key: string; label: string; value: string }> = []
  if (search.name) conditions.push({ key: 'name', label: t('batch.list.nameLabel'), value: search.name })
  if (search.status) {
    const match = batchStatusOptions.value.find((option) => option.value === search.status)
    conditions.push({ key: 'status', label: t('batch.list.colStatus'), value: match?.label ?? search.status })
  }
  if (search.start) conditions.push({ key: 'start', label: t('batch.list.startDate'), value: search.start })
  if (search.end) conditions.push({ key: 'end', label: t('batch.list.endDate'), value: search.end })
  attrSearchFields.value.forEach((field) => {
    const value = search.attr[String(field.attr_id)]
    if (value) {
      conditions.push({ key: `attr-${field.attr_id}`, label: attrLabel(field), value })
    }
  })
  return conditions
})

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) {
    throw new Error('Tenant not resolved in session')
  }
  const role = String(data.user?.app_metadata?.role ?? data.user?.user_metadata?.role ?? '').toLowerCase()
  const adminFlag = Boolean(data.user?.app_metadata?.is_admin || data.user?.user_metadata?.is_admin)
  isAdmin.value = adminFlag || role === 'admin'
  tenantId.value = id
  return id
}

async function loadAttrFields() {
  if (attrLoading.value) return
  try {
    attrLoading.value = true
    await ensureTenant()
    const { data: setData, error: setError } = await supabase
      .from('attr_set')
      .select('attr_set_id, code, name, domain, scope, owner_id, is_active, sort_order')
      .eq('domain', 'batch')
      .eq('is_active', true)
      .order('sort_order', { ascending: true })
      .order('code', { ascending: true })
    if (setError) throw setError
    const setIds = (setData ?? []).map((row: any) => Number(row.attr_set_id)).filter((id) => !Number.isNaN(id))
    if (!setIds.length) {
      attrFields.value = []
      return
    }
    const { data: ruleData, error: ruleError } = await supabase
      .from('attr_set_rule')
      .select('attr_set_id, attr_id, required, sort_order, is_active, attr_def:attr_def!fk_attr_set_rule_attr(attr_id, code, name, name_i18n, data_type, ref_kind, ref_domain, is_active)')
      .in('attr_set_id', setIds)
      .eq('is_active', true)
      .order('sort_order', { ascending: true })
    if (ruleError) throw ruleError
    const fields: AttrField[] = []
    const seen = new Set<number>()
    for (const row of ruleData ?? []) {
      const attr = (row as any).attr_def
      if (!attr || !attr.is_active) continue
      const attrId = Number(attr.attr_id)
      if (seen.has(attrId)) continue
      seen.add(attrId)
      fields.push({
        attr_set_id: Number((row as any).attr_set_id),
        attr_id: attrId,
        code: String(attr.code ?? ''),
        name: String(attr.name ?? attr.code ?? attr.attr_id),
        name_i18n: (attr as any).name_i18n ?? null,
        data_type: String(attr.data_type ?? ''),
        ref_kind: (attr as any).ref_kind ?? null,
        ref_domain: (attr as any).ref_domain ?? null,
      })
    }
    attrFields.value = fields
    for (const field of fields) {
      const key = String(field.attr_id)
      if (!(key in search.attr)) search.attr[key] = ''
    }
    await loadAttrRefOptions(fields)
  } catch (err) {
    console.warn('Failed to load attribute fields', err)
    attrFields.value = []
  } finally {
    attrLoading.value = false
  }
}

async function loadBatchStatusOptions() {
  if (batchStatusLoading.value) return
  try {
    batchStatusLoading.value = true
    const { data, error } = await supabase
      .from('v_batch_status')
      .select('status_code, label_ja, label_en, sort_order')
      .order('sort_order')
    if (error) throw error
    batchStatusRows.value = (data ?? []).map((row: any) => ({
      status_code: String(row.status_code ?? '').trim(),
      label_ja: row.label_ja ?? null,
      label_en: row.label_en ?? null,
      sort_order: typeof row.sort_order === 'number' ? row.sort_order : Number(row.sort_order ?? 0),
    })).filter((row: any) => row.status_code)
  } catch (err) {
    console.warn('Failed to load batch statuses', err)
    batchStatusRows.value = []
  } finally {
    batchStatusLoading.value = false
  }
}

async function fetchBatches() {
  try {
    loading.value = true
    const tenant = await ensureTenant()
    await loadAttrFields()
    const query = supabase
      .from('mes_batches')
      .select('*')
      .eq('tenant_id', tenant)
      .order('created_at', { ascending: false })

    if (search.start) {
      query.gte('planned_start', search.start)
    }
    if (search.end) {
      query.lte('planned_start', search.end + 'T23:59:59')
    }
    if (search.name) {
      query.or(`batch_code.ilike.%${search.name}%,batch_label.ilike.%${search.name}%`)
    }
    if (search.status) {
      query.eq('status', search.status)
    }

    const { data, error } = await query
    if (error) throw error

    batches.value = (data ?? []).map((row) => {
      const label = row.batch_label ?? resolveMetaLabel(row.meta)
      return {
        ...row,
        label: label || '',
        display_name: row.notes?.split('\n')[0] || row.batch_code,
      }
    })
    await fetchAttrValues(batches.value.map((row) => row.id))
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

async function fetchRecipes() {
  try {
    const tenant = await ensureTenant()
    const { data, error } = await supabase
      .from('mes_recipes')
      .select('id, name, code, version')
      .eq('tenant_id', tenant)
      .order('name')
    if (error) throw error
    recipes.value = data ?? []
  } catch (err) {
    console.error(err)
  }
}

async function fetchAttrValues(batchIds: string[]) {
  if (!batchIds.length || !attrSearchFields.value.length) {
    attrValuesByBatch.value = {}
    return
  }
  try {
    const attrIds = attrSearchFields.value.map((field) => field.attr_id)
    const { data, error } = await supabase
      .from('entity_attr')
      .select('entity_id, attr_id, value_text, value_num, value_bool, value_date, value_ts, value_json, value_ref_type_id')
      .eq('entity_type', 'batch')
      .in('entity_id', batchIds)
      .in('attr_id', attrIds)
    if (error) throw error
    const map: Record<string, Record<string, unknown>> = {}
    for (const row of data ?? []) {
      const entityId = String((row as any).entity_id)
      if (!map[entityId]) map[entityId] = {}
      map[entityId][String((row as any).attr_id)] = pickAttrValue(row as any)
    }
    attrValuesByBatch.value = map
  } catch (err) {
    console.warn('Failed to load attribute values', err)
    attrValuesByBatch.value = {}
  }
}

async function loadAttrRefOptions(fields: AttrField[]) {
  const keys = new Set<string>()
  for (const field of fields) {
    if (field.data_type === 'ref' && field.ref_kind && field.ref_domain) {
      keys.add(`${field.ref_kind}:${field.ref_domain}`)
    }
  }
  if (!keys.size) {
    attrRefOptions.value = {}
    return
  }
  const cache = { ...attrRefOptions.value }
  for (const key of Array.from(keys)) {
    if (cache[key]) continue
    const [kind, domain] = key.split(':')
    let options: Array<{ value: string | number, label: string }> = []
    if (kind === 'registry_def') {
      const { data, error } = await supabase
        .from('registry_def')
        .select('def_id, def_key, spec')
        .eq('kind', domain)
        .eq('is_active', true)
        .order('def_key', { ascending: true })
      if (error) {
        console.warn('Failed to load registry options', error)
      } else {
        options = (data ?? []).map((row: any) => ({
          value: row.def_id,
          label: row.spec?.name || row.def_key,
        }))
      }
    } else if (kind === 'type_def') {
      const { data, error } = await supabase
        .from('type_def')
        .select('type_id, code, name')
        .eq('domain', domain)
        .eq('is_active', true)
        .order('sort_order', { ascending: true })
      if (error) {
        console.warn('Failed to load type options', error)
      } else {
        options = (data ?? []).map((row: any) => ({
          value: row.type_id,
          label: row.name || row.code,
        }))
      }
    }
    cache[key] = options
  }
  attrRefOptions.value = cache
}

function resetFilters() {
  search.name = ''
  search.status = ''
  search.start = defaultStartDate()
  search.end = ''
  attrSearchFields.value.forEach((field) => {
    search.attr[String(field.attr_id)] = ''
  })
  fetchBatches()
}

const filteredBatches = computed(() => {
  return batches.value.filter((batch) => {
    const nameQuery = search.name.toLowerCase()
    const nameMatch = !search.name
      || batch.batch_code.toLowerCase().includes(nameQuery)
      || batch.display_name.toLowerCase().includes(nameQuery)
    const statusMatch = !search.status || String(batch.status ?? '') === search.status
    const startOk = !search.start || (!!batch.planned_start && safeTimestamp(batch.planned_start) >= safeTimestamp(search.start))
    const endSource = batch.planned_end ?? batch.planned_start
    const endOk = !search.end || (!!endSource && safeTimestamp(endSource) <= safeTimestamp(search.end, true))
    const attrMatch = attrSearchFields.value.every((field) => {
      const query = (search.attr[String(field.attr_id)] ?? '').trim()
      if (!query) return true
      const raw = attrValueFor(batch.id, field.attr_id)
      return matchAttrValue(raw, query)
    })
    return nameMatch && statusMatch && startOk && endOk && attrMatch
  })
})

const sortedBatches = computed(() => {
  const rows = [...filteredBatches.value]
  rows.sort((a, b) => {
    const key = sortKey.value
    const dir = sortDirection.value === 'asc' ? 1 : -1
    const av = (a as any)[key]
    const bv = (b as any)[key]
    if (av == null && bv == null) return 0
    if (av == null) return 1
    if (bv == null) return -1
    if (typeof av === 'number' && typeof bv === 'number') {
      return dir * (av - bv)
    }
    return dir * String(av).localeCompare(String(bv))
  })
  return rows
})

function setSort(key: SortKey) {
  if (sortKey.value === key) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = key
    sortDirection.value = 'asc'
  }
}

function sortGlyph(key: SortKey) {
  if (sortKey.value !== key) return ''
  return sortDirection.value === 'asc' ? '▲' : '▼'
}

function fmtDateTime(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
  } catch {
    return value
  }
}

function safeTimestamp(value: string, endOfDay = false) {
  try {
    if (endOfDay) {
      const end = new Date(value)
      end.setHours(23, 59, 59, 999)
      return end.getTime()
    }
    return new Date(value).getTime()
  } catch {
    return 0
  }
}

function defaultStartDate() {
  const d = new Date()
  d.setMonth(d.getMonth() - 2)
  const yyyy = d.getFullYear()
  const mm = String(d.getMonth() + 1).padStart(2, '0')
  const dd = String(d.getDate()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}`
}

function statusClass(status: string | null) {
  if (!status) return 'px-2 py-1 rounded-full bg-gray-100 text-gray-600'
  const lower = status.toLowerCase()
  if (lower.includes('complete')) return 'px-2 py-1 rounded-full bg-green-100 text-green-700'
  if (lower.includes('progress')) return 'px-2 py-1 rounded-full bg-yellow-100 text-yellow-700'
  return 'px-2 py-1 rounded-full bg-blue-100 text-blue-700'
}

function statusLabel(status: string | null | undefined) {
  if (!status) return '—'
  const match = batchStatusOptions.value.find((option) => option.value === status)
  return match?.label ?? status
}

function resolveMetaLabel(meta: unknown) {
  if (!meta || typeof meta !== 'object' || Array.isArray(meta)) return null
  const label = (meta as Record<string, unknown>).label
  if (typeof label !== 'string') return null
  const trimmed = label.trim()
  return trimmed.length ? trimmed : null
}

function attrLabel(field: AttrField) {
  const lang = String(locale.value ?? '').toLowerCase()
  const key = lang.startsWith('ja') ? 'ja' : 'en'
  const label = field.name_i18n?.[key]
  return label || field.name || field.code
}

function attrOptions(field: AttrField) {
  if (!field.ref_kind || !field.ref_domain) return []
  const key = `${field.ref_kind}:${field.ref_domain}`
  return attrRefOptions.value[key] ?? []
}

function pickAttrValue(row: Record<string, any>) {
  if (row.value_text != null) return row.value_text
  if (row.value_num != null) return row.value_num
  if (row.value_bool != null) return row.value_bool
  if (row.value_date != null) return row.value_date
  if (row.value_ts != null) return row.value_ts
  if (row.value_json != null) return row.value_json
  if (row.value_ref_type_id != null) return row.value_ref_type_id
  return null
}

function attrValueFor(batchId: string, attrId: number) {
  const batchMap = attrValuesByBatch.value[batchId]
  if (!batchMap) return null
  return batchMap[String(attrId)] ?? null
}

function normalizeAttrValue(raw: unknown) {
  if (raw && typeof raw === 'object' && 'def_id' in (raw as any)) {
    return (raw as any).def_id
  }
  return raw
}

function formatAttrValueForField(value: unknown, field: AttrField) {
  if (value == null) return '—'
  if (field.data_type === 'ref') {
    const normalized = normalizeAttrValue(value)
    const options = attrOptions(field)
    const hit = options.find((opt) => String(opt.value) === String(normalized))
    return hit?.label ?? String(normalized ?? '—')
  }
  if (field.data_type === 'boolean' || typeof value === 'boolean') {
    return Boolean(value) ? t('common.yes') : t('common.no')
  }
  if (field.data_type === 'date') {
    try {
      return new Date(String(value)).toLocaleDateString()
    } catch {
      return String(value)
    }
  }
  if (field.data_type === 'timestamp') {
    return fmtDateTime(String(value))
  }
  if (typeof value === 'object') {
    try {
      return JSON.stringify(value)
    } catch {
      return String(value)
    }
  }
  return String(value)
}

function matchAttrValue(raw: unknown, query: string) {
  if (raw == null) return false
  const queryTrimmed = query.trim()
  if (!queryTrimmed) return true
  const normalized = normalizeAttrValue(raw)
  if (typeof normalized === 'boolean') {
    const lowered = queryTrimmed.toLowerCase()
    const wanted = ['true', '1', 'yes', 'y'].includes(lowered)
      ? true
      : ['false', '0', 'no', 'n'].includes(lowered)
        ? false
        : null
    if (wanted === null) return false
    return normalized === wanted
  }
  const rawNum = Number(normalized)
  const queryNum = Number(queryTrimmed)
  if (!Number.isNaN(rawNum) && !Number.isNaN(queryNum)) {
    return rawNum === queryNum
  }
  return String(normalized).toLowerCase().includes(queryTrimmed.toLowerCase())
}

function tOr(key: string, fallback: string) {
  const value = t(key)
  return value === key ? fallback : value
}

function isRestrictedStatus(status: string | null | undefined) {
  if (!status) return false
  const lower = status.toLowerCase()
  return lower.includes('progress') || lower.includes('complete')
}

function goEdit(batch: BatchRow) {
  if (!isAdmin.value && isRestrictedStatus(batch.status)) {
    window.alert(tOr('batch.list.editBlocked', 'This batch cannot be edited in its current status.'))
    return
  }
  router.push({ path: `/batches/${batch.id}` })
}

function openSummary(batch: BatchRow) {
  summaryState.value = batch
  showSummary.value = true
}

function confirmDelete(batch: BatchRow) {
  if (!isAdmin.value && isRestrictedStatus(batch.status)) {
    window.alert(tOr('batch.list.deleteBlocked', 'This batch cannot be deleted in its current status.'))
    return
  }
  toDelete.value = batch
}

async function deleteBatch() {
  if (!toDelete.value) return
  if (!isAdmin.value && isRestrictedStatus(toDelete.value.status)) {
    window.alert(tOr('batch.list.deleteBlocked', 'This batch cannot be deleted in its current status.'))
    return
  }
  try {
    loading.value = true
    await ensureTenant()
    const { error } = await supabase.from('mes_batches').delete().eq('id', toDelete.value.id)
    if (error) throw error
    toDelete.value = null
    fetchBatches()
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

function openCreate() {
  showCreate.value = true
}

function closeCreate() {
  showCreate.value = false
}

async function handleCreate(payload: { recipeId: string, batchCode: string | null, label: string | null, plannedStart: string | null, plannedEnd: string | null, notes: string | null, processVersion: number | null }) {
  try {
    loading.value = true
    const tenant = await ensureTenant()
    const batchCode = payload.batchCode?.trim() ? payload.batchCode.trim() : await generateBatchCode()
    const { data, error } = await supabase.rpc('create_batch_from_recipe', {
      _tenant_id: tenant,
      _recipe_id: payload.recipeId,
      _batch_code: batchCode,
      _planned_start: payload.plannedStart ? new Date(payload.plannedStart).toISOString() : null,
      _process_version: payload.processVersion,
      _notes: payload.notes,
    })
    if (error) throw error
    const meta: Record<string, unknown> = {}
    const label = payload.label?.trim() || ''
    if (label) meta.label = label
    const updatePayload: Record<string, unknown> = {
      batch_label: label || null,
    }
    if (Object.keys(meta).length > 0) updatePayload.meta = meta
    if (payload.plannedEnd) {
      updatePayload.planned_end = new Date(payload.plannedEnd).toISOString()
    }
    if (data) {
      const { error: updateError } = await supabase
        .from('mes_batches')
        .update(updatePayload)
        .eq('id', data)
      if (updateError) throw updateError
      await assignBatchAttrSets(data, tenant)
    }
    showCreate.value = false
    fetchBatches()
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

async function assignBatchAttrSets(batchId: string, tenant: string) {
  const { data: setData, error: setError } = await supabase
    .from('attr_set')
    .select('attr_set_id')
    .eq('domain', 'batch')
    .eq('is_active', true)
  if (setError) throw setError
  const rows = (setData ?? []).map((row) => ({
    tenant_id: tenant,
    entity_type: 'batch',
    entity_id: batchId,
    attr_set_id: row.attr_set_id,
    is_active: true,
  }))
  if (!rows.length) return
  const { error } = await supabase
    .from('entity_attr_set')
    .upsert(rows, { onConflict: 'tenant_id,entity_type,entity_id,attr_set_id' })
  if (error) throw error
}

async function generateBatchCode() {
  const today = new Date()
  const prefix = `BATCH-${today.getFullYear()}${String(today.getMonth() + 1).padStart(2, '0')}${String(today.getDate()).padStart(2, '0')}`
  const { data, error } = await supabase
    .from('mes_batches')
    .select('batch_code')
    .ilike('batch_code', `${prefix}-%`)
  if (error) throw error
  const usedNumbers = (data ?? [])
    .map((row) => {
      const match = row.batch_code.match(/-(\d{4})$/)
      return match ? Number(match[1]) : 0
    })
    .filter((n) => !Number.isNaN(n))
  const next = usedNumbers.length ? Math.max(...usedNumbers) + 1 : 1
  return `${prefix}-${String(next).padStart(4, '0')}`
}

onMounted(async () => {
  await ensureTenant()
  await Promise.all([loadBatchStatusOptions(), fetchBatches(), fetchRecipes()])
})
</script>
