<template>
  <div ref="rootEl" class="relative" @keydown.escape.stop="filterOpen = false">
    <div
      class="flex w-full items-center gap-1"
      :class="align === 'right' ? 'justify-end text-right' : 'justify-start text-left'"
    >
      <button
        class="flex min-w-0 items-center gap-1 text-xs font-medium uppercase tracking-wide text-gray-600 hover:text-gray-900"
        type="button"
        @click="emit('sort', sortKey)"
      >
        <span class="truncate">{{ label }}</span>
        <span class="min-w-[1rem] text-[10px] text-gray-500">{{ sortIndicator }}</span>
      </button>
      <button
        v-if="hasFilterControl"
        class="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded border text-gray-500 hover:bg-gray-100 hover:text-gray-800"
        :class="hasFilter ? 'border-blue-300 bg-blue-50 text-blue-700' : 'border-gray-200 bg-white'"
        type="button"
        :title="filterButtonTitle"
        :aria-label="filterButtonTitle"
        @click.stop="openFilter"
      >
        <svg class="h-3.5 w-3.5" viewBox="0 0 20 20" aria-hidden="true" fill="currentColor">
          <path
            d="M3.25 4.5A1 1 0 0 1 4.2 3h11.6a1 1 0 0 1 .78 1.63L12 10.31V15a1 1 0 0 1-.45.83l-2 1.32A1 1 0 0 1 8 16.32v-6.01L3.42 4.63a1 1 0 0 1-.17-.13Z"
          />
        </svg>
      </button>
    </div>

    <div
      v-if="hasFilterControl && filterOpen"
      class="absolute z-30 mt-1 w-44 rounded border border-gray-200 bg-white p-2 text-left normal-case tracking-normal shadow-lg"
      :class="align === 'right' ? 'right-0' : 'left-0'"
    >
      <select
        v-if="filterType === 'select'"
        :value="filterValue"
        class="h-8 w-full rounded border border-gray-200 bg-white px-2 text-xs font-normal text-gray-700"
        @change="handleFilterChange"
      >
        <option value="">{{ allLabel }}</option>
        <option v-for="option in filterOptions" :key="option.value" :value="option.value">
          {{ option.label }}
        </option>
      </select>
      <input
        v-else-if="filterType === 'text'"
        ref="filterInput"
        :value="filterValue"
        class="h-8 w-full rounded border border-gray-200 px-2 text-xs font-normal text-gray-700"
        :placeholder="filterPlaceholder || label"
        type="search"
        @input="handleFilterChange"
      />
      <div v-if="hasFilter" class="mt-2 flex justify-end">
        <button
          class="inline-flex h-6 w-6 items-center justify-center rounded text-gray-600 hover:bg-gray-100 hover:text-gray-900"
          type="button"
          title="Clear filter"
          aria-label="Clear filter"
          @click="clearFilter"
        >
          <svg class="h-3.5 w-3.5" viewBox="0 0 20 20" aria-hidden="true" fill="currentColor">
            <path
              d="M5.22 5.22a.75.75 0 0 1 1.06 0L10 8.94l3.72-3.72a.75.75 0 1 1 1.06 1.06L11.06 10l3.72 3.72a.75.75 0 1 1-1.06 1.06L10 11.06l-3.72 3.72a.75.75 0 1 1-1.06-1.06L8.94 10 5.22 6.28a.75.75 0 0 1 0-1.06Z"
            />
          </svg>
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import type { ColumnFilterType, ColumnSortDirection } from '@/composables/useColumnTableControls'

type FilterOption = {
  value: string
  label: string
}

const props = withDefaults(
  defineProps<{
    label: string
    sortKey: string
    activeSortKey: string
    sortDirection: ColumnSortDirection
    filterValue: string
    filterType?: ColumnFilterType
    filterOptions?: FilterOption[]
    filterPlaceholder?: string
    allLabel?: string
    align?: 'left' | 'right'
  }>(),
  {
    filterType: 'text',
    filterOptions: () => [],
    filterPlaceholder: '',
    allLabel: 'All',
    align: 'left',
  },
)

const emit = defineEmits<{
  sort: [key: string]
  'update:filterValue': [value: string]
}>()

const rootEl = ref<HTMLElement | null>(null)
const filterInput = ref<HTMLInputElement | null>(null)
const filterOpen = ref(false)

const sortIndicator = computed(() => {
  if (props.activeSortKey !== props.sortKey) return '↕'
  return props.sortDirection === 'asc' ? '▲' : '▼'
})

const hasFilterControl = computed(() => props.filterType !== 'none')
const hasFilter = computed(() => props.filterValue.trim().length > 0)
const filterButtonTitle = computed(() => {
  if (!hasFilter.value) return props.filterPlaceholder || props.label
  return `${props.label}: ${props.filterValue}`
})

function openFilter() {
  filterOpen.value = !filterOpen.value
  if (filterOpen.value && props.filterType === 'text') {
    nextTick(() => filterInput.value?.focus())
  }
}

function clearFilter() {
  emit('update:filterValue', '')
  if (props.filterType === 'text') {
    nextTick(() => filterInput.value?.focus())
  }
}

function handleFilterChange(event: Event) {
  const target = event.target as HTMLInputElement | HTMLSelectElement | null
  emit('update:filterValue', target?.value ?? '')
  if (props.filterType === 'select') {
    filterOpen.value = false
  }
}

function handleDocumentPointerDown(event: PointerEvent) {
  if (!filterOpen.value) return
  const target = event.target as Node | null
  if (target && rootEl.value?.contains(target)) return
  filterOpen.value = false
}

onMounted(() => {
  document.addEventListener('pointerdown', handleDocumentPointerDown)
})

onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', handleDocumentPointerDown)
})
</script>
