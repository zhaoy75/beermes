<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="currentPageTitle" />
    <div class="max-w-6xl mx-auto px-2 sm:px-4 lg:px-0 pb-10 space-y-6">
      <!-- Top stats -->
      <section class="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <article v-for="card in kpiCards" :key="card.id" class="relative overflow-hidden rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <div class="absolute inset-0 pointer-events-none opacity-90" :class="card.gradient"></div>
          <div class="relative flex items-start justify-between">
            <div>
              <p class="text-[11px] font-semibold uppercase tracking-wide text-slate-500">{{ card.label }}</p>
              <p class="mt-3 text-3xl font-semibold text-slate-900">{{ card.value }}</p>
            </div>
            <span class="inline-flex h-10 w-10 items-center justify-center rounded-full bg-white/70 text-lg shadow-sm ring-1 ring-slate-200 backdrop-blur-sm">{{ card.icon }}</span>
          </div>
          <span v-if="card.chip" class="relative mt-5 inline-flex items-center rounded-full border border-slate-200 px-3 py-1 text-[11px] font-semibold tracking-wide text-slate-500">{{ card.chip }}</span>
        </article>
      </section>

      <!-- Main grid -->
      <section class="grid grid-cols-1 lg:grid-cols-2 gap-6 items-start">
        <!-- In-progress batches -->
        <div class="flex h-full flex-col rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div class="flex items-center justify-between border-b border-slate-100 px-5 py-4">
            <div>
              <h2 class="text-base font-semibold text-slate-900">{{ $t('dashboard.lists.inProgressTitle') }}</h2>
              <p class="text-xs text-slate-500">{{ $t('dashboard.kpis.inProgress') }}</p>
            </div>
            <span class="inline-flex min-w-[2.5rem] justify-center rounded-full bg-amber-100 px-2 py-1 text-xs font-semibold text-amber-800">{{
              inProgressCount }}</span>
          </div>
          <ul class="flex-1 divide-y divide-slate-100">
            <li
              v-for="batch in inProgressBatches"
              :key="batch.batchId"
              class="group flex items-start justify-between gap-3 px-5 py-4 transition hover:bg-slate-50/70"
            >
              <div class="space-y-1">
                <div class="text-sm font-semibold text-slate-800">
                  {{ batch.batchId }}
                  <span class="text-slate-500">• {{ batch.beerName }}</span>
                </div>
                <div class="text-xs text-slate-500">{{
                  $t('dashboard.lists.brewedMeta', {
                    date: fmtDate(batch.brewDate),
                    style: batch.style,
                    liters: batch.batchSize,
                  })
                }}</div>
              </div>
              <span class="rounded-full bg-amber-100 px-2.5 py-1 text-[11px] font-semibold uppercase tracking-wide text-amber-700">{{
                $t('dashboard.lists.inProgressBadge') }}</span>
            </li>
            <li v-if="inProgressBatches.length === 0" class="px-5 py-10 text-center text-sm text-slate-500">{{ $t('dashboard.lists.none') }}</li>
          </ul>
        </div>

        <!-- TODOs -->
        <div class="flex h-full flex-col rounded-2xl border border-slate-200 bg-white shadow-sm">
          <div class="flex items-center justify-between border-b border-slate-100 px-5 py-4">
            <h2 class="text-base font-semibold text-slate-900">{{ $t('dashboard.todos.title') }}</h2>
            <button class="inline-flex items-center gap-1 rounded-full border border-slate-200 px-3 py-1 text-xs font-semibold text-slate-600 transition hover:bg-slate-100"
              @click="addQuickTodo">
              <span class="text-base leading-none">＋</span>
              {{ $t('dashboard.todos.add') }}
            </button>
          </div>
          <ul class="flex-1 divide-y divide-slate-100">
            <li v-for="t in todos" :key="t.id" class="flex items-start gap-3 px-5 py-4">
              <input type="checkbox" v-model="t.done" class="mt-1 h-4 w-4 rounded border-slate-300 text-blue-600 focus:ring-blue-500" />
              <div class="flex-1 space-y-1">
                <div :class="['text-sm font-medium', t.done ? 'text-slate-400 line-through' : 'text-slate-700']">{{ t.text }}</div>
                <div v-if="t.due" class="text-xs text-slate-500">{{ $t('dashboard.todos.due', { date: fmtDate(t.due) }) }}</div>
              </div>
              <button class="text-xs font-semibold text-slate-400 transition hover:text-red-600" @click="removeTodo(t.id)">{{
                $t('dashboard.todos.remove') }}</button>
            </li>
            <li v-if="todos.length === 0" class="px-5 py-10 text-center text-sm text-slate-500">{{ $t('dashboard.todos.empty') }}</li>
          </ul>
          <div class="flex flex-col gap-3 border-t border-slate-100 px-5 py-4 sm:flex-row">
            <input
              v-model.trim="newTodo"
              :placeholder="$t('dashboard.todos.newPlaceholder')"
              class="flex-1 rounded-full border border-slate-200 px-4 py-2 text-sm focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-100"
              @keyup.enter="createTodo"
            />
            <div class="flex flex-col gap-3 sm:flex-row sm:gap-2">
              <input
                v-model="newTodoDue"
                type="date"
                class="w-full rounded-full border border-slate-200 px-3 py-2 text-sm focus:border-blue-400 focus:outline-none focus:ring-2 focus:ring-blue-100"
              />
              <button
                class="inline-flex min-w-[96px] w-full items-center justify-center rounded-full bg-blue-600 px-4 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-700 sm:w-auto"
                @click="createTodo"
              >{{ $t('dashboard.todos.add') }}</button>
            </div>
          </div>
        </div>

        <!-- Charts -->
        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <div class="mb-4 flex items-center justify-between">
            <div>
              <h2 class="text-base font-semibold text-slate-900">{{ $t('dashboard.charts.volumeTitle') }}</h2>
              <p class="text-xs text-slate-500">{{ $t('dashboard.charts.monthly') }}</p>
            </div>
            <span class="inline-flex items-center rounded-full bg-sky-100 px-3 py-1 text-[11px] font-semibold uppercase tracking-wide text-sky-700">L</span>
          </div>
          <div class="h-72">
            <canvas ref="volCanvas"></canvas>
          </div>
        </div>

        <div class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
          <div class="mb-4 flex items-center justify-between">
            <div>
              <h2 class="text-base font-semibold text-slate-900">{{ $t('dashboard.charts.revenueTitle') }}</h2>
              <p class="text-xs text-slate-500">{{ $t('dashboard.charts.monthly') }}</p>
            </div>
            <span class="inline-flex items-center rounded-full bg-emerald-100 px-3 py-1 text-[11px] font-semibold uppercase tracking-wide text-emerald-700">¥</span>
          </div>
          <div class="h-72">
            <canvas ref="revCanvas"></canvas>
          </div>
        </div>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup>
import { ref, computed, onMounted, onBeforeUnmount, reactive, watch } from "vue";
import { useI18n } from 'vue-i18n'
import AdminLayout from "@/components/layout/AdminLayout.vue";
import PageBreadcrumb from "@/components/common/PageBreadcrumb.vue";

const { t } = useI18n()
const currentPageTitle = computed(() => t('dashboard.title'))
import { Chart, registerables } from 'chart.js'
Chart.register(...registerables)

/***** Props *****/
// batches: array of { batchId, beerName, status, brewDate(YYYY-MM-DD), finishDate, style, batchSize(Number) }
// sales: array of { date(YYYY-MM-DD), revenue(Number) }
const props = defineProps({
  batches: {
    type: Array,
    default: () => [
      { batchId:'2025-IPA-001', beerName:'Galaxy IPA', status:'In progress', brewDate:'2025-08-20', finishDate:'', style:'IPA', batchSize:20 },
      { batchId:'2025-STO-002', beerName:'Night Stout', status:'Complete', brewDate:'2025-06-02', finishDate:'2025-06-28', style:'Stout', batchSize:25 },
      { batchId:'2025-LGR-003', beerName:'Kölsch Breeze', status:'Complete', brewDate:'2025-05-10', finishDate:'2025-05-30', style:'Kölsch', batchSize:18 },
      { batchId:'2025-PLS-004', beerName:'Pils Nova', status:'Complete', brewDate:'2025-07-01', finishDate:'2025-07-25', style:'Pilsner', batchSize:30 },
      { batchId:'2025-IPA-005', beerName:'Galaxy IPA', status:'Complete', brewDate:'2025-08-01', finishDate:'2025-08-25', style:'IPA', batchSize:22 }
    ]
  },
  sales: {
    type: Array,
    default: () => [
      { date:'2024-11-01', revenue: 350000 },
      { date:'2024-12-01', revenue: 420000 },
      { date:'2025-01-01', revenue: 380000 },
      { date:'2025-02-01', revenue: 440000 },
      { date:'2025-03-01', revenue: 470000 },
      { date:'2025-04-01', revenue: 390000 },
      { date:'2025-05-01', revenue: 520000 },
      { date:'2025-06-01', revenue: 610000 },
      { date:'2025-07-01', revenue: 580000 },
      { date:'2025-08-01', revenue: 650000 }
    ]
  }
})

/***** State for TODOs *****/
const todos = reactive([
  { id:1, text:'Check fermentation temperature for IPA-001', done:false, due:new Date().toISOString().slice(0,10) },
  { id:2, text:'Order Citra hops', done:false, due:'' },
])
let todoSeq = 3
const newTodo = ref('')
const newTodoDue = ref('')
const addQuickTodo = () => { newTodo.value = t('dashboard.todos.quickNew'); createTodo() }
const createTodo = () => {
  if(!newTodo.value.trim()) return
  todos.push({ id:todoSeq++, text:newTodo.value.trim(), done:false, due:newTodoDue.value || '' })
  newTodo.value = ''; newTodoDue.value = ''
}
const removeTodo = (id) => {
  const i = todos.findIndex(t=>t.id===id)
  if(i>-1) todos.splice(i,1)
}

/***** Derived: batches *****/
const inProgressBatches = computed(() => props.batches.filter(l => l.status === 'In progress'))
const inProgressCount = computed(() => inProgressBatches.value.length)

const completedBatches = computed(() => props.batches.filter(l => l.status === 'Complete'))

function monthKey(d){ const dt = new Date(d+'T00:00:00'); return `${dt.getFullYear()}-${String(dt.getMonth()+1).padStart(2,'0')}` }
function lastNMonthKeys(n){
  const arr=[]; const now=new Date(); now.setDate(1); // normalize first of month
  for(let i=n-1;i>=0;i--){ const d=new Date(now); d.setMonth(now.getMonth()-i); arr.push(`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`) }
  return arr
}

// Volume per month from completed batches (by finishDate)
const volumeMonthly = computed(()=>{
  const labels = lastNMonthKeys(12)
  const map = Object.fromEntries(labels.map(k=>[k,0]))
  for(const l of completedBatches.value){ if(l.finishDate){ const k = monthKey(l.finishDate); if(k in map) map[k]+= Number(l.batchSize||0) }}
  return { labels, data: labels.map(k=>map[k]) }
})

// Revenue per month from sales
const revenueMonthly = computed(()=>{
  const labels = lastNMonthKeys(12)
  const map = Object.fromEntries(labels.map(k=>[k,0]))
  for(const s of props.sales){ const k = monthKey(s.date); if(k in map) map[k]+= Number(s.revenue||0) }
  return { labels, data: labels.map(k=>map[k]) }
})

// 30-day KPIs
const volume30d = computed(()=> completedBatches.value
  .filter(l => l.finishDate && (Date.now() - new Date(l.finishDate+'T00:00:00')) <= 30*24*3600*1000)
  .reduce((a,b)=> a + Number(b.batchSize||0), 0))
const revenue30d = computed(()=> props.sales
  .filter(s => (Date.now() - new Date(s.date+'T00:00:00')) <= 30*24*3600*1000)
  .reduce((a,b)=> a + Number(b.revenue||0), 0))
const completed30d = computed(()=> completedBatches.value
  .filter(l => l.finishDate && (Date.now() - new Date(l.finishDate+'T00:00:00')) <= 30*24*3600*1000).length)

const kpiCards = computed(() => [
  {
    id: 'in-progress',
    label: t('dashboard.kpis.inProgress'),
    value: inProgressCount.value.toLocaleString(),
    chip: 'LIVE',
    icon: '🧪',
    gradient: 'bg-gradient-to-br from-amber-200/45 via-white to-transparent',
  },
  {
    id: 'completed',
    label: t('dashboard.kpis.completed30d'),
    value: completed30d.value.toLocaleString(),
    chip: '30D',
    icon: '✅',
    gradient: 'bg-gradient-to-br from-indigo-200/45 via-white to-transparent',
  },
  {
    id: 'volume',
    label: t('dashboard.kpis.volume30d'),
    value: `${volume30d.value.toLocaleString()} L`,
    chip: '30D',
    icon: '🛢️',
    gradient: 'bg-gradient-to-br from-sky-200/45 via-white to-transparent',
  },
  {
    id: 'revenue',
    label: t('dashboard.kpis.revenue30d'),
    value: `¥${revenue30d.value.toLocaleString()}`,
    chip: '30D',
    icon: '💴',
    gradient: 'bg-gradient-to-br from-emerald-200/45 via-white to-transparent',
  },
])

/***** Charts *****/
const volCanvas = ref(null)
const revCanvas = ref(null)
let volChart, revChart

const fmtMonth = (k) => { const [y,m]=k.split('-'); return `${y}/${m}` }

function makeLineChart(ctx, labels, data, label){
  return new Chart(ctx, {
    type:'line',
    data:{ labels: labels.map(fmtMonth), datasets:[{ label, data, tension:.3, fill:false }] },
    options:{
      responsive:true,
      maintainAspectRatio:false,
      plugins:{ legend:{ display:false }, tooltip:{ callbacks:{ label:(c)=> `${c.parsed.y.toLocaleString()}` } } },
      scales:{ x:{ grid:{ display:false } }, y:{ beginAtZero:true } }
    }
  })
}

onMounted(()=>{
  volChart = makeLineChart(volCanvas.value.getContext('2d'), volumeMonthly.value.labels, volumeMonthly.value.data, t('dashboard.charts.volumeDataset'))
  revChart = makeLineChart(revCanvas.value.getContext('2d'), revenueMonthly.value.labels, revenueMonthly.value.data, t('dashboard.charts.revenueDataset'))
})

onBeforeUnmount(()=>{ volChart?.destroy(); revChart?.destroy() })

watch(volumeMonthly, ({labels, data})=>{
  if(!volChart) return
  volChart.data.labels = labels.map(fmtMonth)
  volChart.data.datasets[0].data = data
  volChart.update()
})

watch(revenueMonthly, ({labels, data})=>{
  if(!revChart) return
  revChart.data.labels = labels.map(fmtMonth)
  revChart.data.datasets[0].data = data
  revChart.update()
})

/***** Utils *****/
const fmtDate = (d) => d ? new Date(d+"T00:00:00").toLocaleDateString() : ''
</script>

<style scoped>
/* Give each chart some height for responsiveness */
canvas { display:block; width:100%; height:300px; }
</style>
