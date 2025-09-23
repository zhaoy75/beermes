<template>
  <div v-if="open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
    <div class="w-full max-w-3xl bg-white rounded-xl shadow-lg border border-gray-200">
      <header class="flex items-center justify-between px-4 py-3 border-b">
        <div>
          <h3 class="text-lg font-semibold text-gray-800">{{ t('lot.summary.title', { code: lot.lot_code }) }}</h3>
          <p class="text-xs text-gray-500">{{ t('lot.summary.subtitle') }}</p>
        </div>
        <button class="text-sm px-2 py-1 rounded border hover:bg-gray-100" type="button" @click="emit('close')">{{ t('common.close') }}</button>
      </header>

      <section class="max-h-[75vh] overflow-y-auto divide-y divide-gray-100">
        <div class="px-4 py-4">
          <h4 class="text-sm font-semibold uppercase text-gray-500 mb-2">{{ t('lot.summary.overview') }}</h4>
          <div v-if="loading" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
          <dl v-else class="grid grid-cols-1 md:grid-cols-2 gap-x-6 gap-y-2 text-sm">
            <div>
              <dt class="font-medium text-gray-600">{{ t('lot.summary.status') }}</dt>
              <dd class="text-gray-800">{{ detail?.status ?? '—' }}</dd>
            </div>
            <div>
              <dt class="font-medium text-gray-600">{{ t('lot.summary.recipe') }}</dt>
              <dd class="text-gray-800">{{ detail?.recipe?.name ?? '—' }} <span v-if="detail?.recipe?.code" class="text-xs text-gray-500">({{ detail?.recipe?.code }})</span></dd>
            </div>
            <div>
              <dt class="font-medium text-gray-600">{{ t('lot.summary.plannedStart') }}</dt>
              <dd class="text-gray-800">{{ fmt(detail?.planned_start) }}</dd>
            </div>
            <!-- <div>
              <dt class="font-medium text-gray-600">{{ t('lot.summary.plannedEnd') }}</dt>
              <dd class="text-gray-800">{{ fmt(detail?.planned_end) }}</dd>
            </div>
            <div>
              <dt class="font-medium text-gray-600">{{ t('lot.summary.actualStart') }}</dt>
              <dd class="text-gray-800">{{ fmt(detail?.actual_start) }}</dd>
            </div>
            <div>
              <dt class="font-medium text-gray-600">{{ t('lot.summary.actualEnd') }}</dt>
              <dd class="text-gray-800">{{ fmt(detail?.actual_end) }}</dd>
            </div> -->
            <div>
              <dt class="font-medium text-gray-600">{{ t('lot.summary.targetVolume') }}</dt>
              <dd class="text-gray-800">{{ detail?.target_volume_l ?? '—' }}</dd>
            </div>
            <div>
              <dt class="font-medium text-gray-600">{{ t('lot.summary.processVersion') }}</dt>
              <dd class="text-gray-800">{{ detail?.process_version ?? '—' }}</dd>
            </div>
            <div class="md:col-span-2">
              <dt class="font-medium text-gray-600">{{ t('lot.summary.notes') }}</dt>
              <dd class="text-gray-800 whitespace-pre-line">{{ detail?.notes || '—' }}</dd>
            </div>
          </dl>
        </div>

        <div class="px-4 py-4">
          <h4 class="text-sm font-semibold uppercase text-gray-500 mb-2">{{ t('lot.summary.ingredients') }}</h4>
          <div v-if="loadingIngredients" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
          <table v-else class="min-w-full text-sm border border-gray-200 rounded-lg overflow-hidden">
            <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('lot.summary.ingredient') }}</th>
                <th class="px-3 py-2 text-right">{{ t('lot.summary.amount') }}</th>
                <th class="px-3 py-2 text-left">{{ t('lot.summary.usageStage') }}</th>
                <th class="px-3 py-2 text-left">{{ t('lot.summary.notes') }}</th>
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
                <td class="px-3 py-4 text-center text-gray-500" colspan="4">{{ t('lot.summary.noIngredients') }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <div class="px-4 py-4">
          <h4 class="text-sm font-semibold uppercase text-gray-500 mb-2">{{ t('lot.summary.steps') }}</h4>
          <div v-if="loadingSteps" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
          <table v-else class="min-w-full text-sm border border-gray-200 rounded-lg overflow-hidden">
            <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
              <tr>
                <th class="px-3 py-2 text-left">#</th>
                <th class="px-3 py-2 text-left">{{ t('lot.summary.step') }}</th>
                <th class="px-3 py-2 text-left">{{ t('lot.summary.status') }}</th>
                <th class="px-3 py-2 text-left">{{ t('lot.summary.qa') }}</th>
                <th class="px-3 py-2 text-left">{{ t('lot.summary.notes') }}</th>
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
                <td class="px-3 py-4 text-center text-gray-500" colspan="5">{{ t('lot.summary.noSteps') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '@/lib/supabase'

interface LotSummaryLot {
  id: string
  lot_code: string
}

const props = defineProps<{ open: boolean, lot: LotSummaryLot }>()
const emit = defineEmits(['close'])

const { t } = useI18n()

const loading = ref(false)
const loadingIngredients = ref(false)
const loadingSteps = ref(false)

const detail = ref<any>(null)
const ingredients = ref<Array<{ id: string, material_name: string, amount: number | null, uom_code: string | null, usage_stage: string | null, notes: string | null }>>([])
const steps = ref<Array<any>>([])

watch(() => props.open, (val) => {
  if (val) {
    loadSummary()
  }
})

watch(() => props.lot?.id, () => {
  if (props.open) {
    loadSummary()
  }
})

async function loadSummary() {
  if (!props.lot?.id) return
  try {
    loading.value = true
    const { data, error } = await supabase
      .from('prd_lots')
      .select('*, recipe:rcp_recipes(name, code, version)')
      .eq('id', props.lot.id)
      .maybeSingle()
    if (error) throw error
    detail.value = data
    await Promise.all([loadIngredients(data?.recipe_id), loadSteps(props.lot.id)])
  } catch (err) {
    console.error(err)
  } finally {
    loading.value = false
  }
}

async function loadIngredients(recipeId: string | undefined) {
  ingredients.value = []
  if (!recipeId) return
  try {
    loadingIngredients.value = true
    const { data, error } = await supabase
      .from('rcp_ingredients')
      .select('id, amount, usage_stage, notes, material:mst_materials(name, code), uom:mst_uom(code)')
      .eq('recipe_id', recipeId)
      .order('usage_stage', { ascending: true })
    if (error) throw error
    ingredients.value = (data ?? []).map((row) => ({
      id: row.id,
      amount: row.amount,
      usage_stage: row.usage_stage,
      notes: row.notes,
      material_name: `${row.material?.name ?? ''} (${row.material?.code ?? ''})`.trim(),
      uom_code: row.uom?.code ?? null,
    }))
  } catch (err) {
    console.error(err)
  } finally {
    loadingIngredients.value = false
  }
}

async function loadSteps(lotId: string) {
  steps.value = []
  try {
    loadingSteps.value = true
    const { data, error } = await supabase
      .from('prd_lot_steps')
      .select('id, step_no, step, status, planned_params, qa_checks, actual_params, notes')
      .eq('lot_id', lotId)
      .order('step_no', { ascending: true })
    if (error) throw error
    steps.value = (data ?? []).map((row) => ({
      ...row,
      qa_checks: Array.isArray(row.qa_checks) ? row.qa_checks.join('\n') : (typeof row.qa_checks === 'string' ? row.qa_checks : JSON.stringify(row.qa_checks ?? [])),
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
