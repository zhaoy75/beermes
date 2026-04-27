<template>
  <td :class="cellClasses">
    <div
      :class="contentClasses"
      :style="contentStyle"
      :title="tooltipText"
      :aria-label="tooltipText"
      :tabindex="focusable && tooltipText ? 0 : undefined"
    >
      <slot>{{ displayValue }}</slot>
    </div>
  </td>
</template>

<script setup lang="ts">
import { computed, type CSSProperties } from 'vue'

const props = withDefaults(
  defineProps<{
    value?: string | number | null
    align?: 'left' | 'right' | 'center'
    maxWidth?: string
    truncate?: boolean
    monospace?: boolean
    numeric?: boolean
    title?: string
    focusable?: boolean
  }>(),
  {
    value: '',
    align: 'left',
    maxWidth: '',
    truncate: false,
    monospace: false,
    numeric: false,
    title: '',
    focusable: false,
  },
)

const displayValue = computed(() => {
  if (props.value == null || props.value === '') return '—'
  return String(props.value)
})

const tooltipText = computed(() => {
  const value = props.title || (props.truncate ? displayValue.value : '')
  return value && value !== '—' ? value : undefined
})

const cellClasses = computed(() => [
  'px-2 py-1.5 align-middle text-sm text-gray-700',
  props.align === 'right' ? 'text-right' : '',
  props.align === 'center' ? 'text-center' : '',
  props.numeric ? 'tabular-nums' : '',
])

const contentClasses = computed(() => [
  'min-w-0',
  props.truncate ? 'truncate' : 'whitespace-nowrap',
  props.align === 'right' ? 'ml-auto' : '',
  props.align === 'center' ? 'mx-auto' : '',
  props.monospace ? 'font-mono text-xs' : '',
  props.numeric ? 'tabular-nums' : '',
  props.focusable && tooltipText.value
    ? 'rounded-sm focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-1'
    : '',
])

const contentStyle = computed<CSSProperties | undefined>(() => {
  if (!props.maxWidth) return undefined
  return { maxWidth: props.maxWidth }
})
</script>
