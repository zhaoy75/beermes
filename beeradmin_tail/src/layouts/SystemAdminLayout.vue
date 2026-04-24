<template>
  <div class="min-h-screen xl:flex bg-amber-50/30 dark:bg-gray-950">
    <SystemAdminSidebar />
    <Backdrop />
    <div
      class="flex-1 transition-all duration-300 ease-in-out"
      :class="[isExpanded || isHovered ? 'lg:ml-[240px]' : 'lg:ml-[90px]']"
    >
      <AppHeader />
      <div class="w-full p-4 md:p-6">
        <slot></slot>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import Backdrop from '@/components/layout/Backdrop.vue'
import AppHeader from '@/components/layout/AppHeader.vue'
import { useSidebar } from '@/composables/useSidebar'
import SystemAdminSidebar from '@/modules/system-admin/components/SystemAdminSidebar.vue'

const { isExpanded, isHovered } = useSidebar()
</script>
