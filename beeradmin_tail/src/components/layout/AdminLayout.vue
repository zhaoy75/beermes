<template>
  <div class="min-h-screen xl:flex">
    <app-sidebar />
    <Backdrop />
    <div
      class="flex-1 transition-all duration-300 ease-in-out"
      :class="[isExpanded || isHovered ? 'lg:ml-[240px]' : 'lg:ml-[90px]']"
    >
      <app-header />
      <div class="p-4 mx-auto max-w-(--breakpoint-2xl) md:p-6">
        <slot></slot>
      </div>
    </div>

    <InventorySearchModal
      v-if="isInventorySearchOpen"
      ref="inventorySearchModalRef"
      :site-id="inventorySearchOptions.siteId ?? ''"
      :site-locked="Boolean(inventorySearchOptions.siteLocked)"
      :selectable="Boolean(inventorySearchOptions.onSelect)"
      @close="closeInventorySearch"
      @select="handleInventorySearchSelect"
    />
  </div>
</template>

<script setup lang="ts">
import { nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import InventorySearchModal from '@/components/inventory/InventorySearchModal.vue'
import {
  closeInventorySearch as closeInventorySearchState,
  openInventorySearch as openInventorySearchState,
  resolveInventorySearchOpenOptions,
  useInventorySearchModal,
  type InventorySearchSelection,
} from '@/composables/useInventorySearchModal'
import { useSidebar } from '@/composables/useSidebar'
import AppSidebar from './AppSidebar.vue'
import AppHeader from './AppHeader.vue'
import Backdrop from './Backdrop.vue'

type InventorySearchModalExposed = {
  focusFirstField: () => Promise<void> | void
}

const { isExpanded, isHovered } = useSidebar()

const { isInventorySearchOpen, inventorySearchOptions } = useInventorySearchModal()
const inventorySearchModalRef = ref<InventorySearchModalExposed | null>(null)
const previouslyFocusedElement = ref<HTMLElement | null>(null)

async function focusInventorySearch() {
  await nextTick()
  await inventorySearchModalRef.value?.focusFirstField?.()
}

async function openInventorySearch() {
  if (!isInventorySearchOpen.value) {
    previouslyFocusedElement.value =
      document.activeElement instanceof HTMLElement ? document.activeElement : null
    openInventorySearchState(resolveInventorySearchOpenOptions())
  }
  await focusInventorySearch()
}

async function closeInventorySearch(focusOverride?: (() => void) | null) {
  closeInventorySearchState()
  const previous = previouslyFocusedElement.value
  previouslyFocusedElement.value = null
  await nextTick()
  if (focusOverride) {
    focusOverride()
    return
  }
  if (previous && previous.isConnected) previous.focus()
}

async function handleInventorySearchSelect(row: InventorySearchSelection) {
  const onSelect = inventorySearchOptions.value.onSelect
  const afterSelectFocus = inventorySearchOptions.value.afterSelectFocus
  onSelect?.(row)
  await closeInventorySearch(afterSelectFocus ? () => afterSelectFocus(row) : null)
}

function handleGlobalKeydown(event: KeyboardEvent) {
  if (event.defaultPrevented) return
  const isShortcut =
    event.key.toLowerCase() === 'i' &&
    (event.ctrlKey || event.metaKey) &&
    !event.altKey &&
    !event.shiftKey

  if (isShortcut) {
    event.preventDefault()
    openInventorySearch().catch?.(() => undefined)
    return
  }

  if (event.key === 'Escape' && isInventorySearchOpen.value) {
    event.preventDefault()
    closeInventorySearch().catch?.(() => undefined)
  }
}

onMounted(() => {
  window.addEventListener('keydown', handleGlobalKeydown)
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', handleGlobalKeydown)
})
</script>
