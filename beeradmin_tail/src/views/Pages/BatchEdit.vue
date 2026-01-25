<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div v-if="loadingBatch" class="p-6 text-sm text-gray-500">{{ t('common.loading') }}</div>
    <div v-else-if="!batch" class="p-6 text-sm text-red-600">{{ t('batch.edit.notFound') }}</div>
    <div v-else class="space-y-6">
      <!-- Batch Information -->
      <section class="bg-white rounded-xl shadow border border-gray-200 p-5">
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
            <input id="batchStatus" v-model.trim="batchForm.status" type="text" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchLabel">{{ t('batch.edit.label') }}</label>
            <input id="batchLabel" v-model.trim="batchForm.label" type="text" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchPlannedStart">{{ t('batch.edit.plannedStart') }}</label>
            <input id="batchPlannedStart" v-model="batchForm.planned_start" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
          </div>
          <!-- <div>
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
          </div> -->
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchTargetVolume">{{ t('batch.edit.targetVolume') }}</label>
            <input id="batchTargetVolume" v-model.number="batchForm.target_volume_l" type="number" min="0" step="0.01" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div class="lg:col-span-3">
            <label class="block text-sm text-gray-600 mb-1" for="batchNotes">{{ t('batch.edit.notes') }}</label>
            <textarea id="batchNotes" v-model.trim="batchForm.notes" rows="3" class="w-full border rounded px-3 py-2"></textarea>
          </div>
          <div class="lg:col-span-3 space-y-2">
            <div class="flex items-center justify-between">
              <div>
                <p class="text-sm font-semibold text-gray-700">{{ t('batch.edit.parentBatchesTitle') }}</p>
                <p class="text-xs text-gray-500">{{ t('batch.edit.parentBatchesSubtitle') }}</p>
              </div>
              <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="addParentBatch">{{ t('batch.edit.parentBatchesAdd') }}</button>
            </div>
            <div v-if="batchForm.parent_batches.length === 0" class="text-xs text-gray-500">{{ t('batch.edit.parentBatchesEmpty') }}</div>
            <div v-for="(row, index) in batchForm.parent_batches" :key="`parent-${index}`" class="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div class="md:col-span-2">
                <label class="block text-sm text-gray-600 mb-1" :for="`editParentBatchCode-${index}`">{{ t('batch.edit.parentBatchCode') }}</label>
                <input :id="`editParentBatchCode-${index}`" v-model.trim="row.batch_code" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1" :for="`editParentBatchQty-${index}`">{{ t('batch.edit.parentBatchQuantity') }}</label>
                <input :id="`editParentBatchQty-${index}`" v-model="row.quantity_liters" type="number" min="0" step="0.01" class="w-full h-[40px] border rounded px-3" />
              </div>
              <div class="md:col-span-3 flex justify-end">
                <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="removeParentBatch(index)">{{ t('batch.edit.parentBatchesRemove') }}</button>
              </div>
            </div>
          </div>
        </form>
      </section>

      <section class="bg-white rounded-xl shadow border border-gray-200 p-5">
        <header class="flex items-center justify-between mb-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.edit.actualTitle') }}</h2>
            <p class="text-xs text-gray-500">{{ t('batch.edit.actualSubtitle') }}</p>
          </div>
          <button class="px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="savingBatch" @click="saveBatch">
            {{ savingBatch ? t('common.saving') : t('common.save') }}
          </button>
        </header>
        <form class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4" @submit.prevent>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchActualProductVolume">{{ t('batch.edit.actualProductVolume') }}</label>
            <input id="batchActualProductVolume" v-model.trim="batchForm.actual_product_volume" type="number" min="0" step="0.01" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchActualOg">{{ t('batch.edit.actualOg') }}</label>
            <input id="batchActualOg" v-model.trim="batchForm.actual_og" type="number" min="0" step="0.001" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchActualFg">{{ t('batch.edit.actualFg') }}</label>
            <input id="batchActualFg" v-model.trim="batchForm.actual_fg" type="number" min="0" step="0.001" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchActualAbv">{{ t('batch.edit.actualAbv') }}</label>
            <input id="batchActualAbv" v-model.trim="batchForm.actual_abv" type="number" min="0" step="0.01" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchActualSrm">{{ t('batch.edit.actualSrm') }}</label>
            <input id="batchActualSrm" v-model.trim="batchForm.actual_srm" type="number" min="0" step="0.1" class="w-full h-[40px] border rounded px-3" />
          </div>
        </form>
      </section>

      <!-- Ingredients -->
      <section v-if="false" class="bg-white rounded-xl shadow border border-gray-200 p-5">
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
      <section class="bg-white rounded-xl shadow border border-gray-200 p-5">
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
            <span v-if="packagesLoading" class="text-sm text-gray-500">{{ t('common.loading') }}</span>
            <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-50" type="button" :disabled="packagesLoading || savingPackaging" @click="savePackagingMovement">
              {{ savingPackaging ? t('common.saving') : t('common.save') }}
            </button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="packagesLoading" @click="openPackageAdd">{{ t('batch.packaging.addButton') }}</button>
          </div>
        </header>

        <div v-show="!sectionCollapsed.packaging" class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4">
          <div class="border border-dashed border-gray-300 rounded-lg p-3 bg-gray-50">
            <p class="text-xs uppercase text-gray-500">{{ t('batch.packaging.summaryTotalProduct') }}</p>
            <p class="text-lg font-semibold text-gray-800">{{ formatVolumeValue(totalProductVolume) }}</p>
          </div>
          <div class="border border-dashed border-gray-300 rounded-lg p-3 bg-gray-50">
            <p class="text-xs uppercase text-gray-500">{{ t('batch.packaging.summaryFilled') }}</p>
            <p class="text-lg font-semibold text-gray-800">{{ formatVolumeValue(totalFilledVolume) }}</p>
          </div>
          <div class="border border-dashed border-gray-300 rounded-lg p-3 bg-gray-50">
            <p class="text-xs uppercase text-gray-500">{{ t('batch.packaging.summaryRemaining') }}</p>
            <p class="text-lg font-semibold text-gray-800">{{ formatVolumeValue(remainingVolume) }}</p>
          </div>
        </div>

        <div v-show="!sectionCollapsed.packaging" class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full text-sm divide-y divide-gray-200">
            <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.fillDate') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.package') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.outputSite') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.packaging.columns.quantity') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.packaging.columns.unitSize') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.packaging.columns.totalVolume') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.notes') }}</th>
                <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="pkg in packages" :key="pkg.id" class="hover:bg-gray-50">
                <td class="px-3 py-2 text-gray-600">{{ pkg.fill_at ? new Date(pkg.fill_at).toLocaleDateString() : '—' }}</td>
                <td class="px-3 py-2">
                  <div class="font-medium text-gray-800">{{ pkg.package_label }}</div>
                  <div class="text-xs text-gray-500">{{ pkg.package_code }}</div>
                </td>
                <td class="px-3 py-2 text-gray-600">{{ siteLabel(pkg.site_id) }}</td>
                <td class="px-3 py-2 text-right">{{ pkg.package_qty.toLocaleString() }}</td>
                <td class="px-3 py-2 text-right">{{ formatVolumeValue(pkg.unit_volume_l) }}</td>
                <td class="px-3 py-2 text-right font-semibold text-gray-800">{{ formatVolumeValue(pkg.total_volume_l) }}</td>
                <td class="px-3 py-2 text-sm text-gray-600 whitespace-pre-wrap">{{ pkg.notes || '—' }}</td>
                <td class="px-3 py-2 space-x-2">
                  <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" type="button" @click="openPackageEdit(pkg)">{{ t('common.edit') }}</button>
                  <button class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700" type="button" @click="deletePackage(pkg)">{{ t('common.delete') }}</button>
                </td>
              </tr>
              <tr v-if="!packagesLoading && packages.length === 0">
                <td class="px-3 py-6 text-center text-gray-500" colspan="8">{{ t('batch.packaging.noData') }}</td>
              </tr>
              <tr v-if="packagesLoading">
                <td class="px-3 py-6 text-center text-gray-500" colspan="8">{{ t('common.loading') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <!-- Yeast Starter Maintenance -->
      <section class="bg-white rounded-xl shadow border border-gray-200 p-5">
        <header class="flex items-center justify-between mb-4">
          <div class="flex items-center gap-3">
            <button class="px-2 py-1 text-xs rounded border border-gray-300 hover:bg-gray-100" type="button" @click="toggleSection('yeast')">
              {{ collapseLabel(sectionCollapsed.yeast) }}
            </button>
            <div>
              <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.yeast.sectionTitle') }}</h2>
              <p class="text-xs text-gray-500">{{ t('batch.yeast.sectionSubtitle') }}</p>
            </div>
          </div>
          <div class="text-sm text-gray-500" v-if="yeastLoading">{{ t('common.loading') }}</div>
        </header>

        <div v-show="!sectionCollapsed.yeast" class="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4">
          <div class="border border-dashed border-gray-300 rounded-lg p-3 bg-gray-50">
            <p class="text-xs uppercase text-gray-500">{{ t('batch.yeast.totalPulled') }}</p>
            <p class="text-lg font-semibold text-gray-800">{{ formatQuantity(yeastTotals.totalPulled) }}</p>
          </div>
          <div class="border border-dashed border-gray-300 rounded-lg p-3 bg-gray-50">
            <p class="text-xs uppercase text-gray-500">{{ t('batch.yeast.totalReturned') }}</p>
            <p class="text-lg font-semibold text-gray-800">{{ formatQuantity(yeastTotals.totalReturned) }}</p>
          </div>
          <div class="border border-dashed border-gray-300 rounded-lg p-3 bg-gray-50">
            <p class="text-xs uppercase text-gray-500">{{ t('batch.yeast.totalDumped') }}</p>
            <p class="text-lg font-semibold text-gray-800">{{ formatQuantity(yeastTotals.totalDumped) }}</p>
          </div>
        </div>

        <div v-show="!sectionCollapsed.yeast" class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full text-sm divide-y divide-gray-200">
            <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('batch.yeast.colTimestamp') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.yeast.colSourceBatch') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.yeast.colTankFrom') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.yeast.colTankTo') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.yeast.colVolumePulled') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.yeast.colVolumeReturned') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.yeast.colVolumeDumped') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.yeast.colNotes') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="movement in yeastMovements" :key="movement.id" class="hover:bg-gray-50">
                <td class="px-3 py-2 text-gray-600">{{ fmtDateTime(movement.recorded_at) }}</td>
                <td class="px-3 py-2">
                  <div class="font-medium text-gray-800">{{ movement.source_batch_code || '—' }}</div>
                  <div v-if="movement.source_batch_id" class="text-xs text-gray-500">{{ movement.source_batch_id }}</div>
                </td>
                <td class="px-3 py-2 text-gray-600">{{ movement.from_tank || '—' }}</td>
                <td class="px-3 py-2 text-gray-600">{{ movement.to_tank || '—' }}</td>
                <td class="px-3 py-2 text-right">{{ formatQuantity(movement.volume_out) }}</td>
                <td class="px-3 py-2 text-right">{{ formatQuantity(movement.volume_in) }}</td>
                <td class="px-3 py-2 text-right">{{ formatQuantity(movement.volume_dumped) }}</td>
                <td class="px-3 py-2 text-gray-600 whitespace-pre-wrap">{{ movement.notes || '—' }}</td>
              </tr>
              <tr v-if="!yeastLoading && yeastMovements.length === 0">
                <td class="px-3 py-6 text-center text-gray-500" colspan="8">{{ t('batch.yeast.noData') }}</td>
              </tr>
              <tr v-if="yeastLoading">
                <td class="px-3 py-6 text-center text-gray-500" colspan="8">{{ t('common.loading') }}</td>
              </tr>
            </tbody>
          </table>
        </div>

        <p class="mt-3 text-xs text-gray-400">{{ t('batch.yeast.todoHint') }}</p>
      </section>

      <!-- Steps -->
      <section class="bg-white rounded-xl shadow border border-gray-200 p-5">
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

    <BatchIngredientDialog :open="ingredientDialog.open" :editing="ingredientDialog.editing" :loading="ingredientDialog.loading" :materials="materials" :uoms="uoms" :initial="ingredientDialog.initial" @close="closeIngredientDialog" @submit="saveIngredient" />
    <BatchPackageDialog :open="packageDialog.open" :editing="packageDialog.editing" :loading="packageDialog.loading" :categories="packageCategories" :sites="siteOptions" :initial="packageDialog.initial" @close="closePackageDialog" @submit="savePackage" />
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
import BatchPackageDialog from '@/views/Pages/components/BatchPackageDialog.vue'

const route = useRoute()
const { t } = useI18n()

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
  label: '',
  process_version: null as number | null,
  planned_start: '',
  // planned_end: '',
  // actual_start: '',
  // actual_end: '',
  target_volume_l: null as number | null,
  actual_product_volume: '',
  actual_og: '',
  actual_fg: '',
  actual_abv: '',
  actual_srm: '',
  vessel_id: '',
  notes: '',
  parent_batches: [] as ParentBatchFormRow[],
})

type ParentBatchFormRow = {
  batch_code: string
  quantity_liters: string
}

type ParentBatchMeta = {
  batch_code: string
  quantity_liters: number
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

const sectionCollapsed = reactive({
  ingredients: false,
  packaging: false,
  yeast: false,
  steps: false,
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

const steps = ref<Array<any>>([])
const stepsLoading = ref(false)

interface YeastMovementRow {
  id: string
  recorded_at: string | null
  source_batch_id: string | null
  source_batch_code: string | null
  from_tank: string | null
  to_tank: string | null
  volume_in: number | null
  volume_out: number | null
  volume_dumped: number | null
  notes: string | null
}

const yeastMovements = ref<YeastMovementRow[]>([])
const yeastLoading = ref(false)

const yeastTotals = computed(() => {
  const totals = { totalPulled: 0, totalReturned: 0, totalDumped: 0 }
  for (const row of yeastMovements.value) {
    totals.totalPulled += row.volume_out ?? 0
    totals.totalReturned += row.volume_in ?? 0
    totals.totalDumped += row.volume_dumped ?? 0
  }
  return totals
})

const totalFilledVolume = computed(() => {
  return packages.value.reduce((sum, row) => sum + row.total_volume_l, 0)
})

const totalProductVolume = computed(() => {
  const actual = numberOrNull(batchForm.actual_product_volume)
  if (actual != null) return actual
  const target = batchForm.target_volume_l
  if (target == null || Number.isNaN(Number(target))) return null
  return Number(target)
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

function siteLabel(siteId?: string | null) {
  if (!siteId) return '—'
  return siteOptionMap.value.get(siteId) ?? '—'
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

function resolveParentBatches(meta: unknown) {
  if (!meta || typeof meta !== 'object' || Array.isArray(meta)) return []
  const raw = (meta as Record<string, unknown>).parent_batches
  if (!Array.isArray(raw)) return []
  return raw
    .map((row) => {
      if (!row || typeof row !== 'object' || Array.isArray(row)) return null
      const code = String((row as Record<string, unknown>).batch_code ?? '').trim()
      const qty = Number((row as Record<string, unknown>).quantity_liters)
      if (!code || Number.isNaN(qty)) return null
      return { batch_code: code, quantity_liters: String(qty) }
    })
    .filter((row): row is ParentBatchFormRow => row !== null)
}

function numberOrNull(value: string) {
  if (value === null || value === undefined || value === '') return null
  const num = Number(value)
  return Number.isNaN(num) ? null : num
}

function toNumber(value: any): number | null {
  if (value === null || value === undefined || value === '') return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function normalizeParentBatches(rows: ParentBatchFormRow[]) {
  if (!rows.length) return null
  const cleaned = rows
    .map((row) => {
      const code = row.batch_code.trim()
      if (!code) return null
      const qty = Number(row.quantity_liters)
      if (!Number.isFinite(qty) || qty <= 0) return null
      return { batch_code: code, quantity_liters: qty }
    })
    .filter((row): row is ParentBatchMeta => row !== null)
  return cleaned.length ? cleaned : null
}

function buildMetaWithLabel(meta: unknown, label: string, actualProductVolume: string, parentBatches: ParentBatchMeta[] | null) {
  const base = (meta && typeof meta === 'object' && !Array.isArray(meta))
    ? { ...(meta as Record<string, unknown>) }
    : {}
  const trimmed = label.trim()
  if (trimmed) {
    base.label = trimmed
  } else {
    delete base.label
  }
  const volume = numberOrNull(actualProductVolume)
  if (volume == null) {
    delete base.actual_product_volume
  } else {
    base.actual_product_volume = volume
  }
  if (!parentBatches || parentBatches.length === 0) {
    delete base.parent_batches
  } else {
    base.parent_batches = parentBatches
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

function addParentBatch() {
  batchForm.parent_batches.push({ batch_code: '', quantity_liters: '' })
}

function removeParentBatch(index: number) {
  batchForm.parent_batches.splice(index, 1)
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
      batchForm.label = resolveMetaLabel(data.meta) ?? ''
      const actualVolume = resolveMetaNumber(data.meta, 'actual_product_volume')
      batchForm.actual_product_volume = actualVolume != null ? String(actualVolume) : ''
      batchForm.parent_batches = resolveParentBatches(data.meta)
      batchForm.process_version = data.process_version ?? null
      batchForm.planned_start = toInputDateTime(data.planned_start)
      // batchForm.planned_end = toInputDateTime(data.planned_end)
      // batchForm.actual_start = toInputDateTime(data.actual_start)
      // batchForm.actual_end = toInputDateTime(data.actual_end)
      batchForm.target_volume_l = data.target_volume_l ?? null
      batchForm.actual_og = data.actual_og != null ? String(data.actual_og) : ''
      batchForm.actual_fg = data.actual_fg != null ? String(data.actual_fg) : ''
      batchForm.actual_abv = data.actual_abv != null ? String(data.actual_abv) : ''
      batchForm.actual_srm = data.actual_srm != null ? String(data.actual_srm) : ''
      batchForm.vessel_id = data.vessel_id ?? ''
      batchForm.notes = data.notes ?? ''
      await Promise.all([
        loadIngredients(data.recipe_id),
        loadSteps(),
        loadMaterialsAndUoms(),
        loadSites(),
        loadYeastMovements(data.id),
        loadPackages(data.id),
      ])
    } else {
      ingredients.value = []
      steps.value = []
      yeastMovements.value = []
      packages.value = []
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

async function loadYeastMovements(targetBatchId: string | undefined) {
  yeastMovements.value = []
  if (!targetBatchId) return
  try {
    yeastLoading.value = true
    // TODO: Replace with Supabase query once yeast starter movements are stored server-side.
    yeastMovements.value = []
  } catch (err) {
    console.error(err)
  } finally {
    yeastLoading.value = false
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
    const parentBatches = normalizeParentBatches(batchForm.parent_batches)
    const meta = buildMetaWithLabel(batch.value?.meta, batchForm.label, batchForm.actual_product_volume, parentBatches)
    const trimmedBatchCode = batchForm.batch_code.trim()
    const update: Record<string, any> = {
      batch_code: trimmedBatchCode || batch.value?.batch_code || null,
      status: batchForm.status || null,
      process_version: batchForm.process_version,
      planned_start: fromInputDateTime(batchForm.planned_start),
      // planned_end: fromInputDateTime(batchForm.planned_end),
      // actual_start: fromInputDateTime(batchForm.actual_start),
      // actual_end: fromInputDateTime(batchForm.actual_end),
      target_volume_l: batchForm.target_volume_l,
      actual_og: numberOrNull(batchForm.actual_og),
      actual_fg: numberOrNull(batchForm.actual_fg),
      actual_abv: numberOrNull(batchForm.actual_abv),
      actual_srm: numberOrNull(batchForm.actual_srm),
      vessel_id: batchForm.vessel_id || null,
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
  if (!window.confirm(t('batch.packaging.deleteConfirm', { code: row.package_code }))) return
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
    await fetchPackageCategories()
  } catch (err) {
    console.error(err)
  }
})
</script>
