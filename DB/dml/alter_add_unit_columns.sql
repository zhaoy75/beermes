-- Add unit columns for existing databases
alter table public.lot
  add column if not exists unit numeric;

alter table public.inv_movement_lines
  add column if not exists unit numeric;
