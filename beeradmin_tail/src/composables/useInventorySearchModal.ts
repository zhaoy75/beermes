import { ref } from 'vue'

export type InventorySearchSelection = {
  id: string
  lotId: string
  lotNo: string | null
  batchCode: string | null
  productName: string | null
  styleName: string | null
  packageId: string | null
  packageTypeLabel: string | null
  siteId: string | null
  qtyLiters: number | null
  qtyPackages: number | null
}

export type InventorySearchOpenOptions = {
  siteId?: string | null
  siteLocked?: boolean
  onSelect?: ((row: InventorySearchSelection) => void) | null
  afterSelectFocus?: ((row: InventorySearchSelection) => void) | null
}

const isInventorySearchOpen = ref(false)
const inventorySearchOptions = ref<InventorySearchOpenOptions>({})
const inventorySearchContextProvider = ref<(() => InventorySearchOpenOptions | undefined) | null>(
  null,
)

function normalizedOptions(options?: InventorySearchOpenOptions): InventorySearchOpenOptions {
  if (!options) return {}
  return {
    siteId: options.siteId ?? '',
    siteLocked: options.siteLocked ?? false,
    onSelect: options.onSelect ?? null,
    afterSelectFocus: options.afterSelectFocus ?? null,
  }
}

export function openInventorySearch(options?: InventorySearchOpenOptions) {
  inventorySearchOptions.value = normalizedOptions(options)
  isInventorySearchOpen.value = true
}

export function closeInventorySearch() {
  isInventorySearchOpen.value = false
  inventorySearchOptions.value = {}
}

export function resolveInventorySearchOpenOptions() {
  return normalizedOptions(inventorySearchContextProvider.value?.())
}

export function registerInventorySearchContext(
  provider: () => InventorySearchOpenOptions | undefined,
) {
  inventorySearchContextProvider.value = provider
  return () => {
    if (inventorySearchContextProvider.value === provider) {
      inventorySearchContextProvider.value = null
    }
  }
}

export function useInventorySearchModal() {
  return {
    isInventorySearchOpen,
    inventorySearchOptions,
  }
}
