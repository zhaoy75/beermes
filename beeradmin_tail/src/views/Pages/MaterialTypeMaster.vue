<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-7xl mx-auto">
      <header class="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('materialType.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('materialType.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loadingTypes"
            @click="refreshAll"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="grid grid-cols-1 lg:grid-cols-[280px_1fr] gap-4">
        <aside class="border border-gray-200 rounded-xl shadow-sm p-3">
          <div class="flex items-center justify-between mb-3">
            <h2 class="text-sm font-semibold text-gray-700">{{ t('materialType.treeTitle') }}</h2>
            <button
              class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-50"
              @click="toggleExpandAll"
            >
              {{ expandedAll ? t('common.collapse') : t('common.expand') }}
            </button>
          </div>

          <div v-if="loadingTypes" class="text-sm text-gray-500 py-4">{{ t('common.loading') }}</div>
          <div v-else-if="visibleTree.length === 0" class="text-sm text-gray-500 py-4">
            {{ t('common.noData') }}
          </div>
          <ul v-else class="space-y-1">
            <li v-for="entry in visibleTree" :key="entry.node.row.type_id">
              <div
                class="flex items-center gap-2 rounded px-2 py-1 text-sm cursor-pointer hover:bg-gray-50"
                :class="entry.node.row.type_id === selectedTypeId ? 'bg-blue-50 text-blue-700' : 'text-gray-700'"
                :style="{ paddingLeft: `${entry.depth * 14}px` }"
                @click="selectType(entry.node.row.type_id)"
              >
                <button
                  v-if="entry.node.children.length > 0"
                  class="text-xs text-gray-500"
                  type="button"
                  @click.stop="toggleExpanded(entry.node.row.type_id)"
                >
                  {{ isExpanded(entry.node.row.type_id) ? '▾' : '▸' }}
                </button>
                <span v-else class="w-3 inline-block" />
                <span class="truncate">
                  {{ entry.node.row.name || entry.node.row.code }}
                </span>
              </div>
            </li>
          </ul>
        </aside>

        <div class="space-y-4">
          <div class="border border-gray-200 rounded-xl shadow-sm p-4">
            <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
              <div>
                <p class="text-xs text-gray-500">{{ t('materialType.selectedLabel') }}</p>
                <h2 class="text-lg font-semibold">
                  {{ selectedType?.name || t('materialType.noSelection') }}
                </h2>
                <p v-if="selectedType" class="text-xs text-gray-500 font-mono">
                  {{ selectedType.code }}
                </p>
              </div>
              <div class="flex flex-wrap gap-2">
                <button
                  class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
                  :disabled="!selectedType"
                  @click="openCreateChild"
                >
                  {{ t('materialType.addChild') }}
                </button>
                <button
                  class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
                  :disabled="!selectedType"
                  @click="openEdit"
                >
                  {{ t('common.edit') }}
                </button>
                <button
                  class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
                  :disabled="!selectedType"
                  @click="openAttrManager"
                >
                  {{ t('materialType.manageAttributes') }}
                </button>
                <button
                  class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700 disabled:opacity-50"
                  :disabled="!selectedType"
                  @click="confirmDelete"
                >
                  {{ t('common.delete') }}
                </button>
              </div>
            </div>
          </div>

          <div class="border border-gray-200 rounded-xl shadow-sm overflow-hidden">
            <div class="px-4 py-3 border-b flex items-center justify-between">
              <div>
                <h3 class="text-sm font-semibold text-gray-700">{{ t('materialType.attributeTitle') }}</h3>
                <p v-if="assignedAttrSets.length" class="text-xs text-gray-500 mt-1">
                  {{ t('materialType.attributeSetCount', { count: assignedAttrSets.length }) }}
                </p>
              </div>
              <button
                class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
                :disabled="!selectedType || loadingAttrs"
                @click="loadAttributes"
              >
                {{ t('common.refresh') }}
              </button>
            </div>

            <div class="px-4 py-3 border-b bg-gray-50" v-if="assignedAttrSets.length">
              <div class="flex flex-wrap gap-2">
                <span
                  v-for="set in assignedAttrSets"
                  :key="set.attr_set_id"
                  class="text-xs px-2 py-1 rounded border border-gray-200 bg-white text-gray-700"
                >
                  {{ set.name }} ({{ set.code }})
                </span>
              </div>
            </div>

            <div v-if="loadingAttrs" class="p-4 text-sm text-gray-500">{{ t('common.loading') }}</div>
            <div v-else-if="!selectedType" class="p-4 text-sm text-gray-500">
              {{ t('materialType.selectPrompt') }}
            </div>
            <div v-else-if="attributeRows.length === 0" class="p-4 text-sm text-gray-500">
              {{ t('materialType.attrEmpty') }}
            </div>
            <table v-else class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50">
                <tr>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialType.table.attrSet') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialType.table.code') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialType.table.name') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialType.table.dataType') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialType.table.required') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialType.table.uiSection') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialType.table.uiWidget') }}</th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('materialType.table.active') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="row in attributeRows" :key="row.key" class="hover:bg-gray-50">
                  <td class="px-3 py-2 text-xs text-gray-600">{{ row.attrSetLabel }}</td>
                  <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.code }}</td>
                  <td class="px-3 py-2 text-gray-800">{{ row.name }}</td>
                  <td class="px-3 py-2 text-gray-600">{{ row.dataType }}</td>
                  <td class="px-3 py-2 text-gray-600">{{ row.required ? t('common.yes') : t('common.no') }}</td>
                  <td class="px-3 py-2 text-gray-600">{{ row.uiSection || '—' }}</td>
                  <td class="px-3 py-2 text-gray-600">{{ row.uiWidget || '—' }}</td>
                  <td class="px-3 py-2 text-gray-600">{{ row.active ? t('common.yes') : t('common.no') }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <div v-if="showTypeModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ editingType ? t('materialType.editTitle') : t('materialType.newTitle') }}</h3>
          </div>
          <div class="p-4 space-y-4">
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('materialType.form.code') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="typeForm.code" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              <p v-if="typeErrors.code" class="mt-1 text-xs text-red-600">{{ typeErrors.code }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('materialType.form.name') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="typeForm.name" class="w-full h-[40px] border rounded px-3" />
              <p v-if="typeErrors.name" class="mt-1 text-xs text-red-600">{{ typeErrors.name }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('materialType.form.parent') }}</label>
              <select v-model="typeForm.parent_type_id" class="w-full h-[40px] border rounded px-3 bg-white">
                <option :value="null">{{ t('materialType.form.noParent') }}</option>
                <option v-for="option in parentOptions" :key="option.type_id" :value="option.type_id">
                  {{ option.name || option.code }}
                </option>
              </select>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('materialType.form.sortOrder') }}</label>
                <input v-model.number="typeForm.sort_order" type="number" min="0" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div class="flex items-center gap-2 pt-6">
                <input id="typeActive" v-model="typeForm.is_active" type="checkbox" class="h-4 w-4" />
                <label for="typeActive" class="text-sm text-gray-700">{{ t('materialType.form.active') }}</label>
              </div>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeTypeModal">{{ t('common.cancel') }}</button>
            <button
              class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
              :disabled="savingType"
              @click="saveType"
            >
              {{ savingType ? t('common.saving') : t('common.save') }}
            </button>
          </div>
        </div>
      </div>

      <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('materialType.deleteTitle') }}</h3>
          </div>
          <div class="p-4 text-sm">
            {{ t('materialType.deleteConfirm', { name: selectedType?.name || selectedType?.code || '' }) }}
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="showDelete = false">{{ t('common.cancel') }}</button>
            <button
              class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700 disabled:opacity-50"
              :disabled="savingType"
              @click="deleteType"
            >
              {{ t('common.delete') }}
            </button>
          </div>
        </div>
      </div>

      <div v-if="showAttrManager" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('materialType.manageAttributes') }}</h3>
            <p class="text-xs text-gray-500 mt-1">{{ t('materialType.manageAttributesSubtitle') }}</p>
          </div>
          <div class="p-4 space-y-3 max-h-[60vh] overflow-y-auto">
            <div v-if="attrSets.length === 0" class="text-sm text-gray-500">
              {{ t('materialType.attrSetEmpty') }}
            </div>
            <label
              v-for="set in attrSets"
              :key="set.attr_set_id"
              class="flex items-start gap-3 p-3 border rounded-lg hover:bg-gray-50"
            >
              <input v-model="attrSetSelection" type="checkbox" :value="set.attr_set_id" class="mt-1 h-4 w-4" />
              <div>
                <div class="text-sm font-medium text-gray-800">{{ set.name }}</div>
                <div class="text-xs text-gray-500">{{ set.code }} · {{ set.domain }}</div>
              </div>
            </label>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeAttrManager">{{ t('common.cancel') }}</button>
            <button
              class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
              :disabled="savingAttrSets"
              @click="saveAttrSets"
            >
              {{ savingAttrSets ? t('common.saving') : t('common.save') }}
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
import { supabase } from '@/lib/supabase'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

type TypeRow = {
  type_id: number
  code: string
  name: string
  parent_type_id: number | null
  sort_order: number | null
  is_active: boolean
  created_at: string | null
  scope: string
  owner_id: string | null
}

type TreeNode = {
  row: TypeRow
  children: TreeNode[]
}

type AttrSetRow = {
  attr_set_id: number
  code: string
  name: string
  domain: string
  scope: string
  owner_id: string | null
  is_active: boolean
  sort_order: number | null
}

type AttrDefRow = {
  attr_id: number
  code: string
  name: string
  data_type: string
  description: string | null
  is_active: boolean
}

type AttrRuleRow = {
  attr_set_id: number
  attr_id: number
  required: boolean
  sort_order: number | null
  is_active: boolean
  ui_section: string | null
  ui_widget: string | null
  help_text: string | null
  attr_def: AttrDefRow | null
}

const TYPE_DOMAIN = 'material_type'
const ENTITY_TYPE = 'material_type'
const ATTR_DOMAINS = ['material', 'material_type']
const ROOT_TYPE_CODE = 'material'
const ROOT_TYPE_NAME = 'Material'
const INDUSTRY_CODE = 'CRAFT_BEER'

const { t } = useI18n()
const pageTitle = computed(() => t('materialType.title'))

const typeRows = ref<TypeRow[]>([])
const loadingTypes = ref(false)
const selectedTypeId = ref<number | null>(null)
const expanded = ref<Set<number>>(new Set())
const expandedAll = ref(true)

const showTypeModal = ref(false)
const editingType = ref(false)
const savingType = ref(false)
const showDelete = ref(false)

const typeForm = reactive({
  code: '',
  name: '',
  parent_type_id: null as number | null,
  sort_order: 0,
  is_active: true,
})

const typeErrors = reactive({
  code: '',
  name: '',
})

const attrSets = ref<AttrSetRow[]>([])
const assignedAttrSetIds = ref<number[]>([])
const attrRules = ref<AttrRuleRow[]>([])
const loadingAttrs = ref(false)
const showAttrManager = ref(false)
const attrSetSelection = ref<number[]>([])
const savingAttrSets = ref(false)

const tenantId = ref<string | null>(null)
const isAdmin = ref(false)
const ensuringRoot = ref(false)
const industryId = ref<string | null>(null)

const selectedType = computed(() => {
  if (selectedTypeId.value == null) return null
  return typeRows.value.find((row) => row.type_id === selectedTypeId.value) ?? null
})

const parentOptions = computed(() => {
  const currentId = editingType.value ? selectedTypeId.value : null
  return typeRows.value.filter((row) => row.type_id !== currentId)
})

const treeNodes = computed<TreeNode[]>(() => buildTree(typeRows.value))

const visibleTree = computed(() => {
  const output: Array<{ node: TreeNode; depth: number }> = []
  const walk = (nodes: TreeNode[], depth: number) => {
    for (const node of nodes) {
      output.push({ node, depth })
      if (expanded.value.has(node.row.type_id)) {
        walk(node.children, depth + 1)
      }
    }
  }
  walk(treeNodes.value, 0)
  return output
})

const attrSetLookup = computed(() => {
  const map = new Map<number, AttrSetRow>()
  for (const set of attrSets.value) {
    map.set(set.attr_set_id, set)
  }
  return map
})

const assignedAttrSets = computed(() => {
  return assignedAttrSetIds.value
    .map((id) => attrSetLookup.value.get(id))
    .filter((set): set is AttrSetRow => Boolean(set))
})

const attributeRows = computed(() => {
  const rows = attrRules.value.map((rule) => {
    const attr = rule.attr_def
    const set = attrSetLookup.value.get(rule.attr_set_id)
    return {
      key: `${rule.attr_set_id}-${rule.attr_id}`,
      attrSetLabel: set ? `${set.name} (${set.code})` : String(rule.attr_set_id),
      code: attr?.code ?? '',
      name: attr?.name ?? '',
      dataType: attr?.data_type ?? '',
      required: rule.required,
      uiSection: rule.ui_section,
      uiWidget: rule.ui_widget,
      active: rule.is_active && (attr?.is_active ?? true),
    }
  })
  return rows.sort((a, b) => a.attrSetLabel.localeCompare(b.attrSetLabel) || a.code.localeCompare(b.code))
})

function buildTree(rows: TypeRow[]) {
  const map = new Map<number, TreeNode>()
  for (const row of rows) {
    map.set(row.type_id, { row, children: [] })
  }
  const roots: TreeNode[] = []
  for (const node of map.values()) {
    const parentId = node.row.parent_type_id
    if (parentId && map.has(parentId)) {
      map.get(parentId)?.children.push(node)
    } else {
      roots.push(node)
    }
  }
  const sortNodes = (nodes: TreeNode[]) => {
    nodes.sort((a, b) => {
      const aSort = a.row.sort_order ?? 0
      const bSort = b.row.sort_order ?? 0
      if (aSort !== bSort) return aSort - bSort
      return a.row.code.localeCompare(b.row.code)
    })
    for (const node of nodes) sortNodes(node.children)
  }
  sortNodes(roots)
  return roots
}

function isExpanded(typeId: number) {
  return expanded.value.has(typeId)
}

function toggleExpanded(typeId: number) {
  const next = new Set(expanded.value)
  if (next.has(typeId)) next.delete(typeId)
  else next.add(typeId)
  expanded.value = next
  expandedAll.value = next.size === typeRows.value.length && typeRows.value.length > 0
}

function toggleExpandAll() {
  if (!expandedAll.value) {
    expanded.value = new Set(typeRows.value.map((row) => row.type_id))
    expandedAll.value = true
  } else {
    expanded.value = new Set()
    expandedAll.value = false
  }
}

function selectType(typeId: number) {
  selectedTypeId.value = typeId
  loadAttributes()
}

function resetTypeForm() {
  typeForm.code = ''
  typeForm.name = ''
  typeForm.parent_type_id = null
  typeForm.sort_order = 0
  typeForm.is_active = true
  typeErrors.code = ''
  typeErrors.name = ''
}

function openCreateChild() {
  if (!selectedType.value) return
  resetTypeForm()
  editingType.value = false
  typeForm.parent_type_id = selectedType.value.type_id
  showTypeModal.value = true
}

function openEdit() {
  if (!selectedType.value) return
  resetTypeForm()
  editingType.value = true
  typeForm.code = selectedType.value.code
  typeForm.name = selectedType.value.name
  typeForm.parent_type_id = selectedType.value.parent_type_id
  typeForm.sort_order = selectedType.value.sort_order ?? 0
  typeForm.is_active = selectedType.value.is_active
  showTypeModal.value = true
}

function closeTypeModal() {
  showTypeModal.value = false
}

function validateTypeForm() {
  typeErrors.code = ''
  typeErrors.name = ''
  if (!typeForm.code.trim()) typeErrors.code = t('materialType.errors.codeRequired')
  if (!typeForm.name.trim()) typeErrors.name = t('materialType.errors.nameRequired')
  return !typeErrors.code && !typeErrors.name
}

function confirmDelete() {
  if (!selectedType.value) return
  showDelete.value = true
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved in session')
  tenantId.value = id
  const role = String(data.user?.app_metadata?.role ?? data.user?.user_metadata?.role ?? '').toLowerCase()
  const adminFlag = Boolean(data.user?.app_metadata?.is_admin || data.user?.user_metadata?.is_admin)
  isAdmin.value = adminFlag || role === 'admin'
  return id
}

function canEdit(row: TypeRow) {
  if (row.scope === 'system') return isAdmin.value
  return true
}

async function ensureIndustry() {
  if (industryId.value) return industryId.value
  const { data, error } = await supabase
    .from('industry')
    .select('industry_id, code')
    .eq('code', INDUSTRY_CODE)
    .eq('is_active', true)
    .limit(1)
  if (error) throw error
  const matched = data?.[0]?.industry_id ?? null
  if (matched) {
    industryId.value = matched
    return matched
  }
  const { data: fallback, error: fallbackError } = await supabase
    .from('industry')
    .select('industry_id')
    .eq('is_active', true)
    .order('sort_order', { ascending: true })
    .limit(1)
  if (fallbackError) throw fallbackError
  industryId.value = fallback?.[0]?.industry_id ?? null
  return industryId.value
}

async function fetchTypes() {
  try {
    loadingTypes.value = true
    const industry = await ensureIndustry()
    const { data, error } = await supabase
      .from('type_def')
      .select('type_id, code, name, parent_type_id, sort_order, is_active, created_at, scope, owner_id')
      .eq('domain', TYPE_DOMAIN)
      .eq('industry_id', industry)
      .order('sort_order', { ascending: true })
      .order('code', { ascending: true })
    if (error) throw error
    const rows = (data ?? []) as TypeRow[]
    if (rows.length === 0 && !ensuringRoot.value) {
      ensuringRoot.value = true
      try {
        await createRootType()
        const { data: refreshed, error: refreshError } = await supabase
          .from('type_def')
          .select('type_id, code, name, parent_type_id, sort_order, is_active, created_at, scope, owner_id')
          .eq('domain', TYPE_DOMAIN)
          .order('sort_order', { ascending: true })
          .order('code', { ascending: true })
        if (refreshError) throw refreshError
        typeRows.value = (refreshed ?? []) as TypeRow[]
      } finally {
        ensuringRoot.value = false
      }
    } else {
      typeRows.value = rows
    }
    expanded.value = new Set(typeRows.value.map((row) => row.type_id))
    expandedAll.value = typeRows.value.length > 0
    if (selectedTypeId.value && !typeRows.value.find((row) => row.type_id === selectedTypeId.value)) {
      selectedTypeId.value = null
    }
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
    typeRows.value = []
  } finally {
    loadingTypes.value = false
  }
}

async function createRootType() {
  const tenant = await ensureTenant()
  const industry = await ensureIndustry()
  const payload = {
    tenant_id: tenant,
    domain: TYPE_DOMAIN,
    industry_id: industry,
    code: ROOT_TYPE_CODE,
    name: ROOT_TYPE_NAME,
    parent_type_id: null,
    sort_order: 0,
    is_active: true,
    scope: 'tenant',
    owner_id: tenant,
  }
  const { error } = await supabase.from('type_def').insert(payload)
  if (error) throw error
}

async function fetchAttrSets() {
  try {
    const industry = await ensureIndustry()
    const { data, error } = await supabase
      .from('attr_set')
      .select('attr_set_id, code, name, domain, scope, owner_id, is_active, sort_order')
      .in('domain', ATTR_DOMAINS)
      .eq('industry_id', industry)
      .eq('is_active', true)
      .order('sort_order', { ascending: true })
      .order('code', { ascending: true })
    if (error) throw error
    attrSets.value = (data ?? []) as AttrSetRow[]
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
    attrSets.value = []
  }
}

async function loadAttributes() {
  if (!selectedType.value) {
    assignedAttrSetIds.value = []
    attrRules.value = []
    return
  }
  try {
    loadingAttrs.value = true
    const { data: assignmentData, error: assignmentError } = await supabase
      .from('entity_attr_set')
      .select('attr_set_id')
      .eq('entity_type', ENTITY_TYPE)
      .eq('entity_id', selectedType.value.type_id)
      .eq('is_active', true)
    if (assignmentError) throw assignmentError
    const setIds = (assignmentData ?? []).map((row) => row.attr_set_id as number)
    assignedAttrSetIds.value = setIds
    if (setIds.length === 0) {
      attrRules.value = []
      return
    }
    const { data: ruleData, error: ruleError } = await supabase
      .from('attr_set_rule')
      .select(
        'attr_set_id, attr_id, required, sort_order, is_active, ui_section, ui_widget, help_text, attr_def:attr_def!fk_attr_set_rule_attr(attr_id, code, name, data_type, description, is_active)'
      )
      .in('attr_set_id', setIds)
      .order('sort_order', { ascending: true })
    if (ruleError) throw ruleError
    attrRules.value = (ruleData ?? []) as AttrRuleRow[]
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
    assignedAttrSetIds.value = []
    attrRules.value = []
  } finally {
    loadingAttrs.value = false
  }
}

async function saveType() {
  try {
    if (!validateTypeForm()) return
    if (!selectedType.value && editingType.value) return
    savingType.value = true
    const tenant = await ensureTenant()
    if (editingType.value && selectedType.value) {
      if (!canEdit(selectedType.value)) {
        throw new Error(t('materialType.errors.adminOnlySystem'))
      }
      const { error } = await supabase
        .from('type_def')
        .update({
          code: typeForm.code.trim(),
          name: typeForm.name.trim(),
          parent_type_id: typeForm.parent_type_id,
          sort_order: typeForm.sort_order ?? 0,
          is_active: typeForm.is_active,
        })
        .eq('type_id', selectedType.value.type_id)
      if (error) throw error
      toast.success(t('common.saved'))
    } else {
      const industry = await ensureIndustry()
      const payload = {
        tenant_id: tenant,
        domain: TYPE_DOMAIN,
        industry_id: industry,
        code: typeForm.code.trim(),
        name: typeForm.name.trim(),
        parent_type_id: typeForm.parent_type_id,
        sort_order: typeForm.sort_order ?? 0,
        is_active: typeForm.is_active,
        scope: 'tenant',
        owner_id: tenant,
      }
      const { error } = await supabase.from('type_def').insert(payload)
      if (error) throw error
      toast.success(t('common.saved'))
    }
    showTypeModal.value = false
    await fetchTypes()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    savingType.value = false
  }
}

async function deleteType() {
  if (!selectedType.value) return
  try {
    savingType.value = true
    if (!canEdit(selectedType.value)) {
      throw new Error(t('materialType.errors.adminOnlySystem'))
    }
    const { error } = await supabase.from('type_def').delete().eq('type_id', selectedType.value.type_id)
    if (error) throw error
    toast.success(t('common.deleted'))
    showDelete.value = false
    selectedTypeId.value = null
    await fetchTypes()
    await loadAttributes()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    savingType.value = false
  }
}

async function openAttrManager() {
  if (!selectedType.value) return
  try {
    await fetchAttrSets()
  } catch (err) {
    console.error(err)
  }
  attrSetSelection.value = [...assignedAttrSetIds.value]
  showAttrManager.value = true
}

function closeAttrManager() {
  showAttrManager.value = false
}

async function saveAttrSets() {
  if (!selectedType.value) return
  try {
    savingAttrSets.value = true
    const tenant = await ensureTenant()
    const current = assignedAttrSetIds.value
    const desired = attrSetSelection.value
    const toAdd = desired.filter((id) => !current.includes(id))
    const toRemove = current.filter((id) => !desired.includes(id))

    if (toAdd.length > 0) {
      const insertRows = toAdd.map((id) => ({
        tenant_id: tenant,
        entity_type: ENTITY_TYPE,
        entity_id: selectedType.value?.type_id ?? null,
        attr_set_id: id,
        is_active: true,
      }))
      const { error } = await supabase.from('entity_attr_set').insert(insertRows)
      if (error) throw error
    }

    if (toRemove.length > 0) {
      const { error } = await supabase
        .from('entity_attr_set')
        .delete()
        .eq('entity_type', ENTITY_TYPE)
        .eq('entity_id', selectedType.value.type_id)
        .in('attr_set_id', toRemove)
      if (error) throw error
    }

    toast.success(t('common.saved'))
    showAttrManager.value = false
    await loadAttributes()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    savingAttrSets.value = false
  }
}

async function refreshAll() {
  await fetchTypes()
  await fetchAttrSets()
  await loadAttributes()
}

onMounted(async () => {
  await refreshAll()
})
</script>
