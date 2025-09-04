<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="currentPageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-6xl mx-auto">
      <!-- Header -->
      <header class="mb-4 flex items-center justify-between">
        <div>
          <h1 class="text-xl font-semibold">Beer Tax Maintenance</h1>
          <p class="text-sm text-gray-500">Supabase‑backed CRUD for beer tax table</p>
        </div>
        <div class="flex gap-2">
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">New</button>
          <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50" @click="fetchTaxes">Refresh</button>
        </div>
      </header>

      <!-- Desktop Table -->
      <section class="hidden md:block overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">id</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">category</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">note</th>
              <th class="px-3 py-2 text-right text-xs font-medium text-gray-600">taxrate</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">created_date</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">effect_date</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">expire_date</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">Actions</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in rows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.id }}</td>
              <td class="px-3 py-2">{{ row.category }}</td>
              <td class="px-3 py-2 text-gray-600">{{ row.note }}</td>
              <td class="px-3 py-2 text-right">{{ fmtRate(row.taxrate) }}</td>
              <td class="px-3 py-2">{{ fmtDate(row.created_date) }}</td>
              <td class="px-3 py-2">{{ fmtDate(row.effect_date) }}</td>
              <td class="px-3 py-2">{{ fmtDate(row.expire_date) }}</td>
              <td class="px-3 py-2 space-x-2">
                <button class="px-2 py-1 text-sm rounded border hover:bg-gray-100" @click="openEdit(row)">Edit</button>
                <button class="px-2 py-1 text-sm rounded bg-red-600 text-white hover:bg-red-700"
                  @click="confirmDelete(row)">Delete</button>
              </td>
            </tr>
            <tr v-if="rows.length === 0">
              <td colspan="8" class="px-3 py-8 text-center text-gray-500">No data</td>
            </tr>
          </tbody>
        </table>
      </section>

      <!-- Mobile Cards -->
      <section class="md:hidden space-y-3">
        <div v-for="row in rows" :key="row.id" class="border border-gray-200 rounded-xl shadow-sm p-3">
          <div class="flex items-start justify-between gap-3">
            <div>
              <div class="text-sm text-gray-500">id</div>
              <div class="font-mono text-xs text-gray-700">{{ row.id }}</div>
            </div>
            <div class="flex gap-2">
              <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openEdit(row)">Edit</button>
              <button class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700"
                @click="confirmDelete(row)">Delete</button>
            </div>
          </div>
          <dl class="grid grid-cols-2 gap-2 mt-2 text-sm">
            <div>
              <dt class="text-gray-500">category</dt>
              <dd class="font-medium">{{ row.category }}</dd>
            </div>
            <div>
              <dt class="text-gray-500">taxrate</dt>
              <dd class="font-medium">{{ fmtRate(row.taxrate) }}</dd>
            </div>
            <div class="col-span-2">
              <dt class="text-gray-500">note</dt>
              <dd class="text-gray-700">{{ row.note }}</dd>
            </div>
            <div>
              <dt class="text-gray-500">created_date</dt>
              <dd class="font-medium">{{ fmtDate(row.created_date) }}</dd>
            </div>
            <div>
              <dt class="text-gray-500">effect_date</dt>
              <dd class="font-medium">{{ fmtDate(row.effect_date) }}</dd>
            </div>
            <div>
              <dt class="text-gray-500">expire_date</dt>
              <dd class="font-medium">{{ fmtDate(row.expire_date) }}</dd>
            </div>
          </dl>
        </div>
        <p v-if="rows.length === 0" class="text-center text-gray-500 py-8">No data</p>
      </section>
      <!-- Editor Modal -->
      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
        <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg border border-gray-200">
          <div class="flex items-center justify-between px-4 py-3 border-b">
            <h2 class="text-base font-semibold">{{ form.id ? 'Edit' : 'Create' }} Beer Tax</h2>
            <button class="px-2 py-1 text-sm rounded border hover:bg-gray-50" @click="closeModal">Close</button>
          </div>
          <div class="p-4 grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm text-gray-600 mb-1">id</label>
              <input class="w-full h-[40px] border rounded px-3 bg-gray-50 text-gray-500" :value="form.id || 'Auto'"
                disabled>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">category<span class="text-red-600">*</span></label>
              <input v-model.trim="form.category" class="w-full h-[40px] border rounded px-3"
                placeholder="e.g., IPA / Lager" />
              <p v-if="errors.category" class="mt-1 text-xs text-red-600">{{ errors.category }}</p>
            </div>
            <div class="sm:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">note</label>
              <input v-model.trim="form.note" class="w-full h-[40px] border rounded px-3" placeholder="optional" />
              <p v-if="errors.note" class="mt-1 text-xs text-red-600">{{ errors.note }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">taxrate<span class="text-red-600">*</span></label>
              <input v-model="form.taxrate" type="number" step="0.001" min="0"
                class="w-full h-[40px] border rounded px-3" placeholder="e.g., 0.08" />
              <p v-if="errors.taxrate" class="mt-1 text-xs text-red-600">{{ errors.taxrate }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">created_date<span class="text-red-600">*</span></label>
              <input v-model="form.created_date" type="date" class="w-full h-[40px] border rounded px-3" />
              <p v-if="errors.created_date" class="mt-1 text-xs text-red-600">{{ errors.created_date }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">effect_date<span class="text-red-600">*</span></label>
              <input v-model="form.effect_date" type="date" class="w-full h-[40px] border rounded px-3" />
              <p v-if="errors.effect_date" class="mt-1 text-xs text-red-600">{{ errors.effect_date }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">expire_date<span class="text-red-600">*</span></label>
              <input v-model="form.expire_date" type="date" class="w-full h-[40px] border rounded px-3" />
              <p v-if="errors.expire_date" class="mt-1 text-xs text-red-600">{{ errors.expire_date }}</p>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">Cancel</button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" :disabled="saving"
              @click="saveRecord">{{ saving ? 'Saving…' : 'Save' }}</button>
          </div>
        </div>
      </div>

      <!-- Delete confirm -->
      <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
        <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">Delete Record</h3>
          </div>
          <div class="p-4 text-sm">Are you sure you want to delete <span class="font-mono">{{ toDelete?.id }}</span>?
            This cannot be undone.</div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="showDelete = false">Cancel</button>
            <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700"
              @click="deleteRecord">Delete</button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { supabase } from '../../lib/supabase'
import AdminLayout from "@/components/layout/AdminLayout.vue";
import PageBreadcrumb from "@/components/common/PageBreadcrumb.vue";


const currentPageTitle = ref("酒税管理")

/**
 * Configure Supabase
 * - Put your credentials in Vite env: VITE_SUPABASE_URL, VITE_SUPABASE_ANON_KEY
 * - Table name: beer_taxes
 *   Columns:
 *     id (uuid default gen_random_uuid() or bigint primary key)
 *     category (text)
 *     note (text)
 *     taxrate (numeric)
 *     created_date (date)
 *     effect_date (date)
 *     expire_date (date)
 */
// const supabase = createClient(
//   import.meta.env.VITE_SUPABASE_URL,
//   import.meta.env.VITE_SUPABASE_ANON_KEY
// )

const rows = ref([])
const loading = ref(false)
const saving = ref(false)

// Modal state
const showModal = ref(false)
const showDelete = ref(false)
const toDelete = ref(null)

const blank = () => ({
  id: null,
  category: '',
  note: '',
  taxrate: '',
  created_date: new Date().toISOString().slice(0, 10),
  effect_date: '',
  expire_date: ''
})
const form = reactive(blank())
const errors = reactive({})

function resetForm() { Object.assign(form, blank()); Object.keys(errors).forEach(k => delete errors[k]) }

async function fetchTaxes() {
  loading.value = true
  const { data, error } = await supabase
    .from('taxrate')
    .select('*')
    .order('effect_date', { ascending: false })
  loading.value = false
  if (error) { alert('Fetch error: ' + error.message); return }
  rows.value = data || []
}

function fmtDate(d) { return d ? new Date(d + 'T00:00:00').toLocaleDateString() : '' }
function fmtRate(r) { const n = Number(r); return isNaN(n) ? '' : n.toFixed(3) }

function openCreate() { resetForm(); showModal.value = true }
function openEdit(row) { resetForm(); Object.assign(form, row); showModal.value = true }
function closeModal() { showModal.value = false }

function confirmDelete(row) { toDelete.value = row; showDelete.value = true }
async function deleteRecord() {
  if (!toDelete.value) return
  const { error } = await supabase.from('taxrate').delete().eq('id', toDelete.value.id)
  if (error) { alert('Delete error: ' + error.message); return }
  rows.value = rows.value.filter(r => r.id !== toDelete.value.id)
  showDelete.value = false; toDelete.value = null
}

function isDateString(v) { return /^\d{4}-\d{2}-\d{2}$/.test(String(v || '')) }

function validate() {
  Object.keys(errors).forEach(k => delete errors[k])
  if (!form.category) errors.category = 'category is required'
  // taxrate: number >= 0
  const rate = Number(form.taxrate)
  if (form.taxrate === '' || isNaN(rate)) errors.taxrate = 'taxrate must be a number'
  else if (rate < 0) errors.taxrate = 'taxrate must be >= 0'

  // dates: required + proper order
  // if (!isDateString(form.created_date)) errors.created_date = 'created_date (YYYY-MM-DD)'
  // if (!isDateString(form.effect_date)) errors.effect_date = 'effect_date (YYYY-MM-DD)'
  // if (!isDateString(form.expire_date)) errors.expire_date = 'expire_date (YYYY-MM-DD)'

  if (!errors.effect_date && !errors.expire_date) {
    const eff = new Date(form.effect_date + 'T00:00:00')
    const exp = new Date(form.expire_date + 'T00:00:00')
    if (eff > exp) errors.expire_date = 'expire_date must be after effect_date'
  }

  return Object.keys(errors).length === 0
}

async function saveRecord() {
  if (!validate()) return
  saving.value = true
  const payload = {
    category: form.category,
    note: form.note || null,
    taxrate: Number(form.taxrate),
    created_date: form.created_date,
    effect_date: form.effect_date === '' ? null : form.effect_date,
    expire_date: form.expire_date === '' ? null : form.expire_date
  }
  let resp
  if (form.id) {
    resp = await supabase.from('taxrate').update(payload).eq('id', form.id).select('*').single()
  } else {
    resp = await supabase.from('taxrate').insert(payload).select('*').single()
  }
  saving.value = false
  if (resp.error) { alert('Save error: ' + resp.error.message); return }

  const saved = resp.data
  // Update local list (optimistic upsert)
  const idx = rows.value.findIndex(r => r.id === saved.id)
  if (idx > -1) rows.value[idx] = saved
  else rows.value.unshift(saved)

  showModal.value = false
}

onMounted(fetchTaxes)
</script>

<style scoped>
/***** Optional: table tweaks *****/
th,
td {
  white-space: nowrap;
}

td:nth-child(3) {
  white-space: normal;
}
</style>
