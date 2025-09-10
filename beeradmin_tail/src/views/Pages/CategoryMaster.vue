<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="currentPageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 max-w-4xl mx-auto">
      <!-- Header -->
      <header class="mb-4 flex items-center justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ $t('category.title') }}</h1>
          <p class="text-sm text-gray-500">{{ $t('category.subtitle') }}</p>
        </div>
        <div class="flex gap-2">
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreate">{{ $t('common.new') }}</button>
          <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50" @click="fetchCategories">{{ $t('common.refresh') }}</button>
        </div>
      </header>

      <!-- Table -->
      <section class="overflow-x-auto border border-gray-200 rounded-xl shadow-sm">
        <table class="min-w-full divide-y divide-gray-200">
          <thead class="bg-gray-50">
            <tr>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ $t('labels.id') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ $t('labels.name') }}</th>
              <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ $t('common.actions') }}</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-gray-100">
            <tr v-for="row in rows" :key="row.id" class="hover:bg-gray-50">
              <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.id }}</td>
              <td class="px-3 py-2">{{ row.name }}</td>
              <td class="px-3 py-2 space-x-2">
                <button class="px-2 py-1 text-sm rounded border hover:bg-gray-100" @click="openEdit(row)">{{ $t('common.edit') }}</button>
                <button class="px-2 py-1 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="confirmDelete(row)">{{ $t('common.delete') }}</button>
              </td>
            </tr>
            <tr v-if="rows.length === 0">
              <td colspan="3" class="px-3 py-8 text-center text-gray-500">{{ $t('common.noData') }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <!-- Editor Modal -->
      <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
        <div class="w-full max-w-lg bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ form.id ? $t('category.editTitle') : $t('category.newTitle') }}</h3>
          </div>
          <div class="p-4 space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ $t('labels.id') }}</label>
                <input
                  v-model="form.id"
                  :disabled="editing"
                  type="number"
                  class="w-full h-[40px] border rounded px-3 disabled:bg-gray-50"
                  placeholder="カテゴリID"
                />
                <p v-if="errors.id" class="mt-1 text-xs text-red-600">{{ errors.id }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ $t('labels.name') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="form.name" class="w-full h-[40px] border rounded px-3" />
                <p v-if="errors.name" class="mt-1 text-xs text-red-600">{{ errors.name }}</p>
              </div>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeModal">{{ $t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" :disabled="saving" @click="saveRecord">
              {{ saving ? $t('common.saving') : $t('common.save') }}
            </button>
          </div>
        </div>
      </div>

      <!-- Delete confirm -->
      <div v-if="showDelete" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40">
        <div class="w-full max-w-md bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b">
            <h3 class="font-semibold">{{ $t('category.deleteTitle') }}</h3>
          </div>
          <div class="p-4 text-sm">{{ $t('category.deleteConfirm', { id: toDelete?.id }) }}</div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="showDelete = false">{{ $t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-red-600 text-white hover:bg-red-700" @click="deleteRecord">{{ $t('common.delete') }}</button>
          </div>
        </div>
      </div>
    </div>
  </AdminLayout>

</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import { supabase } from '../../lib/supabase'
import AdminLayout from "@/components/layout/AdminLayout.vue";
import PageBreadcrumb from "@/components/common/PageBreadcrumb.vue";

const { t } = useI18n()
const currentPageTitle = computed(() => t('category.title'))

// Adjust this to match your Supabase table name
const TABLE = 'category' // e.g., 'brew_category' or 'category'

const rows = ref([])
const loading = ref(false)
const saving = ref(false)

// Modal state
const showModal = ref(false)
const showDelete = ref(false)
const toDelete = ref(null)
// const editing = computed(() => form.id !== null && form.id !== '' && form.id !== undefined)

const blank = () => ({
  id: '',
  name: '',
})
const form = reactive(blank())
const errors = reactive({})
const editing = ref(false)

function resetForm() {
  Object.assign(form, blank())
  Object.keys(errors).forEach(k => delete errors[k])
}

async function fetchCategories() {
  loading.value = true
  const { data, error } = await supabase
    .from(TABLE)
    .select('*')
    .order('id', { ascending: true })
  loading.value = false
  if (error) { alert('Fetch error: ' + error.message); return }
  rows.value = data || []
}

function openCreate() { editing.value = false; resetForm(); showModal.value = true }
function openEdit(row) { editing.value = true; resetForm(); Object.assign(form, row); showModal.value = true }
function closeModal() { showModal.value = false }

function confirmDelete(row) { toDelete.value = row; showDelete.value = true }
async function deleteRecord() {
  if (!toDelete.value) return
  const { error } = await supabase.from(TABLE).delete().eq('id', toDelete.value.id)
  if (error) { alert('Delete error: ' + error.message); return }
  rows.value = rows.value.filter(r => r.id !== toDelete.value.id)
  showDelete.value = false; toDelete.value = null
}

function validate() {
  Object.keys(errors).forEach(k => delete errors[k])
  // id: optional, but if provided must be an integer
  if (form.id !== null && form.id !== '' && form.id !== undefined) {
    const idNum = Number(form.id)
    if (!Number.isInteger(idNum)) errors.id = t('errors.mustBeInteger', { field: t('labels.id') })
    else if (idNum < 0) errors.id = t('errors.rateMin', { field: t('labels.id') })
  }

  // name: required, string
  if (!form.name || String(form.name).trim() === '') errors.name = t('errors.required', { field: t('labels.name') })

  return Object.keys(errors).length === 0
}

async function saveRecord() {
  if (!validate()) return
  saving.value = true
  const payload = { name: form.name?.trim() || '' }
  // Only include id on create if user entered it; do not allow id change on edit
  if (!editing.value && form.id !== null && form.id !== '' && form.id !== undefined) {
    payload.id = Number(form.id)
  }

  let resp
  if (editing.value) {
    resp = await supabase.from(TABLE).update({ name: payload.name }).eq('id', form.id).select('*').single()
  } else {
    resp = await supabase.from(TABLE).insert(payload).select('*').single()
  }
  saving.value = false
  if (resp.error) { alert('Save error: ' + resp.error.message); return }

  const saved = resp.data
  const idx = rows.value.findIndex(r => r.id === saved.id)
  if (idx > -1) rows.value[idx] = saved
  else rows.value.push(saved)
  showModal.value = false
}

onMounted(fetchCategories)
</script>

<style scoped>
th, td { white-space: nowrap; }
</style>
