<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="currentPageTitle" />
    <!-- Top stats -->
    <section class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 mb-4">
      <div class="rounded-xl border border-gray-200 p-4 shadow-sm">
        <div class="text-xs text-gray-500">{{ $t('dashboard.kpis.inProgress') }}</div>
        <div class="mt-1 text-2xl font-bold">{{ inProgressCount }}</div>
      </div>
      <div class="rounded-xl border border-gray-200 p-4 shadow-sm">
        <div class="text-xs text-gray-500">{{ $t('dashboard.kpis.completed30d') }}</div>
        <div class="mt-1 text-2xl font-bold">{{ completed30d }}</div>
      </div>
      <div class="rounded-xl border border-gray-200 p-4 shadow-sm">
        <div class="text-xs text-gray-500">{{ $t('dashboard.kpis.volume30d') }}</div>
        <div class="mt-1 text-2xl font-bold">{{ volume30d.toLocaleString() }} L</div>
      </div>
      <div class="rounded-xl border border-gray-200 p-4 shadow-sm">
        <div class="text-xs text-gray-500">{{ $t('dashboard.kpis.revenue30d') }}</div>
        <div class="mt-1 text-2xl font-bold">¥{{ revenue30d.toLocaleString() }}</div>
      </div>
    </section>

    <!-- Main grid -->
    <section class="grid grid-cols-1 lg:grid-cols-3 gap-4">
      <!-- Left column: lists -->
      <div class="space-y-4 lg:col-span-1">
        <!-- In-progress lots list -->
        <div class="rounded-xl border border-gray-200 shadow-sm">
          <div class="p-4 border-b border-gray-100 flex items-center justify-between">
            <h2 class="text-base font-semibold">{{ $t('dashboard.lists.inProgressTitle') }}</h2>
            <span class="text-xs px-2 py-1 rounded-full bg-amber-50 text-amber-700 border border-amber-200">{{
              inProgressCount }}</span>
          </div>
          <ul class="divide-y divide-gray-100">
            <li v-for="lot in inProgressLots" :key="lot.lotId" class="p-3 flex items-center justify-between">
              <div>
                <div class="font-medium">{{ lot.lotId }} <span class="text-gray-500">• {{ lot.beerName }}</span></div>
                <div class="text-xs text-gray-500">{{ $t('dashboard.lists.brewedMeta', { date: fmtDate(lot.brewDate), style: lot.style, liters: lot.batchSize }) }}</div>
              </div>
              <span class="text-xs rounded-full px-2 py-1 bg-amber-100 text-amber-800">{{ $t('batch.statusMap.In progress') }}</span>
            </li>
            <li v-if="inProgressLots.length === 0" class="p-4 text-sm text-gray-500">{{ $t('dashboard.lists.none') }}</li>
          </ul>
        </div>

        <!-- TODOs -->
        <div class="rounded-xl border border-gray-200 shadow-sm">
          <div class="p-4 border-b border-gray-100 flex items-center justify-between">
            <h2 class="text-base font-semibold">{{ $t('dashboard.todos.title') }}</h2>
            <button class="text-sm px-2 py-1 border rounded hover:bg-gray-50" @click="addQuickTodo">{{ $t('dashboard.todos.add') }}</button>
          </div>
          <ul class="divide-y divide-gray-100">
            <li v-for="t in todos" :key="t.id" class="p-3 flex items-center gap-3">
              <input type="checkbox" v-model="t.done" class="h-4 w-4" />
              <div class="flex-1">
                <div :class="['text-sm', t.done ? 'line-through text-gray-400' : '']">{{ t.text }}</div>
                <div class="text-xs text-gray-500" v-if="t.due">{{ $t('dashboard.todos.due', { date: fmtDate(t.due) }) }}</div>
              </div>
              <button class="text-xs text-gray-500 hover:text-red-600" @click="removeTodo(t.id)">{{ $t('dashboard.todos.remove') }}</button>
            </li>
            <li v-if="todos.length === 0" class="p-4 text-sm text-gray-500">{{ $t('dashboard.todos.empty') }}</li>
          </ul>
          <div class="p-3 flex gap-2">
            <input v-model.trim="newTodo" :placeholder="$t('dashboard.todos.newPlaceholder')" class="flex-1 border rounded px-3 h-[38px]"
              @keyup.enter="createTodo" />
            <input v-model="newTodoDue" type="date" class="border rounded px-2 h-[38px]" />
            <button class="px-3 rounded bg-blue-600 text-white hover:bg-blue-700 h-[38px]"
              @click="createTodo">{{ $t('dashboard.todos.add') }}</button>
          </div>
        </div>
      </div>

      <!-- Right column: charts -->
      <div class="space-y-4 lg:col-span-2">
        <div class="rounded-xl border border-gray-200 p-3 shadow-sm">
          <div class="flex items-center justify-between mb-2">
            <h2 class="text-base font-semibold">{{ $t('dashboard.charts.volumeTitle') }}</h2>
            <div class="text-xs text-gray-500">{{ $t('dashboard.charts.monthly') }}</div>
          </div>
          <div class="max-h-[320px]">
            <canvas ref="volCanvas" height="140"></canvas>
          </div>
        </div>
        <div class="rounded-xl border border-gray-200 p-3 shadow-sm">
          <div class="flex items-center justify-between mb-2">
            <h2 class="text-base font-semibold">{{ $t('dashboard.charts.revenueTitle') }}</h2>
            <div class="text-xs text-gray-500">{{ $t('dashboard.charts.monthly') }}</div>
          </div>
          <div class="max-h-[320px]">
            <canvas ref="revCanvas" height="140"></canvas>
          </div>
        </div>
      </div>
    </section>
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
// lots: array of { lotId, beerName, status, brewDate(YYYY-MM-DD), finishDate, style, batchSize(Number) }
// sales: array of { date(YYYY-MM-DD), revenue(Number) }
const props = defineProps({
  lots: {
    type: Array,
    default: () => [
      { lotId:'2025-IPA-001', beerName:'Galaxy IPA', status:'In progress', brewDate:'2025-08-20', finishDate:'', style:'IPA', batchSize:20 },
      { lotId:'2025-STO-002', beerName:'Night Stout', status:'Complete', brewDate:'2025-06-02', finishDate:'2025-06-28', style:'Stout', batchSize:25 },
      { lotId:'2025-LGR-003', beerName:'Kölsch Breeze', status:'Complete', brewDate:'2025-05-10', finishDate:'2025-05-30', style:'Kölsch', batchSize:18 },
      { lotId:'2025-PLS-004', beerName:'Pils Nova', status:'Complete', brewDate:'2025-07-01', finishDate:'2025-07-25', style:'Pilsner', batchSize:30 },
      { lotId:'2025-IPA-005', beerName:'Galaxy IPA', status:'Complete', brewDate:'2025-08-01', finishDate:'2025-08-25', style:'IPA', batchSize:22 }
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

/***** Derived: lots *****/
const inProgressLots = computed(() => props.lots.filter(l => l.status === 'In progress'))
const inProgressCount = computed(() => inProgressLots.value.length)

const completedLots = computed(() => props.lots.filter(l => l.status === 'Complete'))

function monthKey(d){ const dt = new Date(d+'T00:00:00'); return `${dt.getFullYear()}-${String(dt.getMonth()+1).padStart(2,'0')}` }
function lastNMonthKeys(n){
  const arr=[]; const now=new Date(); now.setDate(1); // normalize first of month
  for(let i=n-1;i>=0;i--){ const d=new Date(now); d.setMonth(now.getMonth()-i); arr.push(`${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}`) }
  return arr
}

// Volume per month from completed lots (by finishDate)
const volumeMonthly = computed(()=>{
  const labels = lastNMonthKeys(12)
  const map = Object.fromEntries(labels.map(k=>[k,0]))
  for(const l of completedLots.value){ if(l.finishDate){ const k = monthKey(l.finishDate); if(k in map) map[k]+= Number(l.batchSize||0) }}
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
const volume30d = computed(()=> completedLots.value
  .filter(l => l.finishDate && (Date.now() - new Date(l.finishDate+'T00:00:00')) <= 30*24*3600*1000)
  .reduce((a,b)=> a + Number(b.batchSize||0), 0))
const revenue30d = computed(()=> props.sales
  .filter(s => (Date.now() - new Date(s.date+'T00:00:00')) <= 30*24*3600*1000)
  .reduce((a,b)=> a + Number(b.revenue||0), 0))
const completed30d = computed(()=> completedLots.value
  .filter(l => l.finishDate && (Date.now() - new Date(l.finishDate+'T00:00:00')) <= 30*24*3600*1000).length)

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
