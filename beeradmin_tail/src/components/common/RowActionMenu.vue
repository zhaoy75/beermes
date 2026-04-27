<template>
  <div ref="rootEl" class="relative inline-flex" @keydown.escape.stop="closeMenu">
    <button
      class="inline-flex h-8 w-8 items-center justify-center rounded border border-gray-300 bg-white text-gray-600 hover:bg-gray-50 hover:text-gray-900 disabled:opacity-50"
      type="button"
      :title="label"
      :aria-label="label"
      :disabled="disabled || actions.length === 0"
      @click.stop="toggleMenu"
    >
      <svg class="h-4 w-4" viewBox="0 0 20 20" aria-hidden="true" fill="currentColor">
        <circle cx="5" cy="10" r="1.6" />
        <circle cx="10" cy="10" r="1.6" />
        <circle cx="15" cy="10" r="1.6" />
      </svg>
    </button>

    <div
      v-if="menuOpen"
      class="absolute right-0 z-40 mt-1 w-48 rounded border border-gray-200 bg-white p-1 text-left shadow-lg"
    >
      <button
        v-for="action in actions"
        :key="action.key"
        class="flex w-full items-center rounded px-3 py-2 text-sm hover:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-50"
        :class="action.tone === 'danger' ? 'text-red-700 hover:bg-red-50' : 'text-gray-700'"
        type="button"
        :title="action.title || action.label"
        :disabled="action.disabled"
        @click="selectAction(action.key)"
      >
        {{ action.label }}
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onBeforeUnmount, onMounted, ref } from 'vue'

type RowAction = {
  key: string
  label: string
  title?: string
  disabled?: boolean
  tone?: 'default' | 'danger'
}

withDefaults(
  defineProps<{
    actions: RowAction[]
    label?: string
    disabled?: boolean
  }>(),
  {
    label: 'Actions',
    disabled: false,
  },
)

const emit = defineEmits<{
  select: [key: string]
}>()

const rootEl = ref<HTMLElement | null>(null)
const menuOpen = ref(false)

function toggleMenu() {
  menuOpen.value = !menuOpen.value
}

function closeMenu() {
  menuOpen.value = false
}

function selectAction(key: string) {
  emit('select', key)
  closeMenu()
}

function handleDocumentPointerDown(event: PointerEvent) {
  if (!menuOpen.value) return
  const target = event.target as Node | null
  if (target && rootEl.value?.contains(target)) return
  closeMenu()
}

onMounted(() => {
  document.addEventListener('pointerdown', handleDocumentPointerDown)
})

onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', handleDocumentPointerDown)
})
</script>
