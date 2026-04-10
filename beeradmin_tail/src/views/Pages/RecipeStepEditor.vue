<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="space-y-6">
      <section class="rounded-lg border border-gray-200 bg-white shadow">
        <header class="flex flex-col gap-3 border-b p-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 class="text-lg font-semibold text-gray-900">{{ pageTitle }}</h2>
            <p class="text-sm text-gray-500">{{ pageSubtitle }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <button class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-100" type="button" @click="goBack">
              {{ t('recipe.itemEditor.back') }}
            </button>
            <button
              class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700 disabled:opacity-60"
              type="button"
              :disabled="saving"
              @click="saveEditor"
            >
              {{ saving ? t('common.saving') : t('recipe.itemEditor.saveAndReturn') }}
            </button>
          </div>
        </header>

        <div class="grid grid-cols-1 gap-4 p-4 md:grid-cols-3">
          <div class="rounded-lg border border-gray-200 bg-gray-50 p-4">
            <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">{{ t('recipe.itemEditor.recipeSummary') }}</p>
            <dl class="mt-2 space-y-1 text-sm text-gray-700">
              <div class="flex justify-between gap-3">
                <dt>{{ t('recipe.edit.recipeCode') }}</dt>
                <dd class="font-mono">{{ recipeHeader?.recipe_code || '-' }}</dd>
              </div>
              <div class="flex justify-between gap-3">
                <dt>{{ t('recipe.edit.recipeName') }}</dt>
                <dd>{{ recipeHeader?.recipe_name || '-' }}</dd>
              </div>
              <div class="flex justify-between gap-3">
                <dt>{{ t('recipe.edit.version') }}</dt>
                <dd>{{ activeVersion ? `v${activeVersion.version_no}` : '-' }}</dd>
              </div>
              <div class="flex justify-between gap-3">
                <dt>{{ t('recipe.itemEditor.editorMode') }}</dt>
                <dd>{{ editorModeLabel }}</dd>
              </div>
            </dl>
          </div>
          <div class="rounded-lg border border-gray-200 bg-gray-50 p-4 md:col-span-2">
            <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">{{ t('recipe.itemEditor.routeContext') }}</p>
            <dl class="mt-2 grid grid-cols-1 gap-2 text-sm text-gray-700 md:grid-cols-3">
              <div>
                <dt class="text-xs text-gray-500">{{ t('recipe.edit.group') }}</dt>
                <dd>{{ sectionLabel }}</dd>
              </div>
              <div>
                <dt class="text-xs text-gray-500">{{ t('common.mode') }}</dt>
                <dd>{{ editModeLabel }}</dd>
              </div>
              <div>
                <dt class="text-xs text-gray-500">{{ t('recipe.edit.schemaCode') }}</dt>
                <dd class="font-mono">{{ activeVersion?.schema_code || DEFAULT_SCHEMA_KEY }}</dd>
              </div>
            </dl>
            <p v-if="schemaError" class="mt-3 text-sm text-amber-700">{{ schemaError }}</p>
            <p v-if="loadError" class="mt-3 text-sm text-red-600">{{ loadError }}</p>
          </div>
        </div>
      </section>

      <section v-if="loadingPage" class="rounded-lg border border-gray-200 bg-white p-6 text-sm text-gray-500 shadow">
        {{ t('common.loading') }}
      </section>

      <section v-else class="space-y-4">
        <div class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="border-b px-4 py-3">
            <h3 class="text-sm font-semibold text-gray-900">{{ t('recipe.itemEditor.sectionMainInformation') }}</h3>
            <p class="mt-1 text-xs text-gray-500">{{ t('recipe.itemEditor.stepPageHint') }}</p>
          </div>
          <div class="grid grid-cols-1 gap-3 p-3 md:grid-cols-4 xl:grid-cols-6">
            <div class="md:col-span-1">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.stepNo') }}<span class="text-red-600">*</span></label>
              <input v-model.number="stepForm.step_no" type="number" min="1" class="h-[40px] w-full rounded border px-3" />
              <p v-if="stepErrors.step_no" class="mt-1 text-xs text-red-600">{{ stepErrors.step_no }}</p>
            </div>
            <div class="md:col-span-1">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.stepType') }}<span class="text-red-600">*</span></label>
              <select v-model="stepForm.step_type" class="h-[40px] w-full rounded border bg-white px-3">
                <option v-for="option in stepTypeOptions" :key="option" :value="option">{{ formatStepType(option) }}</option>
              </select>
              <p class="mt-1 text-xs text-gray-500">{{ usesSchemaStepOptions ? t('recipe.edit.loadedFromSchema') : t('recipe.edit.usingFallbackOptions') }}</p>
            </div>
            <div class="md:col-span-2 xl:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.stepCode') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="stepForm.step_code" class="h-[40px] w-full rounded border px-3 font-mono text-sm" />
              <p v-if="stepErrors.step_code" class="mt-1 text-xs text-red-600">{{ stepErrors.step_code }}</p>
            </div>
            <div class="md:col-span-4 xl:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.stepName') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="stepForm.step_name" class="h-[40px] w-full rounded border px-3" />
              <p v-if="stepErrors.step_name" class="mt-1 text-xs text-red-600">{{ stepErrors.step_name }}</p>
            </div>
            <div class="md:col-span-2 xl:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.stepTemplateCode') }}</label>
              <input v-model.trim="stepForm.step_template_code" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div class="md:col-span-2 xl:col-span-1">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.durationSec') }}</label>
              <input v-model.trim="stepForm.duration_sec" type="number" min="0" class="h-[40px] w-full rounded border px-3" />
              <p v-if="stepErrors.duration_sec" class="mt-1 text-xs text-red-600">{{ stepErrors.duration_sec }}</p>
            </div>
            <div class="md:col-span-2 xl:col-span-3">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.instructions') }}</label>
              <textarea v-model.trim="stepForm.instructions" rows="3" class="w-full rounded border px-3 py-2"></textarea>
            </div>
            <div class="md:col-span-2 xl:col-span-3">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.notes') }}</label>
              <textarea v-model.trim="stepForm.notes" rows="3" class="w-full rounded border px-3 py-2"></textarea>
            </div>
          </div>
        </div>

        <div class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="border-b px-4 py-3">
            <h3 class="text-sm font-semibold text-gray-900">{{ t('recipe.itemEditor.sectionMaterials') }}</h3>
            <p class="mt-1 text-xs text-gray-500">{{ t('recipe.itemEditor.stepMaterialsHint') }}</p>
          </div>
          <div class="space-y-4 p-4">
            <div>
              <div class="mb-3 flex items-center justify-between">
                <div>
                  <h4 class="text-sm font-semibold text-gray-900">{{ t('recipe.itemEditor.inputMaterialsTitle') }}</h4>
                </div>
                <button class="rounded border border-dashed px-3 py-1 text-sm hover:bg-gray-50" type="button" @click.prevent="addInputMaterialRow">
                  {{ t('recipe.itemEditor.addInputMaterial') }}
                </button>
              </div>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200 text-sm">
                  <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
                    <tr>
                      <th class="px-3 py-2">{{ t('recipe.itemEditor.materialKey') }}</th>
                      <th class="px-3 py-2">{{ t('recipe.edit.quantity') }}</th>
                      <th class="px-3 py-2">{{ t('recipe.edit.unit') }}</th>
                      <th class="px-3 py-2">{{ t('recipe.edit.basis') }}</th>
                      <th class="px-3 py-2">{{ t('recipe.itemEditor.consumptionMode') }}</th>
                      <th class="px-3 py-2">{{ t('recipe.edit.notes') }}</th>
                      <th class="px-3 py-2">{{ t('common.actions') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="(row, index) in inputMaterialRows" :key="row.key">
                      <td class="px-3 py-2">
                        <input
                          :ref="(el) => setInputMaterialTypeInputRef(row.key, el)"
                          v-model.trim="row.material_type"
                          class="w-full rounded border px-2 py-1 font-mono text-xs"
                          @focus="handleMaterialTypeFocus(row)"
                        />
                      </td>
                      <td class="px-3 py-2"><input v-model.trim="row.qty" class="w-full rounded border px-2 py-1" /></td>
                      <td class="px-3 py-2">
                        <select v-model="row.uom_code" class="w-full rounded border bg-white px-2 py-1">
                          <option value="">{{ t('common.none') }}</option>
                          <option v-for="option in uomOptionsForCode(row.uom_code)" :key="option.code" :value="option.code">
                            {{ formatUomOptionLabel(option) }}
                          </option>
                        </select>
                      </td>
                      <td class="px-3 py-2">
                        <select v-model="row.basis" class="w-full rounded border bg-white px-2 py-1">
                          <option value="">{{ t('common.none') }}</option>
                          <option v-for="option in inputBasisOptions" :key="option" :value="option">{{ formatBasis(option) }}</option>
                        </select>
                      </td>
                      <td class="px-3 py-2">
                        <select v-model="row.consumption_mode" class="w-full rounded border bg-white px-2 py-1">
                          <option value="">{{ t('common.none') }}</option>
                          <option v-for="option in consumptionModeOptions" :key="option" :value="option">{{ formatConsumptionMode(option) }}</option>
                        </select>
                      </td>
                      <td class="px-3 py-2"><input v-model.trim="row.notes" class="w-full rounded border px-2 py-1" /></td>
                      <td class="px-3 py-2 text-right">
                        <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" type="button" @click.prevent="removeInputMaterialRow(index)">
                          {{ t('common.delete') }}
                        </button>
                      </td>
                    </tr>
                    <tr v-if="inputMaterialRows.length === 0">
                      <td colspan="7" class="px-3 py-4 text-center text-sm text-gray-500">{{ t('recipe.itemEditor.noInputMaterials') }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <p v-if="stepErrors.material_inputs" class="mt-2 text-xs text-red-600">{{ stepErrors.material_inputs }}</p>
            </div>

            <div>
              <div class="mb-3 flex items-center justify-between">
                <div>
                  <h4 class="text-sm font-semibold text-gray-900">{{ t('recipe.itemEditor.outputMaterialsTitle') }}</h4>
                </div>
                <button class="rounded border border-dashed px-3 py-1 text-sm hover:bg-gray-50" type="button" @click.prevent="addOutputMaterialRow">
                  {{ t('recipe.itemEditor.addOutputMaterial') }}
                </button>
              </div>
              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200 text-sm">
                  <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
                    <tr>
                      <th class="px-3 py-2">{{ t('recipe.edit.outputCode') }}</th>
                      <th class="px-3 py-2">{{ t('recipe.edit.outputName') }}</th>
                      <th class="px-3 py-2">{{ t('recipe.edit.outputType') }}</th>
                      <th class="px-3 py-2">{{ t('recipe.edit.quantity') }}</th>
                      <th class="px-3 py-2">{{ t('recipe.edit.unit') }}</th>
                      <th class="px-3 py-2">{{ t('recipe.edit.notes') }}</th>
                      <th class="px-3 py-2">{{ t('common.actions') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="(row, index) in outputMaterialRows" :key="row.key">
                      <td class="px-3 py-2"><input v-model.trim="row.output_material_type" class="w-full rounded border px-2 py-1 font-mono text-xs" /></td>
                      <td class="px-3 py-2"><input v-model.trim="row.output_name" class="w-full rounded border px-2 py-1" /></td>
                      <td class="px-3 py-2">
                        <select v-model="row.output_type" class="w-full rounded border bg-white px-2 py-1">
                          <option value="">{{ t('common.none') }}</option>
                          <option v-for="option in outputTypeOptions" :key="option" :value="option">{{ formatOutputType(option) }}</option>
                        </select>
                      </td>
                      <td class="px-3 py-2"><input v-model.trim="row.qty" class="w-full rounded border px-2 py-1" /></td>
                      <td class="px-3 py-2">
                        <select v-model="row.uom_code" class="w-full rounded border bg-white px-2 py-1">
                          <option value="">{{ t('common.none') }}</option>
                          <option v-for="option in uomOptionsForCode(row.uom_code)" :key="option.code" :value="option.code">
                            {{ formatUomOptionLabel(option) }}
                          </option>
                        </select>
                      </td>
                      <td class="px-3 py-2"><input v-model.trim="row.notes" class="w-full rounded border px-2 py-1" /></td>
                      <td class="px-3 py-2 text-right">
                        <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" type="button" @click.prevent="removeOutputMaterialRow(index)">
                          {{ t('common.delete') }}
                        </button>
                      </td>
                    </tr>
                    <tr v-if="outputMaterialRows.length === 0">
                      <td colspan="7" class="px-3 py-4 text-center text-sm text-gray-500">{{ t('recipe.itemEditor.noOutputMaterials') }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <p v-if="stepErrors.material_outputs" class="mt-2 text-xs text-red-600">{{ stepErrors.material_outputs }}</p>
            </div>
          </div>
        </div>

        <div class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="flex items-center justify-between border-b px-4 py-3">
            <div>
              <h3 class="text-sm font-semibold text-gray-900">{{ t('recipe.itemEditor.sectionEquipments') }}</h3>
              <p class="mt-1 text-xs text-gray-500">{{ t('recipe.itemEditor.stepEquipmentHint') }}</p>
            </div>
            <button class="rounded border border-dashed px-3 py-1 text-sm hover:bg-gray-50" type="button" @click.prevent="addEquipmentRow">
              {{ t('recipe.itemEditor.addEquipment') }}
            </button>
          </div>
          <div class="overflow-x-auto p-4">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
                <tr>
                  <th class="px-3 py-2">{{ t('recipe.itemEditor.equipmentTypeCode') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.itemEditor.equipmentTemplateCode') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.quantity') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.itemEditor.capabilityRules') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.notes') }}</th>
                  <th class="px-3 py-2">{{ t('common.actions') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="(row, index) in equipmentRows" :key="row.key" class="align-top">
                  <td class="px-3 py-2"><input v-model.trim="row.equipment_type_code" class="w-full rounded border px-2 py-1 font-mono text-xs" /></td>
                  <td class="px-3 py-2"><input v-model.trim="row.equipment_template_code" class="w-full rounded border px-2 py-1 font-mono text-xs" /></td>
                  <td class="px-3 py-2"><input v-model.trim="row.quantity" class="w-full rounded border px-2 py-1" /></td>
                  <td class="px-3 py-2">
                    <textarea v-model.trim="row.capability_rules" rows="3" class="w-full rounded border px-2 py-1 font-mono text-xs" :placeholder="jsonObjectPlaceholder"></textarea>
                  </td>
                  <td class="px-3 py-2"><input v-model.trim="row.notes" class="w-full rounded border px-2 py-1" /></td>
                  <td class="px-3 py-2 text-right">
                    <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" type="button" @click.prevent="removeEquipmentRow(index)">
                      {{ t('common.delete') }}
                    </button>
                  </td>
                </tr>
                <tr v-if="equipmentRows.length === 0">
                  <td colspan="6" class="px-3 py-4 text-center text-sm text-gray-500">{{ t('recipe.itemEditor.noEquipment') }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <p v-if="stepErrors.equipment_requirements" class="px-4 pb-4 text-xs text-red-600">{{ stepErrors.equipment_requirements }}</p>
        </div>

        <div class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="flex items-center justify-between border-b px-4 py-3">
            <div>
              <h3 class="text-sm font-semibold text-gray-900">{{ t('recipe.itemEditor.sectionParameters') }}</h3>
              <p class="mt-1 text-xs text-gray-500">{{ t('recipe.itemEditor.stepParametersHint') }}</p>
            </div>
            <button class="rounded border border-dashed px-3 py-1 text-sm hover:bg-gray-50" type="button" @click.prevent="addParameterRow">
              {{ t('recipe.edit.addTargetParam') }}
            </button>
          </div>
          <div class="overflow-x-auto p-4">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
                <tr>
                  <th class="px-3 py-2">{{ t('recipe.edit.code') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.targetParamName') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.target') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.itemEditor.minValue') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.itemEditor.maxValue') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.itemEditor.setpoint') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.unit') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.requiredFlag') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.itemEditor.samplingFrequency') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.notes') }}</th>
                  <th class="px-3 py-2">{{ t('common.actions') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="(row, index) in parameterRows" :key="row.key">
                  <td class="px-3 py-2"><input v-model.trim="row.parameter_code" class="w-full rounded border px-2 py-1 font-mono text-xs" /></td>
                  <td class="px-3 py-2"><input v-model.trim="row.parameter_name" class="w-full rounded border px-2 py-1" /></td>
                  <td class="px-3 py-2"><input v-model.trim="row.target" class="w-full rounded border px-2 py-1" /></td>
                  <td class="px-3 py-2"><input v-model.trim="row.min" class="w-full rounded border px-2 py-1" /></td>
                  <td class="px-3 py-2"><input v-model.trim="row.max" class="w-full rounded border px-2 py-1" /></td>
                  <td class="px-3 py-2"><input v-model.trim="row.setpoint" class="w-full rounded border px-2 py-1" /></td>
                  <td class="px-3 py-2">
                    <select v-model="row.uom_code" class="w-full rounded border bg-white px-2 py-1">
                      <option value="">{{ t('common.none') }}</option>
                      <option v-for="option in uomOptionsForCode(row.uom_code)" :key="option.code" :value="option.code">
                        {{ formatUomOptionLabel(option) }}
                      </option>
                    </select>
                  </td>
                  <td class="px-3 py-2 text-center"><input v-model="row.required" type="checkbox" class="h-4 w-4" /></td>
                  <td class="px-3 py-2"><input v-model.trim="row.sampling_frequency" class="w-full rounded border px-2 py-1" /></td>
                  <td class="px-3 py-2"><input v-model.trim="row.notes" class="w-full rounded border px-2 py-1" /></td>
                  <td class="px-3 py-2 text-right">
                    <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" type="button" @click.prevent="removeParameterRow(index)">
                      {{ t('common.delete') }}
                    </button>
                  </td>
                </tr>
                <tr v-if="parameterRows.length === 0">
                  <td colspan="11" class="px-3 py-4 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <p v-if="stepErrors.parameters" class="px-4 pb-4 text-xs text-red-600">{{ stepErrors.parameters }}</p>
        </div>

        <div class="rounded-lg border border-gray-200 bg-white shadow">
          <div class="flex items-center justify-between border-b px-4 py-3">
            <div>
              <h3 class="text-sm font-semibold text-gray-900">{{ t('recipe.itemEditor.sectionQa') }}</h3>
              <p class="mt-1 text-xs text-gray-500">{{ t('recipe.itemEditor.stepQualityHint') }}</p>
            </div>
            <button class="rounded border border-dashed px-3 py-1 text-sm hover:bg-gray-50" type="button" @click.prevent="addQualityRow">
              {{ t('recipe.edit.addQualityCheck') }}
            </button>
          </div>
          <div class="overflow-x-auto p-4">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
                <tr>
                  <th class="px-3 py-2">{{ t('recipe.edit.code') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.name') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.samplingPoint') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.frequency') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.requiredFlag') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.acceptanceCriteria') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.notes') }}</th>
                  <th class="px-3 py-2">{{ t('common.actions') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="(row, index) in qualityRows" :key="row.key" class="align-top">
                  <td class="px-3 py-2"><input v-model.trim="row.check_code" class="w-full rounded border px-2 py-1 font-mono text-xs" /></td>
                  <td class="px-3 py-2"><input v-model.trim="row.check_name" class="w-full rounded border px-2 py-1" /></td>
                  <td class="px-3 py-2"><input v-model.trim="row.sampling_point" class="w-full rounded border px-2 py-1" /></td>
                  <td class="px-3 py-2"><input v-model.trim="row.frequency" class="w-full rounded border px-2 py-1" /></td>
                  <td class="px-3 py-2 text-center"><input v-model="row.required" type="checkbox" class="h-4 w-4" /></td>
                  <td class="px-3 py-2">
                    <textarea v-model.trim="row.acceptance_criteria" rows="3" class="w-full rounded border px-2 py-1 font-mono text-xs" :placeholder="jsonObjectPlaceholder"></textarea>
                  </td>
                  <td class="px-3 py-2"><input v-model.trim="row.notes" class="w-full rounded border px-2 py-1" /></td>
                  <td class="px-3 py-2 text-right">
                    <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" type="button" @click.prevent="removeQualityRow(index)">
                      {{ t('common.delete') }}
                    </button>
                  </td>
                </tr>
                <tr v-if="qualityRows.length === 0">
                  <td colspan="8" class="px-3 py-4 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <p v-if="stepErrors.quality_checks" class="px-4 pb-4 text-xs text-red-600">{{ stepErrors.quality_checks }}</p>
        </div>

        <div class="flex items-center justify-end gap-2">
          <button class="rounded border px-3 py-2 hover:bg-gray-100" type="button" @click="goBack">{{ t('common.cancel') }}</button>
          <button
            class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700 disabled:opacity-60"
            type="button"
            :disabled="saving"
            @click="saveEditor"
          >
            {{ saving ? t('common.saving') : t('recipe.itemEditor.saveAndReturn') }}
          </button>
        </div>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { openTypeDefGraph, type TypeDefGraphSelection } from '@/composables/useTypeDefGraphModal'
import { supabase } from '@/lib/supabase'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

const DEFAULT_SCHEMA_KEY = 'recipe_body_v1'
const FALLBACK_STEP_TYPES = ['process', 'prep', 'transfer', 'inspection', 'packaging', 'other']
const INPUT_BASIS_OPTIONS = ['per_base', 'fixed_per_batch', 'yield_based']
const CONSUMPTION_MODE_OPTIONS = ['exact', 'estimate', 'backflush']
const OUTPUT_TYPE_OPTIONS = ['primary', 'intermediate', 'co_product', 'waste']

type JsonObject = Record<string, unknown>

interface RecipeHeaderRow {
  id: string
  recipe_code: string
  recipe_name: string
  industry_type: string | null
}

interface RecipeVersionRow {
  id: string
  recipe_id: string
  version_no: number
  schema_code: string | null
  recipe_body_json: unknown
}

interface RecipeSchemaPayload {
  def_id: string | null
  def_key: string
  scope: string | null
  schema: JsonObject
}

interface UomRow {
  id: string
  code: string
  name: string
}

interface RecipeStepMaterialInput {
  material_type: string
  qty: number
  uom_code: string
  basis?: string
  consumption_mode?: string
  notes?: string
}

interface RecipeStepMaterialOutput {
  output_material_type: string
  output_name: string
  output_type: string
  qty: number
  uom_code: string
  notes?: string
}

interface RecipeEquipmentRequirement {
  equipment_type_code: string
  equipment_template_code?: string
  quantity?: number
  capability_rules?: JsonObject
  notes?: string
}

interface RecipeParameterTarget {
  parameter_code: string
  parameter_name?: string
  target?: number | string
  min?: number
  max?: number
  setpoint?: number | string
  uom_code?: string
  required?: boolean
  sampling_frequency?: string
  notes?: string
}

interface RecipeQualityCheck {
  check_code: string
  check_name?: string
  sampling_point?: string
  frequency?: string
  required?: boolean
  acceptance_criteria?: JsonObject
  notes?: string
}

interface RecipeFlowStep {
  step_code: string
  step_name: string
  step_no: number
  step_type?: string
  step_template_code?: string
  instructions?: string
  duration_sec?: number
  material_inputs?: RecipeStepMaterialInput[]
  material_outputs?: RecipeStepMaterialOutput[]
  equipment_requirements?: RecipeEquipmentRequirement[]
  parameters?: RecipeParameterTarget[]
  quality_checks?: RecipeQualityCheck[]
  hold_constraints?: JsonObject[]
  notes?: string
}

interface RecipeBody {
  schema_version: string
  recipe_info: JsonObject
  base: JsonObject
  outputs: {
    primary: unknown[]
    co_products: unknown[]
    waste: unknown[]
  }
  materials: {
    required: unknown[]
    optional: unknown[]
  }
  flow: {
    steps: RecipeFlowStep[]
  }
  quality: {
    global_checks: unknown[]
    release_criteria: JsonObject
  }
  documents: unknown[]
  [key: string]: unknown
}

interface InputMaterialRowState {
  key: string
  material_type: string
  qty: string
  uom_code: string
  basis: string
  consumption_mode: string
  notes: string
}

interface OutputMaterialRowState {
  key: string
  output_material_type: string
  output_name: string
  output_type: string
  qty: string
  uom_code: string
  notes: string
}

interface EquipmentRowState {
  key: string
  equipment_type_code: string
  equipment_template_code: string
  quantity: string
  capability_rules: string
  notes: string
}

interface ParameterRowState {
  key: string
  parameter_code: string
  parameter_name: string
  target: string
  min: string
  max: string
  setpoint: string
  uom_code: string
  required: boolean
  sampling_frequency: string
  notes: string
}

interface QualityRowState {
  key: string
  check_code: string
  check_name: string
  sampling_point: string
  frequency: string
  required: boolean
  acceptance_criteria: string
  notes: string
}

const route = useRoute()
const router = useRouter()
const { t } = useI18n()

const recipeHeader = ref<RecipeHeaderRow | null>(null)
const activeVersion = ref<RecipeVersionRow | null>(null)
const recipeBody = ref<RecipeBody>(createDefaultRecipeBody(DEFAULT_SCHEMA_KEY, ''))
const recipeSchema = ref<JsonObject | null>(null)
const uoms = ref<UomRow[]>([])
const loadingPage = ref(false)
const saving = ref(false)
const loadError = ref('')
const schemaError = ref('')

const stepSource = ref<RecipeFlowStep | null>(null)
const stepForm = reactive({
  step_no: 1,
  step_code: '',
  step_name: '',
  step_type: FALLBACK_STEP_TYPES[0],
  step_template_code: '',
  duration_sec: '',
  instructions: '',
  notes: '',
})
const stepErrors = reactive<Record<string, string>>({})

let inputMaterialRowCounter = 0
let outputMaterialRowCounter = 0
let equipmentRowCounter = 0
let parameterRowCounter = 0
let qualityRowCounter = 0

const inputMaterialRows = ref<InputMaterialRowState[]>([])
const outputMaterialRows = ref<OutputMaterialRowState[]>([])
const equipmentRows = ref<EquipmentRowState[]>([])
const parameterRows = ref<ParameterRowState[]>([])
const qualityRows = ref<QualityRowState[]>([])
const inputMaterialTypeInputRefs = new Map<string, HTMLInputElement>()

const recipeId = computed(() => (typeof route.params.recipeId === 'string' ? route.params.recipeId : ''))
const versionId = computed(() => (typeof route.params.versionId === 'string' ? route.params.versionId : ''))
const routeIndex = computed<number | null>(() => {
  if (typeof route.params.index !== 'string') return null
  const parsed = Number(route.params.index)
  return Number.isInteger(parsed) && parsed >= 0 ? parsed : null
})

const pageTitle = computed(() => (
  routeIndex.value === null ? t('recipe.itemEditor.stepCreateTitle') : t('recipe.itemEditor.stepEditTitle')
))
const pageSubtitle = computed(() => t('recipe.itemEditor.stepPageHint'))
const editorModeLabel = computed(() => t('recipe.itemEditor.modeStep'))
const editModeLabel = computed(() => (
  routeIndex.value === null ? t('recipe.itemEditor.modeCreate') : t('recipe.itemEditor.modeEdit')
))
const sectionLabel = computed(() => t('recipe.schemaSections.flow'))
const activeSchemaKey = computed(() => activeVersion.value?.schema_code || DEFAULT_SCHEMA_KEY)
const schemaStepTypes = computed(() => extractSchemaStepTypes(recipeSchema.value))
const usesSchemaStepOptions = computed(() => schemaStepTypes.value.length > 0)
const stepTypeOptions = computed(() => {
  const options = usesSchemaStepOptions.value ? [...schemaStepTypes.value] : [...FALLBACK_STEP_TYPES]
  if (stepForm.step_type && !options.includes(stepForm.step_type)) {
    options.unshift(stepForm.step_type)
  }
  return options
})
const inputBasisOptions = computed(() => INPUT_BASIS_OPTIONS)
const consumptionModeOptions = computed(() => CONSUMPTION_MODE_OPTIONS)
const outputTypeOptions = computed(() => OUTPUT_TYPE_OPTIONS)
const jsonObjectPlaceholder = computed(() => '{"key":"value"}')

const mesClient = () => supabase.schema('mes')

function handleMaterialTypeFocus(row: InputMaterialRowState) {
  openTypeDefGraph({
    preferredDomain: 'material_type',
    restoreFocusOnClose: false,
    onSelect: (selectedType: TypeDefGraphSelection) => {
      row.material_type = selectedType.code
      if (selectedType.defaultUomCode) {
        row.uom_code = selectedType.defaultUomCode
      }
    },
  })
}

function setInputMaterialTypeInputRef(key: string, element: unknown) {
  if (element instanceof HTMLInputElement) {
    inputMaterialTypeInputRefs.set(key, element)
    return
  }
  inputMaterialTypeInputRefs.delete(key)
}

function isJsonObject(value: unknown): value is JsonObject {
  return Boolean(value) && typeof value === 'object' && !Array.isArray(value)
}

function deepCloneJson<T>(value: T): T {
  return JSON.parse(JSON.stringify(value)) as T
}

function createDefaultRecipeBody(schemaCode: string, industryType: string): RecipeBody {
  return {
    schema_version: schemaCode === DEFAULT_SCHEMA_KEY ? 'recipe_body_v1' : 'recipe_body_v1',
    recipe_info: {
      recipe_type: 'process_manufacturing',
      industry_type: industryType || '',
      notes: '',
    },
    base: {
      quantity: 1,
      uom_code: 'PCS',
    },
    outputs: {
      primary: [],
      co_products: [],
      waste: [],
    },
    materials: {
      required: [],
      optional: [],
    },
    flow: {
      steps: [],
    },
    quality: {
      global_checks: [],
      release_criteria: {},
    },
    documents: [],
  }
}

function asTrimmedString(value: unknown) {
  return typeof value === 'string' ? value.trim() : ''
}

function asNumber(value: unknown) {
  if (typeof value === 'number' && Number.isFinite(value)) return value
  if (typeof value === 'string' && value.trim()) {
    const parsed = Number(value)
    return Number.isFinite(parsed) ? parsed : null
  }
  return null
}

function parseJsonObjectText(raw: string, errorMessage: string) {
  const trimmed = raw.trim()
  if (!trimmed) return undefined
  try {
    const parsed = JSON.parse(trimmed) as unknown
    if (!isJsonObject(parsed)) throw new Error(errorMessage)
    return parsed
  } catch {
    throw new Error(errorMessage)
  }
}

function normalizeStepMaterialInput(value: unknown): RecipeStepMaterialInput | null {
  if (!isJsonObject(value)) return null
  const materialType = asTrimmedString(value.material_type) || asTrimmedString(value.material_key)
  const qty = asNumber(value.qty)
  const uomCode = asTrimmedString(value.uom_code)
  if (!materialType || qty === null || qty < 0 || !uomCode) return null
  return {
    material_type: materialType,
    qty,
    uom_code: uomCode,
    basis: asTrimmedString(value.basis) || undefined,
    consumption_mode: asTrimmedString(value.consumption_mode) || undefined,
    notes: asTrimmedString(value.notes) || undefined,
  }
}

function normalizeStepMaterialOutput(value: unknown): RecipeStepMaterialOutput | null {
  if (!isJsonObject(value)) return null
  const outputMaterialType = asTrimmedString(value.output_material_type) || asTrimmedString(value.output_code)
  const outputName = asTrimmedString(value.output_name)
  const outputType = asTrimmedString(value.output_type)
  const qty = asNumber(value.qty)
  const uomCode = asTrimmedString(value.uom_code)
  if (!outputMaterialType || !outputName || !outputType || qty === null || qty < 0 || !uomCode) return null
  return {
    output_material_type: outputMaterialType,
    output_name: outputName,
    output_type: outputType,
    qty,
    uom_code: uomCode,
    notes: asTrimmedString(value.notes) || undefined,
  }
}

function normalizeEquipmentRequirement(value: unknown): RecipeEquipmentRequirement | null {
  if (!isJsonObject(value)) return null
  const equipmentTypeCode = asTrimmedString(value.equipment_type_code)
  if (!equipmentTypeCode) return null
  const quantity = asNumber(value.quantity)
  return {
    equipment_type_code: equipmentTypeCode,
    equipment_template_code: asTrimmedString(value.equipment_template_code) || undefined,
    quantity: quantity === null ? undefined : quantity,
    capability_rules: isJsonObject(value.capability_rules) ? deepCloneJson(value.capability_rules) : undefined,
    notes: asTrimmedString(value.notes) || undefined,
  }
}

function normalizeParameterTarget(value: unknown): RecipeParameterTarget | null {
  if (!isJsonObject(value)) return null
  const parameterCode = asTrimmedString(value.parameter_code)
  if (!parameterCode) return null
  return {
    parameter_code: parameterCode,
    parameter_name: asTrimmedString(value.parameter_name) || undefined,
    target: typeof value.target === 'number' || typeof value.target === 'string' ? value.target : undefined,
    min: typeof value.min === 'number' ? value.min : undefined,
    max: typeof value.max === 'number' ? value.max : undefined,
    setpoint: typeof value.setpoint === 'number' || typeof value.setpoint === 'string' ? value.setpoint : undefined,
    uom_code: asTrimmedString(value.uom_code) || undefined,
    required: typeof value.required === 'boolean' ? value.required : undefined,
    sampling_frequency: asTrimmedString(value.sampling_frequency) || undefined,
    notes: asTrimmedString(value.notes) || undefined,
  }
}

function normalizeQualityCheck(value: unknown): RecipeQualityCheck | null {
  if (!isJsonObject(value)) return null
  const checkCode = asTrimmedString(value.check_code)
  if (!checkCode) return null
  return {
    check_code: checkCode,
    check_name: asTrimmedString(value.check_name) || undefined,
    sampling_point: asTrimmedString(value.sampling_point) || undefined,
    frequency: asTrimmedString(value.frequency) || undefined,
    required: typeof value.required === 'boolean' ? value.required : undefined,
    acceptance_criteria: isJsonObject(value.acceptance_criteria) ? deepCloneJson(value.acceptance_criteria) : undefined,
    notes: asTrimmedString(value.notes) || undefined,
  }
}

function normalizeFlowStep(value: unknown): RecipeFlowStep | null {
  if (!isJsonObject(value)) return null
  const stepCode = asTrimmedString(value.step_code)
  const stepName = asTrimmedString(value.step_name)
  const stepNo = asNumber(value.step_no)
  if (!stepCode || !stepName || stepNo === null || !Number.isInteger(stepNo) || stepNo < 1) return null

  return {
    step_code: stepCode,
    step_name: stepName,
    step_no: stepNo,
    step_type: asTrimmedString(value.step_type) || undefined,
    step_template_code: asTrimmedString(value.step_template_code) || undefined,
    instructions: asTrimmedString(value.instructions) || undefined,
    duration_sec: typeof value.duration_sec === 'number' ? value.duration_sec : undefined,
    material_inputs: Array.isArray(value.material_inputs)
      ? value.material_inputs.map(normalizeStepMaterialInput).filter((item): item is RecipeStepMaterialInput => Boolean(item))
      : [],
    material_outputs: Array.isArray(value.material_outputs)
      ? value.material_outputs.map(normalizeStepMaterialOutput).filter((item): item is RecipeStepMaterialOutput => Boolean(item))
      : [],
    equipment_requirements: Array.isArray(value.equipment_requirements)
      ? value.equipment_requirements.map(normalizeEquipmentRequirement).filter((item): item is RecipeEquipmentRequirement => Boolean(item))
      : [],
    parameters: Array.isArray(value.parameters)
      ? value.parameters.map(normalizeParameterTarget).filter((item): item is RecipeParameterTarget => Boolean(item))
      : [],
    quality_checks: Array.isArray(value.quality_checks)
      ? value.quality_checks.map(normalizeQualityCheck).filter((item): item is RecipeQualityCheck => Boolean(item))
      : [],
    hold_constraints: Array.isArray(value.hold_constraints) ? value.hold_constraints.filter(isJsonObject) : [],
    notes: asTrimmedString(value.notes) || undefined,
  }
}

function normalizeRecipeBody(raw: unknown, industryType: string, schemaCode: string): RecipeBody {
  const base = isJsonObject(raw) ? raw : {}
  const normalized = createDefaultRecipeBody(schemaCode, industryType)
  const flow = isJsonObject(base.flow) ? base.flow : {}
  const quality = isJsonObject(base.quality) ? base.quality : {}
  const outputs = isJsonObject(base.outputs) ? base.outputs : {}
  const materials = isJsonObject(base.materials) ? base.materials : {}

  return {
    ...deepCloneJson(base),
    schema_version: typeof base.schema_version === 'string' ? base.schema_version : normalized.schema_version,
    recipe_info: isJsonObject(base.recipe_info) ? deepCloneJson(base.recipe_info) : normalized.recipe_info,
    base: isJsonObject(base.base) ? deepCloneJson(base.base) : normalized.base,
    outputs: {
      primary: Array.isArray(outputs.primary) ? deepCloneJson(outputs.primary) : [],
      co_products: Array.isArray(outputs.co_products) ? deepCloneJson(outputs.co_products) : [],
      waste: Array.isArray(outputs.waste) ? deepCloneJson(outputs.waste) : [],
    },
    materials: {
      required: Array.isArray(materials.required) ? deepCloneJson(materials.required) : [],
      optional: Array.isArray(materials.optional) ? deepCloneJson(materials.optional) : [],
    },
    flow: {
      steps: Array.isArray(flow.steps)
        ? flow.steps.map(normalizeFlowStep).filter((item): item is RecipeFlowStep => Boolean(item))
        : [],
    },
    quality: {
      global_checks: Array.isArray(quality.global_checks) ? deepCloneJson(quality.global_checks) : [],
      release_criteria: isJsonObject(quality.release_criteria) ? deepCloneJson(quality.release_criteria) : {},
    },
    documents: Array.isArray(base.documents) ? deepCloneJson(base.documents) : [],
  }
}

function formatLabel(value: string) {
  return value
    .split('_')
    .filter(Boolean)
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ')
}

function toTranslationKey(value: string) {
  return value.replace(/_([a-z])/g, (_, char: string) => char.toUpperCase())
}

function translateEnum(baseKey: string, value: string) {
  const key = `${baseKey}.${toTranslationKey(value)}`
  const translated = t(key)
  return translated === key ? formatLabel(value) : translated
}

function formatStepType(value: string) {
  return translateEnum('recipe.stepTypes', value)
}

function formatBasis(value: string) {
  return translateEnum('recipe.basis', value)
}

function formatConsumptionMode(value: string) {
  return translateEnum('recipe.consumptionModes', value)
}

function formatOutputType(value: string) {
  const keyMap: Record<string, string> = {
    primary: 'recipe.edit.outputTypePrimary',
    intermediate: 'recipe.edit.outputTypeIntermediate',
    co_product: 'recipe.edit.outputTypeCoProduct',
    waste: 'recipe.edit.outputTypeWaste',
  }
  const key = keyMap[value]
  if (!key) return formatLabel(value)
  const translated = t(key)
  return translated === key ? formatLabel(value) : translated
}

function formatUomOptionLabel(row: Pick<UomRow, 'code' | 'name'> | null) {
  if (!row) return ''
  return row.name ? `${row.code} - ${row.name}` : row.code
}

function uomOptionsForCode(currentCode: string) {
  const normalized = currentCode.trim()
  const options = [...uoms.value]
  if (normalized && !options.some((row) => row.code === normalized)) {
    options.unshift({
      id: `custom:${normalized}`,
      code: normalized,
      name: normalized,
    })
  }
  return options
}

function resolveSchemaNode(root: JsonObject | null, value: unknown): JsonObject | null {
  if (isJsonObject(value) && typeof value.$ref === 'string' && value.$ref.startsWith('#/')) {
    const segments = value.$ref.slice(2).split('/')
    let current: unknown = root
    for (const segment of segments) {
      if (!isJsonObject(current)) return null
      current = current[segment]
    }
    return isJsonObject(current) ? current : null
  }
  return isJsonObject(value) ? value : null
}

function extractSchemaStepTypes(schema: JsonObject | null) {
  const props = resolveSchemaNode(schema, schema?.properties)
  const flowNode = resolveSchemaNode(schema, props?.flow)
  const flowProps = resolveSchemaNode(schema, flowNode?.properties)
  const stepsNode = resolveSchemaNode(schema, flowProps?.steps)
  const stepItems = resolveSchemaNode(schema, stepsNode?.items)
  const stepProps = resolveSchemaNode(schema, stepItems?.properties)
  const stepTypeNode = resolveSchemaNode(schema, stepProps?.step_type)
  const enumValues = Array.isArray(stepTypeNode?.enum)
    ? stepTypeNode.enum.filter((item): item is string => typeof item === 'string' && item.trim().length > 0)
    : []
  return Array.from(new Set(enumValues))
}

function createInputMaterialRow(initial?: Partial<InputMaterialRowState>): InputMaterialRowState {
  return {
    key: `in-${++inputMaterialRowCounter}`,
    material_type: initial?.material_type ?? '',
    qty: initial?.qty ?? '',
    uom_code: initial?.uom_code ?? '',
    basis: initial?.basis ?? 'per_base',
    consumption_mode: initial?.consumption_mode ?? 'estimate',
    notes: initial?.notes ?? '',
  }
}

function createOutputMaterialRow(initial?: Partial<OutputMaterialRowState>): OutputMaterialRowState {
  return {
    key: `out-${++outputMaterialRowCounter}`,
    output_material_type: initial?.output_material_type ?? '',
    output_name: initial?.output_name ?? '',
    output_type: initial?.output_type ?? '',
    qty: initial?.qty ?? '',
    uom_code: initial?.uom_code ?? '',
    notes: initial?.notes ?? '',
  }
}

function createEquipmentRow(initial?: Partial<EquipmentRowState>): EquipmentRowState {
  return {
    key: `eq-${++equipmentRowCounter}`,
    equipment_type_code: initial?.equipment_type_code ?? '',
    equipment_template_code: initial?.equipment_template_code ?? '',
    quantity: initial?.quantity ?? '',
    capability_rules: initial?.capability_rules ?? '',
    notes: initial?.notes ?? '',
  }
}

function createParameterRow(initial?: Partial<ParameterRowState>): ParameterRowState {
  return {
    key: `param-${++parameterRowCounter}`,
    parameter_code: initial?.parameter_code ?? '',
    parameter_name: initial?.parameter_name ?? '',
    target: initial?.target ?? '',
    min: initial?.min ?? '',
    max: initial?.max ?? '',
    setpoint: initial?.setpoint ?? '',
    uom_code: initial?.uom_code ?? '',
    required: initial?.required ?? false,
    sampling_frequency: initial?.sampling_frequency ?? '',
    notes: initial?.notes ?? '',
  }
}

function createQualityRow(initial?: Partial<QualityRowState>): QualityRowState {
  return {
    key: `qc-${++qualityRowCounter}`,
    check_code: initial?.check_code ?? '',
    check_name: initial?.check_name ?? '',
    sampling_point: initial?.sampling_point ?? '',
    frequency: initial?.frequency ?? '',
    required: initial?.required ?? false,
    acceptance_criteria: initial?.acceptance_criteria ?? '',
    notes: initial?.notes ?? '',
  }
}

async function loadReferenceData() {
  const { data, error } = await supabase
    .from('mst_uom')
    .select('id, code, name')
    .order('code', { ascending: true })

  if (error) throw error
  uoms.value = (data ?? []) as UomRow[]
}

function resetStepErrors() {
  Object.keys(stepErrors).forEach((key) => delete stepErrors[key])
}

function resetStepForm() {
  stepSource.value = null
  stepForm.step_no = recipeBody.value.flow.steps.length > 0 ? Math.max(...recipeBody.value.flow.steps.map((item) => item.step_no)) + 10 : 10
  stepForm.step_code = ''
  stepForm.step_name = ''
  stepForm.step_type = stepTypeOptions.value[0] ?? FALLBACK_STEP_TYPES[0]
  stepForm.step_template_code = ''
  stepForm.duration_sec = ''
  stepForm.instructions = ''
  stepForm.notes = ''
  inputMaterialRows.value = []
  outputMaterialRows.value = []
  equipmentRows.value = []
  parameterRows.value = []
  qualityRows.value = []
  inputMaterialTypeInputRefs.clear()
  resetStepErrors()
}

function initializeStepEditor() {
  resetStepForm()
  if (routeIndex.value === null) return

  const step = recipeBody.value.flow.steps[routeIndex.value]
  if (!step) throw new Error(t('recipe.itemEditor.targetNotFound'))

  stepSource.value = deepCloneJson(step)
  stepForm.step_no = step.step_no
  stepForm.step_code = step.step_code
  stepForm.step_name = step.step_name
  stepForm.step_type = step.step_type || stepTypeOptions.value[0] || FALLBACK_STEP_TYPES[0]
  stepForm.step_template_code = step.step_template_code || ''
  stepForm.duration_sec = step.duration_sec != null ? String(step.duration_sec) : ''
  stepForm.instructions = step.instructions || ''
  stepForm.notes = step.notes || ''
  inputMaterialRows.value = (step.material_inputs ?? []).map((row) => createInputMaterialRow({
    material_type: row.material_type,
    qty: String(row.qty),
    uom_code: row.uom_code,
    basis: row.basis || '',
    consumption_mode: row.consumption_mode || '',
    notes: row.notes || '',
  }))
  outputMaterialRows.value = (step.material_outputs ?? []).map((row) => createOutputMaterialRow({
    output_material_type: row.output_material_type,
    output_name: row.output_name,
    output_type: row.output_type,
    qty: String(row.qty),
    uom_code: row.uom_code,
    notes: row.notes || '',
  }))
  equipmentRows.value = (step.equipment_requirements ?? []).map((row) => createEquipmentRow({
    equipment_type_code: row.equipment_type_code,
    equipment_template_code: row.equipment_template_code || '',
    quantity: row.quantity == null ? '' : String(row.quantity),
    capability_rules: row.capability_rules ? JSON.stringify(row.capability_rules, null, 2) : '',
    notes: row.notes || '',
  }))
  parameterRows.value = (step.parameters ?? []).map((row) => createParameterRow({
    parameter_code: row.parameter_code,
    parameter_name: row.parameter_name || '',
    target: row.target == null ? '' : String(row.target),
    min: row.min == null ? '' : String(row.min),
    max: row.max == null ? '' : String(row.max),
    setpoint: row.setpoint == null ? '' : String(row.setpoint),
    uom_code: row.uom_code || '',
    required: row.required ?? false,
    sampling_frequency: row.sampling_frequency || '',
    notes: row.notes || '',
  }))
  qualityRows.value = (step.quality_checks ?? []).map((row) => createQualityRow({
    check_code: row.check_code,
    check_name: row.check_name || '',
    sampling_point: row.sampling_point || '',
    frequency: row.frequency || '',
    required: row.required ?? false,
    acceptance_criteria: row.acceptance_criteria ? JSON.stringify(row.acceptance_criteria, null, 2) : '',
    notes: row.notes || '',
  }))
}

async function addInputMaterialRow() {
  const row = createInputMaterialRow()
  inputMaterialRows.value.push(row)
  await nextTick()
  inputMaterialTypeInputRefs.get(row.key)?.focus()
}

function removeInputMaterialRow(index: number) {
  inputMaterialRows.value.splice(index, 1)
}

function addOutputMaterialRow() {
  outputMaterialRows.value.push(createOutputMaterialRow())
}

function removeOutputMaterialRow(index: number) {
  outputMaterialRows.value.splice(index, 1)
}

function addEquipmentRow() {
  equipmentRows.value.push(createEquipmentRow())
}

function removeEquipmentRow(index: number) {
  equipmentRows.value.splice(index, 1)
}

function addParameterRow() {
  parameterRows.value.push(createParameterRow())
}

function removeParameterRow(index: number) {
  parameterRows.value.splice(index, 1)
}

function addQualityRow() {
  qualityRows.value.push(createQualityRow())
}

function removeQualityRow(index: number) {
  qualityRows.value.splice(index, 1)
}

function parseOptionalNumber(raw: string) {
  if (!raw.trim()) return undefined
  const parsed = Number(raw)
  return Number.isFinite(parsed) ? parsed : null
}

function parseOptionalNumericOrText(raw: string) {
  const trimmed = raw.trim()
  if (!trimmed) return undefined
  const parsed = Number(trimmed)
  return Number.isNaN(parsed) ? trimmed : parsed
}

function validateStepForm() {
  resetStepErrors()
  if (!Number.isInteger(stepForm.step_no) || stepForm.step_no < 1) stepErrors.step_no = t('recipe.edit.stepNumberPositive')
  if (!stepForm.step_code.trim()) stepErrors.step_code = t('recipe.edit.stepCodeRequired')
  if (!stepForm.step_name.trim()) stepErrors.step_name = t('recipe.edit.stepNameRequired')
  return Object.keys(stepErrors).length === 0
}

function buildMaterialInputs() {
  const rows = inputMaterialRows.value.filter((row) => (
    row.material_type.trim() || row.qty.trim() || row.uom_code.trim() || row.basis || row.consumption_mode || row.notes.trim()
  ))
  const parsed: RecipeStepMaterialInput[] = []

  for (const row of rows) {
    const materialType = row.material_type.trim()
    const qty = parseOptionalNumber(row.qty)
    const uomCode = row.uom_code.trim()
    if (!materialType) {
      stepErrors.material_inputs = t('recipe.itemEditor.inputMaterialRequired')
      return null
    }
    if (qty == null || qty < 0) {
      stepErrors.material_inputs = t('recipe.edit.quantityNonNegative')
      return null
    }
    if (!uomCode) {
      stepErrors.material_inputs = t('recipe.edit.uomCodeRequired')
      return null
    }
    parsed.push({
      material_type: materialType,
      qty,
      uom_code: uomCode,
      basis: row.basis || undefined,
      consumption_mode: row.consumption_mode || undefined,
      notes: row.notes.trim() || undefined,
    })
  }

  return parsed
}

function buildMaterialOutputs() {
  const rows = outputMaterialRows.value.filter((row) => (
    row.output_material_type.trim() || row.output_name.trim() || row.output_type || row.qty.trim() || row.uom_code.trim() || row.notes.trim()
  ))
  const parsed: RecipeStepMaterialOutput[] = []

  for (const row of rows) {
    const outputMaterialType = row.output_material_type.trim()
    const outputName = row.output_name.trim()
    const qty = parseOptionalNumber(row.qty)
    const uomCode = row.uom_code.trim()
    if (!outputMaterialType) {
      stepErrors.material_outputs = t('recipe.edit.outputCodeRequired')
      return null
    }
    if (!outputName) {
      stepErrors.material_outputs = t('recipe.edit.outputNameRequired')
      return null
    }
    if (!row.output_type) {
      stepErrors.material_outputs = t('recipe.itemEditor.outputTypeRequired')
      return null
    }
    if (qty == null || qty < 0) {
      stepErrors.material_outputs = t('recipe.edit.outputQuantityNonNegative')
      return null
    }
    if (!uomCode) {
      stepErrors.material_outputs = t('recipe.edit.outputUomRequired')
      return null
    }
    parsed.push({
      output_material_type: outputMaterialType,
      output_name: outputName,
      output_type: row.output_type,
      qty,
      uom_code: uomCode,
      notes: row.notes.trim() || undefined,
    })
  }

  return parsed
}

function buildEquipmentRequirements() {
  const rows = equipmentRows.value.filter((row) => (
    row.equipment_type_code.trim() || row.equipment_template_code.trim() || row.quantity.trim() || row.capability_rules.trim() || row.notes.trim()
  ))
  const parsed: RecipeEquipmentRequirement[] = []

  for (const row of rows) {
    const equipmentTypeCode = row.equipment_type_code.trim()
    if (!equipmentTypeCode) {
      stepErrors.equipment_requirements = t('recipe.itemEditor.equipmentTypeRequired')
      return null
    }
    const quantity = parseOptionalNumber(row.quantity)
    if (quantity !== undefined && (quantity == null || quantity < 1)) {
      stepErrors.equipment_requirements = t('recipe.itemEditor.equipmentQuantityPositive')
      return null
    }
    let capabilityRules: JsonObject | undefined
    try {
      capabilityRules = parseJsonObjectText(row.capability_rules, t('recipe.itemEditor.jsonObjectInvalid'))
    } catch (error: unknown) {
      stepErrors.equipment_requirements = error instanceof Error ? error.message : String(error)
      return null
    }
    parsed.push({
      equipment_type_code: equipmentTypeCode,
      equipment_template_code: row.equipment_template_code.trim() || undefined,
      quantity: quantity === undefined ? undefined : quantity,
      capability_rules: capabilityRules,
      notes: row.notes.trim() || undefined,
    })
  }

  return parsed
}

function buildParameters() {
  const rows = parameterRows.value.filter((row) => (
    row.parameter_code.trim() || row.parameter_name.trim() || row.target.trim() || row.min.trim() || row.max.trim()
    || row.setpoint.trim() || row.uom_code.trim() || row.required || row.sampling_frequency.trim() || row.notes.trim()
  ))
  const parsed: RecipeParameterTarget[] = []

  for (const row of rows) {
    const parameterCode = row.parameter_code.trim()
    if (!parameterCode) {
      stepErrors.parameters = t('recipe.itemEditor.parameterCodeRequired')
      return null
    }
    const min = parseOptionalNumber(row.min)
    const max = parseOptionalNumber(row.max)
    if (min === null || max === null) {
      stepErrors.parameters = t('recipe.itemEditor.parameterNumberInvalid')
      return null
    }
    parsed.push({
      parameter_code: parameterCode,
      parameter_name: row.parameter_name.trim() || undefined,
      target: parseOptionalNumericOrText(row.target),
      min: min === undefined ? undefined : min,
      max: max === undefined ? undefined : max,
      setpoint: parseOptionalNumericOrText(row.setpoint),
      uom_code: row.uom_code.trim() || undefined,
      required: row.required || undefined,
      sampling_frequency: row.sampling_frequency.trim() || undefined,
      notes: row.notes.trim() || undefined,
    })
  }

  return parsed
}

function buildQualityChecks() {
  const rows = qualityRows.value.filter((row) => (
    row.check_code.trim() || row.check_name.trim() || row.sampling_point.trim() || row.frequency.trim()
    || row.required || row.acceptance_criteria.trim() || row.notes.trim()
  ))
  const parsed: RecipeQualityCheck[] = []

  for (const row of rows) {
    const checkCode = row.check_code.trim()
    if (!checkCode) {
      stepErrors.quality_checks = t('recipe.edit.qualityCheckCodeRequired')
      return null
    }
    let acceptanceCriteria: JsonObject | undefined
    try {
      acceptanceCriteria = parseJsonObjectText(row.acceptance_criteria, t('recipe.edit.acceptanceCriteriaInvalid'))
    } catch (error: unknown) {
      stepErrors.quality_checks = error instanceof Error ? error.message : String(error)
      return null
    }
    parsed.push({
      check_code: checkCode,
      check_name: row.check_name.trim() || undefined,
      sampling_point: row.sampling_point.trim() || undefined,
      frequency: row.frequency.trim() || undefined,
      required: row.required || undefined,
      acceptance_criteria: acceptanceCriteria,
      notes: row.notes.trim() || undefined,
    })
  }

  return parsed
}

async function loadSchema() {
  schemaError.value = ''

  try {
    const { data, error } = await supabase.rpc('recipe_schema_get', {
      p_def_key: activeSchemaKey.value,
    })
    if (error) throw error
    if (!isJsonObject(data) || !isJsonObject(data.schema) || typeof data.def_key !== 'string') {
      throw new Error(t('recipe.edit.invalidSchemaPayload'))
    }
    const payload = data as unknown as RecipeSchemaPayload
    recipeSchema.value = payload.schema
  } catch (error: unknown) {
    recipeSchema.value = null
    schemaError.value = t('recipe.edit.loadSchemaFailed', {
      message: error instanceof Error ? error.message : String(error),
    })
  }
}

async function loadRecipeContext() {
  const { data: headerData, error: headerError } = await mesClient()
    .from('mst_recipe')
    .select('id, recipe_code, recipe_name, industry_type')
    .eq('id', recipeId.value)
    .single()
  if (headerError || !headerData) throw headerError ?? new Error(t('recipe.itemEditor.loadFailed'))

  const { data: versionData, error: versionError } = await mesClient()
    .from('mst_recipe_version')
    .select('id, recipe_id, version_no, schema_code, recipe_body_json')
    .eq('id', versionId.value)
    .eq('recipe_id', recipeId.value)
    .single()
  if (versionError || !versionData) throw versionError ?? new Error(t('recipe.itemEditor.loadFailed'))

  recipeHeader.value = headerData as RecipeHeaderRow
  activeVersion.value = versionData as RecipeVersionRow
  recipeBody.value = normalizeRecipeBody(versionData.recipe_body_json, headerData.industry_type ?? '', versionData.schema_code || DEFAULT_SCHEMA_KEY)
}

async function initializePage() {
  if (!recipeId.value || !versionId.value) {
    loadError.value = t('recipe.itemEditor.invalidRoute')
    return
  }

  loadingPage.value = true
  loadError.value = ''

  try {
    await Promise.all([
      loadRecipeContext(),
      loadReferenceData(),
    ])
    await loadSchema()
    initializeStepEditor()
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error)
    loadError.value = message
    toast.error(message)
  } finally {
    loadingPage.value = false
  }
}

async function persistRecipeBody() {
  if (!activeVersion.value) throw new Error(t('recipe.itemEditor.saveFailed'))
  const { error } = await mesClient()
    .from('mst_recipe_version')
    .update({
      recipe_body_json: recipeBody.value,
    })
    .eq('id', activeVersion.value.id)
  if (error) throw error
}

async function saveEditor() {
  if (!activeVersion.value) return
  if (!validateStepForm()) return

  const materialInputs = buildMaterialInputs()
  const materialOutputs = buildMaterialOutputs()
  const equipmentRequirements = buildEquipmentRequirements()
  const parameters = buildParameters()
  const qualityChecks = buildQualityChecks()

  if (!materialInputs || !materialOutputs || !equipmentRequirements || !parameters || !qualityChecks) return

  const durationSec = parseOptionalNumber(stepForm.duration_sec)
  if (durationSec === null || (durationSec !== undefined && durationSec < 0)) {
    stepErrors.duration_sec = t('recipe.itemEditor.durationNonNegative')
    return
  }

  const step: RecipeFlowStep = {
    step_code: stepForm.step_code.trim(),
    step_name: stepForm.step_name.trim(),
    step_no: stepForm.step_no,
    step_type: stepForm.step_type || undefined,
    step_template_code: stepForm.step_template_code.trim() || undefined,
    instructions: stepForm.instructions.trim() || undefined,
    duration_sec: durationSec,
    material_inputs: materialInputs,
    material_outputs: materialOutputs,
    equipment_requirements: equipmentRequirements,
    parameters,
    quality_checks: qualityChecks,
    hold_constraints: stepSource.value?.hold_constraints ?? [],
    notes: stepForm.notes.trim() || undefined,
  }

  if (routeIndex.value === null) {
    recipeBody.value.flow.steps.push(step)
  } else {
    recipeBody.value.flow.steps.splice(routeIndex.value, 1, step)
  }
  recipeBody.value.flow.steps.sort((a, b) => a.step_no - b.step_no)

  try {
    saving.value = true
    await persistRecipeBody()
    toast.success(t('recipe.itemEditor.stepSaved'))
    await goBack()
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error)
    toast.error(t('recipe.itemEditor.saveFailedWithMessage', { message }))
  } finally {
    saving.value = false
  }
}

async function goBack() {
  await router.push({
    path: `/recipeEdit/${recipeId.value}/${versionId.value}`,
    query: activeVersion.value?.schema_code ? { schemaKey: activeVersion.value.schema_code } : undefined,
  })
}

onMounted(async () => {
  await initializePage()
})

watch(
  () => [route.params.recipeId, route.params.versionId, route.params.index],
  async (next, previous) => {
    if (JSON.stringify(next) === JSON.stringify(previous)) return
    await initializePage()
  },
)
</script>
