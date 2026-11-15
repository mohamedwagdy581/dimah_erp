-- Repair only settlement attachment policies; keeps existing files and rows.
begin;
-- A definer helper reads membership without depending on users/employees RLS.
-- It never grants access across tenants and only accepts settlement file paths.
create or replace function public.hr_can_access_settlement_file(p_name text)
returns boolean language sql stable security definer set search_path = public, pg_temp
as $access$
  select exists (
    select 1
    from public.users u
    join public.employees e on e.tenant_id = u.tenant_id
    where u.id = auth.uid()
      and u.is_active is true
      and u.role in ('hr', 'admin')
      and u.tenant_id::text = split_part(p_name, '/', 1)
      and e.id::text = split_part(p_name, '/', 2)
      and p_name ~ '^[0-9a-f-]{36}/[0-9a-f-]{36}/[0-9a-f-]{36}\.(pdf|jpg|jpeg|png)$'
  );
$access$;
revoke all on function public.hr_can_access_settlement_file(text) from public;
grant execute on function public.hr_can_access_settlement_file(text) to authenticated;

drop policy if exists hr_settlement_files_read on storage.objects;
create policy hr_settlement_files_read on storage.objects for select to authenticated
using (
  bucket_id = 'employee_settlement_files'
  and public.hr_can_access_settlement_file(storage.objects.name)
);
drop policy if exists hr_settlement_files_insert on storage.objects;
create policy hr_settlement_files_insert on storage.objects for insert to authenticated
with check (
  bucket_id = 'employee_settlement_files'
  and public.hr_can_access_settlement_file(storage.objects.name)
);
drop policy if exists hr_settlement_files_update on storage.objects;
create policy hr_settlement_files_update on storage.objects for update to authenticated
using (
  bucket_id = 'employee_settlement_files'
  and public.hr_can_access_settlement_file(storage.objects.name)
)
with check (
  bucket_id = 'employee_settlement_files'
  and public.hr_can_access_settlement_file(storage.objects.name)
);

notify pgrst, 'reload schema';
commit;
