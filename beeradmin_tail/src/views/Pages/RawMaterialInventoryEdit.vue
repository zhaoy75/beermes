<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white p-4 text-gray-900">
      <div class="mx-auto max-w-5xl space-y-6">
        <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h1 class="text-xl font-semibold">{{ pageTitle }}</h1>
            <p class="text-sm text-gray-500">{{ pageSubtitle }}</p>
          </div>
          <button
            type="button"
            class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50"
            @click="goBack"
          >
            {{ t('common.cancel') }}
          </button>
        </header>

        <section class="rounded-xl border border-gray-200 bg-white shadow-sm">
          <div v-if="loadError" class="border-b border-red-100 bg-red-50 px-4 py-3 text-sm text-red-700">
            {{ loadError }}
          </div>

          <form class="space-y-6 p-4" @submit.prevent="saveRecord">
            <section v-if="mode === 'move'" class="rounded-lg border border-amber-200 bg-amber-50 px-4 py-4">
              <div class="flex flex-col gap-2 md:flex-row md:items-start md:justify-between">
                <div>
                  <h2 class="text-sm font-semibold text-amber-900">{{ t('rawMaterialInventoryEdit.movePanelTitle') }}</h2>
                  <p class="mt-1 text-xs text-amber-800">{{ t('rawMaterialInventoryEdit.movePanelSubtitle') }}</p>
                </div>
                <span class="inline-flex rounded-full bg-white px-2.5 py-1 text-xs font-medium text-amber-800 ring-1 ring-amber-200">
                  {{ originalLot?.lot_no || lotId || '—' }}
                </span>
              </div>
              <dl class="mt-4 grid grid-cols-1 gap-3 text-sm md:grid-cols-3">
                <div class="rounded border border-amber-100 bg-white px-3 py-2">
                  <dt class="text-xs text-gray-500">{{ t('rawMaterialInventoryEdit.fields.material') }}</dt>
                  <dd class="mt-1 font-medium text-gray-900">{{ selectedMaterialDisplay }}</dd>
                </div>
                <div class="rounded border border-amber-100 bg-white px-3 py-2">
                  <dt class="text-xs text-gray-500">{{ t('rawMaterialInventoryEdit.fields.currentLocation') }}</dt>
                  <dd class="mt-1 font-medium text-gray-900">{{ currentLocationLabel }}</dd>
                </div>
                <div class="rounded border border-amber-100 bg-white px-3 py-2">
                  <dt class="text-xs text-gray-500">{{ t('rawMaterialInventoryEdit.fields.currentQty') }}</dt>
                  <dd class="mt-1 font-medium text-gray-900">{{ currentQtyDisplay }}</dd>
                </div>
              </dl>
            </section>

            <section class="grid grid-cols-1 gap-4 md:grid-cols-2">
              <div>
                <label class="mb-1 block text-sm text-gray-600">
                  {{ t('rawMaterialInventoryEdit.fields.materialType') }}<span class="text-red-600">*</span>
                </label>
                <select
                  v-model="form.material_type_id"
                  class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
                  :disabled="mode !== 'create'"
                  @change="handleMaterialTypeChange"
                >
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in materialTypeOptions" :key="option.value" :value="option.value">
                    {{ option.label }}
                  </option>
                </select>
                <p v-if="errors.material_type_id" class="mt-1 text-xs text-red-600">{{ errors.material_type_id }}</p>
              </div>

              <div>
                <label class="mb-1 block text-sm text-gray-600">
                  {{ t('rawMaterialInventoryEdit.fields.material') }}<span class="text-red-600">*</span>
                </label>
                <select
                  v-model="form.material_id"
                  class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
                  :disabled="mode !== 'create'"
                  @change="handleMaterialChange"
                >
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in filteredMaterialOptions" :key="option.id" :value="option.id">
                    {{ option.material_code }} - {{ option.material_name }}
                  </option>
                </select>
                <p v-if="errors.material_id" class="mt-1 text-xs text-red-600">{{ errors.material_id }}</p>
              </div>

              <div>
                <label class="mb-1 block text-sm text-gray-600">
                  {{ mode === 'move' ? t('rawMaterialInventoryEdit.fields.currentQty') : t('rawMaterialInventoryEdit.fields.qty') }}
                  <span class="text-red-600">*</span>
                </label>
                <input
                  v-model.trim="form.qty"
                  type="number"
                  min="0"
                  step="0.01"
                  class="h-[40px] w-full rounded border border-gray-300 px-3"
                  :readonly="mode === 'move'"
                />
                <p v-if="selectedUomLabel" class="mt-1 text-xs text-gray-500">{{ selectedUomLabel }}</p>
                <p v-if="errors.qty" class="mt-1 text-xs text-red-600">{{ errors.qty }}</p>
              </div>

              <div v-if="mode === 'move'">
                <label class="mb-1 block text-sm text-gray-600">{{ t('rawMaterialInventoryEdit.fields.currentLocation') }}</label>
                <input :value="currentLocationLabel" type="text" class="h-[40px] w-full rounded border border-gray-300 bg-gray-50 px-3" readonly />
              </div>

              <div v-else>
                <label class="mb-1 block text-sm text-gray-600">
                  {{ t('rawMaterialInventoryEdit.fields.location') }}<span class="text-red-600">*</span>
                </label>
                <select
                  v-model="form.site_id"
                  class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
                  :disabled="mode === 'edit'"
                >
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in siteOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
                <p v-if="errors.site_id" class="mt-1 text-xs text-red-600">{{ errors.site_id }}</p>
              </div>

              <div v-if="mode === 'move'">
                <label class="mb-1 block text-sm text-gray-600">
                  {{ t('rawMaterialInventoryEdit.fields.destinationLocation') }}<span class="text-red-600">*</span>
                </label>
                <select v-model="form.dest_site_id" class="h-[40px] w-full rounded border border-gray-300 bg-white px-3">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in siteOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
                <p v-if="errors.dest_site_id" class="mt-1 text-xs text-red-600">{{ errors.dest_site_id }}</p>
              </div>
            </section>

            <section class="rounded-lg border border-gray-200 bg-gray-50">
              <header class="border-b border-gray-200 px-4 py-3">
                <h2 class="text-sm font-semibold text-gray-900">{{ t('rawMaterialInventoryEdit.attributeTitle') }}</h2>
                <p class="mt-1 text-xs text-gray-500">{{ t('rawMaterialInventoryEdit.attributeSubtitle') }}</p>
              </header>

              <div v-if="attrLoading" class="px-4 py-6 text-sm text-gray-500">{{ t('common.loading') }}</div>
              <div v-else-if="attrFields.length === 0" class="px-4 py-6 text-sm text-gray-500">{{ t('rawMaterialInventoryEdit.attributeEmpty') }}</div>
              <div v-else class="space-y-6 px-4 py-4">
                <section v-for="group in attrSections" :key="group.section" class="space-y-3">
                  <div class="text-xs font-semibold uppercase tracking-wide text-gray-500">{{ group.section }}</div>
                  <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                    <div v-for="field in group.fields" :key="field.attr_id" :class="attrInputKind(field) === 'json' ? 'md:col-span-2' : ''">
                      <label class="mb-1 block text-sm text-gray-600">
                        {{ attrLabel(field) }}<span v-if="field.required" class="text-red-600">*</span>
                        <span v-if="field.uom_code" class="ml-1 text-xs text-gray-400">({{ field.uom_code }})</span>
                      </label>

                      <input
                        v-if="attrInputKind(field) === 'text'"
                        :value="attrTextValue(field)"
                        type="text"
                        class="h-[40px] w-full rounded border border-gray-300 px-3"
                        @input="updateAttrText(field, $event)"
                      />
                      <input
                        v-else-if="attrInputKind(field) === 'number'"
                        :value="attrTextValue(field)"
                        type="number"
                        :min="field.num_min ?? undefined"
                        :max="field.num_max ?? undefined"
                        class="h-[40px] w-full rounded border border-gray-300 px-3"
                        @input="updateAttrText(field, $event)"
                      />
                      <select
                        v-else-if="attrInputKind(field) === 'select'"
                        :value="attrTextValue(field)"
                        class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
                        @change="updateAttrText(field, $event)"
                      >
                        <option value="">{{ t('common.select') }}</option>
                        <option v-for="option in attrAllowedOptions(field)" :key="String(option.value)" :value="String(option.value)">
                          {{ option.label }}
                        </option>
                      </select>
                      <label v-else-if="attrInputKind(field) === 'boolean'" class="inline-flex h-[40px] items-center gap-2">
                        <input type="checkbox" class="h-4 w-4 rounded border-gray-300" :checked="Boolean(field.value)" @change="updateAttrBoolean(field, $event)" />
                        <span class="text-sm text-gray-700">{{ t('common.active') }}</span>
                      </label>
                      <textarea
                        v-else-if="attrInputKind(field) === 'json'"
                        :value="attrTextValue(field)"
                        rows="4"
                        class="w-full rounded border border-gray-300 px-3 py-2 font-mono text-sm"
                        @input="updateAttrText(field, $event)"
                      />
                      <input
                        v-else-if="attrInputKind(field) === 'date'"
                        :value="attrTextValue(field)"
                        type="date"
                        class="h-[40px] w-full rounded border border-gray-300 px-3"
                        @input="updateAttrText(field, $event)"
                      />
                      <input
                        v-else-if="attrInputKind(field) === 'timestamp'"
                        :value="attrTextValue(field)"
                        type="datetime-local"
                        class="h-[40px] w-full rounded border border-gray-300 px-3"
                        @input="updateAttrText(field, $event)"
                      />
                      <input
                        v-else
                        :value="attrTextValue(field)"
                        type="text"
                        class="h-[40px] w-full rounded border border-gray-300 px-3"
                        @input="updateAttrText(field, $event)"
                      />

                      <p v-if="field.help_text || field.description" class="mt-1 text-xs text-gray-500">{{ field.help_text || field.description }}</p>
                      <p v-if="field.error" class="mt-1 text-xs text-red-600">{{ field.error }}</p>
                    </div>
                  </div>
                </section>
              </div>
            </section>

            <div class="flex items-center justify-end gap-2 border-t border-gray-200 pt-4">
              <button type="button" class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50" @click="goBack">
                {{ t('common.cancel') }}
              </button>
              <button type="submit" class="rounded bg-blue-600 px-3 py-2 text-sm text-white hover:bg-blue-700 disabled:opacity-60" :disabled="saving || loading">
                {{ saving ? t('common.saving') : primaryActionLabel }}
              </button>
            </div>
          </form>
        </section>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import { normalizeBatchAttrDataType, validateBatchAttrField } from '@/lib/batchAttrValidation'

type NameI18n = {
  ja?: string | null
  en?: string | null
} | null

type EditorMode = 'create' | 'edit' | 'move'

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

type SiteOption = {
  value: string
  label: string
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

type MovementLineResultRow = {
  movement_id: string
  qty: number
  meta: unknown
}

type MovementHeaderRow = {
  id: string
  status: string
  src_site_id: string | null
  dest_site_id: string | null
}

type AttrDefRow = {
  attr_id: number
  code: string
  name: string
  name_i18n?: NameI18n
  data_type: string
  description?: string | null
  is_active?: boolean
  required?: boolean
  uom_id: string | null
  num_min: number | null
  num_max: number | null
  text_regex: string | null
  allowed_values: unknown | null
  ref_kind: string | null
  ref_domain: string | null
}

type AttrRuleRow = {
  attr_set_id: number
  attr_id: number
  required: boolean
  sort_order: number | null
  is_active: boolean
  ui_section?: string | null
  ui_widget?: string | null
  help_text?: string | null
  attr_def: AttrDefRow | AttrDefRow[] | null
}

type AttrField = {
  attr_id: number
  code: string
  name: string
  name_i18n: NameI18n
  data_type: string
  required: boolean
  ui_section: string
  ui_widget: string
  help_text: string
  description: string
  uom_id: string | null
  uom_code: string | null
  num_min: number | null
  num_max: number | null
  text_regex: string | null
  allowed_values: unknown | null
  ref_kind: string | null
  ref_domain: string | null
  value: string | boolean
  options: Array<{ value: string | number, label: string }>
  error: string
}

type EntityAttrValueRow = {
  attr_id: number
  value_text?: string | null
  value_num?: number | null
  value_bool?: boolean | null
  value_date?: string | null
  value_ts?: string | null
  value_json?: unknown
  value_ref_type_id?: string | null
}

type TypeRefOptionRow = {
  type_id: string
  code: string
  name: string | null
}

type RegistryRefOptionRow = {
  def_id: number | string
  def_key: string
  spec?: {
    name?: string | null
  } | null
}

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()
const mesClient = () => supabase.schema('mes')

const tenantId = ref('')
const loading = ref(false)
const saving = ref(false)
const loadError = ref('')

const materialTypes = ref<MaterialTypeRow[]>([])
const materialRows = ref<MaterialRow[]>([])
const siteOptions = ref<SiteOption[]>([])
const uomRows = ref<UomRow[]>([])
const attrFields = ref<AttrField[]>([])
const attrLoading = ref(false)
const refOptionsCache = new Map<string, Array<{ value: string | number, label: string }>>()
const originalLot = ref<LotRow | null>(null)
const originalQty = ref(0)

const form = reactive({
  material_type_id: '',
  material_id: '',
  qty: '',
  site_id: '',
  dest_site_id: '',
  uom_id: '',
})

const errors = reactive<Record<string, string>>({})

const lotId = computed(() => {
  const value = route.params.lotId
  return typeof value === 'string' && value.trim().length > 0 ? value : ''
})

const mode = computed<EditorMode>(() => {
  if (!lotId.value) return 'create'
  return route.query.mode === 'move' ? 'move' : 'edit'
})

const pageTitle = computed(() => {
  if (mode.value === 'move') return t('rawMaterialInventoryEdit.moveTitle')
  if (mode.value === 'edit') return t('rawMaterialInventoryEdit.editTitle')
  return t('rawMaterialInventoryEdit.newTitle')
})

const pageSubtitle = computed(() => {
  if (mode.value === 'move') return t('rawMaterialInventoryEdit.moveSubtitle')
  if (mode.value === 'edit') return t('rawMaterialInventoryEdit.editSubtitle')
  return t('rawMaterialInventoryEdit.newSubtitle')
})

const materialTypeMap = computed(() => {
  const map = new Map<string, MaterialTypeRow>()
  materialTypes.value.forEach((row) => map.set(row.type_id, row))
  return map
})

const materialMap = computed(() => {
  const map = new Map<string, MaterialRow>()
  materialRows.value.forEach((row) => map.set(row.id, row))
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
  return materialTypes.value
    .filter((row) => rawMaterialTypeIds.value.size === 0 || rawMaterialTypeIds.value.has(row.type_id))
    .slice()
    .sort((a, b) => materialTypePathText(a.type_id).localeCompare(materialTypePathText(b.type_id)))
    .map((row) => ({
      value: row.type_id,
      label: materialTypePathText(row.type_id),
    }))
})

const selectedTypeDescendantIds = computed(() => {
  if (!form.material_type_id) return new Set<string>()
  const ids = new Set<string>()
  const visit = (typeId: string) => {
    if (ids.has(typeId)) return
    ids.add(typeId)
    materialTypes.value.forEach((row) => {
      if (row.parent_type_id === typeId) visit(row.type_id)
    })
  }
  visit(form.material_type_id)
  return ids
})

const filteredMaterialOptions = computed(() => {
  return materialRows.value
    .filter((row) => {
      if (!row.material_type_id) return false
      if (rawMaterialTypeIds.value.size > 0 && !rawMaterialTypeIds.value.has(row.material_type_id)) return false
      if (selectedTypeDescendantIds.value.size === 0) return true
      return selectedTypeDescendantIds.value.has(row.material_type_id)
    })
    .slice()
    .sort((a, b) => a.material_code.localeCompare(b.material_code))
})

const selectedMaterial = computed(() => (form.material_id ? materialMap.value.get(form.material_id) ?? null : null))
const selectedUomLabel = computed(() => {
  if (!form.uom_id) return ''
  const uom = uomMap.value.get(form.uom_id)
  if (!uom) return ''
  return uom.name ? `${uom.code} - ${uom.name}` : uom.code
})

const selectedMaterialDisplay = computed(() => {
  const material = selectedMaterial.value
  if (!material) return '—'
  return `${material.material_code} - ${material.material_name || material.material_code}`
})

const currentQtyDisplay = computed(() => {
  const qty = originalQty.value
  const formatted = Number.isFinite(qty) ? new Intl.NumberFormat(locale.value, { maximumFractionDigits: 2 }).format(qty) : '—'
  return selectedUomLabel.value ? `${formatted} ${selectedUomLabel.value}` : formatted
})

const primaryActionLabel = computed(() => (mode.value === 'move' ? t('rawMaterialInventoryEdit.actions.move') : t('common.save')))

const currentLocationLabel = computed(() => {
  if (!originalLot.value?.site_id) return '—'
  return siteOptions.value.find((row) => row.value === originalLot.value?.site_id)?.label ?? originalLot.value.site_id
})

const attrSections = computed(() => {
  const groups = new Map<string, AttrField[]>()
  attrFields.value.forEach((field) => {
    const key = field.ui_section || t('rawMaterialInventoryEdit.attributeDefaultSection')
    const list = groups.get(key) ?? []
    list.push(field)
    groups.set(key, list)
  })
  return Array.from(groups.entries()).map(([section, fields]) => ({ section, fields }))
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
  if (!typeId) return ''
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

function clearErrors() {
  Object.keys(errors).forEach((key) => delete errors[key])
}

function messageText(error: unknown) {
  return error instanceof Error ? error.message : String(error)
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

function readLotIdFromMeta(value: unknown) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null
  const lotValue = (value as { lot_id?: unknown }).lot_id
  if (typeof lotValue !== 'string') return null
  const trimmed = lotValue.trim()
  return trimmed.length > 0 ? trimmed : null
}

function readRegistryDefId(value: unknown) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return ''
  const defId = (value as { def_id?: unknown }).def_id
  if (defId == null) return ''
  return String(defId)
}

function generateDocNo(prefix: string) {
  const now = new Date()
  const datePart = now.toISOString().slice(0, 10).replace(/-/g, '')
  return `${prefix}-${datePart}-${Math.random().toString(36).slice(2, 6).toUpperCase()}`
}

function generateLotNo() {
  const now = new Date()
  const datePart = now.toISOString().slice(0, 10).replace(/-/g, '')
  return `LOT-RM-${datePart}-${Math.random().toString(36).slice(2, 6).toUpperCase()}`
}

function parseOptionalNumber(value: unknown) {
  if (value == null || value === '') return null
  const parsed = typeof value === 'number' ? value : Number(value)
  return Number.isFinite(parsed) ? parsed : null
}

function normalizeAttrFieldValue(dataType: string, raw: unknown) {
  const normalized = normalizeBatchAttrDataType(dataType)
  if (normalized === 'bool') return Boolean(raw)
  if (raw === null || raw === undefined) return normalized === 'bool' ? false : ''
  if (normalized === 'number') return String(raw)
  if (normalized === 'json') return typeof raw === 'string' ? raw : JSON.stringify(raw, null, 2)
  return String(raw)
}

function toInputDateTime(value: string | null | undefined) {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  const offset = date.getTimezoneOffset()
  const local = new Date(date.getTime() - offset * 60_000)
  return local.toISOString().slice(0, 16)
}

function fromInputDateTime(value: string) {
  if (!value) return null
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return null
  return date.toISOString()
}

function parseJsonValue(value: string) {
  return JSON.parse(value)
}

async function loadReferenceOptions(kind: string | null, domain: string | null) {
  if (!kind || !domain) return []
  const key = `${kind}:${domain}`
  if (refOptionsCache.has(key)) return refOptionsCache.get(key) ?? []

  let options: Array<{ value: string | number, label: string }> = []
  if (kind === 'type_def') {
    const { data, error } = await supabase
      .from('type_def')
      .select('type_id, code, name')
      .eq('domain', domain)
      .eq('is_active', true)
      .order('sort_order', { ascending: true })
      .order('code', { ascending: true })
    if (error) throw error
    options = ((data ?? []) as TypeRefOptionRow[]).map((row) => ({
      value: row.type_id,
      label: row.name || row.code,
    }))
  } else if (kind === 'registry_def') {
    const { data, error } = await supabase
      .from('registry_def')
      .select('def_id, def_key, spec')
      .eq('kind', domain)
      .eq('is_active', true)
      .order('def_key', { ascending: true })
    if (error) throw error
    options = ((data ?? []) as RegistryRefOptionRow[]).map((row) => ({
      value: row.def_id,
      label: row.spec?.name || row.def_key,
    }))
  }

  refOptionsCache.set(key, options)
  return options
}

async function loadBaseData() {
  const [typeResult, materialResult, siteResult, uomResult] = await Promise.all([
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
      .eq('status', 'active')
      .order('material_code', { ascending: true }),
    supabase
      .from('mst_sites')
      .select('id, name')
      .order('name', { ascending: true }),
    supabase
      .from('mst_uom')
      .select('id, code, name')
      .order('code', { ascending: true }),
  ])

  if (typeResult.error) throw typeResult.error
  if (materialResult.error) throw materialResult.error
  if (siteResult.error) throw siteResult.error
  if (uomResult.error) throw uomResult.error

  materialTypes.value = (typeResult.data ?? []) as MaterialTypeRow[]
  materialRows.value = (materialResult.data ?? []).map((row) => ({
    id: String(row.id),
    material_code: String(row.material_code ?? ''),
    material_name: String(row.material_name ?? ''),
    material_type_id: typeof row.material_type_id === 'string' ? row.material_type_id : null,
    base_uom_id: typeof row.base_uom_id === 'string' ? row.base_uom_id : null,
    status: String(row.status ?? ''),
  }))
  siteOptions.value = (siteResult.data ?? []).map((row) => ({
    value: String(row.id),
    label: typeof row.name === 'string' ? row.name : String(row.id),
  }))
  uomRows.value = (uomResult.data ?? []) as UomRow[]
}

async function calculateLotQty(lotIdValue: string, siteIdValue: string) {
  const linesResult = await supabase
    .from('inv_movement_lines')
    .select('movement_id, qty, meta')
    .contains('meta', { lot_id: lotIdValue })

  if (linesResult.error) throw linesResult.error

  const lines = ((linesResult.data ?? []) as MovementLineResultRow[]).map((row) => ({
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

async function saveAttrValues(tenant: string, lotIdValue: string) {
  const currentAttrIds = attrFields.value.map((field) => field.attr_id)
  const existingResult = await supabase
    .from('entity_attr')
    .select('attr_id')
    .eq('tenant_id', tenant)
    .eq('entity_type', 'lot')
    .eq('entity_id', lotIdValue)

  if (existingResult.error) throw existingResult.error

  const existingIds = new Set(((existingResult.data ?? []) as Array<{ attr_id: number }>).map((row) => Number(row.attr_id)))
  const deleteIds = new Set<number>()
  existingIds.forEach((attrId) => {
    if (!currentAttrIds.includes(attrId)) deleteIds.add(attrId)
  })

  const toUpsert: Array<Record<string, unknown>> = []
  attrFields.value.forEach((field) => {
    const empty = field.value === null || field.value === undefined || field.value === '' || (field.data_type === 'json' && String(field.value).trim() === '')
    if (empty) {
      deleteIds.add(field.attr_id)
      return
    }
    const row: Record<string, unknown> = {
      tenant_id: tenant,
      entity_type: 'lot',
      entity_id: lotIdValue,
      attr_id: field.attr_id,
      uom_id: field.uom_id ?? null,
    }
    if (field.data_type === 'number') row.value_num = Number(field.value)
    else if (field.data_type === 'bool') row.value_bool = Boolean(field.value)
    else if (field.data_type === 'date') row.value_date = field.value
    else if (field.data_type === 'timestamp') row.value_ts = fromInputDateTime(String(field.value))
    else if (field.data_type === 'json') row.value_json = parseJsonValue(String(field.value))
    else if (field.data_type === 'ref') {
      if (field.ref_kind === 'registry_def') row.value_json = { def_id: field.value, kind: field.ref_domain }
      else row.value_ref_type_id = String(field.value).trim()
    } else row.value_text = String(field.value)
    toUpsert.push(row)
    deleteIds.delete(field.attr_id)
  })

  if (deleteIds.size > 0) {
    const { error } = await supabase
      .from('entity_attr')
      .delete()
      .eq('tenant_id', tenant)
      .eq('entity_type', 'lot')
      .eq('entity_id', lotIdValue)
      .in('attr_id', Array.from(deleteIds))
    if (error) throw error
  }

  if (toUpsert.length > 0) {
    const { error } = await supabase
      .from('entity_attr')
      .upsert(toUpsert, { onConflict: 'tenant_id,entity_type,entity_id,attr_id' })
    if (error) throw error
  }
}

async function loadAttrFields(typeIdValue: string, lotIdValue: string | null) {
  if (!typeIdValue) {
    attrFields.value = []
    return
  }

  try {
    attrLoading.value = true
    const tenant = await ensureTenant()
    const assignmentResult = await supabase
      .from('entity_attr_set')
      .select('attr_set_id')
      .eq('tenant_id', tenant)
      .eq('entity_type', 'material_type')
      .eq('entity_id', typeIdValue)
      .eq('is_active', true)

    if (assignmentResult.error) throw assignmentResult.error

    const setIds = (assignmentResult.data ?? []).map((row) => Number((row as { attr_set_id: number }).attr_set_id))
    if (setIds.length === 0) {
      attrFields.value = []
      return
    }

    const ruleResult = await supabase
      .from('attr_set_rule')
      .select('attr_set_id, attr_id, required, sort_order, is_active, ui_section, ui_widget, help_text, attr_def:attr_def!fk_attr_set_rule_attr(attr_id, code, name, name_i18n, data_type, description, is_active, required, uom_id, num_min, num_max, text_regex, allowed_values, ref_kind, ref_domain)')
      .eq('tenant_id', tenant)
      .in('attr_set_id', setIds)
      .eq('is_active', true)
      .order('sort_order', { ascending: true })

    if (ruleResult.error) throw ruleResult.error

    const valueMap = new Map<number, EntityAttrValueRow>()
    if (lotIdValue) {
      const valueResult = await supabase
        .from('entity_attr')
        .select('attr_id, value_text, value_num, value_bool, value_date, value_ts, value_json, value_ref_type_id')
        .eq('tenant_id', tenant)
        .eq('entity_type', 'lot')
        .eq('entity_id', lotIdValue)
      if (valueResult.error) throw valueResult.error
      ;((valueResult.data ?? []) as EntityAttrValueRow[]).forEach((row) => valueMap.set(Number(row.attr_id), row))
    }

    const fields: AttrField[] = []
    for (const row of ruleResult.data ?? []) {
      const typedRow = row as unknown as AttrRuleRow
      const attrRaw = typedRow.attr_def
      const attr = Array.isArray(attrRaw) ? (attrRaw[0] ?? null) : attrRaw
      if (!attr || attr.is_active === false) continue
      const dataType = normalizeBatchAttrDataType(attr.data_type)
      const valueRow = valueMap.get(attr.attr_id)
      let value: unknown = ''
      if (dataType === 'number') value = valueRow?.value_num ?? ''
      else if (dataType === 'bool') value = valueRow?.value_bool ?? false
      else if (dataType === 'date') value = valueRow?.value_date ?? ''
      else if (dataType === 'timestamp') value = toInputDateTime(valueRow?.value_ts)
      else if (dataType === 'json') value = valueRow?.value_json ? JSON.stringify(valueRow.value_json, null, 2) : ''
      else if (dataType === 'ref') {
        if (attr.ref_kind === 'registry_def') value = readRegistryDefId(valueRow?.value_json)
        else value = valueRow?.value_ref_type_id ?? ''
      } else value = valueRow?.value_text ?? ''

      fields.push({
        attr_id: attr.attr_id,
        code: attr.code,
        name: attr.name,
        name_i18n: attr.name_i18n ?? null,
        data_type: dataType,
        required: Boolean(typedRow.required || attr.required),
        ui_section: typedRow.ui_section?.trim() || t('rawMaterialInventoryEdit.attributeDefaultSection'),
        ui_widget: typedRow.ui_widget?.trim() || '',
        help_text: typedRow.help_text?.trim() || '',
        description: attr.description?.trim() || '',
        uom_id: attr.uom_id ?? null,
        uom_code: attr.uom_id ? uomMap.value.get(attr.uom_id)?.code ?? null : null,
        num_min: parseOptionalNumber(attr.num_min),
        num_max: parseOptionalNumber(attr.num_max),
        text_regex: attr.text_regex ?? null,
        allowed_values: attr.allowed_values ?? null,
        ref_kind: attr.ref_kind ?? null,
        ref_domain: attr.ref_domain ?? null,
        value: normalizeAttrFieldValue(dataType, value),
        options: await loadReferenceOptions(attr.ref_kind ?? null, attr.ref_domain ?? null),
        error: '',
      })
    }

    fields.sort((a, b) => a.ui_section.localeCompare(b.ui_section) || a.code.localeCompare(b.code))
    attrFields.value = fields
  } catch (error) {
    attrFields.value = []
    toast.error(messageText(error))
  } finally {
    attrLoading.value = false
  }
}

async function loadExistingLot() {
  if (!lotId.value) return
  const lotResult = await supabase
    .from('lot')
    .select('id, material_id, site_id, uom_id, lot_no, status')
    .eq('id', lotId.value)
    .single()

  if (lotResult.error) throw lotResult.error

  const lot = lotResult.data as LotRow
  originalLot.value = lot
  form.material_id = lot.material_id ?? ''
  const material = lot.material_id ? materialMap.value.get(lot.material_id) ?? null : null
  form.material_type_id = material?.material_type_id ?? ''
  form.uom_id = lot.uom_id ?? material?.base_uom_id ?? ''
  form.site_id = lot.site_id ?? ''
  form.dest_site_id = ''

  const qty = lot.site_id ? await calculateLotQty(lot.id, lot.site_id) : 0
  originalQty.value = qty
  form.qty = qty > 0 ? String(qty) : ''
  await loadAttrFields(form.material_type_id, lot.id)
}

function attrLabel(field: AttrField) {
  const isJa = locale.value.toString().toLowerCase().startsWith('ja')
  const ja = field.name_i18n?.ja?.trim()
  const en = field.name_i18n?.en?.trim()
  if (isJa) return ja || field.name || en || field.code
  return en || field.name || ja || field.code
}

function attrInputKind(field: AttrField) {
  if (field.ui_widget === 'select') return 'select'
  if (field.ui_widget === 'toggle') return 'boolean'
  const dataType = normalizeBatchAttrDataType(field.data_type)
  if (dataType === 'ref') return 'select'
  if (dataType === 'bool') return 'boolean'
  if (dataType === 'json') return 'json'
  if (dataType === 'date') return 'date'
  if (dataType === 'timestamp') return 'timestamp'
  if (dataType === 'number') return 'number'
  if (attrAllowedOptions(field).length > 0) return 'select'
  return 'text'
}

function attrAllowedOptions(field: AttrField) {
  if (field.options.length > 0) return field.options
  if (Array.isArray(field.allowed_values)) {
    return field.allowed_values
      .map((entry) => {
        const value = String(entry ?? '').trim()
        if (!value) return null
        return { value, label: value }
      })
      .filter((entry): entry is { value: string, label: string } => Boolean(entry))
  }
  if (!field.allowed_values || typeof field.allowed_values !== 'object') return []
  return Object.entries(field.allowed_values as Record<string, unknown>)
    .map(([key, value]) => {
      const normalizedKey = key.trim()
      const label = String(value ?? key).trim()
      if (!normalizedKey) return null
      return { value: normalizedKey, label: label || normalizedKey }
    })
    .filter((entry): entry is { value: string, label: string } => Boolean(entry))
}

function attrTextValue(field: AttrField) {
  return typeof field.value === 'string' ? field.value : ''
}

function updateAttrText(field: AttrField, event: Event) {
  const target = event.target as HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement | null
  field.value = target?.value ?? ''
}

function updateAttrBoolean(field: AttrField, event: Event) {
  const target = event.target as HTMLInputElement | null
  field.value = Boolean(target?.checked)
}

function handleMaterialTypeChange() {
  clearErrors()
  form.material_id = ''
  form.uom_id = ''
  attrFields.value = []
  if (form.material_type_id) {
    void loadAttrFields(form.material_type_id, mode.value === 'create' ? null : lotId.value)
  }
}

function handleMaterialChange() {
  clearErrors()
  const material = selectedMaterial.value
  if (!material) {
    form.uom_id = ''
    return
  }
  form.material_type_id = material.material_type_id ?? form.material_type_id
  form.uom_id = material.base_uom_id ?? ''
  void loadAttrFields(form.material_type_id, mode.value === 'create' ? null : lotId.value)
}

function validateAttrFields() {
  let hasError = false
  attrFields.value.forEach((field) => {
    field.error = validateBatchAttrField(
      {
        code: field.code,
        name: attrLabel(field),
        data_type: field.data_type,
        required: field.required,
        num_min: field.num_min,
        num_max: field.num_max,
        text_regex: field.text_regex,
        allowed_values: field.allowed_values,
        ref_kind: field.ref_kind,
        value: field.value,
      },
      {
        required: (label) => t('errors.required', { field: label }),
        mustBeNumber: (label) => t('errors.mustBeNumber', { field: label }),
        minValue: (label, min) => t('rawMaterialInventoryEdit.attributeMin', { field: label, min }),
        maxValue: (label, max) => t('rawMaterialInventoryEdit.attributeMax', { field: label, max }),
        pattern: (label) => t('rawMaterialInventoryEdit.attributePattern', { field: label }),
        allowedValues: (label) => t('rawMaterialInventoryEdit.attributeAllowedValues', { field: label }),
        invalidJson: (label) => t('rawMaterialInventoryEdit.attributeJson', { field: label }),
        invalidReference: (label) => t('rawMaterialInventoryEdit.attributeReference', { field: label }),
      },
    )
    if (field.error) hasError = true
  })
  return !hasError
}

function validateForm() {
  clearErrors()

  if (!form.material_type_id) {
    errors.material_type_id = t('errors.required', { field: t('rawMaterialInventoryEdit.fields.materialType') })
  }

  if (!form.material_id) {
    errors.material_id = t('errors.required', { field: t('rawMaterialInventoryEdit.fields.material') })
  }

  if (mode.value === 'move') {
    if (!form.dest_site_id) {
      errors.dest_site_id = t('errors.required', { field: t('rawMaterialInventoryEdit.fields.destinationLocation') })
    } else if (form.dest_site_id === originalLot.value?.site_id) {
      errors.dest_site_id = t('rawMaterialInventoryEdit.errors.destinationSame')
    }
  } else {
    if (!form.site_id) {
      errors.site_id = t('errors.required', { field: t('rawMaterialInventoryEdit.fields.location') })
    }

    const qty = Number(form.qty)
    if (!Number.isFinite(qty) || qty <= 0) {
      errors.qty = t('rawMaterialInventoryEdit.errors.qtyPositive')
    }
  }

  const attrValid = validateAttrFields()
  return Object.keys(errors).length === 0 && attrValid
}

async function createMovement(
  tenant: string,
  input: {
    docType: 'adjustment' | 'transfer'
    reason: string
    srcSiteId: string | null
    destSiteId: string | null
    materialId: string
    qty: number
    uomId: string
    lotIdValue: string
  },
) {
  const movementResult = await supabase
    .from('inv_movements')
    .insert({
      tenant_id: tenant,
      doc_no: generateDocNo(input.docType === 'transfer' ? 'RMITR' : 'RMINV'),
      doc_type: input.docType,
      status: 'posted',
      movement_at: new Date().toISOString(),
      src_site_id: input.srcSiteId,
      dest_site_id: input.destSiteId,
      reason: input.reason,
      meta: {
        source: 'raw_material_inventory_edit',
        lot_id: input.lotIdValue,
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
    material_id: input.materialId,
    qty: input.qty,
    uom_id: input.uomId,
    meta: {
      lot_id: input.lotIdValue,
    },
  })

  if (lineResult.error) throw lineResult.error
}

async function saveRecord() {
  if (!validateForm()) return

  try {
    saving.value = true
    const tenant = await ensureTenant()

    if (mode.value === 'create') {
      const createQty = Number(form.qty)
      const lotResult = await supabase
        .from('lot')
        .insert({
          tenant_id: tenant,
          lot_no: generateLotNo(),
          material_id: form.material_id,
          site_id: form.site_id,
          qty: createQty,
          uom_id: form.uom_id,
          status: 'active',
          meta: {
            source: 'raw_material_inventory_edit',
          },
        })
        .select('id')
        .single()

      if (lotResult.error || !lotResult.data) {
        throw lotResult.error || new Error('Lot insert failed')
      }

      await saveAttrValues(tenant, lotResult.data.id)
      await createMovement(tenant, {
        docType: 'adjustment',
        reason: 'raw_material_inventory_create',
        srcSiteId: null,
        destSiteId: form.site_id,
        materialId: form.material_id,
        qty: createQty,
        uomId: form.uom_id,
        lotIdValue: lotResult.data.id,
      })
      await refreshProjection(tenant, lotResult.data.id, form.site_id, form.uom_id)
    } else if (mode.value === 'edit' && originalLot.value?.site_id) {
      const currentQty = originalQty.value
      const nextQty = Number(form.qty)
      const delta = Number((nextQty - currentQty).toFixed(6))
      const lotValue = lotId.value

      const updateLotResult = await supabase
        .from('lot')
        .update({
          qty: nextQty,
          uom_id: form.uom_id,
        })
        .eq('id', lotValue)
      if (updateLotResult.error) throw updateLotResult.error

      await saveAttrValues(tenant, lotValue)

      if (delta !== 0) {
        await createMovement(tenant, {
          docType: 'adjustment',
          reason: 'raw_material_inventory_adjust',
          srcSiteId: delta < 0 ? originalLot.value.site_id : null,
          destSiteId: delta > 0 ? originalLot.value.site_id : null,
          materialId: form.material_id,
          qty: Math.abs(delta),
          uomId: form.uom_id,
          lotIdValue: lotValue,
        })
      }

      await refreshProjection(tenant, lotValue, originalLot.value.site_id, form.uom_id)
    } else if (mode.value === 'move' && originalLot.value?.site_id) {
      const lotValue = lotId.value
      const currentQty = originalQty.value
      const destinationSiteId = form.dest_site_id

      await saveAttrValues(tenant, lotValue)
      await createMovement(tenant, {
        docType: 'transfer',
        reason: 'raw_material_inventory_move',
        srcSiteId: originalLot.value.site_id,
        destSiteId: destinationSiteId,
        materialId: form.material_id,
        qty: currentQty,
        uomId: form.uom_id,
        lotIdValue: lotValue,
      })

      const updateLotResult = await supabase
        .from('lot')
        .update({
          site_id: destinationSiteId,
          uom_id: form.uom_id,
          qty: currentQty,
        })
        .eq('id', lotValue)
      if (updateLotResult.error) throw updateLotResult.error

      await refreshProjection(tenant, lotValue, originalLot.value.site_id, form.uom_id)
      await refreshProjection(tenant, lotValue, destinationSiteId, form.uom_id)
    }

    toast.success(t('common.saved'))
    void router.push({ name: 'RawMaterialInventory' })
  } catch (error) {
    toast.error(messageText(error))
  } finally {
    saving.value = false
  }
}

function goBack() {
  void router.push({ name: 'RawMaterialInventory' })
}

onMounted(async () => {
  try {
    loading.value = true
    loadError.value = ''
    await ensureTenant()
    await loadBaseData()
    if (lotId.value) {
      await loadExistingLot()
    }
  } catch (error) {
    loadError.value = messageText(error)
  } finally {
    loading.value = false
  }
})
</script>
