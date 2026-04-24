import { defineStore } from 'pinia'
import { supabase } from '@/lib/supabase'

export type RuleengineLabelGroup =
  | 'movement_intent'
  | 'site_type'
  | 'lot_tax_type'
  | 'tax_event'
  | 'edge_type'
  | 'tax_decision_code'

export type RuleengineLabel = {
  ja?: string | null
  en?: string | null
  show_in_movement_wizard?: boolean
}

export type RuleengineUiLabelsPayload = {
  version: string
  updated_at: string | null
  enums: Partial<Record<RuleengineLabelGroup, string[]>>
  labels: Partial<Record<RuleengineLabelGroup, Record<string, RuleengineLabel>>>
}

type RuleengineLabelsState = {
  tenantId: string | null
  payload: RuleengineUiLabelsPayload | null
  loading: boolean
  lastError: string | null
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return value != null && typeof value === 'object' && !Array.isArray(value)
}

function normalizeLabels(value: unknown) {
  const groups: RuleengineUiLabelsPayload['labels'] = {}
  if (!isRecord(value)) return groups
  for (const [group, mapValue] of Object.entries(value)) {
    if (!isRecord(mapValue)) continue
    const labels: Record<string, RuleengineLabel> = {}
    for (const [code, labelValue] of Object.entries(mapValue)) {
      if (!isRecord(labelValue)) continue
      labels[code] = {
        ja: typeof labelValue.ja === 'string' ? labelValue.ja : null,
        en: typeof labelValue.en === 'string' ? labelValue.en : null,
        show_in_movement_wizard:
          typeof labelValue.show_in_movement_wizard === 'boolean'
            ? labelValue.show_in_movement_wizard
            : undefined,
      }
    }
    groups[group as RuleengineLabelGroup] = labels
  }
  return groups
}

function normalizeEnums(value: unknown) {
  const groups: RuleengineUiLabelsPayload['enums'] = {}
  if (!isRecord(value)) return groups
  for (const [group, enumValue] of Object.entries(value)) {
    if (!Array.isArray(enumValue)) continue
    groups[group as RuleengineLabelGroup] = enumValue
      .filter((item): item is string => typeof item === 'string')
  }
  return groups
}

function normalizePayload(value: unknown): RuleengineUiLabelsPayload {
  const row = isRecord(value) ? value : {}
  return {
    version: typeof row.version === 'string' ? row.version : '',
    updated_at: typeof row.updated_at === 'string' ? row.updated_at : null,
    enums: normalizeEnums(row.enums),
    labels: normalizeLabels(row.labels),
  }
}

export const useRuleengineLabelsStore = defineStore('ruleengineLabels', {
  state: (): RuleengineLabelsState => ({
    tenantId: null,
    payload: null,
    loading: false,
    lastError: null,
  }),
  actions: {
    async loadLabels(options: { tenantId?: string | null, force?: boolean } = {}) {
      const tenantId = options.tenantId ?? null
      if (!options.force && this.payload && this.tenantId === tenantId) return this.payload

      this.loading = true
      this.lastError = null
      try {
        const { data, error } = await supabase.rpc('ruleengine_get_ui_labels')
        if (error) throw error
        const payload = normalizePayload(Array.isArray(data) ? data[0] : data)
        this.payload = payload
        this.tenantId = tenantId
        return payload
      } catch (err) {
        this.lastError = err instanceof Error ? err.message : String(err)
        throw err
      } finally {
        this.loading = false
      }
    },
    clearLabels() {
      this.tenantId = null
      this.payload = null
      this.loading = false
      this.lastError = null
    },
  },
  persist: {
    key: 'ruleengine-labels',
    storage: window.localStorage,
  },
})
