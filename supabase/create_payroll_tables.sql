create table if not exists public.payroll_runs (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  period_start date not null,
  period_end date not null,
  status text not null default 'draft',
  total_employees int not null default 0,
  total_amount numeric not null default 0,
  created_at timestamptz not null default now()
);

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

create index if not exists idx_payroll_items_run
  on public.payroll_items (run_id);
