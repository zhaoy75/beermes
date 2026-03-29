<template>
  <aside
    :class="[
      'fixed mt-16 flex flex-col lg:mt-0 top-0 px-5 left-0 bg-white dark:bg-gray-900 dark:border-gray-800 text-gray-900 h-screen transition-all duration-300 ease-in-out z-99999 border-r border-gray-200',
      {
        'lg:w-[240px]': isExpanded || isMobileOpen || isHovered,
        'lg:w-[90px]': !isExpanded && !isHovered,
        'translate-x-0 w-[240px]': isMobileOpen,
        '-translate-x-full': !isMobileOpen,
        'lg:translate-x-0': true,
      },
    ]"
    @mouseenter="setIsHovered(true)"
    @mouseleave="setIsHovered(false)"
  >
    <div
      :class="[
        'py-8 flex',
        !isExpanded && !isHovered ? 'lg:justify-center' : 'justify-start',
      ]"
    >
      <router-link to="/system-admin">
        <div
          class="flex h-10 items-center rounded-xl bg-amber-100 px-3 text-sm font-semibold tracking-wide text-amber-900 dark:bg-amber-900/30 dark:text-amber-200"
        >
          <span v-if="isExpanded || isHovered || isMobileOpen">System Admin</span>
          <span v-else>SA</span>
        </div>
      </router-link>
    </div>

    <nav class="flex flex-col gap-3 overflow-y-auto">
      <div>
        <h2
          :class="[
            'mb-4 text-xs uppercase flex leading-[20px] text-gray-400',
            !isExpanded && !isHovered ? 'lg:justify-center' : 'justify-start',
          ]"
        >
          <template v-if="isExpanded || isHovered || isMobileOpen">
            {{ t('systemAdmin.nav.group') }}
          </template>
          <HorizontalDots v-else />
        </h2>

        <ul class="flex flex-col gap-2">
          <li v-for="item in navItems" :key="item.path">
            <router-link
              :to="item.path"
              :class="[
                'menu-item group',
                isActive(item.path) ? 'menu-item-active' : 'menu-item-inactive',
              ]"
            >
              <span
                :class="[
                  isActive(item.path) ? 'menu-item-icon-active' : 'menu-item-icon-inactive',
                ]"
              >
                <component :is="item.icon" />
              </span>
              <span v-if="isExpanded || isHovered || isMobileOpen" class="menu-item-text">
                {{ item.label }}
              </span>
            </router-link>
          </li>
        </ul>
      </div>

      <div
        class="mt-4 rounded-2xl border border-amber-200 bg-amber-50 p-4 text-sm text-amber-900 dark:border-amber-900/40 dark:bg-amber-900/20 dark:text-amber-200"
        v-if="isExpanded || isHovered || isMobileOpen"
      >
        <div class="font-semibold">{{ t('systemAdmin.nav.noticeTitle') }}</div>
        <p class="mt-1 text-xs leading-5">{{ t('systemAdmin.nav.noticeBody') }}</p>
      </div>
    </nav>
  </aside>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useI18n } from 'vue-i18n'
import { LayoutDashboardIcon, SettingsIcon, ListIcon, HorizontalDots } from '@/icons'
import { useSidebar } from '@/composables/useSidebar'

const route = useRoute()
const { t } = useI18n()
const { isExpanded, isMobileOpen, isHovered, setIsHovered } = useSidebar()

const navItems = computed(() => [
  {
    path: '/system-admin',
    label: t('systemAdmin.nav.dashboard'),
    icon: LayoutDashboardIcon,
  },
  {
    path: '/system-admin/tenants',
    label: t('systemAdmin.nav.tenants'),
    icon: SettingsIcon,
  },
  {
    path: '/system-admin/audit',
    label: t('systemAdmin.nav.audit'),
    icon: ListIcon,
  },
  {
    path: '/system-admin/attr-definitions',
    label: t('sidebar.items.attrDefMaster'),
    icon: SettingsIcon,
  },
  {
    path: '/system-admin/attr-sets',
    label: t('sidebar.items.attrSetMaster'),
    icon: SettingsIcon,
  },
])

function isActive(path: string) {
  return route.path === path || route.path.startsWith(`${path}/`)
}
</script>
