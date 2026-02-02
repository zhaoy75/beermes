<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="space-y-5">
      <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
        <header class="mb-4">
          <h1 class="text-lg font-semibold text-gray-900">{{ t('batchYield.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('batchYield.subtitle') }}</p>
        </header>

        <form class="grid grid-cols-1 md:grid-cols-5 gap-3" @submit.prevent>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('batchYield.filters.style') }}</label>
            <select v-model="filters.style" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in styleOptions" :key="option" :value="option">{{ option || '—' }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('batchYield.filters.recipe') }}</label>
            <select v-model="filters.recipeId" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in recipeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('batchYield.filters.status') }}</label>
            <select v-model="filters.status" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in filteredStatusOptions" :key="option" :value="option">{{ option }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('batchYield.filters.dateFrom') }}</label>
            <input v-model="filters.dateFrom" type="date" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('batchYield.filters.dateTo') }}</label>
            <input v-model="filters.dateTo" type="date" class="w-full h-[40px] border rounded px-3" />
          </div>
        </form>
      </section>

      <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
        <header class="flex items-center justify-between mb-4">
          <h2 class="text-base font-semibold text-gray-900">{{ t('batchYield.summary.style') }} / {{ t('batchYield.summary.recipe') }}</h2>
          <span v-if="loading" class="text-sm text-gray-500">{{ t('common.loading') }}</span>
        </header>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('batchYield.summary.style') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batchYield.summary.recipe') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batchYield.summary.batchCount') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batchYield.summary.targetVolume') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batchYield.summary.actualVolume') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batchYield.summary.yield') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="row in summaryRows" :key="row.key" class="hover:bg-gray-50">
                <td class="px-3 py-2 text-gray-700">{{ row.style || '—' }}</td>
                <td class="px-3 py-2 text-gray-700">{{ row.recipeName }}</td>
                <td class="px-3 py-2 text-right">{{ row.batchCount }}</td>
                <td class="px-3 py-2 text-right">{{ formatVolume(row.totalTarget) }}</td>
                <td class="px-3 py-2 text-right">{{ formatVolume(row.totalActual) }}</td>
                <td class="px-3 py-2 text-right">{{ formatPercent(row.yieldPercent) }}</td>
              </tr>
              <tr v-if="!loading && summaryRows.length === 0">
                <td colspan="6" class="px-3 py-6 text-center text-gray-500">{{ t('batchYield.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
        <header class="flex items-center justify-between mb-4">
          <h2 class="text-base font-semibold text-gray-900">{{ t('batchYield.yieldLabel') }}</h2>
        </header>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('batchYield.batches.batchCode') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batchYield.summary.style') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batchYield.summary.recipe') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batchYield.batches.status') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batchYield.batches.planned') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batchYield.batches.target') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batchYield.batches.actual') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batchYield.batches.yield') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="batch in filteredBatches" :key="batch.id" class="hover:bg-gray-50">
                <td class="px-3 py-2 text-blue-600 hover:underline cursor-pointer" @click="goBatch(batch.id)">{{ batch.batch_code }}</td>
                <td class="px-3 py-2 text-gray-700">{{ batch.style || '—' }}</td>
                <td class="px-3 py-2 text-gray-700">{{ batch.recipeName }}</td>
                <td class="px-3 py-2 text-gray-700">{{ batch.status || '—' }}</td>
                <td class="px-3 py-2 text-gray-600">{{ formatDate(batch.planned_start) }}</td>
                <td class="px-3 py-2 text-right">{{ formatVolume(batch.target_volume_l) }}</td>
                <td class="px-3 py-2 text-right">{{ formatVolume(batch.actual_volume_l) }}</td>
                <td class="px-3 py-2 text-right">{{ formatPercent(batch.yield_percent) }}</td>
              </tr>
              <tr v-if="!loading && filteredBatches.length === 0">
                <td colspan="8" class="px-3 py-6 text-center text-gray-500">{{ t('batchYield.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'

const FINISHED_STATUSES = ['complete', 'completed', 'done', 'finished', 'released']

interface BatchRow {
  id: string
  batch_code: string
  status: string | null
  planned_start: string | null
  target_volume_l: number | null
  actual_volume_l: number
  yield_percent: number | null
  recipeId: string
  recipeName: string
  style: string | null
}

const { t, locale } = useI18n()
const router = useRouter()

const pageTitle = computed(() => t('batchYield.title'))

const loading = ref(false)
const tenantId = ref<string | null>(null)
const batches = ref<BatchRow[]>([])
const statuses = ref<string[]>([])
const recipes = ref<Array<{ id: string; name: string; code: string; style: string | null }>>([])
const uoms = ref<Array<{ id: string; code: string }>>([])

const filters = reactive({ style: '', recipeId: '', status: '', dateFrom: '', dateTo: '' })

const styleOptions = computed(() => Array.from(new Set(recipes.value.map((r) => r.style || ''))).sort())

const recipeOptions = computed(() => {
  let list = recipes.value
  if (filters.style) list = list.filter((r) => (r.style || '') === filters.style)
  return list.map((r) => ({ value: r.id, label: r.name || r.code || r.id }))
})

const statusOptions = computed(() => statuses.value)
const filteredStatusOptions = computed(() => statusOptions.value.filter((status) => status))

const uomLookup = computed(() => {
  const map = new Map<string, string>()
  uoms.value.forEach((row) => map.set(row.id, row.code))
  return map
})

const filteredBatches = computed(() => {
  const fromTs = filters.dateFrom ? new Date(`${filters.dateFrom}T00:00:00`).getTime() : null
  const toTs = filters.dateTo ? new Date(`${filters.dateTo}T23:59:59`).getTime() : null
  return batches.value.filter((batch) => {
    const matchesStyle = !filters.style || (batch.style || '') === filters.style
    const matchesRecipe = !filters.recipeId || batch.recipeId === filters.recipeId
    const matchesStatus = !filters.status || (batch.status || '') === filters.status
    const batchTs = batch.planned_start ? new Date(batch.planned_start).getTime() : null
    const matchesFrom = fromTs == null || (batchTs != null && batchTs >= fromTs)
    const matchesTo = toTs == null || (batchTs != null && batchTs <= toTs)
    return matchesStyle && matchesRecipe && matchesStatus && matchesFrom && matchesTo
  })
})

const summaryRows = computed(() => {
  const map = new Map<string, { style: string | null; recipeName: string; batchCount: number; totalTarget: number; totalActual: number }>()
  filteredBatches.value.forEach((batch) => {
    const key = `${batch.style || ''}__${batch.recipeId}`
    if (!map.has(key)) {
      map.set(key, {
        style: batch.style,
        recipeName: batch.recipeName,
        batchCount: 0,
        totalTarget: 0,
        totalActual: 0,
      })
    }
    const entry = map.get(key)!
    entry.batchCount += 1
    entry.totalTarget += batch.target_volume_l || 0
    entry.totalActual += batch.actual_volume_l || 0
  })
  return Array.from(map.values()).map((entry, index) => ({
    key: `${entry.style || ''}-${entry.recipeName}-${index}`,
    style: entry.style,
    recipeName: entry.recipeName,
    batchCount: entry.batchCount,
    totalTarget: entry.totalTarget,
    totalActual: entry.totalActual,
    yieldPercent: entry.totalTarget > 0 ? (entry.totalActual / entry.totalTarget) * 100 : null,
  }))
})

function formatVolume(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return `${Number(value).toLocaleString(undefined, { maximumFractionDigits: 2 })}`
}

function formatPercent(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return `${value.toFixed(1)}%`
}

function formatDate(value: string | null) {
  if (!value) return '—'
  try {
    return new Intl.DateTimeFormat(locale.value).format(new Date(value))
  } catch {
    return value
  }
}

async function loadUoms() {
  try {
    const { data, error } = await supabase.from('mst_uom').select('id, code').order('code', { ascending: true })
    if (error) throw error
    uoms.value = data ?? []
  } catch (err) {
    console.warn('Failed to load UOM codes', err)
    uoms.value = []
  }
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

function convertToLiters(size: number | null | undefined, uomCode: string | null | undefined) {
  if (size == null || Number.isNaN(Number(size))) return null
  const numeric = Number(size)
  switch (uomCode) {
    case 'L':
    case null:
    case undefined:
      return numeric
    case 'mL':
      return numeric / 1000
    case 'gal_us':
      return numeric * 3.78541
    default:
      return numeric
  }
}

function toNumber(value: any): number | null {
  if (value === null || value === undefined || value === '') return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function parseKpi(value: any) {
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

function kpiValue(kpi: any, id: string, key: 'planed' | 'actual') {
  const rows = parseKpi(kpi)
  const row = rows.find((item: any) => item && item.id === id)
  if (!row) return null
  const raw = key === 'planed' ? (row.planed ?? row.planned) : row.actual
  return toNumber(raw)
}

async function fetchBatches() {
  try {
    loading.value = true
    const tenant = await ensureTenant()
    recipes.value = []
    statuses.value = []

    const batchQuery = supabase
      .from('mes_batches')
      .select('id, batch_code, status, planned_start, kpi, recipe:mes_recipes(id, name, code, style)')
      .eq('tenant_id', tenant)

    if (filters.dateFrom) batchQuery.gte('planned_start', `${filters.dateFrom}`)
    if (filters.dateTo) batchQuery.lte('planned_start', `${filters.dateTo}T23:59:59`)

    const { data: batchRows, error: batchError } = await batchQuery
    if (batchError) throw batchError

    const recipeMap = new Map<string, { id: string; name: string; code: string; style: string | null }>()

    const batchIds = (batchRows ?? []).map((row) => row.id)
    const packageVolumes = new Map<string, number>()

    if (batchIds.length > 0) {
      if (!uoms.value.length) {
        await loadUoms()
      }
      const { data: lineRows, error: lineError } = await supabase
        .from('inv_movement_lines')
        .select('batch_id, package_id, qty, uom_id, meta, movement:movement_id ( doc_type, status )')
        .eq('tenant_id', tenant)
        .in('batch_id', batchIds)
        .not('package_id', 'is', null)
      if (lineError) throw lineError

      ;(lineRows ?? []).forEach((row: any) => {
        if (!row.batch_id) return
        if (row.movement?.doc_type !== 'production_receipt') return
        if (row.movement?.status === 'void') return
        const qty = row.qty != null ? Number(row.qty) : null
        const uomCode = row.uom_id ? uomLookup.value.get(row.uom_id) : null
        let volume = qty != null ? convertToLiters(qty, uomCode) : null
        if (!volume || volume <= 0) {
          const pkgQty = Number(row.meta?.package_qty ?? 0)
          const unitVolume = Number(row.meta?.unit_volume_l ?? 0)
          if (pkgQty > 0 && unitVolume > 0) {
            volume = pkgQty * unitVolume
          }
        }
        if (!volume || Number.isNaN(volume)) return
        packageVolumes.set(row.batch_id, (packageVolumes.get(row.batch_id) ?? 0) + volume)
      })
    }

    const filteredBatches = (batchRows ?? [])
      .map((row) => {
        const recipe = row.recipe
        if (recipe && !recipeMap.has(recipe.id)) {
          recipeMap.set(recipe.id, {
            id: recipe.id,
            name: recipe.name ?? recipe.code ?? recipe.id,
            code: recipe.code ?? recipe.id,
            style: recipe.style ?? null,
          })
        }
        const actualVolume = packageVolumes.get(row.id) ?? 0
        const targetVolume = kpiValue(row.kpi, 'volume', 'planed')
          ?? kpiValue(row.kpi, 'volume_l', 'planed')
          ?? 0
        const yieldPercent = targetVolume > 0 && actualVolume > 0 ? (actualVolume / targetVolume) * 100 : null
        const status = row.status ?? ''
        const statusLower = status.toLowerCase()
        const isFinished = FINISHED_STATUSES.some((keyword) => statusLower === keyword.toLowerCase())
        if (!isFinished) return null
        return {
          id: row.id,
          batch_code: row.batch_code,
          status,
          planned_start: row.planned_start,
          target_volume_l: targetVolume,
          actual_volume_l: actualVolume,
          yield_percent: yieldPercent,
          recipeId: recipe?.id ?? '',
          recipeName: recipe?.name ?? recipe?.code ?? '—',
          style: recipe?.style ?? null,
        }
      })
      .filter((batch): batch is BatchRow => batch !== null)

    batches.value = filteredBatches

    recipes.value = Array.from(recipeMap.values()).sort((a, b) => (a.name || '').localeCompare(b.name || ''))
    statuses.value = Array.from(new Set(batches.value.map((batch) => batch.status || '')))
      .filter(Boolean)
      .sort((a, b) => a.localeCompare(b))
  } catch (err) {
    console.error(err)
    batches.value = []
  } finally {
    loading.value = false
  }
}

function goBatch(id: string) {
  router.push(`/batches/${id}`)
}

watch(
  () => [filters.dateFrom, filters.dateTo],
  () => {
    fetchBatches()
  }
)

watch(
  () => filters.style,
  () => {
    if (!recipeOptions.value.find((option) => option.value === filters.recipeId)) {
      filters.recipeId = ''
    }
  }
)

onMounted(async () => {
  await ensureTenant()
  await fetchBatches()
})
</script>
