import { createRouter, createWebHistory } from 'vue-router'
import { systemAdminGuard } from '@/guards/systemAdminGuard'
import { tenantGuard } from '@/guards/tenantGuard'
import { DEVELOPMENT_MODE_ENABLED } from '@/lib/devMode'
import { systemRoutes } from '@/router/system-routes'
import { tenantRoutes } from '@/router/tenant-routes'

const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  scrollBehavior(_to, _from, savedPosition) {
    return savedPosition || { left: 0, top: 0 }
  },
  routes: [
    ...tenantRoutes,
    ...systemRoutes,
  ],
})

router.addRoute({ path: '/:pathMatch(.*)*', redirect: '/error-404' })

router.beforeEach(async (to) => {
  if (to.meta.requiresDevelopmentMode === true && !DEVELOPMENT_MODE_ENABLED) {
    return '/error-404'
  }

  if (to.meta.requiresSystemAdmin === true) {
    return systemAdminGuard(to)
  }

  return tenantGuard(to)
})

export default router
