<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="equipment-schedule-page space-y-4">
      <section class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-white/[0.03]">
        <div class="mb-4 flex flex-col gap-3 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <h1 class="text-xl font-semibold text-gray-800 dark:text-white/90">{{ t('equipmentSchedule.title') }}</h1>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">{{ t('equipmentSchedule.subtitle') }}</p>
          </div>
          <button
            type="button"
            class="inline-flex items-center justify-center rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-white/[0.03]"
            :disabled="loading"
            @click="refreshBoard"
          >
            {{ t('common.refresh') }}
          </button>
        </div>

        <div class="grid gap-4 md:grid-cols-2 xl:grid-cols-6">
          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">{{ t('equipmentSchedule.filters.site') }}</label>
            <select
              v-model="filters.siteIds"
              multiple
              class="equipment-schedule-select h-32 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
            >
              <option v-for="site in siteOptions" :key="site.value" :value="site.value">{{ site.label }}</option>
            </select>
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">{{ t('equipmentSchedule.filters.equipmentType') }}</label>
            <select
              v-model="filters.equipmentTypeIds"
              multiple
              class="equipment-schedule-select h-32 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
            >
              <option v-for="type in equipmentTypeOptions" :key="type.value" :value="type.value">{{ type.label }}</option>
            </select>
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">{{ t('equipmentSchedule.filters.equipment') }}</label>
            <select
              v-model="filters.equipmentIds"
              multiple
              class="equipment-schedule-select h-32 w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
            >
              <option v-for="equipment in equipmentOptions" :key="equipment.value" :value="equipment.value">{{ equipment.label }}</option>
            </select>
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">{{ t('equipmentSchedule.filters.dateFrom') }}</label>
            <input
              v-model="filters.rangeStart"
              type="date"
              class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
            />
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">{{ t('equipmentSchedule.filters.dateTo') }}</label>
            <input
              v-model="filters.rangeEnd"
              type="date"
              class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
            />
          </div>

          <div>
            <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">{{ t('equipmentSchedule.filters.viewMode') }}</label>
            <select
              v-model="filters.viewMode"
              class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
            >
              <option value="day">{{ t('equipmentSchedule.views.day') }}</option>
              <option value="week">{{ t('equipmentSchedule.views.week') }}</option>
            </select>
          </div>
        </div>

        <div class="mt-4 flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div class="flex flex-wrap items-center gap-4 text-sm text-gray-700 dark:text-gray-300">
            <label class="inline-flex items-center gap-2">
              <input v-model="filters.showCompleted" type="checkbox" class="h-4 w-4 rounded border-gray-300" />
              <span>{{ t('equipmentSchedule.filters.showCompleted') }}</span>
            </label>
            <label class="inline-flex items-center gap-2">
              <input v-model="filters.showActualUsage" type="checkbox" class="h-4 w-4 rounded border-gray-300" />
              <span>{{ t('equipmentSchedule.filters.showActualUsage') }}</span>
            </label>
          </div>

          <div class="flex flex-wrap items-center gap-2">
            <button
              type="button"
              class="inline-flex items-center justify-center rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-white/[0.03]"
              @click="handleReset"
            >
              {{ t('common.reset') }}
            </button>
            <button
              type="button"
              class="inline-flex items-center justify-center rounded-lg bg-brand-500 px-4 py-2 text-sm font-medium text-white hover:bg-brand-600"
              @click="handleSearch"
            >
              {{ t('common.search') }}
            </button>
          </div>
        </div>
      </section>

      <section class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-white/[0.03]">
        <div class="flex flex-wrap items-center gap-3">
          <div
            v-for="item in legendItems"
            :key="item.key"
            class="inline-flex items-center gap-2 rounded-full border border-gray-200 px-3 py-1.5 text-sm text-gray-700 dark:border-gray-700 dark:text-gray-300"
          >
            <span class="h-3 w-3 rounded-full" :class="item.dotClass"></span>
            <span>{{ item.label }}</span>
          </div>
        </div>
      </section>

      <section class="rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-white/[0.03]">
        <div v-if="loading" class="py-12 text-center text-sm text-gray-500 dark:text-gray-400">{{ t('common.loading') }}</div>
        <div v-else-if="loadError" class="rounded-xl border border-error-200 bg-error-50 px-4 py-3 text-sm text-error-700 dark:border-error-800/50 dark:bg-error-500/10 dark:text-error-300">
          {{ loadError }}
        </div>
        <div v-else-if="groupedSiteRows.length === 0" class="py-12 text-center text-sm text-gray-500 dark:text-gray-400">
          {{ t('equipmentSchedule.empty') }}
        </div>
        <div v-else class="space-y-4">
          <section
            v-for="siteGroup in groupedSiteRows"
            :key="siteGroup.siteId"
            class="rounded-2xl border border-gray-200 bg-gray-50/70 dark:border-gray-700 dark:bg-gray-900/40"
          >
            <header class="flex flex-col gap-3 border-b border-gray-200 px-4 py-3 sm:flex-row sm:items-center sm:justify-between dark:border-gray-700">
              <div>
                <h2 class="text-lg font-semibold text-gray-800 dark:text-white/90">{{ siteGroup.siteLabel }}</h2>
                <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
                  {{ t('equipmentSchedule.siteSummary', { count: siteGroup.rows.length }) }}
                </p>
              </div>
              <button
                type="button"
                class="inline-flex items-center justify-center rounded-lg border border-gray-300 px-3 py-2 text-sm font-medium text-gray-700 hover:bg-white dark:border-gray-600 dark:text-gray-300 dark:hover:bg-white/[0.03]"
                @click="toggleSite(siteGroup.siteId)"
              >
                {{ isSiteCollapsed(siteGroup.siteId) ? t('common.expand') : t('common.collapse') }}
              </button>
            </header>

            <div v-if="!isSiteCollapsed(siteGroup.siteId)" class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200 text-sm dark:divide-gray-700">
                <thead class="bg-white/80 dark:bg-gray-900/50">
                  <tr>
                    <th class="px-4 py-3 text-left font-semibold text-gray-600 dark:text-gray-300">
                      {{ t('equipmentSchedule.filters.equipment') }}
                    </th>
                    <th class="px-4 py-3 text-left font-semibold text-gray-600 dark:text-gray-300">
                      {{ t('equipmentSchedule.filters.equipmentType') }}
                    </th>
                    <th class="px-4 py-3 text-left font-semibold text-gray-600 dark:text-gray-300">
                      {{ t('equipmentSchedule.modal.fields.status') }}
                    </th>
                    <th class="px-4 py-3 text-right font-semibold text-gray-600 dark:text-gray-300">
                      {{ t('equipmentSchedule.legend.reservation') }}
                    </th>
                    <th class="px-4 py-3 text-right font-semibold text-gray-600 dark:text-gray-300">
                      {{ t('equipmentSchedule.legend.actualUsage') }}
                    </th>
                    <th class="px-4 py-3 text-right font-semibold text-gray-600 dark:text-gray-300">
                      {{ t('common.actions') }}
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200 bg-white/70 dark:divide-gray-700 dark:bg-transparent">
                  <tr
                    v-for="row in siteGroup.rows"
                    :key="row.equipment.id"
                    class="align-middle hover:bg-gray-50/80 dark:hover:bg-white/[0.03]"
                  >
                    <td class="px-4 py-3">
                      <div class="text-xs font-mono text-gray-500 dark:text-gray-400">{{ row.equipment.equipment_code }}</div>
                      <div class="mt-1 text-sm font-semibold text-gray-800 dark:text-white/90">
                        {{ equipmentDisplayName(row.equipment) || t('equipment.nameFallback') }}
                      </div>
                    </td>
                    <td class="px-4 py-3 text-sm text-gray-600 dark:text-gray-300">
                      {{ equipmentTypeLabel(row.equipment.equipment_type_id) }}
                    </td>
                    <td class="px-4 py-3">
                      <span class="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-600 dark:bg-gray-800 dark:text-gray-300">
                        {{ equipmentStatusLabel(row.equipment.equipment_status) }}
                      </span>
                    </td>
                    <td class="px-4 py-3 text-right text-sm font-medium text-gray-700 dark:text-gray-200">
                      {{ row.reservationCount }}
                    </td>
                    <td class="px-4 py-3 text-right text-sm font-medium text-gray-700 dark:text-gray-200">
                      {{ row.actualCount }}
                    </td>
                    <td class="px-4 py-3 text-right">
                      <button
                        type="button"
                        class="inline-flex items-center justify-center rounded-lg bg-brand-500 px-3 py-2 text-sm font-medium text-white hover:bg-brand-600"
                        @click="openCreateModalForRow(row.equipment)"
                      >
                        {{ t('equipmentSchedule.actions.newReservation') }}
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <section class="equipment-schedule-panel--board rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-white/[0.03]">
            <div v-if="boardEquipmentRows.length === 0" class="py-12 text-center text-sm text-gray-500 dark:text-gray-400">
              {{ t('equipmentSchedule.empty') }}
            </div>
            <div
              v-else
              ref="timelineContainerRef"
              class="equipment-board-gantt"
            ></div>
          </section>
        </div>
      </section>
    </div>

    <Modal v-if="modalOpen" @close="closeModal">
      <template #body>
        <div class="relative mx-4 w-full max-w-3xl overflow-y-auto rounded-3xl bg-white p-6 shadow-xl dark:bg-gray-900 lg:p-8">
          <div class="mb-6">
            <h2 class="text-xl font-semibold text-gray-800 dark:text-white/90">
              {{ modalMode === 'edit' ? t('equipmentSchedule.modal.editTitle') : t('equipmentSchedule.modal.createTitle') }}
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
                v-model="reservationForm.reservation_type"
                class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
                @change="handleReservationTypeChange"
              >
                <option v-for="option in reservationTypeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
              </select>
            </div>

            <div>
              <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">
                {{ t('equipmentSchedule.modal.fields.equipment') }}
              </label>
              <div v-if="modalMode === 'edit'" class="flex h-11 items-center rounded-lg border border-gray-300 bg-gray-50 px-3 text-sm text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-200">
                {{ selectedEquipmentLabel }}
              </div>
              <select
                v-else
                v-model="reservationForm.equipment_id"
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
                v-model="reservationForm.status"
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
                v-model="reservationForm.batch_id"
                :disabled="reservationForm.reservation_type !== 'batch'"
                class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 disabled:cursor-not-allowed disabled:bg-gray-50 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:disabled:bg-gray-800"
                @change="handleBatchChange"
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
                v-model="reservationForm.batch_step_id"
                :disabled="reservationForm.reservation_type !== 'batch' || !reservationForm.batch_id || batchStepLoading"
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
              <input
                v-model="reservationForm.start_at"
                type="datetime-local"
                class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
              />
            </div>

            <div>
              <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">
                {{ t('equipmentSchedule.modal.fields.endAt') }}
              </label>
              <input
                v-model="reservationForm.end_at"
                type="datetime-local"
                class="h-11 w-full rounded-lg border border-gray-300 bg-white px-3 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
              />
            </div>

            <div class="md:col-span-2">
              <label class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-300">
                {{ t('equipmentSchedule.modal.fields.note') }}
              </label>
              <textarea
                v-model.trim="reservationForm.note"
                rows="4"
                class="w-full rounded-lg border border-gray-300 bg-white px-3 py-2 text-sm text-gray-800 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
              ></textarea>
            </div>
          </div>

          <div class="mt-6 flex flex-col-reverse gap-3 sm:flex-row sm:justify-end">
            <button
              type="button"
              class="inline-flex items-center justify-center rounded-lg border border-gray-300 px-4 py-2 text-sm font-medium text-gray-700 hover:bg-gray-50 dark:border-gray-700 dark:text-gray-300 dark:hover:bg-white/[0.03]"
              @click="closeModal"
            >
              {{ t('common.close') }}
            </button>
            <button
              type="button"
              class="inline-flex items-center justify-center rounded-lg bg-brand-500 px-4 py-2 text-sm font-medium text-white hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-70"
              :disabled="saving"
              @click="saveReservation"
            >
              {{ saving ? t('common.saving') : t('common.save') }}
            </button>
          </div>
        </div>
      </template>
    </Modal>
  </AdminLayout>
</template>

<script setup lang="ts">
import 'vis-timeline/styles/vis-timeline-graph2d.min.css'

import { computed, nextTick, onBeforeUnmount, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import { toast } from 'vue3-toastify'
import { DataSet } from 'vis-data'
import {
  Timeline,
  type DataGroup,
  type DataItem,
  type TimelineEventPropertiesResult,
  type TimelineOptions,
} from 'vis-timeline'

import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import Modal from '@/components/profile/Modal.vue'
import { supabase } from '@/lib/supabase'

type NameI18n = Record<string, string> | null
type RowRecord = Record<string, unknown>

interface SiteRow {
  id: string
  name: string
}

interface EquipmentTypeRow {
  type_id: string
  code: string | null
  name: string | null
  name_i18n: NameI18n
  sort_order: number | null
}

interface EquipmentRow {
  id: string
  equipment_code: string
  name_i18n: NameI18n
  equipment_type_id: string | null
  equipment_kind: string | null
  site_id: string
  equipment_status: string | null
  is_active: boolean
  sort_order: number | null
}

interface ReservationRow {
  id: string
  site_id: string
  equipment_id: string
  reservation_type: string
  batch_id: string | null
  batch_step_id: string | null
  start_at: string
  end_at: string
  status: string
  note: string | null
  created_at: string | null
  updated_at: string | null
}

interface AssignmentRow {
  id: string
  batch_id: string | null
  batch_step_id: string | null
  reservation_id: string | null
  equipment_id: string
  assignment_role: string | null
  status: string
  assigned_at: string | null
  released_at: string | null
  note: string | null
  updated_at: string | null
}

interface BatchRow {
  id: string
  batch_code: string
  batch_label: string | null
  status: string | null
}

interface StepRow {
  id: string
  batch_id: string
  step_no: number | null
  step_name: string | null
  step_code: string | null
}

interface FilterState {
  siteIds: string[]
  equipmentTypeIds: string[]
  equipmentIds: string[]
  rangeStart: string
  rangeEnd: string
  viewMode: 'day' | 'week'
  showCompleted: boolean
  showActualUsage: boolean
}

interface ReservationFormState {
  id: string | null
  reservation_type: string
  equipment_id: string
  batch_id: string
  batch_step_id: string
  start_at: string
  end_at: string
  status: string
  note: string
}

interface SelectOption {
  value: string
  label: string
}

interface TimelineGroupMeta {
  equipmentId: string
  siteId: string
}

interface BoardTimelineGroup extends DataGroup {
  id: string
  content: string
  title: string
  className?: string
  nestedGroups?: string[]
  treeLevel?: number
  _meta: TimelineGroupMeta
}

interface TimelineItemMeta {
  kind: 'reservation' | 'actual'
  reservationId?: string
  reservationType?: string
  batchId?: string
  batchStepId?: string
  equipmentId: string
  status?: string
  hasConflict?: boolean
  label?: string
}

interface BoardTimelineItem extends DataItem {
  id: string
  group: string
  content: string
  title: string
  className?: string
  start: Date
  end?: Date
  type: 'range'
  _meta: TimelineItemMeta
}

interface EquipmentScheduleRow {
  equipment: EquipmentRow
  reservationCount: number
  actualCount: number
}

interface SiteScheduleGroup {
  siteId: string
  siteLabel: string
  rows: EquipmentScheduleRow[]
}

interface VisibleAssignmentRow {
  row: AssignmentRow
  hasConflict: boolean
}

const mesClient = () => supabase.schema('mes')
const { t, locale } = useI18n()
const router = useRouter()
const route = useRoute()

const pageTitle = computed(() => t('equipmentSchedule.title'))

const loading = ref(false)
const loadError = ref('')
const saving = ref(false)
const batchStepLoading = ref(false)

const siteRows = ref<SiteRow[]>([])
const equipmentTypeRows = ref<EquipmentTypeRow[]>([])
const equipmentRows = ref<EquipmentRow[]>([])
const reservationRows = ref<ReservationRow[]>([])
const assignmentRows = ref<AssignmentRow[]>([])
const batchRows = ref<BatchRow[]>([])
const stepRowsById = ref<Record<string, StepRow>>({})
const batchStepsByBatch = ref<Record<string, StepRow[]>>({})
const collapsedSiteIds = ref<string[]>([])
const timelineContainerRef = ref<HTMLElement | null>(null)
const timelineInstance = ref<Timeline | null>(null)

const filters = reactive<FilterState>(createDefaultFilters())

const modalOpen = ref(false)
const modalMode = ref<'create' | 'edit'>('create')
const formError = ref('')
const reservationForm = reactive<ReservationFormState>(createEmptyReservationForm())

const reservationTypeValues = ['batch', 'maintenance', 'cip', 'manual_block'] as const
const reservationStatusValues = ['draft', 'reserved', 'confirmed', 'in_progress', 'completed', 'cancelled'] as const
const assignmentCompletedStatuses = new Set(['done', 'cancelled'])
const reservationCompletedStatuses = new Set(['completed', 'cancelled'])
const activeReservationStatuses = new Set(['draft', 'reserved', 'confirmed', 'in_progress'])

const legendItems = computed(() => [
  { key: 'reservation', label: t('equipmentSchedule.legend.reservation'), dotClass: 'bg-blue-600' },
  { key: 'actual', label: t('equipmentSchedule.legend.actualUsage'), dotClass: 'bg-green-600' },
  { key: 'maintenance', label: t('equipmentSchedule.legend.maintenance'), dotClass: 'bg-red-600' },
  { key: 'completed', label: t('equipmentSchedule.legend.completed'), dotClass: 'bg-gray-400' },
  { key: 'conflict', label: t('equipmentSchedule.legend.conflict'), dotClass: 'bg-amber-500' },
])

const siteMap = computed(() => new Map(siteRows.value.map((row) => [row.id, row])))
const equipmentTypeMap = computed(() => new Map(equipmentTypeRows.value.map((row) => [row.type_id, row])))
const equipmentMap = computed(() => new Map(equipmentRows.value.map((row) => [row.id, row])))
const batchMap = computed(() => new Map(batchRows.value.map((row) => [row.id, row])))

const siteOptions = computed<SelectOption[]>(() =>
  siteRows.value.map((row) => ({
    value: row.id,
    label: row.name || row.id,
  })),
)

const equipmentTypeOptions = computed<SelectOption[]>(() =>
  equipmentTypeRows.value.map((row) => ({
    value: row.type_id,
    label: equipmentTypeLabel(row.type_id),
  })),
)

const equipmentOptions = computed<SelectOption[]>(() =>
  boardEquipmentRows.value.map((row) => ({
    value: row.id,
    label: equipmentFullLabel(row),
  })),
)

const batchOptions = computed<SelectOption[]>(() =>
  batchRows.value.map((row) => ({
    value: row.id,
    label: batchLabel(row.id),
  })),
)

const reservationTypeOptions = computed<SelectOption[]>(() =>
  reservationTypeValues.map((value) => ({
    value,
    label: reservationTypeLabel(value),
  })),
)

const reservationStatusOptions = computed<SelectOption[]>(() =>
  reservationStatusValues.map((value) => ({
    value,
    label: reservationStatusLabel(value),
  })),
)

const batchStepOptions = computed<SelectOption[]>(() => {
  if (!reservationForm.batch_id) return []
  const rows = batchStepsByBatch.value[reservationForm.batch_id] ?? []
  return rows.map((row) => ({
    value: row.id,
    label: stepLabel(row.id),
  }))
})

const selectedEquipment = computed(() => equipmentMap.value.get(reservationForm.equipment_id) ?? null)
const selectedEquipmentLabel = computed(() => (selectedEquipment.value ? equipmentFullLabel(selectedEquipment.value) : t('common.none')))
const selectedSiteLabel = computed(() => siteLabel(selectedEquipment.value?.site_id ?? null))

const boardRange = computed(() => normalizeBoardRange(filters.rangeStart, filters.rangeEnd, filters.viewMode))

const boardEquipmentRows = computed(() => {
  const rows = [...equipmentRows.value]
  rows.sort((a, b) => {
    const siteCompare = siteLabel(a.site_id).localeCompare(siteLabel(b.site_id))
    if (siteCompare !== 0) return siteCompare
    const sortCompare = (a.sort_order ?? 0) - (b.sort_order ?? 0)
    if (sortCompare !== 0) return sortCompare
    return a.equipment_code.localeCompare(b.equipment_code)
  })
  return rows
})

const visibleReservations = computed<ReservationRow[]>(() => {
  const range = boardRange.value
  const equipmentIds = new Set(boardEquipmentRows.value.map((row) => row.id))
  const linkedReservationIds = filters.showActualUsage
    ? new Set(
      assignmentRows.value
        .map((row) => row.reservation_id)
        .filter((value): value is string => Boolean(value)),
    )
    : new Set<string>()

  return reservationRows.value.filter((row) => {
    if (!equipmentIds.has(row.equipment_id)) return false
    if (!filters.showCompleted && reservationCompletedStatuses.has(row.status)) return false
    if (linkedReservationIds.has(row.id)) return false

    const start = new Date(row.start_at)
    const end = new Date(row.end_at)
    return isValidRange(start, end) && intersectsRange(start, end, range.start, range.end)
  })
})

const visibleAssignments = computed<VisibleAssignmentRow[]>(() => {
  if (!filters.showActualUsage) return []

  const range = boardRange.value
  const equipmentIds = new Set(boardEquipmentRows.value.map((row) => row.id))
  const reservationIntervals = reservationRows.value
    .filter((row) => equipmentIds.has(row.equipment_id))
    .filter((row) => activeReservationStatuses.has(row.status))
    .map((row) => ({
      equipmentId: row.equipment_id,
      start: new Date(row.start_at),
      end: new Date(row.end_at),
    }))

  return assignmentRows.value.flatMap((row) => {
    if (!equipmentIds.has(row.equipment_id)) return []
    if (!filters.showCompleted && assignmentCompletedStatuses.has(row.status)) return []

    const start = resolveAssignmentStart(row)
    const end = resolveAssignmentEnd(row)
    if (!start || !end || !isValidRange(start, end) || !intersectsRange(start, end, range.start, range.end)) return []

    const hasConflict = !row.reservation_id && reservationIntervals.some((reservation) =>
      reservation.equipmentId === row.equipment_id && intersectsRange(start, end, reservation.start, reservation.end),
    )

    return [{ row, hasConflict }]
  })
})

const groupedSiteRows = computed<SiteScheduleGroup[]>(() => {
  const reservationCounts = new Map<string, number>()
  const actualCounts = new Map<string, number>()

  for (const row of visibleReservations.value) {
    reservationCounts.set(row.equipment_id, (reservationCounts.get(row.equipment_id) ?? 0) + 1)
  }

  for (const item of visibleAssignments.value) {
    actualCounts.set(item.row.equipment_id, (actualCounts.get(item.row.equipment_id) ?? 0) + 1)
  }

  const groups = new Map<string, SiteScheduleGroup>()

  for (const equipment of boardEquipmentRows.value) {
    const group = groups.get(equipment.site_id) ?? {
      siteId: equipment.site_id,
      siteLabel: siteLabel(equipment.site_id),
      rows: [],
    }

    group.rows.push({
      equipment,
      reservationCount: reservationCounts.get(equipment.id) ?? 0,
      actualCount: actualCounts.get(equipment.id) ?? 0,
    })

    groups.set(equipment.site_id, group)
  }

  return Array.from(groups.values()).sort((a, b) => a.siteLabel.localeCompare(b.siteLabel))
})

const equipmentScheduleSummaryById = computed(() => {
  const summary = new Map<string, { reservations: number, actuals: number }>()

  for (const equipment of boardEquipmentRows.value) {
    summary.set(equipment.id, { reservations: 0, actuals: 0 })
  }

  for (const row of visibleReservations.value) {
    const current = summary.get(row.equipment_id) ?? { reservations: 0, actuals: 0 }
    current.reservations += 1
    summary.set(row.equipment_id, current)
  }

  for (const item of visibleAssignments.value) {
    const current = summary.get(item.row.equipment_id) ?? { reservations: 0, actuals: 0 }
    current.actuals += 1
    summary.set(item.row.equipment_id, current)
  }

  return summary
})

const timelineGroups = computed<BoardTimelineGroup[]>(() =>
  boardEquipmentRows.value.map((equipment) => ({
    id: equipment.id,
    content: equipmentFullLabel(equipment),
    title: [
      equipmentFullLabel(equipment),
      equipmentTypeLabel(equipment.equipment_type_id),
      siteLabel(equipment.site_id),
      t('equipmentSchedule.rowSummary', equipmentScheduleSummaryById.value.get(equipment.id) ?? { reservations: 0, actuals: 0 }),
    ].filter(Boolean).join(' / '),
    className: 'timeline-group-row',
    _meta: {
      equipmentId: equipment.id,
      siteId: equipment.site_id,
    },
  })),
)

const timelineItems = computed<BoardTimelineItem[]>(() =>
  [
    ...visibleReservations.value.map((row) => buildReservationTimelineItem(row)),
    ...visibleAssignments.value.map((item) => buildActualTimelineItem(item.row, item.hasConflict)),
  ].sort((a, b) => {
    const groupCompare = String(a.group).localeCompare(String(b.group))
    if (groupCompare !== 0) return groupCompare

    const startCompare = a.start.getTime() - b.start.getTime()
    if (startCompare !== 0) return startCompare

    return a.content.localeCompare(b.content)
  }),
)

const timelineItemsById = computed(() => new Map(timelineItems.value.map((item) => [item.id, item])))

const timelineOptions = computed<TimelineOptions>(() => ({
  start: boardRange.value.start,
  end: boardRange.value.end,
  stack: true,
  orientation: 'top',
  groupOrder: (a, b) => String(a.id).localeCompare(String(b.id)),
  verticalScroll: true,
  horizontalScroll: true,
  zoomKey: 'ctrlKey',
  zoomMin: filters.viewMode === 'day' ? 60 * 60 * 1000 : 24 * 60 * 60 * 1000,
  zoomMax: 31 * 24 * 60 * 60 * 1000,
  selectable: true,
  multiselect: false,
  editable: false,
  locale: resolveLocaleLang(),
  timeAxis: {
    scale: filters.viewMode === 'day' ? 'hour' : 'day',
    step: 1,
  },
  format: filters.viewMode === 'day'
    ? {
        minorLabels: { hour: 'HH:mm' },
        majorLabels: { hour: 'M月D日 ddd' },
      }
    : {
        minorLabels: { day: 'DD' },
        majorLabels: { day: 'M月' },
      },
  groupTemplate: (group?: DataGroup) => {
    const typedGroup = group as BoardTimelineGroup | undefined
    const equipment = typedGroup?._meta?.equipmentId
      ? equipmentMap.value.get(typedGroup._meta.equipmentId)
      : null
    const summary = equipment?.id
      ? equipmentScheduleSummaryById.value.get(equipment.id) ?? { reservations: 0, actuals: 0 }
      : null
    const wrapper = document.createElement('div')
    wrapper.className = 'timeline-group-label'
    if (equipment) {
      wrapper.innerHTML = `
        <div class="timeline-group-code">${equipment.equipment_code}</div>
        <div class="timeline-group-name">${equipmentDisplayName(equipment) || t('equipment.nameFallback')}</div>
        <div class="timeline-group-meta">${equipmentTypeLabel(equipment.equipment_type_id)}</div>
        <div class="timeline-group-summary">${summary ? t('equipmentSchedule.rowSummary', summary) : ''}</div>
      `
      return wrapper
    }
    wrapper.textContent = typeof group?.content === 'string' ? group.content : ''
    return wrapper
  },
}))

watch(
  () => route.query,
  () => {
    applyQueryToFilters(route.query)
    void loadBoard()
  },
  { immediate: true },
)

watch([timelineGroups, timelineItems, timelineOptions, locale], () => {
  void nextTick(() => {
    syncTimeline()
  })
}, { deep: true })

onBeforeUnmount(() => {
  timelineInstance.value?.destroy()
  timelineInstance.value = null
})

function createDefaultFilters(viewMode: 'day' | 'week' = 'week'): FilterState {
  const start = startOfDay(new Date())
  const end = addDays(start, viewMode === 'day' ? 1 : 7)
  return {
    siteIds: [],
    equipmentTypeIds: [],
    equipmentIds: [],
    rangeStart: formatDateInput(start),
    rangeEnd: formatDateInput(end),
    viewMode,
    showCompleted: false,
    showActualUsage: true,
  }
}

function createEmptyReservationForm(): ReservationFormState {
  const start = startOfHour(new Date())
  const end = addHours(start, 1)
  return {
    id: null,
    reservation_type: 'batch',
    equipment_id: '',
    batch_id: '',
    batch_step_id: '',
    start_at: formatDateTimeInput(start),
    end_at: formatDateTimeInput(end),
    status: 'reserved',
    note: '',
  }
}

function startOfDay(value: Date) {
  return new Date(value.getFullYear(), value.getMonth(), value.getDate(), 0, 0, 0, 0)
}

function startOfHour(value: Date) {
  return new Date(value.getFullYear(), value.getMonth(), value.getDate(), value.getHours(), 0, 0, 0)
}

function addDays(value: Date, days: number) {
  const next = new Date(value)
  next.setDate(next.getDate() + days)
  return next
}

function addHours(value: Date, hours: number) {
  const next = new Date(value)
  next.setHours(next.getHours() + hours)
  return next
}

function parseDateInput(value: string) {
  if (!value) return startOfDay(new Date())
  const parsed = new Date(`${value}T00:00:00`)
  return Number.isNaN(parsed.getTime()) ? startOfDay(new Date()) : parsed
}

function parseDateTimeInput(value: string) {
  if (!value) return null
  const parsed = new Date(value)
  return Number.isNaN(parsed.getTime()) ? null : parsed
}

function formatDateInput(value: Date) {
  const local = new Date(value.getTime() - value.getTimezoneOffset() * 60000)
  return local.toISOString().slice(0, 10)
}

function formatDateTimeInput(value: Date) {
  const local = new Date(value.getTime() - value.getTimezoneOffset() * 60000)
  return local.toISOString().slice(0, 16)
}

function normalizeBoardRange(rangeStart: string, rangeEnd: string, viewMode: 'day' | 'week') {
  const start = parseDateInput(rangeStart)
  let end = parseDateInput(rangeEnd)
  if (end.getTime() <= start.getTime()) {
    end = addDays(start, viewMode === 'day' ? 1 : 7)
  }
  return {
    start,
    end,
    startIso: start.toISOString(),
    endIso: end.toISOString(),
  }
}

function resolveLocaleLang() {
  return String(locale.value ?? '').toLowerCase().startsWith('ja') ? 'ja' : 'en'
}

function localizeName(value: { name_i18n?: NameI18n, name?: string | null, code?: string | null }) {
  const lang = resolveLocaleLang()
  const localized = value.name_i18n?.[lang]
  if (localized) return localized
  if (value.name) return value.name
  const fallback = value.name_i18n ? Object.values(value.name_i18n)[0] : ''
  return fallback || value.code || ''
}

function asNameI18n(value: unknown): NameI18n {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null
  const result: Record<string, string> = {}
  for (const [key, item] of Object.entries(value)) {
    if (typeof item === 'string') result[key] = item
  }
  return result
}

function siteLabel(siteId: string | null | undefined) {
  if (!siteId) return t('common.noData')
  return siteMap.value.get(siteId)?.name || siteId
}

function equipmentDisplayName(row: EquipmentRow) {
  const lang = resolveLocaleLang()
  if (row.name_i18n?.[lang]) return row.name_i18n[lang]
  const fallback = row.name_i18n ? Object.values(row.name_i18n)[0] : ''
  return fallback || ''
}

function equipmentFullLabel(row: EquipmentRow) {
  const name = equipmentDisplayName(row) || t('equipment.nameFallback')
  return `${row.equipment_code} ${name}`.trim()
}

function equipmentTypeLabel(typeId: string | null | undefined) {
  if (!typeId) return t('common.noData')
  const row = equipmentTypeMap.value.get(typeId)
  if (!row) return typeId
  return localizeName({ name_i18n: row.name_i18n, name: row.name, code: row.code })
}

function equipmentStatusLabel(status: string | null) {
  if (status === 'available') return t('equipment.status.available')
  if (status === 'in_use') return t('equipment.status.inUse')
  if (status === 'cleaning') return t('equipment.status.cleaning')
  if (status === 'maintenance') return t('equipment.status.maintenance')
  if (status === 'retired') return t('equipment.status.retired')
  return t('common.unknown')
}

function batchLabel(batchId: string | null | undefined) {
  if (!batchId) return t('common.none')
  const row = batchMap.value.get(batchId)
  if (!row) return batchId
  return row.batch_label?.trim() || row.batch_code
}

function stepLabel(stepId: string | null | undefined) {
  if (!stepId) return t('common.none')
  const row = stepRowsById.value[stepId]
  if (!row) return stepId
  const prefix = row.step_no != null ? `${row.step_no}` : row.step_code ?? ''
  const name = row.step_name?.trim() || row.step_code?.trim() || ''
  return [prefix, name].filter(Boolean).join(' ')
}

function reservationTypeLabel(value: string) {
  return t(`equipmentSchedule.reservationTypes.${value}`)
}

function reservationStatusLabel(value: string) {
  return t(`equipmentSchedule.reservationStatuses.${value}`)
}

function reservationPrimaryLabel(row: ReservationRow) {
  if (row.reservation_type === 'batch') return batchLabel(row.batch_id)
  return reservationTypeLabel(row.reservation_type)
}

function actualPrimaryLabel(row: AssignmentRow) {
  return batchLabel(row.batch_id)
}

function isValidRange(start: Date, end: Date) {
  return Number.isFinite(start.getTime()) && Number.isFinite(end.getTime()) && end.getTime() > start.getTime()
}

function intersectsRange(start: Date, end: Date, rangeStart: Date, rangeEnd: Date) {
  return start.getTime() < rangeEnd.getTime() && end.getTime() > rangeStart.getTime()
}

function resolveAssignmentStart(row: AssignmentRow) {
  if (row.assigned_at) {
    const parsed = new Date(row.assigned_at)
    if (!Number.isNaN(parsed.getTime())) return parsed
  }
  if (row.updated_at) {
    const parsed = new Date(row.updated_at)
    if (!Number.isNaN(parsed.getTime())) return parsed
  }
  return null
}

function resolveAssignmentEnd(row: AssignmentRow) {
  if (row.released_at) {
    const parsed = new Date(row.released_at)
    if (!Number.isNaN(parsed.getTime())) return parsed
  }
  if (row.status === 'in_use') return new Date()
  const start = resolveAssignmentStart(row)
  if (!start) return null
  return addHours(start, 1)
}

function parseCsvQuery(value: unknown): string[] {
  if (Array.isArray(value)) {
    return value.flatMap((item) => parseCsvQuery(item))
  }
  if (typeof value !== 'string') return []
  return value.split(',').map((item) => item.trim()).filter(Boolean)
}

function parseBooleanQuery(value: unknown, fallback: boolean) {
  if (value == null) return fallback
  if (Array.isArray(value)) return parseBooleanQuery(value[0], fallback)
  if (typeof value !== 'string') return fallback
  if (value === 'true') return true
  if (value === 'false') return false
  return fallback
}

function parseStringQuery(value: unknown, fallback: string) {
  if (Array.isArray(value)) return parseStringQuery(value[0], fallback)
  return typeof value === 'string' && value.trim() ? value : fallback
}

function applyQueryToFilters(query: Record<string, unknown>) {
  const defaults = createDefaultFilters()
  filters.siteIds = parseCsvQuery(query.site)
  filters.equipmentTypeIds = parseCsvQuery(query.equipmentType)
  filters.equipmentIds = parseCsvQuery(query.equipment)
  filters.rangeStart = parseStringQuery(query.start, defaults.rangeStart)
  filters.rangeEnd = parseStringQuery(query.end, defaults.rangeEnd)
  filters.viewMode = parseStringQuery(query.view, defaults.viewMode) === 'day' ? 'day' : 'week'
  filters.showCompleted = parseBooleanQuery(query.showCompleted, defaults.showCompleted)
  filters.showActualUsage = parseBooleanQuery(query.showActual, defaults.showActualUsage)
}

function buildRouteQuery() {
  return {
    site: filters.siteIds.length ? filters.siteIds.join(',') : undefined,
    equipmentType: filters.equipmentTypeIds.length ? filters.equipmentTypeIds.join(',') : undefined,
    equipment: filters.equipmentIds.length ? filters.equipmentIds.join(',') : undefined,
    start: filters.rangeStart || undefined,
    end: filters.rangeEnd || undefined,
    view: filters.viewMode,
    showCompleted: String(filters.showCompleted),
    showActual: String(filters.showActualUsage),
  }
}

async function handleSearch() {
  await router.replace({ query: buildRouteQuery() })
}

async function handleReset() {
  Object.assign(filters, createDefaultFilters())
  await router.replace({ query: buildRouteQuery() })
}

async function refreshBoard() {
  await loadBoard()
}

function mapSiteRow(row: RowRecord): SiteRow {
  return {
    id: String(row.id),
    name: String(row.name ?? row.id),
  }
}

function mapEquipmentTypeRow(row: RowRecord): EquipmentTypeRow {
  return {
    type_id: String(row.type_id),
    code: typeof row.code === 'string' ? row.code : null,
    name: typeof row.name === 'string' ? row.name : null,
    name_i18n: asNameI18n(row.name_i18n),
    sort_order: typeof row.sort_order === 'number' ? row.sort_order : Number(row.sort_order ?? 0),
  }
}

function mapEquipmentRow(row: RowRecord): EquipmentRow {
  return {
    id: String(row.id),
    equipment_code: String(row.equipment_code ?? ''),
    name_i18n: asNameI18n(row.name_i18n),
    equipment_type_id: typeof row.equipment_type_id === 'string' ? row.equipment_type_id : null,
    equipment_kind: typeof row.equipment_kind === 'string' ? row.equipment_kind : null,
    site_id: String(row.site_id),
    equipment_status: typeof row.equipment_status === 'string' ? row.equipment_status : null,
    is_active: Boolean(row.is_active),
    sort_order: typeof row.sort_order === 'number' ? row.sort_order : Number(row.sort_order ?? 0),
  }
}

function mapReservationRow(row: RowRecord): ReservationRow {
  return {
    id: String(row.id),
    site_id: String(row.site_id),
    equipment_id: String(row.equipment_id),
    reservation_type: String(row.reservation_type ?? ''),
    batch_id: typeof row.batch_id === 'string' ? row.batch_id : null,
    batch_step_id: typeof row.batch_step_id === 'string' ? row.batch_step_id : null,
    start_at: String(row.start_at),
    end_at: String(row.end_at),
    status: String(row.status ?? 'reserved'),
    note: typeof row.note === 'string' ? row.note : null,
    created_at: typeof row.created_at === 'string' ? row.created_at : null,
    updated_at: typeof row.updated_at === 'string' ? row.updated_at : null,
  }
}

function mapAssignmentRow(row: RowRecord): AssignmentRow {
  return {
    id: String(row.id),
    batch_id: typeof row.batch_id === 'string' ? row.batch_id : null,
    batch_step_id: typeof row.batch_step_id === 'string' ? row.batch_step_id : null,
    reservation_id: typeof row.reservation_id === 'string' ? row.reservation_id : null,
    equipment_id: String(row.equipment_id),
    assignment_role: typeof row.assignment_role === 'string' ? row.assignment_role : null,
    status: String(row.status ?? 'assigned'),
    assigned_at: typeof row.assigned_at === 'string' ? row.assigned_at : null,
    released_at: typeof row.released_at === 'string' ? row.released_at : null,
    note: typeof row.note === 'string' ? row.note : null,
    updated_at: typeof row.updated_at === 'string' ? row.updated_at : null,
  }
}

function mapBatchRow(row: RowRecord): BatchRow {
  return {
    id: String(row.id),
    batch_code: String(row.batch_code ?? row.id),
    batch_label: typeof row.batch_label === 'string' ? row.batch_label : null,
    status: typeof row.status === 'string' ? row.status : null,
  }
}

function mapStepRow(row: RowRecord): StepRow {
  return {
    id: String(row.id),
    batch_id: String(row.batch_id),
    step_no: typeof row.step_no === 'number' ? row.step_no : Number(row.step_no ?? 0),
    step_name: typeof row.step_name === 'string' ? row.step_name : null,
    step_code: typeof row.step_code === 'string' ? row.step_code : null,
  }
}

function mergeStepRows(rows: StepRow[]) {
  const nextById = { ...stepRowsById.value }
  const nextByBatch = { ...batchStepsByBatch.value }

  for (const row of rows) {
    nextById[row.id] = row
    const list = nextByBatch[row.batch_id] ? [...nextByBatch[row.batch_id]] : []
    const existingIndex = list.findIndex((item) => item.id === row.id)
    if (existingIndex >= 0) {
      list[existingIndex] = row
    } else {
      list.push(row)
    }
    list.sort((a, b) => (a.step_no ?? 0) - (b.step_no ?? 0))
    nextByBatch[row.batch_id] = list
  }

  stepRowsById.value = nextById
  batchStepsByBatch.value = nextByBatch
}

async function loadBoard() {
  loading.value = true
  loadError.value = ''

  try {
    const range = boardRange.value

    const equipmentQuery = supabase
      .from('mst_equipment')
      .select('id, equipment_code, name_i18n, equipment_type_id, equipment_kind, site_id, equipment_status, is_active, sort_order')
      .eq('is_active', true)

    if (filters.siteIds.length > 0) equipmentQuery.in('site_id', filters.siteIds)
    if (filters.equipmentTypeIds.length > 0) equipmentQuery.in('equipment_type_id', filters.equipmentTypeIds)
    if (filters.equipmentIds.length > 0) equipmentQuery.in('id', filters.equipmentIds)

    const [siteResult, typeResult, batchResult, equipmentResult] = await Promise.all([
      supabase.from('mst_sites').select('id, name').order('name', { ascending: true }),
      supabase
        .from('type_def')
        .select('type_id, code, name, name_i18n, sort_order')
        .eq('domain', 'equipment_type')
        .eq('is_active', true)
        .order('sort_order', { ascending: true })
        .order('code', { ascending: true }),
      supabase
        .from('mes_batches')
        .select('id, batch_code, batch_label, status')
        .order('created_at', { ascending: false }),
      equipmentQuery
        .order('site_id', { ascending: true })
        .order('sort_order', { ascending: true })
        .order('equipment_code', { ascending: true }),
    ])

    if (siteResult.error) throw siteResult.error
    if (typeResult.error) throw typeResult.error
    if (batchResult.error) throw batchResult.error
    if (equipmentResult.error) throw equipmentResult.error

    siteRows.value = (siteResult.data ?? []).map(mapSiteRow)
    equipmentTypeRows.value = (typeResult.data ?? []).map(mapEquipmentTypeRow)
    batchRows.value = (batchResult.data ?? []).map(mapBatchRow)
    equipmentRows.value = (equipmentResult.data ?? []).map(mapEquipmentRow)

    const equipmentIds = equipmentRows.value.map((row) => row.id)
    if (equipmentIds.length === 0) {
      reservationRows.value = []
      assignmentRows.value = []
      ensureCollapsedSites()
      return
    }

    const [reservationResult, assignmentResult] = await Promise.all([
      mesClient()
        .from('equipment_reservation')
        .select('id, site_id, equipment_id, reservation_type, batch_id, batch_step_id, start_at, end_at, status, note, created_at, updated_at')
        .in('equipment_id', equipmentIds)
        .lt('start_at', range.endIso)
        .gt('end_at', range.startIso)
        .order('start_at', { ascending: true }),
      mesClient()
        .from('batch_equipment_assignment')
        .select('id, batch_id, batch_step_id, reservation_id, equipment_id, assignment_role, status, assigned_at, released_at, note, updated_at')
        .in('equipment_id', equipmentIds)
        .lt('assigned_at', range.endIso)
        .order('assigned_at', { ascending: true }),
    ])

    if (reservationResult.error) throw reservationResult.error
    if (assignmentResult.error) throw assignmentResult.error

    reservationRows.value = (reservationResult.data ?? [])
      .map(mapReservationRow)
      .filter((row) => intersectsRange(new Date(row.start_at), new Date(row.end_at), range.start, range.end))

    assignmentRows.value = (assignmentResult.data ?? [])
      .map(mapAssignmentRow)
      .filter((row) => {
        const start = resolveAssignmentStart(row)
        const end = resolveAssignmentEnd(row)
        return !!start && !!end && intersectsRange(start, end, range.start, range.end)
      })

    const stepIds = Array.from(new Set(
      [...reservationRows.value, ...assignmentRows.value]
        .map((row) => row.batch_step_id)
        .filter((value): value is string => Boolean(value)),
    ))

    if (stepIds.length > 0) {
      const { data, error } = await mesClient()
        .from('batch_step')
        .select('id, batch_id, step_no, step_name, step_code')
        .in('id', stepIds)

      if (error) throw error
      mergeStepRows((data ?? []).map(mapStepRow))
    }

    ensureCollapsedSites()
  } catch (err) {
    console.error(err)
    loadError.value = err instanceof Error ? err.message : t('equipmentSchedule.errors.loadBoard')
  } finally {
    loading.value = false
  }
}

async function ensureBatchStepsLoaded(batchId: string) {
  if (!batchId) return
  if (batchStepsByBatch.value[batchId]) return

  try {
    batchStepLoading.value = true
    const { data, error } = await mesClient()
      .from('batch_step')
      .select('id, batch_id, step_no, step_name, step_code')
      .eq('batch_id', batchId)
      .order('step_no', { ascending: true })
    if (error) throw error
    mergeStepRows((data ?? []).map(mapStepRow))
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : t('equipmentSchedule.errors.loadBoard'))
  } finally {
    batchStepLoading.value = false
  }
}

function assignmentStatusLabel(value: string) {
  return t(`equipmentSchedule.assignmentStatuses.${value}`)
}

function buildBoardTaskLabel(primaryLabel: string, batchStepId: string | null | undefined) {
  const step = stepLabel(batchStepId)
  if (!batchStepId || step === t('common.none')) return primaryLabel
  return `${primaryLabel} / ${step}`
}

function buildReservationTimelineItem(row: ReservationRow): BoardTimelineItem {
  const equipment = equipmentMap.value.get(row.equipment_id)
  const classNames = ['timeline-item', 'timeline-item--reservation']

  if (reservationCompletedStatuses.has(row.status)) classNames.push('timeline-item--completed')
  else if (row.status === 'in_progress') classNames.push('timeline-item--active')
  else classNames.push('timeline-item--planned')

  if (row.reservation_type === 'maintenance') classNames.push('timeline-item--maintenance')
  if (row.reservation_type === 'cip') classNames.push('timeline-item--cip')
  if (row.reservation_type === 'manual_block') classNames.push('timeline-item--manual')

  const label = buildBoardTaskLabel(reservationPrimaryLabel(row), row.batch_step_id)

  return {
    id: `reservation:${row.id}`,
    group: row.equipment_id,
    content: label,
    title: [
      equipment ? equipmentFullLabel(equipment) : row.equipment_id,
      reservationTypeLabel(row.reservation_type),
      reservationStatusLabel(row.status),
      formatDateTimeInput(new Date(row.start_at)),
      formatDateTimeInput(new Date(row.end_at)),
    ].join(' / '),
    className: classNames.join(' '),
    start: new Date(row.start_at),
    end: new Date(row.end_at),
    type: 'range',
    _meta: {
      kind: 'reservation',
      reservationId: row.id,
      reservationType: row.reservation_type,
      batchId: row.batch_id ?? undefined,
      batchStepId: row.batch_step_id ?? undefined,
      equipmentId: row.equipment_id,
      status: row.status,
      label: reservationPrimaryLabel(row),
    },
  }
}

function buildActualTimelineItem(row: AssignmentRow, hasConflict: boolean): BoardTimelineItem {
  const start = resolveAssignmentStart(row) ?? new Date()
  const end = resolveAssignmentEnd(row) ?? addHours(start, 1)
  const equipment = equipmentMap.value.get(row.equipment_id)
  const classNames = ['timeline-item', 'timeline-item--actual']

  if (hasConflict) classNames.push('timeline-item--conflict')
  else if (row.status === 'in_use') classNames.push('timeline-item--active')
  else if (row.status === 'done' || row.status === 'cancelled') classNames.push('timeline-item--completed')
  else classNames.push('timeline-item--planned')

  const label = buildBoardTaskLabel(actualPrimaryLabel(row), row.batch_step_id)

  return {
    id: `actual:${row.id}`,
    group: row.equipment_id,
    content: label,
    title: [
      equipment ? equipmentFullLabel(equipment) : row.equipment_id,
      hasConflict ? t('equipmentSchedule.legend.conflict') : t('equipmentSchedule.legend.actualUsage'),
      assignmentStatusLabel(row.status),
      formatDateTimeInput(start),
      formatDateTimeInput(end),
    ].join(' / '),
    className: classNames.join(' '),
    start,
    end,
    type: 'range',
    _meta: {
      kind: 'actual',
      batchId: row.batch_id ?? undefined,
      batchStepId: row.batch_step_id ?? undefined,
      reservationId: row.reservation_id ?? undefined,
      equipmentId: row.equipment_id,
      status: hasConflict ? 'conflict' : row.status,
      hasConflict,
      label: actualPrimaryLabel(row),
    },
  }
}

async function handleTimelineItemAction(item: BoardTimelineItem | undefined) {
  if (!item) return

  if (item._meta.kind === 'reservation' && item._meta.reservationId) {
    const reservation = reservationRows.value.find((row) => row.id === item._meta.reservationId)
    if (reservation) {
      await openEditModal(reservation)
    }
    return
  }

  if (item._meta.kind === 'actual') {
    const batchId = item._meta.batchId ?? null
    const batchStepId = item._meta.batchStepId ?? null
    if (batchId && batchStepId) {
      await router.push({
        name: 'batchStepExecution',
        params: { batchId, stepId: batchStepId },
      })
      return
    }
    if (batchId) {
      await router.push({
        name: 'batchEdit',
        params: { batchId },
      })
    }
  }
}

function resolveCreateWindowFromTimelineEvent(properties?: TimelineEventPropertiesResult) {
  const fallback = defaultCreateWindow()
  const rawTime = properties?.time
  const clickTime = rawTime instanceof Date ? rawTime : rawTime ? new Date(rawTime) : null
  if (!clickTime || Number.isNaN(clickTime.getTime())) return fallback

  const start = filters.viewMode === 'day' ? startOfHour(clickTime) : startOfDay(clickTime)
  const end = filters.viewMode === 'day' ? addHours(start, 1) : addDays(start, 1)
  return isValidRange(start, end) ? { start, end } : fallback
}

function handleTimelineClick(properties?: TimelineEventPropertiesResult) {
  if (!properties?.item) return
  void handleTimelineItemAction(timelineItemsById.value.get(String(properties.item)))
}

function handleTimelineDoubleClick(properties?: TimelineEventPropertiesResult) {
  if (!properties || properties.item) return

  const equipmentId = properties.group != null ? String(properties.group) : ''
  if (!equipmentId || !equipmentMap.value.has(equipmentId)) return

  const { start, end } = resolveCreateWindowFromTimelineEvent(properties)
  openCreateModal(equipmentId, start, end)
}

function syncTimeline() {
  if (!timelineContainerRef.value) return

  if (!timelineInstance.value) {
    const groups = new DataSet<BoardTimelineGroup, 'id'>(timelineGroups.value)
    const items = new DataSet<BoardTimelineItem, 'id'>(timelineItems.value)
    const timeline = new Timeline(timelineContainerRef.value, items, groups, timelineOptions.value)
    timeline.on('click', handleTimelineClick as (properties?: unknown) => void)
    timeline.on('doubleClick', handleTimelineDoubleClick as (properties?: unknown) => void)
    timelineInstance.value = timeline
    return
  }

  timelineInstance.value.setOptions(timelineOptions.value)
  timelineInstance.value.setGroups(new DataSet<BoardTimelineGroup, 'id'>(timelineGroups.value))
  timelineInstance.value.setItems(new DataSet<BoardTimelineItem, 'id'>(timelineItems.value))
  timelineInstance.value.setWindow(boardRange.value.start, boardRange.value.end, { animation: false })
}

function defaultCreateWindow() {
  const start = filters.viewMode === 'day' ? startOfHour(boardRange.value.start) : startOfDay(boardRange.value.start)
  const end = filters.viewMode === 'day' ? addHours(start, 1) : addDays(start, 1)
  return { start, end }
}

function openCreateModalForRow(equipment: EquipmentRow) {
  const { start, end } = defaultCreateWindow()
  openCreateModal(equipment.id, start, end)
}

function openCreateModal(equipmentId: string, start: Date, end: Date) {
  modalMode.value = 'create'
  formError.value = ''
  Object.assign(reservationForm, createEmptyReservationForm(), {
    equipment_id: equipmentId,
    start_at: formatDateTimeInput(start),
    end_at: formatDateTimeInput(end),
  })
  modalOpen.value = true
}

async function openEditModal(row: ReservationRow) {
  modalMode.value = 'edit'
  formError.value = ''
  Object.assign(reservationForm, {
    id: row.id,
    reservation_type: row.reservation_type,
    equipment_id: row.equipment_id,
    batch_id: row.batch_id ?? '',
    batch_step_id: row.batch_step_id ?? '',
    start_at: formatDateTimeInput(new Date(row.start_at)),
    end_at: formatDateTimeInput(new Date(row.end_at)),
    status: row.status,
    note: row.note ?? '',
  })
  if (reservationForm.batch_id) {
    await ensureBatchStepsLoaded(reservationForm.batch_id)
  }
  modalOpen.value = true
}

function closeModal() {
  modalOpen.value = false
  formError.value = ''
  Object.assign(reservationForm, createEmptyReservationForm())
}

function handleReservationTypeChange() {
  if (reservationForm.reservation_type !== 'batch') {
    reservationForm.batch_id = ''
    reservationForm.batch_step_id = ''
  }
}

async function handleBatchChange() {
  reservationForm.batch_step_id = ''
  if (reservationForm.batch_id) {
    await ensureBatchStepsLoaded(reservationForm.batch_id)
  }
}

function validateReservationForm() {
  const equipment = equipmentMap.value.get(reservationForm.equipment_id)
  if (!equipment) return t('equipmentSchedule.errors.equipmentRequired')
  if (!equipment.is_active || equipment.equipment_status === 'retired') return t('equipmentSchedule.errors.equipmentInactive')

  const start = parseDateTimeInput(reservationForm.start_at)
  const end = parseDateTimeInput(reservationForm.end_at)
  if (!start || !end || end.getTime() <= start.getTime()) return t('equipmentSchedule.errors.invalidRange')

  if (reservationForm.reservation_type === 'batch' && !reservationForm.batch_id) {
    return t('equipmentSchedule.errors.batchRequired')
  }

  if (reservationForm.batch_step_id) {
    const options = batchStepsByBatch.value[reservationForm.batch_id] ?? []
    if (!options.some((row) => row.id === reservationForm.batch_step_id)) {
      return t('equipmentSchedule.errors.batchStepMismatch')
    }
  }

  const overlappingReservation = reservationRows.value.find((row) => {
    if (row.id === reservationForm.id) return false
    if (row.equipment_id !== reservationForm.equipment_id) return false
    if (!activeReservationStatuses.has(row.status)) return false
    return intersectsRange(start, end, new Date(row.start_at), new Date(row.end_at))
  })
  if (overlappingReservation) return t('equipmentSchedule.errors.reservationOverlap')

  const overlappingAssignment = assignmentRows.value.find((row) => {
    if (row.equipment_id !== reservationForm.equipment_id) return false
    if (row.status !== 'in_use') return false
    const actualStart = resolveAssignmentStart(row)
    const actualEnd = resolveAssignmentEnd(row)
    if (!actualStart || !actualEnd) return false
    return intersectsRange(start, end, actualStart, actualEnd)
  })
  if (overlappingAssignment) return t('equipmentSchedule.errors.actualOverlap')

  return ''
}

async function saveReservation() {
  formError.value = ''
  const validationError = validateReservationForm()
  if (validationError) {
    formError.value = validationError
    return
  }

  const equipment = equipmentMap.value.get(reservationForm.equipment_id)
  const start = parseDateTimeInput(reservationForm.start_at)
  const end = parseDateTimeInput(reservationForm.end_at)
  if (!equipment || !start || !end) {
    formError.value = t('equipmentSchedule.errors.saveFailed')
    return
  }

  const payload = {
    site_id: equipment.site_id,
    equipment_id: equipment.id,
    reservation_type: reservationForm.reservation_type,
    batch_id: reservationForm.reservation_type === 'batch' ? reservationForm.batch_id || null : null,
    batch_step_id: reservationForm.reservation_type === 'batch' ? reservationForm.batch_step_id || null : null,
    start_at: start.toISOString(),
    end_at: end.toISOString(),
    status: reservationForm.status,
    note: reservationForm.note.trim() || null,
  }

  try {
    saving.value = true
    if (modalMode.value === 'edit' && reservationForm.id) {
      const { error } = await mesClient()
        .from('equipment_reservation')
        .update(payload)
        .eq('id', reservationForm.id)
      if (error) throw error
    } else {
      const { error } = await mesClient()
        .from('equipment_reservation')
        .insert(payload)
      if (error) throw error
    }

    toast.success(t('common.saved'))
    closeModal()
    await loadBoard()
  } catch (err) {
    console.error(err)
    formError.value = err instanceof Error ? err.message : t('equipmentSchedule.errors.saveFailed')
  } finally {
    saving.value = false
  }
}

function ensureCollapsedSites() {
  const validIds = new Set(groupedSiteRows.value.map((group) => group.siteId))
  collapsedSiteIds.value = collapsedSiteIds.value.filter((id) => validIds.has(id))
}

function isSiteCollapsed(siteId: string) {
  return collapsedSiteIds.value.includes(siteId)
}

function toggleSite(siteId: string) {
  if (isSiteCollapsed(siteId)) {
    collapsedSiteIds.value = collapsedSiteIds.value.filter((id) => id !== siteId)
  } else {
    collapsedSiteIds.value = [...collapsedSiteIds.value, siteId]
  }
}
</script>

<style scoped>
.equipment-schedule-select {
  min-height: 8rem;
}

.equipment-board-gantt {
  height: min(72vh, 860px);
  min-height: 560px;
  overflow: hidden;
  border-radius: 1rem;
  border: 1px solid rgba(226, 232, 240, 0.92);
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.55);
  font-family: 'Noto Sans JP', 'Segoe UI', sans-serif;
}

:deep(.equipment-board-gantt .vis-timeline) {
  border: none;
  background: transparent;
  height: 100%;
}

:deep(.equipment-board-gantt .vis-panel) {
  border-color: #e5e7eb;
  background: transparent;
}

:deep(.equipment-board-gantt .vis-time-axis) {
  background: linear-gradient(180deg, #f8fafc 0%, #f1f5f9 100%);
}

:deep(.equipment-board-gantt .vis-time-axis .vis-text) {
  color: #64748b;
  font-size: 12px;
  font-weight: 600;
}

:deep(.equipment-board-gantt .vis-panel.vis-left),
:deep(.equipment-board-gantt .vis-labelset .vis-label) {
  background: rgba(255, 255, 255, 0.96);
}

:deep(.equipment-board-gantt .vis-labelset .vis-label) {
  border-bottom: 1px solid #eef2f7;
  padding: 0;
}

:deep(.equipment-board-gantt .timeline-group-label) {
  display: flex;
  min-height: 58px;
  flex-direction: column;
  justify-content: center;
  gap: 2px;
  padding: 10px 12px;
}

:deep(.equipment-board-gantt .timeline-group-code) {
  font-size: 11px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;
  color: #64748b;
}

:deep(.equipment-board-gantt .timeline-group-name) {
  font-size: 13px;
  font-weight: 700;
  color: #111827;
}

:deep(.equipment-board-gantt .timeline-group-meta),
:deep(.equipment-board-gantt .timeline-group-summary) {
  font-size: 11px;
  color: #6b7280;
}

:deep(.equipment-board-gantt .vis-panel.vis-center),
:deep(.equipment-board-gantt .vis-panel.vis-background) {
  background: rgba(255, 255, 255, 0.92);
}

:deep(.equipment-board-gantt .vis-grid.vis-vertical) {
  border-left: 1px solid rgba(226, 232, 240, 0.55);
}

:deep(.equipment-board-gantt .vis-grid.vis-horizontal) {
  border-bottom: 1px solid rgba(226, 232, 240, 0.55);
}

:deep(.equipment-board-gantt .vis-current-time) {
  background: #2563eb;
  width: 2px;
}

:deep(.equipment-board-gantt .vis-item) {
  border-width: 1px;
  border-radius: 999px;
  box-shadow: 0 8px 18px rgba(15, 23, 42, 0.08);
  color: #111827;
  font-size: 12px;
  font-weight: 600;
}

:deep(.equipment-board-gantt .vis-item .vis-item-content) {
  padding: 6px 10px;
}

:deep(.equipment-board-gantt .timeline-item--reservation.timeline-item--planned) {
  background: #dbeafe;
  border-color: #60a5fa;
}

:deep(.equipment-board-gantt .timeline-item--reservation.timeline-item--active) {
  background: #bfdbfe;
  border-color: #2563eb;
}

:deep(.equipment-board-gantt .timeline-item--reservation.timeline-item--maintenance) {
  background: #fee2e2;
  border-color: #ef4444;
}

:deep(.equipment-board-gantt .timeline-item--reservation.timeline-item--cip) {
  background: #dbeafe;
  border-color: #0284c7;
}

:deep(.equipment-board-gantt .timeline-item--reservation.timeline-item--manual) {
  background: #e2e8f0;
  border-color: #64748b;
}

:deep(.equipment-board-gantt .timeline-item--actual.timeline-item--planned) {
  background: #ccfbf1;
  border-color: #14b8a6;
}

:deep(.equipment-board-gantt .timeline-item--actual.timeline-item--active) {
  background: #dcfce7;
  border-color: #16a34a;
}

:deep(.equipment-board-gantt .timeline-item--conflict) {
  background: #fef3c7;
  border-color: #f59e0b;
}

:deep(.equipment-board-gantt .timeline-item--completed) {
  background: #e5e7eb;
  border-color: #9ca3af;
  color: #4b5563;
}

:deep(.equipment-board-gantt .vis-item.vis-selected) {
  box-shadow: 0 0 0 2px rgba(37, 99, 235, 0.18);
}

:deep(.equipment-board-gantt .vis-item.vis-range) {
  cursor: pointer;
}

:global(html[data-theme='dark'] .equipment-board-gantt) {
  border-color: rgba(71, 85, 105, 0.72);
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.98) 0%, rgba(17, 24, 39, 0.96) 100%);
}

:global(html[data-theme='dark'] .equipment-board-gantt .vis-time-axis) {
  background: linear-gradient(180deg, rgba(30, 41, 59, 0.96) 0%, rgba(15, 23, 42, 0.96) 100%);
}

:global(html[data-theme='dark'] .equipment-board-gantt .vis-panel) {
  border-color: #334155;
}

:global(html[data-theme='dark'] .equipment-board-gantt .vis-panel.vis-left),
:global(html[data-theme='dark'] .equipment-board-gantt .vis-labelset .vis-label),
:global(html[data-theme='dark'] .equipment-board-gantt .vis-panel.vis-center),
:global(html[data-theme='dark'] .equipment-board-gantt .vis-panel.vis-background) {
  background: rgba(15, 23, 42, 0.9);
}

:global(html[data-theme='dark'] .equipment-board-gantt .vis-labelset .vis-label) {
  border-bottom-color: rgba(51, 65, 85, 0.72);
}

:global(html[data-theme='dark'] .equipment-board-gantt .vis-time-axis .vis-text),
:global(html[data-theme='dark'] .equipment-board-gantt .timeline-group-name) {
  color: #e2e8f0;
}

:global(html[data-theme='dark'] .equipment-board-gantt .timeline-group-code),
:global(html[data-theme='dark'] .equipment-board-gantt .timeline-group-meta),
:global(html[data-theme='dark'] .equipment-board-gantt .timeline-group-summary) {
  color: #94a3b8;
}

:global(html[data-theme='dark'] .equipment-board-gantt .vis-grid.vis-vertical) {
  border-left-color: rgba(51, 65, 85, 0.5);
}

:global(html[data-theme='dark'] .equipment-board-gantt .vis-grid.vis-horizontal) {
  border-bottom-color: rgba(51, 65, 85, 0.44);
}

:global(html[data-theme='dark'] .equipment-board-gantt .vis-current-time) {
  background: #60a5fa;
}

:global(html[data-theme='dark'] .equipment-board-gantt .vis-item) {
  color: #e5e7eb;
  box-shadow: 0 10px 22px rgba(2, 6, 23, 0.28);
}

:global(html[data-theme='dark'] .equipment-board-gantt .timeline-item--reservation.timeline-item--planned) {
  background: rgba(37, 99, 235, 0.3);
  border-color: rgba(96, 165, 250, 0.7);
}

:global(html[data-theme='dark'] .equipment-board-gantt .timeline-item--reservation.timeline-item--active) {
  background: rgba(29, 78, 216, 0.38);
  border-color: rgba(96, 165, 250, 0.8);
}

:global(html[data-theme='dark'] .equipment-board-gantt .timeline-item--reservation.timeline-item--maintenance) {
  background: rgba(127, 29, 29, 0.42);
  border-color: rgba(248, 113, 113, 0.78);
}

:global(html[data-theme='dark'] .equipment-board-gantt .timeline-item--reservation.timeline-item--cip) {
  background: rgba(12, 74, 110, 0.38);
  border-color: rgba(56, 189, 248, 0.76);
}

:global(html[data-theme='dark'] .equipment-board-gantt .timeline-item--reservation.timeline-item--manual) {
  background: rgba(51, 65, 85, 0.7);
  border-color: rgba(148, 163, 184, 0.76);
}

:global(html[data-theme='dark'] .equipment-board-gantt .timeline-item--actual.timeline-item--planned) {
  background: rgba(15, 118, 110, 0.42);
  border-color: rgba(45, 212, 191, 0.75);
}

:global(html[data-theme='dark'] .equipment-board-gantt .timeline-item--actual.timeline-item--active) {
  background: rgba(20, 83, 45, 0.52);
  border-color: rgba(74, 222, 128, 0.72);
}

:global(html[data-theme='dark'] .equipment-board-gantt .timeline-item--conflict) {
  background: rgba(146, 64, 14, 0.5);
  border-color: rgba(251, 191, 36, 0.76);
}

:global(html[data-theme='dark'] .equipment-board-gantt .timeline-item--completed) {
  background: rgba(55, 65, 81, 0.8);
  border-color: rgba(156, 163, 175, 0.68);
  color: #cbd5e1;
}
</style>
