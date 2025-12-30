<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto space-y-6">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('beerInventory.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('beerInventory.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="inventoryLoading || movementLoading"
            @click="refreshAll"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <header class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-semibold">{{ t('beerInventory.sections.inventory') }}</h2>
            <p class="text-sm text-gray-500">{{ t('beerInventory.inventory.subtitle') }}</p>
          </div>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="inventoryLoading"
            @click="loadPackageInventory"
          >
            {{ t('common.refresh') }}
          </button>
        </header>

        <div class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.inventory.table.beerName') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.inventory.table.category') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.inventory.table.packageType') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.inventory.table.lotNo') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.inventory.table.productionDate') }}</th>
                <th class="px-3 py-2 text-right">{{ t('beerInventory.inventory.table.qtyLiters') }}</th>
                <th class="px-3 py-2 text-right">{{ t('beerInventory.inventory.table.qtyPackages') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.inventory.table.site') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="row in inventoryRows" :key="row.id" class="hover:bg-gray-50">
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
              <tr v-if="!inventoryLoading && inventoryRows.length === 0">
                <td colspan="8" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <header class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-semibold">{{ t('beerInventory.sections.movements') }}</h2>
            <p class="text-sm text-gray-500">{{ t('beerInventory.movement.subtitle') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openMovementCreate">
              {{ t('common.new') }}
            </button>
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
              :disabled="movementLoading"
              @click="fetchMovements"
            >
              {{ t('common.refresh') }}
            </button>
          </div>
        </header>

        <section class="border border-gray-200 rounded-lg p-4 bg-white">
          <form class="grid grid-cols-1 md:grid-cols-6 gap-3" @submit.prevent>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.movement.filters.beerName') }}</label>
              <input v-model.trim="movementFilters.beerName" type="search" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.movement.filters.category') }}</label>
              <select v-model="movementFilters.category" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.all') }}</option>
                <option v-for="category in categories" :key="category.id" :value="category.id">
                  {{ category.name || category.code || category.id }}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.movement.filters.packageType') }}</label>
              <select v-model="movementFilters.packageType" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.all') }}</option>
                <option v-for="option in packageCategoryOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.movement.filters.lotNo') }}</label>
              <input v-model.trim="movementFilters.lotNo" type="search" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.movement.filters.dateFrom') }}</label>
              <input v-model="movementFilters.dateFrom" type="date" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.movement.filters.dateTo') }}</label>
              <input v-model="movementFilters.dateTo" type="date" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div class="md:col-span-4">
              <label class="block text-sm text-gray-600 mb-2">{{ t('beerInventory.movement.filters.movementType') }}</label>
              <div class="flex flex-wrap gap-4 text-sm">
                <label class="inline-flex items-center gap-2">
                  <input v-model="movementTypeFilters.domestic" type="checkbox" class="h-4 w-4" />
                  <span>{{ t('beerInventory.movement.types.domestic') }}</span>
                </label>
                <label class="inline-flex items-center gap-2">
                  <input v-model="movementTypeFilters.foreign" type="checkbox" class="h-4 w-4" />
                  <span>{{ t('beerInventory.movement.types.foreign') }}</span>
                </label>
                <label class="inline-flex items-center gap-2">
                  <input v-model="movementTypeFilters.internal" type="checkbox" class="h-4 w-4" />
                  <span>{{ t('beerInventory.movement.types.internal') }}</span>
                </label>
                <label class="inline-flex items-center gap-2">
                  <input v-model="movementTypeFilters.disposal" type="checkbox" class="h-4 w-4" />
                  <span>{{ t('beerInventory.movement.types.disposal') }}</span>
                </label>
              </div>
            </div>
            <div class="md:col-span-2 flex items-end">
              <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="resetMovementFilters">
                {{ t('common.reset') }}
              </button>
            </div>
          </form>
        </section>

        <div class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.table.docNo') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.table.movementDate') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.table.docType') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.table.beerName') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.table.category') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.table.packageType') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.table.lotNo') }}</th>
                <th class="px-3 py-2 text-right">{{ t('beerInventory.movement.table.qtyPackages') }}</th>
                <th class="px-3 py-2 text-right">{{ t('beerInventory.movement.table.qtyLiters') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.table.source') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.table.destination') }}</th>
                <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.table.status') }}</th>
                <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="row in filteredMovementRows" :key="row.id" class="hover:bg-gray-50">
                <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.docNo }}</td>
                <td class="px-3 py-2 text-xs text-gray-500">{{ formatDateTime(row.movementAt) }}</td>
                <td class="px-3 py-2 text-gray-700">{{ docTypeLabel(row.docType) }}</td>
                <td class="px-3 py-2 text-gray-900">{{ row.beerName || '—' }}</td>
                <td class="px-3 py-2">{{ categoryLabel(row.categoryId) }}</td>
                <td class="px-3 py-2">{{ row.packageTypeLabel || '—' }}</td>
                <td class="px-3 py-2 font-mono text-xs text-gray-600">{{ row.lotCode || '—' }}</td>
                <td class="px-3 py-2 text-right">{{ formatNumber(row.packageQty) }}</td>
                <td class="px-3 py-2 text-right">{{ formatNumber(row.qtyLiters) }}</td>
                <td class="px-3 py-2">{{ siteLabel(row.sourceSiteId) }}</td>
                <td class="px-3 py-2">{{ siteLabel(row.destSiteId) }}</td>
                <td class="px-3 py-2">{{ statusLabel(row.status) }}</td>
                <td class="px-3 py-2">
                  <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openMovementEdit(row)">
                    {{ t('common.edit') }}
                  </button>
                </td>
              </tr>
              <tr v-if="!movementLoading && filteredMovementRows.length === 0">
                <td colspan="13" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <div v-if="showMovementModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-4xl bg-white rounded-xl shadow-lg border">
          <header class="px-4 py-3 border-b">
            <h3 class="font-semibold">
              {{ editingMovement ? t('beerInventory.movement.form.titleEdit') : t('beerInventory.movement.form.titleNew') }}
            </h3>
          </header>
          <section class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.movement.form.docNo') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="movementForm.docNo" class="w-full h-[40px] border rounded px-3" />
                <p v-if="movementErrors.docNo" class="text-xs text-red-600 mt-1">{{ movementErrors.docNo }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.movement.form.docType') }}<span class="text-red-600">*</span></label>
                <select v-model="movementForm.docType" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in movementDocTypeOptions" :key="option" :value="option">
                    {{ docTypeLabel(option) }}
                  </option>
                </select>
                <p v-if="movementErrors.docType" class="text-xs text-red-600 mt-1">{{ movementErrors.docType }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.movement.form.movementDate') }}<span class="text-red-600">*</span></label>
                <input v-model="movementForm.movementAt" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
                <p v-if="movementErrors.movementAt" class="text-xs text-red-600 mt-1">{{ movementErrors.movementAt }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.movement.form.source') }}<span class="text-red-600">*</span></label>
                <select v-model="movementForm.sourceSiteId" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in siteOptions" :key="`src-${option.value}`" :value="option.value">{{ option.label }}</option>
                </select>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.movement.form.destination') }}<span class="text-red-600">*</span></label>
                <select v-model="movementForm.destSiteId" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in siteOptions" :key="`dest-${option.value}`" :value="option.value">{{ option.label }}</option>
                </select>
              </div>
              <div class="md:col-span-2" v-if="movementErrors.site">
                <p class="text-xs text-red-600">{{ movementErrors.site }}</p>
              </div>
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1">{{ t('beerInventory.movement.form.notes') }}</label>
                <textarea v-model.trim="movementForm.notes" rows="2" class="w-full border rounded px-3 py-2"></textarea>
              </div>
            </div>

            <section class="border border-gray-200 rounded-lg">
              <header class="flex items-center justify-between px-3 py-2 border-b bg-gray-50">
                <h4 class="text-sm font-semibold text-gray-800">{{ t('beerInventory.movement.form.lines') }}</h4>
                <button class="px-2 py-1 text-xs rounded border border-dashed hover:bg-gray-100" type="button" @click="addMovementLine">
                  {{ t('beerInventory.movement.form.addLine') }}
                </button>
              </header>
              <p v-if="movementErrors.lines" class="px-3 pt-2 text-xs text-red-600">{{ movementErrors.lines }}</p>
              <div class="overflow-x-auto">
                <table class="min-w-full text-sm">
                  <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                    <tr>
                      <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.form.package') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.form.lot') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.form.packageType') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.form.packageQty') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('beerInventory.movement.form.qtyLiters') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="(line, index) in movementForm.lines" :key="line.localId" class="hover:bg-gray-50">
                      <td class="px-3 py-2">
                        <select
                          v-model="line.packageId"
                          class="w-full h-[38px] border rounded px-2 bg-white"
                          @change="handlePackageChange(line)"
                        >
                          <option value="">{{ t('common.select') }}</option>
                          <option v-for="option in packageOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                        </select>
                        <p v-if="movementLineErrors[index]?.packageId" class="text-xs text-red-600 mt-1">{{ movementLineErrors[index]?.packageId }}</p>
                      </td>
                      <td class="px-3 py-2 text-xs text-gray-600 font-mono">{{ line.lotCode || '—' }}</td>
                      <td class="px-3 py-2 text-gray-600">{{ line.packageTypeLabel || '—' }}</td>
                      <td class="px-3 py-2">
                        <input v-model.number="line.packageQty" type="number" min="0" step="1" class="w-full h-[38px] border rounded px-2" @input="updateLineVolume(line)" />
                        <p v-if="movementLineErrors[index]?.packageQty" class="text-xs text-red-600 mt-1">{{ movementLineErrors[index]?.packageQty }}</p>
                      </td>
                      <td class="px-3 py-2 text-gray-600">{{ formatNumber(line.qtyLiters) }}</td>
                      <td class="px-3 py-2">
                        <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" type="button" @click="removeMovementLine(index)">
                          {{ t('common.delete') }}
                        </button>
                      </td>
                    </tr>
                    <tr v-if="movementForm.lines.length === 0">
                      <td colspan="6" class="px-3 py-4 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </section>
          </section>
          <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeMovementModal">{{ t('common.cancel') }}</button>
            <button
              class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
              :disabled="movementSaving"
              @click="saveMovement"
            >
              {{ movementSaving ? t('common.saving') : t('common.save') }}
            </button>
          </footer>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
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
  lotCode: string | null
  productionDate: string | null
  qtyPackages: number | null
  qtyLiters: number | null
  siteId: string | null
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

interface MovementRow {
  id: string
  movementId: string
  docNo: string
  docType: string
  movementAt: string | null
  status: string
  sourceSiteId: string | null
  destSiteId: string | null
  notes: string | null
  beerName: string | null
  categoryId: string | null
  packageTypeId: string | null
  packageTypeLabel: string | null
  lotCode: string | null
  packageQty: number | null
  qtyLiters: number | null
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
  packageTypeId: string | null
  packageTypeLabel: string | null
}

const { t, locale } = useI18n()
const pageTitle = computed(() => t('beerInventory.title'))

const tenantId = ref<string | null>(null)
const inventoryLoading = ref(false)
const movementLoading = ref(false)
const movementSaving = ref(false)

const categories = ref<CategoryRow[]>([])
const packageCategories = ref<PackageCategoryRow[]>([])
const uoms = ref<Array<{ id: string; code: string | null }>>([])
const siteOptions = ref<SiteOption[]>([])

const packages = ref<PackageRow[]>([])
const locationByPackage = ref<Map<string, { siteId: string; movementAt: string }>>(new Map())
const locationByLot = ref<Map<string, { siteId: string; movementAt: string }>>(new Map())

const movementRows = ref<MovementRow[]>([])

const movementFilters = reactive({
  beerName: '',
  category: '',
  packageType: '',
  lotNo: '',
  dateFrom: '',
  dateTo: '',
})

const movementTypeFilters = reactive({
  domestic: true,
  foreign: true,
  internal: true,
  disposal: true,
})

const showMovementModal = ref(false)
const editingMovement = ref(false)

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

const movementErrors = reactive<Record<string, string>>({})
const movementLineErrors = ref<Array<Record<string, string>>>([])

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
    const packageTypeLabel = row.package?.package_name || row.package?.package_code || (packageTypeId ? packageCategoryMap.value.get(packageTypeId)?.label : null) || null
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

const packageOptions = computed(() => {
  return Array.from(packageLookup.value.values())
    .sort((a, b) => (a.lotCode || '').localeCompare(b.lotCode || ''))
    .map((item) => ({
      value: item.id,
      label: `${item.lotCode || '—'} · ${item.beerName || '—'} · ${item.packageTypeLabel || '—'}`,
    }))
})

const packageCategoryOptions = computed(() =>
  packageCategories.value.map((row) => ({
    value: row.id,
    label: row.package_name || row.package_code,
  }))
)

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
      lotCode: info?.lotCode ?? null,
      productionDate: row.fill_at ?? null,
      qtyPackages: packageQty,
      qtyLiters,
      siteId: location?.siteId || lotLocation?.siteId || null,
    }
  })
})

const filteredMovementRows = computed(() => {
  const nameFilter = movementFilters.beerName.trim().toLowerCase()
  const lotFilter = movementFilters.lotNo.trim().toLowerCase()
  return movementRows.value.filter((row) => {
    if (nameFilter && !(row.beerName || '').toLowerCase().includes(nameFilter)) return false
    if (movementFilters.category && row.categoryId !== movementFilters.category) return false
    if (movementFilters.packageType && row.packageTypeId !== movementFilters.packageType) return false
    if (lotFilter && !(row.lotCode || '').toLowerCase().includes(lotFilter)) return false
    return true
  })
})

const movementDocTypeOptions = ['sale', 'tax_transfer', 'transfer', 'waste']

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

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
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
  const map = t('beerInventory.movement.docTypeMap') as Record<string, string>
  return map[value] || value
}

function statusLabel(value: string) {
  const map = t('beerInventory.movement.statusMap') as Record<string, string>
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

function selectedDocTypes() {
  const docTypes: string[] = []
  if (movementTypeFilters.domestic) docTypes.push('sale')
  if (movementTypeFilters.foreign) docTypes.push('tax_transfer')
  if (movementTypeFilters.internal) docTypes.push('transfer')
  if (movementTypeFilters.disposal) docTypes.push('waste')
  return docTypes
}

async function fetchMovements() {
  try {
    movementLoading.value = true
    const tenant = await ensureTenant()
    const docTypes = selectedDocTypes()
    if (docTypes.length === 0) {
      movementRows.value = []
      return
    }

    let headerQuery = supabase
      .from('inv_movements')
      .select('id, doc_no, doc_type, movement_at, status, src_site_id, dest_site_id, notes')
      .eq('tenant_id', tenant)
      .in('doc_type', docTypes)
      .order('movement_at', { ascending: false })

    if (movementFilters.dateFrom) headerQuery = headerQuery.gte('movement_at', `${movementFilters.dateFrom}T00:00:00`)
    if (movementFilters.dateTo) headerQuery = headerQuery.lte('movement_at', `${movementFilters.dateTo}T23:59:59`)

    const { data: headers, error: headerError } = await headerQuery
    if (headerError) throw headerError

    const headerList = (headers ?? []) as MovementHeader[]
    const headerMap = new Map(headerList.map((row) => [row.id, row]))
    const movementIds = headerList.map((row) => row.id)

    if (movementIds.length === 0) {
      movementRows.value = []
      return
    }

    const { data: lines, error: lineError } = await supabase
      .from('inv_movement_lines')
      .select('id, movement_id, package_id, lot_id, qty, uom_id, meta')
      .in('movement_id', movementIds)
      .order('line_no', { ascending: true })

    if (lineError) throw lineError

    const lineList = (lines ?? []).filter((row: any) => row.package_id || row.lot_id) as MovementLineRow[]
    const packageIds = lineList.map((row) => row.package_id).filter(Boolean) as string[]
    const lotIds = lineList.map((row) => row.lot_id).filter(Boolean) as string[]

    const packageInfoMap = await loadPackageInfo(packageIds)
    const lotInfoMap = await loadLotInfo(lotIds, packageInfoMap)

    movementRows.value = lineList.map((line) => {
      const header = headerMap.get(line.movement_id)
      const pkgInfo = line.package_id ? packageInfoMap.get(line.package_id) : undefined
      const lotInfo = line.lot_id ? lotInfoMap.get(line.lot_id) : undefined
      const packageQty = toNumber(line.meta?.package_qty)
      const qtyLiters = toNumber(line.qty) ?? (packageQty && pkgInfo?.unitSizeLiters ? packageQty * pkgInfo.unitSizeLiters : null)

      return {
        id: line.id,
        movementId: line.movement_id,
        docNo: header?.doc_no ?? '—',
        docType: header?.doc_type ?? '—',
        movementAt: header?.movement_at ?? null,
        status: header?.status ?? 'open',
        sourceSiteId: header?.src_site_id ?? null,
        destSiteId: header?.dest_site_id ?? null,
        notes: header?.notes ?? null,
        beerName: pkgInfo?.beerName ?? lotInfo?.beerName ?? null,
        categoryId: pkgInfo?.categoryId ?? lotInfo?.categoryId ?? null,
        packageTypeId: pkgInfo?.packageTypeId ?? null,
        packageTypeLabel: pkgInfo?.packageTypeLabel ?? null,
        lotCode: pkgInfo?.lotCode ?? lotInfo?.lotCode ?? null,
        packageQty,
        qtyLiters,
      }
    })
  } catch (err) {
    console.error(err)
    movementRows.value = []
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    movementLoading.value = false
  }
}

async function loadPackageInfo(packageIds: string[]) {
  const infoMap = new Map<string, PackageInfo>()
  if (packageIds.length === 0) return infoMap

  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('pkg_packages')
    .select(
      'id, lot_id, fill_at, package_id, package_size_l, package_qty, lot:lot_id ( id, lot_code, recipe:rcp_recipes ( id, name, category ) ), package:package_id ( id, package_code, package_name, size, uom_id )'
    )
    .eq('tenant_id', tenant)
    .in('id', packageIds)
  if (error) throw error

  ;(data ?? []).forEach((row: any) => {
    const packageRow = row as PackageRow
    const unitSizeLiters = resolvePackageSizeLiters(packageRow)
    infoMap.set(packageRow.id, {
      id: packageRow.id,
      lotId: packageRow.lot_id ?? packageRow.lot?.id ?? null,
      lotCode: packageRow.lot?.lot_code ?? null,
      beerName: packageRow.lot?.recipe?.name ?? null,
      categoryId: packageRow.lot?.recipe?.category ?? null,
      packageTypeId: packageRow.package_id ?? packageRow.package?.id ?? null,
      packageTypeLabel:
        packageRow.package?.package_name ||
        packageRow.package?.package_code ||
        (packageRow.package_id ? packageCategoryMap.value.get(packageRow.package_id)?.label : null) ||
        null,
      unitSizeLiters,
    })
  })

  return infoMap
}

async function loadLotInfo(lotIds: string[], packageInfoMap: Map<string, PackageInfo>) {
  const infoMap = new Map<string, { lotCode: string | null; beerName: string | null; categoryId: string | null }>()
  if (lotIds.length === 0) return infoMap

  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('prd_lots')
    .select('id, lot_code, recipe:recipe_id ( id, name, category )')
    .eq('tenant_id', tenant)
    .in('id', lotIds)
  if (error) throw error

  ;(data ?? []).forEach((row: any) => {
    infoMap.set(row.id, {
      lotCode: row.lot_code ?? null,
      beerName: row.recipe?.name ?? null,
      categoryId: row.recipe?.category ?? null,
    })
  })

  packageInfoMap.forEach((info) => {
    if (info.lotId && !infoMap.has(info.lotId)) {
      infoMap.set(info.lotId, {
        lotCode: info.lotCode,
        beerName: info.beerName,
        categoryId: info.categoryId,
      })
    }
  })

  return infoMap
}

function resetMovementFilters() {
  movementFilters.beerName = ''
  movementFilters.category = ''
  movementFilters.packageType = ''
  movementFilters.lotNo = ''
  movementFilters.dateFrom = ''
  movementFilters.dateTo = ''
  movementTypeFilters.domestic = true
  movementTypeFilters.foreign = true
  movementTypeFilters.internal = true
  movementTypeFilters.disposal = true
}

function createLocalId() {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return crypto.randomUUID()
  }
  return `line-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
}

function resetMovementForm() {
  movementForm.id = ''
  movementForm.docNo = ''
  movementForm.docType = ''
  movementForm.movementAt = formatInputDateTime(new Date())
  movementForm.status = 'open'
  movementForm.sourceSiteId = ''
  movementForm.destSiteId = ''
  movementForm.notes = ''
  movementForm.lines = []
  movementLineErrors.value = []
  Object.keys(movementErrors).forEach((key) => delete movementErrors[key])
}

function openMovementCreate() {
  editingMovement.value = false
  resetMovementForm()
  addMovementLine()
  showMovementModal.value = true
}

async function openMovementEdit(row: MovementRow) {
  editingMovement.value = true
  resetMovementForm()
  movementForm.id = row.movementId
  movementForm.docNo = row.docNo
  movementForm.docType = row.docType
  movementForm.movementAt = row.movementAt ? formatInputDateTime(new Date(row.movementAt)) : formatInputDateTime(new Date())
  movementForm.status = row.status
  movementForm.sourceSiteId = row.sourceSiteId ?? ''
  movementForm.destSiteId = row.destSiteId ?? ''
  movementForm.notes = row.notes ?? ''

  await loadMovementLines(row.movementId)
  showMovementModal.value = true
}

function closeMovementModal() {
  showMovementModal.value = false
}

async function loadMovementLines(movementId: string) {
  const { data, error } = await supabase
    .from('inv_movement_lines')
    .select('id, package_id, lot_id, qty, uom_id, meta')
    .eq('movement_id', movementId)
    .order('line_no', { ascending: true })
  if (error) throw error

  movementForm.lines = (data ?? []).map((row: any) => {
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
      packageTypeId: pkgInfo?.packageTypeId ?? null,
      packageTypeLabel: pkgInfo?.packageTypeLabel ?? null,
    }
  })

  if (movementForm.lines.length === 0) addMovementLine()
  movementLineErrors.value = movementForm.lines.map(() => ({}))
}

function addMovementLine() {
  movementForm.lines.push({
    localId: createLocalId(),
    packageId: '',
    packageQty: null,
    qtyLiters: null,
    lotId: null,
    lotCode: null,
    packageTypeId: null,
    packageTypeLabel: null,
  })
  movementLineErrors.value.push({})
}

function removeMovementLine(index: number) {
  movementForm.lines.splice(index, 1)
  movementLineErrors.value.splice(index, 1)
}

function handlePackageChange(line: MovementLineForm) {
  const info = line.packageId ? packageLookup.value.get(line.packageId) : undefined
  line.lotId = info?.lotId ?? null
  line.lotCode = info?.lotCode ?? null
  line.packageTypeId = info?.packageTypeId ?? null
  line.packageTypeLabel = info?.packageTypeLabel ?? null
  updateLineVolume(line)
}

function updateLineVolume(line: MovementLineForm) {
  const info = line.packageId ? packageLookup.value.get(line.packageId) : undefined
  const unitSize = info?.unitSizeLiters
  if (!unitSize || !line.packageQty) {
    line.qtyLiters = null
    return
  }
  line.qtyLiters = line.packageQty * unitSize
}

function validateMovementForm() {
  Object.keys(movementErrors).forEach((key) => delete movementErrors[key])
  movementLineErrors.value = movementForm.lines.map(() => ({}))

  if (!movementForm.docNo) movementErrors.docNo = t('beerInventory.movement.errors.docNoRequired')
  if (!movementForm.docType) movementErrors.docType = t('beerInventory.movement.errors.docTypeRequired')
  if (!movementForm.movementAt) movementErrors.movementAt = t('beerInventory.movement.errors.movementDateRequired')
  if (!movementForm.sourceSiteId || !movementForm.destSiteId) movementErrors.site = t('beerInventory.movement.errors.siteRequired')

  if (movementForm.lines.length === 0) {
    movementErrors.lines = t('beerInventory.movement.errors.linesRequired')
  }

  movementForm.lines.forEach((line, index) => {
    const entry: Record<string, string> = {}
    if (!line.packageId) entry.packageId = t('beerInventory.movement.errors.packageRequired')
    if (!line.packageQty || line.packageQty <= 0) entry.packageQty = t('beerInventory.movement.errors.packageQtyRequired')
    const info = line.packageId ? packageLookup.value.get(line.packageId) : undefined
    if (!info?.unitSizeLiters) entry.packageQty = t('beerInventory.movement.errors.packageSizeRequired')
    movementLineErrors.value[index] = entry
  })

  movementLineErrors.value = [...movementLineErrors.value]

  return Object.keys(movementErrors).length === 0 && movementLineErrors.value.every((entry) => Object.keys(entry).length === 0)
}

async function saveMovement() {
  if (!validateMovementForm()) return
  try {
    movementSaving.value = true
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
    if (editingMovement.value && movementId) {
      const { error } = await supabase.from('inv_movements').update(payload).eq('id', movementId)
      if (error) throw error
      await supabase.from('inv_movement_lines').delete().eq('movement_id', movementId)
    } else {
      const { data, error } = await supabase.from('inv_movements').insert(payload).select('id').single()
      if (error || !data) throw error || new Error('Insert failed')
      movementId = data.id
    }

    const linePayload = movementForm.lines.map((line, index) => {
      const info = line.packageId ? packageLookup.value.get(line.packageId) : undefined
      return {
        tenant_id: tenant,
        movement_id: movementId,
        line_no: index + 1,
        package_id: line.packageId || null,
        lot_id: info?.lotId ?? line.lotId ?? null,
        qty: line.qtyLiters ?? 0,
        uom_id: findLitersUomId(),
        meta: line.packageQty ? { package_qty: line.packageQty } : null,
      }
    })

    if (linePayload.length > 0) {
      const { error: lineError } = await supabase.from('inv_movement_lines').insert(linePayload)
      if (lineError) throw lineError
    }

    closeMovementModal()
    await fetchMovements()
    await loadPackageInventory()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    movementSaving.value = false
  }
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

function findLitersUomId() {
  const match = uoms.value.find((row) => row.code?.toLowerCase() === 'l')
  return match?.id ?? uoms.value[0]?.id ?? null
}

async function refreshAll() {
  await Promise.all([loadPackageInventory(), fetchMovements()])
}

watch(
  () => ({
    dateFrom: movementFilters.dateFrom,
    dateTo: movementFilters.dateTo,
    domestic: movementTypeFilters.domestic,
    foreign: movementTypeFilters.foreign,
    internal: movementTypeFilters.internal,
    disposal: movementTypeFilters.disposal,
  }),
  async () => {
    await fetchMovements()
  }
)

watch(locale, () => {
  movementRows.value = [...movementRows.value]
})

onMounted(async () => {
  try {
    await ensureTenant()
    await Promise.all([loadSites(), loadCategories(), loadPackageCategories(), loadUoms()])
    await loadPackageInventory()
    await fetchMovements()
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
