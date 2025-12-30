<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="currentPageTitle" />
    <div class="space-y-6">
      <section class="rounded-2xl border border-slate-200 bg-white shadow-sm">
        <header
          class="flex flex-col gap-2 border-b border-slate-100 px-6 py-5 cursor-pointer select-none lg:flex-row lg:items-center lg:justify-between"
          @click="inventoryOpen = !inventoryOpen"
        >
          <div>
            <h2 class="text-lg font-semibold text-slate-900">
              {{ $t('orderAssistant.inventory.title') }}
            </h2>
            <p class="mt-1 text-sm text-slate-500">
              {{ $t('orderAssistant.inventory.subtitle') }}
            </p>
          </div>
          <ChevronDownIcon
            class="h-5 w-5 text-slate-400 transition-transform duration-200 lg:ml-auto"
            :class="{ 'rotate-180 text-slate-600': inventoryOpen }"
          />
        </header>
        <div v-show="inventoryOpen" class="px-6 py-6 overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="text-left text-xs font-semibold uppercase text-slate-500">
              <tr>
                <th class="py-3 pr-3">{{ $t('orderAssistant.inventory.columns.material') }}</th>
                <th class="py-3 pr-3">{{ $t('orderAssistant.inventory.columns.onHand') }}</th>
                <th class="py-3 pr-3">{{ $t('orderAssistant.inventory.columns.safety') }}</th>
                <th class="py-3 pr-3">{{ $t('orderAssistant.inventory.columns.coverage') }}</th>
                <th class="py-3">{{ $t('orderAssistant.inventory.columns.status') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100 text-slate-800">
              <tr v-for="item in inventoryLevels" :key="item.id">
                <td class="py-3 pr-3">
                  <p class="font-semibold">{{ item.materialName }}</p>
                  <p class="text-xs text-slate-500">{{ item.materialCode }}</p>
                </td>
                <td class="py-3 pr-3">
                  {{ item.onHand }} {{ item.unit }}
                </td>
                <td class="py-3 pr-3">
                  {{ item.safetyStock }} {{ item.unit }}
                </td>
                <td class="py-3 pr-3">
                  ~{{ item.coverageDays }} {{ $t('orderAssistant.inventory.coverageDays') }}
                </td>
                <td class="py-3">
                  <span
                    :class="['inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold', inventoryStatusClass(item)]"
                  >
                    {{ inventoryStatusLabel(item) }}
                  </span>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section class="rounded-2xl border border-slate-200 bg-white shadow-sm">
        <header
          class="flex flex-col gap-2 border-b border-slate-100 px-6 py-5 cursor-pointer select-none lg:flex-row lg:items-center lg:justify-between"
          @click="productionOpen = !productionOpen"
        >
          <div>
            <h2 class="text-lg font-semibold text-slate-900">
              {{ $t('orderAssistant.production.title') }}
            </h2>
            <p class="mt-1 text-sm text-slate-500">
              {{ $t('orderAssistant.production.subtitle') }}
            </p>
          </div>
          <ChevronDownIcon
            class="h-5 w-5 text-slate-400 transition-transform duration-200 lg:ml-auto"
            :class="{ 'rotate-180 text-slate-600': productionOpen }"
          />
        </header>
        <div v-show="productionOpen" class="px-6 py-6 overflow-x-auto">
          <table class="min-w-full divide-y divide-slate-200 text-sm">
            <thead class="text-left text-xs font-semibold uppercase text-slate-500">
              <tr>
                <th class="py-3 pr-3">{{ $t('orderAssistant.production.columns.beer') }}</th>
                <th class="py-3 pr-3">{{ $t('orderAssistant.production.columns.brewDate') }}</th>
                <th class="py-3 pr-3">{{ $t('orderAssistant.production.columns.volume') }}</th>
                <th class="py-3 pr-3">{{ $t('orderAssistant.production.columns.status') }}</th>
                <th class="py-3">{{ $t('orderAssistant.production.columns.notes') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100 text-slate-800">
              <tr v-for="batch in upcomingBeers" :key="batch.id">
                <td class="py-3 pr-3 font-semibold">
                  {{ batch.beerName }}
                </td>
                <td class="py-3 pr-3">
                  {{ formatDate(batch.brewDate) }}
                </td>
                <td class="py-3 pr-3">
                  {{ batch.volumeL.toLocaleString() }} L
                </td>
                <td class="py-3 pr-3">
                  <span
                    :class="['inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold', productionStatusClass(batch.status)]"
                  >
                    {{ productionStatusLabel(batch.status) }}
                  </span>
                </td>
                <td class="py-3">
                  <p class="text-xs text-slate-500">
                    {{ batch.notes }}
                  </p>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section class="rounded-2xl border border-slate-200 bg-white shadow-sm">
        <header class="flex flex-col gap-4 border-b border-slate-100 px-6 py-5 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h1 class="text-xl font-semibold text-slate-900">
              {{ currentPageTitle }}
            </h1>
            <p class="mt-1 text-sm text-slate-500">
              {{ $t('orderAssistant.subtitle') }}
            </p>
          </div>
          <div class="flex flex-wrap gap-3">
            <button
              type="button"
              class="inline-flex items-center gap-2 rounded-full bg-blue-600 px-5 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 disabled:cursor-not-allowed disabled:bg-slate-300"
              :disabled="isGenerating"
              @click="generateOrders"
            >
              <svg v-if="isGenerating" class="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                <path class="opacity-90" d="M22 12a10 10 0 0 0-10-10" stroke="currentColor" stroke-width="4" stroke-linecap="round" />
              </svg>
              <span>
                {{
                  isGenerating
                    ? $t('orderAssistant.generating')
                    : $t('orderAssistant.generateBtn')
                }}
              </span>
            </button>
            <p v-if="lastGeneratedAt" class="text-xs text-slate-500">
              {{ $t('orderAssistant.lastRun', { time: formatTimestamp(lastGeneratedAt) }) }}
            </p>
          </div>
        </header>
        <div class="px-6 py-6 space-y-4">
          <p
            v-if="orderLines.length === 0 && !isGenerating"
            class="rounded-xl border border-dashed border-slate-200 bg-slate-50 px-4 py-6 text-center text-sm text-slate-500"
          >
            {{ $t('orderAssistant.emptyState') }}
          </p>
          <div v-else class="overflow-x-auto">
            <table class="min-w-full divide-y divide-slate-200 text-sm">
              <thead class="text-left text-xs font-semibold uppercase text-slate-500">
                <tr>
                  <th class="py-3 pr-3">{{ $t('orderAssistant.columns.material') }}</th>
                  <th class="py-3 pr-3">{{ $t('orderAssistant.columns.qty') }}</th>
                  <th class="py-3 pr-3">{{ $t('orderAssistant.columns.supplier') }}</th>
                  <th class="py-3 pr-3">{{ $t('orderAssistant.columns.email') }}</th>
                  <th class="py-3 pr-3">{{ $t('orderAssistant.columns.supabase') }}</th>
                  <th class="py-3 text-right">{{ $t('orderAssistant.columns.actions') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 text-slate-800">
                <tr v-for="line in orderLines" :key="line.id">
                  <td class="py-3 pr-3">
                    <p class="font-semibold">{{ line.materialName }}</p>
                    <p class="text-xs text-slate-500">{{ line.materialCode }}</p>
                  </td>
                  <td class="py-3 pr-3">
                    {{ line.quantity }} {{ line.unit }}
                  </td>
                  <td class="py-3 pr-3">
                    <p class="font-medium">{{ line.supplier.name }}</p>
                    <p class="text-xs text-slate-500">{{ line.supplier.email }}</p>
                  </td>
                  <td class="py-3 pr-3">
                    <span
                      :class="['inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium', statusClass(line.emailState)]"
                    >
                      {{ statusLabel(line.emailState) }}
                    </span>
                  </td>
                  <td class="py-3 pr-3">
                    <span
                      :class="['inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium', statusClass(line.supabaseState)]"
                    >
                      {{ statusLabel(line.supabaseState) }}
                    </span>
                  </td>
                  <td class="py-3 text-right">
                    <div class="flex flex-wrap justify-end gap-2">
                      <button
                        type="button"
                        class="rounded-full border border-slate-200 px-3 py-1 text-xs font-semibold text-slate-700 transition hover:bg-slate-100 disabled:cursor-not-allowed disabled:border-slate-100 disabled:text-slate-300"
                        :disabled="line.emailState === 'running' || line.emailState === 'success'"
                        @click="sendEmail(line)"
                      >
                        {{ $t('orderAssistant.actions.email') }}
                      </button>
                      <button
                        type="button"
                        class="rounded-full border border-blue-200 px-3 py-1 text-xs font-semibold text-blue-600 transition hover:bg-blue-50 disabled:cursor-not-allowed disabled:border-slate-100 disabled:text-slate-300"
                        :disabled="line.supabaseState === 'running' || line.supabaseState === 'success'"
                        @click="pushToSupabase(line)"
                      >
                        {{ $t('orderAssistant.actions.supabase') }}
                      </button>
                    </div>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'

import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { ChevronDownIcon } from '@/icons'

type ActionState = 'idle' | 'running' | 'success' | 'error'

type SupplierInfo = {
  name: string
  email: string
}

type OrderLine = {
  id: string
  materialCode: string
  materialName: string
  quantity: number
  unit: string
  supplier: SupplierInfo
  emailState: ActionState
  supabaseState: ActionState
}

const { t } = useI18n()
const currentPageTitle = computed(() => t('orderAssistant.title'))

type InventoryRow = {
  id: string
  materialCode: string
  materialName: string
  onHand: number
  safetyStock: number
  coverageDays: number
  unit: string
}

type UpcomingBatch = {
  id: string
  beerName: string
  brewDate: string
  volumeL: number
  status: 'scheduled' | 'planning' | 'waiting'
  notes: string
}

const orderLines = ref<OrderLine[]>([])
const isGenerating = ref(false)
const lastGeneratedAt = ref<string | null>(null)

const inventoryLevels = ref<InventoryRow[]>([
  {
    id: 'inv-1',
    materialCode: 'MALT-PALE-25',
    materialName: 'Pale Malt 25kg',
    onHand: 1120,
    safetyStock: 1600,
    coverageDays: 9,
    unit: 'kg',
  },
  {
    id: 'inv-2',
    materialCode: 'MALT-WHEAT-20',
    materialName: 'Wheat Malt 20kg',
    onHand: 620,
    safetyStock: 900,
    coverageDays: 6,
    unit: 'kg',
  },
  {
    id: 'inv-3',
    materialCode: 'HOPS-CITRA',
    materialName: 'Citra Hops (Pellet)',
    onHand: 18,
    safetyStock: 28,
    coverageDays: 5,
    unit: 'kg',
  },
  {
    id: 'inv-4',
    materialCode: 'YEAST-NEIPA',
    materialName: 'Juicy Yeast Pitch',
    onHand: 6,
    safetyStock: 10,
    coverageDays: 4,
    unit: 'packs',
  },
])

const upcomingBeers = ref<UpcomingBatch[]>([
  {
    id: 'batch-1',
    beerName: 'Galaxy IPA',
    brewDate: new Date().toISOString(),
    volumeL: 2400,
    status: 'scheduled',
    notes: 'Dry hop with 8kg Citra, packaging mid-month.',
  },
  {
    id: 'batch-2',
    beerName: 'Night Stout',
    brewDate: new Date(new Date().setDate(new Date().getDate() + 18)).toISOString(),
    volumeL: 1800,
    status: 'planning',
    notes: 'Check cocoa nib stock before brew day.',
  },
  {
    id: 'batch-3',
    beerName: 'Citrus Saison',
    brewDate: new Date(new Date().setMonth(new Date().getMonth() + 1, 8)).toISOString(),
    volumeL: 2000,
    status: 'waiting',
    notes: 'Awaiting approval of orange peel supplier.',
  },
])

const inventoryOpen = ref(false)
const productionOpen = ref(true)

const seedLineTemplates = [
  {
    materialCode: 'MALT-PALE-25',
    materialName: 'Pale Malt 25kg',
    quantity: 20,
    unit: 'bags',
    supplier: { name: 'Golden Grains Co.', email: 'orders@goldengrains.com' },
  },
  {
    materialCode: 'HOPS-CITRA',
    materialName: 'Citra Hops (Pellet)',
    quantity: 12,
    unit: 'kg',
    supplier: { name: 'Hop Galaxy', email: 'sales@hopgalaxy.io' },
  },
  {
    materialCode: 'YEAST-NEIPA',
    materialName: 'Juicy Yeast Pitch',
    quantity: 8,
    unit: 'packs',
    supplier: { name: 'Pure Pitch Labs', email: 'orders@purepitchlabs.com' },
  },
]

async function generateOrders() {
  if (isGenerating.value) return
  isGenerating.value = true
  await delay(900)
  orderLines.value = buildSeedLines()
  lastGeneratedAt.value = new Date().toISOString()
  isGenerating.value = false
}

async function sendEmail(line: OrderLine) {
  if (line.emailState === 'running' || line.emailState === 'success') return
  line.emailState = 'running'
  await delay(800)
  line.emailState = 'success'
}

async function pushToSupabase(line: OrderLine) {
  if (line.supabaseState === 'running' || line.supabaseState === 'success') return
  line.supabaseState = 'running'
  await delay(900)
  line.supabaseState = 'success'
}

function makeId() {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID()
  }
  return Math.random().toString(36).slice(2)
}

function buildSeedLines(): OrderLine[] {
  return seedLineTemplates.map((template) => ({
    id: makeId(),
    ...template,
    emailState: 'idle',
    supabaseState: 'idle',
  }))
}

function delay(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

function formatTimestamp(value: string) {
  const formatter = new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  })
  return formatter.format(new Date(value))
}

function formatDate(value: string) {
  const formatter = new Intl.DateTimeFormat(undefined, {
    month: 'short',
    day: 'numeric',
  })
  return formatter.format(new Date(value))
}

function inventoryStatusCode(item: InventoryRow) {
  const ratio = item.onHand / item.safetyStock
  if (ratio >= 1) return 'healthy'
  if (ratio >= 0.7) return 'warning'
  return 'critical'
}

function inventoryStatusLabel(item: InventoryRow) {
  const code = inventoryStatusCode(item)
  return t(`orderAssistant.inventory.status.${code}`)
}

function inventoryStatusClass(item: InventoryRow) {
  const code = inventoryStatusCode(item)
  if (code === 'healthy') return 'border-emerald-200 text-emerald-600 bg-emerald-50'
  if (code === 'warning') return 'border-amber-200 text-amber-600 bg-amber-50'
  return 'border-red-200 text-red-600 bg-red-50'
}

function productionStatusLabel(status: UpcomingBatch['status']) {
  return t(`orderAssistant.production.status.${status}`)
}

function productionStatusClass(status: UpcomingBatch['status']) {
  if (status === 'scheduled') return 'border-emerald-200 text-emerald-600 bg-emerald-50'
  if (status === 'planning') return 'border-blue-200 text-blue-600 bg-blue-50'
  return 'border-slate-200 text-slate-500 bg-white'
}

function statusLabel(state: ActionState) {
  switch (state) {
    case 'running':
      return t('orderAssistant.status.running')
    case 'success':
      return t('orderAssistant.status.success')
    case 'error':
      return t('orderAssistant.status.error')
    default:
      return t('orderAssistant.status.idle')
  }
}

function statusClass(state: ActionState) {
  switch (state) {
    case 'running':
      return 'border-amber-200 text-amber-600 bg-amber-50'
    case 'success':
      return 'border-emerald-200 text-emerald-600 bg-emerald-50'
    case 'error':
      return 'border-red-200 text-red-600 bg-red-50'
    default:
      return 'border-slate-200 text-slate-500 bg-white'
  }
}
</script>
