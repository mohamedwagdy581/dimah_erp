create table if not exists public.leave_requests (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  employee_id uuid not null references public.employees(id),
  type text not null default 'annual',
  start_date date not null,
  end_date date not null,
  status text not null default 'pending',
  file_url text null,
  notes text null,
  created_at timestamptz not null default now()
);

create index if not exists idx_leave_tenant_start
  on public.leave_requests (tenant_id, start_date);

create index if not exists idx_leave_employee_start
  on public.leave_requests (employee_id, start_date);
