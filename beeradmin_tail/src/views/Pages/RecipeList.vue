<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <section
      class="mb-6 bg-white shadow rounded-lg p-4 border border-gray-200"
      aria-labelledby="recipeSearchHeading"
    >
      <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between mb-4">
        <div>
          <h2 id="recipeSearchHeading" class="text-lg font-semibold text-gray-900">
            {{ t('recipe.list.searchTitle') }}
          </h2>
          <p class="text-sm text-gray-500">{{ t('recipe.list.showing', { count: filteredRecipes.length }) }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button
            class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700"
            :disabled="loading"
            @click="openCreate"
          >
            {{ t('common.new') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-60"
            :disabled="loading"
            @click="refresh"
          >
            {{ t('common.refresh') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100"
            :disabled="loading"
            @click="resetFilters"
          >
            {{ t('recipe.list.reset') }}
          </button>
        </div>
      </div>

      <form class="grid grid-cols-1 md:grid-cols-4 gap-4" @submit.prevent>
        <div>
          <label for="recipeName" class="block text-sm text-gray-600 mb-1">
            {{ t('recipe.list.name') }}
          </label>
          <input
            id="recipeName"
            v-model.trim="filters.name"
            type="search"
            class="w-full h-[40px] border rounded px-3"
            :placeholder="t('recipe.list.keywordPh')"
          />
        </div>
        <div>
          <label for="recipeStyle" class="block text-sm text-gray-600 mb-1">
            {{ t('recipe.list.style') }}
          </label>
          <select
            id="recipeStyle"
            v-model="filters.style"
            class="w-full h-[40px] border rounded px-3 bg-white"
          >
            <option value="">{{ t('recipe.list.all') }}</option>
            <option v-for="style in styleOptions" :key="style" :value="style">
              {{ style || '—' }}
            </option>
          </select>
        </div>
        <div>
          <label for="recipeStatus" class="block text-sm text-gray-600 mb-1">
            {{ t('recipe.list.status') }}
          </label>
          <select
            id="recipeStatus"
            v-model="filters.status"
            class="w-full h-[40px] border rounded px-3 bg-white"
          >
            <option value="">{{ t('recipe.list.all') }}</option>
            <option v-for="status in STATUSES" :key="status" :value="status">
              {{ statusLabel(status) }}
            </option>
          </select>
        </div>
        <div class="flex items-center gap-2 pt-6">
          <input
            id="showAllVersions"
            v-model="showAllVersions"
            type="checkbox"
            class="h-4 w-4"
          />
          <label for="showAllVersions" class="text-sm text-gray-700">
            {{ t('recipe.list.showAllVersions') }}
          </label>
        </div>
      </form>
    </section>

    <section class="bg-white shadow rounded-lg border border-gray-200 overflow-hidden" aria-labelledby="recipeTableHeading">
      <h2 id="recipeTableHeading" class="sr-only">{{ t('recipe.list.title') }}</h2>

      <div class="hidden md:block overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50 text-xs text-gray-600 uppercase">
            <tr>
              <th class="px-3 py-2 text-left">
                <button class="inline-flex items-center gap-1" @click="setSort('code')">
                  {{ t('recipe.list.recipeId') }}
                  <span class="text-xs">{{ sortIcon('code') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left">
                <button class="inline-flex items-center gap-1" @click="setSort('name')">
                  {{ t('recipe.list.name') }}
                  <span class="text-xs">{{ sortIcon('name') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left">
                <button class="inline-flex items-center gap-1" @click="setSort('version')">
                  {{ t('recipe.list.version') }}
                  <span class="text-xs">{{ sortIcon('version') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left">
                <button class="inline-flex items-center gap-1" @click="setSort('status')">
                  {{ t('recipe.list.status') }}
                  <span class="text-xs">{{ sortIcon('status') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left">
                <button class="inline-flex items-center gap-1" @click="setSort('created_at')">
                  {{ t('recipe.list.created') }}
                  <span class="text-xs">{{ sortIcon('created_at') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left">{{ t('recipe.list.category') }}</th>
              <th class="px-3 py-2 text-left">{{ t('recipe.list.style') }}</th>
              <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100 text-sm">
            <tr v-for="row in sortedRecipes" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.code }}</td>
              <td class="px-3 py-2">
                <button class="text-blue-600 hover:underline" @click="goEdit(row)">
                  {{ row.name }}
                </button>
              </td>
              <td class="px-3 py-2">v{{ row.version }}</td>
              <td class="px-3 py-2">
                <span class="px-2 py-1 rounded-full text-xs"
                  :class="statusChip(row.status)">
                  {{ statusLabel(row.status) }}
                </span>
              </td>
              <td class="px-3 py-2 text-xs text-gray-500">{{ formatDate(row.created_at) }}</td>
              <td class="px-3 py-2">{{ categoryLabel(row.category) }}</td>
              <td class="px-3 py-2">{{ row.style || '—' }}</td>
              <td class="px-3 py-2 space-x-2">
                <button
                  class="px-2 py-1 text-xs rounded border hover:bg-gray-100 disabled:opacity-60"
                  :disabled="copyingId === row.id || copying"
                  @click="openCopy(row)"
                >
                  {{ copyingId === row.id ? t('common.copying') : t('common.copy') }}
                </button>
                <button
                  class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700"
                  @click="confirmDelete(row)"
                >
                  {{ t('common.delete') }}
                </button>
              </td>
            </tr>
            <tr v-if="!loading && sortedRecipes.length === 0">
              <td colspan="8" class="px-3 py-6 text-center text-gray-500">
                {{ t('common.noData') }}
              </td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="md:hidden divide-y divide-gray-200">
        <article
          v-for="row in sortedRecipes"
          :key="`card-${row.id}`"
          class="p-4"
        >
          <header class="flex items-start justify-between">
            <div>
              <p class="text-xs uppercase tracking-wide text-gray-400">{{ row.code }}</p>
              <button class="text-base font-semibold text-blue-600" @click="goEdit(row)">
                {{ row.name }}
              </button>
            </div>
            <span class="px-2 py-1 text-xs rounded-full" :class="statusChip(row.status)">
              {{ statusLabel(row.status) }}
            </span>
          </header>
          <dl class="mt-2 text-sm text-gray-600 space-y-1">
            <div class="flex justify-between">
              <dt>{{ t('recipe.list.version') }}</dt>
              <dd>v{{ row.version }}</dd>
            </div>
            <div class="flex justify-between">
              <dt>{{ t('recipe.list.style') }}</dt>
              <dd>{{ row.style || '—' }}</dd>
            </div>
            <div class="flex justify-between">
              <dt>{{ t('recipe.list.category') }}</dt>
              <dd>{{ categoryLabel(row.category) }}</dd>
            </div>
            <div class="flex justify-between text-xs text-gray-500">
              <dt>{{ t('recipe.list.created') }}</dt>
              <dd>{{ formatDate(row.created_at) }}</dd>
            </div>
          </dl>
          <footer class="mt-3 flex gap-2">
            <button
              class="px-3 py-2 text-sm rounded border hover:bg-gray-100 disabled:opacity-60"
              :disabled="copyingId === row.id || copying"
              @click="openCopy(row)"
            >
              {{ copyingId === row.id ? t('common.copying') : t('common.copy') }}
            </button>
            <button class="px-3 py-2 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">
              {{ t('common.delete') }}
            </button>
          </footer>
        </article>
        <p v-if="!loading && sortedRecipes.length === 0" class="p-4 text-sm text-gray-500 text-center">
          {{ t('common.noData') }}
        </p>
      </div>
    </section>

    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg border border-gray-200">
        <header class="px-4 py-3 border-b">
          <h3 class="font-semibold text-gray-900">
            {{ editing ? t('recipe.list.editTitle') : t('recipe.list.newTitle') }}
          </h3>
        </header>
        <section class="p-4 space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.recipeId') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="form.code" class="w-full h-[40px] border rounded px-3" />
              <p v-if="errors.code" class="mt-1 text-xs text-red-600">{{ errors.code }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.version') }}<span class="text-red-600">*</span></label>
              <input v-model.number="form.version" type="number" min="1" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.name') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="form.name" class="w-full h-[40px] border rounded px-3" />
              <p v-if="errors.name" class="mt-1 text-xs text-red-600">{{ errors.name }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.status') }}<span class="text-red-600">*</span></label>
              <select v-model="form.status" class="w-full h-[40px] border rounded px-3 bg-white">
                <option v-for="status in STATUSES" :key="status" :value="status">
                  {{ t('recipe.statusMap.' + status) }}
                </option>
              </select>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.category') }}</label>
              <select v-model="form.category" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('recipe.list.selectCategory') }}</option>
                <option v-for="option in categoryOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.style') }}</label>
              <input v-model.trim="form.style" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{ t('labels.note') }}</label>
              <textarea v-model.trim="form.notes" rows="3" class="w-full border rounded px-3 py-2"></textarea>
            </div>
          </div>
        </section>
        <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
          <button class="px-3 py-2 rounded border hover:bg-gray-100" @click="closeModal">
            {{ t('common.cancel') }}
          </button>
          <button
            class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
            :disabled="saving"
            @click="saveRecipe"
          >
            {{ saving ? t('common.saving') : t('common.save') }}
          </button>
        </footer>
      </div>
    </div>

    <div v-if="showCopyModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-md bg-white rounded-xl shadow-lg border border-gray-200">
        <header class="px-4 py-3 border-b">
          <h3 class="font-semibold text-gray-900">{{ t('recipe.list.copyTitle') }}</h3>
          <p class="text-sm text-gray-500 mt-1">{{ t('recipe.list.copyDescription') }}</p>
        </header>
        <section class="p-4 space-y-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.recipeId') }}<span class="text-red-600">*</span></label>
            <input v-model.trim="copyForm.code" class="w-full h-[40px] border rounded px-3" />
            <p v-if="copyErrors.code" class="text-xs text-red-600 mt-1">{{ copyErrors.code }}</p>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.name') }}<span class="text-red-600">*</span></label>
            <input v-model.trim="copyForm.name" class="w-full h-[40px] border rounded px-3" />
            <p v-if="copyErrors.name" class="text-xs text-red-600 mt-1">{{ copyErrors.name }}</p>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.style') }}</label>
            <input v-model.trim="copyForm.style" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div class="text-xs text-gray-500 bg-gray-50 border border-dashed border-gray-200 rounded px-3 py-2">
            {{ t('recipe.list.copyVersionNote') }}
          </div>
        </section>
        <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
          <button class="px-3 py-2 rounded border hover:bg-gray-100" @click="closeCopyModal()">
            {{ t('common.cancel') }}
          </button>
          <button
            class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-60"
            :disabled="copying"
            @click="executeCopy"
          >
            {{ copying ? t('common.copying') : t('recipe.list.copyConfirm') }}
          </button>
        </footer>
      </div>
    </div>

    <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-md bg-white rounded-xl shadow-lg border border-gray-200">
        <header class="px-4 py-3 border-b">
          <h3 class="font-semibold text-gray-900">{{ t('common.delete') }}</h3>
        </header>
        <section class="p-4 text-sm text-gray-700">
          {{ t('recipe.list.deleteConfirm', { name: toDelete?.name ?? '', version: toDelete?.version ?? '' }) }}
        </section>
        <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
          <button class="px-3 py-2 rounded border hover:bg-gray-100" @click="showDelete = false">
            {{ t('common.cancel') }}
          </button>
          <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700" @click="deleteRecipe">
            {{ t('common.delete') }}
          </button>
        </footer>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, reactive, ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

const STATUSES = ['draft', 'released', 'retired'] as const

const { t } = useI18n()
const router = useRouter()

const pageTitle = computed(() => t('recipe.list.title'))

interface RecipeRow {
  id: string
  code: string
  name: string
  style: string | null
  version: number
  status: string
  notes: string | null
  created_at: string | null
  category: string | null
}

interface CategoryRow {
  def_id: string
  def_key: string
  spec: Record<string, any>
}

type SortKey = 'code' | 'name' | 'version' | 'status' | 'created_at'
type SortDirection = 'asc' | 'desc'

const recipes = ref<RecipeRow[]>([])
const loading = ref(false)
const saving = ref(false)
const sortKey = ref<SortKey>('created_at')
const sortDirection = ref<SortDirection>('desc')
const categories = ref<CategoryRow[]>([])

const filters = reactive({
  name: '',
  style: '',
  status: '',
})

const form = reactive({
  id: '',
  code: '',
  name: '',
  style: '',
  category: '',
  version: 1,
  status: STATUSES[0],
  notes: '',
})

const errors = reactive<Record<string, string>>({})
const showModal = ref(false)
const showDelete = ref(false)
const editing = ref(false)
const toDelete = ref<RecipeRow | null>(null)
const copyingId = ref<string | null>(null)
const showAllVersions = ref(false)
const showCopyModal = ref(false)
const copyTarget = ref<RecipeRow | null>(null)
const copyForm = reactive({ code: '', name: '', style: '' })
const copyErrors = reactive<Record<string, string>>({})
const copying = ref(false)

const styleOptions = computed(() => {
  const set = new Set<string>()
  recipes.value.forEach((row) => {
    if (row.style) set.add(row.style)
  })
  return Array.from(set).sort((a, b) => a.localeCompare(b))
})

const categoryMap = computed(() => {
  const map = new Map<string, string>()
  categories.value.forEach((row) => {
    const label = typeof row.spec?.name === 'string' ? row.spec.name : row.def_key
    map.set(row.def_id, label || row.def_key)
  })
  return map
})

const categoryOptions = computed(() =>
  categories.value.map((row) => ({
    value: row.def_id,
    label: typeof row.spec?.name === 'string' ? row.spec.name : row.def_key,
  })),
)

const filteredRecipes = computed(() => {
  const nameTerm = filters.name.trim().toLowerCase()
  const styleTerm = filters.style.trim().toLowerCase()
  const base = recipes.value.filter((row) => {
    const matchesName = !nameTerm || row.name.toLowerCase().includes(nameTerm) || row.code.toLowerCase().includes(nameTerm)
    const matchesStyle = !styleTerm || (row.style?.toLowerCase() ?? '').includes(styleTerm)
    const matchesStatus = !filters.status || row.status === filters.status
    return matchesName && matchesStyle && matchesStatus
  })
  if (showAllVersions.value) return base

  const latestByCode = new Map<string, RecipeRow>()
  for (const row of base) {
    const existing = latestByCode.get(row.code)
    if (!existing) {
      latestByCode.set(row.code, row)
      continue
    }

    const existingVersion = existing.version ?? 0
    const currentVersion = row.version ?? 0
    const existingTimeRaw = existing.created_at ? new Date(existing.created_at).getTime() : Number.NaN
    const currentTimeRaw = row.created_at ? new Date(row.created_at).getTime() : Number.NaN
    const existingTime = Number.isNaN(existingTimeRaw) ? 0 : existingTimeRaw
    const currentTime = Number.isNaN(currentTimeRaw) ? 0 : currentTimeRaw

    const isNewerVersion = currentVersion > existingVersion
    const isSameVersionNewerDate = currentVersion === existingVersion && currentTime > existingTime

    if (isNewerVersion || isSameVersionNewerDate) {
      latestByCode.set(row.code, row)
    }
  }

  return Array.from(latestByCode.values())
})

const sortedRecipes = computed(() => {
  const sorted = [...filteredRecipes.value]
  sorted.sort((a, b) => {
    const key = sortKey.value
    const dir = sortDirection.value === 'asc' ? 1 : -1

    const av = a[key]
    const bv = b[key]

    if (av === null || av === undefined) return 1
    if (bv === null || bv === undefined) return -1

    if (typeof av === 'number' && typeof bv === 'number') {
      return (av - bv) * dir
    }

    const aStr = String(av).toLowerCase()
    const bStr = String(bv).toLowerCase()
    if (aStr < bStr) return -1 * dir
    if (aStr > bStr) return 1 * dir
    return 0
  })
  return sorted
})

const sortIcon = (key: SortKey) => {
  if (sortKey.value !== key) return ''
  return sortDirection.value === 'asc' ? '▲' : '▼'
}

const statusChip = (status: string) => {
  if (status === 'released') return 'bg-green-100 text-green-800'
  if (status === 'draft') return 'bg-yellow-100 text-yellow-800'
  if (status === 'retired') return 'bg-gray-200 text-gray-600'
  return 'bg-gray-100 text-gray-600'
}

const statusLabel = (status: string) => {
  const key = `recipe.statusMap.${status}`
  const label = t(key)
  return label === key ? status : label
}

function setSort(key: SortKey) {
  if (sortKey.value === key) {
    sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
  } else {
    sortKey.value = key
    sortDirection.value = key === 'created_at' ? 'desc' : 'asc'
  }
}

function formatDate(input: string | null) {
  if (!input) return '—'
  const date = new Date(input)
  if (Number.isNaN(date.getTime())) return input
  return date.toLocaleString()
}

function openCreate() {
  editing.value = false
  resetForm()
  form.version = 1
  form.status = STATUSES[0]
  showModal.value = true
}

function closeModal() {
  showModal.value = false
}

function confirmDelete(row: RecipeRow) {
  toDelete.value = row
  showDelete.value = true
}

function resetFilters() {
  filters.name = ''
  filters.style = ''
  filters.status = ''
}

function resetForm() {
  form.id = ''
  form.code = ''
  form.name = ''
  form.style = ''
  form.category = ''
  form.version = 1
  form.status = STATUSES[0]
  form.notes = ''
  Object.keys(errors).forEach((key) => delete errors[key])
}

function validate() {
  Object.keys(errors).forEach((key) => delete errors[key])
  if (!form.code) errors.code = t('errors.required', { field: t('recipe.list.recipeId') })
  if (!form.name) errors.name = t('errors.required', { field: t('recipe.list.name') })
  return Object.keys(errors).length === 0
}

async function fetchCategories() {
  try {
    const { data, error } = await supabase
      .from('registry_def')
      .select('def_id, def_key, spec')
      .eq('kind', 'alcohol_type')
      .eq('is_active', true)
      .order('def_key', { ascending: true })
    if (error) throw error
    categories.value = data ?? []
  } catch (err) {
    console.warn('Failed to load categories', err)
  }
}

async function fetchRecipes() {
  loading.value = true
  const { data, error } = await supabase
    .from('mes_recipes')
    .select('id, code, name, style, version, status, notes, created_at, category')
    .order('created_at', { ascending: false, nullsFirst: false })
  loading.value = false
  if (error) {
    toast.error('Load error: ' + error.message)
    return
  }
  recipes.value = data ?? []
}

async function refresh() {
  await fetchRecipes()
}

async function saveRecipe() {
  if (!validate()) return

  saving.value = true
  const payload = {
    code: form.code.trim(),
    name: form.name.trim(),
    style: form.style.trim() || null,
    version: form.version || 1,
    status: form.status,
    notes: form.notes.trim() || null,
    category: form.category || null,
  }

  let response
  if (editing.value && form.id) {
    response = await supabase
      .from('mes_recipes')
      .update(payload)
      .eq('id', form.id)
      .select('id, code, name, style, version, status, notes, created_at, category')
      .single()
  } else {
    response = await supabase
      .from('mes_recipes')
      .insert({ ...payload })
      .select('id, code, name, style, version, status, notes, created_at, category')
      .single()
  }

  saving.value = false
  if (response.error) {
    toast.error('Save error: ' + response.error.message)
    return
  }

  const saved = response.data
  if (!saved) return

  if (editing.value) {
    const idx = recipes.value.findIndex((row) => row.id === saved.id)
    if (idx >= 0) recipes.value[idx] = saved
  } else {
    recipes.value.unshift(saved)
  }

  closeModal()
}

async function deleteRecipe() {
  if (!toDelete.value) return
  const { error } = await supabase.from('mes_recipes').delete().eq('id', toDelete.value.id)
  if (error) {
    toast.error('Delete error: ' + error.message)
    return
  }
  recipes.value = recipes.value.filter((row) => row.id !== toDelete.value?.id)
  showDelete.value = false
  toDelete.value = null
}

function goEdit(row: RecipeRow) {
  router.push(`/recipeEdit/${row.id}/${row.version}`)
}

function categoryLabel(id: string | null | undefined) {
  if (!id) return '—'
  return categoryMap.value.get(id) ?? '—'
}

const normalizeObject = (value: unknown) => {
  if (value && typeof value === 'object' && !Array.isArray(value)) return value as Record<string, unknown>
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value)
      return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
        ? (parsed as Record<string, unknown>)
        : {}
    } catch {
      return {}
    }
  }
  return {}
}

const normalizeArray = (value: unknown) => {
  if (Array.isArray(value)) return value as unknown[]
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value)
      return Array.isArray(parsed) ? parsed : []
    } catch {
      return []
    }
  }
  return []
}

function resetCopyErrors() {
  Object.keys(copyErrors).forEach((key) => delete copyErrors[key])
}

function openCopy(row: RecipeRow) {
  resetCopyErrors()
  copyTarget.value = row
  const suffix = (t('recipe.list.copySuffix') || 'copy').trim()
  const normalizedSuffix = suffix ? suffix.replace(/\s+/g, '-') : 'copy'
  const codeLowerSuffix = normalizedSuffix.toLowerCase()
  const codeAlreadyHasSuffix = row.code.toLowerCase().endsWith(`-${codeLowerSuffix}`)
  copyForm.code = codeAlreadyHasSuffix ? row.code : `${row.code}-${normalizedSuffix}`
  copyForm.name = suffix ? `${row.name} ${suffix}`.trim() : row.name
  copyForm.style = row.style ?? ''
  copyingId.value = null
  showCopyModal.value = true
}

function closeCopyModal(force = false) {
  if (copying.value && !force) return
  showCopyModal.value = false
  copyTarget.value = null
  copyForm.code = ''
  copyForm.name = ''
  copyForm.style = ''
  copying.value = false
  copyingId.value = null
  resetCopyErrors()
}

async function executeCopy() {
  if (!copyTarget.value || copying.value) return

  resetCopyErrors()
  const trimmedCode = copyForm.code.trim()
  const trimmedName = copyForm.name.trim()
  const trimmedStyle = copyForm.style.trim()

  if (!trimmedCode) copyErrors.code = t('errors.required', { field: t('recipe.list.recipeId') })
  if (!trimmedName) copyErrors.name = t('errors.required', { field: t('recipe.list.name') })
  if (Object.keys(copyErrors).length > 0) return

  copying.value = true
  copyingId.value = copyTarget.value.id

  try {
    const { data: original, error: loadError } = await supabase
      .from('mes_recipes')
      .select('id, code, name, style, version, status, notes, batch_size_l, target_og, target_fg, target_abv, target_ibu, target_srm, category')
      .eq('id', copyTarget.value.id)
      .single()
    if (loadError || !original) throw loadError ?? new Error('Missing recipe')

    const { data: inserted, error: insertError } = await supabase
      .from('mes_recipes')
      .insert({
        code: trimmedCode,
        name: trimmedName,
        style: trimmedStyle || null,
        version: 1,
        status: 'draft',
        notes: original.notes,
        batch_size_l: original.batch_size_l,
        target_og: original.target_og,
        target_fg: original.target_fg,
        target_abv: original.target_abv,
        target_ibu: original.target_ibu,
        target_srm: original.target_srm,
        category: original.category,
      })
      .select('id, code, name, style, version, status, notes, created_at')
      .single()
    if (insertError || !inserted) throw insertError ?? new Error('Insert failed')

    const { data: ingredientRows, error: ingredientLoadError } = await supabase
      .from('mes_ingredients')
      .select('material_id, amount, uom_id, usage_stage, notes')
      .eq('recipe_id', copyTarget.value.id)
    if (ingredientLoadError) throw ingredientLoadError

    if (ingredientRows && ingredientRows.length > 0) {
      const ingredientPayload = ingredientRows.map((item) => ({
        recipe_id: inserted.id,
        material_id: item.material_id,
        amount: item.amount,
        uom_id: item.uom_id,
        usage_stage: item.usage_stage,
        notes: item.notes,
      }))
      const { error: ingredientInsertError } = await supabase
        .from('mes_ingredients')
        .insert(ingredientPayload)
      if (ingredientInsertError) throw ingredientInsertError
    }

    const { data: processRows, error: processLoadError } = await supabase
      .from('mes_recipe_processes')
      .select('id, name, version, is_active, notes, mes_recipe_steps(id, step_no, step, target_params, qa_checks, notes)')
      .eq('recipe_id', copyTarget.value.id)
    if (processLoadError) throw processLoadError

    if (processRows && processRows.length > 0) {
      type StepRecord = {
        id: string
        process_id: string
        step_no: number
        step: string
        target_params: unknown
        qa_checks: unknown
        notes: string | null
      }

      type ProcessRecord = {
        id: string
        name: string
        version: number
        is_active: boolean
        notes: string | null
        mes_recipe_steps?: StepRecord[]
      }

      const processesToClone = processRows as ProcessRecord[]

      for (const process of processesToClone) {
        const { data: createdProcess, error: processInsertError } = await supabase
          .from('mes_recipe_processes')
          .insert({
            recipe_id: inserted.id,
            name: process.name,
            version: process.version,
            is_active: process.is_active,
            notes: process.notes,
          })
          .select('id')
          .single()
        if (processInsertError || !createdProcess) throw processInsertError ?? new Error('Process copy failed')

        const steps = process.mes_recipe_steps ?? []
        if (steps.length > 0) {
          const stepPayload = steps.map((step) => ({
            process_id: createdProcess.id,
            step_no: step.step_no,
            step: step.step,
            target_params: normalizeObject(step.target_params),
            qa_checks: normalizeArray(step.qa_checks),
            notes: step.notes,
          }))
          const { error: stepsInsertError } = await supabase
            .from('mes_recipe_steps')
            .insert(stepPayload)
          if (stepsInsertError) throw stepsInsertError
        }
      }
    }

    recipes.value.unshift(inserted)
    toast.success(t('recipe.list.copySuccess', { name: inserted.name, version: inserted.version }))
    copying.value = false
    closeCopyModal(true)
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error)
    toast.error(t('recipe.list.copyError', { message }))
  } finally {
    copying.value = false
    copyingId.value = null
  }
}

onMounted(async () => {
  await Promise.all([fetchCategories(), fetchRecipes()])
})
</script>
