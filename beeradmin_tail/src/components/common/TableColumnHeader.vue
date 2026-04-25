<template>
  <div ref="rootEl" class="relative" @keydown.escape.stop="menuOpen = false">
    <div
      class="flex w-full items-center gap-1"
      :class="align === 'right' ? 'justify-end text-right' : 'justify-start text-left'"
    >
      <span class="min-w-0 truncate text-xs font-medium uppercase tracking-wide text-gray-600">
        {{ label }}
      </span>
      <button
        class="inline-flex h-6 w-6 shrink-0 items-center justify-center rounded border hover:bg-gray-100"
        :class="hasActiveControl ? 'border-blue-300 bg-blue-50 text-blue-700' : 'border-gray-200 bg-white text-gray-500 hover:text-gray-800'"
        type="button"
        :title="menuButtonTitle"
        :aria-label="menuButtonTitle"
        @click.stop="toggleMenu"
      >
        <svg class="h-3.5 w-3.5" viewBox="0 0 20 20" aria-hidden="true" fill="currentColor">
          <circle cx="5" cy="10" r="1.6" />
          <circle cx="10" cy="10" r="1.6" />
          <circle cx="15" cy="10" r="1.6" />
        </svg>
      </button>
    </div>

    <div
      v-if="menuOpen"
      class="absolute z-30 mt-1 w-52 rounded border border-gray-200 bg-white p-2 text-left normal-case tracking-normal shadow-lg"
      :class="align === 'right' ? 'right-0' : 'left-0'"
    >
      <div class="space-y-1">
        <button
          class="flex w-full items-center justify-between rounded px-2 py-1.5 text-xs font-normal text-gray-700 hover:bg-gray-100"
          :class="isSortAscActive ? 'bg-blue-50 text-blue-700' : ''"
          type="button"
          @click="applySort('asc')"
        >
          <span class="inline-flex items-center gap-2">
            <span aria-hidden="true">▲</span>
            <span>{{ t('common.sortAsc') }}</span>
          </span>
          <span v-if="isSortAscActive" aria-hidden="true">✓</span>
        </button>
        <button
          class="flex w-full items-center justify-between rounded px-2 py-1.5 text-xs font-normal text-gray-700 hover:bg-gray-100"
          :class="isSortDescActive ? 'bg-blue-50 text-blue-700' : ''"
          type="button"
          @click="applySort('desc')"
        >
          <span class="inline-flex items-center gap-2">
            <span aria-hidden="true">▼</span>
            <span>{{ t('common.sortDesc') }}</span>
          </span>
          <span v-if="isSortDescActive" aria-hidden="true">✓</span>
        </button>
      </div>
      <div v-if="hasFilterControl" class="mt-2 border-t border-gray-100 pt-2">
        <div class="mb-1 flex items-center justify-between gap-2">
          <span class="text-xs font-medium text-gray-500">{{ t('common.filter') }}</span>
          <button
            v-if="hasFilter"
            class="text-xs font-normal text-blue-600 hover:text-blue-800"
            type="button"
            @click="clearFilter"
          >
            {{ t('common.clear') }}
          </button>
        </div>
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
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
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
  sort: [key: string, direction?: ColumnSortDirection]
  'update:filterValue': [value: string]
}>()

const { t } = useI18n()
const rootEl = ref<HTMLElement | null>(null)
const filterInput = ref<HTMLInputElement | null>(null)
const menuOpen = ref(false)

const isSortActive = computed(() => props.activeSortKey === props.sortKey)
const isSortAscActive = computed(() => isSortActive.value && props.sortDirection === 'asc')
const isSortDescActive = computed(() => isSortActive.value && props.sortDirection === 'desc')
const hasFilterControl = computed(() => props.filterType !== 'none')
const hasFilter = computed(() => props.filterValue.trim().length > 0)
const hasActiveControl = computed(() => isSortActive.value || hasFilter.value)
const menuButtonTitle = computed(() => {
  if (hasFilter.value) return `${props.label}: ${props.filterValue}`
  return `${props.label} ${t('common.actions')}`
})

function toggleMenu() {
  menuOpen.value = !menuOpen.value
  if (menuOpen.value && props.filterType === 'text') {
    nextTick(() => filterInput.value?.focus())
  }
}

function applySort(direction: ColumnSortDirection) {
  emit('sort', props.sortKey, direction)
  menuOpen.value = false
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
    menuOpen.value = false
  }
}

function handleDocumentPointerDown(event: PointerEvent) {
  if (!menuOpen.value) return
  const target = event.target as Node | null
  if (target && rootEl.value?.contains(target)) return
  menuOpen.value = false
}

onMounted(() => {
  document.addEventListener('pointerdown', handleDocumentPointerDown)
})

onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', handleDocumentPointerDown)
})
</script>
