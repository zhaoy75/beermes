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
              <div class="md:col-span-2 space-y-3">
                <label class="block text-sm text-gray-600 mb-1">{{ t('equipment.tank.calibrationTable') }}</label>
                <div class="rounded-xl border border-gray-200 bg-gray-50 p-3 space-y-3">
                  <div class="grid grid-cols-1 md:grid-cols-[minmax(0,1fr)_minmax(0,1fr)_16rem] gap-3">
                    <div>
                      <label class="block text-xs text-gray-500 mb-1">
                        {{ t('equipment.tank.calibration.referenceTemperature') }}
                      </label>
                      <input
                        v-model.trim="calibrationEditor.reference_temperature_c"
                        type="number"
                        step="0.001"
                        class="w-full h-[38px] border rounded px-3 bg-white"
                      />
                    </div>
                    <div>
                      <label class="block text-xs text-gray-500 mb-1">
                        {{ t('equipment.tank.calibration.thermalExpansion') }}
                      </label>
                      <input
                        v-model.trim="calibrationEditor.thermal_expansion_coef_per_c"
                        type="number"
                        step="0.000001"
                        class="w-full h-[38px] border rounded px-3 bg-white"
                        :placeholder="t('equipment.tank.calibration.optional')"
                      />
                    </div>
                    <div class="rounded-lg border border-gray-200 bg-white px-3 py-2 text-xs text-gray-600 space-y-1">
                      <div class="flex items-center justify-between gap-3">
                        <span>{{ t('equipment.tank.calibration.pointCount') }}</span>
                        <span class="font-medium text-gray-900">{{ calibrationPointCount }}</span>
                      </div>
                      <div class="flex items-center justify-between gap-3">
                        <span>{{ t('equipment.tank.calibration.maxDepth') }}</span>
                        <span class="font-medium text-gray-900">{{ formatCalibrationMetric(calibrationMaxDepth) }}</span>
                      </div>
                      <div class="flex items-center justify-between gap-3">
                        <span>{{ t('equipment.tank.calibration.maxVolume') }}</span>
                        <span class="font-medium text-gray-900">{{ formatCalibrationMetric(calibrationMaxVolume) }}</span>
                      </div>
                    </div>
                  </div>

                  <div class="overflow-x-auto rounded-lg border border-gray-200 bg-white">
                    <table class="min-w-full text-sm">
                      <thead class="bg-gray-100 text-xs uppercase text-gray-500">
                        <tr>
                          <th class="px-3 py-2 text-left w-14">#</th>
                          <th class="px-3 py-2 text-left min-w-[10rem]">
                            {{ t('equipment.tank.calibration.depthMm') }}
                          </th>
                          <th class="px-3 py-2 text-left min-w-[10rem]">
                            {{ t('equipment.tank.calibration.volumeL') }}
                          </th>
                          <th class="px-3 py-2 text-left w-24">
                            {{ t('common.actions') }}
                          </th>
                        </tr>
                      </thead>
                      <tbody class="divide-y divide-gray-100">
                        <tr
                          v-for="(row, index) in calibrationRows"
                          :key="row.id"
                          class="align-top"
                        >
                          <td class="px-3 py-2 text-xs text-gray-500">{{ index + 1 }}</td>
                          <td class="px-3 py-2">
                            <input
                              v-model.trim="row.depth_mm"
                              type="number"
                              step="0.001"
                              class="w-full h-[36px] border rounded px-3"
                              :class="calibrationRowErrors[row.id]?.depth_mm ? 'border-red-300 bg-red-50' : ''"
                              @keydown.enter.prevent="handleCalibrationEnter(index)"
                            />
                            <p v-if="calibrationRowErrors[row.id]?.depth_mm" class="mt-1 text-xs text-red-600">
                              {{ calibrationRowErrors[row.id]?.depth_mm }}
                            </p>
                          </td>
                          <td class="px-3 py-2">
                            <input
                              v-model.trim="row.volume_l"
                              type="number"
                              step="0.001"
                              class="w-full h-[36px] border rounded px-3"
                              :class="calibrationRowErrors[row.id]?.volume_l ? 'border-red-300 bg-red-50' : ''"
                              @keydown.enter.prevent="handleCalibrationEnter(index)"
                            />
                            <p v-if="calibrationRowErrors[row.id]?.volume_l" class="mt-1 text-xs text-red-600">
                              {{ calibrationRowErrors[row.id]?.volume_l }}
                            </p>
                          </td>
                          <td class="px-3 py-2">
                            <button
                              class="px-2 py-1 text-xs rounded border hover:bg-gray-50"
                              type="button"
                              @click="removeCalibrationRow(index)"
                            >
                              {{ t('common.delete') }}
                            </button>
                          </td>
                        </tr>
                      </tbody>
                    </table>
                  </div>

                  <div class="flex flex-wrap items-center gap-2">
                    <button
                      class="px-3 py-2 text-xs rounded border border-gray-300 bg-white hover:bg-gray-50"
                      type="button"
                      @click="addCalibrationRow"
                    >
                      {{ t('equipment.tank.calibration.addRow') }}
                    </button>
                    <button
                      class="px-3 py-2 text-xs rounded border border-gray-300 bg-white hover:bg-gray-50"
                      type="button"
                      @click="sortCalibrationRows"
                    >
                      {{ t('equipment.tank.calibration.sortByDepth') }}
                    </button>
                    <button
                      class="px-3 py-2 text-xs rounded border border-gray-300 bg-white hover:bg-gray-50"
                      type="button"
                      @click="resetCalibrationEditor"
                    >
                      {{ t('common.reset') }}
                    </button>
                  </div>

                  <p v-if="errors.calibration_table" class="text-xs text-red-600">
                    {{ errors.calibration_table }}
                  </p>

                  <details class="rounded-lg border border-dashed border-gray-300 bg-white p-3">
                    <summary class="cursor-pointer text-xs font-medium text-gray-600">
                      {{ t('equipment.tank.calibration.jsonPreview') }}
                    </summary>
                    <pre class="mt-3 overflow-x-auto rounded bg-gray-50 p-3 text-xs text-gray-700">{{ calibrationTablePreview || '{}' }}</pre>
                  </details>
                </div>
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
import ConfirmActionDialog from '@/components/common/ConfirmActionDialog.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { useConfirmDialog } from '@/composables/useConfirmDialog'
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
  calibration_table: Record<string, any> | null
}

type SiteRow = {
  id: string
  name: string
}

type UomRow = {
  id: string
  code: string
  name: string | null
  dimension: string | null
}

type CalibrationEditorRow = {
  id: string
  depth_mm: string
  volume_l: string
}

const { confirmDialog, requestConfirmation, cancelConfirmation, acceptConfirmation } = useConfirmDialog()

type CalibrationRowError = {
  depth_mm?: string
  volume_l?: string
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
  calibration_table: '',
})

const calibrationEditor = reactive({
  reference_temperature_c: '20',
  thermal_expansion_coef_per_c: '',
})

const calibrationRows = ref<CalibrationEditorRow[]>([])

const maintenanceDialog = reactive({
  open: false,
  status: 'available',
  targetId: '' as string | null,
})

const deleteDialog = reactive({
  open: false,
})

const errors = reactive<Record<string, string>>({})
let calibrationRowSequence = 0

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
    label: site.name || site.id,
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
  return match?.name || t('common.noData')
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

function nextCalibrationRowId() {
  calibrationRowSequence += 1
  return `calibration-${calibrationRowSequence}`
}

function createCalibrationRow(depth = '', volume = ''): CalibrationEditorRow {
  return {
    id: nextCalibrationRowId(),
    depth_mm: depth,
    volume_l: volume,
  }
}

function ensureCalibrationRowMinimum() {
  while (calibrationRows.value.length < 2) {
    calibrationRows.value.push(createCalibrationRow())
  }
}

function resetCalibrationEditor() {
  calibrationEditor.reference_temperature_c = '20'
  calibrationEditor.thermal_expansion_coef_per_c = ''
  calibrationRows.value = [createCalibrationRow('0', '0'), createCalibrationRow()]
  tankForm.calibration_table = ''
}

function rowHasCalibrationValue(row: CalibrationEditorRow) {
  return (
    normalizeTextValue(row.depth_mm).trim() !== '' ||
    normalizeTextValue(row.volume_l).trim() !== ''
  )
}

function isCalibrationTemplateOnly(row: CalibrationEditorRow) {
  return parseNumber(row.depth_mm) === 0 && parseNumber(row.volume_l) === 0
}

function isCalibrationEditorEmpty() {
  const activeRows = calibrationRows.value.filter((row) => rowHasCalibrationValue(row))
  if (activeRows.length === 0) return true
  if (
    activeRows.length === 1 &&
    isCalibrationTemplateOnly(activeRows[0]) &&
    (parseNumber(calibrationEditor.reference_temperature_c) ?? 20) === 20 &&
    normalizeTextValue(calibrationEditor.thermal_expansion_coef_per_c).trim() === ''
  ) {
    return true
  }
  return false
}

function hydrateCalibrationEditor(calibrationTable: Record<string, any> | null) {
  if (!calibrationTable || typeof calibrationTable !== 'object') {
    resetCalibrationEditor()
    return
  }

  const referenceTemperature = parseNumber(String(calibrationTable.reference_temperature_c ?? ''))
  const thermalExpansion = parseNumber(String(calibrationTable.thermal_expansion_coef_per_c ?? ''))
  calibrationEditor.reference_temperature_c =
    referenceTemperature != null ? String(referenceTemperature) : '20'
  calibrationEditor.thermal_expansion_coef_per_c =
    thermalExpansion != null ? String(thermalExpansion) : ''

  const points = Array.isArray(calibrationTable.points) ? calibrationTable.points : []
  calibrationRows.value = points.map((point) =>
    createCalibrationRow(
      point?.depth_mm != null ? String(point.depth_mm) : '',
      point?.volume_l != null ? String(point.volume_l) : '',
    ),
  )
  if (calibrationRows.value.length === 0) {
    calibrationRows.value = [createCalibrationRow('0', '0')]
  }
  ensureCalibrationRowMinimum()
  tankForm.calibration_table = JSON.stringify(calibrationTable, null, 2)
}

function buildCalibrationTablePayload() {
  if (isCalibrationEditorEmpty()) return null
  const activeRows = calibrationRows.value.filter((row) => rowHasCalibrationValue(row))

  const points = activeRows
    .map((row) => ({
      depth_mm: parseNumber(row.depth_mm),
      volume_l: parseNumber(row.volume_l),
    }))
    .filter(
      (
        point,
      ): point is {
        depth_mm: number
        volume_l: number
      } => point.depth_mm != null && point.volume_l != null,
    )
    .sort((a, b) => a.depth_mm - b.depth_mm)

  const payload: Record<string, any> = {
    version: 1,
    reference_temperature_c: parseNumber(calibrationEditor.reference_temperature_c) ?? 20,
    points,
  }

  const thermalExpansion = parseNumber(calibrationEditor.thermal_expansion_coef_per_c)
  if (thermalExpansion != null) {
    payload.thermal_expansion_coef_per_c = thermalExpansion
  }

  return payload
}

const calibrationValidation = computed(() => {
  if (isCalibrationEditorEmpty()) {
    return {
      rowErrors: {} as Record<string, CalibrationRowError>,
      formError: '',
      activeCount: 0,
      maxDepth: null,
      maxVolume: null,
    }
  }
  const rowErrors: Record<string, CalibrationRowError> = {}
  const activeRows = calibrationRows.value.filter((row) => rowHasCalibrationValue(row))

  const parsedRows = activeRows.map((row) => {
    const depth = parseNumber(row.depth_mm)
    const volume = parseNumber(row.volume_l)
    const error: CalibrationRowError = {}

    if (depth == null) error.depth_mm = t('equipment.errors.calibrationDepthNumeric')
    else if (depth < 0) error.depth_mm = t('equipment.errors.calibrationDepthNonNegative')

    if (volume == null) error.volume_l = t('equipment.errors.calibrationVolumeNumeric')
    else if (volume < 0) error.volume_l = t('equipment.errors.calibrationVolumeNonNegative')

    if (error.depth_mm || error.volume_l) rowErrors[row.id] = error

    return {
      row,
      depth,
      volume,
      invalid: Boolean(error.depth_mm || error.volume_l),
    }
  })

  const validRows = parsedRows
    .filter((entry) => !entry.invalid && entry.depth != null && entry.volume != null)
    .sort((a, b) => (a.depth as number) - (b.depth as number))

  for (let index = 1; index < validRows.length; index += 1) {
    const prev = validRows[index - 1]
    const current = validRows[index]
    if ((current.depth as number) === (prev.depth as number)) {
      rowErrors[current.row.id] = {
        ...(rowErrors[current.row.id] ?? {}),
        depth_mm: t('equipment.errors.calibrationDepthUnique'),
      }
    }
    if ((current.volume as number) < (prev.volume as number)) {
      rowErrors[current.row.id] = {
        ...(rowErrors[current.row.id] ?? {}),
        volume_l: t('equipment.errors.calibrationVolumeMonotone'),
      }
    }
  }

  const maxDepth = validRows.length
    ? Math.max(...validRows.map((entry) => entry.depth as number))
    : null
  const maxVolume = validRows.length
    ? Math.max(...validRows.map((entry) => entry.volume as number))
    : null

  let formError = ''
  if (activeRows.length > 0 && activeRows.length < 2) {
    formError = t('equipment.errors.calibrationMinPoints')
  } else if (Object.keys(rowErrors).length > 0) {
    formError = t('equipment.errors.calibrationReview')
  }

  return {
    rowErrors,
    formError,
    activeCount: activeRows.length,
    maxDepth,
    maxVolume,
  }
})

const calibrationRowErrors = computed(() => calibrationValidation.value.rowErrors)
const calibrationPointCount = computed(() => calibrationValidation.value.activeCount)
const calibrationMaxDepth = computed(() => calibrationValidation.value.maxDepth)
const calibrationMaxVolume = computed(() => calibrationValidation.value.maxVolume)
const calibrationTablePreview = computed(() => {
  const payload = buildCalibrationTablePayload()
  return payload ? JSON.stringify(payload, null, 2) : ''
})

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
    calibration_table: '',
  })
  resetCalibrationEditor()
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

async function handleKindChange() {
  if (!isEditing.value) return
  if (form.equipment_kind === 'tank') return
  if (hasTankProfile.value) {
    const confirmed = await requestConfirmation({
      title: t('common.continue'),
      message: t('equipment.confirmTankRemoval'),
      confirmLabel: t('common.continue'),
      tone: 'warning',
    })
    if (confirmed) return
    form.equipment_kind = 'tank'
  }
}

function normalizeTextValue(value: unknown) {
  if (value == null) return ''
  return String(value)
}

function parseNumber(value: unknown) {
  const normalized = normalizeTextValue(value).trim()
  if (normalized === '') return null
  const num = Number(normalized)
  return Number.isFinite(num) ? num : null
}

function formatCalibrationMetric(value: number | null) {
  if (value == null) return '—'
  return Number.isInteger(value) ? String(value) : value.toFixed(3)
}

function addCalibrationRow() {
  calibrationRows.value.push(createCalibrationRow())
}

function removeCalibrationRow(index: number) {
  calibrationRows.value.splice(index, 1)
  ensureCalibrationRowMinimum()
}

function sortCalibrationRows() {
  const activeRows = calibrationRows.value.filter((row) => rowHasCalibrationValue(row))
  const emptyRows = calibrationRows.value.filter((row) => !rowHasCalibrationValue(row))
  activeRows.sort((a, b) => {
    const aDepth = parseNumber(a.depth_mm)
    const bDepth = parseNumber(b.depth_mm)
    if (aDepth == null && bDepth == null) return 0
    if (aDepth == null) return 1
    if (bDepth == null) return -1
    return aDepth - bDepth
  })
  calibrationRows.value = [...activeRows, ...emptyRows]
  ensureCalibrationRowMinimum()
}

function handleCalibrationEnter(index: number) {
  if (index === calibrationRows.value.length - 1) {
    addCalibrationRow()
  }
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
      .select('equipment_id, capacity_volume, volume_uom, max_work_volume, max_work_uom, is_pressurized, is_jacketed, cip_supported, tank_attr_doc, calibration_table')
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
        calibration_table: row.calibration_table ? JSON.stringify(row.calibration_table, null, 2) : '',
      })
      hydrateCalibrationEditor(row.calibration_table ?? null)
      hasTankProfile.value = true
    } else {
      resetCalibrationEditor()
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
      .select('id, name')
      .eq('active', true)
      .order('name', { ascending: true })
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
    const calibrationError = calibrationValidation.value.formError
    if (calibrationError) {
      errors.calibration_table = calibrationError
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
      const calibrationTable = buildCalibrationTablePayload()
      tankForm.calibration_table = calibrationTable ? JSON.stringify(calibrationTable, null, 2) : ''
      if (errors.tank_attr_doc) throw new Error(t('equipment.errors.jsonObject'))
      if (errors.calibration_table) throw new Error(errors.calibration_table)
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
        calibration_table: calibrationTable ?? {},
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
