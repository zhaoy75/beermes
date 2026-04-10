import { ref } from 'vue'

export type TypeDefGraphSelection = {
  typeId: string
  domain: string
  code: string
  name: string
  isActive: boolean
}

export type TypeDefGraphOpenOptions = {
  preferredDomain?: string | null
  restoreFocusOnClose?: boolean
  onSelect?: ((row: TypeDefGraphSelection) => void) | null
}

const isTypeDefGraphOpen = ref(false)
const DEFAULT_OPTIONS = {
  preferredDomain: null as string | null,
  restoreFocusOnClose: true,
  onSelect: null as ((row: TypeDefGraphSelection) => void) | null,
}
const typeDefGraphOptions = ref({ ...DEFAULT_OPTIONS })

export function openTypeDefGraph(options?: TypeDefGraphOpenOptions) {
  typeDefGraphOptions.value = {
    preferredDomain: options?.preferredDomain ?? null,
    restoreFocusOnClose: options?.restoreFocusOnClose ?? true,
    onSelect: options?.onSelect ?? null,
  }
  isTypeDefGraphOpen.value = true
}

export function closeTypeDefGraph() {
  isTypeDefGraphOpen.value = false
  typeDefGraphOptions.value = { ...DEFAULT_OPTIONS }
}

export function useTypeDefGraphModal() {
  return {
    isTypeDefGraphOpen,
    typeDefGraphOptions,
  }
}
