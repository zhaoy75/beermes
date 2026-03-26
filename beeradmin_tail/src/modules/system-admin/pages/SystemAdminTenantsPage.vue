<template>
  <SystemAdminLayout>
    <PageBreadcrumb :pageTitle="t('systemAdmin.pages.tenants.title')" />

    <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900">
      <div class="flex flex-col gap-4 lg:flex-row lg:items-center lg:justify-between">
        <div>
          <h3 class="text-lg font-semibold text-gray-800 dark:text-white/90">
            {{ t('systemAdmin.pages.tenants.title') }}
          </h3>
          <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {{ t('systemAdmin.pages.tenants.subtitle') }}
          </p>
        </div>
        <button
          type="button"
          disabled
          class="rounded-lg bg-gray-200 px-4 py-2.5 text-sm font-medium text-gray-500 dark:bg-gray-800 dark:text-gray-400"
        >
          {{ t('systemAdmin.actions.createTenant') }}
        </button>
      </div>

      <div class="mt-6 grid gap-4 md:grid-cols-[2fr_1fr]">
        <input
          v-model="keyword"
          type="text"
          :placeholder="t('systemAdmin.pages.tenants.searchPlaceholder')"
          class="h-11 rounded-lg border border-gray-300 bg-transparent px-4 py-2.5 text-sm text-gray-800 shadow-theme-xs focus:border-amber-300 focus:outline-hidden focus:ring-3 focus:ring-amber-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
        />
        <select
          v-model="status"
          class="h-11 rounded-lg border border-gray-300 bg-transparent px-3 py-2.5 text-sm text-gray-800 shadow-theme-xs focus:border-amber-300 focus:outline-hidden focus:ring-3 focus:ring-amber-500/10 dark:border-gray-700 dark:bg-gray-900 dark:text-white/90"
        >
          <option value="">{{ t('systemAdmin.filters.allStatuses') }}</option>
          <option value="active">{{ t('systemAdmin.status.active') }}</option>
          <option value="suspended">{{ t('systemAdmin.status.suspended') }}</option>
          <option value="voided">{{ t('systemAdmin.status.voided') }}</option>
        </select>
      </div>

      <div v-if="store.loading" class="mt-6 text-sm text-gray-500 dark:text-gray-400">
        {{ t('common.loading') }}
      </div>
      <div v-else-if="store.error" class="mt-6 rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700 dark:bg-red-900/20 dark:text-red-300">
        {{ store.error }}
      </div>

      <div v-else class="mt-6 grid gap-4 lg:grid-cols-2">
        <router-link
          v-for="tenant in filteredTenants"
          :key="tenant.id"
          :to="`/system-admin/tenants/${tenant.id}`"
          class="rounded-2xl border border-gray-200 p-5 transition hover:border-amber-300 hover:bg-amber-50/40 dark:border-gray-800 dark:hover:border-amber-900/40 dark:hover:bg-white/[0.02]"
        >
          <div class="flex items-start justify-between gap-4">
            <div>
              <h4 class="text-base font-semibold text-gray-900 dark:text-white">{{ tenant.name }}</h4>
              <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">
                {{ t('systemAdmin.fields.createdAt') }}: {{ formatDate(tenant.createdAt) }}
              </p>
            </div>
            <TenantStatusBadge :status="tenant.status" />
          </div>
          <div class="mt-4 grid grid-cols-2 gap-3 text-sm text-gray-600 dark:text-gray-300">
            <div>
              <div class="text-xs text-gray-500 dark:text-gray-400">{{ t('systemAdmin.fields.users') }}</div>
              <div class="mt-1 font-medium">{{ tenant.userCount }}</div>
            </div>
            <div>
              <div class="text-xs text-gray-500 dark:text-gray-400">{{ t('systemAdmin.fields.owners') }}</div>
              <div class="mt-1 font-medium">{{ tenant.ownerCount }}</div>
            </div>
          </div>
        </router-link>
      </div>

      <div
        v-if="!store.loading && !store.error && filteredTenants.length === 0"
        class="mt-6 rounded-xl border border-dashed border-gray-300 p-6 text-center text-sm text-gray-500 dark:border-gray-700 dark:text-gray-400"
      >
        {{ t('systemAdmin.empty.tenants') }}
      </div>
    </section>
  </SystemAdminLayout>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { useI18n } from 'vue-i18n'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import SystemAdminLayout from '@/layouts/SystemAdminLayout.vue'
import TenantStatusBadge from '@/modules/system-admin/components/TenantStatusBadge.vue'
import { useSystemAdminStore } from '@/modules/system-admin/stores/useSystemAdminStore'

const { t } = useI18n()
const store = useSystemAdminStore()
const keyword = ref('')
const status = ref('')

const filteredTenants = computed(() => {
  const word = keyword.value.trim().toLowerCase()
  return store.tenants.filter((tenant) => {
    const matchesWord = !word || tenant.name.toLowerCase().includes(word)
    const matchesStatus = !status.value || tenant.status === status.value
    return matchesWord && matchesStatus
  })
})

function formatDate(value: string | null) {
  if (!value) return '-'
  return new Date(value).toLocaleString()
}

onMounted(() => {
  store.loadTenants().catch(() => undefined)
})
</script>
