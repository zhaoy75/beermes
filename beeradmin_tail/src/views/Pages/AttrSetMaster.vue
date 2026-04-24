<template>
  <SystemAdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4">
      <header class="mb-4 flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h1 class="text-xl font-semibold">{{ t('attrSet.title') }}</h1>
          <p class="text-sm text-gray-500">{{ t('attrSet.subtitle') }}</p>
        </div>
        <div class="flex flex-wrap items-center gap-2">
          <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="openCreateSet">
            {{ t('common.new') }}
          </button>
          <button
            class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
            :disabled="loading"
            @click="refreshAll"
          >
            {{ t('common.refresh') }}
          </button>
        </div>
      </header>

      <section class="mb-4 border border-gray-200 rounded-xl shadow-sm p-4">
        <div class="flex flex-col gap-2 md:flex-row md:items-center md:gap-4">
          <label class="text-sm font-medium text-gray-700" for="attr-set-domain-filter">
            {{ t('attrSet.filters.domain') }}
          </label>
          <select
            id="attr-set-domain-filter"
            v-model="selectedDomain"
            class="h-[40px] min-w-[220px] rounded border border-gray-300 bg-white px-3 text-sm"
          >
            <option :value="ALL_DOMAINS">{{ t('common.all') }}</option>
            <option v-for="domain in domainOptions" :key="domain" :value="domain">
              {{ domain }}
            </option>
          </select>
        </div>
      </section>

      <section class="grid grid-cols-1 lg:grid-cols-[320px_1fr] gap-4">
        <aside class="border border-gray-200 rounded-xl shadow-sm p-3 h-[calc(100vh-200px)] overflow-y-auto">
          <div class="mb-3">
            <h2 class="text-sm font-semibold text-gray-700">{{ t('attrSet.palette.title') }}</h2>
            <p class="text-xs text-gray-500">{{ t('attrSet.palette.subtitle') }}</p>
          </div>
          <input
            v-model.trim="paletteFilter"
            class="w-full h-[38px] border rounded px-3 text-sm mb-3"
            :placeholder="t('attrSet.palette.searchPlaceholder')"
          />

          <div v-if="loading" class="text-sm text-gray-500 py-4">{{ t('common.loading') }}</div>
          <div v-else-if="paletteGroups.length === 0" class="text-sm text-gray-500 py-4">
            {{ t('common.noData') }}
          </div>
          <div v-else class="space-y-3">
            <div v-for="group in paletteGroups" :key="group.key" class="border border-gray-200 rounded-lg">
              <div class="px-3 py-2 bg-gray-50 text-xs font-semibold text-gray-600">
                {{ group.label }}
              </div>
              <ul class="divide-y divide-gray-100">
                <li
                  v-for="attr in group.items"
                  :key="attr.attr_id"
                  class="px-3 py-2 text-xs flex items-start gap-2 cursor-grab hover:bg-gray-50"
                  draggable="true"
                  @dragstart="onAttrDragStart($event, attr)"
                >
                  <div class="flex-1">
                    <div class="font-mono text-[11px] text-gray-700">{{ attr.code }}</div>
                    <div class="text-gray-800">{{ attr.name }}</div>
                    <div v-if="displayNameI18n(attr)" class="text-[11px] text-gray-500">
                      {{ displayNameI18n(attr) }}
                    </div>
                  </div>
                  <span class="text-[10px] text-gray-400">{{ dataTypeLabel(attr.data_type) }}</span>
                </li>
              </ul>
            </div>
          </div>
        </aside>

        <div class="space-y-4">
          <div class="border border-gray-200 rounded-xl shadow-sm p-4">
            <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
              <div>
                <p class="text-xs text-gray-500">{{ t('attrSet.canvas.title') }}</p>
                <h2 class="text-lg font-semibold">
                  {{ selectedSet?.name || t('attrSet.canvas.noSelection') }}
                </h2>
                <p v-if="selectedSet" class="text-xs text-gray-500 font-mono">
                  {{ selectedSet.code }}
                </p>
              </div>
              <div class="flex flex-wrap gap-2">
                <button
                  class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
                  :disabled="!selectedSet"
                  @click="openPreview"
                >
                  {{ t('attrSet.actions.preview') }}
                </button>
                <button
                  class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700 disabled:opacity-50"
                  :disabled="!selectedSet || saving"
                  @click="saveSelectedSet"
                >
                  {{ saving ? t('common.saving') : t('common.save') }}
                </button>
              </div>
            </div>
          </div>

          <div class="border border-gray-200 rounded-xl shadow-sm">
            <div class="px-4 py-3 border-b flex items-center justify-between">
              <div>
                <h3 class="text-sm font-semibold text-gray-700">{{ t('attrSet.list.title') }}</h3>
                <p class="text-xs text-gray-500">{{ t('attrSet.list.subtitle') }}</p>
              </div>
            </div>
            <div class="p-3 grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
              <div
                v-for="set in filteredAttrSets"
                :key="set.attr_set_id"
                class="border rounded-lg p-3 cursor-pointer hover:border-blue-300"
                :class="set.attr_set_id === selectedSetId ? 'border-blue-500 bg-blue-50/40' : 'border-gray-200'"
                @click="selectSet(set.attr_set_id)"
                @contextmenu.prevent="openContextMenu($event, set)"
              >
                <div class="text-xs text-gray-500">{{ set.domain }}</div>
                <div class="font-semibold text-gray-800">{{ set.name }}</div>
                <div class="text-xs font-mono text-gray-500">{{ set.code }}</div>
                <div class="mt-2 text-[11px] text-gray-500">
                  {{ industryLabel(set.industry_id) }} · {{ set.is_active ? t('common.yes') : t('common.no') }}
                </div>
              </div>
            </div>
          </div>

          <div
            class="border border-dashed border-gray-300 rounded-xl p-4 min-h-[240px]"
            @dragover.prevent
            @drop.prevent="onAttrDrop"
          >
            <div class="flex items-center justify-between mb-2">
              <h3 class="text-sm font-semibold text-gray-700">{{ t('attrSet.rules.title') }}</h3>
              <button
                class="text-xs px-2 py-1 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
                :disabled="!selectedSet"
                @click="openRulesDialog"
              >
                {{ t('attrSet.actions.editRules') }}
              </button>
            </div>
            <div v-if="!selectedSet" class="text-sm text-gray-500">{{ t('attrSet.canvas.noSelectionHint') }}</div>
            <div v-else-if="rulesForSelected.length === 0" class="text-sm text-gray-500">
              {{ t('attrSet.rules.emptyHint') }}
            </div>
            <div v-else class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200 text-sm">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                      <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setRuleSort('code')">
                        <span>{{ t('attrSet.rules.code') }}</span>
                        <span v-if="ruleSortIcon('code')" class="text-xs">{{ ruleSortIcon('code') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                      <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setRuleSort('name')">
                        <span>{{ t('attrSet.rules.name') }}</span>
                        <span v-if="ruleSortIcon('name')" class="text-xs">{{ ruleSortIcon('name') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                      <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setRuleSort('required')">
                        <span>{{ t('attrSet.rules.required') }}</span>
                        <span v-if="ruleSortIcon('required')" class="text-xs">{{ ruleSortIcon('required') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                      <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setRuleSort('editable')">
                        <span>{{ t('attrSet.rules.editable') }}</span>
                        <span v-if="ruleSortIcon('editable')" class="text-xs">{{ ruleSortIcon('editable') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                      <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setRuleSort('visible')">
                        <span>{{ t('attrSet.rules.visible') }}</span>
                        <span v-if="ruleSortIcon('visible')" class="text-xs">{{ ruleSortIcon('visible') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                      <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setRuleSort('defaultValue')">
                        <span>{{ t('attrSet.rules.defaultValue') }}</span>
                        <span v-if="ruleSortIcon('defaultValue')" class="text-xs">{{ ruleSortIcon('defaultValue') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">{{ t('common.actions') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="rule in sortedRulesForSelected" :key="rule.attr_id" class="hover:bg-gray-50">
                    <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ rule.code }}</td>
                    <td class="px-3 py-2">
                      <div>{{ rule.name }}</div>
                      <div v-if="rule.name_i18n" class="text-xs text-gray-500">
                        {{ displayNameI18n(rule) }}
                      </div>
                    </td>
                    <td class="px-3 py-2">
                      <input v-model="rule.required" type="checkbox" class="h-4 w-4" />
                    </td>
                    <td class="px-3 py-2">
                      <input v-model="rule.editable" type="checkbox" class="h-4 w-4" />
                    </td>
                    <td class="px-3 py-2">
                      <input v-model="rule.visible" type="checkbox" class="h-4 w-4" />
                    </td>
                    <td class="px-3 py-2">
                      <input v-model.trim="rule.default_value" class="h-[32px] border rounded px-2 text-xs w-full" />
                    </td>
                    <td class="px-3 py-2">
                      <div class="flex items-center gap-2">
                        <button
                          class="inline-flex h-7 w-7 items-center justify-center rounded border border-gray-300 text-xs hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-40"
                          :disabled="!canMoveRuleUp(rule.attr_id)"
                          title="Move up"
                          @click="moveRuleUp(rule.attr_id)"
                        >
                          ↑
                        </button>
                        <button
                          class="inline-flex h-7 w-7 items-center justify-center rounded border border-gray-300 text-xs hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-40"
                          :disabled="!canMoveRuleDown(rule.attr_id)"
                          title="Move down"
                          @click="moveRuleDown(rule.attr_id)"
                        >
                          ↓
                        </button>
                        <button class="text-xs text-red-600 hover:underline" @click="removeRule(rule.attr_id)">
                          {{ t('common.delete') }}
                        </button>
                      </div>
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
        </div>
      </section>

      <div
        v-if="contextMenu.open"
        class="fixed inset-0 z-50"
        @click="closeContextMenu"
      >
        <div
          class="absolute bg-white border border-gray-200 rounded shadow-lg text-sm"
          :style="{ top: `${contextMenu.y}px`, left: `${contextMenu.x}px` }"
        >
          <button class="block w-full text-left px-3 py-2 hover:bg-gray-50" @click="contextMenuEdit">
            {{ t('common.edit') }}
          </button>
          <button class="block w-full text-left px-3 py-2 hover:bg-gray-50" @click="contextMenuPreview">
            {{ t('attrSet.actions.preview') }}
          </button>
          <button class="block w-full text-left px-3 py-2 hover:bg-gray-50" @click="contextMenuEditRules">
            {{ t('attrSet.actions.editRules') }}
          </button>
          <button class="block w-full text-left px-3 py-2 hover:bg-gray-50" @click="contextMenuSave">
            {{ t('attrSet.actions.save') }}
          </button>
          <button class="block w-full text-left px-3 py-2 text-red-600 hover:bg-red-50" @click="contextMenuDelete">
            {{ t('attrSet.actions.delete') }}
          </button>
        </div>
      </div>

      <div v-if="showSetModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b flex items-center justify-between">
            <h3 class="font-semibold">{{ editingSet ? t('attrSet.editTitle') : t('attrSet.newTitle') }}</h3>
            <button class="text-xs px-2 py-1 rounded border hover:bg-gray-50" @click="closeSetModal">
              {{ t('common.close') }}
            </button>
          </div>
          <div class="p-4 space-y-4">
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('attrSet.form.code') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="setForm.code" class="w-full h-[40px] border rounded px-3 font-mono" />
              <p v-if="setErrors.code" class="mt-1 text-xs text-red-600">{{ setErrors.code }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('attrSet.form.name') }}<span class="text-red-600">*</span></label>
              <input v-model.trim="setForm.name" class="w-full h-[40px] border rounded px-3" />
              <p v-if="setErrors.name" class="mt-1 text-xs text-red-600">{{ setErrors.name }}</p>
            </div>
            <div>
              <label class="block text-sm text-gray-600 mb-1">{{ t('attrSet.form.nameI18n') }}</label>
              <textarea v-model.trim="setForm.name_i18n" class="w-full min-h-[80px] border rounded px-3 py-2 font-mono text-xs" />
              <p v-if="setErrors.name_i18n" class="mt-1 text-xs text-red-600">{{ setErrors.name_i18n }}</p>
            </div>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('attrSet.form.domain') }}<span class="text-red-600">*</span></label>
                <input v-model.trim="setForm.domain" class="w-full h-[40px] border rounded px-3" />
                <p v-if="setErrors.domain" class="mt-1 text-xs text-red-600">{{ setErrors.domain }}</p>
              </div>
              <div>
                <label class="block text-sm text-gray-600 mb-1">{{ t('attrSet.form.industry') }}</label>
                <select v-model="setForm.industry_id" class="w-full h-[40px] border rounded px-3 bg-white">
                  <option :value="null">{{ t('attrSet.form.industryShared') }}</option>
                  <option v-for="option in industryOptions" :key="option.industry_id" :value="option.industry_id">
                    {{ option.name }}
                  </option>
                </select>
              </div>
            </div>
            <div class="flex items-center gap-2">
              <input id="setActive" v-model="setForm.is_active" type="checkbox" class="h-4 w-4" />
              <label for="setActive" class="text-sm text-gray-700">{{ t('attrSet.form.active') }}</label>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="closeSetModal">{{ t('common.cancel') }}</button>
            <button class="px-3 py-2 rounded bg-blue-600 text-white hover:bg-blue-700" @click="saveSet">
              {{ t('common.save') }}
            </button>
          </div>
        </div>
      </div>

      <div v-if="showRulesDialog" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-4xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b flex items-center justify-between">
            <h3 class="font-semibold">{{ t('attrSet.rules.dialogTitle') }}</h3>
            <button class="text-xs px-2 py-1 rounded border hover:bg-gray-50" @click="showRulesDialog = false">
              {{ t('common.close') }}
            </button>
          </div>
          <div class="p-4">
            <div v-if="rulesForSelected.length === 0" class="text-sm text-gray-500">
              {{ t('attrSet.rules.emptyHint') }}
            </div>
            <div v-else class="overflow-x-auto">
              <table class="min-w-full divide-y divide-gray-200 text-sm">
                <thead class="bg-gray-50">
                  <tr>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                      <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setRuleSort('code')">
                        <span>{{ t('attrSet.rules.code') }}</span>
                        <span v-if="ruleSortIcon('code')" class="text-xs">{{ ruleSortIcon('code') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                      <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setRuleSort('name')">
                        <span>{{ t('attrSet.rules.name') }}</span>
                        <span v-if="ruleSortIcon('name')" class="text-xs">{{ ruleSortIcon('name') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                      <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setRuleSort('required')">
                        <span>{{ t('attrSet.rules.required') }}</span>
                        <span v-if="ruleSortIcon('required')" class="text-xs">{{ ruleSortIcon('required') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                      <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setRuleSort('editable')">
                        <span>{{ t('attrSet.rules.editable') }}</span>
                        <span v-if="ruleSortIcon('editable')" class="text-xs">{{ ruleSortIcon('editable') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                      <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setRuleSort('visible')">
                        <span>{{ t('attrSet.rules.visible') }}</span>
                        <span v-if="ruleSortIcon('visible')" class="text-xs">{{ ruleSortIcon('visible') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left text-xs font-medium text-gray-600">
                      <button class="flex items-center gap-1 cursor-pointer select-none" type="button" @click="setRuleSort('defaultValue')">
                        <span>{{ t('attrSet.rules.defaultValue') }}</span>
                        <span v-if="ruleSortIcon('defaultValue')" class="text-xs">{{ ruleSortIcon('defaultValue') }}</span>
                      </button>
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="rule in sortedRulesForSelected" :key="rule.attr_id">
                    <td class="px-3 py-2 font-mono text-xs text-gray-700">{{ rule.code }}</td>
                    <td class="px-3 py-2">
                      <div>{{ rule.name }}</div>
                      <div v-if="rule.name_i18n" class="text-xs text-gray-500">
                        {{ displayNameI18n(rule) }}
                      </div>
                    </td>
                    <td class="px-3 py-2">
                      <input v-model="rule.required" type="checkbox" class="h-4 w-4" />
                    </td>
                    <td class="px-3 py-2">
                      <input v-model="rule.editable" type="checkbox" class="h-4 w-4" />
                    </td>
                    <td class="px-3 py-2">
                      <input v-model="rule.visible" type="checkbox" class="h-4 w-4" />
                    </td>
                    <td class="px-3 py-2">
                      <input v-model.trim="rule.default_value" class="h-[32px] border rounded px-2 text-xs w-full" />
                    </td>
                  </tr>
                </tbody>
              </table>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="showRulesDialog = false">{{ t('common.close') }}</button>
          </div>
        </div>
      </div>

      <div v-if="showPreview" class="fixed inset-0 z-50 flex items-center justify-center bg-black/40 p-4">
        <div class="w-full max-w-2xl bg-white rounded-xl shadow-lg border">
          <div class="px-4 py-3 border-b flex items-center justify-between">
            <h3 class="font-semibold">{{ t('attrSet.preview.title') }}</h3>
            <button class="text-xs px-2 py-1 rounded border hover:bg-gray-50" @click="showPreview = false">
              {{ t('common.close') }}
            </button>
          </div>
          <div class="p-4 space-y-3">
            <div v-if="previewFields.length === 0" class="text-sm text-gray-500">
              {{ t('attrSet.preview.empty') }}
            </div>
            <div v-else class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div v-for="field in previewFields" :key="field.attr_id">
                <label class="block text-xs text-gray-600 mb-1">{{ field.name }}</label>
                <input
                  v-if="field.data_type === 'number'"
                  type="number"
                  class="w-full h-[38px] border rounded px-2"
                  :disabled="!field.editable"
                  :placeholder="field.default_value"
                />
                <input
                  v-else-if="field.data_type === 'bool'"
                  type="checkbox"
                  class="h-4 w-4"
                  :disabled="!field.editable"
                />
                <select
                  v-else-if="field.data_type === 'enum'"
                  class="w-full h-[38px] border rounded px-2"
                  :disabled="!field.editable"
                >
                  <option v-for="value in field.enum_values" :key="value" :value="value">
                    {{ value }}
                  </option>
                </select>
                <input
                  v-else
                  type="text"
                  class="w-full h-[38px] border rounded px-2"
                  :disabled="!field.editable"
                  :placeholder="field.default_value"
                />
              </div>
            </div>
          </div>
          <div class="px-4 py-3 border-t flex items-center justify-end gap-2">
            <button class="px-3 py-2 rounded border hover:bg-gray-50" @click="showPreview = false">{{ t('common.close') }}</button>
          </div>
        </div>
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
  </SystemAdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import ConfirmActionDialog from '@/components/common/ConfirmActionDialog.vue'
import { supabase } from '@/lib/supabase'
import { useConfirmDialog } from '@/composables/useConfirmDialog'
import SystemAdminLayout from '@/layouts/SystemAdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'
import { useTableSort } from '@/composables/useTableSort'
import { useAuthStore } from '@/stores/auth'

type AttrDefRow = {
  tenant_id: string
  attr_id: number
  code: string
  name: string
  name_i18n: Record<string, string> | null
  domain: string
  data_type: string
  allowed_values: unknown | null
  scope: string
}

type AttrSetRow = {
  tenant_id: string
  attr_set_id: number
  code: string
  name: string
  name_i18n: Record<string, string> | null
  domain: string
  industry_id: string | null
  is_active: boolean
  scope: string
  owner_id: string | null
}

type AttrRuleRow = {
  attr_id: number
  code: string
  name: string
  name_i18n: Record<string, string> | null
  data_type: string
  allowed_values: unknown | null
  required: boolean
  editable: boolean
  visible: boolean
  default_value: string
  sort_order: number
  is_active: boolean
}

type AttrSetRuleQueryRow = {
  attr_id: number
  required: boolean | null
  sort_order: number | null
  is_active: boolean | null
  meta: Record<string, unknown> | null
  attr_def:
    | {
        attr_id: number
        code: string
        name: string
        name_i18n: Record<string, string> | null
        data_type: string
        allowed_values: unknown | null
      }
    | {
        attr_id: number
        code: string
        name: string
        name_i18n: Record<string, string> | null
        data_type: string
        allowed_values: unknown | null
      }[]
    | null
}

type AttrDefJoinedRow = {
  attr_id: number
  code: string
  name: string
  name_i18n: Record<string, string> | null
  data_type: string
  allowed_values: unknown | null
}

type RuleSortKey = 'code' | 'name' | 'required' | 'editable' | 'visible' | 'defaultValue' | 'sortOrder'

type IndustryRow = {
  industry_id: string
  name: string
  sort_order: number
}

const { t } = useI18n()
const { confirmDialog, requestConfirmation, cancelConfirmation, acceptConfirmation } = useConfirmDialog()
const auth = useAuthStore()
const pageTitle = computed(() => t('attrSet.title'))
const SYSTEM_TENANT_ID = '00000000-0000-0000-0000-000000000000'
const ALL_DOMAINS = '__all__'

const loading = ref(false)
const saving = ref(false)
const paletteFilter = ref('')
const attrDefs = ref<AttrDefRow[]>([])
const attrSets = ref<AttrSetRow[]>([])
const rules = ref<Record<number, AttrRuleRow[]>>({})
const selectedSetId = ref<number | null>(null)
const showSetModal = ref(false)
const editingSet = ref(false)
const showRulesDialog = ref(false)
const showPreview = ref(false)
const tenantId = ref<string | null>(null)
const isAdmin = ref(false)
const industries = ref<IndustryRow[]>([])
const selectedDomain = ref(ALL_DOMAINS)

const setForm = reactive({
  code: '',
  name: '',
  name_i18n: '',
  domain: '',
  industry_id: null as string | null,
  is_active: true,
})

const setErrors = reactive<Record<string, string>>({
  code: '',
  name: '',
  domain: '',
  name_i18n: '',
})

const contextMenu = reactive({
  open: false,
  x: 0,
  y: 0,
  target: null as AttrSetRow | null,
})

const domainOptions = computed(() => {
  const domains = new Set<string>()
  attrDefs.value.forEach((row) => {
    if (row.domain) domains.add(row.domain)
  })
  attrSets.value.forEach((row) => {
    if (row.domain) domains.add(row.domain)
  })
  return Array.from(domains).sort((a, b) => a.localeCompare(b))
})

const filteredAttrSets = computed(() => {
  if (selectedDomain.value === ALL_DOMAINS) return attrSets.value
  return attrSets.value.filter((row) => row.domain === selectedDomain.value)
})

const availableAttrDefs = computed(() => {
  const currentSet = selectedSet.value
  const sameTenantItems = currentSet
    ? attrDefs.value.filter((item) => item.tenant_id === currentSet.tenant_id)
    : attrDefs.value

  if (selectedDomain.value === ALL_DOMAINS) return sameTenantItems
  return sameTenantItems.filter((item) => item.domain === selectedDomain.value)
})

const paletteGroups = computed(() => {
  const term = paletteFilter.value.trim().toLowerCase()
  const filtered = availableAttrDefs.value.filter((item) => {
    const label = `${item.code} ${item.name} ${displayNameI18n(item)}`.toLowerCase()
    return !term || label.includes(term)
  })

  const grouped = new Map<string, { key: string; label: string; items: AttrDefRow[] }>()
  filtered.forEach((item) => {
    const key = `${item.domain}::${normalizeDataType(item.data_type)}`
    const label = `${item.domain} · ${dataTypeLabel(item.data_type)}`
    if (!grouped.has(key)) grouped.set(key, { key, label, items: [] })
    grouped.get(key)!.items.push(item)
  })

  return Array.from(grouped.values()).sort((a, b) => a.label.localeCompare(b.label))
})

const selectedSet = computed(() => attrSets.value.find((row) => row.attr_set_id === selectedSetId.value) || null)

const rulesForSelected = computed(() => {
  if (!selectedSetId.value) return []
  return rules.value[selectedSetId.value] || []
})

const {
  sortedRows: sortedRulesForSelected,
  setSort: setRuleSort,
  sortIcon: ruleSortIcon,
  sortKey: ruleSortKey,
  sortDirection: ruleSortDirection,
} = useTableSort<AttrRuleRow, RuleSortKey>(
  rulesForSelected,
  {
    code: (rule) => rule.code,
    name: (rule) => rule.name,
    required: (rule) => rule.required,
    editable: (rule) => rule.editable,
    visible: (rule) => rule.visible,
    defaultValue: (rule) => rule.default_value,
    sortOrder: (rule) => rule.sort_order,
  },
  'sortOrder',
)

const industryOptions = computed(() => {
  return [...industries.value].sort((a, b) => (a.sort_order ?? 0) - (b.sort_order ?? 0) || a.name.localeCompare(b.name))
})

const previewFields = computed(() => {
  return rulesForSelected.value
    .filter((rule) => rule.visible)
    .map((rule) => ({
      ...rule,
      data_type: normalizeDataType(rule.data_type),
      enum_values: Array.isArray(rule.allowed_values) ? rule.allowed_values : [],
    }))
})

function normalizeDataType(value: string) {
  if (value === 'string') return 'text'
  if (value === 'boolean') return 'bool'
  return value
}

function dataTypeLabel(value: string) {
  const normalized = normalizeDataType(value)
  if (normalized === 'number') return t('attrDef.types.number')
  if (normalized === 'text') return t('attrDef.types.text')
  if (normalized === 'enum') return t('attrDef.types.enum')
  if (normalized === 'bool') return t('attrDef.types.bool')
  return normalized
}

function displayNameI18n(row: { name_i18n: Record<string, string> | null }) {
  if (!row.name_i18n) return ''
  const entries = Object.entries(row.name_i18n)
    .filter((entry) => entry[1])
    .map(([key, value]) => `${key}:${value}`)
  return entries.length ? entries.join(' · ') : ''
}

function industryLabel(industryId: string | null) {
  if (!industryId) return t('attrSet.form.industryShared')
  const match = industries.value.find((item) => item.industry_id === industryId)
  return match?.name ?? industryId
}

async function ensureTenant() {
  if (auth.accessToken === null && auth.userId === null) {
    await auth.bootstrap()
  }
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  const role = String(data.user?.app_metadata?.role ?? data.user?.user_metadata?.role ?? '').toLowerCase()
  const isAdminFlag = Boolean(
    data.user?.app_metadata?.is_admin ||
    data.user?.user_metadata?.is_admin ||
    data.user?.app_metadata?.is_system_admin ||
    data.user?.app_metadata?.system_role,
  )
  isAdmin.value = isAdminFlag || role === 'admin' || auth.isSystemAdmin
  if (!id) {
    if (auth.isSystemAdmin || Boolean(data.user?.app_metadata?.is_system_admin || data.user?.app_metadata?.system_role)) {
      tenantId.value = SYSTEM_TENANT_ID
      return tenantId.value
    }
    throw new Error('Tenant not resolved in session')
  }
  tenantId.value = id
  return id
}

function canEdit(row: AttrSetRow) {
  if (row.scope === 'system') return auth.isSystemAdmin || isAdmin.value
  return true
}

async function fetchAttrDefs() {
  const { data, error } = await supabase
    .from('attr_def')
    .select('tenant_id, attr_id, code, name, name_i18n, domain, data_type, allowed_values, scope')
    .eq('is_active', true)
    .order('code', { ascending: true })
  if (error) throw error
  attrDefs.value = (data ?? []) as AttrDefRow[]
}

async function fetchAttrSets() {
  const { data, error } = await supabase
    .from('attr_set')
    .select('tenant_id, attr_set_id, code, name, name_i18n, domain, industry_id, is_active, scope, owner_id')
    .order('code', { ascending: true })
  if (error) throw error
  attrSets.value = (data ?? []) as AttrSetRow[]
  await syncSelectedSetWithFilter()
}

async function fetchRulesForSet(attrSetId: number) {
  const { data, error } = await supabase
    .from('attr_set_rule')
    .select('attr_id, required, sort_order, is_active, meta, attr_def:attr_def!fk_attr_set_rule_attr(attr_id, code, name, name_i18n, data_type, allowed_values)')
    .eq('attr_set_id', attrSetId)
    .order('sort_order', { ascending: true })
  if (error) throw error

  const mapped = ((data ?? []) as unknown as AttrSetRuleQueryRow[]).map((row, index) => {
    const attr = Array.isArray(row.attr_def)
      ? (row.attr_def[0] ?? null)
      : ((row.attr_def ?? null) as AttrDefJoinedRow | null)
    const meta = row.meta || {}
    return {
      attr_id: attr?.attr_id ?? row.attr_id,
      code: attr?.code ?? '',
      name: attr?.name ?? '',
      name_i18n: attr?.name_i18n ?? null,
      data_type: attr?.data_type ?? '',
      allowed_values: attr?.allowed_values ?? null,
      required: Boolean(row.required),
      editable: meta.editable !== undefined ? Boolean(meta.editable) : true,
      visible: meta.visible !== undefined ? Boolean(meta.visible) : true,
      default_value: meta.default_value !== undefined ? String(meta.default_value ?? '') : '',
      sort_order: row.sort_order ?? index,
      is_active: Boolean(row.is_active ?? true),
    } as AttrRuleRow
  })

  rules.value = {
    ...rules.value,
    [attrSetId]: mapped,
  }
}

async function fetchIndustries() {
  const { data, error } = await supabase
    .from('industry')
    .select('industry_id, name, sort_order')
    .eq('is_active', true)
    .order('sort_order', { ascending: true })
  if (error) throw error
  industries.value = (data ?? []) as IndustryRow[]
}

function resetSetErrors() {
  Object.keys(setErrors).forEach((key) => {
    setErrors[key] = ''
  })
}

function resetSetForm() {
  setForm.code = ''
  setForm.name = ''
  setForm.name_i18n = ''
  setForm.domain = selectedDomain.value === ALL_DOMAINS ? '' : selectedDomain.value
  setForm.industry_id = null
  setForm.is_active = true
  resetSetErrors()
}

function openCreateSet() {
  editingSet.value = false
  resetSetForm()
  showSetModal.value = true
}

function openEditSet(set: AttrSetRow) {
  editingSet.value = true
  resetSetForm()
  setForm.code = set.code
  setForm.name = set.name
  setForm.name_i18n = set.name_i18n ? JSON.stringify(set.name_i18n, null, 2) : ''
  setForm.domain = set.domain
  setForm.industry_id = set.industry_id
  setForm.is_active = set.is_active
  showSetModal.value = true
}

async function selectSet(attrSetId: number) {
  selectedSetId.value = attrSetId
  if (!rules.value[attrSetId]) {
    try {
      await fetchRulesForSet(attrSetId)
    } catch (err) {
      toast.error(err instanceof Error ? err.message : String(err))
    }
  }
}

async function syncSelectedSetWithFilter() {
  const visibleSets = filteredAttrSets.value
  const currentSelectedVisible = visibleSets.some((row) => row.attr_set_id === selectedSetId.value)
  if (currentSelectedVisible) return

  if (!visibleSets.length) {
    selectedSetId.value = null
    return
  }

  await selectSet(visibleSets[0].attr_set_id)
}

function openContextMenu(event: MouseEvent, set: AttrSetRow) {
  contextMenu.open = true
  contextMenu.x = event.clientX
  contextMenu.y = event.clientY
  contextMenu.target = set
}

function closeContextMenu() {
  contextMenu.open = false
  contextMenu.target = null
}

async function contextMenuPreview() {
  if (contextMenu.target) {
    await selectSet(contextMenu.target.attr_set_id)
    openPreview()
  }
  closeContextMenu()
}

async function contextMenuEdit() {
  if (contextMenu.target) {
    if (!canEdit(contextMenu.target)) {
      toast.error(t('attrSet.errors.adminOnlySystem'))
      closeContextMenu()
      return
    }
    await selectSet(contextMenu.target.attr_set_id)
    openEditSet(contextMenu.target)
  }
  closeContextMenu()
}

async function contextMenuEditRules() {
  if (contextMenu.target) {
    await selectSet(contextMenu.target.attr_set_id)
    openRulesDialog()
  }
  closeContextMenu()
}

async function contextMenuSave() {
  if (contextMenu.target) {
    await selectSet(contextMenu.target.attr_set_id)
    saveSelectedSet()
  }
  closeContextMenu()
}

async function contextMenuDelete() {
  if (contextMenu.target) {
    await selectSet(contextMenu.target.attr_set_id)
    confirmDeleteSet(contextMenu.target)
  }
  closeContextMenu()
}

function openPreview() {
  if (!selectedSet.value) return
  showPreview.value = true
}

function openRulesDialog() {
  if (!selectedSet.value) return
  showRulesDialog.value = true
}

function closeSetModal() {
  showSetModal.value = false
}

function parseJsonInput(value: string) {
  if (!value.trim()) return null
  try {
    return JSON.parse(value)
  } catch {
    return undefined
  }
}

function validateSetForm() {
  resetSetErrors()
  if (!setForm.code.trim()) setErrors.code = t('attrSet.errors.codeRequired')
  if (!setForm.name.trim()) setErrors.name = t('attrSet.errors.nameRequired')
  if (!setForm.domain.trim()) setErrors.domain = t('attrSet.errors.domainRequired')

  if (setForm.name_i18n.trim()) {
    const parsed = parseJsonInput(setForm.name_i18n)
    if (parsed === undefined || typeof parsed !== 'object') {
      setErrors.name_i18n = t('attrSet.errors.jsonObject')
    }
  }

  return Object.values(setErrors).every((value) => !value)
}

async function saveSet() {
  try {
    if (!validateSetForm()) return
    saving.value = true
    const tenant = await ensureTenant()

    const nameI18n = setForm.name_i18n.trim() ? parseJsonInput(setForm.name_i18n) : null
    if (nameI18n === undefined) {
      setErrors.name_i18n = t('attrSet.errors.jsonObject')
      return
    }

    const payload = {
      code: setForm.code.trim(),
      name: setForm.name.trim(),
      name_i18n: nameI18n,
      domain: setForm.domain.trim(),
      industry_id: setForm.industry_id,
      is_active: setForm.is_active,
    }

    if (editingSet.value && selectedSet.value) {
      if (!canEdit(selectedSet.value)) {
        toast.error(t('attrSet.errors.adminOnlySystem'))
        return
      }
      const { error } = await supabase
        .from('attr_set')
        .update(payload)
        .eq('attr_set_id', selectedSet.value.attr_set_id)
      if (error) throw error
      toast.success(t('common.saved'))
    } else {
      const insertPayload = {
        ...payload,
        tenant_id: auth.isSystemAdmin ? SYSTEM_TENANT_ID : tenant,
        scope: auth.isSystemAdmin ? 'system' : 'tenant',
        owner_id: auth.isSystemAdmin ? null : tenant,
      }
      const { error } = await supabase.from('attr_set').insert(insertPayload)
      if (error) throw error
      toast.success(t('common.saved'))
    }

    await fetchAttrSets()
    showSetModal.value = false
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

async function saveSelectedSet() {
  if (!selectedSet.value) return
  try {
    if (!canEdit(selectedSet.value)) {
      toast.error(t('attrSet.errors.adminOnlySystem'))
      return
    }
    saving.value = true
    const setId = selectedSet.value.attr_set_id
    const rows = rulesForSelected.value.map((rule, index) => ({
      tenant_id: selectedSet.value?.tenant_id ?? SYSTEM_TENANT_ID,
      attr_set_id: setId,
      attr_id: rule.attr_id,
      required: rule.required,
      sort_order: index,
      is_active: rule.is_active,
      meta: {
        editable: rule.editable,
        visible: rule.visible,
        default_value: rule.default_value,
      },
    }))

    const { error: deleteError } = await supabase
      .from('attr_set_rule')
      .delete()
      .eq('tenant_id', selectedSet.value.tenant_id)
      .eq('attr_set_id', setId)
    if (deleteError) throw deleteError

    if (rows.length) {
      const { error } = await supabase.from('attr_set_rule').insert(rows)
      if (error) throw error
    }

    toast.success(t('common.saved'))
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

async function confirmDeleteSet(set: AttrSetRow) {
  if (!canEdit(set)) {
    toast.error(t('attrSet.errors.adminOnlySystem'))
    return
  }
  const confirmed = await requestConfirmation({
    title: t('common.delete'),
    message: t('attrSet.deleteConfirm', { code: set.code }),
    confirmLabel: t('common.delete'),
    tone: 'danger',
  })
  if (!confirmed) return
  try {
    saving.value = true
    await supabase.from('attr_set_rule').delete().eq('tenant_id', set.tenant_id).eq('attr_set_id', set.attr_set_id)
    const { error } = await supabase.from('attr_set').delete().eq('tenant_id', set.tenant_id).eq('attr_set_id', set.attr_set_id)
    if (error) throw error
    toast.success(t('common.deleted'))
    if (selectedSetId.value === set.attr_set_id) {
      selectedSetId.value = null
    }
    await fetchAttrSets()
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    saving.value = false
  }
}

function removeRule(attrId: number) {
  if (!selectedSetId.value) return
  rules.value = {
    ...rules.value,
    [selectedSetId.value]: normalizeRuleOrder(rulesForSelected.value.filter((rule) => rule.attr_id !== attrId)),
  }
}

function normalizeRuleOrder(list: AttrRuleRow[]) {
  return list.map((rule, index) => ({
    ...rule,
    sort_order: index,
  }))
}

function canMoveRuleUp(attrId: number) {
  return rulesForSelected.value.findIndex((rule) => rule.attr_id === attrId) > 0
}

function canMoveRuleDown(attrId: number) {
  const index = rulesForSelected.value.findIndex((rule) => rule.attr_id === attrId)
  return index >= 0 && index < rulesForSelected.value.length - 1
}

function moveRule(attrId: number, direction: -1 | 1) {
  if (!selectedSetId.value) return
  const current = [...rulesForSelected.value]
  const index = current.findIndex((rule) => rule.attr_id === attrId)
  const nextIndex = index + direction
  if (index < 0 || nextIndex < 0 || nextIndex >= current.length) return
  const [movedRule] = current.splice(index, 1)
  current.splice(nextIndex, 0, movedRule)
  rules.value = {
    ...rules.value,
    [selectedSetId.value]: normalizeRuleOrder(current),
  }
  ruleSortKey.value = 'sortOrder'
  ruleSortDirection.value = 'asc'
}

function moveRuleUp(attrId: number) {
  moveRule(attrId, -1)
}

function moveRuleDown(attrId: number) {
  moveRule(attrId, 1)
}

function onAttrDragStart(event: DragEvent, attr: AttrDefRow) {
  event.dataTransfer?.setData('text/plain', String(attr.attr_id))
}

function onAttrDrop(event: DragEvent) {
  const attrId = Number(event.dataTransfer?.getData('text/plain'))
  if (!attrId || !selectedSetId.value) return
  const attr = availableAttrDefs.value.find((item) => item.attr_id === attrId)
  if (!attr) return

  const existing = rulesForSelected.value.find((rule) => rule.attr_id === attrId)
  if (existing) {
    toast.info(t('attrSet.rules.alreadyAdded'))
    return
  }

  const newRule: AttrRuleRow = {
    attr_id: attr.attr_id,
    code: attr.code,
    name: attr.name,
    name_i18n: attr.name_i18n,
    data_type: attr.data_type,
    allowed_values: attr.allowed_values,
    required: false,
    editable: true,
    visible: true,
    default_value: '',
    sort_order: rulesForSelected.value.length,
    is_active: true,
  }

  rules.value = {
    ...rules.value,
    [selectedSetId.value]: normalizeRuleOrder([...rulesForSelected.value, newRule]),
  }
}

async function refreshAll() {
  try {
    loading.value = true
    await ensureTenant()
    await Promise.all([fetchAttrDefs(), fetchAttrSets(), fetchIndustries()])
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  } finally {
    loading.value = false
  }
}

watch(selectedDomain, () => {
  syncSelectedSetWithFilter().catch((err) => {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  })
})

onMounted(() => {
  refreshAll().catch((err) => console.error(err))
})
</script>
