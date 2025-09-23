<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
    <div class="w-full max-w-lg bg-white rounded-xl shadow-lg border border-gray-200">
      <header class="px-4 py-3 border-b flex items-center justify-between">
        <h3 class="text-lg font-semibold text-gray-800">{{ editing ? t('lot.ingredients.editTitle') : t('lot.ingredients.addTitle') }}</h3>
        <button class="text-sm px-2 py-1 rounded border hover:bg-gray-100" type="button" @click="emit('close')">{{ t('common.cancel') }}</button>
      </header>
      <form class="p-4 space-y-4" @submit.prevent="submitForm">
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="ingredientMaterial">{{ t('lot.ingredients.material') }}<span class="text-red-600">*</span></label>
          <select id="ingredientMaterial" v-model="form.material_id" class="w-full h-[40px] border rounded px-3" :disabled="editing" required>
            <option value="" disabled>{{ t('lot.ingredients.materialPlaceholder') }}</option>
            <option v-for="mat in materials" :key="mat.id" :value="mat.id">
              {{ mat.name }} ({{ mat.code }})
            </option>
          </select>
        </div>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="ingredientAmount">{{ t('lot.ingredients.amount') }}</label>
            <input id="ingredientAmount" v-model.number="form.amount" type="number" step="0.001" min="0" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="ingredientUom">{{ t('lot.ingredients.uom') }}<span class="text-red-600">*</span></label>
            <select id="ingredientUom" v-model="form.uom_id" class="w-full h-[40px] border rounded px-3" required>
              <option value="" disabled>{{ t('lot.ingredients.uomPlaceholder') }}</option>
              <option v-for="uom in uoms" :key="uom.id" :value="uom.id">{{ uom.code }}</option>
            </select>
          </div>
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="ingredientStage">{{ t('lot.ingredients.stage') }}</label>
          <input id="ingredientStage" v-model.trim="form.usage_stage" type="text" class="w-full h-[40px] border rounded px-3" />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="ingredientNotes">{{ t('lot.ingredients.notes') }}</label>
          <textarea id="ingredientNotes" v-model.trim="form.notes" rows="3" class="w-full border rounded px-3 py-2"></textarea>
        </div>
      </form>
      <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
        <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="emit('close')">{{ t('common.cancel') }}</button>
        <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="!form.material_id || !form.uom_id || loading" @click="submitForm">
          {{ loading ? t('common.loading') : (editing ? t('common.save') : t('common.add')) }}
        </button>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'

interface MaterialOption {
  id: string
  name: string
  code: string
}

interface UomOption {
  id: string
  code: string
}

interface IngredientFormState {
  id?: string
  material_id: string
  amount: number | null
  uom_id: string
  usage_stage: string | null
  notes: string | null
}

const props = defineProps<{ open: boolean, editing: boolean, loading: boolean, materials: MaterialOption[], uoms: UomOption[], initial?: IngredientFormState | null }>()
const emit = defineEmits<{
  (e: 'close'): void
  (e: 'submit', payload: IngredientFormState): void
}>()

const { t } = useI18n()

const blank = (): IngredientFormState => ({
  material_id: '',
  amount: null,
  uom_id: '',
  usage_stage: null,
  notes: null,
})

const form = reactive<IngredientFormState>(blank())

watch(() => props.open, (val) => {
  if (val) {
    Object.assign(form, blank(), props.initial ?? {})
  }
})

watch(() => props.initial, (val) => {
  if (props.open) {
    Object.assign(form, blank(), val ?? {})
  }
}, { deep: true })

function submitForm() {
  if (!form.material_id || !form.uom_id) return
  emit('submit', { ...form })
}
</script>
