<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto space-y-6">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('producedBeer.movementWizard.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('producedBeer.movementWizard.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50" @click="goBack">{{ t('producedBeer.movementWizard.back') }}</button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-semibold">{{ t('producedBeer.movementWizard.wizardTitle') }}</h2>
            <p class="text-sm text-gray-500">{{ t('producedBeer.movementWizard.wizardSubtitle') }}</p>
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

        <div class="space-y-6">
          <div class="space-y-6">
            <section v-if="currentStep === 1" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">{{ t('producedBeer.movementWizard.intent.title') }}</h3>
                <p class="text-sm text-gray-500">{{ t('producedBeer.movementWizard.intent.subtitle') }}</p>
              </header>
              <p v-if="intentLoadError" class="text-xs text-red-600">{{ intentLoadError }}</p>
              <p v-else-if="intentsLoading" class="text-xs text-gray-500">{{ t('producedBeer.movementWizard.intent.loading') }}</p>
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
                <h3 class="text-base font-semibold">{{ t('producedBeer.movementWizard.sites.title') }}</h3>
                <p class="text-sm text-gray-500">{{ t('producedBeer.movementWizard.sites.subtitle') }}</p>
              </header>
              <p v-if="rulesLoadError" class="text-xs text-red-600">{{ rulesLoadError }}</p>
              <p v-else-if="rulesLoading" class="text-xs text-gray-500">{{ t('producedBeer.movementWizard.sites.loading') }}</p>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.sourceSiteType') }}</label>
                  <select v-model="movementForm.srcSiteType" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">{{ t('common.select') }}</option>
                    <option v-for="site in srcSiteTypeOptions" :key="site" :value="site">{{ siteTypeLabel(site) }}</option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.destinationSiteType') }}</label>
                  <select v-model="movementForm.dstSiteType" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">{{ t('common.select') }}</option>
                    <option v-for="site in dstSiteTypeOptions" :key="site" :value="site">{{ siteTypeLabel(site) }}</option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.sourceSite') }}</label>
                  <select v-model="movementForm.srcSite" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">{{ t('common.select') }}</option>
                    <option v-for="site in filteredSrcSiteOptions" :key="site.id" :value="site.id">{{ siteOptionLabel(site) }}</option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.destinationSite') }}</label>
                  <select v-model="movementForm.dstSite" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">{{ t('common.select') }}</option>
                    <option v-for="site in filteredDstSiteOptions" :key="site.id" :value="site.id">{{ siteOptionLabel(site) }}</option>
                  </select>
                </div>
              </div>

              <div v-if="taxDecisionOptions.length" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.taxDecisionCode') }}</label>
                  <p class="text-xs text-gray-500 mb-2">
                    {{ t('producedBeer.movementWizard.fields.defaultTaxDecision') }}: {{ taxDecisionLabel(defaultTaxDecisionCode) }}
                  </p>
                  <select v-model="movementForm.taxDecisionCode" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">{{ t('common.select') }}</option>
                    <option v-for="option in taxDecisionOptions" :key="option.value" :value="option.value">
                      {{ option.label }}
                    </option>
                  </select>
                </div>
                <div v-if="movementForm.taxDecisionCode && movementForm.taxDecisionCode !== defaultTaxDecisionCode">
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.reasonNonDefault') }}</label>
                  <input v-model.trim="movementForm.taxDecisionReason" class="w-full h-[40px] border rounded px-3" />
                  <p v-if="!movementForm.taxDecisionReason" class="mt-1 text-xs text-amber-600">{{ t('producedBeer.movementWizard.fields.reasonNonDefaultHint') }}</p>
                </div>
              </div>
            </section>

            <section v-if="currentStep === 3" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">{{ t('producedBeer.movementWizard.lots.title') }}</h3>
                <p class="text-sm text-gray-500">{{ t('producedBeer.movementWizard.lots.subtitle') }}</p>
              </header>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.product') }}</label>
                  <input v-model.trim="movementForm.product" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.sourceLotTaxType') }}</label>
                  <select v-model="movementForm.srcLotTaxType" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">{{ t('common.select') }}</option>
                    <option v-for="lotType in lotTaxTypeOptions" :key="lotType" :value="lotType">{{ lotTaxTypeLabel(lotType) }}</option>
                  </select>
                </div>
              </div>
              <div class="overflow-x-auto border border-gray-200 rounded-lg">
                <table class="min-w-full text-sm divide-y divide-gray-200">
                  <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                    <tr>
                      <th class="px-3 py-2 text-left">{{ t('producedBeer.movementWizard.table.select') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('producedBeer.movementWizard.table.lotCode') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('producedBeer.movementWizard.table.beerCategory') }}</th>
                      <th class="px-3 py-2 text-right">{{ t('producedBeer.movementWizard.table.targetAbv') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('producedBeer.movementWizard.table.styleName') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('producedBeer.movementWizard.table.batchCode') }}</th>
                      <th class="px-3 py-2 text-right">{{ t('producedBeer.movementWizard.table.packageVolume') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('producedBeer.movementWizard.table.packageUom') }}</th>
                      <th class="px-3 py-2 text-right">{{ t('producedBeer.movementWizard.table.quantity') }}</th>
                      <th class="px-3 py-2 text-right">{{ t('producedBeer.movementWizard.table.movementQuantity') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('producedBeer.movementWizard.table.uom') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr
                      v-for="lot in lotOptions"
                      :key="lot.id"
                      :class="['hover:bg-gray-50', isLotEventDivergent(lot) ? 'bg-amber-50' : '']"
                    >
                      <td class="px-3 py-2">
                        <input v-model="movementForm.srcLots" type="checkbox" :value="lot.id" />
                      </td>
                      <td class="px-3 py-2 text-gray-700">{{ lot.lotCode || lot.label }}</td>
                      <td class="px-3 py-2 text-gray-700">{{ alcoholTypeLabel(lot.beerCategoryId) }}</td>
                      <td class="px-3 py-2 text-right text-gray-700">{{ formatAbv(lot.targetAbv) }}</td>
                      <td class="px-3 py-2 text-gray-700">{{ lot.styleName || '—' }}</td>
                      <td class="px-3 py-2 text-gray-700">{{ lot.batchCode || '—' }}</td>
                      <td class="px-3 py-2 text-right text-gray-700">{{ formatNumber(lot.packageVolume) }}</td>
                      <td class="px-3 py-2 text-gray-700">{{ lot.packageUom || '—' }}</td>
                      <td class="px-3 py-2 text-right text-gray-700">{{ formatNumber(displayLotQuantity(lot)) }}</td>
                      <td class="px-3 py-2">
                        <input
                          v-model="movementForm.srcLotMoveQty[lot.id]"
                          type="number"
                          :step="isPackagedMoveInput(lot) ? '1' : '0.001'"
                          min="0"
                          :max="displayLotQuantity(lot) ?? undefined"
                          class="w-28 h-[34px] border rounded px-2 text-right disabled:bg-gray-100 disabled:text-gray-400"
                          :disabled="!movementForm.srcLots.includes(lot.id)"
                        />
                      </td>
                      <td class="px-3 py-2 text-gray-700">{{ movementInputUomLabel(lot) }}</td>
                    </tr>
                    <tr v-if="lotOptions.length === 0">
                      <td class="px-3 py-6 text-center text-gray-500" colspan="11">{{ t('producedBeer.movementWizard.table.noLotsFound') }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <p v-if="selectedLotTaxTypeSet.length > 1" class="text-xs text-amber-600">
                {{ t('producedBeer.movementWizard.lots.multiTaxTypeWarning') }}
              </p>
              <p v-if="hasMultipleCandidateTaxEvents" class="text-xs text-amber-600">
                {{ t('producedBeer.movementWizard.lots.multiEventWarning') }}:
                {{ distinctCandidateTaxEvents.map((eventCode) => taxEventLabel(eventCode)).join(' / ') }}
              </p>
            </section>

            <section v-if="currentStep === 4" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">{{ t('producedBeer.movementWizard.info.title') }}</h3>
                <p class="text-sm text-gray-500">{{ t('producedBeer.movementWizard.info.subtitle') }}</p>
              </header>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.unitPrice') }}</label>
                  <input v-model="movementForm.unitPrice" type="number" step="0.01" min="0" class="w-full h-[40px] border rounded px-3 text-right" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.price') }}</label>
                  <input v-model="movementForm.price" type="number" step="0.01" min="0" class="w-full h-[40px] border rounded px-3 text-right" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.notes') }}</label>
                  <input v-model.trim="movementForm.notes" class="w-full h-[40px] border rounded px-3" />
                </div>
              </div>
            </section>

            <section v-if="currentStep === 5" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">{{ t('producedBeer.movementWizard.confirm.title') }}</h3>
                <p class="text-sm text-gray-500">{{ t('producedBeer.movementWizard.confirm.subtitle') }}</p>
              </header>
              <div class="rounded-lg border border-gray-200 p-4 space-y-2 text-sm text-gray-600">
                <div>{{ t('producedBeer.movementWizard.confirmRows.movementIntent') }}: <span class="text-gray-900">{{ intentLabel(movementForm.intent) }}</span></div>
                <div>{{ t('producedBeer.movementWizard.confirmRows.srcSiteType') }}: <span class="text-gray-900">{{ siteTypeLabel(movementForm.srcSiteType) }}</span></div>
                <div>{{ t('producedBeer.movementWizard.confirmRows.dstSiteType') }}: <span class="text-gray-900">{{ siteTypeLabel(movementForm.dstSiteType) }}</span></div>
                <div>{{ t('producedBeer.movementWizard.confirmRows.taxDecisionCode') }}: <span class="text-gray-900">{{ taxDecisionLabel(movementForm.taxDecisionCode) }}</span></div>
                <div>{{ t('producedBeer.movementWizard.confirmRows.taxEvent') }}: <span class="text-gray-900">{{ taxEventLabel(derivedTaxEvent) }}</span></div>
                <div>{{ t('producedBeer.movementWizard.confirmRows.ruleId') }}: <span class="text-gray-900">{{ derivedRuleId || '—' }}</span></div>
              </div>
            </section>
          </div>

        </div>

        <footer class="flex flex-wrap items-center justify-between gap-3">
          <div class="flex items-center gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="prevStep" :disabled="currentStep === 1">
              {{ t('producedBeer.movementWizard.actions.prev') }}
            </button>
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="nextStep" :disabled="currentStep === wizardSteps.length">
              {{ t('producedBeer.movementWizard.actions.next') }}
            </button>
          </div>
          <div class="flex items-center gap-2">
            <button
              class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
              type="button"
              :disabled="saving || currentStep !== wizardSteps.length"
              @click="saveMovement"
            >
              {{ t('producedBeer.movementWizard.actions.post') }}
            </button>
          </div>
        </footer>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

type RuleLabel = { ja?: string; en?: string }

type MovementRules = {
  enums?: Record<string, string[]>
  site_type_labels?: Record<string, RuleLabel>
  lot_tax_type_labels?: Record<string, RuleLabel>
  tax_event_labels?: Record<string, RuleLabel>
  edge_type_labels?: Record<string, RuleLabel>
  tax_decision_code_labels?: Record<string, RuleLabel>
  movement_intent_rules?: Array<Record<string, any>>
  tax_decision_definitions?: Array<Record<string, any>>
  tax_transformation_rules?: Array<Record<string, any>>
}

const router = useRouter()
const { t, locale } = useI18n()
const pageTitle = computed(() => t('producedBeer.movementWizard.title'))

const currentStep = ref(1)
const wizardSteps = computed(() => ([
  { key: 'intent', label: t('producedBeer.movementWizard.steps.step1'), index: 1 },
  { key: 'sites', label: t('producedBeer.movementWizard.steps.step2'), index: 2 },
  { key: 'lot', label: t('producedBeer.movementWizard.steps.step3'), index: 3 },
  { key: 'info', label: t('producedBeer.movementWizard.steps.step4'), index: 4 },
  { key: 'confirm', label: t('producedBeer.movementWizard.steps.step5'), index: 5 },
]))

const rules = ref<MovementRules | null>(null)
const tenantId = ref<string | null>(null)
const intentsLoading = ref(false)
const rulesLoading = ref(false)
const intentLoadError = ref('')
const rulesLoadError = ref('')
const intentOptions = ref<Array<{ value: string; label: string }>>([])

type SiteOption = {
  id: string
  name: string
  siteTypeKey: string | null
}

type LotOption = {
  id: string
  label: string
  lotTaxType: string | null
  lotCode: string | null
  batchCode: string | null
  beerCategoryId: string | null
  targetAbv: number | null
  styleName: string | null
  packageId: string | null
  packageVolume: number | null
  packageUom: string | null
  quantity: number | null
  uomId: string | null
  uomCode: string | null
}

const siteOptions = ref<SiteOption[]>([])
const lotOptions = ref<LotOption[]>([])
const alcoholTypeLabels = ref<Record<string, string>>({})
const saving = ref(false)

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
  srcLotMoveQty: {} as Record<string, string>,
  srcLotTaxType: '',
  unitPrice: '',
  price: '',
  notes: '',
})

function pickLabel(label: RuleLabel | null | undefined, fallback: string) {
  if (!label) return fallback
  const isJa = String(locale.value || '').toLowerCase().startsWith('ja')
  if (isJa) return label.ja || label.en || fallback
  return label.en || label.ja || fallback
}

function mapLabel(map: Record<string, RuleLabel> | undefined, code: string | null | undefined) {
  if (!code) return '—'
  return pickLabel(map?.[code], code)
}

function intentLabel(code: string | null | undefined) {
  if (!code) return '—'
  const row = intentOptions.value.find((item) => item.value === code)
  return row?.label || code
}

function siteTypeLabel(code: string | null | undefined) {
  return mapLabel(rules.value?.site_type_labels, code)
}

function siteOptionLabel(site: SiteOption) {
  const base = site.name || site.id
  if (!site.siteTypeKey) return base
  const typeLabel = siteTypeLabel(site.siteTypeKey)
  if (!typeLabel || typeLabel === site.siteTypeKey) return base
  return `${base} (${typeLabel})`
}

function lotTaxTypeLabel(code: string | null | undefined) {
  return mapLabel(rules.value?.lot_tax_type_labels, code)
}

function taxEventLabel(code: string | null | undefined) {
  return mapLabel(rules.value?.tax_event_labels, code)
}

function taxDecisionLabel(code: string | null | undefined) {
  if (!code) return '—'
  const option = taxDecisionOptions.value.find((item) => item.value === code)
  if (option?.label) return option.label
  return mapLabel(rules.value?.tax_decision_code_labels, code)
}

const numberFormatter = computed(() => new Intl.NumberFormat(locale.value, { maximumFractionDigits: 3 }))

function formatNumber(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return numberFormatter.value.format(value)
}

function formatAbv(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return `${numberFormatter.value.format(value)}%`
}

function normalizeVolumeUom(code: string | null | undefined) {
  if (!code) return null
  const normalized = code.trim().toLowerCase()
  if (!normalized) return null
  return normalized
}

function toLiters(value: number, uomCode: string | null | undefined) {
  const uom = normalizeVolumeUom(uomCode)
  if (uom == null || uom === 'l') return value
  if (uom === 'ml') return value / 1000
  if (uom === 'gal_us') return value * 3.78541
  return null
}

function fromLiters(valueLiters: number, uomCode: string | null | undefined) {
  const uom = normalizeVolumeUom(uomCode)
  if (uom == null || uom === 'l') return valueLiters
  if (uom === 'ml') return valueLiters * 1000
  if (uom === 'gal_us') return valueLiters / 3.78541
  return null
}

function isVolumeUom(code: string | null | undefined) {
  const normalized = normalizeVolumeUom(code)
  return normalized === 'l' || normalized === 'ml' || normalized === 'gal_us'
}

function packageUnitVolumeInLotUom(lot: LotOption) {
  if (lot.packageVolume == null || !Number.isFinite(lot.packageVolume) || lot.packageVolume <= 0) return null
  const fromUom = normalizeVolumeUom(lot.packageUom)
  const toUom = normalizeVolumeUom(lot.uomCode)
  if (!fromUom || !toUom || fromUom === toUom) return lot.packageVolume
  const liters = toLiters(lot.packageVolume, fromUom)
  if (liters == null) return null
  return fromLiters(liters, toUom)
}

function isPackagedMoveInput(lot: LotOption) {
  return Boolean(lot.packageId)
}

function displayLotQuantity(lot: LotOption) {
  if (lot.quantity == null || Number.isNaN(lot.quantity)) return null
  if (!isPackagedMoveInput(lot)) return lot.quantity
  const unitVolume = packageUnitVolumeInLotUom(lot)
  if (unitVolume != null && unitVolume > 0) return lot.quantity / unitVolume
  return lot.quantity
}

function movementInputUomLabel(lot: LotOption) {
  if (isPackagedMoveInput(lot)) return t('producedBeer.movementWizard.table.package')
  return lot.uomCode || '—'
}

function toNumber(value: any): number | null {
  if (value == null || value === '') return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function resolveMetaString(meta: Record<string, any> | null | undefined, key: string) {
  const value = meta?.[key]
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  return trimmed.length ? trimmed : null
}

function resolveMetaNumber(meta: Record<string, any> | null | undefined, key: string) {
  const value = meta?.[key]
  if (value == null) return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function alcoholTypeLabel(code: string | null | undefined) {
  if (!code) return '—'
  return alcoholTypeLabels.value[code] ?? code
}

async function saveMovement() {
  if (saving.value) return
  try {
    if (!movementForm.intent) throw new Error('movement_intent is required')
    if (!movementForm.srcSite || !movementForm.dstSite) throw new Error('src/dst site is required')
    if (!movementForm.taxDecisionCode) throw new Error('tax_decision_code is required')
    if (!movementForm.srcLots.length) throw new Error('select at least one lot')
    if (movementForm.taxDecisionCode !== defaultTaxDecisionCode.value && !movementForm.taxDecisionReason.trim()) {
      throw new Error('reason is required for non-default tax decision')
    }

    const selectedRows = lotOptions.value.filter((lot) => movementForm.srcLots.includes(lot.id))
    if (!selectedRows.length) throw new Error('selected lot rows not found')

    const errors: string[] = []
    const rows = selectedRows.map((lot) => {
      const rawQty = movementForm.srcLotMoveQty[lot.id]
      const inputQty = toNumber(rawQty)
      if (inputQty == null || inputQty <= 0) errors.push(`invalid movement quantity for lot ${lot.lotCode || lot.id}`)
      if (!lot.uomId) errors.push(`uom is missing for lot ${lot.lotCode || lot.id}`)
      const usePackageInput = isPackagedMoveInput(lot)
      const unitVolume = packageUnitVolumeInLotUom(lot)
      if (usePackageInput && unitVolume == null && isVolumeUom(lot.uomCode)) {
        errors.push(`package volume is missing for lot ${lot.lotCode || lot.id}`)
      }
      const qty = usePackageInput
        ? ((unitVolume != null && unitVolume > 0) ? (inputQty ?? 0) * unitVolume : (inputQty ?? 0))
        : (inputQty ?? 0)

      const maxQty = lot.quantity
      if (maxQty != null && Number.isFinite(maxQty) && qty > maxQty + 1e-9) {
        errors.push(`movement quantity exceeds available quantity for lot ${lot.lotCode || lot.id}`)
      }

      return {
        lot,
        qty,
        packageQty: usePackageInput ? (inputQty ?? 0) : null,
      }
    })
    if (errors.length) throw new Error(errors[0])

    saving.value = true
    const baseKey = `produced_beer_move:${Date.now()}`
    const createdIds: string[] = []
    for (let i = 0; i < rows.length; i += 1) {
      const row = rows[i]
      const payload = {
        movement_intent: movementForm.intent,
        src_site: movementForm.srcSite,
        dst_site: movementForm.dstSite,
        src_lot_id: row.lot.id,
        qty: row.qty,
        uom_id: row.lot.uomId,
        tax_decision_code: movementForm.taxDecisionCode,
        reason: movementForm.taxDecisionReason.trim() || null,
        notes: movementForm.notes.trim() || null,
        meta: {
          source: 'produced_beer_movement_ui',
          unit_price: toNumber(movementForm.unitPrice),
          price: toNumber(movementForm.price),
          package_qty: row.packageQty,
          idempotency_key: `${baseKey}:${i + 1}:${row.lot.id}`,
        },
      }
      const { data, error } = await supabase.rpc('product_move', { p_doc: payload })
      if (error) throw error
      if (data) createdIds.push(String(data))
    }
    toast.success(`Posted ${createdIds.length} movement(s).`)
    router.push({ path: '/producedBeer' })
  } catch (err: any) {
    console.error(err)
    toast.error(err?.message ?? 'Failed to save movement')
  } finally {
    saving.value = false
  }
}

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
    const isJa = String(locale.value || '').toLowerCase().startsWith('ja')
    const label = isJa
      ? (def?.name_ja ?? def?.name_en ?? mapLabel(rules.value?.tax_decision_code_labels, code))
      : (def?.name_en ?? def?.name_ja ?? mapLabel(rules.value?.tax_decision_code_labels, code))
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

function previewTaxEventForLotType(lotTaxType: string | null | undefined) {
  if (!lotTaxType) return ''
  const ruleset = rules.value?.tax_transformation_rules ?? []
  if (!movementForm.intent || !movementForm.srcSiteType || !movementForm.dstSiteType) return ''
  const rule = ruleset.find((item: any) =>
    item.movement_intent === movementForm.intent &&
    item.src_site_type === movementForm.srcSiteType &&
    item.dst_site_type === movementForm.dstSiteType &&
    item.lot_tax_type === lotTaxType
  )
  if (!rule) return ''
  const decisions = rule.allowed_tax_decisions ?? []
  if (!decisions.length) return ''
  const selected = decisions.find((d: any) => d.tax_decision_code === movementForm.taxDecisionCode)
  const decision = selected ?? decisions.find((d: any) => d.default) ?? decisions[0]
  return decision?.tax_event ?? ''
}

const candidateTaxEventByLotId = computed(() => {
  const result = new Map<string, string>()
  lotOptions.value.forEach((lot) => {
    const eventCode = previewTaxEventForLotType(lot.lotTaxType)
    if (eventCode) result.set(lot.id, eventCode)
  })
  return result
})

const distinctCandidateTaxEvents = computed(() =>
  Array.from(new Set(Array.from(candidateTaxEventByLotId.value.values()).filter(Boolean)))
)

const hasMultipleCandidateTaxEvents = computed(() => distinctCandidateTaxEvents.value.length > 1)

const baseCandidateTaxEvent = computed(() => {
  if (movementForm.srcLotTaxType) return previewTaxEventForLotType(movementForm.srcLotTaxType)
  return distinctCandidateTaxEvents.value[0] ?? ''
})

function isLotEventDivergent(lot: LotOption) {
  if (!hasMultipleCandidateTaxEvents.value) return false
  const eventCode = candidateTaxEventByLotId.value.get(lot.id) ?? ''
  if (!eventCode) return false
  const base = baseCandidateTaxEvent.value
  if (!base) return false
  return eventCode !== base
}

watch(
  () => movementForm.intent,
  async (value, oldValue) => {
    if (value === oldValue) return
    movementForm.srcSite = ''
    movementForm.dstSite = ''
    movementForm.srcSiteType = ''
    movementForm.dstSiteType = ''
    movementForm.taxDecisionCode = ''
    movementForm.taxDecisionReason = ''
    movementForm.srcLots = []
    movementForm.srcLotMoveQty = {}
    movementForm.srcLotTaxType = ''
    lotOptions.value = []

    if (!value) {
      rules.value = null
      return
    }

    await loadRulesForIntent(value)
  }
)

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
      movementForm.srcLotMoveQty = {}
      movementForm.srcLotTaxType = ''
      return
    }
    await loadLotsForSite(value)
  }
)

watch(
  () => movementForm.srcLots,
  () => {
    const selected = new Set(movementForm.srcLots)
    Object.keys(movementForm.srcLotMoveQty).forEach((lotId) => {
      if (!selected.has(lotId)) delete movementForm.srcLotMoveQty[lotId]
    })
    const types = selectedLotTaxTypeSet.value
    if (types.length === 1) {
      movementForm.srcLotTaxType = types[0]
    } else {
      movementForm.srcLotTaxType = ''
    }
  },
  { deep: true }
)

watch(
  () => locale.value,
  () => {
    loadMovementIntents().catch((err) => console.error(err))
    loadAlcoholTypes().catch((err) => console.error(err))
  }
)

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved')
  tenantId.value = id
  return id
}

async function loadMovementIntents() {
  intentLoadError.value = ''
  intentsLoading.value = true
  try {
    const { data, error } = await supabase.rpc('movement_get_movement_ui_intent')
    if (error) throw error
    intentOptions.value = (data ?? [])
      .map((row: any) => ({
        value: String(row?.movement_intent ?? ''),
        label: String(
          String(locale.value || '').toLowerCase().startsWith('ja')
            ? (row?.name_ja ?? row?.name_en ?? row?.movement_intent ?? '')
            : (row?.name_en ?? row?.name_ja ?? row?.movement_intent ?? '')
        ),
      }))
      .filter((row: { value: string }) => !!row.value)
  } catch (err: any) {
    console.error(err)
    intentOptions.value = []
    intentLoadError.value = err?.message ?? t('producedBeer.movementWizard.errors.loadIntents')
  } finally {
    intentsLoading.value = false
  }
}

async function loadRulesForIntent(movementIntent: string) {
  rulesLoadError.value = ''
  rulesLoading.value = true
  try {
    const { data, error } = await supabase.rpc('movement_get_rules', {
      p_movement_intent: movementIntent,
    })
    if (error) throw error
    rules.value = ((Array.isArray(data) ? data[0] : data) ?? null) as MovementRules | null
  } catch (err: any) {
    console.error(err)
    rules.value = null
    rulesLoadError.value = err?.message ?? t('producedBeer.movementWizard.errors.loadRules')
  } finally {
    rulesLoading.value = false
  }
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
    .select('id, name, site_type_id')
    .eq('tenant_id', tenant)
    .eq('active', true)
    .order('name')
  if (error) throw error
  siteOptions.value = (sites ?? []).map((row: any) => {
    const defKey = typeMap.get(row.site_type_id) ?? null
    const ruleKey = defKey ? defKeyToRuleKey[defKey] ?? null : null
    return {
      id: row.id,
      name: row.name ?? row.id,
      siteTypeKey: ruleKey,
    }
  })
}

async function loadAlcoholTypes() {
  const { data, error } = await supabase
    .from('registry_def')
    .select('def_id, def_key, spec')
    .eq('kind', 'alcohol_type')
    .eq('is_active', true)
  if (error) throw error
  const map: Record<string, string> = {}
  ;(data ?? []).forEach((row: any) => {
    const label = typeof row?.spec?.name === 'string' ? row.spec.name : row.def_key
    if (row?.def_id) map[String(row.def_id)] = String(label || row.def_id)
  })
  alcoholTypeLabels.value = map
}

async function loadLotsForSite(siteId: string) {
  const tenant = await ensureTenant()
  const { data: inventoryRows, error } = await supabase
    .from('inv_inventory')
    .select('id, lot_id, qty, uom_id, lot:lot_id ( id, lot_no, batch_id, package_id, lot_tax_type, status )')
    .eq('tenant_id', tenant)
    .eq('site_id', siteId)
    .gt('qty', 0)
  if (error) throw error

  const activeRows = (inventoryRows ?? []).filter((row: any) => {
    const lotRow = Array.isArray(row.lot) ? row.lot[0] : row.lot
    return !lotRow || lotRow.status !== 'void'
  })

  const batchIds = Array.from(new Set(activeRows
    .map((row: any) => (Array.isArray(row.lot) ? row.lot[0] : row.lot)?.batch_id)
    .filter(Boolean)))
  const uomIds = Array.from(new Set(activeRows.map((row: any) => row.uom_id).filter(Boolean)))
  const packageIds = Array.from(new Set(activeRows
    .map((row: any) => (Array.isArray(row.lot) ? row.lot[0] : row.lot)?.package_id)
    .filter(Boolean)))

  const batchMap = new Map<string, string | null>()
  const batchCategoryMap = new Map<string, string | null>()
  const batchTargetAbvMap = new Map<string, number | null>()
  const batchStyleMap = new Map<string, string | null>()
  if (batchIds.length) {
    const attrIdToCode = new Map<string, string>()
    const attrIds: number[] = []
    const attrValueByBatch = new Map<string, {
      beerCategoryId: string | null
      targetAbv: number | null
      styleName: string | null
    }>()

    try {
      const { data: attrDefs, error: attrDefError } = await supabase
        .from('attr_def')
        .select('attr_id, code')
        .eq('domain', 'batch')
        .in('code', ['beer_category', 'target_abv', 'style_name'])
        .eq('is_active', true)
      if (attrDefError) throw attrDefError

      ;(attrDefs ?? []).forEach((row: any) => {
        const id = Number(row.attr_id)
        if (!Number.isFinite(id)) return
        attrIds.push(id)
        attrIdToCode.set(String(row.attr_id), String(row.code))
      })

      if (attrIds.length) {
        const { data: attrValues, error: attrValueError } = await supabase
          .from('entity_attr')
          .select('entity_id, attr_id, value_text, value_num, value_ref_type_id, value_json')
          .eq('entity_type', 'batch')
          .in('entity_id', batchIds)
          .in('attr_id', attrIds)
        if (attrValueError) throw attrValueError

        ;(attrValues ?? []).forEach((row: any) => {
          const batchId = String(row.entity_id ?? '')
          if (!batchId) return
          if (!attrValueByBatch.has(batchId)) {
            attrValueByBatch.set(batchId, {
              beerCategoryId: null,
              targetAbv: null,
              styleName: null,
            })
          }
          const entry = attrValueByBatch.get(batchId)
          if (!entry) return
          const code = attrIdToCode.get(String(row.attr_id))
          if (!code) return

          if (code === 'beer_category') {
            const jsonDefId = row.value_json?.def_id
            if (typeof jsonDefId === 'string' && jsonDefId.trim()) entry.beerCategoryId = jsonDefId.trim()
            else if (typeof row.value_text === 'string' && row.value_text.trim()) entry.beerCategoryId = row.value_text.trim()
            else if (row.value_ref_type_id != null) entry.beerCategoryId = String(row.value_ref_type_id)
          }
          if (code === 'target_abv') {
            const num = toNumber(row.value_num)
            if (num != null) entry.targetAbv = num
          }
          if (code === 'style_name') {
            if (typeof row.value_text === 'string' && row.value_text.trim()) entry.styleName = row.value_text.trim()
          }
        })
      }
    } catch (err) {
      console.warn('Failed to load batch attributes for lot table', err)
    }

    const { data: batchRows, error: batchError } = await supabase
      .from('mes_batches')
      .select('id, batch_code, meta, recipe:recipe_id ( category, target_abv, style )')
      .eq('tenant_id', tenant)
      .in('id', batchIds)
    if (batchError) throw batchError
    ;(batchRows ?? []).forEach((row: any) => {
      const attr = attrValueByBatch.get(row.id)
      const recipe = Array.isArray(row.recipe) ? row.recipe[0] : row.recipe
      const meta = (row.meta && typeof row.meta === 'object' && !Array.isArray(row.meta)) ? row.meta as Record<string, any> : null

      batchMap.set(row.id, row.batch_code ?? null)
      batchCategoryMap.set(
        row.id,
        attr?.beerCategoryId
          ?? (typeof recipe?.category === 'string' ? recipe.category : null)
          ?? resolveMetaString(meta, 'beer_category')
          ?? resolveMetaString(meta, 'category')
          ?? null
      )
      batchTargetAbvMap.set(
        row.id,
        attr?.targetAbv
          ?? toNumber(recipe?.target_abv)
          ?? resolveMetaNumber(meta, 'target_abv')
          ?? null
      )
      batchStyleMap.set(
        row.id,
        attr?.styleName
          ?? (typeof recipe?.style === 'string' ? recipe.style : null)
          ?? resolveMetaString(meta, 'style_name')
          ?? resolveMetaString(meta, 'style')
          ?? null
      )
    })
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

  const packageVolumeMap = new Map<string, number | null>()
  const packageUomMap = new Map<string, string | null>()
  if (packageIds.length) {
    const { data: pkgRows, error: pkgError } = await supabase
      .from('mst_package')
      .select('id, unit_volume, volume_uom')
      .in('id', packageIds)
    if (pkgError) throw pkgError
    ;(pkgRows ?? []).forEach((row: any) => {
      packageVolumeMap.set(row.id, toNumber(row.unit_volume))
      packageUomMap.set(row.id, typeof row.volume_uom === 'string' ? row.volume_uom : null)
    })
  }

  const optionMap = new Map<string, LotOption>()
  activeRows.forEach((row: any) => {
    const lotRow = Array.isArray(row.lot) ? row.lot[0] : row.lot
    const lotId = lotRow?.id ?? row.lot_id ?? row.id
    if (!lotId) return
    const batchId = lotRow?.batch_id ?? null
    const qtyValue = Number(row.qty)
    const qty = Number.isFinite(qtyValue) ? qtyValue : 0
    const existing = optionMap.get(lotId)
    if (existing) {
      existing.quantity = (existing.quantity ?? 0) + qty
      return
    }
    optionMap.set(lotId, {
      id: lotId,
      label: lotRow?.lot_no ?? lotId,
      lotTaxType: typeof lotRow?.lot_tax_type === 'string' ? lotRow.lot_tax_type : null,
      lotCode: lotRow?.lot_no ?? null,
      batchCode: batchId ? batchMap.get(batchId) ?? null : null,
      beerCategoryId: batchId ? batchCategoryMap.get(batchId) ?? null : null,
      targetAbv: batchId ? batchTargetAbvMap.get(batchId) ?? null : null,
      styleName: batchId ? batchStyleMap.get(batchId) ?? null : null,
      packageId: lotRow?.package_id ? String(lotRow.package_id) : null,
      packageVolume: lotRow?.package_id ? packageVolumeMap.get(lotRow.package_id) ?? null : null,
      packageUom: lotRow?.package_id ? packageUomMap.get(lotRow.package_id) ?? null : null,
      quantity: qty,
      uomId: row.uom_id ? String(row.uom_id) : null,
      uomCode: row.uom_id ? uomMap.get(row.uom_id) ?? null : null,
    })
  })

  lotOptions.value = Array.from(optionMap.values()).sort((a, b) => (a.lotCode ?? '').localeCompare(b.lotCode ?? ''))
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
  loadMovementIntents().catch((err) => console.error(err))
  loadSites().catch((err) => console.error(err))
  loadAlcoholTypes().catch((err) => console.error(err))
})
</script>
