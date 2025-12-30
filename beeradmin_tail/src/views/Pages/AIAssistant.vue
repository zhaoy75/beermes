<template>
  <AdminLayout>
    <PageBreadcrumb :pageTitle="currentPageTitle" />
    <div class="space-y-6">
      <section class="rounded-2xl border border-slate-200 bg-white shadow-sm">
        <header class="border-b border-slate-100 px-6 py-5">
          <h1 class="text-xl font-semibold text-slate-900">
            {{ currentPageTitle }}
          </h1>
          <p class="mt-1 text-sm text-slate-500">
            {{ $t('assistant.subtitle') }}
          </p>
        </header>
        <div class="grid gap-0 lg:grid-cols-5">
          <div class="lg:col-span-5 flex flex-col border-t border-slate-100 lg:border-t-0 lg:border-l">
            <div
              ref="historyEl"
              class="flex-1 overflow-y-auto px-6 py-6 space-y-4 max-h-[60vh]"
            >
              <p
                v-if="messages.length === 0"
                class="rounded-xl border border-dashed border-slate-200 bg-slate-50 px-4 py-6 text-center text-sm text-slate-500"
              >
                {{ $t('assistant.emptyState') }}
              </p>
              <div
                v-for="message in messages"
                :key="message.id"
                :class="[
                  'flex gap-3 rounded-2xl border px-4 py-3 shadow-sm',
                  message.role === 'assistant'
                    ? 'border-blue-100 bg-blue-50 text-slate-800'
                    : 'border-slate-200 bg-white'
                ]"
              >
                <div
                  class="mt-1 flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full text-sm font-semibold"
                  :class="message.role === 'assistant' ? 'bg-blue-500 text-white' : 'bg-slate-100 text-slate-700'"
                >
                  {{ message.role === 'assistant' ? 'AI' : 'You' }}
                </div>
                <div class="flex-1 space-y-1">
                  <p class="text-sm leading-relaxed text-slate-800 whitespace-pre-line">
                    {{ message.content }}
                  </p>
                  <p class="text-xs text-slate-400">
                    {{ formatTimestamp(message.createdAt) }}
                  </p>
                </div>
              </div>
              <div v-if="isSending" class="flex items-center gap-2 text-sm text-slate-500">
                <svg class="h-4 w-4 animate-spin text-blue-500" viewBox="0 0 24 24" fill="none">
                  <circle class="opacity-30" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
                  <path
                    class="opacity-90"
                    d="M22 12a10 10 0 0 0-10-10"
                    stroke="currentColor"
                    stroke-width="4"
                    stroke-linecap="round"
                  />
                </svg>
                {{ $t('assistant.waiting') }}
              </div>
            </div>
            <footer class="border-t border-slate-100 bg-slate-50 px-6 py-5">
              <form class="space-y-3" @submit.prevent="submitQuestion">
                <label class="block text-sm font-medium text-slate-700">
                  {{ $t('assistant.promptLabel') }}
                </label>
                <textarea
                  v-model="draft"
                  :placeholder="$t('assistant.promptPlaceholder')"
                  class="min-h-[110px] w-full rounded-2xl border border-slate-200 bg-white px-4 py-3 text-sm text-slate-800 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-2 focus:ring-blue-200"
                  :disabled="isSending"
                  required
                />
                <div class="flex items-center justify-between gap-3">
                  <p class="text-xs text-slate-400">
                    {{ $t('assistant.disclaimer') }}
                  </p>
                  <button
                    type="submit"
                    class="inline-flex items-center gap-2 rounded-full bg-blue-600 px-5 py-2 text-sm font-semibold text-white shadow-sm transition hover:bg-blue-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-blue-500 disabled:cursor-not-allowed disabled:bg-slate-200"
                    :disabled="isSending || draft.trim().length === 0"
                  >
                    <svg
                      v-if="isSending"
                      class="h-4 w-4 animate-spin"
                      viewBox="0 0 24 24"
                      fill="none"
                    >
                      <circle class="opacity-30" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4" />
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
                        isSending
                          ? $t('assistant.submitSending')
                          : $t('assistant.submit')
                      }}
                    </span>
                  </button>
                </div>
                <p v-if="errorMessage" class="text-sm text-red-600">
                  {{ errorMessage }}
                </p>
              </form>
            </footer>
          </div>
        </div>
      </section>
    </div>
  </AdminLayout>
</template>

<script setup lang="ts">
import { nextTick, ref, watch, computed } from 'vue'
import { useI18n } from 'vue-i18n'
import AdminLayout from '@/components/layout/AdminLayout.vue'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'

type Role = 'user' | 'assistant'
type ChatMessage = {
  id: string
  createdAt: string
  role: Role
  content: string
}

const { t } = useI18n()
const currentPageTitle = computed(() => t('assistant.title'))

const messages = ref<ChatMessage[]>([
  {
    id: makeId(),
    createdAt: new Date().toISOString(),
    role: 'assistant',
    content: t('assistant.seedMessage'),
  },
])

const draft = ref('')
const isSending = ref(false)
const errorMessage = ref('')
const historyEl = ref<HTMLElement | null>(null)
const chatEndpoint = import.meta.env.VITE_AI_ASSISTANT_API_URL ?? '/api/assistant/chat'

watch(
  () => messages.value.length,
  async () => {
    await nextTick()
    const el = historyEl.value
    if (el) {
      el.scrollTop = el.scrollHeight
    }
  }
)

function formatTimestamp(value: string) {
  const formatter = new Intl.DateTimeFormat(undefined, {
    dateStyle: 'medium',
    timeStyle: 'short',
  })
  return formatter.format(new Date(value))
}

async function submitQuestion() {
  const question = draft.value.trim()
  if (!question || isSending.value) return

  errorMessage.value = ''
  isSending.value = true
  draft.value = ''

  const userMessage: ChatMessage = {
    id: makeId(),
    role: 'user',
    content: question,
    createdAt: new Date().toISOString(),
  }
  messages.value.push(userMessage)

  try {
    const response = await fetch(chatEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        prompt: question,
        history: messages.value.slice(-6).map((m) => ({ role: m.role, content: m.content })),
      }),
    })

    if (!response.ok) {
      const message = await response.text()
      throw new Error(message || t('assistant.errorGeneric'))
    }

    const payload = await response.json()
    const assistantContent = extractTextFromPayload(payload)
    messages.value.push({
      id: makeId(),
      role: 'assistant',
      content: assistantContent,
      createdAt: new Date().toISOString(),
    })
  } catch (error) {
    console.error('AI assistant error', error)
    errorMessage.value = error instanceof Error ? error.message : t('assistant.errorGeneric')
  } finally {
    isSending.value = false
  }
}

function extractTextFromPayload(payload: unknown) {
  if (payload && typeof payload === 'object') {
    const maybeText =
      (payload as Record<string, unknown>).text ??
      (payload as Record<string, unknown>).answer ??
      (payload as Record<string, unknown>).content
    if (typeof maybeText === 'string' && maybeText.trim().length) {
      return maybeText.trim()
    }
  }
  return t('assistant.fallbackAnswer')
}

function makeId() {
  if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') {
    return crypto.randomUUID()
  }
  return Math.random().toString(36).slice(2)
}
</script>
