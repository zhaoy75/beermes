# `public.get_packing_source_lotid(p_batch_id uuid) returns uuid`

## Purpose
Return one source lot id for a batch.
The source lot is the root produced lot created by `PRODUCE` edge (`from_lot_id is null`).

## Function Signature
```sql
create or replace function public.get_packing_source_lotid(p_batch_id uuid)
returns uuid
language plpgsql
stable
security invoker;
```

## Data Source View
Use a view that joins `lot` and `lot_edge`.

```sql
create or replace view public.v_batch_source_lot_candidates as
select
  l.tenant_id,
  l.batch_id,
  l.id as source_lot_id,
  l.site_id,
  l.uom_id,
  l.status,
  l.qty,
  l.produced_at,
  l.created_at
from public.lot l
join public.lot_edge e
  on e.to_lot_id = l.id
 and e.tenant_id = l.tenant_id
where e.from_lot_id is null
  and e.edge_type = 'PRODUCE'::public.lot_edge_type;
```

## Selection Rules
- `p_batch_id` must match `v_batch_source_lot_candidates.batch_id`.
- tenant must match current session tenant (`public._assert_tenant()`).
- `status <> 'void'`
- `qty > 0`
- `produced_at desc nulls last`
- `created_at desc`

## Suggested Implementation
```sql
create or replace function public.get_packing_source_lotid(p_batch_id uuid)
returns uuid
language plpgsql
stable
security invoker
as $$
declare
  v_tenant uuid;
  v_source_lot_id uuid;
begin
  if p_batch_id is null then
    raise exception 'p_batch_id is required';
  end if;

  v_tenant := public._assert_tenant();

  select v.source_lot_id
    into v_source_lot_id
  from public.v_batch_source_lot_candidates v
  where v.tenant_id = v_tenant
    and v.batch_id = p_batch_id
    and v.status <> 'void'
    and v.qty > 0
  order by v.produced_at desc nulls last, v.created_at desc
  limit 1;

  return v_source_lot_id; -- null when not found
end;
$$;
```

## Output
- Returns `source_lot_id` (`uuid`) when found.
- Returns `null` when no candidate exists.

## Error
- raise exception when `p_batch_id` is null.

## Notes
- This function is designed for filling/packing flow where source lot must come from root `PRODUCE` lineage.
- If site-based filtering is needed, add `p_site_id uuid` and filter by `site_id`.
