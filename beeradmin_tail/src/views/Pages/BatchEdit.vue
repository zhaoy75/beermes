<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div v-if="loadingBatch" class="p-6 text-sm text-gray-500">{{ t('common.loading') }}</div>
    <div v-else-if="!batch" class="p-6 text-sm text-red-600">{{ t('batch.edit.notFound') }}</div>
    <div v-else class="space-y-6">
      <!-- Batch Information -->
      <section class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5">
        <header class="flex items-center justify-between mb-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.edit.infoTitle') }}</h2>
            <p class="text-xs text-gray-500">{{ t('batch.edit.infoSubtitle') }}</p>
          </div>
          <button class="px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="savingBatch" @click="saveBatch">{{ savingBatch ? t('common.saving') : t('common.save') }}</button>
        </header>
        <form class="grid grid-cols-1 lg:grid-cols-3 gap-4" @submit.prevent>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchCode">{{ t('batch.edit.batchCode') }}</label>
            <input id="batchCode" v-model.trim="batchForm.batch_code" type="text" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchStatus">{{ t('batch.edit.status') }}</label>
            <select id="batchStatus" v-model="batchForm.status" class="w-full h-[40px] border rounded px-3 bg-white" :disabled="batchStatusLoading">
              <option value="">{{ t('common.select') }}</option>
              <option v-for="option in batchStatusOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchLabel">{{ t('batch.edit.label') }}</label>
            <input id="batchLabel" v-model.trim="batchForm.batch_label" type="text" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchScaleFactor">{{ t('batch.edit.scaleFactor') }}</label>
            <input id="batchScaleFactor" v-model.number="batchForm.scale_factor" type="number" min="0" step="0.0001" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchPlannedStart">{{ t('batch.edit.plannedStart') }}</label>
            <input id="batchPlannedStart" v-model="batchForm.planned_start" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchPlannedEnd">{{ t('batch.edit.plannedEnd') }}</label>
            <input id="batchPlannedEnd" v-model="batchForm.planned_end" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchActualStart">{{ t('batch.edit.actualStart') }}</label>
            <input id="batchActualStart" v-model="batchForm.actual_start" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchActualEnd">{{ t('batch.edit.actualEnd') }}</label>
            <input id="batchActualEnd" v-model="batchForm.actual_end" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div class="lg:col-span-3">
            <label class="block text-sm text-gray-600 mb-1" for="batchNotes">{{ t('batch.edit.notes') }}</label>
            <textarea id="batchNotes" v-model.trim="batchForm.notes" rows="3" class="w-full border rounded px-3 py-2"></textarea>
          </div>
        </form>
      </section>

      <section class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5">
        <header class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <button class="px-2 py-1 text-xs rounded border border-gray-300 hover:bg-gray-100" type="button" @click="toggleSection('kpi')">
              {{ collapseLabel(sectionCollapsed.kpi) }}
            </button>
            <div>
              <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.edit.kpiTitle') }}</h2>
              <p class="text-xs text-gray-500">{{ t('batch.edit.kpiSubtitle') }}</p>
            </div>
          </div>
          <button class="px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="savingBatch" @click="saveBatch">
            {{ savingBatch ? t('common.saving') : t('common.save') }}
          </button>
        </header>
        <div v-show="!sectionCollapsed.kpi" class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full text-sm divide-y divide-gray-200">
            <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
              <tr>
                <th class="px-2 py-1 text-left w-[160px]">{{ t('batch.edit.kpiName') }}</th>
                <th class="px-2 py-1 text-left w-[90px]">{{ t('batch.edit.kpiUom') }}</th>
                <th class="px-3 py-1 text-right">{{ t('batch.edit.kpiPlanned') }}</th>
                <th class="px-3 py-1 text-right">{{ t('batch.edit.kpiActual') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="(row, index) in batchForm.kpi_rows" :key="`${row.id}-${index}`" class="hover:bg-gray-50">
                <td class="px-2 py-1 text-sm text-gray-700 w-[160px]">
                  <span class="block truncate">{{ row.name }}</span>
                </td>
                <td class="px-2 py-1 text-sm text-gray-700 w-[90px]">
                  <span class="block truncate">{{ row.uom }}</span>
                </td>
                <td class="px-3 py-1 text-right">
                  <input
                    v-model="row.planed"
                    :type="isNumericKpi(row) ? 'number' : 'text'"
                    :min="isNumericKpi(row) ? '0' : undefined"
                    :step="isNumericKpi(row) ? '0.001' : undefined"
                    class="w-full h-[30px] border rounded px-2 text-right"
                  />
                </td>
                <td class="px-3 py-1 text-right">
                  <input
                    v-model="row.actual"
                    :type="isNumericKpi(row) ? 'number' : 'text'"
                    :min="isNumericKpi(row) ? '0' : undefined"
                    :step="isNumericKpi(row) ? '0.001' : undefined"
                    class="w-full h-[30px] border rounded px-2 text-right"
                  />
                </td>
              </tr>
              <tr v-if="batchForm.kpi_rows.length === 0">
                <td class="px-3 py-4 text-center text-gray-500" colspan="5">{{ t('common.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5">
        <header class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <button class="px-2 py-1 text-xs rounded border border-gray-300 hover:bg-gray-100" type="button" @click="toggleSection('materials')">
              {{ collapseLabel(sectionCollapsed.materials) }}
            </button>
            <div>
              <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.edit.materialConsumptionTitle') }}</h2>
              <p class="text-xs text-gray-500">{{ t('batch.edit.materialConsumptionSubtitle') }}</p>
            </div>
          </div>
          <button class="px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="savingBatch" @click="saveBatch">
            {{ savingBatch ? t('common.saving') : t('common.save') }}
          </button>
        </header>
        <div v-show="!sectionCollapsed.materials" class="space-y-4">
          <div v-if="materialConsumptionGroups.length === 0" class="text-sm text-gray-500">{{ t('common.noData') }}</div>
          <div class="overflow-x-auto border border-gray-200 rounded-lg">
            <table class="min-w-full text-sm divide-y divide-gray-200">
              <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
                <tr>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.materialConsumptionClass') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.materialConsumptionMaterialList') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('batch.edit.materialConsumptionPlanned') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('batch.edit.materialConsumptionActual') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('batch.edit.materialConsumptionVariance') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.materialConsumptionDetails') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.materialConsumptionDetailsButton') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="group in materialConsumptionGroups" :key="group.key" class="hover:bg-gray-50">
                  <td class="px-3 py-2 text-sm text-gray-700">{{ group.label }}</td>
                  <td class="px-3 py-2 text-sm text-gray-700">
                    <div class="max-w-[280px] text-xs text-gray-600 line-clamp-2">
                      {{ materialListText(group.row.materials) }}
                    </div>
                  </td>
                  <td class="px-3 py-2 text-right">
                    <input v-model="group.row.planned_qty" type="number" min="0" step="0.001" class="w-24 h-[36px] border rounded px-2 text-right" />
                  </td>
                  <td class="px-3 py-2 text-right">
                    <input v-model="group.row.actual_qty" type="number" min="0" step="0.001" class="w-24 h-[36px] border rounded px-2 text-right" />
                  </td>
                  <td class="px-3 py-2 text-right">
                    <input v-model="group.row.variance" type="number" step="0.001" class="w-24 h-[36px] border rounded px-2 text-right" :placeholder="variancePlaceholder(group.row)" />
                  </td>
                  <td class="px-3 py-2">
                    <input v-model.trim="group.row.details_notes" type="text" class="w-full h-[36px] border rounded px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <div class="flex items-center gap-2">
                      <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="openMaterialDetail(group.label, group.key)">
                        {{ t('batch.edit.materialConsumptionDetailsButton') }}
                      </button>
                      <span class="text-xs text-gray-500">{{ group.row.materials.length }} {{ t('batch.edit.materialConsumptionDetailsCount') }}</span>
                    </div>
                  </td>
                </tr>
                <tr v-if="materialConsumptionGroups.length === 0">
                  <td class="px-3 py-4 text-center text-gray-500" colspan="7">{{ t('common.noData') }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <section class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5">
        <header class="flex items-center justify-between mb-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.edit.outputActualTitle') }}</h2>
            <p class="text-xs text-gray-500">{{ t('batch.edit.outputActualSubtitle') }}</p>
          </div>
          <div class="flex items-center gap-2">
            <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="addOutputRow">{{ t('common.add') }}</button>
            <button class="px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="savingBatch" @click="saveBatch">
              {{ savingBatch ? t('common.saving') : t('common.save') }}
            </button>
          </div>
        </header>
        <div class="space-y-4">
          <div v-if="batchForm.output_rows.length === 0" class="text-sm text-gray-500">{{ t('common.noData') }}</div>
          <div v-for="(row, index) in batchForm.output_rows" :key="`output-${index}`" class="border border-gray-200 rounded-lg p-3 space-y-3">
            <div class="grid grid-cols-1 md:grid-cols-5 gap-3">
              <div>
                <label class="block text-xs text-gray-500 mb-1">{{ t('batch.edit.outputActualMaterialId') }}</label>
                <input v-model.trim="row.material_id" type="text" class="w-full h-[36px] border rounded px-2" />
              </div>
              <div>
                <label class="block text-xs text-gray-500 mb-1">{{ t('batch.edit.outputActualQty') }}</label>
                <input v-model="row.qty" type="number" min="0" step="0.001" class="w-full h-[36px] border rounded px-2 text-right" />
              </div>
              <div>
                <label class="block text-xs text-gray-500 mb-1">{{ t('batch.edit.outputActualUom') }}</label>
                <input v-model.trim="row.uom" type="text" class="w-full h-[36px] border rounded px-2" />
              </div>
              <div>
                <label class="block text-xs text-gray-500 mb-1">{{ t('batch.edit.outputActualType') }}</label>
                <input v-model.trim="row.type" type="text" class="w-full h-[36px] border rounded px-2" />
              </div>
              <div>
                <label class="block text-xs text-gray-500 mb-1">{{ t('batch.edit.outputActualDispositionType') }}</label>
                <select v-model="row.disposition_type" class="w-full h-[36px] border rounded px-2 bg-white">
                  <option value="">{{ t('batch.edit.outputActualDispositionNone') }}</option>
                  <option value="transfer_batch">{{ t('batch.edit.outputActualDispositionTransferBatch') }}</option>
                  <option value="transfer_warehouse">{{ t('batch.edit.outputActualDispositionTransferWarehouse') }}</option>
                  <option value="disposal">{{ t('batch.edit.outputActualDispositionDisposal') }}</option>
                </select>
              </div>
            </div>

            <div v-if="row.disposition_type === 'transfer_batch'" class="grid grid-cols-1 md:grid-cols-4 gap-3">
              <div class="md:col-span-2">
                <label class="block text-xs text-gray-500 mb-1">{{ t('batch.edit.outputActualTargetBatch') }}</label>
                <select v-model="row.transfer_batch_id" class="w-full h-[36px] border rounded px-2 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in batchOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
              </div>
              <div>
                <label class="block text-xs text-gray-500 mb-1">{{ t('batch.edit.outputActualTransferQty') }}</label>
                <input v-model="row.transfer_qty" type="number" min="0" step="0.001" class="w-full h-[36px] border rounded px-2 text-right" />
              </div>
              <div>
                <label class="block text-xs text-gray-500 mb-1">{{ t('batch.edit.outputActualTransferUom') }}</label>
                <input v-model.trim="row.transfer_uom" type="text" class="w-full h-[36px] border rounded px-2" />
              </div>
            </div>

            <div v-if="row.disposition_type === 'transfer_warehouse'" class="grid grid-cols-1 md:grid-cols-4 gap-3">
              <div class="md:col-span-2">
                <label class="block text-xs text-gray-500 mb-1">{{ t('batch.edit.outputActualTargetWarehouse') }}</label>
                <select v-model="row.warehouse_site_id" class="w-full h-[36px] border rounded px-2 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in siteOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
              </div>
              <div>
                <label class="block text-xs text-gray-500 mb-1">{{ t('batch.edit.outputActualTransferQty') }}</label>
                <input v-model="row.warehouse_qty" type="number" min="0" step="0.001" class="w-full h-[36px] border rounded px-2 text-right" />
              </div>
              <div>
                <label class="block text-xs text-gray-500 mb-1">{{ t('batch.edit.outputActualTransferUom') }}</label>
                <input v-model.trim="row.warehouse_uom" type="text" class="w-full h-[36px] border rounded px-2" />
              </div>
            </div>

            <div v-if="row.disposition_type === 'disposal'" class="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div class="md:col-span-2">
                <label class="block text-xs text-gray-500 mb-1">{{ t('batch.edit.outputActualDisposalReason') }}</label>
                <input v-model.trim="row.disposal_reason" type="text" class="w-full h-[36px] border rounded px-2" />
              </div>
            </div>

            <div class="flex justify-end">
              <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="removeOutputRow(index)">{{ t('common.delete') }}</button>
            </div>
          </div>
        </div>
      </section>

      <!-- Ingredients -->
      <section v-if="false" class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5">
        <header class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <button class="px-2 py-1 text-xs rounded border border-gray-300 hover:bg-gray-100" type="button" @click="toggleSection('ingredients')">
              {{ collapseLabel(sectionCollapsed.ingredients) }}
            </button>
            <div>
              <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.ingredients.sectionTitle') }}</h2>
              <p class="text-xs text-gray-500">{{ t('batch.ingredients.sectionSubtitle') }}</p>
            </div>
          </div>
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="ingredientLoading || !batch?.recipe_id" @click="openIngredientAdd">{{ t('common.add') }}</button>
        </header>
        <div v-if="ingredientLoading && !sectionCollapsed.ingredients" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
        <div v-show="!sectionCollapsed.ingredients" v-else class="overflow-x-auto">
          <table class="min-w-full text-sm border border-gray-200 rounded-lg overflow-hidden">
            <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('batch.ingredients.material') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.ingredients.amount') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.ingredients.uom') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.ingredients.stage') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.ingredients.notes') }}</th>
                <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="row in ingredients" :key="row.id" class="hover:bg-gray-50">
                <td class="px-3 py-2">{{ row.material_label }}</td>
                <td class="px-3 py-2 text-right">{{ row.amount ?? '—' }}</td>
                <td class="px-3 py-2">{{ row.uom_code ?? '—' }}</td>
                <td class="px-3 py-2">{{ row.usage_stage ?? '—' }}</td>
                <td class="px-3 py-2">{{ row.notes ?? '—' }}</td>
                <td class="px-3 py-2 space-x-2">
                  <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" type="button" @click="openIngredientEdit(row)">{{ t('common.edit') }}</button>
                  <button class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700" type="button" @click="deleteIngredient(row)">{{ t('common.delete') }}</button>
                </td>
              </tr>
              <tr v-if="!ingredients.length">
                <td class="px-3 py-6 text-center text-gray-500" colspan="6">{{ t('common.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- Packaging -->
      <section class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5">
        <header class="flex flex-col md:flex-row md:items-center md:justify-between gap-3 mb-4">
          <div class="flex items-center gap-3">
            <button class="px-2 py-1 text-xs rounded border border-gray-300 hover:bg-gray-100" type="button" @click="toggleSection('packaging')">
              {{ collapseLabel(sectionCollapsed.packaging) }}
            </button>
            <div>
              <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.packaging.sectionTitle') }}</h2>
              <p class="text-xs text-gray-500">{{ t('batch.packaging.sectionSubtitle') }}</p>
            </div>
          </div>
          <div class="flex items-center gap-2">
            <span v-if="packingNotice" class="text-xs text-green-600">{{ packingNotice }}</span>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="packingDialog.loading || !batch" @click="openPackingDialog">
              {{ t('batch.packaging.openDialog') }}
            </button>
          </div>
        </header>

        <div v-show="!sectionCollapsed.packaging" class="space-y-3">
          <div v-if="packingEvents.length === 0" class="text-sm text-gray-500">{{ t('batch.packaging.noData') }}</div>
          <div v-else class="overflow-x-auto border border-gray-200 rounded-lg">
            <table class="min-w-full text-sm divide-y divide-gray-200">
              <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
                <tr>
                  <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.eventTime') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.type') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.volume') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.movement') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.filling') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.memo') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="event in packingEvents" :key="event.id" class="hover:bg-gray-50">
                  <td class="px-3 py-2 text-gray-600">{{ formatPackingDate(event.event_time) }}</td>
                  <td class="px-3 py-2 font-medium text-gray-800">{{ formatPackingType(event.packing_type) }}</td>
                  <td class="px-3 py-2 text-gray-700">{{ formatPackingVolume(event) }}</td>
                  <td class="px-3 py-2 text-gray-700">{{ formatPackingMovement(event) }}</td>
                  <td class="px-3 py-2 text-gray-700">{{ formatPackingFilling(event) }}</td>
                  <td class="px-3 py-2 text-gray-600">{{ event.memo || '—' }}</td>
                  <td class="px-3 py-2 space-x-2">
                    <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" type="button" @click="openPackingEdit(event)">
                      {{ t('batch.packaging.actions.edit') }}
                    </button>
                    <button class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700" type="button" @click="deletePackingEvent(event)">
                      {{ t('batch.packaging.actions.delete') }}
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </section>

      <!-- Steps -->
      <section class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5">
        <header class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <button class="px-2 py-1 text-xs rounded border border-gray-300 hover:bg-gray-100" type="button" @click="toggleSection('steps')">
              {{ collapseLabel(sectionCollapsed.steps) }}
            </button>
            <div>
              <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.steps.sectionTitle') }}</h2>
              <p class="text-xs text-gray-500">{{ t('batch.steps.sectionSubtitle') }}</p>
            </div>
          </div>
        </header>
        <div v-if="stepsLoading && !sectionCollapsed.steps" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
        <div v-show="!sectionCollapsed.steps" v-else class="overflow-x-auto">
          <table class="min-w-full text-sm border border-gray-200 rounded-lg overflow-hidden">
            <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
              <tr>
                <th class="px-3 py-2 text-left">#</th>
                <th class="px-3 py-2 text-left">{{ t('batch.steps.step') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.steps.status') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.steps.planned') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.steps.actualParams') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.steps.notes') }}</th>
                <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="step in steps" :key="step.id" class="hover:bg-gray-50">
                <td class="px-3 py-2">{{ step.step_no }}</td>
                <td class="px-3 py-2">{{ step.step }}</td>
                <td class="px-3 py-2">
                  <input v-model.trim="step.edit.status" type="text" class="w-full h-[32px] border rounded px-2" />
                </td>
                <td class="px-3 py-2 whitespace-pre-wrap text-xs text-gray-600">{{ step.planned_summary }}</td>
                <td class="px-3 py-2">
                  <textarea v-model.trim="step.edit.actual_params" rows="2" class="w-full border rounded px-2 py-1 text-xs"></textarea>
                </td>
                <td class="px-3 py-2">
                  <textarea v-model.trim="step.edit.notes" rows="2" class="w-full border rounded px-2 py-1 text-xs"></textarea>
                </td>
                <td class="px-3 py-2 space-y-1">
                  <button class="w-full px-2 py-1 text-xs rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="step.saving" @click="saveStep(step)">{{ step.saving ? t('common.saving') : t('common.save') }}</button>
                </td>
              </tr>
              <tr v-if="!steps.length">
                <td class="px-3 py-6 text-center text-gray-500" colspan="7">{{ t('common.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>

    <div v-if="materialDetailDialog.open && materialDetailDialog.row" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-3xl bg-white rounded-xl shadow-lg border border-gray-200">
        <header class="flex items-center justify-between px-4 py-3 border-b">
          <div>
            <h3 class="text-lg font-semibold text-gray-800">{{ t('batch.edit.materialConsumptionDetailsTitle') }}</h3>
            <p class="text-xs text-gray-500">{{ materialDetailDialog.materialLabel }}</p>
          </div>
          <button class="text-sm px-2 py-1 rounded border hover:bg-gray-100" type="button" @click="closeMaterialDetail">{{ t('common.close') }}</button>
        </header>
        <div class="p-4 space-y-4">
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('batch.edit.materialConsumptionDetailsNotes') }}</label>
            <textarea v-model="materialDetailDialog.row.details_notes" rows="3" class="w-full border rounded px-3 py-2 text-sm"></textarea>
          </div>
          <div class="space-y-2">
            <div class="flex items-center justify-between">
              <h4 class="text-sm font-semibold text-gray-700">{{ t('batch.edit.materialConsumptionDetailsRecords') }}</h4>
              <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="addDetailMaterialRow">{{ t('common.add') }}</button>
            </div>
            <div class="overflow-x-auto border border-gray-200 rounded-lg">
              <table class="min-w-full text-sm divide-y divide-gray-200">
                <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
                  <tr>
                    <th class="px-3 py-2 text-left">{{ t('batch.edit.materialConsumptionMaterial') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('batch.edit.materialConsumptionPlanned') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('batch.edit.materialConsumptionActual') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('batch.edit.materialConsumptionVariance') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('batch.edit.materialConsumptionDetailsNotes') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <template v-for="(row, index) in materialDetailDialog.row.materials" :key="`detail-${index}`">
                    <tr class="hover:bg-gray-50">
                      <td class="px-3 py-2">
                        <select v-model="row.material_id" class="w-full h-[34px] border rounded px-2 bg-white">
                          <option value="">{{ t('common.select') }}</option>
                          <option v-for="option in materialOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                        </select>
                      </td>
                      <td class="px-3 py-2 text-right">
                        <input v-model="row.planned_qty" type="number" min="0" step="0.001" class="w-full h-[34px] border rounded px-2 text-right" />
                      </td>
                      <td class="px-3 py-2 text-right">
                        <input v-model="row.actual_qty" type="number" min="0" step="0.001" class="w-full h-[34px] border rounded px-2 text-right" />
                      </td>
                      <td class="px-3 py-2 text-right">
                        <input v-model="row.variance" type="number" step="0.001" class="w-24 h-[34px] border rounded px-2 text-right" :placeholder="variancePlaceholder(row)" />
                      </td>
                      <td class="px-3 py-2">
                        <input v-model.trim="row.details_notes" type="text" class="w-full h-[34px] border rounded px-2" />
                      </td>
                      <td class="px-3 py-2">
                        <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="removeDetailMaterialRow(index)">{{ t('common.delete') }}</button>
                      </td>
                    </tr>
                    <tr>
                      <td class="px-3 py-2 bg-gray-50" colspan="6">
                        <div class="flex items-center justify-between mb-2">
                          <span class="text-xs text-gray-500">{{ t('batch.edit.materialConsumptionDetailsBatch') }}</span>
                          <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="addDetailBatch(row)">
                            {{ t('common.add') }}
                          </button>
                        </div>
                        <div class="overflow-x-auto border border-gray-200 rounded-lg bg-white">
                          <table class="min-w-full text-xs divide-y divide-gray-200">
                            <thead class="bg-gray-50 text-gray-500 uppercase">
                              <tr>
                                <th class="px-2 py-1 text-left">{{ t('batch.edit.materialConsumptionDetailsBatch') }}</th>
                                <th class="px-2 py-1 text-right">{{ t('batch.edit.materialConsumptionDetailsQty') }}</th>
                                <th class="px-2 py-1 text-left">{{ t('batch.edit.materialConsumptionDetailsUom') }}</th>
                                <th class="px-2 py-1 text-left">{{ t('common.actions') }}</th>
                              </tr>
                            </thead>
                            <tbody class="divide-y divide-gray-100">
                              <tr v-for="(b, bIndex) in row.batches" :key="`batch-${index}-${bIndex}`">
                                <td class="px-2 py-1">
                                  <input v-model.trim="b.batch_id" type="text" class="w-full h-[30px] border rounded px-2" />
                                </td>
                                <td class="px-2 py-1 text-right">
                                  <input v-model="b.qty" type="number" min="0" step="0.001" class="w-full h-[30px] border rounded px-2 text-right" />
                                </td>
                                <td class="px-2 py-1">
                                  <input v-model.trim="b.uom" type="text" class="w-full h-[30px] border rounded px-2" />
                                </td>
                                <td class="px-2 py-1">
                                  <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="removeDetailBatch(row, bIndex)">{{ t('common.delete') }}</button>
                                </td>
                              </tr>
                              <tr v-if="row.batches.length === 0">
                                <td class="px-2 py-3 text-center text-gray-500" colspan="4">{{ t('common.noData') }}</td>
                              </tr>
                            </tbody>
                          </table>
                        </div>
                      </td>
                    </tr>
                  </template>
                  <tr v-if="materialDetailDialog.row.materials.length === 0">
                    <td class="px-3 py-5 text-center text-gray-500" colspan="6">{{ t('common.noData') }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </div>
    </div>

    <div v-if="packingDialog.open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-4xl bg-white rounded-xl shadow-lg border border-gray-200">
        <header class="flex items-start justify-between px-4 py-3 border-b gap-4">
          <div>
            <h3 class="text-lg font-semibold text-gray-800">{{ t('batch.packaging.dialog.title') }}</h3>
            <p class="text-xs text-gray-500">
              {{ t('batch.packaging.dialog.batchSummary', { code: batch?.batch_code ?? '—', name: batchForm.batch_label || '—' }) }}
            </p>
          </div>
          <button class="text-sm px-2 py-1 rounded border hover:bg-gray-100" type="button" @click="closePackingDialog">
            {{ t('common.close') }}
          </button>
        </header>
        <div class="p-4 space-y-4">
          <div v-if="packingDialog.globalError" class="text-sm text-red-600">{{ packingDialog.globalError }}</div>
          <div class="border border-gray-200 rounded-lg p-3 space-y-3">
            <h4 class="text-sm font-semibold text-gray-700">{{ t('batch.packaging.dialog.summaryTitle') }}</h4>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-3 text-sm text-gray-600">
              <div class="space-y-1">
                <div class="text-xs uppercase text-gray-500">{{ t('batch.packaging.dialog.summaryTotal') }}</div>
                <div class="text-base font-semibold text-gray-800">{{ packingSummaryTotalText }}</div>
              </div>
              <div class="space-y-1">
                <div class="text-xs uppercase text-gray-500">{{ t('batch.packaging.dialog.summaryProcessed') }}</div>
                <div class="text-base font-semibold text-gray-800">{{ packingSummaryProcessedText }}</div>
              </div>
              <div class="space-y-1">
                <div class="text-xs uppercase text-gray-500">{{ t('batch.packaging.dialog.summaryRemaining') }}</div>
                <div
                  class="text-base font-semibold"
                  :class="packingRemainingVolumeClass"
                >
                  {{ packingSummaryRemainingText }}
                </div>
              </div>
            </div>
            <p class="text-xs text-gray-500">{{ t('batch.packaging.dialog.summaryHint') }}</p>
          </div>
          <div class="space-y-3">
            <div>
              <p class="text-xs uppercase text-gray-500 mb-2">{{ t('batch.packaging.dialog.packingType') }}</p>
              <div class="grid grid-cols-1 sm:grid-cols-5 gap-2">
                <button
                  v-for="option in packingTypeOptions"
                  :key="option.value"
                  class="px-3 py-2 rounded border text-sm"
                  :class="packingDialog.form.packing_type === option.value ? 'border-blue-600 bg-blue-50 text-blue-700' : 'border-gray-200 text-gray-600 hover:bg-gray-50'"
                  type="button"
                  @click="selectPackingType(option.value)"
                >
                  {{ option.label }}
                </button>
              </div>
              <p v-if="packingDialog.errors.packing_type" class="mt-1 text-xs text-red-600">{{ packingDialog.errors.packing_type }}</p>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
              <div>
                <label class="block text-sm text-gray-600 mb-1" for="packingEventTime">{{ t('batch.packaging.dialog.eventTime') }}</label>
                <input id="packingEventTime" v-model="packingDialog.form.event_time" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
                <p v-if="packingDialog.errors.event_time" class="mt-1 text-xs text-red-600">{{ packingDialog.errors.event_time }}</p>
              </div>
            </div>
          </div>

          <div v-if="showPackingVolumeSection" class="border border-gray-200 rounded-lg p-3 space-y-3">
            <div>
              <h4 class="text-sm font-semibold text-gray-700">{{ t('batch.packaging.dialog.volumeSection') }}</h4>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div>
                <label class="block text-sm text-gray-600 mb-1" for="packingVolumeQty">{{ t('batch.packaging.dialog.volumeQty') }}</label>
                <div class="flex items-center gap-2">
                  <input id="packingVolumeQty" v-model="packingDialog.form.volume_qty" type="number" min="0" step="0.001" class="w-full h-[40px] border rounded px-3 text-right" />
                  <span class="text-sm text-gray-500">{{ t('batch.packaging.dialog.volumeUnit') }}</span>
                </div>
                <p v-if="packingDialog.errors.volume_qty" class="mt-1 text-xs text-red-600">{{ packingDialog.errors.volume_qty }}</p>
              </div>
              <div v-if="showPackingReason" class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1" for="packingReason">{{ t('batch.packaging.dialog.reason') }}</label>
                <input id="packingReason" v-model.trim="packingDialog.form.reason" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
            </div>
          </div>

          <div v-if="showPackingFillingSection" class="border border-gray-200 rounded-lg p-3 space-y-3">
            <div class="flex items-center justify-between">
              <h4 class="text-sm font-semibold text-gray-700">{{ t('batch.packaging.dialog.fillingSection') }}</h4>
              <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="addFillingLine">
                {{ t('batch.packaging.dialog.addFilling') }}
              </button>
            </div>
            <div v-if="packingDialog.errors.filling_lines" class="text-xs text-red-600">{{ packingDialog.errors.filling_lines }}</div>
            <div class="overflow-x-auto border border-gray-200 rounded-lg">
              <table class="min-w-full text-sm divide-y divide-gray-200">
                <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
                  <tr>
                    <th class="px-3 py-2 text-left">{{ t('batch.packaging.dialog.fillingTable.packageType') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('batch.packaging.dialog.fillingTable.qty') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('batch.packaging.dialog.fillingTable.unitVolume') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('batch.packaging.dialog.fillingTable.totalVolume') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="(line, index) in packingDialog.form.filling_lines" :key="line.id">
                    <td class="px-3 py-2">
                      <select v-model="line.package_type_id" class="w-full h-[36px] border rounded px-2 bg-white">
                        <option value="">{{ t('common.select') }}</option>
                        <option v-for="option in packageCategoryOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                      </select>
                    </td>
                    <td class="px-3 py-2 text-right">
                      <input v-model="line.qty" type="number" min="1" step="1" class="w-full h-[36px] border rounded px-2 text-right" />
                    </td>
                    <td class="px-3 py-2 text-right text-gray-600">{{ formatFillingUnitVolume(line.package_type_id) }}</td>
                    <td class="px-3 py-2 text-right text-gray-600">{{ formatFillingLineTotal(line) }}</td>
                    <td class="px-3 py-2">
                      <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="removeFillingLine(index)">
                        {{ t('batch.packaging.actions.delete') }}
                      </button>
                    </td>
                  </tr>
                  <tr v-if="packingDialog.form.filling_lines.length === 0">
                    <td class="px-3 py-4 text-center text-gray-500" colspan="5">{{ t('batch.packaging.dialog.noFillingLines') }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-3 text-sm text-gray-600">
              <div>{{ t('batch.packaging.dialog.fillingTotals.units', { count: packingFillingTotals.totalUnits }) }}</div>
              <div>{{ t('batch.packaging.dialog.fillingTotals.volume', { volume: formatVolumeValue(packingFillingTotals.totalVolume) }) }}</div>
            </div>
          </div>

          <div v-if="showPackingMovementSection" class="border border-gray-200 rounded-lg p-3 space-y-3">
            <h4 class="text-sm font-semibold text-gray-700">{{ t('batch.packaging.dialog.movementSection') }}</h4>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1" for="packingMovementSite">{{ t('batch.packaging.dialog.movementSite') }}</label>
                <select id="packingMovementSite" v-model="packingDialog.form.movement_site_id" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in siteOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
                <p v-if="packingDialog.errors.movement_site_id" class="mt-1 text-xs text-red-600">{{ packingDialog.errors.movement_site_id }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1" for="packingMovementQty">{{ t('batch.packaging.dialog.movementQty') }}</label>
                <input id="packingMovementQty" v-model="packingDialog.form.movement_qty" type="number" min="0" step="0.001" class="w-full h-[40px] border rounded px-3 text-right" @input="markMovementQtyTouched" />
                <p v-if="packingDialog.errors.movement_qty" class="mt-1 text-xs text-red-600">{{ packingDialog.errors.movement_qty }}</p>
              </div>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1" for="packingMovementMemo">{{ t('batch.packaging.dialog.movementMemo') }}</label>
              <input id="packingMovementMemo" v-model.trim="packingDialog.form.movement_memo" type="text" class="w-full h-[40px] border rounded px-3" />
            </div>
          </div>

          <div class="border border-gray-200 rounded-lg p-3 space-y-2">
            <h4 class="text-sm font-semibold text-gray-700">{{ t('batch.packaging.dialog.reviewTitle') }}</h4>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-2 text-sm text-gray-600">
              <div>{{ t('batch.packaging.dialog.reviewType') }}: <span class="text-gray-800">{{ formatPackingType(packingDialog.form.packing_type) }}</span></div>
              <div>{{ t('batch.packaging.dialog.reviewVolume') }}: <span class="text-gray-800">{{ reviewVolumeText }}</span></div>
              <div>{{ t('batch.packaging.dialog.reviewMovement') }}: <span class="text-gray-800">{{ reviewMovementText }}</span></div>
              <div>{{ t('batch.packaging.dialog.reviewFilling') }}: <span class="text-gray-800">{{ reviewFillingText }}</span></div>
            </div>
            <p v-if="packingMismatchWarning" class="text-xs text-amber-600">{{ packingMismatchWarning }}</p>
          </div>
        </div>
        <footer class="flex items-center justify-end gap-2 px-4 py-3 border-t">
          <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100" type="button" :disabled="packingDialog.loading" @click="closePackingDialog">
            {{ t('batch.packaging.dialog.cancel') }}
          </button>
          <button class="px-3 py-2 rounded border border-blue-600 text-blue-600 hover:bg-blue-50 disabled:opacity-50" type="button" :disabled="packingDialog.loading" @click="savePackingEvent(true)">
            {{ t('batch.packaging.dialog.saveAndAdd') }}
          </button>
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="packingDialog.loading" @click="savePackingEvent(false)">
            {{ packingDialog.loading ? t('common.saving') : t('batch.packaging.dialog.save') }}
          </button>
        </footer>
      </div>
    </div>

    <BatchIngredientDialog :open="ingredientDialog.open" :editing="ingredientDialog.editing" :loading="ingredientDialog.loading" :materials="materials" :uoms="uoms" :initial="ingredientDialog.initial" @close="closeIngredientDialog" @submit="saveIngredient" />
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute } from 'vue-router'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import BatchIngredientDialog from '@/views/Pages/components/BatchIngredientDialog.vue'

const route = useRoute()
const { t, locale } = useI18n()

const batchId = computed(() => route.params.batchId as string | undefined)

const pageTitle = computed(() => t('batch.edit.title'))

const tenantId = ref<string | null>(null)
const batch = ref<any>(null)
const loadingBatch = ref(false)
const savingBatch = ref(false)
const savingPackaging = ref(false)

const batchForm = reactive({
  batch_code: '',
  status: '',
  batch_label: '',
  scale_factor: null as number | null,
  process_version: null as number | null,
  planned_start: '',
  planned_end: '',
  actual_start: '',
  actual_end: '',
  notes: '',
  kpi_rows: [] as KpiRow[],
  material_consumption_rows: {} as Record<string, MaterialConsumptionClassRow>,
  output_rows: [] as OutputRowForm[],
})

type KpiRow = {
  id: string
  name: string
  uom: string
  datasource?: string | null
  search_key_flg?: boolean
  planed: string
  actual: string
}

type MaterialClass = {
  def_key: string
  name: string
  label: string
}

type MaterialConsumptionDetail = {
  batch_id: string
  qty: string
  uom: string
}

type MaterialConsumptionRow = {
  material_id: string
  planned_qty: string
  actual_qty: string
  variance: string
  uom: string
  details_notes: string
  batches: MaterialConsumptionDetail[]
}

type MaterialConsumptionClassRow = {
  planned_qty: string
  actual_qty: string
  variance: string
  details_notes: string
  materials: MaterialConsumptionRow[]
}

type OutputRowForm = {
  material_id: string
  qty: string
  uom: string
  type: string
  disposition_type: '' | 'transfer_batch' | 'transfer_warehouse' | 'disposal'
  transfer_batch_id: string
  transfer_qty: string
  transfer_uom: string
  warehouse_site_id: string
  warehouse_qty: string
  warehouse_uom: string
  disposal_reason: string
}

type KpiMeta = {
  id: string
  name: string
  uom: string
  datasource?: string | null
  search_key_flg?: boolean
}

const ingredients = ref<Array<any>>([])
const ingredientLoading = ref(false)
const materials = ref<Array<{ id: string, name: string, code: string }>>([])
const uoms = ref<Array<{ id: string, code: string }>>([])

const ingredientDialog = reactive({
  open: false,
  editing: false,
  loading: false,
  initial: null as any,
})

const materialDetailDialog = reactive({
  open: false,
  row: null as MaterialConsumptionClassRow | null,
  materialLabel: '',
  classKey: '',
})

const sectionCollapsed = reactive({
  ingredients: false,
  packaging: false,
  steps: false,
  kpi: false,
  materials: false,
})

interface PackageCategoryOption {
  id: string
  code: string
  name: string | null
  default_volume_l: number | null
  display: string
}

interface SiteOption {
  value: string
  label: string
  code?: string
}

interface PackageRow {
  id: string
  movement_id: string
  fill_at: string | null
  package_id: string
  package_code: string
  package_label: string
  site_id: string | null
  package_qty: number
  unit_volume_l: number | null
  total_volume_l: number
  notes: string | null
}

const packageCategories = ref<PackageCategoryOption[]>([])
const packages = ref<PackageRow[]>([])
const packagesLoading = ref(false)
const siteOptions = ref<SiteOption[]>([])
const packageDialog = reactive({
  open: false,
  editing: false,
  loading: false,
  initial: null as any,
})

type PackingType = 'ship' | 'filling' | 'transfer' | 'loss' | 'dispose'

type PackingFillingLine = {
  id: string
  package_type_id: string
  qty: number
}

type PackingEvent = {
  id: string
  packing_type: PackingType
  event_time: string
  memo: string | null
  volume_qty: number | null
  volume_uom: string | null
  movement: { site_id: string | null, qty: number | null, memo: string | null } | null
  filling_lines: PackingFillingLine[]
  reason: string | null
}

type PackingFillingLineForm = {
  id: string
  package_type_id: string
  qty: string
}

type PackingFormState = {
  id?: string
  packing_type: PackingType
  event_time: string
  memo: string
  volume_qty: string
  movement_site_id: string
  movement_qty: string
  movement_memo: string
  filling_lines: PackingFillingLineForm[]
  reason: string
}

const packingEvents = ref<PackingEvent[]>([])
const packingNotice = ref('')
const packingMovementQtyTouched = ref(false)
const packingDialog = reactive({
  open: false,
  editing: false,
  loading: false,
  globalError: '',
  errors: {} as Record<string, string>,
  form: null as PackingFormState | null,
})

const steps = ref<Array<any>>([])
const stepsLoading = ref(false)

const materialClasses = ref<MaterialClass[]>([])
const materialClassLoading = ref(false)
const batchOptions = ref<Array<{ value: string, label: string }>>([])
const batchStatusRows = ref<Array<{ status_code: string, label_ja: string | null, label_en: string | null, sort_order: number | null }>>([])
const batchStatusLoading = ref(false)

const batchStatusOptions = computed(() => {
  const lang = String(locale.value ?? '').toLowerCase()
  const useJa = lang.startsWith('ja')
  return batchStatusRows.value
    .slice()
    .sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0))
    .map((row) => {
      const label = useJa ? row.label_ja : row.label_en
      const fallback = row.label_en ?? row.label_ja ?? row.status_code
      return { value: row.status_code, label: String(label ?? fallback ?? row.status_code).trim() || row.status_code }
    })
})

const totalFilledVolume = computed(() => {
  return packages.value.reduce((sum, row) => sum + row.total_volume_l, 0)
})

const totalProductVolume = computed(() => {
  const actualKpi = kpiValue(batchForm.kpi_rows, 'volume', 'actual')
    ?? kpiValue(batchForm.kpi_rows, 'volume_l', 'actual')
  if (actualKpi != null) return actualKpi
  const plannedKpi = kpiValue(batchForm.kpi_rows, 'volume', 'planed')
    ?? kpiValue(batchForm.kpi_rows, 'volume_l', 'planed')
  if (plannedKpi != null) return plannedKpi
  const legacyActual = resolveMetaNumber(batch.value?.meta, 'actual_product_volume')
  return legacyActual
})

const remainingVolume = computed(() => {
  if (totalProductVolume.value == null) return null
  return Math.max(totalProductVolume.value - totalFilledVolume.value, 0)
})

const siteOptionMap = computed(() => {
  const map = new Map<string, string>()
  siteOptions.value.forEach((item) => map.set(item.value, item.label))
  return map
})

const siteCodeMap = computed(() => {
  const map = new Map<string, string>()
  siteOptions.value.forEach((item) => {
    if (item.code) map.set(item.value, item.code)
  })
  return map
})

const uomLookup = computed(() => {
  const map = new Map<string, string>()
  uoms.value.forEach((row) => {
    if (row.id) map.set(row.id, row.code ?? '')
  })
  return map
})

const materialConsumptionGroups = computed(() => {
  const groups: Array<{ key: string, label: string, row: MaterialConsumptionClassRow }> = []
  const keys = new Set<string>()
  materialClasses.value.forEach((cls) => {
    const label = cls.label || cls.name || cls.def_key
    keys.add(cls.def_key)
    groups.push({
      key: cls.def_key,
      label,
      row: batchForm.material_consumption_rows[cls.def_key] ?? {
        planned_qty: '',
        actual_qty: '',
        variance: '',
        details_notes: '',
        materials: [],
      },
    })
  })
  Object.keys(batchForm.material_consumption_rows || {}).forEach((key) => {
    if (keys.has(key)) return
    groups.push({
      key,
      label: key,
      row: batchForm.material_consumption_rows[key] ?? {
        planned_qty: '',
        actual_qty: '',
        variance: '',
        details_notes: '',
        materials: [],
      },
    })
  })
  return groups
})

const materialOptions = computed(() => {
  return materials.value.map((row) => ({
    value: row.id,
    label: row.code ? `${row.name} (${row.code})` : row.name,
  }))
})

const materialLabelMap = computed(() => {
  const map = new Map<string, string>()
  materialOptions.value.forEach((option) => {
    if (!option.value) return
    map.set(option.value, option.label)
  })
  return map
})

const packageCategoryOptions = computed(() =>
  packageCategories.value.map((row) => ({
    value: row.id,
    label: row.display,
  }))
)

const packingTypeOptions = computed(() => ([
  { value: 'filling', label: t('batch.packaging.types.filling') },
  { value: 'ship', label: t('batch.packaging.types.ship') },
  { value: 'transfer', label: t('batch.packaging.types.transfer') },
  { value: 'loss', label: t('batch.packaging.types.loss') },
  { value: 'dispose', label: t('batch.packaging.types.dispose') },
] as Array<{ value: PackingType, label: string }>))

const showPackingVolumeSection = computed(() => {
  const type = packingDialog.form?.packing_type
  return type === 'ship' || type === 'transfer' || type === 'loss' || type === 'dispose'
})

const showPackingMovementSection = computed(() => {
  const type = packingDialog.form?.packing_type
  return type === 'ship' || type === 'filling' || type === 'transfer'
})

const showPackingFillingSection = computed(() => packingDialog.form?.packing_type === 'filling')

const showPackingReason = computed(() => {
  const type = packingDialog.form?.packing_type
  return type === 'loss' || type === 'dispose'
})

const packingFillingTotals = computed(() => {
  const lines = packingDialog.form?.filling_lines ?? []
  return computeFillingTotals(lines)
})

const packingProcessedVolume = computed(() => {
  if (!packingEvents.value.length) return 0
  let total = 0
  packingEvents.value.forEach((event) => {
    if (event.packing_type === 'filling') {
      const qty = event.movement?.qty
      if (qty != null) total += qty
      return
    }
    if (event.volume_qty != null) {
      total += event.volume_qty
      return
    }
    if (event.movement?.qty != null) total += event.movement.qty
  })
  return total
})

const packingRemainingVolume = computed(() => {
  if (totalProductVolume.value == null) return null
  return Math.max(totalProductVolume.value - packingProcessedVolume.value, 0)
})

const packingSummaryTotalText = computed(() => {
  if (totalProductVolume.value == null) return '—'
  return formatVolumeValue(totalProductVolume.value)
})

const packingSummaryProcessedText = computed(() => {
  return formatVolumeValue(packingProcessedVolume.value)
})

const packingSummaryRemainingText = computed(() => {
  if (packingRemainingVolume.value == null) return '—'
  return formatVolumeValue(packingRemainingVolume.value)
})

const packingRemainingVolumeClass = computed(() => {
  if (packingRemainingVolume.value == null) return 'text-gray-800'
  if (packingRemainingVolume.value > 0) return 'text-amber-600'
  return 'text-emerald-600'
})

const reviewVolumeText = computed(() => {
  if (!packingDialog.form) return '—'
  if (packingDialog.form.packing_type === 'filling') {
    const total = packingFillingTotals.value.totalVolume
    return total != null ? formatVolumeValue(total) : '—'
  }
  if (!showPackingVolumeSection.value) return '—'
  const qty = toNumber(packingDialog.form.volume_qty)
  return qty != null ? formatVolumeValue(qty) : '—'
})

const reviewMovementText = computed(() => {
  if (!packingDialog.form || !showPackingMovementSection.value) return '—'
  const site = siteLabel(packingDialog.form.movement_site_id || null)
  const qty = toNumber(packingDialog.form.movement_qty)
  const qtyLabel = qty != null ? formatVolumeValue(qty) : '—'
  return `${site} / ${qtyLabel}`
})

const reviewFillingText = computed(() => {
  if (!showPackingFillingSection.value) return '—'
  return formatFillingTotals(packingFillingTotals.value)
})

const packingMismatchWarning = computed(() => {
  if (!packingDialog.form || !showPackingMovementSection.value) return ''
  const movementQty = toNumber(packingDialog.form.movement_qty)
  if (movementQty == null) return ''
  if (packingDialog.form.packing_type === 'filling') {
    const total = packingFillingTotals.value.totalVolume
    if (total != null && Math.abs(movementQty - total) > 0.0001) {
      return t('batch.packaging.warnings.movementMismatch')
    }
    return ''
  }
  if (showPackingVolumeSection.value) {
    const volumeQty = toNumber(packingDialog.form.volume_qty)
    if (volumeQty != null && Math.abs(movementQty - volumeQty) > 0.0001) {
      return t('batch.packaging.warnings.movementMismatch')
    }
  }
  return ''
})

function materialListText(rows: MaterialConsumptionRow[]) {
  if (!rows || rows.length === 0) return t('common.noData')
  const labels = rows
    .map((row) => materialLabelMap.value.get(row.material_id) || row.material_id)
    .map((label) => String(label || '').trim())
    .filter((label) => label.length)
  if (!labels.length) return t('common.noData')
  return labels.join(', ')
}

const kpiMeta = ref<KpiMeta[]>([])
const kpiMetaLoading = ref(false)

const fallbackKpiMeta: KpiMeta[] = [
  { id: 'tax_category_code', name: '製品種類', uom: '', datasource: 'registry_def', search_key_flg: true },
  { id: 'volume', name: '生産量', uom: 'l' },
  { id: 'abv', name: 'ABV', uom: '' },
  { id: 'og', name: 'OG', uom: '' },
  { id: 'fg', name: 'FG', uom: '' },
  { id: 'srm', name: 'SRM', uom: '' },
  { id: 'ibu', name: 'IBU', uom: '' },
]

function siteLabel(siteId?: string | null) {
  if (!siteId) return '—'
  return siteOptionMap.value.get(siteId) ?? '—'
}

function parseKpiArray(value: unknown) {
  if (!value) return []
  if (Array.isArray(value)) return value
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value)
      return Array.isArray(parsed) ? parsed : []
    } catch {
      return []
    }
  }
  return []
}

function normalizeKpiMeta(list: unknown): KpiMeta[] {
  if (!Array.isArray(list)) return []
  return list
    .map((item) => {
      if (!item || typeof item !== 'object' || Array.isArray(item)) return null
      const id = String((item as Record<string, unknown>).id ?? '').trim()
      if (!id) return null
      const name = String((item as Record<string, unknown>).name ?? id).trim()
      const uom = String((item as Record<string, unknown>).uom ?? '').trim()
      const datasource = (item as Record<string, unknown>).datasource
      const searchKey = (item as Record<string, unknown>).search_key_flg
      return {
        id,
        name: name || id,
        uom,
        datasource: datasource != null ? String(datasource) : null,
        search_key_flg: Boolean(searchKey),
      }
    })
    .filter((row): row is KpiMeta => row !== null)
}

async function loadKpiMeta() {
  if (kpiMeta.value.length || kpiMetaLoading.value) return
  try {
    kpiMetaLoading.value = true
    const { data, error } = await supabase
      .from('registry_def')
      .select('def_id, scope, spec')
      .eq('kind', 'kpi_definition')
      .eq('def_key', 'beer_production_kpi')
    if (error) throw error
    const selected = (data ?? []).find((row: any) => row.scope === 'tenant')
      ?? (data ?? [])[0]
    const metaList = normalizeKpiMeta((selected?.spec as any)?.kpi_meta)
    kpiMeta.value = metaList
  } catch (err) {
    console.warn('Failed to load KPI meta', err)
    kpiMeta.value = []
  } finally {
    kpiMetaLoading.value = false
  }
}

function normalizeKpiRows(source: unknown): KpiRow[] {
  const list = parseKpiArray(source)
  const existing = new Map<string, any>()
  list.forEach((row) => {
    if (!row || typeof row !== 'object' || Array.isArray(row)) return
    const id = String((row as Record<string, unknown>).id ?? '').trim()
    if (!id) return
    existing.set(id, row)
  })

  const metaList = kpiMeta.value.length ? kpiMeta.value : fallbackKpiMeta
  return metaList.map((def) => {
    const raw = (existing.get(def.id)
      ?? (def.id === 'volume' ? existing.get('volume_l') : undefined)) as Record<string, unknown> | undefined
    const plannedValue = raw?.planed ?? raw?.planned
    return {
      id: def.id,
      name: def.name,
      uom: def.uom,
      datasource: def.datasource ?? null,
      search_key_flg: def.search_key_flg ?? false,
      planed: plannedValue != null ? String(plannedValue) : '',
      actual: raw?.actual != null ? String(raw.actual) : '',
    }
  })
}

function kpiValue(rows: KpiRow[], id: string, key: 'planed' | 'actual') {
  const match = rows.find((row) => row.id === id)
  if (!match) return null
  return toNumber(match[key])
}

function isNumericKpi(row: KpiRow) {
  return row.datasource !== 'registry_def'
}

function kpiPayloadValue(row: KpiRow, value: string) {
  if (value == null || value === '') return null
  if (isNumericKpi(row)) return toNumber(value)
  const trimmed = value.trim()
  return trimmed.length ? trimmed : null
}

function buildKpiPayload(rows: KpiRow[]) {
  if (!rows.length) return []
  return rows.map((row) => ({
    id: row.id,
    name: row.name?.trim() || row.id,
    uom: row.uom?.trim() || '',
    datasource: row.datasource ?? undefined,
    search_key_flg: row.search_key_flg ?? undefined,
    planed: kpiPayloadValue(row, row.planed),
    actual: kpiPayloadValue(row, row.actual),
  }))
}

function normalizeMaterialConsumptionRows(value: unknown) {
  const toRows = (list: any[]): MaterialConsumptionRow[] => {
    return (list ?? []).map((item) => {
      const planned = item?.planned_qty ?? item?.planned
      const actual = item?.actual_qty ?? item?.actual
      const variance = item?.variance
      const notes = item?.details_notes ?? item?.notes ?? ''
      const batches = Array.isArray(item?.batches) ? item.batches : []
      return {
        material_id: String(item?.material_id ?? ''),
        planned_qty: planned != null ? String(planned) : '',
        actual_qty: actual != null ? String(actual) : '',
        variance: variance != null ? String(variance) : '',
        uom: String(item?.uom ?? ''),
        details_notes: String(notes ?? ''),
        batches: batches.map((batch: any) => ({
          batch_id: String(batch?.batch_id ?? ''),
          qty: batch?.qty != null ? String(batch.qty) : '',
          uom: String(batch?.uom ?? ''),
        })),
      }
    })
  }

  if (!value) return {}
  const toClassRow = (items: MaterialConsumptionRow[], summary?: any): MaterialConsumptionClassRow => {
    const planned = summary?.planned_qty ?? summary?.planned
    const actual = summary?.actual_qty ?? summary?.actual
    const variance = summary?.variance
    const notes = summary?.details_notes ?? summary?.notes ?? ''
    const plannedValue = planned != null ? String(planned) : ''
    const actualValue = actual != null ? String(actual) : ''
    const varianceValue = variance != null ? String(variance) : ''
    return {
      planned_qty: plannedValue,
      actual_qty: actualValue,
      variance: varianceValue,
      details_notes: String(notes ?? ''),
      materials: items,
    }
  }

  if (Array.isArray(value)) {
    const items = toRows(value)
    return { unclassified: toClassRow(items) }
  }
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value)
      if (Array.isArray(parsed)) return { unclassified: toClassRow(toRows(parsed)) }
      if (parsed && typeof parsed === 'object') {
        return Object.fromEntries(Object.entries(parsed as Record<string, unknown>)
          .map(([key, val]) => {
            if (Array.isArray(val)) return [key, toClassRow(toRows(val))]
            if (typeof val === 'string') {
              try {
                const parsedVal = JSON.parse(val)
                return [key, toClassRow(toRows(Array.isArray(parsedVal) ? parsedVal : []))]
              } catch {
                return [key, toClassRow([])]
              }
            }
            if (val && typeof val === 'object') {
              const items = Array.isArray((val as any).items) ? (val as any).items : []
              const summary = (val as any).summary ?? val
              return [key, toClassRow(toRows(items), summary)]
            }
            return [key, toClassRow([])]
          }))
      }
    } catch {
      return {}
    }
  }
  if (value && typeof value === 'object') {
    return Object.fromEntries(Object.entries(value as Record<string, unknown>)
      .map(([key, val]) => {
        if (Array.isArray(val)) return [key, toClassRow(toRows(val))]
        if (typeof val === 'string') {
          try {
            const parsedVal = JSON.parse(val)
            return [key, toClassRow(toRows(Array.isArray(parsedVal) ? parsedVal : []))]
          } catch {
            return [key, toClassRow([])]
          }
        }
        if (val && typeof val === 'object') {
          const items = Array.isArray((val as any).items) ? (val as any).items : []
          const summary = (val as any).summary ?? val
          return [key, toClassRow(toRows(items), summary)]
        }
        return [key, toClassRow([])]
      }))
  }
  return {}
}

function ensureMaterialConsumptionKeys() {
  const map = { ...(batchForm.material_consumption_rows || {}) }
  materialClasses.value.forEach((cls) => {
    if (!(cls.def_key in map)) {
      map[cls.def_key] = {
        planned_qty: '',
        actual_qty: '',
        variance: '',
        details_notes: '',
        materials: [],
      }
    }
  })
  batchForm.material_consumption_rows = map
}

function buildMaterialConsumptionPayload(map: Record<string, MaterialConsumptionClassRow>) {
  const payload: Record<string, unknown> = {}
  Object.entries(map || {}).forEach(([key, rows]) => {
    const detailRows = (rows.materials ?? [])
      .map((row) => {
        const planned = row.planned_qty !== '' ? toNumber(row.planned_qty) : null
        const actual = row.actual_qty !== '' ? toNumber(row.actual_qty) : null
        const variance = row.variance !== ''
          ? toNumber(row.variance)
          : (planned != null && actual != null ? actual - planned : null)
        const batches = (row.batches ?? [])
          .map((batch) => ({
            batch_id: batch.batch_id || null,
            qty: batch.qty !== '' ? toNumber(batch.qty) : null,
            uom: batch.uom || null,
          }))
          .filter((batch) => batch.batch_id || batch.qty != null || batch.uom)
        const hasCore = row.material_id || planned != null || actual != null || row.uom || variance != null
        if (!hasCore) return null
        const entry: Record<string, unknown> = {
          material_id: row.material_id || null,
          planned_qty: planned,
          actual_qty: actual,
          uom: row.uom || null,
          variance,
        }
        const notes = row.details_notes?.trim()
        if (notes) entry.details_notes = notes
        if (batches.length) entry.batches = batches
        return entry
      })
      .filter((row): row is Record<string, unknown> => row !== null)

    const summaryPlanned = rows.planned_qty !== '' ? toNumber(rows.planned_qty) : null
    const summaryActual = rows.actual_qty !== '' ? toNumber(rows.actual_qty) : null
    const summaryVariance = rows.variance !== ''
      ? toNumber(rows.variance)
      : (summaryPlanned != null && summaryActual != null ? summaryActual - summaryPlanned : null)
    const summaryNotes = rows.details_notes?.trim()

    const summary: Record<string, unknown> = {}
    if (summaryPlanned != null) summary.planned_qty = summaryPlanned
    if (summaryActual != null) summary.actual_qty = summaryActual
    if (summaryVariance != null) summary.variance = summaryVariance
    if (summaryNotes) summary.details_notes = summaryNotes

    if (Object.keys(summary).length) {
      payload[key] = { summary, items: detailRows }
    } else if (detailRows.length) {
      payload[key] = detailRows
    }
  })
  return payload
}

function newMaterialConsumptionRow(): MaterialConsumptionRow {
  return {
    material_id: '',
    planned_qty: '',
    actual_qty: '',
    variance: '',
    uom: '',
    details_notes: '',
    batches: [],
  }
}

function newMaterialConsumptionClassRow(): MaterialConsumptionClassRow {
  return {
    planned_qty: '',
    actual_qty: '',
    variance: '',
    details_notes: '',
    materials: [],
  }
}

function variancePlaceholder(row: { planned_qty: string; actual_qty: string }) {
  const planned = toNumber(row.planned_qty)
  const actual = toNumber(row.actual_qty)
  if (planned == null || actual == null) return ''
  return String(actual - planned)
}

function openMaterialDetail(label: string, classKey: string) {
  if (!batchForm.material_consumption_rows[classKey]) {
    batchForm.material_consumption_rows[classKey] = newMaterialConsumptionClassRow()
  }
  if (!batchForm.material_consumption_rows[classKey].materials) {
    batchForm.material_consumption_rows[classKey].materials = []
  }
  materialDetailDialog.row = batchForm.material_consumption_rows[classKey]
  materialDetailDialog.materialLabel = label
  materialDetailDialog.classKey = classKey
  materialDetailDialog.open = true
}

function closeMaterialDetail() {
  materialDetailDialog.open = false
  materialDetailDialog.row = null
  materialDetailDialog.materialLabel = ''
  materialDetailDialog.classKey = ''
}

function addDetailMaterialRow() {
  if (!materialDetailDialog.row) return
  materialDetailDialog.row.materials.push(newMaterialConsumptionRow())
}

function removeDetailMaterialRow(index: number) {
  if (!materialDetailDialog.row) return
  materialDetailDialog.row.materials.splice(index, 1)
}

function addDetailBatch(row: MaterialConsumptionRow) {
  if (!row.batches) row.batches = []
  row.batches.push({ batch_id: '', qty: '', uom: '' })
}

function removeDetailBatch(row: MaterialConsumptionRow, index: number) {
  row.batches.splice(index, 1)
}

function newOutputRow(): OutputRowForm {
  return {
    material_id: '',
    qty: '',
    uom: '',
    type: '',
    disposition_type: '',
    transfer_batch_id: '',
    transfer_qty: '',
    transfer_uom: '',
    warehouse_site_id: '',
    warehouse_qty: '',
    warehouse_uom: '',
    disposal_reason: '',
  }
}

function normalizeOutputRows(value: unknown): OutputRowForm[] {
  const list = Array.isArray(value) ? value : parseKpiArray(value)
  if (!Array.isArray(list)) return []
  return list.map((item: any) => {
    const disposition = item?.disposition ?? {}
    let dispositionType: OutputRowForm['disposition_type'] = ''
    let transferBatchId = ''
    let transferQty = ''
    let transferUom = ''
    let warehouseSiteId = ''
    let warehouseQty = ''
    let warehouseUom = ''
    let disposalReason = ''

    const dispType = String(disposition?.type ?? '')
    if (dispType === 'transfer' || dispType === 'transfer_batch') {
      dispositionType = 'transfer_batch'
      const to = Array.isArray(disposition?.to) ? disposition.to[0] : null
      if (to) {
        transferBatchId = String(to.batch_id ?? '')
        transferQty = to.qty != null ? String(to.qty) : ''
        transferUom = String(to.uom ?? '')
      }
    } else if (dispType === 'transfer_warehouse' || dispType === 'warehouse') {
      dispositionType = 'transfer_warehouse'
      warehouseSiteId = String(disposition?.site_id ?? disposition?.warehouse_id ?? disposition?.to_site_id ?? '')
      warehouseQty = disposition?.qty != null ? String(disposition.qty) : ''
      warehouseUom = String(disposition?.uom ?? '')
    } else if (dispType === 'dispose' || dispType === 'disposal') {
      dispositionType = 'disposal'
      disposalReason = String(disposition?.reason ?? disposition?.reason_code ?? '')
    }

    return {
      material_id: String(item?.material_id ?? ''),
      qty: item?.qty != null ? String(item.qty) : '',
      uom: String(item?.uom ?? ''),
      type: String(item?.type ?? ''),
      disposition_type: dispositionType,
      transfer_batch_id: transferBatchId,
      transfer_qty: transferQty,
      transfer_uom: transferUom,
      warehouse_site_id: warehouseSiteId,
      warehouse_qty: warehouseQty,
      warehouse_uom: warehouseUom,
      disposal_reason: disposalReason,
    }
  })
}

function buildOutputPayload(rows: OutputRowForm[]) {
  return (rows ?? [])
    .map((row) => {
      const hasCore = row.material_id || row.qty || row.uom || row.type
      const base: Record<string, unknown> = {
        material_id: row.material_id || null,
        qty: row.qty !== '' ? toNumber(row.qty) : null,
        uom: row.uom || null,
        type: row.type || null,
      }

      let disposition: Record<string, unknown> | null = null
      if (row.disposition_type === 'transfer_batch') {
        const qty = row.transfer_qty !== '' ? toNumber(row.transfer_qty) : toNumber(row.qty)
        const uom = row.transfer_uom || row.uom || null
        disposition = {
          type: 'transfer',
          to: row.transfer_batch_id
            ? [{ batch_id: row.transfer_batch_id, qty, uom }]
            : [],
        }
      } else if (row.disposition_type === 'transfer_warehouse') {
        const qty = row.warehouse_qty !== '' ? toNumber(row.warehouse_qty) : toNumber(row.qty)
        const uom = row.warehouse_uom || row.uom || null
        disposition = {
          type: 'transfer_warehouse',
          site_id: row.warehouse_site_id || null,
          qty,
          uom,
        }
      } else if (row.disposition_type === 'disposal') {
        disposition = {
          type: 'dispose',
          reason: row.disposal_reason || null,
        }
      }

      if (disposition) base.disposition = disposition
      return { base, hasCore }
    })
    .filter((row) => row.hasCore)
    .map((row) => row.base)
}

function addOutputRow() {
  batchForm.output_rows.push(newOutputRow())
}

function removeOutputRow(index: number) {
  batchForm.output_rows.splice(index, 1)
}

function findLitersUomId() {
  const match = uoms.value.find((row) => row.code?.toLowerCase() === 'l')
  return match?.id ?? uoms.value[0]?.id ?? null
}

function buildPackagingDocNo(siteId: string | null) {
  const batchCode = batch.value?.batch_code ?? 'BATCH'
  const siteCode = siteId ? siteCodeMap.value.get(siteId) : null
  if (siteCode) return `PR-${batchCode}-${siteCode}`
  if (siteId) return `PR-${batchCode}-${siteId.slice(0, 6)}`
  return `PR-${batchCode}-NO-SITE`
}

function resolveMovementAt(existingAt: string | null, fillAt: string | null) {
  if (fillAt) {
    const parsed = new Date(fillAt)
    if (!Number.isNaN(parsed.getTime())) {
      if (existingAt) {
        const existing = new Date(existingAt)
        if (!Number.isNaN(existing.getTime()) && existing > parsed) return existingAt
      }
      return parsed.toISOString()
    }
  }
  return existingAt ?? new Date().toISOString()
}

async function ensurePackagingMovement(siteId: string | null, fillAt: string | null) {
  const tenant = await ensureTenant()
  const docNo = buildPackagingDocNo(siteId)
  const { data: existing, error } = await supabase
    .from('inv_movements')
    .select('id, movement_at, dest_site_id')
    .eq('tenant_id', tenant)
    .eq('doc_no', docNo)
    .maybeSingle()
  if (error) throw error

  const movementAt = resolveMovementAt(existing?.movement_at ?? null, fillAt)
  const payload = {
    tenant_id: tenant,
    doc_no: docNo,
    doc_type: 'production_receipt',
    status: 'posted',
    movement_at: movementAt,
    src_site_id: null,
    dest_site_id: siteId,
    meta: { material_type: 'beer', tax_type: '', tax_report_status: '' },
  }

  if (existing?.id) {
    const shouldUpdate = existing.dest_site_id !== siteId || existing.movement_at !== movementAt
    if (shouldUpdate) {
      const { error: updateError } = await supabase.from('inv_movements').update(payload).eq('id', existing.id)
      if (updateError) throw updateError
    }
    return { id: existing.id, movement_at: movementAt }
  }

  const { data, error: insertError } = await supabase.from('inv_movements').insert(payload).select('id, movement_at').single()
  if (insertError || !data) throw insertError || new Error('Insert failed')
  return { id: data.id, movement_at: data.movement_at ?? movementAt }
}

async function nextPackagingLineNo(movementId: string) {
  const { data, error } = await supabase
    .from('inv_movement_lines')
    .select('line_no')
    .eq('movement_id', movementId)
    .order('line_no', { ascending: false })
    .limit(1)
    .maybeSingle()
  if (error) throw error
  return (data?.line_no ?? 0) + 1
}

async function cleanupEmptyMovement(movementId: string) {
  const { data, error } = await supabase
    .from('inv_movement_lines')
    .select('id')
    .eq('movement_id', movementId)
    .limit(1)
  if (error) throw error
  if (!data || data.length === 0) {
    const { error: deleteError } = await supabase.from('inv_movements').delete().eq('id', movementId)
    if (deleteError) throw deleteError
  }
}

function resolveMetaLabel(meta: unknown) {
  if (!meta || typeof meta !== 'object' || Array.isArray(meta)) return null
  const label = (meta as Record<string, unknown>).label
  if (typeof label !== 'string') return null
  const trimmed = label.trim()
  return trimmed.length ? trimmed : null
}

function resolveMetaNumber(meta: unknown, key: string) {
  if (!meta || typeof meta !== 'object' || Array.isArray(meta)) return null
  const value = (meta as Record<string, unknown>)[key]
  if (value === null || value === undefined) return null
  const num = Number(value)
  return Number.isNaN(num) ? null : num
}

function toNumber(value: any): number | null {
  if (value === null || value === undefined || value === '') return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function buildMetaWithLabel(meta: unknown, label: string) {
  const base = (meta && typeof meta === 'object' && !Array.isArray(meta))
    ? { ...(meta as Record<string, unknown>) }
    : {}
  const trimmed = label.trim()
  if (trimmed) {
    base.label = trimmed
  } else {
    delete base.label
  }
  return base
}

type SectionKey = keyof typeof sectionCollapsed

function toggleSection(key: SectionKey) {
  sectionCollapsed[key] = !sectionCollapsed[key]
}

function collapseLabel(collapsed: boolean) {
  return collapsed ? t('common.expand') : t('common.collapse')
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved')
  tenantId.value = id
  return id
}

watch(batchId, (val) => {
  if (val) fetchBatch()
}, { immediate: true })

async function fetchBatch() {
  if (!batchId.value) return
  try {
    loadingBatch.value = true
    await ensureTenant()
    await loadKpiMeta()
    await loadMaterialClasses()
    await loadBatchOptions()
    await loadBatchStatusOptions()
    const { data, error } = await supabase
      .from('mes_batches')
      .select('*')
      .eq('id', batchId.value)
      .maybeSingle()
    if (error) throw error
    batch.value = data
    if (data) {
      batchForm.batch_code = data.batch_code ?? ''
      batchForm.status = data.status ?? ''
      batchForm.batch_label = data.batch_label ?? resolveMetaLabel(data.meta) ?? ''
      batchForm.scale_factor = data.scale_factor ?? null
      batchForm.process_version = data.process_version ?? null
      batchForm.planned_start = toInputDateTime(data.planned_start)
      batchForm.planned_end = toInputDateTime(data.planned_end)
      batchForm.actual_start = toInputDateTime(data.actual_start)
      batchForm.actual_end = toInputDateTime(data.actual_end)
      batchForm.kpi_rows = normalizeKpiRows(data.kpi)
      batchForm.material_consumption_rows = normalizeMaterialConsumptionRows(data.material_consumption)
      ensureMaterialConsumptionKeys()
      batchForm.output_rows = normalizeOutputRows(data.output_actual)
      batchForm.notes = data.notes ?? ''
      packingEvents.value = normalizePackingEvents((data.meta as any)?.packing_events)
      await Promise.all([
        loadIngredients(data.recipe_id),
        loadSteps(),
        loadMaterialsAndUoms(),
        loadSites(),
        loadPackages(data.id),
      ])
    } else {
      ingredients.value = []
      steps.value = []
      packages.value = []
      batchForm.kpi_rows = normalizeKpiRows(null)
      batchForm.material_consumption_rows = normalizeMaterialConsumptionRows(null)
      ensureMaterialConsumptionKeys()
      batchForm.output_rows = []
      packingEvents.value = []
    }
  } catch (err) {
    console.error(err)
  } finally {
    loadingBatch.value = false
  }
}

async function loadMaterialsAndUoms() {
  try {
    const tenant = await ensureTenant()
    const [matRes, uomRes] = await Promise.all([
      supabase.from('mst_materials').select('id, name, code').eq('tenant_id', tenant).order('name'),
      supabase.from('mst_uom').select('id, code').eq('tenant_id', tenant).order('code'),
    ])
    if (matRes.error) throw matRes.error
    if (uomRes.error) throw uomRes.error
    materials.value = matRes.data ?? []
    uoms.value = uomRes.data ?? []
  } catch (err) {
    console.error(err)
  }
}

async function loadSites() {
  try {
    const tenant = await ensureTenant()
    const { data, error } = await supabase
      .from('mst_sites')
      .select('id, code, name')
      .eq('tenant_id', tenant)
      .order('code')
    if (error) throw error
    siteOptions.value = (data ?? []).map((row: any) => ({
      value: row.id,
      label: `${row.code} — ${row.name}`,
      code: row.code,
    }))
  } catch (err) {
    console.error(err)
  }
}

async function loadMaterialClasses() {
  if (materialClassLoading.value) return
  try {
    materialClassLoading.value = true
    const { data, error } = await supabase
      .from('registry_def')
      .select('def_key, scope, spec, is_active')
      .eq('kind', 'material_class')
      .eq('is_active', true)
    if (error) throw error
    const rows = (data ?? []).filter((row: any) => {
      const category = String(row.spec?.category ?? '').trim()
      return category === '原材料'
    })
    const tenantRows = rows.filter((row: any) => row.scope === 'tenant')
    const systemRows = rows.filter((row: any) => row.scope !== 'tenant')
    const seen = new Set<string>()
    const merged: MaterialClass[] = []
    ;[...tenantRows, ...systemRows].forEach((row: any) => {
      const key = String(row.def_key ?? '').trim()
      if (!key || seen.has(key)) return
      const spec = row.spec ?? {}
      const name = String(spec.name ?? key).trim()
      const label = String(spec.label ?? spec.name ?? key).trim()
      merged.push({ def_key: key, name: name || key, label: label || key })
      seen.add(key)
    })
    merged.sort((a, b) => a.label.localeCompare(b.label))
    materialClasses.value = merged
    ensureMaterialConsumptionKeys()
  } catch (err) {
    console.warn('Failed to load material classes', err)
    materialClasses.value = []
  } finally {
    materialClassLoading.value = false
  }
}

async function loadBatchOptions() {
  try {
    const tenant = await ensureTenant()
    const { data, error } = await supabase
      .from('mes_batches')
      .select('id, batch_code')
      .eq('tenant_id', tenant)
      .order('batch_code')
    if (error) throw error
    batchOptions.value = (data ?? [])
      .filter((row: any) => row.id !== batchId.value)
      .map((row: any) => ({ value: row.id, label: row.batch_code }))
  } catch (err) {
    console.error(err)
  }
}

async function loadBatchStatusOptions() {
  if (batchStatusLoading.value) return
  try {
    batchStatusLoading.value = true
    const { data, error } = await supabase
      .from('v_batch_status')
      .select('status_code, label_ja, label_en, sort_order')
      .order('sort_order')
    if (error) throw error
    batchStatusRows.value = (data ?? []).map((row: any) => ({
      status_code: String(row.status_code ?? '').trim(),
      label_ja: row.label_ja ?? null,
      label_en: row.label_en ?? null,
      sort_order: typeof row.sort_order === 'number' ? row.sort_order : Number(row.sort_order ?? 0),
    })).filter((row: any) => row.status_code)
  } catch (err) {
    console.error('Failed to load batch statuses', err)
    batchStatusRows.value = []
  } finally {
    batchStatusLoading.value = false
  }
}

async function loadIngredients(recipeId: string | undefined) {
  ingredients.value = []
  if (!recipeId) return
  try {
    ingredientLoading.value = true
    const { data, error } = await supabase
      .from('mes_ingredients')
      .select('id, material_id, amount, uom_id, usage_stage, notes, material:mst_materials(name, code), uom:mst_uom(code)')
      .eq('recipe_id', recipeId)
      .order('usage_stage', { ascending: true })
    if (error) throw error
    ingredients.value = (data ?? []).map((row) => ({
      id: row.id,
      material_id: row.material_id,
      amount: row.amount,
      uom_id: row.uom_id,
      usage_stage: row.usage_stage,
      notes: row.notes,
      material_label: `${row.material?.name ?? ''} (${row.material?.code ?? ''})`.trim(),
      uom_code: row.uom?.code ?? null,
    }))
  } catch (err) {
    console.error(err)
  } finally {
    ingredientLoading.value = false
  }
}

async function loadSteps() {
  steps.value = []
  if (!batchId.value) return
  try {
    stepsLoading.value = true
    const { data, error } = await supabase
      .from('mes_batch_steps')
      .select('id, step_no, step, status, planned_params, actual_params, notes')
      .eq('batch_id', batchId.value)
      .order('step_no', { ascending: true })
    if (error) throw error
    steps.value = (data ?? []).map((row) => ({
      ...row,
      planned_summary: summariseJson(row.planned_params),
      edit: {
        status: row.status ?? 'open',
        actual_params: stringifyJson(row.actual_params),
        notes: row.notes ?? '',
      },
      saving: false,
    }))
  } catch (err) {
    console.error(err)
  } finally {
    stepsLoading.value = false
  }
}

async function fetchPackageCategories() {
  try {
    const { data, error } = await supabase
      .from('mst_beer_package_category')
      .select('id, package_code, package_name, size, uom:mst_uom(code)')
      .order('package_code', { ascending: true })
    if (error) throw error
    packageCategories.value = (data ?? []).map((row: any) => {
      const uomCode = row.uom?.code ?? null
      const defaultVolume = convertToLiters(row.size, uomCode)
      const namePart = row.package_name ? ` — ${row.package_name}` : ''
      const sizePart = defaultVolume != null ? ` (${defaultVolume.toLocaleString(undefined, { maximumFractionDigits: 2 })} L)` : ''
      return {
        id: row.id,
        code: row.package_code,
        name: row.package_name ?? null,
        default_volume_l: defaultVolume,
        display: `${row.package_code}${namePart}${sizePart}`,
      }
    })
  } catch (err) {
    console.error(err)
  }
}

async function loadPackages(targetBatchId: string | undefined) {
  packages.value = []
  if (!targetBatchId) return
  try {
    packagesLoading.value = true
    if (!packageCategories.value.length) {
      await fetchPackageCategories()
    }
    const tenant = await ensureTenant()
    const { data, error } = await supabase
      .from('inv_movement_lines')
      .select('id, movement_id, package_id, batch_id, qty, uom_id, notes, meta, movement:movement_id ( movement_at, status, dest_site_id, doc_type )')
      .eq('tenant_id', tenant)
      .eq('batch_id', targetBatchId)
      .not('package_id', 'is', null)
      .order('movement_id', { ascending: false })
    if (error) throw error

    const lines = (data ?? []).filter(
      (row: any) => row.movement?.doc_type === 'production_receipt' && row.movement?.status !== 'void'
    )

    packages.value = lines.map((row: any) => {
      const category = packageCategories.value.find((c) => c.id === row.package_id)
      const meta = row.meta ?? {}
      const unitVolume = toNumber(meta.unit_volume_l) ?? category?.default_volume_l ?? null
      const qtyLiters = row.qty != null ? convertToLiters(Number(row.qty), row.uom_id ? uomLookup.value.get(row.uom_id) : null) : null
      const qtyFromMeta = toNumber(meta.package_qty)
      const derivedQty = qtyFromMeta != null
        ? qtyFromMeta
        : unitVolume && qtyLiters != null
          ? qtyLiters / unitVolume
          : 0
      const totalVolume = qtyLiters != null ? qtyLiters : (unitVolume ?? 0) * derivedQty
      return {
        id: row.id,
        movement_id: row.movement_id,
        fill_at: meta.fill_at ?? row.movement?.movement_at ?? null,
        package_id: row.package_id,
        package_code: category?.code ?? '—',
        package_label: category?.name ? `${category.code} — ${category.name}` : category?.code ?? '—',
        site_id: row.movement?.dest_site_id ?? null,
        package_qty: derivedQty,
        unit_volume_l: unitVolume,
        total_volume_l: totalVolume,
        notes: row.notes ?? null,
      }
    })
    packages.value.sort((a, b) => {
      const aTime = a.fill_at ? Date.parse(a.fill_at) : 0
      const bTime = b.fill_at ? Date.parse(b.fill_at) : 0
      return bTime - aTime
    })
  } catch (err) {
    console.error(err)
  } finally {
    packagesLoading.value = false
  }
}

function openIngredientAdd() {
  ingredientDialog.open = true
  ingredientDialog.editing = false
  ingredientDialog.initial = {
    material_id: '',
    amount: null,
    uom_id: '',
    usage_stage: null,
    notes: null,
  }
}

function openIngredientEdit(row: any) {
  ingredientDialog.open = true
  ingredientDialog.editing = true
  ingredientDialog.initial = {
    id: row.id,
    material_id: row.material_id,
    amount: row.amount,
    uom_id: row.uom_id,
    usage_stage: row.usage_stage,
    notes: row.notes,
  }
}

function closeIngredientDialog() {
  ingredientDialog.open = false
  ingredientDialog.initial = null
}

async function saveIngredient(payload: any) {
  if (!batch.value?.recipe_id) return
  try {
    ingredientDialog.loading = true
    if (ingredientDialog.editing && payload.id) {
      const { error } = await supabase
        .from('mes_ingredients')
        .update({
          amount: payload.amount,
          uom_id: payload.uom_id,
          usage_stage: payload.usage_stage,
          notes: payload.notes,
        })
        .eq('id', payload.id)
      if (error) throw error
    } else {
      const tenant = await ensureTenant()
      const { error } = await supabase
        .from('mes_ingredients')
        .insert({
          tenant_id: tenant,
          recipe_id: batch.value.recipe_id,
          material_id: payload.material_id,
          amount: payload.amount,
          uom_id: payload.uom_id,
          usage_stage: payload.usage_stage,
          notes: payload.notes,
        })
      if (error) throw error
    }
    closeIngredientDialog()
    await loadIngredients(batch.value.recipe_id)
  } catch (err) {
    console.error(err)
  } finally {
    ingredientDialog.loading = false
  }
}

async function deleteIngredient(row: any) {
  if (!window.confirm(t('batch.ingredients.deleteConfirm', { name: row.material_label }))) return
  try {
    const { error } = await supabase.from('mes_ingredients').delete().eq('id', row.id)
    if (error) throw error
    await loadIngredients(batch.value?.recipe_id)
  } catch (err) {
    console.error(err)
  }
}

async function saveBatch() {
  if (!batchId.value) return
  try {
    savingBatch.value = true
    const meta = buildMetaWithLabel(batch.value?.meta, batchForm.batch_label)
    const trimmedBatchCode = batchForm.batch_code.trim()
    const trimmedBatchLabel = batchForm.batch_label.trim()
    const update: Record<string, any> = {
      batch_code: trimmedBatchCode || batch.value?.batch_code || null,
      status: batchForm.status || null,
      batch_label: trimmedBatchLabel || null,
      scale_factor: toNumber(batchForm.scale_factor),
      process_version: batchForm.process_version,
      planned_start: fromInputDateTime(batchForm.planned_start),
      planned_end: fromInputDateTime(batchForm.planned_end),
      actual_start: fromInputDateTime(batchForm.actual_start),
      actual_end: fromInputDateTime(batchForm.actual_end),
      kpi: buildKpiPayload(batchForm.kpi_rows),
      material_consumption: buildMaterialConsumptionPayload(batchForm.material_consumption_rows),
      output_actual: buildOutputPayload(batchForm.output_rows),
      notes: batchForm.notes || null,
      meta,
    }
    const { error } = await supabase
      .from('mes_batches')
      .update(update)
      .eq('id', batchId.value)
    if (error) throw error
    await fetchBatch()
  } catch (err) {
    console.error(err)
  } finally {
    savingBatch.value = false
  }
}

async function saveStep(step: any) {
  try {
    step.saving = true
    const parsedActual = parseJsonSafe(step.edit.actual_params)
    const { error } = await supabase
      .from('mes_batch_steps')
      .update({
        status: step.edit.status || null,
        actual_params: parsedActual,
        notes: step.edit.notes || null,
      })
      .eq('id', step.id)
    if (error) throw error
    step.saving = false
    await loadSteps()
  } catch (err) {
    console.error(err)
    step.saving = false
  }
}

function openPackageAdd() {
  packageDialog.open = true
  packageDialog.editing = false
  packageDialog.initial = {
    package_id: '',
    fill_at: new Date().toISOString().slice(0, 10),
    site_id: '',
    package_qty: 0,
    package_size_l: '',
    notes: '',
  }
}

function openPackageEdit(row: PackageRow) {
  packageDialog.open = true
  packageDialog.editing = true
  packageDialog.initial = {
    id: row.id,
    package_id: row.package_id,
    fill_at: row.fill_at ? row.fill_at : '',
    site_id: row.site_id ?? '',
    package_qty: row.package_qty,
    package_size_l: row.unit_volume_l != null ? String(row.unit_volume_l) : '',
    notes: row.notes ?? '',
  }
}

function closePackageDialog() {
  packageDialog.open = false
  packageDialog.initial = null
}

async function savePackage(payload: any) {
  if (!batchId.value) return
  try {
    packageDialog.loading = true
    const tenant = await ensureTenant()
    const litersUomId = findLitersUomId()
    if (!litersUomId) throw new Error('Liters UOM not found')

    const category = packageCategories.value.find((row) => row.id === payload.package_id)
    const unitVolume = payload.package_size_l !== '' ? Number(payload.package_size_l) : category?.default_volume_l ?? null
    const packageQty = Number(payload.package_qty) || 0
    const qtyLiters = unitVolume != null ? packageQty * unitVolume : 0
    const meta: Record<string, unknown> = {}
    if (payload.fill_at) meta.fill_at = payload.fill_at
    if (!Number.isNaN(packageQty)) meta.package_qty = packageQty
    if (unitVolume != null && !Number.isNaN(unitVolume)) meta.unit_volume_l = unitVolume

    const movement = await ensurePackagingMovement(payload.site_id || null, payload.fill_at || null)
    const linePayload = {
      tenant_id: tenant,
      movement_id: movement.id,
      package_id: payload.package_id,
      batch_id: batchId.value,
      qty: qtyLiters,
      uom_id: litersUomId,
      notes: payload.notes ? payload.notes.trim() : null,
      meta: Object.keys(meta).length ? meta : null,
    }

    if (packageDialog.editing && payload.id) {
      const existing = packages.value.find((row) => row.id === payload.id)
      if (existing && existing.movement_id !== movement.id) {
        const { error } = await supabase.from('inv_movement_lines').delete().eq('id', payload.id)
        if (error) throw error
        const lineNo = await nextPackagingLineNo(movement.id)
        const { error: insertError } = await supabase.from('inv_movement_lines').insert({ ...linePayload, line_no: lineNo })
        if (insertError) throw insertError
        await cleanupEmptyMovement(existing.movement_id)
      } else {
        const { error } = await supabase.from('inv_movement_lines').update(linePayload).eq('id', payload.id)
        if (error) throw error
      }
    } else {
      const lineNo = await nextPackagingLineNo(movement.id)
      const { error } = await supabase.from('inv_movement_lines').insert({ ...linePayload, line_no: lineNo })
      if (error) throw error
    }
    closePackageDialog()
    await loadPackages(batchId.value)
  } catch (err) {
    console.error(err)
  } finally {
    packageDialog.loading = false
  }
}

async function deletePackage(row: PackageRow) {
  if (!window.confirm(t('batch.packaging.confirmDelete'))) return
  try {
    const { error } = await supabase.from('inv_movement_lines').delete().eq('id', row.id)
    if (error) throw error
    await cleanupEmptyMovement(row.movement_id)
    await loadPackages(batchId.value)
  } catch (err) {
    console.error(err)
  }
}

async function savePackagingMovement() {
  try {
    savingPackaging.value = true
    if (batchId.value) {
      await loadPackages(batchId.value)
    }
  } catch (err) {
    console.error(err)
  } finally {
    savingPackaging.value = false
  }
}

function nowInputDateTime() {
  return toInputDateTime(new Date().toISOString())
}

function newPackingForm(type: PackingType): PackingFormState {
  return {
    packing_type: type,
    event_time: nowInputDateTime(),
    memo: '',
    volume_qty: '',
    movement_site_id: '',
    movement_qty: '',
    movement_memo: '',
    filling_lines: [],
    reason: '',
  }
}

function normalizePackingEvents(value: unknown): PackingEvent[] {
  if (!Array.isArray(value)) return []
  return value
    .map((item) => {
      if (!item || typeof item !== 'object' || Array.isArray(item)) return null
      const raw = item as Record<string, unknown>
      const type = String(raw.packing_type ?? '').trim() as PackingType
      if (!type) return null
      const eventTime = String(raw.event_time ?? '').trim()
      return {
        id: String(raw.id ?? generateLocalId()),
        packing_type: type,
        event_time: eventTime || new Date().toISOString(),
        memo: raw.memo != null ? String(raw.memo) : null,
        volume_qty: toNumber(raw.volume_qty),
        volume_uom: raw.volume_uom != null ? String(raw.volume_uom) : 'L',
        movement: raw.movement && typeof raw.movement === 'object' ? {
          site_id: (raw.movement as any).site_id != null ? String((raw.movement as any).site_id) : null,
          qty: toNumber((raw.movement as any).qty),
          memo: (raw.movement as any).memo != null ? String((raw.movement as any).memo) : null,
        } : null,
        filling_lines: Array.isArray(raw.filling_lines)
          ? (raw.filling_lines as any[]).map((line) => ({
            id: String(line?.id ?? generateLocalId()),
            package_type_id: String(line?.package_type_id ?? ''),
            qty: toNumber(line?.qty) ?? 0,
          }))
          : [],
        reason: raw.reason != null ? String(raw.reason) : null,
      }
    })
    .filter((row): row is PackingEvent => row !== null)
}

function generateLocalId() {
  return `local-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`
}

function openPackingDialog() {
  packingDialog.open = true
  packingDialog.editing = false
  packingDialog.loading = false
  packingDialog.globalError = ''
  packingDialog.errors = {}
  packingDialog.form = newPackingForm('ship')
  packingMovementQtyTouched.value = false
}

function openPackingEdit(event: PackingEvent) {
  packingDialog.open = true
  packingDialog.editing = true
  packingDialog.loading = false
  packingDialog.globalError = ''
  packingDialog.errors = {}
  packingDialog.form = {
    id: event.id,
    packing_type: event.packing_type,
    event_time: toInputDateTime(event.event_time),
    memo: event.memo ?? '',
    volume_qty: event.volume_qty != null ? String(event.volume_qty) : '',
    movement_site_id: event.movement?.site_id ?? '',
    movement_qty: event.movement?.qty != null ? String(event.movement.qty) : '',
    movement_memo: event.movement?.memo ?? '',
    filling_lines: event.filling_lines.map((line) => ({
      id: line.id ?? generateLocalId(),
      package_type_id: line.package_type_id,
      qty: String(line.qty ?? ''),
    })),
    reason: event.reason ?? '',
  }
  packingMovementQtyTouched.value = true
}

function closePackingDialog() {
  if (!packingDialog.form) {
    packingDialog.open = false
    return
  }
  if (isPackingFormDirty(packingDialog.form)) {
    if (!window.confirm(t('batch.packaging.dialog.closeConfirm'))) return
  }
  packingDialog.open = false
  packingDialog.form = null
  packingDialog.errors = {}
  packingDialog.globalError = ''
}

function isPackingFormDirty(form: PackingFormState) {
  return Boolean(
    form.memo ||
    form.volume_qty ||
    form.movement_site_id ||
    form.movement_qty ||
    form.movement_memo ||
    form.reason ||
    (form.filling_lines && form.filling_lines.length)
  )
}

function selectPackingType(value: PackingType) {
  if (!packingDialog.form) return
  if (packingDialog.form.packing_type === value) return
  if (shouldConfirmPackingTypeChange(packingDialog.form, value)) {
    if (!window.confirm(t('batch.packaging.dialog.typeChangeConfirm'))) return
  }
  const prevType = packingDialog.form.packing_type
  packingDialog.form.packing_type = value
  resetPackingFormForType(packingDialog.form, prevType)
  packingMovementQtyTouched.value = false
}

function shouldConfirmPackingTypeChange(form: PackingFormState, next: PackingType) {
  const wasFilling = form.packing_type === 'filling'
  const willBeFilling = next === 'filling'
  if (wasFilling && !willBeFilling && form.filling_lines.length) return true
  const wasVolume = isVolumeType(form.packing_type)
  const willVolume = isVolumeType(next)
  if (wasVolume && !willVolume && form.volume_qty) return true
  const wasMovement = isMovementType(form.packing_type)
  const willMovement = isMovementType(next)
  if (wasMovement && !willMovement && (form.movement_site_id || form.movement_qty || form.movement_memo)) return true
  if ((form.packing_type === 'loss' || form.packing_type === 'dispose') && !(next === 'loss' || next === 'dispose') && form.reason) return true
  return false
}

function resetPackingFormForType(form: PackingFormState, prevType: PackingType) {
  if (!isVolumeType(form.packing_type) || !isVolumeType(prevType)) {
    form.volume_qty = ''
  }
  if (!isMovementType(form.packing_type) || !isMovementType(prevType)) {
    form.movement_site_id = ''
    form.movement_qty = ''
    form.movement_memo = ''
  }
  if (form.packing_type !== 'filling') {
    form.filling_lines = []
  }
  if (!(form.packing_type === 'loss' || form.packing_type === 'dispose')) {
    form.reason = ''
  }
}

function isVolumeType(type: PackingType) {
  return type === 'ship' || type === 'transfer' || type === 'loss' || type === 'dispose'
}

function isMovementType(type: PackingType) {
  return type === 'ship' || type === 'filling' || type === 'transfer'
}

function addFillingLine() {
  if (!packingDialog.form) return
  packingDialog.form.filling_lines.push({
    id: generateLocalId(),
    package_type_id: '',
    qty: '',
  })
}

function removeFillingLine(index: number) {
  if (!packingDialog.form) return
  packingDialog.form.filling_lines.splice(index, 1)
}

function markMovementQtyTouched() {
  packingMovementQtyTouched.value = true
}

async function savePackingEvent(addAnother: boolean) {
  if (!packingDialog.form || !batchId.value) return
  packingDialog.errors = {}
  packingDialog.globalError = ''
  const errors = validatePackingForm(packingDialog.form)
  if (Object.keys(errors).length) {
    packingDialog.errors = errors
    return
  }
  try {
    packingDialog.loading = true
    const nextEvent = buildPackingEvent(packingDialog.form)
    if (packingDialog.editing && packingDialog.form.id) {
      const idx = packingEvents.value.findIndex((row) => row.id === packingDialog.form?.id)
      if (idx >= 0) {
        packingEvents.value.splice(idx, 1, nextEvent)
      } else {
        packingEvents.value.unshift(nextEvent)
      }
    } else {
      packingEvents.value.unshift(nextEvent)
    }
    await persistPackingEvents()
    showPackingNotice(t('batch.packaging.toast.saved'))
    if (addAnother) {
      const nextType = packingDialog.form.packing_type
      packingDialog.form = newPackingForm(nextType)
      packingDialog.editing = false
      packingMovementQtyTouched.value = false
    } else {
      packingDialog.open = false
      packingDialog.form = null
    }
  } catch (err) {
    console.error(err)
    packingDialog.globalError = t('batch.packaging.errors.saveFailed')
  } finally {
    packingDialog.loading = false
  }
}

async function deletePackingEvent(event: PackingEvent) {
  if (!window.confirm(t('batch.packaging.confirmDelete'))) return
  try {
    packingEvents.value = packingEvents.value.filter((row) => row.id !== event.id)
    await persistPackingEvents()
    showPackingNotice(t('batch.packaging.toast.deleted'))
  } catch (err) {
    console.error(err)
    packingDialog.globalError = t('batch.packaging.errors.deleteFailed')
  }
}

async function persistPackingEvents() {
  if (!batchId.value) return
  const base = buildMetaWithLabel(batch.value?.meta, batchForm.batch_label)
  const nextMeta = { ...base, packing_events: packingEvents.value }
  const { error } = await supabase
    .from('mes_batches')
    .update({ meta: nextMeta })
    .eq('id', batchId.value)
  if (error) throw error
  if (batch.value) {
    batch.value = { ...batch.value, meta: nextMeta }
  }
}

function validatePackingForm(form: PackingFormState) {
  const errors: Record<string, string> = {}
  if (!form.packing_type) errors.packing_type = t('batch.packaging.errors.typeRequired')
  if (!form.event_time) errors.event_time = t('batch.packaging.errors.eventTimeRequired')
  if (isVolumeType(form.packing_type)) {
    const qty = toNumber(form.volume_qty)
    if (qty == null || qty <= 0) errors.volume_qty = t('batch.packaging.errors.volumeRequired')
  }
  if (isMovementType(form.packing_type)) {
    if (!form.movement_site_id) errors.movement_site_id = t('batch.packaging.errors.siteRequired')
    const qty = toNumber(form.movement_qty)
    if (qty == null || qty <= 0) errors.movement_qty = t('batch.packaging.errors.movementQtyRequired')
  }
  if (form.packing_type === 'filling') {
    if (!form.filling_lines.length) {
      errors.filling_lines = t('batch.packaging.errors.fillingRequired')
    } else {
      const invalid = form.filling_lines.some((line) => {
        const qty = toNumber(line.qty)
        return !line.package_type_id || qty == null || qty < 1 || !Number.isInteger(qty)
      })
      if (invalid) errors.filling_lines = t('batch.packaging.errors.fillingLineInvalid')
    }
  }
  return errors
}

function buildPackingEvent(form: PackingFormState): PackingEvent {
  const id = form.id ?? generateLocalId()
  const volumeQty = isVolumeType(form.packing_type) ? toNumber(form.volume_qty) : null
  const movement = isMovementType(form.packing_type)
    ? {
      site_id: form.movement_site_id || null,
      qty: toNumber(form.movement_qty),
      memo: form.movement_memo ? form.movement_memo.trim() : null,
    }
    : null
  const fillingLines = form.packing_type === 'filling'
    ? form.filling_lines.map((line) => ({
      id: line.id ?? generateLocalId(),
      package_type_id: line.package_type_id,
      qty: toNumber(line.qty) ?? 0,
    }))
    : []
  return {
    id,
    packing_type: form.packing_type,
    event_time: fromInputDateTime(form.event_time) ?? new Date().toISOString(),
    memo: form.memo ? form.memo.trim() : null,
    volume_qty: volumeQty,
    volume_uom: volumeQty != null ? 'L' : null,
    movement,
    filling_lines: fillingLines,
    reason: form.reason ? form.reason.trim() : null,
  }
}

function computeFillingTotals(lines: PackingFillingLineForm[]) {
  let totalUnits = 0
  let totalVolume = 0
  let hasMissing = false
  lines.forEach((line) => {
    const qty = toNumber(line.qty)
    if (qty == null) return
    totalUnits += qty
    const unitVolume = resolvePackageUnitVolume(line.package_type_id)
    if (unitVolume == null) {
      hasMissing = true
      return
    }
    totalVolume += qty * unitVolume
  })
  return {
    totalUnits,
    totalVolume: hasMissing ? null : totalVolume,
  }
}

function resolvePackageUnitVolume(packageTypeId: string) {
  const row = packageCategories.value.find((item) => item.id === packageTypeId)
  return row?.default_volume_l ?? null
}

function formatFillingUnitVolume(packageTypeId: string) {
  const unit = resolvePackageUnitVolume(packageTypeId)
  return unit != null ? formatVolumeValue(unit) : '—'
}

function formatFillingLineTotal(line: PackingFillingLineForm) {
  const qty = toNumber(line.qty)
  const unit = resolvePackageUnitVolume(line.package_type_id)
  if (qty == null || unit == null) return '—'
  return formatVolumeValue(qty * unit)
}

function formatFillingTotals(totals: { totalUnits: number, totalVolume: number | null }) {
  const volumeLabel = totals.totalVolume != null ? formatVolumeValue(totals.totalVolume) : '—'
  return t('batch.packaging.dialog.fillingTotals.summary', { units: totals.totalUnits, volume: volumeLabel })
}

function formatPackingType(type: PackingType) {
  const match = packingTypeOptions.value.find((option) => option.value === type)
  return match?.label ?? type
}

function formatPackingDate(value: string) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
  } catch {
    return value
  }
}

function formatPackingVolume(event: PackingEvent) {
  if (event.volume_qty == null) return '—'
  return formatVolumeValue(event.volume_qty)
}

function formatPackingMovement(event: PackingEvent) {
  if (!event.movement) return '—'
  const site = siteLabel(event.movement.site_id)
  const qty = event.movement.qty != null ? formatVolumeValue(event.movement.qty) : '—'
  return `${site} / ${qty}`
}

function formatPackingFilling(event: PackingEvent) {
  if (!event.filling_lines.length) return '—'
  let totalUnits = 0
  let totalVolume = 0
  let hasMissing = false
  event.filling_lines.forEach((line) => {
    totalUnits += line.qty ?? 0
    const unit = resolvePackageUnitVolume(line.package_type_id)
    if (unit == null) {
      hasMissing = true
      return
    }
    totalVolume += line.qty * unit
  })
  const volumeLabel = hasMissing ? '—' : formatVolumeValue(totalVolume)
  return `${totalUnits} / ${volumeLabel}`
}

function showPackingNotice(message: string) {
  packingNotice.value = message
  window.setTimeout(() => {
    if (packingNotice.value === message) packingNotice.value = ''
  }, 3000)
}

watch(
  () => [packingDialog.form?.volume_qty, packingDialog.form?.packing_type],
  () => {
    if (!packingDialog.form || !showPackingMovementSection.value) return
    if (packingMovementQtyTouched.value) return
    if (packingDialog.form.packing_type === 'ship' || packingDialog.form.packing_type === 'transfer') {
      packingDialog.form.movement_qty = packingDialog.form.volume_qty || ''
    }
  }
)

watch(
  () => packingFillingTotals.value.totalVolume,
  (total) => {
    if (!packingDialog.form || packingDialog.form.packing_type !== 'filling') return
    if (packingMovementQtyTouched.value) return
    if (total == null) return
    packingDialog.form.movement_qty = String(total)
  }
)

function summariseJson(value: any) {
  if (!value) return '—'
  try {
    if (typeof value === 'string') {
      const obj = JSON.parse(value)
      return Object.entries(obj).map(([k, v]) => `${k}: ${v}`).join('\n')
    }
    if (typeof value === 'object') {
      return Object.entries(value).map(([k, v]) => `${k}: ${v}`).join('\n')
    }
  } catch (err) {
    console.error(err)
  }
  return String(value)
}

function stringifyJson(value: any) {
  if (!value) return ''
  try {
    return typeof value === 'string' ? value : JSON.stringify(value)
  } catch {
    return ''
  }
}

function parseJsonSafe(value: string) {
  if (!value) return null
  try {
    return JSON.parse(value)
  } catch {
    return value
  }
}

function formatQuantity(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  try {
    return Number(value).toLocaleString(undefined, { maximumFractionDigits: 2 })
  } catch {
    return String(value)
  }
}

function convertToLiters(size: number | null | undefined, uomCode: string | null | undefined) {
  if (size == null || Number.isNaN(Number(size))) return null
  if (!uomCode) return Number(size)
  switch (uomCode) {
    case 'L':
      return Number(size)
    case 'mL':
      return Number(size) / 1000
    case 'gal_us':
      return Number(size) * 3.78541
    default:
      return Number(size)
  }
}

function formatVolumeValue(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  const display = Number(value)
  return `${display.toLocaleString(undefined, { maximumFractionDigits: 2 })} L`
}

function toInputDateTime(value: string | null | undefined) {
  if (!value) return ''
  try {
    const d = new Date(value)
    const pad = (n: number) => String(n).padStart(2, '0')
    const yyyy = d.getFullYear()
    const mm = pad(d.getMonth() + 1)
    const dd = pad(d.getDate())
    const hh = pad(d.getHours())
    const mi = pad(d.getMinutes())
    return `${yyyy}-${mm}-${dd}T${hh}:${mi}`
  } catch {
    return ''
  }
}

function fromInputDateTime(value: string) {
  if (!value) return null
  try {
    return new Date(value).toISOString()
  } catch {
    return value
  }
}

onMounted(async () => {
  try {
    await ensureTenant()
    await Promise.all([loadKpiMeta(), loadMaterialClasses(), loadBatchOptions(), loadBatchStatusOptions()])
    await fetchPackageCategories()
  } catch (err) {
    console.error(err)
  }
})
</script>
