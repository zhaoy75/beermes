<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="space-y-6">
      <section class="rounded-lg border border-gray-200 bg-white shadow">
        <header class="flex flex-col gap-3 border-b p-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-semibold text-gray-900">{{ pageTitle }}</h2>
            <p class="text-sm text-gray-500">{{ pageSubtitle }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <button class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-100" type="button" @click="goBack">
              {{ t('recipe.itemEditor.back') }}
            </button>
            <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700 disabled:opacity-60" type="button" :disabled="saving" @click="saveEditor">
              {{ saving ? t('common.saving') : t('recipe.itemEditor.saveAndReturn') }}
            </button>
          </div>
        </header>

        <div class="grid grid-cols-1 gap-4 p-4 md:grid-cols-3">
          <div class="rounded-lg border border-gray-200 bg-gray-50 p-4">
            <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">{{ t('recipe.itemEditor.recipeSummary') }}</p>
            <dl class="mt-2 space-y-1 text-sm text-gray-700">
              <div class="flex justify-between gap-3">
                <dt>{{ t('recipe.edit.recipeCode') }}</dt>
                <dd class="font-mono">{{ recipeHeader?.recipe_code || '-' }}</dd>
              </div>
              <div class="flex justify-between gap-3">
                <dt>{{ t('recipe.edit.recipeName') }}</dt>
                <dd>{{ recipeHeader?.recipe_name || '-' }}</dd>
              </div>
              <div class="flex justify-between gap-3">
                <dt>{{ t('recipe.edit.version') }}</dt>
                <dd>{{ activeVersion ? `v${activeVersion.version_no}` : '-' }}</dd>
              </div>
              <div class="flex justify-between gap-3">
                <dt>{{ t('recipe.itemEditor.editorMode') }}</dt>
                <dd>{{ editorModeLabel }}</dd>
              </div>
            </dl>
          </div>
          <div class="rounded-lg border border-gray-200 bg-gray-50 p-4 md:col-span-2">
            <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">{{ t('recipe.itemEditor.routeContext') }}</p>
            <dl class="mt-2 grid grid-cols-1 gap-2 text-sm text-gray-700 md:grid-cols-3">
              <div>
                <dt class="text-xs text-gray-500">{{ t('recipe.edit.group') }}</dt>
                <dd>{{ sectionLabel }}</dd>
              </div>
              <div>
                <dt class="text-xs text-gray-500">{{ t('common.mode') }}</dt>
                <dd>{{ editModeLabel }}</dd>
              </div>
              <div>
                <dt class="text-xs text-gray-500">{{ t('recipe.edit.schemaCode') }}</dt>
                <dd class="font-mono">{{ activeVersion?.schema_code || DEFAULT_SCHEMA_KEY }}</dd>
              </div>
            </dl>
            <p v-if="loadError" class="mt-3 text-sm text-red-600">{{ loadError }}</p>
          </div>
        </div>
      </section>

      <section v-if="loadingPage" class="rounded-lg border border-gray-200 bg-white p-6 text-sm text-gray-500 shadow">
        {{ t('common.loading') }}
      </section>

      <section v-else-if="isMaterialEditor" class="grid grid-cols-1 gap-4 lg:grid-cols-[320px_1fr]">
        <aside class="space-y-4">
          <div class="rounded-lg border border-gray-200 bg-white shadow">
            <div class="border-b px-4 py-3">
              <h3 class="text-sm font-semibold text-gray-900">{{ t('recipe.edit.materialSourceTitle') }}</h3>
              <p class="mt-1 text-xs text-gray-500">{{ t('recipe.edit.materialTypeTreeHint') }}</p>
            </div>
            <div class="max-h-[360px] overflow-y-auto p-2">
              <div v-if="materialTypeTreeEntries.length === 0" class="px-2 py-4 text-sm text-gray-500">{{ t('recipe.edit.materialTypeTreeEmpty') }}</div>
              <ul v-else class="space-y-1">
                <li v-for="entry in materialTypeTreeEntries" :key="entry.node.row.type_id">
                  <button
                    type="button"
                    class="flex w-full items-center rounded px-2 py-2 text-left text-sm hover:bg-gray-50"
                    :class="selectedMaterialTypeId === entry.node.row.type_id ? 'bg-blue-50 text-blue-700 ring-1 ring-blue-200' : 'text-gray-700'"
                    :style="{ paddingLeft: `${12 + entry.depth * 16}px` }"
                    @click="selectMaterialType(entry.node.row.type_id)"
                  >
                    <span class="truncate">{{ displayMaterialTypeName(entry.node.row) }}</span>
                  </button>
                </li>
              </ul>
            </div>
          </div>

          <div class="rounded-lg border border-gray-200 bg-white shadow">
            <div class="border-b px-4 py-3">
              <h3 class="text-sm font-semibold text-gray-900">{{ t('recipe.edit.materialSourceListTitle') }}</h3>
              <p class="mt-1 text-xs text-gray-500">
                {{ selectedMaterialType ? displayMaterialTypeName(selectedMaterialType) : t('recipe.edit.selectMaterialTypePrompt') }}
              </p>
            </div>
            <div class="max-h-[420px] overflow-y-auto p-2">
              <div v-if="filteredMaterialOptions.length === 0" class="px-2 py-4 text-sm text-gray-500">{{ t('recipe.edit.ingredientsFilteredEmpty') }}</div>
              <ul v-else class="space-y-1">
                <li v-for="material in filteredMaterialOptions" :key="material.id">
                  <button
                    type="button"
                    class="w-full rounded border px-3 py-2 text-left hover:bg-gray-50"
                    :class="materialForm.material_id === material.id ? 'border-blue-300 bg-blue-50 text-blue-700' : 'border-transparent text-gray-800'"
                    @click="materialForm.material_id = material.id"
                  >
                    <div class="font-medium">{{ material.material_name }}</div>
                    <div class="font-mono text-xs text-gray-500">{{ material.material_code }}</div>
                  </button>
                </li>
              </ul>
            </div>
          </div>
        </aside>

        <div class="space-y-4">
          <div class="rounded-lg border border-gray-200 bg-white shadow">
            <div class="border-b px-4 py-3">
              <h3 class="text-sm font-semibold text-gray-900">{{ t('recipe.edit.materialEditorTitle') }}</h3>
              <p class="mt-1 text-xs text-gray-500">{{ t('recipe.itemEditor.materialPageHint') }}</p>
            </div>
            <div class="grid grid-cols-1 gap-4 p-4 md:grid-cols-2">
              <div class="md:col-span-2 rounded-lg border border-dashed border-gray-300 bg-gray-50 px-3 py-3">
                <div class="text-xs text-gray-500">{{ t('recipe.edit.materialColumn') }}</div>
                <div v-if="displayedMaterialOption" class="mt-1">
                  <div class="font-medium text-gray-900">{{ displayedMaterialOption.material_name }}</div>
                  <div class="font-mono text-xs text-gray-500">{{ displayedMaterialOption.material_code }}</div>
                </div>
                <div v-else class="mt-1 text-sm text-gray-500">{{ t('recipe.edit.selectMaterialSourcePrompt') }}</div>
                <p v-if="materialErrors.material_id" class="mt-2 text-xs text-red-600">{{ materialErrors.material_id }}</p>
              </div>

              <div>
                <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.group') }}</label>
                <select v-model="materialForm.section" class="h-[40px] w-full rounded border bg-white px-3">
                  <option value="required">{{ t('recipe.materialSections.required') }}</option>
                  <option value="optional">{{ t('recipe.materialSections.optional') }}</option>
                </select>
              </div>
              <div>
                <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.materialTypeFilter') }}</label>
                <div class="flex h-[40px] items-center rounded border bg-gray-50 px-3 text-sm text-gray-700">
                  {{ selectedMaterialType ? displayMaterialTypeName(selectedMaterialType) : t('recipe.edit.selectMaterialTypePrompt') }}
                </div>
              </div>
              <div>
                <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.materialRole') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="materialForm.material_role" class="h-[40px] w-full rounded border px-3" />
                <p v-if="materialErrors.material_role" class="mt-1 text-xs text-red-600">{{ materialErrors.material_role }}</p>
              </div>
              <div>
                <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.quantity') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="materialForm.qty" type="number" min="0" step="0.001" class="h-[40px] w-full rounded border px-3" />
                <p v-if="materialErrors.qty" class="mt-1 text-xs text-red-600">{{ materialErrors.qty }}</p>
              </div>
              <div>
                <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.uomCode') }}<span class="text-red-600">*</span></label>
                <select v-model="materialForm.uom_code" class="h-[40px] w-full rounded border bg-white px-3">
                  <option value="">{{ t('recipe.edit.selectUom') }}</option>
                  <option v-for="uom in uoms" :key="uom.id" :value="uom.code">{{ uom.code }} — {{ uom.name || uom.code }}</option>
                </select>
                <p v-if="materialErrors.uom_code" class="mt-1 text-xs text-red-600">{{ materialErrors.uom_code }}</p>
              </div>
              <div>
                <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.basis') }}</label>
                <select v-model="materialForm.basis" class="h-[40px] w-full rounded border bg-white px-3">
                  <option value="per_base">{{ t('recipe.basis.perBase') }}</option>
                  <option value="percent_of_base">{{ t('recipe.basis.percentOfBase') }}</option>
                  <option value="fixed_per_batch">{{ t('recipe.basis.fixedPerBatch') }}</option>
                  <option value="by_formula">{{ t('recipe.basis.byFormula') }}</option>
                </select>
              </div>
              <div class="md:col-span-2">
                <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.notes') }}</label>
                <textarea v-model.trim="materialForm.notes" rows="3" class="w-full rounded border px-3 py-2"></textarea>
              </div>
            </div>
          </div>

          <div class="rounded-lg border border-gray-200 bg-white shadow">
            <div class="border-b px-4 py-3">
              <h3 class="text-sm font-semibold text-gray-900">{{ t('recipe.edit.materialAttributeTitle') }}</h3>
              <p class="mt-1 text-xs text-gray-500">{{ t('recipe.edit.materialAttributeSubtitle') }}</p>
            </div>
            <div v-if="materialAttrLoading" class="px-4 py-6 text-sm text-gray-500">{{ t('common.loading') }}</div>
            <div v-else-if="!selectedMaterialType" class="px-4 py-6 text-sm text-gray-500">{{ t('recipe.edit.selectMaterialTypePrompt') }}</div>
            <div v-else-if="materialAttrFields.length === 0" class="px-4 py-6 text-sm text-gray-500">{{ t('recipe.edit.materialAttributeEmpty') }}</div>
            <div v-else class="space-y-4 p-4">
              <section v-for="group in materialAttrSections" :key="group.section" class="space-y-3">
                <div>
                  <h4 class="text-sm font-medium text-gray-900">{{ group.section }}</h4>
                </div>
                <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
                  <div v-for="field in group.fields" :key="field.code" :class="materialAttrInputKind(field) === 'json' ? 'md:col-span-2' : ''">
                    <label class="mb-1 block text-sm text-gray-600">
                      {{ materialAttrLabel(field) }}
                      <span v-if="field.required" class="text-red-600">*</span>
                      <span v-if="field.uom_code" class="ml-1 text-xs text-gray-400">({{ field.uom_code }})</span>
                    </label>

                    <input
                      v-if="materialAttrInputKind(field) === 'text'"
                      :value="materialAttrTextValue(field)"
                      class="h-[40px] w-full rounded border px-3"
                      @input="updateMaterialAttrText(field, $event)"
                    />

                    <input
                      v-else-if="materialAttrInputKind(field) === 'number'"
                      :value="materialAttrTextValue(field)"
                      type="number"
                      :min="field.num_min ?? undefined"
                      :max="field.num_max ?? undefined"
                      step="any"
                      class="h-[40px] w-full rounded border px-3"
                      @input="updateMaterialAttrText(field, $event)"
                    />

                    <select
                      v-else-if="materialAttrInputKind(field) === 'select'"
                      :value="materialAttrTextValue(field)"
                      class="h-[40px] w-full rounded border bg-white px-3"
                      @change="updateMaterialAttrText(field, $event)"
                    >
                      <option value="">{{ t('common.select') }}</option>
                      <option v-for="option in materialAttrAllowedOptions(field)" :key="option.value" :value="option.value">
                        {{ option.label }}
                      </option>
                    </select>

                    <label v-else-if="materialAttrInputKind(field) === 'boolean'" class="inline-flex h-[40px] items-center gap-2">
                      <input :checked="Boolean(field.value)" type="checkbox" class="h-4 w-4" @change="updateMaterialAttrBoolean(field, $event)" />
                      <span class="text-sm text-gray-700">{{ t('common.yes') }}</span>
                    </label>

                    <textarea
                      v-else-if="materialAttrInputKind(field) === 'json'"
                      :value="materialAttrTextValue(field)"
                      rows="4"
                      class="w-full rounded border px-3 py-2 font-mono text-xs"
                      @input="updateMaterialAttrText(field, $event)"
                    />

                    <input
                      v-else
                      :value="materialAttrTextValue(field)"
                      class="h-[40px] w-full rounded border px-3"
                      @input="updateMaterialAttrText(field, $event)"
                    />

                    <p v-if="field.help_text" class="mt-1 text-xs text-gray-500">{{ field.help_text }}</p>
                    <p v-else-if="field.description" class="mt-1 text-xs text-gray-500">{{ field.description }}</p>
                    <p v-if="field.error" class="mt-1 text-xs text-red-600">{{ field.error }}</p>
                  </div>
                </div>
              </section>
            </div>
          </div>

          <div class="flex items-center justify-end gap-2">
            <button class="rounded border px-3 py-2 hover:bg-gray-100" type="button" @click="goBack">{{ t('common.cancel') }}</button>
            <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700 disabled:opacity-60" type="button" :disabled="saving" @click="saveEditor">
              {{ saving ? t('common.saving') : t('recipe.itemEditor.saveAndReturn') }}
            </button>
          </div>
        </div>
      </section>

      <section v-else class="rounded-lg border border-gray-200 bg-white shadow">
        <div class="border-b px-4 py-3">
          <h3 class="text-sm font-semibold text-gray-900">{{ t('recipe.itemEditor.outputPageTitle') }}</h3>
          <p class="mt-1 text-xs text-gray-500">{{ t('recipe.itemEditor.outputPageHint') }}</p>
        </div>
        <div class="grid grid-cols-1 gap-4 p-4 md:grid-cols-2">
          <div>
            <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.outputCategory') }}</label>
            <select v-model="outputForm.section" class="h-[40px] w-full rounded border bg-white px-3">
              <option value="primary">{{ t('recipe.edit.primaryOutputs') }}</option>
              <option value="co_products">{{ t('recipe.edit.coProductOutputs') }}</option>
              <option value="waste">{{ t('recipe.edit.wasteOutputs') }}</option>
            </select>
          </div>
          <div>
            <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.outputType') }}</label>
            <select v-model="outputForm.output_type" class="h-[40px] w-full rounded border bg-white px-3">
              <option value="primary">{{ t('recipe.edit.outputTypePrimary') }}</option>
              <option value="intermediate">{{ t('recipe.edit.outputTypeIntermediate') }}</option>
              <option value="co_product">{{ t('recipe.edit.outputTypeCoProduct') }}</option>
              <option value="waste">{{ t('recipe.edit.outputTypeWaste') }}</option>
            </select>
          </div>
          <div>
            <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.outputCode') }}<span class="text-red-600">*</span></label>
            <input v-model.trim="outputForm.output_code" class="h-[40px] w-full rounded border px-3 font-mono text-sm" />
            <p v-if="outputErrors.output_code" class="mt-1 text-xs text-red-600">{{ outputErrors.output_code }}</p>
          </div>
          <div>
            <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.outputName') }}<span class="text-red-600">*</span></label>
            <input v-model.trim="outputForm.output_name" class="h-[40px] w-full rounded border px-3" />
            <p v-if="outputErrors.output_name" class="mt-1 text-xs text-red-600">{{ outputErrors.output_name }}</p>
          </div>
          <div>
            <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.quantity') }}<span class="text-red-600">*</span></label>
            <input v-model.trim="outputForm.qty" type="number" min="0" step="0.001" class="h-[40px] w-full rounded border px-3" />
            <p v-if="outputErrors.qty" class="mt-1 text-xs text-red-600">{{ outputErrors.qty }}</p>
          </div>
          <div>
            <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.uomCode') }}<span class="text-red-600">*</span></label>
            <select v-model="outputForm.uom_code" class="h-[40px] w-full rounded border bg-white px-3">
              <option value="">{{ t('recipe.edit.selectUom') }}</option>
              <option v-for="uom in uoms" :key="uom.id" :value="uom.code">{{ uom.code }} — {{ uom.name || uom.code }}</option>
            </select>
            <p v-if="outputErrors.uom_code" class="mt-1 text-xs text-red-600">{{ outputErrors.uom_code }}</p>
          </div>
          <div>
            <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.basis') }}</label>
            <select v-model="outputForm.basis" class="h-[40px] w-full rounded border bg-white px-3">
              <option value="per_base">{{ t('recipe.basis.perBase') }}</option>
              <option value="fixed_per_batch">{{ t('recipe.edit.outputBasisFixedPerBatch') }}</option>
              <option value="yield_based">{{ t('recipe.edit.outputBasisYieldBased') }}</option>
            </select>
          </div>
          <div class="md:col-span-2">
            <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.notes') }}</label>
            <textarea v-model.trim="outputForm.notes" rows="3" class="w-full rounded border px-3 py-2"></textarea>
          </div>
        </div>
        <div class="flex items-center justify-end gap-2 border-t px-4 py-3">
          <button class="rounded border px-3 py-2 hover:bg-gray-100" type="button" @click="goBack">{{ t('common.cancel') }}</button>
          <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700 disabled:opacity-60" type="button" :disabled="saving" @click="saveEditor">
            {{ saving ? t('common.saving') : t('recipe.itemEditor.saveAndReturn') }}
          </button>
        </div>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import { normalizeBatchAttrDataType, validateBatchAttrField } from '@/lib/batchAttrValidation'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

const DEFAULT_SCHEMA_KEY = 'recipe_body_v1'

type JsonObject = Record<string, unknown>
type MaterialSection = 'required' | 'optional'
type OutputSection = 'primary' | 'co_products' | 'waste'
type EditorKind = 'material' | 'output'

interface RecipeHeaderRow {
  id: string
  recipe_code: string
  recipe_name: string
  industry_type: string | null
}

interface RecipeVersionRow {
  id: string
  recipe_id: string
  version_no: number
  schema_code: string | null
  recipe_body_json: unknown
}

interface MaterialTypeRow {
  type_id: string
  code: string
  name: string
  name_i18n?: {
    ja?: string
    en?: string
  } | null
  parent_type_id: string | null
  sort_order?: number | null
}

interface MaterialMasterRow {
  id: string
  material_code: string
  material_name: string
  material_type_id: string | null
  base_uom_id: string | null
}

interface UomRow {
  id: string
  code: string
  name: string | null
}

interface RecipeMaterialRequirement {
  material_key: string
  material_name?: string
  material_role: string
  material_type_code?: string
  material_code?: string
  qty: number
  uom_code: string
  basis?: string
  is_optional?: boolean
  attr_values?: JsonObject
  notes?: string
}

interface RecipeOutputSpec {
  output_code: string
  output_name: string
  output_type: string
  qty: number
  uom_code: string
  basis?: string
  notes?: string
}

interface RecipeBody {
  schema_version: string
  recipe_info: JsonObject
  base: JsonObject
  outputs: {
    primary: RecipeOutputSpec[]
    co_products: RecipeOutputSpec[]
    waste: RecipeOutputSpec[]
  }
  materials: {
    required: RecipeMaterialRequirement[]
    optional: RecipeMaterialRequirement[]
  }
  flow: JsonObject
  quality: JsonObject
  documents: unknown[]
  [key: string]: unknown
}

interface MaterialAttrDefRow {
  attr_id: number
  code: string
  name: string
  name_i18n?: {
    ja?: string
    en?: string
  } | null
  data_type: string
  description?: string | null
  is_active?: boolean
  required?: boolean
  uom_id?: string | null
  num_min?: number | null
  num_max?: number | null
  text_regex?: string | null
  allowed_values?: unknown | null
  ref_kind?: string | null
  ref_domain?: string | null
}

interface MaterialAttrRuleRow {
  attr_set_id: number
  attr_id: number
  required: boolean
  sort_order: number
  is_active: boolean
  ui_section?: string | null
  ui_widget?: string | null
  help_text?: string | null
  attr_def: MaterialAttrDefRow | MaterialAttrDefRow[] | null
}

interface MaterialAttrField {
  attr_id: number
  code: string
  name: string
  name_i18n?: {
    ja?: string
    en?: string
  } | null
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
  error: string
}

interface MaterialTreeNode {
  row: MaterialTypeRow
  children: MaterialTreeNode[]
}

interface MaterialTreeEntry {
  node: MaterialTreeNode
  depth: number
}

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()

const recipeHeader = ref<RecipeHeaderRow | null>(null)
const activeVersion = ref<RecipeVersionRow | null>(null)
const recipeBody = ref<RecipeBody>(createDefaultRecipeBody(DEFAULT_SCHEMA_KEY, ''))
const loadingPage = ref(false)
const saving = ref(false)
const loadError = ref('')

const materialTypes = ref<MaterialTypeRow[]>([])
const materialOptions = ref<MaterialMasterRow[]>([])
const uoms = ref<UomRow[]>([])

const selectedMaterialTypeId = ref('')
const materialAttrLoading = ref(false)
const materialAttrFields = ref<MaterialAttrField[]>([])
const materialAttrValueSeed = ref<JsonObject | null>(null)
const materialOriginalSection = ref<MaterialSection | null>(null)
const materialEditIndex = ref<number | null>(null)
const materialOriginalRequirement = ref<RecipeMaterialRequirement | null>(null)
const materialForm = reactive({
  section: 'required' as MaterialSection,
  material_type_code: '',
  material_id: '',
  material_role: '',
  qty: '',
  uom_code: '',
  basis: 'per_base',
  notes: '',
})
const materialErrors = reactive<Record<string, string>>({})

const outputOriginalSection = ref<OutputSection | null>(null)
const outputEditIndex = ref<number | null>(null)
const outputForm = reactive({
  section: 'primary' as OutputSection,
  output_code: '',
  output_name: '',
  output_type: 'primary',
  qty: '',
  uom_code: '',
  basis: 'per_base',
  notes: '',
})
const outputErrors = reactive<Record<string, string>>({})

const recipeId = computed(() => (typeof route.params.recipeId === 'string' ? route.params.recipeId : ''))
const versionId = computed(() => (typeof route.params.versionId === 'string' ? route.params.versionId : ''))
const editorKind = computed<EditorKind | ''>(() => {
  const value = typeof route.params.kind === 'string' ? route.params.kind : ''
  return value === 'material' || value === 'output' ? value : ''
})
const routeSection = computed(() => (typeof route.params.section === 'string' ? route.params.section : ''))
const routeIndex = computed<number | null>(() => {
  if (typeof route.params.index !== 'string') return null
  const parsed = Number(route.params.index)
  return Number.isInteger(parsed) && parsed >= 0 ? parsed : null
})

const isMaterialEditor = computed(() => editorKind.value === 'material')
const pageTitle = computed(() => {
  if (editorKind.value === 'material') {
    return materialEditIndex.value === null ? t('recipe.itemEditor.materialCreateTitle') : t('recipe.itemEditor.materialEditTitle')
  }
  if (editorKind.value === 'output') {
    return outputEditIndex.value === null ? t('recipe.itemEditor.outputCreateTitle') : t('recipe.itemEditor.outputEditTitle')
  }
  return t('recipe.itemEditor.invalidTitle')
})
const pageSubtitle = computed(() => (
  isMaterialEditor.value ? t('recipe.itemEditor.materialPageHint') : t('recipe.itemEditor.outputPageHint')
))
const editorModeLabel = computed(() => (
  isMaterialEditor.value ? t('recipe.itemEditor.modeMaterial') : t('recipe.itemEditor.modeOutput')
))
const editModeLabel = computed(() => (
  (isMaterialEditor.value ? materialEditIndex.value : outputEditIndex.value) === null
    ? t('recipe.itemEditor.modeCreate')
    : t('recipe.itemEditor.modeEdit')
))
const sectionLabel = computed(() => {
  if (editorKind.value === 'material') return formatMaterialSection(materialForm.section)
  if (editorKind.value === 'output') return formatOutputSection(outputForm.section)
  return '-'
})

const mesClient = () => supabase.schema('mes')

const materialTypeMap = computed(() => {
  const map = new Map<string, MaterialTypeRow>()
  materialTypes.value.forEach((row) => map.set(row.type_id, row))
  return map
})

const materialTypeCodeMap = computed(() => {
  const map = new Map<string, MaterialTypeRow>()
  materialTypes.value.forEach((row) => map.set(row.code, row))
  return map
})

const materialMasterMap = computed(() => {
  const map = new Map<string, MaterialMasterRow>()
  materialOptions.value.forEach((row) => map.set(row.id, row))
  return map
})

const rawMaterialRoot = computed(() => materialTypes.value.find((row) => row.code === 'RAW_MATERIAL') ?? null)

const rawMaterialTree = computed(() => {
  if (!rawMaterialRoot.value) return null
  const childrenByParent = new Map<string | null, MaterialTypeRow[]>()
  for (const row of materialTypes.value) {
    const key = row.parent_type_id ?? null
    const list = childrenByParent.get(key) ?? []
    list.push(row)
    childrenByParent.set(key, list)
  }

  const sortRows = (rows: MaterialTypeRow[]) =>
    rows.slice().sort((a, b) => {
      const sortDiff = (a.sort_order ?? 0) - (b.sort_order ?? 0)
      if (sortDiff !== 0) return sortDiff
      return a.code.localeCompare(b.code)
    })

  const buildNode = (row: MaterialTypeRow): MaterialTreeNode => ({
    row,
    children: sortRows(childrenByParent.get(row.type_id) ?? []).map((child) => buildNode(child)),
  })

  return buildNode(rawMaterialRoot.value)
})

const materialTypeTreeEntries = computed<MaterialTreeEntry[]>(() => {
  const root = rawMaterialTree.value
  if (!root) return []
  const entries: MaterialTreeEntry[] = []
  const visit = (node: MaterialTreeNode, depth: number) => {
    entries.push({ node, depth })
    node.children.forEach((child) => visit(child, depth + 1))
  }
  visit(root, 0)
  return entries
})

const selectedMaterialType = computed(() => (
  selectedMaterialTypeId.value ? materialTypeMap.value.get(selectedMaterialTypeId.value) ?? null : null
))

const selectedMaterialTypeFilterIds = computed(() => {
  const selectedId = selectedMaterialTypeId.value || rawMaterialRoot.value?.type_id || ''
  if (!selectedId) return new Set<string>()

  const root = materialTypeMap.value.get(selectedId)
  if (!root) return new Set<string>()

  const ids = new Set<string>()
  const walk = (typeId: string) => {
    ids.add(typeId)
    for (const row of materialTypes.value) {
      if (row.parent_type_id === typeId) walk(row.type_id)
    }
  }
  walk(root.type_id)
  return ids
})

const selectedMaterialOption = computed(() => (
  materialForm.material_id ? materialMasterMap.value.get(materialForm.material_id) ?? null : null
))

const displayedMaterialOption = computed(() => {
  if (selectedMaterialOption.value) {
    return {
      material_name: selectedMaterialOption.value.material_name,
      material_code: selectedMaterialOption.value.material_code,
    }
  }

  if (materialOriginalRequirement.value) {
    return {
      material_name: materialOriginalRequirement.value.material_name || materialOriginalRequirement.value.material_code || materialOriginalRequirement.value.material_key,
      material_code: materialOriginalRequirement.value.material_code || materialOriginalRequirement.value.material_key,
    }
  }

  return null
})

const filteredMaterialOptions = computed(() => {
  if (selectedMaterialTypeFilterIds.value.size === 0) return materialOptions.value
  return materialOptions.value.filter((row) => row.material_type_id && selectedMaterialTypeFilterIds.value.has(row.material_type_id))
})

const materialAttrSections = computed(() => {
  const groups = new Map<string, MaterialAttrField[]>()
  for (const field of materialAttrFields.value) {
    const key = field.ui_section || t('recipe.edit.materialAttributeDefaultSection')
    const list = groups.get(key) ?? []
    list.push(field)
    groups.set(key, list)
  }
  return Array.from(groups.entries()).map(([section, fields]) => ({ section, fields }))
})

const ATTRIBUTES_OPTIONAL_IN_RECIPE_EDITOR = true

function isJsonObject(value: unknown): value is JsonObject {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value)
}

function deepCloneJson<T>(value: T): T {
  return JSON.parse(JSON.stringify(value)) as T
}

function createDefaultRecipeBody(schemaCode: string, industryType: string): RecipeBody {
  return {
    schema_version: schemaCode === DEFAULT_SCHEMA_KEY ? 'recipe_body_v1' : 'recipe_body_v1',
    recipe_info: {
      recipe_type: 'process_manufacturing',
      industry_type: industryType || '',
      notes: '',
    },
    base: {
      quantity: 1,
      uom_code: 'PCS',
    },
    outputs: {
      primary: [],
      co_products: [],
      waste: [],
    },
    materials: {
      required: [],
      optional: [],
    },
    flow: {
      steps: [],
    },
    quality: {
      global_checks: [],
      release_criteria: {},
    },
    documents: [],
  }
}

function normalizeOutputSpec(value: unknown): RecipeOutputSpec | null {
  if (!isJsonObject(value)) return null
  const outputCode = typeof value.output_code === 'string' ? value.output_code : ''
  const outputName = typeof value.output_name === 'string' ? value.output_name : ''
  const outputType = typeof value.output_type === 'string' ? value.output_type : ''
  const qty = typeof value.qty === 'number' ? value.qty : Number(value.qty)
  const uomCode = typeof value.uom_code === 'string' ? value.uom_code : ''
  if (!outputCode || !outputName || !outputType || !Number.isFinite(qty) || !uomCode) return null
  return {
    output_code: outputCode,
    output_name: outputName,
    output_type: outputType,
    qty,
    uom_code: uomCode,
    basis: typeof value.basis === 'string' ? value.basis : undefined,
    notes: typeof value.notes === 'string' ? value.notes : undefined,
  }
}

function normalizeMaterialRequirement(value: unknown): RecipeMaterialRequirement | null {
  if (!isJsonObject(value)) return null
  const materialKey = typeof value.material_key === 'string' ? value.material_key : ''
  const materialRole = typeof value.material_role === 'string' ? value.material_role : ''
  const qty = typeof value.qty === 'number' ? value.qty : Number(value.qty)
  const uomCode = typeof value.uom_code === 'string' ? value.uom_code : ''
  if (!materialKey || !materialRole || !Number.isFinite(qty) || !uomCode) return null
  return {
    material_key: materialKey,
    material_name: typeof value.material_name === 'string' ? value.material_name : undefined,
    material_role: materialRole,
    material_type_code: typeof value.material_type_code === 'string' ? value.material_type_code : undefined,
    material_code: typeof value.material_code === 'string' ? value.material_code : undefined,
    qty,
    uom_code: uomCode,
    basis: typeof value.basis === 'string' ? value.basis : undefined,
    is_optional: typeof value.is_optional === 'boolean' ? value.is_optional : undefined,
    attr_values: isJsonObject(value.attr_values) ? deepCloneJson(value.attr_values) : undefined,
    notes: typeof value.notes === 'string' ? value.notes : undefined,
  }
}

function normalizeRecipeBody(raw: unknown, industryType: string, schemaCode: string): RecipeBody {
  const base = isJsonObject(raw) ? raw : {}
  const normalized = createDefaultRecipeBody(schemaCode, industryType)

  const outputs = isJsonObject(base.outputs) ? base.outputs : {}
  const materials = isJsonObject(base.materials) ? base.materials : {}

  return {
    ...deepCloneJson(base),
    schema_version: typeof base.schema_version === 'string' ? base.schema_version : normalized.schema_version,
    recipe_info: isJsonObject(base.recipe_info) ? deepCloneJson(base.recipe_info) : normalized.recipe_info,
    base: isJsonObject(base.base) ? deepCloneJson(base.base) : normalized.base,
    outputs: {
      primary: Array.isArray(outputs.primary)
        ? outputs.primary.map(normalizeOutputSpec).filter((item): item is RecipeOutputSpec => Boolean(item))
        : [],
      co_products: Array.isArray(outputs.co_products)
        ? outputs.co_products.map(normalizeOutputSpec).filter((item): item is RecipeOutputSpec => Boolean(item))
        : [],
      waste: Array.isArray(outputs.waste)
        ? outputs.waste.map(normalizeOutputSpec).filter((item): item is RecipeOutputSpec => Boolean(item))
        : [],
    },
    materials: {
      required: Array.isArray(materials.required)
        ? materials.required.map(normalizeMaterialRequirement).filter((item): item is RecipeMaterialRequirement => Boolean(item))
        : [],
      optional: Array.isArray(materials.optional)
        ? materials.optional.map(normalizeMaterialRequirement).filter((item): item is RecipeMaterialRequirement => Boolean(item))
        : [],
    },
    flow: isJsonObject(base.flow) ? deepCloneJson(base.flow) : normalized.flow,
    quality: isJsonObject(base.quality) ? deepCloneJson(base.quality) : normalized.quality,
    documents: Array.isArray(base.documents) ? deepCloneJson(base.documents) : normalized.documents,
  }
}

function displayMaterialTypeName(row: Pick<MaterialTypeRow, 'name' | 'code' | 'name_i18n'> | null) {
  if (!row) return ''
  const isJa = locale.value.toString().toLowerCase().startsWith('ja')
  const ja = row.name_i18n?.ja?.trim()
  const en = row.name_i18n?.en?.trim()
  if (isJa) return ja || row.name || en || row.code
  return en || row.name || ja || row.code
}

function formatMaterialSection(value: MaterialSection) {
  return t(`recipe.materialSections.${value}`)
}

function formatOutputSection(value: OutputSection) {
  if (value === 'primary') return t('recipe.edit.primaryOutputs')
  if (value === 'co_products') return t('recipe.edit.coProductOutputs')
  return t('recipe.edit.wasteOutputs')
}

async function loadReferenceData() {
  const [{ data: uomData, error: uomError }] = await Promise.all([
    supabase.from('mst_uom').select('id, code, name').order('code', { ascending: true }),
  ])

  if (uomError) throw uomError
  uoms.value = (uomData ?? []) as UomRow[]

  if (!isMaterialEditor.value) {
    materialTypes.value = []
    materialOptions.value = []
    return
  }

  const [
    { data: materialData, error: materialError },
    { data: materialTypeData, error: materialTypeError },
  ] = await Promise.all([
    mesClient()
      .from('mst_material')
      .select('id, material_code, material_name, material_type_id, base_uom_id, status')
      .eq('status', 'active')
      .order('material_code', { ascending: true }),
    supabase
      .from('type_def')
      .select('type_id, code, name, name_i18n, parent_type_id, sort_order')
      .eq('domain', 'material_type')
      .eq('is_active', true)
      .order('sort_order', { ascending: true }),
  ])

  if (materialError) throw materialError
  if (materialTypeError) throw materialTypeError

  materialOptions.value = (materialData ?? []) as MaterialMasterRow[]
  materialTypes.value = (materialTypeData ?? []) as MaterialTypeRow[]
}

async function loadRecipeContext() {
  const { data: headerData, error: headerError } = await mesClient()
    .from('mst_recipe')
    .select('id, recipe_code, recipe_name, industry_type')
    .eq('id', recipeId.value)
    .single()
  if (headerError || !headerData) throw headerError ?? new Error(t('recipe.itemEditor.loadFailed'))

  const { data: versionData, error: versionError } = await mesClient()
    .from('mst_recipe_version')
    .select('id, recipe_id, version_no, schema_code, recipe_body_json')
    .eq('id', versionId.value)
    .eq('recipe_id', recipeId.value)
    .single()
  if (versionError || !versionData) throw versionError ?? new Error(t('recipe.itemEditor.loadFailed'))

  recipeHeader.value = headerData as RecipeHeaderRow
  activeVersion.value = versionData as RecipeVersionRow
  recipeBody.value = normalizeRecipeBody(versionData.recipe_body_json, headerData.industry_type ?? '', versionData.schema_code || DEFAULT_SCHEMA_KEY)
}

function ensureMaterialTypeSelection() {
  if (selectedMaterialTypeId.value) return
  if (rawMaterialRoot.value) {
    selectedMaterialTypeId.value = rawMaterialRoot.value.type_id
    return
  }
  if (materialTypes.value.length > 0) {
    selectedMaterialTypeId.value = materialTypes.value[0].type_id
  }
}

function resetMaterialErrors() {
  Object.keys(materialErrors).forEach((key) => delete materialErrors[key])
  materialAttrFields.value.forEach((field) => {
    field.error = ''
  })
}

function resetOutputErrors() {
  Object.keys(outputErrors).forEach((key) => delete outputErrors[key])
}

function findMaterialIdForRequirement(item: RecipeMaterialRequirement) {
  const exact = materialOptions.value.find((row) => row.material_code === item.material_code)
  if (exact) return exact.id
  const fallback = materialOptions.value.find((row) => row.material_code === item.material_key)
  return fallback?.id ?? ''
}

function initializeMaterialEditor() {
  resetMaterialErrors()
  materialOriginalSection.value = null
  materialEditIndex.value = routeIndex.value
  materialForm.section = routeSection.value === 'optional' ? 'optional' : 'required'
  materialForm.material_type_code = ''
  materialForm.material_id = ''
  materialForm.material_role = ''
  materialForm.qty = ''
  materialForm.uom_code = ''
  materialForm.basis = 'per_base'
  materialForm.notes = ''
  selectedMaterialTypeId.value = ''
  materialAttrFields.value = []
  materialAttrValueSeed.value = {}
  materialOriginalRequirement.value = null

  if (routeIndex.value === null) {
    ensureMaterialTypeSelection()
    return
  }

  const section = routeSection.value === 'optional' ? 'optional' : 'required'
  const item = recipeBody.value.materials[section][routeIndex.value]
  if (!item) throw new Error(t('recipe.itemEditor.targetNotFound'))

  materialOriginalSection.value = section
  materialOriginalRequirement.value = deepCloneJson(item)
  materialForm.section = section
  materialForm.material_id = findMaterialIdForRequirement(item)
  const selectedMaterial = materialForm.material_id ? materialMasterMap.value.get(materialForm.material_id) : null
  const selectedType = selectedMaterial?.material_type_id ? materialTypeMap.value.get(selectedMaterial.material_type_id) : undefined
  const fallbackType = item.material_type_code ? materialTypeCodeMap.value.get(item.material_type_code) : null
  materialAttrValueSeed.value = item.attr_values ? deepCloneJson(item.attr_values) : {}
  selectedMaterialTypeId.value = selectedType?.type_id || fallbackType?.type_id || ''
  materialForm.material_type_code = item.material_type_code || selectedType?.code || fallbackType?.code || ''
  materialForm.material_role = item.material_role
  materialForm.qty = String(item.qty)
  materialForm.uom_code = item.uom_code
  materialForm.basis = item.basis || 'per_base'
  materialForm.notes = item.notes || ''
  ensureMaterialTypeSelection()
}

function initializeOutputEditor() {
  resetOutputErrors()
  outputOriginalSection.value = null
  outputEditIndex.value = routeIndex.value
  outputForm.section = routeSection.value === 'co_products' || routeSection.value === 'waste' ? routeSection.value : 'primary'
  outputForm.output_code = ''
  outputForm.output_name = ''
  outputForm.output_type = outputForm.section === 'co_products' ? 'co_product' : outputForm.section === 'waste' ? 'waste' : 'primary'
  outputForm.qty = ''
  outputForm.uom_code = ''
  outputForm.basis = 'per_base'
  outputForm.notes = ''

  if (routeIndex.value === null) return

  const section = outputForm.section
  const item = recipeBody.value.outputs[section][routeIndex.value]
  if (!item) throw new Error(t('recipe.itemEditor.targetNotFound'))

  outputOriginalSection.value = section
  outputForm.output_code = item.output_code
  outputForm.output_name = item.output_name
  outputForm.output_type = item.output_type
  outputForm.qty = String(item.qty)
  outputForm.uom_code = item.uom_code
  outputForm.basis = item.basis || 'per_base'
  outputForm.notes = item.notes || ''
}

async function initializePage() {
  if (!recipeId.value || !versionId.value || !editorKind.value) {
    loadError.value = t('recipe.itemEditor.invalidRoute')
    return
  }

  loadingPage.value = true
  loadError.value = ''

  try {
    await loadReferenceData()
    await loadRecipeContext()
    if (isMaterialEditor.value) {
      initializeMaterialEditor()
    } else {
      initializeOutputEditor()
    }
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error)
    loadError.value = message
    toast.error(message)
  } finally {
    loadingPage.value = false
  }
}

function selectMaterialType(typeId: string) {
  selectedMaterialTypeId.value = typeId
}

function materialAttrLabel(field: MaterialAttrField) {
  const isJa = locale.value.toString().toLowerCase().startsWith('ja')
  const ja = field.name_i18n?.ja?.trim()
  const en = field.name_i18n?.en?.trim()
  if (isJa) return ja || field.name || en || field.code
  return en || field.name || ja || field.code
}

function materialAttrInputKind(field: MaterialAttrField) {
  const dataType = normalizeBatchAttrDataType(field.data_type)
  if (dataType === 'number') return 'number'
  if (dataType === 'bool') return 'boolean'
  if (dataType === 'json') return 'json'
  if (dataType === 'text') {
    const options = materialAttrAllowedOptions(field)
    if (options.length > 0 || field.ui_widget === 'select') return 'select'
    return 'text'
  }
  return 'text'
}

function materialAttrAllowedOptions(field: MaterialAttrField) {
  if (Array.isArray(field.allowed_values)) {
    return field.allowed_values
      .map((entry) => String(entry ?? '').trim())
      .filter(Boolean)
      .map((value) => ({ value, label: value }))
  }
  if (!field.allowed_values || typeof field.allowed_values !== 'object') return []
  return Object.entries(field.allowed_values as Record<string, unknown>)
    .map(([key, value]) => {
      const normalizedKey = key.trim()
      const normalizedLabel = String(value ?? key).trim()
      if (!normalizedKey) return null
      return { value: normalizedKey, label: normalizedLabel || normalizedKey }
    })
    .filter((entry): entry is { value: string, label: string } => Boolean(entry))
}

function materialAttrTextValue(field: MaterialAttrField) {
  return typeof field.value === 'string' ? field.value : ''
}

function updateMaterialAttrText(field: MaterialAttrField, event: Event) {
  const target = event.target as HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement | null
  field.value = target?.value ?? ''
}

function updateMaterialAttrBoolean(field: MaterialAttrField, event: Event) {
  const target = event.target as HTMLInputElement | null
  field.value = Boolean(target?.checked)
}

function normalizeMaterialAttrFieldValue(field: Pick<MaterialAttrField, 'data_type'>, raw: unknown) {
  const dataType = normalizeBatchAttrDataType(field.data_type)
  if (dataType === 'bool') return Boolean(raw)
  if (raw === null || raw === undefined) return dataType === 'bool' ? false : ''
  if (dataType === 'number') return String(raw)
  if (dataType === 'json') return typeof raw === 'string' ? raw : JSON.stringify(raw, null, 2)
  return String(raw)
}

async function loadMaterialAttrFields(typeId: string) {
  if (!typeId) {
    materialAttrFields.value = []
    return
  }

  try {
    materialAttrLoading.value = true
    const existingValues = new Map(materialAttrFields.value.map((field) => [field.code, field.value]))
    const seed = materialAttrValueSeed.value
    const { data: assignmentData, error: assignmentError } = await supabase
      .from('entity_attr_set')
      .select('attr_set_id')
      .eq('entity_type', 'material_type')
      .eq('entity_id', typeId)
      .eq('is_active', true)
    if (assignmentError) throw assignmentError

    const setIds = (assignmentData ?? []).map((row) => Number((row as { attr_set_id: unknown }).attr_set_id))
    if (setIds.length === 0) {
      if (selectedMaterialTypeId.value === typeId) materialAttrFields.value = []
      materialAttrValueSeed.value = null
      return
    }

    const { data: ruleData, error: ruleError } = await supabase
      .from('attr_set_rule')
      .select('attr_set_id, attr_id, required, sort_order, is_active, ui_section, ui_widget, help_text, attr_def:attr_def!fk_attr_set_rule_attr(attr_id, code, name, name_i18n, data_type, description, is_active, required, uom_id, num_min, num_max, text_regex, allowed_values, ref_kind, ref_domain)')
      .in('attr_set_id', setIds)
      .eq('is_active', true)
      .order('sort_order', { ascending: true })
    if (ruleError) throw ruleError

    const fields: MaterialAttrField[] = []
    for (const row of ruleData ?? []) {
      const typedRow = row as unknown as MaterialAttrRuleRow
      const attrRaw = typedRow.attr_def
      const attr = Array.isArray(attrRaw) ? (attrRaw[0] ?? null) : attrRaw
      if (!attr || attr.is_active === false) continue
      const dataType = normalizeBatchAttrDataType(attr.data_type)
      const seededValue = seed && Object.prototype.hasOwnProperty.call(seed, attr.code) ? seed[attr.code] : existingValues.get(attr.code)
      fields.push({
        attr_id: attr.attr_id,
        code: attr.code,
        name: attr.name,
        name_i18n: attr.name_i18n ?? null,
        data_type: dataType,
        required: ATTRIBUTES_OPTIONAL_IN_RECIPE_EDITOR ? false : Boolean(typedRow.required || attr.required),
        ui_section: typedRow.ui_section?.trim() || t('recipe.edit.materialAttributeDefaultSection'),
        ui_widget: typedRow.ui_widget?.trim() || '',
        help_text: typedRow.help_text?.trim() || '',
        description: attr.description?.trim() || '',
        uom_id: attr.uom_id ?? null,
        uom_code: attr.uom_id ? uoms.value.find((row) => row.id === attr.uom_id)?.code ?? null : null,
        num_min: typeof attr.num_min === 'number' ? attr.num_min : attr.num_min != null ? Number(attr.num_min) : null,
        num_max: typeof attr.num_max === 'number' ? attr.num_max : attr.num_max != null ? Number(attr.num_max) : null,
        text_regex: attr.text_regex ?? null,
        allowed_values: attr.allowed_values ?? null,
        ref_kind: attr.ref_kind ?? null,
        ref_domain: attr.ref_domain ?? null,
        value: normalizeMaterialAttrFieldValue({ data_type: dataType }, seededValue),
        error: '',
      })
    }

    fields.sort((a, b) => a.ui_section.localeCompare(b.ui_section) || a.code.localeCompare(b.code))
    if (selectedMaterialTypeId.value === typeId) materialAttrFields.value = fields
    materialAttrValueSeed.value = null
  } catch (error: unknown) {
    materialAttrFields.value = []
    materialAttrValueSeed.value = null
    const message = error instanceof Error ? error.message : String(error)
    toast.error(message)
  } finally {
    materialAttrLoading.value = false
  }
}

function validateMaterialAttrFields() {
  let hasError = false
  materialAttrFields.value.forEach((field) => {
    field.error = validateBatchAttrField(
      {
        code: field.code,
        name: materialAttrLabel(field),
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
        minValue: (label, min) => t('recipe.edit.materialAttributeMin', { field: label, min }),
        maxValue: (label, max) => t('recipe.edit.materialAttributeMax', { field: label, max }),
        pattern: (label) => t('recipe.edit.materialAttributePattern', { field: label }),
        allowedValues: (label) => t('recipe.edit.materialAttributeAllowedValues', { field: label }),
        invalidJson: (label) => t('recipe.edit.materialAttributeJson', { field: label }),
        invalidReference: (label) => t('recipe.edit.materialAttributeReference', { field: label }),
      },
    )
    if (field.error) hasError = true
  })
  return !hasError
}

function buildMaterialAttrValues() {
  const values: JsonObject = {}
  materialAttrFields.value.forEach((field) => {
    const dataType = normalizeBatchAttrDataType(field.data_type)
    if (dataType === 'bool') {
      values[field.code] = Boolean(field.value)
      return
    }
    if (field.value === null || field.value === undefined) return
    const rawValue = typeof field.value === 'string' ? field.value.trim() : field.value
    if (rawValue === '') return
    if (dataType === 'number') {
      values[field.code] = Number(rawValue)
      return
    }
    if (dataType === 'json') {
      values[field.code] = JSON.parse(String(rawValue))
      return
    }
    values[field.code] = rawValue
  })
  return Object.keys(values).length > 0 ? values : undefined
}

function buildFallbackMaterialIdentity() {
  const role = materialForm.material_role.trim()
  const typeCode = materialForm.material_type_code.trim()
  const materialKey = typeCode ? `${typeCode}:${role}` : role

  return {
    material_key: materialKey,
    material_name: role || undefined,
    material_code: undefined as string | undefined,
    material_type_code: typeCode || undefined,
  }
}

function validateMaterialForm() {
  resetMaterialErrors()
  if (!materialForm.material_role.trim()) materialErrors.material_role = t('recipe.edit.materialRoleRequired')
  const qty = Number(materialForm.qty)
  if (!Number.isFinite(qty) || qty < 0) materialErrors.qty = t('recipe.edit.quantityNonNegative')
  if (!materialForm.uom_code.trim()) materialErrors.uom_code = t('recipe.edit.uomCodeRequired')
  const attrValid = validateMaterialAttrFields()
  return Object.keys(materialErrors).length === 0 && attrValid
}

function validateOutputForm() {
  resetOutputErrors()
  if (!outputForm.output_code.trim()) outputErrors.output_code = t('recipe.edit.outputCodeRequired')
  if (!outputForm.output_name.trim()) outputErrors.output_name = t('recipe.edit.outputNameRequired')
  const qty = Number(outputForm.qty)
  if (!Number.isFinite(qty) || qty < 0) outputErrors.qty = t('recipe.edit.outputQuantityNonNegative')
  if (!outputForm.uom_code.trim()) outputErrors.uom_code = t('recipe.edit.outputUomRequired')
  return Object.keys(outputErrors).length === 0
}

async function persistRecipeBody() {
  if (!activeVersion.value) throw new Error(t('recipe.itemEditor.saveFailed'))
  const { error } = await mesClient()
    .from('mst_recipe_version')
    .update({
      recipe_body_json: recipeBody.value,
    })
    .eq('id', activeVersion.value.id)
  if (error) throw error
}

async function saveEditor() {
  if (!activeVersion.value || !recipeHeader.value) return
  if (isMaterialEditor.value) {
    if (!validateMaterialForm()) return
    const material = materialMasterMap.value.get(materialForm.material_id)
    const originalMaterial = materialOriginalRequirement.value
    const type = material?.material_type_id ? materialTypeMap.value.get(material.material_type_id) : undefined
    const fallbackIdentity = !material && !originalMaterial ? buildFallbackMaterialIdentity() : null
    const requirement: RecipeMaterialRequirement = {
      material_key: material?.material_code || originalMaterial?.material_key || fallbackIdentity?.material_key || '',
      material_name: material?.material_name || originalMaterial?.material_name || fallbackIdentity?.material_name,
      material_role: materialForm.material_role.trim(),
      material_code: material?.material_code || originalMaterial?.material_code || fallbackIdentity?.material_code,
      material_type_code: type?.code || originalMaterial?.material_type_code || fallbackIdentity?.material_type_code,
      qty: Number(materialForm.qty),
      uom_code: materialForm.uom_code.trim(),
      basis: materialForm.basis,
      is_optional: materialForm.section === 'optional',
      attr_values: buildMaterialAttrValues(),
      notes: materialForm.notes.trim() || undefined,
    }

    const targetList = recipeBody.value.materials[materialForm.section]
    if (materialEditIndex.value === null || materialOriginalSection.value === null) {
      targetList.push(requirement)
    } else if (materialOriginalSection.value === materialForm.section) {
      targetList.splice(materialEditIndex.value, 1, requirement)
    } else {
      recipeBody.value.materials[materialOriginalSection.value].splice(materialEditIndex.value, 1)
      targetList.push(requirement)
    }
  } else {
    if (!validateOutputForm()) return
    const output: RecipeOutputSpec = {
      output_code: outputForm.output_code.trim(),
      output_name: outputForm.output_name.trim(),
      output_type: outputForm.output_type,
      qty: Number(outputForm.qty),
      uom_code: outputForm.uom_code.trim(),
      basis: outputForm.basis || undefined,
      notes: outputForm.notes.trim() || undefined,
    }

    const targetList = recipeBody.value.outputs[outputForm.section]
    if (outputEditIndex.value === null || outputOriginalSection.value === null) {
      targetList.push(output)
    } else if (outputOriginalSection.value === outputForm.section) {
      targetList.splice(outputEditIndex.value, 1, output)
    } else {
      recipeBody.value.outputs[outputOriginalSection.value].splice(outputEditIndex.value, 1)
      targetList.push(output)
    }
  }

  try {
    saving.value = true
    await persistRecipeBody()
    toast.success(isMaterialEditor.value ? t('recipe.itemEditor.materialSaved') : t('recipe.itemEditor.outputSaved'))
    await goBack()
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error)
    toast.error(t('recipe.itemEditor.saveFailedWithMessage', { message }))
  } finally {
    saving.value = false
  }
}

async function goBack() {
  await router.push({
    path: `/recipeEdit/${recipeId.value}/${versionId.value}`,
    query: activeVersion.value?.schema_code ? { schemaKey: activeVersion.value.schema_code } : undefined,
  })
}

watch(
  () => materialForm.material_id,
  (materialId) => {
    if (!materialId) return
    const material = materialMasterMap.value.get(materialId)
    if (!material) return

    if (material.material_type_id) {
      const type = materialTypeMap.value.get(material.material_type_id)
      if (type?.type_id && selectedMaterialTypeId.value !== type.type_id) {
        selectedMaterialTypeId.value = type.type_id
      }
      if (type?.code && materialForm.material_type_code !== type.code) {
        materialForm.material_type_code = type.code
      }
    }

    if (!materialForm.uom_code && material.base_uom_id) {
      const uom = uoms.value.find((row) => row.id === material.base_uom_id)
      if (uom?.code) materialForm.uom_code = uom.code
    }
  },
)

watch(
  () => selectedMaterialTypeId.value,
  async (typeId) => {
    const type = typeId ? materialTypeMap.value.get(typeId) : null
    materialForm.material_type_code = type?.code || ''
    if (typeId) {
      await loadMaterialAttrFields(typeId)
    } else {
      materialAttrFields.value = []
    }

    if (!typeId || !materialForm.material_id) return
    const material = materialMasterMap.value.get(materialForm.material_id)
    if (!material?.material_type_id) return
    // The type tree is only a browser/filter for the source list.
    // Keep the current selection until the user explicitly picks another material.
  },
)

watch(
  () => [route.params.recipeId, route.params.versionId, route.params.kind, route.params.section, route.params.index],
  async () => {
    await initializePage()
  },
)

onMounted(async () => {
  await initializePage()
})
</script>
