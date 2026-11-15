-- Read-only. Run this file by itself in Supabase SQL Editor.
-- Includes application accounts that exist without an Auth account.
with target as (select 'mohamedmahrous@dimahmusic.com'::text as email),
employees as (
  select e.id, e.tenant_id, e.full_name, e.email
  from public.employees e, target t where lower(btrim(e.email)) = t.email
), accounts as (
  select u.id, u.email, u.tenant_id, u.employee_id, u.role, u.is_active,
    a.id is not null as auth_exists_for_app_id
  from public.users u left join auth.users a on a.id = u.id
  where lower(btrim(u.email)) = (select email from target)
    or u.employee_id in (select id from employees)
)
select jsonb_build_object(
  'email', (select email from target),
  'employee_count', (select count(*) from employees),
  'employees', coalesce((select jsonb_agg(to_jsonb(e)) from employees e), '[]'::jsonb),
  'auth_accounts', coalesce((select jsonb_agg(jsonb_build_object('id', a.id, 'email', a.email, 'email_confirmed_at', a.email_confirmed_at))
    from auth.users a where lower(btrim(a.email)) = (select email from target)), '[]'::jsonb),
  'app_accounts', coalesce((select jsonb_agg(to_jsonb(u)) from accounts u), '[]'::jsonb)
) as login_diagnosis;
