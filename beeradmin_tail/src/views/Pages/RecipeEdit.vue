<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="space-y-6">
      <section class="rounded-lg border border-gray-200 bg-white shadow" aria-labelledby="recipeEditHeader">
        <header class="flex flex-col gap-3 border-b p-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 id="recipeEditHeader" class="text-lg font-semibold text-gray-900">{{ t('recipe.edit.headerTitle') }}</h2>
            <p class="text-sm text-gray-500">{{ t('recipe.edit.headerSubtitle') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <button class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-100" :disabled="loadingPage" @click="loadRecipeContext">
              {{ t('common.refresh') }}
            </button>
            <button class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-100" :disabled="schemaLoading" @click="loadSchema">
              {{ schemaLoading ? t('recipe.edit.loadingSchema') : t('recipe.edit.loadSchema') }}
            </button>
            <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700 disabled:opacity-60" :disabled="saving" @click="saveRecipe">
              {{ saving ? t('common.saving') : t('common.save') }}
            </button>
            <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700 disabled:opacity-60" :disabled="versioning" @click="versionUp">
              {{ versioning ? t('common.saving') : t('recipe.edit.versionUpAction') }}
            </button>
          </div>
        </header>

        <div class="grid grid-cols-1 gap-6 p-4 lg:grid-cols-[2fr_1fr]">
          <form class="grid grid-cols-1 gap-4 md:grid-cols-2" @submit.prevent>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.recipeCode') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="headerForm.recipe_code" class="h-[40px] w-full rounded border px-3" />
              <p v-if="headerErrors.recipe_code" class="mt-1 text-xs text-red-600">{{ headerErrors.recipe_code }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.recipeName') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="headerForm.recipe_name" class="h-[40px] w-full rounded border px-3" />
              <p v-if="headerErrors.recipe_name" class="mt-1 text-xs text-red-600">{{ headerErrors.recipe_name }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.recipeCategory') }}</label>
              <input v-model.trim="headerForm.recipe_category" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.industryType') }}</label>
              <input v-model.trim="headerForm.industry_type" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.recipeStatus') }}</label>
              <select v-model="headerForm.status" class="h-[40px] w-full rounded border bg-white px-3">
                <option v-for="status in RECIPE_STATUSES" :key="status" :value="status">{{ formatRecipeStatus(status) }}</option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.version') }}</label>
              <select v-model="currentVersionId" class="h-[40px] w-full rounded border bg-white px-3" @change="handleVersionChange">
                <option v-for="version in versionOptions" :key="version.id" :value="version.id">
                  v{{ version.version_no }} / {{ formatVersionStatus(version.status) }}
                </option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.versionLabel') }}</label>
              <input v-model.trim="versionForm.version_label" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.schemaCode') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="versionForm.schema_code" class="h-[40px] w-full rounded border px-3 font-mono text-sm" />
              <p v-if="versionErrors.schema_code" class="mt-1 text-xs text-red-600">{{ versionErrors.schema_code }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.versionStatus') }}</label>
              <select v-model="versionForm.status" class="h-[40px] w-full rounded border bg-white px-3">
                <option v-for="status in VERSION_STATUSES" :key="status" :value="status">{{ formatVersionStatus(status) }}</option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.effectiveFrom') }}</label>
              <input v-model="versionForm.effective_from" type="datetime-local" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.effectiveTo') }}</label>
              <input v-model="versionForm.effective_to" type="datetime-local" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div class="md:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.changeSummary') }}</label>
              <textarea v-model.trim="versionForm.change_summary" rows="3" class="w-full rounded border px-3 py-2"></textarea>
            </div>
          </form>

          <div class="rounded-lg border border-gray-200 bg-gray-50 p-4">
            <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">{{ t('recipe.edit.schemaTitle') }}</p>
            <p class="mt-1 font-mono text-sm text-gray-900">{{ versionForm.schema_code || DEFAULT_SCHEMA_KEY }}</p>
            <p class="mt-1 text-xs text-gray-500">
              <span v-if="schemaMeta.scope">{{ t('recipe.edit.schemaScope') }}: {{ schemaMeta.scope }}</span>
              <span v-if="schemaMeta.def_id" class="ml-2">{{ t('recipe.edit.schemaDefId') }}: {{ schemaMeta.def_id }}</span>
            </p>
            <p v-if="schemaError" class="mt-2 text-xs text-red-600">{{ schemaError }}</p>

            <div class="mt-4">
              <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">{{ t('recipe.edit.visibleSections') }}</p>
              <div class="mt-2 flex flex-wrap gap-2">
                <span
                  v-for="section in schemaSectionBadges"
                  :key="section.key"
                  class="inline-flex items-center rounded-full px-2 py-1 text-xs"
                  :class="section.enabled ? 'bg-green-100 text-green-800' : 'bg-gray-200 text-gray-600'"
                >
                  {{ section.label }}
                </span>
              </div>
            </div>

            <div class="mt-4">
              <p class="text-xs font-semibold uppercase tracking-wide text-gray-500">{{ t('recipe.edit.bodySummary') }}</p>
              <dl class="mt-2 space-y-1 text-sm text-gray-600">
                <div class="flex justify-between gap-3">
                  <dt>{{ t('recipe.edit.requiredMaterials') }}</dt>
                  <dd>{{ requiredMaterials.length }}</dd>
                </div>
                <div class="flex justify-between gap-3">
                  <dt>{{ t('recipe.edit.optionalMaterials') }}</dt>
                  <dd>{{ optionalMaterials.length }}</dd>
                </div>
                <div class="flex justify-between gap-3">
                  <dt>{{ t('recipe.edit.steps') }}</dt>
                  <dd>{{ flowSteps.length }}</dd>
                </div>
                <div class="flex justify-between gap-3">
                  <dt>{{ t('recipe.edit.stepTypeSource') }}</dt>
                  <dd>{{ usesSchemaStepOptions ? t('recipe.stepTypeSources.schema') : t('recipe.stepTypeSources.fallback') }}</dd>
                </div>
              </dl>
            </div>
          </div>
        </div>
      </section>

      <section v-if="showMaterialsSection" class="rounded-lg border border-gray-200 bg-white shadow" aria-labelledby="materialsHeading">
        <header class="flex flex-col gap-3 border-b p-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 id="materialsHeading" class="text-lg font-semibold text-gray-900">{{ t('recipe.schemaSections.materials') }}</h2>
            <p class="text-sm text-gray-500">{{ t('recipe.edit.materialsStoredIn') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-3">
            <span v-if="!isSectionExpanded('materials')" class="text-xs text-amber-700">{{ t('recipe.edit.sectionFolded') }}</span>
            <label class="inline-flex items-center gap-2 text-sm text-gray-600">
              <span>{{ t('recipe.edit.sectionDisplay') }}</span>
              <button
                type="button"
                role="switch"
                class="relative inline-flex h-6 w-11 items-center rounded-full transition"
                :aria-checked="isSectionExpanded('materials')"
                :title="isSectionExpanded('materials') ? t('recipe.edit.hideSection') : t('recipe.edit.showSection')"
                :class="isSectionExpanded('materials') ? 'bg-blue-600' : 'bg-gray-300'"
                @click="toggleSectionExpanded('materials')"
              >
                <span class="inline-block h-5 w-5 transform rounded-full bg-white transition" :class="isSectionExpanded('materials') ? 'translate-x-5' : 'translate-x-1'" />
              </button>
              <span class="min-w-[2.5rem] text-xs font-medium">{{ isSectionExpanded('materials') ? t('recipe.edit.sectionOn') : t('recipe.edit.sectionOff') }}</span>
            </label>
            <button v-if="isSectionExpanded('materials')" type="button" class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" @click="openMaterialCreate(false)">{{ t('recipe.edit.addMaterial') }}</button>
          </div>
        </header>
        <div v-show="isSectionExpanded('materials')" class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
              <tr>
                <th class="px-3 py-2">{{ t('recipe.edit.group') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.materialColumn') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.materialRole') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.quantity') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.uomCode') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.basis') }}</th>
                <th class="px-3 py-2">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="row in materialRows" :key="row.key" class="hover:bg-gray-50">
                <td class="px-3 py-2">{{ formatMaterialSection(row.section) }}</td>
                <td class="px-3 py-2">
                  <div class="font-medium text-gray-900">{{ row.item.material_name || row.item.material_code || row.item.material_key }}</div>
                  <div class="font-mono text-xs text-gray-500">{{ row.item.material_code || row.item.material_spec_code || row.item.material_key }}</div>
                </td>
                <td class="px-3 py-2">{{ row.item.material_role }}</td>
                <td class="px-3 py-2">{{ row.item.qty ?? t('common.none') }}</td>
                <td class="px-3 py-2">{{ row.item.uom_code || t('common.none') }}</td>
                <td class="px-3 py-2">{{ row.item.basis ? formatBasis(row.item.basis) : t('common.none') }}</td>
                <td class="px-3 py-2 space-x-2">
                  <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" @click="openMaterialEdit(row.section, row.index)">{{ t('common.edit') }}</button>
                  <button class="rounded bg-red-600 px-2 py-1 text-xs text-white hover:bg-red-700" @click="deleteMaterial(row.section, row.index)">{{ t('common.delete') }}</button>
                </td>
              </tr>
              <tr v-if="materialRows.length === 0">
                <td colspan="7" class="px-3 py-6 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section v-if="showOutputsSection" class="rounded-lg border border-gray-200 bg-white shadow" aria-labelledby="outputsHeading">
        <header class="flex flex-col gap-3 border-b p-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 id="outputsHeading" class="text-lg font-semibold text-gray-900">{{ t('recipe.schemaSections.outputs') }}</h2>
            <p class="text-sm text-gray-500">{{ t('recipe.edit.outputsStoredIn') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-3">
            <span v-if="!isSectionExpanded('outputs')" class="text-xs text-amber-700">{{ t('recipe.edit.sectionFolded') }}</span>
            <label class="inline-flex items-center gap-2 text-sm text-gray-600">
              <span>{{ t('recipe.edit.sectionDisplay') }}</span>
              <button
                type="button"
                role="switch"
                class="relative inline-flex h-6 w-11 items-center rounded-full transition"
                :aria-checked="isSectionExpanded('outputs')"
                :title="isSectionExpanded('outputs') ? t('recipe.edit.hideSection') : t('recipe.edit.showSection')"
                :class="isSectionExpanded('outputs') ? 'bg-blue-600' : 'bg-gray-300'"
                @click="toggleSectionExpanded('outputs')"
              >
                <span class="inline-block h-5 w-5 transform rounded-full bg-white transition" :class="isSectionExpanded('outputs') ? 'translate-x-5' : 'translate-x-1'" />
              </button>
              <span class="min-w-[2.5rem] text-xs font-medium">{{ isSectionExpanded('outputs') ? t('recipe.edit.sectionOn') : t('recipe.edit.sectionOff') }}</span>
            </label>
          </div>
        </header>
        <div v-show="isSectionExpanded('outputs')" class="grid grid-cols-1 gap-4 p-4 xl:grid-cols-3">
          <div v-for="group in outputSectionRows" :key="group.key" class="rounded-lg border border-gray-200">
            <div class="flex items-center justify-between border-b px-4 py-3">
              <h3 class="font-medium text-gray-900">{{ group.label }}</h3>
              <button class="rounded bg-blue-600 px-2 py-1 text-xs text-white hover:bg-blue-700" @click="openOutputCreate(group.section)">{{ t('recipe.edit.addOutput') }}</button>
            </div>
            <div class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200 text-sm">
                <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
                  <tr>
                    <th class="px-3 py-2">{{ t('recipe.edit.outputCode') }}</th>
                    <th class="px-3 py-2">{{ t('recipe.edit.outputName') }}</th>
                    <th class="px-3 py-2">{{ t('recipe.edit.quantity') }}</th>
                    <th class="px-3 py-2">{{ t('recipe.edit.uomCode') }}</th>
                    <th class="px-3 py-2">{{ t('common.actions') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="(row, index) in group.rows" :key="`${group.key}-${row.output_code}-${index}`">
                    <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.output_code }}</td>
                    <td class="px-3 py-2">{{ row.output_name }}</td>
                    <td class="px-3 py-2">{{ row.qty }}</td>
                    <td class="px-3 py-2">{{ row.uom_code }}</td>
                    <td class="px-3 py-2 space-x-2">
                      <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" @click="openOutputEdit(group.section, index)">{{ t('common.edit') }}</button>
                      <button class="rounded bg-red-600 px-2 py-1 text-xs text-white hover:bg-red-700" @click="deleteOutput(group.section, index)">{{ t('common.delete') }}</button>
                    </td>
                  </tr>
                  <tr v-if="group.rows.length === 0">
                    <td colspan="5" class="px-3 py-4 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </section>

      <section v-if="showEquipmentSection" class="rounded-lg border border-gray-200 bg-white shadow" aria-labelledby="equipmentHeading">
        <header class="flex flex-col gap-3 border-b p-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 id="equipmentHeading" class="text-lg font-semibold text-gray-900">{{ t('recipe.schemaSections.equipment') }}</h2>
            <p class="text-sm text-gray-500">{{ t('recipe.edit.equipmentStoredIn') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-3">
            <span v-if="!isSectionExpanded('equipment')" class="text-xs text-amber-700">{{ t('recipe.edit.sectionFolded') }}</span>
            <label class="inline-flex items-center gap-2 text-sm text-gray-600">
              <span>{{ t('recipe.edit.sectionDisplay') }}</span>
              <button
                type="button"
                role="switch"
                class="relative inline-flex h-6 w-11 items-center rounded-full transition"
                :aria-checked="isSectionExpanded('equipment')"
                :title="isSectionExpanded('equipment') ? t('recipe.edit.hideSection') : t('recipe.edit.showSection')"
                :class="isSectionExpanded('equipment') ? 'bg-blue-600' : 'bg-gray-300'"
                @click="toggleSectionExpanded('equipment')"
              >
                <span class="inline-block h-5 w-5 transform rounded-full bg-white transition" :class="isSectionExpanded('equipment') ? 'translate-x-5' : 'translate-x-1'" />
              </button>
              <span class="min-w-[2.5rem] text-xs font-medium">{{ isSectionExpanded('equipment') ? t('recipe.edit.sectionOn') : t('recipe.edit.sectionOff') }}</span>
            </label>
            <button v-if="isSectionExpanded('equipment')" type="button" class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" @click="openEquipmentCreate">{{ t('recipe.edit.addEquipmentRequirement') }}</button>
          </div>
        </header>
        <div v-show="isSectionExpanded('equipment')" class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
              <tr>
                <th class="px-3 py-2">{{ t('recipe.edit.equipmentType') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.equipmentTemplate') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.quantity') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.notes') }}</th>
                <th class="px-3 py-2">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="(row, index) in equipmentRequirements" :key="`${row.equipment_type_code}-${index}`">
                <td class="px-3 py-2">{{ row.equipment_type_code }}</td>
                <td class="px-3 py-2">{{ row.equipment_template_code || t('common.none') }}</td>
                <td class="px-3 py-2">{{ row.quantity ?? 1 }}</td>
                <td class="px-3 py-2">{{ row.notes || t('common.none') }}</td>
                <td class="px-3 py-2 space-x-2">
                  <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" @click="openEquipmentEdit(index)">{{ t('common.edit') }}</button>
                  <button class="rounded bg-red-600 px-2 py-1 text-xs text-white hover:bg-red-700" @click="deleteEquipmentRequirement(index)">{{ t('common.delete') }}</button>
                </td>
              </tr>
              <tr v-if="equipmentRequirements.length === 0">
                <td colspan="5" class="px-3 py-6 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section v-if="showFlowSection" class="rounded-lg border border-gray-200 bg-white shadow" aria-labelledby="stepsHeading">
        <header class="flex flex-col gap-3 border-b p-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 id="stepsHeading" class="text-lg font-semibold text-gray-900">{{ t('recipe.edit.flowTitle') }}</h2>
            <p class="text-sm text-gray-500">{{ t('recipe.edit.flowSubtitle') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-3">
            <span v-if="!isSectionExpanded('flow')" class="text-xs text-amber-700">{{ t('recipe.edit.sectionFolded') }}</span>
            <label class="inline-flex items-center gap-2 text-sm text-gray-600">
              <span>{{ t('recipe.edit.sectionDisplay') }}</span>
              <button
                type="button"
                role="switch"
                class="relative inline-flex h-6 w-11 items-center rounded-full transition"
                :aria-checked="isSectionExpanded('flow')"
                :title="isSectionExpanded('flow') ? t('recipe.edit.hideSection') : t('recipe.edit.showSection')"
                :class="isSectionExpanded('flow') ? 'bg-blue-600' : 'bg-gray-300'"
                @click="toggleSectionExpanded('flow')"
              >
                <span class="inline-block h-5 w-5 transform rounded-full bg-white transition" :class="isSectionExpanded('flow') ? 'translate-x-5' : 'translate-x-1'" />
              </button>
              <span class="min-w-[2.5rem] text-xs font-medium">{{ isSectionExpanded('flow') ? t('recipe.edit.sectionOn') : t('recipe.edit.sectionOff') }}</span>
            </label>
            <button v-if="isSectionExpanded('flow')" type="button" class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" @click="openStepCreate">{{ t('recipe.edit.addStep') }}</button>
          </div>
        </header>
        <div v-show="isSectionExpanded('flow')" class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
              <tr>
                <th class="px-3 py-2">#</th>
                <th class="px-3 py-2">{{ t('recipe.edit.stepCode') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.stepName') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.stepType') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.durationSec') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.parameters') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.qualityChecks') }}</th>
                <th class="px-3 py-2">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="(step, index) in flowSteps" :key="step.step_code || `step-${index}`" class="hover:bg-gray-50">
                <td class="px-3 py-2 font-mono text-xs text-gray-600">{{ step.step_no }}</td>
                <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ step.step_code }}</td>
                <td class="px-3 py-2">{{ step.step_name }}</td>
                <td class="px-3 py-2">{{ step.step_type ? formatStepType(step.step_type) : t('common.none') }}</td>
                <td class="px-3 py-2">{{ step.duration_sec ?? t('common.none') }}</td>
                <td class="px-3 py-2 text-xs text-gray-600">{{ step.parameters?.length ?? 0 }}</td>
                <td class="px-3 py-2 text-xs text-gray-600">{{ step.quality_checks?.length ?? 0 }}</td>
                <td class="px-3 py-2 space-x-2">
                  <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" @click="openStepEdit(index)">{{ t('common.edit') }}</button>
                  <button class="rounded bg-red-600 px-2 py-1 text-xs text-white hover:bg-red-700" @click="deleteStep(index)">{{ t('common.delete') }}</button>
                </td>
              </tr>
              <tr v-if="flowSteps.length === 0">
                <td colspan="8" class="px-3 py-6 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section v-if="showQualitySection" class="rounded-lg border border-gray-200 bg-white shadow" aria-labelledby="qualityHeading">
        <header class="flex flex-col gap-3 border-b p-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 id="qualityHeading" class="text-lg font-semibold text-gray-900">{{ t('recipe.schemaSections.quality') }}</h2>
            <p class="text-sm text-gray-500">{{ t('recipe.edit.qualityStoredIn') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-3">
            <span v-if="!isSectionExpanded('quality')" class="text-xs text-amber-700">{{ t('recipe.edit.sectionFolded') }}</span>
            <label class="inline-flex items-center gap-2 text-sm text-gray-600">
              <span>{{ t('recipe.edit.sectionDisplay') }}</span>
              <button
                type="button"
                role="switch"
                class="relative inline-flex h-6 w-11 items-center rounded-full transition"
                :aria-checked="isSectionExpanded('quality')"
                :title="isSectionExpanded('quality') ? t('recipe.edit.hideSection') : t('recipe.edit.showSection')"
                :class="isSectionExpanded('quality') ? 'bg-blue-600' : 'bg-gray-300'"
                @click="toggleSectionExpanded('quality')"
              >
                <span class="inline-block h-5 w-5 transform rounded-full bg-white transition" :class="isSectionExpanded('quality') ? 'translate-x-5' : 'translate-x-1'" />
              </button>
              <span class="min-w-[2.5rem] text-xs font-medium">{{ isSectionExpanded('quality') ? t('recipe.edit.sectionOn') : t('recipe.edit.sectionOff') }}</span>
            </label>
            <button v-if="isSectionExpanded('quality')" type="button" class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" @click="openGlobalQualityCreate">{{ t('recipe.edit.addGlobalCheck') }}</button>
          </div>
        </header>
        <div v-show="isSectionExpanded('quality')" class="grid grid-cols-1 gap-4 p-4 lg:grid-cols-[2fr_1fr]">
          <div class="overflow-x-auto rounded-lg border border-gray-200">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
                <tr>
                  <th class="px-3 py-2">{{ t('recipe.edit.code') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.name') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.frequency') }}</th>
                  <th class="px-3 py-2">{{ t('recipe.edit.requiredFlag') }}</th>
                  <th class="px-3 py-2">{{ t('common.actions') }}</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="(row, index) in globalQualityChecks" :key="`${row.check_code}-${index}`">
                  <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.check_code }}</td>
                  <td class="px-3 py-2">{{ row.check_name || qualityCheckMap.get(row.check_code)?.check_name || t('common.none') }}</td>
                  <td class="px-3 py-2">{{ row.frequency || t('common.none') }}</td>
                  <td class="px-3 py-2">{{ row.required ? t('common.yes') : t('common.no') }}</td>
                  <td class="px-3 py-2 space-x-2">
                    <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" @click="openGlobalQualityEdit(index)">{{ t('common.edit') }}</button>
                    <button class="rounded bg-red-600 px-2 py-1 text-xs text-white hover:bg-red-700" @click="deleteGlobalQualityCheck(index)">{{ t('common.delete') }}</button>
                  </td>
                </tr>
                <tr v-if="globalQualityChecks.length === 0">
                  <td colspan="5" class="px-3 py-6 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="rounded-lg border border-gray-200 p-4">
            <label class="mb-2 block text-sm font-medium text-gray-700">{{ t('recipe.edit.releaseCriteria') }}</label>
            <textarea v-model="releaseCriteriaText" rows="10" class="w-full rounded border px-3 py-2 font-mono text-xs"></textarea>
            <div class="mt-3 flex justify-end">
              <button class="rounded border px-3 py-2 text-sm hover:bg-gray-100" @click="applyReleaseCriteria">{{ t('recipe.edit.applyReleaseCriteria') }}</button>
            </div>
          </div>
        </div>
      </section>

      <section v-if="showDocumentsSection" class="rounded-lg border border-gray-200 bg-white shadow" aria-labelledby="documentsHeading">
        <header class="flex flex-col gap-3 border-b p-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h2 id="documentsHeading" class="text-lg font-semibold text-gray-900">{{ t('recipe.schemaSections.documents') }}</h2>
            <p class="text-sm text-gray-500">{{ t('recipe.edit.documentsStoredIn') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-3">
            <span v-if="!isSectionExpanded('documents')" class="text-xs text-amber-700">{{ t('recipe.edit.sectionFolded') }}</span>
            <label class="inline-flex items-center gap-2 text-sm text-gray-600">
              <span>{{ t('recipe.edit.sectionDisplay') }}</span>
              <button
                type="button"
                role="switch"
                class="relative inline-flex h-6 w-11 items-center rounded-full transition"
                :aria-checked="isSectionExpanded('documents')"
                :title="isSectionExpanded('documents') ? t('recipe.edit.hideSection') : t('recipe.edit.showSection')"
                :class="isSectionExpanded('documents') ? 'bg-blue-600' : 'bg-gray-300'"
                @click="toggleSectionExpanded('documents')"
              >
                <span class="inline-block h-5 w-5 transform rounded-full bg-white transition" :class="isSectionExpanded('documents') ? 'translate-x-5' : 'translate-x-1'" />
              </button>
              <span class="min-w-[2.5rem] text-xs font-medium">{{ isSectionExpanded('documents') ? t('recipe.edit.sectionOn') : t('recipe.edit.sectionOff') }}</span>
            </label>
            <button v-if="isSectionExpanded('documents')" type="button" class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" @click="openDocumentCreate">{{ t('recipe.edit.addDocument') }}</button>
          </div>
        </header>
        <div v-show="isSectionExpanded('documents')" class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200 text-sm">
            <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
              <tr>
                <th class="px-3 py-2">{{ t('recipe.edit.documentCode') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.documentType') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.documentTitle') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.revision') }}</th>
                <th class="px-3 py-2">{{ t('recipe.edit.requiredFlag') }}</th>
                <th class="px-3 py-2">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100">
              <tr v-for="(row, index) in documentRows" :key="`${row.doc_code}-${index}`">
                <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ row.doc_code }}</td>
                <td class="px-3 py-2">{{ row.doc_type }}</td>
                <td class="px-3 py-2">{{ row.title || t('common.none') }}</td>
                <td class="px-3 py-2">{{ row.revision || t('common.none') }}</td>
                <td class="px-3 py-2">{{ row.required ? t('common.yes') : t('common.no') }}</td>
                <td class="px-3 py-2 space-x-2">
                  <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" @click="openDocumentEdit(index)">{{ t('common.edit') }}</button>
                  <button class="rounded bg-red-600 px-2 py-1 text-xs text-white hover:bg-red-700" @click="deleteDocument(index)">{{ t('common.delete') }}</button>
                </td>
              </tr>
              <tr v-if="documentRows.length === 0">
                <td colspan="6" class="px-3 py-6 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>
    </div>

    <div v-if="showMaterialModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-3xl rounded-xl border border-gray-200 bg-white shadow-lg">
        <header class="border-b px-4 py-3">
          <h3 class="font-semibold text-gray-900">{{ materialEditIndex === null ? t('recipe.edit.addMaterial') : t('recipe.edit.editMaterial') }}</h3>
        </header>
        <section class="space-y-4 p-4">
          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.group') }}</label>
              <select v-model="materialForm.section" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="required">{{ t('recipe.materialSections.required') }}</option>
                <option value="optional">{{ t('recipe.materialSections.optional') }}</option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.materialColumn') }}<span class="text-red-600">*</span></label>
              <select v-model="materialForm.material_id" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="">{{ t('recipe.edit.selectMaterialPlaceholder') }}</option>
                <option v-for="material in materialOptions" :key="material.id" :value="material.id">
                  {{ material.material_code }} — {{ material.material_name }}
                </option>
              </select>
              <p v-if="materialErrors.material_id" class="mt-1 text-xs text-red-600">{{ materialErrors.material_id }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.materialRole') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="materialForm.material_role" class="h-[40px] w-full rounded border px-3" />
              <p v-if="materialErrors.material_role" class="mt-1 text-xs text-red-600">{{ materialErrors.material_role }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.quantity') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="materialForm.qty" type="number" min="0" step="0.001" class="h-[40px] w-full rounded border px-3" />
              <p v-if="materialErrors.qty" class="mt-1 text-xs text-red-600">{{ materialErrors.qty }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.uomCode') }}<span class="text-red-600">*</span></label>
              <select v-model="materialForm.uom_code" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="">{{ t('recipe.edit.selectUom') }}</option>
                <option v-for="uom in uoms" :key="uom.id" :value="uom.code">{{ uom.code }} — {{ uom.name || uom.code }}</option>
              </select>
              <p v-if="materialErrors.uom_code" class="mt-1 text-xs text-red-600">{{ materialErrors.uom_code }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.basis') }}</label>
              <select v-model="materialForm.basis" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="per_base">{{ t('recipe.basis.perBase') }}</option>
                <option value="percent_of_base">{{ t('recipe.basis.percentOfBase') }}</option>
                <option value="fixed_per_batch">{{ t('recipe.basis.fixedPerBatch') }}</option>
                <option value="by_formula">{{ t('recipe.basis.byFormula') }}</option>
              </select>
            </div>
            <div class="md:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.notes') }}</label>
              <textarea v-model.trim="materialForm.notes" rows="3" class="w-full rounded border px-3 py-2"></textarea>
            </div>
          </div>
        </section>
        <footer class="flex items-center justify-end gap-2 border-t px-4 py-3">
          <button class="rounded border px-3 py-2 hover:bg-gray-100" @click="closeMaterialModal">{{ t('common.cancel') }}</button>
          <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" @click="saveMaterial">{{ t('common.save') }}</button>
        </footer>
      </div>
    </div>

    <div v-if="showOutputModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-3xl rounded-xl border border-gray-200 bg-white shadow-lg">
        <header class="border-b px-4 py-3">
          <h3 class="font-semibold text-gray-900">{{ outputEditIndex === null ? t('recipe.edit.addOutput') : t('recipe.edit.editOutput') }}</h3>
        </header>
        <section class="space-y-4 p-4">
          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.outputCategory') }}</label>
              <select v-model="outputForm.section" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="primary">{{ t('recipe.edit.primaryOutputs') }}</option>
                <option value="co_products">{{ t('recipe.edit.coProductOutputs') }}</option>
                <option value="waste">{{ t('recipe.edit.wasteOutputs') }}</option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.outputType') }}</label>
              <select v-model="outputForm.output_type" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="primary">{{ t('recipe.edit.outputTypePrimary') }}</option>
                <option value="intermediate">{{ t('recipe.edit.outputTypeIntermediate') }}</option>
                <option value="co_product">{{ t('recipe.edit.outputTypeCoProduct') }}</option>
                <option value="waste">{{ t('recipe.edit.outputTypeWaste') }}</option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.outputCode') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="outputForm.output_code" class="h-[40px] w-full rounded border px-3 font-mono text-sm" />
              <p v-if="outputErrors.output_code" class="mt-1 text-xs text-red-600">{{ outputErrors.output_code }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.outputName') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="outputForm.output_name" class="h-[40px] w-full rounded border px-3" />
              <p v-if="outputErrors.output_name" class="mt-1 text-xs text-red-600">{{ outputErrors.output_name }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.quantity') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="outputForm.qty" type="number" min="0" step="0.001" class="h-[40px] w-full rounded border px-3" />
              <p v-if="outputErrors.qty" class="mt-1 text-xs text-red-600">{{ outputErrors.qty }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.uomCode') }}<span class="text-red-600">*</span></label>
              <select v-model="outputForm.uom_code" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="">{{ t('recipe.edit.selectUom') }}</option>
                <option v-for="uom in uoms" :key="uom.id" :value="uom.code">{{ uom.code }} — {{ uom.name || uom.code }}</option>
              </select>
              <p v-if="outputErrors.uom_code" class="mt-1 text-xs text-red-600">{{ outputErrors.uom_code }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.basis') }}</label>
              <select v-model="outputForm.basis" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="per_base">{{ t('recipe.basis.perBase') }}</option>
                <option value="fixed_per_batch">{{ t('recipe.edit.outputBasisFixedPerBatch') }}</option>
                <option value="yield_based">{{ t('recipe.edit.outputBasisYieldBased') }}</option>
              </select>
            </div>
            <div class="md:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.notes') }}</label>
              <textarea v-model.trim="outputForm.notes" rows="3" class="w-full rounded border px-3 py-2"></textarea>
            </div>
          </div>
        </section>
        <footer class="flex items-center justify-end gap-2 border-t px-4 py-3">
          <button class="rounded border px-3 py-2 hover:bg-gray-100" @click="closeOutputModal">{{ t('common.cancel') }}</button>
          <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" @click="saveOutput">{{ t('common.save') }}</button>
        </footer>
      </div>
    </div>

    <div v-if="showEquipmentModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-3xl rounded-xl border border-gray-200 bg-white shadow-lg">
        <header class="border-b px-4 py-3">
          <h3 class="font-semibold text-gray-900">{{ equipmentEditIndex === null ? t('recipe.edit.addEquipmentRequirement') : t('recipe.edit.editEquipmentRequirement') }}</h3>
        </header>
        <section class="space-y-4 p-4">
          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.equipmentType') }}<span class="text-red-600">*</span></label>
              <select v-model="equipmentForm.equipment_type_code" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="">{{ t('recipe.edit.selectEquipmentType') }}</option>
                <option v-for="type in equipmentTypes" :key="type.type_id" :value="type.code">{{ type.code }} — {{ type.name }}</option>
              </select>
              <p v-if="equipmentErrors.equipment_type_code" class="mt-1 text-xs text-red-600">{{ equipmentErrors.equipment_type_code }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.equipmentTemplate') }}</label>
              <select v-model="equipmentForm.equipment_template_code" class="h-[40px] w-full rounded border bg-white px-3">
                <option value="">{{ t('common.none') }}</option>
                <option
                  v-for="template in equipmentTemplates.filter((row) => !equipmentForm.equipment_type_code || (row.equipment_type_id ? equipmentTypeMap.get(row.equipment_type_id)?.code : undefined) === equipmentForm.equipment_type_code)"
                  :key="template.id"
                  :value="template.template_code"
                >
                  {{ template.template_code }} — {{ template.template_name }}
                </option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.quantity') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="equipmentForm.quantity" type="number" min="1" step="1" class="h-[40px] w-full rounded border px-3" />
              <p v-if="equipmentErrors.quantity" class="mt-1 text-xs text-red-600">{{ equipmentErrors.quantity }}</p>
            </div>
            <div class="md:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.capabilityRules') }}</label>
              <textarea v-model="equipmentForm.capability_rules" rows="5" class="w-full rounded border px-3 py-2 font-mono text-xs"></textarea>
              <p v-if="equipmentErrors.capability_rules" class="mt-1 text-xs text-red-600">{{ equipmentErrors.capability_rules }}</p>
            </div>
            <div class="md:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.notes') }}</label>
              <textarea v-model.trim="equipmentForm.notes" rows="3" class="w-full rounded border px-3 py-2"></textarea>
            </div>
          </div>
        </section>
        <footer class="flex items-center justify-end gap-2 border-t px-4 py-3">
          <button class="rounded border px-3 py-2 hover:bg-gray-100" @click="closeEquipmentModal">{{ t('common.cancel') }}</button>
          <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" @click="saveEquipmentRequirement">{{ t('common.save') }}</button>
        </footer>
      </div>
    </div>

    <div v-if="showStepModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-5xl rounded-xl border border-gray-200 bg-white shadow-lg">
        <header class="border-b px-4 py-3">
          <h3 class="font-semibold text-gray-900">{{ stepEditIndex === null ? t('recipe.edit.addStep') : t('recipe.edit.editStep') }}</h3>
        </header>
        <section class="space-y-4 p-4">
          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.stepNo') }}<span class="text-red-600">*</span></label>
              <input v-model.number="stepForm.step_no" type="number" min="1" class="h-[40px] w-full rounded border px-3" />
              <p v-if="stepErrors.step_no" class="mt-1 text-xs text-red-600">{{ stepErrors.step_no }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.stepType') }}<span class="text-red-600">*</span></label>
              <select v-model="stepForm.step_type" class="h-[40px] w-full rounded border bg-white px-3">
                <option v-for="option in stepTypeOptions" :key="option" :value="option">{{ formatStepType(option) }}</option>
              </select>
              <p class="mt-1 text-xs text-gray-500">{{ usesSchemaStepOptions ? t('recipe.edit.loadedFromSchema') : t('recipe.edit.usingFallbackOptions') }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.stepCode') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="stepForm.step_code" class="h-[40px] w-full rounded border px-3 font-mono text-sm" />
              <p v-if="stepErrors.step_code" class="mt-1 text-xs text-red-600">{{ stepErrors.step_code }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.stepName') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="stepForm.step_name" class="h-[40px] w-full rounded border px-3" />
              <p v-if="stepErrors.step_name" class="mt-1 text-xs text-red-600">{{ stepErrors.step_name }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.stepTemplateCode') }}</label>
              <input v-model.trim="stepForm.step_template_code" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.durationSec') }}</label>
              <input v-model.trim="stepForm.duration_sec" type="number" min="0" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div class="md:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.instructions') }}</label>
              <textarea v-model.trim="stepForm.instructions" rows="3" class="w-full rounded border px-3 py-2"></textarea>
            </div>
          </div>

          <div class="grid grid-cols-1 gap-4 lg:grid-cols-2">
            <div>
              <div class="mb-2 flex items-center justify-between">
                <label class="block text-sm text-gray-600">{{ t('recipe.edit.parameters') }}</label>
                <button class="rounded border border-dashed px-3 py-1 text-sm hover:bg-gray-50" @click.prevent="addParameterRow">{{ t('recipe.edit.addTargetParam') }}</button>
              </div>
              <div class="overflow-x-auto rounded border border-gray-200">
                <table class="min-w-full divide-y divide-gray-200 text-sm">
                  <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
                    <tr>
                      <th class="px-3 py-2">{{ t('recipe.edit.code') }}</th>
                      <th class="px-3 py-2">{{ t('recipe.edit.target') }}</th>
                      <th class="px-3 py-2">{{ t('recipe.edit.unit') }}</th>
                      <th class="px-3 py-2">{{ t('common.actions') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="(row, index) in parameterRows" :key="row.key">
                      <td class="px-3 py-2"><input v-model.trim="row.parameter_code" class="w-full rounded border px-2 py-1" /></td>
                      <td class="px-3 py-2"><input v-model.trim="row.target" class="w-full rounded border px-2 py-1" /></td>
                      <td class="px-3 py-2"><input v-model.trim="row.uom_code" class="w-full rounded border px-2 py-1" /></td>
                      <td class="px-3 py-2 text-right">
                        <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" @click.prevent="removeParameterRow(index)">{{ t('common.delete') }}</button>
                      </td>
                    </tr>
                    <tr v-if="parameterRows.length === 0">
                      <td colspan="4" class="px-3 py-4 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>

            <div>
              <div class="mb-2 flex items-center justify-between">
                <label class="block text-sm text-gray-600">{{ t('recipe.edit.qualityChecks') }}</label>
                <button class="rounded border border-dashed px-3 py-1 text-sm hover:bg-gray-50" @click.prevent="addQualityRow">{{ t('recipe.edit.addQualityCheck') }}</button>
              </div>
              <div class="overflow-x-auto rounded border border-gray-200">
                <table class="min-w-full divide-y divide-gray-200 text-sm">
                  <thead class="bg-gray-50 text-left text-xs uppercase text-gray-500">
                    <tr>
                      <th class="px-3 py-2">{{ t('recipe.edit.code') }}</th>
                      <th class="px-3 py-2">{{ t('recipe.edit.frequency') }}</th>
                      <th class="px-3 py-2">{{ t('common.actions') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="(row, index) in qualityRows" :key="row.key">
                      <td class="px-3 py-2"><input v-model.trim="row.check_code" class="w-full rounded border px-2 py-1" /></td>
                      <td class="px-3 py-2"><input v-model.trim="row.frequency" class="w-full rounded border px-2 py-1" /></td>
                      <td class="px-3 py-2 text-right">
                        <button class="rounded border px-2 py-1 text-xs hover:bg-gray-100" @click.prevent="removeQualityRow(index)">{{ t('common.delete') }}</button>
                      </td>
                    </tr>
                    <tr v-if="qualityRows.length === 0">
                      <td colspan="3" class="px-3 py-4 text-center text-sm text-gray-500">{{ t('common.noData') }}</td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </div>

          <div>
            <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.notes') }}</label>
            <textarea v-model.trim="stepForm.notes" rows="3" class="w-full rounded border px-3 py-2"></textarea>
          </div>
        </section>
        <footer class="flex items-center justify-end gap-2 border-t px-4 py-3">
          <button class="rounded border px-3 py-2 hover:bg-gray-100" @click="closeStepModal">{{ t('common.cancel') }}</button>
          <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" @click="saveStep">{{ t('common.save') }}</button>
        </footer>
      </div>
    </div>

    <div v-if="showGlobalQualityModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-4xl rounded-xl border border-gray-200 bg-white shadow-lg">
        <header class="border-b px-4 py-3">
          <h3 class="font-semibold text-gray-900">{{ globalQualityEditIndex === null ? t('recipe.edit.addGlobalCheck') : t('recipe.edit.editGlobalCheck') }}</h3>
        </header>
        <section class="space-y-4 p-4">
          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.code') }}<span class="text-red-600">*</span></label>
              <select v-model="globalQualityForm.check_code" class="h-[40px] w-full rounded border bg-white px-3" @change="syncGlobalQualityName">
                <option value="">{{ t('recipe.edit.selectQualityCheck') }}</option>
                <option v-for="check in qualityCheckOptions" :key="check.id" :value="check.check_code">{{ check.check_code }} — {{ check.check_name }}</option>
              </select>
              <p v-if="globalQualityErrors.check_code" class="mt-1 text-xs text-red-600">{{ globalQualityErrors.check_code }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.name') }}</label>
              <input v-model.trim="globalQualityForm.check_name" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.samplingPoint') }}</label>
              <input v-model.trim="globalQualityForm.sampling_point" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.frequency') }}</label>
              <input v-model.trim="globalQualityForm.frequency" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div class="flex items-center gap-2">
              <input id="globalCheckRequired" v-model="globalQualityForm.required" type="checkbox" class="h-4 w-4" />
              <label for="globalCheckRequired" class="text-sm text-gray-700">{{ t('recipe.edit.requiredFlag') }}</label>
            </div>
            <div class="md:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.acceptanceCriteria') }}</label>
              <textarea v-model="globalQualityForm.acceptance_criteria" rows="5" class="w-full rounded border px-3 py-2 font-mono text-xs"></textarea>
              <p v-if="globalQualityErrors.acceptance_criteria" class="mt-1 text-xs text-red-600">{{ globalQualityErrors.acceptance_criteria }}</p>
            </div>
            <div class="md:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.notes') }}</label>
              <textarea v-model.trim="globalQualityForm.notes" rows="3" class="w-full rounded border px-3 py-2"></textarea>
            </div>
          </div>
        </section>
        <footer class="flex items-center justify-end gap-2 border-t px-4 py-3">
          <button class="rounded border px-3 py-2 hover:bg-gray-100" @click="closeGlobalQualityModal">{{ t('common.cancel') }}</button>
          <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" @click="saveGlobalQualityCheck">{{ t('common.save') }}</button>
        </footer>
      </div>
    </div>

    <div v-if="showDocumentModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-4xl rounded-xl border border-gray-200 bg-white shadow-lg">
        <header class="border-b px-4 py-3">
          <h3 class="font-semibold text-gray-900">{{ documentEditIndex === null ? t('recipe.edit.addDocument') : t('recipe.edit.editDocument') }}</h3>
        </header>
        <section class="space-y-4 p-4">
          <div class="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.documentCode') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="documentForm.doc_code" class="h-[40px] w-full rounded border px-3 font-mono text-sm" />
              <p v-if="documentErrors.doc_code" class="mt-1 text-xs text-red-600">{{ documentErrors.doc_code }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.documentType') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="documentForm.doc_type" class="h-[40px] w-full rounded border px-3" />
              <p v-if="documentErrors.doc_type" class="mt-1 text-xs text-red-600">{{ documentErrors.doc_type }}</p>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.documentTitle') }}</label>
              <input v-model.trim="documentForm.title" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.revision') }}</label>
              <input v-model.trim="documentForm.revision" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div class="md:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.url') }}</label>
              <input v-model.trim="documentForm.url" class="h-[40px] w-full rounded border px-3" />
            </div>
            <div class="flex items-center gap-2">
              <input id="documentRequired" v-model="documentForm.required" type="checkbox" class="h-4 w-4" />
              <label for="documentRequired" class="text-sm text-gray-700">{{ t('recipe.edit.requiredFlag') }}</label>
            </div>
            <div class="md:col-span-2">
              <label class="mb-1 block text-sm text-gray-600">{{ t('recipe.edit.notes') }}</label>
              <textarea v-model.trim="documentForm.notes" rows="3" class="w-full rounded border px-3 py-2"></textarea>
            </div>
          </div>
        </section>
        <footer class="flex items-center justify-end gap-2 border-t px-4 py-3">
          <button class="rounded border px-3 py-2 hover:bg-gray-100" @click="closeDocumentModal">{{ t('common.cancel') }}</button>
          <button class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700" @click="saveDocument">{{ t('common.save') }}</button>
        </footer>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

const DEFAULT_SCHEMA_KEY = 'recipe_body_schema_v1'
const RECIPE_STATUSES = ['active', 'inactive'] as const
const VERSION_STATUSES = ['draft', 'in_review', 'approved', 'obsolete', 'archived'] as const
const FALLBACK_STEP_TYPES = ['process', 'prep', 'transfer', 'inspection', 'packaging', 'other']

type JsonObject = Record<string, unknown>
type RecipeStatus = (typeof RECIPE_STATUSES)[number]
type VersionStatus = (typeof VERSION_STATUSES)[number]
type MaterialSection = 'required' | 'optional'
type OutputSection = 'primary' | 'co_products' | 'waste'

interface RecipeHeaderRow {
  id: string
  recipe_code: string
  recipe_name: string
  recipe_category: string | null
  industry_type: string | null
  status: RecipeStatus
  current_version_id: string | null
}

interface RecipeVersionRow {
  id: string
  recipe_id: string
  version_no: number
  version_label: string | null
  recipe_body_json: JsonObject
  resolved_reference_json: JsonObject
  schema_code: string | null
  template_code: string | null
  status: VersionStatus
  effective_from: string | null
  effective_to: string | null
  change_summary: string | null
  created_at: string | null
  updated_at: string | null
}

interface MaterialTypeRow {
  type_id: string
  code: string
  name: string
}

interface MaterialSpecRow {
  id: string
  material_type_id: string | null
  spec_code: string
  spec_name: string
}

interface MaterialMasterRow {
  id: string
  material_code: string
  material_name: string
  material_type_id: string | null
  material_spec_id: string | null
  base_uom_id: string | null
  status: RecipeStatus
}

interface UomRow {
  id: string
  code: string
  name: string | null
}

interface EquipmentTypeRow {
  type_id: string
  code: string
  name: string
}

interface EquipmentTemplateRow {
  id: string
  template_code: string
  template_name: string
  equipment_type_id: string | null
  status: RecipeStatus
}

interface QualityCheckMasterRow {
  id: string
  check_code: string
  check_name: string
  status: RecipeStatus
}

interface RecipeSchemaPayload {
  def_id: string | null
  def_key: string
  scope: string | null
  schema: JsonObject
}

interface RecipeMaterialRequirement {
  material_key: string
  material_name?: string
  material_role: string
  material_type_code?: string
  material_spec_code?: string
  material_code?: string
  qty: number
  uom_code: string
  basis?: string
  is_optional?: boolean
  notes?: string
}

interface RecipeOutputSpec {
  output_code: string
  output_name: string
  output_type: string
  qty: number
  uom_code: string
  basis?: string
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
  material_inputs?: JsonObject[]
  material_outputs?: JsonObject[]
  equipment_requirements?: JsonObject[]
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
    primary: RecipeOutputSpec[]
    co_products: RecipeOutputSpec[]
    waste: RecipeOutputSpec[]
  }
  materials: {
    required: RecipeMaterialRequirement[]
    optional: RecipeMaterialRequirement[]
  }
  equipment: {
    default_requirements: RecipeEquipmentRequirement[]
  }
  flow: {
    steps: RecipeFlowStep[]
  }
  quality: {
    global_checks: RecipeQualityCheck[]
    release_criteria: JsonObject
  }
  documents: RecipeDocumentRef[]
  [key: string]: unknown
}

interface RecipeDocumentRef {
  doc_code: string
  doc_type: string
  title?: string
  revision?: string
  url?: string
  required?: boolean
  notes?: string
}

interface MaterialRowState {
  key: string
  section: MaterialSection
  index: number
  item: RecipeMaterialRequirement
}

interface ParameterRowState {
  key: string
  parameter_code: string
  target: string
  uom_code: string
}

interface QualityRowState {
  key: string
  check_code: string
  frequency: string
}

type RecipeSectionKey = 'materials' | 'outputs' | 'equipment' | 'flow' | 'quality' | 'documents'

const route = useRoute()
const router = useRouter()
const { t } = useI18n()

const pageTitle = computed(() => t('recipe.edit.title'))
const recipeId = computed(() => (typeof route.params.recipeId === 'string' ? route.params.recipeId : ''))
const routeVersionId = computed(() => (typeof route.params.versionId === 'string' ? route.params.versionId : ''))

const loadingPage = ref(false)
const saving = ref(false)
const versioning = ref(false)
const schemaLoading = ref(false)
const schemaError = ref('')
const currentVersionId = ref('')

const recipeHeader = ref<RecipeHeaderRow | null>(null)
const recipeVersions = ref<RecipeVersionRow[]>([])
const activeVersion = ref<RecipeVersionRow | null>(null)
const recipeBody = ref<RecipeBody>(createDefaultRecipeBody(DEFAULT_SCHEMA_KEY, ''))

const materialTypes = ref<MaterialTypeRow[]>([])
const materialSpecs = ref<MaterialSpecRow[]>([])
const materialOptions = ref<MaterialMasterRow[]>([])
const equipmentTypes = ref<EquipmentTypeRow[]>([])
const equipmentTemplates = ref<EquipmentTemplateRow[]>([])
const qualityCheckOptions = ref<QualityCheckMasterRow[]>([])
const uoms = ref<UomRow[]>([])

const schemaMeta = reactive({
  def_id: '',
  def_key: DEFAULT_SCHEMA_KEY,
  scope: '',
})
const recipeSchema = ref<JsonObject | null>(null)
const sectionVisibility = reactive<Record<RecipeSectionKey, boolean>>({
  materials: true,
  outputs: true,
  equipment: true,
  flow: true,
  quality: true,
  documents: true,
})

const headerForm = reactive({
  recipe_code: '',
  recipe_name: '',
  recipe_category: '',
  industry_type: '',
  status: RECIPE_STATUSES[0] as RecipeStatus,
})

const versionForm = reactive({
  id: '',
  version_no: 1,
  version_label: '',
  schema_code: DEFAULT_SCHEMA_KEY,
  status: VERSION_STATUSES[0] as VersionStatus,
  effective_from: '',
  effective_to: '',
  change_summary: '',
})

const headerErrors = reactive<Record<string, string>>({})
const versionErrors = reactive<Record<string, string>>({})

const showMaterialModal = ref(false)
const materialEditIndex = ref<number | null>(null)
const materialForm = reactive({
  section: 'required' as MaterialSection,
  material_id: '',
  material_role: '',
  qty: '',
  uom_code: '',
  basis: 'per_base',
  notes: '',
})
const materialErrors = reactive<Record<string, string>>({})

const showOutputModal = ref(false)
const outputEditIndex = ref<number | null>(null)
const outputForm = reactive({
  section: 'primary' as OutputSection,
  output_code: '',
  output_name: '',
  output_type: 'primary',
  qty: '',
  uom_code: '',
  basis: 'per_base',
  notes: '',
})
const outputErrors = reactive<Record<string, string>>({})

const showEquipmentModal = ref(false)
const equipmentEditIndex = ref<number | null>(null)
const equipmentForm = reactive({
  equipment_type_code: '',
  equipment_template_code: '',
  quantity: '1',
  capability_rules: '{}',
  notes: '',
})
const equipmentErrors = reactive<Record<string, string>>({})

const showGlobalQualityModal = ref(false)
const globalQualityEditIndex = ref<number | null>(null)
const globalQualityForm = reactive({
  check_code: '',
  check_name: '',
  sampling_point: '',
  frequency: '',
  required: true,
  acceptance_criteria: '{}',
  notes: '',
})
const globalQualityErrors = reactive<Record<string, string>>({})

const showDocumentModal = ref(false)
const documentEditIndex = ref<number | null>(null)
const documentForm = reactive({
  doc_code: '',
  doc_type: '',
  title: '',
  revision: '',
  url: '',
  required: false,
  notes: '',
})
const documentErrors = reactive<Record<string, string>>({})

const showStepModal = ref(false)
const stepEditIndex = ref<number | null>(null)
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

let parameterRowCounter = 0
let qualityRowCounter = 0
const releaseCriteriaText = ref('{}')

const parameterRows = ref<ParameterRowState[]>([])
const qualityRows = ref<QualityRowState[]>([])

const mesClient = () => supabase.schema('mes')

const versionOptions = computed(() => [...recipeVersions.value].sort((a, b) => b.version_no - a.version_no))

const materialTypeMap = computed(() => {
  const map = new Map<string, MaterialTypeRow>()
  for (const row of materialTypes.value) {
    map.set(row.type_id, row)
  }
  return map
})

const materialSpecMap = computed(() => {
  const map = new Map<string, MaterialSpecRow>()
  for (const row of materialSpecs.value) {
    map.set(row.id, row)
  }
  return map
})

const materialMasterMap = computed(() => {
  const map = new Map<string, MaterialMasterRow>()
  for (const row of materialOptions.value) {
    map.set(row.id, row)
  }
  return map
})

const equipmentTypeMap = computed(() => {
  const map = new Map<string, EquipmentTypeRow>()
  for (const row of equipmentTypes.value) {
    map.set(row.type_id, row)
  }
  return map
})

const qualityCheckMap = computed(() => {
  const map = new Map<string, QualityCheckMasterRow>()
  for (const row of qualityCheckOptions.value) {
    map.set(row.check_code, row)
  }
  return map
})

const requiredMaterials = computed(() => recipeBody.value.materials.required)
const optionalMaterials = computed(() => recipeBody.value.materials.optional)
const primaryOutputs = computed(() => recipeBody.value.outputs.primary)
const coProductOutputs = computed(() => recipeBody.value.outputs.co_products)
const wasteOutputs = computed(() => recipeBody.value.outputs.waste)
const equipmentRequirements = computed(() => recipeBody.value.equipment.default_requirements)
const flowSteps = computed(() => recipeBody.value.flow.steps)
const globalQualityChecks = computed(() => recipeBody.value.quality.global_checks)
const documentRows = computed(() => recipeBody.value.documents)

const materialRows = computed(() => {
  const rows: MaterialRowState[] = []
  recipeBody.value.materials.required.forEach((item, index) => {
    rows.push({ key: `required-${index}`, section: 'required', index, item })
  })
  recipeBody.value.materials.optional.forEach((item, index) => {
    rows.push({ key: `optional-${index}`, section: 'optional', index, item })
  })
  return rows
})

const outputSectionRows = computed(() => [
  { key: 'primary', section: 'primary' as OutputSection, label: t('recipe.edit.primaryOutputs'), rows: primaryOutputs.value },
  { key: 'co_products', section: 'co_products' as OutputSection, label: t('recipe.edit.coProductOutputs'), rows: coProductOutputs.value },
  { key: 'waste', section: 'waste' as OutputSection, label: t('recipe.edit.wasteOutputs'), rows: wasteOutputs.value },
])

const activeSchemaKey = computed(() => versionForm.schema_code.trim() || DEFAULT_SCHEMA_KEY)
const isDefaultRecipeBodySchema = computed(() => activeSchemaKey.value === DEFAULT_SCHEMA_KEY)

const schemaStepTypes = computed(() => extractSchemaStepTypes(recipeSchema.value))
const usesSchemaStepOptions = computed(() => schemaStepTypes.value.length > 0)
const stepTypeOptions = computed(() => {
  const options = usesSchemaStepOptions.value ? [...schemaStepTypes.value] : [...FALLBACK_STEP_TYPES]
  if (stepForm.step_type && !options.includes(stepForm.step_type)) {
    options.unshift(stepForm.step_type)
  }
  return options
})

const showMaterialsSection = computed(() => !recipeSchema.value || schemaHasSection(recipeSchema.value, 'materials'))
const showOutputsSection = computed(() => isDefaultRecipeBodySchema.value || !recipeSchema.value || schemaHasSection(recipeSchema.value, 'outputs') || primaryOutputs.value.length > 0 || coProductOutputs.value.length > 0 || wasteOutputs.value.length > 0)
const showEquipmentSection = computed(() => isDefaultRecipeBodySchema.value || !recipeSchema.value || schemaHasSection(recipeSchema.value, 'equipment') || equipmentRequirements.value.length > 0)
const showFlowSection = computed(() => !recipeSchema.value || schemaHasSection(recipeSchema.value, 'flow'))
const showQualitySection = computed(() => isDefaultRecipeBodySchema.value || !recipeSchema.value || schemaHasSection(recipeSchema.value, 'quality') || globalQualityChecks.value.length > 0 || Object.keys(recipeBody.value.quality.release_criteria ?? {}).length > 0)
const showDocumentsSection = computed(() => isDefaultRecipeBodySchema.value || !recipeSchema.value || schemaHasSection(recipeSchema.value, 'documents') || documentRows.value.length > 0)
const schemaSectionBadges = computed(() => [
  { key: 'materials', label: formatSchemaSection('materials'), enabled: showMaterialsSection.value },
  { key: 'flow', label: formatSchemaSection('flow'), enabled: showFlowSection.value },
  { key: 'outputs', label: formatSchemaSection('outputs'), enabled: showOutputsSection.value },
  { key: 'equipment', label: formatSchemaSection('equipment'), enabled: showEquipmentSection.value },
  { key: 'quality', label: formatSchemaSection('quality'), enabled: showQualitySection.value },
  { key: 'documents', label: formatSchemaSection('documents'), enabled: showDocumentsSection.value },
])

function isSectionAvailable(section: RecipeSectionKey) {
  switch (section) {
    case 'materials':
      return showMaterialsSection.value
    case 'outputs':
      return showOutputsSection.value
    case 'equipment':
      return showEquipmentSection.value
    case 'flow':
      return showFlowSection.value
    case 'quality':
      return showQualitySection.value
    case 'documents':
      return showDocumentsSection.value
  }
}

function isSectionExpanded(section: RecipeSectionKey) {
  return isSectionAvailable(section) && sectionVisibility[section]
}

function toggleSectionExpanded(section: RecipeSectionKey) {
  if (!isSectionAvailable(section)) return
  sectionVisibility[section] = !sectionVisibility[section]
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
    equipment: {
      default_requirements: [],
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

function normalizeOutputSpec(value: unknown): RecipeOutputSpec | null {
  if (!isJsonObject(value)) return null
  const outputCode = typeof value.output_code === 'string' ? value.output_code : ''
  const outputName = typeof value.output_name === 'string' ? value.output_name : ''
  const outputType = typeof value.output_type === 'string' ? value.output_type : ''
  const qty = typeof value.qty === 'number' ? value.qty : Number(value.qty)
  const uomCode = typeof value.uom_code === 'string' ? value.uom_code : ''
  if (!outputCode || !outputName || !outputType || !Number.isFinite(qty) || !uomCode) return null
  return {
    output_code: outputCode,
    output_name: outputName,
    output_type: outputType,
    qty,
    uom_code: uomCode,
    basis: typeof value.basis === 'string' ? value.basis : undefined,
    notes: typeof value.notes === 'string' ? value.notes : undefined,
  }
}

function normalizeMaterialRequirement(value: unknown): RecipeMaterialRequirement | null {
  if (!isJsonObject(value)) return null
  const materialKey = typeof value.material_key === 'string' ? value.material_key : ''
  const materialRole = typeof value.material_role === 'string' ? value.material_role : ''
  const qty = typeof value.qty === 'number' ? value.qty : Number(value.qty)
  const uomCode = typeof value.uom_code === 'string' ? value.uom_code : ''
  if (!materialKey || !materialRole || !Number.isFinite(qty) || !uomCode) return null
  return {
    material_key: materialKey,
    material_name: typeof value.material_name === 'string' ? value.material_name : undefined,
    material_role: materialRole,
    material_type_code: typeof value.material_type_code === 'string' ? value.material_type_code : undefined,
    material_spec_code: typeof value.material_spec_code === 'string' ? value.material_spec_code : undefined,
    material_code: typeof value.material_code === 'string' ? value.material_code : undefined,
    qty,
    uom_code: uomCode,
    basis: typeof value.basis === 'string' ? value.basis : undefined,
    is_optional: typeof value.is_optional === 'boolean' ? value.is_optional : undefined,
    notes: typeof value.notes === 'string' ? value.notes : undefined,
  }
}

function normalizeEquipmentRequirement(value: unknown): RecipeEquipmentRequirement | null {
  if (!isJsonObject(value)) return null
  const equipmentTypeCode = typeof value.equipment_type_code === 'string' ? value.equipment_type_code : ''
  if (!equipmentTypeCode) return null
  const quantity = typeof value.quantity === 'number' ? value.quantity : Number(value.quantity)
  return {
    equipment_type_code: equipmentTypeCode,
    equipment_template_code: typeof value.equipment_template_code === 'string' ? value.equipment_template_code : undefined,
    quantity: Number.isFinite(quantity) && quantity > 0 ? Math.trunc(quantity) : undefined,
    capability_rules: isJsonObject(value.capability_rules) ? deepCloneJson(value.capability_rules) : undefined,
    notes: typeof value.notes === 'string' ? value.notes : undefined,
  }
}

function normalizeParameterTarget(value: unknown): RecipeParameterTarget | null {
  if (!isJsonObject(value) || typeof value.parameter_code !== 'string' || !value.parameter_code) return null
  return {
    parameter_code: value.parameter_code,
    parameter_name: typeof value.parameter_name === 'string' ? value.parameter_name : undefined,
    target: typeof value.target === 'number' || typeof value.target === 'string' ? value.target : undefined,
    min: typeof value.min === 'number' ? value.min : undefined,
    max: typeof value.max === 'number' ? value.max : undefined,
    setpoint: typeof value.setpoint === 'number' || typeof value.setpoint === 'string' ? value.setpoint : undefined,
    uom_code: typeof value.uom_code === 'string' ? value.uom_code : undefined,
    required: typeof value.required === 'boolean' ? value.required : undefined,
    sampling_frequency: typeof value.sampling_frequency === 'string' ? value.sampling_frequency : undefined,
    notes: typeof value.notes === 'string' ? value.notes : undefined,
  }
}

function normalizeQualityCheck(value: unknown): RecipeQualityCheck | null {
  if (!isJsonObject(value) || typeof value.check_code !== 'string' || !value.check_code) return null
  return {
    check_code: value.check_code,
    check_name: typeof value.check_name === 'string' ? value.check_name : undefined,
    sampling_point: typeof value.sampling_point === 'string' ? value.sampling_point : undefined,
    frequency: typeof value.frequency === 'string' ? value.frequency : undefined,
    required: typeof value.required === 'boolean' ? value.required : undefined,
    acceptance_criteria: isJsonObject(value.acceptance_criteria) ? value.acceptance_criteria : undefined,
    notes: typeof value.notes === 'string' ? value.notes : undefined,
  }
}

function normalizeFlowStep(value: unknown): RecipeFlowStep | null {
  if (!isJsonObject(value)) return null
  const stepCode = typeof value.step_code === 'string' ? value.step_code : ''
  const stepName = typeof value.step_name === 'string' ? value.step_name : ''
  const stepNo = typeof value.step_no === 'number' ? value.step_no : Number(value.step_no)
  if (!stepCode || !stepName || !Number.isInteger(stepNo) || stepNo < 1) return null

  return {
    step_code: stepCode,
    step_name: stepName,
    step_no: stepNo,
    step_type: typeof value.step_type === 'string' ? value.step_type : undefined,
    step_template_code: typeof value.step_template_code === 'string' ? value.step_template_code : undefined,
    instructions: typeof value.instructions === 'string' ? value.instructions : undefined,
    duration_sec: typeof value.duration_sec === 'number' ? value.duration_sec : undefined,
    material_inputs: Array.isArray(value.material_inputs) ? value.material_inputs.filter(isJsonObject) : [],
    material_outputs: Array.isArray(value.material_outputs) ? value.material_outputs.filter(isJsonObject) : [],
    equipment_requirements: Array.isArray(value.equipment_requirements) ? value.equipment_requirements.filter(isJsonObject) : [],
    parameters: Array.isArray(value.parameters) ? value.parameters.map(normalizeParameterTarget).filter((item): item is RecipeParameterTarget => Boolean(item)) : [],
    quality_checks: Array.isArray(value.quality_checks) ? value.quality_checks.map(normalizeQualityCheck).filter((item): item is RecipeQualityCheck => Boolean(item)) : [],
    hold_constraints: Array.isArray(value.hold_constraints) ? value.hold_constraints.filter(isJsonObject) : [],
    notes: typeof value.notes === 'string' ? value.notes : undefined,
  }
}

function normalizeDocumentRef(value: unknown): RecipeDocumentRef | null {
  if (!isJsonObject(value)) return null
  const docCode = typeof value.doc_code === 'string' ? value.doc_code : ''
  const docType = typeof value.doc_type === 'string' ? value.doc_type : ''
  if (!docCode || !docType) return null
  return {
    doc_code: docCode,
    doc_type: docType,
    title: typeof value.title === 'string' ? value.title : undefined,
    revision: typeof value.revision === 'string' ? value.revision : undefined,
    url: typeof value.url === 'string' ? value.url : undefined,
    required: typeof value.required === 'boolean' ? value.required : undefined,
    notes: typeof value.notes === 'string' ? value.notes : undefined,
  }
}

function normalizeRecipeBody(raw: unknown, industryType: string, schemaCode: string): RecipeBody {
  const base = isJsonObject(raw) ? raw : {}
  const normalized = createDefaultRecipeBody(schemaCode, industryType)

  normalized.schema_version = typeof base.schema_version === 'string' ? base.schema_version : normalized.schema_version
  normalized.recipe_info = isJsonObject(base.recipe_info) ? deepCloneJson(base.recipe_info) : normalized.recipe_info
  normalized.base = isJsonObject(base.base) ? deepCloneJson(base.base) : normalized.base

  const outputs = isJsonObject(base.outputs) ? base.outputs : {}
  const primaryOutputs = Array.isArray(outputs.primary)
    ? outputs.primary.map(normalizeOutputSpec).filter((item): item is RecipeOutputSpec => Boolean(item))
    : []
  const coProductOutputs = Array.isArray(outputs.co_products)
    ? outputs.co_products.map(normalizeOutputSpec).filter((item): item is RecipeOutputSpec => Boolean(item))
    : []
  const wasteOutputs = Array.isArray(outputs.waste)
    ? outputs.waste.map(normalizeOutputSpec).filter((item): item is RecipeOutputSpec => Boolean(item))
    : []

  const materials = isJsonObject(base.materials) ? base.materials : {}
  const required = Array.isArray(materials.required)
    ? materials.required.map(normalizeMaterialRequirement).filter((item): item is RecipeMaterialRequirement => Boolean(item))
    : []
  const optional = Array.isArray(materials.optional)
    ? materials.optional.map(normalizeMaterialRequirement).filter((item): item is RecipeMaterialRequirement => Boolean(item))
    : []

  const equipment = isJsonObject(base.equipment) ? base.equipment : {}
  const defaultEquipmentRequirements = Array.isArray(equipment.default_requirements)
    ? equipment.default_requirements.map(normalizeEquipmentRequirement).filter((item): item is RecipeEquipmentRequirement => Boolean(item))
    : []

  const flow = isJsonObject(base.flow) ? base.flow : {}
  const steps = Array.isArray(flow.steps)
    ? flow.steps.map(normalizeFlowStep).filter((item): item is RecipeFlowStep => Boolean(item))
    : []

  const quality = isJsonObject(base.quality) ? base.quality : {}
  const globalChecks = Array.isArray(quality.global_checks)
    ? quality.global_checks.map(normalizeQualityCheck).filter((item): item is RecipeQualityCheck => Boolean(item))
    : []
  const releaseCriteria = isJsonObject(quality.release_criteria) ? deepCloneJson(quality.release_criteria) : {}

  const documents = Array.isArray(base.documents)
    ? base.documents.map(normalizeDocumentRef).filter((item): item is RecipeDocumentRef => Boolean(item))
    : []

  return {
    ...deepCloneJson(base),
    schema_version: normalized.schema_version,
    recipe_info: normalized.recipe_info,
    base: normalized.base,
    outputs: {
      primary: primaryOutputs,
      co_products: coProductOutputs,
      waste: wasteOutputs,
    },
    materials: {
      required,
      optional,
    },
    equipment: {
      default_requirements: defaultEquipmentRequirements,
    },
    flow: {
      steps,
    },
    quality: {
      global_checks: globalChecks,
      release_criteria: releaseCriteria,
    },
    documents,
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

function formatRecipeStatus(value: RecipeStatus) {
  return translateEnum('recipe.statuses', value)
}

function formatVersionStatus(value: VersionStatus) {
  return translateEnum('recipe.versionStatuses', value)
}

function formatMaterialSection(value: MaterialSection) {
  return translateEnum('recipe.materialSections', value)
}

function formatBasis(value: string) {
  return translateEnum('recipe.basis', value)
}

function formatStepType(value: string) {
  return translateEnum('recipe.stepTypes', value)
}

function formatSchemaSection(value: string) {
  return translateEnum('recipe.schemaSections', value)
}

function parseJsonObjectText(text: string, errorMessage: string): JsonObject {
  const trimmed = text.trim()
  if (!trimmed) return {}
  try {
    const parsed: unknown = JSON.parse(trimmed)
    if (!isJsonObject(parsed)) throw new Error(errorMessage)
    return parsed
  } catch {
    throw new Error(errorMessage)
  }
}

function toDateTimeLocal(value: string | null) {
  if (!value) return ''
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return ''
  const pad = (input: number) => String(input).padStart(2, '0')
  return `${date.getFullYear()}-${pad(date.getMonth() + 1)}-${pad(date.getDate())}T${pad(date.getHours())}:${pad(date.getMinutes())}`
}

function fromDateTimeLocal(value: string) {
  if (!value) return null
  const date = new Date(value)
  return Number.isNaN(date.getTime()) ? null : date.toISOString()
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

function schemaHasSection(schema: JsonObject | null, sectionKey: string) {
  const props = resolveSchemaNode(schema, schema?.properties)
  return Boolean(resolveSchemaNode(schema, props?.[sectionKey]))
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

function resetHeaderErrors() {
  Object.keys(headerErrors).forEach((key) => delete headerErrors[key])
  Object.keys(versionErrors).forEach((key) => delete versionErrors[key])
}

function validateHeaderForms() {
  resetHeaderErrors()
  if (!headerForm.recipe_code.trim()) headerErrors.recipe_code = t('recipe.edit.recipeCodeRequired')
  if (!headerForm.recipe_name.trim()) headerErrors.recipe_name = t('recipe.edit.recipeNameRequired')
  if (!versionForm.schema_code.trim()) versionErrors.schema_code = t('recipe.edit.schemaCodeRequired')
  return Object.keys(headerErrors).length === 0 && Object.keys(versionErrors).length === 0
}

async function loadReferenceData() {
  const [
    { data: materialData },
    { data: materialSpecData },
    { data: materialTypeData },
    { data: equipmentTypeData },
    { data: equipmentTemplateData },
    { data: qualityCheckData },
    { data: uomData },
  ] = await Promise.all([
    mesClient()
      .from('mst_material')
      .select('id, material_code, material_name, material_type_id, material_spec_id, base_uom_id, status')
      .eq('status', 'active')
      .order('material_code', { ascending: true }),
    mesClient()
      .from('mst_material_spec')
      .select('id, material_type_id, spec_code, spec_name')
      .eq('status', 'active')
      .order('spec_code', { ascending: true }),
    supabase
      .from('type_def')
      .select('type_id, code, name')
      .eq('domain', 'material_type')
      .eq('is_active', true)
      .order('sort_order', { ascending: true }),
    supabase
      .from('type_def')
      .select('type_id, code, name')
      .eq('domain', 'equipment_type')
      .eq('is_active', true)
      .order('sort_order', { ascending: true }),
    mesClient()
      .from('mst_equipment_template')
      .select('id, template_code, template_name, equipment_type_id, status')
      .eq('status', 'active')
      .order('template_code', { ascending: true }),
    mesClient()
      .from('mst_quality_check')
      .select('id, check_code, check_name, status')
      .eq('status', 'active')
      .order('check_code', { ascending: true }),
    supabase
      .from('mst_uom')
      .select('id, code, name')
      .order('code', { ascending: true }),
  ])

  materialOptions.value = (materialData ?? []) as MaterialMasterRow[]
  materialSpecs.value = (materialSpecData ?? []) as MaterialSpecRow[]
  materialTypes.value = (materialTypeData ?? []) as MaterialTypeRow[]
  equipmentTypes.value = (equipmentTypeData ?? []) as EquipmentTypeRow[]
  equipmentTemplates.value = (equipmentTemplateData ?? []) as EquipmentTemplateRow[]
  qualityCheckOptions.value = (qualityCheckData ?? []) as QualityCheckMasterRow[]
  uoms.value = (uomData ?? []) as UomRow[]
}

async function loadSchema() {
  schemaLoading.value = true
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
    schemaMeta.def_id = payload.def_id ?? ''
    schemaMeta.def_key = payload.def_key
    schemaMeta.scope = payload.scope ?? ''
  } catch (error: unknown) {
    recipeSchema.value = null
    schemaMeta.def_id = ''
    schemaMeta.def_key = activeSchemaKey.value
    schemaMeta.scope = ''
    schemaError.value = error instanceof Error ? error.message : String(error)
    toast.error(t('recipe.edit.loadSchemaFailed', { message: schemaError.value }))
  } finally {
    schemaLoading.value = false
  }
}

async function loadRecipeContext() {
  if (!recipeId.value) {
    toast.error(t('recipe.edit.missingRecipeId'))
    void router.push('/recipeList')
    return
  }

  loadingPage.value = true

  const { data: headerData, error: headerError } = await mesClient()
    .from('mst_recipe')
    .select('id, recipe_code, recipe_name, recipe_category, industry_type, status, current_version_id')
    .eq('id', recipeId.value)
    .single()

  if (headerError || !headerData) {
    loadingPage.value = false
    toast.error(t('recipe.edit.loadRecipeFailed', { message: headerError?.message ?? '' }))
    void router.push('/recipeList')
    return
  }

  const { data: versionData, error: versionError } = await mesClient()
    .from('mst_recipe_version')
    .select('id, recipe_id, version_no, version_label, recipe_body_json, resolved_reference_json, schema_code, template_code, status, effective_from, effective_to, change_summary, created_at, updated_at')
    .eq('recipe_id', recipeId.value)
    .order('version_no', { ascending: false })

  loadingPage.value = false

  if (versionError) {
    toast.error(t('recipe.edit.loadRecipeVersionsFailed', { message: versionError.message }))
    return
  }

  recipeHeader.value = headerData as RecipeHeaderRow
  recipeVersions.value = (versionData ?? []) as RecipeVersionRow[]

  const selectedVersion =
    recipeVersions.value.find((row) => row.id === routeVersionId.value)
    ?? recipeVersions.value.find((row) => row.id === recipeHeader.value?.current_version_id)
    ?? recipeVersions.value[0]
    ?? null

  if (!selectedVersion) {
    toast.error(t('recipe.edit.noRecipeVersionFound'))
    return
  }

  applyRecipeHeader(recipeHeader.value)
  applyRecipeVersion(selectedVersion)
  currentVersionId.value = selectedVersion.id
  await loadSchema()
}

function applyRecipeHeader(row: RecipeHeaderRow) {
  headerForm.recipe_code = row.recipe_code
  headerForm.recipe_name = row.recipe_name
  headerForm.recipe_category = row.recipe_category ?? ''
  headerForm.industry_type = row.industry_type ?? ''
  headerForm.status = row.status
}

function applyRecipeVersion(row: RecipeVersionRow) {
  activeVersion.value = row
  versionForm.id = row.id
  versionForm.version_no = row.version_no
  versionForm.version_label = row.version_label ?? ''
  versionForm.schema_code = row.schema_code || (typeof route.query.schemaKey === 'string' ? route.query.schemaKey : DEFAULT_SCHEMA_KEY)
  versionForm.status = row.status
  versionForm.effective_from = toDateTimeLocal(row.effective_from)
  versionForm.effective_to = toDateTimeLocal(row.effective_to)
  versionForm.change_summary = row.change_summary ?? ''
  recipeBody.value = normalizeRecipeBody(row.recipe_body_json, headerForm.industry_type, versionForm.schema_code)
  releaseCriteriaText.value = JSON.stringify(recipeBody.value.quality.release_criteria ?? {}, null, 2)
}

async function handleVersionChange() {
  if (!currentVersionId.value || !recipeHeader.value) return
  const version = recipeVersions.value.find((row) => row.id === currentVersionId.value)
  if (!version) return
  await router.replace({
    path: `/recipeEdit/${recipeHeader.value.id}/${version.id}`,
    query: { schemaKey: version.schema_code || DEFAULT_SCHEMA_KEY },
  })
}

function syncRecipeBodyWithHeader() {
  recipeBody.value.recipe_info = {
    ...recipeBody.value.recipe_info,
    industry_type: headerForm.industry_type.trim() || undefined,
  }
}

function syncReleaseCriteriaFromEditor() {
  recipeBody.value.quality.release_criteria = parseJsonObjectText(
    releaseCriteriaText.value,
    t('recipe.edit.releaseCriteriaInvalid'),
  )
}

async function persistRecipe(showToast = true) {
  if (!recipeHeader.value || !activeVersion.value) return false
  if (!validateHeaderForms()) return false

  try {
    syncRecipeBodyWithHeader()
    syncReleaseCriteriaFromEditor()
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error)
    toast.error(message)
    return false
  }
  saving.value = true

  try {
    const { error: headerError } = await mesClient()
      .from('mst_recipe')
      .update({
        recipe_code: headerForm.recipe_code.trim(),
        recipe_name: headerForm.recipe_name.trim(),
        recipe_category: headerForm.recipe_category.trim() || null,
        industry_type: headerForm.industry_type.trim() || null,
        status: headerForm.status,
      })
      .eq('id', recipeHeader.value.id)
    if (headerError) throw headerError

    const { data: versionRow, error: versionError } = await mesClient()
      .from('mst_recipe_version')
      .update({
        version_label: versionForm.version_label.trim() || null,
        schema_code: versionForm.schema_code.trim() || DEFAULT_SCHEMA_KEY,
        status: versionForm.status,
        effective_from: fromDateTimeLocal(versionForm.effective_from),
        effective_to: fromDateTimeLocal(versionForm.effective_to),
        change_summary: versionForm.change_summary.trim() || null,
        recipe_body_json: recipeBody.value,
      })
      .eq('id', activeVersion.value.id)
      .select('id, recipe_id, version_no, version_label, recipe_body_json, resolved_reference_json, schema_code, template_code, status, effective_from, effective_to, change_summary, created_at, updated_at')
      .single()
    if (versionError || !versionRow) throw versionError ?? new Error(t('recipe.edit.saveRecipeVersionFailed'))

    activeVersion.value = versionRow as RecipeVersionRow
    await loadRecipeContext()
    if (showToast) toast.success(t('recipe.edit.recipeSaved'))
    return true
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error)
    toast.error(t('recipe.edit.saveError', { message }))
    return false
  } finally {
    saving.value = false
  }
}

async function saveRecipe() {
  await persistRecipe(true)
}

async function versionUp() {
  if (!recipeHeader.value || !activeVersion.value || versioning.value) return
  if (!validateHeaderForms()) return

  versioning.value = true
  try {
    const saved = await persistRecipe(false)
    if (!saved) return

    const latestVersionNo = recipeVersions.value.reduce((max, row) => Math.max(max, row.version_no), 0)
    const nextVersionNo = latestVersionNo + 1

    const { data: inserted, error: insertError } = await mesClient()
      .from('mst_recipe_version')
      .insert({
        recipe_id: recipeHeader.value.id,
        version_no: nextVersionNo,
        version_label: `v${nextVersionNo}`,
        recipe_body_json: recipeBody.value,
        resolved_reference_json: activeVersion.value.resolved_reference_json ?? {},
        schema_code: versionForm.schema_code.trim() || DEFAULT_SCHEMA_KEY,
        template_code: activeVersion.value.template_code ?? null,
        status: 'draft',
        change_summary: versionForm.change_summary.trim() || null,
      })
      .select('id, recipe_id, version_no, version_label, recipe_body_json, resolved_reference_json, schema_code, template_code, status, effective_from, effective_to, change_summary, created_at, updated_at')
      .single()
    if (insertError || !inserted) throw insertError ?? new Error(t('recipe.edit.createNewVersionFailed'))

    const { error: updateHeaderError } = await mesClient()
      .from('mst_recipe')
      .update({ current_version_id: inserted.id })
      .eq('id', recipeHeader.value.id)
    if (updateHeaderError) throw updateHeaderError

    await router.replace({
      path: `/recipeEdit/${recipeHeader.value.id}/${inserted.id}`,
      query: { schemaKey: inserted.schema_code || DEFAULT_SCHEMA_KEY },
    })
    toast.success(t('recipe.edit.versionCreated', { version: nextVersionNo }))
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error)
    toast.error(t('recipe.edit.versionUpError', { message }))
  } finally {
    versioning.value = false
  }
}

function resetMaterialErrors() {
  Object.keys(materialErrors).forEach((key) => delete materialErrors[key])
}

function openMaterialCreate(optional: boolean) {
  materialEditIndex.value = null
  materialForm.section = optional ? 'optional' : 'required'
  materialForm.material_id = ''
  materialForm.material_role = ''
  materialForm.qty = ''
  materialForm.uom_code = ''
  materialForm.basis = 'per_base'
  materialForm.notes = ''
  resetMaterialErrors()
  showMaterialModal.value = true
}

function openMaterialEdit(section: MaterialSection, index: number) {
  const item = recipeBody.value.materials[section][index]
  if (!item) return

  materialEditIndex.value = index
  materialForm.section = section
  materialForm.material_id = findMaterialIdForRequirement(item)
  materialForm.material_role = item.material_role
  materialForm.qty = String(item.qty)
  materialForm.uom_code = item.uom_code
  materialForm.basis = item.basis || 'per_base'
  materialForm.notes = item.notes || ''
  resetMaterialErrors()
  showMaterialModal.value = true
}

function closeMaterialModal() {
  showMaterialModal.value = false
}

function findMaterialIdForRequirement(item: RecipeMaterialRequirement) {
  const exact = materialOptions.value.find((row) => row.material_code === item.material_code)
  if (exact) return exact.id
  const fallback = materialOptions.value.find((row) => row.material_code === item.material_key)
  return fallback?.id ?? ''
}

function validateMaterialForm() {
  resetMaterialErrors()
  if (!materialForm.material_id) materialErrors.material_id = t('recipe.edit.materialRequired')
  if (!materialForm.material_role.trim()) materialErrors.material_role = t('recipe.edit.materialRoleRequired')
  const qty = Number(materialForm.qty)
  if (!Number.isFinite(qty) || qty < 0) materialErrors.qty = t('recipe.edit.quantityNonNegative')
  if (!materialForm.uom_code.trim()) materialErrors.uom_code = t('recipe.edit.uomCodeRequired')
  return Object.keys(materialErrors).length === 0
}

function saveMaterial() {
  if (!validateMaterialForm()) return
  const material = materialMasterMap.value.get(materialForm.material_id)
  if (!material) {
    materialErrors.material_id = t('recipe.edit.selectedMaterialNotFound')
    return
  }

  const spec = material.material_spec_id ? materialSpecMap.value.get(material.material_spec_id) : undefined
  const type = material.material_type_id != null ? materialTypeMap.value.get(material.material_type_id) : undefined
  const requirement: RecipeMaterialRequirement = {
    material_key: material.material_code,
    material_name: material.material_name,
    material_role: materialForm.material_role.trim(),
    material_code: material.material_code,
    material_spec_code: spec?.spec_code,
    material_type_code: type?.code,
    qty: Number(materialForm.qty),
    uom_code: materialForm.uom_code.trim(),
    basis: materialForm.basis,
    is_optional: materialForm.section === 'optional',
    notes: materialForm.notes.trim() || undefined,
  }

  const targetList = recipeBody.value.materials[materialForm.section]
  if (materialEditIndex.value === null) {
    targetList.push(requirement)
  } else {
    targetList.splice(materialEditIndex.value, 1, requirement)
  }

  closeMaterialModal()
}

function deleteMaterial(section: MaterialSection, index: number) {
  recipeBody.value.materials[section].splice(index, 1)
}

function resetOutputErrors() {
  Object.keys(outputErrors).forEach((key) => delete outputErrors[key])
}

function openOutputCreate(section: OutputSection) {
  outputEditIndex.value = null
  outputForm.section = section
  outputForm.output_code = ''
  outputForm.output_name = ''
  outputForm.output_type = section === 'co_products' ? 'co_product' : section === 'waste' ? 'waste' : 'primary'
  outputForm.qty = ''
  outputForm.uom_code = ''
  outputForm.basis = 'per_base'
  outputForm.notes = ''
  resetOutputErrors()
  showOutputModal.value = true
}

function openOutputEdit(section: OutputSection, index: number) {
  const item = recipeBody.value.outputs[section][index]
  if (!item) return
  outputEditIndex.value = index
  outputForm.section = section
  outputForm.output_code = item.output_code
  outputForm.output_name = item.output_name
  outputForm.output_type = item.output_type
  outputForm.qty = String(item.qty)
  outputForm.uom_code = item.uom_code
  outputForm.basis = item.basis || 'per_base'
  outputForm.notes = item.notes || ''
  resetOutputErrors()
  showOutputModal.value = true
}

function closeOutputModal() {
  showOutputModal.value = false
}

function validateOutputForm() {
  resetOutputErrors()
  if (!outputForm.output_code.trim()) outputErrors.output_code = t('recipe.edit.outputCodeRequired')
  if (!outputForm.output_name.trim()) outputErrors.output_name = t('recipe.edit.outputNameRequired')
  const qty = Number(outputForm.qty)
  if (!Number.isFinite(qty) || qty < 0) outputErrors.qty = t('recipe.edit.outputQuantityNonNegative')
  if (!outputForm.uom_code.trim()) outputErrors.uom_code = t('recipe.edit.outputUomRequired')
  return Object.keys(outputErrors).length === 0
}

function saveOutput() {
  if (!validateOutputForm()) return
  const output: RecipeOutputSpec = {
    output_code: outputForm.output_code.trim(),
    output_name: outputForm.output_name.trim(),
    output_type: outputForm.output_type,
    qty: Number(outputForm.qty),
    uom_code: outputForm.uom_code.trim(),
    basis: outputForm.basis || undefined,
    notes: outputForm.notes.trim() || undefined,
  }
  const targetList = recipeBody.value.outputs[outputForm.section]
  if (outputEditIndex.value === null) {
    targetList.push(output)
  } else {
    targetList.splice(outputEditIndex.value, 1, output)
  }
  closeOutputModal()
}

function deleteOutput(section: OutputSection, index: number) {
  recipeBody.value.outputs[section].splice(index, 1)
}

function resetEquipmentErrors() {
  Object.keys(equipmentErrors).forEach((key) => delete equipmentErrors[key])
}

function openEquipmentCreate() {
  equipmentEditIndex.value = null
  equipmentForm.equipment_type_code = ''
  equipmentForm.equipment_template_code = ''
  equipmentForm.quantity = '1'
  equipmentForm.capability_rules = '{}'
  equipmentForm.notes = ''
  resetEquipmentErrors()
  showEquipmentModal.value = true
}

function openEquipmentEdit(index: number) {
  const item = equipmentRequirements.value[index]
  if (!item) return
  equipmentEditIndex.value = index
  equipmentForm.equipment_type_code = item.equipment_type_code
  equipmentForm.equipment_template_code = item.equipment_template_code || ''
  equipmentForm.quantity = String(item.quantity ?? 1)
  equipmentForm.capability_rules = JSON.stringify(item.capability_rules ?? {}, null, 2)
  equipmentForm.notes = item.notes || ''
  resetEquipmentErrors()
  showEquipmentModal.value = true
}

function closeEquipmentModal() {
  showEquipmentModal.value = false
}

function validateEquipmentForm() {
  resetEquipmentErrors()
  if (!equipmentForm.equipment_type_code.trim()) equipmentErrors.equipment_type_code = t('recipe.edit.equipmentTypeRequired')
  const quantity = Number(equipmentForm.quantity)
  if (!Number.isInteger(quantity) || quantity < 1) equipmentErrors.quantity = t('recipe.edit.equipmentQuantityMin')
  try {
    parseJsonObjectText(equipmentForm.capability_rules, t('recipe.edit.capabilityRulesInvalid'))
  } catch (error: unknown) {
    equipmentErrors.capability_rules = error instanceof Error ? error.message : String(error)
  }
  return Object.keys(equipmentErrors).length === 0
}

function saveEquipmentRequirement() {
  if (!validateEquipmentForm()) return
  const requirement: RecipeEquipmentRequirement = {
    equipment_type_code: equipmentForm.equipment_type_code.trim(),
    equipment_template_code: equipmentForm.equipment_template_code.trim() || undefined,
    quantity: Number(equipmentForm.quantity),
    capability_rules: parseJsonObjectText(equipmentForm.capability_rules, t('recipe.edit.capabilityRulesInvalid')),
    notes: equipmentForm.notes.trim() || undefined,
  }
  if (equipmentEditIndex.value === null) {
    recipeBody.value.equipment.default_requirements.push(requirement)
  } else {
    recipeBody.value.equipment.default_requirements.splice(equipmentEditIndex.value, 1, requirement)
  }
  closeEquipmentModal()
}

function deleteEquipmentRequirement(index: number) {
  recipeBody.value.equipment.default_requirements.splice(index, 1)
}

function resetGlobalQualityErrors() {
  Object.keys(globalQualityErrors).forEach((key) => delete globalQualityErrors[key])
}

function openGlobalQualityCreate() {
  globalQualityEditIndex.value = null
  globalQualityForm.check_code = ''
  globalQualityForm.check_name = ''
  globalQualityForm.sampling_point = ''
  globalQualityForm.frequency = ''
  globalQualityForm.required = true
  globalQualityForm.acceptance_criteria = '{}'
  globalQualityForm.notes = ''
  resetGlobalQualityErrors()
  showGlobalQualityModal.value = true
}

function openGlobalQualityEdit(index: number) {
  const item = globalQualityChecks.value[index]
  if (!item) return
  globalQualityEditIndex.value = index
  globalQualityForm.check_code = item.check_code
  globalQualityForm.check_name = item.check_name || ''
  globalQualityForm.sampling_point = item.sampling_point || ''
  globalQualityForm.frequency = item.frequency || ''
  globalQualityForm.required = item.required ?? true
  globalQualityForm.acceptance_criteria = JSON.stringify(item.acceptance_criteria ?? {}, null, 2)
  globalQualityForm.notes = item.notes || ''
  resetGlobalQualityErrors()
  showGlobalQualityModal.value = true
}

function closeGlobalQualityModal() {
  showGlobalQualityModal.value = false
}

function syncGlobalQualityName() {
  const option = qualityCheckMap.value.get(globalQualityForm.check_code)
  if (option && !globalQualityForm.check_name.trim()) {
    globalQualityForm.check_name = option.check_name
  }
}

function validateGlobalQualityForm() {
  resetGlobalQualityErrors()
  if (!globalQualityForm.check_code.trim()) globalQualityErrors.check_code = t('recipe.edit.qualityCheckCodeRequired')
  try {
    parseJsonObjectText(globalQualityForm.acceptance_criteria, t('recipe.edit.acceptanceCriteriaInvalid'))
  } catch (error: unknown) {
    globalQualityErrors.acceptance_criteria = error instanceof Error ? error.message : String(error)
  }
  return Object.keys(globalQualityErrors).length === 0
}

function saveGlobalQualityCheck() {
  if (!validateGlobalQualityForm()) return
  const check: RecipeQualityCheck = {
    check_code: globalQualityForm.check_code.trim(),
    check_name: globalQualityForm.check_name.trim() || undefined,
    sampling_point: globalQualityForm.sampling_point.trim() || undefined,
    frequency: globalQualityForm.frequency.trim() || undefined,
    required: globalQualityForm.required,
    acceptance_criteria: parseJsonObjectText(globalQualityForm.acceptance_criteria, t('recipe.edit.acceptanceCriteriaInvalid')),
    notes: globalQualityForm.notes.trim() || undefined,
  }
  if (globalQualityEditIndex.value === null) {
    recipeBody.value.quality.global_checks.push(check)
  } else {
    recipeBody.value.quality.global_checks.splice(globalQualityEditIndex.value, 1, check)
  }
  closeGlobalQualityModal()
}

function deleteGlobalQualityCheck(index: number) {
  recipeBody.value.quality.global_checks.splice(index, 1)
}

function applyReleaseCriteria() {
  try {
    syncReleaseCriteriaFromEditor()
    toast.success(t('recipe.edit.releaseCriteriaApplied'))
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error)
    toast.error(message)
  }
}

function resetDocumentErrors() {
  Object.keys(documentErrors).forEach((key) => delete documentErrors[key])
}

function openDocumentCreate() {
  documentEditIndex.value = null
  documentForm.doc_code = ''
  documentForm.doc_type = ''
  documentForm.title = ''
  documentForm.revision = ''
  documentForm.url = ''
  documentForm.required = false
  documentForm.notes = ''
  resetDocumentErrors()
  showDocumentModal.value = true
}

function openDocumentEdit(index: number) {
  const item = documentRows.value[index]
  if (!item) return
  documentEditIndex.value = index
  documentForm.doc_code = item.doc_code
  documentForm.doc_type = item.doc_type
  documentForm.title = item.title || ''
  documentForm.revision = item.revision || ''
  documentForm.url = item.url || ''
  documentForm.required = item.required ?? false
  documentForm.notes = item.notes || ''
  resetDocumentErrors()
  showDocumentModal.value = true
}

function closeDocumentModal() {
  showDocumentModal.value = false
}

function validateDocumentForm() {
  resetDocumentErrors()
  if (!documentForm.doc_code.trim()) documentErrors.doc_code = t('recipe.edit.documentCodeRequired')
  if (!documentForm.doc_type.trim()) documentErrors.doc_type = t('recipe.edit.documentTypeRequired')
  return Object.keys(documentErrors).length === 0
}

function saveDocument() {
  if (!validateDocumentForm()) return
  const documentRef: RecipeDocumentRef = {
    doc_code: documentForm.doc_code.trim(),
    doc_type: documentForm.doc_type.trim(),
    title: documentForm.title.trim() || undefined,
    revision: documentForm.revision.trim() || undefined,
    url: documentForm.url.trim() || undefined,
    required: documentForm.required,
    notes: documentForm.notes.trim() || undefined,
  }
  if (documentEditIndex.value === null) {
    recipeBody.value.documents.push(documentRef)
  } else {
    recipeBody.value.documents.splice(documentEditIndex.value, 1, documentRef)
  }
  closeDocumentModal()
}

function deleteDocument(index: number) {
  recipeBody.value.documents.splice(index, 1)
}

function createParameterRow(initial?: Partial<ParameterRowState>) {
  return {
    key: `param-${++parameterRowCounter}`,
    parameter_code: initial?.parameter_code ?? '',
    target: initial?.target ?? '',
    uom_code: initial?.uom_code ?? '',
  }
}

function createQualityRow(initial?: Partial<QualityRowState>) {
  return {
    key: `qc-${++qualityRowCounter}`,
    check_code: initial?.check_code ?? '',
    frequency: initial?.frequency ?? '',
  }
}

function resetStepErrors() {
  Object.keys(stepErrors).forEach((key) => delete stepErrors[key])
}

function resetStepForm() {
  stepEditIndex.value = null
  stepSource.value = null
  stepForm.step_no = flowSteps.value.length > 0 ? Math.max(...flowSteps.value.map((item) => item.step_no)) + 10 : 10
  stepForm.step_code = ''
  stepForm.step_name = ''
  stepForm.step_type = stepTypeOptions.value[0] ?? FALLBACK_STEP_TYPES[0]
  stepForm.step_template_code = ''
  stepForm.duration_sec = ''
  stepForm.instructions = ''
  stepForm.notes = ''
  parameterRows.value = []
  qualityRows.value = []
  resetStepErrors()
}

function openStepCreate() {
  resetStepForm()
  showStepModal.value = true
}

function openStepEdit(index: number) {
  const step = flowSteps.value[index]
  if (!step) return
  resetStepForm()
  stepEditIndex.value = index
  stepSource.value = deepCloneJson(step)
  stepForm.step_no = step.step_no
  stepForm.step_code = step.step_code
  stepForm.step_name = step.step_name
  stepForm.step_type = step.step_type || stepTypeOptions.value[0] || FALLBACK_STEP_TYPES[0]
  stepForm.step_template_code = step.step_template_code || ''
  stepForm.duration_sec = step.duration_sec != null ? String(step.duration_sec) : ''
  stepForm.instructions = step.instructions || ''
  stepForm.notes = step.notes || ''
  parameterRows.value = (step.parameters ?? []).map((row) => createParameterRow({
    parameter_code: row.parameter_code,
    target: row.target == null ? '' : String(row.target),
    uom_code: row.uom_code || '',
  }))
  qualityRows.value = (step.quality_checks ?? []).map((row) => createQualityRow({
    check_code: row.check_code,
    frequency: row.frequency || '',
  }))
  showStepModal.value = true
}

function closeStepModal() {
  showStepModal.value = false
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

function validateStepForm() {
  resetStepErrors()
  if (!Number.isInteger(stepForm.step_no) || stepForm.step_no < 1) stepErrors.step_no = t('recipe.edit.stepNumberPositive')
  if (!stepForm.step_code.trim()) stepErrors.step_code = t('recipe.edit.stepCodeRequired')
  if (!stepForm.step_name.trim()) stepErrors.step_name = t('recipe.edit.stepNameRequired')
  return Object.keys(stepErrors).length === 0
}

function saveStep() {
  if (!validateStepForm()) return

  const parameters = parameterRows.value
    .map((row) => ({
      parameter_code: row.parameter_code.trim(),
      target: row.target.trim(),
      uom_code: row.uom_code.trim(),
    }))
    .filter((row) => row.parameter_code)
    .map((row): RecipeParameterTarget => ({
      parameter_code: row.parameter_code,
      target: row.target === '' ? undefined : (Number.isNaN(Number(row.target)) ? row.target : Number(row.target)),
      uom_code: row.uom_code || undefined,
    }))

  const qualityChecks = qualityRows.value
    .map((row) => ({
      check_code: row.check_code.trim(),
      frequency: row.frequency.trim(),
    }))
    .filter((row) => row.check_code)
    .map((row): RecipeQualityCheck => ({
      check_code: row.check_code,
      frequency: row.frequency || undefined,
    }))

  const step: RecipeFlowStep = {
    step_code: stepForm.step_code.trim(),
    step_name: stepForm.step_name.trim(),
    step_no: stepForm.step_no,
    step_type: stepForm.step_type,
    step_template_code: stepForm.step_template_code.trim() || undefined,
    instructions: stepForm.instructions.trim() || undefined,
    duration_sec: stepForm.duration_sec.trim() ? Number(stepForm.duration_sec) : undefined,
    parameters,
    quality_checks: qualityChecks,
    notes: stepForm.notes.trim() || undefined,
    material_inputs: stepSource.value?.material_inputs ?? [],
    material_outputs: stepSource.value?.material_outputs ?? [],
    equipment_requirements: stepSource.value?.equipment_requirements ?? [],
    hold_constraints: stepSource.value?.hold_constraints ?? [],
  }

  if (stepEditIndex.value === null) {
    recipeBody.value.flow.steps.push(step)
  } else {
    recipeBody.value.flow.steps.splice(stepEditIndex.value, 1, step)
  }

  recipeBody.value.flow.steps.sort((a, b) => a.step_no - b.step_no)
  closeStepModal()
}

function deleteStep(index: number) {
  recipeBody.value.flow.steps.splice(index, 1)
}

onMounted(async () => {
  await loadReferenceData()
  await loadRecipeContext()
})

watch(
  () => [route.params.recipeId, route.params.versionId, route.query.schemaKey],
  async (next, previous) => {
    if (JSON.stringify(next) === JSON.stringify(previous)) return
    await loadRecipeContext()
  },
)
</script>
