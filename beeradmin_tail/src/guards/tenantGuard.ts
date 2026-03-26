import type { RouteLocationNormalized } from 'vue-router'
import { useAuthStore } from '@/stores/auth'
import { isCurrentUserTenantAdmin } from '@/modules/tenant/services/tenantContext'

export async function tenantGuard(to: RouteLocationNormalized) {
  const auth = useAuthStore()

  if (auth.accessToken === null && auth.userId === null) {
    await auth.bootstrap()
  }

  const isPublic = to.meta.public === true
  if (to.meta.requiresAuth && !auth.isAuthed && !isPublic) {
    return { path: '/signin', query: { redirect: to.fullPath } }
  }

  if (to.meta.requiresAdmin === true) {
    const allowed = await isCurrentUserTenantAdmin()
    if (!allowed) {
      return { path: '/error-404' }
    }
  }

  if (to.path === '/signin' && auth.isAuthed) {
    return { path: (to.query.redirect as string) ?? '/' }
  }

  return true
}
