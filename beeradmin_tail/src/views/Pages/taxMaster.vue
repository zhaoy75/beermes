<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto">
      <header class="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('tax.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('tax.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <input
            v-model.trim="searchTerm"
            type="search"
            :placeholder="t('tax.searchPlaceholder')"
            class="w-60 h-[40px] border rounded px-3 text-sm"
          />
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">
            {{ t('common.new') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="fetchTaxes"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="hidden md:block overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('category')"
              >
                {{ t('labels.category') }}<span v-if="sortKey === 'category'"> {{ sortGlyph }}</span>
              </th>
              <th
                class="px-3 py-2 text-right text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('taxrate')"
              >
                {{ t('labels.taxrate') }}<span v-if="sortKey === 'taxrate'"> {{ sortGlyph }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('effect_date')"
              >
                {{ t('labels.effect_date') }}<span v-if="sortKey === 'effect_date'"> {{ sortGlyph }}</span>
              </th>
              <th
                class="px-3 py-2 text-left text-xs font-medium text-gray-600 cursor-pointer select-none"
                @click="setSort('expire_date')"
              >
                {{ t('labels.expire_date') }}<span v-if="sortKey === 'expire_date'"> {{ sortGlyph }}</span>
              </th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('labels.note') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in sortedRows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2">{{ categoryLabel(row.category) }}</td>
              <td class="px-3 py-2 text-right font-mono text-xs text-gray-700">{{ formatRate(row.taxrate) }}</td>
              <td class="px-3 py-2 text-xs text-gray-600">{{ formatDate(row.effect_date) }}</td>
              <td class="px-3 py-2 text-xs text-gray-600">{{ formatDate(row.expire_date) }}</td>
              <td class="px-3 py-2 text-sm text-gray-600">{{ row.note || '—' }}</td>
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
              <td colspan="6" class="px-3 py-8 text-center text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <section class="md:hidden grid gap-3">
        <div v-for="row in sortedRows" :key="row.id" class="border border-gray-200 rounded-xl shadow-sm p-4">
          <div class="flex items-start justify-between gap-3">
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">{{ categoryLabel(row.category) }}</p>
              <p class="font-mono text-sm text-gray-700">{{ formatRate(row.taxrate) }}</p>
            </div>
            <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openEdit(row)">
              {{ t('common.edit') }}
            </button>
          </div>
          <dl class="text-sm text-gray-600 space-y-1 mt-2">
            <div class="flex justify-between">
              <dt>{{ t('labels.effect_date') }}</dt>
              <dd>{{ formatDate(row.effect_date) }}</dd>
            </div>
            <div class="flex justify-between">
              <dt>{{ t('labels.expire_date') }}</dt>
              <dd>{{ formatDate(row.expire_date) }}</dd>
            </div>
            <div>
              <dt>{{ t('labels.note') }}</dt>
              <dd>{{ row.note || '—' }}</dd>
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
        <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ editing ? t('tax.editTitle') : t('tax.newTitle') }}</h3>
          </div>
          <div class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.category') }}<span class="text-red-600">*</span></label>
                <select v-model="form.category" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option disabled value="">{{ t('tax.categoryPlaceholder') }}</option>
                  <option v-for="option in categoryOptions" :key="option.value" :value="option.value">
                    {{ option.label }}
                  </option>
                </select>
                <p v-if="errors.category" class="mt-1 text-xs text-red-600">{{ errors.category }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.taxrate') }}<span class="text-red-600">*</span></label>
                <input
                  v-model="form.taxrate"
                  type="number"
                  step="0.01"
                  min="0"
                  class="w-full h-[40px] border rounded px-3"
                  placeholder="0.00"
                />
                <p v-if="errors.taxrate" class="mt-1 text-xs text-red-600">{{ errors.taxrate }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.effect_date') }}</label>
                <input v-model="form.effect_date" type="date" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.expire_date') }}</label>
                <input v-model="form.expire_date" type="date" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.expire_date" class="mt-1 text-xs text-red-600">{{ errors.expire_date }}</p>
              </div>
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1">{{ t('labels.note') }}</label>
                <input v-model.trim="form.note" class="w-full h-[40px] border rounded px-3" />
              </div>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">{{ t('common.cancel') }}</button>
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
            <h3 class="font-semibold">{{ t('tax.deleteTitle') }}</h3>
          </div>
          <div class="p-4 text-sm">{{ t('tax.deleteConfirm', { category: categoryLabel(toDelete?.category), rate: formatRate(toDelete?.taxrate ?? null) }) }}</div>
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
import { ref, reactive, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

type TaxRow = {
  id: string
  category: string
  note: string | null
  taxrate: number
  created_date: string
  effect_date: string | null
  expire_date: string | null
}

type SortKey = 'category' | 'taxrate' | 'effect_date' | 'expire_date'
type SortDirection = 'asc' | 'desc'

type CategoryRow = {
  id: string
  code: string
  name: string | null
}

const TABLE = 'tax_beer'
const CATEGORY_TABLE = 'mst_category'

const { t } = useI18n()
const pageTitle = computed(() => t('tax.title'))

const rows = ref<TaxRow[]>([])
const loading = ref(false)
const saving = ref(false)
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const toDelete = ref<TaxRow | null>(null)

const sortKey = ref<SortKey>('category')
const sortDirection = ref<SortDirection>('asc')
const searchTerm = ref('')

const blank = () => ({
  id: '',
  category: '' as string,
  note: '',
  taxrate: '',
  effect_date: '',
  expire_date: '',
})

const form = reactive<Record<string, any>>(blank())
const errors = reactive<Record<string, string>>({})

const categories = ref<CategoryRow[]>([])

type CategorySelectOption = {
  value: string
  label: string
}

const categoryOptions = computed<CategorySelectOption[]>(() =>
  categories.value.map((item) => ({
    value: item.code,
    label: item.name ? `${item.name} (${item.code})` : item.code,
  }))
)

const categoriesByCode = computed(() => {
  const map = new Map<string, CategoryOption>()
  categories.value.forEach((item) => {
    map.set(item.code, item)
  })
  return map
})

const filteredRows = computed(() => {
  const keyword = searchTerm.value.trim().toLowerCase()
  if (keyword === '') return rows.value
  return rows.value.filter((row) => {
    const categoryLabelText = categoryLabel(row.category)
    const joined = [row.category, categoryLabelText, row.note ?? '', row.effect_date ?? '', row.expire_date ?? '']
      .join(' ')
      .toLowerCase()
    return joined.includes(keyword)
  })
})

const sortedRows = computed(() => {
  const data = [...filteredRows.value]
  const direction = sortDirection.value === 'asc' ? 1 : -1
  const key = sortKey.value

  data.sort((a, b) => {
    const aVal = a[key]
    const bVal = b[key]

    if (key === 'taxrate') {
      return ((aVal as number) - (bVal as number)) * direction
    }

    const aStr = (aVal ?? '').toString().toLowerCase()
    const bStr = (bVal ?? '').toString().toLowerCase()

    if (key === 'effect_date' || key === 'expire_date') {
      const aTime = aStr ? Date.parse(aStr) : 0
      const bTime = bStr ? Date.parse(bStr) : 0
      return (aTime - bTime) * direction
    }

    return aStr.localeCompare(bStr) * direction
  })

  return data
})

const sortGlyph = computed(() => (sortDirection.value === 'asc' ? '▲' : '▼'))

function setSort(column: SortKey) {
  if (sortKey.value === column) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = column
    sortDirection.value = 'asc'
  }
}

function categoryLabel(value: string | null | undefined) {
  if (!value) return ''
  const match = categoriesByCode.value.get(value)
  if (match) {
    return match.name ? `${match.name} (${match.code})` : match.code
  }
  return value
}

function formatRate(value: number | string | null) {
  if (value == null || value === '') return '—'
  const num = Number(value)
  return Number.isFinite(num) ? num.toFixed(2) : String(value)
}

function formatDate(value: string | null) {
  if (!value) return '—'
  return value
}

function resetForm() {
  Object.assign(form, blank())
  Object.keys(errors).forEach((key) => delete errors[key])
}

function openCreate() {
  editing.value = false
  resetForm()
  form.category = categories.value[0]?.code ?? ''
  if (!form.category) {
    toast.warning(t('tax.missingCategories'))
  }
  showModal.value = true
}

function openEdit(row: TaxRow) {
  editing.value = true
  resetForm()
  Object.assign(form, {
    id: row.id,
    category: row.category,
    note: row.note ?? '',
    taxrate: formatRate(row.taxrate),
    effect_date: row.effect_date ?? '',
    expire_date: row.expire_date ?? '',
  })
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function confirmDelete(row: TaxRow) {
  toDelete.value = row
  showDelete.value = true
}

function validate() {
  Object.keys(errors).forEach((key) => delete errors[key])

  if (!form.category) {
    errors.category = t('errors.required', { field: t('labels.category') })
  } else if (!categoriesByCode.value.has(form.category)) {
    errors.category = t('tax.invalidCategory')
  }

  const rate = Number(form.taxrate)
  if (form.taxrate === '' || Number.isNaN(rate)) {
    errors.taxrate = t('errors.mustBeNumber', { field: t('labels.taxrate') })
  } else if (rate < 0) {
    errors.taxrate = t('errors.rateMin', { field: t('labels.taxrate') })
  }

  if (form.effect_date && form.expire_date) {
    const eff = Date.parse(form.effect_date)
    const exp = Date.parse(form.expire_date)
    if (!Number.isNaN(eff) && !Number.isNaN(exp) && eff > exp) {
      errors.expire_date = t('errors.expireAfter')
    }
  }

  return Object.keys(errors).length === 0
}

async function fetchTaxes() {
  loading.value = true
  const { data, error } = await supabase
    .from<TaxRow>(TABLE)
    .select('id, category, note, taxrate, created_date, effect_date, expire_date')
    .order('effect_date', { ascending: false })
  loading.value = false

  if (error) {
    toast.error('Fetch error: ' + error.message)
    return
  }

  rows.value = (data ?? []).map((item) => ({
    ...item,
    note: item.note ?? '',
    effect_date: item.effect_date ?? null,
    expire_date: item.expire_date ?? null,
  }))
}

async function fetchCategories() {
  const { data, error } = await supabase
    .from<CategoryRow>(CATEGORY_TABLE)
    .select('id, code, name')
    .order('code', { ascending: true })

  if (error) {
    toast.error('Category fetch error: ' + error.message)
    return
  }

  categories.value = data ?? []
}

async function saveRecord() {
  if (!validate()) return

  saving.value = true
  const normalizedRate = Math.round(Number(form.taxrate) * 100) / 100
  const payload = {
    category: form.category,
    note: form.note ? form.note.trim() : null,
    taxrate: normalizedRate,
    effect_date: form.effect_date || null,
    expire_date: form.expire_date || null,
  }

  let response
  if (editing.value) {
    response = await supabase
      .from(TABLE)
      .update(payload)
      .eq('id', form.id)
      .select('id, category, note, taxrate, created_date, effect_date, expire_date')
      .single()
  } else {
    response = await supabase
      .from(TABLE)
      .insert(payload)
      .select('id, category, note, taxrate, created_date, effect_date, expire_date')
      .single()
  }

  saving.value = false
  if (response.error) {
    toast.error('Save error: ' + response.error.message)
    return
  }

  const saved = response.data as TaxRow
  const normalized: TaxRow = {
    ...saved,
    note: saved.note ?? '',
    effect_date: saved.effect_date ?? null,
    expire_date: saved.expire_date ?? null,
  }

  const idx = rows.value.findIndex((row) => row.id === normalized.id)
  if (idx > -1) rows.value[idx] = normalized
  else rows.value.unshift(normalized)
  rows.value = [...rows.value]

  showModal.value = false
}

async function deleteRecord() {
  if (!toDelete.value) return

  const { error } = await supabase.from(TABLE).delete().eq('id', toDelete.value.id)
  if (error) {
    toast.error('Delete error: ' + error.message)
    return
  }

  rows.value = rows.value.filter((row) => row.id !== toDelete.value?.id)
  showDelete.value = false
  toDelete.value = null
}

onMounted(async () => {
  await Promise.all([fetchCategories(), fetchTaxes()])
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}

td:nth-child(5) {
  white-space: normal;
}
</style>
