import { computed, reactive, ref, unref, type ComputedRef, type Ref } from 'vue'

export type ColumnSortDirection = 'asc' | 'desc'
export type ColumnFilterType = 'none' | 'text' | 'select'

type SortValue = boolean | number | string | null | undefined
type TableSource<T> = ComputedRef<T[]> | Ref<T[]>

export type ColumnControlDefinition<T, K extends string> = {
  key: K
  sortValue?: (row: T) => SortValue
  filterValue?: (row: T) => SortValue
  filterType?: ColumnFilterType
}

const collator = new Intl.Collator(undefined, {
  numeric: true,
  sensitivity: 'base',
})

function normalizeValue(value: SortValue) {
  if (value == null) return null
  if (typeof value === 'string') {
    const trimmed = value.trim()
    return trimmed.length ? trimmed : null
  }
  if (typeof value === 'boolean') return value ? 'true' : 'false'
  if (typeof value === 'number') return Number.isFinite(value) ? value : null
  return String(value)
}

function valueText(value: SortValue) {
  const normalized = normalizeValue(value)
  return normalized == null ? '' : String(normalized).toLowerCase()
}

function compareValues(left: SortValue, right: SortValue, direction: ColumnSortDirection) {
  const normalizedLeft = normalizeValue(left)
  const normalizedRight = normalizeValue(right)
  const multiplier = direction === 'asc' ? 1 : -1

  if (normalizedLeft == null && normalizedRight == null) return 0
  if (normalizedLeft == null) return 1 * multiplier
  if (normalizedRight == null) return -1 * multiplier

  if (typeof normalizedLeft === 'number' && typeof normalizedRight === 'number') {
    return (normalizedLeft - normalizedRight) * multiplier
  }

  return collator.compare(String(normalizedLeft), String(normalizedRight)) * multiplier
}

export function useColumnTableControls<T, K extends string>(
  sourceRows: TableSource<T>,
  columns: Array<ColumnControlDefinition<T, K>>,
  initialSortKey: K,
  initialDirection: ColumnSortDirection = 'asc',
) {
  const sortKey = ref<K>(initialSortKey)
  const sortDirection = ref<ColumnSortDirection>(initialDirection)
  const columnFilters = reactive<Record<string, string>>({})
  const columnMap = computed(() => new Map(columns.map((column) => [column.key, column])))

  columns.forEach((column) => {
    columnFilters[column.key] = ''
  })

  const filteredRows = computed<T[]>(() => {
    const activeColumns = columns.filter((column) => {
      const value = columnFilters[column.key]?.trim()
      return Boolean(value && column.filterType !== 'none')
    })
    if (!activeColumns.length) return [...unref(sourceRows)]

    return unref(sourceRows).filter((row) =>
      activeColumns.every((column) => {
        const filter = columnFilters[column.key].trim().toLowerCase()
        const rawValue = (column.filterValue ?? column.sortValue)?.(row)
        const rowText = valueText(rawValue)
        if (column.filterType === 'select') return rowText === filter
        return rowText.includes(filter)
      }),
    )
  })

  const sortedRows = computed<T[]>(() => {
    const currentKey = sortKey.value as K
    const column = columnMap.value.get(currentKey)
    const accessor = column?.sortValue ?? column?.filterValue
    const list = filteredRows.value.map((row, index) => ({ row, index }))

    if (!accessor) return list.map((entry) => entry.row)

    list.sort((left, right) => {
      const result = compareValues(accessor(left.row), accessor(right.row), sortDirection.value)
      return result !== 0 ? result : left.index - right.index
    })

    return list.map((entry) => entry.row)
  })

  const hasColumnFilters = computed(() =>
    columns.some((column) => (columnFilters[column.key] ?? '').trim().length > 0),
  )

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

  function clearColumnFilters() {
    columns.forEach((column) => {
      columnFilters[column.key] = ''
    })
  }

  return {
    sortKey,
    sortDirection,
    columnFilters,
    filteredRows,
    sortedRows,
    hasColumnFilters,
    setSort,
    sortIcon,
    clearColumnFilters,
  }
}
