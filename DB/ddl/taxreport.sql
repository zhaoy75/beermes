create table if not exists tax_reports (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  tax_type text not null default 'monthly',
  tax_year int not null,
  tax_month int not null,
  status text not null default 'draft',
  declaration_type text not null default 'on_time',
  declaration_reason text,
  original_report_id uuid,
  previous_report_id uuid,
  amendment_no int,
  previous_confirmed_payable_tax_amount numeric,
  previous_confirmed_refund_tax_amount numeric,
  correction_delta_tax_amount numeric,
  prior_cumulative_tax_amount_calculated numeric,
  prior_cumulative_tax_amount_override numeric,
  prior_cumulative_tax_amount_source text not null default 'calculated',
  prior_cumulative_tax_amount_notes text,
  prior_cumulative_tax_amount_updated_at timestamptz,
  prior_cumulative_tax_amount_updated_by uuid,
  total_tax_amount numeric not null default 0,
  volume_breakdown jsonb default '[]'::jsonb,
  comparison_breakdown jsonb default '[]'::jsonb,
  report_files jsonb default '[]'::jsonb,
  attachment_files jsonb default '[]'::jsonb,
  updated_at timestamptz default now(),
  created_at timestamptz default now(),
  constraint tax_reports_status_check check (status in ('draft','stale','submitted','approved')),
  constraint tax_reports_month_check check (tax_month between 1 and 12),
  constraint tax_reports_declaration_type_check check (declaration_type in ('on_time','late','amended')),
  constraint tax_reports_prior_cumulative_source_check check (prior_cumulative_tax_amount_source in ('calculated','manual_override')),
  constraint tax_reports_prior_cumulative_amount_check check (
    prior_cumulative_tax_amount_calculated is null or prior_cumulative_tax_amount_calculated >= 0
  ),
  constraint tax_reports_prior_cumulative_override_check check (
    prior_cumulative_tax_amount_override is null or prior_cumulative_tax_amount_override >= 0
  ),
  constraint tax_reports_amendment_shape_check check (
    (
      declaration_type = 'amended'
      and amendment_no is not null
      and amendment_no > 0
      and previous_report_id is not null
    )
    or (
      declaration_type <> 'amended'
      and amendment_no is null
      and original_report_id is null
      and previous_report_id is null
    )
  )
);

alter table public.tax_reports
  add column if not exists declaration_type text not null default 'on_time',
  add column if not exists declaration_reason text,
  add column if not exists original_report_id uuid,
  add column if not exists previous_report_id uuid,
  add column if not exists amendment_no int,
  add column if not exists previous_confirmed_payable_tax_amount numeric,
  add column if not exists previous_confirmed_refund_tax_amount numeric,
  add column if not exists correction_delta_tax_amount numeric,
  add column if not exists prior_cumulative_tax_amount_calculated numeric,
  add column if not exists prior_cumulative_tax_amount_override numeric,
  add column if not exists prior_cumulative_tax_amount_source text not null default 'calculated',
  add column if not exists prior_cumulative_tax_amount_notes text,
  add column if not exists prior_cumulative_tax_amount_updated_at timestamptz,
  add column if not exists prior_cumulative_tax_amount_updated_by uuid,
  add column if not exists comparison_breakdown jsonb default '[]'::jsonb,
  add column if not exists updated_at timestamptz default now();

alter table public.tax_reports
  drop constraint if exists tax_reports_status_check;

alter table public.tax_reports
  add constraint tax_reports_status_check
  check (status in ('draft','stale','submitted','approved'));

alter table public.tax_reports
  drop constraint if exists tax_reports_declaration_type_check;

alter table public.tax_reports
  add constraint tax_reports_declaration_type_check
  check (declaration_type in ('on_time','late','amended'));

alter table public.tax_reports
  drop constraint if exists tax_reports_prior_cumulative_source_check;

alter table public.tax_reports
  add constraint tax_reports_prior_cumulative_source_check
  check (prior_cumulative_tax_amount_source in ('calculated','manual_override'));

alter table public.tax_reports
  drop constraint if exists tax_reports_prior_cumulative_amount_check;

alter table public.tax_reports
  add constraint tax_reports_prior_cumulative_amount_check
  check (prior_cumulative_tax_amount_calculated is null or prior_cumulative_tax_amount_calculated >= 0);

alter table public.tax_reports
  drop constraint if exists tax_reports_prior_cumulative_override_check;

alter table public.tax_reports
  add constraint tax_reports_prior_cumulative_override_check
  check (prior_cumulative_tax_amount_override is null or prior_cumulative_tax_amount_override >= 0);

alter table public.tax_reports
  drop constraint if exists tax_reports_amendment_shape_check;

alter table public.tax_reports
  add constraint tax_reports_amendment_shape_check
  check (
    (
      declaration_type = 'amended'
      and amendment_no is not null
      and amendment_no > 0
      and previous_report_id is not null
    )
    or (
      declaration_type <> 'amended'
      and amendment_no is null
      and original_report_id is null
      and previous_report_id is null
    )
  );

alter table public.tax_reports
  drop constraint if exists tax_reports_tenant_id_tax_year_tax_month_key;

create unique index if not exists tax_reports_base_declaration_unique
  on public.tax_reports (tenant_id, tax_type, tax_year, tax_month)
  where declaration_type in ('on_time', 'late');

create unique index if not exists tax_reports_amended_declaration_unique
  on public.tax_reports (tenant_id, tax_type, tax_year, tax_month, amendment_no)
  where declaration_type = 'amended';

create table if not exists public.tax_batch_corrections (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  comparison_report_id uuid not null references public.tax_reports(id),
  batch_id uuid not null references public.mes_batches(id),
  old_beer_category_id text,
  new_beer_category_id text,
  old_actual_abv numeric,
  new_actual_abv numeric,
  old_target_abv numeric,
  new_target_abv numeric,
  reason text not null,
  status text not null default 'draft',
  used_report_id uuid references public.tax_reports(id),
  created_by uuid,
  created_at timestamptz not null default now(),
  updated_by uuid,
  updated_at timestamptz not null default now(),
  approved_by uuid,
  approved_at timestamptz,
  voided_by uuid,
  voided_at timestamptz,
  used_at timestamptz,
  constraint tax_batch_corrections_status_check
    check (status in ('draft','approved','used','void')),
  constraint tax_batch_corrections_reason_check
    check (btrim(reason) <> ''),
  constraint tax_batch_corrections_used_shape_check
    check (
      (status = 'used' and used_report_id is not null and used_at is not null)
      or (status <> 'used')
    ),
  constraint tax_batch_corrections_void_shape_check
    check (
      (status = 'void' and voided_at is not null)
      or (status <> 'void')
    )
);

alter table public.tax_batch_corrections
  add column if not exists comparison_report_id uuid,
  add column if not exists batch_id uuid,
  add column if not exists old_beer_category_id text,
  add column if not exists new_beer_category_id text,
  add column if not exists old_actual_abv numeric,
  add column if not exists new_actual_abv numeric,
  add column if not exists old_target_abv numeric,
  add column if not exists new_target_abv numeric,
  add column if not exists reason text,
  add column if not exists status text not null default 'draft',
  add column if not exists used_report_id uuid,
  add column if not exists created_by uuid,
  add column if not exists created_at timestamptz not null default now(),
  add column if not exists updated_by uuid,
  add column if not exists updated_at timestamptz not null default now(),
  add column if not exists approved_by uuid,
  add column if not exists approved_at timestamptz,
  add column if not exists voided_by uuid,
  add column if not exists voided_at timestamptz,
  add column if not exists used_at timestamptz;

alter table public.tax_batch_corrections
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table public.tax_batch_corrections
  drop constraint if exists tax_batch_corrections_status_check;

alter table public.tax_batch_corrections
  add constraint tax_batch_corrections_status_check
  check (status in ('draft','approved','used','void'));

alter table public.tax_batch_corrections
  drop constraint if exists tax_batch_corrections_reason_check;

alter table public.tax_batch_corrections
  add constraint tax_batch_corrections_reason_check
  check (btrim(coalesce(reason, '')) <> '');

alter table public.tax_batch_corrections
  drop constraint if exists tax_batch_corrections_used_shape_check;

alter table public.tax_batch_corrections
  add constraint tax_batch_corrections_used_shape_check
  check (
    (status = 'used' and used_report_id is not null and used_at is not null)
    or (status <> 'used')
  );

alter table public.tax_batch_corrections
  drop constraint if exists tax_batch_corrections_void_shape_check;

alter table public.tax_batch_corrections
  add constraint tax_batch_corrections_void_shape_check
  check (
    (status = 'void' and voided_at is not null)
    or (status <> 'void')
  );

create unique index if not exists tax_batch_corrections_active_unique
  on public.tax_batch_corrections (tenant_id, comparison_report_id, batch_id)
  where status in ('draft','approved','used');

create index if not exists idx_tax_batch_corrections_comparison_report
  on public.tax_batch_corrections (tenant_id, comparison_report_id);

create index if not exists idx_tax_batch_corrections_used_report
  on public.tax_batch_corrections (tenant_id, used_report_id)
  where used_report_id is not null;

create index if not exists idx_tax_batch_corrections_batch
  on public.tax_batch_corrections (tenant_id, batch_id);

alter table public.tax_batch_corrections enable row level security;

drop policy if exists tax_batch_corrections_tenant_all on public.tax_batch_corrections;
create policy tax_batch_corrections_tenant_all
  on public.tax_batch_corrections
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (
    tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid
    and exists (
      select 1
      from public.tax_reports r
      where r.tenant_id = tax_batch_corrections.tenant_id
        and r.id = tax_batch_corrections.comparison_report_id
    )
    and exists (
      select 1
      from public.mes_batches b
      where b.tenant_id = tax_batch_corrections.tenant_id
        and b.id = tax_batch_corrections.batch_id
    )
    and (
      tax_batch_corrections.used_report_id is null
      or exists (
        select 1
        from public.tax_reports used_report
        where used_report.tenant_id = tax_batch_corrections.tenant_id
          and used_report.id = tax_batch_corrections.used_report_id
      )
    )
  );

create table if not exists public.tax_report_cumulative_amount_audit (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null,
  tax_report_id uuid not null references public.tax_reports(id) on delete cascade,
  old_override_amount numeric,
  new_override_amount numeric,
  old_source text,
  new_source text not null,
  notes text,
  changed_by uuid,
  changed_at timestamptz not null default now(),
  constraint tax_report_cumulative_amount_audit_new_source_check
    check (new_source in ('calculated','manual_override')),
  constraint tax_report_cumulative_amount_audit_old_source_check
    check (old_source is null or old_source in ('calculated','manual_override'))
);

alter table public.tax_report_cumulative_amount_audit
  add column if not exists old_override_amount numeric,
  add column if not exists new_override_amount numeric,
  add column if not exists old_source text,
  add column if not exists new_source text,
  add column if not exists notes text,
  add column if not exists changed_by uuid,
  add column if not exists changed_at timestamptz not null default now();

alter table public.tax_report_cumulative_amount_audit
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table public.tax_report_cumulative_amount_audit enable row level security;

drop policy if exists "tax_report_cumulative_amount_audit_tenant_all" on public.tax_report_cumulative_amount_audit;
create policy "tax_report_cumulative_amount_audit_tenant_all"
  on public.tax_report_cumulative_amount_audit
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

alter table tax_reports   enable row level security;

alter table tax_reports
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

drop policy if exists "tax_reports_tenant_all" on tax_reports;
create policy "tax_reports_tenant_all"
  on tax_reports
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);

alter table inv_inventory
  alter column tenant_id set default (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid;

alter table inv_inventory   enable row level security;

drop policy if exists "inv_inventory_tenant_all" on inv_inventory;
create policy "inv_inventory_tenant_all"
  on inv_inventory
  for all
  using (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid)
  with check (tenant_id = (auth.jwt() -> 'app_metadata' ->> 'tenant_id')::uuid);
