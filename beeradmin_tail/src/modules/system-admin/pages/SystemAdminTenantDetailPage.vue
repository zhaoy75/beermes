<template>
  <SystemAdminLayout>
    <PageBreadcrumb :pageTitle="pageTitle" />

    <div v-if="store.loading" class="text-sm text-gray-500 dark:text-gray-400">
      {{ t('common.loading') }}
    </div>
    <div v-else-if="store.error" class="rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700 dark:bg-red-900/20 dark:text-red-300">
      {{ store.error }}
    </div>
    <template v-else-if="detail">
      <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900">
        <div class="flex flex-col gap-4 lg:flex-row lg:items-start lg:justify-between">
          <div>
            <div class="flex items-center gap-3">
              <h3 class="text-lg font-semibold text-gray-900 dark:text-white">{{ detail.tenant.name }}</h3>
              <TenantStatusBadge :status="detail.tenant.status" />
            </div>
            <p class="mt-2 text-sm text-gray-500 dark:text-gray-400">
              {{ t('systemAdmin.pages.tenantDetail.subtitle') }}
            </p>
          </div>
          <div class="grid grid-cols-2 gap-3 text-sm">
            <div class="rounded-xl bg-gray-50 px-4 py-3 dark:bg-gray-800">
              <div class="text-xs text-gray-500 dark:text-gray-400">{{ t('systemAdmin.fields.users') }}</div>
              <div class="mt-1 font-semibold text-gray-900 dark:text-white">{{ detail.tenant.userCount }}</div>
            </div>
            <div class="rounded-xl bg-gray-50 px-4 py-3 dark:bg-gray-800">
              <div class="text-xs text-gray-500 dark:text-gray-400">{{ t('systemAdmin.fields.owners') }}</div>
              <div class="mt-1 font-semibold text-gray-900 dark:text-white">{{ detail.tenant.ownerCount }}</div>
            </div>
          </div>
        </div>
      </section>

      <div class="mt-6 grid gap-6 xl:grid-cols-[1.1fr_1fr]">
        <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900">
          <h4 class="text-base font-semibold text-gray-900 dark:text-white">
            {{ t('systemAdmin.pages.tenantDetail.membersTitle') }}
          </h4>
          <div class="mt-4 space-y-3">
            <div
              v-for="member in detail.members"
              :key="member.userId"
              class="flex items-center justify-between gap-4 rounded-xl border border-gray-200 px-4 py-3 dark:border-gray-800"
            >
              <div>
                <div class="font-medium text-gray-900 dark:text-white">{{ member.displayName }}</div>
                <div class="mt-1 text-xs text-gray-500 dark:text-gray-400">{{ member.email || member.userId }}</div>
              </div>
              <div class="text-sm text-gray-600 dark:text-gray-300">{{ member.role }}</div>
            </div>
          </div>
        </section>

        <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900">
          <h4 class="text-base font-semibold text-gray-900 dark:text-white">
            {{ t('systemAdmin.pages.tenantDetail.permissionsTitle') }}
          </h4>
          <div class="mt-4 space-y-3">
            <div
              v-for="feature in detail.featurePermissions"
              :key="feature.key"
              class="flex items-center justify-between rounded-xl border border-gray-200 px-4 py-3 dark:border-gray-800"
            >
              <span class="text-sm font-medium text-gray-800 dark:text-white">{{ feature.key }}</span>
              <span class="text-xs text-gray-500 dark:text-gray-400">
                {{ feature.enabled ? t('common.active') : t('common.inactive') }}
              </span>
            </div>
          </div>
        </section>
      </div>

      <div class="mt-6 grid gap-6 xl:grid-cols-[1fr_1fr]">
        <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900">
          <h4 class="text-base font-semibold text-gray-900 dark:text-white">
            {{ t('systemAdmin.pages.tenantDetail.settingsTitle') }}
          </h4>
          <dl class="mt-4 grid gap-4 text-sm">
            <div class="rounded-xl bg-gray-50 px-4 py-3 dark:bg-gray-800">
              <dt class="text-xs text-gray-500 dark:text-gray-400">{{ t('systemAdmin.fields.defaultLocale') }}</dt>
              <dd class="mt-1 font-medium text-gray-900 dark:text-white">{{ detail.settings.defaultLocale }}</dd>
            </div>
            <div class="rounded-xl bg-gray-50 px-4 py-3 dark:bg-gray-800">
              <dt class="text-xs text-gray-500 dark:text-gray-400">{{ t('systemAdmin.fields.timezone') }}</dt>
              <dd class="mt-1 font-medium text-gray-900 dark:text-white">{{ detail.settings.timezone }}</dd>
            </div>
            <div class="rounded-xl bg-gray-50 px-4 py-3 dark:bg-gray-800">
              <dt class="text-xs text-gray-500 dark:text-gray-400">{{ t('systemAdmin.fields.masterDataProfile') }}</dt>
              <dd class="mt-1 font-medium text-gray-900 dark:text-white">{{ detail.settings.masterDataProfileKey || '-' }}</dd>
            </div>
          </dl>
        </section>

        <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900">
          <h4 class="text-base font-semibold text-gray-900 dark:text-white">
            {{ t('systemAdmin.pages.tenantDetail.invitationsTitle') }}
          </h4>
          <div v-if="detail.invitations.length === 0" class="mt-4 text-sm text-gray-500 dark:text-gray-400">
            {{ t('systemAdmin.empty.invitations') }}
          </div>
          <div v-else class="mt-4 space-y-3">
            <div
              v-for="invite in detail.invitations"
              :key="invite.id"
              class="rounded-xl border border-gray-200 px-4 py-3 dark:border-gray-800"
            >
              <div class="font-medium text-gray-900 dark:text-white">{{ invite.email }}</div>
              <div class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                {{ invite.role }} / {{ invite.status }}
              </div>
            </div>
          </div>
        </section>
      </div>
    </template>
  </SystemAdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, watch } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import SystemAdminLayout from '@/layouts/SystemAdminLayout.vue'
import TenantStatusBadge from '@/modules/system-admin/components/TenantStatusBadge.vue'
import { useSystemAdminStore } from '@/modules/system-admin/stores/useSystemAdminStore'

const route = useRoute()
const { t } = useI18n()
const store = useSystemAdminStore()

const tenantId = computed(() => String(route.params.tenantId ?? ''))
const detail = computed(() => store.currentTenant)
const pageTitle = computed(() => detail.value?.tenant.name ?? t('systemAdmin.pages.tenantDetail.title'))

async function load() {
  if (!tenantId.value) return
  await store.loadTenantDetail(tenantId.value)
}

onMounted(() => {
  load().catch(() => undefined)
})

watch(tenantId, () => {
  load().catch(() => undefined)
})
</script>
