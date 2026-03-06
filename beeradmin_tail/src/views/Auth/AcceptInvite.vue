<template>
  <FullScreenLayout>
    <div class="relative p-6 bg-white z-1 dark:bg-gray-900 sm:p-0">
      <div class="relative flex flex-col justify-center w-full h-screen lg:flex-row dark:bg-gray-900">
        <div class="flex flex-col flex-1 w-full lg:w-1/2">
          <button
            type="button"
            @click="toggleLanguage"
            class="absolute top-6 right-6 inline-flex h-10 w-10 items-center justify-center rounded-full border border-gray-200 text-gray-500 transition-colors hover:bg-gray-100 hover:text-gray-700 dark:border-gray-700 dark:text-gray-400 dark:hover:bg-gray-800 dark:hover:text-gray-200"
            :aria-label="$t('auth.acceptInvite.languageToggle', { lang: nextLocaleLabel })"
            :title="$t('auth.acceptInvite.languageToggle', { lang: nextLocaleLabel })"
          >
            <svg
              class="h-5 w-5"
              viewBox="0 0 20 20"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <path
                d="M10 18.3333C14.6023 18.3333 18.3333 14.6023 18.3333 10C18.3333 5.39763 14.6023 1.66663 10 1.66663C5.39763 1.66663 1.66663 5.39763 1.66663 10C1.66663 14.6023 5.39763 18.3333 10 18.3333Z"
                stroke="currentColor"
                stroke-width="1.2"
              />
              <path
                d="M10 1.66663C12.0848 3.94953 13.25 6.87916 13.25 10C13.25 13.1208 12.0848 16.0504 10 18.3333"
                stroke="currentColor"
                stroke-width="1.2"
              />
              <path
                d="M10 1.66663C7.91518 3.94953 6.75 6.87916 6.75 10C6.75 13.1208 7.91518 16.0504 10 18.3333"
                stroke="currentColor"
                stroke-width="1.2"
              />
              <path
                d="M1.66663 10H18.3333"
                stroke="currentColor"
                stroke-width="1.2"
              />
              <path
                d="M3.54163 5.20837H16.4583"
                stroke="currentColor"
                stroke-width="1.2"
              />
              <path
                d="M3.54163 14.7916H16.4583"
                stroke="currentColor"
                stroke-width="1.2"
              />
            </svg>
            <span class="sr-only">
              {{ $t('auth.acceptInvite.languageToggle', { lang: nextLocaleLabel }) }}
            </span>
          </button>
          <div class="w-full max-w-md pt-10 mx-auto">
            <router-link
              to="/signin"
              class="inline-flex items-center text-sm text-gray-500 transition-colors hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300"
            >
              <svg
                class="stroke-current"
                xmlns="http://www.w3.org/2000/svg"
                width="20"
                height="20"
                viewBox="0 0 20 20"
                fill="none"
              >
                <path
                  d="M12.7083 5L7.5 10.2083L12.7083 15.4167"
                  stroke=""
                  stroke-width="1.5"
                  stroke-linecap="round"
                  stroke-linejoin="round"
                />
              </svg>
              {{ t('auth.acceptInvite.backToSignIn') }}
            </router-link>
          </div>

          <div class="flex flex-col justify-center flex-1 w-full max-w-md mx-auto">
            <div class="mb-5 sm:mb-8">
              <h1
                class="mb-2 font-semibold text-gray-800 text-title-sm dark:text-white/90 sm:text-title-md"
              >
                {{ isRecoveryMode ? t('auth.acceptInvite.titleRecovery') : t('auth.acceptInvite.titleInvite') }}
              </h1>
              <p class="text-sm text-gray-500 dark:text-gray-400">
                {{
                  isRecoveryMode
                    ? t('auth.acceptInvite.subtitleRecovery')
                    : t('auth.acceptInvite.subtitleInvite')
                }}
              </p>
            </div>

            <div
              v-if="state === 'verifying'"
              class="rounded-lg border border-gray-200 bg-gray-50 px-4 py-3 text-sm text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
            >
              {{ t('auth.acceptInvite.verifying') }}
            </div>

            <form v-else @submit.prevent="submit" class="space-y-5">
              <div
                class="rounded-lg border border-gray-200 bg-gray-50 px-4 py-3 text-sm text-gray-700 dark:border-gray-700 dark:bg-gray-800 dark:text-gray-300"
              >
                {{ t('auth.acceptInvite.emailLabel') }}: <span class="font-medium">{{ email }}</span>
              </div>

              <div>
                <label
                  for="password"
                  class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400"
                >
                  {{ t('auth.acceptInvite.passwordLabel') }}<span class="text-error-500">*</span>
                </label>
                <input
                  v-model="password"
                  :type="showPassword ? 'text' : 'password'"
                  id="password"
                  :placeholder="t('auth.acceptInvite.passwordPlaceholder')"
                  class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
                />
              </div>

              <div>
                <label
                  for="confirmPassword"
                  class="mb-1.5 block text-sm font-medium text-gray-700 dark:text-gray-400"
                >
                  {{ t('auth.acceptInvite.confirmPasswordLabel') }}<span class="text-error-500">*</span>
                </label>
                <input
                  v-model="confirmPassword"
                  :type="showPassword ? 'text' : 'password'"
                  id="confirmPassword"
                  :placeholder="t('auth.acceptInvite.confirmPasswordPlaceholder')"
                  class="dark:bg-dark-900 h-11 w-full rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs placeholder:text-gray-400 focus:border-brand-300 focus:outline-hidden focus:ring-3 focus:ring-brand-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90 dark:placeholder:text-white/30 dark:focus:border-brand-800"
                />
              </div>

              <label
                for="showPassword"
                class="flex items-center text-sm font-normal text-gray-700 cursor-pointer select-none dark:text-gray-400"
              >
                <input
                  id="showPassword"
                  v-model="showPassword"
                  type="checkbox"
                  class="h-4 w-4 rounded border-gray-300 text-brand-500 focus:ring-brand-500"
                />
                <span class="ml-2">{{ t('auth.acceptInvite.showPassword') }}</span>
              </label>

              <p v-if="errorMsg" class="text-red-600 text-sm">{{ errorMsg }}</p>
              <p v-if="successMsg" class="text-green-600 text-sm">{{ successMsg }}</p>

              <div>
                <button
                  type="submit"
                  :disabled="isSubmitting || !isReadyForSubmit"
                  class="flex items-center justify-center w-full px-4 py-3 text-sm font-medium text-white transition rounded-lg bg-brand-500 shadow-theme-xs hover:bg-brand-600 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  {{
                    isSubmitting
                      ? t('auth.acceptInvite.processing')
                      : (isRecoveryMode
                        ? t('auth.acceptInvite.submitRecovery')
                        : t('auth.acceptInvite.submitInvite'))
                  }}
                </button>
              </div>
            </form>
          </div>
        </div>

        <div
          class="relative items-center hidden w-full h-full lg:w-1/2 bg-brand-950 dark:bg-white/5 lg:grid"
        >
          <div class="flex items-center justify-center z-1">
            <CommonGridShape />
            <div class="flex flex-col items-center max-w-xs">
              <router-link to="/" class="block mb-4">
                <img width="{231}" height="{48}" src="/images/logo/beer-auth.svg" alt="Logo" />
              </router-link>
              <p class="text-center text-gray-400 dark:text-white/60">
                {{ t('auth.acceptInvite.sideCopy') }}
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  </FullScreenLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useI18n } from 'vue-i18n'
import CommonGridShape from '@/components/common/CommonGridShape.vue'
import FullScreenLayout from '@/components/layout/FullScreenLayout.vue'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

type ViewState = 'verifying' | 'ready' | 'submitting' | 'success' | 'error'
type LocaleOption = 'en' | 'ja'

const MIN_PASSWORD_LENGTH = 6

const route = useRoute()
const router = useRouter()
const auth = useAuthStore()
const { t, locale } = useI18n()

const state = ref<ViewState>('verifying')
const email = ref('')
const password = ref('')
const confirmPassword = ref('')
const showPassword = ref(false)
const errorMsg = ref('')
const successMsg = ref('')

const isSubmitting = computed(() => state.value === 'submitting')
const isReadyForSubmit = computed(() => state.value === 'ready' || state.value === 'error')

function readParam(input: unknown): string | null {
  if (typeof input !== 'string') return null
  const trimmed = input.trim()
  return trimmed ? trimmed : null
}

function readHashParam(key: string): string | null {
  const hash = route.hash.startsWith('#') ? route.hash.slice(1) : route.hash
  if (!hash) return null
  const params = new URLSearchParams(hash)
  return readParam(params.get(key))
}

const tenantId = computed(() => readParam(route.query.tenant_id) ?? null)

const redirectPath = computed(() => {
  const redirect = readParam(route.query.redirect)
  if (!redirect) return '/'
  return redirect.startsWith('/') ? redirect : '/'
})

const tokenHash = computed(() => readParam(route.query.token_hash) ?? readHashParam('token_hash'))
const inviteType = computed(() => readParam(route.query.type) ?? readHashParam('type') ?? 'invite')
const isRecoveryMode = computed(() => inviteType.value === 'recovery')
const nextLocale = computed<LocaleOption>(() => (locale.value === 'ja' ? 'en' : 'ja'))
const nextLocaleLabel = computed(() => t(`auth.signin.languageNames.${nextLocale.value}`))

const toggleLanguage = () => {
  locale.value = nextLocale.value
}

async function verifyLinkAndSession() {
  errorMsg.value = ''
  state.value = 'verifying'

  if (tokenHash.value && inviteType.value !== 'invite' && inviteType.value !== 'recovery') {
    state.value = 'error'
    errorMsg.value = t('auth.acceptInvite.errors.invalidLinkType')
    return
  }

  if (tokenHash.value) {
    const { error } = await supabase.auth.verifyOtp({
      token_hash: tokenHash.value,
      type: isRecoveryMode.value ? 'recovery' : 'invite',
    })
    if (error) {
      const { data: fallbackSession } = await supabase.auth.getSession()
      if (!fallbackSession.session?.user?.email) {
        state.value = 'error'
        errorMsg.value = t('auth.acceptInvite.errors.invalidOrExpiredLink')
        return
      }
    }
  }

  const { data: sessionData, error: sessionError } = await supabase.auth.getSession()
  if (sessionError || !sessionData.session?.user?.email) {
    state.value = 'error'
    errorMsg.value = tokenHash.value
      ? t('auth.acceptInvite.errors.invalidOrExpiredLink')
      : t('auth.acceptInvite.errors.missingSession')
    return
  }

  email.value = sessionData.session.user.email
  await auth.bootstrap()
  state.value = 'ready'
}

async function submit() {
  if (!isReadyForSubmit.value) return

  errorMsg.value = ''
  successMsg.value = ''

  if (!password.value) {
    state.value = 'error'
    errorMsg.value = t('auth.acceptInvite.errors.passwordRequired')
    return
  }
  if (password.value.length < MIN_PASSWORD_LENGTH) {
    state.value = 'error'
    errorMsg.value = t('auth.acceptInvite.errors.passwordMin', { min: MIN_PASSWORD_LENGTH })
    return
  }
  if (password.value !== confirmPassword.value) {
    state.value = 'error'
    errorMsg.value = t('auth.acceptInvite.errors.passwordMismatch')
    return
  }

  state.value = 'submitting'

  try {
    if (isRecoveryMode.value) {
      const { error } = await supabase.auth.updateUser({ password: password.value })
      if (error) throw error
    } else {
      const payload: { password: string; tenant_id?: string } = { password: password.value }
      if (tenantId.value) payload.tenant_id = tenantId.value

      const { data, error } = await supabase.functions.invoke('accept-invitation', {
        body: payload,
      })

      if (error) throw error
      if (data && typeof data === 'object' && 'error' in data) {
        throw new Error(String((data as { error?: unknown }).error ?? t('auth.acceptInvite.errors.submitFailed')))
      }
    }

    await supabase.auth.refreshSession()
    await auth.bootstrap()

    state.value = 'success'
    successMsg.value = isRecoveryMode.value
      ? t('auth.acceptInvite.success.passwordUpdated')
      : t('auth.acceptInvite.success.invitationAccepted')
    await router.replace(redirectPath.value)
  } catch (err) {
    state.value = 'error'
    errorMsg.value = err instanceof Error ? err.message : t('auth.acceptInvite.errors.submitFailed')
  }
}

onMounted(async () => {
  await verifyLinkAndSession()
})
</script>
