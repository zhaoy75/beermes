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
          <label class="block text-sm text-gray-600 mb-1" for="plannedStart">{{ t('batch.create.plannedStart') }}</label>
          <input
            id="plannedStart"
            v-model="form.plannedStart"
            type="date"
            class="w-full h-[40px] border rounded px-3"
            placeholder="YYYY-MM-DD"
            @focus="openDatePicker"
          />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="plannedEnd">{{ t('batch.create.plannedEnd') }}</label>
          <input
            id="plannedEnd"
            v-model="form.plannedEnd"
            type="date"
            class="w-full h-[40px] border rounded px-3"
            placeholder="YYYY-MM-DD"
            @focus="openDatePicker"
          />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="notes">{{ t('batch.create.notes') }}</label>
          <input id="notes" v-model.trim="form.notes" type="text" class="w-full h-[40px] border rounded px-3" />
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
  (e: 'submit', payload: { recipeId: string, batchCode: string | null, label: string | null, plannedStart: string | null, plannedEnd: string | null, notes: string | null, processVersion: number | null }): void
}>()

const { t } = useI18n()

const blank = () => ({
  recipeId: '',
  batchCode: '',
  plannedStart: '',
  plannedEnd: '',
  notes: '',
  processVersion: null as number | null,
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
    label: null,
    plannedStart: form.plannedStart || null,
    plannedEnd: form.plannedEnd || null,
    notes: form.notes ? form.notes.trim() : null,
    processVersion: form.processVersion || null,
  })
}

function openDatePicker(event: Event) {
  const target = event.target as HTMLInputElement | null
  if (!target) return
  if (typeof target.showPicker === 'function') {
    target.showPicker()
  }
}
</script>
