<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div class="space-y-6">
      <section class="bg-white shadow rounded-lg border border-gray-200" aria-labelledby="recipeInfoHeading">
        <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between p-4 border-b">
          <div>
            <h2 id="recipeInfoHeading" class="text-lg font-semibold text-gray-900">
              {{ t('recipe.edit.infoTitle') }}
            </h2>
            <p class="text-sm text-gray-500">{{ t('recipe.edit.infoSubtitle') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-60"
              :disabled="loadingRecipe"
              @click="loadRecipe"
            >
              {{ t('common.refresh') }}
            </button>
            <button
              class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-60"
              :disabled="savingRecipe"
              @click="saveRecipeInfo"
            >
              {{ savingRecipe ? t('common.saving') : t('common.save') }}
            </button>
          </div>
        </header>

        <form class="p-4 grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4" @submit.prevent>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.recipeId') }}<span class="text-red-600">*</span></label>
            <input v-model.trim="recipeForm.code" class="w-full h-[40px] border rounded px-3" />
            <p v-if="recipeErrors.code" class="text-xs text-red-600 mt-1">{{ recipeErrors.code }}</p>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.name') }}<span class="text-red-600">*</span></label>
            <input v-model.trim="recipeForm.name" class="w-full h-[40px] border rounded px-3" />
            <p v-if="recipeErrors.name" class="text-xs text-red-600 mt-1">{{ recipeErrors.name }}</p>
          </div>
          <div>
            <div class="flex items-center justify-between mb-1">
              <label class="block text-sm text-gray-600">{{ t('recipe.list.name') }}<span class="text-red-600">*</span></label>
              <div class="flex items-center gap-2">
                <span class="inline-flex items-center justify-center h-[32px] px-2 border rounded bg-gray-50 text-xs font-semibold">v{{ recipeForm.version }}</span>
                <button
                  type="button"
                  class="px-3 py-1.5 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-60"
                  :disabled="versioning || savingRecipe"
                  @click="versionUp"
                >
                  {{ versioning ? t('common.saving') : t('recipe.edit.versionUp') }}
                </button>
              </div>
            </div>
            <input v-model.trim="recipeForm.name" class="w-full h-[40px] border rounded px-3" />
            <p v-if="recipeErrors.name" class="text-xs text-red-600 mt-1">{{ recipeErrors.name }}</p>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.status') }}</label>
            <select v-model="recipeForm.status" class="w-full h-[40px] border rounded px-3 bg-white">
              <option v-for="status in STATUSES" :key="status" :value="status">
                {{ statusLabel(status) }}
              </option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.style') }}</label>
            <input v-model.trim="recipeForm.style" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.edit.category') }}</label>
            <select v-model="recipeForm.category" class="w-full h-[40px] border rounded px-3 bg-white">
              <option value="">{{ t('recipe.edit.selectCategory') }}</option>
              <option v-for="category in categories" :key="category.id" :value="category.id">
                {{ category.name || category.code }}
              </option>
            </select>
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.edit.batchSize') }}</label>
            <input v-model.trim="recipeForm.batch_size_l" type="number" step="0.01" min="0" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.edit.targetOg') }}</label>
            <input v-model.trim="recipeForm.target_og" type="number" step="0.001" min="0" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.edit.targetFg') }}</label>
            <input v-model.trim="recipeForm.target_fg" type="number" step="0.001" min="0" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.edit.targetAbv') }}</label>
            <input v-model.trim="recipeForm.target_abv" type="number" step="0.01" min="0" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.edit.targetIbu') }}</label>
            <input v-model.trim="recipeForm.target_ibu" type="number" step="0.1" min="0" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div>
            <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.edit.targetSrm') }}</label>
            <input v-model.trim="recipeForm.target_srm" type="number" step="0.1" min="0" class="w-full h-[40px] border rounded px-3" />
          </div>
          <div class="lg:col-span-3">
            <label class="block text-sm text-gray-600 mb-1">{{ t('labels.note') }}</label>
            <textarea v-model.trim="recipeForm.notes" rows="3" class="w-full border rounded px-3 py-2"></textarea>
          </div>
        </form>
      </section>

      <section class="bg-white shadow rounded-lg border border-gray-200" aria-labelledby="ingredientHeading">
        <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between p-4 border-b">
          <div>
            <h2 id="ingredientHeading" class="text-lg font-semibold text-gray-900">
              {{ t('recipe.edit.ingredientsTitle') }}
            </h2>
            <p class="text-sm text-gray-500">{{ t('recipe.edit.ingredientsSubtitle') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <div class="flex items-center gap-2">
              <label for="ingredientTypeFilter" class="text-xs font-semibold text-gray-500 uppercase tracking-wide">
                {{ t('recipe.edit.materialTypeFilter') }}
              </label>
              <select
                id="ingredientTypeFilter"
                v-model="materialCategoryFilter"
                class="h-[38px] min-w-[150px] rounded border border-gray-300 bg-white px-3 text-sm"
              >
                <option v-for="option in materialTypeOptions" :key="option.value" :value="option.value">
                  {{ option.label }}
                </option>
              </select>
            </div>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openIngredientCreate">
              {{ t('recipe.edit.addIngredient') }}
            </button>
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-100 disabled:opacity-60"
              :disabled="ingredientsLoading"
              @click="loadIngredients"
            >
              {{ t('common.refresh') }}
            </button>
          </div>
        </header>

        <div class="overflow-x-auto">
          <table class="min-w-full divide-y divide-gray-200">
            <thead class="bg-gray-50 text-xs uppercase text-gray-500">
              <tr>
                <th class="px-3 py-2 text-left">{{ t('recipe.edit.materialColumn') }}</th>
                <th class="px-3 py-2 text-left">{{ t('recipe.edit.amountColumn') }}</th>
                <th class="px-3 py-2 text-left">{{ t('recipe.edit.usageStage') }}</th>
                <th class="px-3 py-2 text-left">{{ t('labels.note') }}</th>
                <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-100 text-sm">
              <tr v-for="row in filteredIngredients" :key="row.id" class="hover:bg-gray-50">
                <td class="px-3 py-2">
                  <div class="font-medium text-gray-900">{{ materialLabel(row) }}</div>
                  <div class="text-xs text-gray-500">{{ row.material?.code }}</div>
                  <div v-if="ingredientCategoryLabel(row)" class="text-[11px] uppercase tracking-wide text-gray-400">
                    {{ ingredientCategoryLabel(row) }}
                  </div>
                </td>
                <td class="px-3 py-2">
                  {{ row.amount ?? '—' }}
                  <span v-if="row.uom" class="text-xs text-gray-500">{{ row.uom.code }}</span>
                </td>
                <td class="px-3 py-2">{{ row.usage_stage || '—' }}</td>
                <td class="px-3 py-2 text-xs text-gray-600">{{ row.notes || '—' }}</td>
                <td class="px-3 py-2 space-x-2">
                  <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openIngredientEdit(row)">
                    {{ t('common.edit') }}
                  </button>
                  <button class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700" @click="deleteIngredient(row)">
                    {{ t('common.delete') }}
                  </button>
                </td>
              </tr>
              <tr v-if="!ingredientsLoading && filteredIngredients.length === 0">
                <td colspan="5" class="px-3 py-6 text-center text-gray-500 text-sm">
                  {{
                    ingredients.length === 0
                      ? t('recipe.edit.ingredientsEmpty')
                      : t('recipe.edit.ingredientsFilteredEmpty')
                  }}
                </td>
              </tr>
            </tbody>
          </table>
        </div>
      </section>

      <section class="bg-white shadow rounded-lg border border-gray-200" aria-labelledby="processHeading">
        <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between p-4 border-b">
          <div>
            <h2 id="processHeading" class="text-lg font-semibold text-gray-900">
              {{ t('recipe.edit.processTitle') }}
            </h2>
            <p class="text-sm text-gray-500">{{ t('recipe.edit.processSubtitle') }}</p>
          </div>
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openProcessCreate">
            {{ t('recipe.edit.addProcess') }}
          </button>
        </header>

        <div v-if="processesLoading" class="p-4 text-sm text-gray-500">{{ t('common.loading') }}</div>
        <div v-else class="p-4 space-y-4">
          <div v-if="processes.length === 0" class="text-sm text-gray-500">
            {{ t('recipe.edit.processEmpty') }}
          </div>
          <article
            v-for="process in processes"
            :key="process.id"
            class="border border-gray-200 rounded-lg"
          >
            <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between px-4 py-3 border-b">
              <div>
                <h3 class="text-base font-semibold text-gray-900">
                  {{ process.name }}
                  <span class="text-xs text-gray-500">v{{ process.version }}</span>
                </h3>
                <p class="text-xs text-gray-500">
                  {{ process.is_active ? t('recipe.edit.processActive') : t('recipe.edit.processInactive') }}
                </p>
              </div>
              <div class="flex flex-wrap items-center gap-2">
                <button class="px-3 py-1 text-sm rounded border hover:bg-gray-100" @click="openProcessEdit(process)">
                  {{ t('common.edit') }}
                </button>
                <button class="px-3 py-1 text-sm rounded bg-red-600 text-white hover:bg-red-700" @click="deleteProcess(process)">
                  {{ t('common.delete') }}
                </button>
              </div>
            </header>

            <div class="px-4 py-3 space-y-3">
              <div v-if="process.notes" class="text-sm text-gray-600 bg-gray-50 border border-gray-200 rounded p-3">
                {{ process.notes }}
              </div>

              <div class="flex justify-between items-center">
                <h4 class="text-sm font-semibold text-gray-700">{{ t('recipe.edit.stepsTitle') }}</h4>
                <button class="px-3 py-1 text-xs rounded bg-blue-600 text-white hover:bg-blue-700" @click="openStepCreate(process)">
                  {{ t('recipe.edit.addStep') }}
                </button>
              </div>

              <div class="overflow-x-auto">
                <table class="min-w-full divide-y divide-gray-200 text-sm">
                  <thead class="bg-gray-50 text-xs uppercase text-gray-500">
                    <tr>
                      <th class="px-3 py-2 text-left">#</th>
                      <th class="px-3 py-2 text-left">{{ t('recipe.edit.stepType') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('recipe.edit.targetParams') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('recipe.edit.qaChecks') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('labels.note') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="step in process.steps" :key="step.id" class="hover:bg-gray-50">
                      <td class="px-3 py-2 font-mono text-xs text-gray-600">{{ step.step_no }}</td>
                      <td class="px-3 py-2">{{ formatStepType(step.step) }}</td>
                      <td class="px-3 py-2 text-xs text-gray-600">
                        <div v-if="targetParamSummary(step.target_params).length > 0" class="space-y-1">
                          <div
                            v-for="(item, idx) in targetParamSummary(step.target_params)"
                            :key="`${step.id}-tp-${idx}`"
                            class="flex flex-wrap items-baseline gap-x-1"
                          >
                            <span class="font-medium text-gray-700">{{ item.name }}</span>
                            <span v-if="item.display" class="text-gray-500">—</span>
                            <span v-if="item.display">{{ item.display }}</span>
                          </div>
                        </div>
                        <span v-else>—</span>
                      </td>
                      <td class="px-3 py-2 text-xs text-gray-600">
                        <div v-if="qaChecksSummary(step.qa_checks).length > 0" class="space-y-1">
                          <div
                            v-for="(item, idx) in qaChecksSummary(step.qa_checks)"
                            :key="`${step.id}-qa-${idx}`"
                          >
                            {{ item }}
                          </div>
                        </div>
                        <span v-else>—</span>
                      </td>
                      <td class="px-3 py-2 text-xs text-gray-600">{{ step.notes || '—' }}</td>
                      <td class="px-3 py-2 space-x-2">
                        <button class="px-2 py-1 text-xs rounded border hover:bg-gray-100" @click="openStepEdit(process, step)">
                          {{ t('common.edit') }}
                        </button>
                        <button class="px-2 py-1 text-xs rounded bg-red-600 text-white hover:bg-red-700" @click="deleteStep(process, step)">
                          {{ t('common.delete') }}
                        </button>
                      </td>
                    </tr>
                    <tr v-if="process.steps.length === 0">
                      <td colspan="6" class="px-3 py-4 text-sm text-gray-500 text-center">
                        {{ t('recipe.edit.stepsEmpty') }}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
            </div>
          </article>
        </div>
      </section>
    </div>

    <!-- Ingredient Modal -->
    <div v-if="showIngredientModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg border border-gray-200">
        <header class="px-4 py-3 border-b">
          <h3 class="font-semibold text-gray-900">
            {{ editingIngredient ? t('recipe.edit.editIngredient') : t('recipe.edit.addIngredient') }}
          </h3>
        </header>
        <section class="p-4 space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.edit.materialColumn') }}<span class="text-red-600">*</span></label>
              <select v-model="ingredientForm.material_id" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('recipe.edit.selectMaterial') }}</option>
                <option v-for="material in materials" :key="material.id" :value="material.id">
                  {{ material.code }} — {{ material.name || material.code }}
                </option>
              </select>
              <p v-if="ingredientErrors.material" class="text-xs text-red-600 mt-1">{{ ingredientErrors.material }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.edit.amountColumn') }}</label>
              <input v-model.trim="ingredientForm.amount" type="number" step="0.01" min="0" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('labels.uom') }}<span class="text-red-600">*</span></label>
              <select v-model="ingredientForm.uom_id" class="w-full h-[40px] border rounded px-3 bg-white">
                <option value="">{{ t('recipe.edit.selectUom') }}</option>
                <option v-for="uom in uoms" :key="uom.id" :value="uom.id">
                  {{ uomLabel(uom) }}
                </option>
              </select>
              <p v-if="ingredientErrors.uom" class="text-xs text-red-600 mt-1">{{ ingredientErrors.uom }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.edit.usageStage') }}</label>
              <input v-model.trim="ingredientForm.usage_stage" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{ t('labels.note') }}</label>
              <textarea v-model.trim="ingredientForm.notes" rows="3" class="w-full border rounded px-3 py-2"></textarea>
            </div>
          </div>
        </section>
        <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
          <button class="px-3 py-2 rounded border hover:bg-gray-100" @click="closeIngredientModal">
            {{ t('common.cancel') }}
          </button>
          <button
            class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-60"
            :disabled="ingredientSaving"
            @click="saveIngredient"
          >
            {{ ingredientSaving ? t('common.saving') : t('common.save') }}
          </button>
        </footer>
      </div>
    </div>

    <!-- Process Modal -->
    <div v-if="showProcessModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-xl bg-white rounded-xl shadow-lg border border-gray-200">
        <header class="px-4 py-3 border-b">
          <h3 class="font-semibold text-gray-900">
            {{ editingProcess ? t('recipe.edit.editProcess') : t('recipe.edit.addProcess') }}
          </h3>
        </header>
        <section class="p-4 space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('labels.name') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="processForm.name" class="w-full h-[40px] border rounded px-3" />
              <p v-if="processErrors.name" class="text-xs text-red-600 mt-1">{{ processErrors.name }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.list.version') }}</label>
              <input v-model.number="processForm.version" type="number" min="1" class="w-full h-[40px] border rounded px-3" />
            </div>
            <div class="md:col-span-2 flex items-center gap-2">
              <input id="processActive" v-model="processForm.is_active" type="checkbox" class="h-4 w-4" />
              <label for="processActive" class="text-sm text-gray-700">{{ t('recipe.edit.markActive') }}</label>
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{ t('labels.note') }}</label>
              <textarea v-model.trim="processForm.notes" rows="3" class="w-full border rounded px-3 py-2"></textarea>
            </div>
          </div>
        </section>
        <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
          <button class="px-3 py-2 rounded border hover:bg-gray-100" @click="closeProcessModal">
            {{ t('common.cancel') }}
          </button>
          <button
            class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-60"
            :disabled="processSaving"
            @click="saveProcess"
          >
            {{ processSaving ? t('common.saving') : t('common.save') }}
          </button>
        </footer>
      </div>
    </div>

    <!-- Step Modal -->
    <div v-if="showStepModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
      <div class="w-full max-w-3xl bg-white rounded-xl shadow-lg border border-gray-200">
        <header class="px-4 py-3 border-b">
          <h3 class="font-semibold text-gray-900">
            {{ editingStep ? t('recipe.edit.editStep') : t('recipe.edit.addStep') }}
          </h3>
        </header>
        <section class="p-4 space-y-4">
          <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('labels.name') }}</label>
              <div class="text-sm text-gray-700">{{ currentProcess?.name }}</div>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.edit.stepNumber') }}<span class="text-red-600">*</span></label>
              <input v-model.number="stepForm.step_no" type="number" min="1" class="w-full h-[40px] border rounded px-3" />
              <p v-if="stepErrors.step_no" class="text-xs text-red-600 mt-1">{{ stepErrors.step_no }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('recipe.edit.stepType') }}<span class="text-red-600">*</span></label>
              <select v-model="stepForm.step" class="w-full h-[40px] border rounded px-3 bg-white">
                <option v-for="option in STEP_OPTIONS" :key="option" :value="option">
                  {{ formatStepType(option) }}
                </option>
              </select>
            </div>
            <div class="md:col-span-2 space-y-2">
              <label class="block text-sm text-gray-600">{{ t('recipe.edit.targetParams') }}</label>
              <div class="overflow-x-auto border border-gray-200 rounded-lg">
                <table class="min-w-full divide-y divide-gray-200 text-sm">
                  <thead class="bg-gray-50 text-xs uppercase text-gray-500">
                    <tr>
                      <th class="px-3 py-2 text-left">{{ t('recipe.edit.targetParamName') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('recipe.edit.targetParamTarget') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('labels.uom') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="(row, index) in targetParamRows" :key="row.key" class="bg-white">
                      <td class="px-3 py-2 align-top">
                        <input
                          v-model.trim="row.name"
                          class="w-full border rounded px-2 py-1 text-sm"
                          :placeholder="t('recipe.edit.targetParamNamePlaceholder')"
                        />
                      </td>
                      <td class="px-3 py-2 align-top">
                        <input
                          v-model.trim="row.target"
                          class="w-full border rounded px-2 py-1 text-sm"
                          :placeholder="t('recipe.edit.targetParamTargetPlaceholder')"
                        />
                      </td>
                      <td class="px-3 py-2 align-top">
                        <select v-model="row.uom_id" class="w-full border rounded px-2 py-1 bg-white text-sm">
                          <option value="">{{ t('recipe.edit.selectUom') }}</option>
                          <option v-for="uom in uoms" :key="uom.id" :value="uom.id">
                            {{ uomLabel(uom) }}
                          </option>
                        </select>
                      </td>
                      <td class="px-3 py-2 align-top text-right">
                        <button
                          type="button"
                          class="px-2 py-1 text-xs rounded border hover:bg-gray-100"
                          @click="removeTargetParamRow(index)"
                        >
                          {{ t('common.delete') }}
                        </button>
                      </td>
                    </tr>
                    <tr v-if="targetParamRows.length === 0">
                      <td colspan="4" class="px-3 py-4 text-center text-sm text-gray-500">
                        {{ t('common.noData') }}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div class="flex justify-end">
                <button
                  type="button"
                  class="px-3 py-1.5 text-sm rounded border border-dashed hover:bg-gray-50"
                  @click="addTargetParamRow"
                >
                  {{ t('recipe.edit.addTargetParam') }}
                </button>
              </div>
              <p v-if="stepErrors.target_params" class="text-xs text-red-600">{{ stepErrors.target_params }}</p>
            </div>
            <div class="md:col-span-2 space-y-2">
              <label class="block text-sm text-gray-600">{{ t('recipe.edit.qaChecks') }}</label>
              <div class="overflow-x-auto border border-gray-200 rounded-lg">
                <table class="min-w-full divide-y divide-gray-200 text-sm">
                  <thead class="bg-gray-50 text-xs uppercase text-gray-500">
                    <tr>
                      <th class="px-3 py-2 text-left">{{ t('recipe.edit.qaCheckDescription') }}</th>
                      <th class="px-3 py-2 text-left">{{ t('common.actions') }}</th>
                    </tr>
                  </thead>
                  <tbody class="divide-y divide-gray-100">
                    <tr v-for="(row, index) in qaCheckRows" :key="row.key" class="bg-white">
                      <td class="px-3 py-2 align-top">
                        <input
                          v-model.trim="row.description"
                          class="w-full border rounded px-2 py-1 text-sm"
                          :placeholder="t('recipe.edit.qaCheckPlaceholder')"
                        />
                      </td>
                      <td class="px-3 py-2 align-top text-right">
                        <button
                          type="button"
                          class="px-2 py-1 text-xs rounded border hover:bg-gray-100"
                          @click="removeQaCheckRow(index)"
                        >
                          {{ t('common.delete') }}
                        </button>
                      </td>
                    </tr>
                    <tr v-if="qaCheckRows.length === 0">
                      <td colspan="2" class="px-3 py-4 text-center text-sm text-gray-500">
                        {{ t('common.noData') }}
                      </td>
                    </tr>
                  </tbody>
                </table>
              </div>
              <div class="flex justify-end">
                <button
                  type="button"
                  class="px-3 py-1.5 text-sm rounded border border-dashed hover:bg-gray-50"
                  @click="addQaCheckRow"
                >
                  {{ t('recipe.edit.addQaCheck') }}
                </button>
              </div>
              <p v-if="stepErrors.qa_checks" class="text-xs text-red-600">{{ stepErrors.qa_checks }}</p>
            </div>
            <div class="md:col-span-2">
              <label class="block text-sm text-gray-600 mb-1">{{ t('labels.note') }}</label>
              <textarea v-model.trim="stepForm.notes" rows="3" class="w-full border rounded px-3 py-2"></textarea>
            </div>
          </div>
        </section>
        <footer class="px-4 py-3 border-t flex items-center justify-end gap-2">
          <button class="px-3 py-2 rounded border hover:bg-gray-100" @click="closeStepModal">
            {{ t('common.cancel') }}
          </button>
          <button
            class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-60"
            :disabled="stepSaving"
            @click="saveStep"
          >
            {{ stepSaving ? t('common.saving') : t('common.save') }}
          </button>
        </footer>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { supabase } from '@/lib/supabase'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

const STATUSES = ['draft', 'released', 'retired'] as const
const STEP_OPTIONS = ['mashing', 'lautering', 'boil', 'whirlpool', 'cooling', 'fermentation', 'dry_hop', 'cold_crash', 'transfer', 'packaging', 'other']
const MATERIAL_CATEGORIES = ['malt', 'hop', 'yeast', 'adjunct', 'water', 'packaging', 'chemical', 'cleaning', 'other'] as const

type MaterialCategory = (typeof MATERIAL_CATEGORIES)[number]

const route = useRoute()
const router = useRouter()
const { t } = useI18n()

const recipeId = computed(() => route.params.recipeId as string | undefined)
const pageTitle = computed(() => t('recipe.edit.title'))

interface RecipeDetail {
  id: string
  code: string
  name: string
  style: string | null
  version: number
  status: string
  batch_size_l: number | null
  target_og: number | null
  target_fg: number | null
  target_abv: number | null
  target_ibu: number | null
  target_srm: number | null
  notes: string | null
  created_at: string | null
  category: string | null
}

interface MaterialRow {
  id: string
  code: string
  name: string | null
  category: MaterialCategory
}

interface UomRow {
  id: string
  code: string
  name: string | null
}

interface CategoryRow {
  id: string
  code: string
  name: string | null
}

interface IngredientRow {
  id: string
  recipe_id: string
  material_id: string
  amount: number | null
  uom_id: string
  usage_stage: string | null
  notes: string | null
  material: { id: string; code: string; name: string | null; category: MaterialCategory | null } | null
  uom: { id: string; code: string; name: string | null } | null
}

interface StepRow {
  id: string
  process_id: string
  step_no: number
  step: string
  target_params: unknown
  qa_checks: unknown
  notes: string | null
}

interface ProcessRow {
  id: string
  recipe_id: string
  name: string
  version: number
  is_active: boolean
  notes: string | null
  steps: StepRow[]
}

interface TargetParamRow {
  key: string
  name: string
  target: string
  uom_id: string
}

interface QaCheckRow {
  key: string
  description: string
}

interface TargetParamEntry {
  name: string
  target: string
  uom_id: string
}

type QaCheckEntry = { description: string }

type StepRecord = {
  id: string
  process_id: string
  step_no: number
  step: string
  target_params: unknown
  qa_checks: unknown
  notes: string | null
}

type ProcessRecord = {
  id: string
  recipe_id: string
  name: string
  version: number
  is_active: boolean
  notes: string | null
  prc_steps?: StepRecord[]
}

const recipe = ref<RecipeDetail | null>(null)
const loadingRecipe = ref(false)
const savingRecipe = ref(false)
const versioning = ref(false)
const recipeErrors = reactive<Record<string, string>>({})
const recipeForm = reactive({
  code: '',
  name: '',
  style: '',
  category: '',
  version: 1,
  status: STATUSES[0],
  batch_size_l: '',
  target_og: '',
  target_fg: '',
  target_abv: '',
  target_ibu: '',
  target_srm: '',
  notes: '',
})

const materials = ref<MaterialRow[]>([])
const uoms = ref<UomRow[]>([])
const categories = ref<CategoryRow[]>([])
const ingredients = ref<IngredientRow[]>([])
const materialCategoryFilter = ref<'all' | MaterialCategory>('all')
const ingredientsLoading = ref(false)
const ingredientSaving = ref(false)
const ingredientErrors = reactive<Record<string, string>>({})
const showIngredientModal = ref(false)
const editingIngredient = ref(false)
const ingredientForm = reactive({
  id: '',
  material_id: '',
  uom_id: '',
  amount: '',
  usage_stage: '',
  notes: '',
})

const processes = ref<ProcessRow[]>([])
const processesLoading = ref(false)
const processSaving = ref(false)
const processErrors = reactive<Record<string, string>>({})
const showProcessModal = ref(false)
const editingProcess = ref(false)
const processForm = reactive({
  id: '',
  name: '',
  version: 1,
  is_active: true,
  notes: '',
})

const showStepModal = ref(false)
const editingStep = ref(false)
const stepSaving = ref(false)
const currentProcess = ref<ProcessRow | null>(null)
const stepErrors = reactive<Record<string, string>>({})
const stepForm = reactive({
  id: '',
  step_no: 1,
  step: STEP_OPTIONS[0],
  notes: '',
})

let targetParamRowId = 0
let qaCheckRowId = 0

const targetParamRows = ref<TargetParamRow[]>([])
const qaCheckRows = ref<QaCheckRow[]>([])

const statusLabel = (status: string) => {
  const key = `recipe.statusMap.${status}`
  const label = t(key)
  return label === key ? status : label
}

const formatStepType = (value: string) => {
  if (!value) return ''
  return value
    .split('_')
    .map((part) => part.charAt(0).toUpperCase() + part.slice(1))
    .join(' ')
}

function materialCategoryLabel(value: string | null | undefined) {
  if (!value) return ''
  const key = `material.categories.${value}`
  const translated = t(key as any)
  return translated === key ? value : translated
}

const uomLabel = (row: UomRow) => {
  if (!row) return ''
  return row.name ? `${row.code} — ${row.name}` : row.code
}

const uomLookup = computed(() => {
  const map = new Map<string, UomRow>()
  for (const item of uoms.value) {
    map.set(item.id, item)
  }
  return map
})

const materialTypeOptions = computed(() => [
  { value: 'all' as const, label: t('common.all') },
  ...MATERIAL_CATEGORIES.map((category) => ({ value: category, label: materialCategoryLabel(category) })),
])

const materialMap = computed(() => {
  const map = new Map<string, MaterialRow>()
  for (const item of materials.value) {
    map.set(item.id, item)
  }
  return map
})

const filteredIngredients = computed(() => {
  const filter = materialCategoryFilter.value
  if (filter === 'all') return ingredients.value
  return ingredients.value.filter((row) => {
    const category = row.material?.category ?? materialMap.value.get(row.material_id)?.category ?? null
    return category === filter
  })
})

const ingredientCategoryLabel = (row: IngredientRow) => {
  const category = row.material?.category ?? materialMap.value.get(row.material_id)?.category ?? null
  return category ? materialCategoryLabel(category) : ''
}

function createTargetParamRow(initial?: Partial<Omit<TargetParamRow, 'key'>>) {
  return {
    key: `tp-${++targetParamRowId}`,
    name: initial?.name ?? '',
    target: initial?.target ?? '',
    uom_id: initial?.uom_id ?? '',
  }
}

function createQaCheckRow(initial?: Partial<Omit<QaCheckRow, 'key'>>) {
  return {
    key: `qa-${++qaCheckRowId}`,
    description: initial?.description ?? '',
  }
}

targetParamRows.value = [createTargetParamRow()]
qaCheckRows.value = [createQaCheckRow()]

function extractTargetParamEntries(value: unknown): TargetParamEntry[] {
  const parsed = parseJsonLike(value)
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) return []

  const entries: TargetParamEntry[] = []
  for (const [name, raw] of Object.entries(parsed as Record<string, unknown>)) {
    if (!name) continue
    let target = ''
    let uom_id = ''

    if (raw && typeof raw === 'object' && !Array.isArray(raw)) {
      const rawObj = raw as Record<string, unknown>
      const rawTarget = rawObj.target ?? rawObj.value ?? null
      target = rawTarget == null ? '' : String(rawTarget)
      const uomValue = rawObj.uom_id ?? rawObj.uom ?? null
      if (typeof uomValue === 'string') uom_id = uomValue
    } else {
      target = raw == null ? '' : String(raw)
    }

    entries.push({ name, target, uom_id })
  }
  return entries
}

function extractQaCheckEntries(value: unknown): QaCheckEntry[] {
  const parsed = parseJsonLike(value)
  if (Array.isArray(parsed)) {
    return parsed
      .map((item) => (item == null ? '' : String(item).trim()))
      .filter((item): item is string => item.length > 0)
      .map((description) => ({ description }))
  }
  if (typeof parsed === 'string') {
    const trimmed = parsed.trim()
    return trimmed ? [{ description: trimmed }] : []
  }
  return []
}

function parseJsonLike(value: unknown) {
  if (typeof value !== 'string') return value
  try {
    return JSON.parse(value)
  } catch {
    return null
  }
}

function hydrateTargetParamRows(value: unknown) {
  const entries = extractTargetParamEntries(value)
  return entries.map((entry) => createTargetParamRow(entry))
}

function hydrateQaCheckRows(value: unknown) {
  const entries = extractQaCheckEntries(value)
  return entries.map((entry) => createQaCheckRow(entry))
}

function normalizeTargetValue(value: string) {
  const trimmed = value.trim()
  if (!trimmed) return null
  const numeric = Number(trimmed)
  return Number.isNaN(numeric) ? trimmed : numeric
}

const targetParamSummary = (value: unknown) => {
  const entries = extractTargetParamEntries(value)
  return entries.map((entry) => {
    const uom = entry.uom_id ? uomLookup.value.get(entry.uom_id) : undefined
    const labelParts: string[] = []
    if (entry.target) labelParts.push(entry.target)
    if (uom) labelParts.push(uom.name || uom.code)
    return {
      ...entry,
      display: labelParts.join(' '),
    }
  })
}

const qaChecksSummary = (value: unknown) => extractQaCheckEntries(value).map((entry) => entry.description)

const materialLabel = (row: IngredientRow) => {
  if (row.material?.name) return row.material.name
  if (row.material?.code) return row.material.code
  const fallback = materialMap.value.get(row.material_id)
  if (fallback?.name) return fallback.name
  if (fallback?.code) return fallback.code
  return row.material_id
}

function numberOrNull(value: string) {
  if (value === null || value === undefined || value === '') return null
  const num = Number(value)
  return Number.isNaN(num) ? null : num
}

function resetRecipeErrors() {
  Object.keys(recipeErrors).forEach((key) => delete recipeErrors[key])
}

async function versionUp() {
  if (!recipeId.value || versioning.value) return

  resetRecipeErrors()
  if (!recipeForm.code) recipeErrors.code = t('errors.required', { field: t('recipe.list.recipeId') })
  if (!recipeForm.name) recipeErrors.name = t('errors.required', { field: t('recipe.list.name') })
  if (Object.keys(recipeErrors).length > 0) return

  versioning.value = true

  const trimmedCode = recipeForm.code.trim()
  const trimmedName = recipeForm.name.trim()
  const trimmedStyle = recipeForm.style.trim()

  const basePayload = {
    code: trimmedCode,
    name: trimmedName,
    style: trimmedStyle || null,
    version: recipeForm.version || 1,
    status: recipeForm.status,
    category: recipeForm.category || null,
    batch_size_l: numberOrNull(recipeForm.batch_size_l),
    target_og: numberOrNull(recipeForm.target_og),
    target_fg: numberOrNull(recipeForm.target_fg),
    target_abv: numberOrNull(recipeForm.target_abv),
    target_ibu: numberOrNull(recipeForm.target_ibu),
    target_srm: numberOrNull(recipeForm.target_srm),
    notes: recipeForm.notes.trim() || null,
  }

  try {
    const { error: updateError } = await supabase
      .from('rcp_recipes')
      .update(basePayload)
      .eq('id', recipeId.value)
    if (updateError) throw updateError

    const { data: versionRows, error: versionError } = await supabase
      .from('rcp_recipes')
      .select('version')
      .eq('code', trimmedCode)
      .order('version', { ascending: false })
      .limit(1)
    if (versionError) throw versionError

    const highestVersion = versionRows?.[0]?.version ?? basePayload.version ?? 0
    const newVersion = highestVersion + 1

    const newRecipePayload = {
      ...basePayload,
      version: newVersion,
      status: 'draft',
    }

    const { data: inserted, error: insertError } = await supabase
      .from('rcp_recipes')
      .insert(newRecipePayload)
      .select('id, code, name, style, version, status, batch_size_l, target_og, target_fg, target_abv, target_ibu, target_srm, notes, created_at, category')
      .single()
    if (insertError || !inserted) throw insertError ?? new Error('Insert failed')

    const { data: ingredientRows, error: ingredientError } = await supabase
      .from('rcp_ingredients')
      .select('material_id, amount, uom_id, usage_stage, notes')
      .eq('recipe_id', recipeId.value)
    if (ingredientError) throw ingredientError

    if (ingredientRows && ingredientRows.length > 0) {
      const ingredientPayload = ingredientRows.map((item) => ({
        recipe_id: inserted.id,
        material_id: item.material_id,
        amount: item.amount,
        uom_id: item.uom_id,
        usage_stage: item.usage_stage,
        notes: item.notes,
      }))
      const { error: ingredientInsertError } = await supabase
        .from('rcp_ingredients')
        .insert(ingredientPayload)
      if (ingredientInsertError) throw ingredientInsertError
    }

    const { data: processRows, error: processError } = await supabase
      .from('prc_processes')
      .select('id, name, version, is_active, notes, prc_steps(id, step_no, step, target_params, qa_checks, notes)')
      .eq('recipe_id', recipeId.value)
    if (processError) throw processError

    if (processRows && processRows.length > 0) {
      type StepRecord = {
        id: string
        process_id: string
        step_no: number
        step: string
        target_params: unknown
        qa_checks: unknown
        notes: string | null
      }

      type ProcessRecord = {
        id: string
        name: string
        version: number
        is_active: boolean
        notes: string | null
        prc_steps?: StepRecord[]
      }

      const parseObject = (value: unknown) => {
        if (value && typeof value === 'object' && !Array.isArray(value)) return value as Record<string, unknown>
        if (typeof value === 'string') {
          try {
            const parsed = JSON.parse(value)
            return parsed && typeof parsed === 'object' && !Array.isArray(parsed)
              ? (parsed as Record<string, unknown>)
              : {}
          } catch {
            return {}
          }
        }
        return {}
      }

      const parseArray = (value: unknown) => {
        if (Array.isArray(value)) return value as unknown[]
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

      for (const process of processRows as ProcessRecord[]) {
        const { data: createdProcess, error: processInsertError } = await supabase
          .from('prc_processes')
          .insert({
            recipe_id: inserted.id,
            name: process.name,
            version: process.version,
            is_active: process.is_active,
            notes: process.notes,
          })
          .select('id')
          .single()
        if (processInsertError || !createdProcess) throw processInsertError ?? new Error('Process copy failed')

        const steps = process.prc_steps ?? []
        if (steps.length > 0) {
          const stepPayload = steps.map((step) => ({
            process_id: createdProcess.id,
            step_no: step.step_no,
            step: step.step,
            target_params: parseObject(step.target_params),
            qa_checks: parseArray(step.qa_checks),
            notes: step.notes,
          }))
          const { error: stepInsertError } = await supabase
            .from('prc_steps')
            .insert(stepPayload)
          if (stepInsertError) throw stepInsertError
        }
      }
    }

    await router.replace(`/recipeEdit/${inserted.id}/${inserted.version}`)
    await loadRecipe()
    toast.success(t('recipe.edit.versionUpDone', { version: inserted.version }))
  } catch (error: unknown) {
    const message = error instanceof Error ? error.message : String(error)
    toast.error(t('recipe.edit.versionUpError', { message }))
  } finally {
    versioning.value = false
  }
}

async function loadRecipe() {
  if (!recipeId.value) {
    toast.error('Missing recipe id')
    router.push('/recipeList')
    return
  }
  loadingRecipe.value = true
  const { data, error } = await supabase
    .from('rcp_recipes')
    .select('id, code, name, style, version, status, batch_size_l, target_og, target_fg, target_abv, target_ibu, target_srm, notes, created_at, category')
    .eq('id', recipeId.value)
    .single()
  loadingRecipe.value = false
  if (error || !data) {
    toast.error('Failed to load recipe: ' + (error?.message ?? ''))
    router.push('/recipeList')
    return
  }
  recipe.value = data
  recipeForm.code = data.code ?? ''
  recipeForm.name = data.name ?? ''
  recipeForm.style = data.style ?? ''
  recipeForm.category = data.category ?? ''
  recipeForm.version = data.version ?? 1
  recipeForm.status = (STATUSES.includes(data.status as typeof STATUSES[number]) ? data.status : STATUSES[0]) as typeof STATUSES[number]
  recipeForm.batch_size_l = data.batch_size_l != null ? String(data.batch_size_l) : ''
  recipeForm.target_og = data.target_og != null ? String(data.target_og) : ''
  recipeForm.target_fg = data.target_fg != null ? String(data.target_fg) : ''
  recipeForm.target_abv = data.target_abv != null ? String(data.target_abv) : ''
  recipeForm.target_ibu = data.target_ibu != null ? String(data.target_ibu) : ''
  recipeForm.target_srm = data.target_srm != null ? String(data.target_srm) : ''
  recipeForm.notes = data.notes ?? ''

  await Promise.all([loadIngredients(), loadProcesses()])
}

async function loadMaterials() {
  const { data, error } = await supabase
    .from('mst_materials')
    .select('id, code, name, category')
    .order('code', { ascending: true })
  if (error) {
    console.warn('Load materials failed', error)
    return
  }
  materials.value = data ?? []
}

async function loadUoms() {
  const { data, error } = await supabase
    .from('mst_uom')
    .select('id, code, name')
    .order('code', { ascending: true })
  if (error) {
    console.warn('Load uom failed', error)
    return
  }
  uoms.value = data ?? []
}

async function loadCategories() {
  const { data, error } = await supabase
    .from('mst_category')
    .select('id, code, name')
    .order('name', { ascending: true, nullsFirst: false })
  if (error) {
    console.warn('Load categories failed', error)
    return
  }
  categories.value = data ?? []
}

async function loadIngredients() {
  if (!recipeId.value) return
  ingredientsLoading.value = true
  const { data, error } = await supabase
    .from('rcp_ingredients')
    .select('id, recipe_id, material_id, amount, uom_id, usage_stage, notes, material:material_id(id, code, name, category), uom:uom_id(id, code, name)')
    .eq('recipe_id', recipeId.value)
    .order('usage_stage', { ascending: true, nullsLast: true })
    .order('material_id', { ascending: true })
  ingredientsLoading.value = false
  if (error) {
    toast.error('Failed to load ingredients: ' + error.message)
    return
  }
  ingredients.value = (data ?? []) as IngredientRow[]
}

function resetIngredientForm() {
  ingredientForm.id = ''
  ingredientForm.material_id = ''
  ingredientForm.uom_id = ''
  ingredientForm.amount = ''
  ingredientForm.usage_stage = ''
  ingredientForm.notes = ''
  Object.keys(ingredientErrors).forEach((key) => delete ingredientErrors[key])
}

function openIngredientCreate() {
  editingIngredient.value = false
  resetIngredientForm()
  showIngredientModal.value = true
}

function openIngredientEdit(row: IngredientRow) {
  editingIngredient.value = true
  resetIngredientForm()
  ingredientForm.id = row.id
  ingredientForm.material_id = row.material_id
  ingredientForm.uom_id = row.uom_id
  ingredientForm.amount = row.amount != null ? String(row.amount) : ''
  ingredientForm.usage_stage = row.usage_stage ?? ''
  ingredientForm.notes = row.notes ?? ''
  showIngredientModal.value = true
}

function closeIngredientModal() {
  showIngredientModal.value = false
}

function validateIngredient() {
  Object.keys(ingredientErrors).forEach((key) => delete ingredientErrors[key])
  if (!ingredientForm.material_id) ingredientErrors.material = t('errors.required', { field: t('recipe.edit.materialColumn') })
  if (!ingredientForm.uom_id) ingredientErrors.uom = t('errors.required', { field: t('labels.uom') })
  return Object.keys(ingredientErrors).length === 0
}

async function saveIngredient() {
  if (!recipeId.value) return
  if (!validateIngredient()) return

  ingredientSaving.value = true
  const payload = {
    recipe_id: recipeId.value,
    material_id: ingredientForm.material_id,
    uom_id: ingredientForm.uom_id,
    amount: ingredientForm.amount !== '' ? Number(ingredientForm.amount) : null,
    usage_stage: ingredientForm.usage_stage.trim() || null,
    notes: ingredientForm.notes.trim() || null,
  }

  let response
  if (editingIngredient.value && ingredientForm.id) {
    response = await supabase
      .from('rcp_ingredients')
      .update(payload)
      .eq('id', ingredientForm.id)
      .select('id')
      .single()
  } else {
    response = await supabase
      .from('rcp_ingredients')
      .insert(payload)
      .select('id')
      .single()
  }

  ingredientSaving.value = false
  if (response.error) {
    toast.error('Failed to save ingredient: ' + response.error.message)
    return
  }

  closeIngredientModal()
  await loadIngredients()
}

async function deleteIngredient(row: IngredientRow) {
  if (!confirm(t('recipe.edit.deleteIngredientConfirm', { name: materialLabel(row) }))) return
  const { error } = await supabase.from('rcp_ingredients').delete().eq('id', row.id)
  if (error) {
    toast.error('Failed to delete ingredient: ' + error.message)
    return
  }
  ingredients.value = ingredients.value.filter((item) => item.id !== row.id)
}

async function loadProcesses() {
  if (!recipeId.value) return
  processesLoading.value = true
  const { data, error } = await supabase
    .from('prc_processes')
    .select('id, recipe_id, name, version, is_active, notes, prc_steps(id, process_id, step_no, step, target_params, qa_checks, notes)')
    .eq('recipe_id', recipeId.value)
    .order('version', { ascending: false })
    .order('step_no', { foreignTable: 'prc_steps', ascending: true })
  processesLoading.value = false
  if (error) {
    toast.error('Failed to load processes: ' + error.message)
    return
  }

  const rows = (data ?? []) as ProcessRecord[]
  processes.value = rows.map((item) => ({
    id: item.id,
    recipe_id: item.recipe_id,
    name: item.name,
    version: item.version,
    is_active: item.is_active,
    notes: item.notes,
    steps: (item.prc_steps ?? []).map((step) => ({
      id: step.id,
      process_id: step.process_id,
      step_no: step.step_no,
      step: step.step,
      target_params: step.target_params,
      qa_checks: step.qa_checks,
      notes: step.notes,
    })),
  }))
}

function resetProcessForm() {
  processForm.id = ''
  processForm.name = ''
  processForm.version = 1
  processForm.is_active = true
  processForm.notes = ''
  Object.keys(processErrors).forEach((key) => delete processErrors[key])
}

function openProcessCreate() {
  editingProcess.value = false
  resetProcessForm()
  if (processes.value.length > 0) {
    const maxVersion = Math.max(...processes.value.map((p) => p.version))
    processForm.version = maxVersion + 1
  }
  showProcessModal.value = true
}

function openProcessEdit(process: ProcessRow) {
  editingProcess.value = true
  resetProcessForm()
  processForm.id = process.id
  processForm.name = process.name
  processForm.version = process.version
  processForm.is_active = process.is_active
  processForm.notes = process.notes ?? ''
  showProcessModal.value = true
}

function closeProcessModal() {
  showProcessModal.value = false
}

function validateProcess() {
  Object.keys(processErrors).forEach((key) => delete processErrors[key])
  if (!processForm.name) processErrors.name = t('errors.required', { field: t('labels.name') })
  return Object.keys(processErrors).length === 0
}

async function saveProcess() {
  if (!recipeId.value) return
  if (!validateProcess()) return

  processSaving.value = true
  const payload = {
    recipe_id: recipeId.value,
    name: processForm.name.trim(),
    version: processForm.version || 1,
    is_active: processForm.is_active,
    notes: processForm.notes.trim() || null,
  }

  let response
  if (editingProcess.value && processForm.id) {
    response = await supabase
      .from('prc_processes')
      .update(payload)
      .eq('id', processForm.id)
      .select('id')
      .single()
  } else {
    response = await supabase
      .from('prc_processes')
      .insert(payload)
      .select('id')
      .single()
  }

  processSaving.value = false
  if (response.error) {
    toast.error('Failed to save process: ' + response.error.message)
    return
  }

  closeProcessModal()
  await loadProcesses()
}

async function deleteProcess(process: ProcessRow) {
  if (!confirm(t('recipe.edit.deleteProcessConfirm', { name: process.name, version: process.version }))) return
  const { error } = await supabase.from('prc_processes').delete().eq('id', process.id)
  if (error) {
    toast.error('Failed to delete process: ' + error.message)
    return
  }
  await loadProcesses()
}

function resetStepForm() {
  stepForm.id = ''
  stepForm.step_no = 1
  stepForm.step = STEP_OPTIONS[0]
  stepForm.notes = ''
  targetParamRows.value = [createTargetParamRow()]
  qaCheckRows.value = [createQaCheckRow()]
  Object.keys(stepErrors).forEach((key) => delete stepErrors[key])
}

function addTargetParamRow() {
  targetParamRows.value.push(createTargetParamRow())
}

function removeTargetParamRow(index: number) {
  if (index < 0 || index >= targetParamRows.value.length) return
  targetParamRows.value.splice(index, 1)
  if (targetParamRows.value.length === 0) {
    targetParamRows.value.push(createTargetParamRow())
  }
}

function addQaCheckRow() {
  qaCheckRows.value.push(createQaCheckRow())
}

function removeQaCheckRow(index: number) {
  if (index < 0 || index >= qaCheckRows.value.length) return
  qaCheckRows.value.splice(index, 1)
  if (qaCheckRows.value.length === 0) {
    qaCheckRows.value.push(createQaCheckRow())
  }
}

function openStepCreate(process: ProcessRow) {
  currentProcess.value = process
  editingStep.value = false
  resetStepForm()
  const maxNo = process.steps.length > 0 ? Math.max(...process.steps.map((s) => s.step_no)) : 0
  stepForm.step_no = maxNo + 1
  showStepModal.value = true
}

function openStepEdit(process: ProcessRow, step: StepRow) {
  currentProcess.value = process
  editingStep.value = true
  resetStepForm()
  stepForm.id = step.id
  stepForm.step_no = step.step_no
  stepForm.step = STEP_OPTIONS.includes(step.step) ? step.step : STEP_OPTIONS[0]
  stepForm.notes = step.notes ?? ''
  const hydratedParams = hydrateTargetParamRows(step.target_params)
  targetParamRows.value = hydratedParams.length > 0 ? hydratedParams : [createTargetParamRow()]
  const hydratedQa = hydrateQaCheckRows(step.qa_checks)
  qaCheckRows.value = hydratedQa.length > 0 ? hydratedQa : [createQaCheckRow()]
  showStepModal.value = true
}

function closeStepModal() {
  showStepModal.value = false
}

async function saveRecipeInfo() {
  if (!recipeId.value) return
  resetRecipeErrors()
  if (!recipeForm.code) recipeErrors.code = t('errors.required', { field: t('recipe.list.recipeId') })
  if (!recipeForm.name) recipeErrors.name = t('errors.required', { field: t('recipe.list.name') })
  if (Object.keys(recipeErrors).length > 0) return

  const payload = {
    code: recipeForm.code.trim(),
    name: recipeForm.name.trim(),
    style: recipeForm.style.trim() || null,
    version: recipeForm.version || 1,
    status: recipeForm.status,
    category: recipeForm.category || null,
    batch_size_l: numberOrNull(recipeForm.batch_size_l),
    target_og: numberOrNull(recipeForm.target_og),
    target_fg: numberOrNull(recipeForm.target_fg),
    target_abv: numberOrNull(recipeForm.target_abv),
    target_ibu: numberOrNull(recipeForm.target_ibu),
    target_srm: numberOrNull(recipeForm.target_srm),
    notes: recipeForm.notes.trim() || null,
  }

  savingRecipe.value = true
  const { data, error } = await supabase
    .from('rcp_recipes')
    .update(payload)
    .eq('id', recipeId.value)
    .select('id, code, name, style, version, status, batch_size_l, target_og, target_fg, target_abv, target_ibu, target_srm, notes, created_at, category')
    .single()
  savingRecipe.value = false
  if (error || !data) {
    toast.error('Failed to save recipe: ' + (error?.message ?? ''))
    return
  }
  recipe.value = data
  recipeForm.category = data.category ?? ''
  toast.success(t('recipe.edit.recipeSaved'))
}

async function saveStep() {
  if (!currentProcess.value) return
  Object.keys(stepErrors).forEach((key) => delete stepErrors[key])
  if (!stepForm.step_no || stepForm.step_no < 1) {
    stepErrors.step_no = t('errors.mustBeInteger', { field: t('recipe.edit.stepNumber') })
    return
  }

  const normalizedTargetRows = targetParamRows.value
    .map((row) => ({
      name: row.name.trim(),
      target: row.target.trim(),
      uom_id: row.uom_id,
    }))
    .filter((row) => row.name || row.target || row.uom_id)

  if (normalizedTargetRows.some((row) => !row.name)) {
    stepErrors.target_params = t('recipe.edit.targetParamNameRequired')
    return
  }

  const seen = new Set<string>()
  for (const row of normalizedTargetRows) {
    const key = row.name.toLowerCase()
    if (seen.has(key)) {
      stepErrors.target_params = t('recipe.edit.targetParamDuplicate')
      return
    }
    seen.add(key)
  }

  const targetParams: Record<string, unknown> = {}
  for (const row of normalizedTargetRows) {
    const value = normalizeTargetValue(row.target)
    if (!row.uom_id && value !== null) {
      targetParams[row.name] = value
    } else {
      const entry: Record<string, unknown> = {}
      if (value !== null) entry.target = value
      if (row.uom_id) entry.uom_id = row.uom_id
      targetParams[row.name] = entry
    }
  }

  const qaChecks = qaCheckRows.value
    .map((row) => row.description.trim())
    .filter((value) => value.length > 0)

  stepSaving.value = true
  const payload = {
    process_id: currentProcess.value.id,
    step_no: stepForm.step_no,
    step: stepForm.step,
    target_params: Object.keys(targetParams).length > 0 ? targetParams : {},
    qa_checks: qaChecks,
    notes: stepForm.notes.trim() || null,
  }

  let response
  if (editingStep.value && stepForm.id) {
    response = await supabase
      .from('prc_steps')
      .update(payload)
      .eq('id', stepForm.id)
      .select('id')
      .single()
  } else {
    response = await supabase
      .from('prc_steps')
      .insert(payload)
      .select('id')
      .single()
  }

  stepSaving.value = false
  if (response.error) {
    toast.error('Failed to save step: ' + response.error.message)
    return
  }

  closeStepModal()
  await loadProcesses()
}

async function deleteStep(process: ProcessRow, step: StepRow) {
  if (!confirm(t('recipe.edit.deleteStepConfirm', { step: formatStepType(step.step), number: step.step_no }))) return
  const { error } = await supabase.from('prc_steps').delete().eq('id', step.id)
  if (error) {
    toast.error('Failed to delete step: ' + error.message)
    return
  }
  await loadProcesses()
}

onMounted(async () => {
  await Promise.all([loadMaterials(), loadUoms(), loadCategories()])
  await loadRecipe()
})
</script>
