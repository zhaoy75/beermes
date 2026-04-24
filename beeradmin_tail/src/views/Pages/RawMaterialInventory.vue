<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white p-4 text-gray-900">
      <div class="w-full space-y-6">
        <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h1 class="text-xl font-semibold">{{ pageTitle }}</h1>
            <p class="text-sm text-gray-500">{{ t('rawMaterialInventory.subtitle') }}</p>
          </div>

          <div class="flex flex-wrap items-center gap-2">
            <button
              type="button"
              class="rounded bg-blue-600 px-3 py-2 text-sm font-medium text-white shadow-sm transition hover:bg-blue-700 disabled:opacity-50"
              :disabled="loading"
              @click="openCreate"
            >
              {{ t('rawMaterialInventory.actions.newInventory') }}
            </button>
            <button
              type="button"
              class="rounded border border-gray-300 px-3 py-2 text-sm text-gray-900 hover:bg-gray-100 disabled:opacity-50"
              :disabled="loading"
              @click="loadInventory"
            >
              {{ t('common.refresh') }}
            </button>
          </div>
        </header>

        <div class="grid grid-cols-1 gap-6" :class="contentGridClass">
          <div class="relative" :class="showTypePanel ? 'xl:block' : 'xl:hidden'">
            <aside class="rounded-xl border border-gray-200 bg-white shadow-sm">
              <div class="border-b border-gray-200 px-4 py-3">
                <h2 class="text-sm font-semibold text-gray-900">{{ t('rawMaterialInventory.treeTitle') }}</h2>
                <p class="mt-1 text-xs text-gray-500">{{ t('rawMaterialInventory.treeHint') }}</p>
              </div>

              <div class="space-y-3 p-4">
                <div class="relative">
                  <input
                    v-model.trim="typeSearchTerm"
                    type="search"
                    class="h-[40px] w-full rounded border border-gray-300 bg-white px-3 pr-9 text-sm"
                    :placeholder="t('rawMaterialInventory.placeholders.typeSearch')"
                  />
                  <span class="pointer-events-none absolute inset-y-0 right-3 flex items-center text-gray-400">
                    <svg xmlns="http://www.w3.org/2000/svg" class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-4.35-4.35m0 0A7.5 7.5 0 1016.65 16.65z" />
                    </svg>
                  </span>
                </div>

                <div class="rounded-lg border border-dashed border-gray-300 bg-gray-50 px-3 py-3">
                  <div class="text-xs text-gray-500">{{ t('rawMaterialInventory.selectedType') }}</div>
                  <div v-if="selectedType" class="mt-1">
                    <div class="font-medium text-gray-900">{{ displayMaterialTypeName(selectedType) }}</div>
                    <div class="font-mono text-xs text-gray-500">{{ selectedType.code }}</div>
                    <div class="mt-1 text-xs text-gray-500">{{ selectedTypePathText }}</div>
                  </div>
                  <div v-else class="mt-1 text-sm text-gray-500">{{ t('common.all') }}</div>
                </div>
              </div>

              <div class="max-h-[620px] overflow-y-auto px-2 pb-3">
                <div v-if="materialTypeTreeEntries.length === 0" class="px-3 py-6 text-sm text-gray-500">
                  {{ t('rawMaterialInventory.empty.typeTree') }}
                </div>

                <ul v-else class="space-y-1">
                  <li v-for="entry in materialTypeTreeEntries" :key="entry.node.row.type_id">
                    <div class="flex items-center gap-1" :style="{ paddingLeft: `${8 + entry.depth * 16}px` }">
                      <button
                        v-if="isExpandableType(entry.node.row.type_id)"
                        type="button"
                        class="flex h-8 w-8 items-center justify-center rounded text-gray-500 transition hover:bg-gray-50 hover:text-gray-700"
                        :aria-label="typeToggleLabel(isTypeExpanded(entry.node.row.type_id))"
                        :title="typeToggleLabel(isTypeExpanded(entry.node.row.type_id))"
                        @click.stop="toggleTypeExpanded(entry.node.row.type_id)"
                      >
                        <span aria-hidden="true">{{ isTypeExpanded(entry.node.row.type_id) ? '▾' : '▸' }}</span>
                      </button>
                      <span v-else class="inline-block h-8 w-8" aria-hidden="true" />

                      <button
                        type="button"
                        class="flex min-w-0 flex-1 items-center rounded px-2 py-2 text-left text-sm transition hover:bg-gray-50"
                        :class="filters.materialTypeId === entry.node.row.type_id ? 'bg-blue-50 text-blue-700 ring-1 ring-blue-200' : 'text-gray-700'"
                        @click="selectType(entry.node.row.type_id)"
                      >
                        <span class="truncate">{{ displayMaterialTypeName(entry.node.row) }}</span>
                      </button>
                    </div>
                  </li>
                </ul>
              </div>
            </aside>

            <button
              type="button"
              class="absolute right-0 top-6 z-10 hidden h-9 w-7 translate-x-1/2 items-center justify-center rounded-full border border-gray-300 bg-white text-gray-500 shadow-sm transition hover:border-gray-400 hover:bg-gray-50 hover:text-gray-700 xl:flex"
              :aria-label="typePanelToggleText"
              :title="typePanelToggleText"
              @click="toggleTypePanel"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 6l-6 6 6 6" />
              </svg>
            </button>
          </div>

          <section class="relative space-y-6">
            <button
              v-if="!showTypePanel"
              type="button"
              class="absolute left-0 top-6 z-10 hidden h-9 w-7 -translate-x-1/2 items-center justify-center rounded-full border border-gray-300 bg-white text-gray-500 shadow-sm transition hover:border-gray-400 hover:bg-gray-50 hover:text-gray-700 xl:flex"
              :aria-label="typePanelToggleText"
              :title="typePanelToggleText"
              @click="toggleTypePanel"
            >
              <svg xmlns="http://www.w3.org/2000/svg" class="h-3.5 w-3.5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 6l6 6-6 6" />
              </svg>
            </button>

            <section class="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
              <form class="grid grid-cols-1 gap-4 md:grid-cols-2" @submit.prevent>
                <div>
                  <label class="mb-1 block text-sm text-gray-600">{{ t('rawMaterialInventory.filters.materialName') }}</label>
                  <input
                    v-model.trim="filters.keyword"
                    type="search"
                    class="h-[40px] w-full rounded border border-gray-300 px-3"
                    :placeholder="t('rawMaterialInventory.placeholders.materialName')"
                  />
                </div>

                <div>
                  <label class="mb-1 block text-sm text-gray-600">{{ t('rawMaterialInventory.filters.location') }}</label>
                  <select v-model="filters.locationId" class="h-[40px] w-full rounded border border-gray-300 bg-white px-3">
                    <option value="">{{ t('common.all') }}</option>
                    <option v-for="option in locationOptions" :key="option.value" :value="option.value">
                      {{ option.label }}
                    </option>
                  </select>
                </div>
              </form>
            </section>

            <section class="rounded-xl border border-gray-200 bg-white shadow-sm">
              <div class="border-b border-gray-200 px-4 py-3">
                <div class="flex items-center justify-between gap-3">
                  <div>
                    <h2 class="text-lg font-semibold">{{ t('rawMaterialInventory.tableTitle') }}</h2>
                    <p class="text-sm text-gray-500">{{ selectedTypePathText || t('common.all') }}</p>
                  </div>
                  <span class="rounded-full bg-gray-100 px-2.5 py-1 text-xs font-medium text-gray-600">
                    {{ t('rawMaterialInventory.results.count', { count: filteredRows.length }) }}
                  </span>
                </div>
              </div>

              <div v-if="loadError" class="border-b border-red-100 bg-red-50 px-4 py-3 text-sm text-red-700">
                {{ loadError }}
              </div>

              <DataTable
                v-model:expandedRows="expandedSummaryRows"
                :value="filteredRows"
                data-key="materialId"
                paginator
                :rows="20"
                :rows-per-page-options="[20, 50, 100]"
                removable-sort
                class="inventory-datatable"
              >
                <template #empty>
                  <div class="px-4 py-8 text-center text-sm text-gray-500">
                    {{ loading ? t('common.loading') : t('common.noData') }}
                  </div>
                </template>

                <Column style="width: 3rem">
                  <template #body="{ data }">
                    <div class="flex justify-center">
                      <button
                        v-if="hasExpandableLots(data)"
                        type="button"
                        class="inline-flex h-7 w-7 items-center justify-center rounded border border-gray-300 text-gray-700 transition hover:bg-gray-100"
                        :aria-label="isSummaryRowExpanded(data) ? t('common.collapse') : t('common.expand')"
                        :title="isSummaryRowExpanded(data) ? t('common.collapse') : t('common.expand')"
                        @click.stop="toggleSummaryRow(data)"
                      >
                        <span aria-hidden="true">{{ isSummaryRowExpanded(data) ? '▾' : '▸' }}</span>
                      </button>
                      <button
                        v-else-if="primaryLotRow(data)"
                        type="button"
                        class="inline-flex h-7 w-7 items-center justify-center rounded border border-gray-300 text-gray-700 transition hover:bg-gray-100"
                        :aria-label="t('common.actions')"
                        :title="t('common.actions')"
                        @click.stop="toggleLotActionMenu(primaryLotRowId(data), $event)"
                      >
                        <svg class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                          <path
                            fill-rule="evenodd"
                            clip-rule="evenodd"
                            d="M5.99902 10.245C6.96552 10.245 7.74902 11.0285 7.74902 11.995V12.005C7.74902 12.9715 6.96552 13.755 5.99902 13.755C5.03253 13.755 4.24902 12.9715 4.24902 12.005V11.995C4.24902 11.0285 5.03253 10.245 5.99902 10.245ZM17.999 10.245C18.9655 10.245 19.749 11.0285 19.749 11.995V12.005C19.749 12.9715 18.9655 13.755 17.999 13.755C17.0325 13.755 16.249 12.9715 16.249 12.005V11.995C16.249 11.0285 17.0325 10.245 17.999 10.245ZM13.749 11.995C13.749 11.0285 12.9655 10.245 11.999 10.245C11.0325 10.245 10.249 11.0285 10.249 11.995V12.005C10.249 12.9715 11.0325 13.755 11.999 13.755C12.9655 13.755 13.749 12.9715 13.749 12.005V11.995Z"
                          />
                        </svg>
                      </button>
                    </div>
                  </template>
                </Column>

                <Column field="materialName" :header="t('rawMaterialInventory.table.materialName')" sortable>
                  <template #body="{ data }">
                    <div class="min-w-0 leading-tight">
                      <button
                        type="button"
                        class="text-left text-sm font-medium text-blue-700 hover:underline"
                        @click="openMaterialDetail(data)"
                      >
                        {{ data.materialName }}
                      </button>
                      <div class="mt-0.5 text-[11px] text-gray-400">{{ data.materialCode }}</div>
                    </div>
                  </template>
                </Column>

                <Column field="materialTypeSummary" :header="t('rawMaterialInventory.table.materialType')" sortable>
                  <template #body="{ data }">
                    <div class="flex flex-wrap gap-1">
                      <button
                        v-for="typeEntry in data.materialTypeEntries"
                        :key="`${data.materialId}-${typeEntry.typeId}`"
                        type="button"
                        class="rounded-full border border-gray-300 px-2 py-0.5 text-[11px] leading-4 text-gray-700 transition hover:bg-gray-50"
                        @click="selectType(typeEntry.typeId)"
                      >
                        {{ typeEntry.label }}
                      </button>
                    </div>
                  </template>
                </Column>

                <Column field="qty" :header="t('rawMaterialInventory.table.qty')" sortable>
                  <template #body="{ data }">
                    <div class="text-right">{{ formatQuantity(data.qty) }}</div>
                  </template>
                </Column>

                <Column field="uomSummary" :header="t('rawMaterialInventory.table.uom')" sortable>
                  <template #body="{ data }">
                    <div class="text-xs text-gray-700">{{ data.uomSummary }}</div>
                  </template>
                </Column>

                <Column field="locationSummary" :header="t('rawMaterialInventory.table.location')" sortable>
                  <template #body="{ data }">
                    <div class="min-w-0">
                      <div class="text-xs text-gray-700">{{ data.locationSummary }}</div>
                      <div class="mt-0.5 text-[11px] text-gray-400">{{ data.locationLabels.length }} {{ t('rawMaterialInventory.detailDialog.summary.locations') }}</div>
                    </div>
                  </template>
                </Column>

                <template #expansion="{ data }">
                  <div class="bg-gray-50 px-3 py-3">
                    <div class="mb-2 flex flex-wrap items-center justify-between gap-2">
                      <div class="text-xs font-medium text-gray-700">
                        {{ t('rawMaterialInventory.detailDialog.summary.lots') }}: {{ data.lotRows.length }}
                      </div>
                      <button
                        type="button"
                        class="rounded border border-gray-300 px-2.5 py-1 text-xs text-gray-700 transition hover:bg-white"
                        @click="openMaterialDetail(data)"
                      >
                        {{ t('rawMaterialInventory.actions.viewDetails') }}
                      </button>
                    </div>

                    <div class="overflow-x-auto">
                      <table class="min-w-full divide-y divide-gray-200">
                        <thead class="bg-white">
                          <tr>
                            <th class="px-3 py-2 text-left text-[11px] font-semibold uppercase tracking-wide text-gray-500">
                              {{ t('rawMaterialInventory.detailDialog.historyTable.lotNo') }}
                            </th>
                            <th class="px-3 py-2 text-left text-[11px] font-semibold uppercase tracking-wide text-gray-500">
                              {{ t('rawMaterialInventory.table.location') }}
                            </th>
                            <th class="px-3 py-2 text-right text-[11px] font-semibold uppercase tracking-wide text-gray-500">
                              {{ t('rawMaterialInventory.table.qty') }}
                            </th>
                            <th class="px-3 py-2 text-left text-[11px] font-semibold uppercase tracking-wide text-gray-500">
                              {{ t('rawMaterialInventory.table.uom') }}
                            </th>
                            <th class="px-3 py-2 text-right text-[11px] font-semibold uppercase tracking-wide text-gray-500">
                              {{ t('common.actions') }}
                            </th>
                          </tr>
                        </thead>
                        <tbody class="divide-y divide-gray-200 bg-white">
                          <tr v-for="lotRow in data.lotRows" :key="lotRow.lotId">
                            <td class="px-3 py-2 text-xs text-gray-700">{{ lotRow.lotNo || lotRow.lotId }}</td>
                            <td class="px-3 py-2 text-xs text-gray-700">{{ lotRow.locationLabel }}</td>
                            <td class="px-3 py-2 text-right text-xs text-gray-700">{{ formatQuantity(lotRow.qty) }}</td>
                            <td class="px-3 py-2 text-xs text-gray-700">{{ lotRow.uomLabel }}</td>
                            <td class="px-3 py-2 text-right">
                              <div class="inline-flex" data-action-menu="true">
                                <button
                                  type="button"
                                  class="inline-flex h-7 w-7 items-center justify-center rounded border border-gray-300 text-gray-700 transition hover:bg-gray-100"
                                  :aria-label="t('common.actions')"
                                  @click.stop="toggleLotActionMenu(lotRow.lotId, $event)"
                                >
                                  <svg class="h-3.5 w-3.5" viewBox="0 0 24 24" fill="currentColor" aria-hidden="true">
                                    <path
                                      fill-rule="evenodd"
                                      clip-rule="evenodd"
                                      d="M5.99902 10.245C6.96552 10.245 7.74902 11.0285 7.74902 11.995V12.005C7.74902 12.9715 6.96552 13.755 5.99902 13.755C5.03253 13.755 4.24902 12.9715 4.24902 12.005V11.995C4.24902 11.0285 5.03253 10.245 5.99902 10.245ZM17.999 10.245C18.9655 10.245 19.749 11.0285 19.749 11.995V12.005C19.749 12.9715 18.9655 13.755 17.999 13.755C17.0325 13.755 16.249 12.9715 16.249 12.005V11.995C16.249 11.0285 17.0325 10.245 17.999 10.245ZM13.749 11.995C13.749 11.0285 12.9655 10.245 11.999 10.245C11.0325 10.245 10.249 11.0285 10.249 11.995V12.005C10.249 12.9715 11.0325 13.755 11.999 13.755C12.9655 13.755 13.749 12.9715 13.749 12.005V11.995Z"
                                    />
                                  </svg>
                                </button>
                              </div>
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </template>
              </DataTable>

              <teleport to="body">
                <div
                  v-if="openActionMenuLotRow && actionMenuStyle"
                  class="fixed z-[1200] w-44 rounded-xl border border-gray-200 bg-white p-2 shadow-lg"
                  :style="actionMenuStyle"
                  data-action-menu="true"
                >
                  <button
                    type="button"
                    class="flex w-full rounded-lg px-3 py-1.5 text-left text-sm text-gray-700 transition hover:bg-gray-50"
                    @click="handleLotEdit(openActionMenuLotRow)"
                  >
                    {{ t('common.edit') }}
                  </button>
                  <button
                    type="button"
                    class="flex w-full rounded-lg px-3 py-1.5 text-left text-sm text-gray-700 transition hover:bg-gray-50"
                    @click="handleLotMove(openActionMenuLotRow)"
                  >
                    {{ t('rawMaterialInventory.actions.move') }}
                  </button>
                  <button
                    type="button"
                    class="flex w-full rounded-lg px-3 py-1.5 text-left text-sm text-red-600 transition hover:bg-red-50"
                    @click="handleLotDispose(openActionMenuLotRow)"
                  >
                    {{ t('rawMaterialInventory.actions.dispose') }}
                  </button>
                </div>
              </teleport>
            </section>
          </section>
        </div>
      </div>
    </div>

    <ConfirmActionDialog
      :open="confirmDialog.open"
      :title="confirmDialog.title"
      :message="confirmDialog.message"
      :confirm-label="confirmDialog.confirmLabel"
      :cancel-label="confirmDialog.cancelLabel"
      :tone="confirmDialog.tone"
      @cancel="cancelConfirmation"
      @confirm="acceptConfirmation"
    />

    <Modal v-if="detailDialogOpen" :fullScreenBackdrop="true" @close="closeMaterialDetail">
      <template #body>
        <div class="relative z-[100000] w-full max-w-[96vw] px-4 py-6">
          <section
            class="mx-auto max-h-[88vh] overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-2xl"
            role="dialog"
            aria-modal="true"
            :aria-label="t('rawMaterialInventory.detailDialog.title')"
          >
            <header class="flex flex-col gap-3 border-b border-gray-200 px-5 py-4 md:flex-row md:items-start md:justify-between">
              <div>
                <h2 class="text-lg font-semibold text-gray-900">{{ t('rawMaterialInventory.detailDialog.title') }}</h2>
                <p class="text-sm text-gray-500">{{ t('rawMaterialInventory.detailDialog.subtitle') }}</p>
              </div>
              <button
                type="button"
                class="rounded-lg border border-gray-300 px-3 py-2 text-sm text-gray-700 hover:bg-gray-50"
                @click="closeMaterialDetail"
              >
                {{ t('common.close') }}
              </button>
            </header>

            <div class="space-y-4 overflow-y-auto px-5 py-4">
              <section class="rounded-xl border border-gray-200 bg-gray-50 p-4">
                <div class="grid grid-cols-1 gap-4 lg:grid-cols-[minmax(0,1.6fr)_repeat(3,minmax(0,1fr))]">
                  <div>
                    <div class="text-xs font-semibold uppercase tracking-wide text-gray-500">
                      {{ t('rawMaterialInventory.detailDialog.summary.material') }}
                    </div>
                    <div class="mt-1 text-lg font-semibold text-gray-900">
                      {{ detailMaterialSummary?.materialName || '—' }}
                    </div>
                    <div class="mt-1 font-mono text-xs text-gray-500">
                      {{ detailMaterialSummary?.materialCode || '—' }}
                    </div>
                    <div class="mt-2 flex flex-wrap gap-1.5">
                      <span
                        v-for="typeEntry in detailMaterialSummary?.materialTypeEntries ?? []"
                        :key="`detail-type-${typeEntry.typeId}`"
                        class="rounded-full border border-gray-300 bg-white px-2.5 py-1 text-xs text-gray-700"
                      >
                        {{ typeEntry.label }}
                      </span>
                    </div>
                  </div>

                  <div class="rounded-lg border border-gray-200 bg-white px-3 py-3">
                    <div class="text-xs text-gray-500">{{ t('rawMaterialInventory.detailDialog.summary.totalQty') }}</div>
                    <div class="mt-1 text-lg font-semibold text-gray-900">{{ detailTotalQtyText }}</div>
                  </div>

                  <div class="rounded-lg border border-gray-200 bg-white px-3 py-3">
                    <div class="text-xs text-gray-500">{{ t('rawMaterialInventory.detailDialog.summary.locations') }}</div>
                    <div class="mt-1 text-lg font-semibold text-gray-900">{{ detailLocationRows.length }}</div>
                  </div>

                  <div class="rounded-lg border border-gray-200 bg-white px-3 py-3">
                    <div class="text-xs text-gray-500">{{ t('rawMaterialInventory.detailDialog.summary.lots') }}</div>
                    <div class="mt-1 text-lg font-semibold text-gray-900">{{ detailMaterialSummary?.lotRows.length ?? 0 }}</div>
                  </div>
                </div>
              </section>

              <section class="rounded-xl border border-gray-200 bg-white">
                <header class="border-b border-gray-200 px-4 py-3">
                  <h3 class="text-sm font-semibold text-gray-900">{{ t('rawMaterialInventory.detailDialog.inventoryByLocationTitle') }}</h3>
                  <p class="mt-1 text-xs text-gray-500">{{ t('rawMaterialInventory.detailDialog.inventoryByLocationSubtitle') }}</p>
                </header>

                <div v-if="detailLocationRows.length === 0" class="px-4 py-6 text-sm text-gray-500">
                  {{ t('rawMaterialInventory.detailDialog.inventoryByLocationEmpty') }}
                </div>

                <div v-else class="overflow-x-auto">
                  <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                      <tr>
                        <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                          {{ t('rawMaterialInventory.detailDialog.locationTable.location') }}
                        </th>
                        <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">
                          {{ t('rawMaterialInventory.detailDialog.locationTable.qty') }}
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                          {{ t('rawMaterialInventory.detailDialog.locationTable.uom') }}
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                          {{ t('rawMaterialInventory.detailDialog.locationTable.lots') }}
                        </th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100">
                      <tr v-for="row in detailLocationRows" :key="`${detailMaterialId}::${row.locationId || row.locationLabel}`">
                        <td class="px-4 py-3 text-sm text-gray-700">{{ row.locationLabel }}</td>
                        <td class="px-4 py-3 text-right text-sm text-gray-700">{{ formatQuantity(row.qty) }}</td>
                        <td class="px-4 py-3 text-sm text-gray-700">{{ formatListText(row.uomLabels) }}</td>
                        <td class="px-4 py-3 text-sm text-gray-700">
                          <div>{{ row.lotCount }}</div>
                          <div class="mt-1 text-xs text-gray-400">{{ formatListText(row.lotNos) }}</div>
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </section>

              <section class="rounded-xl border border-gray-200 bg-white">
                <header class="border-b border-gray-200 px-4 py-3">
                  <h3 class="text-sm font-semibold text-gray-900">{{ t('rawMaterialInventory.detailDialog.movementHistoryTitle') }}</h3>
                  <p class="mt-1 text-xs text-gray-500">{{ t('rawMaterialInventory.detailDialog.movementHistorySubtitle') }}</p>
                </header>

                <div v-if="detailHistoryLoading" class="px-4 py-6 text-sm text-gray-500">
                  {{ t('common.loading') }}
                </div>
                <div v-else-if="detailHistoryError" class="px-4 py-6 text-sm text-red-700">
                  {{ detailHistoryError }}
                </div>
                <div v-else-if="detailHistoryRows.length === 0" class="px-4 py-6 text-sm text-gray-500">
                  {{ t('rawMaterialInventory.detailDialog.movementHistoryEmpty') }}
                </div>
                <div v-else class="overflow-x-auto">
                  <table class="min-w-full divide-y divide-gray-200">
                    <thead class="bg-gray-50">
                      <tr>
                        <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                          {{ t('rawMaterialInventory.detailDialog.historyTable.date') }}
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                          {{ t('rawMaterialInventory.detailDialog.historyTable.docNo') }}
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                          {{ t('rawMaterialInventory.detailDialog.historyTable.movementType') }}
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                          {{ t('rawMaterialInventory.detailDialog.historyTable.lotNo') }}
                        </th>
                        <th class="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wide text-gray-500">
                          {{ t('rawMaterialInventory.detailDialog.historyTable.qty') }}
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                          {{ t('rawMaterialInventory.detailDialog.historyTable.source') }}
                        </th>
                        <th class="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wide text-gray-500">
                          {{ t('rawMaterialInventory.detailDialog.historyTable.destination') }}
                        </th>
                      </tr>
                    </thead>
                    <tbody class="divide-y divide-gray-100">
                      <tr v-for="row in detailHistoryRows" :key="`${row.movementId}-${row.lotNo}-${row.qty}`">
                        <td class="px-4 py-3 text-sm text-gray-700">{{ formatDateTime(row.occurredAt) }}</td>
                        <td class="px-4 py-3 text-sm text-gray-700">{{ row.docNo }}</td>
                        <td class="px-4 py-3 text-sm text-gray-700">{{ row.docType }}</td>
                        <td class="px-4 py-3 text-sm text-gray-700">{{ row.lotNo }}</td>
                        <td class="px-4 py-3 text-right text-sm text-gray-700">{{ formatQuantity(row.qty) }} {{ row.uomLabel }}</td>
                        <td class="px-4 py-3 text-sm text-gray-700">{{ row.srcSiteLabel }}</td>
                        <td class="px-4 py-3 text-sm text-gray-700">{{ row.destSiteLabel }}</td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </section>
            </div>
          </section>
        </div>
      </template>
    </Modal>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRouter } from 'vue-router'
import DataTable from 'primevue/datatable'
import Column from 'primevue/column'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'
import ConfirmActionDialog from '@/components/common/ConfirmActionDialog.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import Modal from '@/components/ui/Modal.vue'
import { useConfirmDialog } from '@/composables/useConfirmDialog'
import { supabase } from '@/lib/supabase'

type NameI18n = {
  ja?: string | null
  en?: string | null
} | null

type MaterialTypeRow = {
  type_id: string
  code: string
  name: string | null
  name_i18n?: NameI18n
  parent_type_id: string | null
  sort_order: number | null
}

type MaterialTreeNode = {
  row: MaterialTypeRow
  children: MaterialTreeNode[]
}

type MaterialTreeEntry = {
  node: MaterialTreeNode
  depth: number
}

type MaterialRow = {
  id: string
  material_code: string
  material_name: string
  material_type_id: string | null
  base_uom_id: string | null
  status: string
}

type SiteRow = {
  id: string
  name: string | null
}

type UomRow = {
  id: string
  code: string
  name: string | null
}

type LotRow = {
  id: string
  material_id: string | null
  site_id: string | null
  uom_id: string | null
  lot_no: string | null
  status: string | null
}

type MovementHeaderRow = {
  id: string
  status: string
  src_site_id: string | null
  dest_site_id: string | null
}

type InventoryLotRow = {
  id: string
  lotId: string
  lotNo: string | null
  materialId: string
  materialCode: string
  materialName: string
  materialTypeId: string | null
  materialTypeLabel: string
  qty: number
  uomId: string | null
  uomLabel: string
  locationId: string | null
  locationLabel: string
}

type MaterialTypeEntry = {
  typeId: string
  label: string
}

type MaterialSummaryRow = {
  id: string
  materialId: string
  materialCode: string
  materialName: string
  materialTypeEntries: MaterialTypeEntry[]
  materialTypeSummary: string
  qty: number
  uomLabels: string[]
  uomSummary: string
  locationIds: string[]
  locationLabels: string[]
  locationSummary: string
  lotRows: InventoryLotRow[]
}

type MaterialLocationSummaryRow = {
  locationId: string | null
  locationLabel: string
  qty: number
  uomLabels: string[]
  lotNos: string[]
  lotCount: number
}

type MovementLineHistoryRow = {
  movement_id: string
  qty: number
  uom_id: string | null
  meta: unknown
}

type MovementHistoryHeaderRow = {
  id: string
  doc_no: string | null
  doc_type: string | null
  status: string
  movement_at: string | null
  src_site_id: string | null
  dest_site_id: string | null
}

type MaterialMovementHistoryRow = {
  movementId: string
  docNo: string
  docType: string
  occurredAt: string | null
  lotNo: string
  qty: number
  uomLabel: string
  srcSiteLabel: string
  destSiteLabel: string
}

type ActionMenuPosition = {
  top: string
  left: string
}

function sortTypeRows(rows: MaterialTypeRow[]) {
  return rows.slice().sort((a, b) => {
    const sortDiff = (a.sort_order ?? 0) - (b.sort_order ?? 0)
    if (sortDiff !== 0) return sortDiff
    return a.code.localeCompare(b.code)
  })
}

function uniqueStrings(values: Array<string | null | undefined>) {
  const seen = new Set<string>()
  const result: string[] = []
  values.forEach((value) => {
    const normalized = typeof value === 'string' ? value.trim() : ''
    if (!normalized || seen.has(normalized)) return
    seen.add(normalized)
    result.push(normalized)
  })
  return result
}

function messageText(error: unknown) {
  if (error instanceof Error) return error.message
  if (typeof error === 'object' && error && 'message' in error && typeof (error as { message?: unknown }).message === 'string') {
    return (error as { message: string }).message
  }
  return String(error)
}

const { t, locale } = useI18n()
const router = useRouter()
const mesClient = () => supabase.schema('mes')
const { confirmDialog, requestConfirmation, cancelConfirmation, acceptConfirmation } = useConfirmDialog()

const pageTitle = computed(() => t('rawMaterialInventory.title'))

const tenantId = ref('')
const loading = ref(false)
const loadError = ref('')
const disposingLotId = ref('')
const typeSearchTerm = ref('')
const showTypePanel = ref(true)
const expandedTypeIds = ref<Set<string>>(new Set())
const treeExpansionInitialized = ref(false)
const expandedSummaryRows = ref<Record<string, boolean>>({})
const openActionMenuLotId = ref('')
const actionMenuStyle = ref<ActionMenuPosition | null>(null)

const detailDialogOpen = ref(false)
const detailMaterialId = ref('')
const detailMaterialSnapshot = ref<MaterialSummaryRow | null>(null)
const detailHistoryLoading = ref(false)
const detailHistoryError = ref('')
const detailHistoryRows = ref<MaterialMovementHistoryRow[]>([])

const materialTypes = ref<MaterialTypeRow[]>([])
const materialRows = ref<MaterialRow[]>([])
const siteRows = ref<SiteRow[]>([])
const uomRows = ref<UomRow[]>([])
const lotRows = ref<LotRow[]>([])
const inventoryLotRows = ref<InventoryLotRow[]>([])

const filters = reactive({
  keyword: '',
  materialTypeId: '',
  locationId: '',
})

const materialTypeMap = computed(() => {
  const map = new Map<string, MaterialTypeRow>()
  materialTypes.value.forEach((row) => map.set(row.type_id, row))
  return map
})

const materialMap = computed(() => {
  const map = new Map<string, MaterialRow>()
  materialRows.value.forEach((row) => map.set(row.id, row))
  return map
})

const lotMap = computed(() => {
  const map = new Map<string, LotRow>()
  lotRows.value.forEach((row) => map.set(row.id, row))
  return map
})

const expandableTypeIds = computed(() => {
  const parentIds = new Set<string>()
  for (const row of materialTypes.value) {
    if (row.parent_type_id) parentIds.add(row.parent_type_id)
  }
  return parentIds
})

const siteMap = computed(() => {
  const map = new Map<string, SiteRow>()
  siteRows.value.forEach((row) => map.set(row.id, row))
  return map
})

const uomMap = computed(() => {
  const map = new Map<string, UomRow>()
  uomRows.value.forEach((row) => map.set(row.id, row))
  return map
})

const rawMaterialRoot = computed(() => materialTypes.value.find((row) => row.code === 'RAW_MATERIAL') ?? null)

const rawMaterialTypeIds = computed(() => {
  if (!rawMaterialRoot.value) return new Set<string>()
  const ids = new Set<string>()
  const visit = (typeId: string) => {
    if (ids.has(typeId)) return
    ids.add(typeId)
    materialTypes.value.forEach((row) => {
      if (row.parent_type_id === typeId) visit(row.type_id)
    })
  }
  visit(rawMaterialRoot.value.type_id)
  return ids
})

const materialTypeForest = computed<MaterialTreeNode[]>(() => {
  if (materialTypes.value.length === 0) return []

  const childrenByParent = new Map<string | null, MaterialTypeRow[]>()
  for (const row of materialTypes.value) {
    const key = row.parent_type_id ?? null
    const list = childrenByParent.get(key) ?? []
    list.push(row)
    childrenByParent.set(key, list)
  }

  const buildNode = (row: MaterialTypeRow): MaterialTreeNode => ({
    row,
    children: sortTypeRows(childrenByParent.get(row.type_id) ?? []).map((child) => buildNode(child)),
  })

  if (rawMaterialRoot.value) return [buildNode(rawMaterialRoot.value)]

  const roots = materialTypes.value.filter((row) => !row.parent_type_id || !materialTypeMap.value.has(row.parent_type_id))
  return sortTypeRows(roots).map((row) => buildNode(row))
})

const visibleMaterialTypeForest = computed<MaterialTreeNode[]>(() => {
  const query = typeSearchTerm.value.trim().toLowerCase()
  if (!query) return materialTypeForest.value

  const filterNode = (node: MaterialTreeNode): MaterialTreeNode | null => {
    const label = displayMaterialTypeName(node.row).toLowerCase()
    const selfMatches = label.includes(query) || node.row.code.toLowerCase().includes(query)
    if (selfMatches) return node

    const children = node.children
      .map((child) => filterNode(child))
      .filter((child): child is MaterialTreeNode => Boolean(child))

    if (children.length === 0) return null
    return { row: node.row, children }
  }

  return materialTypeForest.value
    .map((node) => filterNode(node))
    .filter((node): node is MaterialTreeNode => Boolean(node))
})

const materialTypeTreeEntries = computed<MaterialTreeEntry[]>(() => {
  const entries: MaterialTreeEntry[] = []
  const visit = (node: MaterialTreeNode, depth: number) => {
    entries.push({ node, depth })
    if (node.children.length === 0 || isTypeExpanded(node.row.type_id)) {
      node.children.forEach((child) => visit(child, depth + 1))
    }
  }
  visibleMaterialTypeForest.value.forEach((node) => visit(node, 0))
  return entries
})

const selectedType = computed(() => (filters.materialTypeId ? materialTypeMap.value.get(filters.materialTypeId) ?? null : null))

const selectedMaterialTypeIds = computed(() => {
  if (!filters.materialTypeId) return null
  const ids = new Set<string>()
  const visit = (typeId: string) => {
    if (ids.has(typeId)) return
    ids.add(typeId)
    materialTypes.value.forEach((row) => {
      if (row.parent_type_id === typeId) visit(row.type_id)
    })
  }
  visit(filters.materialTypeId)
  return ids
})

const selectedTypePathText = computed(() => materialTypePathText(filters.materialTypeId))

const locationOptions = computed(() => {
  return siteRows.value
    .slice()
    .sort((a, b) => String(a.name ?? '').localeCompare(String(b.name ?? '')))
    .map((row) => ({
      value: row.id,
      label: row.name ?? row.id,
    }))
})

const materialSummaryRows = computed<MaterialSummaryRow[]>(() => {
  const buckets = new Map<string, {
    materialCode: string
    materialName: string
    qty: number
    materialTypeMap: Map<string, string>
    uomLabels: string[]
    locationIds: string[]
    locationLabels: string[]
    lotRows: InventoryLotRow[]
  }>()

  inventoryLotRows.value.forEach((row) => {
    const existing = buckets.get(row.materialId) ?? {
      materialCode: row.materialCode,
      materialName: row.materialName,
      qty: 0,
      materialTypeMap: new Map<string, string>(),
      uomLabels: [] as string[],
      locationIds: [] as string[],
      locationLabels: [] as string[],
      lotRows: [] as InventoryLotRow[],
    }

    existing.qty += row.qty
    if (row.materialTypeId && row.materialTypeLabel) existing.materialTypeMap.set(row.materialTypeId, row.materialTypeLabel)
    existing.uomLabels.push(row.uomLabel)
    if (row.locationId) existing.locationIds.push(row.locationId)
    existing.locationLabels.push(row.locationLabel)
    existing.lotRows.push(row)
    buckets.set(row.materialId, existing)
  })

  return Array.from(buckets.entries())
    .map(([materialId, bucket]) => {
      const materialTypeEntries = Array.from(bucket.materialTypeMap.entries())
        .map(([typeId, label]) => ({ typeId, label }))
        .sort((a, b) => a.label.localeCompare(b.label))
      const uomLabels = uniqueStrings(bucket.uomLabels)
      const locationIds = uniqueStrings(bucket.locationIds)
      const locationLabels = uniqueStrings(bucket.locationLabels)

      return {
        id: materialId,
        materialId,
        materialCode: bucket.materialCode,
        materialName: bucket.materialName,
        materialTypeEntries,
        materialTypeSummary: materialTypeEntries.map((entry) => entry.label).join(', '),
        qty: bucket.qty,
        uomLabels,
        uomSummary: formatListText(uomLabels),
        locationIds,
        locationLabels,
        locationSummary: formatListText(locationLabels),
        lotRows: bucket.lotRows.slice().sort((a, b) => {
          const locationDiff = a.locationLabel.localeCompare(b.locationLabel)
          if (locationDiff !== 0) return locationDiff
          return String(a.lotNo ?? '').localeCompare(String(b.lotNo ?? ''))
        }),
      }
    })
    .sort((a, b) => {
      const nameDiff = a.materialName.localeCompare(b.materialName)
      if (nameDiff !== 0) return nameDiff
      return a.materialCode.localeCompare(b.materialCode)
    })
})

const filteredRows = computed(() => {
  const keyword = filters.keyword.trim().toLowerCase()
  return materialSummaryRows.value.filter((row) => {
    const matchKeyword = keyword === '' || row.materialName.toLowerCase().includes(keyword)
    const matchType = !selectedMaterialTypeIds.value || row.materialTypeEntries.some((entry) => selectedMaterialTypeIds.value?.has(entry.typeId))
    const matchLocation = !filters.locationId || row.locationIds.includes(filters.locationId)
    return matchKeyword && matchType && matchLocation
  })
})

function primaryLotRow(row: MaterialSummaryRow) {
  return row.lotRows[0] ?? null
}

function primaryLotRowId(row: MaterialSummaryRow) {
  return primaryLotRow(row)?.lotId ?? ''
}

function hasExpandableLots(row: MaterialSummaryRow) {
  return row.lotRows.length > 1
}

function isSummaryRowExpanded(row: MaterialSummaryRow) {
  return Boolean(expandedSummaryRows.value[row.materialId])
}

function toggleSummaryRow(row: MaterialSummaryRow) {
  if (!hasExpandableLots(row)) return

  const nextExpandedRows = { ...expandedSummaryRows.value }
  if (nextExpandedRows[row.materialId]) delete nextExpandedRows[row.materialId]
  else nextExpandedRows[row.materialId] = true

  expandedSummaryRows.value = nextExpandedRows
  closeActionMenu()
}

watch(materialSummaryRows, (rows) => {
  const expandableMaterialIds = new Set(
    rows.filter((row) => hasExpandableLots(row)).map((row) => row.materialId),
  )

  const nextExpandedRows = Object.entries(expandedSummaryRows.value).reduce<Record<string, boolean>>((acc, [materialId, isExpanded]) => {
    if (isExpanded && expandableMaterialIds.has(materialId)) acc[materialId] = true
    return acc
  }, {})

  const currentKeys = Object.keys(expandedSummaryRows.value)
  const nextKeys = Object.keys(nextExpandedRows)
  const changed = currentKeys.length !== nextKeys.length || currentKeys.some((key) => nextExpandedRows[key] !== expandedSummaryRows.value[key])
  if (changed) {
    expandedSummaryRows.value = nextExpandedRows
  }
}, { immediate: true })

const detailMaterialSummary = computed(() => {
  if (!detailMaterialId.value) return detailMaterialSnapshot.value
  return materialSummaryRows.value.find((row) => row.materialId === detailMaterialId.value) ?? detailMaterialSnapshot.value
})

const detailLocationRows = computed<MaterialLocationSummaryRow[]>(() => {
  const summaryRow = detailMaterialSummary.value
  if (!summaryRow) return []

  const buckets = new Map<string, {
    locationId: string | null
    locationLabel: string
    qty: number
    uomLabels: string[]
    lotNos: string[]
  }>()

  summaryRow.lotRows.forEach((row) => {
    const key = row.locationId || row.locationLabel
    const existing = buckets.get(key) ?? {
      locationId: row.locationId,
      locationLabel: row.locationLabel,
      qty: 0,
      uomLabels: [] as string[],
      lotNos: [] as string[],
    }
    existing.qty += row.qty
    existing.uomLabels.push(row.uomLabel)
    if (row.lotNo) existing.lotNos.push(row.lotNo)
    buckets.set(key, existing)
  })

  return Array.from(buckets.values())
    .map((row) => ({
      locationId: row.locationId,
      locationLabel: row.locationLabel,
      qty: row.qty,
      uomLabels: uniqueStrings(row.uomLabels),
      lotNos: uniqueStrings(row.lotNos),
      lotCount: uniqueStrings(row.lotNos).length,
    }))
    .sort((a, b) => a.locationLabel.localeCompare(b.locationLabel))
})

const detailTotalQtyText = computed(() => {
  const summaryRow = detailMaterialSummary.value
  if (!summaryRow) return '—'
  return `${formatQuantity(summaryRow.qty)} ${summaryRow.uomSummary}`
})

const openActionMenuLotRow = computed(() => (
  openActionMenuLotId.value
    ? inventoryLotRows.value.find((row) => row.lotId === openActionMenuLotId.value) ?? null
    : null
))

const contentGridClass = computed(() => (
  showTypePanel.value
    ? 'xl:grid-cols-[280px_minmax(0,1fr)]'
    : 'xl:grid-cols-[minmax(0,1fr)]'
))

const typePanelToggleText = computed(() => {
  const title = t('rawMaterialInventory.treeTitle')
  const action = showTypePanel.value ? t('common.collapse') : t('common.expand')
  const isJa = locale.value.toString().toLowerCase().startsWith('ja')
  return isJa ? `${title}を${action}` : `${action} ${title}`
})

function displayMaterialTypeName(row: Pick<MaterialTypeRow, 'name' | 'code' | 'name_i18n'> | null) {
  if (!row) return ''
  const isJa = locale.value.toString().toLowerCase().startsWith('ja')
  const ja = row.name_i18n?.ja?.trim()
  const en = row.name_i18n?.en?.trim()
  if (isJa) return ja || row.name || en || row.code
  return en || row.name || ja || row.code
}

function materialTypePathText(typeId: string | null | undefined) {
  if (!typeId) return ''
  const parts: string[] = []
  const visited = new Set<string>()
  let current = materialTypeMap.value.get(typeId) ?? null
  while (current && !visited.has(current.type_id)) {
    visited.add(current.type_id)
    parts.unshift(displayMaterialTypeName(current))
    current = current.parent_type_id ? materialTypeMap.value.get(current.parent_type_id) ?? null : null
  }
  return parts.join(' / ')
}

function formatQuantity(value: number | null | undefined) {
  if (value == null) return '—'
  return new Intl.NumberFormat(locale.value, { maximumFractionDigits: 2 }).format(value)
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return new Intl.DateTimeFormat(locale.value, {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date)
}

function formatListText(values: string[]) {
  const normalized = uniqueStrings(values)
  return normalized.length > 0 ? normalized.join(', ') : '—'
}

function siteLabel(siteId: string | null | undefined) {
  if (!siteId) return '—'
  return siteMap.value.get(siteId)?.name ?? siteId
}

function uomLabel(uomId: string | null | undefined) {
  if (!uomId) return '—'
  const uom = uomMap.value.get(uomId)
  if (!uom) return '—'
  return uom.name ? `${uom.code} - ${uom.name}` : uom.code
}

function isExpandableType(typeId: string) {
  return expandableTypeIds.value.has(typeId)
}

function isTypeExpanded(typeId: string) {
  if (typeSearchTerm.value.trim()) return true
  return expandedTypeIds.value.has(typeId)
}

function typeToggleLabel(isExpanded: boolean) {
  return isExpanded ? t('common.collapse') : t('common.expand')
}

function expandTypePath(typeId: string | null | undefined) {
  if (!typeId) return

  const next = new Set(expandedTypeIds.value)
  let current = materialTypeMap.value.get(typeId) ?? null

  while (current?.parent_type_id) {
    next.add(current.parent_type_id)
    current = materialTypeMap.value.get(current.parent_type_id) ?? null
  }

  expandedTypeIds.value = next
}

function syncExpandedTypeState() {
  const next = new Set<string>()

  if (!treeExpansionInitialized.value) {
    expandableTypeIds.value.forEach((typeId) => next.add(typeId))
    expandedTypeIds.value = next
    treeExpansionInitialized.value = true
    return
  }

  expandableTypeIds.value.forEach((typeId) => {
    if (expandedTypeIds.value.has(typeId)) next.add(typeId)
  })

  expandedTypeIds.value = next
}

function defaultTypeId() {
  return rawMaterialRoot.value?.type_id ?? materialTypeForest.value[0]?.row.type_id ?? ''
}

function ensureTypeSelection() {
  if (
    filters.materialTypeId
    && materialTypeMap.value.has(filters.materialTypeId)
    && (rawMaterialTypeIds.value.size === 0 || rawMaterialTypeIds.value.has(filters.materialTypeId))
  ) {
    expandTypePath(filters.materialTypeId)
    return
  }

  const nextTypeId = defaultTypeId()
  filters.materialTypeId = nextTypeId
  expandTypePath(nextTypeId)
}

function selectType(typeId: string | null | undefined) {
  const nextTypeId = typeId && materialTypeMap.value.has(typeId) ? typeId : defaultTypeId()
  if (!nextTypeId) {
    filters.materialTypeId = ''
    return
  }
  if (rawMaterialTypeIds.value.size > 0 && !rawMaterialTypeIds.value.has(nextTypeId)) return
  filters.materialTypeId = nextTypeId
  expandTypePath(nextTypeId)
}

function toggleTypeExpanded(typeId: string) {
  if (!isExpandableType(typeId) || typeSearchTerm.value.trim()) return

  const next = new Set(expandedTypeIds.value)
  if (next.has(typeId)) next.delete(typeId)
  else next.add(typeId)
  expandedTypeIds.value = next
}

function toggleTypePanel() {
  showTypePanel.value = !showTypePanel.value
}

function toggleLotActionMenu(lotId: string, event?: MouseEvent) {
  if (openActionMenuLotId.value === lotId) {
    closeActionMenu()
    return
  }

  const trigger = event?.currentTarget
  if (!(trigger instanceof HTMLElement)) {
    openActionMenuLotId.value = lotId
    actionMenuStyle.value = { top: '1rem', left: '1rem' }
    return
  }

  const menuWidth = 176
  const menuHeight = 184
  const menuOffset = 8
  const viewportMargin = 8
  const rect = trigger.getBoundingClientRect()
  const maxLeft = Math.max(viewportMargin, window.innerWidth - menuWidth - viewportMargin)
  const left = Math.min(Math.max(viewportMargin, rect.right - menuWidth), maxLeft)
  const openUpwards = rect.bottom + menuOffset + menuHeight > window.innerHeight - viewportMargin
    && rect.top - menuOffset - menuHeight >= viewportMargin
  const topPx = openUpwards
    ? Math.max(viewportMargin, rect.top - menuOffset - menuHeight)
    : Math.min(rect.bottom + menuOffset, Math.max(viewportMargin, window.innerHeight - menuHeight - viewportMargin))

  actionMenuStyle.value = {
    top: `${topPx}px`,
    left: `${left}px`,
  }
  openActionMenuLotId.value = lotId
}

function closeActionMenu() {
  openActionMenuLotId.value = ''
  actionMenuStyle.value = null
}

function handleDocumentPointerdown(event: PointerEvent) {
  if (!(event.target instanceof HTMLElement)) return
  if (event.target.closest('[data-action-menu="true"]')) return
  closeActionMenu()
}

function handleViewportChange() {
  if (openActionMenuLotId.value) closeActionMenu()
}

function readLotIdFromMeta(value: unknown) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null
  const lotId = (value as { lot_id?: unknown }).lot_id
  if (typeof lotId !== 'string') return null
  const trimmed = lotId.trim()
  return trimmed.length > 0 ? trimmed : null
}

function generateDocNo(prefix: string) {
  const now = new Date()
  const datePart = now.toISOString().slice(0, 10).replace(/-/g, '')
  return `${prefix}-${datePart}-${Math.random().toString(36).slice(2, 6).toUpperCase()}`
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const value = data.user?.app_metadata?.tenant_id as string | undefined
  if (!value) throw new Error('Tenant not resolved')
  tenantId.value = value
  return value
}

async function calculateLotQty(lotIdValue: string, siteIdValue: string) {
  const linesResult = await supabase
    .from('inv_movement_lines')
    .select('movement_id, qty, meta')
    .contains('meta', { lot_id: lotIdValue })

  if (linesResult.error) throw linesResult.error

  const lines = ((linesResult.data ?? []) as Array<{ movement_id: string, qty: number, meta: unknown }>).map((row) => ({
    movement_id: String(row.movement_id),
    qty: Number(row.qty ?? 0),
    meta: row.meta,
  }))
  const movementIds = Array.from(new Set(lines.map((row) => row.movement_id)))
  if (movementIds.length === 0) return 0

  const movementResult = await supabase
    .from('inv_movements')
    .select('id, status, src_site_id, dest_site_id')
    .in('id', movementIds)
    .eq('status', 'posted')

  if (movementResult.error) throw movementResult.error

  const movementMap = new Map<string, MovementHeaderRow>()
  ;((movementResult.data ?? []) as MovementHeaderRow[]).forEach((row) => {
    movementMap.set(String(row.id), {
      id: String(row.id),
      status: String(row.status),
      src_site_id: typeof row.src_site_id === 'string' ? row.src_site_id : null,
      dest_site_id: typeof row.dest_site_id === 'string' ? row.dest_site_id : null,
    })
  })

  let total = 0
  lines.forEach((line) => {
    if (readLotIdFromMeta(line.meta) !== lotIdValue) return
    const movement = movementMap.get(line.movement_id)
    if (!movement) return
    if (movement.dest_site_id === siteIdValue) total += line.qty
    if (movement.src_site_id === siteIdValue) total -= line.qty
  })
  return total
}

async function refreshProjection(tenant: string, lotIdValue: string, siteIdValue: string, uomIdValue: string) {
  const qty = await calculateLotQty(lotIdValue, siteIdValue)
  const existingResult = await supabase
    .from('inv_inventory')
    .select('id')
    .eq('tenant_id', tenant)
    .eq('lot_id', lotIdValue)
    .eq('site_id', siteIdValue)
    .maybeSingle()

  if (existingResult.error) throw existingResult.error

  if (qty > 0) {
    if (existingResult.data?.id) {
      const { error } = await supabase
        .from('inv_inventory')
        .update({ qty, uom_id: uomIdValue })
        .eq('id', existingResult.data.id)
      if (error) throw error
    } else {
      const { error } = await supabase
        .from('inv_inventory')
        .insert({
          tenant_id: tenant,
          site_id: siteIdValue,
          lot_id: lotIdValue,
          qty,
          uom_id: uomIdValue,
        })
      if (error) throw error
    }
  } else if (existingResult.data?.id) {
    const { error } = await supabase.from('inv_inventory').delete().eq('id', existingResult.data.id)
    if (error) throw error
  }
}

async function loadMaterialMovementHistory(materialIdValue: string) {
  const linesResult = await supabase
    .from('inv_movement_lines')
    .select('movement_id, qty, uom_id, meta')
    .eq('material_id', materialIdValue)

  if (linesResult.error) throw linesResult.error

  const lines = ((linesResult.data ?? []) as Array<{ movement_id: unknown, qty: unknown, uom_id: unknown, meta: unknown }>)
    .map((row) => ({
      movement_id: String(row.movement_id),
      qty: Number(row.qty ?? 0),
      uom_id: typeof row.uom_id === 'string' ? row.uom_id : null,
      meta: row.meta,
    } satisfies MovementLineHistoryRow))

  const movementIds = Array.from(new Set(lines.map((row) => row.movement_id)))
  if (movementIds.length === 0) return [] as MaterialMovementHistoryRow[]

  const movementResult = await supabase
    .from('inv_movements')
    .select('id, doc_no, doc_type, status, movement_at, src_site_id, dest_site_id')
    .in('id', movementIds)
    .order('movement_at', { ascending: false })

  if (movementResult.error) throw movementResult.error

  const movementMap = new Map<string, MovementHistoryHeaderRow>()
  ;((movementResult.data ?? []) as Array<Record<string, unknown>>).forEach((row) => {
    movementMap.set(String(row.id), {
      id: String(row.id),
      doc_no: typeof row.doc_no === 'string' ? row.doc_no : null,
      doc_type: typeof row.doc_type === 'string' ? row.doc_type : null,
      status: typeof row.status === 'string' ? row.status : '',
      movement_at: typeof row.movement_at === 'string' ? row.movement_at : null,
      src_site_id: typeof row.src_site_id === 'string' ? row.src_site_id : null,
      dest_site_id: typeof row.dest_site_id === 'string' ? row.dest_site_id : null,
    })
  })

  return lines
    .map((line) => {
      const movement = movementMap.get(line.movement_id)
      if (!movement || movement.status !== 'posted') return null
      const lotId = readLotIdFromMeta(line.meta)
      const lotNo = lotId ? (lotMap.value.get(lotId)?.lot_no ?? lotId) : '—'
      return {
        movementId: movement.id,
        docNo: movement.doc_no || movement.id,
        docType: movement.doc_type || '—',
        occurredAt: movement.movement_at,
        lotNo,
        qty: line.qty,
        uomLabel: uomLabel(line.uom_id),
        srcSiteLabel: siteLabel(movement.src_site_id),
        destSiteLabel: siteLabel(movement.dest_site_id),
      } satisfies MaterialMovementHistoryRow
    })
    .filter((row): row is MaterialMovementHistoryRow => Boolean(row))
    .sort((a, b) => String(b.occurredAt ?? '').localeCompare(String(a.occurredAt ?? '')))
}

async function loadInventory() {
  try {
    loading.value = true
    loadError.value = ''
    await ensureTenant()

    const [typeResult, materialResult, siteResult, uomResult, lotResult] = await Promise.all([
      supabase
        .from('type_def')
        .select('type_id, code, name, name_i18n, parent_type_id, sort_order')
        .eq('domain', 'material_type')
        .eq('is_active', true)
        .order('sort_order', { ascending: true })
        .order('code', { ascending: true }),
      mesClient()
        .from('mst_material')
        .select('id, material_code, material_name, material_type_id, base_uom_id, status')
        .order('material_code', { ascending: true }),
      supabase
        .from('mst_sites')
        .select('id, name')
        .order('name', { ascending: true }),
      supabase
        .from('mst_uom')
        .select('id, code, name')
        .order('code', { ascending: true }),
      supabase
        .from('lot')
        .select('id, material_id, site_id, uom_id, lot_no, status')
        .in('status', ['active', 'consumed']),
    ])

    if (typeResult.error) throw typeResult.error
    if (materialResult.error) throw materialResult.error
    if (siteResult.error) throw siteResult.error
    if (uomResult.error) throw uomResult.error
    if (lotResult.error) throw lotResult.error

    materialTypes.value = (typeResult.data ?? []) as MaterialTypeRow[]
    materialRows.value = (materialResult.data ?? []).map((row) => ({
      id: String(row.id),
      material_code: String(row.material_code ?? ''),
      material_name: String(row.material_name ?? ''),
      material_type_id: typeof row.material_type_id === 'string' ? row.material_type_id : null,
      base_uom_id: typeof row.base_uom_id === 'string' ? row.base_uom_id : null,
      status: String(row.status ?? ''),
    }))
    siteRows.value = (siteResult.data ?? []).map((row) => ({
      id: String(row.id),
      name: typeof row.name === 'string' ? row.name : null,
    }))
    uomRows.value = (uomResult.data ?? []) as UomRow[]

    syncExpandedTypeState()
    ensureTypeSelection()

    const rawMaterialIds = new Set(
      materialRows.value
        .filter((row) => row.material_type_id && rawMaterialTypeIds.value.has(row.material_type_id))
        .map((row) => row.id),
    )

    lotRows.value = ((lotResult.data ?? []) as LotRow[])
      .map((row) => ({
        id: String(row.id),
        material_id: typeof row.material_id === 'string' ? row.material_id : null,
        site_id: typeof row.site_id === 'string' ? row.site_id : null,
        uom_id: typeof row.uom_id === 'string' ? row.uom_id : null,
        lot_no: typeof row.lot_no === 'string' ? row.lot_no : null,
        status: typeof row.status === 'string' ? row.status : null,
      }))
      .filter((row) => row.material_id && rawMaterialIds.has(row.material_id))

    const activeLots = lotRows.value.filter((row) => row.material_id && row.site_id)
    if (activeLots.length === 0) {
      inventoryLotRows.value = []
      return
    }

    const movementLinesResult = await supabase
      .from('inv_movement_lines')
      .select('movement_id, qty, meta')
      .in('material_id', Array.from(rawMaterialIds))

    if (movementLinesResult.error) throw movementLinesResult.error

    const movementLines = ((movementLinesResult.data ?? []) as Array<{ movement_id: string, qty: number, meta: unknown }>)
      .map((row) => ({
        movement_id: String(row.movement_id),
        qty: Number(row.qty ?? 0),
        meta: row.meta,
      }))
      .filter((row) => row.qty > 0)

    const movementIds = Array.from(new Set(movementLines.map((row) => row.movement_id)))
    const movementMap = new Map<string, MovementHeaderRow>()
    if (movementIds.length > 0) {
      const movementResult = await supabase
        .from('inv_movements')
        .select('id, status, src_site_id, dest_site_id')
        .in('id', movementIds)
        .eq('status', 'posted')
      if (movementResult.error) throw movementResult.error
      ;((movementResult.data ?? []) as MovementHeaderRow[]).forEach((row) => {
        movementMap.set(String(row.id), {
          id: String(row.id),
          status: String(row.status),
          src_site_id: typeof row.src_site_id === 'string' ? row.src_site_id : null,
          dest_site_id: typeof row.dest_site_id === 'string' ? row.dest_site_id : null,
        })
      })
    }

    const balanceMap = new Map<string, number>()
    movementLines.forEach((line) => {
      const lotId = readLotIdFromMeta(line.meta)
      if (!lotId) return
      const movement = movementMap.get(line.movement_id)
      if (!movement) return
      if (movement.dest_site_id) {
        const key = `${lotId}::${movement.dest_site_id}`
        balanceMap.set(key, (balanceMap.get(key) ?? 0) + line.qty)
      }
      if (movement.src_site_id) {
        const key = `${lotId}::${movement.src_site_id}`
        balanceMap.set(key, (balanceMap.get(key) ?? 0) - line.qty)
      }
    })

    const nextRows: InventoryLotRow[] = []
    activeLots.forEach((lot) => {
      const material = lot.material_id ? materialMap.value.get(lot.material_id) ?? null : null
      if (!material || !lot.site_id) return
      const qty = balanceMap.get(`${lot.id}::${lot.site_id}`) ?? 0
      if (qty <= 0) return
      const typeLabel = material.material_type_id ? materialTypePathText(material.material_type_id) : '—'
      const siteLabelValue = siteMap.value.get(lot.site_id)?.name ?? lot.site_id
      const uomId = lot.uom_id ?? material.base_uom_id
      nextRows.push({
        id: lot.id,
        lotId: lot.id,
        lotNo: lot.lot_no ?? null,
        materialId: material.id,
        materialCode: material.material_code,
        materialName: material.material_name || material.material_code,
        materialTypeId: material.material_type_id,
        materialTypeLabel: typeLabel,
        qty,
        uomId,
        uomLabel: uomLabel(uomId),
        locationId: lot.site_id,
        locationLabel: siteLabelValue,
      })
    })

    inventoryLotRows.value = nextRows
  } catch (error) {
    loadError.value = messageText(error)
    toast.error(loadError.value)
    inventoryLotRows.value = []
  } finally {
    loading.value = false
  }
}

function openCreate() {
  void router.push({
    name: 'RawMaterialInventoryEdit',
    query: filters.materialTypeId ? { materialTypeId: filters.materialTypeId } : undefined,
  })
}

function openEdit(row: InventoryLotRow) {
  void router.push({ name: 'RawMaterialInventoryEdit', params: { lotId: row.lotId } })
}

function openMove(row: InventoryLotRow) {
  void router.push({ name: 'RawMaterialInventoryEdit', params: { lotId: row.lotId }, query: { mode: 'move' } })
}

async function disposeRow(row: InventoryLotRow) {
  if (!row.locationId) {
    toast.error(t('rawMaterialInventory.errors.locationRequired'))
    return
  }
  if (!row.uomId) {
    toast.error(t('rawMaterialInventory.errors.uomRequired'))
    return
  }

  const confirmed = await requestConfirmation({
    title: t('rawMaterialInventory.dispose.title'),
    message: t('rawMaterialInventory.dispose.confirm', {
      material: row.materialName,
      lotNo: row.lotNo || row.lotId,
      qty: formatQuantity(row.qty),
      location: row.locationLabel,
    }),
    confirmLabel: t('rawMaterialInventory.actions.dispose'),
    cancelLabel: t('common.cancel'),
    tone: 'danger',
  })

  if (!confirmed) return

  try {
    disposingLotId.value = row.lotId
    const tenant = await ensureTenant()

    const movementResult = await supabase
      .from('inv_movements')
      .insert({
        tenant_id: tenant,
        doc_no: generateDocNo('RMWST'),
        doc_type: 'waste',
        status: 'posted',
        movement_at: new Date().toISOString(),
        src_site_id: row.locationId,
        dest_site_id: null,
        reason: 'raw_material_inventory_dispose',
        meta: {
          source: 'raw_material_inventory_list',
          lot_id: row.lotId,
        },
      })
      .select('id')
      .single()

    if (movementResult.error || !movementResult.data) {
      throw movementResult.error || new Error('Movement insert failed')
    }

    const lineResult = await supabase.from('inv_movement_lines').insert({
      tenant_id: tenant,
      movement_id: movementResult.data.id,
      line_no: 1,
      material_id: row.materialId,
      qty: row.qty,
      uom_id: row.uomId,
      meta: {
        lot_id: row.lotId,
      },
    })
    if (lineResult.error) throw lineResult.error

    const lotResult = await supabase
      .from('lot')
      .update({
        qty: 0,
        status: 'consumed',
        uom_id: row.uomId,
      })
      .eq('id', row.lotId)
    if (lotResult.error) throw lotResult.error

    await refreshProjection(tenant, row.lotId, row.locationId, row.uomId)
    toast.success(t('rawMaterialInventory.dispose.done'))
    await loadInventory()
  } catch (error) {
    toast.error(messageText(error))
  } finally {
    disposingLotId.value = ''
  }
}

async function openMaterialDetail(row: MaterialSummaryRow) {
  detailMaterialId.value = row.materialId
  detailMaterialSnapshot.value = row
  detailDialogOpen.value = true
  detailHistoryLoading.value = true
  detailHistoryError.value = ''
  detailHistoryRows.value = []
  closeActionMenu()

  try {
    detailHistoryRows.value = await loadMaterialMovementHistory(row.materialId)
  } catch (error) {
    detailHistoryError.value = messageText(error)
  } finally {
    detailHistoryLoading.value = false
  }
}

function closeMaterialDetail() {
  detailDialogOpen.value = false
  detailHistoryLoading.value = false
  detailHistoryError.value = ''
  detailHistoryRows.value = []
  detailMaterialId.value = ''
  detailMaterialSnapshot.value = null
}

function handleLotEdit(row: InventoryLotRow) {
  closeActionMenu()
  openEdit(row)
}

function handleLotMove(row: InventoryLotRow) {
  closeActionMenu()
  openMove(row)
}

function handleLotDispose(row: InventoryLotRow) {
  closeActionMenu()
  void disposeRow(row)
}

onMounted(() => {
  document.addEventListener('pointerdown', handleDocumentPointerdown)
  window.addEventListener('resize', handleViewportChange)
  window.addEventListener('scroll', handleViewportChange, true)
  void loadInventory()
})

onBeforeUnmount(() => {
  document.removeEventListener('pointerdown', handleDocumentPointerdown)
  window.removeEventListener('resize', handleViewportChange)
  window.removeEventListener('scroll', handleViewportChange, true)
})
</script>

<style scoped>
.inventory-datatable :deep(.p-datatable-table-container) {
  overflow-x: auto;
}

.inventory-datatable :deep(.p-datatable-table) {
  min-width: 100%;
}

.inventory-datatable :deep(.p-datatable-thead > tr > th) {
  border-bottom: 1px solid #e5e7eb;
  background: #f9fafb;
  padding: 0.5rem 0.75rem;
  text-align: left;
  font-size: 0.6875rem;
  font-weight: 600;
  line-height: 0.875rem;
  letter-spacing: 0.05em;
  color: #6b7280;
  text-transform: uppercase;
}

.inventory-datatable :deep(.p-column-header-content) {
  gap: 0.25rem;
}

.inventory-datatable :deep(.p-datatable-tbody > tr) {
  transition: background-color 150ms ease;
}

.inventory-datatable :deep(.p-datatable-tbody > tr:hover) {
  background: #f9fafb;
}

.inventory-datatable :deep(.p-datatable-tbody > tr > td) {
  border-bottom: 1px solid #f3f4f6;
  padding: 0.5rem 0.75rem;
  vertical-align: top;
  font-size: 0.8125rem;
  line-height: 1.125rem;
  color: #4b5563;
}

.inventory-datatable :deep(.p-datatable-tbody > tr.p-datatable-row-expansion > td) {
  padding: 0;
  background: #f9fafb;
}

.inventory-datatable :deep(.p-datatable-empty-message) {
  padding: 2rem 1rem;
}

.inventory-datatable :deep(.p-sortable-column:not(.p-highlight):hover) {
  background: #f3f4f6;
  color: #4b5563;
}

.inventory-datatable :deep(.p-sortable-column.p-highlight) {
  background: #f9fafb;
  color: #1f2937;
}

.inventory-datatable :deep(.p-sortable-column-icon) {
  color: #9ca3af;
}

.inventory-datatable :deep(.p-paginator) {
  border-top: 1px solid #e5e7eb;
  background: #ffffff;
  padding: 0.5rem 0.75rem;
}

.inventory-datatable :deep(.p-paginator-current) {
  color: #111827;
}

.inventory-datatable :deep(.p-paginator .p-paginator-page),
.inventory-datatable :deep(.p-paginator .p-paginator-prev),
.inventory-datatable :deep(.p-paginator .p-paginator-next),
.inventory-datatable :deep(.p-paginator .p-paginator-first),
.inventory-datatable :deep(.p-paginator .p-paginator-last) {
  min-width: 1.875rem;
  height: 1.875rem;
  border: 1px solid transparent;
  border-radius: 0.375rem;
  color: #4b5563;
}

.inventory-datatable :deep(.p-paginator .p-paginator-page:hover),
.inventory-datatable :deep(.p-paginator .p-paginator-prev:hover),
.inventory-datatable :deep(.p-paginator .p-paginator-next:hover),
.inventory-datatable :deep(.p-paginator .p-paginator-first:hover),
.inventory-datatable :deep(.p-paginator .p-paginator-last:hover) {
  background: #f3f4f6;
}

.inventory-datatable :deep(.p-paginator .p-paginator-page.p-highlight) {
  background: #2563eb;
  color: #ffffff;
}

.inventory-datatable :deep(.p-paginator-rpp-dropdown),
.inventory-datatable :deep(.p-paginator-rpp-dropdown .p-select-label),
.inventory-datatable :deep(.p-paginator-rpp-dropdown .p-select-dropdown) {
  background: #ffffff;
  color: #111827;
}

.inventory-datatable :deep(.p-paginator-rpp-dropdown) {
  border: 1px solid #d1d5db;
  border-radius: 0.375rem;
}
</style>
