<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto space-y-6">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ editing ? t('producedBeer.edit.titleEdit') : t('producedBeer.edit.titleNew') }}</h1>
          <p class="text-sm text-gray-500">{{ t('producedBeer.edit.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50" @click="goBack">
            {{ t('producedBeer.edit.back') }}
          </button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.edit.form.docNo') }}<span class="text-red-600">*</span></label>
            <input v-model.trim="movementForm.docNo" class="w-full h-[40px] border rounded px-3" />
            <p v-if="errors.docNo" class="text-xs text-red-600 mt-1">{{ errors.docNo }}</p>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.edit.form.docType') }}<span class="text-red-600">*</span></label>
            <select v-model="movementForm.docType" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.select') }}</option>
              <option v-for="option in movementDocTypeOptions" :key="option" :value="option">
                {{ docTypeLabel(option) }}
              </option>
            </select>
            <p v-if="errors.docType" class="text-xs text-red-600 mt-1">{{ errors.docType }}</p>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.edit.form.movementDate') }}<span class="text-red-600">*</span></label>
            <input v-model="movementForm.movementAt" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
            <p v-if="errors.movementAt" class="text-xs text-red-600 mt-1">{{ errors.movementAt }}</p>
          </div>
        </div>
      </section>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <header class="flex items-center justify-between">
          <div>
            <h2 class="text-lg font-semibold">{{ t('producedBeer.edit.source.title') }}</h2>
            <p class="text-sm text-gray-500">{{ t('producedBeer.edit.source.subtitle') }}</p>
          </div>
          <div class="w-full md:w-72">
            <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.edit.form.sourceSite') }}<span class="text-red-600">*</span></label>
            <select v-model="movementForm.sourceSiteId" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.select') }}</option>
              <option v-for="option in siteOptions" :key="`src-${option.value}`" :value="option.value">
                {{ option.label }}
              </option>
            </select>
            <p v-if="errors.site" class="text-xs text-red-600 mt-1">{{ errors.site }}</p>
          </div>
        </header>

        <div class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.beerName') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.category') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.packageType') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.lotNo') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.productionDate') }}</th>
                <th class="px-3 py-2 text-right">{{ t('producedBeer.inventory.table.qtyLiters') }}</th>
                <th class="px-3 py-2 text-right">{{ t('producedBeer.inventory.table.qtyPackages') }}</th>
                <th class="px-3 py-2 text-left">{{ t('producedBeer.inventory.table.site') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr
                v-for="row in sourceInventoryRows"
                :key="row.id"
                class="hover:bg-gray-50 cursor-pointer"
                @dblclick="openMoveDialog(row)"
              >
                <td class="px-3 py-2">
                  <div class="font-medium text-gray-900">{{ row.beerName || '—' }}</div>
                </td>
                <td class="px-3 py-2">{{ categoryLabel(row.categoryId) }}</td>
                <td class="px-3 py-2">{{ row.packageTypeLabel || '—' }}</td>
                <td class="px-3 py-2 font-mono text-xs text-gray-600">{{ row.lotCode || '—' }}</td>
                <td class="px-3 py-2 text-xs text-gray-500">{{ formatDate(row.productionDate) }}</td>
                <td class="px-3 py-2 text-right">{{ formatNumber(row.qtyLiters) }}</td>
                <td class="px-3 py-2 text-right">{{ formatNumber(row.qtyPackages) }}</td>
                <td class="px-3 py-2">{{ siteLabel(row.siteId) }}</td>
              </tr>
              <tr v-if="!inventoryLoading && sourceInventoryRows.length === 0">
                <td colspan="8" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <header class="flex items-center justify-between">
          <div>
            <h2 class="text-lg font-semibold">{{ t('producedBeer.edit.destination.title') }}</h2>
            <p class="text-sm text-gray-500">{{ t('producedBeer.edit.destination.subtitle') }}</p>
          </div>
          <div class="w-full md:w-72">
            <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.edit.form.destinationSite') }}<span class="text-red-600">*</span></label>
            <select v-model="movementForm.destSiteId" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.select') }}</option>
              <option v-for="option in siteOptions" :key="`dest-${option.value}`" :value="option.value">
                {{ option.label }}
              </option>
            </select>
            <p v-if="errors.site" class="text-xs text-red-600 mt-1">{{ errors.site }}</p>
          </div>
        </header>

        <section class="border border-gray-200 rounded-lg">
          <header class="flex items-center justify-between px-3 py-2 border-b bg-gray-50">
            <h3 class="text-sm font-semibold text-gray-800">{{ t('producedBeer.edit.lines.title') }}</h3>
            <span class="text-xs text-gray-500">{{ t('producedBeer.edit.lines.hint') }}</span>
          </header>
          <p v-if="errors.lines" class="px-3 pt-2 text-xs text-red-600">{{ errors.lines }}</p>
          <div class="overflow-x-auto">
            <table class="min-w-full text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                <tr>
                  <th class="px-3 py-2 text-left">{{ t('producedBeer.edit.lines.columns.beer') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('producedBeer.edit.lines.columns.category') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('producedBeer.edit.lines.columns.packageType') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('producedBeer.edit.lines.columns.lot') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('producedBeer.edit.lines.columns.qtyPackages') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('producedBeer.edit.lines.columns.qtyLiters') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="(line, index) in movementForm.lines" :key="line.localId">
                  <td class="px-3 py-2 text-gray-900">{{ line.beerName || '—' }}</td>
                  <td class="px-3 py-2 text-gray-600">{{ categoryLabel(line.categoryId) }}</td>
                  <td class="px-3 py-2 text-gray-600">{{ line.packageTypeLabel || '—' }}</td>
                  <td class="px-3 py-2 font-mono text-xs text-gray-500">{{ line.lotCode || '—' }}</td>
                  <td class="px-3 py-2 text-right">{{ formatNumber(line.packageQty) }}</td>
                  <td class="px-3 py-2 text-right">{{ formatNumber(line.qtyLiters) }}</td>
                  <td class="px-3 py-2">
                    <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="removeMovementLine(index)">
                      {{ t('common.delete') }}
                    </button>
                  </td>
                </tr>
                <tr v-if="movementForm.lines.length === 0">
                  <td colspan="7" class="px-3 py-6 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </section>

      <footer class="flex items-center justify-end gap-2">
        <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="goBack">{{ t('common.cancel') }}</button>
        <button
          class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
          :disabled="saving"
          @click="saveMovement"
        >
          {{ saving ? t('common.saving') : t('common.save') }}
        </button>
      </footer>

      <div v-if="showMoveDialog" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
          <header class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('producedBeer.edit.moveDialog.title') }}</h3>
          </header>
          <section class="p-4 space-y-3">
            <div class="text-sm text-gray-600">
              <p class="font-medium text-gray-900">{{ selectedInventory?.beerName || '—' }}</p>
              <p>{{ selectedInventory?.packageTypeLabel || '—' }}</p>
              <p class="text-xs text-gray-500">{{ selectedInventory?.lotCode || '—' }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.edit.moveDialog.packageQty') }}</label>
              <input
                v-model.number="moveQuantity"
                type="number"
                min="0"
                step="1"
                class="w-full h-[40px] border rounded px-3"
                :max="selectedInventory?.qtyPackages ?? undefined"
              />
              <p v-if="moveDialogError" class="text-xs text-red-600 mt-1">{{ moveDialogError }}</p>
            </div>
            <div class="text-xs text-gray-500">
              {{ t('producedBeer.edit.moveDialog.qtyLiters') }}: {{ formatNumber(calculatedMoveLiters) }}
            </div>
          </section>
          <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeMoveDialog">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="confirmMoveQuantity">
              {{ t('producedBeer.edit.moveDialog.confirm') }}
            </button>
          </footer>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import { supabase } from '@/lib/supabase'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

interface CategoryRow {
  id: string
  code: string
  name: string | null
}

interface SiteOption {
  value: string
  label: string
}

interface PackageCategoryRow {
  id: string
  package_code: string
  package_name: string | null
  size: number | null
  uom_id: string | null
}

interface PackageRow {
  id: string
  lot_id: string | null
  fill_at: string | null
  package_id: string | null
  package_size_l: number | null
  package_qty: number | null
  lot?: {
    id: string
    lot_code: string
    recipe?: {
      id: string
      name: string
      category: string | null
    } | null
  } | null
  package?: {
    id: string
    package_code: string
    package_name: string | null
    size: number | null
    uom_id: string | null
  } | null
}

interface InventoryRow {
  id: string
  beerName: string | null
  categoryId: string | null
  packageTypeLabel: string | null
  packageTypeId: string | null
  lotCode: string | null
  productionDate: string | null
  qtyPackages: number | null
  qtyLiters: number | null
  siteId: string | null
  unitSizeLiters: number | null
  lotId: string | null
}

interface MovementHeader {
  id: string
  doc_no: string
  doc_type: string
  movement_at: string | null
  status: string
  src_site_id: string | null
  dest_site_id: string | null
  notes: string | null
}

interface MovementLineRow {
  id: string
  movement_id: string
  package_id: string | null
  lot_id: string | null
  qty: number | null
  uom_id: string | null
  meta?: Record<string, any> | null
}

interface PackageInfo {
  id: string
  lotId: string | null
  lotCode: string | null
  beerName: string | null
  categoryId: string | null
  packageTypeId: string | null
  packageTypeLabel: string | null
  unitSizeLiters: number | null
}

interface MovementLineForm {
  localId: string
  id?: string
  packageId: string
  packageQty: number | null
  qtyLiters: number | null
  lotId: string | null
  lotCode: string | null
  beerName: string | null
  categoryId: string | null
  packageTypeId: string | null
  packageTypeLabel: string | null
  unitSizeLiters: number | null
}

const { t, locale } = useI18n()
const router = useRouter()
const route = useRoute()
const pageTitle = computed(() => t('producedBeer.edit.breadcrumb'))

const tenantId = ref<string | null>(null)
const inventoryLoading = ref(false)
const saving = ref(false)

const categories = ref<CategoryRow[]>([])
const packageCategories = ref<PackageCategoryRow[]>([])
const uoms = ref<Array<{ id: string; code: string | null }>>([])
const siteOptions = ref<SiteOption[]>([])
const packages = ref<PackageRow[]>([])
const locationByPackage = ref<Map<string, { siteId: string; movementAt: string }>>(new Map())
const locationByLot = ref<Map<string, { siteId: string; movementAt: string }>>(new Map())

const movementForm = reactive({
  id: '',
  docNo: '',
  docType: '',
  movementAt: '',
  status: 'open',
  sourceSiteId: '',
  destSiteId: '',
  notes: '',
  lines: [] as MovementLineForm[],
})

const errors = reactive<Record<string, string>>({})

const showMoveDialog = ref(false)
const selectedInventory = ref<InventoryRow | null>(null)
const moveQuantity = ref<number | null>(null)
const moveDialogError = ref('')

const movementDocTypeOptions = ['sale', 'tax_transfer', 'return', 'transfer', 'waste']

const editing = computed(() => Boolean(movementForm.id))

const siteMap = computed(() => {
  const map = new Map<string, SiteOption>()
  siteOptions.value.forEach((item) => map.set(item.value, item))
  return map
})

const categoryMap = computed(() => {
  const map = new Map<string, CategoryRow>()
  categories.value.forEach((row) => map.set(row.id, row))
  return map
})

const packageCategoryMap = computed(() => {
  const map = new Map<string, { label: string; size: number | null; uomId: string | null }>()
  packageCategories.value.forEach((row) => {
    map.set(row.id, {
      label: row.package_name || row.package_code,
      size: row.size ?? null,
      uomId: row.uom_id ?? null,
    })
  })
  return map
})

const uomMap = computed(() => {
  const map = new Map<string, string>()
  uoms.value.forEach((row) => map.set(row.id, row.code ?? ''))
  return map
})

const packageLookup = computed(() => {
  const map = new Map<string, PackageInfo>()
  packages.value.forEach((row) => {
    if (!row.id) return
    const lotCode = row.lot?.lot_code ?? null
    const beerName = row.lot?.recipe?.name ?? null
    const categoryId = row.lot?.recipe?.category ?? null
    const packageTypeId = row.package_id ?? row.package?.id ?? null
    const packageTypeLabel =
      row.package?.package_name ||
      row.package?.package_code ||
      (packageTypeId ? packageCategoryMap.value.get(packageTypeId)?.label : null) ||
      null
    const unitSizeLiters = resolvePackageSizeLiters(row)
    map.set(row.id, {
      id: row.id,
      lotId: row.lot_id ?? row.lot?.id ?? null,
      lotCode,
      beerName,
      categoryId,
      packageTypeId,
      packageTypeLabel,
      unitSizeLiters,
    })
  })
  return map
})

const inventoryRows = computed<InventoryRow[]>(() => {
  return packages.value.map((row) => {
    const info = packageLookup.value.get(row.id)
    const packageQty = toNumber(row.package_qty)
    const qtyLiters = info?.unitSizeLiters && packageQty != null ? packageQty * info.unitSizeLiters : null
    const location = locationByPackage.value.get(row.id)
    const lotLocation = info?.lotId ? locationByLot.value.get(info.lotId) : undefined
    return {
      id: row.id,
      beerName: info?.beerName ?? null,
      categoryId: info?.categoryId ?? null,
      packageTypeLabel: info?.packageTypeLabel ?? null,
      packageTypeId: info?.packageTypeId ?? null,
      lotCode: info?.lotCode ?? null,
      productionDate: row.fill_at ?? null,
      qtyPackages: packageQty,
      qtyLiters,
      siteId: location?.siteId || lotLocation?.siteId || null,
      unitSizeLiters: info?.unitSizeLiters ?? null,
      lotId: info?.lotId ?? null,
    }
  })
})

const sourceInventoryRows = computed(() => {
  if (!movementForm.sourceSiteId) return []
  return inventoryRows.value.filter((row) => row.siteId === movementForm.sourceSiteId)
})

const calculatedMoveLiters = computed(() => {
  if (!selectedInventory.value || !moveQuantity.value) return null
  return selectedInventory.value.unitSizeLiters ? moveQuantity.value * selectedInventory.value.unitSizeLiters : null
})

const numberFormatter = computed(() => new Intl.NumberFormat(locale.value, { maximumFractionDigits: 2 }))

function formatNumber(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return numberFormatter.value.format(value)
}

function formatDate(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Intl.DateTimeFormat(locale.value).format(new Date(value))
  } catch {
    return value
  }
}

function categoryLabel(categoryId: string | null | undefined) {
  if (!categoryId) return '—'
  const category = categoryMap.value.get(categoryId)
  return category?.name || category?.code || categoryId
}

function siteLabel(siteId: string | null | undefined) {
  if (!siteId) return '—'
  return siteMap.value.get(siteId)?.label ?? '—'
}

function docTypeLabel(value: string) {
  const map = t('producedBeer.movement.docTypeMap') as Record<string, string>
  return map[value] || value
}

function toNumber(value: any): number | null {
  if (value == null) return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function convertToLiters(size: number | null, uomCode: string | null | undefined) {
  if (size == null || Number.isNaN(size)) return null
  switch (uomCode) {
    case 'L':
    case null:
    case undefined:
      return size
    case 'mL':
      return size / 1000
    case 'gal_us':
      return size * 3.78541
    default:
      return size
  }
}

function resolvePackageSizeLiters(row: PackageRow): number | null {
  const direct = toNumber(row.package_size_l)
  if (direct != null && direct > 0) return direct
  const size = toNumber(row.package?.size)
  if (size == null) return null
  const uomCode = row.package?.uom_id ? uomMap.value.get(row.package.uom_id) : null
  return convertToLiters(size, uomCode)
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

async function loadCategories() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_category')
    .select('id, code, name')
    .eq('tenant_id', tenant)
    .order('code', { ascending: true })
  if (error) throw error
  categories.value = data ?? []
}

async function loadPackageCategories() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_beer_package_category')
    .select('id, package_code, package_name, size, uom_id')
    .eq('tenant_id', tenant)
    .order('package_code', { ascending: true })
  if (error) throw error
  packageCategories.value = data ?? []
}

async function loadUoms() {
  const { data, error } = await supabase.from('mst_uom').select('id, code').order('code', { ascending: true })
  if (error) throw error
  uoms.value = data ?? []
}

async function loadSites() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_sites')
    .select('id, code, name')
    .eq('tenant_id', tenant)
    .order('code', { ascending: true })
  if (error) throw error
  siteOptions.value = (data ?? []).map((row) => ({ value: row.id, label: `${row.code} — ${row.name}` }))
}

async function loadPackageInventory() {
  try {
    inventoryLoading.value = true
    const tenant = await ensureTenant()
    const { data, error } = await supabase
      .from('pkg_packages')
      .select(
        'id, lot_id, fill_at, package_id, package_size_l, package_qty, lot:lot_id ( id, lot_code, recipe:rcp_recipes ( id, name, category ) ), package:package_id ( id, package_code, package_name, size, uom_id )'
      )
      .eq('tenant_id', tenant)
      .order('fill_at', { ascending: false })
    if (error) throw error
    packages.value = (data ?? []) as PackageRow[]
    await loadLocations(packages.value)
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    inventoryLoading.value = false
  }
}

async function loadLocations(rows: PackageRow[]) {
  const packageIds = rows.map((row) => row.id).filter(Boolean)
  const lotIds = rows.map((row) => row.lot_id).filter(Boolean) as string[]

  const packageMap = new Map<string, { siteId: string; movementAt: string }>()
  const lotMap = new Map<string, { siteId: string; movementAt: string }>()

  if (packageIds.length > 0) {
    const { data, error } = await supabase
      .from('inv_movement_lines')
      .select('package_id, movement:movement_id ( movement_at, dest_site_id )')
      .in('package_id', packageIds)
    if (!error && data) {
      data.forEach((row: any) => {
        const packageId = row.package_id as string | null
        const movementAt = row.movement?.movement_at as string | null
        const destSiteId = row.movement?.dest_site_id as string | null
        if (!packageId || !movementAt || !destSiteId) return
        const existing = packageMap.get(packageId)
        if (!existing || new Date(movementAt) > new Date(existing.movementAt)) {
          packageMap.set(packageId, { siteId: destSiteId, movementAt })
        }
      })
    }
  }

  if (lotIds.length > 0) {
    const { data, error } = await supabase
      .from('inv_movement_lines')
      .select('lot_id, movement:movement_id ( movement_at, dest_site_id )')
      .in('lot_id', lotIds)
    if (!error && data) {
      data.forEach((row: any) => {
        const lotId = row.lot_id as string | null
        const movementAt = row.movement?.movement_at as string | null
        const destSiteId = row.movement?.dest_site_id as string | null
        if (!lotId || !movementAt || !destSiteId) return
        const existing = lotMap.get(lotId)
        if (!existing || new Date(movementAt) > new Date(existing.movementAt)) {
          lotMap.set(lotId, { siteId: destSiteId, movementAt })
        }
      })
    }
  }

  locationByPackage.value = packageMap
  locationByLot.value = lotMap
}

function openMoveDialog(row: InventoryRow) {
  if (!movementForm.sourceSiteId) {
    toast.error(t('producedBeer.edit.errors.sourceRequired'))
    return
  }
  selectedInventory.value = row
  moveQuantity.value = null
  moveDialogError.value = ''
  showMoveDialog.value = true
}

function closeMoveDialog() {
  showMoveDialog.value = false
  selectedInventory.value = null
  moveQuantity.value = null
  moveDialogError.value = ''
}

function confirmMoveQuantity() {
  if (!selectedInventory.value) return
  if (!moveQuantity.value || moveQuantity.value <= 0) {
    moveDialogError.value = t('producedBeer.edit.errors.moveQtyRequired')
    return
  }
  const maxQty = selectedInventory.value.qtyPackages ?? null
  if (maxQty != null && moveQuantity.value > maxQty) {
    moveDialogError.value = t('producedBeer.edit.errors.moveQtyExceed')
    return
  }

  const packageId = selectedInventory.value.id
  const existing = movementForm.lines.find((line) => line.packageId === packageId)
  const qtyLiters = selectedInventory.value.unitSizeLiters
    ? moveQuantity.value * selectedInventory.value.unitSizeLiters
    : null

  if (existing) {
    existing.packageQty = (existing.packageQty ?? 0) + moveQuantity.value
    existing.qtyLiters = (existing.qtyLiters ?? 0) + (qtyLiters ?? 0)
  } else {
    movementForm.lines.push({
      localId: createLocalId(),
      packageId,
      packageQty: moveQuantity.value,
      qtyLiters,
      lotId: selectedInventory.value.lotId ?? null,
      lotCode: selectedInventory.value.lotCode ?? null,
      beerName: selectedInventory.value.beerName ?? null,
      categoryId: selectedInventory.value.categoryId ?? null,
      packageTypeId: selectedInventory.value.packageTypeId ?? null,
      packageTypeLabel: selectedInventory.value.packageTypeLabel ?? null,
      unitSizeLiters: selectedInventory.value.unitSizeLiters ?? null,
    })
  }

  closeMoveDialog()
}

function removeMovementLine(index: number) {
  movementForm.lines.splice(index, 1)
}

function validateForm() {
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!movementForm.docNo) errors.docNo = t('producedBeer.edit.errors.docNoRequired')
  if (!movementForm.docType) errors.docType = t('producedBeer.edit.errors.docTypeRequired')
  if (!movementForm.movementAt) errors.movementAt = t('producedBeer.edit.errors.movementDateRequired')
  if (!movementForm.sourceSiteId || !movementForm.destSiteId) errors.site = t('producedBeer.edit.errors.siteRequired')
  if (movementForm.lines.length === 0) errors.lines = t('producedBeer.edit.errors.linesRequired')

  return Object.keys(errors).length === 0
}

async function saveMovement() {
  if (!validateForm()) return
  try {
    saving.value = true
    const tenant = await ensureTenant()
    const payload = {
      tenant_id: tenant,
      doc_no: movementForm.docNo.trim(),
      doc_type: movementForm.docType,
      movement_at: new Date(movementForm.movementAt).toISOString(),
      status: movementForm.status,
      src_site_id: movementForm.sourceSiteId || null,
      dest_site_id: movementForm.destSiteId || null,
      notes: movementForm.notes.trim() || null,
    }

    let movementId = movementForm.id
    if (movementId) {
      const { error } = await supabase.from('inv_movements').update(payload).eq('id', movementId)
      if (error) throw error
      await supabase.from('inv_movement_lines').delete().eq('movement_id', movementId)
    } else {
      const { data, error } = await supabase.from('inv_movements').insert(payload).select('id').single()
      if (error || !data) throw error || new Error('Insert failed')
      movementId = data.id
    }

    const linePayload = movementForm.lines.map((line, index) => ({
      tenant_id: tenant,
      movement_id: movementId,
      line_no: index + 1,
      package_id: line.packageId || null,
      lot_id: line.lotId ?? null,
      qty: line.qtyLiters ?? 0,
      uom_id: findLitersUomId(),
      meta: line.packageQty ? { package_qty: line.packageQty } : null,
    }))

    if (linePayload.length > 0) {
      const { error: lineError } = await supabase.from('inv_movement_lines').insert(linePayload)
      if (lineError) throw lineError
    }

    toast.success(t('producedBeer.edit.toast.saved'))
    goBack()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

function findLitersUomId() {
  const match = uoms.value.find((row) => row.code?.toLowerCase() === 'l')
  return match?.id ?? uoms.value[0]?.id ?? null
}

function createLocalId() {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return crypto.randomUUID()
  }
  return `line-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
}

function goBack() {
  router.push({ path: '/producedBeer' })
}

async function loadMovement(movementId: string) {
  const { data, error } = await supabase
    .from('inv_movements')
    .select('id, doc_no, doc_type, movement_at, status, src_site_id, dest_site_id, notes')
    .eq('id', movementId)
    .single()
  if (error) throw error
  const header = data as MovementHeader
  movementForm.id = header.id
  movementForm.docNo = header.doc_no
  movementForm.docType = header.doc_type
  movementForm.movementAt = header.movement_at ? formatInputDateTime(new Date(header.movement_at)) : formatInputDateTime(new Date())
  movementForm.status = header.status
  movementForm.sourceSiteId = header.src_site_id ?? ''
  movementForm.destSiteId = header.dest_site_id ?? ''
  movementForm.notes = header.notes ?? ''

  const { data: lines, error: lineError } = await supabase
    .from('inv_movement_lines')
    .select('id, movement_id, package_id, lot_id, qty, uom_id, meta')
    .eq('movement_id', movementId)
    .order('line_no', { ascending: true })
  if (lineError) throw lineError

  movementForm.lines = (lines ?? []).map((row: any) => {
    const pkgInfo = row.package_id ? packageLookup.value.get(row.package_id) : undefined
    const unitSize = pkgInfo?.unitSizeLiters
    const qtyLiters = toNumber(row.qty)
    const packageQty = toNumber(row.meta?.package_qty) ?? (unitSize && qtyLiters ? qtyLiters / unitSize : null)
    return {
      localId: createLocalId(),
      id: row.id,
      packageId: row.package_id ?? '',
      packageQty,
      qtyLiters: qtyLiters ?? (packageQty && unitSize ? packageQty * unitSize : null),
      lotId: row.lot_id ?? pkgInfo?.lotId ?? null,
      lotCode: pkgInfo?.lotCode ?? null,
      beerName: pkgInfo?.beerName ?? null,
      categoryId: pkgInfo?.categoryId ?? null,
      packageTypeId: pkgInfo?.packageTypeId ?? null,
      packageTypeLabel: pkgInfo?.packageTypeLabel ?? null,
      unitSizeLiters: unitSize ?? null,
    }
  })
}

function formatInputDateTime(date: Date) {
  const pad = (n: number) => String(n).padStart(2, '0')
  const yyyy = date.getFullYear()
  const mm = pad(date.getMonth() + 1)
  const dd = pad(date.getDate())
  const hh = pad(date.getHours())
  const mi = pad(date.getMinutes())
  return `${yyyy}-${mm}-${dd}T${hh}:${mi}`
}

onMounted(async () => {
  try {
    await ensureTenant()
    await Promise.all([loadSites(), loadCategories(), loadPackageCategories(), loadUoms()])
    await loadPackageInventory()
    if (typeof route.query.id === 'string' && route.query.id) {
      await loadMovement(route.query.id)
    } else {
      movementForm.movementAt = formatInputDateTime(new Date())
    }
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
