insert into storage.buckets (id, name, public)
values ('tax-report-files', 'tax-report-files', false)
on conflict (id) do update
set name = excluded.name,
    public = excluded.public;

drop policy if exists tax_report_files_select on storage.objects;
create policy tax_report_files_select
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'tax-report-files'
    and name like ('tenant__' || coalesce(auth.jwt() -> 'app_metadata' ->> 'tenant_id', '') || '__%')
  );

drop policy if exists tax_report_files_insert on storage.objects;
create policy tax_report_files_insert
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'tax-report-files'
    and name like ('tenant__' || coalesce(auth.jwt() -> 'app_metadata' ->> 'tenant_id', '') || '__%')
  );

drop policy if exists tax_report_files_update on storage.objects;
create policy tax_report_files_update
  on storage.objects
  for update
  to authenticated
  using (
    bucket_id = 'tax-report-files'
    and name like ('tenant__' || coalesce(auth.jwt() -> 'app_metadata' ->> 'tenant_id', '') || '__%')
  )
  with check (
    bucket_id = 'tax-report-files'
    and name like ('tenant__' || coalesce(auth.jwt() -> 'app_metadata' ->> 'tenant_id', '') || '__%')
  );

drop policy if exists tax_report_files_delete on storage.objects;
create policy tax_report_files_delete
  on storage.objects
  for delete
  to authenticated
  using (
    bucket_id = 'tax-report-files'
    and name like ('tenant__' || coalesce(auth.jwt() -> 'app_metadata' ->> 'tenant_id', '') || '__%')
  );
