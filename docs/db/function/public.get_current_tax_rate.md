# `public.get_current_tax_rate(p_tax_category_code text, p_target_date date) returns numeric`

## Purpose
Resolve the applicable alcohol tax rate for a tax category on a given date.

This function reads tax master data from `public.registry_def` where:
- `kind = 'alcohol_tax'`
- `spec.tax_category_code` matches the requested category
- `p_target_date` falls between `spec.start_date` and `spec.expiration_date`

## Rule Source
- Table: `public.registry_def`
- Selector:
  - `kind = 'alcohol_tax'`
  - `is_active = true`
- Source payload: `registry_def.spec` JSON

Expected JSON fields in `spec`:
- `tax_category_code`
- `tax_rate`
- `start_date`
- `expiration_date`

Example source row:
```json
{
  "name": "ビール",
  "tax_category_code": 350,
  "tax_rate": 63.35,
  "start_date": "2023-10-01",
  "expiration_date": "2026-09-30"
}
```

## Function Signature
```sql
create or replace function public.get_current_tax_rate(
  p_tax_category_code text,
  p_target_date date
)
returns numeric
language plpgsql
security invoker;
```

## Input Contract
Required inputs:
- `p_tax_category_code` text
  - compared against `registry_def.spec ->> 'tax_category_code'`
- `p_target_date` date

Input normalization:
- `p_tax_category_code` is trimmed before matching
- numeric tax category codes stored in JSON are compared as text

## Match Rules
1. Read `public.registry_def` rows where:
   - `kind = 'alcohol_tax'`
   - `is_active = true`
2. Match tax category:
   - `spec ->> 'tax_category_code' = trimmed p_tax_category_code`
3. Match effective date:
   - `p_target_date >= (spec ->> 'start_date')::date`
   - and
     - `p_target_date <= (spec ->> 'expiration_date')::date`
     - or `spec ->> 'expiration_date'` is null/empty

## Scope Priority
If tenant-specific alcohol tax definitions are introduced later, the function should follow standard registry priority:
- tenant row first: `scope = 'tenant' and owner_id = current tenant`
- fallback to system row: `scope = 'system'`

If tenant-specific rows are not used, system rows are sufficient.

## Return Value
- Returns matched `tax_rate` as `numeric`

## Validation
- `p_tax_category_code` must not be null or empty
- `p_target_date` must not be null
- matched row must contain:
  - valid `tax_rate`
  - valid `start_date`
- `tax_rate` must be numeric and `>= 0`

## Ambiguity and Not Found Rules
- If no row matches:
  - raise exception
- If more than one row matches after scope priority is applied:
  - raise exception because master data overlaps and is ambiguous

## Suggested Error Codes
- `GTR001`: missing tax_category_code
- `GTR002`: missing target_date
- `GTR003`: no tax rate definition found for category/date
- `GTR004`: overlapping tax rate definitions found for category/date
- `GTR005`: invalid tax master data in `registry_def.spec`

## Selection Behavior
Recommended implementation order:
1. Resolve tenant context if tenant-scope registry rows are supported
2. Build candidate set from `registry_def`
3. Apply category/date filters
4. Apply scope priority
5. Ensure exactly one row remains
6. Return `(spec ->> 'tax_rate')::numeric`

## Example Calls
```sql
select public.get_current_tax_rate('350', date '2026-03-08');
```

Expected result on March 8, 2026:
```text
63.35
```

```sql
select public.get_current_tax_rate('350', date '2026-10-01');
```

Expected result on October 1, 2026:
```text
54.25
```

## Example SQL Shape
```sql
select (r.spec ->> 'tax_rate')::numeric
from public.registry_def r
where r.kind = 'alcohol_tax'
  and r.is_active = true
  and coalesce(nullif(btrim(r.spec ->> 'tax_category_code'), ''), '') = btrim(p_tax_category_code)
  and (r.spec ->> 'start_date')::date <= p_target_date
  and (
    nullif(btrim(r.spec ->> 'expiration_date'), '') is null
    or (r.spec ->> 'expiration_date')::date >= p_target_date
  );
```

## Notes
- The source JSON key is `expiration_date`, not `expiration_data`.
- This function should be read-only.
- This function is intended to support `product_move`, `product_filling`, tax reporting, and UI pages that need a numeric tax rate derived from tax category and date.
