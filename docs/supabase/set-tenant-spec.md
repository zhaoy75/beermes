# `set-tenant` Edge Function Specification

## Purpose
- Resolve the current user’s tenant from `tenant_members`.
- Write resolved `tenant_id` into `auth.users.app_metadata`.
- Enable tenant-scoped RLS access after sign-in/session refresh.

## Endpoint
- Function name: `set-tenant`
- Method: `POST`
- Path: `/functions/v1/set-tenant`
- Auth: `Authorization: Bearer <JWT>` required

## Request Contract

### Payload
- No request body is required.
- Empty JSON body is allowed:

```json
{}
```

## Behavior
1. Validate HTTP method:
   - `OPTIONS` returns CORS response.
   - Non-`POST` returns `405`.
2. Validate bearer token and current user (`auth.getUser` using anon client bound to caller JWT).
3. Query `tenant_members` with service role client:
   - filter: `user_id = current_user_id`
4. If no membership rows exist, return `404`.
5. Select tenant for JWT metadata:
   - current implementation uses `memberships[0].tenant_id` (first returned row).
6. Update user app metadata:
   - `auth.admin.updateUserById(user_id, { app_metadata: { ...existing, tenant_id } })`
7. Return success JSON with `tenant_id` and a note to refresh session/JWT.

## Response Contract

### 200 OK
```json
{
  "ok": true,
  "user_id": "uuid",
  "tenant_id": "uuid",
  "note": "Call supabase.auth.refreshSession() or sign in again to refresh JWT with tenant_id."
}
```

### Error Responses
- `400`: DB/admin update error
- `401`: missing or invalid/expired JWT
- `404`: user is not a member of any tenant
- `405`: method is not `POST`

## Data Dependencies
- `tenant_members(tenant_id, user_id, role, ...)`
- `auth.users.app_metadata`

## Security Requirements
- Service role key is used only in Edge Function runtime.
- Caller identity is always derived from bearer JWT (`auth.getUser`), never from request body.
- Function must not expose service-role secrets in responses/logs.

## Current Constraints
- Tenant selection is first-match only; there is no explicit priority or tenant selection parameter.
- If a user belongs to multiple tenants, selected tenant may be non-deterministic unless query ordering is controlled.

## Recommended Enhancements
1. Deterministic selection:
   - add ordering/priority (for example by role or created time), or
   - accept explicit `tenant_id` input and verify membership.
2. Keep invite finalization separate:
   - invitation acceptance is handled by `accept-invitation` from `/accept-invite`,
   - `set-tenant` should remain focused on tenant context selection only.
3. Audit logging:
   - store who/when tenant context was set.
