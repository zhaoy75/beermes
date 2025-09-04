<!-- src/components/SupaTabulator.vue -->
<template>
  <div class="space-y-3">
    <form class="flex gap-2 items-center" @submit.prevent>
      <input
        v-model="search"
        class="border rounded px-3 py-2"
        placeholder="Search name/email/phone…"
      />
      <label class="text-sm opacity-70">
        Page size
        <select v-model.number="pageSize" class="border rounded px-2 py-1 ml-1">
          <option :value="10">10</option>
          <option :value="20">20</option>
          <option :value="50">50</option>
        </select>
      </label>
    </form>

    <div ref="tableEl"></div>
  </div>
</template>


<script setup lang="ts">
import { ref, onMounted, onBeforeUnmount, watch } from 'vue'
import { TabulatorFull as Tabulator }  from 'tabulator-tables/dist/js/tabulator_esm.js'
import type {
  ColumnDefinition,
  //RowComponent,
  CellEditEventCallback,
} from 'tabulator-tables'
import { supabase } from '@/lib/supabase'

/**
 * Example assumes a table `contacts`:
 *  id (uuid, pk), name text, email text, phone text, created_at timestamptz
 * Enable RLS and add policies for your app users.
 */

type Contact = {
  id: string
  name: string
  email: string | null
  phone: string | null
  created_at: string
}

const tableEl = ref<HTMLDivElement | null>(null)
//const { default: Tabulator } = await import('tabulator-tables/dist/js/tabulator_esm.js')
let table: Tabulator | null = null

// UI state
const search = ref('')
const pageSize = ref(10)

// Tabulator columns (inline editors included)
const columns: ColumnDefinition[] = [
  { title: 'Name', field: 'name', sorter: 'string', editor: 'input', headerSort: true, validator: ['required'] },
  { title: 'Email', field: 'email', sorter: 'string', editor: 'input', headerSort: true },
  { title: 'Phone', field: 'phone', sorter: 'string', editor: 'input', headerSort: true },
  { title: 'Created', field: 'created_at', sorter: 'datetime', headerSort: true },
  {
    title: 'Delete',
    field: 'actions',
    headerHozAlign: 'center',
    hozAlign: 'center',
    formatter: () => '🗑️',
    cellClick: async (_e, cell) => {
      const row = cell.getRow()
      const data = row.getData() as Contact
      const { error } = await supabase.from('contacts').delete().eq('id', data.id)
      if (error) return alert(error.message)
      table?.setData() // reload current page
    },
    width: 90
  }
]

// Server loader: Tabulator calls this with current page/sort/filter
/* eslint-disable @typescript-eslint/no-explicit-any */
async function fetchPage(_url: string, _config: any, params: any) {
  const page = params.page || 1
  const size = params.size || pageSize.value
  const from = (page - 1) * size
  const to = from + size - 1

  let q = supabase.from('contacts').select('*', { count: 'exact' }).range(from, to)

  // sort (use first sorter)
  const sorter = (params.sorters || [])[0]
  if (sorter) {
    q = q.order(sorter.field, { ascending: sorter.dir === 'asc' })
  }

  // filter by search (name OR email OR phone)
  const s = (params.filters?.[0]?.value ?? search.value)?.toString().trim()
  if (s) {
    q = q.or(`name.ilike.*${s}*,email.ilike.*${s}*,phone.ilike.*${s}*`)
  }

  const { data, count, error } = await q
  if (error) throw error

  return {
    data: (data || []) as Contact[],
    last_page: Math.max(1, Math.ceil((count || 0) / size)),
  }
}

onMounted(async () => {
  // Build table
  table = new Tabulator(tableEl.value as HTMLDivElement, {
    height: 520,
    layout: 'fitColumns',
    placeholder: 'No data',
    pagination: 'remote',
    paginationSize: pageSize.value,
    ajaxURL: '/',              // unused, but required by Tabulator
    ajaxURLGenerator: (url: string) => url, // keep same URL
    ajaxURLFunc: fetchPage,    // ← our Supabase loader
    columns,
  })

  // Inline edit → Supabase update
  const onCellEdited: CellEditEventCallback = async (cell) => {
    const field = cell.getField()
    if (['id', 'created_at'].includes(field)) return

    const rowData = cell.getRow().getData() as Contact
    const value = cell.getValue()

    const { error } = await supabase
      .from('contacts')
      .update({ [field]: value })
      .eq('id', rowData.id)

    if (error) {
      // revert on failure
      cell.restoreOldValue()
      alert('Update failed: ' + error.message)
    }
  }
  table.on('cellEdited', onCellEdited)

  // Optional: realtime auto-refresh
  supabase.channel('contacts-rt')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'contacts' }, () => {
      table?.setData()
    })
    .subscribe()
})

onBeforeUnmount(() => {
  supabase.removeAllChannels()
  table?.destroy()
  table = null
})

// Refresh when search or page size changes
watch(search, () => table?.setData())
watch(pageSize, (n) => table?.setPageSize(n))
</script>



<style scoped>
/* Add any additional styles here if needed */
</style>
