<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
    <div class="w-full max-w-xl bg-white rounded-xl shadow-lg border border-gray-200">
      <header class="px-4 py-3 border-b flex items-center justify-between">
        <h3 class="text-lg font-semibold text-gray-800">{{ editing ? t('lot.packaging.editTitle') : t('lot.packaging.addTitle') }}</h3>
        <button class="text-sm px-2 py-1 rounded border hover:bg-gray-100" type="button" @click="emit('close')">{{ t('common.cancel') }}</button>
      </header>
      <form class="p-4 space-y-4" @submit.prevent="submitForm">
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="packageSelect">{{ t('lot.packaging.columns.package') }}<span class="text-red-600">*</span></label>
            <select id="packageSelect" v-model="form.package_id" class="w-full h-[40px] border rounded px-3" required @change="onPackageChange">
              <option value="" disabled>{{ t('lot.packaging.packagePlaceholder') }}</option>
              <option v-for="pkg in categories" :key="pkg.id" :value="pkg.id">
                {{ pkg.display }}
              </option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="fillDate">{{ t('lot.packaging.columns.fillDate') }}</label>
            <input id="fillDate" v-model="form.fill_at" type="date" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="qtyInput">{{ t('lot.packaging.columns.quantity') }}<span class="text-red-600">*</span></label>
            <input id="qtyInput" v-model.number="form.package_qty" type="number" min="0" step="1" class="w-full h-[40px] border rounded px-3" required />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="sizeInput">{{ t('lot.packaging.columns.sizeOverride') }}</label>
            <div class="flex items-center gap-2">
              <input id="sizeInput" v-model="form.package_size_l" type="number" step="0.001" min="0" class="flex-1 h-[40px] border rounded px-3" />
              <span class="text-sm text-gray-500">{{ t('lot.packaging.lUnit') }}</span>
            </div>
            <p v-if="form.package_id" class="mt-1 text-xs text-gray-500">{{ t('lot.packaging.defaultSizeHint', { size: defaultSizeLabel }) }}</p>
          </div>
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1" for="notesInput">{{ t('lot.packaging.columns.notes') }}</label>
          <textarea id="notesInput" v-model.trim="form.notes" rows="3" class="w-full border rounded px-3 py-2"></textarea>
        </div>
      </form>
      <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
        <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="emit('close')">{{ t('common.cancel') }}</button>
        <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="loading" @click="submitForm">
          {{ loading ? t('common.saving') : t('common.save') }}
        </button>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'

type CategoryOption = {
  id: string
  code: string
  name: string | null
  default_volume_l: number | null
  display: string
}

type PackageFormState = {
  id?: string
  package_id: string
  fill_at: string
  package_qty: number
  package_size_l: string
  notes: string
}

const props = defineProps<{ open: boolean, editing: boolean, loading: boolean, categories: CategoryOption[], initial?: PackageFormState | null }>()
const emit = defineEmits<{ (e: 'close'): void; (e: 'submit', payload: PackageFormState): void }>()

const { t } = useI18n()

const blank = (): PackageFormState => ({
  package_id: '',
  fill_at: '',
  package_qty: 0,
  package_size_l: '',
  notes: '',
})

const form = reactive<PackageFormState>(blank())

const defaultSizeLabel = computed(() => {
  const current = props.categories.find((c) => c.id === form.package_id)
  if (!current?.default_volume_l) return t('lot.packaging.noDefaultSize')
  return `${current.default_volume_l.toLocaleString(undefined, { maximumFractionDigits: 2 })} L`
})

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

function onPackageChange() {
  if (!form.package_size_l) {
    const current = props.categories.find((c) => c.id === form.package_id)
    if (current?.default_volume_l) {
      form.package_size_l = String(current.default_volume_l)
    }
  }
}

function submitForm() {
  if (!form.package_id || Number(form.package_qty) < 0) return
  emit('submit', { ...form })
}
</script>
