<template>
  <span
    class="inline-flex items-center rounded-full px-2.5 py-1 text-xs font-medium"
    :class="badgeClass"
  >
    {{ label }}
  </span>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useI18n } from 'vue-i18n'

const props = defineProps<{
  status: 'active' | 'suspended' | 'voided'
}>()

const { t } = useI18n()

const label = computed(() => t(`systemAdmin.status.${props.status}`))
const badgeClass = computed(() => {
  if (props.status === 'active') {
    return 'bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-300'
  }
  if (props.status === 'suspended') {
    return 'bg-amber-100 text-amber-700 dark:bg-amber-900/30 dark:text-amber-300'
  }
  return 'bg-red-100 text-red-700 dark:bg-red-900/30 dark:text-red-300'
})
</script>
