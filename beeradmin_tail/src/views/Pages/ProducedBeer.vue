<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 w-full space-y-6">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('producedBeer.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('producedBeer.subtitle') }}</p>
        </div>
      </header>

      <section class="border border-gray-200 rounded-xl shadow-sm p-4 bg-white space-y-4">
        <header class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-semibold">{{ t('producedBeer.sections.movements') }}</h2>
            <p class="text-sm text-gray-500">{{ t('producedBeer.movement.subtitle') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
              :disabled="!hasMovementColumnFilters"
              type="button"
              @click="clearMovementColumnFilters"
            >
              {{ t('common.clearFilters') }}
            </button>
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
              :disabled="movementLoading || exportLoading || visibleMovementCards.length === 0"
              @click="exportMovementsExcel"
            >
              {{
                exportLoading
                  ? t('producedBeer.movement.export.exporting')
                  : t('producedBeer.movement.actions.exportExcel')
              }}
            </button>
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50"
              @click="openMovementCreateFast"
            >
              {{ t('producedBeer.movement.actions.fast') }}
            </button>
            <button
              class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700"
              @click="openMovementCreate"
            >
              {{ t('producedBeer.movement.actions.new') }}
            </button>
            <button
              class="px-3 py-2 rounded border hover:bg-gray-50"
              type="button"
              @click="resetMovementFilters"
            >
              {{ t('common.reset') }}
            </button>
          </div>
        </header>

        <section class="border border-gray-200 rounded-lg p-4 bg-white">
          <form class="grid grid-cols-1 md:grid-cols-12 gap-3" @submit.prevent>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.batchNo')
              }}</label>
              <input
                v-model.trim="movementFilters.batchNo"
                type="search"
                class="w-full h-[40px] border rounded px-3"
              />
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.category')
              }}</label>
              <select
                v-model="movementFilters.category"
                class="w-full h-[40px] border rounded px-3 bg-white"
              >
                <option value="">{{ t('common.all') }}</option>
                <option
                  v-for="category in categories"
                  :key="category.def_id"
                  :value="category.def_id"
                >
                  {{
                    typeof category.spec?.name === 'string' ? category.spec.name : category.def_key
                  }}
                </option>
              </select>
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.packageType')
              }}</label>
              <select
                v-model="movementFilters.packageType"
                class="w-full h-[40px] border rounded px-3 bg-white"
              >
                <option value="">{{ t('common.all') }}</option>
                <option
                  v-for="option in packageCategoryOptions"
                  :key="option.value"
                  :value="option.value"
                >
                  {{ option.label }}
                </option>
              </select>
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.beerName')
              }}</label>
              <input
                v-model.trim="movementFilters.beerName"
                type="search"
                class="w-full h-[40px] border rounded px-3"
              />
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.dateFrom')
              }}</label>
              <AppDateTimePicker
                v-model="movementFilters.dateFrom"
                class="w-full h-[40px] border rounded px-3"
              />
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.dateTo')
              }}</label>
              <AppDateTimePicker
                v-model="movementFilters.dateTo"
                class="w-full h-[40px] border rounded px-3"
              />
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{
                t('producedBeer.movement.filters.movementType')
              }}</label>
              <select
                v-model="movementTypeFilter"
                class="w-full h-[40px] border rounded px-3 bg-white"
              >
                <option value="all">{{ t('common.all') }}</option>
                <option
                  v-for="option in taxEventFilterOptions"
                  :key="option.value"
                  :value="option.value"
                >
                  {{ option.label }}
                </option>
              </select>
            </div>
            <div class="md:col-span-3 flex items-end">
              <label class="flex min-h-[40px] items-center gap-2 text-sm text-gray-700">
                <input
                  v-model="movementFilters.taxMovementOnly"
                  type="checkbox"
                  class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                <span>{{ t('producedBeer.movement.filters.taxMovementOnly') }}</span>
              </label>
            </div>
            <div class="md:col-span-3 flex items-end">
              <label class="flex min-h-[40px] items-center gap-2 text-sm text-gray-700">
                <input
                  v-model="movementFilters.showReversedMovements"
                  type="checkbox"
                  class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
                />
                <span>{{ t('producedBeer.movement.filters.showReversedMovements') }}</span>
              </label>
            </div>
          </form>
        </section>

        <div
          v-if="selectedMovementCards.length > 0"
          class="ml-auto flex w-fit flex-wrap items-center justify-end gap-2 rounded-lg border border-red-100 bg-red-50 px-3 py-2 text-sm"
        >
          <span class="text-red-900">
            {{ t('producedBeer.movement.bulk.selected', { count: selectedMovementCards.length }) }}
          </span>
          <button
            class="rounded border border-red-200 bg-white px-3 py-1.5 text-red-700 hover:bg-red-50 disabled:opacity-50"
            type="button"
            :disabled="movementBulkProcessing"
            @click="clearMovementSelection"
          >
            {{ t('producedBeer.movement.bulk.clearSelection') }}
          </button>
          <button
            class="rounded bg-red-600 px-3 py-1.5 text-white hover:bg-red-700 disabled:opacity-50"
            type="button"
            :disabled="movementBulkProcessing || reversibleSelectedMovementCards.length === 0"
            @click="reverseSelectedMovements"
          >
            {{
              movementBulkProcessing
                ? t('common.saving')
                : t('producedBeer.movement.bulk.reverse')
            }}
          </button>
        </div>

        <section class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="compact-table min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-xs uppercase text-gray-600">
              <tr>
                <th class="w-10 px-2 py-1.5 text-center">
                  <input
                    class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 disabled:opacity-40"
                    type="checkbox"
                    :checked="allVisibleMovementCardsSelected"
                    :disabled="visibleMovementCards.length === 0 || movementLoading || movementBulkProcessing"
                    :aria-label="t('producedBeer.movement.bulk.selectVisible')"
                    @change="toggleVisibleMovementSelection"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.movementAt"
                    :active-sort-key="movementSortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('producedBeer.movement.card.movementDate')"
                    sort-key="movementAt"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.batchCode"
                    :active-sort-key="movementSortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('producedBeer.movement.card.batchCode')"
                    sort-key="batchCode"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.beerCategory"
                    :active-sort-key="movementSortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('producedBeer.inventory.table.beerCategory')"
                    sort-key="beerCategory"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.styleName"
                    :active-sort-key="movementSortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('producedBeer.inventory.table.styleName')"
                    sort-key="styleName"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-right">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.targetAbv"
                    align="right"
                    :active-sort-key="movementSortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('producedBeer.inventory.table.targetAbv')"
                    sort-key="targetAbv"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.packageType"
                    :active-sort-key="movementSortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('producedBeer.movement.card.linePackageType')"
                    sort-key="packageType"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-right">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.volumePerPackage"
                    align="right"
                    :active-sort-key="movementSortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('producedBeer.movement.card.volumePerPackage')"
                    sort-key="volumePerPackage"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-right">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.unitOfPackage"
                    align="right"
                    :active-sort-key="movementSortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('producedBeer.movement.card.unitOfPackage')"
                    sort-key="unitOfPackage"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-right">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.totalVolume"
                    align="right"
                    :active-sort-key="movementSortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('producedBeer.movement.card.totalVolume')"
                    sort-key="totalVolume"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-right">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.taxRate"
                    align="right"
                    :active-sort-key="movementSortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('producedBeer.movement.card.taxRate')"
                    sort-key="taxRate"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.source"
                    :active-sort-key="movementSortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('producedBeer.movement.card.source')"
                    sort-key="source"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.destination"
                    :active-sort-key="movementSortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('producedBeer.movement.card.destination')"
                    sort-key="destination"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.docNo"
                    :active-sort-key="movementSortKey"
                    :filter-placeholder="t('common.search')"
                    :label="t('producedBeer.movement.card.docNo')"
                    sort-key="docNo"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="px-3 py-2 text-left">
                  <TableColumnHeader
                    v-model:filter-value="movementColumnFilters.taxEvent"
                    :active-sort-key="movementSortKey"
                    :all-label="t('common.all')"
                    :filter-options="movementTaxEventColumnFilterOptions"
                    filter-type="select"
                    :label="t('producedBeer.movement.filters.movementType')"
                    sort-key="taxEvent"
                    :sort-direction="movementSortDirection"
                    @sort="setMovementColumnSort"
                  />
                </th>
                <th class="w-10 px-2 py-1.5 text-center">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="card in visibleMovementCards" :key="card.id" class="hover:bg-gray-50">
                <td class="px-2 py-1.5 text-center">
                  <input
                    class="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500 disabled:opacity-40"
                    type="checkbox"
                    :checked="selectedMovementCardIdSet.has(card.id)"
                    :disabled="movementLoading || movementBulkProcessing"
                    :aria-label="t('producedBeer.movement.bulk.selectRow')"
                    @change="toggleMovementSelection(card)"
                  />
                </td>
                <td class="px-3 py-2 text-xs text-gray-500">
                  {{ formatDateTime(card.movementAt) }}
                </td>
                <CompactTableCell
                  :value="movementBatchCodeLabel(card)"
                  text-column="batchCode"
                  truncate
                  monospace
                  focusable
                />
                <CompactTableCell
                  :value="movementBeerCategoryLabel(card)"
                  text-column="beerCategory"
                  truncate
                  focusable
                />
                <CompactTableCell
                  :value="movementStyleLabel(card)"
                  text-column="styleName"
                  truncate
                  focusable
                />
                <td class="px-3 py-2 text-right text-gray-600">
                  {{ movementTargetAbvLabel(card) }}
                </td>
                <CompactTableCell
                  :value="movementPackageLabel(card)"
                  text-column="packageType"
                  truncate
                  focusable
                />
                <td class="px-3 py-2 text-right text-gray-600">
                  {{ movementVolumeLabel(card) }}
                </td>
                <td class="px-3 py-2 text-right text-gray-600">
                  {{ movementUnitOfPackageLabel(card) }}
                </td>
                <td class="px-3 py-2 text-right font-semibold text-gray-900">
                  {{ formatVolumeNumberValue(card.totalLiters) }}
                </td>
                <td class="px-3 py-2 text-right text-gray-600">{{ movementTaxRateLabel(card) }}</td>
                <CompactTableCell
                  :value="siteLabel(card.sourceSiteId)"
                  text-column="source"
                  truncate
                  focusable
                />
                <CompactTableCell
                  :value="siteLabel(card.destSiteId)"
                  text-column="destination"
                  truncate
                  focusable
                />
                <CompactTableCell
                  :value="movementDocumentNoLabel(card.docNo)"
                  :title="card.docNo || ''"
                  text-column="batchCode"
                  truncate
                  focusable
                />
                <CompactTableCell
                  :value="movementTypeLabel(card.taxEvent)"
                  text-column="removalType"
                  truncate
                  focusable
                />
                <td class="px-2 py-1.5 text-center">
                  <button
                    class="inline-flex h-8 w-8 items-center justify-center rounded border border-red-200 bg-white text-red-700 hover:bg-red-50 disabled:border-gray-200 disabled:text-gray-400 disabled:opacity-60 disabled:hover:bg-white"
                    :disabled="movementLoading || movementBulkProcessing || card.status === 'void'"
                    :aria-label="
                      card.status === 'void'
                        ? t('producedBeer.movement.actions.reversed')
                        : t('producedBeer.movement.actions.reverse')
                    "
                    :title="
                      card.status === 'void'
                        ? t('producedBeer.movement.actions.reversed')
                        : t('producedBeer.movement.actions.reverse')
                    "
                    @click="reverseMovement(card)"
                  >
                    <svg class="h-4 w-4" viewBox="0 0 20 20" aria-hidden="true" fill="none">
                      <path
                        d="M6.3 6.8A5 5 0 1 1 5 10.2"
                        stroke="currentColor"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.8"
                      />
                      <path
                        d="M6.4 3.8v3.1h3.1"
                        stroke="currentColor"
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="1.8"
                      />
                    </svg>
                  </button>
                </td>
              </tr>
              <tr v-if="!movementLoading && visibleMovementCards.length === 0">
                <td colspan="16" class="px-3 py-8 text-center text-gray-500">
                  {{ t('common.noData') }}
                </td>
              </tr>
            </tbody>
          </table>
        </section>
      </section>
    </div>

    <ConfirmActionDialog
      :open="confirmDialog.open"
      :title="confirmDialog.title"
      :message="confirmDialog.message"
      :confirm-label="confirmDialog.confirmLabel"
      :cancel-label="confirmDialog.cancelLabel"
      :tone="confirmDialog.tone"
      @cancel="cancelConfirmation"
      @confirm="acceptConfirmation"
    />
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import AppDateTimePicker from '@/components/common/AppDateTimePicker.vue'
import ConfirmActionDialog from '@/components/common/ConfirmActionDialog.vue'
import TableColumnHeader from '@/components/common/TableColumnHeader.vue'
import {
  buildAlcoholTypeLabelMap,
  loadAlcoholTypeReferenceData,
  resolveAlcoholTypeLabel,
} from '@/lib/alcoholTypeRegistry'
import {
  resolveBatchBeerCategoryId,
  resolveBatchDisplayName,
  resolveBatchStyleName,
  resolveBatchTargetAbv,
  type BatchRecipeSource,
} from '@/lib/batchRecipeSnapshot'
import { useConfirmDialog } from '@/composables/useConfirmDialog'
import { useColumnTableControls, type ColumnSortDirection } from '@/composables/useColumnTableControls'
import { useRuleengineLabels } from '@/composables/useRuleengineLabels'
import { createWorkbookBlob, type WorkbookCell, type WorkbookSheet } from '@/lib/fillingReportExport'
import { extractErrorMessage, formatRpcErrorMessage } from '@/lib/rpcErrors'
import { supabase } from '@/lib/supabase'
import { formatAbvPercent } from '@/lib/abvFormat'
import {
  formatTotalVolumeFromLiters,
  formatUnitVolumeFromLiters,
  millilitersToLiters,
  quantityToMilliliters,
} from '@/lib/volumeFormat'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import CompactTableCell from '@/components/common/CompactTableCell.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

interface CategoryRow {
  def_id: string
  def_key: string
  spec: Record<string, unknown>
}

interface SiteOption {
  value: string
  label: string
}

interface PackageCategoryRow {
  id: string
  package_code: string
  name_i18n: Record<string, string> | null
  unit_volume: number | null
  volume_uom: string | null
}

interface MovementHeader {
  id: string
  doc_no: string
  doc_type: string
  movement_at: string | null
  status: string
  src_site_id: string | null
  dest_site_id: string | null
  notes: string | null
  meta?: Record<string, unknown> | null
}

interface MovementLineRow {
  id: string
  movement_id: string
  package_id: string | null
  batch_id: string | null
  qty: number | null
  unit: number | null
  tax_rate: number | null
  uom_id: string | null
  meta?: Record<string, unknown> | null
}

type AttrDefRow = {
  attr_id: unknown
  code: unknown
}

type EntityAttrRow = {
  entity_id: unknown
  attr_id: unknown
  value_text: unknown
  value_num: unknown
  value_ref_type_id: unknown
  value_json: unknown
}

type MesBatchRow = BatchRecipeSource & {
  id: string
}

interface PackageInfo {
  id: string
  batchId: string | null
  batchCode: string | null
  beerName: string | null
  packageTypeId: string | null
  packageTypeLabel: string | null
  unitSizeLiters: number | null
  productionDate: string | null
}

interface MovementLineCard {
  id: string
  packageId: string | null
  batchCode: string | null
  beerName: string | null
  categoryId: string | null
  styleName: string | null
  targetAbv: number | null
  packageTypeId: string | null
  packageTypeLabel: string | null
  packageQty: number | null
  unitOfPackage: number | null
  taxRate: number | null
  qtyLiters: number | null
}

interface MovementCard {
  id: string
  docNo: string
  docType: string
  taxType: string | null
  taxEvent: string | null
  movementAt: string | null
  status: string
  sourceSiteId: string | null
  destSiteId: string | null
  lines: MovementLineCard[]
}

interface MovementCardView extends MovementCard {
  totalPackages: number | null
  totalLiters: number | null
}

const MOVEMENT_SEARCH_STATE_STORAGE_KEY = 'beeradmin.producedBeer.movements.searchState.v1'
const MOVEMENT_TYPE_FILTER_VALUES = [
  'all',
  'TAXABLE_REMOVAL',
  'NON_TAXABLE_REMOVAL',
  'EXPORT_EXEMPT',
  'RETURN_TO_FACTORY',
] as const
const MOVEMENT_TABLE_SORT_KEYS = [
  'movementAt',
  'batchCode',
  'beerCategory',
  'styleName',
  'targetAbv',
  'packageType',
  'volumePerPackage',
  'unitOfPackage',
  'totalVolume',
  'taxRate',
  'source',
  'destination',
  'docNo',
  'taxEvent',
] as const
const DEFAULT_MOVEMENT_TYPE_FILTER = 'all'

type MovementTypeFilter = typeof MOVEMENT_TYPE_FILTER_VALUES[number]
type MovementTableSortKey = typeof MOVEMENT_TABLE_SORT_KEYS[number]

interface MovementFiltersState {
  beerName: string
  category: string
  packageType: string
  batchNo: string
  dateFrom: string
  dateTo: string
  taxMovementOnly: boolean
  showReversedMovements: boolean
}

interface StoredMovementSearchState {
  filters?: Partial<MovementFiltersState>
  movementType?: MovementTypeFilter
  columnFilters?: Partial<Record<MovementTableSortKey, string>>
  sortKey?: MovementTableSortKey
  sortDirection?: ColumnSortDirection
}

const { t, locale } = useI18n()
const router = useRouter()
const { confirmDialog, requestConfirmation, cancelConfirmation, acceptConfirmation } = useConfirmDialog()
const { enumValues, loadRuleengineLabels, ruleLabel } = useRuleengineLabels()
const pageTitle = computed(() => t('producedBeer.title'))

const tenantId = ref<string | null>(null)
const movementLoading = ref(false)
const exportLoading = ref(false)
const movementBulkProcessing = ref(false)

const categories = ref<CategoryRow[]>([])
const packageCategories = ref<PackageCategoryRow[]>([])
const uoms = ref<Array<{ id: string; code: string | null }>>([])
const siteOptions = ref<SiteOption[]>([])

const movementCards = ref<MovementCard[]>([])
const selectedMovementCardIds = ref<string[]>([])
const defaultMovementDateFrom = oneMonthAgoDateInput()
const rememberedMovementSearchState = readStoredMovementSearchState()
const movementFilters = reactive<MovementFiltersState>({
  ...defaultMovementFilters(),
  ...rememberedMovementSearchState.filters,
})

const movementTypeFilter = ref<MovementTypeFilter>(
  rememberedMovementSearchState.movementType ?? DEFAULT_MOVEMENT_TYPE_FILTER,
)

const taxEventFilterOptions = computed(() => {
  const allowed = ['TAXABLE_REMOVAL', 'NON_TAXABLE_REMOVAL', 'EXPORT_EXEMPT', 'RETURN_TO_FACTORY']
  const codes = enumValues('tax_event').filter((code) => allowed.includes(code))
  const values = codes.length ? codes : allowed
  return values.map((code) => ({ value: code, label: taxEventLabel(code) }))
})

const siteMap = computed(() => {
  const map = new Map<string, SiteOption>()
  siteOptions.value.forEach((item) => map.set(item.value, item))
  return map
})

const packageCategoryMap = computed(() => {
  const map = new Map<string, { label: string; size: number | null; uomId: string | null }>()
  packageCategories.value.forEach((row) => {
    map.set(row.id, {
      label: resolvePackageName(row),
      size: row.unit_volume ?? null,
      uomId: row.volume_uom ?? null,
    })
  })
  return map
})

const categoryLabelMap = computed(() => buildAlcoholTypeLabelMap(categories.value))

const uomMap = computed(() => {
  const map = new Map<string, string>()
  uoms.value.forEach((row) => map.set(row.id, row.code ?? ''))
  return map
})

const packageCategoryOptions = computed(() =>
  packageCategories.value.map((row) => ({
    value: row.id,
    label: resolvePackageName(row),
  })),
)

const filteredMovementCards = computed<MovementCardView[]>(() => {
  const nameFilter = movementFilters.beerName.trim().toLowerCase()
  const batchFilter = movementFilters.batchNo.trim().toLowerCase()

  return movementCards.value.reduce<MovementCardView[]>((acc, card) => {
    const filteredLines = card.lines.filter((line) => {
      if (nameFilter && !(line.beerName || '').toLowerCase().includes(nameFilter)) return false
      if (movementFilters.category && line.categoryId !== movementFilters.category) return false
      if (movementFilters.packageType && line.packageTypeId !== movementFilters.packageType)
        return false
      if (batchFilter && !(line.batchCode || '').toLowerCase().includes(batchFilter)) return false
      return true
    })

    if (filteredLines.length === 0) return acc

    const totalPackages = filteredLines.reduce((sum, line) => sum + (line.packageQty ?? 0), 0)
    const totalLiters = filteredLines.reduce((sum, line) => sum + (line.qtyLiters ?? 0), 0)

    acc.push({
      ...card,
      lines: filteredLines,
      totalPackages,
      totalLiters,
    })
    return acc
  }, [])
})

const {
  sortKey: movementSortKey,
  sortDirection: movementSortDirection,
  columnFilters: movementColumnFilters,
  sortedRows: visibleMovementCards,
  hasColumnFilters: hasMovementColumnFilters,
  setSort: setMovementSort,
  clearColumnFilters: clearMovementColumnFilters,
} = useColumnTableControls<MovementCardView, MovementTableSortKey>(
  filteredMovementCards,
  [
    { key: 'movementAt', sortValue: (card) => (card.movementAt ? Date.parse(card.movementAt) : null), filterValue: (card) => formatDateTime(card.movementAt), filterType: 'text' },
    { key: 'batchCode', sortValue: (card) => movementBatchCodeLabel(card), filterType: 'text' },
    { key: 'beerCategory', sortValue: (card) => movementBeerCategoryLabel(card), filterType: 'text' },
    { key: 'styleName', sortValue: (card) => movementStyleLabel(card), filterType: 'text' },
    { key: 'targetAbv', sortValue: (card) => movementTargetAbvSortValue(card), filterValue: (card) => movementTargetAbvLabel(card), filterType: 'text' },
    { key: 'packageType', sortValue: (card) => movementPackageLabel(card), filterType: 'text' },
    { key: 'volumePerPackage', sortValue: (card) => movementVolumeLabel(card), filterType: 'text' },
    { key: 'unitOfPackage', sortValue: (card) => movementUnitOfPackageSortValue(card), filterValue: (card) => movementUnitOfPackageLabel(card), filterType: 'text' },
    { key: 'totalVolume', sortValue: (card) => card.totalLiters, filterValue: (card) => formatVolumeNumberValue(card.totalLiters), filterType: 'text' },
    { key: 'taxRate', sortValue: (card) => movementTaxRateSortValue(card), filterValue: (card) => movementTaxRateLabel(card), filterType: 'text' },
    { key: 'source', sortValue: (card) => siteLabel(card.sourceSiteId), filterType: 'text' },
    { key: 'destination', sortValue: (card) => siteLabel(card.destSiteId), filterType: 'text' },
    { key: 'docNo', sortValue: (card) => card.docNo, filterType: 'text' },
    { key: 'taxEvent', sortValue: (card) => movementTypeLabel(card.taxEvent), filterValue: (card) => card.taxEvent, filterType: 'select' },
  ],
  'movementAt',
  'desc',
)
applyStoredMovementTableState(rememberedMovementSearchState)

const movementTaxEventColumnFilterOptions = computed(() => {
  const options = taxEventFilterOptions.value.map((option) => ({
    value: option.value,
    label: option.label,
  }))
  if (movementCards.value.some((card) => card.taxEvent === 'NONE')) {
    options.push({ value: 'NONE', label: '—' })
  }
  return options
})

const selectedMovementCardIdSet = computed(() => new Set(selectedMovementCardIds.value))
const selectedMovementCards = computed(() =>
  visibleMovementCards.value.filter((card) => selectedMovementCardIdSet.value.has(card.id)),
)
const reversibleSelectedMovementCards = computed(() =>
  selectedMovementCards.value.filter((card) => card.status !== 'void'),
)
const allVisibleMovementCardsSelected = computed(() => {
  if (visibleMovementCards.value.length === 0) return false
  return visibleMovementCards.value.every((card) => selectedMovementCardIdSet.value.has(card.id))
})

function setMovementColumnSort(key: string, direction?: ColumnSortDirection) {
  setMovementSort(key as MovementTableSortKey, direction)
}

const numberFormatter = computed(
  () => new Intl.NumberFormat(locale.value, { maximumFractionDigits: 2 }),
)

function formatNumber(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return numberFormatter.value.format(value)
}

function oneMonthAgoDateInput() {
  const date = new Date()
  date.setMonth(date.getMonth() - 1)
  return formatDateInput(date)
}

function formatDateInput(date: Date) {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

function defaultMovementFilters(): MovementFiltersState {
  return {
    beerName: '',
    category: '',
    packageType: '',
    batchNo: '',
    dateFrom: defaultMovementDateFrom,
    dateTo: '',
    taxMovementOnly: true,
    showReversedMovements: false,
  }
}

function readStoredMovementSearchState(): StoredMovementSearchState {
  if (typeof window === 'undefined') return {}
  try {
    const raw = window.localStorage.getItem(MOVEMENT_SEARCH_STATE_STORAGE_KEY)
    if (!raw) return {}
    const parsed = JSON.parse(raw)
    if (!isPlainRecord(parsed)) return {}
    const rawFilters = isPlainRecord(parsed.filters) ? parsed.filters : {}
    const rawColumnFilters = isPlainRecord(parsed.columnFilters) ? parsed.columnFilters : {}
    const columnFilters = MOVEMENT_TABLE_SORT_KEYS.reduce<Partial<Record<MovementTableSortKey, string>>>(
      (result, key) => {
        const value = storedString(rawColumnFilters[key])
        if (value) result[key] = value
        return result
      },
      {},
    )

    return {
      filters: {
        beerName: storedString(rawFilters.beerName),
        category: storedString(rawFilters.category),
        packageType: storedString(rawFilters.packageType),
        batchNo: storedString(rawFilters.batchNo),
        dateFrom: storedString(rawFilters.dateFrom, defaultMovementDateFrom),
        dateTo: storedString(rawFilters.dateTo),
        taxMovementOnly: storedBoolean(rawFilters.taxMovementOnly, true),
        showReversedMovements: storedBoolean(rawFilters.showReversedMovements, false),
      },
      movementType: isMovementTypeFilter(parsed.movementType)
        ? parsed.movementType
        : DEFAULT_MOVEMENT_TYPE_FILTER,
      columnFilters,
      sortKey: isMovementTableSortKey(parsed.sortKey) ? parsed.sortKey : undefined,
      sortDirection: isColumnSortDirection(parsed.sortDirection) ? parsed.sortDirection : undefined,
    }
  } catch (error) {
    console.warn('Failed to read movement search state', error)
    return {}
  }
}

function applyStoredMovementTableState(state: StoredMovementSearchState) {
  Object.entries(state.columnFilters ?? {}).forEach(([key, value]) => {
    if (isMovementTableSortKey(key)) movementColumnFilters[key] = value
  })
  if (state.sortKey) setMovementSort(state.sortKey, state.sortDirection ?? 'desc')
}

function rememberMovementSearchState() {
  if (typeof window === 'undefined') return
  try {
    window.localStorage.setItem(
      MOVEMENT_SEARCH_STATE_STORAGE_KEY,
      JSON.stringify(movementSearchStatePayload()),
    )
  } catch (error) {
    console.warn('Failed to remember movement search state', error)
  }
}

function movementSearchStatePayload(): StoredMovementSearchState {
  return {
    filters: { ...movementFilters },
    movementType: movementTypeFilter.value,
    columnFilters: MOVEMENT_TABLE_SORT_KEYS.reduce<Partial<Record<MovementTableSortKey, string>>>(
      (result, key) => {
        const value = movementColumnFilters[key]?.trim()
        if (value) result[key] = value
        return result
      },
      {},
    ),
    sortKey: movementSortKey.value,
    sortDirection: movementSortDirection.value,
  }
}

function storedString(value: unknown, fallback = '') {
  return typeof value === 'string' ? value : fallback
}

function storedBoolean(value: unknown, fallback: boolean) {
  return typeof value === 'boolean' ? value : fallback
}

function isPlainRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
}

function isMovementTypeFilter(value: unknown): value is MovementTypeFilter {
  return typeof value === 'string' && MOVEMENT_TYPE_FILTER_VALUES.includes(value as MovementTypeFilter)
}

function isMovementTableSortKey(value: unknown): value is MovementTableSortKey {
  return typeof value === 'string' && MOVEMENT_TABLE_SORT_KEYS.includes(value as MovementTableSortKey)
}

function isColumnSortDirection(value: unknown): value is ColumnSortDirection {
  return value === 'asc' || value === 'desc'
}

function formatVolumeNumberValue(value: number | null | undefined) {
  return formatTotalVolumeFromLiters(value, locale.value)
}

function formatAbv(value: number | null | undefined) {
  return formatAbvPercent(value, locale.value)
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
  } catch {
    return value
  }
}

function resolveLang() {
  return String(locale.value ?? '')
    .toLowerCase()
    .startsWith('ja')
    ? 'ja'
    : 'en'
}

function resolvePackageName(row: PackageCategoryRow) {
  const lang = resolveLang()
  const name = row.name_i18n?.[lang] ?? Object.values(row.name_i18n ?? {})[0]
  return name || row.package_code
}

function siteLabel(siteId: string | null | undefined) {
  if (!siteId) return '—'
  return siteMap.value.get(siteId)?.label ?? '—'
}

function legacyMovementTaxEvent(docType: string, taxType: string | null) {
  if (docType === 'sale' && taxType === 'tax') return 'TAXABLE_REMOVAL'
  if (docType === 'sale' && taxType === 'notax') return 'NON_TAXABLE_REMOVAL'
  if (docType === 'return' && taxType === 'notax') return 'RETURN_TO_FACTORY'
  if (docType === 'waste' && taxType === 'notax') return 'NON_TAXABLE_REMOVAL'
  if (docType === 'transfer' && taxType === 'notax') return 'NON_TAXABLE_REMOVAL'
  if (docType === 'tax_transfer') return 'EXPORT_EXEMPT'
  return null
}

function resolveHeaderTaxType(header: MovementHeader) {
  return typeof header.meta?.tax_type === 'string' ? header.meta.tax_type : null
}

function resolveHeaderTaxEvent(header: MovementHeader) {
  const taxType = resolveHeaderTaxType(header)
  return typeof header.meta?.tax_event === 'string' && header.meta.tax_event.trim()
    ? header.meta.tax_event.trim()
    : legacyMovementTaxEvent(header.doc_type, taxType)
}

function movementTypeLabel(taxEvent: string | null | undefined) {
  const normalized = (taxEvent ?? '').trim()
  if (!normalized.length) return '—'
  if (normalized === 'NONE') return '—'
  return ruleLabel('tax_event', normalized)
}

function taxEventLabel(taxEvent: string | null | undefined) {
  const normalized = (taxEvent ?? '').trim()
  if (!normalized.length) return '—'
  return ruleLabel('tax_event', normalized)
}

function clearMovementSelection() {
  selectedMovementCardIds.value = []
}

function toggleMovementSelection(card: MovementCardView) {
  if (movementLoading.value || movementBulkProcessing.value) return
  const selected = new Set(selectedMovementCardIds.value)
  if (selected.has(card.id)) selected.delete(card.id)
  else selected.add(card.id)
  selectedMovementCardIds.value = Array.from(selected)
}

function toggleVisibleMovementSelection() {
  if (movementLoading.value || movementBulkProcessing.value) return
  const selected = new Set(selectedMovementCardIds.value)
  if (allVisibleMovementCardsSelected.value) {
    visibleMovementCards.value.forEach((card) => selected.delete(card.id))
  } else {
    visibleMovementCards.value.forEach((card) => selected.add(card.id))
  }
  selectedMovementCardIds.value = Array.from(selected)
}

function uniqueNonEmpty(values: Array<string | null | undefined>) {
  return Array.from(
    new Set(values.map((value) => (value ?? '').trim()).filter((value) => value.length > 0)),
  )
}

function uniqueNumbers(values: Array<number | null | undefined>, precision = 6) {
  const map = new Map<string, number>()
  values.forEach((value) => {
    if (value == null || Number.isNaN(value)) return
    const normalized = Number(value.toFixed(precision))
    map.set(String(normalized), normalized)
  })
  return Array.from(map.values())
}

function movementStyleLabel(card: MovementCardView) {
  const styles = uniqueNonEmpty(card.lines.map((line) => line.styleName))
  return styles.length ? styles.join(', ') : '—'
}

function movementBatchCodeLabel(card: MovementCardView) {
  const batchCodes = uniqueNonEmpty(card.lines.map((line) => line.batchCode))
  return batchCodes.length ? batchCodes.join(', ') : '—'
}

function categoryLabel(categoryId: string | null | undefined) {
  if (!categoryId) return null
  return resolveAlcoholTypeLabel(categoryLabelMap.value, categoryId) ?? categoryId
}

function movementBeerCategoryLabel(card: MovementCardView) {
  const labels = uniqueNonEmpty(card.lines.map((line) => categoryLabel(line.categoryId)))
  return labels.length ? labels.join(', ') : '—'
}

function movementTargetAbvLabel(card: MovementCardView) {
  const abvs = uniqueNumbers(card.lines.map((line) => line.targetAbv))
  if (!abvs.length) return '—'
  return abvs.map((value) => formatAbv(value)).join(', ')
}

function movementTargetAbvSortValue(card: MovementCardView) {
  return uniqueNumbers(card.lines.map((line) => line.targetAbv))[0] ?? null
}

function movementPackageLabel(card: MovementCardView) {
  const packages = uniqueNonEmpty(card.lines.map((line) => line.packageTypeLabel))
  return packages.length ? packages.join(', ') : '—'
}

function packageVolumePerPackageLabel(packageTypeId: string | null | undefined) {
  if (!packageTypeId) return null
  const pkg = packageCategoryMap.value.get(packageTypeId)
  if (pkg?.size == null || Number.isNaN(pkg.size)) return null
  const qty = Number(pkg.size)
  const uomCode = pkg.uomId ? uomMap.value.get(pkg.uomId) ?? pkg.uomId : null
  const liters = Number.isFinite(qty) ? convertToLiters(qty, uomCode) : null
  return liters != null ? formatUnitVolumeFromLiters(liters, locale.value) : String(pkg.size)
}

function movementVolumeLabel(card: MovementCardView) {
  const packageVolumes = uniqueNonEmpty(
    card.lines.map((line) => packageVolumePerPackageLabel(line.packageTypeId)),
  )
  return packageVolumes.length ? packageVolumes.join(', ') : '—'
}

function movementUnitOfPackageLabel(card: MovementCardView) {
  const units = uniqueNumbers(card.lines.map((line) => line.unitOfPackage))
  if (!units.length) return '—'
  return units.map((value) => formatNumber(value)).join(', ')
}

function movementUnitOfPackageSortValue(card: MovementCardView) {
  return uniqueNumbers(card.lines.map((line) => line.unitOfPackage))[0] ?? null
}

function movementTaxRateLabel(card: MovementCardView) {
  const taxRates = uniqueNumbers(card.lines.map((line) => line.taxRate ?? NaN))
  if (taxRates.length) return taxRates.map((value) => `${formatNumber(value)}/kl`).join(', ')
  if (card.taxEvent && card.taxEvent !== 'TAXABLE_REMOVAL') return '0/kl'
  if (card.taxType === 'notax') return '0/kl'
  return '—'
}

function movementTaxRateSortValue(card: MovementCardView) {
  const taxRates = uniqueNumbers(card.lines.map((line) => line.taxRate ?? NaN))
  if (taxRates.length) return taxRates[0] ?? null
  if (card.taxEvent && card.taxEvent !== 'TAXABLE_REMOVAL') return 0
  if (card.taxType === 'notax') return 0
  return null
}

function movementDocumentNoLabel(docNo: string) {
  return docNo.length > 15 ? `${docNo.slice(0, 15)}....` : docNo
}

function borderedRow(values: Array<string | number | null | undefined>, style: 'border' | 'header' = 'border'): WorkbookCell[] {
  return values.map((value) => ({
    style,
    value,
  }))
}

function buildMovementExportSheet(): WorkbookSheet {
  const header = borderedRow([
    t('producedBeer.movement.card.movementDate'),
    t('producedBeer.movement.card.batchCode'),
    t('producedBeer.inventory.table.beerCategory'),
    t('producedBeer.inventory.table.styleName'),
    t('producedBeer.inventory.table.targetAbv'),
    t('producedBeer.movement.card.linePackageType'),
    t('producedBeer.movement.card.volumePerPackage'),
    t('producedBeer.movement.card.unitOfPackage'),
    t('producedBeer.movement.card.totalVolume'),
    t('producedBeer.movement.card.taxRate'),
    t('producedBeer.movement.card.source'),
    t('producedBeer.movement.card.destination'),
    t('producedBeer.movement.card.docNo'),
    t('producedBeer.movement.filters.movementType'),
  ], 'header')

  const rows = visibleMovementCards.value.map((card) =>
    borderedRow([
      formatDateTime(card.movementAt),
      movementBatchCodeLabel(card),
      movementBeerCategoryLabel(card),
      movementStyleLabel(card),
      movementTargetAbvLabel(card),
      movementPackageLabel(card),
      movementVolumeLabel(card),
      movementUnitOfPackageLabel(card),
      formatVolumeNumberValue(card.totalLiters),
      movementTaxRateLabel(card),
      siteLabel(card.sourceSiteId),
      siteLabel(card.destSiteId),
      card.docNo,
      movementTypeLabel(card.taxEvent),
    ]),
  )

  return {
    name: t('producedBeer.sections.movements'),
    rows: [header, ...rows],
  }
}

function exportMovementsExcel() {
  if (!visibleMovementCards.value.length) {
    toast.error(t('producedBeer.movement.export.noData'))
    return
  }

  try {
    exportLoading.value = true
    const createdAt = new Date()
    const blob = createWorkbookBlob({
      creator: 'beeradmin_tail',
      createdAtIso: createdAt.toISOString(),
      sheets: [buildMovementExportSheet()],
    })
    const dateStamp = createdAt.toISOString().slice(0, 10).replace(/-/g, '')
    const fileName = `movements-${dateStamp}.xlsx`
    downloadBlob(blob, fileName)
  } catch (err) {
    toast.error(extractErrorMessage(err) || t('producedBeer.movement.export.failed'))
  } finally {
    exportLoading.value = false
  }
}

function downloadBlob(blob: Blob, fileName: string) {
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = fileName
  link.click()
  URL.revokeObjectURL(url)
}

function matchesMovementType(header: MovementHeader) {
  const taxEvent = resolveHeaderTaxEvent(header)
  if (movementFilters.taxMovementOnly && (!taxEvent || taxEvent === 'NONE')) return false
  if (movementTypeFilter.value === 'all') return true
  return taxEvent === movementTypeFilter.value
}

function toNumber(value: unknown): number | null {
  if (value == null) return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function asRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === 'object' && value !== null && !Array.isArray(value) ? value as Record<string, unknown> : null
}

function convertToLiters(size: number | null, uomCode: string | null | undefined) {
  return millilitersToLiters(quantityToMilliliters(size, uomCode))
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved in session')
  tenantId.value = id
  return id
}

async function loadCategories() {
  const { optionRows } = await loadAlcoholTypeReferenceData(supabase)
  categories.value = optionRows as CategoryRow[]
}

async function loadPackageCategories() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_package')
    .select('id, package_code, name_i18n, unit_volume, volume_uom, is_active')
    .eq('tenant_id', tenant)
    .eq('is_active', true)
    .order('package_code', { ascending: true })
  if (error) throw error
  packageCategories.value = data ?? []
}

async function loadUoms() {
  const { data, error } = await supabase
    .from('mst_uom')
    .select('id, code')
    .order('code', { ascending: true })
  if (error) throw error
  uoms.value = data ?? []
}

async function loadSites() {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from('mst_sites')
    .select('id, name')
    .eq('tenant_id', tenant)
    .order('name', { ascending: true })
  if (error) throw error
  siteOptions.value = (data ?? []).map((row) => ({ value: row.id, label: row.name ?? row.id }))
}

async function fetchMovements() {
  try {
    movementLoading.value = true
    const tenant = await ensureTenant()
    let headerQuery = supabase
      .from('inv_movements')
      .select('id, doc_no, doc_type, movement_at, status, src_site_id, dest_site_id, notes, meta')
      .eq('tenant_id', tenant)
      .order('movement_at', { ascending: false })

    if (movementFilters.dateFrom)
      headerQuery = headerQuery.gte('movement_at', `${movementFilters.dateFrom}T00:00:00`)
    if (movementFilters.dateTo)
      headerQuery = headerQuery.lte('movement_at', `${movementFilters.dateTo}T23:59:59`)
    if (!movementFilters.showReversedMovements) headerQuery = headerQuery.neq('status', 'void')

    const { data: headers, error: headerError } = await headerQuery
    if (headerError) throw headerError

    const headerList = (headers ?? []) as MovementHeader[]
    const filteredHeaders = headerList.filter((row) => matchesMovementType(row))
    const headerMap = new Map(filteredHeaders.map((row) => [row.id, row]))
    const movementIds = filteredHeaders.map((row) => row.id)

    if (movementIds.length === 0) {
      movementCards.value = []
      return
    }

    const { data: lines, error: lineError } = await supabase
      .from('inv_movement_lines')
      .select('id, movement_id, package_id, batch_id, qty, unit, tax_rate, uom_id, meta')
      .in('movement_id', movementIds)
      .order('line_no', { ascending: true })

    if (lineError) throw lineError

    const lineList = (lines ?? []).filter((row) => row.package_id || row.batch_id) as MovementLineRow[]
    const packageIds = lineList.map((row) => row.package_id).filter(Boolean) as string[]
    const batchIds = lineList.map((row) => row.batch_id).filter(Boolean) as string[]

    const packageInfoMap = await loadPackageInfo(packageIds)
    const batchInfoMap = await loadBatchInfo(batchIds)

    const cardMap = new Map<string, MovementCard>()
    lineList.forEach((line) => {
      const header = headerMap.get(line.movement_id)
      if (!header) return
      if (!cardMap.has(line.movement_id)) {
        const taxType = resolveHeaderTaxType(header)
        const taxEvent = resolveHeaderTaxEvent(header)
        cardMap.set(line.movement_id, {
          id: line.movement_id,
          docNo: header.doc_no,
          docType: header.doc_type,
          taxType,
          taxEvent,
          movementAt: header.movement_at ?? null,
          status: header.status,
          sourceSiteId: header.src_site_id ?? null,
          destSiteId: header.dest_site_id ?? null,
          lines: [],
        })
      }

      const pkgInfo = line.package_id ? packageInfoMap.get(line.package_id) : undefined
      const batchInfo = line.batch_id ? batchInfoMap.get(line.batch_id) : undefined
      const packageQty = toNumber(line.meta?.package_qty)
      const qtyLiters =
        toNumber(line.qty) ??
        (packageQty && pkgInfo?.unitSizeLiters ? packageQty * pkgInfo.unitSizeLiters : null)

      const lineCard: MovementLineCard = {
        id: line.id,
        packageId: line.package_id ?? null,
        batchCode: pkgInfo?.batchCode ?? batchInfo?.batchCode ?? null,
        beerName: pkgInfo?.beerName ?? batchInfo?.beerName ?? null,
        categoryId: batchInfo?.beerCategoryId ?? null,
        styleName: batchInfo?.styleName ?? null,
        targetAbv: batchInfo?.targetAbv ?? null,
        packageTypeId: pkgInfo?.packageTypeId ?? null,
        packageTypeLabel: pkgInfo?.packageTypeLabel ?? null,
        packageQty,
        unitOfPackage: toNumber(line.unit),
        taxRate: toNumber(line.tax_rate),
        qtyLiters,
      }

      cardMap.get(line.movement_id)?.lines.push(lineCard)
    })

    movementCards.value = Array.from(cardMap.values()).sort((a, b) => {
      const aTime = a.movementAt ? Date.parse(a.movementAt) : 0
      const bTime = b.movementAt ? Date.parse(b.movementAt) : 0
      return bTime - aTime
    })
  } catch (err) {
    console.error(err)
    movementCards.value = []
    toast.error(formatRpcErrorMessage(err))
  } finally {
    movementLoading.value = false
  }
}

async function loadPackageInfo(packageIds: string[]) {
  const infoMap = new Map<string, PackageInfo>()
  if (packageIds.length === 0) return infoMap
  const uniqueIds = Array.from(new Set(packageIds))
  uniqueIds.forEach((id) => {
    const category = packageCategoryMap.value.get(id)
    const uomCode = category?.uomId ? uomMap.value.get(category.uomId) : null
    const unitSizeLiters = category?.size != null ? convertToLiters(category.size, uomCode) : null
    infoMap.set(id, {
      id,
      batchId: null,
      batchCode: null,
      beerName: null,
      packageTypeId: id,
      packageTypeLabel: category?.label ?? null,
      unitSizeLiters,
      productionDate: null,
    })
  })
  return infoMap
}

async function loadBatchInfo(batchIds: string[]) {
  const infoMap = new Map<
    string,
    {
      batchCode: string | null
      beerName: string | null
      beerCategoryId: string | null
      targetAbv: number | null
      styleName: string | null
    }
  >()
  if (batchIds.length === 0) return infoMap

  const tenant = await ensureTenant()
  const uniqueIds = Array.from(new Set(batchIds))

  const attrIdToCode = new Map<string, string>()
  const attrIds: number[] = []
  const attrValueByBatch = new Map<
    string,
    {
      beerCategoryId: string | null
      targetAbv: number | null
      styleName: string | null
    }
  >()

  try {
    const { data: attrDefs, error: attrDefError } = await supabase
      .from('attr_def')
      .select('attr_id, code')
      .eq('domain', 'batch')
      .in('code', ['beer_category', 'actual_abv', 'target_abv', 'style_name'])
      .eq('is_active', true)
    if (attrDefError) throw attrDefError
    ;((attrDefs ?? []) as AttrDefRow[]).forEach((row) => {
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
        .in('entity_id', uniqueIds)
        .in('attr_id', attrIds)
      if (attrValueError) throw attrValueError
      ;((attrValues ?? []) as EntityAttrRow[]).forEach((row) => {
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
          const jsonDefId = asRecord(row.value_json)?.def_id
          if (typeof jsonDefId === 'string' && jsonDefId.trim())
            entry.beerCategoryId = jsonDefId.trim()
          else if (typeof row.value_text === 'string' && row.value_text.trim())
            entry.beerCategoryId = row.value_text.trim()
          else if (row.value_ref_type_id != null)
            entry.beerCategoryId = String(row.value_ref_type_id)
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
          if (typeof row.value_text === 'string' && row.value_text.trim())
            entry.styleName = row.value_text.trim()
        }
      })
    }
  } catch (err) {
    console.warn('Failed to load batch attr values, fallback to recipe/meta only', err)
  }

  const { data, error } = await supabase
    .from('mes_batches')
    .select('id, batch_code, batch_label, product_name, meta, mes_recipe_id, released_reference_json, recipe_json')
    .eq('tenant_id', tenant)
    .in('id', uniqueIds)
  if (error) throw error
  ;((data ?? []) as MesBatchRow[]).forEach((row) => {
    const attr = attrValueByBatch.get(row.id)

    infoMap.set(row.id, {
      batchCode: row.batch_code ?? null,
      beerName: resolveBatchDisplayName(row),
      beerCategoryId: resolveBatchBeerCategoryId(row, attr),
      targetAbv: resolveBatchTargetAbv(row, attr),
      styleName: resolveBatchStyleName(row, attr),
    })
  })
  return infoMap
}

function resetMovementFilters() {
  Object.assign(movementFilters, defaultMovementFilters())
  movementTypeFilter.value = DEFAULT_MOVEMENT_TYPE_FILTER
  rememberMovementSearchState()
}

function openMovementCreate() {
  router.push({ path: '/producedBeerMovement' })
}

function openMovementCreateFast() {
  router.push({ path: '/producedBeerMovementFast' })
}

async function rollbackMovement(card: MovementCard) {
  const { error } = await supabase.rpc('product_move_rollback', {
    p_doc: {
      product_movement_id: card.id,
      doc_no: `PMR-${card.docNo || card.id}`,
      movement_at: new Date().toISOString(),
      reason: 'cancelled_from_movement_register',
      meta: {
        idempotency_key: `product_move_rollback:${card.id}`,
      },
    },
  })
  if (error) throw error
}

async function reverseMovement(card: MovementCard) {
  if (movementLoading.value || movementBulkProcessing.value || card.status === 'void') return

  const confirmed = await requestConfirmation({
    title: t('producedBeer.movement.actions.reverse'),
    message: t('producedBeer.movement.actions.reverseConfirm', { docNo: card.docNo }),
    confirmLabel: t('producedBeer.movement.actions.reverse'),
    tone: 'danger',
  })
  if (!confirmed) return

  try {
    movementLoading.value = true
    await rollbackMovement(card)

    toast.success(t('producedBeer.movement.actions.reverseSuccess'))
    selectedMovementCardIds.value = selectedMovementCardIds.value.filter((id) => id !== card.id)
    await fetchMovements()
  } catch (err) {
    console.error(err)
    toast.error(formatRpcErrorMessage(err, {
      fallbackKey: 'producedBeer.movement.errors.reverseFailed',
    }))
  } finally {
    movementLoading.value = false
  }
}

async function reverseSelectedMovements() {
  const selectedCount = selectedMovementCards.value.length
  const cards = reversibleSelectedMovementCards.value
  if (!selectedCount || !cards.length) return

  const confirmed = await requestConfirmation({
    title: t('producedBeer.movement.bulk.reverse'),
    message: t('producedBeer.movement.bulk.reverseConfirm', {
      selected: selectedCount,
      count: cards.length,
    }),
    confirmLabel: t('producedBeer.movement.bulk.reverse'),
    tone: 'danger',
  })
  if (!confirmed) return

  try {
    movementBulkProcessing.value = true
    for (const card of cards) {
      await rollbackMovement(card)
    }
    clearMovementSelection()
    await fetchMovements()
    toast.success(t('producedBeer.movement.bulk.reverseSuccess', { count: cards.length }))
  } catch (err) {
    console.error(err)
    toast.error(formatRpcErrorMessage(err, {
      fallbackKey: 'producedBeer.movement.bulk.reverseFailed',
    }))
  } finally {
    movementBulkProcessing.value = false
  }
}

watch(visibleMovementCards, (cards) => {
  const visibleIds = new Set(cards.map((card) => card.id))
  selectedMovementCardIds.value = selectedMovementCardIds.value.filter((id) => visibleIds.has(id))
})

watch(
  () => ({
    dateFrom: movementFilters.dateFrom,
    dateTo: movementFilters.dateTo,
    taxMovementOnly: movementFilters.taxMovementOnly,
    showReversedMovements: movementFilters.showReversedMovements,
    movementType: movementTypeFilter.value,
  }),
  async () => {
    await fetchMovements()
  },
)

watch(
  () => movementSearchStatePayload(),
  () => rememberMovementSearchState(),
  { deep: true, flush: 'post' },
)

onMounted(async () => {
  try {
    await ensureTenant()
    await Promise.all([
      loadSites(),
      loadCategories(),
      loadPackageCategories(),
      loadUoms(),
      loadRuleengineLabels({ tenantId: tenantId.value }),
    ])
    await fetchMovements()
  } catch (err) {
    console.error(err)
    toast.error(formatRpcErrorMessage(err))
  }
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}

.compact-table :is(th, td) {
  padding: 0.375rem 0.5rem;
}

.compact-table tbody tr {
  min-height: 2.25rem;
}
</style>
