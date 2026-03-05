create table if not exists public.employee_compensation_history (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  employee_id uuid not null references public.employees(id),
  basic_salary numeric not null default 0,
  housing_allowance numeric not null default 0,
  transport_allowance numeric not null default 0,
  other_allowance numeric not null default 0,
  effective_at date null,
  note text null,
  created_at timestamptz not null default now()
);

create index if not exists idx_employee_comp_hist_tenant
  on public.employee_compensation_history (tenant_id);

create index if not exists idx_employee_comp_hist_employee
  on public.employee_compensation_history (employee_id);
