<template>
  <div class="space-y-1">
    <button
      class="flex w-full items-center gap-1 text-xs font-medium uppercase tracking-wide text-gray-600 hover:text-gray-900"
      :class="align === 'right' ? 'justify-end text-right' : 'justify-start text-left'"
      type="button"
      @click="emit('sort', sortKey)"
    >
      <span>{{ label }}</span>
      <span class="min-w-[1rem] text-[10px] text-gray-500">{{ sortIndicator }}</span>
    </button>
    <select
      v-if="filterType === 'select'"
      :value="filterValue"
      class="h-8 w-full min-w-[7rem] rounded border border-gray-200 bg-white px-2 text-xs font-normal normal-case tracking-normal text-gray-700"
      @change="handleFilterChange"
    >
      <option value="">{{ allLabel }}</option>
      <option v-for="option in filterOptions" :key="option.value" :value="option.value">
        {{ option.label }}
      </option>
    </select>
    <input
      v-else-if="filterType === 'text'"
      :value="filterValue"
      class="h-8 w-full min-w-[7rem] rounded border border-gray-200 px-2 text-xs font-normal normal-case tracking-normal text-gray-700"
      :placeholder="filterPlaceholder"
      type="search"
      @input="handleFilterChange"
    />
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
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

const sortIndicator = computed(() => {
  if (props.activeSortKey !== props.sortKey) return '↕'
  return props.sortDirection === 'asc' ? '▲' : '▼'
})

function handleFilterChange(event: Event) {
  const target = event.target as HTMLInputElement | HTMLSelectElement | null
  emit('update:filterValue', target?.value ?? '')
}
</script>
