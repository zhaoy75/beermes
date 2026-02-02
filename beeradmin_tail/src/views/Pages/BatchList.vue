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
            {{ t('common.refresh') }}
          </button>
        </div>
      </div>
      <form class="grid grid-cols-1 md:grid-cols-4 gap-4" @submit.prevent>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="batchNameFilter">{{ t('batch.list.nameLabel') }}</label>
          <input id="batchNameFilter" v-model.trim="search.name" type="search" class="w-full h-[36px] border rounded px-3" :placeholder="t('batch.list.namePlaceholder')" />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="batchLabelFilter">{{ t('batch.list.labelLabel') }}</label>
          <input id="batchLabelFilter" v-model.trim="search.label" type="search" class="w-full h-[36px] border rounded px-3" />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="batchStatusFilter">{{ t('batch.list.colStatus') }}</label>
          <select id="batchStatusFilter" v-model="search.status" class="w-full h-[36px] border rounded px-3 bg-white" :disabled="batchStatusLoading">
            <option value="">{{ t('common.select') }}</option>
            <option v-for="option in batchStatusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
          </select>
        </div>
        <div v-for="field in kpiSearchFields" :key="field.id">
          <label class="block text-sm text-gray-600 mb-1" :for="`kpi-search-${field.id}`">{{ field.name }}</label>
          <input :id="`kpi-search-${field.id}`" v-model.trim="search.kpi[field.id]" type="search" class="w-full h-[36px] border rounded px-3" />
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
                <button class="inline-flex items-center gap-1" @click="setSort(col.key)" type="button">
                  <span>{{ t(col.label) }}</span>
                  <span class="text-[10px] text-gray-400">{{ sortGlyph(col.key) }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left text-xs font-semibold text-gray-600 uppercase tracking-wide">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="batch in sortedBatches" :key="batch.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 text-sm text-blue-600 hover:underline cursor-pointer" @click="goEdit(batch.id)">{{ batch.batch_code }}</td>
              <td class="px-3 py-2 text-sm">{{ batch.label || '—' }}</td>
              <td class="px-3 py-2 text-sm">{{ batch.display_name }}</td>
              <td class="px-3 py-2 text-sm">
                <span :class="statusClass(batch.status)">{{ statusLabel(batch.status) }}</span>
              </td>
              <td class="px-3 py-2 text-sm text-gray-600">{{ fmtDateTime(batch.created_at) }}</td>
              <!-- <td class="px-3 py-2 text-sm text-gray-600">{{ fmtDateTime(batch.planned_end) }}</td>
              <td class="px-3 py-2 text-sm text-gray-600">{{ fmtDateTime(batch.actual_start) }}</td>
              <td class="px-3 py-2 text-sm text-gray-600">{{ fmtDateTime(batch.actual_end) }}</td> -->
              <td class="px-3 py-2 text-sm">
                <div class="flex flex-wrap gap-2">
                  <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openSummary(batch)" type="button">{{ t('batch.list.summary') }}</button>
                  <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="goEdit(batch.id)" type="button">{{ t('common.edit') }}</button>
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
  kpi?: any
  created_at: string | null
  planned_start: string | null
  // planned_end?: string | null
  // actual_start?: string | null
  // actual_end?: string | null
  notes?: string | null
}

interface BatchRow extends RawBatchRow {
  display_name: string
  label: string
}

type SortKey = 'batch_code' | 'display_name' | 'label' | 'status' | 'created_at'

type SearchState = {
  name: string
  label: string
  status: string
  start: string
  end: string
  kpi: Record<string, string>
}

type KpiMeta = {
  id: string
  name: string
  uom?: string
  datasource?: string | null
  search_key_flg?: boolean
}

const columns: Array<{ key: SortKey, label: string }> = [
  { key: 'batch_code', label: 'batch.list.colBatchCode' },
  { key: 'label', label: 'batch.list.colLabel' },
  { key: 'display_name', label: 'batch.list.colName' },
  { key: 'status', label: 'batch.list.colStatus' },
  { key: 'created_at', label: 'batch.list.colCreated' },
  // { key: 'planned_end', label: 'batch.list.colPlannedEnd' },
  // { key: 'actual_start', label: 'batch.list.colActualStart' },
  // { key: 'actual_end', label: 'batch.list.colActualEnd' },
]

const batches = ref<BatchRow[]>([])
const loading = ref(false)
const tenantId = ref<string | null>(null)
const recipes = ref<Array<{ id: string, name: string, code: string, version: number }>>([])

const search = reactive<SearchState>({
  name: '',
  label: '',
  status: '',
  start: defaultStartDate(),
  end: '',
  kpi: {},
})
const sortKey = ref<SortKey>('created_at')
const sortDirection = ref<'asc' | 'desc'>('desc')

const showSummary = ref(false)
const summaryState = ref<BatchRow | null>(null)
const showCreate = ref(false)
const toDelete = ref<BatchRow | null>(null)

const kpiMeta = ref<KpiMeta[]>([])
const kpiMetaLoading = ref(false)
const batchStatusRows = ref<Array<{ status_code: string, label_ja: string | null, label_en: string | null, sort_order: number | null }>>([])
const batchStatusLoading = ref(false)

const fallbackKpiMeta: KpiMeta[] = [
  { id: 'tax_category_code', name: '製品種類', uom: '', datasource: 'registry_def', search_key_flg: true },
  { id: 'volume', name: '生産量', uom: 'l' },
  { id: 'abv', name: 'ABV', uom: '' },
  { id: 'og', name: 'OG', uom: '' },
  { id: 'fg', name: 'FG', uom: '' },
  { id: 'srm', name: 'SRM', uom: '' },
  { id: 'ibu', name: 'IBU', uom: '' },
]

const kpiSearchFields = computed(() => {
  const metaList = kpiMeta.value.length ? kpiMeta.value : fallbackKpiMeta
  return metaList.filter((item) => item.search_key_flg)
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
  if (search.label) conditions.push({ key: 'label', label: t('batch.list.labelLabel'), value: search.label })
  if (search.status) {
    const match = batchStatusOptions.value.find((option) => option.value === search.status)
    conditions.push({ key: 'status', label: t('batch.list.colStatus'), value: match?.label ?? search.status })
  }
  if (search.start) conditions.push({ key: 'start', label: t('batch.list.startDate'), value: search.start })
  if (search.end) conditions.push({ key: 'end', label: t('batch.list.endDate'), value: search.end })
  kpiSearchFields.value.forEach((field) => {
    const value = search.kpi[field.id]
    if (value) {
      conditions.push({ key: `kpi-${field.id}`, label: field.name, value })
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
  tenantId.value = id
  return id
}

function normalizeKpiMeta(list: unknown): KpiMeta[] {
  if (!Array.isArray(list)) return []
  return list
    .map((item) => {
      if (!item || typeof item !== 'object' || Array.isArray(item)) return null
      const id = String((item as Record<string, unknown>).id ?? '').trim()
      if (!id) return null
      const name = String((item as Record<string, unknown>).name ?? id).trim()
      const uom = String((item as Record<string, unknown>).uom ?? '').trim()
      const datasource = (item as Record<string, unknown>).datasource
      const searchKey = (item as Record<string, unknown>).search_key_flg
      return {
        id,
        name: name || id,
        uom,
        datasource: datasource != null ? String(datasource) : null,
        search_key_flg: Boolean(searchKey),
      }
    })
    .filter((row): row is KpiMeta => row !== null)
}

async function loadKpiMeta() {
  if (kpiMeta.value.length || kpiMetaLoading.value) return
  try {
    kpiMetaLoading.value = true
    const { data, error } = await supabase
      .from('registry_def')
      .select('def_id, scope, spec')
      .eq('kind', 'kpi_definition')
      .eq('def_key', 'beer_production_kpi')
    if (error) throw error
    const selected = (data ?? []).find((row: any) => row.scope === 'tenant')
      ?? (data ?? [])[0]
    kpiMeta.value = normalizeKpiMeta((selected?.spec as any)?.kpi_meta)
  } catch (err) {
    console.warn('Failed to load KPI meta', err)
    kpiMeta.value = []
  } finally {
    kpiMetaLoading.value = false
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
      query.ilike('batch_code', `%${search.name}%`)
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
        // planned_end: (row as any)?.planned_end ?? null,
        // actual_start: (row as any)?.actual_start ?? null,
        // actual_end: (row as any)?.actual_end ?? null,
      }
    })
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

function resetFilters() {
  search.name = ''
  search.label = ''
  search.status = ''
  search.start = defaultStartDate()
  search.end = ''
  kpiSearchFields.value.forEach((field) => {
    search.kpi[field.id] = ''
  })
  fetchBatches()
}

const filteredBatches = computed(() => {
  return batches.value.filter((batch) => {
    const nameQuery = search.name.toLowerCase()
    const labelQuery = search.label.toLowerCase()
    const nameMatch = !search.name
      || batch.batch_code.toLowerCase().includes(nameQuery)
      || batch.display_name.toLowerCase().includes(nameQuery)
    const labelMatch = !search.label || batch.label.toLowerCase().includes(labelQuery)
    const statusMatch = !search.status || String(batch.status ?? '') === search.status
    const startOk = !search.start || (!!batch.planned_start && safeTimestamp(batch.planned_start) >= safeTimestamp(search.start))
    const endOk = !search.end || (!!batch.planned_start && safeTimestamp(batch.planned_start) <= safeTimestamp(search.end, true))
    const kpiMatch = kpiSearchFields.value.every((field) => {
      const query = (search.kpi[field.id] ?? '').trim()
      if (!query) return true
      const raw = resolveKpiValue(batch.kpi, field.id)
      return matchKpiValue(raw, query)
    })
    return nameMatch && labelMatch && statusMatch && startOk && endOk && kpiMatch
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

function parseKpiArray(value: unknown) {
  if (!value) return []
  if (Array.isArray(value)) return value
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value)
      return Array.isArray(parsed) ? parsed : []
    } catch {
      return []
    }
  }
  return []
}

function resolveKpiValue(kpi: unknown, id: string) {
  const list = parseKpiArray(kpi)
  const row = list.find((item: any) => item && item.id === id)
  if (!row) return null
  return row.actual ?? row.planed ?? row.planned ?? null
}

function matchKpiValue(raw: unknown, query: string) {
  if (raw == null) return false
  const queryTrimmed = query.trim()
  if (!queryTrimmed) return true
  const rawNum = Number(raw)
  const queryNum = Number(queryTrimmed)
  if (!Number.isNaN(rawNum) && !Number.isNaN(queryNum)) {
    return rawNum === queryNum
  }
  return String(raw).toLowerCase().includes(queryTrimmed.toLowerCase())
}

function goEdit(id: string) {
  router.push({ path: `/batches/${id}` })
}

function openSummary(batch: BatchRow) {
  summaryState.value = batch
  showSummary.value = true
}

function confirmDelete(batch: BatchRow) {
  toDelete.value = batch
}

async function deleteBatch() {
  if (!toDelete.value) return
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

async function handleCreate(payload: { recipeId: string, batchCode: string | null, label: string | null, plannedStart: string | null, notes: string | null, processVersion: number | null }) {
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
    if (payload.label) meta.label = payload.label
    const updatePayload: Record<string, unknown> = {
      batch_label: payload.label || null,
    }
    if (Object.keys(meta).length > 0) updatePayload.meta = meta
    if (data) {
      const { error: updateError } = await supabase
        .from('mes_batches')
        .update(updatePayload)
        .eq('id', data)
      if (updateError) throw updateError
    }
    showCreate.value = false
    fetchBatches()
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
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
  await Promise.all([loadKpiMeta(), loadBatchStatusOptions(), fetchBatches(), fetchRecipes()])
})
</script>
