<template>
  <Modal :fullScreenBackdrop="true" @close="emit('close')">
    <template #body>
      <div class="relative z-[100000] w-full max-w-[96vw] px-4 py-6">
        <section
          ref="dialogRef"
          class="mx-auto max-h-[88vh] overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-2xl"
          role="dialog"
          aria-modal="true"
          tabindex="-1"
          :aria-label="t('typeDefGraphModal.title')"
          @keydown.capture="handleDialogKeydown"
        >
          <header class="flex flex-col gap-3 border-b border-gray-200 px-5 py-4 md:flex-row md:items-start md:justify-between">
            <div>
              <h2 class="text-lg font-semibold text-gray-900">{{ t('typeDefGraphModal.title') }}</h2>
              <p class="text-sm text-gray-500">{{ t('typeDefGraphModal.subtitle') }}</p>
            </div>
            <div class="flex items-center gap-2">
              <span class="hidden rounded-full border border-gray-200 px-3 py-1 text-xs text-gray-500 md:inline-flex">
                {{ t('typeDefGraphModal.shortcuts.closeHint') }}
              </span>
              <button
                class="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
                type="button"
                @click="emit('close')"
              >
                {{ t('common.close') }}
              </button>
            </div>
          </header>

          <div class="space-y-4 overflow-y-auto px-5 py-4">
            <section class="rounded-xl border border-gray-200 bg-gray-50/80 p-4">
              <div class="grid grid-cols-1 gap-4 xl:grid-cols-[240px_minmax(0,1fr)_auto]">
                <div>
                  <label class="mb-1 block text-sm text-gray-600">{{ t('typeDefGraphModal.fields.domain') }}</label>
                  <select
                    v-model="selectedDomain"
                    class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
                  >
                    <option v-for="option in domainOptions" :key="option.value" :value="option.value">
                      {{ option.label }}
                    </option>
                  </select>
                  <p class="mt-2 text-xs text-gray-500">{{ t('typeDefGraphModal.fields.domainHint') }}</p>
                </div>

                <div>
                  <label class="mb-1 block text-sm text-gray-600">{{ t('typeDefGraphModal.fields.search') }}</label>
                  <input
                    ref="searchInputRef"
                    v-model.trim="searchQuery"
                    type="text"
                    class="h-[40px] w-full rounded border border-gray-300 bg-white px-3"
                    :placeholder="t('typeDefGraphModal.fields.searchPlaceholder')"
                  />
                  <p class="mt-2 text-xs text-gray-500">{{ t('typeDefGraphModal.fields.searchHint') }}</p>
                </div>

                <div class="flex flex-wrap items-end gap-2 xl:justify-end">
                  <button
                    class="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50 disabled:opacity-50"
                    type="button"
                    :disabled="loading"
                    @click="refreshBrowser"
                  >
                    {{ t('common.refresh') }}
                  </button>
                </div>
              </div>
            </section>

            <div v-if="loading" class="rounded-xl border border-gray-200 px-4 py-10 text-center text-sm text-gray-500">
              {{ t('common.loading') }}
            </div>
            <div v-else-if="errorMessage" class="rounded-xl border border-red-200 bg-red-50 px-4 py-4 text-sm text-red-700">
              {{ errorMessage }}
            </div>
            <div v-else-if="rootRows.length === 0" class="rounded-xl border border-gray-200 px-4 py-10 text-center text-sm text-gray-500">
              {{ t('typeDefGraphModal.empty') }}
            </div>
            <section v-else class="rounded-xl border border-gray-200 bg-white p-4">
              <div class="mb-3 flex items-center justify-between gap-3">
                <div>
                  <h3 class="text-sm font-semibold text-gray-900">{{ t('typeDefGraphModal.browserTitle') }}</h3>
                  <p class="text-xs text-gray-500">{{ selectedDomainLabel }}</p>
                </div>
              </div>

              <div ref="columnsScrollRef" class="overflow-x-auto pb-2">
                <div class="flex min-w-max gap-3">
                  <section
                    v-for="(column, columnIndex) in browserColumns"
                    :key="column.key"
                    class="w-[230px] shrink-0 rounded-xl border border-gray-200 bg-slate-50/70"
                  >
                    <header class="border-b border-gray-200 px-3 py-2">
                      <div class="truncate text-xs font-semibold uppercase tracking-wide text-gray-500">
                        {{ column.title }}
                      </div>
                    </header>
                    <div class="max-h-[60vh] space-y-1 overflow-y-auto p-2">
                      <button
                        v-for="row in column.rows"
                        :key="row.type_id"
                        type="button"
                        class="flex w-full items-start gap-2 rounded-lg border px-2.5 py-2 text-left transition"
                        :class="rowButtonClass(row, columnIndex)"
                        @click="selectColumnRow(columnIndex, row.type_id)"
                        @dblclick="selectTypeRow(row)"
                      >
                        <span
                          class="mt-1 h-2 w-2 shrink-0 rounded-full"
                          :class="row.is_active ? 'bg-emerald-500' : 'bg-slate-300'"
                        ></span>
                        <div class="min-w-0 flex-1">
                          <div class="break-words text-sm font-medium leading-tight text-gray-900">
                            {{ displayTypeName(row) }}
                          </div>
                          <div class="mt-1 flex items-center gap-2">
                            <span class="truncate font-mono text-[11px] text-gray-400">{{ row.code }}</span>
                            <span
                              v-if="childrenCount(row.type_id) > 0"
                              class="shrink-0 rounded-full bg-gray-100 px-1.5 py-0.5 text-[10px] text-gray-500"
                            >
                              {{ childrenCount(row.type_id) }}
                            </span>
                          </div>
                        </div>
                      </button>
                    </div>
                  </section>
                </div>
              </div>
            </section>
          </div>
        </section>
      </div>
    </template>
  </Modal>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import Modal from '@/components/ui/Modal.vue'
import { useTypeDefGraphModal, type TypeDefGraphSelection } from '@/composables/useTypeDefGraphModal'
import { supabase } from '@/lib/supabase'

type NameI18n = Record<string, string> | null

type TypeRow = {
  type_id: string
  domain: string
  code: string
  name: string
  name_i18n: NameI18n
  parent_type_id: string | null
  sort_order: number | null
  is_active: boolean
}

type DomainOption = {
  value: string
  label: string
}

type BrowserColumn = {
  key: string
  title: string
  rows: TypeRow[]
}

const BUILTIN_DOMAINS = ['material_type', 'equipment_type'] as const
const INDUSTRY_CODE = 'CRAFT_BEER'

const emit = defineEmits<{
  close: []
  select: [row: TypeDefGraphSelection]
}>()

const { t, locale } = useI18n()
const { typeDefGraphOptions } = useTypeDefGraphModal()

const dialogRef = ref<HTMLElement | null>(null)
const searchInputRef = ref<HTMLInputElement | null>(null)
const columnsScrollRef = ref<HTMLElement | null>(null)

const industryId = ref<string | null>(null)
const selectedDomain = ref(typeDefGraphOptions.value.preferredDomain || 'material_type')
const searchQuery = ref('')
const domainOptions = ref<DomainOption[]>([])
const typeRows = ref<TypeRow[]>([])
const selectedPath = ref<string[]>([])
const loading = ref(false)
const errorMessage = ref('')

const rowById = computed(() => {
  const map = new Map<string, TypeRow>()
  for (const row of typeRows.value) map.set(row.type_id, row)
  return map
})

const childrenByParent = computed(() => {
  const map = new Map<string | null, TypeRow[]>()
  for (const row of typeRows.value) {
    const parentId = rowById.value.has(row.parent_type_id ?? '') ? row.parent_type_id : null
    const bucket = map.get(parentId) ?? []
    bucket.push(row)
    map.set(parentId, bucket)
  }
  for (const [key, rows] of map.entries()) {
    map.set(key, sortRows(rows))
  }
  return map
})

const rootRows = computed(() => childrenByParent.value.get(null) ?? [])
const selectedNode = computed(() => {
  const lastId = selectedPath.value[selectedPath.value.length - 1]
  return lastId ? rowById.value.get(lastId) ?? null : null
})
const selectedPathRows = computed(() => selectedPath.value.map((id) => rowById.value.get(id)).filter(isTypeRow))
const selectedDomainLabel = computed(() => {
  const matched = domainOptions.value.find((entry) => entry.value === selectedDomain.value)
  return matched?.label || selectedDomain.value
})

const searchMatches = computed(() => {
  if (!hasSearchQuery.value) return [] as TypeRow[]
  const query = normalizeText(searchQuery.value)
  return typeRows.value.filter((row) => matchesRow(row, query))
})
const hasSearchQuery = computed(() => Boolean(searchQuery.value.trim()))
const matchedRowIds = computed(() => new Set(searchMatches.value.map((row) => row.type_id)))

const browserColumns = computed<BrowserColumn[]>(() => {
  const columns: BrowserColumn[] = [
    {
      key: 'root',
      title: t('typeDefGraphModal.columns.root'),
      rows: rootRows.value,
    },
  ]

  for (const row of selectedPathRows.value) {
    const childRows = childrenByParent.value.get(row.type_id) ?? []
    if (childRows.length === 0) break
    columns.push({
      key: row.type_id,
      title: displayTypeName(row),
      rows: childRows,
    })
  }

  return columns
})

function isTypeRow(value: TypeRow | undefined | null): value is TypeRow {
  return Boolean(value)
}

function isJsonObject(value: unknown): value is Record<string, unknown> {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value)
}

function normalizeText(value: string) {
  return value.trim().toLocaleLowerCase()
}

function sortRows(rows: TypeRow[]) {
  return [...rows].sort((left, right) => {
    const leftSort = left.sort_order ?? 0
    const rightSort = right.sort_order ?? 0
    if (leftSort !== rightSort) return leftSort - rightSort
    return left.code.localeCompare(right.code)
  })
}

function formatDomainLabel(domain: string) {
  if (domain === 'material_type') return t('materialType.domains.materialType')
  if (domain === 'equipment_type') return t('materialType.domains.equipmentType')
  return domain
}

function displayTypeName(row: Pick<TypeRow, 'name' | 'code' | 'name_i18n'> | null) {
  if (!row) return ''
  const isJa = locale.value.startsWith('ja')
  const ja = row.name_i18n?.ja?.trim()
  const en = row.name_i18n?.en?.trim()
  if (isJa) return ja || row.name || en || row.code
  return en || row.name || ja || row.code
}

function childrenCount(typeId: string) {
  return (childrenByParent.value.get(typeId) ?? []).length
}

function matchesRow(row: TypeRow, query: string) {
  if (!query) return true
  const values = [
    row.code,
    row.name,
    row.name_i18n?.ja ?? '',
    row.name_i18n?.en ?? '',
  ]
  return values.some((value) => normalizeText(value).includes(query))
}

function buildPathForRow(rowId: string) {
  const path: string[] = []
  const visited = new Set<string>()
  let currentId: string | null = rowId

  while (currentId && !visited.has(currentId)) {
    const row = rowById.value.get(currentId)
    if (!row) break
    visited.add(currentId)
    path.unshift(row.type_id)
    currentId = row.parent_type_id && rowById.value.has(row.parent_type_id) ? row.parent_type_id : null
  }

  return path
}

function selectPath(path: string[]) {
  selectedPath.value = path.filter((id) => rowById.value.has(id))
}

function ensureDefaultSelection() {
  if (rootRows.value.length === 0) {
    selectedPath.value = []
    return
  }

  if (selectedPath.value.length === 0) {
    selectedPath.value = [rootRows.value[0].type_id]
    return
  }

  const currentId = selectedPath.value[selectedPath.value.length - 1]
  if (!currentId || !rowById.value.has(currentId)) {
    selectedPath.value = [rootRows.value[0].type_id]
    return
  }

  selectPath(buildPathForRow(currentId))
}

function selectColumnRow(columnIndex: number, rowId: string) {
  const nextPath = [...selectedPath.value.slice(0, columnIndex), rowId]
  selectPath(nextPath)
}

function currentColumnRows() {
  if (selectedPath.value.length <= 1) return rootRows.value
  const parentId = selectedPath.value[selectedPath.value.length - 2]
  return childrenByParent.value.get(parentId) ?? []
}

function moveSelection(offset: number) {
  const rows = currentColumnRows()
  if (rows.length === 0) return

  const currentId = selectedPath.value[selectedPath.value.length - 1]
  const currentIndex = rows.findIndex((row) => row.type_id === currentId)
  const nextIndex = currentIndex >= 0 ? Math.min(Math.max(currentIndex + offset, 0), rows.length - 1) : 0

  if (selectedPath.value.length <= 1) {
    selectedPath.value = [rows[nextIndex].type_id]
    return
  }

  const prefix = selectedPath.value.slice(0, -1)
  selectedPath.value = [...prefix, rows[nextIndex].type_id]
}

function moveToChild() {
  if (!selectedNode.value) return
  const children = childrenByParent.value.get(selectedNode.value.type_id) ?? []
  if (children.length === 0) return
  selectedPath.value = [...selectedPath.value, children[0].type_id]
}

function moveToParent() {
  if (selectedPath.value.length <= 1) return
  selectedPath.value = selectedPath.value.slice(0, -1)
}

function rowButtonClass(row: TypeRow, columnIndex: number) {
  const isSelected = selectedPath.value[columnIndex] === row.type_id
  const isMatched = matchedRowIds.value.has(row.type_id)

  if (isSelected) {
    return 'border-blue-200 bg-blue-50'
  }
  if (isMatched) {
    return 'border-amber-200 bg-amber-50/70 hover:border-amber-300'
  }
  return 'border-transparent bg-white hover:border-gray-200 hover:bg-gray-50'
}

function selectTypeRow(row: TypeRow) {
  emit('select', {
    typeId: row.type_id,
    domain: row.domain,
    code: row.code,
    name: displayTypeName(row),
    isActive: row.is_active,
  })
}

function isInteractiveInputTarget(target: EventTarget | null) {
  if (!(target instanceof HTMLElement)) return false
  const tag = target.tagName
  return tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT' || target.isContentEditable
}

function handleDialogKeydown(event: KeyboardEvent) {
  if (event.key === 'Escape') {
    event.preventDefault()
    emit('close')
    return
  }

  if (isInteractiveInputTarget(event.target)) return

  if (event.key === 'ArrowDown') {
    event.preventDefault()
    moveSelection(1)
    return
  }

  if (event.key === 'ArrowUp') {
    event.preventDefault()
    moveSelection(-1)
    return
  }

  if (event.key === 'ArrowRight') {
    event.preventDefault()
    moveToChild()
    return
  }

  if (event.key === 'ArrowLeft') {
    event.preventDefault()
    moveToParent()
  }
}

async function ensureIndustry() {
  if (industryId.value) return industryId.value

  const { data, error } = await supabase
    .from('industry')
    .select('industry_id, code')
    .eq('code', INDUSTRY_CODE)
    .eq('is_active', true)
    .limit(1)

  if (error) throw error
  const matched = data?.[0]?.industry_id ?? null
  if (matched) {
    industryId.value = matched
    return matched
  }

  const { data: fallback, error: fallbackError } = await supabase
    .from('industry')
    .select('industry_id')
    .eq('is_active', true)
    .order('sort_order', { ascending: true })
    .limit(1)

  if (fallbackError) throw fallbackError
  industryId.value = fallback?.[0]?.industry_id ?? null
  if (!industryId.value) throw new Error(t('typeDefGraphModal.errors.industryMissing'))
  return industryId.value
}

async function loadDomains() {
  const industry = await ensureIndustry()
  const { data, error } = await supabase
    .from('type_def')
    .select('domain')
    .eq('industry_id', industry)
    .order('domain', { ascending: true })

  if (error) throw error

  const values = new Set<string>(BUILTIN_DOMAINS)
  for (const row of data ?? []) {
    if (typeof row.domain === 'string' && row.domain.trim()) {
      values.add(row.domain.trim())
    }
  }
  values.add(selectedDomain.value)

  domainOptions.value = Array.from(values)
    .sort((left, right) => left.localeCompare(right))
    .map((value) => ({
      value,
      label: formatDomainLabel(value),
    }))
}

async function loadTypes() {
  loading.value = true
  errorMessage.value = ''

  try {
    const industry = await ensureIndustry()
    const { data, error } = await supabase
      .from('type_def')
      .select('type_id, domain, code, name, name_i18n, parent_type_id, sort_order, is_active')
      .eq('domain', selectedDomain.value)
      .eq('industry_id', industry)
      .order('sort_order', { ascending: true })
      .order('code', { ascending: true })

    if (error) throw error

    typeRows.value = (data ?? []).map((row) => ({
      ...(row as TypeRow),
      name_i18n: isJsonObject(row.name_i18n) ? (row.name_i18n as NameI18n) : null,
    }))
    ensureDefaultSelection()
  } catch (error: unknown) {
    typeRows.value = []
    selectedPath.value = []
    errorMessage.value = t('typeDefGraphModal.errors.loadFailed', {
      message: error instanceof Error ? error.message : String(error),
    })
  } finally {
    loading.value = false
  }
}

async function loadBrowser() {
  await loadDomains()
  await loadTypes()
}

async function refreshBrowser() {
  await loadBrowser()
}

async function focusFirstField() {
  await nextTick()
  if (searchInputRef.value) {
    searchInputRef.value.focus()
    searchInputRef.value.select()
    return
  }
  dialogRef.value?.focus()
}

watch(selectedDomain, async (next, previous) => {
  if (!next || next === previous) return
  selectedPath.value = []
  await loadTypes()
})

watch(selectedPath, async () => {
  await nextTick()
  if (!columnsScrollRef.value) return
  columnsScrollRef.value.scrollLeft = columnsScrollRef.value.scrollWidth
})

onMounted(async () => {
  await loadBrowser()
  await focusFirstField()
})

defineExpose({
  focusFirstField,
})
</script>
