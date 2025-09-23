<template>
  <div v-if="open && lot" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
    <div class="w-full max-w-sm bg-white rounded-xl shadow-lg border border-gray-200">
      <header class="px-4 py-3 border-b">
        <h3 class="text-lg font-semibold text-gray-800">{{ t('lot.delete.title') }}</h3>
      </header>
      <div class="px-4 py-4 space-y-2 text-sm text-gray-700">
        <p>{{ t('lot.delete.confirm', { code: lot.lot_code }) }}</p>
        <p class="text-xs text-gray-500">{{ t('lot.delete.warning') }}</p>
      </div>
      <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
        <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="emit('cancel')">{{ t('common.cancel') }}</button>
        <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700 disabled:opacity-50" type="button" :disabled="loading" @click="emit('confirm')">{{ loading ? t('common.loading') : t('common.delete') }}</button>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'

interface LotRef {
  lot_code: string
}

const props = defineProps<{ open: boolean, lot: LotRef | null, loading: boolean }>()
const emit = defineEmits(['cancel', 'confirm'])

const { t } = useI18n()
</script>
