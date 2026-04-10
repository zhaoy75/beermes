<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="space-y-6">
      <section class="rounded-lg border border-gray-200 bg-white shadow">
        <header class="flex flex-col gap-3 border-b p-4 md:flex-row md:items-start md:justify-between">
          <div>
            <h2 class="text-lg font-semibold text-gray-900">{{ pageTitle }}</h2>
            <p class="text-sm text-gray-500">{{ pageSubtitle }}</p>
          </div>
          <div class="flex flex-wrap gap-2">
            <button class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-100" type="button" @click="goBack">
              {{ t('batch.edit.backToBatch') }}
            </button>
            <button
              class="rounded bg-brand-500 px-3 py-2 text-white hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-60"
              type="button"
              :disabled="!step || loadingPage || stepSaveState.saving"
              @click="saveStepInputs"
            >
              {{ stepSaveState.saving ? t('common.loading') : t('batch.edit.stepSaveInputs') }}
            </button>
          </div>
        </header>

        <div v-if="loadingPage" class="p-6 text-sm text-gray-500">
          {{ t('common.loading') }}
        </div>
        <div v-else-if="pageError" class="p-6 text-sm text-red-600">
          {{ pageError }}
        </div>
        <template v-else-if="step && batch">
          <div v-if="stepSaveState.error" class="border-b border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {{ stepSaveState.error }}
          </div>
          <div v-else-if="stepSaveState.success" class="border-b border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
            {{ stepSaveState.success }}
          </div>

          <div class="grid grid-cols-1 gap-3 p-4 md:grid-cols-2 xl:grid-cols-4">
            <div class="rounded-lg border border-gray-200 p-3">
              <div class="text-xs uppercase text-gray-500">{{ t('batch.edit.batchCode') }}</div>
              <div class="mt-1 text-sm font-medium text-gray-800">{{ batch.batch_code || '—' }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 p-3">
              <div class="text-xs uppercase text-gray-500">{{ t('batch.edit.productName') }}</div>
              <div class="mt-1 text-sm font-medium text-gray-800">{{ batch.product_name || '—' }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 p-3 xl:col-span-2">
              <div class="text-xs uppercase text-gray-500">{{ t('batch.edit.releasedRecipeTitle') }}</div>
              <div class="mt-1 flex flex-wrap items-center gap-2 text-sm">
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
            </div>
            <div class="rounded-lg border border-gray-200 p-3">
              <div class="text-xs uppercase text-gray-500">{{ t('batch.edit.stepName') }}</div>
              <div class="mt-1 text-sm font-medium text-gray-800">{{ `${step.step_no}. ${step.step_name}` }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 p-3">
              <div class="text-xs uppercase text-gray-500">{{ t('batch.edit.stepCode') }}</div>
              <div class="mt-1 text-sm font-medium text-gray-800">{{ step.step_code }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 p-3">
              <div class="text-xs uppercase text-gray-500">{{ t('batch.edit.stepTemplate') }}</div>
              <div class="mt-1 text-sm text-gray-700">{{ step.step_template_code || '—' }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 p-3">
              <div class="text-xs uppercase text-gray-500">{{ t('batch.edit.stepType') }}</div>
              <div class="mt-1 text-sm text-gray-700">{{ selectedStepTypeText }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 p-3 xl:col-span-2">
              <div class="text-xs uppercase text-gray-500">{{ t('batch.edit.stepInstructions') }}</div>
              <div class="mt-1 whitespace-pre-wrap text-sm text-gray-700">{{ selectedStepInstructionsText }}</div>
            </div>
          </div>
        </template>
      </section>

      <template v-if="step && batch">
        <section class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="border-b px-4 py-3">
            <h3 class="text-sm font-semibold text-gray-900">{{ t('batch.edit.stepExecutionControlTitle') }}</h3>
          </div>
          <div class="grid grid-cols-1 gap-4 p-4 md:grid-cols-2 xl:grid-cols-4">
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('batch.edit.stepStatus') }}</label>
              <select v-model="stepForm.status" class="h-[40px] w-full rounded border px-3">
                <option v-for="option in stepStatusOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('batch.edit.stepStartedAt') }}</label>
              <input v-model="stepForm.started_at" type="datetime-local" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('batch.edit.stepEndedAt') }}</label>
              <input v-model="stepForm.ended_at" type="datetime-local" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('batch.edit.stepDuration') }}</label>
              <div class="flex h-[40px] items-center rounded border bg-gray-50 px-3 text-sm text-gray-700">
                {{ formatDurationSeconds(step.planned_duration_sec) }}
              </div>
            </div>
            <div class="md:col-span-2 xl:col-span-4">
              <label class="mb-1 block text-sm text-gray-600">{{ t('batch.edit.notes') }}</label>
              <textarea v-model.trim="stepForm.notes" rows="3" class="w-full rounded border px-3 py-2" />
            </div>
          </div>
        </section>

        <section class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="border-b px-4 py-3">
            <h3 class="text-sm font-semibold text-gray-900">{{ t('batch.edit.stepParametersTitle') }}</h3>
          </div>
          <div v-if="parameterForms.length === 0" class="p-4 text-sm text-gray-500">{{ t('common.noData') }}</div>
          <div v-else class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                <tr>
                  <th class="px-3 py-2 text-left">{{ t('recipe.parameters.parameterCode') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('recipe.parameters.target') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('recipe.parameters.min') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('recipe.parameters.max') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('recipe.parameters.uomCode') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepActualValue') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepComment') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="row in parameterForms" :key="row.local_key">
                  <td class="px-3 py-2 text-gray-700">{{ row.parameter_code || row.parameter_name || '—' }}</td>
                  <td class="px-3 py-2 text-right text-gray-700">{{ formatDynamicValue(row.target) }}</td>
                  <td class="px-3 py-2 text-right text-gray-700">{{ formatDynamicValue(row.min) }}</td>
                  <td class="px-3 py-2 text-right text-gray-700">{{ formatDynamicValue(row.max) }}</td>
                  <td class="px-3 py-2 text-gray-700">{{ row.uom_code || '—' }}</td>
                  <td class="px-3 py-2">
                    <input v-model.trim="row.actual_value" type="text" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <input v-model.trim="row.comment" type="text" class="h-[36px] w-full rounded border px-2" />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="border-b px-4 py-3">
            <h3 class="text-sm font-semibold text-gray-900">{{ t('batch.edit.stepQualityChecksTitle') }}</h3>
          </div>
          <div v-if="qualityCheckForms.length === 0" class="p-4 text-sm text-gray-500">{{ t('common.noData') }}</div>
          <div v-else class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                <tr>
                  <th class="px-3 py-2 text-left">{{ t('recipe.qa.checkCode') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('recipe.qa.frequency') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('recipe.qa.required') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepResultStatus') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepResultValue') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepCheckedAt') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepCheckedBy') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepResultNote') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="row in qualityCheckForms" :key="row.local_key">
                  <td class="px-3 py-2 text-gray-700">{{ row.check_code || row.check_name || '—' }}</td>
                  <td class="px-3 py-2 text-gray-700">{{ row.frequency || '—' }}</td>
                  <td class="px-3 py-2 text-gray-700">{{ row.required ? t('common.yes') : t('common.no') }}</td>
                  <td class="px-3 py-2">
                    <select v-model="row.result_status" class="h-[36px] w-full rounded border px-2">
                      <option value="">{{ t('common.select') }}</option>
                      <option v-for="option in qualityResultStatusOptions" :key="option.value" :value="option.value">
                        {{ option.label }}
                      </option>
                    </select>
                  </td>
                  <td class="px-3 py-2">
                    <input v-model.trim="row.result_value" type="text" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <input v-model="row.checked_at" type="datetime-local" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <input v-model.trim="row.checked_by" type="text" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <input v-model.trim="row.result_note" type="text" class="h-[36px] w-full rounded border px-2" />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="border-b px-4 py-3">
            <h3 class="text-sm font-semibold text-gray-900">{{ t('batch.edit.stepPlannedMaterialsTitle') }}</h3>
          </div>
          <div v-if="plannedMaterials.length === 0" class="p-4 text-sm text-gray-500">{{ t('common.noData') }}</div>
          <div v-else class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                <tr>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepMaterial') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('recipe.materials.role') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('recipe.materials.qty') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('recipe.materials.uomCode') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="row in plannedMaterials" :key="row.id">
                  <td class="px-3 py-2 text-gray-700">{{ plannedMaterialLabel(row) }}</td>
                  <td class="px-3 py-2 text-gray-700">{{ row.material_role || row.requirement_json?.material_role || '—' }}</td>
                  <td class="px-3 py-2 text-right text-gray-700">{{ formatNumber(row.planned_qty) }}</td>
                  <td class="px-3 py-2 text-gray-700">{{ uomLabel(row.uom_id) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="flex flex-col gap-3 border-b px-4 py-3 md:flex-row md:items-center md:justify-between">
            <h3 class="text-sm font-semibold text-gray-900">{{ t('batch.edit.stepActualMaterialsTitle') }}</h3>
            <div class="flex flex-wrap gap-2">
              <button class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-100" type="button" @click="addActualMaterialRow">
                {{ t('batch.edit.stepAddActualMaterial') }}
              </button>
              <button
                class="rounded bg-brand-500 px-3 py-2 text-sm text-white hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-60"
                type="button"
                :disabled="actualMaterialsState.saving"
                @click="saveActualMaterials"
              >
                {{ actualMaterialsState.saving ? t('common.loading') : t('common.save') }}
              </button>
            </div>
          </div>
          <div v-if="actualMaterialsState.error" class="border-b border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {{ actualMaterialsState.error }}
          </div>
          <div v-else-if="actualMaterialsState.success" class="border-b border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
            {{ actualMaterialsState.success }}
          </div>
          <div v-if="actualMaterialForms.length === 0" class="p-4 text-sm text-gray-500">{{ t('common.noData') }}</div>
          <div v-else class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                <tr>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepMaterial') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepLot') }}</th>
                  <th class="px-3 py-2 text-right">{{ t('batch.edit.stepActualQty') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('recipe.materials.uomCode') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepConsumedAt') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepComment') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('common.delete') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="(row, index) in actualMaterialForms" :key="row.local_key">
                  <td class="px-3 py-2">
                    <select v-model="row.material_id" class="h-[36px] w-full rounded border px-2" @change="handleActualMaterialChange(index)">
                      <option value="">{{ t('common.select') }}</option>
                      <option v-for="option in materialOptions" :key="option.id" :value="option.id">{{ option.label }}</option>
                    </select>
                  </td>
                  <td class="px-3 py-2">
                    <select v-model="row.lot_id" class="h-[36px] w-full rounded border px-2" @change="handleActualLotChange(index)">
                      <option value="">{{ t('common.select') }}</option>
                      <option v-for="option in lotOptionsForMaterial(row.material_id)" :key="option.id" :value="option.id">{{ option.label }}</option>
                    </select>
                  </td>
                  <td class="px-3 py-2">
                    <input v-model.trim="row.actual_qty" type="number" step="any" min="0" class="h-[36px] w-full rounded border px-2 text-right" />
                  </td>
                  <td class="px-3 py-2">
                    <select v-model="row.uom_id" class="h-[36px] w-full rounded border px-2">
                      <option value="">{{ t('common.select') }}</option>
                      <option v-for="option in uomOptions" :key="option.id" :value="option.id">{{ option.name || option.code }}</option>
                    </select>
                  </td>
                  <td class="px-3 py-2">
                    <input v-model="row.consumed_at" type="datetime-local" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <input v-model.trim="row.note" type="text" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <button class="rounded border border-gray-300 px-2 py-1 text-xs hover:bg-gray-100" type="button" @click="removeActualMaterialRow(index)">
                      {{ t('common.delete') }}
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="flex flex-col gap-3 border-b px-4 py-3 md:flex-row md:items-center md:justify-between">
            <h3 class="text-sm font-semibold text-gray-900">{{ t('batch.edit.stepEquipmentTitle') }}</h3>
            <div class="flex flex-wrap gap-2">
              <button class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-100" type="button" @click="addEquipmentAssignmentRow">
                {{ t('batch.edit.stepAddEquipmentAssignment') }}
              </button>
              <button
                class="rounded bg-brand-500 px-3 py-2 text-sm text-white hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-60"
                type="button"
                :disabled="equipmentState.saving"
                @click="saveEquipmentAssignments"
              >
                {{ equipmentState.saving ? t('common.loading') : t('common.save') }}
              </button>
            </div>
          </div>
          <div v-if="equipmentState.error" class="border-b border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {{ equipmentState.error }}
          </div>
          <div v-else-if="equipmentState.success" class="border-b border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
            {{ equipmentState.success }}
          </div>
          <div v-if="equipmentAssignmentForms.length === 0" class="p-4 text-sm text-gray-500">{{ t('common.noData') }}</div>
          <div v-else class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                <tr>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepEquipment') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepAssignmentRole') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepAssignedAt') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepReleasedAt') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('common.delete') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="(row, index) in equipmentAssignmentForms" :key="row.local_key">
                  <td class="px-3 py-2">
                    <select v-model="row.equipment_id" class="h-[36px] w-full rounded border px-2">
                      <option value="">{{ t('common.select') }}</option>
                      <option v-for="option in equipmentOptions" :key="option.id" :value="option.id">{{ option.label }}</option>
                    </select>
                  </td>
                  <td class="px-3 py-2">
                    <input v-model.trim="row.assignment_role" type="text" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <input v-model="row.assigned_at" type="datetime-local" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <input v-model="row.released_at" type="datetime-local" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <button class="rounded border border-gray-300 px-2 py-1 text-xs hover:bg-gray-100" type="button" @click="removeEquipmentAssignmentRow(index)">
                      {{ t('common.delete') }}
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="flex flex-col gap-3 border-b px-4 py-3 md:flex-row md:items-center md:justify-between">
            <h3 class="text-sm font-semibold text-gray-900">{{ t('batch.edit.stepExecutionLogsTitle') }}</h3>
            <div class="flex flex-wrap gap-2">
              <button class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-100" type="button" @click="addExecutionLogRow">
                {{ t('batch.edit.stepAddLog') }}
              </button>
              <button
                class="rounded bg-brand-500 px-3 py-2 text-sm text-white hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-60"
                type="button"
                :disabled="logState.saving"
                @click="saveExecutionLogs"
              >
                {{ logState.saving ? t('common.loading') : t('common.save') }}
              </button>
            </div>
          </div>
          <div v-if="logState.error" class="border-b border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {{ logState.error }}
          </div>
          <div v-else-if="logState.success" class="border-b border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
            {{ logState.success }}
          </div>
          <div v-if="executionLogForms.length === 0" class="p-4 text-sm text-gray-500">{{ t('common.noData') }}</div>
          <div v-else class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                <tr>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepEventType') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepEventAt') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepComment') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('common.delete') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="(row, index) in executionLogForms" :key="row.local_key">
                  <td class="px-3 py-2">
                    <select v-model="row.event_type" class="h-[36px] w-full rounded border px-2">
                      <option value="">{{ t('common.select') }}</option>
                      <option v-for="option in executionEventOptions" :key="option.value" :value="option.value">
                        {{ option.label }}
                      </option>
                    </select>
                  </td>
                  <td class="px-3 py-2">
                    <input v-model="row.event_at" type="datetime-local" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <input v-model.trim="row.comment" type="text" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <button class="rounded border border-gray-300 px-2 py-1 text-xs hover:bg-gray-100" type="button" @click="removeExecutionLogRow(index)">
                      {{ t('common.delete') }}
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>

        <section class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="flex flex-col gap-3 border-b px-4 py-3 md:flex-row md:items-center md:justify-between">
            <h3 class="text-sm font-semibold text-gray-900">{{ t('batch.edit.stepDeviationsTitle') }}</h3>
            <div class="flex flex-wrap gap-2">
              <button class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-100" type="button" @click="addDeviationRow">
                {{ t('batch.edit.stepAddDeviation') }}
              </button>
              <button
                class="rounded bg-brand-500 px-3 py-2 text-sm text-white hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-60"
                type="button"
                :disabled="deviationState.saving"
                @click="saveDeviations"
              >
                {{ deviationState.saving ? t('common.loading') : t('common.save') }}
              </button>
            </div>
          </div>
          <div v-if="deviationState.error" class="border-b border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {{ deviationState.error }}
          </div>
          <div v-else-if="deviationState.success" class="border-b border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
            {{ deviationState.success }}
          </div>
          <div v-if="deviationForms.length === 0" class="p-4 text-sm text-gray-500">{{ t('common.noData') }}</div>
          <div v-else class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                <tr>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepDeviationCode') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepDeviationSummary') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepDeviationSeverity') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepDeviationStatus') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepOpenedAt') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepClosedAt') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('batch.edit.stepComment') }}</th>
                  <th class="px-3 py-2 text-left">{{ t('common.delete') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="(row, index) in deviationForms" :key="row.local_key">
                  <td class="px-3 py-2">
                    <input v-model.trim="row.deviation_code" type="text" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <input v-model.trim="row.summary" type="text" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <select v-model="row.severity" class="h-[36px] w-full rounded border px-2">
                      <option v-for="option in deviationSeverityOptions" :key="option.value" :value="option.value">
                        {{ option.label }}
                      </option>
                    </select>
                  </td>
                  <td class="px-3 py-2">
                    <select v-model="row.status" class="h-[36px] w-full rounded border px-2">
                      <option v-for="option in deviationStatusOptions" :key="option.value" :value="option.value">
                        {{ option.label }}
                      </option>
                    </select>
                  </td>
                  <td class="px-3 py-2">
                    <input v-model="row.opened_at" type="datetime-local" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <input v-model="row.closed_at" type="datetime-local" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <input v-model.trim="row.note" type="text" class="h-[36px] w-full rounded border px-2" />
                  </td>
                  <td class="px-3 py-2">
                    <button class="rounded border border-gray-300 px-2 py-1 text-xs hover:bg-gray-100" type="button" @click="removeDeviationRow(index)">
                      {{ t('common.delete') }}
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </section>
      </template>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
/* eslint-disable @typescript-eslint/no-explicit-any */
import { computed, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'

type BatchHeaderRow = {
  id: string
  tenant_id: string
  batch_code: string
  product_name: string | null
  mes_recipe_id: string | null
  recipe_version_id: string | null
  released_reference_json: Record<string, any>
  recipe_json: Record<string, any>
}

type BatchExecutionStepRow = {
  id: string
  step_no: number
  step_code: string
  step_name: string
  step_template_code: string | null
  planned_duration_sec: number | null
  status: string
  planned_params: Record<string, any>
  actual_params: Record<string, any>
  quality_checks_json: any[]
  snapshot_json: Record<string, any>
  started_at: string | null
  ended_at: string | null
  notes: string | null
}

type BatchMaterialPlanRow = {
  id: string
  material_role: string | null
  planned_qty: number
  uom_id: string
  requirement_json: Record<string, any>
  snapshot_json: Record<string, any>
}

type UomOption = {
  id: string
  code: string
  name: string | null
}

type MaterialOption = {
  id: string
  code: string
  name: string
  base_uom_id: string | null
  label: string
}

type LotOption = {
  id: string
  lot_no: string
  material_id: string | null
  uom_id: string | null
  label: string
}

type EquipmentOption = {
  id: string
  code: string
  name: string
  label: string
}

type StepFormState = {
  status: string
  started_at: string
  ended_at: string
  notes: string
}

type ParameterFormRow = {
  local_key: string
  parameter_code: string
  parameter_name: string
  target: unknown
  min: unknown
  max: unknown
  uom_code: string
  actual_value: string
  comment: string
}

type QualityCheckFormRow = {
  local_key: string
  check_code: string
  check_name: string
  sampling_point: string
  frequency: string
  required: boolean
  acceptance_criteria: Record<string, any> | null
  result_status: string
  result_value: string
  result_note: string
  checked_at: string
  checked_by: string
}

type ActualMaterialFormRow = {
  local_key: string
  id: string | null
  material_id: string
  lot_id: string
  actual_qty: string
  uom_id: string
  consumed_at: string
  note: string
  snapshot_json: Record<string, any>
}

type EquipmentAssignmentFormRow = {
  local_key: string
  id: string | null
  equipment_id: string
  assignment_role: string
  assigned_at: string
  released_at: string
  snapshot_json: Record<string, any>
}

type ExecutionLogFormRow = {
  local_key: string
  id: string | null
  event_type: string
  event_at: string
  comment: string
  event_data: Record<string, any>
}

type DeviationFormRow = {
  local_key: string
  id: string | null
  deviation_code: string
  summary: string
  severity: string
  status: string
  opened_at: string
  closed_at: string
  note: string
  detail_json: Record<string, any>
}

type SectionState = {
  saving: boolean
  error: string
  success: string
}

const route = useRoute()
const router = useRouter()
const { t, locale } = useI18n()
const mesClient = () => supabase.schema('mes')

const batchId = computed(() => String(route.params.batchId ?? '').trim())
const stepId = computed(() => String(route.params.stepId ?? '').trim())
const pageTitle = computed(() => t('batch.edit.stepDetailTitle'))

const batch = ref<BatchHeaderRow | null>(null)
const step = ref<BatchExecutionStepRow | null>(null)
const loadingPage = ref(false)
const pageError = ref('')
const currentUserId = ref<string | null>(null)
const currentUserLabel = ref('')

const stepForm = reactive<StepFormState>({
  status: 'open',
  started_at: '',
  ended_at: '',
  notes: '',
})

const plannedMaterials = ref<BatchMaterialPlanRow[]>([])
const parameterForms = ref<ParameterFormRow[]>([])
const qualityCheckForms = ref<QualityCheckFormRow[]>([])
const actualMaterialForms = ref<ActualMaterialFormRow[]>([])
const equipmentAssignmentForms = ref<EquipmentAssignmentFormRow[]>([])
const executionLogForms = ref<ExecutionLogFormRow[]>([])
const deviationForms = ref<DeviationFormRow[]>([])
const loadedActualMaterialIds = ref<string[]>([])
const loadedEquipmentAssignmentIds = ref<string[]>([])
const loadedExecutionLogIds = ref<string[]>([])
const loadedDeviationIds = ref<string[]>([])

const uomOptions = ref<UomOption[]>([])
const materialOptions = ref<MaterialOption[]>([])
const lotOptions = ref<LotOption[]>([])
const equipmentOptions = ref<EquipmentOption[]>([])

const stepSaveState = reactive<SectionState>({ saving: false, error: '', success: '' })
const actualMaterialsState = reactive<SectionState>({ saving: false, error: '', success: '' })
const equipmentState = reactive<SectionState>({ saving: false, error: '', success: '' })
const logState = reactive<SectionState>({ saving: false, error: '', success: '' })
const deviationState = reactive<SectionState>({ saving: false, error: '', success: '' })

const pageSubtitle = computed(() => {
  if (!step.value) return t('batch.edit.stepDetailSubtitle')
  return `${step.value.step_no}. ${step.value.step_name}`
})

const releasedRecipeReference = computed(() => asRecord(batch.value?.released_reference_json))
const hasReleasedRecipe = computed(() => Boolean(releasedRecipeLinkText.value && releasedRecipeLinkText.value !== '—'))
const canOpenReleasedRecipe = computed(() => Boolean(batch.value?.mes_recipe_id && batch.value?.recipe_version_id))

const releasedRecipeLinkText = computed(() => {
  const recipeName = safeText(releasedRecipeReference.value?.recipe_name) || safeText(batch.value?.product_name)
  const recipeCode = safeText(releasedRecipeReference.value?.recipe_code)
  if (recipeName && recipeCode) return `${recipeName} (${recipeCode})`
  return recipeName || recipeCode || '—'
})

const releasedRecipeVersionSummaryText = computed(() => {
  const versionNo = releasedRecipeReference.value?.version_no
  const versionLabel = safeText(releasedRecipeReference.value?.version_label)
  const parts: string[] = []
  if (versionNo != null && versionNo !== '') parts.push(`v${versionNo}`)
  if (versionLabel) parts.push(versionLabel)
  return parts.length ? parts.join(' / ') : '—'
})

const selectedStepTypeText = computed(() =>
  safeText(step.value?.snapshot_json?.step_type)
  || safeText(step.value?.planned_params?.step_type)
  || '—',
)

const selectedStepInstructionsText = computed(() =>
  safeText(step.value?.snapshot_json?.instructions)
  || safeText(step.value?.planned_params?.instructions)
  || '—',
)

const stepStatusOptions = computed(() => [
  { value: 'open', label: t('batch.edit.stepStatusOptions.open') },
  { value: 'ready', label: t('batch.edit.stepStatusOptions.ready') },
  { value: 'in_progress', label: t('batch.edit.stepStatusOptions.inProgress') },
  { value: 'hold', label: t('batch.edit.stepStatusOptions.hold') },
  { value: 'completed', label: t('batch.edit.stepStatusOptions.completed') },
  { value: 'skipped', label: t('batch.edit.stepStatusOptions.skipped') },
  { value: 'cancelled', label: t('batch.edit.stepStatusOptions.cancelled') },
])

const executionEventOptions = computed(() => [
  'create',
  'release',
  'start',
  'pause',
  'resume',
  'complete',
  'parameter_capture',
  'qa_record',
  'material_issue',
  'equipment_assign',
  'deviation',
  'comment',
].map((value) => ({
  value,
  label: executionEventLabel(value),
})))

const deviationSeverityOptions = computed(() => [
  { value: 'minor', label: t('batch.edit.deviationSeverityOptions.minor') },
  { value: 'major', label: t('batch.edit.deviationSeverityOptions.major') },
  { value: 'critical', label: t('batch.edit.deviationSeverityOptions.critical') },
])

const deviationStatusOptions = computed(() => [
  { value: 'open', label: t('batch.edit.deviationStatusOptions.open') },
  { value: 'approved', label: t('batch.edit.deviationStatusOptions.approved') },
  { value: 'rejected', label: t('batch.edit.deviationStatusOptions.rejected') },
  { value: 'closed', label: t('batch.edit.deviationStatusOptions.closed') },
])

const qualityResultStatusOptions = computed(() => [
  { value: 'pending', label: t('batch.edit.stepResultStatusOptions.pending') },
  { value: 'pass', label: t('batch.edit.stepResultStatusOptions.pass') },
  { value: 'fail', label: t('batch.edit.stepResultStatusOptions.fail') },
  { value: 'not_applicable', label: t('batch.edit.stepResultStatusOptions.notApplicable') },
])

const durationUnits = computed(() => ({
  hour: t('batch.edit.timeUnits.hour'),
  minute: t('batch.edit.timeUnits.minute'),
  second: t('batch.edit.timeUnits.second'),
}))

let localRowSeed = 0

function nextLocalKey(prefix: string) {
  localRowSeed += 1
  return `${prefix}-${localRowSeed}`
}

function goBack() {
  if (!batchId.value) return
  void router.push({
    name: 'batchEdit',
    params: { batchId: batchId.value },
  })
}

async function openReleasedRecipe() {
  if (!batch.value?.mes_recipe_id || !batch.value?.recipe_version_id) return
  await router.push({
    path: `/recipeEdit/${batch.value.mes_recipe_id}/${batch.value.recipe_version_id}`,
  })
}

async function ensureCurrentUser() {
  if (currentUserId.value || currentUserLabel.value) return
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  currentUserId.value = data.user?.id ?? null
  currentUserLabel.value = safeText(data.user?.email) || safeText(data.user?.user_metadata?.name)
}

async function loadPage() {
  if (!batchId.value || !stepId.value) {
    batch.value = null
    step.value = null
    pageError.value = t('batch.edit.stepDetailNotFound')
    return
  }

  loadingPage.value = true
  pageError.value = ''
  clearAllStates()
  resetCollections()

  try {
    await ensureCurrentUser()
    const mes = mesClient()
    const [batchResult, stepResult, uomResult, materialResult, equipmentResult, lotResult] = await Promise.all([
      supabase.rpc('batch_get_detail', { p_batch_id: batchId.value }),
      mes
        .from('batch_step')
        .select('id, step_no, step_code, step_name, step_template_code, planned_duration_sec, status, planned_params, actual_params, quality_checks_json, snapshot_json, started_at, ended_at, notes')
        .eq('batch_id', batchId.value)
        .eq('id', stepId.value)
        .maybeSingle(),
      supabase
        .from('mst_uom')
        .select('id, code, name')
        .order('code'),
      mes
        .from('mst_material')
        .select('id, material_code, material_name, base_uom_id, status')
        .eq('status', 'active')
        .order('material_code'),
      supabase
        .from('mst_equipment')
        .select('id, equipment_code, name_i18n, is_active')
        .eq('is_active', true)
        .order('equipment_code'),
      supabase
        .from('lot')
        .select('id, lot_no, material_id, uom_id, status')
        .eq('status', 'active')
        .order('lot_no'),
    ])

    if (batchResult.error) throw batchResult.error
    if (stepResult.error) throw stepResult.error
    if (uomResult.error) throw uomResult.error
    if (materialResult.error) throw materialResult.error
    if (equipmentResult.error) throw equipmentResult.error
    if (lotResult.error) throw lotResult.error

    const detail = asRecord(batchResult.data)
    const batchHeader = asRecord(detail?.batch)
    if (!batchHeader) {
      batch.value = null
      step.value = null
      pageError.value = t('batch.edit.notFound')
      return
    }

    batch.value = {
      id: String(batchHeader.id ?? ''),
      tenant_id: String(batchHeader.tenant_id ?? ''),
      batch_code: String(batchHeader.batch_code ?? ''),
      product_name: safeNullableText(batchHeader.product_name),
      mes_recipe_id: safeNullableText(batchHeader.mes_recipe_id),
      recipe_version_id: safeNullableText(batchHeader.recipe_version_id),
      released_reference_json: asRecord(batchHeader.released_reference_json) ?? {},
      recipe_json: asRecord(batchHeader.recipe_json) ?? {},
    }

    if (!stepResult.data) {
      step.value = null
      pageError.value = t('batch.edit.stepDetailNotFound')
      return
    }

    uomOptions.value = (uomResult.data ?? []).map((row: any) => ({
      id: String(row.id ?? ''),
      code: String(row.code ?? ''),
      name: row.name ?? null,
    }))

    materialOptions.value = (materialResult.data ?? []).map((row: any) => ({
      id: String(row.id ?? ''),
      code: String(row.material_code ?? ''),
      name: String(row.material_name ?? row.material_code ?? ''),
      base_uom_id: row.base_uom_id ?? null,
      label: [safeText(row.material_code), safeText(row.material_name)].filter(Boolean).join(' - ') || String(row.id ?? ''),
    }))

    equipmentOptions.value = (equipmentResult.data ?? []).map((row: any) => {
      const code = String(row.equipment_code ?? row.id ?? '')
      const name = resolveNameI18n(row.name_i18n ?? null)
      return {
        id: String(row.id ?? ''),
        code,
        name,
        label: name ? `${code} - ${name}` : code,
      }
    })

    lotOptions.value = (lotResult.data ?? []).map((row: any) => ({
      id: String(row.id ?? ''),
      lot_no: String(row.lot_no ?? row.id ?? ''),
      material_id: safeNullableText(row.material_id),
      uom_id: safeNullableText(row.uom_id),
      label: String(row.lot_no ?? row.id ?? ''),
    }))

    step.value = {
      id: String(stepResult.data.id ?? ''),
      step_no: Number(stepResult.data.step_no ?? 0),
      step_code: String(stepResult.data.step_code ?? ''),
      step_name: String(stepResult.data.step_name ?? ''),
      step_template_code: safeNullableText(stepResult.data.step_template_code),
      planned_duration_sec: stepResult.data.planned_duration_sec != null ? Number(stepResult.data.planned_duration_sec) : null,
      status: String(stepResult.data.status ?? 'open'),
      planned_params: asRecord(stepResult.data.planned_params) ?? {},
      actual_params: asRecord(stepResult.data.actual_params) ?? {},
      quality_checks_json: asArray(stepResult.data.quality_checks_json),
      snapshot_json: asRecord(stepResult.data.snapshot_json) ?? {},
      started_at: safeNullableText(stepResult.data.started_at),
      ended_at: safeNullableText(stepResult.data.ended_at),
      notes: safeNullableText(stepResult.data.notes),
    }

    initializeStepForms()
    await loadStepCollections(step.value.id)
  } catch (err) {
    console.error(err)
    batch.value = null
    step.value = null
    pageError.value = extractErrorMessage(err) || t('batch.edit.stepDetailLoadFailed')
  } finally {
    loadingPage.value = false
  }
}

function initializeStepForms() {
  if (!step.value) return
  stepForm.status = safeText(step.value.status) || 'open'
  stepForm.started_at = toDateTimeInputValue(step.value.started_at)
  stepForm.ended_at = toDateTimeInputValue(step.value.ended_at)
  stepForm.notes = step.value.notes ?? ''

  parameterForms.value = buildParameterForms(step.value)
  qualityCheckForms.value = buildQualityCheckForms(step.value)
}

async function loadStepCollections(currentStepId: string) {
  const mes = mesClient()
  const [plannedResult, actualResult, equipmentResult, logResult, deviationResult] = await Promise.all([
    mes
      .from('batch_material_plan')
      .select('id, material_role, planned_qty, uom_id, requirement_json, snapshot_json')
      .eq('batch_step_id', currentStepId)
      .order('created_at', { ascending: true }),
    mes
      .from('batch_material_actual')
      .select('id, material_id, lot_id, actual_qty, uom_id, consumed_at, snapshot_json, note')
      .eq('batch_step_id', currentStepId)
      .order('consumed_at', { ascending: true }),
    mes
      .from('batch_equipment_assignment')
      .select('id, equipment_id, assignment_role, assigned_at, released_at, snapshot_json')
      .eq('batch_step_id', currentStepId)
      .order('assigned_at', { ascending: true }),
    mes
      .from('batch_execution_log')
      .select('id, event_type, event_at, comment, event_data')
      .eq('batch_step_id', currentStepId)
      .order('event_at', { ascending: true }),
    mes
      .from('batch_deviation')
      .select('id, batch_step_id, deviation_code, summary, severity, status, opened_at, closed_at, detail_json')
      .eq('batch_step_id', currentStepId)
      .order('opened_at', { ascending: false }),
  ])

  if (plannedResult.error) throw plannedResult.error
  if (actualResult.error) throw actualResult.error
  if (equipmentResult.error) throw equipmentResult.error
  if (logResult.error) throw logResult.error
  if (deviationResult.error) throw deviationResult.error

  plannedMaterials.value = (plannedResult.data ?? []).map((row: any) => ({
    id: String(row.id ?? ''),
    material_role: safeNullableText(row.material_role),
    planned_qty: Number(row.planned_qty ?? 0),
    uom_id: String(row.uom_id ?? ''),
    requirement_json: asRecord(row.requirement_json) ?? {},
    snapshot_json: asRecord(row.snapshot_json) ?? {},
  }))

  actualMaterialForms.value = (actualResult.data ?? []).map((row: any) => ({
    local_key: nextLocalKey('actual-material'),
    id: String(row.id ?? ''),
    material_id: safeText(row.material_id),
    lot_id: safeText(row.lot_id),
    actual_qty: row.actual_qty != null ? String(row.actual_qty) : '',
    uom_id: safeText(row.uom_id),
    consumed_at: toDateTimeInputValue(row.consumed_at),
    note: safeText(row.note),
    snapshot_json: asRecord(row.snapshot_json) ?? {},
  }))
  loadedActualMaterialIds.value = actualMaterialForms.value
    .map((row) => row.id)
    .filter((value): value is string => Boolean(value))

  equipmentAssignmentForms.value = (equipmentResult.data ?? []).map((row: any) => ({
    local_key: nextLocalKey('equipment'),
    id: String(row.id ?? ''),
    equipment_id: safeText(row.equipment_id),
    assignment_role: safeText(row.assignment_role),
    assigned_at: toDateTimeInputValue(row.assigned_at),
    released_at: toDateTimeInputValue(row.released_at),
    snapshot_json: asRecord(row.snapshot_json) ?? {},
  }))
  loadedEquipmentAssignmentIds.value = equipmentAssignmentForms.value
    .map((row) => row.id)
    .filter((value): value is string => Boolean(value))

  executionLogForms.value = (logResult.data ?? []).map((row: any) => ({
    local_key: nextLocalKey('log'),
    id: String(row.id ?? ''),
    event_type: safeText(row.event_type),
    event_at: toDateTimeInputValue(row.event_at),
    comment: safeText(row.comment),
    event_data: asRecord(row.event_data) ?? {},
  }))
  loadedExecutionLogIds.value = executionLogForms.value
    .map((row) => row.id)
    .filter((value): value is string => Boolean(value))

  deviationForms.value = (deviationResult.data ?? []).map((row: any) => ({
    local_key: nextLocalKey('deviation'),
    id: String(row.id ?? ''),
    deviation_code: safeText(row.deviation_code),
    summary: safeText(row.summary),
    severity: safeText(row.severity) || 'minor',
    status: safeText(row.status) || 'open',
    opened_at: toDateTimeInputValue(row.opened_at),
    closed_at: toDateTimeInputValue(row.closed_at),
    note: safeText(asRecord(row.detail_json)?.note),
    detail_json: asRecord(row.detail_json) ?? {},
  }))
  loadedDeviationIds.value = deviationForms.value
    .map((row) => row.id)
    .filter((value): value is string => Boolean(value))
}

async function saveStepInputs() {
  if (!step.value) return
  clearSectionState(stepSaveState)

  const previousStatus = safeText(step.value.status)
  const targetStatus = safeText(stepForm.status) || 'open'
  const startedAt = toIsoDateTime(stepForm.started_at)
  const endedAtInput = toIsoDateTime(stepForm.ended_at)
  const endedAt = isStepCompletionStatus(targetStatus) ? (endedAtInput ?? new Date().toISOString()) : endedAtInput
  if (startedAt && endedAt && new Date(startedAt).getTime() > new Date(endedAt).getTime()) {
    stepSaveState.error = t('batch.edit.stepTimeRangeError')
    return
  }

  stepSaveState.saving = true
  let currentStepSaved = false
  try {
    await ensureCurrentUser()
    const mes = mesClient()
    const actualParamsBase = { ...(step.value.actual_params ?? {}) }
    delete actualParamsBase.parameters

    const { error } = await mes
      .from('batch_step')
      .update({
        status: targetStatus,
        started_at: startedAt,
        ended_at: endedAt,
        notes: nullableText(stepForm.notes),
        actual_params: {
          ...actualParamsBase,
          parameters: parameterForms.value.map((row) => ({
            parameter_code: row.parameter_code || null,
            parameter_name: row.parameter_name || null,
            uom_code: row.uom_code || null,
            actual_value: nullableText(row.actual_value),
            comment: nullableText(row.comment),
          })),
        },
        quality_checks_json: qualityCheckForms.value.map((row) => ({
          check_code: row.check_code || null,
          check_name: row.check_name || null,
          sampling_point: nullableText(row.sampling_point),
          frequency: nullableText(row.frequency),
          required: Boolean(row.required),
          acceptance_criteria: row.acceptance_criteria ?? {},
          result_status: nullableText(row.result_status),
          result_value: nullableText(row.result_value),
          result_note: nullableText(row.result_note),
          checked_at: toIsoDateTime(row.checked_at),
          checked_by: nullableText(row.checked_by),
        })),
        updated_by: currentUserId.value,
      })
      .eq('id', step.value.id)
    if (error) throw error
    currentStepSaved = true

    step.value = {
      ...step.value,
      status: targetStatus,
      started_at: startedAt,
      ended_at: endedAt,
      notes: nullableText(stepForm.notes),
      actual_params: {
        ...actualParamsBase,
        parameters: parameterForms.value.map((row) => ({
          parameter_code: row.parameter_code || null,
          parameter_name: row.parameter_name || null,
          uom_code: row.uom_code || null,
          actual_value: nullableText(row.actual_value),
          comment: nullableText(row.comment),
        })),
      },
      quality_checks_json: qualityCheckForms.value.map((row) => ({
        check_code: row.check_code || null,
        check_name: row.check_name || null,
        sampling_point: nullableText(row.sampling_point),
        frequency: nullableText(row.frequency),
        required: Boolean(row.required),
        acceptance_criteria: row.acceptance_criteria ?? {},
        result_status: nullableText(row.result_status),
        result_value: nullableText(row.result_value),
        result_note: nullableText(row.result_note),
        checked_at: toIsoDateTime(row.checked_at),
        checked_by: nullableText(row.checked_by),
      })),
    }
    stepForm.status = targetStatus
    stepForm.ended_at = toDateTimeInputValue(endedAt)

    if (batch.value && shouldMoveNextStepToReady(previousStatus, targetStatus)) {
      await moveNextBatchStepToReady({
        batchId: batch.value.id,
        tenantId: batch.value.tenant_id,
        currentStepNo: step.value.step_no,
      })
    }
    stepSaveState.success = t('common.saved')
  } catch (err) {
    console.error(err)
    const message = extractErrorMessage(err) || t('common.unknown')
    stepSaveState.error = currentStepSaved
      ? t('batch.edit.stepTransitionFailed', { message })
      : `${t('batch.edit.stepSaveFailed')} (${message})`
  } finally {
    stepSaveState.saving = false
  }
}

async function moveNextBatchStepToReady(params: {
  batchId: string
  tenantId: string
  currentStepNo: number
}) {
  const mes = mesClient()
  const { data: nextStep, error: nextStepError } = await mes
    .from('batch_step')
    .select('id, status, step_no')
    .eq('tenant_id', params.tenantId)
    .eq('batch_id', params.batchId)
    .gt('step_no', params.currentStepNo)
    .order('step_no', { ascending: true })
    .limit(1)
    .maybeSingle()

  if (nextStepError) throw nextStepError
  if (!nextStep) return

  const nextStatus = safeText(nextStep.status)
  if (nextStatus === 'ready') return
  if (nextStatus !== 'open') return

  const { error } = await mes
    .from('batch_step')
    .update({
      status: 'ready',
      updated_by: currentUserId.value,
    })
    .eq('id', String(nextStep.id))

  if (error) throw error
}

function addActualMaterialRow() {
  actualMaterialForms.value.push({
    local_key: nextLocalKey('actual-material'),
    id: null,
    material_id: '',
    lot_id: '',
    actual_qty: '',
    uom_id: '',
    consumed_at: toDateTimeInputValue(new Date().toISOString()),
    note: '',
    snapshot_json: {},
  })
}

function removeActualMaterialRow(index: number) {
  actualMaterialForms.value.splice(index, 1)
}

function handleActualMaterialChange(index: number) {
  const row = actualMaterialForms.value[index]
  const material = materialOptions.value.find((option) => option.id === row.material_id)
  if (!material) return
  if (!row.uom_id && material.base_uom_id) row.uom_id = material.base_uom_id
  if (row.lot_id) {
    const lot = lotOptions.value.find((option) => option.id === row.lot_id)
    if (lot && lot.material_id && lot.material_id !== row.material_id) {
      row.lot_id = ''
    }
  }
}

function handleActualLotChange(index: number) {
  const row = actualMaterialForms.value[index]
  const lot = lotOptions.value.find((option) => option.id === row.lot_id)
  if (!lot) return
  if (!row.material_id && lot.material_id) row.material_id = lot.material_id
  if (!row.uom_id && lot.uom_id) row.uom_id = lot.uom_id
}

function lotOptionsForMaterial(materialId: string) {
  if (!materialId) return lotOptions.value
  return lotOptions.value.filter((option) => option.material_id === materialId || !option.material_id)
}

async function saveActualMaterials() {
  if (!step.value || !batch.value) return
  clearSectionState(actualMaterialsState)

  const rows = actualMaterialForms.value.filter((row) => !isActualMaterialRowEmpty(row))
  for (const row of rows) {
    if (!row.actual_qty || parseNumber(row.actual_qty) == null) {
      actualMaterialsState.error = t('errors.required', { field: t('batch.edit.stepActualQty') })
      return
    }
    if (!row.uom_id) {
      actualMaterialsState.error = t('errors.required', { field: t('recipe.materials.uomCode') })
      return
    }
    if (!row.material_id && !row.lot_id) {
      actualMaterialsState.error = t('batch.edit.stepMaterialOrLotRequired')
      return
    }
  }

  actualMaterialsState.saving = true
  try {
    await ensureCurrentUser()
    const mes = mesClient()
    const existingIds = new Set(loadedActualMaterialIds.value)
    const keptIds = new Set(rows.map((row) => row.id).filter((value): value is string => Boolean(value)))
    const deleteIds = [...existingIds].filter((id) => !keptIds.has(id))

    if (deleteIds.length) {
      const { error } = await mes.from('batch_material_actual').delete().in('id', deleteIds)
      if (error) throw error
    }

    for (const row of rows) {
      const material = materialOptions.value.find((option) => option.id === row.material_id)
      const lot = lotOptions.value.find((option) => option.id === row.lot_id)
      const payload = {
        tenant_id: batch.value.tenant_id,
        batch_id: batch.value.id,
        batch_step_id: step.value.id,
        material_id: nullableText(row.material_id),
        lot_id: nullableText(row.lot_id),
        actual_qty: parseNumber(row.actual_qty) ?? 0,
        uom_id: row.uom_id,
        consumed_at: toIsoDateTime(row.consumed_at) ?? new Date().toISOString(),
        snapshot_json: {
          ...(row.snapshot_json ?? {}),
          material_code: material?.code ?? null,
          material_name: material?.name ?? null,
          lot_no: lot?.lot_no ?? null,
        },
        note: nullableText(row.note),
      }

      if (row.id) {
        const { error } = await mes.from('batch_material_actual').update(payload).eq('id', row.id)
        if (error) throw error
      } else {
        const { error } = await mes.from('batch_material_actual').insert({
          ...payload,
          created_by: currentUserId.value,
        })
        if (error) throw error
      }
    }

    await loadStepCollections(step.value.id)
    actualMaterialsState.success = t('common.saved')
  } catch (err) {
    console.error(err)
    actualMaterialsState.error = `${t('batch.edit.stepSectionSaveFailed')} (${extractErrorMessage(err) || t('common.unknown')})`
  } finally {
    actualMaterialsState.saving = false
  }
}

function addEquipmentAssignmentRow() {
  equipmentAssignmentForms.value.push({
    local_key: nextLocalKey('equipment'),
    id: null,
    equipment_id: '',
    assignment_role: '',
    assigned_at: toDateTimeInputValue(new Date().toISOString()),
    released_at: '',
    snapshot_json: {},
  })
}

function removeEquipmentAssignmentRow(index: number) {
  equipmentAssignmentForms.value.splice(index, 1)
}

async function saveEquipmentAssignments() {
  if (!step.value || !batch.value) return
  clearSectionState(equipmentState)

  const rows = equipmentAssignmentForms.value.filter((row) => !isEquipmentAssignmentRowEmpty(row))
  for (const row of rows) {
    if (!row.equipment_id) {
      equipmentState.error = t('errors.required', { field: t('batch.edit.stepEquipment') })
      return
    }
    if (!row.assigned_at) {
      equipmentState.error = t('errors.required', { field: t('batch.edit.stepAssignedAt') })
      return
    }
    if (row.assigned_at && row.released_at && new Date(row.assigned_at).getTime() > new Date(row.released_at).getTime()) {
      equipmentState.error = t('batch.edit.stepTimeRangeError')
      return
    }
  }

  equipmentState.saving = true
  try {
    await ensureCurrentUser()
    const mes = mesClient()
    const existingIds = new Set(loadedEquipmentAssignmentIds.value)
    const keptIds = new Set(rows.map((row) => row.id).filter((value): value is string => Boolean(value)))
    const deleteIds = [...existingIds].filter((id) => !keptIds.has(id))

    if (deleteIds.length) {
      const { error } = await mes.from('batch_equipment_assignment').delete().in('id', deleteIds)
      if (error) throw error
    }

    for (const row of rows) {
      const equipment = equipmentOptions.value.find((option) => option.id === row.equipment_id)
      const payload = {
        tenant_id: batch.value.tenant_id,
        batch_id: batch.value.id,
        batch_step_id: step.value.id,
        equipment_id: row.equipment_id,
        assignment_role: nullableText(row.assignment_role),
        assigned_at: toIsoDateTime(row.assigned_at) ?? new Date().toISOString(),
        released_at: toIsoDateTime(row.released_at),
        snapshot_json: {
          ...(row.snapshot_json ?? {}),
          equipment_code: equipment?.code ?? null,
          equipment_name: equipment?.name ?? null,
        },
      }

      if (row.id) {
        const { error } = await mes.from('batch_equipment_assignment').update(payload).eq('id', row.id)
        if (error) throw error
      } else {
        const { error } = await mes.from('batch_equipment_assignment').insert({
          ...payload,
          created_by: currentUserId.value,
        })
        if (error) throw error
      }
    }

    await loadStepCollections(step.value.id)
    equipmentState.success = t('common.saved')
  } catch (err) {
    console.error(err)
    equipmentState.error = `${t('batch.edit.stepSectionSaveFailed')} (${extractErrorMessage(err) || t('common.unknown')})`
  } finally {
    equipmentState.saving = false
  }
}

function addExecutionLogRow() {
  executionLogForms.value.push({
    local_key: nextLocalKey('log'),
    id: null,
    event_type: 'comment',
    event_at: toDateTimeInputValue(new Date().toISOString()),
    comment: '',
    event_data: {},
  })
}

function removeExecutionLogRow(index: number) {
  executionLogForms.value.splice(index, 1)
}

async function saveExecutionLogs() {
  if (!step.value || !batch.value) return
  clearSectionState(logState)

  const rows = executionLogForms.value.filter((row) => !isExecutionLogRowEmpty(row))
  for (const row of rows) {
    if (!row.event_type) {
      logState.error = t('errors.required', { field: t('batch.edit.stepEventType') })
      return
    }
    if (!row.event_at) {
      logState.error = t('errors.required', { field: t('batch.edit.stepEventAt') })
      return
    }
  }

  logState.saving = true
  try {
    await ensureCurrentUser()
    const mes = mesClient()
    const existingIds = new Set(loadedExecutionLogIds.value)
    const keptIds = new Set(rows.map((row) => row.id).filter((value): value is string => Boolean(value)))
    const deleteIds = [...existingIds].filter((id) => !keptIds.has(id))

    if (deleteIds.length) {
      const { error } = await mes.from('batch_execution_log').delete().in('id', deleteIds)
      if (error) throw error
    }

    for (const row of rows) {
      const payload = {
        tenant_id: batch.value.tenant_id,
        batch_id: batch.value.id,
        batch_step_id: step.value.id,
        event_type: row.event_type,
        event_at: toIsoDateTime(row.event_at) ?? new Date().toISOString(),
        event_data: row.event_data ?? {},
        comment: nullableText(row.comment),
      }

      if (row.id) {
        const { error } = await mes.from('batch_execution_log').update(payload).eq('id', row.id)
        if (error) throw error
      } else {
        const { error } = await mes.from('batch_execution_log').insert({
          ...payload,
          actor_user_id: currentUserId.value,
        })
        if (error) throw error
      }
    }

    await loadStepCollections(step.value.id)
    logState.success = t('common.saved')
  } catch (err) {
    console.error(err)
    logState.error = `${t('batch.edit.stepSectionSaveFailed')} (${extractErrorMessage(err) || t('common.unknown')})`
  } finally {
    logState.saving = false
  }
}

function addDeviationRow() {
  deviationForms.value.push({
    local_key: nextLocalKey('deviation'),
    id: null,
    deviation_code: '',
    summary: '',
    severity: 'minor',
    status: 'open',
    opened_at: toDateTimeInputValue(new Date().toISOString()),
    closed_at: '',
    note: '',
    detail_json: {},
  })
}

function removeDeviationRow(index: number) {
  deviationForms.value.splice(index, 1)
}

async function saveDeviations() {
  if (!step.value || !batch.value) return
  clearSectionState(deviationState)

  const rows = deviationForms.value.filter((row) => !isDeviationRowEmpty(row))
  for (const row of rows) {
    if (!row.summary) {
      deviationState.error = t('errors.required', { field: t('batch.edit.stepDeviationSummary') })
      return
    }
    if (!row.opened_at) {
      deviationState.error = t('errors.required', { field: t('batch.edit.stepOpenedAt') })
      return
    }
    if (row.opened_at && row.closed_at && new Date(row.opened_at).getTime() > new Date(row.closed_at).getTime()) {
      deviationState.error = t('batch.edit.stepTimeRangeError')
      return
    }
  }

  deviationState.saving = true
  try {
    await ensureCurrentUser()
    const mes = mesClient()
    const existingIds = new Set(loadedDeviationIds.value)
    const keptIds = new Set(rows.map((row) => row.id).filter((value): value is string => Boolean(value)))
    const deleteIds = [...existingIds].filter((id) => !keptIds.has(id))

    if (deleteIds.length) {
      const { error } = await mes.from('batch_deviation').delete().in('id', deleteIds)
      if (error) throw error
    }

    for (const row of rows) {
      const payload = {
        tenant_id: batch.value.tenant_id,
        batch_id: batch.value.id,
        batch_step_id: step.value.id,
        deviation_code: nullableText(row.deviation_code),
        summary: row.summary,
        severity: row.severity,
        status: row.status,
        detail_json: {
          ...(row.detail_json ?? {}),
          note: nullableText(row.note),
        },
        opened_at: toIsoDateTime(row.opened_at) ?? new Date().toISOString(),
        closed_at: toIsoDateTime(row.closed_at),
        closed_by: row.closed_at ? currentUserId.value : null,
        updated_by: currentUserId.value,
      }

      if (row.id) {
        const { error } = await mes.from('batch_deviation').update(payload).eq('id', row.id)
        if (error) throw error
      } else {
        const { error } = await mes.from('batch_deviation').insert({
          ...payload,
          opened_by: currentUserId.value,
        })
        if (error) throw error
      }
    }

    await loadStepCollections(step.value.id)
    deviationState.success = t('common.saved')
  } catch (err) {
    console.error(err)
    deviationState.error = `${t('batch.edit.stepSectionSaveFailed')} (${extractErrorMessage(err) || t('common.unknown')})`
  } finally {
    deviationState.saving = false
  }
}

function buildParameterForms(stepRow: BatchExecutionStepRow) {
  const plannedRows = asArray(stepRow.planned_params?.parameters)
  const fallbackRows = plannedRows.length ? plannedRows : asArray(stepRow.snapshot_json?.parameters)
  const actualRows = asArray(stepRow.actual_params?.parameters)
  const actualMap = new Map<string, Record<string, any>>()
  actualRows.forEach((value: any, index: number) => {
    const row = asRecord(value) ?? {}
    const key = safeText(row.parameter_code) || safeText(row.parameter_name) || `actual-${index}`
    actualMap.set(key, row)
  })

  return fallbackRows.map((value: any, index: number) => {
    const row = asRecord(value) ?? {}
    const key = safeText(row.parameter_code) || safeText(row.parameter_name) || `planned-${index}`
    const actual = actualMap.get(key) ?? {}
    return {
      local_key: nextLocalKey('parameter'),
      parameter_code: safeText(row.parameter_code),
      parameter_name: safeText(row.parameter_name),
      target: row.target,
      min: row.min,
      max: row.max,
      uom_code: safeText(row.uom_code),
      actual_value: safeText(actual.actual_value),
      comment: safeText(actual.comment),
    }
  })
}

function buildQualityCheckForms(stepRow: BatchExecutionStepRow) {
  const checks = asArray(stepRow.quality_checks_json)
  const fallback = checks.length ? checks : asArray(stepRow.snapshot_json?.quality_checks)
  return fallback.map((value: any) => {
    const row = asRecord(value) ?? {}
    return {
      local_key: nextLocalKey('quality'),
      check_code: safeText(row.check_code),
      check_name: safeText(row.check_name),
      sampling_point: safeText(row.sampling_point),
      frequency: safeText(row.frequency),
      required: Boolean(row.required),
      acceptance_criteria: asRecord(row.acceptance_criteria),
      result_status: safeText(row.result_status),
      result_value: safeText(row.result_value),
      result_note: safeText(row.result_note),
      checked_at: toDateTimeInputValue(row.checked_at),
      checked_by: safeText(row.checked_by) || currentUserLabel.value,
    }
  })
}

function plannedMaterialLabel(row: BatchMaterialPlanRow) {
  return safeText(row.requirement_json?.material_name)
    || safeText(row.requirement_json?.material_code)
    || safeText(row.requirement_json?.material_type)
    || safeText(row.snapshot_json?.material_name)
    || safeText(row.snapshot_json?.material_code)
    || '—'
}

function clearAllStates() {
  clearSectionState(stepSaveState)
  clearSectionState(actualMaterialsState)
  clearSectionState(equipmentState)
  clearSectionState(logState)
  clearSectionState(deviationState)
}

function clearSectionState(state: SectionState) {
  state.error = ''
  state.success = ''
}

function resetCollections() {
  plannedMaterials.value = []
  parameterForms.value = []
  qualityCheckForms.value = []
  actualMaterialForms.value = []
  equipmentAssignmentForms.value = []
  executionLogForms.value = []
  deviationForms.value = []
  loadedActualMaterialIds.value = []
  loadedEquipmentAssignmentIds.value = []
  loadedExecutionLogIds.value = []
  loadedDeviationIds.value = []
}

function isActualMaterialRowEmpty(row: ActualMaterialFormRow) {
  return !row.material_id && !row.lot_id && !row.actual_qty && !row.uom_id && !row.note
}

function isEquipmentAssignmentRowEmpty(row: EquipmentAssignmentFormRow) {
  return !row.equipment_id && !row.assignment_role && !row.assigned_at && !row.released_at
}

function isExecutionLogRowEmpty(row: ExecutionLogFormRow) {
  return !row.event_type && !row.event_at && !row.comment
}

function isDeviationRowEmpty(row: DeviationFormRow) {
  return !row.deviation_code && !row.summary && !row.note
}

function toDateTimeInputValue(value: unknown) {
  const text = safeText(value)
  if (!text) return ''
  const date = new Date(text)
  if (Number.isNaN(date.getTime())) return ''
  const yyyy = date.getFullYear()
  const mm = String(date.getMonth() + 1).padStart(2, '0')
  const dd = String(date.getDate()).padStart(2, '0')
  const hh = String(date.getHours()).padStart(2, '0')
  const mi = String(date.getMinutes()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}T${hh}:${mi}`
}

function toIsoDateTime(value: string | null | undefined) {
  const text = safeText(value)
  if (!text) return null
  const date = new Date(text)
  if (Number.isNaN(date.getTime())) return null
  return date.toISOString()
}

function parseNumber(value: string | number | null | undefined) {
  if (typeof value === 'number') return Number.isFinite(value) ? value : null
  const text = safeText(value)
  if (!text) return null
  const parsed = Number(text)
  return Number.isFinite(parsed) ? parsed : null
}

function resolveNameI18n(value: unknown) {
  const record = asRecord(value)
  if (!record) return ''
  const lang = locale.value.toLowerCase().startsWith('ja') ? 'ja' : 'en'
  const primary = safeText(record[lang])
  if (primary) return primary
  const fallback = Object.values(record).find((item) => typeof item === 'string' && safeText(item))
  return typeof fallback === 'string' ? fallback : ''
}

function formatNumber(value: number | null | undefined) {
  if (value == null || Number.isNaN(Number(value))) return '—'
  return new Intl.NumberFormat(locale.value.startsWith('ja') ? 'ja-JP' : 'en-US', {
    maximumFractionDigits: 6,
  }).format(Number(value))
}

function formatDynamicValue(value: unknown) {
  if (value === null || value === undefined || value === '') return '—'
  if (typeof value === 'number') return formatNumber(value)
  if (typeof value === 'string') {
    const trimmed = value.trim()
    return trimmed || '—'
  }
  return String(value)
}

function formatDurationSeconds(value: number | null | undefined) {
  if (value == null || Number.isNaN(Number(value))) return '—'
  const total = Math.max(0, Math.trunc(Number(value)))
  const hours = Math.floor(total / 3600)
  const minutes = Math.floor((total % 3600) / 60)
  const seconds = total % 60
  if (hours > 0) return `${hours}${durationUnits.value.hour} ${minutes}${durationUnits.value.minute}`
  if (minutes > 0) return `${minutes}${durationUnits.value.minute} ${seconds}${durationUnits.value.second}`
  return `${seconds}${durationUnits.value.second}`
}

function isStepCompletionStatus(status: string | null | undefined) {
  const normalized = safeText(status)
  return normalized === 'completed' || normalized === 'skipped'
}

function shouldMoveNextStepToReady(previousStatus: string | null | undefined, nextStatus: string | null | undefined) {
  return !isStepCompletionStatus(previousStatus) && isStepCompletionStatus(nextStatus)
}

function uomLabel(uomId: string | null | undefined) {
  if (!uomId) return '—'
  const match = uomOptions.value.find((row) => row.id === uomId)
  if (!match) return uomId
  return match.name || match.code || uomId
}

function executionEventLabel(eventType: string | null | undefined) {
  const normalized = safeText(eventType)
  if (!normalized) return '—'

  const keyMap: Record<string, string> = {
    create: 'batch.edit.stepEventTypeOptions.create',
    release: 'batch.edit.stepEventTypeOptions.release',
    start: 'batch.edit.stepEventTypeOptions.start',
    pause: 'batch.edit.stepEventTypeOptions.pause',
    resume: 'batch.edit.stepEventTypeOptions.resume',
    complete: 'batch.edit.stepEventTypeOptions.complete',
    parameter_capture: 'batch.edit.stepEventTypeOptions.parameterCapture',
    qa_record: 'batch.edit.stepEventTypeOptions.qaRecord',
    material_issue: 'batch.edit.stepEventTypeOptions.materialIssue',
    equipment_assign: 'batch.edit.stepEventTypeOptions.equipmentAssign',
    deviation: 'batch.edit.stepEventTypeOptions.deviation',
    comment: 'batch.edit.stepEventTypeOptions.comment',
  }

  const messageKey = keyMap[normalized]
  return messageKey ? t(messageKey) : humanizeToken(normalized)
}

function humanizeToken(value: string | null | undefined) {
  const normalized = safeText(value)
  if (!normalized) return '—'
  return normalized
    .replace(/_/g, ' ')
    .replace(/\b\w/g, (char) => char.toUpperCase())
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

function safeNullableText(value: unknown) {
  const text = safeText(value)
  return text || null
}

function nullableText(value: unknown) {
  return safeText(value) || null
}

function extractErrorMessage(error: unknown) {
  if (error && typeof error === 'object' && 'message' in error) {
    const message = (error as { message?: unknown }).message
    if (typeof message === 'string') return message
  }
  if (typeof error === 'string') return error
  return ''
}

watch([batchId, stepId], () => {
  void loadPage()
}, { immediate: true })
</script>
