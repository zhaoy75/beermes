<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="$t('recipe.edit.title')" />

    <!-- Select recipe/version -->
    <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4 mb-4">
      <h2 class="text-lg font-semibold mb-3">{{ $t('recipe.edit.selectVersion') }}</h2>
      <div v-if="!selectionLocked" class="grid grid-cols-1 md:grid-cols-3 gap-3 items-end">
        <div>
          <label class="block text-sm text-gray-600 mb-1">{{ $t('recipe.edit.recipe') }}</label>
          <select v-model="selectedDefId" class="w-full h-[40px] border rounded px-3" @change="loadVersions">
            <option :value="''">-- {{ $t('recipe.edit.selectPlaceholder') }} --</option>
            <option v-for="d in definitions" :key="d.id" :value="d.id">{{ d.name }}</option>
          </select>
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1">{{ $t('recipe.edit.version') }}</label>
          <select v-model="selectedVersionId" class="w-full h-[40px] border rounded px-3" @change="loadSteps">
            <option :value="''">-- {{ $t('recipe.edit.selectPlaceholder') }} --</option>
            <option v-for="v in versions" :key="v.id" :value="v.id">{{ v.version }} ({{ v.status }})</option>
          </select>
        </div>
      </div>
      <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-3">
        <div class="p-3 border border-gray-200 rounded-lg bg-gray-50">
          <p class="text-xs uppercase text-gray-500">{{ $t('recipe.edit.recipe') }}</p>
          <p class="text-base font-semibold">{{ selectedDefinition?.name || selectedDefId }}</p>
          <p v-if="selectedDefinition" class="text-xs text-gray-500">ID: {{ selectedDefinition.id }}</p>
        </div>
        <div class="p-3 border border-gray-200 rounded-lg bg-gray-50">
          <p class="text-xs uppercase text-gray-500">{{ $t('recipe.edit.version') }}</p>
          <p class="text-base font-semibold">{{ selectedVersion?.version || '-' }}</p>
          <p v-if="selectedVersion" class="text-xs text-gray-500">{{ selectedVersion.status }}<span
              v-if="selectedVersion.created_at"> · {{ formatDate(selectedVersion.created_at) }}</span></p>
        </div>
      </div>
      <div class="flex gap-2 mt-4">
        <select v-model="addKey" class="h-[40px] border rounded px-2 flex-1">
          <option :value="''">{{ $t('recipe.edit.addFromTemplate') }}</option>
          <option v-for="k in stepSchemaKeys" :key="k" :value="k">{{ schemaLabel(k) }}</option>
        </select>
        <button class="px-4 md:px-5 h-[40px] rounded bg-blue-600 text-white whitespace-nowrap shrink-0"
          :disabled="!addKey || !selectedVersionId" @click="addStep">{{ $t('recipe.edit.add') }}</button>
        <button class="px-4 md:px-5 h-[40px] rounded border whitespace-nowrap shrink-0"
          :disabled="!selectedVersionId || saving" @click="saveAll">{{
            saving ? $t('common.saving') : $t('recipe.edit.saveAll') }}</button>
      </div>
    </section>

    <!-- Steps -->
    <section v-if="selectedVersionId" class="space-y-3">
      <details v-for="(s, idx) in steps" :key="s.localId" open
        class="group border border-gray-200 rounded-xl bg-white shadow-sm overflow-hidden">
        <summary class="flex items-center justify-between gap-3 cursor-pointer select-none p-4">
          <div class="flex items-center gap-2">
            <span class="font-semibold">{{ schemaLabel(s.step_key) }}</span>
            <span class="text-xs text-gray-500">(pos {{ s.position }})</span>
          </div>
          <div class="flex items-center gap-2">
            <button class="px-2 py-1 text-xs border rounded" @click.stop="move(idx, -1)"
              :disabled="idx === 0">↑</button>
            <button class="px-2 py-1 text-xs border rounded" @click.stop="move(idx, 1)"
              :disabled="idx === steps.length - 1">↓</button>
            <button class="px-2 py-1 text-xs bg-red-600 text-white rounded" @click.stop="removeStep(idx)">{{
              $t('common.delete') }}</button>
          </div>
        </summary>
        <div class="px-4 pb-4 pt-0">
          <div class="grid grid-cols-1 md:grid-cols-4 gap-3 mb-3">
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ $t('recipe.edit.defaultDurationMin') }}</label>
              <input v-model.number="s.default_duration_minutes" type="number" min="0"
                class="w-full h-[38px] border rounded px-2" />
            </div>
          </div>

          <!-- Config dynamic editor -->
          <div class="border rounded-lg p-3">
            <h4 class="font-semibold mb-2">{{ $t('recipe.edit.config') }}</h4>
            <component :is="DynamicConfig" :modelValue="s.configObj" :schema="schemaFor(s.step_key)"
              @update:modelValue="(val) => s.configObj = val" />
          </div>

          <!-- QC metrics (optional) -->
          <div class="border rounded-lg p-3 mt-3">
            <div class="flex items-center justify-between mb-2">
              <h4 class="font-semibold">{{ $t('recipe.edit.qc') }}</h4>
              <button class="px-2 py-1 text-xs border rounded" @click="toggleQc(s)">{{ s.qc?.metrics ?
                $t('recipe.edit.clear') : $t('recipe.edit.enable') }}</button>
            </div>
            <div v-if="s.qc && Array.isArray(s.qc.metrics)" class="space-y-2">
              <div v-for="(m, mi) in s.qc.metrics" :key="mi" class="grid grid-cols-1 md:grid-cols-5 gap-2 items-end">
                <div><label class="block text-xs text-gray-600">{{ $t('recipe.edit.metricName') }}</label><input
                    v-model.trim="m.name" class="w-full h-[34px] border rounded px-2" /></div>
                <div><label class="block text-xs text-gray-600">{{ $t('recipe.edit.unit') }}</label><input
                    v-model.trim="m.unit" class="w-full h-[34px] border rounded px-2" /></div>
                <div><label class="block text-xs text-gray-600">{{ $t('recipe.edit.target') }}</label><input
                    v-model.number="m.target" type="number" step="any" class="w-full h-[34px] border rounded px-2" />
                </div>
                <div><label class="block text-xs text-gray-600">{{ $t('recipe.edit.tolerance') }}</label><input
                    v-model.number="m.tolerance" type="number" step="any" class="w-full h-[34px] border rounded px-2" />
                </div>
                <div class="flex gap-2"><input v-model.trim="m.when" class="w-full h-[34px] border rounded px-2"
                    :placeholder="$t('recipe.edit.whenOptional')" /><button class="px-2 h-[34px] text-xs border rounded"
                    @click="removeMetric(s, mi)">−</button></div>
              </div>
              <button class="px-2 py-1 text-xs border rounded" @click="addMetric(s)">+ {{ $t('recipe.edit.addMetric')
                }}</button>
            </div>
          </div>
        </div>
      </details>
      <div v-if="steps.length === 0" class="text-center text-gray-500 py-8">{{ $t('recipe.edit.noStepsYet') }}</div>
    </section>
  </AdminLayout>
</template>

<script setup lang="tsx">
import { ref, reactive, onMounted, toRaw, computed, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import i18n from '@/i18n'
import { useRoute } from 'vue-router'
import { supabase } from '../../lib/supabase'
import AdminLayout from "@/components/layout/AdminLayout.vue";
import PageBreadcrumb from "@/components/common/PageBreadcrumb.vue";

// Module-level safe deep copy helper
const deepCopy = (v: any) => {
  try {
    return v == null ? v : JSON.parse(JSON.stringify(v))
  } catch {
    return Array.isArray(v) ? v.slice() : { ...(v || {}) }
  }
}

// ---- Step schemas (loaded from Supabase template) ----
type StepTemplate = {
  key: string
  name?: string
  fields?: Record<string, any>
  defaults?: Record<string, any>
  default_duration_minutes?: number | null
  order?: number | null
}

type StepTemplateRecord = {
  name?: string
  version?: string
  steps_fixed?: boolean
  steps?: RawStep[]
}

type RawStep = {
  key?: string
  code?: string
  step_key?: string
  name?: string
  label?: string | Record<string, string>
  defaults?: Record<string, any>
  fields?: Record<string, any>
  default_duration_minutes?: number | null
  order?: number | null
}

const stepTemplate = ref<StepTemplateRecord | null>(null)
const stepSchemas = ref<Record<string, StepTemplate>>({})
const stepSchemaKeys = computed(() => Object.keys(stepSchemas.value))

const stepLabels = ref<Record<string, Record<string, string>>>({})

const normalizeLabelText = (
  label: string | Record<string, string> | undefined,
  locale: string
): string | null => {
  if (!label) return null
  if (typeof label === 'string') return label.trim() || null
  if (typeof label === 'object') {
    const prioritized = [locale, locale.split('-')[0], 'en', 'en-US', 'en-GB']
    for (const key of prioritized) {
      if (key && typeof label[key] === 'string' && label[key].trim()) return label[key].trim()
    }
    const first = Object.values(label).find((v) => typeof v === 'string' && v.trim())
    return typeof first === 'string' ? first.trim() : null
  }
  return null
}

const resolveStepKey = (step: RawStep): string | null => {
  const direct = step?.key ?? step?.code ?? step?.step_key ?? null
  if (direct) return String(direct)
  const fromLabel = normalizeLabelText(step?.label, 'en')
  if (fromLabel) return fromLabel.replace(/[^A-Za-z0-9]+/g, '_').toUpperCase()
  if (typeof step?.name === 'string' && step.name.trim()) {
    return step.name.replace(/[^A-Za-z0-9]+/g, '_').toUpperCase()
  }
  if (typeof step?.order === 'number' && Number.isFinite(step.order)) {
    return `STEP_${step.order}`
  }
  return null
}

async function loadStepTemplates() {
  const { data, error } = await supabase
    .from('process_step_template')
    .select('schema')
    .order('created_at', { ascending: false })
    .limit(1)

  if (error) {
    console.error('Failed to load process step templates', error)
    return
  }

  const record = Array.isArray(data) ? data[0] : data
  const schema = (record?.schema ?? null) as StepTemplateRecord | null
  if (!schema || !Array.isArray(schema.steps)) {
    console.warn('process_step_template schema missing or malformed')
    stepTemplate.value = schema
    stepSchemas.value = {}
    return
  }

  const map: Record<string, StepTemplate> = {}
  const labelMap: Record<string, Record<string, string>> = {}
  const locale = i18n.global.locale?.value || 'en'
  for (const step of schema.steps) {
    const key = resolveStepKey(step)
    if (!key) continue
    const labelObj: Record<string, string> = {}
    if (typeof step.label === 'object') {
      Object.entries(step.label).forEach(([k, v]) => {
        if (typeof v === 'string' && v.trim()) labelObj[k] = v.trim()
      })
    } else if (typeof step.label === 'string' && step.label.trim()) {
      labelObj.en = step.label.trim()
    }
    if (typeof step.name === 'string' && step.name.trim() && !labelObj.en) {
      labelObj.en = step.name.trim()
    }

    labelMap[key] = labelObj

    const displayName = normalizeLabelText(Object.keys(labelObj).length ? labelObj : undefined, locale) ?? step.name ?? key
    map[key] = {
      key,
      name: displayName,
      fields: step.fields ?? {},
      defaults: step.defaults ?? {},
      default_duration_minutes: step.default_duration_minutes ?? null,
      order: typeof step.order === 'number' ? step.order : null,
    }
  }

  stepTemplate.value = schema
  stepSchemas.value = map
  stepLabels.value = labelMap
  applyLocaleToSchemas(locale)
}

// Dynamic config editor component (inline)
const DynamicConfig = {
  props: ['modelValue', 'schema'],
  emits: ['update:modelValue'],
  setup(props, { emit }) {
    const deepCopy = (v) => {
      try { return v == null ? v : JSON.parse(JSON.stringify(v)) } catch { return Array.isArray(v) ? v.slice() : { ...(v || {}) } }
    }
    const local = reactive(deepCopy(toRaw(props.modelValue) || {}))
    const ensureDefault = (key, defVal) => { if (local[key] === undefined) local[key] = defVal }
    // initialize defaults from schema
    if (props.schema?.defaults) {
      for (const [k, v] of Object.entries(props.schema.defaults)) ensureDefault(k, deepCopy(v))
    }
    const update = () => emit('update:modelValue', JSON.parse(JSON.stringify(local)))
    const addArrayItem = (key, template) => { if (!Array.isArray(local[key])) local[key] = []; local[key].push(deepCopy(template)); update() }
    const removeArrayItem = (key, idx) => { local[key].splice(idx, 1); update() }
    const selectLabel = (labelDef, fallbackKey) => {
      const loc = i18n.global.locale?.value || 'en'
      if (!labelDef) return (t && typeof t === 'function') ? (t(`recipe.edit.fields.${fallbackKey}`) as string) : fallbackKey
      if (typeof labelDef === 'string') return labelDef
      return labelDef[loc] || labelDef.en || labelDef.ja || fallbackKey
    }

    const renderField = (key, type, value) => {
      // Primitive types as strings
      if (typeof type === 'string') {
        if (type === 'number')
          return (<input
            type="number"
            step="any"
            class="w-full h-[34px] border rounded px-2"
            v-model={[local[key], 'number']}
            onInput={update}
          />
          )
        else if (type === 'boolean')
          return (<input type="checkbox" class="h-4 w-4" v-model={local[key]} onChange={update} />)
        else
          return (<input class="w-full h-[34px] border rounded px-2" v-model={local[key]} onInput={update} />)
      }
      // Descriptor object for primitive types
      if (typeof type === 'object' && (type as any)?.type && typeof (type as any).type === 'string' && (type as any).type !== 'object' && (type as any).type !== 'array') {
        const tt = (type as any).type as string
        if (tt === 'number')
          return (
            <input
              type="number"
              step="any"
              class="w-full h-[34px] border rounded px-2"
              v-model={[local[key], 'number']}
              onInput={update}
            />
          )
        if (tt === 'boolean') return (<input type="checkbox" class="h-4 w-4" v-model={local[key]} onChange={update} />)
        return (<input class="w-full h-[34px] border rounded px-2" v-model={local[key]} onInput={update} />)
      }
      if (type?.type === 'object') {
        const f = type.fields || {}
        return (
          <div class="grid grid-cols-1 md:grid-cols-3 gap-2">
            {Object.entries(f).map(([ck, ct]) => {
              const lbl = typeof ct === 'object' && (ct as any).label
              return (<div><label class="block text-xs text-gray-600">{selectLabel(lbl, ck)}</label>{renderFieldNested(local, ck, ct)}</div>)
            })}
          </div>
        )
      }
      if (type?.type === 'array') {
        const of = type.of
        const template = typeof of === 'string' ? (of === 'number' ? 0 : '') : Object.fromEntries(Object.keys(of).map(k => {
          const def = (of as any)[k]
          const tp = typeof def === 'string' ? def : def.type
          return [k, tp === 'number' ? 0 : (tp === 'boolean' ? false : '')]
        }))
        return (
          <div>
            {Array.isArray(local[key]) && local[key].map((item, idx) => (
              <div key={idx} class="grid grid-cols-1 md:grid-cols-5 gap-2 items-end mb-2">
                {typeof of === 'string' ? (
                  <input class="w-full h-[34px] border rounded px-2" v-model={local[key][idx]} onInput={update} />
                ) : (
                  Object.keys(of).map((fk) => {
                    const def = (of as any)[fk]
                    const tp = typeof def === 'string' ? def : def.type
                    const lbl = typeof def === 'object' && (def as any).label
                    return (<div><label class="block text-xs text-gray-600">{selectLabel(lbl, fk)}</label>{renderArrayField(local[key][idx], fk, tp)}</div>)
                  })
                )}
                <button class="px-2 h-[34px] text-xs border rounded" onClick={() => removeArrayItem(key, idx)}>−</button>
              </div>
            ))}
            <button class="px-2 py-1 text-xs border rounded" onClick={() => addArrayItem(key, template)}>+ Add</button>
          </div>
        )
      }
    }
    const renderFieldNested = (obj, ck, ct) => {
      // Primitive as string
      if (ct === 'number') return (
        <input
          type="number"
          step="any"
          class="w-full h-[34px] border rounded px-2"
          value={obj[ck] ?? ''}
          onInput={(e) => { const t = e.currentTarget; obj[ck] = t.value === '' ? null : Number(t.value); update() }}
        />
      )
      if (ct === 'boolean') return (<input type="checkbox" class="h-4 w-4" v-model={obj[ck]} onChange={update} />)
      if (typeof ct === 'string') return (<input class="w-full h-[34px] border rounded px-2" v-model={obj[ck]} onInput={update} />)
      // Descriptor for primitive types
      if (typeof ct === 'object' && (ct as any)?.type && typeof (ct as any).type === 'string' && (ct as any).type !== 'object' && (ct as any).type !== 'array') {
        const tt = (ct as any).type as string
        if (tt === 'number') return (
          <input
            type="number"
            step="any"
            class="w-full h-[34px] border rounded px-2"
            value={obj[ck] ?? ''}
            onInput={(e) => { const t = e.currentTarget; obj[ck] = t.value === '' ? null : Number(t.value); update() }}
          />
        )
        if (tt === 'boolean') return (<input type="checkbox" class="h-4 w-4" v-model={obj[ck]} onChange={update} />)
        return (<input class="w-full h-[34px] border rounded px-2" v-model={obj[ck]} onInput={update} />)
      }
      if (ct?.type === 'object') {
        const f = ct.fields || {}
        return (
          <div class="grid grid-cols-1 md:grid-cols-3 gap-2">
            {Object.entries(f).map(([k, t]) => {
              const lbl = (t as any)?.label
              const loc = i18n.global.locale?.value || 'en'
              const text = lbl ? (lbl[loc] || lbl.en || lbl.ja) : k
              return (<div><label class="block text-xs text-gray-600">{text}</label>{renderFieldNested(obj[ck] || (obj[ck] = {}), k, t)}</div>)
            })}
          </div>
        )
      }
      return (<div class="text-xs text-gray-500">Unsupported</div>)
    }
    const renderArrayField = (row, fk, type) => {
      if (type === 'number') return (
        <input
          type="number"
          step="any"
          class="w-full h-[34px] border rounded px-2"
          value={row[fk] ?? ''}
          onInput={(e) => { const t = e.currentTarget; row[fk] = t.value === '' ? null : Number(t.value); update() }}
        />
      )
      if (type === 'boolean') return (<input type="checkbox" class="h-4 w-4" v-model={row[fk]} onChange={update} />)
      return (<input class="w-full h-[34px] border rounded px-2" v-model={row[fk]} onInput={update} />)
    }
    return () => {
      const schema = props.schema
      if (!schema) return (<div>
        <textarea class="w-full min-h-[120px] border rounded p-2 font-mono text-xs" v-model={local.__raw} placeholder="JSON config" onInput={() => { try { const v = JSON.parse(local.__raw || '{}'); emit('update:modelValue', v) } catch { } }}></textarea>
      </div>)
      const fields = schema.fields || {}
      return (
        <div class="grid grid-cols-1 gap-3">
          {Object.entries(fields).map(([key, type]) => {
            const lbl = typeof type === 'object' && (type as any).label
            const loc = i18n.global.locale?.value || 'en'
            const text = lbl ? (lbl[loc] || lbl.en || lbl.ja) : key
            return (
              <div>
                <label class="block text-xs text-gray-600 mb-1">{text}</label>
                {renderField(key, type, local[key])}
              </div>
            )
          })}
        </div>
      )
    }
  }
}

// ----- State -----
const prefilledRecipeId = ref<string | null>(null)

const definitions = ref([])
const versions = ref([])
const selectedDefId = ref('')
const selectedVersionId = ref('')
const steps = ref([]) // {id?, localId, step_key, name, position, default_duration_minutes, configObj, qc}
const addKey = ref('')
const saving = ref(false)
const pendingDeletes = new Set()

const { t } = useI18n()

const selectionLocked = computed(() => prefilledRecipeId.value !== null)
const selectedDefinition = computed(() => definitions.value.find((d) => d.id === selectedDefId.value) || null)
const selectedVersion = computed(() => versions.value.find((v) => v.id === selectedVersionId.value) || null)

const getLabelForLocale = (step_key: string, locale: string): string | null => {
  const labels = stepLabels.value[step_key]
  if (labels) {
    const prioritized = [locale, locale.split('-')[0], 'en', 'en-US', 'en-GB']
    for (const key of prioritized) {
      if (key && typeof labels[key] === 'string' && labels[key].trim()) return labels[key].trim()
    }
    const first = Object.values(labels).find((v) => typeof v === 'string' && v.trim())
    if (typeof first === 'string') return first.trim()
  }
  return null
}

const applyLocaleToSchemas = (locale = i18n.global.locale?.value || 'en') => {
  if (!Object.keys(stepSchemas.value).length) return
  const updated: Record<string, StepTemplate> = {}
  for (const [key, schema] of Object.entries(stepSchemas.value)) {
    const localized = getLabelForLocale(key, locale)
    updated[key] = {
      ...schema,
      name: localized ?? schema.name ?? key,
    }
  }
  stepSchemas.value = updated
  steps.value.forEach((step) => {
    step.name = schemaLabel(step.step_key)
  })
}

watch(
  () => i18n.global.locale?.value,
  (locale) => {
    if (locale) applyLocaleToSchemas(locale)
  }
)

function schemaFor(step_key) { return stepSchemas.value[step_key] || null }
function schemaLabel(step_key: string) {
  const locale = i18n.global.locale?.value || 'en'
  return getLabelForLocale(step_key, locale) ?? stepSchemas.value[step_key]?.name ?? step_key
}

const formatDate = (value?: string | null) => {
  if (!value) return ''
  const d = new Date(value)
  return Number.isNaN(d.getTime()) ? value : d.toLocaleString()
}

function normalizeSteps(list) {
  list.sort((a, b) => (a.position ?? 0) - (b.position ?? 0))
  steps.value = list.map((r, i) => ({
    id: r.id ?? null,
    localId: r.id || `${Date.now()}-${Math.random()}`,
    step_key: r.step_key,
    name: r.name ?? schemaLabel(r.step_key),
    position: r.position ?? i,
    default_duration_minutes: r.default_duration_minutes ?? null,
    configObj: r.config ?? {},
    qc: r.qc ?? null,
  }))
}

async function loadDefinitions() {
  const { data, error } = await supabase
    .from('process_definitions')
    .select('id, name')
    .order('created_at', { ascending: false })

  if (!error) definitions.value = data ?? []
  return data ?? []
}

async function loadVersions() {
  selectedVersionId.value = ''
  steps.value = []
  if (!selectedDefId.value) {
    versions.value = []
    return []
  }
  const { data, error } = await supabase
    .from('process_versions')
    .select('*')
    .eq('process_id', selectedDefId.value)
    .order('created_at', { ascending: false })

  if (!error) versions.value = data ?? []
  return data ?? []
}
async function loadSteps() {
  steps.value = []
  if (!selectedVersionId.value) return
  const { data, error } = await supabase.from('process_steps').select('id, step_key, name, position, default_duration_minutes, config').eq('process_version_id', selectedVersionId.value).order('position', { ascending: true })
  if (error) { alert('Load steps error: ' + error.message); return }
  normalizeSteps(data || [])
}

function addStep() {
  const key = addKey.value; if (!key) return
  const schema = schemaFor(key)
  if (!schema) {
    console.warn('No schema found for step key', key)
    return
  }
  const cfg = schema?.defaults ? deepCopy(schema.defaults) : {}
  const pos = steps.value.length
  const dispName = schemaLabel(key)
  steps.value.push({ id: null, localId: `${Date.now()}-${Math.random()}`, step_key: key, name: dispName, position: pos, default_duration_minutes: schema?.default_duration_minutes ?? null, configObj: cfg, qc: null })
  addKey.value = ''
}

function move(idx, delta) { const t = idx + delta; if (t < 0 || t >= steps.value.length) return; const [row] = steps.value.splice(idx, 1); steps.value.splice(t, 0, row); steps.value.forEach((r, i) => r.position = i) }
function removeStep(idx) { const s = steps.value[idx]; if (s.id) pendingDeletes.add(s.id); steps.value.splice(idx, 1); steps.value.forEach((r, i) => r.position = i) }

function addMetric(s) { if (!s.qc) s.qc = { metrics: [] }; if (!Array.isArray(s.qc.metrics)) s.qc.metrics = []; s.qc.metrics.push({ name: '', unit: '', target: null, tolerance: null, when: '' }) }
function removeMetric(s, mi) { s.qc.metrics.splice(mi, 1) }
function toggleQc(s) { if (s.qc?.metrics) s.qc = null; else s.qc = { metrics: [] } }

async function saveAll() {
  if (!selectedVersionId.value) return
  saving.value = true
  try {
    // deletions
    if (pendingDeletes.size) { const ids = [...pendingDeletes]; const { error } = await supabase.from('process_steps').delete().in('id', ids); if (error) throw new Error(error.message); pendingDeletes.clear() }
    // upsert steps in order
    for (const [i, s] of steps.value.entries()) {
      const payload = { process_version_id: selectedVersionId.value, step_key: s.step_key, name: s.name, position: i, default_duration_minutes: s.default_duration_minutes, config: s.configObj }
      if (s.id) { const { error } = await supabase.from('process_steps').update(payload).eq('id', s.id); if (error) throw new Error(error.message) }
      else { const { data, error } = await supabase.from('process_steps').insert(payload).select('id').single(); if (error) throw new Error(error.message); s.id = data.id }
    }
    alert(t('recipe.edit.saved'))
  } catch (e) { alert('Save error: ' + e.message) }
  saving.value = false
}

const route = useRoute()
const initializeFromRoute = async () => {
  const rid = route.params.recipeId as string | undefined
  const vid = route.params.versionId as string | undefined

  prefilledRecipeId.value = rid ?? null

  if (!rid) {
    selectedDefId.value = ''
    versions.value = []
    selectedVersionId.value = ''
    steps.value = []
    return
  }

  selectedDefId.value = rid
  const versionRows = await loadVersions()

  let targetVersionId = ''
  if (vid && versionRows.some((v: any) => v.id === vid)) {
    targetVersionId = vid
  } else if (versionRows.length) {
    targetVersionId = versionRows[0].id
  }

  selectedVersionId.value = targetVersionId
  if (targetVersionId) {
    await loadSteps()
  } else {
    steps.value = []
  }
}

watch(
  () => [route.params.recipeId, route.params.versionId],
  () => {
    initializeFromRoute()
  }
)

onMounted(async () => {
  await loadStepTemplates()
  await loadDefinitions()
  await initializeFromRoute()
})
</script>

<style scoped>
details[open]>summary+* {
  animation: fadeIn .2s ease-in
}

@keyframes fadeIn {
  from {
    opacity: .7;
    transform: translateY(-2px)
  }

  to {
    opacity: 1;
    transform: none
  }
}

textarea,
.font-mono {
  font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
}
</style>
