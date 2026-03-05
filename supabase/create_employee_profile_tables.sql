create table if not exists public.employee_personal (
  employee_id uuid primary key references public.employees(id),
  tenant_id uuid not null references public.tenants(id),
  nationality text null,
  marital_status text null,
  address text null,
  city text null,
  country text null,
  passport_no text null,
  passport_expiry date null,
  education_level text null,
  major text null,
  university text null
);

create table if not exists public.employee_financial (
  employee_id uuid primary key references public.employees(id),
  tenant_id uuid not null references public.tenants(id),
  bank_name text null,
  iban text null,
  account_number text null,
  payment_method text not null default 'bank' -- bank/cash
);

create table if not exists public.employee_contracts (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  employee_id uuid not null references public.employees(id),
  contract_type text not null default 'full_time',
  start_date date not null,
  end_date date null,
  probation_months int null,
  file_url text null,
  created_at timestamptz not null default now()
);

create index if not exists idx_employee_personal_tenant
  on public.employee_personal (tenant_id);

create index if not exists idx_employee_financial_tenant
  on public.employee_financial (tenant_id);

create index if not exists idx_employee_contracts_employee
  on public.employee_contracts (employee_id);
