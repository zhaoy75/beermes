import { defineStore } from 'pinia'
import { getCurrentTenantContext, isCurrentUserTenantAdmin } from '@/modules/tenant/services/tenantContext'

type TenantSessionState = {
  tenantId: string | null
  isTenantAdmin: boolean
}

export const useTenantSessionStore = defineStore('tenantSession', {
  state: (): TenantSessionState => ({
    tenantId: null,
    isTenantAdmin: false,
  }),
  actions: {
    async refresh() {
      const ctx = await getCurrentTenantContext()
      this.tenantId = ctx.tenantId
      this.isTenantAdmin = ctx.tenantId ? await isCurrentUserTenantAdmin() : false
    },
  },
})
