<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 space-y-6">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('producedBeer.movementWizard.title') }}</h1>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50" @click="goBack">{{ t('producedBeer.movementWizard.back') }}</button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-semibold">{{ t('producedBeer.movementWizard.wizardTitle') }}</h2>
          </div>
          <div class="inline-flex rounded-lg border border-gray-300 bg-white p-0.5">
            <button
              v-for="step in wizardSteps"
              :key="step.key"
              class="px-3 py-1.5 text-sm rounded-md"
              :class="currentStep === step.index ? 'bg-gray-900 text-white' : canEnterStep(step.index) ? 'text-gray-600 hover:bg-gray-50' : 'text-gray-400 cursor-not-allowed'"
              :disabled="!canEnterStep(step.index)"
              type="button"
              @click="goToStep(step.index)"
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
              </header>
              <p v-if="intentLoadError" class="text-xs text-red-600">{{ intentLoadError }}</p>
              <p v-else-if="intentsLoading" class="text-xs text-gray-500">{{ t('producedBeer.movementWizard.intent.loading') }}</p>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <button
                  v-for="option in step1Options"
                  :key="option.key"
                  class="p-4 rounded-lg border text-left"
                  :class="isStep1OptionSelected(option) ? 'border-blue-600 bg-blue-50' : 'border-gray-200 hover:bg-gray-50'"
                  type="button"
                  @click="selectStep1Option(option)"
                >
                  <div class="text-sm font-semibold text-gray-900">{{ option.label }}</div>
                  <div v-if="option.description" class="mt-1 text-xs text-gray-500">{{ option.description }}</div>
                </button>
              </div>
            </section>

            <section v-if="currentStep === 2" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">{{ t('producedBeer.movementWizard.sites.title') }}</h3>
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

            </section>

            <section v-if="currentStep === 3" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">{{ t('producedBeer.movementWizard.lots.title') }}</h3>
                <p v-if="lotSelectionSource === 'lot'" class="text-xs text-amber-600">
                  {{ t('producedBeer.movementWizard.lots.lookupModeHint') }}
                </p>
              </header>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.sourceLotTaxType') }}</label>
                  <select
                    v-model="movementForm.srcLotTaxType"
                    class="w-full h-[40px] border rounded px-3 bg-white disabled:bg-gray-100 disabled:text-gray-400"
                    :disabled="sourceLotTaxTypeOptions.length === 0"
                  >
                    <option value="">{{ t('common.select') }}</option>
                    <option v-for="lotType in sourceLotTaxTypeOptions" :key="lotType" :value="lotType">{{ lotTaxTypeLabel(lotType) }}</option>
                  </select>
                  <p v-if="!movementForm.srcLotTaxType" class="mt-1 text-xs text-gray-500">
                    {{ t('producedBeer.movementWizard.fields.sourceLotTaxTypeHint') }}
                  </p>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.taxDecisionCode') }}</label>
                  <select
                    v-model="movementForm.taxDecisionCode"
                    class="w-full h-[40px] border rounded px-3 bg-white disabled:bg-gray-100 disabled:text-gray-400"
                    :disabled="!taxDecisionSelectable"
                  >
                    <option value="">{{ t('common.select') }}</option>
                    <option v-for="option in taxDecisionOptions" :key="option.value" :value="option.value">
                      {{ option.label }}
                    </option>
                  </select>
                  <p class="mt-1 text-xs text-gray-500">
                    {{ t('producedBeer.movementWizard.fields.defaultTaxDecision') }}: {{ taxDecisionLabel(defaultTaxDecisionCode) }}
                  </p>
                  <p v-if="!taxDecisionSelectable" class="mt-1 text-xs text-gray-500">
                    {{ t('producedBeer.movementWizard.fields.taxDecisionCodeHint') }}
                  </p>
                </div>
              </div>
              <div class="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
                <div v-if="isLotLookupMode" class="relative">
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.lotNo') }}</label>
                  <input
                    v-model.trim="lotLookupQuery"
                    class="w-full h-[40px] border rounded px-3"
                    :placeholder="t('producedBeer.movementWizard.fields.lotNoPlaceholder')"
                    @focus="openLotSuggestions"
                    @input="handleLotLookupInput"
                    @keydown="handleLotLookupKeydown"
                    @blur="handleLotLookupBlur"
                  />
                  <div
                    v-if="showLotSuggestions && lotSuggestions.length"
                    class="absolute z-20 mt-1 w-full rounded-lg border border-gray-200 bg-white shadow-lg overflow-hidden"
                  >
                    <button
                      v-for="(lot, index) in lotSuggestions"
                      :key="`${lot.id}:${index}`"
                      type="button"
                      class="w-full px-3 py-2 text-left text-sm border-b last:border-b-0"
                      :class="index === activeLotSuggestionIndex ? 'bg-blue-50 text-blue-700' : 'hover:bg-gray-50 text-gray-700'"
                      @mousedown.prevent="selectLotSuggestion(lot)"
                    >
                      <div class="font-medium">{{ lot.lotCode || lot.label }}</div>
                      <div class="text-xs text-gray-500">
                        {{ lot.styleName || '—' }} / {{ lot.batchCode || '—' }} / {{ formatNumber(displayLotQuantity(lot)) }} {{ movementInputUomLabel(lot) }}
                      </div>
                      <div class="text-[11px] text-gray-400">{{ lotDisambiguationText(lot) }}</div>
                    </button>
                  </div>
                  <p v-if="lotLookupQuery && !lotSuggestions.length" class="mt-1 text-xs text-amber-600">
                    {{ t('producedBeer.movementWizard.lots.noSuggestion') }}
                  </p>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.product') }}</label>
                  <input v-model.trim="movementForm.product" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div v-if="taxDecisionReasonRequired">
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.movementWizard.fields.reasonNonDefault') }}</label>
                  <input v-model.trim="movementForm.taxDecisionReason" class="w-full h-[40px] border rounded px-3" />
                  <p v-if="!movementForm.taxDecisionReason" class="mt-1 text-xs text-amber-600">{{ t('producedBeer.movementWizard.fields.reasonNonDefaultHint') }}</p>
                </div>
              </div>
              <div
                v-if="isLotLookupMode && selectedLookupLot"
                class="rounded-lg border border-blue-100 bg-blue-50 px-3 py-2 text-sm text-gray-700"
              >
                <span class="font-medium">{{ selectedLookupLot.lotCode || selectedLookupLot.label }}</span>
                <span class="ml-2">{{ selectedLookupLot.styleName || '—' }}</span>
                <span class="ml-2">{{ formatNumber(displayLotQuantity(selectedLookupLot)) }} {{ movementInputUomLabel(selectedLookupLot) }}</span>
                <span class="ml-2">{{ formatNumber(selectedLookupLot.packageVolume) }} {{ selectedLookupLot.packageUom || '' }}</span>
                <div class="mt-1 text-xs text-gray-500">{{ lotDisambiguationText(selectedLookupLot) }}</div>
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
                      <th class="px-3 py-2 text-right">{{ t('producedBeer.movementWizard.table.totalVolume') }}</th>
                      <th class="px-3 py-2 text-right">{{ t('producedBeer.movementWizard.table.quantity') }}</th>
                      <th class="px-3 py-2 text-right">{{ t('producedBeer.movementWizard.table.movementQuantity') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('producedBeer.movementWizard.table.uom') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr
                      v-for="lot in filteredLotOptions"
                      :key="lot.id"
                      :class="['hover:bg-gray-50', isLotEventDivergent(lot) ? 'bg-amber-50' : '']"
                    >
                      <td class="px-3 py-2">
                        <input v-model="movementForm.srcLots" type="checkbox" :value="lot.id" />
                      </td>
                      <td class="px-3 py-2 text-gray-700">
                        <div>{{ lot.lotCode || lot.label }}</div>
                        <div class="text-[11px] text-gray-400">{{ lotDisambiguationText(lot) }}</div>
                      </td>
                      <CompactTableCell
                        :value="alcoholTypeLabel(lot.beerCategoryId)"
                        text-column="beerCategory"
                        truncate
                        focusable
                      />
                      <td class="px-3 py-2 text-right text-gray-700">{{ formatAbv(lot.targetAbv) }}</td>
                      <CompactTableCell
                        :value="lot.styleName"
                        text-column="styleName"
                        truncate
                        focusable
                      />
                      <CompactTableCell
                        :value="lot.batchCode"
                        text-column="batchCode"
                        truncate
                        monospace
                        focusable
                      />
                      <td class="px-3 py-2 text-right text-gray-700">{{ formatNumber(lot.packageVolume) }}</td>
                      <CompactTableCell
                        :value="lot.packageUom"
                        text-column="packageType"
                        truncate
                        focusable
                      />
                      <td class="px-3 py-2 text-right text-gray-700">{{ formatNumber(lot.quantity) }}</td>
                      <td class="px-3 py-2 text-right text-gray-700">{{ formatNumber(displayLotQuantity(lot)) }}</td>
                      <td class="px-3 py-2">
                        <input
                          v-model="movementForm.srcLotMoveQty[lot.id]"
                          type="number"
                          :step="isPackagedMoveInput(lot) ? '1' : '0.001'"
                          min="0"
                          :max="displayLotQuantity(lot) ?? undefined"
                          :data-lot-move-input="lot.id"
                          class="w-28 h-[34px] border rounded px-2 text-right disabled:bg-gray-100 disabled:text-gray-400"
                          :disabled="!movementForm.srcLots.includes(lot.id)"
                        />
                      </td>
                      <td class="px-3 py-2 text-gray-700">{{ movementInputUomLabel(lot) }}</td>
                    </tr>
                    <tr v-if="filteredLotOptions.length === 0">
                      <td class="px-3 py-6 text-center text-gray-500" colspan="12">{{ t('producedBeer.movementWizard.table.noLotsFound') }}</td>
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
              </header>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">移動日時</label>
                  <AppDateTimePicker v-model="movementForm.movedAt" mode="datetime" class="w-full h-[40px] border rounded px-3" />
                </div>
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
              </header>
              <div class="rounded-lg border border-gray-200 p-4 space-y-2 text-sm text-gray-600">
                <div v-if="entryMode === 'OTHER_BREWERY_SHIPMENT'">
                  {{ t('producedBeer.movementWizard.confirmRows.registrationType') }}:
                  <span class="text-gray-900">{{ t('producedBeer.movementWizard.otherBrewery.title') }}</span>
                </div>
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
            <button class="px-3 py-2 rounded border hover:bg-gray-50 disabled:opacity-50" type="button" @click="nextStep" :disabled="isNextDisabled">
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
/* eslint-disable @typescript-eslint/no-explicit-any, @typescript-eslint/no-unused-vars */
import { computed, nextTick, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AppDateTimePicker from '@/components/common/AppDateTimePicker.vue'
import CompactTableCell from '@/components/common/CompactTableCell.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import {
  buildAlcoholTypeLabelMap,
  loadAlcoholTypeReferenceData,
  resolveAlcoholTypeLabel,
} from '@/lib/alcoholTypeRegistry'
import {
  resolveBatchBeerCategoryId,
  resolveBatchStyleName,
  resolveBatchTargetAbv,
} from '@/lib/batchRecipeSnapshot'
import { checkLotChronology, lotChronologyViolationMessage } from '@/lib/lotChronology'
import { formatRpcErrorMessage } from '@/lib/rpcErrors'
import { useRuleengineLabels } from '@/composables/useRuleengineLabels'
import { supabase } from '@/lib/supabase'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

type RuleLabel = { ja?: string; en?: string }

type MovementRules = {
  enums?: Record<string, string[]>
  movement_intent_labels?: Record<string, RuleLabel>
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
const { loadRuleengineLabels, ruleLabel } = useRuleengineLabels()
const pageTitle = computed(() => t('producedBeer.movementWizard.title'))
const OTHER_BREWERY_SHIPMENT_INTENT = 'SHIP_DOMESTIC'
const OTHER_BREWERY_SITE_TYPE = 'OTHER_BREWERY'
type EntryMode = 'RULE_INTENT' | 'OTHER_BREWERY_SHIPMENT'
type Step1Option = {
  key: string
  type: EntryMode
  value: string
  label: string
  description: string
}

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
const entryMode = ref<EntryMode>('RULE_INTENT')
const step1Options = computed<Step1Option[]>(() => [
  ...intentOptions.value.map((option) => ({
    key: `intent:${option.value}`,
    type: 'RULE_INTENT' as const,
    value: option.value,
    label: option.label,
    description: '',
  })),
  {
    key: 'preset:other-brewery-shipment',
    type: 'OTHER_BREWERY_SHIPMENT',
    value: OTHER_BREWERY_SHIPMENT_INTENT,
    label: t('producedBeer.movementWizard.otherBrewery.title'),
    description: '',
  },
])

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
  siteId: string | null
  siteName: string | null
  producedAt: string | null
  batchCode: string | null
  beerCategoryId: string | null
  targetAbv: number | null
  styleName: string | null
  packageId: string | null
  packageVolume: number | null
  packageUom: string | null
  packageVolumeFix: boolean
  packageUnitCount: number | null
  quantity: number | null
  uomId: string | null
  uomCode: string | null
}

type LotReferenceMaps = {
  batchMap: Map<string, string | null>
  batchCategoryMap: Map<string, string | null>
  batchTargetAbvMap: Map<string, number | null>
  batchStyleMap: Map<string, string | null>
  uomMap: Map<string, string>
  packageVolumeMap: Map<string, number | null>
  packageUomMap: Map<string, string | null>
  packageVolumeFixMap: Map<string, boolean>
}

const siteOptions = ref<SiteOption[]>([])
const lotOptions = ref<LotOption[]>([])
const lotSelectionSource = ref<'none' | 'inventory' | 'lot'>('none')
const lotLookupQuery = ref('')
const showLotSuggestions = ref(false)
const activeLotSuggestionIndex = ref(0)
const alcoholTypeLabelMap = ref<Map<string, string>>(new Map())
const saving = ref(false)

const movementForm = reactive({
  movedAt: formatDateTimeLocal(new Date()),
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

function intentLabel(code: string | null | undefined) {
  if (!code) return '—'
  const row = intentOptions.value.find((item) => item.value === code)
  if (row?.label) return row.label
  return ruleLabel('movement_intent', code, rules.value?.movement_intent_labels)
}

function siteTypeLabel(code: string | null | undefined) {
  return ruleLabel('site_type', code, rules.value?.site_type_labels)
}

function siteOptionLabel(site: SiteOption) {
  const base = site.name || site.id
  if (!site.siteTypeKey) return base
  const typeLabel = siteTypeLabel(site.siteTypeKey)
  if (!typeLabel || typeLabel === site.siteTypeKey) return base
  return `${base} (${typeLabel})`
}

function lotTaxTypeLabel(code: string | null | undefined) {
  return ruleLabel('lot_tax_type', code, rules.value?.lot_tax_type_labels)
}

function taxEventLabel(code: string | null | undefined) {
  return ruleLabel('tax_event', code, rules.value?.tax_event_labels)
}

function taxDecisionLabel(code: string | null | undefined) {
  if (!code) return '—'
  const option = taxDecisionOptions.value.find((item) => item.value === code)
  if (option?.label) return option.label
  return ruleLabel('tax_decision_code', code, rules.value?.tax_decision_code_labels)
}

const numberFormatter = computed(() => new Intl.NumberFormat(locale.value, { maximumFractionDigits: 3 }))

function formatNumber(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return numberFormatter.value.format(value)
}

function formatDateTimeLocal(value: Date) {
  const yyyy = value.getFullYear()
  const mm = String(value.getMonth() + 1).padStart(2, '0')
  const dd = String(value.getDate()).padStart(2, '0')
  const hh = String(value.getHours()).padStart(2, '0')
  const mi = String(value.getMinutes()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}T${hh}:${mi}`
}

function toIsoDateTime(value: string) {
  if (!value) return null
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date.toISOString()
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

function packageUnitVolumeForUom(
  packageVolume: number | null,
  packageUom: string | null,
  targetUomCode: string | null | undefined,
) {
  if (packageVolume == null || !Number.isFinite(packageVolume) || packageVolume <= 0) return null
  const fromUom = normalizeVolumeUom(packageUom)
  const toUom = normalizeVolumeUom(targetUomCode)
  if (!fromUom || !toUom || fromUom === toUom) return packageVolume
  const liters = toLiters(packageVolume, fromUom)
  if (liters == null) return null
  return fromLiters(liters, toUom)
}

function packageUnitVolumeInLotUom(lot: LotOption) {
  return packageUnitVolumeForUom(lot.packageVolume, lot.packageUom, lot.uomCode)
}

function asJsonRecord(value: unknown): Record<string, unknown> | null {
  return value && typeof value === 'object' && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : null
}

function resolveSavedPackageCount(lotRow: unknown) {
  const lot = asJsonRecord(lotRow)
  if (!lot) return null
  const meta = asJsonRecord(lot.meta)
  return (
    toNumber(lot.unit)
    ?? toNumber(meta?.unit_count)
    ?? toNumber(meta?.package_qty)
  )
}

function roundPackageCount(value: number | null | undefined) {
  if (value == null || !Number.isFinite(value) || value <= 0) return null
  const rounded = Math.round(value * 1000000) / 1000000
  return Math.abs(rounded - Math.round(rounded)) < 0.0000001 ? Math.round(rounded) : rounded
}

function resolveAvailablePackageCount(
  lotRow: unknown,
  availableQty: number | null,
  availableUomCode: string | null,
  packageInfo: {
    packageVolume: number | null
    packageUom: string | null
    packageVolumeFix: boolean
  },
  uomMap: Map<string, string>,
) {
  const lot = asJsonRecord(lotRow)
  const savedUnit = resolveSavedPackageCount(lotRow)
  if (savedUnit != null && savedUnit > 0) {
    const lotQty = toNumber(lot?.qty)
    const lotUomId = typeof lot?.uom_id === 'string' ? String(lot.uom_id) : null
    const lotUomCode = lotUomId ? (uomMap.get(lotUomId) ?? null) : availableUomCode
    const lotQtyLiters = lotQty != null ? toLiters(lotQty, lotUomCode) : null
    const availableQtyLiters = availableQty != null ? toLiters(availableQty, availableUomCode) : null
    if (
      lotQtyLiters != null
      && lotQtyLiters > 0
      && availableQtyLiters != null
      && availableQtyLiters > 0
      && Math.abs(lotQtyLiters - availableQtyLiters) > 0.000001
    ) {
      return roundPackageCount(savedUnit * (availableQtyLiters / lotQtyLiters))
    }
    return roundPackageCount(savedUnit)
  }

  if (packageInfo.packageVolumeFix !== false) {
    const unitVolume = packageUnitVolumeForUom(
      packageInfo.packageVolume,
      packageInfo.packageUom,
      availableUomCode,
    )
    if (unitVolume != null && unitVolume > 0 && availableQty != null && availableQty > 0) {
      return roundPackageCount(availableQty / unitVolume)
    }
  }

  return null
}

function isPackagedMoveInput(lot: LotOption) {
  if (!lot.packageId) return false
  if (lot.packageVolumeFix === false) return false
  const unitVolume = packageUnitVolumeInLotUom(lot)
  return unitVolume != null && unitVolume > 0
}

function availablePackageCount(lot: LotOption) {
  if (!isPackagedMoveInput(lot)) return null
  if (lot.packageUnitCount != null && lot.packageUnitCount > 0) return lot.packageUnitCount
  if (lot.quantity == null || !Number.isFinite(lot.quantity) || lot.quantity <= 0) return null
  const unitVolume = packageUnitVolumeInLotUom(lot)
  if (unitVolume == null || unitVolume <= 0) return null
  return roundPackageCount(lot.quantity / unitVolume)
}

function displayLotQuantity(lot: LotOption) {
  if (lot.quantity == null || Number.isNaN(lot.quantity)) return null
  if (!isPackagedMoveInput(lot)) return lot.quantity
  return availablePackageCount(lot)
}

function movementInputUomLabel(lot: LotOption) {
  if (isPackagedMoveInput(lot)) return t('producedBeer.movementWizard.table.package')
  return lot.uomCode || '—'
}

function resolvedMovementQuantity(lot: LotOption) {
  const inputQty = toNumber(movementForm.srcLotMoveQty[lot.id])
  if (inputQty == null || inputQty <= 0) return null
  const unitVolume = packageUnitVolumeInLotUom(lot)
  return isPackagedMoveInput(lot) && unitVolume != null && unitVolume > 0
    ? inputQty * unitVolume
    : inputQty
}

function resolveMovedPackageCount(lot: LotOption, qty: number) {
  if (lot.packageUnitCount != null && lot.packageUnitCount > 0 && lot.quantity != null && lot.quantity > 0) {
    return roundPackageCount(lot.packageUnitCount * (qty / lot.quantity))
  }
  if (lot.packageVolumeFix !== false) {
    const unitVolume = packageUnitVolumeInLotUom(lot)
    if (unitVolume != null && unitVolume > 0) return roundPackageCount(qty / unitVolume)
  }
  return null
}

function isSelectedLotRowValid(lot: LotOption) {
  const inputQty = toNumber(movementForm.srcLotMoveQty[lot.id])
  if (isPackagedMoveInput(lot)) {
    if (inputQty == null || inputQty <= 0 || !Number.isInteger(inputQty)) return false
    const maxPackages = availablePackageCount(lot)
    if (maxPackages != null && inputQty > maxPackages + 1e-9) return false
  }
  const qty = resolvedMovementQuantity(lot)
  if (qty == null || qty <= 0) return false
  if (!lot.uomId) return false
  const maxQty = lot.quantity
  if (maxQty != null && Number.isFinite(maxQty) && qty > maxQty + 1e-9) return false
  return true
}

function formatDateValue(value: string | null | undefined) {
  if (!value) return null
  try {
    return new Intl.DateTimeFormat(locale.value).format(new Date(value))
  } catch {
    return value
  }
}

function shortLotId(lotId: string | null | undefined) {
  if (!lotId) return '—'
  return lotId.slice(0, 8)
}

function lotDisambiguationText(lot: LotOption) {
  const parts: string[] = []
  if (lot.siteName) parts.push(lot.siteName)
  const producedAt = formatDateValue(lot.producedAt)
  if (producedAt) parts.push(producedAt)
  parts.push(`ID ${shortLotId(lot.id)}`)
  return parts.join(' / ')
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
  return resolveAlcoholTypeLabel(alcoholTypeLabelMap.value, code) ?? code
}

function resetMovementContext() {
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
  lotSelectionSource.value = 'none'
  lotLookupQuery.value = ''
  showLotSuggestions.value = false
}

function applyOtherBreweryDestinationDefaults() {
  movementForm.dstSiteType = OTHER_BREWERY_SITE_TYPE
  if (movementForm.dstSite) {
    const dstSite = siteOptions.value.find((site) => site.id === movementForm.dstSite)
    if (dstSite?.siteTypeKey !== OTHER_BREWERY_SITE_TYPE) movementForm.dstSite = ''
  }
}

function selectRuleIntent(intent: string) {
  entryMode.value = 'RULE_INTENT'
  if (movementForm.intent === intent) return
  movementForm.intent = intent
}

function isStep1OptionSelected(option: Step1Option) {
  return entryMode.value === option.type && movementForm.intent === option.value
}

function selectStep1Option(option: Step1Option) {
  if (option.type === 'OTHER_BREWERY_SHIPMENT') {
    void selectOtherBreweryShipmentPreset()
    return
  }
  selectRuleIntent(option.value)
}

async function selectOtherBreweryShipmentPreset() {
  entryMode.value = 'OTHER_BREWERY_SHIPMENT'
  if (movementForm.intent !== OTHER_BREWERY_SHIPMENT_INTENT) {
    movementForm.intent = OTHER_BREWERY_SHIPMENT_INTENT
    return
  }
  resetMovementContext()
  await loadRulesForIntent(OTHER_BREWERY_SHIPMENT_INTENT)
  applyOtherBreweryDestinationDefaults()
}

async function saveMovement() {
  if (saving.value) return
  try {
    if (!movementForm.intent) throw new Error('movement_intent is required')
    if (!movementForm.srcSite || !movementForm.dstSite) throw new Error('src/dst site is required')
    if (entryMode.value === 'OTHER_BREWERY_SHIPMENT') {
      const dstSite = siteOptions.value.find((site) => site.id === movementForm.dstSite)
      if (movementForm.dstSiteType !== OTHER_BREWERY_SITE_TYPE || dstSite?.siteTypeKey !== OTHER_BREWERY_SITE_TYPE) {
        throw new Error(t('producedBeer.movementWizard.errors.otherBreweryDestinationRequired'))
      }
    }
    if (!movementForm.srcLotTaxType) throw new Error('src_lot_tax_type is required')
    if (!movementForm.taxDecisionCode) throw new Error('tax_decision_code is required')
    if (!movementForm.srcLots.length) throw new Error('select at least one lot')
    if (taxDecisionReasonRequired.value && !movementForm.taxDecisionReason.trim()) {
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
      if (usePackageInput && inputQty != null && !Number.isInteger(inputQty)) {
        errors.push(`package quantity must be an integer for lot ${lot.lotCode || lot.id}`)
      }
      const maxPackages = usePackageInput ? availablePackageCount(lot) : null
      if (usePackageInput && inputQty != null && maxPackages != null && inputQty > maxPackages + 1e-9) {
        errors.push(`package quantity exceeds available quantity for lot ${lot.lotCode || lot.id}`)
      }
      const unitVolume = packageUnitVolumeInLotUom(lot)
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
        packageQty: usePackageInput ? (inputQty ?? 0) : resolveMovedPackageCount(lot, qty),
      }
    })
    if (errors.length) throw new Error(errors[0])

    const movementAt = toIsoDateTime(movementForm.movedAt)
    if (!movementAt) throw new Error('movement_at is required')
    await assertSelectedLotChronology(rows.map((row) => row.lot), movementAt)

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
        unit: row.packageQty,
        uom_id: row.lot.uomId,
        tax_decision_code: movementForm.taxDecisionCode,
        movement_at: movementAt,
        reason: movementForm.taxDecisionReason.trim() || null,
        notes: movementForm.notes.trim() || null,
        meta: {
          source: 'produced_beer_movement_ui',
          ...(entryMode.value === 'OTHER_BREWERY_SHIPMENT' ? { entry_mode: 'OTHER_BREWERY_SHIPMENT' } : {}),
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
    toast.error(formatRpcErrorMessage(err, {
      fallbackKey: 'producedBeer.movementFast.errors.saveFailed',
    }))
  } finally {
    saving.value = false
  }
}

async function assertSelectedLotChronology(lots: LotOption[], movementAt: string) {
  const result = await checkLotChronology({
    supabase,
    movementAt,
    lots: lots.map((lot) => ({
      lotId: lot.id,
      lotLabel: lot.lotCode || lot.label || lot.id,
    })),
  })
  if (result.unavailableReason) {
    console.warn('Lot chronology early-warning check unavailable', result.unavailableReason)
    return
  }
  const violation = result.violations[0]
  if (violation) {
    throw new Error(lotChronologyViolationMessage(violation, locale.value))
  }
}

const selectedIntentRule = computed(() => {
  if (!movementForm.intent) return null
  return (rules.value?.movement_intent_rules ?? []).find((rule: any) => rule.movement_intent === movementForm.intent) ?? null
})

const allowedSrcSiteTypes = computed(() => selectedIntentRule.value?.allowed_src_site_types ?? [])
const allowedDstSiteTypes = computed(() => selectedIntentRule.value?.allowed_dst_site_types ?? [])

const contextTaxTransformationRules = computed(() =>
  (rules.value?.tax_transformation_rules ?? []).filter((rule: any) => {
    if (movementForm.intent && rule.movement_intent !== movementForm.intent) return false
    if (movementForm.srcSiteType && rule.src_site_type !== movementForm.srcSiteType) return false
    if (movementForm.dstSiteType && rule.dst_site_type !== movementForm.dstSiteType) return false
    return true
  }),
)

const sourceLotTaxTypeOptions = computed(() =>
  Array.from(
    new Set(
      contextTaxTransformationRules.value
        .map((rule: any) => (typeof rule?.lot_tax_type === 'string' ? rule.lot_tax_type : ''))
        .filter((value: string) => !!value),
    ),
  ),
)

const matchingTaxTransformationRules = computed(() =>
  contextTaxTransformationRules.value.filter((rule: any) => {
    if (movementForm.srcLotTaxType && rule.lot_tax_type !== movementForm.srcLotTaxType) return false
    return true
  }),
)

const taxDecisionOptions = computed(() => {
  const defs = new Map<string, { name_ja?: string; name_en?: string }>()
  ;(rules.value?.tax_decision_definitions ?? []).forEach((row: any) => {
    defs.set(row.tax_decision_code, { name_ja: row.name_ja, name_en: row.name_en })
  })
  const candidates = matchingTaxTransformationRules.value
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
      ? (def?.name_ja ?? def?.name_en ?? ruleLabel('tax_decision_code', code, rules.value?.tax_decision_code_labels))
      : (def?.name_en ?? def?.name_ja ?? ruleLabel('tax_decision_code', code, rules.value?.tax_decision_code_labels))
    return { value: code, label }
  })
})

const defaultTaxDecisionCode = computed(() => {
  const defaultCodes = Array.from(
    new Set(
      matchingTaxTransformationRules.value.flatMap((rule: any) =>
        (rule.allowed_tax_decisions ?? [])
          .filter((decision: any) => decision?.default && decision?.tax_decision_code)
          .map((decision: any) => String(decision.tax_decision_code)),
      ),
    ),
  )
  return defaultCodes.length === 1 ? defaultCodes[0] : ''
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
const taxDecisionSelectable = computed(() => !!movementForm.srcLotTaxType && taxDecisionOptions.value.length > 0)
const taxDecisionReasonRequired = computed(() =>
  !!movementForm.taxDecisionCode &&
  !!defaultTaxDecisionCode.value &&
  movementForm.taxDecisionCode !== defaultTaxDecisionCode.value,
)

const srcSiteTypeOptions = computed(() => allowedSrcSiteTypes.value)
const dstSiteTypeOptions = computed(() => {
  if (entryMode.value !== 'OTHER_BREWERY_SHIPMENT') return allowedDstSiteTypes.value
  return allowedDstSiteTypes.value.filter((siteType: string) => siteType === OTHER_BREWERY_SITE_TYPE)
})

const filteredSrcSiteOptions = computed(() => {
  if (!movementForm.srcSiteType) return siteOptions.value
  return siteOptions.value.filter((site) => site.siteTypeKey === movementForm.srcSiteType)
})

const filteredDstSiteOptions = computed(() => {
  if (entryMode.value === 'OTHER_BREWERY_SHIPMENT') {
    return siteOptions.value.filter((site) => site.siteTypeKey === OTHER_BREWERY_SITE_TYPE)
  }
  if (!movementForm.dstSiteType) return siteOptions.value
  return siteOptions.value.filter((site) => site.siteTypeKey === movementForm.dstSiteType)
})

const siteNameMap = computed(() => {
  const map = new Map<string, string>()
  siteOptions.value.forEach((site) => map.set(site.id, site.name || site.id))
  return map
})

const isLotLookupMode = computed(() => lotSelectionSource.value === 'lot')
const tenantWideFilledLotSourceSiteTypes = new Set(['DOMESTIC_CUSTOMER', 'OTHER_BREWERY'])
const bypassLotTaxTypeCandidateFilter = computed(() =>
  tenantWideFilledLotSourceSiteTypes.has(movementForm.srcSiteType),
)

const taxTypeFilteredLotOptions = computed(() => {
  if (!movementForm.srcLotTaxType) return [] as LotOption[]
  return lotOptions.value.filter((lot) => lot.lotTaxType === movementForm.srcLotTaxType)
})

const lotSuggestions = computed(() => {
  if (!isLotLookupMode.value) return [] as LotOption[]
  const keyword = lotLookupQuery.value.trim().toLowerCase()
  if (!keyword) return [] as LotOption[]
  const candidates = bypassLotTaxTypeCandidateFilter.value
    ? lotOptions.value
    : taxTypeFilteredLotOptions.value
  return candidates
    .filter((lot) => {
      const haystack = [
        lot.lotCode,
        lot.label,
        lot.batchCode,
        lot.styleName,
        lot.siteName,
        lot.id,
      ]
        .map((value) => String(value ?? '').toLowerCase())
        .join(' ')
      return haystack.includes(keyword)
    })
    .sort((a, b) => {
      const aCode = String(a.lotCode ?? a.label ?? '').toLowerCase()
      const bCode = String(b.lotCode ?? b.label ?? '').toLowerCase()
      const aStarts = aCode.startsWith(keyword) ? 0 : 1
      const bStarts = bCode.startsWith(keyword) ? 0 : 1
      if (aStarts !== bStarts) return aStarts - bStarts
      return aCode.localeCompare(bCode)
    })
    .slice(0, 8)
})

const filteredLotOptions = computed(() => {
  if (!bypassLotTaxTypeCandidateFilter.value && !movementForm.srcLotTaxType) return [] as LotOption[]
  const productKeyword = movementForm.product.trim().toLowerCase()
  const lotKeyword = lotLookupQuery.value.trim().toLowerCase()
  if (isLotLookupMode.value && !lotKeyword && movementForm.srcLots.length === 0) return [] as LotOption[]
  const candidates = bypassLotTaxTypeCandidateFilter.value
    ? lotOptions.value
    : taxTypeFilteredLotOptions.value
  return candidates.filter((lot) => {
    const matchesProduct = !productKeyword || [
      lot.lotCode,
      lot.label,
      lot.batchCode,
      lot.styleName,
      lot.siteName,
      lot.id,
      alcoholTypeLabel(lot.beerCategoryId),
    ].some((value) => String(value ?? '').toLowerCase().includes(productKeyword))
    const matchesLot = !lotKeyword || [
      lot.lotCode,
      lot.label,
      lot.siteName,
      lot.id,
    ].some((value) => String(value ?? '').toLowerCase().includes(lotKeyword))
    return matchesProduct && matchesLot
  })
})

const selectedLookupLot = computed(() => {
  if (!isLotLookupMode.value || movementForm.srcLots.length !== 1) return null
  return lotOptions.value.find((lot) => lot.id === movementForm.srcLots[0]) ?? null
})

const hasStep1Input = computed(() => !!movementForm.intent)

const selectedLots = computed(() => lotOptions.value.filter((lot) => movementForm.srcLots.includes(lot.id)))

const isStep2Complete = computed(() => {
  if (!movementForm.srcSiteType || !movementForm.srcSite || !movementForm.dstSiteType || !movementForm.dstSite) {
    return false
  }

  if (entryMode.value === 'OTHER_BREWERY_SHIPMENT') {
    const dstSite = siteOptions.value.find((site) => site.id === movementForm.dstSite)
    return movementForm.dstSiteType === OTHER_BREWERY_SITE_TYPE && dstSite?.siteTypeKey === OTHER_BREWERY_SITE_TYPE
  }

  return true
})

const isStep3Complete = computed(() => {
  if (!movementForm.srcLotTaxType || !movementForm.taxDecisionCode) return false
  if (taxDecisionReasonRequired.value && !movementForm.taxDecisionReason.trim()) return false
  if (!selectedLots.value.length) return false
  return selectedLots.value.every((lot) => isSelectedLotRowValid(lot))
})

const isNextDisabled = computed(() =>
  currentStep.value === wizardSteps.value.length || !canEnterStep(currentStep.value + 1),
)

function focusMovementQtyInput(lotId: string) {
  nextTick(() => {
    const input = document.querySelector<HTMLInputElement>(`[data-lot-move-input="${lotId}"]`)
    input?.focus()
    input?.select()
  })
}

function openLotSuggestions() {
  if (!isLotLookupMode.value || !lotLookupQuery.value.trim()) return
  showLotSuggestions.value = lotSuggestions.value.length > 0
  activeLotSuggestionIndex.value = 0
}

function handleLotLookupInput() {
  if (!isLotLookupMode.value) return
  activeLotSuggestionIndex.value = 0
  showLotSuggestions.value = lotSuggestions.value.length > 0
}

function handleLotLookupBlur() {
  window.setTimeout(() => {
    showLotSuggestions.value = false
  }, 120)
}

function selectLotSuggestion(lot: LotOption) {
  const existingQty = movementForm.srcLotMoveQty[lot.id] ?? ''
  lotLookupQuery.value = lot.lotCode ?? lot.label ?? ''
  movementForm.srcLots = [lot.id]
  movementForm.srcLotMoveQty = { [lot.id]: existingQty }
  showLotSuggestions.value = false
  activeLotSuggestionIndex.value = 0
  focusMovementQtyInput(lot.id)
}

function handleLotLookupKeydown(event: KeyboardEvent) {
  if (!isLotLookupMode.value) return
  if (event.key === 'ArrowDown') {
    if (!lotSuggestions.value.length) return
    event.preventDefault()
    showLotSuggestions.value = true
    activeLotSuggestionIndex.value = Math.min(activeLotSuggestionIndex.value + 1, lotSuggestions.value.length - 1)
    return
  }
  if (event.key === 'ArrowUp') {
    if (!lotSuggestions.value.length) return
    event.preventDefault()
    showLotSuggestions.value = true
    activeLotSuggestionIndex.value = Math.max(activeLotSuggestionIndex.value - 1, 0)
    return
  }
  if (event.key === 'Enter') {
    if (!showLotSuggestions.value || !lotSuggestions.value.length) return
    event.preventDefault()
    selectLotSuggestion(lotSuggestions.value[activeLotSuggestionIndex.value] ?? lotSuggestions.value[0])
    return
  }
  if (event.key === 'Escape') {
    showLotSuggestions.value = false
  }
}


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
    resetMovementContext()

    if (!value) {
      rules.value = null
      return
    }

    await loadRulesForIntent(value)
    if (entryMode.value === 'OTHER_BREWERY_SHIPMENT') applyOtherBreweryDestinationDefaults()
  }
)

watch(
  sourceLotTaxTypeOptions,
  (options) => {
    if (!options.length) {
      movementForm.srcLotTaxType = ''
      return
    }
    if (!options.includes(movementForm.srcLotTaxType)) {
      movementForm.srcLotTaxType = options.length === 1 ? options[0] : ''
    }
  },
  { immediate: true },
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
  () => movementForm.srcLotTaxType,
  (value) => {
    const selected = new Set(
      movementForm.srcLots.filter((lotId) => {
        const lot = lotOptions.value.find((row) => row.id === lotId)
        return !!lot && lot.lotTaxType === value
      }),
    )
    movementForm.srcLots = movementForm.srcLots.filter((lotId) => selected.has(lotId))
    Object.keys(movementForm.srcLotMoveQty).forEach((lotId) => {
      if (!selected.has(lotId)) delete movementForm.srcLotMoveQty[lotId]
    })
  },
)

watch(
  () => [movementForm.srcSite, movementForm.srcSiteType] as const,
  async ([siteId]) => {
    if (!siteId) {
      lotOptions.value = []
      lotSelectionSource.value = 'none'
      lotLookupQuery.value = ''
      showLotSuggestions.value = false
      movementForm.srcLots = []
      movementForm.srcLotMoveQty = {}
      movementForm.srcLotTaxType = ''
      return
    }
    lotLookupQuery.value = ''
    showLotSuggestions.value = false
    movementForm.srcLots = []
    movementForm.srcLotMoveQty = {}
    movementForm.srcLotTaxType = ''
    await loadLotsForSite(siteId)
  }
)

watch(
  () => entryMode.value,
  (value) => {
    if (value === 'OTHER_BREWERY_SHIPMENT') applyOtherBreweryDestinationDefaults()
  },
)

watch(
  () => movementForm.dstSiteType,
  () => {
    if (entryMode.value !== 'OTHER_BREWERY_SHIPMENT') return
    applyOtherBreweryDestinationDefaults()
  },
)

watch(
  () => movementForm.srcLots,
  () => {
    const selected = new Set(movementForm.srcLots)
    Object.keys(movementForm.srcLotMoveQty).forEach((lotId) => {
      if (!selected.has(lotId)) delete movementForm.srcLotMoveQty[lotId]
    })
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
    const nextIntentOptions = (data ?? [])
      .map((row: any) => ({
        value: String(row?.movement_intent ?? ''),
        label: String(
          String(locale.value || '').toLowerCase().startsWith('ja')
            ? (row?.name_ja ?? row?.name_en ?? row?.movement_intent ?? '')
            : (row?.name_en ?? row?.name_ja ?? row?.movement_intent ?? '')
        ),
      }))
      .filter((row: { value: string }) => !!row.value)
    intentOptions.value = nextIntentOptions

    if (
      movementForm.intent &&
      entryMode.value === 'RULE_INTENT' &&
      !nextIntentOptions.some((option: { value: string }) => option.value === movementForm.intent)
    ) {
      movementForm.intent = ''
    }
  } catch (err: any) {
    console.error(err)
    intentOptions.value = []
    intentLoadError.value = formatRpcErrorMessage(err, {
      fallbackKey: 'producedBeer.movementWizard.errors.loadIntents',
    })
    toast.error(intentLoadError.value)
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
    rulesLoadError.value = formatRpcErrorMessage(err, {
      fallbackKey: 'producedBeer.movementWizard.errors.loadRules',
    })
    toast.error(rulesLoadError.value)
  } finally {
    rulesLoading.value = false
  }
}

const siteTypeAliasToRuleKey: Record<string, string> = {
  brewery: 'BREWERY_MANUFACTUR',
  brewery_manufactur: 'BREWERY_MANUFACTUR',
  bonded_area: 'TAX_STORAGE',
}

function toRuleSiteTypeKey(defKey: string | null | undefined) {
  if (!defKey) return null
  const normalized = defKey.trim()
  if (!normalized) return null
  const lower = normalized.toLowerCase()
  const alias = siteTypeAliasToRuleKey[lower]
  if (alias) return alias
  return normalized.toUpperCase().replace(/-/g, '_')
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
    const ruleKey = toRuleSiteTypeKey(defKey)
    return {
      id: row.id,
      name: row.name ?? row.id,
      siteTypeKey: ruleKey,
    }
  })
}

async function loadAlcoholTypes() {
  const { optionRows, fallbackRows } = await loadAlcoholTypeReferenceData(supabase)
  alcoholTypeLabelMap.value = buildAlcoholTypeLabelMap(
    optionRows as Array<Record<string, unknown>>,
    fallbackRows as Array<Record<string, unknown>>,
  )
}

async function loadLotReferenceMaps(
  tenant: string,
  batchIds: string[],
  uomIds: string[],
  packageIds: string[],
): Promise<LotReferenceMaps> {
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
        .in('code', ['beer_category', 'actual_abv', 'target_abv', 'style_name'])
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
          if (code === 'actual_abv') {
            const num = toNumber(row.value_num)
            if (num != null) entry.targetAbv = num
          }
          if (code === 'target_abv' && entry.targetAbv == null) {
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
      .select('id, batch_code, meta, mes_recipe_id, released_reference_json, recipe_json')
      .eq('tenant_id', tenant)
      .in('id', batchIds)
    if (batchError) throw batchError
    ;(batchRows ?? []).forEach((row: any) => {
      const attr = attrValueByBatch.get(row.id)

      batchMap.set(row.id, row.batch_code ?? null)
      batchCategoryMap.set(row.id, resolveBatchBeerCategoryId(row, attr))
      batchTargetAbvMap.set(row.id, resolveBatchTargetAbv(row, attr))
      batchStyleMap.set(row.id, resolveBatchStyleName(row, attr))
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
  const packageVolumeFixMap = new Map<string, boolean>()
  if (packageIds.length) {
    const { data: pkgRows, error: pkgError } = await supabase
      .from('mst_package')
      .select('id, unit_volume, volume_uom, volume_fix_flg')
      .in('id', packageIds)
    if (pkgError) throw pkgError

    const packageVolumeUomIds = Array.from(new Set((pkgRows ?? [])
      .map((row: any) => (typeof row.volume_uom === 'string' ? row.volume_uom : ''))
      .filter((value: string) => !!value && !uomMap.has(value))))
    if (packageVolumeUomIds.length) {
      const { data: packageUomRows, error: packageUomError } = await supabase
        .from('mst_uom')
        .select('id, code')
        .in('id', packageVolumeUomIds)
      if (packageUomError) throw packageUomError
      ;(packageUomRows ?? []).forEach((row: any) => uomMap.set(row.id, row.code))
    }

    ;(pkgRows ?? []).forEach((row: any) => {
      packageVolumeMap.set(row.id, toNumber(row.unit_volume))
      packageVolumeFixMap.set(row.id, row.volume_fix_flg !== false)
      if (typeof row.volume_uom === 'string') {
        packageUomMap.set(row.id, uomMap.get(row.volume_uom) ?? row.volume_uom)
      } else {
        packageUomMap.set(row.id, null)
      }
    })
  }

  return {
    batchMap,
    batchCategoryMap,
    batchTargetAbvMap,
    batchStyleMap,
    uomMap,
    packageVolumeMap,
    packageUomMap,
    packageVolumeFixMap,
  }
}

function buildLotOptionsFromInventoryRows(rows: any[], refs: LotReferenceMaps) {
  const optionMap = new Map<string, LotOption>()
  rows.forEach((row: any) => {
    const lotRow = Array.isArray(row.lot) ? row.lot[0] : row.lot
    const lotId = lotRow?.id ?? row.lot_id ?? row.id
    if (!lotId) return
    const batchId = lotRow?.batch_id ?? null
    const qtyValue = Number(row.qty)
    const qty = Number.isFinite(qtyValue) ? qtyValue : 0
    const uomId = row.uom_id ? String(row.uom_id) : null
    const uomCode = uomId ? refs.uomMap.get(uomId) ?? null : null
    const packageId = lotRow?.package_id ? String(lotRow.package_id) : null
    const packageInfo = {
      packageVolume: packageId ? refs.packageVolumeMap.get(packageId) ?? null : null,
      packageUom: packageId ? refs.packageUomMap.get(packageId) ?? null : null,
      packageVolumeFix: packageId ? refs.packageVolumeFixMap.get(packageId) ?? true : true,
    }
    const packageUnitCount = resolveAvailablePackageCount(
      lotRow,
      qty,
      uomCode,
      packageInfo,
      refs.uomMap,
    )
    const existing = optionMap.get(lotId)
    if (existing) {
      existing.quantity = (existing.quantity ?? 0) + qty
      if (packageUnitCount != null) {
        existing.packageUnitCount = (existing.packageUnitCount ?? 0) + packageUnitCount
      }
      return
    }
    optionMap.set(lotId, {
      id: lotId,
      label: lotRow?.lot_no ?? lotId,
      lotTaxType: typeof lotRow?.lot_tax_type === 'string' ? lotRow.lot_tax_type : null,
      lotCode: lotRow?.lot_no ?? null,
      siteId: row.site_id ? String(row.site_id) : null,
      siteName: row.site_id ? siteNameMap.value.get(String(row.site_id)) ?? String(row.site_id) : null,
      producedAt: typeof lotRow?.produced_at === 'string' ? lotRow.produced_at : null,
      batchCode: batchId ? refs.batchMap.get(batchId) ?? null : null,
      beerCategoryId: batchId ? refs.batchCategoryMap.get(batchId) ?? null : null,
      targetAbv: batchId ? refs.batchTargetAbvMap.get(batchId) ?? null : null,
      styleName: batchId ? refs.batchStyleMap.get(batchId) ?? null : null,
      packageId,
      packageVolume: packageInfo.packageVolume,
      packageUom: packageInfo.packageUom,
      packageVolumeFix: packageInfo.packageVolumeFix,
      packageUnitCount,
      quantity: qty,
      uomId,
      uomCode,
    })
  })

  return Array.from(optionMap.values()).sort((a, b) =>
    `${a.lotCode ?? ''} ${a.siteName ?? ''} ${a.id}`.localeCompare(`${b.lotCode ?? ''} ${b.siteName ?? ''} ${b.id}`),
  )
}

function buildLotOptionsFromLotRows(rows: any[], refs: LotReferenceMaps) {
  return rows
    .map((row: any) => {
      const batchId = typeof row.batch_id === 'string' ? row.batch_id : null
      const lotId = String(row.id ?? '')
      if (!lotId) return null
      const uomId = row.uom_id ? String(row.uom_id) : null
      const uomCode = uomId ? refs.uomMap.get(uomId) ?? null : null
      const packageId = row.package_id ? String(row.package_id) : null
      const packageInfo = {
        packageVolume: packageId ? refs.packageVolumeMap.get(packageId) ?? null : null,
        packageUom: packageId ? refs.packageUomMap.get(packageId) ?? null : null,
        packageVolumeFix: packageId ? refs.packageVolumeFixMap.get(packageId) ?? true : true,
      }
      const qty = toNumber(row.qty)
      return {
        id: lotId,
        label: row.lot_no ?? lotId,
        lotTaxType: typeof row.lot_tax_type === 'string' ? row.lot_tax_type : null,
        lotCode: row.lot_no ?? null,
        siteId: row.site_id ? String(row.site_id) : null,
        siteName: row.site_id ? siteNameMap.value.get(String(row.site_id)) ?? String(row.site_id) : null,
        producedAt: typeof row.produced_at === 'string' ? row.produced_at : null,
        batchCode: batchId ? refs.batchMap.get(batchId) ?? null : null,
        beerCategoryId: batchId ? refs.batchCategoryMap.get(batchId) ?? null : null,
        targetAbv: batchId ? refs.batchTargetAbvMap.get(batchId) ?? null : null,
        styleName: batchId ? refs.batchStyleMap.get(batchId) ?? null : null,
        packageId,
        packageVolume: packageInfo.packageVolume,
        packageUom: packageInfo.packageUom,
        packageVolumeFix: packageInfo.packageVolumeFix,
        packageUnitCount: resolveAvailablePackageCount(row, qty, uomCode, packageInfo, refs.uomMap),
        quantity: qty,
        uomId,
        uomCode,
      } satisfies LotOption
    })
    .filter((row): row is LotOption => row != null)
    .sort((a, b) =>
      `${a.lotCode ?? ''} ${a.siteName ?? ''} ${a.id}`.localeCompare(`${b.lotCode ?? ''} ${b.siteName ?? ''} ${b.id}`),
    )
}

async function loadLotsForSite(siteId: string) {
  const tenant = await ensureTenant()
  const useTenantWideFilledLotLookup = tenantWideFilledLotSourceSiteTypes.has(movementForm.srcSiteType)

  if (!useTenantWideFilledLotLookup) {
    const { data: inventoryRows, error } = await supabase
      .from('inv_inventory')
      .select('id, site_id, lot_id, qty, uom_id, lot:lot_id ( id, lot_no, batch_id, package_id, lot_tax_type, status, produced_at, qty, unit, uom_id, meta )')
      .eq('tenant_id', tenant)
      .eq('site_id', siteId)
      .gt('qty', 0)
    if (error) throw error

    const activeRows = (inventoryRows ?? []).filter((row: any) => {
      const lotRow = Array.isArray(row.lot) ? row.lot[0] : row.lot
      return !lotRow || lotRow.status !== 'void'
    })

    if (activeRows.length) {
      const batchIds = Array.from(new Set(activeRows
        .map((row: any) => (Array.isArray(row.lot) ? row.lot[0] : row.lot)?.batch_id)
        .filter(Boolean)))
      const uomIds = Array.from(new Set(activeRows
        .flatMap((row: any) => {
          const lotRow = Array.isArray(row.lot) ? row.lot[0] : row.lot
          return [row.uom_id, lotRow?.uom_id]
        })
        .filter(Boolean)))
      const packageIds = Array.from(new Set(activeRows
        .map((row: any) => (Array.isArray(row.lot) ? row.lot[0] : row.lot)?.package_id)
        .filter(Boolean)))
      const refs = await loadLotReferenceMaps(tenant, batchIds, uomIds, packageIds)
      lotOptions.value = buildLotOptionsFromInventoryRows(activeRows, refs)
      lotSelectionSource.value = 'inventory'
      return
    }
  }

  lotSelectionSource.value = 'lot'

  let activeLots: any[] = []
  if (useTenantWideFilledLotLookup) {
    const { data: tenantFilledLotRows, error: tenantFilledLotError } = await supabase
      .from('lot')
      .select('id, lot_no, site_id, produced_at, batch_id, package_id, lot_tax_type, status, qty, unit, uom_id, meta')
      .eq('tenant_id', tenant)
      .not('package_id', 'is', null)
      .neq('status', 'void')
      .gt('qty', 0)
      .order('lot_no')
      .limit(500)
    if (tenantFilledLotError) throw tenantFilledLotError
    activeLots = (tenantFilledLotRows ?? []).filter((row: any) => row?.status !== 'void')
  } else {
    const { data: scopedLotRows, error: scopedLotError } = await supabase
      .from('lot')
      .select('id, lot_no, site_id, produced_at, batch_id, package_id, lot_tax_type, status, qty, unit, uom_id, meta')
      .eq('tenant_id', tenant)
      .or(`site_id.eq.${siteId},site_id.is.null`)
      .neq('status', 'void')
      .gt('qty', 0)
      .order('lot_no')
      .limit(500)
    if (scopedLotError) throw scopedLotError

    activeLots = (scopedLotRows ?? []).filter((row: any) => row?.status !== 'void')
    if (!activeLots.length) {
      const { data: tenantLotRows, error: tenantLotError } = await supabase
        .from('lot')
        .select('id, lot_no, site_id, produced_at, batch_id, package_id, lot_tax_type, status, qty, unit, uom_id, meta')
        .eq('tenant_id', tenant)
        .neq('status', 'void')
        .gt('qty', 0)
        .order('lot_no')
        .limit(500)
      if (tenantLotError) throw tenantLotError
      activeLots = (tenantLotRows ?? []).filter((row: any) => row?.status !== 'void')
    }
  }

  if (!activeLots.length) {
    lotOptions.value = []
    return
  }

  const batchIds = Array.from(new Set(activeLots.map((row: any) => row.batch_id).filter(Boolean)))
  const uomIds = Array.from(new Set(activeLots.map((row: any) => row.uom_id).filter(Boolean)))
  const packageIds = Array.from(new Set(activeLots.map((row: any) => row.package_id).filter(Boolean)))
  const refs = await loadLotReferenceMaps(tenant, batchIds, uomIds, packageIds)
  lotOptions.value = buildLotOptionsFromLotRows(activeLots, refs)
  lotSelectionSource.value = 'lot'
}

function nextStep() {
  if (isNextDisabled.value) return
  goToStep(currentStep.value + 1)
}

function canEnterStep(stepIndex: number) {
  if (stepIndex <= currentStep.value) return true
  if (stepIndex === 2) return hasStep1Input.value
  if (stepIndex >= 3 && (!hasStep1Input.value || !isStep2Complete.value)) return false
  if (stepIndex >= 4 && !isStep3Complete.value) return false
  return stepIndex <= wizardSteps.value.length
}

function goToStep(stepIndex: number) {
  if (!canEnterStep(stepIndex)) return
  currentStep.value = stepIndex
}

function prevStep() {
  if (currentStep.value > 1) currentStep.value -= 1
}

function goBack() {
  router.back()
}

onMounted(() => {
  ensureTenant()
    .then((tenant) => loadRuleengineLabels({ tenantId: tenant }))
    .catch((err) => {
      console.error(err)
      toast.error(formatRpcErrorMessage(err))
    })
  loadMovementIntents().catch((err) => {
    console.error(err)
    toast.error(formatRpcErrorMessage(err))
  })
  loadSites().catch((err) => console.error(err))
  loadAlcoholTypes().catch((err) => console.error(err))
})
</script>
