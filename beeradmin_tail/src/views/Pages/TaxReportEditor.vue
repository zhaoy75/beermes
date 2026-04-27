<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />
    <div class="min-h-screen bg-white p-4 text-gray-900">
      <div class="w-full space-y-4">
        <header class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
          <div>
            <h1 class="text-xl font-semibold">{{ pageTitle }}</h1>
            <p class="text-sm text-gray-500">{{ t('taxReportEditor.subtitle') }}</p>
          </div>
          <div class="flex flex-wrap items-center gap-2">
            <button type="button" class="rounded border border-gray-300 px-3 py-2 hover:bg-gray-50" @click="goBack">
              {{ t('taxReportEditor.actions.back') }}
            </button>
            <button
              type="button"
              class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700 disabled:opacity-50"
              :disabled="saving || generating || loadingInitial"
              @click="saveReport"
            >
              {{ saving ? t('common.saving') : t('common.save') }}
            </button>
          </div>
        </header>

        <section class="space-y-6 rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
          <section class="grid grid-cols-1 gap-4 md:grid-cols-4">
            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('taxReport.form.taxType') }}<span class="text-red-600">*</span>
              </label>
              <select
                v-model="form.tax_type"
                class="h-[40px] w-full rounded border bg-white px-3"
                disabled
              >
                <option v-for="type in taxTypeOptions" :key="type" :value="type">{{ taxTypeLabel(type) }}</option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('taxReport.form.taxYear') }}<span class="text-red-600">*</span>
              </label>
              <input
                v-model.number="form.tax_year"
                type="number"
                min="2000"
                class="h-[40px] w-full rounded border px-3"
                disabled
              />
            </div>
            <div v-if="form.tax_type === 'monthly'">
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('taxReport.form.taxMonth') }}<span class="text-red-600">*</span>
              </label>
              <select
                v-model.number="form.tax_month"
                class="h-[40px] w-full rounded border bg-white px-3"
                disabled
              >
                <option v-for="month in monthOptions" :key="month" :value="month">{{ month }}</option>
              </select>
            </div>
            <div>
              <label class="mb-1 block text-sm text-gray-600">
                {{ t('taxReport.form.status') }}<span class="text-red-600">*</span>
              </label>
              <select v-model="form.status" class="h-[40px] w-full rounded border bg-white px-3" :disabled="!editing">
                <option v-for="status in statusOptions" :key="status" :value="status">{{ statusLabel(status) }}</option>
              </select>
              <p v-if="errors.status" class="mt-1 text-xs text-red-600">{{ errors.status }}</p>
            </div>
          </section>

          <section class="space-y-0">
          <section class="flex flex-col gap-3 border-y border-gray-100 py-2 xl:flex-row xl:items-center xl:justify-between">
            <div class="overflow-x-auto">
              <div class="inline-flex min-w-max rounded-full border border-gray-200 bg-gray-100 p-1">
                <button
                  v-for="tab in formTabs"
                  :key="tab.id"
                  type="button"
                  class="min-w-[5.5rem] rounded-full px-4 py-2 text-center text-sm font-medium transition"
                  :class="activeFormTab === tab.id ? 'bg-white text-blue-700 shadow-sm' : 'text-gray-600 hover:bg-white/70 hover:text-gray-900'"
                  :title="tab.title"
                  :aria-label="tab.ariaLabel"
                  @click="activeFormTab = tab.id"
                >
                  {{ tab.label }}
                </button>
              </div>
            </div>
            <div class="flex flex-wrap justify-end gap-2">
              <div class="inline-flex w-fit rounded-full border border-gray-300 bg-gray-50 p-1">
                <button
                  v-for="mode in editorModes"
                  :key="mode.id"
                  type="button"
                  class="rounded-full px-4 py-2 text-sm font-medium transition"
                  :class="editorMode === mode.id ? 'bg-white font-semibold text-blue-700 shadow-sm' : 'text-gray-600 hover:text-gray-900'"
                  @click="editorMode = mode.id"
                >
                  {{ mode.label }}
                </button>
              </div>
              <button
                type="button"
                class="rounded border px-3 py-2 hover:bg-gray-50 disabled:opacity-50"
                :disabled="generating"
                @click="createXmlForSummary"
              >
                {{ t('taxReport.actions.createXml') }}
              </button>
              <a v-if="summaryXmlUrl" :href="summaryXmlUrl" :download="summaryXmlName" class="self-center text-xs text-blue-600">
                {{ t('taxReport.actions.downloadXml') }}
              </a>
            </div>
          </section>

          <section v-if="editorMode === 'edit' && activeFormTab === 'LIA010'" class="space-y-2">
            <div>
              <h2 class="text-base font-semibold">{{ t('taxReportEditor.forms.lia010.title') }}</h2>
              <p class="text-xs text-gray-500">{{ t('taxReportEditor.forms.lia010.subtitle') }}</p>
            </div>
            <div class="max-h-[42vh] overflow-auto rounded border bg-gray-50">
              <table class="min-w-full text-xs">
                <thead class="sticky top-0 z-10 bg-white text-xs uppercase text-gray-500">
                  <tr>
                    <th class="w-32 px-3 py-1.5 text-left">{{ t('taxReportEditor.fieldList.code') }}</th>
                    <th class="px-3 py-1.5 text-left">{{ t('taxReportEditor.fieldList.label') }}</th>
                    <th class="px-3 py-1.5 text-left">{{ t('taxReportEditor.fieldList.value') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr
                    v-for="field in lia010EditorFields"
                    :key="field.code"
                    :class="field.highlight ? 'bg-white font-medium' : ''"
                  >
                    <td class="whitespace-nowrap px-3 py-1.5 font-mono text-xs text-gray-500">{{ field.code }}</td>
                    <td class="px-3 py-1.5 text-gray-700">{{ field.label }}</td>
                    <td class="px-3 py-1.5 text-gray-900">{{ field.value }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <section v-if="editorMode === 'edit' && activeFormTab === 'LIA110'" class="space-y-3">
            <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
              <div>
                <h2 class="text-base font-semibold">{{ t('taxReportEditor.sections.movement.title') }}</h2>
                <p class="text-xs text-gray-500">{{ t('taxReportEditor.sections.movement.subtitle') }}</p>
              </div>
            </div>
            <div class="overflow-x-auto rounded border bg-gray-50">
              <table class="min-w-full text-sm">
                <thead class="bg-white text-xs uppercase text-gray-500">
                  <tr>
                    <th class="px-3 py-2 text-left">
                      <button class="inline-flex items-center gap-1 hover:text-gray-700" type="button" @click="sortMovementTable('kubun')">
                        <span>{{ t('taxReportEditor.columns.kubun') }}</span>
                        <span>{{ movementSortIndicator('kubun') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left">
                      <button class="inline-flex items-center gap-1 hover:text-gray-700" type="button" @click="sortMovementTable('category')">
                        <span>{{ t('taxReport.breakdown.columns.category') }}</span>
                        <span>{{ movementSortIndicator('category') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left">
                      <button class="inline-flex items-center gap-1 hover:text-gray-700" type="button" @click="sortMovementTable('abv')">
                        <span>{{ t('taxReport.breakdown.columns.abv') }}</span>
                        <span>{{ movementSortIndicator('abv') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-right">
                      <button class="inline-flex items-center gap-1 hover:text-gray-700" type="button" @click="sortMovementTable('volume')">
                        <span>{{ t('taxReport.breakdown.columns.volume') }}</span>
                        <span>{{ movementSortIndicator('volume') }}</span>
                      </button>
                    </th>
                    <th class="px-3 py-2 text-left">
                      <button class="inline-flex items-center gap-1 hover:text-gray-700" type="button" @click="sortMovementTable('taxEvent')">
                        <span>{{ t('taxReportEditor.columns.taxEvent') }}</span>
                        <span>{{ movementSortIndicator('taxEvent') }}</span>
                      </button>
                    </th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="row in movementTableRows" :key="row.item.key" :class="movementRowClass(row.item)">
                    <td class="px-3 py-2 text-gray-700">{{ lia110KubunCodeForItem(row.item) }}</td>
                    <td class="px-3 py-2 text-gray-700">{{ row.item.categoryName }}</td>
                    <td class="px-3 py-2">
                      <input
                        v-if="row.editable && row.sourceIndex != null"
                        :value="formatInputNumber(row.item.abv)"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2"
                        @input="updateReportBreakdownNumber(row.sourceIndex, 'abv', $event)"
                      />
                      <span v-else class="text-gray-600">{{ formatAbv(row.item.abv) }}</span>
                    </td>
                    <td class="px-3 py-2 text-right">
                      <input
                        v-if="row.editable && row.sourceIndex != null"
                        :value="formatInputNumber(row.item.volume_l)"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2 text-right"
                        @input="updateReportBreakdownNumber(row.sourceIndex, 'volume_l', $event)"
                      />
                      <span v-else class="text-gray-700">{{ formatNullableNumber(row.item.volume_l, 2) }}</span>
                    </td>
                    <td class="px-3 py-2 text-gray-700">
                      <div>{{ movementRowLabel(row.item) }}</div>
                      <div v-if="movementRowRoleLabel(row.item)" class="text-[11px] text-gray-400">
                        {{ movementRowRoleLabel(row.item) }}
                      </div>
                    </td>
                  </tr>
                  <tr v-if="movementTableRows.length === 0">
                    <td colspan="5" class="px-3 py-4 text-center text-xs text-gray-400">{{ t('taxReport.emptyBreakdown') }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
            <p v-if="errors.breakdown" class="text-xs text-red-600">{{ errors.breakdown }}</p>
          </section>

          <section v-if="editorMode === 'edit' && activeFormTab === 'LIA130'" class="space-y-2">
            <div class="flex flex-col gap-1 md:flex-row md:items-end md:justify-between">
              <div>
                <h2 class="text-base font-semibold text-gray-800">{{ t('taxReportEditor.forms.lia130.title') }}</h2>
                <p class="text-xs text-gray-500">{{ t('taxReportEditor.sections.reduction.subtitle') }}</p>
              </div>
              <div class="text-xs text-gray-500">
                <span v-if="reductionPreviewLoading">{{ t('common.loading') }}</span>
                <span v-else>{{ t('taxReportEditor.sections.reduction.rate', {
                  category: taxReductionPreview.category,
                  rate: formatPercent(taxReductionPreview.rate),
                }) }}</span>
              </div>
            </div>
            <p v-if="reductionPreviewError" class="text-xs text-red-600">
              {{ t('taxReportEditor.sections.reduction.loadFailed', { message: reductionPreviewError }) }}
            </p>
            <div class="max-h-[42vh] overflow-auto rounded border bg-gray-50">
              <table class="min-w-full text-xs">
                <thead class="sticky top-0 z-10 bg-white text-xs uppercase text-gray-500">
                  <tr>
                    <th class="w-32 px-3 py-1.5 text-left">{{ t('taxReportEditor.fieldList.code') }}</th>
                    <th class="px-3 py-1.5 text-left">{{ t('taxReportEditor.fieldList.label') }}</th>
                    <th class="px-3 py-1.5 text-left">{{ t('taxReportEditor.fieldList.value') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr
                    v-for="field in lia130EditorFields"
                    :key="field.code"
                    :class="field.highlight ? 'bg-white font-medium' : ''"
                  >
                    <td class="whitespace-nowrap px-3 py-1.5 font-mono text-xs text-gray-500">{{ field.code }}</td>
                    <td class="px-3 py-1.5 text-gray-700">{{ field.label }}</td>
                    <td class="px-3 py-1.5 text-gray-900">{{ field.value }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <section v-if="editorMode === 'edit' && activeFormTab === 'LIA220'" class="space-y-3">
            <div>
              <h2 class="text-base font-semibold">{{ t('taxReportEditor.forms.lia220.title') }}</h2>
              <p class="text-xs text-gray-500">{{ t('taxReportEditor.sections.returns.subtitle') }}</p>
            </div>
            <div class="overflow-x-auto rounded border bg-gray-50">
              <table class="min-w-full text-sm">
                <thead class="bg-white text-xs uppercase text-gray-500">
                  <tr>
                    <th class="px-3 py-2 text-left">{{ t('taxReportEditor.columns.taxEvent') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.category') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.abv') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('taxReport.breakdown.columns.volume') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="row in returnTableRows" :key="row.item.key">
                    <td class="px-3 py-2 text-gray-700">{{ breakdownMovementLabel(row.item) }}</td>
                    <td class="px-3 py-2 text-gray-700">{{ row.item.categoryName }}</td>
                    <td class="px-3 py-2">
                      <input
                        v-if="row.sourceIndex != null"
                        :value="formatInputNumber(row.item.abv)"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2"
                        @input="updateReportBreakdownNumber(row.sourceIndex, 'abv', $event)"
                      />
                    </td>
                    <td class="px-3 py-2 text-right">
                      <input
                        v-if="row.sourceIndex != null"
                        :value="formatInputNumber(row.item.volume_l)"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2 text-right"
                        @input="updateReportBreakdownNumber(row.sourceIndex, 'volume_l', $event)"
                      />
                    </td>
                  </tr>
                  <tr v-if="returnTableRows.length === 0">
                    <td colspan="4" class="px-3 py-4 text-center text-xs text-gray-400">{{ t('taxReportEditor.preview.empty') }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <section v-if="editorMode === 'edit' && activeFormTab === 'LIA260'" class="space-y-3">
            <div>
              <h2 class="text-base font-semibold">{{ t('taxReportEditor.forms.lia260.title') }}</h2>
              <p class="text-xs text-gray-500">{{ t('taxReportEditor.forms.lia260.subtitle') }}</p>
            </div>
            <div class="overflow-x-auto rounded border bg-gray-50">
              <table class="min-w-full text-sm">
                <thead class="bg-white text-xs uppercase text-gray-500">
                  <tr>
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.category') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.abv') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('taxReport.breakdown.columns.volume') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReportEditor.lia260.exportDate') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReportEditor.lia260.destination') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReportEditor.lia260.customsOffice') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReportEditor.lia260.exporter') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="row in exportExemptTableRows" :key="row.item.key">
                    <td class="px-3 py-2 text-gray-700">{{ row.item.categoryName }}</td>
                    <td class="px-3 py-2">
                      <input
                        v-if="row.sourceIndex != null"
                        :value="formatInputNumber(row.item.abv)"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2"
                        @input="updateReportBreakdownNumber(row.sourceIndex, 'abv', $event)"
                      />
                    </td>
                    <td class="px-3 py-2 text-right">
                      <input
                        v-if="row.sourceIndex != null"
                        :value="formatInputNumber(row.item.volume_l)"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2 text-right"
                        @input="updateReportBreakdownNumber(row.sourceIndex, 'volume_l', $event)"
                      />
                    </td>
                    <td class="px-3 py-2 text-gray-500">{{ reportDateText }}</td>
                    <td class="px-3 py-2 text-gray-400">—</td>
                    <td class="px-3 py-2 text-gray-400">—</td>
                    <td class="px-3 py-2 text-gray-700">{{ tenantProfile.NOZEISHA_NM || tenantName || '—' }}</td>
                  </tr>
                  <tr v-if="exportExemptTableRows.length === 0">
                    <td colspan="7" class="px-3 py-4 text-center text-xs text-gray-400">{{ t('taxReportEditor.preview.empty') }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>

          <section v-if="editorMode === 'preview'" class="space-y-2">
            <div class="flex flex-col gap-2 rounded-lg border border-gray-200 bg-gray-50 px-3 py-2 md:flex-row md:items-center md:justify-between">
              <div class="text-xs text-gray-500">{{ t('taxReportEditor.preview.dragHint') }}</div>
              <div class="flex items-center gap-1">
                <button
                  type="button"
                  class="flex h-8 w-8 items-center justify-center rounded border bg-white text-base hover:bg-gray-50 disabled:opacity-40"
                  :title="t('taxReportEditor.preview.zoomOut')"
                  :aria-label="t('taxReportEditor.preview.zoomOut')"
                  :disabled="previewZoom <= PREVIEW_MIN_ZOOM"
                  @click="zoomPreviewBy(-PREVIEW_ZOOM_STEP)"
                >
                  −
                </button>
                <button
                  type="button"
                  class="h-8 min-w-[4rem] rounded border bg-white px-2 text-xs font-semibold hover:bg-gray-50"
                  :title="t('taxReportEditor.preview.resetZoom')"
                  :aria-label="t('taxReportEditor.preview.resetZoom')"
                  @click="resetPreviewZoom"
                >
                  {{ previewZoomPercent }}
                </button>
                <button
                  type="button"
                  class="flex h-8 w-8 items-center justify-center rounded border bg-white text-base hover:bg-gray-50 disabled:opacity-40"
                  :title="t('taxReportEditor.preview.zoomIn')"
                  :aria-label="t('taxReportEditor.preview.zoomIn')"
                  :disabled="previewZoom >= PREVIEW_MAX_ZOOM"
                  @click="zoomPreviewBy(PREVIEW_ZOOM_STEP)"
                >
                  ＋
                </button>
                <button
                  type="button"
                  class="flex h-8 w-8 items-center justify-center rounded border bg-white text-sm hover:bg-gray-50"
                  :title="t('taxReportEditor.preview.fitWidth')"
                  :aria-label="t('taxReportEditor.preview.fitWidth')"
                  @click="fitPreviewToWidth"
                >
                  ⤢
                </button>
              </div>
            </div>
            <div
              ref="previewViewport"
              class="h-[70vh] overflow-auto rounded-lg border border-gray-300 bg-gray-200 touch-none"
              :class="previewDragging ? 'cursor-grabbing select-none' : 'cursor-grab'"
              @pointerdown="startPreviewPan"
              @pointermove="movePreviewPan"
              @pointerup="endPreviewPan"
              @pointercancel="endPreviewPan"
              @pointerleave="endPreviewPan"
            >
              <div class="flex w-full min-w-max justify-center p-6">
                <div :style="previewScaledPageStyle">
                  <div
                    class="w-[297mm] min-h-[210mm] border border-neutral-400 bg-white px-[10mm] py-[8mm] text-[10px] leading-tight text-black shadow-xl"
                    :style="previewPageTransformStyle"
                  >
              <div v-if="activeFormTab === 'LIA010'" class="space-y-[2mm] text-[10px]">
                <div class="grid grid-cols-[60mm_1fr_38mm] items-start">
                  <div class="space-y-[2mm] text-[14px]">
                    <div>ＣＣ１－５２０５－１</div>
                    <div class="pl-[18mm] text-[18px]">{{ reportPeriodText }}</div>
                  </div>
                  <div class="pt-[10mm] text-center text-[22px] font-bold tracking-[0.35em]">酒 税 納 税 申 告 書</div>
                  <div class="pt-[12mm] text-right">整理番号</div>
                </div>

                <table class="w-full border-collapse border-2 border-black">
                  <tbody>
                    <tr class="h-[44mm] align-top">
                      <td class="w-[46mm] border border-black p-[2mm]">
                        <div>{{ reportDateText }}</div>
                        <div class="mt-[24mm] text-center text-[14px]">{{ tenantProfile.ZEIMUSHO.zeimusho_NM || '' }}　税務署長殿</div>
                      </td>
                      <td class="w-[10mm] border border-black p-[1mm] text-center text-[16px] leading-[2.4]">申<br />告<br />者</td>
                      <td class="border border-black p-0">
                        <div class="grid h-full grid-rows-3">
                          <div class="border-b border-black p-[1.5mm]">
                            （製造場の所在地及び名称）〒<br />
                            <span class="text-[12px] font-semibold">{{ tenantProfile.SEIZOJO_ADR || '' }}</span><br />
                            <span class="text-[12px] font-semibold">{{ tenantProfile.SEIZOJO_NM || tenantName || '' }}</span>
                          </div>
                          <div class="border-b border-black p-[1.5mm]">
                            （住所）〒<br />
                            <span class="text-[12px] font-semibold">{{ tenantProfile.NOZEISHA_ADR || '' }}</span>
                          </div>
                          <div class="p-[1.5mm]">
                            （氏名又は名称及び代表者氏名）<br />
                            <span class="text-[12px] font-semibold">{{ tenantProfile.NOZEISHA_NM || tenantName || '' }}</span>
                          </div>
                        </div>
                      </td>
                      <td class="w-[54mm] border border-black p-0">
                        <div class="grid h-full grid-cols-[12mm_1fr]">
                          <div class="border-r border-black p-[1mm] text-center leading-[2.6]">税<br />務<br />署<br />整<br />理<br />欄</div>
                          <div class="grid grid-rows-4">
                            <div class="grid grid-cols-2 border-b border-black">
                              <div class="border-r border-black p-[1.5mm]">申告区分</div>
                              <div class="p-[1.5mm]">調査区分</div>
                            </div>
                            <div class="grid grid-cols-2 border-b border-black">
                              <div class="border-r border-black p-[1.5mm]">申告年月日</div>
                              <div class="p-[1.5mm]">調査年月日</div>
                            </div>
                            <div class="border-b border-black p-[1.5mm]">審査者印</div>
                            <div class="p-[1.5mm]">確認者印</div>
                          </div>
                        </div>
                      </td>
                    </tr>
                    <tr>
                      <td colspan="4" class="border border-black p-[2mm] text-[14px]">
                        下記のとおり酒税の納税申告書（　期限内申告書　）を提出します。
                      </td>
                    </tr>
                  </tbody>
                </table>

                <div class="text-center text-[12px]">記</div>
                <table class="w-full border-collapse border-2 border-black text-[11px]">
                  <tbody>
                    <tr>
                      <td rowspan="4" class="w-[12mm] border border-black p-[1mm] text-center leading-[1.6]">納付すべき税額等の計算</td>
                      <th class="w-[46mm] border border-black p-[1.5mm] font-normal">区　分</th>
                      <th class="w-[72mm] border border-black p-[1.5mm] font-normal">この申告書による税額</th>
                      <th class="border border-black p-[1.5mm] font-normal">修正申告の場合の修正申告前の確定額</th>
                      <th class="w-[56mm] border border-black p-[1.5mm] font-normal">差引納付税額</th>
                    </tr>
                    <tr class="h-[9mm]">
                      <td class="border border-black p-[1.5mm] text-center">算　出　税　額　①</td>
                      <td class="border border-black p-[1.5mm] text-right text-[16px] font-semibold">{{ formatInteger(filingTaxAmount) }}　円</td>
                      <td class="border border-black p-[1.5mm]"></td>
                      <td rowspan="3" class="border border-black p-[1.5mm] align-bottom text-right text-[16px] font-semibold">{{ formatInteger(finalPayableTaxAmount) }}　円</td>
                    </tr>
                    <tr class="h-[9mm]">
                      <td class="border border-black p-[1.5mm] text-center">端 数 切 捨 額　②</td>
                      <td class="border border-black p-[1.5mm] text-right text-[16px]">{{ formatInteger(roundedDownTaxAmount) }}　円</td>
                      <td class="border border-black p-[1.5mm]"></td>
                    </tr>
                    <tr class="h-[9mm]">
                      <td class="border border-black p-[1.5mm] text-center">納付すべき税額　④</td>
                      <td class="border border-black p-[1.5mm] text-right text-[16px] font-semibold">{{ formatInteger(finalPayableTaxAmount) }}　円</td>
                      <td class="border border-black p-[1.5mm]"></td>
                    </tr>
                  </tbody>
                </table>

                <table class="w-full border-collapse border-2 border-black text-[10px]">
                  <tbody>
                    <tr class="h-[11mm]">
                      <td class="w-[68mm] border border-black p-[1.5mm]">納期限の延長</td>
                      <td class="border border-black p-[1.5mm] text-center">還付される税金の受取場所</td>
                      <td class="w-[52mm] border border-black p-[1.5mm] text-center">摘　要</td>
                    </tr>
                    <tr class="h-[25mm]">
                      <td class="border border-black p-[1.5mm]">税理士署名押印</td>
                      <td class="border border-black p-[1.5mm]">
                        <div>銀行等の預貯金口座に振込みを希望する場合</div>
                        <div class="mt-[4mm]">口座種類　普通　　口座番号</div>
                      </td>
                      <td class="border border-black p-[1.5mm]"></td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div v-else-if="activeFormTab === 'LIA110'" class="space-y-[2mm]">
                <div class="grid grid-cols-[65mm_1fr_55mm] items-start">
                  <div class="space-y-[2mm] text-[14px]">
                    <div>ＣＣ１－５２０５－２</div>
                    <div class="pl-[18mm] text-[18px]">{{ reportPeriodText }}</div>
                    <div class="text-[11px]">（本表の２）</div>
                  </div>
                  <div class="pt-[9mm] text-center text-[22px] font-bold tracking-[0.35em]">税　額　算　出　表</div>
                  <div class="pt-[6mm] text-right text-[14px]">（　　/　　）</div>
                  <div class="col-start-3 mt-[1mm] border-2 border-black text-[11px]">
                    <div class="grid grid-cols-[18mm_1fr]">
                      <div class="border-r border-black px-[2mm] py-[1mm]">製造場名</div>
                      <div class="px-[2mm] py-[1mm] font-semibold">{{ tenantProfile.SEIZOJO_NM || tenantName || '' }}</div>
                    </div>
                  </div>
                </div>
                <table class="w-full border-collapse border-2 border-black text-[8.5px]">
                  <thead>
                    <tr class="align-middle">
                      <th class="w-[8mm] border border-black p-[0.8mm] font-normal">順<br />号</th>
                      <th class="w-[8mm] border border-black p-[0.8mm] font-normal">区<br />分</th>
                      <th class="w-[12mm] border border-black p-[0.8mm] font-normal">酒類<br />コード</th>
                      <th class="w-[35mm] border border-black p-[0.8mm] font-normal">酒類の品目別</th>
                      <th class="w-[12mm] border border-black p-[0.8mm] font-normal">アルコール<br />分別<br />度</th>
                      <th class="w-[26mm] border border-black p-[0.8mm] font-normal">①総移出数量<br /><span class="float-right text-[7px]">ML</span></th>
                      <th class="w-[29mm] border border-black p-[0.8mm] font-normal">②未納税移出数量<br />③輸出免税数量<br /><span class="float-right text-[7px]">ML</span></th>
                      <th class="w-[26mm] border border-black p-[0.8mm] font-normal">④課税標準数量<br /><span class="float-right text-[7px]">ML</span></th>
                      <th class="w-[16mm] border border-black p-[0.8mm] font-normal">⑤税率<br /><span class="float-right text-[7px]">円</span></th>
                      <th class="w-[25mm] border border-black p-[0.8mm] font-normal">⑦軽減後税額<br />⑥税額<br /><span class="float-right text-[7px]">円</span></th>
                      <th class="w-[27mm] border border-black p-[0.8mm] font-normal">控除数量<br />⑧控除税額<br /><span class="float-right text-[7px]">ML　円</span></th>
                      <th class="w-[28mm] border border-black p-[0.8mm] font-normal">⑨算出税額<br />（⑥－⑧）又は<br />（⑦－⑧）<br /><span class="float-right text-[7px]">円</span></th>
                      <th class="border border-black p-[0.8mm] font-normal">摘要</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(row, index) in movementTableRows" :key="`preview-${row.item.key}`" class="h-[7.2mm]">
                      <td class="border border-black p-[0.8mm] text-center">{{ index + 1 }}</td>
                      <td class="border border-black p-[0.8mm] text-center">{{ lia110KubunCodeForItem(row.item) }}</td>
                      <td class="border border-black p-[0.8mm] text-center">{{ row.item.categoryCode }}</td>
                      <td class="border border-black p-[0.8mm] font-semibold">{{ row.item.categoryName }}</td>
                      <td class="border border-black p-[0.8mm] text-right">{{ formatAbv(row.item.abv) }}</td>
                      <td class="border border-black p-[0.8mm] text-right">{{ formatMilliliters(row.item.volume_l) }}</td>
                      <td class="border border-black p-0">
                        <div class="h-1/2 border-b border-black px-[0.8mm] text-right">{{ formatMilliliters(row.item.non_taxable_volume_l) }}</div>
                        <div class="px-[0.8mm] text-right">{{ formatMilliliters(row.item.export_exempt_volume_l) }}</div>
                      </td>
                      <td class="border border-black p-[0.8mm] text-right">{{ formatMilliliters(row.item.taxable_volume_l) }}</td>
                      <td class="border border-black p-[0.8mm] text-right">{{ formatInteger(row.item.tax_rate) }}</td>
                      <td class="border border-black p-0">
                        <div class="h-1/2 border-b border-black px-[0.8mm] text-right">（{{ formatInteger(row.item.tax_amount ?? 0) }}）</div>
                        <div class="px-[0.8mm] text-right">{{ formatInteger(row.item.tax_amount ?? 0) }}</div>
                      </td>
                      <td class="border border-black p-0">
                        <div class="h-1/2 border-b border-black px-[0.8mm] text-right"></div>
                        <div class="px-[0.8mm] text-right"></div>
                      </td>
                      <td class="border border-black p-[0.8mm] text-right">{{ formatInteger(previewTaxAmount(row.item)) }}</td>
                      <td class="border border-black p-[0.8mm]">{{ movementRowLabel(row.item) }}</td>
                    </tr>
                    <tr v-if="movementTableRows.length === 0" class="h-[7.2mm]">
                      <td colspan="13" class="border border-black p-[1mm] text-center">{{ t('taxReportEditor.preview.empty') }}</td>
                    </tr>
                    <tr v-for="index in lia110BlankRowCount" :key="`lia110-blank-${index}`" class="h-[7.2mm]">
                      <td class="border border-black p-[0.8mm] text-center">{{ movementTableRows.length + index }}</td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div v-else-if="activeFormTab === 'LIA130'" class="space-y-[4mm]">
                <div class="grid grid-cols-[76mm_1fr_128mm] items-start">
                  <div class="space-y-[3mm] pl-[12mm] text-[19px]">
                    <div>{{ reportPeriodText }}</div>
                    <div>令和　　年　　月　　日分</div>
                  </div>
                  <div class="pt-[10mm] text-center text-[21px] font-bold tracking-[0.35em]">軽 減 税 額 算 出 表</div>
                  <div class="mt-[1mm] border-2 border-black text-[13px]">
                    <div class="grid h-[8mm] grid-cols-[24mm_1fr] border-b-2 border-black">
                      <div class="border-r border-black px-[2mm] py-[1.5mm]">整理番号</div>
                      <div class="px-[2mm] py-[1.5mm]"></div>
                    </div>
                    <div class="grid h-[8mm] grid-cols-[24mm_1fr]">
                      <div class="border-r border-black px-[2mm] py-[1.5mm]">製造場名</div>
                      <div class="px-[2mm] py-[1.5mm] font-semibold">{{ tenantProfile.SEIZOJO_NM || tenantName || '' }}</div>
                    </div>
                  </div>
                </div>

                <table class="w-full border-collapse border-2 border-black text-[10px]">
                  <colgroup>
                    <col class="w-[11mm]" />
                    <col class="w-[72mm]" />
                    <col class="w-[7mm]" />
                    <col class="w-[65mm]" />
                    <col class="w-[61mm]" />
                    <col class="w-[61mm]" />
                  </colgroup>
                  <thead>
                    <tr class="h-[10mm]">
                      <th
                        colspan="3"
                        rowspan="2"
                        class="border border-black p-0 font-normal"
                        style="background-image: linear-gradient(to top right, transparent calc(50% - 0.7px), #111 calc(50% - 0.7px), #111 calc(50% + 0.7px), transparent calc(50% + 0.7px));"
                      ></th>
                      <th rowspan="2" class="border border-black p-[1.5mm] font-normal">
                        全製造場の本則税額(円)<br />Ⓐ
                      </th>
                      <th colspan="2" class="border border-black p-[1mm] font-normal">申告対象製造場</th>
                    </tr>
                    <tr class="h-[9mm]">
                      <th class="border border-black p-[1mm] font-normal">本則税額(円)<br />Ⓑ</th>
                      <th class="border border-black p-[1mm] font-normal">軽減後税額(円)<br />Ⓒ</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr class="h-[10mm] border-t-2 border-black">
                      <td class="border border-black"></td>
                      <td class="border border-black p-[1mm] text-center">前月までの当年度酒税累計額</td>
                      <td class="border border-black text-center">①</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.priorFiscalYearStandardTaxAmount) }}</td>
                      <td
                        class="border border-black bg-gray-300"
                        style="background-image: linear-gradient(to bottom left, transparent calc(50% - 0.7px), #111 calc(50% - 0.7px), #111 calc(50% + 0.7px), transparent calc(50% + 0.7px));"
                      ></td>
                      <td
                        class="border border-black bg-gray-300"
                        style="background-image: linear-gradient(to bottom left, transparent calc(50% - 0.7px), #111 calc(50% - 0.7px), #111 calc(50% + 0.7px), transparent calc(50% + 0.7px));"
                      ></td>
                    </tr>
                    <tr class="h-[10mm]">
                      <td rowspan="5" class="border border-black p-[1mm] text-center leading-[1.45]" style="writing-mode: vertical-rl;">
                        当月の当年度酒税累計額の計算
                      </td>
                      <td class="border border-black p-[1mm]">軽減対象酒類の移出に係る税額</td>
                      <td class="border border-black text-center">②</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.currentMonthStandardTaxAmount) }}</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.currentMonthStandardTaxAmount) }}</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.currentMonthReducedTaxAmount) }}</td>
                    </tr>
                    <tr class="h-[10mm]">
                      <td class="border border-black p-[1mm] text-center">0円〜5,000万円以下</td>
                      <td class="border border-black text-center">③</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.currentMonthStandardTaxAmount) }}</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.currentMonthStandardTaxAmount) }}</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.currentMonthReducedTaxAmount) }}</td>
                    </tr>
                    <tr class="h-[10mm]">
                      <td class="border border-black p-[1mm] text-center">5,000万円超〜8,000万円以下</td>
                      <td class="border border-black text-center">④</td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                    </tr>
                    <tr class="h-[10mm]">
                      <td class="border border-black p-[1mm] text-center">8,000万円超〜1億円以下</td>
                      <td class="border border-black text-center">⑤</td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                    </tr>
                    <tr class="h-[10mm]">
                      <td class="border border-black p-[1mm] text-center">1億円超(本則税額と軽減後税額は同額)</td>
                      <td class="border border-black text-center">⑥</td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                    </tr>
                    <tr class="h-[10mm] border-t-2 border-black">
                      <td class="border border-black"></td>
                      <td class="border border-black p-[1mm] text-center">控除税額計算前の当年度酒税累計額<br />(①＋②)</td>
                      <td class="border border-black text-center">⑦</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.cumulativeBeforeReturnStandardTaxAmount) }}</td>
                      <td
                        class="border border-black bg-gray-300"
                        style="background-image: linear-gradient(to bottom left, transparent calc(50% - 0.7px), #111 calc(50% - 0.7px), #111 calc(50% + 0.7px), transparent calc(50% + 0.7px));"
                      ></td>
                      <td
                        class="border border-black bg-gray-300"
                        style="background-image: linear-gradient(to bottom left, transparent calc(50% - 0.7px), #111 calc(50% - 0.7px), #111 calc(50% + 0.7px), transparent calc(50% + 0.7px));"
                      ></td>
                    </tr>
                    <tr class="h-[10mm] border-t-2 border-black">
                      <td class="border border-black"></td>
                      <td class="border border-black p-[1mm] text-center">戻入れ酒類の控除税額の合計</td>
                      <td class="border border-black text-center">⑧</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.returnStandardTaxAmount) }}</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.returnStandardTaxAmount) }}</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.returnReducedTaxAmount) }}</td>
                    </tr>
                    <tr class="h-[10mm]">
                      <td class="border border-black"></td>
                      <td class="border border-black p-[1mm] text-center">差引酒税額<br />(②−⑧)</td>
                      <td class="border border-black text-center">⑨</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.currentMonthStandardTaxAmount - taxReductionPreview.returnStandardTaxAmount) }}</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.netStandardTaxAmount) }}</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.netReducedTaxAmount) }}</td>
                    </tr>
                    <tr class="h-[10mm] border-t-2 border-black">
                      <td class="border border-black"></td>
                      <td class="border border-black p-[1mm] text-center">当年度酒税累計額<br />(①＋⑨)</td>
                      <td class="border border-black text-center">⑩</td>
                      <td class="border border-black p-[1mm] text-right">{{ formatInteger(taxReductionPreview.cumulativeAfterReturnStandardTaxAmount) }}</td>
                      <td
                        class="border border-black bg-gray-300"
                        style="background-image: linear-gradient(to bottom left, transparent calc(50% - 0.7px), #111 calc(50% - 0.7px), #111 calc(50% + 0.7px), transparent calc(50% + 0.7px));"
                      ></td>
                      <td
                        class="border border-black bg-gray-300"
                        style="background-image: linear-gradient(to bottom left, transparent calc(50% - 0.7px), #111 calc(50% - 0.7px), #111 calc(50% + 0.7px), transparent calc(50% + 0.7px));"
                      ></td>
                    </tr>
                  </tbody>
                </table>

                <div class="grid grid-cols-[74mm_1fr] gap-[6mm]">
                  <div class="grid h-[44mm] grid-rows-[18mm_1fr] border-2 border-black">
                    <div class="flex items-center justify-center border-b border-black">軽減割合の区分</div>
                    <div class="flex items-center justify-center text-[13px]">{{ taxReductionPreview.category }}</div>
                  </div>
                  <div class="space-y-[4mm]">
                    <table class="w-full border-collapse border-2 border-black text-[10px]">
                      <tbody>
                        <tr class="h-[10mm]">
                          <td class="border border-black p-[1mm] text-center">申告対象製造場　軽減対象外酒類の移出に係る税額</td>
                          <td class="w-[7mm] border border-black text-center">⑪</td>
                          <td class="w-[62mm] border border-black"></td>
                        </tr>
                        <tr class="h-[10mm]">
                          <td class="border border-black p-[1mm] text-center">申告対象製造場　移入酒類の再移出等控除税額の合計</td>
                          <td class="border border-black text-center">⑫</td>
                          <td class="border border-black"></td>
                        </tr>
                        <tr class="h-[10mm]">
                          <td class="border border-black p-[1mm] text-center">申告対象製造場　被災酒類に対する酒税の控除税額の合計</td>
                          <td class="border border-black text-center">⑬</td>
                          <td class="border border-black"></td>
                        </tr>
                      </tbody>
                    </table>
                    <table class="w-full border-collapse border-2 border-black text-[10px]">
                      <tbody>
                        <tr class="h-[10mm]">
                          <td class="border border-black p-[1mm] text-center">申告対象製造場　合計酒税額<br />（⑨Ⓒ＋⑪−⑫−⑬）</td>
                          <td class="w-[7mm] border border-black text-center">⑭</td>
                          <td class="w-[62mm] border border-black p-[1mm] text-right font-semibold">{{ formatInteger(taxReductionPreview.netReducedTaxAmount) }}</td>
                        </tr>
                      </tbody>
                    </table>
                    <div class="text-right text-[10px]">※酒税納税申告書の①へ記載</div>
                  </div>
                </div>
              </div>

              <div v-else-if="activeFormTab === 'LIA220'" class="space-y-[2mm]">
                <div class="grid grid-cols-[75mm_1fr_54mm] items-start">
                  <div class="space-y-[2mm] text-[14px]">
                    <div>ＣＣ１－５２０５－４</div>
                    <div class="pl-[18mm] text-[18px]">{{ reportPeriodText }}</div>
                    <div class="text-[11px]">（付表２）</div>
                  </div>
                  <div class="pt-[9mm] text-center text-[20px] font-bold">戻入れ酒類の控除（還付）税額計算書</div>
                  <div class="pt-[7mm] text-right text-[14px]">（　　/　　）</div>
                  <div class="col-start-3 mt-[1mm] border-2 border-black text-[11px]">
                    <div class="grid grid-cols-[18mm_1fr]">
                      <div class="border-r border-black px-[2mm] py-[1mm]">製造場名</div>
                      <div class="px-[2mm] py-[1mm] font-semibold">{{ tenantProfile.SEIZOJO_NM || tenantName || '' }}</div>
                    </div>
                  </div>
                </div>
                <table class="w-full border-collapse border-2 border-black text-[9px]">
                  <thead>
                    <tr>
                      <th class="w-[7mm] border border-black p-[0.8mm] font-normal">順<br />号</th>
                      <th class="w-[8mm] border border-black p-[0.8mm] font-normal">区<br />分</th>
                      <th class="w-[12mm] border border-black p-[0.8mm] font-normal">酒類<br />コード</th>
                      <th class="w-[36mm] border border-black p-[0.8mm] font-normal">酒類の品目別</th>
                      <th class="w-[13mm] border border-black p-[0.8mm] font-normal">アルコール<br />分別<br />度</th>
                      <th class="w-[28mm] border border-black p-[0.8mm] font-normal">数量<br /><span class="float-right text-[7px]">ML</span></th>
                      <th class="w-[16mm] border border-black p-[0.8mm] font-normal">税率<br /><span class="float-right text-[7px]">円</span></th>
                      <th class="w-[25mm] border border-black p-[0.8mm] font-normal">税額<br /><span class="float-right text-[7px]">円</span></th>
                      <th class="w-[24mm] border border-black p-[0.8mm] font-normal">軽減後税額<br /><span class="float-right text-[7px]">円</span></th>
                      <th class="border border-black p-[0.8mm] font-normal">摘要</th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(row, index) in returnTableRows" :key="`return-preview-${row.item.key}`" class="h-[7.2mm]">
                      <td class="border border-black p-[0.8mm] text-center">{{ index + 1 }}</td>
                      <td class="border border-black p-[0.8mm] text-center">1</td>
                      <td class="border border-black p-[0.8mm] text-center">{{ row.item.categoryCode }}</td>
                      <td class="border border-black p-[0.8mm] font-semibold">{{ row.item.categoryName }}</td>
                      <td class="border border-black p-[0.8mm] text-right">{{ formatAbv(row.item.abv) }}</td>
                      <td class="border border-black p-[0.8mm] text-right">{{ formatMilliliters(row.item.volume_l) }}</td>
                      <td class="border border-black p-[0.8mm] text-right">{{ formatInteger(row.item.tax_rate) }}</td>
                      <td class="border border-black p-[0.8mm] text-right">{{ formatInteger(previewReturnTaxAmount(row.item)) }}</td>
                      <td class="border border-black p-[0.8mm] text-right"></td>
                      <td class="border border-black p-[0.8mm]">{{ breakdownMovementLabel(row.item) }}</td>
                    </tr>
                    <tr v-if="returnTableRows.length === 0" class="h-[7.2mm]">
                      <td colspan="10" class="border border-black p-[1mm] text-center">{{ t('taxReportEditor.preview.empty') }}</td>
                    </tr>
                    <tr v-for="index in lia220BlankRowCount" :key="`lia220-blank-${index}`" class="h-[7.2mm]">
                      <td class="border border-black p-[0.8mm] text-center">{{ returnTableRows.length + index }}</td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                    </tr>
                  </tbody>
                </table>
              </div>

              <div v-else-if="activeFormTab === 'LIA260'" class="space-y-[2mm]">
                <div class="grid grid-cols-[75mm_1fr_54mm] items-start">
                  <div class="space-y-[2mm] text-[14px]">
                    <div>ＣＣ１－５２０５－８</div>
                    <div class="pl-[18mm] text-[18px]">{{ reportPeriodText }}</div>
                    <div class="text-[11px]">（付表６）</div>
                  </div>
                  <div class="pt-[5mm] text-center text-[18px] font-bold leading-snug">
                    輸出免税酒類輸出明細書　兼<br />
                    輸出酒類販売場における購入明細書
                  </div>
                  <div class="pt-[7mm] text-right text-[14px]">（　　/　　）</div>
                  <div class="col-start-3 mt-[1mm] border-2 border-black text-[11px]">
                    <div class="grid grid-cols-[18mm_1fr]">
                      <div class="border-r border-black px-[2mm] py-[1mm]">製造場名</div>
                      <div class="px-[2mm] py-[1mm] font-semibold">{{ tenantProfile.SEIZOJO_NM || tenantName || '' }}</div>
                    </div>
                  </div>
                </div>
                <table class="w-full border-collapse border-2 border-black text-[8.5px]">
                  <thead>
                    <tr>
                      <th class="w-[7mm] border border-black p-[0.8mm] font-normal">順<br />号</th>
                      <th class="w-[8mm] border border-black p-[0.8mm] font-normal">区<br />分</th>
                      <th class="w-[13mm] border border-black p-[0.8mm] font-normal">酒類<br />コード</th>
                      <th class="w-[32mm] border border-black p-[0.8mm] font-normal">酒類の品目別等</th>
                      <th class="w-[12mm] border border-black p-[0.8mm] font-normal">アルコール<br />分別<br />度</th>
                      <th class="w-[26mm] border border-black p-[0.8mm] font-normal">数量<br /><span class="float-right text-[7px]">ML</span></th>
                      <th class="w-[32mm] border border-black p-[0.8mm] font-normal">輸出年月日<br />又は<br />販売年月日</th>
                      <th class="w-[24mm] border border-black p-[0.8mm] font-normal">仕向地</th>
                      <th class="w-[24mm] border border-black p-[0.8mm] font-normal">輸出港の<br />所轄税関</th>
                      <th class="border border-black p-[0.8mm] font-normal">
                        輸出者 又 は<br />国際第二種貨物利用運送事業者<br />の住所及び氏名又は名称
                      </th>
                    </tr>
                  </thead>
                  <tbody>
                    <tr v-for="(row, index) in exportExemptRows" :key="`export-preview-${row.key}`" class="h-[13.5mm]">
                      <td class="border border-black p-[0.8mm] text-center">{{ index + 1 }}</td>
                      <td class="border border-black p-[0.8mm] text-center">0</td>
                      <td class="border border-black p-[0.8mm] text-center">{{ row.categoryCode }}</td>
                      <td class="border border-black p-[0.8mm] font-semibold">{{ row.categoryName }}</td>
                      <td class="border border-black p-[0.8mm] text-right">{{ formatAbv(row.abv) }}</td>
                      <td class="border border-black p-[0.8mm] text-right">{{ formatMilliliters(row.volume_l) }}</td>
                      <td class="border border-black p-[0.8mm]">{{ reportDateText }}</td>
                      <td class="border border-black p-[0.8mm]"></td>
                      <td class="border border-black p-[0.8mm]"></td>
                      <td class="border border-black p-[0.8mm] leading-[1.7]">
                        {{ tenantProfile.NOZEISHA_NM || tenantName || '' }}<br />
                        {{ tenantProfile.NOZEISHA_ADR || '' }}
                      </td>
                    </tr>
                    <tr v-if="exportExemptRows.length === 0" class="h-[13.5mm]">
                      <td colspan="10" class="border border-black p-[1mm] text-center">{{ t('taxReportEditor.preview.empty') }}</td>
                    </tr>
                    <tr v-for="index in lia260BlankRowCount" :key="`lia260-blank-${index}`" class="h-[13.5mm]">
                      <td class="border border-black p-[0.8mm] text-center">{{ exportExemptRows.length + index }}</td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black p-[0.8mm]">令和　年　月　日</td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                      <td class="border border-black"></td>
                    </tr>
                  </tbody>
                </table>
                <div class="grid min-h-[25mm] grid-cols-[22mm_1fr] border-2 border-black">
                  <div class="border-r border-black p-[2mm]">参考事項</div>
                  <div class="p-[2mm]"></div>
                </div>
              </div>
            </div>
                </div>
              </div>
            </div>
          </section>

          <section v-if="showDisposeSection" class="space-y-3">
            <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
              <div>
                <h2 class="text-base font-semibold">{{ t('taxReport.sections.dispose.title') }}</h2>
                <p class="text-xs text-gray-500">{{ t('taxReport.sections.dispose.subtitle') }}</p>
              </div>
              <div class="flex flex-wrap items-center gap-2">
                <button
                  class="rounded border px-3 py-2 hover:bg-gray-50 disabled:opacity-50"
                  :disabled="generating"
                  @click="createXmlForDispose"
                >
                  {{ t('taxReport.actions.createXml') }}
                </button>
                <a v-if="disposeXmlUrl" :href="disposeXmlUrl" :download="disposeXmlName" class="text-xs text-blue-600">
                  {{ t('taxReport.actions.downloadXml') }}
                </a>
              </div>
            </div>
            <div class="overflow-x-auto rounded border bg-gray-50">
              <table class="min-w-full text-sm">
                <thead class="bg-white text-xs uppercase text-gray-500">
                  <tr>
                    <th class="px-3 py-2 text-left">{{ t('taxReportEditor.columns.taxEvent') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.category') }}</th>
                    <th class="px-3 py-2 text-left">{{ t('taxReport.breakdown.columns.abv') }}</th>
                    <th class="px-3 py-2 text-right">{{ t('taxReport.breakdown.columns.volume') }}</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-100">
                  <tr v-for="(item, index) in disposeBreakdown" :key="item.key">
                    <td class="px-3 py-2 text-gray-700">{{ breakdownMovementLabel(item) }}</td>
                    <td class="px-3 py-2 text-gray-700">{{ item.categoryName }}</td>
                    <td class="px-3 py-2">
                      <input
                        v-model.number="item.abv"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2"
                        @input="handleDisposeChange(index)"
                      />
                    </td>
                    <td class="px-3 py-2 text-right">
                      <input
                        v-model.number="item.volume_l"
                        type="number"
                        min="0"
                        step="0.01"
                        class="h-[36px] w-full rounded border bg-white px-2 text-right"
                        @input="handleDisposeChange(index)"
                      />
                    </td>
                  </tr>
                  <tr v-if="disposeBreakdown.length === 0">
                    <td colspan="4" class="px-3 py-4 text-center text-xs text-gray-400">{{ t('taxReport.emptyBreakdown') }}</td>
                  </tr>
                </tbody>
              </table>
            </div>
          </section>
          </section>

          <section class="space-y-3">
            <div>
              <h2 class="text-base font-semibold">{{ t('taxReportEditor.sections.files.title') }}</h2>
              <p class="text-xs text-gray-500">{{ t('taxReportEditor.sections.files.subtitle') }}</p>
            </div>
            <div class="space-y-2 rounded border bg-gray-50 p-3">
              <div
                v-for="file in displayReportFiles"
                :key="`${file.fileType}-${file.fileName}`"
                class="flex flex-col gap-2 rounded border bg-white px-3 py-2 text-sm md:flex-row md:items-center md:justify-between"
              >
                <div class="min-w-0">
                  <div class="truncate font-medium text-gray-800">{{ file.fileName }}</div>
                  <div class="text-xs text-gray-500">
                    {{ file.saved ? t('taxReportEditor.sections.files.saved') : t('taxReportEditor.sections.files.pending') }}
                  </div>
                </div>
                <button
                  v-if="file.saved"
                  class="rounded border px-3 py-1.5 text-xs hover:bg-gray-50"
                  type="button"
                  @click="downloadSavedReportFile(file)"
                >
                  {{ t('taxReportEditor.sections.files.download') }}
                </button>
              </div>
              <p v-if="displayReportFiles.length === 0" class="text-xs text-gray-400">
                {{ t('taxReportEditor.sections.files.empty') }}
              </p>
            </div>
            <label class="block text-sm text-gray-600">{{ t('taxReport.form.attachments') }}</label>
            <input type="file" multiple class="h-[40px] w-full rounded border px-3 py-2" @change="handleAttachmentUpload" />
            <div v-if="attachmentList.length" class="flex flex-wrap gap-2 text-xs">
              <span
                v-for="file in attachmentList"
                :key="file"
                class="inline-flex items-center gap-2 rounded-full border border-gray-200 px-2.5 py-1 text-gray-700"
              >
                {{ file }}
                <button class="text-gray-400 hover:text-gray-700" type="button" @click="removeAttachment(file)">×</button>
              </span>
            </div>
            <p v-else class="text-xs text-gray-400">{{ t('taxReport.form.attachmentsHint') }}</p>
          </section>

          <footer class="flex items-center justify-between border-t pt-4">
            <div class="text-xs text-gray-500">
              <span v-if="generating">{{ t('taxReport.generating') }}</span>
            </div>
            <div class="flex items-center gap-2">
              <button class="rounded border px-3 py-2 hover:bg-gray-50" @click="goBack">{{ t('common.cancel') }}</button>
              <button
                class="rounded bg-blue-600 px-3 py-2 text-white hover:bg-blue-700 disabled:opacity-50"
                :disabled="saving || generating || loadingInitial"
                @click="saveReport"
              >
                {{ saving ? t('common.saving') : t('common.save') }}
              </button>
            </div>
          </footer>
        </section>
      </div>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { computed, nextTick, onMounted, onUnmounted, reactive, ref, watch } from 'vue'
import { useI18n } from 'vue-i18n'
import { useRoute, useRouter } from 'vue-router'
import { toast } from 'vue3-toastify'
import 'vue3-toastify/dist/index.css'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import { formatRpcErrorMessage, parseRpcError } from '@/lib/rpcErrors'
import { supabase } from '@/lib/supabase'
import { formatAbvPercent } from '@/lib/abvFormat'
import {
  createEmptyTaxReportProfile,
  fetchTaxReportProfileForTenant,
  type TaxReportProfile,
} from '@/lib/taxReportProfile'
import {
  calculateTaxTotalAmount,
  buildLia110ReportRows,
  buildTaxReductionPreview,
  buildDisposeXmlFilename,
  buildXmlFilename,
  buildXmlPayload,
  downloadStoredTaxReportFile,
  disposeItemsFromBreakdown,
  fetchPriorFiscalYearStandardTaxAmount,
  type GeneratedTaxReportFile,
  inferStoredFileType,
  mergeStoredFiles,
  normalizeReport,
  parseFileList,
  removeStoredTaxReportFiles,
  resolveTaxEvent,
  isReturnTaxEvent,
  lia110KubunCodeForItem,
  sortTaxVolumeItems,
  summaryItemsFromBreakdown,
  type TaxReportStoredFile,
  uploadGeneratedTaxReportFiles,
  type JsonMap,
  type TaxVolumeItem,
} from '@/lib/taxReport'
import {
  buildTaxableRemovalBusinessYearFileName,
  businessYearForDate,
  createTaxableRemovalBusinessYearWorkbookBlob,
  loadTaxableRemovalDetailRows,
  type TaxableRemovalExportLabels,
} from '@/lib/taxableRemovalReport'
import {
  buildTaxLedgerBusinessYearFileName,
  createTaxLedgerBusinessYearWorkbookBlob,
  getTaxLedgerConfig,
  loadTaxLedgerDetailRows,
  type TaxLedgerColumnKey,
  type TaxLedgerExportLabels,
  type TaxLedgerKey,
} from '@/lib/taxLedgerReport'
import { formatYen, nonNegativeYen, taxAmountFromLiters, truncateYen } from '@/lib/moneyFormat'
import {
  formatMilliliters as formatMillilitersValue,
  litersToMilliliters,
} from '@/lib/volumeFormat'
import { useRuleengineLabels } from '@/composables/useRuleengineLabels'

type MovementSortKey = 'kubun' | 'taxEvent' | 'category' | 'abv' | 'volume'
type MovementSortDirection = 'asc' | 'desc'
type EditorMode = 'edit' | 'preview'
type TaxReportFormTab = 'LIA010' | 'LIA110' | 'LIA130' | 'LIA220' | 'LIA260'
type SupportingLedgerFileType = Extract<
  GeneratedTaxReportFile['fileType'],
  | 'non_taxable_removal_ledger_excel'
  | 'export_exempt_ledger_excel'
  | 'non_taxable_receipt_ledger_excel'
  | 'return_to_factory_ledger_excel'
>

interface MovementTableRow {
  item: TaxVolumeItem
  sourceIndex: number | null
  editable: boolean
}

interface EditorField {
  code: string
  label: string
  value: string
  highlight?: boolean
}

const TABLE = 'tax_reports'
const STATUS_OPTIONS = ['draft', 'stale', 'submitted', 'approved'] as const
type TaxReportStatus = (typeof STATUS_OPTIONS)[number]
const TAX_TYPE_OPTIONS = ['monthly'] as const
const PREVIEW_PAGE_WIDTH_MM = 297
const PREVIEW_PAGE_HEIGHT_MM = 210
const PREVIEW_MIN_ZOOM = 0.4
const PREVIEW_MAX_ZOOM = 2
const PREVIEW_ZOOM_STEP = 0.1
const CSS_PIXELS_PER_MM = 96 / 25.4
const showDisposeSection = false
const taxLedgerKeys: TaxLedgerKey[] = [
  'nonTaxableRemoval',
  'exportExempt',
  'nonTaxableReceipt',
  'returnToFactory',
]
const taxLedgerFileTypes: Record<TaxLedgerKey, SupportingLedgerFileType> = {
  nonTaxableRemoval: 'non_taxable_removal_ledger_excel',
  exportExempt: 'export_exempt_ledger_excel',
  nonTaxableReceipt: 'non_taxable_receipt_ledger_excel',
  returnToFactory: 'return_to_factory_ledger_excel',
}
const taxLedgerColumnKeys: TaxLedgerColumnKey[] = [
  'movementAt',
  'item',
  'brand',
  'abv',
  'container',
  'packageCount',
  'quantityMl',
  'taxRate',
  'sourceAddress',
  'sourceName',
  'destinationAddress',
  'destinationName',
  'recipientAddress',
  'location',
  'exporterAddress',
  'exportDestinationAddress',
  'exportDestinationName',
  'transferorAddress',
  'deliveryAddress',
  'lotNo',
  'notes',
]

const { t, tm, locale } = useI18n()
const route = useRoute()
const router = useRouter()
const { loadRuleengineLabels, ruleLabel } = useRuleengineLabels()

const loadingInitial = ref(false)
const saving = ref(false)
const generating = ref(false)
const tenantId = ref<string | null>(null)
const tenantName = ref('')
const tenantProfile = ref<TaxReportProfile>(createEmptyTaxReportProfile())

const form = reactive({
  id: '',
  tax_type: 'monthly',
  tax_year: new Date().getFullYear(),
  tax_month: new Date().getMonth() + 1,
  status: 'draft',
  attachment_files: '',
})
const savedReportStatus = ref<TaxReportStatus>('draft')

const errors = reactive<Record<string, string>>({})
const reportBreakdown = ref<TaxVolumeItem[]>([])
const disposeBreakdown = ref<TaxVolumeItem[]>([])
const totalTaxAmount = ref(0)
const priorFiscalYearStandardTaxAmount = ref(0)
const reductionPreviewLoading = ref(false)
const reductionPreviewError = ref('')
const summaryXmlUrl = ref('')
const summaryXmlName = ref('')
const disposeXmlUrl = ref('')
const disposeXmlName = ref('')
const storedReportFiles = ref<TaxReportStoredFile[]>([])
const previewViewport = ref<HTMLElement | null>(null)
const previewZoom = ref(1)
const previewDragging = ref(false)
const previewDragState = reactive({
  pointerId: null as number | null,
  startX: 0,
  startY: 0,
  scrollLeft: 0,
  scrollTop: 0,
})
const movementSort = reactive<{
  key: MovementSortKey
  direction: MovementSortDirection
}>({
  key: 'category',
  direction: 'asc',
})
const editorMode = ref<EditorMode>('preview')
const activeFormTab = ref<TaxReportFormTab>('LIA010')

const editing = computed(() => typeof route.params.id === 'string' && route.params.id.length > 0)
const pageTitle = computed(() => (editing.value ? t('taxReportEditor.editTitle') : t('taxReportEditor.newTitle')))
const statusOptions = STATUS_OPTIONS
const taxTypeOptions = TAX_TYPE_OPTIONS
const monthOptions = computed(() => [4, 5, 6, 7, 8, 9, 10, 11, 12, 1, 2, 3])
const editorModes = computed<Array<{ id: EditorMode; label: string }>>(() => [
  { id: 'edit', label: t('taxReportEditor.modes.edit') },
  { id: 'preview', label: t('taxReportEditor.modes.preview') },
])
const toShortTabText = (value: string) => {
  const characters = Array.from(value)
  return characters.length <= 14 ? value : characters.slice(0, 14).join('')
}
const formTabs = computed<Array<{ id: TaxReportFormTab; label: string; title: string; ariaLabel: string }>>(() => [
  {
    id: 'LIA010',
    label: toShortTabText(t('taxReportEditor.forms.lia010.shortTitle')),
    title: toShortTabText(t('taxReportEditor.forms.lia010.shortTitle')),
    ariaLabel: t('taxReportEditor.forms.lia010.title'),
  },
  {
    id: 'LIA110',
    label: toShortTabText(t('taxReportEditor.forms.lia110.shortTitle')),
    title: toShortTabText(t('taxReportEditor.forms.lia110.shortTitle')),
    ariaLabel: t('taxReportEditor.forms.lia110.title'),
  },
  {
    id: 'LIA130',
    label: toShortTabText(t('taxReportEditor.forms.lia130.shortTitle')),
    title: toShortTabText(t('taxReportEditor.forms.lia130.shortTitle')),
    ariaLabel: t('taxReportEditor.forms.lia130.title'),
  },
  {
    id: 'LIA220',
    label: toShortTabText(t('taxReportEditor.forms.lia220.shortTitle')),
    title: toShortTabText(t('taxReportEditor.forms.lia220.shortTitle')),
    ariaLabel: t('taxReportEditor.forms.lia220.title'),
  },
  {
    id: 'LIA260',
    label: toShortTabText(t('taxReportEditor.forms.lia260.shortTitle')),
    title: toShortTabText(t('taxReportEditor.forms.lia260.shortTitle')),
    ariaLabel: t('taxReportEditor.forms.lia260.title'),
  },
])
const attachmentList = computed(() => parseFileList(form.attachment_files))
const reportBusinessYear = computed(() => businessYearForReportPeriod(form.tax_year, form.tax_month))
const expectedGeneratedFiles = computed(() => {
  const files: Array<{ fileName: string; fileType: GeneratedTaxReportFile['fileType'] }> = []
  if (reportBreakdown.value.length > 0) {
    files.push({
      fileName: buildXmlFilename(form.tax_type, form.tax_year, form.tax_month),
      fileType: 'tax_report_xml',
    })
  }
  if (disposeBreakdown.value.length > 0) {
    files.push({
      fileName: buildDisposeXmlFilename(form.tax_type, form.tax_year, form.tax_month),
      fileType: 'tax_report_dispose_xml',
    })
  }
  if (form.tax_type === 'monthly' && form.tax_month) {
    files.push({
      fileName: buildTaxableRemovalBusinessYearFileName(reportBusinessYear.value),
      fileType: 'taxable_removal_excel',
    })
    taxLedgerKeys.forEach((key) => {
      const config = getTaxLedgerConfig(key)
      files.push({
        fileName: buildTaxLedgerBusinessYearFileName(config, reportBusinessYear.value),
        fileType: taxLedgerFileTypes[key],
      })
    })
  }
  return files
})
const displayReportFiles = computed(() => {
  type DisplayReportFile = {
    fileName: string
    fileType: string
    saved: boolean
    stored: TaxReportStoredFile | null
  }
  const storedByType = new Map(storedReportFiles.value.map((file) => [String(file.fileType), file]))
  const rows: DisplayReportFile[] = expectedGeneratedFiles.value.map((file) => ({
    fileName: file.fileName,
    fileType: file.fileType,
    saved: storedByType.has(file.fileType),
    stored: storedByType.get(file.fileType) ?? null,
  }))

  storedReportFiles.value.forEach((file) => {
    const alreadyIncluded = rows.some((row) => row.fileType === file.fileType)
    if (!alreadyIncluded) {
      rows.push({
        fileName: file.fileName,
        fileType: file.fileType,
        saved: true,
        stored: file,
      })
    }
  })

  return rows.sort((a, b) => a.fileName.localeCompare(b.fileName))
})
const movementTableRows = computed<MovementTableRow[]>(() => {
  const sourceIndexByKey = new Map(reportBreakdown.value.map((item, index) => [item.key, index]))
  const rows = buildLia110ReportRows(reportBreakdown.value).map((item) => ({
    item,
    sourceIndex: (item.row_role ?? 'detail') === 'detail' ? sourceIndexByKey.get(item.key) ?? null : null,
    editable: (item.row_role ?? 'detail') === 'detail',
  }))

  return sortMovementTableRows(rows)
})
const returnTableRows = computed<MovementTableRow[]>(() =>
  reportBreakdown.value
    .map((item, index) => ({ item, sourceIndex: index, editable: true }))
    .filter((row) => isReturnTaxEvent(row.item.move_type, row.item.tax_event))
    .sort((a, b) => {
      const categoryResult = compareStrings(a.item.categoryName, b.item.categoryName, 'asc')
      if (categoryResult !== 0) return categoryResult
      return compareNullableNumbers(a.item.abv, b.item.abv, 'desc')
    }),
)
const exportExemptTableRows = computed<MovementTableRow[]>(() =>
  reportBreakdown.value
    .map((item, index) => ({ item, sourceIndex: index, editable: true }))
    .filter((row) => resolveTaxEvent(row.item.move_type, row.item.tax_event) === 'EXPORT_EXEMPT')
    .sort((a, b) => {
      const categoryResult = compareStrings(a.item.categoryName, b.item.categoryName, 'asc')
      if (categoryResult !== 0) return categoryResult
      return compareNullableNumbers(a.item.abv, b.item.abv, 'desc')
    }),
)
const taxReductionPreview = computed(() =>
  buildTaxReductionPreview({
    breakdown: reportBreakdown.value,
    priorFiscalYearStandardTaxAmount: priorFiscalYearStandardTaxAmount.value,
  }),
)
const filingTaxAmount = computed(() => taxReductionPreview.value.netReducedTaxAmount)
const roundedDownTaxAmount = computed(() => (filingTaxAmount.value > 0 ? filingTaxAmount.value % 100 : 0))
const finalPayableTaxAmount = computed(() => Math.max(0, filingTaxAmount.value - roundedDownTaxAmount.value))
const refundableTaxAmount = computed(() => Math.max(0, -filingTaxAmount.value))
const lia010EditorFields = computed<EditorField[]>(() => [
  { code: 'EFA00010', label: t('taxReportEditor.lia010.fields.filingPeriod'), value: reportPeriodText.value },
  { code: 'EFB00010', label: t('taxReportEditor.lia010.fields.submissionDate'), value: t('taxReportEditor.lia010.generatedAtXmlCreation') },
  { code: 'EFB00020', label: t('taxReportEditor.lia010.fields.taxOffice'), value: displayValue(tenantProfile.value.ZEIMUSHO.zeimusho_NM) },
  { code: 'EFB00030', label: t('taxReportEditor.lia010.fields.factoryZip'), value: formatZipParts(tenantProfile.value.SEIZOJO_ZIP) },
  { code: 'EFB00040', label: t('taxReportEditor.lia010.fields.factoryAddress'), value: displayValue(tenantProfile.value.SEIZOJO_ADR) },
  { code: 'EFB00050', label: t('taxReportEditor.lia010.fields.factoryName'), value: displayValue(tenantProfile.value.SEIZOJO_NM || tenantName.value) },
  { code: 'EFB00060', label: t('taxReportEditor.lia010.fields.factoryTel'), value: formatTelParts(tenantProfile.value.SEIZOJO_TEL) },
  { code: 'EFB00070', label: t('taxReportEditor.lia010.fields.taxpayerZip'), value: formatZipParts(tenantProfile.value.NOZEISHA_ZIP) },
  { code: 'EFB00080', label: t('taxReportEditor.lia010.fields.taxpayerAddress'), value: displayValue(tenantProfile.value.NOZEISHA_ADR) },
  { code: 'EFB00090', label: t('taxReportEditor.lia010.fields.taxpayerTel'), value: formatTelParts(tenantProfile.value.NOZEISHA_TEL) },
  { code: 'EFB00100', label: t('taxReportEditor.lia010.fields.taxpayerName'), value: displayValue(tenantProfile.value.NOZEISHA_NM || tenantName.value) },
  { code: 'EFB00110', label: t('taxReportEditor.lia010.fields.representativeName'), value: displayValue(tenantProfile.value.DAIHYO_NM) },
  { code: 'kubun_CD', label: t('taxReportEditor.lia010.fields.declarationType'), value: t('taxReportEditor.lia010.declarationTypeDefault') },
  { code: 'EFD00020', label: t('taxReportEditor.lia010.fields.taxAmount'), value: formatCurrency(filingTaxAmount.value), highlight: true },
  { code: 'EFD00030', label: t('taxReportEditor.lia010.fields.roundedDownAmount'), value: formatCurrency(roundedDownTaxAmount.value) },
  { code: 'EFD00040', label: t('taxReportEditor.lia010.fields.refundableTaxAmount'), value: formatCurrency(refundableTaxAmount.value) },
  { code: 'EFD00050', label: t('taxReportEditor.lia010.fields.payableTaxAmount'), value: formatCurrency(finalPayableTaxAmount.value), highlight: true },
  { code: 'EFD00090', label: t('taxReportEditor.lia010.fields.amendedRefundableTaxAmount'), value: displayValue('') },
  { code: 'EFD00100', label: t('taxReportEditor.lia010.fields.amendedPayableTaxAmount'), value: displayValue('') },
  { code: 'EFD00110', label: t('taxReportEditor.lia010.fields.netPayableTaxAmount'), value: formatCurrency(finalPayableTaxAmount.value), highlight: true },
  { code: 'EFE00010', label: t('taxReportEditor.lia010.fields.taxAccountantName'), value: displayValue(tenantProfile.value.DAIRI_NM) },
  { code: 'EFE00020', label: t('taxReportEditor.lia010.fields.taxAccountantTel'), value: formatTelParts(tenantProfile.value.DAIRI_TEL) },
  { code: 'EFG00000', label: t('taxReportEditor.lia010.fields.refundAccount'), value: formatRefundAccount(tenantProfile.value.KANPU_KINYUKIKAN) },
  { code: 'EFI00000', label: t('taxReportEditor.lia010.fields.creatorName'), value: displayValue(tenantName.value) },
])
const lia130EditorFields = computed<EditorField[]>(() => [
  { code: 'EQA00010', label: t('taxReportEditor.lia130.fields.filingPeriod'), value: reportPeriodText.value },
  { code: 'EQB00020', label: t('taxReportEditor.lia130.fields.factoryName'), value: displayValue(tenantProfile.value.SEIZOJO_NM || tenantName.value) },
  { code: 'EQC00010', label: t('taxReportEditor.lia130.fields.priorFiscalYear'), value: formatCurrency(taxReductionPreview.value.priorFiscalYearStandardTaxAmount) },
  { code: 'EQC00050', label: t('taxReportEditor.lia130.fields.currentMonthStandardTax'), value: formatCurrency(taxReductionPreview.value.currentMonthStandardTaxAmount) },
  { code: 'EQC00070', label: t('taxReportEditor.lia130.fields.currentMonthStandardTax'), value: formatCurrency(taxReductionPreview.value.currentMonthStandardTaxAmount) },
  { code: 'EQC00080', label: t('taxReportEditor.lia130.fields.currentMonthReducedTax'), value: formatCurrency(taxReductionPreview.value.currentMonthReducedTaxAmount) },
  { code: 'EQC00100', label: t('taxReportEditor.lia130.fields.currentMonthStandardTax'), value: formatCurrency(taxReductionPreview.value.currentMonthStandardTaxAmount) },
  { code: 'EQC00120', label: t('taxReportEditor.lia130.fields.currentMonthStandardTax'), value: formatCurrency(taxReductionPreview.value.currentMonthStandardTaxAmount) },
  { code: 'EQC00130', label: t('taxReportEditor.lia130.fields.currentMonthReducedTax'), value: formatCurrency(taxReductionPreview.value.currentMonthReducedTaxAmount) },
  { code: 'EQC00290', label: t('taxReportEditor.lia130.fields.cumulativeBeforeReturn'), value: formatCurrency(taxReductionPreview.value.cumulativeBeforeReturnStandardTaxAmount) },
  { code: 'EQC00310', label: t('taxReportEditor.lia130.fields.returnStandardTax'), value: formatCurrency(taxReductionPreview.value.returnStandardTaxAmount) },
  { code: 'EQC00330', label: t('taxReportEditor.lia130.fields.returnStandardTax'), value: formatCurrency(taxReductionPreview.value.returnStandardTaxAmount) },
  { code: 'EQC00340', label: t('taxReportEditor.lia130.fields.returnReducedTax'), value: formatCurrency(taxReductionPreview.value.returnReducedTaxAmount) },
  { code: 'EQC00360', label: t('taxReportEditor.lia130.fields.netStandardTax'), value: formatCurrency(taxReductionPreview.value.netStandardTaxAmount), highlight: true },
  { code: 'EQC00380', label: t('taxReportEditor.lia130.fields.netStandardTax'), value: formatCurrency(taxReductionPreview.value.netStandardTaxAmount), highlight: true },
  { code: 'EQC00390', label: t('taxReportEditor.lia130.fields.netReducedTax'), value: formatCurrency(taxReductionPreview.value.netReducedTaxAmount), highlight: true },
  { code: 'EQC00400', label: t('taxReportEditor.lia130.fields.cumulativeAfterReturn'), value: formatCurrency(taxReductionPreview.value.cumulativeAfterReturnStandardTaxAmount) },
  { code: 'EQD00000', label: t('taxReportEditor.lia130.fields.reductionCategory'), value: displayValue(taxReductionPreview.value.category) },
  { code: 'EQE00040', label: t('taxReportEditor.lia130.fields.finalFactoryTax'), value: formatCurrency(taxReductionPreview.value.netReducedTaxAmount), highlight: true },
])
const exportExemptRows = computed(() =>
  reportBreakdown.value.filter((item) => resolveTaxEvent(item.move_type, item.tax_event) === 'EXPORT_EXEMPT'),
)
const lia110BlankRowCount = computed(() => Math.max(0, 18 - Math.max(1, movementTableRows.value.length)))
const lia220BlankRowCount = computed(() => Math.max(0, 18 - Math.max(1, returnTableRows.value.length)))
const lia260BlankRowCount = computed(() => Math.max(0, 9 - Math.max(1, exportExemptRows.value.length)))
const reportPeriodText = computed(() => formatWarekiMonth(form.tax_year, form.tax_month))
const reportDateText = computed(() => formatWarekiDate(form.tax_year, form.tax_month, 1))
const previewZoomPercent = computed(() => `${Math.round(previewZoom.value * 100)}%`)
const previewScaledPageStyle = computed(() => ({
  width: `${PREVIEW_PAGE_WIDTH_MM * previewZoom.value}mm`,
  minHeight: `${PREVIEW_PAGE_HEIGHT_MM * previewZoom.value}mm`,
}))
const previewPageTransformStyle = computed(() => ({
  transform: `scale(${previewZoom.value})`,
  transformOrigin: 'top left',
  fontFamily: "'Yu Mincho', YuMincho, 'Hiragino Mincho ProN', serif",
}))
const taxableRemovalExportLabels = computed<TaxableRemovalExportLabels>(() => ({
  summaryTitle: t('taxableRemovalReport.summary.title'),
  tableTitle: t('taxableRemovalReport.table.title'),
  generatedAt: t('taxableRemovalReport.export.generatedAt'),
  businessYear: t('taxableRemovalReport.export.businessYear'),
  monthSheetLabel: t('taxableRemovalReport.export.monthSheetLabel'),
  summarySheetName: t('taxableRemovalReport.export.summarySheetName'),
  summaryColumns: {
    liquorCode: t('taxableRemovalReport.summary.columns.liquorCode'),
    abv: t('taxableRemovalReport.summary.columns.abv'),
    quantityMl: t('taxableRemovalReport.summary.columns.quantityMl'),
    packageCount: t('taxableRemovalReport.summary.columns.packageCount'),
    taxRate: t('taxableRemovalReport.summary.columns.taxRate'),
    taxAmount: t('taxableRemovalReport.summary.columns.taxAmount'),
  },
  tableColumns: {
    item: t('taxableRemovalReport.table.columns.item'),
    brand: t('taxableRemovalReport.table.columns.brand'),
    abv: t('taxableRemovalReport.table.columns.abv'),
    movementAt: t('taxableRemovalReport.table.columns.movementAt'),
    container: t('taxableRemovalReport.table.columns.container'),
    quantityMl: t('taxableRemovalReport.table.columns.quantityMl'),
    unitPrice: t('taxableRemovalReport.table.columns.unitPrice'),
    amount: t('taxableRemovalReport.table.columns.amount'),
    removalType: t('taxableRemovalReport.table.columns.removalType'),
    destinationAddress: t('taxableRemovalReport.table.columns.destinationAddress'),
    destinationName: t('taxableRemovalReport.table.columns.destinationName'),
    lotNo: t('taxableRemovalReport.table.columns.lotNo'),
    notes: t('taxableRemovalReport.table.columns.notes'),
  },
}))
const taxLedgerExportLabels = computed<TaxLedgerExportLabels>(() => ({
  generatedAt: t('taxLedgerReport.export.generatedAt'),
  businessYear: t('taxLedgerReport.export.businessYear'),
  columns: Object.fromEntries(
    [...taxLedgerColumnKeys, 'containerType'].map((column) => [
      column,
      t(`taxLedgerReport.table.columns.${column}`),
    ]),
  ) as TaxLedgerExportLabels['columns'],
}))

function statusLabel(status: string) {
  const map = tm('taxReport.statusMap')
  if (!map || typeof map !== 'object') return status
  const label = (map as Record<string, unknown>)[status]
  return typeof label === 'string' ? label : status
}

function taxTypeLabel(taxType: string) {
  const map = tm('taxReport.taxTypeMap')
  if (!map || typeof map !== 'object') return taxType
  const label = (map as Record<string, unknown>)[taxType]
  return typeof label === 'string' ? label : taxType
}

function taxEventLabel(value: string | null | undefined) {
  return ruleLabel('tax_event', value)
}

function breakdownMovementLabel(item: TaxVolumeItem) {
  const actualTaxEvent = resolveTaxEvent(item.move_type, item.tax_event)
  return taxEventLabel(actualTaxEvent)
}

function movementRowLabel(item: TaxVolumeItem) {
  const rowRole = item.row_role ?? 'detail'
  if (rowRole === 'detail') return breakdownMovementLabel(item)
  if (rowRole === 'kubun_summary') return t('taxReportEditor.rowTypes.kubunSummary')
  if (rowRole === 'category_summary') return t('taxReportEditor.rowTypes.categorySummary')
  if (rowRole === 'grand_total') return t('taxReportEditor.rowTypes.grandTotal')
  return breakdownMovementLabel(item)
}

function movementRowRoleLabel(item: TaxVolumeItem) {
  const rowRole = item.row_role ?? 'detail'
  if (rowRole === 'detail') return ''
  return t('taxReportEditor.rowTypes.generated')
}

function movementRowClass(item: TaxVolumeItem) {
  const rowRole = item.row_role ?? 'detail'
  if (rowRole === 'grand_total') return 'bg-blue-50 font-semibold'
  if (rowRole === 'category_summary') return 'bg-gray-100 font-semibold'
  if (rowRole === 'kubun_summary') return 'bg-gray-50 font-medium'
  return 'bg-white'
}

function movementSortIndicator(key: MovementSortKey) {
  if (movementSort.key !== key) return ''
  return movementSort.direction === 'asc' ? '↑' : '↓'
}

function formatInputNumber(value: number | null | undefined) {
  return Number.isFinite(value) ? String(value) : ''
}

function formatNullableNumber(value: number | null | undefined, maximumFractionDigits = 2) {
  if (!Number.isFinite(value)) return '—'
  return new Intl.NumberFormat(locale.value, {
    maximumFractionDigits,
  }).format(Number(value))
}

function formatAbv(value: number | null | undefined) {
  return formatAbvPercent(value, locale.value)
}

function formatPercent(value: number | null | undefined) {
  if (!Number.isFinite(value)) return '—'
  return new Intl.NumberFormat(locale.value, {
    style: 'percent',
    maximumFractionDigits: 1,
  }).format(Number(value))
}

function displayValue(value: string | number | null | undefined) {
  const text = value == null ? '' : String(value).trim()
  return text || '—'
}

function formatZipParts(value: TaxReportProfile['NOZEISHA_ZIP']) {
  if (!value.zip1 && !value.zip2) return '—'
  return [value.zip1, value.zip2].filter(Boolean).join('-')
}

function formatTelParts(value: TaxReportProfile['NOZEISHA_TEL']) {
  const parts = [value.tel1, value.tel2, value.tel3].filter(Boolean)
  return parts.length > 0 ? parts.join('-') : '—'
}

function formatRefundAccount(value: TaxReportProfile['KANPU_KINYUKIKAN']) {
  const parts = [
    value.kinyukikan_NM,
    value.kinyukikan_KB,
    value.shiten_NM,
    value.shiten_KB,
    value.yokin,
    value.koza,
  ].filter(Boolean)
  return parts.length > 0 ? parts.join(' / ') : '—'
}

function compareNullableNumbers(
  left: number | null | undefined,
  right: number | null | undefined,
  direction: MovementSortDirection,
) {
  const a = Number.isFinite(left) ? Number(left) : null
  const b = Number.isFinite(right) ? Number(right) : null
  if (a == null && b == null) return 0
  if (a == null) return 1
  if (b == null) return -1
  return direction === 'asc' ? a - b : b - a
}

function compareStrings(left: string, right: string, direction: MovementSortDirection) {
  const result = left.localeCompare(right, locale.value)
  return direction === 'asc' ? result : -result
}

function sortMovementTableRows(rows: MovementTableRow[]) {
  if (movementSort.key === 'category' && movementSort.direction === 'asc') return rows

  return [...rows].sort((a, b) => compareMovementTableRows(a.item, b.item))
}

function compareMovementTableRows(a: TaxVolumeItem, b: TaxVolumeItem) {
  let result = 0
  if (movementSort.key === 'kubun') {
    result = compareNullableNumbers(lia110KubunCodeForItem(a), lia110KubunCodeForItem(b), movementSort.direction)
  } else if (movementSort.key === 'taxEvent') {
    result = compareStrings(movementRowLabel(a), movementRowLabel(b), movementSort.direction)
  } else if (movementSort.key === 'category') {
    result = compareStrings(a.categoryName, b.categoryName, movementSort.direction)
  } else if (movementSort.key === 'abv') {
    result = compareNullableNumbers(a.abv, b.abv, movementSort.direction)
  } else if (movementSort.key === 'volume') {
    result = compareNullableNumbers(a.volume_l, b.volume_l, movementSort.direction)
  }
  if (result !== 0) return result

  const categoryResult = compareStrings(a.categoryName, b.categoryName, 'asc')
  if (categoryResult !== 0) return categoryResult

  const kubunResult = lia110KubunCodeForItem(a) - lia110KubunCodeForItem(b)
  if (kubunResult !== 0) return kubunResult

  const roleResult = movementRowRoleRank(a) - movementRowRoleRank(b)
  if (roleResult !== 0) return roleResult

  return compareNullableNumbers(a.abv, b.abv, 'desc')
}

function movementRowRoleRank(item: TaxVolumeItem) {
  switch (item.row_role ?? 'detail') {
    case 'detail':
      return 0
    case 'kubun_summary':
      return 1
    case 'category_summary':
      return 2
    case 'grand_total':
      return 3
    default:
      return 9
  }
}

function sortMovementBreakdown(
  items: TaxVolumeItem[],
  key = movementSort.key,
  direction = movementSort.direction,
) {
  items.sort((a, b) => {
    if (key === 'kubun') {
      const result = compareNullableNumbers(lia110KubunCodeForItem(a), lia110KubunCodeForItem(b), direction)
      if (result !== 0) return result
    } else if (key === 'taxEvent') {
      const result = compareStrings(breakdownMovementLabel(a), breakdownMovementLabel(b), direction)
      if (result !== 0) return result
    } else if (key === 'category') {
      const result = compareStrings(a.categoryName, b.categoryName, direction)
      if (result !== 0) return result
    } else if (key === 'abv') {
      const result = compareNullableNumbers(a.abv, b.abv, direction)
      if (result !== 0) return result
    } else if (key === 'volume') {
      const result = compareNullableNumbers(a.volume_l, b.volume_l, direction)
      if (result !== 0) return result
    }

    const categoryResult = compareStrings(a.categoryName, b.categoryName, 'asc')
    if (categoryResult !== 0) return categoryResult
    return compareNullableNumbers(a.abv, b.abv, 'asc')
  })
}

function sortMovementTable(key: MovementSortKey) {
  if (movementSort.key === key) {
    movementSort.direction = movementSort.direction === 'asc' ? 'desc' : 'asc'
  } else {
    movementSort.key = key
    movementSort.direction = 'asc'
  }
  sortMovementBreakdown(reportBreakdown.value)
}

function clampPreviewZoom(value: number) {
  if (!Number.isFinite(value)) return 1
  return Math.min(PREVIEW_MAX_ZOOM, Math.max(PREVIEW_MIN_ZOOM, Number(value.toFixed(2))))
}

function setPreviewZoom(value: number) {
  previewZoom.value = clampPreviewZoom(value)
}

function zoomPreviewBy(delta: number) {
  setPreviewZoom(previewZoom.value + delta)
}

function resetPreviewZoom() {
  setPreviewZoom(1)
}

function fitPreviewToWidth() {
  const viewport = previewViewport.value
  if (!viewport) {
    setPreviewZoom(1)
    return
  }
  const pageWidthPx = PREVIEW_PAGE_WIDTH_MM * CSS_PIXELS_PER_MM
  const availableWidth = Math.max(320, viewport.clientWidth - 48)
  setPreviewZoom(availableWidth / pageWidthPx)
  viewport.scrollLeft = 0
}

async function fitPreviewToWidthWhenVisible() {
  if (editorMode.value !== 'preview') return
  await nextTick()
  fitPreviewToWidth()
}

function startPreviewPan(event: PointerEvent) {
  if (event.button !== 0 || !previewViewport.value) return
  previewDragging.value = true
  previewDragState.pointerId = event.pointerId
  previewDragState.startX = event.clientX
  previewDragState.startY = event.clientY
  previewDragState.scrollLeft = previewViewport.value.scrollLeft
  previewDragState.scrollTop = previewViewport.value.scrollTop
  previewViewport.value.setPointerCapture?.(event.pointerId)
}

function movePreviewPan(event: PointerEvent) {
  if (!previewDragging.value || !previewViewport.value) return
  event.preventDefault()
  const dx = event.clientX - previewDragState.startX
  const dy = event.clientY - previewDragState.startY
  previewViewport.value.scrollLeft = previewDragState.scrollLeft - dx
  previewViewport.value.scrollTop = previewDragState.scrollTop - dy
}

function endPreviewPan(event?: PointerEvent) {
  if (event && previewViewport.value && previewDragState.pointerId != null) {
    previewViewport.value.releasePointerCapture?.(previewDragState.pointerId)
  }
  previewDragging.value = false
  previewDragState.pointerId = null
}

function formatCurrency(value: number | null | undefined) {
  return formatYen(value, locale.value)
}

function formatInteger(value: number | null | undefined) {
  if (!Number.isFinite(value)) return ''
  return new Intl.NumberFormat(locale.value, {
    maximumFractionDigits: 0,
  }).format(truncateYen(Number(value)))
}

function formatMilliliters(value: number | null | undefined) {
  return formatMillilitersValue(litersToMilliliters(value), locale.value, '')
}

function previewTaxAmount(item: TaxVolumeItem) {
  if (Number.isFinite(item.tax_amount)) return nonNegativeYen(Number(item.tax_amount))
  const taxableVolume = item.taxable_volume_l ?? (resolveTaxEvent(item.move_type, item.tax_event) === 'TAXABLE_REMOVAL' ? item.volume_l : 0)
  return taxAmountFromLiters(taxableVolume, item.tax_rate || 0)
}

function previewReturnTaxAmount(item: TaxVolumeItem) {
  return taxAmountFromLiters(item.volume_l || 0, item.tax_rate || 0)
}

function formatWarekiMonth(year: number, month: number) {
  const { eraName, yy } = toWarekiYearParts(year)
  return `${eraName} ${yy} 年 ${month} 月分`
}

function formatWarekiDate(year: number, month: number, day: number) {
  const { eraName, yy } = toWarekiYearParts(year)
  return `${eraName} ${yy} 年 ${month} 月 ${day} 日`
}

function businessYearForReportPeriod(year: number, month: number) {
  return businessYearForDate(`${year}-${String(month).padStart(2, '0')}-01`) ?? year
}

function toWarekiYearParts(year: number) {
  if (year >= 2019) return { eraName: '令和', yy: year - 2018 }
  if (year >= 1989) return { eraName: '平成', yy: year - 1988 }
  return { eraName: '昭和', yy: year - 1925 }
}

function recalcTotalTax() {
  totalTaxAmount.value = calculateTaxTotalAmount(reportBreakdown.value)
}

function handleBreakdownChange(index: number) {
  const item = reportBreakdown.value[index]
  if (!item) return
  if (!Number.isFinite(item.volume_l)) item.volume_l = 0
  item.volume_ml = litersToMilliliters(item.volume_l)
  if (!Number.isFinite(item.abv)) item.abv = null
  recalcTotalTax()
}

function updateReportBreakdownNumber(
  index: number,
  field: 'abv' | 'volume_l',
  event: Event,
) {
  const item = reportBreakdown.value[index]
  const target = event.target as HTMLInputElement | null
  if (!item || !target) return
  const value = target.value === '' ? null : Number(target.value)
  if (field === 'abv') {
    item.abv = Number.isFinite(value) ? Number(value) : null
  } else {
    item.volume_l = Number.isFinite(value) ? Number(value) : 0
  }
  handleBreakdownChange(index)
}

function handleDisposeChange(index: number) {
  const item = disposeBreakdown.value[index]
  if (!item) return
  if (!Number.isFinite(item.volume_l)) item.volume_l = 0
  item.volume_ml = litersToMilliliters(item.volume_l)
  if (!Number.isFinite(item.abv)) item.abv = null
  recalcTotalTax()
}

function setXmlLink(kind: 'summary' | 'dispose', name: string, xml: string) {
  const url = URL.createObjectURL(new Blob([xml], { type: 'application/xml' }))
  if (kind === 'summary') {
    if (summaryXmlUrl.value) URL.revokeObjectURL(summaryXmlUrl.value)
    summaryXmlUrl.value = url
    summaryXmlName.value = name
  } else {
    if (disposeXmlUrl.value) URL.revokeObjectURL(disposeXmlUrl.value)
    disposeXmlUrl.value = url
    disposeXmlName.value = name
  }
}

function downloadBlob(filename: string, blob: Blob) {
  const url = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  anchor.href = url
  anchor.download = filename
  document.body.appendChild(anchor)
  anchor.click()
  anchor.remove()
  URL.revokeObjectURL(url)
}

function downloadTextFile(filename: string, content: string, mime = 'application/xml') {
  downloadBlob(filename, new Blob([content], { type: mime }))
}

async function downloadSavedReportFile(entry: {
  stored: TaxReportStoredFile | null
  fileName: string
}) {
  if (!entry.stored) return
  if (!entry.stored.storageBucket || !entry.stored.storagePath) {
    try {
      const fileType = inferStoredFileType(entry.fileName)
      if (fileType === 'tax_report_xml') {
        const summaryFile = await buildSummaryXmlFile()
        if (summaryFile) {
          const xml = await summaryFile.blob.text()
          downloadTextFile(summaryFile.fileName, xml)
        }
        return
      }
      if (fileType === 'tax_report_dispose_xml') {
        const disposeFile = await buildDisposeXmlFile()
        if (disposeFile) {
          const xml = await disposeFile.blob.text()
          downloadTextFile(disposeFile.fileName, xml)
        }
        return
      }
      toast.info(t('taxReport.fileUnavailable'))
    } catch (err) {
      console.error(err)
      toast.error(err instanceof Error ? err.message : String(err))
    }
    return
  }
  try {
    const blob = await downloadStoredTaxReportFile({
      supabase,
      file: entry.stored,
    })
    downloadBlob(entry.fileName, blob)
  } catch (err) {
    console.error(err)
    toast.error(err instanceof Error ? err.message : String(err))
  }
}

async function ensureTenant() {
  if (tenantId.value) return tenantId.value
  const { data, error } = await supabase.auth.getUser()
  if (error) throw error
  const id = data.user?.app_metadata?.tenant_id as string | undefined
  if (!id) throw new Error('Tenant not resolved in session')
  tenantId.value = id
  return id
}

async function loadTenantTaxReportProfile() {
  const tenant = await ensureTenant()
  const loaded = await fetchTaxReportProfileForTenant(supabase, tenant)
  tenantName.value = loaded.tenantName
  tenantProfile.value = loaded.profile
}

function applySavedReport(row: JsonMap) {
  const normalized = normalizeReport(row)
  form.id = normalized.id
  form.tax_type = normalized.tax_type || 'monthly'
  form.tax_year = normalized.tax_year
  form.tax_month = normalized.tax_month
  form.status = normalized.status
  savedReportStatus.value = STATUS_OPTIONS.includes(normalized.status as TaxReportStatus)
    ? (normalized.status as TaxReportStatus)
    : 'draft'
  form.attachment_files = normalized.attachment_files.join('\n')
  storedReportFiles.value = normalized.report_files
  reportBreakdown.value = sortTaxVolumeItems(summaryItemsFromBreakdown(normalized.volume_breakdown)).map((item) => ({ ...item }))
  disposeBreakdown.value = sortTaxVolumeItems(disposeItemsFromBreakdown(normalized.volume_breakdown)).map((item) => ({ ...item }))
  sortMovementBreakdown(reportBreakdown.value)
  totalTaxAmount.value = normalized.total_tax_amount
  return normalized
}

function reportRowFromGenerateResponse(data: unknown) {
  const response = data && typeof data === 'object' ? (data as JsonMap) : {}
  const report = response.report
  if (!report || typeof report !== 'object') {
    throw new Error('tax_report_generate did not return a report row')
  }
  return report as JsonMap
}

async function generateReportForPeriod(
  taxType: string,
  year: number,
  month: number,
  options: {
    status?: 'draft' | 'stale'
    reportFiles?: TaxReportStoredFile[]
    attachmentFiles?: string[]
    silent?: boolean
  } = {},
) {
  try {
    generating.value = true
    reportBreakdown.value = []
    disposeBreakdown.value = []
    totalTaxAmount.value = 0

    await ensureTenant()
    const { data, error } = await supabase.rpc('tax_report_generate', {
      p_doc: {
        report_id: form.id || null,
        tax_type: taxType,
        tax_year: year,
        tax_month: month,
        status: options.status ?? 'draft',
        report_files: options.reportFiles ?? storedReportFiles.value,
        attachment_files: options.attachmentFiles ?? parseFileList(form.attachment_files),
      },
    })

    if (error) throw error
    applySavedReport(reportRowFromGenerateResponse(data))
  } catch (err) {
    console.error(err)
    if (!options.silent) toast.error(formatRpcErrorMessage(err))
    throw err
  } finally {
    generating.value = false
  }
}

async function ensureFreshReportForXml() {
  if (form.status !== 'stale') return
  await generateReportForPeriod(form.tax_type, form.tax_year, form.tax_month, {
    status: 'draft',
    silent: true,
  })
}

function isTaxReportStatus(value: string): value is TaxReportStatus {
  return STATUS_OPTIONS.includes(value as TaxReportStatus)
}

async function setReportStatus(status: TaxReportStatus) {
  if (!form.id) throw new Error('Tax report has not been generated')
  const { error } = await supabase.rpc('tax_report_set_status', {
    p_tax_report_id: form.id,
    p_status: status,
    p_reason: null,
  })
  if (error) throw error
  form.status = status
  savedReportStatus.value = status
}

async function applyRequestedFinalStatus(requestedStatus: string) {
  if (requestedStatus === 'stale') {
    await setReportStatus('stale')
    return
  }

  if (requestedStatus === 'submitted') {
    await setReportStatus('submitted')
    return
  }

  if (requestedStatus === 'approved') {
    if (form.status !== 'submitted') await setReportStatus('submitted')
    await setReportStatus('approved')
  }
}

function validateForm() {
  Object.keys(errors).forEach((key) => delete errors[key])
  if (!form.tax_type) errors.tax_type = t('taxReport.errors.taxTypeRequired')
  if (!form.tax_year) errors.tax_year = t('taxReport.errors.taxYearRequired')
  if (form.tax_type === 'monthly' && !form.tax_month) errors.tax_month = t('taxReport.errors.taxMonthRequired')
  if (!form.status) errors.status = t('taxReport.errors.statusRequired')
  if (reportBreakdown.value.length === 0) errors.breakdown = t('taxReport.emptyBreakdown')
  return Object.keys(errors).length === 0
}

function showValidationErrorToast() {
  const firstError = Object.values(errors).find((message) => message)
  if (firstError) toast.error(firstError)
}

async function buildSummaryXmlFile() {
  const summaryBreakdown = summaryItemsFromBreakdown(reportBreakdown.value)
  if (summaryBreakdown.length === 0) return null
  const tenant = await ensureTenant()
  const priorStandardTaxAmount = await fetchPriorFiscalYearStandardTaxAmount({
    supabase,
    tenantId: tenant,
    taxYear: form.tax_year,
    taxMonth: form.tax_month,
    excludeReportId: form.id || null,
  })
  priorFiscalYearStandardTaxAmount.value = priorStandardTaxAmount
  const fileName = buildXmlFilename(form.tax_type, form.tax_year, form.tax_month)
  const content = await buildXmlPayload({
    taxType: form.tax_type,
    taxYear: form.tax_year,
    taxMonth: form.tax_month,
    breakdown: summaryBreakdown,
    profile: tenantProfile.value,
    tenantId: tenant,
    tenantName: tenantName.value,
    priorFiscalYearStandardTaxAmount: priorStandardTaxAmount,
    includeLia130: true,
  })
  return {
    blob: new Blob([content], { type: 'application/xml' }),
    fileName,
    fileType: 'tax_report_xml' as const,
    generatedAt: new Date().toISOString(),
    mimeType: 'application/xml',
  }
}

async function buildDisposeXmlFile() {
  if (disposeBreakdown.value.length === 0) return null
  const fileName = buildDisposeXmlFilename(form.tax_type, form.tax_year, form.tax_month)
  const content = await buildXmlPayload({
    taxType: form.tax_type,
    taxYear: form.tax_year,
    taxMonth: form.tax_month,
    breakdown: disposeBreakdown.value,
    profile: tenantProfile.value,
    tenantId: tenantId.value ?? '',
    tenantName: tenantName.value,
    includeLia130: false,
  })
  return {
    blob: new Blob([content], { type: 'application/xml' }),
    fileName,
    fileType: 'tax_report_dispose_xml' as const,
    generatedAt: new Date().toISOString(),
    mimeType: 'application/xml',
  }
}

async function buildSupportingLedgerWorkbookFiles() {
  if (form.tax_type !== 'monthly' || !form.tax_year || !form.tax_month) return null

  const tenant = await ensureTenant()
  const businessYear = reportBusinessYear.value
  const createdAt = new Date()
  const detailRows = await loadTaxableRemovalDetailRows({
    supabase,
    tenantId: tenant,
    locale: locale.value,
    removalTypeLabel: t('taxableRemovalReport.defaults.taxableRemovalType'),
  })
  const taxableRemovalBlob = createTaxableRemovalBusinessYearWorkbookBlob({
    detailRows,
    businessYear,
    labels: taxableRemovalExportLabels.value,
    locale: locale.value,
    createdAt,
    creator: 'beeradmin_tail',
  })

  const files: GeneratedTaxReportFile[] = [{
    blob: taxableRemovalBlob,
    fileName: buildTaxableRemovalBusinessYearFileName(businessYear),
    fileType: 'taxable_removal_excel' as const,
    generatedAt: createdAt.toISOString(),
    mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  }]

  for (const key of taxLedgerKeys) {
    const config = getTaxLedgerConfig(key)
    const ledgerRows = await loadTaxLedgerDetailRows({
      supabase,
      tenantId: tenant,
      locale: locale.value,
      config,
    })
    files.push({
      blob: createTaxLedgerBusinessYearWorkbookBlob({
        detailRows: ledgerRows,
        businessYear,
        config,
        labels: taxLedgerExportLabels.value,
        locale: locale.value,
        createdAt,
        creator: 'beeradmin_tail',
      }),
      fileName: buildTaxLedgerBusinessYearFileName(config, businessYear),
      fileType: taxLedgerFileTypes[key],
      generatedAt: createdAt.toISOString(),
      mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    })
  }

  return files
}

async function saveReport() {
  let uploadedFiles: TaxReportStoredFile[] = []
  let filesPersisted = false
  try {
    saving.value = true
    const requestedStatus = form.status
    if (!isTaxReportStatus(requestedStatus)) {
      errors.status = t('taxReport.errors.statusRequired')
      return
    }

    if (savedReportStatus.value === 'submitted' || savedReportStatus.value === 'approved') {
      if (requestedStatus !== savedReportStatus.value) await setReportStatus(requestedStatus)
      await router.push({ name: 'TaxReport' })
      return
    }

    if (form.tax_type === 'yearly') form.tax_month = 12
    await generateReportForPeriod(form.tax_type, form.tax_year, form.tax_month, {
      status: 'draft',
      silent: true,
    })

    if (!validateForm()) {
      showValidationErrorToast()
      return
    }

    const tenant = await ensureTenant()
    const reportId = form.id
    if (!reportId) throw new Error('Tax report has not been generated')
    const generatedFiles: GeneratedTaxReportFile[] = []

    const summaryFile = await buildSummaryXmlFile()
    if (summaryFile) generatedFiles.push(summaryFile)

    const disposeFile = await buildDisposeXmlFile()
    if (disposeFile) generatedFiles.push(disposeFile)

    const supportingLedgerFiles = await buildSupportingLedgerWorkbookFiles()
    if (supportingLedgerFiles) generatedFiles.push(...supportingLedgerFiles)

    const activeFileTypes = new Set(generatedFiles.map((file) => file.fileType))
    const obsoleteStoredFiles = storedReportFiles.value.filter(
      (file) => !activeFileTypes.has(file.fileType as GeneratedTaxReportFile['fileType']),
    )
    const retainedStoredFiles = storedReportFiles.value.filter(
      (file) => activeFileTypes.has(file.fileType as GeneratedTaxReportFile['fileType']),
    )

    uploadedFiles = await uploadGeneratedTaxReportFiles({
      supabase,
      files: generatedFiles,
      reportId,
      tenantId: tenant,
    })

    const replacedStoredFiles = retainedStoredFiles.filter((existing) =>
      uploadedFiles.some((uploaded) =>
        uploaded.fileType === existing.fileType &&
        uploaded.storageBucket === existing.storageBucket &&
        uploaded.storagePath !== existing.storagePath,
      ),
    )
    const reportFiles = mergeStoredFiles(retainedStoredFiles, uploadedFiles)
    await generateReportForPeriod(form.tax_type, form.tax_year, form.tax_month, {
      status: 'draft',
      reportFiles,
      attachmentFiles: parseFileList(form.attachment_files),
      silent: true,
    })
    filesPersisted = true
    await applyRequestedFinalStatus(requestedStatus)
    storedReportFiles.value = reportFiles
    const cleanupFiles = [...obsoleteStoredFiles, ...replacedStoredFiles]
    if (cleanupFiles.length > 0) {
      try {
        await removeStoredTaxReportFiles({
          supabase,
          files: cleanupFiles,
        })
      } catch (cleanupErr) {
        console.warn('Failed to remove obsolete tax report files from storage', cleanupErr)
      }
    }
    await router.push({ name: 'TaxReport' })
  } catch (err) {
    if (uploadedFiles.length > 0 && !filesPersisted) {
      await removeStoredTaxReportFiles({
        supabase,
        files: uploadedFiles,
      })
    }
    console.error(err)
    toast.error(formatRpcErrorMessage(err))
  } finally {
    saving.value = false
  }
}

async function createXmlForSummary() {
  try {
    await ensureFreshReportForXml()
    const summaryFile = await buildSummaryXmlFile()
    if (!summaryFile) {
      toast.info(t('taxReport.emptyBreakdown'))
      return
    }
    const xml = await summaryFile.blob.text()
    downloadTextFile(summaryFile.fileName, xml)
    setXmlLink('summary', summaryFile.fileName, xml)
  } catch (err) {
    toast.error(formatRpcErrorMessage(err))
    console.error(err)
  }
}

async function createXmlForDispose() {
  try {
    await ensureFreshReportForXml()
    const disposeFile = await buildDisposeXmlFile()
    if (!disposeFile) {
      toast.info(t('taxReport.emptyBreakdown'))
      return
    }
    const xml = await disposeFile.blob.text()
    downloadTextFile(disposeFile.fileName, xml)
    setXmlLink('dispose', disposeFile.fileName, xml)
  } catch (err) {
    toast.error(formatRpcErrorMessage(err))
    console.error(err)
  }
}

function handleAttachmentUpload(event: Event) {
  const input = event.target as HTMLInputElement
  const files = Array.from(input.files ?? [])
  if (!files.length) return
  const current = new Set(parseFileList(form.attachment_files))
  files.forEach((file) => current.add(file.name))
  form.attachment_files = Array.from(current).join('\n')
  input.value = ''
}

function removeAttachment(file: string) {
  form.attachment_files = parseFileList(form.attachment_files)
    .filter((name) => name !== file)
    .join('\n')
}

async function loadExistingReport(id: string) {
  const tenant = await ensureTenant()
  const { data, error } = await supabase
    .from(TABLE)
    .select('id, tax_type, tax_year, tax_month, status, total_tax_amount, volume_breakdown, report_files, attachment_files, created_at')
    .eq('tenant_id', tenant)
    .eq('id', id)
    .maybeSingle()
  if (error) throw error
  if (!data) throw new Error('Tax report not found')

  applySavedReport(data as JsonMap)
}

async function refreshReductionPreview() {
  if (form.tax_type !== 'monthly' || !form.tax_year || !form.tax_month) {
    priorFiscalYearStandardTaxAmount.value = 0
    reductionPreviewError.value = ''
    return
  }
  try {
    reductionPreviewLoading.value = true
    reductionPreviewError.value = ''
    const tenant = await ensureTenant()
    priorFiscalYearStandardTaxAmount.value = await fetchPriorFiscalYearStandardTaxAmount({
      supabase,
      tenantId: tenant,
      taxYear: form.tax_year,
      taxMonth: form.tax_month,
      excludeReportId: form.id || null,
    })
  } catch (err) {
    console.error(err)
    reductionPreviewError.value = err instanceof Error ? err.message : String(err)
  } finally {
    reductionPreviewLoading.value = false
  }
}

function queryNumber(value: unknown, fallback: number) {
  const numeric = Number(value)
  return Number.isFinite(numeric) ? numeric : fallback
}

watch(editorMode, (mode) => {
  if (mode === 'preview') void fitPreviewToWidthWhenVisible()
})

watch(activeFormTab, () => {
  void fitPreviewToWidthWhenVisible()
})

async function initializeNewReport() {
  form.tax_type = typeof route.query.taxType === 'string' ? route.query.taxType : 'monthly'
  form.tax_year = queryNumber(route.query.taxYear, new Date().getFullYear())
  form.tax_month = form.tax_type === 'monthly' ? queryNumber(route.query.taxMonth, new Date().getMonth() + 1) : 12
  form.status = 'draft'
  await generateReportForPeriod(form.tax_type, form.tax_year, form.tax_month, { silent: true })
}

async function goBack() {
  await router.push({ name: 'TaxReport' })
}

onMounted(async () => {
  try {
    loadingInitial.value = true
    await ensureTenant()
    await Promise.all([
      loadRuleengineLabels({ tenantId: tenantId.value }),
      loadTenantTaxReportProfile(),
    ])
    if (editing.value && typeof route.params.id === 'string') {
      await loadExistingReport(route.params.id)
    } else {
      await initializeNewReport()
    }
    await refreshReductionPreview()
    await fitPreviewToWidthWhenVisible()
  } catch (err) {
    console.error(err)
    toast.error(formatRpcErrorMessage(err))
    if (!editing.value && parseRpcError(err).businessCode === 'TRG005') {
      await router.push({ name: 'TaxReport' })
    }
  } finally {
    loadingInitial.value = false
  }
})

onUnmounted(() => {
  if (summaryXmlUrl.value) URL.revokeObjectURL(summaryXmlUrl.value)
  if (disposeXmlUrl.value) URL.revokeObjectURL(disposeXmlUrl.value)
})
</script>
