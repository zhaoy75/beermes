import { supabase } from '@/lib/supabase'

export type SystemAdminTenantSummary = {
  id: string
  name: string
  tenantCode: string | null
  createdAt: string | null
  status: 'active' | 'suspended' | 'voided'
  ownerCount: number
  userCount: number
}

export type SystemAdminTenantMember = {
  userId: string
  role: 'owner' | 'admin' | 'editor' | 'viewer'
  createdAt: string | null
  email: string
  displayName: string
}

export type SystemAdminInvitation = {
  id: string
  email: string
  role: 'owner' | 'admin' | 'editor' | 'viewer'
  status: 'invited' | 'accepted' | 'revoked' | 'expired'
  invitedAt: string | null
}

export type SystemAdminTenantDetail = {
  tenant: SystemAdminTenantSummary
  members: SystemAdminTenantMember[]
  invitations: SystemAdminInvitation[]
  featurePermissions: Array<{ key: string; enabled: boolean }>
  settings: {
    defaultLocale: string
    timezone: string
    masterDataProfileKey: string | null
  }
  auditLogs: Array<{
    id: string
    timestamp: string
    actor: string
    action: string
    result: 'success' | 'failure'
  }>
}

type TenantRow = {
  id: string
  name: string
  created_at: string | null
}

type TenantMemberRow = {
  tenant_id: string
  user_id: string
  role: 'owner' | 'admin' | 'editor' | 'viewer'
  created_at: string | null
}

type TenantInvitationRow = {
  id: string
  tenant_id: string
  email: string
  role: 'owner' | 'admin' | 'editor' | 'viewer'
  status: 'invited' | 'accepted' | 'revoked' | 'expired'
  invited_at: string | null
}

function deriveTenantSummary(tenant: TenantRow, members: TenantMemberRow[]): SystemAdminTenantSummary {
  return {
    id: tenant.id,
    name: tenant.name,
    tenantCode: null,
    createdAt: tenant.created_at,
    status: 'active',
    ownerCount: members.filter((item) => item.role === 'owner').length,
    userCount: members.length,
  }
}

async function resolveUserEmail(userId: string) {
  const { data } = await supabase.auth.getUser()
  if (data.user?.id === userId) return data.user.email ?? ''
  return ''
}

export async function listSystemAdminTenants() {
  const { data: tenantData, error: tenantError } = await supabase
    .from('tenants')
    .select('id, name, created_at')
    .order('created_at', { ascending: false })
  if (tenantError) throw tenantError

  const { data: memberData, error: memberError } = await supabase
    .from('tenant_members')
    .select('tenant_id, user_id, role, created_at')
  if (memberError) throw memberError

  const members = (memberData ?? []) as TenantMemberRow[]
  return ((tenantData ?? []) as TenantRow[]).map((tenant) =>
    deriveTenantSummary(
      tenant,
      members.filter((item) => item.tenant_id === tenant.id),
    ),
  )
}

export async function getSystemAdminTenantDetail(tenantId: string): Promise<SystemAdminTenantDetail> {
  const { data: tenantData, error: tenantError } = await supabase
    .from('tenants')
    .select('id, name, created_at')
    .eq('id', tenantId)
    .maybeSingle()
  if (tenantError) throw tenantError
  if (!tenantData) throw new Error('Tenant not found.')

  const { data: memberData, error: memberError } = await supabase
    .from('tenant_members')
    .select('tenant_id, user_id, role, created_at')
    .eq('tenant_id', tenantId)
  if (memberError) throw memberError

  let invitations: SystemAdminInvitation[] = []
  const { data: invitationData, error: invitationError } = await supabase
    .from('tenant_invitations')
    .select('id, tenant_id, email, role, status, invited_at')
    .eq('tenant_id', tenantId)
    .in('status', ['invited', 'accepted', 'revoked', 'expired'])

  if (!invitationError) {
    invitations = ((invitationData ?? []) as TenantInvitationRow[]).map((row) => ({
      id: row.id,
      email: row.email,
      role: row.role,
      status: row.status,
      invitedAt: row.invited_at,
    }))
  }

  const members = await Promise.all(
    ((memberData ?? []) as TenantMemberRow[]).map(async (row) => {
      const email = await resolveUserEmail(row.user_id)
      return {
        userId: row.user_id,
        role: row.role,
        createdAt: row.created_at,
        email,
        displayName: email ? email.split('@')[0] : `user-${row.user_id.slice(0, 8)}`,
      }
    }),
  )

  return {
    tenant: deriveTenantSummary(tenantData as TenantRow, (memberData ?? []) as TenantMemberRow[]),
    members,
    invitations,
    featurePermissions: [
      { key: 'production', enabled: true },
      { key: 'inventory', enabled: true },
      { key: 'liquor-tax', enabled: true },
      { key: 'ai-tools', enabled: false },
    ],
    settings: {
      defaultLocale: 'ja',
      timezone: 'Asia/Tokyo',
      masterDataProfileKey: null,
    },
    auditLogs: [],
  }
}
