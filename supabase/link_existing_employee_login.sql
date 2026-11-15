-- Reviewed repair for ONE existing Auth account and ONE existing employee.
-- Run inspect_employee_login.sql first, then this in Supabase SQL Editor.
-- This does not create Auth accounts or employees, change departments/roles,
-- modify passwords, or change schema. New public.users rows have role employee.
begin;
do $$
declare
  target_email constant text := 'mohammedwagdi2030@gmail.com';
  auth_id uuid;
  emp record;
  existing record;
  matches integer;
begin
  select count(*) into matches from auth.users
    where lower(trim(email)) = target_email;
  if matches <> 1 then
    raise exception 'Expected one Auth account for %, found %', target_email, matches;
  end if;
  select id into auth_id from auth.users
    where lower(trim(email)) = target_email;

  select count(*) into matches from public.employees
    where lower(trim(email)) = target_email;
  if matches <> 1 then
    raise exception 'Expected one employee for %, found %. Resolve missing/duplicate records first.', target_email, matches;
  end if;
  select id, tenant_id, full_name, department_id into emp
    from public.employees where lower(trim(email)) = target_email for update;
  if emp.tenant_id is null then
    raise exception 'The employee has no tenant_id';
  end if;
  if exists (select 1 from public.users
    where lower(trim(email)) = target_email and id <> auth_id) then
    raise exception 'A different public.users ID already uses this email. Review the mapping first.';
  end if;
  select id, tenant_id, employee_id into existing
    from public.users where id = auth_id for update;
  if found then
    if existing.tenant_id is distinct from emp.tenant_id then
      raise exception 'Existing app account belongs to a different tenant';
    end if;
    if existing.employee_id is not null and existing.employee_id <> emp.id then
      raise exception 'Auth account is already linked to a different employee';
    end if;
    update public.users set employee_id = emp.id where id = auth_id;
  else
    insert into public.users
      (id, tenant_id, email, name, role, employee_id, is_active)
    values
      (auth_id, emp.tenant_id, target_email, emp.full_name, 'employee', emp.id, true);
  end if;
end $$;
commit;

select u.email, u.role, u.employee_id, e.full_name, d.name as department_name
from public.users u
join public.employees e on e.id = u.employee_id and e.tenant_id = u.tenant_id
left join public.departments d on d.id = e.department_id and d.tenant_id = e.tenant_id
where lower(trim(u.email)) = 'mohammedwagdi2030@gmail.com';
