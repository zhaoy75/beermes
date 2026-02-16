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

## Node Selection
Include lots for current tenant where:
- `lot.batch_id = p_batch_id`

Recommended node fields:
- `id`
- `lot_no`
- `batch_id`
- `site_id`
- `qty`
- `uom_id`
- `status`
- `produced_at`
- `created_at`

## Edge Selection
Include edges for current tenant where either endpoint belongs to the batch:
- `from_lot.batch_id = p_batch_id` OR `to_lot.batch_id = p_batch_id`

Recommended edge fields:
- `id`
- `source` (`from_lot_id`)
- `target` (`to_lot_id`)
- `edge_type`
- `qty`
- `uom_id`
- `movement_id`
- `created_at`

## Source Lot Hint (Optional but Recommended)
Also return root source lot id for filling UI:
- join `lot` and `lot_edge` on `lot_edge.to_lot_id = lot.id`
- `lot.batch_id = p_batch_id`
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
      "created_at": "timestamp"
    }
  ]
}
```

## Errors
- Raise exception when `p_batch_id` is null.

## Notes for UI
- This function only returns graph data; layout (topological levels, x/y) is done in Vue.
- For disconnected nodes, UI should render them as independent subgraphs.
