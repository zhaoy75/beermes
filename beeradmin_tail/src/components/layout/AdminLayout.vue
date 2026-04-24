<template>
  <div class="min-h-screen xl:flex">
    <app-sidebar />
    <Backdrop />
    <div
      class="flex-1 transition-all duration-300 ease-in-out"
      :class="[isExpanded || isHovered ? 'lg:ml-[240px]' : 'lg:ml-[90px]']"
    >
      <app-header />
      <div class="w-full p-4 md:p-6">
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

    <TypeDefGraphModal
      v-if="isTypeDefGraphOpen"
      ref="typeDefGraphModalRef"
      @close="closeTypeDefGraph"
      @select="handleTypeDefGraphSelect"
    />
  </div>
</template>

<script setup lang="ts">
import { nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import InventorySearchModal from '@/components/inventory/InventorySearchModal.vue'
import TypeDefGraphModal from '@/components/type-def/TypeDefGraphModal.vue'
import {
  closeInventorySearch as closeInventorySearchState,
  openInventorySearch as openInventorySearchState,
  resolveInventorySearchOpenOptions,
  useInventorySearchModal,
  type InventorySearchSelection,
} from '@/composables/useInventorySearchModal'
import {
  closeTypeDefGraph as closeTypeDefGraphState,
  openTypeDefGraph as openTypeDefGraphState,
  useTypeDefGraphModal,
  type TypeDefGraphSelection,
} from '@/composables/useTypeDefGraphModal'
import { useSidebar } from '@/composables/useSidebar'
import AppSidebar from './AppSidebar.vue'
import AppHeader from './AppHeader.vue'
import Backdrop from './Backdrop.vue'

type InventorySearchModalExposed = {
  focusFirstField: () => Promise<void> | void
}

type TypeDefGraphModalExposed = {
  focusFirstField: () => Promise<void> | void
}

const { isExpanded, isHovered } = useSidebar()

const { isInventorySearchOpen, inventorySearchOptions } = useInventorySearchModal()
const { isTypeDefGraphOpen, typeDefGraphOptions } = useTypeDefGraphModal()
const inventorySearchModalRef = ref<InventorySearchModalExposed | null>(null)
const typeDefGraphModalRef = ref<TypeDefGraphModalExposed | null>(null)
const previouslyFocusedElement = ref<HTMLElement | null>(null)

async function focusInventorySearch() {
  await nextTick()
  await inventorySearchModalRef.value?.focusFirstField?.()
}

async function focusTypeDefGraph() {
  await nextTick()
  await typeDefGraphModalRef.value?.focusFirstField?.()
}

async function openInventorySearch() {
  if (isTypeDefGraphOpen.value) return
  if (!isInventorySearchOpen.value) {
    previouslyFocusedElement.value =
      document.activeElement instanceof HTMLElement ? document.activeElement : null
    openInventorySearchState(resolveInventorySearchOpenOptions())
  }
  await focusInventorySearch()
}

async function openTypeDefGraph() {
  if (isInventorySearchOpen.value) return
  if (!isTypeDefGraphOpen.value) {
    previouslyFocusedElement.value =
      document.activeElement instanceof HTMLElement ? document.activeElement : null
    openTypeDefGraphState()
  }
  await focusTypeDefGraph()
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

async function closeTypeDefGraph(focusOverride?: (() => void) | null) {
  const shouldRestoreFocus = typeDefGraphOptions.value.restoreFocusOnClose !== false
  closeTypeDefGraphState()
  const previous = previouslyFocusedElement.value
  previouslyFocusedElement.value = null
  await nextTick()
  if (!shouldRestoreFocus) return
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

async function handleTypeDefGraphSelect(row: TypeDefGraphSelection) {
  const onSelect = typeDefGraphOptions.value.onSelect
  onSelect?.(row)
  await closeTypeDefGraph()
}

function handleGlobalKeydown(event: KeyboardEvent) {
  if (event.defaultPrevented) return
  const isInventoryShortcut =
    event.key.toLowerCase() === 'i' &&
    (event.ctrlKey || event.metaKey) &&
    !event.altKey &&
    !event.shiftKey
  const isTypeDefShortcut =
    event.key.toLowerCase() === 't' &&
    (event.ctrlKey || event.metaKey) &&
    !event.altKey &&
    !event.shiftKey

  if (isInventoryShortcut) {
    event.preventDefault()
    openInventorySearch().catch?.(() => undefined)
    return
  }

  if (isTypeDefShortcut) {
    event.preventDefault()
    openTypeDefGraph().catch?.(() => undefined)
    return
  }

  if (event.key === 'Escape' && isTypeDefGraphOpen.value) {
    event.preventDefault()
    closeTypeDefGraph().catch?.(() => undefined)
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
