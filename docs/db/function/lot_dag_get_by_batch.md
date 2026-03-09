# `public.lot_dag_get_by_batch(p_batch_id uuid) returns jsonb`

## Purpose
Return lot DAG data for a batch id as UI-ready JSON.

The DAG is built from:
- nodes: `public.lot`
- edges: `public.lot_edge` (`from_lot_id -> to_lot_id`)

## Function Signature
```sql
create or replace function public.lot_dag_get_by_batch(p_batch_id uuid)
returns jsonb
language plpgsql
stable
security invoker;
```

## Input Contract
- Required: `p_batch_id uuid`

## Validation
- `p_batch_id` is required.
- Tenant is resolved by `public._assert_tenant()`.

## Data Access
- Read: `public.lot`
- Read: `public.lot_edge`
- Read: `public.mst_sites` (node site name)
- Read: `public.inv_movements` (edge movement tax type)

## Node Selection
Include lots for current tenant where:
- `lot.batch_id = p_batch_id`

Returned node fields:
- `id`
- `lot_no`
- `batch_id`
- `site_id`
- `site_name`
- `lot_tax_type`
- `qty`
- `uom_id`
- `status`
- `produced_at`
- `created_at`

Site data is resolved by left-joining `public.mst_sites` on `lot.site_id`.

Node order in the JSON array:
- `produced_at desc nulls last`
- `created_at asc`
- `id asc`

## Edge Selection
Include edges for current tenant where either endpoint belongs to the batch:
- `from_lot.batch_id = p_batch_id` OR `to_lot.batch_id = p_batch_id`

Tenant isolation is enforced in two places:
- `lot_edge.tenant_id = current tenant`
- joined source/target lots are filtered with `lot.tenant_id = current tenant`

Returned edge fields:
- `id`
- `source` (`from_lot_id`)
- `target` (`to_lot_id`)
- `edge_type`
- `qty`
- `uom_id`
- `movement_id`
- `movement_tax_type`
- `created_at`

`movement_tax_type` is derived from the linked movement header with this
precedence:
- `inv_movements.meta.tax_event`
- `inv_movements.meta.tax_type`

Edge order in the JSON array:
- `created_at asc`
- `id asc`

## Source Lot Resolution
The function always returns `source_lot_id`. It is `null` when no matching source
lot exists.

Resolution rules:
- join `lot` and `lot_edge` on `lot_edge.to_lot_id = lot.id`
- `lot.batch_id = p_batch_id`
- `lot.tenant_id = current tenant`
- `lot_edge.tenant_id = lot.tenant_id`
- `lot_edge.from_lot_id is null`
- `lot_edge.edge_type = 'PRODUCE'`
- `lot.status <> 'void'`
- `lot.qty > 0`
- order by `lot.produced_at desc nulls last, lot.created_at desc`
- pick one as `source_lot_id`

## Output
Return JSON object:
```json
{
  "batch_id": "uuid",
  "source_lot_id": "uuid|null",
  "nodes": [
    {
      "id": "uuid",
      "lot_no": "text",
      "batch_id": "uuid",
      "site_id": "uuid",
      "site_name": "text|null",
      "lot_tax_type": "text|null",
      "qty": 100,
      "uom_id": "uuid",
      "status": "active",
      "produced_at": "timestamp",
      "created_at": "timestamp"
    }
  ],
  "edges": [
    {
      "id": "uuid",
      "source": "uuid|null",
      "target": "uuid|null",
      "edge_type": "PRODUCE",
      "qty": 100,
      "uom_id": "uuid",
      "movement_id": "uuid",
      "movement_tax_type": "text|null",
      "created_at": "timestamp"
    }
  ]
}
```

If no matching lots or edges exist for the batch, the function still returns:
- `"batch_id": p_batch_id`
- `"source_lot_id": null`
- `"nodes": []`
- `"edges": []`

## Errors
- Raise exception when `p_batch_id` is null.

## Notes for UI
- This function only returns graph data; layout (topological levels, x/y) is done in Vue.
- For disconnected nodes, UI should render them as independent subgraphs.
- The function does not recurse beyond edges directly connected to batch lots. It
  returns the lots in the batch plus edges whose source or target is one of those
  lots.
