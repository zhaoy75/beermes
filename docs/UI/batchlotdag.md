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
  - source lot highlighted
- Edge:
  - line between source and target
  - label: `edge_type / qty`

## Error Handling
- If RPC fails, show localized load error message.
