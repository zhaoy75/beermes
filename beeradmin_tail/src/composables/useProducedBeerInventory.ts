import { computed, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import { toast } from 'vue3-toastify'
import { supabase } from '@/lib/supabase'
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
} from '@/lib/batchRecipeSnapshot'
import { formatVolumeNumber } from '@/lib/volumeFormat'

type ContainerKind = 'tank' | 'keg' | 'case' | 'other'

interface CategoryRow {
  def_id: string
  def_key: string
  spec: Record<string, any>
}

interface SiteOption {
  value: string
  label: string
  ownerType: string | null
  ownerName: string | null
  siteTypeKey: string | null
  isDomesticRemovalDummy: boolean
}

interface PackageCategoryRow {
  id: string
  package_code: string
  barcode: string | null
  name_i18n: Record<string, string> | null
  unit_volume: number | null
  volume_uom: string | null
}

interface InventoryRow {
  id: string
  lotId: string
  lotIds: string[]
  mergedCount: number
  lotNo: string | null
  lotTaxType: string | null
  batchId: string | null
  batchCode: string | null
  beerCategoryId: string | null
  targetAbv: number | null
  styleName: string | null
  productName: string | null
  packageId: string | null
  packageTypeLabel: string | null
  packageCode: string | null
  packageBarcode: string | null
  containerKind: ContainerKind
  arrivalIntent: string | null
  showAsInventoryWithoutPackage: boolean
  keywordIndex: string
  productionDate: string | null
  qtyPackages: number | null
  qtyLiters: number | null
  siteId: string | null
  siteIds: string[]
  siteLabelText: string
  canShowDag: boolean
  canVoid: boolean
  voidTargets: Array<{ lotId: string; siteId: string }>
  mergedDetails: InventoryMergedDetail[]
}

interface InventoryMergedDetail {
  id: string
  lotId: string
  lotNo: string | null
  lotTaxType: string | null
  productionDate: string | null
  qtyPackages: number | null
  qtyLiters: number | null
  siteId: string | null
}

interface PackageInfo {
  packageId: string
  packageTypeLabel: string | null
  packageCode: string | null
  packageBarcode: string | null
  unitSizeLiters: number | null
  containerKind: ContainerKind
}

interface BatchInfo {
  batchCode: string | null
  beerCategoryId: string | null
  targetAbv: number | null
  styleName: string | null
  productName: string | null
  keywordText: string
}

const DOMESTIC_REMOVAL_DUMMY_OWNER_TYPE = 'OUTSIDE'
const DOMESTIC_REMOVAL_DUMMY_OWNER_NAME = 'SYSTEM_DOMESTIC_REMOVAL_COMPLETE'

function pushKeyword(set: Set<string>, value: unknown) {
  if (value == null) return
  if (typeof value === 'string') {
    const trimmed = value.trim()
    if (trimmed) set.add(trimmed.toLowerCase())
    return
  }
  if (typeof value === 'number' || typeof value === 'boolean') {
    set.add(String(value).toLowerCase())
    return
  }
  if (Array.isArray(value)) {
    value.forEach((item) => pushKeyword(set, item))
    return
  }
  if (typeof value === 'object') {
    Object.values(value as Record<string, unknown>).forEach((item) => pushKeyword(set, item))
  }
}

function buildKeywordIndex(...values: Array<unknown>) {
  const terms = new Set<string>()
  values.forEach((value) => pushKeyword(terms, value))
  return Array.from(terms).join(' ')
}

export function useProducedBeerInventory() {
  const { locale } = useI18n()

  const tenantId = ref<string | null>(null)
  const inventoryLoading = ref(false)

  const categories = ref<CategoryRow[]>([])
  const categoryFallbackRows = ref<CategoryRow[]>([])
  const packageCategories = ref<PackageCategoryRow[]>([])
  const uoms = ref<Array<{ id: string; code: string | null }>>([])
  const siteOptions = ref<SiteOption[]>([])

  const inventoryRows = ref<InventoryRow[]>([])

  const siteMap = computed(() => {
    const map = new Map<string, SiteOption>()
    siteOptions.value.forEach((item) => map.set(item.value, item))
    return map
  })

  const ownedSiteOptions = computed(() =>
    siteOptions.value
      .filter((item) => item.ownerType === 'OWN')
      .map((item) => ({ value: item.value, label: item.label })),
  )

  const categoryLabelMap = computed(() => buildAlcoholTypeLabelMap(categories.value, categoryFallbackRows.value))

  const packageCategoryMap = computed(() => {
    const map = new Map<
      string,
      {
        label: string | null
        packageCode: string | null
        packageBarcode: string | null
        size: number | null
        uomId: string | null
        containerKind: ContainerKind
      }
    >()

    packageCategories.value.forEach((row) => {
      const label = resolvePackageName(row)
      map.set(row.id, {
        label,
        packageCode: row.package_code ?? null,
        packageBarcode: row.barcode ?? null,
        size: row.unit_volume ?? null,
        uomId: row.volume_uom ?? null,
        containerKind: resolveContainerKind(row.package_code, label),
      })
    })

    return map
  })

  const uomMap = computed(() => {
    const map = new Map<string, string>()
    uoms.value.forEach((row) => map.set(row.id, row.code ?? ''))
    return map
  })

  const packageOptions = computed(() =>
    packageCategories.value.map((row) => ({
      value: row.id,
      label: resolvePackageName(row) || row.package_code || row.id,
    })),
  )

  const numberFormatter = computed(
    () => new Intl.NumberFormat(locale.value, { maximumFractionDigits: 2 }),
  )

  function formatNumber(value: number | null | undefined) {
    if (value == null || Number.isNaN(value)) return '—'
    return numberFormatter.value.format(value)
  }

  function formatVolumeNumberValue(value: number | null | undefined) {
    return formatVolumeNumber(value, locale.value)
  }

  function formatAbv(value: number | null | undefined) {
    if (value == null || Number.isNaN(value)) return '—'
    return `${numberFormatter.value.format(value)}%`
  }

  function formatDate(value: string | null | undefined) {
    if (!value) return '—'
    try {
      return new Intl.DateTimeFormat(locale.value).format(new Date(value))
    } catch {
      return value
    }
  }

  function categoryLabel(categoryId: string | null | undefined) {
    if (!categoryId) return '—'
    return resolveAlcoholTypeLabel(categoryLabelMap.value, categoryId) ?? categoryId
  }

  function siteLabel(siteId: string | null | undefined) {
    if (!siteId) return '—'
    return siteMap.value.get(siteId)?.label ?? '—'
  }

  function siteTypeKey(siteId: string | null | undefined) {
    if (!siteId) return null
    return siteMap.value.get(siteId)?.siteTypeKey ?? null
  }

  function isDomesticRemovalDummySite(siteId: string | null | undefined) {
    if (!siteId) return false
    return siteMap.value.get(siteId)?.isDomesticRemovalDummy ?? false
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
    return name || row.package_code || null
  }

  function resolveContainerKind(
    packageCode: string | null | undefined,
    packageLabel: string | null | undefined,
  ): ContainerKind {
    const normalized = `${packageCode ?? ''} ${packageLabel ?? ''}`.toLowerCase()
    if (!normalized.trim()) return 'tank'
    if (normalized.includes('tank')) return 'tank'
    if (normalized.includes('keg')) return 'keg'
    if (normalized.includes('case')) return 'case'
    return 'other'
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

  function resolveMetaNumber(meta: Record<string, any> | null | undefined, key: string) {
    const value = meta?.[key]
    if (value == null) return null
    const num = Number(value)
    return Number.isFinite(num) ? num : null
  }

  function toNumber(value: any): number | null {
    if (value == null) return null
    const num = Number(value)
    return Number.isFinite(num) ? num : null
  }

  function convertToLiters(size: number | null, uomCode: string | null | undefined) {
    if (size == null || Number.isNaN(size)) return null
    switch (uomCode) {
      case 'L':
      case null:
      case undefined:
        return size
      case 'mL':
        return size / 1000
      case 'gal_us':
        return size * 3.78541
      default:
        return size
    }
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
    const { optionRows, fallbackRows } = await loadAlcoholTypeReferenceData(supabase)
    categories.value = optionRows as CategoryRow[]
    categoryFallbackRows.value = fallbackRows as CategoryRow[]
  }

  async function loadPackageCategories() {
    const tenant = await ensureTenant()
    const { data, error } = await supabase
      .from('mst_package')
      .select('id, package_code, barcode, name_i18n, unit_volume, volume_uom, is_active')
      .eq('tenant_id', tenant)
      .eq('is_active', true)
      .order('package_code', { ascending: true })
    if (error) throw error
    packageCategories.value = data ?? []
  }

  async function loadUoms() {
    const { data, error } = await supabase.from('mst_uom').select('id, code').order('code')
    if (error) throw error
    uoms.value = data ?? []
  }

  async function loadSites() {
    const tenant = await ensureTenant()
    const { data: siteTypes, error: siteTypeError } = await supabase
      .from('registry_def')
      .select('def_id, def_key')
      .eq('kind', 'site_type')
      .eq('is_active', true)
    if (siteTypeError) throw siteTypeError
    const siteTypeMap = new Map<string, string>()
    ;(siteTypes ?? []).forEach((row: any) => {
      if (!row?.def_id) return
      siteTypeMap.set(String(row.def_id), String(row.def_key ?? ''))
    })

    const { data, error } = await supabase
      .from('mst_sites')
      .select('id, name, owner_type, owner_name, site_type_id')
      .eq('tenant_id', tenant)
      .order('name', { ascending: true })
    if (error) throw error
    siteOptions.value = (data ?? []).map((row) => ({
      value: row.id,
      label: row.name ?? row.id,
      ownerType: row.owner_type ?? null,
      ownerName: row.owner_name ?? null,
      siteTypeKey: row.site_type_id ? siteTypeMap.get(String(row.site_type_id)) ?? null : null,
      isDomesticRemovalDummy:
        row.owner_type === DOMESTIC_REMOVAL_DUMMY_OWNER_TYPE
        && row.owner_name === DOMESTIC_REMOVAL_DUMMY_OWNER_NAME,
    }))
  }

  async function loadPackageInfo(packageIds: string[]) {
    const infoMap = new Map<string, PackageInfo>()
    if (packageIds.length === 0) return infoMap

    Array.from(new Set(packageIds)).forEach((id) => {
      const category = packageCategoryMap.value.get(id)
      const uomCode = category?.uomId ? uomMap.value.get(category.uomId) : null
      const unitSizeLiters = category?.size != null ? convertToLiters(category.size, uomCode) : null
      infoMap.set(id, {
        packageId: id,
        packageTypeLabel: category?.label ?? null,
        packageCode: category?.packageCode ?? null,
        packageBarcode: category?.packageBarcode ?? null,
        unitSizeLiters,
        containerKind: category?.containerKind ?? 'other',
      })
    })

    return infoMap
  }

  async function loadBatchInfo(batchIds: string[]) {
    const infoMap = new Map<string, BatchInfo>()
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
    const keywordTermsByBatch = new Map<string, Set<string>>()

    const ensureKeywordSet = (batchId: string) => {
      if (!keywordTermsByBatch.has(batchId)) keywordTermsByBatch.set(batchId, new Set<string>())
      return keywordTermsByBatch.get(batchId) as Set<string>
    }

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
          .in('entity_id', uniqueIds)
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
            if (typeof jsonDefId === 'string' && jsonDefId.trim()) {
              entry.beerCategoryId = jsonDefId.trim()
            } else if (typeof row.value_text === 'string' && row.value_text.trim()) {
              entry.beerCategoryId = row.value_text.trim()
            } else if (row.value_ref_type_id != null) {
              entry.beerCategoryId = String(row.value_ref_type_id)
            }
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
            if (typeof row.value_text === 'string' && row.value_text.trim()) {
              entry.styleName = row.value_text.trim()
            }
          }
        })
      }

      const { data: keywordAttrs, error: keywordError } = await supabase
        .from('entity_attr')
        .select('entity_id, value_text, value_num, value_json')
        .eq('entity_type', 'batch')
        .in('entity_id', uniqueIds)
      if (keywordError) throw keywordError

      ;(keywordAttrs ?? []).forEach((row: any) => {
        const batchId = String(row.entity_id ?? '')
        if (!batchId) return
        const keywordSet = ensureKeywordSet(batchId)
        pushKeyword(keywordSet, row.value_text)
        pushKeyword(keywordSet, row.value_num)
        pushKeyword(keywordSet, row.value_json)
      })
    } catch (err) {
      console.warn('Failed to load batch attr values, fallback to recipe/meta only', err)
    }

    const { data, error } = await supabase
      .from('mes_batches')
      .select('id, batch_code, batch_label, product_name, meta, mes_recipe_id, released_reference_json, recipe_json')
      .eq('tenant_id', tenant)
      .in('id', uniqueIds)
    if (error) throw error

    ;(data ?? []).forEach((row: any) => {
      const attr = attrValueByBatch.get(row.id)
      const meta =
        row.meta && typeof row.meta === 'object' && !Array.isArray(row.meta)
          ? (row.meta as Record<string, any>)
          : null
      const productName = resolveBatchDisplayName(row)
      const keywordText = buildKeywordIndex(
        row.batch_code,
        row.batch_label,
        row.product_name,
        meta,
        keywordTermsByBatch.get(row.id),
      )

      infoMap.set(row.id, {
        batchCode: row.batch_code ?? resolveBatchLabel(meta) ?? null,
        beerCategoryId: resolveBatchBeerCategoryId(row, attr),
        targetAbv: resolveBatchTargetAbv(row, attr),
        styleName: resolveBatchStyleName(row, attr),
        productName,
        keywordText,
      })
    })

    return infoMap
  }

  async function loadInventory() {
    try {
      inventoryLoading.value = true
      const tenant = await ensureTenant()
      const { data, error } = await supabase
        .from('inv_inventory')
        .select('id, site_id, lot_id, qty, uom_id')
        .eq('tenant_id', tenant)
        .gt('qty', 0)
        .order('created_at', { ascending: false })
      if (error) throw error

      const inventory = data ?? []
      if (!inventory.length) {
        inventoryRows.value = []
        return
      }

      const lotIds = Array.from(new Set(inventory.map((row: any) => row.lot_id).filter(Boolean)))
      if (!lotIds.length) {
        inventoryRows.value = []
        return
      }

      const { data: lots, error: lotError } = await supabase
        .from('lot')
        .select('id, lot_no, lot_tax_type, batch_id, package_id, produced_at, status, meta')
        .eq('tenant_id', tenant)
        .in('id', lotIds)
        .neq('status', 'void')
      if (lotError) throw lotError

      const lotMap = new Map<string, any>()
      ;(lots ?? []).forEach((row: any) => {
        if (String(row.status ?? '').toLowerCase() !== 'void') lotMap.set(row.id, row)
      })
      if (lotMap.size === 0) {
        inventoryRows.value = []
        return
      }

      const packageIds = Array.from(
        new Set(
          Array.from(lotMap.values())
            .map((row: any) => row.package_id)
            .filter(Boolean),
        ),
      )
      const batchIds = Array.from(
        new Set(
          Array.from(lotMap.values())
            .map((row: any) => row.batch_id)
            .filter(Boolean),
        ),
      )

      const packageInfoMap = await loadPackageInfo(packageIds)
      const batchInfoMap = await loadBatchInfo(batchIds)

      type InventoryAccumulator = {
        key: string
        lotId: string
        lotIds: Set<string>
        siteId: string
        siteIds: Set<string>
        siteLabels: Set<string>
        lotNo: string | null
        lotTaxType: string | null
        batchId: string | null
        batchCode: string | null
        beerCategoryId: string | null
        targetAbv: number | null
        styleName: string | null
        productName: string | null
        packageId: string | null
        packageTypeLabel: string | null
        packageCode: string | null
        packageBarcode: string | null
        containerKind: ContainerKind
        arrivalIntent: string | null
        showAsInventoryWithoutPackage: boolean
        keywordParts: Set<string>
        productionDate: string | null
        qtyPackages: number
        qtyLiters: number
        canVoid: boolean
        voidTargets: Array<{ lotId: string; siteId: string }>
        detailMap: Map<string, InventoryMergedDetail>
      }

      const accum = new Map<string, InventoryAccumulator>()

      inventory.forEach((row: any) => {
        const lot = lotMap.get(row.lot_id)
        if (!lot) return

        const siteId = row.site_id as string | null
        if (!siteId) return
        if (isDomesticRemovalDummySite(siteId)) return

        const pkgInfo = lot.package_id ? packageInfoMap.get(lot.package_id) : undefined
        const batchInfo = lot.batch_id ? batchInfoMap.get(lot.batch_id) : undefined
        const lotMeta =
          lot.meta && typeof lot.meta === 'object' && !Array.isArray(lot.meta)
            ? (lot.meta as Record<string, unknown>)
            : null
        const arrivalIntentRaw = lotMeta?.movement_intent
        const arrivalIntent = typeof arrivalIntentRaw === 'string' ? arrivalIntentRaw : null
        const showAsInventoryWithoutPackage =
          arrivalIntent === 'INTERNAL_TRANSFER' || arrivalIntent === 'RETURN_FROM_CUSTOMER'
        const inventoryQty = toNumber(row.qty)
        if (inventoryQty == null || inventoryQty <= 0) return

        const inventoryUomCode = row.uom_id ? (uomMap.value.get(row.uom_id) ?? null) : null
        const qtyLiters = convertToLiters(inventoryQty, inventoryUomCode) ?? 0
        const unitSizeLiters = pkgInfo?.unitSizeLiters ?? null
        const qtyPackages =
          unitSizeLiters != null && unitSizeLiters > 0 ? qtyLiters / unitSizeLiters : 0
        const packageGroupKey = pkgInfo?.packageId ?? `label:${pkgInfo?.packageTypeLabel ?? ''}`
        const batchGroupKey = lot.batch_id ? String(lot.batch_id) : ''
        const lotNoGroupKey = String(lot.lot_no ?? '')
        const lotTaxTypeGroupKey = String(lot.lot_tax_type ?? '')
        const key = `${batchGroupKey}__${lotNoGroupKey}__${lotTaxTypeGroupKey}__${packageGroupKey}__${siteId}`
        const detailKey = `${lot.id}__${siteId}`
        if (!accum.has(key)) {
          const siteName = siteLabel(siteId)
          const containerKind = pkgInfo?.containerKind ?? 'tank'
          const keywordParts = new Set<string>()

          pushKeyword(keywordParts, lot.lot_no)
          pushKeyword(keywordParts, lot.lot_tax_type)
          pushKeyword(keywordParts, lot.id)
          pushKeyword(keywordParts, batchInfo?.batchCode)
          pushKeyword(keywordParts, batchInfo?.productName)
          pushKeyword(keywordParts, batchInfo?.styleName)
          pushKeyword(keywordParts, pkgInfo?.packageTypeLabel)
          pushKeyword(keywordParts, pkgInfo?.packageCode)
          pushKeyword(keywordParts, pkgInfo?.packageBarcode)
          pushKeyword(keywordParts, siteName)
          pushKeyword(keywordParts, batchInfo?.keywordText)

          accum.set(key, {
            key,
            lotId: String(lot.id),
            lotIds: new Set([String(lot.id)]),
            siteId,
            siteIds: new Set([siteId]),
            siteLabels: new Set(siteName && siteName !== '—' ? [siteName] : []),
            lotNo: lot.lot_no ?? null,
            lotTaxType: lot.lot_tax_type ?? null,
            batchId: lot.batch_id ? String(lot.batch_id) : null,
            batchCode: batchInfo?.batchCode ?? null,
            beerCategoryId: batchInfo?.beerCategoryId ?? null,
            targetAbv: batchInfo?.targetAbv ?? null,
            styleName: batchInfo?.styleName ?? null,
            productName: batchInfo?.productName ?? null,
            packageId: pkgInfo?.packageId ?? null,
            packageTypeLabel: pkgInfo?.packageTypeLabel ?? null,
            packageCode: pkgInfo?.packageCode ?? null,
            packageBarcode: pkgInfo?.packageBarcode ?? null,
            containerKind,
            arrivalIntent,
            showAsInventoryWithoutPackage,
            keywordParts,
            productionDate: lot.produced_at ?? null,
            qtyPackages: 0,
            qtyLiters: 0,
            canVoid: siteTypeKey(siteId) === 'TAX_STORAGE',
            voidTargets: siteTypeKey(siteId) === 'TAX_STORAGE'
              ? [{ lotId: String(lot.id), siteId }]
              : [],
            detailMap: new Map(),
          })
        }

        const entry = accum.get(key)
        if (!entry) return
        entry.lotIds.add(String(lot.id))
        entry.siteIds.add(siteId)
        const siteName = siteLabel(siteId)
        if (siteName && siteName !== '—') entry.siteLabels.add(siteName)
        entry.qtyLiters += qtyLiters
        entry.qtyPackages += qtyPackages
        pushKeyword(entry.keywordParts, lot.id)
        if (!entry.productionDate && lot.produced_at) entry.productionDate = lot.produced_at
        if (siteTypeKey(siteId) === 'TAX_STORAGE') {
          const targetKey = `${lot.id}__${siteId}`
          if (!entry.voidTargets.some((target) => `${target.lotId}__${target.siteId}` === targetKey)) {
            entry.voidTargets.push({ lotId: String(lot.id), siteId })
          }
        } else {
          entry.canVoid = false
        }

        const detail = entry.detailMap.get(detailKey)
        if (detail) {
          detail.qtyLiters = (detail.qtyLiters ?? 0) + qtyLiters
          detail.qtyPackages = (detail.qtyPackages ?? 0) + qtyPackages
          if (!detail.productionDate && lot.produced_at) detail.productionDate = lot.produced_at
        } else {
          entry.detailMap.set(detailKey, {
            id: detailKey,
            lotId: String(lot.id),
            lotNo: lot.lot_no ?? null,
            lotTaxType: lot.lot_tax_type ?? null,
            productionDate: lot.produced_at ?? null,
            qtyPackages: qtyPackages > 0 ? qtyPackages : null,
            qtyLiters: qtyLiters > 0 ? qtyLiters : null,
            siteId,
          })
        }
      })

      inventoryRows.value = Array.from(accum.values())
        .filter((row) => row.qtyLiters > 0 || row.qtyPackages > 0)
        .map((row) => ({
          id: row.key,
          lotId: row.lotId,
          lotIds: Array.from(row.lotIds),
          mergedCount: row.detailMap.size,
          lotNo: row.lotNo,
          lotTaxType: row.lotTaxType,
          batchId: row.batchId,
          batchCode: row.batchCode,
          beerCategoryId: row.beerCategoryId,
          targetAbv: row.targetAbv,
          styleName: row.styleName,
          productName: row.productName,
          packageId: row.packageId,
          packageTypeLabel: row.packageTypeLabel,
          packageCode: row.packageCode,
          packageBarcode: row.packageBarcode,
          containerKind: row.containerKind,
          arrivalIntent: row.arrivalIntent,
          showAsInventoryWithoutPackage: row.showAsInventoryWithoutPackage,
          keywordIndex: Array.from(row.keywordParts).join(' '),
          productionDate: row.productionDate,
          qtyPackages: row.qtyPackages > 0 ? row.qtyPackages : null,
          qtyLiters: row.qtyLiters > 0 ? row.qtyLiters : null,
          siteId: row.siteId,
          siteIds: Array.from(row.siteIds),
          siteLabelText: Array.from(row.siteLabels).sort((a, b) => a.localeCompare(b)).join(', ') || '—',
          canShowDag: row.lotIds.size === 1,
          canVoid: row.canVoid && row.voidTargets.length > 0,
          voidTargets: row.voidTargets,
          mergedDetails: Array.from(row.detailMap.values()).sort((a, b) => {
            const dateCompare = (b.productionDate ?? '').localeCompare(a.productionDate ?? '')
            if (dateCompare !== 0) return dateCompare
            return a.lotId.localeCompare(b.lotId)
          }),
        }))
    } catch (err) {
      console.error(err)
      inventoryRows.value = []
      toast.error(err instanceof Error ? err.message : String(err))
    } finally {
      inventoryLoading.value = false
    }
  }

  async function initialize() {
    await ensureTenant()
    await Promise.all([loadSites(), loadCategories(), loadPackageCategories(), loadUoms()])
    await loadInventory()
  }

  return {
    categoryLabel,
    formatAbv,
    formatDate,
    formatNumber,
    formatVolumeNumberValue,
    initialize,
    inventoryLoading,
    inventoryRows,
    loadInventory,
    ownedSiteOptions,
    packageOptions,
    siteLabel,
    siteOptions,
  }
}
