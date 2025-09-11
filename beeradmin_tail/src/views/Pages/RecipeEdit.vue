<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="$t('recipe.edit.title')" />

    <!-- Select recipe/version -->
    <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4 mb-4">
      <h2 class="text-lg font-semibold mb-3">{{ $t('recipe.edit.selectVersion') }}</h2>
      <div class="grid grid-cols-1 md:grid-cols-3 gap-3 items-end">
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
        <div class="flex gap-2">
          <select v-model="addKey" class="h-[40px] border rounded px-2 flex-1">
            <option :value="''">{{ $t('recipe.edit.addFromTemplate') }}</option>
            <option v-for="k in Object.keys(STEP_SCHEMAS)" :key="k" :value="k">{{ k }} — {{ $t('recipe.edit.schemas.' + k) }}
            </option>
          </select>
          <button class="px-3 h-[40px] rounded bg-blue-600 text-white" :disabled="!addKey || !selectedVersionId"
            @click="addStep">{{ $t('recipe.edit.add') }}</button>
          <button class="px-3 h-[40px] rounded border" :disabled="!selectedVersionId || saving" @click="saveAll">{{
            saving ? $t('common.saving') : $t('recipe.edit.saveAll') }}</button>
        </div>
      </div>
    </section>

    <!-- Steps -->
    <section v-if="selectedVersionId" class="space-y-3">
      <details v-for="(s, idx) in steps" :key="s.localId" open
        class="group border border-gray-200 rounded-xl bg-white shadow-sm overflow-hidden">
        <summary class="flex items-center justify-between gap-3 cursor-pointer select-none p-4">
          <div class="flex items-center gap-2">
            <span class="font-semibold">{{ s.step_key }} — {{ s.name }}</span>
            <span class="text-xs text-gray-500">(pos {{ s.position }})</span>
          </div>
          <div class="flex items-center gap-2">
            <button class="px-2 py-1 text-xs border rounded" @click.stop="move(idx, -1)" :disabled="idx === 0">↑</button>
            <button class="px-2 py-1 text-xs border rounded" @click.stop="move(idx, 1)"
              :disabled="idx === steps.length - 1">↓</button>
            <button class="px-2 py-1 text-xs bg-red-600 text-white rounded"
              @click.stop="removeStep(idx)">{{ $t('common.delete') }}</button>
          </div>
        </summary>
        <div class="px-4 pb-4 pt-0">
          <div class="grid grid-cols-1 md:grid-cols-4 gap-3 mb-3">
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ $t('recipe.edit.stepKey') }}</label>
              <input v-model.trim="s.step_key" class="w-full h-[38px] border rounded px-2" />
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{ $t('recipe.edit.name') }}</label>
              <input v-model.trim="s.name" class="w-full h-[38px] border rounded px-2" />
            </div>
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
              <button class="px-2 py-1 text-xs border rounded" @click="toggleQc(s)">{{ s.qc?.metrics ? $t('recipe.edit.clear') : $t('recipe.edit.enable') }}</button>
            </div>
            <div v-if="s.qc && Array.isArray(s.qc.metrics)" class="space-y-2">
              <div v-for="(m, mi) in s.qc.metrics" :key="mi" class="grid grid-cols-1 md:grid-cols-5 gap-2 items-end">
                <div><label class="block text-xs text-gray-600">{{ $t('recipe.edit.metricName') }}</label><input v-model.trim="m.name"
                    class="w-full h-[34px] border rounded px-2" /></div>
                <div><label class="block text-xs text-gray-600">{{ $t('recipe.edit.unit') }}</label><input v-model.trim="m.unit"
                    class="w-full h-[34px] border rounded px-2" /></div>
                <div><label class="block text-xs text-gray-600">{{ $t('recipe.edit.target') }}</label><input v-model.number="m.target"
                    type="number" step="any" class="w-full h-[34px] border rounded px-2" /></div>
                <div><label class="block text-xs text-gray-600">{{ $t('recipe.edit.tolerance') }}</label><input v-model.number="m.tolerance"
                    type="number" step="any" class="w-full h-[34px] border rounded px-2" /></div>
                <div class="flex gap-2"><input v-model.trim="m.when" class="w-full h-[34px] border rounded px-2"
                    :placeholder="$t('recipe.edit.whenOptional')" /><button class="px-2 h-[34px] text-xs border rounded"
                    @click="removeMetric(s, mi)">−</button></div>
              </div>
              <button class="px-2 py-1 text-xs border rounded" @click="addMetric(s)">+ {{ $t('recipe.edit.addMetric') }}</button>
            </div>
          </div>
        </div>
      </details>
      <div v-if="steps.length === 0" class="text-center text-gray-500 py-8">{{ $t('recipe.edit.noStepsYet') }}</div>
    </section>
  </AdminLayout>
</template>

<script setup lang="tsx">
import { ref, reactive, onMounted, toRaw } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute } from 'vue-router'
import { supabase } from '../../lib/supabase'
import AdminLayout from "@/components/layout/AdminLayout.vue";
import PageBreadcrumb from "@/components/common/PageBreadcrumb.vue";

// ---- Step schemas (minimal, can expand) ----
const STEP_SCHEMAS = {
  MILL: {
    name: 'Milling',
    fields: {
      target_grist_ratio: { type: 'object', fields: { fine_percent: 'number', coarse_percent: 'number' } },
      malt_bill: { type: 'array', of: { name: 'string', percent: 'number' } },
      equipment_id: 'string',
      sop_url: 'string',
    },
    defaults: { target_grist_ratio: { fine_percent: 70, coarse_percent: 30 }, malt_bill: [], equipment_id: '', sop_url: '' },
    default_duration_minutes: 30,
  },
  MASH: {
    name: 'Mashing',
    fields: {
      water_to_grist_ratio_lkg: 'number',
      target_ph: 'number',
      mash_profile: { type: 'array', of: { name: 'string', temp_c: 'number', hold_min: 'number' } },
      additions: { type: 'array', of: { time_min: 'number', name: 'string', amount_g: 'number', amount_ml: 'number' } },
      equipment_id: 'string',
      sensors: { type: 'object', fields: { temp_probe: 'string', ph_probe: 'string' } },
      sop_url: 'string',
    },
    defaults: { mash_profile: [], additions: [], equipment_id: '', sensors: {} },
    default_duration_minutes: 75,
  },
  LAUTER: {
    name: 'Lautering',
    fields: { sparge_temp_c: 'number', sparge_volume_l: 'number', recirculation_min: 'number', target_preboil_gravity: 'number', equipment_id: 'string', sensors: { type: 'object', fields: { flow_meter: 'string' } } },
    defaults: {},
    default_duration_minutes: 60,
  },
  BOIL: {
    name: 'Boil',
    fields: {
      boil_minutes: 'number',
      hop_schedule: { type: 'array', of: { at_min: 'number', hop: 'string', form: 'string', amount_g: 'number', purpose: 'string', method: 'string' } },
      boil_off_rate_lph: 'number',
      whirlpool_min: 'number',
      equipment_id: 'string',
    },
    defaults: { hop_schedule: [] },
    default_duration_minutes: 60,
  },
  CHILL: {
    name: 'Chilling',
    fields: { target_wort_temp_c: 'number', heat_exchanger: 'string', oxygenation_ppm: 'number', transfer_to: 'string' },
    defaults: {},
    default_duration_minutes: 25,
  },
  FERM: {
    name: 'Fermentation',
    fields: {
      style: 'string', yeast: 'string', pitch_rate_million_cells_per_ml_plato: 'number',
      fermentation_profile: { type: 'array', of: { day: 'number', temp_c: 'number' } },
      spunding: { type: 'object', fields: { enable: 'boolean', target_pressure_bar: 'number' } },
      diacetyl_rest: { type: 'object', fields: { trigger: 'string', temp_c: 'number', min_hours: 'number' } },
      equipment_id: 'string', logging_interval_min: 'number',
    },
    defaults: { fermentation_profile: [], spunding: { enable: false } },
    default_duration_minutes: 10080,
  },
  DRYHOP: {
    name: 'Dry Hopping',
    fields: { additions: { type: 'array', of: { day: 'number', hop: 'string', amount_g_per_l: 'number' } }, purge_with_co2: 'boolean', max_oxygen_ppb: 'number' },
    defaults: { additions: [] },
    default_duration_minutes: 2880,
  },
  COND: {
    name: 'Conditioning',
    fields: { cold_crash_c: 'number', cold_crash_hours: 'number', clarifier_addition: { type: 'object', fields: { name: 'string', ml_per_hl: 'number' } } },
    defaults: {},
    default_duration_minutes: 4320,
  },
  PACKAGE: {
    name: 'Packaging',
    fields: { format: { type: 'array', of: 'string' }, target_co2_vols: 'number', dissolved_oxygen_ppb_max: 'number', line: 'string' },
    defaults: { format: [] },
    default_duration_minutes: 180,
  },
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
    const renderField = (key, type, value) => {
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
      if (type?.type === 'object') {
        const f = type.fields || {}
        return (
          <div class="grid grid-cols-1 md:grid-cols-3 gap-2">
            {Object.entries(f).map(([ck, ct]) => (
              <div><label class="block text-xs text-gray-600">{ck}</label>{renderFieldNested(local, ck, ct)}</div>
            ))}
          </div>
        )
      }
      if (type?.type === 'array') {
        const of = type.of
        const template = typeof of === 'string' ? (of === 'number' ? 0 : '') : Object.fromEntries(Object.keys(of).map(k => [k, of[k] === 'number' ? 0 : '']))
        return (
          <div>
            {Array.isArray(local[key]) && local[key].map((item, idx) => (
              <div key={idx} class="grid grid-cols-1 md:grid-cols-5 gap-2 items-end mb-2">
                {typeof of === 'string' ? (
                  <input class="w-full h-[34px] border rounded px-2" v-model={local[key][idx]} onInput={update} />
                ) : (
                  Object.keys(of).map((fk) => (
                    <div><label class="block text-xs text-gray-600">{fk}</label>{renderArrayField(local[key][idx], fk, of[fk])}</div>
                  ))
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
  if (ct === 'number') return (
    <input
      type="number"
      step="any"
      class="w-full h-[34px] border rounded px-2"
      value={obj[ck] ?? ''}
      onInput={(e) => { const t = e.currentTarget ; obj[ck] = t.value === '' ? null : Number(t.value); update() }}
    />
  )
  if (ct === 'boolean') return (<input type="checkbox" class="h-4 w-4" v-model={obj[ck]} onChange={update} />)
  if (typeof ct === 'string') return (<input class="w-full h-[34px] border rounded px-2" v-model={obj[ck]} onInput={update} />)
  if (ct?.type === 'object') {
    const f = ct.fields || {}
    return (<div class="grid grid-cols-1 md:grid-cols-3 gap-2">{Object.entries(f).map(([k, t]) => (<div><label class="block text-xs text-gray-600">{k}</label>{renderFieldNested(obj[ck] || (obj[ck] = {}), k, t)}</div>))}</div>)
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
      onInput={(e) => { const t = e.currentTarget ; row[fk] = t.value === '' ? null : Number(t.value); update() }}
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
      {Object.entries(fields).map(([key, type]) => (
        <div>
          <label class="block text-xs text-gray-600 mb-1">{key}</label>
          {renderField(key, type, local[key])}
        </div>
      ))}
    </div>
  )
}
  }
}

// ----- State -----
const definitions = ref([])
const versions = ref([])
const selectedDefId = ref('')
const selectedVersionId = ref('')
const steps = ref([]) // {id?, localId, step_key, name, position, default_duration_minutes, configObj, qc}
const addKey = ref('')
const saving = ref(false)
const pendingDeletes = new Set()

const { t } = useI18n()

function schemaFor(step_key) { return STEP_SCHEMAS[step_key] || null }

function normalizeSteps(list) {
  list.sort((a, b) => (a.position ?? 0) - (b.position ?? 0))
  steps.value = list.map((r, i) => ({
    id: r.id ?? null,
    localId: r.id || `${Date.now()}-${Math.random()}`,
    step_key: r.step_key,
    name: r.name,
    position: r.position ?? i,
    default_duration_minutes: r.default_duration_minutes ?? null,
    configObj: r.config ?? {},
    qc: r.qc ?? null,
  }))
}

async function loadDefinitions() {
  const { data, error } = await supabase.from('process_definitions').select('id, name').order('created_at', { ascending: false })
  if (!error) definitions.value = data
}

async function loadVersions() {
  selectedVersionId.value = ''; steps.value = []
  if (!selectedDefId.value) return
  const { data, error } = await supabase.from('process_versions').select('*').eq('process_id', selectedDefId.value).order('created_at', { ascending: false })
  if (!error) versions.value = data
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
  const cfg = schema?.defaults ? deepCopy(schema.defaults) : {}
  const pos = steps.value.length
  const nameKey = `recipe.edit.schemas.${key}`
  const nameI18n = t(nameKey)
  const dispName = nameI18n === nameKey ? (schema?.name || key) : nameI18n
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
onMounted(async () => {
  await loadDefinitions()
  const rid = route.params.recipeId as string | undefined
  if (rid) {
    selectedDefId.value = rid
    await loadVersions()
  }
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
