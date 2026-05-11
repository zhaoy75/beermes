<template>
  <Modal v-if="open" @close="emit('close')">
    <template #body>
      <div class="relative mx-4 w-full max-w-3xl overflow-y-auto rounded-3xl bg-white p-6 shadow-xl dark:bg-gray-900 lg:p-8">
        <div class="mb-6">
          <h2 class="text-xl font-semibold text-gray-800 dark:text-white/90">
            {{ mode === 'edit' ? t('equipmentSchedule.modal.editTitle') : t('equipmentSchedule.modal.createTitle') }}
          </h2>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">{{ t('equipmentSchedule.modal.subtitle') }}</p>
        </div>

        <div
          v-if="formError"
          class="mb-4 rounded-xl border border-error-200 bg-error-50 px-4 py-3 text-sm text-error-700 dark:border-error-800/50 dark:bg-error-500/10 dark:text-error-300"
        >
          {{ formError }}
        </div>

        <div class="grid gap-4 md:grid-cols-2">
          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">
              {{ t('equipmentSchedule.modal.fields.type') }}
            </label>
            <select
              v-model="formState.reservation_type"
              class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
              @change="emit('reservationTypeChange')"
            >
              <option v-for="option in reservationTypeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">
              {{ t('equipmentSchedule.modal.fields.equipment') }}
            </label>
            <div v-if="mode === 'edit'" class="flex h-11 items-center rounded-lg border border-gray-300 bg-gray-50 px-3 text-sm text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-200">
              {{ selectedEquipmentLabel }}
            </div>
            <select
              v-else
              v-model="formState.equipment_id"
              class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
            >
              <option value="">{{ t('common.select') }}</option>
              <option v-for="option in equipmentOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">
              {{ t('equipmentSchedule.modal.fields.site') }}
            </label>
            <div class="flex h-11 items-center rounded-lg border border-gray-300 bg-gray-50 px-3 text-sm text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-200">
              {{ selectedSiteLabel }}
            </div>
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">
              {{ t('equipmentSchedule.modal.fields.status') }}
            </label>
            <select
              v-model="formState.status"
              class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
            >
              <option v-for="option in reservationStatusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">
              {{ t('equipmentSchedule.modal.fields.batch') }}
            </label>
            <select
              v-model="formState.batch_id"
              :disabled="formState.reservation_type !== 'batch'"
              class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 disabled:cursor-not-allowed disabled:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:disabled:bg-gray-800"
              @change="emit('batchChange')"
            >
              <option value="">{{ t('common.none') }}</option>
              <option v-for="option in batchOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">
              {{ t('equipmentSchedule.modal.fields.batchStep') }}
            </label>
            <select
              v-model="formState.batch_step_id"
              :disabled="formState.reservation_type !== 'batch' || !formState.batch_id || batchStepLoading"
              class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 disabled:cursor-not-allowed disabled:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:disabled:bg-gray-800"
            >
              <option value="">{{ t('common.none') }}</option>
              <option v-for="option in batchStepOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">
              {{ t('equipmentSchedule.modal.fields.startAt') }}
            </label>
            <AppDateTimePicker
              v-model="formState.start_at"
              mode="datetime"
              class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
            />
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">
              {{ t('equipmentSchedule.modal.fields.endAt') }}
            </label>
            <AppDateTimePicker
              v-model="formState.end_at"
              mode="datetime"
              class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
            />
          </div>

          <div class="md:col-span-2">
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">
              {{ t('equipmentSchedule.modal.fields.note') }}
            </label>
            <textarea
              v-model.trim="formState.note"
              rows="4"
              class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
            ></textarea>
          </div>
        </div>

        <div class="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:items-center sm:justify-between">
          <button
            v-if="mode === 'edit'"
            type="button"
            class="inline-flex items-center justify-center rounded-lg border border-error-300 px-4 py-2 text-sm font-medium text-error-700 hover:bg-error-50 disabled:cursor-not-allowed disabled:opacity-70 dark:border-error-800/60 dark:text-error-300 dark:hover:bg-error-500/10"
            :disabled="saving || deleting"
            @click="emit('delete')"
          >
            {{ deleting ? t('common.deleting') : t('common.delete') }}
          </button>
          <div v-else class="hidden sm:block"></div>
          <div class="flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
            <button
              type="button"
              class="inline-flex items-center justify-center rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-white/[0.03]"
              :disabled="saving || deleting"
              @click="emit('close')"
            >
              {{ t('common.close') }}
            </button>
            <button
              type="button"
              class="inline-flex items-center justify-center rounded-lg bg-brand-500 px-4 py-2 text-sm font-medium text-white hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-70"
              :disabled="saving || deleting"
              @click="emit('save')"
            >
              {{ saving ? t('common.saving') : t('common.save') }}
            </button>
          </div>
        </div>
      </div>
    </template>
  </Modal>
</template>

<script setup lang="ts">
import { reactive, watch } from 'vue'
import { useI18n } from 'vue-i18n'

import AppDateTimePicker from '@/components/common/AppDateTimePicker.vue'
import Modal from '@/components/profile/Modal.vue'

import type { ReservationFormState, SelectOption } from '../equipment-schedule/types'

const props = defineProps<{
  open: boolean
  mode: 'create' | 'edit'
  formError: string
  saving: boolean
  deleting: boolean
  batchStepLoading: boolean
  form: ReservationFormState
  selectedEquipmentLabel: string
  selectedSiteLabel: string
  equipmentOptions: SelectOption[]
  reservationTypeOptions: SelectOption[]
  reservationStatusOptions: SelectOption[]
  batchOptions: SelectOption[]
  batchStepOptions: SelectOption[]
}>()

const emit = defineEmits<{
  close: []
  save: []
  delete: []
  reservationTypeChange: []
  batchChange: []
  'update:form': [value: ReservationFormState]
}>()

const { t } = useI18n()
const localForm = reactive<ReservationFormState>({ ...props.form })
const formState = localForm

watch(
  () => props.form,
  (value) => {
    Object.assign(localForm, value)
  },
  { deep: true, immediate: true },
)

watch(
  localForm,
  (value) => {
    emit('update:form', { ...value })
  },
  { deep: true },
)
</script>
