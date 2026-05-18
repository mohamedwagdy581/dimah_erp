create table if not exists public.employee_settlements (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  employee_id uuid not null references public.employees(id),
  final_working_date date not null,
  settlement_date date not null,
  gross_amount numeric(12, 2) not null default 0,
  deductions_amount numeric(12, 2) not null default 0,
  net_amount numeric(12, 2) not null default 0,
  notes text null,
  created_at timestamptz not null default now()
);

create index if not exists idx_employee_settlements_employee
  on public.employee_settlements (employee_id, settlement_date desc);

create index if not exists idx_employee_settlements_tenant
  on public.employee_settlements (tenant_id, settlement_date desc);
