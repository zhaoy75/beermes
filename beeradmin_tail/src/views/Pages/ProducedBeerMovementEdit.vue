<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto space-y-6">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">酒税関連登録</h1>
          <p class="text-sm text-gray-500">movementrule.jsonc に基づいて動的にルールを適用します。</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50" @click="goBack">戻る</button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-semibold">酒税関連登録ウィザード</h2>
            <p class="text-sm text-gray-500">ステップ1〜5を順に入力してください。</p>
          </div>
          <div class="inline-flex rounded-lg border border-gray-300 bg-white p-0.5">
            <button
              v-for="step in wizardSteps"
              :key="step.key"
              class="px-3 py-1.5 text-sm rounded-md"
              :class="currentStep === step.index ? 'bg-gray-900 text-white' : 'text-gray-600 hover:bg-gray-50'"
              type="button"
              @click="currentStep = step.index"
            >
              {{ step.label }}
            </button>
          </div>
        </div>

        <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div class="lg:col-span-2 space-y-6">
            <section v-if="currentStep === 1" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">ステップ1：移動目的（movement_intent）</h3>
                <p class="text-sm text-gray-500">ルールファイルから移動目的を読み込みます。</p>
              </header>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <button
                  v-for="option in intentOptions"
                  :key="option.value"
                  class="p-4 rounded-lg border text-left"
                  :class="movementForm.intent === option.value ? 'border-blue-600 bg-blue-50' : 'border-gray-200 hover:bg-gray-50'"
                  type="button"
                  @click="movementForm.intent = option.value"
                >
                  <div class="text-sm font-semibold text-gray-900">{{ option.label }}</div>
                  <div class="text-xs text-gray-500">{{ option.value }}</div>
                  </button>
                </div>
              <div v-if="intentRuleSummary" class="rounded-lg border border-gray-200 p-3 text-sm text-gray-600 space-y-1">
                <div><span class="text-xs uppercase text-gray-500">Allowed Src Site</span> {{ intentRuleSummary.src }}</div>
                <div><span class="text-xs uppercase text-gray-500">Allowed Dst Site</span> {{ intentRuleSummary.dst }}</div>
                <div><span class="text-xs uppercase text-gray-500">Edge Type</span> {{ intentRuleSummary.edgeType }}</div>
              </div>
            </section>

            <section v-if="currentStep === 2" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">ステップ2：移動元/移動先の選択</h3>
                <p class="text-sm text-gray-500">サイト種別とデフォルト税区分をシステムが導出します。</p>
              </header>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Source Site Type</label>
                  <select v-model="movementForm.srcSiteType" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">Select</option>
                    <option v-for="site in srcSiteTypeOptions" :key="site" :value="site">{{ site }}</option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Destination Site Type</label>
                  <select v-model="movementForm.dstSiteType" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">Select</option>
                    <option v-for="site in dstSiteTypeOptions" :key="site" :value="site">{{ site }}</option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Source Site</label>
                  <select v-model="movementForm.srcSite" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">Select</option>
                    <option v-for="site in filteredSrcSiteOptions" :key="site.id" :value="site.id">{{ site.label }}</option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Destination Site</label>
                  <select v-model="movementForm.dstSite" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">Select</option>
                    <option v-for="site in filteredDstSiteOptions" :key="site.id" :value="site.id">{{ site.label }}</option>
                  </select>
                </div>
              </div>

              <div v-if="taxDecisionOptions.length" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Tax Decision Code</label>
                  <p class="text-xs text-gray-500 mb-2">
                    default: {{ defaultTaxDecisionCode || '—' }}
                  </p>
                  <select v-model="movementForm.taxDecisionCode" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">Select</option>
                    <option v-for="option in taxDecisionOptions" :key="option.value" :value="option.value">
                      {{ option.label }}
                    </option>
                  </select>
                </div>
                <div v-if="movementForm.taxDecisionCode && movementForm.taxDecisionCode !== defaultTaxDecisionCode">
                  <label class="block text-sm text-gray-600 mb-1">Reason (required for non-default)</label>
                  <input v-model.trim="movementForm.taxDecisionReason" class="w-full h-[40px] border rounded px-3" />
                  <p v-if="!movementForm.taxDecisionReason" class="mt-1 text-xs text-amber-600">Reason is required when selecting a non-default code.</p>
                </div>
              </div>
            </section>

            <section v-if="currentStep === 3" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">ステップ3：移動商品（Lot）選択</h3>
                <p class="text-sm text-gray-500">ロット種別により税区分が変わる場合があります。</p>
              </header>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Product</label>
                  <input v-model.trim="movementForm.product" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Source Lot Tax Type</label>
                  <select v-model="movementForm.srcLotTaxType" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">Select</option>
                    <option v-for="lotType in lotTaxTypeOptions" :key="lotType" :value="lotType">{{ lotType }}</option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Destination Lot Tax Type</label>
                  <select v-model="movementForm.dstLotTaxType" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">Select</option>
                    <option v-for="lotType in lotTaxTypeOptions" :key="lotType" :value="lotType">{{ lotType }}</option>
                  </select>
                </div>
              </div>
              <div class="overflow-x-auto border border-gray-200 rounded-lg">
                <table class="min-w-full text-sm divide-y divide-gray-200">
                  <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                    <tr>
                      <th class="px-3 py-2 text-left">Select</th>
                      <th class="px-3 py-2 text-left">Lot Code</th>
                      <th class="px-3 py-2 text-left">Related Batch</th>
                      <th class="px-3 py-2 text-left">Batch Info</th>
                      <th class="px-3 py-2 text-left">Package</th>
                      <th class="px-3 py-2 text-right">Quantity</th>
                      <th class="px-3 py-2 text-left">UOM</th>
                      <th class="px-3 py-2 text-left">Lot Tax Type</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="lot in lotOptions" :key="lot.id" class="hover:bg-gray-50">
                      <td class="px-3 py-2">
                        <input v-model="movementForm.srcLots" type="checkbox" :value="lot.id" />
                      </td>
                      <td class="px-3 py-2 text-gray-700">{{ lot.lotCode || lot.label }}</td>
                      <td class="px-3 py-2 text-gray-700">{{ lot.relatedBatchCode || '—' }}</td>
                      <td class="px-3 py-2 text-gray-700">{{ lot.batchLabel || '—' }}</td>
                      <td class="px-3 py-2 text-gray-700">{{ lot.packageLabel || '—' }}</td>
                      <td class="px-3 py-2 text-right text-gray-700">{{ lot.quantity ?? '—' }}</td>
                      <td class="px-3 py-2 text-gray-700">{{ lot.uomCode || '—' }}</td>
                      <td class="px-3 py-2 text-gray-700">{{ lot.lotTaxType || '—' }}</td>
                    </tr>
                    <tr v-if="lotOptions.length === 0">
                      <td class="px-3 py-6 text-center text-gray-500" colspan="8">No lots found.</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <p v-if="selectedLotTaxTypeSet.length > 1" class="text-xs text-amber-600">
                複数の lot 税区分が選択されています。選択によって税イベントが変わる可能性があります。
              </p>
            </section>

            <section v-if="currentStep === 4" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">ステップ4：必要情報の入力</h3>
                <p class="text-sm text-gray-500">数量・日付・理由などを入力します。</p>
              </header>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Date</label>
                  <input v-model="movementForm.eventDate" type="date" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Quantity</label>
                  <input v-model="movementForm.quantity" type="number" step="0.001" class="w-full h-[40px] border rounded px-3 text-right" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">UOM</label>
                  <input v-model.trim="movementForm.uom" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Notes</label>
                  <input v-model.trim="movementForm.notes" class="w-full h-[40px] border rounded px-3" />
                </div>
              </div>
            </section>

            <section v-if="currentStep === 5" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">ステップ5：確認</h3>
                <p class="text-sm text-gray-500">導出された税イベントとルールを確認します。</p>
              </header>
              <div class="rounded-lg border border-gray-200 p-4 space-y-2 text-sm text-gray-600">
                <div>movement_intent: <span class="text-gray-900">{{ movementForm.intent || '—' }}</span></div>
                <div>src_site_type: <span class="text-gray-900">{{ movementForm.srcSiteType || '—' }}</span></div>
                <div>dst_site_type: <span class="text-gray-900">{{ movementForm.dstSiteType || '—' }}</span></div>
                <div>tax_decision_code: <span class="text-gray-900">{{ movementForm.taxDecisionCode || '—' }}</span></div>
                <div>tax_event: <span class="text-gray-900">{{ derivedTaxEvent || '—' }}</span></div>
                <div>rule_id: <span class="text-gray-900">{{ derivedRuleId || '—' }}</span></div>
              </div>
            </section>
          </div>

          <aside class="space-y-4">
            <div class="border border-gray-200 rounded-lg p-4 space-y-3">
              <h3 class="text-sm font-semibold text-gray-700">Derived Tax</h3>
              <div class="text-sm text-gray-600">
                <div class="text-xs uppercase text-gray-500">Tax Event</div>
                <div class="text-base font-semibold text-gray-900">{{ derivedTaxEvent || '—' }}</div>
              </div>
              <div class="text-sm text-gray-600">
                <div class="text-xs uppercase text-gray-500">Rule</div>
                <div class="text-base font-semibold text-gray-900">{{ derivedRuleId || '—' }}</div>
              </div>
            </div>
          </aside>
        </div>

        <footer class="flex flex-wrap items-center justify-between gap-3">
          <div class="flex items-center gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="prevStep" :disabled="currentStep === 1">
              戻る
            </button>
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="nextStep" :disabled="currentStep === wizardSteps.length">
              次へ
            </button>
          </div>
          <div class="flex items-center gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button">下書き保存</button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" type="button">確定</button>
          </div>
        </footer>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import movementRuleRaw from '../../../../docs/data/movementrule.jsonc?raw'
import { supabase } from '@/lib/supabase'

type MovementRules = {
  enums?: Record<string, string[]>
  movement_intent_labels?: Record<string, { ja?: string; en?: string }>
  movement_intent_rules?: Array<Record<string, any>>
  tax_decision_definitions?: Array<Record<string, any>>
  tax_transformation_rules?: Array<Record<string, any>>
}

const router = useRouter()
const pageTitle = computed(() => '酒税関連登録')

const currentStep = ref(1)
const wizardSteps = computed(() => ([
  { key: 'intent', label: 'ステップ1', index: 1 },
  { key: 'sites', label: 'ステップ2', index: 2 },
  { key: 'lot', label: 'ステップ3', index: 3 },
  { key: 'info', label: 'ステップ4', index: 4 },
  { key: 'confirm', label: 'ステップ5', index: 5 },
]))

const rules = ref<MovementRules | null>(null)
const tenantId = ref<string | null>(null)

type SiteOption = {
  id: string
  label: string
  siteTypeKey: string | null
}

type LotOption = {
  id: string
  label: string
  lotTaxType: string | null
  lotCode: string | null
  relatedBatchCode: string | null
  batchLabel: string | null
  packageLabel: string | null
  quantity: number | null
  uomCode: string | null
}

const siteOptions = ref<SiteOption[]>([])
const lotOptions = ref<LotOption[]>([])

const movementForm = reactive({
  intent: '',
  srcSite: '',
  dstSite: '',
  srcSiteType: '',
  dstSiteType: '',
  taxDecisionCode: '',
  taxDecisionReason: '',
  product: '',
  srcLots: [] as string[],
  srcLotTaxType: '',
  dstLotTaxType: '',
  eventDate: '',
  quantity: '',
  uom: '',
  notes: '',
})

const intentOptions = computed(() => {
  const intents = rules.value?.enums?.movement_intent ?? []
  const labels = rules.value?.movement_intent_labels ?? {}
  return intents.map((key) => ({
    value: key,
    label: labels?.[key]?.ja ?? labels?.[key]?.en ?? key,
  }))
})

const siteTypeOptions = computed(() => rules.value?.enums?.site_type ?? [])
const lotTaxTypeOptions = computed(() => rules.value?.enums?.lot_tax_type ?? [])

const selectedIntentRule = computed(() => {
  if (!movementForm.intent) return null
  return (rules.value?.movement_intent_rules ?? []).find((rule: any) => rule.movement_intent === movementForm.intent) ?? null
})

const allowedSrcSiteTypes = computed(() => selectedIntentRule.value?.allowed_src_site_types ?? [])
const allowedDstSiteTypes = computed(() => selectedIntentRule.value?.allowed_dst_site_types ?? [])

const taxDecisionOptions = computed(() => {
  const defs = new Map<string, { name_ja?: string; name_en?: string }>()
  ;(rules.value?.tax_decision_definitions ?? []).forEach((row: any) => {
    defs.set(row.tax_decision_code, { name_ja: row.name_ja, name_en: row.name_en })
  })
  const candidates = (rules.value?.tax_transformation_rules ?? []).filter((rule: any) => {
    if (movementForm.intent && rule.movement_intent !== movementForm.intent) return false
    if (movementForm.srcSiteType && rule.src_site_type !== movementForm.srcSiteType) return false
    if (movementForm.dstSiteType && rule.dst_site_type !== movementForm.dstSiteType) return false
    if (movementForm.srcLotTaxType && rule.lot_tax_type !== movementForm.srcLotTaxType) return false
    return true
  })
  const codes = new Set<string>()
  candidates.forEach((rule: any) => {
    ;(rule.allowed_tax_decisions ?? []).forEach((decision: any) => {
      if (decision?.tax_decision_code) codes.add(decision.tax_decision_code)
    })
  })
  return Array.from(codes).map((code) => {
    const def = defs.get(code)
    const label = def?.name_ja ?? def?.name_en ?? code
    return { value: code, label }
  })
})

const defaultTaxDecisionCode = computed(() => {
  const ruleset = rules.value?.tax_transformation_rules ?? []
  if (!movementForm.intent || !movementForm.srcSiteType || !movementForm.dstSiteType) return ''
  const rule = ruleset.find((item: any) =>
    item.movement_intent === movementForm.intent &&
    item.src_site_type === movementForm.srcSiteType &&
    item.dst_site_type === movementForm.dstSiteType
  )
  const defaultDecision = rule?.allowed_tax_decisions?.find((d: any) => d.default)
  return defaultDecision?.tax_decision_code ?? ''
})

const derivedTaxRule = computed(() => {
  const ruleset = rules.value?.tax_transformation_rules ?? []
  if (!movementForm.intent || !movementForm.srcSiteType || !movementForm.dstSiteType || !movementForm.srcLotTaxType) return null
  return ruleset.find((rule: any) =>
    rule.movement_intent === movementForm.intent &&
    rule.src_site_type === movementForm.srcSiteType &&
    rule.dst_site_type === movementForm.dstSiteType &&
    rule.lot_tax_type === movementForm.srcLotTaxType
  ) ?? null
})

const derivedTaxDecision = computed(() => {
  const decisions = derivedTaxRule.value?.allowed_tax_decisions ?? []
  if (!decisions.length) return null
  const selected = decisions.find((d: any) => d.tax_decision_code === movementForm.taxDecisionCode)
  if (selected) return selected
  return decisions.find((d: any) => d.default) ?? decisions[0]
})

const derivedTaxEvent = computed(() => derivedTaxDecision.value?.tax_event ?? '')
const derivedRuleId = computed(() => derivedTaxRule.value?.movement_intent ? `${derivedTaxRule.value.movement_intent}` : '')

const intentRuleSummary = computed(() => {
  if (!selectedIntentRule.value) return null
  return {
    edgeType: selectedIntentRule.value.edge_type ?? '—',
    src: (selectedIntentRule.value.allowed_src_site_types ?? []).join(', ') || '—',
    dst: (selectedIntentRule.value.allowed_dst_site_types ?? []).join(', ') || '—',
  }
})

const srcSiteTypeOptions = computed(() => allowedSrcSiteTypes.value)
const dstSiteTypeOptions = computed(() => allowedDstSiteTypes.value)

const filteredSrcSiteOptions = computed(() => {
  if (!movementForm.srcSiteType) return siteOptions.value
  return siteOptions.value.filter((site) => site.siteTypeKey === movementForm.srcSiteType)
})

const filteredDstSiteOptions = computed(() => {
  if (!movementForm.dstSiteType) return siteOptions.value
  return siteOptions.value.filter((site) => site.siteTypeKey === movementForm.dstSiteType)
})

const selectedLots = computed(() => lotOptions.value.filter((lot) => movementForm.srcLots.includes(lot.id)))

const selectedLotTaxTypeSet = computed(() => {
  const set = new Set<string>()
  selectedLots.value.forEach((lot) => {
    if (lot.lotTaxType) set.add(lot.lotTaxType)
  })
  return Array.from(set)
})

watch(
  () => [movementForm.intent, movementForm.srcSiteType, movementForm.dstSiteType, movementForm.srcLotTaxType],
  () => {
    const decisions = taxDecisionOptions.value
    if (decisions.length === 1) {
      movementForm.taxDecisionCode = decisions[0].value
      movementForm.taxDecisionReason = ''
    } else if (!decisions.find((d) => d.value === movementForm.taxDecisionCode)) {
      movementForm.taxDecisionCode = defaultTaxDecisionCode.value || ''
    }
  }
)

watch(
  () => movementForm.srcSite,
  async (value) => {
    if (!value) {
      lotOptions.value = []
      movementForm.srcLots = []
      movementForm.srcLotTaxType = ''
      return
    }
    await loadLotsForSite(value)
  }
)

watch(
  () => movementForm.srcLots,
  () => {
    const types = selectedLotTaxTypeSet.value
    if (types.length === 1) {
      movementForm.srcLotTaxType = types[0]
    } else {
      movementForm.srcLotTaxType = ''
    }
  },
  { deep: true }
)

function parseJsonc(raw: string) {
  const noBlock = raw.replace(/\/\*[\s\S]*?\*\//g, '')
  const noLine = noBlock.replace(/^\s*\/\/.*$/gm, '')
  return JSON.parse(noLine)
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved')
  tenantId.value = id
  return id
}

const defKeyToRuleKey: Record<string, string> = {
  brewery: 'BREWERY_MANUFACTUR',
  brewery_storage: 'BREWERY_STORAGE',
  tax_storage: 'TAX_STORAGE',
  domestic_customer: 'DOMESTIC_CUSTOMER',
  oversea_customer: 'OVERSEA_CUSTOMER',
  other_brewery: 'OTHER_BREWERY',
  disposal_facility: 'DISPOSAL_FACILITY',
  direct_sales_shop: 'DIRECT_SALES_SHOP',
}

async function loadSites() {
  const tenant = await ensureTenant()
  const { data: siteTypeDefs, error: defError } = await supabase
    .from('registry_def')
    .select('def_id, def_key')
    .eq('kind', 'site_type')
    .eq('is_active', true)
  if (defError) throw defError
  const typeMap = new Map<string, string>()
  ;(siteTypeDefs ?? []).forEach((row: any) => {
    typeMap.set(row.def_id, row.def_key)
  })
  const { data: sites, error } = await supabase
    .from('mst_sites')
    .select('id, code, name, site_type_id')
    .eq('tenant_id', tenant)
    .eq('active', true)
    .order('code')
  if (error) throw error
  siteOptions.value = (sites ?? []).map((row: any) => {
    const defKey = typeMap.get(row.site_type_id) ?? null
    const ruleKey = defKey ? defKeyToRuleKey[defKey] ?? null : null
    return {
      id: row.id,
      label: `${row.code} — ${row.name}`,
      siteTypeKey: ruleKey,
    }
  })
}

async function loadLotsForSite(siteId: string) {
  const tenant = await ensureTenant()
  const { data: lineRows, error } = await supabase
    .from('inv_movement_lines')
    .select('id, batch_id, meta, movement:movement_id ( src_site_id )')
    .eq('tenant_id', tenant)
    .eq('movement.src_site_id', siteId)
  if (error) throw error
  const batchIds = Array.from(new Set((lineRows ?? []).map((row: any) => row.batch_id).filter(Boolean)))
  const uomIds = Array.from(new Set((lineRows ?? []).map((row: any) => row.meta?.uom_id).filter(Boolean)))
  const packageIds = Array.from(new Set((lineRows ?? []).map((row: any) => row.meta?.package_id).filter(Boolean)))

  const batchMap = new Map<string, string>()
  const batchLabelMap = new Map<string, string>()
  const relatedBatchMap = new Map<string, string | null>()
  if (batchIds.length) {
    const { data: batchRows, error: batchError } = await supabase
      .from('mes_batches')
      .select('id, batch_code, batch_label, meta')
      .eq('tenant_id', tenant)
      .in('id', batchIds)
    if (batchError) throw batchError
    ;(batchRows ?? []).forEach((row: any) => {
      batchMap.set(row.id, row.batch_code)
      batchLabelMap.set(row.id, row.batch_label ?? '')
      const related = row.meta?.related_batch_id
      relatedBatchMap.set(row.id, typeof related === 'string' ? related : null)
    })
  }

  const relatedIds = Array.from(new Set(Array.from(relatedBatchMap.values()).filter(Boolean))) as string[]
  const relatedCodeMap = new Map<string, string>()
  if (relatedIds.length) {
    const { data: relatedRows, error: relatedError } = await supabase
      .from('mes_batches')
      .select('id, batch_code')
      .eq('tenant_id', tenant)
      .in('id', relatedIds)
    if (relatedError) throw relatedError
    ;(relatedRows ?? []).forEach((row: any) => relatedCodeMap.set(row.id, row.batch_code))
  }

  const uomMap = new Map<string, string>()
  if (uomIds.length) {
    const { data: uomRows, error: uomError } = await supabase
      .from('mst_uom')
      .select('id, code')
      .in('id', uomIds)
    if (uomError) throw uomError
    ;(uomRows ?? []).forEach((row: any) => uomMap.set(row.id, row.code))
  }

  const packageMap = new Map<string, string>()
  if (packageIds.length) {
    const { data: pkgRows, error: pkgError } = await supabase
      .from('mst_package')
      .select('id, package_code, name_i18n, unit_volume, volume_uom')
      .in('id', packageIds)
    if (pkgError) throw pkgError
    ;(pkgRows ?? []).forEach((row: any) => {
      const name = row.name_i18n ? Object.values(row.name_i18n)[0] : ''
      const size = row.unit_volume != null ? `${row.unit_volume}${row.volume_uom ? ` ${row.volume_uom}` : ''}` : ''
      const label = [row.package_code, name, size].filter(Boolean).join(' / ')
      packageMap.set(row.id, label)
    })
  }

  lotOptions.value = (lineRows ?? []).map((row: any) => ({
    id: row.batch_id ?? row.id,
    label: batchMap.get(row.batch_id) ?? row.batch_id ?? row.id,
    lotTaxType: typeof row.meta?.lot_tax_type === 'string' ? row.meta.lot_tax_type : null,
    lotCode: batchMap.get(row.batch_id) ?? null,
    relatedBatchCode: row.batch_id && relatedBatchMap.get(row.batch_id)
      ? relatedCodeMap.get(relatedBatchMap.get(row.batch_id) as string) ?? null
      : null,
    batchLabel: row.batch_id ? batchLabelMap.get(row.batch_id) ?? null : null,
    packageLabel: row.meta?.package_id ? packageMap.get(row.meta.package_id) ?? null : null,
    quantity: typeof row.meta?.quantity === 'number' ? row.meta.quantity : null,
    uomCode: row.meta?.uom_id ? uomMap.get(row.meta.uom_id) ?? null : null,
  }))
}

function nextStep() {
  if (currentStep.value < wizardSteps.value.length) currentStep.value += 1
}

function prevStep() {
  if (currentStep.value > 1) currentStep.value -= 1
}

function goBack() {
  router.back()
}

onMounted(() => {
  rules.value = parseJsonc(movementRuleRaw) as MovementRules
  loadSites().catch((err) => console.error(err))
})
</script>
