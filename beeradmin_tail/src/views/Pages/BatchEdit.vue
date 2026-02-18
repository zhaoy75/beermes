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
        <div v-else-if="batchRelations.length > 0">
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
            </tbody>
          </table>
          </div>
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
                <td class="px-3 py-2 space-x-2">
                  <button
                    class="px-2 py-1 text-xs rounded border hover:bg-gray-100 disabled:opacity-50 disabled:cursor-not-allowed"
                    type="button"
                    :disabled="!canEditPackingEvent(event)"
                    @click="openPackingEdit(event)"
                  >
                    {{ t('batch.packaging.actions.edit') }}
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
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()

const batchId = computed(() => route.params.batchId as string | undefined)
const pageTitle = computed(() => t('batch.edit.title'))
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
  volume_uom: string | null
}

interface SiteOption {
  value: string
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
  sample_volume: number | null
}

const packageCategories = ref<PackageCategoryOption[]>([])
const siteOptions = ref<SiteOption[]>([])
const volumeUoms = ref<VolumeUomOption[]>([])
const uomOptionsRaw = ref<UomOption[]>([])
const packingEvents = ref<PackingEvent[]>([])
const packingNotice = ref('')

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

function fillingLinesVolumeFromEvent(lines: PackingFillingLine[]) {
  return lines.reduce((sum, line) => {
    const unit = resolvePackageUnitVolume(line.package_type_id)
    if (unit == null) return sum
    return sum + line.qty * unit
  }, 0)
}

function processedVolumeFromPackingEvent(event: PackingEvent) {
  if (event.packing_type === 'filling') {
    let total = 0
    const qty = event.movement?.qty
    if (qty != null && Number.isFinite(qty)) total += qty
    const sample = event.sample_volume ?? 0
    if (Number.isFinite(sample)) total += sample
    if (event.tank_fill_start_volume != null && event.tank_left_volume != null) {
      const loss = event.tank_fill_start_volume - event.tank_left_volume - fillingLinesVolumeFromEvent(event.filling_lines) - sample
      if (Number.isFinite(loss)) total += loss
    }
    return total
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
    await Promise.all([loadBatchOptions(), loadBatchStatusOptions(), loadSites(), fetchPackageCategories(), loadVolumeUoms(), loadUoms()])
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
      const fillingLines = Array.isArray(meta.filling_lines)
        ? meta.filling_lines.map((line: any) => ({
          id: String(line?.id ?? generateLocalId()),
          package_type_id: String(line?.package_type_id ?? ''),
          qty: toNumber(line?.qty) ?? 0,
          lot_code: typeof line?.lot_code === 'string' ? line.lot_code : '',
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
        sample_volume: meta.sample_volume != null ? toNumber(meta.sample_volume) : null,
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
      .select('id, package_code, name_i18n, unit_volume, volume_uom, is_active')
      .eq('is_active', true)
      .order('package_code', { ascending: true })
    if (error) throw error
    packageCategories.value = (data ?? []).map((row: any) => ({
      id: row.id,
      package_code: row.package_code,
      name_i18n: row.name_i18n ?? null,
      unit_volume: row.unit_volume != null ? Number(row.unit_volume) : null,
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
  if (error) throw error
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
  let failedStage: 'produce' | 'save' = 'produce'
  try {
    const movementAt = batch.value.actual_end
      ? new Date(batch.value.actual_end).toISOString()
      : new Date().toISOString()
    const batchCode = String(batch.value.batch_code ?? 'BATCH')
    const normalizedQty = Number(qty).toFixed(6)
    const idempotencyKey = `batch_actual_yield:${batchId.value}:${normalizedQty}:${uomId}`

    const existingProduceMovements = await findPostedActualYieldProduceMovements(batchId.value)
    const matchingProduceMovement = existingProduceMovements.find((movement) =>
      isSameActualYieldProduce(movement, qty, uomId, siteId),
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
      if (produceError) throw produceError
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
    if (batchSaveError) throw batchSaveError

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
    const baseMessage = failedStage === 'save'
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

function canEditPackingEvent(event: PackingEvent) {
  return event.packing_type !== 'filling' && event.packing_type !== 'transfer'
}

function openPackingEdit(event: PackingEvent) {
  if (!canEditPackingEvent(event)) return
  void goToPackingPage(event.id)
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
    showPackingNotice(t('batch.packaging.toast.deleted'))
  } catch (err) {
    console.error(err)
    showPackingNotice(t('batch.packaging.errors.deleteFailed'))
  }
}

function resolvePackageUnitVolume(packageTypeId: string) {
  const row = packageCategories.value.find((item) => item.id === packageTypeId)
  if (!row || row.unit_volume == null) return null
  return convertToLiters(row.unit_volume, resolveUomCode(row.volume_uom))
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

function formatPackingTankNo(event: PackingEvent) {
  const tankNo = event.tank_no?.trim()
  return tankNo || '—'
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
  const totalUnits = event.filling_lines.reduce((sum, line) => sum + (line.qty ?? 0), 0)
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

function packingLossFromEvent(event: PackingEvent) {
  if (event.packing_type !== 'filling') return null
  if (event.tank_fill_start_volume == null || event.tank_left_volume == null) return null
  const sample = event.sample_volume ?? 0
  const fillingVolume = fillingLinesVolumeFromEvent(event.filling_lines)
  const loss = event.tank_fill_start_volume - event.tank_left_volume - fillingVolume - sample
  return Number.isFinite(loss) ? loss : null
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

function showPackingNotice(message: string) {
  packingNotice.value = message
  window.setTimeout(() => {
    if (packingNotice.value === message) packingNotice.value = ''
  }, 3000)
}

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

function formatVolumeValue(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  const display = Number(value)
  return `${display.toLocaleString(undefined, { maximumFractionDigits: 2 })} L`
}

onMounted(async () => {
  try {
    await ensureTenant()
    await Promise.all([loadBatchOptions(), loadBatchStatusOptions(), loadSites(), loadVolumeUoms(), loadUoms(), fetchPackageCategories(), loadPackingEvents(), loadBatchRelations()])
  } catch (err) {
    console.error(err)
  }
})
</script>
