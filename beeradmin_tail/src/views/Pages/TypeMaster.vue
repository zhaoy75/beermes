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
            :disabled="loadingTypes || sortingTypes"
            @click="refreshAll"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="mb-4 border border-gray-200 rounded-xl shadow-sm p-4">
        <div class="flex flex-col gap-3 lg:flex-row lg:items-end lg:justify-between">
          <div class="grid grid-cols-1 md:grid-cols-[220px_1fr] gap-3 items-end">
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('materialType.domainLabel') }}</label>
              <select
                v-model="selectedDomain"
                class="w-full h-[40px] border rounded px-3 bg-white"
                :disabled="loadingTypes || sortingTypes"
                @change="handleDomainChange"
              >
                <option v-for="domain in availableDomains" :key="domain.value" :value="domain.value">
                  {{ domain.label }}
                </option>
              </select>
            </div>
            <div class="text-sm text-gray-500">
              {{ t('materialType.domainHint') }}
            </div>
          </div>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="savingDomain"
            @click="openAddDomain"
          >
            {{ t('materialType.addDomain') }}
          </button>
        </div>
      </section>

      <section class="grid grid-cols-1 lg:grid-cols-[320px_1fr] gap-4">
        <aside class="border border-gray-200 rounded-xl shadow-sm p-3">
          <div class="flex items-center justify-between mb-3">
            <div>
              <h2 class="text-sm font-semibold text-gray-700">{{ t('materialType.treeTitle') }}</h2>
              <p class="text-xs text-gray-500 mt-1">{{ selectedDomainLabel }}</p>
            </div>
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
                :class="{
                  'bg-blue-50 text-blue-700': entry.node.row.type_id === selectedTypeId,
                  'text-gray-700': entry.node.row.type_id !== selectedTypeId,
                  'ring-2 ring-blue-300': dragOverTypeId === entry.node.row.type_id && canDropOn(entry.node.row.type_id),
                  'opacity-60': draggedTypeId === entry.node.row.type_id,
                }"
                :style="{ paddingLeft: `${entry.depth * 14}px` }"
                :draggable="canDragRow(entry.node.row)"
                @click="selectType(entry.node.row.type_id)"
                @dragstart="handleDragStart(entry.node.row.type_id)"
                @dragover.prevent="handleDragOver(entry.node.row.type_id)"
                @drop.prevent="handleDrop(entry.node.row.type_id)"
                @dragend="clearDragState"
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
                  {{ displayTypeName(entry.node.row) }}
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
                  {{ selectedType ? displayTypeName(selectedType) : t('materialType.noSelection') }}
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

            <div v-if="assignedAttrSets.length" class="px-4 py-3 border-b bg-gray-50">
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
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                    <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setAttributeSort('attrSetLabel')">
                      <span>{{ t('materialType.table.attrSet') }}</span>
                      <span v-if="attributeSortIcon('attrSetLabel')" class="text-xs">{{ attributeSortIcon('attrSetLabel') }}</span>
                    </button>
                  </th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                    <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setAttributeSort('code')">
                      <span>{{ t('materialType.table.code') }}</span>
                      <span v-if="attributeSortIcon('code')" class="text-xs">{{ attributeSortIcon('code') }}</span>
                    </button>
                  </th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                    <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setAttributeSort('name')">
                      <span>{{ t('materialType.table.name') }}</span>
                      <span v-if="attributeSortIcon('name')" class="text-xs">{{ attributeSortIcon('name') }}</span>
                    </button>
                  </th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                    <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setAttributeSort('dataType')">
                      <span>{{ t('materialType.table.dataType') }}</span>
                      <span v-if="attributeSortIcon('dataType')" class="text-xs">{{ attributeSortIcon('dataType') }}</span>
                    </button>
                  </th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                    <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setAttributeSort('required')">
                      <span>{{ t('materialType.table.required') }}</span>
                      <span v-if="attributeSortIcon('required')" class="text-xs">{{ attributeSortIcon('required') }}</span>
                    </button>
                  </th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                    <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setAttributeSort('uiSection')">
                      <span>{{ t('materialType.table.uiSection') }}</span>
                      <span v-if="attributeSortIcon('uiSection')" class="text-xs">{{ attributeSortIcon('uiSection') }}</span>
                    </button>
                  </th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                    <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setAttributeSort('uiWidget')">
                      <span>{{ t('materialType.table.uiWidget') }}</span>
                      <span v-if="attributeSortIcon('uiWidget')" class="text-xs">{{ attributeSortIcon('uiWidget') }}</span>
                    </button>
                  </th>
                  <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                    <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setAttributeSort('active')">
                      <span>{{ t('materialType.table.active') }}</span>
                      <span v-if="attributeSortIcon('active')" class="text-xs">{{ attributeSortIcon('active') }}</span>
                    </button>
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="row in sortedAttributeRows" :key="row.key" class="hover:bg-gray-50">
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
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('materialType.form.nameJa') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="typeForm.name_ja" class="w-full h-[40px] border rounded px-3" />
                <p v-if="typeErrors.name_ja" class="mt-1 text-xs text-red-600">{{ typeErrors.name_ja }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('materialType.form.nameEn') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="typeForm.name_en" class="w-full h-[40px] border rounded px-3" />
                <p v-if="typeErrors.name_en" class="mt-1 text-xs text-red-600">{{ typeErrors.name_en }}</p>
              </div>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('materialType.form.parent') }}</label>
              <select v-model="typeForm.parent_type_id" class="w-full h-[40px] border rounded px-3 bg-white">
                <option :value="null">{{ t('materialType.form.noParent') }}</option>
                <option v-for="option in parentOptions" :key="option.type_id" :value="option.type_id">
                  {{ displayTypeName(option) }}
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
            {{ t('materialType.deleteConfirm', { name: selectedType ? displayTypeName(selectedType) : '' }) }}
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

      <div v-if="showDomainModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ t('materialType.addDomainTitle') }}</h3>
          </div>
          <div class="p-4 space-y-4">
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('materialType.form.domainCode') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="domainForm.domain" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              <p v-if="domainErrors.domain" class="mt-1 text-xs text-red-600">{{ domainErrors.domain }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('materialType.form.rootCode') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="domainForm.root_code" class="w-full h-[40px] border rounded px-3 font-mono text-sm" />
              <p v-if="domainErrors.root_code" class="mt-1 text-xs text-red-600">{{ domainErrors.root_code }}</p>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('materialType.form.nameJa') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="domainForm.name_ja" class="w-full h-[40px] border rounded px-3" />
                <p v-if="domainErrors.name_ja" class="mt-1 text-xs text-red-600">{{ domainErrors.name_ja }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('materialType.form.nameEn') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="domainForm.name_en" class="w-full h-[40px] border rounded px-3" />
                <p v-if="domainErrors.name_en" class="mt-1 text-xs text-red-600">{{ domainErrors.name_en }}</p>
              </div>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeDomainModal">{{ t('common.cancel') }}</button>
            <button
              class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
              :disabled="savingDomain"
              @click="saveDomain"
            >
              {{ savingDomain ? t('common.saving') : t('common.save') }}
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
import { useTableSort } from '@/composables/useTableSort'

type NameI18n = Record<string, string> | null

type TypeRow = {
  type_id: string
  domain: string
  code: string
  name: string
  name_i18n: NameI18n
  parent_type_id: string | null
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

type AttributeDisplayRow = {
  key: string
  attrSetLabel: string
  code: string
  name: string
  dataType: string
  required: boolean
  uiSection: string | null
  uiWidget: string | null
  active: boolean
}

type AttributeSortKey = 'attrSetLabel' | 'code' | 'name' | 'dataType' | 'required' | 'uiSection' | 'uiWidget' | 'active'

type AttrRuleRow = {
  attr_set_id: number
  attr_id: number
  required: boolean
  sort_order: number | null
  is_active: boolean
  ui_section: string | null
  ui_widget: string | null
  help_text: string | null
  attr_def: AttrDefRow | AttrDefRow[] | null
}

type DomainOption = {
  value: string
  label: string
}

const BUILTIN_DOMAINS = ['material_type', 'equipment_type'] as const
const INDUSTRY_CODE = 'CRAFT_BEER'

const { t, locale } = useI18n()
const pageTitle = computed(() => t('materialType.title'))

const selectedDomain = ref<string>('material_type')
const domainOptions = ref<DomainOption[]>([])

const typeRows = ref<TypeRow[]>([])
const loadingTypes = ref(false)
const sortingTypes = ref(false)
const selectedTypeId = ref<string | null>(null)
const expanded = ref<Set<string>>(new Set())
const expandedAll = ref(true)

const showTypeModal = ref(false)
const editingType = ref(false)
const savingType = ref(false)
const showDelete = ref(false)
const showDomainModal = ref(false)
const savingDomain = ref(false)

const typeForm = reactive({
  code: '',
  name_ja: '',
  name_en: '',
  parent_type_id: null as string | null,
  sort_order: 0,
  is_active: true,
})

const typeErrors = reactive({
  code: '',
  name_ja: '',
  name_en: '',
})

const domainForm = reactive({
  domain: '',
  root_code: '',
  name_ja: '',
  name_en: '',
})

const domainErrors = reactive({
  domain: '',
  root_code: '',
  name_ja: '',
  name_en: '',
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

const draggedTypeId = ref<string | null>(null)
const dragOverTypeId = ref<string | null>(null)

const selectedType = computed(() => {
  if (selectedTypeId.value == null) return null
  return typeRows.value.find((row) => row.type_id === selectedTypeId.value) ?? null
})

const selectedDomainLabel = computed(() => formatDomainLabel(selectedDomain.value))

const availableDomains = computed(() => {
  const labels = new Map<string, DomainOption>()
  for (const option of domainOptions.value) labels.set(option.value, option)
  return Array.from(labels.values()).sort((a, b) => a.label.localeCompare(b.label))
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
  for (const set of attrSets.value) map.set(set.attr_set_id, set)
  return map
})

const assignedAttrSets = computed(() => {
  return assignedAttrSetIds.value
    .map((id) => attrSetLookup.value.get(id))
    .filter((set): set is AttrSetRow => Boolean(set))
})

const attributeRows = computed<AttributeDisplayRow[]>(() => {
  return attrRules.value
    .map((rule) => {
      const attr = Array.isArray(rule.attr_def) ? (rule.attr_def[0] ?? null) : rule.attr_def
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
    .sort((a, b) => a.attrSetLabel.localeCompare(b.attrSetLabel) || a.code.localeCompare(b.code))
})

const {
  sortedRows: sortedAttributeRows,
  setSort: setAttributeSort,
  sortIcon: attributeSortIcon,
} = useTableSort<AttributeDisplayRow, AttributeSortKey>(
  attributeRows,
  {
    attrSetLabel: (row) => row.attrSetLabel,
    code: (row) => row.code,
    name: (row) => row.name,
    dataType: (row) => row.dataType,
    required: (row) => row.required,
    uiSection: (row) => row.uiSection,
    uiWidget: (row) => row.uiWidget,
    active: (row) => row.active,
  },
  'attrSetLabel',
)

function canonicalName(nameJa: string, nameEn: string) {
  return nameJa.trim() || nameEn.trim()
}

function buildNameI18n(nameJa: string, nameEn: string) {
  return {
    ja: nameJa.trim(),
    en: nameEn.trim(),
  }
}

function formatDomainLabel(domain: string) {
  if (domain === 'material_type') return t('materialType.domains.materialType')
  if (domain === 'equipment_type') return t('materialType.domains.equipmentType')
  return domain
}

function displayTypeName(row: Pick<TypeRow, 'name' | 'code' | 'name_i18n'> | null) {
  if (!row) return ''
  const isJa = locale.value.startsWith('ja')
  const ja = row.name_i18n?.ja?.trim()
  const en = row.name_i18n?.en?.trim()
  if (isJa) return ja || row.name || en || row.code
  return en || row.name || ja || row.code
}

function getDefaultDomainRoot(domain: string) {
  if (domain === 'material_type') {
    return {
      code: 'material',
      nameJa: '原材料',
      nameEn: 'Material',
    }
  }
  if (domain === 'equipment_type') {
    return {
      code: 'equipment',
      nameJa: '設備',
      nameEn: 'Equipment',
    }
  }
  const base = domain.endsWith('_type') ? domain.slice(0, -5) : domain
  const code = base || 'root'
  const label = code.replace(/_/g, ' ')
  const nameEn = label.replace(/\b\w/g, (char) => char.toUpperCase())
  return {
    code,
    nameJa: nameEn,
    nameEn,
  }
}

function resolveAttrSetDomains(domain: string) {
  if (domain === 'material_type') return ['material']
  if (domain === 'equipment_type') return ['equipment']
  if (domain.endsWith('_type')) {
    return [domain, domain.slice(0, -5)].filter((value, index, list) => value && list.indexOf(value) === index)
  }
  return [domain]
}

function buildTree(rows: TypeRow[]) {
  const map = new Map<string, TreeNode>()
  for (const row of rows) map.set(row.type_id, { row, children: [] })
  const roots: TreeNode[] = []
  for (const node of map.values()) {
    const parentId = node.row.parent_type_id
    if (parentId && map.has(parentId)) map.get(parentId)?.children.push(node)
    else roots.push(node)
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

function isExpanded(typeId: string) {
  return expanded.value.has(typeId)
}

function toggleExpanded(typeId: string) {
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

function selectType(typeId: string) {
  selectedTypeId.value = typeId
  loadAttributes()
}

function resetTypeForm() {
  typeForm.code = ''
  typeForm.name_ja = ''
  typeForm.name_en = ''
  typeForm.parent_type_id = null
  typeForm.sort_order = 0
  typeForm.is_active = true
  typeErrors.code = ''
  typeErrors.name_ja = ''
  typeErrors.name_en = ''
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
  typeForm.name_ja = selectedType.value.name_i18n?.ja ?? selectedType.value.name
  typeForm.name_en = selectedType.value.name_i18n?.en ?? selectedType.value.name
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
  typeErrors.name_ja = ''
  typeErrors.name_en = ''
  if (!typeForm.code.trim()) typeErrors.code = t('materialType.errors.codeRequired')
  if (!typeForm.name_ja.trim()) typeErrors.name_ja = t('materialType.errors.nameJaRequired')
  if (!typeForm.name_en.trim()) typeErrors.name_en = t('materialType.errors.nameEnRequired')
  return !typeErrors.code && !typeErrors.name_ja && !typeErrors.name_en
}

function confirmDelete() {
  if (!selectedType.value) return
  showDelete.value = true
}

function resetDomainForm() {
  const defaults = getDefaultDomainRoot(selectedDomain.value)
  domainForm.domain = ''
  domainForm.root_code = defaults.code
  domainForm.name_ja = defaults.nameJa
  domainForm.name_en = defaults.nameEn
  domainErrors.domain = ''
  domainErrors.root_code = ''
  domainErrors.name_ja = ''
  domainErrors.name_en = ''
}

function openAddDomain() {
  resetDomainForm()
  showDomainModal.value = true
}

function closeDomainModal() {
  showDomainModal.value = false
}

function validateDomainForm() {
  domainErrors.domain = ''
  domainErrors.root_code = ''
  domainErrors.name_ja = ''
  domainErrors.name_en = ''
  if (!domainForm.domain.trim()) domainErrors.domain = t('materialType.errors.domainRequired')
  if (!domainForm.root_code.trim()) domainErrors.root_code = t('materialType.errors.rootCodeRequired')
  if (!domainForm.name_ja.trim()) domainErrors.name_ja = t('materialType.errors.nameJaRequired')
  if (!domainForm.name_en.trim()) domainErrors.name_en = t('materialType.errors.nameEnRequired')
  if (availableDomains.value.some((entry) => entry.value === domainForm.domain.trim())) {
    domainErrors.domain = t('materialType.errors.domainExists')
  }
  return !domainErrors.domain && !domainErrors.root_code && !domainErrors.name_ja && !domainErrors.name_en
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

function siblingRows(parentTypeId: string | null) {
  return typeRows.value
    .filter((row) => (row.parent_type_id ?? null) === (parentTypeId ?? null))
    .slice()
    .sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0) || a.code.localeCompare(b.code))
}

function canDragRow(row: TypeRow) {
  if (!canEdit(row)) return false
  return siblingRows(row.parent_type_id).every((item) => canEdit(item))
}

function canDropOn(targetTypeId: string) {
  if (!draggedTypeId.value || draggedTypeId.value === targetTypeId) return false
  const dragged = typeRows.value.find((row) => row.type_id === draggedTypeId.value)
  const target = typeRows.value.find((row) => row.type_id === targetTypeId)
  if (!dragged || !target) return false
  if (!canDragRow(dragged) || !canDragRow(target)) return false
  return (dragged.parent_type_id ?? null) === (target.parent_type_id ?? null)
}

function handleDragStart(typeId: string) {
  const row = typeRows.value.find((entry) => entry.type_id === typeId)
  if (!row || !canDragRow(row)) return
  draggedTypeId.value = typeId
}

function handleDragOver(typeId: string) {
  dragOverTypeId.value = canDropOn(typeId) ? typeId : null
}

function clearDragState() {
  draggedTypeId.value = null
  dragOverTypeId.value = null
}

async function handleDrop(targetTypeId: string) {
  try {
    if (!canDropOn(targetTypeId) || !draggedTypeId.value) return
    sortingTypes.value = true
    const tenant = await ensureTenant()
    const dragged = typeRows.value.find((row) => row.type_id === draggedTypeId.value)
    const target = typeRows.value.find((row) => row.type_id === targetTypeId)
    if (!dragged || !target) return
    const siblings = siblingRows(target.parent_type_id)
    const draggedIndex = siblings.findIndex((row) => row.type_id === dragged.type_id)
    const targetIndex = siblings.findIndex((row) => row.type_id === target.type_id)
    if (draggedIndex < 0 || targetIndex < 0) return
    const reordered = siblings.slice()
    const [removed] = reordered.splice(draggedIndex, 1)
    reordered.splice(targetIndex, 0, removed)
    const changed = reordered
      .map((row, index) => ({ row, sortOrder: (index + 1) * 10 }))
      .filter(({ row, sortOrder }) => (row.sort_order ?? 0) !== sortOrder)
    if (changed.length === 0) return
    const results = await Promise.all(
      changed.map(({ row, sortOrder }) =>
        supabase
          .from('type_def')
          .update({ sort_order: sortOrder })
          .eq('tenant_id', tenant)
          .eq('type_id', row.type_id),
      ),
    )
    const failed = results.find((result) => result.error)
    if (failed?.error) throw failed.error
    toast.success(t('common.saved'))
    await fetchTypes()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    sortingTypes.value = false
    clearDragState()
  }
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

async function fetchDomains() {
  try {
    const industry = await ensureIndustry()
    const { data, error } = await supabase
      .from('type_def')
      .select('domain')
      .eq('industry_id', industry)
      .order('domain', { ascending: true })
    if (error) throw error
    const values = new Set<string>(BUILTIN_DOMAINS)
    for (const row of data ?? []) {
      if (typeof row.domain === 'string' && row.domain.trim()) values.add(row.domain)
    }
    if (selectedDomain.value.trim()) values.add(selectedDomain.value.trim())
    domainOptions.value = Array.from(values).map((value) => ({
      value,
      label: formatDomainLabel(value),
    }))
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
    domainOptions.value = Array.from(BUILTIN_DOMAINS).map((value) => ({ value, label: formatDomainLabel(value) }))
  }
}

async function fetchTypes() {
  try {
    loadingTypes.value = true
    const industry = await ensureIndustry()
    const { data, error } = await supabase
      .from('type_def')
      .select('type_id, domain, code, name, name_i18n, parent_type_id, sort_order, is_active, created_at, scope, owner_id')
      .eq('domain', selectedDomain.value)
      .eq('industry_id', industry)
      .order('sort_order', { ascending: true })
      .order('code', { ascending: true })
    if (error) throw error
    const rows = (data ?? []) as TypeRow[]
    if (rows.length === 0 && !ensuringRoot.value && BUILTIN_DOMAINS.includes(selectedDomain.value as (typeof BUILTIN_DOMAINS)[number])) {
      ensuringRoot.value = true
      try {
        await createRootType(selectedDomain.value)
        const { data: refreshed, error: refreshError } = await supabase
          .from('type_def')
          .select('type_id, domain, code, name, name_i18n, parent_type_id, sort_order, is_active, created_at, scope, owner_id')
          .eq('domain', selectedDomain.value)
          .eq('industry_id', industry)
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

async function createRootType(domain: string) {
  const tenant = await ensureTenant()
  const industry = await ensureIndustry()
  const defaults = getDefaultDomainRoot(domain)
  const payload = {
    tenant_id: tenant,
    domain,
    industry_id: industry,
    code: defaults.code,
    name: canonicalName(defaults.nameJa, defaults.nameEn),
    name_i18n: buildNameI18n(defaults.nameJa, defaults.nameEn),
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
    const attrDomains = resolveAttrSetDomains(selectedDomain.value)
    const { data, error } = await supabase
      .from('attr_set')
      .select('attr_set_id, code, name, domain, scope, owner_id, is_active, sort_order')
      .in('domain', attrDomains)
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
      .eq('entity_type', selectedDomain.value)
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
    attrRules.value = (ruleData ?? []) as unknown as AttrRuleRow[]
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
    const name = canonicalName(typeForm.name_ja, typeForm.name_en)
    const nameI18n = buildNameI18n(typeForm.name_ja, typeForm.name_en)
    if (editingType.value && selectedType.value) {
      if (!canEdit(selectedType.value)) {
        throw new Error(t('materialType.errors.adminOnlySystem'))
      }
      const { error } = await supabase
        .from('type_def')
        .update({
          code: typeForm.code.trim(),
          name,
          name_i18n: nameI18n,
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
        domain: selectedDomain.value,
        industry_id: industry,
        code: typeForm.code.trim(),
        name,
        name_i18n: nameI18n,
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

async function saveDomain() {
  try {
    if (!validateDomainForm()) return
    savingDomain.value = true
    const tenant = await ensureTenant()
    const industry = await ensureIndustry()
    const domain = domainForm.domain.trim()
    const payload = {
      tenant_id: tenant,
      domain,
      industry_id: industry,
      code: domainForm.root_code.trim(),
      name: canonicalName(domainForm.name_ja, domainForm.name_en),
      name_i18n: buildNameI18n(domainForm.name_ja, domainForm.name_en),
      parent_type_id: null,
      sort_order: 0,
      is_active: true,
      scope: 'tenant',
      owner_id: tenant,
    }
    const { error } = await supabase.from('type_def').insert(payload)
    if (error) throw error
    selectedDomain.value = domain
    showDomainModal.value = false
    await fetchDomains()
    await refreshCurrentDomain()
    toast.success(t('common.saved'))
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    savingDomain.value = false
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
        entity_type: selectedDomain.value,
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
        .eq('entity_type', selectedDomain.value)
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

async function refreshCurrentDomain() {
  selectedTypeId.value = null
  assignedAttrSetIds.value = []
  attrRules.value = []
  await fetchTypes()
  await fetchAttrSets()
  await loadAttributes()
}

async function handleDomainChange() {
  await refreshCurrentDomain()
}

async function refreshAll() {
  await fetchDomains()
  await fetchTypes()
  await fetchAttrSets()
  await loadAttributes()
}

onMounted(async () => {
  await refreshAll()
})
</script>
