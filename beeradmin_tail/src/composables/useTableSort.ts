import { computed, ref, unref, type ComputedRef, type Ref } from 'vue'

export type SortDirection = 'asc' | 'desc'

type SortValue = boolean | number | string | null | undefined
type SortSource<T> = ComputedRef<T[]> | Ref<T[]>
type SortAccessors<T, K extends string> = Record<K, (row: T) => SortValue>

const collator = new Intl.Collator(undefined, {
  numeric: true,
  sensitivity: 'base',
})

function normalizeSortValue(value: SortValue) {
  if (value == null) return null
  if (typeof value === 'string') {
    const trimmed = value.trim()
    return trimmed === '' ? null : trimmed
  }
  if (typeof value === 'boolean') return value ? 1 : 0
  if (typeof value === 'number') return Number.isFinite(value) ? value : null
  return String(value)
}

function compareValues(a: SortValue, b: SortValue, direction: SortDirection) {
  const normalizedA = normalizeSortValue(a)
  const normalizedB = normalizeSortValue(b)
  const multiplier = direction === 'asc' ? 1 : -1

  if (normalizedA == null && normalizedB == null) return 0
  if (normalizedA == null) return 1 * multiplier
  if (normalizedB == null) return -1 * multiplier

  if (typeof normalizedA === 'number' && typeof normalizedB === 'number') {
    return (normalizedA - normalizedB) * multiplier
  }

  return collator.compare(String(normalizedA), String(normalizedB)) * multiplier
}

export function useTableSort<T, K extends string>(
  sourceRows: SortSource<T>,
  accessors: SortAccessors<T, K>,
  initialKey: K,
  initialDirection: SortDirection = 'asc',
) {
  const sortKey = ref<K>(initialKey)
  const sortDirection = ref<SortDirection>(initialDirection)

  const sortedRows = computed<T[]>(() => {
    const currentKey = sortKey.value as K
    const accessor = accessors[currentKey]
    const list = [...unref(sourceRows)]

    list.sort((a, b) => compareValues(accessor(a), accessor(b), sortDirection.value))
    return list
  })

  function setSort(key: K) {
    if (sortKey.value === key) {
      sortDirection.value = sortDirection.value === 'asc' ? 'desc' : 'asc'
      return
    }
    sortKey.value = key
    sortDirection.value = 'asc'
  }

  function sortIcon(key: K) {
    if (sortKey.value !== key) return ''
    return sortDirection.value === 'asc' ? '▲' : '▼'
  }

  return {
    sortKey,
    sortDirection,
    sortedRows,
    setSort,
    sortIcon,
  }
}
