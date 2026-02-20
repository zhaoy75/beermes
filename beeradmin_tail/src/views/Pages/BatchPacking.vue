<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div v-if="loadingBatch" class="p-6 text-sm text-gray-500">{{ t('common.loading') }}</div>
    <div v-else-if="!batch" class="p-6 text-sm text-red-600">{{ t('batch.edit.notFound') }}</div>
    <div v-else class="space-y-6">
      <section v-if="!isPackingPage" class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5">
        <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between mb-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-800">{{ t('batch.edit.infoTitle') }}</h2>
            <p class="text-xs text-gray-500">{{ t('batch.edit.infoSubtitle') }}</p>
          </div>
          <div class="flex items-center gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" @click="openActualYieldDialog">
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

        <form class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4" @submit.prevent>
          <div>
            <label class="block text-sm text-gray-600 mb-1" for="batchCode">{{ t('batch.edit.batchCode') }}</label>
            <input
              id="batchCode"
              :value="batch?.batch_code ?? '—'"
              type="text"
              class="w-full h-[40px] border rounded px-3 bg-gray-50 text-gray-600"
              readonly
            />
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
                  <input v-model="field.value" type="number" step="any" class="w-full h-[40px] border rounded px-3" />
                  <span v-if="field.uom_code" class="text-xs text-gray-500">{{ field.uom_code }}</span>
                </div>
              </template>
              <template v-else-if="field.data_type === 'boolean'">
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
            </div>
          </div>
        </div>

        <hr class="my-5 border-gray-200" />

        <div v-if="relationLoading" class="text-sm text-gray-500">{{ t('common.loading') }}</div>
        <div v-else>
          <div class="flex flex-col md:flex-row md:items-center md:justify-between gap-3 mb-4">
            <div>
              <h3 class="text-base font-semibold text-gray-800">{{ t('batch.relation.title') }}</h3>
              <p class="text-xs text-gray-500">{{ t('batch.relation.subtitle') }}</p>
            </div>
            <div class="flex items-center gap-2">
              <button class="px-3 py-2 rounded border hover:bg-gray-50" type="button" :disabled="relationLoading" @click="openRelationDialog()">
                {{ t('batch.relation.actions.add') }}
              </button>
            </div>
          </div>

          <div class="overflow-x-auto border border-gray-200 rounded-lg">
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
              <tr v-if="batchRelations.length === 0">
                <td class="px-3 py-6 text-center text-gray-500" colspan="8">{{ t('batch.relation.empty') }}</td>
              </tr>
            </tbody>
          </table>
          </div>
        </div>
      </section>

      <section class="bg-white rounded-xl shadow border border-gray-200 px-4 py-5">
        <header class="flex flex-col md:flex-row md:items-center md:justify-between gap-3 mb-4">
          <div>
            <h2 class="text-lg font-semibold text-gray-800">{{ isPackingPage ? t('batch.packaging.dialog.title') : t('batch.edit.fillingTitle') }}</h2>
            <p class="text-xs text-gray-500">
              {{
                isPackingPage
                  ? t('batch.packaging.dialog.batchSummary', { code: batch?.batch_code ?? '—', name: batchForm.batch_label || '—' })
                  : t('batch.edit.fillingSubtitle')
              }}
            </p>
          </div>
          <div class="flex items-center gap-2">
            <span v-if="packingNotice" class="text-xs text-green-600">{{ packingNotice }}</span>
            <button
              v-if="isPackingPage"
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-50"
              type="button"
              :disabled="!batchId"
              @click="backToBatchEdit"
            >
              {{ t('batch.packaging.actions.return') }}
            </button>
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-50"
              type="button"
              :disabled="!batchId"
              @click="openLotDagPage"
            >
              {{ t('batch.edit.lotDagButton') }}
            </button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="packingDialog.loading || !batch" @click="openPackingDialog">
              {{ isPackingPage ? t('common.new') : t('batch.packaging.openDialog') }}
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
              <tr
                v-for="event in packingEvents"
                :key="event.id"
                :class="[
                  'hover:bg-gray-50',
                  highlightedPackingEventId === event.id ? 'bg-emerald-50' : '',
                ]"
              >
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
                <td class="px-3 py-2 space-x-2">
                  <button
                    class="px-2 py-1 text-xs rounded border hover:bg-gray-100"
                    type="button"
                    @click="openPackingEdit(event)"
                  >
                    {{ canEditPackingEvent(event) ? t('batch.packaging.actions.edit') : t('batch.packaging.actions.view') }}
                  </button>
                  <button class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700" type="button" @click="deletePackingEvent(event)">
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
    </div>

    <div v-if="packingDialog.open && packingDialog.form" :class="isPackingPage ? 'mt-4' : 'fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4'">
      <div :class="isPackingPage ? 'w-full bg-white rounded-xl shadow border border-gray-200' : 'w-full max-w-4xl bg-white rounded-xl shadow-lg border border-gray-200'">
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
          <fieldset :disabled="packingDialog.readOnly" class="space-y-4">
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
                <div class="text-base font-semibold" :class="packingRemainingVolumeClass">
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
                  :class="packingDialog.form?.packing_type === option.value ? 'border-blue-600 bg-blue-50 text-blue-700' : 'border-gray-200 text-gray-600 hover:bg-gray-50'"
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
              <div>
                <label class="block text-sm text-gray-600 mb-1" for="packingMemo">{{ t('batch.packaging.dialog.memo') }}</label>
                <input id="packingMemo" v-model.trim="packingDialog.form.memo" type="text" class="w-full h-[40px] border rounded px-3" />
              </div>
            </div>
          </div>

          <div v-if="showPackingVolumeSection" class="border border-gray-200 rounded-lg p-3 space-y-3">
            <h4 class="text-sm font-semibold text-gray-700">{{ t('batch.packaging.dialog.volumeSection') }}</h4>
            <div class="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div>
                <label class="block text-sm text-gray-600 mb-1" for="packingVolumeQty">{{ t('batch.packaging.dialog.volumeQty') }}</label>
                <input id="packingVolumeQty" v-model="packingDialog.form.volume_qty" type="number" min="0" step="0.001" class="w-full h-[40px] border rounded px-3 text-right" />
                <p v-if="packingDialog.errors.volume_qty" class="mt-1 text-xs text-red-600">{{ packingDialog.errors.volume_qty }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1" for="packingVolumeUom">{{ t('batch.packaging.dialog.volumeUom') }}</label>
                <select id="packingVolumeUom" v-model="packingDialog.form.volume_uom" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in volumeUomOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
                <p v-if="packingDialog.errors.volume_uom" class="mt-1 text-xs text-red-600">{{ packingDialog.errors.volume_uom }}</p>
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
            </div>
            <div class="grid grid-cols-1 md:grid-cols-4 gap-3">
              <div class="md:col-span-4 md:max-w-sm">
                <label class="block text-sm text-gray-600 mb-1" for="tankNo">{{ t('batch.packaging.dialog.tankNo') }}</label>
                <select id="tankNo" v-model="packingDialog.form.tank_id" class="w-full h-[36px] border rounded px-2 bg-white">
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="option in tankOptions" :key="option.value" :value="option.value">{{ option.label }}</option>
                </select>
                <p v-if="packingDialog.errors.tank_id" class="mt-1 text-xs text-red-600">{{ packingDialog.errors.tank_id }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1" for="tankFillStartDepth">{{ t('batch.packaging.dialog.tankFillStartDepth') }}</label>
                <input id="tankFillStartDepth" v-model="packingDialog.form.tank_fill_start_depth" type="number" min="0" step="0.001" class="w-full h-[36px] border rounded px-2 text-right" />
                <p v-if="packingDialog.errors.tank_fill_start_depth" class="mt-1 text-xs text-red-600">{{ packingDialog.errors.tank_fill_start_depth }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1" for="tankFillStart">{{ t('batch.packaging.dialog.tankFillStart') }}</label>
                <input id="tankFillStart" v-model="packingDialog.form.tank_fill_start_volume" type="number" step="0.001" class="w-full h-[36px] border rounded px-2 text-right" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1" for="tankFillLeftDepth">{{ t('batch.packaging.dialog.tankFillLeftDepth') }}</label>
                <input id="tankFillLeftDepth" v-model="packingDialog.form.tank_fill_left_depth" type="number" min="0" step="0.001" class="w-full h-[36px] border rounded px-2 text-right" />
                <p v-if="packingDialog.errors.tank_fill_left_depth" class="mt-1 text-xs text-red-600">{{ packingDialog.errors.tank_fill_left_depth }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1" for="tankLeft">{{ t('batch.packaging.dialog.tankLeft') }}</label>
                <input id="tankLeft" v-model="packingDialog.form.tank_left_volume" type="number" step="0.001" class="w-full h-[36px] border rounded px-2 text-right" />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1" for="sampleVolume">{{ t('batch.packaging.dialog.sampleVolume') }}</label>
                <input id="sampleVolume" v-model="packingDialog.form.sample_volume" type="number" min="0" step="0.001" class="w-full h-[36px] border rounded px-2 text-right bg-gray-50 text-gray-600" readonly />
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('batch.packaging.dialog.tankLoss') }}</label>
                <input :value="tankLossVolumeText" type="text" class="w-full h-[36px] border rounded px-2 text-right bg-gray-50 text-gray-600" readonly />
              </div>
            </div>
            <hr class="border-gray-200" />
            <div v-if="packingDialog.errors.filling_lines" class="text-xs text-red-600">{{ packingDialog.errors.filling_lines }}</div>
            <div class="flex items-center justify-end">
              <button class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-100" type="button" @click="addFillingLine">
                {{ t('batch.packaging.dialog.addFilling') }}
              </button>
            </div>
            <div class="overflow-x-auto border border-gray-200 rounded-lg">
              <table class="min-w-full text-sm divide-y divide-gray-200">
                <thead class="bg-gray-50 text-gray-600 uppercase text-xs">
                  <tr>
                    <th class="px-3 py-2 text-left">{{ t('batch.packaging.dialog.fillingTable.packageType') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('batch.packaging.dialog.fillingTable.lotCode') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('batch.packaging.dialog.fillingTable.input') }}</th>
                    <th class="px-3 py-2 text-center">{{ t('batch.packaging.dialog.fillingTable.sampleFlg') }}</th>
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
                    <td class="px-3 py-2">
                      <input v-model.trim="line.lot_code" type="text" class="w-full h-[36px] border rounded px-2" />
                    </td>
                    <td class="px-3 py-2 text-right">
                      <input
                        v-if="isPackageVolumeFixed(line.package_type_id)"
                        v-model="line.qty"
                        type="number"
                        min="1"
                        step="1"
                        class="w-full h-[36px] border rounded px-2 text-right"
                      />
                      <input
                        v-else
                        v-model="line.volume"
                        type="number"
                        min="0"
                        step="0.001"
                        class="w-full h-[36px] border rounded px-2 text-right"
                      />
                    </td>
                    <td class="px-3 py-2 text-center">
                      <input v-model="line.sample_flg" type="checkbox" class="h-4 w-4" />
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
                    <td class="px-3 py-4 text-center text-gray-500" colspan="7">{{ t('batch.packaging.dialog.noFillingLines') }}</td>
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
          </fieldset>
        </div>
        <footer class="flex items-center justify-end gap-2 px-4 py-3 border-t">
          <button class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100" type="button" :disabled="packingDialog.loading" @click="closePackingDialog">
            {{ packingDialog.readOnly ? t('common.close') : t('batch.packaging.dialog.cancel') }}
          </button>
          <button v-if="!packingDialog.readOnly" class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50" type="button" :disabled="packingDialog.loading" @click="savePackingEvent(false)">
            {{ packingDialog.loading ? t('common.saving') : t('batch.packaging.dialog.save') }}
          </button>
        </footer>
      </div>
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
              <input id="actualYieldDialogQty" v-model="actualYieldDialog.form.actual_yield" type="number" min="0" step="0.000001" class="w-full h-[40px] border rounded px-3 text-right" />
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
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()

const batchId = computed(() => route.params.batchId as string | undefined)
const isPackingPage = computed(() => route.name === 'batchPacking')
const pageTitle = computed(() => (isPackingPage.value ? t('batch.packaging.dialog.title') : t('batch.edit.title')))
const ZERO_UUID = '00000000-0000-0000-0000-000000000000'

const tenantId = ref<string | null>(null)
const batch = ref<any>(null)
const loadingBatch = ref(false)
const savingBatch = ref(false)

const batchForm = reactive({
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
    uom_id: string | null
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
  ref_kind: string | null
  ref_domain: string | null
  value: any
  options: Array<{ value: string | number, label: string }>
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
  max_volume: number | null
  volume_fix_flg: boolean | null
  volume_uom: string | null
}

interface SiteOption {
  value: string
  label: string
}

interface TankOption {
  value: string
  code: string
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

type PackingType = 'ship' | 'filling' | 'transfer' | 'loss' | 'dispose'

type PackingFillingLine = {
  id: string
  package_type_id: string
  qty: number
  volume: number | null
  lot_code?: string | null
  sample_flg: boolean
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
  tank_id: string | null
  tank_no: string | null
  tank_fill_start_depth: number | null
  tank_fill_start_volume: number | null
  tank_fill_left_depth: number | null
  tank_left_volume: number | null
  sample_volume: number | null
}

type PackingFillingLineForm = {
  id: string
  package_type_id: string
  qty: string
  volume: string
  lot_code: string
  sample_flg: boolean
}

type PackingFormState = {
  id?: string
  packing_type: PackingType
  event_time: string
  memo: string
  volume_qty: string
  volume_uom: string
  movement_site_id: string
  movement_qty: string
  movement_memo: string
  filling_lines: PackingFillingLineForm[]
  reason: string
  tank_id: string
  tank_fill_start_depth: string
  tank_fill_start_volume: string
  tank_fill_left_depth: string
  tank_left_volume: string
  sample_volume: string
}

const packageCategories = ref<PackageCategoryOption[]>([])
const tankOptions = ref<TankOption[]>([])
const siteOptions = ref<SiteOption[]>([])
const volumeUoms = ref<VolumeUomOption[]>([])
const uomOptionsRaw = ref<UomOption[]>([])
const packingEvents = ref<PackingEvent[]>([])
const packingNotice = ref('')
const highlightedPackingEventId = ref('')
let highlightedPackingTimer: number | null = null
const packingMovementQtyTouched = ref(false)
const DEFAULT_TANK_TEMPERATURE_C = 20
const TANK_VOLUME_CALC_DEBOUNCE_MS = 250
const tankVolumeRequestToken = reactive({ start: 0, left: 0 })
let tankVolumeStartTimer: number | null = null
let tankVolumeLeftTimer: number | null = null
const packingDialog = reactive({
  open: false,
  editing: false,
  readOnly: false,
  loading: false,
  globalError: '',
  errors: {} as Record<string, string>,
  form: null as PackingFormState | null,
})

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

function resolveLang() {
  return String(locale.value ?? '').toLowerCase().startsWith('ja') ? 'ja' : 'en'
}

function resolveNameI18n(value: Record<string, string> | null | undefined) {
  if (!value) return ''
  const lang = resolveLang()
  if (value[lang]) return value[lang]
  const fallback = Object.values(value)[0]
  return fallback ?? ''
}

function resolveUomCode(value: string | null | undefined) {
  if (!value) return null
  const byId = volumeUoms.value.find((row) => row.id === value)
  if (byId) return byId.code
  const byCode = volumeUoms.value.find((row) => row.code === value)
  if (byCode) return byCode.code
  return value
}

function resolveUomId(value: string | null | undefined) {
  if (!value) return ''
  const byId = volumeUoms.value.find((row) => row.id === value)
  if (byId) return byId.id
  const byCode = volumeUoms.value.find((row) => row.code === value)
  if (byCode) return byCode.id
  return value
}

function defaultVolumeUomId() {
  const preferred = volumeUoms.value.find((row) => row.code === 'L')?.id
  return preferred || volumeUoms.value[0]?.id || ''
}



function formVolumeInLiters(form: PackingFormState) {
  const qty = toNumber(form.volume_qty)
  if (qty == null) return null
  return convertToLiters(qty, resolveUomCode(form.volume_uom))
}

function eventVolumeInLiters(event: PackingEvent) {
  if (event.volume_qty == null) return null
  return convertToLiters(event.volume_qty, resolveUomCode(event.volume_uom))
}

function resolvePackageOption(packageTypeId: string) {
  return packageCategories.value.find((item) => item.id === packageTypeId)
}

function isPackageVolumeFixed(packageTypeId: string) {
  const row = resolvePackageOption(packageTypeId)
  if (!row) return true
  return row.volume_fix_flg !== false
}

function resolveFillingLineVolumeFromForm(line: PackingFillingLineForm) {
  if (!line.package_type_id) return null
  if (isPackageVolumeFixed(line.package_type_id)) {
    const qty = toNumber(line.qty)
    const unitVolume = resolvePackageUnitVolume(line.package_type_id)
    if (qty == null || unitVolume == null) return null
    return qty * unitVolume
  }
  const inputVolume = toNumber(line.volume)
  if (inputVolume == null) return null
  return inputVolume
}

function resolveFillingLineVolumeFromEvent(line: PackingFillingLine) {
  if (!line.package_type_id) return null
  if (isPackageVolumeFixed(line.package_type_id)) {
    const unit = resolvePackageUnitVolume(line.package_type_id)
    if (unit == null) return null
    return (line.qty ?? 0) * unit
  }
  if (line.volume != null && Number.isFinite(line.volume)) return line.volume
  if (line.qty != null && Number.isFinite(line.qty)) return line.qty
  return null
}

function fillingLinesVolumeFromEvent(lines: PackingFillingLine[]) {
  return lines.reduce((sum, line) => {
    if (line.sample_flg) return sum
    const volume = resolveFillingLineVolumeFromEvent(line)
    if (volume == null) return sum
    return sum + volume
  }, 0)
}

function fillingSampleVolumeFromEvent(lines: PackingFillingLine[]) {
  return lines.reduce((sum, line) => {
    if (!line.sample_flg) return sum
    const volume = resolveFillingLineVolumeFromEvent(line)
    if (volume == null) return sum
    return sum + volume
  }, 0)
}

function processedVolumeFromPackingEvent(event: PackingEvent) {
  if (event.packing_type === 'filling') {
    let total = 0
    const qty = event.movement?.qty
    if (qty != null && Number.isFinite(qty)) total += qty
    const sample = event.sample_volume ?? fillingSampleVolumeFromEvent(event.filling_lines)
    if (Number.isFinite(sample)) total += sample
    if (event.tank_fill_start_volume != null && event.tank_left_volume != null) {
      const totalFillVolume = fillingLinesVolumeFromEvent(event.filling_lines)
      const loss = event.tank_fill_start_volume - event.tank_left_volume - totalFillVolume - sample
      if (Number.isFinite(loss)) total += loss
    }
    return total
  }
  const volume = eventVolumeInLiters(event)
  if (volume != null) return volume
  if (event.movement?.qty != null && Number.isFinite(event.movement.qty)) return event.movement.qty
  return 0
}

function processedVolumeFromPackingForm(form: PackingFormState) {
  if (form.packing_type === 'filling') {
    let total = 0
    const fillingTotals = computeFillingTotals(form.filling_lines)
    const movementQty = toNumber(form.movement_qty)
    if (movementQty != null && Number.isFinite(movementQty)) {
      total += movementQty
    } else if (fillingTotals.totalVolume != null && Number.isFinite(fillingTotals.totalVolume)) {
      total += fillingTotals.totalVolume
    }
    const sample = toNumber(form.sample_volume) ?? computeFillingSampleVolume(form.filling_lines)
    if (Number.isFinite(sample)) total += sample
    const start = toNumber(form.tank_fill_start_volume)
    const left = toNumber(form.tank_left_volume)
    if (start != null && left != null && fillingTotals.totalVolume != null) {
      const loss = start - left - fillingTotals.totalVolume - sample
      if (Number.isFinite(loss)) total += loss
    }
    return total
  }
  const volume = formVolumeInLiters(form)
  if (volume != null) return volume
  const movementQty = toNumber(form.movement_qty)
  if (movementQty != null && Number.isFinite(movementQty)) return movementQty
  return 0
}

function defaultPackageId() {
  // TODO: confirm mapping for volume-only events; fallback to first package for now.
  return packageCategories.value[0]?.id ?? ''
}

function resolveLitersUomId() {
  return volumeUoms.value.find((row) => row.code === 'L')?.id ?? defaultVolumeUomId()
}

function mapPackingDocType(type: PackingType) {
  switch (type) {
    case 'filling':
      return 'production_receipt'
    case 'ship':
      return 'sale'
    case 'transfer':
      return 'transfer'
    case 'loss':
      return 'adjustment'
    case 'dispose':
      return 'waste'
    default:
      return 'adjustment'
  }
}

const packingTypeOptions = computed(() => ([
  { value: 'filling', label: t('batch.packaging.types.filling') },
  { value: 'ship', label: t('batch.packaging.types.ship') },
  { value: 'transfer', label: t('batch.packaging.types.transfer') },
  { value: 'loss', label: t('batch.packaging.types.loss') },
  { value: 'dispose', label: t('batch.packaging.types.dispose') },
] as Array<{ value: PackingType, label: string }>))

const packageCategoryOptions = computed(() =>
  packageCategories.value.map((row) => ({
    value: row.id,
    label: formatPackageLabel(row),
  }))
)

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

function formatPackageLabel(row: PackageCategoryOption) {
  const name = resolveNameI18n(row.name_i18n)
  const namePart = name ? ` — ${name}` : ''
  const unitVolume = row.unit_volume != null ? convertToLiters(row.unit_volume, resolveUomCode(row.volume_uom)) : null
  const sizePart = unitVolume != null ? ` (${unitVolume.toLocaleString(undefined, { maximumFractionDigits: 2 })} L)` : ''
  return `${row.package_code}${namePart}${sizePart}`
}

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

const persistedProcessedVolume = computed(() => {
  if (!packingEvents.value.length) return 0
  return packingEvents.value.reduce((sum, event) => sum + processedVolumeFromPackingEvent(event), 0)
})

const draftProcessedDelta = computed(() => {
  if (!packingDialog.open || !packingDialog.form || packingDialog.readOnly) return 0
  const draftProcessed = processedVolumeFromPackingForm(packingDialog.form)
  if (!packingDialog.form.id) return draftProcessed
  const existing = packingEvents.value.find((event) => event.id === packingDialog.form?.id)
  const existingProcessed = existing ? processedVolumeFromPackingEvent(existing) : 0
  return draftProcessed - existingProcessed
})

const packingProcessedVolume = computed(() => {
  return persistedProcessedVolume.value + draftProcessedDelta.value
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

const packingFillingSampleVolume = computed(() => {
  const lines = packingDialog.form?.filling_lines ?? []
  return computeFillingSampleVolume(lines)
})

const tankLossVolume = computed(() => {
  if (!packingDialog.form) return null
  const start = toNumber(packingDialog.form.tank_fill_start_volume)
  const left = toNumber(packingDialog.form.tank_left_volume)
  const sample = toNumber(packingDialog.form.sample_volume) ?? 0
  const total = packingFillingTotals.value.totalVolume
  if (start == null || left == null || total == null) return null
  return start - left - total - sample
})

const tankLossVolumeText = computed(() => {
  if (tankLossVolume.value == null) return '—'
  return formatVolumeValue(tankLossVolume.value)
})

const reviewVolumeText = computed(() => {
  if (!packingDialog.form) return '—'
  if (packingDialog.form.packing_type === 'filling') {
    const total = packingFillingTotals.value.totalVolume
    return total != null ? formatVolumeValue(total) : '—'
  }
  if (!showPackingVolumeSection.value) return '—'
  const qty = formVolumeInLiters(packingDialog.form)
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
    const volumeQty = formVolumeInLiters(packingDialog.form)
    if (volumeQty != null && Math.abs(movementQty - volumeQty) > 0.0001) {
      return t('batch.packaging.warnings.movementMismatch')
    }
  }
  return ''
})

function attrLabel(field: AttrField) {
  const lang = locale.value?.toString().toLowerCase().startsWith('ja') ? 'ja' : 'en'
  const label = field.name_i18n?.[lang]
  return label || field.name || field.code
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

watch(isPackingPage, (enabled) => {
  if (enabled) {
    syncPackingPageEditor()
    return
  }
  if (packingDialog.open) {
    packingDialog.open = false
    packingDialog.form = null
    packingDialog.readOnly = false
    packingDialog.errors = {}
    packingDialog.globalError = ''
  }
})

watch(
  () => route.query.eventId,
  () => {
    if (isPackingPage.value) syncPackingPageEditor()
  }
)

async function fetchBatch() {
  if (!batchId.value) return
  try {
    loadingBatch.value = true
    await ensureTenant()
    await Promise.all([loadBatchOptions(), loadBatchStatusOptions(), loadSites(), loadTankOptions(), fetchPackageCategories(), loadVolumeUoms(), loadUoms()])
    const { data, error } = await supabase.rpc('batch_get_detail', {
      p_batch_id: batchId.value,
    })
    if (error) throw error
    const detail = (data ?? null) as any
    const header = detail?.batch ?? null
    batch.value = header
    if (header) {
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
      await loadPackingEvents()
      await loadBatchAttributes(header.id)
    } else {
      attrFields.value = []
      packingEvents.value = []
      batchRelations.value = []
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
      .select('attr_id, required, sort_order, is_active, attr_def:attr_def!fk_attr_set_rule_attr(attr_id, code, name, name_i18n, data_type, uom_id, ref_kind, ref_domain)')
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
        const { data, error } = await supabase
          .from('registry_def')
          .select('def_id, def_key, spec')
          .eq('kind', domain)
          .eq('is_active', true)
          .order('def_key', { ascending: true })
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
      const attr = (row as AttrRuleRow).attr_def
      if (!attr) continue
      const valueRow = valueMap.get(attr.attr_id)
      let value: any = ''
      if (attr.data_type === 'number') value = valueRow?.value_num ?? ''
      else if (attr.data_type === 'boolean') value = valueRow?.value_bool ?? false
      else if (attr.data_type === 'date') value = valueRow?.value_date ?? ''
      else if (attr.data_type === 'timestamp') value = toInputDateTime(valueRow?.value_ts)
      else if (attr.data_type === 'json') value = valueRow?.value_json ? JSON.stringify(valueRow.value_json, null, 2) : ''
      else if (attr.data_type === 'ref') {
        if (attr.ref_kind === 'registry_def') value = valueRow?.value_json?.def_id ?? ''
        else value = valueRow?.value_ref_type_id ?? ''
      } else value = valueRow?.value_text ?? ''

      const optionsKey = attr.ref_kind && attr.ref_domain ? `${attr.ref_kind}:${attr.ref_domain}` : ''
      fields.push({
        attr_id: attr.attr_id,
        code: attr.code,
        name: attr.name,
        name_i18n: attr.name_i18n ?? null,
        data_type: attr.data_type,
        required: Boolean((row as AttrRuleRow).required),
        uom_id: attr.uom_id ?? null,
        uom_code: attr.uom_id ? uomMap.get(String(attr.uom_id)) ?? null : null,
        ref_kind: attr.ref_kind ?? null,
        ref_domain: attr.ref_domain ?? null,
        value,
        options: optionsKey ? refOptions.get(optionsKey) ?? [] : [],
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

async function saveBatchAttributes(batchUuid: string) {
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
    else if (field.data_type === 'boolean') row.value_bool = Boolean(field.value)
    else if (field.data_type === 'date') row.value_date = field.value
    else if (field.data_type === 'timestamp') row.value_ts = fromInputDateTime(String(field.value))
    else if (field.data_type === 'json') row.value_json = parseJsonSafe(String(field.value))
    else if (field.data_type === 'ref') {
      if (field.ref_kind === 'registry_def') {
        row.value_json = { def_id: field.value, kind: field.ref_domain }
      } else {
        row.value_ref_type_id = Number(field.value)
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
    const { data, error } = await supabase
      .from('mst_sites')
      .select('id, name')
      .eq('tenant_id', tenant)
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

async function loadTankOptions() {
  try {
    const tenant = await ensureTenant()
    const { data: tankRows, error: tankError } = await supabase
      .from('mst_equipment_tank')
      .select('equipment_id')
    if (tankError) throw tankError
    const tankIds = (tankRows ?? [])
      .map((row: any) => row.equipment_id)
      .filter((value: any): value is string => typeof value === 'string' && value.length > 0)
    if (!tankIds.length) {
      tankOptions.value = []
      return
    }
    const { data: equipmentRows, error: equipmentError } = await supabase
      .from('mst_equipment')
      .select('id, equipment_code, name_i18n, equipment_kind, is_active')
      .eq('tenant_id', tenant)
      .eq('equipment_kind', 'tank')
      .eq('is_active', true)
      .in('id', tankIds)
      .order('equipment_code')
    if (equipmentError) throw equipmentError
    tankOptions.value = (equipmentRows ?? []).map((row: any) => {
      const code = String(row.equipment_code ?? row.id)
      const name = resolveNameI18n(row.name_i18n ?? null)
      return {
        value: String(row.id),
        code,
        label: name ? `${code} - ${name}` : code,
      }
    })
  } catch (err) {
    console.error(err)
    tankOptions.value = []
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
      syncPackingPageEditor()
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
      const rawTankNo = meta.tank_no != null ? String(meta.tank_no) : null
      const rawTankId = meta.tank_id != null ? String(meta.tank_id) : null
      const tankId = rawTankId || (rawTankNo && isUuidLike(rawTankNo) ? rawTankNo : null)
      const fillingLines = Array.isArray(meta.filling_lines)
        ? meta.filling_lines.map((line: any) => ({
          id: String(line?.id ?? generateLocalId()),
          package_type_id: String(line?.package_type_id ?? ''),
          qty: toNumber(line?.qty) ?? 0,
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
        tank_id: tankId,
        tank_no: rawTankNo,
        tank_fill_start_depth: meta.tank_fill_start_depth != null ? toNumber(meta.tank_fill_start_depth) : null,
        tank_fill_start_volume: meta.tank_fill_start_volume != null ? toNumber(meta.tank_fill_start_volume) : null,
        tank_fill_left_depth: meta.tank_fill_left_depth != null ? toNumber(meta.tank_fill_left_depth) : null,
        tank_left_volume: meta.tank_left_volume != null ? toNumber(meta.tank_left_volume) : null,
        sample_volume: meta.sample_volume != null ? toNumber(meta.sample_volume) : null,
      } as PackingEvent
    })
    syncPackingPageEditor()
  } catch (err) {
    console.error(err)
    packingEvents.value = []
    syncPackingPageEditor()
  }
}

async function fetchPackageCategories() {
  try {
    let { data, error } = await supabase
      .from('mst_package')
      .select('id, package_code, name_i18n, unit_volume, max_volume, volume_fix_flg, volume_uom, is_active')
      .eq('is_active', true)
      .order('package_code', { ascending: true })
    if (error) {
      const fallback = await supabase
        .from('mst_package')
        .select('id, package_code, name_i18n, unit_volume, volume_uom, is_active')
        .eq('is_active', true)
        .order('package_code', { ascending: true })
      data = fallback.data as any
      error = fallback.error
    }
    if (error) throw error
    packageCategories.value = (data ?? []).map((row: any) => ({
      id: row.id,
      package_code: row.package_code,
      name_i18n: row.name_i18n ?? null,
      unit_volume: row.unit_volume != null ? Number(row.unit_volume) : null,
      max_volume: row.max_volume != null ? Number(row.max_volume) : null,
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
    const meta = buildBatchMeta(batch.value?.meta)
    const trimmedBatchLabel = batchForm.batch_label.trim()
    const update: Record<string, any> = {
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
    if (error) throw error
    await saveBatchAttributes(batchId.value)
    await fetchBatch()
  } catch (err) {
    console.error(err)
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
  actualYieldDialog.open = true
  actualYieldDialog.loading = false
  actualYieldDialog.globalError = ''
  actualYieldDialog.errors = {}
  actualYieldDialog.form.actual_yield = batchForm.actual_yield
  actualYieldDialog.form.actual_yield_uom = batchForm.actual_yield_uom || defaultVolumeUomId()
  actualYieldDialog.form.site_id = resolveProduceSiteId(batch.value) || ''
}

function closeActualYieldDialog() {
  if (actualYieldDialog.loading) return
  actualYieldDialog.open = false
  actualYieldDialog.globalError = ''
  actualYieldDialog.errors = {}
}

async function saveActualYieldDialog() {
  const errors: Record<string, string> = {}
  const qty = toNumber(actualYieldDialog.form.actual_yield)
  const uomId = actualYieldDialog.form.actual_yield_uom
  const siteId = actualYieldDialog.form.site_id
  if (qty == null || qty <= 0) errors.actual_yield = t('batch.edit.actualYieldRequired')
  if (!uomId) errors.actual_yield_uom = t('batch.edit.actualYieldUomRequired')
  if (!siteId) errors.site_id = t('batch.edit.actualYieldSiteRequired')
  if (Object.keys(errors).length) {
    actualYieldDialog.errors = errors
    return
  }
  if (!batchId.value || !batch.value) {
    actualYieldDialog.globalError = t('batch.edit.actualYieldSaveFailed')
    return
  }

  actualYieldDialog.loading = true
  actualYieldDialog.globalError = ''
  try {
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
    if (batchSaveError) throw batchSaveError

    batchForm.actual_yield = String(qty)
    batchForm.actual_yield_uom = uomId
    batch.value.actual_yield = qty
    batch.value.actual_yield_uom = uomId
    batch.value.meta = patch.meta

    const movementAt = batch.value.actual_end
      ? new Date(batch.value.actual_end).toISOString()
      : new Date().toISOString()
    const batchCode = String(batch.value.batch_code ?? 'BATCH')
    const normalizedQty = Number(qty).toFixed(6)
    const idempotencyKey = `batch_actual_yield:${batchId.value}:${normalizedQty}:${uomId}`
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
    if (produceError) {
      const detail = extractErrorMessage(produceError)
      actualYieldDialog.globalError = detail
        ? `${t('batch.edit.actualYieldProduceFailed')} (${detail})`
        : t('batch.edit.actualYieldProduceFailed')
      return
    }

    actualYieldDialog.open = false
    actualYieldDialog.errors = {}
    actualYieldDialog.globalError = ''
    showPackingNotice(t('batch.edit.actualYieldSaved'))
  } catch (err) {
    const detail = extractErrorMessage(err)
    actualYieldDialog.globalError = detail
      ? `${t('batch.edit.actualYieldSaveFailed')} (${detail})`
      : t('batch.edit.actualYieldSaveFailed')
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
    query: { from: 'packing' },
  })
}

async function backToBatchEdit() {
  if (!batchId.value) return
  const form = packingDialog.form
  if (packingDialog.open && !packingDialog.readOnly && form && isPackingFormDirty(form)) {
    if (!window.confirm(t('batch.packaging.dialog.closeConfirm'))) return
  }
  await router.push({
    name: 'batchEdit',
    params: { batchId: batchId.value },
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

function openPackingDialogInternal(type: PackingType) {
  packingDialog.open = true
  packingDialog.editing = false
  packingDialog.readOnly = false
  packingDialog.loading = false
  packingDialog.globalError = ''
  packingDialog.errors = {}
  packingDialog.form = newPackingForm(type)
  packingMovementQtyTouched.value = false
}

async function openPackingDialog() {
  if (!isPackingPage.value) {
    await goToPackingPage()
    return
  }
  if (!packingDialog.readOnly && packingDialog.form && isPackingFormDirty(packingDialog.form)) {
    if (!window.confirm(t('batch.packaging.dialog.typeChangeConfirm'))) return
  }
  if (routeEventId()) await clearPackingEventQuery()
  openPackingDialogInternal('filling')
}

function canEditPackingEvent(event: PackingEvent) {
  return event.packing_type !== 'filling' && event.packing_type !== 'transfer' && event.packing_type !== 'ship'
}

function openPackingEditInternal(event: PackingEvent, readOnly = false) {
  packingDialog.open = true
  packingDialog.editing = !readOnly
  packingDialog.readOnly = readOnly
  packingDialog.loading = false
  packingDialog.globalError = ''
  packingDialog.errors = {}
  packingDialog.form = {
    id: event.id,
    packing_type: event.packing_type,
    event_time: toInputDateTime(event.event_time),
    memo: event.memo ?? '',
    volume_qty: event.volume_qty != null ? String(event.volume_qty) : '',
    volume_uom: resolveUomId(event.volume_uom) || defaultVolumeUomId(),
    movement_site_id: event.movement?.site_id ?? '',
    movement_qty: event.movement?.qty != null ? String(event.movement.qty) : '',
    movement_memo: event.movement?.memo ?? '',
    filling_lines: event.filling_lines.map((line) => ({
      id: line.id ?? generateLocalId(),
      package_type_id: line.package_type_id,
      qty: String(line.qty ?? ''),
      volume: line.volume != null
        ? String(line.volume)
        : (!isPackageVolumeFixed(line.package_type_id) && line.qty != null ? String(line.qty) : ''),
      lot_code: line.lot_code ?? '',
      sample_flg: Boolean(line.sample_flg),
    })),
    reason: event.reason ?? '',
    tank_id: event.tank_id ?? resolveTankIdByCode(event.tank_no) ?? '',
    tank_fill_start_depth: event.tank_fill_start_depth != null ? String(event.tank_fill_start_depth) : '0',
    tank_fill_start_volume: event.tank_fill_start_volume != null ? String(event.tank_fill_start_volume) : '',
    tank_fill_left_depth: event.tank_fill_left_depth != null ? String(event.tank_fill_left_depth) : '0',
    tank_left_volume: event.tank_left_volume != null ? String(event.tank_left_volume) : '',
    sample_volume: event.sample_volume != null ? String(event.sample_volume) : '',
  }
  packingMovementQtyTouched.value = true
}

function openPackingEdit(event: PackingEvent) {
  if (!isPackingPage.value) {
    void goToPackingPage(event.id)
    return
  }
  openPackingEditInternal(event, !canEditPackingEvent(event))
}

function closePackingDialog() {
  const form = packingDialog.form
  if (!packingDialog.readOnly && form && isPackingFormDirty(form)) {
    if (!window.confirm(t('batch.packaging.dialog.closeConfirm'))) return
  }
  packingDialog.open = false
  packingDialog.form = null
  packingDialog.editing = false
  packingDialog.readOnly = false
  packingDialog.errors = {}
  packingDialog.globalError = ''
  if (isPackingPage.value && routeEventId()) void clearPackingEventQuery()
}

function isPackingFormDirty(form: PackingFormState) {
  return Boolean(
    form.memo ||
    form.volume_qty ||
    form.volume_uom ||
    form.movement_site_id ||
    form.movement_qty ||
    form.movement_memo ||
    form.reason ||
    form.tank_id ||
    form.tank_fill_start_depth ||
    form.tank_fill_start_volume ||
    form.tank_fill_left_depth ||
    form.tank_left_volume ||
    form.sample_volume ||
    (form.filling_lines && form.filling_lines.length)
  )
}

function routeEventId() {
  const queryValue = route.query.eventId
  return typeof queryValue === 'string' && queryValue ? queryValue : ''
}

async function clearPackingEventQuery() {
  if (!isPackingPage.value) return
  if (!batchId.value) return
  if (!route.query.eventId) return
  const nextQuery = { ...route.query }
  delete nextQuery.eventId
  await router.replace({
    name: 'batchPacking',
    params: { batchId: batchId.value },
    query: nextQuery,
  })
}

function syncPackingPageEditor() {
  if (!isPackingPage.value) return
  const eventId = routeEventId()
  if (eventId) {
    const target = packingEvents.value.find((row) => row.id === eventId)
    if (target) {
      openPackingEditInternal(target, !canEditPackingEvent(target))
      return
    }
  }
  packingDialog.open = false
  packingDialog.form = null
  packingDialog.editing = false
  packingDialog.readOnly = false
  packingDialog.errors = {}
  packingDialog.globalError = ''
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
    form.volume_uom = defaultVolumeUomId()
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
  if (form.packing_type !== 'filling') {
    form.tank_id = ''
    form.tank_fill_start_depth = '0'
    form.tank_fill_start_volume = ''
    form.tank_fill_left_depth = '0'
    form.tank_left_volume = ''
    form.sample_volume = ''
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
    volume: '',
    lot_code: '',
    sample_flg: false,
  })
}

function removeFillingLine(index: number) {
  if (!packingDialog.form) return
  packingDialog.form.filling_lines.splice(index, 1)
}

function isUuidLike(value: string) {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value)
}

async function calculateTankVolume(target: 'start' | 'left') {
  if (!packingDialog.form || packingDialog.form.packing_type !== 'filling') return
  if (packingDialog.readOnly) return
  const tankId = packingDialog.form.tank_id
  if (!tankId) return
  const depth = target === 'start'
    ? toNumber(packingDialog.form.tank_fill_start_depth)
    : toNumber(packingDialog.form.tank_fill_left_depth)
  if (depth == null || depth < 0) return

  const token = ++tankVolumeRequestToken[target]
  try {
    const { data, error } = await supabase.rpc('get_volume_by_tank', {
      p_tank_id: tankId,
      p_depth_mm: depth,
      p_temperature_c: DEFAULT_TANK_TEMPERATURE_C,
    })
    if (error) throw error
    if (token !== tankVolumeRequestToken[target]) return
    const volume = toNumber(data)
    if (volume == null) return
    if (!packingDialog.form) return
    if (target === 'start') {
      packingDialog.form.tank_fill_start_volume = String(volume)
    } else {
      packingDialog.form.tank_left_volume = String(volume)
    }
  } catch (err) {
    console.error(err)
    const key = target === 'start' ? 'tank_fill_start_depth' : 'tank_fill_left_depth'
    packingDialog.errors[key] = t('batch.packaging.errors.tankVolumeCalcFailed')
  }
}

function scheduleTankVolumeCalc(target: 'start' | 'left') {
  if (target === 'start') {
    if (tankVolumeStartTimer != null) window.clearTimeout(tankVolumeStartTimer)
    tankVolumeStartTimer = window.setTimeout(() => {
      tankVolumeStartTimer = null
      void calculateTankVolume('start')
    }, TANK_VOLUME_CALC_DEBOUNCE_MS)
    return
  }
  if (tankVolumeLeftTimer != null) window.clearTimeout(tankVolumeLeftTimer)
  tankVolumeLeftTimer = window.setTimeout(() => {
    tankVolumeLeftTimer = null
    void calculateTankVolume('left')
  }, TANK_VOLUME_CALC_DEBOUNCE_MS)
}

function markMovementQtyTouched() {
  packingMovementQtyTouched.value = true
}

async function savePackingEvent(addAnother: boolean) {
  if (packingDialog.readOnly) return
  if (!packingDialog.form || !batchId.value) return
  packingDialog.errors = {}
  packingDialog.globalError = ''
  const errors = validatePackingForm(packingDialog.form)
  if (Object.keys(errors).length) {
    packingDialog.errors = errors
    return
  }
  try {
    const savedEventId = packingDialog.form.id ?? null
    const savedType = packingDialog.form.packing_type
    const wasEditing = packingDialog.editing
    packingDialog.loading = true
    await persistPackingEvent(packingDialog.form, packingDialog.editing)
    await loadPackingEvents()
    showPackingNotice(t('batch.packaging.toast.saved'))
    const highlightId = wasEditing
      ? savedEventId
      : (packingEvents.value[packingEvents.value.length - 1]?.id ?? null)
    if (highlightId) highlightPackingEvent(highlightId)
    if (addAnother) {
      packingDialog.open = true
      packingDialog.form = newPackingForm(savedType)
      packingDialog.editing = false
      packingDialog.readOnly = false
      packingMovementQtyTouched.value = false
    } else {
      packingDialog.open = false
      packingDialog.form = null
      packingDialog.editing = false
      packingDialog.readOnly = false
      if (isPackingPage.value && routeEventId()) void clearPackingEventQuery()
    }
  } catch (err) {
    console.error(err)
    const detail = extractErrorMessage(err)
    packingDialog.globalError = detail
      ? `${t('batch.packaging.errors.saveFailed')} (${detail})`
      : t('batch.packaging.errors.saveFailed')
  } finally {
    packingDialog.loading = false
  }
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
  if (!window.confirm(t('batch.relation.confirmDelete'))) return
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
  if (!window.confirm(t('batch.packaging.confirmDelete'))) return
  try {
    const { error } = await supabase
      .from('inv_movements')
      .update({ status: 'void' })
      .eq('id', event.id)
    if (error) throw error
    await loadPackingEvents()
    if (highlightedPackingEventId.value === event.id) clearHighlightedPackingEvent()
    showPackingNotice(t('batch.packaging.toast.deleted'))
  } catch (err) {
    console.error(err)
    packingDialog.globalError = t('batch.packaging.errors.deleteFailed')
  }
}

type RootSourceLot = {
  id: string
  uom_id: string
  site_id: string
}

async function resolveRootSourceLot(batchIdValue: string, preferredSiteId?: string | null): Promise<RootSourceLot | null> {
  const { data: candidates, error: candidateError } = await supabase
    .from('lot')
    .select('id, uom_id, site_id')
    .eq('batch_id', batchIdValue)
    .neq('status', 'void')
    .gt('qty', 0)
    .order('produced_at', { ascending: false })
    .order('created_at', { ascending: false })
    .limit(50)
  let filteredCandidates = candidates
  if (!candidateError && preferredSiteId) {
    filteredCandidates = (candidates ?? []).filter((row: any) => row.site_id === preferredSiteId)
  }
  if (candidateError) throw candidateError
  if (!filteredCandidates?.length) return null

  const candidateIds = filteredCandidates
    .map((row) => row.id)
    .filter((value): value is string => typeof value === 'string' && !!value)
  if (!candidateIds.length) return null

  const { data: roots, error: rootError } = await supabase
    .from('lot_edge')
    .select('to_lot_id')
    .is('from_lot_id', null)
    .eq('edge_type', 'PRODUCE')
    .in('to_lot_id', candidateIds)
  if (rootError) throw rootError
  if (!roots?.length) return null

  const rootLotIds = new Set(
    roots
      .map((row) => row.to_lot_id)
      .filter((value): value is string => typeof value === 'string' && !!value),
  )
  for (const candidate of filteredCandidates) {
    if (rootLotIds.has(candidate.id) && candidate.uom_id && candidate.site_id) {
      return {
        id: candidate.id as string,
        uom_id: candidate.uom_id as string,
        site_id: candidate.site_id as string,
      }
    }
  }
  return null
}

async function resolveFillingSourceLot(batchIdValue: string) {
  const { data: sourceLotId, error: rpcError } = await supabase.rpc('get_packing_source_lotid', {
    p_batch_id: batchIdValue,
  })
  if (rpcError) throw rpcError
  if (!sourceLotId || typeof sourceLotId !== 'string') return null

  const { data: lotRow, error: lotError } = await supabase
    .from('lot')
    .select('id, uom_id, site_id')
    .eq('id', sourceLotId)
    .maybeSingle()
  if (lotError) throw lotError
  if (!lotRow?.id || !lotRow?.uom_id || !lotRow?.site_id) return null

  return {
    id: String(lotRow.id),
    uom_id: String(lotRow.uom_id),
    site_id: String(lotRow.site_id),
  }
}

async function callProductFilling(payload: Record<string, any>) {
  const { error } = await supabase.rpc('product_filling', { p_doc: payload })
  if (error) throw error
}

async function callProductMove(payload: Record<string, any>) {
  const { error } = await supabase.rpc('product_move', { p_doc: payload })
  if (error) throw error
}

async function persistPackingEvent(form: PackingFormState, isEditing: boolean) {
  if (!batchId.value) return
  const batchCode = batch.value?.batch_code ?? ''
  const volumeQty = isVolumeType(form.packing_type) ? toNumber(form.volume_qty) : null
  const volumeUomId = resolveUomId(form.volume_uom)
  const lineUomId = resolveLitersUomId()
  const packingId = form.id ?? generateLocalId()
  const movementAt = fromInputDateTime(form.event_time) ?? new Date().toISOString()
  const docNo = `PACK-${batchCode}-${Date.now()}`
  const selectedTank = tankOptions.value.find((row) => row.value === form.tank_id)
  const fillingLinesMeta = form.filling_lines.map((line) => ({
    id: line.id,
    package_type_id: line.package_type_id,
    qty: isPackageVolumeFixed(line.package_type_id) ? toNumber(line.qty) : null,
    volume: isPackageVolumeFixed(line.package_type_id) ? null : toNumber(line.volume),
    lot_code: line.lot_code ? line.lot_code.trim() : null,
    sample_flg: Boolean(line.sample_flg),
  }))
  const packingMeta = {
    source: 'packing',
    batch_id: batchId.value,
    batch_code: batchCode,
    packing_id: packingId,
    packing_type: form.packing_type,
    memo: form.memo ? form.memo.trim() : null,
    volume_qty: volumeQty,
    volume_uom: volumeUomId || null,
    movement_site_id: form.movement_site_id || null,
    movement_qty: form.movement_qty ? toNumber(form.movement_qty) : null,
    movement_memo: form.movement_memo ? form.movement_memo.trim() : null,
    filling_lines: fillingLinesMeta,
    tank_id: form.tank_id || null,
    tank_no: selectedTank?.code ?? null,
    tank_fill_start_depth: toNumber(form.tank_fill_start_depth),
    tank_fill_start_volume: toNumber(form.tank_fill_start_volume),
    tank_fill_left_depth: toNumber(form.tank_fill_left_depth),
    tank_left_volume: toNumber(form.tank_left_volume),
    sample_volume: toNumber(form.sample_volume),
    tank_loss_volume: tankLossVolume.value,
  }

  if (form.packing_type === 'filling') {
    if (isEditing) {
      throw new Error('Editing Filling events is not supported. Delete and re-create the event.')
    }
    const siteId = form.movement_site_id || null
    if (!siteId) throw new Error(t('batch.packaging.errors.siteRequired'))

    const sourceLot = await resolveFillingSourceLot(batchId.value)
    if (!sourceLot) {
      throw new Error('Source lot for filling is not found. Run product_produce first.')
    }
    const sourceSiteId = sourceLot.site_id
    const sourceUomId = sourceLot.uom_id
    const sourceUomCode = resolveUomCode(sourceUomId)
    const tankLossQtyLiters = tankLossVolume.value ?? 0
    if (tankLossQtyLiters < 0) {
      throw new Error('Tank loss volume must be greater than or equal to 0.')
    }
    const sampleQtyLiters = toNumber(form.sample_volume) ?? computeFillingSampleVolume(form.filling_lines)
    if (sampleQtyLiters < 0) {
      throw new Error('Sample volume must be greater than or equal to 0.')
    }
    const effectiveLossQtyLiters = tankLossQtyLiters + sampleQtyLiters
    const lossQtySourceUom = convertFromLiters(effectiveLossQtyLiters, sourceUomCode) ?? effectiveLossQtyLiters

    const lines = form.filling_lines
      .filter((line) => !line.sample_flg)
      .map((line, index) => {
        const volumeFix = isPackageVolumeFixed(line.package_type_id)
        const qtyUnits = toNumber(line.qty)
        const lineVolumeLiters = resolveFillingLineVolumeFromForm(line)
        if (lineVolumeLiters == null || lineVolumeLiters <= 0) return null
        if (volumeFix && (qtyUnits == null || qtyUnits <= 0 || !Number.isInteger(qtyUnits))) return null
        return {
          line_no: index + 1,
          lot_no: line.lot_code ? line.lot_code.trim() : null,
          package_id: line.package_type_id || null,
          qty: convertFromLiters(lineVolumeLiters, sourceUomCode) ?? lineVolumeLiters,
          unit: volumeFix ? qtyUnits : null,
          meta: {
            unit_count: volumeFix ? qtyUnits : null,
            input_volume_l: volumeFix ? null : lineVolumeLiters,
            volume_fix_flg: volumeFix,
            sample_flg: false,
          },
        }
      })
      .filter((line): line is NonNullable<typeof line> => line !== null)
    if (!lines.length) {
      throw new Error(t('batch.packaging.errors.nonSampleRequired'))
    }
    const totalFillQty = computeFillingTotals(form.filling_lines).totalVolume ?? 0

    const fillPayload = {
      doc_no: docNo,
      movement_at: movementAt,
      src_site_id: sourceSiteId,
      dest_site_id: siteId,
      batch_id: batchId.value,
      from_lot_id: sourceLot.id,
      uom_id: sourceUomId,
      tank_id: form.tank_id || null,
      loss_qty: lossQtySourceUom,
      notes: form.memo ? form.memo.trim() : null,
      meta: {
        ...packingMeta,
        movement_qty: totalFillQty,
        movement_intent: 'PACKAGE_FILL',
        idempotency_key: `packing_fill:${batchId.value}:${packingId}`,
      },
      lines,
    }
    await callProductFilling(fillPayload)
    return
  }

  if (form.packing_type === 'transfer') {
    if (isEditing) {
      throw new Error('Editing Transfer events is not supported. Delete and re-create the event.')
    }

    const dstSiteId = form.movement_site_id || null
    if (!dstSiteId) throw new Error(t('batch.packaging.errors.siteRequired'))

    const preferredSrcSiteId = resolveProduceSiteId(batch.value)
    const sourceLot = await resolveRootSourceLot(batchId.value, preferredSrcSiteId)
      ?? await resolveRootSourceLot(batchId.value, null)
    if (!sourceLot) {
      throw new Error('Root source lot for transfer is not found. Run product_produce first.')
    }

    const movementQty = toNumber(form.movement_qty)
    if (movementQty == null || movementQty <= 0) {
      throw new Error(t('batch.packaging.errors.movementQtyRequired'))
    }

    const movementQtyLiters = convertToLiters(movementQty, resolveUomCode(volumeUomId)) ?? movementQty
    const sourceUomCode = resolveUomCode(sourceLot.uom_id)
    const sourceQty = convertFromLiters(movementQtyLiters, sourceUomCode) ?? movementQtyLiters

    const movePayload = {
      doc_no: docNo,
      movement_at: movementAt,
      movement_intent: 'INTERNAL_TRANSFER',
      src_site: sourceLot.site_id,
      dst_site: dstSiteId,
      src_lot_id: sourceLot.id,
      qty: sourceQty,
      uom_id: sourceLot.uom_id,
      tax_decision_code: 'NON_TAXABLE_REMOVAL',
      reason: form.reason ? form.reason.trim() : null,
      notes: form.memo ? form.memo.trim() : null,
      meta: {
        ...packingMeta,
        movement_intent: 'INTERNAL_TRANSFER',
        idempotency_key: `packing_transfer:${batchId.value}:${packingId}`,
      },
    }

    await callProductMove(movePayload)
    return
  }

  if (form.packing_type === 'ship') {
    if (isEditing) {
      throw new Error('Editing Ship events is not supported. Delete and re-create the event.')
    }

    const dstSiteId = form.movement_site_id || null
    if (!dstSiteId) throw new Error(t('batch.packaging.errors.siteRequired'))

    const preferredSrcSiteId = resolveProduceSiteId(batch.value)
    const sourceLot = await resolveRootSourceLot(batchId.value, preferredSrcSiteId)
      ?? await resolveRootSourceLot(batchId.value, null)
    if (!sourceLot) {
      throw new Error('Root source lot for ship is not found. Run product_produce first.')
    }

    const movementQty = toNumber(form.movement_qty)
    if (movementQty == null || movementQty <= 0) {
      throw new Error(t('batch.packaging.errors.movementQtyRequired'))
    }

    const movementQtyLiters = convertToLiters(movementQty, resolveUomCode(volumeUomId)) ?? movementQty
    const sourceUomCode = resolveUomCode(sourceLot.uom_id)
    const sourceQty = convertFromLiters(movementQtyLiters, sourceUomCode) ?? movementQtyLiters

    const movePayload = {
      doc_no: docNo,
      movement_at: movementAt,
      movement_intent: 'SHIP_DOMESTIC',
      src_site: sourceLot.site_id,
      dst_site: dstSiteId,
      src_lot_id: sourceLot.id,
      qty: sourceQty,
      uom_id: sourceLot.uom_id,
      tax_decision_code: 'NON_TAXABLE_REMOVAL',
      reason: form.reason ? form.reason.trim() : null,
      notes: form.memo ? form.memo.trim() : null,
      meta: {
        ...packingMeta,
        movement_intent: 'SHIP_DOMESTIC',
        idempotency_key: `packing_ship:${batchId.value}:${packingId}`,
      },
    }

    await callProductMove(movePayload)
    return
  }

  const movementPayload = {
    doc_no: isEditing ? undefined : docNo,
    doc_type: mapPackingDocType(form.packing_type),
    status: 'posted',
    movement_at: movementAt,
    src_site_id: null,
    dest_site_id: isMovementType(form.packing_type) ? (form.movement_site_id || null) : null,
    reason: form.reason ? form.reason.trim() : null,
    notes: form.memo ? form.memo.trim() : null,
    meta: packingMeta,
  }

  let movementId = form.id ?? ''
  if (isEditing && form.id) {
    const { error } = await supabase
      .from('inv_movements')
      .update(movementPayload)
      .eq('id', form.id)
    if (error) throw error
    movementId = form.id
    const { error: deleteError } = await supabase
      .from('inv_movement_lines')
      .delete()
      .eq('movement_id', movementId)
    if (deleteError) throw deleteError
  } else {
    const { data, error } = await supabase
      .from('inv_movements')
      .insert(movementPayload)
      .select('id')
      .single()
    if (error) throw error
    movementId = data.id
  }

  const lines: Array<Record<string, any>> = []
  if (volumeQty != null) {
    const packageId = defaultPackageId()
    if (!packageId) {
      throw new Error('No package configured for volume-only movement.')
    }
    const volumeLiters = convertToLiters(volumeQty, resolveUomCode(volumeUomId))
    lines.push({
      movement_id: movementId,
      line_no: 1,
      package_id: packageId,
      batch_id: batchId.value,
      qty: volumeLiters ?? volumeQty,
      uom_id: lineUomId,
      notes: null,
      meta: { volume_uom_id: volumeUomId || null },
    })
  }

  if (lines.length) {
    const { error: lineError } = await supabase.from('inv_movement_lines').insert(lines)
    if (lineError) throw lineError
  }
}

function validatePackingForm(form: PackingFormState) {
  const errors: Record<string, string> = {}
  if (!form.packing_type) errors.packing_type = t('batch.packaging.errors.typeRequired')
  if (!form.event_time) errors.event_time = t('batch.packaging.errors.eventTimeRequired')
  if (isVolumeType(form.packing_type)) {
    const qty = toNumber(form.volume_qty)
    if (qty == null || qty <= 0) errors.volume_qty = t('batch.packaging.errors.volumeRequired')
    if (!form.volume_uom) errors.volume_uom = t('batch.packaging.errors.volumeUomRequired')
  }
  if (isMovementType(form.packing_type)) {
    if (!form.movement_site_id) errors.movement_site_id = t('batch.packaging.errors.siteRequired')
    const qty = toNumber(form.movement_qty)
    if (qty == null || qty <= 0) errors.movement_qty = t('batch.packaging.errors.movementQtyRequired')
  }
  if (form.packing_type === 'filling') {
    if (!form.tank_id) errors.tank_id = t('batch.packaging.errors.tankRequired')
    const startDepth = toNumber(form.tank_fill_start_depth)
    if (startDepth == null || startDepth < 0) errors.tank_fill_start_depth = t('batch.packaging.errors.depthRequired')
    const leftDepth = toNumber(form.tank_fill_left_depth)
    if (leftDepth == null || leftDepth < 0) errors.tank_fill_left_depth = t('batch.packaging.errors.depthRequired')
    if (!form.filling_lines.length) {
      errors.filling_lines = t('batch.packaging.errors.fillingRequired')
    } else {
      const hasInventoryLine = form.filling_lines.some((line) => !line.sample_flg)
      if (!hasInventoryLine) {
        errors.filling_lines = t('batch.packaging.errors.nonSampleRequired')
      }
      const invalid = form.filling_lines.some((line) => {
        if (!line.package_type_id) return true
        const volumeFix = isPackageVolumeFixed(line.package_type_id)
        if (volumeFix) {
          const qty = toNumber(line.qty)
          if (qty == null || qty < 1 || !Number.isInteger(qty)) return true
        } else {
          const volume = toNumber(line.volume)
          if (volume == null || volume <= 0) return true
        }
        return typeof line.sample_flg !== 'boolean'
      })
      if (invalid) errors.filling_lines = t('batch.packaging.errors.fillingLineInvalid')
    }
  }
  return errors
}

function computeFillingTotals(lines: PackingFillingLineForm[]) {
  let totalUnits = 0
  let totalVolume = 0
  let hasMissing = false
  lines.forEach((line) => {
    if (line.sample_flg) return
    const lineVolume = resolveFillingLineVolumeFromForm(line)
    if (lineVolume == null) {
      hasMissing = true
      return
    }
    if (isPackageVolumeFixed(line.package_type_id)) {
      const qty = toNumber(line.qty)
      if (qty != null && Number.isFinite(qty)) totalUnits += qty
    }
    totalVolume += lineVolume
  })
  return {
    totalUnits,
    totalVolume: hasMissing ? null : totalVolume,
  }
}

function computeFillingSampleVolume(lines: PackingFillingLineForm[]) {
  return lines.reduce((sum, line) => {
    if (!line.sample_flg) return sum
    const lineVolume = resolveFillingLineVolumeFromForm(line)
    if (lineVolume == null) return sum
    return sum + lineVolume
  }, 0)
}

function resolvePackageUnitVolume(packageTypeId: string) {
  const row = resolvePackageOption(packageTypeId)
  if (!row || row.unit_volume == null) return null
  return convertToLiters(row.unit_volume, resolveUomCode(row.volume_uom))
}

function formatFillingUnitVolume(packageTypeId: string) {
  if (!isPackageVolumeFixed(packageTypeId)) return '—'
  const row = resolvePackageOption(packageTypeId)
  if (!row || row.unit_volume == null) return '—'
  const uomCode = resolveUomCode(row.volume_uom)
  const qty = Number(row.unit_volume)
  const display = Number.isFinite(qty) ? qty.toLocaleString(undefined, { maximumFractionDigits: 3 }) : String(row.unit_volume)
  return uomCode ? `${display} ${uomCode}` : display
}

function formatFillingLineTotal(line: PackingFillingLineForm) {
  const lineVolume = resolveFillingLineVolumeFromForm(line)
  if (lineVolume == null) return '—'
  return formatVolumeValue(lineVolume)
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

function formatPackingBeerCategory() {
  const fromForm = batchForm.product_name?.trim()
  if (fromForm) return fromForm
  const fromBatch = typeof batch.value?.product_name === 'string' ? batch.value.product_name.trim() : ''
  if (fromBatch) return fromBatch
  return '—'
}

function resolveTankCodeById(tankId: string | null | undefined) {
  if (!tankId) return ''
  const match = tankOptions.value.find((row) => row.value === tankId)
  return match?.code ?? ''
}

function formatPackingTankNo(event: PackingEvent) {
  const code = event.tank_no?.trim() || resolveTankCodeById(event.tank_id)
  return code || '—'
}

function resolvePackageCode(packageTypeId: string) {
  const row = packageCategories.value.find((item) => item.id === packageTypeId)
  return row?.package_code ?? packageTypeId
}

function formatPackingPackageInfo(event: PackingEvent) {
  if (!event.filling_lines.length) return '—'
  const codes = event.filling_lines
    .map((line) => resolvePackageCode(line.package_type_id))
    .filter((value, index, arr) => value && arr.indexOf(value) === index)
  if (!codes.length) return '—'
  return codes.join(', ')
}

function formatPackingNumber(event: PackingEvent) {
  if (!event.filling_lines.length) return '—'
  const totalUnits = event.filling_lines.reduce((sum, line) => {
    if (line.sample_flg) return sum
    if (!isPackageVolumeFixed(line.package_type_id)) return sum
    return sum + (line.qty ?? 0)
  }, 0)
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
  const start = packingTankStartVolumeFromEvent(event)
  const left = packingTankLeftVolumeFromEvent(event)
  if (start == null || left == null) return null
  const payout = start - left
  return Number.isFinite(payout) ? payout : null
}

function packingTotalLineVolumeFromEvent(event: PackingEvent) {
  if (event.packing_type !== 'filling') return null
  const total = fillingLinesVolumeFromEvent(event.filling_lines)
  return Number.isFinite(total) ? total : null
}

function packingFillingRemainingFromEvent(event: PackingEvent) {
  const payout = packingFillingPayoutFromEvent(event)
  const totalLine = packingTotalLineVolumeFromEvent(event)
  if (payout == null || totalLine == null) return null
  const remaining = payout - totalLine
  return Number.isFinite(remaining) ? remaining : null
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

function packingLossFromEvent(event: PackingEvent) {
  if (event.packing_type !== 'filling') return null
  if (event.tank_fill_start_volume == null || event.tank_left_volume == null) return null
  const sample = event.sample_volume ?? fillingSampleVolumeFromEvent(event.filling_lines)
  const fillingVolume = fillingLinesVolumeFromEvent(event.filling_lines)
  const loss = event.tank_fill_start_volume - event.tank_left_volume - fillingVolume - sample
  return Number.isFinite(loss) ? loss : null
}

function formatPackingLoss(event: PackingEvent) {
  const loss = packingLossFromEvent(event)
  if (loss == null) return '—'
  return formatVolumeValue(loss)
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

function resolveTankIdByCode(tankNo: string | null | undefined) {
  if (!tankNo) return null
  const value = tankNo.trim()
  if (!value) return null
  const match = tankOptions.value.find((row) => row.code === value)
  return match?.value ?? null
}

function showPackingNotice(message: string) {
  packingNotice.value = message
  window.setTimeout(() => {
    if (packingNotice.value === message) packingNotice.value = ''
  }, 3000)
}

function clearHighlightedPackingEvent() {
  highlightedPackingEventId.value = ''
  if (highlightedPackingTimer != null) {
    window.clearTimeout(highlightedPackingTimer)
    highlightedPackingTimer = null
  }
}

function highlightPackingEvent(eventId: string) {
  clearHighlightedPackingEvent()
  highlightedPackingEventId.value = eventId
  highlightedPackingTimer = window.setTimeout(() => {
    if (highlightedPackingEventId.value === eventId) {
      highlightedPackingEventId.value = ''
    }
    highlightedPackingTimer = null
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

watch(
  () => packingFillingSampleVolume.value,
  (total) => {
    if (!packingDialog.form || packingDialog.form.packing_type !== 'filling') return
    if (packingDialog.readOnly) return
    const hasSampleLine = packingDialog.form.filling_lines.some((line) => line.sample_flg)
    packingDialog.form.sample_volume = hasSampleLine ? String(total) : ''
  }
)

watch(
  () => [packingDialog.form?.packing_type, packingDialog.form?.tank_id, packingDialog.form?.tank_fill_start_depth],
  () => {
    if (!packingDialog.form || packingDialog.form.packing_type !== 'filling') return
    const depth = toNumber(packingDialog.form.tank_fill_start_depth)
    if (!packingDialog.form.tank_id || depth == null || depth < 0) return
    delete packingDialog.errors.tank_fill_start_depth
    scheduleTankVolumeCalc('start')
  }
)

watch(
  () => [packingDialog.form?.packing_type, packingDialog.form?.tank_id, packingDialog.form?.tank_fill_left_depth],
  () => {
    if (!packingDialog.form || packingDialog.form.packing_type !== 'filling') return
    const depth = toNumber(packingDialog.form.tank_fill_left_depth)
    if (!packingDialog.form.tank_id || depth == null || depth < 0) return
    delete packingDialog.errors.tank_fill_left_depth
    scheduleTankVolumeCalc('left')
  }
)

function siteLabel(siteId?: string | null) {
  if (!siteId) return '—'
  const match = siteOptions.value.find((row) => row.value === siteId)
  return match?.label ?? '—'
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

function parseJsonSafe(value: string) {
  if (!value) return null
  try {
    return JSON.parse(value)
  } catch {
    return value
  }
}

function toNumber(value: any): number | null {
  if (value === null || value === undefined || value === '') return null
  const num = Number(value)
  return Number.isFinite(num) ? num : null
}

function toInputDate(value: string | null | undefined) {
  if (!value) return ''
  try {
    const d = new Date(value)
    const pad = (n: number) => String(n).padStart(2, '0')
    const yyyy = d.getFullYear()
    const mm = pad(d.getMonth() + 1)
    const dd = pad(d.getDate())
    return `${yyyy}-${mm}-${dd}`
  } catch {
    return ''
  }
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
  if (!value) return null
  try {
    return new Date(value).toISOString()
  } catch {
    return value
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

function convertFromLiters(sizeInLiters: number | null | undefined, uomCode: string | null | undefined) {
  if (sizeInLiters == null || Number.isNaN(Number(sizeInLiters))) return null
  if (!uomCode) return Number(sizeInLiters)
  switch (uomCode) {
    case 'L':
      return Number(sizeInLiters)
    case 'mL':
      return Number(sizeInLiters) * 1000
    case 'gal_us':
      return Number(sizeInLiters) / 3.78541
    default:
      return Number(sizeInLiters)
  }
}

function formatVolumeValue(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  const display = Number(value)
  return `${display.toLocaleString(undefined, { maximumFractionDigits: 2 })} L`
}

function newPackingForm(type: PackingType): PackingFormState {
  return {
    packing_type: type,
    event_time: toInputDateTime(new Date().toISOString()),
    memo: '',
    volume_qty: '',
    volume_uom: defaultVolumeUomId(),
    movement_site_id: '',
    movement_qty: '',
    movement_memo: '',
    filling_lines: [],
    reason: '',
    tank_id: '',
    tank_fill_start_depth: '0',
    tank_fill_start_volume: '',
    tank_fill_left_depth: '0',
    tank_left_volume: '',
    sample_volume: '',
  }
}

onMounted(async () => {
  try {
    await ensureTenant()
    await Promise.all([loadBatchOptions(), loadBatchStatusOptions(), loadSites(), loadTankOptions(), loadVolumeUoms(), loadUoms(), fetchPackageCategories(), loadPackingEvents(), loadBatchRelations()])
  } catch (err) {
    console.error(err)
  }
})

onBeforeUnmount(() => {
  clearHighlightedPackingEvent()
  if (tankVolumeStartTimer != null) {
    window.clearTimeout(tankVolumeStartTimer)
    tankVolumeStartTimer = null
  }
  if (tankVolumeLeftTimer != null) {
    window.clearTimeout(tankVolumeLeftTimer)
    tankVolumeLeftTimer = null
  }
})
</script>
