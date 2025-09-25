import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  scrollBehavior(to, from, savedPosition) {
    return savedPosition || { left: 0, top: 0 }
  },
  routes: [
    // {
    //   path: '/',
    //   name: 'Ecommerce',
    //   component: () => import('../views/Ecommerce.vue'),
    //   meta: {
    //     title: 'eCommerce Dashboard',
    //     requiresAuth: true ,
    //   },
    // },
    {
      path: '/',
      name: '概要',
      component: () => import('../views/pages/BeerDash.vue'),
      meta: {
        title: 'eCommerce Dashboard',
        requiresAuth: true ,
      },
    },
    {
      path: '/recipeEdit/:recipeId/:versionId?',
      name: 'レシピ編集',
      component: () => import('../views/Pages/RecipeEdit.vue'),
      meta: {
        title: 'レシピ編集',
        requiresAuth: true ,
      },
    },
    {
      path: '/recipeList',
      name: 'レシピ一覧',
      component: () => import('../views/Pages/RecipeList.vue'),
      meta: {
        title: 'レシピ一覧',
        requiresAuth: true ,
      },
    },

    {
      path: '/lots',
      name: 'lots',
      component: () => import('../views/Pages/LotList.vue'),
      meta: {
        title: 'Lot Management',
        requiresAuth: true ,
      },
    },
    {
      path: '/lots/:lotId',
      name: 'lotEdit',
      component: () => import('../views/Pages/LotEdit.vue'),
      meta: {
        title: 'Lot Edit',
        requiresAuth: true ,
      },
    },
    {
      path: '/waste',
      name: 'waste',
      component: () => import('../views/Pages/WasteList.vue'),
      meta: {
        title: 'Waste Management',
        requiresAuth: true ,
      },
    },
    {
      path: '/calendar',
      name: 'Calendar',
      component: () => import('../views/Others/Calendar.vue'),
      meta: {
        title: 'Calendar',
        requiresAuth: true ,
      },
    },
    {
      path: '/taxMaster',
      name: '酒税',
      component: () => import('../views/pages/TaxMaster.vue'),
      meta: {
        title: 'Tax Maintenance',
        requiresAuth: true ,
      },
    },
    {
      path: '/taxYearSummary',
      name: 'TaxYearSummary',
      component: () => import('../views/Pages/TaxYearSummary.vue'),
      meta: {
        title: 'Tax Year Summary',
        requiresAuth: true ,
      },
    },
    {
      path: '/siteMovements',
      name: 'SiteMovements',
      component: () => import('../views/Pages/SiteMovement.vue'),
      meta: {
        title: 'Site Movements',
        requiresAuth: true ,
      },
    },
    {
      path: '/uomMaster',
      name: '単位マスタ',
      component: () => import('../views/pages/UomMaster.vue'),
      meta: {
        title: 'Unit of Measure',
        requiresAuth: true ,
      },
    },
    {
      path: '/rawMaterialReceipts',
      name: 'RawMaterialReceipts',
      component: () => import('../views/Pages/RawMaterialReceipts.vue'),
      meta: {
        title: 'Raw Material Receipts',
        requiresAuth: true ,
      },
    },
    {
      path: '/rawMaterialInventory',
      name: 'RawMaterialInventory',
      component: () => import('../views/Pages/RawMaterialInventory.vue'),
      meta: {
        title: 'Raw Material Inventory',
        requiresAuth: true ,
      },
    },
    {
      path: '/tankMaintenance',
      name: 'TankMaintenance',
      component: () => import('../views/Pages/TankMaintenance.vue'),
      meta: {
        title: 'Tank Maintenance',
        requiresAuth: true ,
      },
    },
    {
      path: '/categoryMaster',
      name: 'カテゴリマスタ',
      component: () => import('../views/pages/CategoryMaster.vue'),
      meta: {
        title: 'Category Master',
        requiresAuth: true ,
      },
    },
    {
      path: '/siteTypeMaster',
      name: 'サイト種別マスタ',
      component: () => import('../views/Pages/SiteTypeMaster.vue'),
      meta: {
        title: 'Site Type Master',
        requiresAuth: true ,
      },
    },
    {
      path: '/siteMaster',
      name: 'サイトマスタ',
      component: () => import('../views/Pages/SiteMaster.vue'),
      meta: {
        title: 'Site Master',
        requiresAuth: true ,
      },
    },
    {
      path: '/lotYieldSummary',
      name: 'LotYieldSummary',
      component: () => import('../views/Pages/LotYieldSummary.vue'),
      meta: {
        title: 'Lot Yield Summary',
        requiresAuth: true ,
      },
    },
    {
      path: '/beerPackageCategory',
      name: 'beerPackageCategory',
      component: () => import('../views/Pages/BeerPackageCategory.vue'),
      meta: {
        title: 'Beer Package Category',
        requiresAuth: true ,
      },
    },
    {
      path: '/MaterialMaster',
      name: '原材料マスタ',
      component: () => import('../views/pages/MaterialMaster.vue'),
      meta: {
        title: 'Material Master',
        requiresAuth: true ,
      },
    },

    {
      path: '/profile',
      name: 'Profile',
      component: () => import('../views/Others/UserProfile.vue'),
      meta: {
        title: 'Profile',
        requiresAuth: true ,
      },
    },
    {
      path: '/form-elements',
      name: 'Form Elements',
      component: () => import('../views/Forms/FormElements.vue'),
      meta: {
        title: 'Form Elements',
        requiresAuth: true ,
      },
    },
    {
      path: '/basic-tables',
      name: 'Basic Tables',
      component: () => import('../views/Tables/BasicTables.vue'),
      meta: {
        title: 'Basic Tables',
        requiresAuth: true ,
      },
    },
    {
      path: '/basic-tables1',
      name: 'Basic Tables1',
      component: () => import('../views/Tables/BasicTables1.vue'),
      meta: {
        title: 'Basic Tables1',
        requiresAuth: true ,
      },
    },
    {
      path: '/line-chart',
      name: 'Line Chart',
      component: () => import('../views/Chart/LineChart/LineChart.vue'),
      meta: {
        title: 'Line Chart',
        requiresAuth: true ,
      },
    },
    {
      path: '/bar-chart',
      name: 'Bar Chart',
      component: () => import('../views/Chart/BarChart/BarChart.vue'),
      meta: {
        title: 'Bar Chart',
        requiresAuth: true ,
      },
    },
    {
      path: '/alerts',
      name: 'Alerts',
      component: () => import('../views/UiElements/Alerts.vue'),
      meta: {
        title: 'Alerts',
        requiresAuth: true ,
      },
    },
    {
      path: '/avatars',
      name: 'Avatars',
      component: () => import('../views/UiElements/Avatars.vue'),
      meta: {
        title: 'Avatars',
        requiresAuth: true ,
      },
    },
    {
      path: '/badge',
      name: 'Badge',
      component: () => import('../views/UiElements/Badges.vue'),
      meta: {
        title: 'Badge',
        requiresAuth: true ,
      },
    },

    {
      path: '/buttons',
      name: 'Buttons',
      component: () => import('../views/UiElements/Buttons.vue'),
      meta: {
        title: 'Buttons',
        requiresAuth: true ,
      },
    },


    {
      path: '/images',
      name: 'Images',
      component: () => import('../views/UiElements/Images.vue'),
      meta: {
        title: 'Images',
        requiresAuth: true ,
      },
    },
    {
      path: '/videos',
      name: 'Videos',
      component: () => import('../views/UiElements/Videos.vue'),
      meta: {
        title: 'Videos',
        requiresAuth: true ,
      },
    },
    {
      path: '/blank',
      name: 'Blank',
      component: () => import('../views/Pages/BlankPage.vue'),
      meta: {
        title: 'Blank',
        requiresAuth: true ,
      },
    },

    {
      path: '/error-404',
      name: '404 Error',
      component: () => import('../views/Errors/FourZeroFour.vue'),
      meta: {
        title: '404 Error',
      },
    },

    {
      path: '/signin',
      name: 'Signin',
      component: () => import('../views/Auth/Signin.vue'),
      meta: {
        title: 'Signin',
      },
    },
    {
      path: '/signup',
      name: 'Signup',
      component: () => import('../views/Auth/Signup.vue'),
      meta: {
        title: 'Signup',
      },
    },
  ],
})

router.addRoute({ path: '/:pathMatch(.*)*', redirect: '/error-404' })

export default router

// router.beforeEach((to, from, next) => {
//   document.title = `Vue.js ${to.meta.title} | TailAdmin - Vue.js Tailwind CSS Dashboard Template`
//   next()
// })

import { useAuthStore } from '../stores/auth'

router.beforeEach(async (to) => {
  const auth = useAuthStore()

  // If coming fresh (no bootstrap yet), ensure state mirrors Supabase
  if (auth.accessToken === null && auth.userId === null) {
    await auth.bootstrap()
  }

  const isPublic = to.meta.public === true
  if (to.meta.requiresAuth && !auth.isAuthed && !isPublic) {
    return { path: '/signin', query: { redirect: to.fullPath } }
  }

  // If already authed, keep them out of /login
  if (to.path === '/signin' && auth.isAuthed) {
    return { path: (to.query.redirect as string) ?? '/' }
  }
})
