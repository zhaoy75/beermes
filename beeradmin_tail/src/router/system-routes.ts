import type { RouteRecordRaw } from 'vue-router'

export const systemRoutes: RouteRecordRaw[] = [
  {
    path: '/system-admin',
    name: 'SystemAdminHome',
    component: () => import('@/modules/system-admin/pages/SystemAdminHomePage.vue'),
    meta: {
      title: 'System Admin',
      requiresAuth: true,
      requiresSystemAdmin: true,
    },
  },
  {
    path: '/system-admin/tenants',
    name: 'SystemAdminTenants',
    component: () => import('@/modules/system-admin/pages/SystemAdminTenantsPage.vue'),
    meta: {
      title: 'System Admin Tenants',
      requiresAuth: true,
      requiresSystemAdmin: true,
    },
  },
  {
    path: '/system-admin/tenants/:tenantId',
    name: 'SystemAdminTenantDetail',
    component: () => import('@/modules/system-admin/pages/SystemAdminTenantDetailPage.vue'),
    meta: {
      title: 'System Admin Tenant Detail',
      requiresAuth: true,
      requiresSystemAdmin: true,
    },
  },
  {
    path: '/system-admin/audit',
    name: 'SystemAdminAudit',
    component: () => import('@/modules/system-admin/pages/SystemAdminAuditPage.vue'),
    meta: {
      title: 'System Admin Audit',
      requiresAuth: true,
      requiresSystemAdmin: true,
    },
  },
]
