-- Final setup for test accounts (Auth -> public.users -> manager links)
-- Run this file after creating users in Supabase Auth.
-- Required Auth emails:
--   it@dimahmusic.com
--   hr@dimahmusic.com
--   finance@dimahmusic.com
--   info@dimahmusic.com

begin;

-- 0) Normalize common email typos first (employees/users side).
update public.employees
set email = 'finance@dimahmusic.com'
where lower(email) = 'finanace@dimahmusic.com';

update public.employees
set email = 'it@dimahmusic.com'
where lower(email) = 'it@dimahmusi.com';

update public.users
set email = 'finance@dimahmusic.com'
where lower(email) = 'finanace@dimahmusic.com';

update public.users
set email = 'it@dimahmusic.com'
where lower(email) = 'it@dimahmusi.com';

-- 1) Normalize roles + basic user rows from auth.users.
with target_emails as (
  select unnest(array[
    'it@dimahmusic.com',
    'hr@dimahmusic.com',
    'finance@dimahmusic.com',
    'info@dimahmusic.com'
  ]) as email
),
auth_users as (
  select
    au.id as auth_id,
    lower(au.email) as email
  from auth.users au
  join target_emails te on lower(au.email) = te.email
),
src as (
  select
    a.auth_id,
    a.email,
    '550e8400-e29b-41d4-a716-446655440000'::uuid as tenant_id,
    split_part(a.email, '@', 1) as name,
    case
      when a.email = 'info@dimahmusic.com' then 'admin'
      when a.email = 'hr@dimahmusic.com' then 'hr'
      else 'manager'
    end as role
  from auth_users a
)
insert into public.users (id, tenant_id, email, name, role, is_active)
select
  s.auth_id,
  s.tenant_id,
  s.email,
  s.name,
  s.role,
  true
from src s
on conflict (id) do update
set
  tenant_id = excluded.tenant_id,
  email = excluded.email,
  name = excluded.name,
  role = excluded.role,
  is_active = true;

-- 2) Link employee_id by matching employee email.
-- If employee row does not exist with same email, employee_id stays null.
update public.users u
set employee_id = e.id
from public.employees e
where u.tenant_id = e.tenant_id
  and lower(u.email) = lower(e.email)
  and u.tenant_id = '550e8400-e29b-41d4-a716-446655440000'::uuid
  and lower(u.email) in (
    'it@dimahmusic.com',
    'hr@dimahmusic.com',
    'finance@dimahmusic.com',
    'info@dimahmusic.com'
  );

-- 3) Optional: auto-assign department managers by department name patterns.
-- Edit patterns if your real department names differ.
update public.departments d
set manager_id = u.employee_id
from public.users u
where d.tenant_id = u.tenant_id
  and u.employee_id is not null
  and (
    (lower(u.email) = 'it@dimahmusic.com' and lower(d.name) like '%it%')
    or (lower(u.email) = 'finance@dimahmusic.com' and lower(d.name) like '%fin%')
    or (lower(u.email) = 'hr@dimahmusic.com' and lower(d.name) like '%hr%')
  );

commit;

-- 4) Verification (target accounts)
select
  u.email,
  u.role,
  u.employee_id,
  e.full_name as employee_name,
  d.name as managed_department
from public.users u
left join public.employees e on e.id = u.employee_id
left join public.departments d on d.manager_id = u.employee_id
where lower(u.email) in (
  'it@dimahmusic.com',
  'hr@dimahmusic.com',
  'finance@dimahmusic.com',
  'info@dimahmusic.com'
)
order by u.email;

-- 5) Verification (any manager/admin/hr user still not linked to employee profile)
select
  u.email,
  u.role,
  u.employee_id
from public.users u
where u.tenant_id = '550e8400-e29b-41d4-a716-446655440000'::uuid
  and u.role in ('manager', 'hr')
  and u.employee_id is null
order by u.email;
