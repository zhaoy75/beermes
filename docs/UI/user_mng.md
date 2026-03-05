## Purpose
- Manage tenant user records shown in the `ユーザー一覧` page (`/users`).
- Store and manage user/invitation data in Supabase (no local mock state).
- Support search, invite (add), edit role, and delete/revoke from one page.

## Entry Points
- Sidebar: `ユーザー管理` → `ユーザー一覧`
- Route path: `/users`
- Vue page: `beeradmin_tail/src/views/Pages/UserManagement.vue`

## Users and Permissions
- Route requires authenticated user (`meta.requiresAuth = true`).
- Tenant `owner/admin`: can invite, edit role, and delete/revoke.
- Other tenant users: read-only or blocked (implementation choice).

## Page Layout
### Header
- Breadcrumb title: `users.title`
- Page title: `users.title`
- Subtitle: `users.subtitle`
- Primary action button: `users.actions.add`

### Body
- Search area (4 filters):
  - Name text filter (if display name exists)
  - Email text filter
  - Role dropdown (`viewer`, `editor`, `admin`, `owner`)
  - Status dropdown (`active`, `invited`)
- Result area:
  - User cards in responsive grid (`md:2`, `xl:3`)
  - Empty-state card when no result (`users.cards.empty`)

### Modal Dialog
- Invite user dialog (Add)
- Edit user dialog (Role edit)
- Delete confirmation dialog

## Field Definitions
### Search Filters
- `name`: partial match, case-insensitive (optional field)
- `email`: partial match, case-insensitive
- `role`: exact match (`owner` / `admin` / `editor` / `viewer`)
- `status`: exact match (`active` / `invited`)

### User Card
- `name` (optional or fallback to `-`)
- `email`
- `status` badge:
  - `active` (member exists in `tenant_members`)
  - `invited` (pending in `tenant_invitations`)
- `role` label
- Row actions:
  - Edit
  - Delete

### Invite Form (Add)
- `email` (required)
- `role` (required; API value set from UI selection)
  - If UI uses `member`, backend maps `member -> viewer`.

### Edit Form
- `role` (required; `owner` edit can be restricted by business rule)

## Action
### Add button
- Opens invite dialog.
- On save, call Edge Function `invite-member`:
  - `supabase.functions.invoke('invite-member', { body: { tenant_id, email, role } })`

### Edit button
- Opens edit dialog with selected user data.

### Save button
- Invite mode:
  - Validate `email`, `role`
  - Invoke `invite-member`
  - On success: refresh list
- Edit mode:
  - Update active member role:
    - `supabase.from('tenant_members').update({ role }).eq('tenant_id', tenantId).eq('user_id', userId)`
  - Update pending invite role:
    - `supabase.from('tenant_invitations').update({ role }).eq('tenant_id', tenantId).eq('id', invitationId).eq('status', 'invited')`
  - On success: refresh list

### Delete button
- Opens delete confirmation dialog.
- Confirm action behavior:
  - If status = `active`: remove tenant membership
    - `supabase.from('tenant_members').delete().eq('tenant_id', tenantId).eq('user_id', userId)`
  - If status = `invited`: revoke invitation
    - `supabase.from('tenant_invitations').update({ status: 'revoked' }).eq('tenant_id', tenantId).eq('id', invitationId).eq('status', 'invited')`
  - On success: refresh list

## Business Rules
- Search filtering uses trimmed lowercase values for `name` and `email`.
- Role filter is optional; empty role means all roles.
- Status filter is optional; empty status means all statuses.
- Invite is blocked if required fields are empty or invalid.
- Duplicate pending invite should return API error (`409`) from `invite-member`.
- Delete/revoke requires explicit confirmation.
- Do not allow deleting your own `owner/admin` membership unless explicitly designed.

## Data Handling
- Source tables:
  - `tenant_members` (active members)
  - `tenant_invitations` (pending/revoked/accepted invitations; UI uses `invited` for current pending rows)
- Recommended list strategy:
  - Query `tenant_members` for active members
  - Query `tenant_invitations` for `status='invited'`
  - Merge to one UI list model (`status: active|invited`)
- Add uses Edge Function `invite-member`.
- Edit/Delete use Supabase table APIs (`update` / `delete`) with RLS protection.
- I18n labels/messages use:
  - `beeradmin_tail/src/locales/ja.json` (`users.*`)
  - `beeradmin_tail/src/locales/en.json` (`users.*`)
- New i18n keys may be needed for statuses (`active`, `invited`, `revoked`) and invite/revoke messages.

## Other
- This page must support multilanguage UI (Japanese / English).
