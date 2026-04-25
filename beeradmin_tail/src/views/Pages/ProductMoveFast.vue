<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white text-gray-900 p-4 space-y-4">
      <header
        class="sticky top-0 z-20 -mx-4 px-4 py-3 border-b border-gray-200 bg-white/95 backdrop-blur"
      >
        <div class="flex flex-col gap-3 lg:flex-row lg:items-center lg:justify-between">
          <div>
            <h1 class="text-xl font-semibold">{{ t('producedBeer.movementFast.title') }}</h1>
            <p class="text-sm text-gray-500">{{ t('producedBeer.movementFast.subtitle') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50"
              type="button"
              @click="goBack"
            >
              {{ t('producedBeer.movementFast.actions.back') }}
            </button>
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
              type="button"
              :disabled="saving"
              @click="submit('post')"
            >
              {{ t('producedBeer.movementFast.actions.post') }}
            </button>
            <button
              class="px-3 py-2 rounded bg-gray-900 text-white hover:bg-gray-800 disabled:opacity-50"
              type="button"
              :disabled="saving"
              @click="submit('next')"
            >
              {{ t('producedBeer.movementFast.actions.postNext') }}
            </button>
          </div>
        </div>
      </header>

      <section class="sticky top-[88px] z-10">
        <div class="grid grid-cols-1 xl:grid-cols-[minmax(0,1fr)_20rem] gap-4 items-start">
          <section class="border border-gray-200 rounded-2xl bg-white shadow-sm p-4">
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-3">
          <div class="lg:col-span-3">
            <label class="block text-sm text-gray-600 mb-1">{{
              t('producedBeer.movementFast.fields.fromSite')
            }}</label>
            <select
              v-model="routeForm.fromSiteId"
              class="w-full h-[42px] border rounded-lg px-3 bg-white"
            >
              <option value="">{{ t('common.select') }}</option>
              <option v-for="site in sourceSiteOptions" :key="site.id" :value="site.id">
                {{ siteOptionLabel(site) }}
              </option>
            </select>
          </div>
          <div class="lg:col-span-1 flex items-end">
            <button
              class="w-full h-[42px] rounded-lg border border-gray-300 hover:bg-gray-50 disabled:opacity-50"
              type="button"
              :disabled="!routeForm.fromSiteId && !routeForm.toSiteId"
              @click="swapRoute"
            >
              {{ t('producedBeer.movementFast.actions.swap') }}
            </button>
          </div>
          <div class="lg:col-span-3">
            <label class="block text-sm text-gray-600 mb-1">{{
              t('producedBeer.movementFast.fields.toSite')
            }}</label>
            <select
              v-model="routeForm.toSiteId"
              class="w-full h-[42px] border rounded-lg px-3 bg-white"
            >
              <option value="">{{ t('common.select') }}</option>
              <option v-for="site in destinationSiteOptions" :key="site.id" :value="site.id">
                {{ siteOptionLabel(site) }}
              </option>
            </select>
          </div>
          <div class="lg:col-span-2">
            <label class="block text-sm text-gray-600 mb-1">{{
              t('producedBeer.movementFast.fields.movedAt')
            }}</label>
            <input
              v-model="routeForm.movedAt"
              type="datetime-local"
              class="w-full h-[42px] border rounded-lg px-3"
            />
          </div>
          <div class="lg:col-span-2">
            <label class="block text-sm text-gray-600 mb-1">{{
              t('producedBeer.movementFast.fields.allocationPolicy')
            }}</label>
            <select
              v-model="routeForm.allocationPolicy"
              class="w-full h-[42px] border rounded-lg px-3 bg-white"
            >
              <option v-for="option in allocationOptions" :key="option.value" :value="option.value">
                {{ option.label }}
              </option>
            </select>
          </div>
          <div class="lg:col-span-1">
            <label class="mb-1 block select-none text-sm text-transparent">
              &nbsp;
            </label>
            <button
              class="flex h-[42px] w-full items-center justify-center rounded-lg border border-gray-300 bg-white text-gray-500 hover:bg-gray-50 hover:text-amber-500 disabled:opacity-50"
              type="button"
              :disabled="!canToggleFavorite"
              :title="
                isCurrentRouteFavorite
                  ? t('producedBeer.movementFast.actions.unfavorite')
                  : t('producedBeer.movementFast.actions.favorite')
              "
              :aria-label="
                isCurrentRouteFavorite
                  ? t('producedBeer.movementFast.actions.unfavorite')
                  : t('producedBeer.movementFast.actions.favorite')
              "
              @click="toggleCurrentRouteFavorite"
            >
              <StaredIcon
                class="h-5 w-5"
                :class="isCurrentRouteFavorite ? 'text-amber-500' : 'text-gray-300'"
              />
            </button>
          </div>
          <div class="lg:col-span-4">
            <label class="block text-sm text-gray-600 mb-1">{{
              t('producedBeer.movementFast.fields.movementIntent')
            }}</label>
            <div
              class="w-full h-[42px] border rounded-lg px-3 bg-gray-50 text-sm text-gray-700 flex items-center"
            >
              {{ movementIntentDisplay }}
            </div>
          </div>
          <div class="lg:col-span-4">
            <label class="block text-sm text-gray-600 mb-1">{{
              t('producedBeer.movementFast.fields.taxEvent')
            }}</label>
            <div
              class="w-full h-[42px] border rounded-lg px-3 bg-gray-50 text-sm text-gray-700 flex items-center"
            >
              {{ derivedTaxEventDisplay }}
            </div>
          </div>
          <div class="lg:col-span-4">
            <label class="block text-sm text-gray-600 mb-1">{{
              t('producedBeer.movementFast.fields.taxDecisionCode')
            }}</label>
            <select
              v-model="routeForm.taxDecisionCode"
              class="w-full h-[42px] border rounded-lg px-3 bg-white"
              :disabled="taxDecisionOptions.length <= 1"
            >
              <option value="">{{ t('common.select') }}</option>
              <option
                v-for="option in taxDecisionOptions"
                :key="option.value"
                :value="option.value"
              >
                {{ option.label }}
              </option>
            </select>
          </div>
          <div class="lg:col-span-12">
            <label class="block text-sm text-gray-600 mb-1">{{
              t('producedBeer.movementFast.fields.note')
            }}</label>
            <input
              v-model.trim="routeForm.note"
              type="text"
              class="w-full h-[42px] border rounded-lg px-3"
            />
          </div>
        </div>
        <div v-if="routeErrors.length" class="mt-3 flex flex-wrap gap-2">
          <span
            v-for="error in routeErrors"
            :key="error"
            class="inline-flex items-center rounded-full bg-red-50 px-3 py-1 text-xs text-red-700 border border-red-200"
          >
            {{ error }}
          </span>
        </div>

        <div class="mt-3 border-t border-gray-100 pt-2">
          <div class="flex items-center justify-between mb-2">
            <div>
              <h2 class="text-xs font-semibold uppercase tracking-wide text-gray-700">
                {{ t('producedBeer.movementFast.panels.routes') }}
              </h2>
              <p class="text-xs text-gray-500">
                {{ t('producedBeer.movementFast.hints.routes') }}
              </p>
            </div>
          </div>
          <div class="grid grid-cols-1 lg:grid-cols-2 gap-2">
            <section class="rounded-lg border border-gray-200 p-2">
              <h3 class="text-[11px] uppercase tracking-wide text-gray-400 mb-1">
                {{ t('producedBeer.movementFast.panels.favorites') }}
              </h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-1 max-h-32 overflow-auto pr-1">
                <div
                  v-for="preset in favoriteRoutes.slice(0, 6)"
                  :key="`fav-${preset.key}`"
                  class="flex items-center gap-1 rounded-md border border-gray-200 px-1.5 py-1"
                >
                  <button
                    class="min-w-0 flex-1 text-left rounded-md px-1 py-0.5 hover:bg-gray-50"
                    type="button"
                    @click="applyRoutePreset(preset)"
                  >
                    <div class="text-xs font-medium text-gray-900 truncate">
                      {{ preset.fromSiteName }} → {{ preset.toSiteName }}
                    </div>
                  </button>
                  <button
                    class="inline-flex h-7 w-7 items-center justify-center rounded-md text-gray-400 hover:bg-red-50 hover:text-red-600"
                    type="button"
                    :title="t('common.delete')"
                    :aria-label="t('common.delete')"
                    @click="removeFavoriteRoute(preset.key)"
                  >
                    <TrashIcon class="h-4 w-4" />
                  </button>
                </div>
                <p v-if="favoriteRoutes.length === 0" class="text-xs text-gray-500 md:col-span-2">
                  {{ t('common.noData') }}
                </p>
              </div>
            </section>

            <section class="rounded-lg border border-gray-200 p-2">
              <h3 class="text-[11px] uppercase tracking-wide text-gray-400 mb-1">
                {{ t('producedBeer.movementFast.panels.recent') }}
              </h3>
              <div class="grid grid-cols-1 md:grid-cols-2 gap-1 max-h-32 overflow-auto pr-1">
                <button
                  v-for="preset in recentRoutes.slice(0, 6)"
                  :key="`recent-${preset.key}`"
                  class="w-full text-left rounded-md border border-gray-200 px-2 py-1.5 hover:bg-gray-50"
                  type="button"
                  @click="applyRoutePreset(preset)"
                >
                  <div class="text-xs font-medium text-gray-900 truncate">
                    {{ preset.fromSiteName }} → {{ preset.toSiteName }}
                  </div>
                </button>
                <p v-if="recentRoutes.length === 0" class="text-xs text-gray-500 md:col-span-2">
                  {{ t('common.noData') }}
                </p>
              </div>
            </section>
          </div>
            </div>
          </section>

          <aside class="space-y-4">
            <section class="border border-gray-200 rounded-2xl bg-white shadow-sm p-4 space-y-4">
              <div>
                <h2 class="text-sm font-semibold text-gray-900">
                  {{ t('producedBeer.movementFast.panels.summary') }}
                </h2>
                <p class="text-xs text-gray-500">
                  {{ t('producedBeer.movementFast.hints.summary') }}
                </p>
              </div>

              <dl class="space-y-2 text-sm">
                <div class="flex items-center justify-between gap-4">
                  <dt class="text-gray-500">{{ t('producedBeer.movementFast.summary.route') }}</dt>
                  <dd class="text-right font-medium text-gray-900">{{ routeSummaryText }}</dd>
                </div>
                <div class="flex items-center justify-between gap-4">
                  <dt class="text-gray-500">{{ t('producedBeer.movementFast.summary.policy') }}</dt>
                  <dd class="text-right font-medium text-gray-900">
                    {{ allocationPolicyLabel(routeForm.allocationPolicy) }}
                  </dd>
                </div>
                <div class="flex items-center justify-between gap-4">
                  <dt class="text-gray-500">{{ t('producedBeer.movementFast.summary.intent') }}</dt>
                  <dd class="text-right font-medium text-gray-900">{{ movementIntentDisplay }}</dd>
                </div>
                <div class="flex items-center justify-between gap-4">
                  <dt class="text-gray-500">{{ t('producedBeer.movementFast.summary.taxEvent') }}</dt>
                  <dd class="text-right font-medium text-gray-900">{{ derivedTaxEventDisplay }}</dd>
                </div>
                <div class="flex items-center justify-between gap-4">
                  <dt class="text-gray-500">
                    {{ t('producedBeer.movementFast.summary.taxDecision') }}
                  </dt>
                  <dd class="text-right font-medium text-gray-900">{{ taxDecisionDisplay }}</dd>
                </div>
                <div class="flex items-center justify-between gap-4">
                  <dt class="text-gray-500">{{ t('producedBeer.movementFast.summary.lines') }}</dt>
                  <dd class="text-right font-medium text-gray-900">{{ validLineCount }}</dd>
                </div>
                <div class="flex items-center justify-between gap-4">
                  <dt class="text-gray-500">{{ t('producedBeer.movementFast.summary.totalQty') }}</dt>
                  <dd class="text-right font-medium text-gray-900">
                    {{ formatNumber(totalQtyLiters) }}
                  </dd>
                </div>
              </dl>

              <div>
                <h3 class="text-xs uppercase tracking-wide text-gray-400 mb-2">
                  {{ t('producedBeer.movementFast.panels.validation') }}
                </h3>
                <div class="space-y-2">
                  <p v-if="displayErrors.length === 0 && validLineCount > 0" class="text-sm text-emerald-700">
                    {{ t('producedBeer.movementFast.labels.ready') }}
                  </p>
                  <p v-else-if="displayErrors.length === 0" class="text-sm text-gray-500">
                    {{ t('common.noData') }}
                  </p>
                  <p v-for="error in displayErrors" :key="error" class="text-sm text-red-600">
                    {{ error }}
                  </p>
                </div>
              </div>

              <div>
                <h3 class="text-xs uppercase tracking-wide text-gray-400 mb-2">
                  {{ t('producedBeer.movementFast.panels.warnings') }}
                </h3>
                <div class="space-y-2">
                  <p v-if="warnings.length === 0" class="text-sm text-gray-500">
                    {{ t('common.none') }}
                  </p>
                  <p v-for="warning in warnings" :key="warning" class="text-sm text-amber-600">
                    {{ warning }}
                  </p>
                </div>
              </div>

              <div
                v-if="routeForm.allocationPolicy === 'MANUAL'"
                class="rounded-xl border border-amber-200 bg-amber-50 p-3 text-sm text-amber-800"
              >
                {{ t('producedBeer.movementFast.hints.manualMode') }}
              </div>
            </section>
          </aside>
        </div>
      </section>

      <section class="border border-gray-200 rounded-2xl bg-white shadow-sm p-4 space-y-4">
          <div class="flex flex-col gap-2 lg:flex-row lg:items-center lg:justify-between">
            <div>
              <h2 class="text-sm font-semibold text-gray-900">
                {{ t('producedBeer.movementFast.panels.lines') }}
              </h2>
              <p class="text-xs text-gray-500">
                {{
                  routeForm.fromSiteId
                    ? t('producedBeer.movementFast.hints.beerSearch')
                    : t('producedBeer.movementFast.hints.selectSourceFirst')
                }}
              </p>
            </div>
            <div class="flex items-center gap-2">
              <span v-if="inventoryLoading" class="text-xs text-gray-500">{{
                t('common.loading')
              }}</span>
              <span v-else class="text-xs text-gray-500">{{
                t('producedBeer.movementFast.labels.availableBeerCount', {
                  count: beerOptions.length,
                })
              }}</span>
            </div>
          </div>

          <div class="rounded-xl border border-gray-200 bg-gray-50 p-3">
            <div class="grid grid-cols-1 lg:grid-cols-12 gap-3">
              <div class="lg:col-span-4">
                <label class="block text-xs text-gray-600 mb-1">
                  {{ t('producedBeer.movementFast.fields.keyword') }}
                </label>
                <div class="relative">
                  <input
                    ref="quickKeywordInputRef"
                    v-model.trim="quickEntry.keyword"
                    type="text"
                    class="w-full h-[38px] border rounded-lg px-3 bg-white"
                    :placeholder="t('producedBeer.movementFast.placeholders.keyword')"
                    @focus="quickSuggestionOpen = true"
                    @blur="handleQuickKeywordBlur"
                    @input="handleQuickKeywordInput"
                    @keydown="handleQuickKeywordKeydown"
                  />
                  <div
                    v-if="quickSuggestionOpen && quickKeywordSuggestions.length"
                    class="absolute z-20 mt-1 w-full rounded-xl border border-gray-200 bg-white shadow-lg"
                  >
                    <button
                      v-for="option in quickKeywordSuggestions"
                      :key="`quick-${option.key}`"
                      class="w-full px-3 py-2 text-left hover:bg-gray-50 border-b border-gray-100 last:border-b-0"
                      type="button"
                      @mousedown.prevent="selectQuickBeer(option)"
                    >
                      <div class="text-sm font-medium text-gray-900">
                        {{ displayBeerOption(option) }}
                      </div>
                      <div class="text-xs text-gray-500">
                        {{ quickSuggestionMeta(option) }}
                      </div>
                    </button>
                  </div>
                </div>
              </div>

              <div class="lg:col-span-3">
                <label class="block text-xs text-gray-600 mb-1">
                  {{ t('producedBeer.movementFast.fields.package') }}
                </label>
                <select
                  v-model="quickEntry.packageId"
                  class="w-full h-[38px] border rounded-lg px-3 bg-white"
                >
                  <option value="">{{ t('common.select') }}</option>
                  <option v-for="pkg in quickPackageOptions" :key="pkg.id" :value="pkg.id">
                    {{ pkg.label }}
                  </option>
                </select>
              </div>

              <div class="lg:col-span-2">
                <label class="block text-xs text-gray-600 mb-1">
                  {{ t('producedBeer.movementFast.fields.unit') }}
                </label>
                <input
                  ref="quickAmountInputRef"
                  v-model.trim="quickEntry.unitText"
                  type="number"
                  min="0"
                  step="1"
                  inputmode="numeric"
                  class="w-full h-[38px] border rounded-lg px-3 text-right bg-white"
                  :placeholder="t('producedBeer.movementFast.placeholders.unit')"
                  @keydown.enter.exact.prevent="addLineFromQuickEntry"
                />
              </div>

              <div class="lg:col-span-2">
                <label class="block text-xs text-gray-600 mb-1">
                  {{ t('producedBeer.movementFast.fields.volume') }}
                </label>
                <input
                  ref="quickVolumeInputRef"
                  v-model.trim="quickEntry.volumeText"
                  type="number"
                  min="0"
                  step="0.001"
                  inputmode="decimal"
                  class="w-full h-[38px] border rounded-lg px-3 text-right bg-white"
                  :placeholder="t('producedBeer.movementFast.placeholders.volume')"
                  @keydown.enter.exact.prevent="addLineFromQuickEntry"
                />
              </div>

              <div class="lg:col-span-1 flex items-end">
                <button
                  class="w-full h-[38px] rounded-lg border border-gray-300 hover:bg-gray-100 disabled:opacity-50"
                  type="button"
                  :disabled="!routeForm.fromSiteId"
                  @click="addLineFromQuickEntry"
                >
                  {{ t('producedBeer.movementFast.actions.addLine') }}
                </button>
              </div>
            </div>
          </div>

          <div class="overflow-x-auto">
            <table class="min-w-full divide-y divide-gray-200 text-sm">
              <thead class="bg-gray-50 text-xs uppercase text-gray-500">
                <tr>
                  <th class="px-3 py-2 text-left w-14">#</th>
                  <th class="px-3 py-2 text-left w-56 min-w-[14rem]">
                    {{ t('producedBeer.movementFast.columns.beer') }}
                  </th>
                  <th class="px-3 py-2 text-left w-44 min-w-[10rem]">
                    {{ t('producedBeer.movementFast.columns.lotNo') }}
                  </th>
                  <th class="px-3 py-2 text-left w-52 min-w-[11rem]">
                    {{ t('producedBeer.movementFast.columns.packageInfo') }}
                  </th>
                  <th class="px-3 py-2 text-right w-32 min-w-[7rem]">
                    {{ t('producedBeer.movementFast.columns.unit') }}
                  </th>
                  <th class="px-3 py-2 text-right w-40 min-w-[9rem]">
                    {{ t('producedBeer.movementFast.columns.volume') }}
                  </th>
                  <th class="px-3 py-2 text-left min-w-[14rem]">
                    {{ t('producedBeer.movementFast.columns.note') }}
                  </th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-100">
                <tr v-for="(row, index) in lineRows" :key="row.id" class="align-top">
                  <td class="px-3 py-2 text-xs text-gray-400">{{ index + 1 }}</td>
                  <td class="px-3 py-2">
                    <div
                      class="h-[38px] border rounded-lg px-3 bg-gray-50 text-sm text-gray-700 flex items-center"
                    >
                      {{ row.searchText || '—' }}
                    </div>
                    <p
                      v-if="row.beerKey && beerOptionByKey.get(row.beerKey)"
                      class="mt-1 text-xs text-gray-500"
                    >
                      {{
                        t('producedBeer.movementFast.labels.stock', {
                          qty: formatNumber(
                            beerOptionByKey.get(row.beerKey)?.totalQtyLiters ?? null,
                          ),
                        })
                      }}
                    </p>
                    <p v-if="lineErrorMap[row.id]" class="mt-1 text-xs text-red-600">
                      {{ lineErrorMap[row.id] }}
                    </p>
                  </td>
                  <td class="px-3 py-2 min-w-[10rem]">
                    <template v-if="routeForm.allocationPolicy === 'MANUAL'">
                      <select
                        v-model="row.selectedLotId"
                        class="w-full h-[38px] border rounded-lg px-3 bg-white"
                        :disabled="!row.beerKey"
                      >
                        <option value="">{{ t('common.select') }}</option>
                        <option
                          v-for="lot in lotOptionsForRow(row)"
                          :key="lot.lotId"
                          :value="lot.lotId"
                        >
                          {{ lotOptionLabel(lot) }}
                        </option>
                      </select>
                    </template>
                    <div
                      v-else
                      class="h-[38px] border rounded-lg px-3 bg-gray-50 text-sm text-gray-700 flex items-center"
                    >
                      {{
                        resolvedLotLabelForRow(row) || t('producedBeer.movementFast.labels.autoAllocated')
                      }}
                    </div>
                  </td>
                  <td class="px-3 py-2 min-w-[11rem]">
                    <div
                      class="h-[38px] border rounded-lg px-3 bg-gray-50 text-sm text-gray-700 flex items-center truncate"
                      :title="resolvedPackageInfoForRow(row)"
                    >
                      {{ resolvedPackageInfoForRow(row) }}
                    </div>
                  </td>
                  <td class="px-3 py-2 min-w-[7rem]">
                    <div
                      class="h-[38px] border rounded-lg px-2 bg-gray-50 text-sm text-gray-700 flex items-center justify-end"
                    >
                      {{ resolvedUnitDisplayForRow(row) }}
                    </div>
                  </td>
                  <td class="px-3 py-2 min-w-[9rem]">
                    <input
                      :ref="(el) => setQtyInputRef(row.id, el)"
                      v-model="row.qtyText"
                      type="number"
                      min="0"
                      step="0.001"
                      inputmode="decimal"
                      class="w-[8.5rem] max-w-full h-[38px] border rounded-lg px-2 text-right ml-auto"
                      placeholder="0.000"
                      @keydown="handleQtyKeydown($event, index)"
                    />
                  </td>
                  <td class="px-3 py-2">
                    <input
                      v-model.trim="row.note"
                      type="text"
                      class="w-full h-[38px] border rounded-lg px-3"
                      :placeholder="t('producedBeer.movementFast.placeholders.note')"
                    />
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <div
            class="flex flex-wrap items-center justify-between gap-3 border-t border-gray-100 pt-3"
          >
            <p class="text-xs text-gray-500">
              {{ t('producedBeer.movementFast.hints.pasteExample') }}
            </p>
            <button
              class="px-3 py-2 rounded border border-gray-300 hover:bg-gray-50"
              type="button"
              @click="resetLines"
            >
              {{ t('producedBeer.movementFast.actions.clearLines') }}
            </button>
          </div>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, nextTick, onBeforeUnmount, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { StaredIcon, TrashIcon } from '@/icons'
import {
  registerInventorySearchContext,
  type InventorySearchSelection,
} from '@/composables/useInventorySearchModal'
import { useRuleengineLabels } from '@/composables/useRuleengineLabels'
import {
  resolveBatchDisplayName,
  resolveBatchStyleName,
  resolveReleasedRecipeCode,
  type BatchRecipeAttrFallback,
} from '@/lib/batchRecipeSnapshot'
import { checkLotChronology, lotChronologyViolationMessage } from '@/lib/lotChronology'
import { formatRpcErrorMessage } from '@/lib/rpcErrors'
import { supabase } from '@/lib/supabase'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'

type SiteOption = {
  id: string
  name: string
  siteTypeKey: string | null
}

type RuleLabel = {
  ja?: string
  en?: string
  show_in_movement_wizard?: boolean
}

type MovementRules = {
  enums?: Record<string, string[]>
  movement_intent_labels?: Record<string, RuleLabel>
  site_type_labels?: Record<string, RuleLabel>
  tax_event_labels?: Record<string, RuleLabel>
  tax_decision_code_labels?: Record<string, RuleLabel>
  tax_decision_definitions?: Array<{
    tax_decision_code?: string
    name_ja?: string
    name_en?: string
  }>
  movement_intent_rules?: Array<{
    movement_intent?: string
    allowed_src_site_types?: string[]
    allowed_dst_site_types?: string[]
    ui_hints?: Record<string, any>
  }>
  tax_transformation_rules?: Array<{
    movement_intent?: string
    src_site_type?: string
    dst_site_type?: string
    lot_tax_type?: string
    allowed_tax_decisions?: Array<{
      tax_decision_code?: string
      default?: boolean
      tax_event?: string
    }>
  }>
}

type BeerLotOption = {
  lotId: string
  lotNo: string | null
  batchId: string | null
  batchCode: string | null
  packageId: string | null
  packageLabel: string | null
  packageUnitVolumeLiters: number | null
  packageVolumeUomCode: string | null
  inventoryQty: number
  qtyLiters: number
  uomId: string
  uomCode: string | null
  lotTaxType: string | null
  producedAt: string | null
  expiresAt: string | null
}

type BeerOption = {
  key: string
  beerCode: string
  beerName: string
  styleName: string | null
  entityAttrSummary: string
  totalQtyLiters: number
  candidateLots: BeerLotOption[]
  searchIndex: string
}

type PackageOption = {
  id: string
  label: string
  unitVolumeLiters: number | null
  volumeUomCode: string | null
}

type UomDefinition = {
  id: string
  code: string
  baseFactor: number | null
  baseCode: string | null
}

type LineRow = {
  id: string
  searchText: string
  beerKey: string
  selectedLotId: string
  qtyText: string
  note: string
}

type RoutePreset = {
  key: string
  fromSiteId: string
  toSiteId: string
  fromSiteName: string
  toSiteName: string
  lastUsedAt: string
  useCount: number
  favorite: boolean
}

type JsonRecord = Record<string, unknown>

type SubmitMode = 'post' | 'next'

const WARNING_NEAR_EXPIRY_DAYS = 30
const ROUTE_STORAGE_PREFIX = 'product-move-fast-routes'
const ROUTE_META_KEY = 'product_move_fast'
const ROUTE_FAVORITES_META_KEY = 'favorite_routes'
const INTERNAL_TRANSFER_INTENT = 'INTERNAL_TRANSFER'

const router = useRouter()
const { t, locale } = useI18n()
const { loadRuleengineLabels, ruleLabel } = useRuleengineLabels()
const pageTitle = computed(() => t('producedBeer.movementFast.title'))

const tenantId = ref<string | null>(null)
const userId = ref<string | null>(null)
const siteOptions = ref<SiteOption[]>([])
const beerOptions = ref<BeerOption[]>([])
const storedRoutes = ref<RoutePreset[]>([])
const favoriteRoutePresets = ref<RoutePreset[]>([])
const tenantMemberMeta = ref<JsonRecord>({})
const movementRules = ref<MovementRules | null>(null)
const inventoryLoading = ref(false)
const saving = ref(false)
const validationRequested = ref(false)
const activeSuggestionRowId = ref<string | null>(null)
const beerInputRefs = new Map<string, HTMLInputElement>()
const qtyInputRefs = new Map<string, HTMLInputElement>()
const quickKeywordInputRef = ref<HTMLInputElement | null>(null)
const quickAmountInputRef = ref<HTMLInputElement | null>(null)
const quickVolumeInputRef = ref<HTMLInputElement | null>(null)
const quickSuggestionOpen = ref(false)
const uomDefinitionsByKey = new Map<string, UomDefinition>()
const uomDefinitionsLoaded = ref(false)
let unregisterInventorySearchContext: (() => void) | null = null

const routeForm = reactive({
  fromSiteId: '',
  toSiteId: '',
  movedAt: formatDateTimeLocal(new Date()),
  allocationPolicy: 'FEFO',
  movementIntent: INTERNAL_TRANSFER_INTENT,
  taxDecisionCode: '',
  note: '',
})

const quickEntry = reactive({
  keyword: '',
  beerKey: '',
  packageId: '',
  unitText: '',
  volumeText: '',
})

const allocationOptions = computed(() => [
  { value: 'FEFO', label: t('producedBeer.movementFast.allocation.fefo') },
  { value: 'FIFO', label: t('producedBeer.movementFast.allocation.fifo') },
  { value: 'MANUAL', label: t('producedBeer.movementFast.allocation.manual') },
])

let rowSeed = 0

function createEmptyRow(): LineRow {
  rowSeed += 1
  return {
    id: `line-${rowSeed}`,
    searchText: '',
    beerKey: '',
    selectedLotId: '',
    qtyText: '',
    note: '',
  }
}

function createInitialRows(count = 5) {
  return Array.from({ length: count }, () => createEmptyRow())
}

const lineRows = ref<LineRow[]>(createInitialRows())

function toNumber(value: unknown): number | null {
  if (value == null || value === '') return null
  const parsed = Number(value)
  return Number.isFinite(parsed) ? parsed : null
}

function formatDateTimeLocal(value: Date) {
  const yyyy = value.getFullYear()
  const mm = String(value.getMonth() + 1).padStart(2, '0')
  const dd = String(value.getDate()).padStart(2, '0')
  const hh = String(value.getHours()).padStart(2, '0')
  const mi = String(value.getMinutes()).padStart(2, '0')
  return `${yyyy}-${mm}-${dd}T${hh}:${mi}`
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '—'
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) return value
  return date.toLocaleString(locale.value)
}

function formatNumber(value: number | null | undefined) {
  if (value == null || Number.isNaN(value)) return '—'
  return new Intl.NumberFormat(locale.value, { maximumFractionDigits: 3 }).format(value)
}

function resolveLocalizedName(value: unknown) {
  if (typeof value === 'string') {
    const trimmed = value.trim()
    return trimmed || null
  }
  if (!value || typeof value !== 'object' || Array.isArray(value)) return null
  const record = value as Record<string, unknown>
  const isJa = String(locale.value || '')
    .toLowerCase()
    .startsWith('ja')
  const primary = isJa ? record.ja : record.en
  if (typeof primary === 'string' && primary.trim()) return primary.trim()
  const fallback = Object.values(record).find(
    (entry) => typeof entry === 'string' && entry.trim(),
  ) as string | undefined
  return fallback?.trim() || null
}

function resolveBatchLabel(meta: Record<string, any> | null | undefined) {
  const label = meta?.label
  if (typeof label !== 'string') return null
  const trimmed = label.trim()
  return trimmed.length ? trimmed : null
}

function resolveMetaString(meta: Record<string, any> | null | undefined, key: string) {
  const value = meta?.[key]
  if (typeof value !== 'string') return null
  const trimmed = value.trim()
  return trimmed.length ? trimmed : null
}

function normalizeVolumeUom(code: string | null | undefined) {
  if (!code) return null
  const normalized = code.trim().toLowerCase()
  return normalized || null
}

async function loadUomDefinitions() {
  if (uomDefinitionsLoaded.value) return
  const { data, error } = await supabase
    .from('mst_uom')
    .select('id, code, base_factor, base_code')
  if (error) throw error
  uomDefinitionsByKey.clear()
  ;(data ?? []).forEach((row: any) => {
    const id = String(row?.id ?? '').trim().toLowerCase()
    const code = normalizeVolumeUom(row?.code ?? null)
    if (!id && !code) return
    const definition: UomDefinition = {
      id,
      code: code ?? '',
      baseFactor: toNumber(row?.base_factor),
      baseCode: normalizeVolumeUom(row?.base_code ?? null),
    }
    if (id) uomDefinitionsByKey.set(id, definition)
    if (code) uomDefinitionsByKey.set(code, definition)
  })
  uomDefinitionsLoaded.value = true
}

function resolveFactorToLiters(
  uomCode: string | null | undefined,
  visited: Set<string> = new Set(),
): number | null {
  const normalized = normalizeVolumeUom(uomCode)
  if (!normalized || normalized === 'l') return 1
  if (visited.has(normalized)) return null
  visited.add(normalized)

  const uom = uomDefinitionsByKey.get(normalized)
  if (!uom) return null

  const baseFactor = uom.baseFactor
  if (baseFactor == null || !Number.isFinite(baseFactor)) return null
  const baseCode = normalizeVolumeUom(uom.baseCode)
  if (!baseCode || baseCode === 'l') return baseFactor

  const baseToLiters = resolveFactorToLiters(baseCode, visited)
  if (baseToLiters == null) return null
  return baseFactor * baseToLiters
}

function convertToLiters(value: number, uomCode: string | null | undefined) {
  const factor = resolveFactorToLiters(uomCode)
  if (factor == null) return value
  return value * factor
}

function convertFromLiters(value: number, uomCode: string | null | undefined) {
  const factor = resolveFactorToLiters(uomCode)
  if (factor == null || factor === 0) return value
  return value / factor
}

function setBeerInputRef(id: string, el: unknown) {
  if (el instanceof HTMLInputElement) beerInputRefs.set(id, el)
  else beerInputRefs.delete(id)
}

function setQtyInputRef(id: string, el: unknown) {
  if (el instanceof HTMLInputElement) qtyInputRefs.set(id, el)
  else qtyInputRefs.delete(id)
}

function focusBeerRow(index: number) {
  const row = lineRows.value[index]
  if (!row) return
  const target = beerInputRefs.get(row.id)
  if (!target) return
  target.focus()
  target.select()
}

function focusQtyRow(index: number) {
  const row = lineRows.value[index]
  if (!row) return
  const target = qtyInputRefs.get(row.id)
  if (!target) return
  target.focus()
  target.select()
}

async function ensureTenant() {
  if (tenantId.value && userId.value) return { tenantId: tenantId.value, userId: userId.value }
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const resolvedTenant = data.user?.app_metadata?.tenant_id as string | undefined
  const resolvedUser = data.user?.id as string | undefined
  if (!resolvedTenant || !resolvedUser)
    throw new Error(t('producedBeer.movementFast.errors.tenantRequired'))
  tenantId.value = resolvedTenant
  userId.value = resolvedUser
  return { tenantId: resolvedTenant, userId: resolvedUser }
}

const siteTypeAliasToRuleKey: Record<string, string> = {
  brewery: 'BREWERY_MANUFACTUR',
  brewery_manufactur: 'BREWERY_MANUFACTUR',
  bonded_area: 'TAX_STORAGE',
}

function toRuleSiteTypeKey(defKey: string | null | undefined) {
  if (!defKey) return null
  const normalized = defKey.trim()
  if (!normalized) return null
  const lower = normalized.toLowerCase()
  const alias = siteTypeAliasToRuleKey[lower]
  if (alias) return alias
  return normalized.toUpperCase().replace(/-/g, '_')
}

async function loadSites() {
  const auth = await ensureTenant()
  const { data: siteTypeDefs, error: typeError } = await supabase
    .from('registry_def')
    .select('def_id, def_key')
    .eq('kind', 'site_type')
    .eq('is_active', true)
  if (typeError) throw typeError

  const siteTypeMap = new Map<string, string>()
  ;(siteTypeDefs ?? []).forEach((row: any) => {
    if (row?.def_id) siteTypeMap.set(String(row.def_id), String(row.def_key ?? ''))
  })

  const { data, error } = await supabase
    .from('mst_sites')
    .select('id, name, site_type_id')
    .eq('tenant_id', auth.tenantId)
    .eq('active', true)
    .order('name', { ascending: true })
  if (error) throw error

  siteOptions.value = (data ?? [])
    .map((row: any) => {
      const defKey = siteTypeMap.get(String(row.site_type_id ?? '')) ?? null
      return {
        id: String(row.id),
        name: String(row.name ?? row.id),
        siteTypeKey: toRuleSiteTypeKey(defKey),
      } satisfies SiteOption
    })
    .filter((row) => !!row.siteTypeKey)
}

async function loadMovementRules() {
  const { data, error } = await supabase.rpc('movement_get_rules', {
    p_movement_intent: INTERNAL_TRANSFER_INTENT,
  })
  if (error) throw error
  movementRules.value = ((Array.isArray(data) ? data[0] : data) ?? null) as MovementRules | null
}

function siteOptionLabel(site: SiteOption) {
  const siteType = site.siteTypeKey
    ? ruleLabel('site_type', site.siteTypeKey, movementRules.value?.site_type_labels)
    : ''
  return siteType ? `${site.name} (${siteType})` : site.name
}

const siteMap = computed(() => new Map(siteOptions.value.map((site) => [site.id, site])))

const fromSite = computed(() => siteMap.value.get(routeForm.fromSiteId) ?? null)
const toSite = computed(() => siteMap.value.get(routeForm.toSiteId) ?? null)
const fromSiteType = computed(() => fromSite.value?.siteTypeKey ?? '')
const toSiteType = computed(() => toSite.value?.siteTypeKey ?? '')

const internalTransferRule = computed(() => {
  return (
    movementRules.value?.movement_intent_rules?.find(
      (rule) => rule.movement_intent === INTERNAL_TRANSFER_INTENT,
    ) ?? null
  )
})

const allowedSourceSiteTypes = computed(
  () => new Set(internalTransferRule.value?.allowed_src_site_types ?? []),
)

const allowedDestinationSiteTypes = computed(
  () => new Set(internalTransferRule.value?.allowed_dst_site_types ?? []),
)

const sourceSiteOptions = computed(() =>
  siteOptions.value.filter((site) => {
    if (!site.siteTypeKey) return false
    return allowedSourceSiteTypes.value.has(site.siteTypeKey)
  }),
)

const destinationSiteOptions = computed(() =>
  siteOptions.value.filter((site) => {
    if (!site.siteTypeKey) return false
    return allowedDestinationSiteTypes.value.has(site.siteTypeKey)
  }),
)

function compareDateAsc(a: string | null | undefined, b: string | null | undefined) {
  const aTime = a ? Date.parse(a) : Number.POSITIVE_INFINITY
  const bTime = b ? Date.parse(b) : Number.POSITIVE_INFINITY
  return aTime - bTime
}

async function loadBeerOptionsForSite(siteId: string) {
  inventoryLoading.value = true
  try {
    await loadUomDefinitions()
    const auth = await ensureTenant()
    const { data: inventoryRows, error } = await supabase
      .from('inv_inventory')
      .select(
        'lot_id, qty, uom_id, lot:lot_id ( id, lot_no, batch_id, package_id, produced_at, expires_at, lot_tax_type, status )',
      )
      .eq('tenant_id', auth.tenantId)
      .eq('site_id', siteId)
      .gt('qty', 0)
    if (error) throw error

    const activeRows = (inventoryRows ?? []).filter((row: any) => {
      const lotRow = Array.isArray(row.lot) ? row.lot[0] : row.lot
      return lotRow && lotRow.status !== 'void'
    })
    if (!activeRows.length) {
      beerOptions.value = []
      return
    }

    const batchIds = Array.from(
      new Set(
        activeRows
          .map((row: any) => {
            const lotRow = Array.isArray(row.lot) ? row.lot[0] : row.lot
            return lotRow?.batch_id ? String(lotRow.batch_id) : ''
          })
          .filter(Boolean),
      ),
    )
    const uomIds = Array.from(
      new Set(activeRows.map((row: any) => String(row.uom_id ?? '')).filter(Boolean)),
    )
    const packageIds = Array.from(
      new Set(
        activeRows
          .map((row: any) => {
            const lotRow = Array.isArray(row.lot) ? row.lot[0] : row.lot
            return lotRow?.package_id ? String(lotRow.package_id) : ''
          })
          .filter(Boolean),
      ),
    )

    const uomMap = new Map<string, string>()
    if (uomIds.length) {
      const { data: uoms, error: uomError } = await supabase
        .from('mst_uom')
        .select('id, code')
        .in('id', uomIds)
      if (uomError) throw uomError
      ;(uoms ?? []).forEach((row: any) => {
        if (row?.id) uomMap.set(String(row.id), String(row.code ?? ''))
      })
    }

    const packageMap = new Map<
      string,
      { label: string; unitVolumeLiters: number | null; volumeUomCode: string | null }
    >()
    if (packageIds.length) {
      const { data: packages, error: packageError } = await supabase
        .from('mst_package')
        .select('id, package_code, name_i18n, unit_volume, volume_uom')
        .in('id', packageIds)
      if (packageError) throw packageError
      ;(packages ?? []).forEach((row: any) => {
        if (!row?.id) return
        const packageCode = typeof row.package_code === 'string' ? row.package_code.trim() : ''
        const packageName = resolveLocalizedName(row.name_i18n)
        const unitVolume = toNumber(row.unit_volume)
        const volumeUomCode = normalizeVolumeUom(row.volume_uom ?? null)
        const unitVolumeLiters =
          unitVolume == null ? null : convertToLiters(unitVolume, volumeUomCode)
        packageMap.set(String(row.id), {
          label: packageName || packageCode || String(row.id),
          unitVolumeLiters:
            unitVolumeLiters != null && Number.isFinite(unitVolumeLiters) ? unitVolumeLiters : null,
          volumeUomCode,
        })
      })
    }

    const batchEntityAttrMap = new Map<string, string>()
    const batchRecipeAttrMap = new Map<string, BatchRecipeAttrFallback>()
    if (batchIds.length) {
      try {
        const { data: attrDefs, error: attrDefError } = await supabase
          .from('attr_def')
          .select('attr_id, code')
          .eq('domain', 'batch')
          .eq('is_active', true)
        if (attrDefError) throw attrDefError

        const attrCodeById = new Map<string, string>()
        const attrIds: number[] = []
        ;(attrDefs ?? []).forEach((row: any) => {
          const attrId = Number(row.attr_id)
          const code = typeof row.code === 'string' ? row.code.trim() : ''
          if (!Number.isFinite(attrId) || !code) return
          attrIds.push(attrId)
          attrCodeById.set(String(attrId), code)
        })

        if (attrIds.length) {
          const { data: attrRows, error: attrError } = await supabase
            .from('entity_attr')
            .select('entity_id, attr_id, value_text, value_num, value_json')
            .eq('entity_type', 'batch')
            .in('entity_id', batchIds)
            .in('attr_id', attrIds)
          if (attrError) throw attrError

          const attrPartsByBatch = new Map<string, string[]>()
          ;(attrRows ?? []).forEach((row: any) => {
            const batchId = String(row.entity_id ?? '')
            const attrCode = attrCodeById.get(String(row.attr_id))
            if (!batchId || !attrCode) return
            const textValue =
              (typeof row.value_text === 'string' && row.value_text.trim()) ||
              (row.value_num != null ? String(row.value_num) : '') ||
              (row.value_json != null ? JSON.stringify(row.value_json) : '')
            const trimmed = textValue.trim()
            if (!trimmed) return
            if (!attrPartsByBatch.has(batchId)) attrPartsByBatch.set(batchId, [])
            const list = attrPartsByBatch.get(batchId)
            if (!list) return
            list.push(`${attrCode}:${trimmed}`)
            if (attrCode === 'style_name') {
              batchRecipeAttrMap.set(batchId, { styleName: trimmed })
            }
          })

          attrPartsByBatch.forEach((parts, batchId) => {
            const unique = Array.from(new Set(parts))
            if (unique.length) batchEntityAttrMap.set(batchId, unique.join(' | '))
          })
        }
      } catch (err) {
        console.warn('Failed to load batch entity_attr for ProductMoveFast keyword suggestion', err)
      }
    }

    const batchMap = new Map<
      string,
      {
        batchCode: string
        beerCode: string
        beerName: string
        styleName: string | null
        entityAttrSummary: string
      }
    >()
    if (batchIds.length) {
      const { data: batches, error: batchError } = await supabase
        .from('mes_batches')
        .select('id, batch_code, batch_label, product_name, meta, mes_recipe_id, released_reference_json, recipe_json')
        .eq('tenant_id', auth.tenantId)
        .in('id', batchIds)
      if (batchError) throw batchError
      ;(batches ?? []).forEach((row: any) => {
        const batchCode = String(row.batch_code ?? row.id)
        const attr = batchRecipeAttrMap.get(String(row.id))
        const beerCode = resolveReleasedRecipeCode(row) ?? batchCode
        const styleName = resolveBatchStyleName(row, attr)
        const beerName = String(resolveBatchDisplayName(row) ?? styleName ?? beerCode)
        batchMap.set(String(row.id), {
          batchCode,
          beerCode,
          beerName,
          styleName: styleName ?? null,
          entityAttrSummary: batchEntityAttrMap.get(String(row.id)) ?? '',
        })
      })
    }

    const optionMap = new Map<string, BeerOption>()
    activeRows.forEach((row: any) => {
      const lotRow = Array.isArray(row.lot) ? row.lot[0] : row.lot
      if (!lotRow?.batch_id) return
      const batchInfo = batchMap.get(String(lotRow.batch_id))
      if (!batchInfo) return
      const qtyValue = toNumber(row.qty)
      if (qtyValue == null || qtyValue <= 0) return
      const qtyLiters = convertToLiters(qtyValue, uomMap.get(String(row.uom_id ?? '')))
      if (qtyLiters == null || qtyLiters <= 0) return

      const key = `${batchInfo.beerCode}__${batchInfo.beerName}`
      if (!optionMap.has(key)) {
        const searchIndex = [
          batchInfo.beerCode,
          batchInfo.beerName,
          batchInfo.styleName,
          batchInfo.batchCode,
          batchInfo.entityAttrSummary,
        ]
          .filter(Boolean)
          .join(' ')
          .toLowerCase()
        optionMap.set(key, {
          key,
          beerCode: batchInfo.beerCode,
          beerName: batchInfo.beerName,
          styleName: batchInfo.styleName,
          entityAttrSummary: batchInfo.entityAttrSummary,
          totalQtyLiters: 0,
          candidateLots: [],
          searchIndex,
        })
      }

      const option = optionMap.get(key)
      if (!option) return
      option.totalQtyLiters += qtyLiters
      if (
        batchInfo.entityAttrSummary &&
        !option.entityAttrSummary.includes(batchInfo.entityAttrSummary)
      ) {
        option.entityAttrSummary = option.entityAttrSummary
          ? `${option.entityAttrSummary} | ${batchInfo.entityAttrSummary}`
          : batchInfo.entityAttrSummary
        option.searchIndex = `${option.searchIndex} ${batchInfo.entityAttrSummary.toLowerCase()}`
      }
      const packageId = lotRow.package_id ? String(lotRow.package_id) : null
      const packageInfo = packageId ? packageMap.get(packageId) : null
      const packageLabel = packageInfo?.label ?? (packageId || null)
      if (packageLabel) option.searchIndex = `${option.searchIndex} ${packageLabel.toLowerCase()}`
      option.candidateLots.push({
        lotId: String(lotRow.id),
        lotNo: lotRow.lot_no ? String(lotRow.lot_no) : null,
        batchId: String(lotRow.batch_id),
        batchCode: batchInfo.batchCode,
        packageId,
        packageLabel,
        packageUnitVolumeLiters: packageInfo?.unitVolumeLiters ?? null,
        packageVolumeUomCode: packageInfo?.volumeUomCode ?? null,
        inventoryQty: qtyValue,
        qtyLiters,
        uomId: String(row.uom_id),
        uomCode: uomMap.get(String(row.uom_id ?? '')) ?? null,
        lotTaxType: typeof lotRow.lot_tax_type === 'string' ? String(lotRow.lot_tax_type) : null,
        producedAt: typeof lotRow.produced_at === 'string' ? lotRow.produced_at : null,
        expiresAt: typeof lotRow.expires_at === 'string' ? lotRow.expires_at : null,
      })
    })

    beerOptions.value = Array.from(optionMap.values())
      .map((option) => ({
        ...option,
        candidateLots: [...option.candidateLots].sort((a, b) =>
          compareDateAsc(a.expiresAt || a.producedAt, b.expiresAt || b.producedAt),
        ),
      }))
      .sort((a, b) => a.beerCode.localeCompare(b.beerCode))
  } finally {
    inventoryLoading.value = false
  }
}

const beerOptionByKey = computed(
  () => new Map(beerOptions.value.map((option) => [option.key, option])),
)

function displayBeerOption(option: BeerOption) {
  return `${option.beerCode} · ${option.beerName}`
}

function focusQuickKeywordInput() {
  const target = quickKeywordInputRef.value
  if (!target) return
  target.focus()
  target.select()
}

function focusQuickAmountInput() {
  const target = quickAmountInputRef.value
  if (!target) return
  target.focus()
  target.select()
}

function focusQuickVolumeInput() {
  const target = quickVolumeInputRef.value
  if (!target) return
  target.focus()
  target.select()
}

function handleInventorySearchSelection(row: InventorySearchSelection) {
  const matchedOption = beerOptions.value.find((option) =>
    option.candidateLots.some((lot) => lot.lotId === row.lotId),
  )
  if (!matchedOption) {
    toast.error(t('producedBeer.movementFast.errors.beerUnresolved'))
    return
  }

  quickEntry.beerKey = matchedOption.key
  quickEntry.keyword = row.lotNo?.trim() || displayBeerOption(matchedOption)
  quickEntry.packageId =
    row.packageId && matchedOption.candidateLots.some((lot) => lot.packageId === row.packageId)
      ? row.packageId
      : ''
  const qtyPackages = toNumber(row.qtyPackages)
  const qtyLiters = toNumber(row.qtyLiters)

  if (quickEntry.packageId && qtyPackages != null && qtyPackages > 0) {
    quickEntry.unitText = String(roundQty(qtyPackages))
    quickEntry.volumeText = qtyLiters != null && qtyLiters > 0 ? String(roundQty(qtyLiters)) : ''
  } else {
    quickEntry.unitText = ''
    quickEntry.volumeText = qtyLiters != null && qtyLiters > 0 ? String(roundQty(qtyLiters)) : ''
  }
  quickSuggestionOpen.value = false
}

function focusAfterInventorySearchSelection(row: InventorySearchSelection) {
  if (row.packageId) {
    focusQuickAmountInput()
    return
  }
  focusQuickVolumeInput()
}

const quickKeywordSuggestions = computed(() => {
  const term = quickEntry.keyword.trim().toLowerCase()
  if (!term) return beerOptions.value.slice(0, 12)
  return beerOptions.value.filter((option) => option.searchIndex.includes(term)).slice(0, 12)
})

const selectedQuickBeer = computed(() => {
  if (!quickEntry.beerKey) return null
  return beerOptionByKey.value.get(quickEntry.beerKey) ?? null
})

const quickPackageOptions = computed<PackageOption[]>(() => {
  const map = new Map<
    string,
    { label: string; unitVolumeLiters: number | null; volumeUomCode: string | null }
  >()
  const targets = selectedQuickBeer.value ? [selectedQuickBeer.value] : beerOptions.value
  targets.forEach((option) => {
    option.candidateLots.forEach((lot) => {
      if (!lot.packageId) return
      map.set(lot.packageId, {
        label: lot.packageLabel || lot.packageId,
        unitVolumeLiters: lot.packageUnitVolumeLiters,
        volumeUomCode: lot.packageVolumeUomCode,
      })
    })
  })
  return Array.from(map.entries())
    .map(([id, value]) => ({
      id,
      label: value.label,
      unitVolumeLiters: value.unitVolumeLiters,
      volumeUomCode: value.volumeUomCode,
    }))
    .sort((a, b) => a.label.localeCompare(b.label))
})

function formatUomForDisplay(code: string | null | undefined) {
  const normalized = normalizeVolumeUom(code)
  if (!normalized) return 'L'
  if (normalized === 'gal_us') return 'gal(US)'
  return normalized.toUpperCase()
}

function formatSuggestionPackageUnit(lot: BeerLotOption) {
  if (!lot.packageId) return ''
  const packageName = lot.packageLabel || lot.packageId
  if (!packageName) return ''
  if (lot.packageUnitVolumeLiters == null || lot.packageUnitVolumeLiters <= 0) return packageName
  const uomCode = lot.packageVolumeUomCode || 'l'
  const packageUnitValue = convertFromLiters(lot.packageUnitVolumeLiters, uomCode)
  return `${packageName} ${formatNumber(packageUnitValue)} ${formatUomForDisplay(uomCode)}`
}

function quickSuggestionMeta(option: BeerOption) {
  const packageUnits = Array.from(
    new Set(option.candidateLots.map((lot) => formatSuggestionPackageUnit(lot)).filter(Boolean)),
  )
    .slice(0, 3)
    .join(', ')
  return [option.styleName, packageUnits, option.entityAttrSummary].filter(Boolean).join(' | ')
}

function handleQuickKeywordInput() {
  if (!quickEntry.beerKey) {
    quickSuggestionOpen.value = true
    return
  }
  const selected = beerOptionByKey.value.get(quickEntry.beerKey)
  if (!selected) {
    quickEntry.beerKey = ''
    quickSuggestionOpen.value = true
    return
  }
  if (quickEntry.keyword !== displayBeerOption(selected)) {
    quickEntry.beerKey = ''
    quickEntry.packageId = ''
    quickSuggestionOpen.value = true
  }
}

function handleQuickKeywordBlur() {
  window.setTimeout(() => {
    quickSuggestionOpen.value = false
  }, 120)
}

function selectQuickBeer(option: BeerOption) {
  quickEntry.beerKey = option.key
  quickEntry.keyword = displayBeerOption(option)
  const packageAllowed = quickPackageOptions.value.some((entry) => entry.id === quickEntry.packageId)
  if (!packageAllowed) quickEntry.packageId = ''
  quickSuggestionOpen.value = false
  nextTick(() => focusQuickAmountInput())
}

function resolveQuickBeerOptions() {
  if (quickEntry.beerKey) {
    const selected = beerOptionByKey.value.get(quickEntry.beerKey)
    if (selected) return [selected]
  }
  const keyword = quickEntry.keyword.trim().toLowerCase()
  if (!keyword) return [] as BeerOption[]
  const exact = beerOptions.value.filter((option) => {
    return (
      option.beerCode.toLowerCase() === keyword ||
      option.beerName.toLowerCase() === keyword ||
      displayBeerOption(option).toLowerCase() === keyword
    )
  })
  if (exact.length) return exact
  return beerOptions.value.filter((option) => option.searchIndex.includes(keyword))
}

function roundQty(value: number) {
  return Math.round(value * 1000) / 1000
}

function resolveRequestedVolumeLiters() {
  const unit = toNumber(quickEntry.unitText)
  const volume = toNumber(quickEntry.volumeText)
  if (quickEntry.packageId && unit != null && unit > 0) {
    const packageInfo = quickPackageOptions.value.find((entry) => entry.id === quickEntry.packageId)
    if (packageInfo?.unitVolumeLiters != null && packageInfo.unitVolumeLiters > 0) {
      const calculated = packageInfo.unitVolumeLiters * unit
      quickEntry.volumeText = String(roundQty(calculated))
      return calculated
    }
    if (volume != null && volume > 0) return volume
    throw new Error(t('producedBeer.movementFast.errors.packageVolumeUnavailable'))
  }
  if (unit != null && unit > 0 && !quickEntry.packageId) {
    throw new Error(t('producedBeer.movementFast.errors.packageRequiredForUnit'))
  }
  if (volume != null && volume > 0) return volume
  throw new Error(t('producedBeer.movementFast.errors.volumeRequired'))
}

function appendAllocatedRows(
  allocations: Array<{ option: BeerOption; lot: BeerLotOption; qtyLiters: number }>,
) {
  const existing = lineRows.value.filter(
    (row) => row.searchText.trim() || row.selectedLotId || row.qtyText.trim() || row.note.trim(),
  )
  const appended = allocations.map((allocation) => {
    const row = createEmptyRow()
    row.searchText = displayBeerOption(allocation.option)
    row.beerKey = allocation.option.key
    row.selectedLotId = allocation.lot.lotId
    row.qtyText = String(roundQty(allocation.qtyLiters))
    row.note = ''
    return row
  })
  lineRows.value = [...existing, ...appended]
  ensureTrailingRows()
}

function draftedQtyByLotId() {
  const reserved = new Map<string, number>()
  lineRows.value.forEach((row) => {
    if (!row.selectedLotId) return
    const qty = toNumber(row.qtyText)
    if (qty == null || qty <= 0) return
    reserved.set(row.selectedLotId, (reserved.get(row.selectedLotId) ?? 0) + qty)
  })
  return reserved
}

function addLineFromQuickEntry() {
  if (!routeForm.fromSiteId) {
    toast.error(t('producedBeer.movementFast.errors.sourceSiteRequiredForLine'))
    return
  }
  const options = resolveQuickBeerOptions()
  if (!options.length) {
    toast.error(t('producedBeer.movementFast.errors.beerUnresolved'))
    return
  }
  let requestedVolumeLiters = 0
  try {
    requestedVolumeLiters = resolveRequestedVolumeLiters()
  } catch (err) {
    const message = err instanceof Error ? err.message : String(err)
    toast.error(message || t('producedBeer.movementFast.errors.volumeRequired'))
    return
  }

  const reservedByLotId = draftedQtyByLotId()
  let remaining = requestedVolumeLiters
  const allocations: Array<{ option: BeerOption; lot: BeerLotOption; qtyLiters: number }> = []
  let hadCandidateLots = false
  for (const option of options) {
    if (remaining <= 0.0001) break
    const packageFilteredLots = quickEntry.packageId
      ? candidateLotsForPolicy(option).filter((lot) => lot.packageId === quickEntry.packageId)
      : candidateLotsForPolicy(option)
    if (packageFilteredLots.length) hadCandidateLots = true

    const availableLots = packageFilteredLots
      .map((lot) => {
        const reserved = reservedByLotId.get(lot.lotId) ?? 0
        return {
          lot,
          availableLiters: Math.max(0, lot.qtyLiters - reserved),
        }
      })
      .filter((entry) => entry.availableLiters > 0.0001)

    for (const entry of availableLots) {
      if (remaining <= 0.0001) break
      const take = Math.min(remaining, entry.availableLiters)
      allocations.push({ option, lot: entry.lot, qtyLiters: take })
      remaining -= take
    }
  }
  if (!allocations.length && quickEntry.packageId && !hadCandidateLots) {
    toast.error(t('producedBeer.movementFast.errors.packageNoStock'))
    return
  }
  if (remaining > 0.0001) {
    toast.error(t('producedBeer.movementFast.errors.qtyExceedsStock'))
    return
  }

  if (quickEntry.beerKey) {
    const selected = options.find((entry) => entry.key === quickEntry.beerKey)
    if (selected) quickEntry.keyword = displayBeerOption(selected)
  } else if (options.length === 1) {
    quickEntry.beerKey = options[0].key
    quickEntry.keyword = displayBeerOption(options[0])
  }
  appendAllocatedRows(allocations)
  quickEntry.unitText = ''
  quickEntry.volumeText = ''
  quickSuggestionOpen.value = false
  nextTick(() => focusQuickKeywordInput())
}

function handleQuickKeywordKeydown(event: KeyboardEvent) {
  if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return
  if (event.key !== 'Enter') return
  event.preventDefault()
  if (quickSuggestionOpen.value && quickKeywordSuggestions.value.length) {
    selectQuickBeer(quickKeywordSuggestions.value[0])
    return
  }
  addLineFromQuickEntry()
}

function lotOptionsForRow(row: LineRow) {
  if (!row.beerKey) return []
  const option = beerOptionByKey.value.get(row.beerKey)
  if (!option) return []
  return candidateLotsForPolicy(option)
}

function lotOptionLabel(lot: BeerLotOption) {
  const primary = lot.lotNo || lot.batchCode || lot.lotId
  return `${primary} (${formatNumber(lot.qtyLiters)} L)`
}

function selectedLotForRow(row: LineRow, option: BeerOption | null | undefined) {
  if (!row.selectedLotId || !option) return null
  return option.candidateLots.find((lot) => lot.lotId === row.selectedLotId) ?? null
}

function resolvedLotLabelForRow(row: LineRow) {
  const option = row.beerKey ? beerOptionByKey.value.get(row.beerKey) : null
  const lot = selectedLotForRow(row, option)
  return lot ? lotOptionLabel(lot) : ''
}

function resolvedPackageInfoForRow(row: LineRow) {
  const option = row.beerKey ? beerOptionByKey.value.get(row.beerKey) : null
  const lot = selectedLotForRow(row, option)
  if (!lot?.packageId) return '—'
  return lot.packageLabel || lot.packageId
}

function resolvedUnitDisplayForRow(row: LineRow) {
  const qtyLiters = toNumber(row.qtyText)
  if (qtyLiters == null || qtyLiters <= 0) return '—'
  const option = row.beerKey ? beerOptionByKey.value.get(row.beerKey) : null
  const lot = selectedLotForRow(row, option)
  if (lot?.packageUnitVolumeLiters != null && lot.packageUnitVolumeLiters > 0) {
    return formatNumber(qtyLiters / lot.packageUnitVolumeLiters)
  }
  return formatNumber(qtyLiters)
}

function filteredBeerOptions(index: number) {
  const row = lineRows.value[index]
  if (!row) return []
  const term = row.searchText.trim().toLowerCase()
  if (!term) return []
  return beerOptions.value.filter((option) => option.searchIndex.includes(term)).slice(0, 8)
}

function ensureTrailingRows() {
  const nonEmptyRows = lineRows.value.filter(
    (row) => row.searchText.trim() || row.selectedLotId || row.qtyText.trim() || row.note.trim(),
  )
  const trailingEmpty = [...lineRows.value]
    .reverse()
    .findIndex((row) => row.searchText.trim() || row.selectedLotId || row.qtyText.trim() || row.note.trim())
  const trailingEmptyCount = trailingEmpty === -1 ? lineRows.value.length : trailingEmpty

  if (lineRows.value.length < 5) {
    while (lineRows.value.length < 5) lineRows.value.push(createEmptyRow())
    return
  }
  if (nonEmptyRows.length > 0 && trailingEmptyCount < 2) {
    lineRows.value.push(createEmptyRow())
  }
}

function normalizeSelectedBeer(row: LineRow) {
  if (!row.beerKey) return
  const option = beerOptionByKey.value.get(row.beerKey)
  if (!option) {
    row.beerKey = ''
    row.selectedLotId = ''
    return
  }
  if (row.searchText !== displayBeerOption(option)) {
    row.beerKey = ''
    row.selectedLotId = ''
  }
}

function handleBeerInput(index: number) {
  const row = lineRows.value[index]
  if (!row) return
  normalizeSelectedBeer(row)
  activeSuggestionRowId.value = row.id
  ensureTrailingRows()
}

function selectBeer(index: number, option: BeerOption) {
  const row = lineRows.value[index]
  if (!row) return
  row.beerKey = option.key
  row.selectedLotId = ''
  row.searchText = displayBeerOption(option)
  activeSuggestionRowId.value = null
  ensureTrailingRows()
  nextTick(() => focusQtyRow(index))
}

function handleBeerBlur(rowId: string) {
  window.setTimeout(() => {
    if (activeSuggestionRowId.value === rowId) activeSuggestionRowId.value = null
  }, 120)
}

function handleBeerKeydown(event: KeyboardEvent, index: number) {
  const suggestions = filteredBeerOptions(index)
  if (event.key === 'Enter') {
    event.preventDefault()
    const row = lineRows.value[index]
    if (!row) return
    if (suggestions.length) {
      selectBeer(index, suggestions[0])
      return
    }
    if (row.beerKey) {
      nextTick(() => focusQtyRow(index))
    }
  }
}

function applyParsedLines(index: number, parsedLines: Array<{ identifier: string; qty: number }>) {
  if (!parsedLines.length) return
  while (lineRows.value.length < index + parsedLines.length + 1)
    lineRows.value.push(createEmptyRow())
  parsedLines.forEach((parsed, offset) => {
    const row = lineRows.value[index + offset]
    if (!row) return
    const match = beerOptions.value.find((option) =>
      option.searchIndex.includes(parsed.identifier.toLowerCase()),
    )
    if (match) {
      row.beerKey = match.key
      row.selectedLotId = ''
      row.searchText = displayBeerOption(match)
    } else {
      row.beerKey = ''
      row.selectedLotId = ''
      row.searchText = parsed.identifier
    }
    row.qtyText = String(parsed.qty)
  })
  ensureTrailingRows()
}

function parsePasteText(text: string) {
  return text
    .split(/\r?\n/)
    .map((line) => line.trim())
    .filter(Boolean)
    .map((line) => {
      const match = line.match(/^(.+?)\s+(-?\d+(?:\.\d+)?)$/)
      if (!match) return null
      const qty = Number(match[2])
      if (!Number.isFinite(qty)) return null
      return { identifier: match[1].trim(), qty }
    })
    .filter((row): row is { identifier: string; qty: number } => !!row)
}

function handleBeerPaste(event: ClipboardEvent, index: number) {
  const text = event.clipboardData?.getData('text') ?? ''
  const parsed = parsePasteText(text)
  if (parsed.length <= 1) return
  event.preventDefault()
  applyParsedLines(index, parsed)
}

function handleQtyKeydown(event: KeyboardEvent, index: number) {
  if (event.key !== 'Enter') return
  event.preventDefault()
  ensureTrailingRows()
  nextTick(() => {
    const nextIndex = Math.min(index + 1, lineRows.value.length - 1)
    focusQtyRow(nextIndex)
  })
}

function resetLines() {
  lineRows.value = createInitialRows()
  validationRequested.value = false
  activeSuggestionRowId.value = null
  quickEntry.keyword = ''
  quickEntry.beerKey = ''
  quickEntry.packageId = ''
  quickEntry.unitText = ''
  quickEntry.volumeText = ''
  nextTick(() => focusQuickKeywordInput())
}

function clearRowsForNewSource() {
  lineRows.value = createInitialRows()
  activeSuggestionRowId.value = null
  quickEntry.keyword = ''
  quickEntry.beerKey = ''
  quickEntry.packageId = ''
  quickEntry.unitText = ''
  quickEntry.volumeText = ''
  quickSuggestionOpen.value = false
}

function goBack() {
  router.back()
}

function swapRoute() {
  const from = routeForm.fromSiteId
  routeForm.fromSiteId = routeForm.toSiteId
  routeForm.toSiteId = from
}

function currentRouteKey(fromSiteId: string, toSiteId: string) {
  return `${fromSiteId}__${toSiteId}`
}

function normalizeRoutePreset(input: unknown): RoutePreset | null {
  if (!input || typeof input !== 'object') return null
  const row = input as Record<string, unknown>
  const key = typeof row.key === 'string' ? row.key.trim() : ''
  const fromSiteId = typeof row.fromSiteId === 'string' ? row.fromSiteId.trim() : ''
  const toSiteId = typeof row.toSiteId === 'string' ? row.toSiteId.trim() : ''
  if (!key || !fromSiteId || !toSiteId) return null
  return {
    key,
    fromSiteId,
    toSiteId,
    fromSiteName: typeof row.fromSiteName === 'string' ? row.fromSiteName : fromSiteId,
    toSiteName: typeof row.toSiteName === 'string' ? row.toSiteName : toSiteId,
    lastUsedAt: typeof row.lastUsedAt === 'string' ? row.lastUsedAt : new Date(0).toISOString(),
    useCount: Number.isFinite(Number(row.useCount)) ? Number(row.useCount) : 0,
    favorite: Boolean(row.favorite),
  }
}

function normalizeRoutePresetList(input: unknown, favorite: boolean) {
  if (!Array.isArray(input)) return []
  return input
    .map((entry) => normalizeRoutePreset(entry))
    .filter((entry): entry is RoutePreset => !!entry)
    .map((entry) => ({ ...entry, favorite }))
    .sort((a, b) => Date.parse(b.lastUsedAt) - Date.parse(a.lastUsedAt))
}

function routeMetaPayload() {
  const currentMeta = tenantMemberMeta.value
  const currentSection =
    currentMeta[ROUTE_META_KEY] && typeof currentMeta[ROUTE_META_KEY] === 'object'
      ? (currentMeta[ROUTE_META_KEY] as JsonRecord)
      : {}
  return {
    ...currentMeta,
    [ROUTE_META_KEY]: {
      ...currentSection,
      [ROUTE_FAVORITES_META_KEY]: favoriteRoutePresets.value.slice(0, 20),
    },
  } satisfies JsonRecord
}

const canToggleFavorite = computed(() => !!routeForm.fromSiteId && !!routeForm.toSiteId)
const currentRouteStorageKey = computed(() =>
  currentRouteKey(routeForm.fromSiteId, routeForm.toSiteId),
)
const favoriteRoutes = computed(() => favoriteRoutePresets.value)
const recentRoutes = computed(() => storedRoutes.value.slice(0, 8))
const isCurrentRouteFavorite = computed(() =>
  favoriteRoutePresets.value.some((route) => route.key === currentRouteStorageKey.value),
)

function getRouteStorageKey() {
  return `${ROUTE_STORAGE_PREFIX}:${tenantId.value ?? 'tenant'}:${userId.value ?? 'user'}`
}

function loadStoredRoutes() {
  if (typeof window === 'undefined') return
  try {
    const raw = window.localStorage.getItem(getRouteStorageKey())
    storedRoutes.value = normalizeRoutePresetList(raw ? JSON.parse(raw) : [], false)
  } catch {
    storedRoutes.value = []
  }
}

function persistStoredRoutes() {
  if (typeof window === 'undefined') return
  window.localStorage.setItem(getRouteStorageKey(), JSON.stringify(storedRoutes.value.slice(0, 20)))
}

async function loadFavoriteRoutes() {
  const auth = await ensureTenant()
  try {
    const { data, error } = await supabase
      .from('tenant_members')
      .select('meta')
      .eq('tenant_id', auth.tenantId)
      .eq('user_id', auth.userId)
      .maybeSingle()
    if (error) throw error
    const meta =
      data?.meta && typeof data.meta === 'object' && !Array.isArray(data.meta)
        ? (data.meta as JsonRecord)
        : {}
    tenantMemberMeta.value = meta
    const section =
      meta[ROUTE_META_KEY] && typeof meta[ROUTE_META_KEY] === 'object'
        ? (meta[ROUTE_META_KEY] as JsonRecord)
        : {}
    favoriteRoutePresets.value = normalizeRoutePresetList(section[ROUTE_FAVORITES_META_KEY], true)
  } catch (error) {
    tenantMemberMeta.value = {}
    favoriteRoutePresets.value = []
    console.warn('Failed to load ProductMoveFast favorites from tenant_members.meta', error)
  }
}

async function persistFavoriteRoutes() {
  const auth = await ensureTenant()
  const nextMeta = routeMetaPayload()
  const { error } = await supabase
    .from('tenant_members')
    .update({ meta: nextMeta })
    .eq('tenant_id', auth.tenantId)
    .eq('user_id', auth.userId)
  if (error) throw error
  tenantMemberMeta.value = nextMeta
}

function applyRoutePreset(route: RoutePreset) {
  routeForm.fromSiteId = route.fromSiteId
  routeForm.toSiteId = route.toSiteId
}

function touchRoutePreset() {
  const fromSiteValue = fromSite.value
  const toSiteValue = toSite.value
  if (!fromSiteValue || !toSiteValue) return
  const key = currentRouteKey(fromSiteValue.id, toSiteValue.id)
  const existing = storedRoutes.value.find((route) => route.key === key)
  if (existing) {
    existing.lastUsedAt = new Date().toISOString()
    existing.useCount += 1
  } else {
    storedRoutes.value.unshift({
      key,
      fromSiteId: fromSiteValue.id,
      toSiteId: toSiteValue.id,
      fromSiteName: fromSiteValue.name,
      toSiteName: toSiteValue.name,
      lastUsedAt: new Date().toISOString(),
      useCount: 1,
      favorite: false,
    })
  }
  storedRoutes.value = [...storedRoutes.value].sort(
    (a, b) => Date.parse(b.lastUsedAt) - Date.parse(a.lastUsedAt),
  )
  persistStoredRoutes()
}

async function toggleCurrentRouteFavorite() {
  const key = currentRouteStorageKey.value
  if (!key || !fromSite.value || !toSite.value) return
  const existing = favoriteRoutePresets.value.find((route) => route.key === key)
  if (existing) {
    favoriteRoutePresets.value = favoriteRoutePresets.value.filter((route) => route.key !== key)
  } else {
    favoriteRoutePresets.value = [
      {
        key,
        fromSiteId: fromSite.value.id,
        toSiteId: toSite.value.id,
        fromSiteName: fromSite.value.name,
        toSiteName: toSite.value.name,
        lastUsedAt: new Date().toISOString(),
        useCount: 0,
        favorite: true,
      },
      ...favoriteRoutePresets.value,
    ].sort((a, b) => Date.parse(b.lastUsedAt) - Date.parse(a.lastUsedAt))
  }
  try {
    await persistFavoriteRoutes()
  } catch (error) {
    console.error(error)
    toast.error(error instanceof Error ? error.message : String(error))
    await loadFavoriteRoutes()
  }
}

async function removeFavoriteRoute(key: string) {
  const current = favoriteRoutePresets.value
  favoriteRoutePresets.value = current.filter((route) => route.key !== key)
  try {
    await persistFavoriteRoutes()
  } catch (error) {
    console.error(error)
    favoriteRoutePresets.value = current
    toast.error(error instanceof Error ? error.message : String(error))
  }
}

function allocationPolicyLabel(value: string) {
  const option = allocationOptions.value.find((entry) => entry.value === value)
  return option?.label ?? value
}

const selectedBeerLotTaxTypes = computed(() => {
  const set = new Set<string>()
  lineRows.value.forEach((row) => {
    const option = row.beerKey ? beerOptionByKey.value.get(row.beerKey) : null
    if (!option) return
    const selectedLot = selectedLotForRow(row, option)
    if (selectedLot?.lotTaxType) {
      set.add(selectedLot.lotTaxType)
      return
    }
    option.candidateLots.forEach((lot) => {
      if (lot.lotTaxType) set.add(lot.lotTaxType)
    })
  })
  return Array.from(set)
})

function matchingTaxRulesForRoute() {
  return (movementRules.value?.tax_transformation_rules ?? []).filter((entry) => {
    if (entry.movement_intent !== INTERNAL_TRANSFER_INTENT) return false
    if (fromSiteType.value && entry.src_site_type !== fromSiteType.value) return false
    if (toSiteType.value && entry.dst_site_type !== toSiteType.value) return false
    if (selectedBeerLotTaxTypes.value.length === 1) {
      return entry.lot_tax_type === selectedBeerLotTaxTypes.value[0]
    }
    return true
  })
}

const taxDecisionOptions = computed(() => {
  const defs = new Map<string, { name_ja?: string; name_en?: string }>()
  ;(movementRules.value?.tax_decision_definitions ?? []).forEach((row) => {
    if (!row.tax_decision_code) return
    defs.set(row.tax_decision_code, { name_ja: row.name_ja, name_en: row.name_en })
  })

  const codes = new Set<string>()
  matchingTaxRulesForRoute().forEach((rule) => {
    ;(rule.allowed_tax_decisions ?? []).forEach((decision) => {
      if (decision.tax_decision_code) codes.add(decision.tax_decision_code)
    })
  })

  return Array.from(codes).map((code) => {
    const def = defs.get(code)
    const isJa = String(locale.value || '')
      .toLowerCase()
      .startsWith('ja')
    const label = isJa
      ? (def?.name_ja ??
        def?.name_en ??
        ruleLabel('tax_decision_code', code, movementRules.value?.tax_decision_code_labels))
      : (def?.name_en ??
        def?.name_ja ??
        ruleLabel('tax_decision_code', code, movementRules.value?.tax_decision_code_labels))
    return { value: code, label }
  })
})

function defaultTaxDecisionCodeForRule(
  movementIntent: string,
  srcSiteType: string | null | undefined,
  dstSiteType: string | null | undefined,
  lotTaxType: string | null | undefined,
) {
  if (!movementIntent || !srcSiteType || !dstSiteType) return null
  const matchingRules = (movementRules.value?.tax_transformation_rules ?? []).filter((entry) => {
    if (entry.movement_intent !== movementIntent) return false
    if (entry.src_site_type !== srcSiteType) return false
    if (entry.dst_site_type !== dstSiteType) return false
    if (lotTaxType && entry.lot_tax_type !== lotTaxType) return false
    return true
  })
  const rule = matchingRules[0]
  if (!rule) return null
  const defaultDecision = rule.allowed_tax_decisions?.find((entry) => entry.default)
  return (
    defaultDecision?.tax_decision_code ?? rule.allowed_tax_decisions?.[0]?.tax_decision_code ?? null
  )
}

const defaultTaxDecisionCode = computed(() => {
  return defaultTaxDecisionCodeForRule(
    INTERNAL_TRANSFER_INTENT,
    fromSiteType.value,
    toSiteType.value,
    selectedBeerLotTaxTypes.value.length === 1 ? selectedBeerLotTaxTypes.value[0] : null,
  )
})

function taxDecisionLabel(code: string | null | undefined) {
  if (!code) return '—'
  const option = taxDecisionOptions.value.find((entry) => entry.value === code)
  return option?.label ?? ruleLabel('tax_decision_code', code, movementRules.value?.tax_decision_code_labels)
}

function intentLabel(code: string | null | undefined) {
  return ruleLabel('movement_intent', code, movementRules.value?.movement_intent_labels)
}

function taxEventLabel(code: string | null | undefined) {
  return ruleLabel('tax_event', code, movementRules.value?.tax_event_labels)
}

const derivedTaxEventCodes = computed(() => {
  const codes = new Set<string>()
  matchingTaxRulesForRoute().forEach((rule) => {
    const selectedDecision = routeForm.taxDecisionCode
      ? rule.allowed_tax_decisions?.find(
          (entry) => entry.tax_decision_code === routeForm.taxDecisionCode,
        )
      : undefined
    const decision =
      selectedDecision ??
      rule.allowed_tax_decisions?.find((entry) => entry.default) ??
      rule.allowed_tax_decisions?.[0]
    if (decision?.tax_event) codes.add(decision.tax_event)
  })
  return Array.from(codes)
})

const derivedTaxEventDisplay = computed(() => {
  if (!routeForm.fromSiteId || !routeForm.toSiteId) return '—'
  if (derivedTaxEventCodes.value.length === 0) return '—'
  if (derivedTaxEventCodes.value.length === 1) return taxEventLabel(derivedTaxEventCodes.value[0])
  return t('producedBeer.movementFast.labels.variesByLot')
})

const movementIntentDisplay = computed(() => intentLabel(INTERNAL_TRANSFER_INTENT))
const taxDecisionDisplay = computed(() => taxDecisionLabel(routeForm.taxDecisionCode))

function candidateLotsForPolicy(option: BeerOption) {
  const lots = [...option.candidateLots]
  if (routeForm.allocationPolicy === 'FIFO') {
    return lots.sort((a, b) =>
      compareDateAsc(a.producedAt || a.expiresAt, b.producedAt || b.expiresAt),
    )
  }
  return lots.sort((a, b) =>
    compareDateAsc(a.expiresAt || a.producedAt, b.expiresAt || b.producedAt),
  )
}

function defaultTaxDecisionCodeForLot(lotTaxType: string | null | undefined) {
  return defaultTaxDecisionCodeForRule(
    INTERNAL_TRANSFER_INTENT,
    fromSiteType.value,
    toSiteType.value,
    lotTaxType,
  )
}

function resolveTaxDecisionCodeForLot(lotTaxType: string | null | undefined) {
  const srcType = fromSiteType.value
  const dstType = toSiteType.value
  if (!srcType || !dstType || !lotTaxType) return null
  const rule = (movementRules.value?.tax_transformation_rules ?? []).find((entry) => {
    return (
      entry.movement_intent === INTERNAL_TRANSFER_INTENT &&
      entry.src_site_type === srcType &&
      entry.dst_site_type === dstType &&
      entry.lot_tax_type === lotTaxType
    )
  })
  if (!rule) return null
  if (routeForm.taxDecisionCode) {
    const matched = rule.allowed_tax_decisions?.find(
      (entry) => entry.tax_decision_code === routeForm.taxDecisionCode,
    )
    if (!matched) {
      throw new Error(t('producedBeer.movementFast.errors.selectedTaxDecisionUnsupported'))
    }
    return matched.tax_decision_code ?? null
  }
  return defaultTaxDecisionCodeForLot(lotTaxType)
}

function resolveTaxEventForLot(
  lotTaxType: string | null | undefined,
  taxDecisionCode: string | null | undefined,
) {
  const srcType = fromSiteType.value
  const dstType = toSiteType.value
  if (!srcType || !dstType || !lotTaxType || !taxDecisionCode) return null
  const rule = (movementRules.value?.tax_transformation_rules ?? []).find((entry) => {
    return (
      entry.movement_intent === INTERNAL_TRANSFER_INTENT &&
      entry.src_site_type === srcType &&
      entry.dst_site_type === dstType &&
      entry.lot_tax_type === lotTaxType
    )
  })
  const decision = rule?.allowed_tax_decisions?.find(
    (entry) => entry.tax_decision_code === taxDecisionCode,
  )
  return decision?.tax_event ?? null
}

type AllocatedMoveSegment = {
  beerCode: string
  beerName: string
  qtyLiters: number
  qtySourceUom: number
  unit: number | null
  lotId: string
  lotNo: string | null
  lotTaxType: string | null
  uomId: string
  uomCode: string | null
  taxDecisionCode: string
  note: string | null
}

function allocateLine(line: ValidatedLine, remainingByLotId?: Map<string, number>) {
  const unitCountForLot = (lot: BeerLotOption, qtyLiters: number) => {
    if (lot.packageUnitVolumeLiters == null || lot.packageUnitVolumeLiters <= 0) return null
    const raw = qtyLiters / lot.packageUnitVolumeLiters
    if (!Number.isFinite(raw) || raw <= 0) return null
    const rounded = Math.round(raw * 1000000) / 1000000
    return Math.abs(rounded - Math.round(rounded)) < 0.0000001 ? Math.round(rounded) : rounded
  }

  const availableForLot = (lot: BeerLotOption) => {
    if (!remainingByLotId) return lot.qtyLiters
    return remainingByLotId.get(lot.lotId) ?? lot.qtyLiters
  }
  const consumeFromLot = (lot: BeerLotOption, qtyLiters: number) => {
    if (!remainingByLotId) return
    const current = remainingByLotId.get(lot.lotId) ?? lot.qtyLiters
    remainingByLotId.set(lot.lotId, Math.max(0, current - qtyLiters))
  }

  if (routeForm.allocationPolicy === 'MANUAL') {
    const manualLot = line.selectedLot
    if (!manualLot) {
      throw new Error(t('producedBeer.movementFast.errors.manualLotRequired'))
    }
    const availableLiters = availableForLot(manualLot)
    if (line.qtyLiters > availableLiters + 0.0001) {
      throw new Error(t('producedBeer.movementFast.errors.qtyExceedsSelectedLot'))
    }
    const qtySourceUom = convertFromLiters(line.qtyLiters, manualLot.uomCode)
    if (qtySourceUom == null || !Number.isFinite(qtySourceUom) || qtySourceUom <= 0) {
      throw new Error(t('producedBeer.movementFast.errors.allocationUom'))
    }
    const resolvedTaxDecisionCode = resolveTaxDecisionCodeForLot(manualLot.lotTaxType)
    if (!resolvedTaxDecisionCode) {
      throw new Error(t('producedBeer.movementFast.errors.taxDecisionMissing'))
    }
    consumeFromLot(manualLot, line.qtyLiters)
    return [
      {
        beerCode: line.option.beerCode,
        beerName: line.option.beerName,
        qtyLiters: line.qtyLiters,
        qtySourceUom,
        unit: unitCountForLot(manualLot, line.qtyLiters),
        lotId: manualLot.lotId,
        lotNo: manualLot.lotNo,
        lotTaxType: manualLot.lotTaxType,
        uomId: manualLot.uomId,
        uomCode: manualLot.uomCode,
        taxDecisionCode: resolvedTaxDecisionCode,
        note: line.note,
      },
    ]
  }

  const orderedLotsBase = candidateLotsForPolicy(line.option)
  const orderedLots = line.selectedLot
    ? [line.selectedLot, ...orderedLotsBase.filter((lot) => lot.lotId !== line.selectedLot?.lotId)]
    : orderedLotsBase
  let remainingLiters = line.qtyLiters
  const segments: AllocatedMoveSegment[] = []

  for (const lot of orderedLots) {
    if (remainingLiters <= 0.0000001) break
    const availableLiters = availableForLot(lot)
    if (availableLiters <= 0) continue

    const takeLiters = Math.min(remainingLiters, availableLiters)
    const qtySourceUom = convertFromLiters(takeLiters, lot.uomCode)
    if (qtySourceUom == null || !Number.isFinite(qtySourceUom) || qtySourceUom <= 0) {
      throw new Error(t('producedBeer.movementFast.errors.allocationUom'))
    }

    const resolvedTaxDecisionCode = resolveTaxDecisionCodeForLot(lot.lotTaxType)
    if (!resolvedTaxDecisionCode) {
      throw new Error(t('producedBeer.movementFast.errors.taxDecisionMissing'))
    }

    segments.push({
      beerCode: line.option.beerCode,
      beerName: line.option.beerName,
      qtyLiters: takeLiters,
      qtySourceUom,
      unit: unitCountForLot(lot, takeLiters),
      lotId: lot.lotId,
      lotNo: lot.lotNo,
      lotTaxType: lot.lotTaxType,
      uomId: lot.uomId,
      uomCode: lot.uomCode,
      taxDecisionCode: resolvedTaxDecisionCode,
      note: line.note,
    })
    consumeFromLot(lot, takeLiters)
    remainingLiters -= takeLiters
  }

  if (remainingLiters > 0.0001) {
    throw new Error(t('producedBeer.movementFast.errors.qtyExceedsStock'))
  }

  return segments
}

const routeErrors = computed(() => {
  const errors: string[] = []
  if (!routeForm.fromSiteId) errors.push(t('producedBeer.movementFast.errors.fromRequired'))
  if (!routeForm.toSiteId) errors.push(t('producedBeer.movementFast.errors.toRequired'))
  if (routeForm.fromSiteId && routeForm.toSiteId && routeForm.fromSiteId === routeForm.toSiteId) {
    errors.push(t('producedBeer.movementFast.errors.sameSite'))
  }
  if (!movementRules.value) {
    errors.push(t('producedBeer.movementFast.errors.rulesUnavailable'))
  }
  if (
    routeForm.fromSiteId &&
    fromSiteType.value &&
    !allowedSourceSiteTypes.value.has(fromSiteType.value)
  ) {
    errors.push(t('producedBeer.movementFast.errors.noRouteRule'))
  }
  if (
    routeForm.toSiteId &&
    toSiteType.value &&
    !allowedDestinationSiteTypes.value.has(toSiteType.value)
  ) {
    errors.push(t('producedBeer.movementFast.errors.noRouteRule'))
  }
  if (routeForm.fromSiteId && routeForm.toSiteId && matchingTaxRulesForRoute().length === 0) {
    errors.push(t('producedBeer.movementFast.errors.noRouteRule'))
  }
  if (taxDecisionOptions.value.length > 1 && !routeForm.taxDecisionCode) {
    errors.push(t('producedBeer.movementFast.errors.taxDecisionRequired'))
  }
  return Array.from(new Set(errors))
})

type ValidatedLine = {
  rowId: string
  index: number
  option: BeerOption
  selectedLot: BeerLotOption | null
  qtyLiters: number
  note: string | null
}

const validatedLines = computed(() => {
  const valid: ValidatedLine[] = []
  lineRows.value.forEach((row, index) => {
    const option = row.beerKey ? beerOptionByKey.value.get(row.beerKey) : null
    const qty = toNumber(row.qtyText)
    const selectedLot = selectedLotForRow(row, option)
    if (!option || qty == null || qty <= 0) return
    if (routeForm.allocationPolicy === 'MANUAL') {
      if (!selectedLot) return
      if (qty > selectedLot.qtyLiters + 0.0001) return
    }
    valid.push({
      rowId: row.id,
      index,
      option,
      selectedLot,
      qtyLiters: qty,
      note: row.note.trim() || null,
    })
  })
  return valid
})

const lineErrorMap = computed(() => {
  const errors: Record<string, string> = {}
  lineRows.value.forEach((row) => {
    const hasAnyInput =
      !!row.searchText.trim() || !!row.selectedLotId || !!row.qtyText.trim() || !!row.note.trim()
    if (!hasAnyInput) return
    const option = row.beerKey ? beerOptionByKey.value.get(row.beerKey) : null
    const selectedLot = selectedLotForRow(row, option)
    const qty = toNumber(row.qtyText)
    if (!row.searchText.trim()) {
      errors[row.id] = t('producedBeer.movementFast.errors.beerRequired')
      return
    }
    if (!option) {
      errors[row.id] = t('producedBeer.movementFast.errors.beerUnresolved')
      return
    }
    if (qty == null || qty <= 0) {
      errors[row.id] = t('producedBeer.movementFast.errors.qtyPositive')
      return
    }
    if (routeForm.allocationPolicy === 'MANUAL') {
      if (!row.selectedLotId) {
        errors[row.id] = t('producedBeer.movementFast.errors.manualLotRequired')
        return
      }
      if (!selectedLot) {
        errors[row.id] = t('producedBeer.movementFast.errors.manualLotInvalid')
        return
      }
      if (qty > selectedLot.qtyLiters + 0.0001) {
        errors[row.id] = t('producedBeer.movementFast.errors.qtyExceedsSelectedLot')
      }
      return
    }
    if (qty > option.totalQtyLiters + 0.0001) {
      errors[row.id] = t('producedBeer.movementFast.errors.qtyExceedsStock')
    }
  })
  return errors
})

const allErrors = computed(() => {
  const errors = [...routeErrors.value, ...Object.values(lineErrorMap.value)]
  if (errors.length === 0 && validatedLines.value.length === 0) {
    errors.push(t('producedBeer.movementFast.errors.lineRequired'))
  }
  return Array.from(new Set(errors))
})

const displayErrors = computed(() => {
  const errors = [...routeErrors.value, ...Object.values(lineErrorMap.value)]
  if (errors.length === 0 && validatedLines.value.length === 0 && validationRequested.value) {
    errors.push(t('producedBeer.movementFast.errors.lineRequired'))
  }
  return Array.from(new Set(errors))
})

const warnings = computed(() => {
  const messages: string[] = []
  validatedLines.value.forEach((line) => {
    if (line.option.candidateLots.length >= 3) {
      messages.push(
        t('producedBeer.movementFast.warnings.manyLots', { beer: line.option.beerCode }),
      )
    }
    if (
      line.option.candidateLots.some((lot) => {
        if (!lot.expiresAt) return false
        const expiresAt = Date.parse(lot.expiresAt)
        if (Number.isNaN(expiresAt)) return false
        const diffDays = (expiresAt - Date.now()) / (1000 * 60 * 60 * 24)
        return diffDays >= 0 && diffDays <= WARNING_NEAR_EXPIRY_DAYS
      })
    ) {
      messages.push(
        t('producedBeer.movementFast.warnings.nearExpiry', { beer: line.option.beerCode }),
      )
    }
    if (line.qtyLiters >= line.option.totalQtyLiters * 0.8) {
      messages.push(
        t('producedBeer.movementFast.warnings.lowStock', { beer: line.option.beerCode }),
      )
    }
  })
  return Array.from(new Set(messages))
})

const validLineCount = computed(() => validatedLines.value.length)
const totalQtyLiters = computed(() =>
  validatedLines.value.reduce((sum, line) => sum + line.qtyLiters, 0),
)
const routeSummaryText = computed(() => {
  if (!fromSite.value || !toSite.value) return '—'
  return `${fromSite.value.name} → ${toSite.value.name}`
})

function buildRemainingLitersByLotId() {
  const remaining = new Map<string, number>()
  beerOptions.value.forEach((option) => {
    option.candidateLots.forEach((lot) => {
      const existing = remaining.get(lot.lotId)
      if (existing == null || lot.qtyLiters > existing) {
        remaining.set(lot.lotId, lot.qtyLiters)
      }
    })
  })
  return remaining
}

function buildMovePayloads() {
  const movementAt = new Date(routeForm.movedAt).toISOString()
  const payloads: Array<Record<string, any>> = []
  const idempotencyPrefix = `product_move_fast:${Date.now()}`
  const remainingByLotId = buildRemainingLitersByLotId()

  validatedLines.value.forEach((line, lineIndex) => {
    const segments = allocateLine(line, remainingByLotId)
    segments.forEach((segment, segmentIndex) => {
      payloads.push({
        movement_intent: INTERNAL_TRANSFER_INTENT,
        src_site: routeForm.fromSiteId,
        dst_site: routeForm.toSiteId,
        src_lot_id: segment.lotId,
        qty: segment.qtySourceUom,
        unit: segment.unit,
        uom_id: segment.uomId,
        tax_decision_code: segment.taxDecisionCode,
        movement_at: movementAt,
        notes: routeForm.note.trim() || segment.note || null,
        meta: {
          source: 'product_move_fast',
          allocation_policy: routeForm.allocationPolicy,
          beer_code: segment.beerCode,
          beer_name: segment.beerName,
          lot_no: segment.lotNo,
          derived_tax_event: resolveTaxEventForLot(segment.lotTaxType, segment.taxDecisionCode),
          line_note: segment.note,
          package_qty: segment.unit,
          qty_l: segment.qtyLiters,
          ui_line_index: lineIndex + 1,
          allocation_segment_index: segmentIndex + 1,
          idempotency_key: `${idempotencyPrefix}:${lineIndex + 1}:${segmentIndex + 1}:${segment.lotId}`,
        },
      })
    })
  })

  return payloads
}

async function submit(mode: SubmitMode) {
  if (saving.value) return
  validationRequested.value = true
  if (allErrors.value.length) {
    toast.error(allErrors.value[0])
    return
  }

  saving.value = true
  try {
    const payloads = buildMovePayloads()
    await assertMovePayloadChronology(payloads)
    const { data, error } = await supabase.rpc('product_move_fast_post', { p_docs: payloads })
    if (error) throw error

    const movementIds = Array.isArray((data as any)?.movement_ids)
      ? (data as any).movement_ids.map((entry: unknown) => String(entry))
      : []
    const postedCount =
      movementIds.length > 0 ? movementIds.length : Number((data as any)?.count ?? payloads.length)

    touchRoutePreset()
    if (routeForm.fromSiteId) {
      await loadBeerOptionsForSite(routeForm.fromSiteId)
    }
    toast.success(
      t('producedBeer.movementFast.toast.saved', {
        count: postedCount,
      }),
    )

    if (mode === 'next') {
      resetLines()
    }
  } catch (err: any) {
    console.error(err)
    toast.error(formatRpcErrorMessage(err, {
      fallbackKey: 'producedBeer.movementFast.errors.saveFailed',
    }))
  } finally {
    saving.value = false
  }
}

async function assertMovePayloadChronology(payloads: Array<Record<string, any>>) {
  const movementAt = payloads.find((payload) => payload.movement_at)?.movement_at
  const lots = payloads
    .map((payload) => ({
      lotId: String(payload.src_lot_id || ''),
      lotLabel: String(payload.meta?.lot_no || payload.src_lot_id || ''),
    }))
    .filter((lot) => lot.lotId)
  const result = await checkLotChronology({ supabase, movementAt, lots })
  if (result.unavailableReason) {
    console.warn('Lot chronology early-warning check unavailable', result.unavailableReason)
    return
  }
  const violation = result.violations[0]
  if (violation) {
    throw new Error(lotChronologyViolationMessage(violation, locale.value))
  }
}

function handleGlobalKeydown(event: KeyboardEvent) {
  const target = event.target as HTMLElement | null
  const isEditable =
    !!target &&
    (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable)

  if (event.key === '/' && !event.metaKey && !event.ctrlKey && !event.altKey && !isEditable) {
    event.preventDefault()
    focusQuickKeywordInput()
    return
  }

  if (event.key === 'Enter' && event.ctrlKey) {
    event.preventDefault()
    submit('next').catch?.(() => undefined)
    return
  }
  if (event.key === 'Enter' && event.shiftKey) {
    event.preventDefault()
    submit('next').catch?.(() => undefined)
  }
}

watch(
  () => routeForm.fromSiteId,
  async (value, oldValue) => {
    if (value === oldValue) return
    clearRowsForNewSource()
    if (!value) {
      beerOptions.value = []
      return
    }
    try {
      await loadBeerOptionsForSite(value)
      nextTick(() => focusQuickKeywordInput())
    } catch (err) {
      console.error(err)
      beerOptions.value = []
      toast.error(err instanceof Error ? err.message : String(err))
    }
  },
)

watch(
  () => [fromSiteType.value, toSiteType.value, selectedBeerLotTaxTypes.value.join('|')] as const,
  () => {
    const current = routeForm.taxDecisionCode
    const valid = taxDecisionOptions.value.find((option) => option.value === current)
    if (!valid) {
      routeForm.taxDecisionCode =
        taxDecisionOptions.value.length === 1
          ? taxDecisionOptions.value[0].value
          : (defaultTaxDecisionCode.value ?? '')
    }
  },
  { immediate: true },
)

watch(
  () =>
    lineRows.value
      .map((row) => `${row.searchText}__${row.selectedLotId}__${row.qtyText}__${row.note}`)
      .join('|'),
  () => {
    ensureTrailingRows()
  },
)

watch(
  () => routeForm.allocationPolicy,
  (next, prev) => {
    if (prev === 'MANUAL' && next !== 'MANUAL') {
      lineRows.value.forEach((row) => {
        row.selectedLotId = ''
      })
    }
  },
)

watch(
  () => quickEntry.beerKey,
  () => {
    const packageAllowed = quickPackageOptions.value.some((entry) => entry.id === quickEntry.packageId)
    if (!packageAllowed) quickEntry.packageId = ''
  },
)

watch(
  () => [quickEntry.packageId, quickEntry.unitText] as const,
  () => {
    const unit = toNumber(quickEntry.unitText)
    if (!quickEntry.packageId || unit == null || unit <= 0) return
    const packageInfo = quickPackageOptions.value.find((entry) => entry.id === quickEntry.packageId)
    if (packageInfo?.unitVolumeLiters == null || packageInfo.unitVolumeLiters <= 0) return
    quickEntry.volumeText = String(roundQty(packageInfo.unitVolumeLiters * unit))
  },
)

onMounted(async () => {
  try {
    await ensureTenant()
    await Promise.all([
      loadUomDefinitions(),
      loadSites(),
      loadMovementRules(),
      loadRuleengineLabels({ tenantId: tenantId.value }),
    ])
    loadStoredRoutes()
    await loadFavoriteRoutes()
    unregisterInventorySearchContext = registerInventorySearchContext(() => {
      if (!routeForm.fromSiteId) return undefined
      return {
        siteId: routeForm.fromSiteId,
        siteLocked: true,
        onSelect: handleInventorySearchSelection,
        afterSelectFocus: focusAfterInventorySearchSelection,
      }
    })
    window.addEventListener('keydown', handleGlobalKeydown)
    nextTick(() => focusQuickKeywordInput())
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
})

onBeforeUnmount(() => {
  unregisterInventorySearchContext?.()
  unregisterInventorySearchContext = null
  window.removeEventListener('keydown', handleGlobalKeydown)
})
</script>

<style scoped>
th,
td {
  white-space: nowrap;
}
</style>
