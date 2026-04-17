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
          <EquipmentScheduleMultiSelectFilter
            v-model="filters.siteIds"
            :label="t('equipmentSchedule.filters.site')"
            :options="siteOptions"
            :all-label="t('common.all')"
            :select-all-label="t('equipmentSchedule.filters.selectAll')"
            :clear-all-label="t('equipmentSchedule.filters.deleteAll')"
          />

          <EquipmentScheduleMultiSelectFilter
            v-model="filters.equipmentTypeIds"
            :label="t('equipmentSchedule.filters.equipmentType')"
            :options="equipmentTypeTreeOptions"
            :all-label="t('common.all')"
            :select-all-label="t('equipmentSchedule.filters.selectAll')"
            :clear-all-label="t('equipmentSchedule.filters.clearAll')"
            panel-class="max-h-80"
          />

          <EquipmentScheduleMultiSelectFilter
            v-model="filters.equipmentIds"
            :label="t('equipmentSchedule.filters.equipment')"
            :options="equipmentOptions"
            :all-label="t('common.all')"
            :select-all-label="t('equipmentSchedule.filters.selectAll')"
            :clear-all-label="t('equipmentSchedule.filters.deleteAll')"
          />

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
              @change="handleViewModeChange"
            >
              <option value="day">{{ t('equipmentSchedule.views.day') }}</option>
              <option value="week">{{ t('equipmentSchedule.views.week') }}</option>
              <option value="two_weeks">{{ t('equipmentSchedule.views.twoWeeks') }}</option>
              <option value="month">{{ t('equipmentSchedule.views.month') }}</option>
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

      <section class="equipment-schedule-panel--board rounded-2xl border border-gray-200 bg-white p-4 shadow-sm dark:border-gray-800 dark:bg-white/[0.03]">
        <div class="equipment-board-legend mb-4 flex flex-wrap items-center gap-3">
          <div
            v-for="item in legendItems"
            :key="item.key"
            class="inline-flex items-center gap-2 rounded-full border border-gray-200 px-3 py-1.5 text-sm text-gray-700 dark:border-gray-700 dark:text-gray-300"
          >
            <span class="h-3 w-3 rounded-full" :class="item.dotClass"></span>
            <span>{{ item.label }}</span>
          </div>
        </div>
        <div
          ref="timelineContainerRef"
          class="equipment-board-timeline"
        ></div>
        <div
          v-if="loading || loadError || boardEquipmentRows.length === 0"
          class="equipment-board-overlay"
          :class="{
            'equipment-board-overlay--error': !loading && !!loadError,
          }"
        >
          <div
            v-if="loading"
            class="py-12 text-center text-sm text-gray-500 dark:text-gray-400"
          >
            {{ t('common.loading') }}
          </div>
          <div
            v-else-if="loadError"
            class="rounded-xl border border-error-200 bg-error-50 px-4 py-3 text-sm text-error-700 dark:border-error-800/50 dark:bg-error-500/10 dark:text-error-300"
          >
            {{ loadError }}
          </div>
          <div
            v-else
            class="py-12 text-center text-sm text-gray-500 dark:text-gray-400"
          >
            {{ t('equipmentSchedule.empty') }}
          </div>
        </div>
      </section>
    </div>

    <EquipmentReservationDialog
      :open="modalOpen"
      :mode="modalMode"
      :form-error="formError"
      :saving="saving"
      :deleting="deleting"
      :batch-step-loading="batchStepLoading"
      :form="reservationForm"
      :selected-equipment-label="selectedEquipmentLabel"
      :selected-site-label="selectedSiteLabel"
      :equipment-options="equipmentOptions"
      :reservation-type-options="reservationTypeOptions"
      :reservation-status-options="reservationStatusOptions"
      :batch-options="batchOptions"
      :batch-step-options="batchStepOptions"
      @close="closeModal"
      @save="saveReservation"
      @delete="deleteReservation"
      @update:form="Object.assign(reservationForm, $event)"
      @reservation-type-change="handleReservationTypeChange"
      @batch-change="handleBatchChange"
    />
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
  type TimelineItem,
  type TimelineEventPropertiesResult,
  type TimelineOptions,
} from 'vis-timeline'

import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import { supabase } from '@/lib/supabase'
import EquipmentReservationDialog from './components/EquipmentReservationDialog.vue'
import EquipmentScheduleMultiSelectFilter from './components/EquipmentScheduleMultiSelectFilter.vue'
import {
  addDays,
  addHours,
  asNameI18n,
  createDefaultFilters,
  createEmptyReservationForm,
  formatDateInput,
  formatDateTimeInput,
  intersectsRange,
  isValidRange,
  localizeName,
  normalizeBoardRange,
  parseBooleanQuery,
  parseCsvQuery,
  parseDateInput,
  parseDateTimeInput,
  parseStringQuery,
  rangeDaysForViewMode,
  resolveAssignmentEnd,
  resolveAssignmentStart,
  startOfDay,
  startOfHour,
} from './equipment-schedule/utils'
import type {
  AssignmentRow,
  BatchRow,
  BoardTimelineGroup,
  BoardTimelineItem,
  EquipmentRow,
  EquipmentTypeRow,
  FilterState,
  MultiSelectOption,
  PreparedAssignmentRow,
  PreparedReservationRow,
  ReservationFormState,
  ReservationRow,
  RowRecord,
  SelectOption,
  SiteRow,
  StepRow,
  VisibleAssignmentRow,
} from './equipment-schedule/types'

const mesClient = () => supabase.schema('mes')
const { t, locale } = useI18n()
const router = useRouter()
const route = useRoute()

const pageTitle = computed(() => t('equipmentSchedule.title'))

const loading = ref(false)
const loadError = ref('')
const saving = ref(false)
const deleting = ref(false)
const batchStepLoading = ref(false)

const siteRows = ref<SiteRow[]>([])
const equipmentTypeRows = ref<EquipmentTypeRow[]>([])
const equipmentRows = ref<EquipmentRow[]>([])
const reservationRows = ref<ReservationRow[]>([])
const assignmentRows = ref<AssignmentRow[]>([])
const batchRows = ref<BatchRow[]>([])
const stepRowsById = ref<Record<string, StepRow>>({})
const batchStepsByBatch = ref<Record<string, StepRow[]>>({})
const timelineContainerRef = ref<HTMLElement | null>(null)
const timelineInstance = ref<Timeline | null>(null)
let timelineGroupsDataSet: DataSet<BoardTimelineGroup, 'id'> | null = null
let timelineItemsDataSet: DataSet<BoardTimelineItem, 'id'> | null = null
let dailyMarkerIds: string[] = []
let weeklyMarkerIds: string[] = []
const referenceDataLoaded = ref(false)
const lastMarkerRangeKey = ref('')
const lastSyncedWindowStart = ref<number | null>(null)
const lastSyncedWindowEnd = ref<number | null>(null)
const lastTimelineOptionsKey = ref('')

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

type TimelineRangeChangeProperties = {
  start?: Date | string | number
  end?: Date | string | number
  byUser?: boolean
}

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

const siteOptions = computed<MultiSelectOption[]>(() =>
  siteRows.value.map((row) => ({
    value: row.id,
    label: row.name || row.id,
  })),
)

const equipmentTypeChildrenByParent = computed(() => {
  const map = new Map<string | null, EquipmentTypeRow[]>()
  for (const row of equipmentTypeRows.value) {
    const key = row.parent_type_id && equipmentTypeMap.value.has(row.parent_type_id) ? row.parent_type_id : null
    const list = map.get(key) ?? []
    list.push(row)
    map.set(key, list)
  }
  for (const list of map.values()) {
    list.sort((a, b) => {
      const sortCompare = (a.sort_order ?? 0) - (b.sort_order ?? 0)
      if (sortCompare !== 0) return sortCompare
      return equipmentTypeLabel(a.type_id).localeCompare(equipmentTypeLabel(b.type_id))
    })
  }
  return map
})

const equipmentTypeTreeOptions = computed<MultiSelectOption[]>(() => {
  const result: MultiSelectOption[] = []
  const walk = (parentId: string | null, depth: number) => {
    const children = equipmentTypeChildrenByParent.value.get(parentId) ?? []
    for (const row of children) {
      result.push({
        value: row.type_id,
        label: equipmentTypeLabel(row.type_id),
        depth,
      })
      walk(row.type_id, depth + 1)
    }
  }
  walk(null, 0)
  return result
})

const equipmentTypeDescendantIdsById = computed(() => {
  const cache = new Map<string, string[]>()
  const walk = (typeId: string): string[] => {
    if (cache.has(typeId)) return cache.get(typeId) ?? []
    const children = equipmentTypeChildrenByParent.value.get(typeId) ?? []
    const descendantIds = [typeId]
    for (const child of children) descendantIds.push(...walk(child.type_id))
    cache.set(typeId, descendantIds)
    return descendantIds
  }
  for (const row of equipmentTypeRows.value) walk(row.type_id)
  return cache
})

const effectiveEquipmentTypeFilterIds = computed(() => {
  if (filters.equipmentTypeIds.length === 0) return []
  const ids = new Set<string>()
  for (const typeId of filters.equipmentTypeIds) {
    const descendants = equipmentTypeDescendantIdsById.value.get(typeId) ?? [typeId]
    for (const id of descendants) ids.add(id)
  }
  return [...ids]
})

const equipmentOptions = computed<MultiSelectOption[]>(() =>
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

const boardEquipmentIdSet = computed(() => new Set(boardEquipmentRows.value.map((row) => row.id)))

const preparedReservationRows = computed<PreparedReservationRow[]>(() =>
  reservationRows.value.flatMap((row) => {
    const start = new Date(row.start_at)
    const end = new Date(row.end_at)
    if (!isValidRange(start, end)) return []

    return [{
      row,
      start,
      end,
      isCompleted: reservationCompletedStatuses.has(row.status),
      isActive: activeReservationStatuses.has(row.status),
    }]
  }),
)

const preparedAssignmentRows = computed<PreparedAssignmentRow[]>(() =>
  assignmentRows.value.flatMap((row) => {
    const start = resolveAssignmentStart(row)
    const end = resolveAssignmentEnd(row)
    if (!start || !end || !isValidRange(start, end)) return []

    return [{
      row,
      start,
      end,
      isCompleted: assignmentCompletedStatuses.has(row.status),
      isInUse: row.status === 'in_use',
    }]
  }),
)

const visibleReservations = computed<PreparedReservationRow[]>(() => {
  const range = boardRange.value
  const equipmentIds = boardEquipmentIdSet.value

  return preparedReservationRows.value.filter((entry) => {
    if (!equipmentIds.has(entry.row.equipment_id)) return false
    if (!filters.showCompleted && entry.isCompleted) return false
    if (filters.showActualUsage && visibleAssignmentReservationIds.value.has(entry.row.id)) return false

    return intersectsRange(entry.start, entry.end, range.start, range.end)
  })
})

const activeReservationWindowsByEquipment = computed(() => {
  const activeReservationsByEquipment = new Map<string, PreparedReservationRow[]>()
  const equipmentIds = boardEquipmentIdSet.value

  for (const entry of preparedReservationRows.value) {
    if (!entry.isActive || !equipmentIds.has(entry.row.equipment_id)) continue

    const rows = activeReservationsByEquipment.get(entry.row.equipment_id) ?? []
    rows.push(entry)
    activeReservationsByEquipment.set(entry.row.equipment_id, rows)
  }

  return activeReservationsByEquipment
})

const visibleAssignments = computed<VisibleAssignmentRow[]>(() => {
  if (!filters.showActualUsage) return []

  const range = boardRange.value
  const equipmentIds = boardEquipmentIdSet.value

  return preparedAssignmentRows.value.flatMap((entry) => {
    if (!equipmentIds.has(entry.row.equipment_id)) return []
    if (!filters.showCompleted && entry.isCompleted) return []
    if (!intersectsRange(entry.start, entry.end, range.start, range.end)) return []

    const hasConflict = !entry.row.reservation_id && (activeReservationWindowsByEquipment.value.get(entry.row.equipment_id) ?? []).some(
      (reservation) => intersectsRange(entry.start, entry.end, reservation.start, reservation.end),
    )

    return [{
      row: entry.row,
      start: entry.start,
      end: entry.end,
      hasConflict,
    }]
  })
})

const visibleAssignmentReservationIds = computed(() => new Set(
  visibleAssignments.value
    .map((entry) => entry.row.reservation_id)
    .filter((value): value is string => Boolean(value)),
))

const equipmentScheduleSummaryById = computed(() => {
  const summary = new Map<string, { reservations: number, actuals: number }>()

  for (const equipment of boardEquipmentRows.value) {
    summary.set(equipment.id, { reservations: 0, actuals: 0 })
  }

  for (const reservation of visibleReservations.value) {
    const current = summary.get(reservation.row.equipment_id) ?? { reservations: 0, actuals: 0 }
    current.reservations += 1
    summary.set(reservation.row.equipment_id, current)
  }

  for (const item of visibleAssignments.value) {
    const current = summary.get(item.row.equipment_id) ?? { reservations: 0, actuals: 0 }
    current.actuals += 1
    summary.set(item.row.equipment_id, current)
  }

  return summary
})

const timelineLocale = computed(() => resolveLocaleLang())
const timelineAxisScale = computed(() => (filters.viewMode === 'day' ? 'hour' : 'day'))

const timelineGroups = computed<BoardTimelineGroup[]>(() =>
  boardEquipmentRows.value.map((equipment) => ({
    id: equipment.id,
    content: buildGroupContentMarkup(equipment),
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
    ...visibleReservations.value.map((entry) => buildReservationTimelineItem(entry)),
    ...visibleAssignments.value.map((entry) => buildActualTimelineItem(entry)),
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
  verticalScroll: true,
  horizontalScroll: true,
  zoomKey: 'ctrlKey',
  zoomMin: filters.viewMode === 'day' ? 60 * 60 * 1000 : 24 * 60 * 60 * 1000,
  zoomMax: 31 * 24 * 60 * 60 * 1000,
  selectable: true,
  multiselect: false,
  moveable: true,
  editable: {
    add: false,
    remove: false,
    updateGroup: false,
    updateTime: true,
    overrideItems: false,
  },
  itemsAlwaysDraggable: {
    item: false,
    range: true,
  },
  locale: timelineLocale.value,
  onMove: handleTimelineMove,
  onMoving: handleTimelineMoving,
  timeAxis: {
    scale: timelineAxisScale.value,
    step: 1,
  },
  format: filters.viewMode === 'day'
    ? {
        minorLabels: { hour: 'HH:mm' },
        majorLabels: { hour: 'M月D日 ddd' },
      }
    : filters.viewMode === 'month'
      ? {
          minorLabels: { day: 'DD' },
          majorLabels: { day: 'YYYY年M月' },
        }
      : {
        minorLabels: { day: 'DD' },
        majorLabels: { day: 'M月' },
      },
}))

watch(
  () => route.query,
  async () => {
    applyQueryToFilters(route.query)
    await loadBoard()
    await nextTick()
    syncTimeline()
  },
  { immediate: true },
)

watch(locale, async () => {
  await nextTick()
  syncTimeline()
})

onBeforeUnmount(() => {
  timelineInstance.value?.destroy()
  timelineInstance.value = null
  timelineGroupsDataSet = null
  timelineItemsDataSet = null
  dailyMarkerIds = []
  weeklyMarkerIds = []
  lastMarkerRangeKey.value = ''
})

function resolveLocaleLang() {
  return String(locale.value ?? '').toLowerCase().startsWith('ja') ? 'ja' : 'en'
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

function startOfBoardWeek(value: Date) {
  const next = new Date(value)
  next.setHours(0, 0, 0, 0)
  const day = next.getDay()
  const diff = day === 0 ? -6 : 1 - day
  next.setDate(next.getDate() + diff)
  return next
}

function escapeHtml(value: string) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;')
}

function buildGroupContentMarkup(equipment: EquipmentRow) {
  const summary = equipmentScheduleSummaryById.value.get(equipment.id) ?? { reservations: 0, actuals: 0 }
  const code = escapeHtml(equipment.equipment_code)
  const name = escapeHtml(equipmentDisplayName(equipment) || t('equipment.nameFallback'))
  const type = escapeHtml(equipmentTypeLabel(equipment.equipment_type_id))
  const summaryText = escapeHtml(t('equipmentSchedule.rowSummary', summary))

  return `
    <div class="timeline-group-label">
      <div class="timeline-group-code">${code}</div>
      <div class="timeline-group-name">${name}</div>
      <div class="timeline-group-meta">${type}</div>
      <div class="timeline-group-summary">${summaryText}</div>
    </div>
  `
}

function equipmentTypeLabel(typeId: string | null | undefined) {
  if (!typeId) return t('common.noData')
  const row = equipmentTypeMap.value.get(typeId)
  if (!row) return typeId
  return localizeName({ name_i18n: row.name_i18n, name: row.name, code: row.code }, resolveLocaleLang())
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

function applyQueryToFilters(query: Record<string, unknown>) {
  const defaults = createDefaultFilters()
  filters.siteIds = parseCsvQuery(query.site)
  filters.equipmentTypeIds = parseCsvQuery(query.equipmentType)
  filters.equipmentIds = parseCsvQuery(query.equipment)
  filters.rangeStart = parseStringQuery(query.start, defaults.rangeStart)
  filters.rangeEnd = parseStringQuery(query.end, defaults.rangeEnd)
  {
    const nextView = parseStringQuery(query.view, defaults.viewMode)
    filters.viewMode = nextView === 'day' || nextView === 'week' || nextView === 'two_weeks' || nextView === 'month'
      ? nextView
      : defaults.viewMode
  }
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

function handleViewModeChange() {
  const start = parseDateInput(filters.rangeStart)
  const nextEnd = addDays(start, rangeDaysForViewMode(filters.viewMode))
  filters.rangeEnd = formatDateInput(nextEnd)
}

async function handleSearch() {
  await router.replace({ query: buildRouteQuery() })
}

async function handleReset() {
  Object.assign(filters, createDefaultFilters())
  await router.replace({ query: buildRouteQuery() })
}

async function refreshBoard() {
  await loadBoard({ refreshReferences: true })
  await nextTick()
  syncTimeline()
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
    parent_type_id: typeof row.parent_type_id === 'string' ? row.parent_type_id : null,
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

async function loadReferenceData(options?: { force?: boolean }) {
  if (referenceDataLoaded.value && !options?.force) return

  const [siteResult, typeResult, batchResult] = await Promise.all([
    supabase.from('mst_sites').select('id, name').order('name', { ascending: true }),
    supabase
      .from('type_def')
      .select('type_id, code, name, name_i18n, parent_type_id, sort_order')
      .eq('domain', 'equipment_type')
      .eq('is_active', true)
      .order('sort_order', { ascending: true })
      .order('code', { ascending: true }),
    supabase
      .from('mes_batches')
      .select('id, batch_code, batch_label, status')
      .order('created_at', { ascending: false }),
  ])

  if (siteResult.error) throw siteResult.error
  if (typeResult.error) throw typeResult.error
  if (batchResult.error) throw batchResult.error

  siteRows.value = (siteResult.data ?? []).map(mapSiteRow)
  equipmentTypeRows.value = (typeResult.data ?? []).map(mapEquipmentTypeRow)
  batchRows.value = (batchResult.data ?? []).map(mapBatchRow)
  referenceDataLoaded.value = true
}

async function loadBoard(options?: { refreshReferences?: boolean }) {
  loading.value = true
  loadError.value = ''

  try {
    await loadReferenceData({ force: options?.refreshReferences })
    const range = boardRange.value

    const equipmentQuery = supabase
      .from('mst_equipment')
      .select('id, equipment_code, name_i18n, equipment_type_id, equipment_kind, site_id, equipment_status, is_active, sort_order')
      .eq('is_active', true)

    if (filters.siteIds.length > 0) equipmentQuery.in('site_id', filters.siteIds)
    if (effectiveEquipmentTypeFilterIds.value.length > 0) equipmentQuery.in('equipment_type_id', effectiveEquipmentTypeFilterIds.value)
    if (filters.equipmentIds.length > 0) equipmentQuery.in('id', filters.equipmentIds)

    const { data: equipmentData, error: equipmentError } = await equipmentQuery
      .order('site_id', { ascending: true })
      .order('sort_order', { ascending: true })
      .order('equipment_code', { ascending: true })

    if (equipmentError) throw equipmentError

    equipmentRows.value = (equipmentData ?? []).map(mapEquipmentRow)

    const equipmentIds = equipmentRows.value.map((row) => row.id)
    if (equipmentIds.length === 0) {
      reservationRows.value = []
      assignmentRows.value = []
      return
    }

    const assignmentSelect = 'id, batch_id, batch_step_id, reservation_id, equipment_id, assignment_role, status, assigned_at, released_at, note, updated_at'

    const [reservationResult, assignmentResult, legacyAssignmentResult] = await Promise.all([
      mesClient()
        .from('equipment_reservation')
        .select('id, site_id, equipment_id, reservation_type, batch_id, batch_step_id, start_at, end_at, status, note, created_at, updated_at')
        .in('equipment_id', equipmentIds)
        .lt('start_at', range.endIso)
        .gt('end_at', range.startIso)
        .order('start_at', { ascending: true }),
      mesClient()
        .from('batch_equipment_assignment')
        .select(assignmentSelect)
        .in('equipment_id', equipmentIds)
        .not('assigned_at', 'is', null)
        .lt('assigned_at', range.endIso)
        .order('assigned_at', { ascending: true }),
      mesClient()
        .from('batch_equipment_assignment')
        .select(assignmentSelect)
        .in('equipment_id', equipmentIds)
        .is('assigned_at', null)
        .lt('updated_at', range.endIso)
        .order('updated_at', { ascending: true }),
    ])

    if (reservationResult.error) throw reservationResult.error
    if (assignmentResult.error) throw assignmentResult.error
    if (legacyAssignmentResult.error) throw legacyAssignmentResult.error

    reservationRows.value = (reservationResult.data ?? [])
      .map(mapReservationRow)
      .filter((row) => intersectsRange(new Date(row.start_at), new Date(row.end_at), range.start, range.end))

    const assignmentMap = new Map<string, AssignmentRow>()
    for (const row of [...(assignmentResult.data ?? []), ...(legacyAssignmentResult.data ?? [])]) {
      const mappedRow = mapAssignmentRow(row)
      assignmentMap.set(mappedRow.id, mappedRow)
    }

    assignmentRows.value = [...assignmentMap.values()]
      .filter((row) => {
        const start = resolveAssignmentStart(row)
        const end = resolveAssignmentEnd(row)
        return !!start && !!end && intersectsRange(start, end, range.start, range.end)
      })
      .sort((left, right) => {
        const leftStart = resolveAssignmentStart(left)?.getTime() ?? Number.POSITIVE_INFINITY
        const rightStart = resolveAssignmentStart(right)?.getTime() ?? Number.POSITIVE_INFINITY
        if (leftStart !== rightStart) return leftStart - rightStart
        return left.id.localeCompare(right.id)
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

function buildReservationTimelineItem(entry: PreparedReservationRow): BoardTimelineItem {
  const { row, start, end } = entry
  const equipment = equipmentMap.value.get(row.equipment_id)
  const classNames = ['timeline-item', 'timeline-item--reservation']

  if (entry.isCompleted) classNames.push('timeline-item--completed')
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
      formatDateTimeInput(start),
      formatDateTimeInput(end),
    ].join(' / '),
    className: classNames.join(' '),
    start,
    end,
    type: 'range',
    editable: {
      remove: false,
      updateGroup: false,
      updateTime: true,
    },
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

function buildActualTimelineItem(entry: VisibleAssignmentRow): BoardTimelineItem {
  const { row, start, end, hasConflict } = entry
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
    editable: false,
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

function resolveCreateWindowFromTimelineEvent(properties?: TimelineEventPropertiesResult) {
  const fallback = defaultCreateWindow()
  const rawTime = properties?.time
  const clickTime = rawTime instanceof Date ? rawTime : rawTime ? new Date(rawTime) : null
  if (!clickTime || Number.isNaN(clickTime.getTime())) return fallback

  const start = filters.viewMode === 'day' ? startOfHour(clickTime) : startOfDay(clickTime)
  const end = filters.viewMode === 'day' ? addHours(start, 1) : addDays(start, 1)
  return isValidRange(start, end) ? { start, end } : fallback
}

function handleTimelineDoubleClick(properties?: TimelineEventPropertiesResult) {
  if (!properties) return

  const item = properties.item ? timelineItemsById.value.get(String(properties.item)) : undefined
  if (item?._meta.kind === 'reservation' && item._meta.reservationId) {
    const reservation = reservationRows.value.find((row) => row.id === item._meta.reservationId)
    if (reservation) {
      void openEditModal(reservation)
    }
    return
  }

  const equipmentId = item?._meta.equipmentId ?? (properties.group != null ? String(properties.group) : '')
  if (!equipmentId || !equipmentMap.value.has(equipmentId)) return

  const { start, end } = resolveCreateWindowFromTimelineEvent(properties)
  openCreateModal(equipmentId, start, end)
}

function normalizeTimelineItemDate(value: TimelineItem['start'] | TimelineItem['end']) {
  if (value instanceof Date) return new Date(value)
  if (typeof value === 'string' || typeof value === 'number') {
    const next = new Date(value)
    return Number.isNaN(next.getTime()) ? null : next
  }
  return null
}

function validateReservationWindowChange(
  reservationId: string | null,
  equipmentId: string,
  start: Date,
  end: Date,
) {
  if (!isValidRange(start, end)) return t('equipmentSchedule.errors.invalidRange')

  const overlappingReservation = preparedReservationRows.value.find((entry) => {
    if (entry.row.id === reservationId) return false
    if (entry.row.equipment_id !== equipmentId) return false
    if (!entry.isActive) return false
    return intersectsRange(start, end, entry.start, entry.end)
  })
  if (overlappingReservation) return t('equipmentSchedule.errors.reservationOverlap')

  const overlappingAssignment = preparedAssignmentRows.value.find((entry) => {
    if (entry.row.equipment_id !== equipmentId) return false
    if (!entry.isInUse) return false
    return intersectsRange(start, end, entry.start, entry.end)
  })
  if (overlappingAssignment) return t('equipmentSchedule.errors.actualOverlap')

  return ''
}

function resolveDraggedReservationWindow(currentItem: BoardTimelineItem, item: TimelineItem) {
  const originalStart = currentItem.start
  const originalEnd = currentItem.end ?? currentItem.start
  const originalDuration = Math.max(1, originalEnd.getTime() - originalStart.getTime())

  let nextStart = normalizeTimelineItemDate(item.start) ?? originalStart
  let nextEnd = normalizeTimelineItemDate(item.end) ?? originalEnd

  const startChanged = nextStart.getTime() !== originalStart.getTime()
  const endChanged = nextEnd.getTime() !== originalEnd.getTime()
  const nextDuration = nextEnd.getTime() - nextStart.getTime()

  if (nextDuration !== originalDuration) {
    if (!startChanged && endChanged) {
      nextStart = new Date(nextEnd.getTime() - originalDuration)
    } else {
      nextEnd = new Date(nextStart.getTime() + originalDuration)
    }
  }

  return { start: nextStart, end: nextEnd }
}

function handleTimelineMoving(item: TimelineItem, callback: (item: TimelineItem | null) => void) {
  const currentItem = timelineItemsById.value.get(String(item.id))
  if (!currentItem || currentItem._meta.kind !== 'reservation') {
    callback(null)
    return
  }

  const { start, end } = resolveDraggedReservationWindow(currentItem, item)

  callback({
    ...item,
    group: currentItem.group,
    start,
    end,
  })
}

async function handleTimelineMove(item: TimelineItem, callback: (item: TimelineItem | null) => void) {
  const currentItem = timelineItemsById.value.get(String(item.id))
  if (!currentItem || currentItem._meta.kind !== 'reservation' || !currentItem._meta.reservationId) {
    callback(null)
    return
  }

  const { start, end } = resolveDraggedReservationWindow(currentItem, item)

  const validationError = validateReservationWindowChange(
    currentItem._meta.reservationId,
    currentItem._meta.equipmentId,
    start,
    end,
  )
  if (validationError) {
    toast.error(validationError)
    callback(null)
    return
  }

  try {
    saving.value = true
    const { error } = await mesClient()
      .from('equipment_reservation')
      .update({
        start_at: start.toISOString(),
        end_at: end.toISOString(),
      })
      .eq('id', currentItem._meta.reservationId)
    if (error) throw error

    callback({
      ...item,
      group: currentItem.group,
      start,
      end,
    })

    await loadBoard()
    await nextTick()
    syncTimeline()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : t('equipmentSchedule.errors.saveFailed'))
    callback(null)
  } finally {
    saving.value = false
  }
}

async function handleTimelineRangeChanged(properties?: TimelineRangeChangeProperties) {
  if (!properties?.byUser) return

  const start = normalizeTimelineItemDate(properties.start)
  const end = normalizeTimelineItemDate(properties.end)
  if (!start || !end || end.getTime() <= start.getTime()) return

  const nextRangeStart = formatDateInput(startOfDay(start))
  const nextRangeEnd = formatDateInput(startOfDay(end))
  if (filters.rangeStart === nextRangeStart && filters.rangeEnd === nextRangeEnd) return

  filters.rangeStart = nextRangeStart
  filters.rangeEnd = nextRangeEnd
  await router.replace({ query: buildRouteQuery() })
}

function syncTimeline() {
  if (!timelineContainerRef.value) return
  const nextOptions = timelineOptions.value
  const nextRangeStart = boardRange.value.start.getTime()
  const nextRangeEnd = boardRange.value.end.getTime()
  const nextOptionsKey = [timelineLocale.value, filters.viewMode].join('|')

  if (!timelineInstance.value) {
    timelineGroupsDataSet = new DataSet<BoardTimelineGroup, 'id'>(timelineGroups.value)
    timelineItemsDataSet = new DataSet<BoardTimelineItem, 'id'>(timelineItems.value)
    const timeline = new Timeline(timelineContainerRef.value, timelineItemsDataSet, timelineGroupsDataSet, nextOptions)
    timeline.on('doubleClick', handleTimelineDoubleClick as (properties?: unknown) => void)
    timeline.on('rangechanged', handleTimelineRangeChanged as (properties?: unknown) => void)
    timelineInstance.value = timeline
    lastSyncedWindowStart.value = nextRangeStart
    lastSyncedWindowEnd.value = nextRangeEnd
    lastTimelineOptionsKey.value = nextOptionsKey
    syncTimelineMarkers(true)
    return
  }

  if (lastTimelineOptionsKey.value !== nextOptionsKey) {
    timelineInstance.value.setOptions(nextOptions)
    lastTimelineOptionsKey.value = nextOptionsKey
  }

  if (timelineGroupsDataSet) {
    syncDataSetEntries(timelineGroupsDataSet, timelineGroups.value)
  }

  if (timelineItemsDataSet) {
    syncDataSetEntries(timelineItemsDataSet, timelineItems.value)
  }

  syncTimelineMarkers()

  if (lastSyncedWindowStart.value !== nextRangeStart || lastSyncedWindowEnd.value !== nextRangeEnd) {
    timelineInstance.value.setWindow(boardRange.value.start, boardRange.value.end, { animation: false })
    lastSyncedWindowStart.value = nextRangeStart
    lastSyncedWindowEnd.value = nextRangeEnd
  }

  timelineInstance.value.redraw()
}

function clearTimelineMarkers(markerIds: string[]) {
  if (!timelineInstance.value) return

  for (const markerId of markerIds) {
    try {
      timelineInstance.value.removeCustomTime(markerId)
    } catch {
      // Ignore missing markers during full timeline refresh.
    }
  }
}

function syncDataSetEntries<T extends { id: string }>(dataSet: DataSet<T, 'id'>, nextEntries: T[]) {
  const nextIds = new Set(nextEntries.map((entry) => entry.id))
  const staleIds = (dataSet.getIds() as string[]).filter((id) => !nextIds.has(id))

  if (staleIds.length > 0) {
    dataSet.remove(staleIds)
  }

  if (nextEntries.length > 0) {
    dataSet.update(nextEntries as Parameters<typeof dataSet.update>[0])
  }
}

function syncTimelineMarkers(force = false) {
  if (!timelineInstance.value) return
  const nextMarkerRangeKey = `${boardRange.value.start.toISOString()}|${boardRange.value.end.toISOString()}`
  if (!force && lastMarkerRangeKey.value === nextMarkerRangeKey) return

  clearTimelineMarkers(dailyMarkerIds)
  clearTimelineMarkers(weeklyMarkerIds)
  dailyMarkerIds = []
  weeklyMarkerIds = []

  for (
    let cursor = startOfDay(boardRange.value.start);
    cursor <= boardRange.value.end;
    cursor = addDays(cursor, 1)
  ) {
    const markerDate = new Date(cursor)
    const markerId = `timeline-day-marker-${markerDate.toISOString().slice(0, 10)}`
    timelineInstance.value.addCustomTime(markerDate, markerId)
    dailyMarkerIds.push(markerId)
  }

  for (
    let cursor = startOfBoardWeek(boardRange.value.start);
    cursor <= boardRange.value.end;
    cursor = addDays(cursor, 7)
  ) {
    const markerDate = new Date(cursor)
    const markerId = `timeline-week-marker-${markerDate.toISOString().slice(0, 10)}`
    timelineInstance.value.addCustomTime(markerDate, markerId)
    weeklyMarkerIds.push(markerId)
  }

  lastMarkerRangeKey.value = nextMarkerRangeKey
}

function defaultCreateWindow() {
  const start = filters.viewMode === 'day' ? startOfHour(boardRange.value.start) : startOfDay(boardRange.value.start)
  const end = filters.viewMode === 'day' ? addHours(start, 1) : addDays(start, 1)
  return { start, end }
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
  deleting.value = false
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
  return validateReservationWindowChange(reservationForm.id, reservationForm.equipment_id, start, end)
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
    await nextTick()
    syncTimeline()
  } catch (err) {
    console.error(err)
    formError.value = err instanceof Error ? err.message : t('equipmentSchedule.errors.saveFailed')
  } finally {
    saving.value = false
  }
}

async function deleteReservation() {
  if (modalMode.value !== 'edit' || !reservationForm.id) return

  const confirmed = window.confirm(t('equipmentSchedule.modal.deleteConfirm', {
    equipment: selectedEquipmentLabel.value,
  }))
  if (!confirmed) return

  formError.value = ''

  try {
    deleting.value = true
    const { error } = await mesClient()
      .from('equipment_reservation')
      .delete()
      .eq('id', reservationForm.id)
    if (error) throw error

    toast.success(t('common.deleted'))
    closeModal()
    await loadBoard()
    await nextTick()
    syncTimeline()
  } catch (err) {
    console.error(err)
    formError.value = err instanceof Error ? err.message : t('equipmentSchedule.errors.deleteFailed')
  } finally {
    deleting.value = false
  }
}

</script>

<style scoped>
.equipment-schedule-panel--board {
  position: relative;
  display: grid;
  grid-template-columns: minmax(0, 1fr);
  grid-template-rows: auto minmax(0, 1fr);
}

.equipment-board-legend {
  grid-column: 1;
  grid-row: 1;
}

.equipment-board-overlay {
  grid-column: 1;
  grid-row: 2;
  display: flex;
  align-items: center;
  justify-content: center;
  border-radius: 1rem;
  background: rgba(255, 255, 255, 0.82);
  backdrop-filter: blur(2px);
  z-index: 3;
}

.equipment-board-overlay--error {
  align-items: flex-start;
  padding: 1rem;
}

.equipment-board-timeline {
  grid-column: 1;
  grid-row: 2;
  height: min(72vh, 860px);
  min-height: 560px;
  overflow: hidden;
  border-radius: 1rem;
  border: 1px solid rgba(226, 232, 240, 0.92);
  background: linear-gradient(180deg, #ffffff 0%, #f8fafc 100%);
  box-shadow: inset 0 1px 0 rgba(255, 255, 255, 0.55);
  font-family: 'Noto Sans JP', 'Segoe UI', sans-serif;
}

:deep(.equipment-board-timeline .vis-timeline) {
  border: none;
  background: transparent;
  height: 100%;
}

:deep(.equipment-board-timeline .vis-panel) {
  border-color: #e5e7eb;
  background: transparent;
}

:deep(.equipment-board-timeline .vis-time-axis) {
  background: linear-gradient(180deg, #f8fafc 0%, #f1f5f9 100%);
}

:deep(.equipment-board-timeline .vis-time-axis .vis-text) {
  color: #64748b;
  font-size: 12px;
  font-weight: 600;
}

:deep(.equipment-board-timeline .vis-panel.vis-left),
:deep(.equipment-board-timeline .vis-labelset .vis-label) {
  background: rgba(255, 255, 255, 0.96);
}

:deep(.equipment-board-timeline .vis-labelset .vis-label) {
  border-bottom: 1px solid #eef2f7;
  padding: 0;
}

:deep(.equipment-board-timeline .timeline-group-label) {
  display: flex;
  min-height: 58px;
  flex-direction: column;
  justify-content: center;
  gap: 2px;
  padding: 10px 12px;
}

:deep(.equipment-board-timeline .timeline-group-code) {
  font-size: 8px;
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, 'Liberation Mono', 'Courier New', monospace;
  color: #64748b;
}

:deep(.equipment-board-timeline .timeline-group-name) {
  font-size: 10px;
  font-weight: 700;
  color: #111827;
}

:deep(.equipment-board-timeline .timeline-group-meta),
:deep(.equipment-board-timeline .timeline-group-summary) {
  font-size: 8px;
  color: #6b7280;
}

:deep(.equipment-board-timeline .vis-panel.vis-background) {
  background: rgba(255, 255, 255, 0.92);
}

:deep(.equipment-board-timeline .vis-panel.vis-center) {
  background: transparent;
}

:deep(.equipment-board-timeline .vis-grid.vis-vertical) {
  border-left: 1px solid rgba(100, 100, 100, 0.92);
}

:deep(.equipment-board-timeline .vis-time-axis .vis-grid.vis-minor) {
  border-left-color: rgba(0, 0, 0, 0.05);
  border-left-width: 1px;
}

:deep(.equipment-board-timeline .vis-time-axis .vis-grid.vis-major) {
  border-left-color: rgba(0, 0, 0, 0.08);
  border-left-width: 1px;
}

:deep(.equipment-board-timeline .vis-custom-time[class*='timeline-day-marker-']) {
  width: 1px;
  background: rgba(0, 0, 0, 1);
  cursor: default;
  pointer-events: none;
  z-index: 0;
}

:deep(.equipment-board-timeline .vis-custom-time[class*='timeline-week-marker-']) {
  width: 1px;
  background: rgba(71, 85, 105, 0.34);
  cursor: default;
  pointer-events: none;
  z-index: 0;
}

:deep(.equipment-board-timeline .vis-grid.vis-horizontal) {
  border-bottom: 1px solid rgba(226, 232, 240, 0.55);
}

:deep(.equipment-board-timeline .vis-current-time) {
  background: #2563eb;
  width: 2px;
}

:deep(.equipment-board-timeline .vis-item) {
  border-width: 1px;
  border-radius: 999px;
  box-shadow: 0 8px 18px rgba(15, 23, 42, 0.08);
  color: #111827;
  font-size: 12px;
  font-weight: 600;
}

:deep(.equipment-board-timeline .vis-item .vis-item-content) {
  padding: 6px 10px;
}

:deep(.equipment-board-timeline .timeline-item--reservation.timeline-item--planned) {
  background: #dbeafe;
  border-color: #60a5fa;
}

:deep(.equipment-board-timeline .timeline-item--reservation.timeline-item--active) {
  background: #bfdbfe;
  border-color: #2563eb;
}

:deep(.equipment-board-timeline .timeline-item--reservation.timeline-item--maintenance) {
  background: #fee2e2;
  border-color: #ef4444;
}

:deep(.equipment-board-timeline .timeline-item--reservation.timeline-item--cip) {
  background: #dbeafe;
  border-color: #0284c7;
}

:deep(.equipment-board-timeline .timeline-item--reservation.timeline-item--manual) {
  background: #e2e8f0;
  border-color: #64748b;
}

:deep(.equipment-board-timeline .timeline-item--actual.timeline-item--planned) {
  background: #ccfbf1;
  border-color: #14b8a6;
}

:deep(.equipment-board-timeline .timeline-item--actual.timeline-item--active) {
  background: #dcfce7;
  border-color: #16a34a;
}

:deep(.equipment-board-timeline .timeline-item--conflict) {
  background: #fef3c7;
  border-color: #f59e0b;
}

:deep(.equipment-board-timeline .timeline-item--completed) {
  background: #e5e7eb;
  border-color: #9ca3af;
  color: #4b5563;
}

:deep(.equipment-board-timeline .vis-item.vis-selected) {
  box-shadow: 0 0 0 2px rgba(37, 99, 235, 0.18);
}

:deep(.equipment-board-timeline .vis-item.vis-range) {
  cursor: pointer;
}

:global(html[data-theme='dark'] .equipment-board-timeline) {
  border-color: rgba(71, 85, 105, 0.72);
  background: linear-gradient(180deg, rgba(15, 23, 42, 0.98) 0%, rgba(17, 24, 39, 0.96) 100%);
}

:global(html[data-theme='dark'] .equipment-board-overlay) {
  background: rgba(15, 23, 42, 0.78);
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-time-axis) {
  background: linear-gradient(180deg, rgba(30, 41, 59, 0.96) 0%, rgba(15, 23, 42, 0.96) 100%);
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-panel) {
  border-color: #334155;
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-panel.vis-left),
:global(html[data-theme='dark'] .equipment-board-timeline .vis-labelset .vis-label),
:global(html[data-theme='dark'] .equipment-board-timeline .vis-panel.vis-background) {
  background: rgba(15, 23, 42, 0.9);
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-panel.vis-center) {
  background: transparent;
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-labelset .vis-label) {
  border-bottom-color: rgba(51, 65, 85, 0.72);
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-time-axis .vis-text),
:global(html[data-theme='dark'] .equipment-board-timeline .timeline-group-name) {
  color: #e2e8f0;
}

:global(html[data-theme='dark'] .equipment-board-timeline .timeline-group-code),
:global(html[data-theme='dark'] .equipment-board-timeline .timeline-group-meta),
:global(html[data-theme='dark'] .equipment-board-timeline .timeline-group-summary) {
  color: #94a3b8;
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-grid.vis-vertical) {
  border-left-color: rgba(100, 116, 139, 0.78);
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-time-axis .vis-grid.vis-minor) {
  border-left-color: rgba(255, 255, 255, 0.06);
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-time-axis .vis-grid.vis-major) {
  border-left-color: rgba(255, 255, 255, 0.1);
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-custom-time[class*='timeline-day-marker-']) {
  background: rgba(226, 232, 240, 0.9);
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-custom-time[class*='timeline-week-marker-']) {
  background: rgba(148, 163, 184, 0.42);
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-grid.vis-horizontal) {
  border-bottom-color: rgba(51, 65, 85, 0.44);
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-current-time) {
  background: #60a5fa;
}

:global(html[data-theme='dark'] .equipment-board-timeline .vis-item) {
  color: #e5e7eb;
  box-shadow: 0 10px 22px rgba(2, 6, 23, 0.28);
}

:global(html[data-theme='dark'] .equipment-board-timeline .timeline-item--reservation.timeline-item--planned) {
  background: rgba(37, 99, 235, 0.3);
  border-color: rgba(96, 165, 250, 0.7);
}

:global(html[data-theme='dark'] .equipment-board-timeline .timeline-item--reservation.timeline-item--active) {
  background: rgba(29, 78, 216, 0.38);
  border-color: rgba(96, 165, 250, 0.8);
}

:global(html[data-theme='dark'] .equipment-board-timeline .timeline-item--reservation.timeline-item--maintenance) {
  background: rgba(127, 29, 29, 0.42);
  border-color: rgba(248, 113, 113, 0.78);
}

:global(html[data-theme='dark'] .equipment-board-timeline .timeline-item--reservation.timeline-item--cip) {
  background: rgba(12, 74, 110, 0.38);
  border-color: rgba(56, 189, 248, 0.76);
}

:global(html[data-theme='dark'] .equipment-board-timeline .timeline-item--reservation.timeline-item--manual) {
  background: rgba(51, 65, 85, 0.7);
  border-color: rgba(148, 163, 184, 0.76);
}

:global(html[data-theme='dark'] .equipment-board-timeline .timeline-item--actual.timeline-item--planned) {
  background: rgba(15, 118, 110, 0.42);
  border-color: rgba(45, 212, 191, 0.75);
}

:global(html[data-theme='dark'] .equipment-board-timeline .timeline-item--actual.timeline-item--active) {
  background: rgba(20, 83, 45, 0.52);
  border-color: rgba(74, 222, 128, 0.72);
}

:global(html[data-theme='dark'] .equipment-board-timeline .timeline-item--conflict) {
  background: rgba(146, 64, 14, 0.5);
  border-color: rgba(251, 191, 36, 0.76);
}

:global(html[data-theme='dark'] .equipment-board-timeline .timeline-item--completed) {
  background: rgba(55, 65, 81, 0.8);
  border-color: rgba(156, 163, 175, 0.68);
  color: #cbd5e1;
}
</style>
