create table if not exists public.payroll_runs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  period_start date not null,
  period_end date not null,
  status text not null default 'draft',
  reject_reason text null,
  total_employees int not null default 0,
  total_amount numeric not null default 0,
  hr_approved_at timestamptz null,
  finance_manager_approved_at timestamptz null,
  admin_approved_at timestamptz null,
  disbursement_status text not null default 'not_started',
  disbursement_task_id uuid null references public.employee_tasks(id),
  disbursement_assignee_employee_id uuid null references public.employees(id),
  created_at timestamptz not null default now()
);

alter table public.payroll_runs
  add column if not exists reject_reason text null,
  add column if not exists hr_approved_at timestamptz null,
  add column if not exists finance_manager_approved_at timestamptz null,
  add column if not exists admin_approved_at timestamptz null,
  add column if not exists disbursement_status text not null default 'not_started',
  add column if not exists disbursement_task_id uuid null references public.employee_tasks(id),
  add column if not exists disbursement_assignee_employee_id uuid null references public.employees(id);

create table if not exists public.payroll_items (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  run_id uuid not null references public.payroll_runs(id),
  employee_id uuid not null references public.employees(id),
  basic_salary numeric not null default 0,
  housing_allowance numeric not null default 0,
  transport_allowance numeric not null default 0,
  other_allowance numeric not null default 0,
  total_amount numeric not null default 0
);

create index if not exists idx_payroll_runs_tenant_start
  on public.payroll_runs (tenant_id, period_start);

create index if not exists idx_payroll_runs_tenant_status
  on public.payroll_runs (tenant_id, status);

create index if not exists idx_payroll_runs_disbursement_status
  on public.payroll_runs (tenant_id, disbursement_status);

create index if not exists idx_payroll_items_run
  on public.payroll_items (run_id);
