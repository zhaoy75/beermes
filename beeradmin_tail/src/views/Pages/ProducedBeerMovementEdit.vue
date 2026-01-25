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
            <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.edit.form.movementType') }}<span class="text-red-600">*</span></label>
            <select v-model="movementForm.movementType" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.select') }}</option>
              <option v-for="option in movementTypeOptions" :key="option" :value="option">
                {{ movementTypeLabel(option) }}
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
          <div class="w-full md:w-auto flex flex-col md:flex-row md:items-end gap-3">
            <div class="w-full md:w-56">
              <label class="block text-sm text-gray-600 mb-1">{{ t('site.filters.siteType') }}</label>
              <select v-model="siteTypeFilters.source" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.all') }}</option>
                <option v-for="option in siteTypeOptions" :key="`src-type-${option.value}`" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
            <div class="w-full md:w-64">
              <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.edit.form.sourceSite') }}<span class="text-red-600">*</span></label>
              <select v-model="movementForm.sourceSiteId" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in filteredSourceSites" :key="`src-${option.value}`" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
              <p v-if="errors.site" class="text-xs text-red-600 mt-1">{{ errors.site }}</p>
            </div>
          </div>
        </header>

        <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
          <article
            v-for="row in sourceInventoryRows"
            :key="row.id"
            class="border rounded-lg p-3 shadow-sm cursor-pointer transition"
            :class="selectedInventory?.id === row.id ? 'border-blue-500 ring-1 ring-blue-200 bg-blue-50' : 'border-gray-200 hover:border-gray-300'"
            @click="selectSourceInventory(row)"
            @dblclick="openMoveDialog(row)"
          >
            <div class="flex items-start justify-between gap-2">
              <div>
                <p class="text-xs uppercase tracking-wide text-gray-400">{{ t('producedBeer.inventory.table.beerName') }}</p>
                <p class="font-semibold text-gray-900">{{ row.beerName || '—' }}</p>
              </div>
              <span class="text-xs px-2 py-1 rounded-full border text-gray-500">{{ row.packageTypeLabel || '—' }}</span>
            </div>
            <dl class="mt-3 space-y-1 text-xs text-gray-600">
              <div class="flex items-center justify-between">
                <dt>{{ t('producedBeer.inventory.table.batchNo') }}</dt>
                <dd class="font-mono text-xs">{{ row.batchCode || '—' }}</dd>
              </div>
              <div class="flex items-center justify-between">
                <dt>{{ t('producedBeer.inventory.table.category') }}</dt>
                <dd>{{ categoryLabel(row.categoryId) }}</dd>
              </div>
              <div class="flex items-center justify-between">
                <dt>{{ t('producedBeer.inventory.table.productionDate') }}</dt>
                <dd class="text-gray-500">{{ formatDate(row.productionDate) }}</dd>
              </div>
              <div class="flex items-center justify-between">
                <dt>{{ t('producedBeer.inventory.table.qtyLiters') }}</dt>
                <dd class="font-medium text-gray-900">{{ formatNumber(row.qtyLiters) }}</dd>
              </div>
              <div class="flex items-center justify-between">
                <dt>{{ t('producedBeer.inventory.table.qtyPackages') }}</dt>
                <dd class="font-medium text-gray-900">{{ formatNumber(row.qtyPackages) }}</dd>
              </div>
            </dl>
          </article>
          <div v-if="!inventoryLoading && sourceInventoryRows.length === 0" class="col-span-full py-8 text-center text-gray-500">
            {{ t('common.noData') }}
          </div>
        </div>
      </section>

      <section class="flex flex-wrap items-center justify-center gap-3">
        <button
          class="px-4 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
          :disabled="!movementForm.sourceSiteId"
          @click="handleMoveToDestination"
        >
          {{ t('producedBeer.edit.actions.moveToDestination') }}
        </button>
        <button
          class="px-4 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
          :disabled="movementForm.lines.length === 0"
          @click="handleMoveToSource"
        >
          {{ t('producedBeer.edit.actions.moveToSource') }}
        </button>
      </section>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <header class="flex items-center justify-between">
          <div>
            <h2 class="text-lg font-semibold">{{ t('producedBeer.edit.destination.title') }}</h2>
            <p class="text-sm text-gray-500">{{ t('producedBeer.edit.destination.subtitle') }}</p>
          </div>
          <div class="w-full md:w-auto flex flex-col md:flex-row md:items-end gap-3">
            <div class="w-full md:w-56">
              <label class="block text-sm text-gray-600 mb-1">{{ t('site.filters.siteType') }}</label>
              <select v-model="siteTypeFilters.destination" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.all') }}</option>
                <option v-for="option in siteTypeOptions" :key="`dest-type-${option.value}`" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
            <div class="w-full md:w-64">
              <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.edit.form.destinationSite') }}<span class="text-red-600">*</span></label>
              <select v-model="movementForm.destSiteId" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in filteredDestinationSites" :key="`dest-${option.value}`" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
              <p v-if="errors.site" class="text-xs text-red-600 mt-1">{{ errors.site }}</p>
            </div>
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
                  <th class="px-3 py-2 text-left">{{ t('producedBeer.edit.lines.columns.batch') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('producedBeer.edit.lines.columns.qtyPackages') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('producedBeer.edit.lines.columns.qtyLiters') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr
                  v-for="(line, index) in movementForm.lines"
                  :key="line.localId"
                  class="cursor-pointer"
                  :class="line.localId === selectedLineId ? 'bg-blue-50' : 'hover:bg-gray-50'"
                  @click="selectMovementLine(line)"
                >
                  <td class="px-3 py-2 text-gray-900">{{ line.beerName || '—' }}</td>
                  <td class="px-3 py-2 text-gray-600">{{ categoryLabel(line.categoryId) }}</td>
                  <td class="px-3 py-2 text-gray-600">{{ line.packageTypeLabel || '—' }}</td>
                  <td class="px-3 py-2 font-mono text-xs text-gray-500">{{ line.batchCode || '—' }}</td>
                  <td class="px-3 py-2 text-right">{{ formatNumber(line.packageQty) }}</td>
                  <td class="px-3 py-2 text-right">{{ formatNumber(line.qtyLiters) }}</td>
                  <td class="px-3 py-2">
                    <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click.stop="removeMovementLine(index)">
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
              <p class="text-xs text-gray-500">{{ selectedInventory?.batchCode || '—' }}</p>
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

      <div v-if="showManualDialog" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-lg bg-white rounded-xl shadow-lg border">
          <header class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('producedBeer.edit.manualDialog.title') }}</h3>
          </header>
          <section class="p-4 space-y-3">
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.edit.manualDialog.packageSelect') }}</label>
              <select v-model="manualMoveForm.packageId" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in manualInventoryOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
            <div v-if="manualSelectedInventory" class="rounded-lg border border-gray-200 bg-gray-50 p-3 text-xs text-gray-600">
              <p class="font-medium text-gray-900">{{ manualSelectedInventory.beerName || '—' }}</p>
              <p>{{ categoryLabel(manualSelectedInventory.categoryId) }}</p>
              <p>{{ manualSelectedInventory.packageTypeLabel || '—' }}</p>
              <p class="font-mono text-xs text-gray-500">{{ manualSelectedInventory.batchCode || '—' }}</p>
              <p class="text-xs text-gray-500">{{ formatDate(manualSelectedInventory.productionDate) }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.edit.moveDialog.packageQty') }}</label>
              <input
                v-model.number="manualMoveForm.packageQty"
                type="number"
                min="0"
                step="1"
                class="w-full h-[40px] border rounded px-3"
                :max="manualSelectedInventory?.qtyPackages ?? undefined"
              />
              <p v-if="manualDialogError" class="text-xs text-red-600 mt-1">{{ manualDialogError }}</p>
            </div>
            <div class="text-xs text-gray-500">
              {{ t('producedBeer.edit.moveDialog.qtyLiters') }}: {{ formatNumber(manualCalculatedLiters) }}
            </div>
          </section>
          <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeManualDialog">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="confirmManualMoveLine">
              {{ t('producedBeer.edit.manualDialog.confirm') }}
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
  siteTypeId: string | null
}

interface SiteTypeOption {
  id: string
  code: string
  name: string | null
  flags?: Record<string, any> | null
}

interface PackageCategoryRow {
  id: string
  package_code: string
  package_name: string | null
  size: number | null
  uom_id: string | null
}

interface InventoryRow {
  id: string
  packageId: string | null
  beerName: string | null
  categoryId: string | null
  packageTypeLabel: string | null
  packageTypeId: string | null
  batchCode: string | null
  productionDate: string | null
  qtyPackages: number | null
  qtyLiters: number | null
  siteId: string | null
  unitSizeLiters: number | null
  batchId: string | null
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
  meta?: Record<string, any> | null
}

interface MovementLineRow {
  id: string
  movement_id: string
  package_id: string | null
  batch_id: string | null
  qty: number | null
  uom_id: string | null
  meta?: Record<string, any> | null
}

interface PackageInfo {
  id: string
  batchId: string | null
  batchCode: string | null
  beerName: string | null
  packageTypeId: string | null
  packageTypeLabel: string | null
  unitSizeLiters: number | null
  productionDate: string | null
}

interface MovementLineForm {
  localId: string
  id?: string
  packageId: string
  packageQty: number | null
  qtyLiters: number | null
  batchId: string | null
  batchCode: string | null
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
const siteTypes = ref<SiteTypeOption[]>([])
const inventoryRows = ref<InventoryRow[]>([])

const movementForm = reactive({
  id: '',
  docNo: '',
  movementType: '',
  movementAt: '',
  status: 'open',
  sourceSiteId: '',
  destSiteId: '',
  notes: '',
  lines: [] as MovementLineForm[],
})

const siteTypeFilters = reactive({
  source: '',
  destination: '',
})

const errors = reactive<Record<string, string>>({})

const showMoveDialog = ref(false)
const selectedInventory = ref<InventoryRow | null>(null)
const moveQuantity = ref<number | null>(null)
const moveDialogError = ref('')
const selectedLineId = ref<string | null>(null)
const showManualDialog = ref(false)
const manualMoveForm = reactive({
  packageId: '',
  packageQty: null as number | null,
})
const manualDialogError = ref('')

const movementTypeOptions = ['taxed', 'notax', 'returnNotax', 'wasteNotax', 'transferNotax'] as const

const editing = computed(() => Boolean(movementForm.id))

const siteMap = computed(() => {
  const map = new Map<string, SiteOption>()
  siteOptions.value.forEach((item) => map.set(item.value, item))
  return map
})

const siteTypeOptions = computed(() => {
  return siteTypes.value.map((row) => ({
    value: row.id,
    label: resolveSiteTypeLabel(row),
  }))
})

const filteredSourceSites = computed(() => {
  if (!siteTypeFilters.source) return siteOptions.value
  return siteOptions.value.filter((option) => option.siteTypeId === siteTypeFilters.source)
})

const filteredDestinationSites = computed(() => {
  if (!siteTypeFilters.destination) return siteOptions.value
  return siteOptions.value.filter((option) => option.siteTypeId === siteTypeFilters.destination)
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

const sourceInventoryRows = computed(() => {
  if (!movementForm.sourceSiteId) return []
  return inventoryRows.value.filter((row) => row.siteId === movementForm.sourceSiteId)
})

const calculatedMoveLiters = computed(() => {
  if (!selectedInventory.value || !moveQuantity.value) return null
  return selectedInventory.value.unitSizeLiters ? moveQuantity.value * selectedInventory.value.unitSizeLiters : null
})

const manualSelectedInventory = computed(() => {
  if (!manualMoveForm.packageId) return null
  return inventoryRows.value.find((row) => row.id === manualMoveForm.packageId) ?? null
})

const manualCalculatedLiters = computed(() => {
  if (!manualSelectedInventory.value || !manualMoveForm.packageQty) return null
  return manualSelectedInventory.value.unitSizeLiters
    ? manualMoveForm.packageQty * manualSelectedInventory.value.unitSizeLiters
    : null
})

const manualInventoryOptions = computed(() => {
  return inventoryRows.value.map((row) => ({
    value: row.id,
    label: [row.beerName || '—', row.batchCode || '—', row.packageTypeLabel || '—'].join(' | '),
  }))
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

function resolveBatchLabel(meta: Record<string, any> | null | undefined) {
  const label = meta?.label
  if (typeof label !== 'string') return null
  const trimmed = label.trim()
  return trimmed.length ? trimmed : null
}

function resolveSiteTypeLabel(row: SiteTypeOption) {
  const flags = row.flags as Record<string, any> | null | undefined
  const jaLabel = flags && typeof flags.ja === 'string' ? flags.ja.trim() : ''
  if (jaLabel) return `${row.code} — ${jaLabel}`
  if (row.name) return `${row.code} — ${row.name}`
  return row.code
}

function siteLabel(siteId: string | null | undefined) {
  if (!siteId) return '—'
  return siteMap.value.get(siteId)?.label ?? '—'
}

function movementTypeLabel(value: string) {
  switch (value) {
    case 'taxed':
      return t('producedBeer.movement.types.taxed')
    case 'notax':
      return t('producedBeer.movement.types.notax')
    case 'returnNotax':
      return t('producedBeer.movement.types.returnNotax')
    case 'wasteNotax':
      return t('producedBeer.movement.types.wasteNotax')
    case 'transferNotax':
      return t('producedBeer.movement.types.transferNotax')
    default:
      return value
  }
}

function resolveMovementDocType(movementType: string) {
  switch (movementType) {
    case 'taxed':
      return { docType: 'sale', taxType: 'tax' }
    case 'notax':
      return { docType: 'sale', taxType: 'notax' }
    case 'returnNotax':
      return { docType: 'return', taxType: 'notax' }
    case 'wasteNotax':
      return { docType: 'waste', taxType: 'notax' }
    case 'transferNotax':
      return { docType: 'transfer', taxType: 'notax' }
    default:
      return { docType: '', taxType: '' }
  }
}

function resolveMovementType(docType: string, taxType: string | null | undefined) {
  if (docType === 'sale' && taxType === 'tax') return 'taxed'
  if (docType === 'sale' && taxType === 'notax') return 'notax'
  if (docType === 'return' && taxType === 'notax') return 'returnNotax'
  if (docType === 'waste' && taxType === 'notax') return 'wasteNotax'
  if (docType === 'transfer' && taxType === 'notax') return 'transferNotax'
  return ''
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
    .select('id, code, name, site_type_id')
    .eq('tenant_id', tenant)
    .order('code', { ascending: true })
  if (error) throw error
  siteOptions.value = (data ?? []).map((row) => ({
    value: row.id,
    label: `${row.code} — ${row.name}`,
    siteTypeId: row.site_type_id ?? null,
  }))
}

async function loadSiteTypes() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_site_types')
    .select('id, code, name, flags')
    .eq('tenant_id', tenant)
    .order('code', { ascending: true })
  if (error) throw error
  siteTypes.value = data ?? []
}

async function loadInventoryFromMovements() {
  try {
    inventoryLoading.value = true
    const tenant = await ensureTenant()
    const { data, error } = await supabase
      .from('inv_movement_lines')
      .select(
        'id, movement_id, package_id, batch_id, qty, uom_id, meta, movement:movement_id ( movement_at, status, src_site_id, dest_site_id, doc_type )'
      )
      .eq('tenant_id', tenant)
      .or('package_id.not.is.null,batch_id.not.is.null')
      .order('movement_id', { ascending: true })
    if (error) throw error

    const lines = (data ?? []).filter((row: any) => row.movement?.status !== 'void')
    if (!lines.length) {
      inventoryRows.value = []
      return
    }

    const packageIds = Array.from(new Set(lines.map((row: any) => row.package_id).filter(Boolean)))
    const batchIds = Array.from(new Set(lines.map((row: any) => row.batch_id).filter(Boolean)))

    const packageInfoMap = await loadPackageInfo(packageIds)
    const batchInfoMap = await loadBatchInfo(batchIds)

    type InventoryAccumulator = {
      key: string
      siteId: string
      packageId: string | null
      batchId: string | null
      beerName: string | null
      categoryId: string | null
      packageTypeLabel: string | null
      packageTypeId: string | null
      batchCode: string | null
      productionDate: string | null
      qtyPackages: number
      qtyLiters: number
      unitSizeLiters: number | null
    }

    const accum = new Map<string, InventoryAccumulator>()

    const applyDelta = (siteId: string | null, delta: number, row: any) => {
      if (!siteId) return
      const pkgInfo = row.package_id ? packageInfoMap.get(row.package_id) : undefined
      const batchInfo = row.batch_id ? batchInfoMap.get(row.batch_id) : undefined
      const unitSizeLiters = pkgInfo?.unitSizeLiters ?? null
      const qtyLiters = toNumber(row.qty) ?? 0
      const packageQty = toNumber(row.meta?.package_qty)
      const derivedPackages = packageQty != null
        ? packageQty
        : (unitSizeLiters && qtyLiters ? qtyLiters / unitSizeLiters : 0)

      const key = `${siteId}__${row.package_id ?? ''}__${row.batch_id ?? ''}`
      if (!accum.has(key)) {
        accum.set(key, {
          key,
          siteId,
          packageId: row.package_id ?? null,
          batchId: row.batch_id ?? pkgInfo?.batchId ?? null,
          beerName: pkgInfo?.beerName ?? batchInfo?.beerName ?? null,
          categoryId: null,
          packageTypeLabel: pkgInfo?.packageTypeLabel ?? null,
          packageTypeId: pkgInfo?.packageTypeId ?? null,
          batchCode: pkgInfo?.batchCode ?? batchInfo?.batchCode ?? null,
          productionDate: pkgInfo?.productionDate ?? row.movement?.movement_at ?? null,
          qtyPackages: 0,
          qtyLiters: 0,
          unitSizeLiters,
        })
      }

      const entry = accum.get(key)
      if (!entry) return
      entry.qtyLiters += qtyLiters * delta
      entry.qtyPackages += derivedPackages * delta
    }

    lines.forEach((row: any) => {
      const movement = row.movement ?? null
      if (!movement) return
      applyDelta(movement.dest_site_id ?? null, 1, row)
      applyDelta(movement.src_site_id ?? null, -1, row)
    })

    inventoryRows.value = Array.from(accum.values())
      .filter((row) => (row.qtyLiters > 0 || row.qtyPackages > 0) && row.packageId)
      .map((row) => ({
        id: row.key,
        packageId: row.packageId,
        beerName: row.beerName,
        categoryId: row.categoryId,
        packageTypeLabel: row.packageTypeLabel,
        packageTypeId: row.packageTypeId,
        batchCode: row.batchCode,
        productionDate: row.productionDate,
        qtyPackages: row.qtyPackages > 0 ? row.qtyPackages : null,
        qtyLiters: row.qtyLiters > 0 ? row.qtyLiters : null,
        siteId: row.siteId,
        unitSizeLiters: row.unitSizeLiters,
        batchId: row.batchId,
      }))
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    inventoryLoading.value = false
  }
}

async function loadPackageInfo(packageIds: string[]) {
  const infoMap = new Map<string, PackageInfo>()
  if (packageIds.length === 0) return infoMap
  const uniqueIds = Array.from(new Set(packageIds))
  uniqueIds.forEach((id) => {
    const category = packageCategoryMap.value.get(id)
    const uomCode = category?.uomId ? uomMap.value.get(category.uomId) : null
    const unitSizeLiters = category?.size != null ? convertToLiters(category.size, uomCode) : null
    infoMap.set(id, {
      id,
      batchId: null,
      batchCode: null,
      beerName: null,
      packageTypeId: id,
      packageTypeLabel: category?.label ?? null,
      unitSizeLiters,
      productionDate: null,
    })
  })
  return infoMap
}

async function loadBatchInfo(batchIds: string[]) {
  const infoMap = new Map<string, { batchCode: string | null; beerName: string | null }>()
  if (batchIds.length === 0) return infoMap

  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mes_batches')
    .select('id, batch_code, meta')
    .eq('tenant_id', tenant)
    .in('id', batchIds)
  if (error) throw error

  ;(data ?? []).forEach((row: any) => {
    infoMap.set(row.id, {
      batchCode: row.batch_code ?? null,
      beerName: resolveBatchLabel(row.meta) ?? null,
    })
  })
  return infoMap
}

function selectSourceInventory(row: InventoryRow) {
  selectedInventory.value = row
}

function handleMoveToDestination() {
  if (!movementForm.sourceSiteId) {
    toast.error(t('producedBeer.edit.errors.sourceRequired'))
    return
  }
  if (sourceInventoryRows.value.length === 0) {
    openManualDialog()
    return
  }
  if (!selectedInventory.value) {
    toast.error(t('producedBeer.edit.errors.selectSourceItem'))
    return
  }
  if (selectedInventory.value.siteId !== movementForm.sourceSiteId) {
    toast.error(t('producedBeer.edit.errors.sourceRequired'))
    return
  }
  openMoveDialog(selectedInventory.value)
}

function handleMoveToSource() {
  if (!selectedLineId.value) {
    toast.error(t('producedBeer.edit.errors.selectLineRequired'))
    return
  }
  const index = movementForm.lines.findIndex((line) => line.localId === selectedLineId.value)
  if (index === -1) {
    selectedLineId.value = null
    return
  }
  movementForm.lines.splice(index, 1)
  selectedLineId.value = null
}

function selectMovementLine(line: MovementLineForm) {
  selectedLineId.value = line.localId
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

function addMovementLineFromInventory(row: InventoryRow, qty: number) {
  const packageId = row.packageId
  if (!packageId) {
    toast.error(t('producedBeer.edit.errors.manualPackageRequired'))
    return
  }
  const existing = movementForm.lines.find((line) => line.packageId === packageId)
  const qtyLiters = row.unitSizeLiters ? qty * row.unitSizeLiters : null

  if (existing) {
    existing.packageQty = (existing.packageQty ?? 0) + qty
    existing.qtyLiters = (existing.qtyLiters ?? 0) + (qtyLiters ?? 0)
  } else {
    movementForm.lines.push({
      localId: createLocalId(),
      packageId,
      packageQty: qty,
      qtyLiters,
      batchId: row.batchId ?? null,
      batchCode: row.batchCode ?? null,
      beerName: row.beerName ?? null,
      categoryId: row.categoryId ?? null,
      packageTypeId: row.packageTypeId ?? null,
      packageTypeLabel: row.packageTypeLabel ?? null,
      unitSizeLiters: row.unitSizeLiters ?? null,
    })
  }
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

  addMovementLineFromInventory(selectedInventory.value, moveQuantity.value)
  closeMoveDialog()
}

function openManualDialog() {
  manualMoveForm.packageId = ''
  manualMoveForm.packageQty = null
  manualDialogError.value = ''
  showManualDialog.value = true
}

function closeManualDialog() {
  showManualDialog.value = false
  manualMoveForm.packageId = ''
  manualMoveForm.packageQty = null
  manualDialogError.value = ''
}

function confirmManualMoveLine() {
  if (!manualMoveForm.packageId) {
    manualDialogError.value = t('producedBeer.edit.errors.manualPackageRequired')
    return
  }
  const selected = manualSelectedInventory.value
  if (!selected) {
    manualDialogError.value = t('producedBeer.edit.errors.manualPackageRequired')
    return
  }
  if (!manualMoveForm.packageQty || manualMoveForm.packageQty <= 0) {
    manualDialogError.value = t('producedBeer.edit.errors.moveQtyRequired')
    return
  }
  const maxQty = selected.qtyPackages ?? null
  if (maxQty != null && manualMoveForm.packageQty > maxQty) {
    manualDialogError.value = t('producedBeer.edit.errors.moveQtyExceed')
    return
  }

  addMovementLineFromInventory(selected, manualMoveForm.packageQty)
  closeManualDialog()
}

function removeMovementLine(index: number) {
  const [removed] = movementForm.lines.splice(index, 1)
  if (removed?.localId && selectedLineId.value === removed.localId) {
    selectedLineId.value = null
  }
}

function validateForm() {
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!movementForm.docNo) errors.docNo = t('producedBeer.edit.errors.docNoRequired')
  if (!movementForm.movementType) errors.docType = t('producedBeer.edit.errors.docTypeRequired')
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
    const { docType, taxType } = resolveMovementDocType(movementForm.movementType)
    if (!docType) throw new Error('Movement type not resolved')
    const payload = {
      tenant_id: tenant,
      doc_no: movementForm.docNo.trim(),
      doc_type: docType,
      movement_at: new Date(movementForm.movementAt).toISOString(),
      status: movementForm.status,
      src_site_id: movementForm.sourceSiteId || null,
      dest_site_id: movementForm.destSiteId || null,
      meta: { tax_type: taxType },
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
      batch_id: line.batchId ?? null,
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
  if (typeof window !== 'undefined' && window.history.length > 1) {
    router.back()
    return
  }
  router.push({ path: '/producedBeer' })
}

async function loadMovement(movementId: string) {
  const { data, error } = await supabase
    .from('inv_movements')
    .select('id, doc_no, doc_type, movement_at, status, src_site_id, dest_site_id, notes, meta')
    .eq('id', movementId)
    .single()
  if (error) throw error
  const header = data as MovementHeader
  movementForm.id = header.id
  movementForm.docNo = header.doc_no
  movementForm.movementType = resolveMovementType(header.doc_type, header.meta?.tax_type)
  movementForm.movementAt = header.movement_at ? formatInputDateTime(new Date(header.movement_at)) : formatInputDateTime(new Date())
  movementForm.status = header.status
  movementForm.sourceSiteId = header.src_site_id ?? ''
  movementForm.destSiteId = header.dest_site_id ?? ''
  movementForm.notes = header.notes ?? ''

  const { data: lines, error: lineError } = await supabase
    .from('inv_movement_lines')
    .select('id, movement_id, package_id, batch_id, qty, uom_id, meta')
    .eq('movement_id', movementId)
    .order('line_no', { ascending: true })
  if (lineError) throw lineError

  const lineList = lines ?? []
  const packageIds = lineList.map((row: any) => row.package_id).filter(Boolean) as string[]
  const batchIds = lineList.map((row: any) => row.batch_id).filter(Boolean) as string[]
  const packageInfoMap = await loadPackageInfo(packageIds)
  const batchInfoMap = await loadBatchInfo(batchIds)

  movementForm.lines = lineList.map((row: any) => {
    const pkgInfo = row.package_id ? packageInfoMap.get(row.package_id) : undefined
    const batchInfo = row.batch_id ? batchInfoMap.get(row.batch_id) : undefined
    const unitSize = pkgInfo?.unitSizeLiters ?? null
    const qtyLiters = toNumber(row.qty)
    const packageQty = toNumber(row.meta?.package_qty) ?? (unitSize && qtyLiters ? qtyLiters / unitSize : null)
    return {
      localId: createLocalId(),
      id: row.id,
      packageId: row.package_id ?? '',
      packageQty,
      qtyLiters: qtyLiters ?? (packageQty && unitSize ? packageQty * unitSize : null),
      batchId: row.batch_id ?? pkgInfo?.batchId ?? null,
      batchCode: pkgInfo?.batchCode ?? batchInfo?.batchCode ?? null,
      beerName: pkgInfo?.beerName ?? batchInfo?.beerName ?? null,
      categoryId: null,
      packageTypeId: pkgInfo?.packageTypeId ?? null,
      packageTypeLabel: pkgInfo?.packageTypeLabel ?? null,
      unitSizeLiters: unitSize ?? null,
    }
  })
  selectedLineId.value = null
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

watch(
  () => movementForm.sourceSiteId,
  () => {
    selectedInventory.value = null
    moveQuantity.value = null
    showMoveDialog.value = false
  }
)

watch(
  () => siteTypeFilters.source,
  () => {
    if (!movementForm.sourceSiteId) return
    const exists = filteredSourceSites.value.some((option) => option.value === movementForm.sourceSiteId)
    if (!exists) movementForm.sourceSiteId = ''
  }
)

watch(
  () => siteTypeFilters.destination,
  () => {
    if (!movementForm.destSiteId) return
    const exists = filteredDestinationSites.value.some((option) => option.value === movementForm.destSiteId)
    if (!exists) movementForm.destSiteId = ''
  }
)

watch(sourceInventoryRows, (rows) => {
  if (selectedInventory.value && !rows.some((row) => row.id === selectedInventory.value?.id)) {
    selectedInventory.value = null
  }
})

onMounted(async () => {
  try {
    await ensureTenant()
    await Promise.all([loadSites(), loadSiteTypes(), loadCategories(), loadPackageCategories(), loadUoms()])
    await loadInventoryFromMovements()
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
