<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <section class="mb-6 rounded-lg border border-gray-200 bg-white p-4 shadow" aria-labelledby="recipeListSearch">
      <div class="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h2 id="recipeListSearch" class="text-lg font-semibold text-gray-900">{{ t('recipe.list.searchTitle') }}</h2>
          <p class="text-sm text-gray-500">{{ t('recipe.list.rowCount', { count: visibleRows.length }) }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" :disabled="loading" @click="openCreate">
            {{ t('common.new') }}
          </button>
          <button class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-100" :disabled="loading" @click="refresh">
            {{ t('common.refresh') }}
          </button>
          <button class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-100" :disabled="loading" @click="resetFilters">
            {{ t('common.reset') }}
          </button>
        </div>
      </div>

      <form class="grid grid-cols-1 gap-4 md:grid-cols-4" @submit.prevent>
        <div>
          <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.keyword') }}</label>
          <input v-model.trim="filters.keyword" class="h-[40px] w-full rounded border px-3" :placeholder="t('recipe.list.keywordPlaceholder')" />
        </div>
        <div>
          <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.category') }}</label>
          <select v-model="filters.category" class="h-[40px] w-full rounded border bg-white px-3">
            <option value="">{{ t('common.all') }}</option>
            <option v-for="option in categoryOptions" :key="option" :value="option">{{ option }}</option>
          </select>
        </div>
        <div>
          <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.industry') }}</label>
          <select v-model="filters.industry" class="h-[40px] w-full rounded border bg-white px-3">
            <option value="">{{ t('common.all') }}</option>
            <option v-for="option in industryOptions" :key="option" :value="option">{{ option }}</option>
          </select>
        </div>
        <div>
          <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.versionStatus') }}</label>
          <select v-model="filters.versionStatus" class="h-[40px] w-full rounded border bg-white px-3">
            <option value="">{{ t('common.all') }}</option>
            <option v-for="status in VERSION_STATUSES" :key="status" :value="status">{{ formatVersionStatus(status) }}</option>
          </select>
        </div>
        <div class="md:col-span-4 flex items-center gap-2">
          <input id="showAllVersions" v-model="showAllVersions" type="checkbox" class="h-4 w-4" />
          <label for="showAllVersions" class="text-sm text-gray-700">{{ t('recipe.list.showAllVersions') }}</label>
        </div>
      </form>
    </section>

    <section class="overflow-hidden rounded-lg border border-gray-200 bg-white shadow">
      <div class="hidden overflow-x-auto md:block">
        <table class="min-w-full divide-y divide-gray-200 text-sm">
          <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
            <tr>
              <th class="px-3 py-2">{{ t('recipe.list.recipeCode') }}</th>
              <th class="px-3 py-2">{{ t('recipe.list.recipeName') }}</th>
              <th class="px-3 py-2">{{ t('recipe.list.version') }}</th>
              <th class="px-3 py-2">{{ t('recipe.list.versionStatus') }}</th>
              <th class="px-3 py-2">{{ t('recipe.list.recipeStatus') }}</th>
              <th class="px-3 py-2">{{ t('recipe.list.category') }}</th>
              <th class="px-3 py-2">{{ t('recipe.list.industry') }}</th>
              <th class="px-3 py-2">{{ t('recipe.list.schema') }}</th>
              <th class="px-3 py-2">{{ t('recipe.list.updated') }}</th>
              <th class="px-3 py-2">{{ t('recipe.list.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in visibleRows" :key="`${row.recipe_id}:${row.version_id}`" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.recipe_code }}</td>
              <td class="px-3 py-2">
                <button class="text-left text-blue-600 hover:underline" @click="goEdit(row)">
                  {{ row.recipe_name }}
                </button>
              </td>
              <td class="px-3 py-2">v{{ row.version_no }}</td>
              <td class="px-3 py-2">
                <span class="rounded-full px-2 py-1 text-xs" :class="versionStatusChip(row.version_status)">
                  {{ formatVersionStatus(row.version_status) }}
                </span>
              </td>
              <td class="px-3 py-2">
                <span class="rounded-full px-2 py-1 text-xs" :class="recipeStatusChip(row.recipe_status)">
                  {{ formatRecipeStatus(row.recipe_status) }}
              </span>
              </td>
              <td class="px-3 py-2">{{ row.recipe_category || t('common.none') }}</td>
              <td class="px-3 py-2">{{ row.industry_type || t('common.none') }}</td>
              <td class="px-3 py-2 font-mono text-xs text-gray-600">{{ row.schema_code || DEFAULT_SCHEMA_KEY }}</td>
              <td class="px-3 py-2 text-xs text-gray-500">{{ formatDate(row.updated_at) }}</td>
              <td class="px-3 py-2 space-x-2">
                <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" :disabled="copyingId === row.version_id" @click="openCopy(row)">
                  {{ copyingId === row.version_id ? t('common.copying') : t('common.copy') }}
                </button>
                <button class="rounded bg-red-600 px-2 py-1 text-xs text-white hover:bg-red-700" @click="confirmDelete(row)">
                  {{ t('common.delete') }}
                </button>
              </td>
            </tr>
            <tr v-if="!loading && visibleRows.length === 0">
              <td colspan="10" class="px-3 py-8 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <div class="divide-y divide-gray-200 md:hidden">
        <article v-for="row in visibleRows" :key="`card-${row.recipe_id}-${row.version_id}`" class="p-4">
          <div class="flex items-start justify-between gap-3">
            <div>
              <p class="font-mono text-xs uppercase tracking-wide text-gray-400">{{ row.recipe_code }}</p>
              <button class="text-left text-base font-semibold text-blue-600" @click="goEdit(row)">
                {{ row.recipe_name }}
              </button>
            </div>
            <span class="rounded-full px-2 py-1 text-xs" :class="versionStatusChip(row.version_status)">
              {{ formatLabel(row.version_status) }}
            </span>
          </div>
          <dl class="mt-3 space-y-1 text-sm text-gray-600">
            <div class="flex justify-between gap-3">
              <dt>{{ t('recipe.list.version') }}</dt>
              <dd>v{{ row.version_no }}</dd>
            </div>
            <div class="flex justify-between gap-3">
              <dt>{{ t('recipe.list.category') }}</dt>
              <dd>{{ row.recipe_category || t('common.none') }}</dd>
            </div>
            <div class="flex justify-between gap-3">
              <dt>{{ t('recipe.list.industry') }}</dt>
              <dd>{{ row.industry_type || t('common.none') }}</dd>
            </div>
            <div class="flex justify-between gap-3">
              <dt>{{ t('recipe.list.schema') }}</dt>
              <dd class="font-mono text-xs">{{ row.schema_code || DEFAULT_SCHEMA_KEY }}</dd>
            </div>
          </dl>
          <div class="mt-3 flex gap-2">
            <button class="rounded border px-3 py-2 text-sm hover:bg-gray-100" :disabled="copyingId === row.version_id" @click="openCopy(row)">
              {{ copyingId === row.version_id ? t('common.copying') : t('common.copy') }}
            </button>
            <button class="rounded bg-red-600 px-3 py-2 text-sm text-white hover:bg-red-700" @click="confirmDelete(row)">
              {{ t('common.delete') }}
            </button>
          </div>
        </article>
      </div>
    </section>

    <div v-if="showCreateModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-2xl rounded-xl border border-gray-200 bg-white shadow-lg">
        <header class="border-b px-4 py-3">
          <h3 class="font-semibold text-gray-900">{{ t('recipe.list.newRecipe') }}</h3>
        </header>
        <section class="space-y-4 p-4">
          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.recipeCode') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="createForm.recipe_code" class="h-[40px] w-full rounded border px-3" />
              <p v-if="formErrors.recipe_code" class="mt-1 text-xs text-red-600">{{ formErrors.recipe_code }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.recipeName') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="createForm.recipe_name" class="h-[40px] w-full rounded border px-3" />
              <p v-if="formErrors.recipe_name" class="mt-1 text-xs text-red-600">{{ formErrors.recipe_name }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.recipeCategory') }}</label>
              <input v-model.trim="createForm.recipe_category" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.industryType') }}</label>
              <input v-model.trim="createForm.industry_type" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.schemaKey') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="createForm.schema_key" class="h-[40px] w-full rounded border px-3 font-mono text-sm" />
              <p v-if="formErrors.schema_key" class="mt-1 text-xs text-red-600">{{ formErrors.schema_key }}</p>
            </div>
          </div>
        </section>
        <footer class="flex items-center justify-end gap-2 border-t px-4 py-3">
          <button class="rounded border px-3 py-2 hover:bg-gray-100" @click="closeCreate">{{ t('common.cancel') }}</button>
          <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700 disabled:opacity-60" :disabled="saving" @click="createRecipe">
            {{ saving ? t('common.saving') : t('common.save') }}
          </button>
        </footer>
      </div>
    </div>

    <div v-if="showCopyModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-2xl rounded-xl border border-gray-200 bg-white shadow-lg">
        <header class="border-b px-4 py-3">
          <h3 class="font-semibold text-gray-900">{{ t('recipe.list.copyRecipe') }}</h3>
        </header>
        <section class="space-y-4 p-4">
          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.recipeCode') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="copyForm.recipe_code" class="h-[40px] w-full rounded border px-3" />
              <p v-if="copyErrors.recipe_code" class="mt-1 text-xs text-red-600">{{ copyErrors.recipe_code }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.recipeName') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="copyForm.recipe_name" class="h-[40px] w-full rounded border px-3" />
              <p v-if="copyErrors.recipe_name" class="mt-1 text-xs text-red-600">{{ copyErrors.recipe_name }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.recipeCategory') }}</label>
              <input v-model.trim="copyForm.recipe_category" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.industryType') }}</label>
              <input v-model.trim="copyForm.industry_type" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.list.schemaKey') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="copyForm.schema_key" class="h-[40px] w-full rounded border px-3 font-mono text-sm" />
              <p v-if="copyErrors.schema_key" class="mt-1 text-xs text-red-600">{{ copyErrors.schema_key }}</p>
            </div>
          </div>
        </section>
        <footer class="flex items-center justify-end gap-2 border-t px-4 py-3">
          <button class="rounded border px-3 py-2 hover:bg-gray-100" @click="closeCopy">{{ t('common.cancel') }}</button>
          <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700 disabled:opacity-60" :disabled="copying" @click="copyRecipe">
            {{ copying ? t('common.copying') : t('common.copy') }}
          </button>
        </footer>
      </div>
    </div>

    <div v-if="showDeleteModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-md rounded-xl border border-gray-200 bg-white shadow-lg">
        <header class="border-b px-4 py-3">
          <h3 class="font-semibold text-gray-900">{{ t('recipe.list.deleteRecipe') }}</h3>
        </header>
        <section class="p-4 text-sm text-gray-700">
          {{ t('recipe.list.deleteConfirmFull', { name: deleteTarget?.recipe_name ?? '' }) }}
        </section>
        <footer class="flex items-center justify-end gap-2 border-t px-4 py-3">
          <button class="rounded border px-3 py-2 hover:bg-gray-100" @click="showDeleteModal = false">{{ t('common.cancel') }}</button>
          <button class="rounded bg-red-600 px-3 py-2 text-white hover:bg-red-700" @click="deleteRecipe">{{ t('common.delete') }}</button>
        </footer>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { formatRpcErrorMessage } from '@/lib/rpcErrors'
import { supabase } from '@/lib/supabase'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

const DEFAULT_SCHEMA_KEY = 'recipe_body_v1'
const VERSION_STATUSES = ['draft', 'in_review', 'approved', 'obsolete', 'archived'] as const

type JsonObject = Record<string, unknown>
type RecipeStatus = 'active' | 'inactive'
type VersionStatus = (typeof VERSION_STATUSES)[number]

interface RecipeHeaderRow {
  id: string
  recipe_code: string
  recipe_name: string
  recipe_category: string | null
  industry_type: string | null
  status: RecipeStatus
  current_version_id: string | null
  created_at: string | null
  updated_at: string | null
}

interface RecipeVersionRow {
  id: string
  recipe_id: string
  version_no: number
  version_label: string | null
  schema_code: string | null
  status: VersionStatus
  created_at: string | null
  updated_at: string | null
}

interface RecipeListRow {
  recipe_id: string
  version_id: string
  recipe_code: string
  recipe_name: string
  recipe_category: string | null
  industry_type: string | null
  recipe_status: RecipeStatus
  version_no: number
  version_label: string | null
  version_status: VersionStatus
  schema_code: string | null
  created_at: string | null
  updated_at: string | null
}

interface RecipeSchemaPayload {
  def_id: string | null
  def_key: string
  scope: string | null
  schema: JsonObject
}

const { t, locale } = useI18n()
const router = useRouter()
const pageTitle = computed(() => t('recipe.list.title'))

const loading = ref(false)
const saving = ref(false)
const copying = ref(false)
const copyingId = ref<string | null>(null)
const showAllVersions = ref(false)
const showCreateModal = ref(false)
const showCopyModal = ref(false)
const showDeleteModal = ref(false)

const recipes = ref<RecipeHeaderRow[]>([])
const versions = ref<RecipeVersionRow[]>([])
const copySource = ref<RecipeListRow | null>(null)
const deleteTarget = ref<RecipeListRow | null>(null)

const filters = reactive({
  keyword: '',
  category: '',
  industry: '',
  versionStatus: '',
})

const createForm = reactive({
  recipe_code: '',
  recipe_name: '',
  recipe_category: '',
  industry_type: '',
  schema_key: DEFAULT_SCHEMA_KEY,
})

const copyForm = reactive({
  recipe_code: '',
  recipe_name: '',
  recipe_category: '',
  industry_type: '',
  schema_key: DEFAULT_SCHEMA_KEY,
})

const formErrors = reactive<Record<string, string>>({})
const copyErrors = reactive<Record<string, string>>({})

const mesClient = () => supabase.schema('mes')

const versionMap = computed(() => {
  const map = new Map<string, RecipeVersionRow[]>()
  for (const version of versions.value) {
    const list = map.get(version.recipe_id)
    if (list) {
      list.push(version)
    } else {
      map.set(version.recipe_id, [version])
    }
  }
  for (const list of map.values()) {
    list.sort((a, b) => {
      if (a.version_no !== b.version_no) return b.version_no - a.version_no
      const aTime = a.updated_at ? Date.parse(a.updated_at) : 0
      const bTime = b.updated_at ? Date.parse(b.updated_at) : 0
      return bTime - aTime
    })
  }
  return map
})

const categoryOptions = computed(() =>
  Array.from(new Set(recipes.value.map((row) => row.recipe_category).filter((value): value is string => Boolean(value)))).sort(),
)

const industryOptions = computed(() =>
  Array.from(new Set(recipes.value.map((row) => row.industry_type).filter((value): value is string => Boolean(value)))).sort(),
)

const visibleRows = computed(() => {
  const rows: RecipeListRow[] = []

  for (const recipe of recipes.value) {
    const versionRows = versionMap.value.get(recipe.id) ?? []
    const targetVersions = showAllVersions.value
      ? versionRows
      : [pickCurrentVersion(recipe, versionRows)].filter((value): value is RecipeVersionRow => Boolean(value))

    for (const version of targetVersions) {
      rows.push({
        recipe_id: recipe.id,
        version_id: version.id,
        recipe_code: recipe.recipe_code,
        recipe_name: recipe.recipe_name,
        recipe_category: recipe.recipe_category,
        industry_type: recipe.industry_type,
        recipe_status: recipe.status,
        version_no: version.version_no,
        version_label: version.version_label,
        version_status: version.status,
        schema_code: version.schema_code,
        created_at: version.created_at ?? recipe.created_at,
        updated_at: version.updated_at ?? recipe.updated_at,
      })
    }
  }

  const keyword = filters.keyword.trim().toLowerCase()
  const filtered = rows.filter((row) => {
    const matchesKeyword =
      !keyword
      || row.recipe_code.toLowerCase().includes(keyword)
      || row.recipe_name.toLowerCase().includes(keyword)
    const matchesCategory = !filters.category || row.recipe_category === filters.category
    const matchesIndustry = !filters.industry || row.industry_type === filters.industry
    const matchesVersionStatus = !filters.versionStatus || row.version_status === filters.versionStatus
    return matchesKeyword && matchesCategory && matchesIndustry && matchesVersionStatus
  })

  filtered.sort((a, b) => {
    const aTime = a.updated_at ? Date.parse(a.updated_at) : 0
    const bTime = b.updated_at ? Date.parse(b.updated_at) : 0
    if (aTime !== bTime) return bTime - aTime
    if (a.recipe_code !== b.recipe_code) return a.recipe_code.localeCompare(b.recipe_code)
    return b.version_no - a.version_no
  })

  return filtered
})

function pickCurrentVersion(recipe: RecipeHeaderRow, versionRows: RecipeVersionRow[]) {
  if (recipe.current_version_id) {
    const matched = versionRows.find((row) => row.id === recipe.current_version_id)
    if (matched) return matched
  }
  return versionRows[0] ?? null
}

function formatLabel(value: string) {
  return value
    .split('_')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ')
}

function toTranslationKey(value: string) {
  return value.replace(/_([a-z])/g, (_, char: string) => char.toUpperCase())
}

function translateEnum(baseKey: string, value: string) {
  const key = `${baseKey}.${toTranslationKey(value)}`
  const translated = t(key)
  return translated === key ? formatLabel(value) : translated
}

function formatRecipeStatus(value: RecipeStatus) {
  return translateEnum('recipe.statuses', value)
}

function formatVersionStatus(value: VersionStatus) {
  return translateEnum('recipe.versionStatuses', value)
}

function formatDate(value: string | null) {
  if (!value) return t('common.none')
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? value : date.toLocaleString(locale.value)
}

function recipeStatusChip(status: RecipeStatus) {
  return status === 'active' ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-600'
}

function versionStatusChip(status: VersionStatus) {
  if (status === 'approved') return 'bg-green-100 text-green-800'
  if (status === 'draft') return 'bg-yellow-100 text-yellow-800'
  if (status === 'in_review') return 'bg-blue-100 text-blue-800'
  return 'bg-gray-200 text-gray-600'
}

function normalizeSchemaKey(value: string) {
  return value.trim() || DEFAULT_SCHEMA_KEY
}

function buildRecipeEditLocation(row: Pick<RecipeListRow, 'recipe_id' | 'version_id' | 'schema_code'>) {
  return {
    path: `/recipeEdit/${row.recipe_id}/${row.version_id}`,
    query: { schemaKey: row.schema_code || DEFAULT_SCHEMA_KEY },
  }
}

function createInitialRecipeBody(schema: JsonObject | null, industryType: string) {
  const schemaVersion =
    typeof schema?.properties === 'object'
    && schema.properties
    && typeof (schema.properties as JsonObject).schema_version === 'object'
    && (schema.properties as JsonObject).schema_version
    && typeof (((schema.properties as JsonObject).schema_version as JsonObject).const) === 'string'
      ? String(((schema.properties as JsonObject).schema_version as JsonObject).const)
      : 'recipe_body_v1'

  return {
    schema_version: schemaVersion,
    recipe_info: {
      recipe_type: 'process_manufacturing',
      industry_type: industryType || '',
      notes: '',
    },
    base: {
      quantity: 1,
      uom_code: 'PCS',
    },
    materials: {
      required: [],
      optional: [],
    },
    flow: {
      steps: [],
    },
  }
}

async function ensureSchema(schemaKey: string) {
  const normalized = normalizeSchemaKey(schemaKey)
  const { data, error } = await supabase.rpc('recipe_schema_get', {
    p_def_key: normalized,
  })
  if (error) throw error
  if (!data || typeof data !== 'object' || Array.isArray(data)) {
    throw new Error(t('recipe.list.invalidSchemaResponse'))
  }
  const payload = data as RecipeSchemaPayload
  return payload
}

async function fetchRecipes() {
  loading.value = true
  const [{ data: recipeData, error: recipeError }, { data: versionData, error: versionError }] = await Promise.all([
    mesClient()
      .from('mst_recipe')
      .select('id, recipe_code, recipe_name, recipe_category, industry_type, status, current_version_id, created_at, updated_at')
      .order('updated_at', { ascending: false }),
    mesClient()
      .from('mst_recipe_version')
      .select('id, recipe_id, version_no, version_label, schema_code, status, created_at, updated_at')
      .order('version_no', { ascending: false }),
  ])
  loading.value = false

  if (recipeError) {
    toast.error(t('recipe.list.loadRecipesFailed', { message: recipeError.message }))
    return
  }
  if (versionError) {
    toast.error(t('recipe.list.loadVersionsFailed', { message: versionError.message }))
    return
  }

  recipes.value = (recipeData ?? []) as RecipeHeaderRow[]
  versions.value = (versionData ?? []) as RecipeVersionRow[]
}

async function refresh() {
  await fetchRecipes()
}

function resetFilters() {
  filters.keyword = ''
  filters.category = ''
  filters.industry = ''
  filters.versionStatus = ''
}

function resetCreateForm() {
  createForm.recipe_code = ''
  createForm.recipe_name = ''
  createForm.recipe_category = ''
  createForm.industry_type = ''
  createForm.schema_key = DEFAULT_SCHEMA_KEY
  Object.keys(formErrors).forEach((key) => delete formErrors[key])
}

function resetCopyForm() {
  copyForm.recipe_code = ''
  copyForm.recipe_name = ''
  copyForm.recipe_category = ''
  copyForm.industry_type = ''
  copyForm.schema_key = DEFAULT_SCHEMA_KEY
  Object.keys(copyErrors).forEach((key) => delete copyErrors[key])
}

function openCreate() {
  resetCreateForm()
  showCreateModal.value = true
}

function closeCreate() {
  if (saving.value) return
  showCreateModal.value = false
}

function openCopy(row: RecipeListRow) {
  resetCopyForm()
  copySource.value = row
  copyForm.recipe_code = `${row.recipe_code}-copy`
  copyForm.recipe_name = `${row.recipe_name} Copy`
  copyForm.recipe_category = row.recipe_category ?? ''
  copyForm.industry_type = row.industry_type ?? ''
  copyForm.schema_key = row.schema_code || DEFAULT_SCHEMA_KEY
  copyingId.value = row.version_id
  showCopyModal.value = true
}

function closeCopy() {
  if (copying.value) return
  showCopyModal.value = false
  copySource.value = null
  copyingId.value = null
}

function confirmDelete(row: RecipeListRow) {
  deleteTarget.value = row
  showDeleteModal.value = true
}

function validateCreateForm() {
  Object.keys(formErrors).forEach((key) => delete formErrors[key])
  if (!createForm.recipe_code.trim()) formErrors.recipe_code = t('recipe.list.recipeCodeRequired')
  if (!createForm.recipe_name.trim()) formErrors.recipe_name = t('recipe.list.recipeNameRequired')
  if (!createForm.schema_key.trim()) formErrors.schema_key = t('recipe.list.schemaKeyRequired')
  return Object.keys(formErrors).length === 0
}

function validateCopyForm() {
  Object.keys(copyErrors).forEach((key) => delete copyErrors[key])
  if (!copyForm.recipe_code.trim()) copyErrors.recipe_code = t('recipe.list.recipeCodeRequired')
  if (!copyForm.recipe_name.trim()) copyErrors.recipe_name = t('recipe.list.recipeNameRequired')
  if (!copyForm.schema_key.trim()) copyErrors.schema_key = t('recipe.list.schemaKeyRequired')
  return Object.keys(copyErrors).length === 0
}

async function createRecipe() {
  if (!validateCreateForm()) return

  saving.value = true
  try {
    const schema = await ensureSchema(createForm.schema_key)
    const recipeBody = createInitialRecipeBody(schema.schema, createForm.industry_type.trim())

    const { data: recipeRow, error: recipeError } = await mesClient()
      .from('mst_recipe')
      .insert({
        recipe_code: createForm.recipe_code.trim(),
        recipe_name: createForm.recipe_name.trim(),
        recipe_category: createForm.recipe_category.trim() || null,
        industry_type: createForm.industry_type.trim() || null,
        status: 'active',
      })
      .select('id, recipe_code, recipe_name, recipe_category, industry_type, status, current_version_id, created_at, updated_at')
      .single()
    if (recipeError || !recipeRow) throw recipeError ?? new Error(t('recipe.list.createRecipeFailed'))

    const { data: versionRow, error: versionError } = await mesClient()
      .from('mst_recipe_version')
      .insert({
        recipe_id: recipeRow.id,
        version_no: 1,
        version_label: 'v1',
        schema_code: schema.def_key,
        recipe_body_json: recipeBody,
        resolved_reference_json: {},
        status: 'draft',
      })
      .select('id, recipe_id, version_no, version_label, schema_code, status, created_at, updated_at')
      .single()
    if (versionError || !versionRow) throw versionError ?? new Error(t('recipe.list.createRecipeVersionFailed'))

    const { error: updateError } = await mesClient()
      .from('mst_recipe')
      .update({ current_version_id: versionRow.id })
      .eq('id', recipeRow.id)
    if (updateError) throw updateError

    closeCreate()
    await refresh()
    await router.push(buildRecipeEditLocation({
      recipe_id: recipeRow.id,
      version_id: versionRow.id,
      schema_code: versionRow.schema_code,
    }))
  } catch (error: unknown) {
    const message = formatRpcErrorMessage(error)
    toast.error(t('recipe.list.createError', { message }))
  } finally {
    saving.value = false
  }
}

async function copyRecipe() {
  if (!copySource.value || !validateCopyForm()) return

  copying.value = true
  try {
    const schema = await ensureSchema(copyForm.schema_key)
    const { data: sourceVersion, error: sourceError } = await mesClient()
      .from('mst_recipe_version')
      .select('id, recipe_body_json, resolved_reference_json, template_code, schema_code')
      .eq('id', copySource.value.version_id)
      .single()
    if (sourceError || !sourceVersion) throw sourceError ?? new Error(t('recipe.list.sourceRecipeVersionNotFound'))

    const { data: recipeRow, error: recipeError } = await mesClient()
      .from('mst_recipe')
      .insert({
        recipe_code: copyForm.recipe_code.trim(),
        recipe_name: copyForm.recipe_name.trim(),
        recipe_category: copyForm.recipe_category.trim() || null,
        industry_type: copyForm.industry_type.trim() || null,
        status: 'active',
      })
      .select('id, recipe_code, recipe_name, recipe_category, industry_type, status, current_version_id, created_at, updated_at')
      .single()
    if (recipeError || !recipeRow) throw recipeError ?? new Error(t('recipe.list.createCopiedRecipeFailed'))

    const { data: versionRow, error: versionError } = await mesClient()
      .from('mst_recipe_version')
      .insert({
        recipe_id: recipeRow.id,
        version_no: 1,
        version_label: 'v1',
        schema_code: schema.def_key,
        template_code: sourceVersion.template_code ?? null,
        recipe_body_json: sourceVersion.recipe_body_json,
        resolved_reference_json: sourceVersion.resolved_reference_json ?? {},
        status: 'draft',
      })
      .select('id, recipe_id, version_no, version_label, schema_code, status, created_at, updated_at')
      .single()
    if (versionError || !versionRow) throw versionError ?? new Error(t('recipe.list.createCopiedRecipeVersionFailed'))

    const { error: updateError } = await mesClient()
      .from('mst_recipe')
      .update({ current_version_id: versionRow.id })
      .eq('id', recipeRow.id)
    if (updateError) throw updateError

    closeCopy()
    await refresh()
    await router.push(buildRecipeEditLocation({
      recipe_id: recipeRow.id,
      version_id: versionRow.id,
      schema_code: versionRow.schema_code,
    }))
  } catch (error: unknown) {
    const message = formatRpcErrorMessage(error)
    toast.error(t('recipe.list.copyErrorToast', { message }))
  } finally {
    copying.value = false
    copyingId.value = null
  }
}

async function deleteRecipe() {
  if (!deleteTarget.value) return
  const { error } = await mesClient()
    .from('mst_recipe')
    .delete()
    .eq('id', deleteTarget.value.recipe_id)
  if (error) {
    toast.error(t('recipe.list.deleteError', { message: error.message }))
    return
  }
  showDeleteModal.value = false
  deleteTarget.value = null
  await refresh()
}

function goEdit(row: RecipeListRow) {
  void router.push(buildRecipeEditLocation(row))
}

onMounted(async () => {
  await fetchRecipes()
})
</script>
