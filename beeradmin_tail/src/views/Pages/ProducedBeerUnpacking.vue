<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 space-y-6">
      <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('producedBeerUnpacking.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('producedBeerUnpacking.subtitle') }}</p>
        </div>
        <button
          class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50"
          type="button"
          @click="goBack"
        >
          {{ t('producedBeerUnpacking.actions.back') }}
        </button>
      </header>

      <section
        v-if="pageError"
        class="rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
      >
        {{ pageError }}
      </section>

      <section
        v-if="loading"
        class="rounded-xl border border-gray-200 bg-white px-4 py-6 text-sm text-gray-500"
      >
        {{ t('common.loading') }}
      </section>

      <template v-else-if="source">
        <section class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm space-y-4">
          <header>
            <h2 class="text-lg font-semibold text-gray-900">
              {{ t('producedBeerUnpacking.sections.source') }}
            </h2>
            <p class="text-sm text-gray-500">{{ t('producedBeerUnpacking.source.subtitle') }}</p>
          </header>

          <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
            <div>
              <div class="text-xs uppercase text-gray-500">
                {{ t('producedBeerUnpacking.source.lotNo') }}
              </div>
              <div class="mt-1 font-mono text-sm text-gray-800">{{ source.lotNo || '—' }}</div>
            </div>
            <div>
              <div class="text-xs uppercase text-gray-500">
                {{ t('producedBeerUnpacking.source.batch') }}
              </div>
              <div class="mt-1 text-sm text-gray-800">{{ source.batchLabel }}</div>
            </div>
            <div>
              <div class="text-xs uppercase text-gray-500">
                {{ t('producedBeerUnpacking.source.product') }}
              </div>
              <div class="mt-1 text-sm text-gray-800">{{ source.productLabel }}</div>
            </div>
            <div>
              <div class="text-xs uppercase text-gray-500">
                {{ t('producedBeerUnpacking.source.package') }}
              </div>
              <div class="mt-1 text-sm text-gray-800">{{ source.packageLabel }}</div>
            </div>
            <div>
              <div class="text-xs uppercase text-gray-500">
                {{ t('producedBeerUnpacking.source.site') }}
              </div>
              <div class="mt-1 text-sm text-gray-800">{{ source.siteLabel }}</div>
            </div>
            <div>
              <div class="text-xs uppercase text-gray-500">
                {{ t('producedBeerUnpacking.source.available') }}
              </div>
              <div class="mt-1 text-sm text-gray-800">{{ formatSelectedVolume(availableLiters) }}</div>
            </div>
          </div>
        </section>

        <section class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm space-y-4">
          <header>
            <h2 class="text-lg font-semibold text-gray-900">
              {{ t('producedBeerUnpacking.sections.form') }}
            </h2>
            <p class="text-sm text-gray-500">{{ t('producedBeerUnpacking.form.subtitle') }}</p>
          </header>

          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('producedBeerUnpacking.form.qty') }}
              </label>
              <input
                v-model.trim="form.qty"
                type="number"
                min="0"
                step="0.001"
                class="w-full h-[40px] rounded border border-gray-300 px-3"
              />
              <p v-if="errors.qty" class="mt-1 text-xs text-red-600">{{ errors.qty }}</p>
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('producedBeerUnpacking.form.uom') }}
              </label>
              <select
                v-model="form.uom_id"
                class="w-full h-[40px] rounded border border-gray-300 bg-white px-3"
              >
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in volumeUomOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
              <p v-if="errors.uom_id" class="mt-1 text-xs text-red-600">{{ errors.uom_id }}</p>
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('producedBeerUnpacking.form.destSite') }}
              </label>
              <select
                v-model="form.dest_site_id"
                class="w-full h-[40px] rounded border border-gray-300 bg-white px-3"
              >
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in siteOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
              <p v-if="errors.dest_site_id" class="mt-1 text-xs text-red-600">
                {{ errors.dest_site_id }}
              </p>
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('producedBeerUnpacking.form.tank') }}
              </label>
              <select
                v-model="form.tank_id"
                class="w-full h-[40px] rounded border border-gray-300 bg-white px-3"
              >
                <option value="">{{ t('producedBeerUnpacking.defaults.noTank') }}</option>
                <option v-for="option in tankOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('producedBeerUnpacking.form.targetBatch') }}
              </label>
              <select
                v-model="form.target_batch_id"
                class="w-full h-[40px] rounded border border-gray-300 bg-white px-3"
              >
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in batchOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
              <p v-if="errors.target_batch_id" class="mt-1 text-xs text-red-600">
                {{ errors.target_batch_id }}
              </p>
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('producedBeerUnpacking.form.lossQty') }}
              </label>
              <input
                v-model.trim="form.loss_qty"
                type="number"
                min="0"
                step="0.001"
                class="w-full h-[40px] rounded border border-gray-300 px-3"
              />
              <p v-if="errors.loss_qty" class="mt-1 text-xs text-red-600">{{ errors.loss_qty }}</p>
            </div>

            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('producedBeerUnpacking.form.reason') }}
              </label>
              <input
                v-model.trim="form.reason"
                type="text"
                class="w-full h-[40px] rounded border border-gray-300 px-3"
              />
            </div>
          </div>

          <div>
            <label class="mb-1 block text-sm text-gray-600">
              {{ t('producedBeerUnpacking.form.memo') }}
            </label>
            <textarea
              v-model.trim="form.memo"
              rows="3"
              class="w-full rounded border border-gray-300 px-3 py-2"
            />
          </div>
        </section>

        <section class="rounded-xl border border-gray-200 bg-gray-50/70 p-4 shadow-sm space-y-3">
          <header>
            <h2 class="text-lg font-semibold text-gray-900">
              {{ t('producedBeerUnpacking.sections.preview') }}
            </h2>
            <p class="text-sm text-gray-500">{{ t('producedBeerUnpacking.preview.subtitle') }}</p>
          </header>

          <div class="grid grid-cols-1 gap-4 md:grid-cols-3">
            <div class="rounded-lg border border-gray-200 bg-white px-4 py-3">
              <div class="text-xs uppercase text-gray-500">
                {{ t('producedBeerUnpacking.preview.remaining') }}
              </div>
              <div class="mt-1 text-base font-semibold text-gray-800">
                {{ formatSelectedVolume(remainingLiters) }}
              </div>
            </div>
            <div class="rounded-lg border border-gray-200 bg-white px-4 py-3">
              <div class="text-xs uppercase text-gray-500">
                {{ t('producedBeerUnpacking.preview.recovered') }}
              </div>
              <div class="mt-1 text-base font-semibold text-gray-800">
                {{ formatSelectedVolume(recoveredLiters) }}
              </div>
            </div>
            <div class="rounded-lg border border-gray-200 bg-white px-4 py-3">
              <div class="text-xs uppercase text-gray-500">
                {{ t('producedBeerUnpacking.preview.loss') }}
              </div>
              <div class="mt-1 text-base font-semibold text-gray-800">
                {{ formatSelectedVolume(lossLiters) }}
              </div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-4 md:grid-cols-3 text-sm text-gray-600">
            <div>
              <div class="text-xs uppercase text-gray-500">
                {{ t('producedBeerUnpacking.preview.destSite') }}
              </div>
              <div class="mt-1 text-gray-800">{{ selectedSiteLabel }}</div>
            </div>
            <div>
              <div class="text-xs uppercase text-gray-500">
                {{ t('producedBeerUnpacking.preview.tank') }}
              </div>
              <div class="mt-1 text-gray-800">{{ selectedTankLabel }}</div>
            </div>
            <div>
              <div class="text-xs uppercase text-gray-500">
                {{ t('producedBeerUnpacking.preview.targetBatch') }}
              </div>
              <div class="mt-1 text-gray-800">{{ selectedBatchLabel }}</div>
            </div>
          </div>
        </section>

        <section class="flex flex-wrap items-center justify-end gap-2">
          <button
            class="px-4 py-2 rounded border border-gray-300 hover:bg-gray-50"
            type="button"
            :disabled="saving"
            @click="goBack"
          >
            {{ t('common.cancel') }}
          </button>
          <button
            class="px-4 py-2 rounded bg-amber-600 text-white hover:bg-amber-700 disabled:opacity-50"
            type="button"
            :disabled="saving"
            @click="saveUnpacking"
          >
            {{ saving ? t('common.saving') : t('common.save') }}
          </button>
        </section>
      </template>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import { toast } from 'vue3-toastify'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { formatRpcErrorMessage } from '@/lib/rpcErrors'
import { supabase } from '@/lib/supabase'
import { formatVolume } from '@/lib/volumeFormat'

type SourceSummary = {
  lotId: string
  lotNo: string | null
  lotTaxType: string | null
  batchId: string | null
  batchLabel: string
  productLabel: string
  packageLabel: string
  siteId: string
  siteLabel: string
  availableQty: number
  availableQtyLiters: number
  sourceUomId: string
  sourceUomCode: string | null
}

type SelectOption = {
  value: string
  label: string
}

const MANUFACTURING_SITE_TYPE_KEY = 'BREWERY_MANUFACTUR'

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()

const pageTitle = computed(() => t('producedBeerUnpacking.title'))
const loading = ref(false)
const saving = ref(false)
const pageError = ref('')
const tenantId = ref<string | null>(null)
const source = ref<SourceSummary | null>(null)
const siteOptions = ref<SelectOption[]>([])
const tankOptions = ref<Array<SelectOption & { code: string }>>([])
const batchOptions = ref<SelectOption[]>([])
const volumeUomOptions = ref<Array<SelectOption & { code: string }>>([])
const uomCodeById = ref(new Map<string, string>())

const form = reactive({
  qty: '',
  uom_id: '',
  dest_site_id: '',
  tank_id: '',
  target_batch_id: '',
  loss_qty: '0',
  reason: 'unpack',
  memo: '',
})

const errors = reactive<Record<string, string>>({})

function toNumber(value: unknown) {
  if (value == null || value === '') return null
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : null
}

function resolveNameI18n(value: Record<string, string> | null | undefined) {
  if (!value) return ''
  const lang = String(locale.value ?? '').toLowerCase().startsWith('ja') ? 'ja' : 'en'
  if (value[lang]) return value[lang]
  const fallback = Object.values(value)[0]
  return fallback ?? ''
}

function resolveUomCode(value: string | null | undefined) {
  if (!value) return null
  return uomCodeById.value.get(value) ?? value
}

function convertToLiters(size: number | null | undefined, uomCode: string | null | undefined) {
  if (size == null || Number.isNaN(Number(size))) return null
  if (!uomCode) return Number(size)
  switch (uomCode) {
    case 'L':
      return Number(size)
    case 'mL':
      return Number(size) / 1000
    case 'gal_us':
      return Number(size) * 3.78541
    default:
      return Number(size)
  }
}

function convertFromLiters(
  sizeInLiters: number | null | undefined,
  uomCode: string | null | undefined,
) {
  if (sizeInLiters == null || Number.isNaN(Number(sizeInLiters))) return null
  if (!uomCode) return Number(sizeInLiters)
  switch (uomCode) {
    case 'L':
      return Number(sizeInLiters)
    case 'mL':
      return Number(sizeInLiters) * 1000
    case 'gal_us':
      return Number(sizeInLiters) / 3.78541
    default:
      return Number(sizeInLiters)
  }
}

function extractErrorMessage(err: unknown) {
  if (!err) return ''
  if (typeof err === 'string') return err
  if (err instanceof Error) return err.message
  const record = err as Record<string, unknown>
  if (typeof record.message === 'string' && record.message.trim()) return record.message
  if (typeof record.details === 'string' && record.details.trim()) return record.details
  if (typeof record.hint === 'string' && record.hint.trim()) return record.hint
  return ''
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

function selectedOptionLabel(options: SelectOption[], value: string) {
  if (!value) return '—'
  return options.find((option) => option.value === value)?.label ?? value
}

const selectedUomCode = computed(() => resolveUomCode(form.uom_id))
const availableLiters = computed(() => source.value?.availableQtyLiters ?? null)

const unpackQtyLiters = computed(() => {
  const qty = toNumber(form.qty)
  return convertToLiters(qty, selectedUomCode.value)
})

const lossLiters = computed(() => {
  const qty = toNumber(form.loss_qty) ?? 0
  return convertToLiters(qty, selectedUomCode.value)
})

const recoveredLiters = computed(() => {
  const unpackQty = unpackQtyLiters.value
  const lossQty = lossLiters.value ?? 0
  if (unpackQty == null) return null
  return unpackQty - lossQty
})

const remainingLiters = computed(() => {
  const available = availableLiters.value
  const unpackQty = unpackQtyLiters.value
  if (available == null) return null
  if (unpackQty == null) return available
  return available - unpackQty
})

const selectedSiteLabel = computed(() => selectedOptionLabel(siteOptions.value, form.dest_site_id))
const selectedTankLabel = computed(() => selectedOptionLabel(tankOptions.value, form.tank_id))
const selectedBatchLabel = computed(() => selectedOptionLabel(batchOptions.value, form.target_batch_id))

function formatSelectedVolume(valueInLiters: number | null | undefined) {
  const converted = convertFromLiters(valueInLiters, selectedUomCode.value)
  return formatVolume(converted, locale.value, selectedUomCode.value ?? 'L')
}

async function loadUoms() {
  const { data, error } = await supabase
    .from('mst_uom')
    .select('id, code, name, dimension')
    .eq('dimension', 'volume')
    .order('code')
  if (error) throw error
  const options = (data ?? [])
    .map((row: Record<string, unknown>) => {
      const id = String(row.id ?? '')
      const code = String(row.code ?? '')
      const name = row.name != null ? String(row.name) : ''
      return {
        value: id,
        code,
        label: name ? `${code} - ${name}` : code,
      }
    })
    .filter((row) => row.value)
  volumeUomOptions.value = options
  uomCodeById.value = new Map(options.map((row) => [row.value, row.code]))
}

async function loadSiteOptions(tenant: string) {
  const { data: siteTypeRow, error: siteTypeError } = await supabase
    .from('registry_def')
    .select('def_id')
    .eq('kind', 'site_type')
    .eq('def_key', MANUFACTURING_SITE_TYPE_KEY)
    .eq('is_active', true)
    .maybeSingle()
  if (siteTypeError) throw siteTypeError
  if (!siteTypeRow?.def_id) {
    siteOptions.value = []
    return
  }
  const { data, error } = await supabase
    .from('mst_sites')
    .select('id, name, active')
    .eq('tenant_id', tenant)
    .eq('site_type_id', siteTypeRow.def_id)
    .eq('active', true)
    .order('name')
  if (error) throw error
  siteOptions.value = (data ?? [])
    .map((row: Record<string, unknown>) => ({
      value: String(row.id ?? ''),
      label: String(row.name ?? row.id ?? ''),
    }))
    .filter((row) => row.value)
}

async function loadTankOptions(tenant: string) {
  const { data: tankRows, error: tankError } = await supabase
    .from('mst_equipment_tank')
    .select('equipment_id')
  if (tankError) throw tankError
  const tankIds = (tankRows ?? [])
    .map((row: Record<string, unknown>) => row.equipment_id)
    .filter((value): value is string => typeof value === 'string' && value.length > 0)
  if (!tankIds.length) {
    tankOptions.value = []
    return
  }
  const { data: equipmentRows, error: equipmentError } = await supabase
    .from('mst_equipment')
    .select('id, equipment_code, name_i18n, equipment_kind, is_active')
    .eq('tenant_id', tenant)
    .eq('equipment_kind', 'tank')
    .eq('is_active', true)
    .in('id', tankIds)
    .order('equipment_code')
  if (equipmentError) throw equipmentError
  tankOptions.value = (equipmentRows ?? [])
    .map((row: Record<string, unknown>) => {
      const code = String(row.equipment_code ?? row.id ?? '')
      const name = resolveNameI18n(
        (row.name_i18n as Record<string, string> | null | undefined) ?? null,
      )
      return {
        value: String(row.id ?? ''),
        code,
        label: name ? `${code} - ${name}` : code,
      }
    })
    .filter((row) => row.value)
}

async function loadBatchOptions(tenant: string) {
  const { data, error } = await supabase
    .from('mes_batches')
    .select('id, batch_code, batch_label, product_name')
    .eq('tenant_id', tenant)
    .order('batch_code')
  if (error) throw error
  batchOptions.value = (data ?? [])
    .map((row: Record<string, unknown>) => {
      const batchCode = row.batch_code != null ? String(row.batch_code) : ''
      const batchLabel = row.batch_label != null ? String(row.batch_label) : ''
      const productName = row.product_name != null ? String(row.product_name) : ''
      const suffix = productName || batchLabel
      return {
        value: String(row.id ?? ''),
        label: suffix ? `${batchCode || row.id} / ${suffix}` : String(batchCode || row.id || ''),
      }
    })
    .filter((row) => row.value)
}

async function loadSourceSummary(tenant: string) {
  const lotId = String(route.params.lotId ?? '').trim()
  if (!lotId) throw new Error(t('producedBeerUnpacking.errors.invalidLot'))

  const { data: lotRow, error: lotError } = await supabase
    .from('lot')
    .select('id, lot_no, lot_tax_type, batch_id, package_id, site_id, qty, uom_id, status')
    .eq('tenant_id', tenant)
    .eq('id', lotId)
    .maybeSingle()
  if (lotError) throw lotError
  if (!lotRow) throw new Error(t('producedBeerUnpacking.errors.invalidLot'))
  if (!lotRow.package_id) throw new Error(t('producedBeerUnpacking.errors.notPackaged'))
  if (String(lotRow.status ?? '').toLowerCase() === 'void') {
    throw new Error(t('producedBeerUnpacking.errors.invalidLot'))
  }

  const [inventoryResult, packageResult, batchResult, siteResult] = await Promise.all([
    supabase
      .from('inv_inventory')
      .select('qty, site_id, uom_id')
      .eq('tenant_id', tenant)
      .eq('lot_id', lotId)
      .eq('uom_id', lotRow.uom_id)
      .gt('qty', 0)
      .order('created_at', { ascending: true })
      .limit(1)
      .maybeSingle(),
    supabase
      .from('mst_package')
      .select('id, package_code, name_i18n')
      .eq('tenant_id', tenant)
      .eq('id', lotRow.package_id)
      .maybeSingle(),
    lotRow.batch_id
      ? supabase
          .from('mes_batches')
          .select('id, batch_code, batch_label, product_name')
          .eq('tenant_id', tenant)
          .eq('id', lotRow.batch_id)
          .maybeSingle()
      : Promise.resolve({ data: null, error: null }),
    supabase
      .from('mst_sites')
      .select('id, name')
      .eq('tenant_id', tenant)
      .eq('id', lotRow.site_id)
      .maybeSingle(),
  ])

  if (inventoryResult.error) throw inventoryResult.error
  if (packageResult.error) throw packageResult.error
  if (batchResult.error) throw batchResult.error
  if (siteResult.error) throw siteResult.error

  const inventoryRow = inventoryResult.data
  if (!inventoryRow?.site_id || toNumber(inventoryRow.qty) == null || Number(inventoryRow.qty) <= 0) {
    throw new Error(t('producedBeerUnpacking.errors.noInventory'))
  }

  const sourceUomCode = resolveUomCode(String(lotRow.uom_id))
  const availableQty = Number(inventoryRow.qty)
  const availableQtyLiters = convertToLiters(availableQty, sourceUomCode)
  if (availableQtyLiters == null || availableQtyLiters <= 0) {
    throw new Error(t('producedBeerUnpacking.errors.noInventory'))
  }

  const packageLabel = resolveNameI18n(
    (packageResult.data?.name_i18n as Record<string, string> | null | undefined) ?? null,
  )
  const packageCode = packageResult.data?.package_code != null
    ? String(packageResult.data.package_code)
    : ''
  const batchCode = batchResult.data?.batch_code != null ? String(batchResult.data.batch_code) : ''
  const batchLabel = batchResult.data?.batch_label != null
    ? String(batchResult.data.batch_label)
    : ''
  const productName = batchResult.data?.product_name != null
    ? String(batchResult.data.product_name)
    : ''

  source.value = {
    lotId: String(lotRow.id),
    lotNo: lotRow.lot_no != null ? String(lotRow.lot_no) : null,
    lotTaxType: lotRow.lot_tax_type != null ? String(lotRow.lot_tax_type) : null,
    batchId: lotRow.batch_id != null ? String(lotRow.batch_id) : null,
    batchLabel: batchCode || batchLabel || '—',
    productLabel: productName || batchLabel || batchCode || '—',
    packageLabel: packageLabel || packageCode || '—',
    siteId: String(inventoryRow.site_id),
    siteLabel: siteResult.data?.name != null ? String(siteResult.data.name) : String(inventoryRow.site_id),
    availableQty,
    availableQtyLiters,
    sourceUomId: String(lotRow.uom_id),
    sourceUomCode,
  }
}

function initializeDefaults() {
  if (!source.value) return
  form.uom_id = source.value.sourceUomId
  form.target_batch_id = source.value.batchId ?? ''
  const matchingSourceSite = siteOptions.value.find((option) => option.value === source.value?.siteId)
  if (matchingSourceSite) {
    form.dest_site_id = matchingSourceSite.value
  } else if (siteOptions.value.length === 1) {
    form.dest_site_id = siteOptions.value[0].value
  }
}

async function initialize() {
  loading.value = true
  pageError.value = ''
  try {
    const tenant = await ensureTenant()
    await loadUoms()
    await Promise.all([
      loadSiteOptions(tenant),
      loadTankOptions(tenant),
      loadBatchOptions(tenant),
      loadSourceSummary(tenant),
    ])
    initializeDefaults()
  } catch (err) {
    pageError.value = extractErrorMessage(err) || t('producedBeerUnpacking.errors.loadFailed')
    source.value = null
  } finally {
    loading.value = false
  }
}

function resetErrors() {
  Object.keys(errors).forEach((key) => {
    delete errors[key]
  })
}

function validateForm() {
  resetErrors()
  if (!source.value) {
    pageError.value = t('producedBeerUnpacking.errors.invalidLot')
    return false
  }

  if (!form.uom_id) errors.uom_id = t('producedBeerUnpacking.errors.uomRequired')
  const unpackQty = unpackQtyLiters.value
  if (unpackQty == null || unpackQty <= 0) {
    errors.qty = t('producedBeerUnpacking.errors.qtyRequired')
  } else if (availableLiters.value != null && unpackQty > availableLiters.value) {
    errors.qty = t('producedBeerUnpacking.errors.qtyExceeded')
  }

  const lossQty = lossLiters.value ?? 0
  if (lossQty < 0) {
    errors.loss_qty = t('producedBeerUnpacking.errors.lossInvalid')
  } else if (unpackQty != null && lossQty >= unpackQty) {
    errors.loss_qty = t('producedBeerUnpacking.errors.lossTooLarge')
  }

  if (!form.dest_site_id) errors.dest_site_id = t('producedBeerUnpacking.errors.destSiteRequired')
  if (!form.target_batch_id) errors.target_batch_id = t('producedBeerUnpacking.errors.batchRequired')

  return Object.keys(errors).length === 0
}

function buildDocNo() {
  const sourceLot = source.value?.lotNo?.replace(/[^A-Za-z0-9_-]+/g, '') || 'LOT'
  return `PU-${sourceLot}-${Date.now()}`
}

function buildIdempotencyKey() {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID()
  }
  return `pu-${Date.now()}-${Math.random().toString(16).slice(2, 10)}`
}

async function saveUnpacking() {
  if (!validateForm() || !source.value) return
  try {
    saving.value = true
    const inputQtyLiters = unpackQtyLiters.value
    const inputLossLiters = lossLiters.value ?? 0
    if (inputQtyLiters == null) return

    const sourceUomCode = source.value.sourceUomCode
    const qtyForSourceUom = convertFromLiters(inputQtyLiters, sourceUomCode)
    const lossForSourceUom = convertFromLiters(inputLossLiters, sourceUomCode)
    if (qtyForSourceUom == null || lossForSourceUom == null) {
      throw new Error(t('producedBeerUnpacking.errors.uomConvertFailed'))
    }

    const payload = {
      doc_no: buildDocNo(),
      movement_at: new Date().toISOString(),
      src_site_id: source.value.siteId,
      dest_site_id: form.dest_site_id,
      src_lot_id: source.value.lotId,
      target_batch_id: form.target_batch_id,
      qty: qtyForSourceUom,
      loss_qty: lossForSourceUom,
      uom_id: source.value.sourceUomId,
      tank_id: form.tank_id || null,
      reason: form.reason.trim() || 'unpack',
      notes: form.memo.trim() || null,
      meta: {
        entry_source: 'produced_beer_inventory_unpacking',
        idempotency_key: buildIdempotencyKey(),
      },
    }

    const { error } = await supabase.rpc('product_unpacking', {
      p_doc: payload,
    })
    if (error) throw error

    toast.success(t('producedBeerUnpacking.saveSuccess'))
    await router.push({ name: 'ProducedBeerInventory' })
  } catch (err) {
    console.error(err)
    toast.error(formatRpcErrorMessage(err, {
      fallbackKey: 'producedBeerUnpacking.saveFailed',
    }))
  } finally {
    saving.value = false
  }
}

function goBack() {
  void router.push({ name: 'ProducedBeerInventory' })
}

onMounted(async () => {
  await initialize()
})
</script>

<style scoped>
input,
select,
textarea {
  min-width: 0;
}
</style>
