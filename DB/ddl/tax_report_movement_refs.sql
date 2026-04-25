create table if not exists public.tax_report_movement_refs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  tax_report_id uuid not null references public.tax_reports(id) on delete cascade,
  movement_id uuid not null references public.inv_movements(id),
  movement_line_id uuid null references public.inv_movement_lines(id),
  tax_event text null,
  role text not null default 'source',
  source_period_year int null,
  source_period_month int null,
  created_at timestamptz default now(),
  unique (tenant_id, tax_report_id, movement_id, movement_line_id)
);

create index if not exists idx_tax_report_movement_refs_movement
  on public.tax_report_movement_refs (tenant_id, movement_id);

create index if not exists idx_tax_report_movement_refs_report
  on public.tax_report_movement_refs (tenant_id, tax_report_id);

create index if not exists idx_tax_report_movement_refs_line
  on public.tax_report_movement_refs (tenant_id, movement_line_id)
  where movement_line_id is not null;

alter table public.tax_report_movement_refs enable row level security;

alter table public.tax_report_movement_refs
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

drop policy if exists tax_report_movement_refs_tenant_all on public.tax_report_movement_refs;
create policy tax_report_movement_refs_tenant_all
  on public.tax_report_movement_refs
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    and exists (
      select 1
      from public.tax_reports r
      where r.tenant_id = tax_report_movement_refs.tenant_id
        and r.id = tax_report_movement_refs.tax_report_id
    )
    and exists (
      select 1
      from public.inv_movements m
      where m.tenant_id = tax_report_movement_refs.tenant_id
        and m.id = tax_report_movement_refs.movement_id
    )
    and (
      tax_report_movement_refs.movement_line_id is null
      or exists (
        select 1
        from public.inv_movement_lines l
        where l.tenant_id = tax_report_movement_refs.tenant_id
          and l.movement_id = tax_report_movement_refs.movement_id
          and l.id = tax_report_movement_refs.movement_line_id
      )
    )
  );
