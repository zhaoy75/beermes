<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white p-4 text-gray-900">
      <div class="mx-auto max-w-7xl space-y-6">
        <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h1 class="text-xl font-semibold">{{ pageTitle }}</h1>
            <p class="text-sm text-gray-500">{{ t('rawMaterialInventory.subtitle') }}</p>
          </div>

          <div class="flex flex-wrap items-center gap-2">
            <button
              type="button"
              class="rounded border border-gray-300 px-3 py-2 text-sm text-gray-900 hover:bg-gray-100 disabled:opacity-50"
              :disabled="loading"
              @click="openCreate"
            >
              {{ t('rawMaterialInventory.actions.newInventory') }}
            </button>
            <button
              type="button"
              class="rounded border border-gray-300 px-3 py-2 text-sm text-gray-900 hover:bg-gray-100 disabled:opacity-50"
              :disabled="loading"
              @click="loadInventory"
            >
              {{ t('common.refresh') }}
            </button>
          </div>
        </header>

        <section class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
          <form class="grid grid-cols-1 gap-4 md:grid-cols-3" @submit.prevent>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('rawMaterialInventory.filters.materialName') }}</label>
              <input
                v-model.trim="filters.keyword"
                type="search"
                class="h-[40px] w-full rounded border border-gray-300 px-3"
                :placeholder="t('rawMaterialInventory.placeholders.materialName')"
              />
            </div>

            <div class="md:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('rawMaterialInventory.filters.materialType') }}</label>
              <div class="flex flex-wrap gap-2">
                <button
                  type="button"
                  class="rounded-full border px-3 py-1.5 text-sm transition"
                  :class="filters.materialTypeId ? 'border-gray-300 text-gray-700 hover:bg-gray-50' : 'border-gray-900 bg-gray-900 text-white'"
                  @click="filters.materialTypeId = ''"
                >
                  {{ t('common.all') }}
                </button>
                <button
                  v-for="option in materialTypeOptions"
                  :key="option.value"
                  type="button"
                  class="rounded-full border px-3 py-1.5 text-sm transition"
                  :class="filters.materialTypeId === option.value ? 'border-gray-900 bg-gray-900 text-white' : 'border-gray-300 text-gray-700 hover:bg-gray-50'"
                  @click="filters.materialTypeId = option.value"
                >
                  {{ option.shortLabel }}
                </button>
              </div>
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('rawMaterialInventory.filters.location') }}</label>
              <select v-model="filters.locationId" class="h-[40px] w-full rounded border border-gray-300 bg-white px-3">
                <option value="">{{ t('common.all') }}</option>
                <option v-for="option in locationOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
          </form>
        </section>

        <section class="rounded-xl border border-gray-200 bg-white shadow-sm">
          <div class="border-b border-gray-200 px-4 py-3">
            <div class="flex items-center justify-between gap-3">
              <div>
                <h2 class="text-lg font-semibold">{{ t('rawMaterialInventory.tableTitle') }}</h2>
                <p class="text-sm text-gray-500">{{ t('rawMaterialInventory.results.count', { count: filteredRows.length }) }}</p>
              </div>
            </div>
          </div>

          <div v-if="loadError" class="border-b border-red-100 bg-red-50 px-4 py-3 text-sm text-red-700">
            {{ loadError }}
          </div>

          <DataTable
            :value="filteredRows"
            data-key="id"
            paginator
            :rows="20"
            :rows-per-page-options="[20, 50, 100]"
            removable-sort
            class="inventory-datatable"
          >
            <template #empty>
              <div class="px-4 py-8 text-center text-sm text-gray-500">
                {{ loading ? t('common.loading') : t('common.noData') }}
              </div>
            </template>

            <Column field="materialName" :header="t('rawMaterialInventory.table.materialName')" sortable>
              <template #body="{ data }">
                <div class="min-w-0">
                  <div class="font-medium text-gray-900">{{ data.materialName }}</div>
                  <div v-if="data.lotNo" class="text-xs text-gray-400">{{ data.lotNo }}</div>
                </div>
              </template>
            </Column>

            <Column field="materialTypeLabel" :header="t('rawMaterialInventory.table.materialType')" sortable>
              <template #body="{ data }">
                <button
                  type="button"
                  class="text-left text-sm text-gray-700 hover:underline"
                  @click="filters.materialTypeId = data.materialTypeId || ''"
                >
                  {{ data.materialTypeLabel }}
                </button>
              </template>
            </Column>

            <Column field="qty" :header="t('rawMaterialInventory.table.qty')" sortable>
              <template #body="{ data }">
                <div class="text-right">{{ formatQuantity(data.qty) }}</div>
              </template>
            </Column>

            <Column field="uomLabel" :header="t('rawMaterialInventory.table.uom')" sortable />
            <Column field="locationLabel" :header="t('rawMaterialInventory.table.location')" sortable />

            <Column :header="t('common.actions')">
              <template #body="{ data }">
                <div class="flex flex-wrap items-center gap-2">
                  <button
                    type="button"
                    class="rounded border border-gray-300 px-2 py-1 text-xs text-gray-900 hover:bg-gray-100 disabled:opacity-50"
                    :disabled="loading || disposingLotId === data.lotId"
                    @click="openEdit(data)"
                  >
                    {{ t('common.edit') }}
                  </button>
                  <button
                    type="button"
                    class="rounded border border-gray-300 px-2 py-1 text-xs text-gray-900 hover:bg-gray-100 disabled:opacity-50"
                    :disabled="loading || disposingLotId === data.lotId"
                    @click="openMove(data)"
                  >
                    {{ t('rawMaterialInventory.actions.move') }}
                  </button>
                  <button
                    type="button"
                    class="rounded border border-gray-300 px-2 py-1 text-xs text-gray-900 hover:bg-gray-100 disabled:opacity-50"
                    :disabled="loading || disposingLotId === data.lotId"
                    @click="confirmDispose(data)"
                  >
                    {{ t('rawMaterialInventory.actions.dispose') }}
                  </button>
                </div>
              </template>
            </Column>
          </DataTable>
        </section>
      </div>
    </div>

    <ConfirmActionDialog
      :open="confirmDialog.open"
      :title="confirmDialog.title"
      :message="confirmDialog.message"
      :confirm-label="confirmDialog.confirmLabel"
      :cancel-label="confirmDialog.cancelLabel"
      :tone="confirmDialog.tone"
      @cancel="cancelConfirmation"
      @confirm="acceptConfirmation"
    />
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'
import ConfirmActionDialog from '@/components/common/ConfirmActionDialog.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { useConfirmDialog } from '@/composables/useConfirmDialog'
import { supabase } from '@/lib/supabase'

type NameI18n = {
  ja?: string | null
  en?: string | null
} | null

type MaterialTypeRow = {
  type_id: string
  code: string
  name: string | null
  name_i18n?: NameI18n
  parent_type_id: string | null
  sort_order: number | null
}

type MaterialRow = {
  id: string
  material_code: string
  material_name: string
  material_type_id: string | null
  base_uom_id: string | null
  status: string
}

type SiteRow = {
  id: string
  name: string | null
}

type UomRow = {
  id: string
  code: string
  name: string | null
}

type LotRow = {
  id: string
  material_id: string | null
  site_id: string | null
  uom_id: string | null
  lot_no: string | null
  status: string | null
}

type MovementHeaderRow = {
  id: string
  status: string
  src_site_id: string | null
  dest_site_id: string | null
}

type InventoryGridRow = {
  id: string
  lotId: string
  lotNo: string | null
  materialId: string
  materialName: string
  materialTypeId: string | null
  materialTypeLabel: string
  qty: number
  uomId: string | null
  uomLabel: string
  locationId: string | null
  locationLabel: string
}

const { t, locale } = useI18n()
const router = useRouter()
const mesClient = () => supabase.schema('mes')
const { confirmDialog, requestConfirmation, cancelConfirmation, acceptConfirmation } = useConfirmDialog()

const pageTitle = computed(() => t('rawMaterialInventory.title'))

const tenantId = ref('')
const loading = ref(false)
const loadError = ref('')
const disposingLotId = ref('')

const materialTypes = ref<MaterialTypeRow[]>([])
const materialRows = ref<MaterialRow[]>([])
const siteRows = ref<SiteRow[]>([])
const uomRows = ref<UomRow[]>([])
const inventoryRows = ref<InventoryGridRow[]>([])

const filters = reactive({
  keyword: '',
  materialTypeId: '',
  locationId: '',
})

const materialTypeMap = computed(() => {
  const map = new Map<string, MaterialTypeRow>()
  materialTypes.value.forEach((row) => map.set(row.type_id, row))
  return map
})

const siteMap = computed(() => {
  const map = new Map<string, SiteRow>()
  siteRows.value.forEach((row) => map.set(row.id, row))
  return map
})

const uomMap = computed(() => {
  const map = new Map<string, UomRow>()
  uomRows.value.forEach((row) => map.set(row.id, row))
  return map
})

const rawMaterialRoot = computed(() => materialTypes.value.find((row) => row.code === 'RAW_MATERIAL') ?? null)

const rawMaterialTypeIds = computed(() => {
  if (!rawMaterialRoot.value) return new Set<string>()
  const ids = new Set<string>()
  const visit = (typeId: string) => {
    if (ids.has(typeId)) return
    ids.add(typeId)
    materialTypes.value.forEach((row) => {
      if (row.parent_type_id === typeId) visit(row.type_id)
    })
  }
  visit(rawMaterialRoot.value.type_id)
  return ids
})

const materialTypeOptions = computed(() => {
  const rootTypeId = rawMaterialRoot.value?.type_id ?? ''
  return materialTypes.value
    .filter((row) => rawMaterialTypeIds.value.has(row.type_id) && row.type_id !== rootTypeId)
    .slice()
    .sort((a, b) => materialTypePathText(a.type_id).localeCompare(materialTypePathText(b.type_id)))
    .map((row) => ({
      value: row.type_id,
      label: materialTypePathText(row.type_id),
      shortLabel: displayMaterialTypeName(row),
    }))
})

const selectedMaterialTypeIds = computed(() => {
  if (!filters.materialTypeId) return null
  const ids = new Set<string>()
  const visit = (typeId: string) => {
    if (ids.has(typeId)) return
    ids.add(typeId)
    materialTypes.value.forEach((row) => {
      if (row.parent_type_id === typeId) visit(row.type_id)
    })
  }
  visit(filters.materialTypeId)
  return ids
})

const locationOptions = computed(() => {
  return siteRows.value
    .slice()
    .sort((a, b) => String(a.name ?? '').localeCompare(String(b.name ?? '')))
    .map((row) => ({
      value: row.id,
      label: row.name ?? row.id,
    }))
})

const filteredRows = computed(() => {
  const keyword = filters.keyword.trim().toLowerCase()
  return inventoryRows.value.filter((row) => {
    const matchKeyword = keyword === '' || row.materialName.toLowerCase().includes(keyword)
    const matchType = !selectedMaterialTypeIds.value || (row.materialTypeId ? selectedMaterialTypeIds.value.has(row.materialTypeId) : false)
    const matchLocation = !filters.locationId || row.locationId === filters.locationId
    return matchKeyword && matchType && matchLocation
  })
})

function displayMaterialTypeName(row: Pick<MaterialTypeRow, 'name' | 'code' | 'name_i18n'> | null) {
  if (!row) return ''
  const isJa = locale.value.toString().toLowerCase().startsWith('ja')
  const ja = row.name_i18n?.ja?.trim()
  const en = row.name_i18n?.en?.trim()
  if (isJa) return ja || row.name || en || row.code
  return en || row.name || ja || row.code
}

function materialTypePathText(typeId: string | null | undefined) {
  if (!typeId) return '—'
  const parts: string[] = []
  const visited = new Set<string>()
  let current = materialTypeMap.value.get(typeId) ?? null
  while (current && !visited.has(current.type_id)) {
    visited.add(current.type_id)
    parts.unshift(displayMaterialTypeName(current))
    current = current.parent_type_id ? materialTypeMap.value.get(current.parent_type_id) ?? null : null
  }
  return parts.join(' / ')
}

function formatQuantity(value: number | null | undefined) {
  if (value == null) return '—'
  return new Intl.NumberFormat(locale.value, { maximumFractionDigits: 2 }).format(value)
}

function readLotIdFromMeta(value: unknown) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null
  const lotId = (value as { lot_id?: unknown }).lot_id
  if (typeof lotId !== 'string') return null
  const trimmed = lotId.trim()
  return trimmed.length > 0 ? trimmed : null
}

function generateDocNo(prefix: string) {
  const now = new Date()
  const datePart = now.toISOString().slice(0, 10).replace(/-/g, '')
  return `${prefix}-${datePart}-${Math.random().toString(36).slice(2, 6).toUpperCase()}`
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const value = data.user?.app_metadata?.tenant_id as string | undefined
  if (!value) throw new Error('Tenant not resolved')
  tenantId.value = value
  return value
}

async function calculateLotQty(lotIdValue: string, siteIdValue: string) {
  const linesResult = await supabase
    .from('inv_movement_lines')
    .select('movement_id, qty, meta')
    .contains('meta', { lot_id: lotIdValue })

  if (linesResult.error) throw linesResult.error

  const lines = ((linesResult.data ?? []) as Array<{ movement_id: string, qty: number, meta: unknown }>).map((row) => ({
    movement_id: String(row.movement_id),
    qty: Number(row.qty ?? 0),
    meta: row.meta,
  }))
  const movementIds = Array.from(new Set(lines.map((row) => row.movement_id)))
  if (movementIds.length === 0) return 0

  const movementResult = await supabase
    .from('inv_movements')
    .select('id, status, src_site_id, dest_site_id')
    .in('id', movementIds)
    .eq('status', 'posted')

  if (movementResult.error) throw movementResult.error

  const movementMap = new Map<string, MovementHeaderRow>()
  ;((movementResult.data ?? []) as MovementHeaderRow[]).forEach((row) => {
    movementMap.set(String(row.id), {
      id: String(row.id),
      status: String(row.status),
      src_site_id: typeof row.src_site_id === 'string' ? row.src_site_id : null,
      dest_site_id: typeof row.dest_site_id === 'string' ? row.dest_site_id : null,
    })
  })

  let total = 0
  lines.forEach((line) => {
    if (readLotIdFromMeta(line.meta) !== lotIdValue) return
    const movement = movementMap.get(line.movement_id)
    if (!movement) return
    if (movement.dest_site_id === siteIdValue) total += line.qty
    if (movement.src_site_id === siteIdValue) total -= line.qty
  })
  return total
}

async function refreshProjection(tenant: string, lotIdValue: string, siteIdValue: string, uomIdValue: string) {
  const qty = await calculateLotQty(lotIdValue, siteIdValue)
  const existingResult = await supabase
    .from('inv_inventory')
    .select('id')
    .eq('tenant_id', tenant)
    .eq('lot_id', lotIdValue)
    .eq('site_id', siteIdValue)
    .maybeSingle()

  if (existingResult.error) throw existingResult.error

  if (qty > 0) {
    if (existingResult.data?.id) {
      const { error } = await supabase
        .from('inv_inventory')
        .update({ qty, uom_id: uomIdValue })
        .eq('id', existingResult.data.id)
      if (error) throw error
    } else {
      const { error } = await supabase
        .from('inv_inventory')
        .insert({
          tenant_id: tenant,
          site_id: siteIdValue,
          lot_id: lotIdValue,
          qty,
          uom_id: uomIdValue,
        })
      if (error) throw error
    }
  } else if (existingResult.data?.id) {
    const { error } = await supabase.from('inv_inventory').delete().eq('id', existingResult.data.id)
    if (error) throw error
  }
}

async function loadInventory() {
  try {
    loading.value = true
    loadError.value = ''
    await ensureTenant()

    const [typeResult, materialResult, siteResult, uomResult, lotResult] = await Promise.all([
      supabase
        .from('type_def')
        .select('type_id, code, name, name_i18n, parent_type_id, sort_order')
        .eq('domain', 'material_type')
        .eq('is_active', true)
        .order('sort_order', { ascending: true })
        .order('code', { ascending: true }),
      mesClient()
        .from('mst_material')
        .select('id, material_code, material_name, material_type_id, base_uom_id, status')
        .order('material_code', { ascending: true }),
      supabase
        .from('mst_sites')
        .select('id, name')
        .order('name', { ascending: true }),
      supabase
        .from('mst_uom')
        .select('id, code, name')
        .order('code', { ascending: true }),
      supabase
        .from('lot')
        .select('id, material_id, site_id, uom_id, lot_no, status')
        .in('status', ['active', 'consumed']),
    ])

    if (typeResult.error) throw typeResult.error
    if (materialResult.error) throw materialResult.error
    if (siteResult.error) throw siteResult.error
    if (uomResult.error) throw uomResult.error
    if (lotResult.error) throw lotResult.error

    materialTypes.value = (typeResult.data ?? []) as MaterialTypeRow[]
    materialRows.value = (materialResult.data ?? []).map((row) => ({
      id: String(row.id),
      material_code: String(row.material_code ?? ''),
      material_name: String(row.material_name ?? ''),
      material_type_id: typeof row.material_type_id === 'string' ? row.material_type_id : null,
      base_uom_id: typeof row.base_uom_id === 'string' ? row.base_uom_id : null,
      status: String(row.status ?? ''),
    }))
    siteRows.value = (siteResult.data ?? []).map((row) => ({
      id: String(row.id),
      name: typeof row.name === 'string' ? row.name : null,
    }))
    uomRows.value = (uomResult.data ?? []) as UomRow[]

    const rawMaterialIds = new Set(
      materialRows.value
        .filter((row) => row.material_type_id && rawMaterialTypeIds.value.has(row.material_type_id))
        .map((row) => row.id),
    )

    const lots = ((lotResult.data ?? []) as LotRow[]).filter((row) => row.material_id && row.site_id && rawMaterialIds.has(row.material_id))
    if (lots.length === 0) {
      inventoryRows.value = []
      return
    }

    const movementLinesResult = await supabase
      .from('inv_movement_lines')
      .select('movement_id, qty, meta')
      .in('material_id', Array.from(rawMaterialIds))

    if (movementLinesResult.error) throw movementLinesResult.error

    const movementLines = ((movementLinesResult.data ?? []) as Array<{ movement_id: string, qty: number, meta: unknown }>)
      .map((row) => ({
        movement_id: String(row.movement_id),
        qty: Number(row.qty ?? 0),
        meta: row.meta,
      }))
      .filter((row) => row.qty > 0)

    const movementIds = Array.from(new Set(movementLines.map((row) => row.movement_id)))
    const movementMap = new Map<string, MovementHeaderRow>()
    if (movementIds.length > 0) {
      const movementResult = await supabase
        .from('inv_movements')
        .select('id, status, src_site_id, dest_site_id')
        .in('id', movementIds)
        .eq('status', 'posted')
      if (movementResult.error) throw movementResult.error
      ;((movementResult.data ?? []) as MovementHeaderRow[]).forEach((row) => {
        movementMap.set(String(row.id), {
          id: String(row.id),
          status: String(row.status),
          src_site_id: typeof row.src_site_id === 'string' ? row.src_site_id : null,
          dest_site_id: typeof row.dest_site_id === 'string' ? row.dest_site_id : null,
        })
      })
    }

    const balanceMap = new Map<string, number>()
    movementLines.forEach((line) => {
      const lotId = readLotIdFromMeta(line.meta)
      if (!lotId) return
      const movement = movementMap.get(line.movement_id)
      if (!movement) return
      if (movement.dest_site_id) {
        const key = `${lotId}::${movement.dest_site_id}`
        balanceMap.set(key, (balanceMap.get(key) ?? 0) + line.qty)
      }
      if (movement.src_site_id) {
        const key = `${lotId}::${movement.src_site_id}`
        balanceMap.set(key, (balanceMap.get(key) ?? 0) - line.qty)
      }
    })

    const materialMap = new Map<string, MaterialRow>()
    materialRows.value.forEach((row) => materialMap.set(row.id, row))

    const nextRows: InventoryGridRow[] = []
    lots.forEach((lot) => {
      const material = lot.material_id ? materialMap.get(lot.material_id) ?? null : null
      if (!material || !lot.site_id) return
      const qty = balanceMap.get(`${lot.id}::${lot.site_id}`) ?? 0
      if (qty <= 0) return
      const typeLabel = material.material_type_id ? materialTypePathText(material.material_type_id) : '—'
      const siteLabel = siteMap.value.get(lot.site_id)?.name ?? lot.site_id
      const uomId = lot.uom_id ?? material.base_uom_id
      const uom = uomId ? uomMap.value.get(uomId) ?? null : null
      nextRows.push({
        id: lot.id,
        lotId: lot.id,
        lotNo: lot.lot_no ?? null,
        materialId: material.id,
        materialName: material.material_name || material.material_code,
        materialTypeId: material.material_type_id,
        materialTypeLabel: typeLabel,
        qty,
        uomId,
        uomLabel: uom ? (uom.name ? `${uom.code} - ${uom.name}` : uom.code) : '—',
        locationId: lot.site_id,
        locationLabel: siteLabel,
      })
    })

    inventoryRows.value = nextRows
  } catch (error) {
    loadError.value = error instanceof Error ? error.message : String(error)
    toast.error(loadError.value)
    inventoryRows.value = []
  } finally {
    loading.value = false
  }
}

function openCreate() {
  void router.push({ name: 'RawMaterialInventoryEdit' })
}

function openEdit(row: InventoryGridRow) {
  void router.push({ name: 'RawMaterialInventoryEdit', params: { lotId: row.lotId } })
}

function openMove(row: InventoryGridRow) {
  void router.push({ name: 'RawMaterialInventoryEdit', params: { lotId: row.lotId }, query: { mode: 'move' } })
}

async function disposeRow(row: InventoryGridRow) {
  if (!row.locationId) {
    toast.error(t('rawMaterialInventory.errors.locationRequired'))
    return
  }
  if (!row.uomId) {
    toast.error(t('rawMaterialInventory.errors.uomRequired'))
    return
  }

  const confirmed = await requestConfirmation({
    title: t('rawMaterialInventory.dispose.title'),
    message: t('rawMaterialInventory.dispose.confirm', {
      material: row.materialName,
      lotNo: row.lotNo || row.lotId,
      qty: formatQuantity(row.qty),
      location: row.locationLabel,
    }),
    confirmLabel: t('rawMaterialInventory.actions.dispose'),
    cancelLabel: t('common.cancel'),
    tone: 'danger',
  })

  if (!confirmed) return

  try {
    disposingLotId.value = row.lotId
    const tenant = await ensureTenant()

    const movementResult = await supabase
      .from('inv_movements')
      .insert({
        tenant_id: tenant,
        doc_no: generateDocNo('RMWST'),
        doc_type: 'waste',
        status: 'posted',
        movement_at: new Date().toISOString(),
        src_site_id: row.locationId,
        dest_site_id: null,
        reason: 'raw_material_inventory_dispose',
        meta: {
          source: 'raw_material_inventory_list',
          lot_id: row.lotId,
        },
      })
      .select('id')
      .single()

    if (movementResult.error || !movementResult.data) {
      throw movementResult.error || new Error('Movement insert failed')
    }

    const lineResult = await supabase.from('inv_movement_lines').insert({
      tenant_id: tenant,
      movement_id: movementResult.data.id,
      line_no: 1,
      material_id: row.materialId,
      qty: row.qty,
      uom_id: row.uomId,
      meta: {
        lot_id: row.lotId,
      },
    })
    if (lineResult.error) throw lineResult.error

    const lotResult = await supabase
      .from('lot')
      .update({
        qty: 0,
        status: 'consumed',
        uom_id: row.uomId,
      })
      .eq('id', row.lotId)
    if (lotResult.error) throw lotResult.error

    await refreshProjection(tenant, row.lotId, row.locationId, row.uomId)
    toast.success(t('rawMaterialInventory.dispose.done'))
    await loadInventory()
  } catch (error) {
    toast.error(error instanceof Error ? error.message : String(error))
  } finally {
    disposingLotId.value = ''
  }
}

function confirmDispose(row: InventoryGridRow) {
  void disposeRow(row)
}

onMounted(() => {
  void loadInventory()
})
</script>

<style scoped>
.inventory-datatable :deep(.p-datatable-table-container) {
  overflow-x: auto;
}

.inventory-datatable :deep(.p-datatable-table) {
  min-width: 100%;
}

.inventory-datatable :deep(.p-datatable-thead > tr > th) {
  border-bottom: 1px solid #e5e7eb;
  background: #f9fafb;
  padding: 0.75rem 1rem;
  text-align: left;
  font-size: 0.75rem;
  font-weight: 600;
  line-height: 1rem;
  letter-spacing: 0.05em;
  color: #6b7280;
  text-transform: uppercase;
}

.inventory-datatable :deep(.p-column-header-content) {
  gap: 0.25rem;
}

.inventory-datatable :deep(.p-datatable-tbody > tr) {
  transition: background-color 150ms ease;
}

.inventory-datatable :deep(.p-datatable-tbody > tr:hover) {
  background: #f9fafb;
}

.inventory-datatable :deep(.p-datatable-tbody > tr > td) {
  border-bottom: 1px solid #f3f4f6;
  padding: 0.75rem 1rem;
  vertical-align: top;
  font-size: 0.875rem;
  line-height: 1.25rem;
  color: #4b5563;
}

.inventory-datatable :deep(.p-datatable-empty-message) {
  padding: 2rem 1rem;
}

.inventory-datatable :deep(.p-sortable-column:not(.p-highlight):hover) {
  background: #f3f4f6;
  color: #4b5563;
}

.inventory-datatable :deep(.p-sortable-column.p-highlight) {
  background: #f9fafb;
  color: #1f2937;
}

.inventory-datatable :deep(.p-sortable-column-icon) {
  color: #9ca3af;
}

.inventory-datatable :deep(.p-paginator) {
  border-top: 1px solid #e5e7eb;
  background: #ffffff;
  padding: 0.75rem 1rem;
}

.inventory-datatable :deep(.p-paginator-current) {
  color: #111827;
}

.inventory-datatable :deep(.p-paginator .p-paginator-page),
.inventory-datatable :deep(.p-paginator .p-paginator-prev),
.inventory-datatable :deep(.p-paginator .p-paginator-next),
.inventory-datatable :deep(.p-paginator .p-paginator-first),
.inventory-datatable :deep(.p-paginator .p-paginator-last) {
  min-width: 2rem;
  height: 2rem;
  border: 1px solid transparent;
  border-radius: 0.375rem;
  color: #4b5563;
}

.inventory-datatable :deep(.p-paginator .p-paginator-page:hover),
.inventory-datatable :deep(.p-paginator .p-paginator-prev:hover),
.inventory-datatable :deep(.p-paginator .p-paginator-next:hover),
.inventory-datatable :deep(.p-paginator .p-paginator-first:hover),
.inventory-datatable :deep(.p-paginator .p-paginator-last:hover) {
  background: #f3f4f6;
}

.inventory-datatable :deep(.p-paginator .p-paginator-page.p-highlight) {
  background: #2563eb;
  color: #ffffff;
}

.inventory-datatable :deep(.p-paginator-rpp-dropdown),
.inventory-datatable :deep(.p-paginator-rpp-dropdown .p-select-label),
.inventory-datatable :deep(.p-paginator-rpp-dropdown .p-select-dropdown) {
  background: #ffffff;
  color: #111827;
}

.inventory-datatable :deep(.p-paginator-rpp-dropdown) {
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
}
</style>
