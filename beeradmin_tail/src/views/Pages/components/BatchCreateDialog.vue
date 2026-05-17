<template>
  <div
    v-if="open"
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    @keydown.enter.capture="handleEnterShortcut"
  >
    <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg border border-gray-200">
      <header class="px-4 py-3 border-b flex items-center justify-between">
        <div>
          <h3 class="text-lg font-semibold text-gray-800">{{ t('batch.create.title') }}</h3>
          <p class="text-xs text-gray-500">{{ t('batch.create.subtitle') }}</p>
        </div>
        <button class="text-sm px-2 py-1 rounded border hover:bg-gray-100" type="button" @click="emit('close')">{{ t('common.cancel') }}</button>
      </header>

      <form class="p-4 space-y-4 max-h-[70vh] overflow-y-auto" @submit.prevent="submitForm">
        <div v-if="showRecipeSelection">
          <label class="block text-sm text-gray-600 mb-1" for="recipeId">{{ t('batch.create.recipe') }}</label>
          <select id="recipeId" v-model="form.recipeId" class="w-full h-[40px] border rounded px-3 bg-white">
            <option value="">{{ t('batch.create.recipePlaceholder') }}</option>
            <option v-for="recipe in recipes" :key="recipe.id" :value="recipe.id">
              {{ recipeLabel(recipe) }}
            </option>
          </select>
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="batchCode">{{ t('batch.create.batchCode') }}</label>
          <input id="batchCode" v-model.trim="form.batchCode" type="text" class="w-full h-[40px] border rounded px-3" :placeholder="t('batch.create.batchCodePlaceholder')" />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="plannedStart">{{ t('batch.create.plannedStart') }}</label>
          <AppDateTimePicker
            id="plannedStart"
            v-model="form.plannedStart"
            class="w-full h-[40px] border rounded px-3"
            placeholder="YYYY-MM-DD"
          />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="plannedEnd">{{ t('batch.create.plannedEnd') }}</label>
          <AppDateTimePicker
            id="plannedEnd"
            v-model="form.plannedEnd"
            class="w-full h-[40px] border rounded px-3"
            placeholder="YYYY-MM-DD"
          />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="notes">{{ t('batch.create.notes') }}</label>
          <input id="notes" v-model.trim="form.notes" type="text" class="w-full h-[40px] border rounded px-3" />
        </div>

        <div v-if="attrLoading" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
        <section v-else-if="attrFields.length" class="space-y-3 border-t border-gray-200 pt-4">
          <h4 class="text-sm font-semibold text-gray-700">{{ t('batch.create.attributes') }}</h4>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div v-for="field in attrFields" :key="field.attr_id">
              <label class="block text-sm text-gray-600 mb-1" :for="`batch-create-attr-${field.attr_id}`">
                {{ attrLabel(field) }}
              </label>
              <template v-if="field.data_type === 'ref'">
                <select
                  :id="`batch-create-attr-${field.attr_id}`"
                  v-model="attrValues[String(field.attr_id)]"
                  :class="inputClass(field)"
                  @change="validateAttrField(field)"
                  @blur="validateAttrField(field)"
                >
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in field.options" :key="`${option.value}`" :value="option.value">
                    {{ option.label }}
                  </option>
                </select>
              </template>
              <template v-else-if="allowedOptions(field).length">
                <select
                  :id="`batch-create-attr-${field.attr_id}`"
                  v-model="attrValues[String(field.attr_id)]"
                  :class="inputClass(field)"
                  @change="validateAttrField(field)"
                  @blur="validateAttrField(field)"
                >
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in allowedOptions(field)" :key="option.value" :value="option.value">
                    {{ option.label }}
                  </option>
                </select>
              </template>
              <template v-else-if="field.data_type === 'number'">
                <div class="flex items-center gap-2">
                  <input
                    :id="`batch-create-attr-${field.attr_id}`"
                    v-model="attrValues[String(field.attr_id)]"
                    type="number"
                    step="any"
                    :min="field.num_min ?? undefined"
                    :max="field.num_max ?? undefined"
                    :class="inputClass(field)"
                    @input="validateAttrField(field)"
                    @blur="validateAttrField(field)"
                  />
                  <span v-if="field.uom_code" class="text-xs text-gray-500">{{ field.uom_code }}</span>
                </div>
              </template>
              <template v-else-if="field.data_type === 'bool'">
                <label class="inline-flex h-[40px] items-center gap-2 text-sm text-gray-700">
                  <input
                    :id="`batch-create-attr-${field.attr_id}`"
                    v-model="attrValues[String(field.attr_id)]"
                    type="checkbox"
                    class="h-4 w-4"
                  />
                  {{ t('common.yes') }}
                </label>
              </template>
              <template v-else-if="field.data_type === 'date'">
                <AppDateTimePicker
                  :id="`batch-create-attr-${field.attr_id}`"
                  v-model="attrValues[String(field.attr_id)]"
                  :class="inputClass(field)"
                  @change="validateAttrField(field)"
                  @blur="validateAttrField(field)"
                />
              </template>
              <template v-else-if="field.data_type === 'timestamp'">
                <AppDateTimePicker
                  :id="`batch-create-attr-${field.attr_id}`"
                  v-model="attrValues[String(field.attr_id)]"
                  mode="datetime"
                  :class="inputClass(field)"
                  @change="validateAttrField(field)"
                  @blur="validateAttrField(field)"
                />
              </template>
              <template v-else-if="field.data_type === 'json'">
                <textarea
                  :id="`batch-create-attr-${field.attr_id}`"
                  :value="attrTextValue(field)"
                  rows="3"
                  :class="textareaClass(field)"
                  @input="onAttrInput(field, $event)"
                  @blur="validateAttrField(field)"
                ></textarea>
              </template>
              <template v-else>
                <input
                  :id="`batch-create-attr-${field.attr_id}`"
                  v-model.trim="attrValues[String(field.attr_id)]"
                  type="text"
                  :class="inputClass(field)"
                  @input="validateAttrField(field)"
                  @blur="validateAttrField(field)"
                />
              </template>
              <p v-if="attrErrors[String(field.attr_id)]" class="mt-1 text-xs text-red-600">
                {{ attrErrors[String(field.attr_id)] }}
              </p>
            </div>
          </div>
        </section>
        <p class="text-xs text-gray-500">{{ t('batch.create.autoCodeHint') }}</p>
      </form>
      <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
        <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="emit('close')">{{ t('common.cancel') }}</button>
        <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="loading" @click="submitForm">
          {{ loading ? t('common.loading') : t('batch.create.createButton') }}
        </button>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import AppDateTimePicker from '@/components/common/AppDateTimePicker.vue'
import { runDialogEnterAction } from '@/lib/dialogKeyboard'
import {
  normalizeBatchAttrDataType,
  validateBatchAttrField,
} from '@/lib/batchAttrValidation'

type RecipeOption = {
  id: string
  name: string
  code: string
  versionNo: number | null
  versionStatus: string | null
}

type AttrInputField = {
  attr_id: number
  code: string
  name: string
  name_i18n?: Record<string, string> | null
  data_type: string
  required: boolean
  uom_id: string | null
  uom_code: string | null
  num_min?: number | null
  num_max?: number | null
  text_regex?: string | null
  allowed_values?: unknown | null
  ref_kind?: string | null
  ref_domain?: string | null
  options: Array<{ value: string | number, label: string }>
}

const props = defineProps<{
  open: boolean
  recipes: RecipeOption[]
  loading: boolean
  showRecipeSelection: boolean
  attrFields: AttrInputField[]
  attrLoading: boolean
}>()
const emit = defineEmits<{
  (e: 'close'): void
  (e: 'submit', payload: { recipeId: string, batchCode: string | null, label: string | null, plannedStart: string | null, plannedEnd: string | null, notes: string | null, attrValues: Record<string, unknown> }): void
}>()

const { t, locale } = useI18n()

const blank = () => ({
  recipeId: '',
  batchCode: '',
  plannedStart: '',
  plannedEnd: '',
  notes: '',
})

const form = reactive(blank())
const attrValues = reactive<Record<string, unknown>>({})
const attrErrors = reactive<Record<string, string>>({})

watch(() => props.open, (val) => {
  if (val) {
    Object.assign(form, blank())
    resetAttrValues()
  }
})

watch(() => props.attrFields, () => {
  if (props.open) resetAttrValues()
})

watch(() => props.showRecipeSelection, (show) => {
  if (!show) form.recipeId = ''
})

function submitForm() {
  if (props.loading) return
  if (!validateAttributes()) return

  emit('submit', {
    recipeId: props.showRecipeSelection ? form.recipeId : '',
    batchCode: form.batchCode ? form.batchCode.trim() : null,
    label: null,
    plannedStart: form.plannedStart || null,
    plannedEnd: form.plannedEnd || null,
    notes: form.notes ? form.notes.trim() : null,
    attrValues: { ...attrValues },
  })
}

function handleEnterShortcut(event: KeyboardEvent) {
  runDialogEnterAction(event, submitForm)
}

function recipeLabel(recipe: RecipeOption) {
  const versionText = recipe.versionNo == null ? '' : ` / v${recipe.versionNo}`
  return `${recipe.name} (${recipe.code})${versionText}`
}

function resetAttrValues() {
  Object.keys(attrValues).forEach((key) => delete attrValues[key])
  Object.keys(attrErrors).forEach((key) => delete attrErrors[key])
  for (const field of props.attrFields) {
    attrValues[String(field.attr_id)] = defaultAttrValue(field)
  }
}

function defaultAttrValue(field: AttrInputField) {
  return normalizeBatchAttrDataType(field.data_type) === 'bool' ? false : ''
}

function attrLabel(field: AttrInputField) {
  const key = String(locale.value ?? '').toLowerCase().startsWith('ja') ? 'ja' : 'en'
  const label = field.name_i18n?.[key]
  return label || field.name || field.code
}

function inputClass(field: AttrInputField) {
  return [
    'w-full h-[40px] border rounded px-3 bg-white',
    attrErrors[String(field.attr_id)] ? 'border-red-500 focus:border-red-500 focus:ring-red-500' : '',
  ]
}

function textareaClass(field: AttrInputField) {
  return [
    'w-full border rounded px-3 py-2 font-mono text-xs',
    attrErrors[String(field.attr_id)] ? 'border-red-500 focus:border-red-500 focus:ring-red-500' : '',
  ]
}

function validateAttributes() {
  let valid = true
  for (const field of props.attrFields) {
    if (validateAttrField(field)) valid = false
  }
  return valid
}

function validateAttrField(field: AttrInputField) {
  const key = String(field.attr_id)
  const error = validateBatchAttrField(
    {
      code: field.code,
      name: attrLabel(field),
      data_type: field.data_type,
      required: false,
      num_min: field.num_min ?? null,
      num_max: field.num_max ?? null,
      text_regex: field.text_regex ?? null,
      allowed_values: field.allowed_values ?? null,
      ref_kind: field.ref_kind ?? null,
      value: attrValues[key],
    },
    {
      required: (label) => t('errors.required', { field: label }),
      mustBeNumber: (label) => t('errors.mustBeNumber', { field: label }),
      minValue: (label, min) => t('batch.edit.errors.attrMin', { field: label, min }),
      maxValue: (label, max) => t('batch.edit.errors.attrMax', { field: label, max }),
      pattern: (label) => t('batch.edit.errors.attrPattern', { field: label }),
      allowedValues: (label) => t('batch.edit.errors.attrAllowedValues', { field: label }),
      invalidJson: (label) => t('batch.edit.errors.attrJson', { field: label }),
      invalidReference: (label) => t('batch.edit.errors.attrReference', { field: label }),
    },
  )
  attrErrors[key] = error
  return error
}

function attrTextValue(field: AttrInputField) {
  const value = attrValues[String(field.attr_id)]
  if (value === null || value === undefined) return ''
  return String(value)
}

function onAttrInput(field: AttrInputField, event: Event) {
  const target = event.target as HTMLInputElement | HTMLTextAreaElement | null
  attrValues[String(field.attr_id)] = target?.value ?? ''
  validateAttrField(field)
}

function allowedOptions(field: AttrInputField) {
  const value = field.allowed_values
  if (Array.isArray(value)) {
    return value
      .map((entry) => String(entry ?? '').trim())
      .filter(Boolean)
      .map((entry) => ({ value: entry, label: entry }))
  }
  if (!value || typeof value !== 'object') return []

  return Object.entries(value as Record<string, unknown>)
    .map(([key, entry]) => {
      const normalized = key.trim()
      if (!normalized) return null
      const label = typeof entry === 'string' || typeof entry === 'number' || typeof entry === 'boolean'
        ? String(entry)
        : normalized
      return { value: normalized, label }
    })
    .filter((entry): entry is { value: string, label: string } => entry !== null)
}
</script>
