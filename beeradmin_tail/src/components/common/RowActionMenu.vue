<template>
  <div ref="rootEl" class="relative inline-flex" @keydown.escape.stop="closeMenu">
    <button
      ref="triggerEl"
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

    <Teleport to="body">
      <div
        v-if="menuOpen"
        ref="menuEl"
        class="fixed z-[9999] w-48 rounded border border-gray-200 bg-white p-1 text-left shadow-lg"
        :style="menuStyle"
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
    </Teleport>
  </div>
</template>

<script setup lang="ts">
import { nextTick, onBeforeUnmount, onMounted, ref, type CSSProperties } from 'vue'

type RowAction = {
  key: string
  label: string
  title?: string
  disabled?: boolean
  tone?: 'default' | 'danger'
}

const props = withDefaults(
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
const triggerEl = ref<HTMLElement | null>(null)
const menuEl = ref<HTMLElement | null>(null)
const menuOpen = ref(false)
const menuStyle = ref<CSSProperties>({
  left: '0px',
  top: '0px',
})

function toggleMenu() {
  menuOpen.value = !menuOpen.value
  if (menuOpen.value) {
    nextTick(updateMenuPosition)
  }
}

function closeMenu() {
  menuOpen.value = false
}

function selectAction(key: string) {
  emit('select', key)
  closeMenu()
}

function updateMenuPosition() {
  const trigger = triggerEl.value
  if (!trigger) return

  const rect = trigger.getBoundingClientRect()
  const gap = 4
  const viewportPadding = 8
  const menuWidth = 192
  const menuHeight = menuEl.value?.offsetHeight ?? Math.min(props.actions.length * 36 + 8, 240)
  const maxLeft = window.innerWidth - menuWidth - viewportPadding
  const preferredLeft = rect.right - menuWidth
  const left = Math.max(viewportPadding, Math.min(preferredLeft, maxLeft))
  const hasRoomBelow = window.innerHeight - rect.bottom >= menuHeight + gap + viewportPadding
  const preferredTop = hasRoomBelow ? rect.bottom + gap : rect.top - menuHeight - gap
  const top = Math.max(viewportPadding, preferredTop)

  menuStyle.value = {
    left: `${left}px`,
    top: `${top}px`,
  }
}

function handleDocumentPointerDown(event: PointerEvent) {
  if (!menuOpen.value) return
  const target = event.target as Node | null
  if (target && rootEl.value?.contains(target)) return
  if (target && menuEl.value?.contains(target)) return
  closeMenu()
}

function handleFloatingBoundaryChange() {
  if (!menuOpen.value) return
  updateMenuPosition()
}

onMounted(() => {
  document.addEventListener('pointerdown', handleDocumentPointerDown)
  window.addEventListener('resize', handleFloatingBoundaryChange)
  window.addEventListener('scroll', handleFloatingBoundaryChange, true)
})

onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', handleDocumentPointerDown)
  window.removeEventListener('resize', handleFloatingBoundaryChange)
  window.removeEventListener('scroll', handleFloatingBoundaryChange, true)
})
</script>
