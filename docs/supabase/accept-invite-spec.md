# `accept-invite` Page + `accept-invitation` Edge Function Specification

## Purpose
- Provide a dedicated invite-acceptance page at `/accept-invite`.
- Let invited users set their password from UI.
- Finalize tenant membership from pending invitation rows.
- Mark invitation lifecycle state as accepted.
- Set current tenant context in JWT app metadata.

## Scope
- Frontend page spec: route, UI states, submit behavior.
- Backend function spec: `accept-invitation`.
- Integrates with existing `invite-member` and `set-tenant` design.

## Frontend Route Contract
- Route path: `/accept-invite`
- Route name: `AcceptInvite`
- Route meta:
  - `title: 'Accept Invite'`
  - `public: true`
  - no `requiresAuth`

## Router/Auth Guard Requirements
- `router.beforeEach` must allow `/accept-invite` without redirecting to `/signin`.
- `auth.bootstrap()` and `onAuthStateChange` redirect guard must not force redirect away from `/accept-invite` while session is being established from invite token.
- Current `onAuthStateChange` exclusion list (`/signin`, `/signup`) should include `/accept-invite`.

## Invite URL Contract
- Base URL: `http://localhost:5173/accept-invite`
- Required query params from Supabase invite email:
  - `token_hash`
  - `type=invite`
- Optional query params:
  - `tenant_id` (if invite email embeds explicit tenant)
  - `redirect` (post-success app redirect; defaults to `/`)

## Supabase Config Requirement
- `supabase/config.toml` should include `http://localhost:5173/accept-invite` in:
  - `[auth].additional_redirect_urls`

## UI Contract (`accept-invite` page)
- Form fields:
  - `password`
  - `confirmPassword`
- Primary action button:
  - Label: `Set Password and Join`
  - Disabled while submitting
- Validation:
  - password required
  - password length >= auth minimum
  - `confirmPassword === password`
- States:
  - `verifying_link`
  - `ready`
  - `submitting`
  - `success`
  - `error`

## Frontend Behavior
1. On page load, read query params.
2. Validate `token_hash` and `type=invite`; show invalid-link error if missing.
3. Call:
   - `supabase.auth.verifyOtp({ token_hash, type: 'invite' })`
4. Ensure session exists and extract `user.email`.
5. User enters password + confirm password.
6. On click `Set Password and Join`, call:
   - `supabase.functions.invoke('accept-invitation', { body: { password, tenant_id? } })`
7. On success:
   - call `supabase.auth.refreshSession()`
   - redirect to `redirect` query param or `/`
8. Show user-friendly error for expired/revoked invite, weak password, or server failures.

## Edge Function Contract

### Endpoint
- Function name: `accept-invitation`
- Method: `POST`
- Path: `/functions/v1/accept-invitation`
- Auth: `Authorization: Bearer <JWT>` required

### Request Payload
```json
{
  "password": "string",
  "tenant_id": "uuid (optional)"
}
```

### Validation
- `password`: required, non-empty string, meets project password policy.
- `tenant_id`: optional UUID; if present, acceptance is scoped to that tenant.
- Caller JWT must resolve to a real user with email.

### Behavior
1. Validate method and CORS.
2. Resolve caller from bearer JWT (`auth.getUser`).
3. Validate `password`.
4. Look up pending invites from `tenant_invitations`:
   - `lower(email) = lower(caller.email)`
   - `status = 'invited'`
   - not expired (`expires_at is null OR expires_at > now()`)
   - if `tenant_id` passed, add tenant filter
5. If no pending invites:
   - if user already has tenant membership from prior accepted invite, return idempotent success
   - otherwise return `404` (no valid invite)
6. Set password:
   - `auth.admin.updateUserById(caller_user_id, { password })`
7. For each pending invite, upsert membership:
   - insert into `tenant_members(tenant_id, user_id, role, invited_by)`
   - on conflict `(tenant_id, user_id)` do nothing
8. Mark matched invitations accepted:
   - `status = 'accepted'`
   - `accepted_at = now()`
   - `invited_user_id = caller_user_id`
9. Select current tenant:
   - if request `tenant_id` present and accepted, use it
   - else use most recently invited row (`invited_at desc`)
10. Set current tenant in app metadata:
   - `auth.admin.updateUserById(user_id, { app_metadata: { ...existing, tenant_id: current_tenant_id } })`
11. Return success payload.

### Success Response (`200`)
```json
{
  "ok": true,
  "user_id": "uuid",
  "email": "invited@company.com",
  "accepted_count": 1,
  "accepted_tenant_ids": ["uuid"],
  "current_tenant_id": "uuid",
  "note": "Call supabase.auth.refreshSession() to refresh JWT tenant_id."
}
```

### Error Responses
- `400`: invalid payload / weak password / bad tenant_id format
- `401`: missing or invalid JWT
- `404`: no pending invitation for caller email
- `409`: tenant mismatch or invitation is revoked/expired
- `500`: unexpected DB/auth-admin error

## Data and Constraint Requirements
- `tenant_invitations` table from `invite-member` spec must exist.
- `tenant_members` must have unique key on `(tenant_id, user_id)`.
- Recommended index for lookup performance:
  - `(lower(email), status, expires_at)`

## Security Requirements
- Never log raw password.
- Service role key only in Edge runtime.
- Caller identity must come from JWT, never request body.
- Password validation errors should be generic enough to avoid leaking policy internals beyond required guidance.

## Integration Notes
- `invite-member` remains responsible for creating pending invites only.
- `accept-invitation` becomes the explicit finalization point after user sets password.
- `set-tenant` remains usable for explicit tenant switching/reselection after initial acceptance.

## Non-Goals (v1)
- Invite revoke/resend UI
- Tenant picker UI when many pending invites exist
- Multi-step onboarding beyond membership + tenant context set
