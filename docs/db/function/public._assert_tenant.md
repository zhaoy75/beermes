# `public._assert_tenant() returns uuid`

## Purpose
Resolve and validate current tenant context.

## Input Contract
- No input.

## Validation
- `auth.jwt().app_metadata.tenant_id` must exist and be valid UUID.

## Data Access
- No table required.

## Behavior
- Parse tenant id from JWT context.
- Raise exception if missing/invalid.

## Output
- Tenant UUID.

## Errors
- Missing tenant context.
- Invalid UUID format.
