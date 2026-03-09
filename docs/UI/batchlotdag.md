# Batch Lot DAG Page UI Specification

## Purpose
- Show lot DAG history for one batch on a dedicated page (not a dialog).

## Entry Points
- Batch Edit page -> button: `移動履歴`
- Batch Packing page -> button: `移動履歴`
- On click, navigate to lot DAG page for current batch.

## Data Source
- RPC: `public.lot_dag_get_by_batch`
- Parameter: `p_batch_id = current batch id`

## Page Layout
- Header:
  - Title: Lot DAG
  - Subtitle: show lot DAG related to current batch
  - Back button: return to previous batch page (Batch Edit or Batch Packing)
- Body:
  - Error message area
  - Loading state
  - No data message
  - DAG canvas (nodes and edges)

## Rendering Rules
- Node:
  - label: `lot_no` (fallback: `id`)
  - sub label: `qty / status`
  - meta label: `site_name / lot_tax_type`
  - source lot highlighted
- Edge:
  - line between source and target
  - primary label on the line: `edge_type / qty`
  - secondary label under the line: `movement_tax_type`
  - arrow head shows direction from source lot to target lot
- Interaction:
  - on first render, nodes should be auto-arranged to reduce obvious edge crossings
  - user can drag individual DAG nodes to rearrange the diagram
  - edge lines and arrow heads must follow the moved node positions immediately

## Error Handling
- If RPC fails, show localized load error message.
