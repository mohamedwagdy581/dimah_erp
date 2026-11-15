-- Read-only diagnosis. Run in Supabase SQL Editor, not in the application.
with target as (
  select 'mohammedwagdi2030@gmail.com'::text as email
)
select
  t.email,
  a.id as auth_user_id,
  a.email_confirmed_at,
  u.id as app_user_id,
  u.role,
  u.tenant_id as app_tenant_id,
  u.employee_id as linked_employee_id,
  e.id as employee_id,
  e.full_name,
  e.tenant_id as employee_tenant_id,
  e.department_id,
  d.name as department_name
from target t
left join auth.users a on lower(trim(a.email)) = t.email
left join public.users u on u.id = a.id
left join public.employees e on lower(trim(e.email)) = t.email
left join public.departments d on d.id = e.department_id
  and d.tenant_id = e.tenant_id;
