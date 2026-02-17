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
      <div v-else class="border border-gray-200 rounded-lg overflow-auto" style="max-height: 70vh;">
        <svg :width="lotDag.canvasWidth" :height="lotDag.canvasHeight" class="bg-white">
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
          </g>
          <g>
            <g v-for="node in lotDag.renderNodes" :key="node.id">
              <rect
                :x="node.x - 85"
                :y="node.y - 24"
                width="170"
                height="48"
                rx="8"
                :fill="node.id === lotDag.sourceLotId ? '#dcfce7' : (node.virtual ? '#f8fafc' : '#eff6ff')"
                stroke="#64748b"
              />
              <text :x="node.x" :y="node.y - 4" text-anchor="middle" font-size="12" fill="#0f172a">
                {{ node.label }}
              </text>
              <text v-if="node.subLabel" :x="node.x" :y="node.y + 12" text-anchor="middle" font-size="10" fill="#475569">
                {{ node.subLabel }}
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
import { supabase } from '@/lib/supabase'

type LotDagNode = {
  id: string
  lot_no: string | null
  qty: number | null
  status: string | null
}

type LotDagEdge = {
  id: string
  source: string | null
  target: string | null
  edge_type: string | null
  qty: number | null
}

type LotDagRenderNode = {
  id: string
  label: string
  subLabel: string
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
}

const route = useRoute()
const router = useRouter()
const { t } = useI18n()

const batchId = computed(() => route.params.batchId as string | undefined)
const fromPage = computed(() => (typeof route.query.from === 'string' ? route.query.from : 'edit'))
const pageTitle = computed(() => t('batch.edit.lotDagButton'))
const loadingBatch = ref(false)
const batch = ref<any>(null)

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
  const code = batch.value?.batch_code ?? '—'
  const name = batch.value?.batch_label ?? batch.value?.product_name ?? '—'
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
    const detail = (data ?? null) as any
    batch.value = detail?.batch ?? null
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
      ? ((data[0] && typeof data[0] === 'object') ? data[0] as Record<string, any> : {})
      : ((data && typeof data === 'object') ? data as Record<string, any> : {})
    lotDag.sourceLotId = typeof payload.source_lot_id === 'string' ? payload.source_lot_id : null
    lotDag.nodes = Array.isArray(payload.nodes)
      ? payload.nodes.map((row: any) => ({
        id: String(row?.id ?? ''),
        lot_no: row?.lot_no != null ? String(row.lot_no) : null,
        qty: toNumber(row?.qty),
        status: row?.status != null ? String(row.status) : null,
      })).filter((row: LotDagNode) => row.id)
      : []
    lotDag.edges = Array.isArray(payload.edges)
      ? payload.edges.map((row: any) => ({
        id: String(row?.id ?? generateLocalId()),
        source: row?.source != null ? String(row.source) : null,
        target: row?.target != null ? String(row.target) : null,
        edge_type: row?.edge_type != null ? String(row.edge_type) : null,
        qty: toNumber(row?.qty),
      }))
      : []
    buildLotDagLayout()
  } catch (err) {
    console.error(err)
    const detail = extractErrorMessage(err)
    lotDag.globalError = detail
      ? `${t('batch.edit.lotDagLoadFailed')} (${detail})`
      : t('batch.edit.lotDagLoadFailed')
  } finally {
    lotDag.loading = false
  }
}

function buildLotDagLayout() {
  const nodeMap = new Map<string, LotDagNode>()
  const childrenMap = new Map<string, Set<string>>()
  const incomingCount = new Map<string, number>()
  const sourceNodes = new Set<string>()
  const targetNodes = new Set<string>()

  lotDag.nodes.forEach((node) => {
    nodeMap.set(node.id, node)
    childrenMap.set(node.id, new Set())
    incomingCount.set(node.id, 0)
  })

  ;(lotDag.edges ?? []).forEach((edge) => {
    if (!edge.source || !edge.target) return
    if (!nodeMap.has(edge.source) || !nodeMap.has(edge.target)) return
    childrenMap.get(edge.source)?.add(edge.target)
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
  levels.forEach((ids) => {
    ids.sort((a, b) => {
      if (a === lotDag.sourceLotId) return -1
      if (b === lotDag.sourceLotId) return 1
      return a.localeCompare(b)
    })
  })

  const levelKeys = Array.from(levels.keys()).sort((a, b) => a - b)
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
      renderNodeMap.set(id, {
        id,
        label: row?.lot_no ?? id,
        subLabel: `${qtyLabel} / ${statusLabel}`,
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
    renderEdges.push({
      id: edge.id,
      x1: from.x + 85,
      y1: from.y,
      x2: to.x - 85,
      y2: to.y,
      label: [typeLabel, qtyLabel].filter(Boolean).join(' / '),
    })
  })

  const maxX = renderNodes.reduce((max, node) => Math.max(max, node.x + 120), 960)
  const maxY = renderNodes.reduce((max, node) => Math.max(max, node.y + 90), 420)
  lotDag.renderNodes = renderNodes
  lotDag.renderEdges = renderEdges
  lotDag.canvasWidth = Math.max(960, maxX)
  lotDag.canvasHeight = Math.max(420, maxY)
}

function toNumber(value: any): number | null {
  if (value === null || value === undefined || value === '') return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function generateLocalId() {
  const rng = (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function')
    ? crypto.randomUUID()
    : `${Date.now()}-${Math.random().toString(16).slice(2)}`
  return `tmp-${rng}`
}

function extractErrorMessage(err: unknown) {
  if (!err) return ''
  if (typeof err === 'string') return err
  if (err instanceof Error) return err.message
  const rec = err as Record<string, unknown>
  const message = rec.message
  if (typeof message === 'string' && message.trim()) return message
  const details = rec.details
  if (typeof details === 'string' && details.trim()) return details
  const hint = rec.hint
  if (typeof hint === 'string' && hint.trim()) return hint
  return ''
}
</script>
