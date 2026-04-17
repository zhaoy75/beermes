import type { DataGroup, DataItem } from 'vis-timeline'

export type NameI18n = Record<string, string> | null
export type RowRecord = Record<string, unknown>

export interface SiteRow {
  id: string
  name: string
}

export interface EquipmentTypeRow {
  type_id: string
  code: string | null
  name: string | null
  name_i18n: NameI18n
  parent_type_id: string | null
  sort_order: number | null
}

export interface EquipmentRow {
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

export interface ReservationRow {
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

export interface AssignmentRow {
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

export interface BatchRow {
  id: string
  batch_code: string
  batch_label: string | null
  status: string | null
}

export interface StepRow {
  id: string
  batch_id: string
  step_no: number | null
  step_name: string | null
  step_code: string | null
}

export interface FilterState {
  siteIds: string[]
  equipmentTypeIds: string[]
  equipmentIds: string[]
  rangeStart: string
  rangeEnd: string
  viewMode: 'day' | 'week' | 'two_weeks' | 'month'
  showCompleted: boolean
  showActualUsage: boolean
}

export interface ReservationFormState {
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

export interface SelectOption {
  value: string
  label: string
}

export interface MultiSelectOption extends SelectOption {
  depth?: number
}

export interface TimelineGroupMeta {
  equipmentId: string
  siteId: string
}

export interface BoardTimelineGroup extends DataGroup {
  id: string
  content: string
  title: string
  className?: string
  nestedGroups?: string[]
  treeLevel?: number
  _meta: TimelineGroupMeta
}

export interface TimelineItemMeta {
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

export interface BoardTimelineItem extends DataItem {
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

export interface PreparedReservationRow {
  row: ReservationRow
  start: Date
  end: Date
  isCompleted: boolean
  isActive: boolean
}

export interface PreparedAssignmentRow {
  row: AssignmentRow
  start: Date
  end: Date
  isCompleted: boolean
  isInUse: boolean
}

export interface VisibleAssignmentRow {
  row: AssignmentRow
  start: Date
  end: Date
  hasConflict: boolean
}
