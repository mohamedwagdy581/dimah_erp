create table if not exists public.attendance_records (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  employee_id uuid not null references public.employees(id),
  date date not null,
  status text not null default 'present',
  check_in timestamptz null,
  check_out timestamptz null,
  notes text null,
  created_at timestamptz not null default now()
);

create index if not exists idx_attendance_tenant_date
  on public.attendance_records (tenant_id, date);

create index if not exists idx_attendance_employee_date
  on public.attendance_records (employee_id, date);
