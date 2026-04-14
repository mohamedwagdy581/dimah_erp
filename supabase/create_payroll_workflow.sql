alter table public.payroll_runs
  add column if not exists reject_reason text null,
  add column if not exists hr_approved_at timestamptz null,
  add column if not exists finance_manager_approved_at timestamptz null,
  add column if not exists admin_approved_at timestamptz null,
  add column if not exists disbursement_status text not null default 'not_started',
  add column if not exists disbursement_task_id uuid null references public.employee_tasks(id),
  add column if not exists disbursement_assignee_employee_id uuid null references public.employees(id);

create index if not exists idx_payroll_runs_tenant_status
  on public.payroll_runs (tenant_id, status);

create index if not exists idx_payroll_runs_disbursement_status
  on public.payroll_runs (tenant_id, disbursement_status);

update public.payroll_runs
set disbursement_status = coalesce(disbursement_status, 'not_started')
where disbursement_status is null;
