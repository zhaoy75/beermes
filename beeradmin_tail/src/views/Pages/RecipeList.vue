<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="currentPageTitle" />

    <!-- Search -->
    <section class="mb-6 bg-white shadow rounded-lg p-4 border border-gray-200" aria-labelledby="searchHeading">
      <div class="flex items-center justify-between mb-4">
        <h2 id="searchHeading" class="text-lg font-semibold">{{ $t('recipe.list.searchTitle') }}</h2>
        <div class="flex items-center gap-2">
          <button class="text-sm px-3 py-1 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">{{ $t('common.new') }}</button>
          <button class="text-sm px-3 py-1 rounded border border-gray-300 hover:bg-gray-100" @click="resetSearch">{{ $t('recipe.list.reset') }}</button>
        </div>
      </div>
      <form class="grid grid-cols-1 md:grid-cols-5 gap-4" @submit.prevent>
        <div>
          <label class="block text-sm text-gray-600 mb-1">{{ $t('recipe.list.status') }}</label>
          <select v-model="search.status" class="w-full h-[36px] border rounded px-3 py-2">
            <option value="">{{ $t('recipe.list.all') }}</option>
            <option value="draft">{{ $t('recipe.statusMap.draft') }}</option>
            <option value="released">{{ $t('recipe.statusMap.released') }}</option>
            <option value="retired">{{ $t('recipe.statusMap.retired') }}</option>
          </select>
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1">{{ $t('recipe.list.startDate') }}</label>
          <input type="date" v-model="search.startDate" class="w-full h-[36px] border rounded px-3 py-2" />
        </div>
        <div>
          <label class="block text-sm text-gray-600 mb-1">{{ $t('recipe.list.endDate') }}</label>
          <input type="date" v-model="search.endDate" class="w-full h-[36px] border rounded px-3 py-2" />
        </div>
        <div class="md:col-span-2">
          <label class="block text-sm text-gray-600 mb-1">{{ $t('recipe.list.keyword') }}</label>
          <input type="search" v-model.trim="search.q" :placeholder="$t('recipe.list.keywordPh')"
            class="w-full h-[36px] border rounded px-3 py-2" />
        </div>
      </form>
      <div class="mt-2 text-sm text-gray-500">{{ $t('recipe.list.showing', { count: sortedRows.length }) }}</div>
    </section>

    <!-- Table -->
    <section>
      <div class="hidden md:block overflow-x-auto">
        <table class="min-w-full border border-gray-200 divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-2 text-left text-sm font-medium text-gray-600">
                <button class="inline-flex items-center gap-1" @click="setSort('recipe_id')">
                  {{ $t('recipe.list.recipeId') }} <span class="text-xs opacity-60">{{ sortIcon('recipe_id') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left text-sm font-medium text-gray-600">
                <button class="inline-flex items-center gap-1" @click="setSort('name')">
                  {{ $t('recipe.list.name') }} <span class="text-xs opacity-60">{{ sortIcon('name') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left text-sm font-medium text-gray-600">
                <button class="inline-flex items-center gap-1" @click="setSort('version')">
                  {{ $t('recipe.list.version') }} <span class="text-xs opacity-60">{{ sortIcon('version') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left text-sm font-medium text-gray-600">
                <button class="inline-flex items-center gap-1" @click="setSort('status')">
                  {{ $t('recipe.list.status') }} <span class="text-xs opacity-60">{{ sortIcon('status') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-left text-sm font-medium text-gray-600">
                <button class="inline-flex items-center gap-1" @click="setSort('created_at')">
                  {{ $t('recipe.list.created') }} <span class="text-xs opacity-60">{{ sortIcon('created_at') }}</span>
                </button>
              </th>
              <th class="px-3 py-2 text-sm font-medium text-gray-600">{{ $t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="r in sortedRows" :key="r.version_id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs">{{ r.recipe_id }}</td>
              <td class="px-3 py-2">{{ r.name }}</td>
              <td class="px-3 py-2">{{ r.version }}</td>
              <td class="px-3 py-2"><span :class="['px-2 py-1 text-xs rounded-full', statusClass(r.status)]">{{ r.status }}</span></td>
              <td class="px-3 py-2">{{ fmtDate(r.created_at) }}</td>
              <td class="px-3 py-2 space-x-2">
                <router-link :to="{ path: `/recipeEdit/${r.recipe_id}` }" class="px-2 py-1 text-sm border rounded hover:bg-gray-100">Details</router-link>
                <button class="px-2 py-1 text-sm border rounded hover:bg-gray-100" @click="openEdit(r)">{{ $t('common.edit') }}</button>
                <button class="px-2 py-1 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(r)">{{ $t('common.delete') }}</button>
              </td>
            </tr>
            <tr v-if="sortedRows.length === 0">
              <td colspan="6" class="px-3 py-6 text-center text-gray-500">{{ $t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </div>

      <!-- Mobile cards -->
      <div class="grid gap-3 md:hidden">
        <div v-for="r in sortedRows" :key="r.version_id" class="border rounded-lg p-3">
          <div class="flex items-center justify-between">
            <div class="font-mono text-xs">{{ r.recipe_id }}</div>
            <span :class="['px-2 py-1 text-xs rounded-full', statusClass(r.status)]">{{ r.status }}</span>
          </div>
          <div class="text-sm mt-1">{{ r.name }} <span class="text-gray-500">• {{ r.version }}</span></div>
          <div class="text-xs text-gray-500">{{ fmtDate(r.created_at) }}</div>
          <div class="flex justify-end gap-2 mt-2">
            <router-link :to="{ path: `/recipeEdit/${r.recipe_id}` }" class="px-2 py-1 text-xs border rounded hover:bg-gray-100">Details</router-link>
            <button class="px-2 py-1 text-xs border rounded hover:bg-gray-100" @click="openEdit(r)">{{ $t('common.edit') }}</button>
            <button class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(r)">{{ $t('common.delete') }}</button>
          </div>
        </div>
      </div>
    </section>

    <!-- Editor Modal -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
      <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg border border-gray-200">
        <div class="flex items-center justify-between px-4 py-3 border-b">
          <h2 class="text-base font-semibold">{{ form.version_id ? $t('recipe.list.editTitle') : $t('recipe.list.newTitle') }}</h2>
          <button class="px-2 py-1 text-sm rounded border hover:bg-gray-50" @click="closeModal">{{ $t('common.close') }}</button>
        </div>
        <div class="p-4 grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ $t('recipe.list.orgId') }}</label>
            <input v-model.trim="form.org_id" :disabled="form.version_id" class="w-full h-[40px] border rounded px-3" placeholder="org uuid" />
            <p v-if="errors.org_id" class="mt-1 text-xs text-red-600">{{ errors.org_id }}</p>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ $t('recipe.list.name') }}</label>
            <input v-model.trim="form.name" class="w-full h-[40px] border rounded px-3" />
            <p v-if="errors.name" class="mt-1 text-xs text-red-600">{{ errors.name }}</p>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ $t('recipe.list.version') }}</label>
            <input v-model.trim="form.version" class="w-full h-[40px] border rounded px-3" />
            <p v-if="errors.version" class="mt-1 text-xs text-red-600">{{ errors.version }}</p>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ $t('recipe.list.status') }}</label>
            <select v-model="form.status" class="w-full h-[40px] border rounded px-3">
              <option value="draft">draft</option>
              <option value="released">released</option>
              <option value="retired">retired</option>
            </select>
            <p v-if="errors.status" class="mt-1 text-xs text-red-600">{{ errors.status }}</p>
          </div>
        </div>
        <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
          <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">{{ $t('common.cancel') }}</button>
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" :disabled="saving" @click="saveRecord">{{ saving ? $t('common.saving') : $t('common.save') }}</button>
        </div>
      </div>
    </div>

    <!-- Delete confirm -->
    <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
      <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
        <div class="px-4 py-3 border-b">
          <h3 class="font-semibold">{{ $t('common.delete') }}</h3>
        </div>
        <div class="p-4 text-sm">{{ $t('recipe.list.deleteConfirm', { version: toDelete?.version, name: toDelete?.name }) }}</div>
        <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
          <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="showDelete = false">{{ $t('common.cancel') }}</button>
          <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700" @click="deleteRecord">{{ $t('common.delete') }}</button>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup>
import { ref, reactive, computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase'
import AdminLayout from "@/components/layout/AdminLayout.vue";
import PageBreadcrumb from "@/components/common/PageBreadcrumb.vue";

const { t } = useI18n()
const currentPageTitle = computed(() => t('recipe.list.title'))
const rows = ref([])
const loading = ref(false)
const saving = ref(false)

// Modal state
const showModal = ref(false)
const showDelete = ref(false)
const toDelete = ref(null)

const form = reactive({ version_id: null, process_id: null, recipe_id: null, org_id: '', name: '', version: '', status: 'draft' })
const errors = reactive({})

const search = reactive({ status: '', startDate: '', endDate: '', q: '' })

const sortKey = ref('created_at')
const sortDir = ref('desc')

function setSort(key) { if (sortKey.value === key) sortDir.value = sortDir.value === 'asc' ? 'desc' : 'asc'; else { sortKey.value = key; sortDir.value = 'asc' } }
function sortIcon(key) { if (sortKey.value !== key) return '↕'; return sortDir.value === 'asc' ? '▲' : '▼' }

function statusClass(s) { if (s === 'released') return 'bg-green-100 text-green-800'; if (s === 'draft') return 'bg-yellow-100 text-yellow-800'; if (s === 'retired') return 'bg-gray-200 text-gray-700'; return 'bg-gray-100 text-gray-800' }
function fmtDate(d) { return d ? new Date(d).toLocaleString() : '' }

async function fetchData() {
  loading.value = true
  const [defs, vers] = await Promise.all([
    supabase.from('process_definitions').select('*'),
    supabase.from('process_versions').select('*')
  ])
  loading.value = false
  if (defs.error) { alert('Fetch definitions error: ' + defs.error.message); return }
  if (vers.error) { alert('Fetch versions error: ' + vers.error.message); return }
  const byId = Object.fromEntries((defs.data || []).map(d => [d.id, d]))
  rows.value = (vers.data || []).map(v => {
    const def = byId[v.process_id]
    return {
      version_id: v.id,
      process_id: v.process_id,
      recipe_id: def?.id ?? v.process_id,
      name: def?.name ?? '(unknown)',
      version: v.version,
      status: v.status,
      created_at: v.created_at,
      org_id: def?.org_id ?? ''
    }
  })
}

const parseDate = (d) => d ? new Date(d + 'T00:00:00') : null
const inRange = (dateStr, startStr, endStr) => {
  if (!dateStr) return true
  const d = new Date(dateStr)
  const s = parseDate(startStr)
  const e = parseDate(endStr)
  if (s && d < s) return false
  if (e) { const eod = new Date(e); eod.setHours(23,59,59,999); if (d > eod) return false }
  return true
}

const filteredRows = computed(() => {
  const q = search.q.toLowerCase()
  return rows.value.filter(r => {
    const statusOk = !search.status || r.status === search.status
    const dateOk = inRange(r.created_at, search.startDate, search.endDate)
    const textOk = !q || `${r.name} ${r.version}`.toLowerCase().includes(q)
    return statusOk && dateOk && textOk
  })
})

const sortedRows = computed(() => {
  const arr = [...filteredRows.value]
  const dir = sortDir.value === 'asc' ? 1 : -1
  const key = sortKey.value
  const val = (r) => {
    if (key === 'created_at') return new Date(r.created_at).getTime()
    return (r[key] ?? '').toString().toLowerCase()
  }
  arr.sort((a,b) => { const va = val(a), vb = val(b); if (va < vb) return -1*dir; if (va > vb) return 1*dir; return 0 })
  return arr
})

function openCreate() { Object.assign(form, { version_id: null, process_id: null, recipe_id: null, org_id: '', name: '', version: '', status: 'draft' }); clearErrors(); showModal.value = true }
function openEdit(r) { Object.assign(form, r); clearErrors(); showModal.value = true }
function closeModal() { showModal.value = false }
function clearErrors() { for (const k of Object.keys(errors)) delete errors[k] }

function validate() {
  clearErrors()
  if (!form.name) errors.name = 'name required'
  if (!form.version) errors.version = 'version required'
  if (!['draft','released','retired'].includes(form.status)) errors.status = 'invalid status'
  if (!form.version_id && !/^\w{8}(-\w{4}){3}-\w{12}$/.test(String(form.org_id))) errors.org_id = 'org_id must be UUID'
  return Object.keys(errors).length === 0
}

async function saveRecord() {
  if (!validate()) return
  saving.value = true
  try {
    if (form.version_id) {
      // Update definition name
      const { error: e1 } = await supabase.from('process_definitions').update({ name: form.name }).eq('id', form.recipe_id)
      if (e1) throw new Error(e1.message)
      // Update version entry
      const { error: e2 } = await supabase.from('process_versions').update({ version: form.version, status: form.status }).eq('id', form.version_id)
      if (e2) throw new Error(e2.message)
    } else {
      // Create definition then version
      const { data: d1, error: e1 } = await supabase.from('process_definitions').insert({ org_id: form.org_id, name: form.name }).select('*').single()
      if (e1) throw new Error(e1.message)
      const payloadV = { process_id: d1.id, version: form.version, status: form.status }
      const { data: d2, error: e2 } = await supabase.from('process_versions').insert(payloadV).select('*').single()
      if (e2) throw new Error(e2.message)
    }
  } catch (e) {
    saving.value = false; alert('Save error: ' + e.message); return
  }
  saving.value = false
  showModal.value = false
  fetchData()
}

function confirmDelete(r) { toDelete.value = r; showDelete.value = true }
async function deleteRecord() {
  if (!toDelete.value) return
  const verId = toDelete.value.version_id
  const procId = toDelete.value.process_id
  const { error } = await supabase.from('process_versions').delete().eq('id', verId)
  if (error) { alert('Delete error: ' + error.message); return }
  // if no versions remain, delete definition too
  const { data: remain, error: e2 } = await supabase.from('process_versions').select('id').eq('process_id', procId).limit(1)
  if (!e2 && (remain || []).length === 0) {
    await supabase.from('process_definitions').delete().eq('id', procId)
  }
  showDelete.value = false; toDelete.value = null; fetchData()
}

function resetSearch() { search.status=''; search.startDate=''; search.endDate=''; search.q='' }

onMounted(fetchData)
</script>

<style scoped>
th, td { white-space: nowrap; }
</style>
