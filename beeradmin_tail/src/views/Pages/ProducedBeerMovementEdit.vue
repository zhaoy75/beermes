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
            <p class="text-sm text-gray-500">Step 1〜5 を順に入力してください。</p>
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
                <h3 class="text-base font-semibold">Step 1: movement_intent</h3>
                <p class="text-sm text-gray-500">ルールファイルから intent を読み込みます。</p>
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
            </section>

            <section v-if="currentStep === 2" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">Step 2: src/dst site</h3>
                <p class="text-sm text-gray-500">Site type と default tax を system が導出します。</p>
              </header>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Source Site</label>
                  <input v-model.trim="movementForm.srcSite" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Destination Site</label>
                  <input v-model.trim="movementForm.dstSite" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Source Site Type (derived)</label>
                  <select v-model="movementForm.srcSiteType" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">Select</option>
                    <option v-for="site in siteTypeOptions" :key="site" :value="site">{{ site }}</option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Destination Site Type (derived)</label>
                  <select v-model="movementForm.dstSiteType" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">Select</option>
                    <option v-for="site in siteTypeOptions" :key="site" :value="site">{{ site }}</option>
                  </select>
                </div>
              </div>

              <div v-if="taxDecisionOptions.length" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Tax Decision Code</label>
                  <select v-model="movementForm.taxDecisionCode" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">Select</option>
                    <option v-for="option in taxDecisionOptions" :key="option.value" :value="option.value">
                      {{ option.label }}
                    </option>
                  </select>
                </div>
              </div>
            </section>

            <section v-if="currentStep === 3" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">Step 3: product / lot</h3>
                <p class="text-sm text-gray-500">Lot 種別により tax が変わる場合があります。</p>
              </header>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Product</label>
                  <input v-model.trim="movementForm.product" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">Source Lot</label>
                  <input v-model.trim="movementForm.srcLot" class="w-full h-[40px] border rounded px-3" />
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
            </section>

            <section v-if="currentStep === 4" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">Step 4: 必要情報</h3>
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
                <h3 class="text-base font-semibold">Step 5: 確認</h3>
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
import { computed, onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import movementRuleRaw from '../../../../docs/data/movementrule.jsonc?raw'

type MovementRules = {
  enums?: Record<string, string[]>
  movement_intent_rules?: Record<string, any>
  tax_decision_definitions?: Record<string, { label?: { ja?: string; en?: string } }>
  tax_transformation_rules?: Array<Record<string, any>>
}

const router = useRouter()
const pageTitle = computed(() => '酒税関連登録')

const currentStep = ref(1)
const wizardSteps = computed(() => ([
  { key: 'intent', label: 'Step 1', index: 1 },
  { key: 'sites', label: 'Step 2', index: 2 },
  { key: 'lot', label: 'Step 3', index: 3 },
  { key: 'info', label: 'Step 4', index: 4 },
  { key: 'confirm', label: 'Step 5', index: 5 },
]))

const rules = ref<MovementRules | null>(null)

const movementForm = reactive({
  intent: '',
  srcSite: '',
  dstSite: '',
  srcSiteType: '',
  dstSiteType: '',
  taxDecisionCode: '',
  product: '',
  srcLot: '',
  srcLotTaxType: '',
  dstLotTaxType: '',
  eventDate: '',
  quantity: '',
  uom: '',
  notes: '',
})

const intentOptions = computed(() => {
  const ruleMap = rules.value?.movement_intent_rules ?? {}
  return Object.keys(ruleMap).map((key) => {
    const label = ruleMap[key]?.label?.ja ?? ruleMap[key]?.label?.en ?? key
    return { value: key, label }
  })
})

const siteTypeOptions = computed(() => rules.value?.enums?.site_type ?? [])
const lotTaxTypeOptions = computed(() => rules.value?.enums?.lot_tax_type ?? [])

const selectedIntentRule = computed(() => {
  if (!movementForm.intent) return null
  return rules.value?.movement_intent_rules?.[movementForm.intent] ?? null
})

const taxDecisionOptions = computed(() => {
  const codes = selectedIntentRule.value?.allowed_tax_decision_codes ?? []
  const defs = rules.value?.tax_decision_definitions ?? {}
  return codes.map((code: string) => {
    const label = defs?.[code]?.label?.ja ?? defs?.[code]?.label?.en ?? code
    return { value: code, label }
  })
})

const derivedTaxRule = computed(() => {
  const ruleset = rules.value?.tax_transformation_rules ?? []
  if (!movementForm.intent || !movementForm.srcSiteType || !movementForm.dstSiteType || !movementForm.srcLotTaxType) return null
  return ruleset.find((rule: any) =>
    rule.movement_intent === movementForm.intent &&
    (rule.tax_decision_code ?? null) === (movementForm.taxDecisionCode || null) &&
    rule.src_site_type === movementForm.srcSiteType &&
    rule.dst_site_type === movementForm.dstSiteType &&
    rule.src_lot_tax_type === movementForm.srcLotTaxType &&
    (movementForm.dstLotTaxType ? rule.dst_lot_tax_type === movementForm.dstLotTaxType : true)
  ) ?? null
})

const derivedTaxEvent = computed(() => derivedTaxRule.value?.tax_event ?? '')
const derivedRuleId = computed(() => derivedTaxRule.value?.rule_id ?? '')

function parseJsonc(raw: string) {
  const noBlock = raw.replace(/\/\*[\s\S]*?\*\//g, '')
  const noLine = noBlock.replace(/^\s*\/\/.*$/gm, '')
  return JSON.parse(noLine)
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
})
</script>
