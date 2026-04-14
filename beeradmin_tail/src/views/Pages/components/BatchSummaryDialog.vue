<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
    <div class="w-full max-w-3xl bg-white rounded-xl shadow-lg border border-gray-200">
      <header class="flex items-center justify-between px-4 py-3 border-b">
        <div>
          <h3 class="text-lg font-semibold text-gray-800">{{ t('batch.summary.title', { code: batch.batch_code }) }}</h3>
          <p class="text-xs text-gray-500">{{ t('batch.summary.subtitle') }}</p>
        </div>
        <button class="text-sm px-2 py-1 rounded border hover:bg-gray-100" type="button" @click="emit('close')">{{ t('common.close') }}</button>
      </header>

      <section class="max-h-[75vh] overflow-y-auto divide-y divide-gray-100">
        <div class="px-4 py-4">
          <h4 class="text-sm font-semibold uppercase text-gray-500 mb-2">{{ t('batch.summary.overview') }}</h4>
          <div v-if="loading" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
          <dl v-else class="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-2 text-sm">
            <div>
              <dt class="font-medium text-gray-600">{{ t('batch.summary.status') }}</dt>
              <dd class="text-gray-800">{{ detail?.status ?? '—' }}</dd>
            </div>
            <div>
              <dt class="font-medium text-gray-600">{{ t('batch.summary.recipe') }}</dt>
              <dd class="text-gray-800">{{ detailRecipeName }} <span v-if="detailRecipeCode" class="text-xs text-gray-500">({{ detailRecipeCode }})</span></dd>
            </div>
            <div>
              <dt class="font-medium text-gray-600">{{ t('batch.summary.plannedStart') }}</dt>
              <dd class="text-gray-800">{{ fmt(detail?.planned_start) }}</dd>
            </div>
            <!-- <div>
              <dt class="font-medium text-gray-600">{{ t('batch.summary.plannedEnd') }}</dt>
              <dd class="text-gray-800">{{ fmt(detail?.planned_end) }}</dd>
            </div>
            <div>
              <dt class="font-medium text-gray-600">{{ t('batch.summary.actualStart') }}</dt>
              <dd class="text-gray-800">{{ fmt(detail?.actual_start) }}</dd>
            </div>
            <div>
              <dt class="font-medium text-gray-600">{{ t('batch.summary.actualEnd') }}</dt>
              <dd class="text-gray-800">{{ fmt(detail?.actual_end) }}</dd>
            </div> -->
            <div>
              <dt class="font-medium text-gray-600">{{ t('batch.summary.targetVolume') }}</dt>
              <dd class="text-gray-800">{{ formatVolume(resolvePlannedVolume(detail?.kpi)) }}</dd>
            </div>
            <div class="md:col-span-2">
              <dt class="font-medium text-gray-600">{{ t('batch.summary.notes') }}</dt>
              <dd class="text-gray-800 whitespace-pre-line">{{ detail?.notes || '—' }}</dd>
            </div>
          </dl>
        </div>

        <div class="px-4 py-4">
          <h4 class="text-sm font-semibold uppercase text-gray-500 mb-2">{{ t('batch.summary.ingredients') }}</h4>
          <div v-if="loadingIngredients" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
          <table v-else class="min-w-full text-sm border border-gray-200 rounded-lg overflow-hidden">
            <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('batch.summary.ingredient') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.summary.amount') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.summary.usageStage') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.summary.notes') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="item in ingredients" :key="item.id" class="hover:bg-gray-50">
                <td class="px-3 py-2">{{ item.material_name }}</td>
                <td class="px-3 py-2 text-right">{{ item.amount }} {{ item.uom_code }}</td>
                <td class="px-3 py-2">{{ item.usage_stage || '—' }}</td>
                <td class="px-3 py-2">{{ item.notes || '—' }}</td>
              </tr>
              <tr v-if="ingredients.length === 0">
                <td class="px-3 py-4 text-center text-gray-500" colspan="4">{{ t('batch.summary.noIngredients') }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="px-4 py-4">
          <h4 class="text-sm font-semibold uppercase text-gray-500 mb-2">{{ t('batch.summary.steps') }}</h4>
          <div v-if="loadingSteps" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
          <table v-else class="min-w-full text-sm border border-gray-200 rounded-lg overflow-hidden">
            <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
              <tr>
                <th class="px-3 py-2 text-left">#</th>
                <th class="px-3 py-2 text-left">{{ t('batch.summary.step') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.summary.status') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.summary.qa') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.summary.notes') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="step in steps" :key="step.id" class="hover:bg-gray-50">
                <td class="px-3 py-2">{{ step.step_no }}</td>
                <td class="px-3 py-2">{{ step.step }}</td>
                <td class="px-3 py-2">{{ step.status || 'open' }}</td>
                <td class="px-3 py-2 whitespace-pre-line">{{ step.qa_checks }}</td>
                <td class="px-3 py-2 whitespace-pre-line">{{ step.notes || '—' }}</td>
              </tr>
              <tr v-if="steps.length === 0">
                <td class="px-3 py-4 text-center text-gray-500" colspan="5">{{ t('batch.summary.noSteps') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import {
  resolveReleasedRecipeCode,
  resolveReleasedRecipeName,
} from '@/lib/batchRecipeSnapshot'
import { supabase } from '@/lib/supabase'
import { formatVolumeNumber } from '@/lib/volumeFormat'

interface BatchSummaryBatch {
  id: string
  batch_code: string
}

const props = defineProps<{ open: boolean, batch: BatchSummaryBatch }>()
const emit = defineEmits(['close'])

const { t, locale } = useI18n()
const mesClient = () => supabase.schema('mes')

const loading = ref(false)
const loadingIngredients = ref(false)
const loadingSteps = ref(false)

const detail = ref<any>(null)
const ingredients = ref<Array<{ id: string, material_name: string, amount: number | null, uom_code: string | null, usage_stage: string | null, notes: string | null }>>([])
const steps = ref<Array<any>>([])
const detailRecipeName = computed(() => resolveReleasedRecipeName(detail.value) ?? '—')
const detailRecipeCode = computed(() => resolveReleasedRecipeCode(detail.value))

function toNumber(value: any): number | null {
  if (value === null || value === undefined || value === '') return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function parseKpi(value: any) {
  if (!value) return []
  if (Array.isArray(value)) return value
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value)
      return Array.isArray(parsed) ? parsed : []
    } catch {
      return []
    }
  }
  return []
}

function resolvePlannedVolume(kpi: any) {
  const rows = parseKpi(kpi)
  const row = rows.find((item: any) => item && item.id === 'volume')
    ?? rows.find((item: any) => item && item.id === 'volume_l')
  if (!row) return null
  return toNumber(row.planed ?? row.planned)
}

function formatVolume(value: number | null) {
  return formatVolumeNumber(value, locale.value)
}

function formatQualityChecks(value: unknown) {
  if (!Array.isArray(value)) return '[]'
  const labels = value.map((row) => {
    if (typeof row === 'string') return row
    if (row && typeof row === 'object') {
      const record = row as Record<string, unknown>
      return String(record.check_code ?? record.parameter_code ?? record.code ?? record.name ?? '')
    }
    return ''
  }).map((row) => row.trim()).filter(Boolean)
  return labels.length ? labels.join('\n') : '[]'
}

function ingredientRowsFromRecipeJson(recipeJson: unknown) {
  const record = recipeJson && typeof recipeJson === 'object' && !Array.isArray(recipeJson)
    ? recipeJson as Record<string, unknown>
    : null
  const materials = record && materialsKey(record)
  const materialRows = materials ? [
    ...arrayValue(materials.required),
    ...arrayValue(materials.optional),
  ] : []
  return materialRows.map((row, index) => {
    const item = row && typeof row === 'object' && !Array.isArray(row)
      ? row as Record<string, unknown>
      : {}
    const materialName = String(
      item.material_name
      ?? item.material_code
      ?? item.material_type_code
      ?? item.material_type
      ?? `material-${index + 1}`,
    )
    const amount = toNumber(item.qty)
    const uomCode = typeof item.uom_code === 'string' && item.uom_code.trim() ? item.uom_code.trim() : null
    const usageStage = typeof item.material_role === 'string' && item.material_role.trim() ? item.material_role.trim() : null
    const notes = typeof item.notes === 'string' && item.notes.trim() ? item.notes.trim() : null
    return {
      id: `recipe-${index}`,
      material_name: materialName,
      amount,
      uom_code: uomCode,
      usage_stage: usageStage,
      notes,
    }
  })
}

function materialsKey(record: Record<string, unknown>) {
  const materials = record.materials
  return materials && typeof materials === 'object' && !Array.isArray(materials)
    ? materials as Record<string, unknown>
    : null
}

function arrayValue(value: unknown) {
  return Array.isArray(value) ? value : []
}

watch(() => props.open, (val) => {
  if (val) {
    loadSummary()
  }
})

watch(() => props.batch?.id, () => {
  if (props.open) {
    loadSummary()
  }
})

async function loadSummary() {
  if (!props.batch?.id) return
  try {
    loading.value = true
    const { data, error } = await supabase
      .from('mes_batches')
      .select('id, batch_code, status, planned_start, planned_end, actual_start, actual_end, notes, kpi, batch_label, product_name, meta, mes_recipe_id, recipe_version_id, released_reference_json, recipe_json')
      .eq('id', props.batch.id)
      .maybeSingle()
    if (error) throw error
    detail.value = data
    await Promise.all([loadIngredients(props.batch.id, data?.recipe_json), loadSteps(props.batch.id)])
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

async function loadIngredients(batchId: string, recipeJson: unknown) {
  ingredients.value = []
  try {
    loadingIngredients.value = true
    const { data, error } = await mesClient()
      .from('batch_material_plan')
      .select('id, batch_step_id, material_role, planned_qty, requirement_json, snapshot_json, uom_id')
      .eq('batch_id', batchId)
      .order('created_at', { ascending: true })
    if (error) throw error
    ingredients.value = (data ?? []).map((row: any) => {
      const requirement = row.requirement_json && typeof row.requirement_json === 'object' && !Array.isArray(row.requirement_json)
        ? row.requirement_json as Record<string, unknown>
        : {}
      const snapshot = row.snapshot_json && typeof row.snapshot_json === 'object' && !Array.isArray(row.snapshot_json)
        ? row.snapshot_json as Record<string, unknown>
        : {}
      const materialName = String(
        requirement.material_name
        ?? requirement.material_code
        ?? requirement.material_type_code
        ?? requirement.material_type
        ?? row.material_role
        ?? row.id,
      )
      const usageStage =
        (typeof snapshot.step_code === 'string' && snapshot.step_code.trim())
        || (typeof row.material_role === 'string' && row.material_role.trim())
        || null
      const notes =
        (typeof requirement.notes === 'string' && requirement.notes.trim())
        || (typeof snapshot.source === 'string' && snapshot.source.trim())
        || null
      return {
        id: row.id,
        amount: toNumber(row.planned_qty) ?? toNumber(requirement.qty),
        usage_stage: usageStage,
        notes,
        material_name: materialName,
        uom_code: typeof requirement.uom_code === 'string' && requirement.uom_code.trim() ? requirement.uom_code.trim() : null,
      }
    })
    if (ingredients.value.length === 0) {
      ingredients.value = ingredientRowsFromRecipeJson(recipeJson)
    }
  } catch (err) {
    console.error(err)
    ingredients.value = ingredientRowsFromRecipeJson(recipeJson)
  } finally {
    loadingIngredients.value = false
  }
}

async function loadSteps(batchId: string) {
  steps.value = []
  try {
    loadingSteps.value = true
    const { data, error } = await mesClient()
      .from('batch_step')
      .select('id, step_no, step_code, step_name, status, quality_checks_json, notes')
      .eq('batch_id', batchId)
      .order('step_no', { ascending: true })
    if (error) throw error
    steps.value = (data ?? []).map((row) => ({
      id: row.id,
      step_no: row.step_no,
      step: row.step_name ?? row.step_code ?? '—',
      status: row.status,
      qa_checks: formatQualityChecks(row.quality_checks_json),
      notes: row.notes,
    }))
  } catch (err) {
    console.error(err)
  } finally {
    loadingSteps.value = false
  }
}

function fmt(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
  } catch {
    return value
  }
}
</script>
