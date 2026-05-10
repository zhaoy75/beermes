<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div v-if="loadingBatch" class="p-6 text-sm text-gray-500">{{ t('common.loading') }}</div>
    <div v-else-if="!batch" class="p-6 text-sm text-red-600">{{ t('batch.edit.notFound') }}</div>
    <div v-else class="space-y-6">
      <section class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5">
        <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between mb-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.edit.infoTitle') }}</h2>
            <p class="text-xs text-gray-500">{{ t('batch.edit.infoSubtitle') }}</p>
          </div>
          <div class="flex items-center gap-2">
            <button
              class="px-3 py-2 rounded border hover:bg-gray-50 disabled:opacity-50"
              type="button"
              :disabled="!canInputActualYield"
              :title="canInputActualYield ? '' : t('batch.edit.actualYieldStatusBlocked')"
              @click="openActualYieldDialog"
            >
              {{ t('batch.edit.actualYieldDialogButton') }}
            </button>
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="openRelationDialog()">
              {{ t('batch.relation.actions.add') }}
            </button>
            <button
              class="px-4 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
              type="button"
              :disabled="savingBatch"
              @click="saveBatch"
            >
              {{ savingBatch ? t('common.saving') : t('common.save') }}
            </button>
          </div>
        </header>

        <div v-if="batchSaveError" class="mb-4 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-700">
          {{ batchSaveError }}
        </div>

        <form class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4" @submit.prevent>
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
            <label class="block text-sm text-gray-600 mb-1" for="batchProductName">{{ t('batch.edit.productName') }}</label>
            <input id="batchProductName" v-model.trim="batchForm.product_name" type="text" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('batch.edit.actualYield') }}</label>
            <div class="w-full h-[40px] border rounded px-3 bg-gray-50 text-gray-700 flex items-center justify-end">
              {{ batchActualYieldText }}
            </div>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchPlannedStart">{{ t('batch.edit.plannedStart') }}</label>
            <input id="batchPlannedStart" v-model="batchForm.planned_start" type="date" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchPlannedEnd">{{ t('batch.edit.plannedEnd') }}</label>
            <input id="batchPlannedEnd" v-model="batchForm.planned_end" type="date" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchActualStart">{{ t('batch.edit.actualStart') }}</label>
            <input id="batchActualStart" v-model="batchForm.actual_start" type="date" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchActualEnd">{{ t('batch.edit.actualEnd') }}</label>
            <input id="batchActualEnd" v-model="batchForm.actual_end" type="date" class="w-full h-[40px] border rounded px-3" />
          </div>
        </form>

        <div class="mt-4 flex flex-col gap-1 text-sm md:flex-row md:items-center md:gap-3">
          <span class="text-gray-500">{{ t('batch.edit.releasedRecipeTitle') }}</span>
          <template v-if="hasReleasedRecipe">
            <button
              v-if="canOpenReleasedRecipe"
              type="button"
              class="text-left font-medium text-blue-700 underline-offset-2 hover:underline"
              @click="openReleasedRecipe"
            >
              {{ releasedRecipeLinkText }}
            </button>
            <span v-else class="font-medium text-gray-800">{{ releasedRecipeLinkText }}</span>
            <span v-if="releasedRecipeVersionSummaryText !== '—'" class="text-gray-500">
              {{ releasedRecipeVersionSummaryText }}
            </span>
          </template>
          <span v-else class="text-gray-500">{{ t('batch.edit.releasedRecipeEmpty') }}</span>
        </div>

        <hr class="my-5 border-gray-200" />

        <div class="space-y-3">
          <div v-if="attrLoading" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
          <div v-else-if="attrFields.length === 0" class="text-sm text-gray-500">{{ t('batch.edit.attrEmpty') }}</div>
          <div v-else class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            <div v-for="field in attrFields" :key="field.attr_id">
              <label class="block text-sm text-gray-600 mb-1">
                {{ attrLabel(field) }}<span v-if="field.required" class="text-red-600">*</span>
              </label>
              <template v-if="field.data_type === 'ref'">
                <select v-model="field.value" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="opt in field.options" :key="opt.value" :value="opt.value">{{ opt.label }}</option>
                </select>
              </template>
              <template v-else-if="field.data_type === 'number'">
                <div class="flex items-center gap-2">
                  <input
                    v-model="field.value"
                    type="number"
                    step="any"
                    :min="field.num_min ?? undefined"
                    :max="field.num_max ?? undefined"
                    :class="[
                      'w-full h-[40px] border rounded px-3',
                      field.error ? 'border-red-500 focus:border-red-500 focus:ring-red-500' : '',
                    ]"
                    @input="validateBatchAttributeField(field)"
                    @blur="validateBatchAttributeField(field)"
                  />
                  <span v-if="field.uom_code" class="text-xs text-gray-500">{{ field.uom_code }}</span>
                </div>
              </template>
              <template v-else-if="field.data_type === 'bool'">
                <label class="inline-flex items-center gap-2 text-sm text-gray-700">
                  <input v-model="field.value" type="checkbox" class="h-4 w-4" />
                  {{ t('common.yes') }}
                </label>
              </template>
              <template v-else-if="field.data_type === 'date'">
                <input v-model="field.value" type="date" class="w-full h-[40px] border rounded px-3" />
              </template>
              <template v-else-if="field.data_type === 'timestamp'">
                <input v-model="field.value" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
              </template>
              <template v-else-if="field.data_type === 'json'">
                <textarea v-model.trim="field.value" rows="3" class="w-full border rounded px-3 py-2 font-mono text-xs"></textarea>
              </template>
              <template v-else>
                <input v-model.trim="field.value" type="text" class="w-full h-[40px] border rounded px-3" />
              </template>
              <p v-if="field.error" class="mt-1 text-xs text-red-600">{{ field.error }}</p>
            </div>
          </div>
        </div>
      </section>

      <section v-if="showStepExecutionSection" class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5">
        <header class="flex flex-col md:flex-row md:items-center md:justify-between gap-3 mb-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.edit.stepExecutionTitle') }}</h2>
            <p class="text-xs text-gray-500">{{ t('batch.edit.stepExecutionSubtitle') }}</p>
          </div>
          <div v-if="!executionLoading" class="flex flex-wrap gap-2 text-xs text-gray-600">
            <span class="rounded-full bg-gray-100 px-2 py-1">
              {{ t('batch.edit.executionBatchStatus') }}: {{ statusLabel(batchForm.status || batch?.status || '') }}
            </span>
            <span class="rounded-full bg-gray-100 px-2 py-1">
              {{ t('batch.edit.executionProgress') }}: {{ executionCompletedSteps }} / {{ executionTotalSteps }}
            </span>
            <span class="rounded-full bg-gray-100 px-2 py-1">
              {{ t('batch.edit.executionCurrentStep') }}: {{ executionCurrentStepText }}
            </span>
            <span class="rounded-full bg-gray-100 px-2 py-1">
              {{ t('batch.edit.executionOpenDeviations') }}: {{ executionOpenDeviationCount }}
            </span>
          </div>
        </header>

        <div v-if="executionLoading" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
        <div v-else-if="executionError" class="rounded-lg border border-amber-200 bg-amber-50 px-3 py-2 text-sm text-amber-700">
          {{ executionError }}
        </div>
        <div v-else class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full text-sm divide-y divide-gray-200">
            <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('batch.edit.stepNo') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.edit.stepCode') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.edit.stepName') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.edit.stepStatus') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.edit.stepDuration') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.edit.stepStartedAt') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.edit.stepEndedAt') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.edit.stepPlannedMaterials') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.edit.stepQualityChecks') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.edit.stepEquipmentAssignments') }}</th>
                <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="step in executionSteps" :key="step.id" class="hover:bg-gray-50 cursor-pointer" @click="openStepDetail(step)">
                <td class="px-3 py-2 text-gray-700">{{ step.step_no }}</td>
                <td class="px-3 py-2 text-gray-700">{{ step.step_code }}</td>
                <td class="px-3 py-2 text-gray-800 font-medium">{{ step.step_name }}</td>
                <td class="px-3 py-2">
                  <span :class="stepStatusClass(step.status)">{{ stepStatusLabel(step.status) }}</span>
                </td>
                <td class="px-3 py-2 text-right text-gray-700">{{ formatDurationSeconds(step.planned_duration_sec) }}</td>
                <td class="px-3 py-2 text-gray-600">{{ formatDateTime(step.started_at) }}</td>
                <td class="px-3 py-2 text-gray-600">{{ formatDateTime(step.ended_at) }}</td>
                <td class="px-3 py-2 text-right text-gray-700">{{ step.planned_material_count }}</td>
                <td class="px-3 py-2 text-right text-gray-700">{{ step.quality_check_count }}</td>
                <td class="px-3 py-2 text-right text-gray-700">{{ step.equipment_assignment_count }}</td>
                <td class="px-3 py-2">
                  <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" type="button" @click.stop="openStepDetail(step)">
                    {{ t('batch.edit.viewStep') }}
                  </button>
                </td>
              </tr>
              <tr v-if="executionSteps.length === 0">
                <td class="px-3 py-6 text-center text-gray-500" colspan="11">{{ t('batch.edit.executionEmpty') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5">
        <header class="flex flex-col md:flex-row md:items-center md:justify-between gap-3 mb-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.edit.fillingTitle') }}</h2>
            <p class="text-xs text-gray-500">{{ t('batch.edit.fillingSubtitle') }}</p>
          </div>
          <div class="flex items-center gap-2">
            <span v-if="packingNotice" class="text-xs text-green-600">{{ packingNotice }}</span>
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-50"
              type="button"
              :disabled="!batchId"
              @click="openLotDagPage"
            >
              {{ t('batch.edit.lotDagButton') }}
            </button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="!batch" @click="openPackingDialog">
              {{ t('batch.packaging.openDialog') }}
            </button>
          </div>
        </header>

        <div class="grid grid-cols-1 md:grid-cols-3 gap-3 text-sm text-gray-600 mb-4">
          <div class="border border-gray-200 rounded-lg p-3">
            <div class="text-xs uppercase text-gray-500">{{ t('batch.edit.fillingSummaryTotal') }}</div>
            <div class="text-base font-semibold text-gray-800">{{ packingSummaryTotalText }}</div>
          </div>
          <div class="border border-gray-200 rounded-lg p-3">
            <div class="text-xs uppercase text-gray-500">{{ t('batch.edit.fillingSummaryProcessed') }}</div>
            <div class="text-base font-semibold text-gray-800">{{ packingSummaryProcessedText }}</div>
          </div>
          <div class="border border-gray-200 rounded-lg p-3">
            <div class="text-xs uppercase text-gray-500">{{ t('batch.edit.fillingSummaryRemaining') }}</div>
            <div class="text-base font-semibold" :class="packingRemainingVolumeClass">{{ packingSummaryRemainingText }}</div>
          </div>
        </div>

        <div class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full text-sm divide-y divide-gray-200">
            <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.date') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.beerCategory') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.packingType') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.tankNo') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.packaging.columns.tankFillStartVolume') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.packaging.columns.tankFillLeftVolume') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.packaging.columns.fillingPayoutQty') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.packageInfo') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.packaging.columns.number') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.packaging.columns.totalLineVolume') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.packaging.columns.fillingRemainingQty') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.packaging.columns.loss') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.packaging.columns.memo') }}</th>
                <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="event in packingEvents" :key="event.id" class="hover:bg-gray-50">
                <td class="px-3 py-2 text-gray-600">{{ formatPackingDate(event.event_time) }}</td>
                <td class="px-3 py-2 text-gray-700">{{ formatPackingBeerCategory() }}</td>
                <td class="px-3 py-2 font-medium text-gray-800">{{ formatPackingType(event.packing_type) }}</td>
                <td class="px-3 py-2 text-gray-700">{{ formatPackingTankNo(event) }}</td>
                <td class="px-3 py-2 text-right text-gray-700">{{ formatPackingTankStartVolume(event) }}</td>
                <td class="px-3 py-2 text-right text-gray-700">{{ formatPackingTankLeftVolume(event) }}</td>
                <td class="px-3 py-2 text-right text-gray-700">{{ formatPackingFillingPayout(event) }}</td>
                <td class="px-3 py-2 text-gray-700">{{ formatPackingPackageInfo(event) }}</td>
                <td class="px-3 py-2 text-right text-gray-700">{{ formatPackingNumber(event) }}</td>
                <td class="px-3 py-2 text-right text-gray-700">{{ formatPackingTotalLineVolume(event) }}</td>
                <td class="px-3 py-2 text-right text-gray-700">{{ formatPackingFillingRemaining(event) }}</td>
                <td class="px-3 py-2 text-right text-gray-700">{{ formatPackingLoss(event) }}</td>
                <td class="px-3 py-2 text-gray-600">{{ event.memo || '—' }}</td>
                <td class="px-3 py-2">
                  <button
                    v-if="event.packing_type !== 'unpack'"
                    class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700"
                    type="button"
                    @click="deletePackingEvent(event)"
                  >
                    {{ t('batch.packaging.actions.delete') }}
                  </button>
                </td>
              </tr>
              <tr v-if="packingEvents.length === 0">
                <td class="px-3 py-6 text-center text-gray-500" colspan="14">{{ t('batch.packaging.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5">
        <header class="flex flex-col md:flex-row md:items-center md:justify-between gap-3 mb-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.relation.title') }}</h2>
            <p class="text-xs text-gray-500">{{ t('batch.relation.subtitle') }}</p>
          </div>
          <div class="flex items-center gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" :disabled="relationLoading" @click="openRelationDialog()">
              {{ t('batch.relation.actions.add') }}
            </button>
          </div>
        </header>

        <div v-if="relationLoading" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
        <div v-else-if="batchRelations.length === 0" class="text-sm text-gray-500">{{ t('common.noData') }}</div>
        <div v-else class="overflow-x-auto border border-gray-200 rounded-lg">
          <table class="min-w-full text-sm divide-y divide-gray-200">
            <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('batch.relation.columns.type') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.relation.columns.src') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.relation.columns.dst') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.relation.columns.quantity') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.relation.columns.uom') }}</th>
                <th class="px-3 py-2 text-right">{{ t('batch.relation.columns.ratio') }}</th>
                <th class="px-3 py-2 text-left">{{ t('batch.relation.columns.effectiveAt') }}</th>
                <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="relation in batchRelations" :key="relation.id" class="hover:bg-gray-50">
                <td class="px-3 py-2 text-gray-700">{{ relationTypeLabel(relation.relation_type) }}</td>
                <td class="px-3 py-2 text-gray-700">{{ batchLabel(relation.src_batch_id) }}</td>
                <td class="px-3 py-2 text-gray-700">{{ batchLabel(relation.dst_batch_id) }}</td>
                <td class="px-3 py-2 text-right text-gray-700">{{ formatNumber(relation.quantity) }}</td>
                <td class="px-3 py-2 text-gray-700">{{ uomLabel(relation.uom_id) }}</td>
                <td class="px-3 py-2 text-right text-gray-700">{{ formatNumber(relation.ratio) }}</td>
                <td class="px-3 py-2 text-gray-600">{{ formatDateTime(relation.effective_at) }}</td>
                <td class="px-3 py-2 space-x-2">
                  <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" type="button" @click="openRelationDialog(relation)">
                    {{ t('batch.relation.actions.edit') }}
                  </button>
                  <button class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700" type="button" @click="deleteRelation(relation)">
                    {{ t('batch.relation.actions.delete') }}
                  </button>
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>

    <div v-if="relationDialog.open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-3xl bg-white rounded-xl shadow-lg border border-gray-200">
        <header class="flex items-start justify-between px-4 py-3 border-b gap-4">
          <div>
            <h3 class="text-lg font-semibold text-gray-800">{{ relationDialog.editing ? t('batch.relation.dialog.editTitle') : t('batch.relation.dialog.title') }}</h3>
            <p class="text-xs text-gray-500">{{ t('batch.relation.dialog.subtitle') }}</p>
          </div>
          <button class="text-sm px-2 py-1 rounded border hover:bg-gray-100" type="button" @click="closeRelationDialog">
            {{ t('common.close') }}
          </button>
        </header>
        <div class="p-4 space-y-4">
          <div v-if="relationDialog.globalError" class="text-sm text-red-600">{{ relationDialog.globalError }}</div>
          <div class="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('batch.relation.fields.type') }}</label>
              <select v-model="relationDialog.form.relation_type" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in relationTypeOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
              </select>
              <p v-if="relationDialog.errors.relation_type" class="mt-1 text-xs text-red-600">{{ relationDialog.errors.relation_type }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('batch.relation.fields.effectiveAt') }}</label>
              <input v-model="relationDialog.form.effective_at" type="datetime-local" class="w-full h-[40px] border rounded px-3" />
              <p v-if="relationDialog.errors.effective_at" class="mt-1 text-xs text-red-600">{{ relationDialog.errors.effective_at }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('batch.relation.fields.src') }}</label>
              <select v-model="relationDialog.form.src_batch_id" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in batchAllOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
              </select>
              <p v-if="relationDialog.errors.src_batch_id" class="mt-1 text-xs text-red-600">{{ relationDialog.errors.src_batch_id }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('batch.relation.fields.dst') }}</label>
              <select v-model="relationDialog.form.dst_batch_id" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in batchAllOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
              </select>
              <p v-if="relationDialog.errors.dst_batch_id" class="mt-1 text-xs text-red-600">{{ relationDialog.errors.dst_batch_id }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('batch.relation.fields.quantity') }}</label>
              <input v-model="relationDialog.form.quantity" type="number" step="0.000001" class="w-full h-[40px] border rounded px-3 text-right" />
              <p v-if="relationDialog.errors.quantity" class="mt-1 text-xs text-red-600">{{ relationDialog.errors.quantity }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('batch.relation.fields.uom') }}</label>
              <select v-model="relationDialog.form.uom_id" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in uomOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
              </select>
              <p v-if="relationDialog.errors.uom_id" class="mt-1 text-xs text-red-600">{{ relationDialog.errors.uom_id }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('batch.relation.fields.ratio') }}</label>
              <input v-model="relationDialog.form.ratio" type="number" step="0.000001" class="w-full h-[40px] border rounded px-3 text-right" />
            </div>
          </div>
        </div>
        <footer class="flex items-center justify-end gap-2 px-4 py-3 border-t">
          <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100" type="button" :disabled="relationDialog.loading" @click="closeRelationDialog">
            {{ t('common.cancel') }}
          </button>
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="relationDialog.loading" @click="saveRelation">
            {{ relationDialog.loading ? t('common.saving') : t('common.save') }}
          </button>
        </footer>
      </div>
    </div>

    <div v-if="actualYieldDialog.open" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-lg bg-white rounded-xl shadow-lg border border-gray-200">
        <header class="flex items-start justify-between px-4 py-3 border-b gap-4">
          <div>
            <h3 class="text-lg font-semibold text-gray-800">{{ t('batch.edit.actualYieldDialogTitle') }}</h3>
            <p class="text-xs text-gray-500">{{ t('batch.edit.actualYieldDialogSubtitle') }}</p>
          </div>
          <button class="text-sm px-2 py-1 rounded border hover:bg-gray-100 disabled:opacity-50" type="button" :disabled="actualYieldDialog.loading" @click="closeActualYieldDialog">
            {{ t('common.close') }}
          </button>
        </header>
        <div class="p-4 space-y-4">
          <div v-if="actualYieldDialog.globalError" class="text-sm text-red-600">{{ actualYieldDialog.globalError }}</div>
          <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
            <div>
              <label class="block text-sm text-gray-600 mb-1" for="actualYieldDialogQty">{{ t('batch.edit.actualYield') }}</label>
              <input
                id="actualYieldDialogQty"
                v-model="actualYieldDialog.form.actual_yield"
                type="number"
                min="0"
                :max="MAX_BATCH_ACTUAL_YIELD"
                step="0.000001"
                class="w-full h-[40px] border rounded px-3 text-right"
              />
              <p v-if="actualYieldDialog.errors.actual_yield" class="mt-1 text-xs text-red-600">{{ actualYieldDialog.errors.actual_yield }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1" for="actualYieldDialogUom">{{ t('batch.edit.actualYieldUom') }}</label>
              <select id="actualYieldDialogUom" v-model="actualYieldDialog.form.actual_yield_uom" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in volumeUomOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
              </select>
              <p v-if="actualYieldDialog.errors.actual_yield_uom" class="mt-1 text-xs text-red-600">{{ actualYieldDialog.errors.actual_yield_uom }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1" for="actualYieldDialogSite">{{ t('batch.edit.actualYieldSite') }}</label>
              <select id="actualYieldDialogSite" v-model="actualYieldDialog.form.site_id" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('common.select') }}</option>
                <option v-for="option in siteOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
              </select>
              <p v-if="actualYieldDialog.errors.site_id" class="mt-1 text-xs text-red-600">{{ actualYieldDialog.errors.site_id }}</p>
            </div>
          </div>
        </div>
        <footer class="flex items-center justify-end gap-2 px-4 py-3 border-t">
          <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-50" type="button" :disabled="actualYieldDialog.loading" @click="closeActualYieldDialog">
            {{ t('common.cancel') }}
          </button>
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="actualYieldDialog.loading" @click="saveActualYieldDialog">
            {{ actualYieldDialog.loading ? t('common.saving') : t('common.save') }}
          </button>
        </footer>
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
  </AdminLayout>
</template>

<script setup lang="ts">
/* eslint-disable @typescript-eslint/no-explicit-any */
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import ConfirmActionDialog from '@/components/common/ConfirmActionDialog.vue'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { useConfirmDialog } from '@/composables/useConfirmDialog'
import {
  fillingUnitsFromEvent,
  packingFillingPayoutFromEvent as derivePackingFillingPayoutFromEvent,
  packingFillingRemainingFromEvent as derivePackingFillingRemainingFromEvent,
  packingLossFromEvent as derivePackingLossFromEvent,
  packingTotalLineVolumeFromEvent as derivePackingTotalLineVolumeFromEvent,
  processedFillingVolumeFromEvent,
} from '@/lib/batchFilling'
import {
  buildAlcoholTypeLabelMap,
  loadAlcoholTypeReferenceData,
  resolveAlcoholTypeLabel,
} from '@/lib/alcoholTypeRegistry'
import {
  normalizeBatchAttrDataType,
  validateBatchAttrField,
} from '@/lib/batchAttrValidation'
import {
  dateOnlyToUtcStartOfDayIso,
  normalizeDateOnly,
} from '@/lib/dateOnly'
import { DEVELOPMENT_MODE_ENABLED } from '@/lib/devMode'
import { toRpcUserError } from '@/lib/rpcErrors'
import { supabase } from '@/lib/supabase'
import { formatVolume } from '@/lib/volumeFormat'

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()
const { confirmDialog, requestConfirmation, cancelConfirmation, acceptConfirmation } = useConfirmDialog()
const mesClient = () => supabase.schema('mes')

const batchId = computed(() => route.params.batchId as string | undefined)
const pageTitle = computed(() => t('batch.edit.title'))
const ZERO_UUID = '00000000-0000-0000-0000-000000000000'
const MAX_BATCH_ACTUAL_YIELD = 1000000
const ACTUAL_YIELD_ALLOWED_STATUSES = new Set(['in_progress', 'finished', 'completed'])
const showStepExecutionSection = DEVELOPMENT_MODE_ENABLED

const tenantId = ref<string | null>(null)
const batch = ref<any>(null)
const loadingBatch = ref(false)
const savingBatch = ref(false)

const batchForm = reactive({
  batch_code: '',
  batch_label: '',
  status: '',
  product_name: '',
  actual_yield: '',
  actual_yield_uom: '',
  planned_start: '',
  planned_end: '',
  actual_start: '',
  actual_end: '',
  related_batch_id: '',
})

type AttrRuleRow = {
  attr_id: number
  required: boolean
  sort_order: number | null
  is_active: boolean
  attr_def?: {
    attr_id: number
    code: string
    name: string
    name_i18n: Record<string, string> | null
    data_type: string
    required: boolean
    uom_id: string | null
    num_min: number | null
    num_max: number | null
    text_regex: string | null
    allowed_values: unknown | null
    ref_kind: string | null
    ref_domain: string | null
  } | null
}

type AttrField = {
  attr_id: number
  code: string
  name: string
  name_i18n: Record<string, string> | null
  data_type: string
  required: boolean
  uom_id: string | null
  uom_code: string | null
  num_min: number | null
  num_max: number | null
  text_regex: string | null
  allowed_values: unknown | null
  ref_kind: string | null
  ref_domain: string | null
  value: any
  options: Array<{ value: string | number, label: string }>
  error: string
}

const attrFields = ref<AttrField[]>([])
const attrLoading = ref(false)
const refOptionsCache = new Map<string, Array<{ value: string | number, label: string }>>()

const batchOptions = ref<Array<{ value: string, label: string }>>([])
const batchAllOptions = ref<Array<{ value: string, label: string }>>([])
const batchOptionsLoading = ref(false)
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

interface PackageCategoryOption {
  id: string
  package_code: string
  name_i18n: Record<string, string> | null
  unit_volume: number | null
  volume_fix_flg: boolean | null
  volume_uom: string | null
}

interface SiteOption {
  value: string
  label: string
}

const MANUFACTURING_SITE_TYPE_KEY = 'BREWERY_MANUFACTUR'

interface BeerCategoryOption {
  value: string
  key: string
  label: string
}

interface VolumeUomOption {
  id: string
  code: string
  name: string | null
}

type UomOption = {
  id: string
  code: string
  name: string | null
}

type PackingType = 'ship' | 'filling' | 'transfer' | 'loss' | 'dispose' | 'unpack'

type PackingFillingLine = {
  id: string
  package_type_id: string
  qty: number | null
  volume: number | null
  sample_flg: boolean
  lot_code?: string | null
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
  tank_no: string | null
  tank_fill_start_volume: number | null
  tank_left_volume: number | null
  tank_loss_calc_mode: string | null
  tank_loss_volume: number | null
  sample_volume: number | null
  loss_qty: number | null
  loss_uom: string | null
  source_lot_no: string | null
  source_package_id: string | null
  unpack_qty: number | null
  unpack_uom: string | null
  unpack_units: number | null
  source_remaining_qty: number | null
  source_remaining_uom: string | null
}

const packageCategories = ref<PackageCategoryOption[]>([])
const siteOptions = ref<SiteOption[]>([])
const beerCategories = ref<BeerCategoryOption[]>([])
const beerCategoryLabelMap = computed(() => {
  const map = new Map<string, string>()
  beerCategories.value.forEach((row) => {
    if (!row.label) return
    ;[row.value, row.key, row.label].forEach((key) => {
      const normalized = String(key ?? '').trim()
      if (normalized) map.set(normalized, row.label)
    })
  })
  return map
})
const recipeCategoryId = ref<string | null>(null)
const volumeUoms = ref<VolumeUomOption[]>([])
const uomOptionsRaw = ref<UomOption[]>([])
const packingEvents = ref<PackingEvent[]>([])
const packingNotice = ref('')
const batchSaveError = ref('')

const actualYieldDialog = reactive({
  open: false,
  loading: false,
  globalError: '',
  errors: {} as Record<string, string>,
  form: {
    actual_yield: '',
    actual_yield_uom: '',
    site_id: '',
  },
})

type BatchRelationRow = {
  id: string
  src_batch_id: string
  dst_batch_id: string
  relation_type: string
  quantity: number | null
  uom_id: string | null
  ratio: number | null
  effective_at: string | null
}

type RelationFormState = {
  id?: string
  relation_type: string
  src_batch_id: string
  dst_batch_id: string
  quantity: string
  uom_id: string
  ratio: string
  effective_at: string
}

const batchRelations = ref<BatchRelationRow[]>([])
const relationLoading = ref(false)
const relationDialog = reactive({
  open: false,
  editing: false,
  loading: false,
  globalError: '',
  errors: {} as Record<string, string>,
  form: {
    relation_type: '',
    src_batch_id: '',
    dst_batch_id: '',
    quantity: '',
    uom_id: '',
    ratio: '',
    effective_at: '',
  } as RelationFormState,
})

type BatchExecutionStepRow = {
  id: string
  step_no: number
  step_code: string
  step_name: string
  step_template_code: string | null
  planned_duration_sec: number | null
  status: string
  planned_params: Record<string, any>
  quality_checks_json: any[]
  snapshot_json: Record<string, any>
  started_at: string | null
  ended_at: string | null
  notes: string | null
  planned_material_count: number
  quality_check_count: number
  equipment_assignment_count: number
  actual_material_count: number
  deviation_count: number
}

type BatchDeviationRow = {
  id: string
  deviation_code: string | null
  summary: string
  severity: string
  status: string
  opened_at: string
  closed_at: string | null
  detail_json: Record<string, any>
  batch_step_id: string | null
}

const executionSteps = ref<BatchExecutionStepRow[]>([])
const executionDeviations = ref<BatchDeviationRow[]>([])
const executionLoading = ref(false)
const executionError = ref('')

const releasedRecipeReference = computed(() => asRecord(batch.value?.released_reference_json))
const releasedRecipeBody = computed(() => asRecord(batch.value?.recipe_json))
const hasReleasedRecipe = computed(() => {
  return Boolean(
    batch.value?.mes_recipe_id ||
    batch.value?.recipe_version_id ||
    releasedRecipeReference.value ||
    releasedRecipeBody.value,
  )
})
const canOpenReleasedRecipe = computed(() => Boolean(batch.value?.mes_recipe_id && batch.value?.recipe_version_id))

const releasedRecipeLinkText = computed(() => {
  const recipeName = safeText(releasedRecipeReference.value?.recipe_name) || safeText(batch.value?.product_name)
  const recipeCode = safeText(releasedRecipeReference.value?.recipe_code)
  if (recipeName && recipeCode) return `${recipeName} (${recipeCode})`
  if (recipeName) return recipeName
  if (recipeCode) return recipeCode
  return '—'
})

const releasedRecipeVersionNoText = computed(() => {
  const versionNo = releasedRecipeReference.value?.version_no
  if (versionNo === null || versionNo === undefined || versionNo === '') return '—'
  return String(versionNo)
})

const releasedRecipeVersionLabelText = computed(() => {
  return safeText(releasedRecipeReference.value?.version_label) || '—'
})

const releasedRecipeVersionSummaryText = computed(() => {
  const parts: string[] = []
  if (releasedRecipeVersionNoText.value !== '—') parts.push(`v${releasedRecipeVersionNoText.value}`)
  if (releasedRecipeVersionLabelText.value !== '—') parts.push(releasedRecipeVersionLabelText.value)
  return parts.join(' / ') || '—'
})

const executionTotalSteps = computed(() => executionSteps.value.length)
const executionCompletedSteps = computed(() =>
  executionSteps.value.filter((step) => step.status === 'completed').length,
)
const executionOpenDeviationCount = computed(() =>
  executionDeviations.value.filter((row) => row.status === 'open').length,
)
const currentExecutionStep = computed(() => {
  const ordered = executionSteps.value.slice().sort((a, b) => a.step_no - b.step_no)
  return ordered.find((step) => step.status === 'in_progress')
    || ordered.find((step) => step.status === 'ready')
    || ordered.find((step) => step.status === 'open')
    || null
})
const executionCurrentStepText = computed(() => {
  if (!currentExecutionStep.value) return t('batch.edit.executionNoCurrentStep')
  return `${currentExecutionStep.value.step_no}. ${currentExecutionStep.value.step_name}`
})

function resolveUomCode(value: string | null | undefined) {
  if (!value) return null
  const byId = volumeUoms.value.find((row) => row.id === value)
  if (byId) return byId.code
  const byCode = volumeUoms.value.find((row) => row.code === value)
  if (byCode) return byCode.code
  return value
}

function defaultVolumeUomId() {
  const preferred = volumeUoms.value.find((row) => row.code === 'L')?.id
  return preferred || volumeUoms.value[0]?.id || ''
}



function eventVolumeInLiters(event: PackingEvent) {
  if (event.volume_qty == null) return null
  return convertToLiters(event.volume_qty, resolveUomCode(event.volume_uom))
}

function fillingCalculationOptions() {
  return {
    isPackageVolumeFixed,
    resolvePackageUnitVolume,
  }
}

function processedVolumeFromPackingEvent(event: PackingEvent) {
  if (event.packing_type === 'filling') {
    return processedFillingVolumeFromEvent(event, fillingCalculationOptions())
  }
  if (event.packing_type === 'unpack') {
    const volume = eventVolumeInLiters(event)
    if (volume != null) return -volume
    if (event.movement?.qty != null && Number.isFinite(event.movement.qty)) return -event.movement.qty
    return 0
  }
  const volume = eventVolumeInLiters(event)
  if (volume != null) return volume
  if (event.movement?.qty != null && Number.isFinite(event.movement.qty)) return event.movement.qty
  return 0
}

const packingTypeOptions = computed(() => ([
  { value: 'filling', label: t('batch.packaging.types.filling') },
  { value: 'ship', label: t('batch.packaging.types.ship') },
  { value: 'transfer', label: t('batch.packaging.types.transfer') },
  { value: 'loss', label: t('batch.packaging.types.loss') },
  { value: 'dispose', label: t('batch.packaging.types.dispose') },
] as Array<{ value: PackingType, label: string }>))

const volumeUomOptions = computed(() =>
  volumeUoms.value.map((row) => ({
    value: row.id,
    label: row.name ? `${row.code} - ${row.name}` : row.code,
  }))
)

const uomOptions = computed(() =>
  uomOptionsRaw.value.map((row) => ({
    value: row.id,
    label: row.name ? `${row.code} - ${row.name}` : row.code,
  }))
)

const relationTypeOptions = computed(() => ([
  { value: 'split', label: t('batch.relation.types.split') },
  { value: 'merge', label: t('batch.relation.types.merge') },
  { value: 'blend', label: t('batch.relation.types.blend') },
  { value: 'rework', label: t('batch.relation.types.rework') },
  { value: 'repackage', label: t('batch.relation.types.repackage') },
  { value: 'dilution', label: t('batch.relation.types.dilution') },
  { value: 'transfer', label: t('batch.relation.types.transfer') },
]))

const batchActualYieldLiters = computed(() => {
  const qty = toNumber(batchForm.actual_yield)
  if (qty == null) return null
  return convertToLiters(qty, resolveUomCode(batchForm.actual_yield_uom))
})

const batchActualYieldText = computed(() => {
  const liters = batchActualYieldLiters.value
  if (liters == null) return '—'
  return formatVolumeValue(liters)
})

const totalProductVolume = computed(() => {
  if (batchActualYieldLiters.value != null) return batchActualYieldLiters.value
  return resolveBatchVolume(batch.value)
})

const packingProcessedVolume = computed(() => {
  if (!packingEvents.value.length) return 0
  return packingEvents.value.reduce((sum, event) => sum + processedVolumeFromPackingEvent(event), 0)
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

function attrLabel(field: AttrField) {
  const lang = locale.value?.toString().toLowerCase().startsWith('ja') ? 'ja' : 'en'
  const label = field.name_i18n?.[lang]
  return label || field.name || field.code
}

function statusLabel(status: string | null | undefined) {
  const value = safeText(status)
  if (!value) return '—'
  const match = batchStatusOptions.value.find((option) => option.value === value)
  return match?.label ?? humanizeToken(value)
}

function isActualYieldAllowedStatus(status: string | null | undefined) {
  const value = safeText(status).toLowerCase()
  return ACTUAL_YIELD_ALLOWED_STATUSES.has(value)
}

const canInputActualYield = computed(() =>
  isActualYieldAllowedStatus(batchForm.status || batch.value?.status),
)

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
    await Promise.all([loadBatchOptions(), loadBatchStatusOptions(), loadSites(), loadBeerCategories(), fetchPackageCategories(), loadVolumeUoms(), loadUoms()])
    const { data, error } = await supabase.rpc('batch_get_detail', {
      p_batch_id: batchId.value,
    })
    if (error) throw toRpcUserError(error)
    const detail = (data ?? null) as any
    const header = detail?.batch ?? null
    batch.value = header
    if (header) {
      batchForm.batch_code = header.batch_code ?? ''
      batchForm.batch_label = header.batch_label ?? resolveMetaLabel(header.meta) ?? ''
      batchForm.status = header.status ?? ''
      batchForm.product_name = header.product_name ?? ''
      batchForm.actual_yield = header.actual_yield != null ? String(header.actual_yield) : ''
      batchForm.actual_yield_uom = header.actual_yield_uom ?? ''
      batchForm.planned_start = toInputDate(header.planned_start)
      batchForm.planned_end = toInputDate(header.planned_end)
      batchForm.actual_start = toInputDate(header.actual_start)
      batchForm.actual_end = toInputDate(header.actual_end)
      batchForm.related_batch_id = resolveMetaString(header.meta, 'related_batch_id') ?? ''
      recipeCategoryId.value = await loadRecipeCategory(header.mes_recipe_id ?? null)
      batchRelations.value = (Array.isArray(detail?.relations) ? detail.relations : []).map((row: any) => ({
        id: row.id,
        src_batch_id: row.src_batch_id,
        dst_batch_id: row.dst_batch_id,
        relation_type: row.relation_type,
        quantity: row.quantity != null ? Number(row.quantity) : null,
        uom_id: row.uom_id ?? null,
        ratio: row.ratio != null ? Number(row.ratio) : null,
        effective_at: row.effective_at ?? null,
      }))
      if (!showStepExecutionSection) {
        executionSteps.value = []
        executionDeviations.value = []
        executionError.value = ''
      }
      const detailLoaders = [
        loadPackingEvents(),
        loadBatchAttributes(header.id),
      ]
      if (showStepExecutionSection) {
        detailLoaders.push(loadBatchExecution(header.id))
      }
      await Promise.all(detailLoaders)
    } else {
      attrFields.value = []
      recipeCategoryId.value = null
      packingEvents.value = []
      batchRelations.value = []
      executionSteps.value = []
      executionDeviations.value = []
    }
  } catch (err) {
    console.error(err)
  } finally {
    loadingBatch.value = false
  }
}

async function loadBatchAttributes(batchUuid: string) {
  try {
    attrLoading.value = true
    const tenant = await ensureTenant()
    const { data: assigned, error: assignedError } = await supabase
      .from('entity_attr_set')
      .select('attr_set_id')
      .eq('entity_type', 'batch')
      .eq('entity_id', batchUuid)
      .eq('is_active', true)
    if (assignedError) throw assignedError
    const setIds = (assigned ?? []).map((row) => row.attr_set_id as number)
    if (setIds.length === 0) {
      attrFields.value = []
      return
    }

    const { data: ruleRows, error: ruleError } = await supabase
      .from('attr_set_rule')
      .select('attr_id, required, sort_order, is_active, attr_def:attr_def!fk_attr_set_rule_attr(attr_id, code, name, name_i18n, data_type, required, uom_id, num_min, num_max, text_regex, allowed_values, ref_kind, ref_domain)')
      .in('attr_set_id', setIds)
      .eq('is_active', true)
      .order('sort_order', { ascending: true })
    if (ruleError) throw ruleError

    const { data: valueRows, error: valueError } = await supabase
      .from('entity_attr')
      .select('attr_id, value_text, value_num, value_bool, value_date, value_ts, value_json, value_ref_type_id, uom_id')
      .eq('entity_type', 'batch')
      .eq('entity_id', batchUuid)
    if (valueError) throw valueError

    const valueMap = new Map<number, any>()
    ;(valueRows ?? []).forEach((row: any) => valueMap.set(Number(row.attr_id), row))

    const uomIds = new Set<string>()
    const refKeys = new Set<string>()
    for (const row of ruleRows ?? []) {
      const attr = row.attr_def as any
      if (!attr) continue
      if (attr.uom_id) uomIds.add(String(attr.uom_id))
      if (attr.data_type === 'ref' && attr.ref_kind && attr.ref_domain) {
        refKeys.add(`${attr.ref_kind}:${attr.ref_domain}`)
      }
    }

    const uomMap = new Map<string, string>()
    if (uomIds.size) {
      const { data: uomRows, error: uomError } = await supabase
        .from('mst_uom')
        .select('id, code')
        .eq('tenant_id', tenant)
        .in('id', Array.from(uomIds))
      if (uomError) throw uomError
      for (const row of uomRows ?? []) uomMap.set(String(row.id), row.code)
    }

    const refOptions = new Map<string, Array<{ value: string | number, label: string }>>()
    for (const key of Array.from(refKeys)) {
      if (refOptionsCache.has(key)) {
        refOptions.set(key, refOptionsCache.get(key) ?? [])
        continue
      }
      const [kind, domain] = key.split(':')
      let options: Array<{ value: string | number, label: string }> = []
      if (kind === 'registry_def') {
        const query = domain === 'alcohol_type'
          ? supabase.from('v_alcohol_type_options').select('def_id, def_key, spec').order('value', { ascending: true })
          : supabase.from('registry_def').select('def_id, def_key, spec').eq('kind', domain).eq('is_active', true).order('def_key', { ascending: true })
        const { data, error } = await query
        if (error) throw error
        options = (data ?? []).map((row: any) => ({
          value: row.def_id,
          label: row.spec?.name || row.def_key,
        }))
      } else if (kind === 'type_def') {
        const { data, error } = await supabase
          .from('type_def')
          .select('type_id, code, name')
          .eq('domain', domain)
          .eq('is_active', true)
          .order('sort_order', { ascending: true })
        if (error) throw error
        options = (data ?? []).map((row: any) => ({
          value: row.type_id,
          label: row.name || row.code,
        }))
      }
      refOptionsCache.set(key, options)
      refOptions.set(key, options)
    }

    const fields: AttrField[] = []
    for (const row of ruleRows ?? []) {
      const typedRow = row as unknown as AttrRuleRow
      const attrRaw = typedRow.attr_def as any
      const attr = Array.isArray(attrRaw) ? attrRaw[0] : attrRaw
      if (!attr) continue
      const valueRow = valueMap.get(attr.attr_id)
      let value: any = ''
      const dataType = normalizeBatchAttrDataType(attr.data_type)
      if (dataType === 'number') value = valueRow?.value_num ?? ''
      else if (dataType === 'bool') value = valueRow?.value_bool ?? false
      else if (dataType === 'date') value = normalizeDateOnly(valueRow?.value_date)
      else if (dataType === 'timestamp') value = toInputDateTime(valueRow?.value_ts)
      else if (dataType === 'json') value = valueRow?.value_json ? JSON.stringify(valueRow.value_json, null, 2) : ''
      else if (dataType === 'ref') {
        if (attr.ref_kind === 'registry_def') value = valueRow?.value_json?.def_id ?? ''
        else value = valueRow?.value_ref_type_id ?? ''
      } else value = valueRow?.value_text ?? ''

      const optionsKey = attr.ref_kind && attr.ref_domain ? `${attr.ref_kind}:${attr.ref_domain}` : ''
      fields.push({
        attr_id: attr.attr_id,
        code: attr.code,
        name: attr.name,
        name_i18n: attr.name_i18n ?? null,
        data_type: dataType,
        required: Boolean(typedRow.required || attr.required),
        uom_id: attr.uom_id ?? null,
        uom_code: attr.uom_id ? uomMap.get(String(attr.uom_id)) ?? null : null,
        num_min: parseOptionalNumber(attr.num_min),
        num_max: parseOptionalNumber(attr.num_max),
        text_regex: attr.text_regex ?? null,
        allowed_values: attr.allowed_values ?? null,
        ref_kind: attr.ref_kind ?? null,
        ref_domain: attr.ref_domain ?? null,
        value,
        options: optionsKey ? refOptions.get(optionsKey) ?? [] : [],
        error: '',
      })
    }
    attrFields.value = fields
  } catch (err) {
    console.error(err)
    attrFields.value = []
  } finally {
    attrLoading.value = false
  }
}

function validateBatchAttributes(options: { enforceRequired?: boolean } = {}) {
  let hasError = false
  batchSaveError.value = ''

  for (const field of attrFields.value) {
    if (validateBatchAttributeField(field, options)) hasError = true
  }

  if (hasError) {
    batchSaveError.value = t('batch.edit.errors.attrInvalid')
  }

  return !hasError
}

function validateBatchAttributeField(field: AttrField, options: { enforceRequired?: boolean } = {}) {
  field.error = validateBatchAttrField(
    {
      code: field.code,
      name: attrLabel(field),
      data_type: field.data_type,
      required: options.enforceRequired ? field.required : false,
      num_min: field.num_min,
      num_max: field.num_max,
      text_regex: field.text_regex,
      allowed_values: field.allowed_values,
      ref_kind: field.ref_kind,
      value: field.value,
    },
    {
      required: (label) => t('errors.required', { field: label }),
      mustBeNumber: (label) => t('errors.mustBeNumber', { field: label }),
      minValue: (label, min) => t('batch.edit.errors.attrMin', { field: label, min }),
      maxValue: (label, max) => t('batch.edit.errors.attrMax', { field: label, max }),
      pattern: (label) => t('batch.edit.errors.attrPattern', { field: label }),
      allowedValues: (label) => t('batch.edit.errors.attrAllowedValues', { field: label }),
      invalidJson: (label) => t('batch.edit.errors.attrJson', { field: label }),
      invalidReference: (label) => t('batch.edit.errors.attrReference', { field: label }),
    },
  )
  return field.error
}

function ensureActualYieldAttributePrerequisites() {
  if (attrLoading.value) {
    const message = t('batch.edit.actualYieldAttrLoading')
    batchSaveError.value = message
    showPackingNotice(message)
    return false
  }
  if (!validateBatchAttributes({ enforceRequired: true })) {
    const message = t('batch.edit.actualYieldAttrRequired')
    batchSaveError.value = message
    showPackingNotice(message)
    return false
  }
  return true
}

function parseOptionalNumber(value: unknown) {
  if (value == null || value === '') return null
  const parsed = typeof value === 'number' ? value : Number(value)
  return Number.isFinite(parsed) ? parsed : null
}

async function saveBatchAttributes(batchUuid: string, options: { enforceRequired?: boolean } = {}) {
  if (!validateBatchAttributes(options)) {
    throw new Error(batchSaveError.value || t('batch.edit.errors.attrInvalid'))
  }

  const tenant = await ensureTenant()
  const toUpsert: Array<Record<string, any>> = []
  const toDelete: number[] = []

  for (const field of attrFields.value) {
    const base = {
      tenant_id: tenant,
      entity_type: 'batch',
      entity_id: batchUuid,
      attr_id: field.attr_id,
      uom_id: field.uom_id ?? null,
    }

    const isEmpty =
      field.value === null ||
      field.value === undefined ||
      field.value === '' ||
      (field.data_type === 'json' && String(field.value).trim() === '')

    if (isEmpty) {
      toDelete.push(field.attr_id)
      continue
    }

    const row: Record<string, any> = { ...base }
    if (field.data_type === 'number') row.value_num = Number(field.value)
    else if (field.data_type === 'bool') row.value_bool = Boolean(field.value)
    else if (field.data_type === 'date') row.value_date = normalizeDateOnly(field.value)
    else if (field.data_type === 'timestamp') row.value_ts = fromInputDateTime(String(field.value))
    else if (field.data_type === 'json') row.value_json = parseJsonValue(String(field.value))
    else if (field.data_type === 'ref') {
      if (field.ref_kind === 'registry_def') {
        row.value_json = { def_id: field.value, kind: field.ref_domain }
      } else {
        row.value_ref_type_id = String(field.value).trim()
      }
    } else row.value_text = String(field.value)

    toUpsert.push(row)
  }

  if (toDelete.length) {
    const { error } = await supabase
      .from('entity_attr')
      .delete()
      .eq('tenant_id', tenant)
      .eq('entity_type', 'batch')
      .eq('entity_id', batchUuid)
      .in('attr_id', toDelete)
    if (error) throw error
  }

  if (toUpsert.length) {
    const { error } = await supabase
      .from('entity_attr')
      .upsert(toUpsert, { onConflict: 'tenant_id,entity_type,entity_id,attr_id' })
    if (error) throw error
  }
}

async function loadBatchOptions() {
  if (batchOptionsLoading.value) return
  try {
    batchOptionsLoading.value = true
    const { data, error } = await supabase.rpc('batch_search', {
      p_filter: {
        limit: 1000,
        offset: 0,
      },
    })
    if (error) throw error
    const all = (data ?? []).map((row: any) => ({ value: row.id, label: row.batch_code }))
    batchAllOptions.value = all
    batchOptions.value = all.filter((row: any) => row.value !== batchId.value)
  } catch (err) {
    console.error(err)
  } finally {
    batchOptionsLoading.value = false
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

async function loadSites() {
  try {
    const tenant = await ensureTenant()
    const { data: siteTypeRow, error: siteTypeError } = await supabase
      .from('registry_def')
      .select('def_id')
      .eq('kind', 'site_type')
      .eq('def_key', MANUFACTURING_SITE_TYPE_KEY)
      .eq('is_active', true)
      .maybeSingle()
    if (siteTypeError) throw siteTypeError
    if (!siteTypeRow?.def_id) {
      siteOptions.value = []
      return
    }
    const { data, error } = await supabase
      .from('mst_sites')
      .select('id, name')
      .eq('tenant_id', tenant)
      .eq('site_type_id', siteTypeRow.def_id)
      .order('name')
    if (error) throw error
    siteOptions.value = (data ?? []).map((row: any) => ({
      value: row.id,
      label: row.name ?? row.id,
    }))
  } catch (err) {
    console.error(err)
  }
}

async function loadBeerCategories() {
  try {
    const { optionRows, fallbackRows } = await loadAlcoholTypeReferenceData(supabase)
    const labelMap = buildAlcoholTypeLabelMap(
      optionRows as Array<Record<string, unknown>>,
      fallbackRows as Array<Record<string, unknown>>,
    )
    beerCategories.value = optionRows.map((row: any) => ({
      value: String(row.def_id),
      key: String(row.def_key ?? ''),
      label: resolveAlcoholTypeLabel(labelMap, row.def_id) ?? String(row.def_key ?? row.def_id),
    }))
  } catch (err) {
    console.error(err)
    beerCategories.value = []
  }
}

async function loadRecipeCategory(mesRecipeId: string | null | undefined) {
  try {
    const tenant = await ensureTenant()
    if (!mesRecipeId) return null
    const { data, error } = await mesClient()
      .from('mst_recipe')
      .select('recipe_category')
      .eq('tenant_id', tenant)
      .eq('id', mesRecipeId)
      .maybeSingle()
    if (error) throw error
    if (data?.recipe_category) return String(data.recipe_category)
    return null
  } catch (err) {
    console.error(err)
    return null
  }
}

async function loadVolumeUoms() {
  try {
    const { data, error } = await supabase
      .from('mst_uom')
      .select('id, code, name, dimension')
      .eq('dimension', 'volume')
      .order('code')
    if (error) throw error
    volumeUoms.value = (data ?? []).map((row: any) => ({
      id: row.id,
      code: row.code,
      name: row.name ?? null,
    }))
  } catch (err) {
    console.error(err)
    volumeUoms.value = []
  }
}

async function loadUoms() {
  try {
    const { data, error } = await supabase
      .from('mst_uom')
      .select('id, code, name')
      .order('code')
    if (error) throw error
    uomOptionsRaw.value = (data ?? []).map((row: any) => ({
      id: row.id,
      code: row.code,
      name: row.name ?? null,
    }))
  } catch (err) {
    console.error(err)
    uomOptionsRaw.value = []
  }
}

async function loadBatchRelations() {
  if (!batchId.value) return
  try {
    relationLoading.value = true
    const tenant = await ensureTenant()
    const { data, error } = await supabase
      .from('mes_batch_relation')
      .select('id, src_batch_id, dst_batch_id, relation_type, quantity, uom_id, ratio, effective_at')
      .eq('tenant_id', tenant)
      .or(`src_batch_id.eq.${batchId.value},dst_batch_id.eq.${batchId.value}`)
      .order('effective_at', { ascending: false })
    if (error) throw error
    batchRelations.value = (data ?? []).map((row: any) => ({
      id: row.id,
      src_batch_id: row.src_batch_id,
      dst_batch_id: row.dst_batch_id,
      relation_type: row.relation_type,
      quantity: row.quantity != null ? Number(row.quantity) : null,
      uom_id: row.uom_id ?? null,
      ratio: row.ratio != null ? Number(row.ratio) : null,
      effective_at: row.effective_at ?? null,
    }))
  } catch (err) {
    console.error(err)
    batchRelations.value = []
  } finally {
    relationLoading.value = false
  }
}

async function loadBatchExecution(batchUuid: string) {
  if (!showStepExecutionSection) {
    executionSteps.value = []
    executionDeviations.value = []
    executionError.value = ''
    executionLoading.value = false
    return
  }
  try {
    executionLoading.value = true
    executionError.value = ''
    const mes = mesClient()
    const [stepResult, plannedResult, actualResult, equipmentResult, deviationResult] = await Promise.all([
      mes
        .from('batch_step')
        .select('id, step_no, step_code, step_name, step_template_code, planned_duration_sec, status, planned_params, quality_checks_json, snapshot_json, started_at, ended_at, notes')
        .eq('batch_id', batchUuid)
        .order('step_no', { ascending: true }),
      mes
        .from('batch_material_plan')
        .select('id, batch_step_id')
        .eq('batch_id', batchUuid),
      mes
        .from('batch_material_actual')
        .select('id, batch_step_id')
        .eq('batch_id', batchUuid),
      mes
        .from('batch_equipment_assignment')
        .select('id, batch_step_id')
        .eq('batch_id', batchUuid),
      mes
        .from('batch_deviation')
        .select('id, batch_step_id, deviation_code, summary, severity, status, opened_at, closed_at, detail_json')
        .eq('batch_id', batchUuid),
    ])

    if (stepResult.error) throw stepResult.error
    if (plannedResult.error) throw plannedResult.error
    if (actualResult.error) throw actualResult.error
    if (equipmentResult.error) throw equipmentResult.error
    if (deviationResult.error) throw deviationResult.error

    const plannedCountMap = countRowsByStepId(plannedResult.data ?? [])
    const actualCountMap = countRowsByStepId(actualResult.data ?? [])
    const equipmentCountMap = countRowsByStepId(equipmentResult.data ?? [])
    const deviationCountMap = countRowsByStepId(deviationResult.data ?? [])

    executionDeviations.value = (deviationResult.data ?? []).map((row: any) => ({
      id: row.id,
      batch_step_id: row.batch_step_id ?? null,
      deviation_code: row.deviation_code ?? null,
      summary: String(row.summary ?? ''),
      severity: String(row.severity ?? 'minor'),
      status: String(row.status ?? 'open'),
      opened_at: String(row.opened_at ?? ''),
      closed_at: row.closed_at ?? null,
      detail_json: asRecord(row.detail_json) ?? {},
    }))

    executionSteps.value = (stepResult.data ?? []).map((row: any) => ({
      id: row.id,
      step_no: Number(row.step_no ?? 0),
      step_code: String(row.step_code ?? ''),
      step_name: String(row.step_name ?? ''),
      step_template_code: row.step_template_code ?? null,
      planned_duration_sec: row.planned_duration_sec != null ? Number(row.planned_duration_sec) : null,
      status: String(row.status ?? 'open'),
      planned_params: asRecord(row.planned_params) ?? {},
      quality_checks_json: asArray(row.quality_checks_json),
      snapshot_json: asRecord(row.snapshot_json) ?? {},
      started_at: row.started_at ?? null,
      ended_at: row.ended_at ?? null,
      notes: row.notes ?? null,
      planned_material_count: plannedCountMap.get(row.id) ?? 0,
      quality_check_count: asArray(row.quality_checks_json).length,
      equipment_assignment_count: equipmentCountMap.get(row.id) ?? 0,
      actual_material_count: actualCountMap.get(row.id) ?? 0,
      deviation_count: deviationCountMap.get(row.id) ?? 0,
    }))
  } catch (err) {
    console.error(err)
    executionSteps.value = []
    executionDeviations.value = []
    executionError.value = extractErrorMessage(err)
      ? `${t('batch.edit.executionLoadFailed')} (${extractErrorMessage(err)})`
      : t('batch.edit.executionLoadFailed')
  } finally {
    executionLoading.value = false
  }
}

async function loadPackingEvents() {
  if (!batchId.value) return
  try {
    const { data: movementRows, error } = await supabase
      .from('inv_movements')
      .select('id, doc_no, doc_type, status, movement_at, src_site_id, dest_site_id, reason, notes, meta')
      .eq('meta->>source', 'packing')
      .eq('meta->>batch_id', batchId.value)
      .neq('status', 'void')
      .order('movement_at', { ascending: true })
    if (error) throw error
    const rows = (movementRows ?? []) as any[]
    if (!rows.length) {
      packingEvents.value = []
      return
    }
    const movementIds = rows.map((row) => row.id)
    const { data: lineRows, error: lineError } = await supabase
      .from('inv_movement_lines')
      .select('movement_id, package_id, qty, uom_id, meta')
      .in('movement_id', movementIds)
    if (lineError) throw lineError
    const linesByMovement = new Map<string, any[]>()
    ;(lineRows ?? []).forEach((line: any) => {
      const list = linesByMovement.get(line.movement_id) ?? []
      list.push(line)
      linesByMovement.set(line.movement_id, list)
    })

    packingEvents.value = rows.map((row) => {
      const meta = (row.meta ?? {}) as Record<string, any>
      const movementLines = linesByMovement.get(row.id) ?? []
      const recoveredLineMeta = movementLines
        .map((line: any) => (line?.meta ?? {}) as Record<string, any>)
        .find((lineMeta) => String(lineMeta?.line_role ?? '') === 'RECOVERED')
      const fillingLines = Array.isArray(meta.filling_lines)
        ? meta.filling_lines.map((line: any) => ({
          id: String(line?.id ?? generateLocalId()),
          package_type_id: String(line?.package_id ?? line?.package_type_id ?? ''),
          qty: line?.qty != null ? toNumber(line?.qty) : null,
          volume: line?.volume != null ? toNumber(line?.volume) : null,
          lot_code: typeof line?.lot_code === 'string' ? line.lot_code : '',
          sample_flg: line?.sample_flg === true || line?.sample_flg === 'true',
        }))
        : []
      return {
        id: row.id,
        packing_type: String(meta.packing_type ?? row.doc_type ?? '').trim() as PackingType,
        event_time: row.movement_at ?? new Date().toISOString(),
        memo: meta.memo ?? row.notes ?? null,
        volume_qty: meta.volume_qty != null ? toNumber(meta.volume_qty) : null,
        volume_uom: meta.volume_uom != null ? String(meta.volume_uom) : null,
        movement: {
          site_id: meta.movement_site_id != null ? String(meta.movement_site_id) : null,
          qty: meta.movement_qty != null ? toNumber(meta.movement_qty) : null,
          memo: meta.movement_memo != null ? String(meta.movement_memo) : null,
        },
        filling_lines: fillingLines,
        reason: meta.reason != null ? String(meta.reason) : row.reason ?? null,
        tank_no: meta.tank_no != null ? String(meta.tank_no) : null,
        tank_fill_start_volume: meta.tank_fill_start_volume != null ? toNumber(meta.tank_fill_start_volume) : null,
        tank_left_volume: meta.tank_left_volume != null ? toNumber(meta.tank_left_volume) : null,
        tank_loss_calc_mode: meta.tank_loss_calc_mode != null ? String(meta.tank_loss_calc_mode) : null,
        tank_loss_volume: meta.tank_loss_volume != null ? toNumber(meta.tank_loss_volume) : null,
        sample_volume: meta.sample_volume != null ? toNumber(meta.sample_volume) : null,
        loss_qty: meta.loss_qty != null ? toNumber(meta.loss_qty) : null,
        loss_uom: meta.loss_uom != null ? String(meta.loss_uom) : null,
        source_lot_no: meta.source_lot_no != null ? String(meta.source_lot_no) : null,
        source_package_id: meta.source_package_id != null
          ? String(meta.source_package_id)
          : recoveredLineMeta?.source_package_id != null
            ? String(recoveredLineMeta.source_package_id)
            : null,
        unpack_qty: meta.unpack_qty != null
          ? toNumber(meta.unpack_qty)
          : (meta.volume_qty != null ? (toNumber(meta.volume_qty) ?? 0) + (toNumber(meta.loss_qty) ?? 0) : null),
        unpack_uom: meta.unpack_uom != null
          ? String(meta.unpack_uom)
          : meta.volume_uom != null
            ? String(meta.volume_uom)
            : null,
        unpack_units: meta.unpack_units != null ? toNumber(meta.unpack_units) : null,
        source_remaining_qty: meta.source_remaining_qty != null ? toNumber(meta.source_remaining_qty) : null,
        source_remaining_uom: meta.source_remaining_uom != null
          ? String(meta.source_remaining_uom)
          : meta.unpack_uom != null
            ? String(meta.unpack_uom)
            : meta.volume_uom != null
              ? String(meta.volume_uom)
              : null,
      } as PackingEvent
    })
  } catch (err) {
    console.error(err)
    packingEvents.value = []
  }
}

async function fetchPackageCategories() {
  try {
    const { data, error } = await supabase
      .from('mst_package')
      .select('id, package_code, name_i18n, unit_volume, volume_fix_flg, volume_uom, is_active')
      .eq('is_active', true)
      .order('package_code', { ascending: true })
    if (error) throw error
    packageCategories.value = (data ?? []).map((row: any) => ({
      id: row.id,
      package_code: row.package_code,
      name_i18n: row.name_i18n ?? null,
      unit_volume: row.unit_volume != null ? Number(row.unit_volume) : null,
      volume_fix_flg: typeof row.volume_fix_flg === 'boolean' ? row.volume_fix_flg : null,
      volume_uom: row.volume_uom != null ? String(row.volume_uom) : null,
    }))
  } catch (err) {
    console.error(err)
  }
}

async function saveBatch() {
  if (!batchId.value) return
  try {
    savingBatch.value = true
    batchSaveError.value = ''
    if (!validateBatchAttributes()) return
    const trimmedBatchCode = batchForm.batch_code.trim()
    if (!trimmedBatchCode) {
      batchSaveError.value = t('batch.edit.errors.batchCodeRequired')
      return
    }
    const meta = buildBatchMeta(batch.value?.meta)
    const trimmedBatchLabel = batchForm.batch_label.trim()
    const update: Record<string, any> = {
      batch_code: trimmedBatchCode,
      status: batchForm.status || null,
      batch_label: trimmedBatchLabel || null,
      product_name: batchForm.product_name.trim() || null,
      actual_yield: toNumber(batchForm.actual_yield),
      actual_yield_uom: batchForm.actual_yield_uom || null,
      planned_start: fromInputDate(batchForm.planned_start),
      planned_end: fromInputDate(batchForm.planned_end),
      actual_start: fromInputDate(batchForm.actual_start),
      actual_end: fromInputDate(batchForm.actual_end),
      meta,
    }
    const { error } = await supabase.rpc('batch_save', {
      p_batch_id: batchId.value,
      p_patch: update,
    })
    if (error) throw toRpcUserError(error, { fallbackKey: 'batch.edit.errors.saveFailed' })
    await saveBatchAttributes(batchId.value)
    await fetchBatch()
  } catch (err) {
    console.error(err)
    batchSaveError.value = extractErrorMessage(err) || t('batch.edit.errors.saveFailed')
  } finally {
    savingBatch.value = false
  }
}

function generateLocalId() {
  return `local-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`
}

function openRelationDialog(row?: BatchRelationRow) {
  relationDialog.open = true
  relationDialog.editing = Boolean(row)
  relationDialog.loading = false
  relationDialog.globalError = ''
  relationDialog.errors = {}
  relationDialog.form = {
    id: row?.id,
    relation_type: row?.relation_type ?? '',
    src_batch_id: row?.src_batch_id ?? (batchId.value ?? ''),
    dst_batch_id: row?.dst_batch_id ?? '',
    quantity: row?.quantity != null ? String(row.quantity) : '',
    uom_id: row?.uom_id ?? '',
    ratio: row?.ratio != null ? String(row.ratio) : '',
    effective_at: toInputDateTime(row?.effective_at ?? new Date().toISOString()),
  }
}

function openActualYieldDialog() {
  if (!canInputActualYield.value) {
    showPackingNotice(t('batch.edit.actualYieldStatusBlocked'))
    return
  }
  if (!ensureActualYieldAttributePrerequisites()) return
  actualYieldDialog.open = true
  actualYieldDialog.loading = false
  actualYieldDialog.globalError = ''
  actualYieldDialog.errors = {}
  actualYieldDialog.form.actual_yield = batchForm.actual_yield
  actualYieldDialog.form.actual_yield_uom = batchForm.actual_yield_uom || defaultVolumeUomId()
  const resolvedSiteId = resolveProduceSiteId(batch.value)
  actualYieldDialog.form.site_id = isSelectableManufacturingSite(resolvedSiteId) ? (resolvedSiteId ?? '') : ''
}

function closeActualYieldDialog() {
  if (actualYieldDialog.loading) return
  actualYieldDialog.open = false
  actualYieldDialog.globalError = ''
  actualYieldDialog.errors = {}
}

type ActualYieldProduceMovement = {
  id: string
  src_site_id: string | null
  dest_site_id: string | null
  qty: number | null
  uom_id: string | null
}

function isSameActualYieldProduce(
  movement: ActualYieldProduceMovement,
  qty: number,
  uomId: string,
  siteId: string,
) {
  const movementSiteId = movement.dest_site_id || movement.src_site_id || null
  if (!movementSiteId || movementSiteId !== siteId) return false
  if (!movement.uom_id || movement.uom_id !== uomId) return false
  if (movement.qty == null) return false
  return Math.abs(movement.qty - qty) <= 0.000001
}

async function findPostedActualYieldProduceMovements(batchIdValue: string) {
  const { data: movementRows, error: movementError } = await supabase
    .from('inv_movements')
    .select('id, src_site_id, dest_site_id, created_at')
    .eq('status', 'posted')
    .eq('meta->>source', 'batch_actual_yield')
    .eq('meta->>batch_id', batchIdValue)
    .eq('meta->>movement_intent', 'BREW_PRODUCE')
    .order('created_at', { ascending: false })

  if (movementError) throw movementError
  const rows = (movementRows ?? []) as Array<{ id: string, src_site_id: string | null, dest_site_id: string | null }>
  if (!rows.length) return [] as ActualYieldProduceMovement[]

  const movementIds = rows.map((row) => row.id)
  const { data: lineRows, error: lineError } = await supabase
    .from('inv_movement_lines')
    .select('movement_id, line_no, qty, uom_id')
    .in('movement_id', movementIds)

  if (lineError) throw lineError
  const lineByMovement = new Map<string, { qty: number | null, uom_id: string | null }>()
  ;(lineRows ?? []).forEach((line: any) => {
    const movementId = String(line.movement_id ?? '')
    if (!movementId || lineByMovement.has(movementId)) return
    lineByMovement.set(movementId, {
      qty: toNumber(line.qty),
      uom_id: line.uom_id != null ? String(line.uom_id) : null,
    })
  })

  return rows.map((row) => {
    const line = lineByMovement.get(row.id)
    return {
      id: row.id,
      src_site_id: row.src_site_id ?? null,
      dest_site_id: row.dest_site_id ?? null,
      qty: line?.qty ?? null,
      uom_id: line?.uom_id ?? null,
    } as ActualYieldProduceMovement
  })
}

async function rollbackActualYieldProduceMovement(
  movementId: string,
  batchCode: string,
  movementAt: string,
) {
  const rollbackDoc = {
    doc_no: `PPR-${batchCode}-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`,
    movement_at: movementAt,
    produce_movement_id: movementId,
    reason: 'actual_yield_corrected',
    notes: 'Rollback previous actual yield produce movement',
    meta: {
      source: 'batch_actual_yield',
      movement_intent: 'BREW_PRODUCE_ROLLBACK',
      idempotency_key: `batch_actual_yield_rollback:${movementId}`,
    },
  }
  const { error } = await supabase.rpc('product_produce_rollback', {
    p_doc: rollbackDoc,
  })
  if (error) throw toRpcUserError(error)
}

async function saveActualYieldDialog() {
  if (!canInputActualYield.value) {
    actualYieldDialog.globalError = t('batch.edit.actualYieldStatusBlocked')
    return
  }
  const errors: Record<string, string> = {}
  const qty = toNumber(actualYieldDialog.form.actual_yield)
  const uomId = actualYieldDialog.form.actual_yield_uom
  const siteId = actualYieldDialog.form.site_id
  if (qty == null || qty <= 0) errors.actual_yield = t('batch.edit.actualYieldRequired')
  else if (qty > MAX_BATCH_ACTUAL_YIELD) {
    errors.actual_yield = t('batch.edit.actualYieldMax', { max: MAX_BATCH_ACTUAL_YIELD })
  }
  if (!uomId) errors.actual_yield_uom = t('batch.edit.actualYieldUomRequired')
  if (!siteId) errors.site_id = t('batch.edit.actualYieldSiteRequired')
  else if (!isSelectableManufacturingSite(siteId)) errors.site_id = t('batch.edit.actualYieldSiteInvalid')
  if (Object.keys(errors).length) {
    actualYieldDialog.errors = errors
    return
  }
  if (!batchId.value || !batch.value) {
    actualYieldDialog.globalError = t('batch.edit.actualYieldSaveFailed')
    return
  }
  if (!ensureActualYieldAttributePrerequisites()) {
    actualYieldDialog.globalError = t('batch.edit.actualYieldAttrRequired')
    return
  }
  const targetQty = qty as number

  actualYieldDialog.loading = true
  actualYieldDialog.globalError = ''
  let failedStage: 'attributes' | 'produce' | 'save' = 'attributes'
  try {
    await saveBatchAttributes(batchId.value, { enforceRequired: true })

    failedStage = 'produce'
    const movementAt = dateOnlyToUtcStartOfDayIso(batch.value.actual_start) ?? new Date().toISOString()
    const batchCode = String(batch.value.batch_code ?? 'BATCH')
    const normalizedQty = Number(qty).toFixed(6)
    const idempotencyKey = `batch_actual_yield:${batchId.value}:${normalizedQty}:${uomId}`

    const existingProduceMovements = await findPostedActualYieldProduceMovements(batchId.value)
    const matchingProduceMovement = existingProduceMovements.find((movement) =>
      isSameActualYieldProduce(movement, targetQty, uomId, siteId),
    )

    if (!matchingProduceMovement) {
      failedStage = 'produce'
      for (const movement of existingProduceMovements) {
        await rollbackActualYieldProduceMovement(movement.id, batchCode, movementAt)
      }
      const produceDoc = {
        doc_no: `BP-${batchCode}-${Date.now()}`,
        movement_at: movementAt,
        src_site_id: siteId,
        dest_site_id: siteId,
        material_id: ZERO_UUID,
        batch_id: batchId.value,
        qty,
        uom_id: uomId,
        produced_at: movementAt,
        meta: {
          source: 'batch_actual_yield',
          batch_id: batchId.value,
          batch_code: batchCode,
          movement_intent: 'BREW_PRODUCE',
          idempotency_key: idempotencyKey,
        },
        line_meta: {
          source: 'batch_actual_yield',
        },
      }

      const { error: produceError } = await supabase.rpc('product_produce', {
        p_doc: produceDoc,
      })
      if (produceError) throw toRpcUserError(produceError, {
        fallbackKey: 'batch.edit.actualYieldProduceFailed',
      })
    }

    failedStage = 'save'
    const patch: Record<string, any> = {
      actual_yield: qty,
      actual_yield_uom: uomId,
      meta: {
        ...(batch.value?.meta && typeof batch.value.meta === 'object' && !Array.isArray(batch.value.meta) ? batch.value.meta : {}),
        manufacturing_site_id: siteId,
      },
    }
    const { error: batchSaveError } = await supabase.rpc('batch_save', {
      p_batch_id: batchId.value,
      p_patch: patch,
    })
    if (batchSaveError) throw toRpcUserError(batchSaveError, {
      fallbackKey: 'batch.edit.actualYieldSaveFailed',
    })

    batchForm.actual_yield = String(qty)
    batchForm.actual_yield_uom = uomId
    batch.value.actual_yield = qty
    batch.value.actual_yield_uom = uomId
    batch.value.meta = patch.meta

    actualYieldDialog.open = false
    actualYieldDialog.errors = {}
    actualYieldDialog.globalError = ''
    showPackingNotice(t('batch.edit.actualYieldSaved'))
  } catch (err) {
    const detail = extractErrorMessage(err)
    const baseMessage = failedStage === 'attributes'
      ? t('batch.edit.actualYieldAttrSaveFailed')
      : failedStage === 'save'
      ? t('batch.edit.actualYieldSaveFailed')
      : t('batch.edit.actualYieldProduceFailed')
    actualYieldDialog.globalError = detail
      ? `${baseMessage} (${detail})`
      : baseMessage
  } finally {
    actualYieldDialog.loading = false
  }
}

function closeRelationDialog() {
  relationDialog.open = false
  relationDialog.errors = {}
  relationDialog.globalError = ''
}

async function openLotDagPage() {
  if (!batchId.value) return
  await router.push({
    name: 'batchLotDag',
    params: { batchId: batchId.value },
    query: { from: 'edit' },
  })
}

async function goToPackingPage(eventId?: string) {
  if (!batchId.value) return
  const query = eventId ? { eventId } : undefined
  await router.push({
    name: 'batchPacking',
    params: { batchId: batchId.value },
    query,
  })
}

function openPackingDialog() {
  void goToPackingPage()
}

async function openReleasedRecipe() {
  if (!batch.value?.mes_recipe_id || !batch.value?.recipe_version_id) return
  await router.push({
    path: `/recipeEdit/${batch.value.mes_recipe_id}/${batch.value.recipe_version_id}`,
  })
}

async function openStepDetail(step: BatchExecutionStepRow) {
  if (!batchId.value) return
  await router.push({
    name: 'batchStepExecution',
    params: {
      batchId: batchId.value,
      stepId: step.id,
    },
    query: { from: 'edit' },
  })
}

function validateRelationForm(form: RelationFormState) {
  const errors: Record<string, string> = {}
  if (!form.relation_type) errors.relation_type = t('batch.relation.errors.typeRequired')
  if (!form.src_batch_id) errors.src_batch_id = t('batch.relation.errors.srcRequired')
  if (!form.dst_batch_id) errors.dst_batch_id = t('batch.relation.errors.dstRequired')
  if (form.src_batch_id && form.dst_batch_id && form.src_batch_id === form.dst_batch_id) {
    errors.dst_batch_id = t('batch.relation.errors.sameBatch')
  }
  const qty = toNumber(form.quantity)
  if (form.quantity && qty == null) errors.quantity = t('batch.relation.errors.quantityInvalid')
  if (qty != null && !form.uom_id) errors.uom_id = t('batch.relation.errors.uomRequired')
  if (!form.effective_at) errors.effective_at = t('batch.relation.errors.effectiveRequired')
  return errors
}

async function saveRelation() {
  if (!relationDialog.form) return
  relationDialog.errors = {}
  relationDialog.globalError = ''
  const errors = validateRelationForm(relationDialog.form)
  if (Object.keys(errors).length) {
    relationDialog.errors = errors
    return
  }
  try {
    relationDialog.loading = true
    const tenant = await ensureTenant()
    const payload = {
      tenant_id: tenant,
      src_batch_id: relationDialog.form.src_batch_id,
      dst_batch_id: relationDialog.form.dst_batch_id,
      relation_type: relationDialog.form.relation_type,
      quantity: toNumber(relationDialog.form.quantity),
      uom_id: relationDialog.form.uom_id || null,
      ratio: toNumber(relationDialog.form.ratio),
      effective_at: fromInputDateTime(relationDialog.form.effective_at) ?? new Date().toISOString(),
    }
    if (relationDialog.editing && relationDialog.form.id) {
      const { error } = await supabase
        .from('mes_batch_relation')
        .update(payload)
        .eq('id', relationDialog.form.id)
      if (error) throw error
    } else {
      const { error } = await supabase
        .from('mes_batch_relation')
        .insert(payload)
      if (error) throw error
    }
    relationDialog.open = false
    await loadBatchRelations()
  } catch (err) {
    console.error(err)
    relationDialog.globalError = t('batch.relation.errors.saveFailed')
  } finally {
    relationDialog.loading = false
  }
}

async function deleteRelation(row: BatchRelationRow) {
  const confirmed = await requestConfirmation({
    title: t('common.delete'),
    message: t('batch.relation.confirmDelete'),
    confirmLabel: t('common.delete'),
    tone: 'danger',
  })
  if (!confirmed) return
  try {
    const { error } = await supabase
      .from('mes_batch_relation')
      .delete()
      .eq('id', row.id)
    if (error) throw error
    await loadBatchRelations()
  } catch (err) {
    console.error(err)
  }
}

async function deletePackingEvent(event: PackingEvent) {
  const confirmed = await requestConfirmation({
    title: t('common.delete'),
    message: t('batch.packaging.confirmDelete'),
    confirmLabel: t('common.delete'),
    tone: 'danger',
  })
  if (!confirmed) return
  try {
    if (event.packing_type === 'filling') {
      await rollbackFillingPackingEvent(event)
    } else {
      const { error } = await supabase
        .from('inv_movements')
        .update({ status: 'void' })
        .eq('id', event.id)
      if (error) throw error
    }
    await loadPackingEvents()
    showPackingNotice(t('batch.packaging.toast.deleted'))
  } catch (err) {
    console.error(err)
    showPackingNotice(t('batch.packaging.errors.deleteFailed'))
  }
}

async function rollbackFillingPackingEvent(event: PackingEvent) {
  const batchCode = batch.value?.batch_code || 'BATCH'
  const rollbackDoc = {
    doc_no: `PFR-${batchCode}-${Date.now()}-${Math.random().toString(16).slice(2, 8)}`,
    movement_at: new Date().toISOString(),
    filling_movement_id: event.id,
    reason: 'packing_event_deleted',
    notes: 'Rollback deleted filling packing event',
    meta: {
      source: 'packing',
      movement_intent: 'PACKAGE_FILL_ROLLBACK',
      idempotency_key: `packing_filling_rollback:${event.id}`,
    },
  }
  const { error } = await supabase.rpc('product_filling_rollback', {
    p_doc: rollbackDoc,
  })
  if (error) throw toRpcUserError(error)
}

function resolvePackageUnitVolume(packageTypeId: string) {
  const row = packageCategories.value.find((item) => item.id === packageTypeId)
  if (!row || row.unit_volume == null) return null
  return convertToLiters(row.unit_volume, resolveUomCode(row.volume_uom))
}

function isPackageVolumeFixed(packageTypeId: string) {
  const row = packageCategories.value.find((item) => item.id === packageTypeId)
  if (!row) return true
  return row.volume_fix_flg !== false
}

function formatPackingType(type: PackingType) {
  if (type === 'unpack') return t('batch.packaging.types.unpack')
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

function beerCategoryLabel(categoryValue: string | null | undefined) {
  if (!categoryValue) return '—'
  const normalized = categoryValue.trim()
  if (!normalized) return '—'
  return resolveAlcoholTypeLabel(beerCategoryLabelMap.value, normalized) ?? normalized
}

function formatPackingBeerCategory() {
  const attr = attrFields.value.find((field) => field.code === 'beer_category')
  const attrValue = attr?.value != null ? String(attr.value).trim() : ''
  if (attrValue) {
    const option = attr?.options.find((item) => String(item.value) === attrValue)
    if (option?.label) return option.label
    return beerCategoryLabel(attrValue)
  }
  if (recipeCategoryId.value) return beerCategoryLabel(recipeCategoryId.value)
  const metaValue =
    resolveMetaString(batch.value?.meta, 'beer_category') ??
    resolveMetaString(batch.value?.meta, 'category')
  if (metaValue) return beerCategoryLabel(metaValue)
  return '—'
}

function formatPackingTankNo(event: PackingEvent) {
  const tankNo = event.tank_no?.trim()
  return tankNo || '—'
}

function resolvePackageCode(packageTypeId: string) {
  const row = packageCategories.value.find((item) => item.id === packageTypeId)
  return row?.package_code ?? packageTypeId
}

function formatPackingPackageInfo(event: PackingEvent) {
  if (event.packing_type === 'unpack') {
    const parts: string[] = []
    const packageCode = event.source_package_id ? resolvePackageCode(event.source_package_id) : ''
    const sourceLotNo = event.source_lot_no?.trim() ?? ''
    if (packageCode) parts.push(packageCode)
    if (sourceLotNo) parts.push(sourceLotNo)
    return parts.length ? parts.join(' / ') : '—'
  }
  if (!event.filling_lines.length) return '—'
  const codes = event.filling_lines
    .map((line) => resolvePackageCode(line.package_type_id))
    .filter((value, index, arr) => value && arr.indexOf(value) === index)
  if (!codes.length) return '—'
  return codes.join(', ')
}

function formatPackingNumber(event: PackingEvent) {
  if (event.packing_type === 'unpack') {
    let unpackUnits = event.unpack_units
    if ((unpackUnits == null || !Number.isFinite(unpackUnits)) && event.source_package_id) {
      const unpackVolume = packingTotalLineVolumeFromEvent(event)
      const packageUnitVolume = resolvePackageUnitVolume(event.source_package_id)
      if (unpackVolume != null && packageUnitVolume != null && packageUnitVolume > 0) {
        unpackUnits = unpackVolume / packageUnitVolume
      }
    }
    if (unpackUnits == null || !Number.isFinite(unpackUnits)) return '—'
    return unpackUnits.toLocaleString(undefined, { maximumFractionDigits: 3 })
  }
  if (!event.filling_lines.length) return '—'
  const totalUnits = fillingUnitsFromEvent(event.filling_lines, fillingCalculationOptions())
  if (!Number.isFinite(totalUnits)) return '—'
  return totalUnits.toLocaleString(undefined, { maximumFractionDigits: 0 })
}

function packingTankStartVolumeFromEvent(event: PackingEvent) {
  if (event.packing_type !== 'filling') return null
  if (event.tank_fill_start_volume == null) return null
  return Number.isFinite(event.tank_fill_start_volume) ? event.tank_fill_start_volume : null
}

function packingTankLeftVolumeFromEvent(event: PackingEvent) {
  if (event.packing_type !== 'filling') return null
  if (event.tank_left_volume == null) return null
  return Number.isFinite(event.tank_left_volume) ? event.tank_left_volume : null
}

function packingFillingPayoutFromEvent(event: PackingEvent) {
  if (event.packing_type === 'unpack') return eventVolumeInLiters(event)
  return derivePackingFillingPayoutFromEvent(event)
}

function packingTotalLineVolumeFromEvent(event: PackingEvent) {
  if (event.packing_type === 'unpack') {
    if (event.unpack_qty == null) return null
    return convertToLiters(event.unpack_qty, resolveUomCode(event.unpack_uom))
  }
  if (event.packing_type !== 'filling') return null
  return derivePackingTotalLineVolumeFromEvent(event, fillingCalculationOptions())
}

function packingFillingRemainingFromEvent(event: PackingEvent) {
  if (event.packing_type === 'unpack') {
    if (event.source_remaining_qty == null) return null
    return convertToLiters(event.source_remaining_qty, resolveUomCode(event.source_remaining_uom))
  }
  if (event.packing_type !== 'filling') return null
  return derivePackingFillingRemainingFromEvent(event, fillingCalculationOptions())
}

function packingLossFromEvent(event: PackingEvent) {
  if (event.packing_type === 'unpack') {
    if (event.loss_qty == null) return null
    return convertToLiters(event.loss_qty, resolveUomCode(event.loss_uom))
  }
  if (event.packing_type !== 'filling') return null
  return derivePackingLossFromEvent(event, fillingCalculationOptions())
}

function formatPackingTankStartVolume(event: PackingEvent) {
  const value = packingTankStartVolumeFromEvent(event)
  if (value == null) return '—'
  return formatVolumeValue(value)
}

function formatPackingTankLeftVolume(event: PackingEvent) {
  const value = packingTankLeftVolumeFromEvent(event)
  if (value == null) return '—'
  return formatVolumeValue(value)
}

function formatPackingFillingPayout(event: PackingEvent) {
  const value = packingFillingPayoutFromEvent(event)
  if (value == null) return '—'
  return formatVolumeValue(value)
}

function formatPackingTotalLineVolume(event: PackingEvent) {
  const value = packingTotalLineVolumeFromEvent(event)
  if (value == null) return '—'
  return formatVolumeValue(value)
}

function formatPackingFillingRemaining(event: PackingEvent) {
  const value = packingFillingRemainingFromEvent(event)
  if (value == null) return '—'
  return formatVolumeValue(value)
}

function formatPackingLoss(event: PackingEvent) {
  const value = packingLossFromEvent(event)
  if (value == null) return '—'
  return formatVolumeValue(value)
}

function relationTypeLabel(value: string) {
  const match = relationTypeOptions.value.find((option) => option.value === value)
  return match?.label ?? value
}

function batchLabel(batchIdValue: string | null | undefined) {
  if (!batchIdValue) return '—'
  const match = batchAllOptions.value.find((row) => row.value === batchIdValue)
  return match?.label ?? batchIdValue
}

function uomLabel(uomId: string | null | undefined) {
  if (!uomId) return '—'
  const match = uomOptionsRaw.value.find((row) => row.id === uomId)
  if (match) return match.name ? `${match.code} - ${match.name}` : match.code
  return uomId
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  try {
    return new Date(value).toLocaleString()
  } catch {
    return value
  }
}

function formatNumber(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return Number(value).toLocaleString(undefined, { maximumFractionDigits: 6 })
}

function asRecord(value: unknown) {
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null
  return value as Record<string, any>
}

function asArray(value: unknown) {
  return Array.isArray(value) ? value : []
}

function safeText(value: unknown) {
  if (typeof value !== 'string') return ''
  const trimmed = value.trim()
  return trimmed.length ? trimmed : ''
}

function countRowsByStepId(rows: Array<{ batch_step_id?: string | null }>) {
  const map = new Map<string, number>()
  rows.forEach((row) => {
    const stepId = typeof row.batch_step_id === 'string' ? row.batch_step_id : null
    if (!stepId) return
    map.set(stepId, (map.get(stepId) ?? 0) + 1)
  })
  return map
}

function humanizeToken(value: string | null | undefined) {
  const normalized = safeText(value)
  if (!normalized) return '—'
  return normalized
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (char) => char.toUpperCase())
}

function formatDurationSeconds(value: number | null | undefined) {
  if (value == null || Number.isNaN(Number(value))) return '—'
  const total = Math.max(0, Math.trunc(Number(value)))
  const hours = Math.floor(total / 3600)
  const minutes = Math.floor((total % 3600) / 60)
  const seconds = total % 60
  if (hours > 0) return `${hours}h ${minutes}m`
  if (minutes > 0) return `${minutes}m ${seconds}s`
  return `${seconds}s`
}

function stepStatusLabel(status: string | null | undefined) {
  switch (status) {
    case 'open':
      return t('batch.edit.stepStatusOptions.open')
    case 'ready':
      return t('batch.edit.stepStatusOptions.ready')
    case 'in_progress':
      return t('batch.edit.stepStatusOptions.inProgress')
    case 'hold':
      return t('batch.edit.stepStatusOptions.hold')
    case 'completed':
      return t('batch.edit.stepStatusOptions.completed')
    case 'skipped':
      return t('batch.edit.stepStatusOptions.skipped')
    case 'cancelled':
      return t('batch.edit.stepStatusOptions.cancelled')
    default:
      return humanizeToken(status)
  }
}

function stepStatusClass(status: string | null | undefined) {
  switch (status) {
    case 'completed':
      return 'inline-flex rounded-full bg-emerald-100 px-2 py-0.5 text-xs font-medium text-emerald-700'
    case 'in_progress':
      return 'inline-flex rounded-full bg-blue-100 px-2 py-0.5 text-xs font-medium text-blue-700'
    case 'ready':
      return 'inline-flex rounded-full bg-cyan-100 px-2 py-0.5 text-xs font-medium text-cyan-700'
    case 'hold':
      return 'inline-flex rounded-full bg-amber-100 px-2 py-0.5 text-xs font-medium text-amber-700'
    case 'cancelled':
      return 'inline-flex rounded-full bg-rose-100 px-2 py-0.5 text-xs font-medium text-rose-700'
    case 'skipped':
      return 'inline-flex rounded-full bg-slate-100 px-2 py-0.5 text-xs font-medium text-slate-700'
    default:
      return 'inline-flex rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-700'
  }
}

function showPackingNotice(message: string) {
  packingNotice.value = message
  window.setTimeout(() => {
    if (packingNotice.value === message) packingNotice.value = ''
  }, 3000)
}

function isSelectableManufacturingSite(siteId: string | null | undefined) {
  const value = siteId?.trim()
  if (!value) return false
  return siteOptions.value.some((row) => row.value === value)
}

function resolveBatchVolume(source: any): number | null {
  if (!source) return null
  if (source.actual_yield != null) {
    const uomCode = resolveUomCode(source.actual_yield_uom)
    const liters = convertToLiters(Number(source.actual_yield), uomCode)
    if (liters != null) return liters
  }
  const kpiRows = parseKpiArray(source.kpi)
  const actual = findKpiValue(kpiRows, 'volume', 'actual') ?? findKpiValue(kpiRows, 'volume_l', 'actual')
  if (actual != null) return actual
  const planned = findKpiValue(kpiRows, 'volume', 'planed') ?? findKpiValue(kpiRows, 'volume_l', 'planed')
  if (planned != null) return planned
  return resolveMetaNumber(source.meta, 'actual_product_volume')
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

function findKpiValue(rows: any[], id: string, key: 'planed' | 'actual') {
  const match = rows.find((row) => row?.id === id)
  if (!match) return null
  return toNumber(match[key])
}

function resolveMetaLabel(meta: unknown) {
  if (!meta || typeof meta !== 'object' || Array.isArray(meta)) return null
  const label = (meta as Record<string, unknown>).label
  if (typeof label !== 'string') return null
  const trimmed = label.trim()
  return trimmed.length ? trimmed : null
}

function resolveMetaString(meta: unknown, key: string) {
  if (!meta || typeof meta !== 'object' || Array.isArray(meta)) return null
  const value = (meta as Record<string, unknown>)[key]
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  return trimmed.length ? trimmed : null
}

function resolveMetaNumber(meta: unknown, key: string) {
  if (!meta || typeof meta !== 'object' || Array.isArray(meta)) return null
  const value = (meta as Record<string, unknown>)[key]
  if (value === null || value === undefined) return null
  const num = Number(value)
  return Number.isNaN(num) ? null : num
}

function resolveProduceSiteId(source: any) {
  if (!source) return null
  const meta = (source.meta && typeof source.meta === 'object' && !Array.isArray(source.meta))
    ? source.meta as Record<string, any>
    : {}
  const candidates = [
    meta.manufacturing_site_id,
    meta.manufacture_site_id,
    meta.brew_site_id,
    meta.site_id,
    meta.dest_site_id,
    meta.movement_site_id,
  ]
  for (const value of candidates) {
    if (typeof value === 'string' && value.trim()) return value.trim()
  }
  return null
}

function extractErrorMessage(err: unknown) {
  if (!err) return ''
  if (typeof err === 'string') return err
  if (err instanceof Error) return err.message
  const rec = err as Record<string, unknown>
  const message = rec.message
  if (typeof message === 'string' && message.trim()) return message
  const details = rec.details
  if (typeof details === 'string' && details.trim()) return details
  const hint = rec.hint
  if (typeof hint === 'string' && hint.trim()) return hint
  return ''
}

function buildBatchMeta(meta: unknown) {
  const base = (meta && typeof meta === 'object' && !Array.isArray(meta))
    ? { ...(meta as Record<string, unknown>) }
    : {}
  const trimmed = batchForm.batch_label.trim()
  if (trimmed) base.label = trimmed
  else delete base.label

  const related = batchForm.related_batch_id
  if (related) base.related_batch_id = related
  else delete base.related_batch_id
  return base
}

function parseJsonValue(value: string) {
  const trimmed = value.trim()
  if (!trimmed) return null
  return JSON.parse(trimmed)
}

function toNumber(value: any): number | null {
  if (value === null || value === undefined || value === '') return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function toInputDate(value: string | null | undefined) {
  return normalizeDateOnly(value)
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

function fromInputDate(value: string) {
  return normalizeDateOnly(value) || null
}

function fromInputDateTime(value: string) {
  if (!value) return null
  try {
    return new Date(value).toISOString()
  } catch {
    return value
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
  return formatVolume(value, locale.value)
}

onMounted(async () => {
  try {
    await ensureTenant()
    await Promise.all([loadBatchOptions(), loadBatchStatusOptions(), loadSites(), loadBeerCategories(), loadVolumeUoms(), loadUoms(), fetchPackageCategories(), loadPackingEvents(), loadBatchRelations()])
  } catch (err) {
    console.error(err)
  }
})
</script>
