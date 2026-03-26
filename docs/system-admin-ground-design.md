# System Admin Ground Design

## Purpose
- Define the ground design for a System Admin feature in the same repository and application stack.
- Establish a clear separation between tenant-scoped administration and system-scoped administration.
- Provide a stable high-level design that can be used later for detailed specifications and implementation tasks.

## Background
- The current application is tenant-aware and uses Supabase as the backend platform.
- Existing access patterns are centered on a current `tenant_id` and tenant membership.
- System Admin must operate above tenant scope and must not depend on ordinary tenant-admin authorization rules.

## Goals
- Add a system-scoped administration capability for managing tenants.
- Keep the System Admin feature in the same codebase as the existing application.
- Separate System Admin concerns from tenant application concerns in routing, layout, permissions, services, and audit handling.
- Store tenant-management data and audit logs in Supabase with a clear table design.

## Non-Goals
- Detailed screen specification for every dialog and field.
- Full API contract and request/response detail.
- Actual implementation of database schema, Edge Functions, or frontend pages.
- General business-master maintenance for day-to-day tenant operations beyond the limited admin scope defined here.

## Design Principles
- System scope and tenant scope must be explicitly separated.
- Destructive actions must be guarded by stronger confirmation and full audit logging.
- System Admin write operations should execute on trusted backend paths, not direct client-side table writes.
- The first release should be intentionally narrow and operationally safe.
- Audit data should be append-only and suitable for later compliance review.

## Functional Scope

### 1. Tenant Management
System Admin should support the following core tenant operations:

- Create tenant
- Suspend or stop tenant
- Void tenant
- Manage tenant users
- Manage tenant function permissions
- Manage limited tenant master data

### 2. Audit Log
System Admin should be able to review tenant-management activity logs with at least:

- who performed the action
- what action was performed
- which tenant was targeted
- when the action occurred
- whether the action succeeded or failed

## Recommended Functional Definition

### Tenant Creation
Tenant creation should include more than inserting a single row. The logical action should be treated as an onboarding workflow:

- create tenant record
- assign lifecycle status
- assign initial owner user
- assign default permission bundle
- seed required initial master data
- write one audit event representing the full operation

### Tenant Lifecycle Control
Use explicit lifecycle states instead of only a binary active/inactive approach.

Recommended states:
- `active`: normal operation
- `suspended`: login and operational use restricted; reversible state
- `voided`: retired tenant; not expected to resume ordinary operation

Recommendation:
- Prefer `suspended` for temporary stop.
- Reserve `voided` for administrative retirement or invalid tenants.

### Tenant User Management
System Admin should be able to:
- assign the initial owner during tenant creation
- view tenant membership summary
- add or remove tenant users
- adjust tenant roles when needed
- resend or revoke invitations when required

Recommendation:
- Keep tenant-local user operations aligned with existing tenant membership concepts.
- System Admin should override tenant boundaries through backend-controlled operations, not frontend direct writes.

### Tenant Function Permission Management
Tenant function permission management should be treated as tenant entitlements, not the same thing as user role management.

Examples:
- AI modules enabled or disabled
- tax-report module enabled or disabled
- production module enabled or disabled
- feature rollout by tenant plan or contract

Recommendation:
- Manage function permissions at tenant level through a dedicated permission model.
- Avoid mixing feature entitlement flags into ordinary user profile metadata.

### Tenant Master Data Management
This area should be deliberately narrow in the first release.

Recommended v1 scope:
- bootstrap master data templates
- emergency correction of critical tenant configuration
- reference data needed for system-level recovery or support

Not recommended for v1:
- routine business maintenance that tenant admins already own
- broad cross-tenant editing of all master tables

## Architecture Overview

### 1. Application Boundary
System Admin should exist in the same frontend codebase, but with separate application structure:

- separate route tree, such as `/system-admin/...`
- separate layout
- separate menu definition
- separate permission checks
- separate service modules
- separate audit policies

This separation reduces accidental reuse of tenant-admin logic in system-admin screens.

### 1.1 Target Frontend Folder Structure
Recommended target structure for this repository:

```text
src/
  modules/
    tenant/
      pages/
      components/
      services/
      stores/
    system-admin/
      pages/
      components/
      services/
      stores/
  router/
    tenant-routes.ts
    system-routes.ts
  layouts/
    TenantLayout.vue
    SystemAdminLayout.vue
  guards/
    tenantGuard.ts
    systemAdminGuard.ts
```

Recommended interpretation:
- `modules/tenant/*`: tenant-scoped business application logic
- `modules/system-admin/*`: system-scoped administration logic
- `router/tenant-routes.ts`: tenant route tree
- `router/system-routes.ts`: system-admin route tree
- `layouts/TenantLayout.vue`: tenant visual shell
- `layouts/SystemAdminLayout.vue`: system-admin visual shell
- `guards/tenantGuard.ts`: tenant auth and tenant-admin enforcement
- `guards/systemAdminGuard.ts`: system-scope enforcement

Migration note:
- existing tenant pages can remain in their current locations during transition
- route splitting, layout separation, and guard separation should be introduced first
- page-by-page relocation into `modules/tenant/pages` can be done incrementally

### 2. Authorization Boundary
Do not model System Admin as a tenant role.

Recommendation:
- introduce a system-scope role model, separate from `tenant_members`
- optionally cache system scope in JWT/app metadata for fast client checks
- always re-validate system-admin authority on trusted backend operations

Reason:
- tenant roles answer "what can this user do inside a tenant"
- system scope answers "can this user administrate tenants at platform level"

### 3. Backend Execution Model
System Admin mutations should use trusted backend execution paths.

Recommended options:
- Supabase Edge Functions for create/update administrative actions
- SQL RPC functions for narrowly scoped database procedures

Do not rely on direct client writes for:
- cross-tenant updates
- tenant lifecycle actions
- system audit creation
- privileged user-management actions

### 4. Audit Model
Audit recording should be part of the write workflow, not an optional side effect.

Recommendation:
- every system-admin mutation writes an audit event in the same logical transaction boundary where possible
- if full transactional coupling is not feasible, the action service must fail closed or clearly mark audit failure

## Recommended Supabase Data Design

### Core Existing Concept
The current repository already has tenant-centric structures such as:
- `tenants`
- `tenant_members`
- `tenant_invitations`

System Admin design should extend this model rather than replace it.

### Recommended Tables

#### `system_user_roles`
Purpose:
- define which users have system-scope access

Suggested columns:
- `user_id`
- `system_role`
- `status`
- `granted_by`
- `granted_at`
- `revoked_at`
- `meta`

Suggested role examples:
- `system_admin`
- `system_operator`
- `system_auditor`

#### `tenants`
Extend the tenant record to support lifecycle management.

Suggested additional columns:
- `tenant_code`
- `status`
- `created_by`
- `suspended_at`
- `suspended_reason`
- `voided_at`
- `voided_reason`
- `meta`

#### `tenant_feature_permissions`
Purpose:
- manage enabled functions per tenant

Suggested columns:
- `tenant_id`
- `feature_key`
- `enabled`
- `granted_by`
- `granted_at`
- `expires_at`
- `meta`

This table should represent tenant entitlements, not per-user permission overrides.

#### `tenant_bootstrap_settings`
Purpose:
- store setup decisions applied at tenant creation time

Suggested examples:
- default locale
- enabled modules
- default site type template
- default tax or regulatory template

This may be implemented either as a dedicated table or as structured metadata attached to tenant setup operations.

#### `system_admin_audit_logs`
Purpose:
- store append-only system-admin activity logs

Suggested columns:
- `id`
- `occurred_at`
- `actor_user_id`
- `actor_email`
- `action_type`
- `target_tenant_id`
- `target_entity_type`
- `target_entity_id`
- `request_id`
- `result`
- `reason`
- `before_data`
- `after_data`
- `meta`

Recommendation:
- keep audit logs append-only
- avoid updates except for internal retention or archival handling

## Access Control Design

### Frontend Access
System Admin pages should only be visible and routable for users with system scope.

Recommended checks:
- route meta flag such as `requiresSystemAdmin`
- system-admin menu visibility guard
- dedicated system-admin entry point after login when relevant

### Backend Access
Every system-admin mutation must validate the caller against system-scope authorization from a trusted backend path.

Recommendation:
- never trust only a frontend route guard
- never trust only a cached frontend store flag
- validate the caller on every privileged operation

### Separation from Tenant Admin
Do not reuse tenant-admin checks for system-admin pages.

Reason:
- tenant admin is scoped to one tenant
- system admin operates across tenants
- mixing the two creates authorization ambiguity and future defects

## Audit Logging Design

### Required Audit Events
At minimum, log events for:
- tenant created
- tenant suspended
- tenant reactivated
- tenant voided
- tenant owner assigned or changed
- tenant user added, removed, or role changed
- tenant function permission changed
- tenant master data admin change

### Required Audit Attributes
Each audit event should include:
- actor identity
- action type
- tenant identity
- target entity identity
- event time
- success or failure result
- reason or note where relevant

### Recommended Audit Behavior
- store both summary fields and structured payload data
- capture old and new values for material changes
- avoid logging secrets, tokens, or password reset content
- include correlation/request id to tie UI action and backend log together

## UI Ground Design

### Overall Information Architecture
Do not build the feature as one large page. Use a dedicated system-admin workspace with clear navigation.

Recommended top-level pages:
- `System Admin Home`
- `Tenant Management`
- `Audit Log`

Recommended tenant detail sections:
- `Overview`
- `Users`
- `Permissions`
- `Master Data`
- `Audit`

### Route and Layout Direction
Recommended route pattern:
- `/system-admin`
- `/system-admin/tenants`
- `/system-admin/tenants/:tenantId`
- `/system-admin/audit`

Recommended layout characteristics:
- separate sidebar/menu from tenant application
- persistent system-admin context header
- visible distinction from ordinary tenant pages

### Tenant Management Page
Recommended content:
- searchable tenant list
- status filters
- create tenant action
- open detail view action
- suspend/reactivate/void quick actions where appropriate

Recommended list columns:
- tenant name
- tenant code
- status
- owner count
- user count
- created date
- last admin activity

### Tenant Detail Page

#### Overview Tab
Recommended content:
- tenant profile summary
- lifecycle status
- creation information
- current enabled modules
- high-risk actions area

#### Users Tab
Recommended content:
- owner and admin summary
- member list
- invite or assign user actions
- role update actions
- invitation status handling

#### Permissions Tab
Recommended content:
- feature entitlement list
- toggles or controlled edit actions
- effective date if needed for contractual features

#### Master Data Tab
Recommended content:
- only system-approved admin-editable configuration areas
- clear warning that this area is not for routine tenant operation

#### Audit Tab
Recommended content:
- filterable event list
- actor, action, target, timestamp, result
- detail drawer or modal for payload review

### Interaction Design Recommendations
- Require confirmation modal with reason input for suspend and void actions.
- Use badges for lifecycle status and permission states.
- Separate read-only information from destructive controls visually.
- Show audit-reference or request id on completion of sensitive actions.

## Service Module Direction
In the same codebase, isolate system-admin frontend logic with dedicated service modules.

Recommended module categories:
- `systemAdminTenantService`
- `systemAdminUserService`
- `systemAdminPermissionService`
- `systemAdminAuditService`

Reason:
- prevents accidental reuse of tenant-scoped service logic
- keeps permission handling explicit
- makes future test scope cleaner

## Recommended Implementation Phases

### Phase 1
- establish system-scope role model
- add route tree, layout, menu, and route guards
- add system-admin home and tenant list

### Phase 2
- implement tenant creation
- implement tenant lifecycle actions: suspend, reactivate, void
- add audit logging for these actions

### Phase 3
- implement tenant user management
- align with existing invitation and membership concepts

### Phase 4
- implement tenant function permission management

### Phase 5
- implement audit log UI and detailed review workflow

### Phase 6
- implement limited tenant master data administration only for clearly approved areas

## Risks and Design Notes
- The current application model is centered on a single active `tenant_id`; system-admin operations must not depend on that pattern.
- If system-admin authority is stored only in JWT metadata and not validated server-side, authorization drift and stale-session issues will occur.
- If tenant master data management is too broad, system-admin scope will become operationally unsafe and difficult to audit.
- If audit logging is handled only in the UI, records will be incomplete and untrustworthy.

## Final Recommendation
- Treat System Admin as a separate application boundary inside the same repository.
- Keep v1 focused on tenant lifecycle, tenant membership oversight, tenant feature entitlement, and strong auditability.
- Delay broad master-data editing until the operational need and audit rules are clearer.
