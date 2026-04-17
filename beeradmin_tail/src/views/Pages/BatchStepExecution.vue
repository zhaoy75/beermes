<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="space-y-5">
      <section class="rounded-lg border border-gray-200 bg-white shadow">
        <header class="flex flex-col gap-2 border-b px-4 py-3 md:flex-row md:items-start md:justify-between">
          <div>
            <h2 class="text-base font-semibold text-gray-900">{{ pageTitle }}</h2>
            <p class="text-xs text-gray-500">{{ pageSubtitle }}</p>
          </div>
          <div class="flex flex-wrap gap-2">
            <button class="rounded border border-gray-300 px-3 py-1.5 text-sm hover:bg-gray-100" type="button" @click="goBack">
              {{ t('batch.edit.backToBatch') }}
            </button>
            <button
              class="rounded bg-brand-500 px-3 py-1.5 text-sm text-white hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-60"
              type="button"
              :disabled="!step || loadingPage || stepSaveState.saving"
              @click="saveStepInputs"
            >
              {{ stepSaveState.saving ? t('common.loading') : t('batch.edit.stepSaveInputs') }}
            </button>
          </div>
        </header>

        <div v-if="loadingPage" class="p-5 text-sm text-gray-500">
          {{ t('common.loading') }}
        </div>
        <div v-else-if="pageError" class="p-5 text-sm text-red-600">
          {{ pageError }}
        </div>
        <template v-else-if="step && batch">
          <div v-if="stepSaveState.error" class="border-b border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {{ stepSaveState.error }}
          </div>
          <div v-else-if="stepSaveState.success" class="border-b border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
            {{ stepSaveState.success }}
          </div>

          <div class="grid grid-cols-1 gap-2.5 p-3 md:grid-cols-2 xl:grid-cols-6">
            <div class="rounded-lg border border-gray-200 px-3 py-2">
              <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.batchCode') }}</div>
              <div class="mt-0.5 text-sm font-medium text-gray-800">{{ batch.batch_code || '—' }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 px-3 py-2">
              <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.productName') }}</div>
              <div class="mt-0.5 text-sm font-medium text-gray-800">{{ batch.product_name || '—' }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 px-3 py-2 md:col-span-2 xl:col-span-2">
              <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.releasedRecipeTitle') }}</div>
              <div class="mt-0.5 flex flex-wrap items-center gap-1.5 text-sm">
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
            <div class="rounded-lg border border-gray-200 px-3 py-2">
              <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.stepName') }}</div>
              <div class="mt-0.5 text-sm font-medium text-gray-800">{{ `${step.step_no}. ${step.step_name}` }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 px-3 py-2">
              <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.stepCode') }}</div>
              <div class="mt-0.5 text-sm font-medium text-gray-800">{{ step.step_code }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 px-3 py-2">
              <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.stepTemplate') }}</div>
              <div class="mt-0.5 text-sm text-gray-700">{{ step.step_template_code || '—' }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 px-3 py-2">
              <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.stepType') }}</div>
              <div class="mt-0.5 text-sm text-gray-700">{{ selectedStepTypeText }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 px-3 py-2 md:col-span-2 xl:col-span-3">
              <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.stepInstructions') }}</div>
              <div class="mt-0.5 whitespace-pre-wrap text-sm leading-5 text-gray-700">{{ selectedStepInstructionsText }}</div>
            </div>
          </div>
        </template>
      </section>

      <template v-if="step && batch">
        <section class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="border-b px-4 py-2.5">
            <h3 class="text-sm font-semibold text-gray-900">{{ t('batch.edit.stepExecutionControlTitle') }}</h3>
          </div>
          <div class="grid grid-cols-1 gap-3 p-3 xl:grid-cols-[minmax(0,1.3fr)_minmax(0,0.7fr)]">
            <div class="grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-4">
              <div>
                <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.stepStatus') }}</label>
                <select v-model="stepForm.status" class="h-[36px] w-full rounded border px-2.5 text-sm">
                  <option v-for="option in stepStatusOptions" :key="option.value" :value="option.value">
                    {{ option.label }}
                  </option>
                </select>
              </div>
              <div>
                <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.stepStartedAt') }}</label>
                <input v-model="stepForm.started_at" type="datetime-local" class="h-[36px] w-full rounded border px-2.5 text-sm" />
              </div>
              <div>
                <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.stepEndedAt') }}</label>
                <input v-model="stepForm.ended_at" type="datetime-local" class="h-[36px] w-full rounded border px-2.5 text-sm" />
              </div>
              <div>
                <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.stepDuration') }}</label>
                <div class="flex h-[36px] items-center rounded border bg-gray-50 px-2.5 text-sm text-gray-700">
                  {{ formatDurationSeconds(step.planned_duration_sec) }}
                </div>
              </div>
              <div class="md:col-span-2 xl:col-span-4">
                <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.notes') }}</label>
                <textarea v-model.trim="stepForm.notes" rows="2" class="w-full rounded border px-2.5 py-2 text-sm" />
              </div>
            </div>

            <div class="grid grid-cols-1 gap-3 sm:grid-cols-2 xl:grid-cols-1">
              <div class="rounded-lg border border-gray-200 bg-gray-50 px-3 py-3">
                <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.stepCurrentStatusSummary') }}</div>
                <div class="mt-1 text-sm font-semibold text-gray-900">{{ currentStepStatusSummaryLabel }}</div>
              </div>
              <div class="rounded-lg border border-gray-200 bg-gray-50 px-3 py-3">
                <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.stepLatestTimestampSummary') }}</div>
                <div class="mt-1 text-sm font-semibold text-gray-900">{{ latestExecutionTimestampSummaryLabel }}</div>
              </div>
            </div>
          </div>
        </section>

        <section class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="flex flex-col gap-3 border-b px-4 py-3 md:flex-row md:items-start md:justify-between">
            <div>
              <h3 class="text-sm font-semibold text-gray-900">{{ `${t('batch.edit.stepPlannedMaterialsTitle')} / ${t('batch.edit.stepActualMaterialsTitle')}` }}</h3>
              <p class="mt-1 text-xs text-gray-500">{{ t('batch.edit.stepMaterialSectionHint') }}</p>
            </div>
            <div class="flex flex-wrap gap-2">
              <button
                v-for="tab in materialWorkspaceTabs"
                :key="tab.value"
                class="inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-xs font-medium transition"
                :class="materialWorkspaceTab === tab.value ? 'border-brand-500 bg-brand-50 text-brand-700' : 'border-gray-300 text-gray-600 hover:bg-gray-100'"
                type="button"
                @click="materialWorkspaceTab = tab.value"
              >
                <span>{{ tab.label }}</span>
                <span class="rounded-full bg-white/80 px-1.5 py-0.5 text-[11px] text-gray-500">{{ tab.count }}</span>
              </button>
            </div>
          </div>
          <div v-if="actualMaterialsState.error" class="border-b border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {{ actualMaterialsState.error }}
          </div>
          <div v-else-if="actualMaterialsState.success" class="border-b border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
            {{ actualMaterialsState.success }}
          </div>

          <template v-if="materialWorkspaceTab === 'inputs'">
            <div class="flex flex-col gap-2 border-b px-4 py-3 md:flex-row md:items-center md:justify-between">
              <p class="text-xs text-gray-500">{{ t('batch.edit.stepMaterialCompactHint') }}</p>
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
            <div v-if="materialExecutionRows.length === 0" class="p-4 text-sm text-gray-500">{{ t('common.noData') }}</div>
            <div v-else class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200 text-sm">
                <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                  <tr>
                    <th class="px-3 py-2 text-left">{{ t('recipe.edit.materialTypeFilter') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('recipe.materials.qty') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('recipe.materials.uomCode') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('recipe.itemEditor.consumptionMode') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('batch.edit.stepMaterial') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('batch.edit.stepActualQty') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('batch.edit.stepDetailToggle') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('common.delete') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <template v-for="(displayRow, index) in materialExecutionRows" :key="displayRow.row.local_key">
                    <tr>
                      <td class="px-3 py-2 text-gray-700">
                        <div>{{ displayRow.planTypeLabel }}</div>
                        <div v-if="displayRow.planRoleLabel" class="text-xs text-gray-500">{{ displayRow.planRoleLabel }}</div>
                      </td>
                      <td class="px-3 py-2 text-right text-gray-700">{{ displayRow.planQtyLabel }}</td>
                      <td class="px-3 py-2 text-gray-700">{{ displayRow.planUomLabel }}</td>
                      <td class="px-3 py-2 text-gray-700">{{ displayRow.planConsumptionModeLabel }}</td>
                      <td class="px-3 py-2">
                        <select v-model="displayRow.row.material_id" class="h-[36px] w-full rounded border px-2" @change="handleActualMaterialChange(index)">
                          <option value="">{{ t('common.select') }}</option>
                          <option v-for="option in materialOptionsForActualRow(displayRow.row)" :key="option.id" :value="option.id">{{ option.label }}</option>
                        </select>
                      </td>
                      <td class="px-3 py-2">
                        <input v-model.trim="displayRow.row.actual_qty" type="number" step="any" min="0" class="h-[36px] w-full rounded border px-2 text-right" />
                      </td>
                      <td class="px-3 py-2">
                        <button class="rounded border border-gray-300 px-2 py-1 text-xs hover:bg-gray-100" type="button" @click="toggleActualMaterialDetails(displayRow.row.local_key)">
                          {{ isActualMaterialDetailsOpen(displayRow.row.local_key) ? t('batch.edit.stepHideDetails') : t('batch.edit.stepShowDetails') }}
                        </button>
                      </td>
                      <td class="px-3 py-2">
                        <button class="rounded border border-gray-300 px-2 py-1 text-xs hover:bg-gray-100" type="button" @click="removeActualMaterialRow(index)">
                          {{ t('common.delete') }}
                        </button>
                      </td>
                    </tr>
                    <tr v-if="isActualMaterialDetailsOpen(displayRow.row.local_key)" class="bg-gray-50/70">
                      <td colspan="8" class="px-3 py-3">
                        <div class="grid grid-cols-1 gap-3 md:grid-cols-3">
                          <div>
                            <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.stepLot') }}</label>
                            <select v-model="displayRow.row.lot_id" class="h-[36px] w-full rounded border px-2 text-sm" @change="handleActualLotChange(displayRow.row)">
                              <option value="">{{ t('common.select') }}</option>
                              <option v-for="option in lotOptionsForActualRow(displayRow.row)" :key="option.id" :value="option.id">{{ option.label }}</option>
                            </select>
                          </div>
                          <div>
                            <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.stepConsumedAt') }}</label>
                            <input v-model="displayRow.row.consumed_at" type="datetime-local" class="h-[36px] w-full rounded border px-2 text-sm" />
                          </div>
                          <div>
                            <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.notes') }}</label>
                            <input v-model.trim="displayRow.row.note" type="text" class="h-[36px] w-full rounded border px-2 text-sm" />
                          </div>
                        </div>
                      </td>
                    </tr>
                  </template>
                </tbody>
              </table>
            </div>
          </template>

          <template v-else>
            <div class="flex flex-col gap-2 border-b px-4 py-3 md:flex-row md:items-center md:justify-between">
              <p class="text-xs text-gray-500">{{ t('batch.edit.stepSavedWithStepInputsHint') }}</p>
              <button class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-100" type="button" @click="addOutputMaterialRow">
                {{ t('recipe.itemEditor.addOutputMaterial') }}
              </button>
            </div>
            <div v-if="outputMaterialForms.length === 0" class="p-4 text-sm text-gray-500">{{ t('recipe.itemEditor.noOutputMaterials') }}</div>
            <div v-else class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200 text-sm">
                <thead class="bg-gray-50 text-xs uppercase text-gray-600">
                  <tr>
                    <th class="px-3 py-2 text-left">{{ t('recipe.itemEditor.outputMaterialType') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('recipe.materials.qty') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('recipe.materials.uomCode') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('recipe.edit.outputType') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('batch.edit.stepActualQty') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('common.delete') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="(row, index) in outputMaterialForms" :key="row.local_key">
                    <td class="px-3 py-2 text-gray-700">
                      <template v-if="row.planned_output_index !== null">
                        <div>{{ row.output_material_type || '—' }}</div>
                        <div v-if="row.output_name" class="text-xs text-gray-500">{{ row.output_name }}</div>
                      </template>
                      <template v-else>
                        <input v-model.trim="row.output_material_type" type="text" class="h-[36px] w-full rounded border px-2" />
                        <input v-model.trim="row.output_name" type="text" class="mt-2 h-[36px] w-full rounded border px-2" />
                      </template>
                    </td>
                    <td class="px-3 py-2 text-right text-gray-700">{{ formatDynamicValue(row.planned_qty) }}</td>
                    <td class="px-3 py-2 text-gray-700">
                      <template v-if="row.planned_output_index !== null">
                        {{ row.uom_code || '—' }}
                      </template>
                      <template v-else>
                        <input v-model.trim="row.uom_code" type="text" class="h-[36px] w-full rounded border px-2" />
                      </template>
                    </td>
                    <td class="px-3 py-2 text-gray-700">
                      <template v-if="row.planned_output_index !== null">
                        {{ outputTypeLabel(row.output_type) }}
                      </template>
                      <template v-else>
                        <select v-model="row.output_type" class="h-[36px] w-full rounded border px-2">
                          <option value="">{{ t('common.select') }}</option>
                          <option v-for="option in outputTypeOptions" :key="option.value" :value="option.value">
                            {{ option.label }}
                          </option>
                        </select>
                      </template>
                    </td>
                    <td class="px-3 py-2">
                      <input v-model.trim="row.actual_qty" type="number" step="any" min="0" class="h-[36px] w-full rounded border px-2 text-right" />
                    </td>
                    <td class="px-3 py-2">
                      <button class="rounded border border-gray-300 px-2 py-1 text-xs hover:bg-gray-100" type="button" @click="removeOutputMaterialRow(index)">
                        {{ t('common.delete') }}
                      </button>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </template>
        </section>

        <section class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="flex flex-col gap-3 border-b px-4 py-3 md:flex-row md:items-center md:justify-between">
            <div>
              <h3 class="text-sm font-semibold text-gray-900">{{ t('batch.edit.stepEquipmentTitle') }}</h3>
              <p class="mt-1 text-xs text-gray-500">{{ t('batch.edit.stepEquipmentSectionHint') }}</p>
            </div>
            <div class="flex flex-wrap gap-2">
              <button class="rounded border border-gray-300 px-3 py-2 text-sm hover:bg-gray-100" type="button" @click="addEquipmentAssignmentRow">
                {{ t('batch.edit.stepStartOtherEquipment') }}
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
          <div class="grid grid-cols-2 gap-3 border-b p-3 md:grid-cols-4">
            <div class="rounded-lg border border-gray-200 bg-gray-50 px-3 py-2">
              <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.stepEquipmentRequiredCount') }}</div>
              <div class="mt-1 text-lg font-semibold text-gray-900">{{ requiredEquipmentCount }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 bg-gray-50 px-3 py-2">
              <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.stepEquipmentReservedCount') }}</div>
              <div class="mt-1 text-lg font-semibold text-gray-900">{{ equipmentReservations.length }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 bg-gray-50 px-3 py-2">
              <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.stepEquipmentInUseCount') }}</div>
              <div class="mt-1 text-lg font-semibold text-gray-900">{{ activeEquipmentAssignmentCount }}</div>
            </div>
            <div class="rounded-lg border border-gray-200 bg-gray-50 px-3 py-2">
              <div class="text-[11px] uppercase tracking-wide text-gray-500">{{ t('batch.edit.stepEquipmentMismatchCount') }}</div>
              <div class="mt-1 text-lg font-semibold text-gray-900">{{ mismatchedEquipmentAssignmentCount }}</div>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-3 p-3 xl:grid-cols-[minmax(0,0.9fr)_minmax(0,1.1fr)]">
            <div class="space-y-3">
              <section class="rounded-lg border border-gray-200">
                <div class="border-b bg-gray-50 px-3 py-2">
                  <h4 class="text-sm font-medium text-gray-900">{{ t('batch.edit.stepEquipmentPlannedTitle') }}</h4>
                </div>
                <div v-if="stepEquipmentRequirements.length === 0" class="px-3 py-4 text-sm text-gray-500">{{ t('common.noData') }}</div>
                <ul v-else class="divide-y divide-gray-100">
                  <li v-for="requirement in stepEquipmentRequirements" :key="requirement.local_key" class="px-3 py-3">
                    <div class="flex items-start justify-between gap-3">
                      <div class="min-w-0">
                        <div class="text-sm font-medium text-gray-900">{{ equipmentRequirementLabel(requirement) }}</div>
                        <div v-if="requirement.equipment_template_code" class="mt-1 text-xs text-gray-500">
                          {{ t('batch.edit.stepEquipmentTemplate') }}: {{ requirement.equipment_template_code }}
                        </div>
                        <div v-if="requirement.notes" class="mt-1 text-xs text-gray-500">{{ requirement.notes }}</div>
                      </div>
                      <span class="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-700">
                        x{{ requirement.quantity }}
                      </span>
                    </div>
                    <div class="mt-2 text-xs text-gray-500">
                      {{ t('batch.edit.stepEquipmentCoverageSummary', {
                        reserved: equipmentRequirementReservationCount(requirement),
                        actual: equipmentRequirementActualCount(requirement),
                      }) }}
                    </div>
                  </li>
                </ul>
              </section>

              <section class="rounded-lg border border-gray-200">
                <div class="border-b bg-gray-50 px-3 py-2">
                  <h4 class="text-sm font-medium text-gray-900">{{ t('batch.edit.stepEquipmentReservedTitle') }}</h4>
                </div>
                <div v-if="equipmentReservations.length === 0" class="px-3 py-4 text-sm text-gray-500">{{ t('common.noData') }}</div>
                <div v-else class="divide-y divide-gray-100">
                  <article v-for="reservation in equipmentReservations" :key="reservation.id" class="space-y-2 px-3 py-3">
                    <div class="flex items-start justify-between gap-3">
                      <div class="min-w-0">
                        <div class="text-sm font-medium text-gray-900">{{ equipmentLabel(reservation.equipment_id) }}</div>
                        <div class="mt-1 flex flex-wrap gap-1.5">
                          <span class="rounded-full bg-blue-50 px-2 py-0.5 text-xs font-medium text-blue-700">
                            {{ reservationStatusLabel(reservation.status) }}
                          </span>
                          <span class="rounded-full bg-gray-100 px-2 py-0.5 text-xs font-medium text-gray-700">
                            {{ reservationTypeLabel(reservation.reservation_type) }}
                          </span>
                          <span
                            v-if="linkedEquipmentAssignmentByReservationId.has(reservation.id)"
                            class="rounded-full bg-emerald-50 px-2 py-0.5 text-xs font-medium text-emerald-700"
                          >
                            {{ t('batch.edit.stepEquipmentReservedLinked') }}
                          </span>
                        </div>
                      </div>
                      <button
                        class="rounded border border-gray-300 px-2 py-1 text-xs hover:bg-gray-100 disabled:cursor-not-allowed disabled:opacity-60"
                        type="button"
                        :disabled="linkedEquipmentAssignmentByReservationId.has(reservation.id)"
                        @click="useReservedEquipment(reservation.id)"
                      >
                        {{ t('batch.edit.stepUseReservedEquipment') }}
                      </button>
                    </div>
                    <div class="text-xs text-gray-500">{{ formatDateTimeRangeLabel(reservation.start_at, reservation.end_at) }}</div>
                    <div v-if="reservation.note" class="text-xs text-gray-500">{{ reservation.note }}</div>
                  </article>
                </div>
              </section>
            </div>

            <section class="rounded-lg border border-gray-200">
              <div class="border-b bg-gray-50 px-3 py-2">
                <h4 class="text-sm font-medium text-gray-900">{{ t('batch.edit.stepEquipmentActualTitle') }}</h4>
              </div>
              <div v-if="equipmentAssignmentForms.length === 0" class="px-4 py-6 text-sm text-gray-500">
                {{ t('batch.edit.stepEquipmentEmptyHint') }}
              </div>
              <div v-else class="space-y-3 p-3">
                <article
                  v-for="(row, index) in equipmentAssignmentForms"
                  :key="row.local_key"
                  class="rounded-lg border p-3"
                  :class="equipmentAssignmentCardClass(row)"
                >
                  <div class="flex flex-col gap-3 border-b border-gray-100 pb-3 md:flex-row md:items-start md:justify-between">
                    <div class="min-w-0">
                      <div class="text-sm font-semibold text-gray-900">{{ equipmentAssignmentHeading(row, index) }}</div>
                      <div class="mt-1 flex flex-wrap gap-1.5">
                        <span class="rounded-full px-2 py-0.5 text-xs font-medium" :class="equipmentAssignmentStatusBadgeClass(row.status)">
                          {{ equipmentAssignmentStatusLabel(row.status) }}
                        </span>
                        <span
                          v-if="row.reservation_id"
                          class="rounded-full bg-blue-50 px-2 py-0.5 text-xs font-medium text-blue-700"
                        >
                          {{ t('batch.edit.stepEquipmentReservationLinkedBadge') }}
                        </span>
                        <span
                          v-if="equipmentAssignmentHasReservationMismatch(row)"
                          class="rounded-full bg-amber-50 px-2 py-0.5 text-xs font-medium text-amber-700"
                        >
                          {{ t('batch.edit.stepEquipmentReservationMismatch') }}
                        </span>
                        <span
                          v-else-if="equipmentAssignmentHasRequirementMismatch(row)"
                          class="rounded-full bg-amber-50 px-2 py-0.5 text-xs font-medium text-amber-700"
                        >
                          {{ t('batch.edit.stepEquipmentRequirementMismatch') }}
                        </span>
                      </div>
                      <p v-if="row.reservation_id && equipmentReservationById.get(row.reservation_id)" class="mt-1 text-xs text-gray-500">
                        {{ formatDateTimeRangeLabel(
                          equipmentReservationById.get(row.reservation_id)?.start_at ?? '',
                          equipmentReservationById.get(row.reservation_id)?.end_at ?? '',
                        ) }}
                      </p>
                    </div>
                    <button class="rounded border border-gray-300 px-2 py-1 text-xs hover:bg-gray-100" type="button" @click="removeEquipmentAssignmentRow(index)">
                      {{ t('common.delete') }}
                    </button>
                  </div>

                  <div class="mt-3 grid grid-cols-1 gap-3 md:grid-cols-2 xl:grid-cols-3">
                    <div>
                      <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.stepEquipment') }}</label>
                      <select v-model="row.equipment_id" class="h-[36px] w-full rounded border px-2 text-sm" @change="handleEquipmentSelectionChange(row)">
                        <option value="">{{ t('common.select') }}</option>
                        <option v-for="option in equipmentOptionsForAssignmentRow(row)" :key="option.id" :value="option.id">
                          {{ option.label }}
                        </option>
                      </select>
                    </div>
                    <div>
                      <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.stepAssignmentRole') }}</label>
                      <select v-model="row.assignment_role" class="h-[36px] w-full rounded border px-2 text-sm">
                        <option value="">{{ t('common.select') }}</option>
                        <option v-for="option in assignmentRoleOptions" :key="option.value" :value="option.value">
                          {{ option.label }}
                        </option>
                      </select>
                    </div>
                    <div>
                      <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.stepAssignmentStatus') }}</label>
                      <select v-model="row.status" class="h-[36px] w-full rounded border px-2 text-sm" @change="handleEquipmentStatusChange(row)">
                        <option v-for="option in assignmentStatusOptions" :key="option.value" :value="option.value">
                          {{ option.label }}
                        </option>
                      </select>
                    </div>
                    <div>
                      <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.stepEquipmentReservation') }}</label>
                      <select v-model="row.reservation_id" class="h-[36px] w-full rounded border px-2 text-sm" @change="handleEquipmentReservationChange(row)">
                        <option value="">{{ t('common.select') }}</option>
                        <option v-for="option in equipmentReservationOptions" :key="option.id" :value="option.id">
                          {{ option.label }}
                        </option>
                      </select>
                    </div>
                    <div>
                      <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.stepAssignedAt') }}</label>
                      <input v-model="row.assigned_at" type="datetime-local" class="h-[36px] w-full rounded border px-2 text-sm" />
                    </div>
                    <div>
                      <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.stepReleasedAt') }}</label>
                      <input v-model="row.released_at" type="datetime-local" class="h-[36px] w-full rounded border px-2 text-sm" />
                    </div>
                    <div class="md:col-span-2 xl:col-span-3">
                      <label class="mb-1 block text-xs font-medium text-gray-600">{{ t('batch.edit.stepAssignmentNote') }}</label>
                      <textarea v-model.trim="row.note" rows="2" class="w-full rounded border px-2 py-2 text-sm" />
                    </div>
                  </div>

                  <div class="mt-3 flex flex-wrap gap-2">
                    <button class="rounded border border-emerald-300 px-2 py-1 text-xs font-medium text-emerald-700 hover:bg-emerald-50" type="button" @click="applyEquipmentAssignmentAction(row, 'start')">
                      {{ t('batch.edit.stepStartUse') }}
                    </button>
                    <button class="rounded border border-gray-300 px-2 py-1 text-xs font-medium text-gray-700 hover:bg-gray-100" type="button" @click="applyEquipmentAssignmentAction(row, 'release')">
                      {{ t('batch.edit.stepReleaseEquipment') }}
                    </button>
                    <button class="rounded border border-blue-300 px-2 py-1 text-xs font-medium text-blue-700 hover:bg-blue-50" type="button" @click="applyEquipmentAssignmentAction(row, 'complete')">
                      {{ t('batch.edit.stepCompleteEquipment') }}
                    </button>
                    <button class="rounded border border-rose-300 px-2 py-1 text-xs font-medium text-rose-700 hover:bg-rose-50" type="button" @click="applyEquipmentAssignmentAction(row, 'cancel')">
                      {{ t('batch.edit.stepCancelEquipment') }}
                    </button>
                  </div>
                </article>
              </div>
            </section>
          </div>
        </section>

        <section class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="flex flex-col gap-3 border-b px-4 py-3 md:flex-row md:items-start md:justify-between">
            <div>
              <h3 class="text-sm font-semibold text-gray-900">{{ t('batch.edit.stepExecutionDetailsTitle') }}</h3>
              <p class="mt-1 text-xs text-gray-500">{{ t('batch.edit.stepExecutionDetailsHint') }}</p>
            </div>
            <div class="flex flex-wrap gap-2">
              <button
                v-for="tab in secondaryWorkspaceTabs"
                :key="tab.value"
                class="inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-xs font-medium transition"
                :class="secondaryWorkspaceTab === tab.value ? 'border-brand-500 bg-brand-50 text-brand-700' : 'border-gray-300 text-gray-600 hover:bg-gray-100'"
                type="button"
                @click="secondaryWorkspaceTab = tab.value"
              >
                <span>{{ tab.label }}</span>
                <span class="rounded-full bg-white/80 px-1.5 py-0.5 text-[11px] text-gray-500">{{ tab.count }}</span>
              </button>
            </div>
          </div>

          <div class="flex flex-col gap-2 border-b px-4 py-3 md:flex-row md:items-center md:justify-between">
            <p v-if="secondaryWorkspaceTab === 'parameters' || secondaryWorkspaceTab === 'qa'" class="text-xs text-gray-500">
              {{ t('batch.edit.stepSavedWithStepInputsHint') }}
            </p>
            <div v-else />
            <div class="flex flex-wrap gap-2">
              <template v-if="secondaryWorkspaceTab === 'logs'">
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
              </template>
              <template v-else-if="secondaryWorkspaceTab === 'deviations'">
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
              </template>
            </div>
          </div>

          <div v-if="secondaryWorkspaceTab === 'logs' && logState.error" class="border-b border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {{ logState.error }}
          </div>
          <div v-else-if="secondaryWorkspaceTab === 'logs' && logState.success" class="border-b border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
            {{ logState.success }}
          </div>
          <div v-if="secondaryWorkspaceTab === 'deviations' && deviationState.error" class="border-b border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
            {{ deviationState.error }}
          </div>
          <div v-else-if="secondaryWorkspaceTab === 'deviations' && deviationState.success" class="border-b border-emerald-200 bg-emerald-50 px-4 py-3 text-sm text-emerald-700">
            {{ deviationState.success }}
          </div>

          <div v-if="secondaryWorkspaceTab === 'parameters'">
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
          </div>

          <div v-else-if="secondaryWorkspaceTab === 'qa'">
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
          </div>

          <div v-else-if="secondaryWorkspaceTab === 'logs'">
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
          </div>

          <div v-else>
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
  meta: Record<string, any>
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
  material_type_id: string | null
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
  material_type_id: string | null
  label: string
}

type LotOption = {
  id: string
  lot_no: string
  material_id: string | null
  uom_id: string | null
  label: string
}

type PersistActualMaterialsOptions = {
  clearState?: boolean
  setSavingState?: boolean
  showSuccess?: boolean
  reloadCollections?: boolean
}

type EquipmentOption = {
  id: string
  code: string
  name: string
  label: string
  equipment_type_id: string | null
  site_id: string | null
  equipment_status: string | null
}

type EquipmentTypeOption = {
  id: string
  code: string
  name: string
  label: string
}

type EquipmentRequirementRow = {
  local_key: string
  equipment_type_code: string
  equipment_template_code: string
  quantity: number
  notes: string
  type_id: string | null
}

type EquipmentReservationRow = {
  id: string
  site_id: string
  equipment_id: string
  reservation_type: string
  status: string
  start_at: string
  end_at: string
  note: string
  meta_json: Record<string, any>
  batch_step_id: string | null
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
  planned_plan_id: string
  material_id: string
  lot_id: string
  actual_qty: string
  uom_id: string
  consumed_at: string
  note: string
  snapshot_json: Record<string, any>
}

type OutputMaterialFormRow = {
  local_key: string
  planned_output_index: number | null
  output_material_type: string
  output_name: string
  output_type: string
  planned_qty: unknown
  uom_code: string
  actual_qty: string
}

type MaterialExecutionDisplayRow = {
  row: ActualMaterialFormRow
  planTypeLabel: string
  planRoleLabel: string
  planQtyLabel: string
  planUomLabel: string
  planConsumptionModeLabel: string
}

type EquipmentAssignmentFormRow = {
  local_key: string
  id: string | null
  equipment_id: string
  reservation_id: string
  assignment_role: string
  status: string
  assigned_at: string
  released_at: string
  note: string
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

type MaterialWorkspaceTab = 'inputs' | 'outputs'
type SecondaryWorkspaceTab = 'parameters' | 'qa' | 'logs' | 'deviations'

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
const materialWorkspaceTab = ref<MaterialWorkspaceTab>('inputs')
const secondaryWorkspaceTab = ref<SecondaryWorkspaceTab>('parameters')
const expandedActualMaterialRowKeys = ref<string[]>([])

const plannedMaterials = ref<BatchMaterialPlanRow[]>([])
const parameterForms = ref<ParameterFormRow[]>([])
const qualityCheckForms = ref<QualityCheckFormRow[]>([])
const actualMaterialForms = ref<ActualMaterialFormRow[]>([])
const outputMaterialForms = ref<OutputMaterialFormRow[]>([])
const equipmentAssignmentForms = ref<EquipmentAssignmentFormRow[]>([])
const executionLogForms = ref<ExecutionLogFormRow[]>([])
const deviationForms = ref<DeviationFormRow[]>([])
const loadedActualMaterialIds = ref<string[]>([])
const loadedExecutionLogIds = ref<string[]>([])
const loadedDeviationIds = ref<string[]>([])

const uomOptions = ref<UomOption[]>([])
const materialOptions = ref<MaterialOption[]>([])
const lotOptions = ref<LotOption[]>([])
const equipmentOptions = ref<EquipmentOption[]>([])
const equipmentTypeOptions = ref<EquipmentTypeOption[]>([])
const equipmentReservations = ref<EquipmentReservationRow[]>([])

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

const hasBackflushPlannedMaterials = computed(() =>
  plannedMaterials.value.some((row) => plannedMaterialConsumptionMode(row) === 'backflush'),
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

const outputTypeOptions = computed(() => [
  { value: 'primary', label: t('recipe.itemEditor.outputTypePrimary') },
  { value: 'intermediate', label: t('recipe.itemEditor.outputTypeIntermediate') },
  { value: 'co_product', label: t('recipe.itemEditor.outputTypeCoProduct') },
  { value: 'waste', label: t('recipe.itemEditor.outputTypeWaste') },
])

const assignmentRoleOptions = computed(() => [
  { value: 'main', label: t('batch.edit.stepAssignmentRoleOptions.main') },
  { value: 'aux', label: t('batch.edit.stepAssignmentRoleOptions.aux') },
  { value: 'qc', label: t('batch.edit.stepAssignmentRoleOptions.qc') },
  { value: 'cleaning', label: t('batch.edit.stepAssignmentRoleOptions.cleaning') },
])

const assignmentStatusOptions = computed(() => [
  { value: 'assigned', label: t('equipmentSchedule.assignmentStatuses.assigned') },
  { value: 'in_use', label: t('equipmentSchedule.assignmentStatuses.in_use') },
  { value: 'done', label: t('equipmentSchedule.assignmentStatuses.done') },
  { value: 'cancelled', label: t('equipmentSchedule.assignmentStatuses.cancelled') },
])

const equipmentOptionById = computed(() => {
  const map = new Map<string, EquipmentOption>()
  equipmentOptions.value.forEach((row) => {
    map.set(row.id, row)
  })
  return map
})

const equipmentTypeByCode = computed(() => {
  const map = new Map<string, EquipmentTypeOption>()
  equipmentTypeOptions.value.forEach((row) => {
    map.set(row.code, row)
  })
  return map
})

const equipmentReservationById = computed(() => {
  const map = new Map<string, EquipmentReservationRow>()
  equipmentReservations.value.forEach((row) => {
    map.set(row.id, row)
  })
  return map
})

const linkedEquipmentAssignmentByReservationId = computed(() => {
  const map = new Map<string, EquipmentAssignmentFormRow>()
  equipmentAssignmentForms.value.forEach((row) => {
    if (!row.reservation_id) return
    map.set(row.reservation_id, row)
  })
  return map
})

const stepEquipmentRequirements = computed<EquipmentRequirementRow[]>(() => {
  const rows = asArray(step.value?.snapshot_json?.equipment_requirements)
  return rows.map((value: any, index: number) => {
    const row = asRecord(value) ?? {}
    const equipmentTypeCode = safeText(row.equipment_type_code)
    const equipmentType = equipmentTypeByCode.value.get(equipmentTypeCode)
    const quantity = Math.max(1, Math.trunc(Number(row.quantity ?? 1) || 1))
    return {
      local_key: `equipment-requirement-${index}`,
      equipment_type_code: equipmentTypeCode,
      equipment_template_code: safeText(row.equipment_template_code),
      quantity,
      notes: safeText(row.notes),
      type_id: equipmentType?.id ?? null,
    }
  })
})

const requiredEquipmentCount = computed(() =>
  stepEquipmentRequirements.value.reduce((sum, row) => sum + Math.max(1, row.quantity || 1), 0),
)

const preferredEquipmentTypeIds = computed(() =>
  new Set(stepEquipmentRequirements.value.map((row) => row.type_id).filter((value): value is string => Boolean(value))),
)

const preferredEquipmentSiteIds = computed(() => {
  const values = new Set<string>()
  const preferredSiteId = resolveProduceSiteId(batch.value)
  if (preferredSiteId) values.add(preferredSiteId)
  equipmentReservations.value.forEach((row) => {
    if (row.site_id) values.add(row.site_id)
  })
  return values
})

const reservedEquipmentIdSet = computed(() => new Set(equipmentReservations.value.map((row) => row.equipment_id)))

const equipmentReservationOptions = computed(() =>
  equipmentReservations.value.map((row) => ({
    id: row.id,
    label: `${equipmentLabel(row.equipment_id)} / ${formatDateTimeRangeLabel(row.start_at, row.end_at)}`,
  })),
)

const activeEquipmentAssignmentCount = computed(() =>
  equipmentAssignmentForms.value.filter((row) => {
    if (safeText(row.status) !== 'in_use') return false
    return !safeText(row.released_at)
  }).length,
)

const mismatchedEquipmentAssignmentCount = computed(() =>
  equipmentAssignmentForms.value.filter((row) => !isEquipmentAssignmentRowEmpty(row) && equipmentAssignmentHasMismatch(row)).length,
)

const plannedMaterialMap = computed(() => {
  const map = new Map<string, BatchMaterialPlanRow>()
  plannedMaterials.value.forEach((row) => {
    map.set(row.id, row)
  })
  return map
})

const materialExecutionRows = computed<MaterialExecutionDisplayRow[]>(() =>
  actualMaterialForms.value.map((row) => {
    const planned = row.planned_plan_id ? plannedMaterialMap.value.get(row.planned_plan_id) ?? null : null
    return {
      row,
      planTypeLabel: planned ? plannedMaterialTypeLabel(planned) : '—',
      planRoleLabel: planned ? (planned.material_role || safeText(planned.requirement_json?.material_role) || '') : '',
      planQtyLabel: planned ? formatNumber(planned.planned_qty) : '—',
      planUomLabel: planned ? uomLabel(planned.uom_id) : '—',
      planConsumptionModeLabel: planned ? consumptionModeLabel(plannedMaterialConsumptionMode(planned)) : '—',
    }
  }),
)

const materialWorkspaceTabs = computed(() => [
  { value: 'inputs' as MaterialWorkspaceTab, label: t('batch.edit.stepMaterialInputsTab'), count: materialExecutionRows.value.length },
  { value: 'outputs' as MaterialWorkspaceTab, label: t('batch.edit.stepMaterialOutputsTab'), count: outputMaterialForms.value.length },
])

const secondaryWorkspaceTabs = computed(() => [
  { value: 'parameters' as SecondaryWorkspaceTab, label: t('batch.edit.stepParametersTitle'), count: parameterForms.value.length },
  { value: 'qa' as SecondaryWorkspaceTab, label: t('batch.edit.stepQualityChecksTitle'), count: qualityCheckForms.value.length },
  { value: 'logs' as SecondaryWorkspaceTab, label: t('batch.edit.stepExecutionLogsTitle'), count: executionLogForms.value.length },
  { value: 'deviations' as SecondaryWorkspaceTab, label: t('batch.edit.stepDeviationsTitle'), count: deviationForms.value.length },
])

const currentStepStatusSummaryLabel = computed(() => {
  const normalized = safeText(stepForm.status) || safeText(step.value?.status) || 'open'
  return stepStatusOptions.value.find((option) => option.value === normalized)?.label ?? humanizeToken(normalized)
})

const latestExecutionTimestampSummaryLabel = computed(() => {
  if (stepForm.ended_at) return formatDateTimeLabel(stepForm.ended_at)
  if (stepForm.started_at) return formatDateTimeLabel(stepForm.started_at)
  return '—'
})

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
    const [batchResult, stepResult, uomResult, materialResult, equipmentResult, equipmentTypeResult, lotResult] = await Promise.all([
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
        .select('id, material_code, material_name, material_type_id, base_uom_id, status')
        .eq('status', 'active')
        .order('material_code'),
      supabase
        .from('mst_equipment')
        .select('id, equipment_code, name_i18n, equipment_type_id, site_id, equipment_status, is_active')
        .eq('is_active', true)
        .order('equipment_code'),
      supabase
        .from('type_def')
        .select('type_id, code, name, name_i18n, sort_order')
        .eq('domain', 'equipment_type')
        .order('sort_order', { ascending: true }),
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
    if (equipmentTypeResult.error) throw equipmentTypeResult.error
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
      meta: asRecord(batchHeader.meta) ?? {},
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
      material_type_id: safeNullableText(row.material_type_id),
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
        equipment_type_id: safeNullableText(row.equipment_type_id),
        site_id: safeNullableText(row.site_id),
        equipment_status: safeNullableText(row.equipment_status),
      }
    })

    equipmentTypeOptions.value = (equipmentTypeResult.data ?? []).map((row: any) => {
      const name = resolveNameI18n(row.name_i18n ?? null) || safeText(row.name) || safeText(row.code)
      const code = safeText(row.code)
      return {
        id: String(row.type_id ?? ''),
        code,
        name,
        label: code && name && code !== name ? `${code} - ${name}` : (name || code),
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
  outputMaterialForms.value = buildOutputMaterialForms(step.value)
}

async function loadStepCollections(currentStepId: string) {
  const mes = mesClient()
  const currentBatchId = batch.value?.id ?? ''
  const [plannedResult, actualResult, equipmentResult, reservationResult, logResult, deviationResult] = await Promise.all([
    mes
      .from('batch_material_plan')
      .select('id, material_role, material_type_id, planned_qty, uom_id, requirement_json, snapshot_json')
      .eq('batch_step_id', currentStepId)
      .order('created_at', { ascending: true }),
    mes
      .from('batch_material_actual')
      .select('id, material_id, lot_id, actual_qty, uom_id, consumed_at, snapshot_json, note')
      .eq('batch_step_id', currentStepId)
      .order('consumed_at', { ascending: true }),
    mes
      .from('batch_equipment_assignment')
      .select('id, equipment_id, reservation_id, assignment_role, status, assigned_at, released_at, note, snapshot_json')
      .eq('batch_step_id', currentStepId)
      .order('assigned_at', { ascending: true }),
    currentBatchId
      ? mes
          .from('equipment_reservation')
          .select('id, site_id, equipment_id, reservation_type, batch_step_id, start_at, end_at, status, note, meta_json')
          .eq('batch_id', currentBatchId)
          .or(`batch_step_id.eq.${currentStepId},batch_step_id.is.null`)
          .order('start_at', { ascending: true })
      : Promise.resolve({ data: [], error: null }),
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
  if (reservationResult.error) throw reservationResult.error
  if (logResult.error) throw logResult.error
  if (deviationResult.error) throw deviationResult.error

  plannedMaterials.value = (plannedResult.data ?? []).map((row: any) => ({
    id: String(row.id ?? ''),
    material_role: safeNullableText(row.material_role),
    material_type_id: safeNullableText(row.material_type_id),
    planned_qty: Number(row.planned_qty ?? 0),
    uom_id: String(row.uom_id ?? ''),
    requirement_json: asRecord(row.requirement_json) ?? {},
    snapshot_json: asRecord(row.snapshot_json) ?? {},
  }))

  actualMaterialForms.value = (actualResult.data ?? []).map((row: any) => ({
    local_key: nextLocalKey('actual-material'),
    id: String(row.id ?? ''),
    planned_plan_id: safeText(asRecord(row.snapshot_json)?.plan_id),
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

  synchronizeActualMaterialRows()

  equipmentAssignmentForms.value = (equipmentResult.data ?? []).map((row: any) => ({
    local_key: nextLocalKey('equipment'),
    id: String(row.id ?? ''),
    equipment_id: safeText(row.equipment_id),
    reservation_id: safeText(row.reservation_id),
    assignment_role: safeText(row.assignment_role),
    status: safeText(row.status) || 'assigned',
    assigned_at: toDateTimeInputValue(row.assigned_at),
    released_at: toDateTimeInputValue(row.released_at),
    note: safeText(row.note),
    snapshot_json: asRecord(row.snapshot_json) ?? {},
  }))
  equipmentReservations.value = (reservationResult.data ?? []).map((row: any) => ({
    id: String(row.id ?? ''),
    site_id: String(row.site_id ?? ''),
    equipment_id: String(row.equipment_id ?? ''),
    reservation_type: safeText(row.reservation_type) || 'batch',
    batch_step_id: safeNullableText(row.batch_step_id),
    status: safeText(row.status) || 'reserved',
    start_at: safeText(row.start_at),
    end_at: safeText(row.end_at),
    note: safeText(row.note),
    meta_json: asRecord(row.meta_json) ?? {},
  }))

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
  let usedBackflushCompletion = false
  try {
    await ensureCurrentUser()
    const actualParams = buildActualParamsPayload(step.value)
    const qualityChecks = buildQualityChecksPayload()
    const shouldReadyNextStep = Boolean(batch.value) && shouldMoveNextStepToReady(previousStatus, targetStatus)
    const backflushSourceSiteId = resolveBackflushSourceSiteId()

    if (targetStatus === 'completed' && hasBackflushPlannedMaterials.value) {
      usedBackflushCompletion = true
      clearSectionState(actualMaterialsState)
      await persistActualMaterials({
        clearState: false,
        setSavingState: false,
        showSuccess: false,
        reloadCollections: true,
      })

      const { error } = await supabase.rpc('batch_step_complete_backflush', {
        p_batch_step_id: step.value.id,
        p_patch: {
          status: 'completed',
          started_at: startedAt,
          ended_at: endedAt,
          source_site_id: backflushSourceSiteId,
          notes: nullableText(stepForm.notes),
          actual_params: actualParams,
          quality_checks_json: qualityChecks,
          auto_ready_next_step: shouldReadyNextStep,
        },
      })
      if (error) throw error

      await loadPage()
      stepSaveState.success = t('batch.edit.stepSavedWithBackflush')
      return
    }

    const mes = mesClient()
    const { error } = await mes
      .from('batch_step')
      .update({
        status: targetStatus,
        started_at: startedAt,
        ended_at: endedAt,
        notes: nullableText(stepForm.notes),
        actual_params: actualParams,
        quality_checks_json: qualityChecks,
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
      actual_params: actualParams,
      quality_checks_json: qualityChecks,
    }
    stepForm.status = targetStatus
    stepForm.ended_at = toDateTimeInputValue(endedAt)

    if (batch.value && shouldReadyNextStep) {
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
    stepSaveState.error = usedBackflushCompletion
      ? `${t('batch.edit.stepSaveFailed')} (${message})`
      : currentStepSaved
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
  actualMaterialForms.value.push(createActualMaterialRow())
}

function removeActualMaterialRow(index: number) {
  const row = actualMaterialForms.value[index]
  if (row?.planned_plan_id) {
    actualMaterialForms.value.splice(index, 1, createActualMaterialRow({
      plannedPlanId: row.planned_plan_id,
      uomId: plannedMaterialMap.value.get(row.planned_plan_id)?.uom_id ?? '',
    }))
    return
  }
  actualMaterialForms.value.splice(index, 1)
}

function handleActualMaterialChange(index: number) {
  const row = actualMaterialForms.value[index]
  const material = materialOptions.value.find((option) => option.id === row.material_id)
  if (!material) {
    if (row.planned_plan_id) {
      row.uom_id = plannedMaterialMap.value.get(row.planned_plan_id)?.uom_id ?? ''
    }
    return
  }
  if (material.base_uom_id) row.uom_id = material.base_uom_id
  if (row.lot_id) {
    const lot = lotOptions.value.find((option) => option.id === row.lot_id)
    if (lot && lot.material_id && lot.material_id !== row.material_id) row.lot_id = ''
  }
}

function handleActualLotChange(row: ActualMaterialFormRow) {
  if (!row.lot_id) {
    const material = materialOptions.value.find((option) => option.id === row.material_id)
    if (material?.base_uom_id) row.uom_id = material.base_uom_id
    else if (row.planned_plan_id) row.uom_id = plannedMaterialMap.value.get(row.planned_plan_id)?.uom_id ?? row.uom_id
    return
  }

  const lot = lotOptions.value.find((option) => option.id === row.lot_id)
  if (!lot) return
  if (lot.material_id) row.material_id = lot.material_id
  if (lot.uom_id) row.uom_id = lot.uom_id
}

async function saveActualMaterials() {
  actualMaterialsState.saving = true
  try {
    await persistActualMaterials()
  } catch {
    // The helper already populates section-level validation / save errors.
  } finally {
    actualMaterialsState.saving = false
  }
}

async function persistActualMaterials(options: PersistActualMaterialsOptions = {}) {
  if (!step.value || !batch.value) return
  const {
    clearState = true,
    setSavingState = false,
    showSuccess = true,
    reloadCollections = true,
  } = options

  if (clearState) clearSectionState(actualMaterialsState)
  if (setSavingState) actualMaterialsState.saving = true

  try {
    const rows = actualMaterialForms.value.filter((row) => !isActualMaterialRowEmpty(row))
    validateActualMaterialRows(rows)
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
      const planned = row.planned_plan_id ? plannedMaterialMap.value.get(row.planned_plan_id) ?? null : null
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
          plan_id: row.planned_plan_id || null,
          planned_material_type: planned ? plannedMaterialTypeLabel(planned) : null,
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

    if (reloadCollections) {
      await loadStepCollections(step.value.id)
    }
    if (showSuccess) {
      actualMaterialsState.success = t('common.saved')
    }
  } catch (err) {
    actualMaterialsState.error = buildSectionSaveErrorMessage(err)
    throw err
  } finally {
    if (setSavingState) actualMaterialsState.saving = false
  }
}

function addEquipmentAssignmentRow() {
  equipmentAssignmentForms.value.push(createEquipmentAssignmentRow({
    assignmentRole: defaultEquipmentAssignmentRole(),
    status: 'assigned',
    assignedAt: toDateTimeInputValue(new Date().toISOString()),
  }))
}

function removeEquipmentAssignmentRow(index: number) {
  equipmentAssignmentForms.value.splice(index, 1)
}

function useReservedEquipment(reservationId: string) {
  const reservation = equipmentReservationById.value.get(reservationId)
  if (!reservation) return
  const linkedRow = linkedEquipmentAssignmentByReservationId.value.get(reservationId)
  if (linkedRow) {
    handleEquipmentReservationChange(linkedRow)
    return
  }

  equipmentAssignmentForms.value.push(createEquipmentAssignmentRow({
    equipmentId: reservation.equipment_id,
    reservationId: reservation.id,
    assignmentRole: safeText(reservation.meta_json?.assignment_role) || defaultEquipmentAssignmentRole(),
    status: 'assigned',
    assignedAt: toDateTimeInputValue(reservation.start_at) || toDateTimeInputValue(new Date().toISOString()),
    note: reservation.note,
  }))
}

function handleEquipmentSelectionChange(row: EquipmentAssignmentFormRow) {
  if (!row.equipment_id) return
  if (!row.assignment_role) row.assignment_role = defaultEquipmentAssignmentRole()
}

function handleEquipmentReservationChange(row: EquipmentAssignmentFormRow) {
  if (!row.reservation_id) return
  const reservation = equipmentReservationById.value.get(row.reservation_id)
  if (!reservation) return
  row.equipment_id = reservation.equipment_id
  if (!row.assignment_role) {
    row.assignment_role = safeText(reservation.meta_json?.assignment_role) || defaultEquipmentAssignmentRole()
  }
  if (!row.assigned_at) {
    row.assigned_at = toDateTimeInputValue(reservation.start_at) || toDateTimeInputValue(new Date().toISOString())
  }
  if (!row.note && reservation.note) row.note = reservation.note
}

function handleEquipmentStatusChange(row: EquipmentAssignmentFormRow) {
  const normalized = safeText(row.status) || 'assigned'
  const nowValue = toDateTimeInputValue(new Date().toISOString())
  if (normalized === 'in_use') {
    if (!row.assigned_at) row.assigned_at = nowValue
    row.released_at = ''
    return
  }
  if ((normalized === 'done' || normalized === 'cancelled') && !row.released_at) {
    row.released_at = nowValue
  }
}

function applyEquipmentAssignmentAction(row: EquipmentAssignmentFormRow, action: 'start' | 'release' | 'complete' | 'cancel') {
  const nowValue = toDateTimeInputValue(new Date().toISOString())
  if (action === 'start') {
    row.status = 'in_use'
    if (!row.assigned_at) row.assigned_at = nowValue
    row.released_at = ''
    return
  }
  if (action === 'release') {
    row.status = 'assigned'
    if (!row.assigned_at) row.assigned_at = nowValue
    row.released_at = nowValue
    return
  }
  if (action === 'complete') {
    row.status = 'done'
    if (!row.assigned_at) row.assigned_at = nowValue
    row.released_at = nowValue
    return
  }
  row.status = 'cancelled'
  if (!row.assigned_at) row.assigned_at = nowValue
  row.released_at = nowValue
}

async function saveEquipmentAssignments() {
  if (!step.value || !batch.value) return
  clearSectionState(equipmentState)

  const rows = equipmentAssignmentForms.value.filter((row) => !isEquipmentAssignmentRowEmpty(row))
  try {
    validateEquipmentAssignmentRows(rows)
  } catch (err) {
    equipmentState.error = buildSectionSaveErrorMessage(err)
    return
  }

  equipmentState.saving = true
  try {
    await ensureCurrentUser()
    const payloadRows = rows.map((row) => buildEquipmentAssignmentSaveRow(row))
    const { error } = await supabase.rpc('batch_step_save_equipment_assignments', {
      p_batch_step_id: step.value.id,
      p_rows: payloadRows,
    })
    if (error) throw error

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

function buildOutputMaterialForms(stepRow: BatchExecutionStepRow) {
  const plannedRows = asArray(stepRow.snapshot_json?.material_outputs)
  const actualRows = asArray(stepRow.actual_params?.material_outputs)
  const plannedOutputForms = plannedRows.map((value: any, index: number) => {
    const row = asRecord(value) ?? {}
    const actual = actualRows.find((candidate: any) => Number(asRecord(candidate)?.planned_output_index) === index)
      ?? actualRows[index]
      ?? {}
    return {
      local_key: nextLocalKey('output-material'),
      planned_output_index: index,
      output_material_type: safeText(row.output_material_type),
      output_name: safeText(row.output_name),
      output_type: safeText(row.output_type),
      planned_qty: row.qty,
      uom_code: safeText(row.uom_code),
      actual_qty: safeText(actual.actual_qty),
    }
  })

  const extraForms = actualRows
    .filter((value: any) => {
      const row = asRecord(value) ?? {}
      return row.planned_output_index == null && (
        safeText(row.output_material_type)
        || safeText(row.output_name)
        || safeText(row.output_type)
        || safeText(row.uom_code)
        || safeText(row.actual_qty)
      )
    })
    .map((value: any) => {
      const row = asRecord(value) ?? {}
      return createOutputMaterialRow({
        outputMaterialType: safeText(row.output_material_type),
        outputName: safeText(row.output_name),
        outputType: safeText(row.output_type),
        uomCode: safeText(row.uom_code),
        actualQty: safeText(row.actual_qty),
      })
    })

  return [...plannedOutputForms, ...extraForms]
}

function createOutputMaterialRow(initial: {
  plannedOutputIndex?: number | null
  outputMaterialType?: string
  outputName?: string
  outputType?: string
  plannedQty?: unknown
  uomCode?: string
  actualQty?: string
} = {}): OutputMaterialFormRow {
  return {
    local_key: nextLocalKey('output-material'),
    planned_output_index: initial.plannedOutputIndex ?? null,
    output_material_type: initial.outputMaterialType ?? '',
    output_name: initial.outputName ?? '',
    output_type: initial.outputType ?? '',
    planned_qty: initial.plannedQty ?? null,
    uom_code: initial.uomCode ?? '',
    actual_qty: initial.actualQty ?? '',
  }
}

function addOutputMaterialRow() {
  outputMaterialForms.value.push(createOutputMaterialRow())
}

function removeOutputMaterialRow(index: number) {
  const row = outputMaterialForms.value[index]
  if (!row) return
  if (row.planned_output_index !== null) {
    outputMaterialForms.value.splice(index, 1, createOutputMaterialRow({
      plannedOutputIndex: row.planned_output_index,
      outputMaterialType: row.output_material_type,
      outputName: row.output_name,
      outputType: row.output_type,
      plannedQty: row.planned_qty,
      uomCode: row.uom_code,
    }))
    return
  }
  outputMaterialForms.value.splice(index, 1)
}

function buildActualParamsPayload(stepRow: BatchExecutionStepRow) {
  const actualParamsBase = { ...(stepRow.actual_params ?? {}) }
  delete actualParamsBase.parameters
  delete actualParamsBase.material_outputs
  return {
    ...actualParamsBase,
    parameters: parameterForms.value.map((row) => ({
      parameter_code: row.parameter_code || null,
      parameter_name: row.parameter_name || null,
      uom_code: row.uom_code || null,
      actual_value: nullableText(row.actual_value),
      comment: nullableText(row.comment),
    })),
    material_outputs: outputMaterialForms.value
      .filter((row) => row.output_material_type || row.output_name || row.actual_qty || row.output_type || row.uom_code)
      .map((row) => ({
        planned_output_index: row.planned_output_index,
        output_material_type: row.output_material_type || null,
        output_name: row.output_name || null,
        output_type: row.output_type || null,
        uom_code: row.uom_code || null,
        actual_qty: parseNumber(row.actual_qty),
      })),
  }
}

function buildQualityChecksPayload() {
  return qualityCheckForms.value.map((row) => ({
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
  }))
}

function createActualMaterialRow(initial: {
  plannedPlanId?: string
  uomId?: string
  materialId?: string
  actualQty?: string
  lotId?: string
  consumedAt?: string
  note?: string
  id?: string | null
  snapshotJson?: Record<string, any>
} = {}): ActualMaterialFormRow {
  return {
    local_key: nextLocalKey('actual-material'),
    id: initial.id ?? null,
    planned_plan_id: initial.plannedPlanId ?? '',
    material_id: initial.materialId ?? '',
    lot_id: initial.lotId ?? '',
    actual_qty: initial.actualQty ?? '',
    uom_id: initial.uomId ?? '',
    consumed_at: initial.consumedAt ?? toDateTimeInputValue(new Date().toISOString()),
    note: initial.note ?? '',
    snapshot_json: initial.snapshotJson ?? {},
  }
}

function createEquipmentAssignmentRow(initial: {
  id?: string | null
  equipmentId?: string
  reservationId?: string
  assignmentRole?: string
  status?: string
  assignedAt?: string
  releasedAt?: string
  note?: string
  snapshotJson?: Record<string, any>
} = {}): EquipmentAssignmentFormRow {
  return {
    local_key: nextLocalKey('equipment'),
    id: initial.id ?? null,
    equipment_id: initial.equipmentId ?? '',
    reservation_id: initial.reservationId ?? '',
    assignment_role: initial.assignmentRole ?? '',
    status: initial.status ?? 'assigned',
    assigned_at: initial.assignedAt ?? '',
    released_at: initial.releasedAt ?? '',
    note: initial.note ?? '',
    snapshot_json: initial.snapshotJson ?? {},
  }
}

function defaultEquipmentAssignmentRole() {
  return equipmentAssignmentForms.value.length > 0 ? 'aux' : 'main'
}

function buildEquipmentAssignmentSaveRow(row: EquipmentAssignmentFormRow) {
  const equipment = equipmentOptionById.value.get(row.equipment_id)
  const reservation = row.reservation_id ? equipmentReservationById.value.get(row.reservation_id) ?? null : null
  return {
    id: row.id,
    equipment_id: row.equipment_id,
    reservation_id: nullableText(row.reservation_id),
    assignment_role: nullableText(row.assignment_role),
    status: safeText(row.status) || 'assigned',
    assigned_at: toIsoDateTime(row.assigned_at),
    released_at: toIsoDateTime(row.released_at),
    note: nullableText(row.note),
    snapshot_json: {
      ...(row.snapshot_json ?? {}),
      equipment_code: equipment?.code ?? null,
      equipment_name: equipment?.name ?? null,
      equipment_type_id: equipment?.equipment_type_id ?? null,
      reservation_status: reservation?.status ?? null,
      reservation_type: reservation?.reservation_type ?? null,
      reservation_start_at: reservation?.start_at ?? null,
      reservation_end_at: reservation?.end_at ?? null,
    },
  }
}

function synchronizeActualMaterialRows() {
  const validPlannedIds = new Set(plannedMaterials.value.map((row) => row.id))
  const linkedByPlan = new Map<string, ActualMaterialFormRow[]>()
  const orphanRows: ActualMaterialFormRow[] = []

  actualMaterialForms.value.forEach((row) => {
    if (row.planned_plan_id && validPlannedIds.has(row.planned_plan_id)) {
      const bucket = linkedByPlan.get(row.planned_plan_id) ?? []
      bucket.push(row)
      linkedByPlan.set(row.planned_plan_id, bucket)
      return
    }
    orphanRows.push(row)
  })

  const synchronized: ActualMaterialFormRow[] = []
  const extraRows: ActualMaterialFormRow[] = []

  plannedMaterials.value.forEach((plannedRow) => {
    const linkedRows = linkedByPlan.get(plannedRow.id) ?? []
    const assignedRow = linkedRows.shift() ?? orphanRows.shift() ?? createActualMaterialRow({
      plannedPlanId: plannedRow.id,
      uomId: plannedRow.uom_id,
    })
    assignedRow.planned_plan_id = plannedRow.id
    if (!assignedRow.uom_id) assignedRow.uom_id = plannedRow.uom_id
    synchronized.push(assignedRow)

    linkedRows.forEach((row) => {
      row.planned_plan_id = ''
      extraRows.push(row)
    })
  })

  actualMaterialForms.value = [...synchronized, ...orphanRows, ...extraRows]
}

function plannedMaterialConsumptionMode(row: BatchMaterialPlanRow) {
  return findNestedStringValueByKey(row.requirement_json, 'consumption_mode')
    || findNestedStringValueByKey(row.snapshot_json, 'consumption_mode')
    || 'estimate'
}

function plannedMaterialTypeLabel(row: BatchMaterialPlanRow) {
  return safeText(row.requirement_json?.material_type)
    || safeText(row.requirement_json?.material_type_code)
    || safeText(row.snapshot_json?.material_type)
    || safeText(row.snapshot_json?.material_type_code)
    || '—'
}

function consumptionModeLabel(value: string | null | undefined) {
  const normalized = safeText(value) || 'estimate'
  const key = `recipe.consumptionModes.${normalized}`
  const translated = t(key)
  return translated === key ? humanizeToken(normalized) : translated
}

function materialOptionsForActualRow(row: ActualMaterialFormRow) {
  const planned = row.planned_plan_id ? plannedMaterialMap.value.get(row.planned_plan_id) ?? null : null
  if (!planned?.material_type_id) return materialOptions.value
  return materialOptions.value.filter((option) => option.material_type_id === planned.material_type_id || option.id === row.material_id)
}

function lotOptionsForActualRow(row: ActualMaterialFormRow) {
  if (row.material_id) {
    return lotOptions.value.filter((option) => option.material_id === row.material_id || option.id === row.lot_id)
  }

  const candidateMaterialIds = new Set(materialOptionsForActualRow(row).map((option) => option.id))
  if (candidateMaterialIds.size === 0) return lotOptions.value
  return lotOptions.value.filter((option) => !option.material_id || candidateMaterialIds.has(option.material_id) || option.id === row.lot_id)
}

function outputTypeLabel(value: string | null | undefined) {
  const normalized = safeText(value)
  if (!normalized) return '—'
  return outputTypeOptions.value.find((option) => option.value === normalized)?.label ?? humanizeToken(normalized)
}

function isActualMaterialDetailsOpen(localKey: string) {
  return expandedActualMaterialRowKeys.value.includes(localKey)
}

function toggleActualMaterialDetails(localKey: string) {
  if (isActualMaterialDetailsOpen(localKey)) {
    expandedActualMaterialRowKeys.value = expandedActualMaterialRowKeys.value.filter((value) => value !== localKey)
    return
  }
  expandedActualMaterialRowKeys.value = [...expandedActualMaterialRowKeys.value, localKey]
}

function equipmentLabel(equipmentId: string | null | undefined) {
  if (!equipmentId) return '—'
  return equipmentOptionById.value.get(equipmentId)?.label ?? equipmentId
}

function equipmentRequirementLabel(row: EquipmentRequirementRow) {
  const equipmentType = row.equipment_type_code ? equipmentTypeByCode.value.get(row.equipment_type_code) : null
  return equipmentType?.label || row.equipment_type_code || row.equipment_template_code || '—'
}

function equipmentMatchesRequirement(equipmentId: string, requirement: EquipmentRequirementRow) {
  const equipment = equipmentOptionById.value.get(equipmentId)
  if (!equipment) return false
  if (requirement.type_id) return equipment.equipment_type_id === requirement.type_id
  return true
}

function equipmentRequirementReservationCount(requirement: EquipmentRequirementRow) {
  return equipmentReservations.value.filter((row) => equipmentMatchesRequirement(row.equipment_id, requirement)).length
}

function equipmentRequirementActualCount(requirement: EquipmentRequirementRow) {
  return equipmentAssignmentForms.value.filter((row) =>
    safeText(row.status) !== 'cancelled' && row.equipment_id && equipmentMatchesRequirement(row.equipment_id, requirement)).length
}

function reservationStatusLabel(value: string | null | undefined) {
  const normalized = safeText(value) || 'reserved'
  const key = `equipmentSchedule.reservationStatuses.${normalized}`
  const translated = t(key)
  return translated === key ? humanizeToken(normalized) : translated
}

function reservationTypeLabel(value: string | null | undefined) {
  const normalized = safeText(value) || 'batch'
  const key = `equipmentSchedule.reservationTypes.${normalized}`
  const translated = t(key)
  return translated === key ? humanizeToken(normalized) : translated
}

function equipmentAssignmentStatusLabel(value: string | null | undefined) {
  const normalized = safeText(value) || 'assigned'
  const key = `equipmentSchedule.assignmentStatuses.${normalized}`
  const translated = t(key)
  return translated === key ? humanizeToken(normalized) : translated
}

function equipmentAssignmentStatusBadgeClass(value: string | null | undefined) {
  const normalized = safeText(value) || 'assigned'
  if (normalized === 'in_use') return 'bg-emerald-50 text-emerald-700'
  if (normalized === 'done') return 'bg-blue-50 text-blue-700'
  if (normalized === 'cancelled') return 'bg-rose-50 text-rose-700'
  return 'bg-gray-100 text-gray-700'
}

function equipmentAssignmentHeading(row: EquipmentAssignmentFormRow, index: number) {
  if (row.equipment_id) return equipmentLabel(row.equipment_id)
  return `${t('batch.edit.stepEquipmentTitle')} #${index + 1}`
}

function equipmentAssignmentHasReservationMismatch(row: EquipmentAssignmentFormRow) {
  if (safeText(row.status) === 'cancelled') return false
  if (!row.reservation_id || !row.equipment_id) return false
  const reservation = equipmentReservationById.value.get(row.reservation_id)
  if (!reservation) return false
  return reservation.equipment_id !== row.equipment_id
}

function equipmentAssignmentHasRequirementMismatch(row: EquipmentAssignmentFormRow) {
  if (safeText(row.status) === 'cancelled') return false
  if (!row.equipment_id || stepEquipmentRequirements.value.length === 0) return false
  return !stepEquipmentRequirements.value.some((requirement) => equipmentMatchesRequirement(row.equipment_id, requirement))
}

function equipmentAssignmentHasMismatch(row: EquipmentAssignmentFormRow) {
  return equipmentAssignmentHasReservationMismatch(row) || equipmentAssignmentHasRequirementMismatch(row)
}

function equipmentAssignmentCardClass(row: EquipmentAssignmentFormRow) {
  if (equipmentAssignmentHasMismatch(row)) return 'border-amber-300 bg-amber-50/40'
  if (safeText(row.status) === 'in_use' && !safeText(row.released_at)) return 'border-emerald-300 bg-emerald-50/40'
  return 'border-gray-200 bg-white'
}

function equipmentOptionRankingScore(option: EquipmentOption, row: EquipmentAssignmentFormRow) {
  let score = 0
  if (row.equipment_id === option.id) score += 1000
  const reservation = row.reservation_id ? equipmentReservationById.value.get(row.reservation_id) ?? null : null
  if (reservation?.equipment_id === option.id) score += 400
  else if (reservedEquipmentIdSet.value.has(option.id)) score += 250
  if (option.equipment_type_id && preferredEquipmentTypeIds.value.has(option.equipment_type_id)) score += 150
  if (option.site_id && preferredEquipmentSiteIds.value.has(option.site_id)) score += 50
  if (option.equipment_status === 'available') score += 25
  return score
}

function equipmentOptionsForAssignmentRow(row: EquipmentAssignmentFormRow) {
  return [...equipmentOptions.value].sort((left, right) => {
    const scoreDelta = equipmentOptionRankingScore(right, row) - equipmentOptionRankingScore(left, row)
    if (scoreDelta !== 0) return scoreDelta
    return left.label.localeCompare(right.label)
  })
}

function validateEquipmentAssignmentRows(rows: EquipmentAssignmentFormRow[]) {
  const effectiveRows = rows.filter((row) => safeText(row.status) !== 'cancelled')
  if (requiredEquipmentCount.value > 0 && effectiveRows.length < requiredEquipmentCount.value) {
    throw new Error(t('batch.edit.stepEquipmentRequiredAssignmentsError', { count: requiredEquipmentCount.value }))
  }

  const reservationIds = new Set<string>()
  for (const row of rows) {
    if (!row.equipment_id) {
      throw new Error(t('errors.required', { field: t('batch.edit.stepEquipment') }))
    }
    if (!row.assigned_at) {
      throw new Error(t('errors.required', { field: t('batch.edit.stepAssignedAt') }))
    }
    if (row.assigned_at && row.released_at && new Date(row.assigned_at).getTime() > new Date(row.released_at).getTime()) {
      throw new Error(t('batch.edit.stepTimeRangeError'))
    }
    if (row.reservation_id) {
      if (reservationIds.has(row.reservation_id)) {
        throw new Error(t('batch.edit.stepEquipmentDuplicateReservationError'))
      }
      reservationIds.add(row.reservation_id)
    }
  }

  for (let index = 0; index < rows.length; index += 1) {
    const current = rows[index]
    if (safeText(current.status) === 'cancelled') continue
    for (let compareIndex = index + 1; compareIndex < rows.length; compareIndex += 1) {
      const candidate = rows[compareIndex]
      if (current.equipment_id !== candidate.equipment_id) continue
      if (safeText(candidate.status) === 'cancelled') continue
      if (!equipmentAssignmentRowsOverlap(current, candidate)) continue
      throw new Error(t('batch.edit.stepEquipmentOverlapError', { equipment: equipmentLabel(current.equipment_id) }))
    }
  }
}

function equipmentAssignmentRowsOverlap(left: EquipmentAssignmentFormRow, right: EquipmentAssignmentFormRow) {
  const leftStart = new Date(left.assigned_at).getTime()
  const rightStart = new Date(right.assigned_at).getTime()
  const leftEnd = left.released_at ? new Date(left.released_at).getTime() : Number.POSITIVE_INFINITY
  const rightEnd = right.released_at ? new Date(right.released_at).getTime() : Number.POSITIVE_INFINITY
  if (Number.isNaN(leftStart) || Number.isNaN(rightStart)) return false
  return leftStart <= rightEnd && rightStart <= leftEnd
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

function validateActualMaterialRows(rows: ActualMaterialFormRow[]) {
  for (const row of rows) {
    if (!row.actual_qty || parseNumber(row.actual_qty) == null) {
      throw new Error(t('errors.required', { field: t('batch.edit.stepActualQty') }))
    }
    if (!row.uom_id) {
      throw new Error(t('errors.required', { field: t('recipe.materials.uomCode') }))
    }
    if (!row.material_id && !row.lot_id) {
      throw new Error(t('batch.edit.stepMaterialOrLotRequired'))
    }
  }
}

function buildSectionSaveErrorMessage(error: unknown) {
  const message = extractErrorMessage(error) || t('common.unknown')
  return `${t('batch.edit.stepSectionSaveFailed')} (${message})`
}

function resetCollections() {
  plannedMaterials.value = []
  parameterForms.value = []
  qualityCheckForms.value = []
  actualMaterialForms.value = []
  outputMaterialForms.value = []
  equipmentAssignmentForms.value = []
  equipmentReservations.value = []
  executionLogForms.value = []
  deviationForms.value = []
  loadedActualMaterialIds.value = []
  loadedExecutionLogIds.value = []
  loadedDeviationIds.value = []
  materialWorkspaceTab.value = 'inputs'
  secondaryWorkspaceTab.value = 'parameters'
  expandedActualMaterialRowKeys.value = []
}

function isActualMaterialRowEmpty(row: ActualMaterialFormRow) {
  return !row.material_id && !row.lot_id && !row.actual_qty && !row.uom_id && !row.note
}

function isEquipmentAssignmentRowEmpty(row: EquipmentAssignmentFormRow) {
  return !row.equipment_id && !row.reservation_id && !row.assignment_role && !row.assigned_at && !row.released_at && !row.note
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

function formatDateTimeLabel(value: unknown) {
  const text = safeText(value)
  if (!text) return '—'
  const date = new Date(text)
  if (Number.isNaN(date.getTime())) return '—'
  return new Intl.DateTimeFormat(locale.value.startsWith('ja') ? 'ja-JP' : 'en-US', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date)
}

function formatDateTimeRangeLabel(startAt: unknown, endAt: unknown) {
  const startLabel = formatDateTimeLabel(startAt)
  const endLabel = formatDateTimeLabel(endAt)
  if (startLabel === '—' && endLabel === '—') return '—'
  if (endLabel === '—') return startLabel
  if (startLabel === '—') return endLabel
  return `${startLabel} - ${endLabel}`
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

function findNestedStringValueByKey(value: unknown, key: string): string {
  if (!value || typeof value !== 'object') return ''
  if (Array.isArray(value)) {
    for (const item of value) {
      const nested = findNestedStringValueByKey(item, key)
      if (nested) return nested
    }
    return ''
  }

  const record = value as Record<string, unknown>
  const direct = safeText(record[key])
  if (direct) return direct

  for (const nestedValue of Object.values(record)) {
    const nested = findNestedStringValueByKey(nestedValue, key)
    if (nested) return nested
  }
  return ''
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

function resolveProduceSiteId(source: BatchHeaderRow | null | undefined) {
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

function resolveBackflushSourceSiteId() {
  const batchSiteId = resolveProduceSiteId(batch.value)
  if (batchSiteId) return batchSiteId

  const assignmentSiteIds = new Set<string>()
  equipmentAssignmentForms.value.forEach((row) => {
    if (safeText(row.status) === 'cancelled') return
    const siteId = row.equipment_id ? equipmentOptionById.value.get(row.equipment_id)?.site_id : null
    if (siteId) assignmentSiteIds.add(siteId)
  })
  if (assignmentSiteIds.size === 1) return [...assignmentSiteIds][0]

  const reservationSiteIds = new Set<string>()
  equipmentReservations.value.forEach((row) => {
    if (row.site_id) reservationSiteIds.add(row.site_id)
  })
  if (reservationSiteIds.size === 1) return [...reservationSiteIds][0]

  const combinedSiteIds = new Set<string>([
    ...assignmentSiteIds,
    ...reservationSiteIds,
  ])
  if (combinedSiteIds.size === 1) return [...combinedSiteIds][0]

  return null
}

watch([batchId, stepId], () => {
  void loadPage()
}, { immediate: true })
</script>
