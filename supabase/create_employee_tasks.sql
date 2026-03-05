create table if not exists public.employee_tasks (
  id uuid primary key default gen_random_uuid(),
  tenant_id uuid not null references public.tenants(id),
  employee_id uuid not null references public.employees(id),
  assigned_by_employee_id uuid null references public.employees(id),
  title text not null,
  description text null,
  due_date date null,
  status text not null default 'todo' check (status in ('todo', 'in_progress', 'done')),
  progress int not null default 0 check (progress >= 0 and progress <= 100),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_employee_tasks_tenant_employee
  on public.employee_tasks (tenant_id, employee_id, status);

create index if not exists idx_employee_tasks_tenant_created
  on public.employee_tasks (tenant_id, created_at desc);
