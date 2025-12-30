<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="currentPageTitle" />
    <div class="max-w-6xl space-y-6">
      <section class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="flex flex-wrap items-start justify-between gap-4">
          <div>
            <h1 class="text-lg font-semibold text-slate-900">
              {{ currentPageTitle }}
            </h1>
            <p class="mt-1 text-sm text-slate-500">
              {{ $t('forecast.subtitle') }}
            </p>
          </div>
          <button
            type="button"
            class="inline-flex items-center gap-2 rounded-full bg-blue-600 px-5 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 disabled:cursor-not-allowed disabled:bg-slate-300"
            :disabled="isLoading"
            @click="fetchForecast"
          >
            <svg
              v-if="isLoading"
              class="h-4 w-4 animate-spin"
              viewBox="0 0 24 24"
              fill="none"
              aria-hidden="true"
            >
              <circle
                class="opacity-20"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                stroke-width="4"
              />
              <path
                class="opacity-90"
                d="M22 12a10 10 0 0 0-10-10"
                stroke="currentColor"
                stroke-width="4"
                stroke-linecap="round"
              />
            </svg>
            <span>
              {{
                isLoading
                  ? $t('forecast.button.loading')
                  : $t('forecast.button.label')
              }}
            </span>
          </button>
        </div>
        <p class="mt-3 text-sm text-slate-500">
          {{ $t('forecast.hint') }}
        </p>
        <p v-if="lastUpdatedLabel" class="mt-2 text-xs text-slate-400">
          {{ lastUpdatedLabel }}
        </p>
        <p
          v-if="errorMessage"
          class="mt-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700"
        >
          {{ errorMessage }}
        </p>

        <div class="mt-6 rounded-2xl border border-dashed border-slate-200 bg-slate-50 p-4">
          <div class="relative rounded-xl border border-white bg-white px-4 py-6 shadow-sm">
            <template v-if="forecastPoints.length">
              <VueApexCharts
                type="line"
                height="360"
                :options="chartOptions"
                :series="chartSeries"
              />
            </template>
            <p
              v-else
              class="flex h-80 items-center justify-center text-sm text-slate-500"
            >
              {{ $t('forecast.chart.empty') }}
            </p>
            <div
              v-if="isLoading"
              class="pointer-events-none absolute inset-0 flex flex-col items-center justify-center gap-4 text-sm text-slate-500"
              aria-live="polite"
            >
              <div class="flex w-1/2 max-w-[180px] items-center justify-center">
                <svg
                  class="w-full h-auto animate-spin text-blue-500"
                  viewBox="0 0 24 24"
                  fill="none"
                  aria-hidden="true"
                >
                  <circle
                    class="opacity-30"
                    cx="12"
                    cy="12"
                    r="10"
                    stroke="currentColor"
                    stroke-width="4"
                  />
                  <path
                    class="opacity-90"
                    d="M22 12a10 10 0 0 0-10-10"
                    stroke="currentColor"
                    stroke-width="4"
                    stroke-linecap="round"
                  />
                </svg>
              </div>
              <div class="text-center">
                <p class="font-semibold text-slate-700">
                  {{ progressLabel || $t('forecast.loadingTitle') }}
                </p>
                <p class="mt-1 text-xs text-slate-500">
                  <template v-if="progressPercent">
                    {{ progressPercent }}% • {{ progressLabel || $t('forecast.loadingMessage') }}
                  </template>
                  <template v-else>
                    {{ $t('forecast.loadingMessage') }}
                  </template>
                </p>
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  </AdminLayout>
  <Teleport to="body">
    <transition name="fade">
      <div
        v-if="showProgressDialog"
        class="fixed inset-0 z-[9999] flex items-center justify-center bg-slate-900/70 px-4 py-6 backdrop-blur-sm"
      >
        <div class="w-full max-w-lg rounded-2xl bg-white p-6 shadow-2xl ring-1 ring-slate-100">
          <div class="flex items-center gap-3">
            <div class="flex h-12 w-12 items-center justify-center rounded-full bg-blue-50 text-blue-500">
              <svg class="h-6 w-6 animate-spin" viewBox="0 0 24 24" fill="none">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                <path
                  class="opacity-75"
                  d="M22 12a10 10 0 0 0-10-10"
                  stroke="currentColor"
                  stroke-width="4"
                  stroke-linecap="round"
                />
              </svg>
            </div>
            <div>
              <p class="text-lg font-semibold text-slate-900">
                {{ $t('forecast.process.title') }}
              </p>
              <p class="text-sm text-slate-500">
                {{ $t('forecast.process.subtitle') }}
              </p>
            </div>
          </div>
          <p class="mt-4 text-xs font-medium uppercase tracking-wide text-slate-400">
            {{ $t('forecast.process.eta') }}
          </p>
          <ol class="mt-4 space-y-3">
            <li
              v-for="step in progressSteps"
              :key="step.key"
              class="flex items-center gap-3 rounded-xl border border-slate-100 bg-slate-50 px-3 py-2"
              :class="{
                'border-blue-200 bg-blue-50 text-blue-700': step.state === 'current',
                'border-emerald-100 bg-emerald-50 text-emerald-700': step.state === 'done',
                'text-slate-500': step.state === 'upcoming',
              }"
            >
              <span
                class="inline-flex h-8 w-8 items-center justify-center rounded-full text-sm font-semibold"
                :class="{
                  'bg-blue-500 text-white': step.state === 'current',
                  'bg-emerald-500 text-white': step.state === 'done',
                  'bg-white text-slate-400': step.state === 'upcoming',
                }"
              >
                <template v-if="step.state === 'done'">✓</template>
                <template v-else>{{ step.index + 1 }}</template>
              </span>
              <div>
                <p class="text-sm font-semibold">
                  {{ step.label }}
                </p>
                <p class="text-xs text-slate-500" v-if="step.description">
                  {{ step.description }}
                </p>
              </div>
            </li>
          </ol>
        </div>
      </div>
    </transition>
  </Teleport>
</template>

<script setup lang="ts">
import { Teleport, computed, onBeforeUnmount, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import VueApexCharts from 'vue3-apexcharts'

import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'

type ForecastPoint = {
  month: string
  value: number
}

const { t } = useI18n()
const currentPageTitle = computed(() => t('forecast.title'))

const forecastPoints = ref<ForecastPoint[]>(createSeedForecast())
const isLoading = ref(false)
const errorMessage = ref('')
const lastUpdatedAt = ref<number | null>(null)
const showProgressDialog = ref(false)
const progressStage = ref(0)
const progressIntervalId = ref<ReturnType<typeof setInterval> | null>(null)
const progressHideTimeoutId = ref<ReturnType<typeof setTimeout> | null>(null)
const progressStepKeys = ['queue', 'generation', 'chart'] as const
const PROGRESS_TICK_MS = 4500
const progressPercent = ref(0)
const progressLabel = ref('')

const chartSeries = computed(() => [
  {
    name: t('forecast.chart.seriesName'),
    data: forecastPoints.value.map((point) => point.value),
  },
])

const chartOptions = computed(() => ({
  chart: {
    type: 'line',
    toolbar: { show: false },
    fontFamily: 'Outfit, Inter, sans-serif',
    animations: { easing: 'easeinout', speed: 400 },
  },
  stroke: {
    curve: 'smooth',
    width: 3,
  },
  colors: ['#0ea5e9'],
  grid: {
    borderColor: '#e2e8f0',
    strokeDashArray: 4,
  },
  xaxis: {
    categories: forecastPoints.value.map((point) => point.month),
    labels: { rotate: -25, trim: true },
    axisBorder: { show: false },
    axisTicks: { show: false },
  },
  yaxis: {
    labels: {
      formatter: (value: number) => Number(value).toLocaleString(),
    },
    title: {
      text: t('forecast.chart.axisLabel'),
    },
  },
  markers: {
    size: 4,
    colors: ['#fff'],
    strokeColors: '#0ea5e9',
    strokeWidth: 2,
  },
  tooltip: {
    y: {
      formatter: (value: number) =>
        `${Number(value).toLocaleString()} ${t('forecast.chart.unit')}`,
    },
  },
  fill: {
    gradient: {
      enabled: true,
      opacityFrom: 0.45,
      opacityTo: 0.05,
    },
  },
}))

const progressSteps = computed(() =>
  progressStepKeys.map((key, index) => {
    const label = t(`forecast.process.steps.${key}.title`)
    const description = t(`forecast.process.steps.${key}.description`)
    let state: 'done' | 'current' | 'upcoming' = 'upcoming'
    if (progressStage.value > index) {
      state = 'done'
    } else if (progressStage.value === index) {
      state = 'current'
    }
    return {
      key,
      label,
      description: description === `forecast.process.steps.${key}.description` ? '' : description,
      state,
      index,
    }
  })
)

const lastUpdatedLabel = computed(() => {
  if (!lastUpdatedAt.value) return ''
  const formatter = new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  })
  return t('forecast.lastUpdated', {
    time: formatter.format(new Date(lastUpdatedAt.value)),
  })
})

const forecastApiUrl =
  import.meta.env.VITE_FORECAST_API_URL ?? '/api/forecast/beer-sales'

async function fetchForecast() {
  errorMessage.value = ''
  isLoading.value = true
  stopProgressInterval()
  showProgressDialog.value = false
  progressLabel.value = 'AI forecast in progress...'
  progressPercent.value = 50
  await new Promise((resolve) => setTimeout(resolve, 10000))
  isLoading.value = false
  progressLabel.value = ''
  progressPercent.value = 0
}

function extractForecastPoints(payload: unknown): ForecastPoint[] {
  const candidates = pickForecastArray(payload)
  if (!candidates.length) return []

  return candidates
    .map((entry, index) => normalizePoint(entry, index))
    .filter((point): point is ForecastPoint => Boolean(point))
}

function pickForecastArray(payload: unknown): unknown[] {
  if (Array.isArray(payload)) {
    return payload
  }

  if (payload && typeof payload === 'object') {
    const container = payload as Record<string, unknown>
    for (const key of ['forecast', 'data', 'points', 'result']) {
      const value = container[key]
      if (Array.isArray(value)) {
        return value
      }
    }
  }
  return []
}

function normalizePoint(entry: unknown, index: number): ForecastPoint | null {
  if (typeof entry === 'number') {
    return {
      month: fallbackLabel(index),
      value: entry,
    }
  }

  if (entry && typeof entry === 'object') {
    const record = entry as Record<string, unknown>
    const rawLabel =
      record.month ?? record.date ?? record.label ?? record.period ?? record.x
    const rawValue =
      record.value ?? record.sales ?? record.amount ?? record.y ?? record.forecast

    const label =
      typeof rawLabel === 'string' && rawLabel.trim().length
        ? rawLabel
        : fallbackLabel(index)
    const value = Number(rawValue)

    if (!Number.isFinite(value)) {
      return null
    }

    return { month: label, value }
  }

  return null
}

function fallbackLabel(index: number) {
  return t('forecast.chart.defaultLabel', { index: index + 1 })
}

function createSeedForecast(): ForecastPoint[] {
  const now = new Date()
  return Array.from({ length: 12 }, (_, offset) => {
    const pointDate = new Date(now.getFullYear(), now.getMonth() + offset, 1)
    const formatted = new Intl.DateTimeFormat(undefined, {
      month: 'short',
      year: 'numeric',
    }).format(pointDate)

    const base = 480 + offset * 25
    const seasonal = Math.sin(offset / 2) * 60
    return {
      month: formatted,
      value: Math.round(base + seasonal),
    }
  })
}

function openProgressDialog() {
  progressStage.value = 0
  showProgressDialog.value = true
  startProgressInterval()
}

function startProgressInterval() {
  stopProgressInterval()
  progressIntervalId.value = window.setInterval(() => {
    progressStage.value = Math.min(progressStage.value + 1, progressStepKeys.length - 1)
  }, PROGRESS_TICK_MS)
}

function stopProgressInterval() {
  if (progressIntervalId.value) {
    clearInterval(progressIntervalId.value)
    progressIntervalId.value = null
  }
}

function scheduleHideDialog(delay = 0) {
  if (progressHideTimeoutId.value) {
    clearTimeout(progressHideTimeoutId.value)
  }
  progressHideTimeoutId.value = window.setTimeout(() => {
    showProgressDialog.value = false
    progressHideTimeoutId.value = null
  }, delay)
}

function hideProgressDialog(immediate = false) {
  stopProgressInterval()
  scheduleHideDialog(immediate ? 0 : 200)
}

function completeProgressDialog() {
  stopProgressInterval()
  progressStage.value = progressStepKeys.length
  scheduleHideDialog(800)
}

onBeforeUnmount(() => {
  stopProgressInterval()
  if (progressHideTimeoutId.value) {
    clearTimeout(progressHideTimeoutId.value)
  }
})
</script>
