<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
    <div class="w-full max-w-lg bg-white rounded-xl shadow-lg border border-gray-200">
      <header class="px-4 py-3 border-b flex items-center justify-between">
        <div>
          <h3 class="text-lg font-semibold text-gray-800">{{ t('batch.create.title') }}</h3>
          <p class="text-xs text-gray-500">{{ t('batch.create.subtitle') }}</p>
        </div>
        <button class="text-sm px-2 py-1 rounded border hover:bg-gray-100" type="button" @click="emit('close')">{{ t('common.cancel') }}</button>
      </header>

      <form class="p-4 space-y-4" @submit.prevent="submitForm">
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="batchCode">{{ t('batch.create.batchCode') }}</label>
          <input id="batchCode" v-model.trim="form.batchCode" type="text" class="w-full h-[40px] border rounded px-3" :placeholder="t('batch.create.batchCodePlaceholder')" />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="batchLabel">{{ t('batch.create.label') }}</label>
          <input id="batchLabel" v-model.trim="form.label" type="text" class="w-full h-[40px] border rounded px-3" />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="plannedStart">{{ t('batch.create.plannedStart') }}</label>
          <input id="plannedStart" v-model="form.plannedStart" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="targetVolume">{{ t('batch.create.targetVolume') }}</label>
            <input id="targetVolume" v-model.number="form.targetVolume" type="number" step="0.01" min="0" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="notes">{{ t('batch.create.notes') }}</label>
            <input id="notes" v-model.trim="form.notes" type="text" class="w-full h-[40px] border rounded px-3" />
          </div>
        </div>
        <div class="space-y-2">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-semibold text-gray-700">{{ t('batch.create.parentBatchesTitle') }}</p>
              <p class="text-xs text-gray-500">{{ t('batch.create.parentBatchesSubtitle') }}</p>
            </div>
            <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="addParentBatch">{{ t('batch.create.parentBatchesAdd') }}</button>
          </div>
          <div v-if="form.parentBatches.length === 0" class="text-xs text-gray-500">{{ t('batch.create.parentBatchesEmpty') }}</div>
          <div v-for="(row, index) in form.parentBatches" :key="`parent-${index}`" class="grid grid-cols-1 md:grid-cols-3 gap-3">
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1" :for="`parentBatchCode-${index}`">{{ t('batch.create.parentBatchCode') }}</label>
              <input :id="`parentBatchCode-${index}`" v-model.trim="row.batch_code" type="text" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1" :for="`parentBatchQty-${index}`">{{ t('batch.create.parentBatchQuantity') }}</label>
              <input :id="`parentBatchQty-${index}`" v-model="row.quantity_liters" type="number" min="0" step="0.01" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div class="md:col-span-3 flex justify-end">
              <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="removeParentBatch(index)">{{ t('batch.create.parentBatchesRemove') }}</button>
            </div>
          </div>
        </div>
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

type RecipeOption = {
  id: string
  name: string
  code: string
  version: number
}

const props = defineProps<{ open: boolean, recipes: RecipeOption[], loading: boolean }>()
const emit = defineEmits<{
  (e: 'close'): void
  (e: 'submit', payload: { recipeId: string, batchCode: string | null, label: string | null, plannedStart: string | null, targetVolume: number | null, notes: string | null, processVersion: number | null, parentBatches: ParentBatchInput[] }): void
}>()

const { t } = useI18n()

type ParentBatchInput = {
  batch_code: string
  quantity_liters: string
}

const blankParentBatch = (): ParentBatchInput => ({
  batch_code: '',
  quantity_liters: '',
})

const blank = () => ({
  recipeId: '',
  batchCode: '',
  label: '',
  plannedStart: '',
  targetVolume: null as number | null,
  notes: '',
  processVersion: null as number | null,
  parentBatches: [] as ParentBatchInput[],
})

const form = reactive(blank())

watch(() => props.open, (val) => {
  if (val) {
    Object.assign(form, blank())
    if (!form.recipeId && props.recipes.length > 0) {
      form.recipeId = props.recipes[0].id
    }
  }
})

watch(() => props.recipes, (list) => {
  if (!props.open) return
  if (!form.recipeId && list.length > 0) {
    form.recipeId = list[0].id
  }
})

function submitForm() {
  emit('submit', {
    recipeId: form.recipeId,
    batchCode: form.batchCode ? form.batchCode.trim() : null,
    label: form.label ? form.label.trim() : null,
    plannedStart: form.plannedStart || null,
    targetVolume: form.targetVolume,
    notes: form.notes ? form.notes.trim() : null,
    processVersion: form.processVersion || null,
    parentBatches: form.parentBatches.map((row) => ({
      batch_code: row.batch_code,
      quantity_liters: row.quantity_liters,
    })),
  })
}

function addParentBatch() {
  form.parentBatches.push(blankParentBatch())
}

function removeParentBatch(index: number) {
  form.parentBatches.splice(index, 1)
}
</script>
