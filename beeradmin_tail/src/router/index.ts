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
      component: () => import('../views/pages/BatchList.vue'),
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
      name: 'レシピ管理',
      component: () => import('../views/Pages/RecipeList.vue'),
      meta: {
        title: 'レシピ管理',
        requiresAuth: true ,
      },
    },

    {
      path: '/batches',
      name: 'batches',
      component: () => import('../views/Pages/BatchList.vue'),
      meta: {
        title: 'Batch Management',
        requiresAuth: true ,
      },
    },
    {
      path: '/batches/:batchId',
      name: 'batchEdit',
      component: () => import('../views/Pages/BatchEdit.vue'),
      meta: {
        title: 'Batch Edit',
        requiresAuth: true ,
      },
    },
    {
      path: '/batches/:batchId/packing',
      name: 'batchPacking',
      component: () => import('../views/Pages/BatchPacking.vue'),
      meta: {
        title: 'Batch Packing',
        requiresAuth: true ,
      },
    },
    {
      path: '/batches/:batchId/lot-dag',
      name: 'batchLotDag',
      component: () => import('../views/Pages/BatchLotDag.vue'),
      meta: {
        title: 'Batch Lot DAG',
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
      path: '/beer-sales-forecast',
      name: 'BeerSalesForecast',
      component: () => import('../views/Pages/BeerSalesForecast.vue'),
      meta: {
        title: 'AI Sales Forecast',
        requiresAuth: true ,
      },
    },
    {
      path: '/ai-assistant',
      name: 'AIAssistant',
      component: () => import('../views/Pages/AIAssistant.vue'),
      meta: {
        title: 'AI Assistant',
        requiresAuth: true ,
      },
    },
    {
      path: '/ai-order-assistant',
      name: 'AIOrderAssistant',
      component: () => import('../views/Pages/AIOrderAssistant.vue'),
      meta: {
        title: 'AI Order Assistant',
        requiresAuth: true ,
      },
    },
    {
      path: '/alcoholTypeMaster',
      name: 'alcoholTypeMaster',
      component: () => import('../views/Pages/AlcoholTypeMaster.vue'),
      meta: {
        title: 'Alcohol Type Master',
        requiresAuth: true ,
      },
    },
    {
      path: '/alcoholTaxMaster',
      name: 'alcoholTaxMaster',
      component: () => import('../views/Pages/AlcoholTaxMaster.vue'),
      meta: {
        title: 'Alcohol Tax Master',
        requiresAuth: true ,
      },
    },
    {
      path: '/materialClassMaster',
      name: 'materialClassMaster',
      component: () => import('../views/Pages/MaterialClassMaster.vue'),
      meta: {
        title: 'Material Class Master',
        requiresAuth: true ,
      },
    },
    {
      path: '/materialTypeMaster',
      name: 'materialTypeMaster',
      component: () => import('../views/Pages/MaterialTypeMaster.vue'),
      meta: {
        title: 'Material Type Master',
        requiresAuth: true ,
      },
    },
    {
      path: '/attrDefMaster',
      name: 'attrDefMaster',
      component: () => import('../views/Pages/AttrDefMaster.vue'),
      meta: {
        title: 'Attribute Definition Master',
        requiresAuth: true ,
      },
    },
    {
      path: '/attrSetMaster',
      name: 'attrSetMaster',
      component: () => import('../views/Pages/AttrSetMaster.vue'),
      meta: {
        title: 'Attribute Set Master',
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
      path: '/taxReports',
      name: 'TaxReport',
      component: () => import('../views/Pages/TaxReport.vue'),
      meta: {
        title: 'Tax Report',
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
      path: '/producedBeer',
      name: 'ProducedBeer',
      component: () => import('../views/Pages/ProducedBeer.vue'),
      meta: {
        title: 'Produced Craft Beer',
        requiresAuth: true ,
      },
    },
    {
      path: '/producedBeerMovement',
      name: 'ProducedBeerMovement',
      component: () => import('../views/Pages/ProducedBeerMovementEdit.vue'),
      meta: {
        title: 'Produced Beer Movement',
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
      path: '/equipmentMaster',
      name: '設備マスタ',
      component: () => import('../views/Pages/EquipmentMaster.vue'),
      meta: {
        title: 'Equipment Master',
        requiresAuth: true ,
      },
    },
    {
      path: '/batchYieldSummary',
      name: 'BatchYieldSummary',
      component: () => import('../views/Pages/BatchYieldSummary.vue'),
      meta: {
        title: 'Batch Yield Summary',
        requiresAuth: true ,
      },
    },
    {
      path: '/packageMaster',
      name: 'packageMaster',
      component: () => import('../views/Pages/PackageMaster.vue'),
      meta: {
        title: 'Package Master',
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
      path: '/users',
      name: 'User Management',
      component: () => import('../views/Pages/UserManagement.vue'),
      meta: {
        title: 'User Management',
        requiresAuth: true ,
      },
    },
    {
      path: '/change-password',
      name: 'Change Password',
      component: () => import('../views/Others/ChangePassword.vue'),
      meta: {
        title: 'Change Password',
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
