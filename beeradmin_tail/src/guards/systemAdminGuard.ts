import type { RouteLocationNormalized } from 'vue-router'
import { supabase } from '@/lib/supabase'
import { useAuthStore } from '@/stores/auth'

async function isCurrentUserSystemAdmin() {
  const { data, error } = await supabase.auth.getUser()
  if (error || !data.user?.id) return false
  return Boolean(
    data.user.app_metadata?.is_system_admin ||
    data.user.app_metadata?.system_role,
  )
}

export async function systemAdminGuard(to: RouteLocationNormalized) {
  const auth = useAuthStore()

  if (auth.accessToken === null && auth.userId === null) {
    await auth.bootstrap()
  }

  if (!auth.isAuthed) {
    return { path: '/signin', query: { redirect: to.fullPath } }
  }

  if (auth.isSystemAdmin) return true

  const allowed = await isCurrentUserSystemAdmin()
  if (!allowed) {
    return { path: '/error-404' }
  }

  return true
}
