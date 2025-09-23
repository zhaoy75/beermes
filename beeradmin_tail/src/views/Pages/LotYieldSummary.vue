<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="space-y-5">
      <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
        <header class="mb-4">
          <h1 class="text-lg font-semibold text-gray-900">{{ t('lotYield.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('lotYield.subtitle') }}</p>
        </header>

        <form class="grid grid-cols-1 md:grid-cols-5 gap-3" @submit.prevent>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('lotYield.filters.style') }}</label>
            <select v-model="filters.style" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in styleOptions" :key="option" :value="option">{{ option || '—' }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('lotYield.filters.recipe') }}</label>
            <select v-model="filters.recipeId" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in recipeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('lotYield.filters.status') }}</label>
            <select v-model="filters.status" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in filteredStatusOptions" :key="option" :value="option">{{ option }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('lotYield.filters.dateFrom') }}</label>
            <input v-model="filters.dateFrom" type="date" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('lotYield.filters.dateTo') }}</label>
            <input v-model="filters.dateTo" type="date" class="w-full h-[40px] border rounded px-3" />
          </div>
        </form>
      </section>

      <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
        <header class="flex items-center justify-between mb-4">
          <h2 class="text-base font-semibold text-gray-900">{{ t('lotYield.summary.style') }} / {{ t('lotYield.summary.recipe') }}</h2>
          <span v-if="loading" class="text-sm text-gray-500">{{ t('common.loading') }}</span>
        </header>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('lotYield.summary.style') }}</th>
                <th class="px-3 py-2 text-left">{{ t('lotYield.summary.recipe') }}</th>
                <th class="px-3 py-2 text-right">{{ t('lotYield.summary.lotCount') }}</th>
                <th class="px-3 py-2 text-right">{{ t('lotYield.summary.targetVolume') }}</th>
                <th class="px-3 py-2 text-right">{{ t('lotYield.summary.actualVolume') }}</th>
                <th class="px-3 py-2 text-right">{{ t('lotYield.summary.yield') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="row in summaryRows" :key="row.key" class="hover:bg-gray-50">
                <td class="px-3 py-2 text-gray-700">{{ row.style || '—' }}</td>
                <td class="px-3 py-2 text-gray-700">{{ row.recipeName }}</td>
                <td class="px-3 py-2 text-right">{{ row.lotCount }}</td>
                <td class="px-3 py-2 text-right">{{ formatVolume(row.totalTarget) }}</td>
                <td class="px-3 py-2 text-right">{{ formatVolume(row.totalActual) }}</td>
                <td class="px-3 py-2 text-right">{{ formatPercent(row.yieldPercent) }}</td>
              </tr>
              <tr v-if="!loading && summaryRows.length === 0">
                <td colspan="6" class="px-3 py-6 text-center text-gray-500">{{ t('lotYield.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
        <header class="flex items-center justify-between mb-4">
          <h2 class="text-base font-semibold text-gray-900">{{ t('lotYield.yieldLabel') }}</h2>
        </header>
        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('lotYield.lots.lotCode') }}</th>
                <th class="px-3 py-2 text-left">{{ t('lotYield.summary.style') }}</th>
                <th class="px-3 py-2 text-left">{{ t('lotYield.summary.recipe') }}</th>
                <th class="px-3 py-2 text-left">{{ t('lotYield.lots.status') }}</th>
                <th class="px-3 py-2 text-left">{{ t('lotYield.lots.planned') }}</th>
                <th class="px-3 py-2 text-right">{{ t('lotYield.lots.target') }}</th>
                <th class="px-3 py-2 text-right">{{ t('lotYield.lots.actual') }}</th>
                <th class="px-3 py-2 text-right">{{ t('lotYield.lots.yield') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="lot in filteredLots" :key="lot.id" class="hover:bg-gray-50">
                <td class="px-3 py-2 text-blue-600 hover:underline cursor-pointer" @click="goLot(lot.id)">{{ lot.lot_code }}</td>
                <td class="px-3 py-2 text-gray-700">{{ lot.style || '—' }}</td>
                <td class="px-3 py-2 text-gray-700">{{ lot.recipeName }}</td>
                <td class="px-3 py-2 text-gray-700">{{ lot.status || '—' }}</td>
                <td class="px-3 py-2 text-gray-600">{{ formatDate(lot.planned_start) }}</td>
                <td class="px-3 py-2 text-right">{{ formatVolume(lot.target_volume_l) }}</td>
                <td class="px-3 py-2 text-right">{{ formatVolume(lot.actual_volume_l) }}</td>
                <td class="px-3 py-2 text-right">{{ formatPercent(lot.yield_percent) }}</td>
              </tr>
              <tr v-if="!loading && filteredLots.length === 0">
                <td colspan="8" class="px-3 py-6 text-center text-gray-500">{{ t('lotYield.noData') }}</td>
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

interface LotRow {
  id: string
  lot_code: string
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

const pageTitle = computed(() => t('lotYield.title'))

const loading = ref(false)
const tenantId = ref<string | null>(null)
const lots = ref<LotRow[]>([])
const statuses = ref<string[]>([])
const recipes = ref<Array<{ id: string; name: string; code: string; style: string | null }>>([])

const filters = reactive({ style: '', recipeId: '', status: '', dateFrom: '', dateTo: '' })

const styleOptions = computed(() => Array.from(new Set(recipes.value.map((r) => r.style || ''))).sort())

const recipeOptions = computed(() => {
  let list = recipes.value
  if (filters.style) list = list.filter((r) => (r.style || '') === filters.style)
  return list.map((r) => ({ value: r.id, label: r.name || r.code || r.id }))
})

const statusOptions = computed(() => statuses.value)
const filteredStatusOptions = computed(() => statusOptions.value.filter((status) => status))

const filteredLots = computed(() => {
  const fromTs = filters.dateFrom ? new Date(`${filters.dateFrom}T00:00:00`).getTime() : null
  const toTs = filters.dateTo ? new Date(`${filters.dateTo}T23:59:59`).getTime() : null
  return lots.value.filter((lot) => {
    const matchesStyle = !filters.style || (lot.style || '') === filters.style
    const matchesRecipe = !filters.recipeId || lot.recipeId === filters.recipeId
    const matchesStatus = !filters.status || (lot.status || '') === filters.status
    const lotTs = lot.planned_start ? new Date(lot.planned_start).getTime() : null
    const matchesFrom = fromTs == null || (lotTs != null && lotTs >= fromTs)
    const matchesTo = toTs == null || (lotTs != null && lotTs <= toTs)
    return matchesStyle && matchesRecipe && matchesStatus && matchesFrom && matchesTo
  })
})

const summaryRows = computed(() => {
  const map = new Map<string, { style: string | null; recipeName: string; lotCount: number; totalTarget: number; totalActual: number }>()
  filteredLots.value.forEach((lot) => {
    const key = `${lot.style || ''}__${lot.recipeId}`
    if (!map.has(key)) {
      map.set(key, {
        style: lot.style,
        recipeName: lot.recipeName,
        lotCount: 0,
        totalTarget: 0,
        totalActual: 0,
      })
    }
    const entry = map.get(key)!
    entry.lotCount += 1
    entry.totalTarget += lot.target_volume_l || 0
    entry.totalActual += lot.actual_volume_l || 0
  })
  return Array.from(map.values()).map((entry, index) => ({
    key: `${entry.style || ''}-${entry.recipeName}-${index}`,
    style: entry.style,
    recipeName: entry.recipeName,
    lotCount: entry.lotCount,
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

async function fetchLots() {
  try {
    loading.value = true
    const tenant = await ensureTenant()
    recipes.value = []
    statuses.value = []

    const lotQuery = supabase
      .from('prd_lots')
      .select('id, lot_code, status, planned_start, target_volume_l, recipe:rcp_recipes(id, name, code, style)')
      .eq('tenant_id', tenant)

    if (filters.dateFrom) lotQuery.gte('planned_start', `${filters.dateFrom}`)
    if (filters.dateTo) lotQuery.lte('planned_start', `${filters.dateTo}T23:59:59`)

    const { data: lotRows, error: lotError } = await lotQuery
    if (lotError) throw lotError

    const recipeMap = new Map<string, { id: string; name: string; code: string; style: string | null }>()

    const lotIds = (lotRows ?? []).map((row) => row.id)
    const packageVolumes = new Map<string, number>()

    if (lotIds.length > 0) {
      const { data: packageRows, error: pkgError } = await supabase
        .from('pkg_packages')
        .select('lot_id, package_qty, package_size_l, package:package_id(size, uom:mst_uom(code))')
        .in('lot_id', lotIds)
      if (pkgError) throw pkgError

      ;(packageRows ?? []).forEach((row) => {
        const qty = Number(row.package_qty ?? 0)
        if (Number.isNaN(qty) || qty <= 0) return
        const explicitSize = row.package_size_l != null ? Number(row.package_size_l) : null
        const defaultSize = convertToLiters(row.package?.size ?? null, row.package?.uom?.code ?? null)
        const unitSize = explicitSize ?? defaultSize ?? 0
        if (unitSize <= 0) return
        const volume = qty * unitSize
        packageVolumes.set(row.lot_id, (packageVolumes.get(row.lot_id) ?? 0) + volume)
      })
    }

    const filteredLots = (lotRows ?? [])
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
        const targetVolume = row.target_volume_l ?? 0
        const yieldPercent = targetVolume > 0 && actualVolume > 0 ? (actualVolume / targetVolume) * 100 : null
        const status = row.status ?? ''
        const statusLower = status.toLowerCase()
        const isFinished = FINISHED_STATUSES.some((keyword) => statusLower === keyword.toLowerCase())
        if (!isFinished) return null
        return {
          id: row.id,
          lot_code: row.lot_code,
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
      .filter((lot): lot is LotRow => lot !== null)

    lots.value = filteredLots

    recipes.value = Array.from(recipeMap.values()).sort((a, b) => (a.name || '').localeCompare(b.name || ''))
    statuses.value = Array.from(new Set(lots.value.map((lot) => lot.status || '')))
      .filter(Boolean)
      .sort((a, b) => a.localeCompare(b))
  } catch (err) {
    console.error(err)
    lots.value = []
  } finally {
    loading.value = false
  }
}

function goLot(id: string) {
  router.push(`/lots/${id}`)
}

watch(
  () => [filters.dateFrom, filters.dateTo],
  () => {
    fetchLots()
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
  await fetchLots()
})
</script>
