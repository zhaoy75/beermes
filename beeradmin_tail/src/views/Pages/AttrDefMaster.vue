<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-7xl mx-auto">
      <header class="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('attrDef.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('attrDef.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button
            class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700"
            @click="openCreate"
          >
            {{ t('common.new') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="refreshAll"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="grid grid-cols-1 lg:grid-cols-[1fr_380px] gap-4">
        <div class="space-y-3">
          <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
            <div class="flex flex-1 flex-wrap gap-2">
              <input
                v-model.trim="filters.code"
                class="h-[40px] w-full md:w-[240px] border rounded px-3 text-sm"
                :placeholder="t('attrDef.filters.codePlaceholder')"
              />
              <select
                v-model="filters.domain"
                class="h-[40px] w-full md:w-[220px] border rounded px-3 text-sm bg-white"
              >
                <option value="">{{ t('attrDef.filters.domainAll') }}</option>
                <option v-for="option in domainOptions" :key="option" :value="option">
                  {{ option }}
                </option>
              </select>
            </div>
            <div class="text-xs text-gray-500">
              {{ t('attrDef.countLabel', { count: filteredRows.length }) }}
            </div>
          </div>

          <div class="border border-gray-200 rounded-xl shadow-sm overflow-hidden">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('attrDef.table.code') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('attrDef.table.displayName') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('attrDef.table.domainIndustry') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('attrDef.table.dataType') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('attrDef.table.uom') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('attrDef.table.validation') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('attrDef.table.active') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('attrDef.table.usage') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr
                  v-for="row in filteredRows"
                  :key="row.attr_id"
                  class="hover:bg-gray-50"
                >
                  <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.code }}</td>
                  <td class="px-3 py-2">
                    <div class="text-gray-800">{{ row.name }}</div>
                    <div v-if="displayNameI18n(row)" class="text-xs text-gray-500">
                      {{ displayNameI18n(row) }}
                    </div>
                  </td>
                  <td class="px-3 py-2 text-gray-600">
                    <div>{{ row.domain }}</div>
                    <div class="text-xs text-gray-500">{{ industryLabel(row.industry_id) }}</div>
                  </td>
                  <td class="px-3 py-2 text-gray-600">{{ dataTypeLabel(row.data_type) }}</td>
                  <td class="px-3 py-2 text-gray-600">{{ uomLabel(row.uom_id) }}</td>
                  <td class="px-3 py-2 text-gray-600">{{ validationLabel(row) }}</td>
                  <td class="px-3 py-2 text-gray-600">
                    {{ row.is_active ? t('common.yes') : t('common.no') }}
                  </td>
                  <td class="px-3 py-2 text-gray-600">
                    <span class="inline-flex items-center gap-1">
                      <span v-if="usageTotal(row) > 0">🔒</span>
                      {{ usageTotal(row) }}
                    </span>
                  </td>
                  <td class="px-3 py-2">
                    <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openEdit(row)">
                      {{ t('common.edit') }}
                    </button>
                  </td>
                </tr>
                <tr v-if="!loading && filteredRows.length === 0">
                  <td colspan="9" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
                </tr>
                <tr v-if="loading">
                  <td colspan="9" class="px-3 py-8 text-center text-gray-500">{{ t('common.loading') }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <aside class="border border-gray-200 rounded-xl shadow-sm p-4 h-fit" v-if="drawerOpen">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-sm font-semibold text-gray-700">
              {{ editing ? t('attrDef.editTitle') : t('attrDef.newTitle') }}
            </h2>
            <button class="text-xs px-2 py-1 rounded border hover:bg-gray-50" @click="closeDrawer">
              {{ t('common.close') }}
            </button>
          </div>

          <div v-if="selectedRow && usageTotal(selectedRow) > 0" class="mb-3 rounded border border-amber-200 bg-amber-50 p-3 text-xs text-amber-700">
            {{ t('attrDef.usedWarning', { count: usageTotal(selectedRow) }) }}
          </div>

          <div class="space-y-4 text-sm">
            <div>
              <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.code') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="form.code" class="w-full h-[40px] border rounded px-3 font-mono" />
              <p v-if="errors.code" class="mt-1 text-xs text-red-600">{{ errors.code }}</p>
            </div>

            <div>
              <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.name') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="form.name" class="w-full h-[40px] border rounded px-3" />
              <p v-if="errors.name" class="mt-1 text-xs text-red-600">{{ errors.name }}</p>
            </div>

            <div>
              <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.nameI18n') }}</label>
              <textarea v-model.trim="form.name_i18n" class="w-full min-h-[80px] border rounded px-3 py-2 font-mono text-xs" />
              <p v-if="errors.name_i18n" class="mt-1 text-xs text-red-600">{{ errors.name_i18n }}</p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.domain') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.domain" list="domainOptions" class="w-full h-[40px] border rounded px-3" />
                <datalist id="domainOptions">
                  <option v-for="option in domainOptions" :key="option" :value="option" />
                </datalist>
                <p v-if="errors.domain" class="mt-1 text-xs text-red-600">{{ errors.domain }}</p>
              </div>
              <div>
                <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.industry') }}</label>
                <select v-model="form.industry_id" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option :value="null">{{ t('attrDef.form.industryShared') }}</option>
                  <option v-for="option in industryOptions" :key="option.industry_id" :value="option.industry_id">
                    {{ option.name }}
                  </option>
                </select>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.dataType') }}<span class="text-red-600">*</span></label>
                <select v-model="form.data_type" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('attrDef.form.dataTypePlaceholder') }}</option>
                  <option v-for="option in dataTypeOptions" :key="option.value" :value="option.value">
                    {{ option.label }}
                  </option>
                </select>
                <p v-if="errors.data_type" class="mt-1 text-xs text-red-600">{{ errors.data_type }}</p>
              </div>
              <div>
                <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.uom') }}</label>
                <select v-model="form.uom_id" class="w-full h-[40px] border rounded px-3 bg-white" :disabled="form.data_type !== 'number'">
                  <option :value="null">{{ t('attrDef.form.uomNone') }}</option>
                  <option v-for="option in uomOptions" :key="option.id" :value="option.id">
                    {{ option.code }} - {{ option.name || option.code }}
                  </option>
                </select>
              </div>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.numMin') }}</label>
                <input v-model.number="form.num_min" type="number" step="any" class="w-full h-[40px] border rounded px-3" :disabled="form.data_type !== 'number'" />
              </div>
              <div>
                <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.numMax') }}</label>
                <input v-model.number="form.num_max" type="number" step="any" class="w-full h-[40px] border rounded px-3" :disabled="form.data_type !== 'number'" />
                <p v-if="errors.num_range" class="mt-1 text-xs text-red-600">{{ errors.num_range }}</p>
              </div>
            </div>

            <div>
              <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.regex') }}</label>
              <input v-model.trim="form.text_regex" class="w-full h-[40px] border rounded px-3" :disabled="form.data_type !== 'text'" />
            </div>

            <div>
              <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.enumValues') }}</label>
              <div class="space-y-2" :class="form.data_type === 'enum' ? '' : 'opacity-60'">
                <div class="flex gap-2">
                  <input
                    v-model.trim="enumDraft"
                    class="flex-1 h-[36px] border rounded px-2 text-xs"
                    :disabled="form.data_type !== 'enum'"
                    :placeholder="t('attrDef.form.enumPlaceholder')"
                    @keyup.enter="addEnumValue"
                  />
                  <button
                    class="px-2 py-1 text-xs rounded border hover:bg-gray-50"
                    type="button"
                    :disabled="form.data_type !== 'enum' || !enumDraft"
                    @click="addEnumValue"
                  >
                    {{ t('common.add') }}
                  </button>
                </div>
                <div v-if="enumValues.length" class="flex flex-wrap gap-2">
                  <span
                    v-for="value in enumValues"
                    :key="value"
                    class="inline-flex items-center gap-1 rounded border border-gray-200 bg-gray-50 px-2 py-1 text-xs"
                  >
                    {{ value }}
                    <button
                      class="text-gray-500 hover:text-gray-700"
                      type="button"
                      :disabled="form.data_type !== 'enum'"
                      @click="removeEnumValue(value)"
                    >
                      ✕
                    </button>
                  </span>
                </div>
                <p v-else class="text-xs text-gray-500">{{ t('attrDef.form.enumEmpty') }}</p>
                <p v-if="errors.allowed_values" class="text-xs text-red-600">{{ errors.allowed_values }}</p>
              </div>
            </div>

            <div>
              <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.defaultValue') }}</label>
              <textarea v-model.trim="form.default_value" class="w-full min-h-[70px] border rounded px-3 py-2 font-mono text-xs" />
              <p v-if="errors.default_value" class="mt-1 text-xs text-red-600">{{ errors.default_value }}</p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div class="flex items-center gap-2 pt-6">
                <input id="attrRequired" v-model="form.required" type="checkbox" class="h-4 w-4" />
                <label for="attrRequired" class="text-sm text-gray-700">{{ t('attrDef.form.required') }}</label>
              </div>
              <div class="flex items-center gap-2 pt-6">
                <input id="attrActive" v-model="form.is_active" type="checkbox" class="h-4 w-4" />
                <label for="attrActive" class="text-sm text-gray-700">{{ t('attrDef.form.active') }}</label>
              </div>
            </div>

            <div>
              <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.technical') }}</label>
              <textarea v-model.trim="form.meta" class="w-full min-h-[90px] border rounded px-3 py-2 font-mono text-xs" />
              <p v-if="errors.meta" class="mt-1 text-xs text-red-600">{{ errors.meta }}</p>
            </div>

            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.refKind') }}</label>
                <input v-model.trim="form.ref_kind" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.refDomain') }}</label>
                <input v-model.trim="form.ref_domain" class="w-full h-[40px] border rounded px-3" />
              </div>
            </div>

            <div>
              <label class="block text-xs text-gray-600 mb-1">{{ t('attrDef.form.description') }}</label>
              <textarea v-model.trim="form.description" class="w-full min-h-[70px] border rounded px-3 py-2 text-xs" />
            </div>

            <div class="flex items-center gap-2">
              <input id="attrDeprecated" v-model="form.deprecated" type="checkbox" class="h-4 w-4" />
              <label for="attrDeprecated" class="text-sm text-gray-700">{{ t('attrDef.form.deprecated') }}</label>
            </div>

            <div class="flex flex-wrap gap-2 pt-2">
              <button
                class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
                :disabled="saving"
                @click="saveAttr"
              >
                {{ saving ? t('common.saving') : t('common.save') }}
              </button>
              <button
                class="px-3 py-2 rounded border hover:bg-gray-50"
                @click="closeDrawer"
              >
                {{ t('common.cancel') }}
              </button>
              <button
                v-if="editing"
                class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700 disabled:opacity-50"
                :disabled="saving || form.deprecated"
                @click="confirmDelete"
              >
                {{ t('common.delete') }}
              </button>
            </div>

            <p v-if="form.deprecated" class="text-xs text-amber-700">
              {{ t('attrDef.form.deprecatedHint') }}
            </p>
          </div>
        </aside>
      </section>

      <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('attrDef.deleteTitle') }}</h3>
          </div>
          <div class="p-4 text-sm">{{ t('attrDef.deleteConfirm', { code: selectedRow?.code || '' }) }}</div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="showDelete = false">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700" @click="deleteAttr">{{ t('common.delete') }}</button>
          </div>
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

type AttrDefRow = {
  attr_id: number
  code: string
  name: string
  name_i18n: Record<string, string> | null
  domain: string
  industry_id: string | null
  data_type: string
  uom_id: string | null
  num_min: number | null
  num_max: number | null
  text_regex: string | null
  allowed_values: unknown | null
  default_value: unknown | null
  required: boolean
  is_active: boolean
  description: string | null
  ref_kind: string | null
  ref_domain: string | null
  meta: Record<string, any>
  scope: string
  owner_id: string | null
}

type IndustryRow = {
  industry_id: string
  code: string
  name: string
  name_i18n: Record<string, string> | null
  is_active: boolean
  sort_order: number
}

type UomRow = {
  id: string
  code: string
  name: string | null
}

type UsageCount = {
  setCount: number
  entityCount: number
}

const TABLE = 'attr_def'

const { t } = useI18n()
const pageTitle = computed(() => t('attrDef.title'))

const rows = ref<AttrDefRow[]>([])
const loading = ref(false)
const saving = ref(false)
const drawerOpen = ref(false)
const editing = ref(false)
const showDelete = ref(false)
const selectedRow = ref<AttrDefRow | null>(null)

const tenantId = ref<string | null>(null)
const isAdmin = ref(false)

const industries = ref<IndustryRow[]>([])
const uoms = ref<UomRow[]>([])
const usageCounts = ref<Map<number, UsageCount>>(new Map())

const filters = reactive({
  code: '',
  domain: '',
})

const form = reactive({
  code: '',
  name: '',
  name_i18n: '',
  domain: '',
  industry_id: null as string | null,
  data_type: '',
  uom_id: null as string | null,
  num_min: null as number | null,
  num_max: null as number | null,
  text_regex: '',
  required: false,
  is_active: true,
  default_value: '',
  meta: '',
  ref_kind: '',
  ref_domain: '',
  description: '',
  deprecated: false,
})

const enumValues = ref<string[]>([])
const enumDraft = ref('')

const errors = reactive<Record<string, string>>({
  code: '',
  name: '',
  domain: '',
  data_type: '',
  num_range: '',
  allowed_values: '',
  name_i18n: '',
  default_value: '',
  meta: '',
})

const dataTypeOptions = computed(() => [
  { value: 'number', label: t('attrDef.types.number') },
  { value: 'text', label: t('attrDef.types.text') },
  { value: 'enum', label: t('attrDef.types.enum') },
  { value: 'bool', label: t('attrDef.types.bool') },
])

const domainOptions = computed(() => {
  const set = new Set(rows.value.map((row) => row.domain).filter(Boolean))
  return Array.from(set).sort((a, b) => a.localeCompare(b))
})

const industryOptions = computed(() => {
  return [...industries.value].sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0) || a.name.localeCompare(b.name))
})

const filteredRows = computed(() => {
  const codeFilter = filters.code.trim().toLowerCase()
  const domainFilter = filters.domain

  return rows.value.filter((row) => {
    const matchCode = !codeFilter || row.code.toLowerCase().includes(codeFilter)
    const matchDomain = !domainFilter || row.domain === domainFilter
    return matchCode && matchDomain
  })
})

function normalizeDataType(value: string) {
  if (value === 'string') return 'text'
  if (value === 'boolean') return 'bool'
  return value
}

function toStorageDataType(value: string) {
  if (value === 'text') return 'string'
  if (value === 'bool') return 'boolean'
  return value
}

function dataTypeLabel(value: string) {
  const normalized = normalizeDataType(value)
  const match = dataTypeOptions.value.find((option) => option.value === normalized)
  return match?.label ?? value
}

function displayNameI18n(row: AttrDefRow) {
  if (!row.name_i18n) return ''
  const entries = Object.entries(row.name_i18n)
    .filter(([_, value]) => value)
    .map(([key, value]) => `${key}:${value}`)
  return entries.length ? entries.join(' · ') : ''
}

function industryLabel(industryId: string | null) {
  if (!industryId) return t('attrDef.industryShared')
  const match = industries.value.find((item) => item.industry_id === industryId)
  return match?.name ?? industryId
}

function uomLabel(uomId: string | null) {
  if (!uomId) return '—'
  const match = uoms.value.find((item) => item.id === uomId)
  return match ? `${match.code}${match.name ? ` (${match.name})` : ''}` : uomId
}

function validationLabel(row: AttrDefRow) {
  const normalized = normalizeDataType(row.data_type)
  if (normalized === 'number') {
    const min = row.num_min ?? '—'
    const max = row.num_max ?? '—'
    return `${min} ~ ${max}`
  }
  if (normalized === 'text') {
    return row.text_regex || '—'
  }
  if (normalized === 'enum') {
    if (Array.isArray(row.allowed_values)) {
      return row.allowed_values.length ? row.allowed_values.join(', ') : '—'
    }
    if (row.allowed_values && typeof row.allowed_values === 'object') {
      const keys = Object.keys(row.allowed_values as Record<string, unknown>)
      return keys.length ? keys.join(', ') : '—'
    }
    return '—'
  }
  return '—'
}

function usageTotal(row: AttrDefRow) {
  const counts = usageCounts.value.get(row.attr_id)
  return counts ? counts.setCount + counts.entityCount : 0
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved in session')
  tenantId.value = id
  const role = String(data.user?.app_metadata?.role ?? data.user?.user_metadata?.role ?? '').toLowerCase()
  const isAdminFlag = Boolean(data.user?.app_metadata?.is_admin || data.user?.user_metadata?.is_admin)
  isAdmin.value = isAdminFlag || role === 'admin'
  return id
}

function canEdit(row: AttrDefRow) {
  if (row.scope === 'system') return isAdmin.value
  return true
}

async function fetchIndustries() {
  const { data, error } = await supabase
    .from('industry')
    .select('industry_id, code, name, name_i18n, is_active, sort_order')
    .eq('is_active', true)
    .order('sort_order', { ascending: true })
    .order('name', { ascending: true })
  if (error) throw error
  industries.value = (data ?? []) as IndustryRow[]
}

async function fetchUoms() {
  const { data, error } = await supabase
    .from('mst_uom')
    .select('id, code, name')
    .order('code', { ascending: true })
  if (error) throw error
  uoms.value = (data ?? []) as UomRow[]
}

async function fetchAttrDefs() {
  try {
    loading.value = true
    const { data, error } = await supabase
      .from(TABLE)
      .select('attr_id, code, name, name_i18n, domain, industry_id, data_type, uom_id, num_min, num_max, text_regex, allowed_values, default_value, required, is_active, description, ref_kind, ref_domain, meta, scope, owner_id')
      .order('code', { ascending: true })
    if (error) throw error
    rows.value = (data ?? []) as AttrDefRow[]
    await fetchUsageCounts(rows.value.map((row) => row.attr_id))
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
    rows.value = []
  } finally {
    loading.value = false
  }
}

async function fetchUsageCounts(attrIds: number[]) {
  if (attrIds.length === 0) {
    usageCounts.value = new Map()
    return
  }
  const counts = new Map<number, UsageCount>()
  const { data: ruleRows, error: ruleError } = await supabase
    .from('attr_set_rule')
    .select('attr_id')
    .in('attr_id', attrIds)
  if (ruleError) throw ruleError
  for (const row of ruleRows ?? []) {
    const id = row.attr_id as number
    const entry = counts.get(id) ?? { setCount: 0, entityCount: 0 }
    entry.setCount += 1
    counts.set(id, entry)
  }

  const { data: entityRows, error: entityError } = await supabase
    .from('entity_attr')
    .select('attr_id')
    .in('attr_id', attrIds)
  if (entityError) throw entityError
  for (const row of entityRows ?? []) {
    const id = row.attr_id as number
    const entry = counts.get(id) ?? { setCount: 0, entityCount: 0 }
    entry.entityCount += 1
    counts.set(id, entry)
  }

  usageCounts.value = counts
}

function resetErrors() {
  Object.keys(errors).forEach((key) => {
    errors[key] = ''
  })
}

function resetForm() {
  form.code = ''
  form.name = ''
  form.name_i18n = ''
  form.domain = ''
  form.industry_id = null
  form.data_type = ''
  form.uom_id = null
  form.num_min = null
  form.num_max = null
  form.text_regex = ''
  form.required = false
  form.is_active = true
  form.default_value = ''
  form.meta = ''
  form.ref_kind = ''
  form.ref_domain = ''
  form.description = ''
  form.deprecated = false
  enumValues.value = []
  enumDraft.value = ''
  resetErrors()
}

function openCreate() {
  editing.value = false
  selectedRow.value = null
  resetForm()
  drawerOpen.value = true
}

function openEdit(row: AttrDefRow) {
  if (!canEdit(row)) {
    toast.error(t('attrDef.errors.adminOnlySystem'))
    return
  }
  editing.value = true
  selectedRow.value = row
  form.code = row.code
  form.name = row.name
  form.name_i18n = row.name_i18n ? JSON.stringify(row.name_i18n, null, 2) : ''
  form.domain = row.domain
  form.industry_id = row.industry_id
  form.data_type = normalizeDataType(row.data_type)
  form.uom_id = row.uom_id
  form.num_min = row.num_min ?? null
  form.num_max = row.num_max ?? null
  form.text_regex = row.text_regex ?? ''
  form.required = row.required
  form.is_active = row.is_active
  form.default_value = row.default_value !== null && row.default_value !== undefined ? JSON.stringify(row.default_value, null, 2) : ''
  form.meta = row.meta ? JSON.stringify(row.meta, null, 2) : ''
  form.ref_kind = row.ref_kind ?? ''
  form.ref_domain = row.ref_domain ?? ''
  form.description = row.description ?? ''
  form.deprecated = Boolean((row.meta as Record<string, any> | null)?.deprecated)

  if (Array.isArray(row.allowed_values)) {
    enumValues.value = row.allowed_values.map((value) => String(value))
  } else {
    enumValues.value = []
  }
  enumDraft.value = ''
  resetErrors()
  drawerOpen.value = true
}

function closeDrawer() {
  drawerOpen.value = false
  showDelete.value = false
}

function addEnumValue() {
  const value = enumDraft.value.trim()
  if (!value || enumValues.value.includes(value)) {
    enumDraft.value = ''
    return
  }
  enumValues.value = [...enumValues.value, value]
  enumDraft.value = ''
}

function removeEnumValue(value: string) {
  enumValues.value = enumValues.value.filter((item) => item !== value)
}

function parseJsonInput(value: string, field: string, allowEmpty = true) {
  if (!value.trim()) {
    if (allowEmpty) return null
    errors[field] = t('attrDef.errors.jsonRequired')
    return undefined
  }
  try {
    return JSON.parse(value)
  } catch (err) {
    errors[field] = t('attrDef.errors.jsonInvalid')
    return undefined
  }
}

function normalizeNumber(value: number | null) {
  if (typeof value !== 'number') return null
  return Number.isFinite(value) ? value : null
}

function validateForm() {
  resetErrors()
  if (!form.code.trim()) errors.code = t('attrDef.errors.codeRequired')
  if (!form.name.trim()) errors.name = t('attrDef.errors.nameRequired')
  if (!form.domain.trim()) errors.domain = t('attrDef.errors.domainRequired')

  const allowedTypes = dataTypeOptions.value.map((option) => option.value)
  if (!form.data_type || !allowedTypes.includes(form.data_type)) {
    errors.data_type = t('attrDef.errors.dataTypeRequired')
  }

  if (form.data_type === 'number') {
    const minValue = normalizeNumber(form.num_min)
    const maxValue = normalizeNumber(form.num_max)
    if (minValue !== null && maxValue !== null && minValue > maxValue) {
      errors.num_range = t('attrDef.errors.numRange')
    }
  }

  if (form.data_type === 'enum' && enumValues.value.length === 0) {
    errors.allowed_values = t('attrDef.errors.enumRequired')
  }

  const nameI18n = parseJsonInput(form.name_i18n, 'name_i18n')
  if (nameI18n === undefined) return false
  if (nameI18n && typeof nameI18n !== 'object') {
    errors.name_i18n = t('attrDef.errors.jsonObject')
    return false
  }

  const defaultValue = parseJsonInput(form.default_value, 'default_value')
  if (defaultValue === undefined) return false

  const meta = parseJsonInput(form.meta, 'meta')
  if (meta === undefined) return false
  if (meta && typeof meta !== 'object') {
    errors.meta = t('attrDef.errors.jsonObject')
    return false
  }

  return Object.values(errors).every((value) => !value)
}

async function saveAttr() {
  try {
    if (!validateForm()) return
    saving.value = true
    const tenant = await ensureTenant()

    const nameI18n = parseJsonInput(form.name_i18n, 'name_i18n')
    const defaultValue = parseJsonInput(form.default_value, 'default_value')
    const metaValue = parseJsonInput(form.meta, 'meta') ?? {}

    if (nameI18n === undefined || defaultValue === undefined || metaValue === undefined) return

    const meta = {
      ...(typeof metaValue === 'object' && metaValue !== null ? metaValue : {}),
      deprecated: form.deprecated,
    }

  const payload = {
    code: form.code.trim(),
    name: form.name.trim(),
    name_i18n: nameI18n,
    domain: form.domain.trim(),
    industry_id: form.industry_id,
    data_type: toStorageDataType(form.data_type),
    uom_id: form.data_type === 'number' ? form.uom_id : null,
    num_min: form.data_type === 'number' ? normalizeNumber(form.num_min) : null,
    num_max: form.data_type === 'number' ? normalizeNumber(form.num_max) : null,
    text_regex: form.data_type === 'text' ? form.text_regex.trim() || null : null,
    allowed_values: form.data_type === 'enum' ? enumValues.value : null,
      default_value: defaultValue,
      required: form.required,
      is_active: form.is_active,
      description: form.description.trim() || null,
      ref_kind: form.ref_kind.trim() || null,
      ref_domain: form.ref_domain.trim() || null,
      meta,
    }

    if (editing.value && selectedRow.value) {
      const { error } = await supabase
        .from(TABLE)
        .update(payload)
        .eq('attr_id', selectedRow.value.attr_id)
      if (error) throw error
      toast.success(t('common.saved'))
    } else {
      const insertPayload = {
        ...payload,
        tenant_id: tenant,
        scope: 'tenant',
        owner_id: tenant,
      }
      const { error } = await supabase.from(TABLE).insert(insertPayload)
      if (error) throw error
      toast.success(t('common.saved'))
    }

    await fetchAttrDefs()
    drawerOpen.value = false
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

function confirmDelete() {
  if (!selectedRow.value) return
  if (usageTotal(selectedRow.value) > 0) {
    toast.error(t('attrDef.errors.deleteUsed'))
    return
  }
  showDelete.value = true
}

async function deleteAttr() {
  if (!selectedRow.value) return
  try {
    saving.value = true
    const { error } = await supabase.from(TABLE).delete().eq('attr_id', selectedRow.value.attr_id)
    if (error) throw error
    toast.success(t('common.deleted'))
    showDelete.value = false
    drawerOpen.value = false
    await fetchAttrDefs()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

async function refreshAll() {
  try {
    await ensureTenant()
    await Promise.all([fetchIndustries(), fetchUoms(), fetchAttrDefs()])
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
}

watch(
  () => form.data_type,
  (value) => {
    if (value !== 'number') {
      form.num_min = null
      form.num_max = null
      form.uom_id = null
    }
    if (value !== 'text') {
      form.text_regex = ''
    }
    if (value !== 'enum') {
      enumValues.value = []
      enumDraft.value = ''
    }
  }
)

onMounted(async () => {
  await refreshAll()
})
</script>
