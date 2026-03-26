<template>
  <SystemAdminLayout>
    <PageBreadcrumb :pageTitle="t('systemAdmin.pages.audit.title')" />

    <section class="rounded-2xl border border-gray-200 bg-white p-5 dark:border-gray-800 dark:bg-gray-900">
      <h3 class="text-lg font-semibold text-gray-900 dark:text-white">
        {{ t('systemAdmin.pages.audit.title') }}
      </h3>
      <p class="mt-1 text-sm text-gray-500 dark:text-gray-400">
        {{ t('systemAdmin.pages.audit.subtitle') }}
      </p>

      <div class="mt-6 rounded-xl border border-dashed border-gray-300 p-6 dark:border-gray-700">
        <p class="text-sm text-gray-600 dark:text-gray-300">
          {{ t('systemAdmin.pages.audit.placeholder') }}
        </p>
        <p class="mt-3 text-xs text-gray-500 dark:text-gray-400">
          {{ t('systemAdmin.pages.audit.placeholderHint') }}
        </p>
      </div>
    </section>
  </SystemAdminLayout>
</template>

<script setup lang="ts">
import { useI18n } from 'vue-i18n'
import PageBreadcrumb from '@/components/common/PageBreadcrumb.vue'
import SystemAdminLayout from '@/layouts/SystemAdminLayout.vue'

const { t } = useI18n()
</script>
