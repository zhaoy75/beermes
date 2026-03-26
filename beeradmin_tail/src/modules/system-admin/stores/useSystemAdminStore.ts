import { defineStore } from 'pinia'
import {
  getSystemAdminTenantDetail,
  listSystemAdminTenants,
  type SystemAdminTenantDetail,
  type SystemAdminTenantSummary,
} from '@/modules/system-admin/services/systemAdminService'

type SystemAdminState = {
  tenants: SystemAdminTenantSummary[]
  currentTenant: SystemAdminTenantDetail | null
  loading: boolean
  error: string
}

export const useSystemAdminStore = defineStore('systemAdmin', {
  state: (): SystemAdminState => ({
    tenants: [],
    currentTenant: null,
    loading: false,
    error: '',
  }),
  actions: {
    async loadTenants() {
      this.loading = true
      this.error = ''
      try {
        this.tenants = await listSystemAdminTenants()
      } catch (err) {
        this.error = err instanceof Error ? err.message : 'Failed to load tenants.'
      } finally {
        this.loading = false
      }
    },

    async loadTenantDetail(tenantId: string) {
      this.loading = true
      this.error = ''
      try {
        this.currentTenant = await getSystemAdminTenantDetail(tenantId)
      } catch (err) {
        this.currentTenant = null
        this.error = err instanceof Error ? err.message : 'Failed to load tenant detail.'
      } finally {
        this.loading = false
      }
    },
  },
})
