-- Read-only comparison. Run this file alone in Supabase SQL Editor.
-- Keep both records until their data and linked history have been reviewed.
-- Does not return IBAN, passport numbers, passwords or keys.
select
  e.id as employee_id,
  e.employee_number,
  e.full_name,
  e.status,
  to_jsonb(e) ->> 'created_at' as created_at,
  e.hire_date,
  e.date_of_birth,
  j.name as job_title,
  e.nationality as employee_nationality,
  p.nationality as personal_nationality,
  p.employee_id is not null as has_personal_row,
  nullif(btrim(p.passport_no), '') is not null as has_passport_number,
  p.passport_expiry,
  f.employee_id is not null as has_financial_row,
  nullif(btrim(f.iban), '') is not null as has_iban,
  f.bank_name,
  c.employee_id is not null as has_compensation_row,
  c.basic_salary,
  (select count(*) from public.employee_contracts k
    where k.employee_id = e.id and k.tenant_id = e.tenant_id) as contract_count,
  k.start_date as latest_contract_start,
  k.end_date as latest_contract_end
from public.employees e
left join public.job_titles j on j.id = e.job_title_id and j.tenant_id = e.tenant_id
left join public.employee_personal p on p.employee_id = e.id and p.tenant_id = e.tenant_id
left join public.employee_financial f on f.employee_id = e.id and f.tenant_id = e.tenant_id
left join public.employee_compensation c on c.employee_id = e.id and c.tenant_id = e.tenant_id
left join lateral (
  select k.start_date, k.end_date
  from public.employee_contracts k
  where k.employee_id = e.id and k.tenant_id = e.tenant_id
  order by k.created_at desc, k.id
  limit 1
) k on true
where e.tenant_id = '550e8400-e29b-41d4-a716-446655440000'::uuid
  and lower(btrim(e.email)) = 'mohamedmahrous@dimahmusic.com'
order by e.employee_number, e.id;
