<template>
  <div ref="rootRef" class="relative">
    <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">{{ label }}</label>
    <button
      type="button"
      class="equipment-schedule-dropdown-trigger flex h-11 w-full items-center justify-between rounded-lg border border-gray-300 bg-white px-3 text-left text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
      @click="open = !open"
    >
      <span class="truncate">{{ selectedLabel }}</span>
      <span class="ml-3 text-xs text-gray-500 dark:text-gray-400">{{ open ? '▲' : '▼' }}</span>
    </button>

    <div
      v-if="open"
      class="equipment-schedule-dropdown-panel absolute z-20 mt-2 w-full overflow-auto rounded-xl border border-gray-200 bg-white p-2 shadow-lg dark:border-gray-700 dark:bg-gray-900"
      :class="panelClass"
    >
      <div class="mb-2 flex items-center gap-2 border-b border-gray-200 px-2 pb-2 dark:border-gray-700">
        <button
          type="button"
          class="rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-700 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-200 dark:hover:bg-gray-700"
          @click="selectAll"
        >
          {{ selectAllLabel }}
        </button>
        <button
          type="button"
          class="rounded-md bg-gray-100 px-2 py-1 text-xs font-medium text-gray-700 hover:bg-gray-200 dark:bg-gray-800 dark:text-gray-200 dark:hover:bg-gray-700"
          @click="clearAll"
        >
          {{ clearAllLabel }}
        </button>
      </div>

      <label
        v-for="option in options"
        :key="option.value"
        class="flex cursor-pointer items-center gap-3 rounded-lg px-3 py-2 text-sm text-gray-700 hover:bg-gray-50 dark:text-gray-300 dark:hover:bg-white/[0.03]"
        :style="resolveOptionPadding(option.depth)"
      >
        <input
          :checked="selectedValueSet.has(option.value)"
          type="checkbox"
          class="h-4 w-4 rounded border-gray-300"
          @change="toggleValue(option.value)"
        />
        <span class="truncate">{{ option.label }}</span>
      </label>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'

import type { MultiSelectOption } from '../equipment-schedule/types'

const props = withDefaults(defineProps<{
  label: string
  modelValue: string[]
  options: MultiSelectOption[]
  allLabel: string
  selectAllLabel: string
  clearAllLabel: string
  panelClass?: string
}>(), {
  panelClass: 'max-h-64',
})

const emit = defineEmits<{
  'update:modelValue': [value: string[]]
}>()

const rootRef = ref<HTMLElement | null>(null)
const open = ref(false)

const selectedValueSet = computed(() => new Set(props.modelValue))
const optionLabelByValue = computed(() => new Map(props.options.map((option) => [option.value, option.label])))
const selectedLabel = computed(() => {
  if (props.modelValue.length === 0) return props.allLabel
  if (props.modelValue.length === 1) {
    return optionLabelByValue.value.get(props.modelValue[0]) ?? props.modelValue[0]
  }
  const firstLabel = optionLabelByValue.value.get(props.modelValue[0]) ?? props.modelValue[0]
  return `${firstLabel} +${props.modelValue.length - 1}`
})

function handleDocumentPointerDown(event: PointerEvent) {
  const target = event.target
  if (!open.value || !(target instanceof Node)) return
  if (!rootRef.value?.contains(target)) {
    open.value = false
  }
}

function toggleValue(value: string) {
  if (selectedValueSet.value.has(value)) {
    emit('update:modelValue', props.modelValue.filter((item) => item !== value))
    return
  }
  emit('update:modelValue', [...props.modelValue, value])
}

function selectAll() {
  emit('update:modelValue', props.options.map((option) => option.value))
}

function clearAll() {
  emit('update:modelValue', [])
}

function resolveOptionPadding(depth?: number) {
  if (!depth) return undefined
  return {
    paddingLeft: `${depth * 16 + 12}px`,
  }
}

onMounted(() => {
  document.addEventListener('pointerdown', handleDocumentPointerDown)
})

onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', handleDocumentPointerDown)
})
</script>
