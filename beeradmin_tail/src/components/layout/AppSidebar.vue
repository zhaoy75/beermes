<template>
  <aside
    :class="[
      'fixed mt-16 flex flex-col lg:mt-0 top-0 px-5 left-0 bg-white dark:bg-gray-900 dark:border-gray-800 text-gray-900 h-screen transition-all duration-300 ease-in-out z-99999 border-r border-gray-200',
      {
        'lg:w-[290px]': isExpanded || isMobileOpen || isHovered,
        'lg:w-[90px]': !isExpanded && !isHovered,
        'translate-x-0 w-[290px]': isMobileOpen,
        '-translate-x-full': !isMobileOpen,
        'lg:translate-x-0': true,
      },
    ]"
    @mouseenter="!isExpanded && (isHovered = true)"
    @mouseleave="isHovered = false"
  >
    <div
      :class="[
        'py-8 flex',
        !isExpanded && !isHovered ? 'lg:justify-center' : 'justify-start',
      ]"
    >
      <router-link to="/">
        <img
          v-if="isExpanded || isHovered || isMobileOpen"
          class="dark:hidden"
          src="/images/logo/beer.svg"
          alt="Logo"
          width="180"
        />
        <img
          v-if="isExpanded || isHovered || isMobileOpen"
          class="hidden dark:block"
          src="/images/logo/beer.svg"
          alt="Logo"
          width="150"
          height="40"
        />
        <img
          v-else
          src="/images/logo/beer-icon.svg"
          alt="Logo"
          width="32"
          height="32"
        />
      </router-link>
    </div>
    <div
      class="flex flex-col overflow-y-auto duration-300 ease-linear no-scrollbar"
    >
      <nav class="mb-6">
        <div class="flex flex-col gap-4">
          <div v-for="(menuGroup, groupIndex) in menuGroups" :key="groupIndex">
            <h2
              :class="[
                'mb-4 text-xs uppercase flex leading-[20px] text-gray-400',
                !isExpanded && !isHovered
                  ? 'lg:justify-center'
                  : 'justify-start',
              ]"
            >
              <template v-if="isExpanded || isHovered || isMobileOpen">
                {{ menuGroup.title }}
              </template>
              <HorizontalDots v-else />
            </h2>
            <ul class="flex flex-col gap-4">
              <li v-for="(item, index) in menuGroup.items" :key="item.name">
                <button
                  v-if="item.subItems"
                  @click="toggleSubmenu(groupIndex, index)"
                  :class="[
                    'menu-item group w-full',
                    {
                      'menu-item-active': isSubmenuOpen(groupIndex, index),
                      'menu-item-inactive': !isSubmenuOpen(groupIndex, index),
                    },
                    !isExpanded && !isHovered
                      ? 'lg:justify-center'
                      : 'lg:justify-start',
                  ]"
                >
                  <span
                    :class="[
                      isSubmenuOpen(groupIndex, index)
                        ? 'menu-item-icon-active'
                        : 'menu-item-icon-inactive',
                    ]"
                  >
                    <component :is="item.icon" />
                  </span>
                  <span
                    v-if="isExpanded || isHovered || isMobileOpen"
                    class="menu-item-text"
                    >{{ item.name }}</span
                  >
                  <ChevronDownIcon
                    v-if="isExpanded || isHovered || isMobileOpen"
                    :class="[
                      'ml-auto w-5 h-5 transition-transform duration-200',
                      {
                        'rotate-180 text-brand-500': isSubmenuOpen(
                          groupIndex,
                          index
                        ),
                      },
                    ]"
                  />
                </button>
                <router-link
                  v-else-if="item.path"
                  :to="item.path"
                  :class="[
                    'menu-item group',
                    {
                      'menu-item-active': isActive(item.path),
                      'menu-item-inactive': !isActive(item.path),
                    },
                  ]"
                >
                  <span
                    :class="[
                      isActive(item.path)
                        ? 'menu-item-icon-active'
                        : 'menu-item-icon-inactive',
                    ]"
                  >
                    <component :is="item.icon" />
                  </span>
                  <span
                    v-if="isExpanded || isHovered || isMobileOpen"
                    class="menu-item-text"
                    >{{ item.name }}</span
                  >
                </router-link>
                <transition
                  @enter="startTransition"
                  @after-enter="endTransition"
                  @before-leave="startTransition"
                  @after-leave="endTransition"
                >
                  <div
                    v-show="
                      isSubmenuOpen(groupIndex, index) &&
                      (isExpanded || isHovered || isMobileOpen)
                    "
                  >
                    <ul class="mt-2 space-y-1 ml-9">
                      <li v-for="(subItem, subIndex) in item.subItems" :key="subItem.name">
                        <button
                          v-if="subItem.subItems"
                          type="button"
                          @click="toggleSubmenuChild(groupIndex, index, subIndex)"
                          :class="[
                            'menu-dropdown-item w-full text-left flex items-center',
                            {
                              'menu-dropdown-item-active': isSubmenuChildOpen(
                                groupIndex,
                                index,
                                subIndex
                              ),
                              'menu-dropdown-item-inactive': !isSubmenuChildOpen(
                                groupIndex,
                                index,
                                subIndex
                              ),
                            },
                          ]"
                        >
                          {{ subItem.name }}
                          <ChevronDownIcon
                            class="ml-auto w-4 h-4 transition-transform duration-200"
                            :class="{
                              'rotate-180 text-brand-500': isSubmenuChildOpen(
                                groupIndex,
                                index,
                                subIndex
                              ),
                            }"
                          />
                        </button>
                        <router-link
                          v-else-if="subItem.path"
                          :to="subItem.path"
                          :class="[
                            'menu-dropdown-item',
                            {
                              'menu-dropdown-item-active': isActive(
                                subItem.path
                              ),
                              'menu-dropdown-item-inactive': !isActive(
                                subItem.path
                              ),
                            },
                          ]"
                        >
                          {{ subItem.name }}
                          <span class="flex items-center gap-1 ml-auto">
                            <span
                              v-if="subItem.new"
                              :class="[
                                'menu-dropdown-badge',
                                {
                                  'menu-dropdown-badge-active': isActive(
                                    subItem.path
                                  ),
                                  'menu-dropdown-badge-inactive': !isActive(
                                    subItem.path
                                  ),
                                },
                              ]"
                            >
                              new
                            </span>
                            <span
                              v-if="subItem.pro"
                              :class="[
                                'menu-dropdown-badge',
                                {
                                  'menu-dropdown-badge-active': isActive(
                                    subItem.path
                                  ),
                                  'menu-dropdown-badge-inactive': !isActive(
                                    subItem.path
                                  ),
                                },
                              ]"
                            >
                              pro
                            </span>
                          </span>
                        </router-link>
                        <transition
                          @enter="startTransition"
                          @after-enter="endTransition"
                          @before-leave="startTransition"
                          @after-leave="endTransition"
                        >
                          <div
                            v-if="subItem.subItems"
                            v-show="
                              isSubmenuChildOpen(groupIndex, index, subIndex) &&
                              (isExpanded || isHovered || isMobileOpen)
                            "
                          >
                            <ul class="mt-1 space-y-1 ml-4">
                              <li v-for="child in subItem.subItems" :key="child.name">
                                <router-link
                                  :to="child.path"
                                  :class="[
                                    'menu-dropdown-item',
                                    {
                                      'menu-dropdown-item-active': isActive(
                                        child.path
                                      ),
                                      'menu-dropdown-item-inactive': !isActive(
                                        child.path
                                      ),
                                    },
                                  ]"
                                >
                                  {{ child.name }}
                                </router-link>
                              </li>
                            </ul>
                          </div>
                        </transition>
                      </li>
                    </ul>
                  </div>
                </transition>
              </li>
            </ul>
          </div>
        </div>
      </nav>
      <SidebarWidget v-if="isExpanded || isHovered || isMobileOpen" />
    </div>
  </aside>
</template>

<script setup>
import { ref, computed } from "vue";
import { useRoute } from "vue-router";
import { useI18n } from 'vue-i18n'

import {
  GridIcon,
  CalenderIcon,
  UserCircleIcon,
  ChatIcon,
  MailIcon,
  DocsIcon,
  PieChartIcon,
  ChevronDownIcon,
  HorizontalDots,
  PageIcon,
  TableIcon,
  ListIcon,
  PlugInIcon,
} from "../../icons";
import SidebarWidget from "./SidebarWidget.vue";
import BoxCubeIcon from "@/icons/BoxCubeIcon.vue";
import { useSidebar } from "@/composables/useSidebar";
import path from "path";

const route = useRoute();
const { t } = useI18n()

const openSubmenuChild = ref(null);

const { isExpanded, isMobileOpen, isHovered, openSubmenu } = useSidebar();

const menuGroups = computed(() => [
  {
    title: t('sidebar.group.main'),
    items: [
      // {
      //   icon: GridIcon,
      //   name: t('sidebar.items.dashboard'),
      //   path: "/",
      //   // subItems: [
      //   //   { name: "Ecommerce", path: "/", pro: false },
      //   //   { name: "DashBoard", path: "/beerdash", pro: false }
      //   // ],
      // },
      // {
      //   icon: GridIcon,
      //   name: t('sidebar.items.calendar'),
      //   path: "/calendar",
      //   // subItems: [
      //   //   { name: "Ecommerce", path: "/", pro: false },
      //   //   { name: "DashBoard", path: "/beerdash", pro: false }
      //   // ],
      // },
      // {
      //   icon: CalenderIcon,
      //   name: t('sidebar.items.recipemng'),
      //   subItems: [
      //      { name: t('sidebar.items.recipeList'), path: "/recipeList", pro: false },
      //      { name: t('sidebar.items.batchYield'), path: "/batchYieldSummary", pro: false },

      //   ],
      // },
      {
        icon: CalenderIcon,
        name: t('sidebar.items.production'),
        subItems: [
          { name: t('sidebar.items.recipeList'), path: "/recipeList", pro: false },
          { name: t('sidebar.items.batchList'), path: "/batches", pro: false },
          // { name: t('sidebar.items.waste'), path: "/waste", pro: false },
        ],
      },
      // {
      //   icon: CalenderIcon,
      //   name: t('sidebar.items.producedBeer'),
      //   path: "/producedBeer",
      // },
      {
        icon: CalenderIcon,
        name: t('sidebar.items.liquorTax'),
        subItems: [
          { name: t('sidebar.items.producedBeer'), path: "/producedBeer", pro: false },
          { name: t('sidebar.items.taxReport'), path: "/taxReports", pro: false },
          { name: t('sidebar.items.taxYearSummary'), path: "/taxYearSummary", pro: false },
          // { name: t('sidebar.items.siteMovements'), path: "/siteMovements", pro: false }
        ],
      },
      // {
      //   icon: CalenderIcon,
      //   name: t('sidebar.items.inventory'),
      //   subItems: [
      //     { name: t('sidebar.items.rawMaterialReceipts'), path: "/rawMaterialReceipts", pro: false },
      //     { name: t('sidebar.items.rawMaterialInventory'), path: "/rawMaterialInventory", pro: false },
      //   ],
      // },
      {
        icon: CalenderIcon,
        name: t('sidebar.items.masterMaintenance'),
        subItems: [
          // { name: t('sidebar.items.materialMaster'), path: "/MaterialMaster", pro: false },
          { name: t('sidebar.items.siteMaster'), path: "/siteMaster", pro: false },
          { name: t('sidebar.items.beerPackageCategory'), path: "/beerPackageCategory", pro: false },
          // { name: t('sidebar.items.tankMaintenance'), path: "/tankMaintenance", pro: false }
        ],
      },
      {
        icon: CalenderIcon,
        name: t('sidebar.items.systemMaintenance'),
        subItems: [
          { name: t('sidebar.items.alcoholTypeMaster'), path: "/alcoholTypeMaster", pro: false },
          { name: t('sidebar.items.alcoholTaxMaster'), path: "/alcoholTaxMaster", pro: false },
          { name: t('sidebar.items.materialClassMaster'), path: "/materialClassMaster", pro: false },
          { name: t('sidebar.items.materialTypeMaster'), path: "/materialTypeMaster", pro: false },
          { name: t('sidebar.items.siteTypeMaster'), path: "/siteTypeMaster", pro: false },
          {
            name: t('sidebar.items.systemRelated'),
            subItems: [
              { name: t('sidebar.items.attrDefMaster'), path: "/attrDefMaster", pro: false },
              { name: t('sidebar.items.attrSetMaster'), path: "/attrSetMaster", pro: false },
              { name: t('sidebar.items.uomMaster'), path: "/uomMaster", pro: false },
            ],
          },

        ],
      },
      {
        icon: UserCircleIcon,
        name: t('sidebar.items.userManagement'),
        subItems: [
          { name: t('sidebar.items.users'), path: "/users", pro: false },
          // { name: t('sidebar.items.profile'), path: "/profile", pro: false },
          { name: t('sidebar.items.changePassword'), path: "/change-password", pro: false },
        ],
      },

      // {
      //   name: "Forms",
      //   icon: ListIcon,
      //   subItems: [
      //     { name: "Form Elements", path: "/form-elements", pro: false },
      //   ],
      // },
      // {
      //   name: "Tables",
      //   icon: TableIcon,
      //   subItems: [{ name: "Basic Tables", path: "/basic-tables", pro: false },
      //     { name: "Basic Tables1", path: "/basic-tables1", pro: false }],
      // },
      // {
      //   name: "Pages",
      //   icon: PageIcon,
      //   subItems: [
      //     { name: "Black Page", path: "/blank", pro: false },
      //     { name: "404 Page", path: "/error-404", pro: false },
      //   ],
      // },
    ],
  },
  // {
  //   title: t('sidebar.group.ai'),
  //   items: [
  //     {
  //       icon: PieChartIcon,
  //       name: t('sidebar.items.beerSalesForecast'),
  //       path: "/beer-sales-forecast",
  //     },
  //     {
  //       icon: BoxCubeIcon,
  //       name: t('sidebar.items.aiOrderAssistant'),
  //       path: "/ai-order-assistant",
  //     },
  //     {
  //       icon: ChatIcon,
  //       name: t('sidebar.items.aiAssistant'),
  //       path: "/ai-assistant",
  //     },
  //   ],
  // },
  // {
  //   title: "Others",
  //   items: [
  //     {
  //       icon: PieChartIcon,
  //       name: "Charts",
  //       subItems: [
  //         { name: "Line Chart", path: "/line-chart", pro: false },
  //         { name: "Bar Chart", path: "/bar-chart", pro: false },
  //       ],
  //     },
  //     {
  //       icon: BoxCubeIcon,
  //       name: "Ui Elements",
  //       subItems: [
  //         { name: "Alerts", path: "/alerts", pro: false },
  //         { name: "Avatars", path: "/avatars", pro: false },
  //         { name: "Badge", path: "/badge", pro: false },
  //         { name: "Buttons", path: "/buttons", pro: false },
  //         { name: "Images", path: "/images", pro: false },
  //         { name: "Videos", path: "/videos", pro: false },
  //       ],
  //     },
  //     {
  //       icon: PlugInIcon,
  //       name: "Authentication",
  //       subItems: [
  //         { name: "Signin", path: "/signin", pro: false },
  //         { name: "Signup", path: "/signup", pro: false },
  //       ],
  //     },
  //     // ... Add other menu items here
  //   ],
  // },
]);

const isActive = (path) => route.path === path;

const toggleSubmenu = (groupIndex, itemIndex) => {
  const key = `${groupIndex}-${itemIndex}`;
  openSubmenu.value = openSubmenu.value === key ? null : key;
};

const toggleSubmenuChild = (groupIndex, itemIndex, subIndex) => {
  const key = `${groupIndex}-${itemIndex}-${subIndex}`;
  openSubmenuChild.value = openSubmenuChild.value === key ? null : key;
};

const isSubItemActive = (subItem) => {
  if (subItem?.path) return isActive(subItem.path);
  if (subItem?.subItems) {
    return subItem.subItems.some((child) => child.path && isActive(child.path));
  }
  return false;
};

const isAnySubmenuRouteActive = computed(() => {
  return menuGroups.value.some((group) =>
    group.items.some(
      (item) =>
        item.subItems && item.subItems.some((subItem) => isSubItemActive(subItem))
    )
  );
});

const isSubmenuOpen = (groupIndex, itemIndex) => {
  const key = `${groupIndex}-${itemIndex}`;
  return (
    openSubmenu.value === key ||
    (isAnySubmenuRouteActive.value &&
      menuGroups.value[groupIndex].items[itemIndex].subItems?.some((subItem) =>
        isSubItemActive(subItem)
      ))
  );
};

const isSubmenuChildOpen = (groupIndex, itemIndex, subIndex) => {
  const key = `${groupIndex}-${itemIndex}-${subIndex}`;
  const subItem = menuGroups.value[groupIndex].items[itemIndex].subItems?.[subIndex];
  if (!subItem?.subItems) return false;
  return (
    openSubmenuChild.value === key ||
    subItem.subItems.some((child) => child.path && isActive(child.path))
  );
};

const startTransition = (el) => {
  el.style.height = "auto";
  const height = el.scrollHeight;
  el.style.height = "0px";
  el.offsetHeight; // force reflow
  el.style.height = height + "px";
};

const endTransition = (el) => {
  el.style.height = "";
};
</script>
