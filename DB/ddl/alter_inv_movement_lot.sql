-- Add lot linkage to inventory movement tables

alter table public.inv_movements
  add column if not exists lot_event_id uuid references public.lot_event(id);

alter table public.inv_movement_lines
  add column if not exists lot_id uuid references public.lot(id);

create index if not exists idx_inv_mov_lot_event
  on public.inv_movements (lot_event_id);

create index if not exists idx_inv_mov_line_lot
  on public.inv_movement_lines (lot_id);
