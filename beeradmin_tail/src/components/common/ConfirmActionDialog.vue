<template>
  <div
    v-if="open"
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4"
    @keydown.enter.capture="handleEnterShortcut"
  >
    <div class="w-full max-w-sm rounded-xl border border-gray-200 bg-white shadow-lg">
      <header v-if="title" class="border-b px-4 py-3">
        <h3 class="text-lg font-semibold text-gray-800">{{ title }}</h3>
      </header>
      <div class="space-y-2 px-4 py-4 text-sm text-gray-700">
        <p class="whitespace-pre-line">{{ message }}</p>
      </div>
      <footer class="flex items-center justify-end gap-2 border-t px-4 py-3">
        <button class="rounded border px-3 py-2 hover:bg-gray-50" type="button" @click="emit('cancel')">
          {{ cancelText }}
        </button>
        <button :class="confirmButtonClass" type="button" @click="emit('confirm')">
          {{ confirmLabel }}
        </button>
      </footer>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { runDialogEnterAction, shouldRunDialogEnterAction } from '@/lib/dialogKeyboard'

type ConfirmDialogTone = 'danger' | 'warning' | 'primary'

const props = withDefaults(defineProps<{
  open: boolean
  title?: string
  message: string
  confirmLabel: string
  cancelLabel?: string
  tone?: ConfirmDialogTone
}>(), {
  title: '',
  cancelLabel: '',
  tone: 'primary',
})

const emit = defineEmits(['cancel', 'confirm'])
const { t } = useI18n()

const cancelText = computed(() => props.cancelLabel || t('common.cancel'))
const confirmButtonClass = computed(() => {
  if (props.tone === 'danger') {
    return 'rounded bg-red-600 px-3 py-2 text-white hover:bg-red-700'
  }
  if (props.tone === 'warning') {
    return 'rounded bg-amber-500 px-3 py-2 text-white hover:bg-amber-600'
  }
  return 'rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700'
})

function confirmFromEnter() {
  emit('confirm')
}

function handleEnterShortcut(event: KeyboardEvent) {
  runDialogEnterAction(event, confirmFromEnter)
}

function handleWindowKeydown(event: KeyboardEvent) {
  if (!props.open || !shouldRunDialogEnterAction(event)) return
  event.preventDefault()
  confirmFromEnter()
}

watch(
  () => props.open,
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
