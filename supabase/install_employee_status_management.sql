-- Install employee deactivation/reactivation. Preserves employee history.
begin;

create or replace function public.hr_sync_inactive_employee_login()
returns trigger language plpgsql security definer set search_path = public, pg_temp
as $$
begin
  if new.status = 'inactive' then
    if exists (select 1 from public.users u where u.employee_id = new.id
      and (u.tenant_id is distinct from new.tenant_id or coalesce(u.role, '') not in ('employee','manager'))) then
      raise exception 'Administrative or inconsistent linked account requires review';
    end if;
    update public.users set is_active = false
    where employee_id = new.id and tenant_id = new.tenant_id
      and role in ('employee','manager');
  end if;
  return new;
end;
$$;
revoke all on function public.hr_sync_inactive_employee_login() from public, anon, authenticated;
drop trigger if exists hr_sync_inactive_employee_login on public.employees;
create trigger hr_sync_inactive_employee_login after update of status on public.employees
for each row execute function public.hr_sync_inactive_employee_login();

create or replace function public.hr_guard_inactive_employee_login()
returns trigger language plpgsql security definer set search_path = public, pg_temp
as $$
declare v_status text;
begin
  if new.employee_id is not null and new.is_active is true and new.role in ('employee','manager') then
    select status into v_status from public.employees
      where id = new.employee_id and tenant_id = new.tenant_id for update;
    if not found or v_status = 'inactive' then
      raise exception 'Reactivate the employee before enabling login';
    end if;
  end if;
  return new;
end;
$$;
revoke all on function public.hr_guard_inactive_employee_login() from public, anon, authenticated;
drop trigger if exists hr_guard_inactive_employee_login on public.users;
create trigger hr_guard_inactive_employee_login before insert or update of employee_id, tenant_id, role, is_active
on public.users for each row execute function public.hr_guard_inactive_employee_login();

create or replace function public.hr_set_employee_status(p_employee_id uuid, p_status text)
returns void language plpgsql security definer set search_path = public, pg_temp
as $$
declare v_tenant uuid; v_status text;
begin
  select tenant_id into v_tenant from public.users
    where id = auth.uid() and is_active is true and role in ('hr','admin');
  if v_tenant is null then raise exception 'Active HR/admin required' using errcode = '42501'; end if;
  if p_status is null or p_status not in ('active','inactive') then
    raise exception 'Invalid employee status' using errcode = '22023';
  end if;
  select status into v_status from public.employees
    where id = p_employee_id and tenant_id = v_tenant for update;
  if not found then raise exception 'Employee outside company' using errcode = '42501'; end if;
  if p_status = 'inactive' and exists(select 1 from public.users
    where employee_id = p_employee_id and id = auth.uid()) then
    raise exception 'Cannot deactivate your own employee record' using errcode = '42501';
  end if;
  update public.employees set status = p_status where id = p_employee_id and tenant_id = v_tenant;
end;
$$;
revoke all on function public.hr_set_employee_status(uuid,text) from public, anon;
grant execute on function public.hr_set_employee_status(uuid,text) to authenticated;

-- Sync existing inactive employees, including previously settled employees.
update public.users u set is_active = false
where u.is_active is true and u.role in ('employee','manager')
  and exists(select 1 from public.employees e where e.id = u.employee_id
    and e.tenant_id = u.tenant_id and e.status = 'inactive');

create or replace function public.employee_login_context(p_actor_id uuid, p_employee_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  actor public.users%rowtype;
  emp public.employees%rowtype;
  auth_id uuid;
  app public.users%rowtype;
  matches integer;
begin
  select * into actor from public.users where id = p_actor_id;
  if not found or coalesce(actor.role, '') not in ('admin', 'hr') or actor.is_active is not true then
    raise exception 'Only active HR and admin accounts may provision logins' using errcode = '42501';
  end if;
  select * into emp from public.employees where id = p_employee_id and tenant_id = actor.tenant_id;
  if not found then
    raise exception 'Employee is outside your company or does not exist' using errcode = '42501';
  end if;
  if emp.email is null or trim(emp.email) = '' then
    raise exception 'Employee email is required' using errcode = '22023';
  end if;
  if emp.status = 'inactive' then
    raise exception 'Inactive employee cannot provision login' using errcode = '42501';
  end if;
  select count(*) into matches from public.employees where lower(trim(email)) = lower(trim(emp.email));
  if matches <> 1 then
    raise exception 'Duplicate employee email; resolve duplicate records before provisioning' using errcode = '23505';
  end if;
  select count(*) into matches from auth.users where lower(trim(email)) = lower(trim(emp.email));
  if matches > 1 then
    raise exception 'Multiple Auth accounts match the email' using errcode = '23505';
  end if;
  select id into auth_id from auth.users where lower(trim(email)) = lower(trim(emp.email));
  select * into app from public.users
    where id = auth_id or lower(trim(email)) = lower(trim(emp.email));
  if found then
    if app.id is distinct from auth_id or app.tenant_id is distinct from emp.tenant_id
       or (app.employee_id is not null and app.employee_id <> emp.id)
       or coalesce(app.role, '') not in ('employee', 'manager') then
      raise exception 'Account is already assigned to another employee, company or privileged role' using errcode = '42501';
    end if;
    if exists (select 1 from public.users
      where (id = auth_id or lower(trim(email)) = lower(trim(emp.email))) and id <> app.id) then
      raise exception 'Conflicting application accounts' using errcode = '23505';
    end if;
  end if;
  return jsonb_build_object(
    'employeeId', emp.id, 'tenantId', emp.tenant_id,
    'email', lower(trim(emp.email)), 'name', emp.full_name,
    'authUserId', auth_id
  );
end;
$$;

revoke all on function public.employee_login_context(uuid,uuid) from public, anon, authenticated;
grant execute on function public.employee_login_context(uuid,uuid) to service_role;
notify pgrst, 'reload schema';
commit;
