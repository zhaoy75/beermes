import { supabase } from '@/lib/supabase'

export async function getCurrentTenantContext() {
  const { data, error } = await supabase.auth.getUser()
  if (error || !data.user?.id) {
    throw error ?? new Error('Unable to resolve current user.')
  }

  return {
    userId: data.user.id,
    tenantId: typeof data.user.app_metadata?.tenant_id === 'string'
      ? data.user.app_metadata.tenant_id
      : null,
    isSystemAdmin: Boolean(
      data.user.app_metadata?.is_system_admin || data.user.app_metadata?.system_role,
    ),
  }
}

export async function isCurrentUserTenantAdmin() {
  const ctx = await getCurrentTenantContext()
  if (!ctx.tenantId) return false

  const { data, error } = await supabase
    .from('tenant_members')
    .select('role')
    .eq('tenant_id', ctx.tenantId)
    .eq('user_id', ctx.userId)
    .maybeSingle()

  if (error || !data) return false
  return data.role === 'owner' || data.role === 'admin'
}
