<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto">
      <header class="mb-4 flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('tank.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('tank.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <input
            v-model.trim="searchTerm"
            type="search"
            :placeholder="t('tank.searchPlaceholder')"
            class="w-56 h-[40px] border rounded px-3 text-sm"
          />
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">
            {{ t('common.new') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="fetchTanks"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="hidden md:block overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none" @click="setSort('code')">
                {{ t('labels.code') }}<span v-if="sortKey === 'code'"> {{ sortIcon }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none" @click="setSort('tankName')">
                {{ t('tank.table.tankName') }}<span v-if="sortKey === 'tankName'"> {{ sortIcon }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none" @click="setSort('size')">
                {{ t('tank.table.capacity') }}<span v-if="sortKey === 'size'"> {{ sortIcon }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none" @click="setSort('uomCode')">
                {{ t('labels.uom') }}<span v-if="sortKey === 'uomCode'"> {{ sortIcon }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('tank.table.steps') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none" @click="setSort('active')">
                {{ t('labels.active') }}<span v-if="sortKey === 'active'"> {{ sortIcon }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none" @click="setSort('created_at')">
                {{ t('labels.createdAt') }}<span v-if="sortKey === 'created_at'"> {{ sortIcon }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in sortedRows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.code }}</td>
              <td class="px-3 py-2">{{ row.tankName || '—' }}</td>
              <td class="px-3 py-2">{{ formatSize(row.size, row.uomCode) }}</td>
              <td class="px-3 py-2">{{ row.uomCode || '—' }}</td>
              <td class="px-3 py-2">
                <span
                  v-for="step in row.usedSteps"
                  :key="`${row.id}-${step}`"
                  class="inline-flex items-center px-2 py-1 mr-1 mb-1 text-[11px] font-medium rounded-full bg-blue-50 text-blue-700"
                >
                  {{ stepLabel(step) }}
                </span>
                <span v-if="row.usedSteps.length === 0" class="text-sm text-gray-400">{{ t('tank.table.noSteps') }}</span>
              </td>
              <td class="px-3 py-2">{{ row.active ? t('common.yes') : t('common.no') }}</td>
              <td class="px-3 py-2 text-xs text-gray-500">{{ formatTimestamp(row.created_at) }}</td>
              <td class="px-3 py-2 space-x-2">
                <button class="px-2 py-1 text-sm rounded border hover:bg-gray-100" @click="openEdit(row)">
                  {{ t('common.edit') }}
                </button>
                <button class="px-2 py-1 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">
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
        <div v-for="row in sortedRows" :key="`card-${row.id}`" class="border border-gray-200 rounded-xl shadow-sm p-4">
          <div class="flex items-center justify-between mb-2">
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">{{ row.code }}</p>
              <h2 class="text-lg font-semibold text-gray-900">{{ row.tankName || '—' }}</h2>
            </div>
            <span
              class="text-xs font-medium px-2 py-1 rounded-full"
              :class="row.active ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-600'"
            >
              {{ row.active ? t('common.yes') : t('common.no') }}
            </span>
          </div>
          <dl class="text-sm text-gray-600 space-y-1">
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('tank.table.capacity') }}</dt>
              <dd>{{ formatSize(row.size, row.uomCode) }}</dd>
            </div>
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('labels.uom') }}</dt>
              <dd>{{ row.uomCode || '—' }}</dd>
            </div>
            <div>
              <dt class="font-medium">{{ t('tank.table.steps') }}</dt>
              <dd class="mt-1 flex flex-wrap gap-1">
                <span
                  v-for="step in row.usedSteps"
                  :key="`${row.id}-mobile-${step}`"
                  class="inline-flex items-center px-2 py-1 text-[11px] font-medium rounded-full bg-blue-50 text-blue-700"
                >
                  {{ stepLabel(step) }}
                </span>
                <span v-if="row.usedSteps.length === 0" class="text-sm text-gray-400">{{ t('tank.table.noSteps') }}</span>
              </dd>
            </div>
            <div class="flex justify-between">
              <dt class="font-medium">{{ t('labels.createdAt') }}</dt>
              <dd class="text-xs text-gray-500">{{ formatTimestamp(row.created_at) }}</dd>
            </div>
          </dl>
          <div class="mt-3 flex gap-2">
            <button class="px-3 py-2 text-sm rounded border hover:bg-gray-100" @click="openEdit(row)">
              {{ t('common.edit') }}
            </button>
            <button class="px-3 py-2 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">
              {{ t('common.delete') }}
            </button>
          </div>
        </div>
        <p v-if="!loading && sortedRows.length === 0" class="text-center text-gray-500 text-sm">
          {{ t('common.noData') }}
        </p>
      </section>

      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-3xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ editing ? t('tank.editTitle') : t('tank.newTitle') }}</h3>
          </div>
          <div class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.code') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.code" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.code" class="mt-1 text-xs text-red-600">{{ errors.code }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('tank.form.tankName') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.tankName" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.tankName" class="mt-1 text-xs text-red-600">{{ errors.tankName }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('tank.form.capacity') }}</label>
                <input v-model.trim="form.size" type="number" step="0.01" min="0" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.size" class="mt-1 text-xs text-red-600">{{ errors.size }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.uom') }}<span class="text-red-600">*</span></label>
                <select v-model="form.uom_id" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option disabled value="">{{ t('tank.form.uomPlaceholder') }}</option>
                  <option v-for="uom in uomOptions" :key="uom.id" :value="uom.id">
                    {{ uom.code }}<span v-if="uom.name"> · {{ uom.name }}</span>
                  </option>
                </select>
                <p v-if="errors.uom_id" class="mt-1 text-xs text-red-600">{{ errors.uom_id }}</p>
              </div>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-2">{{ t('tank.form.usedSteps') }}</label>
              <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2">
                <label
                  v-for="step in stepOptions"
                  :key="step.value"
                  class="flex items-center gap-2 px-3 py-2 border rounded-lg hover:bg-gray-50"
                >
                  <input
                    v-model="form.usedSteps"
                    type="checkbox"
                    :value="step.value"
                    class="h-4 w-4"
                  />
                  <span class="text-sm">{{ step.label }}</span>
                </label>
              </div>
              <p v-if="errors.usedSteps" class="mt-1 text-xs text-red-600">{{ errors.usedSteps }}</p>
            </div>
            <div class="flex items-center gap-2">
              <input id="tank-active" v-model="form.active" type="checkbox" class="h-4 w-4" />
              <label for="tank-active" class="text-sm text-gray-600">{{ t('tank.form.activeLabel') }}</label>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">
              {{ t('common.cancel') }}
            </button>
            <button
              class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
              :disabled="saving"
              @click="saveRecord"
            >
              {{ saving ? t('common.saving') : t('common.save') }}
            </button>
          </div>
        </div>
      </div>

      <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('tank.deleteTitle') }}</h3>
          </div>
          <div class="p-4 text-sm">
            {{ t('tank.deleteConfirm', { code: toDelete?.code ?? '' }) }}
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="showDelete = false">
              {{ t('common.cancel') }}
            </button>
            <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700" @click="deleteRecord">
              {{ t('common.delete') }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

type StepValue =
  | 'mashing'
  | 'lautering'
  | 'boil'
  | 'whirlpool'
  | 'cooling'
  | 'fermentation'
  | 'dry_hop'
  | 'cold_crash'
  | 'packaging'
  | 'transfer'
  | 'other'

type TankMeta = {
  type?: string
  name?: string
  size?: number | null
  usedSteps?: StepValue[]
}

type TankRow = {
  id: string
  code: string
  name: string
  category: string
  uom_id: string
  active: boolean
  created_at: string | null
  meta: TankMeta | null
  uom?: {
    id: string
    code: string
    name: string | null
  }
}

type TankDisplayRow = {
  id: string
  code: string
  tankName: string
  size: number | null
  uom_id: string
  uomCode: string
  active: boolean
  created_at: string | null
  usedSteps: StepValue[]
  meta: TankMeta | null
}

type SortKey = 'code' | 'tankName' | 'size' | 'uomCode' | 'active' | 'created_at'
type SortDirection = 'asc' | 'desc'

type UomOption = {
  id: string
  code: string
  name: string | null
}

const TANK_CATEGORY = 'equipment'
const TABLE = 'mst_materials'
const UOM_TABLE = 'mst_uom'

const STEP_VALUES: StepValue[] = [
  'mashing',
  'lautering',
  'boil',
  'whirlpool',
  'cooling',
  'fermentation',
  'dry_hop',
  'cold_crash',
  'packaging',
  'transfer',
  'other',
]

const { t, locale } = useI18n()
const pageTitle = computed(() => t('tank.title'))

const rows = ref<TankDisplayRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const toDelete = ref<TankDisplayRow | null>(null)

const searchTerm = ref('')
const sortKey = ref<SortKey>('code')
const sortDirection = ref<SortDirection>('asc')

const uomOptions = ref<UomOption[]>([])

const stepOptions = computed(() =>
  STEP_VALUES.map((value) => ({
    value,
    label: stepLabel(value),
  }))
)

const form = reactive({
  id: '',
  code: '',
  tankName: '',
  size: '',
  uom_id: '',
  usedSteps: [] as StepValue[],
  active: true,
})

const errors = reactive<Record<string, string>>({})

function resetForm() {
  form.id = ''
  form.code = ''
  form.tankName = ''
  form.size = ''
  form.uom_id = ''
  form.usedSteps = []
  form.active = true
  Object.keys(errors).forEach((key) => delete errors[key])
}

function stepLabel(step: StepValue) {
  const key = `tank.steps.${step}`
  const translated = t(key as any)
  return translated === key ? step : translated
}

function setSort(column: SortKey) {
  if (sortKey.value === column) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = column
    sortDirection.value = 'asc'
  }
}

const sortIcon = computed(() => (sortDirection.value === 'asc' ? '▲' : '▼'))

const filteredRows = computed(() => {
  const keyword = searchTerm.value.trim().toLowerCase()
  if (!keyword) return rows.value
  return rows.value.filter((row) => {
    return (
      row.code.toLowerCase().includes(keyword) ||
      row.tankName.toLowerCase().includes(keyword)
    )
  })
})

const sortedRows = computed(() => {
  const data = [...filteredRows.value]
  const direction = sortDirection.value === 'asc' ? 1 : -1
  const key = sortKey.value

  data.sort((a, b) => {
    let aVal: any = a[key]
    let bVal: any = b[key]

    if (key === 'active') {
      aVal = a.active ? 1 : 0
      bVal = b.active ? 1 : 0
    }

    if (key === 'created_at') {
      const aTime = a.created_at ? Date.parse(a.created_at) : 0
      const bTime = b.created_at ? Date.parse(b.created_at) : 0
      return (aTime - bTime) * direction
    }

    if (key === 'size') {
      const aSize = typeof a.size === 'number' ? a.size : -Infinity
      const bSize = typeof b.size === 'number' ? b.size : -Infinity
      return (aSize - bSize) * direction
    }

    if (aVal == null && bVal == null) return 0
    if (aVal == null) return 1 * direction
    if (bVal == null) return -1 * direction

    if (typeof aVal === 'number' && typeof bVal === 'number') {
      return (aVal - bVal) * direction
    }

    const aStr = String(aVal).toLowerCase()
    const bStr = String(bVal).toLowerCase()
    return aStr.localeCompare(bStr) * direction
  })

  return data
})

function openCreate() {
  editing.value = false
  resetForm()
  showModal.value = true
}

function openEdit(row: TankDisplayRow) {
  editing.value = true
  resetForm()
  form.id = row.id
  form.code = row.code
  form.tankName = row.tankName
  form.size = row.size != null ? String(row.size) : ''
  form.uom_id = row.uom_id
  form.usedSteps = [...row.usedSteps]
  form.active = row.active
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function confirmDelete(row: TankDisplayRow) {
  toDelete.value = row
  showDelete.value = true
}

function validate() {
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!form.code || form.code.trim() === '') {
    errors.code = t('errors.required', { field: t('labels.code') })
  }

  if (!form.tankName || form.tankName.trim() === '') {
    errors.tankName = t('errors.required', { field: t('tank.form.tankName') })
  }

  if (!form.uom_id) {
    errors.uom_id = t('errors.required', { field: t('labels.uom') })
  }

  if (form.size) {
    const numeric = Number(form.size)
    if (Number.isNaN(numeric)) {
      errors.size = t('errors.mustBeNumber', { field: t('tank.form.capacity') })
    } else if (numeric < 0) {
      errors.size = t('errors.rateMin', { field: t('tank.form.capacity') })
    }
  }

  return Object.keys(errors).length === 0
}

async function fetchUoms() {
  const { data, error } = await supabase
    .from<UomOption>(UOM_TABLE)
    .select('id, code, name')
    .order('code', { ascending: true })

  if (error) {
    toast.error(t('tank.errors.fetchUoms', { message: error.message }))
    return
  }

  uomOptions.value = data ?? []
}

function normalizeRow(row: TankRow): TankDisplayRow {
  const meta = row.meta ?? {}
  const tankName = (meta.name ?? row.name ?? '').trim()
  let sizeValue: number | null = null
  if (typeof meta.size === 'number') {
    sizeValue = meta.size
  } else if (typeof meta.size === 'string') {
    const numeric = Number(meta.size)
    sizeValue = Number.isNaN(numeric) ? null : numeric
  }
  const uomCode = row.uom?.code ?? ''
  const usedSteps = Array.isArray(meta.usedSteps) ? (meta.usedSteps.filter((step): step is StepValue => STEP_VALUES.includes(step as StepValue))) : []
  return {
    id: row.id,
    code: row.code,
    tankName,
    size: sizeValue,
    uom_id: row.uom_id,
    uomCode,
    active: Boolean(row.active),
    created_at: row.created_at,
    usedSteps,
    meta,
  }
}

function formatSize(value: number | null, uomCode: string) {
  if (value == null) return t('tank.table.noCapacity')
  const formatted = new Intl.NumberFormat(locale.value).format(value)
  return uomCode ? `${formatted} ${uomCode}` : formatted
}

async function fetchTanks() {
  loading.value = true
  const { data, error } = await supabase
    .from(TABLE)
    .select('id, code, name, category, uom_id, active, created_at, meta, uom:mst_uom(id, code, name)')
    .eq('category', TANK_CATEGORY)
    .contains('meta', { type: 'tank' })
    .order('code', { ascending: true })
  loading.value = false

  if (error) {
    toast.error(t('tank.errors.fetchTanks', { message: error.message }))
    return
  }

  const rowsRaw = (data ?? []) as TankRow[]
  rows.value = rowsRaw.map(normalizeRow)
}

async function saveRecord() {
  if (!validate()) return

  saving.value = true
  const sizeValue = form.size === '' ? null : Number(form.size)
  const meta: TankMeta = {
    type: 'tank',
    name: form.tankName.trim(),
    size: sizeValue,
    usedSteps: [...form.usedSteps],
  }

  const payload = {
    code: form.code.trim(),
    name: form.tankName.trim(),
    category: TANK_CATEGORY,
    uom_id: form.uom_id,
    active: Boolean(form.active),
    meta,
  }

  let response
  if (editing.value) {
    response = await supabase
      .from(TABLE)
      .update(payload)
      .eq('id', form.id)
      .select('id, code, name, category, uom_id, active, created_at, meta, uom:mst_uom(id, code, name)')
      .single()
  } else {
    response = await supabase
      .from(TABLE)
      .insert(payload)
      .select('id, code, name, category, uom_id, active, created_at, meta, uom:mst_uom(id, code, name)')
      .single()
  }

  saving.value = false

  if (response.error) {
    toast.error(t('tank.errors.save', { message: response.error.message }))
    return
  }

  const saved = response.data as TankRow
  const normalized = normalizeRow(saved)
  const index = rows.value.findIndex((row) => row.id === normalized.id)
  if (index > -1) {
    rows.value[index] = normalized
  } else {
    rows.value.push(normalized)
  }
  rows.value = [...rows.value]

  showModal.value = false
}

async function deleteRecord() {
  if (!toDelete.value) return

  const { error } = await supabase.from(TABLE).delete().eq('id', toDelete.value.id)
  if (error) {
    toast.error(t('tank.errors.delete', { message: error.message }))
    return
  }

  rows.value = rows.value.filter((row) => row.id !== toDelete.value?.id)
  showDelete.value = false
  toDelete.value = null
}

function formatTimestamp(value: string | null) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleString(locale.value)
}

onMounted(async () => {
  await Promise.all([fetchUoms(), fetchTanks()])
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
