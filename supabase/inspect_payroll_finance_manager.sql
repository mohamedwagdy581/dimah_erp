-- Read-only. Run alone; checks the reviewer of the October payroll and account linkage.
-- Does not return passwords, tokens, bank details or salaries.
with target as (
  select r.id, r.tenant_id, r.status, a.current_approver_role,
    a.payload ->> 'finance_reviewed_by' as reviewer_id
  from public.payroll_runs r left join public.approval_requests a
    on a.tenant_id = r.tenant_id and a.request_type = 'payroll_run'
    and a.payload ->> 'run_id' = r.id::text and a.status = 'pending'
  where r.id = '16133bfa-0d71-4101-96b3-7162f158836d'::uuid
)
select t.id as run_id, t.status as payroll_status, t.current_approver_role,
  u.id as account_id, u.email, u.role, u.is_active, u.employee_id,
  u.id::text = t.reviewer_id as is_finance_reviewer,
  e.employee_number, e.full_name, e.status as employee_status,
  e.tenant_id = t.tenant_id as employee_in_same_tenant,
  case when u.id is null then 'No finance manager account'
    when u.is_active is not true then 'Account inactive'
    when u.role <> 'finance_manager' then 'Reviewer role changed'
    when u.employee_id is null then 'Missing employee link'
    when e.id is null then 'Linked employee missing'
    when e.tenant_id <> t.tenant_id then 'Employee belongs to another tenant'
    when e.status <> 'active' then 'Linked employee inactive'
    else 'Ready' end as linkage_status
from target t left join public.users u on u.tenant_id = t.tenant_id
  and (u.role = 'finance_manager' or u.id::text = t.reviewer_id)
left join public.employees e on e.id = u.employee_id
order by u.email;
