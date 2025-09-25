<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto space-y-4">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('rawMaterialReceipts.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('rawMaterialReceipts.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">
            {{ t('common.new') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="fetchReceipts"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white">
        <form class="grid grid-cols-1 md:grid-cols-4 gap-3" @submit.prevent>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('rawMaterialReceipts.filters.docNo') }}</label>
            <input v-model.trim="filters.docNo" type="search" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('rawMaterialReceipts.filters.dateFrom') }}</label>
            <input v-model="filters.dateFrom" type="date" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('rawMaterialReceipts.filters.dateTo') }}</label>
            <input v-model="filters.dateTo" type="date" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div class="flex items-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="resetFilters">{{ t('common.reset') }}</button>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('rawMaterialReceipts.filters.supplier') }}</label>
            <select v-model="filters.supplier" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in siteOptions" :key="`supplier-${option.value}`" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('rawMaterialReceipts.filters.warehouse') }}</label>
            <select v-model="filters.warehouse" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in warehouseOptions" :key="`warehouse-${option.value}`" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('rawMaterialReceipts.filters.status') }}</label>
            <select v-model="filters.status" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in statusOptions" :key="option" :value="option">{{ statusLabel(option) }}</option>
            </select>
          </div>
        </form>
      </section>

      <section class="hidden md:block overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200 text-sm">
          <thead class="bg-gray-50 text-xs uppercase text-gray-600">
            <tr>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('doc_no')">{{ t('rawMaterialReceipts.table.docNo') }}<span v-if="sortKey === 'doc_no'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('movement_at')">{{ t('rawMaterialReceipts.table.movementDate') }}<span v-if="sortKey === 'movement_at'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left">{{ t('rawMaterialReceipts.table.supplier') }}</th>
              <th class="px-3 py-2 text-left">{{ t('rawMaterialReceipts.table.warehouse') }}</th>
              <th class="px-3 py-2 text-left">{{ t('rawMaterialReceipts.table.status') }}</th>
              <th class="px-3 py-2 text-left">{{ t('rawMaterialReceipts.table.totalQty') }}</th>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('created_at')">{{ t('labels.createdAt') }}<span v-if="sortKey === 'created_at'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in sortedRows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.doc_no }}</td>
              <td class="px-3 py-2 text-gray-700">{{ formatDateTime(row.movement_at) }}</td>
              <td class="px-3 py-2">{{ row.supplier_label || '—' }}</td>
              <td class="px-3 py-2">{{ warehouseLabel(row.dest_site_id) }}</td>
              <td class="px-3 py-2">{{ statusLabel(row.status) }}</td>
              <td class="px-3 py-2">{{ formatQuantity(row.total_qty) }}</td>
              <td class="px-3 py-2 text-xs text-gray-500">{{ formatDateTime(row.created_at) }}</td>
              <td class="px-3 py-2 space-x-2">
                <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openView(row)">{{ t('common.edit') }}</button>
                <button
                  v-if="row.status === 'open'"
                  class="px-2 py-1 text-xs rounded bg-green-600 text-white hover:bg-green-700"
                  @click="postMovement(row)"
                >
                  {{ t('rawMaterialReceipts.actions.post') }}
                </button>
                <button
                  v-if="row.status === 'open'"
                  class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700"
                  @click="confirmDelete(row)"
                >
                  {{ t('common.delete') }}
                </button>
              </td>
            </tr>
            <tr v-if="!loading && sortedRows.length === 0">
              <td colspan="8" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section class="md:hidden grid gap-3">
        <div v-for="row in sortedRows" :key="row.id" class="border border-gray-200 rounded-xl shadow-sm p-4">
          <div class="flex items-center justify-between mb-2">
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">{{ row.doc_no }}</p>
              <h2 class="text-lg font-semibold text-gray-900">{{ warehouseLabel(row.dest_site_id) }}</h2>
            </div>
            <span class="text-xs font-medium px-2 py-1 rounded-full" :class="row.status === 'posted' ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'">
              {{ statusLabel(row.status) }}
            </span>
          </div>
          <dl class="text-sm text-gray-600 space-y-1">
            <div class="flex justify-between"><dt>{{ t('rawMaterialReceipts.table.movementDate') }}</dt><dd>{{ formatDateTime(row.movement_at) }}</dd></div>
            <div class="flex justify-between"><dt>{{ t('rawMaterialReceipts.table.supplier') }}</dt><dd>{{ row.supplier_label || '—' }}</dd></div>
            <div class="flex justify-between"><dt>{{ t('rawMaterialReceipts.table.totalQty') }}</dt><dd>{{ formatQuantity(row.total_qty) }}</dd></div>
          </dl>
          <div class="mt-3 flex gap-2">
            <button class="px-3 py-2 text-sm rounded border hover:bg-gray-100" @click="openView(row)">{{ t('common.edit') }}</button>
            <button
              v-if="row.status === 'open'"
              class="px-3 py-2 text-sm rounded bg-green-600 text-white hover:bg-green-700"
              @click="postMovement(row)"
            >
              {{ t('rawMaterialReceipts.actions.post') }}
            </button>
            <button
              v-if="row.status === 'open'"
              class="px-3 py-2 text-sm rounded bg-red-600 text-white hover:bg-red-700"
              @click="confirmDelete(row)"
            >
              {{ t('common.delete') }}
            </button>
          </div>
        </div>
        <p v-if="!loading && sortedRows.length === 0" class="text-center text-gray-500 text-sm">{{ t('common.noData') }}</p>
      </section>

      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4 overflow-y-auto">
        <div class="w-full max-w-3xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ editing ? t('rawMaterialReceipts.editTitle') : t('rawMaterialReceipts.newTitle') }}</h3>
          </div>
          <div class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('rawMaterialReceipts.form.docNo') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.doc_no" class="w-full h-[40px] border rounded px-3" :readonly="readOnly" :disabled="readOnly" />
                <p v-if="errors.doc_no" class="text-xs text-red-600 mt-1">{{ errors.doc_no }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('rawMaterialReceipts.form.movementDate') }}<span class="text-red-600">*</span></label>
                <input v-model="form.movement_at" type="datetime-local" class="w-full h-[40px] border rounded px-3" :disabled="readOnly" />
                <p v-if="errors.movement_at" class="text-xs text-red-600 mt-1">{{ errors.movement_at }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('rawMaterialReceipts.form.supplier') }}</label>
                <select v-model="form.src_site_id" class="w-full h-[40px] border rounded px-3 bg-white" :disabled="readOnly">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in siteOptions" :key="`src-${option.value}`" :value="option.value">{{ option.label }}</option>
                </select>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('rawMaterialReceipts.form.destination') }}<span class="text-red-600">*</span></label>
                <select v-model="form.dest_site_id" class="w-full h-[40px] border rounded px-3 bg-white" :disabled="readOnly">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in warehouseOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
                <p v-if="errors.dest_site_id" class="text-xs text-red-600 mt-1">{{ errors.dest_site_id }}</p>
              </div>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('rawMaterialReceipts.form.notes') }}</label>
              <textarea v-model.trim="form.notes" rows="2" class="w-full border rounded px-3 py-2" :readonly="readOnly" :disabled="readOnly"></textarea>
            </div>
            <section class="border border-gray-200 rounded-lg">
              <header class="flex items-center justify-between px-3 py-2 border-b bg-gray-50">
                <h4 class="text-sm font-semibold text-gray-800">{{ t('rawMaterialReceipts.form.lines') }}</h4>
                <button
                  class="px-2 py-1 text-xs rounded border border-dashed hover:bg-gray-100 disabled:opacity-50"
                  type="button"
                  :disabled="readOnly"
                  @click="addLine"
                >
                  {{ t('rawMaterialReceipts.form.addLine') }}
                </button>
              </header>
              <p v-if="errors.lines" class="px-3 pt-2 text-xs text-red-600">{{ errors.lines }}</p>
              <div class="overflow-x-auto">
                <table class="min-w-full text-sm">
                  <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                    <tr>
                      <th class="px-3 py-2 text-left">{{ t('rawMaterialReceipts.form.material') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('rawMaterialReceipts.form.quantity') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('rawMaterialReceipts.form.uom') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('rawMaterialReceipts.form.lineNotes') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="(line, index) in form.lines" :key="line.localId" class="hover:bg-gray-50">
                      <td class="px-3 py-2">
                        <select
                          v-model="line.material_id"
                          class="w-full h-[38px] border rounded px-2 bg-white"
                          :disabled="readOnly"
                          @change="handleMaterialChange(line)"
                        >
                          <option value="">{{ t('common.select') }}</option>
                          <option v-for="material in materialOptions" :key="material.value" :value="material.value">{{ material.label }}</option>
                        </select>
                        <p v-if="lineErrors[index]?.material_id" class="text-xs text-red-600 mt-1">{{ lineErrors[index]?.material_id }}</p>
                      </td>
                      <td class="px-3 py-2">
                        <input v-model.number="line.qty" type="number" step="0.01" min="0" class="w-full h-[38px] border rounded px-2" :readonly="readOnly" :disabled="readOnly" />
                        <p v-if="lineErrors[index]?.qty" class="text-xs text-red-600 mt-1">{{ lineErrors[index]?.qty }}</p>
                      </td>
                      <td class="px-3 py-2 text-gray-700">{{ line.uom_code || '—' }}</td>
                      <td class="px-3 py-2">
                        <input v-model.trim="line.notes" class="w-full h-[38px] border rounded px-2" :readonly="readOnly" :disabled="readOnly" />
                      </td>
                      <td class="px-3 py-2">
                        <button
                          class="px-2 py-1 text-xs rounded border hover:bg-gray-100 disabled:opacity-50"
                          type="button"
                          :disabled="readOnly"
                          @click="removeLine(index)"
                        >
                          {{ t('common.delete') }}
                        </button>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </section>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" :disabled="saving || readOnly" @click="saveRecord">
              {{ saving ? t('common.saving') : t('common.save') }}
            </button>
          </div>
        </div>
      </div>

      <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('rawMaterialReceipts.deleteTitle') }}</h3>
          </div>
          <div class="p-4 text-sm">{{ t('rawMaterialReceipts.deleteConfirm', { docNo: toDelete?.doc_no ?? '' }) }}</div>
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
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'

const DOC_TYPE = 'purchase'
const ALLOWED_CATEGORIES = ['malt', 'hop', 'yeast', 'adjunct'] as const
const STATUS_OPTIONS = ['open', 'posted'] as const

interface MovementRow {
  id: string
  doc_no: string
  doc_type: string
  status: string
  movement_at: string
  src_site_id: string | null
  dest_site_id: string | null
  supplier_label: string | null
  notes: string
  created_at: string | null
  total_qty: number
}

interface ReceiptLine {
  localId: string
  material_id: string
  qty: number | null
  uom_id: string
  uom_code: string
  notes: string
}

interface MaterialOption {
  value: string
  label: string
  uom_id: string
  uom_code: string
}

interface WarehouseOption {
  value: string
  code: string
  name: string
  label: string
}

interface OptionItem {
  value: string
  label: string
}

const { t, locale } = useI18n()
const pageTitle = computed(() => t('rawMaterialReceipts.title'))

const rows = ref<MovementRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const readOnly = ref(false)
const toDelete = ref<MovementRow | null>(null)

const statusOptions = STATUS_OPTIONS

const filters = reactive({
  docNo: '',
  dateFrom: '',
  dateTo: '',
  supplier: '',
  warehouse: '',
  status: '' as '' | typeof STATUS_OPTIONS[number],
})

const sortKey = ref<'doc_no' | 'movement_at' | 'created_at'>('movement_at')
const sortDirection = ref<'asc' | 'desc'>('desc')

const siteOptions = ref<OptionItem[]>([])
const warehouseOptions = ref<WarehouseOption[]>([])
const materialOptions = ref<MaterialOption[]>([])
const materialLookup = computed(() => {
  const map = new Map<string, MaterialOption>()
  materialOptions.value.forEach((item) => map.set(item.value, item))
  return map
})

const warehouseMap = computed(() => {
  const map = new Map<string, WarehouseOption>()
  warehouseOptions.value.forEach((item) => map.set(item.value, item))
  return map
})

const form = reactive({
  id: '',
  doc_no: '',
  movement_at: '',
  src_site_id: '',
  dest_site_id: '',
  notes: '',
  lines: [] as ReceiptLine[],
})

const errors = reactive<Record<string, string>>({})
const lineErrors = ref<Record<string, string>[]>([])

function statusLabel(value: string) {
  const key = `rawMaterialReceipts.status.${value}`
  const translated = t(key as any)
  return translated === key ? value : translated
}

function warehouseLabel(id: string | null) {
  if (!id) return '—'
  return warehouseMap.value.get(id)?.label ?? '—'
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleString(locale.value)
}

function formatQuantity(value: number | null | undefined) {
  if (value == null) return '—'
  return new Intl.NumberFormat(locale.value, { maximumFractionDigits: 2 }).format(value)
}

function sortGlyphFn() {
  return sortDirection.value === 'asc' ? '▲' : '▼'
}
const sortGlyph = computed(sortGlyphFn)

function setSort(key: 'doc_no' | 'movement_at' | 'created_at') {
  if (sortKey.value === key) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = key
    sortDirection.value = 'desc'
  }
}

const filteredRows = computed(() => {
  const doc = filters.docNo.trim().toLowerCase()
  return rows.value.filter((row) => {
    const matchDoc = !doc || row.doc_no.toLowerCase().includes(doc)
    const matchSupplier = !filters.supplier || row.src_site_id === filters.supplier
    const matchWarehouse = !filters.warehouse || row.dest_site_id === filters.warehouse
    const matchStatus = !filters.status || row.status === filters.status
    const matchDateFrom = !filters.dateFrom || (row.movement_at && row.movement_at >= `${filters.dateFrom}T00:00:00`)
    const matchDateTo = !filters.dateTo || (row.movement_at && row.movement_at <= `${filters.dateTo}T23:59:59`)
    return matchDoc && matchSupplier && matchWarehouse && matchStatus && matchDateFrom && matchDateTo
  })
})

const sortedRows = computed(() => {
  const data = [...filteredRows.value]
  const direction = sortDirection.value === 'asc' ? 1 : -1
  const key = sortKey.value
  data.sort((a, b) => {
    const aVal = a[key]
    const bVal = b[key]
    if (!aVal && !bVal) return 0
    if (!aVal) return 1 * direction
    if (!bVal) return -1 * direction
    return String(aVal).localeCompare(String(bVal)) * direction
  })
  return data
})

function resetFilters() {
  filters.docNo = ''
  filters.dateFrom = ''
  filters.dateTo = ''
  filters.supplier = ''
  filters.warehouse = ''
  filters.status = ''
}

function blankLine(): ReceiptLine {
  return {
    localId: createLocalId(),
    material_id: '',
    qty: null,
    uom_id: '',
    uom_code: '',
    notes: '',
  }
}

function resetForm() {
  form.id = ''
  form.doc_no = generateDocNo()
  form.movement_at = new Date().toISOString().slice(0, 16)
  form.src_site_id = ''
  form.dest_site_id = ''
  form.notes = ''
  form.lines = [blankLine()]
  lineErrors.value = [{}]
  readOnly.value = false
  Object.keys(errors).forEach((key) => delete errors[key])
}

function openCreate() {
  editing.value = false
  resetForm()
  showModal.value = true
}

async function openView(row: MovementRow) {
  editing.value = true
  resetForm()
  form.id = row.id
  form.doc_no = row.doc_no
  form.movement_at = row.movement_at ? new Date(row.movement_at).toISOString().slice(0, 16) : new Date().toISOString().slice(0, 16)
  form.src_site_id = row.src_site_id ?? ''
  form.dest_site_id = row.dest_site_id ?? ''
  form.notes = row.notes ?? ''
  readOnly.value = row.status !== 'open'
  await loadLines(row.id)
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function confirmDelete(row: MovementRow) {
  toDelete.value = row
  showDelete.value = true
}

function generateDocNo() {
  const now = new Date()
  const datePart = now.toISOString().slice(0, 10).replace(/-/g, '')
  return `RM-${datePart}-${Math.random().toString(36).slice(2, 6).toUpperCase()}`
}

function createLocalId() {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return crypto.randomUUID()
  }
  return `line-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
}

function addLine() {
  form.lines.push(blankLine())
  lineErrors.value.push({})
}

function removeLine(index: number) {
  form.lines.splice(index, 1)
  lineErrors.value.splice(index, 1)
  if (form.lines.length === 0) addLine()
}

function handleMaterialChange(line: ReceiptLine) {
  if (!line.material_id) {
    line.uom_id = ''
    line.uom_code = ''
    return
  }
  const match = materialLookup.value.get(line.material_id)
  if (match) {
    line.uom_id = match.uom_id
    line.uom_code = match.uom_code
  }
}

function validateLines() {
  let valid = true
  form.lines.forEach((line, index) => {
    const entry: Record<string, string> = {}
    if (!line.material_id) {
      entry.material_id = t('rawMaterialReceipts.errors.materialRequired')
      valid = false
    }
    if (!line.qty || line.qty <= 0) {
      entry.qty = t('rawMaterialReceipts.errors.qtyRequired')
      valid = false
    }
    lineErrors.value[index] = entry
  })
  lineErrors.value = [...lineErrors.value]
  return valid
}

function validateForm() {
  Object.keys(errors).forEach((key) => delete errors[key])
  if (!form.doc_no) errors.doc_no = t('rawMaterialReceipts.errors.docNoRequired')
  if (!form.movement_at) errors.movement_at = t('rawMaterialReceipts.errors.movementDateRequired')
  if (!form.dest_site_id) errors.dest_site_id = t('rawMaterialReceipts.errors.warehouseRequired')
  const linesValid = validateLines()
  return Object.keys(errors).length === 0 && linesValid
}

async function loadSites() {
  const { data, error } = await supabase
    .from('mst_sites')
    .select('id, code, name')
    .order('code', { ascending: true })
  if (error) throw error
  siteOptions.value = (data ?? []).map((row) => ({ value: row.id, label: `${row.code} — ${row.name}` }))
}

async function loadWarehouses() {
  const { data, error } = await supabase
    .from('v_sites')
    .select('id, code, name, site_type_code')
    .eq('site_type_code', 'warehouse')
    .order('code', { ascending: true })
  if (error) throw error
  warehouseOptions.value = (data ?? []).map((row: any) => ({
    value: row.id,
    code: row.code,
    name: row.name,
    label: `${row.code} — ${row.name}`,
  }))
}

async function loadMaterials() {
  const { data, error } = await supabase
    .from('mst_materials')
    .select('id, code, name, category, uom:uom_id(id, code)')
    .in('category', ALLOWED_CATEGORIES)
    .order('code', { ascending: true })
  if (error) throw error
  materialOptions.value = (data ?? []).map((row: any) => ({
    value: row.id,
    label: `${row.code} — ${row.name}`,
    uom_id: row.uom?.id ?? '',
    uom_code: row.uom?.code ?? '',
  }))
}

async function loadLines(movementId: string) {
  const { data, error } = await supabase
    .from('inv_movement_lines')
    .select('id, material_id, qty, uom_id, notes')
    .eq('movement_id', movementId)
    .order('line_no', { ascending: true })
  if (error) throw error
  const lines = (data ?? []).map((row) => {
    const match = materialLookup.value.get(row.material_id ?? '')
    return {
      localId: createLocalId(),
      material_id: row.material_id ?? '',
      qty: row.qty ?? null,
      uom_id: row.uom_id ?? match?.uom_id ?? '',
      uom_code: match?.uom_code ?? '',
      notes: row.notes ?? '',
    }
  })
  form.lines = lines.length > 0 ? lines : [blankLine()]
  lineErrors.value = form.lines.map(() => ({}))
}

async function fetchReceipts() {
  try {
    loading.value = true
    const { data, error } = await supabase
      .from('inv_movements')
      .select('id, doc_no, doc_type, status, movement_at, src_site_id, dest_site_id, meta, notes, created_at, supplier:src_site_id(code, name), dest:dest_site_id(code, name), lines:inv_movement_lines(qty)')
      .eq('doc_type', DOC_TYPE)
      .order('movement_at', { ascending: false })
    if (error) throw error
    rows.value = (data ?? []).map((row: any) => {
      const supplierLabel = row.supplier ? `${row.supplier.code} — ${row.supplier.name}` : null
      const qtyTotal = (row.lines ?? []).reduce((sum: number, line: any) => sum + (line.qty ?? 0), 0)
      return {
        id: row.id,
        doc_no: row.doc_no,
        doc_type: row.doc_type,
        status: row.status,
        movement_at: row.movement_at,
        src_site_id: row.src_site_id ?? null,
        dest_site_id: row.meta?.site_id ?? row.dest_site_id ?? null,
        supplier_label: supplierLabel,
        notes: row.notes ?? '',
        created_at: row.created_at ?? null,
        total_qty: qtyTotal,
      }
    })
  } catch (err) {
    console.error(err)
    alert(err instanceof Error ? err.message : String(err))
  } finally {
    loading.value = false
  }
}

async function saveRecord() {
  if (readOnly.value) {
    closeModal()
    return
  }
  if (!validateForm()) return
  try {
    saving.value = true
    const payload: Record<string, any> = {
      doc_no: form.doc_no.trim(),
      doc_type: DOC_TYPE,
      movement_at: new Date(form.movement_at).toISOString(),
      status: 'open',
      src_site_id: form.src_site_id || null,
      dest_site_id: form.dest_site_id || null,
      notes: form.notes.trim() || null,
      meta: { site_id: form.dest_site_id || null },
    }

    let movementId = form.id
    if (editing.value && movementId) {
      const { error } = await supabase.from('inv_movements').update(payload).eq('id', movementId)
      if (error) throw error
      const { error: delError } = await supabase.from('inv_movement_lines').delete().eq('movement_id', movementId)
      if (delError) throw delError
    } else {
      const { data, error } = await supabase.from('inv_movements').insert(payload).select('id').single()
      if (error || !data) throw error || new Error('Insert failed')
      movementId = data.id
    }

    const linesPayload = form.lines
      .filter((line) => line.material_id && line.qty && line.qty > 0)
      .map((line, index) => ({
        movement_id: movementId,
        line_no: index + 1,
        material_id: line.material_id,
        qty: line.qty,
        uom_id: line.uom_id,
        notes: line.notes.trim() || null,
      }))

    if (linesPayload.length > 0) {
      const { error: lineError } = await supabase.from('inv_movement_lines').insert(linesPayload)
      if (lineError) throw lineError
    }

    await postMovementById(movementId, form.dest_site_id)
    closeModal()
    await fetchReceipts()
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
    const { error } = await supabase.from('inv_movements').delete().eq('id', toDelete.value.id).eq('status', 'open')
    if (error) throw error
    showDelete.value = false
    toDelete.value = null
    await fetchReceipts()
  } catch (err) {
    console.error(err)
    alert(err instanceof Error ? err.message : String(err))
  }
}

async function postMovement(row: MovementRow) {
  if (row.status !== 'open') return
  const warehouseId = row.dest_site_id
  if (!warehouseId) {
    alert(t('rawMaterialReceipts.errors.warehouseRequired'))
    return
  }
  try {
    saving.value = true
    await postMovementById(row.id, warehouseId)
    await fetchReceipts()
  } catch (err) {
    console.error(err)
    alert(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

async function postMovementById(movementId: string, warehouseId: string | null) {
  if (!warehouseId) throw new Error(t('rawMaterialReceipts.errors.warehouseRequired'))

  const { data: lines, error } = await supabase
    .from('inv_movement_lines')
    .select('material_id, qty, uom_id')
    .eq('movement_id', movementId)
  if (error) throw error
  if (!lines || lines.length === 0) throw new Error(t('rawMaterialReceipts.errors.linesRequired'))

  for (const line of lines) {
    if (!line.material_id || !line.qty) continue
    const { data: existing, error: fetchError } = await supabase
      .from('inv_inventory')
      .select('id, qty')
      .eq('site_id', warehouseId)
      .eq('material_id', line.material_id)
      .maybeSingle()
    if (fetchError) throw fetchError
    if (existing) {
      const newQty = (existing.qty ?? 0) + line.qty
      const { error: updateError } = await supabase
        .from('inv_inventory')
        .update({ qty: newQty, uom_id: line.uom_id })
        .eq('id', existing.id)
      if (updateError) throw updateError
    } else {
      const { error: insertError } = await supabase.from('inv_inventory').insert({
        site_id: warehouseId,
        material_id: line.material_id,
        qty: line.qty,
        uom_id: line.uom_id,
      })
      if (insertError) throw insertError
    }
  }

  const { error: statusError } = await supabase.from('inv_movements').update({ status: 'posted' }).eq('id', movementId)
  if (statusError) throw statusError
}

watch(locale, () => {
  rows.value = [...rows.value]
})

onMounted(async () => {
  await Promise.all([loadSites(), loadWarehouses(), loadMaterials()])
  await fetchReceipts()
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
