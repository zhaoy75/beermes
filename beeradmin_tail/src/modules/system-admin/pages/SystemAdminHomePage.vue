<template>
  <SystemAdminLayout>
    <PageBreadcrumb :pageTitle="t('systemAdmin.pages.home.title')" />

    <div class="grid gap-4 md:grid-cols-3">
      <div
        v-for="card in metricCards"
        :key="card.label"
        class="rounded-2xl border border-amber-200 bg-white p-5 shadow-theme-xs dark:border-amber-900/30 dark:bg-gray-900"
      >
        <p class="text-sm text-gray-500 dark:text-gray-400">{{ card.label }}</p>
        <p class="mt-3 text-3xl font-semibold text-gray-900 dark:text-white">{{ card.value }}</p>
      </div>
    </div>

    <div class="mt-6 grid gap-6 lg:grid-cols-[1.6fr_1fr]">
      <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900">
        <div class="flex items-center justify-between gap-3">
          <div>
            <h3 class="text-lg font-semibold text-gray-800 dark:text-white/90">
              {{ t('systemAdmin.pages.home.tenantsTitle') }}
            </h3>
            <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
              {{ t('systemAdmin.pages.home.tenantsSubtitle') }}
            </p>
          </div>
          <router-link
            to="/system-admin/tenants"
            class="rounded-lg bg-amber-500 px-4 py-2 text-sm font-medium text-white hover:bg-amber-600"
          >
            {{ t('systemAdmin.actions.viewTenants') }}
          </router-link>
        </div>

        <div v-if="store.loading" class="mt-6 text-sm text-gray-500 dark:text-gray-400">
          {{ t('common.loading') }}
        </div>

        <div v-else-if="store.error" class="mt-6 rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700 dark:bg-red-900/20 dark:text-red-300">
          {{ store.error }}
        </div>

        <div v-else class="mt-6 space-y-3">
          <router-link
            v-for="tenant in topTenants"
            :key="tenant.id"
            :to="`/system-admin/tenants/${tenant.id}`"
            class="flex items-center justify-between gap-4 rounded-xl border border-gray-200 px-4 py-3 hover:border-amber-300 hover:bg-amber-50/40 dark:border-gray-800 dark:hover:border-amber-900/40 dark:hover:bg-white/[0.02]"
          >
            <div>
              <div class="font-medium text-gray-900 dark:text-white">{{ tenant.name }}</div>
              <div class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                {{ t('systemAdmin.fields.users') }}: {{ tenant.userCount }}
              </div>
            </div>
            <TenantStatusBadge :status="tenant.status" />
          </router-link>
        </div>
      </section>

      <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900">
        <h3 class="text-lg font-semibold text-gray-800 dark:text-white/90">
          {{ t('systemAdmin.pages.home.architectureTitle') }}
        </h3>
        <ul class="mt-4 space-y-3 text-sm text-gray-600 dark:text-gray-300">
          <li>{{ t('systemAdmin.pages.home.architectureRoutes') }}</li>
          <li>{{ t('systemAdmin.pages.home.architectureGuards') }}</li>
          <li>{{ t('systemAdmin.pages.home.architectureModules') }}</li>
          <li>{{ t('systemAdmin.pages.home.architectureFuture') }}</li>
        </ul>
      </section>
    </div>
  </SystemAdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted } from 'vue'
import { useI18n } from 'vue-i18n'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import SystemAdminLayout from '@/layouts/SystemAdminLayout.vue'
import TenantStatusBadge from '@/modules/system-admin/components/TenantStatusBadge.vue'
import { useSystemAdminStore } from '@/modules/system-admin/stores/useSystemAdminStore'

const { t } = useI18n()
const store = useSystemAdminStore()

const metricCards = computed(() => [
  { label: t('systemAdmin.metrics.tenants'), value: store.tenants.length },
  { label: t('systemAdmin.metrics.users'), value: store.tenants.reduce((sum, item) => sum + item.userCount, 0) },
  { label: t('systemAdmin.metrics.owners'), value: store.tenants.reduce((sum, item) => sum + item.ownerCount, 0) },
])

const topTenants = computed(() => store.tenants.slice(0, 5))

onMounted(() => {
  store.loadTenants().catch(() => undefined)
})
</script>
