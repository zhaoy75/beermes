# Ensure Dummy Domestic Customer Site Function

## Purpose
- Define the exact contract for `public.ensure_dummy_domestic_customer_site()`.
- Provide a backend-only way to resolve or lazily create the tenant dummy `DOMESTIC_CUSTOMER` site.
- Keep the implementation compatible with the current `public.mst_sites` schema.

## Function Signature
- `public.ensure_dummy_domestic_customer_site() returns uuid`

## Ownership
- Backend only.
- UI must not create this site directly.
- The function is designed to be called later by `public.domestic_removal_complete(...)` and other backend-controlled flows.

## Inputs
- No explicit parameters.
- Tenant is derived from `public._assert_tenant()`.

## Output
- Returns the `public.mst_sites.id` of the canonical tenant dummy `DOMESTIC_CUSTOMER` site.

## Dependencies
- `public._assert_tenant()`
- `public.registry_def`
- `public.mst_sites`

## Canonical Dummy Site Definition

### Site Type
- Must resolve to registry definition:
  - `kind = 'site_type'`
  - `def_key = 'DOMESTIC_CUSTOMER'`
  - prefer tenant-owned active definition if present
  - otherwise use active system definition

### Business Identity
- Because `public.mst_sites` has no `meta` or code column, the canonical dummy site is defined by fixed business fields:
  - `owner_type = 'OUTSIDE'`
  - `owner_name = 'SYSTEM_DOMESTIC_REMOVAL_COMPLETE'`
- Matching must also include:
  - `tenant_id = current tenant`
  - resolved `site_type_id`
- `name = '国内移出完了ダミー取引先'` is the canonical display value, but not the primary match key.

### Insert Defaults
- `tenant_id = current tenant`
- `name = '国内移出完了ダミー取引先'`
- `site_type_id = resolved DOMESTIC_CUSTOMER site type`
- `parent_site_id = null`
- `notes = 'System-managed dummy DOMESTIC_CUSTOMER site for domestic removal complete'`
- `active = true`
- `owner_type = 'OUTSIDE'`
- `owner_name = 'SYSTEM_DOMESTIC_REMOVAL_COMPLETE'`
- `sort_order = 999999`

## Resolution Rules

### Existing Row
- If one or more matching rows already exist, the function returns the canonical row id.
- Canonical row means:
  - earliest `created_at`
  - tie-break by `id`
- Before returning the canonical row, the function may normalize:
  - `name`
  - `notes`
  - `active`
  - `sort_order`

### Missing Row
- If no matching row exists, the function creates one and returns the inserted id.

## Concurrency Rules
- The function must be safe under concurrent calls from the same tenant.
- It must take a tenant-scoped `pg_advisory_xact_lock(...)` before the create path.
- Because there is no supporting unique constraint in the current schema, the lock is the primary duplicate-prevention mechanism.

## Failure Conditions
- Raise an exception when:
  - tenant cannot be resolved
  - `DOMESTIC_CUSTOMER` site type cannot be resolved
  - insert fails for other reasons

## Non-Goals
- Do not hide the dummy site from UI in this function.
- Do not add schema columns or unique constraints in this task.
- Do not create the shipment movement in this function.
- Do not validate movement rules in this function.

## Acceptance Criteria
1. Repeated calls in the same tenant return the same site id.
2. Calls in different tenants return tenant-specific site ids.
3. The function creates the site lazily when absent.
4. The function resolves `DOMESTIC_CUSTOMER` through `public.registry_def`.
5. The function uses only existing `public.mst_sites` columns.
