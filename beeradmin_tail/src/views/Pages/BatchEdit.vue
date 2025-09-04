<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="currentPageTitle" />
    <!-- <header class="sticky top-0 z-10 bg-white/90 backdrop-blur border-b border-gray-200 mb-4">
      <div class="flex items-center gap-2 py-3">
        <svg class="w-5 h-5 text-blue-600" viewBox="0 0 24 24" fill="none" aria-hidden="true">
          <path d="M4 10h16M6 6h12M8 14h8m-9 4h10" stroke="currentColor" stroke-width="1.5" stroke-linecap="round" />
        </svg>
        <div>
          <h1 class="text-base font-semibold leading-none">Craft Beer Process Manager</h1>
          <p class="text-xs text-gray-500">Vue 3 • Tailwind • Mobile‑first</p>
        </div>
        <span class="ml-auto inline-flex items-center gap-2 text-xs rounded-full border px-2 py-1"
          :class="overallStatus.class">
          <span class="w-1.5 h-1.5 rounded-full" :class="overallStatus.dot" />{{ overallStatus.text }}
        </span>
      </div>
    </header> -->

    <!-- Lot Summary -->
    <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4 mb-4">
      <h2 class="text-lg font-semibold mb-3">Lot Summary</h2>
      <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
        <div>
          <label for="lotId" class="block text-sm text-gray-600 mb-1">Lot ID</label>
          <input id="lotId" v-model.trim="lot.lotId" class="w-full h-[42px] border rounded px-3"
            placeholder="2025-IPA-001" />
        </div>
        <div>
          <label for="beerName" class="block text-sm text-gray-600 mb-1">Beer Name</label>
          <input id="beerName" v-model.trim="lot.beerName" class="w-full h-[42px] border rounded px-3"
            placeholder="Galaxy IPA" />
        </div>
        <div>
          <label for="style" class="block text-sm text-gray-600 mb-1">Style</label>
          <input id="style" v-model.trim="lot.style" class="w-full h-[42px] border rounded px-3"
            placeholder="IPA / Stout / Lager" />
        </div>
        <div>
          <label for="batchSize" class="block text-sm text-gray-600 mb-1">Batch Size (L)</label>
          <input id="batchSize" type="number" min="0" step="0.1" v-model.number="lot.batchSize"
            class="w-full h-[42px] border rounded px-3" placeholder="20" />
        </div>
        <div>
          <label for="og" class="block text-sm text-gray-600 mb-1">Target OG</label>
          <input id="og" type="number" step="0.001" v-model.number="lot.targetOG"
            class="w-full h-[42px] border rounded px-3" placeholder="1.060" />
        </div>
        <div>
          <label for="fg" class="block text-sm text-gray-600 mb-1">Target FG</label>
          <input id="fg" type="number" step="0.001" v-model.number="lot.targetFG"
            class="w-full h-[42px] border rounded px-3" placeholder="1.012" />
        </div>
        <div>
          <label for="brewDate" class="block text-sm text-gray-600 mb-1">Brew Date</label>
          <input id="brewDate" type="date" v-model="lot.brewDate" class="w-full h-[42px] border rounded px-3" />
        </div>
        <div class="sm:col-span-2">
          <label for="notes" class="block text-sm text-gray-600 mb-1">Lot Notes</label>
          <input id="notes" v-model.trim="lot.notes" class="w-full h-[42px] border rounded px-3"
            placeholder="hops, yeast, targets..." />
        </div>
      </div>
      <div class="flex items-center gap-2 mt-3 text-sm">
        <span
          class="inline-flex items-center gap-1 rounded-full border px-2 py-1 text-emerald-700 border-emerald-200 bg-emerald-50">Est.
          ABV: {{ estABV.toFixed(1) }}%</span>
        <span class="inline-flex items-center gap-1 rounded-full border px-2 py-1"
          :class="attenuationBadge.class">Attenuation: {{ attenuation.toFixed(0) }}%</span>
      </div>
    </section>

    <!-- Process Sections -->
    <section class="space-y-3" aria-label="Process sections">
      <details v-for="(proc, idx) in processes" :key="proc.key" :open="idx === 0 ? true : proc.open"
        class="group border border-gray-200 rounded-xl bg-white shadow-sm overflow-hidden">
        <summary @click.prevent="toggle(proc)"
          class="flex items-center justify-between gap-3 cursor-pointer select-none p-4">
          <div class="flex items-center gap-2">
            <svg class="w-4 h-4 text-gray-500" viewBox="0 0 24 24" fill="none" aria-hidden="true">
              <path d="M12 15l-6-6h12l-6 6z" stroke="currentColor" stroke-width="1.5" fill="currentColor" />
            </svg>
            <span class="font-semibold">{{ proc.title }}</span>
          </div>
          <span class="text-xs rounded-full border px-2 py-1" :class="sectionBadge(proc)">{{ sectionStatus(proc)
            }}</span>
        </summary>
        <div class="px-4 pb-4 pt-0">
          <div class="grid grid-cols-1 sm:grid-cols-2 gap-3">
            <div>
              <label :for="proc.key + '-start'" class="block text-sm text-gray-600 mb-1">Start</label>
              <input :id="proc.key + '-start'" type="datetime-local" v-model="proc.data.start"
                class="w-full h-[42px] border rounded px-3" />
            </div>
            <div>
              <label :for="proc.key + '-end'" class="block text-sm text-gray-600 mb-1">End</label>
              <input :id="proc.key + '-end'" type="datetime-local" v-model="proc.data.end"
                class="w-full h-[42px] border rounded px-3" />
            </div>
            <div v-for="field in proc.fields" :key="field.key">
              <label :for="proc.key + '-' + field.key" class="block text-sm text-gray-600 mb-1">
                {{ field.label }} <span v-if="field.unit">({{ field.unit }})</span>
              </label>
              <input :id="proc.key + '-' + field.key" :type="field.type || 'text'" :step="field.step || null"
                :min="field.min ?? null" :max="field.max ?? null" v-model="proc.data[field.key]"
                :placeholder="field.placeholder || ''" class="w-full h-[42px] border rounded px-3" />
            </div>
            <div class="sm:col-span-2">
              <label :for="proc.key + '-notes'" class="block text-sm text-gray-600 mb-1">Notes</label>
              <textarea :id="proc.key + '-notes'" v-model="proc.data.notes" class="w-full min-h-[88px] border rounded p-3"
                placeholder="Observations, deviations, next actions..."></textarea>
            </div>
          </div>
          <div class="flex flex-wrap gap-2 mt-3">
            <button class="px-3 py-2 text-sm border rounded hover:bg-gray-50" @click="clearSection(proc)">Clear</button>
            <button class="px-3 py-2 text-sm rounded bg-blue-600 text-white hover:bg-blue-700"
              @click="markDone(proc)">Mark Done</button>
          </div>
          <p v-if="proc.doneAt" class="text-xs text-gray-500 mt-2">Done at: {{ fmt(proc.doneAt) }}</p>
        </div>
      </details>
    </section>

    <!-- Audit / Footer Actions -->
    <section class="bg-white border border-gray-200 rounded-xl shadow-sm p-4 mt-4">
      <h3 class="text-base font-semibold mb-1">Audit</h3>
      <p class="text-sm text-gray-600">Autosave: {{ lastSaved ? ('saved ' + timeAgo(lastSaved)) : 'pending…' }}</p>
      <div class="flex gap-2 mt-3 flex-wrap">
        <button class="px-3 py-2 text-sm rounded bg-blue-600 text-white hover:bg-blue-700" @click="save()">Save</button>
        <button class="px-3 py-2 text-sm border rounded hover:bg-gray-50" @click="exportJSON()">Export JSON</button>
        <input id="importFile" ref="importEl" type="file" accept="application/json" class="hidden"
          @change="importJSON($event)" />
        <button class="px-3 py-2 text-sm border rounded hover:bg-gray-50" @click="importEl?.click()">Import</button>
        <button class="px-3 py-2 text-sm border rounded hover:bg-gray-50" @click="resetAll()">Reset</button>
      </div>
    </section>
  </AdminLayout>
</template>

<script setup>
import {  computed, reactive, watch, ref  } from "vue";
import AdminLayout from "@/components/layout/AdminLayout.vue";
import PageBreadcrumb from "@/components/common/PageBreadcrumb.vue";

const currentPageTitle = ref("バッチ情報編集");
const DEFAULT_PROCESSES = [
  {
    key: 'milling', title: 'Milling', fields: [
      { key: 'grainBillKg', label: 'Grain Bill', type: 'number', step: '0.1', unit: 'kg' },
      { key: 'crushGap', label: 'Crush Gap', type: 'number', step: '0.01', unit: 'mm' },
    ]
  },
  {
    key: 'mashing', title: 'Mashing', fields: [
      { key: 'strikeTemp', label: 'Strike Temp', type: 'number', step: '0.1', unit: '°C' },
      { key: 'mashTemp', label: 'Mash Temp', type: 'number', step: '0.1', unit: '°C' },
      { key: 'mashPH', label: 'Mash pH', type: 'number', step: '0.01' },
    ]
  },
  {
    key: 'lautering', title: 'Lautering', fields: [
      { key: 'spargeTemp', label: 'Sparge Temp', type: 'number', step: '0.1', unit: '°C' },
      { key: 'preBoilVol', label: 'Pre-boil Volume', type: 'number', step: '0.1', unit: 'L' },
      { key: 'preBoilGravity', label: 'Pre-boil Gravity', type: 'number', step: '0.001' },
    ]
  },
  {
    key: 'boil', title: 'Boil', fields: [
      { key: 'boilTime', label: 'Boil Time', type: 'number', step: '1', unit: 'min' },
      { key: 'hopAdditions', label: 'Hop Additions', placeholder: '10g @60, 20g @10' },
    ]
  },
  {
    key: 'whirlpool', title: 'Whirlpool', fields: [
      { key: 'whirlpoolTemp', label: 'Temp', type: 'number', step: '0.1', unit: '°C' },
      { key: 'whirlpoolTime', label: 'Time', type: 'number', step: '1', unit: 'min' },
    ]
  },
  {
    key: 'cooling', title: 'Cooling', fields: [
      { key: 'toFermenterTemp', label: 'To Fermenter Temp', type: 'number', step: '0.1', unit: '°C' },
      { key: 'oxygenation', label: 'Oxygenation', placeholder: '60 sec @1 LPM' },
    ]
  },
  {
    key: 'fermentation', title: 'Fermentation', fields: [
      { key: 'yeast', label: 'Yeast', placeholder: 'US-05' },
      { key: 'pitchRate', label: 'Pitch Rate', type: 'number', step: '0.01', unit: 'M cells/mL/°P' },
      { key: 'og', label: 'Original Gravity', type: 'number', step: '0.001' },
      { key: 'fg', label: 'Final Gravity', type: 'number', step: '0.001' },
      { key: 'temp', label: 'Temp', type: 'number', step: '0.1', unit: '°C' },
    ]
  },
  {
    key: 'conditioning', title: 'Conditioning', fields: [
      { key: 'coldCrashing', label: 'Cold Crashing Temp', type: 'number', step: '0.1', unit: '°C' },
      { key: 'diacetylTest', label: 'Diacetyl Test', placeholder: 'pass/fail & notes' },
    ]
  },
  {
    key: 'packaging', title: 'Packaging', fields: [
      { key: 'method', label: 'Method', placeholder: 'keg/bottle/can' },
      { key: 'co2Vol', label: 'CO₂ Volumes', type: 'number', step: '0.1' },
      { key: 'packagedVol', label: 'Packaged Volume', type: 'number', step: '0.1', unit: 'L' },
    ]
  },
]

// --- State
const lot = reactive({ lotId: '', beerName: '', style: '', batchSize: '', targetOG: '', targetFG: '', brewDate: '', notes: '' })
const processes = reactive(DEFAULT_PROCESSES.map(p => blankSection(p)))
const lastSaved = ref(null)
const importEl = ref(null)

// --- Helpers
function blankSection(proc) {
  const data = { start: '', end: '', notes: '' }
  proc.fields.forEach(f => { data[f.key] = '' })
  return { ...proc, open: false, doneAt: null, data }
}
const fmt = iso => new Date(iso).toLocaleString()
const timeAgo = iso => {
  if (!iso) return ''
  const s = Math.floor((Date.now() - new Date(iso)) / 1000)
  if (s < 60) return `${s}s ago`
  const m = Math.floor(s / 60); if (m < 60) return `${m}m ago`
  const h = Math.floor(m / 60); if (h < 24) return `${h}h ago`
  const d = Math.floor(h / 24); return `${d}d ago`
}

// --- Derived metrics
const estABV = computed(() => {
  const og = Number(lot.targetOG || 0), fg = Number(lot.targetFG || 0)
  if (!og || !fg) return 0
  return Math.max(0, (og - fg) * 131.25)
})
const attenuation = computed(() => {
  const og = Number(lot.targetOG || 0), fg = Number(lot.targetFG || 0)
  if (!og || !fg || og <= 1) return 0
  return ((og - fg) / (og - 1)) * 100
})
const attenuationBadge = computed(() => {
  const a = attenuation.value
  if (a > 86) return { class: 'text-emerald-700 border border-emerald-200 bg-emerald-50 rounded-full px-2 py-1' }
  if (a > 70) return { class: 'text-amber-700 border border-amber-200 bg-amber-50 rounded-full px-2 py-1' }
  return { class: 'text-red-700 border border-red-200 bg-red-50 rounded-full px-2 py-1' }
})

const overallStatus = computed(() => {
  const total = processes.length
  const done = processes.filter(p => p.doneAt).length
  if (done === 0) return { text: 'Not started', class: 'border border-red-200 bg-red-50 text-red-700', dot: 'bg-red-600' }
  if (done < total) return { text: `In progress (${done}/${total})`, class: 'border border-amber-200 bg-amber-50 text-amber-700', dot: 'bg-amber-500' }
  return { text: 'Complete', class: 'border border-emerald-200 bg-emerald-50 text-emerald-700', dot: 'bg-emerald-600' }
})

function sectionStatus(proc) {
  if (proc.doneAt) return 'Done'
  const keys = Object.keys(proc.data)
  const filled = keys.filter(k => String(proc.data[k] ?? '').trim().length > 0).length
  return filled > 2 ? 'In progress' : 'Empty'
}
function sectionBadge(proc) {
  const s = sectionStatus(proc)
  if (s === 'Done') return 'text-emerald-700 border border-emerald-200 bg-emerald-50'
  if (s === 'In progress') return 'text-amber-700 border border-amber-200 bg-amber-50'
  return 'text-gray-600 border border-gray-200 bg-gray-50'
}

// --- Actions
function toggle(proc) { proc.open = !proc.open }
function clearSection(proc) { Object.assign(proc, blankSection(proc)) }
function markDone(proc) { proc.doneAt = new Date().toISOString() }

// --- Persistence
const STORAGE_KEY = 'craft-beer-process-v1'
const payload = () => ({
  lot: JSON.parse(JSON.stringify(lot)),
  processes: processes.map(p => ({ key: p.key, title: p.title, fields: p.fields, open: p.open, doneAt: p.doneAt, data: p.data }))
})
function save() {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(payload()))
  lastSaved.value = new Date().toISOString()
}
function load() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY)
    if (!raw) return
    const obj = JSON.parse(raw)
    Object.assign(lot, obj.lot || {})
    if (Array.isArray(obj.processes)) {
      const map = new Map(obj.processes.map(p => [p.key, p]))
      processes.splice(0, processes.length, ...DEFAULT_PROCESSES.map(def => {
        const stored = map.get(def.key)
        return stored ? { ...def, ...stored } : blankSection(def)
      }))
    }
    lastSaved.value = new Date().toISOString()
  } catch (e) { console.error(e) }
}
function exportJSON() {
  const blob = new Blob([JSON.stringify(payload(), null, 2)], { type: 'application/json' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url; a.download = `${lot.lotId || 'lot'}-brew-notes.json`; a.click()
  URL.revokeObjectURL(url)
}
function importJSON(evt) {
  const file = evt.target.files?.[0]
  if (!file) return
  const reader = new FileReader()
  reader.onload = () => {
    try {
      const obj = JSON.parse(reader.result)
      if (obj.lot) Object.assign(lot, obj.lot)
      if (Array.isArray(obj.processes)) {
        const map = new Map(obj.processes.map(p => [p.key, p]))
        processes.splice(0, processes.length, ...DEFAULT_PROCESSES.map(def => {
          const stored = map.get(def.key)
          return stored ? { ...def, ...stored } : blankSection(def)
        }))
      }
      save()
    } catch { alert('Invalid JSON file') }
    evt.target.value = ''
  }
  reader.readAsText(file)
}
function resetAll() {
  if (!confirm('Reset all data?')) return
  localStorage.removeItem(STORAGE_KEY)
  Object.assign(lot, { lotId: '', beerName: '', style: '', batchSize: '', targetOG: '', targetFG: '', brewDate: '', notes: '' })
  processes.splice(0, processes.length, ...DEFAULT_PROCESSES.map(p => blankSection(p)))
  lastSaved.value = null
}

// Auto-save
let t
function debounce(fn, ms = 600) { return (...args) => { clearTimeout(t); t = setTimeout(() => fn(...args), ms) } }
const debouncedSave = debounce(save)
watch(lot, debouncedSave, { deep: true })
watch(processes, debouncedSave, { deep: true })

// Init
load()
</script>

<!-- Using Tailwind utility classes; no scoped styles needed. -->
<style>
/***** Optional: smooth details open/close *****/
details[open]>summary+* {
  animation: fadeIn .2s ease-in
}

@keyframes fadeIn {
  from {
    opacity: .5;
    transform: translateY(-2px)
  }

  to {
    opacity: 1;
    transform: none
  }
}
</style>
