## Purpose
- Manage tenant users in `ユーザー一覧` (`/users`).
- Restrict this page to tenant `owner/admin` only.
- Support member invite, role edit, delete member, reset password, and resend invitation.

## Entry Points
- Sidebar: `ユーザー管理` → `ユーザー一覧`
- Route path: `/users`
- Vue page: `beeradmin_tail/src/views/Pages/UserManagement.vue`

## Access Control
### Route-level
- Route remains authenticated (`meta.requiresAuth = true`).
- Add `meta.requiresAdmin = true` for `/users`.
- Router guard must:
  - resolve current tenant from `app_metadata.tenant_id`.
  - read caller role from `tenant_members`.
  - allow only `owner/admin`.
  - reject others (redirect `/error-404` or `/`).

### UI-level
- Sidebar item `ユーザー一覧` should be hidden for non-admin.
- If page is opened directly by non-admin, show no data and redirect by guard.

## Data Model Scope
- Active membership: `tenant_members`.
- Invitation lifecycle: `tenant_invitations`.
- Auth account: `auth.users` (Supabase Auth).
- Note: current schema does not define a `public.users` table in this repo.  
  If your requirement says `users`, implement as `auth.users` deletion.

## List and Filters
### Data fetch
1. Fetch `tenant_members` for current `tenant_id`.
2. Fetch `tenant_invitations` (`status in invited, accepted`) for same `tenant_id`.
3. Merge into UI card model.

### Search filters
- `name` partial match (case-insensitive).
- `email` partial match (case-insensitive).
- `role` exact (`owner/admin/editor/viewer`).
- `status` exact (`active/invited`).

## Actions
### Add (Invite)
- Existing behavior kept:
  - call `invite-member` Edge Function.

### Edit Role
- Existing behavior kept:
  - active member → update `tenant_members.role`.
  - pending invitation → update `tenant_invitations.role`.

### Delete User
- Replace direct table delete in UI with Edge Function call:
  - `supabase.functions.invoke('user-admin-action', { body: { action: 'delete_user', tenant_id, target_user_id } })`

#### Delete semantics
1. Verify caller is `owner/admin` of `tenant_id`.
2. Remove target from `tenant_members` for this tenant.
3. Revoke pending invitations for target user/email in this tenant.
4. Check remaining memberships of target in other tenants.
5. If no memberships remain, delete target from `auth.users`.
6. Return result describing what was deleted.

#### Delete constraints
- Reject delete if target is `owner` and would become last owner in tenant.
- Reject self-delete by default (explicitly blocked).

### Reset Password (new)
- Add action button on active user card: `Reset Password`.
- Call:
  - `supabase.functions.invoke('user-admin-action', { body: { action: 'reset_password', tenant_id, target_user_id } })`

#### Reset behavior
1. Verify caller admin permission.
2. Resolve target email from `auth.users`.
3. Send recovery/reset email (or generate reset link) with redirect URL.
4. Return success message.

### Resend Invitation (new)
- Add action button on invited user card: `Resend Invitation`.
- Call:
  - `supabase.functions.invoke('user-admin-action', { body: { action: 'resend_invitation', tenant_id, invitation_id } })`

#### Resend behavior
1. Verify caller admin permission.
2. Validate invitation belongs to tenant and is pending/revokable.
3. Mark previous pending invite as revoked (or expired).
4. Send new invite email and create fresh `tenant_invitations` row (`status='invited'`).
5. Return new invitation id/status.

## Proposed Edge Function Contract
### Endpoint
- Function name: `user-admin-action`
- Method: `POST`
- Path: `/functions/v1/user-admin-action`
- Auth: `Bearer JWT` required

### Request payload
```json
{
  "action": "delete_user | reset_password | resend_invitation",
  "tenant_id": "uuid",
  "target_user_id": "uuid (required for delete_user/reset_password)",
  "invitation_id": "uuid (required for resend_invitation)"
}
```

### Response
- `200` success with action-specific details.
- `400` invalid payload.
- `401` invalid JWT.
- `403` not tenant admin.
- `404` target user/invitation not found.
- `409` protected action conflict (last owner/self delete/state conflict).
- `500` unexpected error.

## UI Changes Required
- Add `Reset Password` button for `active` cards.
- Add `Resend Invitation` button for `invited` cards.
- Keep `Edit` and `Delete`.
- Disable all action buttons while `saving`.
- Show per-action success/error toast.

## I18n Additions
- New labels/messages under `users.*`:
  - actions: `resetPassword`, `resendInvitation`
  - confirms: `resetPasswordConfirm`, `resendInvitationConfirm`
  - feedback: `resetPasswordSent`, `resendInvitationSent`
  - errors: `adminOnlyPage`, `lastOwnerProtected`, `selfDeleteBlocked`

## Security Requirements
- All destructive/admin operations must run in Edge Function with service role.
- Client must not directly delete `auth.users`.
- Function logs must avoid secrets and never include password/token content.

## Non-Goals (v1)
- Bulk delete/reset/resend.
- Cross-tenant super-admin tooling.
- Editable user profile fields beyond role/invite lifecycle.
