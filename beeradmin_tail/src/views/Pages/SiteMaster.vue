<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="max-w-6xl mx-auto p-4 space-y-4">
      <header class="flex flex-col gap-2">
        <h1 class="text-xl font-semibold text-gray-800">{{ t('site.title') }}</h1>
      </header>

      <section class="grid grid-cols-1 lg:grid-cols-[320px_1fr] gap-4">
        <aside class="bg-white border border-gray-200 rounded-xl shadow-sm p-4 space-y-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="siteKeywordSearch">{{ t('common.search') }}</label>
            <input
              id="siteKeywordSearch"
              v-model.trim="filters.keyword"
              type="search"
              class="w-full h-[36px] border rounded px-3"
              :placeholder="t('site.filters.namePlaceholder')"
            />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="siteTypeSearch">{{ t('site.filters.siteType') }}</label>
            <select id="siteTypeSearch" v-model="filters.siteType" class="w-full h-[36px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in siteTypeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="siteOwnerTypeSearch">{{ t('site.filters.ownerType') }}</label>
            <select id="siteOwnerTypeSearch" v-model="filters.ownerType" class="w-full h-[36px] border rounded px-3 bg-white">
              <option value="">{{ t('common.all') }}</option>
              <option v-for="option in ownerTypeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
          <div class="flex items-center gap-2">
            <button class="px-3 py-2 text-sm rounded bg-blue-600 text-white hover:bg-blue-700" type="button" @click="startCreateLocation">
              {{ t('site.actions.addLocation') }}
            </button>
            <button class="px-3 py-2 text-sm rounded bg-emerald-600 text-white hover:bg-emerald-700" type="button" @click="startCreateSite">
              {{ t('site.actions.addSite') }}
            </button>
            <button
              class="px-3 py-2 text-sm rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-50"
              type="button"
              :disabled="!selectedId"
              @click="deleteSelected"
            >
              {{ t('common.delete') }}
            </button>
          </div>

          <div class="border-t border-gray-200 pt-3">
            <p v-if="!filteredTree.length" class="text-sm text-gray-500">{{ t('site.tree.empty') }}</p>
            <ul class="space-y-2">
              <li>
                <button
                  type="button"
                  class="w-full text-left px-2 py-1 rounded text-sm"
                  :class="selectedId === null ? 'bg-blue-50 text-blue-700' : 'text-gray-700 hover:bg-gray-50'"
                  @click="selectRoot"
                >
                  {{ t('site.tree.root') }}
                </button>
                <ul class="ml-3 mt-1 space-y-1">
                  <li v-for="node in filteredTree" :key="node.id">
                    <SiteTreeNode
                      :node="node"
                      :selected-id="selectedId"
                      @select="selectNode"
                    />
                  </li>
                </ul>
              </li>
            </ul>
          </div>
        </aside>

        <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4">
          <header class="flex items-center justify-between mb-4">
            <div>
              <h2 class="text-lg font-semibold text-gray-800">
                {{ form.id ? t('site.editTitle') : t('site.newTitle') }}
              </h2>
              <p class="text-xs text-gray-500">{{ selectedPathLabel }}</p>
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
              <label class="block text-sm text-gray-600 mb-1">{{ t('site.table.name') }}</label>
              <input v-model.trim="form.name" class="w-full h-[40px] border rounded px-3" />
              <p v-if="errors.name" class="text-xs text-red-600 mt-1">{{ errors.name }}</p>
            </div>
            <div v-if="!isLocationNodeKind">
              <label class="block text-sm text-gray-600 mb-1">{{ t('site.table.siteType') }}</label>
              <select v-model="form.site_type_id" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in siteTypeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
              </select>
              <p v-if="errors.site_type_id" class="text-xs text-red-600 mt-1">{{ errors.site_type_id }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('site.form.ownerType') }}</label>
              <select v-model="form.owner_type" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in ownerTypeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
              </select>
              <p v-if="errors.owner_type" class="text-xs text-red-600 mt-1">{{ errors.owner_type }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('site.form.ownerName') }}</label>
              <input v-model.trim="form.owner_name" class="w-full h-[40px] border rounded px-3" :disabled="form.owner_type !== 'OUTSIDE'" />
              <p v-if="errors.owner_name" class="text-xs text-red-600 mt-1">{{ errors.owner_name }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('site.form.address') }}</label>
              <div class="flex items-center gap-2">
                <button
                  class="px-3 py-2 text-sm rounded border hover:bg-gray-100 disabled:opacity-50"
                  type="button"
                  :disabled="!addressRule"
                  @click="openAddressDialog"
                >
                  {{ t('common.edit') }}
                </button>
                <span v-if="!addressRule" class="text-xs text-gray-500">{{ t('common.noData') }}</span>
              </div>
              <p class="mt-2 text-sm text-gray-600 whitespace-pre-line">
                {{ formatAddressDisplay(form.address) }}
              </p>
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{ t('site.form.notes') }}</label>
              <textarea v-model.trim="form.notes" rows="3" class="w-full border rounded px-3 py-2"></textarea>
            </div>
          </div>
        </section>
      </section>
    </div>

    <div v-if="addressDialog.open && addressRule" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg border border-gray-200">
        <header class="px-4 py-3 border-b flex items-center justify-between">
          <h3 class="font-semibold">{{ t('site.form.address') }}</h3>
          <button class="text-sm px-2 py-1 rounded border hover:bg-gray-100" type="button" @click="closeAddressDialog">
            {{ t('common.close') }}
          </button>
        </header>
        <section class="p-4 space-y-4">
          <div v-for="field in addressFields" :key="field.key">
            <label class="block text-sm text-gray-600 mb-1">
              {{ addressFieldLabel(field) }}<span v-if="field.required" class="text-red-600">*</span>
            </label>
            <input
              v-model.trim="addressDraft[field.key]"
              type="text"
              class="w-full h-[40px] border rounded px-3"
            />
          </div>
        </section>
        <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
          <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="closeAddressDialog">
            {{ t('common.cancel') }}
          </button>
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" type="button" @click="saveAddressDialog">
            {{ t('common.save') }}
          </button>
        </footer>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, reactive, ref, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'
import SiteTreeNode from '@/views/Pages/components/SiteTreeNode.vue'

interface SiteRow {
  id: string
  tenant_id?: string
  name: string
  site_type_id: string
  parent_site_id: string | null
  node_kind: string
  owner_type: string
  owner_name: string | null
  sort_order: number
  address: any
  contact: any
  notes: string | null
  active: boolean
  created_at: string | null
}

interface RegistryDefRow {
  def_id: string
  def_key: string
  spec: Record<string, any>
}

interface TreeNode {
  id: string
  name: string
  site_type_id: string
  parent_site_id: string | null
  owner_type: string
  sort_order: number
  row: SiteRow
  children: TreeNode[]
}

const { t, locale } = useI18n()
const pageTitle = computed(() => t('site.title'))

const TABLE = 'mst_sites'
const OWNER_TYPE_OWN = 'OWN'
const OWNER_TYPE_OUTSIDE = 'OUTSIDE'
const NODE_KIND_SITE = 'SITE'
const NODE_KIND_LOCATION = 'LOCATION'
const ZERO_UUID = '00000000-0000-0000-0000-000000000000'

const rows = ref<SiteRow[]>([])
const siteTypes = ref<RegistryDefRow[]>([])
const loading = ref(false)
const saving = ref(false)
const tenantId = ref<string | null>(null)

const selectedId = ref<string | null>(null)
const tempId = ref<string | null>(null)
const addressRule = ref<RegistryDefRow | null>(null)
const addressDialog = reactive({ open: false })
const addressDraft = reactive<Record<string, string>>({})

const filters = reactive({
  keyword: '',
  siteType: '',
  ownerType: '',
})

const form = reactive({
  id: '',
  name: '',
  site_type_id: '',
  parent_site_id: '',
  node_kind: NODE_KIND_SITE,
  owner_type: OWNER_TYPE_OWN,
  owner_name: '',
  sort_order: 0,
  address: null as Record<string, any> | null,
  notes: '',
  contact: null as any,
  active: true,
})

const errors = reactive<Record<string, string>>({})
const TEMP_PREFIX = 'temp-'

const siteTypeOptions = computed(() =>
  siteTypes.value.map((item) => {
    const label = resolveRegistryLabel(item) || item.def_key
    return { value: item.def_id, label }
  }),
)

const ownerTypeOptions = computed(() => [
  { value: OWNER_TYPE_OWN, label: t('site.ownerType.own') },
  { value: OWNER_TYPE_OUTSIDE, label: t('site.ownerType.outside') },
])

const treeNodes = computed<TreeNode[]>(() => buildTree(rows.value))

const isLocationNodeKind = computed(() => isLocationKind(form.node_kind))

const filteredTree = computed<TreeNode[]>(() => {
  const keywordFilter = filters.keyword.trim().toLowerCase()
  const typeFilter = filters.siteType
  const ownerTypeFilter = filters.ownerType
  if (!keywordFilter && !typeFilter && !ownerTypeFilter) return treeNodes.value
  return filterTree(treeNodes.value, (node) => {
    const matchesKeyword = !keywordFilter || node.name.toLowerCase().includes(keywordFilter)
    const matchesType = !typeFilter || node.site_type_id === typeFilter
    const matchesOwnerType = !ownerTypeFilter || node.owner_type === ownerTypeFilter
    return matchesKeyword && matchesType && matchesOwnerType
  })
})

const selectedSite = computed(() => rows.value.find((row) => row.id === selectedId.value) || null)

const selectedPathLabel = computed(() => {
  if (!selectedSite.value) return t('site.tree.root')
  return selectedSite.value.name
})

const addressFields = computed(() => {
  const fields = addressRule.value?.spec?.fields
  if (!Array.isArray(fields)) return []
  return fields
    .map((field: any) => ({
      key: String(field?.key ?? '').trim(),
      label: field?.label ?? '',
      label_i18n: field?.label_i18n ?? null,
      required: Boolean(field?.required),
    }))
    .filter((field: any) => field.key)
})

function resolveRegistryLabel(source: RegistryDefRow) {
  const spec = source.spec || {}
  const lang = String(locale.value ?? '').toLowerCase().startsWith('ja') ? 'ja' : 'en'
  if (spec.name_i18n && typeof spec.name_i18n[lang] === 'string') return spec.name_i18n[lang]
  if (typeof spec.name === 'string') return spec.name
  return null
}

function buildTree(list: SiteRow[]): TreeNode[] {
  const map = new Map<string, TreeNode>()
  list.forEach((row) => {
    map.set(row.id, {
      id: row.id,
      name: row.name,
      site_type_id: row.site_type_id,
      parent_site_id: row.parent_site_id,
      owner_type: row.owner_type,
      sort_order: row.sort_order ?? 0,
      row,
      children: [],
    })
  })
  const roots: TreeNode[] = []
  map.forEach((node) => {
    if (node.parent_site_id && map.has(node.parent_site_id)) {
      map.get(node.parent_site_id)!.children.push(node)
    } else {
      roots.push(node)
    }
  })
  const sortNodes = (nodes: TreeNode[]) => {
    nodes.sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0) || a.name.localeCompare(b.name))
    nodes.forEach((n) => sortNodes(n.children))
  }
  sortNodes(roots)
  return roots
}

function filterTree(nodes: TreeNode[], predicate: (node: TreeNode) => boolean): TreeNode[] {
  const result: TreeNode[] = []
  nodes.forEach((node) => {
    const filteredChildren = filterTree(node.children, predicate)
    if (predicate(node) || filteredChildren.length) {
      result.push({ ...node, children: filteredChildren })
    }
  })
  return result
}

function selectNode(node: TreeNode) {
  selectedId.value = node.id
  loadForm(node.row)
}

function selectRoot() {
  selectedId.value = null
  resetForm()
}

function startCreateSite() {
  startCreateByKind(NODE_KIND_SITE)
}

function startCreateLocation() {
  startCreateByKind(NODE_KIND_LOCATION)
}

function startCreateByKind(nodeKind: string) {
  const parentId = resolveCreateParentId()
  removeTempRow()
  resetForm()
  const tempRow = createTempRow(parentId, nodeKind)
  rows.value = [...rows.value, tempRow]
  selectedId.value = tempRow.id
  tempId.value = tempRow.id
  loadForm(tempRow)
}

function resetForm() {
  form.id = ''
  form.name = ''
  form.site_type_id = ''
  form.parent_site_id = ''
  form.node_kind = NODE_KIND_SITE
  form.owner_type = OWNER_TYPE_OWN
  form.owner_name = ''
  form.sort_order = 0
  form.address = null
  form.notes = ''
  form.contact = null
  form.active = true
  Object.keys(errors).forEach((key) => delete errors[key])
}

function loadForm(row: SiteRow) {
  resetForm()
  const isTemp = isTempId(row.id)
  form.id = isTemp ? '' : row.id
  form.name = row.name
  form.site_type_id = row.site_type_id
  form.parent_site_id = row.parent_site_id ?? ''
  form.node_kind = normalizeNodeKind(row.node_kind)
  form.owner_type = row.owner_type ?? OWNER_TYPE_OWN
  form.owner_name = row.owner_name ?? ''
  form.sort_order = row.sort_order ?? 0
  form.address = row.address ?? null
  form.notes = row.notes ?? ''
  form.contact = row.contact ?? null
  form.active = row.active
}

function isTempId(id: string) {
  return id.startsWith(TEMP_PREFIX)
}

function resolveCreateParentId() {
  const targetId = selectedId.value
  if (!targetId || isTempId(targetId)) return null
  return resolveNearestLocationNodeId(targetId)
}

function resolveNearestLocationNodeId(startId: string | null) {
  if (!startId) return null
  const rowMap = new Map(rows.value.map((row) => [row.id, row]))
  const visited = new Set<string>()
  let currentId: string | null = startId

  while (currentId) {
    if (visited.has(currentId)) return null
    visited.add(currentId)
    const current = rowMap.get(currentId)
    if (!current) return null
    if (isLocationKind(current.node_kind)) return current.id
    currentId = current.parent_site_id
  }

  return null
}

function createTempRow(parentId: string | null, nodeKind: string) {
  const normalizedNodeKind = normalizeNodeKind(nodeKind)
  const id = `${TEMP_PREFIX}${Date.now()}`
  return {
    id,
    tenant_id: tenantId.value ?? undefined,
    name: '',
    site_type_id: defaultSiteTypeIdForNodeKind(normalizedNodeKind),
    parent_site_id: parentId,
    node_kind: normalizedNodeKind,
    owner_type: OWNER_TYPE_OWN,
    owner_name: null,
    sort_order: 0,
    address: null,
    contact: null,
    notes: null,
    active: true,
    created_at: null,
  } as SiteRow
}

function normalizeNodeKind(value: string | null | undefined) {
  const raw = String(value ?? '').trim().toUpperCase()
  if (raw === NODE_KIND_LOCATION) return NODE_KIND_LOCATION
  return NODE_KIND_SITE
}

function isLocationKind(value: string | null | undefined) {
  return normalizeNodeKind(value) === NODE_KIND_LOCATION
}

function defaultSiteTypeIdForNodeKind(nodeKind: string) {
  return isLocationKind(nodeKind) ? ZERO_UUID : ''
}

function removeTempRow() {
  if (!tempId.value) return
  rows.value = rows.value.filter((row) => row.id !== tempId.value)
  if (selectedId.value === tempId.value) selectedId.value = null
  tempId.value = null
}

function formatAddressDisplay(value: Record<string, any> | null) {
  if (!value) return '—'
  const format = addressRule.value?.spec?.format
  const lang = String(locale.value ?? '').toLowerCase().startsWith('ja') ? 'ja' : 'en'
  const template = format && typeof format[lang] === 'string' ? format[lang] : ''
  if (template) {
    return template.replace(/\{([^}]+)\}/g, (_, key) => {
      const raw = value[key]
      return raw != null ? String(raw) : ''
    }).trim() || '—'
  }
  try {
    return JSON.stringify(value, null, 2)
  } catch {
    return '—'
  }
}

function addressFieldLabel(field: { label: string; label_i18n: Record<string, string> | null }) {
  const lang = String(locale.value ?? '').toLowerCase().startsWith('ja') ? 'ja' : 'en'
  if (field.label_i18n && field.label_i18n[lang]) return field.label_i18n[lang]
  return field.label || field.label_i18n?.en || ''
}

function validate() {
  Object.keys(errors).forEach((key) => delete errors[key])
  if (!form.name) errors.name = t('site.form.nameRequired')
  if (!isLocationKind(form.node_kind) && !form.site_type_id) errors.site_type_id = t('site.form.siteTypeRequired')
  if (!form.owner_type) errors.owner_type = t('site.form.ownerTypeRequired')
  if (form.owner_type === OWNER_TYPE_OUTSIDE && !form.owner_name.trim()) errors.owner_name = t('site.form.ownerNameRequired')
  return Object.keys(errors).length === 0
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved in session')
  tenantId.value = id
  return id
}

async function fetchAddressRule() {
  const { data, error } = await supabase
    .from('registry_def')
    .select('def_id, def_key, spec')
    .eq('kind', 'address_rule')
    .eq('def_key', 'jp_default')
    .eq('is_active', true)
    .maybeSingle()
  if (error) throw error
  addressRule.value = data ?? null
}

function openAddressDialog() {
  if (!addressRule.value) return
  addressDialog.open = true
  Object.keys(addressDraft).forEach((key) => delete addressDraft[key])
  const current = form.address || {}
  addressFields.value.forEach((field) => {
    addressDraft[field.key] = current[field.key] ? String(current[field.key]) : ''
  })
}

function closeAddressDialog() {
  addressDialog.open = false
}

function saveAddressDialog() {
  const next: Record<string, any> = {}
  addressFields.value.forEach((field) => {
    const value = addressDraft[field.key]
    if (value != null && String(value).trim()) {
      next[field.key] = String(value).trim()
    }
  })
  form.address = Object.keys(next).length ? next : null
  addressDialog.open = false
}

async function fetchSiteTypes() {
  const { data, error } = await supabase
    .from('registry_def')
    .select('def_id, def_key, spec')
    .eq('kind', 'site_type')
    .eq('is_active', true)
    .order('def_key', { ascending: true })
  if (error) throw error
  siteTypes.value = (data ?? []) as RegistryDefRow[]
}

async function fetchSites() {
  try {
    loading.value = true
    const tenant = await ensureTenant()
    const { data, error } = await supabase
      .from(TABLE)
      .select('id, tenant_id, name, site_type_id, parent_site_id, node_kind, owner_type, owner_name, sort_order, address, contact, notes, active, created_at')
      .eq('tenant_id', tenant)
      .order('sort_order', { ascending: true })
      .order('name', { ascending: true })
    if (error) throw error
    rows.value = (data ?? []) as SiteRow[]
    removeTempRow()
  } catch (err) {
    console.error(err)
    rows.value = []
  } finally {
    loading.value = false
  }
}

async function saveRecord() {
  if (!validate()) return
  try {
    saving.value = true
    const tenant = await ensureTenant()
    const isUpdating = Boolean(form.id)
    const payload = {
      tenant_id: tenant,
      name: form.name.trim(),
      site_type_id: isLocationKind(form.node_kind) ? ZERO_UUID : form.site_type_id,
      parent_site_id: form.parent_site_id || null,
      node_kind: normalizeNodeKind(form.node_kind),
      owner_type: form.owner_type,
      owner_name: form.owner_type === OWNER_TYPE_OUTSIDE ? (form.owner_name.trim() || null) : null,
      sort_order: Number(form.sort_order) || 0,
      address: form.address,
      contact: form.contact,
      notes: form.notes.trim() || null,
      active: form.active,
    }

    if (isUpdating) {
      const { error } = await supabase.from(TABLE).update(payload).eq('id', form.id)
      if (error) throw error
    } else {
      const { data, error } = await supabase.from(TABLE).insert(payload).select('id').single()
      if (error) throw error
      if (data?.id) {
        selectedId.value = data.id
      }
    }

    await fetchSites()
    if (isUpdating) {
      const updated = rows.value.find((row) => row.id === form.id)
      if (updated) loadForm(updated)
    } else {
      const created = rows.value.find((row) => row.id === selectedId.value)
      if (created) {
        selectedId.value = created.id
        loadForm(created)
      } else {
        selectedId.value = null
        resetForm()
      }
      tempId.value = null
    }
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

function collectDescendantIds(id: string) {
  const childrenMap = new Map<string, string[]>()
  rows.value.forEach((row) => {
    if (!row.parent_site_id) return
    if (!childrenMap.has(row.parent_site_id)) childrenMap.set(row.parent_site_id, [])
    childrenMap.get(row.parent_site_id)!.push(row.id)
  })
  const result: string[] = []
  const stack = [id]
  while (stack.length) {
    const current = stack.pop()!
    result.push(current)
    const kids = childrenMap.get(current) || []
    kids.forEach((kid) => stack.push(kid))
  }
  return result
}

async function deleteSelected() {
  if (!selectedId.value) return
  if (isTempId(selectedId.value)) {
    removeTempRow()
    resetForm()
    return
  }
  if (!window.confirm(t('site.deleteConfirm', { name: selectedSite.value?.name ?? '' }))) return
  try {
    const ids = collectDescendantIds(selectedId.value)
    const { error } = await supabase.from(TABLE).delete().in('id', ids)
    if (error) throw error
    selectedId.value = null
    resetForm()
    await fetchSites()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
}

onMounted(async () => {
  await ensureTenant()
  await Promise.all([fetchSiteTypes(), fetchSites(), fetchAddressRule()])
})
</script>
