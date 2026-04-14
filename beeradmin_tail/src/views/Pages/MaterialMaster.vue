<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="space-y-6">
      <section class="rounded-lg border border-gray-200 bg-white shadow">
        <header class="flex flex-col gap-4 border-b p-4 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h2 class="text-lg font-semibold text-gray-900">{{ pageTitle }}</h2>
            <p class="mt-1 text-sm text-gray-500">{{ pageSubtitle }}</p>
          </div>

          <div class="flex flex-col gap-2 sm:flex-row sm:items-center">
            <div class="relative">
              <input
                v-model.trim="materialSearchTerm"
                type="search"
                :placeholder="t('material.searchPlaceholder')"
                class="h-[40px] w-full rounded border border-gray-300 px-3 pr-9 text-sm sm:w-72"
              />
              <span class="pointer-events-none absolute inset-y-0 right-3 flex items-center text-gray-400">
                <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-4.35-4.35m0 0A7.5 7.5 0 1016.65 16.65z" />
                </svg>
              </span>
            </div>

            <button
              type="button"
              class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50 disabled:opacity-60"
              :disabled="loading"
              @click="loadPage"
            >
              {{ t('common.refresh') }}
            </button>

            <button
              type="button"
              class="rounded bg-blue-600 px-3 py-2 text-sm text-white hover:bg-blue-700 disabled:opacity-60"
              :disabled="!canCreate"
              @click="startCreate"
            >
              {{ t('material.actions.newMaterial') }}
            </button>
          </div>
        </header>

        <div v-if="pageError" class="border-b border-red-100 bg-red-50 px-4 py-3 text-sm text-red-700">
          {{ pageError }}
        </div>

        <div v-if="loading" class="px-4 py-8 text-sm text-gray-500">
          {{ t('common.loading') }}
        </div>

        <div v-else class="grid grid-cols-1 gap-4 p-4" :class="contentGridClass">
          <div class="relative" :class="showTypePanel ? 'xl:block' : 'xl:hidden'">
            <aside class="rounded-lg border border-gray-200 bg-gray-50">
              <div class="border-b border-gray-200 px-4 py-3">
                <h3 class="text-sm font-semibold text-gray-900">{{ t('material.treeTitle') }}</h3>
                <p class="mt-1 text-xs text-gray-500">{{ t('material.treeHint') }}</p>
              </div>

              <div class="space-y-3 p-4">
                <div class="relative">
                  <input
                    v-model.trim="typeSearchTerm"
                    type="search"
                    :placeholder="t('material.typeSearchPlaceholder')"
                    class="h-[40px] w-full rounded border border-gray-300 bg-white px-3 pr-9 text-sm"
                  />
                  <span class="pointer-events-none absolute inset-y-0 right-3 flex items-center text-gray-400">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-4.35-4.35m0 0A7.5 7.5 0 1016.65 16.65z" />
                    </svg>
                  </span>
                </div>

                <div class="rounded-lg border border-dashed border-gray-300 bg-white px-3 py-3">
                  <div class="text-xs text-gray-500">{{ t('material.selectedType') }}</div>
                  <div v-if="selectedType" class="mt-1">
                    <div class="font-medium text-gray-900">{{ displayMaterialTypeName(selectedType) }}</div>
                    <div class="font-mono text-xs text-gray-500">{{ selectedType.code }}</div>
                    <div class="mt-1 text-xs text-gray-500">{{ selectedTypePathText }}</div>
                  </div>
                  <div v-else class="mt-1 text-sm text-gray-500">{{ t('material.empty.noTypeSelected') }}</div>
                </div>
              </div>

              <div class="max-h-[520px] overflow-y-auto px-2 pb-3">
                <div v-if="materialTypeTreeEntries.length === 0" class="px-3 py-6 text-sm text-gray-500">
                  {{ t('material.empty.typeTree') }}
                </div>

                <ul v-else class="space-y-1">
                  <li v-for="entry in materialTypeTreeEntries" :key="entry.node.row.type_id">
                    <div class="flex items-center gap-1" :style="{ paddingLeft: `${8 + entry.depth * 16}px` }">
                      <button
                        v-if="isExpandableType(entry.node.row.type_id)"
                        type="button"
                        class="flex h-8 w-8 items-center justify-center rounded text-gray-500 transition hover:bg-white hover:text-gray-700"
                        :aria-label="typeToggleLabel(isTypeExpanded(entry.node.row.type_id))"
                        :title="typeToggleLabel(isTypeExpanded(entry.node.row.type_id))"
                        @click.stop="toggleTypeExpanded(entry.node.row.type_id)"
                      >
                        <span aria-hidden="true">{{ isTypeExpanded(entry.node.row.type_id) ? '▾' : '▸' }}</span>
                      </button>
                      <span v-else class="inline-block h-8 w-8" aria-hidden="true" />

                      <button
                        type="button"
                        class="flex min-w-0 flex-1 items-center rounded px-2 py-2 text-left text-sm transition hover:bg-white"
                        :class="selectedTypeId === entry.node.row.type_id ? 'bg-blue-50 text-blue-700 ring-1 ring-blue-200' : 'text-gray-700'"
                        @click="selectType(entry.node.row.type_id)"
                      >
                        <span class="truncate">{{ displayMaterialTypeName(entry.node.row) }}</span>
                      </button>
                    </div>
                  </li>
                </ul>
              </div>
            </aside>

            <button
              type="button"
              class="absolute right-0 top-6 z-10 hidden h-9 w-7 translate-x-1/2 items-center justify-center rounded-full border border-gray-300 bg-white text-gray-500 shadow-sm transition hover:border-gray-400 hover:bg-gray-50 hover:text-gray-700 xl:flex"
              :aria-label="typePanelToggleText"
              :title="typePanelToggleText"
              @click="toggleTypePanel"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 6l-6 6 6 6" />
              </svg>
            </button>
          </div>

          <section class="relative rounded-lg border border-gray-200 bg-white">
            <button
              v-if="!showTypePanel"
              type="button"
              class="absolute left-0 top-6 z-10 hidden h-9 w-7 -translate-x-1/2 items-center justify-center rounded-full border border-gray-300 bg-white text-gray-500 shadow-sm transition hover:border-gray-400 hover:bg-gray-50 hover:text-gray-700 xl:flex"
              :aria-label="typePanelToggleText"
              :title="typePanelToggleText"
              @click="toggleTypePanel"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 6l6 6-6 6" />
              </svg>
            </button>
            <div class="border-b border-gray-200 px-4 py-3">
              <div class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
                <div>
                  <h3 class="text-sm font-semibold text-gray-900">{{ t('material.listTitle') }}</h3>
                  <p class="mt-1 text-xs text-gray-500">
                    {{ selectedType ? selectedTypePathText : t('material.empty.noTypeSelected') }}
                  </p>
                </div>

                <div class="flex items-center gap-2">
                  <span class="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-600">
                    {{ filteredMaterialRows.length }}
                  </span>
                  <button
                    type="button"
                    class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50 disabled:opacity-60"
                    :disabled="!canCreate"
                    @click="startCreate"
                  >
                    {{ t('material.actions.createHere') }}
                  </button>
                </div>
              </div>
            </div>

            <div v-if="!selectedType" class="px-4 py-10 text-sm text-gray-500">
              {{ t('material.empty.noTypeSelected') }}
            </div>

            <div v-else-if="filteredMaterialRows.length === 0" class="space-y-3 px-4 py-10 text-sm text-gray-500">
              <p>{{ materialSearchTerm ? t('material.empty.noSearchResults') : t('material.empty.noMaterials') }}</p>
              <button
                type="button"
                class="rounded border border-gray-300 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-60"
                :disabled="!canCreate"
                @click="startCreate"
              >
                {{ t('material.actions.createFirst') }}
              </button>
            </div>

            <div v-else>
              <div class="hidden overflow-x-auto lg:block">
                <table class="min-w-full divide-y divide-gray-200">
                  <thead class="bg-gray-50">
                    <tr>
                      <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">{{ t('material.fields.code') }}</th>
                      <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">{{ t('material.fields.name') }}</th>
                      <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">{{ t('material.fields.uom') }}</th>
                      <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">{{ t('material.fields.status') }}</th>
                      <th class="px-4 py-3 text-left text-xs font-medium uppercase tracking-wide text-gray-500">{{ t('common.actions') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr
                      v-for="row in filteredMaterialRows"
                      :key="row.id"
                      class="cursor-pointer transition hover:bg-gray-50"
                      :class="selectedMaterialId === row.id ? 'bg-blue-50' : ''"
                      @click="selectMaterial(row)"
                    >
                      <td class="px-4 py-3 font-mono text-xs text-gray-700">{{ row.material_code }}</td>
                      <td class="px-4 py-3">
                        <div class="font-medium text-gray-900">{{ row.material_name || row.material_code }}</div>
                        <div class="mt-1 text-xs text-gray-500">{{ materialTypePathText(row.material_type_id) }}</div>
                      </td>
                      <td class="px-4 py-3 text-sm text-gray-600">{{ uomLabel(row.base_uom_id) }}</td>
                      <td class="px-4 py-3">
                        <span class="rounded-full px-2 py-1 text-xs font-medium" :class="statusBadgeClass(row.status)">
                          {{ formatStatus(row.status) }}
                        </span>
                      </td>
                      <td class="px-4 py-3">
                        <div class="flex items-center gap-2">
                          <button type="button" class="rounded border border-gray-300 px-2 py-1 text-sm hover:bg-white" @click.stop="selectMaterial(row)">
                            {{ t('common.edit') }}
                          </button>
                          <button type="button" class="rounded border border-red-200 px-2 py-1 text-sm text-red-600 hover:bg-red-50" @click.stop="openDelete(row)">
                            {{ t('common.delete') }}
                          </button>
                        </div>
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div class="grid gap-3 p-4 lg:hidden">
                <article
                  v-for="row in filteredMaterialRows"
                  :key="`card-${row.id}`"
                  class="rounded-lg border border-gray-200 p-4"
                  :class="selectedMaterialId === row.id ? 'ring-1 ring-blue-200' : ''"
                >
                  <div class="flex items-start justify-between gap-3">
                    <div>
                      <div class="font-medium text-gray-900">{{ row.material_name || row.material_code }}</div>
                      <div class="font-mono text-xs text-gray-500">{{ row.material_code }}</div>
                    </div>
                    <span class="rounded-full px-2 py-1 text-xs font-medium" :class="statusBadgeClass(row.status)">
                      {{ formatStatus(row.status) }}
                    </span>
                  </div>

                  <dl class="mt-3 space-y-2 text-sm text-gray-600">
                    <div class="flex justify-between gap-3">
                      <dt>{{ t('material.fields.uom') }}</dt>
                      <dd>{{ uomLabel(row.base_uom_id) }}</dd>
                    </div>
                    <div class="space-y-1">
                      <dt>{{ t('material.fields.type') }}</dt>
                      <dd class="text-xs text-gray-500">{{ materialTypePathText(row.material_type_id) }}</dd>
                    </div>
                  </dl>

                  <div class="mt-4 flex items-center gap-2">
                    <button type="button" class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50" @click="selectMaterial(row)">
                      {{ t('common.edit') }}
                    </button>
                    <button type="button" class="rounded border border-red-200 px-3 py-2 text-sm text-red-600 hover:bg-red-50" @click="openDelete(row)">
                      {{ t('common.delete') }}
                    </button>
                  </div>
                </article>
              </div>
            </div>
          </section>

          <section class="rounded-lg border border-gray-200 bg-white">
            <div class="border-b border-gray-200 px-4 py-3">
              <h3 class="text-sm font-semibold text-gray-900">{{ formTitle }}</h3>
              <p class="mt-1 text-xs text-gray-500">{{ formSubtitle }}</p>
            </div>

            <div v-if="formMode === 'idle'" class="space-y-4 px-4 py-6">
              <div class="rounded-lg border border-dashed border-gray-300 bg-gray-50 px-4 py-4">
                <div class="text-xs text-gray-500">{{ t('material.selectedType') }}</div>
                <div v-if="selectedType" class="mt-1">
                  <div class="font-medium text-gray-900">{{ displayMaterialTypeName(selectedType) }}</div>
                  <div class="font-mono text-xs text-gray-500">{{ selectedType.code }}</div>
                  <div class="mt-1 text-xs text-gray-500">{{ selectedTypePathText }}</div>
                </div>
                <div v-else class="mt-1 text-sm text-gray-500">{{ t('material.empty.noTypeSelected') }}</div>
              </div>

              <p class="text-sm text-gray-500">{{ t('material.detailHint') }}</p>

              <button
                type="button"
                class="rounded bg-blue-600 px-3 py-2 text-sm text-white hover:bg-blue-700 disabled:opacity-60"
                :disabled="!canCreate"
                @click="startCreate"
              >
                {{ t('material.actions.newMaterial') }}
              </button>
            </div>

            <form v-else class="space-y-4 px-4 py-4" @submit.prevent="saveRecord">
              <div class="rounded-lg border border-dashed border-gray-300 bg-gray-50 px-4 py-3">
                <div class="text-xs text-gray-500">{{ t('material.selectedType') }}</div>
                <div v-if="formSelectedType" class="mt-1">
                  <div class="font-medium text-gray-900">{{ displayMaterialTypeName(formSelectedType) }}</div>
                  <div class="font-mono text-xs text-gray-500">{{ formSelectedType.code }}</div>
                  <div class="mt-1 text-xs text-gray-500">{{ formTypePathText }}</div>
                </div>
                <div v-else class="mt-1 text-sm text-red-600">{{ errors.material_type_id || t('material.empty.noTypeSelected') }}</div>
                <div class="mt-3 flex flex-wrap items-center gap-2">
                  <button
                    v-if="selectedTypeId && selectedTypeId !== form.material_type_id"
                    type="button"
                    class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-white"
                    @click="applySelectedTypeToForm"
                  >
                    {{ t('material.actions.useSelectedType') }}
                  </button>
                  <span class="text-xs text-gray-500">{{ t('material.formTypeHint') }}</span>
                </div>
              </div>

              <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div>
                  <label class="mb-1 block text-sm text-gray-600">
                    {{ t('material.fields.code') }}<span class="text-red-600">*</span>
                  </label>
                  <input
                    v-model.trim="form.material_code"
                    :placeholder="t('material.placeholders.code')"
                    class="h-[40px] w-full rounded border border-gray-300 px-3"
                  />
                  <p v-if="errors.material_code" class="mt-1 text-xs text-red-600">{{ errors.material_code }}</p>
                </div>

                <div>
                  <label class="mb-1 block text-sm text-gray-600">
                    {{ t('material.fields.name') }}<span class="text-red-600">*</span>
                  </label>
                  <input
                    v-model.trim="form.material_name"
                    :placeholder="t('material.placeholders.name')"
                    class="h-[40px] w-full rounded border border-gray-300 px-3"
                  />
                  <p v-if="errors.material_name" class="mt-1 text-xs text-red-600">{{ errors.material_name }}</p>
                </div>

                <div>
                  <label class="mb-1 block text-sm text-gray-600">
                    {{ t('material.fields.uom') }}<span class="text-red-600">*</span>
                  </label>
                  <select v-model="form.base_uom_id" class="h-[40px] w-full rounded border border-gray-300 bg-white px-3">
                    <option value="">{{ t('material.placeholders.uom') }}</option>
                    <option v-for="uom in uomOptions" :key="uom.id" :value="uom.id">
                      {{ uom.code }}{{ uom.name ? ` - ${uom.name}` : '' }}
                    </option>
                  </select>
                  <p v-if="errors.base_uom_id" class="mt-1 text-xs text-red-600">{{ errors.base_uom_id }}</p>
                </div>

                <div>
                  <label class="mb-1 block text-sm text-gray-600">
                    {{ t('material.fields.status') }}<span class="text-red-600">*</span>
                  </label>
                  <select v-model="form.status" class="h-[40px] w-full rounded border border-gray-300 bg-white px-3">
                    <option value="">{{ t('material.placeholders.status') }}</option>
                    <option v-for="status in statusOptions" :key="status" :value="status">{{ formatStatus(status) }}</option>
                  </select>
                  <p v-if="errors.status" class="mt-1 text-xs text-red-600">{{ errors.status }}</p>
                </div>
              </div>

              <div class="flex flex-wrap items-center justify-end gap-2 border-t border-gray-200 pt-4">
                <button type="button" class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50" @click="resetFormPane">
                  {{ t('common.cancel') }}
                </button>
                <button
                  v-if="formMode === 'edit' && selectedMaterialRow"
                  type="button"
                  class="rounded border border-red-200 px-3 py-2 text-sm text-red-600 hover:bg-red-50"
                  @click="openDelete(selectedMaterialRow)"
                >
                  {{ t('common.delete') }}
                </button>
                <button
                  type="submit"
                  class="rounded bg-blue-600 px-3 py-2 text-sm text-white hover:bg-blue-700 disabled:opacity-60"
                  :disabled="saving"
                >
                  {{ saving ? t('common.saving') : t('common.save') }}
                </button>
              </div>
            </form>
          </section>
        </div>
      </section>

      <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-md rounded-xl border bg-white shadow-lg">
          <div class="border-b px-4 py-3">
            <h3 class="font-semibold text-gray-900">{{ t('material.deleteTitle') }}</h3>
          </div>
          <div class="px-4 py-4 text-sm text-gray-700">
            {{ t('material.deleteConfirm', { code: deleteTarget?.material_code ?? '' }) }}
          </div>
          <div class="flex items-center justify-end gap-2 border-t px-4 py-3">
            <button type="button" class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-50" @click="closeDelete">
              {{ t('common.cancel') }}
            </button>
            <button
              type="button"
              class="rounded bg-red-600 px-3 py-2 text-sm text-white hover:bg-red-700 disabled:opacity-60"
              :disabled="deleting"
              @click="deleteRecord"
            >
              {{ t('common.delete') }}
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
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'

type NameI18n = {
  ja?: string | null
  en?: string | null
} | null

type MaterialTypeRow = {
  type_id: string
  code: string
  name: string | null
  name_i18n?: NameI18n
  parent_type_id: string | null
  sort_order: number | null
}

type MaterialTreeNode = {
  row: MaterialTypeRow
  children: MaterialTreeNode[]
}

type MaterialTreeEntry = {
  node: MaterialTreeNode
  depth: number
}

type UomRow = {
  id: string
  code: string
  name: string | null
}

type MaterialRow = {
  id: string
  material_code: string
  material_name: string
  material_type_id: string | null
  base_uom_id: string | null
  status: string
}

type MaterialFormState = {
  id: string
  material_code: string
  material_name: string
  material_type_id: string
  base_uom_id: string
  status: string
}

type MaterialFormMode = 'idle' | 'create' | 'edit'

const STATUS_OPTIONS = ['active', 'inactive'] as const

const { t, locale } = useI18n()

const pageTitle = computed(() => t('material.title'))
const pageSubtitle = computed(() => t('material.subtitle'))

const mesClient = () => supabase.schema('mes')

const loading = ref(false)
const saving = ref(false)
const deleting = ref(false)
const pageError = ref('')

const typeSearchTerm = ref('')
const materialSearchTerm = ref('')

const materialTypes = ref<MaterialTypeRow[]>([])
const materialRows = ref<MaterialRow[]>([])
const uomOptions = ref<UomRow[]>([])

const selectedTypeId = ref('')
const selectedMaterialId = ref('')
const formMode = ref<MaterialFormMode>('idle')
const showTypePanel = ref(true)
const expandedTypeIds = ref<Set<string>>(new Set())
const treeExpansionInitialized = ref(false)

const showDelete = ref(false)
const deleteTarget = ref<MaterialRow | null>(null)

const form = reactive<MaterialFormState>(blankForm())
const errors = reactive<Record<string, string>>({})

function blankForm(): MaterialFormState {
  return {
    id: '',
    material_code: '',
    material_name: '',
    material_type_id: '',
    base_uom_id: '',
    status: 'active',
  }
}

function sortTypeRows(rows: MaterialTypeRow[]) {
  return rows.slice().sort((a, b) => {
    const sortDiff = (a.sort_order ?? 0) - (b.sort_order ?? 0)
    if (sortDiff !== 0) return sortDiff
    return a.code.localeCompare(b.code)
  })
}

function normalizeMaterialRow(value: Record<string, unknown>): MaterialRow {
  return {
    id: String(value.id),
    material_code: typeof value.material_code === 'string' ? value.material_code : '',
    material_name: typeof value.material_name === 'string' ? value.material_name : '',
    material_type_id: typeof value.material_type_id === 'string' && value.material_type_id.trim() ? value.material_type_id : null,
    base_uom_id: typeof value.base_uom_id === 'string' && value.base_uom_id.trim() ? value.base_uom_id : null,
    status: typeof value.status === 'string' && value.status.trim() ? value.status : 'active',
  }
}

const materialTypeMap = computed(() => {
  const map = new Map<string, MaterialTypeRow>()
  materialTypes.value.forEach((row) => map.set(row.type_id, row))
  return map
})

const expandableTypeIds = computed(() => {
  const parentIds = new Set<string>()
  for (const row of materialTypes.value) {
    if (row.parent_type_id) parentIds.add(row.parent_type_id)
  }
  return parentIds
})

const materialMap = computed(() => {
  const map = new Map<string, MaterialRow>()
  materialRows.value.forEach((row) => map.set(row.id, row))
  return map
})

const uomMap = computed(() => {
  const map = new Map<string, UomRow>()
  uomOptions.value.forEach((row) => map.set(row.id, row))
  return map
})

const rawMaterialRoot = computed(() => materialTypes.value.find((row) => row.code === 'RAW_MATERIAL') ?? null)

const materialTypeForest = computed<MaterialTreeNode[]>(() => {
  if (materialTypes.value.length === 0) return []

  const childrenByParent = new Map<string | null, MaterialTypeRow[]>()
  for (const row of materialTypes.value) {
    const key = row.parent_type_id ?? null
    const list = childrenByParent.get(key) ?? []
    list.push(row)
    childrenByParent.set(key, list)
  }

  const buildNode = (row: MaterialTypeRow): MaterialTreeNode => ({
    row,
    children: sortTypeRows(childrenByParent.get(row.type_id) ?? []).map((child) => buildNode(child)),
  })

  if (rawMaterialRoot.value) return [buildNode(rawMaterialRoot.value)]

  const roots = materialTypes.value.filter((row) => !row.parent_type_id || !materialTypeMap.value.has(row.parent_type_id))
  return sortTypeRows(roots).map((row) => buildNode(row))
})

const visibleMaterialTypeForest = computed<MaterialTreeNode[]>(() => {
  const query = typeSearchTerm.value.trim().toLowerCase()
  if (!query) return materialTypeForest.value

  const filterNode = (node: MaterialTreeNode): MaterialTreeNode | null => {
    const label = displayMaterialTypeName(node.row).toLowerCase()
    const selfMatches = label.includes(query) || node.row.code.toLowerCase().includes(query)
    if (selfMatches) return node

    const children = node.children
      .map((child) => filterNode(child))
      .filter((child): child is MaterialTreeNode => Boolean(child))

    if (children.length === 0) return null
    return { row: node.row, children }
  }

  return materialTypeForest.value
    .map((node) => filterNode(node))
    .filter((node): node is MaterialTreeNode => Boolean(node))
})

const materialTypeTreeEntries = computed<MaterialTreeEntry[]>(() => {
  const entries: MaterialTreeEntry[] = []
  const visit = (node: MaterialTreeNode, depth: number) => {
    entries.push({ node, depth })
    if (node.children.length === 0 || isTypeExpanded(node.row.type_id)) {
      node.children.forEach((child) => visit(child, depth + 1))
    }
  }
  visibleMaterialTypeForest.value.forEach((node) => visit(node, 0))
  return entries
})

const selectedType = computed(() => (selectedTypeId.value ? materialTypeMap.value.get(selectedTypeId.value) ?? null : null))

const selectedTypeDescendantIds = computed(() => {
  if (!selectedTypeId.value) return new Set<string>()
  const ids = new Set<string>()
  const walk = (typeId: string) => {
    if (ids.has(typeId)) return
    ids.add(typeId)
    for (const row of materialTypes.value) {
      if (row.parent_type_id === typeId) walk(row.type_id)
    }
  }
  walk(selectedTypeId.value)
  return ids
})

const filteredMaterialRows = computed(() => {
  const keyword = materialSearchTerm.value.trim().toLowerCase()

  return materialRows.value
    .filter((row) => {
      if (selectedTypeDescendantIds.value.size > 0 && (!row.material_type_id || !selectedTypeDescendantIds.value.has(row.material_type_id))) {
        return false
      }

      if (!keyword) return true
      const name = row.material_name.toLowerCase()
      const code = row.material_code.toLowerCase()
      return name.includes(keyword) || code.includes(keyword)
    })
    .slice()
    .sort((a, b) => a.material_code.localeCompare(b.material_code))
})

const selectedMaterialRow = computed(() => (selectedMaterialId.value ? materialMap.value.get(selectedMaterialId.value) ?? null : null))

const formSelectedType = computed(() => (form.material_type_id ? materialTypeMap.value.get(form.material_type_id) ?? null : null))

const statusOptions = computed(() => {
  const values = new Set<string>(STATUS_OPTIONS)
  if (form.status) values.add(form.status)
  return Array.from(values)
})

const canCreate = computed(() => Boolean(selectedTypeId.value) && !loading.value)
const contentGridClass = computed(() => (
  showTypePanel.value
    ? 'xl:grid-cols-[280px_minmax(0,1fr)_360px]'
    : 'xl:grid-cols-[minmax(0,1fr)_360px]'
))
const typePanelToggleText = computed(() => {
  const title = t('material.treeTitle')
  const action = showTypePanel.value ? t('common.collapse') : t('common.expand')
  const isJa = locale.value.toString().toLowerCase().startsWith('ja')
  return isJa ? `${title}を${action}` : `${action} ${title}`
})

const formTitle = computed(() => {
  if (formMode.value === 'edit') return t('material.editTitle')
  if (formMode.value === 'create') return t('material.newTitle')
  return t('material.detailTitle')
})

const formSubtitle = computed(() => {
  if (formMode.value === 'edit') return t('material.formEditHint')
  if (formMode.value === 'create') return t('material.formCreateHint')
  return t('material.detailHint')
})

const selectedTypePathText = computed(() => materialTypePathText(selectedTypeId.value))
const formTypePathText = computed(() => materialTypePathText(form.material_type_id))

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

  const visited = new Set<string>()
  const parts: string[] = []
  let current = materialTypeMap.value.get(typeId) ?? null

  while (current && !visited.has(current.type_id)) {
    visited.add(current.type_id)
    parts.unshift(displayMaterialTypeName(current))
    current = current.parent_type_id ? materialTypeMap.value.get(current.parent_type_id) ?? null : null
  }

  return parts.join(' / ')
}

function isExpandableType(typeId: string) {
  return expandableTypeIds.value.has(typeId)
}

function isTypeExpanded(typeId: string) {
  if (typeSearchTerm.value.trim()) return true
  return expandedTypeIds.value.has(typeId)
}

function typeToggleLabel(isExpanded: boolean) {
  const isJa = locale.value.toString().toLowerCase().startsWith('ja')
  if (isJa) return isExpanded ? '折りたたむ' : '展開'
  return isExpanded ? 'Collapse' : 'Expand'
}

function expandTypePath(typeId: string | null | undefined) {
  if (!typeId) return

  const next = new Set(expandedTypeIds.value)
  let current = materialTypeMap.value.get(typeId) ?? null

  while (current?.parent_type_id) {
    next.add(current.parent_type_id)
    current = materialTypeMap.value.get(current.parent_type_id) ?? null
  }

  expandedTypeIds.value = next
}

function syncExpandedTypeState() {
  const next = new Set<string>()

  if (!treeExpansionInitialized.value) {
    expandableTypeIds.value.forEach((typeId) => next.add(typeId))
    expandedTypeIds.value = next
    treeExpansionInitialized.value = true
    return
  }

  expandableTypeIds.value.forEach((typeId) => {
    if (expandedTypeIds.value.has(typeId)) next.add(typeId)
  })

  expandedTypeIds.value = next
}

function uomLabel(uomId: string | null) {
  if (!uomId) return '-'
  const uom = uomMap.value.get(uomId)
  if (!uom) return '-'
  return uom.name ? `${uom.code} - ${uom.name}` : uom.code
}

function formatStatus(value: string | null | undefined) {
  if (!value) return '-'
  if (value === 'active') return t('common.active')
  if (value === 'inactive') return t('common.inactive')
  return value
}

function statusBadgeClass(value: string | null | undefined) {
  if (value === 'active') return 'bg-green-100 text-green-700'
  if (value === 'inactive') return 'bg-gray-200 text-gray-700'
  return 'bg-amber-100 text-amber-700'
}

function clearErrors() {
  Object.keys(errors).forEach((key) => delete errors[key])
}

function ensureTypeSelection() {
  if (selectedTypeId.value && materialTypeMap.value.has(selectedTypeId.value)) {
    expandTypePath(selectedTypeId.value)
    return
  }
  if (rawMaterialRoot.value) {
    selectedTypeId.value = rawMaterialRoot.value.type_id
    expandTypePath(selectedTypeId.value)
    return
  }
  const first = materialTypeForest.value[0]?.row.type_id ?? ''
  selectedTypeId.value = first
  expandTypePath(selectedTypeId.value)
}

function resetFormPane() {
  formMode.value = 'idle'
  selectedMaterialId.value = ''
  Object.assign(form, blankForm())
  clearErrors()
}

function selectType(typeId: string) {
  selectedTypeId.value = typeId
  expandTypePath(typeId)
}

function toggleTypeExpanded(typeId: string) {
  if (!isExpandableType(typeId) || typeSearchTerm.value.trim()) return

  const next = new Set(expandedTypeIds.value)
  if (next.has(typeId)) next.delete(typeId)
  else next.add(typeId)
  expandedTypeIds.value = next
}

function toggleTypePanel() {
  showTypePanel.value = !showTypePanel.value
}

function startCreate() {
  clearErrors()
  selectedMaterialId.value = ''
  formMode.value = 'create'
  Object.assign(form, {
    id: '',
    material_code: '',
    material_name: '',
    material_type_id: selectedTypeId.value,
    base_uom_id: '',
    status: 'active',
  })
}

function selectMaterial(row: MaterialRow) {
  clearErrors()
  selectedMaterialId.value = row.id
  formMode.value = 'edit'
  Object.assign(form, {
    id: row.id,
    material_code: row.material_code,
    material_name: row.material_name,
    material_type_id: row.material_type_id ?? '',
    base_uom_id: row.base_uom_id ?? '',
    status: row.status,
  })

  if (row.material_type_id) {
    selectedTypeId.value = row.material_type_id
    expandTypePath(row.material_type_id)
  }
}

function applySelectedTypeToForm() {
  if (!selectedTypeId.value) return
  form.material_type_id = selectedTypeId.value
  if (errors.material_type_id) delete errors.material_type_id
}

function openDelete(row: MaterialRow) {
  deleteTarget.value = row
  showDelete.value = true
}

function closeDelete() {
  if (deleting.value) return
  showDelete.value = false
  deleteTarget.value = null
}

function validateForm() {
  clearErrors()

  if (!form.material_code.trim()) {
    errors.material_code = t('errors.required', { field: t('material.fields.code') })
  }

  if (!form.material_name.trim()) {
    errors.material_name = t('errors.required', { field: t('material.fields.name') })
  }

  if (!form.material_type_id) {
    errors.material_type_id = t('errors.required', { field: t('material.fields.type') })
  }

  if (!form.base_uom_id) {
    errors.base_uom_id = t('errors.required', { field: t('material.fields.uom') })
  }

  if (!form.status) {
    errors.status = t('errors.required', { field: t('material.fields.status') })
  }

  return Object.keys(errors).length === 0
}

function messageText(error: unknown) {
  if (error instanceof Error) return error.message
  if (typeof error === 'object' && error && 'message' in error && typeof (error as { message?: unknown }).message === 'string') {
    return (error as { message: string }).message
  }
  return String(error)
}

async function loadPage() {
  loading.value = true
  pageError.value = ''

  try {
    const [
      { data: uomData, error: uomError },
      { data: typeData, error: typeError },
      { data: materialData, error: materialError },
    ] = await Promise.all([
      supabase.from('mst_uom').select('id, code, name').order('code', { ascending: true }),
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
        .order('material_code', { ascending: true }),
    ])

    if (uomError) throw uomError
    if (typeError) throw typeError
    if (materialError) throw materialError

    uomOptions.value = (uomData ?? []) as UomRow[]
    materialTypes.value = (typeData ?? []) as MaterialTypeRow[]
    materialRows.value = (materialData ?? []).map((row) => normalizeMaterialRow(row))

    syncExpandedTypeState()
    ensureTypeSelection()

    if (formMode.value === 'edit' && selectedMaterialId.value) {
      const latest = materialRows.value.find((row) => row.id === selectedMaterialId.value)
      if (latest) {
        Object.assign(form, {
          id: latest.id,
          material_code: latest.material_code,
          material_name: latest.material_name,
          material_type_id: latest.material_type_id ?? '',
          base_uom_id: latest.base_uom_id ?? '',
          status: latest.status,
        })
      } else {
        resetFormPane()
      }
    }
  } catch (error) {
    pageError.value = t('material.errors.loadFailed', { message: messageText(error) })
    toast.error(pageError.value)
  } finally {
    loading.value = false
  }
}

async function saveRecord() {
  if (!validateForm()) return

  saving.value = true

  const payload = {
    material_code: form.material_code.trim(),
    material_name: form.material_name.trim(),
    material_type_id: form.material_type_id,
    base_uom_id: form.base_uom_id,
    status: form.status,
  }

  try {
    const response = formMode.value === 'edit'
      ? await mesClient()
          .from('mst_material')
          .update(payload)
          .eq('id', form.id)
          .select('id, material_code, material_name, material_type_id, base_uom_id, status')
          .single()
      : await mesClient()
          .from('mst_material')
          .insert(payload)
          .select('id, material_code, material_name, material_type_id, base_uom_id, status')
          .single()

    if (response.error) {
      if (response.error.code === '23505') {
        errors.material_code = t('material.errors.codeUnique')
        toast.error(errors.material_code)
        return
      }
      throw response.error
    }

    const saved = normalizeMaterialRow(response.data)
    const index = materialRows.value.findIndex((row) => row.id === saved.id)
    if (index === -1) {
      materialRows.value = [...materialRows.value, saved]
    } else {
      const next = materialRows.value.slice()
      next[index] = saved
      materialRows.value = next
    }

    selectedTypeId.value = saved.material_type_id ?? selectedTypeId.value
    selectMaterial(saved)
    toast.success(t('common.saved'))
  } catch (error) {
    toast.error(t('material.errors.saveFailed', { message: messageText(error) }))
  } finally {
    saving.value = false
  }
}

async function deleteRecord() {
  if (!deleteTarget.value) return

  deleting.value = true

  try {
    const { error } = await mesClient().from('mst_material').delete().eq('id', deleteTarget.value.id)
    if (error) throw error

    const deletedId = deleteTarget.value.id
    materialRows.value = materialRows.value.filter((row) => row.id !== deletedId)

    if (selectedMaterialId.value === deletedId) {
      resetFormPane()
    }

    toast.success(t('common.deleted'))
    showDelete.value = false
    deleteTarget.value = null
  } catch (error) {
    toast.error(t('material.errors.deleteFailed', { message: messageText(error) }))
  } finally {
    deleting.value = false
  }
}

onMounted(() => {
  void loadPage()
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
