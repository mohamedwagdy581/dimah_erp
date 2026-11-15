-- Read-only diagnosis for the affected employee. Run in Supabase SQL Editor.
-- Does not expose passwords, hashes, tokens or service keys.
with target as (select 'mohamedmahrous@dimahmusic.com'::text as email)
select e.id as employee_id, e.full_name, e.email, e.employee_number,
  e.department_id, e.job_title_id, j.name as job_title,
  e.hire_date, e.date_of_birth, e.nationality as employee_nationality,
  p.employee_id is not null as has_personal_row, p.nationality as personal_nationality,
  p.passport_no is not null as has_passport_number, p.passport_expiry,
  f.employee_id is not null as has_financial_row,
  nullif(btrim(f.iban), '') is not null as has_iban,
  c.employee_id is not null as has_compensation_row,
  k.employee_id is not null as has_contract_row, k.start_date, k.end_date,
  a.id as auth_user_id, a.email_confirmed_at,
  u.id as app_user_id, u.employee_id as linked_employee_id, u.role, u.is_active
from target t
left join public.employees e on lower(btrim(e.email)) = t.email
left join public.job_titles j on j.id = e.job_title_id and j.tenant_id = e.tenant_id
left join public.employee_personal p on p.employee_id = e.id and p.tenant_id = e.tenant_id
left join public.employee_financial f on f.employee_id = e.id and f.tenant_id = e.tenant_id
left join public.employee_compensation c on c.employee_id = e.id and c.tenant_id = e.tenant_id
left join lateral (select * from public.employee_contracts where employee_id = e.id
  and tenant_id = e.tenant_id order by created_at desc limit 1) k on true
left join auth.users a on lower(btrim(a.email)) = t.email
left join public.users u on u.id = a.id or lower(btrim(u.email)) = t.email or u.employee_id = e.id;

-- Installed versions: empty results mean the corresponding SQL is missing.
select p.proname as function_name, pg_get_function_identity_arguments(p.oid) as arguments
from pg_proc p join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public' and p.proname in
  ('create_employee_with_comp','hr_create_employee_complete','hr_employee_creation_ready',
   'employee_login_context','complete_employee_login');
