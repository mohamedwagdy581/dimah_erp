-- Run once in the Supabase SQL editor. Existing settlement rows are preserved.
begin;
create table if not exists public.employee_settlements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  employee_id uuid not null references public.employees(id),
  final_working_date date not null,
  settlement_date date not null,
  gross_amount numeric(12, 2) not null default 0,
  deductions_amount numeric(12, 2) not null default 0,
  net_amount numeric(12, 2) not null default 0,
  notes text,
  created_at timestamptz not null default now()
);
alter table public.employee_settlements add column if not exists settlement_type text not null default 'final';
alter table public.employee_settlements add column if not exists attachment_path text;
alter table public.employee_settlements add column if not exists attachment_name text;
create index if not exists idx_employee_settlements_tenant on public.employee_settlements(tenant_id);
create index if not exists idx_employee_settlements_employee on public.employee_settlements(employee_id, settlement_date desc);
alter table public.employee_settlements enable row level security;
drop policy if exists hr_settlements_scope on public.employee_settlements;
create policy hr_settlements_scope on public.employee_settlements as restrictive for all to authenticated
using (exists(select 1 from public.users u where u.id = auth.uid() and u.is_active and u.tenant_id = employee_settlements.tenant_id))
with check (exists(select 1 from public.users u where u.id = auth.uid() and u.is_active and u.tenant_id = employee_settlements.tenant_id));
drop policy if exists hr_settlements_read on public.employee_settlements;
create policy hr_settlements_read on public.employee_settlements for select to authenticated
using (exists(select 1 from public.users u where u.id = auth.uid() and u.is_active and u.tenant_id = employee_settlements.tenant_id and (u.role in ('hr','admin') or u.employee_id = employee_settlements.employee_id)));
drop policy if exists hr_settlements_read_scope on public.employee_settlements;
create policy hr_settlements_read_scope on public.employee_settlements as restrictive for select to authenticated
using (exists(select 1 from public.users u where u.id = auth.uid() and u.is_active and u.tenant_id = employee_settlements.tenant_id and (u.role in ('hr','admin') or u.employee_id = employee_settlements.employee_id)));
drop policy if exists hr_settlements_insert on public.employee_settlements;
create policy hr_settlements_insert on public.employee_settlements for insert to authenticated
with check (exists(select 1 from public.users u join public.employees e on e.id = employee_settlements.employee_id and e.tenant_id = u.tenant_id where u.id = auth.uid() and u.is_active and u.role in ('hr','admin') and u.tenant_id = employee_settlements.tenant_id));
drop policy if exists hr_settlements_write_scope on public.employee_settlements;
create policy hr_settlements_write_scope on public.employee_settlements as restrictive for insert to authenticated
with check (exists(select 1 from public.users u join public.employees e on e.id = employee_settlements.employee_id and e.tenant_id = u.tenant_id where u.id = auth.uid() and u.is_active and u.role in ('hr','admin') and u.tenant_id = employee_settlements.tenant_id));

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('employee_settlement_files', 'employee_settlement_files', false, 5242880, array['application/pdf','image/jpeg','image/png'])
on conflict (id) do update set public = false, file_size_limit = excluded.file_size_limit, allowed_mime_types = excluded.allowed_mime_types;
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

create or replace function public.hr_save_employee_settlement(
  p_id uuid, p_employee_id uuid, p_settlement_date date, p_final_working_date date,
  p_settlement_type text, p_gross_amount numeric, p_deductions_amount numeric,
  p_notes text default null, p_attachment_path text default null, p_attachment_name text default null
) returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare
  v_tenant uuid;
  v_existing public.employee_settlements%rowtype;
  v_gross numeric := round(p_gross_amount, 2);
  v_deductions numeric := round(p_deductions_amount, 2);
begin
  select u.tenant_id into v_tenant from public.users u
  where u.id = auth.uid() and u.is_active and u.role in ('hr','admin');
  if v_tenant is null then raise exception 'Active HR/admin required'; end if;
  if p_id is null or p_employee_id is null or p_settlement_date is null or p_final_working_date is null
    or p_settlement_type is null or p_settlement_type not in ('final','partial','other')
    or v_gross is null or v_deductions is null or v_gross::text in ('NaN','Infinity','-Infinity')
    or v_deductions::text in ('NaN','Infinity','-Infinity') or v_gross <= 0 or v_deductions < 0 or v_deductions > v_gross
    or length(coalesce(p_notes,'')) > 500 then raise exception 'Invalid settlement values'; end if;
  if p_settlement_type = 'final' and p_final_working_date > p_settlement_date then raise exception 'Final working date is after settlement date'; end if;
  perform 1 from public.employees e where e.id = p_employee_id and e.tenant_id = v_tenant for update;
  if not found then raise exception 'Employee outside tenant'; end if;
  if p_attachment_path is not null then
    if not starts_with(p_attachment_path, v_tenant::text || '/' || p_employee_id::text || '/' || p_id::text || '.')
      or p_attachment_path !~ '\.(pdf|jpg|jpeg|png)$' or p_attachment_name is null
      or not exists(select 1 from storage.objects o where o.bucket_id = 'employee_settlement_files' and o.name = p_attachment_path)
    then raise exception 'Invalid settlement attachment'; end if;
  elsif p_attachment_name is not null then raise exception 'Attachment path required'; end if;
  select * into v_existing from public.employee_settlements where id = p_id;
  if found then
    if v_existing.tenant_id = v_tenant and v_existing.employee_id = p_employee_id
      and v_existing.settlement_date = p_settlement_date and v_existing.final_working_date = p_final_working_date
      and v_existing.settlement_type = p_settlement_type and v_existing.gross_amount = v_gross
      and v_existing.deductions_amount = v_deductions and coalesce(v_existing.notes,'') = btrim(coalesce(p_notes,''))
      and v_existing.attachment_path is not distinct from p_attachment_path
      and v_existing.attachment_name is not distinct from p_attachment_name then return p_id;
    end if;
    raise exception 'Settlement request already used for different values';
  end if;
  insert into public.employee_settlements(id, tenant_id, employee_id, final_working_date, settlement_date,
    settlement_type, gross_amount, deductions_amount, net_amount, notes, attachment_path, attachment_name)
  values(p_id, v_tenant, p_employee_id, p_final_working_date, p_settlement_date, p_settlement_type,
    v_gross, v_deductions, v_gross - v_deductions, nullif(btrim(p_notes),''), p_attachment_path, p_attachment_name);
  if p_settlement_type = 'final' then
    update public.employees set status = 'inactive' where id = p_employee_id and tenant_id = v_tenant;
  end if;
  return p_id;
end;
$$;
revoke all on function public.hr_save_employee_settlement(uuid,uuid,date,date,text,numeric,numeric,text,text,text) from public;
grant execute on function public.hr_save_employee_settlement(uuid,uuid,date,date,text,numeric,numeric,text,text,text) to authenticated;
grant select, insert on public.employee_settlements to authenticated;
notify pgrst, 'reload schema';
commit;
