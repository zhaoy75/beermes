<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto space-y-6">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('producedBeer.taxEvent.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('producedBeer.taxEvent.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50" @click="goBack">
            {{ t('producedBeer.taxEvent.back') }}
          </button>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-semibold">{{ t('producedBeer.taxEvent.wizardTitle') }}</h2>
            <p class="text-sm text-gray-500">{{ t('producedBeer.taxEvent.wizardSubtitle') }}</p>
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
                <h3 class="text-base font-semibold">{{ t('producedBeer.taxEvent.steps.intent.title') }}</h3>
                <p class="text-sm text-gray-500">{{ t('producedBeer.taxEvent.steps.intent.subtitle') }}</p>
              </header>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <button
                  v-for="option in intentOptions"
                  :key="option.value"
                  class="p-4 rounded-lg border text-left"
                  :class="taxEvent.intent === option.value ? 'border-blue-600 bg-blue-50' : 'border-gray-200 hover:bg-gray-50'"
                  type="button"
                  @click="selectIntent(option.value)"
                >
                  <div class="text-sm font-semibold text-gray-900">{{ option.label }}</div>
                  <div class="text-xs text-gray-500">{{ option.note }}</div>
                </button>
              </div>
              <div v-if="taxEvent.intent === 'return'" class="rounded-lg border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800">
                {{ t('producedBeer.taxEvent.steps.intent.returnHint') }}
              </div>
            </section>

            <section v-if="currentStep === 2" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">{{ t('producedBeer.taxEvent.steps.parties.title') }}</h3>
                <p class="text-sm text-gray-500">{{ t('producedBeer.taxEvent.steps.parties.subtitle') }}</p>
              </header>

              <div v-if="taxEvent.intent === 'domestic'" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.shipFrom') }}</label>
                  <input v-model.trim="taxEvent.shipFromSite" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.shipToParty') }}</label>
                  <input v-model.trim="taxEvent.shipToParty" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.shipDate') }}</label>
                  <input v-model="taxEvent.shipDate" type="date" class="w-full h-[40px] border rounded px-3" />
                </div>
              </div>

              <div v-else-if="taxEvent.intent === 'export'" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.shipFrom') }}</label>
                  <input v-model.trim="taxEvent.shipFromSite" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.exportMode') }}</label>
                  <select v-model="taxEvent.exportMode" class="w-full h-[40px] border rounded px-3 bg-white">
                    <option value="">{{ t('common.select') }}</option>
                    <option value="direct">{{ t('producedBeer.taxEvent.exportModes.direct') }}</option>
                    <option value="forwarder">{{ t('producedBeer.taxEvent.exportModes.forwarder') }}</option>
                  </select>
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.destinationCountry') }}</label>
                  <input v-model.trim="taxEvent.destinationCountry" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.plannedShipDate') }}</label>
                  <input v-model="taxEvent.plannedShipDate" type="date" class="w-full h-[40px] border rounded px-3" />
                </div>
              </div>

              <div v-else-if="taxEvent.intent === 'inbound'" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.receivingSite') }}</label>
                  <input v-model.trim="taxEvent.receivingSite" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.sourceType') }}</label>
                  <input v-model.trim="taxEvent.sourceType" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.sourceParty') }}</label>
                  <input v-model.trim="taxEvent.sourceParty" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.receiptDate') }}</label>
                  <input v-model="taxEvent.receiptDate" type="date" class="w-full h-[40px] border rounded px-3" />
                </div>
              </div>

              <div v-else-if="taxEvent.intent === 'nontax_other'" class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.removalSite') }}</label>
                  <input v-model.trim="taxEvent.removalSite" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.reasonCode') }}</label>
                  <input v-model.trim="taxEvent.reasonCode" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.fields.plannedDate') }}</label>
                  <input v-model="taxEvent.plannedDate" type="date" class="w-full h-[40px] border rounded px-3" />
                </div>
              </div>

              <div v-else class="text-sm text-gray-500">{{ t('producedBeer.taxEvent.steps.parties.intentFirst') }}</div>
            </section>

            <section v-if="currentStep === 3" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">{{ t('producedBeer.taxEvent.steps.items.title') }}</h3>
                <p class="text-sm text-gray-500">{{ t('producedBeer.taxEvent.steps.items.subtitle') }}</p>
              </header>
              <div class="overflow-x-auto border border-gray-200 rounded-lg">
                <table class="min-w-full text-sm">
                  <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                    <tr>
                      <th class="px-3 py-2 text-left">{{ t('producedBeer.taxEvent.items.product') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('producedBeer.taxEvent.items.batch') }}</th>
                      <th class="px-3 py-2 text-right">{{ t('producedBeer.taxEvent.items.qty') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('producedBeer.taxEvent.items.uom') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('producedBeer.taxEvent.items.abv') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('producedBeer.taxEvent.items.taxCategory') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="(line, index) in taxEvent.items" :key="line.id">
                      <td class="px-3 py-2"><input v-model.trim="line.product" class="w-full h-[32px] border rounded px-2" /></td>
                      <td class="px-3 py-2"><input v-model.trim="line.batch" class="w-full h-[32px] border rounded px-2" /></td>
                      <td class="px-3 py-2"><input v-model="line.qty" type="number" min="0" step="0.001" class="w-full h-[32px] border rounded px-2 text-right" /></td>
                      <td class="px-3 py-2"><input v-model.trim="line.uom" class="w-full h-[32px] border rounded px-2" /></td>
                      <td class="px-3 py-2"><input v-model.trim="line.abv" class="w-full h-[32px] border rounded px-2" /></td>
                      <td class="px-3 py-2"><input v-model.trim="line.taxCategory" class="w-full h-[32px] border rounded px-2" /></td>
                      <td class="px-3 py-2">
                        <button class="px-2 py-1 text-xs rounded border hover:bg-gray-50" @click="removeItem(index)">{{ t('common.delete') }}</button>
                      </td>
                    </tr>
                    <tr v-if="taxEvent.items.length === 0">
                      <td colspan="7" class="px-3 py-6 text-center text-gray-500">{{ t('common.noData') }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="addItem">
                {{ t('producedBeer.taxEvent.items.addLine') }}
              </button>
            </section>

            <section v-if="currentStep === 4" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">{{ t('producedBeer.taxEvent.steps.evidence.title') }}</h3>
                <p class="text-sm text-gray-500">{{ t('producedBeer.taxEvent.steps.evidence.subtitle') }}</p>
              </header>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.evidence.invoiceNo') }}</label>
                  <input v-model.trim="taxEvent.invoiceNo" class="w-full h-[40px] border rounded px-3" />
                </div>
                <div>
                  <label class="block text-sm text-gray-600 mb-1">{{ t('producedBeer.taxEvent.evidence.blNo') }}</label>
                  <input v-model.trim="taxEvent.blNo" class="w-full h-[40px] border rounded px-3" />
                </div>
              </div>
              <div class="rounded-lg border border-dashed border-gray-300 p-4 text-sm text-gray-500">
                {{ t('producedBeer.taxEvent.evidence.attachmentsHint') }}
              </div>
            </section>

            <section v-if="currentStep === 5" class="space-y-4">
              <header>
                <h3 class="text-base font-semibold">{{ t('producedBeer.taxEvent.steps.review.title') }}</h3>
                <p class="text-sm text-gray-500">{{ t('producedBeer.taxEvent.steps.review.subtitle') }}</p>
              </header>
              <div class="rounded-lg border border-gray-200 p-4 space-y-2 text-sm text-gray-600">
                <div>{{ t('producedBeer.taxEvent.review.intent') }}: <span class="text-gray-900">{{ intentLabel }}</span></div>
                <div>{{ t('producedBeer.taxEvent.review.taxTreatment') }}: <span class="text-gray-900">{{ taxTreatmentLabel }}</span></div>
                <div>{{ t('producedBeer.taxEvent.review.items') }}: <span class="text-gray-900">{{ taxEvent.items.length }}</span></div>
                <div>{{ t('producedBeer.taxEvent.review.evidence') }}: <span class="text-gray-900">{{ evidenceStatus }}</span></div>
              </div>
              <div class="rounded-lg border border-gray-200 p-4 space-y-2 text-sm text-gray-600">
                <h4 class="text-sm font-semibold text-gray-800">{{ t('producedBeer.taxEvent.review.warningsTitle') }}</h4>
                <ul class="list-disc pl-5">
                  <li>{{ t('producedBeer.taxEvent.review.warningIntentLocked') }}</li>
                  <li>{{ t('producedBeer.taxEvent.review.warningPostValidation') }}</li>
                </ul>
              </div>
            </section>
          </div>

          <aside class="space-y-4">
            <div class="border border-gray-200 rounded-lg p-4 space-y-3">
              <h3 class="text-sm font-semibold text-gray-700">{{ t('producedBeer.taxEvent.panel.title') }}</h3>
              <div class="text-sm text-gray-600">
                <div class="text-xs uppercase text-gray-500">{{ t('producedBeer.taxEvent.panel.taxTreatment') }}</div>
                <div class="text-base font-semibold text-gray-900">{{ taxTreatmentLabel }}</div>
              </div>
              <div class="text-sm text-gray-600">
                <div class="text-xs uppercase text-gray-500">{{ t('producedBeer.taxEvent.panel.status') }}</div>
                <div class="text-base font-semibold text-gray-900">{{ taxEvent.status }}</div>
              </div>
            </div>

            <div class="border border-gray-200 rounded-lg p-4 space-y-2">
              <h3 class="text-sm font-semibold text-gray-700">{{ t('producedBeer.taxEvent.panel.checklistTitle') }}</h3>
              <ul class="text-sm text-gray-600 space-y-1">
                <li>• {{ t('producedBeer.taxEvent.panel.checkIntent') }}</li>
                <li>• {{ t('producedBeer.taxEvent.panel.checkParties') }}</li>
                <li>• {{ t('producedBeer.taxEvent.panel.checkItems') }}</li>
                <li>• {{ t('producedBeer.taxEvent.panel.checkEvidence') }}</li>
              </ul>
            </div>

            <div class="border border-gray-200 rounded-lg p-4 space-y-2 text-sm text-gray-600">
              <h3 class="text-sm font-semibold text-gray-700">{{ t('producedBeer.taxEvent.panel.taxPreview') }}</h3>
              <p>{{ t('producedBeer.taxEvent.panel.taxPreviewHint') }}</p>
            </div>
          </aside>
        </div>

        <footer class="flex flex-wrap items-center justify-between gap-3">
          <div class="flex items-center gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="prevStep" :disabled="currentStep === 1">
              {{ t('producedBeer.taxEvent.actions.prev') }}
            </button>
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="nextStep" :disabled="currentStep === wizardSteps.length">
              {{ t('producedBeer.taxEvent.actions.next') }}
            </button>
          </div>
          <div class="flex items-center gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button">
              {{ t('producedBeer.taxEvent.actions.saveDraft') }}
            </button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" type="button">
              {{ t('producedBeer.taxEvent.actions.post') }}
            </button>
          </div>
        </footer>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'

const { t } = useI18n()
const router = useRouter()
const pageTitle = computed(() => t('producedBeer.taxEvent.breadcrumb'))

const currentStep = ref(1)

const wizardSteps = computed(() => ([
  { key: 'intent', label: t('producedBeer.taxEvent.steps.intent.label'), index: 1 },
  { key: 'parties', label: t('producedBeer.taxEvent.steps.parties.label'), index: 2 },
  { key: 'items', label: t('producedBeer.taxEvent.steps.items.label'), index: 3 },
  { key: 'evidence', label: t('producedBeer.taxEvent.steps.evidence.label'), index: 4 },
  { key: 'review', label: t('producedBeer.taxEvent.steps.review.label'), index: 5 },
]))

const intentOptions = computed(() => ([
  {
    value: 'domestic',
    label: t('producedBeer.taxEvent.intents.domestic'),
    note: t('producedBeer.taxEvent.intents.domesticNote'),
  },
  {
    value: 'export',
    label: t('producedBeer.taxEvent.intents.export'),
    note: t('producedBeer.taxEvent.intents.exportNote'),
  },
  {
    value: 'return',
    label: t('producedBeer.taxEvent.intents.return'),
    note: t('producedBeer.taxEvent.intents.returnNote'),
  },
  {
    value: 'inbound',
    label: t('producedBeer.taxEvent.intents.inbound'),
    note: t('producedBeer.taxEvent.intents.inboundNote'),
  },
  {
    value: 'nontax_other',
    label: t('producedBeer.taxEvent.intents.nontaxOther'),
    note: t('producedBeer.taxEvent.intents.nontaxOtherNote'),
  },
]))

const taxEvent = reactive({
  intent: '',
  status: 'draft',
  shipFromSite: '',
  shipToParty: '',
  shipDate: '',
  exportMode: '',
  destinationCountry: '',
  plannedShipDate: '',
  receivingSite: '',
  sourceType: '',
  sourceParty: '',
  receiptDate: '',
  removalSite: '',
  reasonCode: '',
  plannedDate: '',
  items: [] as Array<{
    id: string
    product: string
    batch: string
    qty: string
    uom: string
    abv: string
    taxCategory: string
  }>,
  invoiceNo: '',
  blNo: '',
})

const taxTreatmentLabel = computed(() => {
  switch (taxEvent.intent) {
    case 'domestic':
      return t('producedBeer.taxEvent.treatments.taxed')
    case 'export':
      return t('producedBeer.taxEvent.treatments.export')
    case 'return':
      return t('producedBeer.taxEvent.treatments.return')
    case 'inbound':
      return t('producedBeer.taxEvent.treatments.inbound')
    case 'nontax_other':
      return t('producedBeer.taxEvent.treatments.nontaxOther')
    default:
      return t('producedBeer.taxEvent.treatments.unselected')
  }
})

const intentLabel = computed(() => {
  const match = intentOptions.value.find((option) => option.value === taxEvent.intent)
  return match?.label ?? t('producedBeer.taxEvent.intents.unselected')
})

const evidenceStatus = computed(() => {
  if (taxEvent.intent === 'export') {
    return taxEvent.invoiceNo || taxEvent.blNo
      ? t('producedBeer.taxEvent.review.evidenceProvided')
      : t('producedBeer.taxEvent.review.evidenceMissing')
  }
  return t('producedBeer.taxEvent.review.evidenceOptional')
})

function selectIntent(value: string) {
  if (taxEvent.intent && taxEvent.intent !== value) {
    const confirmed = window.confirm(t('producedBeer.taxEvent.confirmIntentChange'))
    if (!confirmed) return
  }
  taxEvent.intent = value
}

function addItem() {
  taxEvent.items.push({
    id: `${Date.now()}-${Math.random().toString(16).slice(2, 6)}`,
    product: '',
    batch: '',
    qty: '',
    uom: '',
    abv: '',
    taxCategory: '',
  })
}

function removeItem(index: number) {
  taxEvent.items.splice(index, 1)
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
</script>
