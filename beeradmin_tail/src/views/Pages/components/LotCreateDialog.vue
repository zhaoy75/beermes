<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
    <div class="w-full max-w-lg bg-white rounded-xl shadow-lg border border-gray-200">
      <header class="px-4 py-3 border-b flex items-center justify-between">
        <div>
          <h3 class="text-lg font-semibold text-gray-800">{{ t('lot.create.title') }}</h3>
          <p class="text-xs text-gray-500">{{ t('lot.create.subtitle') }}</p>
        </div>
        <button class="text-sm px-2 py-1 rounded border hover:bg-gray-100" type="button" @click="emit('close')">{{ t('common.cancel') }}</button>
      </header>

      <form class="p-4 space-y-4" @submit.prevent="submitForm">
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="recipeSelect">{{ t('lot.create.recipe') }}<span class="text-red-600">*</span></label>
          <select id="recipeSelect" v-model="form.recipeId" class="w-full h-[40px] border rounded px-3" required>
            <option value="" disabled>{{ t('lot.create.recipePlaceholder') }}</option>
            <option v-for="recipe in recipes" :key="recipe.id" :value="recipe.id">
              {{ recipe.name }} ({{ recipe.code }}) v{{ recipe.version }}
            </option>
          </select>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="plannedStart">{{ t('lot.create.plannedStart') }}</label>
            <input id="plannedStart" v-model="form.plannedStart" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="processVersion">{{ t('lot.create.processVersion') }}</label>
            <input id="processVersion" v-model.number="form.processVersion" type="number" min="1" class="w-full h-[40px] border rounded px-3" placeholder="{{ t('lot.create.processPlaceholder') }}" />
          </div>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="targetVolume">{{ t('lot.create.targetVolume') }}</label>
            <input id="targetVolume" v-model.number="form.targetVolume" type="number" step="0.01" min="0" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="notes">{{ t('lot.create.notes') }}</label>
            <input id="notes" v-model.trim="form.notes" type="text" class="w-full h-[40px] border rounded px-3" />
          </div>
        </div>
        <p class="text-xs text-gray-500">{{ t('lot.create.autoCodeHint') }}</p>
      </form>
      <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
        <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="emit('close')">{{ t('common.cancel') }}</button>
        <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="loading || !form.recipeId" @click="submitForm">
          {{ loading ? t('common.loading') : t('lot.create.createButton') }}
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
  (e: 'submit', payload: { recipeId: string, plannedStart: string | null, targetVolume: number | null, notes: string | null, processVersion: number | null }): void
}>()

const { t } = useI18n()

const blank = () => ({
  recipeId: '',
  plannedStart: '',
  targetVolume: null as number | null,
  notes: '',
  processVersion: null as number | null,
})

const form = reactive(blank())

watch(() => props.open, (val) => {
  if (val) {
    Object.assign(form, blank())
  }
})

function submitForm() {
  if (!form.recipeId) return
  emit('submit', {
    recipeId: form.recipeId,
    plannedStart: form.plannedStart || null,
    targetVolume: form.targetVolume,
    notes: form.notes ? form.notes.trim() : null,
    processVersion: form.processVersion || null,
  })
}
</script>
