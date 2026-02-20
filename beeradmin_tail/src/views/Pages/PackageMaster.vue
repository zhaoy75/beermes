<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="max-w-5xl mx-auto p-4 space-y-4">
      <header class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold text-gray-800">{{ t('package.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('package.subtitle') }}</p>
        </div>
        <div class="flex items-center gap-2">
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" type="button" @click="openCreate">
            {{ t('common.add') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-50"
            type="button"
            :disabled="loading"
            @click="fetchPackages"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm overflow-x-auto bg-white">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('package.columns.code') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('package.columns.name') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('package.columns.text') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('package.columns.unitVolume') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('package.columns.maxVolume') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('package.columns.volumeFixFlg') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('package.columns.volumeUom') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('package.columns.createdAt') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in rows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.package_code }}</td>
              <td class="px-3 py-2">{{ resolveName(row) || '—' }}</td>
              <td class="px-3 py-2 text-sm text-gray-600">{{ row.description || '—' }}</td>
              <td class="px-3 py-2 text-sm text-gray-700">{{ formatVolume(row.unit_volume) }}</td>
              <td class="px-3 py-2 text-sm text-gray-700">{{ formatVolume(row.max_volume) }}</td>
              <td class="px-3 py-2 text-sm text-gray-700">{{ resolveVolumeFixFlag(row) ? t('common.yes') : t('common.no') }}</td>
              <td class="px-3 py-2 text-sm text-gray-700">{{ resolveUomLabel(row.volume_uom) }}</td>
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
            <tr v-if="!loading && rows.length === 0">
              <td colspan="9" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>
    </div>

    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg border">
        <header class="px-4 py-3 border-b">
          <h3 class="font-semibold">{{ editing ? t('package.editTitle') : t('package.newTitle') }}</h3>
        </header>
        <section class="p-4 space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm text-gray-600 mb-1">
                {{ t('package.columns.code') }}<span class="text-red-600">*</span>
              </label>
              <input
                v-model.trim="form.package_code"
                class="w-full h-[40px] border rounded px-3"
                :placeholder="t('package.placeholders.code')"
              />
              <p v-if="errors.package_code" class="mt-1 text-xs text-red-600">{{ errors.package_code }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('package.columns.name') }}</label>
              <input
                v-model.trim="form.name"
                class="w-full h-[40px] border rounded px-3"
                :placeholder="t('package.placeholders.name')"
              />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">
                {{ t('package.columns.unitVolume') }}<span class="text-red-600">*</span>
              </label>
              <input
                v-model="form.unit_volume"
                type="number"
                step="0.000001"
                class="w-full h-[40px] border rounded px-3"
                :placeholder="t('package.placeholders.unitVolume')"
              />
              <p v-if="errors.unit_volume" class="mt-1 text-xs text-red-600">{{ errors.unit_volume }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">
                {{ t('package.columns.maxVolume') }}
              </label>
              <input
                v-model="form.max_volume"
                type="number"
                step="0.000001"
                class="w-full h-[40px] border rounded px-3"
                :placeholder="t('package.placeholders.maxVolume')"
              />
              <p v-if="errors.max_volume" class="mt-1 text-xs text-red-600">{{ errors.max_volume }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">
                {{ t('package.columns.volumeUom') }}<span class="text-red-600">*</span>
              </label>
              <select v-model="form.volume_uom" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in volumeUomOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
              </select>
              <p v-if="errors.volume_uom" class="mt-1 text-xs text-red-600">{{ errors.volume_uom }}</p>
            </div>
            <div class="md:col-span-2">
              <label class="inline-flex items-center gap-2 text-sm text-gray-700">
                <input v-model="form.volume_fix_flg" type="checkbox" class="h-4 w-4" />
                {{ t('package.columns.volumeFixFlg') }}
              </label>
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{ t('package.columns.text') }}</label>
              <textarea
                v-model.trim="form.description"
                rows="3"
                class="w-full border rounded px-3 py-2"
                :placeholder="t('package.placeholders.text')"
              ></textarea>
            </div>
          </div>
        </section>
        <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
          <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="closeModal">
            {{ t('common.cancel') }}
          </button>
          <button
            class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
            type="button"
            :disabled="saving"
            @click="saveRecord"
          >
            {{ saving ? t('common.saving') : t('common.save') }}
          </button>
        </footer>
      </div>
    </div>

    <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
        <header class="px-4 py-3 border-b">
          <h3 class="font-semibold">{{ t('package.deleteTitle') }}</h3>
        </header>
        <div class="p-4 text-sm">{{ t('package.deleteConfirm', { code: toDelete?.package_code ?? '' }) }}</div>
        <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
          <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="showDelete = false">
            {{ t('common.cancel') }}
          </button>
          <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700" type="button" @click="deleteRecord">
            {{ t('common.delete') }}
          </button>
        </footer>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'

type PackageRow = {
  id: string
  package_code: string
  name_i18n: Record<string, string> | null
  description: string | null
  unit_volume: number
  max_volume: number | null
  volume_fix_flg: boolean | null
  qty_fix_flg: boolean | null
  fixed_qty: boolean | null
  volume_uom: string
  created_at: string | null
}

const TABLE = 'mst_package'

const { t, locale } = useI18n()
const pageTitle = computed(() => t('package.title'))

const rows = ref<PackageRow[]>([])
const volumeUoms = ref<{ id: string; code: string; name: string | null; dimension: string | null }[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const toDelete = ref<PackageRow | null>(null)

const form = reactive({
  id: '',
  package_code: '',
  name: '',
  name_i18n: {} as Record<string, string>,
  description: '',
  unit_volume: '',
  max_volume: '',
  volume_fix_flg: true,
  volume_uom: '',
})

const errors = reactive<Record<string, string>>({})
const volumeUomOptions = computed(() =>
  volumeUoms.value.map((row) => ({
    value: row.id,
    label: row.name ? `${row.code} - ${row.name}` : row.code,
  }))
)

function resolveLang() {
  return String(locale.value ?? '').toLowerCase().startsWith('ja') ? 'ja' : 'en'
}

function syncFormNameToLocale() {
  const lang = resolveLang()
  const fromI18n = form.name_i18n?.[lang]
  form.name = fromI18n ?? ''
}

function resolveName(row: PackageRow) {
  const lang = resolveLang()
  if (row.name_i18n && row.name_i18n[lang]) return row.name_i18n[lang]
  const fallback = row.name_i18n ? Object.values(row.name_i18n)[0] : ''
  return fallback || ''
}

function formatVolume(value: number | null) {
  if (value == null) return '—'
  const num = Number(value)
  return Number.isFinite(num) ? num.toLocaleString(undefined, { maximumFractionDigits: 6 }) : String(value)
}

function formatTimestamp(value: string | null) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
  } catch {
    return value
  }
}

function resolveUomLabel(value: string | null) {
  if (!value) return '—'
  const match = volumeUoms.value.find((row) => row.id === value)
  if (!match) return value
  return match.name ? `${match.code} - ${match.name}` : match.code
}

function resolveVolumeFixFlag(row: PackageRow) {
  if (typeof row.volume_fix_flg === 'boolean') return row.volume_fix_flg
  if (typeof row.qty_fix_flg === 'boolean') return row.qty_fix_flg
  if (typeof row.fixed_qty === 'boolean') return row.fixed_qty
  return true
}

function openCreate() {
  editing.value = false
  Object.assign(form, {
    id: '',
    package_code: '',
    name: '',
    name_i18n: {},
    description: '',
    unit_volume: '',
    max_volume: '',
    volume_fix_flg: true,
    volume_uom: '',
  })
  const defaultUom = volumeUoms.value.find((row) => row.code === 'L')?.id
  if (defaultUom) form.volume_uom = defaultUom
  Object.keys(errors).forEach((key) => delete errors[key])
  showModal.value = true
}

function openEdit(row: PackageRow) {
  editing.value = true
  const lang = resolveLang()
  Object.assign(form, {
    id: row.id,
    package_code: row.package_code,
    name: row.name_i18n?.[lang] ?? '',
    name_i18n: row.name_i18n ?? {},
    description: row.description ?? '',
    unit_volume: row.unit_volume != null ? String(row.unit_volume) : '',
    max_volume: row.max_volume != null ? String(row.max_volume) : '',
    volume_fix_flg: resolveVolumeFixFlag(row),
    volume_uom: row.volume_uom ?? '',
  })
  Object.keys(errors).forEach((key) => delete errors[key])
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function validateForm() {
  Object.keys(errors).forEach((key) => delete errors[key])
  if (!form.package_code) errors.package_code = t('errors.required', { field: t('package.columns.code') })
  if (!form.unit_volume || isNaN(Number(form.unit_volume))) {
    errors.unit_volume = t('errors.mustBeNumber', { field: t('package.columns.unitVolume') })
  } else if (Number(form.unit_volume) <= 0) {
    errors.unit_volume = t('errors.mustBePositive', { field: t('package.columns.unitVolume') })
  }
  if (form.max_volume !== '') {
    if (isNaN(Number(form.max_volume))) {
      errors.max_volume = t('errors.mustBeNumber', { field: t('package.columns.maxVolume') })
    } else if (Number(form.max_volume) <= 0) {
      errors.max_volume = t('errors.mustBePositive', { field: t('package.columns.maxVolume') })
    }
  }
  if (!form.volume_uom) {
    errors.volume_uom = t('errors.required', { field: t('package.columns.volumeUom') })
  }
  return Object.keys(errors).length === 0
}

async function fetchVolumeUoms() {
  try {
    const { data, error } = await supabase
      .from('mst_uom')
      .select('id, code, name, dimension')
      .eq('dimension', 'volume')
      .order('code', { ascending: true })
    if (error) throw error
    volumeUoms.value = (data ?? []) as { id: string; code: string; name: string | null; dimension: string | null }[]
    if (!form.volume_uom) {
      const preferred = volumeUoms.value.find((row) => row.code === 'L')?.id
      form.volume_uom = preferred || volumeUoms.value[0]?.id || ''
    }
  } catch (err) {
    console.error(err)
    volumeUoms.value = []
  }
}

async function fetchPackages() {
  try {
    loading.value = true
    const { data, error } = await supabase
      .from(TABLE)
      .select('*')
      .order('package_code', { ascending: true })
    if (error) throw error
    rows.value = ((data ?? []) as any[]).map((row) => ({
      id: String(row.id),
      package_code: String(row.package_code ?? ''),
      name_i18n: (row.name_i18n ?? null) as Record<string, string> | null,
      description: row.description ?? null,
      unit_volume: row.unit_volume != null ? Number(row.unit_volume) : 0,
      max_volume: row.max_volume != null ? Number(row.max_volume) : null,
      volume_fix_flg: typeof row.volume_fix_flg === 'boolean' ? row.volume_fix_flg : null,
      qty_fix_flg: typeof row.qty_fix_flg === 'boolean' ? row.qty_fix_flg : null,
      fixed_qty: typeof row.fixed_qty === 'boolean' ? row.fixed_qty : null,
      volume_uom: String(row.volume_uom ?? ''),
      created_at: row.created_at ?? null,
    }))
  } catch (err) {
    console.error(err)
    rows.value = []
  } finally {
    loading.value = false
  }
}

async function saveRecord() {
  if (!validateForm()) return
  try {
    saving.value = true
    const lang = resolveLang()
    const mergedName = { ...(form.name_i18n || {}) }
    if (form.name) mergedName[lang] = form.name

    const payload = {
      package_code: form.package_code.trim(),
      name_i18n: mergedName,
      description: form.description ? form.description.trim() : null,
      unit_volume: Number(form.unit_volume),
      max_volume: form.max_volume === '' ? null : Number(form.max_volume),
      volume_uom: form.volume_uom,
    }

    const payloadQtyFix = {
      ...payload,
      volume_fix_flg: Boolean(form.volume_fix_flg),
    }
    const payloadLegacyQtyFix = {
      ...payload,
      qty_fix_flg: Boolean(form.volume_fix_flg),
    }
    const payloadFixedQty = {
      ...payload,
      fixed_qty: Boolean(form.volume_fix_flg),
    }

    if (editing.value && form.id) {
      let { error } = await supabase.from(TABLE).update(payloadQtyFix).eq('id', form.id)
      if (error) {
        const retryLegacy = await supabase.from(TABLE).update(payloadLegacyQtyFix).eq('id', form.id)
        error = retryLegacy.error
      }
      if (error) {
        const retryFixed = await supabase.from(TABLE).update(payloadFixedQty).eq('id', form.id)
        error = retryFixed.error
      }
      if (error) throw error
    } else {
      let { error } = await supabase.from(TABLE).insert(payloadQtyFix)
      if (error) {
        const retryLegacy = await supabase.from(TABLE).insert(payloadLegacyQtyFix)
        error = retryLegacy.error
      }
      if (error) {
        const retryFixed = await supabase.from(TABLE).insert(payloadFixedQty)
        error = retryFixed.error
      }
      if (error) throw error
    }

    showModal.value = false
    await fetchPackages()
  } catch (err) {
    console.error(err)
  } finally {
    saving.value = false
  }
}

function confirmDelete(row: PackageRow) {
  toDelete.value = row
  showDelete.value = true
}

async function deleteRecord() {
  if (!toDelete.value) return
  try {
    const { error } = await supabase.from(TABLE).delete().eq('id', toDelete.value.id)
    if (error) throw error
    showDelete.value = false
    toDelete.value = null
    await fetchPackages()
  } catch (err) {
    console.error(err)
  }
}

onMounted(async () => {
  await Promise.all([fetchPackages(), fetchVolumeUoms()])
})

watch(
  () => locale.value,
  () => {
    if (showModal.value) {
      syncFormNameToLocale()
    }
  }
)
</script>
