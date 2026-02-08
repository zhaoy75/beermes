<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="max-w-6xl mx-auto p-4 space-y-4">
      <header class="flex flex-col gap-2">
        <h1 class="text-xl font-semibold text-gray-800">{{ t('equipment.title') }}</h1>
        <p class="text-sm text-gray-500">{{ t('equipment.subtitle') }}</p>
      </header>

      <section class="grid grid-cols-1 lg:grid-cols-[320px_1fr] gap-4">
        <aside class="bg-white border border-gray-200 rounded-xl shadow-sm p-4 space-y-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="equipmentCodeSearch">{{ t('equipment.filters.code') }}</label>
            <input
              id="equipmentCodeSearch"
              v-model.trim="filters.code"
              type="search"
              class="w-full h-[36px] border rounded px-3"
              :placeholder="t('equipment.filters.codePlaceholder')"
            />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="equipmentSiteSearch">{{ t('equipment.filters.site') }}</label>
            <select id="equipmentSiteSearch" v-model="filters.site" class="w-full h-[36px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in siteOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="equipmentKindSearch">{{ t('equipment.filters.kind') }}</label>
            <select id="equipmentKindSearch" v-model="filters.kind" class="w-full h-[36px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option value="tank">{{ t('equipment.kinds.tank') }}</option>
              <option value="other">{{ t('equipment.kinds.other') }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="equipmentStatusSearch">{{ t('equipment.filters.status') }}</label>
            <select id="equipmentStatusSearch" v-model="filters.status" class="w-full h-[36px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in statusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
          <div class="flex items-center gap-2">
            <button class="px-3 py-2 text-sm rounded bg-blue-600 text-white hover:bg-blue-700" type="button" @click="startCreate">
              {{ t('common.add') }}
            </button>
            <button
              class="px-3 py-2 text-sm rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-50"
              type="button"
              :disabled="!selectedRow"
              @click="confirmDelete"
            >
              {{ t('common.delete') }}
            </button>
            <button
              class="px-3 py-2 text-sm rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-50"
              type="button"
              :disabled="loading"
              @click="fetchEquipment"
            >
              {{ t('common.refresh') }}
            </button>
          </div>

          <div class="border-t border-gray-200 pt-3 space-y-2">
            <p v-if="!filteredRows.length" class="text-sm text-gray-500">{{ t('common.noData') }}</p>
            <div v-for="row in filteredRows" :key="row.id" class="border rounded-lg p-2">
              <button
                type="button"
                class="w-full text-left"
                :class="selectedId === row.id ? 'text-blue-700' : 'text-gray-700'"
                @click="selectRow(row)"
              >
                <div class="flex items-center justify-between">
                  <div>
                    <div class="text-xs font-mono">{{ row.equipment_code }}</div>
                    <div class="text-sm font-semibold">{{ displayName(row) || t('equipment.nameFallback') }}</div>
                  </div>
                  <span class="text-xs px-2 py-0.5 rounded-full" :class="statusBadgeClass(row.equipment_status)">
                    {{ statusLabel(row.equipment_status) }}
                  </span>
                </div>
                <div class="text-xs text-gray-500 mt-1">
                  {{ kindLabel(row.equipment_kind) }} • {{ siteLabel(row.site_id) }}
                </div>
              </button>
              <div class="mt-2 flex items-center gap-2">
                <button
                  class="px-2 py-1 text-xs rounded border hover:bg-gray-50"
                  type="button"
                  @click="openMaintenance(row)"
                >
                  {{ t('equipment.actions.maintenance') }}
                </button>
                <button
                  class="px-2 py-1 text-xs rounded border hover:bg-gray-50"
                  type="button"
                  @click="selectRow(row)"
                >
                  {{ t('common.edit') }}
                </button>
              </div>
            </div>
          </div>
        </aside>

        <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
          <header class="flex items-center justify-between mb-4">
            <div>
              <h2 class="text-lg font-semibold text-gray-800">
                {{ isEditing ? t('equipment.editTitle') : t('equipment.newTitle') }}
              </h2>
              <p class="text-xs text-gray-500">{{ selectedRow ? displayName(selectedRow) : t('equipment.detailHint') }}</p>
            </div>
            <button
              class="px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
              type="button"
              :disabled="saving"
              @click="saveRecord"
            >
              {{ saving ? t('common.saving') : t('common.save') }}
            </button>
          </header>

          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm text-gray-600 mb-1">
                {{ t('equipment.fields.code') }}<span class="text-red-600">*</span>
              </label>
              <input v-model.trim="form.equipment_code" :disabled="isEditing" class="w-full h-[40px] border rounded px-3" />
              <p v-if="errors.equipment_code" class="text-xs text-red-600 mt-1">{{ errors.equipment_code }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">
                {{ t('equipment.fields.kind') }}<span class="text-red-600">*</span>
              </label>
              <select v-model="form.equipment_kind" class="w-full h-[40px] border rounded px-3 bg-white" @change="handleKindChange">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in kindOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
              </select>
              <p v-if="errors.equipment_kind" class="text-xs text-red-600 mt-1">{{ errors.equipment_kind }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">
                {{ t('equipment.fields.nameEn') }}<span class="text-red-600">*</span>
              </label>
              <input v-model.trim="form.name_en" class="w-full h-[40px] border rounded px-3" />
              <p v-if="errors.name_en" class="text-xs text-red-600 mt-1">{{ errors.name_en }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('equipment.fields.nameJa') }}</label>
              <input v-model.trim="form.name_ja" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">
                {{ t('equipment.fields.site') }}<span class="text-red-600">*</span>
              </label>
              <select v-model="form.site_id" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in siteOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
              </select>
              <p v-if="errors.site_id" class="text-xs text-red-600 mt-1">{{ errors.site_id }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('equipment.fields.status') }}</label>
              <div class="h-[40px] flex items-center gap-2">
                <span class="text-xs px-2 py-0.5 rounded-full" :class="statusBadgeClass(form.equipment_status)">
                  {{ statusLabel(form.equipment_status) }}
                </span>
                <button class="text-xs px-2 py-1 rounded border" type="button" @click="openMaintenance(selectedRow || null)" :disabled="!selectedRow">
                  {{ t('equipment.actions.changeStatus') }}
                </button>
              </div>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('equipment.fields.active') }}</label>
              <label class="inline-flex items-center gap-2 text-sm text-gray-700">
                <input v-model="form.is_active" type="checkbox" class="h-4 w-4" />
                {{ form.is_active ? t('common.active') : t('common.inactive') }}
              </label>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('equipment.fields.commissionedAt') }}</label>
              <input v-model="form.commissioned_at" type="date" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('equipment.fields.decommissionedAt') }}</label>
              <input v-model="form.decommissioned_at" type="date" class="w-full h-[40px] border rounded px-3" />
              <p v-if="errors.decommissioned_at" class="text-xs text-red-600 mt-1">{{ errors.decommissioned_at }}</p>
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{ t('equipment.fields.description') }}</label>
              <textarea v-model.trim="form.description" rows="3" class="w-full border rounded px-3 py-2"></textarea>
            </div>
          </div>

          <div class="border-t border-gray-200 mt-6 pt-4" v-if="isTank">
            <h3 class="text-sm font-semibold text-gray-700 mb-3">{{ t('equipment.tank.title') }}</h3>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">
                  {{ t('equipment.tank.capacity') }}<span class="text-red-600">*</span>
                </label>
                <input v-model="tankForm.capacity_volume" type="number" step="any" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.capacity_volume" class="text-xs text-red-600 mt-1">{{ errors.capacity_volume }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">
                  {{ t('equipment.tank.volumeUom') }}<span class="text-red-600">*</span>
                </label>
                <select v-model="tankForm.volume_uom" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in volumeUomOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
                <p v-if="errors.volume_uom" class="text-xs text-red-600 mt-1">{{ errors.volume_uom }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('equipment.tank.maxWorkVolume') }}</label>
                <input v-model="tankForm.max_work_volume" type="number" step="any" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('equipment.tank.maxWorkUom') }}</label>
                <select v-model="tankForm.max_work_uom" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in volumeUomOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
                <p v-if="errors.max_work_uom" class="text-xs text-red-600 mt-1">{{ errors.max_work_uom }}</p>
              </div>
              <div class="md:col-span-2 grid grid-cols-1 md:grid-cols-3 gap-4">
                <label class="inline-flex items-center gap-2 text-sm text-gray-700">
                  <input v-model="tankForm.is_pressurized" type="checkbox" class="h-4 w-4" />
                  {{ t('equipment.tank.pressurized') }}
                </label>
                <label class="inline-flex items-center gap-2 text-sm text-gray-700">
                  <input v-model="tankForm.is_jacketed" type="checkbox" class="h-4 w-4" />
                  {{ t('equipment.tank.jacketed') }}
                </label>
                <label class="inline-flex items-center gap-2 text-sm text-gray-700">
                  <input v-model="tankForm.cip_supported" type="checkbox" class="h-4 w-4" />
                  {{ t('equipment.tank.cipSupported') }}
                </label>
              </div>
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1">{{ t('equipment.tank.attributes') }}</label>
                <textarea v-model.trim="tankForm.tank_attr_doc" rows="4" class="w-full border rounded px-3 py-2 font-mono text-xs"></textarea>
                <p v-if="errors.tank_attr_doc" class="text-xs text-red-600 mt-1">{{ errors.tank_attr_doc }}</p>
              </div>
            </div>
          </div>
        </section>
      </section>
    </div>

    <div v-if="maintenanceDialog.open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
        <header class="px-4 py-3 border-b flex items-center justify-between">
          <h3 class="font-semibold">{{ t('equipment.maintenance.title') }}</h3>
          <button class="text-sm px-2 py-1 rounded border hover:bg-gray-100" type="button" @click="closeMaintenance">
            {{ t('common.close') }}
          </button>
        </header>
        <section class="p-4 space-y-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('equipment.fields.status') }}</label>
            <select v-model="maintenanceDialog.status" class="w-full h-[40px] border rounded px-3 bg-white">
              <option v-for="option in statusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
        </section>
        <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
          <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="closeMaintenance">
            {{ t('common.cancel') }}
          </button>
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" type="button" @click="saveMaintenance">
            {{ t('common.save') }}
          </button>
        </footer>
      </div>
    </div>

    <div v-if="deleteDialog.open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
        <header class="px-4 py-3 border-b">
          <h3 class="font-semibold">{{ t('equipment.deleteTitle') }}</h3>
        </header>
        <section class="p-4 text-sm">
          {{ t('equipment.deleteConfirm', { code: selectedRow?.equipment_code ?? '' }) }}
        </section>
        <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
          <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="deleteDialog.open = false">
            {{ t('common.cancel') }}
          </button>
          <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700" type="button" @click="deleteSelected">
            {{ t('common.delete') }}
          </button>
        </footer>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

type EquipmentRow = {
  id: string
  equipment_code: string
  name_i18n: Record<string, string> | null
  description: string | null
  equipment_type_id: string | null
  equipment_kind: string | null
  site_id: string
  equipment_status: string
  commissioned_at: string | null
  decommissioned_at: string | null
  is_active: boolean
  sort_order: number
}

type TankRow = {
  equipment_id: string
  capacity_volume: number
  volume_uom: string
  max_work_volume: number | null
  max_work_uom: string | null
  is_pressurized: boolean
  is_jacketed: boolean
  cip_supported: boolean
  tank_attr_doc: Record<string, any> | null
}

type SiteRow = {
  id: string
  code: string
  name: string
}

type UomRow = {
  id: string
  code: string
  name: string | null
  dimension: string | null
}

const TABLE = 'mst_equipment'
const TANK_TABLE = 'mst_equipment_tank'
const { t, locale } = useI18n()
const pageTitle = computed(() => t('equipment.title'))

const rows = ref<EquipmentRow[]>([])
const sites = ref<SiteRow[]>([])
const volumeUoms = ref<UomRow[]>([])
const loading = ref(false)
const saving = ref(false)

const selectedId = ref<string | null>(null)
const selectedRow = ref<EquipmentRow | null>(null)
const tankLoaded = ref(false)
const hasTankProfile = ref(false)

const filters = reactive({
  code: '',
  site: '',
  kind: '',
  status: '',
})

const form = reactive({
  id: '',
  equipment_code: '',
  name_en: '',
  name_ja: '',
  description: '',
  equipment_type_id: '',
  equipment_kind: '',
  site_id: '',
  equipment_status: 'available',
  commissioned_at: '',
  decommissioned_at: '',
  is_active: true,
  sort_order: 0,
})

const tankForm = reactive({
  capacity_volume: '',
  volume_uom: 'L',
  max_work_volume: '',
  max_work_uom: '',
  is_pressurized: false,
  is_jacketed: false,
  cip_supported: true,
  tank_attr_doc: '',
})

const maintenanceDialog = reactive({
  open: false,
  status: 'available',
  targetId: '' as string | null,
})

const deleteDialog = reactive({
  open: false,
})

const errors = reactive<Record<string, string>>({})

const statusOptions = [
  { value: 'available', label: t('equipment.status.available') },
  { value: 'in_use', label: t('equipment.status.inUse') },
  { value: 'cleaning', label: t('equipment.status.cleaning') },
  { value: 'maintenance', label: t('equipment.status.maintenance') },
  { value: 'retired', label: t('equipment.status.retired') },
]

const kindOptions = [
  { value: 'tank', label: t('equipment.kinds.tank') },
  { value: 'pump', label: t('equipment.kinds.pump') },
  { value: 'filler', label: t('equipment.kinds.filler') },
  { value: 'labeler', label: t('equipment.kinds.labeler') },
  { value: 'kettle', label: t('equipment.kinds.kettle') },
  { value: 'mash_tun', label: t('equipment.kinds.mashTun') },
  { value: 'lauter_tun', label: t('equipment.kinds.lauterTun') },
  { value: 'chiller', label: t('equipment.kinds.chiller') },
  { value: 'other', label: t('equipment.kinds.other') },
]

const isEditing = computed(() => Boolean(form.id))
const isTank = computed(() => form.equipment_kind === 'tank')

const siteOptions = computed(() =>
  sites.value.map((site) => ({
    value: site.id,
    label: `${site.code} - ${site.name}`,
  }))
)

const volumeUomOptions = computed(() =>
  volumeUoms.value.map((row) => ({
    value: row.code,
    label: row.name ? `${row.code} - ${row.name}` : row.code,
  }))
)

const filteredRows = computed(() => {
  const code = filters.code.toLowerCase()
  return rows.value.filter((row) => {
    if (code && !row.equipment_code.toLowerCase().includes(code)) return false
    if (filters.site && row.site_id !== filters.site) return false
    if (filters.status && row.equipment_status !== filters.status) return false
    if (filters.kind) {
      if (filters.kind === 'tank') {
        if (row.equipment_kind !== 'tank') return false
      } else if (filters.kind === 'other') {
        if (row.equipment_kind === 'tank') return false
      }
    }
    return true
  })
})

function resolveLang() {
  return String(locale.value ?? '').toLowerCase().startsWith('ja') ? 'ja' : 'en'
}

function displayName(row: EquipmentRow) {
  const lang = resolveLang()
  if (row.name_i18n && row.name_i18n[lang]) return row.name_i18n[lang]
  const fallback = row.name_i18n ? Object.values(row.name_i18n)[0] : ''
  return fallback || ''
}

function kindLabel(kind: string | null) {
  if (!kind) return t('common.noData')
  const match = kindOptions.find((option) => option.value === kind)
  return match ? match.label : kind
}

function siteLabel(siteId: string) {
  const match = sites.value.find((row) => row.id === siteId)
  return match ? `${match.code} - ${match.name}` : t('common.noData')
}

function statusLabel(status: string) {
  const match = statusOptions.find((option) => option.value === status)
  return match ? match.label : status
}

function statusBadgeClass(status: string) {
  if (status === 'available') return 'bg-green-100 text-green-800'
  if (status === 'in_use') return 'bg-blue-100 text-blue-800'
  if (status === 'cleaning') return 'bg-yellow-100 text-yellow-800'
  if (status === 'maintenance') return 'bg-orange-100 text-orange-800'
  if (status === 'retired') return 'bg-gray-200 text-gray-600'
  return 'bg-gray-100 text-gray-600'
}

function resetForm() {
  Object.assign(form, {
    id: '',
    equipment_code: '',
    name_en: '',
    name_ja: '',
    description: '',
    equipment_type_id: '',
    equipment_kind: '',
    site_id: '',
    equipment_status: 'available',
    commissioned_at: '',
    decommissioned_at: '',
    is_active: true,
    sort_order: 0,
  })
  Object.assign(tankForm, {
    capacity_volume: '',
    volume_uom: 'L',
    max_work_volume: '',
    max_work_uom: '',
    is_pressurized: false,
    is_jacketed: false,
    cip_supported: true,
    tank_attr_doc: '',
  })
  Object.keys(errors).forEach((key) => delete errors[key])
  tankLoaded.value = false
  hasTankProfile.value = false
}

function startCreate() {
  selectedId.value = null
  selectedRow.value = null
  resetForm()
}

function selectRow(row: EquipmentRow) {
  selectedId.value = row.id
  selectedRow.value = row
  loadDetail(row)
}

function handleKindChange() {
  if (!isEditing.value) return
  if (form.equipment_kind === 'tank') return
  if (hasTankProfile.value && !window.confirm(t('equipment.confirmTankRemoval'))) {
    form.equipment_kind = 'tank'
  }
}

function parseNumber(value: string) {
  if (value === '' || value == null) return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function parseJsonInput(value: string, field: string) {
  if (!value.trim()) return null
  try {
    const parsed = JSON.parse(value)
    if (parsed && typeof parsed === 'object') return parsed
    errors[field] = t('equipment.errors.jsonObject')
    return null
  } catch {
    errors[field] = t('equipment.errors.jsonObject')
    return null
  }
}

async function loadDetail(row: EquipmentRow) {
  resetForm()
  Object.assign(form, {
    id: row.id,
    equipment_code: row.equipment_code,
    name_en: row.name_i18n?.en ?? '',
    name_ja: row.name_i18n?.ja ?? '',
    description: row.description ?? '',
    equipment_type_id: row.equipment_type_id ?? '',
    equipment_kind: row.equipment_kind ?? '',
    site_id: row.site_id,
    equipment_status: row.equipment_status ?? 'available',
    commissioned_at: row.commissioned_at ?? '',
    decommissioned_at: row.decommissioned_at ?? '',
    is_active: row.is_active ?? true,
    sort_order: row.sort_order ?? 0,
  })

  if (row.equipment_kind === 'tank') {
    await fetchTank(row.id)
  } else {
    tankLoaded.value = true
    hasTankProfile.value = false
  }
}

async function fetchTank(equipmentId: string) {
  try {
    tankLoaded.value = false
    const { data, error } = await supabase
      .from(TANK_TABLE)
      .select('equipment_id, capacity_volume, volume_uom, max_work_volume, max_work_uom, is_pressurized, is_jacketed, cip_supported, tank_attr_doc')
      .eq('equipment_id', equipmentId)
      .maybeSingle()
    if (error) throw error
    const row = data as TankRow | null
    if (row) {
      Object.assign(tankForm, {
        capacity_volume: row.capacity_volume != null ? String(row.capacity_volume) : '',
        volume_uom: row.volume_uom ?? 'L',
        max_work_volume: row.max_work_volume != null ? String(row.max_work_volume) : '',
        max_work_uom: row.max_work_uom ?? '',
        is_pressurized: row.is_pressurized ?? false,
        is_jacketed: row.is_jacketed ?? false,
        cip_supported: row.cip_supported ?? true,
        tank_attr_doc: row.tank_attr_doc ? JSON.stringify(row.tank_attr_doc, null, 2) : '',
      })
      hasTankProfile.value = true
    } else {
      hasTankProfile.value = false
    }
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    tankLoaded.value = true
  }
}

async function fetchEquipment() {
  try {
    loading.value = true
    const { data, error } = await supabase
      .from(TABLE)
      .select('id, equipment_code, name_i18n, description, equipment_type_id, equipment_kind, site_id, equipment_status, commissioned_at, decommissioned_at, is_active, sort_order')
      .order('equipment_code', { ascending: true })
    if (error) throw error
    rows.value = (data ?? []) as EquipmentRow[]
    if (selectedId.value) {
      const match = rows.value.find((row) => row.id === selectedId.value)
      if (match) {
        selectedRow.value = match
      } else {
        selectedId.value = null
        selectedRow.value = null
      }
    }
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
    rows.value = []
  } finally {
    loading.value = false
  }
}

async function fetchSites() {
  try {
    const { data, error } = await supabase
      .from('mst_sites')
      .select('id, code, name')
      .eq('active', true)
      .order('code', { ascending: true })
    if (error) throw error
    sites.value = (data ?? []) as SiteRow[]
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
}

async function fetchVolumeUoms() {
  try {
    const { data, error } = await supabase
      .from('mst_uom')
      .select('id, code, name, dimension')
      .eq('dimension', 'volume')
      .order('code', { ascending: true })
    if (error) throw error
    volumeUoms.value = (data ?? []) as UomRow[]
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
}

function validateForm() {
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!form.equipment_code.trim()) {
    errors.equipment_code = t('equipment.errors.required')
  }

  if (!form.name_en.trim() && !form.name_ja.trim()) {
    errors.name_en = t('equipment.errors.nameRequired')
  }

  if (!form.equipment_kind) {
    errors.equipment_kind = t('equipment.errors.required')
  }


  if (!form.site_id) {
    errors.site_id = t('equipment.errors.required')
  }

  if (form.decommissioned_at && form.commissioned_at && form.decommissioned_at < form.commissioned_at) {
    errors.decommissioned_at = t('equipment.errors.decommissionedAfter')
  }

  if (isTank.value) {
    const capacity = parseNumber(tankForm.capacity_volume)
    if (!capacity || capacity <= 0) {
      errors.capacity_volume = t('equipment.errors.capacity')
    }
    if (!tankForm.volume_uom) {
      errors.volume_uom = t('equipment.errors.required')
    }
    const maxWork = parseNumber(tankForm.max_work_volume)
    if (maxWork != null && capacity != null && maxWork > capacity) {
      errors.max_work_uom = t('equipment.errors.maxWorkOverCapacity')
    }
    if (tankForm.max_work_volume && !tankForm.max_work_uom) {
      errors.max_work_uom = t('equipment.errors.required')
    }
    if (tankForm.tank_attr_doc.trim()) {
      parseJsonInput(tankForm.tank_attr_doc, 'tank_attr_doc')
    }
  }

  return Object.keys(errors).length === 0
}

async function saveRecord() {
  if (!validateForm()) return

  try {
    saving.value = true

    const nameI18n: Record<string, string> = {}
    if (form.name_en.trim()) nameI18n.en = form.name_en.trim()
    if (form.name_ja.trim()) nameI18n.ja = form.name_ja.trim()

    const payload = {
      equipment_code: form.equipment_code.trim(),
      name_i18n: nameI18n,
      description: form.description.trim() || null,
      equipment_type_id: form.equipment_type_id || null,
      equipment_kind: form.equipment_kind || null,
      site_id: form.site_id,
      equipment_status: form.equipment_status || 'available',
      commissioned_at: form.commissioned_at || null,
      decommissioned_at: form.decommissioned_at || null,
      is_active: form.is_active,
      sort_order: form.sort_order ?? 0,
    }

    let equipmentId = form.id

    if (isEditing.value) {
      const { data, error } = await supabase
        .from(TABLE)
        .update(payload)
        .eq('id', form.id)
        .select()
        .single()
      if (error) throw error
      const updated = data as EquipmentRow
      equipmentId = updated.id
      await fetchEquipment()
      selectedRow.value = updated
      selectedId.value = updated.id
    } else {
      const { data, error } = await supabase
        .from(TABLE)
        .insert(payload)
        .select()
        .single()
      if (error) throw error
      const inserted = data as EquipmentRow
      equipmentId = inserted.id
      await fetchEquipment()
      selectedRow.value = inserted
      selectedId.value = inserted.id
      form.id = inserted.id
    }

    if (isTank.value) {
      const tankAttrDoc = tankForm.tank_attr_doc.trim() ? parseJsonInput(tankForm.tank_attr_doc, 'tank_attr_doc') : null
      if (errors.tank_attr_doc) throw new Error(t('equipment.errors.jsonObject'))
      const tankPayload = {
        equipment_id: equipmentId,
        capacity_volume: parseNumber(tankForm.capacity_volume),
        volume_uom: tankForm.volume_uom || 'L',
        max_work_volume: parseNumber(tankForm.max_work_volume),
        max_work_uom: tankForm.max_work_uom || null,
        is_pressurized: tankForm.is_pressurized,
        is_jacketed: tankForm.is_jacketed,
        cip_supported: tankForm.cip_supported,
        tank_attr_doc: tankAttrDoc ?? {},
      }
      const { error: tankError } = await supabase
        .from(TANK_TABLE)
        .upsert(tankPayload, { onConflict: 'equipment_id' })
      if (tankError) throw tankError
      hasTankProfile.value = true
    } else if (hasTankProfile.value && equipmentId) {
      const { error: tankDeleteError } = await supabase.from(TANK_TABLE).delete().eq('equipment_id', equipmentId)
      if (tankDeleteError) throw tankDeleteError
      hasTankProfile.value = false
    }

    toast.success(t('common.saved'))
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

function openMaintenance(row: EquipmentRow | null) {
  if (!row) return
  maintenanceDialog.open = true
  maintenanceDialog.status = row.equipment_status
  maintenanceDialog.targetId = row.id
}

function closeMaintenance() {
  maintenanceDialog.open = false
  maintenanceDialog.targetId = null
}

async function saveMaintenance() {
  if (!maintenanceDialog.targetId) return
  try {
    const { error } = await supabase
      .from(TABLE)
      .update({ equipment_status: maintenanceDialog.status })
      .eq('id', maintenanceDialog.targetId)
    if (error) throw error
    await fetchEquipment()
    if (selectedRow.value && selectedRow.value.id === maintenanceDialog.targetId) {
      form.equipment_status = maintenanceDialog.status
    }
    toast.success(t('common.saved'))
    closeMaintenance()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
}

function confirmDelete() {
  if (!selectedRow.value) return
  deleteDialog.open = true
}

async function deleteSelected() {
  if (!selectedRow.value) return
  try {
    const { error } = await supabase.from(TABLE).update({ is_active: false }).eq('id', selectedRow.value.id)
    if (error) throw error
    toast.success(t('common.saved'))
    deleteDialog.open = false
    await fetchEquipment()
    startCreate()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
}

onMounted(async () => {
  await Promise.all([fetchEquipment(), fetchSites(), fetchVolumeUoms()])
})
</script>
