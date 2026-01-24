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
          <label class="block text-sm text-gray-600 mb-1" for="lotCode">{{ t('lot.create.lotCode') }}</label>
          <input id="lotCode" v-model.trim="form.lotCode" type="text" class="w-full h-[40px] border rounded px-3" :placeholder="t('lot.create.lotCodePlaceholder')" />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="lotLabel">{{ t('lot.create.label') }}</label>
          <input id="lotLabel" v-model.trim="form.label" type="text" class="w-full h-[40px] border rounded px-3" />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="plannedStart">{{ t('lot.create.plannedStart') }}</label>
          <input id="plannedStart" v-model="form.plannedStart" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
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
        <div class="space-y-2">
          <div class="flex items-center justify-between">
            <div>
              <p class="text-sm font-semibold text-gray-700">{{ t('lot.create.parentLotsTitle') }}</p>
              <p class="text-xs text-gray-500">{{ t('lot.create.parentLotsSubtitle') }}</p>
            </div>
            <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="addParentLot">{{ t('lot.create.parentLotsAdd') }}</button>
          </div>
          <div v-if="form.parentLots.length === 0" class="text-xs text-gray-500">{{ t('lot.create.parentLotsEmpty') }}</div>
          <div v-for="(row, index) in form.parentLots" :key="`parent-${index}`" class="grid grid-cols-1 md:grid-cols-3 gap-3">
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1" :for="`parentLotCode-${index}`">{{ t('lot.create.parentLotCode') }}</label>
              <input :id="`parentLotCode-${index}`" v-model.trim="row.lot_code" type="text" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1" :for="`parentLotQty-${index}`">{{ t('lot.create.parentLotQuantity') }}</label>
              <input :id="`parentLotQty-${index}`" v-model="row.quantity_liters" type="number" min="0" step="0.01" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div class="md:col-span-3 flex justify-end">
              <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="removeParentLot(index)">{{ t('lot.create.parentLotsRemove') }}</button>
            </div>
          </div>
        </div>
        <p class="text-xs text-gray-500">{{ t('lot.create.autoCodeHint') }}</p>
      </form>
      <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
        <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="emit('close')">{{ t('common.cancel') }}</button>
        <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="loading" @click="submitForm">
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
  (e: 'submit', payload: { recipeId: string, lotCode: string | null, label: string | null, plannedStart: string | null, targetVolume: number | null, notes: string | null, processVersion: number | null, parentLots: ParentLotInput[] }): void
}>()

const { t } = useI18n()

type ParentLotInput = {
  lot_code: string
  quantity_liters: string
}

const blankParentLot = (): ParentLotInput => ({
  lot_code: '',
  quantity_liters: '',
})

const blank = () => ({
  recipeId: '',
  lotCode: '',
  label: '',
  plannedStart: '',
  targetVolume: null as number | null,
  notes: '',
  processVersion: null as number | null,
  parentLots: [] as ParentLotInput[],
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
    lotCode: form.lotCode ? form.lotCode.trim() : null,
    label: form.label ? form.label.trim() : null,
    plannedStart: form.plannedStart || null,
    targetVolume: form.targetVolume,
    notes: form.notes ? form.notes.trim() : null,
    processVersion: form.processVersion || null,
    parentLots: form.parentLots.map((row) => ({
      lot_code: row.lot_code,
      quantity_liters: row.quantity_liters,
    })),
  })
}

function addParentLot() {
  form.parentLots.push(blankParentLot())
}

function removeParentLot(index: number) {
  form.parentLots.splice(index, 1)
}
</script>
