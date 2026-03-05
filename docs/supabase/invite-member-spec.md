# `invite-member` Edge Function Specification

## Purpose
- Invite a user to a tenant without handling passwords in app code.
- Enforce tenant admin-only invitation control.
- Keep an auditable pending invitation state until acceptance.

## Endpoint
- Function name: `invite-member`
- Method: `POST`
- Path: `/functions/v1/invite-member`
- Auth: `Authorization: Bearer <JWT>` required

## Request Contract

### Payload
```json
{
  "tenant_id": "uuid",
  "email": "new@company.com",
  "role": "member"
}
```

### Validation
- `tenant_id`: required, UUID
- `email`: required, valid email format, normalized to lowercase/trimmed
- `role`: required
  - API accepts: `member` (and optionally `admin` if needed)
  - DB mapping (v1): `member -> viewer`, `admin -> admin` because current `tenant_role` enum is `owner|admin|editor|viewer`

## Behavior
1. Verify caller JWT is present and valid (`auth.getUser`).
2. Verify caller is tenant admin for `tenant_id`:
   - `tenant_members` contains `(tenant_id, caller_user_id)` with role in `('owner', 'admin')`.
3. Validate request payload.
4. Check duplicate state:
   - already a member in `tenant_members` for same tenant + email/user
   - already pending invite for same tenant + email
5. Use service role client to call:
   - `auth.admin.inviteUserByEmail(email, { data: { tenant_id, invited_role, invited_by } })`
6. Create/Upsert pending invitation row in `tenant_invitations` with status `invited`.
7. Return success payload (idempotent-friendly; repeated request may return existing pending invite).

## Database Design

### Existing Table (unchanged)
- `tenant_members(tenant_id, user_id, role, invited_by, created_at)`

### New Table (required)
- `tenant_invitations`
  - `id uuid primary key default gen_random_uuid()`
  - `tenant_id uuid not null references tenants(id) on delete cascade`
  - `email text not null`
  - `role tenant_role not null`
  - `status text not null check (status in ('invited','accepted','revoked','expired')) default 'invited'`
  - `invited_by uuid not null`
  - `invited_user_id uuid null` (if available from auth admin response)
  - `invited_at timestamptz not null default now()`
  - `accepted_at timestamptz null`
  - `expires_at timestamptz null`
  - `meta jsonb not null default '{}'::jsonb`

### Suggested Indexes
- unique pending invite per tenant+email:
  - unique index on `(tenant_id, lower(email))` where `status = 'invited'`
- lookup by invited user:
  - index on `(invited_user_id)`

## Acceptance and Finalization

## Flow
1. Invited user clicks invite link and completes signup/password setup (Supabase Auth flow).
2. Membership is finalized when user first logs in (recommended: extend existing `set-tenant` function):
   - find `tenant_invitations` where `lower(email)=lower(auth.user.email)` and `status='invited'`
   - insert `tenant_members(tenant_id, user_id, role, invited_by)` if not exists
   - update invitation `status='accepted'`, `accepted_at=now()`, `invited_user_id=user_id`
3. Refresh JWT/session so `app_metadata.tenant_id` is current.

## Why this approach
- Works with current schema where `tenant_members` requires `user_id`.
- Avoids storing temporary pseudo-members without a user id.
- Keeps invitation lifecycle explicit and auditable.

## Response Contract

### 200 OK
```json
{
  "ok": true,
  "tenant_id": "uuid",
  "email": "new@company.com",
  "role": "member",
  "invitation_status": "invited"
}
```

### Error Responses
- `400`: invalid payload / invalid role / invalid email
- `401`: missing or invalid JWT
- `403`: caller is not tenant admin
- `404`: tenant not found
- `409`: already member or pending invite exists
- `500`: unexpected server/auth-admin error

## Security Requirements
- Service role key used only inside Edge Function runtime.
- Do not trust payload `tenant_id` without admin membership verification.
- Log inviter, tenant, target email, and result.
- Apply per-user rate limit (recommended) to prevent invite abuse.

## Non-Goals (v1)
- Resend/revoke invite endpoints
- Bulk invites
- Custom email templates per tenant
