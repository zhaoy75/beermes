<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div v-if="loadingBatch" class="p-6 text-sm text-gray-500">{{ t('common.loading') }}</div>
    <div v-else-if="!batch" class="p-6 text-sm text-red-600">{{ t('batch.edit.notFound') }}</div>
    <section v-else class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5 space-y-3">
      <header class="flex items-start justify-between gap-3">
        <div>
          <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.edit.lotDagDialogTitle') }}</h2>
          <p class="text-xs text-gray-500">{{ t('batch.edit.lotDagDialogSubtitle') }}</p>
          <p class="text-xs text-gray-500 mt-1">{{ batchSummaryText }}</p>
        </div>
        <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="goBack">
          {{ t('batch.edit.lotDagBackButton') }}
        </button>
      </header>

      <div v-if="lotDag.globalError" class="text-sm text-red-600">{{ lotDag.globalError }}</div>
      <div v-else-if="lotDag.loading" class="text-sm text-gray-600">{{ t('common.loading') }}</div>
      <div v-else-if="lotDag.renderNodes.length === 0" class="text-sm text-gray-500">{{ t('batch.edit.lotDagNoData') }}</div>
      <div
        v-else
        class="border border-gray-200 rounded-lg overflow-auto select-none"
        style="max-height: 70vh;"
      >
        <svg
          ref="graphSvg"
          :width="lotDag.canvasWidth"
          :height="lotDag.canvasHeight"
          class="bg-white"
          style="touch-action: none;"
          @pointermove="handleNodeDrag"
          @pointerup="endNodeDrag"
          @pointercancel="endNodeDrag"
        >
          <defs>
            <marker
              id="lot-dag-arrowhead"
              markerWidth="8"
              markerHeight="8"
              refX="7"
              refY="4"
              orient="auto"
              markerUnits="strokeWidth"
            >
              <path d="M 0 0 L 8 4 L 0 8 z" fill="#94a3b8" />
            </marker>
          </defs>
          <g>
            <line
              v-for="edge in lotDag.renderEdges"
              :key="edge.id"
              :x1="edge.x1"
              :y1="edge.y1"
              :x2="edge.x2"
              :y2="edge.y2"
              stroke="#94a3b8"
              stroke-width="1.5"
              marker-end="url(#lot-dag-arrowhead)"
            />
            <text
              v-for="edge in lotDag.renderEdges"
              :key="`${edge.id}-label`"
              :x="(edge.x1 + edge.x2) / 2"
              :y="(edge.y1 + edge.y2) / 2 - 4"
              text-anchor="middle"
              font-size="10"
              fill="#475569"
            >
              {{ edge.label }}
            </text>
            <template v-for="edge in lotDag.renderEdges" :key="`${edge.id}-sub-label`">
              <text
                v-if="edge.subLabel"
                :x="(edge.x1 + edge.x2) / 2"
                :y="(edge.y1 + edge.y2) / 2 + 10"
                text-anchor="middle"
                font-size="9"
                fill="#64748b"
              >
                {{ edge.subLabel }}
              </text>
            </template>
          </g>
          <g>
            <g
              v-for="node in lotDag.renderNodes"
              :key="node.id"
              class="cursor-grab"
              :class="{ 'cursor-grabbing': dragState.nodeId === node.id }"
              @pointerdown.stop="beginNodeDrag(node.id, $event)"
            >
              <rect
                :x="node.x - 85"
                :y="node.y - 32"
                width="170"
                height="64"
                rx="8"
                :fill="node.id === lotDag.sourceLotId ? '#dcfce7' : (node.virtual ? '#f8fafc' : '#eff6ff')"
                stroke="#64748b"
              />
              <text :x="node.x" :y="node.y - 12" text-anchor="middle" font-size="12" fill="#0f172a">
                {{ node.label }}
              </text>
              <text v-if="node.subLabel" :x="node.x" :y="node.y + 4" text-anchor="middle" font-size="10" fill="#475569">
                {{ node.subLabel }}
              </text>
              <text v-if="node.metaLabel" :x="node.x" :y="node.y + 20" text-anchor="middle" font-size="10" fill="#475569">
                {{ node.metaLabel }}
              </text>
            </g>
          </g>
        </svg>
      </div>
    </section>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { formatRpcErrorMessage } from '@/lib/rpcErrors'
import { supabase } from '@/lib/supabase'

type LotDagNode = {
  id: string
  lot_no: string | null
  site_name: string | null
  lot_tax_type: string | null
  qty: number | null
  status: string | null
}

type LotDagEdge = {
  id: string
  source: string | null
  target: string | null
  edge_type: string | null
  movement_tax_type: string | null
  qty: number | null
}

type LotDagRenderNode = {
  id: string
  label: string
  subLabel: string
  metaLabel: string
  x: number
  y: number
  virtual: boolean
}

type LotDagRenderEdge = {
  id: string
  x1: number
  y1: number
  x2: number
  y2: number
  label: string
  subLabel: string
}

const route = useRoute()
const router = useRouter()
const { t } = useI18n()

const batchId = computed(() => route.params.batchId as string | undefined)
const fromPage = computed(() => (typeof route.query.from === 'string' ? route.query.from : 'edit'))
const pageTitle = computed(() => t('batch.edit.lotDagButton'))
const loadingBatch = ref(false)
const batch = ref<Record<string, unknown> | null>(null)
const graphSvg = ref<SVGSVGElement | null>(null)

const dragState = reactive({
  pointerId: null as number | null,
  nodeId: null as string | null,
  startClientX: 0,
  startClientY: 0,
  nodeStartX: 0,
  nodeStartY: 0,
})

const lotDag = reactive({
  loading: false,
  globalError: '',
  sourceLotId: null as string | null,
  nodes: [] as LotDagNode[],
  edges: [] as LotDagEdge[],
  renderNodes: [] as LotDagRenderNode[],
  renderEdges: [] as LotDagRenderEdge[],
  canvasWidth: 1200,
  canvasHeight: 640,
})

const batchSummaryText = computed(() => {
  const code = toDisplayString(batch.value?.batch_code) || '—'
  const name = toDisplayString(batch.value?.batch_label)
    || toDisplayString(batch.value?.product_name)
    || '—'
  return `${code} / ${name}`
})

watch(batchId, () => {
  void fetchBatchAndDag()
}, { immediate: true })

async function goBack() {
  if (!batchId.value) return
  if (fromPage.value === 'packing') {
    await router.push({ name: 'batchPacking', params: { batchId: batchId.value } })
    return
  }
  await router.push({ name: 'batchEdit', params: { batchId: batchId.value } })
}

async function fetchBatchAndDag() {
  if (!batchId.value) return
  loadingBatch.value = true
  try {
    const { data, error } = await supabase.rpc('batch_get_detail', { p_batch_id: batchId.value })
    if (error) throw error
    const detail = toRecord(data)
    batch.value = toRecord(detail?.batch)
    await loadLotDag()
  } catch (err) {
    console.error(err)
    batch.value = null
  } finally {
    loadingBatch.value = false
  }
}

async function loadLotDag() {
  if (!batchId.value) return
  lotDag.loading = true
  lotDag.globalError = ''
  lotDag.nodes = []
  lotDag.edges = []
  lotDag.renderNodes = []
  lotDag.renderEdges = []
  lotDag.sourceLotId = null
  try {
    const { data, error } = await supabase.rpc('lot_dag_get_by_batch', { p_batch_id: batchId.value })
    if (error) throw error
    const payload = Array.isArray(data)
      ? (toRecord(data[0]) ?? {})
      : (toRecord(data) ?? {})
    lotDag.sourceLotId = typeof payload.source_lot_id === 'string' ? payload.source_lot_id : null
    lotDag.nodes = Array.isArray(payload.nodes)
      ? payload.nodes.map((value): LotDagNode | null => {
        const row = toRecord(value)
        if (!row) return null
        return {
          id: String(row.id ?? ''),
          lot_no: toDisplayString(row.lot_no),
          site_name: toDisplayString(row.site_name),
          lot_tax_type: toDisplayString(row.lot_tax_type),
          qty: toNumber(row.qty),
          status: toDisplayString(row.status),
        }
      }).filter((row): row is LotDagNode => Boolean(row?.id))
      : []
    lotDag.edges = Array.isArray(payload.edges)
      ? payload.edges.map((value): LotDagEdge | null => {
        const row = toRecord(value)
        if (!row) return null
        return {
          id: toDisplayString(row.id) || generateLocalId(),
          source: toDisplayString(row.source),
          target: toDisplayString(row.target),
          edge_type: toDisplayString(row.edge_type),
          movement_tax_type: toDisplayString(row.movement_tax_type),
          qty: toNumber(row.qty),
        }
      }).filter((row): row is LotDagEdge => Boolean(row))
      : []
    buildLotDagLayout()
  } catch (err) {
    console.error(err)
    lotDag.globalError = formatRpcErrorMessage(err, {
      fallbackKey: 'batch.edit.lotDagLoadFailed',
    })
  } finally {
    lotDag.loading = false
  }
}

function buildLotDagLayout() {
  const nodeMap = new Map<string, LotDagNode>()
  const childrenMap = new Map<string, Set<string>>()
  const parentMap = new Map<string, Set<string>>()
  const incomingCount = new Map<string, number>()
  const sourceNodes = new Set<string>()
  const targetNodes = new Set<string>()

  lotDag.nodes.forEach((node) => {
    nodeMap.set(node.id, node)
    childrenMap.set(node.id, new Set())
    parentMap.set(node.id, new Set())
    incomingCount.set(node.id, 0)
  })

  ;(lotDag.edges ?? []).forEach((edge) => {
    if (!edge.source || !edge.target) return
    if (!nodeMap.has(edge.source) || !nodeMap.has(edge.target)) return
    childrenMap.get(edge.source)?.add(edge.target)
    parentMap.get(edge.target)?.add(edge.source)
    incomingCount.set(edge.target, (incomingCount.get(edge.target) ?? 0) + 1)
    sourceNodes.add(edge.source)
    targetNodes.add(edge.target)
  })

  const roots = Array.from(nodeMap.keys()).filter((id) => (incomingCount.get(id) ?? 0) === 0)
  const queue = [...roots]
  const levelMap = new Map<string, number>()
  roots.forEach((id) => levelMap.set(id, 0))
  while (queue.length) {
    const current = queue.shift() as string
    const currentLevel = levelMap.get(current) ?? 0
    const children = Array.from(childrenMap.get(current) ?? [])
    children.forEach((child) => {
      const nextLevel = currentLevel + 1
      if (!levelMap.has(child) || (levelMap.get(child) as number) < nextLevel) {
        levelMap.set(child, nextLevel)
      }
      queue.push(child)
    })
  }

  const connectedNodeIds = new Set<string>([...sourceNodes, ...targetNodes])
  const isolatedNodes = Array.from(nodeMap.keys()).filter((id) => !connectedNodeIds.has(id))
  const maxLevel = Math.max(0, ...Array.from(levelMap.values()))
  isolatedNodes.forEach((id, index) => {
    levelMap.set(id, maxLevel + 1 + index)
  })

  const levels = new Map<number, string[]>()
  Array.from(nodeMap.keys()).forEach((id) => {
    const lvl = levelMap.get(id) ?? 0
    const list = levels.get(lvl) ?? []
    list.push(id)
    levels.set(lvl, list)
  })

  const levelKeys = Array.from(levels.keys()).sort((a, b) => a - b)
  const fallbackOrder = new Map<string, number>()
  levelKeys.forEach((level) => {
    const ids = levels.get(level) ?? []
    ids.sort((a, b) => {
      if (a === lotDag.sourceLotId) return -1
      if (b === lotDag.sourceLotId) return 1
      return a.localeCompare(b)
    })
    ids.forEach((id, index) => fallbackOrder.set(id, index))
  })

  const buildPositionMap = () => {
    const positions = new Map<string, number>()
    levelKeys.forEach((level) => {
      const ids = levels.get(level) ?? []
      ids.forEach((id, index) => positions.set(id, index))
    })
    return positions
  }

  const getNeighborAverage = (
    id: string,
    compare: (neighborLevel: number, currentLevel: number) => boolean,
    neighbors: Map<string, Set<string>>,
    positions: Map<string, number>,
  ) => {
    const currentLevel = levelMap.get(id) ?? 0
    const values = Array.from(neighbors.get(id) ?? [])
      .filter((neighborId) => {
        const neighborLevel = levelMap.get(neighborId)
        return neighborLevel != null && compare(neighborLevel, currentLevel)
      })
      .map((neighborId) => positions.get(neighborId))
      .filter((value): value is number => value != null)
    if (values.length === 0) return null
    return values.reduce((sum, value) => sum + value, 0) / values.length
  }

  const sortLevel = (
    level: number,
    positions: Map<string, number>,
    compare: (neighborLevel: number, currentLevel: number) => boolean,
    neighbors: Map<string, Set<string>>,
  ) => {
    const ids = [...(levels.get(level) ?? [])]
    ids.sort((a, b) => {
      if (a === lotDag.sourceLotId) return -1
      if (b === lotDag.sourceLotId) return 1
      const aAvg = getNeighborAverage(a, compare, neighbors, positions)
      const bAvg = getNeighborAverage(b, compare, neighbors, positions)
      if (aAvg != null && bAvg != null && aAvg !== bAvg) return aAvg - bAvg
      if (aAvg != null && bAvg == null) return -1
      if (aAvg == null && bAvg != null) return 1
      const aFallback = fallbackOrder.get(a) ?? 0
      const bFallback = fallbackOrder.get(b) ?? 0
      if (aFallback !== bFallback) return aFallback - bFallback
      return a.localeCompare(b)
    })
    levels.set(level, ids)
  }

  for (let pass = 0; pass < 4; pass += 1) {
    let positions = buildPositionMap()
    for (let idx = 1; idx < levelKeys.length; idx += 1) {
      sortLevel(levelKeys[idx], positions, (neighborLevel, currentLevel) => neighborLevel < currentLevel, parentMap)
      positions = buildPositionMap()
    }
    for (let idx = levelKeys.length - 2; idx >= 0; idx -= 1) {
      sortLevel(levelKeys[idx], positions, (neighborLevel, currentLevel) => neighborLevel > currentLevel, childrenMap)
      positions = buildPositionMap()
    }
  }

  const xSpacing = 250
  const ySpacing = 100
  const baseX = 130
  const baseY = 70
  const renderNodeMap = new Map<string, LotDagRenderNode>()

  levelKeys.forEach((level) => {
    const ids = levels.get(level) ?? []
    ids.forEach((id, index) => {
      const row = nodeMap.get(id)
      const x = baseX + level * xSpacing
      const y = baseY + index * ySpacing
      const qtyLabel = row?.qty != null ? row.qty.toLocaleString(undefined, { maximumFractionDigits: 3 }) : '—'
      const statusLabel = row?.status ?? '—'
      const siteLabel = row?.site_name ?? '—'
      const taxLabel = row?.lot_tax_type ?? '—'
      renderNodeMap.set(id, {
        id,
        label: row?.lot_no ?? id,
        subLabel: `${qtyLabel} / ${statusLabel}`,
        metaLabel: `${siteLabel} / ${taxLabel}`,
        x,
        y,
        virtual: false,
      })
    })
  })

  const renderNodes = Array.from(renderNodeMap.values())
  const renderEdges: LotDagRenderEdge[] = []

  ;(lotDag.edges ?? []).forEach((edge) => {
    if (!edge.source || !edge.target) return
    const from = renderNodeMap.get(edge.source)
    const to = renderNodeMap.get(edge.target)
    if (!from || !to) return
    const qtyLabel = edge.qty != null ? edge.qty.toLocaleString(undefined, { maximumFractionDigits: 3 }) : ''
    const typeLabel = edge.edge_type ?? ''
    const movementTaxTypeLabel = edge.movement_tax_type ?? ''
    renderEdges.push({
      id: edge.id,
      x1: from.x + 85,
      y1: from.y,
      x2: to.x - 85,
      y2: to.y,
      label: [typeLabel, qtyLabel].filter(Boolean).join(' / '),
      subLabel: movementTaxTypeLabel,
    })
  })

  const maxX = renderNodes.reduce((max, node) => Math.max(max, node.x + 120), 960)
  const maxY = renderNodes.reduce((max, node) => Math.max(max, node.y + 90), 420)
  lotDag.renderNodes = renderNodes
  lotDag.renderEdges = renderEdges
  lotDag.canvasWidth = Math.max(960, maxX)
  lotDag.canvasHeight = Math.max(420, maxY)
}

function recalculateRenderEdges() {
  const renderNodeMap = new Map<string, LotDagRenderNode>(lotDag.renderNodes.map((node) => [node.id, node]))
  lotDag.renderEdges = (lotDag.edges ?? []).flatMap((edge) => {
    if (!edge.source || !edge.target) return []
    const from = renderNodeMap.get(edge.source)
    const to = renderNodeMap.get(edge.target)
    if (!from || !to) return []
    const qtyLabel = edge.qty != null ? edge.qty.toLocaleString(undefined, { maximumFractionDigits: 3 }) : ''
    const typeLabel = edge.edge_type ?? ''
    const movementTaxTypeLabel = edge.movement_tax_type ?? ''
    return [{
      id: edge.id,
      x1: from.x + 85,
      y1: from.y,
      x2: to.x - 85,
      y2: to.y,
      label: [typeLabel, qtyLabel].filter(Boolean).join(' / '),
      subLabel: movementTaxTypeLabel,
    }]
  })
}

function updateCanvasBounds() {
  const maxX = lotDag.renderNodes.reduce((max, node) => Math.max(max, node.x + 120), 960)
  const maxY = lotDag.renderNodes.reduce((max, node) => Math.max(max, node.y + 90), 420)
  lotDag.canvasWidth = Math.max(960, maxX)
  lotDag.canvasHeight = Math.max(420, maxY)
}

function beginNodeDrag(nodeId: string, event: PointerEvent) {
  if (event.pointerType !== 'touch' && event.button !== 0) return
  const svg = graphSvg.value
  const node = lotDag.renderNodes.find((item) => item.id === nodeId)
  if (!svg || !node) return
  dragState.pointerId = event.pointerId
  dragState.nodeId = nodeId
  dragState.startClientX = event.clientX
  dragState.startClientY = event.clientY
  dragState.nodeStartX = node.x
  dragState.nodeStartY = node.y
  svg.setPointerCapture(event.pointerId)
}

function handleNodeDrag(event: PointerEvent) {
  if (dragState.pointerId !== event.pointerId || !dragState.nodeId) return
  const node = lotDag.renderNodes.find((item) => item.id === dragState.nodeId)
  if (!node) return
  node.x = Math.max(100, dragState.nodeStartX + (event.clientX - dragState.startClientX))
  node.y = Math.max(50, dragState.nodeStartY + (event.clientY - dragState.startClientY))
  recalculateRenderEdges()
  updateCanvasBounds()
}

function endNodeDrag(event: PointerEvent) {
  if (dragState.pointerId !== event.pointerId) return
  const svg = graphSvg.value
  if (svg?.hasPointerCapture(event.pointerId)) {
    svg.releasePointerCapture(event.pointerId)
  }
  dragState.pointerId = null
  dragState.nodeId = null
}

function toNumber(value: unknown): number | null {
  if (value === null || value === undefined || value === '') return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function toRecord(value: unknown): Record<string, unknown> | null {
  return typeof value === 'object' && value !== null && !Array.isArray(value)
    ? value as Record<string, unknown>
    : null
}

function toDisplayString(value: unknown) {
  return value === null || value === undefined ? null : String(value)
}

function generateLocalId() {
  const rng = (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function')
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(16).slice(2)}`
  return `tmp-${rng}`
}

</script>
