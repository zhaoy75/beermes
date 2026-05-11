<template>
  <flat-pickr
    v-bind="$attrs"
    v-model="pickerValue"
    :config="pickerConfig"
  />
</template>

<script setup lang="ts">
import { computed } from 'vue'
import flatPickr from 'vue-flatpickr-component'
import { Japanese } from 'flatpickr/dist/l10n/ja.js'
import { useI18n } from 'vue-i18n'

const props = withDefaults(defineProps<{
  modelValue: unknown
  mode?: 'date' | 'datetime'
}>(), {
  mode: 'date',
})

const emit = defineEmits<{
  (e: 'update:modelValue', value: string): void
  (e: 'change', value: string): void
}>()

const { locale } = useI18n()

const pickerValue = computed({
  get: () => props.modelValue == null ? '' : String(props.modelValue),
  set: (value) => {
    const normalizedValue = typeof value === 'string' ? value : ''
    emit('update:modelValue', normalizedValue)
    emit('change', normalizedValue)
  },
})

const pickerConfig = computed(() => ({
  allowInput: true,
  dateFormat: props.mode === 'datetime' ? 'Y-m-d\\TH:i' : 'Y-m-d',
  disableMobile: true,
  enableTime: props.mode === 'datetime',
  locale: String(locale.value ?? '').toLowerCase().startsWith('ja') ? Japanese : undefined,
  minuteIncrement: 1,
  time_24hr: true,
}))
</script>
