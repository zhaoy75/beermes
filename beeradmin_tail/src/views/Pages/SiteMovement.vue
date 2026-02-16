<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto space-y-4">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('siteMovement.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('siteMovement.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">
            {{ t('common.new') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="fetchMovements"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white">
        <form class="grid grid-cols-1 md:grid-cols-4 gap-3" @submit.prevent>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="docFilter">{{ t('siteMovement.filters.docNo') }}</label>
            <input
              id="docFilter"
              v-model.trim="filters.docNo"
              :placeholder="t('siteMovement.filters.docPlaceholder')"
              class="w-full h-[40px] border rounded px-3"
              type="search"
            />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="dateFrom">{{ t('siteMovement.filters.dateFrom') }}</label>
            <input id="dateFrom" v-model="filters.dateFrom" type="date" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="dateTo">{{ t('siteMovement.filters.dateTo') }}</label>
            <input id="dateTo" v-model="filters.dateTo" type="date" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div class="flex items-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="resetFilters">{{ t('common.reset') }}</button>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('siteMovement.filters.source') }}</label>
            <select v-model="filters.sourceSite" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in siteOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('siteMovement.filters.destination') }}</label>
            <select v-model="filters.destSite" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in siteOptions" :key="`dest-${option.value}`" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
        </form>
      </section>

      <section class="hidden md:block overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200 text-sm">
          <thead class="bg-gray-50 text-xs uppercase text-gray-600">
            <tr>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('doc_no')">{{ t('siteMovement.table.docNo') }}<span v-if="sortKey === 'doc_no'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('doc_type')">{{ t('siteMovement.table.docType') }}<span v-if="sortKey === 'doc_type'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('movement_at')">{{ t('siteMovement.table.movementDate') }}<span v-if="sortKey === 'movement_at'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('source_name')">{{ t('siteMovement.table.source') }}<span v-if="sortKey === 'source_name'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('dest_name')">{{ t('siteMovement.table.destination') }}<span v-if="sortKey === 'dest_name'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('status')">{{ t('siteMovement.table.status') }}<span v-if="sortKey === 'status'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left cursor-pointer" @click="setSort('created_at')">{{ t('siteMovement.table.createdAt') }}<span v-if="sortKey === 'created_at'"> {{ sortGlyph }}</span></th>
              <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in sortedRows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.doc_no }}</td>
              <td class="px-3 py-2 text-gray-700">{{ docTypeLabel(row.doc_type) }}</td>
              <td class="px-3 py-2 text-xs text-gray-500">{{ formatTimestamp(row.movement_at) }}</td>
              <td class="px-3 py-2 text-gray-700">{{ row.source_name || '—' }}</td>
              <td class="px-3 py-2 text-gray-700">{{ row.dest_name || '—' }}</td>
              <td class="px-3 py-2 text-gray-700">{{ statusLabel(row.status) }}</td>
              <td class="px-3 py-2 text-xs text-gray-500">{{ formatTimestamp(row.created_at) }}</td>
              <td class="px-3 py-2 space-x-2">
                <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openEdit(row)">{{ t('common.edit') }}</button>
                <button class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">{{ t('common.delete') }}</button>
              </td>
            </tr>
            <tr v-if="!loading && sortedRows.length === 0">
              <td colspan="8" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section class="md:hidden grid gap-3">
        <article v-for="row in sortedRows" :key="row.id" class="border border-gray-200 rounded-xl shadow-sm p-4 space-y-2">
          <header class="flex items-center justify-between">
            <div>
              <p class="text-xs uppercase text-gray-400">{{ row.doc_no }}</p>
              <h2 class="text-base font-semibold text-gray-900">{{ docTypeLabel(row.doc_type) }}</h2>
            </div>
            <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openEdit(row)">{{ t('common.edit') }}</button>
          </header>
          <dl class="text-sm text-gray-600 space-y-1">
            <div class="flex justify-between"><dt>{{ t('siteMovement.table.movementDate') }}</dt><dd class="text-xs text-gray-500">{{ formatTimestamp(row.movement_at) }}</dd></div>
            <div class="flex justify-between"><dt>{{ t('siteMovement.table.source') }}</dt><dd>{{ row.source_name || '—' }}</dd></div>
            <div class="flex justify-between"><dt>{{ t('siteMovement.table.destination') }}</dt><dd>{{ row.dest_name || '—' }}</dd></div>
            <div class="flex justify-between"><dt>{{ t('siteMovement.table.status') }}</dt><dd>{{ statusLabel(row.status) }}</dd></div>
          </dl>
          <footer class="flex gap-2">
            <button class="px-3 py-2 text-sm rounded border hover:bg-gray-100" @click="openEdit(row)">{{ t('common.edit') }}</button>
            <button class="px-3 py-2 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">{{ t('common.delete') }}</button>
          </footer>
        </article>
        <p v-if="!loading && sortedRows.length === 0" class="text-center text-sm text-gray-500">{{ t('common.noData') }}</p>
      </section>

      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-3xl bg-white rounded-xl shadow-lg border">
          <header class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ editing ? t('siteMovement.editTitle') : t('siteMovement.newTitle') }}</h3>
          </header>
          <section class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('siteMovement.form.docNo') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.doc_no" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.doc_no" class="text-xs text-red-600 mt-1">{{ errors.doc_no }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('siteMovement.form.docType') }}<span class="text-red-600">*</span></label>
                <select v-model="form.doc_type" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in docTypeOptions" :key="option" :value="option">{{ docTypeLabel(option) }}</option>
                </select>
                <p v-if="errors.doc_type" class="text-xs text-red-600 mt-1">{{ errors.doc_type }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('siteMovement.form.movementDate') }}<span class="text-red-600">*</span></label>
                <input v-model="form.movement_at" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.movement_at" class="text-xs text-red-600 mt-1">{{ errors.movement_at }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('siteMovement.form.status') }}</label>
                <select v-model="form.status" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option v-for="option in statusOptions" :key="option" :value="option">{{ statusLabel(option) }}</option>
                </select>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('siteMovement.form.source') }}<span class="text-red-600">*</span></label>
                <select v-model="form.src_site_id" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in siteOptions" :key="`src-${option.value}`" :value="option.value">{{ option.label }}</option>
                </select>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('siteMovement.form.destination') }}<span class="text-red-600">*</span></label>
                <select v-model="form.dest_site_id" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in siteOptions" :key="`dest-${option.value}`" :value="option.value">{{ option.label }}</option>
                </select>
              </div>
              <div class="md:col-span-2" v-if="errors.site">
                <p class="text-xs text-red-600">{{ errors.site }}</p>
              </div>
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1">{{ t('siteMovement.form.notes') }}</label>
                <textarea v-model.trim="form.notes" rows="2" class="w-full border rounded px-3 py-2"></textarea>
              </div>
            </div>

            <section class="border border-gray-200 rounded-lg">
              <header class="flex items-center justify-between px-3 py-2 border-b bg-gray-50">
                <h4 class="text-sm font-semibold text-gray-800">{{ t('siteMovement.form.lines') }}</h4>
                <button class="px-2 py-1 text-xs rounded border border-dashed hover:bg-gray-100" type="button" @click="addLine">{{ t('siteMovement.form.addLine') }}</button>
              </header>
              <p v-if="errors.lines" class="px-3 pt-2 text-xs text-red-600">{{ errors.lines }}</p>
              <div class="overflow-x-auto">
                <table class="min-w-full text-sm">
                  <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                    <tr>
                      <th class="px-3 py-2 text-left">{{ t('siteMovement.form.material') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('siteMovement.form.quantity') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('siteMovement.form.uom') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('siteMovement.form.lineNotes') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="(line, index) in form.lines" :key="line.localId" class="hover:bg-gray-50">
                      <td class="px-3 py-2">
                        <select v-model="line.material_id" class="w-full h-[38px] border rounded px-2 bg-white" @change="handleMaterialChange(line)">
                          <option value="">{{ t('common.select') }}</option>
                          <option v-for="material in materialOptions" :key="material.value" :value="material.value">{{ material.label }}</option>
                        </select>
                        <p v-if="lineErrors[index]?.material_id" class="text-xs text-red-600 mt-1">{{ lineErrors[index]?.material_id }}</p>
                      </td>
                      <td class="px-3 py-2">
                        <input v-model.number="line.qty" type="number" step="0.001" min="0" class="w-full h-[38px] border rounded px-2" />
                        <p v-if="lineErrors[index]?.qty" class="text-xs text-red-600 mt-1">{{ lineErrors[index]?.qty }}</p>
                      </td>
                      <td class="px-3 py-2 text-gray-600">{{ line.uom_code || '—' }}</td>
                      <td class="px-3 py-2">
                        <input v-model.trim="line.notes" class="w-full h-[38px] border rounded px-2" />
                      </td>
                      <td class="px-3 py-2">
                        <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" type="button" @click="removeLine(index)">{{ t('common.delete') }}</button>
                      </td>
                    </tr>
                    <tr v-if="form.lines.length === 0">
                      <td colspan="5" class="px-3 py-4 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </section>
          </section>
          <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" :disabled="saving" @click="saveRecord">
              {{ saving ? t('common.saving') : t('common.save') }}
            </button>
          </footer>
        </div>
      </div>

      <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
          <header class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('siteMovement.deleteTitle') }}</h3>
          </header>
          <section class="p-4 text-sm">{{ t('siteMovement.deleteConfirm', { docNo: toDelete?.doc_no ?? '' }) }}</section>
          <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="showDelete = false">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700" @click="deleteRecord">{{ t('common.delete') }}</button>
          </footer>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

const DOC_TYPES = ['transfer', 'tax_transfer', 'production_issue', 'production_receipt'] as const
const STATUSES = ['open', 'posted', 'void'] as const
const statusOptions = STATUSES
const docTypeOptions = DOC_TYPES

interface MovementRow {
  id: string
  tenant_id?: string
  doc_no: string
  doc_type: string
  movement_at: string | null
  status: string
  src_site_id: string | null
  dest_site_id: string | null
  source_name: string | null
  dest_name: string | null
  notes: string | null
  created_at: string | null
  address: any
  contact: any
}

interface MovementLine {
  localId: string
  id?: string
  material_id: string
  qty: number | null
  uom_id: string | null
  uom_code: string | null
  notes: string
}

const { t, locale } = useI18n()
const route = useRoute()
const pageTitle = computed(() => t('siteMovement.title'))

const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const toDelete = ref<MovementRow | null>(null)

const rows = ref<MovementRow[]>([])
const siteOptions = ref<Array<{ value: string; label: string }>>([])
const materialLookup = ref<Record<string, { id: string; code: string; name: string; uom_id: string; uom_code: string }>>({})

const sortKey = ref<'doc_no' | 'doc_type' | 'movement_at' | 'source_name' | 'dest_name' | 'status' | 'created_at'>('movement_at')
const sortDirection = ref<'asc' | 'desc'>('desc')

const filters = reactive({ docNo: '', dateFrom: '', dateTo: '', sourceSite: '', destSite: '' })
const tenantId = ref<string | null>(null)

const form = reactive({
  id: '',
  doc_no: '',
  doc_type: 'transfer',
  movement_at: '',
  status: 'open',
  src_site_id: '',
  dest_site_id: '',
  notes: '',
  lines: [] as MovementLine[],
})

const errors = reactive<Record<string, string>>({})
const lineErrors = ref<Array<Record<string, string>>> ([])

const sortGlyph = computed(() => (sortDirection.value === 'asc' ? '▲' : '▼'))

const materialOptions = computed(() =>
  Object.values(materialLookup.value).map((item) => ({ value: item.id, label: `${item.code} — ${item.name}` })),
)

const filteredRows = computed(() => {
  const docFilter = filters.docNo.trim().toLowerCase()
  return rows.value.filter((row) => {
    const matchesDoc = !docFilter || row.doc_no.toLowerCase().includes(docFilter)
    const matchesSource = !filters.sourceSite || row.src_site_id === filters.sourceSite
    const matchesDest = !filters.destSite || row.dest_site_id === filters.destSite
    return matchesDoc && matchesSource && matchesDest
  })
})

const sortedRows = computed(() => {
  const list = [...filteredRows.value]
  list.sort((a, b) => {
    const dir = sortDirection.value === 'asc' ? 1 : -1
    const key = sortKey.value
    const av = (a as any)[key]
    const bv = (b as any)[key]
    if (av == null && bv == null) return 0
    if (av == null) return 1
    if (bv == null) return -1
    if (key === 'movement_at' || key === 'created_at') return dir * (new Date(av).getTime() - new Date(bv).getTime())
    return dir * String(av).localeCompare(String(bv))
  })
  return list
})

function setSort(key: typeof sortKey.value) {
  if (sortKey.value === key) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = key
    sortDirection.value = key === 'movement_at' || key === 'created_at' ? 'desc' : 'asc'
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

function docTypeLabel(value: string) {
  const map = t('siteMovement.docTypeMap') as Record<string, string>
  return map[value] || value
}

function statusLabel(value: string) {
  const map = t('siteMovement.statusMap') as Record<string, string>
  return map[value] || value
}

function resetForm() {
  form.id = ''
  form.doc_no = ''
  form.doc_type = 'transfer'
  form.movement_at = formatInputDateTime(new Date())
  form.status = 'open'
  form.src_site_id = ''
  form.dest_site_id = ''
  form.notes = ''
  form.lines = []
  lineErrors.value = []
  Object.keys(errors).forEach((key) => delete errors[key])
}

function addLine() {
  form.lines.push({
    localId: createLocalId(),
    material_id: '',
    qty: null,
    uom_id: null,
    uom_code: null,
    notes: '',
  })
  lineErrors.value.push({})
}

function removeLine(index: number) {
  form.lines.splice(index, 1)
  lineErrors.value.splice(index, 1)
}

function handleMaterialChange(line: MovementLine) {
  const material = materialLookup.value[line.material_id]
  if (material) {
    line.uom_id = material.uom_id
    line.uom_code = material.uom_code
  } else {
    line.uom_id = null
    line.uom_code = null
  }
}

function openCreate() {
  editing.value = false
  resetForm()
  addLine()
  showModal.value = true
}

async function openEdit(row: MovementRow) {
  editing.value = true
  resetForm()
  form.id = row.id
  form.doc_no = row.doc_no
  form.doc_type = row.doc_type
  form.movement_at = row.movement_at ? formatInputDateTime(new Date(row.movement_at)) : formatInputDateTime(new Date())
  form.status = row.status
  form.src_site_id = row.src_site_id ?? ''
  form.dest_site_id = row.dest_site_id ?? ''
  form.notes = row.notes ?? ''
  form.address = row.address ? JSON.stringify(row.address, null, 2) : ''
  form.contact = row.contact ? JSON.stringify(row.contact, null, 2) : ''

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

function resetFilters() {
  filters.docNo = ''
  filters.dateFrom = ''
  filters.dateTo = ''
  filters.sourceSite = ''
  filters.destSite = ''
}

function applyRouteFilters() {
  const docNo = route.query.docNo
  if (typeof docNo === 'string' && docNo.trim()) {
    filters.docNo = docNo.trim()
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

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved in session')
  tenantId.value = id
  return id
}

async function loadSites() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_sites')
    .select('id, name')
    .eq('tenant_id', tenant)
    .order('name', { ascending: true })
  if (error) throw error
  siteOptions.value = (data ?? []).map((row) => ({ value: row.id, label: row.name ?? row.id }))
}

async function loadMaterials() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_materials')
    .select('id, code, name, uom_id, uom:mst_uom(code)')
    .eq('tenant_id', tenant)
    .order('code', { ascending: true })
  if (error) throw error
  const lookup: Record<string, any> = {}
  ;(data ?? []).forEach((row: any) => {
    lookup[row.id] = {
      id: row.id,
      code: row.code,
      name: row.name,
      uom_id: row.uom_id,
      uom_code: row.uom?.code ?? '',
    }
  })
  materialLookup.value = lookup
}

async function loadLines(movementId: string) {
  const { data, error } = await supabase
    .from('inv_movement_lines')
    .select('id, line_no, material_id, qty, uom_id, notes, material:material_id(id, code, name, uom_id, uom:mst_uom(code))')
    .eq('movement_id', movementId)
    .order('line_no', { ascending: true })
  if (error) throw error

  form.lines = (data ?? []).map((row: any) => ({
    localId: createLocalId(),
    id: row.id,
    material_id: row.material_id ?? '',
    qty: row.qty ?? null,
    uom_id: row.uom_id ?? row.material?.uom_id ?? null,
    uom_code: row.material?.uom?.code ?? null,
    notes: row.notes ?? '',
  }))
  if (form.lines.length === 0) addLine()
  lineErrors.value = form.lines.map(() => ({}))
}

async function fetchMovements() {
  try {
    loading.value = true
    const tenant = await ensureTenant()
    let query = supabase
      .from('inv_movements')
      .select('id, tenant_id, doc_no, doc_type, movement_at, status, src_site_id, dest_site_id, address, contact, notes, created_at, src:src_site_id(id, name), dest:dest_site_id(id, name)')
      .eq('tenant_id', tenant)
      .order('movement_at', { ascending: false })

    if (filters.docNo.trim()) {
      const sanitized = filters.docNo.trim().replace(/[%_]/g, (char) => `\\${char}`)
      const keyword = `%${sanitized}%`
      query = query.ilike('doc_no', keyword)
    }
    if (filters.dateFrom) query = query.gte('movement_at', `${filters.dateFrom}T00:00:00`)
    if (filters.dateTo) query = query.lte('movement_at', `${filters.dateTo}T23:59:59`)
    if (filters.sourceSite) query = query.eq('src_site_id', filters.sourceSite)
    if (filters.destSite) query = query.eq('dest_site_id', filters.destSite)

    const { data, error } = await query
    if (error) throw error

    rows.value = (data ?? []).map((row: any) => ({
      id: row.id,
      tenant_id: row.tenant_id,
      doc_no: row.doc_no,
      doc_type: row.doc_type,
      movement_at: row.movement_at,
      status: row.status,
      src_site_id: row.src_site_id,
      dest_site_id: row.dest_site_id,
      source_name: row.src?.name || row.src?.id || null,
      dest_name: row.dest?.name || row.dest?.id || null,
      notes: row.notes ?? null,
      created_at: row.created_at ?? null,
      address: row.address ?? null,
      contact: row.contact ?? null,
    }))
  } catch (err) {
    console.error(err)
    rows.value = []
  } finally {
    loading.value = false
  }
}

function validateLines() {
  let valid = true
  lineErrors.value = form.lines.map(() => ({}))

  if (form.lines.length === 0) {
    errors.lines = t('siteMovement.errors.linesRequired')
    return false
  }
  delete errors.lines

  form.lines.forEach((line, index) => {
    const entry: Record<string, string> = {}
    if (!line.material_id) {
      entry.material_id = t('siteMovement.errors.materialRequired')
      valid = false
    }
    if (!line.qty || line.qty <= 0) {
      entry.qty = t('siteMovement.errors.qtyRequired')
      valid = false
    }
    lineErrors.value[index] = entry
  })
  lineErrors.value = [...lineErrors.value]
  return valid
}

function createLocalId() {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return crypto.randomUUID()
  }
  return `line-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`
}

function validateForm() {
  Object.keys(errors).forEach((key) => delete errors[key])
  if (!form.doc_no) errors.doc_no = t('siteMovement.errors.docNoRequired')
  if (!form.doc_type) errors.doc_type = t('siteMovement.errors.docTypeRequired')
  if (!form.movement_at) errors.movement_at = t('siteMovement.errors.movementDateRequired')
  if (!form.src_site_id || !form.dest_site_id) errors.site = t('siteMovement.errors.siteRequired')
  const linesValid = validateLines()
  return Object.keys(errors).length === 0 && linesValid
}

async function saveRecord() {
  if (!validateForm()) return
  try {
    saving.value = true
    const tenant = await ensureTenant()
    const movementDatetime = new Date(form.movement_at)
    let addressPayload = null
    let contactPayload = null
    try {
      addressPayload = validateJson(form.address, 'address')
      contactPayload = validateJson(form.contact, 'contact')
    } catch {
      saving.value = false
      return
    }
    const payload = {
      tenant_id: tenant,
      doc_no: form.doc_no.trim(),
      doc_type: form.doc_type,
      movement_at: movementDatetime.toISOString(),
      status: form.status,
      src_site_id: form.src_site_id || null,
      dest_site_id: form.dest_site_id || null,
      address: addressPayload,
      contact: contactPayload,
      notes: form.notes.trim() || null,
    }

    let movementId = form.id
    if (editing.value && movementId) {
      const { error } = await supabase.from('inv_movements').update(payload).eq('id', movementId)
      if (error) throw error
      await supabase.from('inv_movement_lines').delete().eq('movement_id', movementId)
    } else {
      const { data, error } = await supabase
        .from('inv_movements')
        .insert(payload)
        .select('id')
        .single()
      if (error || !data) throw error || new Error('Insert failed')
      movementId = data.id
    }

    const linesPayload = form.lines.map((line, index) => ({
      tenant_id: tenant,
      movement_id: movementId,
      line_no: index + 1,
      material_id: line.material_id || null,
      qty: line.qty,
      uom_id: line.uom_id,
      notes: line.notes.trim() || null,
    }))

    if (linesPayload.length > 0) {
      const { error: lineError } = await supabase.from('inv_movement_lines').insert(linesPayload)
      if (lineError) throw lineError
    }

    closeModal()
    await fetchMovements()
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
    const { error } = await supabase.from('inv_movements').delete().eq('id', toDelete.value.id)
    if (error) throw error
    showDelete.value = false
    toDelete.value = null
    await fetchMovements()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
}

watch(
  () => ({ ...filters }),
  async () => {
    await fetchMovements()
  },
  { deep: true }
)

watch(locale, () => {
  rows.value = [...rows.value]
})

onMounted(async () => {
  await ensureTenant()
  await Promise.all([loadSites(), loadMaterials()])
  applyRouteFilters()
  await fetchMovements()
})

watch(
  () => route.query.docNo,
  () => {
    applyRouteFilters()
  }
)
</script>
