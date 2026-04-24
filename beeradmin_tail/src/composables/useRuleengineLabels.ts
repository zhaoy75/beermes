import { computed } from 'vue'
import { useI18n } from 'vue-i18n'
import {
  useRuleengineLabelsStore,
  type RuleengineLabel,
  type RuleengineLabelGroup,
} from '@/stores/ruleengineLabels'

function pickLabel(label: RuleengineLabel | null | undefined, fallback: string, lang: 'ja' | 'en') {
  if (!label) return fallback
  const primary = lang === 'ja' ? label.ja : label.en
  const secondary = lang === 'ja' ? label.en : label.ja
  return primary || secondary || fallback
}

export function useRuleengineLabels() {
  const { locale } = useI18n()
  const store = useRuleengineLabelsStore()
  const lang = computed<'ja' | 'en'>(() =>
    String(locale.value || '').toLowerCase().startsWith('ja') ? 'ja' : 'en',
  )

  function ruleLabel(
    group: RuleengineLabelGroup,
    code: string | null | undefined,
    fallbackMap?: Record<string, RuleengineLabel> | null,
  ) {
    const normalized = (code ?? '').trim()
    if (!normalized) return '—'
    const cached = store.payload?.labels?.[group]?.[normalized]
    const fallback = fallbackMap?.[normalized]
    return pickLabel(cached ?? fallback, normalized, lang.value)
  }

  function enumValues(group: RuleengineLabelGroup) {
    return store.payload?.enums?.[group] ?? []
  }

  async function loadRuleengineLabels(options: { tenantId?: string | null, force?: boolean } = {}) {
    return store.loadLabels(options)
  }

  return {
    enumValues,
    loadRuleengineLabels,
    ruleLabel,
    ruleengineLabelsStore: store,
  }
}
