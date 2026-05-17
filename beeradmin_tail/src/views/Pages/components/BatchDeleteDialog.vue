<template>
  <div
    v-if="open && batch"
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    @keydown.enter.capture="handleEnterShortcut"
  >
    <div class="w-full max-w-sm bg-white rounded-xl shadow-lg border border-gray-200">
      <header class="px-4 py-3 border-b">
        <h3 class="text-lg font-semibold text-gray-800">{{ t('batch.delete.title') }}</h3>
      </header>
      <div class="px-4 py-4 space-y-2 text-sm text-gray-700">
        <p>{{ t('batch.delete.confirm', { code: batch.batch_code }) }}</p>
        <p class="text-xs text-gray-500">{{ t('batch.delete.warning') }}</p>
      </div>
      <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
        <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="emit('cancel')">{{ t('common.cancel') }}</button>
        <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700 disabled:opacity-50" type="button" :disabled="loading" @click="emit('confirm')">{{ loading ? t('common.loading') : t('common.delete') }}</button>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { runDialogEnterAction, shouldRunDialogEnterAction } from '@/lib/dialogKeyboard'

interface BatchRef {
  batch_code: string
}

const props = defineProps<{ open: boolean, batch: BatchRef | null, loading: boolean }>()
const emit = defineEmits(['cancel', 'confirm'])

const { t } = useI18n()

function confirmFromEnter() {
  if (props.loading) return
  emit('confirm')
}

function handleEnterShortcut(event: KeyboardEvent) {
  runDialogEnterAction(event, confirmFromEnter)
}

function handleWindowKeydown(event: KeyboardEvent) {
  if (!props.open || !props.batch || !shouldRunDialogEnterAction(event)) return
  event.preventDefault()
  confirmFromEnter()
}

watch(
  () => props.open && Boolean(props.batch),
  (open) => {
    if (open) {
      window.addEventListener('keydown', handleWindowKeydown)
    } else {
      window.removeEventListener('keydown', handleWindowKeydown)
    }
  },
  { immediate: true },
)

onBeforeUnmount(() => {
  window.removeEventListener('keydown', handleWindowKeydown)
})
</script>
