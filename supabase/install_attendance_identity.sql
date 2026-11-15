-- Employee identity mapping only. Does not import events or alter attendance records.
-- Run once in Supabase SQL Editor. Defaults to the first Hikvision device source.
begin;

create table if not exists public.employee_attendance_identities (
  tenant_id uuid not null,
  device_key text not null default 'hikvision-main',
  employee_id uuid not null references public.employees(id) on delete cascade,
  device_employee_number text not null check (device_employee_number ~ '^[A-Za-z0-9_-]{1,32}$'),
  updated_at timestamptz not null default now(),
  updated_by uuid not null,
  primary key (tenant_id, device_key, employee_id),
  unique (tenant_id, device_key, device_employee_number)
);
alter table public.employee_attendance_identities enable row level security;
revoke all on table public.employee_attendance_identities from anon, authenticated;

-- Internal helper: cannot be invoked by an application user directly.
create or replace function public.attendance_identity_actor()
returns public.users language plpgsql security definer set search_path = ''
as $$
declare actor public.users%rowtype;
begin
  select * into actor from public.users where id = auth.uid();
  if not found or actor.is_active is not true or actor.role not in ('admin', 'hr') or actor.role is null
     or actor.tenant_id is null then
    raise exception 'Active HR or admin account required' using errcode = '42501';
  end if;
  return actor;
end;
$$;
revoke all on function public.attendance_identity_actor() from public, anon, authenticated;

create or replace function public.check_employee_attendance_identity(p_number text, p_employee_id uuid default null)
returns void language plpgsql security definer set search_path = ''
as $$
declare
  actor public.users%rowtype;
  device_number text := nullif(trim(p_number), '');
begin
  actor := public.attendance_identity_actor();
  if p_employee_id is not null and not exists (
    select 1 from public.employees where id = p_employee_id and tenant_id = actor.tenant_id
  ) then
    raise exception 'Employee does not belong to your company' using errcode = '42501';
  end if;
  if device_number is null then return; end if;
  if device_number !~ '^[A-Za-z0-9_-]{1,32}$' then
    raise exception 'Invalid device employee number' using errcode = '22023';
  end if;
  if exists (
    select 1 from public.employee_attendance_identities m
    where m.tenant_id = actor.tenant_id and m.device_key = 'hikvision-main'
      and m.device_employee_number = device_number and m.employee_id is distinct from p_employee_id
  ) then
    raise exception 'Device number is already linked to another employee' using errcode = '23505';
  end if;
end;
$$;

create or replace function public.get_employee_attendance_identity(p_employee_id uuid)
returns text language plpgsql security definer set search_path = ''
as $$
declare actor public.users%rowtype; device_number text;
begin
  actor := public.attendance_identity_actor();
  if p_employee_id is null or not exists (
    select 1 from public.employees where id = p_employee_id and tenant_id = actor.tenant_id
  ) then
    raise exception 'Employee does not belong to your company' using errcode = '42501';
  end if;
  select device_employee_number into device_number from public.employee_attendance_identities
    where employee_id = p_employee_id and tenant_id = actor.tenant_id and device_key = 'hikvision-main';
  return device_number;
end;
$$;

create or replace function public.set_employee_attendance_identity(p_employee_id uuid, p_number text)
returns void language plpgsql security definer set search_path = ''
as $$
declare actor public.users%rowtype; device_number text := nullif(trim(p_number), '');
begin
  actor := public.attendance_identity_actor();
  if p_employee_id is null then raise exception 'Employee required' using errcode = '22023'; end if;
  perform public.check_employee_attendance_identity(p_number, p_employee_id);
  if device_number is null then
    delete from public.employee_attendance_identities
      where tenant_id = actor.tenant_id and device_key = 'hikvision-main' and employee_id = p_employee_id;
    return;
  end if;
  insert into public.employee_attendance_identities
    (tenant_id, device_key, employee_id, device_employee_number, updated_by)
  values (actor.tenant_id, 'hikvision-main', p_employee_id, device_number, actor.id)
  on conflict (tenant_id, device_key, employee_id) do update
    set device_employee_number = excluded.device_employee_number,
        updated_at = now(), updated_by = excluded.updated_by;
end;
$$;

revoke all on function public.check_employee_attendance_identity(text, uuid) from public, anon;
revoke all on function public.get_employee_attendance_identity(uuid) from public, anon;
revoke all on function public.set_employee_attendance_identity(uuid, text) from public, anon;
grant execute on function public.check_employee_attendance_identity(text, uuid) to authenticated;
grant execute on function public.get_employee_attendance_identity(uuid) to authenticated;
grant execute on function public.set_employee_attendance_identity(uuid, text) to authenticated;
notify pgrst, 'reload schema';
commit;
