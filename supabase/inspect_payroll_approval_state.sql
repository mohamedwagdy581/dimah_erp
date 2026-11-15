-- Read-only: compare October 2026 payroll with its linked approval.
-- Run alone in Supabase SQL Editor. Does not change salaries or approvals.
select r.id as run_id, r.period_start, r.period_end,
  r.status as payroll_status, r.total_employees, r.total_amount,
  r.hr_approved_at, r.finance_manager_approved_at, r.admin_approved_at,
  a.id as approval_id, a.status as approval_status,
  a.current_approver_role, a.created_at as approval_created_at
from public.payroll_runs r
left join public.approval_requests a
  on a.tenant_id = r.tenant_id and a.request_type = 'payroll_run'
  and a.payload ->> 'run_id' = r.id::text
where r.period_start >= date '2026-10-01'
  and r.period_start < date '2026-11-01'
order by r.created_at desc, a.created_at desc;
