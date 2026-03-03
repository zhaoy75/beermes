<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-7xl mx-auto space-y-4">
      <header
        class="sticky top-0 z-20 -mx-4 px-4 py-3 border-b border-gray-200 bg-white/95 backdrop-blur"
      >
        <div class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h1 class="text-xl font-semibold">{{ t('producedBeer.movementFast.title') }}</h1>
            <p class="text-sm text-gray-500">{{ t('producedBeer.movementFast.subtitle') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50"
              type="button"
              @click="goBack"
            >
              {{ t('producedBeer.movementFast.actions.back') }}
            </button>
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
              type="button"
              :disabled="saving"
              @click="submit('post')"
            >
              {{ t('producedBeer.movementFast.actions.post') }}
            </button>
            <button
              class="px-3 py-2 rounded bg-gray-900 text-white hover:bg-gray-800 disabled:opacity-50"
              type="button"
              :disabled="saving"
              @click="submit('next')"
            >
              {{ t('producedBeer.movementFast.actions.postNext') }}
            </button>
          </div>
        </div>
      </header>

      <section
        class="sticky top-[88px] z-10 border border-gray-200 rounded-2xl bg-white shadow-sm p-4"
      >
        <div class="grid grid-cols-1 lg:grid-cols-12 gap-3">
          <div class="lg:col-span-3">
            <label class="block text-sm text-gray-600 mb-1">{{
              t('producedBeer.movementFast.fields.fromSite')
            }}</label>
            <select
              v-model="routeForm.fromSiteId"
              class="w-full h-[42px] border rounded-lg px-3 bg-white"
            >
              <option value="">{{ t('common.select') }}</option>
              <option v-for="site in sourceSiteOptions" :key="site.id" :value="site.id">
                {{ siteOptionLabel(site) }}
              </option>
            </select>
          </div>
          <div class="lg:col-span-1 flex items-end">
            <button
              class="w-full h-[42px] rounded-lg border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
              type="button"
              :disabled="!routeForm.fromSiteId && !routeForm.toSiteId"
              @click="swapRoute"
            >
              {{ t('producedBeer.movementFast.actions.swap') }}
            </button>
          </div>
          <div class="lg:col-span-3">
            <div class="flex items-center justify-between">
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movementFast.fields.toSite')
              }}</label>
              <button
                class="text-xs text-gray-500 hover:text-gray-900"
                type="button"
                :disabled="!canToggleFavorite"
                @click="toggleCurrentRouteFavorite"
              >
                {{
                  isCurrentRouteFavorite
                    ? t('producedBeer.movementFast.actions.unfavorite')
                    : t('producedBeer.movementFast.actions.favorite')
                }}
              </button>
            </div>
            <select
              v-model="routeForm.toSiteId"
              class="w-full h-[42px] border rounded-lg px-3 bg-white"
            >
              <option value="">{{ t('common.select') }}</option>
              <option v-for="site in destinationSiteOptions" :key="site.id" :value="site.id">
                {{ siteOptionLabel(site) }}
              </option>
            </select>
          </div>
          <div class="lg:col-span-2">
            <label class="block text-sm text-gray-600 mb-1">{{
              t('producedBeer.movementFast.fields.movedAt')
            }}</label>
            <input
              v-model="routeForm.movedAt"
              type="datetime-local"
              class="w-full h-[42px] border rounded-lg px-3"
            />
          </div>
          <div class="lg:col-span-2">
            <label class="block text-sm text-gray-600 mb-1">{{
              t('producedBeer.movementFast.fields.allocationPolicy')
            }}</label>
            <select
              v-model="routeForm.allocationPolicy"
              class="w-full h-[42px] border rounded-lg px-3 bg-white"
            >
              <option v-for="option in allocationOptions" :key="option.value" :value="option.value">
                {{ option.label }}
              </option>
            </select>
          </div>
          <div class="lg:col-span-1">
            <label class="block text-sm text-gray-600 mb-1">{{
              t('producedBeer.movementFast.fields.lines')
            }}</label>
            <div
              class="h-[42px] rounded-lg border border-dashed border-gray-300 flex items-center justify-center text-sm text-gray-600"
            >
              {{ validLineCount }}
            </div>
          </div>
          <div class="lg:col-span-12">
            <label class="block text-sm text-gray-600 mb-1">{{
              t('producedBeer.movementFast.fields.note')
            }}</label>
            <input
              v-model.trim="routeForm.note"
              type="text"
              class="w-full h-[42px] border rounded-lg px-3"
            />
          </div>
        </div>
        <div v-if="routeErrors.length" class="mt-3 flex flex-wrap gap-2">
          <span
            v-for="error in routeErrors"
            :key="error"
            class="inline-flex items-center rounded-full bg-red-50 px-3 py-1 text-xs text-red-700 border border-red-200"
          >
            {{ error }}
          </span>
        </div>
      </section>

      <div class="grid grid-cols-1 xl:grid-cols-[18rem_minmax(0,1fr)_20rem] gap-4 items-start">
        <aside class="space-y-4">
          <section class="border border-gray-200 rounded-2xl bg-white shadow-sm p-4">
            <div class="flex items-center justify-between mb-3">
              <div>
                <h2 class="text-sm font-semibold text-gray-900">
                  {{ t('producedBeer.movementFast.panels.routes') }}
                </h2>
                <p class="text-xs text-gray-500">
                  {{ t('producedBeer.movementFast.hints.routes') }}
                </p>
              </div>
            </div>

            <div class="space-y-3">
              <div>
                <h3 class="text-xs uppercase tracking-wide text-gray-400 mb-2">
                  {{ t('producedBeer.movementFast.panels.favorites') }}
                </h3>
                <div class="space-y-2">
                  <button
                    v-for="preset in favoriteRoutes"
                    :key="`fav-${preset.key}`"
                    class="w-full text-left rounded-xl border border-gray-200 p-3 hover:bg-gray-50"
                    type="button"
                    @click="applyRoutePreset(preset)"
                  >
                    <div class="text-sm font-medium text-gray-900">
                      {{ preset.fromSiteName }} → {{ preset.toSiteName }}
                    </div>
                    <div class="text-xs text-gray-500">{{ formatDateTime(preset.lastUsedAt) }}</div>
                  </button>
                  <p v-if="favoriteRoutes.length === 0" class="text-sm text-gray-500">
                    {{ t('common.noData') }}
                  </p>
                </div>
              </div>

              <div>
                <h3 class="text-xs uppercase tracking-wide text-gray-400 mb-2">
                  {{ t('producedBeer.movementFast.panels.recent') }}
                </h3>
                <div class="space-y-2">
                  <button
                    v-for="preset in recentRoutes"
                    :key="`recent-${preset.key}`"
                    class="w-full text-left rounded-xl border border-gray-200 p-3 hover:bg-gray-50"
                    type="button"
                    @click="applyRoutePreset(preset)"
                  >
                    <div class="text-sm font-medium text-gray-900">
                      {{ preset.fromSiteName }} → {{ preset.toSiteName }}
                    </div>
                    <div class="flex items-center justify-between text-xs text-gray-500">
                      <span>{{ formatDateTime(preset.lastUsedAt) }}</span>
                      <span>{{
                        t('producedBeer.movementFast.labels.uses', { count: preset.useCount })
                      }}</span>
                    </div>
                  </button>
                  <p v-if="recentRoutes.length === 0" class="text-sm text-gray-500">
                    {{ t('common.noData') }}
                  </p>
                </div>
              </div>
            </div>
          </section>
        </aside>

        <section class="border border-gray-200 rounded-2xl bg-white shadow-sm p-4 space-y-4">
          <div class="flex flex-col gap-2 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <h2 class="text-sm font-semibold text-gray-900">
                {{ t('producedBeer.movementFast.panels.lines') }}
              </h2>
              <p class="text-xs text-gray-500">
                {{
                  routeForm.fromSiteId
                    ? t('producedBeer.movementFast.hints.beerSearch')
                    : t('producedBeer.movementFast.hints.selectSourceFirst')
                }}
              </p>
            </div>
            <div class="flex items-center gap-2">
              <span v-if="inventoryLoading" class="text-xs text-gray-500">{{
                t('common.loading')
              }}</span>
              <span v-else class="text-xs text-gray-500">{{
                t('producedBeer.movementFast.labels.availableBeerCount', {
                  count: beerOptions.length,
                })
              }}</span>
            </div>
          </div>

          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-500">
                <tr>
                  <th class="px-3 py-2 text-left w-14">#</th>
                  <th class="px-3 py-2 text-left min-w-[22rem]">
                    {{ t('producedBeer.movementFast.columns.beer') }}
                  </th>
                  <th class="px-3 py-2 text-right w-40">
                    {{ t('producedBeer.movementFast.columns.quantity') }}
                  </th>
                  <th class="px-3 py-2 text-left min-w-[14rem]">
                    {{ t('producedBeer.movementFast.columns.note') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="(row, index) in lineRows" :key="row.id" class="align-top">
                  <td class="px-3 py-2 text-xs text-gray-400">{{ index + 1 }}</td>
                  <td class="px-3 py-2">
                    <div class="relative">
                      <input
                        :ref="(el) => setBeerInputRef(row.id, el)"
                        v-model="row.searchText"
                        type="text"
                        class="w-full h-[38px] border rounded-lg px-3"
                        :placeholder="t('producedBeer.movementFast.placeholders.beer')"
                        @focus="activeSuggestionRowId = row.id"
                        @blur="handleBeerBlur(row.id)"
                        @input="handleBeerInput(index)"
                        @keydown="handleBeerKeydown($event, index)"
                        @paste="handleBeerPaste($event, index)"
                      />
                      <div
                        v-if="
                          activeSuggestionRowId === row.id &&
                          row.searchText.trim() &&
                          filteredBeerOptions(index).length
                        "
                        class="absolute z-20 mt-1 w-full rounded-xl border border-gray-200 bg-white shadow-lg"
                      >
                        <button
                          v-for="option in filteredBeerOptions(index)"
                          :key="option.key"
                          class="w-full px-3 py-2 text-left hover:bg-gray-50 border-b border-gray-100 last:border-b-0"
                          type="button"
                          @mousedown.prevent="selectBeer(index, option)"
                        >
                          <div class="text-sm font-medium text-gray-900">
                            {{ displayBeerOption(option) }}
                          </div>
                          <div class="text-xs text-gray-500">
                            {{ option.styleName || option.beerName }}
                            <span class="ml-2">{{
                              t('producedBeer.movementFast.labels.stock', {
                                qty: formatNumber(option.totalQtyLiters),
                              })
                            }}</span>
                          </div>
                        </button>
                      </div>
                    </div>
                    <p
                      v-if="row.beerKey && beerOptionByKey.get(row.beerKey)"
                      class="mt-1 text-xs text-gray-500"
                    >
                      {{
                        t('producedBeer.movementFast.labels.stock', {
                          qty: formatNumber(
                            beerOptionByKey.get(row.beerKey)?.totalQtyLiters ?? null,
                          ),
                        })
                      }}
                    </p>
                    <p v-if="lineErrorMap[row.id]" class="mt-1 text-xs text-red-600">
                      {{ lineErrorMap[row.id] }}
                    </p>
                  </td>
                  <td class="px-3 py-2">
                    <input
                      :ref="(el) => setQtyInputRef(row.id, el)"
                      v-model="row.qtyText"
                      type="number"
                      min="0"
                      step="0.001"
                      inputmode="decimal"
                      class="w-full h-[38px] border rounded-lg px-3 text-right"
                      placeholder="0.000"
                      @keydown="handleQtyKeydown($event, index)"
                    />
                  </td>
                  <td class="px-3 py-2">
                    <input
                      v-model.trim="row.note"
                      type="text"
                      class="w-full h-[38px] border rounded-lg px-3"
                      :placeholder="t('producedBeer.movementFast.placeholders.note')"
                    />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div
            class="flex flex-wrap items-center justify-between gap-3 border-t border-gray-100 pt-3"
          >
            <p class="text-xs text-gray-500">
              {{ t('producedBeer.movementFast.hints.pasteExample') }}
            </p>
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50"
              type="button"
              @click="resetLines"
            >
              {{ t('producedBeer.movementFast.actions.clearLines') }}
            </button>
          </div>
        </section>

        <aside class="space-y-4">
          <section class="border border-gray-200 rounded-2xl bg-white shadow-sm p-4 space-y-4">
            <div>
              <h2 class="text-sm font-semibold text-gray-900">
                {{ t('producedBeer.movementFast.panels.summary') }}
              </h2>
              <p class="text-xs text-gray-500">
                {{ t('producedBeer.movementFast.hints.summary') }}
              </p>
            </div>

            <dl class="space-y-2 text-sm">
              <div class="flex items-center justify-between gap-4">
                <dt class="text-gray-500">{{ t('producedBeer.movementFast.summary.route') }}</dt>
                <dd class="text-right font-medium text-gray-900">{{ routeSummaryText }}</dd>
              </div>
              <div class="flex items-center justify-between gap-4">
                <dt class="text-gray-500">{{ t('producedBeer.movementFast.summary.policy') }}</dt>
                <dd class="text-right font-medium text-gray-900">
                  {{ allocationPolicyLabel(routeForm.allocationPolicy) }}
                </dd>
              </div>
              <div class="flex items-center justify-between gap-4">
                <dt class="text-gray-500">{{ t('producedBeer.movementFast.summary.lines') }}</dt>
                <dd class="text-right font-medium text-gray-900">{{ validLineCount }}</dd>
              </div>
              <div class="flex items-center justify-between gap-4">
                <dt class="text-gray-500">{{ t('producedBeer.movementFast.summary.totalQty') }}</dt>
                <dd class="text-right font-medium text-gray-900">
                  {{ formatNumber(totalQtyLiters) }}
                </dd>
              </div>
            </dl>

            <div>
              <h3 class="text-xs uppercase tracking-wide text-gray-400 mb-2">
                {{ t('producedBeer.movementFast.panels.validation') }}
              </h3>
              <div class="space-y-2">
                <p v-if="allErrors.length === 0" class="text-sm text-emerald-700">
                  {{ t('producedBeer.movementFast.labels.ready') }}
                </p>
                <p v-for="error in allErrors" :key="error" class="text-sm text-red-600">
                  {{ error }}
                </p>
              </div>
            </div>

            <div>
              <h3 class="text-xs uppercase tracking-wide text-gray-400 mb-2">
                {{ t('producedBeer.movementFast.panels.warnings') }}
              </h3>
              <div class="space-y-2">
                <p v-if="warnings.length === 0" class="text-sm text-gray-500">
                  {{ t('common.none') }}
                </p>
                <p v-for="warning in warnings" :key="warning" class="text-sm text-amber-600">
                  {{ warning }}
                </p>
              </div>
            </div>

            <div
              v-if="routeForm.allocationPolicy === 'MANUAL'"
              class="rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800"
            >
              {{ t('producedBeer.movementFast.hints.manualMode') }}
            </div>
          </section>
        </aside>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

type SiteOption = {
  id: string
  name: string
  siteTypeKey: string | null
}

type BeerLotOption = {
  lotId: string
  lotNo: string | null
  batchId: string | null
  batchCode: string | null
  qtyLiters: number
  producedAt: string | null
  expiresAt: string | null
}

type BeerOption = {
  key: string
  beerCode: string
  beerName: string
  styleName: string | null
  totalQtyLiters: number
  candidateLots: BeerLotOption[]
  searchIndex: string
}

type LineRow = {
  id: string
  searchText: string
  beerKey: string
  qtyText: string
  note: string
}

type RoutePreset = {
  key: string
  fromSiteId: string
  toSiteId: string
  fromSiteName: string
  toSiteName: string
  lastUsedAt: string
  useCount: number
  favorite: boolean
}

type SubmitMode = 'post' | 'next'

const INTERNAL_SITE_TYPES = [
  'BREWERY_MANUFACTUR',
  'BREWERY_STORAGE',
  'TAX_STORAGE',
  'DIRECT_SALES_SHOP',
]
const WARNING_NEAR_EXPIRY_DAYS = 30
const ROUTE_STORAGE_PREFIX = 'product-move-fast-routes'

const router = useRouter()
const { t, locale } = useI18n()
const pageTitle = computed(() => t('producedBeer.movementFast.title'))

const tenantId = ref<string | null>(null)
const userId = ref<string | null>(null)
const siteOptions = ref<SiteOption[]>([])
const beerOptions = ref<BeerOption[]>([])
const storedRoutes = ref<RoutePreset[]>([])
const inventoryLoading = ref(false)
const saving = ref(false)
const activeSuggestionRowId = ref<string | null>(null)
const beerInputRefs = new Map<string, HTMLInputElement>()
const qtyInputRefs = new Map<string, HTMLInputElement>()

const routeForm = reactive({
  fromSiteId: '',
  toSiteId: '',
  movedAt: formatDateTimeLocal(new Date()),
  allocationPolicy: 'FEFO',
  note: '',
})

const allocationOptions = computed(() => [
  { value: 'FEFO', label: t('producedBeer.movementFast.allocation.fefo') },
  { value: 'FIFO', label: t('producedBeer.movementFast.allocation.fifo') },
  { value: 'MANUAL', label: t('producedBeer.movementFast.allocation.manual') },
])

let rowSeed = 0

function createEmptyRow(): LineRow {
  rowSeed += 1
  return {
    id: `line-${rowSeed}`,
    searchText: '',
    beerKey: '',
    qtyText: '',
    note: '',
  }
}

function createInitialRows(count = 5) {
  return Array.from({ length: count }, () => createEmptyRow())
}

const lineRows = ref<LineRow[]>(createInitialRows())

function toNumber(value: unknown): number | null {
  if (value == null || value === '') return null
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : null
}

function formatDateTimeLocal(value: Date) {
  const yyyy = value.getFullYear()
  const mm = String(value.getMonth() + 1).padStart(2, '0')
  const dd = String(value.getDate()).padStart(2, '0')
  const hh = String(value.getHours()).padStart(2, '0')
  const mi = String(value.getMinutes()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}T${hh}:${mi}`
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleString(locale.value)
}

function formatNumber(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return new Intl.NumberFormat(locale.value, { maximumFractionDigits: 3 }).format(value)
}

function resolveBatchLabel(meta: Record<string, any> | null | undefined) {
  const label = meta?.label
  if (typeof label !== 'string') return null
  const trimmed = label.trim()
  return trimmed.length ? trimmed : null
}

function resolveMetaString(meta: Record<string, any> | null | undefined, key: string) {
  const value = meta?.[key]
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  return trimmed.length ? trimmed : null
}

function normalizeVolumeUom(code: string | null | undefined) {
  if (!code) return null
  const normalized = code.trim().toLowerCase()
  return normalized || null
}

function convertToLiters(value: number, uomCode: string | null | undefined) {
  const normalized = normalizeVolumeUom(uomCode)
  if (!normalized || normalized === 'l') return value
  if (normalized === 'ml') return value / 1000
  if (normalized === 'hl') return value * 100
  if (normalized === 'gal_us') return value * 3.78541
  return value
}

function setBeerInputRef(id: string, el: unknown) {
  if (el instanceof HTMLInputElement) beerInputRefs.set(id, el)
  else beerInputRefs.delete(id)
}

function setQtyInputRef(id: string, el: unknown) {
  if (el instanceof HTMLInputElement) qtyInputRefs.set(id, el)
  else qtyInputRefs.delete(id)
}

function focusBeerRow(index: number) {
  const row = lineRows.value[index]
  if (!row) return
  const target = beerInputRefs.get(row.id)
  if (!target) return
  target.focus()
  target.select()
}

function focusQtyRow(index: number) {
  const row = lineRows.value[index]
  if (!row) return
  const target = qtyInputRefs.get(row.id)
  if (!target) return
  target.focus()
  target.select()
}

async function ensureTenant() {
  if (tenantId.value && userId.value) return { tenantId: tenantId.value, userId: userId.value }
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const resolvedTenant = data.user?.app_metadata?.tenant_id as string | undefined
  const resolvedUser = data.user?.id as string | undefined
  if (!resolvedTenant || !resolvedUser)
    throw new Error(t('producedBeer.movementFast.errors.tenantRequired'))
  tenantId.value = resolvedTenant
  userId.value = resolvedUser
  return { tenantId: resolvedTenant, userId: resolvedUser }
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
  const auth = await ensureTenant()
  const { data: siteTypeDefs, error: typeError } = await supabase
    .from('registry_def')
    .select('def_id, def_key')
    .eq('kind', 'site_type')
    .eq('is_active', true)
  if (typeError) throw typeError

  const siteTypeMap = new Map<string, string>()
  ;(siteTypeDefs ?? []).forEach((row: any) => {
    if (row?.def_id) siteTypeMap.set(String(row.def_id), String(row.def_key ?? ''))
  })

  const { data, error } = await supabase
    .from('mst_sites')
    .select('id, name, site_type_id')
    .eq('tenant_id', auth.tenantId)
    .eq('active', true)
    .order('name', { ascending: true })
  if (error) throw error

  siteOptions.value = (data ?? [])
    .map((row: any) => {
      const defKey = siteTypeMap.get(String(row.site_type_id ?? '')) ?? null
      return {
        id: String(row.id),
        name: String(row.name ?? row.id),
        siteTypeKey: toRuleSiteTypeKey(defKey),
      } satisfies SiteOption
    })
    .filter((row) => row.siteTypeKey && INTERNAL_SITE_TYPES.includes(row.siteTypeKey))
}

function siteOptionLabel(site: SiteOption) {
  const siteType = site.siteTypeKey
    ? t(`producedBeer.movementFast.siteTypes.${site.siteTypeKey}`)
    : ''
  return siteType ? `${site.name} (${siteType})` : site.name
}

const sourceSiteOptions = computed(() => siteOptions.value)
const destinationSiteOptions = computed(() => siteOptions.value)
const siteMap = computed(() => new Map(siteOptions.value.map((site) => [site.id, site])))

const fromSite = computed(() => siteMap.value.get(routeForm.fromSiteId) ?? null)
const toSite = computed(() => siteMap.value.get(routeForm.toSiteId) ?? null)

function compareDateAsc(a: string | null | undefined, b: string | null | undefined) {
  const aTime = a ? Date.parse(a) : Number.POSITIVE_INFINITY
  const bTime = b ? Date.parse(b) : Number.POSITIVE_INFINITY
  return aTime - bTime
}

async function loadBeerOptionsForSite(siteId: string) {
  inventoryLoading.value = true
  try {
    const auth = await ensureTenant()
    const { data: inventoryRows, error } = await supabase
      .from('inv_inventory')
      .select(
        'lot_id, qty, uom_id, lot:lot_id ( id, lot_no, batch_id, produced_at, expires_at, status )',
      )
      .eq('tenant_id', auth.tenantId)
      .eq('site_id', siteId)
      .gt('qty', 0)
    if (error) throw error

    const activeRows = (inventoryRows ?? []).filter((row: any) => {
      const lotRow = Array.isArray(row.lot) ? row.lot[0] : row.lot
      return lotRow && lotRow.status !== 'void'
    })
    if (!activeRows.length) {
      beerOptions.value = []
      return
    }

    const batchIds = Array.from(
      new Set(
        activeRows
          .map((row: any) => {
            const lotRow = Array.isArray(row.lot) ? row.lot[0] : row.lot
            return lotRow?.batch_id ? String(lotRow.batch_id) : ''
          })
          .filter(Boolean),
      ),
    )
    const uomIds = Array.from(
      new Set(activeRows.map((row: any) => String(row.uom_id ?? '')).filter(Boolean)),
    )

    const uomMap = new Map<string, string>()
    if (uomIds.length) {
      const { data: uoms, error: uomError } = await supabase
        .from('mst_uom')
        .select('id, code')
        .in('id', uomIds)
      if (uomError) throw uomError
      ;(uoms ?? []).forEach((row: any) => {
        if (row?.id) uomMap.set(String(row.id), String(row.code ?? ''))
      })
    }

    const batchMap = new Map<
      string,
      { batchCode: string; beerCode: string; beerName: string; styleName: string | null }
    >()
    if (batchIds.length) {
      const { data: batches, error: batchError } = await supabase
        .from('mes_batches')
        .select('id, batch_code, batch_label, product_name, meta, recipe:recipe_id ( style )')
        .eq('tenant_id', auth.tenantId)
        .in('id', batchIds)
      if (batchError) throw batchError
      ;(batches ?? []).forEach((row: any) => {
        const meta =
          row.meta && typeof row.meta === 'object' && !Array.isArray(row.meta)
            ? (row.meta as Record<string, any>)
            : null
        const recipe = Array.isArray(row.recipe) ? row.recipe[0] : row.recipe
        const batchCode = String(row.batch_code ?? row.id)
        const beerCode =
          resolveMetaString(meta, 'product_code') ??
          resolveMetaString(meta, 'beer_code') ??
          resolveMetaString(meta, 'recipe_code') ??
          batchCode
        const styleName =
          typeof recipe?.style === 'string' && recipe.style.trim()
            ? recipe.style.trim()
            : (resolveMetaString(meta, 'style_name') ?? resolveMetaString(meta, 'style'))
        const beerName = String(
          row.product_name ?? row.batch_label ?? resolveBatchLabel(meta) ?? styleName ?? beerCode,
        )
        batchMap.set(String(row.id), {
          batchCode,
          beerCode,
          beerName,
          styleName: styleName ?? null,
        })
      })
    }

    const optionMap = new Map<string, BeerOption>()
    activeRows.forEach((row: any) => {
      const lotRow = Array.isArray(row.lot) ? row.lot[0] : row.lot
      if (!lotRow?.batch_id) return
      const batchInfo = batchMap.get(String(lotRow.batch_id))
      if (!batchInfo) return
      const qtyValue = toNumber(row.qty)
      if (qtyValue == null || qtyValue <= 0) return
      const qtyLiters = convertToLiters(qtyValue, uomMap.get(String(row.uom_id ?? '')))
      if (qtyLiters == null || qtyLiters <= 0) return

      const key = `${batchInfo.beerCode}__${batchInfo.beerName}`
      if (!optionMap.has(key)) {
        const searchIndex = [
          batchInfo.beerCode,
          batchInfo.beerName,
          batchInfo.styleName,
          batchInfo.batchCode,
        ]
          .filter(Boolean)
          .join(' ')
          .toLowerCase()
        optionMap.set(key, {
          key,
          beerCode: batchInfo.beerCode,
          beerName: batchInfo.beerName,
          styleName: batchInfo.styleName,
          totalQtyLiters: 0,
          candidateLots: [],
          searchIndex,
        })
      }

      const option = optionMap.get(key)
      if (!option) return
      option.totalQtyLiters += qtyLiters
      option.candidateLots.push({
        lotId: String(lotRow.id),
        lotNo: lotRow.lot_no ? String(lotRow.lot_no) : null,
        batchId: String(lotRow.batch_id),
        batchCode: batchInfo.batchCode,
        qtyLiters,
        producedAt: typeof lotRow.produced_at === 'string' ? lotRow.produced_at : null,
        expiresAt: typeof lotRow.expires_at === 'string' ? lotRow.expires_at : null,
      })
    })

    beerOptions.value = Array.from(optionMap.values())
      .map((option) => ({
        ...option,
        candidateLots: [...option.candidateLots].sort((a, b) =>
          compareDateAsc(a.expiresAt || a.producedAt, b.expiresAt || b.producedAt),
        ),
      }))
      .sort((a, b) => a.beerCode.localeCompare(b.beerCode))
  } finally {
    inventoryLoading.value = false
  }
}

const beerOptionByKey = computed(
  () => new Map(beerOptions.value.map((option) => [option.key, option])),
)

function displayBeerOption(option: BeerOption) {
  return `${option.beerCode} · ${option.beerName}`
}

function filteredBeerOptions(index: number) {
  const row = lineRows.value[index]
  if (!row) return []
  const term = row.searchText.trim().toLowerCase()
  if (!term) return []
  return beerOptions.value.filter((option) => option.searchIndex.includes(term)).slice(0, 8)
}

function ensureTrailingRows() {
  const nonEmptyRows = lineRows.value.filter(
    (row) => row.searchText.trim() || row.qtyText.trim() || row.note.trim(),
  )
  const trailingEmpty = [...lineRows.value]
    .reverse()
    .findIndex((row) => row.searchText.trim() || row.qtyText.trim() || row.note.trim())
  const trailingEmptyCount = trailingEmpty === -1 ? lineRows.value.length : trailingEmpty

  if (lineRows.value.length < 5) {
    while (lineRows.value.length < 5) lineRows.value.push(createEmptyRow())
    return
  }
  if (nonEmptyRows.length > 0 && trailingEmptyCount < 2) {
    lineRows.value.push(createEmptyRow())
  }
}

function normalizeSelectedBeer(row: LineRow) {
  if (!row.beerKey) return
  const option = beerOptionByKey.value.get(row.beerKey)
  if (!option) {
    row.beerKey = ''
    return
  }
  if (row.searchText !== displayBeerOption(option)) row.beerKey = ''
}

function handleBeerInput(index: number) {
  const row = lineRows.value[index]
  if (!row) return
  normalizeSelectedBeer(row)
  activeSuggestionRowId.value = row.id
  ensureTrailingRows()
}

function selectBeer(index: number, option: BeerOption) {
  const row = lineRows.value[index]
  if (!row) return
  row.beerKey = option.key
  row.searchText = displayBeerOption(option)
  activeSuggestionRowId.value = null
  ensureTrailingRows()
  nextTick(() => focusQtyRow(index))
}

function handleBeerBlur(rowId: string) {
  window.setTimeout(() => {
    if (activeSuggestionRowId.value === rowId) activeSuggestionRowId.value = null
  }, 120)
}

function handleBeerKeydown(event: KeyboardEvent, index: number) {
  const suggestions = filteredBeerOptions(index)
  if (event.key === 'Enter') {
    event.preventDefault()
    const row = lineRows.value[index]
    if (!row) return
    if (suggestions.length) {
      selectBeer(index, suggestions[0])
      return
    }
    if (row.beerKey) {
      nextTick(() => focusQtyRow(index))
    }
  }
}

function applyParsedLines(index: number, parsedLines: Array<{ identifier: string; qty: number }>) {
  if (!parsedLines.length) return
  while (lineRows.value.length < index + parsedLines.length + 1)
    lineRows.value.push(createEmptyRow())
  parsedLines.forEach((parsed, offset) => {
    const row = lineRows.value[index + offset]
    if (!row) return
    const match = beerOptions.value.find((option) =>
      option.searchIndex.includes(parsed.identifier.toLowerCase()),
    )
    if (match) {
      row.beerKey = match.key
      row.searchText = displayBeerOption(match)
    } else {
      row.beerKey = ''
      row.searchText = parsed.identifier
    }
    row.qtyText = String(parsed.qty)
  })
  ensureTrailingRows()
}

function parsePasteText(text: string) {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      const match = line.match(/^(.+?)\s+(-?\d+(?:\.\d+)?)$/)
      if (!match) return null
      const qty = Number(match[2])
      if (!Number.isFinite(qty)) return null
      return { identifier: match[1].trim(), qty }
    })
    .filter((row): row is { identifier: string; qty: number } => !!row)
}

function handleBeerPaste(event: ClipboardEvent, index: number) {
  const text = event.clipboardData?.getData('text') ?? ''
  const parsed = parsePasteText(text)
  if (parsed.length <= 1) return
  event.preventDefault()
  applyParsedLines(index, parsed)
}

function handleQtyKeydown(event: KeyboardEvent, index: number) {
  if (event.key !== 'Enter') return
  event.preventDefault()
  ensureTrailingRows()
  nextTick(() => {
    const nextIndex = Math.min(index + 1, lineRows.value.length - 1)
    focusBeerRow(nextIndex)
  })
}

function resetLines() {
  lineRows.value = createInitialRows()
  activeSuggestionRowId.value = null
  nextTick(() => focusBeerRow(0))
}

function clearRowsForNewSource() {
  lineRows.value = createInitialRows()
  activeSuggestionRowId.value = null
}

function goBack() {
  router.back()
}

function swapRoute() {
  const from = routeForm.fromSiteId
  routeForm.fromSiteId = routeForm.toSiteId
  routeForm.toSiteId = from
}

function currentRouteKey(fromSiteId: string, toSiteId: string) {
  return `${fromSiteId}__${toSiteId}`
}

const canToggleFavorite = computed(() => !!routeForm.fromSiteId && !!routeForm.toSiteId)
const currentRouteStorageKey = computed(() =>
  currentRouteKey(routeForm.fromSiteId, routeForm.toSiteId),
)
const favoriteRoutes = computed(() => storedRoutes.value.filter((route) => route.favorite))
const recentRoutes = computed(() => storedRoutes.value.slice(0, 8))
const isCurrentRouteFavorite = computed(() =>
  storedRoutes.value.some((route) => route.key === currentRouteStorageKey.value && route.favorite),
)

function getRouteStorageKey() {
  return `${ROUTE_STORAGE_PREFIX}:${tenantId.value ?? 'tenant'}:${userId.value ?? 'user'}`
}

function loadStoredRoutes() {
  if (typeof window === 'undefined') return
  try {
    const raw = window.localStorage.getItem(getRouteStorageKey())
    storedRoutes.value = raw ? (JSON.parse(raw) as RoutePreset[]) : []
  } catch {
    storedRoutes.value = []
  }
}

function persistStoredRoutes() {
  if (typeof window === 'undefined') return
  window.localStorage.setItem(getRouteStorageKey(), JSON.stringify(storedRoutes.value.slice(0, 20)))
}

function applyRoutePreset(route: RoutePreset) {
  routeForm.fromSiteId = route.fromSiteId
  routeForm.toSiteId = route.toSiteId
}

function touchRoutePreset(favorite = false) {
  const fromSiteValue = fromSite.value
  const toSiteValue = toSite.value
  if (!fromSiteValue || !toSiteValue) return
  const key = currentRouteKey(fromSiteValue.id, toSiteValue.id)
  const existing = storedRoutes.value.find((route) => route.key === key)
  if (existing) {
    existing.lastUsedAt = new Date().toISOString()
    existing.useCount += 1
    if (favorite) existing.favorite = true
  } else {
    storedRoutes.value.unshift({
      key,
      fromSiteId: fromSiteValue.id,
      toSiteId: toSiteValue.id,
      fromSiteName: fromSiteValue.name,
      toSiteName: toSiteValue.name,
      lastUsedAt: new Date().toISOString(),
      useCount: 1,
      favorite,
    })
  }
  storedRoutes.value = [...storedRoutes.value].sort(
    (a, b) => Date.parse(b.lastUsedAt) - Date.parse(a.lastUsedAt),
  )
  persistStoredRoutes()
}

function toggleCurrentRouteFavorite() {
  const key = currentRouteStorageKey.value
  if (!key || !fromSite.value || !toSite.value) return
  const existing = storedRoutes.value.find((route) => route.key === key)
  if (existing) {
    existing.favorite = !existing.favorite
  } else {
    storedRoutes.value.unshift({
      key,
      fromSiteId: fromSite.value.id,
      toSiteId: toSite.value.id,
      fromSiteName: fromSite.value.name,
      toSiteName: toSite.value.name,
      lastUsedAt: new Date().toISOString(),
      useCount: 0,
      favorite: true,
    })
  }
  persistStoredRoutes()
}

function allocationPolicyLabel(value: string) {
  const option = allocationOptions.value.find((entry) => entry.value === value)
  return option?.label ?? value
}

function isAllowedPageRoute(
  srcSiteType: string | null | undefined,
  dstSiteType: string | null | undefined,
) {
  if (!srcSiteType || !dstSiteType) return true
  if (dstSiteType === 'DIRECT_SALES_SHOP') return false
  if (dstSiteType === 'TAX_STORAGE') return false
  if (srcSiteType === 'BREWERY_MANUFACTUR' && dstSiteType === 'BREWERY_STORAGE') return true
  if (srcSiteType === 'BREWERY_STORAGE' && dstSiteType === 'BREWERY_MANUFACTUR') return true
  if (srcSiteType === 'BREWERY_STORAGE' && dstSiteType === 'BREWERY_STORAGE') return true
  if (srcSiteType === 'BREWERY_MANUFACTUR' && dstSiteType === 'BREWERY_MANUFACTUR') return true
  return false
}

const routeErrors = computed(() => {
  const errors: string[] = []
  if (!routeForm.fromSiteId) errors.push(t('producedBeer.movementFast.errors.fromRequired'))
  if (!routeForm.toSiteId) errors.push(t('producedBeer.movementFast.errors.toRequired'))
  if (routeForm.fromSiteId && routeForm.toSiteId && routeForm.fromSiteId === routeForm.toSiteId) {
    errors.push(t('producedBeer.movementFast.errors.sameSite'))
  }

  const srcType = fromSite.value?.siteTypeKey ?? null
  const dstType = toSite.value?.siteTypeKey ?? null
  if (dstType === 'DIRECT_SALES_SHOP')
    errors.push(t('producedBeer.movementFast.errors.useDomesticShipment'))
  if (dstType === 'TAX_STORAGE') errors.push(t('producedBeer.movementFast.errors.useTaxMovement'))
  if ((srcType || dstType) && !isAllowedPageRoute(srcType, dstType)) {
    errors.push(t('producedBeer.movementFast.errors.invalidRoute'))
  }
  if (routeForm.allocationPolicy === 'MANUAL') {
    errors.push(t('producedBeer.movementFast.errors.manualNotImplemented'))
  }
  return Array.from(new Set(errors))
})

type ValidatedLine = {
  rowId: string
  index: number
  option: BeerOption
  qtyLiters: number
  note: string | null
}

const validatedLines = computed(() => {
  const valid: ValidatedLine[] = []
  lineRows.value.forEach((row, index) => {
    const option = row.beerKey ? beerOptionByKey.value.get(row.beerKey) : null
    const qty = toNumber(row.qtyText)
    if (!option || qty == null || qty <= 0) return
    valid.push({
      rowId: row.id,
      index,
      option,
      qtyLiters: qty,
      note: row.note.trim() || null,
    })
  })
  return valid
})

const lineErrorMap = computed(() => {
  const errors: Record<string, string> = {}
  lineRows.value.forEach((row) => {
    const hasAnyInput = !!row.searchText.trim() || !!row.qtyText.trim() || !!row.note.trim()
    if (!hasAnyInput) return
    const option = row.beerKey ? beerOptionByKey.value.get(row.beerKey) : null
    const qty = toNumber(row.qtyText)
    if (!row.searchText.trim()) {
      errors[row.id] = t('producedBeer.movementFast.errors.beerRequired')
      return
    }
    if (!option) {
      errors[row.id] = t('producedBeer.movementFast.errors.beerUnresolved')
      return
    }
    if (qty == null || qty <= 0) {
      errors[row.id] = t('producedBeer.movementFast.errors.qtyPositive')
      return
    }
    if (qty > option.totalQtyLiters + 0.0001) {
      errors[row.id] = t('producedBeer.movementFast.errors.qtyExceedsStock')
    }
  })
  return errors
})

const allErrors = computed(() => {
  const errors = [...routeErrors.value, ...Object.values(lineErrorMap.value)]
  if (errors.length === 0 && validatedLines.value.length === 0) {
    errors.push(t('producedBeer.movementFast.errors.lineRequired'))
  }
  return Array.from(new Set(errors))
})

const warnings = computed(() => {
  const messages: string[] = []
  validatedLines.value.forEach((line) => {
    if (line.option.candidateLots.length >= 3) {
      messages.push(
        t('producedBeer.movementFast.warnings.manyLots', { beer: line.option.beerCode }),
      )
    }
    if (
      line.option.candidateLots.some((lot) => {
        if (!lot.expiresAt) return false
        const expiresAt = Date.parse(lot.expiresAt)
        if (Number.isNaN(expiresAt)) return false
        const diffDays = (expiresAt - Date.now()) / (1000 * 60 * 60 * 24)
        return diffDays >= 0 && diffDays <= WARNING_NEAR_EXPIRY_DAYS
      })
    ) {
      messages.push(
        t('producedBeer.movementFast.warnings.nearExpiry', { beer: line.option.beerCode }),
      )
    }
    if (line.qtyLiters >= line.option.totalQtyLiters * 0.8) {
      messages.push(
        t('producedBeer.movementFast.warnings.lowStock', { beer: line.option.beerCode }),
      )
    }
  })
  return Array.from(new Set(messages))
})

const validLineCount = computed(() => validatedLines.value.length)
const totalQtyLiters = computed(() =>
  validatedLines.value.reduce((sum, line) => sum + line.qtyLiters, 0),
)
const routeSummaryText = computed(() => {
  if (!fromSite.value || !toSite.value) return '—'
  return `${fromSite.value.name} → ${toSite.value.name}`
})

function buildPayload() {
  return {
    movement_intent: 'INTERNAL_TRANSFER',
    from_site_id: routeForm.fromSiteId,
    to_site_id: routeForm.toSiteId,
    moved_at: new Date(routeForm.movedAt).toISOString(),
    allocation_policy: routeForm.allocationPolicy,
    note: routeForm.note.trim() || null,
    lines: validatedLines.value.map((line) => ({
      beer_code: line.option.beerCode,
      beer_name: line.option.beerName,
      qty_l: line.qtyLiters,
      note: line.note,
    })),
  }
}

async function submit(mode: SubmitMode) {
  if (saving.value) return
  if (allErrors.value.length) {
    toast.error(allErrors.value[0])
    return
  }

  saving.value = true
  try {
    const payload = buildPayload()
    const { data, error } = await supabase.rpc('product_move_fast', { p_doc: payload })
    if (error) throw error

    const movementId =
      typeof data === 'string'
        ? data
        : data && typeof data === 'object' && 'movement_id' in data
          ? String((data as Record<string, any>).movement_id ?? '')
          : ''

    touchRoutePreset(false)
    toast.success(t('producedBeer.movementFast.toast.saved', { movementId: movementId || '—' }))

    if (mode === 'next') {
      resetLines()
    }
  } catch (err: any) {
    console.error(err)
    const message = String(err?.message ?? '')
    if (message.includes('product_move_fast')) {
      toast.error(t('producedBeer.movementFast.errors.rpcUnavailable'))
    } else {
      toast.error(message || t('producedBeer.movementFast.errors.saveFailed'))
    }
  } finally {
    saving.value = false
  }
}

function handleGlobalKeydown(event: KeyboardEvent) {
  const target = event.target as HTMLElement | null
  const isEditable =
    !!target &&
    (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable)

  if (event.key === '/' && !event.metaKey && !event.ctrlKey && !event.altKey && !isEditable) {
    event.preventDefault()
    focusBeerRow(0)
    return
  }

  if (event.key === 'Enter' && event.ctrlKey) {
    event.preventDefault()
    submit('post').catch?.(() => undefined)
    return
  }
  if (event.key === 'Enter' && event.shiftKey) {
    event.preventDefault()
    submit('next').catch?.(() => undefined)
  }
}

watch(
  () => routeForm.fromSiteId,
  async (value, oldValue) => {
    if (value === oldValue) return
    clearRowsForNewSource()
    if (!value) {
      beerOptions.value = []
      return
    }
    try {
      await loadBeerOptionsForSite(value)
      nextTick(() => focusBeerRow(0))
    } catch (err) {
      console.error(err)
      beerOptions.value = []
      toast.error(err instanceof Error ? err.message : String(err))
    }
  },
)

watch(
  () => lineRows.value.map((row) => `${row.searchText}__${row.qtyText}__${row.note}`).join('|'),
  () => {
    ensureTrailingRows()
  },
)

onMounted(async () => {
  try {
    await ensureTenant()
    await loadSites()
    loadStoredRoutes()
    window.addEventListener('keydown', handleGlobalKeydown)
    nextTick(() => focusBeerRow(0))
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', handleGlobalKeydown)
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
